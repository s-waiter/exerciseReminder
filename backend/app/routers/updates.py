from fastapi import APIRouter, Request
import json
import os

router = APIRouter(
    prefix="/updates",
    tags=["updates"]
)

VERSION_FILE = os.path.join("files", "version_info.json")
# Fallback path if running from app directory
VERSION_FILE_ALT = os.path.join("..", "files", "version_info.json")

@router.get("/version.json")
async def get_version_info(request: Request):
    # Final fix for paths:
    # 1. Check direct path relative to CWD (usually /opt/deskcare)
    # 2. Check absolute path on Linux
    # 3. Check relative to this file
    
    current_dir = os.path.dirname(os.path.abspath(__file__)) # app/routers
    app_dir = os.path.dirname(current_dir) # app
    base_dir = os.path.dirname(app_dir) # /opt/deskcare or backend
    
    # Prioritize standard paths
    paths_to_check = [
        "/opt/deskcare/files/version_info.json",  # Production absolute path
        os.path.join(base_dir, "files", "version_info.json"), # Relative to app
        os.path.join(os.getcwd(), "files", "version_info.json"), # CWD
        os.path.join("files", "version_info.json") # Simple relative
    ]
    
    for path in paths_to_check:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    # Support both formats:
                    # 1. New format: {"major": 1, "minor": 0, "patch": 8}
                    # 2. Old format: {"version": "1.0.8"}
                    
                    version_str = data.get("version")
                    if not version_str and "major" in data:
                        version_str = f"{data['major']}.{data['minor']}.{data['patch']}"
                        
                    if version_str:
                        # Normalize version string to remove any 'v' prefix if present
                        clean_version = version_str.replace("v", "")
                        
                        # Generate absolute URL for desktop app compatibility
                        # The desktop app (Qt) might not handle relative URLs correctly or expects a full URL
                        base_url = str(request.base_url).rstrip("/")
                        download_link = f"{base_url}/api/downloads/file?code=public_access"
                        
                        return {
                            "version": clean_version,
                            "latest_version": clean_version, # Backward compat
                            "download_url": download_link, # Dynamic Absolute URL
                            "changelog": data.get("changelog", f"Update to version {clean_version}")
                        }
            except Exception as e:
                print(f"Error reading version file {path}: {e}")
                continue
                
    return {
        "version": "1.0.0", 
        "description": "Default version (File not found)",
        "debug_checked_paths": paths_to_check,
        "current_working_dir": os.getcwd()
    }
