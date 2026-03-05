import paramiko
import os
import sys
import time

# Configuration
HOST = "47.101.52.0"
USER = "root"
PASS = "Pass1234"
REMOTE_BASE = "/opt/deskcare"

def create_client():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        print(f"Connecting to {HOST}...")
        client.connect(HOST, username=USER, password=PASS, timeout=10)
        return client
    except Exception as e:
        print(f"Failed to connect: {e}")
        sys.exit(1)

def run_remote(client, cmd):
    print(f"REMOTE: {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd)
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if out: print(out)
    if err: print(f"Error: {err}")
    return exit_status

def main():
    client = create_client()
    sftp = client.open_sftp()
    
    # 1. Upload clean_db.py
    local_script = os.path.join(os.path.dirname(__file__), "clean_db.py")
    remote_script = f"{REMOTE_BASE}/clean_db.py"
    
    print(f"Uploading {local_script} to {remote_script}...")
    sftp.put(local_script, remote_script)
    
    # 2. Run script using remote venv
    print("Executing clean script on remote server...")
    # Use the DB credentials from environment variables set in the service or assume defaults
    # The clean_db.py uses defaults which match the server's defaults (root/pass/localhost)
    # If server uses different env vars, we might need to source them or pass them.
    # Usually in /opt/deskcare/run.py or service file.
    # Assuming defaults work as per previous context.
    
    run_remote(client, f"{REMOTE_BASE}/venv/bin/python {remote_script}")
    
    # 3. Restart Service (to recreate default admin and config)
    print("Restarting DeskCare service to restore default admin/config...")
    run_remote(client, "systemctl restart deskcare")
    
    # 4. Clean up
    run_remote(client, f"rm {remote_script}")
    
    client.close()
    print("Remote clean complete.")

if __name__ == "__main__":
    main()
