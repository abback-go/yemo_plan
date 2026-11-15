class_name HiddenPlatform
extends StaticBody2D
## 숨은 발판 (지도 문자 H): 평소엔 없고 밟을 수도 없다. 여우창문으로 드러나면 영구히 생긴다.

var key := ""
var rect_px := Rect2()
var _revealed := false
var _shapes: Array[CollisionShape2D] = []
var _t := 0.0


func setup(_room: Room, cells: Array, p_key: String) -> void:
	key = p_key
	collision_layer = GameConst.L_PLATFORM
	collision_mask = 0
	add_to_group(&"illusion")
	var mn := Vector2i(99999, 99999)
	var mx := Vector2i(-1, -1)
	for c in cells:
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	rect_px = Rect2(Vector2(mn) * 16.0, Vector2(mx - mn + Vector2i.ONE) * 16.0)
	for c in cells:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(16, 6)
		cs.shape = rs
		cs.one_way_collision = true
		cs.position = Vector2(c) * 16.0 + Vector2(8, 3)
		add_child(cs)
		_shapes.append(cs)
	_revealed = GameState.has_flag("rev_" + key)
	for s in _shapes:
		s.disabled = not _revealed
	z_index = -1


func is_revealed() -> bool:
	return _revealed


func try_reveal(center: Vector2, radius: float) -> bool:
	if _revealed:
		return false
	var closest := Vector2(clampf(center.x, rect_px.position.x, rect_px.end.x), clampf(center.y, rect_px.position.y, rect_px.end.y))
	if closest.distance_to(center) > radius:
		return false
	_revealed = true
	GameState.set_flag("rev_" + key)
	for s in _shapes:
		s.set_deferred("disabled", false)
	Sfx.play(&"reveal", -2.0, 0.0)
	Fx.burst(rect_px.get_center(), 18, {
		box = Vector2(rect_px.size.x * 0.5, 2), spread = 180.0, speed_min = 10.0, speed_max = 30.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(Color(0.55, 0.85, 1.0)), gravity = Vector2(0, -20), add = true,
	})
	return true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if not _revealed:
		return
	# 푸른 여우불로 된 반투명 발판
	var k := 0.75 + 0.25 * sin(_t * 3.0)
	var r := Rect2(rect_px.position, Vector2(rect_px.size.x, 5))
	draw_rect(r, Color(0.35, 0.65, 1.0, 0.45 * k))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(0.75, 0.92, 1.0, 0.9 * k))
	for i in int(r.size.x / 8.0):
		var x := r.position.x + 4 + i * 8 + sin(_t * 2.0 + i) * 1.5
		draw_rect(Rect2(x, r.position.y + 6 + (i % 2) * 2, 1, 2), Color(0.55, 0.85, 1.0, 0.5 * k))
