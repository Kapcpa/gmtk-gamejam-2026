extends CharacterBody2D

@onready var melee_hitbox: RayCast2D = $melee_hitbox
@onready var debug_melee: Line2D = $melee_hitbox/debug_melee

enum State {
	IDLE,
	RUNNING,
	DASHING,
	ATTACKING,
	HIT,
	DEAD
}

var current_state: State = State.IDLE

const SPEED = 200.0
const MELEE_RANGE = 32.0

func _physics_process(delta: float) -> void:	
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.RUNNING:
			_state_running(delta)
		State.DASHING:
			_state_dashing(delta)
		State.ATTACKING:
			_state_attacking(delta)
		State.HIT:
			_state_hit(delta)
		State.DEAD:
			_state_dead(delta)
	
	move_and_slide()

func _process(delta: float) -> void:
	pass

func _state_idle(_delta: float) -> void:
	velocity = Vector2(move_toward(velocity.x, 0, SPEED), move_toward(velocity.y, 0, SPEED))
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction:
		_change_state(State.RUNNING)

func _state_running(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction:
		velocity = direction * SPEED
	else:
		_change_state(State.IDLE)
	

func _state_dashing(_delta: float) -> void:
	pass

func _state_attacking(_delta: float) -> void:
	pass

func _state_hit(_delta: float) -> void:
	pass

func _state_dead(_delta: float) -> void:
	pass

func _change_state(new_state: State):
	current_state = new_state

func _aim():
	var melee_direction = to_local(get_global_mouse_position())
	
	if melee_direction != Vector2.ZERO:
		melee_hitbox.target_position = melee_direction.normalized() * MELEE_RANGE
		debug_melee.points = [
			Vector2.ZERO, melee_hitbox.target_position
		]
		
	if Input.is_action_just_pressed("attack") and melee_hitbox.is_colliding():
		if melee_hitbox.get_collider().has_method("take_damage"):
			melee_hitbox.get_collider().take_damage(1.0)
