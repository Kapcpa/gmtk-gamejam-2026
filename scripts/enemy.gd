extends CharacterBody2D

class_name EnemyCharacter

enum State {
	IDLE,
	RUNNING,
	RUNNING_AWAY,
	ATTACKING,
	CHARGING,
	HIT,
	DEAD
}

@onready var player: PlayerCharacter = %player
@onready var tilemap: TileMapLayer = %tilemap
@onready var attack_trigger: Area2D = $trigger
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var SPEED = 100.0
@export var ATTACK_SPEED = 200.0
@export var ATTACK_FRICTION = 1200
@export var CHARGING_TIME = 0.5
@export var ATTACK_COOLDOWN: float = 1.0
@export var health: float
@export var vision: int = 20
@export var attack: Node
@export var bullets_in_a_row: int
@export var enemy_type: String

var validate_raycast: RayCast2D = RayCast2D.new()

var knockback: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var will_push_back: bool = false
var charging_timer: float = 0.0
var charging_direction: Vector2 = Vector2.ZERO
var already_shaken: bool = false

var pathfinding_grid: AStarGrid2D
var path: PackedVector2Array

var gun_sprite: Sprite2D
var default_gun_sprite_position: Vector2

var current_state: State = State.IDLE

@onready var damage_sound: AudioStreamPlayer2D = $damage_sound
@onready var death_sound: AudioStreamPlayer2D = $death_sound

func _ready() -> void:
	GameManager.register_enemy(self)
	setup_grid()
	
	validate_raycast.collision_mask = 1
	add_child(validate_raycast)
	
	if enemy_type == "ranged":
		gun_sprite = $GunSprite
		default_gun_sprite_position = gun_sprite.position

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
		State.RUNNING_AWAY:
			_state_running_away(delta)
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
	
	if enemy_type == "ranged":
		if sprite.flip_h:
			gun_sprite.position.x = default_gun_sprite_position.x * -1
		else:
			gun_sprite.position.x = default_gun_sprite_position.x
	
	move_and_slide()

func _state_idle(_delta: float) -> void:
	if enemy_type == "ranged":
		attack.position = gun_sprite.position
		gun_sprite.rotation = PI/2
		if (sprite.is_playing() and sprite.animation == "attack_no_gun"):
			pass
	else:
		sprite.play("idle")
		
	velocity = Vector2.ZERO
	attack_cooldown_timer -= _delta
	var start_cell = tilemap.local_to_map(global_position)
	var target_cell = tilemap.local_to_map(player.global_position)
	path = pathfinding_grid.get_point_path(start_cell, target_cell)
	
	if attack_cooldown_timer <= 0.0 and _can_attack():
		if  1 < path.size() and path.size() < 7 and enemy_type == "ranged":
			_change_state(State.RUNNING_AWAY)
			return
		if path.size() <= 1 and enemy_type == "ranged":
			will_push_back = true
			
		_start_attacking()
		return
	elif not _can_attack() and 1 < path.size() and path.size() < vision:
		_change_state(State.RUNNING)
		return

func _state_running(_delta: float) -> void:
	_flip_sprite()
	if enemy_type == "charging":
		sprite.play("idle")
	else:
		sprite.play("walk")
	attack_cooldown_timer -= _delta
	if attack_cooldown_timer <= 0.0 and _can_attack():
		_start_attacking()
		return
	
	var start_cell = tilemap.local_to_map(global_position)
	var target_cell = tilemap.local_to_map(player.global_position)
	
	path = pathfinding_grid.get_point_path(start_cell, target_cell)
	if enemy_type == "charging" and path.size() <= 5 and _can_attack():
		_change_state(State.IDLE)
		return
	if path.size() <= 1:
		_change_state(State.IDLE)
		return
	
	var next_point = path[1]
	var direction = global_position.direction_to(next_point)
	
	velocity = direction * SPEED

func _state_running_away(_delta) -> void:
	gun_sprite.hide()
	sprite.play("walk")
	attack_cooldown_timer -= _delta
	
	if get_slide_collision_count() > 0:
		_start_attacking()
	
	var start_cell = tilemap.local_to_map(global_position)
	var target_cell = tilemap.local_to_map(player.global_position)
	
	path = pathfinding_grid.get_point_path(start_cell, target_cell)
	
	if path.size() <= 1 or path.size() >= 8:
		_change_state(State.IDLE)
		return
	
	var next_point = path[1]
	var direction = global_position.direction_to(next_point)
	
	sprite.flip_h = direction.x > 0
	
	velocity = direction * SPEED * -1

func _can_attack() -> bool:
	if player in attack_trigger.get_overlapping_bodies():
		validate_raycast.target_position = player.position - position
		validate_raycast.force_raycast_update()
		
		if validate_raycast.is_colliding():
			if enemy_type == "ranged":
				gun_sprite.hide()
			return false
			
		if enemy_type == "ranged":
			gun_sprite.rotation = get_angle_to(player.global_position)
			gun_sprite.show()
		return true
		
	if enemy_type == "ranged":
		gun_sprite.hide()
	return false


func _start_attacking() -> void:
	if bullets_in_a_row == 0 or will_push_back:
		attack_timer = 0.25
	else:
		attack_timer = bullets_in_a_row/10.0
		
	attack_cooldown_timer = ATTACK_COOLDOWN
	
	if enemy_type == "ranged":
		var direction = global_position.direction_to(player.global_position)
		velocity = direction.normalized() * ATTACK_SPEED
	elif enemy_type == "charging":
		charging_timer = CHARGING_TIME
		charging_direction = Vector2.ZERO
		_change_state(State.CHARGING)
		return
	elif enemy_type == "melee":
		charging_timer = CHARGING_TIME
		_change_state(State.CHARGING)
		return
	
	_change_state(State.ATTACKING)

func _state_attacking(_delta: float) -> void:
	_flip_sprite()
	velocity = velocity.move_toward(Vector2.ZERO, ATTACK_FRICTION * _delta)
	
	if will_push_back:
		attack.push_back(player)
		will_push_back = false
		_change_state(State.IDLE)
		return
	elif enemy_type == "ranged":
		if sprite.animation != "attack_no_gun":
			sprite.play("attack_no_gun")
		attack.attack(player, bullets_in_a_row)
	elif enemy_type == "charging":
		sprite.play("attack")
		if get_slide_collision_count() > 0:
			GameManager._apply_shake(4, 10)
		attack.attack(player)
	elif enemy_type == "melee":
		sprite.play("attack")
		attack.attack(player)
	
	attack_timer -= _delta
	attack_cooldown_timer -= _delta
	if attack_timer <= 0.0:
		attack.reset()
		_change_state(State.IDLE)

func _state_charging(_delta: float) -> void:
	sprite.play("telegraph")
	charging_timer -= _delta
	velocity = velocity.move_toward(Vector2.ZERO, ATTACK_FRICTION * _delta)
	if enemy_type == "charging":
		if charging_direction == Vector2.ZERO:
			charging_direction = global_position.direction_to(player.global_position)
		if charging_timer <= 0.0:
			var dash_right: GPUParticles2D = $dash_right
			dash_right.restart()
			velocity = charging_direction.normalized() * ATTACK_SPEED
			_change_state(State.ATTACKING)
	if enemy_type == "melee" and charging_timer <= 0.0:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction.normalized() * ATTACK_SPEED
		_change_state(State.ATTACKING)

func _state_hit(_delta: float) -> void:
	velocity = knockback
	knockback = velocity.move_toward(Vector2.ZERO, 750 * _delta) 
	
	if knockback == Vector2.ZERO:
		_change_state(State.IDLE)

func _state_dead(_delta: float) -> void:
	if (enemy_type == "ranged" or enemy_type == "melee") and not (sprite.is_playing() and sprite.animation == "death") and not (sprite.animation == "death_2" or  sprite.animation == "death_3"):
		sprite.play("death")
		_flip_sprite()
		
	velocity = knockback
	knockback = velocity.move_toward(Vector2.ZERO, 750 * _delta)
	
	if (enemy_type == "ranged" or enemy_type == "melee") and get_slide_collision_count() > 0:
		var last_slide_collision_normal = get_last_slide_collision().get_normal()
		if last_slide_collision_normal.y > 0.0:
			sprite.play("death_3")
		else:
			sprite.play("death_2")
		sprite.flip_h = last_slide_collision_normal.x < 0
		
		if not already_shaken:
			GameManager._apply_shake(3, 10)
			already_shaken = true
	
	if death_sound.playing:
		if death_sound.get_playback_position() > 0.8:
			sprite.visible = false
			if enemy_type == "ranged":
				gun_sprite.visible = false
		return
	
	GameManager.unregister_enemy(self)
	queue_free()

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
