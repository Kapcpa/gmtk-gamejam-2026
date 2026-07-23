extends CharacterBody2D

class_name PlayerCharacter

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
var attack_timer: float = 0.5

const SPEED = 200.0
const MELEE_RANGE = 32.0

var knockback: Vector2 = Vector2.ZERO

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
	
	_aim()
	
	move_and_slide()

func _process(delta: float) -> void:
	pass

func _state_idle(_delta: float) -> void:
	velocity = Vector2(move_toward(velocity.x, 0, SPEED), move_toward(velocity.y, 0, SPEED))
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction:
		_change_state(State.RUNNING)
	if Input.is_action_just_pressed("attack"):
		_aim()
		attack_timer = 0.5
		_change_state(State.ATTACKING)

func _state_running(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction:
		velocity = direction * SPEED
	else:
		_change_state(State.IDLE)
	if Input.is_action_just_pressed("attack"):
		attack_timer = 0.5
		_change_state(State.ATTACKING)

func _state_dashing(_delta: float) -> void:
	pass

func _state_attacking(_delta: float) -> void:
	if melee_hitbox.is_colliding():
		var _collider = melee_hitbox.get_collider()
		if _collider and _collider.is_in_group("enemies"):
			if _collider.current_state != _collider.State.HIT:
				melee_hitbox.get_collider().take_damage(1.0, melee_hitbox.target_position.normalized())
	attack_timer -= _delta
	if attack_timer <= 0.0:
		_change_state(State.IDLE)

func _state_hit(_delta: float) -> void:
	velocity = knockback
	knockback = Vector2(move_toward(knockback.x, 0, 10), move_toward(knockback.y, 0, 10))
	
	if knockback == Vector2.ZERO:
		_change_state(State.IDLE)

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
		
func take_damage(knockback_direction: Vector2) -> void:
	if current_state == State.HIT:
		return
	
	knockback = knockback_direction * 200
	_change_state(State.HIT)
