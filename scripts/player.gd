extends CharacterBody2D

@onready var melee_hitbox: RayCast2D = $melee_hitbox
@onready var debug_melee: Line2D = $melee_hitbox/debug_melee

const SPEED = 200.0
const MELEE_RANGE = 32.0

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED
	move_and_slide()

func _process(delta: float) -> void:
	var melee_direction = to_local(get_global_mouse_position())
	
	if melee_direction != Vector2.ZERO:
		melee_hitbox.target_position = melee_direction.normalized() * MELEE_RANGE
		debug_melee.points = [
			Vector2.ZERO, melee_hitbox.target_position
		]
		
	if Input.is_action_just_pressed("attack") and melee_hitbox.is_colliding():
		if melee_hitbox.get_collider().has_method("take_damage"):
			melee_hitbox.get_collider().take_damage(1.0)
