extends Control

signal game_start

func _process(delta):
	if Input.is_anything_pressed():
		emit_signal("game_start")
		queue_free()
