from fastapi import FastAPI, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from .routers import analytics, downloads, backup, updates, admin
from .database import engine, Base, SessionLocal
from . import crud, schemas
import os
import hashlib
from typing import Optional

# Ensure tables exist
Base.metadata.create_all(bind=engine)

# Create Default Admin if not exists
def create_default_admin():
    db = SessionLocal()
    try:
        if not crud.get_admin_user(db, "root"):
            print("Creating default admin user (root)...")
            crud.create_admin_user(db, schemas.AdminLogin(username="root", password="pass"))
    except Exception as e:
        print(f"Error creating default admin: {e}")
    finally:
        db.close()

create_default_admin()

app = FastAPI(
    title="DeskCare Backend API",
    description="API for DeskCare Application (Analytics, Updates, Backup, Admin)",
    version="2.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow all for now
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/status")
async def status():
    return {"status": "ok", "message": "DeskCare Backend Running v2.0"}

app.include_router(analytics.router)
app.include_router(downloads.router)
app.include_router(backup.router)
app.include_router(updates.router)
app.include_router(admin.router)

# Serve Files Directory (Downloads)
files_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "files")
if not os.path.exists(files_dir):
    os.makedirs(files_dir)
app.mount("/files", StaticFiles(directory=files_dir), name="files")

# Serve Frontend (SPA)
# Handle both local dev (../../frontend/dist) and server deployment (/opt/deskcare/static)
# NOTE: os.path.dirname(__file__) is backend/app
# Server: /opt/deskcare/app/main.py -> static is /opt/deskcare/static (one level up from app)
# Local: backend/app/main.py -> static is backend/static (one level up from app)
server_static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
# Local dev frontend/dist
local_static_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "frontend", "dist")

static_dir = None
if os.path.exists(server_static_dir):
    static_dir = server_static_dir
elif os.path.exists(local_static_dir):
    static_dir = local_static_dir

if static_dir:
    # Ensure static directories exist to avoid mount errors
    if not os.path.exists(static_dir):
        os.makedirs(static_dir)
        
    assets_dir = os.path.join(static_dir, "assets")
    if not os.path.exists(assets_dir):
        os.makedirs(assets_dir)
    app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")
    
    images_dir = os.path.join(static_dir, "images")
    if not os.path.exists(images_dir):
        os.makedirs(images_dir)
    app.mount("/images", StaticFiles(directory=images_dir), name="images")
    
    # Explicit Root Handler
    @app.get("/")
    async def serve_root():
        index_path = os.path.join(static_dir, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return JSONResponse(status_code=404, content={"detail": "Frontend index.html not found"})

    # Catch-all for SPA and Root Static Files
    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        # IMPORTANT: Explicitly ignore API routes in catch-all to prevent 404 hijacking
        # Check against both "/api" and "api" (for different URL formats)
        path_parts = full_path.strip("/").split("/")
        if path_parts and path_parts[0] in ["api", "files", "updates"]:
             return JSONResponse(status_code=404, content={"detail": f"Route /{full_path} not found in API"})
        
        # 1. Try to serve exact file match (e.g. vite.svg, robots.txt, favicon.ico)
        # Security check: ensure path is within static_dir
        # Also remove any leading slashes to prevent absolute path traversal
        clean_path = full_path.lstrip("/")
        if not clean_path: # Root path handled by index.html logic below
             pass
        else:
            file_path = os.path.abspath(os.path.join(static_dir, clean_path))
            if os.path.commonprefix([file_path, os.path.abspath(static_dir)]) == os.path.abspath(static_dir):
                if os.path.exists(file_path) and os.path.isfile(file_path):
                    return FileResponse(file_path)
             
        # 2. Serve index.html for all other routes (SPA) - BUT ONLY if it's not a static resource request
        # If request ends with typical extensions, return 404 instead of index.html
        # This prevents 404 images from returning HTML
        ext = os.path.splitext(full_path)[1].lower()
        if ext in ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.css', '.js', '.json', '.ico', '.map', '.woff', '.woff2', '.ttf']:
             return JSONResponse(status_code=404, content={"detail": "File not found"})

        index_path = os.path.join(static_dir, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return JSONResponse(status_code=404, content={"detail": "Frontend index.html not found"})
