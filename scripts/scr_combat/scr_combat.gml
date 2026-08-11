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
    };
}

function checkpoint_restore() {
    var _save = global.checkpoint;
    audio_play_sound(snd_got_dead, 5, false);

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
    global.current_episode = _save.episode;
    global.current_level = _save.level;

    if (global.player != noone && instance_exists(global.player)) {
        global.player.x = _save.x;
        global.player.y = _save.y;
        global.player.facing = _save.facing;
        global.player.invulnerable_timer = 60;
    }

    var _target = level_room_asset(_save.episode, _save.level);
    if (_target != -1) room_goto(_target);
}

function combat_player_hit(damage) {
    if (global.player == noone) return;
    if (global.player.invulnerable_timer > 0 || global.health <= 0) return;
    if (global.shield_on) return;
    if (damage != 255 && global.difficulty == 0) damage = damage div 2;
    else if (damage != 255 && global.difficulty == 2) damage *= 2;


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

    audio_play_sound(snd_got_punch, 1, false);
    enemy_inst.health -= _scaled_damage;
    enemy_inst.vulnerable_timer = 20;
    if (enemy_inst.health <= 0) {
        enemy_inst.is_dead = true;
        if (enemy_inst.actor_def != undefined) {
            global.score = min(global.score + enemy_inst.actor_def.rating, MAX_SCORE);
        }
        combat_drop_loot(enemy_inst);
        with (enemy_inst) instance_destroy();
    }
}

function combat_drop_loot(enemy_inst) {
    if (!instance_exists(enemy_inst) || enemy_inst.actor_def == undefined
    || enemy_inst.actor_def.type != 2) return;
    var _gx = (enemy_inst.x + enemy_inst.col_w * 0.5) div TILE_W;
    var _gy = (enemy_inst.y + enemy_inst.col_h * 0.5) div TILE_H;
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
    if (_leader == noone || _leader.vulnerable_timer > 0 || _leader.is_dead) return true;

    _leader.health -= 10;
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
    global.score = min(MAX_SCORE, global.score + 10000);
    audio_play_sound(snd_got_explode, 5, false);
    if (_snake && global.current_episode == 1 && global.current_level == 59) {
        dialogue_place_tile(59, 138, 148);
        dialogue_place_tile(59, 139, 202);
    }
    for (var _j = instance_number(obj_enemy) - 1; _j >= 0; _j--) {
        var _victim = instance_find(obj_enemy, _j);
        if (_victim == noone) continue;
        var _victim_type = _victim.actor_type_id;
        if ((_snake && _victim_type >= 22 && _victim_type <= 25)
        || (_skull && _victim_type >= 31 && _victim_type <= 34)
        || (_loki && _victim_type >= 64 && _victim_type <= 67)) {
            _victim.is_dead = true;
            instance_destroy(_victim);
        }
    }
    return true;
}
