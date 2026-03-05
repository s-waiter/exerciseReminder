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
        print("\n--- /opt/deskcare/app/main.py (Head) ---")
        stdin, stdout, stderr = client.exec_command("head -n 100 /opt/deskcare/app/main.py")
        print(stdout.read().decode())
        
        # 2. Check logs
        print("\n--- Logs (Last 50) ---")
        stdin, stdout, stderr = client.exec_command("journalctl -u deskcare -n 50 --no-pager")
        print(stdout.read().decode())

    except Exception as e:
        print(f"Error: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    debug_server()
