#!/usr/bin/env python3
"""Import the supplied God of Thunder soundtrack as GameMaker sound resources."""

from __future__ import annotations
import argparse
import json
import re
import shutil
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_STUFF = Path(r"C:\Users\Zach\Downloads\GOTstuff\GOTstuff")
TRACKS = {
    "action1": 137.77, "action2": 71.76, "action3": 150.07,
    "adventure1": 205.74, "adventure2": 160.89, "adventure3": 113.95,
    "boss": 54.41,
    "creepy1": 121.89, "creepy2": 145.82, "creepy3": 160.97,
    "opening": 149.68,
    "puzzle1": 257.75, "puzzle2": 176.48, "puzzle3": 202.14,
    "puzzle4": 119.80, "sad": 97.85, "scary": 134.95, "win": 67.81,
}


def sound_resource(name: str, filename: str, duration: float) -> dict:
    return {
        "$GMSound": "v2",
        "%Name": name,
        "audioGroupId": {
            "name": "audiogroup_default",
            "path": "audiogroups/audiogroup_default",
        },
        "bitDepth": 1,
        "channelFormat": 0,
        "compression": 0,
        "compressionQuality": 4,
        "conversionMode": 0,
        "duration": duration,
        "exportDir": "",
        "name": name,
        "parent": {"name": "Original Music", "path": "folders/Sounds/Original Music.yy"},
        "preload": False,
        "resourceType": "GMSound",
        "resourceVersion": "2.0",
        "sampleRate": 44100,
        "soundFile": filename,
        "volume": 0.55,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stuff", type=Path, default=DEFAULT_STUFF)
    args = parser.parse_args()
    source_dir = args.stuff / "songs"
    project_path = PROJECT_DIR / "gotgm.yyp"
    project_text = project_path.read_text(encoding="utf-8-sig")
    project_text = re.sub(r",(?=\s*[}\]])", "", project_text)
    project = json.loads(project_text)

    music_script = {"id": {"name": "scr_music", "path": "scripts/scr_music/scr_music.yy"}}
    if not any(item["id"]["name"] == "scr_music" for item in project["resources"]):
        project["resources"].append(music_script)

    names = {f"mus_got_{track}" for track in TRACKS}
    project["resources"] = [
        item for item in project["resources"] if item["id"]["name"] not in names
    ]
    for track, duration in TRACKS.items():
        name = f"mus_got_{track}"
        source = source_dir / f"{track}.mp3"
        if not source.exists():
            raise FileNotFoundError(source)
        target_dir = PROJECT_DIR / "sounds" / name
        target_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{name}.mp3"
        shutil.copyfile(source, target_dir / filename)
        (target_dir / f"{name}.yy").write_text(
            json.dumps(sound_resource(name, filename, duration), indent=2) + "\n",
            encoding="utf-8",
        )
        project["resources"].append({
            "id": {"name": name, "path": f"sounds/{name}/{name}.yy"}
        })

    folder_path = "folders/Sounds/Original Music.yy"
    if not any(folder.get("folderPath") == folder_path for folder in project["Folders"]):
        project["Folders"].append({
            "$GMFolder": "",
            "%Name": "Original Music",
            "folderPath": folder_path,
            "name": "Original Music",
            "resourceType": "GMFolder",
            "resourceVersion": "2.0",
        })

    project_path.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")
    print(f"Imported {len(TRACKS)} soundtrack files from {source_dir}")


if __name__ == "__main__":
    main()
