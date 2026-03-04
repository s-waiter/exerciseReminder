from fastapi import APIRouter, Depends, HTTPException, Header, Request
from sqlalchemy.orm import Session
from .. import crud, models, schemas
from ..database import get_db

router = APIRouter(
    prefix="/backup",
    tags=["backup"]
)

@router.post("/upload")
async def upload_backup(backup: schemas.UserBackupBase, request: Request, db: Session = Depends(get_db)):
    # Validate UID?
    if not backup.uid:
        raise HTTPException(status_code=400, detail="UID is required")
    
    # Create or update
    ip = request.client.host
    backup_create = schemas.UserBackupCreate(
        uid=backup.uid,
        backup_data=backup.backup_data,
        ip_address=ip
    )
    
    db_backup = crud.create_or_update_backup(db, backup_create)
    return {"status": "success", "updated_at": db_backup.updated_at}

@router.get("/restore")
async def restore_backup(uid: str, db: Session = Depends(get_db)):
    db_backup = crud.get_backup(db, uid)
    if not db_backup:
        raise HTTPException(status_code=404, detail="No backup found for this UID")
    
    return {
        "uid": db_backup.uid,
        "backup_data": db_backup.backup_data,
        "updated_at": db_backup.updated_at
    }
