extends RefCounted
## 루멘 대신전 사람들 몸 그림 (CharacterVisual이 static draw_body(v)를 부름) — docs/archive/sera/chapter4.md 7.3절.
## 인물 정보의 "look"으로 모양을 고른다: benedicta(늙은 대사제: 높은 관·너울·해 지팡이) · luca(견습 소년: 손종)
## · gregor(종지기 노인: 대머리·흰 수염·굽은 등·밧줄 뭉치·귀에 손) · monk(두건 수도사) · priest(사제: 금 영대·작은 모자·경전)
## · pilgrim(순례자: 두건 망토·목도리·등불 지팡이·봇짐) · choir(성가대: 흰 옷·악보, 가끔 노래)
## 옷 색은 robe/robe2, 피부·머리는 skin/hair. 숨쉬기·눈 깜빡임·걷기·말하기 움직임.

const OUTL := Color("#16101f")
const GOLD := Color("#e0b048")
const GOLD_L := Color("#fff0a8")
const WOOD := Color("#6a4a30")


static func draw_body(v: CharacterVisual) -> void:
	var info := v.info
	var look := String(info.get("look", "monk"))
	var h := float(info.get("height", 32))
	var robe: Color = info.get("robe", Color("#dcd8e6"))
	var robe2: Color = info.get("robe2", GOLD)
	var skin: Color = info.get("skin", Color("#f0d0c0"))
	var hair: Color = info.get("hair", Color("#4a3a30"))
	var t := v.time()
	var walk := v.walking
	var ph := v.walk_phase()
	var bob := sin(t * 2.0) * 0.5 if not walk else -absf(sin(ph)) * 1.0
	if v.talking:
		bob += sin(t * 14.0) * 0.3
	var hunch := 0.0
	if look == "gregor":
		hunch = 3.0
	elif look == "benedicta":
		hunch = 1.0
	var s := h / 32.0
	var head := Vector2(1.0 + hunch, -h + 6.5 * s + bob + hunch * 0.6)
	var hr := 5.6 * s
	var top_y := -h + 12.5 * s + bob + hunch * 0.3
	# 윤곽 빛
	v.draw_circle(Vector2(0, -h * 0.5), h * 0.5, Color(robe2, 0.05))
	# 등에 멘 것 (뒤)
	if look == "pilgrim":
		_poly(v, PackedVector2Array([Vector2(-8 * s, top_y + 2), Vector2(-3 * s, top_y + 1), Vector2(-3 * s, top_y + 11 * s), Vector2(-9 * s, top_y + 12 * s)]), Color("#7a5a3a"))
		v.draw_line(Vector2(-9 * s, top_y + 1), Vector2(-3 * s, top_y + 1), Color("#d8c8a0"), 2.0)
	elif look == "gregor":
		v.draw_arc(Vector2(-5, top_y + 5), 4.0, 0, TAU, 12, Color("#c8a870"), 2.0)
		v.draw_arc(Vector2(-5, top_y + 5), 2.0, 0, TAU, 8, Color("#a8885a"), 1.0)
	# 다리
	var leg := sin(ph) * 2.5 if walk else 0.0
	v.draw_rect(Rect2(-3 + leg, -5 * s, 2, 5 * s), Color("#2a2028"))
	v.draw_rect(Rect2(1 - leg, -5 * s, 2, 5 * s), Color("#2a2028"))
	# 로브 (긴 옷자락)
	var hem := -3.0 * s if look != "luca" else -6.0 * s
	var sw := sin(t * 2.0) * 0.5
	var robe_pts := PackedVector2Array([
		Vector2(-4.5 * s, top_y), Vector2(5.5 * s, top_y), Vector2(8 * s + sw, hem), Vector2(-7.5 * s + sw, hem),
	])
	_poly(v, robe_pts, robe)
	v.draw_colored_polygon(PackedVector2Array([Vector2(-4.5 * s, top_y), Vector2(-1.0 * s, top_y), Vector2(-2.5 * s + sw, hem), Vector2(-7.5 * s + sw, hem)]), robe.darkened(0.18))
	v.draw_line(Vector2(-7.5 * s + sw, hem), Vector2(8 * s + sw, hem), robe2, 1.0)
	match look:
		"benedicta", "priest":
			# 금 영대 (앞으로 늘어진 띠)
			v.draw_rect(Rect2(1.5 * s, top_y + 1, 2.0 * s, hem - top_y - 2), robe2)
			v.draw_rect(Rect2(1.5 * s, hem - 4 * s, 2.0 * s, 1), GOLD_L)
			v.draw_circle(Vector2(2.5 * s, top_y + 6 * s), 1.2 * s, GOLD_L)
		"monk":
			v.draw_line(Vector2(-4 * s, top_y + 9 * s), Vector2(5 * s, top_y + 9 * s), robe2, 1.5)
			v.draw_line(Vector2(3 * s, top_y + 9 * s), Vector2(4 * s, top_y + 15 * s), robe2, 1.0)
		"luca":
			v.draw_line(Vector2(-4 * s, top_y + 8 * s), Vector2(5.5 * s, top_y + 8 * s), robe2, 2.0)
		"gregor":
			v.draw_rect(Rect2(-2 * s, top_y + 4 * s, 7 * s, hem - top_y - 6 * s), Color("#c8b898"))
			v.draw_line(Vector2(-2 * s, top_y + 4 * s), Vector2(5 * s, top_y + 4 * s), Color("#8a7a5a"), 1.0)
		"pilgrim":
			v.draw_line(Vector2(-4.5 * s, top_y + 1), Vector2(5.5 * s, top_y + 2), robe2, 2.5)
			v.draw_line(Vector2(4.5 * s, top_y + 2), Vector2(6.0 * s, top_y + 7 * s), robe2, 2.0)
		"choir":
			_poly(v, PackedVector2Array([Vector2(-4 * s, top_y), Vector2(5 * s, top_y), Vector2(3 * s, top_y + 4 * s), Vector2(-2 * s, top_y + 4 * s)]), robe2)
	# 팔 + 손에 든 것
	var arm_swing := sin(ph) * 2.0 if walk else (sin(t * 9.0) * 1.2 if v.talking else 0.0)
	var hand := Vector2(5.5 * s + arm_swing, top_y + 9 * s)
	match look:
		"benedicta":
			hand = Vector2(7 * s, top_y + 7 * s)
			_staff(v, Vector2(8 * s, 0), Vector2(8 * s, -h - 6 * s), true)
		"pilgrim":
			hand = Vector2(7 * s, top_y + 6 * s)
			_staff(v, Vector2(8 * s, 0), Vector2(8 * s, -h - 2 * s), false)
			var lp := Vector2(8 * s + sin(t * 1.6) * 0.8, -h - 1 * s)
			v.draw_line(Vector2(8 * s, -h - 2 * s), lp + Vector2(0, 2), Color("#3a3036"), 1.0)
			v.draw_rect(Rect2(lp.x - 2, lp.y + 2, 4, 5), Color(1.0, 0.82, 0.45, 0.85 + 0.15 * sin(t * 7.0)))
			v.draw_circle(lp + Vector2(0, 4), 6.0, Color(1.0, 0.8, 0.45, 0.12))
		"luca":
			hand = Vector2(6 * s, top_y + 8 * s)
			var bp := hand + Vector2(1, 2) + Vector2(sin(t * 6.0) * 0.6 if v.talking else 0.0, 0)
			_poly(v, PackedVector2Array([bp + Vector2(-2, 0), bp + Vector2(2, 0), bp + Vector2(3, 4), bp + Vector2(-3, 4)]), GOLD)
			v.draw_line(bp + Vector2(0, -2), bp, WOOD, 1.0)
		"gregor":
			hand = Vector2(6 * s, top_y + 9 * s)
			v.draw_line(hand + Vector2(-1, -3), hand + Vector2(3, 5), WOOD, 2.0)
			v.draw_rect(Rect2(hand.x + 1, hand.y + 4, 5, 3), Color("#8a6a48"))
		"priest", "choir":
			hand = Vector2(5 * s, top_y + 7 * s)
			var bk := hand + Vector2(1, -1)
			_poly(v, PackedVector2Array([bk + Vector2(-3, 0), bk + Vector2(3, -1), bk + Vector2(3, 3), bk + Vector2(-3, 4)]), Color("#e8dcc0") if look == "choir" else Color("#6a2a34"))
			if look == "priest":
				v.draw_circle(bk + Vector2(0, 1.5), 1.0, GOLD)
		"monk":
			hand = Vector2(3 * s, top_y + 8 * s)
	v.draw_line(Vector2(4 * s, top_y + 2), hand, robe.lightened(0.08) if look != "pilgrim" else robe.darkened(0.1), 2.5)
	if look != "monk":
		v.draw_circle(hand, 1.3, skin)
	else:
		v.draw_rect(Rect2(hand.x - 3, hand.y - 1, 5, 3), robe.darkened(0.12))
	# 머리
	_head(v, look, head, hr, s, skin, hair, robe, robe2, t, bob)


static func _poly(v: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	DrawKit.outlined_poly(v, pts, col, OUTL)


static func _staff(v: CanvasItem, a: Vector2, b: Vector2, sun: bool) -> void:
	v.draw_line(a, b, OUTL, 3.0)
	v.draw_line(a, b, WOOD if not sun else GOLD, 1.5)
	if sun:
		v.draw_circle(b, 4.0, OUTL)
		v.draw_circle(b, 3.2, GOLD)
		v.draw_circle(b, 1.6, GOLD_L)
		for i in 8:
			var ang := TAU * i / 8.0
			v.draw_line(b + Vector2(cos(ang), sin(ang)) * 3.6, b + Vector2(cos(ang), sin(ang)) * 5.4, GOLD, 1.0)


static func _head(v: CharacterVisual, look: String, c: Vector2, r: float, s: float, skin: Color, hair: Color, robe: Color, robe2: Color, t: float, bob: float) -> void:
	# 뒤로 늘어지는 너울·두건 (얼굴보다 먼저)
	match look:
		"benedicta":
			_poly(v, PackedVector2Array([c + Vector2(-5 * s, -3 * s), c + Vector2(3 * s, -4 * s), c + Vector2(1 * s, 7 * s), c + Vector2(-7 * s, 8 * s)]), robe.lerp(Color.WHITE, 0.3))
		"monk", "pilgrim":
			_poly(v, PackedVector2Array([c + Vector2(-6.5 * s, -2 * s), c + Vector2(-2 * s, -7 * s), c + Vector2(4.5 * s, -6 * s), c + Vector2(6.5 * s, -1 * s), c + Vector2(5 * s, 6 * s), c + Vector2(-6 * s, 7 * s)]), robe if look == "monk" else robe.lightened(0.05))
	# 얼굴
	v.draw_circle(c, r + 1.0, OUTL)
	v.draw_circle(c, r, skin)
	v.draw_circle(c + Vector2(-r * 0.5, r * 0.2), r * 0.55, skin.darkened(0.08))
	var eye := c + Vector2(2.4 * s, 0.2 * s)
	var blink := v.blinking()
	match look:
		"monk":
			# 두건 그늘이 눈까지 덮음: 아래 얼굴만
			v.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r + 1, -r), c + Vector2(r + 1, 0.5 * s), c + Vector2(-r, 1.0 * s)]), robe.darkened(0.45))
			v.draw_rect(Rect2(eye.x, eye.y - 0.5, 1.5, 1), Color(1.0, 0.85, 0.5, 0.7))
			_poly(v, PackedVector2Array([c + Vector2(-6 * s, -2 * s), c + Vector2(-2 * s, -7 * s), c + Vector2(4.5 * s, -6.5 * s), c + Vector2(6.8 * s, -1 * s), c + Vector2(5.5 * s, -0.5 * s), c + Vector2(2 * s, -4.5 * s), c + Vector2(-3 * s, -3.5 * s)]), robe)
			v.draw_line(c + Vector2(-2 * s, -6.5 * s), c + Vector2(4 * s, -6 * s), robe2, 1.0)
		_:
			if blink:
				v.draw_line(eye, eye + Vector2(2, 0), Color("#2a1a20"), 1.0)
			else:
				v.draw_rect(Rect2(eye.x, eye.y - 0.5, 1.5, 2.5 if look == "luca" else 2.0), Color("#2a2030"))
				v.draw_rect(Rect2(eye.x, eye.y - 0.5, 1, 1), Color(1, 1, 1, 0.8))
	if v.talking and int(t * 10.0) % 2 == 0:
		v.draw_rect(Rect2(c.x + 2.5 * s, c.y + 3 * s, 2, 1), Color("#8a3a3a"))
	elif look == "choir" and fmod(t, 6.0) > 4.0:
		v.draw_circle(c + Vector2(3 * s, 3.2 * s), 1.0, Color("#8a3a3a"))
		var nk := fmod(t, 2.0) / 2.0
		v.draw_rect(Rect2(c.x + 6 * s + nk * 4.0, c.y - 4 * s - nk * 6.0, 2, 2), Color(1, 1, 1, 1.0 - nk))
	match look:
		"benedicta":
			# 높은 관 (해 문양) + 흰 머리
			v.draw_rect(Rect2(c.x - r, c.y - 2 * s, 2 * s, 4 * s), hair)
			_poly(v, PackedVector2Array([c + Vector2(-4.5 * s, -3.5 * s), c + Vector2(4.5 * s, -3.5 * s), c + Vector2(3.5 * s, -11 * s), c + Vector2(0, -13 * s), c + Vector2(-3.5 * s, -11 * s)]), robe.lerp(Color.WHITE, 0.4))
			v.draw_line(c + Vector2(-4.5 * s, -3.8 * s), c + Vector2(4.5 * s, -3.8 * s), GOLD, 1.5)
			v.draw_circle(c + Vector2(0, -8 * s), 1.8 * s, GOLD)
			v.draw_circle(c + Vector2(0, -8 * s), 0.8 * s, GOLD_L)
			v.draw_line(c + Vector2(1.5 * s, 2.2 * s), c + Vector2(3.5 * s, 2.0 * s), skin.darkened(0.25), 1.0)
		"luca":
			_poly(v, PackedVector2Array([c + Vector2(-5.8 * s, 1 * s), c + Vector2(-5 * s, -4.5 * s), c + Vector2(0, -6.5 * s), c + Vector2(5 * s, -4 * s), c + Vector2(5.5 * s, -1.5 * s), c + Vector2(2.5 * s, -2.8 * s), c + Vector2(1 * s, -1.2 * s), c + Vector2(-1.5 * s, -3 * s)]), hair)
			v.draw_rect(Rect2(c.x - 1 * s, c.y - 7.5 * s, 2, 2), hair)
			v.draw_rect(Rect2(c.x + 1.2 * s, c.y + 1.8 * s, 1, 1), Color(0.8, 0.45, 0.3, 0.6))
			v.draw_rect(Rect2(c.x + 3.6 * s, c.y + 1.6 * s, 1, 1), Color(0.8, 0.45, 0.3, 0.6))
		"gregor":
			# 대머리 + 옆머리·흰 수염·덥수룩한 눈썹, 귀에 손 (가끔)
			v.draw_arc(c, r * 0.9, PI * 1.2, PI * 1.5, 6, Color(1, 1, 1, 0.4), 1.0)
			v.draw_rect(Rect2(c.x - r, c.y - 1 * s, 2.5 * s, 4 * s), hair)
			_poly(v, PackedVector2Array([c + Vector2(-1 * s, 2 * s), c + Vector2(5.5 * s, 1.5 * s), c + Vector2(5 * s, 6 * s), c + Vector2(2 * s, 8.5 * s), c + Vector2(-1.5 * s, 5 * s)]), hair)
			v.draw_line(c + Vector2(1.2 * s, -1.4 * s), c + Vector2(4.5 * s, -1.0 * s), hair, 2.0)
			if fmod(t, 7.0) > 5.0:
				v.draw_circle(c + Vector2(-2.5 * s, 0), 1.6, skin.darkened(0.1))
				v.draw_line(c + Vector2(-2.5 * s, 0), c + Vector2(-1 * s, 6 * s), Color("#6a5040"), 2.0)
		"priest":
			v.draw_colored_polygon(PackedVector2Array([c + Vector2(-5.5 * s, 0.5 * s), c + Vector2(-5 * s, -4.5 * s), c + Vector2(1 * s, -6 * s), c + Vector2(5.2 * s, -3.5 * s), c + Vector2(5 * s, -1.5 * s), c + Vector2(1 * s, -3 * s), c + Vector2(-2 * s, -2.2 * s)]), hair)
			_poly(v, PackedVector2Array([c + Vector2(-3 * s, -5.5 * s), c + Vector2(3 * s, -6 * s), c + Vector2(2.5 * s, -7.5 * s), c + Vector2(-2.5 * s, -7.5 * s)]), robe2)
		"pilgrim":
			_poly(v, PackedVector2Array([c + Vector2(-6 * s, -1.5 * s), c + Vector2(-2 * s, -7 * s), c + Vector2(4.5 * s, -6.5 * s), c + Vector2(6.8 * s, -1 * s), c + Vector2(5.5 * s, -0.8 * s), c + Vector2(2 * s, -4.5 * s), c + Vector2(-3 * s, -3.5 * s)]), robe.lightened(0.05))
			v.draw_rect(Rect2(c.x - 2 * s, c.y + 3.5 * s, 7.5 * s, 2.5 * s), robe2)
		"choir":
			_poly(v, PackedVector2Array([c + Vector2(-6 * s, 3 * s), c + Vector2(-5.5 * s, -4.5 * s), c + Vector2(1 * s, -6.5 * s), c + Vector2(6 * s, -3.5 * s), c + Vector2(6 * s, 0.5 * s), c + Vector2(3.5 * s, -2.5 * s), c + Vector2(0, -2 * s), c + Vector2(-2 * s, -3 * s)]), hair)
