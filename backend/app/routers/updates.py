from fastapi import APIRouter
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
async def get_version_info():
    # Final fix for paths:
    # 1. Check direct path relative to CWD (usually /opt/deskcare)
    # 2. Check absolute path on Linux
    # 3. Check relative to this file
    
    current_dir = os.path.dirname(os.path.abspath(__file__)) # app/routers
    app_dir = os.path.dirname(current_dir) # app
    base_dir = os.path.dirname(app_dir) # /opt/deskcare
    
    paths_to_check = [
        os.path.join(base_dir, "files", "version_info.json"),
        "/opt/deskcare/files/version_info.json",
        os.path.join("files", "version_info.json"),
        "files/version_info.json"
    ]
    
    for path in paths_to_check:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if data.get("version"):
                        return data
            except:
                continue
                
    return {
        "version": "1.0.0", 
        "description": "Default version (File not found)",
        "debug_checked_paths": paths_to_check,
        "current_working_dir": os.getcwd()
    }
