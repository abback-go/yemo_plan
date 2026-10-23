class_name BreakableWall
extends StaticBody2D
## 부서지는 나무 벽·거미줄 (지도 문자 W): 불(화염탄 3타·불기둥·화염 폭풍·여우불)로 태우면 사라진다(영구).

var key := ""
var hp := 40
var rect_px := Rect2()
var _sprite: Sprite2D
var _hurt: Area2D
var _flash := 0.0
var _alive := true


func setup(room: Room, cells: Array, p_key: String) -> void:
	key = p_key
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	var mn := Vector2i(99999, 99999)
	var mx := Vector2i(-1, -1)
	for c in cells:
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	var region := Rect2i(mn, mx - mn + Vector2i.ONE)
	rect_px = Rect2(Vector2(region.position) * 16.0, Vector2(region.size) * 16.0)
	if GameState.has_flag("broke_" + key):
		_alive = false
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
	_sprite.texture = ImageTexture.create_from_image(TilePainter.paint(room.data, room.theme, "W", region))
	_sprite.z_index = -2
	add_child(_sprite)
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var hcs := CollisionShape2D.new()
	var hrs := RectangleShape2D.new()
	hrs.size = rect_px.size + Vector2(4, 4)
	hcs.shape = hrs
	hcs.position = rect_px.get_center()
	_hurt.add_child(hcs)
	add_child(_hurt)


func is_alive() -> bool:
	return _alive


func is_on_floor() -> bool:
	return true


func take_hit(hit: Hit) -> void:
	if not _alive:
		return
	hp -= hit.damage
	Fx.burst(rect_px.get_center(), 6, {spread = 180.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Color("#8a5a3a")), gravity = Vector2(0, 200)})
	Sfx.play(&"hit", -6.0)
	if _sprite:
		_sprite.modulate = Color(1.6, 1.2, 1.0)
		create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		_break()


func _break() -> void:
	_alive = false
	GameState.set_flag("broke_" + key)
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	_hurt.set_deferred("monitorable", false)
	Sfx.play(&"explode", -6.0)
	Fx.burst(rect_px.get_center(), 30, {box = rect_px.size * 0.5, spread = 180.0, speed_min = 30.0, speed_max = 120.0,
		lifetime = 0.8, gravity = Vector2(0, 260), gradient = Palette.fade_gradient(Color("#6a4a32")), size_min = 1.5, size_max = 3.0})
	Fx.burst(rect_px.get_center(), 24, {box = rect_px.size * 0.5, direction = Vector2.UP, spread = 40.0, speed_min = 20.0,
		speed_max = 70.0, lifetime = 0.9, gravity = Vector2(0, -40)})
	var t := create_tween()
	t.tween_property(_sprite, "modulate:a", 0.0, 0.3)
