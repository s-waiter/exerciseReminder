from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request, Header
from sqlalchemy.orm import Session
from .. import crud, models, schemas
from ..database import get_db, SessionLocal
from ..core.geolocation import get_location
from datetime import date

router = APIRouter(
    prefix="/analytics",
    tags=["analytics"]
)

# Compatibility Router for legacy client
legacy_router = APIRouter(
    prefix="/api",
    tags=["legacy"]
)

from user_agents import parse
from typing import Optional

def process_visit_log(ip: str, path: str, user_agent: str, referrer: str):
    db = SessionLocal()
    try:
        location = get_location(ip)
        
        # Parse User Agent
        ua_string = user_agent
        os_info = "Unknown"
        browser_info = "Unknown"
        device_type = "PC"
        
        try:
            ua = parse(ua_string)
            os_info = ua.os.family
            browser_info = ua.browser.family
            if ua.is_mobile:
                device_type = "Mobile"
            elif ua.is_tablet:
                device_type = "Tablet"
            elif ua.is_pc:
                device_type = "PC"
            elif ua.is_bot:
                device_type = "Bot"
        except:
            pass

        visit = schemas.WebsiteVisitCreate(
            ip_address=ip,
            path=path,
            user_agent=user_agent,
            geo_location=location,
            referrer=referrer,
            os=os_info,
            browser=browser_info,
            device_type=device_type
        )
        crud.create_website_visit(db, visit)
    finally:
        db.close()

def process_usage_log(uid: str, version: str, ip: str):
    db = SessionLocal()
    try:
        location = get_location(ip)
        usage = schemas.DailyUsageCreate(
            date=date.today(),
            uid=uid,
            version=version,
            ip_address=ip,
            geo_location=location
        )
        crud.record_daily_usage(db, usage)
    finally:
        db.close()

@router.get("/visit")
async def record_visit(request: Request, background_tasks: BackgroundTasks, user_agent: str = Header(None), referer: Optional[str] = Header(None)):
    ip = request.client.host
    
    current_page = referer if referer else "Direct/Unknown"
    
    # Check if user_agent looks like a browser
    is_bot = False
    try:
        ua = parse(user_agent)
        if ua.is_bot:
            is_bot = True
    except:
        pass
        
    # Create the visit immediately and return ID
    db = SessionLocal()
    try:
        location = get_location(ip)
        
        # Parse User Agent
        ua_string = user_agent
        os_info = "Unknown"
        browser_info = "Unknown"
        device_type = "PC"
        
        try:
            ua = parse(ua_string)
            os_info = ua.os.family
            browser_info = ua.browser.family
            if ua.is_mobile:
                device_type = "Mobile"
            elif ua.is_tablet:
                device_type = "Tablet"
            elif ua.is_pc:
                device_type = "PC"
            elif ua.is_bot:
                device_type = "Bot"
        except:
            pass

        visit = models.WebsiteVisit(
            ip_address=ip,
            path=current_page,
            user_agent=user_agent,
            geo_location=location,
            referrer=referer,
            os=os_info,
            browser=browser_info,
            device_type=device_type
        )
        db.add(visit)
        db.commit()
        db.refresh(visit)
        return {"status": "ok", "visit_id": visit.id}
    except Exception as e:
        print(f"Error recording visit: {e}")
        return {"status": "error"}
    finally:
        db.close()

@router.post("/duration/{visit_id}")
async def update_duration(visit_id: int, duration: int):
    db = SessionLocal()
    try:
        visit = db.query(models.WebsiteVisit).filter(models.WebsiteVisit.id == visit_id).first()
        if visit:
            visit.duration_seconds = duration
            db.commit()
            return {"status": "updated"}
        return {"status": "not_found"}
    finally:
        db.close()

@router.post("/download/{visit_id}")
async def record_download(visit_id: int, version: str):
    db = SessionLocal()
    try:
        visit = db.query(models.WebsiteVisit).filter(models.WebsiteVisit.id == visit_id).first()
        if visit:
            visit.is_downloaded = True
            visit.downloaded_version = version
            db.commit()
            return {"status": "recorded"}
        return {"status": "not_found"}
    finally:
        db.close()



@router.get("/report")
@legacy_router.get("/report") # Support both /analytics/report and /api/report
async def report_usage(uid: str, ver: str, request: Request, background_tasks: BackgroundTasks):
    ip = request.client.host
    background_tasks.add_task(process_usage_log, uid, ver, ip)
    return {"status": "recorded"}

@router.get("/stats/dau")
async def get_dau(day: date = None, db: Session = Depends(get_db)):
    if not day:
        day = date.today()
    count = crud.get_daily_active_users(db, day)
    return {"date": day, "active_users": count}

@router.get("/stats/total_users")
async def get_total(db: Session = Depends(get_db)):
    count = crud.get_total_users(db)
    return {"total_unique_users": count}
