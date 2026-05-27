extends Control

signal tab_clicked(tab_id: String)

@export var tab_id: String = "general"
@export var tab_text: String = "Вкладка"
@export var tab_icon: Texture2D
@export var texture_normal: Texture2D
@export var texture_active: Texture2D

@onready var background = $Background
@onready var icon_rect = $Margin/HBox/Icon
@onready var label = $Margin/HBox/Label
@onready var click_area = $ClickArea

func _ready():
	label.text = tab_text
	
	if tab_icon:
		icon_rect.texture = tab_icon
		
	# ОДРАЗУ ставимо базовий фон, щоб він не був прозорим при запуску
	if texture_normal:
		background.texture = texture_normal
	
	click_area.pressed.connect(_on_click_area_pressed)

func _on_click_area_pressed():
	tab_clicked.emit(tab_id)

func set_active(is_active: bool):
	if is_active:
		if texture_active: background.texture = texture_active
		label.modulate = Color(1.0, 0.9, 0.7) # Робимо текст золотистішим
	else:
		if texture_normal: background.texture = texture_normal
		label.modulate = Color(0.8, 0.8, 0.8) # Робимо текст тьмянішим
