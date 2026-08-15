/// @description The DOS renderer uses actor.show to blink a damaged actor.
/// actor.vunerable is a separate immunity timer: mushrooms deliberately keep
/// it at five while resting and must remain visible during that whole phase.
if (damage_flash_timer > 0 && (damage_flash_timer mod 4) < 2) return;
draw_self();
