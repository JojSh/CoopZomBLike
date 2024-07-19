extends Node3D

signal wave_complete
signal game_complete
signal game_over

@export var enemy_count : int

@onready var default_orc_zomb_scene = load("res://OrcZomb.tscn")
@onready var fast_orc_zomb_scene = load("res://OrcZombFast.tscn")
@onready var big_orc_zomb_scene = load("res://OrcZombBig.tscn")
@onready var player_scene = load("res://Player.tscn")
@onready var players_container = get_node("Players")
@onready var enemies = get_node("Enemies")
@onready var items = get_node("Items")
@onready var projectiles = get_node("Projectiles")
@onready var hud = get_node("UI/HUD")
@onready var phantom_camera = get_node("PhantomCamera3D")
@onready var world_environment = get_node("WorldEnvironment")

var wave_count : int = 0
var player_count : int = 2
var enemy_spawn_point_rotating_index : int = 0
var music_part_b_queued : bool = false
var spawn_point_modifier : float = 0.0

var enemy_wave_sequence : Array = [
	["default", "default"], # 0
	["default", "default", "default", "default"],
	["default", "default", "fast", "fast"],
	["default", "default", "fast", "fast", "fast"],
	["default", "default", "default", "default", "default", "big"], # 4
	["default", "default", "default", "default"], # 5
	["default", "default", "default", "default", "fast", "fast", "fast", "fast", "fast"],
	["default", "default", "default", "fast", "fast", "fast", "fast", "big"],
	["fast", "fast", "fast", "fast", "fast", "fast", "fast", "fast", "fast"],
	["default", "default", "default", "default", "fast", "fast",  "big", "fast", "big"] # 9 - bigs not grouped so they spawn at opposite corners.
]

var item_wave_sequence : Array = [
	[{ "type": "shield", "pos": "NE-I" }, { "type": "knife", "pos": "SE-I" }, { "type": "shield", "pos": "SW-I" }, { "type": "spear", "pos": "NW-I" }], # 0
	[{ "type": "shield", "pos": "NE-O" }, { "type": "knife", "pos": "SE-O" }, { "type": "health", "pos": "SW-O" }, { "type": "spear", "pos": "NW-O" }],
	[{ "type": "spear", "pos": "NE-O" }, { "type": "health", "pos": "SE-I" }, { "type": "spear", "pos": "SW-O" }, { "type": "knife", "pos": "NW-I" }],
	[
		{ "type": "shield", "pos": "NE-I" }, { "type": "health", "pos": "SE-I" }, { "type": "knife", "pos": "SW-I" }, { "type": "spear", "pos": "NW-I" },
		{ "type": "spear", "pos": "NE-O" }, { "type": "knife", "pos": "SE-O" }, { "type": "health", "pos": "SW-O" }, { "type": "shield", "pos": "NW-O" }
	],
	[ # 4
		{ "type": "knife", "pos": "NE-I" }, { "type": "knife", "pos": "SE-I" }, { "type": "knife", "pos": "SW-I" }, { "type": "knife", "pos": "NW-I" },
		{ "type": "health", "pos": "NE-O" }, { "type": "health", "pos": "SE-O" }, { "type": "health", "pos": "SW-O" }, { "type": "health", "pos": "NW-O" }
	],
	[ # 5
		{ "type": "shield", "pos": "NE-I" }, { "type": "health", "pos": "SE-I" }, { "type": "shield", "pos": "SW-I" }, { "type": "health", "pos": "NW-I" },
		{ "type": "health", "pos": "NE-O" }, { "type": "knife", "pos": "SE-O" }, { "type": "health", "pos": "SW-O" }, { "type": "spear", "pos": "NW-O" }
	],
	[{ "type": "shield", "pos": "NE-O" }, { "type": "knife", "pos": "SE-O" }, { "type": "health", "pos": "SW-O" }, { "type": "spear", "pos": "NW-O" }],
	[{ "type": "spear", "pos": "NE-O" }, { "type": "health", "pos": "SE-I" }, { "type": "spear", "pos": "SW-O" }, { "type": "knife", "pos": "NW-I" }],
	[
		{ "type": "shield", "pos": "NE-I" }, { "type": "health", "pos": "SE-I" }, { "type": "knife", "pos": "SW-I" }, { "type": "spear", "pos": "NW-I" },
		{ "type": "spear", "pos": "NE-O" }, { "type": "knife", "pos": "SE-O" }, { "type": "health", "pos": "SW-O" }, { "type": "shield", "pos": "NW-O" }
	],
	[
		{ "type": "knife", "pos": "NE-I" }, { "type": "spear", "pos": "SE-I" }, { "type": "knife", "pos": "SW-I" }, { "type": "spear", "pos": "NW-I" },
		{ "type": "health", "pos": "NE-O" }, { "type": "health", "pos": "SE-O" }, { "type": "health", "pos": "SW-O" }, { "type": "health", "pos": "NW-O" }
	],
]

func _ready ():
	load_map(0)

func spawn_all_players ():
	for i in player_count:
		spawn_player(i)

func spawn_player (index):
	var player = player_scene.instantiate()
	player.player_number = index + 1
	player.starting_position = $PlayerSpawnPoints.get_child(index).position

	players_container.add_child(player)
	player.connect('player_death', _on_player_player_death)
	player.connect('create_collectible', _on_create_collectible)
	player.connect('create_projectile', _on_create_projectile)

	phantom_camera.append_follow_targets(player)

func spawn_item_at_node (type, node_pos):
	var item = load("res://" + type + "_collectible.tscn").instantiate()
	var targeted_node_position = get_node("ItemSpawnPoints/" + node_pos).position

	item.global_position = targeted_node_position
	items.add_child(item)

func drop_item_at (type, x, z):
	var item = load("res://" + type + "_collectible.tscn").instantiate()
	item.global_position = Vector3(x, 0.5, z)
	items.add_child(item)

func spawn_enemy (variant):
	var orc_zomb
	if (variant == "fast"):
		orc_zomb = fast_orc_zomb_scene.instantiate()
	elif (variant == "big"):
		orc_zomb = big_orc_zomb_scene.instantiate()
	elif (variant == "default"):
		orc_zomb = default_orc_zomb_scene.instantiate()

	var pos_to_spawn_at = $EnemySpawnPoints.get_child(enemy_spawn_point_rotating_index)

	orc_zomb.global_position = Vector3(pos_to_spawn_at.position.x + spawn_point_modifier, 0.5, pos_to_spawn_at.position.z)

	if (enemy_spawn_point_rotating_index == 3):
		enemy_spawn_point_rotating_index = 0
		spawn_point_modifier += 0.1
	else:
		enemy_spawn_point_rotating_index += 1
	enemies.add_child(orc_zomb)
	orc_zomb.connect('enemy_death', _on_orc_zomb_enemy_death)

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

	for item in items.get_children():
		item.queue_free()

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

	for enemy_type in enemy_wave_sequence[wave_count]:
		spawn_enemy(enemy_type)

	for item in item_wave_sequence[wave_count]:
		spawn_item_at_node(item.type, item.pos)

	update_enemy_counter()

func resurrect_player (player):
	player.revive()
	phantom_camera.append_follow_targets(player)

func get_dead_players ():
	return players_container.get_children().filter(func(player):
		return player.is_dead == true
	)

func get_alive_players ():
	return players_container.get_children().filter(func(player):
		return player.is_dead == false
	)

func load_map (map_num):
	var first_map = load("res://maps/map_" + str(map_num) + ".tscn")
	var map_scene = first_map.instantiate()
	world_environment.add_child(map_scene)

# _on signal functions:
func _on_create_collectible (type, location):
	drop_item_at(type, location.x, location.y)

func _on_create_projectile (type, location, facing_angle, impulse):
	var projectile = load("res://" + type + "_projectile.tscn")
	var thrown_projectile = projectile.instantiate()
	thrown_projectile.position = location
	thrown_projectile.rotation = Vector3(0, facing_angle, 0)
	projectiles.add_child(thrown_projectile)
	thrown_projectile.connect('create_collectible', _on_create_collectible)
	thrown_projectile.apply_impulse(impulse)

func _on_orc_zomb_enemy_death ():
	update_enemy_counter()

func _on_player_player_death ():
	await get_tree().create_timer(1).timeout

	var last_dead_player = get_dead_players()[-1]
	phantom_camera.erase_follow_targets(last_dead_player)

	if get_alive_players().size() < 1:
		game_over.emit()

func _on_game_start_menu_game_start():
	spawn_all_players()
	generate_wave()
	music_part_b_queued = true

func _on_game_start_menu_change_map(map_index):
	world_environment.get_child(0).queue_free()
	load_map(map_index)

func _on_wave_complete_screen_wave_advance():
	wave_count += 1
	generate_wave()

func _on_part_a_finished():
	if wave_count > 1:
		$Music/PartB.play()
	else:
		$Music/PartA.play()

func _on_part_b_finished():
	$Music/PartB.play()
