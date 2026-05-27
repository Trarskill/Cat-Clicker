extends Node2D

@onready var sprite = $Sprite2D

func take_hit() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sprite, "rotation_degrees", 15.0, 0.05)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.9, 0.9), 0.05)
	
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.2)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
	
	await tween.finished
