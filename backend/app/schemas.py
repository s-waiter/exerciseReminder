from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime, date

# --- Download Keys ---
class DownloadKeyBase(BaseModel):
    key: str

class DownloadKeyCreate(DownloadKeyBase):
    pass

class DownloadKey(DownloadKeyBase):
    id: int
    is_used: bool
    created_at: datetime
    used_at: Optional[datetime]
    used_by_ip: Optional[str]

    class Config:
        orm_mode = True

# --- Admin ---
class AdminLogin(BaseModel):
    username: str
    password: str

class AdminUser(BaseModel):
    id: int
    username: str
    role: str

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

# --- App Usage ---
class AppUsageBase(BaseModel):
    date: date
    uid: str
    version: str
    ip_address: str
    city: str

class AppUsageCreate(AppUsageBase):
    launch_count: int = 1

class AppUsage(AppUsageBase):
    id: int
    last_seen: datetime

    class Config:
        orm_mode = True

# --- User Backup ---
class UserBackupBase(BaseModel):
    uid: str
    backup_data: str # JSON string

class UserBackupCreate(UserBackupBase):
    ip_address: str

class UserBackup(UserBackupBase):
    id: int
    updated_at: datetime
    
    class Config:
        orm_mode = True

# --- Website Visits ---
class WebsiteVisitBase(BaseModel):
    ip_address: str
    path: str
    user_agent: str
    city: str
    referrer: Optional[str] = None
    os: Optional[str] = None
    browser: Optional[str] = None
    device_type: Optional[str] = None
    duration_seconds: int = 0
    is_download_click: bool = False

class WebsiteVisitCreate(WebsiteVisitBase):
    city: str = "Unknown"
    os: str = "Unknown"
    browser: str = "Unknown"
    device_type: str = "PC"
    duration_seconds: int = 0
    is_download_click: bool = False

class WebsiteVisit(WebsiteVisitBase):
    id: int
    visited_at: datetime
    city: str
    os: str = None
    browser: str = None
    device_type: str = None
    duration_seconds: int = 0
    is_download_click: bool = False

    class Config:
        orm_mode = True

# --- Analytics Response ---
class OverviewStats(BaseModel):
    total_pv: int
    today_pv: int
    today_uv: int
    today_dau: int
    total_downloads: int
    total_users: int

class TrendData(BaseModel):
    date: str
    pv: int
    uv: int

class DAUTrendData(BaseModel):
    date: str
    active_users: int
