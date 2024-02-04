extends Sprite3D

@onready var healthBar : TextureProgressBar = get_node("SubViewport/Background/HealthBar")

func _ready():
	texture = $SubViewport.get_texture()

func update_health_bar (currentHp, maxHp):
	healthBar.value = (100 / maxHp) * currentHp
