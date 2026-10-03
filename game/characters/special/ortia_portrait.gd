extends RefCounted
## 오르티아 장로 초상화 (72×72) — 주름진 얼굴, 처진 긴 귀, 이끼·작은 꽃을 엮은 긴 흰 머리, 이끼 망토,
## 옆으로 솟은 지팡이 끝의 빛나는 씨앗. 평소엔 웃는 듯 감은 눈, 놀라거나 진지할 땐 옅은 금록 눈을 뜬다.
## expr: normal · happy · sad · surprised · angry(엄함) · serious(진지 — 눈을 뜸)

const HAIR := Color("#e6e6da")
const HAIR_SH := Color("#b2b4a4")
const SKIN := Color("#e8ccb6")
const SKIN_SH := Color("#c49e88")
const LINE := Color("#5a3e2e")
const MANTLE := Color("#4a6a36")
const MANTLE_SH := Color("#2e4622")
const ROBE := Color("#5a4430")
const MOSS := Color("#6a9a44")
const SAP := Color("#c8ff7a")
const STAFF := Color("#6a5034")
const EYE := Color("#b8c878")


static func draw_portrait(p: Portrait, _info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	var b := sin(t * 1.6) * 0.5 + (sin(t * 12.0) * 0.4 if talking else 0.0)
	var fc := Vector2(36, 38 + b)
	# 지팡이 끝 (화면 오른쪽)
	p.draw_line(Vector2(62, 72), Vector2(60, 14), STAFF, 3.0)
	p.draw_arc(Vector2(56, 14), 4.0, -0.2, PI * 1.3, 10, STAFF, 2.0)
	var k := 0.7 + 0.3 * sin(t * 1.3)
	p.draw_circle(Vector2(56, 19), 9.0, Color(SAP, 0.1 * k))
	p.draw_circle(Vector2(56, 19), 2.5, Color(0.92, 1.0, 0.75, k))
	for a in [-2.0, -1.0, -0.2]:
		var ang: float = a
		var d := Vector2(cos(ang), sin(ang))
		var c := Vector2(60, 12)
		p.draw_colored_polygon(PackedVector2Array([c, c + d * 4.0 + Vector2(-d.y, d.x) * 2.0, c + d * 8.0, c + d * 4.0 - Vector2(-d.y, d.x) * 2.0]), MOSS)
	# 뒤로 길게 흘러내린 흰 머리 (물결치는 가닥)
	var back := PackedVector2Array([fc + Vector2(-16, -12), fc + Vector2(16, -12)])
	for i in 7:
		var k2 := float(i) / 6.0
		back.append(fc + Vector2(18 + sin(t * 1.1 + k2 * 3.0) * 1.5 + k2 * 3.0, -8 + k2 * 42))
	for i in 7:
		var k3 := 1.0 - float(i) / 6.0
		back.append(fc + Vector2(-18 - sin(t * 1.1 + k3 * 3.0 + 1.0) * 1.5 - k3 * 3.0, -8 + k3 * 42))
	p.draw_colored_polygon(back, HAIR_SH)
	for i in 5:
		var sx := -16.0 + i * 8.0
		p.draw_line(fc + Vector2(sx, 14), fc + Vector2(sx * 1.15 + sin(t + i) * 1.0, 34), HAIR.darkened(0.08), 1.0)
	# 망토와 로브
	p.draw_colored_polygon(PackedVector2Array([Vector2(6, 72), Vector2(14, 56 + b), Vector2(58, 56 + b), Vector2(66, 72)]), MANTLE)
	p.draw_colored_polygon(PackedVector2Array([Vector2(26, 56 + b), Vector2(36, 64 + b), Vector2(46, 56 + b), Vector2(44, 72), Vector2(28, 72)]), ROBE)
	p.draw_line(Vector2(14, 57 + b), Vector2(58, 57 + b), MANTLE_SH, 1.0)
	for i in 6:
		p.draw_rect(Rect2(12 + i * 9, 58 + b + (i % 2) * 2, 3, 2), MOSS)
	# 씨앗 목걸이
	p.draw_circle(Vector2(36, 66 + b), 2.5, Color(SAP, 0.9 * k))
	p.draw_circle(Vector2(36, 66 + b), 6.0, Color(SAP, 0.1 * k))
	# 처진 긴 귀
	for side in [-1.0, 1.0]:
		var base := fc + Vector2(side * 11.0, 2)
		var tip := fc + Vector2(side * 25.0, -4.0 + sin(t * 0.6 + side) * 0.4)
		p.draw_colored_polygon(PackedVector2Array([base + Vector2(0, -4), tip, base + Vector2(0, 5)]), SKIN)
		p.draw_line(base + Vector2(side * 1.5, 1), tip + Vector2(-side * 3.0, 1.5), SKIN_SH, 1.0)
	# 얼굴
	var face := PackedVector2Array()
	for i in 18:
		var a2 := TAU * i / 18.0
		face.append(fc + Vector2(cos(a2) * 12.0, sin(a2) * (14.0 if sin(a2) > 0 else 13.0)))
	p.draw_colored_polygon(face, SKIN)
	# 주름
	p.draw_line(fc + Vector2(-9, 6), fc + Vector2(-6, 9), SKIN_SH, 1.0)
	p.draw_line(fc + Vector2(9, 6), fc + Vector2(6, 9), SKIN_SH, 1.0)
	p.draw_line(fc + Vector2(-5, -6), fc + Vector2(5, -6), SKIN_SH, 1.0)
	p.draw_line(fc + Vector2(-11, 1), fc + Vector2(-9, 2), SKIN_SH, 1.0)
	p.draw_line(fc + Vector2(11, 1), fc + Vector2(9, 2), SKIN_SH, 1.0)
	# 눈
	var open := expr in ["surprised", "serious", "angry"] and not blinking
	for sx in [-5.5, 5.5]:
		var e := fc + Vector2(sx, 1)
		if open:
			p.draw_rect(Rect2(e.x - 2, e.y - 1, 4, 3), EYE)
			p.draw_rect(Rect2(e.x - 1, e.y - 1, 1, 1), Color.WHITE)
			p.draw_line(e + Vector2(-3, -2), e + Vector2(3, -2), LINE, 1.0)
		elif expr == "sad":
			p.draw_arc(e + Vector2(0, -1), 2.5, 0.3, PI - 0.3, 5, LINE, 1.0)
		else:
			# 웃는 듯 감은 눈
			p.draw_arc(e + Vector2(0, 1.5), 2.8, PI + 0.3, TAU - 0.3, 6, LINE, 1.0)
		p.draw_line(e + Vector2(-3, -4), e + Vector2(3, -4 - (1 if expr == "angry" and sx > 0 else 0)), HAIR_SH, 2.0)
	# 입
	var m := fc + Vector2(0, 9)
	if talking and int(t * 9.0) % 2 == 0:
		p.draw_rect(Rect2(m.x - 1.5, m.y - 0.5, 3, 2), Color("#8a4a3e"))
	elif expr in ["happy", "normal"]:
		p.draw_arc(m + Vector2(0, -2), 3.0, 0.4, PI - 0.4, 6, Color("#8a4a3e"), 1.0)
	else:
		p.draw_line(m + Vector2(-2, 0), m + Vector2(2, 0), Color("#8a4a3e"), 1.0)
	# 앞머리 (가르마로 넘긴 흰 머리) + 이끼 + 꽃
	p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-14, 4), fc + Vector2(-13, -9), fc + Vector2(-4, -15), fc + Vector2(6, -15), fc + Vector2(14, -8), fc + Vector2(14, 4),
		fc + Vector2(10, -7), fc + Vector2(2, -10), fc + Vector2(-6, -8), fc + Vector2(-11, -2)]), HAIR)
	p.draw_line(fc + Vector2(-10, -11), fc + Vector2(2, -14), Color.WHITE, 1.0)
	for q in [Vector2(-12, -6), Vector2(11, -4), Vector2(-8, -12)]:
		var mp: Vector2 = fc + q
		p.draw_rect(Rect2(mp, Vector2(3, 2)), MOSS)
	var fl := fc + Vector2(-12, -10)
	for i in 5:
		var a3 := TAU * i / 5.0
		p.draw_circle(fl + Vector2(cos(a3), sin(a3)) * 2.5, 1.8, Color("#f0d8f0"))
	p.draw_circle(fl, 1.3, Color("#ffe08a"))
	# 늘어진 옆머리
	p.draw_line(fc + Vector2(-14, 0), fc + Vector2(-16, 26), HAIR, 3.0)
	p.draw_line(fc + Vector2(14, 0), fc + Vector2(16, 24), HAIR, 3.0)
