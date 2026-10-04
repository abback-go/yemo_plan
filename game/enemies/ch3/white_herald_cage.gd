extends Node2D
## 기하학 감옥: 꼭짓점 여섯이 차례로 켜지고 변이 이어짐 → 좁아지며 닫힘. 닫힐 때 안에 있으면 1
## 흰 전령(white_herald.gd)의 기하학 감옥.

var center := Vector2.ZERO
var r0 := 48.0
var warn := 1.0
var _t := 0.0
var _hit := false
var _gap := 0
var _rot := 0.0


func setup(c: Vector2, r: float, w: float) -> void:
	center = c
	r0 = r
	warn = w
	global_position = c
	_gap = randi() % 6
	_rot = randf() * TAU
	z_index = 6


func _physics_process(delta: float) -> void:
	_t += delta * Fx.enemy_time
	var close := clampf((_t - warn) / 0.45, 0.0, 1.0)
	if close > 0.0 and not _hit:
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p and p.is_alive():
			var r := r0 * (1.0 - close)
			var d := p.center().distance_to(center)
			# 닫히는 벽이 세라에게 닿음 (안에 갇혀 있었다면)
			if d < r0 * 0.95 and d >= r - 8.0 and not p.is_invincible():
				_hit = true
				p.take_damage(1, &"herald_cage", center.x)
				Ch3Sfx.play(&"ch3_glass", 0.0, 0.1)
	if close >= 1.0 and _t > warn + 0.75:
		queue_free()
	if close >= 1.0 and _t < warn + 0.5:
		Fx.burst(center, 18, {spread = 180.0, speed_min = 30.0, speed_max = 110.0, lifetime = 0.5,
			gradient = Palette.fade_gradient(Color(1, 1, 1)), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})
		_t = warn + 0.5
	queue_redraw()


func _draw() -> void:
	var close := clampf((_t - warn) / 0.45, 0.0, 1.0)
	var r := r0 * (1.0 - close)
	var shown := clampf(_t / (warn * 0.6), 0.0, 1.0) * 6.0
	var blink := 0.55 + 0.45 * sin(_t * (14.0 if close <= 0.0 else 40.0))
	var pts: Array[Vector2] = []
	for i in 6:
		var a := _rot + TAU * i / 6.0 + close * 1.2
		pts.append(Vector2(cos(a), sin(a)) * r)
	for i in 6:
		if float(i) >= shown:
			break
		var p0 := pts[i]
		draw_rect(Rect2(p0 - Vector2(2.5, 2.5), Vector2(5, 5)), Color(1, 1, 1, 0.9 * blink))
		if i == _gap and close <= 0.0:
			continue # 빠져나갈 틈 (변이 없음)
		var p1 := pts[(i + 1) % 6]
		var w := 2.0 if close <= 0.0 else 4.0
		draw_line(p0, p1, Color(1, 1, 1, (0.45 if close <= 0.0 else 0.95) * blink), w)
		draw_line(p0, p1, Color(1, 1, 1, 0.12 * blink), w + 6.0)
	# 안쪽 삼각형 두 개 (기하학)
	if shown >= 6.0:
		for k in 2:
			var tri := PackedVector2Array()
			for j in 4:
				tri.append(pts[(j * 2 + k) % 6] * 0.55)
			draw_polyline(tri, Color(1, 1, 1, 0.25 * blink), 1.0)
