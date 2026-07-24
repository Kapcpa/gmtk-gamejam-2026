extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var level_number: int = 0

func transition_to(scene_path: String) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	level_number += 1
	get_tree().change_scene_to_file(scene_path)
	GameManager.stamina_left = GameManager.STAMINA[level_number]
	GameManager.stamina_start = GameManager.STAMINA[level_number]
	GameManager.adrenaline = 50.0
	
	var tween_back = create_tween()
	tween_back.tween_property(color_rect, "color:a", 0.0, 0.5)
	
	
