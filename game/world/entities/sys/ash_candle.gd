extends Node2D
## 재의 서고 촛불: 화염탄으로 켜면 둘레가 밝아지고 ash_trial의 시간이 다시 찬다. last = true면 끝 촛불(done_flag).
## {t = "ash_candle", x, y, last = false}

var lit := false
var last := false
var _t := 0.0
var _hurt: Area2D
var _glow: LightGlow


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 0)
	last = bool(e.get("last", false))
	add_to_group(&"ash_candle")
	z_index = 1
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 20)
	cs.shape = r
	cs.position = Vector2(0, -10)
	_hurt.add_child(cs)
	add_child(_hurt)
	_glow = LightGlow.make(Vector2(0, -18), 90.0, Color(1.0, 0.7, 0.35), 0.0)
	add_child(_glow)


func is_alive() -> bool:
	return true


func take_hit(_hit: Hit) -> void:
	if lit:
		for t in get_tree().get_nodes_in_group(&"ash_trial"):
			t.refill()
		return
	lit = true
	_glow.modulate.a = 1.0
	Sfx.play(&"ignite", -2.0, 0.0)
	Fx.burst(global_position + Vector2(0, -18), 10, {spread = 180.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(Palette.FIRE_HOT), add = true})
	for t in get_tree().get_nodes_in_group(&"ash_trial"):
		t.refill()
		if last:
			GameState.set_flag(t.done_flag)


func extinguish() -> void:
	if last and lit:
		return
	lit = false
	_glow.modulate.a = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-4, -12, 8, 12), Color("#e8dcc0"))
	draw_rect(Rect2(-6, -2, 12, 2), Color("#6a5a4a"))
	if lit:
		var f := sin(_t * 18.0) * 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -12), Vector2(f, -20), Vector2(2, -12)]), Palette.FIRE_OUT)
		draw_circle(Vector2(0, -14), 1.5, Palette.FIRE_HOT)
	else:
		draw_line(Vector2(0, -12), Vector2(0, -14), Color("#3a3030"), 1.0)
