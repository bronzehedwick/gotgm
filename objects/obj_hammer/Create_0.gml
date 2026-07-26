/// @description Hammer initialization
facing = Dir.DOWN;
move_speed = 4;
lifetime = 60; // max frames before returning
damage = 10;

// Sprite arrays
dir_sprites = [
    spr_hammer_down,
    spr_hammer_up,
    spr_hammer_left,
    spr_hammer_right,
];

sprite_index = dir_sprites[facing];
image_speed = 1;
