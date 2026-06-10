extends PanelContainer

signal buy_requested(item_id: String, price: int, for_gem: bool)
signal info_requested(item_id: String, button_global_pos: Vector2)

@export var item_id: String = ""

var item_name: String = ""
var item_price: int = 10
var for_gem: bool = false
var card_bg_color: Color = Color("a9744c")
var card_border_color: Color = Color("885434")

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
	price_label.text = str(item_price)
	
	var icon_path = item_data.get("icon", "")
	if icon_path != "":
		icon_rect.texture = load(icon_path)
	
	if for_gem:
		coin_rect.texture = preload("res://Assets/Graphics/Icons/Сurrency/Meowgem-currency-ai.png")
	else:
		coin_rect.texture = preload("res://Assets/Graphics/Icons/Сurrency/Meowcoin-currency-ai.png")
	
	# Наприклад: 
	# if item_data.get("rarity") == "epic":
	#     card_border_color = Color(0.8, 0.2, 0.8)

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
	if Global.inventory.has(item_id):
		var item_data = Global.inventory[item_id]
		
		if typeof(item_data) == TYPE_BOOL:
			if item_data == true:
				_set_bought_state("КУПЛЕНО")
				return 
		else:
			if item_data >= Global.MAX_STACK:
				_set_bought_state("МАКС (" + str(Global.MAX_STACK) + ")")
				return 
	
	_set_normal_state()
	
	var can_afford = false
	if for_gem:
		can_afford = Global.meowgem >= item_price
	else:
		can_afford = Global.meowcoin >= item_price 
		
	buy_button.disabled = false 
	
	if can_afford:
		price_label.modulate = Color(1, 1, 1) 
	else:
		price_label.modulate = Color(1, 0.4, 0.4) 

# --- ФУНКЦІЇ СТАНУ КНОПКИ ---

func _set_bought_state(text: String) -> void:
	buy_button.disabled = true
	buy_label.text = text
	price_bg.visible = false
	price_label.modulate = Color(1, 1, 1)

func _set_normal_state() -> void:
	buy_label.text = "КУПИТИ" 
	price_bg.visible = true

# --- НАТИСКАННЯ НА КНОПКИ ---

func _on_buy_button_pressed() -> void:
	buy_requested.emit(item_id, item_price, for_gem)

func _on_info_button_pressed() -> void:
	info_requested.emit(item_id, info_button.global_position)

# --- АНІМАЦІЇ ТА ПОВІДОМЛЕННЯ ---

func play_success_animation() -> void:
	anim_player.play("purchase_success")
	Global.show_floating_text("+1! " + item_name, Color(0.4, 1.0, 0.4))
	update_state() 

func play_error_animation() -> void:
	anim_player.play("purchase_error")
	Global.show_floating_text("МАЛО КОШТІВ", Color(1.0, 0.4, 0.4))
