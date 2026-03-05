from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime, Text, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class DownloadKey(Base):
    __tablename__ = "download_keys"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String(255), unique=True, index=True)
    is_used = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    used_at = Column(DateTime(timezone=True), nullable=True)
    
    # Optional: Associate with user info if provided
    user_email = Column(String(255), nullable=True)

class DownloadLog(Base):
    __tablename__ = "download_logs"

    id = Column(Integer, primary_key=True, index=True)
    key_id = Column(Integer, ForeignKey("download_keys.id"), nullable=True) # Can be null if free download allowed later
    ip_address = Column(String(45)) # IPv6 max length
    geo_location = Column(String(255)) # JSON or String "City, Country"
    version = Column(String(50))
    downloaded_at = Column(DateTime(timezone=True), server_default=func.now())
    
    key = relationship("DownloadKey")

class DailyUsage(Base):
    __tablename__ = "daily_usage"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(Date, index=True) # Only store date part
    uid = Column(String(64), index=True) # Machine ID (SHA256 hex is 64 chars)
    version = Column(String(50))
    ip_address = Column(String(45))
    geo_location = Column(String(255))
    launch_count = Column(Integer, default=1)
    last_seen = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class UserBackup(Base):
    __tablename__ = "user_backups"

    id = Column(Integer, primary_key=True, index=True)
    uid = Column(String(64), index=True, unique=True) # Machine ID as key for now
    backup_data = Column(Text) # JSON string of settings/data
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    ip_address = Column(String(45))

class WebsiteVisit(Base):
    __tablename__ = "website_visits"

    id = Column(Integer, primary_key=True, index=True)
    ip_address = Column(String(45))
    path = Column(String(255))
    user_agent = Column(String(500))
    geo_location = Column(String(255))
    referrer = Column(String(500), nullable=True)
    os = Column(String(100), nullable=True)
    browser = Column(String(100), nullable=True)
    device_type = Column(String(50), nullable=True) # PC, Mobile, Tablet
    visited_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # New fields for deep analysis
    duration_seconds = Column(Integer, default=0)
    is_downloaded = Column(Boolean, default=False)
    downloaded_version = Column(String(50), nullable=True)
