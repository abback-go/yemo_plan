extends "res://characters/special/astrid_palette.gd"
## 아스트리드 녹턴 교장 몸 그림 (docs/bible/characters.md 2절, chapter1.md 6절 "긴 은회색 머리, 별 장식 망토"). 키 38px.
## 1장부터 보이므로 1장 DB 색(로브 #20203a, 연보라 장식 #c8c0ff, 모자 #181830, 눈 #a0a0e8)을 그대로 쓴다.
## 늙었지만 꼿꼿하다: 가는 지팡이(은빛 초승달과 별)를 짚고, 허리까지 오는 곧은 은회색 머리, 별을 수놓은 긴 망토.
## 자세: idle · run(지팡이를 짚으며 걷기) · cast · attack · windup · shield/guard(별빛 결계) · hurt · kneel · down
##       special(예전의 세계관급 힘이 잠깐 — 머리가 솟고, 하늘을 셋으로 가르는 빛줄기, 젊은 날의 잔상)

const HAIR_SH := Color("#8e8ea6")
const HAIR_HI := Color("#e8e8f2")
const SKIN_SH := Color("#d4b8b4")
const ROBE := Color("#2a2850")
const CLOAK_SH := Color("#14142a")
const CLOAK_HI := Color("#34345a")
const HAT_HI := Color("#2c2c50")
const WOOD := Color("#3a2c30")
const SILVER := Color("#d8dcf0")
const STARLIGHT := Color("#e8e4ff")


static func _n(p: String) -> String:
	match p:
		"guard": return "shield"
		"aim": return "cast"
		"charge", "attack2": return "attack"
		"idle", "run", "cast", "attack", "windup", "shield", "hurt", "kneel", "down", "special":
			return p
	return "idle"


static func draw_body(v: CharacterVisual) -> void:
	var t := v.time()
	var pose := _n(v.pose if v.pose != "" else "idle")
	if v.walking and pose == "idle":
		pose = "run"
	var pk := v.pose_t
	if pose == "down":
		_draw_down(v, t)
		return
	var breathe := sin(t * 1.8) * 0.5
	var low := 0.0
	var lean := 0.0
	var staff_hand := Vector2(7, -17)
	var staff_top := Vector2(9, -44)
	var back_hand := Vector2(-4, -15)
	var glow := 0.0
	var lift := 0.0
	var eyes := "calm"
	var tilt := 0.0
	match pose:
		"run":
			var ph := v.walk_phase()
			breathe = -absf(sin(ph)) * 0.8
			staff_hand = Vector2(8 + sin(ph) * 1.5, -17)
			staff_top = staff_hand + Vector2(3, -28)
			back_hand = Vector2(-5 - sin(ph) * 1.5, -16)
			lean = 0.06
		"cast":
			staff_hand = Vector2(10, -22)
			staff_top = staff_hand + Vector2(14, -14)
			back_hand = Vector2(-6, -20)
			glow = 0.7
			eyes = "open"
		"attack":
			staff_hand = Vector2(11, -23)
			staff_top = staff_hand + Vector2(17, -6)
			back_hand = Vector2(-7, -22)
			glow = 1.0
			lean = 0.08
			eyes = "open"
		"windup":
			staff_hand = Vector2(4, -26)
			staff_top = staff_hand + Vector2(-6, -24)
			back_hand = Vector2(-6, -23)
			glow = clampf(pk / 0.8, 0.0, 1.0)
			lean = -0.08
			eyes = "open"
		"shield":
			staff_hand = Vector2(10, -19)
			staff_top = staff_hand + Vector2(2, -26)
			back_hand = Vector2(8, -24)
			glow = 0.8
			eyes = "open"
		"hurt":
			staff_hand = Vector2(9, -14)
			staff_top = staff_hand + Vector2(10, -24)
			back_hand = Vector2(-7, -24)
			lean = -0.25
			eyes = "shut"
			tilt = -0.2
		"kneel":
			low = 9.0
			staff_hand = Vector2(7, -18)
			staff_top = Vector2(8, -40)
			back_hand = Vector2(6, -13)
			lean = 0.16
			eyes = "down"
			tilt = 0.25
		"special":
			staff_hand = Vector2(6, -30)
			staff_top = staff_hand + Vector2(2, -30)
			back_hand = Vector2(-7, -28)
			glow = 1.0
			lift = 1.0
			eyes = "glow"
	var b := Vector2(0, low + breathe * 0.4)
	var hc := b + Vector2(1 + lean * 6.0, -32 + low * 0.1)

	# 등 뒤 은은한 빛 + 특수 자세의 오라
	v.draw_circle(b + Vector2(0, -20), 18.0, Color(TRIM, 0.05 + glow * 0.06))
	if pose == "special":
		_special_aura(v, b, hc, t, pk)
	# 바닥 그림자
	v.draw_colored_polygon(DrawKit.ellipse(Vector2(0, 0), 9.0, 1.8), Color(0.02, 0.02, 0.05, 0.3))

	# 뒷머리 (허리까지 곧게, 풍성하게)
	var hl := lift * 8.0
	var back := PackedVector2Array([
		hc + Vector2(-6.5, -3), hc + Vector2(3.5, -6.5), hc + Vector2(2.5, 4 - hl), hc + Vector2(0.5 + sin(t * 1.2) * 0.6, 19 - hl * 1.5),
		hc + Vector2(-4 + sin(t * 1.25) * 0.7, 21 - hl * 1.6), hc + Vector2(-9.5 + sin(t * 1.3) * 0.8 - hl, 19 - hl * 1.6), hc + Vector2(-9, 4 - hl * 0.5),
	])
	v.draw_colored_polygon(back, HAIR_SH)
	v.draw_line(hc + Vector2(-6, 0), hc + Vector2(-7 + sin(t * 1.3) * 0.6, 18 - hl * 1.5), HAIR, 1.0)
	v.draw_line(hc + Vector2(-2.5, 2), hc + Vector2(-2.0 + sin(t * 1.2) * 0.6, 19 - hl * 1.5), HAIR, 1.0)

	# 망토 (어깨에서 땅까지 넓게 퍼지는 A자, 뒤로 살짝 물결)
	var top_y := b.y - 25.0 + low * 0.2
	var hem_y := -0.5
	var wav := sin(t * 1.6) * 0.8
	var sx := b.x + lean * 4.0
	var kn := 5.0 if pose == "kneel" else 0.0
	var cloak := PackedVector2Array([
		Vector2(sx - 5.0, top_y), Vector2(sx + 5.0, top_y), Vector2(sx + 7.0, top_y + 6),
		Vector2(10.5 + kn, hem_y), Vector2(1, hem_y + 0.5), Vector2(-11.5 + wav - kn, hem_y), Vector2(sx - 7.0, top_y + 6),
	])
	v.draw_colored_polygon(cloak, CLOAK)
	# 뒤쪽 그림자 · 앞쪽 빛 (3단 명암)
	v.draw_colored_polygon(PackedVector2Array([cloak[0], Vector2(sx - 1.5, top_y + 1), Vector2(-4.5, hem_y), cloak[5], cloak[6]]), CLOAK_SH)
	v.draw_line(Vector2(sx + 6.0, top_y + 6), Vector2(9.5 + kn, hem_y), CLOAK_HI, 1.0)
	# 앞섶으로 보이는 로브 (연보라 안감 단)
	v.draw_colored_polygon(PackedVector2Array([Vector2(sx + 1.0, top_y + 4), Vector2(sx + 4.0, top_y + 3), Vector2(8.0 + kn * 0.6, hem_y), Vector2(1.5, hem_y)]), ROBE)
	v.draw_line(Vector2(sx + 1.0, top_y + 4), Vector2(1.5, hem_y), TRIM, 1.0)
	v.draw_line(Vector2(sx + 4.0, top_y + 3), Vector2(8.0 + kn * 0.6, hem_y), Color(TRIM, 0.5), 1.0)
	v.draw_line(cloak[3], cloak[5], Color(TRIM, 0.75), 1.0)
	# 망토의 별 수 (작은 은별 + 별자리 한 줄)
	var stars := [Vector2(-7, -6), Vector2(-4, -12), Vector2(-8, -17), Vector2(-3, -4), Vector2(-9, -11)]
	for i in stars.size():
		var sp: Vector2 = Vector2(b.x, 0) + (stars[i] as Vector2) * Vector2(1, (25.0 - low * 0.8) / 25.0)
		var tw := 0.55 + 0.45 * StArt.twinkle(t, i * 1.3, 0.9)
		StArt.star(v, sp + Vector2(0, low * 0.2), 1.3, Color(SILVER, tw), -PI * 0.5)
	v.draw_line(b + Vector2(-7, -6), b + Vector2(-4, -12), Color(SILVER, 0.35), 1.0)
	v.draw_line(b + Vector2(-4, -12), b + Vector2(-8, -17), Color(SILVER, 0.35), 1.0)
	# 높이 세운 깃 (연보라 테, 별 브로치)
	v.draw_colored_polygon(PackedVector2Array([Vector2(sx - 4.5, top_y + 1), Vector2(sx - 3.5, top_y - 3), Vector2(sx - 1.0, top_y - 1), Vector2(sx + 1.0, top_y + 1)]), CLOAK_HI)
	v.draw_line(Vector2(sx - 3.5, top_y - 3), Vector2(sx - 1.0, top_y - 1), TRIM, 1.0)
	v.draw_line(Vector2(sx - 5, top_y), Vector2(sx + 5, top_y), TRIM, 1.0)
	StArt.star(v, Vector2(sx + 2.5, top_y + 1.5), 1.8, STARLIGHT, -PI * 0.5)

	# 뒷팔
	_arm(v, Vector2(b.x - 3 + lean * 4.0, top_y + 1), b + back_hand, true)
	# 얼굴·머리
	_head(v, hc, t, eyes, v.blinking(), v.talking, tilt)
	# 모자
	_hat(v, hc, t, tilt + lean * -0.3)
	# 지팡이 (앞손)
	_staff(v, b + staff_hand, b + staff_top, t, glow, pose)
	_arm(v, Vector2(b.x + 3 + lean * 4.0, top_y + 1), b + staff_hand, false)
	if pose == "shield":
		_barrier(v, b + Vector2(16, -18), t, pk)
	if pose == "cast" or pose == "attack":
		var tip := b + staff_top
		var k := 1.0 if pose == "attack" else 0.6 + 0.4 * sin(t * 6.0)
		v.draw_circle(tip, 4.0 + 3.0 * k, Color(STARLIGHT, 0.2 * k))
		StArt.sparkle(v, tip, 4.0 + 2.0 * k, STARLIGHT, k)


static func _arm(v: CanvasItem, sh: Vector2, hand: Vector2, back: bool) -> void:
	var col := CLOAK_SH if back else CLOAK_HI
	var mid := sh.lerp(hand, 0.5) + Vector2(0, 1)
	v.draw_line(sh, mid, col, 2.4)
	var d := (hand - mid).normalized()
	var n := d.orthogonal()
	v.draw_colored_polygon(PackedVector2Array([mid + n * 1.2, hand - d * 1.0 + n * 2.4, hand - d * 1.0 - n * 2.4, mid - n * 1.2]), col)
	v.draw_line(hand - d * 1.0 + n * 2.4, hand - d * 1.0 - n * 2.4, Color(TRIM, 0.6 if back else 0.9), 1.0)
	v.draw_circle(hand, 1.3, SKIN_SH if back else SKIN)


static func _head(v: CanvasItem, hc: Vector2, t: float, eyes: String, blink: bool, talking: bool, tilt: float) -> void:
	v.draw_rect(Rect2(hc.x - 1.5, hc.y + 5, 3, 3), SKIN_SH)
	var face := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var px := cos(a) * 5.8
		if sin(a) > 0.3 and cos(a) > 0.0:
			px *= 0.9
		face.append(hc + Vector2(px, sin(a) * (5.6 if sin(a) < 0 else 6.2)))
	v.draw_colored_polygon(face, SKIN)
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-5.8, -1), hc + Vector2(-4.2, -3), hc + Vector2(-3.8, 4), hc + Vector2(-5.0, 3)]), SKIN_SH)
	var ep := hc + Vector2(3.0, 0.6)
	match eyes:
		"shut":
			v.draw_line(ep + Vector2(-1.4, 0), ep + Vector2(1.8, 0.6), LASH, 1.0)
		"down":
			v.draw_line(ep + Vector2(-1.4, 0.8), ep + Vector2(1.8, 1.0), LASH, 1.0)
		"glow":
			v.draw_rect(Rect2(ep + Vector2(-1, -1), Vector2(2.5, 2)), STARLIGHT)
			v.draw_circle(ep, 3.0, Color(STARLIGHT, 0.25 + 0.1 * sin(t * 8.0)))
		_:
			if blink:
				v.draw_line(ep + Vector2(-1.4, 0.4), ep + Vector2(1.8, 0.6), LASH, 1.0)
			else:
				# 차분히 내리깐 눈: 위 눈꺼풀이 눈동자를 반쯤 덮는다
				var h := 2.0 if eyes == "calm" else 2.6
				v.draw_rect(Rect2(ep + Vector2(-0.6, -0.6), Vector2(2.2, h)), EYE)
				v.draw_rect(Rect2(ep + Vector2(0.4, -0.2), Vector2(1, 1)), Color(1, 1, 1, 0.8))
				v.draw_line(ep + Vector2(-1.4, -0.8), ep + Vector2(2.2, -0.8), LASH, 1.0)
	# 세월의 선 (눈 밑 한 줄)
	v.draw_line(ep + Vector2(-0.8, 2.6), ep + Vector2(1.4, 2.8), SKIN_SH.darkened(0.12), 1.0)
	v.draw_line(hc + Vector2(1.8, -3.0), hc + Vector2(4.6, -2.8), HAIR_SH, 1.0)
	var m := hc + Vector2(2.0, 4.0)
	if talking and int(t * 10.0) % 2 == 0:
		v.draw_rect(Rect2(m + Vector2(-0.5, -0.5), Vector2(1.5, 1.5)), Color("#9a5a5a"))
	else:
		v.draw_rect(Rect2(m + Vector2(-0.5, 0), Vector2(2, 1)), Color("#b88080"))
	# 앞머리 (가운데 가르마) + 옆머리
	var bangs := PackedVector2Array([
		hc + Vector2(-6.2, 0), hc + Vector2(-5.2, -5), hc + Vector2(0, -6.6), hc + Vector2(5, -5),
		hc + Vector2(6.2, -1), hc + Vector2(4.5, -3.5), hc + Vector2(0.8, -4.6), hc + Vector2(-2.0, -3.2), hc + Vector2(-4.0, -1.0),
	])
	v.draw_colored_polygon(bangs, HAIR)
	v.draw_line(hc + Vector2(-4, -4.5), hc + Vector2(-0.5, -6), HAIR_HI, 1.0)
	var lock := PackedVector2Array([hc + Vector2(4.8, -3), hc + Vector2(6.4, -1), hc + Vector2(6.0 + sin(t * 1.4) * 0.4, 9), hc + Vector2(4.6, 9.5), hc + Vector2(5.0, 1)])
	v.draw_colored_polygon(lock, HAIR)
	v.draw_line(hc + Vector2(5.4, 0), hc + Vector2(5.4, 8), HAIR_SH, 1.0)


static func _hat(v: CanvasItem, hc: Vector2, t: float, tilt: float) -> void:
	var bc := hc + Vector2(-0.5, -5.0)
	var brim := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		brim.append(bc + Vector2(cos(a) * 12.0, sin(a) * (2.2 if sin(a) > 0 else 1.6)).rotated(tilt))
	v.draw_colored_polygon(brim, HAT)
	v.draw_line(bc + Vector2(-12, 0).rotated(tilt), bc + Vector2(12, 0).rotated(tilt), HAT_HI, 1.0)
	# 높고 곧은 고깔, 끝만 살짝 뒤로 꺾임
	var bend := sin(t * 1.1) * 0.6
	var cone := PackedVector2Array([
		bc + Vector2(-5, -0.5).rotated(tilt), bc + Vector2(5, -0.5).rotated(tilt), bc + Vector2(2, -12).rotated(tilt),
		bc + Vector2(-0.5 + bend, -19).rotated(tilt), bc + Vector2(-5 + bend, -21).rotated(tilt), bc + Vector2(-1.5 + bend * 0.5, -17).rotated(tilt),
		bc + Vector2(-2.5, -11).rotated(tilt),
	])
	v.draw_colored_polygon(cone, HAT)
	v.draw_line(bc + Vector2(-2.5, -11).rotated(tilt), bc + Vector2(-5, -0.5).rotated(tilt), Color(0.04, 0.04, 0.1), 1.0)
	v.draw_line(bc + Vector2(-4.6, -2).rotated(tilt), bc + Vector2(4.6, -2).rotated(tilt), TRIM, 2.0)
	StArt.star(v, bc + Vector2(2.6, -2.2).rotated(tilt), 1.6, SILVER, -PI * 0.5)
	# 모자 둘레를 도는 작은 별 셋 (1장 그림과 같은 표식)
	for i in 3:
		var a := t * 0.8 + TAU * i / 3.0
		var p := hc + Vector2(cos(a) * 11.0, -9.0 + sin(a) * 3.0)
		v.draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2.ONE), Color(0.9, 0.9, 1.0, 0.75))


## 지팡이: 짙은 나무 + 은빛 초승달 + 그 안의 별
static func _staff(v: CanvasItem, hand: Vector2, top: Vector2, t: float, glow: float, pose: String) -> void:
	var d := (top - hand).normalized()
	var bottom := hand - d * (16.0 if pose != "kneel" else 18.0)
	if pose in ["idle", "run", "kneel", "shield", "hurt"]:
		bottom = Vector2(hand.x + d.x * -16.0, minf(0.0, hand.y + 18.0))
	v.draw_line(bottom, top, WOOD, 2.0)
	v.draw_line(bottom + Vector2(0.5, 0), top + Vector2(0.5, 0), WOOD.lightened(0.15), 1.0)
	# 초승달 머리
	var c := top + d * 3.0
	v.draw_arc(c, 4.0, d.angle() + PI * 0.65, d.angle() + PI * 2.35, 12, SILVER, 1.6)
	var sc := c + d * 0.6
	v.draw_circle(sc, 2.5 + glow * 2.5, Color(STARLIGHT, 0.12 + glow * 0.25))
	StArt.star(v, sc, 1.7 + glow * 0.6, STARLIGHT, -PI * 0.5 + t * (0.5 + glow * 3.0))


## 별빛 결계 (육각 별무늬 판, 앞쪽)
static func _barrier(v: CanvasItem, c: Vector2, t: float, pk: float) -> void:
	var k := clampf(pk / 0.2, 0.0, 1.0)
	var hexp := PackedVector2Array()
	for i in 7:
		var a := TAU * i / 6.0 + PI / 6.0
		hexp.append(c + Vector2(cos(a) * 6.0 * k, sin(a) * 20.0 * k))
	v.draw_colored_polygon(hexp, Color(STARLIGHT, 0.16))
	v.draw_polyline(hexp, Color(STARLIGHT, 0.85), 1.0)
	for i in 3:
		var y := -12.0 + i * 12.0
		StArt.star(v, c + Vector2(0, y * k), 2.0, Color(STARLIGHT, 0.8), -PI * 0.5 + t)
	v.draw_line(c + Vector2(0, -18 * k), c + Vector2(0, 18 * k), Color(STARLIGHT, 0.3 + 0.2 * sin(t * 6.0)), 1.0)


## 예전의 힘: 머리가 솟고, 하늘을 셋으로 가르는 빛줄기 + 젊은 날의 잔상
static func _special_aura(v: CanvasItem, b: Vector2, hc: Vector2, t: float, pk: float) -> void:
	var k := clampf(pk / 0.5, 0.0, 1.0)
	v.draw_circle(b + Vector2(0, -22), 26.0 * k, Color(STARLIGHT, 0.08))
	for i in 3:
		var a := -PI * 0.5 + (i - 1) * 0.55
		var from := hc + Vector2(0, -20)
		var to := from + Vector2(cos(a), sin(a)) * 140.0 * k
		v.draw_line(from, to, Color(STARLIGHT, 0.18), 6.0)
		v.draw_line(from, to, Color(STARLIGHT, 0.7), 1.0)
	# 젊은 날의 잔상 (검은 머리 실루엣이 겹쳐 흔들림)
	var off := Vector2(-3 + sin(t * 3.0), -1)
	v.draw_colored_polygon(PackedVector2Array([hc + off + Vector2(-6, -4), hc + off + Vector2(4, -6), hc + off + Vector2(2, 18), hc + off + Vector2(-8, 18)]), Color(0.15, 0.15, 0.3, 0.25 * k))


static func _draw_down(v: CanvasItem, t: float) -> void:
	var g := Vector2(0, -1)
	# 바닥에 퍼진 머리
	v.draw_colored_polygon(PackedVector2Array([g + Vector2(-20, -3), g + Vector2(-12, -6), g + Vector2(-8, -1), g + Vector2(-18, 1)]), HAIR_SH)
	# 망토
	v.draw_colored_polygon(PackedVector2Array([g + Vector2(-9, -6), g + Vector2(13, -5), g + Vector2(14, 0), g + Vector2(-9, 0)]), CLOAK)
	v.draw_line(g + Vector2(-9, -6), g + Vector2(13, -5), TRIM, 1.0)
	for i in 3:
		StArt.star(v, g + Vector2(-3 + i * 5, -3), 1.1, Color(SILVER, 0.6), -PI * 0.5)
	# 머리
	var hc := g + Vector2(-13, -4)
	v.draw_circle(hc, 5.0, SKIN)
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-5, -2), hc + Vector2(2, -5), hc + Vector2(4, -2), hc + Vector2(-3, 1)]), HAIR)
	v.draw_line(hc + Vector2(0, 0), hc + Vector2(2, 0.5), LASH, 1.0)
	# 굴러간 모자·지팡이
	v.draw_colored_polygon(PackedVector2Array([g + Vector2(17, 0), g + Vector2(27, 0), g + Vector2(24, -4), g + Vector2(20, -12)]), HAT)
	v.draw_line(g + Vector2(-4, 1), g + Vector2(26, -1), WOOD, 2.0)
	v.draw_arc(g + Vector2(28, -2), 3.0, 0.5, 5.5, 8, SILVER, 1.0)
	StArt.star(v, g + Vector2(28, -2), 1.2, Color(STARLIGHT, 0.4 + 0.3 * sin(t * 2.0)), 0.0)
