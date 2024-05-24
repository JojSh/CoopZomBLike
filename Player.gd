extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const DEFAULT_SHOVE_FORCE = 15.0
const DEFAULT_THROW_FORCE = 20.0

signal player_death
signal create_collectible
signal create_projectile

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_hp : int = 100
var max_hp : int = 100
var facing_angle : float
var facing_vector3 : Vector3
var shove_force : float = DEFAULT_SHOVE_FORCE
var attack_power : int = 0
var slashing_weapon_equipped : bool = false
var throwing_weapon_equipped : bool = false
var deflector_equipped : bool = false
var invincible : bool = false
var currently_held_collectible_name : String
var terminal_depth: float = -10.0

@export var is_dead : bool = false
@export var player_number : int
@export var item_equipped : bool = false
@export var starting_position : Vector3

@onready var weaponModel = get_node("Models/WeaponHolder/Model")
@onready var weaponAnimation = get_node("Models/WeaponHolder/WeaponAnimator")
@onready var shoveAnimation = get_node("Models/ShovingHands/ShoveAnimator")
@onready var animation_player: AnimationPlayer
@onready var show_damage_player: AnimationPlayer
@onready var attackShapeCast = get_node("Models/AttackShapeCast")
@onready var dummy_character_model = get_node("Models/DummyCharacterModel")
@onready var models : Node3D = get_node("Models")
@onready var main = get_node("/root/Main")
@onready var hud = get_node("/root/Main/UI/HUD")
@onready var invincibility_timer = get_node("InvincibilityTimer")
@onready var visibility_notifier = get_node("VisibleOnScreenNotifier3D")
@onready var footsteps_sfx = get_node("FootstepsSFX")
@onready var shove_sfx = get_node("ShoveSFX")

func _ready():
	set_colour_by_player_number()
	hud.update_health_bar(player_number, current_hp, max_hp)
	invincibility_timer.wait_time = 0.45 # see if this can be invincibility_timer.set_wait_time(attackRate)

func _physics_process(delta):
	# Add the gravity.
	if not is_dead:
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
			if item_equipped:
				unequip_item()
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
			handle_sprint_animation()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z *  SPEED
		else:
			#footsteps_sfx.stop()
			footsteps_sfx.play()
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		move_and_slide()
		update_debug_info()

		if input_dir.length() > 0:
			facing_angle = Vector2(input_dir.y, input_dir.x).angle()
			facing_vector3 = Vector3(input_dir.y, input_dir.x, 0)
			models.rotation.y = lerp_angle(models.rotation.y, facing_angle, 0.5)

func update_debug_info ():
	hud.update_player_debug_info(player_number, " on screen:", visibility_notifier.is_on_screen())

func handle_sprint_animation ():
	if (slashing_weapon_equipped or throwing_weapon_equipped or deflector_equipped):
		animation_player.play("sprint_rhand_static")
	else:
		animation_player.play("sprint")

func set_colour_by_player_number ():
	var model_name : String = "CharacterHumanP" + str(player_number)
	var model_path : String = "res://NumberedPlayerGLBs/" + model_name + ".tscn"
	var player_model_to_use = load(model_path).instantiate()
	dummy_character_model.queue_free()
	models.add_child(player_model_to_use)
	player_model_to_use
	animation_player = get_node("Models/" + model_name + "/AnimationPlayer")
	show_damage_player = get_node("Models/" + model_name + "/ShowDamagePlayer")

func kill_if_below_terminal_altitude ():
	if (position.y <= terminal_depth):
		current_hp = 0
		hud.update_health_bar(player_number, current_hp, max_hp)
		die()

func try_attack ():
	if slashing_weapon_equipped:
		weaponAnimation.stop()
		weaponAnimation.play("Slash")
	elif throwing_weapon_equipped:
		weaponAnimation.stop()
		throw_item()
	elif deflector_equipped:
		weaponAnimation.stop()
		weaponAnimation.play("ShieldShove")
	else:
		# default shove
		shove_sfx.play()
		animation_player.play("holding-both-shoot")
		

	if attackShapeCast.is_colliding():
		var nearest_collider_index = attackShapeCast.get_collision_count() - 1
		var target = attackShapeCast.get_collider(nearest_collider_index)
		
		if target == self: return

		if target.has_method("receive_shove"):
			target.receive_shove(shove_force, facing_vector3)

		if slashing_weapon_equipped and target.has_method("receive_player_damage"):
			target.receive_player_damage(attack_power)

func receive_enemy_damage (damage, attacker):
	if is_dead or invincible == true:
		return
	elif deflector_equipped and attackShapeCast.is_colliding() and attackShapeCast.get_collider(0) == attacker:
		weaponAnimation.stop()
		weaponAnimation.play("Flash")
		$ShieldClangSFX.play()
	else:
		$ReceiveWhackSFX.play()
		current_hp -= damage
		invincibility_timer.start()
		invincible = true
		show_damage_player.play("show_damage")
		hud.update_health_bar(player_number, current_hp, max_hp)

	if current_hp <= 0:
		die()

func die ():
	$ThudDeathHitSFX.play()
	invincibility_timer.stop()
	animation_player.stop()
	animation_player.play("die")
	player_death.emit()
	is_dead = true

func equip_item (item):
	item_equipped = true
	slashing_weapon_equipped = item.is_slashing_weapon
	throwing_weapon_equipped = item.is_throwing_weapon
	deflector_equipped = item.is_deflector
	
#	place instance of item model in player's hand
	weaponModel.add_child(item.item_model.instantiate())

#	set up weapon's config stats
	shove_force = item.shove_force
	attack_power = item.attack_power

#	store the item's name to make available to drop later
	currently_held_collectible_name = item.item_name

func throw_item ():
	unequip_item()

	var projectile_location = Vector3(position.x + facing_vector3.y, 0.3, position.z + facing_vector3.x)
	var impulse = Vector3(facing_vector3.y * DEFAULT_THROW_FORCE, 0, facing_vector3.x * DEFAULT_THROW_FORCE)
	create_projectile.emit("spear", projectile_location, facing_angle, impulse)

func unequip_item ():
	item_equipped = false
	if slashing_weapon_equipped == true:
		slashing_weapon_equipped = false

	if throwing_weapon_equipped == true:
		throwing_weapon_equipped = false

	if deflector_equipped == true:
		deflector_equipped = false

#	remove model from weapon holder
	var item_model = weaponModel.get_child(0)
	weaponModel.remove_child(item_model)

#	reset to default "shove" config
	shove_force = DEFAULT_SHOVE_FORCE
	attack_power = 0

func drop_item ():
	var location = Vector2(position.x - facing_vector3.y, position.z - facing_vector3.x)
	create_collectible.emit(currently_held_collectible_name, location)

func _on_invincibility_timer_timeout():
	invincible = false

func restore_hp (healing_power):
	current_hp += healing_power
	if current_hp > max_hp: current_hp = max_hp
	hud.update_health_bar(player_number, current_hp, max_hp)

func reset_position ():
	position = starting_position

func revive ():
	is_dead = false
	invincible = false
	animation_player.stop()
	animation_player.play("RESET")
	restore_hp(2)
