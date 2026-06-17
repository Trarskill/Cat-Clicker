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
	# Захист на випадок, якщо вузол ще не завантажився
	if not timer_label: 
		return 

	var time_left: float = 0.0

	# 1. Визначаємо, скільки часу залишилося для поточного предмета
	match item_id:
		"bowl_with_bone": time_left = Global.bowl_bone_timer
		"bowl_with_rice": time_left = Global.bowl_rice_timer
		"bowl_with_fish": time_left = Global.bowl_fish_timer
		"bag_of_fruit": time_left = Global.bag_of_fruit_timer
		"catnip": time_left = Global.catnip_timer
		"clockwork_mouse":
			# Унікальна логіка для мишки: показуємо або час роботи, або кулдаун
			if Global.clockwork_mouse_timer > 0:
				time_left = Global.clockwork_mouse_timer
				timer_label.modulate = Color(0.4, 1.0, 0.4) # Зелений (Працює)
			elif Global.clockwork_mouse_cooldown > 0:
				time_left = Global.clockwork_mouse_cooldown
				timer_label.modulate = Color(1.0, 0.4, 0.4) # Червоний (Кулдаун)

	# 2. Вмикаємо або вимикаємо відображення таймера
	if time_left > 0:
		timer_label.visible = true
		
		timer_label.text = str(int(time_left)) + "с"
	else:
		timer_label.visible = false
		timer_label.modulate = Color(1, 1, 1) # Скидаємо колір до стандартного білого

func update_data(new_quantity):
	quantity = new_quantity
	
	if typeof(Global.inventory[item_id]) == TYPE_BOOL or quantity <= 1:
		count_label.visible = false
	else:
		count_label.visible = true
		count_label.text = str(quantity)
	
	if quantity == 0:
		icon_rect.modulate = Color(0.4, 0.4, 0.4, 0.8) 
	else:
		icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) 
	
	click_area.mouse_filter = Control.MOUSE_FILTER_STOP

func set_equipped_visual(is_equipped: bool) -> void:
	if is_equipped:
		self_modulate = Color(0.65, 1.0, 0.65) 
	else:
		self_modulate = Color(1.0, 1.0, 1.0)

func _on_card_pressed():
	info_requested.emit(item_id, global_position)
