extends Control

signal inventory_toggled(is_open: bool)
signal item_action_executed

@onready var panel = $Panel
@onready var grid = $Panel/MainLayout/MarginContainer/ScrollContainer/Grid
@onready var scroll_container = $Panel/MainLayout/MarginContainer/ScrollContainer

const ITEM_CARD_SCENE = preload("res://UI/Components/InventoryItemCard/InventoryItemCard.tscn")
const INTERACTION_WINDOW_SCENE = preload("res://UI/Components/InteractionWindow/InteractionWindow.tscn")

var current_popup = null

func _ready():
	visible = false
	panel.position.y = get_viewport_rect().size.y
	
	Global.item_timer_expired.connect(update_inventory_display)
	
	scroll_container.resized.connect(_on_scroll_resized)
	call_deferred("_on_scroll_resized")

func open():
	visible = true
	update_inventory_display()
	
	inventory_toggled.emit(true)
	
	var tw = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "position:y", get_viewport_rect().size.y - 800, 0.5)

func close():
	remove_current_popup()
	
	inventory_toggled.emit(false)
	
	var tw = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "position:y", get_viewport_rect().size.y, 0.5)
	await tw.finished
	visible = false

func create_item_card(item_id: String, count: int):
	var card = ITEM_CARD_SCENE.instantiate()
	var info = DataManager.get_item(item_id)
	
	if not info.is_empty():
		card.item_id = item_id
		card.item_name = info["name"]
		card.item_icon = load(info["icon"])
		
		grid.add_child(card)
		card.update_data(count)
		
		var is_equipped = (item_id == Global.equipped_weapon or item_id == Global.equipped_shield)
		card.set_equipped_visual(is_equipped)
	
		if card.has_signal("info_requested"):
			card.info_requested.connect(_on_card_info_requested)
	
		elif card.has_signal("item_clicked"):
			card.item_clicked.connect(_on_card_info_requested)

func update_inventory_display():
	for child in grid.get_children():
		child.queue_free()
	
	for item_id in Global.inventory.keys():
		var data = Global.inventory[item_id]
		
		var should_show = false
		var count = 0
		
		if typeof(data) == TYPE_BOOL:
			should_show = data
			count = 1
		else:
			count = data
			should_show = count > 0
		
		# УНІКАЛЬНА ВЛАСТИВІСТЬ: показувати предмети, поки тікає таймер, навіть при кількості 0
		if item_id == "bowl_with_bone" and Global.bowl_bone_timer > 0:
			should_show = true
		if item_id == "bag_of_fruit" and Global.bag_of_fruit_timer > 0:
			should_show = true
			
		if should_show:
			create_item_card(item_id, count)

func _on_card_info_requested(item_id: String, card_pos: Vector2) -> void:
	remove_current_popup() 
	
	var popup = INTERACTION_WINDOW_SCENE.instantiate()
	add_child(popup)
	current_popup = popup
	
	if popup.has_method("setup"):
		popup.setup(item_id)
	
	if popup.has_signal("action_performed"):
		popup.action_performed.connect(_on_popup_action_handled)
		
	if popup.has_method("appear_at"):
		popup.appear_at(card_pos)

# --- ЛОГІКА АДАПТИВНОЇ СІТКИ ---
func _on_scroll_resized() -> void:
	var available_width = scroll_container.size.x
	var card_total_width = 110.0 + 10.0 
	var new_columns = max(1, int(available_width / card_total_width))
	
	if grid.columns != new_columns:
		grid.columns = new_columns

func remove_current_popup():
	if current_popup and is_instance_valid(current_popup):
		current_popup.hide()
		current_popup.queue_free()
		current_popup = null

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if current_popup and is_instance_valid(current_popup) and current_popup.is_inside_tree():
			var popup_rect = current_popup.get_global_rect()
			if !popup_rect.has_point(event.global_position):
				remove_current_popup()

func _on_popup_action_handled(item_id: String, msg: String, is_success: bool):
	update_inventory_display()
	
	var text_color = Color(0.4, 1.0, 0.4) if is_success else Color(1.0, 0.4, 0.4)
	Global.show_floating_text(msg, text_color)
	
	item_action_executed.emit()
