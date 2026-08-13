/// @description Draw player
// Flash when invulnerable
if (!global.death_active && invulnerable_timer > 0 && (invulnerable_timer mod 4) < 2) {
    // Skip drawing for flash effect
    return;
}
draw_self();

if (global.shield_on) {
    var _shield_frame = floor(current_time / 90) mod 4;
    draw_sprite(spr_actor_109_shield, _shield_frame, x - 1, y);
}
