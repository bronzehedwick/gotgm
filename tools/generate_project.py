#!/usr/bin/env python3
"""
Generate a GameMaker 2024.x project for God of Thunder.

Creates the full .yyp project structure with:
  - Sprites imported from extracted assets
  - Objects with GML event code
  - Scripts for engine systems
  - A playable room

Usage:
    python3 tools/generate_project.py

Reads extracted assets from: ../extracted/
Writes GameMaker project to: current directory (gotgm/)
"""

import json
import os
import shutil
import uuid
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
EXTRACTED_DIR = PROJECT_DIR.parent / "extracted"

PROJECT_NAME = "gotgm"

# ---------------------------------------------------------------------------
# UUID helper
# ---------------------------------------------------------------------------
def new_guid():
    """Generate a GameMaker-style GUID."""
    return str(uuid.uuid4())

# ---------------------------------------------------------------------------
# Folder registry (for .yyp Folders array)
# ---------------------------------------------------------------------------
FOLDERS = []
RESOURCES = []
ROOM_ORDER = []

def register_folder(name, parent_path=""):
    """Register a folder and return its path string."""
    if parent_path:
        folder_path = f"folders/{parent_path}/{name}.yy"
    else:
        folder_path = f"folders/{name}.yy"

    FOLDERS.append({
        "resourceType": "GMFolder",
        "resourceVersion": "1.0",
        "name": name,
        "folderPath": folder_path,
    })

    if parent_path:
        return f"{parent_path}/{name}"
    return name

def register_resource(name, path):
    """Register a resource for the .yyp resources array."""
    RESOURCES.append({
        "id": {
            "name": name,
            "path": path,
        }
    })

def register_room(name, path):
    """Register a room in the room order."""
    ROOM_ORDER.append({
        "roomId": {
            "name": name,
            "path": path,
        }
    })

# ---------------------------------------------------------------------------
# Sprite creation
# ---------------------------------------------------------------------------
def create_sprite(name, folder_path, source_png, frame_width, frame_height,
                  num_frames, origin_x=0, origin_y=0,
                  cols=None, start_frame=0, max_frames=None):
    """
    Create a GameMaker sprite resource from a spritesheet.

    Args:
        name: Sprite resource name (e.g., "spr_player_down")
        folder_path: Parent folder path
        source_png: Path to source spritesheet PNG
        frame_width: Width of each frame
        frame_height: Height of each frame
        num_frames: Number of frames to extract
        origin_x/y: Sprite origin
        cols: Columns in spritesheet (default: auto from image width)
        start_frame: Starting frame index in spritesheet
        max_frames: Max frames to extract (default: num_frames)
    """
    from PIL import Image

    sprite_dir = PROJECT_DIR / "sprites" / name
    sprite_dir.mkdir(parents=True, exist_ok=True)

    img = Image.open(source_png)
    if cols is None:
        cols = img.width // frame_width

    if max_frames is None:
        max_frames = num_frames

    # Generate frame GUIDs
    frames = []
    layer_guid = new_guid()

    for i in range(num_frames):
        src_idx = start_frame + i
        col = src_idx % cols
        row = src_idx // cols

        x = col * frame_width
        y = row * frame_height

        frame_img = img.crop((x, y, x + frame_width, y + frame_height))

        frame_guid = new_guid()

        # Create layer directory and save frame
        layer_dir = sprite_dir / "layers" / layer_guid
        layer_dir.mkdir(parents=True, exist_ok=True)
        frame_img.save(layer_dir / f"{frame_guid}.png")

        # Also save composite image
        frame_img.save(sprite_dir / f"{frame_guid}.png")

        frames.append({
            "resourceType": "GMSpriteFrame",
            "resourceVersion": "2.0",
            "name": frame_guid,
            "compositeImage": {
                "resourceType": "GMSpriteImage",
                "resourceVersion": "2.0",
                "name": "",
                "FrameId": {"name": frame_guid, "path": f"sprites/{name}/{name}.yy"},
                "LayerId": None,
            },
            "images": [
                {
                    "resourceType": "GMSpriteImage",
                    "resourceVersion": "2.0",
                    "name": "",
                    "FrameId": {"name": frame_guid, "path": f"sprites/{name}/{name}.yy"},
                    "LayerId": {"name": layer_guid, "path": f"sprites/{name}/{name}.yy"},
                }
            ],
        })

    # Write sprite .yy
    sprite_yy = {
        "resourceType": "GMSprite",
        "resourceVersion": "2.0",
        "name": name,
        "bbox_bottom": frame_height - 1,
        "bbox_left": 0,
        "bbox_right": frame_width - 1,
        "bbox_top": 0,
        "bboxMode": 0,
        "collisionKind": 1,
        "collisionTolerance": 0,
        "DynamicTexturePage": False,
        "edgeFiltering": False,
        "For3D": False,
        "frames": frames,
        "gridX": 0,
        "gridY": 0,
        "height": frame_height,
        "HTile": False,
        "layers": [
            {
                "resourceType": "GMImageLayer",
                "resourceVersion": "2.0",
                "name": layer_guid,
                "blendMode": 0,
                "displayName": "default",
                "isLocked": False,
                "opacity": 100.0,
                "visible": True,
            }
        ],
        "nineSlice": None,
        "origin": 0,
        "parent": {
            "name": folder_path.split("/")[-1] if "/" in folder_path else folder_path,
            "path": f"folders/{folder_path}.yy",
        },
        "preMultiplyAlpha": False,
        "sequence": {
            "resourceType": "GMSequence",
            "resourceVersion": "2.0",
            "name": name,
            "autoRecord": True,
            "backdropHeight": 768,
            "backdropImageOpacity": 0.5,
            "backdropImagePath": "",
            "backdropWidth": 1366,
            "backdropXOffset": 0.0,
            "backdropYOffset": 0.0,
            "events": {"resourceType": "KeyframeStore<MessageEventKeyframe>", "resourceVersion": "2.0", "Keyframes": []},
            "eventStubScript": None,
            "eventToFunction": {},
            "length": float(num_frames),
            "lockOrigin": False,
            "moments": {"resourceType": "KeyframeStore<MomentsEventKeyframe>", "resourceVersion": "2.0", "Keyframes": []},
            "playback": 1,
            "playbackSpeed": 8.0,
            "playbackSpeedType": 0,
            "showBackdrop": True,
            "showBackdropImage": False,
            "timeUnits": 1,
            "tracks": [
                {
                    "resourceType": "GMSpriteFramesTrack",
                    "resourceVersion": "2.0",
                    "name": "frames",
                    "builtinName": 0,
                    "events": [],
                    "inheritsTrackColour": True,
                    "interpolation": 1,
                    "isCreationTrack": False,
                    "keyframes": {
                        "resourceType": "KeyframeStore<SpriteFrameKeyframe>",
                        "resourceVersion": "2.0",
                        "Keyframes": [
                            {
                                "resourceType": "Keyframe<SpriteFrameKeyframe>",
                                "resourceVersion": "2.0",
                                "Channels": {
                                    "0": {
                                        "resourceType": "SpriteFrameKeyframe",
                                        "resourceVersion": "2.0",
                                        "Id": {"name": f["name"], "path": f"sprites/{name}/{name}.yy"},
                                    }
                                },
                                "Disabled": False,
                                "id": new_guid(),
                                "IsCreationKey": False,
                                "Key": float(idx),
                                "Length": 1.0,
                                "Stretch": False,
                            }
                            for idx, f in enumerate(frames)
                        ],
                    },
                    "modifiers": [],
                    "spriteId": None,
                    "trackColour": 0,
                    "tracks": [],
                    "traits": 0,
                }
            ],
            "visibleRange": None,
            "volume": 1.0,
            "xorigin": origin_x,
            "yorigin": origin_y,
        },
        "swatchColours": None,
        "swfPrecision": 0.5,
        "textureGroupId": {
            "name": "Default",
            "path": "texturegroups/Default",
        },
        "type": 0,
        "VTile": False,
        "width": frame_width,
    }

    with open(sprite_dir / f"{name}.yy", 'w') as f:
        json.dump(sprite_yy, f, indent=2)

    register_resource(name, f"sprites/{name}/{name}.yy")
    return name


def create_sprite_from_image(name, folder_path, source_png, origin_x=0, origin_y=0):
    """Create a single-frame sprite from an entire image."""
    from PIL import Image
    img = Image.open(source_png)

    sprite_dir = PROJECT_DIR / "sprites" / name
    sprite_dir.mkdir(parents=True, exist_ok=True)

    layer_guid = new_guid()
    frame_guid = new_guid()

    # Save frame
    layer_dir = sprite_dir / "layers" / layer_guid
    layer_dir.mkdir(parents=True, exist_ok=True)
    img.save(layer_dir / f"{frame_guid}.png")
    img.save(sprite_dir / f"{frame_guid}.png")

    frames = [{
        "resourceType": "GMSpriteFrame",
        "resourceVersion": "2.0",
        "name": frame_guid,
        "compositeImage": {
            "resourceType": "GMSpriteImage",
            "resourceVersion": "2.0",
            "name": "",
            "FrameId": {"name": frame_guid, "path": f"sprites/{name}/{name}.yy"},
            "LayerId": None,
        },
        "images": [{
            "resourceType": "GMSpriteImage",
            "resourceVersion": "2.0",
            "name": "",
            "FrameId": {"name": frame_guid, "path": f"sprites/{name}/{name}.yy"},
            "LayerId": {"name": layer_guid, "path": f"sprites/{name}/{name}.yy"},
        }],
    }]

    sprite_yy = {
        "resourceType": "GMSprite",
        "resourceVersion": "2.0",
        "name": name,
        "bbox_bottom": img.height - 1,
        "bbox_left": 0,
        "bbox_right": img.width - 1,
        "bbox_top": 0,
        "bboxMode": 0,
        "collisionKind": 1,
        "collisionTolerance": 0,
        "DynamicTexturePage": False,
        "edgeFiltering": False,
        "For3D": False,
        "frames": frames,
        "gridX": 0,
        "gridY": 0,
        "height": img.height,
        "HTile": False,
        "layers": [{
            "resourceType": "GMImageLayer",
            "resourceVersion": "2.0",
            "name": layer_guid,
            "blendMode": 0,
            "displayName": "default",
            "isLocked": False,
            "opacity": 100.0,
            "visible": True,
        }],
        "nineSlice": None,
        "origin": 0,
        "parent": {
            "name": folder_path.split("/")[-1] if "/" in folder_path else folder_path,
            "path": f"folders/{folder_path}.yy",
        },
        "preMultiplyAlpha": False,
        "sequence": {
            "resourceType": "GMSequence",
            "resourceVersion": "2.0",
            "name": name,
            "autoRecord": True,
            "backdropHeight": 768,
            "backdropImageOpacity": 0.5,
            "backdropImagePath": "",
            "backdropWidth": 1366,
            "backdropXOffset": 0.0,
            "backdropYOffset": 0.0,
            "events": {"resourceType": "KeyframeStore<MessageEventKeyframe>", "resourceVersion": "2.0", "Keyframes": []},
            "eventStubScript": None,
            "eventToFunction": {},
            "length": 1.0,
            "lockOrigin": False,
            "moments": {"resourceType": "KeyframeStore<MomentsEventKeyframe>", "resourceVersion": "2.0", "Keyframes": []},
            "playback": 1,
            "playbackSpeed": 8.0,
            "playbackSpeedType": 0,
            "showBackdrop": True,
            "showBackdropImage": False,
            "timeUnits": 1,
            "tracks": [{
                "resourceType": "GMSpriteFramesTrack",
                "resourceVersion": "2.0",
                "name": "frames",
                "builtinName": 0,
                "events": [],
                "inheritsTrackColour": True,
                "interpolation": 1,
                "isCreationTrack": False,
                "keyframes": {
                    "resourceType": "KeyframeStore<SpriteFrameKeyframe>",
                    "resourceVersion": "2.0",
                    "Keyframes": [{
                        "resourceType": "Keyframe<SpriteFrameKeyframe>",
                        "resourceVersion": "2.0",
                        "Channels": {"0": {
                            "resourceType": "SpriteFrameKeyframe",
                            "resourceVersion": "2.0",
                            "Id": {"name": frame_guid, "path": f"sprites/{name}/{name}.yy"},
                        }},
                        "Disabled": False,
                        "id": new_guid(),
                        "IsCreationKey": False,
                        "Key": 0.0,
                        "Length": 1.0,
                        "Stretch": False,
                    }],
                },
                "modifiers": [],
                "spriteId": None,
                "trackColour": 0,
                "tracks": [],
                "traits": 0,
            }],
            "visibleRange": None,
            "volume": 1.0,
            "xorigin": origin_x,
            "yorigin": origin_y,
        },
        "swatchColours": None,
        "swfPrecision": 0.5,
        "textureGroupId": {"name": "Default", "path": "texturegroups/Default"},
        "type": 0,
        "VTile": False,
        "width": img.width,
    }

    with open(sprite_dir / f"{name}.yy", 'w') as f:
        json.dump(sprite_yy, f, indent=2)

    register_resource(name, f"sprites/{name}/{name}.yy")
    return name


# ---------------------------------------------------------------------------
# Object creation
# ---------------------------------------------------------------------------
EVENT_TYPE_MAP = {
    "Create_0": (0, 0),
    "Step_0": (3, 0),
    "Step_1": (3, 1),   # Begin Step
    "Step_2": (3, 2),   # End Step
    "Draw_0": (8, 0),
    "Draw_64": (8, 64), # Draw GUI
    "Draw_72": (8, 72), # Draw GUI Begin
    "Draw_73": (8, 73), # Draw GUI End
    "Alarm_0": (2, 0),
    "Alarm_1": (2, 1),
    "Alarm_2": (2, 2),
    "CleanUp_0": (12, 0),
    "Destroy_0": (1, 0),
    "Other_4": (7, 4),  # Room Start
    "Other_10": (7, 10), # Game Start
}


def create_object(name, folder_path, events=None, sprite_name=None,
                  parent_object=None, persistent=False, visible=True):
    """
    Create a GameMaker object resource.

    Args:
        name: Object resource name
        folder_path: Parent folder path
        events: Dict of {event_file: gml_code} e.g. {"Create_0": "x = 0;"}
        sprite_name: Associated sprite name
        parent_object: Parent object name
        persistent: Whether object persists across rooms
        visible: Whether object is visible
    """
    obj_dir = PROJECT_DIR / "objects" / name
    obj_dir.mkdir(parents=True, exist_ok=True)

    if events is None:
        events = {}

    event_list = []
    for event_file, code in events.items():
        # Write GML file
        with open(obj_dir / f"{event_file}.gml", 'w') as f:
            f.write(code)

        if event_file in EVENT_TYPE_MAP:
            etype, enum = EVENT_TYPE_MAP[event_file]
        else:
            continue

        event_list.append({
            "resourceType": "GMEvent",
            "resourceVersion": "2.0",
            "name": "",
            "collisionObjectId": None,
            "eventNum": enum,
            "eventType": etype,
            "isDnD": False,
        })

    sprite_ref = None
    if sprite_name:
        sprite_ref = {"name": sprite_name, "path": f"sprites/{sprite_name}/{sprite_name}.yy"}

    parent_ref = None
    if parent_object:
        parent_ref = {"name": parent_object, "path": f"objects/{parent_object}/{parent_object}.yy"}

    obj_yy = {
        "resourceType": "GMObject",
        "resourceVersion": "2.0",
        "name": name,
        "eventList": event_list,
        "managed": True,
        "overriddenProperties": [],
        "parent": {
            "name": folder_path.split("/")[-1] if "/" in folder_path else folder_path,
            "path": f"folders/{folder_path}.yy",
        },
        "parentObjectId": parent_ref,
        "persistent": persistent,
        "physicsAngularDamping": 0.1,
        "physicsDensity": 0.5,
        "physicsFriction": 0.2,
        "physicsGroup": 1,
        "physicsKinematic": False,
        "physicsLinearDamping": 0.1,
        "physicsObject": False,
        "physicsRestitution": 0.1,
        "physicsSensor": False,
        "physicsShape": 1,
        "physicsShapePoints": [],
        "physicsStartAwake": True,
        "properties": [],
        "solid": False,
        "spriteId": sprite_ref,
        "visible": visible,
    }

    with open(obj_dir / f"{name}.yy", 'w') as f:
        json.dump(obj_yy, f, indent=2)

    register_resource(name, f"objects/{name}/{name}.yy")
    return name


# ---------------------------------------------------------------------------
# Script creation
# ---------------------------------------------------------------------------
def create_script(name, folder_path, code):
    """Create a GameMaker script resource."""
    script_dir = PROJECT_DIR / "scripts" / name
    script_dir.mkdir(parents=True, exist_ok=True)

    # Write GML
    with open(script_dir / f"{name}.gml", 'w') as f:
        f.write(code)

    # Write .yy
    script_yy = {
        "resourceType": "GMScript",
        "resourceVersion": "2.0",
        "name": name,
        "isCompatibility": False,
        "isDnD": False,
        "parent": {
            "name": folder_path.split("/")[-1] if "/" in folder_path else folder_path,
            "path": f"folders/{folder_path}.yy",
        },
    }

    with open(script_dir / f"{name}.yy", 'w') as f:
        json.dump(script_yy, f, indent=2)

    register_resource(name, f"scripts/{name}/{name}.yy")
    return name


# ---------------------------------------------------------------------------
# Room creation
# ---------------------------------------------------------------------------
def create_room(name, folder_path, width, height, instances=None):
    """Create a GameMaker room resource."""
    room_dir = PROJECT_DIR / "rooms" / name
    room_dir.mkdir(parents=True, exist_ok=True)

    if instances is None:
        instances = []

    bg_layer_guid = new_guid()
    inst_layer_guid = new_guid()

    instance_entries = []
    for inst in instances:
        inst_guid = new_guid()
        instance_entries.append({
            "resourceType": "GMRInstance",
            "resourceVersion": "2.0",
            "name": inst_guid,
            "colour": 4294967295,
            "frozen": False,
            "hasCreationCode": False,
            "ignore": False,
            "imageIndex": 0,
            "imageSpeed": 1.0,
            "inheritCode": False,
            "inheritedItemId": None,
            "inheritItemSettings": False,
            "isDnd": False,
            "objectId": {
                "name": inst["object"],
                "path": f"objects/{inst['object']}/{inst['object']}.yy",
            },
            "properties": [],
            "rotation": 0.0,
            "scaleX": 1.0,
            "scaleY": 1.0,
            "x": inst.get("x", 0),
            "y": inst.get("y", 0),
        })

    room_yy = {
        "resourceType": "GMRoom",
        "resourceVersion": "2.0",
        "name": name,
        "creationCodeFile": "",
        "inheritCode": False,
        "inheritCreationOrder": False,
        "inheritLayers": False,
        "instanceCreationOrder": [
            {"name": inst["name"], "path": f"rooms/{name}/{name}.yy"}
            for inst in instance_entries
        ],
        "isDnd": False,
        "layers": [
            {
                "resourceType": "GMRInstanceLayer",
                "resourceVersion": "2.0",
                "name": "Instances",
                "depth": 0,
                "effectEnabled": True,
                "effectType": None,
                "gridX": 16,
                "gridY": 16,
                "hierarchyFrozen": False,
                "inheritLayerDepth": False,
                "inheritLayerSettings": False,
                "inheritSubLayers": False,
                "inheritVisibility": False,
                "instances": instance_entries,
                "layers": [],
                "properties": [],
                "userdefinedDepth": False,
                "visible": True,
            },
            {
                "resourceType": "GMRBackgroundLayer",
                "resourceVersion": "2.0",
                "name": "Background",
                "animationFPS": 15.0,
                "animationSpeedType": 0,
                "colour": 4278190080,
                "depth": 100,
                "effectEnabled": True,
                "effectType": None,
                "gridX": 32,
                "gridY": 32,
                "hierarchyFrozen": False,
                "hspeed": 0.0,
                "htiled": False,
                "inheritLayerDepth": False,
                "inheritLayerSettings": False,
                "inheritSubLayers": False,
                "inheritVisibility": False,
                "layers": [],
                "properties": [],
                "spriteId": None,
                "stretch": False,
                "userdefinedAnimFPS": False,
                "userdefinedDepth": False,
                "visible": True,
                "vspeed": 0.0,
                "vtiled": False,
                "x": 0,
                "y": 0,
            },
        ],
        "parent": {
            "name": folder_path.split("/")[-1] if "/" in folder_path else folder_path,
            "path": f"folders/{folder_path}.yy",
        },
        "parentRoom": None,
        "physicsSettings": {
            "inheritPhysicsSettings": False,
            "PhysicsWorld": False,
            "PhysicsWorldGravityX": 0.0,
            "PhysicsWorldGravityY": 10.0,
            "PhysicsWorldPixToMetres": 0.1,
        },
        "roomSettings": {
            "inheritRoomSettings": False,
            "Width": width,
            "Height": height,
        },
        "sequenceId": None,
        "views": [
            {
                "hborder": 32,
                "hport": 768,
                "hspeed": -1,
                "hview": 192,
                "inherit": False,
                "objectId": None,
                "vborder": 32,
                "visible": True if i == 0 else False,
                "vspeed": -1,
                "wport": 1280,
                "wview": 320,
                "xport": 0,
                "xview": 0,
                "yborder": 32,
                "yport": 0,
                "yview": 0,
            }
            for i in range(8)
        ],
        "viewSettings": {
            "inheritViewSettings": False,
            "enableViews": True,
            "clearDisplayBuffer": True,
            "clearViewBackground": True,
        },
        "volumes": [],
    }

    with open(room_dir / f"{name}.yy", 'w') as f:
        json.dump(room_yy, f, indent=2)

    register_resource(name, f"rooms/{name}/{name}.yy")
    register_room(name, f"rooms/{name}/{name}.yy")
    return name


# ---------------------------------------------------------------------------
# .yyp project file
# ---------------------------------------------------------------------------
def write_yyp():
    """Write the main project file."""
    yyp = {
        "resourceType": "GMProject",
        "resourceVersion": "2.0",
        "name": PROJECT_NAME,
        "AudioGroups": [
            {
                "resourceType": "GMAudioGroup",
                "resourceVersion": "2.0",
                "name": "audiogroup_default",
                "targets": 461609314234257646,
            }
        ],
        "configs": {
            "children": [],
            "name": "Default",
        },
        "defaultScriptType": 1,
        "Folders": FOLDERS,
        "IncludedFiles": [],
        "isEcma": False,
        "LibraryEmitters": [],
        "MetaData": {
            "IDEVersion": "2024.14.4.222",
        },
        "resources": RESOURCES,
        "RoomOrderNodes": ROOM_ORDER,
        "templateType": None,
        "textureGroups": [
            {
                "resourceType": "GMTextureGroup",
                "resourceVersion": "2.0",
                "name": "Default",
                "autocrop": True,
                "border": 2,
                "compressFormat": "bz2",
                "directory": "",
                "groupParent": None,
                "isScaled": True,
                "loadType": "default",
                "mipsToGenerate": 0,
                "targets": 461609314234257646,
                "texturePageHeight": 2048,
                "texturePageWidth": 2048,
            }
        ],
    }

    with open(PROJECT_DIR / f"{PROJECT_NAME}.yyp", 'w') as f:
        json.dump(yyp, f, indent=2)


# ---------------------------------------------------------------------------
# Copy datafiles (level JSON for runtime loading)
# ---------------------------------------------------------------------------
def setup_datafiles():
    """Copy extracted level data to IncludedFiles for runtime access."""
    data_dir = PROJECT_DIR / "datafiles" / "data"
    data_dir.mkdir(parents=True, exist_ok=True)

    # Copy level data
    for ep in [1, 2, 3]:
        src = EXTRACTED_DIR / "levels" / f"sdat{ep}.json"
        if src.exists():
            shutil.copy2(src, data_dir / f"sdat{ep}.json")

    # Copy actor definitions
    actor_dir = data_dir / "actors"
    actor_dir.mkdir(exist_ok=True)
    for json_file in sorted(EXTRACTED_DIR.glob("actors/actor*.json")):
        shutil.copy2(json_file, actor_dir / json_file.name)

    # Copy palette
    pal_src = EXTRACTED_DIR / "palette.json"
    if pal_src.exists():
        shutil.copy2(pal_src, data_dir / "palette.json")


# ---------------------------------------------------------------------------
# Main generation
# ---------------------------------------------------------------------------
def main():
    print("Generating God of Thunder GameMaker project...")
    print(f"  Project dir: {PROJECT_DIR}")
    print(f"  Extracted assets: {EXTRACTED_DIR}")

    # Check PIL
    try:
        from PIL import Image
    except ImportError:
        print("ERROR: Pillow is required. Install with: pip install Pillow")
        return

    # Check extracted assets exist
    if not EXTRACTED_DIR.exists():
        print(f"ERROR: Extracted assets not found at {EXTRACTED_DIR}")
        return

    # -----------------------------------------------------------------------
    # Register folders
    # -----------------------------------------------------------------------
    register_folder("Sprites")
    spr_chars = register_folder("Characters", "Sprites")
    spr_tiles = register_folder("Tiles", "Sprites")
    spr_objects = register_folder("Objects", "Sprites")
    spr_enemies = register_folder("Enemies", "Sprites")
    spr_ui = register_folder("UI", "Sprites")

    register_folder("Objects")
    obj_engine = register_folder("Engine", "Objects")
    obj_actors = register_folder("Actors", "Objects")
    obj_items = register_folder("Items", "Objects")

    register_folder("Scripts")
    scr_engine = register_folder("Engine", "Scripts")
    scr_actor = register_folder("Actor", "Scripts")
    scr_level = register_folder("Level", "Scripts")
    scr_combat = register_folder("Combat", "Scripts")

    register_folder("Rooms")

    # -----------------------------------------------------------------------
    # Import sprites
    # -----------------------------------------------------------------------
    print("  Importing sprites...")

    # Thor - 4 directions, 4 frames each
    # Spritesheet is 10 cols x 2 rows = 20 frames
    # Directions: 0=down, 1=up, 2=left, 3=right (based on GOT convention)
    # Layout in sheet: frames 0-3 = dir0, 4-7 = dir1, 8-11 = dir2, 12-15 = dir3
    thor_png = EXTRACTED_DIR / "actors" / "actor100.png"
    for d, dname in enumerate(["down", "up", "left", "right"]):
        create_sprite(
            f"spr_thor_{dname}", spr_chars, thor_png,
            16, 16, 4, cols=10, start_frame=d * 4
        )

    # Hammer - 4 directions, 4 frames each
    hammer_png = EXTRACTED_DIR / "actors" / "actor103.png"
    for d, dname in enumerate(["down", "up", "left", "right"]):
        create_sprite(
            f"spr_hammer_{dname}", spr_chars, hammer_png,
            16, 16, 4, cols=10, start_frame=d * 4
        )

    # Tileset - full tilesheet as single sprite for drawing
    create_sprite_from_image("spr_tileset_ep1", spr_tiles,
                             EXTRACTED_DIR / "tiles" / "bpics1.png")

    # Objects/pickups spritesheet
    create_sprite_from_image("spr_objects", spr_objects,
                             EXTRACTED_DIR / "objects" / "objects.png")

    # Status bar HUD
    create_sprite_from_image("spr_status_bar", spr_ui,
                             EXTRACTED_DIR / "status.png")

    # Enemy: actor 2 = BOINGY (common early enemy)
    enemy_png = EXTRACTED_DIR / "actors" / "actor2.png"
    # 1 direction, 4 frames for simple enemies
    create_sprite(
        "spr_enemy_boingy", spr_enemies, enemy_png,
        16, 16, 4, cols=10, start_frame=0
    )

    # Enemy: actor 6 (common in level 1 and 11)
    actor6_json = json.load(open(EXTRACTED_DIR / "actors" / "actor6.json"))
    a6_name = actor6_json["actor_info"]["name"]
    a6_dirs = actor6_json["actor_info"]["directions"]
    a6_frames = actor6_json["actor_info"]["frames"]
    print(f"    Actor 6: {a6_name}, {a6_dirs} dirs, {a6_frames} frames")
    enemy6_png = EXTRACTED_DIR / "actors" / "actor6.png"
    create_sprite(
        f"spr_enemy_{a6_name.lower()}", spr_enemies, enemy6_png,
        16, 16, a6_frames, cols=10, start_frame=0
    )

    # Font atlas
    create_sprite_from_image("spr_font", spr_ui,
                             EXTRACTED_DIR / "font.png")

    print("  Sprites done.")

    # -----------------------------------------------------------------------
    # Copy data files
    # -----------------------------------------------------------------------
    print("  Copying data files...")
    setup_datafiles()
    print("  Data files done.")

    # -----------------------------------------------------------------------
    # Create scripts
    # -----------------------------------------------------------------------
    print("  Creating scripts...")
    create_scripts(scr_engine, scr_actor, scr_level, scr_combat)
    print("  Scripts done.")

    # -----------------------------------------------------------------------
    # Create objects
    # -----------------------------------------------------------------------
    print("  Creating objects...")
    create_objects(obj_engine, obj_actors, obj_items)
    print("  Objects done.")

    # -----------------------------------------------------------------------
    # Create room
    # -----------------------------------------------------------------------
    print("  Creating room...")
    create_room("rm_game", "Rooms", 320, 192, instances=[
        {"object": "obj_game", "x": 0, "y": 0},
    ])
    print("  Room done.")

    # -----------------------------------------------------------------------
    # Write .yyp
    # -----------------------------------------------------------------------
    print("  Writing project file...")
    write_yyp()
    print("  Project file done.")

    print(f"\nProject generated at: {PROJECT_DIR}/{PROJECT_NAME}.yyp")
    print("Open this file in GameMaker to load the project.")


# ===========================================================================
# Script content
# ===========================================================================
def create_scripts(scr_engine, scr_actor, scr_level, scr_combat):
    """Create all GML script resources."""

    # -- scr_globals --
    create_script("scr_globals", scr_engine, """\
/// @description Global constants and initialization

// Tile / screen constants
#macro TILE_W 16
#macro TILE_H 16
#macro GRID_COLS 20
#macro GRID_ROWS 12
#macro SCREEN_W 320
#macro SCREEN_H 192

// Tile collision thresholds (from original MOVPAT.C)
#macro TILE_SOLID 80
#macro TILE_FLY 140
#macro TILE_SPECIAL 200

// Directions
enum Dir {
    DOWN  = 0,
    UP    = 1,
    LEFT  = 2,
    RIGHT = 3,
}

// Max values
#macro MAX_HEALTH 150
#macro MAX_MAGIC  150
#macro MAX_JEWELS 999
#macro MAX_SCORE  999999
#macro MAX_KEYS   99
#macro MAX_ACTORS 16

// World grid
#macro WORLD_COLS 10
#macro WORLD_ROWS 12

/// @function game_init()
/// @description Initialize all global game state
function game_init() {
    // Player state
    global.health = 150;
    global.magic = 0;
    global.jewels = 0;
    global.score = 0;
    global.keys = 0;
    global.difficulty = 1; // 0=easy, 1=normal, 2=hard

    // Current level
    global.current_level = 11; // Starting level for Episode 1
    global.current_episode = 1;

    // Level data (loaded from JSON)
    global.level_data = undefined;
    global.tile_grid = undefined;

    // Inventory flags
    global.inventory = {};

    // Game flags (progression)
    global.flags = {};

    // Actor references
    global.player = noone;
    global.hammer = noone;

    // Palette (loaded from JSON)
    global.palette = undefined;

    // Debug
    global.debug_mode = true;
}
""")

    # -- scr_level --
    create_script("scr_level", scr_level, """\
/// @description Level loading and management

/// @function level_load(level_index)
/// @description Load a level from the episode data
/// @param {real} level_index The level index (0-119)
function level_load(level_index) {
    // Load episode data if not already loaded
    if (global.level_data == undefined) {
        var _file = file_text_open_read("data/sdat" + string(global.current_episode) + ".json");
        if (_file == -1) {
            show_debug_message("ERROR: Could not load level data for episode " + string(global.current_episode));
            return;
        }
        var _str = "";
        while (!file_text_eof(_file)) {
            _str += file_text_readln(_file);
        }
        file_text_close(_file);
        global.level_data = json_parse(_str);
    }

    var _level = global.level_data[level_index];
    global.current_level = level_index;

    // Store tile grid
    global.tile_grid = _level.icon_grid;

    // Clear existing actors (except player and hammer)
    with (obj_enemy) { instance_destroy(); }
    with (obj_pickup) { instance_destroy(); }

    // Spawn actors
    var _actors = _level.actors;
    for (var i = 0; i < 16; i++) {
        var _type = _actors.type[i];
        if (_type > 0) {
            var _loc = _actors.location[i];
            var _tx = (_loc mod GRID_COLS) * TILE_W;
            var _ty = (_loc div GRID_COLS) * TILE_H;
            var _val = _actors.value[i];
            var _dir = _actors.direction[i];
            actor_spawn(_type, _tx, _ty, _val, _dir);
        }
    }

    // Spawn static objects (pickups)
    var _objs = _level.static_objects;
    for (var i = 0; i < 30; i++) {
        var _type = _objs.type[i];
        if (_type > 0) {
            var _ox = _objs.x[i] * TILE_W;
            var _oy = _objs.y[i] * TILE_H;
            pickup_spawn(_type, _ox, _oy);
        }
    }

    show_debug_message("Loaded level " + string(level_index));
}

/// @function level_draw_tiles()
/// @description Draw the tile grid for the current level
function level_draw_tiles() {
    if (global.tile_grid == undefined) return;

    var _tileset = spr_tileset_ep1;
    // Tileset is 16 columns wide (256px / 16px)
    var _ts_cols = 16;

    for (var _row = 0; _row < GRID_ROWS; _row++) {
        for (var _col = 0; _col < GRID_COLS; _col++) {
            var _tile_id = global.tile_grid[_row][_col];

            // Calculate source position in tileset
            var _sx = (_tile_id mod _ts_cols) * TILE_W;
            var _sy = (_tile_id div _ts_cols) * TILE_H;

            // Draw tile
            draw_sprite_part(_tileset, 0, _sx, _sy, TILE_W, TILE_H,
                             _col * TILE_W, _row * TILE_H);
        }
    }
}

/// @function tile_get(grid_x, grid_y)
/// @description Get the tile ID at a grid position
/// @param {real} grid_x Grid column (0-19)
/// @param {real} grid_y Grid row (0-11)
/// @returns {real} Tile ID or -1 if out of bounds
function tile_get(grid_x, grid_y) {
    if (global.tile_grid == undefined) return -1;
    if (grid_x < 0 || grid_x >= GRID_COLS) return -1;
    if (grid_y < 0 || grid_y >= GRID_ROWS) return -1;
    return global.tile_grid[grid_y][grid_x];
}

/// @function tile_is_solid(tile_id)
/// @description Check if a tile is solid (blocks walking)
function tile_is_solid(tile_id) {
    return (tile_id >= TILE_SOLID && tile_id < TILE_FLY);
}

/// @function tile_is_fly_only(tile_id)
/// @description Check if a tile only blocks ground actors
function tile_is_fly_only(tile_id) {
    return (tile_id >= TILE_FLY && tile_id < TILE_SPECIAL);
}

/// @function tile_is_special(tile_id)
/// @description Check if a tile is a special/trigger tile
function tile_is_special(tile_id) {
    return (tile_id >= TILE_SPECIAL);
}
""")

    # -- scr_collision --
    create_script("scr_collision", scr_engine, """\
/// @description Tile-based collision checks (faithful to original check_move functions)

/// @function check_move_player(px, py, pw, ph, dx, dy)
/// @description Player movement collision check (original check_move0)
/// @param {real} px Player x
/// @param {real} py Player y
/// @param {real} pw Player collision width
/// @param {real} ph Player collision height
/// @param {real} dx Delta x
/// @param {real} dy Delta y
/// @returns {bool} true if movement is allowed
function check_move_player(px, py, pw, ph, dx, dy) {
    var _nx = px + dx;
    var _ny = py + dy;

    // Check screen bounds for room transitions
    // (handled separately by the level controller)
    if (_nx < 0 || _nx + pw > SCREEN_W) return false;
    if (_ny < 0 || _ny + ph > SCREEN_H) return false;

    // Check tile collision at the four corners of the collision box
    // Use a 2px inset like the original (thor_x1=thor->x+2, thor_y1=thor->y+2)
    var _x1 = _nx + 2;
    var _y1 = _ny + 2;
    var _x2 = _nx + pw - 2;
    var _y2 = _ny + ph - 2;

    // Check all tiles the player would overlap
    var _gx1 = _x1 div TILE_W;
    var _gy1 = _y1 div TILE_H;
    var _gx2 = _x2 div TILE_W;
    var _gy2 = _y2 div TILE_H;

    for (var _gy = _gy1; _gy <= _gy2; _gy++) {
        for (var _gx = _gx1; _gx <= _gx2; _gx++) {
            var _tid = tile_get(_gx, _gy);
            if (_tid < 0) return false;
            if (tile_is_solid(_tid)) return false;
            if (tile_is_fly_only(_tid)) return false; // player can't fly
        }
    }

    return true;
}

/// @function check_move_hammer(hx, hy, dx, dy)
/// @description Hammer movement collision check (original check_move1)
/// @returns {real} 0=ok, 1=wall, 2=enemy_hit
function check_move_hammer(hx, hy, dx, dy) {
    var _nx = hx + dx;
    var _ny = hy + dy;

    // Off screen = stop
    if (_nx < 0 || _nx + 16 > SCREEN_W) return 1;
    if (_ny < 0 || _ny + 16 > SCREEN_H) return 1;

    // Check tile
    var _gx = (_nx + 8) div TILE_W;
    var _gy = (_ny + 8) div TILE_H;
    var _tid = tile_get(_gx, _gy);

    if (_tid >= TILE_SOLID && _tid < TILE_FLY) return 1; // hit wall

    return 0;
}

/// @function check_move_enemy(ex, ey, ew, eh, dx, dy, is_flying)
/// @description Enemy movement collision check (original check_move2)
/// @returns {bool} true if movement is allowed
function check_move_enemy(ex, ey, ew, eh, dx, dy, is_flying) {
    var _nx = ex + dx;
    var _ny = ey + dy;

    if (_nx < 0 || _nx + ew > SCREEN_W) return false;
    if (_ny < 0 || _ny + eh > SCREEN_H) return false;

    var _gx1 = _nx div TILE_W;
    var _gy1 = _ny div TILE_H;
    var _gx2 = (_nx + ew - 1) div TILE_W;
    var _gy2 = (_ny + eh - 1) div TILE_H;

    for (var _gy = _gy1; _gy <= _gy2; _gy++) {
        for (var _gx = _gx1; _gx <= _gx2; _gx++) {
            var _tid = tile_get(_gx, _gy);
            if (_tid < 0) return false;
            if (tile_is_solid(_tid)) return false;
            if (!is_flying && tile_is_fly_only(_tid)) return false;
        }
    }

    return true;
}
""")

    # -- scr_actor --
    create_script("scr_actor", scr_actor, """\
/// @description Actor spawning and management

/// @function actor_spawn(actor_type, spawn_x, spawn_y, value, dir)
/// @description Spawn an enemy actor from its type definition
function actor_spawn(actor_type, spawn_x, spawn_y, value, dir) {
    // Load actor definition
    var _def = actor_get_definition(actor_type);
    if (_def == undefined) return noone;

    var _inst = instance_create_layer(spawn_x, spawn_y, "Instances", obj_enemy);

    with (_inst) {
        actor_type_id = actor_type;
        actor_def = _def;

        // Copy stats from definition
        move_pattern = _def.move;
        health = _def.health;
        strength = _def.strength;
        speed = _def.speed;
        num_moves = _def.num_moves;
        solid_type = _def.solid;
        is_flying = (_def.flying > 0);

        // Collision box
        col_w = _def.size_x;
        col_h = _def.size_y;

        // Animation
        directions = _def.directions;
        anim_frames = _def.frames;
        frame_speed = _def.frame_speed;
        frame_sequence = _def.frame_sequence;

        // State
        facing = dir;
        pass_value = value;
        speed_count = 0;
        frame_count = 0;
        current_frame = 0;
        vulnerable_timer = 0;
        is_dead = false;
    }

    return _inst;
}

/// @function actor_get_definition(actor_type)
/// @description Load an actor definition from JSON data
function actor_get_definition(actor_type) {
    // Cache definitions
    if (!variable_global_exists("actor_defs")) {
        global.actor_defs = {};
    }

    var _key = string(actor_type);
    if (struct_exists(global.actor_defs, _key)) {
        return global.actor_defs[$ _key];
    }

    // Load from file
    var _path = "data/actors/actor" + _key + ".json";
    if (!file_exists(_path)) {
        show_debug_message("WARNING: Actor definition not found: " + _path);
        return undefined;
    }

    var _file = file_text_open_read(_path);
    var _str = "";
    while (!file_text_eof(_file)) {
        _str += file_text_readln(_file);
    }
    file_text_close(_file);

    var _data = json_parse(_str);
    var _info = _data.actor_info;

    global.actor_defs[$ _key] = _info;
    return _info;
}

/// @function pickup_spawn(obj_type, px, py)
/// @description Spawn a static object/pickup
function pickup_spawn(obj_type, px, py) {
    var _inst = instance_create_layer(px, py, "Instances", obj_pickup);
    with (_inst) {
        pickup_type = obj_type;
        // Object types: 1-4=jewels, 5=apple, 6=potion, 7=key, etc.
    }
    return _inst;
}
""")

    # -- scr_movement --
    create_script("scr_movement", scr_actor, """\
/// @description Movement pattern functions (from 1_MOVPAT.C)

/// @function movement_execute(inst)
/// @description Execute the movement pattern for an actor
function movement_execute(inst) {
    with (inst) {
        // Speed counter - actors don't move every frame
        speed_count++;
        if (speed_count < speed) return;
        speed_count = 0;

        // Dispatch to movement pattern
        switch (move_pattern) {
            case 0:  move_none(); break;
            case 1:  move_wander(); break;
            case 2:  move_hammer(); break;   // hammer movement
            case 3:  move_toward_player(); break;
            case 4:  move_horizontal(); break;
            case 5:  move_vertical(); break;
            case 6:  move_wander_pause(); break;
            case 7:  move_bounce(); break;
            default: move_wander(); break;
        }
    }
}

/// @function move_none()
/// @description Movement pattern 0: stationary
function move_none() {
    // Do nothing - actor stays in place
}

/// @function move_wander()
/// @description Movement pattern 1: random wandering
function move_wander() {
    for (var _m = 0; _m < num_moves; _m++) {
        // Occasionally change direction
        if (irandom(15) == 0) {
            facing = irandom(3);
        }

        var _dx = 0, _dy = 0;
        switch (facing) {
            case Dir.DOWN:  _dy = 1; break;
            case Dir.UP:    _dy = -1; break;
            case Dir.LEFT:  _dx = -1; break;
            case Dir.RIGHT: _dx = 1; break;
        }

        if (check_move_enemy(x, y, col_w, col_h, _dx, _dy, is_flying)) {
            x += _dx;
            y += _dy;
        } else {
            facing = irandom(3);
        }
    }
}

/// @function move_hammer()
/// @description Movement pattern 2: hammer projectile movement
function move_hammer() {
    // Handled by obj_hammer directly
}

/// @function move_toward_player()
/// @description Movement pattern 3: move toward Thor
function move_toward_player() {
    if (global.player == noone || !instance_exists(global.player)) return;

    for (var _m = 0; _m < num_moves; _m++) {
        var _px = global.player.x;
        var _py = global.player.y;
        var _dx = 0, _dy = 0;

        // Pick axis to close distance on
        if (irandom(1) == 0) {
            // Try horizontal first
            if (_px < x) _dx = -1;
            else if (_px > x) _dx = 1;

            if (_dx != 0 && check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
                x += _dx;
                facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
            } else {
                if (_py < y) _dy = -1;
                else if (_py > y) _dy = 1;
                if (_dy != 0 && check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
                    y += _dy;
                    facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
                }
            }
        } else {
            // Try vertical first
            if (_py < y) _dy = -1;
            else if (_py > y) _dy = 1;

            if (_dy != 0 && check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
                y += _dy;
                facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
            } else {
                if (_px < x) _dx = -1;
                else if (_px > x) _dx = 1;
                if (_dx != 0 && check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
                    x += _dx;
                    facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                }
            }
        }
    }
}

/// @function move_horizontal()
/// @description Movement pattern 4: horizontal patrol
function move_horizontal() {
    for (var _m = 0; _m < num_moves; _m++) {
        var _dx = (facing == Dir.RIGHT) ? 1 : -1;
        if (!check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
            facing = (facing == Dir.RIGHT) ? Dir.LEFT : Dir.RIGHT;
            _dx = -_dx;
        }
        if (check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
            x += _dx;
        }
    }
}

/// @function move_vertical()
/// @description Movement pattern 5: vertical patrol
function move_vertical() {
    for (var _m = 0; _m < num_moves; _m++) {
        var _dy = (facing == Dir.DOWN) ? 1 : -1;
        if (!check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
            facing = (facing == Dir.DOWN) ? Dir.UP : Dir.DOWN;
            _dy = -_dy;
        }
        if (check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
            y += _dy;
        }
    }
}

/// @function move_wander_pause()
/// @description Movement pattern 6: wander with random pauses
function move_wander_pause() {
    if (variable_instance_exists(id, "pause_timer") && pause_timer > 0) {
        pause_timer--;
        return;
    }

    // Occasionally pause
    if (irandom(31) == 0) {
        pause_timer = irandom(60) + 20;
        return;
    }

    move_wander();
}

/// @function move_bounce()
/// @description Movement pattern 7: bouncing movement
function move_bounce() {
    for (var _m = 0; _m < num_moves; _m++) {
        var _dx = 0, _dy = 0;
        switch (facing) {
            case Dir.DOWN:  _dy = 1; break;
            case Dir.UP:    _dy = -1; break;
            case Dir.LEFT:  _dx = -1; break;
            case Dir.RIGHT: _dx = 1; break;
        }

        if (!check_move_enemy(x, y, col_w, col_h, _dx, _dy, is_flying)) {
            // Reverse direction on collision
            switch (facing) {
                case Dir.DOWN:  facing = Dir.UP; break;
                case Dir.UP:    facing = Dir.DOWN; break;
                case Dir.LEFT:  facing = Dir.RIGHT; break;
                case Dir.RIGHT: facing = Dir.LEFT; break;
            }
        } else {
            x += _dx;
            y += _dy;
        }
    }
}
""")

    # -- scr_input --
    create_script("scr_input", scr_engine, """\
/// @description Input handling

/// @function input_check()
/// @description Check and return current input state as a struct
function input_check() {
    var _input = {
        left:  keyboard_check(vk_left)  || keyboard_check(ord("A")),
        right: keyboard_check(vk_right) || keyboard_check(ord("D")),
        up:    keyboard_check(vk_up)    || keyboard_check(ord("W")),
        down:  keyboard_check(vk_down)  || keyboard_check(ord("S")),
        fire:  keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter),
        magic: keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_control),
    };
    return _input;
}
""")

    # -- scr_draw --
    create_script("scr_draw", scr_engine, """\
/// @description Drawing helpers

/// @function draw_actor_sprite(actor_type_id, dir, frame, ax, ay)
/// @description Draw an actor using its spritesheet
/// @param {real} actor_type_id The actor definition number
/// @param {real} dir Direction (0-3)
/// @param {real} frame Animation frame (0-3)
/// @param {real} ax X position
/// @param {real} ay Y position
function draw_actor_sprite(actor_type_id, dir, frame, ax, ay) {
    // For now, use the assigned sprite_index on the instance
    // Later this will handle multi-direction spritesheets
    draw_self();
}

/// @function draw_pickup(pickup_type, px, py)
/// @description Draw a pickup/static object from the objects spritesheet
function draw_pickup(pickup_type, px, py) {
    if (pickup_type <= 0 || pickup_type > 32) return;

    var _idx = pickup_type - 1;
    var _cols = 8; // objects.png is 128px wide / 16px = 8 columns
    var _sx = (_idx mod _cols) * TILE_W;
    var _sy = (_idx div _cols) * TILE_H;

    draw_sprite_part(spr_objects, 0, _sx, _sy, TILE_W, TILE_H, px, py);
}
""")

    # -- scr_combat --
    create_script("scr_combat", scr_combat, """\
/// @description Combat functions

/// @function combat_player_hit(damage)
/// @description Handle player taking damage
function combat_player_hit(damage) {
    if (global.player == noone) return;
    if (global.player.invulnerable_timer > 0) return;

    global.health -= damage;
    if (global.health <= 0) {
        global.health = 0;
        // TODO: death sequence
        show_debug_message("PLAYER DIED");
    }

    global.player.invulnerable_timer = 60; // ~1 second at 60fps
}

/// @function combat_enemy_hit(enemy_inst, damage)
/// @description Handle enemy taking damage from hammer
function combat_enemy_hit(enemy_inst, damage) {
    with (enemy_inst) {
        health -= damage;
        vulnerable_timer = 10; // flash

        if (health <= 0) {
            is_dead = true;
            // Award score based on rating
            if (variable_instance_exists(id, "actor_def") && actor_def != undefined) {
                global.score = min(global.score + actor_def.rating, MAX_SCORE);
            }
            instance_destroy();
        }
    }
}
""")


# ===========================================================================
# Object content
# ===========================================================================
def create_objects(obj_engine, obj_actors, obj_items):
    """Create all GameMaker object resources."""

    # -- obj_game --
    create_object("obj_game", obj_engine, persistent=True, events={
        "Create_0": """\
/// @description Game initialization
game_init();

// Load palette data
var _pal_file = file_text_open_read("data/palette.json");
if (_pal_file != -1) {
    var _str = "";
    while (!file_text_eof(_pal_file)) {
        _str += file_text_readln(_pal_file);
    }
    file_text_close(_pal_file);
    global.palette = json_parse(_str);
}

// Load the starting level
level_load(global.current_level);
""",
        "Step_0": """\
/// @description Main game step
// Room transition checks
if (global.player != noone && instance_exists(global.player)) {
    var _p = global.player;
    var _new_level = -1;

    // Check screen edges for transitions
    if (_p.x <= -2) {
        _new_level = global.current_level - 1;
        if (_new_level >= 0 && (_new_level mod WORLD_COLS) < (global.current_level mod WORLD_COLS)) {
            level_load(_new_level);
            _p.x = SCREEN_W - TILE_W;
        } else {
            _p.x = 0;
        }
    }
    else if (_p.x >= SCREEN_W - 1) {
        _new_level = global.current_level + 1;
        if (_new_level < 120 && (_new_level mod WORLD_COLS) > (global.current_level mod WORLD_COLS)) {
            level_load(_new_level);
            _p.x = 0;
        } else {
            _p.x = SCREEN_W - TILE_W;
        }
    }
    else if (_p.y <= -2) {
        _new_level = global.current_level - WORLD_COLS;
        if (_new_level >= 0) {
            level_load(_new_level);
            _p.y = SCREEN_H - TILE_H;
        } else {
            _p.y = 0;
        }
    }
    else if (_p.y >= SCREEN_H - 1) {
        _new_level = global.current_level + WORLD_COLS;
        if (_new_level < 120) {
            level_load(_new_level);
            _p.y = 0;
        } else {
            _p.y = SCREEN_H - TILE_H;
        }
    }
}
""",
        "Draw_0": """\
/// @description Draw level tiles
level_draw_tiles();
""",
        "Draw_64": """\
/// @description Draw HUD
var _scale = 4; // GUI scale for visibility

draw_set_colour(c_black);
draw_rectangle(0, 0, display_get_gui_width(), 60 * _scale, false);

draw_set_colour(c_white);
draw_set_font(-1);

var _y = 8;
var _lh = 20;
draw_text(8, _y, "HP: " + string(global.health) + "/" + string(MAX_HEALTH));
draw_text(200, _y, "JEWELS: " + string(global.jewels));
_y += _lh;
draw_text(8, _y, "MAGIC: " + string(global.magic));
draw_text(200, _y, "KEYS: " + string(global.keys));
_y += _lh;
draw_text(8, _y, "SCORE: " + string(global.score));
draw_text(200, _y, "LEVEL: " + string(global.current_level));

if (global.debug_mode) {
    _y += _lh;
    if (global.player != noone && instance_exists(global.player)) {
        draw_text(8, _y, "POS: " + string(global.player.x) + "," + string(global.player.y));
        draw_text(200, _y, "DIR: " + string(global.player.facing));
    }
}
""",
    })

    # -- obj_player --
    create_object("obj_player", obj_actors, sprite_name="spr_thor_down", events={
        "Create_0": """\
/// @description Player initialization
global.player = id;

facing = Dir.DOWN;
move_speed = 2;
invulnerable_timer = 0;

// Collision box (original: 13x15 with 2px inset)
col_w = 13;
col_h = 15;

// Sprite arrays for each direction
dir_sprites = [
    spr_thor_down,
    spr_thor_up,
    spr_thor_left,
    spr_thor_right,
];

// Animation
anim_frame = 0;
anim_timer = 0;
anim_speed = 6; // frames between animation updates
is_moving = false;

// Hammer state
hammer_cooldown = 0;
""",
        "Step_0": """\
/// @description Player update
var _input = input_check();

// Process invulnerability
if (invulnerable_timer > 0) {
    invulnerable_timer--;
}

// Process hammer cooldown
if (hammer_cooldown > 0) {
    hammer_cooldown--;
}

// Movement
var _dx = 0;
var _dy = 0;
is_moving = false;

if (_input.left)  { _dx = -move_speed; facing = Dir.LEFT; }
if (_input.right) { _dx =  move_speed; facing = Dir.RIGHT; }
if (_input.up)    { _dy = -move_speed; facing = Dir.UP; }
if (_input.down)  { _dy =  move_speed; facing = Dir.DOWN; }

// Move one axis at a time for slide-along-walls behavior
if (_dx != 0) {
    // Move pixel by pixel for accuracy
    var _sign_x = sign(_dx);
    for (var i = 0; i < abs(_dx); i++) {
        if (check_move_player(x, y, col_w, col_h, _sign_x, 0)) {
            x += _sign_x;
            is_moving = true;
        } else {
            break;
        }
    }
}
if (_dy != 0) {
    var _sign_y = sign(_dy);
    for (var i = 0; i < abs(_dy); i++) {
        if (check_move_player(x, y, col_w, col_h, 0, _sign_y)) {
            y += _sign_y;
            is_moving = true;
        } else {
            break;
        }
    }
}

// Animation
if (is_moving) {
    anim_timer++;
    if (anim_timer >= anim_speed) {
        anim_timer = 0;
        anim_frame = (anim_frame + 1) mod 4;
    }
} else {
    anim_frame = 0;
    anim_timer = 0;
}

sprite_index = dir_sprites[facing];
image_index = anim_frame;
image_speed = 0; // manual animation control

// Throw hammer
if (_input.fire && hammer_cooldown <= 0) {
    if (global.hammer == noone || !instance_exists(global.hammer)) {
        var _h = instance_create_layer(x, y, "Instances", obj_hammer);
        _h.facing = facing;
        global.hammer = _h;
        hammer_cooldown = 10;
    }
}

// Check enemy contact damage
if (invulnerable_timer <= 0) {
    var _enemy = instance_place(x, y, obj_enemy);
    if (_enemy != noone) {
        combat_player_hit(_enemy.strength);
    }
}
""",
        "Draw_0": """\
/// @description Draw player
// Flash when invulnerable
if (invulnerable_timer > 0 && (invulnerable_timer mod 4) < 2) {
    // Skip drawing for flash effect
    return;
}
draw_self();
""",
    })

    # -- obj_hammer --
    create_object("obj_hammer", obj_actors, sprite_name="spr_hammer_down", events={
        "Create_0": """\
/// @description Hammer initialization
facing = Dir.DOWN;
move_speed = 4;
lifetime = 60; // max frames before returning
damage = 10;

// Sprite arrays
dir_sprites = [
    spr_hammer_down,
    spr_hammer_up,
    spr_hammer_left,
    spr_hammer_right,
];

sprite_index = dir_sprites[facing];
image_speed = 1;
""",
        "Step_0": """\
/// @description Hammer update
lifetime--;

// Movement
var _dx = 0, _dy = 0;
switch (facing) {
    case Dir.DOWN:  _dy = move_speed; break;
    case Dir.UP:    _dy = -move_speed; break;
    case Dir.LEFT:  _dx = -move_speed; break;
    case Dir.RIGHT: _dx = move_speed; break;
}

sprite_index = dir_sprites[facing];

// Check tile collision
var _result = check_move_hammer(x, y, _dx, _dy);
if (_result == 1 || lifetime <= 0) {
    // Hit wall or expired - destroy
    global.hammer = noone;
    instance_destroy();
    return;
}

x += _dx;
y += _dy;

// Check enemy collision
var _hit = instance_place(x, y, obj_enemy);
if (_hit != noone) {
    combat_enemy_hit(_hit, damage);
    // Hammer continues through enemies (like original)
}
""",
        "CleanUp_0": """\
/// @description Clean up hammer reference
if (global.hammer == id) {
    global.hammer = noone;
}
""",
    })

    # -- obj_enemy --
    create_object("obj_enemy", obj_actors, sprite_name="spr_enemy_boingy", events={
        "Create_0": """\
/// @description Enemy initialization (set by actor_spawn)
actor_type_id = 0;
actor_def = undefined;

move_pattern = 1;
health = 10;
strength = 1;
speed = 2;
num_moves = 1;
solid_type = 0;
is_flying = false;

col_w = 15;
col_h = 15;

directions = 1;
anim_frames = 4;
frame_speed = 6;
frame_sequence = [0, 1, 2, 3];

facing = Dir.DOWN;
pass_value = 0;
speed_count = 0;
frame_count = 0;
current_frame = 0;
vulnerable_timer = 0;
is_dead = false;
pause_timer = 0;
""",
        "Step_0": """\
/// @description Enemy update
if (is_dead) return;

// Movement
movement_execute(id);

// Animation
frame_count++;
if (frame_count >= frame_speed) {
    frame_count = 0;
    current_frame = (current_frame + 1) mod anim_frames;
    image_index = current_frame;
}

// Vulnerability flash
if (vulnerable_timer > 0) {
    vulnerable_timer--;
}

image_speed = 0;
""",
        "Draw_0": """\
/// @description Draw enemy
if (vulnerable_timer > 0 && (vulnerable_timer mod 2) == 0) {
    draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_red, 1);
} else {
    draw_self();
}
""",
    })

    # -- obj_pickup --
    create_object("obj_pickup", obj_items, events={
        "Create_0": """\
/// @description Pickup initialization
pickup_type = 0;
""",
        "Step_0": """\
/// @description Pickup collision check
if (global.player == noone || !instance_exists(global.player)) return;

var _p = global.player;
// Simple bounding box overlap
if (point_in_rectangle(_p.x + 8, _p.y + 8, x, y, x + 15, y + 15)) {
    // Process pickup
    switch (pickup_type) {
        case 1: case 2: case 3: case 4:
            // Jewels (different values)
            var _values = [0, 1, 5, 10, 25];
            global.jewels = min(global.jewels + _values[pickup_type], MAX_JEWELS);
            global.score = min(global.score + _values[pickup_type], MAX_SCORE);
            break;
        case 5:
            // Apple - restore health
            global.health = min(global.health + 10, MAX_HEALTH);
            break;
        case 6:
            // Potion - restore magic
            global.magic = min(global.magic + 10, MAX_MAGIC);
            break;
        case 7:
            // Key
            global.keys = min(global.keys + 1, MAX_KEYS);
            break;
        default:
            show_debug_message("Picked up object type: " + string(pickup_type));
            break;
    }
    instance_destroy();
}
""",
        "Draw_0": """\
/// @description Draw pickup from spritesheet
draw_pickup(pickup_type, x, y);
""",
    })


# ===========================================================================
# Entry point
# ===========================================================================
if __name__ == "__main__":
    main()
