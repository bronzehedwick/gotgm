/// @description Level loading and management

/// @function level_load(level_index)
/// @description Load a level from the episode data
/// @param {real} level_index The level index (0-119)
function level_load(level_index) {
    // Load episode data if not already loaded
    if (global.level_data == undefined) {
        var _path = "data/sdat" + string(global.current_episode) + ".json";
        show_debug_message("Loading level data from: " + _path);

        var _buf = buffer_load(_path);
        if (_buf == -1) {
            show_debug_message("ERROR: Could not load level data: " + _path);
            return;
        }
        var _str = buffer_read(_buf, buffer_string);
        buffer_delete(_buf);
        global.level_data = json_parse(_str);
        show_debug_message("Loaded " + string(array_length(global.level_data)) + " levels");
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
