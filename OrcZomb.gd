extends CharacterBody3D

var health_points : int = 3
var max_health : int = 3
var attack_distance : float = 1.0
var awarenessRadius : float = 500.0
var move_speed : float = 2.0
var movement_target_position: Vector3
var gravity : float = 15.0
var knockback = Vector3.ZERO
var attackRate : float = 1.0

@onready var timer = get_node("Timer")
@onready var player = get_node("/root/Main/Player")
@onready var model : MeshInstance3D = get_node("Model")
@onready var weaponAnimation = get_node("Model/WeaponHolder/WeaponAnimator")
@onready var showDamageAnimation = get_node("Model/ShowDamageAnimator")
@onready var attackRayCast = get_node("Model/AttackRayCast")
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready () :
	#set the timer wait time
	$HealthBar3D.update_health_bar(health_points, max_health)
	timer.wait_time = attackRate # see if this can be timer.set_wait_time(attackRate)
	timer.start()
	
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func _physics_process(delta):
	var distanceToPlayer = position.distance_to(player.position)
	var shouldFollowPlayer = distanceToPlayer < awarenessRadius # && distanceToPlayer > attack_distance

	if shouldFollowPlayer:
		var current_agent_position: Vector3 = global_position
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		
		set_movement_target(player.global_position)

		velocity = current_agent_position.direction_to(next_path_position) * move_speed
		
		var direction = (next_path_position - position).normalized()

		var facing_angle = Vector2(direction.z, direction.x).angle()
		self.rotation.y = lerp_angle(self.rotation.y, facing_angle, 0.5)

	# Gravity
	# add downward velocity equal to gravity * time since last _physics_process call
	velocity.y -= gravity * delta

	move_and_slide()
	knockback = lerp(knockback, Vector3.ZERO, 0.1)

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(player.global_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func receive_damage (damage):
	health_points -= damage
	showDamageAnimation.stop()
	showDamageAnimation.play("show_damage")
	$HealthBar3D.update_health_bar(health_points, max_health)
	if health_points <= 0: queue_free()

func receive_shove (force, shove_direction):
	knockback = shove_direction * force

func _on_timer_timeout():
	if position.distance_to(player.position) <= attack_distance:
		weaponAnimation.stop()
		weaponAnimation.play("Slash")
		player.receive_damage(1)
