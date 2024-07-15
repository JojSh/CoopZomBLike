extends Control

signal game_start
signal change_map

func _process(_delta):
	if Input.is_action_just_pressed("start_game"):
		game_start.emit()
		queue_free()

	if Input.is_action_just_pressed("change_map") and is_visible_in_tree():
		print("Emitting change map signal")
		var maps = $MapSelect.get_children()
		# iterate through maps and find the one that is visible, make that one not visible and the next one invisible
		for i in range(maps.size()):
			if maps[i].is_visible_in_tree():
				maps[i].hide()
				if i == maps.size() - 1:
					maps[0].show()
					change_map.emit(0)
				else:
					maps[i + 1].show()
					change_map.emit(i + 1)
				break

# Try implementing this ^ nicer somthing like:
				#for i in range(maps.size()):
			#if maps[i].is_visible_in_tree():
				#maps[i].hide()
				##var index_to_show = 0 if (i == maps.size() - 1) else i + 1
				#var index_to_show = i + 1
				#if (i == maps.size() - 1): index_to_show = 0
				#maps[index_to_show].show()
				#change_map.emit(index_to_show)
