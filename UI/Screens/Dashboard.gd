extends Control

@onready var header = $UILayer/Header
@onready var lowbar = $UILayer/LowBar
@onready var click_area = $ClickArea
@onready var game_world = $GameWorld
@onready var background = $Background
@onready var background_night = $Background_Night

@onready var shop_popup = $UILayer/ShopPopup
@onready var inventory_popup = $UILayer/InventoryPopup

@onready var cat = $GameWorld/CatPosition/Cat
@onready var dummy = $GameWorld/DummyPosition/Dummy

@onready var lowbar_shop_button = $UILayer/LowBar/Margin/Layout/ShopButton
@onready var lowbar_inventory_button = $UILayer/LowBar/Margin/Layout/InvButton

var is_menu_locked: bool = false
var current_menu_offset_y: float = 0.0

var world_tween: Tween

func _ready() -> void:
	SaveManager.load_game()
	update_ui()
	
	if cat.has_method("update_equipment_visuals"):
		cat.update_equipment_visuals()
	
	click_area.pressed.connect(_on_click_area_pressed)
	lowbar_shop_button.pressed.connect(_on_shop_button_pressed)
	lowbar_inventory_button.pressed.connect(_on_inventory_button_pressed)
	shop_popup.state_changed.connect(_on_shop_state_changed)
	shop_popup.item_bought.connect(_on_item_bought_success)
	inventory_popup.item_action_executed.connect(_on_inventory_action)
	inventory_popup.inventory_toggled.connect(_on_inventory_visibility_changed)
	
	Global.leveled_up.connect(_on_leveled_up)
	
	resized.connect(_on_dashboard_resized)
	_on_dashboard_resized()

# --- ФУНКЦІЯ АВТОМАТИЧНОГО ЦЕНТРУВАННЯ ---
func _on_dashboard_resized() -> void:
	game_world.position.x = size.x / 2.0
	game_world.position.y = (size.y / 2.0) + current_menu_offset_y

func _on_click_area_pressed() -> void:
	
	await cat.play_attack()
	await dummy.take_hit()
	
	# --- РОЗРАХУНОК ДОСВІДУ (XP) ---
	var total_xp = Global.click_power
	
	if Global.bowl_timer > 0:
		var bowl_data = DataManager.get_item("bowl")
		total_xp += bowl_data["stats"]["xp_bonus"]
		
	if Global.equipped_weapon != "":
		var w_data = DataManager.get_item(Global.equipped_weapon)
		if Global.equipped_weapon == "magic_stick":
			if Global.inventory.get("cat_magic", 0) >= 1:
				total_xp += w_data["stats"]["xp_bonus"]
		else:
			total_xp += w_data["stats"]["xp_bonus"]
			
	if Global.equipped_shield != "":
		var s_data = DataManager.get_item(Global.equipped_shield)
		total_xp += s_data["stats"]["xp_bonus"]
		
	var magic_lvl = Global.inventory.get("cat_magic", 0)
	if magic_lvl > 0:
		var magic_data = DataManager.get_item("cat_magic")
		var multiplier = 1.0 + (magic_lvl * magic_data["stats"]["multiplier_per_level"])
		total_xp = int(total_xp * multiplier)
		
	Global.gain_xp(total_xp)
	
	show_xp_feedback(total_xp)
	
	# --- РОЗРАХУНОК МОНЕТ (Мішок фруктів) ---
	if Global.bag_of_fruit_timer > 0:
		Global.click_counter += 1
		if Global.click_counter >= 5:
			Global.click_counter = 0
			var fruit_data = DataManager.get_item("bag_of_fruit")
			var max_coins = fruit_data["stats"]["coin_chance"]
			Global.meowcoin += randi_range(1, max_coins)
	
	update_ui()

func update_ui() -> void:
	header.update_meowcoin(Global.meowcoin)
	header.update_rustycoin(Global.rustycoin)
	header.update_meowgem(Global.meowgem)
	
	var level_bar = lowbar.get_node("Margin/Layout/LevelBar")
	if level_bar:
		if Global.level >= 100:
			level_bar.get_node("LevelTitle").text = "Рівень MAX"
			level_bar.update_xp(Global.xp, Global.max_xp) 
		else:
			level_bar.get_node("LevelTitle").text = "Рівень " + str(Global.level)
			level_bar.update_xp(Global.xp, Global.max_xp)
	
	if shop_popup:
		shop_popup.update_all_cards()

# --- ОБРОБКА ПОДІЙ ІНТЕРФЕЙСУ ---
func _on_item_bought_success() -> void:
	update_ui()

# --- ОБРОБКА КНОПОК ДЛЯ ПЕРЕМИКАННЯ ВКЛАДОК ---
func _on_shop_button_pressed() -> void:
	if is_menu_locked:
		return
		
	is_menu_locked = true
	
	if inventory_popup.visible: 
		inventory_popup.close()
		await get_tree().create_timer(0.2).timeout 
		
	shop_popup.toggle_shop()
	
	await get_tree().create_timer(0.5).timeout
	is_menu_locked = false

func _on_inventory_button_pressed() -> void:
	if is_menu_locked:
		return
		
	is_menu_locked = true
	
	if inventory_popup.visible:
		inventory_popup.close()
	else:
		if shop_popup.current_state != shop_popup.State.CLOSED:
			shop_popup.close()
			
			await get_tree().create_timer(0.2).timeout
			
		inventory_popup.open()
	
	await get_tree().create_timer(0.5).timeout
	is_menu_locked = false

func _on_inventory_action():
	update_ui()
	
	if cat.has_method("update_equipment_visuals"):
		cat.update_equipment_visuals()

# --- УНІВЕРСАЛЬНА ФУНКЦІЯ РУХУ СВІТУ (ДЛЯ ВСІХ ВІКОН) ---
func shift_game_world(target_y: float) -> void:
	current_menu_offset_y = target_y
	
	if world_tween and world_tween.is_valid():
		world_tween.kill()
		
	world_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var final_game_world_y = (size.y / 2.0) + target_y
	
	world_tween.tween_property(game_world, "position:y", final_game_world_y, 0.5)
	world_tween.tween_property(background, "position:y", target_y, 0.5)
	
	if background_night:
		world_tween.tween_property(background_night, "position:y", target_y, 0.5)

# --- ОБРОБНИК МАГАЗИНУ (Використовує універсальну функцію) ---
func _on_shop_state_changed(new_state) -> void:
	var target_y = 0.0
	match new_state:
		shop_popup.State.CLOSED: target_y = 0.0
		shop_popup.State.PARTIAL: target_y = -210.0
		shop_popup.State.FULL: target_y = -350.0
			
	shift_game_world(target_y)

# --- ОБРОБНИК ІНВЕНТАРЮ (Використовує універсальну функцію) ---
func _on_inventory_visibility_changed(is_open: bool) -> void:
	var target_y = -210.0 if is_open else 0.0
	shift_game_world(target_y)

# --- ВІЗУАЛЬНИЙ ВІДГУК ДЛЯ КЛІКІВ ---
func show_xp_feedback(amount: int) -> void:
	var xp_label = Label.new()
	xp_label.text = "+" + str(amount) + " XP"
	
	xp_label.add_theme_color_override("font_color", Color(0.7, 0.3, 0.9)) # Фіолетовий
	xp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	xp_label.add_theme_constant_override("outline_size", 6)
	xp_label.add_theme_font_size_override("font_size", 28)
	
	game_world.add_child(xp_label)
	
	var start_offset_x = randf_range(-70.0, 70.0)
	var start_offset_y = randf_range(-130.0, -80.0)
	xp_label.global_position = cat.global_position + Vector2(start_offset_x, start_offset_y)
	
	var target_x = xp_label.global_position.x + randf_range(-60.0, 60.0)
	var target_y = xp_label.global_position.y - randf_range(80.0, 120.0)
	
	var tw = create_tween().set_parallel(true)
	
	tw.tween_property(xp_label, "global_position", Vector2(target_x, target_y), 0.7).set_ease(Tween.EASE_OUT)
	
	tw.tween_property(xp_label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_delay(0.2)
	
	tw.chain().tween_callback(xp_label.queue_free)

# --- ВІЗУАЛЬНИЙ ВІДГУК НОВОГО РІВНЯ ---
func _on_leveled_up(new_level: int) -> void:
	update_ui()





# --- cheats ---
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if not $UILayer.has_node("AdminMenu"):
			var admin_scene = preload("res://Core/cheats/AdminMenu.tscn")
			var admin_instance = admin_scene.instantiate()
			$UILayer.add_child(admin_instance)
