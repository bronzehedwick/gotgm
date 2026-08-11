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

    audio_play_sound(snd_got_ow, 2, false);
    global.health = max(0, global.health - damage);
    global.player.invulnerable_timer = 60;
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
    return false;
}

function combat_enemy_hit(enemy_inst, damage) {
    if (actor_trigger_special(enemy_inst, true)) return;
    if (enemy_inst.solid_type == 2) {
        enemy_inst.vulnerable_timer = 10;
        return;
    }
    with (enemy_inst) {
        if (vulnerable_timer > 0 || is_dead) return;

        audio_play_sound(snd_got_punch, 1, false);
        health -= damage;
        vulnerable_timer = 10;

        if (health <= 0) {
            is_dead = true;
            if (variable_instance_exists(id, "actor_def") && actor_def != undefined) {
                global.score = min(global.score + actor_def.rating, MAX_SCORE);
            }
            instance_destroy();
        }
    }
}
