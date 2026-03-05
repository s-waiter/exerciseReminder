import requests
import json

BASE_URL = "http://47.101.52.0"

def debug_website_stats():
    print(f"Target: {BASE_URL}")
    
    # 1. Login
    print("\n1. Logging in...")
    try:
        resp = requests.post(f"{BASE_URL}/api/admin/login", json={"username": "root", "password": "pass"})
        if resp.status_code != 200:
            print(f"Login failed: {resp.status_code} {resp.text}")
            return
        
        data = resp.json()
        token = data.get("access_token")
        print(f"Login success. Token: {token[:10]}...")
    except Exception as e:
        print(f"Login error: {e}")
        return

    # 2. Fetch Website Stats
    print("\n2. Fetching Website Stats...")
    try:
        resp = requests.get(f"{BASE_URL}/api/admin/stats/website", params={"token": token})
        if resp.status_code != 200:
            print(f"Fetch stats failed: {resp.status_code} {resp.text}")
            return
            
        stats = resp.json()
        print("Fetch success.")
        
        # Analyze Trend Data
        trend = stats.get("trend", [])
        print(f"Trend data length: {len(trend)}")
        if len(trend) > 0:
            print("First item:", trend[0])
            print("Last item:", trend[-1])
            
            # Check for non-zero data
            non_zero = [t for t in trend if t['pv'] > 0 or t['uv'] > 0]
            print(f"Non-zero days: {len(non_zero)}")
            if non_zero:
                print("Sample non-zero:", non_zero[0])
        else:
            print("Trend data is empty!")

        # Analyze Logs
        logs = stats.get("logs", [])
        print(f"\nLogs length: {len(logs)}")
        if len(logs) > 0:
            print("First log:", logs[0])
            
    except Exception as e:
        print(f"Fetch stats error: {e}")

if __name__ == "__main__":
    debug_website_stats()
