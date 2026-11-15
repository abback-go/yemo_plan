extends "res://characters/special/astrid_palette.gd"
## 아스트리드 교장 대화 초상화 (72×72). 1장 그림(긴 은회색 머리·별 장식 망토·마녀 모자·연보라 눈)과 같은 색을 지키되,
## 늙었지만 꼿꼿한 대마녀로: 가운데 가르마의 곧은 은회색 머리, 넓은 챙 모자, 눈가·입가의 잔주름, 은별 브로치.
## expr: normal(고요한 미소) · happy · sad · angry(엄함) · serious · surprised · tired(결계를 떠받치느라 지침) · wink("…라고 해 두죠")

const HAIR_SH := Color("#9090a8")
const HAIR_HI := Color("#ececf4")
const SKIN_SH := Color("#d6bab6")
const LINE := Color("#b89a98")
const EYE_DEEP := Color("#5a5aa8")
const SILVER := Color("#e0e2f4")


static func draw_portrait(p: Portrait, _info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	if expr == "serious":
		expr = "angry"
	var b := sin(t * 1.4) * 0.5 + (sin(t * 16.0) * 0.4 if talking else 0.0)
	var fc := Vector2(36, 41 + b)
	# 배경: 은은한 보랏빛 밤 + 별 몇 개
	for i in 12:
		p.draw_rect(Rect2(0, i * 6, 72, 6), Color("#0b0a1a").lerp(Color("#25204a"), float(i) / 11.0))
	for i in 10:
		var q := Vector2(fmod(i * 23.0, 70.0) + 1, fmod(i * 17.0, 50.0) + 2)
		p.draw_rect(Rect2(q, Vector2.ONE), Color(0.9, 0.9, 1.0, 0.2 + 0.4 * StArt.twinkle(t, i)))
	# 뒷머리 (어깨 아래로 곧게)
	for side: float in [-1.0, 1.0]:
		p.draw_colored_polygon(PackedVector2Array([
			fc + Vector2(side * 9, -14), fc + Vector2(side * 16, -8), fc + Vector2(side * 18, 10), fc + Vector2(side * 19, 34),
			fc + Vector2(side * 11, 34), fc + Vector2(side * 11, 0),
		]), HAIR_SH)
		p.draw_line(fc + Vector2(side * 15, -4), fc + Vector2(side * 17, 32), HAIR, 1.0)
	# 어깨·망토 (연보라 단, 은별 수)
	p.draw_colored_polygon(PackedVector2Array([Vector2(5, 72), Vector2(12, 58 + b), Vector2(26, 54 + b), Vector2(46, 54 + b), Vector2(60, 58 + b), Vector2(67, 72)]), CLOAK)
	p.draw_line(Vector2(12, 58 + b), Vector2(26, 54 + b), TRIM, 1.0)
	p.draw_line(Vector2(46, 54 + b), Vector2(60, 58 + b), TRIM, 1.0)
	p.draw_rect(Rect2(31, 51 + b, 10, 6), SKIN_SH)
	p.draw_colored_polygon(PackedVector2Array([Vector2(28, 55 + b), Vector2(36, 63 + b), Vector2(44, 55 + b)]), Color("#2c2a54"))
	p.draw_line(Vector2(28, 55 + b), Vector2(36, 63 + b), TRIM, 1.0)
	p.draw_line(Vector2(44, 55 + b), Vector2(36, 63 + b), TRIM, 1.0)
	p.draw_circle(Vector2(36, 63 + b), 3.5, Color(SILVER, 0.2))
	StArt.star(p, Vector2(36, 63 + b), 2.6, SILVER, -PI * 0.5)
	for i in 5:
		StArt.star(p, Vector2(10 + i * 3.5 + (i % 2) * 40.0, 64 + (i % 3) * 3.0 + b), 1.0, Color(SILVER, 0.5 + 0.4 * StArt.twinkle(t, i)), -PI * 0.5)
	# 얼굴 (조금 갸름하고 긴)
	var face := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var px := cos(a) * 12.0
		if sin(a) > 0.4:
			px *= 0.84
		face.append(fc + Vector2(px, sin(a) * (13.5 if sin(a) < 0 else 15.0)))
	p.draw_colored_polygon(face, SKIN)
	p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-12, -2), fc + Vector2(-9.5, -8), fc + Vector2(-8.5, 9), fc + Vector2(-10, 6)]), SKIN_SH)
	_eyes(p, fc, expr, t, blinking)
	# 세월의 선: 눈가 잔주름, 팔자 주름 한 쌍
	p.draw_line(fc + Vector2(-11, 2), fc + Vector2(-10, 4), LINE, 1.0)
	p.draw_line(fc + Vector2(11, 2), fc + Vector2(10, 4), LINE, 1.0)
	p.draw_line(fc + Vector2(-7.5, 6), fc + Vector2(-4.5, 6.5), Color(LINE, 0.45), 1.0)
	p.draw_line(fc + Vector2(7.5, 6), fc + Vector2(4.5, 6.5), Color(LINE, 0.45), 1.0)
	_mouth(p, fc, expr, t, talking)
	if expr == "tired":
		p.draw_colored_polygon(PackedVector2Array([fc + Vector2(12, -6), fc + Vector2(14, -2), fc + Vector2(12, -1), fc + Vector2(10.5, -2.5)]), Color(0.7, 0.85, 1.0, 0.8))
	# 앞머리 (가운데 가르마, 양옆으로 단정하게)
	var bangs := PackedVector2Array([
		fc + Vector2(-12, 2), fc + Vector2(-12, -8), fc + Vector2(-6, -14), fc + Vector2(0, -15), fc + Vector2(6, -14),
		fc + Vector2(12, -8), fc + Vector2(12, 2), fc + Vector2(9, -6), fc + Vector2(3, -11), fc + Vector2(0, -12),
		fc + Vector2(-3, -11), fc + Vector2(-9, -6),
	])
	p.draw_colored_polygon(bangs, HAIR)
	p.draw_line(fc + Vector2(0, -15), fc + Vector2(0, -12), HAIR_SH, 1.0)
	p.draw_line(fc + Vector2(-8, -11), fc + Vector2(-2, -14), HAIR_HI, 1.0)
	for side: float in [-1.0, 1.0]:
		p.draw_colored_polygon(PackedVector2Array([fc + Vector2(side * 11, -6), fc + Vector2(side * 13.5, 0), fc + Vector2(side * 13, 18), fc + Vector2(side * 10.5, 18), fc + Vector2(side * 10.5, 0)]), HAIR)
	# 모자 (넓은 챙, 연보라 띠, 은별 핀)
	var bc := fc + Vector2(0, -14)
	var brim := PackedVector2Array()
	for i in 22:
		var a := TAU * i / 22.0
		brim.append(bc + Vector2(cos(a) * 32.0, sin(a) * (4.5 if sin(a) > 0 else 3.0)))
	p.draw_colored_polygon(brim, HAT)
	p.draw_line(bc + Vector2(-31, 0), bc + Vector2(31, 0), Color("#2c2c50"), 1.0)
	var bend := sin(t * 1.1) * 0.8
	p.draw_colored_polygon(PackedVector2Array([bc + Vector2(-12, -1), bc + Vector2(12, -1), bc + Vector2(5, -18), bc + Vector2(-1 + bend, -30),
		bc + Vector2(-9 + bend, -33), bc + Vector2(-4 + bend * 0.5, -26), bc + Vector2(-6, -16)]), HAT)
	p.draw_line(bc + Vector2(-11, -3), bc + Vector2(11, -3), TRIM, 3.0)
	StArt.star(p, bc + Vector2(6, -3), 2.6, SILVER, -PI * 0.5)
	# 모자 둘레의 작은 별 넷 (1장 그림과 같은 표식)
	for i in 4:
		var a2 := t * 0.6 + TAU * i / 4.0
		p.draw_rect(Rect2(fc + Vector2(cos(a2) * 28, -24 + sin(a2) * 6), Vector2(2, 2)), Color(0.9, 0.9, 1.0, 0.8))


static func _eyes(p: Portrait, fc: Vector2, expr: String, t: float, blinking: bool) -> void:
	var l := fc + Vector2(-5.5, 2)
	var r := fc + Vector2(5.5, 2)
	var brow := HAIR_SH.darkened(0.1)
	match expr:
		"angry":
			p.draw_line(l + Vector2(-3, -7), l + Vector2(3, -5), brow, 1.5)
			p.draw_line(r + Vector2(3, -7), r + Vector2(-3, -5), brow, 1.5)
		"sad", "tired":
			p.draw_line(l + Vector2(-3, -5), l + Vector2(3, -7), brow, 1.0)
			p.draw_line(r + Vector2(3, -5), r + Vector2(-3, -7), brow, 1.0)
		"surprised":
			p.draw_line(l + Vector2(-3, -9), l + Vector2(3, -9), brow, 1.0)
			p.draw_line(r + Vector2(-3, -9), r + Vector2(3, -9), brow, 1.0)
		_:
			p.draw_line(l + Vector2(-3, -7), l + Vector2(3, -6.5), brow, 1.0)
			p.draw_line(r + Vector2(-3, -6.5), r + Vector2(3, -7), brow, 1.0)
	var closed := blinking and expr != "surprised"
	for e in [l, r]:
		var ev: Vector2 = e
		var wink := expr == "wink" and ev.x > fc.x
		if expr == "happy" or closed or wink:
			if expr == "happy" or wink:
				p.draw_arc(ev + Vector2(0, 2), 3.0, PI + 0.3, TAU - 0.3, 8, LASH, 1.5)
			else:
				p.draw_line(ev + Vector2(-3, 1), ev + Vector2(3, 1), LASH, 1.0)
			continue
		# 차분히 내리깐 눈 (위 눈꺼풀이 반쯤)
		var top := -1.5
		match expr:
			"surprised": top = -4.0
			"angry": top = -1.0
			"tired": top = 0.0
			"sad": top = -0.5
		var bot := 3.5
		p.draw_rect(Rect2(ev.x - 3, ev.y + top, 6, bot - top), Color("#f8f4fa"))
		p.draw_rect(Rect2(ev.x - 2, ev.y + top, 4, bot - top), EYE)
		p.draw_rect(Rect2(ev.x - 2, ev.y + top, 4, 1), EYE_DEEP)
		p.draw_rect(Rect2(ev.x - 1, ev.y + top + 1, 1, 1), Color(1, 1, 1, 0.9))
		p.draw_line(Vector2(ev.x - 3.5, ev.y + top - 0.5), Vector2(ev.x + 3.5, ev.y + top - 0.5), LASH, 1.5)


static func _mouth(p: Portrait, fc: Vector2, expr: String, t: float, talking: bool) -> void:
	var m := fc + Vector2(0, 10)
	var col := Color("#9a5a5a")
	if talking and int(t * 11.0) % 2 == 0:
		p.draw_rect(Rect2(m.x - 1.5, m.y - 0.5, 3, 2), Color("#8a4a4a"))
		return
	match expr:
		"happy", "wink":
			p.draw_arc(m + Vector2(0, -2), 2.5, 0.3, PI - 0.3, 6, col, 1.2)
		"sad", "tired":
			p.draw_arc(m + Vector2(0, 2), 2.0, PI + 0.4, TAU - 0.4, 6, col, 1.0)
		"angry":
			p.draw_line(m + Vector2(-2.5, 0), m + Vector2(2.5, 0), col, 1.0)
		"surprised":
			p.draw_circle(m, 1.6, Color("#8a4a4a"))
		_:
			# 고요한 미소 (한쪽 입꼬리만 살짝)
			p.draw_line(m + Vector2(-2, 0), m + Vector2(1, 0), col, 1.0)
			p.draw_line(m + Vector2(1, 0), m + Vector2(2.5, -1), col, 1.0)
