extends Control

@onready var healthBar : TextureProgressBar = get_node("Background/HealthBar")

func update_health_bar (currentHp, maxHp):
	healthBar.value = (100 / maxHp) * currentHp
