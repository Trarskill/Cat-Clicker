extends PanelContainer

signal info_requested(item_id: String, click_position: Vector2)

@export var item_id: String = ""
@export var item_name: String = "Предмет"
@export var item_icon: Texture2D

var quantity: int = 0

@onready var icon_rect = $ItemIcon
@onready var count_label = $CountLabel
@onready var click_area = $ClickArea
@onready var timer_label = $TimerLabel

func _ready():
	if item_icon:
		icon_rect.texture = item_icon
	
	click_area.pressed.connect(_on_card_pressed)

func _process(_delta: float) -> void:
	if item_id == "bowl_with_bone" and Global.bowl_bone_timer > 0:
		timer_label.visible = true
		timer_label.text = str(int(Global.bowl_bone_timer)) + "с"
	elif item_id == "bag_of_fruit" and Global.bag_of_fruit_timer > 0:
		timer_label.visible = true
		timer_label.text = str(int(Global.bag_of_fruit_timer)) + "с"
	else:
		if timer_label:
			timer_label.visible = false

func update_data(new_quantity):
	quantity = new_quantity
	
	if typeof(Global.inventory[item_id]) == TYPE_BOOL or quantity <= 1:
		count_label.visible = false
	else:
		count_label.visible = true
		count_label.text = str(quantity)

func set_equipped_visual(is_equipped: bool) -> void:
	if is_equipped:
		self_modulate = Color(0.65, 1.0, 0.65) 
	else:
		self_modulate = Color(1.0, 1.0, 1.0)

func _on_card_pressed():
	info_requested.emit(item_id, global_position)
