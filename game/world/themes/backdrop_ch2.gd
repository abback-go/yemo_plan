extends RefCounted
## 2장 지역 배경 (RoomBackdrop가 부름) — 황도 아르덴. INARI풍: 화면을 압도하는 거대한 배경 구조물 + 어두운 저채도 + 강조색 빛.
##   kingdom / kingdom_night  먼 층: 황궁(탑·깃발)·대성당 첨탑·시계탑(도는 바늘)·수도교 / 중간: 지붕의 바다(굴뚝 연기·불 켜진 창·장식 깃발 줄)
##                            가까운 층: 성벽·버팀 아치·가로등 / 전경: 통·상자 실루엣, 위로 처마와 등불 줄
##   kingdom_in               먼 층: 거대한 고딕 창(스테인드글라스)과 빛줄기·궁륭 / 중간: 대리석 기둥·은사자 깃발·샹들리에 / 가까운: 기둥·늑재
##   sewer                    먼 층: 끝없는 벽돌 아치와 빛나는 청록 물길·천장 쇠창살 빛 / 중간: 거대한 관·밸브·쏟아지는 물 / 전경: 떨어지는 물방울
##   starfall                 먼 층: 무너진 성곽·부러진 탑·거대한 별 수정·운석 구덩이의 보랏빛 / 중간: 기울어진 집 잔해·떠 있는 돌 조각 / 가까운: 바위·수정
## 방 ID(조상 Room 노드)에 따라 먼 층의 상징물 순서가 바뀐다 (시계 구역이면 시계탑이 먼저, 대성당이면 대성당이 먼저 …).

const KArt := preload("res://world/entities/ch2/k_art.gd")
const Kit := preload("res://world/themes/backdrop_kit.gd")
const MINE := ["kingdom", "kingdom_roof", "kingdom_night", "kingdom_in", "sewer", "starfall"]
const ROOF := Color("#5a2226")
const WINDOW_LIT := Color("#ffb45a")
const GLASS := [Color("#b8323e"), Color("#d8a840"), Color("#3a5ab8"), Color("#7a3ab0"), Color("#3a8a7a")]


## 움직이는 층(예전 is_animated): kingdom·night 먼·중간 / kingdom_in 중간 / sewer 먼·중간·전경 / starfall 먼·중간.
## 나머지 층에 t가 쓰였다면 예전처럼 t = 0으로 멈춘 그림이다.
static func has_theme(theme: String) -> bool:
	return theme in MINE


static func has_sky(theme: String) -> bool:
	return theme in MINE


## 지붕 방(kingdom_roof)은 하늘·배경을 kingdom으로 그린다 (지형 색만 다름)
static func _alias(theme: String) -> String:
	return "kingdom" if theme == "kingdom_roof" else theme


# ═══════════════════════════════════════════════════════════
# 하늘 (화면 고정 640×360)
# ═══════════════════════════════════════════════════════════

## c = Pen (방 진입 때 한 번). 별·구름·빛기둥처럼 t를 쓰는 것만 c.anim으로
static func draw_sky(c, theme: String, pal: Dictionary, _t: float) -> void:
	var top: Color = pal.sky_top
	var bot: Color = pal.sky_bottom
	var acc: Color = pal.accent
	match _alias(theme):
		"kingdom":
			Kit.stepped_grad(c, Rect2(0, 0, 640, 360), top, bot, 26, 1.5)
			# 지평선의 노을 (호박빛이 아래에서 번진다)
			for i in 7:
				c.draw_rect(Rect2(0, 236 + i * 18, 640, 18), Color(acc, 0.018 + i * 0.012))
			Kit.anim_twinkles(c, Rect2(0, 0, 640, 110), 26, Color(1, 0.95, 0.85, 0.55), 7)
			_moon(c, Vector2(512, 64), 15.0, true, Color("#f4e6cc"), bot)
			var cc := top.lerp(bot, 0.45).darkened(0.25)
			c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void: _clouds(cv, t, cc, acc, 0.5))
		"kingdom_night":
			Kit.stepped_grad(c, Rect2(0, 0, 640, 360), top, bot, 26, 1.2)
			Kit.anim_twinkles(c, Rect2(0, 0, 640, 230), 70, Color(0.9, 0.92, 1.0, 0.7), 11)
			_moon(c, Vector2(116, 70), 24.0, false, Color("#eef0f8"), bot)
			var cc2 := top.lerp(bot, 0.6).lightened(0.04)
			c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void: _clouds(cv, t, cc2, Color(0.7, 0.8, 1.0), 0.35))
		"kingdom_in":
			Kit.stepped_grad(c, Rect2(0, 0, 640, 360), top, bot, 20, 0.9)
			# 높은 창에서 비스듬히 내려오는 빛 기둥
			c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
				for i in 4:
					var x := 60.0 + i * 170.0
					var a := 0.03 + 0.012 * sin(t * 0.4 + i * 1.3)
					cv.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 50, 0), Vector2(x + 170, 360), Vector2(x + 90, 360)]), Color(acc, a)))
		"sewer":
			Kit.stepped_grad(c, Rect2(0, 0, 640, 360), top, bot, 18, 1.0)
			# 아래쪽 물빛 일렁임
			c.anim(Rect2(-40, 296, 760, 64), func(cv: CanvasItem, t: float) -> void:
				for i in 12:
					var y := 300.0 + i * 5.0
					var x2 := fmod(i * 97.0 + t * (8.0 + i), 700.0) - 30.0
					cv.draw_rect(Rect2(x2, y, 40.0 + (i % 3) * 20.0, 1), Color(acc, 0.05 + 0.02 * sin(t * 2.0 + i))))
		"starfall":
			Kit.stepped_grad(c, Rect2(0, 0, 640, 360), top, bot, 26, 1.1)
			_nebula(c, acc)
			Kit.anim_twinkles(c, Rect2(0, 0, 640, 260), 90, Color(0.95, 0.9, 1.0, 0.75), 23)
			# 별이 떨어졌던 자리: 지평선 가까이 보랏빛 광휘
			for i in 6:
				c.draw_rect(Rect2(0, 270 + i * 15, 640, 15), Color(acc, 0.02 + i * 0.016))
			c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void: _shooting_stars(cv, t, acc))


static func _moon(c, pos: Vector2, r: float, crescent: bool, col: Color, sky: Color) -> void:
	for i in 4:
		c.draw_circle(pos, r * (2.6 - i * 0.4), Color(col, 0.03))
	c.draw_circle(pos, r, col)
	if crescent:
		c.draw_circle(pos + Vector2(r * 0.42, -r * 0.18), r * 0.9, sky.lerp(col, 0.06))
	else:
		c.draw_circle(pos + Vector2(-r * 0.3, -r * 0.2), r * 0.22, col.darkened(0.08))
		c.draw_circle(pos + Vector2(r * 0.35, r * 0.3), r * 0.15, col.darkened(0.08))
		c.draw_circle(pos + Vector2(r * 0.1, -r * 0.5), r * 0.1, col.darkened(0.06))


## 천천히 흐르는 길쭉한 구름 띠 (아랫면이 빛을 받음)
static func _clouds(c, t: float, col: Color, lit: Color, lit_a: float) -> void:
	for i in 6:
		var y := 70.0 + i * 30.0 + (i % 2) * 8.0
		var w := 150.0 + (i * 53) % 120
		var x := fmod(i * 173.0 + t * (2.0 + i * 0.6), 640.0 + w + 100.0) - w - 50.0
		var h := 5.0 + (i % 3) * 2.0
		c.draw_rect(Rect2(x, y, w, h), Color(col, 0.55))
		c.draw_rect(Rect2(x + 14, y - h * 0.6, w * 0.55, h * 0.7), Color(col, 0.45))
		c.draw_rect(Rect2(x + 6, y + h - 1, w - 12, 1), Color(lit, 0.08 * lit_a * 2.0))


static func _nebula(c, acc: Color) -> void:
	# 대각선으로 흐르는 별의 강 (보랏빛 성운): 넓고 옅은 띠 + 가운데 밝은 띠 + 촘촘한 별가루
	for layer in 3:
		var wdt: float = [70.0, 38.0, 14.0][layer]
		var a: float = [0.05, 0.06, 0.07][layer]
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		for i in 13:
			var k := float(i) / 12.0
			var cx := -40.0 + k * 720.0
			var cy := 262.0 - k * 236.0 + sin(k * 6.0 + 0.5) * 16.0
			var ww: float = wdt * (0.7 + 0.3 * sin(k * 9.0 + layer))
			top.append(Vector2(cx, cy - ww))
			bot.append(Vector2(cx, cy + ww * 0.8))
		bot.reverse()
		top.append_array(bot)
		c.draw_colored_polygon(top, Color(acc.lerp(Color(0.85, 0.75, 1.0), layer * 0.3), a))
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var dots := PackedVector2Array()
	var spd := PackedFloat64Array()
	for i in 120:
		var k2 := rng.randf()
		var cy2 := 262.0 - k2 * 236.0 + sin(k2 * 6.0 + 0.5) * 16.0 + rng.randfn(0.0, 14.0)
		spd.append(rng.randf_range(0.5, 2.0))
		dots.append(Vector2(-40.0 + k2 * 720.0, cy2))
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 120:
			var tw := 0.5 + 0.5 * sin(t * spd[i] + i)
			cv.draw_rect(Rect2(dots[i], Vector2(1, 1)), Color(0.95, 0.88, 1.0, 0.25 + 0.35 * tw)))


static func _shooting_stars(c, t: float, acc: Color) -> void:
	for i in 3:
		var period := 5.0 + i * 2.3
		var ph := fmod(t + i * 1.9, period) / 0.9 # 0.9초 동안만 보임
		if ph > 1.0:
			continue
		var start := Vector2(120 + i * 190, 30 + i * 22)
		var dir := Vector2(-1.0, 0.55).normalized()
		var head := start + dir * 220.0 * ph
		var tail := head - dir * 60.0 * (1.0 - ph * 0.5)
		c.draw_line(tail, head, Color(acc, 0.35 * (1.0 - ph)), 1.0)
		c.draw_line(head - dir * 14.0, head, Color(1, 1, 1, 0.8 * (1.0 - ph)), 1.0)
		KArt.star4(c, head, 2.0, Color(1, 0.95, 1.0, 0.9 * (1.0 - ph)))


# ═══════════════════════════════════════════════════════════
# 시차 층
# ═══════════════════════════════════════════════════════════

## l = Pen (방 진입 때 한 번). 움직이는 것만 l.anim — backdrop_kit.gd 머리말 참고
static func draw_layer(l, theme: String, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> bool:
	if not theme in MINE:
		return false
	theme = _alias(theme)
	var pal := RoomTheme.get_theme(theme)
	match theme:
		"kingdom", "kingdom_night":
			var night := theme == "kingdom_night"
			match depth:
				0: _k_far(l, pal, span, rng, t, night)
				1: _k_mid(l, pal, span, rng, t, night)
				2: _k_near(l, pal, span, rng, night)
				_: _k_front(l, span, rng)
		"kingdom_in":
			match depth:
				0: _in_far(l, pal, span, rng)
				1: _in_mid(l, pal, span, rng, t)
				2: _in_near(l, pal, span, rng)
				_: _in_front(l, span, rng)
		"sewer":
			match depth:
				0: _sw_far(l, pal, span, rng, t)
				1: _sw_mid(l, pal, span, rng, t)
				2: _sw_near(l, pal, span, rng)
				_: _sw_front(l, span, rng, t)
		"starfall":
			match depth:
				0: _sf_far(l, pal, span, rng, t)
				1: _sf_mid(l, pal, span, rng, t)
				2: _sf_near(l, pal, span, rng)
				_: _sf_front(l, span, rng)
	return true


const FRONT_DARK := Color(0.015, 0.014, 0.025, 0.93)


# ─── 황도 아르덴: 먼 층 ─────────────────────────────────

static func _k_far(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, _t: float, night: bool) -> void:
	var col: Color = pal.far
	var ridge := span.y * 0.66
	var win_a := 0.85 if night else 0.6
	# 1) 수도교: 먼 하늘을 가로지르는 아치 다리
	var aq_y := ridge - 62.0
	var aq_col := col.lightened(0.015)
	l.draw_rect(Rect2(-120, aq_y, span.x + 240, 9), aq_col)
	l.draw_rect(Rect2(-120, aq_y - 2, span.x + 240, 2), aq_col.lightened(0.04))
	var ax := -120.0
	while ax < span.x + 120:
		l.draw_rect(Rect2(ax, aq_y + 9, 7, 70), aq_col)
		var arch := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			arch.append(Vector2(ax + 7 + 14 + cos(a) * 14, aq_y + 24 + sin(a) * 15))
		l.draw_polyline(arch, aq_col, 3.0)
		ax += 35.0
	# 2) 성벽 도시의 먼 지붕 선
	var pts := PackedVector2Array([Vector2(-120, span.y + 60)])
	var x := -120.0
	var lit: Array[Vector2] = []
	while x < span.x + 120:
		var w := rng.randf_range(16, 38)
		var h := rng.randf_range(10, 38)
		pts.append(Vector2(x, ridge - h * 0.55))
		pts.append(Vector2(x + w * 0.5, ridge - h))
		pts.append(Vector2(x + w, ridge - h * 0.55))
		if rng.randf() < 0.55:
			lit.append(Vector2(x + w * 0.5 + rng.randf_range(-4, 4), ridge - h * 0.4 + rng.randf_range(2, 14)))
		x += w
	pts.append(Vector2(span.x + 120, span.y + 60))
	l.draw_colored_polygon(pts, col)
	for i in lit.size():
		var p: Vector2 = lit[i]
		l.anim(Rect2(p, Vector2(2, 2)), func(c: CanvasItem, tt: float) -> void:
			var fl := 0.75 + 0.25 * sin(tt * (1.0 + (i % 5) * 0.3) + i)
			c.draw_rect(Rect2(p, Vector2(2, 2)), Color(WINDOW_LIT, win_a * fl * 0.8)))
	# 3) 상징물: 황궁 · 대성당 · 시계탑 (방에 따라 순서가 바뀜)
	var rid: String = l.room_id
	var order: Array[String] = ["castle", "cathedral", "clocktower"]
	if "clock" in rid or "gear" in rid:
		order = ["clocktower", "castle", "cathedral"]
	elif "cathedral" in rid or "crypt" in rid:
		order = ["cathedral", "clocktower", "castle"]
	elif "roof" in rid or "walls" in rid:
		order = ["castle", "clocktower", "cathedral"]
	var slot := 0
	var lx := rng.randf_range(150, 260)
	while lx < span.x + 60:
		match order[slot % order.size()]:
			"castle": _castle(l, Vector2(lx, ridge + 6), col, night)
			"cathedral": _cathedral(l, Vector2(lx, ridge + 6), col, night)
			"clocktower": _clocktower(l, Vector2(lx, ridge + 6), col, night)
		slot += 1
		lx += rng.randf_range(400, 520)


## 황궁: 가운데 큰 성채 + 높낮이가 다른 원뿔 지붕 탑들, 꼭대기에 진홍 깃발
static func _castle(l, base: Vector2, col: Color, night: bool) -> void:
	var c := col.lightened(0.035)
	var roof := ROOF.lerp(col, 0.55)
	var win_a := 0.9 if night else 0.65
	# 성채 몸통
	l.draw_rect(Rect2(base.x - 70, base.y - 120, 140, 130), c)
	_crenel(l, base.x - 70, base.y - 120, 140, c)
	# 탑: [x 오프셋, 너비, 높이]
	var towers := [[-96, 26, 150], [-58, 22, 196], [-14, 32, 236], [30, 22, 186], [70, 28, 156], [104, 18, 120]]
	for i in towers.size():
		var tw: Array = towers[i]
		var tx := base.x + float(tw[0])
		var w := float(tw[1])
		var h := float(tw[2])
		l.draw_rect(Rect2(tx - w * 0.5, base.y - h, w, h + 10), c.lightened(0.01 * (i % 2)))
		# 원뿔 지붕 + 빛 받은 쪽
		var top := Vector2(tx, base.y - h - w * 1.35)
		l.draw_colored_polygon(PackedVector2Array([Vector2(tx - w * 0.62, base.y - h), top, Vector2(tx + w * 0.62, base.y - h)]), roof)
		l.draw_colored_polygon(PackedVector2Array([Vector2(tx + w * 0.05, base.y - h), top, Vector2(tx + w * 0.62, base.y - h)]), roof.lightened(0.06))
		l.draw_rect(Rect2(tx - w * 0.62, base.y - h, w * 1.24, 2), c.lightened(0.05))
		# 창 (위에서 아래로 몇 개)
		for j in int(h / 34.0):
			var wy := base.y - h + 12 + j * 30
			if (i + j) % 3 != 1:
				l.anim(Rect2(tx - 1.5, wy, 3, 5), func(cv: CanvasItem, tt: float) -> void:
					var fl := 0.7 + 0.3 * sin(tt * 1.3 + i * 2.0 + j)
					cv.draw_rect(Rect2(tx - 1.5, wy, 3, 5), Color(WINDOW_LIT, win_a * fl)))
		# 깃발
		if h > 170.0:
			var ptop := top + Vector2(0, -12)
			var pcol := Color("#a8242e").lerp(col, 0.25)
			var pole := c.lightened(0.1)
			l.anim(Kit.bb_pennant(ptop, 16.0, 6.0), func(cv: CanvasItem, tt: float) -> void: KArt.pennant(cv, ptop, 16.0, 6.0, tt + i, pcol, pole))
	# 성문과 성채 창
	var gate := KArt.arch_points(base.x, base.y + 10, 26, 34)
	l.draw_colored_polygon(gate, col.darkened(0.35))
	for k in 5:
		l.draw_rect(Rect2(base.x - 52 + k * 24, base.y - 92, 4, 7), Color(WINDOW_LIT, win_a * 0.7))
	# 황궁 위 커다란 은사자 깃발 (성채 정면)
	var bcol := Color("#7a1a24").lerp(col, 0.2)
	var trim := c.lightened(0.12)
	var b1 := Vector2(base.x - 40, base.y - 112)
	var b2 := Vector2(base.x + 40, base.y - 112)
	l.anim(Kit.bb_banner(b1, 16, 44), func(cv: CanvasItem, tt: float) -> void: KArt.hanging_banner(cv, b1, 16, 44, tt, bcol, true, trim))
	l.anim(Kit.bb_banner(b2, 16, 44), func(cv: CanvasItem, tt: float) -> void: KArt.hanging_banner(cv, b2, 16, 44, tt + 1.0, bcol, true, trim))


static func _crenel(l, x: float, y: float, w: float, c: Color) -> void:
	var cx := x
	while cx < x + w - 4:
		l.draw_rect(Rect2(cx, y - 5, 5, 5), c)
		cx += 9.0


## 루멘 대성당: 쌍둥이 첨탑 + 장미창 + 첨탑 끝 해 문양
static func _cathedral(l, base: Vector2, col: Color, night: bool) -> void:
	var c := col.lightened(0.03)
	var glow_a := 0.55 if night else 0.38
	# 본당
	l.draw_rect(Rect2(base.x - 60, base.y - 110, 120, 120), c)
	l.draw_colored_polygon(PackedVector2Array([Vector2(base.x - 64, base.y - 110), Vector2(base.x, base.y - 160), Vector2(base.x + 64, base.y - 110)]), c.lightened(0.02))
	# 쌍둥이 첨탑
	for sx in [-1.0, 1.0]:
		var tx: float = base.x + sx * 52.0
		l.draw_rect(Rect2(tx - 15, base.y - 190, 30, 200), c)
		l.draw_colored_polygon(PackedVector2Array([Vector2(tx - 17, base.y - 190), Vector2(tx, base.y - 290), Vector2(tx + 17, base.y - 190)]), c.lightened(0.015))
		# 작은 소첨탑
		for k in [-1.0, 1.0]:
			var px: float = tx + k * 15.0
			l.draw_colored_polygon(PackedVector2Array([Vector2(px - 3, base.y - 190), Vector2(px, base.y - 214), Vector2(px + 3, base.y - 190)]), c)
		# 첨탑 끝의 해 문양
		var sun := Vector2(tx, base.y - 296)
		l.draw_circle(sun, 3.0, Color("#c8a040").lerp(col, 0.4))
		# 길쭉한 창
		for j in 3:
			var wp := KArt.arch_points(tx, base.y - 120 + j * 36, 8, 22, true, 4)
			l.draw_colored_polygon(wp, Color(WINDOW_LIT, glow_a * 0.6))
	# 장미창 (색유리 조각이 은은하게)
	var rc := Vector2(base.x, base.y - 120)
	Kit.glow(l, rc, 34.0, Color(WINDOW_LIT, 0.4), 3)
	l.draw_circle(rc, 18.0, c.darkened(0.3))
	l.anim(Kit.bb_circle(rc, 17.0), func(cv: CanvasItem, tt: float) -> void:
		for i in 12:
			var a := TAU * i / 12.0 + tt * 0.02
			var gc: Color = GLASS[i % GLASS.size()]
			cv.draw_colored_polygon(PackedVector2Array([rc, rc + Vector2(cos(a), sin(a)) * 16.0, rc + Vector2(cos(a + TAU / 12.0), sin(a + TAU / 12.0)) * 16.0]), Color(gc, glow_a)))
	l.draw_arc(rc, 17.0, 0, TAU, 24, c.lightened(0.08), 2.0)
	l.draw_circle(rc, 4.0, Color(WINDOW_LIT, glow_a + 0.2))
	# 정문
	l.draw_colored_polygon(KArt.arch_points(base.x, base.y + 10, 24, 44, true, 6), col.darkened(0.3))


## 시계탑: 높은 탑 + 빛나는 큰 시계판(바늘이 천천히 돈다) + 종루
static func _clocktower(l, base: Vector2, col: Color, night: bool) -> void:
	var c := col.lightened(0.04)
	var h := 250.0
	l.draw_rect(Rect2(base.x - 22, base.y - h, 44, h + 10), c)
	l.draw_rect(Rect2(base.x - 26, base.y - h, 52, 6), c.lightened(0.04))
	l.draw_rect(Rect2(base.x - 26, base.y - h + 70, 52, 4), c.lightened(0.03))
	# 종루 (뚫린 아치 + 종)
	l.draw_colored_polygon(KArt.arch_points(base.x, base.y - h - 2, 22, 26, false, 6), col.darkened(0.3))
	l.draw_colored_polygon(PackedVector2Array([Vector2(base.x - 5, base.y - h - 6), Vector2(base.x, base.y - h - 15), Vector2(base.x + 5, base.y - h - 6)]), Color("#8a6a3a").lerp(col, 0.5))
	l.draw_rect(Rect2(base.x - 26, base.y - h - 30, 52, 4), c)
	l.draw_colored_polygon(PackedVector2Array([Vector2(base.x - 28, base.y - h - 30), Vector2(base.x, base.y - h - 74), Vector2(base.x + 28, base.y - h - 30)]), ROOF.lerp(col, 0.5))
	var ptop := Vector2(base.x, base.y - h - 88)
	var pcol := Color("#a8242e").lerp(col, 0.25)
	var pole := c.lightened(0.1)
	l.anim(Kit.bb_pennant(ptop, 14.0, 5.0), func(cv: CanvasItem, tt: float) -> void: KArt.pennant(cv, ptop, 14.0, 5.0, tt * 1.1, pcol, pole))
	# 시계판
	var cc := Vector2(base.x, base.y - h + 36)
	var face_col := Color("#f0d8a0") if night else Color("#d8c090")
	Kit.glow(l, cc, 40.0, Color(WINDOW_LIT, 0.55 if night else 0.35), 4)
	l.draw_circle(cc, 19.0, c.darkened(0.2))
	l.draw_circle(cc, 16.0, Color(face_col, 0.85 if night else 0.6))
	for i in 12:
		var a := TAU * i / 12.0
		l.draw_rect(Rect2(cc + Vector2(cos(a), sin(a)) * 13.0 - Vector2(1, 1), Vector2(2, 2)), col.darkened(0.2))
	var hand_c := col.darkened(0.45)
	l.anim(Kit.bb_circle(cc, 13.0), func(cv: CanvasItem, tt: float) -> void:
		var m := tt * 0.25
		cv.draw_line(cc, cc + Vector2(cos(m - PI * 0.5), sin(m - PI * 0.5)) * 12.0, hand_c, 1.0)
		cv.draw_line(cc, cc + Vector2(cos(m / 12.0 + 1.0), sin(m / 12.0 + 1.0)) * 8.0, hand_c, 2.0))
	# 아래 창
	var wa := 0.8 if night else 0.55
	for j in 4:
		var wr := Rect2(base.x - 2, base.y - h + 90 + j * 34, 4, 9)
		l.anim(wr, func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(wr, Color(WINDOW_LIT, wa * (0.7 + 0.3 * sin(tt + j)))))


# ─── 황도 아르덴: 중간 층 (지붕의 바다) ─────────────────

static func _k_mid(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, _t: float, night: bool) -> void:
	var col: Color = pal.mid
	var base_y := span.y * 0.73
	var win_a := 0.92 if night else 0.72
	var smoke_col := Color(0.62, 0.6, 0.7, 0.16) if not night else Color(0.55, 0.6, 0.8, 0.12)
	for row in 2:
		var c := col.darkened(0.12) if row == 0 else col
		var roof := ROOF.lerp(col, 0.62 if row == 0 else 0.5)
		var by := base_y - (34.0 if row == 0 else 0.0)
		var x := -100.0 + row * rng.randf_range(20, 60)
		var prev_top := Vector2.INF
		while x < span.x + 100:
			var w := rng.randf_range(46, 86)
			var wall_h := rng.randf_range(34, 86)
			var top_y := by - wall_h
			l.draw_rect(Rect2(x, top_y, w, span.y - top_y + 60), c)
			# 지붕: 박공 또는 경사 지붕
			var gable := rng.randf() < 0.6
			var rh := w * (0.5 if gable else 0.34)
			var roof_pts: PackedVector2Array
			if gable:
				roof_pts = PackedVector2Array([Vector2(x - 4, top_y), Vector2(x + w * 0.5, top_y - rh), Vector2(x + w + 4, top_y)])
			else:
				roof_pts = PackedVector2Array([Vector2(x - 4, top_y), Vector2(x + 8, top_y - rh), Vector2(x + w - 8, top_y - rh), Vector2(x + w + 4, top_y)])
			l.draw_colored_polygon(roof_pts, roof)
			# 지붕 기와 줄
			for k in 3:
				var ky := top_y - rh * (0.25 + k * 0.25)
				var inset := (rh * (0.25 + k * 0.25)) / rh * (w * 0.5 if gable else 8.0)
				l.draw_line(Vector2(x + inset - 2, ky), Vector2(x + w - inset + 2, ky), roof.darkened(0.2), 1.0)
			l.draw_line(roof_pts[0], roof_pts[1], roof.lightened(0.12), 1.0)
			# 굴뚝 + 연기
			if rng.randf() < 0.55:
				var cx := x + w * rng.randf_range(0.6, 0.85)
				var ctop := top_y - rh * 0.55 - 10.0
				l.draw_rect(Rect2(cx - 3, ctop, 7, 16), c.lightened(0.04))
				l.draw_rect(Rect2(cx - 4, ctop - 2, 9, 3), c.lightened(0.08))
				var sb := Vector2(cx + 0.5, ctop - 3)
				var sd := rng.randf()
				l.anim(Kit.bb_smoke(sb, 0.9), func(cv: CanvasItem, tt: float) -> void: KArt.smoke(cv, sb, tt, sd, smoke_col, 0.9, 5))
			# 창: 2~3층, 불 켜진 창과 꺼진 창
			var floors := int(wall_h / 22.0)
			var cols := int(w / 18.0)
			for fy in floors:
				for fx in cols:
					var wx := x + 8 + fx * ((w - 16) / maxf(cols - 1, 1)) - 3
					var wy := top_y + 8 + fy * 22
					var on := rng.randf() < (0.62 if night else 0.42)
					if on:
						l.draw_rect(Rect2(wx - 1, wy - 1, 8, 10), Color(WINDOW_LIT, 0.08 * win_a))
						var rk := 0.75 if row == 0 else 0.9
						l.anim(Rect2(wx, wy, 6, 8), func(cv: CanvasItem, tt: float) -> void:
							var fl := 0.8 + 0.2 * sin(tt * 1.7 + wx * 0.1)
							cv.draw_rect(Rect2(wx, wy, 6, 8), Color(WINDOW_LIT, win_a * fl * rk)))
						l.draw_rect(Rect2(wx + 2.5, wy, 1, 8), c)
						l.draw_rect(Rect2(wx, wy + 3.5, 6, 1), c)
					else:
						l.draw_rect(Rect2(wx, wy, 6, 8), c.darkened(0.35))
					l.draw_rect(Rect2(wx - 1, wy + 8, 8, 1), c.lightened(0.08))
			# 목조 골조 (일부 집)
			if row == 1 and rng.randf() < 0.4:
				var tim := c.lightened(0.06)
				l.draw_line(Vector2(x + 2, top_y + 2), Vector2(x + 2, by), tim, 2.0)
				l.draw_line(Vector2(x + w - 2, top_y + 2), Vector2(x + w - 2, by), tim, 2.0)
				l.draw_line(Vector2(x + 2, top_y + wall_h * 0.5), Vector2(x + w - 2, top_y + wall_h * 0.5), tim, 1.0)
			# 장식 깃발 줄 (앞줄 지붕 사이)
			if row == 1 and prev_top != Vector2.INF and rng.randf() < 0.5:
				var ba := prev_top
				var bb := Vector2(x + 6, top_y + 4)
				l.anim(Rect2(ba, Vector2.ZERO).expand(bb).grow_individual(4, 4, 4, 20), func(cv: CanvasItem, tt: float) -> void: _bunting(cv, ba, bb, tt, col))
			prev_top = Vector2(x + w - 6, top_y + 4)
			x += w + rng.randf_range(-6, 10)


## 지붕 사이에 걸린 삼각 깃발 줄
static func _bunting(l, a: Vector2, b: Vector2, t: float, col: Color) -> void:
	var cols := [Color("#a8323a"), Color("#d8a040"), Color("#3a5aa8"), Color("#e8e0d0")]
	var n := int(a.distance_to(b) / 9.0)
	if n < 2:
		return
	var sag := 10.0 + sin(t * 0.9 + a.x * 0.05) * 1.5
	var prev := a
	for i in range(1, n + 1):
		var k := float(i) / n
		var p := a.lerp(b, k) + Vector2(0, sin(k * PI) * sag)
		l.draw_line(prev, p, col.lightened(0.15), 1.0)
		if i < n:
			var fc: Color = cols[i % cols.size()]
			var sw := sin(t * 3.0 + i) * 1.0
			l.draw_colored_polygon(PackedVector2Array([p + Vector2(-2.5, 0), p + Vector2(2.5, 0), p + Vector2(sw, 6)]), fc.lerp(col, 0.45))
		prev = p


# ─── 황도 아르덴: 가까운 층 · 전경 ──────────────────────

static func _k_near(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, night: bool) -> void:
	var col: Color = pal.near
	var base_y := span.y * 0.77
	l.draw_rect(Rect2(-100, base_y, span.x + 200, span.y), col)
	var x := rng.randf_range(-40, 120)
	while x < span.x + 100:
		var kind := rng.randi() % 3
		match kind:
			0:
				# 성벽 조각: 총안 + 아치형 버팀벽
				var w := rng.randf_range(120, 200)
				var h := rng.randf_range(60, 100)
				l.draw_rect(Rect2(x, base_y - h, w, h + 4), col)
				_crenel(l, x, base_y - h, w, col)
				var arch := KArt.arch_points(x + w * 0.5, base_y + 4, w * 0.4, h * 0.65, false, 8)
				l.draw_colored_polygon(arch, col.darkened(0.45))
				x += w
			1:
				# 가로등 기둥 (따뜻한 빛)
				l.draw_rect(Rect2(x - 2, base_y - 70, 4, 74), col)
				l.draw_rect(Rect2(x - 6, base_y - 76, 12, 8), col)
				Kit.glow(l, Vector2(x, base_y - 72), 26.0, Color(WINDOW_LIT, 0.55 if night else 0.38), 4)
				l.draw_rect(Rect2(x - 3, base_y - 74, 6, 4), Color(WINDOW_LIT, 0.8))
				x += 40.0
			_:
				# 지붕 처마와 걸린 간판
				var w2 := rng.randf_range(70, 130)
				l.draw_colored_polygon(PackedVector2Array([Vector2(x, base_y - 40), Vector2(x + w2 * 0.5, base_y - 70), Vector2(x + w2, base_y - 40)]), col)
				l.draw_rect(Rect2(x + 4, base_y - 40, w2 - 8, 44), col)
				l.draw_line(Vector2(x + w2 - 10, base_y - 30), Vector2(x + w2 + 10, base_y - 30), col, 2.0)
				l.draw_rect(Rect2(x + w2 + 2, base_y - 28, 14, 10), col)
				x += w2
		x += rng.randf_range(80, 220)


static func _k_front(l, span: Vector2, rng: RandomNumberGenerator) -> void:
	var dark := FRONT_DARK
	var x := rng.randf_range(0, 260)
	while x < span.x:
		var bottom := span.y + 30
		match rng.randi() % 3:
			0:
				# 통 두 개
				l.draw_rect(Rect2(x, bottom - 40, 22, 40), dark)
				l.draw_rect(Rect2(x + 24, bottom - 32, 20, 32), dark)
			1:
				# 나무 울타리
				for i in 6:
					l.draw_rect(Rect2(x + i * 12, bottom - 36 - (i % 2) * 4, 5, 40), dark)
				l.draw_rect(Rect2(x - 2, bottom - 26, 74, 4), dark)
			_:
				# 쌓인 상자
				l.draw_rect(Rect2(x, bottom - 30, 30, 30), dark)
				l.draw_rect(Rect2(x + 8, bottom - 52, 24, 24), dark)
		x += rng.randf_range(360, 620)
	# 위: 처마 끝과 등불 줄
	var cx := rng.randf_range(80, 300)
	while cx < span.x:
		var w := rng.randf_range(90, 160)
		l.draw_colored_polygon(PackedVector2Array([Vector2(cx, -20), Vector2(cx + w, -20), Vector2(cx + w - 10, 8), Vector2(cx + 10, 8)]), dark)
		var y := 8.0
		var lx := cx + w * 0.5
		l.draw_line(Vector2(lx, y), Vector2(lx, y + 14), dark, 1.0)
		l.draw_rect(Rect2(lx - 4, y + 14, 8, 10), dark)
		cx += w + rng.randf_range(400, 760)


# ─── 성·대성당·투기장 실내 ──────────────────────────────

static func _in_far(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator) -> void:
	var col: Color = pal.far
	l.draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
	var acc: Color = pal.accent
	var gap := 210.0
	var x := rng.randf_range(40, 140)
	var i := 0
	while x < span.x + 60:
		var w := 64.0
		var top := 30.0
		var h := span.y * 0.62
		var base := top + h
		# 빛줄기 (창에서 오른쪽 아래로)
		l.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.3, top + 40), Vector2(x + w * 0.4, top + 40), Vector2(x + w * 1.6, span.y + 40), Vector2(x + w * 0.2, span.y + 40)]), Color(acc, 0.035))
		# 창틀
		var frame := KArt.arch_points(x, base + 6, w + 12, h + 12, true, 10)
		l.draw_colored_polygon(frame, col.lightened(0.05))
		var arch := KArt.arch_points(x, base, w, h, true, 10)
		l.draw_colored_polygon(arch, Color("#100c14"))
		# 색유리: 세로 칸 3줄 × 여러 단
		var rows := int((h - 30) / 16.0)
		for r in rows:
			for cc in 3:
				var px := x - w * 0.5 + 5 + cc * ((w - 10) / 3.0)
				var py := top + 26 + r * 16.0
				var gc: Color = GLASS[(r * 2 + cc * 3 + i) % GLASS.size()]
				l.draw_rect(Rect2(px, py, (w - 10) / 3.0 - 3, 13), Color(gc, 0.22))
				l.draw_rect(Rect2(px + 1, py + 1, 2, 4), Color(1, 1, 1, 0.08))
		# 창 위쪽 둥근 장식 (세 잎)
		var tc := Vector2(x, top + 22)
		l.draw_circle(tc, 9.0, Color(GLASS[(i + 1) % GLASS.size()], 0.26))
		l.draw_arc(tc, 9.0, 0, TAU, 16, col.lightened(0.06), 2.0)
		l.draw_line(Vector2(x - w * 0.16, top + 30), Vector2(x - w * 0.16, base), col.lightened(0.05), 2.0)
		l.draw_line(Vector2(x + w * 0.16, top + 30), Vector2(x + w * 0.16, base), col.lightened(0.05), 2.0)
		# 창 사이 기둥 + 궁륭 늑재
		var px2 := x + gap * 0.5
		l.draw_rect(Rect2(px2 - 10, -40, 20, span.y + 80), col.lightened(0.03))
		var rib := PackedVector2Array()
		for k in 11:
			var a := PI + PI * k / 10.0
			rib.append(Vector2(px2 - gap * 0.5 + cos(a) * gap * 0.5, 20 + sin(a) * 50))
		l.draw_polyline(rib, col.lightened(0.05), 5.0)
		x += gap
		i += 1
	# 바닥 가까이 어두운 띠
	l.draw_rect(Rect2(-100, span.y * 0.82, span.x + 200, span.y), col.darkened(0.3))


static func _in_mid(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, _t: float) -> void:
	var col: Color = pal.mid
	var acc: Color = pal.accent
	var gap := 300.0
	var x := rng.randf_range(20, 160)
	var i := 0
	while x < span.x + 80:
		# 대리석 기둥: 주초 + 몸통(세로 홈) + 주두
		var c := col.lightened(0.07)
		l.draw_rect(Rect2(x - 20, -40, 40, span.y + 80), c)
		for k in 4:
			l.draw_rect(Rect2(x - 15 + k * 9, -40, 2, span.y + 80), c.darkened(0.12))
		l.draw_rect(Rect2(x - 4, -40, 3, span.y + 80), c.lightened(0.05))
		l.draw_rect(Rect2(x - 27, 70, 54, 10), c.lightened(0.05))
		l.draw_rect(Rect2(x - 24, 80, 48, 5), c.darkened(0.05))
		l.draw_rect(Rect2(x - 27, span.y * 0.84, 54, 12), c.lightened(0.03))
		# 기둥 사이의 은사자 깃발
		var bx := x + gap * 0.5
		var bw := 30.0
		var bh := span.y * 0.4
		var btop := Vector2(bx, 92)
		var bcol := Color("#7a1622").lerp(col, 0.4)
		var btrim := Color("#c8a040").lerp(col, 0.4)
		var bph := i * 0.7
		l.anim(Kit.bb_banner(btop, bw, bh), func(cv: CanvasItem, tt: float) -> void: KArt.hanging_banner(cv, btop, bw, bh, tt + bph, bcol, true, btrim))
		# 샹들리에 (사슬 + 촛불 고리)
		if i % 2 == 0:
			var ch := Vector2(bx, 60)
			l.draw_line(Vector2(bx, -20), ch, c.darkened(0.2), 1.0)
			l.draw_rect(Rect2(ch.x - 26, ch.y, 52, 3), Color("#8a6a3a").lerp(col, 0.4))
			for k2 in 6:
				var cx := ch.x - 24 + k2 * 9.6
				l.draw_rect(Rect2(cx - 1, ch.y - 5, 2, 5), Color("#e8dcc0").lerp(col, 0.3))
				l.anim(Rect2(cx - 2, ch.y - 11, 4, 7), func(cv: CanvasItem, tt: float) -> void:
					var f := sin(tt * 8.0 + k2 * 1.7) * 0.7
					cv.draw_colored_polygon(PackedVector2Array([Vector2(cx - 1.5, ch.y - 5), Vector2(cx + f, ch.y - 10), Vector2(cx + 1.5, ch.y - 5)]), Color(1.0, 0.8, 0.45, 0.9)))
			Kit.glow(l, ch + Vector2(0, -6), 40.0, Color(acc, 0.45), 4)
		x += gap
		i += 1


static func _in_near(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator) -> void:
	var col: Color = pal.near
	var gap := 440.0
	var x := rng.randf_range(0, 200)
	while x < span.x + 100:
		l.draw_rect(Rect2(x, -20, 26, span.y + 40), col)
		l.draw_rect(Rect2(x - 6, span.y * 0.88, 38, 14), col)
		var rib := PackedVector2Array()
		for k in 11:
			var a := PI + PI * k / 10.0
			rib.append(Vector2(x + 13 + gap * 0.5 + cos(a) * gap * 0.5, 16 + sin(a) * 40))
		l.draw_polyline(rib, col, 9.0)
		x += gap + rng.randf_range(-40, 40)


static func _in_front(l, span: Vector2, rng: RandomNumberGenerator) -> void:
	var dark := FRONT_DARK
	var x := rng.randf_range(40, 300)
	while x < span.x:
		var bottom := span.y + 30
		# 난간 (기둥 여럿)
		var w := rng.randf_range(90, 150)
		l.draw_rect(Rect2(x, bottom - 40, w, 6), dark)
		var bx := x + 4
		while bx < x + w - 4:
			l.draw_rect(Rect2(bx, bottom - 34, 5, 34), dark)
			l.draw_circle(Vector2(bx + 2.5, bottom - 22), 4.0, dark)
			bx += 12.0
		x += w + rng.randf_range(380, 700)
	var cx := rng.randf_range(100, 400)
	while cx < span.x:
		var bt := Vector2(cx, -10)
		l.fn(Kit.bb_banner(bt, 30, 50), func(cv: CanvasItem) -> void: KArt.hanging_banner(cv, bt, 30, 50, 0.0, dark, false, dark))
		cx += rng.randf_range(500, 900)


# ─── 하수도 ─────────────────────────────────────────────

static func _sw_far(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, _t: float) -> void:
	var col: Color = pal.far
	var acc: Color = pal.accent
	l.draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
	var water_y := span.y * 0.54
	var gap := 170.0
	var x := rng.randf_range(-60, 40)
	var i := 0
	while x < span.x + 100:
		# 벽돌 아치 (안쪽은 깊은 어둠)
		var w := gap - 26.0
		var cx := x + gap * 0.5
		var arch := KArt.arch_points(cx, water_y + 4, w, span.y * 0.62, false, 12)
		l.draw_colored_polygon(arch, col.darkened(0.55))
		l.draw_polyline(arch, col.lightened(0.06), 6.0)
		# 아치 테두리의 벽돌 마디
		for k in 9:
			var a := PI + PI * (k + 0.5) / 9.0
			var r := w * 0.5
			var sy := water_y + 4 - span.y * 0.62 + r
			var p := Vector2(cx + cos(a) * r, sy + sin(a) * r)
			l.draw_line(p, p + Vector2(cos(a), sin(a)) * 5.0, col.darkened(0.2), 1.0)
		# 아치 안 깊은 곳의 다음 아치 (원근)
		var inner := KArt.arch_points(cx, water_y + 4, w * 0.55, span.y * 0.38, false, 10)
		l.draw_polyline(inner, col.lightened(0.02), 3.0)
		# 천장 쇠창살에서 떨어지는 빛줄기
		if i % 2 == 0:
			var gx := cx + rng.randf_range(-20, 20)
			l.draw_rect(Rect2(gx - 9, span.y * 0.12, 18, 4), col.lightened(0.1))
			for g in 4:
				l.draw_rect(Rect2(gx - 8 + g * 5, span.y * 0.12 + 1, 2, 2), Color(acc, 0.35))
			var shaft := PackedVector2Array([Vector2(gx - 8, span.y * 0.12 + 4), Vector2(gx + 8, span.y * 0.12 + 4), Vector2(gx + 34, water_y), Vector2(gx - 2, water_y)])
			var scol := acc.lerp(Color.WHITE, 0.4)
			var si := i
			l.anim(Kit.Pen._bounds(shaft, 1.0), func(cv: CanvasItem, tt: float) -> void:
				var la := 0.05 + 0.02 * sin(tt * 0.7 + si)
				cv.draw_colored_polygon(shaft, Color(scol, la)))
		# 기둥
		l.draw_rect(Rect2(x - 8, -40, 16, water_y + 44), col.lightened(0.03))
		x += gap
		i += 1
	# 빛나는 물길: 층층이 밝아지는 청록 + 일렁이는 물결선
	for k in 5:
		l.draw_rect(Rect2(-100, water_y + k * 4, span.x + 200, 4), Color(acc, 0.16 - k * 0.025).lerp(Color(col, 0.0), 0.2))
	l.draw_rect(Rect2(-100, water_y + 20, span.x + 200, span.y), col.darkened(0.35))
	l.anim(Rect2(-100, water_y, span.x + 230, 20), func(cv: CanvasItem, tt: float) -> void:
		for k in 24:
			var wx := fmod(k * 83.0 + tt * (6.0 + (k % 4) * 3.0), span.x + 200.0) - 100.0
			var wy := water_y + 2 + (k % 5) * 3.5
			cv.draw_rect(Rect2(wx, wy, 10.0 + (k % 3) * 8.0, 1), Color(acc, 0.35 + 0.2 * sin(tt * 2.0 + k))))


static func _sw_mid(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, _t: float) -> void:
	var col: Color = pal.mid
	var acc: Color = pal.accent
	var pipe := col.lightened(0.08)
	# 가로로 지나가는 큰 관 2~3줄
	var ys := [span.y * 0.2, span.y * 0.36, span.y * 0.62]
	for j in ys.size():
		var y: float = ys[j] + rng.randf_range(-10, 10)
		var r := 9.0 + j * 2.0
		if rng.randf() < 0.25:
			continue
		l.draw_rect(Rect2(-100, y - r, span.x + 200, r * 2), pipe)
		l.draw_rect(Rect2(-100, y - r + 2, span.x + 200, 2), pipe.lightened(0.08))
		l.draw_rect(Rect2(-100, y + r - 3, span.x + 200, 3), pipe.darkened(0.25))
		var fx := rng.randf_range(0, 60)
		while fx < span.x + 100:
			l.draw_rect(Rect2(fx, y - r - 2, 6, r * 2 + 4), pipe.lightened(0.04))
			l.draw_rect(Rect2(fx + 1, y - r, 1, 1), pipe.lightened(0.2))
			l.draw_rect(Rect2(fx + 1, y + r - 2, 1, 1), pipe.lightened(0.2))
			fx += rng.randf_range(70, 130)
	# 세로 관 + 밸브 바퀴 + 물을 쏟는 관
	var x := rng.randf_range(40, 200)
	while x < span.x + 60:
		var kind := rng.randi() % 3
		var w := 14.0
		l.draw_rect(Rect2(x - w * 0.5, -20, w, span.y * 0.78), pipe.darkened(0.05))
		l.draw_rect(Rect2(x - w * 0.5 + 2, -20, 2, span.y * 0.78), pipe.lightened(0.06))
		if kind == 0:
			var vc := Vector2(x, span.y * 0.5)
			l.draw_arc(vc, 12.0, 0, TAU, 20, Color("#7a4a2a").lerp(col, 0.4), 3.0)
			for k in 4:
				var a := TAU * k / 4.0 + 0.4
				l.draw_line(vc, vc + Vector2(cos(a), sin(a)) * 12.0, Color("#7a4a2a").lerp(col, 0.4), 2.0)
			l.draw_circle(vc, 3.0, pipe.lightened(0.1))
		elif kind == 1:
			# 옆으로 꺾여 물을 쏟는 관 (물줄기가 흘러내림)
			var my := span.y * 0.46
			l.draw_rect(Rect2(x, my - 7, 30, 14), pipe)
			l.draw_rect(Rect2(x + 28, my - 9, 6, 18), pipe.lightened(0.05))
			var sx := x + 36.0
			# 물줄기 묶음 전체가 하나의 움직이는 요소 (정적 줄기와 떨어지는 물방울이 번갈아 겹쳐서)
			var sh := span.y
			l.anim(Rect2(sx - 32, my - 2, 64, maxf(sh * 0.8 + 32.0 - my, 120.0) + 4.0), func(cv: CanvasItem, tt: float) -> void:
				for k in 5:
					var off := fmod(tt * 60.0 + k * 22.0, 110.0)
					cv.draw_rect(Rect2(sx - 2 + (k % 2), my + off * 0.0, 5, sh * 0.34), Color(acc, 0.05))
					cv.draw_rect(Rect2(sx - 1 + (k % 3), my + off, 2, 8), Color(acc, 0.45))
				cv.draw_rect(Rect2(sx - 3, my, 7, sh * 0.34), Color(acc, 0.12))
				Kit.glow(cv, Vector2(sx, sh * 0.8), 30.0, Color(acc, 0.6), 3)
				for k in 4:
					var sp := fmod(tt * 1.5 + k * 0.25, 1.0)
					cv.draw_rect(Rect2(sx - 6 + k * 4 - sp * 6, sh * 0.8 - sp * 10, 2, 2), Color(acc, 0.6 * (1.0 - sp))))
		x += rng.randf_range(220, 380)


static func _sw_near(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator) -> void:
	var col: Color = pal.near
	var moss := Color("#1f4c3c").lerp(col, 0.5)
	var x := rng.randf_range(0, 200)
	while x < span.x + 60:
		var w := rng.randf_range(26, 40)
		l.draw_rect(Rect2(x, -20, w, span.y + 40), col)
		l.draw_rect(Rect2(x - 5, span.y * 0.3, w + 10, 8), col)
		for k in 4:
			var mx := x + rng.randf_range(0, w)
			l.draw_rect(Rect2(mx, span.y * 0.3 + 8, 2, rng.randf_range(6, 24)), moss)
		# 늘어진 사슬
		if rng.randf() < 0.6:
			var cx := x + w + rng.randf_range(20, 60)
			var y := -10.0
			var len := rng.randf_range(0.2, 0.45) * span.y
			while y < len:
				l.draw_rect(Rect2(cx - 2, y, 4, 6), col.lightened(0.04))
				y += 7.0
		x += rng.randf_range(260, 460)
	l.draw_rect(Rect2(-100, span.y * 0.92, span.x + 200, span.y), col)


static func _sw_front(l, span: Vector2, rng: RandomNumberGenerator, _t: float) -> void:
	var dark := FRONT_DARK
	# 위: 관과 쇠창살 실루엣
	var x := rng.randf_range(0, 200)
	while x < span.x:
		var w := rng.randf_range(120, 260)
		l.draw_rect(Rect2(x, -20, w, 26), dark)
		l.draw_rect(Rect2(x + w * 0.3, 6, 10, 18), dark)
		x += w + rng.randf_range(260, 520)
	# 떨어지는 물방울 (청록)
	var acc := Color("#6af0e0")
	var sh := span.y
	for i in 14:
		var dx := fmod(i * 157.0 + 40.0, span.x)
		var period := 1.6 + (i % 4) * 0.45
		l.anim(Rect2(dx, 5, 1, sh * 0.9 + 5), func(cv: CanvasItem, tt: float) -> void:
			var ph := fmod(tt + i * 0.37, period) / period
			var dy := ph * ph * sh * 0.9
			cv.draw_rect(Rect2(dx, 6 + dy, 1, 3), Color(acc, 0.5 * (1.0 - ph * 0.5))))
	# 아래: 잔해
	var bx := rng.randf_range(100, 400)
	while bx < span.x:
		var bottom := span.y + 30
		l.draw_colored_polygon(PackedVector2Array([Vector2(bx, bottom), Vector2(bx + 10, bottom - 26), Vector2(bx + 34, bottom - 34), Vector2(bx + 60, bottom - 18), Vector2(bx + 70, bottom)]), dark)
		bx += rng.randf_range(420, 760)


# ─── 옛 성곽 지구 (운석) ────────────────────────────────

static func _sf_far(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, _t: float) -> void:
	var col: Color = pal.far
	var acc: Color = pal.accent
	var ridge := span.y * 0.57
	var cx := span.x * rng.randf_range(0.4, 0.6)
	# 맥동 (pulse = 0.85 + 0.15 * sin(t * 0.9))을 쓰는 것만 움직이는 요소
	# 운석 구덩이의 광휘 (뒤에서 비추어 폐허가 역광 실루엣이 됨)
	l.anim(Kit.bb_circle(Vector2(cx, ridge + 10), 230.0), func(cv: CanvasItem, tt: float) -> void:
		var pulse := 0.85 + 0.15 * sin(tt * 0.9)
		for i in 8:
			var k := 1.0 - i / 8.0
			cv.draw_circle(Vector2(cx, ridge + 10), 230.0 * k, Color(acc, 0.022 * pulse * (1.0 + i * 0.5))))
	# 거대한 운석: 구덩이에 반쯤 묻힌 검은 바위 + 빛나는 균열
	var mc := Vector2(cx + 10, ridge + 6)
	var rock := col.darkened(0.25)
	var mpts := PackedVector2Array()
	for i in 14:
		var a := PI + PI * i / 13.0
		var rr := 74.0 + sin(i * 2.7) * 9.0 + cos(i * 1.3) * 6.0
		mpts.append(mc + Vector2(cos(a) * rr * 1.15, sin(a) * rr * 0.8))
	l.draw_colored_polygon(mpts, rock)
	l.draw_colored_polygon(PackedVector2Array([mc + Vector2(-60, -38), mc + Vector2(-20, -60), mc + Vector2(24, -58), mc + Vector2(0, -40)]), rock.lightened(0.06))
	l.anim(Rect2(mc + Vector2(-62, -74), Vector2(132, 78)), func(cv: CanvasItem, tt: float) -> void:
		var pulse := 0.85 + 0.15 * sin(tt * 0.9)
		var crack := Color(acc.lerp(Color.WHITE, 0.25), 0.75 * pulse)
		cv.draw_polyline(PackedVector2Array([mc + Vector2(-58, -10), mc + Vector2(-30, -24), mc + Vector2(-8, -50), mc + Vector2(14, -30), mc + Vector2(46, -40), mc + Vector2(66, -18)]), crack, 2.0)
		cv.draw_line(mc + Vector2(-30, -24), mc + Vector2(-40, 0), crack, 1.0)
		cv.draw_line(mc + Vector2(14, -30), mc + Vector2(20, 0), crack, 1.0)
		cv.draw_line(mc + Vector2(-8, -50), mc + Vector2(-2, -64), crack, 1.0)
		KArt.glow(cv, mc + Vector2(-8, -48), 22.0, Color(acc, 0.9 * pulse), 4))
	var cr1 := Vector2(cx - 90, ridge + 8)
	var cr2 := Vector2(cx + 110, ridge + 8)
	var cc1 := acc.lerp(col, 0.2)
	var cc2 := acc.lerp(col, 0.25)
	l.anim(Kit.bb_crystal(cr1, 96.0), func(cv: CanvasItem, tt: float) -> void: KArt.crystal(cv, cr1, 96.0, cc1, 0.85 + 0.15 * sin(tt * 0.9), 1))
	l.anim(Kit.bb_crystal(cr2, 70.0), func(cv: CanvasItem, tt: float) -> void: KArt.crystal(cv, cr2, 70.0, cc2, 0.85 + 0.15 * sin(tt * 0.9), 3))
	# 무너진 성곽 선 (군데군데 끊김)
	var pts := PackedVector2Array([Vector2(-120, span.y + 60)])
	var x := -120.0
	while x < span.x + 120:
		var w := rng.randf_range(30, 70)
		var broken := rng.randf() < 0.3 or absf(x - cx) < 120.0
		var h := rng.randf_range(2, 10) if broken else rng.randf_range(26, 48)
		pts.append(Vector2(x, ridge - h))
		pts.append(Vector2(x + w * 0.3, ridge - h - rng.randf_range(-6, 8)))
		pts.append(Vector2(x + w * 0.7, ridge - h + rng.randf_range(-4, 10)))
		x += w
	pts.append(Vector2(span.x + 120, ridge))
	pts.append(Vector2(span.x + 120, span.y + 60))
	l.draw_colored_polygon(pts, col)
	# 부러진 탑 (들쭉날쭉한 꼭대기, 창은 텅 비어 빛이 샘)
	var tx := rng.randf_range(40, 160)
	while tx < span.x + 60:
		if absf(tx - cx) < 140.0:
			tx += 160.0
			continue
		var w2 := rng.randf_range(26, 42)
		var h2 := rng.randf_range(100, 180)
		var top := ridge - h2
		l.draw_colored_polygon(PackedVector2Array([
			Vector2(tx - w2 * 0.5, ridge + 4), Vector2(tx - w2 * 0.5, top + 12), Vector2(tx - w2 * 0.2, top),
			Vector2(tx, top + 16), Vector2(tx + w2 * 0.25, top + 6), Vector2(tx + w2 * 0.5, top + 26), Vector2(tx + w2 * 0.5, ridge + 4),
		]), col.lightened(0.02))
		l.draw_line(Vector2(tx + w2 * 0.5, top + 26), Vector2(tx + w2 * 0.5, ridge), Color(acc, 0.18), 1.0)
		for j in 3:
			l.draw_rect(Rect2(tx - 2, top + 34 + j * 26, 4, 7), Color(acc, 0.22))
		tx += rng.randf_range(240, 380)
	# 떠 있는 바위 조각 (천천히 오르내림, 윗면은 밝고 아랫면은 보랏빛)
	for i in 6:
		var fx := fmod(cx + (i - 2.5) * 120.0 + rng.randf_range(-30, 30) + span.x, span.x + 100.0) - 50.0
		var fy0 := ridge - 110.0 - rng.randf_range(0, 110)
		var sz := rng.randf_range(7, 16)
		l.anim(Rect2(fx - sz * 1.7, fy0 - sz - 6.0, sz * 3.4, sz * 3.6 + 12.0), func(cv: CanvasItem, tt: float) -> void:
			var fy := fy0 + sin(tt * 0.6 + i * 1.3) * 5.0
			KArt.glow(cv, Vector2(fx, fy + sz * 0.6), sz * 1.6, Color(acc, 0.3), 3)
			var fr := PackedVector2Array([Vector2(fx - sz, fy - sz * 0.15), Vector2(fx - sz * 0.5, fy - sz * 0.5), Vector2(fx + sz * 0.6, fy - sz * 0.45),
				Vector2(fx + sz, fy), Vector2(fx + sz * 0.4, fy + sz * 0.4), Vector2(fx, fy + sz * 1.1), Vector2(fx - sz * 0.5, fy + sz * 0.35)])
			cv.draw_colored_polygon(fr, col.lightened(0.05))
			cv.draw_line(Vector2(fx - sz * 0.5, fy - sz * 0.5), Vector2(fx + sz * 0.6, fy - sz * 0.45), col.lightened(0.18), 1.0)
			cv.draw_line(Vector2(fx - sz * 0.3, fy + sz * 0.35), Vector2(fx + sz * 0.3, fy + sz * 0.35), Color(acc, 0.7), 1.0))


static func _sf_mid(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator, _t: float) -> void:
	var col: Color = pal.mid
	var acc: Color = pal.accent
	var base_y := span.y * 0.68
	l.draw_rect(Rect2(-100, base_y, span.x + 200, span.y), col)
	var x := rng.randf_range(-40, 80)
	var i := 0
	while x < span.x + 100:
		var kind := rng.randi() % 3
		if kind == 0:
			# 기울어진 집 잔해 (지붕 없이 들보만)
			var w := rng.randf_range(60, 100)
			var h := rng.randf_range(50, 90)
			var lean := rng.randf_range(-10, 10)
			l.draw_colored_polygon(PackedVector2Array([Vector2(x, base_y + 4), Vector2(x + lean, base_y - h), Vector2(x + w * 0.4 + lean, base_y - h + 14), Vector2(x + w * 0.7 + lean, base_y - h * 0.7), Vector2(x + w, base_y - h * 0.8), Vector2(x + w, base_y + 4)]), col.lightened(0.05))
			l.draw_line(Vector2(x + lean, base_y - h), Vector2(x + w * 0.9, base_y - h - 18), col.lightened(0.09), 3.0)
			l.draw_line(Vector2(x + w * 0.3, base_y - h + 6), Vector2(x + w * 0.5, base_y - h - 22), col.lightened(0.07), 2.0)
			for j in 2:
				l.draw_rect(Rect2(x + 12 + j * 26 + lean * 0.5, base_y - h * 0.6, 8, 10), col.darkened(0.45))
			x += w
		elif kind == 1:
			# 별 수정 무리
			var cb := Vector2(x + 20, base_y + 2)
			var chh := rng.randf_range(26, 48)
			var ccol := acc.lerp(col, 0.15)
			var ci := i
			l.anim(Kit.bb_crystal(cb, chh), func(cv: CanvasItem, tt: float) -> void: KArt.crystal(cv, cb, chh, ccol, 0.75 + 0.25 * sin(tt * 1.4 + ci), ci))
			x += 50.0
		else:
			# 금 간 바위와 떠오르는 돌 조각
			var s := rng.randf_range(20, 36)
			l.draw_colored_polygon(PackedVector2Array([Vector2(x, base_y + 2), Vector2(x + s * 0.3, base_y - s), Vector2(x + s * 1.1, base_y - s * 0.8), Vector2(x + s * 1.5, base_y + 2)]), col.lightened(0.03))
			l.draw_line(Vector2(x + s * 0.5, base_y - s * 0.7), Vector2(x + s * 0.9, base_y - 2), Color(acc, 0.5), 1.0)
			var sx0 := x
			var si := i
			l.anim(Rect2(x + s * 0.4 - 1, base_y - s - 18.0 - 18.0 - 6.0, 36.0, 36.0), func(cv: CanvasItem, tt: float) -> void:
				for k in 3:
					var bob := sin(tt * 0.9 + k * 2.0 + si) * 4.0
					var p := Vector2(sx0 + s * 0.4 + k * 12.0, base_y - s - 18.0 - k * 9.0 + bob)
					cv.draw_rect(Rect2(p, Vector2(5 - k, 4 - k * 0.5)), col.lightened(0.08))
					cv.draw_rect(Rect2(p + Vector2(0, 3), Vector2(5 - k, 1)), Color(acc, 0.5)))
			x += s * 1.6
		x += rng.randf_range(60, 180)
		i += 1


static func _sf_near(l, pal: Dictionary, span: Vector2, rng: RandomNumberGenerator) -> void:
	var col: Color = pal.near
	var acc: Color = pal.accent
	var base_y := span.y * 0.78
	l.draw_rect(Rect2(-100, base_y, span.x + 200, span.y), col)
	var x := rng.randf_range(0, 160)
	while x < span.x + 100:
		var s := rng.randf_range(30, 70)
		l.draw_colored_polygon(PackedVector2Array([Vector2(x, base_y + 4), Vector2(x + s * 0.2, base_y - s * 0.7), Vector2(x + s * 0.5, base_y - s), Vector2(x + s * 0.9, base_y - s * 0.5), Vector2(x + s * 1.2, base_y + 4)]), col)
		if rng.randf() < 0.5:
			var cx := x + s * 1.3
			l.draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, base_y + 2), Vector2(cx + 2, base_y - 26), Vector2(cx + 6, base_y + 2)]), Color(acc, 0.22).lerp(col, 0.4))
			l.draw_line(Vector2(cx + 1, base_y - 2), Vector2(cx + 2, base_y - 22), Color(acc, 0.35), 1.0)
		x += s + rng.randf_range(140, 300)


static func _sf_front(l, span: Vector2, rng: RandomNumberGenerator) -> void:
	var dark := FRONT_DARK
	var x := rng.randf_range(0, 260)
	while x < span.x:
		var bottom := span.y + 30
		var s := rng.randf_range(30, 60)
		l.draw_colored_polygon(PackedVector2Array([Vector2(x, bottom), Vector2(x + s * 0.3, bottom - s), Vector2(x + s * 0.6, bottom - s * 0.6), Vector2(x + s * 0.8, bottom - s * 1.3), Vector2(x + s * 1.2, bottom)]), dark)
		x += s + rng.randf_range(380, 680)
