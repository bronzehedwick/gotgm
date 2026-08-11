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
    move_counter--;
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
    if (pause_timer <= 0 && move_counter <= 0) pause_timer = 60;
    if (pause_timer > 0) {
        pause_timer--;
        strength = 0;
        return;
    }

    strength = actor_def.strength;
    move_counter--;
    move_seek_player();
    if (move_counter <= 0) pause_timer = 60;
}

function move_bite_run() {
    if (ai_timer <= 0) {
        ai_timer = irandom_range(50, 149);
        ai_seek = !ai_seek;
    }
    ai_timer--;
    if (ai_seek) move_seek_player();
    else move_walk_bump_random();
}

function move_spear() {
    // The spear extends over four source frames, remains harmful briefly, then retracts.
    spear_timer++;
    if (spear_timer >= 16) {
        spear_timer = 0;
        spear_phase = (spear_phase + 1) mod 4;
    }
    current_frame = min(spear_phase, max(0, array_length(frame_sequence) - 1));
    strength = (spear_phase == 3) ? 255 : actor_def.strength;
}

function move_fish() {
    if (fish_pause > 0) {
        fish_pause--;
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

    var _nx = x + _dx;
    var _ny = y + _dy;
    var _allowed = true;
    var _corners = [
        tile_get(_nx div TILE_W, _ny div TILE_H),
        tile_get((_nx + col_w - 1) div TILE_W, _ny div TILE_H),
        tile_get(_nx div TILE_W, (_ny + col_h - 1) div TILE_H),
        tile_get((_nx + col_w - 1) div TILE_W, (_ny + col_h - 1) div TILE_H)
    ];
    for (var _i = 0; _i < 4; _i++) {
        var _t = _corners[_i];
        if (_t != 100 && _t != 106 && _t != 110 && _t != 111 && _t != 113) _allowed = false;
    }

    if (_allowed) {
        x = _nx;
        y = _ny;
    } else {
        facing = irandom(3);
        fish_pause = irandom_range(15, 45);
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
            trap_falling = true;
            num_moves = max(1, pass_value + 1);
            audio_play_sound(snd_got_fall, 1, false);
        }
        return;
    }

    if (!move_try(0, 2)) {
        health = 0;
        is_dead = true;
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
    effect_timer--;
    if (effect_timer <= 0) {
        is_dead = true;
        instance_destroy();
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
            audio_play_sound(snd_got_braapp, 2, false);
        }
    } else if (boss_state == 2) {
        facing = Dir.LEFT;
        x -= 2;
        boss_timer--;
        if (boss_timer <= 0 || x < global.player.x + 12) boss_state = 3;
    } else {
        facing = Dir.RIGHT;
        x += 2;
        if (x >= 256) {
            x = 256;
            boss_state = 0;
            boss_timer = irandom_range(10, 99);
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

    boss_timer--;
    if (boss_timer <= 0) {
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
        audio_play_sound(snd_got_explode, 3, false);
        var _shot = enemy_spawn_embedded_shot(id, 65);
        if (_shot != noone) {
            _shot.x = x + 8;
            _shot.y = y + 16;
        }
        boss_timer = max(55, 105 - global.difficulty * 20);
    }

    movement_sync_part(4, x + 16, y, current_frame, facing);
    movement_sync_part(5, x, y + 16, current_frame, facing);
    movement_sync_part(6, x + 16, y + 16, current_frame, facing);
}

function move_skull_boss() {
    if (actor_slot != 3 || actor_type_id != 31) return;
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
    if (boss_timer <= 0) {
        var _shot = enemy_spawn_embedded_shot(id, 31);
        if (_shot != noone) {
            _shot.x = x + 12;
            _shot.y = y + 32;
            _shot.shot_move = 7;
        }
        audio_play_sound(snd_got_fall, 2, false);
        boss_timer = max(35, 75 - global.difficulty * 15);
    }

    movement_sync_part(4, x + 16, y, current_frame, facing);
    movement_sync_part(5, x, y + 16, current_frame, facing);
    movement_sync_part(6, x + 16, y + 16, current_frame, facing);
}
