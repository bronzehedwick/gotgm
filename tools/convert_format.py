#!/usr/bin/env python3
"""
Convert generated GameMaker .yy/.yyp files to 2024.x format.

In GM 2024.x, every typed JSON object needs:
  - "$TypeName": "version" as the FIRST field
  - "%Name": "name" as the SECOND field
  - Old fields (resourceType, resourceVersion, name) are KEPT too

The version strings vary by type:
  GMProject -> "v1", GMSprite -> "v2", GMObject -> "",
  GMSpriteFrame -> "v1", GMSequence -> "v1", etc.
"""

import json
import sys
from pathlib import Path
from collections import OrderedDict

PROJECT_DIR = Path(__file__).resolve().parent.parent

# Version strings for each type tag
TYPE_VERSIONS = {
    "GMProject": "v1",
    "GMSprite": "v2",
    "GMObject": "",
    "GMScript": "",
    "GMRoom": "v1",
    "GMFolder": "",
    "GMAudioGroup": "v1",
    "GMTextureGroup": "",
    "GMSpriteFrame": "v1",
    "GMImageLayer": "",
    "GMSpriteImage": "",
    "GMSequence": "v1",
    "GMSpriteFramesTrack": "",
    "GMEvent": "",
    "GMRInstance": "v4",
    "GMRInstanceLayer": "",
    "GMRBackgroundLayer": "",
    "GMRAssetLayer": "",
    "KeyframeStore<MessageEventKeyframe>": "",
    "KeyframeStore<MomentsEventKeyframe>": "",
    "KeyframeStore<SpriteFrameKeyframe>": "",
    "Keyframe<SpriteFrameKeyframe>": "",
    "SpriteFrameKeyframe": "",
}

# Types that have a "name" field that should also get "%Name"
NAMED_TYPES = set(TYPE_VERSIONS.keys())


def convert_value(v):
    """Recursively convert any value."""
    if isinstance(v, dict):
        return convert_dict(v)
    if isinstance(v, list):
        return [convert_value(item) for item in v]
    return v


def convert_dict(d):
    """Convert a dict to GM 2024.x format with type tags."""
    resource_type = d.get("resourceType")

    result = OrderedDict()

    # If this dict has a resourceType, add type tag as first field
    if resource_type and resource_type in TYPE_VERSIONS:
        version = TYPE_VERSIONS[resource_type]
        result[f"${resource_type}"] = version

        # Add %Name if there's a name field
        if "name" in d:
            result["%Name"] = d["name"]

    # Copy all fields in original order, converting nested values
    for key, value in d.items():
        result[key] = convert_value(value)

    return result


def simplify_sprite_frames(d):
    """
    Simplify sprite frame entries to match GM 2024.x format.
    GM 2024.x doesn't use compositeImage/images arrays in frame entries.
    """
    if not isinstance(d, dict):
        return d

    resource_type = d.get("resourceType")

    if resource_type == "GMSpriteFrame":
        # Simplify: only keep name, resourceType, resourceVersion
        simple = OrderedDict()
        if f"$GMSpriteFrame" in d:
            simple["$GMSpriteFrame"] = d["$GMSpriteFrame"]
        if "%Name" in d:
            simple["%Name"] = d["%Name"]
        simple["name"] = d.get("name", d.get("%Name", ""))
        simple["resourceType"] = "GMSpriteFrame"
        simple["resourceVersion"] = "2.0"
        return simple

    # Recurse into all values
    result = OrderedDict()
    for key, value in d.items():
        if isinstance(value, dict):
            result[key] = simplify_sprite_frames(value)
        elif isinstance(value, list):
            result[key] = [simplify_sprite_frames(item) if isinstance(item, (dict, list)) else item for item in value]
        else:
            result[key] = value

    return result


def process_file(filepath):
    """Process a single .yy or .yyp file."""
    with open(filepath, 'r') as f:
        data = json.load(f)

    converted = convert_dict(data)

    # Simplify sprite frames
    if data.get("resourceType") == "GMSprite":
        converted = simplify_sprite_frames(converted)

    # Write with trailing commas (GameMaker format)
    output = json_dumps_gm(converted)

    with open(filepath, 'w') as f:
        f.write(output)


def json_dumps_gm(obj, indent=2, _depth=0):
    """
    Serialize to GameMaker-style JSON (with trailing commas).
    """
    prefix = " " * indent * _depth
    inner = " " * indent * (_depth + 1)

    if obj is None:
        return "null"
    if isinstance(obj, bool):
        return "true" if obj else "false"
    if isinstance(obj, int):
        return str(obj)
    if isinstance(obj, float):
        # GM uses compact floats
        if obj == int(obj) and abs(obj) < 1e15:
            return f"{obj:.1f}"
        return str(obj)
    if isinstance(obj, str):
        return json.dumps(obj)

    if isinstance(obj, list):
        if not obj:
            return "[]"
        items = []
        for item in obj:
            items.append(inner + json_dumps_gm(item, indent, _depth + 1) + ",")
        return "[\n" + "\n".join(items) + "\n" + prefix + "]"

    if isinstance(obj, (dict, OrderedDict)):
        if not obj:
            return "{}"
        items = []
        for key, value in obj.items():
            val_str = json_dumps_gm(value, indent, _depth + 1)
            items.append(f"{inner}{json.dumps(key)}:{val_str},")
        return "{\n" + "\n".join(items) + "\n" + prefix + "}"

    return str(obj)


def main():
    count = 0

    # Process .yyp
    for f in sorted(PROJECT_DIR.glob("*.yyp")):
        print(f"  Converting: {f.name}")
        process_file(f)
        count += 1

    # Process all .yy files
    for f in sorted(PROJECT_DIR.rglob("*.yy")):
        print(f"  Converting: {f.relative_to(PROJECT_DIR)}")
        process_file(f)
        count += 1

    print(f"\nConverted {count} files to GameMaker 2024.x format.")


if __name__ == "__main__":
    main()
