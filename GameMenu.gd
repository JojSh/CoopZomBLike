extends Control

@onready var start_button = get_node("StartButton")

#func _ready():
# can remove this for prod mode
	#self.visible = false

func _on_start_button_pressed():
	self.visible = false
