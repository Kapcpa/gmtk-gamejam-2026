extends CharacterBody2D

class_name EnemyCharacter

enum State {
	IDLE,
	RUNNING,
	ATTACKING,
	HIT,
	DEAD
}

@onready var player: PlayerCharacter = %player
@onready var tilemap: TileMapLayer = %tilemap

@onready var hurtbox: Area2D = $hurtbox
@onready var attack_trigger: Area2D = $trigger

const SPEED = 100.0
const ATTACK_SPEED = 200.0
const ATTACK_FRICTION = 1200
const ATTACK_FORCE = 300

@export var health: float
@export var vision: int = 8

var knockback: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0

var pathfinding_grid: AStarGrid2D
var path: PackedVector2Array

var current_state: State = State.IDLE

func _ready() -> void:
	GameManager.register_enemy(self)
	
	setup_grid()

func setup_grid() -> void:
	pathfinding_grid = AStarGrid2D.new()

	pathfinding_grid.region = tilemap.get_used_rect()
	pathfinding_grid.cell_size = tilemap.tile_set.tile_size
	
	pathfinding_grid.offset = tilemap.tile_set.tile_size / 2.0
	pathfinding_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES 
	
	pathfinding_grid.update()
	
	for cell in tilemap.get_used_cells():
		pathfinding_grid.set_point_solid(cell, true)

func _physics_process(_delta: float) -> void:
	if not player:
		return
	
	match current_state:
		State.IDLE:
			_state_idle(_delta)
		State.RUNNING:
			_state_running(_delta)
		State.ATTACKING:
			_state_attacking(_delta)
		State.HIT:
			_state_hit(_delta)
		State.DEAD:
			_state_dead()
		_:
			pass
	
	move_and_slide()

func _state_idle(_delta: float) -> void:
	velocity = Vector2.ZERO

	var start_cell = tilemap.local_to_map(global_position)
	var target_cell = tilemap.local_to_map(player.global_position)
	
	path = pathfinding_grid.get_point_path(start_cell, target_cell)
	
	if path.size() < vision:
		_change_state(State.RUNNING)
		return

func _state_running(_delta: float) -> void:
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
	attack_timer = 0.25
	
	var direction = global_position.direction_to(player.global_position)
	velocity = direction.normalized() * ATTACK_SPEED
	
	_change_state(State.ATTACKING)

func _state_attacking(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, ATTACK_FRICTION * _delta)
	
	attack_timer -= _delta
	if attack_timer <= 0.0:
		_change_state(State.IDLE)

func _state_hit(_delta: float) -> void:
	velocity = knockback
	knockback = velocity.move_toward(Vector2.ZERO, 750 * _delta) 
	
	if knockback == Vector2.ZERO:
		_change_state(State.IDLE)

func _state_dead() -> void:
	GameManager.unregister_enemy(self)
	queue_free()

func _change_state(new_state: State) -> void:
	current_state = new_state

func take_damage(damage: float, knockback_force: Vector2) -> void:
	if current_state == State.HIT:
		return
	
	health -= damage
	
	knockback = knockback_force
	_change_state(State.HIT)
	
	print(health)
	if health <= 0:
		_change_state(State.DEAD)

func _on_hurtbox_body_entered(body: Node2D) -> void:	
	if body != player or current_state != State.ATTACKING:
		return
	
	var direction = global_position.direction_to(player.global_position)
	player.take_damage(direction * ATTACK_FORCE)

func _on_trigger_body_entered(body: Node2D) -> void:
	if body != player:
		return
	
	_start_attacking()
