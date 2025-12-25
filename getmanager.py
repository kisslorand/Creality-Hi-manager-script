#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import time
import base64
import re
import urllib.request
from urllib.error import HTTPError
from concurrent.futures import ThreadPoolExecutor, as_completed

# =========================
# USER CONFIGURATION
# =========================

REPO = "kisslorand/Creality-Hi-manager-script"
BRANCH = "main"
TARGET_DIR = "/mnt/UDISK/hi-manager"
MAX_THREADS = 4
# =========================

API_URL_TREE = f"https://api.github.com/repos/{REPO}/git/trees/"
API_URL_BRANCH = f"https://api.github.com/repos/{REPO}/branches/{BRANCH}"

HEADERS = {
    "User-Agent": "PythonDownloader"
}

def fetch_json(url):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as response:
        return json.load(response)

def download_file(file_item):
    path = file_item["path"]

    # Skip the script itself, .gitattributes and readme.md
    basename = os.path.basename(path).lower()
    downloader = os.path.basename(__file__).lower()
    
    if basename in (downloader, ".gitattributes", "readme.md"):
        return True, f"Skipped {path}"

    blob_url = file_item["url"]
    local_path = os.path.join(TARGET_DIR, path)

    try:
        blob_data = fetch_json(blob_url)
        content = base64.b64decode(blob_data["content"])

        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        with open(local_path, "wb") as f:
            f.write(content)

        # Determine permissions
        _, ext = os.path.splitext(path)
        if file_item["mode"] == "100755" or ext in (".sh", ".py") or ext.startswith(".so") or ext == "":
            os.chmod(local_path, 0o755)
        else:
            os.chmod(local_path, 0o644)

        return True, path
    except Exception as e:
        return False, f"{path} ({e})"

def print_progress(completed, total, start_time):
    elapsed = time.time() - start_time
    progress = completed / total
    eta = elapsed / progress * (1 - progress) if progress > 0 else 0
    bar_length = 30
    filled = int(bar_length * progress)
    bar = "#" * filled + "-" * (bar_length - filled)
    print(f"\r[{bar}] {completed}/{total} files | ETA: {int(eta)}s", end="", flush=True)

def main():
    if os.path.exists(TARGET_DIR):
        print(f"Removing old directory: {TARGET_DIR}")
        os.system(f"rm -rf {TARGET_DIR}")

    # Branch info
    branch_info = fetch_json(API_URL_BRANCH)
    commit_sha = branch_info["commit"]["commit"]["tree"]["sha"]
    print(f"Branch commit SHA: {commit_sha}")

    # Fetch all files
    tree_url = f"{API_URL_TREE}{commit_sha}?recursive=1"
    tree_data = fetch_json(tree_url)
    files = [item for item in tree_data["tree"] if item["type"] == "blob"]
    total_files = len(files)
    print(f"Total files to download: {total_files}")

    start_time = time.time()
    completed = 0

    # Parallel download
    with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
        future_to_file = {executor.submit(download_file, f): f for f in files}

        for future in as_completed(future_to_file):
            future.result()  # we don't need to print individual files
            completed += 1
            print_progress(completed, total_files, start_time)

    print("\nAll files downloaded successfully.")

if __name__ == "__main__":
    main()
