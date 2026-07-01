class_name ChestLootManager
extends Node

# --- ГОЛОВНИЙ ПУЛ ЛУТУ ---
# База даних усіх можливих нагород зі скрині. Містить ID предмета,
# можливий діапазон кількості, "вагу" (чим вона більша, тим частіше 
# падає предмет) та параметр унікальності (true/false).
const CHEST_POOL = [
	{"id": "meowcoin", "min": 50, "max": 1500, "weight": 95, "unique": false},
	{"id": "meowgem", "min": 1, "max": 6, "weight": 40, "unique": false},
	{"id": "bowl_with_bone", "min": 1, "max": 2, "weight": 50, "unique": false},
	{"id": "bowl_with_rice", "min": 1, "max": 2, "weight": 40, "unique": false},
	{"id": "bowl_with_fish", "min": 1, "max": 2, "weight": 30, "unique": false},
	{"id": "apple", "min": 1, "max": 2, "weight": 50, "unique": false},
	{"id": "bag_of_fruit", "min": 1, "max": 1, "weight": 35, "unique": false},
	{"id": "catnip", "min": 1, "max": 1, "weight": 20, "unique": false},
	{"id": "magical_rose", "min": 1, "max": 1, "weight": 20, "unique": false},
	{"id": "magical_potion", "min": 1, "max": 1, "weight": 5, "unique": false},
	{"id": "xp_potion", "min": 1, "max": 2, "weight": 25, "unique": false},
	{"id": "boss_map", "min": 1, "max": 1, "weight": 2.5, "unique": true},
	{"id": "wooden_shield", "min": 1, "max": 1, "weight": 2, "unique": true},
	{"id": "tricky_stick", "min": 1, "max": 1, "weight": 2, "unique": true},
	{"id": "wooden_sword", "min": 1, "max": 1, "weight": 1.5, "unique": true}
]

# --- ГОЛОВНА ФУНКЦІЯ ГЕНЕРАЦІЇ ЛУТУ ---
# Визначає кількість предметів, відфільтровує вже отримані унікальні речі 
# та предмети, що досягли ліміту стаків, а потім випадковим чином обирає нагороди.
static func generate_chest_loot() -> Array:
	var final_loot = []
	
	# 1. Визначаємо кількість предметів (1 гарантовано, 45% шанс на 2-й)
	var drops_count = 1
	if randf() <= 0.45:
		drops_count = 2
		
	# 2. Формуємо актуальний пул, викидаючи вже наявні або переповнені предмети
	var current_pool = []
	var total_weight: float = 0.0
	
	for item in CHEST_POOL:
		if item["unique"] and _has_unique_item(item["id"]):
			continue
		
		if not item["unique"] and item["id"] not in ["meowcoin", "meowgem"]:
			var current_amount = Global.inventory.get(item["id"], 0)
			if current_amount >= Global.MAX_STACK:
				continue
				
		current_pool.append(item.duplicate())
		total_weight += float(item["weight"])
		
	# 3. Вибираємо предмети (крутимо рулетку)
	for i in range(drops_count):
		if total_weight <= 0: 
			break
			
		var random_value = randf() * total_weight 
		var current_step: float = 0.0
		
		for j in range(current_pool.size()):
			var item = current_pool[j]
			current_step += float(item["weight"])
			
			if random_value < current_step:
				var amount = item["min"]
				
				if item["min"] < item["max"]:
					amount = get_tiered_amount(item["min"], item["max"])
				
				final_loot.append({"id": item["id"], "amount": amount})
				
				total_weight -= item["weight"]
				current_pool.remove_at(j)
				break
				
	return final_loot

# --- АЛГОРИТМ 5 ДІАПАЗОНІВ (ТІРІВ) КІЛЬКОСТІ ---
# Розбиває доступний діапазон (наприклад, 100-1000) на 5 рівних частин.
# Дає високий шанс (50%) на мінімальну нагороду і дуже низький.
static func get_tiered_amount(min_val: int, max_val: int) -> int:
	var range_size = max_val - min_val
	var step = range_size / 5.0 
	
	var tier_roll = randf() 
	var result_min = 0
	var result_max = 0
	
	if tier_roll <= 0.50:
		result_min = min_val
		result_max = int(min_val + step)
	elif tier_roll <= 0.75:
		result_min = int(min_val + step + 1)
		result_max = int(min_val + step * 2)
	elif tier_roll <= 0.90:
		result_min = int(min_val + step * 2 + 1)
		result_max = int(min_val + step * 3)
	elif tier_roll <= 0.97:
		result_min = int(min_val + step * 3 + 1)
		result_max = int(min_val + step * 4)
	else:
		result_min = int(min_val + step * 4 + 1)
		result_max = max_val
		
	return randi_range(result_min, result_max)

# --- ПЕРЕВІРКА НАЯВНОСТІ УНІКАЛЬНИХ ПРЕДМЕТІВ ---
# Аналізує словник інвентарю та слоти екіпірування гравця. 
# Якщо унікальний предмет вже отриманий, він більше не буде випадати.
static func _has_unique_item(id: String) -> bool:
	var item_value = Global.inventory.get(id, 0)
	
	if typeof(item_value) == TYPE_BOOL:
		if item_value == true: return true
	elif typeof(item_value) in [TYPE_INT, TYPE_FLOAT]:
		if item_value > 0: return true
		
	if Global.equipped_weapon == id or Global.equipped_shield == id: 
		return true
		
	return false
