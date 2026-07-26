extends Button

func _on_pressed() -> void:
	TransitionManager.transition_to("res://scenes/level0.tscn")
