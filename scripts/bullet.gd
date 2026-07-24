extends CharacterBody2D

@export var SPEED = 250
const BULLET_FORCE = 200

@onready var hurtbox: Area2D = $Area2D
var player: PlayerCharacter
var already_dodged: bool = false

signal player_dodged_a_bullet

func _ready() -> void:
	velocity = Vector2(0, -SPEED).rotated(rotation)

func _physics_process(delta: float) -> void:
	if get_slide_collision_count() > 0:
		queue_free()
	elif player and player in hurtbox.get_overlapping_bodies():
		if player.current_state not in [player.State.DASHING, player.State.GRAPPLING]:
			player.take_damage(BULLET_FORCE * velocity.normalized())
			queue_free()
		else:
			if not already_dodged:
				already_dodged = true
				player_dodged_a_bullet.emit()
			
	
	move_and_slide()
