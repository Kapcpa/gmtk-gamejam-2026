extends CharacterBody2D

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

const SPEED = 100.0

@export var health: float
@export var vision: int = 8

var knockback: Vector2 = Vector2.ZERO
var invincible_time: float = 0.0

var pathfinding_grid: AStarGrid2D
var path: PackedVector2Array

var current_state: State = State.IDLE

func _ready() -> void:
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
		
func _state_attacking(_delta: float) -> void:
	if hurtbox.body_exited:
		_change_state(State.RUNNING)

	# windup here
	
	var direction = global_position.direction_to(player.global_position)
	player.take_damage(direction)
	

	_change_state(State.RUNNING)

func _state_hit(_delta: float) -> void:
	velocity = knockback
	knockback = Vector2(move_toward(knockback.x, 0, 10), move_toward(knockback.y, 0, 10))
	invincible_time -= _delta
	if invincible_time <= 0.0:
		_change_state(State.IDLE)
	

func _change_state(new_state: State) -> void:
	current_state = new_state

func take_damage(damage: float, knockback_direction: Vector2) -> void:
	print("elvispresley")
	invincible_time = 0.6
	if current_state == State.HIT:
		return
	
	health -= damage
	
	knockback = knockback_direction * 200
	_change_state(State.HIT)
	
	print(health)
	if health <= 0:
		_change_state(State.DEAD)
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body != player:
		return
		
	_change_state(State.ATTACKING)
