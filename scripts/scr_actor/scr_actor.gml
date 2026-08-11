/// @description Actor spawning and management

function actor_spawn(actor_type, spawn_x, spawn_y, value, dir) {
    var _def = actor_get_definition(actor_type);
    if (_def == undefined) return noone;

    var _inst = instance_create_layer(spawn_x, spawn_y, "Actors", obj_enemy);
    actor_configure(_inst, actor_type, value, dir, false);
    return _inst;
}

function actor_configure(inst, actor_type, value, dir, invisible, source_slot = -1) {
    var _def = actor_get_definition(actor_type);
    if (_def == undefined || !instance_exists(inst)) return noone;

    with (inst) {
        actor_type_id = actor_type;
        actor_def = _def;
        move_pattern = _def.move;
        health = _def.health;
        strength = _def.strength;
        move_delay = max(1, _def.speed);
        num_moves = max(1, _def.num_moves);
        solid_type = _def.solid;
        is_flying = (_def.flying > 0);
        col_w = max(1, _def.size_x);
        col_h = max(1, _def.size_y);
        directions = max(1, _def.directions);
        anim_frames = max(1, _def.frames);
        frame_speed = max(1, _def.frame_speed);
        frame_sequence = _def.frame_sequence;
        facing = clamp(dir, Dir.UP, Dir.RIGHT);
        pass_value = value;
        actor_slot = source_slot;
        invisibility_group = real(invisible);
        dialogue_cooldown = 0;
        special_cooldown = 0;
        shot_type = _def.shot_type;
        shot_pattern = _def.shot_pattern;
        shots_allowed = _def.shots_allowed;
        shot_cooldown = irandom_range(1, 20);
        shot_random_timer = max(0, _def.func_pass);
        speed_count = 0;
        frame_count = 0;
        current_frame = 0;
        movement_tick = false;
        vulnerable_timer = 0;
        is_dead = false;
        pause_timer = 0;
        move_counter = 0;
        axis_toggle = false;
        ai_timer = irandom_range(50, 149);
        ai_seek = false;
        boss_state = 0;
        boss_timer = 0;
        spear_timer = 0;
        spear_phase = 0;
        fish_pause = 0;
        trap_falling = false;
        dart_initialized = false;
        dart_timer = 0;
        dart_origin_x = x;
        dart_origin_y = y;
        dart_initial_dir = facing;
        dart_return_dir = facing;
        dart_state = 0;
        effect_timer = max(1, _def.frames * _def.frame_speed);
        visible = (real(invisible) <= 0);
        image_index = (directions > 1) ? facing * anim_frames : 0;
        image_speed = 0;
    }
    return inst;
}

function actor_get_definition(actor_type) {
    if (!variable_global_exists("actor_defs")) global.actor_defs = {};

    var _key = string(actor_type);
    if (struct_exists(global.actor_defs, _key)) return global.actor_defs[$ _key];

    var _path = "data/actors/actor" + _key + ".json";
    var _buf = buffer_load(_path);
    if (_buf == -1) {
        show_debug_message("WARNING: Actor definition not found: " + _path);
        return undefined;
    }
    var _str = buffer_read(_buf, buffer_string);
    buffer_delete(_buf);
    var _data = json_parse(_str);
    var _info = _data.actor_info;
    global.actor_defs[$ _key] = _info;
    return _info;
}

function pickup_spawn(obj_type, px, py) {
    var _inst = instance_create_layer(px, py, "Pickups", obj_pickup);
    with (_inst) pickup_type = obj_type;
    return _inst;
}
