extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label

var is_game_over: bool = false

func _process(delta: float) -> void:
	if not is_game_over:
		label.visible = false
		return
	
	label.visible = true
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	if Input.is_action_just_pressed("restart"):
		_restart()
		return
	if Input.is_action_just_pressed("exit"):
		_exit()
		return

func _restart():
	is_game_over = false
	label.visible = false
	
	TransitionManager.level_number = 0
	
	var scene_path = "res://scenes/level0.tscn"
	
	get_tree().change_scene_to_file(scene_path)
	GameManager.stamina_left = GameManager.STAMINA[TransitionManager.level_number]
	GameManager.stamina_start = GameManager.STAMINA[TransitionManager.level_number]
	GameManager.adrenaline = 50.0
	
	var tween_back = create_tween()
	tween_back.tween_property(color_rect, "color:a", 0.0, 0.5)

func _exit():
	get_tree().quit()
