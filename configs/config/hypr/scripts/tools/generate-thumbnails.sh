#!/usr/bin/env bash
# Generador optimizado de miniaturas para Quickshell Wallpaper Picker

python3 - << 'PY_EOF'
import os, glob, subprocess
from concurrent.futures import ThreadPoolExecutor

thumb_dir = os.path.expanduser("~/.cache/quickshell/wallpapers")
os.makedirs(thumb_dir, exist_ok=True)

conf_file = os.path.expanduser("~/.config/hypr/wallpaper-dirs.conf")
dirs = [
    os.path.expanduser("~/Wallpapers"),
    os.path.expanduser("~/Pictures/Wallpapers"),
    os.path.expanduser("~/.local/share/wallpapers")
]

if os.path.isfile(conf_file):
    with open(conf_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                expanded = os.path.expanduser(line)
                if os.path.isdir(expanded):
                    dirs.append(expanded)

# Collect unique image files, keeping the first configured path for symlink aliases.
images_by_inode = {}
for d in dirs:
    if not os.path.isdir(d):
        continue
    for root, _, files in os.walk(d, followlinks=True):
        for f in files:
            if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp", ".gif")):
                path = os.path.join(root, f)
                try:
                    stat = os.stat(path)
                except OSError:
                    continue
                images_by_inode.setdefault((stat.st_dev, stat.st_ino), path)

images = sorted(images_by_inode.values())

def djb2_hash(path: str) -> str:
    h = 5381
    for c in path:
        h = (((h << 5) + h) + ord(c)) & 0xFFFFFFFF
    return f"{h:08x}"

def process_image(img):
    h = djb2_hash(img)
    thumb = os.path.join(thumb_dir, f"{h}.jpg")
    if os.path.exists(thumb):
        try:
            if os.path.getmtime(thumb) >= os.path.getmtime(img):
                return
        except OSError:
            pass
    # Generate thumbnail
    res = subprocess.run(["vipsthumbnail", img, "-s", "256x144", "-o", thumb], capture_output=True)
    if res.returncode != 0:
        # Fallback to ffmpegthumbnailer
        subprocess.run(["ffmpegthumbnailer", "-i", img, "-o", thumb, "-s", "256", "-q", "6"], capture_output=True)

# Run with 2 workers to not starve the dual-core CPU
with ThreadPoolExecutor(max_workers=2) as executor:
    list(executor.map(process_image, images))

print(f"Thumbnails synchronized: {len(os.listdir(thumb_dir))} cached in {thumb_dir}")
PY_EOF
