import paramiko
import sys
import time

HOST = "47.101.52.0"
USER = "root"
PASS = "Pass1234"

def check_server_health():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        print(f"Connecting to {HOST}...")
        client.connect(HOST, username=USER, password=PASS)
        
        # 1. Check Service Status
        print("\n--- Service Status ---")
        stdin, stdout, stderr = client.exec_command("systemctl status deskcare --no-pager")
        status_output = stdout.read().decode()
        print(status_output)
        
        if "Active: active (running)" in status_output:
            print("✅ Service is RUNNING")
        else:
            print("❌ Service is NOT running")
            
        # 2. Check Port 80
        print("\n--- Port 80 Check ---")
        stdin, stdout, stderr = client.exec_command("netstat -tuln | grep :80")
        print(stdout.read().decode())
        
        # 3. Check Recent Logs
        print("\n--- Recent Logs (Last 20) ---")
        stdin, stdout, stderr = client.exec_command("journalctl -u deskcare -n 20 --no-pager")
        print(stdout.read().decode())

    except Exception as e:
        print(f"Error: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    check_server_health()
