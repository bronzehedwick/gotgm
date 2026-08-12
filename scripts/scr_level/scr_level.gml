/// @description Editable room and original level metadata management

/// @description Compatibility entry point: change to an editable level room
function level_load(level_index) {
    var _target = level_room_asset(global.current_episode, level_index);
    if (_target != -1) {
        room_goto(_target);
    } else {
        show_debug_message("ERROR: Missing editable room for level " + string(level_index));
    }
}

function level_enter_current_room() {
    var _room_name = room_get_name(room);
    if (string_pos("rm_ep", _room_name) != 1) return;

    magic_destroy_tornado();
    global.shield_on = false;
    global.slip_active = false;
    global.slip_charge = 0;
    global.slip_timer = 0;
    global.boss_death_active = false;

    var _episode = real(string_copy(_room_name, 6, 1));
    var _level_index = real(string_copy(_room_name, 8, 3));
    global.current_episode = _episode;
    global.current_level = _level_index;

    if (global.loaded_episode != _episode || global.level_data == undefined) {
        var _path = "data/sdat" + string(_episode) + ".json";
        var _buf = buffer_load(_path);
        if (_buf == -1) {
            show_debug_message("ERROR: Could not load level metadata: " + _path);
            return;
        }
        var _str = buffer_read(_buf, buffer_string);
        buffer_delete(_buf);
        global.level_data = json_parse(_str);
        global.loaded_episode = _episode;
    }

    global.current_level_metadata = global.level_data[_level_index];
    global.tile_grid = variable_clone(global.current_level_metadata.icon_grid);
    var _palette = global.level_data[_level_index].palette_overrides;
    var _sprite_name = "spr_tiles_ep" + string(_episode)
        + "_" + string(_palette[0]) + "_" + string(_palette[1]) + "_" + string(_palette[2]);
    global.room_tiles_sprite = asset_get_index(_sprite_name);

    // Read the editor-owned layer into the original tile-ID grid. The current
    // GameMaker VM mis-renders this imported tileset directly, so the same
    // editable cells are drawn deterministically from the source atlas below.
    var _level_layer = layer_get_id("LevelTiles");
    if (_level_layer != -1) {
        var _level_map = layer_tilemap_get_id(_level_layer);
        if (_level_map != -1) {
            for (var _y = 0; _y < GRID_ROWS; _y++) {
                for (var _x = 0; _x < GRID_COLS; _x++) {
                    var _encoded = tile_get_index(tilemap_get(_level_map, _x, _y));
                    if (_encoded > 0) global.tile_grid[_y][_x] = _encoded - 1;
                }
            }
        }
        layer_set_visible(_level_layer, false);
    }
    var _background_layer = layer_get_id("BackgroundTiles");
    if (_background_layer != -1) layer_set_visible(_background_layer, false);

    for (var _position = 0; _position < 240; _position++) {
        var _override_key = string(_episode) + ":" + string(_level_index) + ":" + string(_position);
        if (struct_exists(global.tile_overrides, _override_key)) {
            level_set_tile(_position mod 20, _position div 20, global.tile_overrides[$ _override_key]);
        }
    }

    music_enter_room();
    var _boss_key = "boss_" + string(_episode) + "_" + string(_level_index);
    if (struct_exists(global.flags, _boss_key)) {
        with (obj_enemy) {
            if ((actor_type_id >= 22 && actor_type_id <= 25)
            || (actor_type_id >= 31 && actor_type_id <= 34)
            || (actor_type_id >= 64 && actor_type_id <= 67)) {
                instance_destroy();
            }
        }
    }

    // Loki introduces himself on the first visit to his arena. The original
    // stores this separately from the persistent defeated-boss flag.
    if (_episode == 3 && _level_index == 95
    && !struct_exists(global.flags, _boss_key)) {
        var _intro_key = "boss_intro_3_95";
        if (!struct_exists(global.flags, _intro_key)) {
            global.flags[$ _intro_key] = true;
            dialogue_start(1002, asset_get_index("spr_face_18"));
        }
    }

    global.last_room = room;

}

function level_room_asset(episode, level_index) {
    var _number = string(level_index);
    _number = string_repeat("0", max(0, 3 - string_length(_number))) + _number;
    return asset_get_index("rm_ep" + string(episode) + "_" + _number);
}

/// @description Draw the room editor tile cells with their palette-correct atlas
function level_draw_tiles() {
    if (global.tile_grid == undefined || global.room_tiles_sprite == -1) return;

    // Original GOT first fills every cell with the room background tile, then
    // draws its foreground icon with palette index zero transparent.
    var _background = global.current_level_metadata.bg_color + 1;
    for (var _bg_row = 0; _bg_row < GRID_ROWS; _bg_row++) {
        for (var _bg_column = 0; _bg_column < GRID_COLS; _bg_column++) {
            draw_sprite_part(global.room_tiles_sprite, 0,
                (_background mod 16) * TILE_W, (_background div 16) * TILE_H,
                TILE_W, TILE_H, _bg_column * TILE_W, _bg_row * TILE_H);
        }
    }

    for (var _row = 0; _row < GRID_ROWS; _row++) {
        for (var _column = 0; _column < GRID_COLS; _column++) {
            var _tile = global.tile_grid[_row][_column];
            if (_tile >= 0) {
                var _source_tile = _tile + 1;
                draw_sprite_part(global.room_tiles_sprite, 0,
                    (_source_tile mod 16) * TILE_W, (_source_tile div 16) * TILE_H,
                    TILE_W, TILE_H, _column * TILE_W, _row * TILE_H);
            }
        }
    }
}

/// @description Read an original tile ID from the editor-visible foreground
function tile_get(grid_x, grid_y) {
    if (grid_x < 0 || grid_x >= GRID_COLS) return -1;
    if (grid_y < 0 || grid_y >= GRID_ROWS) return -1;

    var _layer = layer_get_id("LevelTiles");
    if (_layer != -1) {
        var _tilemap = layer_tilemap_get_id(_layer);
        if (_tilemap != -1) {
            // GameMaker reserves tile zero; original tile N is stored as N+1.
            return tile_get_index(tilemap_get(_tilemap, grid_x, grid_y)) - 1;
        }
    }

    if (global.tile_grid == undefined) return -1;
    return global.tile_grid[grid_y][grid_x];
}

function tile_is_solid(tile_id) {
    return (tile_id >= 0 && tile_id < TILE_SOLID);
}

function tile_is_fly_only(tile_id) {
    return (tile_id >= TILE_SOLID && tile_id < TILE_FLY);
}

function tile_is_special(tile_id) {
    return (tile_id > TILE_SPECIAL);
}


/// @description Original special_tile rules used by enemies and NPCs.
function special_tile_enemy(tile_id, is_flying) {
    switch (tile_id) {
        case 205:
        case 206:
        case 207:
        case 208:
            return true;
        case 209:
        case 210:
            return false;
        case 224:
        case 225:
        case 226:
        case 227:
            return is_flying;
    }

    switch (global.current_episode) {
        case 1:
            if (tile_id >= 201 && tile_id <= 204) return false;
            if (tile_id >= 214 && tile_id <= 217) return false;
            break;
        case 2:
            if (tile_id >= 201 && tile_id <= 203) return false;
            if (tile_id == 204 || tile_id == 211) return true;
            if (tile_id >= 212 && tile_id <= 216) return false;
            break;
        case 3:
            if (tile_id >= 201 && tile_id <= 204) return false;
            if (tile_id == 211 || tile_id == 212) return false;
            break;
    }
    return true;
}
/// @function level_set_tile(grid_x, grid_y, original_tile)
/// @description Change an editor-owned foreground cell and its collision value
function level_set_tile(grid_x, grid_y, original_tile) {
    var _layer = layer_get_id("LevelTiles");
    if (_layer == -1) return;
    var _tilemap = layer_tilemap_get_id(_layer);
    if (_tilemap == -1) return;

    var _data = tilemap_get(_tilemap, grid_x, grid_y);
    _data = tile_set_index(_data, original_tile + 1);
    tilemap_set(_tilemap, _data, grid_x, grid_y);

    if (global.tile_grid != undefined) {
        global.tile_grid[grid_y][grid_x] = original_tile;
    }
}

/// @function special_tile_player(grid_x, grid_y, tile_id, proposed_x, proposed_y)
/// @description Episode-aware behavior for original tile IDs above 200
function special_tile_player(grid_x, grid_y, tile_id, proposed_x, proposed_y) {
    var _diagonal = global.player.input_diagonal;
    var _direction = global.player.facing;
    var _episode = global.current_episode;
    var _center_x = (proposed_x + 8) div TILE_W;
    var _center_y = (proposed_y + 10) div TILE_H;

    // Doors and directional gates are shared by all three episodes.
    switch (tile_id) {
        case 201:
            if (global.keys > 0) {
                global.keys--;
                level_set_tile(grid_x, grid_y, global.current_level_metadata.bg_color);
                audio_play_sound(snd_got_door, 3, false);
                return true;
            }
            return false;

        case 205: return (!_diagonal && _direction != Dir.DOWN);
        case 206: return (!_diagonal && _direction != Dir.UP);
        case 207: return (!_diagonal && _direction != Dir.RIGHT);
        case 208: return (!_diagonal && _direction != Dir.LEFT);

        case 209:
            if (global.jewels >= 10) {
                global.jewels -= 10;
                level_set_tile(grid_x, grid_y, global.current_level_metadata.bg_color);
                audio_play_sound(snd_got_door, 3, false);
                return true;
            }
            return false;

        case 210:
            if (global.jewels >= 100) {
                global.jewels -= 100;
                level_set_tile(grid_x, grid_y, global.current_level_metadata.bg_color);
                audio_play_sound(snd_got_door, 3, false);
                return true;
            }
            return false;
    }

    if (_episode == 1) {
        switch (tile_id) {
            case 202: // ending bridge
                if (proposed_x > 300) global.episode_complete = true;
                return true;
            case 203:
            case 204:
            case 212:
            case 213:
            case 214:
            case 215:
            case 216:
            case 217:
                return false;

            case 211:
                level_set_tile(grid_x, grid_y, 79);
                global.health = 0;
                return true;
        }
    } else if (_episode == 2) {
        switch (tile_id) {
            case 202:
                if (proposed_x > 300) global.episode_complete = true;
                return true;
            case 203:
                var _ep2_trigger = "ep2_object_tile";
                if (global.quest_object == 5) {
                    global.quest_object = 0;
                    global.flags[$ _ep2_trigger] = true;
                    dialogue_start(2012, spr_dialogue_odin);
                } else if (!struct_exists(global.flags, _ep2_trigger)) {
                    global.flags[$ _ep2_trigger] = true;
                    dialogue_start(2011, spr_dialogue_odin);
                }
                return true;
            case 204:
                return true;
            case 211:
                if (_direction == Dir.UP
                && struct_exists(global.flags, "29")
                && struct_exists(global.flags, "21")
                && !struct_exists(global.flags, "22")) {
                    with (obj_enemy) {
                        if (invisibility_group >= 1 && invisibility_group <= 5)
                            visible = true;
                    }
                    global.flags[$ "22"] = true;
                    global.thunder_timer = 60;
                    audio_play_sound(snd_got_thunder, 4, false);
                }
                return true;
            case 212:
            case 213:
            case 214:
            case 215:
            case 216:
                return false;

            case 217:
                if (_center_x != grid_x || _center_y != grid_y) return true;
                var _target_ep2 = global.current_level_metadata.level_jumps.target_location[3];
                global.player.x = (_target_ep2 mod GRID_COLS) * TILE_W;
                global.player.y = ((_target_ep2 div GRID_COLS) * TILE_H) - 2;
                global.player.invulnerable_timer = 60;
                audio_play_sound(snd_got_woop, 2, false);
                return false;
        }
    } else if (_episode == 3) {
        switch (tile_id) {
            case 202: // object-locked door
                if (global.quest_object == 4) {
                    global.quest_object = 0;
                    level_set_tile(grid_x, grid_y, global.current_level_metadata.bg_color);
                    audio_play_sound(snd_got_door, 3, false);
                    return true;
                }
                return false;

            case 203:
                var _ep3_trigger = "ep3_object_tile";
                if (global.quest_object == 5) {
                    global.quest_object = 0;
                    global.flags[$ _ep3_trigger] = true;
                    dialogue_start(2012, spr_dialogue_odin);
                } else if (!struct_exists(global.flags, _ep3_trigger)) {
                    global.flags[$ _ep3_trigger] = true;
                    dialogue_start(2011, spr_dialogue_odin);
                }
                return true;
            case 204:
                if (proposed_x < 4) global.episode_complete = true;
                return true;
            case 211:
            case 212:
            case 213:
                return false;

            case 214:
            case 215:
            case 216:
            case 217:
                if (_center_x != grid_x || _center_y != grid_y) return true;
                var _target_ep3 = global.current_level_metadata.level_jumps.target_location[tile_id - 214];
                global.player.x = (_target_ep3 mod GRID_COLS) * TILE_W;
                global.player.y = ((_target_ep3 div GRID_COLS) * TILE_H) - 2;
                global.player.invulnerable_timer = 60;
                audio_play_sound(snd_got_woop, 2, false);
                return false;
        }
    }

    if (tile_id >= 218 && tile_id <= 229) {
        if (_center_x != grid_x || _center_y != grid_y) return true;

        var _jump_index = tile_id - 220;
        if (tile_id == 218 || tile_id == 219) _jump_index += 6;
        if (_jump_index < 0 || _jump_index >= 10) return false;

        var _target_level = global.current_level_metadata.level_jumps.target_level[_jump_index];
        var _target_location = global.current_level_metadata.level_jumps.target_location[_jump_index];
        var _scroll_warp = (_target_level > 119);
        if (_scroll_warp) _target_level -= 128;

        global.player.invulnerable_timer = 60;
        if (tile_id >= 220 && tile_id <= 223) audio_play_sound(snd_got_fall, 1, false);

        if (_scroll_warp) {
            switch (_direction) {
                case Dir.UP: global.player.y = 175; break;
                case Dir.DOWN: global.player.y = 0; break;
                case Dir.LEFT: global.player.x = 304; break;
                case Dir.RIGHT: global.player.x = 0; break;
            }
        } else {
            global.player.x = (_target_location mod GRID_COLS) * TILE_W;
            global.player.y = ((_target_location div GRID_COLS) * TILE_H) - 2;
        }

        var _target_room = level_room_asset(global.current_episode, _target_level);
        if (_target_room != -1) room_goto(_target_room);
        return false;
    }

    return false;
}

/// @description Kill actors/Thor standing on a tile that becomes solid.
function level_switch_kill_tile(grid_x, grid_y) {
    var _left = grid_x * TILE_W;
    var _top = grid_y * TILE_H;
    var _right = _left + TILE_W - 1;
    var _bottom = _top + TILE_H - 1;

    with (obj_enemy) {
        if (visible && bbox_right >= _left && bbox_left <= _right
        && bbox_bottom >= _top && bbox_top <= _bottom) {
            is_dead = true;
            instance_destroy();
        }
    }
    if (global.player != noone && instance_exists(global.player)
    && global.player.bbox_right >= _left && global.player.bbox_left <= _right
    && global.player.bbox_bottom >= _top && global.player.bbox_top <= _bottom) {
        global.health = 0;
    }
}

/// @description Original switch_icons transformation (special function 4).
function level_toggle_switch_icons() {
    audio_play_sound(snd_got_woop, 3, false);
    for (var _y = 0; _y < GRID_ROWS; _y++) {
        for (var _x = 0; _x < GRID_COLS; _x++) {
            var _tile = tile_get(_x, _y);
            switch (_tile) {
                case 93:  level_set_tile(_x, _y, 144); break;
                case 144: level_set_tile(_x, _y, 93); level_switch_kill_tile(_x, _y); break;
                case 94:  level_set_tile(_x, _y, 146); break;
                case 146: level_set_tile(_x, _y, 94); level_switch_kill_tile(_x, _y); break;
            }
        }
    }
}

/// @description Original rotate_arrows transformation (special function 7).
function level_rotate_arrows() {
    audio_play_sound(snd_got_woop, 3, false);
    for (var _y = 0; _y < GRID_ROWS; _y++) {
        for (var _x = 0; _x < GRID_COLS; _x++) {
            var _tile = tile_get(_x, _y);
            switch (_tile) {
                case 205: level_set_tile(_x, _y, 208); break;
                case 206: level_set_tile(_x, _y, 207); break;
                case 207: level_set_tile(_x, _y, 205); break;
                case 208: level_set_tile(_x, _y, 206); break;
            }
        }
    }
}
