extends Area2D

const ATTACK_FORCE = 300

func attack(player: PlayerCharacter):
	if player in get_overlapping_bodies():
		var direction = global_position.direction_to(player.global_position)
		player.take_damage(direction * ATTACK_FORCE)


func reset():
	pass
