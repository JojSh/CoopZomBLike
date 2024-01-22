extends CharacterBody3D

var attackDistance : float = 2
var attackRate : float = 1.0
var moveSpeed : float = 2.0
var gravity : float = 15.0

@onready var player = get_node("/root/Main/Player")

func _physics_process(delta):
	var distanceToPlayer = position.distance_to(player.position)

	if distanceToPlayer > attackDistance:
		var direction = (player.position - position).normalized()
		velocity.x = direction.x * moveSpeed
		velocity.z = direction.z * moveSpeed

		# Gravity
		# add downward velocity equal to gravity * time since last _physics_process call
		velocity.y -= gravity * delta

	move_and_slide()
