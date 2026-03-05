import paramiko
import sys

HOST = "47.101.52.0"
USER = "root"
PASS = "Pass1234"

def debug_server():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        print(f"Connecting to {HOST}...")
        client.connect(HOST, username=USER, password=PASS)
        
        # 1. Check main.py content
        print("\n--- /opt/deskcare/app/main.py ---")
        stdin, stdout, stderr = client.exec_command("cat /opt/deskcare/app/main.py")
        print(stdout.read().decode())
        
        # 2. Check static files
        print("\n--- /opt/deskcare/static listing ---")
        stdin, stdout, stderr = client.exec_command("ls -F /opt/deskcare/static")
        print(stdout.read().decode())
        
        print("\n--- /opt/deskcare/static/assets listing ---")
        stdin, stdout, stderr = client.exec_command("ls -F /opt/deskcare/static/assets")
        print(stdout.read().decode())

    except Exception as e:
        print(f"Error: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    debug_server()
