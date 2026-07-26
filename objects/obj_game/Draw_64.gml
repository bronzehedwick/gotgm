/// @description Draw HUD
var _scale = 4; // GUI scale for visibility

draw_set_colour(c_black);
draw_rectangle(0, 0, display_get_gui_width(), 60 * _scale, false);

draw_set_colour(c_white);
draw_set_font(-1);

var _y = 8;
var _lh = 20;
draw_text(8, _y, "HP: " + string(global.health) + "/" + string(MAX_HEALTH));
draw_text(200, _y, "JEWELS: " + string(global.jewels));
_y += _lh;
draw_text(8, _y, "MAGIC: " + string(global.magic));
draw_text(200, _y, "KEYS: " + string(global.keys));
_y += _lh;
draw_text(8, _y, "SCORE: " + string(global.score));
draw_text(200, _y, "LEVEL: " + string(global.current_level));

if (global.debug_mode) {
    _y += _lh;
    if (global.player != noone && instance_exists(global.player)) {
        draw_text(8, _y, "POS: " + string(global.player.x) + "," + string(global.player.y));
        draw_text(200, _y, "DIR: " + string(global.player.facing));
    }
}
