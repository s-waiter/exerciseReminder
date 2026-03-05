from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime, Text, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class DownloadKey(Base):
    __tablename__ = "download_keys"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, unique=True, index=True)
    is_used = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    used_at = Column(DateTime(timezone=True), nullable=True)
    
    # Optional: Associate with user info if provided
    user_email = Column(String, nullable=True)

class DownloadLog(Base):
    __tablename__ = "download_logs"

    id = Column(Integer, primary_key=True, index=True)
    key_id = Column(Integer, ForeignKey("download_keys.id"), nullable=True) # Can be null if free download allowed later
    ip_address = Column(String)
    geo_location = Column(String) # JSON or String "City, Country"
    version = Column(String)
    downloaded_at = Column(DateTime(timezone=True), server_default=func.now())
    
    key = relationship("DownloadKey")

class DailyUsage(Base):
    __tablename__ = "daily_usage"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(Date, index=True) # Only store date part
    uid = Column(String, index=True) # Machine ID
    version = Column(String)
    ip_address = Column(String)
    geo_location = Column(String)
    launch_count = Column(Integer, default=1)
    last_seen = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class UserBackup(Base):
    __tablename__ = "user_backups"

    id = Column(Integer, primary_key=True, index=True)
    uid = Column(String, index=True, unique=True) # Machine ID as key for now
    backup_data = Column(Text) # JSON string of settings/data
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    ip_address = Column(String)

class WebsiteVisit(Base):
    __tablename__ = "website_visits"

    id = Column(Integer, primary_key=True, index=True)
    ip_address = Column(String)
    path = Column(String)
    user_agent = Column(String)
    geo_location = Column(String)
    referrer = Column(String, nullable=True)
    os = Column(String, nullable=True)
    browser = Column(String, nullable=True)
    device_type = Column(String, nullable=True) # PC, Mobile, Tablet
    visited_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # New fields for deep analysis
    duration_seconds = Column(Integer, default=0)
    is_downloaded = Column(Boolean, default=False)
    downloaded_version = Column(String, nullable=True)
