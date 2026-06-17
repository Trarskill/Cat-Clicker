extends Node

const SAVE_FILE_PATH = "user://save_game.json"

# Змінні для автозбереження
var autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL: float = 30.0

# --- ІНІЦІАЛІЗАЦІЯ МЕНЕДЖЕРА ЗБЕРЕЖЕНЬ ---
# Вимикає миттєве закриття гри системою, дозволяючи нам 
# самостійно зберегти прогрес перед остаточним виходом.
func _ready():
	get_tree().set_auto_accept_quit(false)

# --- АВТОЗБЕРЕЖЕННЯ КОЖНІ 30 СЕКУНД ---
# Виконується кожен кадр. Відраховує час і автоматично 
# записує всі дані у файл кожні 30 секунд.
func _process(delta: float) -> void:
	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
		autosave_timer = 0.0
		save_game()
		print("[SaveManager] Спрацювало автозбереження (30 сек).")

# --- ОБРОБКА ЗАКРИТТЯ ГРИ ---
# Перехоплює запит на закриття вікна (або згортання на мобільних).
# Примусово зберігає гру та коректно завершує роботу програми.
func _notification(what: int) -> void:
	# Цей сигнал спрацьовує, коли гравець закриває вікно гри (на ПК) 
	# або "змахує" гру в диспетчері завдань (на Android/iOS)
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		print("[SaveManager] Отримано сигнал закриття. Зберігаємо дані перед виходом...")
		save_game()
		get_tree().quit()

# --- ЛОГІКА ЗБЕРЕЖЕННЯ ГРИ ---
# Функція збирає всі ключові змінні, статус екіпірування та 
# весь інвентар з глобального банку (Global) у єдиний словник, 
# конвертує його в JSON формат та записує у файл на диску.
func save_game() -> void:
	var save_data = {
		"meowcoin": Global.meowcoin,
		"rustycoin": Global.rustycoin,
		"meowgem": Global.meowgem,
		"click_power": Global.click_power,
		"click_lvl_power": Global.click_lvl_power,
		"potion_balance": Global.potion_balance,
		"level": Global.level,
		"xp": Global.xp,
		"max_xp": Global.max_xp,
		"max_level_announced": Global.max_level_announced,
		"is_endgame_half_reached": Global.is_endgame_half_reached,
		"equipped_weapon": Global.equipped_weapon,
		"equipped_shield": Global.equipped_shield,
		# --- УСІ ТАЙМЕРИ ---
		"bowl_bone_timer": Global.bowl_bone_timer,
		"bowl_rice_timer": Global.bowl_rice_timer,
		"bowl_fish_timer": Global.bowl_fish_timer,
		"bag_of_fruit_timer": Global.bag_of_fruit_timer,
		"catnip_timer": Global.catnip_timer,
		"clockwork_mouse_cooldown": Global.clockwork_mouse_cooldown,
		"clockwork_mouse_timer": Global.clockwork_mouse_timer,
		
		"inventory": Global.inventory
	}
	
	var json_string = JSON.stringify(save_data)
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
		print("[SaveManager] Гру успішно збережено у фізичний файл!")
	else:
		print("[SaveManager] Помилка: Не вдалося створити файл збереження!")


# --- ЛОГІКА ЗАВАНТАЖЕННЯ ГРИ ---
# Функція перевіряє наявність файлу збереження, зчитує його, 
# розпаковує JSON і обережно відновлює дані в Global.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveManager] Файл збереження не знайдено. Починаємо нову гру.")
		return
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		
		if error == OK:
			var data = json.get_data()
			
			if data.has("meowcoin"): Global.meowcoin = int(data["meowcoin"])
			if data.has("rustycoin"): Global.rustycoin = int(data["rustycoin"])
			if data.has("meowgem"): Global.meowgem = int(data["meowgem"])
			if data.has("click_power"): Global.click_power = int(data["click_power"])
			if data.has("potion_balance"): Global.potion_balance = int(data["potion_balance"])
			if data.has("click_lvl_power"): Global.click_lvl_power = int(data["click_lvl_power"])
			if data.has("level"): Global.level = int(data["level"])
			if data.has("xp"): Global.xp = int(data["xp"])
			if data.has("max_xp"): Global.max_xp = int(data["max_xp"])
			if data.has("max_level_announced"): Global.max_level_announced = data["max_level_announced"]
			if data.has("is_endgame_half_reached"): Global.is_endgame_half_reached = data["is_endgame_half_reached"]
			if data.has("equipped_weapon"): Global.equipped_weapon = data["equipped_weapon"]
			if data.has("equipped_shield"): Global.equipped_shield = data["equipped_shield"]
			# --- ЗАВАНТАЖЕННЯ ВСІХ ТАЙМЕРІВ ---
			if data.has("clockwork_mouse_cooldown"): Global.clockwork_mouse_cooldown = float(data["clockwork_mouse_cooldown"])
			if data.has("clockwork_mouse_timer"): Global.clockwork_mouse_timer = float(data["clockwork_mouse_timer"])
			if data.has("bowl_bone_timer"): Global.bowl_bone_timer = float(data["bowl_bone_timer"])
			if data.has("bowl_rice_timer"): Global.bowl_rice_timer = float(data["bowl_rice_timer"])
			if data.has("bowl_fish_timer"): Global.bowl_fish_timer = float(data["bowl_fish_timer"])
			if data.has("bag_of_fruit_timer"): Global.bag_of_fruit_timer = float(data["bag_of_fruit_timer"])
			if data.has("catnip_timer"): Global.catnip_timer = float(data["catnip_timer"])
			if data.has("clockwork_mouse_cooldown"): Global.clockwork_mouse_cooldown = float(data["clockwork_mouse_cooldown"])
			if data.has("clockwork_mouse_timer"): Global.clockwork_mouse_timer = float(data["clockwork_mouse_timer"])
			if data.has("inventory"):
				for key in data["inventory"].keys():
					if Global.inventory.has(key):
						Global.inventory[key] = data["inventory"][key]
						
			print("[SaveManager] Дані успішно завантажено з файлу!")
		else:
			print("[SaveManager] Помилка: Не вдалося розпарсити JSON файл!")
	else:
		print("[SaveManager] Помилка: Не вдалося відкрити файл для читання!")
