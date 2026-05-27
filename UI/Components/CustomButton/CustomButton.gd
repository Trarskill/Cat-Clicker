extends Button

# Змінні для налаштування розміру
var normal_scale := Vector2(1, 1)
var hover_scale := Vector2(1.05, 1.05)
var pressed_scale := Vector2(0.95, 0.95)
var tween : Tween

func _ready() -> void:
	# Робимо так, щоб кнопка масштабувалася від свого центру, а не від лівого верхнього кута
	pivot_offset = size / 2
	
	# Підключаємо вбудовані сигнали кнопки до наших функцій
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	# Оновлюємо центр обертання, якщо розмір кнопки зміниться
	resized.connect(func(): pivot_offset = size / 2)

# Функція для плавної зміни масштабу
func animate_scale(target_scale: Vector2) -> void:
	if tween and tween.is_running():
		tween.kill() # Зупиняємо попередню анімацію, щоб вони не конфліктували
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.1)

func _on_mouse_entered() -> void:
	animate_scale(hover_scale)

func _on_mouse_exited() -> void:
	animate_scale(normal_scale)

func _on_button_down() -> void:
	animate_scale(pressed_scale)

func _on_button_up() -> void:
	# Якщо після кліку мишка ще на кнопці — залишаємо збільшеною, якщо ні — повертаємо до норми
	if is_hovered():
		animate_scale(hover_scale)
	else:
		animate_scale(normal_scale)
