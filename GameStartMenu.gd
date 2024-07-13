extends Control

signal game_start

func _process(_delta):
	if Input.is_action_just_pressed("start_game"):
		game_start.emit()
		queue_free()
