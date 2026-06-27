class_name IdleDecoration
extends Node2D

# --- ЗМІННІ ДЛЯ НАЛАШТУВАННЯ У ДОЧІРНІХ КЛАСАХ ---
var item_id: String = ""
var is_coin_reward: bool = false
var feedback_color: Color = Color.WHITE
var db_reward_key: String = ""

# Базові налаштування напрямку польоту 
var text_start_offset_x: Vector2 = Vector2(-40.0, -10.0)
var text_start_offset_y: Vector2 = Vector2(-60.0, -40.0)
var text_target_x_range: Vector2 = Vector2(-40.0, 0.0)
var text_target_y_range: Vector2 = Vector2(70.0, 100.0)

# --- ВНУТРІШНІ ЗМІННІ ---
var is_active: bool = false
var transition_tween: Tween
var idle_timer: float = 0.0
var idle_interval: float = 0.0
var reward_amount: int = 0

# --- ІНІЦІАЛІЗАЦІЯ ОБ'ЄКТА ---
# Викликається при створенні. Ховає предмет, додає його до групи UI для 
# глобальних оновлень та завантажує параметри з бази даних.
func _ready() -> void:
	add_to_group("UI")
	scale = Vector2.ZERO
	visible = false
	is_active = false
	
	_load_stats_from_db()
	update_ui()

# --- ЗАВАНТАЖЕННЯ ДАНИХ З БД ---
# Отримує інформацію про предмет з DataManager (інтервал часу та розмір нагороди) 
# залежно від його унікального item_id.
func _load_stats_from_db() -> void:
	if item_id == "": return
	
	var item_data = DataManager.get_item(item_id)
	if not item_data.is_empty() and item_data.has("stats"):
		idle_interval = float(item_data["stats"].get("tick_rate", 5.0))
		reward_amount = int(item_data["stats"].get(db_reward_key, 1))

# --- ВІДЛІК ЧАСУ (ГОЛОВНИЙ ЦИКЛ) ---
# Постійно додає час до таймера, якщо предмет активний. Коли таймер 
# досягає ліміту, запускає процес видачі нагороди.
func _process(delta: float) -> void:
	if is_active:
		idle_timer += delta
		if idle_timer >= idle_interval:
			idle_timer = 0.0
			idle_process()

# --- ПЕРЕВІРКА НАЯВНОСТІ В ІНВЕНТАРІ ---
# Викликається глобально (наприклад, з Dashboard при купівлі чи рівні). 
# Перевіряє, чи є предмет у гравця, і якщо так — активує його на сцені.
# Якщо предмет був забраний/видадений предмет зникає
func update_ui() -> void:
	if item_id == "": return
	
	var has_item = Global.inventory.get(item_id, false)
	
	if has_item:
		if not is_active:
			appear()
	else:
		if is_active:
			disappear()

# --- АНІМАЦІЯ ПОЯВИ ТА СТАРТ ---
# Робить предмет видимим, плавно збільшує його з нульового розміру 
# (ефект пружинки) і запускає відлік пасивного часу.
func appear() -> void:
	is_active = true
	visible = true
	idle_timer = 0.0 
	
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

# --- АНІМАЦІЯ ЗНИКНЕННЯ ---
# Викликається, коли гравець втрачає предмет (наприклад, після вайпу)
func disappear() -> void:
	is_active = false
	idle_timer = 0.0
	
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
		
	# Плавно зменшуємо до нуля і вимикаємо видимість
	transition_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	transition_tween.tween_callback(hide)

# --- ВИДАЧА ПАСИВНОЇ НАГОРОДИ ---
# Нараховує гравцю відповідний ресурс (досвід або монети), запускає 
# візуальний політ тексту і дає команду оновити лічильники на Дешборді.
func idle_process() -> void:
	if is_coin_reward:
		Global.meowcoin += reward_amount
	else:
		Global.gain_xp(reward_amount)
		
	show_feedback(reward_amount)
	get_tree().call_group("UI", "update_quick_stats")

# --- ВІЗУАЛІЗАЦІЯ ЗДОБИЧІ (СПЛИВАЮЧИЙ ТЕКСТ) ---
# Створює текстовий вузол поверх усіх шарів (Z-index 100), застосовує 
# потрібні кольори, генерує координати та запускає анімацію польоту і розчинення.
func show_feedback(amount: int) -> void:
	var float_node: Control
	
	if is_coin_reward:
		var coin_label = RichTextLabel.new()
		coin_label.bbcode_enabled = true
		coin_label.fit_content = true
		coin_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		coin_label.clip_contents = false
		
		var icon_path = "res://Assets/Graphics/Icons/Сurrency/Meowcoin-currency-ai.png"
		coin_label.text = "[center][color=gold]+" + str(amount) + "[/color][img=28]" + icon_path + "[/img][/center]"
		
		coin_label.add_theme_color_override("font_color", feedback_color) 
		coin_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		coin_label.add_theme_constant_override("outline_size", 6)
		coin_label.add_theme_font_size_override("normal_font_size", 28)
		float_node = coin_label
	else:
		var xp_label = Label.new()
		xp_label.text = "+" + str(amount) + " XP"
		
		xp_label.add_theme_color_override("font_color", feedback_color) 
		xp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		xp_label.add_theme_constant_override("outline_size", 6)
		xp_label.add_theme_font_size_override("font_size", 28)
		float_node = xp_label
		
	float_node.z_index = 100
	get_parent().add_child(float_node)
	
	var start_offset_x = randf_range(text_start_offset_x.x, text_start_offset_x.y)
	var start_offset_y = randf_range(text_start_offset_y.x, text_start_offset_y.y)
	float_node.global_position = self.global_position + Vector2(start_offset_x, start_offset_y)
	
	var target_x = float_node.global_position.x + randf_range(text_target_x_range.x, text_target_x_range.y)
	var target_y = float_node.global_position.y - randf_range(text_target_y_range.x, text_target_y_range.y)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(float_node, "global_position", Vector2(target_x, target_y), 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(float_node, "modulate:a", 0.0, 0.75).set_ease(Tween.EASE_IN).set_delay(0.15)
	
	tw.chain().tween_callback(float_node.queue_free)
