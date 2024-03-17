extends CanvasLayer

@onready var healthBar : TextureProgressBar = get_node("Background/HealthBar")
@onready var enemy_counter : Label = get_node("EnemyCounter")
@onready var fps_display : Label = get_node("FPSDisplay")

func _process (delta):
	update_fps_counter()

func update_health_bar (currentHp, maxHp):
	healthBar.value = (100 / maxHp) * currentHp

func update_enemy_counter (new_count):
	enemy_counter.text = "Enemies: " + str(new_count)

func update_fps_counter ():
	var fps = str(Engine.get_frames_per_second())
	fps_display.text = "FPS: " + str(fps)
