#!/usr/bin/env python3
"""Extract authoritative God of Thunder assets from GOTRES.DAT.

The archive and image layouts mirror the original DOS resource manager:

* 256 encrypted, packed 23-byte archive headers
* a four-byte header plus backward-offset LZSS for compressed entries
* VGA planar images with four interleaved pixel planes

Pillow is required for PNG output.  The bundled Codex Python runtime includes
it; a normal Python installation can use ``pip install Pillow``.
"""

from __future__ import annotations

import argparse
import json
import struct
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ENTRY_COUNT = 256
ENTRY_SIZE = 23
HEADER_SIZE = ENTRY_COUNT * ENTRY_SIZE
PIC_BLOCK_SIZE = 262
ACTOR_PIXEL_BYTES = 20 * 16 * 16


@dataclass(frozen=True)
class ResourceEntry:
    name: str
    offset: int
    size: int
    original_size: int
    compressed: bool


class GotArchive:
    def __init__(self, path: Path):
        self.path = path
        self.data = path.read_bytes()
        self.entries = self._read_entries()

    def _read_entries(self) -> dict[str, ResourceEntry]:
        if len(self.data) < HEADER_SIZE:
            raise ValueError(f"{self.path} is too small to be a GOT resource archive")

        encrypted = self.data[:HEADER_SIZE]
        header = bytes(value ^ ((128 + index) & 0xFF)
                       for index, value in enumerate(encrypted))

        entries: dict[str, ResourceEntry] = {}
        for index in range(ENTRY_COUNT):
            raw_name, offset, size, original_size, key = struct.unpack_from(
                "<9slllH", header, index * ENTRY_SIZE
            )
            if offset == 0 and size == 0:
                continue
            name = raw_name.split(b"\0", 1)[0].decode("ascii")
            if offset < HEADER_SIZE or offset + size > len(self.data):
                raise ValueError(f"Invalid bounds for resource {name}")
            entries[name] = ResourceEntry(name, offset, size, original_size, key != 0)
        return entries

    def read(self, name: str) -> bytes:
        entry = self.entries[name.upper()]
        payload = self.data[entry.offset:entry.offset + entry.size]
        if not entry.compressed:
            if len(payload) != entry.original_size:
                raise ValueError(f"Unexpected uncompressed size for {entry.name}")
            return payload

        result = decompress_lzss(payload)
        if len(result) != entry.original_size:
            raise ValueError(
                f"Unexpected decompressed size for {entry.name}: "
                f"{len(result)} != {entry.original_size}"
            )
        return result


def decompress_lzss(payload: bytes) -> bytes:
    """Decode the DOS game's backward-offset LZSS stream."""
    if len(payload) < 4:
        raise ValueError("Truncated LZSS stream")

    expected_size, marker = struct.unpack_from("<HH", payload)
    if marker != 1:
        raise ValueError(f"Unexpected LZSS marker {marker}")

    source_index = 4
    output = bytearray()
    while len(output) < expected_size:
        if source_index >= len(payload):
            raise ValueError("Truncated LZSS flag byte")
        flags = payload[source_index]
        source_index += 1

        for _ in range(8):
            if len(output) >= expected_size:
                break
            if flags & 1:
                if source_index >= len(payload):
                    raise ValueError("Truncated LZSS literal")
                output.append(payload[source_index])
                source_index += 1
            else:
                if source_index + 1 >= len(payload):
                    raise ValueError("Truncated LZSS back-reference")
                encoded = struct.unpack_from("<H", payload, source_index)[0]
                source_index += 2
                count = (encoded >> 12) + 2
                offset = encoded & 0xFFF
                if offset == 0 or offset > len(output):
                    raise ValueError(f"Invalid LZSS offset {offset}")
                for _ in range(count):
                    output.append(output[-offset])
                    if len(output) >= expected_size:
                        break
            flags >>= 1

    return bytes(output)


def palette_from_resource(data: bytes) -> list[tuple[int, int, int, int]]:
    if len(data) != 256 * 3:
        raise ValueError("PALETTE must contain 256 VGA RGB triplets")

    palette = []
    for index in range(256):
        red, green, blue = data[index * 3:index * 3 + 3]
        # The main PALETTE resource already stores expanded 8-bit values. The
        # separate STORYPAL resource is six-bit, but is not used for gameplay
        # tiles or actors.
        palette.append((red, green, blue, 255))
    return palette


def indexed_image(width: int, height: int, indices: bytes,
                  palette: list[tuple[int, int, int, int]],
                  transparent: bool = True) -> Image.Image:
    if len(indices) != width * height:
        raise ValueError(f"Expected {width * height} pixels, got {len(indices)}")
    pixels = []
    for value in indices:
        red, green, blue, alpha = palette[value]
        if transparent and value in (0, 15):
            alpha = 0
        pixels.append((red, green, blue, alpha))
    image = Image.new("RGBA", (width, height))
    image.putdata(pixels)
    return image


def deplane(data: bytes, width: int, height: int) -> bytes:
    """Convert four VGA planes into ordinary row-major pixel indices."""
    expected = width * height
    source = data[:expected] + bytes(max(0, expected - len(data)))
    output = bytearray(expected)
    source_index = 0
    for plane in range(4):
        for y in range(height):
            for x in range(width // 4):
                output[y * width + plane + x * 4] = source[source_index]
                source_index += 1
    return bytes(output)


def decode_pic_block(block: bytes,
                     palette: list[tuple[int, int, int, int]]) -> Image.Image:
    if len(block) < 6:
        raise ValueError("Truncated picture block")
    width_in_plane, height, _transparent = struct.unpack_from("<HHH", block)
    width = width_in_plane * 4
    return indexed_image(width, height, deplane(block[6:], width, height), palette)


def save_pic_atlas(data: bytes, output: Path,
                   palette: list[tuple[int, int, int, int]],
                   columns: int) -> None:
    count = len(data) // PIC_BLOCK_SIZE
    rows = (count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * 16, rows * 16))
    for index in range(count):
        start = index * PIC_BLOCK_SIZE
        tile = decode_pic_block(data[start:start + PIC_BLOCK_SIZE], palette)
        atlas.alpha_composite(tile, ((index % columns) * 16, (index // columns) * 16))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)


def save_actor(data: bytes, output: Path,
               palette: list[tuple[int, int, int, int]]) -> None:
    if len(data) != 5200:
        raise ValueError(f"Actor resource must contain 5200 bytes, got {len(data)}")
    atlas = Image.new("RGBA", (10 * 16, 2 * 16))
    for index in range(20):
        start = index * 16 * 16
        frame = indexed_image(16, 16, data[start:start + 256], palette)
        atlas.alpha_composite(frame, ((index % 10) * 16, (index // 10) * 16))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)


def save_single_planar(data: bytes, output: Path,
                       palette: list[tuple[int, int, int, int]]) -> None:
    if len(data) < 6:
        raise ValueError("Truncated planar image")
    width_in_plane, height, _transparent = struct.unpack_from("<HHH", data)
    width = width_in_plane * 4
    image = indexed_image(width, height, deplane(data[6:], width, height), palette)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)


def save_font(data: bytes, output: Path,
              palette: list[tuple[int, int, int, int]]) -> None:
    glyph_count = len(data) // 72
    columns = 16
    rows = (glyph_count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * 8, rows * 9))
    for index in range(glyph_count):
        glyph_data = data[index * 72:(index + 1) * 72]
        glyph_indices = deplane(glyph_data, 8, 9)
        # TEXT is a mask; the DOS renderer supplies the final palette colour.
        glyph = Image.new("RGBA", (8, 9))
        glyph.putdata([
            (255, 255, 255, 255) if value not in (0, 15) else (0, 0, 0, 0)
            for value in glyph_indices
        ])
        atlas.alpha_composite(glyph, ((index % columns) * 8, (index // columns) * 9))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)


def extract_archive(archive_path: Path, output_dir: Path) -> None:
    archive = GotArchive(archive_path)
    palette_data = archive.read("PALETTE")
    palette = palette_from_resource(palette_data)

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "palette.json").write_text(
        json.dumps([
            {"index": index, "r": color[0], "g": color[1], "b": color[2]}
            for index, color in enumerate(palette)
        ], indent=2) + "\n",
        encoding="utf-8",
    )

    for episode in (1, 2, 3):
        save_pic_atlas(
            archive.read(f"BPICS{episode}"),
            output_dir / "tiles" / f"bpics{episode}.png",
            palette,
            columns=16,
        )

    save_pic_atlas(archive.read("OBJECTS"), output_dir / "objects" / "objects.png",
                   palette, columns=8)
    save_single_planar(archive.read("STATUS"), output_dir / "status.png", palette)
    save_font(archive.read("TEXT"), output_dir / "font.png", palette)

    for name, entry in sorted(archive.entries.items()):
        if name.startswith("ACTOR"):
            number = int(name[5:])
            save_actor(archive.read(name), output_dir / "actors" / f"actor{number}.png",
                       palette)

    manifest = [entry.__dict__ for entry in archive.entries.values()]
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="Path to GOTRES.DAT")
    parser.add_argument("output", type=Path, help="Directory for extracted PNG/JSON assets")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    extract_archive(args.archive, args.output)
    print(f"Extracted {args.archive} to {args.output}")


if __name__ == "__main__":
    main()
