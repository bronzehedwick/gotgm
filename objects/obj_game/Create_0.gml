/// @description Game initialization
game_init();

depth = 300;
level_enter_current_room();
menu_show_title();
show_debug_message("Game initialized in " + room_get_name(room));
