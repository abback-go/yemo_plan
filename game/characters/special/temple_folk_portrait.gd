extends RefCounted
## 루멘 대신전 사람들 초상화 (72×72) — 인물 정보의 "look"(temple_folk_draw.gd와 같음)으로 머리쓰개·얼굴을 고른다.
## 눈·입은 Portrait의 기본 표정 그림(_eyes·_mouth)을 그대로 쓴다 (normal·happy·angry·sad·surprised).

const OUTL := Color("#16101f")
const GOLD := Color("#e0b048")
const GOLD_L := Color("#fff0a8")


static func draw_portrait(p: Portrait, info: Dictionary, _expr: String, t: float, talking: bool, _blinking: bool) -> void:
	var look := String(info.get("look", "monk"))
	var robe: Color = info.get("robe", Color("#dcd8e6"))
	var robe2: Color = info.get("robe2", GOLD)
	var skin: Color = info.get("skin", Color("#f0d0c0"))
	var hair: Color = info.get("hair", Color("#4a3a30"))
	var eye: Color = info.get("eye", Color("#3a3040"))
	var b := sin(t * 2.0) * 0.6 + (sin(t * 18.0) * 0.5 if talking else 0.0)
	var fc := Vector2(36, 40 + b)
	if look == "gregor":
		fc += Vector2(2, 3)
	# 어깨·옷
	p.draw_colored_polygon(PackedVector2Array([Vector2(6, 72), Vector2(15, 57 + b), Vector2(57, 57 + b), Vector2(66, 72)]), OUTL)
	p.draw_colored_polygon(PackedVector2Array([Vector2(7, 72), Vector2(16, 58 + b), Vector2(56, 58 + b), Vector2(65, 72)]), robe)
	p.draw_colored_polygon(PackedVector2Array([Vector2(7, 72), Vector2(16, 58 + b), Vector2(26, 58 + b), Vector2(22, 72)]), robe.darkened(0.15))
	match look:
		"benedicta", "priest":
			p.draw_rect(Rect2(28, 58 + b, 5, 14), robe2)
			p.draw_rect(Rect2(39, 58 + b, 5, 14), robe2)
			p.draw_circle(Vector2(30.5, 66 + b), 1.5, GOLD_L)
			p.draw_circle(Vector2(41.5, 66 + b), 1.5, GOLD_L)
		"choir":
			p.draw_colored_polygon(PackedVector2Array([Vector2(22, 58 + b), Vector2(50, 58 + b), Vector2(44, 66 + b), Vector2(28, 66 + b)]), robe2)
		"pilgrim":
			p.draw_rect(Rect2(22, 56 + b, 28, 6), robe2)
			p.draw_rect(Rect2(40, 60 + b, 6, 10), robe2.darkened(0.1))
		"gregor":
			p.draw_arc(Vector2(18, 64 + b), 8, 0, TAU, 16, Color("#c8a870"), 3.0)
		"luca":
			p.draw_line(Vector2(16, 66 + b), Vector2(56, 66 + b), robe2, 3.0)
	# 뒤쪽 머리쓰개
	match look:
		"benedicta":
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-18, -10), fc + Vector2(18, -10), fc + Vector2(21, 20), fc + Vector2(-21, 20)]), robe.lerp(Color.WHITE, 0.35))
		"monk", "pilgrim":
			var hood := robe if look == "monk" else robe.lightened(0.06)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-19, 18), fc + Vector2(-18, -8), fc + Vector2(-8, -21), fc + Vector2(8, -21), fc + Vector2(18, -8), fc + Vector2(19, 18)]), OUTL)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-18, 18), fc + Vector2(-17, -8), fc + Vector2(-8, -20), fc + Vector2(8, -20), fc + Vector2(17, -8), fc + Vector2(18, 18)]), hood)
	p.draw_rect(Rect2(fc.x - 4, fc.y + 11, 8, 8), skin.darkened(0.1))
	# 얼굴
	var face := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		face.append(fc + Vector2(cos(a) * 13.0, sin(a) * (14.0 if sin(a) < 0 else 15.5)))
	p.draw_colored_polygon(face, skin)
	if look in ["benedicta", "gregor"]:
		# 주름
		p.draw_line(fc + Vector2(-11, 4), fc + Vector2(-8, 7), skin.darkened(0.15), 1.0)
		p.draw_line(fc + Vector2(11, 4), fc + Vector2(8, 7), skin.darkened(0.15), 1.0)
		p.draw_line(fc + Vector2(-4, -9), fc + Vector2(4, -9), skin.darkened(0.12), 1.0)
	if look == "luca":
		for q: Vector2 in [Vector2(-9, 6), Vector2(-7, 7), Vector2(7, 7), Vector2(9, 6)]:
			p.draw_rect(Rect2(fc + q, Vector2(1, 1)), Color(0.8, 0.45, 0.3, 0.7))
	p._eyes(fc, eye)
	p._mouth(fc)
	# 앞머리·머리쓰개
	match look:
		"benedicta":
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-13, -2), fc + Vector2(-12, -10), fc + Vector2(-4, -13), fc + Vector2(4, -13), fc + Vector2(12, -10), fc + Vector2(13, -2), fc + Vector2(8, -8), fc + Vector2(-8, -8)]), hair)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-13, -11), fc + Vector2(13, -11), fc + Vector2(10, -30), fc + Vector2(0, -36), fc + Vector2(-10, -30)]), OUTL)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-12, -12), fc + Vector2(12, -12), fc + Vector2(9, -29), fc + Vector2(0, -35), fc + Vector2(-9, -29)]), robe.lerp(Color.WHITE, 0.45))
			p.draw_line(fc + Vector2(-12, -12), fc + Vector2(12, -12), GOLD, 2.0)
			p.draw_circle(fc + Vector2(0, -22), 4.0, GOLD)
			p.draw_circle(fc + Vector2(0, -22), 2.0, GOLD_L)
			for i in 8:
				var a := TAU * i / 8.0 + t * 0.2
				p.draw_line(fc + Vector2(0, -22) + Vector2(cos(a), sin(a)) * 4.5, fc + Vector2(0, -22) + Vector2(cos(a), sin(a)) * 6.5, GOLD, 1.0)
		"monk":
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-15, 2), fc + Vector2(-14, -9), fc + Vector2(-7, -17), fc + Vector2(7, -17), fc + Vector2(14, -9), fc + Vector2(15, 2), fc + Vector2(11, -6), fc + Vector2(0, -9), fc + Vector2(-11, -6)]), robe)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-11, -6), fc + Vector2(0, -9), fc + Vector2(11, -6), fc + Vector2(11, -2), fc + Vector2(-11, -2)]), Color(robe.darkened(0.5), 0.55))
			p.draw_line(fc + Vector2(-7, -16), fc + Vector2(7, -16), robe2, 1.0)
		"pilgrim":
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-15, 2), fc + Vector2(-14, -9), fc + Vector2(-7, -17), fc + Vector2(7, -17), fc + Vector2(14, -9), fc + Vector2(15, 2), fc + Vector2(10, -7), fc + Vector2(-10, -7)]), robe.lightened(0.06))
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-10, -7), fc + Vector2(10, -7), fc + Vector2(8, -3), fc + Vector2(-8, -3)]), hair)
			p.draw_rect(Rect2(fc.x - 14, fc.y + 9, 28, 6), robe2)
		"gregor":
			p.draw_arc(fc + Vector2(0, -2), 12.0, PI * 1.15, PI * 1.85, 10, Color(1, 1, 1, 0.35), 2.0)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-14, -4), fc + Vector2(-12, 8), fc + Vector2(-16, 6)]), hair)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(14, -4), fc + Vector2(12, 8), fc + Vector2(16, 6)]), hair)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-10, 6), fc + Vector2(10, 6), fc + Vector2(9, 16), fc + Vector2(0, 22), fc + Vector2(-9, 16)]), hair)
			p.draw_line(fc + Vector2(-9, -4), fc + Vector2(-2, -3), hair, 3.0)
			p.draw_line(fc + Vector2(9, -4), fc + Vector2(2, -3), hair, 3.0)
			p.draw_rect(Rect2(fc.x - 3, fc.y + 9, 6, 2), Color("#8a3a3a"))
		"priest":
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-14, 0), fc + Vector2(-13, -10), fc + Vector2(-5, -15), fc + Vector2(6, -15), fc + Vector2(13, -10), fc + Vector2(14, 0), fc + Vector2(9, -7), fc + Vector2(0, -9), fc + Vector2(-9, -7)]), hair)
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-8, -14), fc + Vector2(8, -14), fc + Vector2(6, -19), fc + Vector2(-6, -19)]), robe2)
		"luca":
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-15, 4), fc + Vector2(-14, -9), fc + Vector2(-5, -17), fc + Vector2(6, -17), fc + Vector2(14, -9), fc + Vector2(15, 2), fc + Vector2(10, -4), fc + Vector2(6, -8), fc + Vector2(2, -3), fc + Vector2(-2, -8), fc + Vector2(-7, -3), fc + Vector2(-11, -7)]), hair)
			p.draw_line(fc + Vector2(-1, -17), fc + Vector2(2, -21), hair, 2.0)
		"choir":
			p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-16, 10), fc + Vector2(-15, -9), fc + Vector2(-6, -17), fc + Vector2(6, -17), fc + Vector2(15, -9), fc + Vector2(16, 10), fc + Vector2(12, 0), fc + Vector2(10, -7), fc + Vector2(-10, -7), fc + Vector2(-12, 0)]), hair)
