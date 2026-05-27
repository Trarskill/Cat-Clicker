extends Node

# --- ТИПИ ПРЕДМЕТІВ ---
enum ItemType { CONSUMABLE, EQUIPMENT, SPECIAL }

# --- БАЗА ДАНИХ ПРЕДМЕТІВ ---
const ITEM_DATABASE = {
	"mysterious_chest": {
		"name": "Дерев'яна скриня з печатко",
		"desc": "Цікаво що в серениді?",
		"proper": "Отримаєте декілька монет, але в майбутньому можна отримати щось ціне",
		"icon": "res://Assets/Graphics/Icons/Items/mysterious-chest-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 10,
		"is_premium": true,
		"stackable": false,
		"stats": {"loot_table": true}
	},
	"bowl": {
		"name": "Кісточка від риби",
		"desc": "Рибу хтось з'їв і залишилася тільки кісточка",
		"proper": "Дає +1 XP за клік (діє 1 хв).",
		"icon": "res://Assets/Graphics/Icons/Items/bowl-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 5,
		"is_premium": false,
		"stackable": true,
		"stats": {"xp_bonus": 1, "duration": 60}
	},
	"apple": {
		"name": "Яблуко",
		"desc": "Звичайне яблуко, але дуже кисле.",
		"proper": "Дає 45 XP, але при з'їданні можемо й нічого неотримати.",
		"icon": "res://Assets/Graphics/Icons/Items/apple-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 35,
		"is_premium": false,
		"stackable": true,
		"stats": {"give_xp": 45, "chance": 0.5}
	},
	"bag_of_fruit": {
		"name": "Мішечок з фруктами",
		"desc": "Ці фрукти світяться? Що буде якщо їх з'їсти?",
		"proper": "Кожен 5-й клік дає до 10 монет (діє 1 хв).",
		"icon": "res://Assets/Graphics/Icons/Items/bag-of-fruit-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 500,
		"is_premium": false,
		"stackable": true,
		"stats": {"coin_chance": 10, "duration": 60}
	},
	"potion": {
		"name": "Невідоме зілля",
		"desc": "Я не впевнений що це гарна думака пити це!",
		"proper": "Дає 100 XP, кожний рівень кото-магії підвищує отримані XP на 100.",
		"icon": "res://Assets/Graphics/Icons/Items/potion-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 100,
		"is_premium": false,
		"stackable": true,
		"stats": {"catalyst": true}
	},

	"wooden_sword": {
		"name": "Меч з дерева",
		"desc": "Скільки за шматок дерева? це грабунок!",
		"proper": "Дає +7 XP при надяганні",
		"icon": "res://Assets/Graphics/Icons/Items/wooden-sword-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 1000,
		"is_premium": false,
		"stackable": false,
		"stats": {"xp_bonus": 7}
	},
	"wooden_shield": {
		"name": "Щит з дерева",
		"desc": "А навіщо він?",
		"proper": "Дає +6 XP при надяганні.",
		"icon": "res://Assets/Graphics/Icons/Items/wooden-shield-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 750,
		"is_premium": false,
		"stackable": false,
		"stats": {"xp_bonus": 6}
	},
	"steel_sword": {
		"name": "Стальний меч",
		"desc": "Цим буде найкреше бити по ворогу",
		"proper": "Дає +20 XP при надяганні.",
		"icon": "res://Assets/Graphics/Icons/Items/steel-sword-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 2500,
		"is_premium": false,
		"stackable": false,
		"stats": {"xp_bonus": 20}
	},
	"magic_stick": {
		"name": "Стара магічна палиця",
		"desc": "Кажуть що я зможу стріляти магією з неї, але як?",
		"proper": "Дає +60 XP при надяганні та наявності мінімум 1 lvl кото-магії.",
		"icon": "res://Assets/Graphics/Icons/Items/wooden-magic-wand-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 5000,
		"is_premium": false,
		"stackable": false,
		"stats": {"xp_bonus": 60, "cat_magic": true}
	},
	"magical_rose": {
		"name": "Магічна роза",
		"desc": "Кажуть якщо її змішати з зіллям можно стати кот-магом.",
		"proper": "Використовується з зіллям для отримання кото-магії.",
		"icon": "res://Assets/Graphics/Icons/Items/magical-rose-ai.png",
		"type": ItemType.SPECIAL,
		"price": 1,
		"is_premium": true,
		"stackable": true,
		"stats": {"magic_upgrade": true}
	},
	"cat_magic": {
		"name": "Кото-Магія",
		"desc": "Стародавня сила, що зростає з кожним ритуалом.",
		"proper": "Пасивно кожен рівень магії збільшує XP на 5%.",
		"icon": "res://Assets/Graphics/Icons/Items/cat-magic-ai.png",
		"type": ItemType.SPECIAL,
		"price": 0, 
		"is_premium": false,
		"stackable": true, 
		"is_upgrade_only": true,
		"max_lvl": 10,
		"stats": {"multiplier_per_level": 0.05}
	}
}

# --- ФУНКЦІЯ ДОСТУПУ ---
func get_item(id: String) -> Dictionary:
	if ITEM_DATABASE.has(id):
		return ITEM_DATABASE[id]
	print("[DataManager] Помилка: Предмет '", id, "' не знайдено в базі даних!")
	return {}
