/// @description Enemy projectile definitions, firing patterns, and movement

function shot_get_definition(shot_type) {
    if (!variable_global_exists("shot_defs")) global.shot_defs = {};
    var _key = string(shot_type);
    if (struct_exists(global.shot_defs, _key)) return global.shot_defs[$ _key];

    var _path = "data/actors/actor" + _key + ".json";
    var _buf = buffer_load(_path);
    if (_buf == -1) return undefined;
    var _text = buffer_read(_buf, buffer_string);
    buffer_delete(_buf);
    var _json = json_parse(_text);
    global.shot_defs[$ _key] = _json.shot_info;
    return _json.shot_info;
}

function shot_sprite_name(shot_type) {
    if (shot_type < 10) return "spr_shot_00" + string(shot_type);
    if (shot_type < 100) return "spr_shot_0" + string(shot_type);
    return "spr_shot_" + string(shot_type);
}

function enemy_shot_count(shooter_id) {
    var _count = 0;
    with (obj_enemy_shot) if (creator_id == shooter_id) _count++;
    return _count;
}

function enemy_shot_line_clear(shooter, dir, flying) {
    if (global.player == noone || !instance_exists(global.player)) return false;
    var _sx = (shooter.x + shooter.col_w * 0.5) div TILE_W;
    var _sy = (shooter.y + shooter.col_h * 0.5) div TILE_H;
    var _px = (global.player.x + global.player.col_w * 0.5) div TILE_W;
    var _py = (global.player.y + global.player.col_h * 0.5) div TILE_H;
    var _limit = flying ? TILE_SOLID : TILE_FLY;

    if (dir < Dir.LEFT) {
        var _from = min(_sy, _py) + 1;
        var _to = max(_sy, _py) - 1;
        for (var _y = _from; _y <= _to; _y++) {
            var _tile = tile_get(_sx, _y);
            if (_tile >= 0 && _tile < _limit) return false;
        }
    } else {
        var _from = min(_sx, _px) + 1;
        var _to = max(_sx, _px) - 1;
        for (var _x = _from; _x <= _to; _x++) {
            var _tile = tile_get(_x, _sy);
            if (_tile >= 0 && _tile < _limit) return false;
        }
    }
    return true;
}

function enemy_spawn_shot(shooter, dir, ignore_walls) {
    if (!instance_exists(shooter)) return noone;
    var _type = shooter.shot_type;
    if (_type <= 0 || _type >= 100) return noone;
    if (enemy_shot_count(shooter.id) >= shooter.shots_allowed) return noone;

    var _def = shot_get_definition(_type);
    if (_def == undefined) return noone;
    if (!ignore_walls && !enemy_shot_line_clear(shooter, dir, _def.flying > 0)) return noone;

    var _shot = instance_create_layer(shooter.x, shooter.y, "Actors", obj_enemy_shot);
    with (_shot) {
        creator_id = shooter.id;
        shot_type = _type;
        shot_def = _def;
        shot_move = _def.move;
        shot_speed = max(1, _def.speed);
        shot_num_moves = max(1, _def.num_moves);
        shot_flying = (_def.flying > 0);
        shot_strength = _def.strength;
        shot_w = max(1, _def.size_x);
        shot_h = max(1, _def.size_y);
        shot_directions = max(1, _def.directions);
        shot_frames = max(1, _def.frames);
        shot_frame_speed = max(1, _def.frame_speed);
        shot_sequence = _def.frame_sequence;
        facing = dir;
        speed_count = 0;
        frame_count = 0;
        current_frame = 0;
        sprite_index = asset_get_index(shot_sprite_name(_type));
        image_speed = 0;
        x = shooter.x + (shooter.col_w - shot_w) * 0.5;
        y = shooter.y + (shooter.col_h - shot_h) * 0.5;
        angle_target_x = global.player.x;
        angle_target_y = global.player.y;
        life_timer = 180;
    }
    shooter.shot_cooldown = 20;
    return _shot;
}

function enemy_fire_pattern(shooter) {
    if (!instance_exists(shooter) || shooter.shots_allowed <= 0 || shooter.shot_type >= 100) return;
    if (global.player == noone || !instance_exists(global.player)) return;
    if (shooter.shot_cooldown > 0) {
        shooter.shot_cooldown--;
        return;
    }

    var _dx = global.player.x - shooter.x;
    var _dy = global.player.y - shooter.y;
    var _dir = shooter.facing;
    var _fire = false;
    var _ignore = false;

    switch (shooter.shot_pattern) {
        case 1:
            if (_dir == Dir.UP && abs(_dx) < 8 && _dy < 0) _fire = true;
            else if (_dir == Dir.DOWN && abs(_dx) < 8 && _dy > 0) _fire = true;
            else if (_dir == Dir.LEFT && abs(_dy) < 8 && _dx < 0) _fire = true;
            else if (_dir == Dir.RIGHT && abs(_dy) < 8 && _dx > 0) _fire = true;
            break;

        case 2:
        case 4:
            _ignore = (shooter.shot_pattern == 4);
            if (abs(_dx) < 8) {
                _dir = (_dy < 0) ? Dir.UP : Dir.DOWN;
                _fire = (_dy != 0);
            } else if (abs(_dy) < 8) {
                _dir = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                _fire = (_dx != 0);
            }
            break;

        case 3:
            if (abs(_dx) < 8) {
                _dir = (_dy < 0) ? Dir.UP : Dir.DOWN;
                _fire = (_dy != 0);
            } else if (abs(_dy) < 8) {
                _dir = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                _fire = (_dx != 0);
            }
            break;

        case 6:
            if (abs(_dx) < 16 && abs(_dy) < 24) {
                if (abs(_dx) > abs(_dy)) _dir = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                else _dir = (_dy < 0) ? Dir.UP : Dir.DOWN;
                _fire = true;
            }
            break;

        case 8:
            if (shooter.shot_random_timer > 0) {
                shooter.shot_random_timer--;
            } else if (irandom(99) < 10) {
                _dir = Dir.UP;
                _fire = true;
                shooter.shot_random_timer = max(1, shooter.actor_def.func_pass);
            }
            break;
    }

    if (_fire) enemy_spawn_shot(shooter, _dir, _ignore);
}

function shot_try_move(dx, dy) {
    if (!check_move_enemy(x, y, shot_w, shot_h, dx, dy, shot_flying)) return false;
    x += dx;
    y += dy;
    return true;
}

function shot_move_cardinal() {
    var _dx = 0;
    var _dy = 0;
    switch (facing) {
        case Dir.UP: _dy = -2; break;
        case Dir.DOWN: _dy = 2; break;
        case Dir.LEFT: _dx = -2; break;
        case Dir.RIGHT: _dx = 2; break;
    }
    return shot_try_move(_dx, _dy);
}

function shot_step_motion() {
    switch (shot_move) {
        case 0:
        case 5:
        case 6:
            life_timer--;
            return life_timer > 0;

        case 1:
        case 2:
            return shot_move_cardinal();

        case 3:
            x -= 2;
            life_timer--;
            return life_timer > 0 && x > -shot_w;

        case 4:
            if (global.player == noone || !instance_exists(global.player)) return false;
            var _dx = clamp(global.player.x - x, -2, 2);
            var _dy = clamp(global.player.y - y, -2, 2);
            if (_dx != 0 && _dy != 0 && shot_try_move(_dx, _dy)) return true;
            if (_dx != 0 && shot_try_move(_dx, 0)) return true;
            if (_dy != 0 && shot_try_move(0, _dy)) return true;
            return true;

        case 7:
            y += 2;
            if (y > 124) {
                shot_move = 8;
                velocity_x = (x < 150) ? 0.67 : -0.67;
                velocity_y = -3.2;
            }
            return true;

        case 8:
            x += velocity_x;
            y += velocity_y;
            velocity_y += 0.12;
            if (y > 164) {
                y = 164;
                velocity_y = -abs(velocity_y) * 0.85;
            }
            return x > -shot_w && x < SCREEN_W;

        case 9:
            current_frame++;
            return current_frame < min(3, array_length(shot_sequence));

        case 10:
            y += 2;
            return y <= 160;

        case 11:
            var _dx = angle_target_x - x;
            var _dy = angle_target_y - y;
            var _length = max(1, point_distance(x, y, angle_target_x, angle_target_y));
            velocity_x = 2 * _dx / _length;
            velocity_y = 2 * _dy / _length;
            return shot_try_move(velocity_x, velocity_y);
    }
    return false;
}
