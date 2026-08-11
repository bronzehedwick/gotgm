/// @description Input handling

/// @function input_check()
/// @description Check and return current input state as a struct
function input_check() {
    var _input = {
        left:  keyboard_check(vk_left)  || keyboard_check(ord("A")),
        right: keyboard_check(vk_right) || keyboard_check(ord("D")),
        up:    keyboard_check(vk_up)    || keyboard_check(ord("W")),
        down:  keyboard_check(vk_down)  || keyboard_check(ord("S")),
        fire:  keyboard_check_pressed(vk_space),
        magic: keyboard_check(ord("Z")) || keyboard_check(vk_control),
        item_next: keyboard_check_pressed(ord("X")) || keyboard_check_pressed(vk_shift),
    };
    return _input;
}
