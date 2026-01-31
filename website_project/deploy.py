import paramiko
import os
import sys
import json

# Configuration
HOSTNAME = '47.101.52.0'
USERNAME = 'root'
PASSWORD = 'Pass1234'
LOCAL_DIST_DIR = os.path.join(os.path.dirname(__file__), 'official_site', 'dist')
REMOTE_TEMP_DIR = '/tmp'

# Get project root to find dist zip and version info
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__)) # website_project
ROOT_ROOT = os.path.dirname(PROJECT_ROOT) # DeskCare root

def get_version_info():
    json_path = os.path.join(ROOT_ROOT, "version_info.json")
    if os.path.exists(json_path):
        with open(json_path, 'r') as f:
            v = json.load(f)
            return f"{v['major']}.{v['minor']}.{v['patch']}"
    return "1.0.0"

VERSION = get_version_info()
ZIP_FILENAME = f"DeskCare_v{VERSION}.zip"
# Zip file is in the project root, not in dist
LOCAL_ZIP_PATH = os.path.join(ROOT_ROOT, ZIP_FILENAME)

# Generate version.json for auto-update
def generate_version_json():
    import datetime
    data = {
        "latest_version": VERSION,
        "release_date": datetime.date.today().isoformat(),
        "download_url": f"http://{HOSTNAME}/updates/{ZIP_FILENAME}",
        "changelog": "最新版本，包含性能优化和错误修复。",
        "min_supported_version": "1.0.0"
    }
    path = os.path.join(PROJECT_ROOT, "version.json")
    with open(path, "w", encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    return path

def deploy():
    try:
        print(f"Connecting to {HOSTNAME}...")
        transport = paramiko.Transport((HOSTNAME, 22))
        transport.connect(username=USERNAME, password=PASSWORD)
        sftp = paramiko.SFTPClient.from_transport(transport)

        # 1. Upload Website Assets
        print(f"Uploading from {LOCAL_DIST_DIR} to {REMOTE_TEMP_DIR}...")
        for root, dirs, files in os.walk(LOCAL_DIST_DIR):
            for file in files:
                local_path = os.path.join(root, file)
                rel_path = os.path.relpath(local_path, LOCAL_DIST_DIR)
                remote_path = os.path.join(REMOTE_TEMP_DIR, rel_path).replace('\\', '/')
                
                # Create remote dir if not exists (simple check)
                remote_dir = os.path.dirname(remote_path)
                try:
                    sftp.stat(remote_dir)
                except FileNotFoundError:
                    # Recursive creation might be needed, but usually assets structure is simple
                    # For now, let's assume setup_remote.sh handles structure or we copy flat to /tmp
                    # Actually, our setup_remote.sh expects flat files in /tmp or specific folders
                    # Let's keep it simple: upload all to /tmp, but maintain assets folder
                    pass

                # Flatten for simplicity as per setup_remote.sh logic, 
                # OR upload structured if setup_remote.sh supports it.
                # Current setup_remote.sh handles /tmp/assets folder.
                
                # Special handling for assets dir
                if rel_path.startswith('assets'):
                    remote_asset_dir = os.path.join(REMOTE_TEMP_DIR, 'assets').replace('\\', '/')
                    try:
                        sftp.mkdir(remote_asset_dir)
                    except:
                        pass
                    remote_path = os.path.join(remote_asset_dir, os.path.basename(file)).replace('\\', '/')
                else:
                    remote_path = os.path.join(REMOTE_TEMP_DIR, file).replace('\\', '/')
                
                print(f"  Uploading {file}...")
                sftp.put(local_path, remote_path)

        # 2. Upload Config & Script
        print("Uploading config and scripts...")
        sftp.put(os.path.join(PROJECT_ROOT, 'deploy', 'setup_remote.sh'), '/tmp/setup_remote.sh')
        sftp.put(os.path.join(PROJECT_ROOT, 'deploy', 'exercise_site.conf'), '/tmp/exercise_site.conf')

        # 3. Upload Software Zip (for updates)
        if os.path.exists(LOCAL_ZIP_PATH):
            print(f"Uploading {ZIP_FILENAME}...")
            sftp.put(LOCAL_ZIP_PATH, f"/tmp/{ZIP_FILENAME}")
        else:
            print(f"[WARNING] Zip file not found at {LOCAL_ZIP_PATH}")

        # 4. Upload version.json
        version_json_path = generate_version_json()
        print("Uploading version.json...")
        sftp.put(version_json_path, "/tmp/version.json")

        # 5. Execute Remote Script
        print("Executing remote setup script...")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(HOSTNAME, username=USERNAME, password=PASSWORD)
        
        stdin, stdout, stderr = ssh.exec_command(f"bash /tmp/setup_remote.sh {ZIP_FILENAME}")
        
        # Print Output
        for line in stdout:
            print(line.strip())
        for line in stderr:
            print(line.strip())
            
        ssh.close()
        sftp.close()
        transport.close()
        print("Deployment successful!")

    except Exception as e:
        print(f"Deployment failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    deploy()
