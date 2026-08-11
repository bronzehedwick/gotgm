/// @description Hammer initialization
facing = Dir.DOWN;
move_speed = 4;
returning = false;
outbound_timer = 45;
return_axis_toggle = false;
damage = 10;

// Sprite arrays follow the original UP, DOWN, LEFT, RIGHT direction order.
dir_sprites = [
    spr_hammer_down,
    spr_hammer_up,
    spr_hammer_left,
    spr_hammer_right,
];

sprite_index = dir_sprites[facing];
image_speed = 1;
