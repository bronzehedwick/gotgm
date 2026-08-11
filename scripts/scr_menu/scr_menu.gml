/// @description Original-style opening and Escape option menus

function menu_init() {
    global.fast_mode = false;
    global.menu = {
        active: false,
        mode: "none",
        return_mode: "pause",
        title: "",
        options: [],
        selection: 0,
        status: "",
        status_timer: 0,
        story_phase: 0,
        story_scroll: 0,
        story_delay: 0,
        page_lines: [],
    };
}

function menu_set(mode, title, options, return_mode = "pause") {
    var _m = global.menu;
    _m.active = true;
    _m.mode = mode;
    _m.title = title;
    _m.options = options;
    _m.selection = 0;
    _m.return_mode = return_mode;
    _m.status = "";
    _m.status_timer = 0;
}

function menu_show_title() {
    global.demo_active = false;
    global.demo_index = 0;
    global.demo_up = false;
    global.demo_down = false;
    global.demo_left = false;
    global.demo_right = false;
    global.demo_fire = false;
    global.demo_magic = false;
    menu_set("title", "God of Thunder Menu", [
        "Play Game", "High Scores", "Credits", "Demo", "BBS Info", "Quit"
    ], "title");
    music_play_opening();
}

function menu_show_player() {
    menu_set("player", "Player Selection", [
        "New Game", "Continue Saved Game", "Back"
    ], "title");
}

function menu_show_episode() {
    menu_set("episode", "Play Which Game?", [
        "Part 1: Serpent Surprise!",
        "Part 2: Non-stick Nognir",
        "Part 3: Lookin' for Loki",
        "Back"
    ], "player");
}

function menu_show_page(mode, title, lines) {
    menu_set(mode, title, [], "title");
    global.menu.page_lines = lines;
}

function menu_open_pause() {
    menu_set("pause", "Options Menu", [
        "Sound / Music", "Skill Level", "Save Game", "Load Game",
        "Die", "Turbo Mode", "Help", "Quit"
    ], "pause");
}

function menu_close() {
    global.menu.active = false;
    global.menu.mode = "none";
    global.menu.status = "";
    music_enter_room();
}

function menu_message(text) {
    global.menu.status = text;
    global.menu.status_timer = 180;
}

function menu_save_game() {
    checkpoint_save();
    var _save = {
        version: 1,
        checkpoint: global.checkpoint,
        flags: global.flags,
        inventory: global.inventory,
        collected_pickups: global.collected_pickups,
        tile_overrides: global.tile_overrides,
        difficulty: global.difficulty,
        music_enabled: global.music_enabled,
    };
    var _file = file_text_open_write("gotgm_save.json");
    if (_file < 0) return false;
    file_text_write_string(_file, json_stringify(_save));
    file_text_close(_file);
    return true;
}

function menu_load_game() {
    if (!file_exists("gotgm_save.json")) return false;
    var _file = file_text_open_read("gotgm_save.json");
    if (_file < 0) return false;
    var _json = "";
    while (!file_text_eof(_file)) _json += file_text_readln(_file);
    file_text_close(_file);
    var _save = json_parse(_json);
    if (_save == undefined || !variable_struct_exists(_save, "checkpoint")) return false;
    global.checkpoint = _save.checkpoint;
    global.flags = _save.flags;
    global.inventory = _save.inventory;
    global.collected_pickups = _save.collected_pickups;
    global.tile_overrides = _save.tile_overrides;
    global.difficulty = _save.difficulty;
    global.music_enabled = _save.music_enabled;
    global.demo_active = false;
    global.menu.active = false;
    global.menu.mode = "none";
    checkpoint_restore();
    return true;
}

function menu_begin_game(episode, demo_playback = false) {
    var _level = 23;
    var _x = 152;
    var _y = 96;
    var _magic = 0;
    var _selected_item = 0;
    var _inventory = {};

    switch (episode) {
        case 2:
            _level = 51;
            _x = 32;
            _y = 32;
            _magic = MAX_MAGIC;
            _selected_item = 1;
            _inventory.item_1 = true;
            _inventory.item_2 = true;
            break;

        case 3:
            _level = 33;
            _x = 272;
            _y = 80;
            _magic = MAX_MAGIC;
            _selected_item = 1;
            _inventory.item_1 = true;
            _inventory.item_2 = true;
            _inventory.item_3 = true;
            _inventory.item_4 = true;
            break;
    }

    var _health = MAX_HEALTH;
    var _jewels = 0;
    var _score = 0;
    if (demo_playback) {
        episode = 1;
        _level = 54;
        _x = 152;
        _y = 96;
        _health = 100;
        _magic = 100;
        _jewels = 463;
        _score = 12455;
        _selected_item = 2;
        _inventory = { item_1: true, item_2: true };
        global.difficulty = 0;
    }

    global.health = _health;
    global.magic = _magic;
    global.jewels = _jewels;
    global.score = _score;
    global.keys = 0;
    global.current_episode = episode;
    global.current_level = _level;
    global.last_room = -1;
    global.inventory = _inventory;
    global.collected_pickups = {};
    global.selected_item = _selected_item;
    global.quest_object = 0;
    global.flags = {};
    global.tile_overrides = {};
    global.checkpoint = {
        episode: episode, level: _level, x: _x, y: _y, facing: Dir.DOWN,
        health: _health, magic: _magic, jewels: _jewels, keys: 0, score: _score,
        selected_item: _selected_item, quest_object: 0,
        inventory_json: json_stringify(_inventory),
    };

    global.demo_active = demo_playback;
    global.demo_index = 0;
    global.demo_up = false;
    global.demo_down = false;
    global.demo_left = false;
    global.demo_right = false;
    global.demo_fire = false;
    global.demo_magic = false;

    if (demo_playback) {
        global.menu.active = false;
        global.menu.mode = "none";
    } else {
        global.menu.active = true;
        global.menu.mode = "story";
        global.menu.options = [];
        global.menu.story_phase = 0;
        global.menu.story_scroll = 0;
        global.menu.story_delay = 60;
    }

    if (global.player != noone && instance_exists(global.player)) {
        global.player.x = _x;
        global.player.y = _y;
        global.player.facing = Dir.DOWN;
    }

    var _start = level_room_asset(episode, _level);
    if (_start != -1) room_goto(_start);
}

function menu_new_game(episode = 1) {
    menu_begin_game(episode, false);
}

function menu_start_demo() {
    menu_begin_game(1, true);
}

function menu_finish_story() {
    global.menu.active = false;
    global.menu.mode = "none";
    music_enter_room();
}

function menu_back() {
    var _return = global.menu.return_mode;
    if (_return == "title") menu_show_title();
    else if (_return == "player") menu_show_player();
    else if (_return == "episode") menu_show_episode();
    else menu_open_pause();
}

function menu_open_audio(return_mode) {
    menu_set("audio", "Sound / Music", [
        "Music: " + (global.music_enabled ? "On" : "Off"),
        "Back"
    ], return_mode);
}

function menu_open_skill(return_mode) {
    menu_set("skill", "Set Skill Level", [
        "Easy Enemies", "Normal Enemies", "Tough Enemies", "Back"
    ], return_mode);
    global.menu.selection = clamp(global.difficulty, 0, 2);
}

function menu_activate() {
    var _m = global.menu;
    switch (_m.mode) {
        case "title":
            switch (_m.selection) {
                case 0: menu_show_player(); break;
                case 1:
                    menu_show_page("high_scores", "High Scores", [
                        "Current score: " + string(global.score),
                        "",
                        "Enter or Escape: Back"
                    ]);
                    break;
                case 2:
                    menu_show_page("credits", "Credits", [
                        "Ron Davis", "Gary Sirois", "Adam Pedersen",
                        "Jason Blochowiak", "Roy Davis",
                        "Wayne Timmerman", "Dan Linton",
                        "", "Enter or Escape: Back"
                    ]);
                    break;
                case 3: menu_start_demo(); break;
                case 4:
                    menu_show_page("bbs_info", "BBS Info", [
                        "God of Thunder is freeware.",
                        "Originally by Impulse Software.",
                        "",
                        "Enter or Escape: Back"
                    ]);
                    break;
                case 5:
                    menu_set("quit_title", "Quit to Desktop?", ["Yes", "No"], "title");
                    break;
            }
            break;

        case "player":
            switch (_m.selection) {
                case 0: menu_show_episode(); break;
                case 1:
                    if (!menu_load_game()) menu_message("No saved game found.");
                    break;
                case 2: menu_show_title(); break;
            }
            break;

        case "episode":
            if (_m.selection <= 2) menu_new_game(_m.selection + 1);
            else menu_show_player();
            break;

        case "quit_title":
            if (_m.selection == 0) game_end();
            else menu_show_title();
            break;

        case "pause":
            switch (_m.selection) {
                case 0: menu_open_audio("pause"); break;
                case 1: menu_open_skill("pause"); break;
                case 2: menu_message(menu_save_game() ? "Game saved." : "Save failed."); break;
                case 3: if (!menu_load_game()) menu_message("No saved game found."); break;
                case 4: global.health = 0; menu_close(); break;
                case 5:
                    global.fast_mode = !global.fast_mode;
                    menu_message("Turbo Mode: " + (global.fast_mode ? "On" : "Off"));
                    break;
                case 6: menu_set("help", "Help", [], "pause"); break;
                case 7: menu_set("quit", "Quit Game?", ["Continue Game", "Opening Screen", "Quit to Desktop"], "pause"); break;
            }
            break;

        case "audio":
            if (_m.selection == 0) {
                global.music_enabled = !global.music_enabled;
                if (!global.music_enabled) {
                    if (global.music_instance != -1) audio_stop_sound(global.music_instance);
                    global.music_instance = -1;
                    global.music_current_asset = -1;
                } else if (_m.return_mode == "title") music_play_opening();
                else music_enter_room();
                _m.options[0] = "Music: " + (global.music_enabled ? "On" : "Off");
            } else menu_back();
            break;

        case "skill":
            if (_m.selection <= 2) {
                global.difficulty = _m.selection;
                menu_message("Skill level selected.");
            } else menu_back();
            break;

        case "help": menu_back(); break;

        case "quit":
            switch (_m.selection) {
                case 0: menu_close(); break;
                case 1: menu_show_title(); break;
                case 2: game_end(); break;
            }
            break;
    }
}

function menu_update() {
    var _m = global.menu;
    if (!_m.active) {
        if (global.demo_active && keyboard_check_pressed(vk_anykey)) {
            menu_show_title();
            return;
        }
        if (!global.dialogue.active && keyboard_check_pressed(vk_escape)) menu_open_pause();
        return;
    }
    if (_m.status_timer > 0) _m.status_timer--;
    else _m.status = "";

    if (_m.mode == "story") {
        if (keyboard_check_pressed(vk_escape)) {
            menu_finish_story();
            return;
        }
        if (_m.story_delay > 0) {
            _m.story_delay--;
            return;
        }

        var _advance = keyboard_check_pressed(vk_anykey);
        switch (_m.story_phase) {
            case 0: // first page waits for a response
                if (_advance) _m.story_phase = 1;
                break;
            case 1: // scroll the VGA display start down one scanline per tick
                if (_advance) {
                    _m.story_phase = 3;
                } else {
                    _m.story_scroll = min(240, _m.story_scroll + 1);
                    if (_m.story_scroll >= 240) _m.story_phase = 2;
                }
                break;
            case 2: // second page waits before gameplay begins
                if (_advance) menu_finish_story();
                break;
            case 3: // a response during the scroll pauses until another response
                if (_advance) _m.story_phase = 1;
                break;
        }
        return;
    }

    if (_m.mode == "help") {
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter)
        || keyboard_check_pressed(vk_space)) menu_back();
        return;
    }

    if (_m.mode == "high_scores" || _m.mode == "credits" || _m.mode == "bbs_info") {
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter)
        || keyboard_check_pressed(vk_space)) menu_show_title();
        return;
    }

    if (keyboard_check_pressed(vk_home)) _m.selection = 0;
    if (keyboard_check_pressed(vk_end)) _m.selection = max(0, array_length(_m.options) - 1);
    if (keyboard_check_pressed(vk_up)) {
        _m.selection--;
        if (_m.selection < 0) _m.selection = array_length(_m.options) - 1;
        audio_play_sound(snd_got_woop, 2, false);
    }
    if (keyboard_check_pressed(vk_down)) {
        _m.selection++;
        if (_m.selection >= array_length(_m.options)) _m.selection = 0;
        audio_play_sound(snd_got_woop, 2, false);
    }
    if (keyboard_check_pressed(vk_escape)) {
        if (_m.mode == "pause") menu_close();
        else if (_m.mode == "title")
            menu_set("quit_title", "Quit to Desktop?", ["Yes", "No"], "title");
        else menu_back();
        return;
    }
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
        audio_play_sound(snd_got_clang, 3, false);
        menu_activate();
    }
}

function menu_draw_box() {
    var _m = global.menu,_longest=string_length(_m.title);
    for (var _i=0;_i<array_length(_m.options);_i++) _longest=max(_longest,string_length(_m.options[_i]));
    if (_longest & 1) _longest++;
    var _width=_longest*8+32,_height=array_length(_m.options)*16+32;
    var _x1=(320-_width) div 2,_y1=(192-_height) div 2;
    if (_x1 & 1) _x1++;
    var _x2=_x1+_width-1,_y2=_y1+_height-1;
    draw_set_colour(make_colour_rgb(131,83,47));draw_rectangle(_x1,_y1,_x2,_y2,false);
    dialogue_draw_tile(192,_x1-16,_y1-16);dialogue_draw_tile(193,_x2,_y1-16);
    dialogue_draw_tile(194,_x1-16,_y2);dialogue_draw_tile(195,_x2,_y2);
    var _across=_width div 16;
    for(var _i=0;_i<_across;_i++){
        dialogue_draw_tile(196,_x1+_i*16,_y1-16);
        dialogue_draw_tile(197,_x1+_i*16,_y2);
    }
    for(var _i=0;_i<array_length(_m.options)+2;_i++){
        dialogue_draw_tile(198,_x1-16,_y1+_i*16);
        dialogue_draw_tile(199,_x2,_y1+_i*16);
    }
    draw_original_text_colour(_m.title,160-string_length(_m.title)*4,_y1+4,make_colour_rgb(255,35,35),false);
    for(var _i=0;_i<array_length(_m.options);_i++)
        draw_original_text_colour(_m.options[_i],_x1+32,_y1+28+_i*16,dialogue_markup_colour(0),false);
    if(array_length(_m.options)>0)
        draw_sprite(spr_actor_103_hammeri,8+(floor(current_time/120) mod 4),_x1+8,_y1+24+_m.selection*16);
    if(string_length(_m.status)>0)
        draw_original_text_colour(_m.status,160-string_length(_m.status)*4,181,dialogue_markup_colour(4),true);
}

function menu_draw_help() {
    dialogue_draw_frame();
    dialogue_draw_line("~1Help~0",144,68);
    dialogue_draw_line("Move: Arrow keys / WASD",52,84);
    dialogue_draw_line("Hammer: Space",52,95);
    dialogue_draw_line("Magic: Z or Control",52,106);
    dialogue_draw_line("Select Item: X or Shift",52,117);
    dialogue_draw_line("Options: Escape",52,128);
    dialogue_draw_line("~4Enter: Back",188,138);
}

function menu_draw_page() {
    var _m = global.menu;
    dialogue_draw_frame();
    draw_original_text_colour(
        _m.title, 160 - string_length(_m.title) * 4, 58,
        make_colour_rgb(255, 35, 35), false
    );
    var _y = 76;
    for (var _i = 0; _i < array_length(_m.page_lines); _i++) {
        var _line = _m.page_lines[_i];
        draw_original_text_colour(
            _line, 160 - string_length(_line) * 4, _y,
            dialogue_markup_colour(0), false
        );
        _y += 11;
    }
}

function menu_draw() {
    var _m = global.menu;
    if (!_m.active) return;

    if (_m.mode == "story") {
        var _story = asset_get_index("spr_story_ep" + string(global.current_episode));
        if (_story != -1)
            draw_sprite_part(_story, 0, 0, floor(_m.story_scroll), 320, 240, 0, 0);
        return;
    }

    draw_sprite(spr_title_menu, 0, 0, 0);

    if (_m.mode == "title") {
        draw_sprite(
            spr_actor_103_hammeri,
            8 + (floor(current_time / 120) mod 4),
            96, 71 + _m.selection * 20
        );
        if (string_length(_m.status) > 0)
            draw_original_text_colour(
                _m.status, 160 - string_length(_m.status) * 4, 218,
                dialogue_markup_colour(4), true
            );
        return;
    }

    draw_set_alpha(0.62);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 319, 239, false);
    draw_set_alpha(1);

    if (_m.mode == "help") menu_draw_help();
    else if (_m.mode == "high_scores" || _m.mode == "credits" || _m.mode == "bbs_info")
        menu_draw_page();
    else menu_draw_box();
}
