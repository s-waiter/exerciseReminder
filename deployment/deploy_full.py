import os
import sys
import shutil
import time
import argparse
import json

# Try to install paramiko if missing
try:
    import paramiko
except ImportError:
    print("Installing paramiko...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "paramiko"])
    import paramiko

# Configuration
HOST = "47.101.52.0"
USER = "root"
PASS = "Pass1234"
# SSH Port configuration (Standard is 22)
SSH_PORTS = [22] 

# Local paths
# This script is now in deployment/ subdirectory, so we need to go up one level
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKEND_DIR = os.path.join(BASE_DIR, "backend")
FRONTEND_DIR = os.path.join(BASE_DIR, "frontend")
DIST_DIR = os.path.join(FRONTEND_DIR, "dist")
VERSION_FILE = os.path.join(BASE_DIR, "version_info.json")

# Remote paths
REMOTE_BASE = "/opt/deskcare"

def create_client():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    last_err = None
    for port in SSH_PORTS:
        try:
            print(f"Connecting to {HOST}:{port}...")
            client.connect(HOST, port=port, username=USER, password=PASS, timeout=5)
            print(f"Connected via port {port}")
            return client
        except Exception as e:
            print(f"Failed to connect on port {port}: {e}")
            last_err = e
            
    raise last_err

def run_remote(client, cmd, ignore_errors=False):
    print(f"REMOTE: {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd)
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if exit_status != 0 and not ignore_errors:
        print(f"Error executing {cmd}: {err}")
    return out

def upload_dir(sftp, local_dir, remote_dir):
    try:
        sftp.mkdir(remote_dir)
    except IOError:
        pass
    
    for item in os.listdir(local_dir):
        if item == "__pycache__" or item == ".git" or item == "venv" or item == "node_modules":
            continue
            
        local_path = os.path.join(local_dir, item)
        remote_path = f"{remote_dir}/{item}"
        
        if os.path.isfile(local_path):
            print(f"Uploading {item}...")
            sftp.put(local_path, remote_path)
        elif os.path.isdir(local_path):
            upload_dir(sftp, local_path, remote_path)

def build_frontend():
    print("--- Building Frontend ---")
    if not os.path.exists(FRONTEND_DIR):
        print(f"Error: Frontend directory not found at {FRONTEND_DIR}")
        return False
    
    # Use user provided npm path
    npm_cmd = r'"D:\jinzhan\Software\code\nodejs\npm.cmd"'
    node_dir = r"D:\jinzhan\Software\code\nodejs"
    
    # Add node to PATH for this process
    os.environ["PATH"] = node_dir + os.pathsep + os.environ["PATH"]
    
    # Check if node_modules exists, if not install
    if not os.path.exists(os.path.join(FRONTEND_DIR, "node_modules")):
        print("Installing frontend dependencies...")
        if os.system(f"cd {FRONTEND_DIR} && {npm_cmd} install") != 0:
            print("Error: npm install failed")
            return False

    print("Running npm run build...")
    if os.system(f"cd {FRONTEND_DIR} && {npm_cmd} run build") != 0:
        print("Error: npm run build failed")
        return False
    
    return True

def deploy_frontend_only(client, sftp):
    print("--- Deploying Frontend (Official Website) ---")
    
    # 1. Build
    if not build_frontend():
        print("Frontend build failed.")
        return

    # 2. Upload to backend static folder on server
    print("Uploading static files...")
    # The structure on server is /opt/deskcare/static (root level) not /opt/deskcare/app/static
    # Let's check main.py logic: 
    # static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
    # if main.py is in /opt/deskcare/app/main.py, then dirname(main.py) is /opt/deskcare/app
    # dirname(/opt/deskcare/app) is /opt/deskcare
    # so static_dir is /opt/deskcare/static
    
    # So we should upload to /opt/deskcare/static
    
    # Clean remote static dir
    run_remote(client, f"rm -rf {REMOTE_BASE}/static/*", True)
    run_remote(client, f"mkdir -p {REMOTE_BASE}/static", True)
    
    upload_dir(sftp, DIST_DIR, f"{REMOTE_BASE}/static")
    print("Frontend deployment complete.")

def deploy_backend_only(client, sftp):
    print("--- Deploying Backend (Python API) ---")
    
    # 1. Stop Service
    print("Stopping service...")
    run_remote(client, "systemctl stop deskcare", True)
    
    # 2. Upload Code
    print("Uploading backend code...")
    # We only update app code, requirements, run.py. We do NOT touch 'files' or 'static'
    run_remote(client, f"rm -rf {REMOTE_BASE}/app/*.py", True) # Clean py files but keep static/ dir? No, static is inside app usually
    # To be safe: clean app code but keep static if it exists
    # Actually, standard structure is app/static. If we wipe app/, we wipe static.
    # So if we deploy backend only, we must re-upload static OR be careful.
    # Strategy: Upload app/ code but exclude static folder locally? 
    # Or just overwrite.
    
    # Let's upload app folder but skip static locally if it's empty
    # Better: just upload everything in app/ except static if we don't want to touch it.
    # But usually backend deploy might include new static logic.
    # Let's assume backend deploy updates python code.
    
    # Upload app dir (excluding static if not present locally, but local backend/app/static is usually empty or gitkept)
    # To avoid deleting remote static (which holds the website), we should be careful.
    # Remote structure: /opt/deskcare/app/static (website)
    # Local structure: backend/app/static (empty or build artifact)
    
    # Safe approach: Upload file by file for app/ root, and subdirs.
    # Or just use rsync logic. Since we use paramiko, let's just upload app/ 
    # BUT we need to make sure we don't wipe /app/static on remote if local is empty.
    
    # Let's iterate local backend/app
    local_app = os.path.join(BACKEND_DIR, "app")
    remote_app = f"{REMOTE_BASE}/app"
    
    for item in os.listdir(local_app):
        if item == "static": continue # Skip static folder when deploying backend code only
        if item == "__pycache__": continue
        
        l_path = os.path.join(local_app, item)
        r_path = f"{remote_app}/{item}"
        
        if os.path.isfile(l_path):
            print(f"Uploading {item}...")
            sftp.put(l_path, r_path)
        elif os.path.isdir(l_path):
            upload_dir(sftp, l_path, r_path)
            
    # Upload root files
    root_files = ["run.py", "requirements.txt", "alembic.ini"]
    for f in root_files:
        local_p = os.path.join(BACKEND_DIR, f)
        if os.path.exists(local_p):
            print(f"Uploading {f}...")
            sftp.put(local_p, f"{REMOTE_BASE}/{f}")

    # 3. Update Dependencies
    print("Checking dependencies...")
    run_remote(client, f"{REMOTE_BASE}/venv/bin/pip install -r {REMOTE_BASE}/requirements.txt")
    
    # 4. Restart Service
    print("Restarting service...")
    run_remote(client, "systemctl daemon-reload")
    run_remote(client, "systemctl restart deskcare")
    
    # 5. Verify
    print("Verifying deployment...")
    time.sleep(5) # Wait for service to start
    status = run_remote(client, "systemctl is-active deskcare")
    print(f"Service status: {status}")
    
    if status.strip() != "active":
        print("Error: Service is not active. Fetching logs...")
        run_remote(client, "journalctl -u deskcare -n 20 --no-pager", True)
    else:
        # Check API health
        try:
            import urllib.request
            resp = urllib.request.urlopen(f"http://{HOST}/docs", timeout=10)
            if resp.status == 200:
                print(f"API Check: OK (http://{HOST}/docs)")
            else:
                print(f"API Check: Failed (Status {resp.status})")
        except Exception as e:
             print(f"API Check: Failed ({e})")
    
    print("Backend deployment complete.")

def get_latest_zip():
    # Find DeskCare_vX.X.X.zip in RELEASES_DIR
    import glob
    releases_dir = os.path.join(BASE_DIR, "releases")
    if not os.path.exists(releases_dir):
        print(f"Warning: {releases_dir} does not exist.")
        return None
        
    zips = glob.glob(os.path.join(releases_dir, "DeskCare_v*.zip"))
    if not zips:
        return None
    # Sort by modification time
    zips.sort(key=os.path.getmtime, reverse=True)
    return zips[0]

def deploy_app_package(client, sftp):
    print("--- Deploying Application Package (Installer Zip) ---")
    
    zip_path = get_latest_zip()
    if not zip_path:
        print(f"Error: No DeskCare_v*.zip found in releases folder")
        return
    
    filename = os.path.basename(zip_path)
    print(f"Found latest package: {filename}")
    
    # 1. Upload Zip
    remote_files_dir = f"{REMOTE_BASE}/files"
    run_remote(client, f"mkdir -p {remote_files_dir}", True)
    
    print(f"Uploading {filename}...")
    sftp.put(zip_path, f"{remote_files_dir}/{filename}")
    run_remote(client, f"chmod 644 {remote_files_dir}/{filename}", True)
    
    # 2. Update version info on server
    # Always generate new version_info based on root version_info.json
    if os.path.exists(VERSION_FILE):
        print("Generating compatible version_info.json...")
        with open(VERSION_FILE, "r") as f:
            v_data = json.load(f)
            
        # Construct C++ compatible version info
        version_str = f"{v_data['major']}.{v_data['minor']}.{v_data['patch']}"
        remote_json = {
            "version": version_str,
            "latest_version": version_str,
            "changelog": f"Update to version {version_str}",
            "download_url": f"http://{HOST}/files/{filename}",
            "major": v_data['major'],
            "minor": v_data['minor'],
            "patch": v_data['patch']
        }
        
        # Write to temp file
        with open("version_info_remote.json", "w") as f:
            json.dump(remote_json, f, indent=4)
            
        print("Uploading version_info.json...")
        
        # 1. Force delete remote files to ensure no caching/stale inodes
        print("Cleaning remote version files...")
        run_remote(client, f"rm -f {REMOTE_BASE}/app/files/version_info.json", True)
        run_remote(client, f"rm -f {REMOTE_BASE}/files/version_info.json", True)
        
        # 2. Upload to app/files location where backend reads it
        # Ensure directory exists
        run_remote(client, f"mkdir -p {REMOTE_BASE}/app/files", True)
        sftp.put("version_info_remote.json", f"{REMOTE_BASE}/app/files/version_info.json")
        run_remote(client, f"chmod 644 {REMOTE_BASE}/app/files/version_info.json", True)
        
        # 3. Also upload to root files if needed
        # Ensure directory exists
        run_remote(client, f"mkdir -p {REMOTE_BASE}/files", True)
        sftp.put("version_info_remote.json", f"{REMOTE_BASE}/files/version_info.json")
        run_remote(client, f"chmod 644 {REMOTE_BASE}/files/version_info.json", True)
        
        os.remove("version_info_remote.json")
        
    print("Application package deployment complete.")

def main():
    parser = argparse.ArgumentParser(description="DeskCare Automated Deployment Tool")
    parser.add_argument("mode", choices=["all", "backend", "frontend", "app"], 
                        help="Deployment mode: all (full stack), backend (python api), frontend (website), app (installer zip)")
    
    args = parser.parse_args()
    
    print(f"Starting deployment in [{args.mode}] mode...")
    
    try:
        client = create_client()
        sftp = client.open_sftp()
    except Exception as e:
        print(f"Connection failed: {e}")
        sys.exit(1)

    if args.mode == "frontend" or args.mode == "all":
        deploy_frontend_only(client, sftp)
        
    if args.mode == "backend" or args.mode == "all":
        deploy_backend_only(client, sftp)
        
    if args.mode == "app" or args.mode == "all":
        deploy_app_package(client, sftp)

    client.close()
    print("All tasks finished.")

if __name__ == "__main__":
    main()
