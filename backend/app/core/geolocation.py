import geoip2.database
import os

GEOIP_DB_PATH = os.path.join(os.path.dirname(__file__), "GeoLite2-City.mmdb")

def get_location(ip: str) -> str:
    if not os.path.exists(GEOIP_DB_PATH):
        return "Unknown (DB Missing)"
    
    try:
        with geoip2.database.Reader(GEOIP_DB_PATH) as reader:
            response = reader.city(ip)
            city = response.city.name or "Unknown City"
            country = response.country.name or "Unknown Country"
            return f"{city}, {country}"
    except Exception as e:
        return f"Error: {str(e)}"
