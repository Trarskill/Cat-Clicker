extends IdleDecoration

func _ready() -> void:
	item_id = "soft_pet_bed"
	is_coin_reward = false
	db_reward_key = "passive_xp"
	feedback_color = Color(0.7, 0.4, 0.9)
	
	super._ready()
