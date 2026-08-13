/// @description Original four-state VGA palette rotation (no bob or tint)
var _phase = floor(current_time / 200) mod 4;
if (sprite_index != -1) {
    draw_sprite(sprite_index, _phase, x, y);
} else {
    draw_pickup(pickup_type, x, y, _phase);
}
