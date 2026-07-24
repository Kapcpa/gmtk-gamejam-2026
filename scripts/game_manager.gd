extends Node

signal combo_updated(new_combo: int)
signal combo_dropped
signal room_cleared 

const COMBO_WINDOW: float = 2.5
const SLOWMO_TIME: float = 0.3
const SHAKE_STRENGTH_CONST: float = 5.0

var player: PlayerCharacter
var active_enemies: Array[EnemyCharacter] = []
var shake_strength: float = 0.0
var camera: Camera2D
var slowmo_timer: float = 0.0
var shake_fade_out_speed: float = 0.0

var combo_count: int = 0
var combo_time_left: float = 0.0

func _process(delta: float) -> void:
	if combo_count > 0:
		combo_time_left -= delta
		if combo_time_left <= 0.0:
			reset_combo()
	
	if shake_strength >= 0.0:
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		shake_strength = lerpf(shake_strength, 0.0, shake_fade_out_speed)
	
	if slowmo_timer > 0.0:
		slowmo_timer -= delta * 1/Engine.time_scale
	else:
		Engine.time_scale = 1.0

func register_hit() -> void:
	combo_count += 1
	combo_time_left = COMBO_WINDOW
	_apply_shake(3, 10)
	combo_updated.emit(combo_count)

func on_player_dodged_a_bullet() -> void:
	Engine.time_scale = 0.3
	slowmo_timer = SLOWMO_TIME
	combo_count += 1
	combo_time_left = COMBO_WINDOW
	combo_updated.emit(combo_count)

func reset_combo() -> void:
	if combo_count > 0:
		combo_count = 0
		combo_dropped.emit()
		_apply_shake(3, 10)

func register_player(player_node: PlayerCharacter) -> void:
	player = player_node

func register_enemy(enemy_node: EnemyCharacter) -> void:
	if not enemy_node in active_enemies:
		active_enemies.append(enemy_node)

func unregister_enemy(enemy_node: Node2D) -> void:
	if enemy_node in active_enemies:
		active_enemies.erase(enemy_node)
		
		# check if wave is complete at the end?
		if active_enemies.is_empty():
			room_cleared.emit()

func _apply_shake(strength, speed) -> void:
	shake_strength = strength
	shake_fade_out_speed = speed
