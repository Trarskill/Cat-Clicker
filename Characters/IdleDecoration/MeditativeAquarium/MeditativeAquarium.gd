extends IdleDecoration

func _ready() -> void:
	item_id = "meditative_aquarium"
	is_coin_reward = true
	db_reward_key = "passive_coins"
	feedback_color = Color(1.0, 0.84, 0.0)
	
	# Акваріум має іншу траєкторію польоту тексту, тому ми її тут перевизначаємо
	text_target_x_range = Vector2(-20.0, 20.0)
	
	super._ready()
