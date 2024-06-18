extends CharacterBody3D

signal enemy_death

var health_points : int
var attack_distance : float = 1.0
var awarenessRadius : float = 500.0
var movement_target_position: Vector3
var gravity : float = 15.0
var knockback = Vector3.ZERO
var attackRate : float = 1.0
var current_position: Vector3
var terminal_depth: float = -10.0
var nearestPlayer
var facing_angle: float = 0.0
var facing_direction: Vector3

@export var is_dead : bool = false
@export var variant: String = "Default"
@export var move_speed : float = 2.0
@export var knockback_force : int = 3
@export var max_health : int = 3
@export var attack_power : int = 1
# e.g more for fast enemies to adjust for their speed. Very small for big enemies.
@export var variant_knockbackableness : float = 1.0

@onready var timer = get_node("Timer")
@onready var players = get_node("/root/Main/Players").get_children()
@onready var models = get_node("Models")
@onready var weaponAnimation = get_node("Models/WeaponHolder/WeaponAnimator")
@onready var attackShapeCast = get_node("Models/AttackShapeCast")
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var default_character_model = get_node("Models/DefaultCharacterModel")
@onready var animation_player = get_node("Models/DefaultCharacterModel/AnimationPlayer")
@onready var show_damage_player = get_node("Models/DefaultCharacterModel/ShowDamageAnimator")

func _ready () :
	health_points = max_health
	set_special_model()
	set_special_size()
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
		
		handle_sprint_animation()
		# specifying x and y as we don't want to affect y (vertical)
		velocity.x = current_position.direction_to(next_path_position).x * move_speed
		velocity.z = current_position.direction_to(next_path_position).z * move_speed
		
		# adjust for any knockback
		velocity.x += knockback.y * variant_knockbackableness # so that faster enemies aren't
		velocity.z += knockback.x * variant_knockbackableness  # more resistant to knockback

		facing_direction = (next_path_position - position).normalized()
		facing_angle = Vector2(facing_direction.z, facing_direction.x).angle()

		self.rotation.y = lerp_angle(self.rotation.y, facing_angle, 0.5)

	# Gravity
	# add downward velocity equal to gravity * time since last _physics_process call
	velocity.y -= gravity * delta

	move_and_slide()
	knockback = lerp(knockback, Vector3.ZERO, 0.1)

func set_special_size ():
	if variant == "Big":
		models.scale = models.scale * 5
		$HealthBar3D.position.y = 3
		$HealthBar3D.position.z = -1

func set_special_model ():
	if variant == "Default": return

	var variant_model_name : String = "CharacterOrc" + variant
	var model_path : String = "res://OrcModelScenes/" + variant_model_name + ".tscn"
	var orc_model_to_use = load(model_path).instantiate()
	default_character_model.queue_free()
	models.add_child(orc_model_to_use)
	#player_model_to_use
	animation_player = get_node("Models/" + variant_model_name + "/AnimationPlayer")
	show_damage_player = get_node("Models/" + variant_model_name + "/ShowDamageAnimator")

func handle_sprint_animation ():
	animation_player.play("walk-rhand-static")

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
	show_damage_player.stop()
	show_damage_player.play("show_damage")
	$ReceiveSlashSFX.play()
	$HealthBar3D.update_health_bar(health_points, max_health)

	if health_points <= 0:
		die()
	
func receive_shove (force, shove_direction):
	$ReceiveShoveSFX.play()
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
			target.receive_enemy_damage(attack_power, self, facing_direction, knockback_force)

func die ():
	# stop the timer
	timer.stop()

	# switch off the health bar
	$HealthBar3D.hide()
	
	# switch off colliders so dead enemies can be passed over/through
	#$CollisionShape3DBox.disabled = true
	$CollisionShape3DCapsule.disabled = true

	$ThudDeathHitSFX.play()
	is_dead = true
	
	# get round some race condition that interrupts "die: animation when falling to death
	await get_tree().create_timer(0.01).timeout
	animation_player.play("die")

	enemy_death.emit()
