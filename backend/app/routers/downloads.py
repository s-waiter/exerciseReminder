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
DOWNLOAD_FILE_PATH = os.path.join(BASE_DIR, "files", "DeskCare_Setup.zip") 

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
    # 1. Check Global Config first
    config = crud.get_system_config(db, "require_download_code")
    require_code = config.value == "true" if config else True
    
    if not require_code and code == "public_access":
         if not os.path.exists(DOWNLOAD_FILE_PATH):
            return JSONResponse(status_code=404, content={"detail": "安装包文件未找到"})
         return FileResponse(DOWNLOAD_FILE_PATH, media_type="application/zip", filename="DeskCare_Setup.zip")

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

    if not os.path.exists(DOWNLOAD_FILE_PATH):
        # Fallback for dev
        return JSONResponse(status_code=404, content={"detail": "安装包文件未找到 (Dev Note: Place DeskCare_Setup.zip in backend/files/)"})

    # Mark as used (increments count, sets is_used if one_time)
    crud.mark_key_used(db, db_key, request.client.host)

    return FileResponse(DOWNLOAD_FILE_PATH, media_type="application/zip", filename="DeskCare_Setup.zip")

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
