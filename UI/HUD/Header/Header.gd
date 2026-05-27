extends MarginContainer

# Отримуємо посилання на текстові мітки кожної валюти
@onready var meowcoin_label = $HeaderLayout/CoinBar/MeowcoinGroup/Label
@onready var rustycoin_label = $HeaderLayout/CoinBar/RustycoinGroup/Label
@onready var meowgem_label = $HeaderLayout/CoinBar/MeowgemGroup/Label

func _ready() -> void:
	# Для тесту можна розкоментувати і перевірити, як виглядають цифри:
	# update_meowcoin(1500)
	# update_rustycoin(45)
	# update_meowgem(3)
	pass

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
