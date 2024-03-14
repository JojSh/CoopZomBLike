extends Control

@onready var target = get_node("/root/Main/Enemies")
@onready var healthBar : TextureProgressBar = get_node("Background/HealthBar")

func update_health_bar (currentHp, maxHp):
	healthBar.value = (100 / maxHp) * currentHp
