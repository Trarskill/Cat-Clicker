extends VBoxContainer

@onready var level_title = $LevelTitle
@onready var progress_bar = $BarRow/ProgressBar
@onready var xp_label = $BarRow/ProgressBar/XPLabel

var fade_tween: Tween

func _ready() -> void:
	xp_label.modulate.a = 0.0
	xp_label.visible = false
	update_level_data(Global.level, Global.xp, Global.max_xp)

func update_level_data(new_level: int, new_xp: int, new_max: int) -> void:
	if new_level >= 100:
		level_title.text = "Рівень MAX"
		progress_bar.max_value = new_max
		progress_bar.value = new_xp
		xp_label.text = str(new_xp) + " / " + str(new_max) + " XP"
	else:
		level_title.text = "Рівень " + str(new_level)
		progress_bar.max_value = new_max
		progress_bar.value = new_xp
		xp_label.text = str(new_xp) + " / " + str(new_max) + " XP"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			trigger_xp_label()

func trigger_xp_label() -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	xp_label.visible = true
	xp_label.modulate.a = 1.0
	
	fade_tween = create_tween()
	fade_tween.tween_interval(2.5)
	fade_tween.tween_property(xp_label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	fade_tween.chain().tween_callback(func(): xp_label.visible = false)

func update_xp(new_xp: int, new_max: int) -> void:
	progress_bar.max_value = new_max
	progress_bar.value = new_xp
	xp_label.text = str(new_xp) + " / " + str(new_max) + " XP"
