extends CanvasLayer

@onready var p1_health_bar : TextureProgressBar = get_node("P1HealthBar/HealthBar")
@onready var p2_health_bar : TextureProgressBar = get_node("P2HealthBar/HealthBar")
@onready var enemy_counter : Label = get_node("EnemyCounter")
@onready var fps_display : Label = get_node("FPSDisplay")

func _process (delta):
	pass
	#update_fps_counter() off for now

func update_health_bar (currentHp, maxHp):
	p1_health_bar.value = (100 / maxHp) * currentHp

func update_enemy_counter (new_count):
	enemy_counter.text = "Enemies: " + str(new_count)

func update_fps_counter ():
	var fps = str(Engine.get_frames_per_second())
	fps_display.text = "FPS: " + str(fps)
