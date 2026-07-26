/// @description Player update
var _input = input_check();

// Process invulnerability
if (invulnerable_timer > 0) {
    invulnerable_timer--;
}

// Process hammer cooldown
if (hammer_cooldown > 0) {
    hammer_cooldown--;
}

// Movement
var _dx = 0;
var _dy = 0;
is_moving = false;

if (_input.left)  { _dx = -move_speed; facing = Dir.LEFT; }
if (_input.right) { _dx =  move_speed; facing = Dir.RIGHT; }
if (_input.up)    { _dy = -move_speed; facing = Dir.UP; }
if (_input.down)  { _dy =  move_speed; facing = Dir.DOWN; }

// Move one axis at a time for slide-along-walls behavior
if (_dx != 0) {
    // Move pixel by pixel for accuracy
    var _sign_x = sign(_dx);
    for (var i = 0; i < abs(_dx); i++) {
        if (check_move_player(x, y, col_w, col_h, _sign_x, 0)) {
            x += _sign_x;
            is_moving = true;
        } else {
            break;
        }
    }
}
if (_dy != 0) {
    var _sign_y = sign(_dy);
    for (var i = 0; i < abs(_dy); i++) {
        if (check_move_player(x, y, col_w, col_h, 0, _sign_y)) {
            y += _sign_y;
            is_moving = true;
        } else {
            break;
        }
    }
}

// Animation
if (is_moving) {
    anim_timer++;
    if (anim_timer >= anim_speed) {
        anim_timer = 0;
        anim_frame = (anim_frame + 1) mod 4;
    }
} else {
    anim_frame = 0;
    anim_timer = 0;
}

sprite_index = dir_sprites[facing];
image_index = anim_frame;
image_speed = 0; // manual animation control

// Throw hammer
if (_input.fire && hammer_cooldown <= 0) {
    if (global.hammer == noone || !instance_exists(global.hammer)) {
        var _h = instance_create_layer(x, y, "Instances", obj_hammer);
        _h.facing = facing;
        global.hammer = _h;
        hammer_cooldown = 10;
    }
}

// Check enemy contact damage
if (invulnerable_timer <= 0) {
    var _enemy = instance_place(x, y, obj_enemy);
    if (_enemy != noone) {
        combat_player_hit(_enemy.strength);
    }
}
