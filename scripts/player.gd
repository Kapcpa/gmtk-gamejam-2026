extends CharacterBody2D

class_name PlayerCharacter

@onready var melee_hitbox: RayCast2D = $melee_hitbox
@onready var debug_melee: Line2D = $melee_hitbox/debug_melee

@onready var throw_hitbox: RayCast2D = $throw_hitbox
@onready var debug_throw: Line2D = $throw_hitbox/debug_throw

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

enum State {
	IDLE,
	RUNNING,
	DASHING,
	ATTACKING,
	GRAPPLED,
	GRAPPLING,
	HIT,
	DEAD
}

const SPEED = 200.0
const MELEE_RANGE = 32.0
const MELEE_SPEED = 300
const MELEE_FRICTION = 1200
const MELEE_FORCE = 300
const THROW_RANGE = 80.0
const GRAPPLE_VELOCITY = 500
const DASH_VELOCITY = 400
const DASH_TIME = 0.2

var current_state: State = State.IDLE
var attack_timer: float = 0.5  # probably will be removed since we can just check if attack animation ended or not
var hit_enemies: Array[EnemyCharacter] = []
var dash_timer: float = DASH_TIME

var kunai_target: EnemyCharacter = null
var validate_raycast: RayCast2D = RayCast2D.new()

var animation_direction: Vector2 = Vector2.ZERO

var knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	validate_raycast.collision_mask = 1
	add_child(validate_raycast)

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
		State.GRAPPLED:
			_state_grappled(delta)
		State.GRAPPLING:
			_state_grappling(delta)
		State.HIT:
			_state_hit(delta)
		State.DEAD:
			_state_dead(delta)
	
	move_and_slide()

func _animate(direction: Vector2, action: String = "") -> void:
	if direction:
		animation_direction = direction
	
	if not animation_direction:
		return
	
	var direction_map: Dictionary = {
		Vector2i(0, -1): "up",
		Vector2i(0, 1): "down",
		Vector2i(1, 0): "side",
		Vector2i(1, -1): "side",
		Vector2i(1, 1): "side"
	}
	
	if animation_direction.x:
		sprite.flip_h = animation_direction.x < 0
	
	var threshold = 0.38
	var snap_x = 0
	var snap_y = 0
	
	# snap to 1 or -1 if the vector pulls strongly enough in that direction
	if abs(animation_direction.x) > threshold:
		snap_x = sign(animation_direction.x)
		
	if abs(animation_direction.y) > threshold:
		snap_y = sign(animation_direction.y)
	
	var direction_key = Vector2i(int(abs(snap_x)), int(snap_y))
	
	if direction_map.has(direction_key):
		var animation = direction_map.get(direction_key)
		if action and sprite.sprite_frames.has_animation(animation + "_" + action):
			animation = animation + "_" + action
		
		sprite.play(animation)

func _state_idle(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	_animate(direction)
	
	if direction:
		_change_state(State.RUNNING)
	
	velocity = velocity.move_toward(Vector2.ZERO, 3000 * _delta)
	
	if Input.is_action_just_pressed("attack"):
		_start_attacking()
		return
	if Input.is_action_just_pressed("throw"):
		_kunai_throw()
		return

func _state_running(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	_animate(direction, "run")
	
	if direction:
		velocity = direction * SPEED
	else:
		_change_state(State.IDLE)

	if Input.is_action_just_pressed("attack"):
		_start_attacking()
		return
	if Input.is_action_just_pressed("throw"):
		_kunai_throw()
		return
	if Input.is_action_just_pressed("dash"):
		dash_timer = DASH_TIME
		_change_state(State.DASHING)

func _state_dashing(_delta: float) -> void:
	dash_timer -= _delta
	var dash_direction = velocity.normalized()
	velocity = dash_direction * DASH_VELOCITY
	if kunai_target and not Input.is_action_pressed("throw"):
		_change_state(State.GRAPPLING)
		return
	if dash_timer <= 0.0:
		if kunai_target:
			_change_state(State.GRAPPLED)
		else:
			_change_state(State.IDLE)

func _start_attacking() -> void:
	attack_timer = 0.25
	hit_enemies.clear()
	velocity = melee_hitbox.target_position.normalized() * MELEE_SPEED
	_change_state(State.ATTACKING)

func _state_attacking(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, MELEE_FRICTION * _delta)
	
	_animate(velocity.normalized(), "attack")
	
	if melee_hitbox.is_colliding():
		var _collider = melee_hitbox.get_collider()
		if _collider and _collider.is_in_group("enemies") and _collider not in hit_enemies:
			if _collider.current_state != _collider.State.HIT:
				var attack_force = melee_hitbox.target_position.normalized() * MELEE_FORCE
				_collider.take_damage(1.0, attack_force)
				GameManager.register_hit()
	
	attack_timer -= _delta
	if attack_timer <= 0.0:
		_change_state(State.IDLE)

func _kunai_throw() -> void:
	if throw_hitbox.is_colliding():
		var _collider = throw_hitbox.get_collider()
		
		validate_raycast.target_position = _collider.position - position
		validate_raycast.force_raycast_update()
		
		if not validate_raycast.is_colliding():
			kunai_target = _collider
			
			var attack_force = throw_hitbox.target_position.normalized() * MELEE_FORCE
			_collider.take_damage(0.0, attack_force)  # don't deal damage in the beginning?
			GameManager.register_hit()
			
			_change_state(State.GRAPPLED)

func _state_grappled(_delta: float) -> void:
	if not kunai_target:
		_change_state(State.IDLE)
		return
	
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction:
		velocity = direction * SPEED
		_animate(direction, "run")
		if Input.is_action_just_pressed("dash"):
			dash_timer = DASH_TIME
			_change_state(State.DASHING)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 3000 * _delta)
		_animate(direction)
	
	validate_raycast.target_position = kunai_target.position - position
	validate_raycast.force_raycast_update()
		
	if validate_raycast.is_colliding():
		_change_state(State.IDLE)		
		validate_raycast.target_position = Vector2.ZERO
		
		return
	
	if Input.is_action_just_released("throw"):
		_change_state(State.GRAPPLING)
	
func _state_grappling(_delta: float) -> void:
	if not kunai_target:
		_change_state(State.IDLE)
		return
	
	var grapple_end = kunai_target.position + throw_hitbox.target_position.normalized() * 32.0
	var grapple_direction = (grapple_end - position).normalized()
	velocity = grapple_direction * GRAPPLE_VELOCITY
	
	var world_collision = false
	
	for index in range(get_slide_collision_count()):
		var _collision = get_slide_collision(index)
		
		if grapple_direction.dot(_collision.get_normal()) < -0.71:
			world_collision = true
			break
	
	if position.distance_to(grapple_end) <= 8.0 or world_collision:
		velocity /= 1.5
		
		kunai_target = null
		
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
	var direction = to_local(get_global_mouse_position())
	
	if direction != Vector2.ZERO:
		melee_hitbox.target_position = direction.normalized() * MELEE_RANGE
		debug_melee.points = [
			Vector2.ZERO, melee_hitbox.target_position
		]
		
		throw_hitbox.target_position = direction.normalized() * THROW_RANGE
		debug_throw.points = [
			Vector2.ZERO, throw_hitbox.target_position
		]
		
func take_damage(knockback_force: Vector2) -> void:
	if current_state == State.HIT:
		return
	
	GameManager.reset_combo()
	
	kunai_target = null
	
	knockback = knockback_force
	_change_state(State.HIT)
