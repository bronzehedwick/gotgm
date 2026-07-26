/// @description Tile-based collision checks (faithful to original check_move functions)

/// @function check_move_player(px, py, pw, ph, dx, dy)
/// @description Player movement collision check (original check_move0)
/// @param {real} px Player x
/// @param {real} py Player y
/// @param {real} pw Player collision width
/// @param {real} ph Player collision height
/// @param {real} dx Delta x
/// @param {real} dy Delta y
/// @returns {bool} true if movement is allowed
function check_move_player(px, py, pw, ph, dx, dy) {
    var _nx = px + dx;
    var _ny = py + dy;

    // Check screen bounds for room transitions
    // (handled separately by the level controller)
    if (_nx < 0 || _nx + pw > SCREEN_W) return false;
    if (_ny < 0 || _ny + ph > SCREEN_H) return false;

    // Check tile collision at the four corners of the collision box
    // Use a 2px inset like the original (thor_x1=thor->x+2, thor_y1=thor->y+2)
    var _x1 = _nx + 2;
    var _y1 = _ny + 2;
    var _x2 = _nx + pw - 2;
    var _y2 = _ny + ph - 2;

    // Check all tiles the player would overlap
    var _gx1 = _x1 div TILE_W;
    var _gy1 = _y1 div TILE_H;
    var _gx2 = _x2 div TILE_W;
    var _gy2 = _y2 div TILE_H;

    for (var _gy = _gy1; _gy <= _gy2; _gy++) {
        for (var _gx = _gx1; _gx <= _gx2; _gx++) {
            var _tid = tile_get(_gx, _gy);
            if (_tid < 0) return false;
            if (tile_is_solid(_tid)) return false;
            if (tile_is_fly_only(_tid)) return false; // player can't fly
        }
    }

    return true;
}

/// @function check_move_hammer(hx, hy, dx, dy)
/// @description Hammer movement collision check (original check_move1)
/// @returns {real} 0=ok, 1=wall, 2=enemy_hit
function check_move_hammer(hx, hy, dx, dy) {
    var _nx = hx + dx;
    var _ny = hy + dy;

    // Off screen = stop
    if (_nx < 0 || _nx + 16 > SCREEN_W) return 1;
    if (_ny < 0 || _ny + 16 > SCREEN_H) return 1;

    // Check tile
    var _gx = (_nx + 8) div TILE_W;
    var _gy = (_ny + 8) div TILE_H;
    var _tid = tile_get(_gx, _gy);

    if (_tid >= TILE_SOLID && _tid < TILE_FLY) return 1; // hit wall

    return 0;
}

/// @function check_move_enemy(ex, ey, ew, eh, dx, dy, is_flying)
/// @description Enemy movement collision check (original check_move2)
/// @returns {bool} true if movement is allowed
function check_move_enemy(ex, ey, ew, eh, dx, dy, is_flying) {
    var _nx = ex + dx;
    var _ny = ey + dy;

    if (_nx < 0 || _nx + ew > SCREEN_W) return false;
    if (_ny < 0 || _ny + eh > SCREEN_H) return false;

    var _gx1 = _nx div TILE_W;
    var _gy1 = _ny div TILE_H;
    var _gx2 = (_nx + ew - 1) div TILE_W;
    var _gy2 = (_ny + eh - 1) div TILE_H;

    for (var _gy = _gy1; _gy <= _gy2; _gy++) {
        for (var _gx = _gx1; _gx <= _gx2; _gx++) {
            var _tid = tile_get(_gx, _gy);
            if (_tid < 0) return false;
            if (tile_is_solid(_tid)) return false;
            if (!is_flying && tile_is_fly_only(_tid)) return false;
        }
    }

    return true;
}
