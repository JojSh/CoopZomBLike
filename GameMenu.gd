extends Control

@onready var start_button = get_node("StartButton")

func _on_start_button_pressed():
	print("you pressed the start button")
	self.visible = false
