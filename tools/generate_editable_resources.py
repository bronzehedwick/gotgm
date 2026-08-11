#!/usr/bin/env python3
"""Generate editable GameMaker resources from God of Thunder's original data.

This deliberately leaves the hand-written runtime resources alone.  It adds:

* one GameMaker room per original screen (360 rooms total)
* separate editable background and foreground tile layers
* placed actor and pickup instances with their original room values
* one child object and correctly coloured sprite for every actor/pickup type
* palette-correct tilesets for every palette variant used by the levels

The generated resources are deterministic, so rerunning this tool produces a
reviewable project rather than a new collection of random GameMaker GUIDs.
"""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
import uuid
import wave
from pathlib import Path

from PIL import Image

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(SCRIPT_DIR))

from extract_gotres import (  # noqa: E402
    ACTOR_PIXEL_BYTES,
    PIC_BLOCK_SIZE,
    GotArchive,
    decode_pic_block,
    indexed_image,
    deplane,
    palette_from_resource,
)


NAMESPACE = uuid.UUID("6c5ab297-c32d-47e6-9636-b19a510dad10")
GENERATED_PREFIXES = (
    "obj_actor_",
    "obj_pickup_",
    "spr_actor_",
    "spr_shot_",
    "spr_pickup_",
    "spr_face_",
    "spr_dialogue_odin",
    "spr_story_",
    "snd_got_",
    "spr_tiles_ep",
    "ts_ep",
    "rm_ep",
)


def guid(label: str) -> str:
    return str(uuid.uuid5(NAMESPACE, label))


def load_gm_json(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig")
    text = re.sub(r",(?=\s*[}\]])", "", text)
    return json.loads(text)


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def slug(value: str) -> str:
    result = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    return result or "unnamed"


def folder_ref(name: str, path: str) -> dict:
    return {"name": name, "path": path}


def resource_ref(name: str, kind: str) -> dict:
    return {"name": name, "path": f"{kind}/{name}/{name}.yy"}


def frame_image_resource(name: str, images: list[Image.Image], parent: dict,
                         playback_speed: float = 8.0) -> None:
    sprite_dir = PROJECT_DIR / "sprites" / name
    sprite_dir.mkdir(parents=True, exist_ok=True)
    layer_id = guid(f"{name}:layer")
    frame_ids = [guid(f"{name}:frame:{index}") for index in range(len(images))]
    width, height = images[0].size

    for frame_id, image in zip(frame_ids, images):
        image.save(sprite_dir / f"{frame_id}.png")
        layer_dir = sprite_dir / "layers" / frame_id
        layer_dir.mkdir(parents=True, exist_ok=True)
        image.save(layer_dir / f"{layer_id}.png")

    frames = [
        {
            "$GMSpriteFrame": "v1",
            "%Name": frame_id,
            "name": frame_id,
            "resourceType": "GMSpriteFrame",
            "resourceVersion": "2.0",
        }
        for frame_id in frame_ids
    ]
    keyframes = []
    for index, frame_id in enumerate(frame_ids):
        keyframes.append({
            "$Keyframe<SpriteFrameKeyframe>": "",
            "Channels": {
                "0": {
                    "$SpriteFrameKeyframe": "",
                    "Id": {"name": frame_id, "path": f"sprites/{name}/{name}.yy"},
                    "resourceType": "SpriteFrameKeyframe",
                    "resourceVersion": "2.0",
                }
            },
            "Disabled": False,
            "id": guid(f"{name}:keyframe:{index}"),
            "IsCreationKey": False,
            "Key": float(index),
            "Length": 1.0,
            "resourceType": "Keyframe<SpriteFrameKeyframe>",
            "resourceVersion": "2.0",
            "Stretch": False,
        })

    sprite = {
        "$GMSprite": "v2",
        "%Name": name,
        "bboxMode": 0,
        "bbox_bottom": height - 1,
        "bbox_left": 0,
        "bbox_right": width - 1,
        "bbox_top": 0,
        "collisionKind": 1,
        "collisionTolerance": 0,
        "DynamicTexturePage": False,
        "edgeFiltering": False,
        "For3D": False,
        "frames": frames,
        "gridX": 0,
        "gridY": 0,
        "height": height,
        "HTile": False,
        "layers": [{
            "$GMImageLayer": "",
            "%Name": layer_id,
            "blendMode": 0,
            "displayName": "default",
            "isLocked": False,
            "name": layer_id,
            "opacity": 100.0,
            "resourceType": "GMImageLayer",
            "resourceVersion": "2.0",
            "visible": True,
        }],
        "name": name,
        "nineSlice": None,
        "origin": 0,
        "parent": parent,
        "preMultiplyAlpha": False,
        "resourceType": "GMSprite",
        "resourceVersion": "2.0",
        "sequence": {
            "$GMSequence": "v1",
            "%Name": name,
            "autoRecord": True,
            "backdropHeight": 768,
            "backdropImageOpacity": 0.5,
            "backdropImagePath": "",
            "backdropWidth": 1366,
            "backdropXOffset": 0.0,
            "backdropYOffset": 0.0,
            "events": {
                "$KeyframeStore<MessageEventKeyframe>": "",
                "Keyframes": [],
                "resourceType": "KeyframeStore<MessageEventKeyframe>",
                "resourceVersion": "2.0",
            },
            "eventStubScript": None,
            "eventToFunction": {},
            "length": float(len(images)),
            "lockOrigin": False,
            "moments": {
                "$KeyframeStore<MomentsEventKeyframe>": "",
                "Keyframes": [],
                "resourceType": "KeyframeStore<MomentsEventKeyframe>",
                "resourceVersion": "2.0",
            },
            "name": name,
            "playback": 1,
            "playbackSpeed": playback_speed,
            "playbackSpeedType": 0,
            "resourceType": "GMSequence",
            "resourceVersion": "2.0",
            "showBackdrop": True,
            "showBackdropImage": False,
            "timeUnits": 1,
            "tracks": [{
                "$GMSpriteFramesTrack": "",
                "builtinName": 0,
                "events": [],
                "inheritsTrackColour": True,
                "interpolation": 1,
                "isCreationTrack": False,
                "keyframes": {
                    "$KeyframeStore<SpriteFrameKeyframe>": "",
                    "Keyframes": keyframes,
                    "resourceType": "KeyframeStore<SpriteFrameKeyframe>",
                    "resourceVersion": "2.0",
                },
                "modifiers": [],
                "name": "frames",
                "resourceType": "GMSpriteFramesTrack",
                "resourceVersion": "2.0",
                "spriteId": None,
                "trackColour": 0,
                "tracks": [],
                "traits": 0,
            }],
            "visibleRange": None,
            "volume": 1.0,
            "xorigin": 0,
            "yorigin": 0,
        },
        "swatchColours": None,
        "swfPrecision": 0.5,
        "textureGroupId": {"name": "Default", "path": "texturegroups/Default"},
        "type": 0,
        "VTile": False,
        "width": width,
    }
    write_json(sprite_dir / f"{name}.yy", sprite)


def create_child_object(name: str, sprite_name: str, parent_name: str,
                        parent_folder: dict, create_code: str) -> None:
    object_dir = PROJECT_DIR / "objects" / name
    obj = {
        "$GMObject": "",
        "%Name": name,
        "eventList": [{
            "$GMEvent": "v1",
            "%Name": "",
            "collisionObjectId": None,
            "eventNum": 0,
            "eventType": 0,
            "isDnD": False,
            "name": "",
            "resourceType": "GMEvent",
            "resourceVersion": "2.0",
        }],
        "managed": True,
        "name": name,
        "overriddenProperties": [],
        "parent": parent_folder,
        "parentObjectId": resource_ref(parent_name, "objects"),
        "persistent": False,
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
        "resourceType": "GMObject",
        "resourceVersion": "2.0",
        "solid": False,
        "spriteId": resource_ref(sprite_name, "sprites"),
        "spriteMaskId": None,
        "visible": True,
    }
    write_json(object_dir / f"{name}.yy", obj)
    (object_dir / "Create_0.gml").write_text(create_code, encoding="utf-8")


def palette_variant(base: list[tuple[int, int, int, int]], overrides: tuple[int, int, int]) -> list[tuple[int, int, int, int]]:
    result = list(base)
    for destination, source in zip((251, 253, 254), overrides):
        result[destination] = base[source]
    return result


def create_tileset(archive: GotArchive, base_palette: list[tuple[int, int, int, int]],
                   episode: int, overrides: tuple[int, int, int]) -> tuple[str, str]:
    suffix = "_".join(str(value) for value in overrides)
    sprite_name = f"spr_tiles_ep{episode}_{suffix}"
    tileset_name = f"ts_ep{episode}_{suffix}"
    palette = palette_variant(base_palette, overrides)
    data = archive.read(f"BPICS{episode}")

    # Tile zero is reserved as empty by GameMaker.  Original tile N therefore
    # occupies GameMaker tile N+1.  The 16x15 atlas has room for all 230 tiles.
    atlas = Image.new("RGBA", (256, 240))
    for index in range(len(data) // PIC_BLOCK_SIZE):
        tile = decode_pic_block(data[index * PIC_BLOCK_SIZE:(index + 1) * PIC_BLOCK_SIZE], palette)
        slot = index + 1
        atlas.alpha_composite(tile, ((slot % 16) * 16, (slot // 16) * 16))

    frame_image_resource(
        sprite_name,
        [atlas],
        folder_ref("Original Tiles", "folders/Sprites/Original Tiles.yy"),
        playback_speed=0.0,
    )
    tileset = {
        "$GMTileSet": "v1",
        "%Name": tileset_name,
        "autoTileSets": [],
        "macroPageTiles": {"SerialiseHeight": 0, "SerialiseWidth": 0, "TileSerialiseData": []},
        "name": tileset_name,
        "out_columns": 16,
        "out_tilehborder": 2,
        "out_tilevborder": 2,
        "parent": folder_ref("Original Tile Sets", "folders/Tile Sets/Original Tile Sets.yy"),
        "resourceType": "GMTileSet",
        "resourceVersion": "2.0",
        "spriteId": resource_ref(sprite_name, "sprites"),
        "spriteNoExport": False,
        "textureGroupId": {"name": "Default", "path": "texturegroups/Default"},
        "tileAnimationFrames": [],
        "tileAnimationSpeed": 15.0,
        "tileHeight": 16,
        "tilehsep": 0,
        "tilevsep": 0,
        "tileWidth": 16,
        "tilexoff": 0,
        "tileyoff": 0,
        "tile_count": 240,
    }
    write_json(PROJECT_DIR / "tilesets" / tileset_name / f"{tileset_name}.yy", tileset)
    return sprite_name, tileset_name

SOUND_NAMES = (
    "ow", "gulp", "swish", "yah", "electric", "thunder", "door", "fall",
    "angel", "woop", "dead", "braapp", "wind", "punch", "clang", "explode",
)


def create_sound_resources(archive: GotArchive) -> list[str]:
    """Convert the 16 archived Creative VOC effects to editable PCM WAV sounds."""
    bank = archive.read("DIGSOUND")
    header_size = 16 * 8
    resources: list[str] = []

    for index, label in enumerate(SOUND_NAMES):
        offset, length = struct.unpack_from("<ll", bank, index * 8)
        voc = bank[header_size + offset:header_size + offset + length]
        if not voc.startswith(b"Creative Voice File\x1a"):
            raise ValueError(f"DIGSOUND entry {index} is not a Creative VOC file")

        block_offset = struct.unpack_from("<H", voc, 20)[0]
        if voc[block_offset] != 1:
            raise ValueError(f"Unsupported first VOC block {voc[block_offset]} in sound {index}")
        block_length = int.from_bytes(voc[block_offset + 1:block_offset + 4], "little")
        block = voc[block_offset + 4:block_offset + 4 + block_length]
        time_constant, codec = block[0], block[1]
        if codec != 0:
            raise ValueError(f"Unsupported VOC codec {codec} in sound {index}")

        samples = block[2:]
        sample_rate = round(1_000_000 / (256 - time_constant))
        sound_name = f"snd_got_{label}"
        sound_dir = PROJECT_DIR / "sounds" / sound_name
        sound_dir.mkdir(parents=True, exist_ok=True)
        wav_path = sound_dir / f"{sound_name}.wav"
        with wave.open(str(wav_path), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(1)
            output.setframerate(sample_rate)
            output.writeframes(samples)

        sound = {
            "$GMSound": "v2",
            "%Name": sound_name,
            "audioGroupId": {
                "name": "audiogroup_default",
                "path": "audiogroups/audiogroup_default",
            },
            "bitDepth": 1,
            "channelFormat": 0,
            "compression": 0,
            "compressionQuality": 4,
            "conversionMode": 0,
            "duration": len(samples) / sample_rate,
            "exportDir": "",
            "name": sound_name,
            "parent": folder_ref("Original Sounds", "folders/Sounds/Original Sounds.yy"),
            "preload": False,
            "resourceType": "GMSound",
            "resourceVersion": "2.0",
            "sampleRate": sample_rate,
            "soundFile": f"{sound_name}.wav",
            "volume": 1.0,
        }
        write_json(sound_dir / f"{sound_name}.yy", sound)
        resources.append(sound_name)

    return resources


def _compile_dialogue(raw_text: str) -> dict[str, list[str]]:
    """Turn the original editable script source into a lookup table by entry."""
    entries: dict[str, list[str]] = {}
    current: str | None = None
    for source_line in raw_text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        stripped = source_line.strip()
        if re.fullmatch(r"\|\d+", stripped):
            current = stripped[1:]
            entries[current] = []
        elif stripped.upper() == "|STOP":
            current = None
        elif current is not None:
            entries[current].append(source_line.rstrip())
    return entries


def create_dialogue_resources(
    archive: GotArchive,
    palette: list[tuple[int, int, int, int]],
) -> list[str]:
    """Preserve the original scripts and restore their animated portraits."""
    dialogue_dir = PROJECT_DIR / "datafiles" / "data" / "dialogue"
    dialogue_dir.mkdir(parents=True, exist_ok=True)

    for episode in (1, 2, 3):
        source = archive.read(f"SPEAK{episode}").decode("cp437")
        (dialogue_dir / f"speak{episode}.got").write_text(source, encoding="utf-8")
        write_json(dialogue_dir / f"dialogue{episode}.json", _compile_dialogue(source))

    resources: list[str] = []
    portrait_parent = folder_ref(
        "Dialogue Portraits", "folders/Sprites/Dialogue Portraits.yy"
    )
    for number in range(1, 21):
        data = archive.read(f"FACE{number}")
        frames = [
            decode_pic_block(data[offset:offset + PIC_BLOCK_SIZE], palette)
            for offset in range(0, len(data), PIC_BLOCK_SIZE)
            if len(data[offset:offset + PIC_BLOCK_SIZE]) == PIC_BLOCK_SIZE
        ]
        name = f"spr_face_{number:02d}"
        frame_image_resource(name, frames, portrait_parent, playback_speed=7.0)
        resources.append(name)

    odin = archive.read("ODINPIC")
    odin_frames = [
        decode_pic_block(odin[offset:offset + PIC_BLOCK_SIZE], palette)
        for offset in range(0, len(odin), PIC_BLOCK_SIZE)
        if len(odin[offset:offset + PIC_BLOCK_SIZE]) == PIC_BLOCK_SIZE
    ]
    frame_image_resource(
        "spr_dialogue_odin", odin_frames, portrait_parent, playback_speed=7.0
    )
    resources.append("spr_dialogue_odin")
    return resources

def _story_palette(data: bytes) -> list[tuple[int, int, int, int]]:
    """Expand the story's six-bit VGA palette to ordinary RGBA."""
    if len(data) != 256 * 3:
        raise ValueError("STORYPAL must contain 256 VGA RGB triplets")
    return [
        tuple(round(component * 255 / 63) for component in data[index:index + 3]) + (255,)
        for index in range(0, len(data), 3)
    ]


def _story_planar_image(
    data: bytes,
    palette: list[tuple[int, int, int, int]],
    transparent: bool,
) -> Image.Image:
    width_in_plane, height, _transparent_index = struct.unpack_from("<HHH", data)
    width = width_in_plane * 4
    return indexed_image(
        width, height, deplane(data[6:], width, height), palette, transparent
    )


def _create_story_resource(archive: GotArchive, episode: int) -> list[str]:
    """Rebuild one exact two-page episode opening used by story()."""
    palette = _story_palette(archive.read("STORYPAL"))
    canvas = Image.new("RGBA", (320, 480), palette[0])

    for index in range(12):
        strip = _story_planar_image(
            archive.read(f"OPENP{index + 1}"), palette, transparent=False
        )
        canvas.alpha_composite(strip, (0, index * 40))

    pictures = archive.read("STORYPIC")
    picture_frames = [
        decode_pic_block(
            pictures[offset:offset + PIC_BLOCK_SIZE],
            palette,
        )
        for offset in range(0, len(pictures), PIC_BLOCK_SIZE)
    ]
    canvas.alpha_composite(picture_frames[0], (146, 64))
    canvas.alpha_composite(picture_frames[1], (24, 328))

    font = archive.read("TEXT")
    glyph_masks: list[Image.Image] = []
    for offset in range(0, len(font), 72):
        pixels = deplane(font[offset:offset + 72], 8, 9)
        mask = Image.new("L", (8, 9))
        mask.putdata([255 if value not in (0, 15) else 0 for value in pixels])
        glyph_masks.append(mask)

    def draw_glyph(character: int, x: int, y: int, colour: int) -> None:
        glyph_index = character - 32
        if glyph_index < 0 or glyph_index >= len(glyph_masks):
            return
        mask = glyph_masks[glyph_index]
        fill = Image.new("RGBA", (8, 9), palette[colour])
        canvas.paste(fill, (x, y), mask)

    story = archive.read(f"STORY{episode}")
    pointer = 0
    line = 0
    x = 8
    y = 2
    colour = 72
    while pointer < len(story) and line < 46:
        character = story[pointer]
        if character == 13:
            x = 8
            line += 1
            y = 2 + line * 10
        elif (
            character == ord("/")
            and pointer + 4 < len(story)
            and story[pointer + 4] == ord("/")
        ):
            colour = int(story[pointer + 1:pointer + 4].decode("ascii"))
            pointer += 4
        elif character != 10:
            for shadow_x, shadow_y in (
                (-1, -1), (1, 1), (-1, 1), (1, -1),
                (0, -1), (0, 1), (-1, 0), (1, 0),
            ):
                draw_glyph(character, x + shadow_x, y + shadow_y, 255)
            draw_glyph(character, x, y, colour)
            x += 8
        pointer += 1

    name = f"spr_story_ep{episode}"
    frame_image_resource(
        name,
        [canvas],
        folder_ref("UI", "folders/Sprites/UI.yy"),
        playback_speed=0.0,
    )
    return [name]


def create_story_resources(archive: GotArchive) -> list[str]:
    """Rebuild the exact two-page openings for all three episodes."""
    resources: list[str] = []
    for episode in (1, 2, 3):
        resources.extend(_create_story_resource(archive, episode))
    return resources


def create_actor_resources(archive: GotArchive,
                           palette: list[tuple[int, int, int, int]]) -> tuple[dict[int, str], list[str]]:
    object_names: dict[int, str] = {}
    resources: list[str] = []
    actor_folder = PROJECT_DIR / "datafiles" / "data" / "actors"
    for path in sorted(actor_folder.glob("actor*.json"), key=lambda item: int(item.stem[5:])):
        definition = json.loads(path.read_text(encoding="utf-8"))
        number = int(definition["actor_number"])
        info = definition["actor_info"]
        label = slug(info.get("name", ""))
        sprite_name = f"spr_actor_{number:03d}_{label}"
        object_name = f"obj_actor_{number:03d}_{label}"
        raw = archive.read(f"ACTOR{number}")
        sequence = info.get("frame_sequence", [0])
        frame_count = max(
            1,
            int(info.get("directions", 0)) * int(info.get("frames", 0)),
            max(sequence, default=0) + 1,
        )
        frame_count = min(16, frame_count)
        frames = [
            indexed_image(16, 16, raw[index * 256:(index + 1) * 256], palette)
            for index in range(frame_count)
        ]
        frame_image_resource(
            sprite_name,
            frames,
            folder_ref("Original Actors", "folders/Sprites/Original Actors.yy"),
            playback_speed=0.0,
        )

        shot_info = definition["shot_info"]
        shot_sprite_name = f"spr_shot_{number:03d}"
        shot_sequence = shot_info.get("frame_sequence", [0])
        shot_frame_count = max(
            1,
            int(shot_info.get("directions", 0)) * int(shot_info.get("frames", 0)),
            max(shot_sequence, default=0) + 1,
        )
        shot_frame_count = min(4, shot_frame_count)
        shot_offset = 16 * 16 * 16
        shot_frames = [
            indexed_image(
                16,
                16,
                raw[shot_offset + index * 256:shot_offset + (index + 1) * 256],
                palette,
            )
            for index in range(shot_frame_count)
        ]
        frame_image_resource(
            shot_sprite_name,
            shot_frames,
            folder_ref("Original Shots", "folders/Sprites/Original Shots.yy"),
            playback_speed=0.0,
        )
        create_child_object(
            object_name,
            sprite_name,
            "obj_enemy",
            folder_ref("Original Actors", "folders/Objects/Actors/Original Actors.yy"),
            f"event_inherited();\nactor_configure(id, {number}, 0, Dir.DOWN, false);\n",
        )
        object_names[number] = object_name
        resources.extend((sprite_name, shot_sprite_name, object_name))
    return object_names, resources


def create_pickup_resources(archive: GotArchive,
                            palette: list[tuple[int, int, int, int]]) -> tuple[dict[int, str], list[str]]:
    data = archive.read("OBJECTS")
    object_names: dict[int, str] = {}
    resources: list[str] = []
    for number in range(1, len(data) // PIC_BLOCK_SIZE + 1):
        sprite_name = f"spr_pickup_{number:02d}"
        object_name = f"obj_pickup_{number:02d}"
        image = decode_pic_block(data[(number - 1) * PIC_BLOCK_SIZE:number * PIC_BLOCK_SIZE], palette)
        frame_image_resource(
            sprite_name,
            [image],
            folder_ref("Original Pickups", "folders/Sprites/Original Pickups.yy"),
            playback_speed=0.0,
        )
        create_child_object(
            object_name,
            sprite_name,
            "obj_pickup",
            folder_ref("Original Pickups", "folders/Objects/Items/Original Pickups.yy"),
            f"event_inherited();\npickup_type = {number};\nimage_speed = 0;\n",
        )
        object_names[number] = object_name
        resources.extend((sprite_name, object_name))
    return object_names, resources


def layer_base(name: str, depth: int, layer_type: str) -> dict:
    return {
        f"${layer_type}": "",
        "%Name": name,
        "depth": depth,
        "effectEnabled": True,
        "effectType": None,
        "gridX": 16,
        "gridY": 16,
        "hierarchyFrozen": False,
        "inheritLayerDepth": False,
        "inheritLayerSettings": False,
        "inheritSubLayers": False,
        "inheritVisibility": False,
        "layers": [],
        "name": name,
        "properties": [],
        "resourceType": layer_type,
        "resourceVersion": "2.0",
        "userdefinedDepth": False,
        "visible": True,
    }


def tile_layer(name: str, depth: int, tileset_name: str, tiles: list[int]) -> dict:
    layer = layer_base(name, depth, "GMRTileLayer")
    layer.update({
        "tilesetId": resource_ref(tileset_name, "tilesets"),
        "x": 0,
        "y": 0,
        "tiles": {
            "SerialiseWidth": 20,
            "SerialiseHeight": 12,
            "TileSerialiseData": tiles,
        },
    })
    return layer


def room_instance(instance_name: str, object_name: str, x: int, y: int,
                  creation_code: bool = False) -> dict:
    return {
        "$GMRInstance": "v4",
        "%Name": instance_name,
        "colour": 4294967295,
        "frozen": False,
        "hasCreationCode": creation_code,
        "ignore": False,
        "imageIndex": 0,
        "imageSpeed": 0.0,
        "inheritCode": False,
        "inheritedItemId": None,
        "inheritItemSettings": False,
        "isDnd": False,
        "name": instance_name,
        "objectId": resource_ref(object_name, "objects"),
        "properties": [],
        "resourceType": "GMRInstance",
        "resourceVersion": "2.0",
        "rotation": 0.0,
        "scaleX": 1.0,
        "scaleY": 1.0,
        "x": x,
        "y": y,
    }


def instance_layer(name: str, depth: int, instances: list[dict]) -> dict:
    layer = layer_base(name, depth, "GMRInstanceLayer")
    layer["instances"] = instances
    return layer


def background_layer() -> dict:
    layer = layer_base("Canvas", 400, "GMRBackgroundLayer")
    layer.update({
        "animationFPS": 15.0,
        "animationSpeedType": 0,
        "colour": 4278190080,
        "hspeed": 0.0,
        "htiled": False,
        "spriteId": None,
        "stretch": False,
        "userdefinedAnimFPS": False,
        "vspeed": 0.0,
        "vtiled": False,
        "x": 0,
        "y": 0,
    })
    return layer


def room_view(visible: bool) -> dict:
    return {
        "hborder": 32,
        "hport": 960,
        "hspeed": -1,
        "hview": 240,
        "inherit": False,
        "objectId": None,
        "vborder": 32,
        "visible": visible,
        "vspeed": -1,
        "wport": 1280,
        "wview": 320,
        "xport": 0,
        "xview": 0,
        "yport": 0,
        "yview": 0,
    }


def create_room(episode: int, level: dict, tileset_name: str,
                actor_objects: dict[int, str], pickup_objects: dict[int, str]) -> str:
    level_index = int(level["level_index"])
    room_name = f"rm_ep{episode}_{level_index:03d}"
    room_dir = PROJECT_DIR / "rooms" / room_name
    actor_instances: list[dict] = []
    pickup_instances: list[dict] = []
    engine_instances: list[dict] = []
    creation_order: list[dict] = []

    def register(instance: dict) -> None:
        creation_order.append({"name": instance["name"], "path": f"rooms/{room_name}/{room_name}.yy"})

    if episode == 1 and level_index == 23:
        controller = room_instance("inst_game_controller", "obj_game", 0, 0)
        player = room_instance("inst_thor", "obj_player", 152, 96)
        engine_instances.extend((controller, player))
        register(controller)
        register(player)

    actors = level["actors"]
    for index, actor_type in enumerate(actors["type"]):
        actor_type = int(actor_type)
        if actor_type == 0:
            continue
        if actor_type not in actor_objects:
            raise ValueError(f"Room {room_name} references missing actor {actor_type}")
        location = int(actors["location"][index])
        instance_name = f"inst_ep{episode}_{level_index:03d}_actor_{index:02d}"
        instance = room_instance(
            instance_name,
            actor_objects[actor_type],
            (location % 20) * 16,
            (location // 20) * 16,
            creation_code=True,
        )
        actor_instances.append(instance)
        register(instance)
        direction = int(actors["direction"][index])
        value = int(actors["value"][index])
        invisible = str(int(actors["invisible"][index]))
        (room_dir / f"InstanceCreationCode_{instance_name}.gml").parent.mkdir(parents=True, exist_ok=True)
        (room_dir / f"InstanceCreationCode_{instance_name}.gml").write_text(
            f"actor_configure(id, {actor_type}, {value}, {direction}, {invisible}, {index + 3});\n",
            encoding="utf-8",
        )

    static_objects = level["static_objects"]
    for index, object_type in enumerate(static_objects["type"]):
        object_type = int(object_type)
        if object_type == 0:
            continue
        if object_type not in pickup_objects:
            raise ValueError(f"Room {room_name} references missing pickup {object_type}")
        instance_name = f"inst_ep{episode}_{level_index:03d}_pickup_{index:02d}"
        instance = room_instance(
            instance_name,
            pickup_objects[object_type],
            int(static_objects["x"][index]) * 16,
            int(static_objects["y"][index]) * 16,
        )
        pickup_instances.append(instance)
        register(instance)

    foreground = [int(value) + 1 for row in level["icon_grid"] for value in row]
    background = [int(level["bg_color"]) + 1] * 240
    room = {
        "$GMRoom": "v1",
        "%Name": room_name,
        "creationCodeFile": "",
        "inheritCode": False,
        "inheritCreationOrder": False,
        "inheritLayers": False,
        "instanceCreationOrder": creation_order,
        "isDnd": False,
        "layers": [
            instance_layer("Engine", -100, engine_instances),
            instance_layer("Actors", 0, actor_instances),
            instance_layer("Pickups", 50, pickup_instances),
            tile_layer("LevelTiles", 100, tileset_name, foreground),
            tile_layer("BackgroundTiles", 200, tileset_name, background),
            background_layer(),
        ],
        "name": room_name,
        "parent": folder_ref(f"Episode {episode}", f"folders/Rooms/Episode {episode}.yy"),
        "parentRoom": None,
        "physicsSettings": {
            "inheritPhysicsSettings": False,
            "PhysicsWorld": False,
            "PhysicsWorldGravityX": 0.0,
            "PhysicsWorldGravityY": 10.0,
            "PhysicsWorldPixToMetres": 0.1,
        },
        "resourceType": "GMRoom",
        "resourceVersion": "2.0",
        "roomSettings": {
            "Height": 240,
            "inheritRoomSettings": False,
            "persistent": False,
            "Width": 320,
        },
        "sequenceId": None,
        "views": [room_view(index == 0) for index in range(8)],
        "viewSettings": {
            "clearDisplayBuffer": True,
            "clearViewBackground": True,
            "enableViews": True,
            "inheritViewSettings": False,
        },
        "volume": 1.0,
    }
    write_json(room_dir / f"{room_name}.yy", room)
    return room_name


def add_folder(project: dict, name: str, path: str) -> None:
    if not any(item.get("folderPath") == path for item in project["Folders"]):
        project["Folders"].append({
            "$GMFolder": "",
            "%Name": name,
            "folderPath": path,
            "name": name,
            "resourceType": "GMFolder",
            "resourceVersion": "2.0",
        })


def resource_entry(name: str) -> dict:
    if name.startswith("obj_"):
        path = f"objects/{name}/{name}.yy"
    elif name.startswith("spr_"):
        path = f"sprites/{name}/{name}.yy"
    elif name.startswith("ts_"):
        path = f"tilesets/{name}/{name}.yy"
    elif name.startswith("snd_"):
        path = f"sounds/{name}/{name}.yy"
    elif name.startswith("rm_"):
        path = f"rooms/{name}/{name}.yy"
    else:
        raise ValueError(name)
    return {"id": {"name": name, "path": path}}


def update_project(project: dict, generated_names: list[str], room_names: list[str]) -> None:
    project["resources"] = [
        item for item in project["resources"]
        if not item["id"]["name"].startswith(GENERATED_PREFIXES)
    ]
    project["resources"].extend(resource_entry(name) for name in generated_names)

    dialogue_names = {
        f"speak{episode}.got" for episode in (1, 2, 3)
    } | {
        f"dialogue{episode}.json" for episode in (1, 2, 3)
    }
    project["IncludedFiles"] = [
        item for item in project["IncludedFiles"]
        if not (
            item.get("filePath") == "datafiles/data/dialogue"
            and item.get("name") in dialogue_names
        )
    ]
    for name in sorted(dialogue_names):
        project["IncludedFiles"].append({
            "$GMIncludedFile": "",
            "%Name": name,
            "CopyToMask": -1,
            "filePath": "datafiles/data/dialogue",
            "name": name,
            "resourceType": "GMIncludedFile",
            "resourceVersion": "2.0",
        })
    start_room = "rm_ep1_023"
    ordered_rooms = [start_room] + [name for name in room_names if name != start_room]
    project["RoomOrderNodes"] = [
        {"roomId": resource_ref(name, "rooms")}
        for name in ordered_rooms
    ]

    for name, path in (
        ("Original Actors", "folders/Objects/Actors/Original Actors.yy"),
        ("Original Pickups", "folders/Objects/Items/Original Pickups.yy"),
        ("Original Actors", "folders/Sprites/Original Actors.yy"),
        ("Original Shots", "folders/Sprites/Original Shots.yy"),
        ("Original Pickups", "folders/Sprites/Original Pickups.yy"),
        ("Original Sounds", "folders/Sounds/Original Sounds.yy"),
        ("Dialogue Portraits", "folders/Sprites/Dialogue Portraits.yy"),
        ("Original Tiles", "folders/Sprites/Original Tiles.yy"),
        ("Tile Sets", "folders/Tile Sets.yy"),
        ("Original Tile Sets", "folders/Tile Sets/Original Tile Sets.yy"),
        ("Episode 1", "folders/Rooms/Episode 1.yy"),
        ("Episode 2", "folders/Rooms/Episode 2.yy"),
        ("Episode 3", "folders/Rooms/Episode 3.yy"),
    ):
        add_folder(project, name, path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--archive",
        type=Path,
        default=Path(r"C:\Program Files\God of THunder\GOTRES.DAT"),
        help="Published GOTRES.DAT used to reconstruct the original artwork",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    archive = GotArchive(args.archive)
    palette = palette_from_resource(archive.read("PALETTE"))
    project = load_gm_json(PROJECT_DIR / "gotgm.yyp")

    levels_by_episode = {
        episode: json.loads((PROJECT_DIR / "datafiles" / "data" / f"sdat{episode}.json").read_text(encoding="utf-8"))
        for episode in (1, 2, 3)
    }
    variants = {
        (episode, tuple(int(value) for value in level["palette_overrides"]))
        for episode, levels in levels_by_episode.items()
        for level in levels
    }

    tilesets: dict[tuple[int, tuple[int, int, int]], str] = {}
    generated_names: list[str] = []
    for episode, overrides in sorted(variants):
        sprite_name, tileset_name = create_tileset(archive, palette, episode, overrides)
        tilesets[(episode, overrides)] = tileset_name
        generated_names.extend((sprite_name, tileset_name))

    sound_resources = create_sound_resources(archive)

    demo_path = PROJECT_DIR / "datafiles" / "data" / "demo.got"
    demo_path.write_bytes(archive.read("DEMO"))
    generated_names.extend(sound_resources)

    story_resources = create_story_resources(archive)
    generated_names.extend(story_resources)

    dialogue_resources = create_dialogue_resources(archive, palette)
    generated_names.extend(dialogue_resources)

    actor_objects, actor_resources = create_actor_resources(archive, palette)
    pickup_objects, pickup_resources = create_pickup_resources(archive, palette)
    generated_names.extend(actor_resources)
    generated_names.extend(pickup_resources)

    room_names: list[str] = []
    for episode, levels in levels_by_episode.items():
        for level in levels:
            overrides = tuple(int(value) for value in level["palette_overrides"])
            room_names.append(create_room(
                episode,
                level,
                tilesets[(episode, overrides)],
                actor_objects,
                pickup_objects,
            ))
    generated_names.extend(room_names)

    update_project(project, generated_names, room_names)
    write_json(PROJECT_DIR / "gotgm.yyp", project)
    print(
        f"Generated {len(room_names)} editable rooms, {len(actor_objects)} actor objects, "
        f"{len(pickup_objects)} pickup objects, and {len(tilesets)} palette-correct tilesets."
    )


if __name__ == "__main__":
    main()
