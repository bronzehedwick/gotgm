/// @description Player update
if (global.menu.active) exit;
if (global.dialogue.active) {
    is_moving = false;
    anim_frame = 0;
    image_index = 0;
    exit;
}

if (global.health <= 0) {
    if (!global.death_active) {
        global.death_active = true;
        global.death_timer = 0;
        audio_play_sound(snd_got_dead, 5, false);
        if (global.hammer != noone && instance_exists(global.hammer))
            instance_destroy(global.hammer);
        global.hammer = noone;
        magic_destroy_tornado();
        global.shield_on = false;
    }
    global.death_timer++;
    var _spin_order = [Dir.UP, Dir.LEFT, Dir.DOWN, Dir.RIGHT];
    facing = _spin_order[(global.death_timer div 5) mod 4];
    sprite_index = (global.armor_level <= 0) ? spr_actor_100_thor_lth
        : ((global.armor_level == 1) ? spr_actor_101_thor_lth : spr_actor_110_thor_gld);
    image_index = facing * 4;
    image_speed = 0;
    if (global.death_timer >= 60) checkpoint_restore();
    exit;
}

var _input = input_check();

if (_input.item_next) magic_select_next();
var _magic_just_pressed = _input.magic && !magic_was_down;
magic_update(_input.magic, _magic_just_pressed);
magic_was_down = _input.magic;

if (global.current_episode == 2 && global.slip_active) {
    _input.up = false;
    _input.left = false;
    _input.right = false;
    _input.down = true;
    global.slip_timer--;
    if (global.slip_timer <= 0) global.slip_active = false;
}

if (invulnerable_timer > 0) invulnerable_timer--;
if (hammer_cooldown > 0) hammer_cooldown--;

var _dx = 0;
var _dy = 0;
is_moving = false;
input_diagonal = false;
input_vertical_dir = _input.up ? Dir.UP : (_input.down ? Dir.DOWN : -1);
input_horizontal_dir = _input.left ? Dir.LEFT : (_input.right ? Dir.RIGHT : -1);

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

if (global.current_episode == 2) {
    var _floor_tile = tile_get((x + 7) div TILE_W, (y + 12) div TILE_H);
    if (_floor_tile == 204 && !struct_exists(global.flags, "19")) {
        if (!global.slip_active) {
            global.slip_charge++;
            if (global.slip_charge > 8) {
                global.slip_active = true;
                global.slip_timer = 8;
                audio_play_sound(snd_got_fall, 2, false);
            }
        }
    } else if (!global.slip_active) {
        global.slip_charge = 0;
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

sprite_index = (global.armor_level <= 0) ? spr_actor_100_thor_lth
    : ((global.armor_level == 1) ? spr_actor_101_thor_lth : spr_actor_110_thor_gld);
image_index = facing * 4 + anim_frame;
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
    if (_enemy != noone && _enemy.visible && !_enemy.is_magic_effect) {
        if (!actor_trigger_special(_enemy, false)) {
            combat_player_hit(_enemy.strength);
            if (_enemy.move_pattern == 18) _enemy.hit_player = true;
        }
    }
}
