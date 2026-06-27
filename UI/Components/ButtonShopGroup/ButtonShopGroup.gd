extends HBoxContainer

signal shop_category_changed(category_id: String)

@onready var tabs = [
	$TabGeneral,
	$TabWeapon,
	$TabMagic
]

func _ready():
	for tab in tabs:
		if tab.has_signal("tab_clicked"):
			tab.tab_clicked.connect(_on_tab_clicked)
	
	call_deferred("_select_initial_tab")

func _select_initial_tab():
	_on_tab_clicked("general")

func _on_tab_clicked(clicked_id: String):
	for tab in tabs:
		tab.set_active(tab.tab_id == clicked_id)
	
	shop_category_changed.emit(clicked_id)
