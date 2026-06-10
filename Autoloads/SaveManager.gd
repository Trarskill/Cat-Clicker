extends Node

const SAVE_FILE_PATH = "user://save_game.json"

func save_game() -> void:
	var save_data = {
		"meowcoin": Global.meowcoin,
		"rustycoin": Global.rustycoin,
		"meowgem": Global.meowgem,
		"click_power": Global.click_power,
		"level": Global.level,
		"xp": Global.xp,
		"max_xp": Global.max_xp,
		"max_level_announced": Global.max_level_announced,
		"is_endgame_half_reached": Global.is_endgame_half_reached,
		"equipped_weapon": Global.equipped_weapon,
		"equipped_shield": Global.equipped_shield,
		"potion_balance": Global.potion_balance,
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
			if data.has("level"): Global.level = int(data["level"])
			if data.has("xp"): Global.xp = int(data["xp"])
			if data.has("max_xp"): Global.max_xp = int(data["max_xp"])
			if data.has("max_level_announced"): Global.max_level_announced = data["max_level_announced"]
			if data.has("is_endgame_half_reached"): Global.is_endgame_half_reached = data["is_endgame_half_reached"]
			if data.has("equipped_weapon"): Global.equipped_weapon = data["equipped_weapon"]
			if data.has("equipped_shield"): Global.equipped_shield = data["equipped_shield"]
			if data.has("potion_balance"): Global.potion_balance = int(data["potion_balance"])
			
			if data.has("inventory"):
				for key in data["inventory"].keys():
					if Global.inventory.has(key):
						Global.inventory[key] = data["inventory"][key]
						
			print("[SaveManager] Дані успішно завантажено з файлу!")
		else:
			print("[SaveManager] Помилка: Не вдалося розпарсити JSON файл!")
	else:
		print("[SaveManager] Помилка: Не вдалося відкрити файл для читання!")
