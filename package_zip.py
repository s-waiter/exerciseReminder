import zipfile
import os
import shutil
import sys
import json

# Read version from version_info.json
def get_version():
    json_path = os.path.join(os.path.dirname(__file__), "version_info.json")
    if os.path.exists(json_path):
        with open(json_path, 'r') as f:
            v = json.load(f)
            return f"{v['major']}.{v['minor']}.{v['patch']}"
    return "1.0.0"

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
DIST_DIR = os.path.join(PROJECT_ROOT, "dist")
VERSION = get_version()
ZIP_NAME = f"DeskCare_v{VERSION}.zip"
ZIP_PATH = os.path.join(PROJECT_ROOT, ZIP_NAME)

def zip_directory(directory_path, zip_path):
    print(f"Compressing {directory_path} to {zip_path}...")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(directory_path):
            for file in files:
                file_path = os.path.join(root, file)
                # Calculate the relative path to keep the structure inside the zip
                # We want the content of 'dist' to be at the root of the zip
                arcname = os.path.relpath(file_path, directory_path)
                print(f"  Adding: {arcname}")
                zipf.write(file_path, arcname)

def main():
    # Base paths
    # Assuming this script is run from the project root or we find it relative to this script
    # But for simplicity, let's assume it's run from project root as per bat script
    project_root = os.getcwd()
    dist_dir = os.path.join(project_root, "dist")
    # Use global ZIP_NAME which is based on version_info.json
    zip_name = ZIP_NAME
    zip_path = os.path.join(project_root, zip_name)
    
    # Check if dist exists
    if not os.path.exists(dist_dir):
        print(f"Error: {dist_dir} does not exist.")
        sys.exit(1)

    # 1. Create Zip
    try:
        if os.path.exists(zip_path):
            os.remove(zip_path)
        zip_directory(dist_dir, zip_path)
        print("Zip creation successful.")
    except Exception as e:
        print(f"Error creating zip: {e}")
        sys.exit(1)

    # 2. Copy to Website Directory
    website_downloads_dir = os.path.join(project_root, "website_project", "official_site", "public", "downloads")
    
    try:
        if not os.path.exists(website_downloads_dir):
            os.makedirs(website_downloads_dir)
            print(f"Created directory: {website_downloads_dir}")
            
        dest_path = os.path.join(website_downloads_dir, zip_name)
        shutil.copy2(zip_path, dest_path)
        print(f"Successfully copied zip to: {dest_path}")
        
    except Exception as e:
        print(f"Error copying to website: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
