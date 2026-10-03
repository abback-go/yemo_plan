class_name CrackedWall
extends StaticBody2D
## 금 간 벽 (docs/chapter1.md 12.6절): 연금 슬라임의 자폭이나 폭주 폭발로만 무너진다(영구).

var key := ""
var size_px := Vector2(32, 48)
var _broken := false


func setup(room: Room, e: Dictionary, eid: String) -> void:
	key = "crack_%s_%s" % [room.data.id, eid]
	size_px = Vector2(float(e.get("w", 2)), float(e.get("h", 3))) * 16.0
	position = room.tile_pos(e)
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	add_to_group(&"cracked_wall")
	if GameState.has_flag(key):
		_broken = true
		return
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size_px
	cs.shape = r
	cs.position = size_px * 0.5
	add_child(cs)
	z_index = -1


func crack_break() -> void:
	if _broken:
		return
	_broken = true
	GameState.set_flag(key)
	GameState.add("secrets")
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	Sfx.play(&"crumble", 0.0, 0.0)
	Fx.shake(0.2, 0.3)
	Fx.burst(global_position + size_px * 0.5, 40, {box = size_px * 0.5, spread = 180.0, speed_min = 30.0, speed_max = 140.0,
		lifetime = 0.9, gravity = Vector2(0, 300), gradient = Palette.fade_gradient(Color("#5a5468")), size_min = 1.5, size_max = 3.5})
	queue_redraw()


func _draw() -> void:
	if _broken:
		return
	var c := Color("#2e2c3e")
	draw_rect(Rect2(Vector2.ZERO, size_px), c)
	for y in int(size_px.y / 8.0):
		draw_rect(Rect2(0, y * 8, size_px.x, 1), c.darkened(0.3))
	# 금
	var pts := PackedVector2Array([Vector2(size_px.x * 0.5, 0), Vector2(size_px.x * 0.35, size_px.y * 0.3), Vector2(size_px.x * 0.6, size_px.y * 0.5), Vector2(size_px.x * 0.4, size_px.y * 0.8), Vector2(size_px.x * 0.55, size_px.y)])
	draw_polyline(pts, Color("#9a90c8"), 1.0)
	draw_line(pts[2], pts[2] + Vector2(size_px.x * 0.3, -6), Color("#9a90c8"), 1.0)
