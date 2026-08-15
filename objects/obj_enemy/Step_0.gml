/// @description Enemy update
if (global.menu.active) exit;
if (global.death_active) exit;
if (dialogue_cooldown > 0) dialogue_cooldown--;
if (special_cooldown > 0) special_cooldown--;
if (dialogue_contact_latched
&& (global.player == noone || !instance_exists(global.player) || !place_meeting(x, y, obj_player))) {
    dialogue_contact_latched = false;
}
if (global.dialogue.active || is_dead || !visible) exit;

if (is_magic_effect) {
    movement_execute(id);
    if (is_tornado) magic_tornado_damage(id);
} else {
enemy_fire_pattern(id);
movement_execute(id);
}

// Original next_frame only advances animation when a movement tick occurs.
if (movement_tick && move_pattern != 6 && move_pattern != 15
&& move_pattern != 22 && move_pattern != 28) {
    frame_count++;
    if (frame_count >= frame_speed) {
        frame_count = 0;
        current_frame = (current_frame + 1) mod array_length(frame_sequence);
    }
}

var _pose = frame_sequence[clamp(current_frame, 0, array_length(frame_sequence) - 1)];
image_index = _pose + ((directions > 1) ? facing * 4 : 0);

if (vulnerable_timer > 0) vulnerable_timer--;
if (damage_flash_timer > 0) damage_flash_timer--;
image_speed = 0;
