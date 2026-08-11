/// @description Input handling

/// @function input_check()
/// @description Check and return current input state as a struct
function input_check() {
    if (global.demo_active) {
        if (global.demo_data == -1) {
            global.demo_data = buffer_load("data/demo.got");
        }
        if (global.demo_data == -1
        || global.demo_index >= buffer_get_size(global.demo_data)) {
            menu_show_title();
            return {
                left: false, right: false, up: false, down: false,
                fire: false, magic: false, item_next: false,
            };
        }

        // DEMO is the original 3,600-tick stream of PC keyboard scan-code
        // press/release events consumed by demo_key_set().
        var _scan = buffer_peek(global.demo_data, global.demo_index, buffer_u8);
        global.demo_index++;
        if (_scan != 0) {
            var _pressed = ((_scan & $80) == 0);
            var _key = _scan & $7f;
            switch (_key) {
                case 72: global.demo_up = _pressed; break;
                case 80: global.demo_down = _pressed; break;
                case 75: global.demo_left = _pressed; break;
                case 77: global.demo_right = _pressed; break;
                case 56: global.demo_fire = _pressed; break;
                case 29: global.demo_magic = _pressed; break;
            }
        }

        return {
            left: global.demo_left,
            right: global.demo_right,
            up: global.demo_up,
            down: global.demo_down,
            fire: global.demo_fire,
            magic: global.demo_magic,
            item_next: false,
        };
    }

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
