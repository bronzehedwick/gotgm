/// @description Original movement patterns 2 (outbound) and 5 (return)
if (global.menu.active) exit;
if (global.player == noone || !instance_exists(global.player)) {
    global.hammer = noone;
    instance_destroy();
    exit;
}

if (!returning) {
    outbound_timer--;
    var _dx = 0;
    var _dy = 0;
    switch (facing) {
        case Dir.UP:    _dy = -move_speed; break;
        case Dir.DOWN:  _dy =  move_speed; break;
        case Dir.LEFT:  _dx = -move_speed; break;
        case Dir.RIGHT: _dx =  move_speed; break;
    }

    // movement_two reverses to movement_five when the hammer is blocked.
    if (outbound_timer <= 0 || check_move_hammer(x, y, _dx, _dy) == 1) {
        returning = true;
    } else {
        x += _dx;
        y += _dy;
    }
} else {
    var _target_x = global.player.x;
    var _target_y = global.player.y - 6;
    var _dx = clamp(_target_x - x, -move_speed, move_speed);
    var _dy = clamp(_target_y - y, -move_speed, move_speed);

    // The DOS routine tries a diagonal first, then alternates axes when blocked.
    var _moved = false;
    if (_dx != 0 && _dy != 0 && check_move_hammer(x, y, _dx, _dy) == 0) {
        x += _dx;
        y += _dy;
        _moved = true;
    } else {
        return_axis_toggle = !return_axis_toggle;
        if (return_axis_toggle) {
            if (_dx != 0 && check_move_hammer(x, y, _dx, 0) == 0) {
                x += _dx;
                _moved = true;
            }
            if (!_moved && _dy != 0 && check_move_hammer(x, y, 0, _dy) == 0) {
                y += _dy;
                _moved = true;
            }
        } else {
            if (_dy != 0 && check_move_hammer(x, y, 0, _dy) == 0) {
                y += _dy;
                _moved = true;
            }
            if (!_moved && _dx != 0 && check_move_hammer(x, y, _dx, 0) == 0) {
                x += _dx;
                _moved = true;
            }
        }
    }

    if (abs(_target_x - x) <= move_speed && abs(_target_y - y) <= move_speed) {
        global.hammer = noone;
        instance_destroy();
        exit;
    }

    if (abs(_dx) >= abs(_dy)) facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
    else facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
}

sprite_index = dir_sprites[facing];

// check_move1 in the DOS game uses a fixed 10x10 hammer rectangle and checks
// every overlapping actor. A single instance_place could select an adjacent
// invulnerable globe instead of the boingy that was visibly struck.
var _hit_any = false;
var _hx1 = x + 1;
var _hy1 = y + 1;
var _hx2 = x + 10;
var _hy2 = y + 10;
for (var _i = 0; _i < instance_number(obj_enemy); _i++) {
    var _hit = instance_find(obj_enemy, _i);
    if (_hit == noone || !_hit.visible || _hit.is_dead) continue;
    var _ex1 = _hit.x;
    var _ey1 = _hit.y;
    var _ex2 = _hit.x + _hit.col_w - 1;
    var _ey2 = _hit.y + _hit.col_h - 1;
    if (_hx1 <= _ex2 && _hx2 >= _ex1 && _hy1 <= _ey2 && _hy2 >= _ey1) {
        combat_enemy_hit(_hit, damage);
        _hit_any = true;
    }
}
if (_hit_any && !returning) returning = true;
