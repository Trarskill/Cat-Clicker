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
	Global.click_lvl_power = 0
	Global.leveled_up.emit(Global.level)
	_refresh_game_state()

# 3. ФУНКЦІЯ: Видати всі предмети
func _on_give_all_pressed() -> void:
	for item_id in Global.inventory.keys():
		var item_data = DataManager.get_item(item_id)
		
		if not item_data.is_empty():
			if typeof(Global.inventory[item_id]) == TYPE_BOOL:
				Global.inventory[item_id] = true
			else:
				if item_data.has("max_lvl"):
					Global.inventory[item_id] = item_data["max_lvl"]
				else:
					Global.inventory[item_id] = Global.MAX_STACK
	
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
	Global.click_power = 10
	Global.click_lvl_power = 0 
	Global.potion_balance = 0
	Global.xp = 0
	Global.level = 1
	Global.max_xp = 50
	Global.max_level_announced = false
	Global.magical_rose_bought = 0
	Global.equipped_weapon = ""
	Global.equipped_shield = ""
	
	for item_id in Global.inventory.keys():
		if item_id == "power_of_paws":
			continue 
			
		if typeof(Global.inventory[item_id]) == TYPE_BOOL:
			Global.inventory[item_id] = false
		else:
			Global.inventory[item_id] = 0
	
	Global.bowl_bone_timer = 0.0
	Global.bowl_rice_timer = 0.0
	Global.bowl_fish_timer = 0.0
	Global.bag_of_fruit_timer  = 0.0
	Global.catnip_timer = 0.0
	Global.clockwork_mouse_timer = 0.0
	Global.clockwork_mouse_cooldown = 0.0
	
	Global.show_floating_text("Повний вайп пройдено! 🧹", Color(1.0, 0.4, 0.4))
	_refresh_game_state()

# Синхронізація
func _refresh_game_state() -> void:
	get_tree().call_group("UI", "update_ui")
