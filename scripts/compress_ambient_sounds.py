"""
Compress ambient MP3 files to 96kbps mono for mobile app use.
Requires ffmpeg in PATH (installed via winget install Gyan.FFmpeg).
"""

import subprocess
import os
import sys

AMBIENT_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "assets", "audio", "ambient"
)

FILES = [
    "mountain.mp3",
    "field.mp3",
    "forest.mp3",
    "sunset.mp3",
    "stars.mp3",
    "ambient-home.mp3",
    "ambient-bible.mp3",
    "ambient-today.mp3",
]


def compress(filename):
    src = os.path.join(AMBIENT_DIR, filename)
    tmp = src + ".tmp.mp3"
    if not os.path.exists(src):
        print(f"  SKIP (not found): {src}")
        return

    size_before = os.path.getsize(src) // 1024
    print(f"  Compressing: {filename} ({size_before} KB) -> 96kbps mono ...")

    result = subprocess.run(
        [
            "ffmpeg", "-y",
            "-i", src,
            "-ac", "1",          # mono
            "-ar", "44100",      # 44.1kHz sample rate
            "-ab", "96k",        # 96 kbps bitrate
            "-codec:a", "libmp3lame",
            "-q:a", "5",         # VBR quality fallback
            tmp,
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print(f"  FAILED: {result.stderr[-300:]}", file=sys.stderr)
        if os.path.exists(tmp):
            os.remove(tmp)
        return

    os.replace(tmp, src)
    size_after = os.path.getsize(src) // 1024
    ratio = round((1 - size_after / size_before) * 100)
    print(f"  OK: {size_before} KB -> {size_after} KB ({ratio}% smaller)\n")


def main():
    print(f"Ambient dir: {AMBIENT_DIR}\n")
    for f in FILES:
        compress(f)
    print("Done.")


if __name__ == "__main__":
    main()
