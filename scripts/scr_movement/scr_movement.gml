/// @description Movement pattern functions (from 1_MOVPAT.C)

/// @function movement_execute(inst)
/// @description Execute the movement pattern for an actor
function movement_execute(inst) {
    with (inst) {
        // Speed counter - actors don't move every frame
        speed_count++;
        if (speed_count < speed) return;
        speed_count = 0;

        // Dispatch to movement pattern
        switch (move_pattern) {
            case 0:  move_none(); break;
            case 1:  move_wander(); break;
            case 2:  move_hammer(); break;   // hammer movement
            case 3:  move_toward_player(); break;
            case 4:  move_horizontal(); break;
            case 5:  move_vertical(); break;
            case 6:  move_wander_pause(); break;
            case 7:  move_bounce(); break;
            default: move_wander(); break;
        }
    }
}

/// @function move_none()
/// @description Movement pattern 0: stationary
function move_none() {
    // Do nothing - actor stays in place
}

/// @function move_wander()
/// @description Movement pattern 1: random wandering
function move_wander() {
    for (var _m = 0; _m < num_moves; _m++) {
        // Occasionally change direction
        if (irandom(15) == 0) {
            facing = irandom(3);
        }

        var _dx = 0, _dy = 0;
        switch (facing) {
            case Dir.DOWN:  _dy = 1; break;
            case Dir.UP:    _dy = -1; break;
            case Dir.LEFT:  _dx = -1; break;
            case Dir.RIGHT: _dx = 1; break;
        }

        if (check_move_enemy(x, y, col_w, col_h, _dx, _dy, is_flying)) {
            x += _dx;
            y += _dy;
        } else {
            facing = irandom(3);
        }
    }
}

/// @function move_hammer()
/// @description Movement pattern 2: hammer projectile movement
function move_hammer() {
    // Handled by obj_hammer directly
}

/// @function move_toward_player()
/// @description Movement pattern 3: move toward Thor
function move_toward_player() {
    if (global.player == noone || !instance_exists(global.player)) return;

    for (var _m = 0; _m < num_moves; _m++) {
        var _px = global.player.x;
        var _py = global.player.y;
        var _dx = 0, _dy = 0;

        // Pick axis to close distance on
        if (irandom(1) == 0) {
            // Try horizontal first
            if (_px < x) _dx = -1;
            else if (_px > x) _dx = 1;

            if (_dx != 0 && check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
                x += _dx;
                facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
            } else {
                if (_py < y) _dy = -1;
                else if (_py > y) _dy = 1;
                if (_dy != 0 && check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
                    y += _dy;
                    facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
                }
            }
        } else {
            // Try vertical first
            if (_py < y) _dy = -1;
            else if (_py > y) _dy = 1;

            if (_dy != 0 && check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
                y += _dy;
                facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
            } else {
                if (_px < x) _dx = -1;
                else if (_px > x) _dx = 1;
                if (_dx != 0 && check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
                    x += _dx;
                    facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                }
            }
        }
    }
}

/// @function move_horizontal()
/// @description Movement pattern 4: horizontal patrol
function move_horizontal() {
    for (var _m = 0; _m < num_moves; _m++) {
        var _dx = (facing == Dir.RIGHT) ? 1 : -1;
        if (!check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
            facing = (facing == Dir.RIGHT) ? Dir.LEFT : Dir.RIGHT;
            _dx = -_dx;
        }
        if (check_move_enemy(x, y, col_w, col_h, _dx, 0, is_flying)) {
            x += _dx;
        }
    }
}

/// @function move_vertical()
/// @description Movement pattern 5: vertical patrol
function move_vertical() {
    for (var _m = 0; _m < num_moves; _m++) {
        var _dy = (facing == Dir.DOWN) ? 1 : -1;
        if (!check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
            facing = (facing == Dir.DOWN) ? Dir.UP : Dir.DOWN;
            _dy = -_dy;
        }
        if (check_move_enemy(x, y, col_w, col_h, 0, _dy, is_flying)) {
            y += _dy;
        }
    }
}

/// @function move_wander_pause()
/// @description Movement pattern 6: wander with random pauses
function move_wander_pause() {
    if (variable_instance_exists(id, "pause_timer") && pause_timer > 0) {
        pause_timer--;
        return;
    }

    // Occasionally pause
    if (irandom(31) == 0) {
        pause_timer = irandom(60) + 20;
        return;
    }

    move_wander();
}

/// @function move_bounce()
/// @description Movement pattern 7: bouncing movement
function move_bounce() {
    for (var _m = 0; _m < num_moves; _m++) {
        var _dx = 0, _dy = 0;
        switch (facing) {
            case Dir.DOWN:  _dy = 1; break;
            case Dir.UP:    _dy = -1; break;
            case Dir.LEFT:  _dx = -1; break;
            case Dir.RIGHT: _dx = 1; break;
        }

        if (!check_move_enemy(x, y, col_w, col_h, _dx, _dy, is_flying)) {
            // Reverse direction on collision
            switch (facing) {
                case Dir.DOWN:  facing = Dir.UP; break;
                case Dir.UP:    facing = Dir.DOWN; break;
                case Dir.LEFT:  facing = Dir.RIGHT; break;
                case Dir.RIGHT: facing = Dir.LEFT; break;
            }
        } else {
            x += _dx;
            y += _dy;
        }
    }
}
