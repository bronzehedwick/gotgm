/// @description The DOS renderer uses actor.show to blink a damaged actor.
if (vulnerable_timer > 0 && (vulnerable_timer mod 4) < 2) return;
draw_self();
