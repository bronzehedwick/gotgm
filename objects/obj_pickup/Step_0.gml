/// @description Pickup collision check
if (global.player == noone || !instance_exists(global.player)) return;

var _p = global.player;
// Simple bounding box overlap
if (point_in_rectangle(_p.x + 8, _p.y + 8, x, y, x + 15, y + 15)) {
    // Process pickup
    switch (pickup_type) {
        case 1: case 2: case 3: case 4:
            // Jewels (different values)
            var _values = [0, 1, 5, 10, 25];
            global.jewels = min(global.jewels + _values[pickup_type], MAX_JEWELS);
            global.score = min(global.score + _values[pickup_type], MAX_SCORE);
            break;
        case 5:
            // Apple - restore health
            global.health = min(global.health + 10, MAX_HEALTH);
            break;
        case 6:
            // Potion - restore magic
            global.magic = min(global.magic + 10, MAX_MAGIC);
            break;
        case 7:
            // Key
            global.keys = min(global.keys + 1, MAX_KEYS);
            break;
        default:
            show_debug_message("Picked up object type: " + string(pickup_type));
            break;
    }
    instance_destroy();
}
