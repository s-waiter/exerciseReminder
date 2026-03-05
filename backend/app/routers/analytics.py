from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request, Header, Body
from sqlalchemy.orm import Session
from .. import crud, models, schemas
from ..database import get_db, SessionLocal
from ..core.geolocation import get_location
from datetime import date
from typing import Optional
from user_agents import parse

router = APIRouter(
    prefix="/api/analytics",
    tags=["analytics"]
)

# --- Website Visits ---

@router.post("/visit")
async def record_visit(
    request: Request, 
    background_tasks: BackgroundTasks, 
    db: Session = Depends(get_db),
    user_agent: Optional[str] = Header(None), 
    referer: Optional[str] = Header(None),
    path: str = Body(..., embed=True)
):
    ip = request.client.host
    
    # Simple bot detection
    if user_agent:
        try:
            ua = parse(user_agent)
            if ua.is_bot:
                return {"status": "ignored_bot", "visit_id": None}
        except:
            pass

    # Create visit synchronously to get ID
    # Use placeholder for async fields
    visit_data = schemas.WebsiteVisitCreate(
        ip_address=ip,
        path=path,
        user_agent=user_agent or "Unknown",
        referrer=referer,
        city="Pending", # Will be updated async
        os="Unknown",
        browser="Unknown",
        device_type="Unknown"
    )
    
    db_visit = crud.create_website_visit(db, visit_data)
    
    # Background task to process detailed info (geo, ua parsing)
    background_tasks.add_task(process_visit_details, db_visit.id, ip, user_agent)
    
    return {"status": "ok", "visit_id": db_visit.id}

@router.post("/visit/{visit_id}/duration")
async def update_duration(
    visit_id: int,
    duration: int = Body(..., embed=True),
    db: Session = Depends(get_db)
):
    visit = db.query(models.WebsiteVisit).filter(models.WebsiteVisit.id == visit_id).first()
    if visit:
        visit.duration_seconds = duration
        db.commit()
    return {"status": "updated"}

@router.post("/visit/{visit_id}/download")
async def mark_download(
    visit_id: int,
    version: str = Body(None, embed=True),
    db: Session = Depends(get_db)
):
    visit = db.query(models.WebsiteVisit).filter(models.WebsiteVisit.id == visit_id).first()
    if visit:
        visit.is_download_click = True
        db.commit()
    return {"status": "marked"}

def process_visit_details(visit_id: int, ip: str, user_agent: str):
    db = SessionLocal()
    try:
        visit = db.query(models.WebsiteVisit).filter(models.WebsiteVisit.id == visit_id).first()
        if not visit: return

        # 1. Geo
        visit.city = get_location(ip)
        
        # 2. UA
        if user_agent:
            try:
                ua = parse(user_agent)
                visit.os = ua.os.family
                visit.browser = ua.browser.family
                if ua.is_mobile:
                    visit.device_type = "Mobile"
                elif ua.is_tablet:
                    visit.device_type = "Tablet"
                elif ua.is_pc:
                    visit.device_type = "PC"
            except:
                pass
                
        db.commit()
    except Exception as e:
        print(f"Error processing visit details: {e}")
    finally:
        db.close()

# --- App Usage (DAU) ---

@router.post("/usage")
async def record_usage(
    request: Request,
    background_tasks: BackgroundTasks,
    uid: str = Body(...),
    version: str = Body(...)
):
    ip = request.client.host
    background_tasks.add_task(process_usage_log, uid, version, ip)
    return {"status": "ok"}


def process_usage_log(uid: str, version: str, ip: str):
    db = SessionLocal()
    try:
        city = get_location(ip)
        usage = schemas.AppUsageCreate(
            date=date.today(),
            uid=uid,
            version=version,
            ip_address=ip,
            city=city
        )
        crud.record_app_usage(db, usage)
    except Exception as e:
        print(f"Error processing usage log: {e}")
    finally:
        db.close()
