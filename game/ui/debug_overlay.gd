extends CanvasLayer
## F1로 켜고 끄는 디버그 표시. 세라의 상태·속도·점프 높이 등 손맛 조정용 수치.

@export var player: Player

var _label: Label


func _ready() -> void:
	layer = 40
	_label = Label.new()
	_label.position = Vector2(12, 48)
	var ls := LabelSettings.new()
	ls.font_size = 12
	ls.font_color = Color(0.8, 1.0, 0.85)
	ls.outline_size = 4
	ls.outline_color = Color.BLACK
	_label.label_settings = ls
	add_child(_label)


func _process(_delta: float) -> void:
	if not visible:
		return
	if player == null:
		player = get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if player == null:
			return
	var t := GameConst.TILE
	_label.text = "FPS %d\nstate %s\nspeed %.1f / %.1f T/s\nfloor %s  air dash %d\nlast jump %.2f T\noverload %.0f\nenemies %d\n[F1] hide  [R] checkpoint" % [
		Engine.get_frames_per_second(),
		Player.State.keys()[player.state],
		player.velocity.x / t,
		player.velocity.y / t,
		player.is_on_floor(),
		player.air_dashes_left,
		player.last_jump_height_t,
		player.overload,
		get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY).size(),
	]
