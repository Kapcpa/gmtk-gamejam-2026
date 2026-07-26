extends CharacterBody2D

@onready var player: PlayerCharacter = %player
@onready var tilemap: TileMapLayer = %tilemap

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var melee_trigger: Area2D = $melee_trigger
@onready var ranged_trigger: Area2D = $ranged_trigger
@onready var attack: Area2D = $BossAttack

@onready var laser_raycast: RayCast2D = $BossAttack/LaserRaycast
@onready var thick_laser: Line2D = $BossAttack/LaserRaycast/thick_laser
@onready var thin_laser: Line2D = $BossAttack/LaserRaycast/thin_laser

@onready var gun_burst: AudioStreamPlayer2D = $BossAttack/GunBurst
@onready var gun_single: AudioStreamPlayer2D = $BossAttack/GunSingle
@onready var death_sound: AudioStreamPlayer2D = $death_sound
@onready var damage_sound: AudioStreamPlayer2D = $damage_sound

@export var SPEED = 70.0
@export var ATTACK_SPEED = 200.0
@export var RANGED_ATTACK_SPEED = -200.0
@export var CHARGING_ATTACK_SPEED = 1000.0
@export var ATTACK_FRICTION = 1000
@export var CHARGING_TIME = 0.7
@export var MELEE_ATTACK_COOLDOWN: float = 1.0
@export var RANGED_ATTACK_COOLDOWN: float = 3.0
@export var LASER_ATTACK_COOLDOWN: float = 6.0
@export var CHARGING_ATTACK_COOLDOWN: float = 8.0
@export var health: float = 24.0
@export var vision: int = 20
@export var bullets_in_a_row: int = 3
@export var CHARGES_COUNT: int = 3

enum State {
	IDLE,
	RUNNING,
	ATTACKING,
	CHARGING,
	HIT,
	DEAD
}

var validate_raycast: RayCast2D = RayCast2D.new()

var knockback: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var melee_attack_cooldown_timer: float = 0.0
var ranged_attack_cooldown_timer: float = 0.0
var laser_attack_cooldown_timer: float = 0.0
var charging_attack_cooldown_timer: float = 0.0
var will_push_back: bool = false
var charging_timer: float = 0.0
var charging_direction: Vector2 = Vector2.ZERO
var already_shaken: bool = false
var attack_type: String = ""
var charges_left: int = 0

var pathfinding_grid: AStarGrid2D
var path: PackedVector2Array

var current_state: State = State.IDLE

func _ready() -> void:
	GameManager.register_enemy(self)
	setup_grid()
	
	validate_raycast.collision_mask = 1
	add_child(validate_raycast)

func setup_grid() -> void:
	pathfinding_grid = AStarGrid2D.new()

	pathfinding_grid.region = tilemap.get_used_rect()
	pathfinding_grid.cell_size = tilemap.tile_set.tile_size
	
	pathfinding_grid.offset = tilemap.tile_set.tile_size / 2.0
	pathfinding_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES 
	
	pathfinding_grid.update()
	
	for cell in tilemap.get_used_cells():
		pathfinding_grid.set_point_solid(cell, true)

func _physics_process(delta: float) -> void:
	if not player:
		return
	
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.RUNNING:
			_state_running(delta)
		State.ATTACKING:
			_state_attacking(delta)
		State.CHARGING:
			_state_charging(delta)
		State.HIT:
			_state_hit(delta)
		State.DEAD:
			_state_dead(delta)
		_:
			pass
	
	move_and_slide()

func _state_idle(_delta: float) -> void:
	sprite.play("idle")
	velocity = Vector2.ZERO
	melee_attack_cooldown_timer -= _delta
	ranged_attack_cooldown_timer -= _delta
	laser_attack_cooldown_timer -= _delta
	charging_attack_cooldown_timer -= _delta
	
	var start_cell = tilemap.local_to_map(global_position)
	var target_cell = tilemap.local_to_map(player.global_position)
	path = pathfinding_grid.get_point_path(start_cell, target_cell)
	
	if melee_attack_cooldown_timer <= 0.0 and _can_attack_melee():
		attack_type = "melee"
		_start_attacking()
		return
	elif charging_attack_cooldown_timer <= 0.0 and _can_attack_ranged() and 1 < path.size() and path.size() < vision:
		attack_type = "charging"
		_start_attacking()
		return
	elif laser_attack_cooldown_timer <= 0.0 and _can_attack_ranged() and 1 < path.size() and path.size() < vision:
		attack_type = "laser"
		_start_attacking()
		return
	elif ranged_attack_cooldown_timer <= 0.0 and _can_attack_ranged() and 1 < path.size() and path.size() < vision:
		attack_type = "ranged"
		_start_attacking()
		return
	elif not _can_attack_melee() and not _can_attack_ranged() or (melee_attack_cooldown_timer and ranged_attack_cooldown_timer and laser_attack_cooldown_timer and charging_attack_cooldown_timer) and 1 < path.size() and path.size() < vision:
		_change_state(State.RUNNING)

func _state_running(_delta: float) -> void:
	_flip_sprite()
	sprite.play("walk")
	melee_attack_cooldown_timer -= _delta
	ranged_attack_cooldown_timer -= _delta
	laser_attack_cooldown_timer -= _delta
	charging_attack_cooldown_timer -= _delta
	
	if melee_attack_cooldown_timer <= 0.0 and _can_attack_melee():
		attack_type = "melee"
		_start_attacking()
		return
	elif charging_attack_cooldown_timer <= 0.0 and _can_attack_ranged() and 1 < path.size() and path.size() < vision:
		attack_type = "charging"
		_start_attacking()
		return
	elif laser_attack_cooldown_timer <= 0.0 and _can_attack_ranged() and 1 < path.size() and path.size() < vision:
		attack_type = "laser"
		_start_attacking()
		return
	elif ranged_attack_cooldown_timer <= 0.0 and _can_attack_ranged() and 1 < path.size() and path.size() < vision:
		attack_type = "ranged"
		_start_attacking()
		return
	elif not _can_attack_melee() and not _can_attack_ranged() or (melee_attack_cooldown_timer and ranged_attack_cooldown_timer and laser_attack_cooldown_timer and charging_attack_cooldown_timer) and 1 < path.size() and path.size() < vision:
		pass
	
	var start_cell = tilemap.local_to_map(global_position)
	var target_cell = tilemap.local_to_map(player.global_position)
	
	path = pathfinding_grid.get_point_path(start_cell, target_cell)
	
	if path.size() <= 1:
		_change_state(State.IDLE)
		return
	
	var next_point = path[1]
	var direction = global_position.direction_to(next_point)
	
	velocity = direction * SPEED

func _start_attacking() -> void:
	if bullets_in_a_row != 0:
		attack_timer = bullets_in_a_row/10.0
	else:
		attack_timer = 0.25
	
	if attack_type == "ranged":
		var direction = global_position.direction_to(player.global_position)
		velocity = direction.normalized() * RANGED_ATTACK_SPEED
		_change_state(State.ATTACKING)
		return
	if attack_type == "charging":
		charging_timer = CHARGING_TIME
		charging_direction = Vector2.ZERO
		charges_left = CHARGES_COUNT
		_change_state(State.CHARGING)
		return
	if attack_type == "melee":
		charging_timer = CHARGING_TIME
		_change_state(State.CHARGING)
		return
	if attack_type == "laser":
		charging_timer = CHARGING_TIME
		_change_state(State.CHARGING)
		return

func _state_attacking(_delta: float) -> void:
	_flip_sprite()
	
	if attack_type == "ranged":
		velocity = velocity.move_toward(Vector2.ZERO, ATTACK_FRICTION * _delta)
		attack.attack_ranged(player, bullets_in_a_row)
		ranged_attack_cooldown_timer = RANGED_ATTACK_COOLDOWN
		print("Boss used a gun")
	if attack_type == "charging":
		attack.attack_melee(player)
		charging_attack_cooldown_timer = CHARGING_ATTACK_COOLDOWN
		print("Boss charged")
		charges_left -= 1
	if attack_type == "melee":
		attack.attack_melee(player)
		melee_attack_cooldown_timer = MELEE_ATTACK_COOLDOWN
		print("Boss punched")
	if attack_type == "laser":
		attack.attack_laser(player)
		laser_attack_cooldown_timer = LASER_ATTACK_COOLDOWN
		print("Boss used a laser")
	
	attack_timer -= _delta
	melee_attack_cooldown_timer -= _delta
	ranged_attack_cooldown_timer -= _delta
	laser_attack_cooldown_timer -= _delta
	charging_attack_cooldown_timer -= _delta
	if attack_timer <= 0.0:
		attack.reset()
		if attack_type == "charging":
			if not charges_left:
				attack_type = ""
				_change_state(State.IDLE)
				return
			elif charging_attack_cooldown_timer <= 0.0:
				charging_timer = CHARGING_TIME
				_change_state(State.CHARGING)
				return
		attack_type = ""
		_change_state(State.IDLE)

func _state_charging(_delta: float) -> void:
	sprite.play("telegraph")
	charging_timer -= _delta
	velocity = velocity.move_toward(Vector2.ZERO, ATTACK_FRICTION * _delta)
	
	if attack_type == "charging" and charges_left:
		if charging_direction == Vector2.ZERO:
			charging_direction = global_position.direction_to(player.global_position)
		if charging_timer <= 0.0:
			var dash_right: GPUParticles2D = $dash_right
			dash_right.restart()
			velocity = charging_direction.normalized() * CHARGING_ATTACK_SPEED
			_change_state(State.ATTACKING)
			charging_direction = Vector2.ZERO
			
	if attack_type == "melee" and charging_timer <= 0.0:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction.normalized() * ATTACK_SPEED
		_change_state(State.ATTACKING)
	
	if attack_type == "laser" and charging_timer <= 0.0:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction.normalized() * RANGED_ATTACK_SPEED
		_change_state(State.ATTACKING)

func _state_hit(_delta: float) -> void:
	velocity = knockback
	knockback = velocity.move_toward(Vector2.ZERO, 750 * _delta) 
	
	if knockback == Vector2.ZERO:
		_change_state(State.IDLE)

func _state_dead(_delta: float) -> void:	
	if death_sound.playing:
		if death_sound.get_playback_position() > 0.8:
			sprite.visible = false
		return
	
	GameManager.unregister_enemy(self)
	queue_free()

func _can_attack_melee() -> bool:
	if player in melee_trigger.get_overlapping_bodies():
		validate_raycast.target_position = player.position - position
		validate_raycast.force_raycast_update()
		
		if validate_raycast.is_colliding():
			return false
		
		return true
	
	return false

func _can_attack_ranged() -> bool:
	if player in ranged_trigger.get_overlapping_bodies():
		validate_raycast.target_position = player.position - position
		validate_raycast.force_raycast_update()
		
		if validate_raycast.is_colliding():
			return false
		
		return true
	
	return false

func _change_state(new_state: State) -> void:
	current_state = new_state

func take_damage(damage: float, knockback_force: Vector2) -> void:
	if current_state in [State.HIT, State.DEAD]:
		return
	
	if damage > 0:
		damage_sound.play()
	
	health -= damage
	
	knockback = knockback_force
	_change_state(State.HIT)
	
	if health <= 0:
		death_sound.play()
		knockback = knockback_force * 1.5
		_change_state(State.DEAD)

func _flip_sprite() -> void:
	var direction = global_position.direction_to(player.global_position)
	sprite.flip_h = direction.x < 0
