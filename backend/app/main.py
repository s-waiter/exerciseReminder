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
    db = SessionLocal()
    try:
        # MySQL migration check
        result = db.execute(text("SHOW COLUMNS FROM website_visits")).fetchall()
        columns = [row[0] for row in result]
            
        # Helper to add column safely
        def add_column_safe(col_name, col_type):
            if col_name not in columns:
                print(f"Migrating: Adding {col_name} column...")
                try:
                    db.execute(text(f"ALTER TABLE website_visits ADD COLUMN {col_name} {col_type}"))
                    db.commit()
                except Exception as ex:
                    print(f"Error adding {col_name}: {ex}")
                    db.rollback()

        if columns: # Only run if table exists
            add_column_safe("referrer", "VARCHAR(255)")
            add_column_safe("os", "VARCHAR(255)")
            add_column_safe("browser", "VARCHAR(255)")
            add_column_safe("device_type", "VARCHAR(255)")
            add_column_safe("duration_seconds", "INTEGER DEFAULT 0")
            add_column_safe("is_downloaded", "BOOLEAN DEFAULT 0")
            add_column_safe("downloaded_version", "VARCHAR(255)")
            
    except Exception as e:
        print(f"Migration warning: {e}")
        # If table doesn't exist, create_all will handle it later, so this exception is fine for first run
    finally:
        db.close()

# Ensure tables exist
Base.metadata.create_all(bind=engine)
# Run migrations for existing tables
run_migrations()

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
