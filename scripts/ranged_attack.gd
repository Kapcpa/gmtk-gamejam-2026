extends Node2D

@export var bullet_scene: PackedScene

# 
var bullet_shot = false

const ATTACK_FORCE = 300

func attack(player: PlayerCharacter):
	if bullet_shot:
		return
	
	var direction = (player.global_position - global_position).normalized()
	var angle = Vector2(0, -1).angle_to(direction)
	var bullet = bullet_scene.instantiate()
	bullet.rotation = angle
	bullet.global_position = global_position
	bullet.player = player
	var game_manager = get_tree().root.get_child(0)
	
	game_manager.add_child(bullet)
	
	bullet_shot = true


func reset():
	bullet_shot = false
