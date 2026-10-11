extends Node2D
## 프로토타입 스테이지 (docs/archive/sera/prototype.md 7절). 4개 구간 + 체크포인트 + 아레나 + 출구.
## 사망 후 다시 불러오면 마지막 체크포인트에서 시작하고, 지난 구간의 적은 만들지 않는다.

@export var level_size := Vector2(3840, 360)

@onready var player: Player = $Player


func _ready() -> void:
	Fx.reset()
	get_tree().paused = false
	_place_player()
	_prune_cleared_sections()
	var cam := player.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(level_size.x)
	cam.limit_bottom = int(level_size.y)
	cam.reset_smoothing()
	GameState.running = true


func _place_player() -> void:
	for cp in get_tree().get_nodes_in_group(&"checkpoint"):
		if cp.index == GameState.checkpoint_index:
			player.global_position = cp.global_position + Vector2(6, 0)
			player.facing = 1
			return


func _prune_cleared_sections() -> void:
	for s in $Sections.get_children():
		if s is Section and s.index < GameState.checkpoint_index:
			for c in s.get_children():
				if c is EnemyBase or c is SpawnTrigger:
					c.queue_free()


func current_section() -> Section:
	var best: Section = null
	for s in $Sections.get_children():
		if s is Section and player.global_position.x >= s.start_x:
			if best == null or s.start_x > best.start_x:
				best = s
	return best


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameState.restart_from_checkpoint()
	elif event.is_action_pressed("debug"):
		var dbg := get_node_or_null("DebugOverlay") as CanvasLayer
		if dbg:
			dbg.visible = not dbg.visible
