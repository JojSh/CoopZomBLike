extends CharacterBody3D

var health : int = 3
var attackDistance : float = 1.0
var awarenessRadius : float = 5.0
var moveSpeed : float = 2.0
var gravity : float = 15.0
var knockback = Vector3.ZERO

@onready var player = get_node("/root/Main/Player")
@onready var model : MeshInstance3D = get_node("Model")

func _physics_process(delta):
	var distanceToPlayer = position.distance_to(player.position)
	var shouldFollowPlayer = distanceToPlayer < awarenessRadius # && distanceToPlayer > attackDistance

	if shouldFollowPlayer:
		var direction = (player.position - position).normalized()
		
		velocity.x = direction.x * moveSpeed + knockback.y
		velocity.z = direction.z * moveSpeed + knockback.x
		
		var facing_angle = Vector2(direction.z, direction.x).angle()
		model.rotation.y = lerp_angle(model.rotation.y, facing_angle, 0.5)

	# Gravity
	# add downward velocity equal to gravity * time since last _physics_process call
	velocity.y -= gravity * delta

	move_and_slide()
	knockback = lerp(knockback, Vector3.ZERO, 0.1)

func receive_damage (damage):
	health -= damage
	if health <= 0: queue_free()

func receive_shove (force, shove_direction):
	knockback = shove_direction * force
