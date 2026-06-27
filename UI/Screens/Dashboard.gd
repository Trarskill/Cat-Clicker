extends Control

@onready var header = $UILayer/Header
@onready var lowbar = $UILayer/LowBar
@onready var click_area = $ClickArea
@onready var game_world = $GameWorld
@onready var background = $Background

@onready var settings_menu = $UILayer/SettingsMenu
@onready var settings_button = $UILayer/Header/HeaderLayout/SettingsButton

@onready var shop_popup = $UILayer/ShopPopup
@onready var inventory_popup = $UILayer/InventoryPopup

@onready var cat = $GameWorld/Cat
@onready var dummy = $GameWorld/Dummy

@onready var lowbar_shop_button = $UILayer/LowBar/Margin/Layout/ShopButton
@onready var lowbar_inventory_button = $UILayer/LowBar/Margin/Layout/InvButton

# --- ЗМІННІ СТАНУ ІНТЕРФЕЙСУ ТА АНІМАЦІЙ ---
var is_menu_locked: bool = false
var current_menu_offset_y: float = 0.0
var world_tween: Tween

# --- ІНІЦІАЛІЗАЦІЯ СЦЕНИ --- 
# Викликається один раз при старті сцени. Завантажує збереження, 
# оновлює інтерфейс та підключає всі необхідні сигнали кнопок і вікон.
func _ready() -> void:
	add_to_group("UI")
	
	SaveManager.load_game()
	update_ui()
	
	get_tree().call_group("UI", "update_ui")
	
	if cat.has_method("update_equipment_visuals"):
		cat.update_equipment_visuals()
	
	click_area.pressed.connect(_on_click_area_pressed)
	lowbar_shop_button.pressed.connect(_on_shop_button_pressed)
	lowbar_inventory_button.pressed.connect(_on_inventory_button_pressed)
	shop_popup.state_changed.connect(_on_shop_state_changed)
	shop_popup.item_bought.connect(_on_item_bought_success)
	inventory_popup.item_action_executed.connect(_on_inventory_action)
	inventory_popup.inventory_toggled.connect(_on_inventory_visibility_changed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	
	Global.leveled_up.connect(_on_leveled_up)
	
	resized.connect(_on_dashboard_resized)
	_on_dashboard_resized()

# --- АВТОМАТИЧНЕ ЦЕНТРУВАННЯ СВІТУ ---
# Викликається при зміні розміру вікна гри. 
# Тримає котика та манекен рівно по центру екрана 
# з урахуванням зсуву від відкритих меню.
func _on_dashboard_resized() -> void:
	game_world.position.x = size.x / 2.0
	game_world.position.y = (size.y / 2.0) + current_menu_offset_y

# --- ЛОГІКА ГОЛОВНОГО КЛІКУ (ОБЧИСЛЕННЯ) ---
# Функція запускає візуальні ефекти удару, звертається до 
# мозку гри (Global) для розрахунку результатів кліку 
# та викликає оновлення UI (спливаючий текст та шкали).
func _on_click_area_pressed() -> void:
	await cat.play_attack()
	await dummy.take_hit()
	
	var click_result = Global.process_click()
	
	show_xp_feedback(click_result["xp"])
	# --- ПЕРЕВІРКА НА ВУДОЧКУ ---
	if Global.equipped_weapon == "magic_fishing_rod":
		show_coin_feedback(1)
		
	update_ui()

# --- ОНОВЛЕННЯ ІНТЕРФЕЙСУ ---
# Синхронізує текст монет, гемів, шкали рівня та 
# карток магазину з актуальними даними з Global.
func update_ui() -> void:
	header.update_meowcoin(Global.meowcoin)
	header.update_rustycoin(Global.rustycoin)
	header.update_meowgem(Global.meowgem)
	
	var level_bar = lowbar.get_node("Margin/Layout/LevelBar")
	if level_bar:
		level_bar.update_level_data(Global.level, Global.xp, Global.max_xp)
	
	if shop_popup:
		shop_popup.update_all_cards()

# --- ШВИДКЕ ОНОВЛЕННЯ (ДЛЯ АВТОКЛІКЕРІВ) ---
# Оновлює лише ті елементи, які можуть змінюватися часто (досвід та монети),
# не навантажуючи магазин чи декорації.
func update_quick_stats() -> void:
	var level_bar = lowbar.get_node("Margin/Layout/LevelBar")
	if level_bar:
		level_bar.update_level_data(Global.level, Global.xp, Global.max_xp)
		
	header.update_meowcoin(Global.meowcoin)

# --- ОБРОБКА УСПІШНОЇ ПОКУПКИ ---
# Оновлює інтерфейс після того, як гравець щось придбав у магазині.
func _on_item_bought_success() -> void:
	get_tree().call_group("UI", "update_ui")

# --- ОБРОБКА КНОПКИ МАГАЗИНУ ---
# Відкриває або закриває магазин. Блокує інші натискання 
# під час анімації, щоб уникнути багів, та автоматично закриває інвентар.
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

# --- ОБРОБКА КНОПКИ ІНВЕНТАРЮ ---
# Відкриває або закриває інвентар. Якщо в цей момент 
# відкрито магазин, спочатку закриває його.
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

# --- ОБРОБКА КНОПКИ НАЛАШТУВАНЬ ---
# Запускає функцію керування вікном налаштувань
# При повторному натискані закриває вікно
func _on_settings_button_pressed() -> void:
	if is_menu_locked:
		return
		
	settings_menu.toggle()

# --- УНІВЕРСАЛЬНА ФУНКЦІЯ РУХУ СВІТУ ---
# Плавно зміщує ігровий світ та фон по вертикалі (використовуючи Tween),
# щоб звільнити місце для меню, яке виїжджає знизу.
func shift_game_world(target_y: float) -> void:
	current_menu_offset_y = target_y
	
	if world_tween and world_tween.is_valid():
		world_tween.kill()
		
	world_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var final_game_world_y = (size.y / 2.0) + target_y
	
	world_tween.tween_property(game_world, "position:y", final_game_world_y, 0.5)
	world_tween.tween_property(background, "position:y", target_y, 0.5)

# --- РЕАКЦІЯ НА ЗМІНУ СТАНУ МАГАЗИНУ ---
# Розраховує цільову позицію зміщення світу 
# залежно від того, наскільки відкрито вікно магазину.
func _on_shop_state_changed(new_state) -> void:
	var target_y = 0.0
	match new_state:
		shop_popup.State.CLOSED: target_y = 0.0
		shop_popup.State.PARTIAL: target_y = -210.0
		shop_popup.State.FULL: target_y = -350.0
			
	shift_game_world(target_y)

# --- РЕАКЦІЯ НА ВІДКРИТТЯ ІНВЕНТАРЮ ---
# Зміщує світ вгору при відкритті інвентарю 
# та повертає на місце при його закритті.
func _on_inventory_visibility_changed(is_open: bool) -> void:
	var target_y = -210.0 if is_open else 0.0
	shift_game_world(target_y)

# --- ВІЗУАЛЬНИЙ ВІДГУК ДЛЯ КЛІКІВ (СПЛИВАЮЧИЙ ДОСВІД) ---
# Створює текстовий вузол, який плавно відлітає від котика вгору 
# та розчиняється, показуючи кількість зароблених XP за клік.
func show_xp_feedback(amount: int) -> void:
	var xp_label = Label.new()
	xp_label.text = "+" + str(amount) + " XP"
	
	xp_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	xp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	xp_label.add_theme_constant_override("outline_size", 6)
	xp_label.add_theme_font_size_override("font_size", 28)
	
	xp_label.z_index = 100
	game_world.add_child(xp_label)
	
	var start_offset_x = randf_range(-70.0, 45.0)
	var start_offset_y = randf_range(-130.0, -80.0)
	xp_label.global_position = cat.global_position + Vector2(start_offset_x, start_offset_y)
	
	var target_x = xp_label.global_position.x + randf_range(-60.0, 60.0)
	var target_y = xp_label.global_position.y - randf_range(80.0, 120.0)
	
	var tw = create_tween().set_parallel(true)
	
	tw.tween_property(xp_label, "global_position", Vector2(target_x, target_y), 0.7).set_ease(Tween.EASE_OUT)
	
	tw.tween_property(xp_label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_delay(0.2)
	
	tw.chain().tween_callback(xp_label.queue_free)

# --- ВІЗУАЛЬНИЙ ВІДГУК ДЛЯ ЗДОБИЧІ (СПЛИВАЮЧІ МОНЕТИ) ---
# Створює текстовий вузол, який плавно відлітає від котика вгору 
# та розчиняється, показуючи кількість зароблених монет (наприклад, від вудочки).
func show_coin_feedback(amount: int) -> void:
	var coin_label = RichTextLabel.new()
	coin_label.bbcode_enabled = true
	coin_label.fit_content = true
	coin_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	coin_label.clip_contents = false
	
	var icon_path = "res://Assets/Graphics/Icons/Сurrency/Meowcoin-currency-ai.png"
	
	coin_label.text = "[center][color=gold]+" + str(amount) + "[/color][img=28]" + icon_path + "[/img][/center]"
	
	coin_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	coin_label.add_theme_constant_override("outline_size", 6)
	coin_label.add_theme_font_size_override("normal_font_size", 28)
	
	coin_label.z_index = 100
	game_world.add_child(coin_label)
	
	var start_offset_x = randf_range(-70.0, 45.0)
	var start_offset_y = randf_range(-130.0, -80.0)
	coin_label.global_position = cat.global_position + Vector2(start_offset_x, start_offset_y)
	
	var target_x = coin_label.global_position.x + randf_range(-60.0, 60.0)
	var target_y = coin_label.global_position.y - randf_range(80.0, 120.0)
	
	var tw = create_tween().set_parallel(true)
	
	tw.tween_property(coin_label, "global_position", Vector2(target_x, target_y), 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(coin_label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_delay(0.2)
	
	tw.chain().tween_callback(coin_label.queue_free)

# --- ОБРОБКА ДІЙ В ІНВЕНТАРІ ---
func _on_inventory_action():
	get_tree().call_group("UI", "update_ui")
	
	if cat.has_method("update_equipment_visuals"):
		cat.update_equipment_visuals()

# --- ВІЗУАЛЬНИЙ ВІДГУК НОВОГО РІВНЯ ---
func _on_leveled_up(_new_level: int) -> void:
	get_tree().call_group("UI", "update_ui")





# --- СИСТЕМА ЧІТІВ (ІГНОРУВАТИ ЦЮ ФУНКЦІЮ) --- 
# Обробляє натискання клавіш. Викликає приховане меню 
# адміністратора при натисканні клавіші F1, якщо воно ще не відкрито.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if not $UILayer.has_node("AdminMenu"):
			var admin_scene = preload("res://Core/cheats/AdminMenu.tscn")
			var admin_instance = admin_scene.instantiate()
			$UILayer.add_child(admin_instance)
