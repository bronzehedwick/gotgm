/// @description Original object pickup behavior from 1_OBJECT.C
if (global.menu.active) exit;
if (global.player == noone || !instance_exists(global.player)) exit;

var _pickup_key = room_get_name(room) + "|" + string(round(x)) + "|" + string(round(y)) + "|" + string(pickup_type);
if (persistent_pickup && struct_exists(global.collected_pickups, _pickup_key)) {
    instance_destroy();
    exit;
}

var _p = global.player;
if (!rectangle_in_rectangle(_p.x, _p.y, _p.x + _p.col_w, _p.y + _p.col_h,
                            x, y, x + 15, y + 15)) exit;

var _collected = true;
var _pickup_sound = snd_got_yah;
switch (pickup_type) {
    case 1: // red jewel
        if (global.jewels >= MAX_JEWELS) _collected = false;
        else global.jewels = min(MAX_JEWELS, global.jewels + 10);
        break;

    case 2: // blue jewel
        if (global.jewels >= MAX_JEWELS) _collected = false;
        else global.jewels = min(MAX_JEWELS, global.jewels + 1);
        break;

    case 3: // red magic potion
        if (global.magic >= MAX_MAGIC) _collected = false;
        else global.magic = min(MAX_MAGIC, global.magic + 10);
        break;

    case 4: // blue magic potion
        if (global.magic >= MAX_MAGIC) _collected = false;
        else global.magic = min(MAX_MAGIC, global.magic + 3);
        break;

    case 5: // good apple
        _pickup_sound = snd_got_gulp;
        if (global.health >= MAX_HEALTH) _collected = false;
        else global.health = min(MAX_HEALTH, global.health + 5);
        break;

    case 6: // bad apple
        _pickup_sound = snd_got_ow;
        global.health = max(0, global.health - 10);
        break;

    case 7: // key
        global.keys = min(MAX_KEYS, global.keys + 1);
        break;

    case 8: // treasure
        if (global.jewels >= MAX_JEWELS) _collected = false;
        else global.jewels = min(MAX_JEWELS, global.jewels + 50);
        break;

    case 9: // trophy
        global.score = min(MAX_SCORE, global.score + 100);
        break;

    case 10: // crown
        global.score = min(MAX_SCORE, global.score + 1000);
        break;

    case 12: case 13: case 14: case 15: case 16:
    case 17: case 18: case 19: case 20: case 21:
    case 22: case 23: case 24: case 25: case 26:
        global.inventory[$ "quest_" + string(pickup_type - 11)] = true;
        global.selected_item = 7;
        global.quest_object = pickup_type - 11;
        break;

    case 27: case 28: case 29: case 30: case 31: case 32:
        global.inventory[$ "item_" + string(pickup_type - 26)] = true;
        global.selected_item = pickup_type - 26;
        global.magic = MAX_MAGIC;
        global.score = min(MAX_SCORE, global.score + 5000);
        break;

    default:
        // Type 11 is intentionally unused in the original table.
        _collected = false;
        break;
}

if (_collected) {
    audio_play_sound(_pickup_sound, 0, false);
    if (persistent_pickup) global.collected_pickups[$ _pickup_key] = true;
    instance_destroy();
}
