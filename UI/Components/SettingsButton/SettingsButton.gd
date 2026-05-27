extends Button

var normal_scale := Vector2(1, 1)
var hover_scale := Vector2(1.1, 1.1)
var pressed_scale := Vector2(0.9, 0.9)
var tween : Tween

func _ready() -> void:
	# Центруємо точку обертання та масштабування
	pivot_offset = size / 2
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	resized.connect(func(): pivot_offset = size / 2)

# Функція для одночасної зміни масштабу та кута обертання
func animate_change(target_scale: Vector2, target_rotation: float) -> void:
	if tween and tween.is_running():
		tween.kill()
	
	# set_parallel(true) дозволяє програвати дві анімації одночасно
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.15)
	tween.tween_property(self, "rotation_degrees", target_rotation, 0.15)

func _on_mouse_entered() -> void:
	# При наведенні збільшуємо і трохи крутимо вправо (15 градусів)
	animate_change(hover_scale, 15.0)

func _on_mouse_exited() -> void:
	# Повертаємо до початкового стану
	animate_change(normal_scale, 0.0)

func _on_button_down() -> void:
	# При кліку стискаємо і крутимо в іншу сторону
	animate_change(pressed_scale, -15.0)

func _on_button_up() -> void:
	if is_hovered():
		animate_change(hover_scale, 15.0)
	else:
		animate_change(normal_scale, 0.0)
