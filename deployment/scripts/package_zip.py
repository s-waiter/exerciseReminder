import zipfile
import os
import shutil
import sys
import json

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIST_DIR = os.path.join(PROJECT_ROOT, "dist")
# Standardize releases path to deployment/releases
RELEASES_DIR = os.path.join(PROJECT_ROOT, "deployment", "releases")

def get_version():
    json_path = os.path.join(PROJECT_ROOT, "version_info.json")
    if os.path.exists(json_path):
        with open(json_path, 'r') as f:
            v = json.load(f)
            return f"{v['major']}.{v['minor']}.{v['patch']}"
    return "1.0.0"

VERSION = get_version()
ZIP_NAME = f"DeskCare_v{VERSION}.zip"
ZIP_PATH = os.path.join(RELEASES_DIR, ZIP_NAME)

def zip_directory(directory_path, zip_path):
    print(f"Compressing {directory_path} to {zip_path}...")
    # Use zipfile module directly instead of shutil.make_archive for more control
    # We want to zip the *contents* of directory_path, not the directory itself
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(directory_path):
            for file in files:
                file_path = os.path.join(root, file)
                # Calculate relative path from directory_path
                arcname = os.path.relpath(file_path, directory_path)
                print(f"  Adding: {arcname}")
                zipf.write(file_path, arcname)

def main():
    # 1. Ensure RELEASES_DIR exists
    if not os.path.exists(RELEASES_DIR):
        os.makedirs(RELEASES_DIR)
        
    # 2. Locate dist directory (created by bat script in CWD)
    # The bat script runs from deployment/, so dist is in deployment/dist
    # BUT wait, the bat script does `cd /d "%~dp0"`, so CWD is D:\...\deployment
    # And it creates `dist` there.
    # So we should look for dist in the current working directory.
    dist_dir = os.path.join(os.getcwd(), "dist")
    
    if not os.path.exists(dist_dir):
        print(f"Error: {dist_dir} does not exist.")
        sys.exit(1)

    # 3. Create Zip
    try:
        if os.path.exists(ZIP_PATH):
            os.remove(ZIP_PATH)
        zip_directory(dist_dir, ZIP_PATH)
        print(f"Zip creation successful: {ZIP_PATH}")
    except Exception as e:
        print(f"Error creating zip: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
