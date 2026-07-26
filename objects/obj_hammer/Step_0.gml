/// @description Hammer update
lifetime--;

// Movement
var _dx = 0, _dy = 0;
switch (facing) {
    case Dir.DOWN:  _dy = move_speed; break;
    case Dir.UP:    _dy = -move_speed; break;
    case Dir.LEFT:  _dx = -move_speed; break;
    case Dir.RIGHT: _dx = move_speed; break;
}

sprite_index = dir_sprites[facing];

// Check tile collision
var _result = check_move_hammer(x, y, _dx, _dy);
if (_result == 1 || lifetime <= 0) {
    // Hit wall or expired - destroy
    global.hammer = noone;
    instance_destroy();
    return;
}

x += _dx;
y += _dy;

// Check enemy collision
var _hit = instance_place(x, y, obj_enemy);
if (_hit != noone) {
    combat_enemy_hit(_hit, damage);
    // Hammer continues through enemies (like original)
}
