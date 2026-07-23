extends CharacterBody2D

const SPEED = 500

func _ready() -> void:
	velocity = Vector2(0, -SPEED).rotated(rotation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if get_slide_collision_count() > 0:
		queue_free()
	move_and_slide()
