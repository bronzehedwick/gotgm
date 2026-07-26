/// @description Game initialization
game_init();

// Load palette data
var _pal_file = file_text_open_read("data/palette.json");
if (_pal_file != -1) {
    var _str = "";
    while (!file_text_eof(_pal_file)) {
        _str += file_text_readln(_pal_file);
    }
    file_text_close(_pal_file);
    global.palette = json_parse(_str);
}

// Load the starting level
level_load(global.current_level);
