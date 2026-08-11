/// @description Player update
if (global.menu.active) exit;
if (global.dialogue.active) {
    is_moving = false;
    anim_frame = 0;
    image_index = 0;
    exit;
}

if (global.health <= 0) {
    checkpoint_restore();
    exit;
}

var _input = input_check();

if (_input.item_next) magic_select_next();
var _magic_just_pressed = _input.magic && !magic_was_down;
magic_update(_input.magic, _magic_just_pressed);
magic_was_down = _input.magic;
if (global.thunder_timer > 0) global.thunder_timer--;

if (invulnerable_timer > 0) invulnerable_timer--;
if (hammer_cooldown > 0) hammer_cooldown--;

var _dx = 0;
var _dy = 0;
is_moving = false;
input_diagonal = false;

// MOVPAT.C gives horizontal facing priority for diagonal movement.
if (_input.up && _input.left) {
    _dx = -move_speed; _dy = -move_speed; facing = Dir.LEFT; input_diagonal = true;
}
else if (_input.up && _input.right) {
    _dx = move_speed; _dy = -move_speed; facing = Dir.RIGHT; input_diagonal = true;
}
else if (_input.down && _input.left) {
    _dx = -move_speed; _dy = move_speed; facing = Dir.LEFT; input_diagonal = true;
}
else if (_input.down && _input.right) {
    _dx = move_speed; _dy = move_speed; facing = Dir.RIGHT; input_diagonal = true;
}
else if (_input.left)  { _dx = -move_speed; facing = Dir.LEFT; }
else if (_input.right) { _dx =  move_speed; facing = Dir.RIGHT; }
else if (_input.up)    { _dy = -move_speed; facing = Dir.UP; }
else if (_input.down)  { _dy =  move_speed; facing = Dir.DOWN; }

if (_dx != 0) {
    var _sign_x = sign(_dx);
    for (var i = 0; i < abs(_dx); i++) {
        if (check_move_player(x, y, col_w, col_h, _sign_x, 0)) {
            x += _sign_x;
            is_moving = true;
        } else break;
    }
}
if (_dy != 0) {
    var _sign_y = sign(_dy);
    for (var i = 0; i < abs(_dy); i++) {
        if (check_move_player(x, y, col_w, col_h, 0, _sign_y)) {
            y += _sign_y;
            is_moving = true;
        } else break;
    }
}

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
image_speed = 0;

if (_input.fire && hammer_cooldown <= 0) {
    if (global.hammer == noone || !instance_exists(global.hammer)) {
        var _h = instance_create_layer(x, y, "Actors", obj_hammer);
        _h.facing = facing;
        if (global.selected_item == 3 && _input.magic && global.magic > 0) _h.move_speed = 6;
        global.hammer = _h;
        audio_play_sound(snd_got_swish, 0, false);
        hammer_cooldown = 10;
    }
}

if (invulnerable_timer <= 0) {
    var _enemy = instance_place(x, y, obj_enemy);
    if (_enemy != noone && _enemy.visible) {
        if (!actor_trigger_special(_enemy, false)) {
            combat_player_hit(_enemy.strength);
        }
    }
}
