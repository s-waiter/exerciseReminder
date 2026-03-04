from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from .. import crud, models, schemas
from ..database import get_db, SessionLocal
from ..core.geolocation import get_location
import os
from datetime import datetime
import uuid

router = APIRouter(
    prefix="/download",
    tags=["download"]
)

# Configuration: Path to the installer
# Ensure this directory exists and contains the installer
DOWNLOAD_FILE_PATH = os.path.join("files", "DeskCare_Setup.exe")

def log_download_bg(key_id: int, ip: str, version: str):
    db = SessionLocal()
    try:
        location = get_location(ip)
        log = schemas.DownloadLogCreate(
            key_id=key_id,
            ip_address=ip,
            geo_location=location,
            version=version
        )
        crud.create_download_log(db, log)
    except Exception as e:
        print(f"Error logging download: {e}")
    finally:
        db.close()

def mark_key_bg(key_id: int):
    db = SessionLocal()
    try:
        key = db.query(models.DownloadKey).filter(models.DownloadKey.id == key_id).first()
        if key:
            key.is_used = True
            key.used_at = datetime.now()
            db.commit()
    finally:
        db.close()

@router.get("/{key}")
async def download_file(key: str, request: Request, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    db_key = crud.get_download_key(db, key)
    
    if not db_key:
        raise HTTPException(status_code=403, detail="无效的下载秘钥 (Invalid Key)")
    
    if db_key.is_used:
        # Option: Allow re-download within X hours? Or just strict one-time?
        # For now, strict one-time but maybe warn user.
        # But if download fails, user is stuck.
        # Better: Allow multiple downloads, but log all.
        # If strict policy required:
        # raise HTTPException(status_code=410, detail="此秘钥已被使用 (Key Already Used)")
        pass

    # Check file existence
    if not os.path.exists(DOWNLOAD_FILE_PATH):
        raise HTTPException(status_code=404, detail="安装包文件未找到 (File Not Found)")

    # Mark as used (if first time)
    if not db_key.is_used:
        background_tasks.add_task(mark_key_bg, db_key.id)

    # Log the download
    client_ip = request.client.host
    version = "latest" # TODO: Read from version file
    background_tasks.add_task(log_download_bg, db_key.id, client_ip, version)

    return FileResponse(DOWNLOAD_FILE_PATH, media_type="application/octet-stream", filename="DeskCare_Setup.exe")

@router.post("/generate_key")
async def generate_key(admin_secret: str, count: int = 1, db: Session = Depends(get_db)):
    # Simple admin check
    if admin_secret != "TraeAdmin2026": 
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    keys = []
    for _ in range(count):
        # Generate a random 8-char key (e.g. A1B2-C3D4 style or simple alphanumeric)
        key_str = str(uuid.uuid4()).split('-')[0].upper()
        
        # Ensure uniqueness
        while crud.get_download_key(db, key_str):
            key_str = str(uuid.uuid4()).split('-')[0].upper()
            
        crud.create_download_key(db, key_str)
        keys.append(key_str)
    
    return {"generated_keys": keys}

@router.get("/keys/list")
async def list_keys(admin_secret: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    if admin_secret != "TraeAdmin2026":
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    keys = db.query(models.DownloadKey).offset(skip).limit(limit).all()
    return keys
