extends "res://characters/special/aurelia_palette.gd"
## 아우렐리아 (루멘 대신전의 수호자) 전용 몸 그림 — docs/archive/sera/bible/characters.md 3절, art.md 3절, docs/archive/sera/chapter4.md 7.3절.
## CharacterVisual이 static draw_body(v)를 부른다 (원점 발밑, +x가 바라보는 쪽, 부모가 좌우를 뒤집음).
## 키 42px. 허리까지 오는 금발(정수리에 땋아 올린 왕관 머리), 하얀 금 갑옷, 머리 뒤에 떠 있는 금빛 광륜(천천히 돎),
## 날개 모양 날의 긴 창, 하얀 천 치마 갑옷. 3단 명암(바탕·그늘·빛), 머리카락 가닥이 따로 흔들리고(바람·달리기에 따라 뒤로 흩날림),
## 창날에 빛이 지나가고, 숨쉬기 1px·눈 깜빡임·창을 고쳐 잡는 대기 동작이 있다.
##
## 자세 (v.pose): idle · run · windup(창을 뒤로 당김 — 예고, 붉은 빛) · attack(찌르기) · attack2(올려 베기) · charge(신성 돌진, 창을 겨드랑이에 끼고 몸을 숙임)
##               · cast(창을 머리 위로 — 빛의 창 비) · guard(창을 비스듬히 막음) · hurt · kneel(한쪽 무릎) · down(쓰러짐) · special(심판의 창: 떠올라 창을 높이 듦)
##               · aim → windup, 모르는 자세 → idle. 걷는 NPC(v.walking)는 차분한 걸음.
## 폭주(바깥 신들): 다음 중 하나면 폭주 그림 — 자세 이름이 "berserk_"로 시작(예: "berserk_charge"), 인물 정보에 "berserk": true
##   (Characters ID "aurelia_berserk"), 또는 v.set_meta("berserk", true). 광륜이 금 가고 흰빛이 새며, 눈이 하얗게, 흰금 불꽃이 몸에서 일렁이고, 머리카락이 떠오른다.
## 덧붙일 수 있는 메타: v.set_meta("halo", 1.6) 광륜 크기 배율(시전 연출).

const ARM_D := Color("#6f6a92")
const SKIN_S := Color("#d9ab99")
const CLOTH := Color("#f4f2fa")
const CLOTH_S := Color("#bdb8d6")
const SHAFT := Color("#f0e4c8")
const SHAFT_S := Color("#b89e70")
const BLADE_S := Color("#9aa4c4")
const DANGER := Color("#ff3b3b")

const THIGH := 9.5
const SHIN := 9.5
const UPPER_ARM := 6.5
const FOREARM := 6.5


static func draw_body(v: CharacterVisual) -> void:
	var raw := v.pose
	var berserk := raw.begins_with("berserk_") or bool(v.info.get("berserk", false)) or (v.has_meta("berserk") and bool(v.get_meta("berserk")))
	var pose := raw.trim_prefix("berserk_")
	if pose == "aim":
		pose = "windup"
	var t := v.time()
	var r := _rig(pose, v, t, v.pose_t, berserk)
	if pose == "down":
		v.draw_set_transform(Vector2(18, -6), -PI * 0.5, Vector2.ONE)
	elif berserk:
		v.draw_set_transform(Vector2(sin(t * 41.0) * 0.4, 0.0), 0.0, Vector2.ONE)
	_draw_rig(v, r, t, berserk, pose)
	v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ═══════════════════════════════════════════════════════════
# 자세 (뼈대 점들)
# ═══════════════════════════════════════════════════════════

static func _rig(pose: String, v: CharacterVisual, t: float, pt: float, berserk: bool) -> Dictionary:
	var br := sin(t * 1.8) * 0.5
	var r := {
		"hip": Vector2(0, -19 + br * 0.4), "lean": 0.0,
		"foot_f": Vector2(3, 0), "foot_b": Vector2(-3, 0),
		"hand_f": Vector2(7, -21 + br * 0.4), "hand_b": Vector2(-4.5, -18 + br * 0.4),
		"butt": Vector2(7.5, 3), "tip": Vector2(7.5, -53),
		"wind": Vector2(-1.0, 0.0), "head": Vector2(0, br * 0.3), "tilt": 0.0, "halo": 1.0,
		"danger": 0.0, "glint": clampf(1.0 - fmod(t + 0.7, 2.6) / 0.4, 0.0, 1.0), "skirt": 0.0, "amp": 1.0,
		"fist_b": false,
	}
	match pose:
		"run":
			var ph := v.walk_phase() if v.walking else t * 11.0
			var s := sin(ph)
			r.hip = Vector2(1, -18.5 - absf(cos(ph)) * 1.0)
			r.lean = 0.16
			r.foot_f = Vector2(1 + s * 7.0, -maxf(cos(ph), 0.0) * 3.5)
			r.foot_b = Vector2(1 - s * 7.0, -maxf(-cos(ph), 0.0) * 3.5)
			r.hand_f = Vector2(9, -21 + s * 0.8)
			r.hand_b = Vector2(-2 - s * 4.0, -18 + absf(s))
			r.butt = Vector2(-14, -13)
			r.tip = Vector2(38, -27 + s * 0.8)
			r.wind = Vector2(-7, -1)
			r.amp = 1.6
			r.skirt = 1.0
		"windup":
			var k := clampf(pt / 0.18, 0.0, 1.0)
			var e := k * k * (3.0 - 2.0 * k)
			var shake := sin(t * 60.0) * 0.4 * e
			r.hip = Vector2(-2.0 * e + shake, -19 + 3.5 * e)
			r.lean = -0.08 * e
			r.foot_f = Vector2(3 + 5.0 * e, 0)
			r.foot_b = Vector2(-3 - 5.0 * e, 0)
			r.hand_f = Vector2(7, -21).lerp(Vector2(4, -24), e)
			r.hand_b = Vector2(-4.5, -18).lerp(Vector2(-7, -23), e)
			r.butt = Vector2(7.5, 3).lerp(Vector2(-40, -21), e)
			r.tip = Vector2(7.5, -53).lerp(Vector2(13, -24.5), e)
			r.wind = Vector2(-2, -0.5)
			r.danger = e * (0.6 + 0.4 * sin(t * 30.0))
			r.glint = 0.0
		"attack":
			var k := clampf(pt / 0.08, 0.0, 1.0)
			r.hip = Vector2(2.0 + 3.0 * k, -16.5)
			r.lean = 0.22
			r.foot_f = Vector2(13, 0)
			r.foot_b = Vector2(-9, 0)
			r.hand_f = Vector2(16, -23)
			r.hand_b = Vector2(8, -22)
			r.butt = Vector2(-4, -21)
			r.tip = Vector2(14 + 38.0 * k, -24)
			r.wind = Vector2(-8, -1)
			r.amp = 1.8
			r.skirt = 1.2
			r.glint = 1.0 - k * 0.5
		"attack2":
			var k := clampf(pt / 0.12, 0.0, 1.0)
			r.hip = Vector2(3, -17)
			r.lean = 0.12
			r.foot_f = Vector2(10, 0)
			r.foot_b = Vector2(-7, 0)
			r.hand_f = Vector2(8, -25)
			r.hand_b = Vector2(1, -21)
			var ang := lerpf(0.35, -0.95, k)
			var dir := Vector2(cos(ang), sin(ang))
			r.butt = Vector2(4, -23) - dir * 16.0
			r.tip = Vector2(4, -23) + dir * 38.0
			r.wind = Vector2(-6, -2)
			r.amp = 1.6
			r.skirt = 1.0
		"charge":
			var flap := sin(t * 30.0)
			r.hip = Vector2(2, -14.5)
			r.lean = 0.5
			r.foot_f = Vector2(9, -1.5)
			r.foot_b = Vector2(-13, -5 + flap * 0.6)
			r.hand_f = Vector2(13, -19)
			r.hand_b = Vector2(4, -19.5)
			r.butt = Vector2(-15, -20)
			r.tip = Vector2(56, -18.5)
			r.wind = Vector2(-14, 1.5 + flap * 0.4)
			r.amp = 2.4
			r.skirt = 2.0
			r.glint = 1.0
		"cast":
			var k := clampf(pt / 0.3, 0.0, 1.0)
			var e := k * k * (3.0 - 2.0 * k)
			r.lean = -0.07 * e
			r.hip = Vector2(0, -19.5)
			r.foot_f = Vector2(4, 0)
			r.foot_b = Vector2(-4, 0)
			r.hand_f = Vector2(7, -21).lerp(Vector2(5, -41), e)
			r.hand_b = Vector2(-4.5, -18).lerp(Vector2(-7, -38), e)
			r.butt = Vector2(7.5, 3).lerp(Vector2(5, -15), e)
			r.tip = Vector2(7.5, -53).lerp(Vector2(5, -71), e)
			r.wind = Vector2(-1, -3.0 * e)
			r.halo = 1.0 + 0.45 * e
			r.glint = 1.0 if e >= 1.0 else 0.0
		"guard":
			r.hip = Vector2(-1, -17.5)
			r.foot_f = Vector2(5, 0)
			r.foot_b = Vector2(-6, 0)
			r.hand_f = Vector2(8, -29)
			r.hand_b = Vector2(3, -17)
			r.butt = Vector2(-1, -4)
			r.tip = Vector2(17, -50)
			r.wind = Vector2(-2, 0)
			r.halo = 1.2
		"hurt":
			var k := clampf(1.0 - pt / 0.35, 0.0, 1.0)
			r.hip = Vector2(-2.0 * k - 0.5, -18.5)
			r.lean = -0.28 * k - 0.05
			r.foot_f = Vector2(4, 0)
			r.foot_b = Vector2(-4, 0)
			r.hand_f = Vector2(5, -19)
			r.hand_b = Vector2(-8, -20)
			r.butt = Vector2(15, -4)
			r.tip = Vector2(-6, -50)
			r.head = Vector2(-1, 0.5)
			r.tilt = -0.25 * k
			r.wind = Vector2(4, -1)
			r.amp = 1.5
			r.glint = 0.0
		"kneel":
			r.hip = Vector2(-1, -10.5 + br * 0.2)
			r.lean = 0.12
			r.foot_f = Vector2(6, 0)
			r.foot_b = Vector2(-12, 0)
			r.knee_f = Vector2(6.5, -9.5)
			r.knee_b = Vector2(-3.5, -1.8)
			r.hand_f = Vector2(8, -17)
			r.hand_b = Vector2(4, -12)
			r.butt = Vector2(10, 2)
			r.tip = Vector2(10, -54)
			r.head = Vector2(1, 1.5)
			r.tilt = 0.35
			r.wind = Vector2(-1, 0)
			r.halo = 0.8
		"down":
			r.hip = Vector2(0, -19)
			r.hand_f = Vector2(6, -15)
			r.hand_b = Vector2(-6, -16)
			r.butt = Vector2(10, 14)
			r.tip = Vector2(10, -42)
			r.tilt = 0.2
			r.wind = Vector2(0, 2)
			r.amp = 0.3
			r.halo = 0.6
			r.glint = 0.0
		"special":
			var k := clampf(pt / 0.5, 0.0, 1.0)
			var e := k * k * (3.0 - 2.0 * k)
			r.hip = Vector2(0, -19 - 3.0 * e + sin(t * 2.0) * 0.6)
			r.lean = -0.1 * e
			r.foot_f = Vector2(1.5, -3.0 * e)
			r.foot_b = Vector2(-1.5, -1.5 * e)
			r.hand_f = Vector2(7, -21).lerp(Vector2(3, -47), e)
			r.hand_b = Vector2(-4.5, -18).lerp(Vector2(0, -43), e)
			r.butt = Vector2(7.5, 3).lerp(Vector2(2, -22), e)
			r.tip = Vector2(7.5, -53).lerp(Vector2(2, -80), e)
			r.wind = Vector2(0, -4.0 * e)
			r.halo = 1.0 + 0.9 * e
			r.amp = 1.6
			r.glint = 1.0
		_:
			if v.walking:
				var ph2 := v.walk_phase()
				var s2 := sin(ph2)
				r.hip = Vector2(0, -19 - absf(cos(ph2)) * 0.6)
				r.lean = 0.04
				r.foot_f = Vector2(s2 * 4.0, -maxf(cos(ph2), 0.0) * 2.0)
				r.foot_b = Vector2(-s2 * 4.0, -maxf(-cos(ph2), 0.0) * 2.0)
				r.hand_f = Vector2(7, -21 + s2 * 0.5)
				r.hand_b = Vector2(-4 - s2 * 2.0, -18)
				r.butt = Vector2(7.5, 2 + s2 * 0.5)
				r.tip = Vector2(7.5, -54 + s2 * 0.5)
				r.wind = Vector2(-2.5, 0)
			else:
				# 창을 고쳐 잡는 대기 동작 (약 5초마다)
				var g := fmod(t, 5.2)
				if g < 0.7:
					var k3 := sin(g / 0.7 * PI)
					var hf: Vector2 = r.hand_f
					r.hand_f = hf + Vector2(0.5, -2.5 * k3)
					r.tip = Vector2(7.5 + 3.0 * k3, -53 - 1.5 * k3)
					r.butt = Vector2(7.5 - 0.5 * k3, 3 - 1.5 * k3)
					r.hand_b = Vector2(-4.5, -18) + Vector2(1.5, -1.0) * k3
	if berserk:
		var w: Vector2 = r.wind
		r.wind = w * 0.6 + Vector2(sin(t * 3.1) * 1.5, -5.0)
		r.amp = float(r.amp) + 1.2
	return r


## 두 마디 팔다리의 관절 위치 (IK). bend: -1 = 무릎이 앞(+x)으로, +1 = 팔꿈치가 뒤·아래로
static func _ik(a: Vector2, b: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := a.distance_to(b)
	if d < 0.01:
		return a + Vector2(0, l1)
	var dmax := l1 + l2 - 0.05
	var dir := (b - a) / d
	if d >= dmax:
		return a + dir * l1 * (d / (l1 + l2))
	var along := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(l1 * l1 - along * along, 0.0))
	var perp := Vector2(-dir.y, dir.x) * bend
	return a + dir * along + perp * h


## 몸통 기준 점 → 화면 점 (엉덩이 기준으로 lean만큼 기울임)
static func _tl(r: Dictionary, p: Vector2) -> Vector2:
	var hip: Vector2 = r.hip
	return hip + p.rotated(float(r.lean))


# ═══════════════════════════════════════════════════════════
# 그리기
# ═══════════════════════════════════════════════════════════

## 윤곽선(1px, 4방향) + 채움
static func _poly(v: CanvasItem, pts: PackedVector2Array, col: Color, outline := true) -> void:
	DrawKit.outlined_poly(v, pts, col, OUTL, outline)


static func _limb(v: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color, outline := true) -> void:
	if outline:
		v.draw_line(a, b, OUTL, w + 2.0)
		v.draw_circle(a, (w + 2.0) * 0.5, OUTL)
		v.draw_circle(b, (w + 2.0) * 0.5, OUTL)
	v.draw_line(a, b, col, w)
	v.draw_circle(a, w * 0.5, col)
	v.draw_circle(b, w * 0.5, col)


static func _draw_rig(v: CharacterVisual, r: Dictionary, t: float, berserk: bool, pose: String) -> void:
	var hip: Vector2 = r.hip
	var foot_f: Vector2 = r.foot_f
	var foot_b: Vector2 = r.foot_b
	var hand_f: Vector2 = r.hand_f
	var hand_b: Vector2 = r.hand_b
	var butt: Vector2 = r.butt
	var tip: Vector2 = r.tip
	var wind: Vector2 = r.wind
	var trim := GOLD.lerp(WHITE_FIRE, 0.45) if berserk else GOLD
	var head := _tl(r, Vector2(1.0, -18.0)) + (r.head as Vector2)
	var tilt := float(r.tilt)
	var sh_f := _tl(r, Vector2(3.6, -10.5))
	var sh_b := _tl(r, Vector2(-3.4, -10.5))
	var hip_f := _tl(r, Vector2(1.6, -0.5))
	var hip_b := _tl(r, Vector2(-1.6, -0.5))
	var knee_f: Vector2 = r.knee_f if r.has("knee_f") else _ik(hip_f, foot_f + Vector2(0, -1.5), THIGH, SHIN, -1.0)
	var knee_b: Vector2 = r.knee_b if r.has("knee_b") else _ik(hip_b, foot_b + Vector2(0, -1.5), THIGH, SHIN, -1.0)
	var elb_f := _ik(sh_f, hand_f, UPPER_ARM, FOREARM, 1.0)
	var elb_b := _ik(sh_b, hand_b, UPPER_ARM, FOREARM, 1.0)

	# 등 뒤 은은한 윤곽 빛 (어두운 배경에서 분리)
	v.draw_circle(Vector2(hip.x, -22), 22.0, Color(1.0, 0.9, 0.6, 0.05 if not berserk else 0.09))
	# 광륜
	var halo_scale := float(r.halo) * (float(v.get_meta("halo")) if v.has_meta("halo") else 1.0)
	_halo(v, head + Vector2(-3.8, -1.5).rotated(tilt), 8.5 * halo_scale, t, berserk)
	if pose == "down":
		_spear(v, butt, tip, 0.0, 0.0, berserk, trim)
	# 머리카락 뒤쪽 (허리까지)
	_hair_back(v, head, hip, wind, float(r.amp), t, tilt, berserk)
	# 뒷팔
	_arm(v, sh_b, elb_b, hand_b, true, trim)
	# 뒷다리
	_leg(v, hip_b, knee_b, foot_b, true, trim)
	# 뒤쪽 치마 천 (바람에 흩날림)
	_skirt_back(v, r, wind, t, float(r.skirt))
	# 몸통
	_torso(v, r, t, trim, berserk)
	# 앞다리
	_leg(v, hip_f, knee_f, foot_f, false, trim)
	# 앞쪽 치마 판
	_skirt_front(v, r, wind, t, float(r.skirt), trim)
	# 머리
	_head(v, head, tilt, t, berserk, wind, float(r.amp), pose)
	# 앞팔 + 창 (+ 창 쥔 주먹을 위에)
	_arm(v, sh_f, elb_f, hand_f, false, trim)
	if pose != "down":
		_spear(v, butt, tip, float(r.glint), float(r.danger), berserk, trim)
		_fist(v, hand_f, trim)
		if hand_b.distance_to(_closest_on(butt, tip, hand_b)) < 2.5:
			_fist(v, hand_b, trim)
	# 앞 어깨갑
	_pauldron(v, sh_f + Vector2(0.3, 0.3), trim, false)
	if berserk:
		_berserk_fire(v, r, head, hand_f, tip, t)


static func _closest_on(a: Vector2, b: Vector2, p: Vector2) -> Vector2:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.001:
		return a
	return a + ab * clampf((p - a).dot(ab) / l2, 0.0, 1.0)


# ─── 광륜 ───────────────────────────────────────────────

static func _halo(v: CanvasItem, c: Vector2, rad: float, t: float, berserk: bool) -> void:
	var gold := Color(1.0, 0.86, 0.45)
	var pulse := 0.85 + 0.15 * sin(t * 2.4)
	for i in 4:
		v.draw_circle(c, rad * (1.9 - i * 0.25), Color(gold if not berserk else WHITE_FIRE, (0.03 + i * 0.018) * pulse))
	v.draw_circle(c, rad * 0.98, Color(1.0, 0.93, 0.66, 0.2 * pulse))
	if not berserk:
		v.draw_arc(c, rad, 0, TAU, 32, Color(OUTL, 0.55), 3.0)
		v.draw_arc(c, rad, 0, TAU, 32, gold, 1.6)
		v.draw_arc(c, rad * 0.72, 0, TAU, 24, Color(gold, 0.6), 1.0)
		for i in 16:
			var a := t * 0.7 + TAU * i / 16.0
			var l1 := rad * 1.08
			var l2 := rad * (1.3 if i % 2 == 0 else 1.18)
			v.draw_line(c + Vector2(cos(a), sin(a)) * l1, c + Vector2(cos(a), sin(a)) * l2, Color(gold, 0.85), 1.0)
		# 고리를 따라 도는 반짝임
		var sa := t * 1.6
		v.draw_circle(c + Vector2(cos(sa), sin(sa)) * rad, 1.4, Color(1, 1, 0.9, 0.95))
		return
	# 폭주: 금 간 광륜 — 끊어진 고리, 틈에서 새는 흰빛, 떨어져 떠도는 조각
	var gaps: Array[float] = [0.6, 2.3, 4.4]
	for i in gaps.size():
		var a0 := gaps[i] + 0.22
		var a1 := gaps[(i + 1) % gaps.size()] - 0.22 + (TAU if i == gaps.size() - 1 else 0.0)
		var jit := sin(t * 23.0 + i) * 0.6
		v.draw_arc(c + Vector2(jit, 0), rad, a0, a1, 12, Color(OUTL, 0.5), 3.0)
		v.draw_arc(c + Vector2(jit, 0), rad, a0, a1, 12, Color(1.0, 0.95, 0.75), 1.6)
	for i in gaps.size():
		var a := gaps[i]
		var p := c + Vector2(cos(a), sin(a)) * rad
		var flick := 0.6 + 0.4 * sin(t * 17.0 + i * 2.0)
		v.draw_circle(p, 3.0, Color(1, 1, 1, 0.35 * flick))
		v.draw_line(p, p + Vector2(cos(a), sin(a)) * (5.0 + 3.0 * flick), Color(1, 1, 1, 0.8 * flick), 1.0)
		v.draw_polyline(PackedVector2Array([c + Vector2(cos(a), sin(a)) * rad * 0.3, c + Vector2(cos(a + 0.2), sin(a + 0.2)) * rad * 0.55, c + Vector2(cos(a - 0.1), sin(a - 0.1)) * rad * 0.8, p]), Color(1, 1, 1, 0.9), 1.0)
		var frag := p + Vector2(cos(a), sin(a)) * (3.0 + sin(t * 3.0 + i) * 1.5) + Vector2(0, sin(t * 2.0 + i) * 1.0)
		v.draw_rect(Rect2(frag - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.93, 0.7))
	for i in 12:
		var a := -t * 1.3 + TAU * i / 12.0
		v.draw_line(c + Vector2(cos(a), sin(a)) * rad * 1.1, c + Vector2(cos(a), sin(a)) * rad * (1.25 + 0.15 * sin(t * 9.0 + i)), Color(1, 1, 1, 0.6), 1.0)


# ─── 머리카락 ───────────────────────────────────────────

static func _strand(root: Vector2, end: Vector2, wind: Vector2, t: float, k: float, amp: float, n := 7) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var s := float(i) / float(n - 1)
		var sway := sin(t * 2.3 + s * 3.2 + k) * amp * s + sin(t * 5.1 + k * 2.0) * 0.3 * amp * s * s
		pts.append(root.lerp(end, s) + wind * pow(s, 1.4) + Vector2(sway, 0))
	return pts


static func _hair_back(v: CanvasItem, head: Vector2, hip: Vector2, wind: Vector2, amp: float, t: float, tilt: float, berserk: bool) -> void:
	var base := HAIR.lerp(Color(1.0, 0.95, 0.8), 0.35) if berserk else HAIR
	var shade := HAIR_S.lerp(Color(1.0, 0.9, 0.7), 0.3) if berserk else HAIR_S
	var end_y := maxf(hip.y + 1.5, head.y + 10.0)
	var outer := _strand(head + Vector2(-1.5, -5.0).rotated(tilt), Vector2(head.x - 8.5, end_y), wind, t, 0.0, amp)
	var inner := _strand(head + Vector2(-1.0, 4.0).rotated(tilt), Vector2(head.x - 3.0, end_y - 1.0), wind * 0.85, t, 0.7, amp * 0.8)
	var mass := PackedVector2Array()
	mass.append(head + Vector2(0.5, -5.2).rotated(tilt))
	for p in outer:
		mass.append(p)
	for i in range(inner.size() - 1, -1, -1):
		mass.append(inner[i])
	_poly(v, mass, base)
	# 그늘 가닥과 빛 가닥 (따로 흔들림)
	var s1 := _strand(head + Vector2(-3.5, -1.0).rotated(tilt), Vector2(head.x - 6.0, end_y + 0.5), wind, t, 1.4, amp * 1.1)
	v.draw_polyline(s1, shade, 2.0)
	var s2 := _strand(head + Vector2(-2.0, -3.5).rotated(tilt), Vector2(head.x - 7.5, end_y - 4.0), wind * 1.05, t, 2.3, amp)
	v.draw_polyline(s2, HAIR_L if not berserk else WHITE_FIRE, 1.0)
	var s3 := _strand(head + Vector2(-1.5, 2.0).rotated(tilt), Vector2(head.x - 4.5, end_y - 2.0), wind * 0.9, t, 3.1, amp * 0.9)
	v.draw_polyline(s3, HAIR_D if not berserk else shade, 1.0)
	# 끝이 세 갈래로 갈라짐
	var tipc := outer[outer.size() - 1]
	var tipi := inner[inner.size() - 1]
	for i in 3:
		var p := tipc.lerp(tipi, (i + 0.5) / 3.0)
		var tw := sin(t * 3.0 + i * 1.7) * 0.8 * amp
		var tipdir := (wind.normalized() * 0.6 + Vector2(0, 1)).normalized() if wind.length() > 0.1 else Vector2(0, 1)
		v.draw_colored_polygon(PackedVector2Array([p + Vector2(-1.2, -1), p + Vector2(1.2, -1), p + tipdir * 3.0 + Vector2(tw, 0)]), base if i != 1 else shade)


# ─── 몸통·팔다리·치마 ──────────────────────────────────

static func _torso(v: CanvasItem, r: Dictionary, t: float, trim: Color, berserk: bool) -> void:
	# 흉갑 (몸통 기준 좌표: 엉덩이가 원점, 위가 -y)
	var plate := PackedVector2Array()
	for p: Vector2 in [Vector2(-3.6, -12.2), Vector2(3.4, -12.2), Vector2(4.8, -9.5), Vector2(4.4, -5.0), Vector2(3.2, -1.4), Vector2(-3.0, -1.4), Vector2(-4.2, -5.0), Vector2(-4.4, -9.5)]:
		plate.append(_tl(r, p))
	_poly(v, plate, ARM)
	# 그늘 (등 쪽)
	var shade := PackedVector2Array()
	for p: Vector2 in [Vector2(-3.6, -12.2), Vector2(-1.0, -12.2), Vector2(-1.4, -1.4), Vector2(-3.0, -1.4), Vector2(-4.2, -5.0), Vector2(-4.4, -9.5)]:
		shade.append(_tl(r, p))
	v.draw_colored_polygon(shade, ARM_S)
	# 빛 (가슴 앞쪽 윗부분)
	var light := PackedVector2Array()
	for p: Vector2 in [Vector2(1.6, -11.4), Vector2(3.6, -10.6), Vector2(4.2, -8.0), Vector2(2.4, -7.2)]:
		light.append(_tl(r, p))
	v.draw_colored_polygon(light, ARM_L)
	# 금 테두리: 목둘레, 가운데 능선, 아래 끝
	v.draw_line(_tl(r, Vector2(-3.2, -12.0)), _tl(r, Vector2(3.2, -12.0)), trim, 1.0)
	v.draw_line(_tl(r, Vector2(0.6, -11.5)), _tl(r, Vector2(0.4, -2.5)), Color(trim, 0.75), 1.0)
	v.draw_line(_tl(r, Vector2(-3.0, -1.8)), _tl(r, Vector2(3.2, -1.8)), trim, 1.0)
	# 가슴의 해 문양
	var sun := _tl(r, Vector2(1.8, -8.4))
	v.draw_circle(sun, 1.4, trim)
	v.draw_circle(sun, 0.7, GOLD_L if not berserk else Color.WHITE)
	# 목·목가리개
	v.draw_rect(Rect2(_tl(r, Vector2(-0.6, -14.2)), Vector2(2.2, 2.2)), SKIN_S)
	v.draw_line(_tl(r, Vector2(-2.6, -12.6)), _tl(r, Vector2(2.8, -12.6)), GOLD_S, 2.0)
	v.draw_line(_tl(r, Vector2(-2.4, -13.0)), _tl(r, Vector2(2.6, -13.0)), trim, 1.0)
	# 허리띠 + 보석
	v.draw_line(_tl(r, Vector2(-3.4, -0.6)), _tl(r, Vector2(3.6, -0.6)), OUTL, 3.0)
	v.draw_line(_tl(r, Vector2(-3.2, -0.6)), _tl(r, Vector2(3.4, -0.6)), GOLD_S, 2.0)
	v.draw_line(_tl(r, Vector2(-3.2, -1.0)), _tl(r, Vector2(3.4, -1.0)), trim, 1.0)
	var gem := _tl(r, Vector2(2.0, -0.6))
	v.draw_rect(Rect2(gem - Vector2(1, 1), Vector2(2, 2)), Color("#5ac8f0") if not berserk else Color.WHITE)
	# 뒤 어깨갑 (몸 뒤쪽이라 몸통 뒤에 반쯤)
	_pauldron(v, _tl(r, Vector2(-3.4, -10.5)) + Vector2(-0.3, 0.2), trim, true)


static func _pauldron(v: CanvasItem, s: Vector2, trim: Color, back: bool) -> void:
	var base := ARM_S if back else ARM
	var top := PackedVector2Array([s + Vector2(-3.4, 0.8), s + Vector2(-2.6, -2.2), s + Vector2(0.0, -3.2), s + Vector2(2.8, -2.4), s + Vector2(3.8, 0.6), s + Vector2(2.6, 2.6), s + Vector2(-2.4, 2.6)])
	_poly(v, top, base)
	v.draw_line(s + Vector2(-2.8, 2.4), s + Vector2(2.6, 2.4), trim, 1.0)
	if not back:
		v.draw_line(s + Vector2(-1.6, -2.0), s + Vector2(1.6, -2.6), ARM_L, 1.0)
		v.draw_colored_polygon(PackedVector2Array([s + Vector2(-2.6, 2.6), s + Vector2(2.4, 2.6), s + Vector2(1.6, 4.6), s + Vector2(-1.8, 4.4)]), ARM_S)
		v.draw_line(s + Vector2(-1.8, 4.4), s + Vector2(1.6, 4.6), trim, 1.0)
		v.draw_circle(s + Vector2(0.4, -0.2), 0.8, trim)


static func _arm(v: CanvasItem, sh: Vector2, el: Vector2, hd: Vector2, back: bool, trim: Color) -> void:
	var c1 := ARM_S if back else ARM
	var c2 := GOLD_S if back else GOLD
	_limb(v, sh, el, 2.6, c1)
	_limb(v, el, hd, 2.6, c2)
	# 팔꿈치 장식 + 손목 테
	v.draw_circle(el, 1.2, trim if not back else GOLD_S)
	var w := hd.lerp(el, 0.3)
	v.draw_circle(w, 1.0, ARM_L if not back else ARM_S)


static func _fist(v: CanvasItem, p: Vector2, trim: Color) -> void:
	v.draw_circle(p, 2.2, OUTL)
	v.draw_circle(p, 1.6, GOLD)
	v.draw_circle(p + Vector2(-0.4, -0.4), 0.7, GOLD_L)


static func _leg(v: CanvasItem, hp: Vector2, kn: Vector2, ft: Vector2, back: bool, trim: Color) -> void:
	var c := ARM_S if back else ARM
	_limb(v, hp, kn, 3.2, CLOTH_S if back else CLOTH)
	_limb(v, kn, ft + Vector2(0, -1.5), 3.0, c)
	# 정강이 금 테 + 무릎 받이
	v.draw_line(kn.lerp(ft, 0.25), kn.lerp(ft, 0.85), Color(trim, 0.7 if not back else 0.4), 1.0)
	v.draw_circle(kn, 1.8, OUTL)
	v.draw_circle(kn, 1.3, trim if not back else GOLD_S)
	# 쇠장화 (앞이 뾰족)
	var boot := PackedVector2Array([ft + Vector2(-2.2, -2.8), ft + Vector2(1.6, -2.8), ft + Vector2(4.2, -0.6), ft + Vector2(4.0, 0.2), ft + Vector2(-2.4, 0.2)])
	_poly(v, boot, GOLD_S if back else GOLD)
	if not back:
		v.draw_line(ft + Vector2(-1.8, -2.4), ft + Vector2(1.4, -2.4), GOLD_L, 1.0)


static func _skirt_back(v: CanvasItem, r: Dictionary, wind: Vector2, t: float, flare: float) -> void:
	var a := _tl(r, Vector2(-3.4, -0.4))
	var b := _tl(r, Vector2(1.0, -0.4))
	var hip: Vector2 = r.hip
	var sw := sin(t * 2.0) * 0.6
	var drift := wind * (0.45 + 0.2 * flare)
	var low := hip + Vector2(-2.5, 11.0)
	var pts := PackedVector2Array([a, b, low + Vector2(3.5 + sw, 0) + drift * 0.6, low + Vector2(-1.0 + sw, 1.0) + drift, low + Vector2(-5.0, -1.0) + drift * 1.2])
	_poly(v, pts, CLOTH_S)


static func _skirt_front(v: CanvasItem, r: Dictionary, wind: Vector2, t: float, flare: float, trim: Color) -> void:
	var hip: Vector2 = r.hip
	var sw := sin(t * 2.2 + 1.0) * 0.5
	var drift := wind * (0.25 + 0.15 * flare)
	# 하얀 천 두 자락 (앞·옆)
	var f0 := _tl(r, Vector2(0.2, -0.4))
	var f1 := _tl(r, Vector2(4.0, -0.6))
	var fl := hip + Vector2(4.5 + sw, 9.0) + drift * 0.5
	var fr := hip + Vector2(0.5 + sw, 9.5) + drift
	_poly(v, PackedVector2Array([f0, f1, fl + Vector2(1.0, 0), fl + Vector2(-1.0, 1.0), fr]), CLOTH)
	v.draw_line(fl + Vector2(-1.0, 1.0), fr, trim, 1.0)
	var s0 := _tl(r, Vector2(-3.4, -0.4))
	var sl := hip + Vector2(-4.0 + sw, 8.0) + drift * 1.1
	_poly(v, PackedVector2Array([s0, _tl(r, Vector2(0.4, -0.4)), hip + Vector2(0.0, 8.5) + drift * 0.8, sl]), CLOTH_S.lerp(CLOTH, 0.5))
	# 엉덩이 판갑 (허리띠 아래 두 장)
	var t0 := _tl(r, Vector2(-3.4, -0.2))
	var t1 := _tl(r, Vector2(3.8, -0.2))
	var t2 := _tl(r, Vector2(4.2, 3.0))
	var t3 := _tl(r, Vector2(-3.0, 3.2))
	_poly(v, PackedVector2Array([t0, t1, t2, t3]), ARM)
	v.draw_line(t3, t2, trim, 1.0)
	v.draw_line(_tl(r, Vector2(0.4, 0.2)), _tl(r, Vector2(0.6, 3.0)), ARM_S, 1.0)


# ─── 머리 ───────────────────────────────────────────────

static func _head(v: CharacterVisual, c: Vector2, tilt: float, t: float, berserk: bool, wind: Vector2, amp: float, pose: String) -> void:
	var rot := func(p: Vector2) -> Vector2: return c + p.rotated(tilt)
	var hair := HAIR.lerp(Color(1.0, 0.95, 0.8), 0.35) if berserk else HAIR
	# 얼굴 (윤곽 + 피부)
	var face := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var rr := 4.5 if sin(a) < 0.3 else 4.2
		var p := Vector2(cos(a) * rr, sin(a) * 4.7)
		if cos(a) > 0.3 and sin(a) > 0.2:
			p += Vector2(0.4, 0.2) # 턱 끝이 살짝 앞으로
		face.append(rot.call(p))
	_poly(v, face, SKIN)
	v.draw_colored_polygon(PackedVector2Array([rot.call(Vector2(-4.3, -1.0)), rot.call(Vector2(-1.5, -1.0)), rot.call(Vector2(-1.0, 4.4)), rot.call(Vector2(-3.4, 3.2))]), SKIN_S)
	# 눈·눈썹·입
	var eye: Vector2 = rot.call(Vector2(2.3, 0.0))
	if berserk:
		v.draw_circle(eye + Vector2(0.5, 0.5), 2.6, Color(1, 1, 1, 0.25 + 0.15 * sin(t * 13.0)))
		v.draw_rect(Rect2(eye, Vector2(2, 2)), Color.WHITE)
		v.draw_line(eye + Vector2(2, 1), eye + Vector2(4.5, 0.5), Color(1, 1, 1, 0.5), 1.0)
	elif v.blinking():
		v.draw_line(eye + Vector2(0, 1.2), eye + Vector2(2.2, 1.2), HAIR_D, 1.0)
	else:
		v.draw_rect(Rect2(eye, Vector2(2, 2)), EYE)
		v.draw_rect(Rect2(eye, Vector2(1, 1)), Color(1, 1, 1, 0.9))
		v.draw_rect(Rect2(eye + Vector2(0, 2), Vector2(2, 0.6)), Color(EYE.darkened(0.4), 0.6))
	# 굳은 눈썹 (안쪽 끝이 낮음)
	var stern := 0.5 if pose in ["windup", "attack", "charge", "special"] or berserk else 0.0
	v.draw_line(rot.call(Vector2(1.0, -2.0 + stern * 0.3)), rot.call(Vector2(3.8, -1.3 + stern)), HAIR_D, 1.0)
	v.draw_rect(Rect2(rot.call(Vector2(4.1, 0.9)), Vector2(1, 1)), SKIN_S)
	var mouth_open := v.talking and int(t * 10.0) % 2 == 0
	if mouth_open or (berserk and int(t * 3.0) % 3 == 0):
		v.draw_rect(Rect2(rot.call(Vector2(2.8, 2.5)), Vector2(1.6, 1.2)), Color("#7a3438"))
	else:
		v.draw_line(rot.call(Vector2(2.6, 2.9)), rot.call(Vector2(3.9, 2.8)), Color("#a05a52"), 1.0)
	# 앞머리 (이마를 덮고 앞으로 두 갈래)
	var bang := PackedVector2Array([
		rot.call(Vector2(-4.6, -1.2)), rot.call(Vector2(-3.6, -4.4)), rot.call(Vector2(-0.6, -5.6)), rot.call(Vector2(2.8, -5.0)),
		rot.call(Vector2(4.8, -2.8)), rot.call(Vector2(4.6, -0.8)), rot.call(Vector2(3.4, -2.2)), rot.call(Vector2(2.2, -0.9)),
		rot.call(Vector2(1.2, -2.6)), rot.call(Vector2(-0.6, -1.6)), rot.call(Vector2(-2.0, -2.6)),
	])
	_poly(v, bang, hair)
	v.draw_line(rot.call(Vector2(-2.6, -4.4)), rot.call(Vector2(1.8, -4.8)), HAIR_L if not berserk else Color.WHITE, 1.0)
	v.draw_line(rot.call(Vector2(3.0, -3.8)), rot.call(Vector2(4.2, -1.6)), HAIR_S, 1.0)
	# 귀 앞으로 흘러내린 옆머리 한 가닥 (흔들림)
	var lock := _strand(rot.call(Vector2(-1.6, -2.0)), rot.call(Vector2(-1.2, 6.0)), wind * 0.25, t, 4.0, amp * 0.5, 5)
	v.draw_polyline(lock, OUTL, 2.8)
	v.draw_polyline(lock, hair, 1.6)
	v.draw_line(lock[1], lock[3], HAIR_L if not berserk else Color.WHITE, 1.0)
	# 땋아 올린 왕관 머리 (정수리를 두르는 땋은 고리)
	for i in 9:
		var a := PI * 1.05 + PI * 0.9 * float(i) / 8.0
		var p: Vector2 = rot.call(Vector2(cos(a) * 4.9, sin(a) * 4.9 - 0.6))
		v.draw_circle(p, 1.6, OUTL)
	for i in 9:
		var a := PI * 1.05 + PI * 0.9 * float(i) / 8.0
		var p: Vector2 = rot.call(Vector2(cos(a) * 4.9, sin(a) * 4.9 - 0.6))
		v.draw_circle(p, 1.2, HAIR_S if i % 2 == 0 else hair)
		v.draw_rect(Rect2(p + Vector2(-0.5, -1.0), Vector2(1, 1)), HAIR_L if not berserk else Color.WHITE)
	# 금 머리핀
	var pin: Vector2 = rot.call(Vector2(-3.6, -3.8))
	v.draw_circle(pin, 1.0, GOLD_L)


# ─── 창 ─────────────────────────────────────────────────

static func _spear(v: CanvasItem, butt: Vector2, tip: Vector2, glint: float, danger: float, berserk: bool, trim: Color) -> void:
	var len := butt.distance_to(tip)
	if len < 4.0:
		return
	var d := (tip - butt) / len
	var n := Vector2(-d.y, d.x)
	var head_len := 11.0
	var base := tip - d * head_len
	# 자루 (상아빛 + 금 고리)
	v.draw_line(butt, base, OUTL, 3.6)
	v.draw_line(butt, base, SHAFT, 1.8)
	v.draw_line(butt + n * 0.6, base + n * 0.6, SHAFT_S, 0.8)
	var k := 6.0
	while k < len - head_len - 2.0:
		var p := butt + d * k
		v.draw_line(p - n * 1.4, p + n * 1.4, trim, 1.0)
		k += 12.0
	v.draw_circle(butt, 1.6, OUTL)
	v.draw_circle(butt, 1.1, trim)
	# 날개 모양 곁날 (양쪽으로 뒤로 젖혀짐)
	for s: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([base + n * s * 1.0, base + n * s * 3.6 + d * 1.0, base + n * s * 6.4 - d * 2.6, base + n * s * 5.0 - d * 4.6, base + n * s * 2.6 - d * 2.4, base - d * 1.8 + n * s * 1.0])
		_poly(v, wing, trim)
		v.draw_line(base + n * s * 2.0, base + n * s * 5.6 - d * 2.4, GOLD_L if not berserk else Color.WHITE, 1.0)
	# 가운데 잎 모양 날
	var leaf := PackedVector2Array([base + n * 1.6, base + d * 4.0 + n * 2.6, tip, base + d * 4.0 - n * 2.6, base - n * 1.6])
	_poly(v, leaf, BLADE)
	v.draw_colored_polygon(PackedVector2Array([base + d * 4.0 - n * 2.6, tip, base - n * 1.6]), BLADE_S)
	v.draw_line(base + d * 0.5, tip - d * 1.0, Color.WHITE, 1.0)
	# 날 밑 금 받침
	v.draw_circle(base, 2.0, OUTL)
	v.draw_circle(base, 1.5, trim)
	v.draw_circle(base, 0.6, Color("#5ac8f0") if not berserk else Color.WHITE)
	# 예고(붉은 빛) — 공격 직전 창끝이 붉게 번쩍임
	if danger > 0.0:
		v.draw_line(base - d * 2.0, tip + d * 2.0, Color(DANGER, 0.35 * danger), 6.0)
		v.draw_circle(tip, 2.0 + 2.5 * danger, Color(DANGER, 0.55 * danger))
		v.draw_circle(tip, 1.2, Color(1.0, 0.85, 0.8, danger))
	# 빛 반사가 날을 따라 지나감
	if glint > 0.0:
		var gp := base.lerp(tip, 1.0 - glint)
		v.draw_line(gp - n * 2.5, gp + n * 2.5, Color(1, 1, 1, 0.9 * glint), 1.0)
		v.draw_line(gp - d * 2.5, gp + d * 2.5, Color(1, 1, 1, 0.9 * glint), 1.0)
		v.draw_circle(gp, 1.6, Color(1, 1, 0.92, 0.6 * glint))
	if berserk:
		v.draw_line(base, tip, Color(1, 1, 1, 0.3), 4.0)


# ─── 폭주: 흰금 불꽃 ───────────────────────────────────

static func _berserk_fire(v: CanvasItem, r: Dictionary, head: Vector2, hand: Vector2, tip: Vector2, t: float) -> void:
	var hip: Vector2 = r.hip
	var spots: Array[Vector2] = [
		head + Vector2(-4, -5), head + Vector2(-7, 2), _tl(r, Vector2(-4, -10)), _tl(r, Vector2(4, -10)),
		hip + Vector2(-3, 6), hip + Vector2(4, 7), hand, tip, head + Vector2(2, -6),
	]
	for i in spots.size():
		var p := spots[i]
		var k := fmod(t * 2.2 + i * 0.37, 1.0)
		var h := 4.0 + 3.0 * sin(t * 11.0 + i * 1.9)
		var sway := sin(t * 7.0 + i) * 1.2
		var base := p + Vector2(0, -k * 3.0)
		var a := 0.75 * (1.0 - k * 0.6)
		v.draw_colored_polygon(PackedVector2Array([base + Vector2(-2.0, 0), base + Vector2(sway, -h), base + Vector2(2.0, 0)]), Color(1.0, 0.9, 0.55, a * 0.7))
		v.draw_colored_polygon(PackedVector2Array([base + Vector2(-1.0, 0), base + Vector2(sway * 0.6, -h * 0.65), base + Vector2(1.0, 0)]), Color(WHITE_FIRE, a))
	for i in 5:
		var k := fmod(t * 0.8 + i * 0.21, 1.0)
		var p := hip + Vector2(sin(i * 2.7) * 8.0, -k * 34.0)
		v.draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, 1.0 - k))
