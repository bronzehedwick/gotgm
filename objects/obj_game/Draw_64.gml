/// @description Original 320x48 status panel
// THUNDER.C moves the displayed VGA page by one pixel/scanline. Redrawing the
// application surface with the same four offsets recreates that screen shake.
if (global.thunder_timer > 0 && surface_exists(application_surface)) {
    var _thunder_phase = global.thunder_timer mod 4;
    var _thunder_x = 0;
    var _thunder_y = 0;
    if (_thunder_phase == 0) _thunder_x = -1;
    else if (_thunder_phase == 1) _thunder_x = 1;
    else if (_thunder_phase == 2) _thunder_y = -1;
    else _thunder_y = 1;
    draw_set_colour(c_black);
    draw_rectangle(0, 0, SCREEN_W - 1, SCREEN_H - 1, false);
    draw_surface(application_surface, _thunder_x, _thunder_y);
}

var _panel_y = SCREEN_H;
draw_sprite(spr_status_bar, 0, 0, _panel_y);

if (global.selected_item >= 1 && global.selected_item <= 6) {
    var _pickup_number = global.selected_item + 26;
    var _item_sprite = asset_get_index("spr_pickup_" + string(_pickup_number));
    if (_item_sprite != -1)
        // PANEL.C display_item(): xfput(282, 8, ... objects[item + 25]).
        draw_sprite(_item_sprite, floor(current_time / 200) mod 4, 282, _panel_y + 8);
}

// Original PANEL.C bar coordinates and palette colours.
var _health_end = 59 + clamp(global.health, 0, MAX_HEALTH);
draw_set_colour(make_colour_rgb(255, 0, 0));
draw_rectangle(59, _panel_y + 8, _health_end, _panel_y + 12, false);
draw_set_colour(make_colour_rgb(211, 131, 83));
draw_rectangle(_health_end, _panel_y + 8, 209, _panel_y + 12, false);

var _magic_end = 59 + clamp(global.magic, 0, MAX_MAGIC);
draw_set_colour(make_colour_rgb(0, 255, 0));
draw_rectangle(59, _panel_y + 20, _magic_end, _panel_y + 24, false);
draw_set_colour(make_colour_rgb(211, 131, 83));
draw_rectangle(_magic_end, _panel_y + 20, 209, _panel_y + 24, false);

var _jewels = string(global.jewels);
var _jewel_x = 70;
if (string_length(_jewels) == 2) _jewel_x = 66;
else if (string_length(_jewels) >= 3) _jewel_x = 62;
draw_original_text(_jewels, _jewel_x, _panel_y + 32);

var _keys = string(global.keys);
var _key_x = 150;
if (string_length(_keys) == 2) _key_x = 146;
else if (string_length(_keys) >= 3) _key_x = 142;
draw_original_text(_keys, _key_x, _panel_y + 32);

var _score = string(global.score);
draw_original_text(_score, 276 - string_length(_score) * 8, _panel_y + 32);

// The DOS boss meter occupies the narrow strip at the upper-right of the
// playfield. It is shared by each four-part chapter boss.
var _boss = movement_actor_slot(3);
if (_boss != noone && instance_exists(_boss)) {
    var _boss_type = _boss.actor_type_id;
    var _is_boss = (_boss_type >= 22 && _boss_type <= 25)
        || (_boss_type >= 31 && _boss_type <= 34)
        || (_boss_type >= 64 && _boss_type <= 67);
    if (_is_boss) {
        var _boss_max = max(1, _boss.actor_def.health);
        var _segments = clamp(ceil(_boss.health * 10 / _boss_max), 0, 10);
        draw_set_colour(make_colour_rgb(83, 47, 31));
        draw_rectangle(303, 1, 318, 82, false);
        draw_set_colour(c_black);
        draw_rectangle(305, 3, 316, 80, false);
        for (var _segment = 0; _segment < 10; _segment++) {
            draw_set_colour((_segment < _segments)
                ? make_colour_rgb(0, 255, 0)
                : make_colour_rgb(47, 47, 47));
            draw_rectangle(307, 73 - _segment * 7, 314, 78 - _segment * 7, false);
        }
    }
}

// LIGHT.C draws ten flashes of eight 24-pixel random walks. A deterministic
// integer pattern keeps the original shape and timing without flickering when
// GameMaker redraws a frame more than once.
if (global.lightning_timer > 0 && global.player != noone
&& instance_exists(global.player)) {
    var _origin_x = global.player.x + 7;
    var _origin_y = global.player.y + 8;
    var _flash = (60 - global.lightning_timer) div 6;
    if (((60 - global.lightning_timer) mod 6) < 3) {
        draw_set_colour((_flash & 1) ? c_white : c_yellow);
        for (var _ray = 0; _ray < 8; _ray++) {
            var _px = _origin_x;
            var _py = _origin_y;
            for (var _bolt = 0; _bolt < 24; _bolt++) {
                var _choice3 = (_flash * 97 + _ray * 31 + _bolt * 17) mod 3;
                var _choice2 = (_flash * 53 + _ray * 19 + _bolt * 11) mod 2;
                switch (_ray) {
                    case 0: _py--; _px += _choice3 - 1; break;
                    case 1:
                        if (_choice2 == 0) _px++; else _py--;
                        break;
                    case 2: _px++; _py += _choice3 - 1; break;
                    case 3:
                        if (_choice2 == 0) _px++; else _py++;
                        break;
                    case 4: _py++; _px += _choice3 - 1; break;
                    case 5:
                        if (_choice2 == 0) _px--; else _py++;
                        break;
                    case 6: _px--; _py += _choice3 - 1; break;
                    case 7:
                        if (_choice2 == 0) _px--; else _py--;
                        break;
                }
                if (_px >= 0 && _px < SCREEN_W && _py >= 0 && _py < SCREEN_H)
                    draw_point(_px, _py);
            }
        }
    }
}

draw_set_colour(c_white);
dialogue_draw();
menu_draw();
