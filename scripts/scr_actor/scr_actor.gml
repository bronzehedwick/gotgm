/// @description Actor spawning and management

/// @function actor_spawn(actor_type, spawn_x, spawn_y, value, dir)
/// @description Spawn an enemy actor from its type definition
function actor_spawn(actor_type, spawn_x, spawn_y, value, dir) {
    // Load actor definition
    var _def = actor_get_definition(actor_type);
    if (_def == undefined) return noone;

    var _inst = instance_create_layer(spawn_x, spawn_y, "Instances", obj_enemy);

    with (_inst) {
        actor_type_id = actor_type;
        actor_def = _def;

        // Copy stats from definition
        move_pattern = _def.move;
        health = _def.health;
        strength = _def.strength;
        speed = _def.speed;
        num_moves = _def.num_moves;
        solid_type = _def.solid;
        is_flying = (_def.flying > 0);

        // Collision box
        col_w = _def.size_x;
        col_h = _def.size_y;

        // Animation
        directions = _def.directions;
        anim_frames = _def.frames;
        frame_speed = _def.frame_speed;
        frame_sequence = _def.frame_sequence;

        // State
        facing = dir;
        pass_value = value;
        speed_count = 0;
        frame_count = 0;
        current_frame = 0;
        vulnerable_timer = 0;
        is_dead = false;
    }

    return _inst;
}

/// @function actor_get_definition(actor_type)
/// @description Load an actor definition from JSON data
function actor_get_definition(actor_type) {
    // Cache definitions
    if (!variable_global_exists("actor_defs")) {
        global.actor_defs = {};
    }

    var _key = string(actor_type);
    if (struct_exists(global.actor_defs, _key)) {
        return global.actor_defs[$ _key];
    }

    // Load from file
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

/// @function pickup_spawn(obj_type, px, py)
/// @description Spawn a static object/pickup
function pickup_spawn(obj_type, px, py) {
    var _inst = instance_create_layer(px, py, "Instances", obj_pickup);
    with (_inst) {
        pickup_type = obj_type;
        // Object types: 1-4=jewels, 5=apple, 6=potion, 7=key, etc.
    }
    return _inst;
}
