extends Control

func _on_button_pressed() -> void:
	print("pressed")
	TransitionManager.transition_to("res://scenes/level0.tscn")
