/// @description Original room soundtrack selection

function music_init() {
    global.music_enabled = true;
    global.music_current_asset = -1;
    global.music_instance = -1;
}

function music_room_asset(episode, music_number) {
    var _episode1 = [
        mus_got_adventure1, mus_got_puzzle1, mus_got_action1, mus_got_creepy1,
        mus_got_win, mus_got_boss
    ];
    var _episode2 = [
        mus_got_adventure2, mus_got_puzzle2, mus_got_action2, mus_got_scary,
        mus_got_creepy3, mus_got_puzzle3, mus_got_win, mus_got_boss
    ];
    var _episode3 = [
        mus_got_adventure3, mus_got_puzzle4, mus_got_action3, mus_got_creepy2,
        mus_got_creepy3, mus_got_sad, mus_got_win, mus_got_boss
    ];
    var _tracks = (episode == 1) ? _episode1 : ((episode == 2) ? _episode2 : _episode3);
    if (music_number < 0 || music_number >= array_length(_tracks)) return -1;
    return _tracks[music_number];
}

function music_play_asset(sound_asset, restart = false) {
    if (!global.music_enabled || sound_asset == -1) return;
    if (!restart && global.music_current_asset == sound_asset
    && audio_is_playing(global.music_instance)) return;

    if (global.music_instance != -1) audio_stop_sound(global.music_instance);
    global.music_current_asset = sound_asset;
    global.music_instance = audio_play_sound(sound_asset, -100, true);
    audio_sound_gain(global.music_instance, 0.55, 0);
}

function music_enter_room() {
    if (global.current_level_metadata == undefined) return;
    music_play_asset(music_room_asset(
        global.current_episode,
        global.current_level_metadata.music
    ));
}

function music_play_boss() {
    music_play_asset(mus_got_boss, true);
}

function music_play_victory() {
    music_play_asset(mus_got_win, true);
}

function music_play_opening() {
    music_play_asset(mus_got_opening, true);
}
