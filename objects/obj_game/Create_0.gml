/// @description Game initialization
game_init();

// Spawn the player at center of screen
var _p = instance_create_layer(SCREEN_W div 2, SCREEN_H div 2, "Instances", obj_player);
global.player = _p;

// Load the starting level
level_load(global.current_level);

show_debug_message("Game initialized. Level: " + string(global.current_level));
