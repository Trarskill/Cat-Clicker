extends PanelContainer

# --- СИГНАЛИ ТА ЗМІННІ СТАНУ ---
signal action_performed(item_id: String, result_msg: String, is_success: bool)

var current_item_id: String = ""
var auto_close_tween: Tween

# --- ОНОВЛЕНІ ШЛЯХИ ДО НОВИХ ВУЗЛІВ ---
@onready var name_label = $Margin/Content/ItemName
@onready var description_text = $Margin/Content/DescriptionText
@onready var panel_properties = $Margin/Content/PanelProperties
@onready var property_icon = $Margin/Content/PanelProperties/Margin/HBox/PropertyIcon
@onready var stats_label = $Margin/Content/PanelProperties/Margin/HBox/StatsLabel
@onready var action_button = $Margin/Content/HBoxContainer/ActionButton
@onready var multi_action = $Margin/Content/HBoxContainer/ActionButtonx10

# --- ІНІЦІАЛІЗАЦІЯ ВІКНА ---
# Викликається при створенні сцени. Підключає кнопку дії та 
# одразу запускає таймер на автоматичне закриття вікна
func _ready():
	action_button.pressed.connect(_on_action_pressed)
	multi_action.pressed.connect(_on_action_multi_pressed)
	start_auto_close_countdown()

# --- ЗАВАНТАЖЕННЯ ДАНИХ ТА НАЛАШТУВАННЯ ІНТЕРФЕЙСУ ---
# Отримує ID предмета, витягує його інформацію з DataManager і 
# заповнює текстові поля, іконки та властивості у віконці
func setup(id: String, extra_param = null):
	current_item_id = id
	
	if typeof(extra_param) == TYPE_VECTOR2:
		global_position = extra_param + Vector2(0, 50)
		var viewport_size = get_viewport_rect().size
		var approx_size = Vector2(350, 177) 
		global_position.x = clamp(global_position.x, 10, viewport_size.x - approx_size.x - 10)
		global_position.y = clamp(global_position.y, 10, viewport_size.y - approx_size.y - 10)
		
	var item_data = DataManager.get_item(id)
	
	if item_data.is_empty():
		queue_free()
		return
		
	name_label.text = item_data.get("name", "Невідомий предмет")
	var desc_text = item_data.get("description", "")
	description_text.text = desc_text
	
	description_text.visible = desc_text != ""
	
	var stats_text = item_data.get("proper", "")
	
	if stats_text != "":
		panel_properties.visible = true
		stats_label.text = stats_text
		
		var item_type = item_data.get("type")
		
		# ОНОВЛЕНО: Тепер враховуються всі 5 нових типів предметів
		match item_type:
			DataManager.ItemType.EQUIPMENT:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/equipment-icon.png") 
			DataManager.ItemType.CONSUMABLE:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/consumable-icon.png") 
			DataManager.ItemType.BUFF:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/buffi-icon.png")
			DataManager.ItemType.PASSIVE:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/passive-icon.png")
			DataManager.ItemType.KEY_ITEM:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/key-item-icon.png")
			DataManager.ItemType.LOOTBOX:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/lootbox-icon.png")
			_:
				property_icon.texture = null
		
		property_icon.visible = property_icon.texture != null
	else:
		panel_properties.visible = false
	
	if has_method("update_ui_state"):
		update_ui_state(item_data)

# --- ЛОГІКА СТАНІВ КНОПКИ ДІЇ ---
# Перевіряє унікальні умови предмета і змінює вигляд або текст кнопки 
func update_ui_state(data: Dictionary):
	action_button.disabled = false
	action_button.visible = true
	action_button.modulate = Color(1, 1, 1, 1)
	
	multi_action.visible = false 
	multi_action.disabled = false
	multi_action.modulate = Color(1, 1, 1, 1)
	
	var item_type = data.get("type")
	
	# --- УНІВЕРСАЛЬНА ПЕРЕВІРКА НА НУЛЬ ---
	if item_type in [DataManager.ItemType.BUFF, DataManager.ItemType.CONSUMABLE, DataManager.ItemType.LOOTBOX]:
		var item_count = Global.inventory.get(current_item_id, 0)
		if int(item_count) < 1:
			action_button.visible = false
			multi_action.visible = false
			return
	
	# --- 1. ПАСИВНІ ПРЕДМЕТИ ---
	if item_type == DataManager.ItemType.PASSIVE:
		if current_item_id == "clockwork_mouse":
			action_button.visible = true
			if Global.clockwork_mouse_timer > 0:
				action_button.disabled = true
				action_button.modulate = Color(1, 1, 1, 0.5)
				action_button.text = "ПРАЦЮЄ..."
			elif Global.clockwork_mouse_cooldown > 0:
				action_button.disabled = true
				action_button.modulate = Color(1, 1, 1, 0.5)
				action_button.text = "ПЕРЕЗАРЯДКА"
			else:
				action_button.disabled = false
				action_button.modulate = Color(1, 1, 1, 1)
				action_button.text = "ЗАВЕСТИ"
			return 
		else:
			action_button.visible = false
			return
		
	# --- 2. ТИМЧАСОВІ БАФИ ---
	# Автоматично перевіряємо всі таймери. 
	# Якщо предметів < 1 (тобто 0), ховаємо кнопку. Якщо більше — залишаємо.
	if item_type == DataManager.ItemType.BUFF:
		var current_timer_value = 0.0
		match current_item_id:
			"bowl_with_bone": current_timer_value = Global.bowl_bone_timer
			"bowl_with_rice": current_timer_value = Global.bowl_rice_timer
			"bowl_with_fish": current_timer_value = Global.bowl_fish_timer
			"bag_of_fruit": current_timer_value = Global.bag_of_fruit_timer
			"catnip": current_timer_value = Global.catnip_timer
			
		var max_time_allowed = 540.0 
		
		if current_item_id == "catnip":
			max_time_allowed = 270.0
		if current_timer_value > max_time_allowed:
			action_button.visible = false
			return
		else:
			action_button.visible = true
	
	# --- 3. КЛЮЧОВІ ПРЕДМЕТИ ---
	if item_type == DataManager.ItemType.KEY_ITEM:
		if current_item_id == "cat_magic":
			action_button.disabled = true
			action_button.text = "ПАСИВНА НАВИЧКА"
			
			var current_lvl = Global.inventory.get(current_item_id, 0)
			var bonus_percent = int(current_lvl * (data["stats"]["multiplier_per_level"] * 100))
			
			panel_properties.visible = true
			stats_label.text = str(current_lvl) + " РІВЕНЬ XP +" + str(bonus_percent) + "%"
			property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/magic-icon.png")
			property_icon.visible = true
			return
		
		if current_item_id == "power_of_paws":
			action_button.disabled = true
			action_button.text = "СТАТИСТИКА"
			
			var lvl = Global.click_lvl_power
			var potions = Global.potion_balance
			var total = 10 + lvl + potions
			
			panel_properties.visible = true
			
			stats_label.text = "СИЛА: " + str(total) + " (Досвід " + str(lvl) + " | Зілля " + str(potions) + ")"
			
			property_icon.visible = true
			return
		
		if current_item_id == "boss_map":
			action_button.text = "ВИВЧИТИ"
			return
		
		if current_item_id == "magical_rose":
			if Global.inventory.get("xp_potion", 0) < 1:
				action_button.disabled = true
				action_button.modulate = Color(1, 1, 1, 0.5)
				action_button.text = "ПОТРІБНЕ ЗІЛЛЯ"
			else:
				action_button.text = "ЧАКЛУВАТИ"
			return
	
	# --- 4. ЕКІПІРУВАННЯ ---
	if item_type == DataManager.ItemType.EQUIPMENT:
		var is_equipped = (current_item_id == Global.equipped_weapon or current_item_id == Global.equipped_shield)
		
		if current_item_id == "magic_stick" and not is_equipped:
			var magic_lvl = Global.inventory.get("cat_magic", 0)
			if magic_lvl == 0:
				action_button.disabled = true
				action_button.modulate = Color(1, 1, 1, 0.5)
				action_button.text = "ПОТРІБНА МАГІЯ"
				return
		
		action_button.text = "ЗНЯТИ" if is_equipped else "ОДЯГНУТИ"
		return
	
	# --- АДАПТИВНА КНОПКА "ВИКОРИСТАТИ ВСЕ" ---
	if data.get("type") == DataManager.ItemType.CONSUMABLE or DataManager.ItemType.BUFF:
		var item_count = Global.inventory.get(current_item_id, 0)
	
		if typeof(item_count) in [TYPE_INT, TYPE_FLOAT] and item_count > 1:
			multi_action.visible = true
			multi_action.disabled = false
			multi_action.modulate = Color(1, 1, 1, 1)
			
			var use_amount = min(int(item_count), 10)
			multi_action.text = "x" + str(use_amount)
			
			var is_timer_active = false
			match current_item_id:
				"bowl_with_bone": is_timer_active = Global.bowl_bone_timer > 0
				"bowl_with_rice": is_timer_active = Global.bowl_rice_timer > 0
				"bowl_with_fish": is_timer_active = Global.bowl_fish_timer > 0
				"bag_of_fruit": is_timer_active = Global.bag_of_fruit_timer > 0
				"catnip": is_timer_active = Global.catnip_timer > 0
			
			if is_timer_active:
				multi_action.visible = false
				
		else:
			multi_action.visible = false
	
	# --- 5. МИТТЄВІ РОЗХІДНИКИ ---
	action_button.text = "ВИКОРИСТАТИ"

# --- УНІВЕРСАЛЬНА ФУНКЦІЯ ПОЯВИ ТА ПОЗИЦІЮВАННЯ ---
# Розраховує безпечну позицію для спливаючого вікна
# поруч із карткою і плавно проявляє його (fade in)
func appear_at(pos: Vector2) -> void:
	global_position = pos
	
	# Чекаємо 1 кадр, щоб Godot встиг правильно розрахувати розмір вікна (size)
	await get_tree().process_frame
	
	var screen_size = get_viewport_rect().size
	var window_size = size
	
	# Вкажіть тут приблизну висоту вашого LowBar (наприклад, 160 пікселів)
	var low_bar_height = 132.0 
	
	# 1. Захист від накладання на LowBar (по осі Y)
	if global_position.y + window_size.y > screen_size.y - low_bar_height:
		global_position.y = screen_size.y - low_bar_height - window_size.y
		
	# 2. Захист від виходу за правий край екрану (по осі X)
	if global_position.x + window_size.x > screen_size.x:
		global_position.x = screen_size.x - window_size.x - 8.0

# --- ОБРОБКА НАТИСКАННЯ КНОПКИ ДІЇ ---
# Викликає функцію використання в Global. Якщо все добре — зберігає гру
# і закривається. Якщо помилка — показує анімацію відмови
func _on_action_pressed():
	var result = Global.use_item(current_item_id)
	
	if not "Потрібне" in result and not "максимуму" in result:
		action_performed.emit(current_item_id, result, true)
		
		hide()
		queue_free()
	else:
		action_performed.emit(current_item_id, result, false)
		play_error_shake()

# --- ОБРОБКА МАСОВОГО ВИКОРИСТАННЯ ПРЕДМЕТІВ ---
# Багаторазово викликає функцію використання в Global (до 10 разів).
# Підсумовує результати (досвід, час, статси), зберігає гру і закривається.
func _on_action_multi_pressed():
	var item_count = Global.inventory.get(current_item_id, 0)
	var use_amount = min(int(item_count), 10) 
	var success_count = 0
	
	var start_gems = Global.meowgem
	var total_xp_gained = 0
	var last_error = ""
	
	var item_data = DataManager.get_item(current_item_id)
	var stats = item_data.get("stats", {})
	var buff_duration = stats.get("duration", 0)
	
	for i in range(use_amount):
		if int(Global.inventory.get(current_item_id, 0)) < 1:
			break
			
		var result = Global.use_item(current_item_id)
		
		var res_lower = result.to_lower()
		if not "потрібне" in res_lower and not "максимуму" in res_lower and not "ліміт" in res_lower and not "не витримає" in res_lower:
			success_count += 1
			
			if current_item_id == "apple" and "Отримано" in result:
				total_xp_gained += stats.get("give_xp", 45)
			elif current_item_id == "xp_potion":
				var magic_lvl = Global.inventory.get("cat_magic", 0)
				total_xp_gained += 100 + (100 * magic_lvl)
		else:
			last_error = result
			break 
			
	if success_count > 0:
		var text_to_show = "Використано " + str(success_count) + " шт!"
		
		if current_item_id in ["apple", "xp_potion"]:
			if total_xp_gained > 0:
				text_to_show += "\n+" + str(total_xp_gained) + " XP"
			else:
				text_to_show += "\nВсі виявились кислими :("
				
		elif current_item_id in ["bowl_with_bone", "bowl_with_rice", "bowl_with_fish", "bag_of_fruit", "catnip"]:
			var total_added_time = success_count * buff_duration
			text_to_show += "\nБаф активовано на " + str(total_added_time) + " сек!"
			
		elif current_item_id == "strength_potion":
			var power_gained = success_count * stats.get("permanent_power", 1)
			text_to_show += "\n+" + str(power_gained) + " Сили назавжди!"
			
		elif current_item_id == "curse_potion":
			var power_lost = success_count * abs(stats.get("permanent_power", -1))
			var gems_gained = Global.meowgem - start_gems
			text_to_show += "\n-" + str(power_lost) + " Сили, +" + str(gems_gained) + " Гемів!"
		
		if last_error != "":
			text_to_show += "\n(Зупинено: Ліміт)"
		
		action_performed.emit(current_item_id, text_to_show, true)
		
		hide()
		queue_free()
	else:
		var error_msg = last_error if last_error != "" else "Помилка використання"
		action_performed.emit(current_item_id, error_msg, false)
		play_error_shake()

# --- ТАЙМЕР АВТОМАТИЧНОГО ЗАКРИТТЯ ---
# Запускає відлік часу (3 секунди), після якого віконце самостійно 
# зникає, щоб не захаращувати екран, якщо гравець про нього забув
func start_auto_close_countdown() -> void:
	if auto_close_tween and auto_close_tween.is_valid():
		auto_close_tween.kill()
		
	auto_close_tween = create_tween()
	auto_close_tween.tween_interval(3.0)
	
	auto_close_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	auto_close_tween.chain().tween_callback(queue_free)

# --- АНІМАЦІЯ ПОМИЛКИ (ТРЕМТІННЯ) ---
# Програє короткий рух вліво-вправо, що візуально 
# сигналізує гравцю про неможливість дії
func play_error_shake():
	var tw = create_tween()
	var original_x = position.x
	
	tw.tween_property(self, "position:x", original_x + 5, 0.05)
	tw.tween_property(self, "position:x", original_x - 5, 0.05)
	tw.tween_property(self, "position:x", original_x, 0.05)

# --- ОБРОБКА КЛІКІВ МИШІ ---
# Дозволяє закрити вікно просто натиснувши мишкою деінде
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if not get_rect().has_point(event.position):
			hide()
			queue_free()
