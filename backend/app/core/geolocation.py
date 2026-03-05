import geoip2.database
import os
import json
import urllib.request

GEOIP_DB_PATH = os.path.join(os.path.dirname(__file__), "GeoLite2-City.mmdb")

def get_location(ip: str) -> str:
    # 1. Try Local DB
    if os.path.exists(GEOIP_DB_PATH):
        try:
            with geoip2.database.Reader(GEOIP_DB_PATH) as reader:
                response = reader.city(ip)
                city = response.city.name or "Unknown City"
                country = response.country.name or "Unknown Country"
                return f"{city}, {country}"
        except Exception as e:
            print(f"GeoIP DB Error: {e}")
            pass # Fallback to API
            
    # 2. Try Online API (ip-api.com) - Free for non-commercial use
    try:
        # ip-api.com/json/{ip}?lang=zh-CN
        url = f"http://ip-api.com/json/{ip}?lang=zh-CN"
        with urllib.request.urlopen(url, timeout=2) as response:
            data = json.loads(response.read().decode())
            if data['status'] == 'success':
                city = data.get('city', '')
                region = data.get('regionName', '')
                country = data.get('country', '')
                # Format: Shanghai, China or just China
                loc_parts = [p for p in [city, region, country] if p]
                return ", ".join(loc_parts) if loc_parts else "Unknown Location"
    except Exception as e:
        print(f"GeoIP API Error: {e}")
        
    return "Unknown (DB Missing & API Failed)"
