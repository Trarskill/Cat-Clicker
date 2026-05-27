extends HBoxContainer

signal shop_category_changed(category_id: String)

# Отримуємо список усіх вкладок-дітей
@onready var tabs = [
	$TabGeneral,
	$TabWeapon,
	$TabMagic
]

func _ready():
	# Підключаємо сигнали від кожної вкладки
	for tab in tabs:
		if tab.has_signal("tab_clicked"):
			tab.tab_clicked.connect(_on_tab_clicked)
	
	# Встановлюємо початковий стан (Загальна лавка)
	call_deferred("_select_initial_tab")

func _select_initial_tab():
	_on_tab_clicked("general")

func _on_tab_clicked(clicked_id: String):
	print("[clicker] Клік по вкладці: ", clicked_id)
	# Оновлюємо візуал усіх кнопок: активна тільки та, чий ID збігається
	for tab in tabs:
		tab.set_active(tab.tab_id == clicked_id)
	
	# Сповіщаємо магазин про зміну категорії
	shop_category_changed.emit(clicked_id)
