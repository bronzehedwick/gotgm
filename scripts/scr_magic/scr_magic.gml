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

function magic_update(is_down, just_pressed) {
    if (global.player == noone || !instance_exists(global.player)) return;

    global.player.move_speed = 2;
    if (!is_down) {
        global.magic_use_timer = 0;
        global.shield_on = false;
        if (global.selected_item == 4) global.tornado_timer = 0;
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

        case 2: // lightning: 15 magic, damages nearby actors
            if (just_pressed && global.magic >= 15) {
                global.magic -= 15;
                audio_play_sound(snd_got_electric, 4, false);
                magic_area_damage(30, 254);
            }
            break;

        case 3: // speed boots: held, drains one magic every nine counts
            if (global.magic > 0) {
                global.player.move_speed = 4;
                if (_pulse) global.magic--;
            }
            break;

        case 4: // tornado: starts at 10 magic, then drains while held
            if (just_pressed && global.magic > 10) {
                global.magic -= 10;
                global.tornado_timer = 20;
                audio_play_sound(snd_got_wind, 2, false);
            } else if (global.tornado_timer > 0 && _pulse && global.magic > 0) {
                global.magic--;
            }
            if (global.tornado_timer > 0) {
                global.tornado_timer--;
                magic_area_damage(42, 10);
            }
            break;

        case 5: // shield: held, drains one magic every nine counts
            if (global.magic > 0) {
                global.shield_on = true;
                if (_pulse) global.magic--;
            }
            break;

        case 6: // thunder: 30 magic, one source-timed 60-count burst
            if (just_pressed && global.magic > 29 && global.thunder_timer <= 0) {
                global.magic -= 30;
                global.thunder_timer = 60;
                audio_play_sound(snd_got_thunder, 4, false);
                with (obj_enemy) {
                    vulnerable_timer = 0;
                    combat_enemy_hit(id, 20);
                }
            }
            break;
    }

    if (global.magic <= 0) {
        global.magic = 0;
        global.shield_on = false;
        if (global.selected_item == 3) global.player.move_speed = 2;
    }
}
