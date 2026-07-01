extends Control

# --- СИГНАЛИ ТА СТАНИ МАГАЗИНУ ---
signal state_changed(new_state)
signal item_bought

# Перелік можливих станів вікна:
enum State { CLOSED, PARTIAL, FULL }
var current_state = State.CLOSED

@onready var panel = $Panel
@onready var arrow = $Panel/MainLayout/HandleArea/ButtonArrow/Arrow
@onready var handle_area = $Panel/MainLayout/HandleArea/ButtonArrow
@onready var shop_group = $Panel/MainLayout/ButtonShopGroup

@onready var general_list = $Panel/MainLayout/MarginContainer/ScrollContainer/ShopLists/GeneralList
@onready var weapon_list = $Panel/MainLayout/MarginContainer/ScrollContainer/ShopLists/WeaponList
@onready var magic_list = $Panel/MainLayout/MarginContainer/ScrollContainer/ShopLists/MagicList

# --- ЗМІННІ ДЛЯ АНІМАЦІЇ ---
var pos_closed := 0.0
var pos_partial := 805.0 # приблизно 63%
var pos_full := 1280.0

# Зберігає посилання на поточне відкрите
# віконце з детальним описом предмета
var current_popup = null

# --- ІНІЦІАЛІЗАЦІЯ ВІКНА МАГАЗИНУ ---
# Викликається при старті. Встановлює початкову позицію, приховує вікно 
# та підключає всі необхідні сигнали від кнопок категорій та карток товарів.
func _ready() -> void:
	panel.position.y = 0
	visible = false 
	handle_area.pressed.connect(_on_handle_pressed)
	Global.multi_mode_changed.connect(update_all_cards)
	
	if shop_group:
		shop_group.shop_category_changed.connect(_on_category_changed)
	
	var all_lists = [general_list, weapon_list, magic_list]
	for list in all_lists:
		for element in list.get_children():
			if element.has_signal("buy_requested"):
				element.buy_requested.connect(_on_buy_requested)
			if element.has_signal("info_requested"):
				element.info_requested.connect(_on_card_info_requested)

# --- ЛОГІКА ПОКУПОК ТА АНІМАЦІЙ ---

# --- ОБРОБКА СПРОБИ ПОКУПКИ ---
# Викликається, коли гравець тисне кнопку ціни на картці. 
# Передає запит у Global, програє анімацію успіху чи помилки, 
# зберігає гру та оновлює всі картки.
func _on_buy_requested(item_id: String, price: int, for_gem: bool) -> void:
	var card = _get_card_by_id(item_id)
	if not card: return
	
	var success = Global.buy_item(item_id, price, for_gem)
	
	if success:
		card.play_success_animation()
		item_bought.emit()
		update_all_cards()
		AudioManager.play_sfx(Global.SFX["BUY_SUCCESS"], false, true)
	else:
		card.play_error_animation()
		AudioManager.play_sfx(Global.SFX["BUY_ERROR"], false, true)

# --- ОНОВЛЕННЯ СТАНУ КАРТОК ---
# Проходить по всіх списках магазину і викликає функцію оновлення у кожної картки 
# (щоб перевірити, чи вистачає грошей, чи досягнуто ліміт покупки)
func update_all_cards() -> void:
	var all_lists = [general_list, weapon_list, magic_list]
	for list in all_lists:
		for element in list.get_children():
			if element.has_method("update_state"):
				element.update_state()

# --- ДОПОМІЖНА ФУНКЦІЯ ПОШУКУ КАРТКИ ---

# --- ПОШУК КАРТКИ ЗА ID ---
func _get_card_by_id(target_id: String) -> Node:
	var all_lists = [general_list, weapon_list, magic_list]
	for list in all_lists:
		for element in list.get_children():
			if element.get("item_id") == target_id:
				return element
	return null

# --- ЛОГІКА ІНТЕРФЕЙСУ (Перемикання та рух вікна) ---

# --- ПЕРЕМИКАННЯ ВКЛАДОК МАГАЗИНУ ---
func _on_category_changed(category_id: String) -> void:
	general_list.visible = false
	weapon_list.visible = false
	magic_list.visible = false
	
	match category_id:
		"general": general_list.visible = true
		"weapon": weapon_list.visible = true
		"magic": magic_list.visible = true

# --- ВІДКРИТТЯ/ЗАКРИТТЯ МАГАЗИНУ ---
func toggle_shop() -> void:
	if current_state == State.CLOSED:
		animate_to_state(State.PARTIAL)
	else:
		animate_to_state(State.CLOSED)

# --- ОБРОБКА НАТИСКАННЯ НА РУЧКУ (СТРІЛКУ) ---
func _on_handle_pressed() -> void:
	if current_state == State.PARTIAL:
		animate_to_state(State.FULL)
	elif current_state == State.FULL:
		animate_to_state(State.PARTIAL)

# --- АНІМАЦІЯ РУХУ ВІКНА ---
func animate_to_state(target_state: State) -> void:
	current_state = target_state
	var target_y = 0.0
	
	if current_state != State.CLOSED:
		visible = true
		update_all_cards()
	
	match current_state:
		State.CLOSED: 
			target_y = 0.0
			arrow.visible = true
		State.PARTIAL: 
			target_y = -pos_partial
			arrow.visible = true 
		State.FULL: 
			target_y = -pos_full
			arrow.visible = false 
	
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", target_y, 0.5)
	
	if current_state == State.CLOSED:
		tween.finished.connect(func(): visible = false)
	
	state_changed.emit(current_state)

# --- ПРИМУСОВЕ ЗАКРИТТЯ МАГАЗИНУ ---
func close() -> void:
	remove_current_popup()
	
	animate_to_state(State.CLOSED)

# --- СТВОРЕННЯ ІНФОРМАЦІЙНОГО ВІКНА ---
func _on_card_info_requested(item_id: String, card_pos: Vector2) -> void:
	remove_current_popup() 
	
	var InteractionWindowScene = preload("res://UI/Components/InteractionWindow/InteractionWindow.tscn")
	var popup = InteractionWindowScene.instantiate()
	add_child(popup)
	current_popup = popup
	
	if popup.has_method("setup"):
		popup.setup(item_id, null, true)
	
	if popup.has_method("appear_at"):
		popup.appear_at(card_pos)

# --- ВИДАЛЕННЯ ІНФОРМАЦІЙНОГО ВІКНА ---
func remove_current_popup() -> void:
	if current_popup and is_instance_valid(current_popup):
		current_popup.hide()
		current_popup.queue_free()
		current_popup = null

# --- ОБРОБКА КЛІКІВ ПОЗА ВІКНОМ ---
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if current_popup and is_instance_valid(current_popup) and current_popup.is_inside_tree():
			var popup_rect = current_popup.get_global_rect()
			if not popup_rect.has_point(event.global_position):
				remove_current_popup()
