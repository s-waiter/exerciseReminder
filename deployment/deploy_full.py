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
            try:
                sftp.put(local_path, remote_path)
            except Exception as e:
                print(f"Error uploading {item}: {e}")
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
    
    # Ensure static dir exists
    run_remote(client, f"mkdir -p {REMOTE_BASE}/static", True)
    # Clean remote static dir
    run_remote(client, f"rm -rf {REMOTE_BASE}/static/*", True)
    
    upload_dir(sftp, DIST_DIR, f"{REMOTE_BASE}/static")
    
    # Restart backend to ensure it picks up any new static file types or mounts if necessary
    print("Restarting backend service to refresh static files...")
    run_remote(client, "systemctl restart deskcare", True)
    
    print("Frontend deployment complete.")

def deploy_backend_only(client, sftp):
    print("--- Deploying Backend (Python API) ---")
    
    # 1. Stop Service
    print("Stopping service...")
    run_remote(client, "systemctl stop deskcare", True)
    
    # 2. Upload Code
    print("Uploading backend code...")
    # Clean remote app code (EXCLUDING static directory)
    # We use a safer way to clean: find and delete only .py files and subdirs except 'static'
    run_remote(client, f"find {REMOTE_BASE}/app -maxdepth 1 -name '*.py' -delete", True)
    
    # Local backend/app path
    local_app_dir = os.path.join(BACKEND_DIR, "app")
    remote_app_dir = f"{REMOTE_BASE}/app"
    
    # Create remote app dir if not exists
    run_remote(client, f"mkdir -p {remote_app_dir}", True)

    # Upload everything from local app/ to remote app/
    # But we want to be CAREFUL not to wipe the remote static folder if it's the website
    # Local backend/app/static is usually empty or doesn't exist.
    
    items = os.listdir(local_app_dir)
    for item in items:
        if item == "__pycache__": continue
        if item == "static": continue # Skip static, it's handled by frontend deploy or exists on server
        
        local_path = os.path.join(local_app_dir, item)
        remote_path = f"{remote_app_dir}/{item}"
        
        if os.path.isfile(local_path):
            print(f"Uploading {item}...")
            sftp.put(local_path, remote_path)
        elif os.path.isdir(local_path):
            # For subdirectories like 'routers', 'core', we can just upload
            upload_dir(sftp, local_path, remote_path)

    # Upload root level files
    root_files = ["run.py", "requirements.txt", "create_db.py", "reset_schema.py", "update_schema.py"]
    for f in root_files:
        local_p = os.path.join(BACKEND_DIR, f)
        if os.path.exists(local_p):
            print(f"Uploading {f}...")
            sftp.put(local_p, f"{REMOTE_BASE}/{f}")

    # Upload 'files' directory (Installer)
    local_files_dir = os.path.join(BACKEND_DIR, "files")
    
    # Check deployment/releases for the latest version zip
    # We DO NOT rename it to DeskCare_Setup.zip anymore to avoid confusion
    # We upload it as is, and backend will find the latest version dynamically
    deployment_releases_dir = os.path.join(BASE_DIR, "deployment", "releases")
    if os.path.exists(deployment_releases_dir):
        # Find latest zip with semantic version sorting
        files = [f for f in os.listdir(deployment_releases_dir) if f.startswith("DeskCare_v") and f.endswith(".zip")]
        if files:
            def version_key(filename):
                # Extract "1.0.9" from "DeskCare_v1.0.9.zip"
                try:
                    v_str = filename.replace("DeskCare_v", "").replace(".zip", "")
                    return tuple(map(int, v_str.split(".")))
                except:
                    return (0, 0, 0)

            files.sort(key=version_key)
            latest_zip = files[-1]
            src_zip = os.path.join(deployment_releases_dir, latest_zip)
            
            # Ensure local backend/files exists
            if not os.path.exists(local_files_dir):
                os.makedirs(local_files_dir)
                
            # Copy to backend/files with ORIGINAL NAME
            dest_zip = os.path.join(local_files_dir, latest_zip)
            
            # Remove ALL files in local backend/files to ensure clean state
            # This prevents uploading stale files like DeskCare_Setup.exe or old zips
            for f in os.listdir(local_files_dir):
                file_path = os.path.join(local_files_dir, f)
                try:
                    if os.path.isfile(file_path):
                        os.unlink(file_path)
                    elif os.path.isdir(file_path):
                        shutil.rmtree(file_path)
                except Exception as e:
                    print(f"Failed to delete {file_path}: {e}")
            
            print(f"Copying latest release {latest_zip} to {dest_zip}...")
            shutil.copy2(src_zip, dest_zip)
            
            # Automatically update version_info.json based on the latest zip filename
            # This ensures the version info is ALWAYS in sync with the uploaded file
            try:
                # Extract version from filename: DeskCare_v1.0.8.zip -> 1.0.8
                v_str = latest_zip.replace("DeskCare_v", "").replace(".zip", "")
                parts = list(map(int, v_str.split(".")))
                if len(parts) == 3:
                    new_version_data = {
                        "major": parts[0],
                        "minor": parts[1],
                        "patch": parts[2],
                        "version": v_str,
                        "latest_version": v_str
                    }
                    print(f"Updating version_info.json to match release: {v_str}")
                    with open(os.path.join(local_files_dir, "version_info.json"), "w") as f:
                        json.dump(new_version_data, f, indent=4)
            except Exception as e:
                print(f"Failed to auto-update version_info.json: {e}")
                # Fallback to copying existing file if auto-update fails
                if os.path.exists(VERSION_FILE):
                    print(f"Copying existing version_info.json to {local_files_dir}...")
                    shutil.copy2(VERSION_FILE, os.path.join(local_files_dir, "version_info.json"))

    # Force upload files directory if it exists, EVEN IF no new zip found (to update version_info.json)
    if os.path.exists(local_files_dir):
        print("Uploading files directory (Installer & Version Info)...")
        remote_files_dir = f"{REMOTE_BASE}/files"
        run_remote(client, f"mkdir -p {remote_files_dir}", True)
        
        # Clean remote files directory before uploading new version to save space
        # This removes all files in files/ so only the latest version remains
        print("Cleaning old remote release files...")
        run_remote(client, f"rm -rf {remote_files_dir}/*", True)
        
        upload_dir(sftp, local_files_dir, remote_files_dir)
        
        # Ensure version_info.json has correct permissions
        run_remote(client, f"chmod 644 {remote_files_dir}/version_info.json", True)

    # 3. Update Dependencies
    print("Checking dependencies...")
    # Using the virtualenv on server
    run_remote(client, f"{REMOTE_BASE}/venv/bin/pip install -r {REMOTE_BASE}/requirements.txt")
    
    # 3.1 Setup Database
    # We only run create_db.py to ensure tables exist, but NEVER reset/drop tables in normal deploy
    print("Ensuring database tables exist...")
    out_create = run_remote(client, f"cd {REMOTE_BASE} && {REMOTE_BASE}/venv/bin/python create_db.py")
    print(out_create)
    
    # 3.2 Update Schema (Safe Migration)
    print("Updating database schema (if needed)...")
    out_update = run_remote(client, f"cd {REMOTE_BASE} && {REMOTE_BASE}/venv/bin/python update_schema.py")
    print(out_update)
    
    # DANGEROUS: Do NOT run reset_schema.py unless explicitly requested!
    # out_reset = run_remote(client, f"cd {REMOTE_BASE} && {REMOTE_BASE}/venv/bin/python reset_schema.py")
    # print(out_reset)
    
    # 4. Restart Service
    print("Restarting service...")
    run_remote(client, "systemctl daemon-reload")
    run_remote(client, "systemctl restart deskcare")
    
    # Force reload again to pick up new directories
    time.sleep(2)
    run_remote(client, "systemctl restart deskcare")
    
    # 5. Verify
    print("Verifying deployment...")
    status = run_remote(client, "systemctl is-active deskcare", True)
    print(f"Service status: {status}")
    
    # API Check (Health Check)
    print("Performing API Health Check...")
    
    # 1. Local Check (on server) - This checks if the service itself started correctly
    print("1. Server Self-Check (curl localhost)...")
    # Wait a bit for service to start
    time.sleep(5)
    
    # Try port 80 first, then 8000
    local_check = run_remote(client, "curl -s -o /dev/null -w '%{http_code}' http://localhost:80/api/status", True)
    target_port = 80
    
    if local_check != "200":
        print("   Port 80 check failed, trying port 8000...")
        local_check = run_remote(client, "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/api/status", True)
        target_port = 8000
    
    if local_check == "200":
        print(f"✅ Service is running internally on port {target_port}.")
        
        # 2. Remote Check (from YOUR computer to Cloud Server)
        print(f"2. Public Access Check (http://{HOST}:{target_port})...")
        try:
            import urllib.request
            # Check public IP
            with urllib.request.urlopen(f"http://{HOST}:{target_port}/api/status", timeout=5) as response:
                if response.status == 200:
                    print("✅ Public access successful!")
                else:
                    print(f"⚠️  Public access returned status {response.status}.")
        except Exception as e:
            print(f"❌ Public access failed: {e}")
            print("   Possible causes:")
            print(f"   - Cloud Provider Firewall (Security Group) blocks port {target_port}")
            print(f"   - Server Firewall (UFW/iptables) blocks port {target_port}")
            print(f"   Action: Please open TCP port {target_port} in your cloud console.")
            
    else:
        print(f"❌ Service failed to start (Internal Check: {local_check}).")
        print("Fetching service logs...")
        logs = run_remote(client, "journalctl -u deskcare -n 50 --no-pager", True)
        print("========== SERVICE LOGS ==========")
        print(logs)
        print("==================================")

    print("Backend deployment complete.")

def get_latest_zip():
    # Find DeskCare_vX.X.X.zip in RELEASES_DIR
    import glob
    releases_dir = os.path.join(BASE_DIR, "deployment", "releases")
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

def run_mysql(client, sql, password="pass"):
    """Helper to run SQL command with or without password"""
    # Try with password first (most likely case for re-runs)
    cmd_with_pass = f'mysql -u root -p"{password}" -e "{sql}"'
    print(f"Executing SQL (with password): {sql}")
    out = run_remote(client, cmd_with_pass, ignore_errors=True)
    
    # Check if successful (empty output or standard output is fine, but error usually goes to stderr which run_remote prints)
    # However, run_remote with ignore_errors=True returns stdout.
    # We can't easily check exit code with current run_remote implementation without modifying it.
    # Let's modify run_remote to return (exit_code, stdout, stderr) or just check the output for "Access denied"
    
    # Actually, let's just try without password if the first one failed?
    # But run_remote doesn't tell us if it failed.
    # Let's assume we can chain them: try password OR try no password.
    
    # Better approach:
    # 1. Create a temporary .my.cnf with the password
    # 2. Run command
    # 3. If that fails, run without .my.cnf
    pass

def setup_mysql(client):
    print("--- Setting up MySQL ---")
    
    # 1. Install MySQL Server
    print("Installing MySQL Server...")
    run_remote(client, "apt-get update", True)
    run_remote(client, "DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server net-tools", True)
    
    # 2. Configure root password and access
    print("Configuring Database...")
    
    # Define SQL commands
    sql_commands = [
        # Set root password for localhost
        "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'pass';",
        # Create Database
        "CREATE DATABASE IF NOT EXISTS deskcare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;",
        # Create remote root user - FIX: Drop first to ensure clean recreation if password/host changed
        "DROP USER IF EXISTS 'root'@'%';",
        "CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'pass';",
        "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;",
        "FLUSH PRIVILEGES;"
    ]
    
    # Strategy: 
    # Since we don't know the current state (fresh install vs existing password),
    # we'll try to execute each command using BOTH authentication methods.
    # This is a bit brute-force but robust for this script.
    
    for sql in sql_commands:
        # Escape double quotes in SQL for the shell command
        safe_sql = sql.replace('"', '\\"')
        
        # Method A: Try with password
        cmd_a = f'mysql -u root -ppass -e "{safe_sql}"'
        # Method B: Try without password (sudo mysql default)
        cmd_b = f'mysql -e "{safe_sql}"'
        
        print(f"Executing: {sql}")
        # We run both. One should succeed, the other might fail.
        # We silence errors to avoid confusing the user, as one failure is expected.
        run_remote(client, f"{cmd_a} || {cmd_b}", ignore_errors=True)
        
    # 3. Allow remote access (bind-address)
    print("Configuring remote access...")
    # Change bind-address by adding a new config file (more reliable than sed)
    remote_conf = "[mysqld]\nbind-address = 0.0.0.0\n"
    # Write to a location that overrides default
    run_remote(client, f"echo '{remote_conf}' > /etc/mysql/mysql.conf.d/99-remote.cnf", True)
    
    # 4. Configure Firewall (UFW)
    print("Configuring Firewall (UFW)...")
    run_remote(client, "ufw allow 3306/tcp", True)
    run_remote(client, "ufw reload", True)

    # 5. Restart MySQL
    print("Restarting MySQL...")
    run_remote(client, "systemctl restart mysql")
    
    # 6. Verify Port Listening
    print("Verifying MySQL is listening on 0.0.0.0:3306...")
    status = run_remote(client, "netstat -tuln | grep 3306", True)
    print(f"Server Port Status: {status}")
    
    if "0.0.0.0:3306" in status or ":::3306" in status:
        print("✅ MySQL is correctly listening on all interfaces.")
    else:
        print("❌ MySQL might not be listening correctly. Please check server logs.")

    print("\n" + "="*60)
    print("MySQL Setup Complete!")
    print("IMPORTANT: If you still cannot connect, please check your Cloud Provider's Security Group (Firewall).")
    print("Ensure that TCP port 3306 is open for Inbound traffic.")
    print("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(description="DeskCare Automated Deployment Tool")
    parser.add_argument("mode", choices=["all", "backend", "frontend", "app", "setup_mysql"], 
                        help="Deployment mode: all, backend, frontend, app, or setup_mysql (install db)")
    
    args = parser.parse_args()
    
    print(f"Starting deployment in [{args.mode}] mode...")
    
    try:
        client = create_client()
        sftp = client.open_sftp()
    except Exception as e:
        print(f"Connection failed: {e}")
        sys.exit(1)

    if args.mode == "setup_mysql":
        setup_mysql(client)
        # Also deploy backend to update config
        deploy_backend_only(client, sftp)

    if args.mode == "frontend" or args.mode == "all":
        deploy_frontend_only(client, sftp)
        
    if args.mode == "backend" or args.mode == "all":
        deploy_backend_only(client, sftp)
        
    if args.mode == "app" or args.mode == "all":
        # Check deployment/releases for the latest version zip
        # We need to manually trigger the file upload logic here if not already done by deploy_backend_only
        # But wait, deploy_backend_only already includes the file upload logic!
        # If mode is 'app', we should probably just run the file upload part.
        # However, for simplicity and robustness, let's just reuse deploy_backend_only
        # as it handles version syncing and everything properly.
        # Re-running backend deploy is safe and ensures config consistency.
        if args.mode == "app": # If 'all', it's already run above
             deploy_backend_only(client, sftp)

    sftp.close()
    client.close()
    print("All tasks finished.")

if __name__ == "__main__":
    main()
