extends Node

var meowcoin: int = 10
var rustycoin: int = 0
var meowgem: int = 0

var click_power: int = 10
var click_lvl_power: int = 0
var potion_balance: int = 0

var level: int = 1
var xp: int = 0
var max_xp: int = 50
var max_level_announced: bool = false
var is_endgame_half_reached: bool = false 

var equipped_weapon: String = ""
var equipped_shield: String = ""

var inventory: Dictionary = {
	"power_of_paws": true,
	"cat_magic": 0,
	"soft_pet_bed": false,
	"meditative_aquarium": false,
	"book_of_cat_tales": false,
	"boss_map": false,
	"mysterious_chest": false,
	"wooden_sword": false,
	"wooden_shield": false,
	"steel_sword": false,
	"magic_stick": false,
	"magic_fishing_rod": false,
	"bowl_with_bone": 0,
	"bowl_with_rice": 0,
	"bowl_with_fish": 0,
	"apple": 0,
	"bag_of_fruit": 0,
	"catnip": 0,
	"magical_rose": 0,
	"xp_potion": 0,
	"strength_potion": 0,
	"curse_potion": 0,
	"clockwork_mouse": false
}

# Максимальна кількість однакових предметів у слоті (для стакуваних)
const MAX_STACK: int = 16

# --- ТАЙМЕРИ АКТИВНИХ ЕФЕКТІВ ---
# Зберігають час до закінчення дії тимчасових предметів
var bowl_bone_timer: float = 0.0
var bowl_rice_timer: float = 0.0
var bowl_fish_timer: float = 0.0
var bag_of_fruit_timer: float = 0.0
var catnip_timer: float = 0.0
var clockwork_mouse_timer: float = 0.0
var clockwork_mouse_cooldown: float = 0.0

# --- ЗМІННІ ДЛЯ ЧЕРГИ ТЕКСТІВ ---
var floating_text_queue: Array = []
var is_showing_floating_text: bool = false

# --- СИГНАЛИ (ПОДІЇ) ---
signal item_timer_expired
signal leveled_up(new_level)

# --- ГОЛОВНИЙ ЦИКЛ ГРИ (ОНОВЛЕННЯ) ---
# Функція автоматично викликається Godot 
# кожен кадр і відповідає за відлік таймерів активних предметів
func _process(delta: float) -> void:
	var timer_expired = false
	
	# --- ТАЙМЕРИ МИСОК ---
	if bowl_bone_timer > 0:
		bowl_bone_timer -= delta
		if bowl_bone_timer <= 0:
			bowl_bone_timer = 0
			timer_expired = true
			
	if bowl_rice_timer > 0:
		bowl_rice_timer -= delta
		if bowl_rice_timer <= 0:
			bowl_rice_timer = 0
			timer_expired = true
			
	if bowl_fish_timer > 0:
		bowl_fish_timer -= delta
		if bowl_fish_timer <= 0:
			bowl_fish_timer = 0
			timer_expired = true
			
	# --- ТАЙМЕРИ ІНШИХ БАФІВ ---
	if bag_of_fruit_timer > 0:
		bag_of_fruit_timer -= delta
		if bag_of_fruit_timer <= 0:
			bag_of_fruit_timer = 0
			timer_expired = true
			
	if catnip_timer > 0:
		catnip_timer -= delta
		if catnip_timer <= 0:
			catnip_timer = 0
			timer_expired = true
	
	# --- ЛОГІКА ЗАВІДНОЇ МИШКИ (БРОНЬОВАНА ВЕРСІЯ) ---
	# 1. Таймер роботи просто віднімається
	if clockwork_mouse_timer > 0.0:
		clockwork_mouse_timer -= delta
		if clockwork_mouse_timer <= 0.0:
			clockwork_mouse_timer = 0.0
			item_timer_expired.emit()
			
	# 2. Таймер кулдауну віднімається паралельно!
	if clockwork_mouse_cooldown > 0.0:
		clockwork_mouse_cooldown -= delta
		if clockwork_mouse_cooldown <= 0.0:
			clockwork_mouse_cooldown = 0.0
			item_timer_expired.emit()
			show_floating_text("Мишка знову готова!", Color(0.8, 0.8, 0.8))
			print("[Mouse] Мишка знову готова!")
	
	# Відправляємо сигнал ОДИН раз за кадр, якщо хоч один таймер закінчився
	if timer_expired:
		item_timer_expired.emit()

# --- ЛОГІКА ГОЛОВНОГО КЛІКУ (ОБЧИСЛЕННЯ) ---
# Функція виконує математичний розрахунок кліку 
# з урахуванням усіх активних бафів, зброї та зілль. 
func process_click() -> Dictionary:
	var total_xp = click_power + click_lvl_power
	var earned_coins = 0
	
	# 1. ДОДАВАННЯ ДОСВІДУ ВІД МИСОК (можуть працювати всі одночасно)
	if bowl_bone_timer > 0:
		total_xp += DataManager.get_item("bowl_with_bone")["stats"]["xp_bonus"]
	if bowl_rice_timer > 0:
		total_xp += DataManager.get_item("bowl_with_rice")["stats"]["xp_bonus"]
	if bowl_fish_timer > 0:
		total_xp += DataManager.get_item("bowl_with_fish")["stats"]["xp_bonus"]
	
	# 2. БОНУСИ ВІД ЕКІПІРУВАННЯ
	if equipped_weapon != "":
		var w_data = DataManager.get_item(equipped_weapon)
		if equipped_weapon == "magic_stick":
			if inventory.get("cat_magic", 0) >= 1:
				total_xp += w_data["stats"].get("xp_bonus", 0)
		elif equipped_weapon == "magic_fishing_rod":
			earned_coins += w_data["stats"].get("coin_bonus", 1)
		else:
			total_xp += w_data["stats"].get("xp_bonus", 0)
	
	if equipped_shield != "":
		var s_data = DataManager.get_item(equipped_shield)
		total_xp += s_data["stats"].get("xp_bonus", 0)
	
	# 3. МНОЖНИК ВІД РІВНЯ КОТО-МАГІЇ
	var magic_lvl = inventory.get("cat_magic", 0)
	if magic_lvl > 0:
		var magic_data = DataManager.get_item("cat_magic")
		var multiplier = 1.0 + (magic_lvl * magic_data["stats"]["multiplier_per_level"])
		total_xp = int(total_xp * multiplier)
	
	# 4. МНОЖНИК ВІД КОТЯЧОЇ М'ЯТИ (застосовується в самому кінці до всього зібраного XP)
	if catnip_timer > 0:
		var catnip_data = DataManager.get_item("catnip")
		var catnip_mult = catnip_data["stats"].get("xp_multiplier", 2.0)
		total_xp = int(total_xp * catnip_mult)
	
	gain_xp(total_xp)
	
	# 5. ДОДАВАННЯ МОНЕТ ВІД МІШЕЧКА
	if bag_of_fruit_timer > 0:
		var fruit_data = DataManager.get_item("bag_of_fruit")
		earned_coins += fruit_data["stats"].get("coin_gets", 1)
		
	# Якщо є зароблені монети за клік (від вудки або мішечка), додаємо їх
	if earned_coins > 0:
		meowcoin += earned_coins
		
	# Повертаємо результати для інтерфейсу
	return {"xp": total_xp, "coins": earned_coins}

# --- ЛОГІКА НАРАХУВАННЯ ДОСВІДУ ---
# Функція додає досвід гравцю та перевіряє умови 
# для підвищення рівня або ендгейм-бонусів
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

# --- ОБРОБКА ДОСВІДУ НА МАКСИМАЛЬНОМУ РІВНІ ---
# Функція циклічно нараховує бонусні монети та геми, 
# коли гравець заповнює шкалу після 100-го рівня
func process_endgame_xp() -> void:
	var half_xp = max_xp / 2
	
	# ЕТАП 1: Половина бару
	if xp >= half_xp and not is_endgame_half_reached:
		is_endgame_half_reached = true
		meowcoin += 250
		show_floating_text("БОНУС: +250 Монет!", Color(1.0, 0.8, 0.2))
	
	# ЕТАП 2: Повний бар
	while xp >= max_xp:
		xp -= max_xp
		is_endgame_half_reached = false
		meowgem += 1
		show_floating_text("МАКС. БОНУС: +1 Гем!", Color(0.9, 0.4, 1.0))
		
		if xp >= half_xp:
			is_endgame_half_reached = true
			meowcoin += 250
			show_floating_text("БОНУС: +250 Монет!", Color(1.0, 0.8, 0.2))

# --- ЛОГІКА ПІДВИЩЕННЯ РІВНЯ ---
# Функція збільшує рівень, розраховує новий поріг досвіду 
# та видає нагороди залежно від досягнутого етапу
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
			click_lvl_power += 1
		
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

# --- ЛОГІКА ПОКУПКИ ПРЕДМЕТІВ ---
# Функція перевіряє ліміти та валюту, віднімає вартість 
# і додає предмет в інвентар. Повертає true, якщо покупка успішна
func buy_item(item_id: String, price: int, is_premium: bool = false) -> bool:
	if not inventory.has(item_id):
		print("[Global] Помилка: Предмет '", item_id, "' не знайдено в інвентарі!")
		return false
	
	var current_item = inventory[item_id]
	if typeof(current_item) == TYPE_BOOL:
		if current_item == true:
			return false
	else:
		if current_item >= MAX_STACK:
			return false
	
	if is_premium:
		if meowgem < price:
			return false
		meowgem -= price
	else:
		if meowcoin < price:
			return false
		meowcoin -= price
	
	if typeof(current_item) == TYPE_BOOL:
		inventory[item_id] = true
	else:
		inventory[item_id] += 1
		
	print("[Global] Успішно придбано: ", item_id, ". Залишок монет: ", meowcoin, " Гемів: ", meowgem)
	return true

# --- ЛОГІКА ВИКОРИСТАННЯ ПРЕДМЕТІВ ---
# Функція обробляє ефекти від зброї, спеціальних предметів та розхідників. 
# Повертає рядок із результатом дії
func use_item(item_id: String) -> String:
	var item_data = DataManager.get_item(item_id)
	if item_data.is_empty(): 
		return "Помилка бази даних"
		
	var stats = item_data.get("stats", {})
	var item_type = item_data.get("type")
	
	# --- 1. ЕКІПІРУВАННЯ (EQUIPMENT) ---
	if item_type == DataManager.ItemType.EQUIPMENT:
		if item_id == "magic_stick" and equipped_weapon != "magic_stick":
			var magic_lvl = inventory.get("cat_magic", 0)
			if magic_lvl == 0:
				return "Потрібно володіти кото-магією!"
		
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
	
	# --- 2. КЛЮЧОВІ ПРЕДМЕТИ (KEY_ITEM) ---
	elif item_type == DataManager.ItemType.KEY_ITEM:
		if item_id == "magical_rose":
			if inventory.get("xp_potion", 0) >= 1:
				var current_magic = inventory.get("cat_magic", 0)
				var magic_data = DataManager.get_item("cat_magic")
				var max_magic = magic_data.get("max_lvl", 10) if not magic_data.is_empty() else 10
				
				if current_magic >= max_magic:
					return "Кото-магія досягла максимуму!"
					
				inventory["xp_potion"] -= 1
				inventory["magical_rose"] -= 1
				inventory["cat_magic"] = current_magic + 1
				return "Магію пробуджено! Рівень: " + str(inventory["cat_magic"])
			else:
				return "Потрібне 1 магічне зілля!"
				
		elif item_id == "boss_map":
			return "Карту вивчено!\n(Боси у наступних оновленнях)"

	# --- 3. МИТТЄВІ РОЗХІДНИКИ (CONSUMABLE) ---
	elif item_type == DataManager.ItemType.CONSUMABLE:
		# Перевірка лімітів для зілль ДО того, як ми заберемо предмет з інвентаря
		if item_id == "strength_potion":
			if potion_balance >= 20:
				return "Досягнуто ліміту Зілля Сили (20)!"
		elif item_id == "curse_potion":
			if potion_balance <= 0:
				return "Організм не витримає прокляття! (Баланс 0)"
		
		# Віднімаємо предмет
		if typeof(inventory[item_id]) == TYPE_BOOL:
			inventory[item_id] = false
		else:
			inventory[item_id] -= 1
			
		# Логіка ефектів
		if item_id == "apple":
			var chance = stats.get("chance")
			if randf() <= chance:
				var xp_reward = stats.get("give_xp")
				gain_xp(xp_reward)
				return "Смачно! Отримано " + str(xp_reward) + " XP"
			else:
				return "Яблуко виявилося кислим... \nНічого не отримано."
				
		elif item_id == "xp_potion":
			var magic_lvl = inventory.get("cat_magic", 0)
			var bonus_xp = 100 + (100 * magic_lvl) 
			gain_xp(bonus_xp)
			return "Випито! Отримано " + str(bonus_xp) + " XP"
			
		elif item_id == "strength_potion":
			potion_balance += 1
			click_power += stats.get("permanent_power", 1)
			return "Сила назавжди зросла! \n +1 Міць Лапок"
			
		elif item_id == "curse_potion":
			potion_balance -= 1
			click_power += stats.get("permanent_power", -1)
			var gems = stats.get("gem_reward", 2)
			meowgem += gems
			return "Сили стало менше, але отримано " + str(gems) + " гемів! \n -1 Міць Лапок"
			
		elif item_id == "mysterious_chest":
			var random_coins = randi_range(200, 1000)
			meowcoin += random_coins
			return "Зі скрині випало " + str(random_coins) + " монет!"

	# --- 4. ТИМЧАСОВІ БАФИ (BUFF) ---
	elif item_type == DataManager.ItemType.BUFF:
		
		if typeof(inventory[item_id]) == TYPE_BOOL:
			inventory[item_id] = false
		else:
			inventory[item_id] -= 1
		
		if item_id == "bowl_with_bone":
			bowl_bone_timer = min(bowl_bone_timer + stats.get("duration"), 600.0)
			return "Бонус +1 XP активовано! \nЗалишилось: " + str(int(bowl_bone_timer)) + " сек"
			
		elif item_id == "bowl_with_rice":
			bowl_rice_timer = min(bowl_rice_timer + stats.get("duration"), 600.0)
			return "Рисовий бонус активовано! \nЗалишилось: " + str(int(bowl_rice_timer)) + " сек"
			
		elif item_id == "bowl_with_fish":
			bowl_fish_timer = min(bowl_fish_timer + stats.get("duration"), 600.0)
			return "Рибний бонус активовано! \nЗалишилось: " + str(int(bowl_fish_timer)) + " сек"
			
		elif item_id == "bag_of_fruit":
			bag_of_fruit_timer = min(bag_of_fruit_timer + stats.get("duration"), 600.0)
			return "Фруктовий бонус активовано! \nЗалишилось: " + str(int(bag_of_fruit_timer)) + " сек"
			
		elif item_id == "catnip":
			catnip_timer = min(catnip_timer + stats.get("duration"), 300.0)
			return "Котяча м'ята діє! \nx2 XP залишилось: " + str(int(catnip_timer)) + " сек"
	
	# --- 5. ПАСИВНІ ПРЕДМЕТИ (PASSIVE) ---
	elif item_data["type"] == DataManager.ItemType.PASSIVE:
		if item_id == "clockwork_mouse":
			if clockwork_mouse_timer > 0.0:
				return "Мишка вже працює!"
			if clockwork_mouse_cooldown > 0.0:
				return "Мишка ще заводиться... Зачекайте!"
			
			var duration = float(stats.get("auto_click_duration", 30.0))
			var cooldown = float(stats.get("cooldown"))
			
			clockwork_mouse_timer = duration
			clockwork_mouse_cooldown = duration + cooldown
			
			return "Мишка почала несамовито працювати!"
		else:
			return "Ця декорація працює автоматично."
	
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
	
	float_label.global_position = screen_center - (float_label.size / 2.0)
	float_label.global_position.y -= 150.0 
	
	float_label.pivot_offset = float_label.size / 2.0
	float_label.scale = Vector2(0.2, 0.2)
	
	var tween = float_label.create_tween().set_parallel(true)
	
	tween.tween_property(float_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "global_position:y", float_label.global_position.y - 250.0, 2.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_delay(1.5)
	
	tween.chain().tween_callback(top_canvas.queue_free)
