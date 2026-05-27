extends PanelContainer

signal buy_requested(item_id: String, price: int, is_premium: bool)

@export var item_id: String = ""
@export var item_name: String = ""
@export var item_desc: String = ""
@export var item_price: int = 10
@export var item_icon: Texture2D
@export var currency_icon: Texture2D 
@export var is_premium: bool = false 

@onready var title_label = $Margin/HBox/TextContent/TitleLabel
@onready var desc_label = $Margin/HBox/TextContent/DescLabel
@onready var price_label = $Margin/HBox/ActionContent/PriceBox/PriceLabel
@onready var icon_rect = $Margin/HBox/IconFrame/ItemIcon
@onready var coin_rect = $Margin/HBox/ActionContent/PriceBox/CoinIcon
@onready var buy_button = $Margin/HBox/ActionContent/BuyButton
@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	title_label.text = item_name
	desc_label.text = item_desc
	price_label.text = str(item_price)
	
	if item_icon: icon_rect.texture = item_icon
	if currency_icon: coin_rect.texture = currency_icon
		
	buy_button.pressed.connect(_on_buy_button_pressed)
	update_state()

func _on_buy_button_pressed() -> void:
	buy_requested.emit(item_id, item_price, is_premium)

# --- АНІМАЦІЇ ТА ПОВІДОМЛЕННЯ ---

func play_success_animation() -> void:
	anim_player.play("purchase_success")
	Global.show_floating_text("+1! " + item_name, Color(0.4, 1.0, 0.4)) # Зелений колір
	update_state() 

func play_error_animation() -> void:
	anim_player.play("purchase_error")
	Global.show_floating_text("МАЛО КОШТІВ", Color(1.0, 0.4, 0.4)) # Червоний колір

# --- ОНОВЛЕННЯ СТАНУ ---

func update_state() -> void:
	if not Global.inventory.has(item_id): return
	
	var item_data = Global.inventory[item_id]
	
	if typeof(item_data) == TYPE_BOOL:
		if item_data == true:
			buy_button.text = "КУПЛЕНО"
			buy_button.disabled = true
	else:
		if item_data >= Global.MAX_STACK:
			buy_button.text = "МАКС (16)"
			buy_button.disabled = true
