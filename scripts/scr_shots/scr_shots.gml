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
    // A zero shot_type means the projectile is embedded in the shooter's own
    // ACTOR resource (the underground spider is the first common example).
    if (_type == 0) _type = shooter.actor_type_id;
    if (_type < 0 || _type >= 100) return noone;
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
        motion_delay = 0;
        slow_counter = 0;
        slow_period = 0;
        drop_wait = 0;
        drop_interval = 0;
        drop_decay_counter = 0;
        bounce_y_velocity = 0;
        bounce_y_counter = 0;
        bounce_curve_counter = 0;
        bounce_down = false;
        bounce_x_counter = 0;
        bounce_x_right = false;
        angle_x_step = 0;
        angle_y_step = 0;
        angle_x_distance = 0;
        angle_y_distance = 0;
        angle_major_y = false;
        angle_counter = 0;
        angle_initialized = false;
        path_toggle = false;
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
    var _reverse_after_fire = false;

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
            // Try the actor''s facing direction first. A successful forward
            // shot turns the actor around; otherwise it may fire backward
            // while retaining its original facing.
            if ((_dir == Dir.UP && abs(_dx) < 8 && _dy < 0)
            || (_dir == Dir.DOWN && abs(_dx) < 8 && _dy > 0)
            || (_dir == Dir.LEFT && abs(_dy) < 8 && _dx < 0)
            || (_dir == Dir.RIGHT && abs(_dy) < 8 && _dx > 0)) {
                _fire = true;
                _reverse_after_fire = true;
            } else {
                _dir = (_dir == Dir.UP) ? Dir.DOWN
                    : ((_dir == Dir.DOWN) ? Dir.UP
                    : ((_dir == Dir.LEFT) ? Dir.RIGHT : Dir.LEFT));
                if ((_dir == Dir.UP && abs(_dx) < 8 && _dy < 0)
                || (_dir == Dir.DOWN && abs(_dx) < 8 && _dy > 0)
                || (_dir == Dir.LEFT && abs(_dy) < 8 && _dx < 0)
                || (_dir == Dir.RIGHT && abs(_dy) < 8 && _dx > 0))
                    _fire = true;
            }
            break;

        case 5: // serpent boss: random leftward breath between lunges
            if (shooter.boss_state == 0 && irandom(99) < 15) {
                shooter.shots_allowed = 3 + global.difficulty;
                var _snake_shot = enemy_spawn_shot(shooter, Dir.LEFT, false);
                if (_snake_shot != noone) {
                    _snake_shot.x = shooter.x;
                    _snake_shot.y = shooter.y + 16;
                    _snake_shot.life_timer = 120;
                    _snake_shot.slow_period = irandom_range(5, 21);
                    _snake_shot.slow_counter = _snake_shot.slow_period;
                    audio_play_sound(snd_got_braapp, 2, false);
                    shooter.shot_cooldown = 50;
                }
            }
            return;

        case 6:
            var _shooter_pos = (shooter.x div TILE_W)
                + (shooter.y div TILE_H) * GRID_COLS;
            var _player_pos = (global.player.x div TILE_W)
                + (global.player.y div TILE_H) * GRID_COLS;
            if (_player_pos == _shooter_pos - GRID_COLS) { _dir = Dir.UP; _fire = true; }
            else if (_player_pos == _shooter_pos + GRID_COLS) { _dir = Dir.DOWN; _fire = true; }
            else if (_player_pos == _shooter_pos - 1) { _dir = Dir.LEFT; _fire = true; }
            else if (_player_pos == _shooter_pos + 1) { _dir = Dir.RIGHT; _fire = true; }
            if (_fire) shooter.current_frame = min(3, array_length(shooter.frame_sequence) - 1);
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

    if (_fire) {
        var _spawned = enemy_spawn_shot(shooter, _dir, _ignore);
        if (_spawned != noone && _reverse_after_fire) {
            shooter.facing = (shooter.facing == Dir.UP) ? Dir.DOWN
                : ((shooter.facing == Dir.DOWN) ? Dir.UP
                : ((shooter.facing == Dir.LEFT) ? Dir.RIGHT : Dir.LEFT));
        }
    }
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

function shot_calculate_angle(target_x, target_y) {
    angle_x_step = sign(target_x - x) * 2;
    angle_y_step = sign(target_y - y) * 2;
    angle_x_distance = abs(target_x - x);
    angle_y_distance = abs(target_y - y);
    angle_major_y = (angle_y_distance >= angle_x_distance);
    angle_counter = 0;
    angle_initialized = true;
}

function shot_move_angle_step() {
    var _next_x = x;
    var _next_y = y;
    if (angle_major_y) {
        _next_y += angle_y_step;
        angle_counter += angle_x_distance;
        if (angle_y_distance > 0 && angle_counter >= angle_y_distance) {
            _next_x += angle_x_step;
            angle_counter -= angle_y_distance;
        }
    } else {
        _next_x += angle_x_step;
        angle_counter += angle_y_distance;
        if (angle_x_distance > 0 && angle_counter >= angle_x_distance) {
            _next_y += angle_y_step;
            angle_counter -= angle_x_distance;
        }
    }
    return [_next_x, _next_y];
}

function shot_try_move_wraith(dx, dy) {
    var _next_x = x + dx;
    var _next_y = y + dy;
    // Episodes 2 and 3 replaced check_move3 with check_movewb: the projectile
    // only observes the inset screen bounds and passes through room terrain.
    if (global.current_episode >= 2) {
        if (_next_x < 16 || _next_x > 287 || _next_y < 1 || _next_y > 159)
            return false;
        x = _next_x;
        y = _next_y;
        return true;
    }
    return shot_try_move(dx, dy);
}

function shot_drop_reward(ordinary_type, apple_threshold) {
    var _gx = (x + shot_w * 0.5) div TILE_W;
    var _gy = (y + shot_h * 0.5) div TILE_H;
    global.projectile_drop_counter++;
    var _drop_type = ordinary_type;
    if (global.projectile_drop_counter >= apple_threshold) {
        _drop_type = 5;
    }
    var _can_drop = _gx >= 0 && _gx < GRID_COLS && _gy >= 0 && _gy < GRID_ROWS
        && tile_get(_gx, _gy) >= TILE_FLY;
    if (_can_drop) {
        for (var _pickup_i = 0; _pickup_i < instance_number(obj_pickup); _pickup_i++) {
            var _pickup = instance_find(obj_pickup, _pickup_i);
            if (_pickup != noone && round(_pickup.x) == _gx * TILE_W
            && round(_pickup.y) == _gy * TILE_H) {
                _can_drop = false;
                break;
            }
        }
    }
    if (!_can_drop) {
        if (_drop_type == 5) global.projectile_drop_counter = apple_threshold - 1;
        return false;
    }
    pickup_spawn(_drop_type, _gx * TILE_W, _gy * TILE_H);
    if (_drop_type == 5) global.projectile_drop_counter = 0;
    return true;
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
            slow_counter--;
            if (slow_counter <= 0) {
                slow_counter = max(1, slow_period);
                shot_speed++;
                if (shot_speed > 6) shot_move = 0;
            }
            return life_timer > 0;

        case 4:
            if (motion_delay > 0) {
                motion_delay--;
                return true;
            }
            life_timer--;
            if (life_timer <= 0) {
                shot_drop_reward(3, 4);
                return false;
            }
            if (global.player == noone || !instance_exists(global.player)) return false;
            var _dx = 0;
            var _dy = 0;
            if (x > global.player.x + 1) _dx = -2;
            else if (x < global.player.x - 1) _dx = 2;
            var _target_y = (shot_type == 1) ? global.player.y + 2 : global.player.y;
            if (y < _target_y - 1) _dy = 2;
            else if (y > _target_y + 1) _dy = -2;
            if (_dx != 0 && _dy != 0 && shot_try_move_wraith(_dx, _dy)) {
                facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                return true;
            }
            path_toggle = !path_toggle;
            if (path_toggle) {
                if (_dx != 0 && shot_try_move_wraith(_dx, 0)) {
                    facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                    return true;
                }
                if (_dy != 0 && shot_try_move_wraith(0, _dy)) {
                    facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
                    return true;
                }
            } else {
                if (_dy != 0 && shot_try_move_wraith(0, _dy)) {
                    facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
                    return true;
                }
                if (_dx != 0 && shot_try_move_wraith(_dx, 0)) {
                    facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
                    return true;
                }
            }
            return true;

        case 7:
            if (drop_wait > 0) {
                drop_wait--;
                return true;
            }
            drop_decay_counter++;
            if (drop_decay_counter > 2) {
                drop_decay_counter = 0;
                drop_interval = max(0, drop_interval - 1);
            }
            drop_wait = drop_interval;
            y += 2;
            var _drop_floor = (global.current_episode == 2) ? 160 : 124;
            if (y > _drop_floor) {
                x += 4 - irandom(8);
                shot_move = 8;
                bounce_y_velocity = 100;
                bounce_y_counter = 0;
                bounce_curve_counter = 50;
                bounce_down = false;
                bounce_x_counter = 3;
                bounce_x_right = (x < 150);
            }
            return true;

        case 8:
            bounce_x_counter--;
            if (bounce_x_counter <= 0) {
                bounce_x_counter = 3;
                x += bounce_x_right ? 2 : -2;
            }
            bounce_y_counter += bounce_y_velocity;
            if (bounce_y_counter > 99) {
                if (!bounce_down) {
                    bounce_y_velocity -= 8;
                    y -= 2;
                } else {
                    bounce_y_velocity += 8;
                    y += 2;
                }
                bounce_y_counter -= 100;
            }
            if (bounce_y_velocity < 0) {
                bounce_y_velocity = 0;
                bounce_curve_counter = 1;
            }
            if (bounce_y_velocity > 100) {
                bounce_y_velocity = 100;
                bounce_curve_counter = 1;
            }
            bounce_curve_counter--;
            if (bounce_curve_counter <= 0) {
                bounce_curve_counter = 50;
                if (bounce_down) bounce_y_velocity = 100;
                bounce_down = !bounce_down;
            }
            if (y > 164) y = 164;
            var _bounce_left = (global.current_episode == 2) ? 8 : 1;
            var _bounce_right = ((global.current_episode == 2) ? 311 : 319) - shot_w;
            return x >= _bounce_left && x <= _bounce_right;

        case 9:
            current_frame++;
            return current_frame < min(3, array_length(shot_sequence));

        case 10:
            y += 2;
            return y <= 160;

        case 11:
            if (!angle_initialized)
                shot_calculate_angle(global.player.x, global.player.y);
            var _angle_step = shot_move_angle_step();
            return shot_try_move(_angle_step[0] - x, _angle_step[1] - y);

        case 12: // Loki pod: aim at Thor, then ricochet after reaching an edge
            if (!angle_initialized)
                shot_calculate_angle(global.player.x, global.player.y);
            var _pod_step = shot_move_angle_step();
            if (_pod_step[0] < 16 || _pod_step[0] > 287
            || _pod_step[1] < 16 || _pod_step[1] > 159) {
                shot_calculate_angle(irandom(318), irandom(190));
                shot_move = 13;
                life_timer = 240;
                current_frame = min(2, array_length(shot_sequence) - 1);
            } else {
                x = _pod_step[0];
                y = _pod_step[1];
            }
            return true;

        case 13: // Loki pod ricochet phase
            life_timer--;
            if (life_timer <= 0) {
                shot_drop_reward(4, 5);
                return false;
            }
            var _ricochet_step = shot_move_angle_step();
            if (_ricochet_step[0] < 16 || _ricochet_step[0] > 287)
                angle_x_step = -angle_x_step;
            else if (_ricochet_step[1] < 16 || _ricochet_step[1] > 159)
                angle_y_step = -angle_y_step;
            else {
                x = _ricochet_step[0];
                y = _ricochet_step[1];
            }
            return true;
    }
    return false;
}

/// @description Bosses store their projectile definition alongside their own
/// actor record instead of referencing a separate shot_type.
function enemy_spawn_embedded_shot(shooter, source_actor_type) {
    if (!instance_exists(shooter)) return noone;
    if (enemy_shot_count(shooter.id) >= shooter.shots_allowed) return noone;
    var _def = shot_get_definition(source_actor_type);
    if (_def == undefined) return noone;

    var _shot = instance_create_layer(shooter.x, shooter.y, "Actors", obj_enemy_shot);
    with (_shot) {
        creator_id = shooter.id;
        shot_type = source_actor_type;
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
        facing = shooter.facing;
        speed_count = 0;
        frame_count = 0;
        current_frame = 0;
        sprite_index = asset_get_index(shot_sprite_name(source_actor_type));
        image_speed = 0;
        x = shooter.x + (shooter.col_w - shot_w) * 0.5;
        y = shooter.y + (shooter.col_h - shot_h) * 0.5;
        angle_target_x = global.player.x;
        angle_target_y = global.player.y;
        motion_delay = 0;
        slow_counter = 0;
        slow_period = 0;
        drop_wait = 0;
        drop_interval = 0;
        drop_decay_counter = 0;
        bounce_y_velocity = 0;
        bounce_y_counter = 0;
        bounce_curve_counter = 0;
        bounce_down = false;
        bounce_x_counter = 0;
        bounce_x_right = false;
        angle_x_step = 0;
        angle_y_step = 0;
        angle_x_distance = 0;
        angle_y_distance = 0;
        angle_major_y = false;
        angle_counter = 0;
        angle_initialized = false;
        path_toggle = false;
        velocity_x = 0;
        velocity_y = 0;
        life_timer = 240;
    }
    shooter.shot_cooldown = 60;
    return _shot;
}
