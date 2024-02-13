extends CharacterBody3D

var health_points : int = 3
var max_health : int = 3
var attackDistance : float = 1.0
var awarenessRadius : float = 5.0
var moveSpeed : float = 2.0
var gravity : float = 15.0
var knockback = Vector3.ZERO
var attackRate : float = 1.0

@onready var timer = get_node("Timer")
@onready var player = get_node("/root/Main/Player")
@onready var model : MeshInstance3D = get_node("Model")
@onready var weaponAnimation = get_node("Model/WeaponHolder/WeaponAnimator")
@onready var showDamageAnimation = get_node("Model/ShowDamageAnimator")
@onready var attackRayCast = get_node("Model/AttackRayCast")

func _ready () :
	#set the timer wait time
	$HealthBar3D.update_health_bar(health_points, max_health)
	timer.wait_time = attackRate # see if this can be timer.set_wait_time(attackRate)
	timer.start()

func _physics_process(delta):
	var distanceToPlayer = position.distance_to(player.position)
	var shouldFollowPlayer = distanceToPlayer < awarenessRadius # && distanceToPlayer > attackDistance

	if shouldFollowPlayer:
		var direction = (player.position - position).normalized()
		
		velocity.x = direction.x * moveSpeed + knockback.y
		velocity.z = direction.z * moveSpeed + knockback.x
		
		var facing_angle = Vector2(direction.z, direction.x).angle()
		self.rotation.y = lerp_angle(self.rotation.y, facing_angle, 0.5)

	# Gravity
	# add downward velocity equal to gravity * time since last _physics_process call
	velocity.y -= gravity * delta

	move_and_slide()
	knockback = lerp(knockback, Vector3.ZERO, 0.1)

func receive_damage (damage):
	health_points -= damage
	showDamageAnimation.stop()
	showDamageAnimation.play("show_damage")
	$HealthBar3D.update_health_bar(health_points, max_health)
	if health_points <= 0: queue_free()

func receive_shove (force, shove_direction):
	knockback = shove_direction * force

func _on_timer_timeout():
	if position.distance_to(player.position) <= attackDistance:
		weaponAnimation.stop()
		weaponAnimation.play("Slash")
		player.receive_damage(1)
