extends PanelContainer

signal buy_requested(item_id: String, price: int, for_gem: bool)
signal info_requested(item_id: String, button_global_pos: Vector2)

@export var item_id: String = ""

var item_name: String = ""
var item_price: int = 10
var for_gem: bool = false
var card_bg_color: Color = Color("a9744c")
var card_border_color: Color = Color("885434")

# --- НОВІ ЗМІННІ ДЛЯ МУЛЬТИ-ПОКУПКИ ---
var current_buy_amount: int = 1
var last_anim_time: float = 0.0

@onready var title_label = $Margin/HBox/TextContent/TitleLabel
@onready var info_button = $Margin/HBox/TextContent/InfoButton
@onready var buy_button = $Margin/HBox/BuyButton
@onready var buy_label = $Margin/HBox/BuyButton/InnerContent/BuyLabel
@onready var price_bg = $Margin/HBox/BuyButton/InnerContent/PriceBg
@onready var price_label = $Margin/HBox/BuyButton/InnerContent/PriceBg/Margin/PriceBox/PriceLabel
@onready var icon_frame = $Margin/HBox/IconFrame 
@onready var icon_rect = $Margin/HBox/IconFrame/ItemIcon
@onready var coin_rect = $Margin/HBox/BuyButton/InnerContent/PriceBg/Margin/PriceBox/CoinIcon
@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	if not buy_button.pressed.is_connected(_on_buy_button_pressed):
		buy_button.pressed.connect(_on_buy_button_pressed)
		
	if not info_button.pressed.is_connected(_on_info_button_pressed):
		info_button.pressed.connect(_on_info_button_pressed)
		
	_load_data_from_db()
	_setup_styles()
	update_state()

func _load_data_from_db() -> void:
	if item_id == "": return
	
	var item_data = DataManager.get_item(item_id)
	if item_data.is_empty(): return
	
	item_name = item_data.get("name", "Невідомий предмет")
	item_price = item_data.get("price", 10)
	for_gem = item_data.get("for_gem", false)
	
	title_label.text = item_name
	
	var icon_path = item_data.get("icon", "")
	if icon_path != "":
		icon_rect.texture = load(icon_path)
	
	if for_gem:
		coin_rect.texture = preload("res://Assets/Graphics/Icons/Сurrency/Meowgem-currency-ai.png")
	else:
		coin_rect.texture = preload("res://Assets/Graphics/Icons/Сurrency/Meowcoin-currency-ai.png")

func _setup_styles() -> void:
	var icon_style = icon_frame.get_theme_stylebox("panel").duplicate()
	icon_style.bg_color = card_bg_color
	icon_style.border_color = card_border_color
	icon_style.border_width_left = 4
	icon_style.border_width_top = 4
	icon_style.border_width_right = 4
	icon_style.border_width_bottom = 4
	icon_style.corner_radius_top_left = 12
	icon_style.corner_radius_top_right = 12
	icon_style.corner_radius_bottom_right = 12
	icon_style.corner_radius_bottom_left = 12
	
	icon_frame.add_theme_stylebox_override("panel", icon_style)

# --- ОНОВЛЕННЯ СТАНУ ---
func update_state() -> void:
	if item_id == "": return
	
	var item_data = DataManager.get_item(item_id)
	if item_data.is_empty(): return
	
	var item_type = item_data.get("type")
	var current_amount = Global.inventory.get(item_id, 0)
	
	# --- 1. ДИНАМІЧНА ЦІНА ДЛЯ РОЗИ ---
	if item_id == "magical_rose":
		item_price = Global.get_magical_rose_price()
			
	# --- 2. ПЕРЕВІРКА СТАКІВ ТА ВІЛЬНОГО МІСЦЯ В ІНВЕНТАРІ ---
	var space_left = 1
	if typeof(current_amount) == TYPE_BOOL:
		if current_amount == true:
			_set_bought_state("КУПЛЕНО")
			return 
		space_left = 1
	else:
		space_left = max(0, Global.MAX_STACK - int(current_amount))
		if space_left <= 0:
			_set_bought_state("МАКС (" + str(Global.MAX_STACK) + ")")
			return 
	
	# --- 3. РОЗРАХУНОК МУЛЬТИ-ПОКУПКИ ---
	var target_amount = Global.multi_click_options[Global.current_multi_idx]
	
	if item_type == DataManager.ItemType.EQUIPMENT or item_type == DataManager.ItemType.KEY_ITEM:
		target_amount = 1
	
	if target_amount == 999:
		target_amount = space_left
	
	current_buy_amount = min(target_amount, space_left)
	
	var total_price = item_price * current_buy_amount
	price_label.text = str(total_price)
	
	if current_buy_amount > 1:
		if target_amount == space_left and Global.multi_click_options[Global.current_multi_idx] == 999:
			_set_normal_state("ВСІ (" + str(current_buy_amount) + ")")
		else:
			_set_normal_state("КУПИТИ x" + str(current_buy_amount))
	else:
		_set_normal_state("КУПИТИ")
	
	# --- 4. ПЕРЕВІРКА ПЛАТОСПРОМОЖНОСТІ ---
	var currency = Global.meowgem if for_gem else Global.meowcoin
	buy_button.disabled = false 
	
	if currency >= total_price:
		price_label.modulate = Color(1, 1, 1) 
	else:
		price_label.modulate = Color(1, 0.4, 0.4)

# --- ФУНКЦІЇ СТАНУ КНОПКИ ---

func _set_bought_state(text: String) -> void:
	buy_button.disabled = true
	buy_label.text = text
	price_bg.visible = false
	price_label.modulate = Color(1, 1, 1)

func _set_normal_state(text: String) -> void:
	buy_label.text = text 
	price_bg.visible = true

# --- НАТИСКАННЯ НА КНОПКИ ---

func _on_buy_button_pressed() -> void:
	var total_price = item_price * current_buy_amount
	var currency = Global.meowgem if for_gem else Global.meowcoin
	
	if currency < total_price:
		play_error_animation()
		return
	
	for i in range(current_buy_amount):
		buy_requested.emit(item_id, item_price, for_gem)

func _on_info_button_pressed() -> void:
	info_requested.emit(item_id, info_button.global_position)

# --- АНІМАЦІЇ ТА ПОВІДОМЛЕННЯ ---

func play_success_animation() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	anim_player.play("purchase_success")
	
	if current_time - last_anim_time > 0.05:
		if current_buy_amount > 1:
			Global.show_floating_text("+" + str(current_buy_amount) + "! " + item_name, Color(0.4, 1.0, 0.4))
		else:
			Global.show_floating_text("+1! " + item_name, Color(0.4, 1.0, 0.4))
			
	last_anim_time = current_time
	update_state() 

func play_error_animation() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	anim_player.play("purchase_error")
	
	if current_time - last_anim_time > 0.05:
		Global.show_floating_text("МАЛО КОШТІВ", Color(1.0, 0.4, 0.4))
		
	last_anim_time = current_time
