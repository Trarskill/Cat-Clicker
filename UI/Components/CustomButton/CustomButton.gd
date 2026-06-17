extends Button

var normal_scale := Vector2(1, 1)
var hover_scale := Vector2(1.05, 1.05)
var pressed_scale := Vector2(0.95, 0.95)
var tween : Tween

func _ready() -> void:
	pivot_offset = size / 2
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	resized.connect(func(): pivot_offset = size / 2)

# Функція для плавної зміни масштабу
func animate_scale(target_scale: Vector2) -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.1)

func _on_mouse_entered() -> void:
	animate_scale(hover_scale)

func _on_mouse_exited() -> void:
	animate_scale(normal_scale)

func _on_button_down() -> void:
	animate_scale(pressed_scale)

func _on_button_up() -> void:
	if is_hovered():
		animate_scale(hover_scale)
	else:
		animate_scale(normal_scale)
