#!/usr/bin/env python3
"""Compile editable God of Thunder .got dialogue sources to runtime JSON."""

from __future__ import annotations
import json
import re
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
DIALOGUE_DIR = PROJECT_DIR / "datafiles" / "data" / "dialogue"


def compile_source(text: str) -> dict[str, list[str]]:
    entries: dict[str, list[str]] = {}
    current: str | None = None
    for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        stripped = line.strip()
        if re.fullmatch(r"\|\d+", stripped):
            current = stripped[1:]
            entries[current] = []
        elif stripped.upper() == "|STOP":
            current = None
        elif current is not None:
            entries[current].append(line.rstrip())
    return entries


def main() -> None:
    for episode in (1, 2, 3):
        source = DIALOGUE_DIR / f"speak{episode}.got"
        output = DIALOGUE_DIR / f"dialogue{episode}.json"
        output.write_text(
            json.dumps(compile_source(source.read_text(encoding="utf-8")), indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Compiled {source.name} -> {output.name}")


if __name__ == "__main__":
    main()
