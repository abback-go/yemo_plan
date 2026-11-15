extends RefCounted
## 너울 본모습(neoul_god) 대화 초상화 (72×72) — 1장 그림(얼굴을 가린 너울, 여우귀, 흰 옷의 붉은 깃, 금 띠, 뒤의 아홉 꼬리 그림자)을
## 그대로 잇되 더 공들여: 은백 머리, 너울 천의 푸른 수, 천 아래로 비치는 눈빛, 귀 끝·꼬리 끝의 푸른 여우불.
## expr: normal · angry/scary(눈빛이 타오름) · sad(귀가 처짐) · happy/smug · surprised
##       gentle  — 5장 어둠: 너울(천)을 걷어 처음으로 얼굴을 보인다. 다정한 눈 ("세라야.")
##       tearful — 천을 걷은 채 눈물
##       awaken  — 아홉 꼬리 각성: 꼬리가 모두 타오르고 금빛·푸른 기운

const FUR := Color("#f4f0ea")
const HAIR := Color("#e2e8f4")
const HAIR_SH := Color("#a8b4d0")
const SKIN := Color("#f6ece8")
const SKIN_SH := Color("#dcc8cc")
const ROBE := Color("#e8eaf2")
const ROBE_SH := Color("#aab2cc")
const RED := Color("#b83a3a")
const NAVY := Color("#2a3a7a")
const GOLD := Color("#d8b050")
const BLUE := Color(0.45, 0.78, 1.0)
const CORE := Color(0.88, 0.97, 1.0)


static func draw_portrait(p: Portrait, _info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void:
	if expr == "scary":
		expr = "angry"
	if expr == "smug":
		expr = "happy"
	var unveiled := expr in ["gentle", "tearful"]
	var awaken := expr == "awaken"
	var b := sin(t * 1.5) * 0.7 + (sin(t * 16.0) * 0.4 if talking else 0.0)
	var c := Vector2(36, 40 + b)
	# 배경: 깊은 어둠 + 푸른 여우불 티끌
	for i in 12:
		p.draw_rect(Rect2(0, i * 6, 72, 6), Color("#02040c").lerp(Color("#0c1834"), float(i) / 11.0))
	if awaken:
		p.draw_circle(c, 40.0, Color(StArt.FOX_GOLD, 0.08 + 0.04 * sin(t * 3.0)))
	# 아홉 꼬리 (뒤에서 부채꼴)
	for i in 9:
		var a := -PI * 0.5 + (i - 4) * 0.33 + sin(t * 1.2 + i) * 0.04
		var root := c + Vector2(0, 14)
		var tip := root + Vector2(cos(a), sin(a)) * 48.0
		var mid := root.lerp(tip, 0.55) + Vector2(sin(t * 1.6 + i) * 3.0, 0)
		var n := (tip - root).normalized().orthogonal()
		var col := Color(0.35, 0.6, 1.0, 0.22) if not awaken else Color(0.75, 0.9, 1.0, 0.55)
		p.draw_colored_polygon(PackedVector2Array([root + n * 3.0, mid + n * 7.0, tip, mid - n * 7.0, root - n * 3.0]), col)
		var fire := 0.4 if not awaken else 1.0
		StArt.foxfire(p, tip, 3.0 if not awaken else 4.0, t + i, fire)
	# 옷 (흰 저고리 같은 겉옷, 붉은 깃, 남색 띠)
	p.draw_colored_polygon(PackedVector2Array([Vector2(5, 72), Vector2(15, 56 + b), Vector2(57, 56 + b), Vector2(67, 72)]), ROBE)
	p.draw_colored_polygon(PackedVector2Array([Vector2(5, 72), Vector2(15, 56 + b), Vector2(22, 58 + b), Vector2(16, 72)]), ROBE_SH)
	p.draw_colored_polygon(PackedVector2Array([Vector2(28, 56 + b), Vector2(36, 72), Vector2(44, 56 + b), Vector2(40, 56 + b), Vector2(36, 64 + b), Vector2(32, 56 + b)]), RED)
	p.draw_rect(Rect2(14, 68 + b * 0.3, 44, 4), NAVY)
	for i in 3:
		p.draw_rect(Rect2(20 + i * 14, 69 + b * 0.3, 2, 2), Color(BLUE, 0.8))
	# 뒷머리
	for side: float in [-1.0, 1.0]:
		p.draw_colored_polygon(PackedVector2Array([c + Vector2(side * 9, -14), c + Vector2(side * 17, -6), c + Vector2(side * 19, 14), c + Vector2(side * 18, 32), c + Vector2(side * 10, 32), c + Vector2(side * 10, 0)]), HAIR_SH)
	# 여우귀 (기분에 따라 처지거나 섬)
	var ear_drop := 6.0 if expr in ["sad", "tearful"] else (0.0 if expr != "surprised" else -3.0)
	var tw := sin(t * 2.5) * 1.0
	for side: float in [-1.0, 1.0]:
		var base := c + Vector2(side * 10, -13)
		var tip := c + Vector2(side * (17 + ear_drop * 0.6) + tw * side * 0.3, -33 + ear_drop)
		p.draw_colored_polygon(PackedVector2Array([base + Vector2(-side * 4, 0), tip, base + Vector2(side * 5, 4)]), FUR)
		p.draw_colored_polygon(PackedVector2Array([base + Vector2(-side * 1, -1), tip.lerp(base, 0.25), base + Vector2(side * 3, 2)]), Color("#f0c8cc"))
		StArt.foxfire(p, tip + Vector2(0, 2), 2.0, t + side, 0.9)
	# 얼굴
	var face := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		var px := cos(a) * 12.0
		if sin(a) > 0.35:
			px *= 0.8 # 갸름한 여우 턱
		face.append(c + Vector2(px, sin(a) * (13.0 if sin(a) < 0 else 15.0)))
	p.draw_colored_polygon(face, SKIN)
	if unveiled:
		_face_unveiled(p, c, expr, t, talking, blinking)
	# 앞머리
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 0), c + Vector2(-11, -9), c + Vector2(-4, -14), c + Vector2(4, -14), c + Vector2(11, -9),
		c + Vector2(12, 0), c + Vector2(8, -6), c + Vector2(2, -10), c + Vector2(-3, -9), c + Vector2(-8, -5)]), HAIR)
	p.draw_line(c + Vector2(-7, -10), c + Vector2(0, -13), Color(1, 1, 1, 0.8), 1.0)
	if not unveiled:
		_veil(p, c, expr, t, talking)
	# 이마의 금 띠 + 비녀 여우불
	p.draw_rect(Rect2(c.x - 12, c.y - 14, 24, 3), GOLD)
	p.draw_rect(Rect2(c.x - 1, c.y - 15, 2, 4), RED)
	StArt.foxfire(p, c + Vector2(0, -20), 2.5 if not awaken else 4.0, t, 1.0)
	if awaken:
		for i in 6:
			var a2 := t * 1.5 + TAU * i / 6.0
			p.draw_rect(Rect2(c + Vector2(cos(a2) * 26.0, sin(a2) * 20.0), Vector2(2, 2)), Color(StArt.FOX_GOLD, 0.8))


## 너울(얼굴을 가리는 천): 반투명, 푸른 수 무늬. 천 아래로 눈빛이 비친다
static func _veil(p: Portrait, c: Vector2, expr: String, t: float, talking: bool) -> void:
	var sway := sin(t * 1.3) * 1.5
	var veil := PackedVector2Array([c + Vector2(-13, -12), c + Vector2(13, -12), c + Vector2(15 + sway, 20), c + Vector2(0, 23), c + Vector2(-15 + sway, 20)])
	p.draw_colored_polygon(veil, Color(0.88, 0.9, 0.98, 0.84))
	for i in 5:
		p.draw_line(c + Vector2(-12 + i * 6, -12), c + Vector2(-14 + i * 7 + sway, 21), Color(0.72, 0.74, 0.88, 0.55), 1.0)
	p.draw_rect(Rect2(c.x - 13, c.y - 13, 26, 2), NAVY)
	for i in 4:
		p.draw_rect(Rect2(c.x - 9 + i * 6, c.y + 15 + sin(t + i) * 0.6, 2, 2), Color(BLUE, 0.85))
	# 눈빛
	var glow := 0.55 + 0.25 * sin(t * 2.0)
	var col := Color(0.5, 0.85, 1.0, glow)
	match expr:
		"angry":
			col = Color(0.75, 0.95, 1.0, 1.0)
			p.draw_line(c + Vector2(-9, -2), c + Vector2(-3, 1), col, 2.0)
			p.draw_line(c + Vector2(9, -2), c + Vector2(3, 1), col, 2.0)
			p.draw_circle(c + Vector2(-6, 1), 4.0, Color(0.6, 0.9, 1.0, 0.25))
			p.draw_circle(c + Vector2(6, 1), 4.0, Color(0.6, 0.9, 1.0, 0.25))
		"sad":
			p.draw_rect(Rect2(c.x - 8, c.y + 1, 4, 1), Color(col, glow * 0.6))
			p.draw_rect(Rect2(c.x + 4, c.y + 1, 4, 1), Color(col, glow * 0.6))
		"happy":
			p.draw_arc(c + Vector2(-6, 2), 2.5, PI, TAU, 6, col, 1.5)
			p.draw_arc(c + Vector2(6, 2), 2.5, PI, TAU, 6, col, 1.5)
		"surprised":
			p.draw_circle(c + Vector2(-6, 0), 2.0, col)
			p.draw_circle(c + Vector2(6, 0), 2.0, col)
		"awaken":
			col = Color(0.85, 0.97, 1.0)
			p.draw_rect(Rect2(c.x - 9, c.y - 1, 5, 2), col)
			p.draw_rect(Rect2(c.x + 4, c.y - 1, 5, 2), col)
			p.draw_circle(c + Vector2(-6.5, 0), 5.0, Color(StArt.FOX_GOLD, 0.25))
			p.draw_circle(c + Vector2(6.5, 0), 5.0, Color(StArt.FOX_GOLD, 0.25))
		_:
			p.draw_rect(Rect2(c.x - 8, c.y - 1, 4, 2), col)
			p.draw_rect(Rect2(c.x + 4, c.y - 1, 4, 2), col)
	if talking and int(t * 11.0) % 2 == 0:
		p.draw_rect(Rect2(c.x - 1, c.y + 10, 2, 1), Color(0.5, 0.6, 0.8, 0.6))


## 천을 걷은 얼굴: 아몬드 모양의 푸른 여우 눈, 붉은 눈꼬리, 작은 입
static func _face_unveiled(p: Portrait, c: Vector2, expr: String, t: float, talking: bool, blinking: bool) -> void:
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -2), c + Vector2(-9.5, -8), c + Vector2(-8.5, 8), c + Vector2(-10, 6)]), SKIN_SH)
	var tear := expr == "tearful"
	for side: float in [-1.0, 1.0]:
		var e := c + Vector2(side * 5.5, 2)
		# 붉은 눈꼬리 화장 (구미호)
		p.draw_line(e + Vector2(side * 3.5, -1), e + Vector2(side * 6.0, -3.0), RED, 1.0)
		if blinking:
			p.draw_line(e + Vector2(-3, 0.5), e + Vector2(3, 0.5), Color("#2a2a40"), 1.0)
			continue
		if tear:
			p.draw_arc(e + Vector2(0, 2.0), 3.0, PI + 0.3, TAU - 0.3, 8, Color("#2a2a40"), 1.5)
			var k := fmod(t * 0.5 + (0.5 if side > 0 else 0.0), 1.0)
			p.draw_rect(Rect2(e + Vector2(side * 1.5, 3.0 + k * 9.0), Vector2(1, 2)), Color(0.75, 0.9, 1.0, 0.9 - k * 0.6))
			continue
		# 아몬드 눈: 위 속눈썹 굵게, 푸른 홍채, 세로로 가는 동공
		var eye := PackedVector2Array([e + Vector2(-3.5, 0.5), e + Vector2(-1.5, -2), e + Vector2(2.5, -2.2), e + Vector2(3.8, -0.5), e + Vector2(1.5, 2), e + Vector2(-2, 2)])
		p.draw_colored_polygon(eye, Color("#fbfaff"))
		p.draw_circle(e + Vector2(0.3, 0), 2.1, Color(0.3, 0.6, 1.0))
		p.draw_rect(Rect2(e + Vector2(0, -1.5), Vector2(1, 3)), Color("#0a1430"))
		p.draw_rect(Rect2(e + Vector2(-1, -1.2), Vector2(1, 1)), Color(1, 1, 1, 0.9))
		p.draw_line(e + Vector2(-3.8, 0.0), e + Vector2(-1.5, -2.4), Color("#2a2a40"), 1.5)
		p.draw_line(e + Vector2(-1.5, -2.4), e + Vector2(3.0, -2.6), Color("#2a2a40"), 1.5)
	# 입
	var m := c + Vector2(0, 10)
	if talking and int(t * 11.0) % 2 == 0:
		p.draw_rect(Rect2(m.x - 1.5, m.y - 0.5, 3, 2), Color("#a04a5a"))
	elif tear:
		p.draw_arc(m + Vector2(0, 1.5), 2.0, PI + 0.4, TAU - 0.4, 6, Color("#b0505a"), 1.0)
	else:
		p.draw_arc(m + Vector2(0, -1.5), 2.5, 0.35, PI - 0.35, 6, Color("#b0505a"), 1.2)
	# 걷어 올린 천 (머리 위로 넘김)
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(-14, -12), c + Vector2(14, -12), c + Vector2(17, -20), c + Vector2(-17, -20)]), Color(0.88, 0.9, 0.98, 0.7))
	p.draw_rect(Rect2(c.x - 15, c.y - 21, 30, 2), NAVY)
