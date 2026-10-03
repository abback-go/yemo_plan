extends RefCounted
## 아우렐리아 대화 초상화 (72×72) — Portrait가 static draw_portrait(p, info, expr, t, talking, blinking)를 부른다.
## 표정: normal(굳은 얼굴) · angry · surprised · sad · smile(옅은 미소 — 4장 끝에 한 번, happy도 이것) · berserk(폭주: 하얀 눈, 금 간 광륜)
## 인물 정보에 "berserk": true (Characters ID "aurelia_berserk")면 표정과 상관없이 폭주 그림.

const OUTL := Color("#16101f")
const ARM := Color("#ece8f4")
const ARM_S := Color("#a9a3c6")
const ARM_L := Color("#ffffff")
const GOLD := Color("#e9b949")
const GOLD_S := Color("#a5742a")
const GOLD_L := Color("#fff1a8")
const HAIR := Color("#f2c55a")
const HAIR_S := Color("#c48934")
const HAIR_L := Color("#fff0a6")
const HAIR_D := Color("#8e5c26")
const SKIN := Color("#f7dcc9")
const SKIN_S := Color("#dfb3a0")
const EYE := Color("#d48a1a")
const EYE_D := Color("#8a4a10")
const BLADE := Color("#e6ecf8")
const WHITE_FIRE := Color(1.0, 0.97, 0.84)


static func draw_portrait(p: Portrait, info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	var berserk := expr == "berserk" or bool(info.get("berserk", false))
	if expr == "happy":
		expr = "smile"
	var bob := sin(t * 2.0) * 0.5 + (sin(t * 18.0) * 0.4 if talking else 0.0)
	var fc := Vector2(36, 37 + bob)
	var hair := HAIR.lerp(Color(1.0, 0.96, 0.82), 0.4) if berserk else HAIR
	var trim := GOLD.lerp(WHITE_FIRE, 0.5) if berserk else GOLD
	if berserk:
		p.draw_rect(Rect2(0, 0, 72, 72), Color(1.0, 0.95, 0.8, 0.06 + 0.03 * sin(t * 7.0)))
	# 광륜 (머리 뒤 큰 원반)
	_halo(p, fc + Vector2(0, -6), 25.0, t, berserk)
	# 창 (오른쪽에 세워 듦): 자루 + 날개 모양 날
	_spear(p, Vector2(62, 74), Vector2(62, 6), t, berserk, trim)
	# 뒷머리 (어깨 뒤로 길게)
	var sway := sin(t * 1.6) * 1.0
	var lift := -4.0 if berserk else 0.0
	p.draw_colored_polygon(PackedVector2Array([
		fc + Vector2(-16, -14), fc + Vector2(16, -14), fc + Vector2(19, 6), fc + Vector2(22 + sway, 36 + lift),
		fc + Vector2(-22 + sway, 36 + lift), fc + Vector2(-19, 6),
	]), OUTL)
	p.draw_colored_polygon(PackedVector2Array([
		fc + Vector2(-15, -13), fc + Vector2(15, -13), fc + Vector2(18, 6), fc + Vector2(21 + sway, 36 + lift),
		fc + Vector2(-21 + sway, 36 + lift), fc + Vector2(-18, 6),
	]), hair)
	for i in 4:
		var x := -17.0 + i * 3.0
		p.draw_line(fc + Vector2(x, 2), fc + Vector2(x - 2.0 + sway, 34 + lift), HAIR_S if not berserk else Color(1, 0.9, 0.7), 1.0)
		p.draw_line(fc + Vector2(-x, 2), fc + Vector2(-x + 2.0 + sway, 34 + lift), HAIR_S if not berserk else Color(1, 0.9, 0.7), 1.0)
	p.draw_line(fc + Vector2(-19, 8), fc + Vector2(-20 + sway, 30 + lift), HAIR_L if not berserk else Color.WHITE, 1.0)
	# 어깨·갑옷
	_armor(p, fc, trim, berserk)
	# 목
	p.draw_rect(Rect2(fc.x - 4, fc.y + 10, 8, 8), SKIN_S)
	p.draw_rect(Rect2(fc.x - 4, fc.y + 10, 2, 8), SKIN_S.darkened(0.08))
	# 얼굴
	var face := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var rx := 12.0
		var ry := 13.5 if sin(a) < 0 else 15.0
		var q := Vector2(cos(a) * rx, sin(a) * ry)
		if sin(a) > 0.5:
			q.x *= 0.82 + 0.18 * (1.0 - sin(a)) # 갸름한 턱
		face.append(fc + q)
	var face_o := PackedVector2Array()
	for q in face:
		face_o.append(fc + (q - fc) * 1.08)
	p.draw_colored_polygon(face_o, OUTL)
	p.draw_colored_polygon(face, SKIN)
	p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-12, -2), fc + Vector2(-8, -2), fc + Vector2(-6, 12), fc + Vector2(-9, 9)]), SKIN_S)
	_eyes(p, fc, expr, t, blinking, berserk)
	_mouth(p, fc, expr, t, talking, berserk)
	# 코
	p.draw_line(fc + Vector2(0.5, 4), fc + Vector2(1.5, 7), SKIN_S, 1.0)
	# 볼 (옅은 미소·놀람)
	if expr in ["smile", "surprised"]:
		p.draw_rect(Rect2(fc.x - 10, fc.y + 6, 4, 2), Color(1.0, 0.55, 0.55, 0.3))
		p.draw_rect(Rect2(fc.x + 6, fc.y + 6, 4, 2), Color(1.0, 0.55, 0.55, 0.3))
	# 옆머리 (얼굴 양옆으로 턱까지)
	for s: float in [-1.0, 1.0]:
		var lk := PackedVector2Array([fc + Vector2(s * 9, -10), fc + Vector2(s * 14, -6), fc + Vector2(s * 14.5, 8 + lift * 0.3), fc + Vector2(s * 12, 16 + lift * 0.5), fc + Vector2(s * 10.5, 4)])
		p.draw_colored_polygon(lk, hair)
		p.draw_line(fc + Vector2(s * 12, -6), fc + Vector2(s * 12.5, 12), HAIR_S, 1.0)
	# 앞머리 (가르마 + 이마를 덮는 갈래)
	var bang := PackedVector2Array([
		fc + Vector2(-14, -4), fc + Vector2(-13, -12), fc + Vector2(-6, -16), fc + Vector2(5, -16), fc + Vector2(13, -12),
		fc + Vector2(14, -4), fc + Vector2(10, -8), fc + Vector2(7, -3), fc + Vector2(4, -9), fc + Vector2(0, -5),
		fc + Vector2(-3, -10), fc + Vector2(-7, -4), fc + Vector2(-10, -9),
	])
	p.draw_colored_polygon(bang, hair)
	p.draw_line(fc + Vector2(-10, -13), fc + Vector2(-1, -15), HAIR_L if not berserk else Color.WHITE, 1.0)
	p.draw_line(fc + Vector2(4, -14), fc + Vector2(11, -11), HAIR_L if not berserk else Color.WHITE, 1.0)
	p.draw_line(fc + Vector2(-4, -12), fc + Vector2(-6, -5), HAIR_S, 1.0)
	p.draw_line(fc + Vector2(6, -12), fc + Vector2(8, -5), HAIR_S, 1.0)
	# 땋아 올린 왕관 머리 (이마 위를 두르는 땋은 띠)
	for i in 13:
		var a := PI * 1.08 + PI * 0.84 * float(i) / 12.0
		var q := fc + Vector2(cos(a) * 15.0, sin(a) * 13.5 - 2.0)
		p.draw_circle(q, 3.0, OUTL)
	for i in 13:
		var a := PI * 1.08 + PI * 0.84 * float(i) / 12.0
		var q := fc + Vector2(cos(a) * 15.0, sin(a) * 13.5 - 2.0)
		p.draw_circle(q, 2.4, HAIR_S if i % 2 == 0 else hair)
		p.draw_line(q + Vector2(-1.2, -1.2), q + Vector2(0.8, 0.4), HAIR_L if not berserk else Color.WHITE, 1.0)
	# 금 머리핀
	p.draw_circle(fc + Vector2(-12, -12), 1.8, GOLD_L)
	p.draw_circle(fc + Vector2(-12, -12), 0.8, GOLD_S)
	if berserk:
		_berserk_fire(p, fc, t)


static func _halo(p: CanvasItem, c: Vector2, r: float, t: float, berserk: bool) -> void:
	var gold := Color(1.0, 0.86, 0.45)
	for i in 4:
		p.draw_circle(c, r * (1.35 - i * 0.12), Color(gold if not berserk else WHITE_FIRE, 0.03 + i * 0.02))
	if not berserk:
		p.draw_arc(c, r, 0, TAU, 48, Color(OUTL, 0.5), 4.0)
		p.draw_arc(c, r, 0, TAU, 48, gold, 2.0)
		p.draw_arc(c, r * 0.8, 0, TAU, 40, Color(gold, 0.45), 1.0)
		for i in 24:
			var a := t * 0.25 + TAU * i / 24.0
			p.draw_line(c + Vector2(cos(a), sin(a)) * (r + 2.0), c + Vector2(cos(a), sin(a)) * (r + (5.0 if i % 2 == 0 else 3.5)), Color(gold, 0.8), 1.0)
		var sa := t * 0.9
		p.draw_circle(c + Vector2(cos(sa), sin(sa)) * r, 1.8, Color(1, 1, 0.9))
		return
	var gaps: Array[float] = [0.4, 2.1, 3.9, 5.2]
	for i in gaps.size():
		var a0 := gaps[i] + 0.15
		var a1 := gaps[(i + 1) % gaps.size()] - 0.15 + (TAU if i == gaps.size() - 1 else 0.0)
		p.draw_arc(c, r, a0, a1, 16, Color(OUTL, 0.5), 4.0)
		p.draw_arc(c, r, a0, a1, 16, Color(1.0, 0.95, 0.75), 2.0)
	for i in gaps.size():
		var a := gaps[i]
		var q := c + Vector2(cos(a), sin(a)) * r
		var fl := 0.6 + 0.4 * sin(t * 15.0 + i * 2.0)
		p.draw_circle(q, 5.0, Color(1, 1, 1, 0.3 * fl))
		p.draw_line(q, q + Vector2(cos(a), sin(a)) * (8.0 + 5.0 * fl), Color(1, 1, 1, 0.85 * fl), 1.0)
		p.draw_polyline(PackedVector2Array([c + Vector2(cos(a), sin(a)) * r * 0.5, c + Vector2(cos(a + 0.12), sin(a + 0.12)) * r * 0.7, c + Vector2(cos(a - 0.08), sin(a - 0.08)) * r * 0.85, q]), Color(1, 1, 1, 0.8), 1.0)


static func _spear(p: CanvasItem, butt: Vector2, tip: Vector2, t: float, berserk: bool, trim: Color) -> void:
	var base := tip + Vector2(0, 16)
	p.draw_line(butt, base, OUTL, 5.0)
	p.draw_line(butt, base, Color("#f0e4c8"), 3.0)
	p.draw_line(butt + Vector2(1, 0), base + Vector2(1, 0), Color("#b89e70"), 1.0)
	for k in 3:
		var y := base.y + 12.0 + k * 16.0
		p.draw_line(Vector2(butt.x - 2.5, y), Vector2(butt.x + 2.5, y), trim, 2.0)
	for s: float in [-1.0, 1.0]:
		var w := PackedVector2Array([base + Vector2(s * 1.5, 0), base + Vector2(s * 6, -2), base + Vector2(s * 11, 5), base + Vector2(s * 8, 9), base + Vector2(s * 4, 4), base + Vector2(s * 1.5, 3)])
		p.draw_colored_polygon(w, trim)
		p.draw_line(base + Vector2(s * 3, 0), base + Vector2(s * 9, 5), GOLD_L if not berserk else Color.WHITE, 1.0)
	var leaf := PackedVector2Array([base + Vector2(-3, 0), base + Vector2(-4.5, -7), tip, base + Vector2(4.5, -7), base + Vector2(3, 0)])
	var lo := PackedVector2Array()
	for q in leaf:
		lo.append(base + (q - base) * 1.12 + Vector2(0, 0.5))
	p.draw_colored_polygon(lo, OUTL)
	p.draw_colored_polygon(leaf, BLADE)
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(0, 0), tip, base + Vector2(4.5, -7), base + Vector2(3, 0)]), Color("#9aa4c4"))
	p.draw_line(base + Vector2(0, -1), tip + Vector2(0, 2), Color.WHITE, 1.0)
	p.draw_circle(base, 2.5, trim)
	p.draw_circle(base, 1.2, Color("#5ac8f0") if not berserk else Color.WHITE)
	var g := clampf(1.0 - fmod(t, 3.0) / 0.5, 0.0, 1.0)
	if g > 0.0:
		var gp := base.lerp(tip, 1.0 - g)
		p.draw_line(gp + Vector2(-3, 0), gp + Vector2(3, 0), Color(1, 1, 1, g), 1.0)
		p.draw_line(gp + Vector2(0, -3), gp + Vector2(0, 3), Color(1, 1, 1, g), 1.0)


static func _armor(p: CanvasItem, fc: Vector2, trim: Color, berserk: bool) -> void:
	# 흉갑 윗부분
	p.draw_colored_polygon(PackedVector2Array([Vector2(14, 74), Vector2(20, 58 + fc.y - 37), Vector2(52, 58 + fc.y - 37), Vector2(58, 74)]), OUTL)
	p.draw_colored_polygon(PackedVector2Array([Vector2(15, 73), Vector2(21, 59 + fc.y - 37), Vector2(51, 59 + fc.y - 37), Vector2(57, 73)]), ARM)
	p.draw_colored_polygon(PackedVector2Array([Vector2(15, 73), Vector2(21, 59 + fc.y - 37), Vector2(28, 59 + fc.y - 37), Vector2(26, 73)]), ARM_S)
	p.draw_line(Vector2(36, 60 + fc.y - 37), Vector2(36, 73), Color(trim, 0.8), 1.0)
	var sun := Vector2(36, 67 + fc.y - 37)
	p.draw_circle(sun, 3.0, trim)
	p.draw_circle(sun, 1.6, GOLD_L if not berserk else Color.WHITE)
	for i in 8:
		var a := TAU * i / 8.0
		p.draw_line(sun + Vector2(cos(a), sin(a)) * 3.5, sun + Vector2(cos(a), sin(a)) * 5.0, trim, 1.0)
	# 목가리개 (금)
	p.draw_colored_polygon(PackedVector2Array([Vector2(26, 58 + fc.y - 37), Vector2(46, 58 + fc.y - 37), Vector2(43, 53 + fc.y - 37), Vector2(29, 53 + fc.y - 37)]), GOLD_S)
	p.draw_line(Vector2(28, 54 + fc.y - 37), Vector2(44, 54 + fc.y - 37), trim, 1.0)
	# 어깨갑 (양쪽, 두 겹)
	for s: float in [-1.0, 1.0]:
		var c := Vector2(36 + s * 19, 62 + fc.y - 37)
		var top := PackedVector2Array([c + Vector2(-9, 6), c + Vector2(-8, -3), c + Vector2(-2, -7), c + Vector2(5, -6), c + Vector2(10, 0), c + Vector2(9, 8)])
		var o := PackedVector2Array()
		for q in top:
			o.append(c + (q - c) * 1.1)
		p.draw_colored_polygon(o, OUTL)
		p.draw_colored_polygon(top, ARM if s > 0 else ARM_S.lerp(ARM, 0.5))
		p.draw_line(c + Vector2(-8, 5), c + Vector2(9, 6), trim, 1.0)
		p.draw_line(c + Vector2(-5, -4), c + Vector2(3, -5), ARM_L, 1.0)
		p.draw_circle(c + Vector2(0, 0), 1.2, trim)


static func _eyes(p: CanvasItem, fc: Vector2, expr: String, t: float, blinking: bool, berserk: bool) -> void:
	var l := fc + Vector2(-6, 2)
	var r := fc + Vector2(6, 2)
	if berserk:
		for q in [l, r]:
			var qq: Vector2 = q
			p.draw_circle(qq, 5.0, Color(1, 1, 1, 0.18 + 0.1 * sin(t * 11.0)))
			p.draw_rect(Rect2(qq.x - 3, qq.y - 1, 6, 3), Color.WHITE)
			p.draw_line(qq + Vector2(-3.5, -2), qq + Vector2(3.5, -2), HAIR_D, 1.0)
		p.draw_line(l + Vector2(-4, -5), l + Vector2(3, -3), HAIR_D, 1.5)
		p.draw_line(r + Vector2(4, -5), r + Vector2(-3, -3), HAIR_D, 1.5)
		return
	if blinking and expr != "surprised":
		for q in [l, r]:
			var qq: Vector2 = q
			p.draw_line(qq + Vector2(-3, 0.5), qq + Vector2(3, 0.5), HAIR_D, 1.0)
		_brows(p, l, r, expr)
		return
	match expr:
		"surprised":
			for q in [l, r]:
				var qq: Vector2 = q
				p.draw_circle(qq, 3.6, Color.WHITE)
				p.draw_circle(qq, 2.2, EYE)
				p.draw_circle(qq, 1.0, EYE_D)
				p.draw_rect(Rect2(qq.x - 1.5, qq.y - 2, 1, 1), Color.WHITE)
		"sad":
			for q in [l, r]:
				var qq: Vector2 = q
				p.draw_rect(Rect2(qq.x - 3, qq.y, 6, 3), Color.WHITE)
				p.draw_rect(Rect2(qq.x - 1.5, qq.y + 0.5, 3, 2.5), EYE)
				p.draw_line(qq + Vector2(-3.5, -0.5), qq + Vector2(3.5, -0.5), HAIR_D, 1.5)
		"smile":
			# 옅은 미소: 눈을 뜬 채 아래 눈꺼풀이 살짝 올라가 부드러워진 눈
			for q in [l, r]:
				var qq: Vector2 = q
				p.draw_rect(Rect2(qq.x - 3, qq.y - 0.5, 6, 3), Color.WHITE)
				p.draw_rect(Rect2(qq.x - 1.5, qq.y - 0.5, 3, 3), EYE)
				p.draw_rect(Rect2(qq.x - 0.5, qq.y + 0.5, 1, 1), EYE_D)
				p.draw_rect(Rect2(qq.x - 1.5, qq.y - 0.5, 1, 1), Color(1, 1, 1, 0.95))
				p.draw_line(qq + Vector2(-3.5, -1.2), qq + Vector2(3.5, -1.2), HAIR_D, 1.5)
				p.draw_line(qq + Vector2(-2.5, 2.8), qq + Vector2(2.5, 2.4), Color(SKIN_S, 0.9), 1.0)
		"angry":
			for q in [l, r]:
				var qq: Vector2 = q
				p.draw_rect(Rect2(qq.x - 3, qq.y - 0.5, 6, 2.5), Color.WHITE)
				p.draw_rect(Rect2(qq.x - 1.5, qq.y - 0.5, 3, 2.5), EYE)
				p.draw_rect(Rect2(qq.x - 0.5, qq.y, 1, 1), EYE_D)
				p.draw_line(qq + Vector2(-3.5, -1), qq + Vector2(3.5, -1), HAIR_D, 2.0)
		_:
			# 굳은 눈: 가늘고 곧은 눈, 금빛 눈동자
			for q in [l, r]:
				var qq: Vector2 = q
				p.draw_rect(Rect2(qq.x - 3, qq.y - 1, 6, 3.5), Color.WHITE)
				p.draw_rect(Rect2(qq.x - 1.5, qq.y - 1, 3, 3.5), EYE)
				p.draw_rect(Rect2(qq.x - 0.5, qq.y, 1, 1.5), EYE_D)
				p.draw_rect(Rect2(qq.x - 1.5, qq.y - 1, 1, 1), Color(1, 1, 1, 0.9))
				p.draw_line(qq + Vector2(-3.5, -1.5), qq + Vector2(3.5, -1.5), HAIR_D, 1.5)
	_brows(p, l, r, expr)


static func _brows(p: CanvasItem, l: Vector2, r: Vector2, expr: String) -> void:
	match expr:
		"angry":
			p.draw_line(l + Vector2(-4, -6), l + Vector2(3, -3.5), HAIR_D, 1.5)
			p.draw_line(r + Vector2(4, -6), r + Vector2(-3, -3.5), HAIR_D, 1.5)
		"surprised":
			p.draw_line(l + Vector2(-3, -7), l + Vector2(3, -7.5), HAIR_D, 1.0)
			p.draw_line(r + Vector2(-3, -7.5), r + Vector2(3, -7), HAIR_D, 1.0)
		"sad":
			p.draw_line(l + Vector2(-4, -4), l + Vector2(3, -6), HAIR_D, 1.0)
			p.draw_line(r + Vector2(4, -4), r + Vector2(-3, -6), HAIR_D, 1.0)
		"smile":
			p.draw_line(l + Vector2(-3, -5.5), l + Vector2(3, -5.5), HAIR_D, 1.0)
			p.draw_line(r + Vector2(-3, -5.5), r + Vector2(3, -5.5), HAIR_D, 1.0)
		_:
			# 곧고 낮은 눈썹 (안쪽 끝이 조금 낮음 — 판정하는 얼굴)
			p.draw_line(l + Vector2(-4, -5.5), l + Vector2(3, -4.5), HAIR_D, 1.5)
			p.draw_line(r + Vector2(4, -5.5), r + Vector2(-3, -4.5), HAIR_D, 1.5)


static func _mouth(p: CanvasItem, fc: Vector2, expr: String, t: float, talking: bool, berserk: bool) -> void:
	var m := fc + Vector2(0, 10)
	var col := Color("#9a4a46")
	var open := talking and int(t * 12.0) % 2 == 0
	if berserk:
		p.draw_rect(Rect2(m.x - 2, m.y - 1, 4, 2 + (1 if open else 0)), Color("#5a2a30"))
		return
	match expr:
		"smile":
			if open:
				p.draw_rect(Rect2(m.x - 2, m.y - 1, 4, 2), Color("#7a3438"))
			else:
				p.draw_arc(m + Vector2(0, -2.5), 2.6, 0.35, PI - 0.35, 6, col, 1.0)
		"angry":
			p.draw_rect(Rect2(m.x - 2.5, m.y - 1, 5, 2 if open else 1), Color("#7a3438"))
		"surprised":
			p.draw_circle(m, 2.0 if not open else 2.6, Color("#7a3438"))
		"sad":
			p.draw_arc(m + Vector2(0, 2), 2.6, PI + 0.4, TAU - 0.4, 6, col, 1.0)
		_:
			if open:
				p.draw_rect(Rect2(m.x - 1.5, m.y - 1, 3, 2), Color("#7a3438"))
			else:
				p.draw_line(m + Vector2(-2.5, 0), m + Vector2(2.5, 0), col, 1.0)


static func _berserk_fire(p: CanvasItem, fc: Vector2, t: float) -> void:
	for i in 10:
		var x := 6.0 + i * 6.6
		var k := fmod(t * 1.6 + i * 0.31, 1.0)
		var base := Vector2(x, 72.0 - k * 10.0)
		var h := 8.0 + 5.0 * sin(t * 9.0 + i * 1.3)
		var a := 0.55 * (1.0 - k)
		p.draw_colored_polygon(PackedVector2Array([base + Vector2(-3, 0), base + Vector2(sin(t * 6.0 + i) * 2.0, -h), base + Vector2(3, 0)]), Color(1.0, 0.9, 0.55, a * 0.8))
		p.draw_colored_polygon(PackedVector2Array([base + Vector2(-1.5, 0), base + Vector2(sin(t * 6.0 + i), -h * 0.6), base + Vector2(1.5, 0)]), Color(WHITE_FIRE, a))
	for i in 6:
		var k := fmod(t * 0.7 + i * 0.17, 1.0)
		p.draw_rect(Rect2(fc.x - 20 + i * 8, fc.y + 20 - k * 50.0, 1, 1), Color(1, 1, 1, 1.0 - k))
