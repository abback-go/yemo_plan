extends "res://characters/special/lyra_palette.gd"
## 리라 — 별의 마녀 몸 그림 (docs/bible/characters.md 3절 5장, art.md 3절). 키 40px, 늘 떠 있다(발밑에서 약 5px).
## 바닥까지 끌리는 은백색 머리(별가루가 반짝), 보랏빛 눈(눈동자에 작은 별), 별자리 금실 자수의 깊은 남색 드레스 로브,
## 끝이 초승달처럼 말려 별이 매달린 거대한 모자, 몸 둘레를 도는 작은 별 7개. 3단 명암, 머리카락 물리(움직이면 뒤로 흩날림).
##
## 자세(v.pose): idle · run · cast · attack · windup · special · guard · hurt · kneel · down · possessed
##   흉내(별빛 무기): sword · sword_windup(일섬 칼집 자세) · sword_attack / bow · bow_draw · bow_release / spear · spear_windup · spear_charge
##   그 밖: charge → spear_charge, aim → bow_draw, attack2 → sword_attack. 모르는 자세는 idle.
## 원점은 발밑(바닥), +x가 바라보는 쪽. 부모가 좌우를 뒤집는다.

## 그릴 때 meta에 스프링 상태를 쌓는다 → 화면 밖에서도 매 프레임 그려야 다시 보일 때 같은 모습 (CharacterVisual)
const KEEP_DRAWING := true
const HAIR := Color("#e7eaf8")
const HAIR_SH := Color("#aeb3da")
const HAIR_DEEP := Color("#7c82b8")
const SKIN := Color("#f8e8e2")
const SKIN_SH := Color("#e4c6c8")
const EYE := Color("#a070e8")
const EYE_DEEP := Color("#5a3a9a")
const LASH := Color("#2a2040")
const ROBE_SH := Color("#0f1338")
const LINING := Color("#5a3490")
const CAPE := Color("#141842")
const HAT := Color("#181c4a")
const HAT_HI := Color("#323e8c")
const GOLD_SH := Color("#a88a4a")

## 드레스 자수 별자리 (치마 안의 u 0~1 가로, v 0~1 세로)
const EMB := [Vector2(0.25, 0.22), Vector2(0.45, 0.38), Vector2(0.35, 0.62), Vector2(0.62, 0.55), Vector2(0.78, 0.8), Vector2(0.55, 0.9)]
const EMB2 := [Vector2(0.7, 0.18), Vector2(0.82, 0.32), Vector2(0.68, 0.42)]


static func _n(p: String) -> String:
	match p:
		"charge": return "spear_charge"
		"aim": return "bow_draw"
		"attack2": return "sword_attack"
		"idle", "run", "cast", "attack", "windup", "special", "guard", "hurt", "kneel", "down", "possessed", \
		"sword", "sword_windup", "sword_attack", "bow", "bow_draw", "bow_release", "spear", "spear_windup", "spear_charge":
			return p
	return "idle"


## 자세별 목표 값 (몸 높이·기울기·두 손·머리 날림·모자 기울기·빛)
static func _target(pose: String, pk: float, t: float, walking: bool) -> Dictionary:
	var d := {
		"float": 5.0 + sin(t * 1.6) * 1.5, "lean": 0.0, "hf": Vector2(6, -19), "hb": Vector2(-5, -17),
		"lift": 0.0, "tilt": -0.06, "glow": 0.0, "head": Vector2.ZERO, "eyes": "normal", "low": 0.0,
	}
	match pose:
		"run":
			d.lean = 0.16
			d.hf = Vector2(4, -17)
			d.hb = Vector2(-7, -18)
			d.tilt = -0.18
		"cast":
			d.hf = Vector2(13, -25)
			d.hb = Vector2(-6, -20)
			d.glow = 0.6
			d.lean = -0.04
		"attack":
			d.hf = Vector2(14, -23)
			d.hb = Vector2(10, -26)
			d.glow = 1.0
			d.lean = 0.08
		"windup":
			d.hf = Vector2(-5, -31)
			d.hb = Vector2(-9, -24)
			d.lift = 0.45
			d.glow = 0.7
			d.lean = -0.12
			d.tilt = -0.15
		"special":
			d.hf = Vector2(6, -42)
			d.hb = Vector2(-5, -41)
			d.lift = 1.0
			d.glow = 1.0
			d.float = 9.0 + sin(t * 2.0) * 1.0
			d.tilt = -0.12
			d.eyes = "closed" if fmod(pk, 2.0) < 1.0 else "normal"
		"guard":
			d.hf = Vector2(11, -27)
			d.hb = Vector2(-3, -22)
			d.glow = 0.5
		"hurt":
			d.hf = Vector2(-4, -22)
			d.hb = Vector2(-10, -27)
			d.lean = -0.28
			d.tilt = -0.3
			d.eyes = "closed"
			d.head = Vector2(-1, 0)
		"kneel":
			d.float = 0.0
			d.low = 7.0
			d.hf = Vector2(9, -8)
			d.hb = Vector2(-2, -15)
			d.lean = 0.12
			d.tilt = 0.18
			d.head = Vector2(1, 1)
			d.eyes = "down"
		"down":
			d.float = 0.0
			d.eyes = "closed"
		"possessed":
			d.float = 11.0 + sin(t * 0.8) * 0.8
			d.hf = Vector2(14, -31)
			d.hb = Vector2(-13, -31)
			d.lift = 0.85
			d.lean = -0.1
			d.tilt = -0.25
			d.head = Vector2(-1, -1)
			d.eyes = "white"
		"sword":
			d.hf = Vector2(8, -18)
			d.hb = Vector2(-5, -19)
			d.lean = 0.06
		"sword_windup":
			d.float = 3.0
			d.low = 2.0
			d.hf = Vector2(-1, -17)
			d.hb = Vector2(-5, -17)
			d.lean = 0.2
			d.lift = 0.25
			d.glow = clampf(pk / 1.2, 0.0, 1.0)
			d.tilt = -0.2
			d.eyes = "closed" if pk < 0.8 else "sharp"
		"sword_attack":
			d.hf = Vector2(15, -24)
			d.hb = Vector2(-8, -21)
			d.lean = 0.24
			d.tilt = -0.25
			d.eyes = "sharp"
		"bow":
			d.hf = Vector2(12, -24)
			d.hb = Vector2(7, -24)
		"bow_draw":
			d.hf = Vector2(13, -25)
			d.hb = Vector2(-2, -25)
			d.lean = -0.05
			d.glow = 0.5
			d.eyes = "sharp"
		"bow_release":
			d.hf = Vector2(13, -25)
			d.hb = Vector2(-7, -28)
			d.lean = -0.08
		"spear":
			d.hf = Vector2(8, -22)
			d.hb = Vector2(-4, -18)
		"spear_windup":
			d.hf = Vector2(-1, -23)
			d.hb = Vector2(-8, -22)
			d.lean = -0.2
			d.low = 2.0
			d.glow = clampf(pk / 0.9, 0.0, 1.0)
			d.eyes = "sharp"
		"spear_charge":
			d.hf = Vector2(12, -22)
			d.hb = Vector2(5, -22)
			d.lean = 0.32
			d.tilt = -0.35
			d.glow = 0.8
			d.eyes = "sharp"
	if walking and pose == "idle":
		d.lean = 0.12
		d.tilt = -0.14
	return d


## 매 프레임 상태 (메타에 저장): 부드러운 손 위치, 속도(머리카락 물리)
static func _state(v: CharacterVisual, tg: Dictionary) -> Dictionary:
	var now := v.time()
	var st: Dictionary = v.get_meta("ly_st") if v.has_meta("ly_st") else {}
	var dt := clampf(now - float(st.get("t", now)), 0.0, 0.1)
	var gp := v.global_position
	var flip := signf(v.global_transform.x.x)
	if flip == 0.0:
		flip = 1.0
	var vel: Vector2 = st.get("vel", Vector2.ZERO)
	if st.has("gp") and dt > 0.0:
		var raw := (gp - (st.gp as Vector2)) / dt
		raw.x *= flip
		vel = vel.lerp(raw.limit_length(600.0), minf(dt * 6.0, 1.0))
	var k := minf(dt * 16.0, 1.0)
	var hf: Vector2 = (st.get("hf", tg.hf) as Vector2).lerp(tg.hf, k)
	var hb: Vector2 = (st.get("hb", tg.hb) as Vector2).lerp(tg.hb, k)
	var lean := lerpf(float(st.get("lean", tg.lean)), tg.lean, k)
	var lift := lerpf(float(st.get("lift", tg.lift)), tg.lift, minf(dt * 5.0, 1.0))
	var fl := lerpf(float(st.get("float", tg.float)), tg.float, minf(dt * 8.0, 1.0))
	var low := lerpf(float(st.get("low", tg.low)), tg.low, k)
	var tilt := lerpf(float(st.get("tilt", tg.tilt)), tg.tilt, minf(dt * 10.0, 1.0))
	var glow := lerpf(float(st.get("glow", tg.glow)), tg.glow, minf(dt * 8.0, 1.0))
	st = {"t": now, "gp": gp, "vel": vel, "hf": hf, "hb": hb, "lean": lean, "lift": lift, "float": fl, "low": low, "tilt": tilt, "glow": glow}
	v.set_meta("ly_st", st)
	return st


static func draw_body(v: CharacterVisual) -> void:
	var t := v.time()
	var pose := _n(v.pose if v.pose != "" else ("run" if v.walking else "idle"))
	if v.walking and pose == "idle":
		pose = "run"
	var pk := v.pose_t
	var tg := _target(pose, pk, t, v.walking)
	var st := _state(v, tg)
	if pose == "down":
		_draw_down(v, t, st)
		return
	var poss := 1.0 if pose == "possessed" else 0.0
	var fl: float = st.float
	var low: float = st.low
	var vel: Vector2 = st.vel
	var b := Vector2(0, -fl + low)
	var trail := clampf(-vel.x * 0.035, -9.0, 9.0) + float(st.lean) * -10.0 ## 머리·옷자락이 뒤로 끌리는 양
	var rise := clampf(vel.y * 0.02, -4.0, 4.0)

	# 바닥 그림자 (떠 있을수록 옅고 작게)
	var sh_a := 0.32 - fl * 0.015
	v.draw_colored_polygon(DrawKit.ellipse(Vector2(0, 0), 11.0 - fl * 0.3, 2.2, 12), Color(0.02, 0.02, 0.06, maxf(sh_a, 0.08)))
	if fl > 1.0:
		v.draw_colored_polygon(DrawKit.ellipse(Vector2(0, 0), 6.0, 1.2, 10), Color(STAR, 0.08 + 0.04 * sin(t * 2.0)))

	# 뒤의 빛 (별빛 기운 / 빙의된 흰 기하학 광륜)
	var glow: float = st.glow
	if poss > 0.0:
		_possessed_halo(v, b + Vector2(-1, -30), t)
	elif glow > 0.02:
		v.draw_circle(b + Vector2(0, -24), 20.0 + glow * 6.0, Color(STAR, 0.05 * glow))
		v.draw_circle(b + Vector2(0, -24), 12.0 + glow * 4.0, Color(STAR, 0.06 * glow))
	# 창 흉내의 광륜 (아우렐리아식)
	if pose.begins_with("spear"):
		_star_halo(v, b + Vector2(-5, -30), t, 1.0)

	# 뒤쪽 별 (몸 뒤로 도는 것)
	_orbit_stars(v, b, t, false, poss, glow)

	var lean: float = st.lean
	var lift: float = st.lift
	# 머리카락 뒤 덩어리 (바닥까지)
	var head_off: Vector2 = tg.head
	var hc: Vector2 = b + Vector2(1, -33 + low * 0.2) + head_off + Vector2(lean * 6.0, absf(lean) * 2.0)
	_hair_back(v, hc, b, t, trail, rise, lift, poss)

	# 뒷팔 (소매)
	var hf: Vector2 = st.hf
	var hb: Vector2 = st.hb
	var sb := b + Vector2(-3 + lean * 5.0, -26)
	var sf := b + Vector2(3 + lean * 6.0, -26.5)
	_arm(v, sb, b + hb, true, poss)
	if pose.begins_with("bow"):
		_bow(v, b + hf, b + hb, pose, pk, t)

	# 드레스
	_dress(v, b, t, trail, lean, low, pose, poss)
	# 몸통·망토(어깨 케이프)
	_torso(v, b, lean, t, poss)
	# 머리
	_head(v, hc, t, tg.eyes, v.blinking(), v.talking, poss, pose)
	_hair_front(v, hc, t, trail, lift, poss)
	# 모자
	_hat(v, hc, t, float(st.tilt) + trail * -0.01, trail, poss, pose)
	# 무기 (손 뒤에 그려야 하는 창·검)
	if pose.begins_with("sword"):
		_sword(v, b + hf, b, pose, pk, t)
	if pose.begins_with("spear"):
		_spear(v, b + hf, b + hb, pose, pk, t)
	# 앞팔
	_arm(v, sf, b + hf, false, poss)
	# 손의 별빛
	_hand_magic(v, b + hf, b + hb, pose, pk, t, glow)
	# 앞쪽 별
	_orbit_stars(v, b, t, true, poss, glow)
	if poss > 0.0:
		_cracks(v, b, hc, t)


# ─── 도우미 ─────────────────────────────────────────────

static func _strip(v: CanvasItem, pts: Array, widths: Array, col: Color) -> void:
	## 가운데 선과 굵기로 띠 다각형 (머리카락 가닥·모자 고깔)
	if pts.size() < 2:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in pts.size():
		var p: Vector2 = pts[i]
		var d: Vector2
		if i == 0:
			d = (pts[1] as Vector2) - p
		elif i == pts.size() - 1:
			d = p - (pts[i - 1] as Vector2)
		else:
			d = (pts[i + 1] as Vector2) - (pts[i - 1] as Vector2)
		var n := d.orthogonal().normalized()
		var w: float = widths[i]
		left.append(p + n * w)
		right.append(p - n * w)
	right.reverse()
	left.append_array(right)
	v.draw_colored_polygon(left, col)


# ─── 머리카락 ───────────────────────────────────────────

static func _hair_back(v: CanvasItem, hc: Vector2, b: Vector2, t: float, trail: float, rise: float, lift: float, poss: float) -> void:
	var n := 12
	var end_y := -0.5 # 바닥에 닿을락 말락
	var main: Array = []
	var wid: Array = []
	for i in n + 1:
		var u := float(i) / n
		var y := lerpf(hc.y - 3.0, end_y + 1.0, u) - lift * u * u * 14.0 - rise * u * u
		var x := hc.x - 3.0 - u * 6.0 + sin(t * 1.4 + u * 3.2) * u * 2.2 + trail * u * u * 1.3 - lift * u * u * 6.0
		main.append(Vector2(x, y))
		wid.append(4.0 + sin(u * PI) * 3.5 - u * 1.5)
	var deep := HAIR_DEEP.lerp(WHITE_GOD, poss * 0.5)
	var base := HAIR_SH.lerp(WHITE_GOD, poss * 0.4)
	var top := HAIR.lerp(WHITE_GOD, poss * 0.3)
	# 가장 뒤 그림자 덩어리 → 바탕 → 밝은 결
	var back: Array = []
	for p in main:
		back.append((p as Vector2) + Vector2(-2.5, 1.0))
	_strip(v, back, wid, deep)
	_strip(v, main, wid, base)
	var hi_w: Array = []
	for w in wid:
		hi_w.append(float(w) * 0.45)
	var hi: Array = []
	for p in main:
		hi.append((p as Vector2) + Vector2(1.2, 0))
	_strip(v, hi, hi_w, top)
	# 따로 흔들리는 가닥 둘 (끝이 더 휘날림)
	for s in 2:
		var pts: Array = []
		var ws: Array = []
		for i in 9:
			var u := float(i) / 8.0
			var y := lerpf(hc.y + 2.0 + s * 3.0, end_y - 2.0 - s * 4.0, u) - lift * u * u * 10.0
			var x := hc.x - 5.0 - s * 2.0 - u * (7.0 + s * 2.0) + sin(t * (1.9 + s * 0.4) + u * 4.0 + s) * u * 3.0 + trail * u * u * (1.6 + s * 0.3) - lift * u * 8.0
			pts.append(Vector2(x, y))
			ws.append(1.6 - u * 1.0)
		_strip(v, pts, ws, base.lerp(top, 0.3 + s * 0.2))
	# 별가루 반짝임 (머리카락을 따라)
	for i in 7:
		var u := 0.18 + i * 0.12
		var idx := mini(int(u * n), n)
		var p: Vector2 = main[idx] + Vector2(sin(i * 2.3) * 2.0, 0)
		var tw := StArt.twinkle(t, i * 1.7, 1.6)
		if poss > 0.0:
			tw *= 0.3
		if tw > 0.55:
			StArt.sparkle(v, p, 2.0 + (tw - 0.55) * 4.0, STAR, (tw - 0.55) * 2.2)
		else:
			v.draw_rect(Rect2(p, Vector2.ONE), Color(STAR, 0.5 * tw))


static func _hair_front(v: CanvasItem, hc: Vector2, t: float, trail: float, lift: float, poss: float) -> void:
	var base := HAIR.lerp(WHITE_GOD, poss * 0.3)
	var sh := HAIR_SH.lerp(WHITE_GOD, poss * 0.3)
	# 앞머리 (이마를 비스듬히 덮음)
	var bangs := PackedVector2Array([
		hc + Vector2(-6.5, -1), hc + Vector2(-5.5, -5.5), hc + Vector2(-1, -7.2), hc + Vector2(4.5, -5.8),
		hc + Vector2(6.8, -2.0), hc + Vector2(6.2, 1.2), hc + Vector2(4.6, -1.6), hc + Vector2(2.2, 0.2),
		hc + Vector2(1.0, -2.2), hc + Vector2(-1.8, 0.6), hc + Vector2(-3.2, -2.0),
	])
	v.draw_colored_polygon(bangs, base)
	v.draw_line(hc + Vector2(-4.5, -5.0), hc + Vector2(2.0, -6.4), HAIR_HI, 1.0)
	v.draw_line(hc + Vector2(1.0, -2.2), hc + Vector2(3.5, -5.0), sh, 1.0)
	# 얼굴 옆으로 흘러내리는 옆머리 (가슴까지, 끝이 살짝 말림)
	var pts: Array = []
	var ws: Array = []
	for i in 8:
		var u := float(i) / 7.0
		var x := hc.x + 5.5 + sin(t * 1.7 + u * 3.0) * u * 1.2 + trail * u * 0.25 - lift * u * 3.0
		var y := hc.y - 2.0 + u * 14.0 - lift * u * 5.0
		pts.append(Vector2(x - u * u * 1.5, y))
		ws.append(1.5 - u * 0.6)
	_strip(v, pts, ws, base)
	v.draw_line(pts[1], pts[5], HAIR_HI, 1.0)
	# 뒤쪽 옆머리 (머리 뒤에서 어깨로)
	var pts2: Array = []
	var ws2: Array = []
	for i in 7:
		var u := float(i) / 6.0
		pts2.append(Vector2(hc.x - 6.0 - u * 1.5 + sin(t * 1.5 + u * 3.0) * u, hc.y - 1.0 + u * 12.0 - lift * u * 4.0))
		ws2.append(1.8 - u * 0.8)
	_strip(v, pts2, ws2, sh)


# ─── 얼굴 ───────────────────────────────────────────────

static func _head(v: CanvasItem, hc: Vector2, t: float, eyes: String, blink: bool, talking: bool, poss: float, pose: String) -> void:
	var skin := SKIN.lerp(Color("#eef0fa"), poss * 0.6)
	# 목
	v.draw_rect(Rect2(hc.x - 1.5, hc.y + 5.0, 3, 3), SKIN_SH)
	# 얼굴 (턱이 살짝 갸름)
	var face := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var rx := 6.2
		var ry := 6.0 if sin(a) < 0 else 6.6
		var px := cos(a) * rx
		if sin(a) > 0.3 and cos(a) > 0.0:
			px *= 0.92
		face.append(hc + Vector2(px, sin(a) * ry))
	v.draw_colored_polygon(face, skin)
	# 뒤쪽 볼 그림자
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-6.2, -1), hc + Vector2(-4.5, -3), hc + Vector2(-4.0, 4), hc + Vector2(-5.5, 3)]), SKIN_SH)
	# 볼 홍조
	if poss <= 0.0:
		v.draw_rect(Rect2(hc + Vector2(1.5, 2.8), Vector2(3, 1)), Color(1.0, 0.55, 0.65, 0.45))
	# 눈 (가까운 눈 크게, 먼 눈은 살짝)
	var ep := hc + Vector2(3.4, 0.4)
	var fe := hc + Vector2(-1.2, 0.4)
	match eyes:
		"white":
			for p in [ep, fe]:
				var pv: Vector2 = p
				v.draw_rect(Rect2(pv + Vector2(-1, -1.5), Vector2(2.5 if pv == ep else 1.2, 3)), WHITE_GOD)
				v.draw_circle(pv, 3.0, Color(1, 1, 1, 0.18 + 0.1 * sin(t * 6.0)))
			v.draw_line(ep + Vector2(-1.5, -2.6), ep + Vector2(2.0, -2.2), LASH, 1.0)
		"closed", "down":
			var dy := 0.6 if eyes == "down" else 0.0
			v.draw_line(ep + Vector2(-1.4, dy), ep + Vector2(1.8, dy + 0.4), LASH, 1.0)
			v.draw_line(ep + Vector2(1.8, dy + 0.4), ep + Vector2(2.6, dy - 0.4), LASH, 1.0)
			v.draw_line(fe + Vector2(-0.6, dy), fe + Vector2(0.8, dy + 0.3), LASH, 1.0)
		_:
			if blink:
				v.draw_line(ep + Vector2(-1.4, 0.5), ep + Vector2(1.8, 0.8), LASH, 1.0)
				v.draw_line(fe + Vector2(-0.6, 0.5), fe + Vector2(0.8, 0.7), LASH, 1.0)
			else:
				var sharp := eyes == "sharp"
				var eh := 2.4 if sharp else 3.2
				# 가까운 눈: 흰자 1px + 보라 눈동자 + 별 동공 + 위 속눈썹
				v.draw_rect(Rect2(ep + Vector2(-1.2, -eh * 0.5), Vector2(3.0, eh)), Color("#fbf8ff"))
				v.draw_rect(Rect2(ep + Vector2(-0.6, -eh * 0.5), Vector2(2.2, eh)), EYE)
				v.draw_rect(Rect2(ep + Vector2(-0.6, eh * 0.5 - 1.0), Vector2(2.2, 1)), EYE_DEEP)
				var star_k := 0.7 + 0.3 * sin(t * 3.0)
				v.draw_rect(Rect2(ep + Vector2(0.2, -0.6), Vector2(1, 1)), Color(STAR_CORE, star_k))
				v.draw_rect(Rect2(ep + Vector2(-0.6, -eh * 0.5), Vector2(1, 1)), Color(1, 1, 1, 0.9))
				v.draw_line(ep + Vector2(-1.6, -eh * 0.5 - 0.6), ep + Vector2(2.4, -eh * 0.5 - 0.2), LASH, 1.0)
				v.draw_rect(Rect2(ep + Vector2(2.2, -eh * 0.5 - 1.2), Vector2(1, 1)), LASH) # 바깥 속눈썹 끝
				# 먼 눈
				v.draw_rect(Rect2(fe + Vector2(-0.4, -eh * 0.5), Vector2(1.2, eh)), EYE)
				v.draw_line(fe + Vector2(-0.8, -eh * 0.5 - 0.5), fe + Vector2(1.0, -eh * 0.5 - 0.3), LASH, 1.0)
	# 눈썹 (은색)
	if eyes != "white":
		v.draw_line(hc + Vector2(1.8, -3.4), hc + Vector2(4.8, -3.2 + (0.6 if eyes == "sharp" else 0.0)), HAIR_SH, 1.0)
	# 입
	var m := hc + Vector2(2.2, 4.2)
	if poss > 0.0:
		v.draw_line(m + Vector2(-1, 0), m + Vector2(1, 0), Color("#9a8ab0"), 1.0)
	elif talking and int(t * 10.0) % 2 == 0:
		v.draw_rect(Rect2(m + Vector2(-0.5, -0.5), Vector2(1.5, 1.5)), Color("#b0606a"))
	elif pose == "hurt" or eyes == "sharp":
		v.draw_line(m + Vector2(-1, 0.2), m + Vector2(1, 0.0), Color("#c07a80"), 1.0)
	else:
		# 다정한 미소 (가는 반달)
		v.draw_rect(Rect2(m + Vector2(-1, 0), Vector2(1, 1)), Color("#c87a80"))
		v.draw_rect(Rect2(m + Vector2(0, 0.5), Vector2(1, 1)), Color("#c87a80"))
		v.draw_rect(Rect2(m + Vector2(1, 0), Vector2(1, 1)), Color("#c87a80"))


# ─── 모자 ───────────────────────────────────────────────

static func _hat(v: CanvasItem, hc: Vector2, t: float, tilt: float, trail: float, poss: float, pose: String) -> void:
	var bc := hc + Vector2(-0.5, -5.5) # 챙 가운데
	var rot := tilt
	var hat := HAT.lerp(Color("#3a3a50"), poss * 0.4)
	var hat_hi := HAT_HI.lerp(Color("#6a6a80"), poss * 0.4)
	# 챙 (아주 넓다)
	var brim := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var r := Vector2(cos(a) * 16.0, sin(a) * 3.2)
		if sin(a) < 0.0:
			r.y *= 0.7
		brim.append(bc + r.rotated(rot))
	v.draw_colored_polygon(brim, HAT_SH)
	var brim_top := PackedVector2Array()
	for i in 11:
		var a := PI + PI * i / 10.0
		brim_top.append(bc + Vector2(cos(a) * 15.5, sin(a) * 2.4 - 0.4).rotated(rot))
	for i in range(10, -1, -1):
		var a := PI + PI * i / 10.0
		brim_top.append(bc + Vector2(cos(a) * 13.0, sin(a) * 1.0 + 0.6).rotated(rot))
	v.draw_colored_polygon(brim_top, hat)
	v.draw_line(bc + Vector2(-15, 0.2).rotated(rot), bc + Vector2(15, 0.2).rotated(rot), hat_hi, 1.0)
	# 고깔: 뒤로 기울어 올라가다 끝이 초승달처럼 앞으로 말린다
	var sway := sin(t * 1.3) * 1.0 + trail * 0.25
	var cl: Array = [
		Vector2(0, -0.5), Vector2(-2.5, -7), Vector2(-5.0 + sway * 0.3, -13), Vector2(-6.5 + sway * 0.6, -18),
		Vector2(-4.5 + sway, -22.5), Vector2(-0.5 + sway, -24.5), Vector2(3.5 + sway, -23), Vector2(5.5 + sway, -19.5),
	]
	var ws: Array = [5.6, 4.6, 3.6, 2.7, 2.0, 1.5, 1.0, 0.4]
	var pts: Array = []
	for p in cl:
		pts.append(bc + (p as Vector2).rotated(rot))
	_strip(v, pts, ws, hat)
	# 그림자 쪽 (뒤)
	var shp: Array = []
	var shw: Array = []
	for i in 4:
		shp.append((pts[i] as Vector2) + Vector2(-1.6, 0.3).rotated(rot))
		shw.append(float(ws[i]) * 0.4)
	_strip(v, shp, shw, HAT_SH)
	# 초승달 바깥 가장자리 빛
	for i in range(3, 7):
		v.draw_line(pts[i] + Vector2(0, -1.2), pts[i + 1] + Vector2(0, -1.2), Color(GOLD, 0.55), 1.0)
	# 금 띠 + 작은 별 둘
	var band_l := bc + Vector2(-5.2, -1.6).rotated(rot)
	var band_r := bc + Vector2(5.2, -1.6).rotated(rot)
	v.draw_line(band_l, band_r, GOLD_SH, 2.0)
	v.draw_line(band_l + Vector2(0, -0.5), band_r + Vector2(0, -0.5), GOLD, 1.0)
	StArt.star(v, bc + Vector2(2.2, -1.9).rotated(rot), 1.8, STAR, -PI * 0.5 + rot)
	# 말린 끝에 매달린 별 (진자처럼 흔들)
	var tip: Vector2 = pts[pts.size() - 1]
	var swing := sin(t * 2.1) * 0.5 + trail * -0.03
	var star_p := tip + Vector2(sin(swing), cos(swing)) * 5.5
	v.draw_line(tip, star_p, Color(GOLD, 0.8), 1.0)
	var sc := STAR if poss <= 0.0 else Color("#d8d8e8")
	v.draw_circle(star_p, 4.0, Color(sc, 0.15))
	StArt.star(v, star_p, 2.6, sc, -PI * 0.5 + swing)
	v.draw_rect(Rect2(star_p - Vector2(0.5, 0.5), Vector2(1, 1)), STAR_CORE)
	if poss <= 0.0:
		StArt.sparkle(v, star_p + Vector2(2.5, -2.5), 2.0, STAR, StArt.twinkle(t, 9.0, 1.4))


# ─── 옷 ─────────────────────────────────────────────────

static func _dress(v: CanvasItem, b: Vector2, t: float, trail: float, lean: float, low: float, pose: String, poss: float) -> void:
	var wy := b.y - 20.0 + low * 0.6
	var hy := -0.5 if low > 0.0 else b.y - 0.5
	var kneel := pose == "kneel"
	var wx := lean * 5.0
	var flow := trail * 0.6
	# 치맛단 점들 (물결)
	var hem: Array[Vector2] = []
	var n := 9
	var half_l := 9.5 + (5.0 if kneel else 0.0)
	var half_r := 10.0 + (6.0 if kneel else 0.0)
	for i in n + 1:
		var u := float(i) / n
		var x := lerpf(-half_l, half_r, u) + flow * (1.0 - u * 0.5)
		var y := hy + sin(t * 2.6 + u * 7.0) * 0.9 + (1.0 if i % 2 == 0 else 0.0)
		hem.append(Vector2(x, y))
	var outline := PackedVector2Array([Vector2(wx - 4.0, wy), Vector2(wx + 4.0, wy)])
	for i in range(n, -1, -1):
		outline.append(hem[i])
	var robe := ROBE.lerp(Color("#5a5a78"), poss * 0.35)
	var robe_sh := ROBE_SH.lerp(Color("#3a3a50"), poss * 0.35)
	# 안감 (치맛단 뒤로 보라)
	var lining := PackedVector2Array()
	for i in n + 1:
		lining.append(hem[i] + Vector2(-1.2 - flow * 0.15, 1.2))
	lining.append(hem[n] + Vector2(0, -3))
	lining.append(hem[0] + Vector2(0, -3))
	v.draw_colored_polygon(lining, LINING.lerp(Color("#6a6a80"), poss * 0.5))
	v.draw_colored_polygon(outline, robe)
	# 뒤쪽 그림자 (3단 명암: 그림자)
	v.draw_colored_polygon(PackedVector2Array([Vector2(wx - 4.0, wy), Vector2(wx - 1.5, wy), hem[2] + Vector2(0, -0.5), hem[0]]), robe_sh)
	# 앞쪽 빛 (3단 명암: 빛) — 앞자락 주름 두 줄
	v.draw_line(Vector2(wx + 2.0, wy + 1), hem[7] + Vector2(-0.5, -1), ROBE_HI, 1.0)
	v.draw_line(Vector2(wx + 0.5, wy + 2), hem[5] + Vector2(0, -1), Color(ROBE_HI, 0.6), 1.0)
	v.draw_line(Vector2(wx - 1.0, wy + 2), hem[3] + Vector2(0, -1), robe_sh, 1.0)
	# 금실 단
	for i in n:
		v.draw_line(hem[i] + Vector2(0, -1), hem[i + 1] + Vector2(0, -1), Color(GOLD, 0.75), 1.0)
	# 별자리 자수 (천천히 반짝)
	var emb_pts: Array = []
	for e in EMB:
		emb_pts.append(_skirt_pt(e, wx, wy, hem))
	var k := 0.55 + 0.25 * sin(t * 1.3)
	for i in range(1, emb_pts.size()):
		v.draw_line(emb_pts[i - 1], emb_pts[i], Color(GOLD, 0.45 * k), 1.0)
	for i in emb_pts.size():
		var tw := StArt.twinkle(t, i * 2.0, 1.1)
		v.draw_rect(Rect2((emb_pts[i] as Vector2) - Vector2(0.5, 0.5), Vector2.ONE), Color(STAR_CORE, 0.5 + 0.5 * tw))
	var emb2: Array = []
	for e in EMB2:
		emb2.append(_skirt_pt(e, wx, wy, hem))
	for i in range(1, emb2.size()):
		v.draw_line(emb2[i - 1], emb2[i], Color(GOLD, 0.35 * k), 1.0)
	# 흩뿌린 별가루
	for i in 6:
		var p := _skirt_pt(Vector2(fmod(i * 0.37 + 0.1, 0.9) + 0.05, fmod(i * 0.53 + 0.2, 0.85) + 0.1), wx, wy, hem)
		v.draw_rect(Rect2(p, Vector2.ONE), Color(STAR, 0.35 * StArt.twinkle(t, i * 3.1 + 5.0)))


static func _skirt_pt(e: Vector2, wx: float, wy: float, hem: Array[Vector2]) -> Vector2:
	var hl: Vector2 = hem[0]
	var hr: Vector2 = hem[hem.size() - 1]
	var left := Vector2(wx - 4.0, wy).lerp(hl, e.y)
	var right := Vector2(wx + 4.0, wy).lerp(hr, e.y)
	return left.lerp(right, e.x).round()


static func _torso(v: CanvasItem, b: Vector2, lean: float, t: float, poss: float) -> void:
	var wx := lean * 5.0
	var sx := lean * 6.0
	var robe := ROBE.lerp(Color("#5a5a78"), poss * 0.35)
	# 몸통 (허리 → 어깨)
	v.draw_colored_polygon(PackedVector2Array([
		b + Vector2(wx - 3.8, -20), b + Vector2(wx + 4.0, -20), b + Vector2(sx + 4.5, -26.5), b + Vector2(sx - 4.0, -27),
	]), robe)
	# 허리띠 + 별 브로치
	v.draw_line(b + Vector2(wx - 4.0, -20.5), b + Vector2(wx + 4.2, -20.5), GOLD_SH, 2.0)
	StArt.star(v, b + Vector2(wx + 2.0, -20.6), 1.8, STAR, -PI * 0.5)
	# 어깨 케이프 (금 테, 목의 별 장식)
	var cape := CAPE.lerp(Color("#4a4a62"), poss * 0.35)
	var cp := PackedVector2Array([
		b + Vector2(sx - 5.5, -26.5), b + Vector2(sx + 5.5, -26.8), b + Vector2(sx + 6.5, -22.5),
		b + Vector2(sx + 2.0, -21.5), b + Vector2(sx - 1.0, -22.8), b + Vector2(sx - 5.0, -21.8), b + Vector2(sx - 6.5, -23.0),
	])
	v.draw_colored_polygon(cp, cape)
	v.draw_polyline(PackedVector2Array([cp[2], cp[3], cp[4], cp[5], cp[6]]), GOLD, 1.0)
	v.draw_line(b + Vector2(sx - 4.0, -26.6), b + Vector2(sx + 4.5, -26.9), Color("#d8dcf0"), 1.0) # 흰 깃
	StArt.star(v, b + Vector2(sx + 2.5, -25.5), 1.6, STAR, -PI * 0.5 + sin(t) * 0.2)


static func _arm(v: CanvasItem, shoulder: Vector2, hand: Vector2, back: bool, poss: float) -> void:
	var col := (ROBE_SH if back else ROBE).lerp(Color("#5a5a78"), poss * 0.35)
	var d := hand - shoulder
	var elbow := shoulder + d * 0.5 + d.orthogonal().normalized() * 1.0
	v.draw_line(shoulder, elbow, col, 2.6)
	# 종 모양 소매 (손목 쪽으로 넓어짐)
	var dir := (hand - elbow).normalized()
	var nrm := dir.orthogonal()
	var cuff := hand - dir * 1.5
	v.draw_colored_polygon(PackedVector2Array([elbow + nrm * 1.3, cuff + nrm * 3.2, cuff - nrm * 3.2, elbow - nrm * 1.3]), col)
	v.draw_line(cuff + nrm * 3.2, cuff - nrm * 3.2, Color(GOLD, 0.6 if back else 0.9), 1.0)
	v.draw_circle(hand, 1.4, SKIN_SH if back else SKIN.lerp(Color("#eef0fa"), poss * 0.6))


# ─── 별 7개 ─────────────────────────────────────────────

static func _orbit_stars(v: CanvasItem, b: Vector2, t: float, front: bool, poss: float, glow: float) -> void:
	var c := b + Vector2(0, -20)
	for i in 7:
		var a := (t * 0.9 if poss <= 0.0 else 1.3) + TAU * i / 7.0
		var depth := sin(a)
		if (depth > 0.0) != front:
			continue
		var p := c + Vector2(cos(a) * (15.0 + glow * 4.0), depth * 5.0 - 2.0 + sin(t * 2.0 + i) * 1.0).rotated(0.12)
		if poss > 0.0:
			p += Vector2(sin(i * 3.1) * 6.0, -6.0 - i % 3 * 4.0)
		var col := STAR if poss <= 0.0 else Color("#b8b8c8")
		var r := 1.2 if front else 0.8
		v.draw_circle(p, r + 1.5, Color(col, 0.09 if front else 0.05))
		StArt.star(v, p, r + 0.6, Color(col, 1.0 if front else 0.6), -PI * 0.5 + t * 2.0 + i)
		if front and poss <= 0.0:
			v.draw_line(p, p - Vector2(cos(a + PI * 0.5), 0) * 3.0, Color(STAR, 0.3), 1.0)


# ─── 손의 마법 ──────────────────────────────────────────

static func _hand_magic(v: CanvasItem, hf: Vector2, hb: Vector2, pose: String, pk: float, t: float, glow: float) -> void:
	match pose:
		"idle", "run":
			# 손바닥 위에 떠 있는 작은 별
			var sp := hf + Vector2(1, -5 + sin(t * 2.2) * 1.0)
			v.draw_circle(sp, 3.0, Color(STAR, 0.15))
			StArt.star(v, sp, 1.8, STAR, -PI * 0.5 + t)
		"cast":
			# 별의 마법진 (손 앞에서 돈다)
			var c := hf + Vector2(4, 0)
			v.draw_arc(c, 6.0, 0, TAU, 16, Color(STAR, 0.7), 1.0)
			for i in 5:
				var a := t * 2.0 + TAU * i / 5.0
				var q := c + Vector2(cos(a), sin(a)) * 6.0
				var q2 := c + Vector2(cos(a + TAU * 2.0 / 5.0), sin(a + TAU * 2.0 / 5.0)) * 6.0
				v.draw_line(q, q2, Color(STAR, 0.45), 1.0)
			StArt.star(v, c, 2.0, STAR_CORE, t * 3.0)
		"attack":
			var c2 := hf + Vector2(4, 1)
			var k := clampf(1.0 - pk / 0.3, 0.0, 1.0)
			v.draw_circle(c2, 5.0 + 6.0 * (1.0 - k), Color(STAR, 0.4 * k + 0.1))
			StArt.sparkle(v, c2, 7.0, STAR_CORE, 1.0)
		"windup", "special":
			for h in [hf, hb]:
				var hv: Vector2 = h
				v.draw_circle(hv, 3.0 + glow * 3.0 + sin(t * 9.0), Color(STAR, 0.18 + glow * 0.15))
				StArt.sparkle(v, hv, 3.0 + glow * 2.0, STAR, 0.7 + 0.3 * sin(t * 7.0))
			if pose == "special":
				# 하늘로 솟는 별빛 기둥
				v.draw_rect(Rect2(hf.x - 4, hf.y - 40, 8, 40), Color(STAR, 0.08))
				v.draw_rect(Rect2(hf.x - 1, hf.y - 40, 2, 40), Color(STAR, 0.25))
		"guard":
			# 별 방패 (육각 별무늬)
			var c3 := hf + Vector2(4, 2)
			var hexp := PackedVector2Array()
			for i in 7:
				var a := TAU * i / 6.0 + PI / 6.0
				hexp.append(c3 + Vector2(cos(a) * 3.0, sin(a) * 10.0))
			v.draw_colored_polygon(hexp, Color(STAR, 0.18))
			v.draw_polyline(hexp, Color(STAR, 0.8), 1.0)
			StArt.star(v, c3, 2.4, STAR, -PI * 0.5)


# ─── 흉내 무기 ──────────────────────────────────────────

## 별검 (레오니식): 길고 가는 빛의 칼날, 금 코등이
static func _sword(v: CanvasItem, hand: Vector2, b: Vector2, pose: String, pk: float, t: float) -> void:
	var dir := Vector2(1.0, 0.38).normalized()
	var len := 22.0
	if pose == "sword_windup":
		# 칼집 자세: 칼날은 허리 뒤로 비스듬히 (별빛 칼집 안), 손잡이에 빛이 모인다
		dir = Vector2(-1.0, 0.25).normalized()
		len = 20.0
		var sheath_a := hand + dir * 3.0
		var sheath_b := hand + dir * 21.0
		v.draw_line(sheath_a, sheath_b, Color("#2a3070"), 3.0)
		v.draw_line(sheath_a, sheath_b, Color(GOLD, 0.6), 1.0)
		var g := clampf(pk / 1.2, 0.0, 1.0)
		v.draw_circle(hand, 3.0 + g * 4.0, Color(STAR, 0.2 + g * 0.3))
		StArt.sparkle(v, hand + Vector2(1, -1), 3.0 + g * 5.0, STAR_CORE, 0.6 + 0.4 * sin(t * 12.0))
		v.draw_line(hand + Vector2(-1, -2), hand + Vector2(2, 2), GOLD, 2.0)
		return
	if pose == "sword_attack":
		dir = Vector2(1.0, -0.06).normalized()
		len = 25.0
		var k := clampf(pk / 0.3, 0.0, 1.0)
		if k < 1.0:
			# 베어 낸 궤적 (초승달 빛)
			var arc := PackedVector2Array()
			for i in 10:
				var a := lerpf(-1.4, 0.15, float(i) / 9.0)
				arc.append(hand + Vector2(cos(a), sin(a)) * 22.0)
			v.draw_polyline(arc, Color(STAR, 0.7 * (1.0 - k)), 3.0)
			v.draw_polyline(arc, Color(STAR_CORE, 0.9 * (1.0 - k)), 1.0)
	var tip := hand + dir * len
	var n := dir.orthogonal()
	v.draw_colored_polygon(PackedVector2Array([hand + n * 1.6, tip, hand - n * 1.6]), Color(STAR, 0.35))
	v.draw_line(hand, tip, Color(STAR, 0.95), 1.0)
	v.draw_line(hand + dir * 2.0, tip - dir * 2.0, STAR_CORE, 1.0)
	# 칼날을 따라 지나가는 반사 점
	var gl := fmod(t * 0.9, 1.0)
	v.draw_rect(Rect2(hand + dir * len * gl - Vector2(0.5, 1), Vector2(1, 2)), Color(1, 1, 1, 0.9))
	# 코등이(별)·손잡이
	StArt.star(v, hand + dir * 1.5, 2.2, GOLD, dir.angle() - PI * 0.5)
	v.draw_line(hand, hand - dir * 3.0, Color("#3a2a60"), 2.0)


## 별자리 활 (엘라리엔식): 별 점을 이은 활대 + 빛 시위 + 빛 화살
static func _bow(v: CanvasItem, hf: Vector2, hb: Vector2, pose: String, pk: float, t: float) -> void:
	var c := hf
	var top := c + Vector2(-3, -13)
	var bot := c + Vector2(-3, 13)
	var arc: Array = []
	for i in 7:
		var u := float(i) / 6.0
		var a := lerpf(-1.25, 1.25, u)
		arc.append(c + Vector2(cos(a) * 4.0 - 3.0 + 3.0, sin(a) * 13.0) + Vector2(cos(a) * 2.0, 0))
	for i in range(1, arc.size()):
		v.draw_line(arc[i - 1], arc[i], Color(STAR, 0.8), 1.0)
	for p in arc:
		var pv: Vector2 = p
		v.draw_rect(Rect2(pv - Vector2(1, 1), Vector2(2, 2)), STAR_CORE)
	top = arc[0]
	bot = arc[arc.size() - 1]
	var pull := hb if pose == "bow_draw" else c + Vector2(-3, 0)
	var vib := 0.0
	if pose == "bow_release":
		vib = sin(pk * 60.0) * maxf(0.0, 1.0 - pk * 3.0) * 2.0
		pull = c + Vector2(-3 + vib, 0)
	v.draw_line(top, pull, Color(STAR, 0.7), 1.0)
	v.draw_line(pull, bot, Color(STAR, 0.7), 1.0)
	if pose == "bow_draw":
		var tip := c + Vector2(9, 0)
		v.draw_line(pull, tip, Color(STAR, 0.9), 1.0)
		StArt.star(v, tip, 2.0, STAR_CORE, 0.0)
		v.draw_circle(tip, 3.0 + sin(t * 10.0), Color(STAR, 0.25))


## 별창 (아우렐리아식): 날개 모양 날의 긴 빛 창
static func _spear(v: CanvasItem, hf: Vector2, hb: Vector2, pose: String, pk: float, t: float) -> void:
	var a: Vector2
	var tip: Vector2
	match pose:
		"spear":
			a = hf + Vector2(0, 14)
			tip = hf + Vector2(0, -26)
		"spear_windup":
			a = hb + Vector2(-8, 1)
			tip = hf + Vector2(20, 0)
		_:
			a = hb + Vector2(-10, 0)
			tip = hf + Vector2(24, 0)
	var dir := (tip - a).normalized()
	var n := dir.orthogonal()
	v.draw_line(a, tip - dir * 5.0, Color("#3a3a80"), 2.0)
	v.draw_line(a, tip - dir * 5.0, Color(GOLD, 0.7), 1.0)
	# 날개 모양 날
	var head := PackedVector2Array([tip, tip - dir * 6.0 + n * 2.5, tip - dir * 5.0 + n * 5.5, tip - dir * 8.0 + n * 1.0,
		tip - dir * 8.0 - n * 1.0, tip - dir * 5.0 - n * 5.5, tip - dir * 6.0 - n * 2.5])
	v.draw_colored_polygon(head, Color(STAR, 0.9))
	v.draw_line(tip - dir * 7.0, tip, STAR_CORE, 1.0)
	if pose == "spear_charge":
		for i in 4:
			var y := -4.0 + i * 3.0
			v.draw_line(a + n * y - dir * (6.0 + i * 3.0), a + n * y - dir * (18.0 + i * 5.0 + sin(t * 20.0 + i) * 3.0), Color(STAR, 0.35), 1.0)
	elif pose == "spear_windup":
		var g := clampf(pk / 0.9, 0.0, 1.0)
		v.draw_circle(tip - dir * 4.0, 4.0 + g * 5.0, Color(STAR, 0.15 + g * 0.25))


## 창을 들 때 등 뒤의 별빛 광륜
static func _star_halo(v: CanvasItem, c: Vector2, t: float, k: float) -> void:
	v.draw_arc(c, 12.0, 0, TAU, 28, Color(GOLD, 0.55 * k), 1.0)
	v.draw_arc(c, 9.5, 0, TAU, 24, Color(STAR, 0.25 * k), 2.0)
	for i in 8:
		var a := t * 0.5 + TAU * i / 8.0
		StArt.star(v, c + Vector2(cos(a), sin(a)) * 12.0, 1.4, Color(STAR, k), a)


# ─── 빙의 (하늘의 문) ───────────────────────────────────

static func _possessed_halo(v: CanvasItem, c: Vector2, t: float) -> void:
	v.draw_circle(c, 26.0, Color(WHITE_GOD, 0.06))
	v.draw_arc(c, 20.0, 0, TAU, 6, Color(WHITE_GOD, 0.7), 1.0) # 육각
	v.draw_arc(c, 24.0 + sin(t * 2.0), 0, TAU, 32, Color(WHITE_GOD, 0.35), 1.0)
	for i in 6:
		var a := TAU * i / 6.0 + t * 0.3
		v.draw_line(c + Vector2(cos(a), sin(a)) * 14.0, c + Vector2(cos(a), sin(a)) * 30.0, Color(WHITE_GOD, 0.3), 1.0)
	v.draw_rect(Rect2(c.x - 1, c.y - 60, 2, 60), Color(WHITE_GOD, 0.15 + 0.1 * sin(t * 3.0)))


## 몸·얼굴에 번진 흰 금
static func _cracks(v: CanvasItem, b: Vector2, hc: Vector2, t: float) -> void:
	var k := 0.7 + 0.3 * sin(t * 4.0)
	var col := Color(WHITE_GOD, k)
	v.draw_polyline(PackedVector2Array([hc + Vector2(2, -6), hc + Vector2(3, -3), hc + Vector2(1.5, -1), hc + Vector2(2.5, 2)]), col, 1.0)
	v.draw_polyline(PackedVector2Array([hc + Vector2(5, 3), hc + Vector2(4, 5), hc + Vector2(5, 7)]), col, 1.0)
	v.draw_polyline(PackedVector2Array([b + Vector2(1, -26), b + Vector2(-1, -22), b + Vector2(1, -18), b + Vector2(-2, -12), b + Vector2(0, -6)]), col, 1.0)
	v.draw_polyline(PackedVector2Array([b + Vector2(-1, -22), b + Vector2(-5, -19)]), col, 1.0)
	v.draw_polyline(PackedVector2Array([b + Vector2(-2, -12), b + Vector2(4, -9), b + Vector2(6, -4)]), col, 1.0)
	for i in 4:
		var q := b + Vector2(sin(i * 2.7) * 8.0, -8.0 - i * 6.0)
		v.draw_rect(Rect2(q, Vector2.ONE), Color(WHITE_GOD, 0.6 * k))


# ─── 쓰러짐 ─────────────────────────────────────────────

static func _draw_down(v: CanvasItem, t: float, st: Dictionary) -> void:
	# 등을 대고 누움: 머리는 뒤(-x), 은빛 머리가 바닥에 부채처럼 퍼진다, 모자는 옆에 떨어져 있다
	var g := Vector2(0, -1)
	# 퍼진 머리카락
	for i in 5:
		var a := PI + 0.25 + i * 0.18
		var pts: Array = []
		var ws: Array = []
		for k in 6:
			var u := float(k) / 5.0
			pts.append(g + Vector2(-13, -2) + Vector2(cos(a) * u * 14.0, sin(a) * u * 4.0 + u * 2.0))
			ws.append(2.4 - u * 1.4)
		_strip(v, pts, ws, HAIR_SH if i % 2 == 0 else HAIR)
	# 드레스 (옆으로 누운 사다리꼴)
	v.draw_colored_polygon(PackedVector2Array([g + Vector2(-9, -5), g + Vector2(14, -6), g + Vector2(15, 0), g + Vector2(-9, 0)]), ROBE)
	v.draw_line(g + Vector2(-8, -5), g + Vector2(14, -6), ROBE_HI, 1.0)
	v.draw_line(g + Vector2(14, -6), g + Vector2(15, 0), Color(GOLD, 0.8), 1.0)
	for i in 4:
		v.draw_rect(Rect2(g + Vector2(-4 + i * 5, -3 - i % 2), Vector2.ONE), Color(STAR_CORE, 0.6 * StArt.twinkle(t, i)))
	# 케이프·팔
	v.draw_colored_polygon(PackedVector2Array([g + Vector2(-9, -6), g + Vector2(-4, -7), g + Vector2(-3, -1), g + Vector2(-9, 0)]), CAPE)
	v.draw_line(g + Vector2(-4, -6), g + Vector2(4, -9), ROBE, 2.0)
	v.draw_circle(g + Vector2(5, -9), 1.3, SKIN)
	# 머리 (옆얼굴, 눈 감음)
	var hc := g + Vector2(-14, -4)
	v.draw_circle(hc, 5.5, SKIN)
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-5, -3), hc + Vector2(2, -6), hc + Vector2(5, -2), hc + Vector2(1, -3), hc + Vector2(-4, 1)]), HAIR)
	v.draw_line(hc + Vector2(0, 0), hc + Vector2(2.5, 0.5), LASH, 1.0)
	# 떨어진 모자 (초승달 끝이 바닥에)
	var hat_c := g + Vector2(20, -2)
	v.draw_colored_polygon(DrawKit.ellipse(hat_c, 9.0, 2.0, 12), HAT_SH)
	v.draw_colored_polygon(PackedVector2Array([hat_c + Vector2(-4, -1), hat_c + Vector2(4, -1), hat_c + Vector2(13, -7), hat_c + Vector2(9, -9)]), HAT)
	StArt.star(v, hat_c + Vector2(13, -3), 2.0, Color(STAR, 0.7), 0.3)
	# 꺼져 가는 별들 (바닥 가까이)
	for i in 7:
		var p := g + Vector2(-16 + i * 6, -10 - sin(t * 1.2 + i) * 2.0)
		v.draw_rect(Rect2(p, Vector2.ONE), Color(STAR, 0.25 + 0.2 * sin(t * 2.0 + i)))
