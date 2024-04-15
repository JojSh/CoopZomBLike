extends RigidBody3D

signal create_collectible

@onready var shapecast = get_node("ShapeCast3D")

const attack_power : int = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (sleeping):
		var current_position = Vector2(position.x, position.z)
		create_collectible.emit("spear", current_position)
		queue_free()
		
	if shapecast.is_colliding() == true:
		var target = shapecast.get_collider(0)
		if target == null or target == self: return

		if target.has_method("receive_player_damage"):
			target.receive_player_damage(attack_power)
			var target_position = Vector2(target.position.x, target.position.z)
			create_collectible.emit("spear", target_position)
			queue_free()
