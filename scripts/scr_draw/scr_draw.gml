/// @description Drawing helpers

function draw_actor_sprite(actor_type_id, dir, frame, ax, ay) {
    draw_self();
}

function draw_pickup(pickup_type, px, py) {
    if (pickup_type <= 0 || pickup_type > 32) return;

    var _idx = pickup_type - 1;
    var _sx = (_idx mod 8) * TILE_W;
    var _sy = (_idx div 8) * TILE_H;
    draw_sprite_part(spr_objects, 0, _sx, _sy, TILE_W, TILE_H, px, py);
}

/// @function draw_original_text_colour(text, x, y, colour, shadow)
/// @description Draw the original DOS font mask in a VGA palette colour
function draw_original_text_colour(text, x, y, colour, shadow) {
    var _text = string(text);
    for (var _index = 1; _index <= string_length(_text); _index++) {
        var _glyph = ord(string_char_at(_text, _index)) - 32;
        if (_glyph >= 0 && _glyph < 94) {
            var _source_x = (_glyph mod 16) * 8;
            var _source_y = (_glyph div 16) * 9;
            if (shadow) {
                draw_sprite_part_ext(spr_font, 0, _source_x, _source_y, 8, 9,
                    x + 1, y + 1, 1, 1, c_black, 1);
            }
            draw_sprite_part_ext(spr_font, 0, _source_x, _source_y, 8, 9,
                x, y, 1, 1, colour, 1);
        }
        x += 8;
    }
}

/// @function draw_original_text(text, x, y)
/// @description HUD text uses the original dark-blue VGA colour
function draw_original_text(text, x, y) {
    draw_original_text_colour(text, x, y, make_colour_rgb(0, 0, 163), false);
}