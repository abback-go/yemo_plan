extends RefCounted
## 공통 시스템(학교 수업 시험 방) 배경 — RoomBackdrop가 부른다. 테마: windtower · observatory · duel · ash

const MINE := ["windtower", "observatory", "duel", "ash"]
const Kit := preload("res://world/themes/backdrop_kit.gd")
const Ch1 := preload("res://world/themes/backdrop_ch1.gd")


## 움직이는 층(예전 is_animated): windtower·observatory·ash의 전경 아닌 층. 그리기 계약은 backdrop_kit.gd 머리말
static func has_theme(theme: String) -> bool:
	return theme in MINE


static func has_sky(theme: String) -> bool:
	return theme in ["windtower", "observatory"]


## 화면 고정 하늘 (640×360)
static func draw_sky(c, theme: String, pal: Dictionary, _t: float) -> void:
	var top: Color = pal.sky_top
	var bot: Color = pal.sky_bottom
	Kit.stepped_grad(c, Rect2(0, 0, 640, 360), top, bot, 24, 1.2)
	var rng := RandomNumberGenerator.new()
	if theme == "windtower":
		# 흘러가는 구름 띠 (낮 하늘)
		rng.seed = 7
		var cl: Array = [] ## [y, w, x0, speed, a]
		for i in 9:
			var y := rng.randf_range(30, 300)
			var w := rng.randf_range(120, 260)
			var x0 := rng.randf_range(0, 900)
			var sp := rng.randf_range(6, 16)
			cl.append([y, w, x0, sp, rng.randf_range(0.18, 0.35)])
		c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
			for e: Array in cl:
				var y: float = e[0]
				var w: float = e[1]
				var x := fmod(float(e[2]) + t * float(e[3]), 900.0) - 200.0
				var a: float = e[4]
				for k2 in 4:
					cv.draw_circle(Vector2(x + k2 * w * 0.25, y + sin(k2 * 1.7) * 6.0), w * 0.16, Color(1, 1, 1, a))
				cv.draw_rect(Rect2(x, y, w * 0.8, w * 0.1), Color(1, 1, 1, a)))
		return
	# observatory: 별이 빽빽한 밤하늘 + 은하수 띠 + 리라 별자리(희미하게) + 초승달
	rng.seed = 1977
	for i in 40:
		var cx := float(i) / 39.0 * 720.0 - 40.0
		var cy := 40.0 + cx * 0.28 + sin(i * 0.9) * 14.0
		c.draw_circle(Vector2(cx, cy), rng.randf_range(18, 34), Color(0.55, 0.6, 1.0, 0.035))
	var sp := PackedVector2Array()
	var spd := PackedFloat64Array()
	for i in 160:
		sp.append(Vector2(rng.randf() * 640, rng.randf() * 300))
		spd.append(rng.randf_range(0.4, 2.2))
	c.anim(Rect2(-3, -3, 648, 308), func(cv: CanvasItem, t: float) -> void:
		for i in 160:
			var p := sp[i]
			var tw := 0.35 + 0.65 * absf(sin(t * spd[i] + i * 1.3))
			var big := i % 23 == 0
			var col := Color(1, 0.95, 0.8) if i % 5 == 0 else Color(0.85, 0.9, 1.0)
			cv.draw_rect(Rect2(p, Vector2.ONE * (2 if big else 1)), Color(col, 0.75 * tw))
			if big:
				cv.draw_rect(Rect2(p + Vector2(-2, 0.5), Vector2(6, 1)), Color(col, 0.25 * tw))
				cv.draw_rect(Rect2(p + Vector2(0.5, -2), Vector2(1, 6)), Color(col, 0.25 * tw)))
	var mc := Vector2(548, 62)
	for r in [60, 44, 34]:
		c.draw_circle(mc, r, Color(1, 0.95, 0.8, 0.03))
	c.draw_circle(mc, 20, Color("#f6ecd4"))
	c.draw_circle(mc + Vector2(8, -4), 18, top.lerp(bot, 0.12))
	# 별똥별 하나가 가끔
	c.anim(Rect2(30, 10, 360, 120), func(cv: CanvasItem, t: float) -> void:
		var ph := fmod(t * 0.17, 1.0)
		if ph < 0.12:
			var k3 := ph / 0.12
			var s0 := Vector2(80 + 300 * k3, 30 + 90 * k3)
			cv.draw_line(s0, s0 - Vector2(40, 12), Color(1, 0.95, 0.8, 0.7 * (1.0 - k3)), 1.0))


## 시차 층. depth 0 먼 · 1 중간 · 2 가까운 · 3 전경
static func draw_layer(l, theme: String, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> bool:
	if not theme in MINE:
		return false
	var th: Dictionary = l.theme
	var col: Color = [th.far, th.mid, th.near, Color(0.02, 0.015, 0.03)][depth]
	if depth == 3:
		Ch1.front_silhouettes(l, span, rng)
		return true
	match theme:
		"windtower": _windtower(l, depth, span, rng, t, col, th)
		"observatory": _observatory(l, depth, span, rng, t, col, th)
		"duel": _duel(l, depth, span, rng, col, th)
		"ash": _ash(l, depth, span, rng, t, col, th)
	return true


## 바람의 탑: 먼 층 = 구름 위로 솟은 다른 탑들 / 중간 = 탑 안쪽 아치 창(하늘이 비침)과 나선 계단 / 가까운 = 바람에 날리는 깃발과 기둥
static func _windtower(l, depth: int, span: Vector2, rng: RandomNumberGenerator, _t: float, col: Color, th: Dictionary) -> void:
	if depth == 0:
		var x := rng.randf_range(0, 120)
		while x < span.x:
			var w := rng.randf_range(30, 60)
			var top := rng.randf_range(40, span.y * 0.5)
			l.draw_rect(Rect2(x, top, w, span.y), Color(col, 0.55))
			l.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, top), Vector2(x + w * 0.5, top - w * 0.9), Vector2(x + w + 6, top)]), Color(col.darkened(0.1), 0.6))
			for k in int((span.y - top) / 40):
				l.draw_rect(Rect2(x + w * 0.5 - 3, top + 20 + k * 40, 6, 10), Color(1, 0.95, 0.8, 0.2))
			x += w + rng.randf_range(80, 200)
		return
	if depth == 1:
		l.draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
		var y := 30.0
		while y < span.y:
			var x2 := rng.randf_range(20, 160)
			while x2 < span.x:
				var w := 54.0
				var h := 110.0
				var arch := PackedVector2Array()
				for i in 9:
					var a := PI + PI * i / 8.0
					arch.append(Vector2(x2 + w * 0.5 + cos(a) * w * 0.5, y + w * 0.5 + sin(a) * w * 0.5))
				arch.append(Vector2(x2 + w, y + h))
				arch.append(Vector2(x2, y + h))
				l.draw_colored_polygon(arch, th.sky_bottom.lerp(th.sky_top, 0.35))
				# 창 너머로 흐르는 구름 조각
				var wx2 := x2
				var wy2 := y
				l.anim(Rect2(x2 - 10, y + 50, w + 20, 4), func(cv: CanvasItem, t: float) -> void:
					var cx := wx2 + fmod(t * 8.0 + wx2, w)
					cv.draw_rect(Rect2(cx - 10, wy2 + 50, 20, 4), Color(1, 1, 1, 0.5)))
				l.draw_line(Vector2(x2 + w * 0.5, y), Vector2(x2 + w * 0.5, y + h), col, 3.0)
				l.draw_rect(Rect2(x2 - 4, y + h, w + 8, 6), col.lightened(0.08))
				x2 += w + rng.randf_range(90, 180)
			# 나선 계단 띠
			l.draw_line(Vector2(-20, y + 140), Vector2(span.x + 20, y + 170), col.lightened(0.06), 6.0)
			y += 220.0
		return
	# 가까운: 굵은 기둥과 바람에 펄럭이는 연보라 깃발
	var x3 := rng.randf_range(0, 200)
	while x3 < span.x:
		l.draw_rect(Rect2(x3, -20, 20, span.y + 40), col)
		var fy := rng.randf_range(40, span.y - 80)
		var fx := x3
		var fc := Color(th.accent, 0.35)
		l.anim(Rect2(x3 + 19, fy - 6, 48, 30), func(cv: CanvasItem, t: float) -> void:
			var pts := PackedVector2Array()
			for i in 7:
				var k := float(i) / 6.0
				pts.append(Vector2(fx + 20 + k * 46, fy + sin(t * 4.0 + k * 3.0 + fx) * 4.0 * k))
			for i in 7:
				var k2 := 1.0 - float(i) / 6.0
				pts.append(Vector2(fx + 20 + k2 * 46, fy + 16 + sin(t * 4.0 + k2 * 3.0 + fx) * 4.0 * k2 - (6.0 if i == 0 else 0.0)))
			cv.draw_colored_polygon(pts, fc))
		x3 += rng.randf_range(260, 420)


## 별 관측대: 먼 층 = 학교의 뾰족 지붕들 / 중간 = 거대한 놋쇠 망원경과 혼천의(천천히 돎) / 가까운 = 굴뚝과 난간
static func _observatory(l, depth: int, span: Vector2, rng: RandomNumberGenerator, _t: float, col: Color, th: Dictionary) -> void:
	var base_y := span.y * (0.62 if depth == 0 else (0.7 if depth == 1 else 0.84))
	if depth == 0:
		var x := -40.0
		while x < span.x + 40:
			var w := rng.randf_range(40, 90)
			var h := rng.randf_range(30, 110)
			l.draw_rect(Rect2(x, base_y - h, w, span.y), col)
			l.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, base_y - h), Vector2(x + w * 0.5, base_y - h - w * 0.8), Vector2(x + w + 4, base_y - h)]), col)
			if rng.randf() < 0.6:
				l.draw_rect(Rect2(x + w * 0.5 - 3, base_y - h + 14, 6, 8), Color(1, 0.8, 0.45, 0.45))
			x += w + rng.randf_range(-10, 30)
		return
	if depth == 1:
		l.draw_rect(Rect2(-100, base_y, span.x + 200, span.y), col)
		var cx := span.x * 0.5 + rng.randf_range(-80, 80)
		var brass := Color("#8a6a3a").lerp(col, 0.4)
		# 망원경
		var p0 := Vector2(cx - 140, base_y)
		l.anim(Rect2(p0 + Vector2(-40, -200), Vector2(200, 210)), func(cv: CanvasItem, t: float) -> void:
			var a := -0.65 + sin(t * 0.1) * 0.05
			var dirv := Vector2.from_angle(a)
			cv.draw_line(p0 + Vector2(0, -40), p0 + Vector2(0, 0), brass, 6.0)
			cv.draw_line(p0 + Vector2(0, -40) - dirv * 30.0, p0 + Vector2(0, -40) + dirv * 120.0, brass, 12.0)
			cv.draw_line(p0 + Vector2(0, -40) + dirv * 120.0, p0 + Vector2(0, -40) + dirv * 150.0, brass.lightened(0.15), 16.0))
		# 혼천의 (고리 셋이 다른 속도로)
		var hc := Vector2(cx + 120, base_y - 70)
		l.draw_line(hc + Vector2(0, 40), Vector2(hc.x, base_y), brass, 4.0)
		l.anim(Kit.bb_circle(hc, 42.0), func(cv: CanvasItem, t: float) -> void:
			for i in 3:
				var rot := t * (0.2 + i * 0.13) + i
				var pts := PackedVector2Array()
				for k in 33:
					var b := TAU * k / 32.0
					var v := Vector2(cos(b) * 40.0, sin(b) * 40.0 * absf(cos(rot)))
					pts.append(hc + v.rotated(i * 0.8))
				cv.draw_polyline(pts, brass.lightened(0.1 * i), 2.0))
		l.draw_circle(hc, 6.0, Color(th.accent, 0.6))
		return
	# 가까운: 굴뚝(연기), 철제 난간
	var x2 := rng.randf_range(0, 120)
	while x2 < span.x:
		var h2 := rng.randf_range(50, 90)
		l.draw_rect(Rect2(x2, base_y - h2, 26, span.y), col)
		l.draw_rect(Rect2(x2 - 3, base_y - h2, 32, 6), col.lightened(0.05))
		var sx := x2
		var sy := base_y - h2
		l.anim(Rect2(x2 + 13 - 18, sy - 6 - 60 - 12, 36, 78), func(cv: CanvasItem, t: float) -> void:
			for k in 4:
				var ph := fmod(t * 0.25 + k * 0.25, 1.0)
				cv.draw_circle(Vector2(sx + 13 + sin(ph * 6.0 + k) * 6.0, sy - 6 - ph * 60.0), 4.0 + ph * 8.0, Color(0.6, 0.62, 0.75, 0.12 * (1.0 - ph))))
		x2 += rng.randf_range(220, 380)
	l.draw_rect(Rect2(-100, base_y + 20, span.x + 200, 3), col.lightened(0.04))
	var bx := -100.0
	while bx < span.x + 100:
		l.draw_rect(Rect2(bx, base_y + 20, 2, 18), col.lightened(0.04))
		bx += 14.0


## 결투장: 둥근 관람석 계단, 금테 두른 검은 기둥, 바닥 위로 뜬 거대한 보라 마법진 윤곽
static func _duel(l, depth: int, span: Vector2, rng: RandomNumberGenerator, col: Color, th: Dictionary) -> void:
	l.draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
	if depth == 0:
		for k in 6:
			var y := span.y * 0.35 + k * 22.0
			l.draw_rect(Rect2(-100, y, span.x + 200, 4), col.lightened(0.05))
			var x := rng.randf_range(0, 20)
			while x < span.x:
				l.draw_rect(Rect2(x, y - 8, 6, 8), col.lightened(0.08))
				x += rng.randf_range(10, 24)
		var c := Vector2(span.x * 0.5, span.y * 0.3)
		for r in [120.0, 96.0]:
			l.draw_arc(c, r, 0.0, TAU, 48, Color(th.accent, 0.12), 2.0)
		for i in 6:
			var a := TAU * i / 6.0
			l.draw_line(c + Vector2.from_angle(a) * 96.0, c + Vector2.from_angle(a + TAU / 3.0) * 96.0, Color(th.accent, 0.08), 1.0)
		return
	var gap := 220.0 if depth == 1 else 380.0
	var x2 := rng.randf_range(20, gap * 0.5)
	while x2 < span.x:
		var w := 30.0 if depth == 1 else 22.0
		l.draw_rect(Rect2(x2, -20, w, span.y + 40), col.lightened(0.04))
		l.draw_rect(Rect2(x2 - 4, span.y * 0.12, w + 8, 4), Color(th.top_hi, 0.35))
		l.draw_rect(Rect2(x2 - 4, span.y * 0.7, w + 8, 4), Color(th.top_hi, 0.35))
		x2 += gap + rng.randf_range(-30, 30)


## 재의 서고: 타다 만 거대 책장(검게 그을린 위쪽), 공중에 떠 있는 재 조각, 멀리 붉게 남은 불씨
static func _ash(l, depth: int, span: Vector2, rng: RandomNumberGenerator, _t: float, col: Color, th: Dictionary) -> void:
	l.draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
	var shelf_w := 80.0 if depth == 0 else (110.0 if depth == 1 else 140.0)
	var gap := 50.0 + depth * 70.0
	var x := rng.randf_range(0, gap)
	var dim := 0.6 if depth == 0 else (0.4 if depth == 1 else 0.2)
	while x < span.x:
		var burnt := rng.randf_range(0.2, 0.6)
		l.draw_rect(Rect2(x, -20, shelf_w, span.y + 40), col.lightened(0.03))
		var y := 10.0
		while y < span.y:
			l.draw_rect(Rect2(x, y, shelf_w, 3), col.lightened(0.07))
			if y > span.y * burnt:
				var bx := x + 3
				while bx < x + shelf_w - 6:
					var bw := rng.randf_range(3, 7)
					var bh := rng.randf_range(12, 22)
					l.draw_rect(Rect2(bx, y - bh, bw, bh), Color("#4a3a32").lerp(col, dim))
					bx += bw + 1
			y += 30
		# 그을린 끝의 불씨
		var ey := span.y * burnt
		var ex := x
		var ea := 0.5 - depth * 0.12
		var acc: Color = th.accent
		for k in 3:
			var er := Rect2(x + 10 + k * shelf_w * 0.3, ey - 2, 3, 2)
			l.anim(er, func(cv: CanvasItem, t: float) -> void:
				var fl := 0.5 + 0.5 * sin(t * 3.0 + ex * 0.1 + k)
				cv.draw_rect(er, Color(acc, ea * fl)))
		x += shelf_w + gap + rng.randf_range(0, 60)
	if depth == 1:
		# 떠오르는 재 (fmod가 음수를 그대로 두어 위로 빠져나간 조각은 다시 나오지 않는다 — 예전 그대로)
		var sh := span.y
		for k in 24:
			var px := rng.randf() * span.x
			var py0 := rng.randf() * span.y
			var sp := rng.randf_range(4, 10)
			l.anim(Rect2(px, -sh, 2, sh * 2.0 + 1), func(cv: CanvasItem, t: float) -> void:
				var p := Vector2(px, fmod(py0 - t * sp, sh))
				cv.draw_rect(Rect2(p, Vector2(2, 1)), Color(0.6, 0.55, 0.5, 0.35)))
