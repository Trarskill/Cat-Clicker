extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

var is_active: bool = false
var transition_tween: Tween

# --- НОВІ ЗМІННІ ДЛЯ АВТОКЛІКУ ---
var click_timer: float = 0.0
const CLICK_INTERVAL: float = 0.5

func _ready() -> void:
	scale = Vector2.ZERO
	visible = false
	is_active = false

func _process(delta: float) -> void:
	if Global.clockwork_mouse_timer > 0.0:
		if not is_active:
			appear()
			
		if is_active:
			click_timer += delta
			if click_timer >= CLICK_INTERVAL:
				click_timer = 0.0
				process_click()
				
	else:
		if is_active:
			disappear()

# --- АНІМАЦІЯ ПОЯВИ ---
func appear() -> void:
	is_active = true
	visible = true
	animated_sprite.play("work") 
	click_timer = 0.0
	
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

# --- АНІМАЦІЯ ЗНИКНЕННЯ ---
func disappear() -> void:
	is_active = false
	
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	
	transition_tween.tween_callback(animated_sprite.stop)
	transition_tween.tween_callback(hide)

# --- ОБРОБКА КЛІКУ МИШКИ ---
func process_click() -> void:
	var mouse_power = Global.click_power
	
	Global.gain_xp(mouse_power)
	
	if Global.bag_of_fruit_timer > 0:
		var fruit_data = DataManager.get_item("bag_of_fruit")
		var earned_coins = fruit_data["stats"].get("coin_gets", 1)
		Global.meowcoin += earned_coins
	
	show_xp_feedback(mouse_power)

# --- ВІЗУАЛІЗАЦІЯ ДОСВІДУ (Спливаючий текст) ---
func show_xp_feedback(amount: int) -> void:
	var xp_label = Label.new()
	xp_label.text = "+" + str(amount) + " XP"
	
	# Налаштовуємо стиль тексту (наприклад, помаранчевий колір для мишки, щоб відрізнявся від кота)
	xp_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2)) 
	xp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	xp_label.add_theme_constant_override("outline_size", 6)
	xp_label.add_theme_font_size_override("font_size", 24)
	
	get_parent().add_child(xp_label)
	
	var start_offset_x = randf_range(-20.0, 20.0)
	var start_offset_y = randf_range(-40.0, -20.0)
	xp_label.global_position = self.global_position + Vector2(start_offset_x, start_offset_y)
	
	var target_x = xp_label.global_position.x + randf_range(-30.0, 30.0)
	var target_y = xp_label.global_position.y - randf_range(60.0, 90.0)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(xp_label, "global_position", Vector2(target_x, target_y), 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(xp_label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(0.1)
	
	tw.chain().tween_callback(xp_label.queue_free)
