extends "res://characters/special/leonie_palette.gd"
## 레오니 대화 초상화 (72×72). Portrait가 draw_portrait를 부른다.
## 짙은 남색 단발(옆 가르마, 끝이 뾰족하게 갈라짐) + 화면 왼쪽 귀 뒤로 땋아 내린 가는 머리(붉은 끈),
## 날카로운 금빛 눈, 콧등을 가로지르는 흉터, 은빛 어깨갑·흉갑·목가리개, 진홍 망토 깃과 은사자 여밈.
## 표정: normal(담담) · stern(엄격 — 눈썹이 내려앉고 입을 다묾) · happy(드문 작은 미소) · angry · sad · surprised

const HAIR_L := Color("#405090")
const HAIR_D := Color("#0c1020")
const SKIN_D := Color("#d6aa96")
const SKIN_L := Color("#fde8da")
const EYE := Color("#f0b02a")
const EYE_L := Color("#ffe07a")
const EYE_D := Color("#9a5a10")
const SCAR := Color("#d98a84")
const BROW := Color("#141a30")
const LID := Color("#2a1e28")
const MOUTH := Color("#9a4a46")


static func draw_portrait(p: Portrait, _info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	var b := sin(t * 2.0) * 0.6 + (sin(t * 18.0) * 0.4 if talking else 0.0)
	var fc := Vector2(36, 35 + b)
	for i in 4:
		p.draw_circle(Vector2(36, 50), 36.0 - i * 6.0, Color(CAPE, 0.05))
	_body(p, b, t)
	_back_hair(p, fc, t)
	_braid(p, fc, t)
	p.draw_rect(Rect2(fc.x - 5, fc.y + 11, 10, 9), SKIN_D) # 목
	p.draw_rect(Rect2(fc.x - 5, fc.y + 11, 10, 3), SKIN_D.darkened(0.15))
	_face(p, fc)
	_eyes(p, fc, expr, blinking, t)
	_scar(p, fc)
	_mouth(p, fc, expr, talking, t)
	if expr == "happy":
		p.draw_rect(Rect2(fc.x - 11, fc.y + 6, 4, 1), Color(1.0, 0.5, 0.5, 0.35))
		p.draw_rect(Rect2(fc.x + 7, fc.y + 6, 4, 1), Color(1.0, 0.5, 0.5, 0.35))
	_front_hair(p, fc, t)


static func _body(p: Portrait, b: float, t: float) -> void:
	var y := 57.0 + b
	# 망토 (어깨 뒤로 넓게) + 세운 깃
	KArt.poly(p, PackedVector2Array([Vector2(-2, 72), Vector2(2, y), Vector2(18, y - 7), Vector2(54, y - 7), Vector2(70, y), Vector2(74, 72)]), CAPE_D)
	# 흉갑 + 목가리개
	KArt.poly(p, PackedVector2Array([Vector2(19, 72), Vector2(21, y + 1), Vector2(36, y - 2), Vector2(51, y + 1), Vector2(53, 72)]), ARMOR)
	KArt.poly(p, PackedVector2Array([Vector2(19, 72), Vector2(21, y + 1), Vector2(31, y - 1), Vector2(29, 72)]), ARMOR_D)
	p.draw_line(Vector2(36, y - 1), Vector2(36, 72), ARMOR.darkened(0.15), 1.0)
	p.draw_line(Vector2(43, y + 1), Vector2(45, 72), ARMOR_L, 1.0)
	var g := fmod(t, 4.5)
	if g < 0.4:
		p.draw_rect(Rect2(44, lerpf(y + 3, 70, g / 0.4), 2, 2), Color.WHITE)
	p.draw_rect(Rect2(29, y - 4, 14, 4), ARMOR_D) # 목가리개
	p.draw_line(Vector2(29, y - 4), Vector2(43, y - 4), ARMOR, 1.0)
	# 어깨갑: 둥근 큰 판 + 아래로 겹친 판 둘
	for side in [-1.0, 1.0]:
		var cx: float = 36.0 + side * 23.0
		var lit: bool = side > 0.0
		var base := ARMOR if lit else ARMOR_D.lightened(0.12)
		for k in 2:
			var ky := y + 4.0 + k * 4.0
			var lame := PackedVector2Array([Vector2(cx - 10, ky + 4), Vector2(cx - 9, ky), Vector2(cx + 9, ky), Vector2(cx + 10, ky + 4)])
			KArt.poly(p, lame, OUT)
			KArt.poly(p, PackedVector2Array([Vector2(cx - 9, ky + 3), Vector2(cx - 8.5, ky + 0.8), Vector2(cx + 8.5, ky + 0.8), Vector2(cx + 9, ky + 3)]), base.darkened(0.12 * (k + 1)))
		var dome := PackedVector2Array()
		for i in 11:
			var a := PI + PI * i / 10.0
			dome.append(Vector2(cx + cos(a) * 11.0, y + 4 + sin(a) * 7.5))
		KArt.poly(p, dome, OUT)
		var dome2 := PackedVector2Array()
		for i in 11:
			var a2 := PI + PI * i / 10.0
			dome2.append(Vector2(cx + cos(a2) * 10.0, y + 3.5 + sin(a2) * 6.5))
		KArt.poly(p, dome2, base)
		p.draw_arc(Vector2(cx + side * 1.0, y + 3.5), 7.0, PI + 0.5, PI + 1.6 if not lit else TAU - 0.6, 6, ARMOR_L if lit else ARMOR, 1.0)
		p.draw_rect(Rect2(cx - 1, y - 1, 2, 2), ARMOR_L if lit else ARMOR) # 리벳
	# 세운 진홍 깃
	KArt.poly(p, PackedVector2Array([Vector2(23, y + 1), Vector2(24, y - 10), Vector2(30, y - 5), Vector2(31, y + 2)]), CAPE)
	KArt.poly(p, PackedVector2Array([Vector2(49, y + 1), Vector2(48, y - 10), Vector2(42, y - 5), Vector2(41, y + 2)]), CAPE)
	p.draw_line(Vector2(24, y - 10), Vector2(30, y - 5), CAPE_L, 1.0)
	p.draw_line(Vector2(48, y - 10), Vector2(42, y - 5), CAPE_L, 1.0)
	# 은사자 여밈
	KArt.lion_crest(p, Vector2(36, y + 7), 4.5, ARMOR_L, CAPE_D)


static func _back_hair(p: Portrait, fc: Vector2, t: float) -> void:
	var sw := sin(t * 1.6) * 0.8
	KArt.poly(p, PackedVector2Array([
		fc + Vector2(-18, -4), fc + Vector2(-15, -17), fc + Vector2(-4, -23), fc + Vector2(8, -22), fc + Vector2(16, -15), fc + Vector2(18, -4),
		fc + Vector2(18 + sw * 0.5, 9), fc + Vector2(15, 16), fc + Vector2(11, 11), fc + Vector2(-11, 11), fc + Vector2(-15, 16), fc + Vector2(-18 + sw * 0.5, 9),
	]), HAIR_D)


static func _face(p: Portrait, fc: Vector2) -> void:
	var face := PackedVector2Array()
	for i in 22:
		var a := TAU * i / 22.0
		var rx := 13.0
		var ry := 14.0 if sin(a) < 0 else 16.0
		var pt := fc + Vector2(cos(a) * rx, sin(a) * ry)
		if sin(a) > 0.55:
			pt.x = fc.x + cos(a) * rx * 0.8 # 단단한 턱선
		face.append(pt)
	KArt.poly(p, face, SKIN)
	# 볼 그늘(화면 왼쪽) + 콧날 + 이마 빛
	KArt.poly(p, PackedVector2Array([fc + Vector2(-13, -1), fc + Vector2(-11, 9), fc + Vector2(-6, 14), fc + Vector2(-9, 6)]), SKIN_D)
	p.draw_line(fc + Vector2(1, 2), fc + Vector2(2, 7), SKIN_D, 1.0)
	p.draw_rect(Rect2(fc.x + 1, fc.y + 7, 3, 1), SKIN_D)
	p.draw_rect(Rect2(fc.x + 6, fc.y - 7, 4, 2), SKIN_L)


static func _eyes(p: Portrait, fc: Vector2, expr: String, blinking: bool, t: float) -> void:
	var l := fc + Vector2(-6, 1)
	var r := fc + Vector2(6, 1)
	if blinking and expr != "surprised":
		for e in [l, r]:
			p.draw_line(e + Vector2(-3, 1), e + Vector2(3, 1), LID, 1.0)
		_brows(p, l, r, expr)
		return
	for e in [l, r]:
		var ev: Vector2 = e
		match expr:
			"happy":
				# 눈매가 살짝 풀린다 (아래 눈꺼풀이 올라감)
				p.draw_rect(Rect2(ev.x - 3, ev.y - 1, 6, 3), EYE)
				p.draw_rect(Rect2(ev.x - 0.5, ev.y - 1, 2, 2), EYE_D)
				p.draw_rect(Rect2(ev.x - 3, ev.y - 2, 6, 1), LID)
				p.draw_line(ev + Vector2(-3, 2), ev + Vector2(3, 2), SKIN_D, 1.0)
			"surprised":
				p.draw_rect(Rect2(ev.x - 3, ev.y - 3, 6, 6), Color("#fff8ee"))
				p.draw_rect(Rect2(ev.x - 1.5, ev.y - 2, 3, 4), EYE)
				p.draw_rect(Rect2(ev.x - 0.5, ev.y - 1, 1, 2), EYE_D)
				p.draw_rect(Rect2(ev.x - 3, ev.y - 3.5, 6, 1), LID)
			"sad":
				p.draw_rect(Rect2(ev.x - 3, ev.y, 6, 3), EYE.darkened(0.15))
				p.draw_rect(Rect2(ev.x - 0.5, ev.y + 0.5, 2, 2), EYE_D)
				p.draw_rect(Rect2(ev.x - 3, ev.y - 0.5, 6, 1), LID)
			"angry":
				p.draw_rect(Rect2(ev.x - 3, ev.y - 1, 6, 3), EYE)
				p.draw_rect(Rect2(ev.x - 0.5, ev.y - 1, 1.5, 2), Color("#3a1a08"))
				p.draw_rect(Rect2(ev.x - 3, ev.y - 2, 6, 1), LID)
				p.draw_circle(ev, 4.5, Color(EYE, 0.10 + 0.06 * sin(t * 6.0)))
			_:
				# normal · stern: 아몬드꼴 날카로운 눈, 위 눈꺼풀을 굵게
				var narrow := 1.0 if expr == "stern" else 0.0
				p.draw_colored_polygon(PackedVector2Array([ev + Vector2(-3.5, 0.5), ev + Vector2(-1.5, -2 + narrow), ev + Vector2(3, -1.5 + narrow), ev + Vector2(3.5, 0.5), ev + Vector2(1, 2.5), ev + Vector2(-2, 2)]), EYE)
				p.draw_rect(Rect2(ev.x - 0.5, ev.y - 1 + narrow, 2, 3 - narrow), EYE_D)
				p.draw_rect(Rect2(ev.x - 2, ev.y - 1 + narrow, 1, 1), EYE_L)
				p.draw_line(ev + Vector2(-3.5, -1 + narrow), ev + Vector2(3.5, -1.5 + narrow), LID, 1.5)
	_brows(p, l, r, expr)


static func _brows(p: Portrait, l: Vector2, r: Vector2, expr: String) -> void:
	match expr:
		"angry":
			p.draw_line(l + Vector2(-4, -6), l + Vector2(3, -3), BROW, 1.5)
			p.draw_line(r + Vector2(4, -6), r + Vector2(-3, -3), BROW, 1.5)
		"stern":
			p.draw_line(l + Vector2(-4, -5), l + Vector2(3, -3.5), BROW, 1.5)
			p.draw_line(r + Vector2(4, -5), r + Vector2(-3, -3.5), BROW, 1.5)
		"sad":
			p.draw_line(l + Vector2(-4, -4), l + Vector2(3, -6), BROW, 1.0)
			p.draw_line(r + Vector2(4, -4), r + Vector2(-3, -6), BROW, 1.0)
		"surprised":
			p.draw_line(l + Vector2(-3, -7), l + Vector2(3, -8), BROW, 1.0)
			p.draw_line(r + Vector2(-3, -8), r + Vector2(3, -7), BROW, 1.0)
		"happy":
			p.draw_line(l + Vector2(-3, -5.5), l + Vector2(3, -6), BROW, 1.0)
			p.draw_line(r + Vector2(-3, -6), r + Vector2(3, -5.5), BROW, 1.0)
		_:
			# 곧고 단정한 눈썹
			p.draw_line(l + Vector2(-4, -5), l + Vector2(3, -4.5), BROW, 1.5)
			p.draw_line(r + Vector2(-3, -4.5), r + Vector2(4, -5), BROW, 1.5)


## 콧등을 가로지르는 흉터 (콧날 위를 비스듬히)
static func _scar(p: Portrait, fc: Vector2) -> void:
	p.draw_line(fc + Vector2(-3, 5), fc + Vector2(5, 2), SCAR, 1.0)
	p.draw_rect(Rect2(fc.x - 1, fc.y + 3, 1, 1), Color(SCAR, 0.6))


static func _mouth(p: Portrait, fc: Vector2, expr: String, talking: bool, t: float) -> void:
	var m := fc + Vector2(0, 11)
	var open := talking and int(t * 12.0) % 2 == 0
	match expr:
		"happy":
			# 작은 미소: 입꼬리가 올라간 짧은 곡선
			p.draw_line(m + Vector2(-3, -1), m + Vector2(-1, 0), MOUTH, 1.0)
			p.draw_line(m + Vector2(-1, 0), m + Vector2(2, 0), MOUTH, 1.0)
			p.draw_line(m + Vector2(2, 0), m + Vector2(4, -1.5), MOUTH, 1.0)
			if open:
				p.draw_rect(Rect2(m.x - 1, m.y, 3, 1), MOUTH.darkened(0.4))
		"angry":
			p.draw_line(m + Vector2(-3, 0.5), m + Vector2(3, -0.5), MOUTH, 1.5)
			if open:
				p.draw_rect(Rect2(m.x - 2.5, m.y, 5, 2), Color("#3a1414"))
				p.draw_rect(Rect2(m.x - 2.5, m.y, 5, 1), Color("#f0e8e0"))
		"sad":
			p.draw_line(m + Vector2(-2.5, 0.5), m + Vector2(2.5, 0.5), MOUTH, 1.0)
			p.draw_rect(Rect2(m.x - 3.5, m.y + 1, 1, 1), MOUTH)
		"surprised":
			p.draw_rect(Rect2(m.x - 1.5, m.y - 1, 3, 3), Color("#4a1a1a"))
		"stern":
			p.draw_line(m + Vector2(-3, 0), m + Vector2(3, 0), MOUTH.darkened(0.25), 1.0)
			if open:
				p.draw_rect(Rect2(m.x - 1.5, m.y, 3, 1.5), Color("#4a1a1a"))
		_:
			if open:
				p.draw_rect(Rect2(m.x - 2, m.y - 0.5, 4, 2), Color("#4a1a1a"))
			else:
				p.draw_line(m + Vector2(-2.5, 0), m + Vector2(2.5, 0), MOUTH, 1.0)


static func _front_hair(p: Portrait, fc: Vector2, t: float) -> void:
	var sw := sin(t * 1.8) * 0.7
	# 옆 가르마 앞머리 (화면 오른쪽으로 쓸어 넘김, 끝이 뾰족하게 갈라짐)
	KArt.poly(p, PackedVector2Array([
		fc + Vector2(-16, 3), fc + Vector2(-16, -9), fc + Vector2(-10, -18), fc + Vector2(-3, -21), fc + Vector2(8, -20),
		fc + Vector2(15, -13), fc + Vector2(16, -2), fc + Vector2(13, -8), fc + Vector2(9, -10), fc + Vector2(6, -6),
		fc + Vector2(3, -11), fc + Vector2(-1, -7), fc + Vector2(-4, -12), fc + Vector2(-8, -5), fc + Vector2(-10, -9), fc + Vector2(-12, 0),
	]), HAIR)
	# 옆머리 (얼굴을 감싸 턱선까지, 끝이 뾰족)
	KArt.poly(p, PackedVector2Array([fc + Vector2(-16, -4), fc + Vector2(-12, -3), fc + Vector2(-12, 9), fc + Vector2(-15 + sw * 0.4, 15), fc + Vector2(-17, 7)]), HAIR)
	KArt.poly(p, PackedVector2Array([fc + Vector2(16, -4), fc + Vector2(12, -4), fc + Vector2(12, 8), fc + Vector2(15 + sw * 0.4, 14), fc + Vector2(17, 6)]), HAIR)
	# 윤기 띠와 가닥
	p.draw_line(fc + Vector2(-11, -15), fc + Vector2(1, -19), HAIR_L, 1.0)
	p.draw_line(fc + Vector2(4, -18), fc + Vector2(12, -13), HAIR_L, 1.0)
	p.draw_line(fc + Vector2(-13, -8), fc + Vector2(-9, -15), HAIR_L, 1.0)
	p.draw_line(fc + Vector2(3, -11), fc + Vector2(4 + sw, -4), HAIR, 1.0)
	p.draw_line(fc + Vector2(-14, 0), fc + Vector2(-14, 11), HAIR_D, 1.0)


## 화면 왼쪽 귀 뒤로 땋아 내린 가는 머리 + 붉은 끈
static func _braid(p: Portrait, fc: Vector2, t: float) -> void:
	var at := fc + Vector2(-15, 5)
	var sw := sin(t * 1.5) * 0.6
	for i in 6:
		var nxt := at + Vector2(-0.7 + sw * 0.12 * i, 3.0)
		p.draw_line(at, nxt, OUT, 4.0)
		p.draw_line(at, nxt, HAIR_L if i % 2 == 0 else HAIR, 2.6)
		at = nxt
	p.draw_rect(Rect2(at.x - 1.5, at.y - 1, 3, 2), CAPE_L)
	p.draw_line(at + Vector2(0, 1), at + Vector2(-1 + sw, 3), HAIR, 1.0)
