/// @description Global constants and initialization

#macro TILE_W 16
#macro TILE_H 16
#macro GRID_COLS 20
#macro GRID_ROWS 12
#macro SCREEN_W 320
#macro SCREEN_H 192
#macro FULL_SCREEN_H 240

#macro TILE_SOLID 80
#macro TILE_FLY 140
#macro TILE_SPECIAL 200

enum Dir {
    UP    = 0,
    DOWN  = 1,
    LEFT  = 2,
    RIGHT = 3,
}

#macro MAX_HEALTH 150
#macro MAX_MAGIC  150
#macro MAX_JEWELS 999
#macro MAX_SCORE  999999
#macro MAX_KEYS   99
#macro MAX_ACTORS 16

#macro WORLD_COLS 10
#macro WORLD_ROWS 12

function game_init() {
    global.health = 150;
    global.magic = 0;
    global.jewels = 0;
    global.score = 0;
    global.keys = 0;
    global.difficulty = 1;

    global.current_level = 23;
    global.current_episode = 1;
    global.loaded_episode = -1;
    global.last_room = -1;

    global.level_data = undefined;
    global.tile_grid = undefined;

    global.inventory = {};
    global.collected_pickups = {};
    global.selected_item = 0;
    global.quest_object = 0;
    global.flags = {};
    global.tile_overrides = {};
    dialogue_init();
    music_init();
    menu_init();
    global.player = noone;
    global.hammer = noone;
    global.palette = undefined;
    global.debug_mode = false;
    global.magic_use_timer = 0;
    global.tornado_timer = 0;
    global.thunder_timer = 0;
    global.shield_on = false;
    global.checkpoint = {
        episode: 1, level: 23, x: 128, y: 95, facing: Dir.DOWN,
        health: 150, magic: 0, jewels: 0, keys: 0, score: 0,
        selected_item: 0, quest_object: 0, inventory_json: "{}",
    };

    display_set_gui_size(SCREEN_W, FULL_SCREEN_H);
}
