/// @description Original 320x48 status panel
var _panel_y = SCREEN_H;
draw_sprite(spr_status_bar, 0, 0, _panel_y);

if (global.selected_item >= 1 && global.selected_item <= 6) {
    var _pickup_number = global.selected_item + 26;
    var _item_sprite = asset_get_index("spr_pickup_" + string(_pickup_number));
    if (_item_sprite != -1) draw_sprite(_item_sprite, 0, 280, _panel_y + 4);
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

draw_set_colour(c_white);
dialogue_draw();
menu_draw();
