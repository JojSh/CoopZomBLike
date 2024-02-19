extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_hp : int = 10
var max_hp : int = 10
var facing_angle : float
var facing_vector3 : Vector3
var shove_force : float = 10.0
var attack_power : int = 0
var weapon_equipped : bool = false
var invincible : bool = false


signal game_over

@onready var weaponHolder = get_node("Model/WeaponHolder")
@onready var weaponAnimation = get_node("Model/WeaponHolder/WeaponAnimator")
@onready var shoveAnimation = get_node("Model/ShovingHands/ShoveAnimator")
@onready var showDamageAnimation = get_node("Model/ShowDamageAnimator")
@onready var attackRayCast = get_node("Model/AttackShapeCast")
@onready var model : MeshInstance3D = get_node("Model")
@onready var hud = get_node("/root/Main/UICanvasLayer/HUD")
@onready var knife_model = load("res://knife_model.tscn")
@onready var timer = get_node("InvincibilityTimer")

func _ready():
	hud.update_health_bar(current_hp, max_hp)
	timer.wait_time = 0.45 # see if this can be timer.set_wait_time(attackRate)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle attack
	if Input.is_action_just_pressed("Attack"):
		try_attack()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	if input_dir.length() > 0:
		facing_angle = Vector2(input_dir.y, input_dir.x).angle()
		facing_vector3 = Vector3(input_dir.y, input_dir.x, 0)
		model.rotation.y = lerp_angle(model.rotation.y, facing_angle, 0.5)

func try_attack ():
	if weapon_equipped:
		weaponAnimation.stop()
		weaponAnimation.play("Slash")
	else:
		shoveAnimation.stop()
		shoveAnimation.play("Shove")

	if attackRayCast.is_colliding():
		var target = attackRayCast.get_collider(0)

		if target.has_method("receive_shove"):
			target.receive_shove(shove_force, facing_vector3)

		if weapon_equipped and target.has_method("receive_damage"):
			target.receive_damage(attack_power)

func receive_damage (damage):
	if invincible == true:
		return
	else:
		current_hp -= damage
		showDamageAnimation.stop()
		timer.start()
		invincible = true
		showDamageAnimation.play("show_damage")
		hud.update_health_bar(current_hp, max_hp)

	if current_hp <= 0:
		emit_signal("game_over")
	
func equip_item (item):
	weapon_equipped = true
	weaponHolder.add_child(knife_model.instantiate())
	shove_force = item.shove_force
	attack_power = item.attack_power

func _on_invincibility_timer_timeout():
	invincible = false
