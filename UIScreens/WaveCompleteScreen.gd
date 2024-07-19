extends Control

signal wave_advance

var open_to_dismissal: bool = false

@onready var any_key_info = get_node("PressAnyKey")

func _process(_delta):
	if open_to_dismissal and Input.is_anything_pressed():
		wave_advance.emit()
		reset_menu_on_dismiss()

func _on_main_wave_complete ():
	self.visible = true
	open_to_dismissal = false

	await get_tree().create_timer(1).timeout
	any_key_info.visible = true
	open_to_dismissal = true

func reset_menu_on_dismiss ():
		self.visible = false
		open_to_dismissal = false
		any_key_info.visible = false
