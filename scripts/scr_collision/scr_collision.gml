/// @description Tile-based collision checks

function actor_special_move_try(actor_inst, dx, dy) {
    if (!instance_exists(actor_inst)) return false;
    if (!check_move_enemy(actor_inst.x, actor_inst.y, actor_inst.col_w,
                          actor_inst.col_h, dx, dy, actor_inst.is_flying)) return false;

    var _nx1 = actor_inst.x + dx;
    var _ny1 = actor_inst.y + dy;
    var _nx2 = _nx1 + actor_inst.col_w - 1;
    var _ny2 = _ny1 + actor_inst.col_h - 1;
    for (var _i = 0; _i < instance_number(obj_enemy); _i++) {
        var _other = instance_find(obj_enemy, _i);
        if (_other == noone || _other.id == actor_inst.id || !_other.visible
        || _other.is_magic_effect) continue;
        if (_nx1 <= _other.x + _other.col_w - 1 && _nx2 >= _other.x
        && _ny1 <= _other.y + _other.col_h - 1 && _ny2 >= _other.y) return false;
    }

    actor_inst.x = _nx1;
    actor_inst.y = _ny1;
    return true;
}

/// @description Original special_movement_func callbacks used when Thor walks
/// into a puzzle actor. Returns whether Thor may complete the proposed step.
function actor_player_collision(actor_inst, dx, dy) {
    if (!instance_exists(actor_inst) || actor_inst.actor_def == undefined) return true;
    var _func = actor_inst.actor_def.func_num;
    var _diagonal = global.player.input_diagonal;

    switch (_func) {
        case 1: // pushable block
            if (_diagonal) return false;
            var _push_x = sign(dx) * 2;
            var _push_y = sign(dy) * 2;
            if (!actor_special_move_try(actor_inst, _push_x, _push_y)) return false;
            if (_push_x < 0) actor_inst.facing = Dir.LEFT;
            else if (_push_x > 0) actor_inst.facing = Dir.RIGHT;
            else if (_push_y < 0) actor_inst.facing = Dir.UP;
            else actor_inst.facing = Dir.DOWN;
            return true;

        case 2: // red/green angel: recharge while Thor presses against it
            if (actor_inst.special_cooldown <= 0) {
                if (actor_inst.actor_def.func_pass == 0 && global.health < MAX_HEALTH) {
                    global.health++;
                    audio_play_sound(snd_got_angel, 1, false);
                } else if (actor_inst.actor_def.func_pass != 0 && global.magic < MAX_MAGIC) {
                    global.magic++;
                    audio_play_sound(snd_got_angel, 1, false);
                }
                actor_inst.special_cooldown = 6;
            }
            return false;

        case 3: // yellow globe dialogue
        case 4: // floor switch
        case 7: // arrow switch
        case 10: // ordinary speaker
        case 11: // red guard speaker
            actor_trigger_special(actor_inst, false);
            return false;

        case 5: // boulder: contact starts it rolling
            actor_inst.facing = global.player.facing;
            actor_inst.move_pattern = 14;
            return false;

        case 8: // horizontal barrel
            if (_diagonal || global.player.facing < Dir.LEFT) return false;
            actor_inst.facing = global.player.facing;
            actor_inst.move_pattern = 14;
            return false;

        case 9: // vertical barrel
            if (_diagonal || global.player.facing > Dir.DOWN) return false;
            actor_inst.facing = global.player.facing;
            actor_inst.move_pattern = 14;
            return false;

        case 255: // explosion effect
            return false;
    }
    return true;
}

function check_move_player(px, py, pw, ph, dx, dy) {
    var _nx = px + dx;
    var _ny = py + dy;

    // Crossing the 320x192 edge is allowed so obj_game can change rooms.
    if (_nx < 0 || _nx + pw > SCREEN_W) return true;
    if (_ny < 0 || _ny + ph > SCREEN_H) return true;

    var _x1 = _nx + 2;
    var _y1 = _ny + 2;
    var _x2 = _nx + pw - 2;
    var _y2 = _ny + ph - 2;
    var _gx1 = _x1 div TILE_W;
    var _gy1 = _y1 div TILE_H;
    var _gx2 = _x2 div TILE_W;
    var _gy2 = _y2 div TILE_H;

    for (var _gy = _gy1; _gy <= _gy2; _gy++) {
        for (var _gx = _gx1; _gx <= _gx2; _gx++) {
            var _tid = tile_get(_gx, _gy);
            if (_tid < 0) return false;
            if (tile_is_solid(_tid)) return false;
            if (tile_is_fly_only(_tid)) return false;
            if (tile_is_special(_tid)) {
                if (!special_tile_player(_gx, _gy, _tid, _nx, _ny)) return false;
            }
        }
    }

    // The DOS engine checks actor callbacks as part of each proposed Thor move.
    // Use Thor's original narrow lower-body collision rectangle here.
    var _px1 = _nx + 1;
    var _py1 = _ny + 8;
    var _px2 = _nx + 12;
    var _py2 = _ny + 15;
    for (var _i = 0; _i < instance_number(obj_enemy); _i++) {
        var _actor = instance_find(obj_enemy, _i);
        if (_actor == noone || !_actor.visible || _actor.is_magic_effect
        || ((_actor.solid_type & 128) != 0)) continue;
        var _ax1 = _actor.x + 1;
        var _ay1 = _actor.y + 1;
        var _ax2 = _actor.x + _actor.col_w - 1;
        var _ay2 = _actor.y + _actor.col_h - 1;
        if (_px1 <= _ax2 && _px2 >= _ax1 && _py1 <= _ay2 && _py2 >= _ay1) {
            return actor_player_collision(_actor, dx, dy);
        }
    }
    return true;
}

function check_move_hammer(hx, hy, dx, dy) {
    var _nx = hx + dx;
    var _ny = hy + dy;

    if (_nx < 0 || _nx + 16 > SCREEN_W) return 1;
    if (_ny < 0 || _ny + 16 > SCREEN_H) return 1;

    var _gx = (_nx + 8) div TILE_W;
    var _gy = (_ny + 8) div TILE_H;
    var _tid = tile_get(_gx, _gy);
    if (_tid >= 0 && _tid < TILE_SOLID) return 1;
    return 0;
}

function check_move_enemy(ex, ey, ew, eh, dx, dy, is_flying) {
    var _nx = ex + dx;
    var _ny = ey + dy;

    if (_nx < 0 || _nx + ew > SCREEN_W) return false;
    if (_ny < 0 || _ny + eh > SCREEN_H) return false;

    var _gx1 = _nx div TILE_W;
    var _gy1 = _ny div TILE_H;
    var _gx2 = (_nx + ew - 1) div TILE_W;
    var _gy2 = (_ny + eh - 1) div TILE_H;

    for (var _gy = _gy1; _gy <= _gy2; _gy++) {
        for (var _gx = _gx1; _gx <= _gx2; _gx++) {
            var _tid = tile_get(_gx, _gy);
            if (_tid < 0) return false;
            if (tile_is_solid(_tid)) return false;
            if (!is_flying && tile_is_fly_only(_tid)) return false;
            if (tile_is_special(_tid) && !special_tile_enemy(_tid, is_flying)) return false;
        }
    }
    return true;
}
