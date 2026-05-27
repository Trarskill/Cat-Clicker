extends Node

var meowcoin: int = 10
var rustycoin: int = 0
var meowgem: int = 0

var click_power: int = 10

var level: int = 1
var xp: int = 0
var max_xp: int = 50
var max_level_announced: bool = false
var is_endgame_half_reached: bool = false 

var equipped_weapon: String = ""
var equipped_shield: String = ""

var inventory: Dictionary = {
	"mysterious_chest": false,
	"wooden_sword": false,
	"wooden_shield": false,
	"steel_sword": false,
	"magic_stick": false,
	"bowl": 0,
	"apple": 0,
	"bag_of_fruit": 0,
	"magical_rose": 0,
	"potion": 0,
	"cat_magic": 0
}

const MAX_STACK: int = 16

var bowl_timer: float = 0.0
var bag_of_fruit_timer: float = 0.0
var click_counter: int = 0

# --- ЗМІННІ ДЛЯ ЧЕРГИ ТЕКСТІВ ---
var floating_text_queue: Array = []
var is_showing_floating_text: bool = false

signal item_timer_expired
signal leveled_up(new_level)

# Ця функція автоматично викликається Godot кожен кадр
func _process(delta: float) -> void:
	if bowl_timer > 0:
		bowl_timer -= delta
		if bowl_timer <= 0:
			item_timer_expired.emit()
			
	if bag_of_fruit_timer > 0:
		bag_of_fruit_timer -= delta
		if bag_of_fruit_timer <= 0:
			item_timer_expired.emit()

# --- ЛОГІКА РІВНІВ ---

# --- НАРАХУВАННЯ ДОСВІДУ ---
func gain_xp(amount: int) -> void:
	xp += amount
	
	if level >= 100:
		process_endgame_xp()
		return
	
	while xp >= max_xp and level < 100:
		level_up()
		
		if level >= 100:
			max_xp = int(50.0 * pow(100.0, 1.5)) 
			if xp > 0:
				process_endgame_xp()
			break

# --- ОКРЕМА ФУНКЦІЯ ДЛЯ МАКСИМАЛЬНОГО РІВНЯ ---
func process_endgame_xp() -> void:
	var half_xp = max_xp / 2
	
	# ЕТАП 1: Половина бару
	if xp >= half_xp and not is_endgame_half_reached:
		is_endgame_half_reached = true
		meowcoin += 250
		show_floating_text("БОНУС: +250 Монет!", Color(1.0, 0.8, 0.2))
		SaveManager.save_game()
	
	# ЕТАП 2: Повний бар
	while xp >= max_xp:
		xp -= max_xp
		is_endgame_half_reached = false
		meowgem += 1
		show_floating_text("МАКС. БОНУС: +1 Гем!", Color(0.9, 0.4, 1.0))
		SaveManager.save_game()
		
		if xp >= half_xp:
			is_endgame_half_reached = true
			meowcoin += 250
			show_floating_text("БОНУС: +250 Монет!", Color(1.0, 0.8, 0.2))

# --- СИСТЕМА НАГОРОД ЗА РІВНІ ---
func level_up() -> void:
	level += 1
	xp -= max_xp
	
	if level < 100:
		max_xp = int(50.0 * pow(float(level), 1.5))
	
	# 1. НАГОРОДА ЗА МОНЕТИ
	if level == 50:
		if inventory.has("wooden_sword") and inventory["wooden_sword"] == false:
			inventory["wooden_sword"] = true
		else:
			var sword_price = DataManager.get_item("wooden_sword").get("price", 1000)
			meowcoin += sword_price
			
	# --- СТАНДАРТНІ НАГОРОДИ ---
	else:
		# 1. КОЖЕН 10+1 РІВЕНЬ дає +1 до сили кліку
		if (level - 1) % 10 == 0 and level <= 91:
			click_power += 1
		
		# 2. ПЕРЕВІРКА НА 5-й РІВЕНЬ ТА ЗВИЧАЙНІ РІВНІ
		if level % 5 == 0:
			# Кожен 5-й рівень завжди дає Гем та суворо 50 монет (навіть після 30 рівня)
			meowgem += 1
			meowcoin += 50
		else:
			# Звичайні рівні, які не діляться на 5
			if level <= 30:
				meowcoin += 50
			else:
				meowcoin += 150
	
	# --- ВІЗУАЛЬНИЙ ВІДГУК НОВОГО РІВНЯ ---
	if level >= 100:
		if not max_level_announced:
			max_level_announced = true
			show_floating_text("ДОСЯГНУТО МАКС. РІВНЯ!", Color(1.0, 0.85, 0.2))
	else:
		if level % 10 == 0:
			show_floating_text("Супер рівень: " + str(level) + "!", Color(0.4, 0.6, 0.9))
		elif level % 5 == 0:
			show_floating_text("Незвичайний рівень: " + str(level) + "!", Color(0.9, 0.4, 1.0))
		elif level > 1 and (level - 1) % 10 == 0 and level <= 91:
			show_floating_text("Рівень сили: " + str(level) + "!", Color(0.8, 0.3, 0.2))
		else:
			show_floating_text("Новий уровень: " + str(level) + "!", Color(0.2, 0.9, 1.0))
	
	leveled_up.emit(level)
	
	SaveManager.save_game()

# Функція покупки. Повертає true, якщо покупка успішна, і false, якщо ні.
func buy_item(item_id: String, price: int, is_premium: bool = false) -> bool:
	if not inventory.has(item_id):
		print("[Global] Помилка: Предмет '", item_id, "' не знайдено в інвентарі!")
		return false
		
	# 1. Перевіряємо ліміти (чи не куплено унікальний предмет і чи не перевищено 16)
	var current_item = inventory[item_id]
	if typeof(current_item) == TYPE_BOOL:
		if current_item == true:
			print("[Global] Предмет вже куплено!")
			return false
	else:
		if current_item >= MAX_STACK:
			print("[Global] Досягнуто максимуму (16) для цього предмета!")
			return false
			
	# 2. Перевіряємо чи вистачає валюти
	if is_premium:
		if meowgem < price:
			print("[Global] Недостатньо Meowgem!")
			return false
		meowgem -= price
	else:
		if meowcoin < price:
			print("[Global] Недостатньо Meowcoin!")
			return false
		meowcoin -= price
		
	# 3. Видаємо товар гравцю
	if typeof(current_item) == TYPE_BOOL:
		inventory[item_id] = true
	else:
		inventory[item_id] += 1
		
	print("[Global] Успішно придбано: ", item_id, ". Залишок монет: ", meowcoin, " Гемів: ", meowgem)
	return true

# --- ЛОГІКА ВИКОРИСТАННЯ ПРЕДМЕТІВ ---

func use_item(item_id: String) -> String:
	var item_data = DataManager.get_item(item_id)
	if item_data.is_empty(): 
		return "Помилка бази даних"
		
	var stats = item_data.get("stats", {})
	
	# 1. ЕКІПІРУВАННЯ (Зброя та Щити)
	if item_data["type"] == DataManager.ItemType.EQUIPMENT:
		# Перевіряємо, чи намагаємося САМЕ ОДЯГНУТИ палицю при низькому рівні магії
		if item_id == "magic_stick" and equipped_weapon != "magic_stick":
			var magic_lvl = inventory.get("cat_magic", 0)
			if magic_lvl == 0:
				return "Потрібено володіти кото-магією!"
		
		# Логіка одягання/зняття щитів та зброї
		if item_id == "wooden_shield":
			if equipped_shield == item_id:
				equipped_shield = ""
				return "Щит знято"
			else:
				equipped_shield = item_id
				return "Щит одягнено"
		else:
			if equipped_weapon == item_id:
				equipped_weapon = ""
				return "Зброю знято"
			else:
				equipped_weapon = item_id
				return "Зброю одягнено"
	
	# 2. СПЕЦІАЛЬНІ ПРЕДМЕТИ (Магічна Роза)
	if item_data["type"] == DataManager.ItemType.SPECIAL:
		if item_id == "magical_rose":
			if inventory.get("potion", 0) >= 1:
				var current_magic = inventory.get("cat_magic", 0)
				
				# ВИПРАВЛЕННЯ: Беремо max_lvl саме з даних "cat_magic", а не з рози
				var magic_data = DataManager.get_item("cat_magic")
				var max_magic = magic_data.get("max_lvl", 10) if not magic_data.is_empty() else 10
				
				if current_magic >= max_magic:
					return "Кото-магія досягла максимуму!"
					
				inventory["potion"] -= 1
				inventory["magical_rose"] -= 1
				inventory["cat_magic"] = current_magic + 1
				return "Магію пробуджено! Рівень: " + str(inventory["cat_magic"])
			else:
				return "Потрібне 1 магічне зілля!"
	
	# 3. РОЗХІДНИКИ
	if item_data["type"] == DataManager.ItemType.CONSUMABLE:
		# Видаляємо предмет з інвентарю
		if typeof(inventory[item_id]) == TYPE_BOOL:
			inventory[item_id] = false
		else:
			inventory[item_id] -= 1
			
		# Яблуко: шанс 0.5 на отримання 45 XP
		if item_id == "apple":
			var chance = stats.get("chance", 0.5)
			if randf() <= chance:
				var xp_reward = stats.get("give_xp", 45)
				gain_xp(xp_reward)
				return "Смачно! Отримано " + str(xp_reward) + " XP"
			else:
				return "Яблуко виявилося кислим... Нічого не отримано."
				
		# Зілля: Дає 100 XP + скейл від рівня магії
		elif item_id == "potion":
			var magic_lvl = inventory.get("cat_magic", 0)
			var bonus_xp = 100 + (100 * magic_lvl) 
			gain_xp(bonus_xp)
			return "Випито! Отримано " + str(bonus_xp) + " XP"
			
		# Кісточка: Активація таймера
		elif item_id == "bowl":
			bowl_timer = stats.get("duration", 60)
			return "Бонус +1 XP до кліку активовано на 60 сек!"
			
		# Мішок фруктів: Активація таймера
		elif item_id == "bag_of_fruit":
			bag_of_fruit_timer = stats.get("duration", 60)
			# Якщо у тебе використовується click_counter для підрахунку кожного 5-го кліку:
			if "click_counter" in self:
				self.click_counter = 0
			return "Фруктовий бонус активовано на 60 сек!"
			
		# Таємнича скриня: Випадкова нагорода
		elif item_id == "mysterious_chest":
			var random_coins = randi_range(200, 1000)
			meowcoin += random_coins
			return "Зі скрині випало " + str(random_coins) + " монет!"
	
	return "Немає ефекту"


# --- УНІВЕРСАЛЬНИЙ ВІЗУАЛЬНИЙ ТЕКСТ (СПЛИВАЮЧЕ ПОВІДОМЛЕННЯ) ---
# --- 1. ДОДАВАННЯ В ЧЕРГУ ---
func show_floating_text(msg: String, text_color: Color) -> void:
	floating_text_queue.append({"msg": msg, "color": text_color})
	_process_text_queue()

# --- 2. ОБРОБКА ЧЕРГИ ---
func _process_text_queue() -> void:
	if is_showing_floating_text or floating_text_queue.is_empty():
		return
		
	is_showing_floating_text = true
	var data = floating_text_queue.pop_front()
	_spawn_floating_text(data["msg"], data["color"])
	
	# ЗАТРИМКА 0.4 секунди
	await get_tree().create_timer(0.4).timeout
	is_showing_floating_text = false
	_process_text_queue()

# --- 3. ФІЗИЧНЕ СТВОРЕННЯ ТА АНІМАЦІЯ ТЕКСТУ ---
func _spawn_floating_text(msg: String, text_color: Color) -> void:
	var float_label = Label.new()
	float_label.text = msg
	
	float_label.add_theme_color_override("font_color", text_color)
	float_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	float_label.add_theme_constant_override("outline_size", 10)
	float_label.add_theme_font_size_override("font_size", 32)
	
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var top_canvas = CanvasLayer.new()
	top_canvas.layer = 128
	
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	tree.current_scene.add_child(top_canvas)
	top_canvas.add_child(float_label)
	
	var screen_center = float_label.get_viewport_rect().size / 2.0
	float_label.reset_size()
	
	# Початкове базове центрування та підняття на 150 пікселів
	float_label.global_position = screen_center - (float_label.size / 2.0)
	float_label.global_position.y -= 150.0 
	
	float_label.pivot_offset = float_label.size / 2.0
	float_label.scale = Vector2(0.2, 0.2)
	
	var tween = float_label.create_tween().set_parallel(true)
	
	tween.tween_property(float_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "global_position:y", float_label.global_position.y - 250.0, 2.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_delay(1.5)
	
	tween.chain().tween_callback(top_canvas.queue_free)
