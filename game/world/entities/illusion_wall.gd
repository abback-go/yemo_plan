class_name IllusionWall
extends StaticBody2D
## 환영 벽 (지도 문자 I): 진짜 벽처럼 보이고 막지만, 여우창문 안에 들어오면 정체가 드러나 사라진다(영구).

var key := ""
var rect_px := Rect2()
var _sprite: Sprite2D
var _revealed := false


func setup(room: Room, cells: Array, p_key: String) -> void:
	key = p_key
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	add_to_group(&"illusion")
	var mn := Vector2i(99999, 99999)
	var mx := Vector2i(-1, -1)
	for c in cells:
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	var region := Rect2i(mn, mx - mn + Vector2i.ONE)
	rect_px = Rect2(Vector2(region.position) * 16.0, Vector2(region.size) * 16.0)
	if GameState.has_flag("rev_" + key):
		_revealed = true
		return
	for c in cells:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(16, 16)
		cs.shape = rs
		cs.position = Vector2(c) * 16.0 + Vector2(8, 8)
		add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.position = rect_px.position
	_sprite.texture = ImageTexture.create_from_image(TilePainter.paint(room.data, room.theme, "I", region))
	_sprite.z_index = -2
	add_child(_sprite)


func is_revealed() -> bool:
	return _revealed


## 여우창문 원과 겹치면 드러남
func try_reveal(center: Vector2, radius: float) -> bool:
	if _revealed:
		return false
	var closest := Vector2(clampf(center.x, rect_px.position.x, rect_px.end.x), clampf(center.y, rect_px.position.y, rect_px.end.y))
	if closest.distance_to(center) > radius:
		return false
	_revealed = true
	GameState.set_flag("rev_" + key)
	GameState.add("secrets")
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	Sfx.play(&"reveal", 0.0, 0.0)
	Fx.burst(rect_px.get_center(), 30, {
		box = rect_px.size * 0.5, spread = 180.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.9,
		gradient = Palette.fade_gradient(Color(0.55, 0.85, 1.0)), gravity = Vector2(0, -30), add = true,
	})
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color(0.6, 0.9, 1.4, 0.0), 0.8)
	return true
