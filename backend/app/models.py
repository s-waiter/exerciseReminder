from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime, Text, Date, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class DownloadKey(Base):
    __tablename__ = "download_keys"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String(50), unique=True, index=True) # Short code e.g. "DESK2026"
    is_used = Column(Boolean, default=False)
    type = Column(String(20), default="one_time") # 'one_time' or 'permanent' or 'time_limited'
    usage_count = Column(Integer, default=0)
    max_uses = Column(Integer, nullable=True) # Optional: Limit max uses even for time_limited
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    used_at = Column(DateTime(timezone=True), nullable=True)
    used_by_ip = Column(String(45), nullable=True)

class SystemConfig(Base):
    __tablename__ = "system_config"
    
    key = Column(String(50), primary_key=True, index=True)
    value = Column(String(255))
    description = Column(String(255), nullable=True)

class AdminUser(Base):
    __tablename__ = "admin_users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    password_hash = Column(String(255)) # Simple hash for now or bcrypt later
    role = Column(String(20), default="admin")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class AppUsage(Base):
    __tablename__ = "app_usage"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(Date, index=True) # YYYY-MM-DD
    uid = Column(String(64), index=True) # Machine ID
    version = Column(String(50))
    ip_address = Column(String(45))
    city = Column(String(100)) # Only city level
    launch_count = Column(Integer, default=1)
    last_seen = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class UserBackup(Base):
    __tablename__ = "user_backups"

    id = Column(Integer, primary_key=True, index=True)
    uid = Column(String(64), index=True, unique=True)
    backup_data = Column(Text) # JSON string
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    ip_address = Column(String(45))

class WebsiteVisit(Base):
    __tablename__ = "website_visits"

    id = Column(Integer, primary_key=True, index=True)
    ip_address = Column(String(45))
    path = Column(String(255))
    user_agent = Column(String(500))
    city = Column(String(100)) # Only city level
    referrer = Column(String(500), nullable=True)
    os = Column(String(100), nullable=True)
    browser = Column(String(100), nullable=True)
    device_type = Column(String(50), nullable=True) # PC, Mobile, Tablet
    visited_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Analytics
    duration_seconds = Column(Integer, default=0)
    is_download_click = Column(Boolean, default=False) # Track if they clicked download
