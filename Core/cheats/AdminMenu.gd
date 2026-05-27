extends PanelContainer

@onready var btn_add_level = $MarginContainer/VBox/BtnAddLevel
@onready var btn_reset_level = $MarginContainer/VBox/BtnResetLevel
@onready var btn_give_all = $MarginContainer/VBox/BtnGiveAll
@onready var btn_give_money = $MarginContainer/VBox/BtnGiveMoney  
@onready var btn_clear_all = $MarginContainer/VBox/BtnClearAll
@onready var btn_close = $MarginContainer/VBox/BtnClose

func _ready() -> void:
	btn_add_level.pressed.connect(_on_add_level_pressed)
	btn_reset_level.pressed.connect(_on_reset_level_pressed)
	btn_give_all.pressed.connect(_on_give_all_pressed)
	btn_give_money.pressed.connect(_on_give_money_pressed)
	btn_clear_all.pressed.connect(_on_clear_all_pressed)
	
	btn_close.pressed.connect(_on_close_pressed)

func _on_close_pressed() -> void:
	hide()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var panel_rect = get_global_rect()
		
		if not panel_rect.has_point(event.global_position):
			get_viewport().set_input_as_handled()
			_on_close_pressed()

# 1. ФУНКЦІЯ: Видати +1 рівень
func _on_add_level_pressed() -> void:
	if Global.level < 100:
		Global.level += 1
		Global.max_xp = int(50.0 * pow(Global.level, 1.5))
		
		if Global.level >= 100:
			Global.max_xp = int(50.0 * pow(100.0, 1.5))
			Global.max_level_announced = true
		
		Global.leveled_up.emit(Global.level)
		_refresh_game_state()

# 2. ФУНКЦІЯ: Скинути рівень в 0 (початковий 1 рівень)
func _on_reset_level_pressed() -> void:
	Global.level = 1
	Global.xp = 0
	Global.max_xp = 50
	Global.max_level_announced = false
	Global.is_endgame_half_reached = false
	
	Global.leveled_up.emit(Global.level)
	_refresh_game_state()

# 3. ФУНКЦІЯ: Видати ресурси + всі предмети
func _on_give_all_pressed() -> void:
	Global.meowcoin += 40000
	Global.meowgem += 1000
	
	var all_item_ids = ["bowl", "bag_of_fruit", "potion", "magical_rose", "magic_stick"]
	for item_id in all_item_ids:
		var item_data = DataManager.get_item(item_id)
		if not item_data.is_empty():
			if item_data.has("is_upgrade_only") and item_data["is_upgrade_only"]:
				Global.inventory[item_id] = 10
			elif item_data.get("type") == DataManager.ItemType.EQUIPMENT:
				Global.inventory[item_id] = true
			else:
				Global.inventory[item_id] = 16
				
	Global.show_floating_text("Адмін-набір видано! 🎁", Color(0.4, 1.0, 0.4))
	_refresh_game_state()

# 4. ФУНКЦІЯ: Видати тільки гроші (без предметів)
func _on_give_money_pressed() -> void:
	Global.meowcoin += 40000
	Global.meowgem += 1000
	
	Global.show_floating_text("+40к Монет & +1к Гемів! 💵", Color(1.0, 0.85, 0.2))
	_refresh_game_state()

# 5. ФУНКЦІЯ: Повний вайп
func _on_clear_all_pressed() -> void:
	Global.meowcoin = 0
	Global.meowgem = 0
	Global.rustycoin = 0
	Global.xp = 0
	Global.level = 1
	Global.max_xp = 50
	Global.max_level_announced = false
	Global.is_endgame_half_reached = false
	
	Global.equipped_weapon = ""
	Global.equipped_shield = ""
	
	Global.inventory = {
		"mysterious_chest": false,
		"wooden_sword": false,
		"wooden_shield": false,
		"steel_sword": false,
		"magic_stick": false,
		"bowl": 0,
		"apple": 0,
		"bag_of_fruit": 0,
		"magical_rose": 0,
		"potion": 0,
		"cat_magic": 0
	}
	
	Global.show_floating_text("Повний вайп пройдено! 🧹", Color(1.0, 0.4, 0.4))
	_refresh_game_state()

# Синхронізація та збереження файлу
func _refresh_game_state() -> void:
	SaveManager.save_game()
	
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("update_ui"):
		current_scene.update_ui()
