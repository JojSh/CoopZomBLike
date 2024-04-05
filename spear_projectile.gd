extends RigidBody3D

@onready var shapecast = get_node("ShapeCast3D")

const attack_power : int = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shapecast.is_colliding:
		var target = shapecast.get_collider(0)
		if target == null or target == self: return

		if target.has_method("receive_damage"):
			target.receive_damage(attack_power)
