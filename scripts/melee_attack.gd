extends Area2D

const ATTACK_FORCE = 300

func attack(player: PlayerCharacter):
	if player in get_overlapping_bodies() and player.current_state not in [player.State.DASHING, player.State.GRAPPLING]:
		var direction = global_position.direction_to(player.global_position)
		player.take_damage(direction * ATTACK_FORCE)


func reset():
	pass
