extends Control

var open_to_dismissal: bool = false

@onready var any_key_info = get_node("PressAnyKey")

func _process(_delta):
	if open_to_dismissal and Input.is_anything_pressed():
		get_tree().reload_current_scene()

func _on_main_game_over():
	await get_tree().create_timer(1).timeout
	self.visible = true
	await get_tree().create_timer(1).timeout
	any_key_info.visible = true
	open_to_dismissal = true
