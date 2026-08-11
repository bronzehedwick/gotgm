/// @description Main game step
menu_update();
if (global.menu.active) exit;
dialogue_update();
if (global.last_room != room) {
    level_enter_current_room();
    if (global.player != noone && instance_exists(global.player)) checkpoint_save();
}

if (global.player == noone || !instance_exists(global.player)) {
    global.player = instance_find(obj_player, 0);
}

if (global.player != noone && instance_exists(global.player)) {
    var _p = global.player;
    var _new_level = -1;
    var _target = -1;

    // These are the exact edge thresholds used by check_move0 in MOVPAT.C.
    if (_p.x < 0) {
        if (global.current_level > 0) {
            _new_level = global.current_level - 1;
            _target = level_room_asset(global.current_episode, _new_level);
            if (_target != -1) {
                _p.x = 304;
                room_goto(_target);
            }
        } else {
            _p.x = 0;
        }
    }
    else if (_p.x > 306) {
        if (global.current_level < 119) {
            _new_level = global.current_level + 1;
            _target = level_room_asset(global.current_episode, _new_level);
            if (_target != -1) {
                _p.x = 0;
                room_goto(_target);
            }
        } else {
            _p.x = 306;
        }
    }
    else if (_p.y < 0) {
        if (global.current_level > 9) {
            _new_level = global.current_level - WORLD_COLS;
            _target = level_room_asset(global.current_episode, _new_level);
            if (_target != -1) {
                _p.y = 175;
                room_goto(_target);
            }
        } else {
            _p.y = 0;
        }
    }
    else if (_p.y > 175) {
        if (global.current_level < 110) {
            _new_level = global.current_level + WORLD_COLS;
            _target = level_room_asset(global.current_episode, _new_level);
            if (_target != -1) {
                _p.y = 0;
                room_goto(_target);
            }
        } else {
            _p.y = 175;
        }
    }
}
