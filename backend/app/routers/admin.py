from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from .. import crud, models, schemas
from ..database import get_db
import secrets
from datetime import datetime

router = APIRouter(
    prefix="/api/admin",
    tags=["admin"]
)

# Simple in-memory token store for demo purposes
# In production, use Redis or JWT
TOKENS = {}

def get_current_admin(token: str):
    if token not in TOKENS:
        raise HTTPException(status_code=401, detail="Invalid token")
    return TOKENS[token]

@router.post("/login")
def login(data: schemas.AdminLogin, db: Session = Depends(get_db)):
    user = crud.get_admin_user(db, data.username)
    if not user or not crud.verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    
    token = secrets.token_hex(16)
    TOKENS[token] = user.username
    return {"access_token": token, "token_type": "bearer"}

@router.get("/check-auth")
def check_auth(token: str):
    if token in TOKENS:
        return {"status": "ok", "user": TOKENS[token]}
    raise HTTPException(status_code=401, detail="Invalid token")

# --- Stats Endpoints ---

@router.get("/stats/overview")
def get_stats_overview(token: str, db: Session = Depends(get_db)):
    get_current_admin(token)
    return crud.get_stats_overview(db)

@router.get("/stats/website")
def get_website_stats(
    token: str, 
    date: str = None, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    get_current_admin(token)
    trend = crud.get_visit_trend(db, 90) # Show 90 days trend
    geo = crud.get_geo_distribution(db, 10)
    
    # Filter logs by date if provided
    logs = crud.get_website_logs(db, 0, limit, date)
    
    return {
        "trend": trend,
        "geo": geo,
        "logs": logs
    }

@router.get("/stats/app")
def get_app_stats(token: str, db: Session = Depends(get_db)):
    get_current_admin(token)
    trend = crud.get_dau_trend(db, 30)
    logs = crud.get_app_usage_logs(db, 0, 100)
    return {
        "trend": trend,
        "logs": logs
    }

# --- Download Code Management ---

@router.get("/codes")
def list_codes(token: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    get_current_admin(token)
    return crud.list_download_keys(db, skip, limit)

@router.post("/codes")
def generate_code(
    token: str, 
    key: str = Body(..., embed=True), 
    type: str = Body("one_time", embed=True), 
    days: int = Body(None, embed=True),
    max_uses: int = Body(None, embed=True),
    db: Session = Depends(get_db)
):
    get_current_admin(token)
    if crud.get_download_key(db, key):
        raise HTTPException(status_code=400, detail="Key already exists")
    
    if type == "time_limited" and not days:
        raise HTTPException(status_code=400, detail="Time limited keys require 'days' parameter")
        
    return crud.create_download_key(db, key, type, days, max_uses)

@router.delete("/codes/{key_id}")
def delete_code(token: str, key_id: int, db: Session = Depends(get_db)):
    get_current_admin(token)
    success = crud.delete_download_key(db, key_id)
    if not success:
        raise HTTPException(status_code=404, detail="Key not found")
    return {"status": "deleted"}

# --- System Config ---

@router.get("/config/download")
def get_download_config(token: str, db: Session = Depends(get_db)):
    get_current_admin(token)
    config = crud.get_system_config(db, "require_download_code")
    return {"require_download_code": config.value == "true" if config else True}

@router.post("/config/download")
def set_download_config(
    token: str, 
    require_download_code: bool = Body(..., embed=True), 
    db: Session = Depends(get_db)
):
    get_current_admin(token)
    crud.set_system_config(db, "require_download_code", "true" if require_download_code else "false")
    return {"status": "ok"}
