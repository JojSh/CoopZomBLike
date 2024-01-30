extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var facing_angle : float
var facing_vector3 : Vector3
var shove_force : float = 10.0

@onready var weaponAnimation = get_node("Model/WeaponHolder/WeaponAnimator")
@onready var attackRayCast = get_node("Model/AttackRayCast")
@onready var model : MeshInstance3D = get_node("Model")

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
#	if Time.get_ticks_msec() - lastAttackTime < attackRate * 1000: # 1000ms in 1s
#		return
#	lastAttackTime = Time.get_ticks_msec()
#	weaponAnimation.stop()

	weaponAnimation.play("Slash")

	if attackRayCast.is_colliding():
		var target = attackRayCast.get_collider()
		if target.has_method("receive_shove"):
			target.receive_shove(shove_force, facing_vector3)
		if target.has_method("receive_damage"):
			target.receive_damage(1)
