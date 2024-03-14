extends CanvasLayer

@onready var healthBar : TextureProgressBar = get_node("Background/HealthBar")
@onready var enemy_counter : Label = get_node("EnemyCounter")

func update_health_bar (currentHp, maxHp):
	healthBar.value = (100 / maxHp) * currentHp

func update_enemy_counter (new_count):
	enemy_counter.text = "Enemies: " + str(new_count)
