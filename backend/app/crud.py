from sqlalchemy.orm import Session
from . import models, schemas
from datetime import date, datetime
from sqlalchemy import func

def get_download_key(db: Session, key: str):
    return db.query(models.DownloadKey).filter(models.DownloadKey.key == key).first()

def create_download_key(db: Session, key: str):
    db_key = models.DownloadKey(key=key)
    db.add(db_key)
    db.commit()
    db.refresh(db_key)
    return db_key

def mark_key_used(db: Session, db_key: models.DownloadKey):
    db_key.is_used = True
    db_key.used_at = datetime.now()
    db.commit()
    db.refresh(db_key)
    return db_key

def create_download_log(db: Session, log: schemas.DownloadLogCreate):
    db_log = models.DownloadLog(**log.dict())
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

def get_download_logs(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.DownloadLog).offset(skip).limit(limit).all()

def record_daily_usage(db: Session, usage: schemas.DailyUsageCreate):
    # Check if user already active today
    existing = db.query(models.DailyUsage).filter(
        models.DailyUsage.date == usage.date,
        models.DailyUsage.uid == usage.uid
    ).first()
    
    if existing:
        existing.launch_count += 1
        existing.last_seen = datetime.now()
        existing.version = usage.version # Update version if upgraded
        db.commit()
        db.refresh(existing)
        return existing
    else:
        db_usage = models.DailyUsage(**usage.dict())
        db.add(db_usage)
        db.commit()
        db.refresh(db_usage)
        return db_usage

def get_daily_active_users(db: Session, day: date):
    return db.query(models.DailyUsage).filter(models.DailyUsage.date == day).count()

def get_total_users(db: Session):
    # Estimate total unique users by distinct UID
    return db.query(models.DailyUsage.uid).distinct().count()

def create_website_visit(db: Session, visit: schemas.WebsiteVisitCreate):
    db_visit = models.WebsiteVisit(**visit.dict())
    db.add(db_visit)
    db.commit()
    db.refresh(db_visit)
    return db_visit

def get_website_visits(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.WebsiteVisit).order_by(models.WebsiteVisit.visited_at.desc()).offset(skip).limit(limit).all()

def get_stats_overview(db: Session):
    total_pv = db.query(models.WebsiteVisit).count()
    today = date.today()
    today_pv = db.query(models.WebsiteVisit).filter(func.date(models.WebsiteVisit.visited_at) == today).count()
    today_uv = db.query(models.WebsiteVisit.ip_address).filter(func.date(models.WebsiteVisit.visited_at) == today).distinct().count()
    total_downloads = db.query(models.DownloadLog).count()
    total_users = db.query(models.DailyUsage.uid).distinct().count()
    return {
        "total_pv": total_pv,
        "today_pv": today_pv,
        "today_uv": today_uv,
        "total_downloads": total_downloads,
        "total_users": total_users
    }

def get_visit_trend(db: Session, days: int = 7):
    # This is a simplified trend query. For better performance on large datasets, consider raw SQL or optimization.
    # Group by date
    # SQLite date function usage: date(visited_at)
    results = db.query(
        func.date(models.WebsiteVisit.visited_at).label("date"),
        func.count(models.WebsiteVisit.id).label("pv"),
        func.count(func.distinct(models.WebsiteVisit.ip_address)).label("uv")
    ).group_by("date").order_by("date").limit(days).all()
    return results

def get_geo_distribution(db: Session, limit: int = 10):
    return db.query(
        models.WebsiteVisit.geo_location,
        func.count(models.WebsiteVisit.id).label("count")
    ).group_by(models.WebsiteVisit.geo_location).order_by(func.count(models.WebsiteVisit.id).desc()).limit(limit).all()

def get_os_distribution(db: Session):
    return db.query(
        models.WebsiteVisit.os,
        func.count(models.WebsiteVisit.id).label("count")
    ).group_by(models.WebsiteVisit.os).order_by(func.count(models.WebsiteVisit.id).desc()).all()

def get_browser_distribution(db: Session):
    return db.query(
        models.WebsiteVisit.browser,
        func.count(models.WebsiteVisit.id).label("count")
    ).group_by(models.WebsiteVisit.browser).order_by(func.count(models.WebsiteVisit.id).desc()).all()


def create_or_update_backup(db: Session, backup: schemas.UserBackupCreate):
    existing = db.query(models.UserBackup).filter(models.UserBackup.uid == backup.uid).first()
    if existing:
        existing.backup_data = backup.backup_data
        existing.ip_address = backup.ip_address
        existing.updated_at = datetime.now()
        db.commit()
        db.refresh(existing)
        return existing
    else:
        db_backup = models.UserBackup(**backup.dict())
        db.add(db_backup)
        db.commit()
        db.refresh(db_backup)
        return db_backup

def get_backup(db: Session, uid: str):
    return db.query(models.UserBackup).filter(models.UserBackup.uid == uid).first()
