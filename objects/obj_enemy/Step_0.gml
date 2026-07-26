/// @description Enemy update
if (is_dead) return;

// Movement
movement_execute(id);

// Animation
frame_count++;
if (frame_count >= frame_speed) {
    frame_count = 0;
    current_frame = (current_frame + 1) mod anim_frames;
    image_index = current_frame;
}

// Vulnerability flash
if (vulnerable_timer > 0) {
    vulnerable_timer--;
}

image_speed = 0;
