/// @description Enemy projectile update
if (global.menu.active) exit;
speed_count++;
if (speed_count >= shot_speed) {
    speed_count = 0;
    var _alive = true;
    for (var _i = 0; _i < shot_num_moves; _i++) {
        if (!shot_step_motion()) {
            _alive = false;
            break;
        }
    }
    if (!_alive) {
        instance_destroy();
        exit;
    }

    frame_count++;
    if (frame_count >= shot_frame_speed && shot_move != 9) {
        frame_count = 0;
        current_frame = (current_frame + 1) mod array_length(shot_sequence);
    }
}

if (array_length(shot_sequence) > 0) {
    var _pose = shot_sequence[clamp(current_frame, 0, array_length(shot_sequence) - 1)];
    if (shot_directions == 4 && shot_frames == 1) image_index = facing;
    else image_index = _pose + ((shot_directions > 1) ? facing * shot_frames : 0);
}
image_speed = 0;

if (global.player != noone && instance_exists(global.player)
&& rectangle_in_rectangle(x, y, x + shot_w, y + shot_h,
                          global.player.x, global.player.y,
                          global.player.x + global.player.col_w,
                          global.player.y + global.player.col_h)) {
    combat_player_hit(shot_strength);
    if (shot_move != 7 && shot_move != 8) instance_destroy();
}
