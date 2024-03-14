extends Node3D

@export var enemy_count : int

@onready var OrcZombScene = load("res://OrcZomb.tscn")
@onready var enemies = get_node("Enemies")
@onready var hud = get_node("UI/HUD")

func _ready():
	
	spawn_enemy_at(18, -6)
	spawn_enemy_at(18, 6)
	spawn_enemy_at(-10, 5)
	
	update_enemy_counter()

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

	#if (enemy_count <= 0):
