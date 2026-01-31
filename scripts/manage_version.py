import json
import os
import sys

# Paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_JSON_PATH = os.path.join(PROJECT_ROOT, "version_info.json")
VERSION_HEADER_PATH = os.path.join(PROJECT_ROOT, "src", "core", "Version.h")

def load_version():
    if not os.path.exists(VERSION_JSON_PATH):
        return {"major": 1, "minor": 0, "patch": 0}
    with open(VERSION_JSON_PATH, "r") as f:
        return json.load(f)

def save_version(version):
    with open(VERSION_JSON_PATH, "w") as f:
        json.dump(version, f, indent=4)

def update_header_file(version):
    content = f"""#ifndef VERSION_H
#define VERSION_H

#define APP_VERSION "{version['major']}.{version['minor']}.{version['patch']}"
#define APP_VERSION_MAJOR {version['major']}
#define APP_VERSION_MINOR {version['minor']}
#define APP_VERSION_PATCH {version['patch']}

#endif // VERSION_H
"""
    with open(VERSION_HEADER_PATH, "w") as f:
        f.write(content)
    print(f"Updated Version.h to {version['major']}.{version['minor']}.{version['patch']}")

def bump_patch():
    version = load_version()
    version["patch"] += 1
    save_version(version)
    update_header_file(version)
    return version

def get_version_string():
    version = load_version()
    return f"{version['major']}.{version['minor']}.{version['patch']}"

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "bump":
            v = bump_patch()
            print(f"BUMPED_VERSION={v['major']}.{v['minor']}.{v['patch']}")
        elif cmd == "get":
            print(f"CURRENT_VERSION={get_version_string()}")
        elif cmd == "update_header":
            update_header_file(load_version())
    else:
        print(f"Current Version: {get_version_string()}")
        print("Usage: python manage_version.py [bump|get|update_header]")
