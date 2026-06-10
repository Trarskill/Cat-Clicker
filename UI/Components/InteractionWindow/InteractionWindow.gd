extends PanelContainer

# Сигнал тепер передає ID предмету, текст повідомлення та чи була дія успішною
signal action_performed(item_id: String, result_msg: String, is_success: bool)

var current_item_id: String = ""
var auto_close_tween: Tween

# --- ОНОВЛЕНІ ШЛЯХИ ДО НОВИХ ВУЗЛІВ ---
@onready var name_label = $Margin/Content/ItemName
@onready var description_text = $Margin/Content/DescriptionText
@onready var panel_properties = $Margin/Content/PanelProperties
@onready var property_icon = $Margin/Content/PanelProperties/Margin/HBox/PropertyIcon
@onready var stats_label = $Margin/Content/PanelProperties/Margin/HBox/StatsLabel
@onready var action_button = $Margin/Content/ActionButton

func _ready():
	action_button.pressed.connect(_on_action_pressed)
	start_auto_close_countdown()

# --- ЗАВАНТАЖЕННЯ ДАНИХ ТА НОВОГО ІНТЕРФЕЙСУ ---
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
		
		match item_type:
			DataManager.ItemType.EQUIPMENT:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/equipment_icon.png") 
			DataManager.ItemType.CONSUMABLE:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/consumable_icon.png") 
			DataManager.ItemType.SPECIAL:
				property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/special_icon.png")
			_:
				property_icon.texture = null
		
		property_icon.visible = property_icon.texture != null
	else:
		panel_properties.visible = false
	
	if has_method("update_ui_state"):
		update_ui_state(item_data)

# --- УНІВЕРСАЛЬНА ФУНКЦІЯ ПОЯВИ ---
func appear_at(card_pos: Vector2, card_size: Vector2 = Vector2(110, 110)) -> void:
	modulate.a = 0
	
	await get_tree().process_frame
	
	var viewport_size = get_viewport_rect().size
	var popup_size = self.size
	
	var target_pos = card_pos + Vector2(-25, -110)
	
	if target_pos.y < 0:
		target_pos.y = card_pos.y + card_size.y + 10
	if target_pos.x + popup_size.x > viewport_size.x:
		target_pos.x = viewport_size.x - popup_size.x - 10
	if target_pos.x < 0:
		target_pos.x = 10
		
	global_position = target_pos
	
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

# --- ТВОЯ УНІКАЛЬНА ЛОГІКА СТАНІВ ---
func update_ui_state(data: Dictionary):
	action_button.disabled = false
	action_button.visible = true
	action_button.modulate = Color(1, 1, 1, 1)
	
	if current_item_id == "bowl_with_bone" and Global.bowl_bone_timer > 0:
		action_button.visible = false
		return
	if current_item_id == "bag_of_fruit" and Global.bag_of_fruit_timer > 0:
		action_button.visible = false
		return
	
	if data.has("is_upgrade_only") and data["is_upgrade_only"]:
		action_button.disabled = true
		action_button.text = "ПАСИВНА НАВИЧКА"
		
		# Рахуємо ста́ти
		var current_lvl = Global.inventory.get(current_item_id, 0)
		var bonus_percent = int(current_lvl * (data["stats"]["multiplier_per_level"] * 100))
		
		panel_properties.visible = true
		stats_label.text = str(current_lvl) + " РІВЕНЬ XP +" + str(bonus_percent) + "%"
		
		property_icon.texture = preload("res://Assets/Graphics/Icons/ItemTypes/special_magic_icon.png")
		property_icon.visible = true
		
		return
	
	if data.get("type") == DataManager.ItemType.EQUIPMENT:
		var is_equipped = false
		if current_item_id == Global.equipped_weapon or current_item_id == Global.equipped_shield:
			is_equipped = true
		
		if current_item_id == "magic_stick" and not is_equipped:
			var magic_lvl = Global.inventory.get("cat_magic", 0)
			if magic_lvl == 0:
				action_button.disabled = true
				action_button.modulate = Color(1, 1, 1, 0.5)
				action_button.text = "ПОТРІБНА ВОЛОДІТИ МАГІЄЮ"
				return
		
		action_button.text = "ЗНЯТИ" if is_equipped else "ОДЯГНУТИ"
		return
	
	if current_item_id == "magical_rose":
		if Global.inventory.get("xp_potion", 0) < 1:
			action_button.disabled = true
			action_button.modulate = Color(1, 1, 1, 0.5)
			action_button.text = "ПОТРІБНЕ ЗІЛЛЯ"
		else:
			action_button.text = "ЧАКЛУВАТИ"
		return
	
	action_button.text = "ВИКОРИСТАТИ"

# --- ОБРОБНИКИ ДІЙ ТА АНІМАЦІЙ ---
func _on_action_pressed():
	var result = Global.use_item(current_item_id)
	
	if not "Потрібне" in result and not "максимуму" in result:
		SaveManager.save_game()
		action_performed.emit(current_item_id, result, true)
		
		hide()
		queue_free()
	else:
		action_performed.emit(current_item_id, result, false)
		play_error_shake()

func start_auto_close_countdown() -> void:
	if auto_close_tween and auto_close_tween.is_valid():
		auto_close_tween.kill()
		
	auto_close_tween = create_tween()
	auto_close_tween.tween_interval(3.0)
	
	auto_close_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	auto_close_tween.chain().tween_callback(queue_free)

func play_error_shake():
	var tw = create_tween()
	var original_x = position.x
	
	tw.tween_property(self, "position:x", original_x + 5, 0.05)
	tw.tween_property(self, "position:x", original_x - 5, 0.05)
	tw.tween_property(self, "position:x", original_x, 0.05)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if not get_rect().has_point(event.position):
			hide()
			queue_free()
