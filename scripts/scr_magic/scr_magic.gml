/// @description Original inventory selection and magic-item behavior

function magic_item_owned(item_number) {
    return struct_exists(global.inventory, "item_" + string(item_number));
}

function magic_select_next() {
    var _start = global.selected_item;
    if (_start < 1 || _start > 6) _start = 0;
    for (var _offset = 1; _offset <= 6; _offset++) {
        var _candidate = ((_start + _offset - 1) mod 6) + 1;
        if (magic_item_owned(_candidate)) {
            global.selected_item = _candidate;
            return;
        }
    }
}

function magic_area_damage(radius, damage) {
    if (global.player == noone || !instance_exists(global.player)) return;
    var _cx = global.player.x + 7;
    var _cy = global.player.y + 7;
    with (obj_enemy) {
        var _ex = x + col_w * 0.5;
        var _ey = y + col_h * 0.5;
        if (abs(_ex - _cx) < radius && abs(_ey - _cy) < radius) {
            vulnerable_timer = 0;
            combat_enemy_hit(id, damage);
        }
    }
}

function magic_destroy_tornado() {
    if (global.tornado_instance != noone && instance_exists(global.tornado_instance)) {
        with (global.tornado_instance) instance_destroy();
    }
    global.tornado_instance = noone;
    global.tornado_timer = 0;
}

function magic_spawn_tornado() {
    magic_destroy_tornado();
    var _tornado = actor_spawn(
        108, global.player.x, global.player.y, 0, global.player.facing
    );
    if (_tornado == noone) return false;
    _tornado.sprite_index = spr_actor_108_tornado;
    _tornado.move_pattern = 16;
    _tornado.actor_slot = 2;
    _tornado.is_magic_effect = true;
    _tornado.is_tornado = true;
    _tornado.is_flying = true;
    _tornado.solid_type |= 128;
    _tornado.strength = 20;
    _tornado.image_speed = 0;
    global.tornado_instance = _tornado;
    global.tornado_timer = 1;
    return true;
}

function magic_tornado_damage(tornado) {
    if (!instance_exists(tornado)) return;
    var _x1 = tornado.x;
    var _y1 = tornado.y;
    var _x2 = _x1 + tornado.col_w - 1;
    var _y2 = _y1 + tornado.col_h - 1;
    for (var _i = 0; _i < instance_number(obj_enemy); _i++) {
        var _target = instance_find(obj_enemy, _i);
        if (_target == noone || _target.id == tornado.id || _target.is_magic_effect
        || !_target.visible || _target.is_dead) continue;
        if (_x1 <= _target.x + _target.col_w - 1 && _x2 >= _target.x
        && _y1 <= _target.y + _target.col_h - 1 && _y2 >= _target.y) {
            combat_enemy_hit(_target, tornado.strength);
        }
    }
}

/// The DOS main loop counts thunder from 60 down and damages source actor
/// slots 15 through 3 one at a time. This preserves its staggered hits and
/// avoids the port''s former all-at-once damage burst.
function magic_update_effects() {
    if (global.lightning_timer > 0) global.lightning_timer--;
    if (global.thunder_timer > 0) {
        global.thunder_timer--;
        if (global.thunder_timer < MAX_ACTORS && global.thunder_timer > 2) {
            var _target = movement_actor_slot(global.thunder_timer);
            if (_target != noone && !_target.is_magic_effect) {
                _target.vulnerable_timer = 0;
                combat_enemy_hit(_target, 20);
            }
        }
    }
}

function magic_update(is_down, just_pressed) {
    if (global.player == noone || !instance_exists(global.player)) return;

    global.player.move_speed = 2;
    if (!is_down) {
        global.magic_use_timer = 0;
        global.tornado_charge = 0;
        global.shield_on = false;
        magic_destroy_tornado();
        return;
    }

    global.magic_use_timer++;
    var _pulse = just_pressed || global.magic_use_timer > 9;
    if (_pulse) global.magic_use_timer = 1;

    switch (global.selected_item) {
        case 1: // healing apple: 2 magic per health point
            if (_pulse && global.health < MAX_HEALTH && global.magic >= 2) {
                global.magic -= 2;
                global.health++;
                audio_play_sound(snd_got_angel, 1, false);
            }
            break;

        case 2: // lightning: ten six-count flashes, repeatable while held
            global.tornado_charge = 0;
            if (global.lightning_timer <= 0 && global.magic >= 15) {
                global.magic -= 15;
                audio_play_sound(snd_got_electric, 4, false);
                global.lightning_timer = 60;
                magic_area_damage(30, 254);
            }
            break;

        case 3: // speed boots: held, drains one magic every nine counts
            global.tornado_charge = 0;
            if (global.magic > 0) {
                global.player.move_speed = 4;
                if (_pulse) global.magic--;
            }
            break;

        case 4: // tornado: the DOS game charges for twenty counts first
            global.tornado_charge++;
            if ((global.tornado_instance == noone
            || !instance_exists(global.tornado_instance))
            && global.tornado_charge > 20 && global.magic > 10) {
                global.magic -= 10;
                if (magic_spawn_tornado())
                    audio_play_sound(snd_got_wind, 2, false);
            } else if (global.tornado_instance != noone
            && instance_exists(global.tornado_instance) && _pulse && global.magic > 0) {
                global.magic--;
            }
            if (global.tornado_instance == noone || !instance_exists(global.tornado_instance))
                global.tornado_timer = 0;
            break;

        case 5: // shield: held, drains one magic every nine counts
            global.tornado_charge = 0;
            if (global.magic > 0) {
                global.shield_on = true;
                if (_pulse) global.magic--;
            }
            break;

        case 6: // thunder: 30 magic, one source-timed 60-count burst
            global.tornado_charge = 0;
            if (just_pressed && global.magic > 29 && global.thunder_timer <= 0) {
                global.magic -= 30;
                global.thunder_timer = 60;
                audio_play_sound(snd_got_thunder, 4, false);
            }
            break;
    }

    if (global.magic <= 0) {
        global.magic = 0;
        global.shield_on = false;
        magic_destroy_tornado();
        if (global.selected_item == 3) global.player.move_speed = 2;
    }
}
