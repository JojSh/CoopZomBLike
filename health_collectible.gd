extends Area3D

@export var item_name : String = "health"
@export var healing_power : int = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_rotation.y += 1 * delta

func _on_body_entered(body):
	if body.has_method("restore_hp"):
		body.restore_hp(healing_power)
		queue_free()
