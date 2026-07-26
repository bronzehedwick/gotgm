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
