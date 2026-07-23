extends CharacterBody2D

class_name PlayerCharacter

@onready var melee_hitbox: RayCast2D = $melee_hitbox
@onready var debug_melee: Line2D = $melee_hitbox/debug_melee
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

enum State {
	IDLE,
	RUNNING,
	DASHING,
	ATTACKING,
	HIT,
	DEAD
}

const SPEED = 200.0
const MELEE_RANGE = 32.0
const MELEE_SPEED = 300
const MELEE_FRICTION = 1200
const MELEE_FORCE = 300
const DASH_VELOCITY = 800
const DASH_TIME = 0.2

var current_state: State = State.IDLE
var attack_timer: float = 0.5  # probably will be removed since we can just check if attack animation ended or not
var hit_enemies: Array[Node2D] = []
var dash_timer: float = DASH_TIME

var knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	GameManager.register_player(self)

func _physics_process(delta: float) -> void:	
	if current_state in [State.IDLE, State.RUNNING, State.DASHING]:
		_aim()
	
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

func _animate(direction: Vector2) -> void:
	if not direction:
		return  # just change action / animate, no direction changing
	
	var animation_map: Dictionary = {
		Vector2i(0, -1): "up",
		Vector2i(0, 1): "down",
		Vector2i(1, 0): "side",
		Vector2i(1, -1): "side_up",
		Vector2i(1, 1): "side_down"
	}
	
	if direction.x:
		sprite.flip_h = direction.x < 0
	
	var threshold = 0.38
	var snap_x = 0
	var snap_y = 0
	
	# snap to 1 or -1 if the vector pulls strongly enough in that direction
	if abs(direction.x) > threshold:
		snap_x = sign(direction.x)
		
	if abs(direction.y) > threshold:
		snap_y = sign(direction.y)
	
	var direction_key = Vector2i(int(abs(snap_x)), int(snap_y))
	
	if animation_map.has(direction_key):
		sprite.play(animation_map.get(direction_key))

func _state_idle(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	_animate(direction)
	
	if direction:
		_change_state(State.RUNNING)
	
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 10 * _delta)
	
	if Input.is_action_just_pressed("attack"):
		_start_attacking()
		return
	if Input.is_action_just_pressed("dash"):
		dash_timer = DASH_TIME
		_change_state(State.DASHING)

func _state_running(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	_animate(direction)
	
	if direction:
		velocity = direction * SPEED
	else:
		_change_state(State.IDLE)
		
	if Input.is_action_just_pressed("attack"):
		_start_attacking()
		return
	if Input.is_action_just_pressed("dash"):
		dash_timer = DASH_TIME
		_change_state(State.DASHING)

func _state_dashing(_delta: float) -> void:
	collision_layer = 0
	dash_timer -= _delta
	var dash_direction = to_local(get_global_mouse_position()).normalized()	
	velocity = velocity.move_toward(dash_direction * DASH_VELOCITY, 2000 * _delta)
	if dash_timer <= 0.0:
		collision_layer = 2
		_change_state(State.IDLE)

func _start_attacking() -> void:
	attack_timer = 0.25
	hit_enemies.clear()
	velocity = melee_hitbox.target_position.normalized() * MELEE_SPEED
	_change_state(State.ATTACKING)

func _state_attacking(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, MELEE_FRICTION * _delta)
	
	_animate(velocity.normalized())
	
	if melee_hitbox.is_colliding():
		var _collider = melee_hitbox.get_collider()
		if _collider and _collider.is_in_group("enemies") and _collider not in hit_enemies:
			if _collider.current_state != _collider.State.HIT:
				var attack_force = melee_hitbox.target_position.normalized() * MELEE_FORCE
				melee_hitbox.get_collider().take_damage(1.0, attack_force)
				GameManager.register_hit()
	
	attack_timer -= _delta
	if attack_timer <= 0.0:
		_change_state(State.IDLE)

func _state_hit(_delta: float) -> void:
	velocity = knockback
	knockback = velocity.move_toward(Vector2.ZERO, 750 * _delta) 
	
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
		
func take_damage(knockback_force: Vector2) -> void:
	if current_state == State.HIT:
		return
	
	GameManager.reset_combo()
	
	knockback = knockback_force
	_change_state(State.HIT)
