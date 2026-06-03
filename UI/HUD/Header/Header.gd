extends MarginContainer

# Отримуємо посилання на текстові мітки кожної валюти
@onready var meowcoin_label = $HeaderLayout/CoinBar/MeowcoinGroup/Label
@onready var rustycoin_label = $HeaderLayout/CoinBar/RustycoinGroup/Label
@onready var meowgem_label = $HeaderLayout/CoinBar/MeowgemGroup/Label

func _ready() -> void:
	_apply_safe_area()

func _apply_safe_area() -> void:
	var os_name = OS.get_name()
	if os_name == "Windows" or os_name == "macOS" or os_name == "Linux":
		return # На ПК просто зупиняємо функцію і нічого не робимо
		
	# 2. Логіка для телефонів (Android / iOS)
	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.window_get_size()
	
	if safe_area.size == window_size or window_size.y == 0:
		return
		
	var scale_ratio = get_viewport_rect().size.y / float(window_size.y)
	var top_margin = safe_area.position.y * scale_ratio
	
	add_theme_constant_override("margin_top", int(top_margin))

# Meowcoin використовує форматування (K, M, B)
func update_meowcoin(amount: float) -> void:
	meowcoin_label.text = format_number(amount)

# Rustycoin та Meowgem завжди показують точні числа
func update_rustycoin(amount: float) -> void:
	rustycoin_label.text = str(int(amount))

func update_meowgem(amount: float) -> void:
	meowgem_label.text = str(int(amount))

# Логіка форматування великих чисел
func format_number(n: float) -> String:
	if n >= 1000000000:
		return ("%.1f" % (n / 1000000000.0)).replace(".0", "") + "B"
	elif n >= 1000000:
		return ("%.1f" % (n / 1000000.0)).replace(".0", "") + "M"
	elif n >= 1000:
		return ("%.1f" % (n / 1000.0)).replace(".0", "") + "K"
	return str(int(n))
