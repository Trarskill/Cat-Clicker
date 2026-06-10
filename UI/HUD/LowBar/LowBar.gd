extends MarginContainer

func _ready() -> void:
	_apply_safe_area()

func _apply_safe_area() -> void:
	var os_name = OS.get_name()
	if os_name == "Windows" or os_name == "macOS" or os_name == "Linux":
		return
		
	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.window_get_size()
	
	if safe_area.size == window_size or window_size.y == 0:
		return
		
	var scale_ratio = get_viewport_rect().size.y / float(window_size.y)
	
	var bottom_dead_zone = window_size.y - safe_area.end.y
	var bottom_margin = bottom_dead_zone * scale_ratio
	
	if bottom_margin > 0:
		add_theme_constant_override("margin_bottom", int(bottom_margin))
