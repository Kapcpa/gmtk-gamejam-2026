extends Node2D

@export var bullet_scene: PackedScene

@onready var hurtbox: Area2D = $hurtbox
@onready var gun_burst: AudioStreamPlayer2D = $GunBurst
@onready var gun_single: AudioStreamPlayer2D = $GunSingle

var bullets_shot: int = 0
var bullet_cooldown = 0.0

const ATTACK_FORCE = 300

func _process(delta: float) -> void:
	if bullet_cooldown > 0.0:
		bullet_cooldown -= delta

func attack(player: PlayerCharacter, bullets_in_a_row):
	if bullets_shot >= bullets_in_a_row:
		return
	if bullet_cooldown <= 0.0:
		var direction = (player.global_position - global_position).normalized()
		var angle = Vector2(0, -1).angle_to(direction)
		var bullet = bullet_scene.instantiate()
		bullet.rotation = angle
		bullet.global_position = global_position
		bullet.player = player
		var game_manager = get_tree().root.get_child(0)
		
		game_manager.add_child(bullet)
		
		if bullets_in_a_row == 1:
			gun_single.play()
		else:
			gun_burst.play()
		
		bullets_shot += 1
		bullet_cooldown = 0.1

func push_back(player: PlayerCharacter):
	if player in hurtbox.get_overlapping_bodies() and player.current_state not in [player.State.DASHING, player.State.GRAPPLING]:
		var direction = global_position.direction_to(player.global_position)
		player.take_damage(direction * ATTACK_FORCE)

func reset():
	bullets_shot = 0
