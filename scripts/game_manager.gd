extends Node

# Signals let your UI easily update without constantly checking variables
signal combo_updated(new_combo: int)
signal combo_dropped
signal room_cleared 

# Entity references
var player: PlayerCharacter
var active_enemies: Array[EnemyCharacter] = []

# Combo tracking
var combo_count: int = 0
var combo_time_left: float = 0.0
const COMBO_WINDOW: float = 2.5 # How many seconds the player has to land the next hit

func _process(delta: float) -> void:
	if combo_count > 0:
		combo_time_left -= delta
		if combo_time_left <= 0.0:
			reset_combo()

func register_hit() -> void:
	combo_count += 1
	combo_time_left = COMBO_WINDOW
	combo_updated.emit(combo_count)
	# Optional: You can scale damage or speed based on combo_count here
	
func reset_combo() -> void:
	if combo_count > 0:
		combo_count = 0
		combo_dropped.emit()

# --- ENTITY MANAGEMENT ---

func register_player(player_node: PlayerCharacter) -> void:
	player = player_node

func register_enemy(enemy_node: EnemyCharacter) -> void:
	if not enemy_node in active_enemies:
		active_enemies.append(enemy_node)

func unregister_enemy(enemy_node: Node2D) -> void:
	if enemy_node in active_enemies:
		active_enemies.erase(enemy_node)
		
		# Example of a global manager feature: check if wave is complete
		if active_enemies.is_empty():
			room_cleared.emit()
