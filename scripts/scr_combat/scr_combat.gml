/// @description Combat functions

/// @function combat_player_hit(damage)
/// @description Handle player taking damage
function combat_player_hit(damage) {
    if (global.player == noone) return;
    if (global.player.invulnerable_timer > 0) return;

    global.health -= damage;
    if (global.health <= 0) {
        global.health = 0;
        // TODO: death sequence
        show_debug_message("PLAYER DIED");
    }

    global.player.invulnerable_timer = 60; // ~1 second at 60fps
}

/// @function combat_enemy_hit(enemy_inst, damage)
/// @description Handle enemy taking damage from hammer
function combat_enemy_hit(enemy_inst, damage) {
    with (enemy_inst) {
        health -= damage;
        vulnerable_timer = 10; // flash

        if (health <= 0) {
            is_dead = true;
            // Award score based on rating
            if (variable_instance_exists(id, "actor_def") && actor_def != undefined) {
                global.score = min(global.score + actor_def.rating, MAX_SCORE);
            }
            instance_destroy();
        }
    }
}
