extends CanvasLayer

@onready var player_health_bars : Node2D = get_node("HealthBars")
@onready var enemy_counter : Label = get_node("EnemyCounter")
@onready var fps_display : Label = get_node("FPSDisplay")

func _process (_delta):
	update_fps_counter() #off for now

func update_health_bar (player_number, currentHp, maxHp):
	var p_num_as_index = player_number - 1
	var bar_to_update = player_health_bars.get_child(p_num_as_index).get_node('HealthBar')
	bar_to_update.value = (100 / maxHp) * currentHp

func update_enemy_counter (new_count):
	enemy_counter.text = "Enemies: " + str(new_count)

func update_fps_counter ():
	var fps = str(Engine.get_frames_per_second())
	fps_display.text = "FPS: " + str(fps)
