extends CharacterBody3D

signal enemy_death

var health_points : int = 3
var max_health : int = 3
var attack_distance : float = 1.0
var awarenessRadius : float = 500.0
var move_speed : float = 3.0 # 0.0
var movement_target_position: Vector3
var gravity : float = 15.0
var knockback = Vector3.ZERO
var attackRate : float = 1.0
var current_position: Vector3
var terminal_depth: float = -10.0
var nearestPlayer

@export var is_dead : bool = false

@onready var timer = get_node("Timer")
@onready var players = get_node("/root/Main/Players").get_children()
@onready var model : MeshInstance3D = get_node("Model")
@onready var weaponAnimation = get_node("Model/WeaponHolder/WeaponAnimator")
@onready var showDamageAnimation = get_node("Model/ShowDamageAnimator")
@onready var attackShapeCast = get_node("Model/AttackShapeCast")
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

	update_nearest_player()
	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func update_nearest_player ():
	#should fetch alive players from GameManager somehow?
	var alive_players = players.filter(func(player):
		return player.is_dead == false
	)

	alive_players.sort_custom(sort_nearest)
	if alive_players:
		nearestPlayer = alive_players[0]

func sort_nearest (a, b):
	if position.distance_to(a.position) < position.distance_to(b.position):
		return true
	return false

func _physics_process(delta):
	if is_dead: return

	die_if_below_terminal_altitude()
	update_nearest_player()
	var distanceToPlayer = position.distance_to(nearestPlayer.position)
	var shouldFollowPlayer = distanceToPlayer < awarenessRadius # && distanceToPlayer > attack_distance

	if shouldFollowPlayer:
		current_position = global_position
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()

		set_movement_target(nearestPlayer.global_position)

		# specifying x and y as we don't want to affect y (vertical)
		velocity.x = current_position.direction_to(next_path_position).x * move_speed
		velocity.z = current_position.direction_to(next_path_position).z * move_speed
		
		# adjust for any knockback
		velocity.x += knockback.y
		velocity.z += knockback.x

		var direction = (next_path_position - position).normalized()
		var facing_angle = Vector2(direction.z, direction.x).angle()

		self.rotation.y = lerp_angle(self.rotation.y, facing_angle, 0.5)

	# Gravity
	# add downward velocity equal to gravity * time since last _physics_process call
	velocity.y -= gravity * delta

	move_and_slide()
	knockback = lerp(knockback, Vector3.ZERO, 0.1)

func die_if_below_terminal_altitude ():
	if (current_position.y <= terminal_depth): die()

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(nearestPlayer.global_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func receive_player_damage (damage):
	if (is_dead): return
	health_points -= damage
	showDamageAnimation.stop()
	showDamageAnimation.play("show_damage")
	$HealthBar3D.update_health_bar(health_points, max_health)

	if health_points <= 0: die()
	
func receive_shove (force, shove_direction):
	knockback = shove_direction * force

func _on_timer_timeout():
	if position.distance_to(nearestPlayer.position) <= attack_distance:
		try_attack() 

func try_attack ():
	weaponAnimation.stop()
	weaponAnimation.play("Slash")
	
	await get_tree().create_timer(0.15).timeout
	if attackShapeCast.is_colliding():
		var nearest_collider_index = attackShapeCast.get_collision_count() - 1
		var target = attackShapeCast.get_collider(nearest_collider_index)
		
		if target == self: return
		if target.has_method("receive_enemy_damage"):
			target.receive_enemy_damage(1, self)

func die ():
	# stop the timer
	timer.stop()

	# switch off the health bar
	$HealthBar3D.hide()
	
	# switch off colliders so dead enemies can be passed over/through
	$CollisionShape3DBox.disabled = true
	$CollisionShape3DCapsule.disabled = true

	showDamageAnimation.play("die")
	is_dead = true
	enemy_death.emit()
