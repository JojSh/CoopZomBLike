extends Node3D

signal wave_complete

@export var enemy_count : int

@onready var OrcZombScene = load("res://OrcZomb.tscn")
@onready var enemies = get_node("Enemies")
@onready var hud = get_node("UI/HUD")

var wave_count : int = 0
var enemy_wave_sequence : Array = [
	[{ "x": 18, "z": -6 }, { "x": -10, "z": 5 }],
	[{ "x": 18, "z": -6 }, { "x": 18, "z": 6 }, { "x": -10, "z": 5 }],
	[{ "x": 18, "z": -6 }, { "x": 18, "z": 6 }, { "x": -10, "z": 5 }, { "x": -10, "z": -5 }]
]

func _ready():
	generate_enemy_wave()

func _process(delta):
	if Input.is_action_just_pressed("debug_test"):
		print(enemies.get_children())

func _on_orc_zomb_enemy_death():
	print(enemies.get_children())
	update_enemy_counter()

func spawn_enemy_at (x, z):
	var orc_zomb = OrcZombScene.instantiate()
	orc_zomb.global_position = Vector3(x, 0.5, z)
	enemies.add_child(orc_zomb)
	orc_zomb.connect('enemy_death', _on_orc_zomb_enemy_death)

func update_enemy_counter ():
	await get_tree().create_timer(0).timeout # waiting for even 0 sec seems to allow for the enemy to be deleted and the count to be correct
	enemy_count = enemies.get_children().size()
	hud.update_enemy_counter(enemy_count)

	if (enemy_count <= 0):
		print('wave_count:', wave_count)
		print('enemy_wave_sequence.size():', enemy_wave_sequence.size())
		if (wave_count + 1 == enemy_wave_sequence.size()):
			print("Show game complete screen!")
		else:
			emit_signal("wave_complete")

func generate_enemy_wave ():
	for i in enemy_wave_sequence[wave_count]:
		spawn_enemy_at(i.x, i.z)

	update_enemy_counter()

func _on_advance_button_pressed():
	wave_count += 1
	generate_enemy_wave ()
