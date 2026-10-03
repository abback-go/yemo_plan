class_name Ch3MoonScene
extends CanvasLayer
## 3장 끝 장면 (docs/chapter3.md 2절 9번·12절): 학교 위 높은 달 — 달 가장자리에 걸터앉은 그림자가 학교를 내려다본다.
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
	# 달 (천천히 내려옴)
	var drift := (1.0 - clampf(_t / 6.0, 0.0, 1.0)) * 12.0
	var mc := Vector2(430, 120 - drift)
	var mr := 74.0
	for i in 6:
		c.draw_circle(mc, mr + 40.0 - i * 6.0, Color(0.9, 0.88, 0.7, a * 0.03 * (i + 1)))
	c.draw_circle(mc, mr, Color(Color("#f2ecd2"), a))
	c.draw_circle(mc + Vector2(-18, -14), 14.0, Color(Color("#e0d8b8"), a))
	c.draw_circle(mc + Vector2(22, 18), 20.0, Color(Color("#e4dcbc"), a))
	c.draw_circle(mc + Vector2(-26, 30), 9.0, Color(Color("#ddd4b2"), a))
	c.draw_circle(mc + Vector2(30, -30), 7.0, Color(Color("#e2dab8"), a))
	# 그림자: 달 왼쪽 아래 가장자리에 걸터앉음
	var base := mc + Vector2(-50, 52)
	var ink := Color(0.03, 0.03, 0.08, a)
	# 다리 (달 아래로 늘어뜨림, 살짝 흔들)
	var sw := sin(_t * 1.3) * 2.0
	c.draw_line(base + Vector2(-2, 0), base + Vector2(-8 + sw, 26), ink, 4.0)
	c.draw_line(base + Vector2(4, 0), base + Vector2(2 - sw, 24), ink, 4.0)
	# 로브 몸
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-10, 2), base + Vector2(12, 2), base + Vector2(6, -26), base + Vector2(-4, -28)]), ink)
	# 머리
	var head := base + Vector2(1, -34)
	c.draw_circle(head, 7.0, ink)
	# 긴 머리 (바람에 왼쪽으로 길게 — 끝에 달빛이 비침)
	var hair := PackedVector2Array([head + Vector2(-5, -2)])
	for k in 9:
		var f := float(k + 1) / 9.0
		hair.append(head + Vector2(-8 - f * 70.0, 4 + f * 30.0 + sin(_t * 1.6 + f * 4.0) * 5.0 * f))
	for k in range(8, -1, -1):
		var f := float(k + 1) / 9.0
		hair.append(head + Vector2(-6 - f * 66.0, 10 + f * 34.0 + sin(_t * 1.6 + f * 4.0 + 0.4) * 5.0 * f))
	c.draw_colored_polygon(hair, ink)
	for k in 6:
		var f := float(k + 2) / 8.0
		var hp := head + Vector2(-8 - f * 66.0, 8 + f * 32.0 + sin(_t * 1.6 + f * 4.0) * 5.0 * f)
		c.draw_rect(Rect2(hp, Vector2(1, 1)), Color(0.85, 0.85, 1.0, a * (0.4 + 0.4 * sin(_t * 3.0 + k))))
	# 커다란 초승달 모자 (끝이 말려 별이 매달림)
	var hb := head + Vector2(0, -4)
	c.draw_colored_polygon(PackedVector2Array([hb + Vector2(-16, 2), hb + Vector2(16, 2), hb + Vector2(4, -6), hb + Vector2(-4, -6)]), ink)
	var tip := PackedVector2Array([hb + Vector2(-5, -5), hb + Vector2(5, -5), hb + Vector2(10, -20), hb + Vector2(20, -30), hb + Vector2(26, -26),
		hb + Vector2(22, -22), hb + Vector2(12, -18)])
	c.draw_colored_polygon(Geometry2D.convex_hull(tip), ink)
	var star := hb + Vector2(27, -20 + sin(_t * 2.0) * 1.5)
	c.draw_line(hb + Vector2(25, -26), star, Color(0.6, 0.6, 0.8, a * 0.6), 1.0)
	_star(c, star, 3.0, Color(1.0, 0.95, 0.7, a))
	# 둘레를 도는 작은 별 일곱
	for i in 7:
		var ang := _t * 0.5 + TAU * i / 7.0
		var sp := base + Vector2(0, -20) + Vector2(cos(ang) * 34.0, sin(ang) * 12.0)
		var front := sin(ang) > 0.0
		_star(c, sp, 1.6 if front else 1.1, Color(0.85, 0.82, 1.0, a * (0.9 if front else 0.45)))
	# 눈 — 마지막에 보랏빛으로 한 번
	var glint := clampf((_t - 3.6) / 0.4, 0.0, 1.0) * clampf((5.2 - _t) / 0.6, 0.0, 1.0)
	if glint > 0.0:
		c.draw_circle(head + Vector2(3, 0), 1.3, Color(0.75, 0.55, 1.0, a * glint))
		c.draw_circle(head + Vector2(3, 0), 4.0 * glint, Color(0.7, 0.5, 1.0, a * glint * 0.25))
	# 학교 실루엣 (아래)
	var sch := Color(0.02, 0.02, 0.05, a)
	c.draw_rect(Rect2(0, 300, 640, 60), sch)
	for b in [[60, 250, 70], [150, 230, 40], [210, 200, 30], [260, 240, 120], [400, 260, 90], [520, 236, 50]]:
		c.draw_rect(Rect2(b[0], b[1], b[2], 300 - b[1] + 1), sch)
	c.draw_colored_polygon(PackedVector2Array([Vector2(205, 200), Vector2(225, 160), Vector2(245, 200)]), sch)
	c.draw_rect(Rect2(218, 176, 14, 14), Color(0.9, 0.8, 0.5, a * 0.35))
	for w in [[80, 270], [100, 270], [290, 262], [330, 262], [370, 262], [430, 280], [540, 256]]:
		c.draw_rect(Rect2(w[0], w[1], 4, 6), Color(1.0, 0.8, 0.45, a * (0.5 + 0.2 * sin(_t * 2.0 + w[0]))))


func _star(c: Control, p: Vector2, r: float, col: Color) -> void:
	c.draw_line(p + Vector2(-r * 1.8, 0), p + Vector2(r * 1.8, 0), col, 1.0)
	c.draw_line(p + Vector2(0, -r * 1.8), p + Vector2(0, r * 1.8), col, 1.0)
	c.draw_circle(p, r * 0.7, col)
