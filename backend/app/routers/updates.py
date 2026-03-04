from fastapi import APIRouter
import json
import os

router = APIRouter(
    prefix="/updates",
    tags=["updates"]
)

VERSION_FILE = os.path.join("files", "version_info.json")

@router.get("/version.json")
async def get_version_info():
    if os.path.exists(VERSION_FILE):
        with open(VERSION_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"version": "1.0.0", "description": "Default version"}
