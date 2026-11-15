extends "res://characters/special/lyra_palette.gd"
## 리라 대화 초상화 (72×72). 게임에서 가장 아름다운 인물: 은백색 머리의 큰 볼륨과 별가루, 별 동공의 보랏빛 눈,
## 별자리 금실 자수 깃, 화면 위로 넘치는 거대한 모자(초승달 끝에 매달린 별), 둘레를 도는 작은 별들.
## expr: normal(다정한 미소) · happy · sad · serious · surprised · angry(→ serious) · possessed(흰 눈·흰 금)
##       weak(결전 직후, 지침) · aged(에필로그: 별빛을 잃고 늙기 시작 — 동공의 별이 사라지고 눈가에 잔주름)

const HAIR := Color("#eceffb")
const HAIR_SH := Color("#b4bade")
const HAIR_DEEP := Color("#8188bf")
const SKIN := Color("#f9eae4")
const SKIN_SH := Color("#ebcfcf")
const EYE := Color("#9a68e6")
const EYE_HI := Color("#d6b8ff")
const EYE_DEEP := Color("#46288a")
const LASH := Color("#231a3a")
const HAT := Color("#191d4c")


static func draw_portrait(p: Portrait, _info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	var poss := expr == "possessed"
	var aged := expr == "aged"
	if expr == "angry":
		expr = "serious"
	var b := sin(t * 1.6) * 0.5 + (sin(t * 18.0) * 0.4 if talking else 0.0)
	var fc := Vector2(36, 38 + b)
	_background(p, t, poss)
	_hair_back(p, fc, t, poss)
	_stars(p, fc, t, false, poss, aged)
	_body(p, fc, b, t, poss)
	_tresses(p, fc, t, poss)
	_face(p, fc, expr, t, talking, blinking, poss, aged)
	_hair_front(p, fc, t, poss, aged)
	_hat(p, fc, t, poss, expr)
	_stars(p, fc, t, true, poss, aged)
	if poss:
		_cracks(p, fc, t)


static func _background(p: Portrait, t: float, poss: bool) -> void:
	if poss:
		p.draw_rect(Rect2(0, 0, 72, 72), Color("#d4d4e2"))
		var c := Vector2(36, 30)
		for r in [10.0, 20.0, 32.0, 46.0]:
			p.draw_arc(c, r + sin(t + r) * 1.0, 0, TAU, 6, Color(0.35, 0.35, 0.45, 0.35), 1.0)
		for i in 6:
			var a := TAU * i / 6.0 + t * 0.2
			p.draw_line(c, c + Vector2(cos(a), sin(a)) * 60.0, Color(0.4, 0.4, 0.5, 0.25), 1.0)
		return
	for i in 12:
		p.draw_rect(Rect2(0, i * 6, 72, 6), Color("#070a24").lerp(Color("#1e2666"), float(i) / 11.0))
	for i in 8:
		p.draw_circle(Vector2(-6 + i * 12, 60 - i * 7), 11.0, Color(0.5, 0.5, 1.0, 0.04))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 22:
		var q := Vector2(rng.randf() * 72, rng.randf() * 62)
		var tw := StArt.twinkle(t, i, 1.3)
		p.draw_rect(Rect2(q, Vector2.ONE), Color(1.0, 0.95, 0.85, 0.2 + 0.6 * tw))


## 뒤 머리: 머리 둘레의 둥근 볼륨 → 어깨 너머로 물결치며 화면 아래 모서리까지
static func _hair_back(p: Portrait, fc: Vector2, t: float, poss: bool) -> void:
	var deep := HAIR_DEEP.lerp(WHITE_GOD, 0.35 if poss else 0.0)
	var base := HAIR_SH.lerp(WHITE_GOD, 0.35 if poss else 0.0)
	var top := HAIR.lerp(WHITE_GOD, 0.3 if poss else 0.0)
	var lift := 3.0 if poss else 0.0
	for side: float in [-1.0, 1.0]:
		var w0 := sin(t * 1.2 + side) * 1.0
		var w1 := sin(t * 1.2 + side + 1.3) * 1.6
		var outer := PackedVector2Array([
			fc + Vector2(0, -15), fc + Vector2(side * 12, -14), fc + Vector2(side * 18, -8 - lift), fc + Vector2(side * 20 + w0, 2 - lift),
			fc + Vector2(side * 20 + w0, 12 - lift), fc + Vector2(side * 23 + w1, 22 - lift), fc + Vector2(side * 27 + w1, 34 - lift),
			fc + Vector2(side * 22 + w1, 34 - lift), fc + Vector2(side * 18 + w0, 24), fc + Vector2(side * 14, 34), fc + Vector2(side * 10, 34),
			fc + Vector2(side * 9, 8), fc + Vector2(0, 4),
		])
		p.draw_colored_polygon(outer, deep)
		var mid := PackedVector2Array([
			fc + Vector2(0, -14), fc + Vector2(side * 11, -13), fc + Vector2(side * 16, -7 - lift), fc + Vector2(side * 18 + w0, 2 - lift),
			fc + Vector2(side * 17 + w0, 12 - lift), fc + Vector2(side * 19 + w1, 22 - lift), fc + Vector2(side * 22 + w1, 34 - lift),
			fc + Vector2(side * 15, 34), fc + Vector2(side * 14 + w0 * 0.5, 22), fc + Vector2(side * 10, 8), fc + Vector2(0, 4),
		])
		p.draw_colored_polygon(mid, base)
		# 윤기 띠와 결
		p.draw_line(fc + Vector2(side * 13, -11), fc + Vector2(side * 17 + w0, -2), Color(top, 0.9), 2.0)
		for k in 3:
			var x0 := side * (13.0 + k * 2.5)
			p.draw_line(fc + Vector2(x0 + w0 * 0.5, 2 + k * 2), fc + Vector2(x0 + side * (3.0 + k) + w1, 33), Color(top, 0.55 + k * 0.1), 1.0)
	# 별가루
	for i in 10:
		var side := -1.0 if i % 2 == 0 else 1.0
		var q := fc + Vector2(side * (14.0 + (i * 7) % 9), -6.0 + i * 4.0)
		var tw := StArt.twinkle(t, i * 1.9, 1.5)
		if poss:
			tw *= 0.2
		if tw > 0.62:
			StArt.sparkle(p, q, 2.0 + (tw - 0.62) * 5.0, STAR, (tw - 0.62) * 2.6)
		else:
			p.draw_rect(Rect2(q, Vector2.ONE), Color(STAR, 0.5 * tw))


static func _body(p: Portrait, fc: Vector2, b: float, t: float, poss: bool) -> void:
	var robe := ROBE.lerp(Color("#6a6a84"), 0.4 if poss else 0.0)
	var y0 := fc.y + 15.0
	p.draw_rect(Rect2(fc.x - 3.5, fc.y + 10, 7, 7), SKIN_SH)
	p.draw_colored_polygon(PackedVector2Array([Vector2(9, 72), Vector2(15, y0 + 6), Vector2(26, y0 + 1), Vector2(46, y0 + 1), Vector2(57, y0 + 6), Vector2(63, 72)]), robe)
	p.draw_colored_polygon(PackedVector2Array([Vector2(9, 72), Vector2(15, y0 + 6), Vector2(22, y0 + 3), Vector2(18, 72)]), robe.darkened(0.35))
	p.draw_line(Vector2(46, y0 + 2), Vector2(58, y0 + 8), ROBE_HI, 1.0)
	# 흰 깃 + 금테 V자
	var cx := fc.x
	p.draw_colored_polygon(PackedVector2Array([Vector2(cx - 9, y0 + 1), Vector2(cx, y0 + 12), Vector2(cx + 9, y0 + 1), Vector2(cx + 5, y0 + 1), Vector2(cx, y0 + 7), Vector2(cx - 5, y0 + 1)]), Color("#e2e5f6"))
	p.draw_line(Vector2(cx - 9, y0 + 1), Vector2(cx, y0 + 12), GOLD, 1.0)
	p.draw_line(Vector2(cx + 9, y0 + 1), Vector2(cx, y0 + 12), GOLD, 1.0)
	var sc := Vector2(cx, y0 + 11)
	p.draw_circle(sc, 4.0, Color(STAR, 0.2))
	StArt.star(p, sc, 3.0, STAR if not poss else Color("#c8c8d8"), -PI * 0.5 + sin(t) * 0.15)
	StArt.constellation(p, [Vector2(16, y0 + 12), Vector2(20, y0 + 8), Vector2(24, y0 + 13), Vector2(21, 71)], GOLD, 0.6 + 0.3 * sin(t * 1.2), 1.0)
	StArt.constellation(p, [Vector2(48, y0 + 10), Vector2(52, y0 + 13), Vector2(56, y0 + 10), Vector2(54, 71)], GOLD, 0.6 + 0.3 * sin(t * 1.2 + 1.5), 1.0)


static func _face(p: Portrait, fc: Vector2, expr: String, t: float, talking: bool, blinking: bool, poss: bool, aged: bool) -> void:
	var skin := SKIN.lerp(Color("#eef0fa"), 0.55 if poss else 0.0)
	var face := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var s := sin(a)
		var px := cos(a) * 12.0
		var py := s * (12.5 if s < 0 else 14.0)
		if s > 0.3:
			px *= 1.0 - (s - 0.3) * 0.45 # 갸름한 턱
		face.append(fc + Vector2(px, py))
	p.draw_colored_polygon(face, skin)
	p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-12, -2), fc + Vector2(-10, -7), fc + Vector2(-9.5, 6), fc + Vector2(-8, 11), fc + Vector2(-10.5, 6)]), SKIN_SH)
	if not poss:
		var blush := 0.55 if expr in ["happy", "surprised"] else 0.32
		p.draw_rect(Rect2(fc.x - 10, fc.y + 5, 4, 2), Color(1.0, 0.58, 0.68, blush))
		p.draw_rect(Rect2(fc.x + 6, fc.y + 5, 4, 2), Color(1.0, 0.58, 0.68, blush))
	_eyes(p, fc, expr, t, blinking, poss, aged)
	_mouth(p, fc, expr, t, talking, poss)
	if aged:
		p.draw_line(fc + Vector2(-11, 1), fc + Vector2(-10, 3), SKIN_SH.darkened(0.12), 1.0)
		p.draw_line(fc + Vector2(11, 1), fc + Vector2(10, 3), SKIN_SH.darkened(0.12), 1.0)


static func _eyes(p: Portrait, fc: Vector2, expr: String, t: float, blinking: bool, poss: bool, aged: bool) -> void:
	var l := fc + Vector2(-5.5, 1)
	var r := fc + Vector2(5.5, 1)
	var brow := HAIR_SH.darkened(0.12)
	match expr:
		"sad":
			p.draw_line(l + Vector2(-3, -6), l + Vector2(2, -8), brow, 1.0)
			p.draw_line(r + Vector2(3, -6), r + Vector2(-2, -8), brow, 1.0)
		"serious":
			p.draw_line(l + Vector2(-3, -7), l + Vector2(3, -6), brow, 1.0)
			p.draw_line(r + Vector2(3, -7), r + Vector2(-3, -6), brow, 1.0)
		"surprised":
			p.draw_line(l + Vector2(-3, -9), l + Vector2(3, -9), brow, 1.0)
			p.draw_line(r + Vector2(-3, -9), r + Vector2(3, -9), brow, 1.0)
		_:
			p.draw_line(l + Vector2(-3, -7), l + Vector2(3, -7.5), brow, 1.0)
			p.draw_line(r + Vector2(-3, -7.5), r + Vector2(3, -7), brow, 1.0)
	if poss:
		for e in [l, r]:
			var ev: Vector2 = e
			p.draw_circle(ev, 6.0, Color(1, 1, 1, 0.15 + 0.1 * sin(t * 5.0)))
			p.draw_colored_polygon(_almond(ev, 3.8, 3.2), WHITE_GOD)
			p.draw_line(ev + Vector2(-4, -3), ev + Vector2(4, -3), LASH, 1.0)
		return
	var closed := blinking and expr != "surprised"
	if expr == "happy" or closed:
		for e in [l, r]:
			var ev: Vector2 = e
			if expr == "happy" and not closed:
				p.draw_arc(ev + Vector2(0, 2), 3.5, PI + 0.2, TAU - 0.2, 8, LASH, 1.5)
			else:
				p.draw_line(ev + Vector2(-3.5, 1), ev + Vector2(3.5, 1.5), LASH, 1.0)
				p.draw_line(ev + Vector2(3.5, 1.5), ev + Vector2(4.5, 0.5), LASH, 1.0)
		return
	# 눈꺼풀 (반쯤 감은 다정한 눈 → 놀람)
	var lid := 0.0
	match expr:
		"normal": lid = 0.3
		"sad": lid = 1.5
		"serious": lid = 1.0
		"surprised": lid = -0.8
		"weak": lid = 2.2
		"aged": lid = 0.8
	for e in [l, r]:
		var ev: Vector2 = e
		var out := 1.0 if ev.x > fc.x else -1.0
		var hw := 3.8 if expr != "surprised" else 4.0
		var hh := 4.0 if expr != "surprised" else 4.5
		# 흰자 (아몬드)
		p.draw_colored_polygon(_almond(ev, hw, hh), Color("#fbf8ff"))
		# 홍채: 위가 짙고 아래로 밝아짐
		var ic := ev + Vector2(0, 0.3)
		p.draw_circle(ic, 3.0, EYE)
		p.draw_rect(Rect2(ic.x - 2.6, ic.y - 3.0, 5.2, 1.6), EYE_DEEP)
		p.draw_rect(Rect2(ic.x - 2.0, ic.y + 1.4, 4.0, 1.3), EYE_HI)
		# 별 동공 (늙기 시작하면 사라짐)
		if not aged:
			var k := 0.75 + 0.25 * sin(t * 2.5 + ev.x)
			StArt.star(p, ic + Vector2(0, 0.2), 1.9, Color(STAR_CORE, k), -PI * 0.5)
		else:
			p.draw_rect(Rect2(ic - Vector2(1, 1), Vector2(2, 2)), EYE_DEEP)
		p.draw_rect(Rect2(ic + Vector2(-2.2, -2.4), Vector2(1.4, 1.4)), Color(1, 1, 1, 0.95))
		# 눈꺼풀 (위에서 덮음)
		if lid > 0.0:
			p.draw_rect(Rect2(ev.x - hw - 0.5, ev.y - hh - 0.5, hw * 2.0 + 1.0, lid + 0.5), SKIN)
		# 위 속눈썹: 굵게, 바깥 끝이 위로 날림
		var ly := ev.y - hh + maxf(lid, 0.0)
		p.draw_line(Vector2(ev.x - hw, ly + 0.8), Vector2(ev.x + hw, ly), LASH, 1.5)
		p.draw_line(Vector2(ev.x + out * hw, ly + (0.0 if out > 0 else 0.8)), Vector2(ev.x + out * (hw + 2.2), ly - 1.6), LASH, 1.0)
		p.draw_line(Vector2(ev.x - hw * 0.6, ev.y + hh - 0.5), Vector2(ev.x + hw * 0.6, ev.y + hh - 0.5), Color(LASH, 0.3), 1.0)
		if expr == "sad":
			p.draw_rect(Rect2(ev.x + out * 2.5, ev.y + hh, 1, 2), Color(0.8, 0.9, 1.0, 0.6 + 0.3 * sin(t * 3.0)))


static func _almond(c: Vector2, hw: float, hh: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		var y := sin(a) * hh
		pts.append(c + Vector2(cos(a) * hw, y * (1.0 if y < 0 else 0.8)))
	return pts


static func _mouth(p: Portrait, fc: Vector2, expr: String, t: float, talking: bool, poss: bool) -> void:
	var m := fc + Vector2(0, 9)
	var col := Color("#b8606a")
	if poss:
		p.draw_line(m + Vector2(-2, 0), m + Vector2(2, 0), Color("#8a8aa0"), 1.0)
		return
	if talking and int(t * 12.0) % 2 == 0:
		p.draw_rect(Rect2(m.x - 1.5, m.y - 0.5, 3, 2.5), Color("#a04a58"))
		return
	match expr:
		"happy":
			p.draw_arc(m + Vector2(0, -2), 3.0, 0.25, PI - 0.25, 8, col, 1.5)
		"sad":
			p.draw_arc(m + Vector2(0, 2), 2.0, PI + 0.4, TAU - 0.4, 6, col, 1.0)
		"serious":
			p.draw_line(m + Vector2(-1.5, 0), m + Vector2(1.5, 0), col, 1.0)
		"surprised":
			p.draw_circle(m, 1.6, Color("#a04a58"))
		_:
			p.draw_arc(m + Vector2(0, -1.5), 2.2, 0.35, PI - 0.35, 6, col, 1.0)


static func _hair_front(p: Portrait, fc: Vector2, t: float, poss: bool, aged: bool) -> void:
	var base := HAIR.lerp(WHITE_GOD, 0.3 if poss else 0.0)
	var sh := HAIR_SH.lerp(WHITE_GOD, 0.3 if poss else 0.0)
	# 옆머리: 관자놀이에서 가슴까지, 끝이 가늘게 말림
	for side: float in [-1.0, 1.0]:
		var sw := sin(t * 1.5 + side * 2.0) * 0.8
		p.draw_colored_polygon(PackedVector2Array([
			fc + Vector2(side * 9.5, -10), fc + Vector2(side * 13.5, -6), fc + Vector2(side * 13.5 + sw * 0.5, 6),
			fc + Vector2(side * 12.5 + sw, 18), fc + Vector2(side * 9.5 + sw * 1.4, 27), fc + Vector2(side * 10.5 + sw, 16), fc + Vector2(side * 10.5, 2),
		]), base)
		p.draw_line(fc + Vector2(side * 12, -4), fc + Vector2(side * 11.5 + sw, 18), sh, 1.0)
		p.draw_line(fc + Vector2(side * 13, -6), fc + Vector2(side * 13, 4), HAIR_HI, 1.0)
	# 앞머리: 뾰족한 가닥 여러 개 (가르마는 왼쪽)
	var tips := [[-12.0, -1.0], [-9.5, 2.5], [-6.5, -1.5], [-3.5, 3.0], [-0.5, -2.5], [2.5, 2.0], [5.5, -2.0], [8.5, 3.0], [11.5, 0.0]]
	var bangs := PackedVector2Array([fc + Vector2(-13, -6), fc + Vector2(-9, -13), fc + Vector2(-3, -15.5), fc + Vector2(4, -15), fc + Vector2(10, -12), fc + Vector2(13, -6)])
	for i in range(tips.size() - 1, -1, -1):
		var tx: float = tips[i][0]
		var ty: float = tips[i][1]
		bangs.append(fc + Vector2(tx, ty))
		if i > 0:
			var px: float = tips[i - 1][0]
			bangs.append(fc + Vector2((tx + px) * 0.5, -7.0 + absf(tx) * 0.12))
	p.draw_colored_polygon(bangs, base)
	p.draw_line(fc + Vector2(-9, -11), fc + Vector2(-2, -14), HAIR_HI, 1.0)
	p.draw_line(fc + Vector2(-6.5, -7), fc + Vector2(-6.5, -1.5), sh, 1.0)
	p.draw_line(fc + Vector2(2.5, -8), fc + Vector2(2.5, 1.5), sh, 1.0)
	p.draw_line(fc + Vector2(8.5, -8), fc + Vector2(8.5, 2), sh, 1.0)
	if not aged:
		StArt.sparkle(p, fc + Vector2(-8, -9), 2.5, STAR, StArt.twinkle(t, 4.0, 1.4))
		StArt.sparkle(p, fc + Vector2(11, -3), 2.0, STAR, StArt.twinkle(t, 7.0, 1.2))


static func _hat(p: Portrait, fc: Vector2, t: float, poss: bool, expr: String) -> void:
	var hat := HAT.lerp(Color("#4a4a62"), 0.4 if poss else 0.0)
	var tilt := -0.07 if expr != "weak" else 0.12
	var bc := fc + Vector2(-1, -15)
	# 챙: 화면 밖으로 넘칠 만큼 넓다 (아래는 그림자, 윗면은 남색)
	var brim := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		brim.append(bc + Vector2(cos(a) * 40.0, sin(a) * (4.5 if sin(a) > 0 else 3.5)).rotated(tilt))
	p.draw_colored_polygon(brim, HAT_SH)
	var top := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		top.append(bc + Vector2(cos(a) * 39.0, sin(a) * 3.2 - 0.5).rotated(tilt))
	for i in range(12, -1, -1):
		var a := PI + PI * i / 12.0
		top.append(bc + Vector2(cos(a) * 34.0, sin(a) * 1.0 + 1.0).rotated(tilt))
	p.draw_colored_polygon(top, hat)
	p.draw_line(bc + Vector2(-38, 0.5).rotated(tilt), bc + Vector2(38, 0.5).rotated(tilt), Color("#36428e"), 1.0)
	# 고깔: 뒤로 기울다 끝이 초승달처럼 말림
	var sway := sin(t * 1.2) * 1.0
	var cone := PackedVector2Array([
		bc + Vector2(-13, -1).rotated(tilt), bc + Vector2(13, -1).rotated(tilt), bc + Vector2(6, -12).rotated(tilt),
		bc + Vector2(-2 + sway * 0.4, -21).rotated(tilt), bc + Vector2(-12 + sway, -27).rotated(tilt), bc + Vector2(-21 + sway, -26).rotated(tilt),
		bc + Vector2(-26 + sway, -21).rotated(tilt), bc + Vector2(-23 + sway, -23).rotated(tilt), bc + Vector2(-14 + sway * 0.6, -21).rotated(tilt),
		bc + Vector2(-8, -12).rotated(tilt),
	])
	p.draw_colored_polygon(cone, hat)
	p.draw_line(bc + Vector2(-8, -12).rotated(tilt), bc + Vector2(-13, -1).rotated(tilt), HAT_SH, 2.0)
	p.draw_line(bc + Vector2(13, -1).rotated(tilt), bc + Vector2(6, -12).rotated(tilt), Color("#3c4ca6"), 1.0)
	p.draw_line(bc + Vector2(6, -12).rotated(tilt), bc + Vector2(-2 + sway * 0.4, -21).rotated(tilt), Color("#3c4ca6"), 1.0)
	p.draw_line(bc + Vector2(-2 + sway * 0.4, -22).rotated(tilt), bc + Vector2(-21 + sway, -27).rotated(tilt), Color(GOLD, 0.5), 1.0)
	p.draw_line(bc + Vector2(-12, -3).rotated(tilt), bc + Vector2(12, -3).rotated(tilt), Color("#a88a4a"), 3.0)
	p.draw_line(bc + Vector2(-12, -4).rotated(tilt), bc + Vector2(12, -4).rotated(tilt), GOLD, 1.0)
	for i in 3:
		StArt.star(p, bc + Vector2(-6 + i * 6, -3.5).rotated(tilt), 1.6, STAR, -PI * 0.5)
	var tip := bc + Vector2(-26 + sway, -21).rotated(tilt)
	var sw := sin(t * 2.0) * 0.4
	var sp := tip + Vector2(sin(sw), cos(sw)) * 9.0
	p.draw_line(tip, sp, Color(GOLD, 0.8), 1.0)
	var sc := STAR if not poss else Color("#c8c8d8")
	p.draw_circle(sp, 5.0, Color(sc, 0.18))
	StArt.star(p, sp, 3.5, sc, -PI * 0.5 + sw)
	if not poss:
		StArt.sparkle(p, sp + Vector2(4, -3), 2.5, STAR, StArt.twinkle(t, 2.0, 1.3))


static func _stars(p: Portrait, fc: Vector2, t: float, front: bool, poss: bool, aged: bool) -> void:
	if aged:
		return
	var c := fc + Vector2(0, 16)
	for i in 7:
		var a := (t * 0.7 if not poss else 0.8) + TAU * i / 7.0
		var depth := sin(a)
		if (depth > 0.0) != front:
			continue
		var q := c + Vector2(cos(a) * 31.0, depth * 7.0 - 3.0)
		var col := STAR if not poss else Color("#9a9aaa")
		q.x = clampf(q.x, 2.0, 70.0)
		p.draw_circle(q, 3.0, Color(col, 0.15 if front else 0.07))
		StArt.star(p, q, 2.2 if front else 1.4, Color(col, 1.0 if front else 0.6), t + i)


static func _cracks(p: Portrait, fc: Vector2, t: float) -> void:
	var col := Color(1, 1, 1, 0.7 + 0.3 * sin(t * 4.0))
	p.draw_polyline(PackedVector2Array([fc + Vector2(-3, -14), fc + Vector2(-1, -9), fc + Vector2(-4, -4), fc + Vector2(-2, 1)]), col, 1.0)
	p.draw_polyline(PackedVector2Array([fc + Vector2(6, 6), fc + Vector2(8, 10), fc + Vector2(6, 14)]), col, 1.0)
	p.draw_polyline(PackedVector2Array([Vector2(30, 56), Vector2(34, 61), Vector2(31, 66), Vector2(35, 72)]), col, 1.0)
	p.draw_polyline(PackedVector2Array([fc + Vector2(-4, -4), fc + Vector2(-9, -1)]), col, 1.0)


## 어깨 위로 흘러내려 화면 아래까지 닿는 머리타래 (바닥까지 끌리는 머리)
static func _tresses(p: Portrait, fc: Vector2, t: float, poss: bool) -> void:
	var base := HAIR.lerp(WHITE_GOD, 0.3 if poss else 0.0)
	var sh := HAIR_SH.lerp(WHITE_GOD, 0.3 if poss else 0.0)
	for side: float in [-1.0, 1.0]:
		var sw := sin(t * 1.3 + side * 1.7) * 1.2
		p.draw_colored_polygon(PackedVector2Array([
			fc + Vector2(side * 12, 6), fc + Vector2(side * 16, 10), fc + Vector2(side * 18 + sw, 22), fc + Vector2(side * 19 + sw * 1.5, 34),
			fc + Vector2(side * 13 + sw, 34), fc + Vector2(side * 13.5 + sw * 0.5, 22), fc + Vector2(side * 11, 12),
		]), sh)
		p.draw_colored_polygon(PackedVector2Array([
			fc + Vector2(side * 13, 8), fc + Vector2(side * 15.5, 11), fc + Vector2(side * 16.5 + sw, 22), fc + Vector2(side * 17 + sw * 1.5, 34),
			fc + Vector2(side * 15 + sw, 34), fc + Vector2(side * 14.5 + sw * 0.5, 22), fc + Vector2(side * 12.5, 12),
		]), base)
		p.draw_line(fc + Vector2(side * 14.5, 12), fc + Vector2(side * 16 + sw, 30), HAIR_HI, 1.0)
