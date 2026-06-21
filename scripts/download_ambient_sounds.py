"""
Download real ambient sound assets from the US National Park Service public domain
sound library (Rocky Mountain National Park). All recordings are in the public domain
and may be downloaded and used without limitation.
Source: https://www.nps.gov/romo/learn/photosmultimedia/sounds-ambient-soundscapes.htm
Credit: National Park Service / J. Job
"""

import urllib.request
import os
import sys

NPS_BASE = "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/"

# Map: local filename -> (NPS filename, description)
DOWNLOADS = {
    # 🏔 Mountain/Wind — commitment screens (sparse high-altitude wind at Gem Lake)
    "mountain.mp3": (
        "romo-WindAmbientGemLakeROMO52516Final1.mp3",
        "Wind at Gem Lake, Rocky Mountain NP - sparse mountain wind",
    ),
    # 🌾 Field/Tundra — assessment & alignment (open alpine tundra, Medicine Bow)
    "field.mp3": (
        "romo-TundraAmbientROMO6916MedicineBowTrailFinal1.mp3",
        "Tundra at Medicine Bow Trail, Rocky Mountain NP - open, expansive",
    ),
    # 🌲 Forest — faith questions & reflection (forest near Lawn Lake)
    "forest.mp3": (
        "romo-ForestAmbientNearLawnLakeROMO52616Final1.mp3",
        "Forest near Lawn Lake, Rocky Mountain NP - birds, trees",
    ),
    # 🌅 Sunset/Dusk — soul care & meditation (evening Moraine Park, frogs & birds)
    "sunset.mp3": (
        "romo-MoraineParkAmbient51916Final1.mp3",
        "Evening at Moraine Park, Rocky Mountain NP - frogs, hummingbirds, dusk",
    ),
    # ⭐ Stars/Night — prayer screens (dawn wetland Moraine Park, still & gentle)
    "stars.mp3": (
        "romo-MoraineWetlandAmbientROMO51816Final1.mp3",
        "Dawn wetland at Moraine Park, Rocky Mountain NP - still, peaceful",
    ),
    # 🏡 Home — home screen (dawn Sun Valley Trail, river & birds)
    "ambient-home.mp3": (
        "romo-DawnAmbientROMO6916SunValleyTrailFinal1.mp3",
        "Dawn at Sun Valley Trail, Rocky Mountain NP - river, uplifting",
    ),
    # 📖 Bible — bible screens (Finch Lake morning, alpine lake, serene)
    "ambient-bible.mp3": (
        "romo-FinchLakeAmbientROMO62016Final1.mp3",
        "Morning at Finch Lake, Rocky Mountain NP - alpine lake, contemplative",
    ),
    # 📅 Today/Daily — today screen (Big Meadows dawn, expansive morning)
    "ambient-today.mp3": (
        "romo-StreamAmbientROMO52516BlackCanyonTrailFinal1.mp3",
        "Stream at Black Canyon Trail, Rocky Mountain NP - flowing water, morning",
    ),
}

OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "assets", "audio", "ambient"
)


def download(local_name, nps_filename, description):
    url = NPS_BASE + nps_filename
    dest = os.path.join(OUTPUT_DIR, local_name)
    print(f"  Downloading: {local_name}")
    print(f"    Source : {url}")
    print(f"    Desc   : {description}")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as response:
            data = response.read()
        with open(dest, "wb") as f:
            f.write(data)
        size_kb = len(data) // 1024
        print(f"    OK     : {size_kb} KB written to {dest}\n")
        return True
    except Exception as e:
        print(f"    FAILED : {e}\n", file=sys.stderr)
        return False


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"Output directory: {OUTPUT_DIR}\n")
    failed = []
    for local_name, (nps_filename, description) in DOWNLOADS.items():
        ok = download(local_name, nps_filename, description)
        if not ok:
            failed.append(local_name)

    print("=" * 60)
    if failed:
        print(f"FAILED ({len(failed)}): {', '.join(failed)}")
        sys.exit(1)
    else:
        total = len(DOWNLOADS)
        print(f"All {total} ambient files downloaded successfully.")
        print("Credit: National Park Service, Rocky Mountain National Park")
        print("License: Public Domain - no restrictions on use.")


if __name__ == "__main__":
    main()
