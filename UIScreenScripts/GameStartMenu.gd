extends Control

signal game_start

var rng_mode_on : bool = false
var available_maps : bool = false
var controls_display_visible : bool = true

@onready var start_button = $MarginContainer/VBoxContainer/HSplitContainer/LeftVBox/Start
@onready var show_controls_toggle = $MarginContainer/VBoxContainer/HSplitContainer/LeftVBox/ShowControlsToggle
@onready var controls_display = $MarginContainer/VBoxContainer/HSplitContainer/LeftVBox/ControlsDisplay

func _ready():
	start_button.grab_focus()

func _on_start_pressed():
	queue_free()

func _on_show_controls_toggle_pressed():
	controls_display_visible = not controls_display_visible # toggle the bool
	if (controls_display_visible):
		show_controls_toggle.text = "Hide controls"
		controls_display.visible = true
	else:
		show_controls_toggle.text = "Show controls"
		controls_display.visible = false
