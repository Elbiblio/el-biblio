"""
Download community/tribe ambient sound from BigSoundBank (CC0 public domain).
Source: https://bigsoundbank.com by Joseph SARDIN
License: CC0 / public domain — no restrictions, no attribution required.

Chosen: Mass: Organ and singing #1 (s2789)
  - Chants and organ during Sunday mass, Basilica Notre-Dame de Montligeon, France
  - 2:34 duration, 24-bit, ORTF stereo, SoundDevices MixPre-3 + Neumann KM184
  - Perfect for tribe/connect/community screens — people in worship together

Backup: Office cathedral of Chartres (s0506)
  - Thursday evening service, ~20 worshippers, amplified voice, reverent
  - 4:58 duration, quieter atmosphere
"""

import urllib.request
import subprocess
import os
import sys

AMBIENT_DIR = os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "assets", "audio", "ambient"
))

DOWNLOADS = [
    {
        "url": "https://bigsoundbank.com/UPLOAD/mp3/2789.mp3",
        "dest": "community.mp3",
        "desc": "Mass organ+chants, Basilica Notre-Dame de Montligeon (BigSoundBank s2789, CC0)",
    },
    {
        "url": "https://bigsoundbank.com/UPLOAD/mp3/0506.mp3",
        "dest": "community-quiet.mp3",
        "desc": "Chartres Cathedral evening office, ~20 worshippers (BigSoundBank s0506, CC0)",
    },
]


def download(url, dest_path, desc):
    print(f"  Downloading: {os.path.basename(dest_path)}")
    print(f"    URL : {url}")
    print(f"    Desc: {desc}")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read()
    with open(dest_path, "wb") as f:
        f.write(data)
    size_kb = len(data) // 1024
    print(f"    Raw : {size_kb} KB\n")
    return size_kb


def compress(path):
    tmp = path + ".tmp.mp3"
    size_before = os.path.getsize(path) // 1024
    result = subprocess.run(
        [
            "ffmpeg", "-y", "-i", path,
            "-ac", "1", "-ar", "44100", "-ab", "96k",
            "-codec:a", "libmp3lame", "-q:a", "5",
            tmp,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"    COMPRESS FAILED: {result.stderr[-200:]}", file=sys.stderr)
        if os.path.exists(tmp):
            os.remove(tmp)
        return
    os.replace(tmp, path)
    size_after = os.path.getsize(path) // 1024
    ratio = round((1 - size_after / size_before) * 100)
    print(f"    Compressed: {size_before} KB -> {size_after} KB ({ratio}% smaller)\n")


def main():
    os.makedirs(AMBIENT_DIR, exist_ok=True)
    print(f"Output dir: {AMBIENT_DIR}\n")
    failed = []
    for item in DOWNLOADS:
        dest = os.path.join(AMBIENT_DIR, item["dest"])
        try:
            download(item["url"], dest, item["desc"])
            compress(dest)
        except Exception as e:
            print(f"  FAILED: {e}\n", file=sys.stderr)
            failed.append(item["dest"])

    print("=" * 60)
    if failed:
        print(f"FAILED: {failed}")
        sys.exit(1)
    else:
        print("All community ambient files downloaded and compressed.")
        print("License: CC0 / Public Domain — Joseph SARDIN / BigSoundBank")


if __name__ == "__main__":
    main()
