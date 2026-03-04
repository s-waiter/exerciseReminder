from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime, date

class DownloadKeyBase(BaseModel):
    key: str

class DownloadKeyCreate(DownloadKeyBase):
    pass

class DownloadKey(DownloadKeyBase):
    id: int
    is_used: bool
    created_at: datetime
    
    class Config:
        orm_mode = True

class DownloadLogBase(BaseModel):
    key_id: Optional[int]
    ip_address: str
    geo_location: str
    version: str

class DownloadLogCreate(DownloadLogBase):
    pass

class DailyUsageBase(BaseModel):
    date: date
    uid: str
    version: str
    ip_address: str
    geo_location: str

class DailyUsageCreate(DailyUsageBase):
    launch_count: int = 1

class UserBackupBase(BaseModel):
    uid: str
    backup_data: str # JSON

class UserBackupCreate(UserBackupBase):
    ip_address: str

class UserBackup(UserBackupBase):
    updated_at: datetime
    
    class Config:
        orm_mode = True

class WebsiteVisitBase(BaseModel):
    ip_address: str
    path: str
    user_agent: str
    geo_location: str
    referrer: Optional[str] = None
    os: Optional[str] = None
    browser: Optional[str] = None
    device_type: Optional[str] = None

class WebsiteVisitCreate(WebsiteVisitBase):
    pass
