extends Node

# --- ТИПИ ПРЕДМЕТІВ ---
enum ItemType { CONSUMABLE, EQUIPMENT, SPECIAL }

# --- БАЗА ДАНИХ ПРЕДМЕТІВ ---
const ITEM_DATABASE = {
# --- СКРИНЯ ---
	"mysterious_chest": {
		"name": "Дерев'яна скриня з печатко",
		"description": "Отримаєте декілька монет, але в майбутньому можна отримати щось ціне",
		"proper": "Отримання предметів або грошей",
		"icon": "res://Assets/Graphics/Icons/Items/mysterious-chest-ai.png",
		"type": ItemType.SPECIAL,
		"price": 10,
		"for_gem": true,
		"stackable": false,
		"stats": {"loot_table": true}
	},

# --- РОЗХІДНИКИ ---
	"bowl_with_bone": {
		"name": "Кісточка від риби",
		"description": "Хтось уже поласував найсмачнішим, але ця хрустка кісточка все ще зберігає аромат великого полювання",
		"proper": "+1 XP за клік",
		"icon": "res://Assets/Graphics/Icons/Items/bowl-with-bone-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 5,
		"for_gem": false,
		"stackable": true,
		"stats": {"xp_bonus": 1, "duration": 60}
	},
	"bowl_with_rice": {
		"name": "Миска з рисом",
		"description": "Простий, але дуже поживний рис. Коти не завжди в захваті від нього, але енергію він дає стабільно.",
		"proper": "+9 XP за клік",
		"icon": "res://Assets/Graphics/Icons/Items/bowl-with-rice-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 45,
		"for_gem": false,
		"stackable": true,
		"stats": {"xp_bonus": 9, "duration": 60}
	},
	"bowl_with_fish": {
		"name": "Миска з рибкою",
		"description": "Свіжа, ароматна рибка! Від одного запаху котик сповнюється ситим і готовий тренуватися інтенсивніше.",
		"proper": "+19 XP за клік",
		"icon": "res://Assets/Graphics/Icons/Items/bowl-with-fish-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 135, 
		"for_gem": false,
		"stackable": true,
		"stats": {"xp_bonus": 19, "duration": 60}
	},
	"apple": {
		"name": "Яблуко",
		"description": "Звичайне яблуко, можна зїсти, але воно дуже кисле при з'їданні можемо й нічого неотримати.",
		"proper": "+45 XP з шансом 50%",
		"icon": "res://Assets/Graphics/Icons/Items/apple-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 25,
		"for_gem": false,
		"stackable": true,
		"stats": {"give_xp": 45, "chance": 0.5}
	},
	"bag_of_fruit": {
		"name": "Мішечок з фруктами",
		"description": "Ці фрукти світяться! Їхній сік настільки незвичайний, що на короткий час перетворює кожен рух на магніт для золота!",
		"proper": "1 Клік = 1 Монета",
		"icon": "res://Assets/Graphics/Icons/Items/bag-of-fruit-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 500,
		"for_gem": false,
		"stackable": true,
		"stats": {"coin_gets": 1, "duration": 60}
	},
	"catnip": {
		"name": "Котяча м'ята",
		"description": "Сушена м'ята найвищого ґатунку. Від одного її запаху в котику прокидається дикий!",
		"proper": "x2 XP за клік",
		"icon": "res://Assets/Graphics/Icons/Items/catnip-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 500,
		"for_gem": false,
		"stackable": true,
		"stats": {"xp_multiplier": 2.0, "duration": 30}
	},

# --- ЗІЛЛЯ ---
	"xp_potion": {
		"name": "Зілля досвіду",
		"description": "Це зілля надає прорив в зняннях! Кожен рівень кото-магії підвищую отриманий XP (на 100).",
		"proper": "+100 XP",
		"icon": "res://Assets/Graphics/Icons/Items/potion-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 100,
		"for_gem": false,
		"stackable": true,
		"stats": {"catalyst": true}
	},
	"strength_potion": {
		"name": "Зілля сили",
		"description": "Густа червона рідина. Дуже чарівний запах, назавжди робить лапки міцнішими.",
		"proper": "Сила +1 XP назавжди",
		"icon": "res://Assets/Graphics/Icons/Items/strength-potion-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 2,
		"for_gem": true,
		"stackable": true,
		"stats": {"permanent_power": 1}
	},
	"curse_potion": {
		"name": "Зілля прокляття",
		"description": "Підозріле темне зілля. Забирає трохи фізичної сили, але натомість матеріалізує кристали просто з повітря.",
		"proper": "Сила -1 XP назавжди, +2 гем",
		"icon": "res://Assets/Graphics/Icons/Items/curse-potion-ai.png",
		"type": ItemType.CONSUMABLE,
		"price": 10,
		"for_gem": false,
		"stackable": true,
		"stats": {"permanent_power": -1, "gem_reward": 2}
	},

# --- МАГІЯ ---
	"cat_magic": {
		"name": "Кото-Магія",
		"description": "Стародавня сила, що зростає з кожним ритуалом.",
		"proper": "Треба володіти магією",
		"icon": "res://Assets/Graphics/Icons/Items/cat-magic-ai.png",
		"type": ItemType.SPECIAL,
		"price": 0, 
		"for_gem": false,
		"stackable": true, 
		"is_upgrade_only": true,
		"max_lvl": 10,
		"stats": {"multiplier_per_level": 0.05}
	},

# --- ЗБРОЯ/ЕКІПЕРУВАННЯ ---
	"wooden_sword": {
		"name": "Меч з дерева",
		"description": "Звичайни мач з дерева? З ним я стану сильнішим!",
		"proper": "Сила +7 XP",
		"icon": "res://Assets/Graphics/Icons/Items/wooden-sword-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 1000,
		"for_gem": false,
		"stackable": false,
		"stats": {"xp_bonus": 7}
	},
	"wooden_shield": {
		"name": "Щит з дерева",
		"description": "А навіщо він?",
		"proper": "Сила +6 XP",
		"icon": "res://Assets/Graphics/Icons/Items/wooden-shield-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 750,
		"for_gem": false,
		"stackable": false,
		"stats": {"xp_bonus": 6}
	},
	"steel_sword": {
		"name": "Стальний меч",
		"description": "Невеликий, але гострий та важкий, крашій за деревяний для бійок та тренувань.",
		"proper": "Сила +20 XP",
		"icon": "res://Assets/Graphics/Icons/Items/steel-sword-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 2500,
		"for_gem": false,
		"stackable": false,
		"stats": {"xp_bonus": 20}
	},
	"magic_stick": {
		"name": "Стара магічна палиця",
		"description": "Кажуть що я зможу чаклувати магією з неї, але треба мінімум 1 lvl \"Кото-Магії\".",
		"proper": "Сила +60 XP",
		"icon": "res://Assets/Graphics/Icons/Items/wooden-magic-wand-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 5000,
		"for_gem": false,
		"stackable": false,
		"stats": {"xp_bonus": 60, "cat_magic": true}
	},
	"magic_fishing_rod": {
		"name": "Магічна вудка",
		"description": "Хто сказав, що вудкою треба ловити тільки рибу? Завдяки зачаруванню вона буквально вибиває монети з манекена!",
		"proper": "+1 монета за клік",
		"icon": "res://Assets/Graphics/Icons/Items/magic-fishing-rod-ai.png",
		"type": ItemType.EQUIPMENT,
		"price": 9990,
		"for_gem": false,
		"stackable": false,
		"stats": {"coin_bonus": 1}
	},
	
# --- СПЕЦИФІЧНІ РЕЧІ ---
	"clockwork_mouse": {
		"name": "Завідна Мишка",
		"description": "Маленький механічний помічник. Заведіть її триває 5хвилин, і вона буде несамовито лупити манекен замість вас, поки не закінчиться завод.",
		"proper": "Працює 30 сек (Перезарядка: 5 хв)",
		"icon": "res://Assets/Graphics/Icons/Items/clockwork-mouse-ai.png",
		"type": ItemType.SPECIAL,
		"price": 3950,
		"for_gem": false,
		"stackable": false,
		"stats": {"auto_click_duration": 30, "cooldown": 300}
	},
	"boss_map": {
		"name": "Старовинна Карта",
		"description": "Потертий пергамент із загадковими мітками. Що так де намальовано великий червоний хрест?",
		"proper": "Дозволяє кинути виклик Босам",
		"icon": "res://Assets/Graphics/Icons/Items/map-ai.png",
		"type": ItemType.SPECIAL,
		"price": 1100,
		"for_gem": false,
		"stackable": false,
		"stats": {"unlock_boss_battles": true}
	},
	"magical_rose": {
		"name": "Магічна роза",
		"description": "Кажуть якщо її змішати з якимсь зіллям можно стати кот-магом.",
		"proper": "Отримання кото-магії.",
		"icon": "res://Assets/Graphics/Icons/Items/magical-rose-ai.png",
		"type": ItemType.SPECIAL,
		"price": 1,
		"for_gem": true,
		"stackable": true,
		"stats": {"magic_upgrade": true}
	}
}

# --- ФУНКЦІЯ ДОСТУПУ ---
func get_item(id: String) -> Dictionary:
	if ITEM_DATABASE.has(id):
		return ITEM_DATABASE[id]
	print("[DataManager] Помилка: Предмет '", id, "' не знайдено в базі даних!")
	return {}
