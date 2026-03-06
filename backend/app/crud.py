from sqlalchemy.orm import Session
from . import models, schemas
from datetime import date, datetime, timedelta
from sqlalchemy import func
import hashlib

# --- Download Keys ---
def get_download_key(db: Session, key: str):
    return db.query(models.DownloadKey).filter(models.DownloadKey.key == key).first()

def create_download_key(db: Session, key: str, type: str = "one_time", expires_in_days: int = None, max_uses: int = None):
    expires_at = None
    if type == "time_limited" and expires_in_days:
        expires_at = datetime.now() + timedelta(days=expires_in_days)
        
    db_key = models.DownloadKey(key=key, type=type, expires_at=expires_at, max_uses=max_uses)
    db.add(db_key)
    db.commit()
    db.refresh(db_key)
    return db_key

def list_download_keys(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.DownloadKey).order_by(models.DownloadKey.created_at.desc()).offset(skip).limit(limit).all()

def delete_download_key(db: Session, key_id: int):
    db_key = db.query(models.DownloadKey).filter(models.DownloadKey.id == key_id).first()
    if db_key:
        db.delete(db_key)
        db.commit()
        return True
    return False

def mark_key_used(db: Session, db_key: models.DownloadKey, ip: str):
    db_key.usage_count = (db_key.usage_count or 0) + 1
    db_key.used_at = datetime.now()
    db_key.used_by_ip = ip
    
    if db_key.type == "one_time":
        db_key.is_used = True
        
    db.commit()
    db.refresh(db_key)
    return db_key

# --- System Config ---
def get_system_config(db: Session, key: str):
    return db.query(models.SystemConfig).filter(models.SystemConfig.key == key).first()

def set_system_config(db: Session, key: str, value: str):
    config = db.query(models.SystemConfig).filter(models.SystemConfig.key == key).first()
    if config:
        config.value = value
    else:
        config = models.SystemConfig(key=key, value=value)
        db.add(config)
    db.commit()
    db.refresh(config)
    return config

# --- Admin ---
def get_admin_user(db: Session, username: str):
    return db.query(models.AdminUser).filter(models.AdminUser.username == username).first()

def create_admin_user(db: Session, user: schemas.AdminLogin):
    # Simple SHA256 for now as per user request for simplicity, 
    # but in production use bcrypt/argon2
    hashed = hashlib.sha256(user.password.encode()).hexdigest()
    db_user = models.AdminUser(username=user.username, password_hash=hashed)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def verify_password(plain_password, hashed_password):
    return hashlib.sha256(plain_password.encode()).hexdigest() == hashed_password

# --- App Usage (DAU) ---
def record_app_usage(db: Session, usage: schemas.AppUsageCreate):
    existing = db.query(models.AppUsage).filter(
        models.AppUsage.date == usage.date,
        models.AppUsage.uid == usage.uid
    ).first()
    
    if existing:
        existing.launch_count += 1
        existing.last_seen = datetime.now()
        existing.version = usage.version
        existing.city = usage.city
        existing.ip_address = usage.ip_address
        db.commit()
        db.refresh(existing)
        return existing
    else:
        db_usage = models.AppUsage(**usage.dict())
        db.add(db_usage)
        db.commit()
        db.refresh(db_usage)
        return db_usage

def get_dau_trend(db: Session, days: int = 30):
    start_date = date.today() - timedelta(days=days)
    
    # 1. Initialize data structure for all days with 0
    trend_data = {}
    for i in range(days + 1):
        d = start_date + timedelta(days=i)
        trend_data[d.strftime("%Y-%m-%d")] = {"date": d.strftime("%Y-%m-%d"), "active_users": 0}
        
    # 2. Query actual data
    results = db.query(
        models.AppUsage.date,
        func.count(models.AppUsage.id).label("active_users")
    ).filter(models.AppUsage.date >= start_date)\
     .group_by(models.AppUsage.date)\
     .order_by(models.AppUsage.date)\
     .all()
     
    # 3. Fill in actual data
    for r in results:
        d_str = r.date.strftime("%Y-%m-%d") if hasattr(r.date, 'strftime') else str(r.date)
        if d_str in trend_data:
            trend_data[d_str]["active_users"] = r.active_users
            
    # 4. Convert to list and sort by date
    result_list = list(trend_data.values())
    result_list.sort(key=lambda x: x["date"])
    return result_list

def get_app_usage_logs(db: Session, skip: int = 0, limit: int = 100, target_date: str = None):
    query = db.query(models.AppUsage)
    
    if target_date:
        query = query.filter(models.AppUsage.date == target_date)
        
    return query.order_by(models.AppUsage.last_seen.desc()).offset(skip).limit(limit).all()

def get_app_geo_distribution(db: Session, limit: int = 10):
    results = db.query(
        models.AppUsage.city,
        func.count(models.AppUsage.id).label("count")
    ).group_by(models.AppUsage.city).order_by(func.count(models.AppUsage.id).desc()).limit(limit).all()
    
    return [{"city": r.city, "count": r.count} for r in results]

# --- Website Visits ---
def create_website_visit(db: Session, visit: schemas.WebsiteVisitCreate):
    db_visit = models.WebsiteVisit(**visit.dict())
    db.add(db_visit)
    db.commit()
    db.refresh(db_visit)
    return db_visit

def get_visit_trend(db: Session, days: int = 30):
    start_date = date.today() - timedelta(days=days)
    
    # 1. Initialize data structure
    trend_data = {}
    for i in range(days + 1):
        d = start_date + timedelta(days=i)
        trend_data[d.strftime("%Y-%m-%d")] = {"date": d.strftime("%Y-%m-%d"), "pv": 0, "uv": 0}
        
    # 2. Query actual data
    results = db.query(
        func.date(models.WebsiteVisit.visited_at).label("date"),
        func.count(models.WebsiteVisit.id).label("pv"),
        func.count(func.distinct(models.WebsiteVisit.ip_address)).label("uv")
    ).filter(func.date(models.WebsiteVisit.visited_at) >= start_date)\
     .group_by("date")\
     .order_by("date")\
     .all()
     
    # 3. Fill in actual data
    for r in results:
        # SQLite returns string for date in some cases, or datetime object
        d_val = r.date
        if hasattr(d_val, 'strftime'):
            d_str = d_val.strftime("%Y-%m-%d")
        else:
            # Handle potential string return from SQLite
            d_str = str(d_val)
            
        if d_str in trend_data:
            trend_data[d_str]["pv"] = r.pv
            trend_data[d_str]["uv"] = r.uv
            
    # 4. Convert to list and sort by date
    result_list = list(trend_data.values())
    result_list.sort(key=lambda x: x["date"])
    return result_list

def get_website_logs(db: Session, skip: int = 0, limit: int = 100, target_date: str = None):
    query = db.query(models.WebsiteVisit)
    
    if target_date:
        query = query.filter(func.date(models.WebsiteVisit.visited_at) == target_date)
        
    return query.order_by(models.WebsiteVisit.visited_at.desc()).offset(skip).limit(limit).all()

# --- Overview Stats ---
def get_stats_overview(db: Session):
    today = date.today()
    
    # Website Stats
    total_pv = db.query(models.WebsiteVisit).count()
    today_pv = db.query(models.WebsiteVisit).filter(func.date(models.WebsiteVisit.visited_at) == today).count()
    today_uv = db.query(models.WebsiteVisit.ip_address).filter(func.date(models.WebsiteVisit.visited_at) == today).distinct().count()
    
    # App Stats
    today_dau = db.query(models.AppUsage).filter(models.AppUsage.date == today).count()
    total_users = db.query(models.AppUsage.uid).distinct().count()
    
    # Download Stats
    total_downloads = db.query(models.DownloadKey).filter(models.DownloadKey.is_used == True).count()
    
    return {
        "total_pv": total_pv,
        "today_pv": today_pv,
        "today_uv": today_uv,
        "today_dau": today_dau,
        "total_downloads": total_downloads,
        "total_users": total_users
    }

def get_geo_distribution(db: Session, limit: int = 10):
    # Combined geo distribution or separate? 
    # Let's do Website Visit Geo for now as it's more representative of traffic
    results = db.query(
        models.WebsiteVisit.city,
        func.count(models.WebsiteVisit.id).label("count")
    ).group_by(models.WebsiteVisit.city).order_by(func.count(models.WebsiteVisit.id).desc()).limit(limit).all()
    
    return [{"city": r.city, "count": r.count} for r in results]

def get_os_distribution(db: Session):
    results = db.query(
        models.WebsiteVisit.os,
        func.count(models.WebsiteVisit.id).label("count")
    ).group_by(models.WebsiteVisit.os).order_by(func.count(models.WebsiteVisit.id).desc()).all()
    return [{"os": r.os, "count": r.count} for r in results]

def get_browser_distribution(db: Session):
    results = db.query(
        models.WebsiteVisit.browser,
        func.count(models.WebsiteVisit.id).label("count")
    ).group_by(models.WebsiteVisit.browser).order_by(func.count(models.WebsiteVisit.id).desc()).all()
    return [{"browser": r.browser, "count": r.count} for r in results]
