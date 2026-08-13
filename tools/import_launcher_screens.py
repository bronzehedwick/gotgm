"""Import the preserved DOS launcher title and restore the menu VGA palette.

The public game source covers the episode executables, while these two front-
end paintings live in GOT.EXE. This importer keeps the GameMaker resources
editable and removes the captured menu cursor by applying only the reference
palette to the clean existing menu image.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

from generate_editable_resources import folder_ref, frame_image_resource, load_gm_json


PROJECT = Path(__file__).resolve().parent.parent


def dos_aspect(image: Image.Image) -> Image.Image:
    image = image.convert("RGB").resize((320, 200), Image.Resampling.NEAREST)
    return image.resize((320, 240), Image.Resampling.NEAREST)


def import_title(path: Path) -> None:
    frame_image_resource(
        "spr_game_title",
        [dos_aspect(Image.open(path)).convert("RGBA")],
        folder_ref("UI", "folders/Sprites/UI.yy"),
        playback_speed=0.0,
    )


def restore_menu_palette(reference_path: Path) -> None:
    sprite_dir = PROJECT / "sprites" / "spr_title_menu"
    metadata = load_gm_json(sprite_dir / "spr_title_menu.yy")
    frame_id = metadata["frames"][0]["name"]
    layer_id = metadata["layers"][0]["name"]
    clean = Image.open(sprite_dir / f"{frame_id}.png").convert("RGB")
    reference = dos_aspect(Image.open(reference_path))

    candidates: dict[tuple[int, int, int], Counter] = defaultdict(Counter)
    clean_pixels = list(clean.get_flattened_data())
    reference_pixels = list(reference.get_flattened_data())
    for old, new in zip(clean_pixels, reference_pixels):
        candidates[old][new] += 1
    palette_map = {old: counts.most_common(1)[0][0] for old, counts in candidates.items()}
    restored = Image.new("RGB", clean.size)
    restored.putdata([palette_map[pixel] for pixel in clean_pixels])
    restored = restored.convert("RGBA")
    restored.save(sprite_dir / f"{frame_id}.png")
    restored.save(sprite_dir / "layers" / frame_id / f"{layer_id}.png")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--title", required=True, type=Path)
    parser.add_argument("--menu-reference", required=True, type=Path)
    args = parser.parse_args()
    import_title(args.title)
    restore_menu_palette(args.menu_reference)


if __name__ == "__main__":
    main()
