/// @description Combat, damage, death, and checkpoint restoration

function checkpoint_save() {
    if (global.player == noone || !instance_exists(global.player)) return;
    global.checkpoint = {
        episode: global.current_episode,
        level: global.current_level,
        x: global.player.x,
        y: global.player.y,
        facing: global.player.facing,
        health: global.health,
        magic: global.magic,
        jewels: global.jewels,
        keys: global.keys,
        score: global.score,
        selected_item: global.selected_item,
        quest_object: global.quest_object,
        inventory_json: json_stringify(global.inventory),
        flags_json: json_stringify(global.flags),
        collected_pickups_json: json_stringify(global.collected_pickups),
        tile_overrides_json: json_stringify(global.tile_overrides),
        armor_level: global.armor_level,
        hammer_damage: global.hammer_damage,
    };
}

function checkpoint_restore() {
    var _save = global.checkpoint;

    if (global.hammer != noone && instance_exists(global.hammer)) instance_destroy(global.hammer);
    global.hammer = noone;
    with (obj_enemy_shot) instance_destroy();

    global.health = _save.health;
    global.magic = _save.magic;
    global.jewels = _save.jewels;
    global.keys = _save.keys;
    global.score = _save.score;
    global.selected_item = _save.selected_item;
    global.quest_object = _save.quest_object;
    global.inventory = json_parse(_save.inventory_json);
    if (variable_struct_exists(_save, "flags_json"))
        global.flags = json_parse(_save.flags_json);
    if (variable_struct_exists(_save, "collected_pickups_json"))
        global.collected_pickups = json_parse(_save.collected_pickups_json);
    if (variable_struct_exists(_save, "tile_overrides_json"))
        global.tile_overrides = json_parse(_save.tile_overrides_json);
    global.armor_level = variable_struct_exists(_save, "armor_level")
        ? _save.armor_level : ((_save.episode == 1) ? 0 : _save.episode - 1);
    global.hammer_damage = variable_struct_exists(_save, "hammer_damage")
        ? _save.hammer_damage : ((_save.episode == 1) ? 10 : ((_save.episode == 2) ? 13 : 17));
    global.current_episode = _save.episode;
    global.current_level = _save.level;
    global.death_active = false;
    global.death_timer = 0;

    if (global.player != noone && instance_exists(global.player)) {
        global.player.x = _save.x;
        global.player.y = _save.y;
        global.player.facing = _save.facing;
        global.player.invulnerable_timer = 60;
    }

    var _target = level_room_asset(_save.episode, _save.level);
    if (_target != -1) room_goto(_target);
}

function combat_spawn_death_effect(enemy_inst) {
    if (!instance_exists(enemy_inst) || enemy_inst.actor_def == undefined) return;
    var _effect_type = (enemy_inst.actor_def.func_num == 255) ? 107 : 106;
    var _effect = actor_spawn(_effect_type, enemy_inst.x, enemy_inst.y, 0, Dir.UP);
    if (_effect == noone) return;
    _effect.is_magic_effect = true;
    _effect.solid_type |= 128;
    _effect.strength = 0;
    _effect.actor_slot = -1;
    _effect.effect_timer = 4;
    _effect.death_source_def = enemy_inst.actor_def;
    _effect.death_source_w = enemy_inst.col_w;
    _effect.death_source_h = enemy_inst.col_h;
}

function combat_spawn_boss_explosion(px, py, frame) {
    var _effect = actor_spawn(107, px, py, 0, Dir.UP);
    if (_effect == noone) return;
    _effect.is_magic_effect = true;
    _effect.is_boss_explosion = true;
    _effect.solid_type |= 128;
    _effect.strength = 0;
    _effect.actor_slot = -1;
    _effect.current_frame = frame mod 3;
    _effect.move_delay = irandom_range(6, 8);
    _effect.effect_timer = (10 - _effect.move_delay) * 10;
}

function combat_spawn_collapse_explosion(tile_position) {
    var _effect = actor_spawn(
        107,
        (tile_position mod GRID_COLS) * TILE_W,
        (tile_position div GRID_COLS) * TILE_H,
        0,
        Dir.UP
    );
    if (_effect == noone) return;
    _effect.is_magic_effect = true;
    _effect.solid_type |= 128;
    _effect.strength = 0;
    _effect.actor_slot = -1;
    _effect.effect_timer = 6;
}

function combat_player_hit(damage) {
    if (global.player == noone) return;
    if (global.player.invulnerable_timer > 0 || global.health <= 0) return;
    if (global.shield_on) return;
    if (damage != 255 && global.difficulty == 0) damage = damage div 2;
    else if (damage != 255 && global.difficulty == 2) damage *= 2;

    // Episodes 2 and 3 start with the silver and golden armor awarded by the
    // previous chapter. Their original executables reduce ordinary damage by
    // one quarter and one third respectively.
    if (damage < 150) {
        if (global.armor_level == 1) damage -= damage div 4;
        else if (global.armor_level >= 2) damage -= damage div 3;
    }


    audio_play_sound(snd_got_ow, 2, false);
    global.health = max(0, global.health - damage);
    global.player.invulnerable_timer = 40;
}


/// @description Run non-damage actor callbacks from the original func_num table.
function actor_trigger_special(actor_inst, from_hammer) {
    if (!instance_exists(actor_inst)
    || actor_inst.actor_def == undefined
    || !actor_inst.visible) return false;

    var _func = actor_inst.actor_def.func_num;
    if (_func == 3) {
        if (!from_hammer && !actor_inst.dialogue_contact_latched
        && actor_inst.dialogue_cooldown <= 0) {
            if (dialogue_start(
                global.current_level * 1000 + actor_inst.actor_slot,
                spr_dialogue_odin
            )) {
                actor_inst.dialogue_contact_latched = true;
                global.dialogue.speaker = actor_inst;
            }
        }
        return true;
    }
    if (_func == 4) {
        if (actor_inst.vulnerable_timer <= 0) {
            actor_inst.vulnerable_timer = 30;
            level_toggle_switch_icons();
        }
        return true;
    }
    if (_func == 7) {
        if (actor_inst.vulnerable_timer <= 0) {
            actor_inst.vulnerable_timer = 30;
            level_rotate_arrows();
        }
        return true;
    }
    if (_func == 10 && !from_hammer) {
        if (!actor_inst.dialogue_contact_latched && actor_inst.dialogue_cooldown <= 0
        && dialogue_start_actor(actor_inst)) {
            actor_inst.dialogue_contact_latched = true;
        }
        return true;
    }
    if (_func == 11 && !from_hammer) {
        if (!actor_inst.dialogue_contact_latched && actor_inst.dialogue_cooldown <= 0
        && dialogue_start_actor(actor_inst)) {
            actor_inst.dialogue_contact_latched = true;
        }
        return true;
    }
    return false;
}

function combat_enemy_hit(enemy_inst, damage) {
    if (!instance_exists(enemy_inst) || enemy_inst.is_magic_effect) return;
    if (actor_trigger_special(enemy_inst, true)) return;
    if (combat_boss_hit(enemy_inst, damage)) return;
    if (enemy_inst.solid_type == 2) {
        enemy_inst.vulnerable_timer = 10;
        return;
    }
    var _scaled_damage = damage;
    if (global.difficulty == 0) _scaled_damage *= 2;
    else if (global.difficulty == 2) _scaled_damage = _scaled_damage div 2;

    if (enemy_inst.vulnerable_timer > 0 || enemy_inst.is_dead) return;

    // Older placed actor children can reach combat without a local health
    // variable. Restore it from the original actor definition on first hit.
    if (!variable_instance_exists(enemy_inst, "health")) {
        var _starting_health = 10;
        if (variable_instance_exists(enemy_inst, "actor_def")
        && is_struct(enemy_inst.actor_def)
        && variable_struct_exists(enemy_inst.actor_def, "health")) {
            _starting_health = enemy_inst.actor_def.health;
        }
        enemy_inst.health = _starting_health;
    }

    audio_play_sound(snd_got_punch, 1, false);
    enemy_inst.health -= _scaled_damage;
    enemy_inst.vulnerable_timer = 20;
    if (enemy_inst.health <= 0) {
        enemy_inst.is_dead = true;
        var _good_guy = enemy_inst.actor_def != undefined
            && enemy_inst.actor_def.type == 4;
        if (_good_guy) {
            // kill_good_guy() in 1_MOVE.C deducts 1000 points and shows Odin's
            // episode-specific 2010 reproach only for the first such killing.
            global.score = max(0, global.score - 1000);
            if (!global.kill_good_guy_informed && global.thunder_timer <= 0) {
                global.kill_good_guy_informed = true;
                dialogue_start(2010, spr_dialogue_odin);
            }
        } else if (enemy_inst.actor_def != undefined) {
            global.score = min(global.score + enemy_inst.actor_def.rating, MAX_SCORE);
        }
        combat_spawn_death_effect(enemy_inst);
        with (enemy_inst) instance_destroy();
    }
}

function combat_reward_episode(episode) {
    global.score = min(
        MAX_SCORE,
        global.score + 20000 + (global.health + global.magic + global.jewels) * 10
    );
    global.health = MAX_HEALTH;
    global.magic = MAX_MAGIC;
    global.jewels = 0;

    if (episode == 1) {
        global.armor_level = 1;
        global.hammer_damage = 13;
    } else if (episode == 2) {
        global.armor_level = 2;
        global.hammer_damage = 17;
    }
}

function combat_begin_boss_closing() {
    var _episode = global.current_episode;
    var _level = global.current_level;
    global.post_boss_episode = _episode;
    global.post_boss_stage = 1;
    music_play_victory();

    if (_episode == 1 && _level == 59) {
        dialogue_place_tile(59, 138, 148);
        dialogue_place_tile(59, 139, 202);
        dialogue_start(1001, spr_dialogue_odin);
    } else if (_episode == 2 && _level == 60) {
        dialogue_place_tile(60, 218, 152);
        dialogue_place_tile(60, 219, 202);
        dialogue_start(1001, spr_dialogue_odin);
    } else if (_episode == 3 && _level == 95) {
        dialogue_start(1001, spr_dialogue_odin);
    } else {
        global.post_boss_stage = 0;
    }
}

function combat_update_progression() {
    if (global.boss_death_active) {
        var _explosions_alive = false;
        for (var _death_i = 0; _death_i < instance_number(obj_enemy); _death_i++) {
            var _death_actor = instance_find(obj_enemy, _death_i);
            if (_death_actor != noone && _death_actor.is_boss_explosion) {
                _explosions_alive = true;
                break;
            }
        }
        if (!_explosions_alive) {
            global.boss_death_active = false;
            combat_begin_boss_closing();
        }
    }

    if (global.post_boss_stage == 1 && !global.dialogue.active) {
        var _episode = global.post_boss_episode;
        combat_reward_episode(_episode);
        if (_episode <= 2) {
            global.post_boss_stage = 2;
            dialogue_start(1002, spr_dialogue_odin);
        } else {
            global.post_boss_stage = 0;
            global.endgame_active = true;
            global.endgame_timer = 0;
            global.endgame_tile_index = 0;
            global.endgame_row = 0;
            global.endgame_phase = 0;
            global.endgame_tiles = [
                126,127,128,129,130,131,132,133,
                146,147,148,149,150,151,152,153,
                166,167,168,169,170,171,172,173,
                186,187,188,189,190,191,192,193
            ];
            if (global.player != noone && instance_exists(global.player)) {
                global.player.x = 152;
                global.player.y = 160;
            }
            var _ending_room = level_room_asset(3, 106);
            if (_ending_room != -1) room_goto(_ending_room);
        }
    } else if (global.post_boss_stage == 2 && !global.dialogue.active) {
        global.post_boss_stage = 0;
    }

    if (global.endgame_active && global.current_episode == 3
    && global.current_level == 106) {
        global.endgame_timer++;
        if (global.endgame_timer >= 6
        && global.endgame_tile_index < array_length(global.endgame_tiles)) {
            global.endgame_timer = 0;
            var _row_start = (global.endgame_phase == 0)
                ? global.endgame_row * 8 : 0;
            var _row_end = (global.endgame_phase == 0)
                ? _row_start + 7 : array_length(global.endgame_tiles) - 1;
            var _pick = irandom_range(global.endgame_tile_index, _row_end);
            var _position = global.endgame_tiles[_pick];
            global.endgame_tiles[_pick] = global.endgame_tiles[global.endgame_tile_index];
            global.endgame_tiles[global.endgame_tile_index] = _position;
            global.endgame_tile_index++;
            level_set_tile(
                _position mod GRID_COLS,
                _position div GRID_COLS,
                global.current_level_metadata.bg_color
            );
            if (global.endgame_phase == 0) {
                level_set_tile(
                    (_position - 80) mod GRID_COLS,
                    (_position - 80) div GRID_COLS,
                    global.current_level_metadata.bg_color
                );
            }
            combat_spawn_collapse_explosion(_position);
            audio_play_sound(snd_got_explode, 3, false);

            if (global.endgame_phase == 0
            && global.endgame_tile_index >= (global.endgame_row + 1) * 8) {
                // ENDGAME.C copies the five 8-tile bands down one tile after
                // every row of explosions, producing the room collapse.
                for (var _shift_y = 6 + global.endgame_row;
                _shift_y >= 2 + global.endgame_row; _shift_y--) {
                    for (var _shift_x = 6; _shift_x <= 13; _shift_x++) {
                        level_set_tile(
                            _shift_x,
                            _shift_y,
                            tile_get(_shift_x, _shift_y - 1)
                        );
                    }
                }
                global.endgame_row++;
                if (global.endgame_row >= 4) {
                    global.endgame_phase = 1;
                    global.endgame_tile_index = 0;
                    global.endgame_tiles = [
                        126,127,128,129,130,131,132,133,
                        146,147,148,149,150,151,152,153,
                        166,167,168,169,170,171,172,173,
                        186,187,188,189,190,191,192,193
                    ];
                }
            }
        }
    }

    if (global.episode_complete) {
        global.episode_complete = false;
        global.endgame_active = false;
        magic_destroy_tornado();
        menu_show_ending(global.current_episode);
    }
}

function combat_drop_loot_definition(actor_definition, drop_x, drop_y, drop_w, drop_h) {
    if (actor_definition == undefined || actor_definition.type != 2) return;
    var _gx = (drop_x + drop_w * 0.5) div TILE_W;
    var _gy = (drop_y + drop_h * 0.5) div TILE_H;
    if (_gx < 0 || _gx >= GRID_COLS || _gy < 0 || _gy >= GRID_ROWS
    || tile_get(_gx, _gy) < TILE_FLY) return;

    var _px = _gx * TILE_W;
    var _py = _gy * TILE_H;
    for (var _i = 0; _i < instance_number(obj_pickup); _i++) {
        var _pickup = instance_find(obj_pickup, _i);
        if (_pickup != noone && round(_pickup.x) == _px && round(_pickup.y) == _py) return;
    }

    var _roll = irandom(99);
    var _rare = irandom(99);
    var _type;
    if (_roll < 25) _type = 5;
    else if ((_roll & 1) != 0) _type = (_rare < 10) ? 1 : 2;
    else _type = (_rare < 10) ? 3 : 4;
    pickup_spawn(_type, _px, _py);
}

function combat_drop_loot(enemy_inst) {
    if (!instance_exists(enemy_inst)) return;
    combat_drop_loot_definition(
        enemy_inst.actor_def, enemy_inst.x, enemy_inst.y,
        enemy_inst.col_w, enemy_inst.col_h
    );
}

function combat_boss_hit(enemy_inst, damage) {
    if (!instance_exists(enemy_inst)) return false;
    var _type = enemy_inst.actor_type_id;
    var _snake = (_type >= 22 && _type <= 25);
    var _skull = (_type >= 31 && _type <= 34);
    var _loki = (_type >= 64 && _type <= 67);
    if (!_snake && !_skull && !_loki) return false;

    // The serpent's vulnerable spot is its upper-right quadrant.
    if (_snake && _type != 23) return true;
    var _leader = movement_actor_slot(3);
    if (_leader == noone || _leader.vulnerable_timer > 0 || _leader.is_dead
    || _leader.boss_invulnerable) return true;

    _leader.health -= 10;
    if (_skull && _leader.health == 50) {
        _leader.boss_state = 1;
        _leader.boss_counter = 0;
        _leader.boss_timer = 1;
        _leader.boss_invulnerable = true;
        _leader.num_moves = 1;
        with (obj_enemy_shot) instance_destroy();
        audio_play_sound(snd_got_explode, 4, false);
    } else if (_loki && _leader.health == 50) {
        _leader.boss_state = 1;
        _leader.boss_counter = 0;
        _leader.boss_timer = 1;
        _leader.boss_invulnerable = true;
        with (obj_enemy_shot) instance_destroy();
        dialogue_start(1003, asset_get_index("spr_face_18"));
    }
    for (var _i = 0; _i < instance_number(obj_enemy); _i++) {
        var _part = instance_find(obj_enemy, _i);
        if (_part == noone) continue;
        var _part_type = _part.actor_type_id;
        if ((_snake && _part_type >= 22 && _part_type <= 25)
        || (_skull && _part_type >= 31 && _part_type <= 34)
        || (_loki && _part_type >= 64 && _part_type <= 67)) {
            _part.vulnerable_timer = 75;
        }
    }
    audio_play_sound(snd_got_clang, 3, false);
    if (_leader.health > 0) return true;

    global.flags[$ "boss_" + string(global.current_episode) + "_" + string(global.current_level)] = true;
    audio_play_sound(snd_got_explode, 5, false);
    global.boss_death_active = true;
    with (obj_enemy_shot) instance_destroy();
    for (var _j = instance_number(obj_enemy) - 1; _j >= 0; _j--) {
        var _victim = instance_find(obj_enemy, _j);
        if (_victim == noone) continue;
        var _victim_type = _victim.actor_type_id;
        if ((_snake && _victim_type >= 22 && _victim_type <= 25)
        || (_skull && _victim_type >= 31 && _victim_type <= 34)
        || (_loki && _victim_type >= 64 && _victim_type <= 67)) {
            _victim.is_dead = true;
            combat_spawn_boss_explosion(_victim.x, _victim.y, _victim.actor_slot - 3);
            instance_destroy(_victim);
        }
    }
    return true;
}
