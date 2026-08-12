/// @description Hammer initialization
facing = Dir.DOWN;
move_speed = 4;
returning = false;
outbound_timer = 45;
return_axis_toggle = false;
damage = global.hammer_damage;

sprite_index = (damage <= 10) ? spr_actor_103_hammeri
    : ((damage <= 13) ? spr_actor_104_hammers : spr_actor_113_hammerg);
hammer_anim_frame = 0;
hammer_anim_timer = 0;
image_index = facing * 4;
image_speed = 0;
