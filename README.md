# God of Thunder -- editable GameMaker restoration

Open `gotgm.yyp` in GameMaker and press Run. The project starts at an
original-style opening menu, plays the original Episode 1 story sequence, then
begins Episode 1 on screen 23.

## Editing the game

The original 120 screens for each of the three episodes are ordinary GameMaker
rooms under **Rooms > Episode 1/2/3**. Each room contains:

- **LevelTiles** -- the editable foreground/collision tile layer
- **BackgroundTiles** -- the editable base-colour tile layer
- **Actors** -- placed child objects with the original type, value, direction,
  invisibility group, script identity, and position
- **Pickups** -- placed original item objects
- **Engine** -- the persistent game controller (and Thor in the starting room)

Actor and projectile artwork is under **Sprites > Original Actors/Original
Shots**. Pickup artwork, dialogue portraits, sounds, and the five
palette-correct tile atlases are also ordinary editable GameMaker resources.

Runtime collision reads the room's `LevelTiles` layer, so tile edits affect both
appearance and gameplay. Original quest scripts can permanently change those
tiles during play; those changes are tracked separately from the editor-owned
room layout.

### Editing conversations and quests

The original human-readable scripts are:

- `datafiles/data/dialogue/speak1.got`
- `datafiles/data/dialogue/speak2.got`
- `datafiles/data/dialogue/speak3.got`

They contain the published game's dialogue, choices, flags, inventory handoffs,
sound cues, and scripted tile changes. After editing them, run:

`python tools/compile_dialogue.py`

Then reopen or reload the project in GameMaker so the updated JSON included
files are packaged. This compiler changes only dialogue data and does not touch
your edited rooms.

## Controls

- Arrow keys or WASD: move
- Space: throw the hammer
- Enter, Space, or Z: advance/confirm dialogue and menus
- Z or Ctrl (hold): use the selected inventory item during play
- X or Shift: cycle owned inventory items
- Up/Down: choose a dialogue response or menu item
- Escape: close dialogue or open/close the options menu

## Rebuilding from the published data

`tools/extract_gotres.py` decodes `GOTRES.DAT`.
`tools/generate_editable_resources.py` deterministically rebuilds the 360
rooms, original actor/pickup/shot/story sprites, dialogue sources and portraits,
sound effects, and tile sets.

Running the full generator overwrites generated rooms and original imported
resources, so do not rerun it after making room-editor or dialogue-source
changes unless you first save those changes elsewhere. Use
`tools/compile_dialogue.py` for ordinary conversation edits.
If GameMaker was open while generated image layers were rebuilt, close the project
without saving stale room tabs and reopen it once so the room editor reloads the
repaired layer images from disk.

## Restoration status

Implemented and compiling in GameMaker 2024.14:

- all 360 editable rooms and their original placements
- palette-correct terrain, actors, pickups, shots, Thor, hammer, status panel,
  and 20 animated conversation portraits
- room-edge transitions, collision ranges, doors, gates, holes, teleports, and
  episode-specific special tiles
- returning hammer, combat damage, enemy firing, common original movement
  patterns, pickups, persistent collected items, checkpoint respawn
- original pushable blocks, recharge angels, switches, rolling boulders and
  directional barrels, wall-following spinballs, and multipart troll movement
- all episode-specific dialogue `EXEC` helpers, including mining, arrest
  transfer, randomized charges, and the Episode 1 troll step-aside event
- functional multipart snake, skull, and Loki encounters with persistent defeat state
- six inventory items with original costs/timing (tornado/thunder visuals are
  currently simplified)
- all 16 original digitized sound effects and the original music tracks
- original-style opening/options menus, the original Episode 1 scrolling story,
  music controls, skill setting, help, and JSON save/load
- the original framed dialogue presentation, palette text colours, Odin portrait, and input separation
- all three original conversation/quest banks, including speech pages, choices,
  numeric/string variables, branching, subroutines, loops, flags, quest items,
  stat changes, sound cues, actor reveals, and persistent scripted tile changes

Still incomplete compared with the published DOS game:

- exact boss phase choreography, status presentation, and closing sequences
- exact ending and closing sequences
- dedicated tornado/thunder presentation and a few less-used projectile details
