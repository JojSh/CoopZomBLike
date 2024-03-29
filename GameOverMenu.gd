extends Control

var open_to_dismissal: bool = false

@onready var any_key_info = get_node("PressAnyKey")

func _process(delta):
	if open_to_dismissal and Input.is_anything_pressed():
		get_tree().reload_current_scene()

func _on_player_game_over():
	self.visible = true
	await get_tree().create_timer(1).timeout
	any_key_info.visible = true
	open_to_dismissal = true
