/// @description Draw level tiles
if (global.tile_grid != undefined) {
    level_draw_tiles();
} else {
    // Fallback: draw a visible background so we know the game is running
    draw_set_colour(c_navy);
    draw_rectangle(0, 0, SCREEN_W, SCREEN_H, false);
    draw_set_colour(c_white);
    draw_text(4, 4, "No level data loaded");
    draw_text(4, 20, "Check Output log for errors");
}
