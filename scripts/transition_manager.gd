extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func transition_to(scene_path: String) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file(scene_path)
	
	var tween_back = create_tween()
	tween_back.tween_property(color_rect, "color:a", 0.0, 0.5)
