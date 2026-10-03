extends RefCounted
## 3장 지역 배경 (RoomBackdrop가 부름) — docs/bible/art.md 2절, docs/chapter3.md 7절.
##   elf       세계수 에일라흐: 절벽 같은 줄기·길 같은 가지·빛나는 수액 줄기, 가지 위 엘프 집(둥근 창·등불), 흔들다리,
##             바람길(흐르는 띠), 반딧불. 가장 먼 층 꼭대기에 에일라흐의 수관(樹冠)이 하늘을 덮는다.
##   elf_deep  뿌리 동굴: 아치처럼 휘어진 거대한 뿌리, 청록 버섯 빛, 빛 구슬이 맺힌 실(반딧불 애벌레), 포자.
##   blight    흰 역병: 하얗게 굳은 나무, 직선·삼각형으로만 갈라지는 금, 육각 수정, 하늘의 기하학 문양(바깥 신들의 언어).
##
## 구조: 각 층(먼 0·중간 1·가까운 2·전경 3)은 정적 그림을 한 번만 그린다(is_animated = false → 매 프레임 다시 그리지 않음).
## 움직이는 것(수액 맥동·등불 흔들림·바람길 띠·덩굴·버섯 빛·떠다니는 조각)은 그 층의 자식 Anim 노드가 따로 그린다.
## → 무거운 정적 그림 + 가벼운 움직임 (웹·모바일 대비).

const MINE := ["elf", "elf_deep", "blight"]
const SAP := Color("#c8ff7a")
const WINDOW := Color("#f2ffc0")
const MUSH := Color("#5affd0")
const WHITE := Color("#f0f0ff")


static func is_animated(_theme: String, _depth: int) -> bool:
	return false


static func has_sky(theme: String) -> bool:
	return theme in MINE


## 시차 층이 실제로 덮어야 하는 크기. RoomBackdrop._span()은 세로도 가로 시차 배율로 계산해서
## 아주 높은 방(세계수 세로 방)에서는 아래가 비므로, 세로 시차 배율(scroll×0.6+0.4)로 다시 잡는다.
static func _cover(l: Node2D, span: Vector2) -> Vector2:
	var rs: Vector2 = l.get("room_size")
	var sc: float = l.get("scroll")
	var need_y := 368.0 + maxf(rs.y - 368.0, 0.0) * (sc * 0.6 + 0.4) + 160.0
	return Vector2(span.x, maxf(span.y, need_y))


static func _th(l: Node2D) -> Dictionary:
	return l.get("theme")


# ═══════════════════════════════════════════════════════
# 하늘 (화면 고정 640×360, 매 프레임)
# ═══════════════════════════════════════════════════════

static func draw_sky(c: Control, theme: String, pal: Dictionary, t: float) -> void:
	var top: Color = pal.sky_top
	var bot: Color = pal.sky_bottom
	for i in 24:
		var k := float(i) / 23.0
		c.draw_rect(Rect2(0, i * 15, 640, 16), top.lerp(bot, pow(k, 1.3)))
	match theme:
		"elf":
			_sky_elf(c, pal, t)
		"elf_deep":
			_sky_deep(c, pal, t)
		"blight":
			_sky_blight(c, pal, t)


static func _sky_elf(c: Control, _pal: Dictionary, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3101
	# 별 (수관 틈으로 보이는 밤하늘)
	for i in 46:
		var p := Vector2(rng.randf() * 640, rng.randf() * 170)
		var tw := 0.35 + 0.65 * absf(sin(t * rng.randf_range(0.4, 1.6) + i))
		c.draw_rect(Rect2(p, Vector2.ONE * (2 if i % 11 == 0 else 1)), Color(0.9, 1.0, 0.85, 0.45 * tw))
	# 달 (연둣빛 달무리)
	var mc := Vector2(492, 78)
	for r in [74.0, 54.0, 40.0]:
		c.draw_circle(mc, r, Color(0.85, 1.0, 0.7, 0.03))
	c.draw_circle(mc, 22, Color("#e8f2d4"))
	c.draw_circle(mc + Vector2(-6, -4), 5, Color("#d2dfbc"))
	c.draw_circle(mc + Vector2(7, 6), 3, Color("#d2dfbc"))
	# 지평선의 다른 거목들 (아주 멀리, 안개에 잠김)
	var fog := Color("#1c3628")
	for i in 5:
		var x := 40.0 + i * 140.0 + rng.randf_range(-30, 30)
		var w := rng.randf_range(16, 30)
		c.draw_rect(Rect2(x - w * 0.5, 210, w, 160), fog.lerp(Color("#24432f"), 0.3))
		for j in 4:
			c.draw_circle(Vector2(x + rng.randf_range(-46, 46), 200 + rng.randf_range(-20, 16)), rng.randf_range(26, 44), fog.lerp(Color("#24432f"), 0.15))
	# 아래쪽 안개 띠 (따뜻한 등불 빛이 번진 듯)
	for i in 6:
		c.draw_rect(Rect2(0, 270 + i * 15, 640, 15), Color(0.8, 1.0, 0.55, 0.018 + i * 0.006))
	# 빛줄기: 수관 틈에서 비스듬히 떨어지는 달빛
	for i in 4:
		var x0 := 90.0 + i * 150.0 + rng.randf_range(-20, 20)
		var a := 0.022 + 0.014 * sin(t * 0.35 + i * 1.7)
		var w0 := rng.randf_range(16, 30)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x0, -10), Vector2(x0 + w0, -10), Vector2(x0 + w0 + 120, 360), Vector2(x0 + 50, 360)]), Color(0.86, 1.0, 0.7, a))


static func _sky_deep(c: Control, _pal: Dictionary, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3102
	# 동굴 안쪽 아득한 곳의 버섯 빛 (흐릿한 점)
	for i in 34:
		var p := Vector2(rng.randf() * 640, 60 + rng.randf() * 280)
		var r := rng.randf_range(1.0, 3.5)
		var k := 0.5 + 0.5 * sin(t * rng.randf_range(0.3, 0.9) + i)
		c.draw_circle(p, r * 3.0, Color(MUSH, 0.025 * k))
		c.draw_circle(p, r * 0.6, Color(MUSH, 0.25 * k))
	for i in 5:
		c.draw_rect(Rect2(0, 250 + i * 22, 640, 22), Color(0.3, 1.0, 0.85, 0.012 + i * 0.006))


static func _sky_blight(c: Control, _pal: Dictionary, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3103
	# 하늘에 새겨진 거대한 기하학 문양 (천천히 돈다) — 원 + 육각형 + 삼각형 두 개 + 가운데 세로 틈(눈)
	var cc := Vector2(330, 120)
	var rot := t * 0.03
	var a := 0.07 + 0.03 * sin(t * 0.5)
	c.draw_arc(cc, 150, 0, TAU, 64, Color(WHITE, a * 0.7), 1.0)
	c.draw_arc(cc, 112, 0, TAU, 64, Color(WHITE, a * 0.5), 1.0)
	_poly_line(c, cc, 150, 6, rot, Color(WHITE, a), 1.0)
	_poly_line(c, cc, 112, 3, -rot * 1.5, Color(WHITE, a * 0.9), 1.0)
	_poly_line(c, cc, 112, 3, -rot * 1.5 + PI, Color(WHITE, a * 0.9), 1.0)
	var eye := 0.5 + 0.5 * sin(t * 0.21)
	c.draw_colored_polygon(PackedVector2Array([cc + Vector2(0, -40), cc + Vector2(4 + 3 * eye, 0), cc + Vector2(0, 40), cc + Vector2(-4 - 3 * eye, 0)]), Color(WHITE, 0.10 + 0.06 * eye))
	c.draw_line(cc + Vector2(0, -36), cc + Vector2(0, 36), Color(1, 1, 1, 0.25 + 0.2 * eye), 1.0)
	# 하늘의 금: 직선으로만 꺾이는 흰 선
	for i in 5:
		var p := Vector2(rng.randf() * 640, rng.randf() * 140)
		var ang := rng.randf_range(0, TAU)
		for j in 4:
			ang += (PI / 3.0) * (1 if rng.randf() < 0.5 else -1)
			var q := p + Vector2(cos(ang), sin(ang)) * rng.randf_range(20, 50)
			c.draw_line(p, q, Color(WHITE, 0.10), 1.0)
			p = q
	# 흰 안개 띠
	for i in 6:
		c.draw_rect(Rect2(0, 250 + i * 18, 640, 18), Color(0.95, 0.95, 1.0, 0.02 + i * 0.008))
	# 이따금 화면을 가로지르는 흰 선 (지직)
	var g := fmod(t, 5.3)
	if g < 0.12:
		var gy := 40.0 + fmod(floorf(t / 5.3) * 97.0, 260.0)
		c.draw_rect(Rect2(0, gy, 640, 1), Color(1, 1, 1, 0.35))
		c.draw_rect(Rect2(120, gy + 3, 300, 1), Color(1, 1, 1, 0.18))


static func _poly_line(c: CanvasItem, center: Vector2, r: float, n: int, rot: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in n + 1:
		var ang := rot + TAU * i / n
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	c.draw_polyline(pts, col, w)


# ═══════════════════════════════════════════════════════
# 시차 층
# ═══════════════════════════════════════════════════════

static func draw_layer(l: Node2D, theme: String, depth: int, span: Vector2, rng: RandomNumberGenerator, _t: float) -> bool:
	if not theme in MINE:
		return false
	var sp := _cover(l, span)
	var anim := Anim.new()
	anim.depth = depth
	match theme:
		"elf":
			match depth:
				0: _elf_far(l, sp, rng, anim)
				1: _elf_mid(l, sp, rng, anim)
				2: _elf_near(l, sp, rng, anim)
				_: _elf_front(l, sp, rng, anim)
		"elf_deep":
			match depth:
				0: _deep_far(l, sp, rng, anim)
				1: _deep_mid(l, sp, rng, anim)
				2: _deep_near(l, sp, rng, anim)
				_: _deep_front(l, sp, rng, anim)
		"blight":
			match depth:
				0: _blight_far(l, sp, rng, anim)
				1: _blight_mid(l, sp, rng, anim)
				2: _blight_near(l, sp, rng, anim)
				_: _blight_front(l, sp, rng, anim)
	if not l.has_meta("ch3_anim") and anim.has_items():
		l.set_meta("ch3_anim", true)
		l.add_child.call_deferred(anim)
	return true


# ─── 공용 모양 ──────────────────────────────────────────

## 굵기가 줄어드는 휜 가지 (점 목록을 따라 사다리꼴을 이어 그림). 윗면 점들을 돌려준다(집·등불 놓을 자리)
static func _limb(l: Node2D, pts: PackedVector2Array, w0: float, w1: float, col: Color, hi: Color) -> PackedVector2Array:
	var tops := PackedVector2Array()
	var n := pts.size()
	for i in n - 1:
		var k0 := float(i) / (n - 1)
		var k1 := float(i + 1) / (n - 1)
		var a := pts[i]
		var b := pts[i + 1]
		var h0 := lerpf(w0, w1, k0) * 0.5
		var h1 := lerpf(w0, w1, k1) * 0.5
		l.draw_colored_polygon(PackedVector2Array([a + Vector2(0, -h0), b + Vector2(0, -h1), b + Vector2(0, h1), a + Vector2(0, h0)]), col)
		tops.append(a + Vector2(0, -h0))
	tops.append(pts[n - 1] + Vector2(0, -w1 * 0.5))
	# 윗면 빛과 아래 그림자
	l.draw_polyline(tops, hi, 2.0)
	var bots := PackedVector2Array()
	for i in n:
		var k := float(i) / (n - 1)
		bots.append(pts[i] + Vector2(0, lerpf(w0, w1, k) * 0.5 - 1.0))
	l.draw_polyline(bots, col.darkened(0.35), 2.0)
	return tops


## a에서 b까지 위로 살짝 휜 점 목록
static func _curve(a: Vector2, b: Vector2, lift: float, n := 12) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var k := float(i) / n
		var p := a.lerp(b, k)
		p.y -= sin(k * PI) * lift
		out.append(p)
	return out


## 둥근 잎 덩어리 (원 여러 개)
static func _foliage(l: Node2D, c: Vector2, r: float, col: Color, rng: RandomNumberGenerator, n := 6) -> void:
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.3, 0.3)
		l.draw_circle(c + Vector2(cos(a) * r * 0.55, sin(a) * r * 0.35), r * rng.randf_range(0.45, 0.7), col)
	l.draw_circle(c, r * 0.62, col)


## 엘프 집 (꼬투리 모양 몸 + 잎 지붕 + 둥근 창·둥근 문). s = 크기 배율, 발밑(가지 윗면) 기준
static func _pod_house(l: Node2D, base: Vector2, s: float, col: Color, roof: Color, lit: float, rng: RandomNumberGenerator) -> void:
	var w := 22.0 * s
	var h := 18.0 * s
	var c := base + Vector2(0, -h * 0.5)
	# 몸 (타원)
	var body := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		body.append(c + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.55))
	l.draw_colored_polygon(body, col)
	# 판자 줄
	for i in 3:
		var yy := c.y - h * 0.2 + i * h * 0.22
		l.draw_line(Vector2(c.x - w * 0.42, yy), Vector2(c.x + w * 0.42, yy), col.darkened(0.25), 1.0)
	# 잎 지붕 (겹친 잎 삼각형)
	for i in 3:
		var yy := c.y - h * 0.35 - i * 4.0 * s
		var ww := w * (0.62 - i * 0.14)
		l.draw_colored_polygon(PackedVector2Array([Vector2(c.x - ww, yy + 3 * s), Vector2(c.x, yy - 7 * s), Vector2(c.x + ww, yy + 3 * s)]), roof.lightened(i * 0.04))
	l.draw_line(Vector2(c.x, c.y - h * 0.35 - 14 * s), Vector2(c.x + 2 * s, c.y - h * 0.35 - 19 * s), roof, maxf(1.0, s))
	# 둥근 창 (불빛)
	var wc := c + Vector2(w * 0.2, -h * 0.05)
	if lit > 0.0:
		l.draw_circle(wc, 7.0 * s, Color(WINDOW, 0.06 * lit))
	l.draw_circle(wc, 2.6 * s, col.darkened(0.5))
	l.draw_circle(wc, 2.0 * s, Color(WINDOW, 0.85 * lit) if lit > 0.0 else col.darkened(0.6))
	l.draw_line(wc + Vector2(-2 * s, 0), wc + Vector2(2 * s, 0), col.darkened(0.4), 1.0)
	# 둥근 문
	var dc := c + Vector2(-w * 0.18, h * 0.2)
	l.draw_circle(dc, 3.2 * s, col.darkened(0.45))
	l.draw_rect(Rect2(dc.x - 3.2 * s, dc.y, 6.4 * s, h * 0.3), col.darkened(0.45))
	if lit > 0.0 and rng.randf() < 0.5:
		l.draw_line(dc + Vector2(2.5 * s, -1), dc + Vector2(2.5 * s, h * 0.3), Color(WINDOW, 0.5 * lit), 1.0)


## 흔들다리 (현수선 + 판자 + 난간 밧줄)
static func _bridge(l: Node2D, a: Vector2, b: Vector2, sag: float, col: Color, rope: Color) -> void:
	var n := maxi(int(a.distance_to(b) / 6.0), 4)
	var prev := a
	var prev_r := a + Vector2(0, -9)
	for i in range(1, n + 1):
		var k := float(i) / n
		var p := a.lerp(b, k) + Vector2(0, sin(k * PI) * sag)
		var r := a.lerp(b, k) + Vector2(0, sin(k * PI) * sag * 0.7 - 9)
		l.draw_line(prev, p, rope, 1.0)
		l.draw_line(prev_r, r, rope, 1.0)
		if i < n:
			l.draw_rect(Rect2(p.x - 2, p.y - 1, 4, 2), col)
			if i % 2 == 0:
				l.draw_line(p, r, Color(rope, 0.7), 1.0)
		prev = p
		prev_r = r


## 위로 솟는 수액 줄기 (갈라지며 올라감) — 점 목록들을 돌려줌
static func _veins(rng: RandomNumberGenerator, x0: float, x1: float, y_bot: float, y_top: float, count: int) -> Array:
	var out: Array = []
	for i in count:
		var p := Vector2(rng.randf_range(x0, x1), y_bot)
		var pts := PackedVector2Array([p])
		var drift := rng.randf_range(-1.0, 1.0)
		while p.y > y_top:
			drift = clampf(drift + rng.randf_range(-0.5, 0.5), -1.2, 1.2)
			p += Vector2(drift * 6.0 + rng.randf_range(-3, 3), -rng.randf_range(9, 15))
			if p.x < x0 or p.x > x1:
				drift = -drift
				p.x = clampf(p.x, x0, x1)
			pts.append(p)
			if rng.randf() < 0.12 and out.size() < count * 4:
				# 곁가지 (위로 갈라져 나가며 가늘어짐)
				var q := p
				var side := PackedVector2Array([q])
				var dir := -1.0 if rng.randf() < 0.5 else 1.0
				for j in rng.randi_range(3, 7):
					q += Vector2(dir * rng.randf_range(4, 9), -rng.randf_range(5, 12))
					q.x = clampf(q.x, x0, x1)
					side.append(q)
				out.append(side)
		out.append(pts)
	return out


# ═══════════════════════════════════════════════════════
# elf — 세계수 마을
# ═══════════════════════════════════════════════════════

static func _elf_far(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).far
	var haze := Color("#1d3a2b")
	# 멀리 다른 줄기들 (안개 속, 거의 하늘색)
	for i in 2:
		var x := sp.x * (0.05 if i == 0 else 0.95) + rng.randf_range(-30, 30)
		var w := rng.randf_range(60, 90)
		l.draw_rect(Rect2(x - w * 0.5, -40, w, sp.y + 80), col.lerp(haze, 0.6))
		l.draw_rect(Rect2(x + w * 0.5 - 6, -40, 6, sp.y + 80), col.lerp(haze, 0.75))
	# 에일라흐의 줄기 (절벽처럼): 안개에 살짝 밝은 몸 + 짙은 골 + 달빛 테두리
	var bark := col.lerp(haze, 0.25)
	var cx := sp.x * rng.randf_range(0.42, 0.58)
	var tw := rng.randf_range(230, 280)
	var ph1 := rng.randf() * 10.0
	var ph2 := rng.randf() * 10.0
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y := -40.0
	while y <= sp.y + 40.0:
		left.append(Vector2(cx - tw * 0.5 + sin(y * 0.012 + ph1) * 10.0 + sin(y * 0.043 + ph2) * 4.0, y))
		right.append(Vector2(cx + tw * 0.5 + sin(y * 0.011 + ph2) * 10.0 + sin(y * 0.037 + ph1) * 4.0, y))
		y += 24.0
	var body := left.duplicate()
	for i in range(right.size() - 1, -1, -1):
		body.append(right[i])
	l.draw_colored_polygon(body, bark)
	# 그늘진 왼쪽 1/3
	var shade := PackedVector2Array()
	for p in left:
		shade.append(p)
	for i in range(left.size() - 1, -1, -1):
		shade.append(left[i] + Vector2(tw * 0.3, 0))
	l.draw_colored_polygon(shade, bark.darkened(0.22))
	var shade2 := PackedVector2Array()
	for p in left:
		shade2.append(p)
	for i in range(left.size() - 1, -1, -1):
		shade2.append(left[i] + Vector2(tw * 0.12, 0))
	l.draw_colored_polygon(shade2, bark.darkened(0.38))
	# 껍질 판: 세로로 긴 판과 그 사이의 깊은 골
	for i in 13:
		var bx := cx - tw * 0.46 + i * tw * 0.077 + rng.randf_range(-4, 4)
		var line := PackedVector2Array()
		var yy := -40.0
		var ph := rng.randf() * 6.0
		while yy <= sp.y + 40.0:
			line.append(Vector2(bx + sin(yy * 0.02 + ph) * 3.5 + sin(yy * 0.071 + ph * 2.0) * 1.5, yy))
			yy += 16.0
		l.draw_polyline(line, bark.darkened(0.5), rng.randf_range(2.5, 4.0))
		var line2 := PackedVector2Array()
		for p in line:
			line2.append(p + Vector2(3.0, 0))
		l.draw_polyline(line2, bark.lightened(0.07), 1.0)
		# 판을 가로지르는 짧은 금
		var cy := rng.randf_range(0, 60)
		while cy < sp.y:
			var cp := Vector2(bx + 4, cy)
			l.draw_line(cp, cp + Vector2(rng.randf_range(6, 12), rng.randf_range(-3, 3)), bark.darkened(0.4), 1.0)
			cy += rng.randf_range(50, 110)
	# 이끼 얼룩 (줄기 오른쪽 달빛 쪽)
	for i in int(sp.y / 60.0):
		var mp := Vector2(cx + rng.randf_range(-tw * 0.1, tw * 0.45), rng.randf_range(0, sp.y))
		for k in 4:
			l.draw_circle(mp + Vector2(rng.randf_range(-8, 8), rng.randf_range(-6, 6)), rng.randf_range(3, 6), Color(0.35, 0.55, 0.25, 0.22))
	# 옹이 구멍
	for i in int(sp.y / 260.0) + 1:
		var kc := Vector2(cx + rng.randf_range(-tw * 0.25, tw * 0.3), rng.randf_range(40, sp.y))
		l.draw_circle(kc, 11.0, bark.darkened(0.6))
		l.draw_arc(kc, 13.0, 0, TAU, 18, bark.darkened(0.3), 3.0)
		l.draw_arc(kc, 19.0, -0.8, 3.4, 16, bark.darkened(0.2), 2.0)
		l.draw_arc(kc, 13.0, -1.2, 0.4, 8, Color(0.85, 1.0, 0.7, 0.12), 1.0)
	# 달빛 테두리 (오른쪽)
	var rim := PackedVector2Array()
	for p in right:
		rim.append(p + Vector2(-2, 0))
	l.draw_polyline(rim, Color(0.85, 1.0, 0.75, 0.16), 3.0)
	var rim2 := PackedVector2Array()
	for p in right:
		rim2.append(p + Vector2(-7, 0))
	l.draw_polyline(rim2, Color(0.85, 1.0, 0.75, 0.05), 6.0)
	# 수액 줄기 (은은한 빛 — 맥동은 Anim이)
	var veins := _veins(rng, cx - tw * 0.38, cx + tw * 0.4, sp.y + 40.0, -40.0, 4)
	for v in veins:
		var pts: PackedVector2Array = v
		l.draw_polyline(pts, Color(SAP, 0.035), 5.0)
		l.draw_polyline(pts, Color(SAP, 0.08), 2.0)
		l.draw_polyline(pts, Color(0.9, 1.0, 0.75, 0.12), 1.0)
		anim.veins.append(pts)
	# 길 같은 가지들 (줄기 양옆으로) — 윗면에 길 등불이 줄지어 있다
	var by := rng.randf_range(90, 160)
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var limb := bark.darkened(0.12)
	while by < sp.y + 20.0:
		var root := Vector2(cx + side * tw * 0.42, by)
		var tip := Vector2(-80.0 if side < 0 else sp.x + 80.0, by - rng.randf_range(30, 70))
		var pts := _curve(root, tip, rng.randf_range(10, 30), 16)
		var tops := _limb(l, pts, 40.0, 12.0, limb, Color(0.55, 0.8, 0.4, 0.35))
		var n := tops.size()
		# 가지 밑동의 부푼 곳
		l.draw_circle(root + Vector2(-side * 6, 4), 22.0, limb)
		for j in range(1, n - 1):
			if j % 2 == 1:
				l.draw_line(pts[j] + Vector2(-4, -4), pts[j] + Vector2(4, 3), limb.darkened(0.3), 2.0)
		# 길 등불 (가지 윗면을 따라 작은 빛)
		for j in range(1, n - 1):
			if rng.randf() < 0.55:
				var lp := tops[j] + Vector2(rng.randf_range(-3, 3), -3)
				l.draw_rect(Rect2(lp - Vector2(0.5, 0.5), Vector2(1, 1)), Color(SAP, 0.75))
				l.draw_circle(lp, 3.0, Color(SAP, 0.08))
		# 가지 위의 작은 집과 아래 매달린 등불
		for j in range(2, n - 1, 3):
			if rng.randf() < 0.6:
				_pod_house(l, tops[j] + Vector2(0, 1), rng.randf_range(0.6, 0.85), Color("#2a2a1e").lerp(limb, 0.4), col.darkened(0.1), 0.9, rng)
			if rng.randf() < 0.6:
				var lp2 := pts[j] + Vector2(rng.randf_range(-6, 6), 10)
				anim.lanterns.append({"pos": lp2, "len": rng.randf_range(6, 14), "ph": rng.randf() * 6.0, "s": 0.6})
		# 가지 끝 잎
		for j in 3:
			_foliage(l, pts[n - 1 - j * 2] + Vector2(0, -14), rng.randf_range(16, 26), col.darkened(0.15), rng, 5)
		by += rng.randf_range(180, 240)
		side = -side
	# 꼭대기: 수관이 하늘을 덮는다 (방 맨 위쪽만)
	var canopy := Color("#06100b")
	var x := -60.0
	while x < sp.x + 60.0:
		var r := rng.randf_range(40, 72)
		l.draw_circle(Vector2(x, rng.randf_range(-60, -10)), r, canopy)
		x += r * 0.9
	x = -40.0
	while x < sp.x + 40.0:
		var p := Vector2(x, rng.randf_range(10, 34))
		l.draw_circle(p, rng.randf_range(10, 22), canopy)
		# 잎 아랫면의 빛나는 점 (반딧불 잎)
		if rng.randf() < 0.6:
			anim.sparks.append({"pos": p + Vector2(rng.randf_range(-8, 8), rng.randf_range(6, 14)), "ph": rng.randf() * 6.0, "col": SAP})
		x += rng.randf_range(16, 30)
	# 안개: 화면 높이마다 아래쪽으로 짙어지는 띠 (깊이감)
	var my := 220.0
	while my < sp.y + 40.0:
		for k in 5:
			l.draw_rect(Rect2(-40, my + k * 14, sp.x + 80, 14), Color(0.6, 0.95, 0.6, 0.012 + k * 0.009))
		my += 368.0


static func _elf_mid(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).mid
	var bark := col.darkened(0.12)
	var wood := Color("#2b2216")
	var moss := Color(0.42, 0.62, 0.26, 0.55)
	# 화면을 가로지르는 굵은 가지 (높이마다 하나)
	var by := rng.randf_range(150, 230)
	var prev_tips: Array = []
	while by < sp.y + 40.0:
		var from_left := rng.randf() < 0.5
		var a := Vector2(-70.0 if from_left else sp.x + 70.0, by + rng.randf_range(-20, 30))
		var b := Vector2(a.x + (1.0 if from_left else -1.0) * rng.randf_range(sp.x * 0.45, sp.x * 0.75), by - rng.randf_range(0, 50))
		var pts := _curve(a, b, rng.randf_range(10, 26), 18)
		var tops := _limb(l, pts, 56.0, 22.0, bark, moss)
		var n := tops.size()
		# 껍질 무늬와 이끼 늘어짐
		for j in range(1, n - 1):
			if j % 2 == 0:
				l.draw_line(pts[j] + Vector2(-6, -8), pts[j] + Vector2(6, 6), bark.darkened(0.35), 2.0)
			if rng.randf() < 0.4:
				var mp := tops[j]
				l.draw_line(mp + Vector2(0, 2), mp + Vector2(0, 2 + rng.randf_range(3, 9)), Color(moss, 0.4), 2.0)
		# 아래로 늘어진 이끼 수염
		for j in range(1, n - 1):
			if rng.randf() < 0.35:
				var bp := pts[j] + Vector2(rng.randf_range(-4, 4), lerpf(28.0, 11.0, float(j) / n))
				l.draw_line(bp, bp + Vector2(rng.randf_range(-2, 2), rng.randf_range(8, 20)), Color(0.3, 0.45, 0.2, 0.5), 1.0)
		# 집 1~2채 (따뜻한 나무 + 잎 지붕 + 밝은 둥근 창)
		var spots := [int(n * 0.35), int(n * 0.7)]
		for si in spots.size():
			var j: int = spots[si]
			if rng.randf() < 0.85:
				var hs := rng.randf_range(1.3, 1.7)
				_pod_house(l, tops[j] + Vector2(0, 2), hs, wood, Color("#1c3a22"), 1.0, rng)
				anim.windows.append({"pos": tops[j] + Vector2(4.4 * hs, -9.0 * hs), "ph": rng.randf() * 6.0})
		# 매달린 씨앗 꼬투리 등불
		for j in range(2, n - 2, 4):
			anim.lanterns.append({"pos": pts[j] + Vector2(rng.randf_range(-5, 5), 18), "len": rng.randf_range(10, 26), "ph": rng.randf() * 6.0, "s": 1.0})
		# 가지 끝 잎 덩어리 (짙은 잎 + 밝은 잎끝)
		var tipc := pts[pts.size() - 1] + Vector2(0, -10)
		_foliage(l, tipc, rng.randf_range(24, 36), col.darkened(0.1), rng, 7)
		for k in 6:
			var lp := tipc + Vector2(rng.randf_range(-26, 26), rng.randf_range(-20, 6))
			l.draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(5, -3), lp + Vector2(2, 2)]), Color(0.35, 0.55, 0.25, 0.6))
		# 앞 가지 끝과 이 가지를 흔들다리로
		if not prev_tips.is_empty() and rng.randf() < 0.85:
			var pa: Vector2 = prev_tips[0]
			var pb := tops[int(n * 0.55)]
			if absf(pa.y - pb.y) < 140.0:
				_bridge(l, pa, pb, rng.randf_range(16, 30), wood.lightened(0.15), Color(0.6, 0.52, 0.34, 0.7))
		prev_tips = [tops[n - 2]]
		by += rng.randf_range(210, 290)
	# 바람길 (흐르는 띠)
	var ry := rng.randf_range(60, 120)
	while ry < sp.y:
		anim.ribbons.append({"y": ry, "amp": rng.randf_range(8, 18), "freq": rng.randf_range(0.008, 0.014), "speed": rng.randf_range(50, 80), "ph": rng.randf() * 6.0, "w": sp.x})
		ry += rng.randf_range(110, 190)


static func _elf_near(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).near
	# 위에서 늘어진 잎 덩어리 + 덩굴
	var x := rng.randf_range(0, 120)
	while x < sp.x:
		var top := rng.randf_range(-40, 10)
		_foliage(l, Vector2(x, top), rng.randf_range(30, 50), col, rng, 7)
		for j in rng.randi_range(1, 3):
			anim.vines.append({"pos": Vector2(x + rng.randf_range(-30, 30), top + 20), "len": rng.randf_range(40, 120), "ph": rng.randf() * 6.0, "col": col.lightened(0.05)})
		x += rng.randf_range(200, 340)
	# 아래쪽: 굵은 가지 실루엣과 고사리 덤불 (방 바닥 높이마다)
	var gy := 300.0
	while gy < sp.y + 60.0:
		var xx := rng.randf_range(-40, 80)
		while xx < sp.x:
			var w := rng.randf_range(80, 160)
			_foliage(l, Vector2(xx + w * 0.5, gy + rng.randf_range(10, 40)), rng.randf_range(26, 40), col, rng, 6)
			# 고사리 잎
			for k in 5:
				var a := -PI * 0.5 + (k - 2) * 0.42
				var base := Vector2(xx + w * 0.5, gy)
				l.draw_line(base, base + Vector2(cos(a), sin(a)) * rng.randf_range(20, 34), col.lightened(0.04), 3.0)
			xx += w + rng.randf_range(160, 320)
		gy += 368.0
	# 반딧불 몇 마리 (가까운 층에서 크게)
	for i in int(sp.x * sp.y / 60000.0) + 3:
		anim.sparks.append({"pos": Vector2(rng.randf() * sp.x, rng.randf() * sp.y), "ph": rng.randf() * 6.0, "col": SAP, "drift": true})


static func _elf_front(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var dark := Color(0.012, 0.025, 0.015, 0.94)
	var x := rng.randf_range(0, 260)
	while x < sp.x:
		var r := rng.randf_range(18, 36)
		var b := sp.y + 30.0
		l.draw_circle(Vector2(x, b - r * 0.3), r, dark)
		l.draw_circle(Vector2(x + r * 0.9, b - r * 0.1), r * 0.8, dark)
		# 큰 잎 하나
		var lp := Vector2(x - r * 0.4, b - r * 1.1)
		l.draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(-14, -10), lp + Vector2(-30, -6), lp + Vector2(-14, 2)]), dark)
		x += rng.randf_range(300, 560)
	var cx := rng.randf_range(80, 380)
	while cx < sp.x:
		anim.vines.append({"pos": Vector2(cx, -20), "len": rng.randf_range(40, 90), "ph": rng.randf() * 6.0, "col": dark, "w": 3.0})
		cx += rng.randf_range(360, 700)


# ═══════════════════════════════════════════════════════
# elf_deep — 뿌리 동굴
# ═══════════════════════════════════════════════════════

## 아치처럼 휜 뿌리 (두꺼운 띠)
static func _root_arch(l: Node2D, a: Vector2, b: Vector2, lift: float, w: float, col: Color) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 17:
		var k := float(i) / 16.0
		var p := a.lerp(b, k)
		p.y -= sin(k * PI) * lift
		pts.append(p)
	l.draw_polyline(pts, col, w)
	var hi := PackedVector2Array()
	for p in pts:
		hi.append(p + Vector2(0, -w * 0.38))
	l.draw_polyline(hi, col.lightened(0.06), maxf(w * 0.12, 1.0))
	var lo := PackedVector2Array()
	for p in pts:
		lo.append(p + Vector2(0, w * 0.4))
	l.draw_polyline(lo, col.darkened(0.3), maxf(w * 0.1, 1.0))
	return pts


static func _mushroom(l: Node2D, base: Vector2, s: float, stem: Color, cap: Color, glow: float) -> void:
	l.draw_rect(Rect2(base.x - 1.5 * s, base.y - 8 * s, 3 * s, 8 * s), stem)
	var capp := PackedVector2Array()
	for i in 9:
		var a := PI + PI * i / 8.0
		capp.append(base + Vector2(cos(a) * 7 * s, -8 * s + sin(a) * 5 * s))
	l.draw_colored_polygon(capp, cap)
	if glow > 0.0:
		# 갓 아래 주름이 빛나고, 갓 위엔 빛 점
		l.draw_circle(base + Vector2(0, -7 * s), 9.0 * s, Color(MUSH, 0.06 * glow))
		l.draw_line(base + Vector2(-6.5 * s, -8 * s), base + Vector2(6.5 * s, -8 * s), Color(MUSH, 0.9 * glow), maxf(1.0, s))
		l.draw_line(base + Vector2(-1.5 * s, -8 * s), base + Vector2(-1.5 * s, -1 * s), Color(MUSH, 0.25 * glow), 1.0)
		l.draw_circle(base + Vector2(-2.5 * s, -10.5 * s), 0.9 * s, Color(MUSH, 0.7 * glow))
		l.draw_circle(base + Vector2(2.5 * s, -11 * s), 0.7 * s, Color(MUSH, 0.6 * glow))


## 버섯 무더기 (큰 것 하나 + 작은 것들)
static func _mush_cluster(l: Node2D, base: Vector2, s: float, col: Color, rng: RandomNumberGenerator) -> void:
	var cap := Color("#15524a").lerp(col, 0.3)
	_mushroom(l, base, s, col.lightened(0.12), cap, 1.0)
	for k in rng.randi_range(2, 4):
		var off := Vector2(rng.randf_range(-10, 10) * s, rng.randf_range(-1, 1))
		_mushroom(l, base + off, s * rng.randf_range(0.4, 0.7), col.lightened(0.1), cap.lightened(0.05), 0.8)


static func _deep_far(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).far
	var wall := col.darkened(0.45)
	l.draw_rect(Rect2(-60, -60, sp.x + 120, sp.y + 120), wall)
	# 동굴 벽의 얼룩 (흙·바위 덩어리) + 이끼 빛 점
	for i in int(sp.x * sp.y / 7000.0):
		var p := Vector2(rng.randf() * sp.x, rng.randf() * sp.y)
		l.draw_circle(p, rng.randf_range(10, 40), wall.lerp(col, rng.randf_range(0.0, 0.5)))
	for i in int(sp.x * sp.y / 2500.0):
		var p := Vector2(rng.randf() * sp.x, rng.randf() * sp.y)
		l.draw_rect(Rect2(p, Vector2.ONE), Color(MUSH, rng.randf_range(0.08, 0.3)))
	# 거대한 뿌리 아치들 (안개 낀 밝은 갈색-청록)
	var root := col.lerp(Color("#2a3a36"), 0.6)
	var y := rng.randf_range(80, 160)
	while y < sp.y + 80.0:
		var a := Vector2(rng.randf_range(-120, sp.x * 0.3), y + rng.randf_range(40, 120))
		var b := Vector2(a.x + rng.randf_range(sp.x * 0.5, sp.x * 0.9), y + rng.randf_range(40, 140))
		var pts := _root_arch(l, a, b, rng.randf_range(90, 180), rng.randf_range(22, 40), root)
		for j in range(1, pts.size() - 1):
			# 뿌리 위 빛이끼
			if rng.randf() < 0.5:
				var lp := pts[j] + Vector2(rng.randf_range(-6, 6), -rng.randf_range(8, 14))
				l.draw_rect(Rect2(lp, Vector2(2, 1)), Color(MUSH, 0.45))
		for j in range(2, pts.size() - 2, 3):
			if rng.randf() < 0.55:
				var mp := pts[j] + Vector2(rng.randf_range(-6, 6), -10)
				_mush_cluster(l, mp, rng.randf_range(0.7, 1.0), root, rng)
				anim.mush.append({"pos": mp + Vector2(0, -8), "r": rng.randf_range(12, 20), "ph": rng.randf() * 6.0})
		y += rng.randf_range(150, 240)
	# 늘어진 잔뿌리
	var x := rng.randf_range(0, 80)
	while x < sp.x:
		var len := rng.randf_range(40, 140)
		var line := PackedVector2Array()
		for i in 8:
			line.append(Vector2(x + sin(i * 0.9 + x) * 3.0, -20 + len * i / 7.0))
		l.draw_polyline(line, root.darkened(0.2), 2.0)
		x += rng.randf_range(50, 130)
	# 바닥 쪽 청록 안개
	var my := 230.0
	while my < sp.y + 40.0:
		for k in 5:
			l.draw_rect(Rect2(-40, my + k * 14, sp.x + 80, 14), Color(0.3, 1.0, 0.85, 0.01 + k * 0.008))
		my += 368.0


static func _deep_mid(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).mid
	var root := col.lerp(Color("#1c2622"), 0.5)
	var y := rng.randf_range(160, 240)
	while y < sp.y + 60.0:
		var a := Vector2(rng.randf_range(-100, sp.x * 0.2), y + rng.randf_range(60, 140))
		var b := Vector2(a.x + rng.randf_range(sp.x * 0.4, sp.x * 0.7), y + rng.randf_range(60, 160))
		var pts := _root_arch(l, a, b, rng.randf_range(80, 150), rng.randf_range(34, 54), root)
		# 껍질 마디
		for j in range(1, pts.size() - 1, 2):
			l.draw_line(pts[j] + Vector2(-3, -12), pts[j] + Vector2(3, 10), root.darkened(0.35), 2.0)
		for j in range(3, pts.size() - 2, 4):
			if rng.randf() < 0.75:
				var mp := pts[j] + Vector2(0, -18)
				_mush_cluster(l, mp, rng.randf_range(1.2, 1.8), root, rng)
				anim.mush.append({"pos": mp + Vector2(0, -12), "r": rng.randf_range(20, 30), "ph": rng.randf() * 6.0})
		y += rng.randf_range(200, 300)
	# 빛 웅덩이 (바닥 높이마다)
	var gy := 330.0
	while gy < sp.y + 40.0:
		for i in 2:
			var pc := Vector2(rng.randf_range(40, sp.x - 40), gy + rng.randf_range(0, 20))
			var w := rng.randf_range(50, 90)
			l.draw_rect(Rect2(pc.x - w * 0.5, pc.y, w, 3), Color(MUSH, 0.25))
			l.draw_rect(Rect2(pc.x - w * 0.4, pc.y + 3, w * 0.8, 2), Color(MUSH, 0.12))
			anim.mush.append({"pos": pc, "r": w * 0.6, "ph": rng.randf() * 6.0})
		gy += 368.0
	# 빛 구슬이 맺힌 실 (반딧불 애벌레) — 천장에서
	var x := rng.randf_range(20, 120)
	while x < sp.x:
		anim.threads.append({"pos": Vector2(x, -10), "len": rng.randf_range(50, 160), "ph": rng.randf() * 6.0})
		x += rng.randf_range(40, 110)


static func _deep_near(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).near
	# 아래: 큰 버섯 실루엣 (주름이 빛남)
	var gy := 320.0
	while gy < sp.y + 60.0:
		var x := rng.randf_range(-20, 160)
		while x < sp.x:
			var s := rng.randf_range(2.6, 4.2)
			var base := Vector2(x, gy + rng.randf_range(0, 40))
			_mushroom(l, base, s, col, col.lightened(0.03), 0.0)
			anim.gills.append({"pos": base + Vector2(0, -8 * s), "w": 6.0 * s, "ph": rng.randf() * 6.0})
			x += rng.randf_range(260, 460)
		gy += 368.0
	# 위: 늘어진 뿌리 덩어리
	var cx := rng.randf_range(40, 200)
	while cx < sp.x:
		var pts := PackedVector2Array()
		var len := rng.randf_range(40, 110)
		for i in 9:
			pts.append(Vector2(cx + sin(i * 0.8 + cx) * 6.0, -20 + len * i / 8.0))
		l.draw_polyline(pts, col, rng.randf_range(8, 16))
		cx += rng.randf_range(160, 320)


static func _deep_front(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, _anim: Anim) -> void:
	var dark := Color(0.008, 0.02, 0.022, 0.94)
	var x := rng.randf_range(0, 280)
	while x < sp.x:
		var w := rng.randf_range(80, 170)
		var b := sp.y + 30.0
		var pts := PackedVector2Array()
		for i in 9:
			var k := float(i) / 8.0
			pts.append(Vector2(x + w * k, b - sin(k * PI) * rng.randf_range(26, 46)))
		pts.append(Vector2(x + w, b + 20))
		pts.append(Vector2(x, b + 20))
		l.draw_colored_polygon(pts, dark)
		x += w + rng.randf_range(260, 520)


# ═══════════════════════════════════════════════════════
# blight — 흰 역병 (바깥 신들: 흰색·무채색·기하학)
# ═══════════════════════════════════════════════════════

## 하얗게 굳은 나무: 줄기는 곧고 가지는 60도로만 꺾인다
static func _petrified_tree(l: Node2D, base: Vector2, h: float, w: float, col: Color, line: Color, rng: RandomNumberGenerator, cracks: Array) -> void:
	var top := base + Vector2(rng.randf_range(-8, 8), -h)
	l.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.5, 0), top + Vector2(-w * 0.18, 0), top + Vector2(w * 0.18, 0), base + Vector2(w * 0.5, 0)]), col)
	l.draw_line(base + Vector2(w * 0.3, 0), top + Vector2(w * 0.1, 0), col.lightened(0.12), 2.0)
	# 가지
	for i in rng.randi_range(3, 5):
		var k := rng.randf_range(0.35, 0.9)
		var p := base.lerp(top, k)
		var dir := -1.0 if i % 2 == 0 else 1.0
		var ang := -PI * 0.5 + dir * PI / 3.0
		var len := rng.randf_range(h * 0.15, h * 0.32)
		var q := p + Vector2(cos(ang), sin(ang)) * len
		l.draw_line(p, q, col, maxf(w * 0.18, 2.0))
		var q2 := q + Vector2(cos(-PI * 0.5), sin(-PI * 0.5)) * len * 0.4
		l.draw_line(q, q2, col, maxf(w * 0.1, 1.0))
	# 기하학 금 (직선 + 60도 꺾임)
	var c := base + Vector2(0, -h * rng.randf_range(0.2, 0.5))
	var pts := PackedVector2Array([c])
	var ang2 := -PI * 0.5
	for j in 6:
		ang2 += (PI / 3.0) * (1 if rng.randf() < 0.5 else -1)
		ang2 = clampf(ang2, -PI * 0.95, -PI * 0.05)
		c += Vector2(cos(ang2), sin(ang2)) * rng.randf_range(8, 18)
		c.x = clampf(c.x, base.x - w * 0.4, base.x + w * 0.4)
		pts.append(c)
	l.draw_polyline(pts, line, 1.0)
	cracks.append(pts)


## 육각 수정 (세로로 긴 육각기둥 + 빛나는 면)
static func _crystal(l: Node2D, base: Vector2, h: float, w: float, ang: float, col: Color, hi: Color) -> void:
	var d := Vector2(sin(ang), -cos(ang))
	var n := Vector2(d.y, -d.x) * -1.0
	var tip := base + d * h
	var shoulder := base + d * h * 0.78
	var pts := PackedVector2Array([base - n * w * 0.5, shoulder - n * w * 0.5, tip, shoulder + n * w * 0.5, base + n * w * 0.5])
	l.draw_colored_polygon(pts, col)
	l.draw_colored_polygon(PackedVector2Array([base, shoulder, tip, shoulder + n * w * 0.5, base + n * w * 0.5]), col.lightened(0.12))
	l.draw_line(base, tip, hi, 1.0)


static func _blight_far(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).far
	var gy := 300.0
	while gy < sp.y + 120.0:
		var x := rng.randf_range(-20, 60)
		while x < sp.x:
			_petrified_tree(l, Vector2(x, gy + rng.randf_range(0, 60)), rng.randf_range(160, 260), rng.randf_range(18, 30), col.lightened(0.1), Color(WHITE, 0.12), rng, anim.cracks)
			x += rng.randf_range(70, 150)
		# 땅에서 솟은 수정 첨탑
		for i in 3:
			var cxp := rng.randf_range(0, sp.x)
			_crystal(l, Vector2(cxp, gy + 70), rng.randf_range(80, 150), rng.randf_range(16, 26), rng.randf_range(-0.2, 0.2), col.lightened(0.14), Color(WHITE, 0.18))
		l.draw_rect(Rect2(-40, gy + 60, sp.x + 80, 400), col.darkened(0.1))
		gy += 368.0


static func _blight_mid(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, anim: Anim) -> void:
	var col: Color = _th(l).mid
	var gy := 320.0
	while gy < sp.y + 120.0:
		var x := rng.randf_range(0, 120)
		while x < sp.x:
			# 반쯤 굳은 나무: 아래는 아직 나무색, 위는 흰 돌
			var base := Vector2(x, gy + rng.randf_range(10, 50))
			var h := rng.randf_range(180, 280)
			var w := rng.randf_range(28, 42)
			l.draw_rect(Rect2(base.x - w * 0.5, base.y - h * 0.3, w, h * 0.3), Color("#1e1a16").lerp(col, 0.4))
			_petrified_tree(l, base + Vector2(0, -h * 0.28), h * 0.72, w, col.lightened(0.16), Color(WHITE, 0.3), rng, anim.cracks)
			# 경계에 낀 수정
			for k in 3:
				_crystal(l, base + Vector2(rng.randf_range(-w * 0.5, w * 0.5), -h * 0.3), rng.randf_range(10, 22), rng.randf_range(5, 8), rng.randf_range(-0.6, 0.6), col.lightened(0.3), Color(WHITE, 0.5))
			x += rng.randf_range(160, 280)
		# 수정 무더기
		for i in 4:
			var cp := Vector2(rng.randf_range(0, sp.x), gy + 60)
			for k in rng.randi_range(3, 5):
				_crystal(l, cp + Vector2(rng.randf_range(-14, 14), 0), rng.randf_range(20, 54), rng.randf_range(8, 14), rng.randf_range(-0.5, 0.5), col.lightened(0.22), Color(WHITE, 0.4))
		gy += 368.0
	# 떠다니는 기하학 조각
	for i in int(sp.x * sp.y / 50000.0) + 4:
		anim.shards.append({"pos": Vector2(rng.randf() * sp.x, rng.randf() * sp.y), "s": rng.randf_range(3, 7), "ph": rng.randf() * 6.0, "n": 3 if rng.randf() < 0.6 else 6})


static func _blight_near(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, _anim: Anim) -> void:
	var col: Color = _th(l).near
	var gy := 330.0
	while gy < sp.y + 80.0:
		var x := rng.randf_range(-20, 160)
		while x < sp.x:
			var cp := Vector2(x, gy + rng.randf_range(20, 50))
			for k in rng.randi_range(2, 4):
				_crystal(l, cp + Vector2(rng.randf_range(-20, 20), 0), rng.randf_range(30, 80), rng.randf_range(12, 22), rng.randf_range(-0.4, 0.4), col.lightened(0.04), Color(WHITE, 0.22))
			x += rng.randf_range(240, 420)
		gy += 368.0
	# 위에서 내려온 흰 덩굴(직선 마디)
	var cx := rng.randf_range(60, 260)
	while cx < sp.x:
		var p := Vector2(cx, -20)
		var pts := PackedVector2Array([p])
		for i in rng.randi_range(4, 7):
			p += Vector2(rng.randf_range(-14, 14), rng.randf_range(14, 24))
			pts.append(p)
		l.draw_polyline(pts, col.lightened(0.05), 4.0)
		l.draw_polyline(pts, Color(WHITE, 0.15), 1.0)
		cx += rng.randf_range(200, 420)


static func _blight_front(l: Node2D, sp: Vector2, rng: RandomNumberGenerator, _anim: Anim) -> void:
	var dark := Color(0.02, 0.02, 0.026, 0.94)
	var x := rng.randf_range(0, 300)
	while x < sp.x:
		var b := sp.y + 30.0
		for k in rng.randi_range(2, 3):
			var h := rng.randf_range(34, 70)
			var cxp := x + rng.randf_range(-24, 24)
			var w := rng.randf_range(14, 24)
			l.draw_colored_polygon(PackedVector2Array([Vector2(cxp - w * 0.5, b), Vector2(cxp - w * 0.5, b - h * 0.75), Vector2(cxp, b - h), Vector2(cxp + w * 0.5, b - h * 0.75), Vector2(cxp + w * 0.5, b)]), dark)
			l.draw_line(Vector2(cxp, b - h), Vector2(cxp, b - h + 10), Color(WHITE, 0.35), 1.0)
		x += rng.randf_range(320, 600)


# ═══════════════════════════════════════════════════════
# 움직이는 것 (층의 자식)
# ═══════════════════════════════════════════════════════

class Anim extends Node2D:
	var depth := 0
	var veins: Array = [] ## PackedVector2Array — 수액 맥동
	var lanterns: Array = [] ## {pos, len, ph, s} — 매달린 씨앗 꼬투리 등불
	var windows: Array = [] ## {pos, ph} — 창 불빛 일렁임
	var ribbons: Array = [] ## {y, amp, freq, speed, ph, w} — 바람길 띠
	var vines: Array = [] ## {pos, len, ph, col, w} — 흔들리는 덩굴
	var sparks: Array = [] ## {pos, ph, col, drift} — 반딧불 잎·반딧불
	var mush: Array = [] ## {pos, r, ph} — 버섯 빛 맥동
	var gills: Array = [] ## {pos, w, ph} — 큰 버섯 주름 빛
	var threads: Array = [] ## {pos, len, ph} — 빛 구슬 실
	var cracks: Array = [] ## PackedVector2Array — 역병 금 맥동
	var shards: Array = [] ## {pos, s, ph, n} — 떠다니는 기하학 조각
	var _t := 0.0

	func has_items() -> bool:
		return not (veins.is_empty() and lanterns.is_empty() and windows.is_empty() and ribbons.is_empty() and vines.is_empty() \
			and sparks.is_empty() and mush.is_empty() and gills.is_empty() and threads.is_empty() and cracks.is_empty() and shards.is_empty())

	func _ready() -> void:
		_t = randf() * 10.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var t := _t
		# 수액 맥동: 줄기를 따라 위로 올라가는 빛 덩어리
		for i in veins.size():
			var pts: PackedVector2Array = veins[i]
			if pts.size() < 2:
				continue
			var seg := fmod(t * 1.2 + i * 2.3, float(pts.size() + 6)) - 3.0
			for j in range(maxi(int(seg) - 2, 0), mini(int(seg) + 2, pts.size() - 1)):
				var k := 1.0 - absf(float(j) - seg) / 2.5
				if k <= 0.0:
					continue
				draw_line(pts[j], pts[j + 1], Color(SAP, 0.35 * k), 3.0)
				draw_line(pts[j], pts[j + 1], Color(1, 1, 0.9, 0.5 * k), 1.0)
		# 창 불빛 일렁임
		for w in windows:
			var p: Vector2 = w.pos
			var k2 := 0.5 + 0.5 * sin(t * 1.3 + float(w.ph)) * sin(t * 2.9 + float(w.ph))
			draw_circle(p, 16.0, Color(WINDOW, 0.03 + 0.03 * k2))
		# 매달린 등불
		for lt in lanterns:
			var top: Vector2 = lt.pos
			var ln: float = lt.len
			var s: float = lt.s
			var sway := sin(t * 1.4 + float(lt.ph)) * 2.0 * s
			var c := top + Vector2(sway, ln)
			draw_line(top, c, Color(0.5, 0.45, 0.3, 0.6), 1.0)
			var glow := 0.75 + 0.25 * sin(t * 3.0 + float(lt.ph) * 2.0)
			draw_circle(c + Vector2(0, 4 * s), 12.0 * s, Color(SAP, 0.06 * glow))
			draw_circle(c + Vector2(0, 4 * s), 6.0 * s, Color(SAP, 0.12 * glow))
			# 씨앗 꼬투리 모양
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, 0), c + Vector2(3.5 * s, 3 * s), c + Vector2(2.5 * s, 7 * s), c + Vector2(0, 9 * s), c + Vector2(-2.5 * s, 7 * s), c + Vector2(-3.5 * s, 3 * s)]), Color(0.55, 0.75, 0.3, 0.9))
			draw_rect(Rect2(c.x - 1.5 * s, c.y + 2.5 * s, 3 * s, 4 * s), Color(0.9, 1.0, 0.6, glow))
		# 바람길: 흐르는 연한 띠 (지나가는 구간만 밝음)
		for r in ribbons:
			var y0: float = r.y
			var amp: float = r.amp
			var fq: float = r.freq
			var spd: float = r.speed
			var ph: float = r.ph
			var w: float = r.w
			var head := fmod(t * spd + ph * 100.0, w + 400.0) - 200.0
			var prev := Vector2.INF
			var x := head - 220.0
			while x <= head:
				var p := Vector2(x, y0 + sin(x * fq + t * 1.3 + ph) * amp)
				if prev != Vector2.INF:
					var k3 := 1.0 - (head - x) / 220.0
					draw_line(prev, p, Color(0.88, 1.0, 0.85, 0.22 * k3), 2.0)
					draw_line(prev + Vector2(0, 5), p + Vector2(0, 5 + sin(x * 0.05) * 2.0), Color(0.88, 1.0, 0.85, 0.09 * k3), 1.0)
				prev = p
				x += 10.0
		# 덩굴
		for v in vines:
			var p0: Vector2 = v.pos
			var ln2: float = v.len
			var col: Color = v.col
			var wd: float = v.get("w", 2.0)
			var pts2 := PackedVector2Array()
			for i in 8:
				var k4 := float(i) / 7.0
				pts2.append(p0 + Vector2(sin(t * 0.9 + float(v.ph) + k4 * 2.0) * 6.0 * k4 * k4, ln2 * k4))
			draw_polyline(pts2, col, wd)
			for i in range(2, 8, 2):
				var lp: Vector2 = pts2[i]
				draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(4, 2), lp + Vector2(1, 4)]), col)
				draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(-4, 1), lp + Vector2(-1, 4)]), col)
		# 반딧불
		for s2 in sparks:
			var p2: Vector2 = s2.pos
			var ph2: float = s2.ph
			if bool(s2.get("drift", false)):
				p2 += Vector2(sin(t * 0.5 + ph2) * 18.0, cos(t * 0.37 + ph2 * 1.3) * 12.0)
			var k5 := clampf(sin(t * 1.7 + ph2 * 3.0) * 1.4, 0.0, 1.0)
			var c2: Color = s2.col
			draw_circle(p2, 5.0, Color(c2, 0.08 * k5))
			draw_rect(Rect2(p2 - Vector2.ONE, Vector2(2, 2)), Color(c2, 0.85 * k5))
		# 버섯 빛
		for m in mush:
			var k6 := 0.6 + 0.4 * sin(t * 0.9 + float(m.ph))
			var mr: float = m.r
			draw_circle(m.pos, mr, Color(MUSH, 0.05 * k6))
			draw_circle(m.pos, mr * 0.45, Color(MUSH, 0.07 * k6))
		for g in gills:
			var k7 := 0.5 + 0.5 * sin(t * 0.7 + float(g.ph))
			var gp: Vector2 = g.pos
			var gw: float = g.w
			draw_line(gp + Vector2(-gw, 0), gp + Vector2(gw, 0), Color(MUSH, 0.25 + 0.3 * k7), 2.0)
			draw_circle(gp + Vector2(0, 6), gw * 1.4, Color(MUSH, 0.03 + 0.03 * k7))
		# 빛 구슬 실: 실을 따라 구슬이 천천히 내려옴
		for th in threads:
			var tp: Vector2 = th.pos
			var tl: float = th.len
			draw_line(tp, tp + Vector2(0, tl), Color(MUSH, 0.10), 1.0)
			for i in 3:
				var yy := fmod(t * 6.0 + float(th.ph) * 20.0 + i * tl / 3.0, tl)
				var k8 := sin(yy / tl * PI)
				draw_circle(tp + Vector2(0, yy), 1.5, Color(MUSH, 0.8 * k8))
				draw_circle(tp + Vector2(0, yy), 4.0, Color(MUSH, 0.1 * k8))
		# 역병 금: 흰빛이 직선 마디를 따라 번졌다 사그라듦
		for i in cracks.size():
			var cp: PackedVector2Array = cracks[i]
			var k9 := clampf(sin(t * 0.8 + i * 1.9) * 2.0 - 1.0, 0.0, 1.0)
			if k9 > 0.0:
				draw_polyline(cp, Color(WHITE, 0.5 * k9), 1.0)
				draw_polyline(cp, Color(WHITE, 0.12 * k9), 3.0)
		# 떠다니는 기하학 조각 (천천히 돌며 깜빡임)
		for sh in shards:
			var sp2: Vector2 = sh.pos
			var ph3: float = sh.ph
			sp2 += Vector2(sin(t * 0.3 + ph3) * 10.0, sin(t * 0.45 + ph3 * 2.0) * 8.0)
			var n: int = sh.n
			var sz: float = sh.s
			var pts3 := PackedVector2Array()
			for k in n:
				var a := t * 0.6 + ph3 + TAU * k / n
				pts3.append(sp2 + Vector2(cos(a), sin(a)) * sz)
			var al := 0.25 + 0.2 * sin(t * 2.0 + ph3)
			draw_colored_polygon(pts3, Color(WHITE, al * 0.5))
			pts3.append(pts3[0])
			draw_polyline(pts3, Color(WHITE, al + 0.2), 1.0)
