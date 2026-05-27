extends PanelContainer

# Сигнал тепер передає ID предмету, текст повідомлення та чи була дія успішною
signal action_performed(item_id: String, result_msg: String, is_success: bool)

var current_item_id: String = ""
var auto_close_tween: Tween

@onready var name_label = $Margin/Content/ItemName
@onready var props_label = $Margin/Content/PropertiesLabel
@onready var action_button = $Margin/Content/ActionButton

func _ready():
	action_button.pressed.connect(_on_action_pressed)
	start_auto_close_countdown()

func setup(id: String, _display_name: String):
	current_item_id = id
	var item_data = DataManager.get_item(id)
	
	if item_data.is_empty():
		queue_free()
		return
		
	name_label.text = item_data["name"]
	props_label.text = item_data["proper"]
	
	update_ui_state(item_data)

func update_ui_state(data: Dictionary):
	action_button.disabled = false
	action_button.visible = true
	action_button.modulate = Color(1, 1, 1, 1)
	
	if current_item_id == "bowl" and Global.bowl_timer > 0:
		action_button.visible = false
		return
	if current_item_id == "bag_of_fruit" and Global.bag_of_fruit_timer > 0:
		action_button.visible = false
		return
	
	# 1. Якщо це Кото-Магія (Upgrade Only)
	if data.has("is_upgrade_only") and data["is_upgrade_only"]:
		action_button.disabled = true
		var current_lvl = Global.inventory.get(current_item_id, 0)
		var bonus_percent = int(current_lvl * (data["stats"]["multiplier_per_level"] * 100))
		action_button.text = str(current_lvl) + " РІВЕНЬ (+" + str(bonus_percent) + "%)"
		return
	
	# 2. Якщо це зброя або щит (Equipment)
	if data.get("type") == DataManager.ItemType.EQUIPMENT:
		var is_equipped = false
		if current_item_id == Global.equipped_weapon or current_item_id == Global.equipped_shield:
			is_equipped = true
		
		# Блокуємо кнопку лише тоді, коли палиця НЕ НАДЯГНЕНА і магія <= 1
		if current_item_id == "magic_stick" and not is_equipped:
			var magic_lvl = Global.inventory.get("cat_magic", 0)
			if magic_lvl == 0:
				action_button.disabled = true
				action_button.modulate = Color(1, 1, 1, 0.5)
				action_button.text = "ПОТРІБНА ВОЛОДІТИ МАГІЄЮ"
				return
		
		action_button.text = "ЗНЯТИ" if is_equipped else "ОДЯГНУТИ"
		return
	
	# 3. Особлива увака для Рози
	if current_item_id == "magical_rose":
		if Global.inventory.get("potion", 0) < 1:
			action_button.disabled = true
			action_button.modulate = Color(1, 1, 1, 0.5)
			action_button.text = "ПОТРІБНЕ ЗІЛЛЯ"
		else:
			action_button.text = "ЧАКЛУВАТИ"
		return
	
	# 4. Для всього іншого
	action_button.text = "ВИКОРИСТАТИ"

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
