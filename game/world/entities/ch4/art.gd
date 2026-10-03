extends RefCounted
## 4장 공용 코드 그림 (배경·소품·장치·적이 함께 씀): 종, 대리석 기둥, 얼굴 없는 루멘 석상, 해, 달, 돔, 빛 무리.
## 모두 static — `const ART := preload("res://world/entities/ch4/art.gd")` 후 `ART.bell(self, ...)`.


const BELL_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.22, 0.03), Vector2(0.28, 0.09), Vector2(0.3, 0.18), Vector2(0.31, 0.36),
	Vector2(0.33, 0.55), Vector2(0.37, 0.72), Vector2(0.45, 0.86), Vector2(0.52, 0.95), Vector2(0.54, 1.0),
]


const BELL_METAL := Color("#c8963c")


const WHITE_HOT := Color("#fff8e8")


## 0~1 결정적 난수 (프레임마다 같은 값 → 움직이는 그림도 흔들리지 않음)
static func hf(i: int, s: int) -> float:
	var n := i * 374761393 + s * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(absi(n) % 10000) / 10000.0


static func bp(top: Vector2, side: Vector2, dir: Vector2, size: float, x: float, y: float) -> Vector2:
	return top + side * x * size + dir * y * size


## 흔들리는 종 (청동·금): pivot에 매달려 ang(라디안)만큼 기운다. dim = 멀수록 어둡게 (0~1), light = 빛 받는 정도
static func bell(c: CanvasItem, pivot: Vector2, length: float, size: float, ang: float, metal: Color, dim: float, light := 0.0) -> void:
	var dir := Vector2(sin(ang), cos(ang))
	var side := Vector2(dir.y, -dir.x)
	var top := pivot + dir * length
	var dark := Color(0.04, 0.03, 0.07)
	var body := metal.lerp(dark, dim)
	var shade := metal.darkened(0.5).lerp(dark, dim)
	var hi := metal.lightened(0.4).lerp(dark, dim * 0.75)
	c.draw_line(pivot, top, shade.darkened(0.3), maxf(1.0, size * 0.05))
	var pts := PackedVector2Array()
	for p in BELL_PROFILE:
		pts.append(bp(top, side, dir, size, p.x, p.y))
	for i in range(BELL_PROFILE.size() - 1, 0, -1):
		pts.append(bp(top, side, dir, size, -BELL_PROFILE[i].x, BELL_PROFILE[i].y))
	c.draw_colored_polygon(pts, body)
	# 그늘진 오른쪽
	var sh := PackedVector2Array()
	for p in BELL_PROFILE:
		sh.append(bp(top, side, dir, size, p.x, p.y))
	sh.append(bp(top, side, dir, size, 0.14, 1.0))
	sh.append(bp(top, side, dir, size, 0.08, 0.12))
	c.draw_colored_polygon(sh, shade)
	# 빛을 받는 왼쪽 띠
	c.draw_colored_polygon(PackedVector2Array([
		bp(top, side, dir, size, -0.2, 0.05), bp(top, side, dir, size, -0.11, 0.04),
		bp(top, side, dir, size, -0.17, 0.86), bp(top, side, dir, size, -0.33, 0.87),
	]), Color(hi, 0.55 + light * 0.4))
	var lw := maxf(1.0, size * 0.025)
	c.draw_line(bp(top, side, dir, size, -0.3, 0.22), bp(top, side, dir, size, 0.3, 0.22), hi, lw)
	c.draw_line(bp(top, side, dir, size, -0.31, 0.28), bp(top, side, dir, size, 0.31, 0.28), Color(hi, 0.5), lw)
	c.draw_line(bp(top, side, dir, size, -0.44, 0.84), bp(top, side, dir, size, 0.44, 0.84), hi, lw)
	# 입술(테) + 입 안쪽 + 추
	c.draw_line(bp(top, side, dir, size, -0.54, 0.99), bp(top, side, dir, size, 0.54, 0.99), hi.lightened(0.15), maxf(1.0, size * 0.045))
	c.draw_colored_polygon(PackedVector2Array([
		bp(top, side, dir, size, -0.48, 1.0), bp(top, side, dir, size, 0.48, 1.0),
		bp(top, side, dir, size, 0.3, 1.06), bp(top, side, dir, size, -0.3, 1.06),
	]), shade.darkened(0.5))
	c.draw_circle(bp(top, side, dir, size, sin(ang * 3.0) * 0.08, 1.04), size * 0.075, shade.darkened(0.2))
	# 머리 고리
	c.draw_rect(Rect2(top - side * size * 0.07 - dir * size * 0.06, Vector2(maxf(size * 0.14, 1.0), maxf(size * 0.07, 1.0))), shade)


## 대리석 기둥: 세로 홈 + 금빛 머리·받침
static func column(c: CanvasItem, x: float, top: float, bottom: float, w: float, body: Color, light: Color, gold: Color) -> void:
	c.draw_rect(Rect2(x - w * 0.5, top, w, bottom - top), body)
	c.draw_rect(Rect2(x - w * 0.5 + w * 0.12, top, maxf(w * 0.14, 1.0), bottom - top), light)
	for i in 3:
		c.draw_rect(Rect2(x - w * 0.5 + w * (0.4 + i * 0.18), top, maxf(w * 0.05, 1.0), bottom - top), body.darkened(0.22))
	c.draw_rect(Rect2(x - w * 0.78, top - w * 0.42, w * 1.56, w * 0.42), body.lightened(0.06))
	c.draw_rect(Rect2(x - w * 0.78, top - w * 0.42, w * 1.56, maxf(w * 0.08, 1.0)), gold)
	c.draw_rect(Rect2(x - w * 0.62, top - w * 0.1, w * 1.24, maxf(w * 0.1, 1.0)), gold.darkened(0.35))
	c.draw_rect(Rect2(x - w * 0.72, bottom - w * 0.32, w * 1.44, w * 0.32), body.lightened(0.04))
	c.draw_rect(Rect2(x - w * 0.72, bottom - w * 0.32, w * 1.44, maxf(w * 0.05, 1.0)), gold.darkened(0.25))


## 얼굴 없는 루멘 석상 (해의 관). pose 0: 가슴 앞에 해 원반 / 1: 한 손을 들어 해 원반을 받쳐 듦
static func lumen_statue(c: CanvasItem, base: Vector2, h: float, body: Color, rim: Color, gold: Color, pose := 0, rim_side := 1.0) -> void:
	var sh_y := base.y - h * 0.78
	var sh_w := h * 0.13
	var hem_w := h * 0.2
	# 받침
	c.draw_rect(Rect2(base.x - hem_w * 1.3, base.y - h * 0.06, hem_w * 2.6, h * 0.06), body.darkened(0.15))
	c.draw_rect(Rect2(base.x - hem_w * 1.3, base.y - h * 0.06, hem_w * 2.6, maxf(h * 0.008, 1.0)), gold.darkened(0.2))
	# 로브 (어깨 → 옷자락)
	var robe := PackedVector2Array([
		Vector2(base.x - sh_w, sh_y), Vector2(base.x + sh_w, sh_y),
		Vector2(base.x + hem_w, base.y - h * 0.06), Vector2(base.x - hem_w, base.y - h * 0.06),
	])
	c.draw_colored_polygon(robe, body)
	# 옷 주름
	for i in 4:
		var fx := base.x + (i - 1.5) * hem_w * 0.42
		c.draw_line(Vector2(base.x + (i - 1.5) * sh_w * 0.4, sh_y + h * 0.08), Vector2(fx, base.y - h * 0.07), body.darkened(0.18), maxf(1.0, h * 0.008))
	# 테두리 빛 (빛을 받는 쪽)
	var e0 := Vector2(base.x + sh_w * rim_side, sh_y)
	var e1 := Vector2(base.x + hem_w * rim_side, base.y - h * 0.06)
	c.draw_line(e0, e1, Color(rim, 0.55), maxf(1.0, h * 0.012))
	# 머리 (얼굴 없음)
	var hc := Vector2(base.x, sh_y - h * 0.07)
	var hr := h * 0.055
	# 해의 관: 머리 뒤 빛살 고리
	for i in 12:
		var a := TAU * i / 12.0
		c.draw_colored_polygon(PackedVector2Array([
			hc + Vector2(cos(a - 0.12), sin(a - 0.12)) * hr * 1.5, hc + Vector2(cos(a), sin(a)) * hr * 2.6, hc + Vector2(cos(a + 0.12), sin(a + 0.12)) * hr * 1.5,
		]), gold)
	c.draw_arc(hc, hr * 1.55, 0, TAU, 20, gold.lightened(0.15), maxf(1.0, hr * 0.18))
	c.draw_circle(hc, hr * 1.05, body.lightened(0.04))
	c.draw_line(hc + Vector2(hr * 0.9 * rim_side, -hr * 0.5), hc + Vector2(hr * 0.9 * rim_side, hr * 0.5), Color(rim, 0.5), maxf(1.0, hr * 0.15))
	# 머리 너울(어깨로 흘러내림)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-hr, -hr * 0.2), hc + Vector2(hr, -hr * 0.2), Vector2(base.x + sh_w * 1.05, sh_y + h * 0.03), Vector2(base.x - sh_w * 1.05, sh_y + h * 0.03)]), body.darkened(0.08))
	if pose == 0:
		# 가슴 앞에 맞잡은 손 + 해 원반
		var dc := Vector2(base.x, sh_y + h * 0.12)
		c.draw_circle(dc, h * 0.06, gold)
		c.draw_circle(dc, h * 0.042, gold.lightened(0.25))
		c.draw_line(Vector2(base.x - sh_w, sh_y + h * 0.02), dc + Vector2(-h * 0.04, h * 0.03), body.lightened(0.05), maxf(1.0, h * 0.03))
		c.draw_line(Vector2(base.x + sh_w, sh_y + h * 0.02), dc + Vector2(h * 0.04, h * 0.03), body.lightened(0.05), maxf(1.0, h * 0.03))
	else:
		# 한 팔을 높이 들어 해 원반을 받쳐 듦
		var hand := Vector2(base.x + sh_w * 1.6 * rim_side, sh_y - h * 0.26)
		c.draw_line(Vector2(base.x + sh_w * rim_side, sh_y + h * 0.01), hand, body.lightened(0.05), maxf(1.0, h * 0.032))
		c.draw_circle(hand + Vector2(0, -h * 0.06), h * 0.075, gold)
		c.draw_circle(hand + Vector2(0, -h * 0.06), h * 0.05, gold.lightened(0.3))
		c.draw_line(Vector2(base.x - sh_w, sh_y + h * 0.02), Vector2(base.x - sh_w * 0.4, sh_y + h * 0.16), body.lightened(0.05), maxf(1.0, h * 0.03))


## 은은한 빛 무리 (겹친 원)
static func glow(c: CanvasItem, p: Vector2, r: float, col: Color, a: float) -> void:
	for i in 4:
		c.draw_circle(p, r * (1.0 - i * 0.22), Color(col, a * (0.18 + i * 0.12)))


static func lantern_dot(c: CanvasItem, p: Vector2, r: float, a: float) -> void:
	c.draw_circle(p, r * 3.2, Color(1.0, 0.75, 0.4, 0.07 * a))
	c.draw_circle(p, r * 1.8, Color(1.0, 0.8, 0.45, 0.2 * a))
	c.draw_circle(p, r, Color(1.0, 0.9, 0.6, a))


## 아치 (기둥 사이 반원 테두리)
static func arch(c: CanvasItem, x0: float, x1: float, spring_y: float, col: Color, width: float) -> void:
	var cx := (x0 + x1) * 0.5
	var r := (x1 - x0) * 0.5
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		pts.append(Vector2(cx + cos(a) * r, spring_y + sin(a) * r))
	c.draw_polyline(pts, col, width)


## 금빛 돔 (북 + 반구 + 꼭대기 등탑)
static func dome(c: CanvasItem, cx: float, base_y: float, r: float, body: Color, gold: Color, window: Color) -> void:
	c.draw_rect(Rect2(cx - r * 0.92, base_y - r * 0.55, r * 1.84, r * 0.55), body)
	for i in 5:
		var wx := cx - r * 0.7 + i * r * 0.35
		c.draw_rect(Rect2(wx - r * 0.05, base_y - r * 0.42, r * 0.1, r * 0.22), window)
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		pts.append(Vector2(cx + cos(a) * r, base_y - r * 0.55 + sin(a) * r * 0.95))
	c.draw_colored_polygon(pts, gold)
	# 반구의 갈빗대와 빛
	for i in 4:
		var a2 := PI + PI * (0.2 + i * 0.2)
		c.draw_line(Vector2(cx + cos(a2) * r, base_y - r * 0.55 + sin(a2) * r * 0.95), Vector2(cx, base_y - r * 1.5), gold.darkened(0.25), maxf(1.0, r * 0.04))
	c.draw_arc(Vector2(cx, base_y - r * 0.55), r * 0.82, PI * 1.12, PI * 1.45, 8, Color(1, 1, 1, 0.25), maxf(1.0, r * 0.07))
	# 등탑
	c.draw_rect(Rect2(cx - r * 0.14, base_y - r * 1.8, r * 0.28, r * 0.32), body)
	c.draw_circle(Vector2(cx, base_y - r * 1.8), r * 0.15, gold)
	c.draw_line(Vector2(cx, base_y - r * 1.9), Vector2(cx, base_y - r * 2.35), gold, maxf(1.0, r * 0.05))
	c.draw_circle(Vector2(cx, base_y - r * 2.35), maxf(1.0, r * 0.06), WHITE_HOT)


## 해: 겹친 빛무리 + 천천히 도는 빛살
static func sun(c: CanvasItem, p: Vector2, r: float, t: float, core: Color, halo: Color, flicker := 0.0) -> void:
	var fl := 1.0 - flicker * (0.5 + 0.5 * sin(t * 2.3) * sin(t * 0.9))
	for i in 6:
		c.draw_circle(p, r * (4.2 - i * 0.55), Color(halo, (0.025 + i * 0.012) * fl))
	var rays := 14
	for i in rays:
		var a := t * 0.025 + TAU * float(i) / rays
		var ln := r * (3.4 + 0.8 * sin(t * 0.6 + i * 1.7))
		var w := 0.045 + 0.02 * (i % 2)
		c.draw_colored_polygon(PackedVector2Array([
			p + Vector2(cos(a - w), sin(a - w)) * r * 1.05, p + Vector2(cos(a), sin(a)) * ln, p + Vector2(cos(a + w), sin(a + w)) * r * 1.05,
		]), Color(halo, 0.07 * fl))
	c.draw_circle(p, r * 1.18, Color(halo, 0.35 * fl))
	c.draw_circle(p, r, core)
	c.draw_circle(p + Vector2(-r * 0.25, -r * 0.25), r * 0.55, Color(1, 1, 1, 0.35))


static func moon(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	for i in 4:
		c.draw_circle(p, r * (2.6 - i * 0.4), Color(col, 0.03 + i * 0.012))
	c.draw_circle(p, r, col)
	c.draw_circle(p + Vector2(r * 0.3, -r * 0.15), r * 0.22, col.darkened(0.08))
	c.draw_circle(p + Vector2(-r * 0.35, r * 0.3), r * 0.16, col.darkened(0.07))
	c.draw_circle(p + Vector2(-r * 0.1, -r * 0.45), r * 0.1, col.darkened(0.06))


## 빛의 거울: center = 고리 중심, angle = 거울판이 세로에서 기운 각(라디안, + = 오른쪽 위로 '/'), lit = 빛을 받는 정도(0~1).
## 받침은 center 아래 28px(바닥)까지. 소품(tp_mirror)과 퍼즐 장치(light_mirror)가 함께 쓴다.
static func mirror(c: CanvasItem, center: Vector2, angle: float, t: float, lit: float) -> void:
	var gold := Color("#e0b048")
	var gold_dark := Color("#8a6428")
	var floor_y := center.y + 28.0
	c.draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 28), center + Vector2(9, 28), center + Vector2(6, 24), center + Vector2(-6, 24)]), gold_dark)
	c.draw_rect(Rect2(center.x - 1.5, center.y + 9, 3, floor_y - center.y - 13), gold_dark)
	c.draw_rect(Rect2(center.x - 1.5, center.y + 9, 1, floor_y - center.y - 13), gold)
	# 짐벌 고리
	c.draw_arc(center, 12.0, 0, TAU, 24, gold_dark, 3.0)
	c.draw_arc(center, 12.0, PI * 1.1, PI * 1.6, 8, gold, 1.0)
	c.draw_circle(center + Vector2(0, -13), 2.0, gold)
	if lit > 0.0:
		glow(c, center, 22.0, Color(1.0, 0.92, 0.7), 0.5 * lit)
	# 거울판
	var d := Vector2(sin(angle), -cos(angle))
	var a := center - d * 11.0
	var b := center + d * 11.0
	c.draw_line(a, b, gold_dark, 7.0)
	c.draw_line(a, b, gold, 5.0)
	c.draw_line(a + d * 1.0, b - d * 1.0, Color("#b8c8e8"), 3.0)
	var g := sin(t * 1.6) * 0.5 + 0.5
	var gp := a.lerp(b, 0.15 + g * 0.7)
	c.draw_line(gp - d * 1.5, gp + d * 1.5, Color(1, 1, 1, 0.9), 3.0)
	c.draw_circle(center, 1.5, gold_dark)


## 금빛 봉인석 (유성 낙화로만 부서짐): base = 바닥 가운데. intact = 1이면 멀쩡, crack = 금 간 정도(0~1)
static func seal_stone(c: CanvasItem, base: Vector2, t: float, intact: float, crack: float) -> void:
	var stone := Color("#4e4a62")
	var stone_l := Color("#7a7690")
	var stone_d := Color("#2e2b3c")
	var gold := Color("#ffd870")
	var pts := PackedVector2Array([
		base + Vector2(-13, 0), base + Vector2(-15, -10), base + Vector2(-12, -24), base + Vector2(-4, -30),
		base + Vector2(6, -29), base + Vector2(13, -22), base + Vector2(15, -9), base + Vector2(12, 0),
	])
	c.draw_colored_polygon(pts, stone)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-15, -10), base + Vector2(-12, -24), base + Vector2(-4, -30), base + Vector2(-6, -24), base + Vector2(-10, -12)]), stone_l)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(13, -22), base + Vector2(15, -9), base + Vector2(12, 0), base + Vector2(8, 0), base + Vector2(10, -18)]), stone_d)
	# 금빛 봉인 고리 + 해 문양 + 둘레 글자
	var cen := base + Vector2(0, -15)
	var pulse := (0.65 + 0.35 * sin(t * 2.0)) * intact
	glow(c, cen, 18.0, Color(1.0, 0.85, 0.45), 0.35 * pulse)
	c.draw_arc(cen, 9.0, 0, TAU, 24, Color(gold, 0.9 * pulse + 0.1), 1.5)
	c.draw_arc(cen, 6.0, 0, TAU, 16, Color(gold, 0.6 * pulse), 1.0)
	for i in 8:
		var a := TAU * i / 8.0 + t * 0.3
		c.draw_line(cen + Vector2(cos(a), sin(a)) * 2.5, cen + Vector2(cos(a), sin(a)) * 5.0, Color(gold, pulse), 1.0)
		var r2 := cen + Vector2(cos(a + 0.4), sin(a + 0.4)) * 11.5
		c.draw_rect(Rect2(r2 - Vector2(0.5, 0.5), Vector2(1, 1)), Color(gold, 0.8 * pulse))
	c.draw_circle(cen, 2.0, Color(1.0, 0.95, 0.8, pulse))
	if crack > 0.0:
		var cc := Color(1.0, 0.95, 0.8, 0.9)
		c.draw_polyline(PackedVector2Array([base + Vector2(-4, -30), base + Vector2(-2, -22), base + Vector2(-5, -14), base + Vector2(-1, -6)]), Color(cc, crack), 1.0)
		c.draw_polyline(PackedVector2Array([base + Vector2(13, -22), base + Vector2(7, -17), base + Vector2(9, -9)]), Color(cc, crack), 1.0)


## 문양 (종 받침·벽화 단서): moon · fox · flame · star · sun. 여우창문 벽화(HintMural)와 같은 모양을 작게
static func symbol(c: CanvasItem, p: Vector2, kind: String, col: Color, bg: Color, s := 1.0) -> void:
	match kind:
		"moon":
			c.draw_circle(p, 5.0 * s, col)
			c.draw_circle(p + Vector2(2, -1.5) * s, 4.2 * s, bg)
		"fox":
			var pts := PackedVector2Array()
			for v: Vector2 in [Vector2(-5, -1), Vector2(-6, -7), Vector2(-1.5, -4), Vector2(1.5, -4), Vector2(6, -7), Vector2(5, -1), Vector2(0, 4.5)]:
				pts.append(p + v * s)
			c.draw_colored_polygon(pts, col)
		"flame":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-3.5, 4.5) * s, p + Vector2(0, -6.5) * s, p + Vector2(3.5, 4.5) * s]), col)
		"star":
			for k in 5:
				var ang := -PI * 0.5 + TAU * k / 5.0
				c.draw_line(p, p + Vector2(cos(ang), sin(ang)) * 5.5 * s, col, 1.5)
		_:
			c.draw_circle(p, 3.0 * s, col)
			for k in 8:
				var ang2 := TAU * k / 8.0
				c.draw_line(p + Vector2(cos(ang2), sin(ang2)) * 4.0 * s, p + Vector2(cos(ang2), sin(ang2)) * 6.0 * s, col, 1.0)
