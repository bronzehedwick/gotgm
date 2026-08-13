/// @description Refresh editable room data after all room layers exist.
level_enter_current_room();
if (!global.death_active && global.player != noone && instance_exists(global.player)) {
    checkpoint_save();
}
