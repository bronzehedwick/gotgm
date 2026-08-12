/// @description Player initialization
global.player = id;

facing = Dir.DOWN;
move_speed = 2;
invulnerable_timer = 0;

// Collision box (original: 13x15 with 2px inset)
col_w = 13;
col_h = 15;

// Sprite arrays for each direction
dir_sprites = [
    spr_thor_down,
    spr_thor_up,
    spr_thor_left,
    spr_thor_right,
];

// Animation
anim_frame = 0;
anim_timer = 0;
anim_speed = 6; // frames between animation updates
is_moving = false;

// Hammer state
hammer_cooldown = 0;
magic_was_down = false;
global.death_active = false;
global.death_timer = 0;
