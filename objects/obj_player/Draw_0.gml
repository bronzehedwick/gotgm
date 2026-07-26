/// @description Draw player
// Flash when invulnerable
if (invulnerable_timer > 0 && (invulnerable_timer mod 4) < 2) {
    // Skip drawing for flash effect
    return;
}
draw_self();
