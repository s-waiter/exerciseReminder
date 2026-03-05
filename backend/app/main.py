from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .routers import analytics, downloads, backup, updates, dashboard
from .database import engine, Base, SessionLocal
from sqlalchemy import text
import os

# Database Migration Helper
def run_migrations():
    # Simple migration to add columns if they don't exist
    # This is a workaround for SQLite not supporting 'IF NOT EXISTS' in ADD COLUMN well via simple SQL in older versions, 
    # but we can try-catch.
    db = SessionLocal()
    try:
        # Check if 'referrer' column exists in 'website_visits'
        # SQLite pragma table_info
        result = db.execute(text("PRAGMA table_info(website_visits)")).fetchall()
        columns = [row[1] for row in result]
        
        if "referrer" not in columns:
            print("Migrating: Adding referrer column...")
            db.execute(text("ALTER TABLE website_visits ADD COLUMN referrer VARCHAR"))
        
        if "os" not in columns:
            print("Migrating: Adding os column...")
            db.execute(text("ALTER TABLE website_visits ADD COLUMN os VARCHAR"))
            
        if "browser" not in columns:
            print("Migrating: Adding browser column...")
            db.execute(text("ALTER TABLE website_visits ADD COLUMN browser VARCHAR"))
            
        if "device_type" not in columns:
            print("Migrating: Adding device_type column...")
            db.execute(text("ALTER TABLE website_visits ADD COLUMN device_type VARCHAR"))
            
        if "duration_seconds" not in columns:
            print("Migrating: Adding duration_seconds column...")
            db.execute(text("ALTER TABLE website_visits ADD COLUMN duration_seconds INTEGER DEFAULT 0"))

        if "is_downloaded" not in columns:
            print("Migrating: Adding is_downloaded column...")
            db.execute(text("ALTER TABLE website_visits ADD COLUMN is_downloaded BOOLEAN DEFAULT 0"))

        if "downloaded_version" not in columns:
            print("Migrating: Adding downloaded_version column...")
            db.execute(text("ALTER TABLE website_visits ADD COLUMN downloaded_version VARCHAR"))
            
        db.commit()
    except Exception as e:
        print(f"Migration warning: {e}")
    finally:
        db.close()

run_migrations()
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="DeskCare Backend API",
    description="API for DeskCare Application (Analytics, Updates, Backup)",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow all for now
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analytics.router)
app.include_router(analytics.legacy_router)
app.include_router(downloads.router)
app.include_router(backup.router)
app.include_router(updates.router)
app.include_router(dashboard.router)

# Serve Files Directory (Downloads)
# Allow public access to /files for zip downloads
# Mount /files BEFORE / to avoid being shadowed by the root static mount
files_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "files")
if os.path.exists(files_dir):
    app.mount("/files", StaticFiles(directory=files_dir), name="files")

# Serve Static Files (Frontend)
# If 'static' folder exists, serve it at root
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")

@app.get("/api/status")
async def status():
    return {"status": "ok", "message": "DeskCare Backend Running"}
