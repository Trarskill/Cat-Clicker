extends Node2D

@onready var anim = $AnimatedSprite2D
@onready var shadow = $Shadow

func _ready() -> void:
	play_idle()

# --- ДОПОМІЖНА ФУНКЦІЯ: ВИЗНАЧАЄ ПОТОЧНЕ ЕКІПІРУВАННЯ ---
func get_current_anim(action: String) -> String:
	# Спочатку перевіряємо, яка саме зброя в руках
	match Global.equipped_weapon:
		"magic_stick":
			return action + "_magic_stick" # Поверне: idle_magic_stick, attack_magic_stick
		"steel_sword":
			return action + "_steel_sword" # Поверне: idle_steel_sword, attack_steel_sword
		"wooden_sword":
			return action + "_wooden_sword"       # Поверне: idle_sword, attack_sword
			
	# Якщо зброї немає, але є щит
	if Global.equipped_shield != "":
		return action + "_shield"          # Поверне: idle_shield, attack_shield
		
	# Якщо котик без екіпірування
	return action + "_cat"                 # Поверне: idle_cat, attack_cat

# --- ФУНКЦІЯ ДЛЯ МИТТЄВОГО ОНОВЛЕННЯ З ІНВЕНТАРЮ ---
func update_equipment_visuals() -> void:
	# Цю функцію викликатиме Dashboard при одяганні предмета,
	# щоб миттєво перемкнути idle-анімацію.
	play_idle()

# --- СТАН СПОКОЮ (IDLE) ---
func play_idle() -> void:
	var anim_name = get_current_anim("idle")
	
	if anim.sprite_frames.has_animation(anim_name) and anim.sprite_frames.get_frame_count(anim_name) > 0:
		anim.play(anim_name)
		_play_shadow(anim_name, "idle")
	else:
		print("[Cat] Анімація '", anim_name, "' ще не додана!")

# --- СТАН АТАКИ (ATTACK) ---
func play_attack() -> void:
	var anim_name = get_current_anim("attack")
	
	if anim.sprite_frames.has_animation(anim_name) and anim.sprite_frames.get_frame_count(anim_name) > 0:
		anim.play(anim_name)
		_play_shadow(anim_name, "attack")
		
		await anim.animation_finished
		
		play_idle() 
	else:
		print("[Cat] Анімація '", anim_name, "' ще не додана!")
		await get_tree().create_timer(0.5).timeout
		play_idle()

# --- СТАН ОТРИМАННЯ УДАРУ (HURT) ---
func play_hurt() -> void:
	var anim_name = get_current_anim("hurt")
	
	if anim.sprite_frames.has_animation(anim_name) and anim.sprite_frames.get_frame_count(anim_name) > 0:
		anim.play(anim_name)
		_play_shadow(anim_name, "hurt")
		
		await anim.animation_finished
		play_idle()
	else:
		print("[Cat] Анімація '", anim_name, "' ще не додана!")
		await get_tree().create_timer(0.5).timeout
		play_idle()

# --- ДОПОМІЖНА ФУНКЦІЯ: БЕЗПЕЧНА ТІНЬ ---
func _play_shadow(target_anim: String, fallback_anim: String) -> void:
	if shadow.sprite_frames.has_animation(target_anim) and shadow.sprite_frames.get_frame_count(target_anim) > 0:
		shadow.play(target_anim)
	elif shadow.sprite_frames.has_animation(fallback_anim) and shadow.sprite_frames.get_frame_count(fallback_anim) > 0:
		shadow.play(fallback_anim)
