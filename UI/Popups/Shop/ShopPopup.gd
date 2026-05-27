extends Control

signal state_changed(new_state)
signal item_bought

enum State { CLOSED, PARTIAL, FULL }
var current_state = State.CLOSED

@onready var panel = $Panel
@onready var arrow = $Panel/MainLayout/HandleArea/Arrow
@onready var handle_area = $Panel/MainLayout/HandleArea
@onready var shop_group = $Panel/MainLayout/ButtonShopGroup

# Посилання на наші 3 списки
@onready var general_list = $Panel/MainLayout/MarginContainer/ScrollContainer/ShopLists/GeneralList
@onready var weapon_list = $Panel/MainLayout/MarginContainer/ScrollContainer/ShopLists/WeaponList
@onready var magic_list = $Panel/MainLayout/MarginContainer/ScrollContainer/ShopLists/MagicList

var pos_closed := 0.0
var pos_partial := 770.0 # приблизно 60%
var pos_full := 1280.0

func _ready() -> void:
	panel.position.y = 0
	visible = false 
	handle_area.pressed.connect(_on_handle_pressed)
	
	# З'єднуємо сигнал від групи кнопок
	if shop_group:
		shop_group.shop_category_changed.connect(_on_category_changed)
		
	# Підключаємо ВСІ картки товарів до єдиної функції покупок
	var all_lists = [general_list, weapon_list, magic_list]
	for list in all_lists:
		for element in list.get_children():
			if element.has_signal("buy_requested"):
				element.buy_requested.connect(_on_buy_requested)
	
	update_all_cards()

# --- ЛОГІКА ПОКУПОК ТА АНІМАЦІЙ ---

func _on_buy_requested(item_id: String, price: int, is_premium: bool) -> void:
	# 1. Знаходимо картку, яка відправила запит (щоб програти анімацію саме на ній)
	var card_sender = null
	var all_lists = [general_list, weapon_list, magic_list]
	
	for list in all_lists:
		for element in list.get_children():
			# Перевіряємо, чи це наша картка з потрібним ID
			if element.has_method("play_success_animation") and element.item_id == item_id:
				card_sender = element
				break
		if card_sender: 
			break

	# 2. Робимо покупку через глобальний банк
	var success = Global.buy_item(item_id, price, is_premium)
	
	# 3. Вибираємо анімацію
	if success:
		if card_sender: 
			card_sender.play_success_animation()
			
		item_bought.emit()
		update_all_cards()
		
		SaveManager.save_game()
	else:
		if card_sender: 
			card_sender.play_error_animation()

func update_all_cards() -> void:
	var all_lists = [general_list, weapon_list, magic_list]
	for list in all_lists:
		for element in list.get_children():
			if element.has_method("update_state"):
				element.update_state()

# --- ЛОГІКА ІНТЕРФЕЙСУ (Перемикання та рух вікна) ---

func _on_category_changed(category_id: String) -> void:
	# Спочатку ховаємо всі списки
	general_list.visible = false
	weapon_list.visible = false
	magic_list.visible = false
	
	# Показуємо тільки активний
	match category_id:
		"general": general_list.visible = true
		"weapon": weapon_list.visible = true
		"magic": magic_list.visible = true

func toggle_shop() -> void:
	if current_state == State.CLOSED:
		animate_to_state(State.PARTIAL)
	else:
		animate_to_state(State.CLOSED)

func _on_handle_pressed() -> void:
	if current_state == State.PARTIAL:
		animate_to_state(State.FULL)
	elif current_state == State.FULL:
		animate_to_state(State.PARTIAL)

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

func close() -> void:
	animate_to_state(State.CLOSED)
