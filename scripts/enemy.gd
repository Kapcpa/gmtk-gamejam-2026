extends CharacterBody2D

@onready var player: CharacterBody2D = %player
@onready var tilemap: TileMapLayer = %tilemap

const SPEED = 100.0

@export var health: float

var pathfinding_grid: AStarGrid2D
var path: PackedVector2Array

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
		
	var start_cell = tilemap.local_to_map(global_position)
	var target_cell = tilemap.local_to_map(player.global_position)
	
	path = pathfinding_grid.get_point_path(start_cell, target_cell)
	
	if path.size() > 1:
		var next_point = path[1]
		var direction = global_position.direction_to(next_point)
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func take_damage(damage: float) -> void:
	health -= damage
	print(health)
	if health <= 0:
		queue_free()
