extends CanvasLayer
## 화면 왼쪽 위에 세라의 상태와 속도를 표시한다. 손맛 조정용.

@export var player: Player

@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	if player == null:
		return
	var t := GameConst.TILE
	_label.text = "FPS %d\nstate %s\nspeed x %.1f T/s  y %.1f T/s\nfloor %s  air dash %d  invincible %s\nlast jump %.2f T\n[R] restart" % [
		Engine.get_frames_per_second(),
		Player.State.keys()[player.state],
		player.velocity.x / t,
		player.velocity.y / t,
		player.is_on_floor(),
		player.air_dashes_left,
		player.is_invincible,
		player.last_jump_height_t,
	]
