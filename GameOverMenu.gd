extends Control

func _on_player_game_over():
	self.visible = true


func _on_start_button_pressed():
	get_tree().reload_current_scene()
