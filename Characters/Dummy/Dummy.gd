extends Node2D

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	if anim.sprite_frames.get_frame_count("idle") > 0:
		anim.play("idle")


func take_hit() -> void:
	if anim.sprite_frames.get_frame_count("hurt") > 0:
		anim.play("hurt")
		
		await anim.animation_finished
		
		anim.play("idle")
	else:
		print("Анімація attack ще не додана!")
		await get_tree().create_timer(0.5).timeout 
	
