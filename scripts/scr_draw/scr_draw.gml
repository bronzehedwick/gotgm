/// @description Drawing helpers

/// @function draw_actor_sprite(actor_type_id, dir, frame, ax, ay)
/// @description Draw an actor using its spritesheet
/// @param {real} actor_type_id The actor definition number
/// @param {real} dir Direction (0-3)
/// @param {real} frame Animation frame (0-3)
/// @param {real} ax X position
/// @param {real} ay Y position
function draw_actor_sprite(actor_type_id, dir, frame, ax, ay) {
    // For now, use the assigned sprite_index on the instance
    // Later this will handle multi-direction spritesheets
    draw_self();
}

/// @function draw_pickup(pickup_type, px, py)
/// @description Draw a pickup/static object from the objects spritesheet
function draw_pickup(pickup_type, px, py) {
    if (pickup_type <= 0 || pickup_type > 32) return;

    var _idx = pickup_type - 1;
    var _cols = 8; // objects.png is 128px wide / 16px = 8 columns
    var _sx = (_idx mod _cols) * TILE_W;
    var _sy = (_idx div _cols) * TILE_H;

    draw_sprite_part(spr_objects, 0, _sx, _sy, TILE_W, TILE_H, px, py);
}
