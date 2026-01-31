import sys
import os

# Add user site-packages to path just in case
sys.path.append(r"C:\Users\admin\AppData\Roaming\Python\Python313\site-packages")

import paramiko

# Configuration
HOST = "47.101.52.0"
USER = "root"
PASS = "Pass1234"
PORT = 22

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DIST_DIR = os.path.join(BASE_DIR, "official_site", "dist")
DEPLOY_DIR = os.path.join(BASE_DIR, "deploy")

def create_ssh_client(server, port, user, password):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(server, port, user, password)
    return client

def upload_files(sftp, local_dir, remote_dir):
    print(f"Uploading from {local_dir} to {remote_dir}...")
    for root, dirs, files in os.walk(local_dir):
        # Create remote directories
        relative_path = os.path.relpath(root, local_dir)
        if relative_path == ".":
            remote_root = remote_dir
        else:
            remote_root = os.path.join(remote_dir, relative_path).replace("\\", "/")
        
        try:
            sftp.stat(remote_root)
        except IOError:
            sftp.mkdir(remote_root)
            
        for file in files:
            local_file = os.path.join(root, file)
            remote_file = os.path.join(remote_root, file).replace("\\", "/")
            print(f"  Uploading {file}...")
            sftp.put(local_file, remote_file)

def main():
    try:
        print(f"Connecting to {HOST}...")
        ssh = create_ssh_client(HOST, PORT, USER, PASS)
        sftp = ssh.open_sftp()

        # 1. Upload Build Artifacts (dist/* -> /tmp/)
        # We upload contents of dist to /tmp/ so setup_remote.sh finds index.html at /tmp/index.html
        if os.path.exists(DIST_DIR):
            upload_files(sftp, DIST_DIR, "/tmp")
        else:
            print(f"Error: {DIST_DIR} not found. Did you run 'npm run build'?")
            return

        # 2. Upload Deploy Scripts (deploy/* -> /tmp/)
        if os.path.exists(DEPLOY_DIR):
             upload_files(sftp, DEPLOY_DIR, "/tmp")
        
        # 3. Fix line endings just in case (Windows -> Linux)
        # Using dos2unix if available, or sed.
        print("Fixing line endings...")
        ssh.exec_command("sed -i 's/\r$//' /tmp/setup_remote.sh")
        
        # 4. Run Setup Script
        print("Running setup script...")
        stdin, stdout, stderr = ssh.exec_command("bash /tmp/setup_remote.sh")
        
        # Stream output
        while True:
            line = stdout.readline()
            if not line:
                break
            print(line.strip())
            
        err = stderr.read().decode()
        if err:
            print(f"Errors:\n{err}")

        sftp.close()
        ssh.close()
        print("Deployment finished successfully!")

    except Exception as e:
        print(f"Deployment failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
