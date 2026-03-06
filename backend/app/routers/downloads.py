from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request, Body
from fastapi.responses import FileResponse, JSONResponse
from sqlalchemy.orm import Session
from .. import crud, models, schemas
from ..database import get_db, SessionLocal
import os
from datetime import datetime
import uuid

router = APIRouter(
    prefix="/api/downloads",
    tags=["download"]
)

# Configuration: Path to the installer
# Ensure this directory exists and contains the installer
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def get_latest_version_file(directory):
    """Helper to find the latest versioned zip file in a directory using semantic versioning."""
    if not os.path.exists(directory):
        return None
        
    files = [f for f in os.listdir(directory) if f.startswith("DeskCare_v") and f.endswith(".zip")]
    if not files:
        return None
        
    def version_key(filename):
        # Extract "1.0.9" from "DeskCare_v1.0.9.zip"
        try:
            v_str = filename.replace("DeskCare_v", "").replace(".zip", "")
            return tuple(map(int, v_str.split(".")))
        except:
            return (0, 0, 0)

    files.sort(key=version_key)
    return os.path.join(directory, files[-1])

def get_installer_path():
    # 1. Search in Production/Standard Path (/opt/deskcare/files)
    prod_path = get_latest_version_file("/opt/deskcare/files")
    if prod_path:
        return prod_path
            
    # 2. Search in Local Dev Path (backend/files)
    local_path = get_latest_version_file(os.path.join(BASE_DIR, "files"))
    if local_path:
        return local_path

    # 3. Fallback: deployment/releases (Local Dev Only)
    try:
        releases_dir = os.path.join(os.path.dirname(BASE_DIR), "deployment", "releases")
        dev_path = get_latest_version_file(releases_dir)
        if dev_path:
            return dev_path
    except:
        pass
        
    return None

DOWNLOAD_FILE_PATH = None # Calculated per request now

@router.get("/status")
def get_download_status(db: Session = Depends(get_db)):
    config = crud.get_system_config(db, "require_download_code")
    return {"require_code": config.value == "true" if config else True}

@router.post("/verify")
def verify_code(code: str = Body(None, embed=True), db: Session = Depends(get_db)):
    # 1. Check Global Config
    config = crud.get_system_config(db, "require_download_code")
    require_code = config.value == "true" if config else True
    
    if not require_code:
        # If no code required, allow download immediately
        # Use a special 'public' code or just bypass
        return {"status": "valid", "download_url": "/api/downloads/file?code=public_access"}

    # 2. Verify Code
    if not code:
        raise HTTPException(status_code=400, detail="请输入下载码")

    db_key = crud.get_download_key(db, code)
    if not db_key:
        raise HTTPException(status_code=400, detail="无效的下载码")
    
    if db_key.is_used and db_key.type == "one_time":
        raise HTTPException(status_code=400, detail="此下载码已被使用")
        
    if db_key.type == "time_limited" and db_key.expires_at and datetime.now() > db_key.expires_at:
        raise HTTPException(status_code=400, detail="此下载码已过期")

    if db_key.max_uses and (db_key.usage_count or 0) >= db_key.max_uses:
        raise HTTPException(status_code=400, detail="此下载码已达到最大使用次数")

    return {"status": "valid", "download_url": f"/api/downloads/file?code={code}"}

@router.get("/file")
async def download_file(code: str, request: Request, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    # Re-evaluate path on each request in case file was added later
    current_file_path = get_installer_path()
    
    # 1. Check Global Config first
    config = crud.get_system_config(db, "require_download_code")
    require_code = config.value == "true" if config else True
    
    if not require_code and code == "public_access":
         if not current_file_path:
            return JSONResponse(status_code=404, content={"detail": "安装包文件未找到"})
         return FileResponse(current_file_path, media_type="application/zip", filename=os.path.basename(current_file_path))

    # 2. Verify Code
    db_key = crud.get_download_key(db, code)
    
    if not db_key:
         return JSONResponse(status_code=403, content={"detail": "无效的下载码"})
    
    if db_key.is_used and db_key.type == "one_time":
         return JSONResponse(status_code=403, content={"detail": "此下载码已被使用"})

    if db_key.type == "time_limited" and db_key.expires_at and datetime.now() > db_key.expires_at:
         return JSONResponse(status_code=403, content={"detail": "此下载码已过期"})

    if db_key.max_uses and (db_key.usage_count or 0) >= db_key.max_uses:
         return JSONResponse(status_code=403, content={"detail": "此下载码已达到最大使用次数"})

    if not current_file_path:
        # Fallback for dev
        return JSONResponse(status_code=404, content={"detail": "安装包文件未找到"})

    # Mark as used (increments count, sets is_used if one_time)
    crud.mark_key_used(db, db_key, request.client.host)

    return FileResponse(current_file_path, media_type="application/zip", filename=os.path.basename(current_file_path))

def mark_key_bg(key_id: int, ip: str):
    db = SessionLocal()
    try:
        key = db.query(models.DownloadKey).filter(models.DownloadKey.id == key_id).first()
        if key:
            crud.mark_key_used(db, key, ip)
    except Exception as e:
        print(f"Error marking key: {e}")
    finally:
        db.close()
