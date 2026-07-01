extends Button

func _ready() -> void:
	pressed.connect(_on_button_pressed)
	
	Global.multi_mode_changed.connect(_update_text)
	
	_update_text()

func _on_button_pressed() -> void:
	if Global.SFX.has("CLICK"):
		AudioManager.play_sfx(Global.SFX["CLICK"], false, true)
	
	Global.current_multi_idx = (Global.current_multi_idx + 1) % Global.multi_click_options.size()
	
	Global.multi_mode_changed.emit()

func _update_text() -> void:
	var val = Global.multi_click_options[Global.current_multi_idx]
	if val == 999:
		text = "MAX"
	else:
		text = "x" + str(val)
