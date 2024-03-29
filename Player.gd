extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const DEFAULT_SHOVE_FORCE = 15.0

signal game_over

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_hp : int = 5
var max_hp : int = 5
var facing_angle : float
var facing_vector3 : Vector3
var shove_force : float = DEFAULT_SHOVE_FORCE
var attack_power : int = 0
var slashing_weapon_equipped : bool = false
var deflector_equipped : bool = false
var invincible : bool = false
var currently_held_collectible_name : String
var terminal_depth: float = -10.0

@export var player_number : int
@export var item_equipped : bool = false
@export var starting_position : Vector3

@onready var weaponModel = get_node("Model/WeaponHolder/Model")
@onready var weaponAnimation = get_node("Model/WeaponHolder/WeaponAnimator")
@onready var shoveAnimation = get_node("Model/ShovingHands/ShoveAnimator")
@onready var showDamageAnimation = get_node("Model/ShowDamageAnimator")
@onready var attackShapeCast = get_node("Model/AttackShapeCast")
@onready var model : MeshInstance3D = get_node("Model")
@onready var main = get_node("/root/Main")
@onready var hud = get_node("/root/Main/UI/HUD")
@onready var timer = get_node("InvincibilityTimer")

func _ready():
	print('current_hp', current_hp)
	print('max_hp', max_hp)
	hud.update_health_bar(player_number, current_hp, max_hp)
	timer.wait_time = 0.45 # see if this can be timer.set_wait_time(attackRate)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		kill_if_below_terminal_altitude()

	# Handle Jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Handle attack
	if Input.is_action_just_pressed(str("p", player_number, "_attack")):
		try_attack()

	# Drop item
	if Input.is_action_just_pressed(str("p", player_number, "_drop_item")):
		drop_item()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector(
		str("p", player_number, "_left"),
		str("p", player_number, "_right"),
		str("p", player_number, "_up"),
		str("p", player_number, "_down")
	)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z *  SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	if input_dir.length() > 0:
		facing_angle = Vector2(input_dir.y, input_dir.x).angle()
		facing_vector3 = Vector3(input_dir.y, input_dir.x, 0)
		model.rotation.y = lerp_angle(model.rotation.y, facing_angle, 0.5)
	
func kill_if_below_terminal_altitude ():
	if (position.y <= terminal_depth):
		emit_signal("game_over")

func try_attack ():
	if slashing_weapon_equipped:
		weaponAnimation.stop()
		weaponAnimation.play("Slash")
	elif deflector_equipped:
		weaponAnimation.stop()
		weaponAnimation.play("ShieldShove")
	else:
		shoveAnimation.stop()
		shoveAnimation.play("Shove")

	if attackShapeCast.is_colliding():
		var nearest_collider_index = attackShapeCast.get_collision_count() - 1
		var target = attackShapeCast.get_collider(nearest_collider_index)
		
		if target == self: return

		if target.has_method("receive_shove"):
			target.receive_shove(shove_force, facing_vector3)

		if slashing_weapon_equipped and target.has_method("receive_damage"):
			target.receive_damage(attack_power)

func receive_damage (damage, attacker):
	if invincible == true:
		return
	elif deflector_equipped and attackShapeCast.is_colliding() and attackShapeCast.get_collider(0) == attacker:
		weaponAnimation.stop()
		weaponAnimation.play("Flash")
	else:
		current_hp -= damage
		showDamageAnimation.stop()
		timer.start()
		invincible = true
		showDamageAnimation.play("show_damage")
		hud.update_health_bar(player_number, current_hp, max_hp)

	if current_hp <= 0:
		emit_signal("game_over")
	
func equip_item (item):
	item_equipped = true
	slashing_weapon_equipped = item.is_slashing_weapon
	deflector_equipped = item.is_deflector

#	place instance of item model in player's hand
	weaponModel.add_child(item.item_model.instantiate())

#	set up weapon's config stats
	shove_force = item.shove_force
	attack_power = item.attack_power

#	store the item's name to make available to drop later
	currently_held_collectible_name = item.item_name

func drop_item ():
	if item_equipped:
		item_equipped = false
		if slashing_weapon_equipped == true:
			slashing_weapon_equipped = false

	#	remove model from weapon holder
		var item_model = weaponModel.get_child(0)
		weaponModel.remove_child(item_model)

	#	reset to default "shove" config
		shove_force = DEFAULT_SHOVE_FORCE
		attack_power = 0

	#	create collectible instance of dropped item in the world
		var currently_held_collectible_scene = load("res://" + currently_held_collectible_name + "_collectible.tscn")
		var dropped_item = currently_held_collectible_scene.instantiate()
		dropped_item.position = Vector3(position.x - facing_vector3.y, 0.5, position.z - facing_vector3.x)
		main.add_child(dropped_item)

func _on_invincibility_timer_timeout():
	invincible = false
	
func restore_hp (healing_power):
	current_hp += healing_power
	if current_hp > max_hp: current_hp = max_hp
	hud.update_health_bar(current_hp, max_hp)

func reset_position ():
	position = starting_position
