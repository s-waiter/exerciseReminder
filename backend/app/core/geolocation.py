import geoip2.database
import os
import json
import urllib.request

GEOIP_DB_PATH = os.path.join(os.path.dirname(__file__), "GeoLite2-City.mmdb")

def format_location(country, region, city):
    """
    Format location string according to Chinese conventions:
    1. If country is not "中国", include country name.
    2. Direct-controlled municipalities (Beijing, Shanghai, Tianjin, Chongqing): Only show City (e.g., "上海市").
    3. Others: Only show Province (Region) (e.g., "安徽省").
    """
    parts = []
    
    # 1. Country check
    if country and country != "中国" and country != "China":
        parts.append(country)

    # 2. Municipality check
    municipalities = ["北京", "上海", "天津", "重庆", "Beijing", "Shanghai", "Tianjin", "Chongqing"]
    is_municipality = False
    
    # Check region or city against municipality list
    # Usually region contains "Beijing" or "Shanghai"
    for m in municipalities:
        if m in region or m in city:
            is_municipality = True
            # For municipalities, we prefer the City name (e.g. "上海市") or Region name if it's cleaner
            # Usually API returns region="Shanghai", city="Shanghai"
            # Let's use the Chinese name + "市" if not present, but API usually returns full name
            # If region is "Shanghai", show "上海市"
            clean_name = m
            if m in ["Beijing", "Shanghai", "Tianjin", "Chongqing"]:
                # Translate to Chinese if needed, or just use what API gave if it's Chinese
                # But here we assume input might be Chinese if lang=zh-CN
                # If input is English, we might want to keep it or translate. 
                # Let's stick to what API gives but filter.
                pass
            
            # Simple logic: If it's a municipality, just show the region/city name once.
            # API (zh-CN) returns: regionName="上海", city="上海"
            # We want "上海市"
            final_city = city if city else region
            if not final_city.endswith("市"):
                final_city += "市"
            parts.append(final_city)
            break
            
    if not is_municipality:
        # 3. Non-municipality: Show Province only (e.g. "安徽省")
        # API returns regionName="安徽", city="合肥"
        # We only want "安徽省"
        if region:
            final_region = region
            # Add "省" if missing and it's a Chinese province name (length 2-3 usually)
            # Avoid adding to "Inner Mongolia" or long names if already present
            if len(final_region) <= 3 and not final_region.endswith("省") and not final_region.endswith("自治区"):
                 # Check if it's a province (heuristic)
                 final_region += "省"
            parts.append(final_region)
        elif city:
             # Fallback to city if region is missing
             parts.append(city)
             
    return " ".join(parts)

def get_location(ip: str) -> str:
    # 1. Try Local DB
    if os.path.exists(GEOIP_DB_PATH):
        try:
            with geoip2.database.Reader(GEOIP_DB_PATH) as reader:
                response = reader.city(ip)
                # Local DB usually returns English names or names map
                # We need to handle language. GeoIP2 has names map.
                city = response.city.names.get('zh-CN', response.city.name)
                country = response.country.names.get('zh-CN', response.country.name)
                # Region/Subdivision
                region = ""
                if response.subdivisions.most_specific:
                     region = response.subdivisions.most_specific.names.get('zh-CN', response.subdivisions.most_specific.name)

                return format_location(country, region, city)
        except Exception as e:
            # print(f"GeoIP DB Error: {e}")
            pass # Fallback to API
            
    # 2. Try Online API (ip-api.com) - Free for non-commercial use
    # Using 'zh-CN' to get Chinese city names
    try:
        # ip-api.com/json/{ip}?lang=zh-CN
        url = f"http://ip-api.com/json/{ip}?lang=zh-CN"
        # Set a User-Agent to avoid being blocked by some APIs
        req = urllib.request.Request(url, headers={'User-Agent': 'DeskCare-Backend/1.0'})
        
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data['status'] == 'success':
                city = data.get('city', '')
                region = data.get('regionName', '') # Province/State
                country = data.get('country', '')
                
                return format_location(country, region, city)
                     
    except Exception as e:
        print(f"GeoIP API Error (ip-api.com): {e}")
        
    # 3. Fallback to another API (ipwhois.app) if the first one fails
    # This provides redundancy
    try:
        url = f"http://ipwhois.app/json/{ip}?lang=zh-CN"
        req = urllib.request.Request(url, headers={'User-Agent': 'DeskCare-Backend/1.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data.get('success', False):
                city = data.get('city', '')
                region = data.get('region', '')
                country = data.get('country', '')
                
                return format_location(country, region, city)

    except Exception as e:
        print(f"GeoIP API Error (ipwhois.app): {e}")

    return "Unknown"
