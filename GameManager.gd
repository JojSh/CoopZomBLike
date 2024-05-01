extends Node3D

signal wave_complete
signal game_complete
signal game_over

@export var enemy_count : int

@onready var orc_zomb_scene = load("res://OrcZomb.tscn")
@onready var player_scene = load("res://Player.tscn")
@onready var players_container = get_node("Players")
@onready var enemies = get_node("Enemies")
@onready var items = get_node("Items")
@onready var projectiles = get_node("Projectiles")
@onready var hud = get_node("UI/HUD")

var wave_count : int = 0
var player_count : int = 4

var enemy_wave_sequence : Array = [
	#[{ "x": 12, "z": 0 }], # test wave with 1 enemy
	[{ "x": 18, "z": -6 }, { "x": -10, "z": 5 }],
	[{ "x": 18, "z": -6 }, { "x": 18, "z": 6 }, { "x": -10, "z": 5 }],
	[{ "x": 18, "z": -6 }, { "x": 18, "z": 6 }, { "x": -10, "z": 5 }, { "x": -10, "z": -5 }],
	[
		{ "x": 16, "z": -8 }, { "x": 16, "z": 8 }, { "x": -8, "z": 7 }, { "x": -8, "z": -7 },
		{ "x": 18, "z": -6 }, { "x": 18, "z": 6 }, { "x": -10, "z": 5 }, { "x": -10, "z": -5 }
	]
]

var item_wave_sequence : Array = [
	[],
	[{ "item_name": "shield", "x": 4.5, "z": -8 }, { "item_name": "health", "x": 0, "z": 0 }],
	[{ "item_name": "knife", "x": 4.5, "z": 7 }, { "item_name": "health", "x": 0, "z": 0 }],
	[{ "item_name": "spear", "x": -6, "z": -1 }, { "item_name": "spear", "x": 14.5, "z": -1 }, { "item_name": "health", "x": 0, "z": 0 }],
]

func _ready ():
	spawn_all_players()

func _on_orc_zomb_enemy_death ():
	update_enemy_counter()

func _on_player_player_death ():
	var alive_players = get_alive_players()
	if alive_players.size() < 1:
		game_over.emit()

func spawn_all_players ():
	for i in player_count:
		spawn_player(i)

func spawn_player (index):
	var player = player_scene.instantiate()
	player.player_number = index + 1
	player.starting_position = Vector3(index * 3, 0.5, -3)
	players_container.add_child(player)
	player.connect('player_death', _on_player_player_death)
	player.connect('create_collectible', _on_create_collectible)
	player.connect('create_projectile', _on_create_projectile)

func spawn_enemy_at (x, z):
	var orc_zomb = orc_zomb_scene.instantiate()
	orc_zomb.global_position = Vector3(x, 0.5, z)
	enemies.add_child(orc_zomb)
	orc_zomb.connect('enemy_death', _on_orc_zomb_enemy_death)

func spawn_item_at (item_name, x, z):
	var item = load("res://" + item_name + "_collectible.tscn").instantiate()
	item.global_position = Vector3(x, 0.5, z)
	items.add_child(item)

func _on_create_collectible (item_name, location):
	spawn_item_at(item_name, location.x, location.y)
	
func _on_create_projectile (item_name, location, facing_angle, impulse):
	var projectile = load("res://" + item_name + "_projectile.tscn")
	var thrown_projectile = projectile.instantiate()
	thrown_projectile.position = location
	thrown_projectile.rotation = Vector3(0, facing_angle, 0)
	projectiles.add_child(thrown_projectile)
	thrown_projectile.connect('create_collectible', _on_create_collectible)
	thrown_projectile.apply_impulse(impulse)

func update_enemy_counter ():
	await get_tree().create_timer(0).timeout # waiting for even 0 sec seems to allow for the enemy to be deleted and the count to be correct
	var alive_enemies = enemies.get_children().filter(func(enemy):
		return enemy.is_dead == false
	)
	enemy_count = alive_enemies.size()
	
	hud.update_enemy_counter(enemy_count)

	if (enemy_count <= 0):
		if (wave_count + 1 == enemy_wave_sequence.size()):
			game_complete.emit()
		else:
			wave_complete.emit()

func cleanup_wave ():
	for enemy in enemies.get_children():
		enemy.queue_free()

	var dead_players = get_dead_players()
	
	for player in dead_players:
		resurrect_player(player)

	# need to set this after resurrection has taken place as the list is not
	# updated with the latest otherwise!
	var alive_players = get_alive_players()
	
	for player in alive_players:
		player.reset_position()
	
	await get_tree().create_timer(2).timeout

func generate_wave ():
	cleanup_wave()
	for i in enemy_wave_sequence[wave_count]:
		spawn_enemy_at(i.x, i.z)
	
	for j in item_wave_sequence[wave_count]:
		spawn_item_at(j.item_name, j.x, j.z)

	update_enemy_counter()

func _on_game_start_menu_game_start():
	generate_wave()

func _on_wave_complete_screen_wave_advance():
	wave_count += 1
	generate_wave()

func resurrect_player (player) :
	player.revive()

func get_dead_players ():
	return players_container.get_children().filter(func(player):
		return player.is_dead == true
	)

func get_alive_players ():
	return players_container.get_children().filter(func(player):
		return player.is_dead == false
	)
