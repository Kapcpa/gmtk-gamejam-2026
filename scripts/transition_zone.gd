extends Area2D

@onready var player: PlayerCharacter = %player
@export_file("*.tscn") var next_scene_path: String

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		if next_scene_path.is_empty():
			return
			
		TransitionManager.transition_to(next_scene_path)
