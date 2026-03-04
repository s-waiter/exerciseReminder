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

# Serve Static Files (Frontend)
# If 'static' folder exists, serve it at root
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")

@app.get("/api/status")
async def status():
    return {"status": "ok", "message": "DeskCare Backend Running"}
