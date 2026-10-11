extends Node2D
## 소환 문양: 바닥에 흰 원과 기하학 선이 그려짐 → 하수인 등장
## 흰 전령(white_herald.gd)의 소환진.

var dur := 1.0
var kind := "blight_spore"
var herald: WeakRef
var _t := 0.0
var _done := false


func setup(at: Vector2, p_dur: float, p_kind: String, h: Node) -> void:
	global_position = at
	dur = p_dur
	kind = p_kind
	herald = weakref(h)
	z_index = 3


func _process(delta: float) -> void:
	_t += delta * Fx.enemy_time
	if not _done and _t >= dur:
		_done = true
		var h: Node = herald.get_ref()
		if h and h is WhiteHerald:
			(h as WhiteHerald).add_summon(kind, global_position)
		Ch3Sfx.play(&"ch3_glass", -2.0, 0.2)
		Fx.burst(global_position + Vector2(0, -8), 20, {direction = Vector2.UP, spread = 50.0, speed_min = 40.0, speed_max = 120.0,
			lifetime = 0.5, gradient = Palette.fade_gradient(Color(1, 1, 1)), size_min = 1.0, size_max = 2.5, gravity = Vector2.ZERO, add = true})
	if _t > dur + 0.4:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / dur, 0.0, 1.0)
	var bl := 0.55 + 0.45 * sin(_t * 18.0)
	var al := (1.0 - clampf((_t - dur) / 0.4, 0.0, 1.0))
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.35))
	draw_arc(Vector2.ZERO, 22.0, 0, TAU * k, 32, Color(1, 1, 1, 0.8 * bl * al), 2.0)
	for i in 3:
		var a := _t * 0.8 + TAU * i / 3.0
		draw_line(Vector2(cos(a), sin(a)) * 22.0, Vector2(cos(a + 2.094), sin(a + 2.094)) * 22.0, Color(1, 1, 1, 0.5 * k * al), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
