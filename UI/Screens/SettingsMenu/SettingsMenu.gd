extends PanelContainer

@export var dimmer: ColorRect 

var is_open: bool = false
var tween: Tween

@onready var close_button = $MarginContainer/VBox/HBoxContainer/BtnClose
@onready var btn_lang_ua = $MarginContainer/VBox/GridContainer/ButtonUK
@onready var btn_lang_gb = $MarginContainer/VBox/GridContainer/ButtonEN
@onready var gift_button = $MarginContainer/VBox/Gift

@onready var music_slider = $MarginContainer/VBox/MusicContainer/MusicSlider
@onready var sfx_slider = $MarginContainer/VBox/SFXContainer/SFXSlider
@onready var music_mute_btn = $MarginContainer/VBox/MusicContainer/MusicButtonOFF
@onready var sfx_mute_btn = $MarginContainer/VBox/SFXContainer/SFXButtonOFF

# --- ЗМІННІ СТАНУ НАЛАШТУВАНЬ ---
var is_music_muted: bool = false
var is_sfx_muted: bool = false
var pre_mute_music_val: float = 0.5
var pre_mute_sfx_val: float = 0.7
var current_language: String = "uk"

# --- ІНІЦІАЛІЗАЦІЯ ---
# Викликається при створенні сцени. Налаштовує початковий 
# стан меню (приховує його), підключає всі сигнали кнопок та 
# повзунків, а також ініціює завантаження збережених налаштувань.
func _ready() -> void:
	pivot_offset = size / 2.0
	hide()
	modulate.a = 0.0
	is_open = false
	
	if dimmer:
		dimmer.hide()
		dimmer.modulate.a = 0.0

	close_button.pressed.connect(close)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_mute_btn.pressed.connect(_on_music_mute_toggled)
	sfx_mute_btn.pressed.connect(_on_sfx_mute_toggled)
	gift_button.pressed.connect(_on_gift_pressed)
	
	btn_lang_ua.pressed.connect(func(): _set_language("uk"))
	btn_lang_gb.pressed.connect(func(): _set_language("en"))
	
	_load_and_apply_settings()

# --- КЕРУВАННЯ ВІКНОМ ---
# Універсальний перемикач: відкриває меню, якщо воно наразі закрите, 
# і закриває його, якщо воно відкрите.
func toggle() -> void:
	if is_open:
		close()
	else:
		open()

# --- ВІДКРИТТЯ НАЛАШТУВАНЬ ---
# Робить меню видимим. Запускає паралельну Tween-анімацію 
# для плавного збільшення вікна та появи затемненого фону (dimmer).
func open() -> void:
	is_open = true
	show()
	if dimmer: dimmer.show()
	
	if tween and tween.is_valid(): tween.kill()
	tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if dimmer:
		tween.tween_property(dimmer, "modulate:a", 1.0, 0.25)

# --- ЗАКРИТТЯ НАЛАШТУВАНЬ ---
# Зберігає поточні налаштування у файл, після чого запускає 
# анімацію плавного зменшення та зникнення вікна і фону. 
# Повністю приховує вузли після завершення.
func close() -> void:
	is_open = false
	
	_save_current_settings()
	
	if tween and tween.is_valid(): tween.kill()
	tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	if dimmer:
		tween.tween_property(dimmer, "modulate:a", 0.0, 0.2)

	tween.chain().tween_callback(func():
		hide()
		if dimmer: dimmer.hide()
	)

# --- Slider МУЗИКИ ---
# Обробник ручної зміни повзунка музики. Встановлює нову гучність у децибелах. 
# Якщо музика була вимкнена (Mute), автоматично знімає це блокування при русі повзунка.
func _on_music_changed(value: float) -> void:
	if is_music_muted:
		is_music_muted = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
		music_mute_btn.text = "🔊"
		
	pre_mute_music_val = value 
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

# --- Slider SFX ---
# Обробник ручної зміни повзунка звукових ефектів (SFX). Оновлює рівень гучності 
# та автоматично вимикає режим Mute, якщо гравець почав тягнути повзунок.
func _on_sfx_changed(value: float) -> void:
	if is_sfx_muted:
		is_sfx_muted = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), false)
		sfx_mute_btn.text = "🔊"
		
	pre_mute_sfx_val = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

# --- ЛОГІКА ВИМКНЕННЯ МУЗИКИ (MUTE) ---
# Обробник кнопки вимкнення музики. Перемикає стан Mute для шини "Music", 
# змінює іконку кнопки (🔊/🔇) та візуально скидає повзунок у нуль (або відновлює його), 
# не викликаючи при цьому подію зміни гучності.
func _on_music_mute_toggled() -> void:
	is_music_muted = !is_music_muted
	var bus_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(bus_idx, is_music_muted)
	
	if is_music_muted:
		pre_mute_music_val = music_slider.value
		music_slider.set_value_no_signal(0.0)
		music_mute_btn.text = "🔇"
	else:
		# Повертаємо збережене значення
		music_slider.set_value_no_signal(pre_mute_music_val)
		music_mute_btn.text = "🔊"

# --- ЛОГІКА ВИМКНЕННЯ ЗВУКУ (MUTE) ---
# Обробник кнопки вимкнення звуків. Керує станом Mute для шини "SFX", 
# запам'ятовує попереднє значення повзунка та оновлює візуальний інтерфейс.
func _on_sfx_mute_toggled() -> void:
	is_sfx_muted = !is_sfx_muted
	var bus_idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_mute(bus_idx, is_sfx_muted)
	
	if is_sfx_muted:
		pre_mute_sfx_val = sfx_slider.value
		sfx_slider.set_value_no_signal(0.0)
		sfx_mute_btn.text = "🔇"
	else:
		sfx_slider.set_value_no_signal(pre_mute_sfx_val)
		sfx_mute_btn.text = "🔊"
	
	sfx_mute_btn.text = "🔇" if is_sfx_muted else "🔊"

# --- ЛОГІКА МОВИ ---
# Змінює активну мову локалізації гри.
func _set_language(lang_code: String) -> void:
	current_language = lang_code
	TranslationServer.set_locale(lang_code)
	
	btn_lang_ua.disabled = (lang_code == "uk")
	btn_lang_gb.disabled = (lang_code == "en")
	
	btn_lang_ua.modulate.a = 1.0
	btn_lang_gb.modulate.a = 1.0

# --- ЛОГІКА ПОДАРУНКА (ПРОМОКОДУ) ---
# Логіка активації промокоду. Видає гравцеві нагороду, відмічає статус подарунка як "отриманий", 
# блокує кнопку від повторних натискань та викликає глобальне спливаюче повідомлення.
func _on_gift_pressed() -> void:
	Global.is_gift_claimed = true
	
	Global.meowcoin += 1000
	Global.inventory["clockwork_mouse"] = true
	
	gift_button.disabled = true
	gift_button.text = "✅ ОТРИМАНО"
	
	Global.show_floating_text("ПОДАРУНОК: Завідна миша та 1000 Монет!", Color(0.95, 0.82, 0.54))
	
	get_tree().call_group("UI", "update_ui")
	get_tree().call_group("UI", "update_quick_stats")

# --- СИСТЕМА ЗБЕРЕЖЕННЯ НАЛАШТУВАНЬ ---
# Збирає всі поточні стани інтерфейсу (значення повзунків, статуси Mute, обрану мову 
# та статус подарунка) у словник і передає його до SaveManager для запису на диск.
func _save_current_settings() -> void:
	var settings_data = {
		"is_music_muted": is_music_muted,
		"is_sfx_muted": is_sfx_muted,
		"pre_mute_music_val": pre_mute_music_val,
		"pre_mute_sfx_val": pre_mute_sfx_val,
		"language": current_language,
		"is_gift_claimed": Global.is_gift_claimed 
	}
	SaveManager.save_settings(settings_data)

# --- СИСТЕМА ЗАВАНТАЖЕННЯ НАЛАШТУВАНЬ ---
# Отримує дані з SaveManager. Якщо файл існує, застосовує збережені налаштування 
# до всіх елементів UI: виставляє повзунки, перемикає мову, застосовує гучність до аудіо-шин 
# та блокує кнопку подарунка, якщо він вже був забраний раніше.
func _load_and_apply_settings() -> void:
	var saved = SaveManager.load_settings()
	if saved.is_empty():
		_set_language(current_language)
		return 
		
	is_music_muted = saved.get("is_music_muted", false)
	is_sfx_muted = saved.get("is_sfx_muted", false)
	pre_mute_music_val = saved.get("pre_mute_music_val", 0.5)
	pre_mute_sfx_val = saved.get("pre_mute_sfx_val", 0.7)
	
	# Застосовуємо звук
	music_mute_btn.text = "🔇" if is_music_muted else "🔊"
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), is_music_muted)
	if is_music_muted:
		music_slider.set_value_no_signal(0.0)
	else:
		music_slider.set_value_no_signal(pre_mute_music_val)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(pre_mute_music_val))
	
	sfx_mute_btn.text = "🔇" if is_sfx_muted else "🔊"
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), is_sfx_muted)
	if is_sfx_muted:
		sfx_slider.set_value_no_signal(0.0)
	else:
		sfx_slider.set_value_no_signal(pre_mute_sfx_val)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(pre_mute_sfx_val))
	
	# ЗАВАНТАЖУЄМО ТА ЗАСТОСОВУЄМО МОВУ
	var saved_lang = saved.get("language", "uk")
	_set_language(saved_lang)
	
	# ЗАВАНТАЖУЄМО СТАТУС ПОДАРУНКА
	Global.is_gift_claimed = saved.get("is_gift_claimed", false)
	
	if Global.is_gift_claimed:
		gift_button.disabled = true
		gift_button.text = "✅ ОТРИМАНО"
