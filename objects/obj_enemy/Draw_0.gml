/// @description Draw enemy
if (vulnerable_timer > 0 && (vulnerable_timer mod 2) == 0) {
    draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_red, 1);
} else {
    draw_self();
}
