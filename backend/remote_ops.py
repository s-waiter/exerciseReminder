import paramiko
import sys
import time
import argparse

# Configuration (Shared with deploy_full.py, ideally should be in a config file)
HOST = "47.101.52.0"
USER = "root"
PASS = "Pass1234"

def create_client():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, username=USER, password=PASS)
    return client

def run_command(cmd):
    client = create_client()
    print(f"REMOTE [{HOST}]: {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd)
    
    # Stream output
    while True:
        line = stdout.readline()
        if not line:
            break
        print(line.strip())
        
    err = stderr.read().decode().strip()
    if err:
        print(f"STDERR: {err}")
        
    client.close()

def main():
    parser = argparse.ArgumentParser(description="DeskCare Remote Service Manager")
    parser.add_argument("action", choices=["start", "stop", "restart", "status", "logs"], help="Action to perform")
    args = parser.parse_args()

    if args.action == "start":
        run_command("systemctl start deskcare")
        print("Service start command sent.")
        time.sleep(2)
        run_command("systemctl status deskcare --no-pager")
        
    elif args.action == "stop":
        run_command("systemctl stop deskcare")
        print("Service stop command sent.")
        time.sleep(1)
        run_command("systemctl is-active deskcare")
        
    elif args.action == "restart":
        run_command("systemctl restart deskcare")
        print("Service restart command sent.")
        time.sleep(2)
        run_command("systemctl status deskcare --no-pager")
        
    elif args.action == "status":
        run_command("systemctl status deskcare --no-pager")
        
    elif args.action == "logs":
        print("Fetching last 50 lines of logs...")
        run_command("journalctl -u deskcare -n 50 --no-pager")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
        input("Press Enter to exit...")
