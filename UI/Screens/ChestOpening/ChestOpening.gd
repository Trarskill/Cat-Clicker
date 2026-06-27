extends CanvasLayer

# --- ЗМІННІ СТАНУ ТА НАЛАШТУВАННЯ ---
var clicks_left: int = 3
var chest_id: String = "mysterious_chest"
var shake_tween: Tween
var base_chest_y: float = 0.0
var dropped_items: Array = []

# --- ЗАВАНТАЖЕННЯ ТЕКСТУР ---
const TEX_CHEST_CLOSED = preload("res://Assets/Graphics/EnvAnim/ChestOpening/ChestOpening-close.png")
const TEX_CHEST_OPEN = preload("res://Assets/Graphics/EnvAnim/ChestOpening/ChestOpening-open.png") 

# --- ВУЗЛИ ІЗ СЦЕНИ ---
@onready var bg_image = $BackgroundImage
@onready var hint_label = $VBox/HintLabel
@onready var center_node = $VBox/Center
@onready var effect_rect = $VBox/Center/EffectRect
@onready var chest_button = $VBox/Center/ChestSpace/ChestButton
@onready var count_label = $VBox/CountLabel
@onready var close_button = $VBox/ContinueButton

# --- ІНІЦІАЛІЗАЦІЯ СЦЕНИ ---
# Викликається при старті: підключає кнопки, встановлює 
# стартовий текст, центрує елементи та запускає анімацію появи
func _ready() -> void:
	chest_button.pressed.connect(_on_chest_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	count_label.text = str("• • •")
	
	await get_tree().process_frame
	
	base_chest_y = chest_button.position.y 
	
	center_node.pivot_offset = center_node.size / 2.0
	chest_button.pivot_offset = chest_button.size / 2.0
	
	play_appear_animation()

# --- ОБРОБКА КЛІКІВ ПО СКРИНІ ---
# Зменшує лічильник кліків, викликає тряску та 
# змінює колір/індикатори з кожним ударом
func _on_chest_pressed() -> void:
	if clicks_left <= 0:
		return 
		
	clicks_left -= 1
	play_shake_animation()
	
	if clicks_left == 2:
		chest_button.modulate = Color(1.2, 0.95, 0.95) 
		count_label.text = str("• •")
	elif clicks_left == 1:
		chest_button.modulate = Color(1.5, 0.75, 0.75)
		count_label.text = str(" • ")
	elif clicks_left == 0:
		chest_button.modulate = Color(1, 1, 1)
		open_chest()

# --- ЛОГІКА ВІДКРИТТЯ СКРИНІ ---
# Звертається до Global за лутом, блокує кнопку 
# взаємодії та запускає фінальну епічну анімацію
func open_chest() -> void:
	dropped_items = Global.open_lootbox(chest_id)
	
	chest_button.disabled = true
	count_label.text = str(" ") 
	
	play_final_animation()

# --- АНІМАЦІЯ ПОЯВИ СЦЕНИ ---
# Плавно показує затемнений фон та змушує 
# скриню ефектно "вистрибнути" з центру екрана
func play_appear_animation() -> void:
	center_node.scale = Vector2(0.1, 0.1)
	bg_image.modulate.a = 0.0 
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_image, "modulate:a", 1.0, 0.4)
	tw.tween_property(center_node, "scale", Vector2(1.0, 1.0), 0.5)

# --- АНІМАЦІЯ УДАРУ ТА ТРЯСКИ ---
# Змушує скриню підстрибувати та обертатися, а 
# також створює хаотичну вібрацію всього екрана (Screen Shake)
func play_shake_animation() -> void:
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		
	shake_tween = create_tween()
	
	chest_button.rotation_degrees = 0.0
	chest_button.position.y = base_chest_y
	offset = Vector2.ZERO
	
	shake_tween.tween_property(chest_button, "position:y", base_chest_y - 15, 0.05)
	shake_tween.parallel().tween_property(chest_button, "rotation_degrees", -6.0, 0.05)
	
	shake_tween.tween_property(chest_button, "position:y", base_chest_y, 0.05)
	shake_tween.parallel().tween_property(chest_button, "rotation_degrees", 6.0, 0.05)
	
	shake_tween.tween_property(chest_button, "position:y", base_chest_y - 8, 0.05)
	shake_tween.parallel().tween_property(chest_button, "rotation_degrees", -3.0, 0.05)
	
	shake_tween.tween_property(chest_button, "position:y", base_chest_y, 0.05)
	shake_tween.parallel().tween_property(chest_button, "rotation_degrees", 0.0, 0.05)
	
	var screen_tw = create_tween()
	screen_tw.tween_property(self, "offset", Vector2(-6, 4), 0.04)
	screen_tw.tween_property(self, "offset", Vector2(5, -5), 0.04)
	screen_tw.tween_property(self, "offset", Vector2(-3, 3), 0.04)
	screen_tw.tween_property(self, "offset", Vector2(2, -2), 0.04)
	screen_tw.tween_property(self, "offset", Vector2.ZERO, 0.04)

# --- ФІНАЛЬНА ЕПІЧНА АНІМАЦІЯ ---
# Відчиняє скриню, створює яскравий спалах світла, ховає 
# скриню, показує лут і надсилає сигнал оновлення UI
func play_final_animation() -> void:
	play_shake_animation()
	await get_tree().create_timer(0.25).timeout
	
	chest_button.texture_normal = TEX_CHEST_OPEN
	
	effect_rect.pivot_offset = effect_rect.size / 2.0 
	effect_rect.scale = Vector2(0.1, 0.1) 
	effect_rect.modulate.a = 0.0
	
	# --- ЕТАП 1: Спалах світла та розчинення скрині ---
	var fx_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	fx_tween.tween_property(effect_rect, "modulate:a", 1.0, 0.4)
	fx_tween.tween_property(effect_rect, "scale", Vector2(1.2, 1.2), 0.4)
	fx_tween.tween_property(chest_button, "modulate:a", 0.0, 0.3)
	fx_tween.tween_property(chest_button, "scale", Vector2(0.5, 0.5), 0.3)
	
	await fx_tween.finished
	
	# --- ЕТАП 2: Поява нагороди по центру ---
	await show_centered_reward()
	
	# --- ЕТАП 3: Фінальні штрихи (Текст та Кнопка) ---
	var final_tw = create_tween()
	hint_label.modulate.a = 0.0
	hint_label.text = "ВІДКРИТО!" 
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	
	final_tw.tween_property(hint_label, "modulate:a", 1.0, 0.5)
	close_button.visible = true
	close_button.text = str("Продовжити")
	
	# Оновлення дешборду
	get_tree().call_group("UI", "update_ui")

# --- ЕПІЧНА ПОЯВА НАГОРОДИ ПО ЦЕНТРУ ---
# Динамічно розраховує розмір і позицію елементів 
# (залежно від кількості) і плавно викидає їх з центру сяйва
func show_centered_reward() -> void:
	var items_to_spawn = dropped_items.size()
	var chest_center_global = chest_button.global_position + (chest_button.size / 2.0)
	
	for i in range(items_to_spawn):
		var item_data = dropped_items[i]
		
		var icon_size = 115
		var font_sz = 34
		
		if items_to_spawn > 1:
			icon_size = 95
			font_sz = 28
			
		var item_box = VBoxContainer.new()
		item_box.alignment = BoxContainer.ALIGNMENT_CENTER
		item_box.custom_minimum_size = Vector2(icon_size + 20, icon_size + 50)
		item_box.size = Vector2(icon_size + 20, icon_size + 50) 
		
		var loot_icon = TextureRect.new()
		loot_icon.texture = get_icon_for_item(item_data["id"]) 
		loot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		loot_icon.custom_minimum_size = Vector2(icon_size, icon_size) 
		loot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var amount_label = Label.new()
		amount_label.text = str(item_data["amount"])
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount_label.add_theme_font_size_override("font_size", font_sz)
		amount_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) 
		amount_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		amount_label.add_theme_constant_override("outline_size", 6)
		
		item_box.add_child(loot_icon)
		item_box.add_child(amount_label)
		add_child(item_box)
		
		item_box.pivot_offset = item_box.size / 2.0
		
		item_box.global_position = chest_center_global - (item_box.size / 2.0)
		item_box.scale = Vector2(0.1, 0.1)
		item_box.modulate.a = 0.0

		var target_x = chest_center_global.x - 71.0
		
		if items_to_spawn == 2:
			if i == 0:
				target_x -= 80 
			else:
				target_x += 80 
		
		var target_pos = Vector2(target_x, chest_center_global.y - 40.0) - (item_box.size / 2.0)
		
		var loot_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		loot_tw.tween_property(item_box, "global_position", target_pos, 0.5)
		loot_tw.tween_property(item_box, "scale", Vector2(1.0, 1.0), 0.5)
		loot_tw.tween_property(item_box, "modulate:a", 1.0, 0.2)
		
		await get_tree().create_timer(0.15).timeout

# --- ДОПОМІЖНА ФУНКЦІЯ ЗАВАНТАЖЕННЯ ІКОНОК ---
# Повертає жорстко задану картинку для базової валюти 
# або шукає шлях до іконки в базі даних DataManager
func get_icon_for_item(id: String) -> Texture2D:
	if id == "meowcoin": 
		return preload("res://Assets/Graphics/Icons/Сurrency/Meowcoin-currency-ai.png")
	if id == "meowgem": 
		return preload("res://Assets/Graphics/Icons/Сurrency/Meowgem-currency-ai.png")
		
	var item_data = DataManager.get_item(id)
	
	if not item_data.is_empty() and item_data.has("icon"):
		return load(item_data["icon"]) 
		
	return preload("res://Assets/Graphics/Icons/empty.png")

# --- ЗАКРИТТЯ СЦЕНИ ---
# Знищує сцену скрині та повертає гравця до 
# основного процесу гри після натискання кнопки
func _on_close_pressed() -> void:
	queue_free()
