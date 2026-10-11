class_name FlagGate
extends StaticBody2D
## 플래그가 서면 열리는 막힘 (창살·마법 결계·잔해). open_if 조건이 맞으면 처음부터 열려 있다.
## look: bars(철창살) · barrier(보라 결계) · rubble(잔해) · seal(봉인 문양)

var open_if := ""
var look := "bars"
var size_px := Vector2(16, 64)
var _open := false
var _anim := 0.0
var _t := 0.0
var _shape: CollisionShape2D


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	open_if = String(e.get("open_if", ""))
	look = String(e.get("look", "bars"))
	size_px = Vector2(float(e.get("w", 1)), float(e.get("h", 4))) * 16.0
	position = room.tile_pos(e)
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size_px
	_shape.shape = rs
	_shape.position = size_px * 0.5
	add_child(_shape)
	z_index = -1
	if RoomData.cond_ok(open_if):
		_open = true
		_anim = 1.0
		_shape.disabled = true
	GameState.flag_changed.connect(_on_flag)


func _on_flag(_k: String) -> void:
	var ok := RoomData.cond_ok(open_if)
	if not _open and ok:
		open()
	elif _open and not ok:
		close()


func close() -> void:
	_open = false
	_shape.set_deferred("disabled", false)
	Sfx.play(&"door", 0.0, 0.0)
	var t := create_tween()
	t.tween_property(self, "_anim", 0.0, 0.25)


func open() -> void:
	_open = true
	_shape.set_deferred("disabled", true)
	Sfx.play(&"door", 0.0, 0.0)
	Fx.shake(0.1, 0.3)
	var t := create_tween()
	t.tween_property(self, "_anim", 1.0, 0.8)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if _anim >= 1.0:
		return
	var a := 1.0 - _anim
	match look:
		"bars":
			var h := size_px.y * a
			draw_rect(Rect2(0, 0, size_px.x, 3), Color("#5a5a6a"))
			var n := maxi(int(size_px.x / 5.0), 2)
			for i in n:
				draw_rect(Rect2(1 + i * (size_px.x - 3) / (n - 1), 0, 2, h), Color("#4a4a58"))
				draw_rect(Rect2(1 + i * (size_px.x - 3) / (n - 1), h - 4, 2, 4), Color("#7a7a8a"))
		"barrier", "seal":
			var col := Color(0.7, 0.45, 1.0) if look == "seal" else Color(0.55, 0.6, 1.0)
			draw_rect(Rect2(Vector2.ZERO, size_px), Color(col, 0.18 * a))
			for i in int(size_px.y / 8.0):
				var y := fmod(i * 8.0 + _t * 20.0, size_px.y)
				draw_line(Vector2(0, y), Vector2(size_px.x, y), Color(col, 0.35 * a), 1.0)
			draw_rect(Rect2(0, 0, 2, size_px.y), Color(col, 0.8 * a))
			draw_rect(Rect2(size_px.x - 2, 0, 2, size_px.y), Color(col, 0.8 * a))
		"rubble":
			for i in int(size_px.y / 8.0):
				draw_rect(Rect2(2 + (i % 2) * 3, size_px.y - (i + 1) * 8 * a, size_px.x - 4, 7), Color("#4a4458").darkened(i * 0.05))
