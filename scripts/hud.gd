extends CanvasLayer

@onready var combo_label: Label = $combo_debug
@onready var adrenaline_label: Label = $AdrenalineLabel
@onready var kunai_cooldown_label: Label = $KunaiCooldown

var kunai: float = 0.0

func _ready() -> void:
	GameManager.combo_updated.connect(_on_combo_updated)
	GameManager.combo_dropped.connect(_on_combo_dropped)
	GameManager.kunai_triggered.connect(_on_kunai_throw_cooldown_reset)
	
	combo_label.text = "Combo: 0"

func _process(delta: float) -> void:
	if kunai > 0.0:
		kunai -= delta
	if kunai < 0.0:
		kunai = 0.0
		
	kunai_cooldown_label.text = "Kunai: %.2f" % kunai
	
	
	if GameManager.combo_count > 0:
		combo_label.text = "COMBO: %d\nTimer: %.2f" % [GameManager.combo_count, GameManager.combo_time_left]
	
	adrenaline_label.text = "Adrenaline: %.2f%%\nStamina: %.2f" % [GameManager.adrenaline, GameManager.stamina_left]

func _on_combo_updated(_new_combo: int) -> void:
	var tween = create_tween()
	combo_label.scale = Vector2(1.5, 1.5)
	tween.tween_property(combo_label, "scale", Vector2(1, 1), 0.2)
	
	combo_label.modulate = Color.WHITE

func _on_combo_dropped() -> void:
	combo_label.text = "COMBO DROPPED!"
	combo_label.modulate = Color.RED
	
	var tween = create_tween()
	var start_pos = combo_label.position
	
	tween.tween_property(combo_label, "position", start_pos + Vector2(10, 0), 0.05)
	tween.tween_property(combo_label, "position", start_pos - Vector2(10, 0), 0.05)
	tween.tween_property(combo_label, "position", start_pos, 0.05)
	
	tween.tween_property(combo_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): 
		combo_label.modulate.a = 1.0 
		combo_label.text = "Combo: 0"
		
		combo_label.modulate = Color.WHITE
	)

func _on_kunai_throw_cooldown_reset(kunai_cooldown) -> void:
	kunai = kunai_cooldown
