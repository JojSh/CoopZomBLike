extends Node

var generated_items : Array
var item_spawn_points : Array
var all_item_types : Array = ["shield", "knife", "spear", "health"]

var generated_enemies : Array
var enemy_heat_val : int
var all_enemy_types = [
	# default 3x more likely than big, fast 2x more likely than big.
	{ "type": "default", "heat_val": 1 }, { "type": "default", "heat_val": 1 }, { "type": "default", "heat_val": 1 },
	{ "type": "fast", "heat_val": 2 }, { "type": "fast", "heat_val": 2 },
	{ "type": "big", "heat_val": 5 }
]

var generated_wave : Dictionary
var heat : int

func generate_wave (received_heat):
	heat = received_heat
	generate_items()
	generate_enemies()
	return generated_wave

func generate_items ():
	var number_of_items = randi() % 4 + 5 # random from 4-8
	var items_heat_val = number_of_items * 2 # currently all items have power level of 2
	var item_gen_index = 0

	# adjust for number (and potentially sum power) of generated items
	enemy_heat_val = heat + items_heat_val
	
	# reset to full list whenever generate_items() is called again.
	item_spawn_points = ["NE-I", "SE-I", "SW-I", "NW-I", "NE-O", "SE-O", "SW-O", "NW-O"]

	while item_gen_index < items_heat_val:
		var random_idx = randi() % all_item_types.size()
		item_gen_index += 2
		item_spawn_points.shuffle()
		var assigned_spawn_point = item_spawn_points.pop_back()
		generated_items.push_back({ "type": all_item_types[random_idx], "spawn_point": assigned_spawn_point })

	generated_wave.items = generated_items

func generate_enemies ():
	var enemy_gen_index = 0

	while enemy_gen_index < enemy_heat_val:
		var remaining_heat = enemy_heat_val - enemy_gen_index

		# filter out enemies with higher than remaining unspent heat value
		var available_enemy_types = all_enemy_types.filter(func(enemy):
			return enemy.heat_val <= remaining_heat
		)

		var random_idx = randi() % available_enemy_types.size()
		var selected_enemy = available_enemy_types[random_idx]

		enemy_gen_index += selected_enemy.heat_val
		generated_enemies.push_back(selected_enemy.type)
	
	generated_wave.enemies = generated_enemies
