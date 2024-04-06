extends Control

signal game_start

func _process(delta):
	if Input.is_anything_pressed():
		game_start.emit()
		queue_free()
