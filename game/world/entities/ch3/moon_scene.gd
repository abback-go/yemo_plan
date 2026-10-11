class_name Ch3MoonScene
extends CanvasLayer
## 3장 끝 장면 (docs/archive/sera/chapter3.md 2절 9번·12절): 학교 위 높은 초승달 — 달의 굽이에 걸터앉은 그림자가 학교를 내려다본다.
## 커다란 초승달 모자, 바람에 길게 날리는 머리, 둘레를 천천히 도는 작은 별 일곱(별의 마녀의 표지).
## 마지막에 그림자의 눈이 보랏빛으로 한 번 반짝인다. 대사는 없다(4장 끝에서 정체가 드러남).
##   await Ch3MoonScene.play(world, 6.5)

var _t := 0.0
var _a := 0.0
var _draw_node: Control


static func play(parent: Node, sec := 6.5) -> void:
	var s := Ch3MoonScene.new()
	parent.add_child(s)
	await s._run(sec)


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw_node = Control.new()
	_draw_node.size = Vector2(640, 360)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.draw.connect(_paint)
	add_child(_draw_node)


func _run(sec: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_a", 1.0, 1.2)
	tw.tween_interval(maxf(sec - 2.4, 0.5))
	tw.tween_property(self, "_a", 0.0, 1.2)
	await tw.finished
	queue_free()


func _process(delta: float) -> void:
	_t += delta
	_draw_node.queue_redraw()


func _paint() -> void:
	var c := _draw_node
	var a := _a
	if a <= 0.0:
		return
	# 하늘
	var top := Color("#04040c")
	var bot := Color("#141434")
	for i in 18:
		var y := i * 20.0
		c.draw_rect(Rect2(0, y, 640, 21), Color(top.lerp(bot, i / 17.0), a))
	# 별
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 90:
		var p := Vector2(rng.randf_range(0, 640), rng.randf_range(0, 250))
		var tw := 0.4 + 0.6 * absf(sin(_t * rng.randf_range(0.6, 2.2) + i))
		c.draw_rect(Rect2(p, Vector2.ONE * (2.0 if i % 13 == 0 else 1.0)), Color(0.85, 0.85, 1.0, a * tw * 0.8))
	# 초승달 (천천히 내려옴) — 둥근 달에서 오른쪽 위로 비켜 난 원을 파낸 모양
	var drift := (1.0 - clampf(_t / 6.0, 0.0, 1.0)) * 12.0
	var mc := Vector2(440, 150 - drift)
	var mr := 74.0
	for i in 6:
		c.draw_circle(mc, mr + 40.0 - i * 6.0, Color(0.9, 0.88, 0.7, a * 0.03 * (i + 1)))
	var c2 := mc + Vector2(28, -22)
	c.draw_colored_polygon(_crescent(mc, mr, c2, 64.0, 40), Color(Color("#f2ecd2"), a))
	for cr in [[Vector2(-46, 10), 9.0], [Vector2(-30, 40), 7.0], [Vector2(-52, -22), 6.0], [Vector2(-14, 58), 5.0]]:
		c.draw_circle(mc + cr[0], cr[1], Color(Color("#e0d8b8"), a))
	# 그림자: 초승달 아래쪽 안쪽 굽이에 걸터앉아, 왼쪽 아래(학교)를 내려다본다. 오른쪽 위 가장자리에 달빛 테두리
	var seat := mc + Vector2(4, 38)
	var ink := Color(0.03, 0.03, 0.08, a)
	var rim := Color(1.0, 0.93, 0.7, a * 0.6)
	var sw := sin(_t * 1.3) * 1.5
	var head := seat + Vector2(-6, -25)
	var hb := head + Vector2(1, -4)
	var hair := PackedVector2Array()
	for k in 11:
		var f := float(k) / 10.0
		hair.append(head + Vector2(5.0 + f * 40.0 + sin(_t * 1.6 + f * 4.0) * 4.0 * f, -2.0 + f * 30.0 - f * f * 8.0))
	for k in range(9, -1, -1):
		var f := float(k) / 10.0
		var o := head + Vector2(5.0 + f * 40.0 + sin(_t * 1.6 + f * 4.0) * 4.0 * f, -2.0 + f * 30.0 - f * f * 8.0)
		hair.append(o + Vector2(-3.0, 6.0) * (1.0 - f * 0.85))
	var tip := Geometry2D.convex_hull(PackedVector2Array([hb + Vector2(-5, -5), hb + Vector2(5, -6), hb + Vector2(9, -18), hb + Vector2(18, -28),
		hb + Vector2(26, -25), hb + Vector2(21, -21), hb + Vector2(12, -16)]))
	var figure := func(off: Vector2, col: Color) -> void:
		# 다리: 초승달 앞면으로 늘어뜨림 (무릎 굽힘, 한쪽이 흔들)
		c.draw_line(seat + off + Vector2(-3, 0), seat + off + Vector2(-10, 6), col, 3.5)
		c.draw_line(seat + off + Vector2(-10, 6), seat + off + Vector2(-9 + sw, 19), col, 3.0)
		c.draw_line(seat + off + Vector2(2, 1), seat + off + Vector2(-5, 8), col, 3.5)
		c.draw_line(seat + off + Vector2(-5, 8), seat + off + Vector2(-3 - sw, 20), col, 3.0)
		# 드레스 로브 (몸을 앞으로 숙임) + 무릎 위 팔
		var robe := PackedVector2Array([Vector2(-9, 3), Vector2(14, 5), Vector2(7, -6), Vector2(0, -20), Vector2(-8, -19)])
		for i in robe.size():
			robe[i] += seat + off
		c.draw_colored_polygon(robe, col)
		c.draw_line(seat + off + Vector2(-6, -16), seat + off + Vector2(-12, 1), col, 2.5)
		c.draw_circle(head + off, 6.0, col)
		var hh := hair.duplicate()
		for i in hh.size():
			hh[i] += off
		c.draw_colored_polygon(hh, col)
		c.draw_colored_polygon(PackedVector2Array([hb + off + Vector2(-18, 3), hb + off + Vector2(15, -2), hb + off + Vector2(5, -6), hb + off + Vector2(-5, -5)]), col)
		var tt := tip.duplicate()
		for i in tt.size():
			tt[i] += off
		c.draw_colored_polygon(tt, col)
	figure.call(Vector2(1, -1), rim)
	figure.call(Vector2.ZERO, ink)
	for k in 7:
		var f := float(k + 2) / 9.0
		var hp := head + Vector2(3.0 + f * 40.0 + sin(_t * 1.6 + f * 4.0) * 4.0 * f, 1.0 + f * 30.0 - f * f * 8.0)
		c.draw_rect(Rect2(hp, Vector2(1, 1)), Color(0.9, 0.9, 1.0, a * (0.4 + 0.45 * sin(_t * 3.0 + k * 1.7))))
	var star := hb + Vector2(27, -18 + sin(_t * 2.0) * 1.5)
	c.draw_line(hb + Vector2(25, -25), star, Color(0.6, 0.6, 0.8, a * 0.6), 1.0)
	_star(c, star, 3.0, Color(1.0, 0.95, 0.7, a))
	# 둘레를 도는 작은 별 일곱
	for i in 7:
		var ang := _t * 0.5 + TAU * i / 7.0
		var sp := seat + Vector2(0, -14) + Vector2(cos(ang) * 36.0, sin(ang) * 12.0)
		var front := sin(ang) > 0.0
		_star(c, sp, 1.6 if front else 1.1, Color(0.85, 0.82, 1.0, a * (0.9 if front else 0.45)))
	# 눈 — 마지막에 보랏빛으로 한 번 (학교 쪽을 봄)
	var glint := clampf((_t - 3.6) / 0.4, 0.0, 1.0) * clampf((5.2 - _t) / 0.6, 0.0, 1.0)
	if glint > 0.0:
		c.draw_circle(head + Vector2(-4, 1), 1.3, Color(0.75, 0.55, 1.0, a * glint))
		c.draw_circle(head + Vector2(-4, 1), 4.0 * glint, Color(0.7, 0.5, 1.0, a * glint * 0.25))
	# 학교 실루엣 (아래)
	var sch := Color(0.02, 0.02, 0.05, a)
	c.draw_rect(Rect2(0, 300, 640, 60), sch)
	for b in [[60, 250, 70], [150, 230, 40], [210, 200, 30], [260, 240, 120], [400, 260, 90], [520, 236, 50]]:
		c.draw_rect(Rect2(b[0], b[1], b[2], 300 - b[1] + 1), sch)
	c.draw_colored_polygon(PackedVector2Array([Vector2(205, 200), Vector2(225, 160), Vector2(245, 200)]), sch)
	c.draw_rect(Rect2(218, 176, 14, 14), Color(0.9, 0.8, 0.5, a * 0.35))
	for w in [[80, 270], [100, 270], [290, 262], [330, 262], [370, 262], [430, 280], [540, 256]]:
		c.draw_rect(Rect2(w[0], w[1], 4, 6), Color(1.0, 0.8, 0.45, a * (0.5 + 0.2 * sin(_t * 2.0 + w[0]))))


## 초승달 다각형: 원(c1, r1)에서 원(c2, r2)를 파낸 모양의 경계 (바깥 호 → 안쪽 호)
func _crescent(c1: Vector2, r1: float, c2: Vector2, r2: float, n: int) -> PackedVector2Array:
	var d := c1.distance_to(c2)
	var u := (c2 - c1) / d
	var aa := (r1 * r1 - r2 * r2 + d * d) / (2.0 * d)
	var hh := sqrt(maxf(r1 * r1 - aa * aa, 0.0))
	var p := c1 + u * aa
	var i1 := p + Vector2(-u.y, u.x) * hh
	var back := (-u).angle()
	var dout := acos(clampf((i1 - c1).normalized().dot(-u), -1.0, 1.0))
	var din := acos(clampf((i1 - c2).normalized().dot(-u), -1.0, 1.0))
	var out := PackedVector2Array()
	for k in n + 1:
		var t := back + lerpf(-dout, dout, float(k) / n)
		out.append(c1 + Vector2(cos(t), sin(t)) * r1)
	for k in range(n - 1, 0, -1):
		var t := back + lerpf(-din, din, float(k) / n)
		out.append(c2 + Vector2(cos(t), sin(t)) * r2)
	return out


func _star(c: Control, p: Vector2, r: float, col: Color) -> void:
	c.draw_line(p + Vector2(-r * 1.8, 0), p + Vector2(r * 1.8, 0), col, 1.0)
	c.draw_line(p + Vector2(0, -r * 1.8), p + Vector2(0, r * 1.8), col, 1.0)
	c.draw_circle(p, r * 0.7, col)
