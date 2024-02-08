extends Area3D

@export var item_name : String = "Knife"
@export var attack_power : float = 1.0
@export var shove_force : float = 5.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_rotation.y += 1 * delta

func _on_body_entered(body):
	if body.has_method("equip_item"):
		body.equip_item(self)
		queue_free()
