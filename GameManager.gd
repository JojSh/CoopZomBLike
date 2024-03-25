extends Node3D

signal wave_complete
signal game_complete

@export var enemy_count : int

@onready var OrcZombScene = load("res://OrcZomb.tscn")
@onready var players = get_node("Players").get_children()
@onready var enemies = get_node("Enemies")
@onready var items = get_node("Items")
@onready var hud = get_node("UI/HUD")

var wave_count : int = 0
var enemy_wave_sequence : Array = [
	[{ "x": 18, "z": -6 }],
	[{ "x": 18, "z": -6 }, { "x": -10, "z": 5 }],
	[{ "x": 18, "z": -6 }, { "x": 18, "z": 6 }, { "x": -10, "z": 5 }],
	[{ "x": 18, "z": -6 }, { "x": 18, "z": 6 }, { "x": -10, "z": 5 }, { "x": -10, "z": -5 }]
]

var item_wave_sequence : Array = [
	[],
	[{ "item_name": "shield", "x": 4.5, "z": -8 }, { "item_name": "health", "x": 0, "z": 0 }],
	[{ "item_name": "knife", "x": 4.5, "z": 7 }, { "item_name": "health", "x": 0, "z": 0 }],
]

func _on_orc_zomb_enemy_death():
	update_enemy_counter()

func spawn_enemy_at (x, z):
	var orc_zomb = OrcZombScene.instantiate()
	orc_zomb.global_position = Vector3(x, 0.5, z)
	enemies.add_child(orc_zomb)
	orc_zomb.connect('enemy_death', _on_orc_zomb_enemy_death)

func spawn_item_at (item_name, x, z):
	var item = load("res://" + item_name + "_collectible.tscn").instantiate()
	item.global_position = Vector3(x, 0.5, z)
	items.add_child(item)

func update_enemy_counter ():
	await get_tree().create_timer(0).timeout # waiting for even 0 sec seems to allow for the enemy to be deleted and the count to be correct
	enemy_count = enemies.get_children().size()
	hud.update_enemy_counter(enemy_count)

	if (enemy_count <= 0):
		if (wave_count + 1 == enemy_wave_sequence.size()):
			emit_signal("game_complete")
		else:
			emit_signal("wave_complete")

func generate_wave ():
	for i in enemy_wave_sequence[wave_count]:
		spawn_enemy_at(i.x, i.z)
	
	for j in item_wave_sequence[wave_count]:
		spawn_item_at(j.item_name, j.x, j.z)

	for player in players:
		player.reset_position()
	update_enemy_counter()

func _on_game_start_menu_game_start():
	generate_wave()

func _on_wave_complete_screen_wave_advance():
	wave_count += 1
	generate_wave()
