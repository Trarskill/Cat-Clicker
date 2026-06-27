extends IdleDecoration

func _ready() -> void:
	item_id = "book_of_cat_tales"
	is_coin_reward = false
	db_reward_key = "passive_xp"
	feedback_color = Color(1.0, 0.7, 0.3)
	
	super._ready()
	
