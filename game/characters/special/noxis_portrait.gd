extends RefCounted
## 녹시스 대화 초상화 (72×72): 별자리 두건, 흘러내린 은빛 머리, 눈가를 덮는 하얀 별 가면(보랏빛 눈), 얇은 입술.
## 표정: normal(얇은 미소) · happy(광신의 웃음) · angry(이를 드러냄, 눈빛이 붉은 보라로) · surprised · sad · zeal(황홀 — 눈이 타오르고 별이 돈다)

const KArt := preload("res://world/entities/ch2/k_art.gd")
const ROBE := Color("#2a2050")
const ROBE_L := Color("#45387a")
const ROBE_D := Color("#140e2a")
const TRIM := Color("#c8a8ff")
const HAIR := Color("#dcd4ec")
const HAIR_D := Color("#a89cc4")
const SKIN := Color("#c4b2c4")
const SKIN_D := Color("#9a88a4")
const MASK := Color("#f4f0fa")
const MASK_D := Color("#b0a8c8")
const STAR := Color("#c89aff")
const LIP := Color("#7a3a5a")


static func draw_portrait(p: Portrait, _info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	var b := sin(t * 1.6) * 0.8 + (sin(t * 16.0) * 0.4 if talking else 0.0)
	var fc := Vector2(36, 38 + b)
	var zeal := expr == "zeal"
	# 뒤의 별빛 소용돌이
	for i in 4:
		p.draw_circle(Vector2(36, 40), 36.0 - i * 7.0, Color(STAR, 0.05 + (0.03 if zeal else 0.0)))
	KArt.twinkles(p, Rect2(2, 2, 68, 40), 10, t, Color(1, 0.95, 1.0, 0.7), 5)
	# 어깨·로브 (별자리 수)
	KArt.poly(p, PackedVector2Array([Vector2(2, 72), Vector2(10, 54 + b), Vector2(26, 50 + b), Vector2(46, 50 + b), Vector2(62, 54 + b), Vector2(70, 72)]), ROBE)
	KArt.poly(p, PackedVector2Array([Vector2(2, 72), Vector2(10, 54 + b), Vector2(26, 50 + b), Vector2(28, 72)]), ROBE_D)
	var cons := [Vector2(48, 60), Vector2(54, 64), Vector2(58, 59), Vector2(64, 66), Vector2(52, 69)]
	for i in cons.size() - 1:
		p.draw_line((cons[i] as Vector2) + Vector2(0, b), (cons[i + 1] as Vector2) + Vector2(0, b), Color(TRIM, 0.4), 1.0)
	for i in cons.size():
		var tw := 0.5 + 0.5 * sin(t * 3.0 + i)
		p.draw_rect(Rect2((cons[i] as Vector2) + Vector2(-0.5, b - 0.5), Vector2(1.5, 1.5)), Color(1, 0.95, 1.0, 0.5 + 0.5 * tw))
	p.draw_line(Vector2(26, 50 + b), Vector2(36, 72), TRIM, 1.0)
	p.draw_line(Vector2(46, 50 + b), Vector2(36, 72), TRIM, 1.0)
	# 별 수정 목걸이
	var pend := Vector2(36, 64 + b)
	KArt.glow(p, pend, 8.0, Color(STAR, 0.8), 3)
	KArt.star5(p, pend, 3.5, STAR.lightened(0.3), t * 0.5)
	# 두건 (뒤)
	KArt.poly(p, PackedVector2Array([fc + Vector2(-20, 18), fc + Vector2(-21, -6), fc + Vector2(-12, -22), fc + Vector2(4, -25), fc + Vector2(17, -17), fc + Vector2(21, -2), fc + Vector2(20, 18)]), ROBE_L)
	KArt.poly(p, PackedVector2Array([fc + Vector2(-20, 18), fc + Vector2(-21, -6), fc + Vector2(-12, -22), fc + Vector2(-8, -12), fc + Vector2(-12, 16)]), ROBE)
	# 얼굴
	var face := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		face.append(fc + Vector2(cos(a) * 11.0, sin(a) * (12.5 if sin(a) < 0 else 14.0)))
	KArt.poly(p, face, SKIN)
	KArt.poly(p, PackedVector2Array([fc + Vector2(-11, 0), fc + Vector2(-8, 10), fc + Vector2(-4, 13), fc + Vector2(-8, 4)]), SKIN_D)
	# 흘러내린 은빛 머리 (가르마 + 양옆으로 길게)
	KArt.poly(p, PackedVector2Array([fc + Vector2(-12, -10), fc + Vector2(-2, -15), fc + Vector2(-4, -6), fc + Vector2(-13, 4), fc + Vector2(-15, 18), fc + Vector2(-17, 6)]), HAIR)
	KArt.poly(p, PackedVector2Array([fc + Vector2(12, -10), fc + Vector2(2, -15), fc + Vector2(4, -6), fc + Vector2(13, 4), fc + Vector2(15, 18), fc + Vector2(17, 6)]), HAIR)
	p.draw_line(fc + Vector2(-13, 0), fc + Vector2(-15, 14), HAIR_D, 1.0)
	p.draw_line(fc + Vector2(13, 0), fc + Vector2(15, 14), HAIR_D, 1.0)
	# 별 가면: 눈가를 덮는 흰 판 + 네 갈래 별 문양
	var mc := fc + Vector2(0, -1)
	KArt.poly(p, PackedVector2Array([mc + Vector2(-13, -1), mc + Vector2(-9, -7), mc + Vector2(0, -12), mc + Vector2(9, -7), mc + Vector2(13, -1), mc + Vector2(8, 5), mc + Vector2(0, 7), mc + Vector2(-8, 5)]), MASK)
	KArt.star4(p, mc + Vector2(0, -2), 11.0, MASK_D)
	KArt.star4(p, mc + Vector2(0, -2), 8.0, MASK)
	p.draw_line(mc + Vector2(-13, -1), mc + Vector2(-8, 5), MASK_D, 1.0)
	p.draw_polyline(PackedVector2Array([mc + Vector2(-13, -1), mc + Vector2(-9, -7), mc + Vector2(0, -12), mc + Vector2(9, -7), mc + Vector2(13, -1)]), Color("#d8b860"), 1.0)
	# 눈구멍의 빛
	var eye_col := STAR.lightened(0.3)
	var glow := 0.7 + 0.3 * sin(t * 3.0)
	match expr:
		"angry":
			eye_col = Color("#ff6ab0")
			glow = 1.0
		"zeal", "happy":
			glow = 1.0
		"sad":
			glow = 0.45
	for sx in [-5.5, 5.5]:
		var e: Vector2 = mc + Vector2(sx, 0)
		p.draw_rect(Rect2(e.x - 3, e.y - 1.5, 6, 3), Color("#1a1028"))
		if blinking and not zeal:
			p.draw_line(e + Vector2(-2, 0), e + Vector2(2, 0), Color(eye_col, 0.5), 1.0)
		else:
			var h := 2.0 if expr != "surprised" else 3.0
			p.draw_rect(Rect2(e.x - 1.5, e.y - h * 0.5, 3, h), Color(eye_col, glow))
			p.draw_circle(e, 3.5 + (2.5 if zeal else 0.0), Color(eye_col, 0.18 * glow))
	# 입
	var m := fc + Vector2(0, 10)
	var open := talking and int(t * 11.0) % 2 == 0
	match expr:
		"happy", "zeal":
			p.draw_arc(m + Vector2(0, -3), 5.0, 0.35, PI - 0.35, 8, LIP, 1.5)
			KArt.poly(p, PackedVector2Array([m + Vector2(-4, -0.6), m + Vector2(4, -0.6), m + Vector2(0, 2.2)]), Color("#2a1020"))
			p.draw_line(m + Vector2(-3.5, -0.6), m + Vector2(3.5, -0.6), Color("#f0e8f0"), 1.0)
		"angry":
			p.draw_rect(Rect2(m.x - 4, m.y - 1, 8, 3), Color("#2a1020"))
			p.draw_line(m + Vector2(-4, -1), m + Vector2(4, -1), Color("#f0e8f0"), 1.0)
			p.draw_line(m + Vector2(-4, 2), m + Vector2(4, 2), Color("#f0e8f0"), 1.0)
		"surprised":
			p.draw_circle(m, 2.2, Color("#2a1020"))
		"sad":
			p.draw_line(m + Vector2(-3, 0.5), m + Vector2(3, 0.5), LIP, 1.0)
		_:
			# 얇은 미소 (한쪽 입꼬리)
			if open:
				p.draw_rect(Rect2(m.x - 2.5, m.y - 1, 5, 2), Color("#2a1020"))
			p.draw_line(m + Vector2(-3, 0), m + Vector2(2, 0), LIP, 1.0)
			p.draw_line(m + Vector2(2, 0), m + Vector2(4, -1.5), LIP, 1.0)
	if zeal:
		for i in 5:
			var ang := t * 1.5 + TAU * i / 5.0
			KArt.star4(p, fc + Vector2(cos(ang) * 26.0, sin(ang) * 9.0 - 14.0), 2.0, Color(STAR.lightened(0.4), 0.9))
