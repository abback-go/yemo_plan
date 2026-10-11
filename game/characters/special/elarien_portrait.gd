extends "res://characters/special/elarien_palette.gd"
## 엘라리엔 대화 초상화 (72×72) — 낮게 묶어 어깨 앞으로 넘긴 긴 연금빛-초록 머리, 긴 귀(표정 따라 움직임),
## 초록 눈, 콧등·볼의 주근깨, 내려 쓴 잎새 무늬 두건, 금 잎 망토 고정쇠, 옆으로 솟은 흰 장궁의 윗날개(금 잎 장식).
## expr: normal · happy · angry · sad · surprised · smirk(건조한 비웃음 — 한쪽 입꼬리) · focus(시위를 볼까지 당김, 한 눈 감음)
##       hurt(다침) · tired(지침)

const HAIR_DK := Color("#6e7c46")
const HAIR_HI := Color("#f6fdd6")
const SKIN_SH := Color("#d9b49c")
const SKIN_DK := Color("#b88a72")
const FRECKLE := Color("#d9a68c")
const EYE_DK := Color("#1e6a34")
const CLOAK := Color("#3c5a2d")
const CLOAK_SH := Color("#263d1d")
const CLOAK_HI := Color("#618646")
const LEAF_PAT := Color("#52763c")
const LINE := Color("#3a2a20")
const BROW := Color("#8a8a52")


static func draw_portrait(p: Portrait, _info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	var b := sin(t * 2.0) * 0.6 + (sin(t * 18.0) * 0.4 if talking else 0.0)
	var fc := Vector2(37, 37 + b) # 얼굴 중심
	var ear_up := 0.0 # +면 귀가 올라감
	var ear_back := 0.0 # +면 귀가 뒤로 젖혀짐(화남)
	match expr:
		"surprised": ear_up = 4.0
		"angry": ear_back = 3.0; ear_up = -1.0
		"sad", "tired": ear_up = -4.0
		"hurt": ear_up = -2.0; ear_back = 2.0
		"happy", "smirk": ear_up = 1.0
	# 장궁 윗날개 (화면 왼쪽으로 솟음)
	_bow_limb(p, t, b)
	# 뒷머리 (어깨 뒤로)
	p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-16, -12), fc + Vector2(14, -14), fc + Vector2(17, 4), fc + Vector2(15, 30), fc + Vector2(-17, 32), fc + Vector2(-18, 2)]), HAIR_SH)
	# 어깨·망토 (내려 쓴 두건이 목을 감쌈)
	p.draw_colored_polygon(PackedVector2Array([Vector2(4, 72), Vector2(12, 56 + b), Vector2(26, 50 + b), Vector2(48, 50 + b), Vector2(62, 56 + b), Vector2(70, 72)]), CLOAK)
	p.draw_colored_polygon(PackedVector2Array([Vector2(4, 72), Vector2(12, 56 + b), Vector2(22, 52 + b), Vector2(20, 72)]), CLOAK_SH)
	# 잎 무늬
	for lp in [Vector2(14, 64), Vector2(54, 62), Vector2(62, 68), Vector2(30, 68)]:
		var q: Vector2 = lp + Vector2(0, b)
		_leaf(p, q, -PI * 0.5 + 0.6, 6.0, 2.2, LEAF_PAT)
	# 두건 접힘 (목 뒤)
	p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-16, 10), fc + Vector2(-8, 14), fc + Vector2(8, 14), fc + Vector2(16, 10), fc + Vector2(14, 18), fc + Vector2(-14, 18)]), CLOAK_SH)
	p.draw_line(fc + Vector2(-15, 10), fc + Vector2(-7, 13), CLOAK_HI, 1.0)
	p.draw_line(fc + Vector2(15, 10), fc + Vector2(7, 13), CLOAK_HI, 1.0)
	# 목과 튜닉 깃
	p.draw_rect(Rect2(fc.x - 4, fc.y + 10, 8, 7), SKIN_SH)
	p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-7, 16), fc + Vector2(0, 22), fc + Vector2(7, 16), fc + Vector2(6, 22), fc + Vector2(-6, 22)]), TUNIC)
	# 가죽 끈 (화살통)
	p.draw_line(Vector2(50, 52 + b), Vector2(30, 72), LEATHER, 2.0)
	# 금 잎 고정쇠
	var cl := Vector2(fc.x, fc.y + 21)
	p.draw_colored_polygon(PackedVector2Array([cl + Vector2(-4, 0), cl + Vector2(0, -3), cl + Vector2(4, 0), cl + Vector2(0, 3)]), GOLD)
	p.draw_line(cl + Vector2(-3, 0), cl + Vector2(3, 0), GOLD_HI, 1.0)
	# 긴 귀 (양쪽, 머리 뒤에서 옆·위로)
	_ear(p, fc, -1.0, ear_up, ear_back, t)
	_ear(p, fc, 1.0, ear_up, ear_back, t)
	# 얼굴
	var face := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var rx := 12.0
		var ry := 13.0 if sin(a) < 0 else 15.0
		var x := cos(a) * rx * (1.0 - maxf(sin(a), 0.0) * 0.18)
		face.append(fc + Vector2(x, sin(a) * ry))
	p.draw_colored_polygon(face, SKIN)
	p.draw_arc(fc + Vector2(0, 1), 12.0, 0.4, 1.5, 8, SKIN_SH, 1.0)
	# 볼 홍조·주근깨
	if expr in ["happy", "surprised", "smirk"]:
		p.draw_rect(Rect2(fc.x - 10, fc.y + 5, 4, 1), Color(1.0, 0.55, 0.5, 0.35))
		p.draw_rect(Rect2(fc.x + 6, fc.y + 5, 4, 1), Color(1.0, 0.55, 0.5, 0.35))
	for f in [Vector2(-7, 4), Vector2(-5, 5), Vector2(-2, 4), Vector2(2, 4), Vector2(5, 5), Vector2(7, 4)]:
		var fp: Vector2 = fc + f
		p.draw_rect(Rect2(fp, Vector2.ONE), FRECKLE)
	# 코 (작은 그림자)
	p.draw_line(fc + Vector2(0.5, 2), fc + Vector2(1.5, 5), SKIN_SH, 1.0)
	_eyes(p, fc, expr, blinking)
	_mouth(p, fc, expr, talking, t)
	if expr == "hurt":
		# 볼의 생채기
		p.draw_line(fc + Vector2(6, 1), fc + Vector2(10, -1), Color("#c84a4a"), 1.0)
	# 앞머리 (가운데 가르마, 가닥이 갈라짐)
	var bangs := PackedVector2Array([fc + Vector2(-14, 4), fc + Vector2(-14, -8), fc + Vector2(-8, -15), fc + Vector2(0, -16), fc + Vector2(8, -15),
		fc + Vector2(14, -8), fc + Vector2(14, 4), fc + Vector2(11, -3), fc + Vector2(8, -7), fc + Vector2(5, -2), fc + Vector2(2, -9),
		fc + Vector2(-1, -4), fc + Vector2(-4, -9), fc + Vector2(-7, -3), fc + Vector2(-10, -6), fc + Vector2(-12, 0)])
	p.draw_colored_polygon(bangs, HAIR)
	p.draw_line(fc + Vector2(-1, -15), fc + Vector2(-1, -9), HAIR_SH, 1.0)
	p.draw_arc(fc + Vector2(0, -6), 10.0, -2.7, -1.9, 6, HAIR_HI, 1.0)
	p.draw_arc(fc + Vector2(0, -6), 10.0, -1.2, -0.5, 5, HAIR_HI, 1.0)
	p.draw_line(fc + Vector2(-7, -10), fc + Vector2(-9, -4), HAIR_SH, 1.0)
	p.draw_line(fc + Vector2(6, -10), fc + Vector2(8, -5), HAIR_SH, 1.0)
	# 얼굴 옆으로 흘러내린 가닥 (따로 흔들림)
	var sw := sin(t * 1.7) * 1.0
	var sw2 := sin(t * 2.3 + 1.3) * 1.0
	p.draw_line(fc + Vector2(-13, -2), fc + Vector2(-14 + sw, 12), HAIR, 2.0)
	p.draw_line(fc + Vector2(-14 + sw, 12), fc + Vector2(-13 + sw * 1.5, 18), HAIR_SH, 1.0)
	p.draw_line(fc + Vector2(13, -2), fc + Vector2(13 + sw2, 10), HAIR, 2.0)
	p.draw_line(fc + Vector2(13 + sw2, 10), fc + Vector2(12 + sw2 * 1.5, 15), HAIR_SH, 1.0)
	# 낮게 묶어 오른쪽(화면) 어깨 앞으로 넘긴 머리 꼬리
	var tail := PackedVector2Array()
	for i in 8:
		var k := float(i) / 7.0
		tail.append(fc + Vector2(13 + k * 6 + sin(t * 1.4 + k * 2.0) * 1.2 * k, 14 + k * 22))
	for i in tail.size() - 1:
		var w := lerpf(7.0, 3.0, float(i) / (tail.size() - 1))
		p.draw_line(tail[i], tail[i + 1], HAIR_SH, w)
		p.draw_line(tail[i] + Vector2(-0.5, 0), tail[i + 1] + Vector2(-0.5, 0), HAIR, maxf(w - 2.5, 1.0))
	p.draw_line(tail[1] + Vector2(-1.5, 0), tail[4] + Vector2(-1.5, 0), HAIR_HI, 1.0)
	# 금 잎 머리끈
	var tie: Vector2 = tail[1]
	p.draw_rect(Rect2(tie.x - 3, tie.y - 1, 6, 3), GOLD)
	p.draw_rect(Rect2(tie.x - 3, tie.y - 1, 6, 1), GOLD_HI)
	_leaf(p, tie + Vector2(3, 0), 0.4, 6.0, 2.0, GOLD)
	if expr == "focus":
		_focus_hand(p, fc, t)


static func _ear(p: Portrait, fc: Vector2, side: float, up: float, back: float, t: float) -> void:
	var base := fc + Vector2(side * 11.0, -1.0)
	var tw := sin(t * 0.9 + side) * 0.5
	var tip := fc + Vector2(side * (27.0 - back * 2.0), -13.0 - up + back * 1.5 + tw)
	var pts := PackedVector2Array([base + Vector2(0, -4), tip, base + Vector2(0, 5)])
	p.draw_colored_polygon(pts, SKIN)
	p.draw_line(base + Vector2(side * 1.5, 1), tip + Vector2(-side * 3.0, 2.5), SKIN_SH, 1.0)
	p.draw_line(base + Vector2(0, 5), tip, SKIN_DK, 1.0)
	# 귀걸이 (작은 금 잎)
	p.draw_rect(Rect2(base.x + side * 2.0 - 1, base.y + 4, 2, 2), GOLD)


static func _eyes(p: Portrait, fc: Vector2, expr: String, blinking: bool) -> void:
	var l := fc + Vector2(-5.5, 1)
	var r := fc + Vector2(5.5, 1)
	if blinking and not expr in ["surprised"]:
		for e in [l, r]:
			var ep: Vector2 = e
			p.draw_line(ep + Vector2(-3, 0), ep + Vector2(3, 0), LINE, 1.0)
		_brows(p, l, r, expr)
		return
	match expr:
		"happy":
			for e in [l, r]:
				p.draw_arc(e + Vector2(0, 2), 3, PI + 0.3, TAU - 0.3, 6, LINE, 1.5)
		"smirk":
			# 반쯤 감은 눈 (위 눈꺼풀이 내려옴)
			for e in [l, r]:
				var ep: Vector2 = e
				p.draw_rect(Rect2(ep.x - 2, ep.y, 4, 2), EYE)
				p.draw_rect(Rect2(ep.x - 1, ep.y, 1, 1), Color(1, 1, 1, 0.8))
				p.draw_line(ep + Vector2(-3, -0.5), ep + Vector2(3, -0.5), LINE, 1.0)
		"focus":
			# 왼눈 감고 오른눈으로 겨눔
			p.draw_line(l + Vector2(-3, 1), l + Vector2(3, 0), LINE, 1.0)
			p.draw_rect(Rect2(r.x - 2, r.y - 1, 4, 3), EYE)
			p.draw_rect(Rect2(r.x - 1, r.y - 1, 1, 3), EYE_DK)
			p.draw_rect(Rect2(r.x + 1, r.y - 1, 1, 1), Color(1, 1, 1, 0.9))
			p.draw_line(r + Vector2(-3, -2), r + Vector2(3, -2), LINE, 1.0)
		"surprised":
			for e in [l, r]:
				var ep: Vector2 = e
				p.draw_circle(ep, 3.2, Color.WHITE)
				p.draw_circle(ep, 2.0, EYE)
				p.draw_rect(Rect2(ep.x - 0.5, ep.y - 0.5, 1, 1), EYE_DK)
		"angry":
			for e in [l, r]:
				var ep: Vector2 = e
				p.draw_rect(Rect2(ep.x - 2, ep.y - 0.5, 4, 2.5), EYE)
				p.draw_rect(Rect2(ep.x - 0.5, ep.y - 0.5, 1, 2), EYE_DK)
				p.draw_line(ep + Vector2(-3, -1), ep + Vector2(3, -1), LINE, 1.0)
		"sad", "tired":
			for e in [l, r]:
				var ep: Vector2 = e
				p.draw_rect(Rect2(ep.x - 2, ep.y + 0.5, 4, 2), EYE)
				p.draw_line(ep + Vector2(-3, 0), ep + Vector2(3, 0.5), LINE, 1.0)
		"hurt":
			p.draw_line(l + Vector2(-3, 0), l + Vector2(3, 1), LINE, 1.0)
			p.draw_line(l + Vector2(-3, 2), l + Vector2(3, 1), LINE, 1.0)
			p.draw_rect(Rect2(r.x - 2, r.y - 1, 4, 3), EYE)
			p.draw_rect(Rect2(r.x - 1, r.y - 1, 1, 1), Color(1, 1, 1, 0.8))
		_:
			# 무덤덤한 눈: 아몬드형, 위 속눈썹 선
			for e in [l, r]:
				var ep: Vector2 = e
				p.draw_rect(Rect2(ep.x - 2, ep.y - 1.5, 4, 3.5), EYE)
				p.draw_rect(Rect2(ep.x - 0.5, ep.y - 1, 1.5, 2.5), EYE_DK)
				p.draw_rect(Rect2(ep.x - 2, ep.y - 1.5, 1, 1), Color(1, 1, 1, 0.9))
				p.draw_line(ep + Vector2(-3, -2), ep + Vector2(3, -2.5), LINE, 1.0)
	_brows(p, l, r, expr)


static func _brows(p: Portrait, l: Vector2, r: Vector2, expr: String) -> void:
	match expr:
		"angry":
			p.draw_line(l + Vector2(-3, -6), l + Vector2(3, -4), BROW, 1.0)
			p.draw_line(r + Vector2(3, -6), r + Vector2(-3, -4), BROW, 1.0)
		"sad", "tired", "hurt":
			p.draw_line(l + Vector2(-3, -4), l + Vector2(3, -6), BROW, 1.0)
			p.draw_line(r + Vector2(3, -4), r + Vector2(-3, -6), BROW, 1.0)
		"surprised":
			p.draw_line(l + Vector2(-3, -7), l + Vector2(3, -7), BROW, 1.0)
			p.draw_line(r + Vector2(-3, -7), r + Vector2(3, -7), BROW, 1.0)
		"smirk":
			# 한쪽 눈썹만 들림
			p.draw_line(l + Vector2(-3, -5), l + Vector2(3, -5), BROW, 1.0)
			p.draw_line(r + Vector2(-3, -6), r + Vector2(3, -7.5), BROW, 1.0)
		_:
			p.draw_line(l + Vector2(-3, -5), l + Vector2(3, -5), BROW, 1.0)
			p.draw_line(r + Vector2(-3, -5), r + Vector2(3, -5), BROW, 1.0)


static func _mouth(p: Portrait, fc: Vector2, expr: String, talking: bool, t: float) -> void:
	var m := fc + Vector2(0, 10)
	var col := Color("#9a4a3e")
	var open := talking and int(t * 12.0) % 2 == 0
	match expr:
		"happy":
			p.draw_arc(m + Vector2(0, -2), 3, 0.3, PI - 0.3, 6, col, 1.0)
		"smirk":
			# 건조한 비웃음: 한쪽(오른쪽) 입꼬리만 올라감
			p.draw_line(m + Vector2(-2, 0), m + Vector2(2, 0), col, 1.0)
			p.draw_line(m + Vector2(2, 0), m + Vector2(4, -1.5), col, 1.0)
		"angry":
			p.draw_line(m + Vector2(-2, 0.5), m + Vector2(2, 0), col, 1.0)
		"sad", "tired":
			p.draw_arc(m + Vector2(0, 2), 2.5, PI + 0.4, TAU - 0.4, 6, col, 1.0)
		"surprised":
			p.draw_circle(m, 1.8, col)
		"hurt":
			p.draw_line(m + Vector2(-2, 0), m + Vector2(2, 1), col, 1.0)
			p.draw_rect(Rect2(m.x - 1, m.y, 2, 1), Color("#f0e8e0"))
		"focus":
			p.draw_line(m + Vector2(-1.5, 0), m + Vector2(1.5, 0), col, 1.0)
		_:
			if open:
				p.draw_rect(Rect2(m.x - 1.5, m.y - 0.5, 3, 2), col)
			else:
				p.draw_line(m + Vector2(-1.5, 0), m + Vector2(1.5, 0), col, 1.0)


static func _bow_limb(p: Portrait, t: float, b: float) -> void:
	# 화면 왼쪽 가장자리로 솟은 흰 장궁의 윗날개 + 금 잎 + 빛 반사
	var pts := PackedVector2Array()
	for i in 9:
		var k := float(i) / 8.0
		pts.append(Vector2(9 - sin(k * PI * 0.5) * 4.0, 72 - k * 66 + b * 0.5))
	for i in pts.size() - 1:
		var w := lerpf(4.0, 2.0, float(i) / (pts.size() - 1))
		p.draw_line(pts[i], pts[i + 1], BOW_SH, w + 1.0)
		p.draw_line(pts[i] + Vector2(0.5, 0), pts[i + 1] + Vector2(0.5, 0), BOW, w)
	p.draw_line(pts[pts.size() - 1], Vector2(13, 72), Color(0.86, 0.92, 0.96, 0.6), 1.0)
	var tip := pts[pts.size() - 1]
	p.draw_rect(Rect2(tip.x - 2, tip.y - 2, 4, 4), GOLD)
	p.draw_rect(Rect2(tip.x - 2, tip.y - 2, 2, 2), GOLD_HI)
	_leaf(p, pts[5] + Vector2(1, 0), -0.6, 7.0, 2.2, GOLD)
	_leaf(p, pts[5] + Vector2(1, 2), 0.4, 6.0, 2.0, GOLD.darkened(0.1))
	var g := fmod(t, 3.4)
	if g < 0.6:
		var k2 := g / 0.6
		var gp := pts[int(k2 * (pts.size() - 1))]
		p.draw_rect(Rect2(gp.x - 0.5, gp.y - 1, 2, 2), Color.WHITE)
		p.draw_circle(gp, 3.0, Color(1, 1, 1, 0.2))


static func _focus_hand(p: Portrait, fc: Vector2, t: float) -> void:
	# 시위를 볼까지 당긴 손: 붕대 감은 손가락 + 시위 + 흰 깃
	var h := fc + Vector2(16, 9)
	p.draw_line(Vector2(fc.x + 22, -2), h + Vector2(-1, 0), Color(0.88, 0.94, 0.98, 0.8), 1.0)
	p.draw_line(h + Vector2(-1, 0), Vector2(fc.x + 24, 74), Color(0.88, 0.94, 0.98, 0.8), 1.0)
	p.draw_line(h + Vector2(-6, 1), h + Vector2(14, 0), Color("#c8a878"), 1.0)
	p.draw_line(h + Vector2(-6, 1), h + Vector2(-10, -2), Color.WHITE, 1.0)
	p.draw_line(h + Vector2(-6, 1), h + Vector2(-10, 3), Color(0.9, 0.9, 0.92), 1.0)
	p.draw_rect(Rect2(h.x - 1, h.y - 3, 6, 6), SKIN)
	for i in 3:
		p.draw_line(h + Vector2(-1, -2 + i * 2), h + Vector2(5, -2 + i * 2), WRAP, 1.0)
	# 모여드는 바람
	for i in 3:
		var ph := fmod(t * 1.4 + i * 0.33, 1.0)
		var r := lerpf(14.0, 2.0, ph)
		var a := i * 2.1 + t
		var q := h + Vector2(14, 0) + Vector2(cos(a), sin(a)) * r
		p.draw_line(q, q.lerp(h + Vector2(14, 0), 0.3), Color(0.86, 1.0, 0.82, 0.6 * (1.0 - ph)), 1.0)


static func _leaf(p: Portrait, c: Vector2, ang: float, len: float, wid: float, col: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	p.draw_colored_polygon(PackedVector2Array([c - d * len * 0.5, c + n * wid, c + d * len * 0.5, c - n * wid]), col)
