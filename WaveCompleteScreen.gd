extends Control

func _on_main_wave_complete():
	self.visible = true


func _on_advance_button_pressed():
	self.visible = false
