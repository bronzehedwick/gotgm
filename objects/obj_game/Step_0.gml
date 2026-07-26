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
