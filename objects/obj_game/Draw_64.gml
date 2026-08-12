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

// The source uses palette/display-page effects for these spells. Procedural
// lines and flashes preserve the timing without requiring new replacement art.
if (global.lightning_timer > 0 && global.player != noone
&& instance_exists(global.player)) {
    var _origin_x = global.player.x + 7;
    var _origin_y = global.player.y + 8;
    draw_set_colour(((global.lightning_timer div 2) & 1) ? c_white : c_yellow);
    for (var _ray = 0; _ray < 8; _ray++) {
        var _px = _origin_x;
        var _py = _origin_y;
        for (var _bolt = 1; _bolt <= 5; _bolt++) {
            var _angle = _ray * 45 + ((_bolt + global.lightning_timer) mod 3 - 1) * 10;
            var _nx = _origin_x + lengthdir_x(_bolt * 12, _angle);
            var _ny = _origin_y + lengthdir_y(_bolt * 12, _angle);
            draw_line(_px, _py, _nx, _ny);
            _px = _nx;
            _py = _ny;
        }
    }
}

if (global.thunder_timer > 0 && ((global.thunder_timer div 2) & 1)) {
    draw_set_alpha(0.22);
    draw_set_colour(c_white);
    draw_rectangle(0, 0, SCREEN_W - 1, SCREEN_H - 1, false);
    draw_set_alpha(1);
}

draw_set_colour(c_white);
dialogue_draw();
menu_draw();
