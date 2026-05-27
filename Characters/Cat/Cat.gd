extends Node2D

@onready var anim = $AnimatedSprite2D
@onready var shadow = $Shadow

func _ready() -> void:
	if anim.sprite_frames.get_frame_count("idle") > 0:
		anim.play("idle")
		shadow.play("idle")

func play_attack() -> void:
	if anim.sprite_frames.get_frame_count("attack") > 0:
		anim.play("attack")
		shadow.play("attack")
		
		await anim.animation_finished
		
		anim.play("idle")
		shadow.play("idle") 
	else:
		print("Анімація attack ще не додана!")
		await get_tree().create_timer(0.5).timeout
