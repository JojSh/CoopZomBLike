extends Area3D

@export var item_name : String = "shield"
@export var attack_power : float = 0.0
@export var shove_force : float = 10.0
@export var is_slashing_weapon : bool = false
@export var is_deflector : bool = true
@export var item_model = load("res://shield_model.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_rotation.y += 1 * delta

func _on_body_entered(body):
	if body.has_method("equip_item") and not body.item_equipped:
		body.equip_item(self)
		queue_free()
