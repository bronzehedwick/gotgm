/// @description Enemy initialization (set by actor_spawn)
actor_type_id = 0;
actor_def = undefined;

move_pattern = 1;
health = 10;
strength = 1;
speed = 2;
num_moves = 1;
solid_type = 0;
is_flying = false;

col_w = 15;
col_h = 15;

directions = 1;
anim_frames = 4;
frame_speed = 6;
frame_sequence = [0, 1, 2, 3];

facing = Dir.DOWN;
pass_value = 0;
speed_count = 0;
frame_count = 0;
current_frame = 0;
vulnerable_timer = 0;
is_dead = false;
pause_timer = 0;
