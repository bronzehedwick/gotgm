/// @description Original actor movement patterns from 1_MOVPAT.C

function movement_execute(inst) {
    with (inst) {
        movement_tick = false;
        speed_count++;
        if (speed_count < max(1, move_delay)) return;

        speed_count = 0;
        movement_tick = true;

        // The DOS loop calls move_actor num_moves times per cycle. Combining those
        // calls here preserves its effective speed while keeping GameMaker at 60 Hz.
        for (var _move = 0; _move < max(1, num_moves); _move++) {
            switch (move_pattern) {
                case 0:  move_none(); break;
                case 1:  move_animate_only(); break;
                case 2:  move_none(); break;
                case 3:  move_walk_bump_random(); break;
                case 4:  move_track_player(); break;
                case 5:  move_seek_player(); break;
                case 6:  move_effect(); break;
                case 7:  move_walk_pause(); break;
                case 8:  move_follow_player(); break;
                case 9:  move_random_straight(); break;
                case 10: move_vertical_random(); break;
                case 11: move_bat_diagonal(); break;
                case 12: move_horizontal_patrol(); break;
                case 13: move_mushroom(); break;
                case 14: move_roll_until_bump(); break;
                case 15: move_none(); break;
                case 16: move_tornado_outbound(); break;
                case 17: move_bat_diagonal(); break;
                case 18: move_bite_run(); break;
                case 22: move_spear(); break;
                case 19: move_walk_pause(); break;
                case 20: move_snake_boss(); break;
                case 21: move_walk_bump_random(); break;
                case 26: move_loki_boss(); break;
                case 23: move_wall_follow(false); break;
                case 24: move_wall_follow(true); break;
                case 25: move_acid_puddle(); break;
                case 27: move_skull_boss(); break;
                case 28: move_fish(); break;
                case 29: move_axis_patrol(); break;
                case 31: move_falling_trap(); break;
                case 37: move_random_straight(); break;
                case 38: move_timed_dart(); break;
                case 39: move_multipart_troll(); break;
                default: move_animate_only(); break;
            }
        }
    }
}

function move_none() {
}

function move_animate_only() {
}

function move_try(dx, dy) {
    if (!check_move_enemy(x, y, col_w, col_h, dx, dy, is_flying)) return false;

    // check_move2() in 1_MOVPAT.C tests the proposed enemy rectangle against
    // every other active actor. That includes push blocks and FAKEBUSH actors;
    // their solidity value is deliberately irrelevant for enemy movement.
    var _nx1 = x + dx + 1;
    var _ny1 = y + dy + 1;
    var _nx2 = x + dx + col_w - 1;
    var _ny2 = y + dy + col_h - 1;
    for (var _i = 0; _i < instance_number(obj_enemy); _i++) {
        var _other = instance_find(obj_enemy, _i);
        if (_other == noone || _other.id == id || !_other.visible
        || _other.is_dead || _other.is_magic_effect) continue;
        var _ox1 = _other.x;
        var _oy1 = _other.y;
        var _ox2 = _other.x + _other.col_w;
        var _oy2 = _other.y + _other.col_h;
        if (_nx1 <= _ox2 && _nx2 >= _ox1
        && _ny1 <= _oy2 && _ny2 >= _oy1) return false;
    }
    x += dx;
    y += dy;
    return true;
}

function move_reverse_direction(dir) {
    switch (dir) {
        case Dir.UP: return Dir.DOWN;
        case Dir.DOWN: return Dir.UP;
        case Dir.LEFT: return Dir.RIGHT;
        default: return Dir.LEFT;
    }
}

function move_walk_bump_random() {
    var _dx = 0;
    var _dy = 0;
    switch (facing) {
        case Dir.UP: _dy = -2; break;
        case Dir.DOWN: _dy = 2; break;
        case Dir.LEFT: _dx = -2; break;
        case Dir.RIGHT: _dx = 2; break;
    }
    if (!move_try(_dx, _dy)) facing = irandom(3);
}

function move_track_player() {
    if (global.player == noone || !instance_exists(global.player)) return;

    var _dx = clamp((global.player.x - 1) - x, -2, 2);
    if (_dx != 0) {
        facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
        if (move_try(_dx, 0)) return;
    }

    var _dy = clamp(global.player.y - y, -2, 2);
    if (_dy != 0) {
        facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
        move_try(0, _dy);
    }
}

function move_seek_player() {
    if (global.player == noone || !instance_exists(global.player)) return;

    var _dx = 0;
    var _dy = 0;
    if (x > global.player.x + 1) _dx = -2;
    else if (x < global.player.x - 1) _dx = 2;
    if (y < global.player.y - 1) _dy = 2;
    else if (y > global.player.y + 1) _dy = -2;

    if (_dx != 0 && _dy != 0 && move_try(_dx, _dy)) {
        facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
        return;
    }

    axis_toggle = !axis_toggle;
    if (axis_toggle) {
        if (_dx != 0 && move_try(_dx, 0)) {
            facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
            return;
        }
        if (_dy != 0 && move_try(0, _dy)) facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
    } else {
        if (_dy != 0 && move_try(0, _dy)) {
            facing = (_dy < 0) ? Dir.UP : Dir.DOWN;
            return;
        }
        if (_dx != 0 && move_try(_dx, 0)) facing = (_dx < 0) ? Dir.LEFT : Dir.RIGHT;
    }
}

function move_walk_pause() {
    if (pause_timer > 0) {
        pause_timer--;
        return;
    }
    if (current_frame == 0 && frame_count == 0) {
        pause_timer = 12;
        facing = irandom(3);
    }
    move_walk_bump_random();
}

function move_random_straight() {
    if (move_counter <= 0) {
        move_counter = irandom_range(10, 99);
        facing = irandom(3);
        return;
    }

    move_counter--;
    var _dx = 0;
    var _dy = 0;
    switch (facing) {
        case Dir.UP: _dy = -2; break;
        case Dir.DOWN: _dy = 2; break;
        case Dir.LEFT: _dx = -2; break;
        case Dir.RIGHT: _dx = 2; break;
    }
    if (!move_try(_dx, _dy)) move_counter = 0;
}

function move_vertical_random() {
    if (facing > Dir.DOWN) facing = irandom(1);
    if (move_counter <= 0) {
        move_counter = irandom_range(10, 99);
        facing = irandom(1);
        return;
    }
    if (pass_value != 1) move_counter--;
    var _dy = (facing == Dir.UP) ? -2 : 2;
    if (!move_try(0, _dy)) move_counter = 0;
}

function move_bat_diagonal() {
    var _first_x = 0;
    var _first_y = 0;
    var _second_x = 0;
    var _second_y = 0;
    var _second_dir = facing;
    var _fail_dir = facing;

    switch (facing) {
        case Dir.UP:
            _first_x = -2; _first_y = -2;
            _second_x = -2; _second_y = 2; _second_dir = Dir.DOWN; _fail_dir = Dir.LEFT;
            break;
        case Dir.DOWN:
            _first_x = -2; _first_y = 2;
            _second_x = -2; _second_y = -2; _second_dir = Dir.UP; _fail_dir = Dir.RIGHT;
            break;
        case Dir.LEFT:
            _first_x = 2; _first_y = -2;
            _second_x = 2; _second_y = 2; _second_dir = Dir.RIGHT; _fail_dir = Dir.UP;
            break;
        case Dir.RIGHT:
            _first_x = 2; _first_y = 2;
            _second_x = 2; _second_y = -2; _second_dir = Dir.LEFT; _fail_dir = Dir.DOWN;
            break;
    }

    if (move_try(_first_x, _first_y)) return;
    facing = _second_dir;
    if (move_try(_second_x, _second_y)) return;
    facing = _fail_dir;
}

function move_mushroom() {
    if (pause_timer <= 0 && move_counter <= 0) {
        pause_timer = 60;
        // The setup branch in movement_thirteen() also returns before
        // next_frame(), so the resting pose begins without an extra frame.
        movement_tick = false;
        return;
    }
    if (pause_timer > 0) {
        pause_timer--;
        strength = 0;
        vulnerable_timer = max(vulnerable_timer, 5);
        // movement_thirteen() returns without next_frame() while resting.
        movement_tick = false;
        if (pause_timer <= 0) move_counter = 60;
        return;
    }

    strength = actor_def.strength;
    move_counter--;
    move_seek_player();
    if (move_counter <= 0) pause_timer = 60;
}

function move_bite_run() {
    if (bite_speed_timer > 0) {
        bite_speed_timer--;
        if (bite_speed_timer <= 0) num_moves = 1;
    }
    if (ai_timer <= 0) {
        ai_timer = irandom_range(50, 149);
        ai_seek = !ai_seek;
    }

    if (ai_seek) move_seek_player();
    else move_walk_bump_random();
    ai_timer--;

    if (hit_player) {
        hit_player = false;
        bite_speed_timer = 50;
        num_moves = 2;
        facing = move_reverse_direction(facing);
        if (ai_seek) {
            ai_seek = false;
            ai_timer = irandom_range(50, 149);
        }
    }
}

function move_spear() {
    // The trap extends, holds for ten movement counts, retracts, pauses, then
    // advances diagonally around its sequence of wall anchors.
    var _redo = true;
    var _guard = 0;
    while (_redo && _guard++ < 16) {
        _redo = false;
        switch (spear_phase) {
            case 0:
                if (tile_get(x div TILE_W, y div TILE_H) >= TILE_SOLID) {
                    current_frame = 1;
                    spear_phase = 1;
                } else {
                    spear_phase = 6;
                    spear_timer = 1;
                    _redo = true;
                }
                break;
            case 1:
                current_frame = 2;
                spear_phase = 2;
                break;
            case 2:
                current_frame = 3;
                strength = 255;
                spear_phase = 3;
                spear_timer = 10;
                break;
            case 3:
                spear_timer--;
                if (spear_timer <= 0) {
                    spear_phase = 4;
                    current_frame = 2;
                }
                break;
            case 4:
                strength = 0;
                spear_phase = 5;
                current_frame = 1;
                break;
            case 5:
                spear_phase = 6;
                current_frame = 0;
                spear_timer = 10;
                break;
            case 6:
                spear_timer--;
                if (spear_timer <= 0) {
                    spear_phase = 0;
                    current_frame = 0;
                    switch (facing) {
                        case Dir.UP:    x += 16; y += 16; facing = Dir.RIGHT; break;
                        case Dir.DOWN:  x -= 16; y -= 16; facing = Dir.LEFT; break;
                        case Dir.LEFT:  x += 16; y -= 16; facing = Dir.UP; break;
                        case Dir.RIGHT: x -= 16; y += 16; facing = Dir.DOWN; break;
                    }
                    if (tile_get(x div TILE_W, y div TILE_H) < TILE_SOLID)
                        _redo = true;
                }
                break;
        }
    }
}

function move_fish() {
    if (fish_cooldown > 0) {
        fish_cooldown--;
        var _delta = move_direction_delta(fish_direction);
        var _nx = x + _delta[0];
        var _ny = y + _delta[1];
        var _allowed = true;
        var _corners = [
            tile_get(_nx div TILE_W, _ny div TILE_H),
            tile_get((_nx + col_w - 1) div TILE_W, _ny div TILE_H),
            tile_get(_nx div TILE_W, (_ny + col_h - 1) div TILE_H),
            tile_get((_nx + col_w - 1) div TILE_W, (_ny + col_h - 1) div TILE_H)
        ];
        for (var _i = 0; _i < 4; _i++) {
            var _tile = _corners[_i];
            if (_tile != 100 && _tile != 106 && _tile != 110
            && _tile != 111 && _tile != 113) _allowed = false;
        }
        if (_allowed) {
            x = _nx;
            y = _ny;
        } else fish_direction = irandom(3);
    } else if (!fish_descending) {
        if (current_frame == 0) {
            frame_count = 1;
            frame_speed = 4;
        }
        frame_count--;
        if (frame_count <= 0) {
            current_frame = (current_frame + 1) mod array_length(frame_sequence);
            frame_count = frame_speed;
        }
        if (current_frame == 3) {
            var _fish_shot_def = shot_get_definition(actor_type_id);
            if (enemy_shot_count(id) < shots_allowed
            && _fish_shot_def != undefined
            && enemy_shot_line_clear(id, Dir.UP, _fish_shot_def.flying > 0)) {
                var _fish_shot = enemy_spawn_embedded_shot(id, actor_type_id);
                if (_fish_shot != noone) _fish_shot.facing = Dir.UP;
            }
            fish_descending = true;
        }
    } else {
        frame_count--;
        if (frame_count <= 0) {
            current_frame--;
            frame_count = frame_speed;
            if (current_frame <= 0) {
                current_frame = 0;
                fish_descending = false;
                frame_speed = 4;
                fish_cooldown = irandom_range(60, 159);
            }
        }
    }

    if (current_frame > 0) {
        solid_type = 1;
        strength = actor_def.strength;
    } else {
        solid_type = 2;
        strength = 0;
    }
}

function move_axis_patrol() {
    if (pass_value == 0) {
        if (facing > Dir.DOWN) facing = Dir.DOWN;
        var _dy = (facing == Dir.UP) ? -2 : 2;
        if (!move_try(0, _dy)) facing = move_reverse_direction(facing);
    } else {
        if (facing < Dir.LEFT) facing = Dir.RIGHT;
        var _dx = (facing == Dir.LEFT) ? -2 : 2;
        if (!move_try(_dx, 0)) facing = move_reverse_direction(facing);
    }
}

function move_falling_trap() {
    if (!trap_falling) {
        if (global.player != noone && instance_exists(global.player)
        && global.player.y > y && abs(global.player.x - x) < 16) {
            var _column = (x + col_w * 0.5) div TILE_W;
            var _from_row = (y + col_h - 2) div TILE_H;
            var _to_row = (global.player.y + global.player.col_h * 0.5) div TILE_H;
            var _clear = true;
            for (var _row = _from_row; _row <= _to_row; _row++) {
                if (tile_get(_column, _row) < TILE_SOLID) {
                    _clear = false;
                    break;
                }
            }
            if (_clear) {
                trap_falling = true;
                num_moves = max(1, pass_value + 1);
                audio_play_sound(snd_got_fall, 1, false);
            }
        }
        return;
    }

    if (!move_try(0, 2)) {
        health = 0;
        is_dead = true;
        combat_spawn_death_effect(id);
        combat_drop_loot(id);
        instance_destroy();
    }
}

function move_timed_dart() {
    if (!dart_initialized) {
        dart_initialized = true;
        dart_timer = (pass_value > 0) ? pass_value * 15 : irandom_range(5, 364);
        dart_origin_x = x;
        dart_origin_y = y;
        dart_initial_dir = facing;
        dart_return_dir = move_reverse_direction(facing);
        dart_state = 0;
    }

    if (dart_timer > 0) {
        dart_timer--;
        return;
    }

    var _dx = 0;
    var _dy = 0;
    switch (facing) {
        case Dir.UP: _dy = -2; break;
        case Dir.DOWN: _dy = 2; break;
        case Dir.LEFT: _dx = -2; break;
        case Dir.RIGHT: _dx = 2; break;
    }

    if (dart_state == 0) {
        if (!move_try(_dx, _dy)) {
            if (x == dart_origin_x && y == dart_origin_y) {
                dart_initialized = false;
            } else {
                dart_state = 1;
                facing = dart_return_dir;
            }
        }
    } else {
        move_try(_dx, _dy);
        var _arrived_x = (dart_initial_dir < Dir.LEFT) || abs(x - dart_origin_x) <= 2;
        var _arrived_y = (dart_initial_dir >= Dir.LEFT) || abs(y - dart_origin_y) <= 2;
        if (_arrived_x && _arrived_y) {
            x = dart_origin_x;
            y = dart_origin_y;
            facing = dart_initial_dir;
            dart_initialized = false;
        }
    }
}

function move_effect() {
    current_frame = (current_frame + 1) mod array_length(frame_sequence);
    effect_timer--;
    if (effect_timer <= 0) {
        if (death_source_def != undefined) {
            combat_drop_loot_definition(death_source_def, x, y, death_source_w, death_source_h);
            death_source_def = undefined;
        }
        is_dead = true;
        instance_destroy();
    } else if (is_boss_explosion && current_frame == 0) {
        audio_play_sound(snd_got_explode, 3, false);
    }
}

function move_follow_player() {
    if (global.player == noone || !instance_exists(global.player)) return;
    x = (global.player.x > 0) ? global.player.x - 1 : global.player.x;
    y = global.player.y;
}

function move_horizontal_patrol() {
    if (facing != Dir.LEFT && facing != Dir.RIGHT) facing = Dir.LEFT;
    var _dx = (facing == Dir.LEFT) ? -2 : 2;
    if (!move_try(_dx, 0)) facing = move_reverse_direction(facing);
}

function move_roll_until_bump() {
    var _dx = 0;
    var _dy = 0;
    switch (facing) {
        case Dir.UP: _dy = -2; break;
        case Dir.DOWN: _dy = 2; break;
        case Dir.LEFT: _dx = -2; break;
        case Dir.RIGHT: _dx = 2; break;
    }
    if (!actor_special_move_try(id, _dx, _dy)) move_pattern = 15;
}

function move_tornado_outbound() {
    var _dx = 0;
    var _dy = 0;
    switch (facing) {
        case Dir.UP: _dy = -2; break;
        case Dir.DOWN: _dy = 2; break;
        case Dir.LEFT: _dx = -2; break;
        case Dir.RIGHT: _dx = 2; break;
    }
    if (!move_try(_dx, _dy)) {
        move_pattern = 17;
        facing = irandom(3);
    }
}

function move_turn_left(dir) {
    switch (dir) {
        case Dir.UP: return Dir.LEFT;
        case Dir.DOWN: return Dir.RIGHT;
        case Dir.LEFT: return Dir.DOWN;
        default: return Dir.UP;
    }
}

function move_turn_right(dir) {
    switch (dir) {
        case Dir.UP: return Dir.RIGHT;
        case Dir.DOWN: return Dir.LEFT;
        case Dir.LEFT: return Dir.UP;
        default: return Dir.DOWN;
    }
}

function move_direction_delta(dir) {
    switch (dir) {
        case Dir.UP: return [0, -2];
        case Dir.DOWN: return [0, 2];
        case Dir.LEFT: return [-2, 0];
        default: return [2, 0];
    }
}

function move_wall_follow(clockwise) {
    if ((pass_value & 2) != 0) num_moves = 2;
    var _side = clockwise ? move_turn_right(facing) : move_turn_left(facing);
    var _other = clockwise ? move_turn_left(facing) : move_turn_right(facing);
    var _choices = [_side, facing, _other, move_reverse_direction(facing)];
    for (var _i = 0; _i < 4; _i++) {
        var _dir = _choices[_i];
        var _delta = move_direction_delta(_dir);
        if (move_try(_delta[0], _delta[1])) {
            facing = _dir;
            return;
        }
    }
}

function move_acid_puddle() {
    if (pause_timer > 0) {
        pause_timer--;
        return;
    }
    if (move_counter <= 0) {
        move_counter = 16;
        facing = irandom(3);
    }
    move_counter--;
    var _delta = move_direction_delta(facing);
    if (!move_try(_delta[0], _delta[1])) {
        facing = (facing + 1) mod 4;
        pause_timer = 12;
    }
}

function movement_actor_slot(slot_number) {
    for (var _i = 0; _i < instance_number(obj_enemy); _i++) {
        var _actor = instance_find(obj_enemy, _i);
        if (_actor != noone && _actor.actor_slot == slot_number) return _actor;
    }
    return noone;
}

function movement_sync_part(slot_number, px, py, frame, dir) {
    var _part = movement_actor_slot(slot_number);
    if (_part == noone) return;
    _part.x = px;
    _part.y = py;
    _part.current_frame = frame;
    _part.facing = dir;
}

function move_snake_boss() {
    if (actor_slot != 3 || actor_type_id != 22) return;
    if (global.player == noone || !instance_exists(global.player)) return;

    if (boss_state == 0) {
        if (boss_timer > 0) boss_timer--;
        if (boss_timer <= 0 && x > global.player.x
        && abs((y + 20) - (global.player.y + 8)) < 8) {
            boss_state = 1;
            boss_timer = 75;
            num_moves = 6;
        } else {
            if (facing > Dir.DOWN) facing = Dir.DOWN;
            var _dy = (facing == Dir.UP) ? -2 : 2;
            if (check_move_enemy(x, y, 31, 31, 0, _dy, false)) y += _dy;
            else facing = move_reverse_direction(facing);
        }
    } else if (boss_state == 1) {
        boss_timer--;
        if (boss_timer <= 0) {
            boss_state = 2;
            boss_timer = 130;
            num_moves = global.difficulty + 2;
            audio_play_sound(snd_got_braapp, 2, false);
        }
    } else if (boss_state == 2) {
        facing = Dir.LEFT;
        x -= 2;
        boss_timer--;
        if (boss_timer <= 0 || x < global.player.x + 12) boss_state = 3;
    } else {
        num_moves = global.difficulty + 1;
        facing = Dir.RIGHT;
        x += 2;
        if (x >= 256) {
            x = 256;
            boss_state = 0;
            boss_timer = irandom_range(10, 99);
            num_moves = 2;
        }
    }

    movement_sync_part(4, x + 16, y, current_frame, facing);
    movement_sync_part(5, x, y + 16, current_frame, facing);
    movement_sync_part(6, x + 16, y + 16, current_frame, facing);
}

function move_multipart_troll() {
    // pass values below five mark the lower-left leader of a four-part troll.
    if (pass_value >= 5) return;
    if (facing != Dir.LEFT && facing != Dir.RIGHT) facing = Dir.LEFT;
    var _dx = (facing == Dir.LEFT) ? -2 : 2;
    if (check_move_enemy(x, y - 16, 31, 31, _dx, 0, false)) {
        for (var _slot = actor_slot - 2; _slot <= actor_slot + 1; _slot++) {
            var _part = movement_actor_slot(_slot);
            if (_part != noone) {
                _part.x += _dx;
                _part.facing = facing;
                _part.current_frame = current_frame;
            }
        }
    } else {
        facing = move_reverse_direction(facing);
    }
}

function move_loki_boss() {
    if (actor_slot != 3 || actor_type_id != 64) return;
    if (global.player == noone || !instance_exists(global.player)) return;

    if (boss_state == 0) {
        boss_counter++;
        boss_timer--;
        if (boss_timer <= 0) {
            boss_direction8 = irandom(7);
            boss_timer = irandom_range(60, 159);
        }

        var _loki_dx = 0;
        var _loki_dy = 0;
        switch (boss_direction8) {
            case 0: _loki_dy = -2; facing = Dir.UP; break;
            case 1: _loki_dy = 2; facing = Dir.DOWN; break;
            case 2: _loki_dx = -2; facing = Dir.LEFT; break;
            case 3: _loki_dx = 2; facing = Dir.RIGHT; break;
            case 4: _loki_dx = -2; _loki_dy = -2; facing = Dir.LEFT; break;
            case 5: _loki_dx = 2; _loki_dy = -2; facing = Dir.RIGHT; break;
            case 6: _loki_dx = 2; _loki_dy = 2; facing = Dir.RIGHT; break;
            case 7: _loki_dx = -2; _loki_dy = 2; facing = Dir.LEFT; break;
        }
        if (!check_move_enemy(x, y, 31, 31, _loki_dx, _loki_dy, true)) {
            boss_timer = 0;
        } else {
            x += _loki_dx;
            y += _loki_dy;
        }

        if (boss_counter >= 120) {
            boss_counter = 0;
            var _first_shot = enemy_spawn_embedded_shot(id, 64);
            if (_first_shot != noone) {
                _first_shot.x = x + 8;
                _first_shot.y = y - 8;
                _first_shot.motion_delay = 30;
                _first_shot.life_timer = irandom_range(90, 189);
            }
            audio_play_sound(snd_got_electric, 3, false);
        }
        boss_invulnerable = false;
        image_alpha = 1;
    } else {
        boss_timer--;
        if (boss_timer > 80) {
            boss_invulnerable = true;
            image_alpha = 0.25;
        } else if (boss_timer == 80) {
            var _tx = x;
            var _ty = y;
            for (var _attempt = 0; _attempt < 12; _attempt++) {
                _tx = irandom_range(16, 272);
                _ty = irandom_range(8, 144);
                if (point_distance(_tx, _ty, global.player.x, global.player.y) > 48) break;
            }
            x = _tx;
            y = _ty;
            facing = Dir.UP;
            boss_invulnerable = false;
            image_alpha = 1;
            audio_play_sound(snd_got_explode, 3, false);

            var _pod_source = movement_actor_slot(4);
            if (_pod_source != noone) {
                var _pods = (global.difficulty == 0) ? 3
                    : ((global.difficulty == 1) ? 5 : 8);
                _pod_source.shots_allowed = max(_pod_source.shots_allowed, _pods);
                for (var _pod_index = 0; _pod_index < _pods; _pod_index++) {
                    var _pod = enemy_spawn_embedded_shot(_pod_source, 65);
                    if (_pod != noone) {
                        _pod.x = x + 8;
                        _pod.y = y + 16;
                        _pod.angle_target_x = global.player.x + irandom_range(-32, 32);
                        _pod.angle_target_y = global.player.y + irandom_range(-32, 32);
                    }
                }
            }
        } else if (boss_timer <= 0) {
            boss_timer = 160;
            boss_invulnerable = true;
            image_alpha = 0.25;
            audio_play_sound(snd_got_explode, 3, false);
        }
    }

    for (var _part_slot = 4; _part_slot <= 6; _part_slot++) {
        var _loki_part = movement_actor_slot(_part_slot);
        if (_loki_part != noone) _loki_part.image_alpha = image_alpha;
    }

    movement_sync_part(4, x + 16, y, current_frame, facing);
    movement_sync_part(5, x, y + 16, current_frame, facing);
    movement_sync_part(6, x + 16, y + 16, current_frame, facing);
}

function move_skull_boss() {
    if (actor_slot != 3 || actor_type_id != 31) return;
    if (boss_state == 1) {
        boss_invulnerable = true;
        boss_timer--;
        if (boss_timer <= 0) {
            boss_timer = 6;
            var _floor_row = 3 + boss_counter div 10;
            var _floor_step = boss_counter mod 10;
            var _floor_column = 1 + (_floor_step div 2) * 4 + (_floor_step mod 2);
            level_set_tile(_floor_column, _floor_row, global.current_level_metadata.bg_color);
            if ((boss_counter mod 3) == 0)
                audio_play_sound(snd_got_explode, 3, false);
            boss_counter++;
            if (boss_counter >= 60) {
                boss_state = 2;
                boss_counter = 0;
                boss_invulnerable = false;
                num_moves = 3;
            }
        }
    } else if (boss_state == 2) {
        boss_invulnerable = false;
        if (boss_counter == 0) {
            if (x < 144) x += 2;
            else if (x > 144) x -= 2;
            else {
                boss_counter = 1;
                boss_direction8 = irandom(1);
            }
        } else {
            var _phase_dx = (boss_direction8 == 0) ? -2 : 2;
            x += _phase_dx;
            facing = (_phase_dx < 0) ? Dir.LEFT : Dir.RIGHT;
            if (x < 20 || x > 270) {
                x = clamp(x, 20, 270);
                boss_counter = 0;
                audio_play_sound(snd_got_explode, 4, false);
                var _spike_source = movement_actor_slot(4);
                if (_spike_source != noone) {
                    var _spikes = 5 + global.difficulty * 3;
                    _spike_source.shots_allowed = max(_spike_source.shots_allowed, _spikes);
                    for (var _spike_index = 0; _spike_index < _spikes; _spike_index++) {
                        var _spike = enemy_spawn_embedded_shot(_spike_source, 32);
                        if (_spike != noone) {
                            _spike.x = (_spike_index == 0)
                                ? global.player.x : 16 + irandom(17) * 16;
                            _spike.y = irandom(15);
                        }
                    }
                }
            }
        }
    } else {
        if (facing != Dir.LEFT && facing != Dir.RIGHT) facing = Dir.LEFT;
        var _dx = (facing == Dir.LEFT) ? -2 : 2;
        var _next_x = x + _dx;
        if (_next_x < 18 || _next_x > 272
        || !check_move_enemy(x, y, 31, 31, _dx, 0, true)) {
            facing = move_reverse_direction(facing);
        } else {
            x = _next_x;
        }

        boss_timer--;
        if (boss_timer <= 0 && (x == 48 || x == 112 || x == 176 || x == 240)) {
            var _shot = enemy_spawn_embedded_shot(id, 31);
            if (_shot != noone) {
                _shot.x = x + 12;
                _shot.y = y + 32;
                _shot.shot_move = 7;
                _shot.drop_wait = 4;
                _shot.drop_interval = 4;
            }
            audio_play_sound(snd_got_fall, 2, false);
            boss_timer = 40;
        }
    }

    movement_sync_part(4, x + 16, y, current_frame, facing);
    movement_sync_part(5, x, y + 16, current_frame, facing);
    movement_sync_part(6, x + 16, y + 16, current_frame, facing);
}
