class_name AgwiVisual
extends Node2D
## 아귀 그림: 잿빛 남보라의 굶주린 귀신. 굽은 등(갈비뼈가 드러난 가슴 + 부푼 배), 가늘고 아주 긴 팔, 큰 입 속의 희미한 보랏빛.
## 이마에 봉인 부적, 1페이즈엔 목·허리에서 바닥 말뚝까지 보랏빛 봉인 사슬. 2페이즈엔 끊어진 사슬이 매달려 흔들린다.
## 예고: 높게 휩쓸기 = 푸른 띠·푸른 손(팔을 머리 위로, "↓ 엎드려"), 낮게 휩쓸기 = 붉은 띠·붉은 손(팔을 바닥에 끌며, "↑ 뛰어").
## 도약 = 착지 지점 붉은 고리, 그림자 손 = 바닥의 검은 원 + 붉은 테, 탐식 = 두 팔을 활짝 벌리고 붉은 입·눈.
## 세라를 가리지 않도록 세라보다 뒤(z -1)에 그린다.

var enemy: Agwi

const BODY := Color("#34324a")
const BODY_LIGHT := Color("#4f4b68")
const BODY_DARK := Color("#1b1928")
const BELLY := Color("#5a5570")
const RIB := Color("#222034")
const HAIR := Color(0.8, 0.78, 0.9)
const SEAL := Color(0.72, 0.45, 1.0)
const CHAIN := Color(0.6, 0.4, 0.92)
const GLOW := Color(0.78, 0.35, 0.95)
const HIGH_COL := Color(0.35, 0.68, 1.0)
const TALISMAN := Color(0.93, 0.83, 0.45)
const CLAW := Color(0.88, 0.86, 0.94)

## 몸통 윤곽 (오른쪽을 볼 때, 발밑 원점)
const TORSO := [
	Vector2(-18, -46), Vector2(-27, -70), Vector2(-28, -98), Vector2(-20, -122), Vector2(-5, -139),
	Vector2(13, -137), Vector2(28, -127), Vector2(31, -113), Vector2(23, -97), Vector2(15, -80),
	Vector2(9, -62), Vector2(1, -42),
]

const HS := 1.45 ## 머리 그림 배율

var _base := Transform2D.IDENTITY ## 몸 그림 기준 변환 (죽을 때 무너지는 연출)
var _fh := Vector2(40, -6) ## 앞손 (지역 좌표)
var _bh := Vector2(-32, -6) ## 뒷손
var _crouch := 0.0
var _lean := 0.0
var _rear := 0.0


func _process(delta: float) -> void:
	if enemy == null:
		return
	if enemy.is_alive():
		scale.x = enemy.facing
	z_index = -1
	_update_pose(delta)
	if enemy.is_dying():
		modulate.a = 1.0 - 0.8 * enemy.state_progress()


func _update_pose(delta: float) -> void:
	var st := enemy.state
	var k := enemy.state_progress()
	var want_c := 0.0
	var want_l := 0.0
	var want_r := 0.0
	match st:
		Agwi.S.HANDS_WIND:
			want_c = 0.8
		Agwi.S.HANDS:
			want_c = 0.8
		Agwi.S.LEAP_WIND:
			want_c = 1.0
			want_l = 0.2
		Agwi.S.LEAP:
			want_r = 0.4
		Agwi.S.LEAP_REC:
			want_c = 0.9 * (1.0 - k)
			want_l = 0.3
		Agwi.S.GRAB_WIND:
			want_l = -0.7
			want_r = 0.3
		Agwi.S.GRAB:
			want_l = 1.0
		Agwi.S.GRAB_MISS:
			want_l = 1.0
			want_c = 0.6
		Agwi.S.GRAB_EAT:
			want_l = 0.3
		Agwi.S.CHAIN_BREAK:
			if enemy.state_elapsed() < Agwi.CHAIN_SNAP_AT:
				want_l = -0.35 + sin(enemy._t * 40.0) * 0.05
				want_r = 0.2
			else:
				want_r = 1.0
		Agwi.S.FLINCH:
			want_l = -0.6
		Agwi.S.SWEEP_WIND:
			if enemy.sweep_high:
				want_r = 0.5
			else:
				want_c = 0.45
				want_l = 0.25
		Agwi.S.SWEEP:
			want_l = 0.35
		Agwi.S.SPIT_WIND, Agwi.S.SPIT:
			want_r = 0.35
		Agwi.S.DYING:
			want_c = 1.0
			want_l = 0.4
	var rate := delta * (14.0 if st == Agwi.S.GRAB or st == Agwi.S.LEAP_REC or st == Agwi.S.FLINCH else 6.0)
	_crouch = move_toward(_crouch, want_c, rate)
	_lean = move_toward(_lean, want_l, rate)
	_rear = move_toward(_rear, want_r, rate)
	# 손 위치
	var targets := _hand_targets()
	var direct := st == Agwi.S.SWEEP or st == Agwi.S.SWEEP_REC
	_fh = targets[0] if direct else _fh.lerp(targets[0], minf(1.0, delta * 10.0))
	_bh = _bh.lerp(targets[1], minf(1.0, delta * 8.0))


## 몸 높이(0 = 엉덩이, 1 = 어깨)에 따른 자세 이동량
func _off(f: float) -> Vector2:
	return Vector2(_lean * 16.0 * f, -_rear * 14.0 * f + absf(_lean) * 4.0 * f + _crouch * 18.0)


func _hand_targets() -> Array[Vector2]:
	var st := enemy.state
	var t := enemy._t
	var k := enemy.state_progress()
	var step := sin(t * 6.0) * 4.0 if absf(enemy.velocity.x) > 5.0 else 0.0
	var f := Vector2(42 + step, -5)
	var b := Vector2(-34 - step, -5)
	match st:
		Agwi.S.SWEEP_WIND:
			f = to_local(enemy.sweep_hand)
			b = Vector2(-30, -20) if enemy.sweep_high else Vector2(-10, -90)
		Agwi.S.SWEEP, Agwi.S.SWEEP_REC:
			f = to_local(enemy.sweep_hand)
			b = Vector2(-36, -40)
		Agwi.S.INHALE_WIND, Agwi.S.INHALE:
			f = Vector2(84, -3)
			b = Vector2(30, -3)
		Agwi.S.INHALE_REC:
			f = Vector2(70, -3).lerp(Vector2(42, -5), k)
			b = Vector2(30, -3).lerp(Vector2(-34, -5), k)
		Agwi.S.SPIT_WIND, Agwi.S.SPIT:
			f = Vector2(40, -104)
			b = Vector2(20, -96)
		Agwi.S.CHAIN_BREAK:
			if enemy.state_elapsed() < Agwi.CHAIN_SNAP_AT:
				f = Vector2(70, -80 + sin(t * 30.0) * 3.0)
				b = Vector2(-66, -78)
			else:
				f = Vector2(56, -178)
				b = Vector2(-50, -172)
		Agwi.S.HANDS_WIND, Agwi.S.HANDS, Agwi.S.HANDS_REC:
			f = Vector2(44, 0)
			b = Vector2(-26, 0)
		Agwi.S.LEAP_WIND:
			f = Vector2(-10, -40)
			b = Vector2(-44, -30)
		Agwi.S.LEAP:
			f = Vector2(40, -150)
			b = Vector2(-30, -150)
		Agwi.S.LEAP_REC:
			f = Vector2(56, -2)
			b = Vector2(-30, -2)
		Agwi.S.GRAB_WIND:
			f = Vector2(30, -176)
			b = Vector2(-58, -150)
		Agwi.S.GRAB:
			f = Vector2(96, -50)
			b = Vector2(88, -76)
		Agwi.S.GRAB_EAT:
			f = Vector2(58, -76)
			b = Vector2(50, -90)
		Agwi.S.GRAB_MISS:
			f = Vector2(100, -2)
			b = Vector2(78, -2)
		Agwi.S.FLINCH:
			f = Vector2(44, -128)
			b = Vector2(-36, -64)
		Agwi.S.DYING:
			f = Vector2(64, -2)
			b = Vector2(-46, -2)
	var arr: Array[Vector2] = [f, b]
	return arr


## 기준 변환(_base) 위에 위치·회전·배율을 얹어 그리기 시작
func _xf(pos: Vector2, rot: float, sc: Vector2) -> void:
	draw_set_transform_matrix(_base * Transform2D(rot, sc, 0.0, pos))


func _xf_reset() -> void:
	draw_set_transform_matrix(_base)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	_xf(c, 0.0, Vector2(1.0, ry / maxf(rx, 0.01)))
	draw_circle(Vector2.ZERO, rx, col)
	_xf_reset()


func _ring(c: Vector2, r: float, flat: float, col: Color, width: float) -> void:
	_xf(c, 0.0, Vector2(1.0, flat))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, col, width)
	_xf_reset()


func _draw() -> void:
	if enemy == null:
		return
	var t := enemy._t
	var st := enemy.state
	var k := enemy.state_progress()
	var fl := 0.15 if enemy.flash_amount() > 0.0 else 0.0

	# ─ 바닥 예고 (몸보다 뒤) ─
	_draw_sweep_band(t, st, k)
	_draw_leap_marker(t, st)
	for h in enemy.hands:
		_draw_shadow_hand(h, t, false)
	if not enemy.anchored:
		pass # 첫 물리 프레임 전: 말뚝 위치를 아직 모름
	elif enemy.chains_intact:
		for a in enemy.chain_anchors():
			_draw_anchor(to_local(a), t)
	else:
		for a in enemy.chain_anchors():
			_draw_broken_anchor(to_local(a))

	# ─ 몸 ─
	if enemy.is_dying():
		_base = Transform2D(0.0, Vector2(1.0 + 0.15 * k, 1.0 - 0.5 * k), 0.0, Vector2(0, k * 26.0))
		_xf_reset()
	var body := BODY.lerp(Color.WHITE, fl)
	var body_light := BODY_LIGHT.lerp(Color.WHITE, fl)
	var dark := BODY_DARK.lerp(Color.WHITE, fl * 0.5)
	var p2 := not enemy.chains_intact ## 사슬이 끊긴 뒤의 모습 (2페이즈)

	var hip_off := Vector2(0, _crouch * 18.0)
	var fs := Vector2(16, -128) + _off(1.0)
	var bs := Vector2(-2, -133) + _off(1.0)
	# 뒷팔·뒷다리 (어둡게)
	_draw_arm(bs, _bh, dark, body.darkened(0.35), -1.0, false, t)
	_draw_leg(Vector2(-12, -48) + hip_off, Vector2(-28, -26) + hip_off * 0.5 + Vector2(-_crouch * 6.0, 0), Vector2(-20, 0), dark, body.darkened(0.3))

	# 몸통
	var pts := PackedVector2Array()
	for i in TORSO.size():
		var v: Vector2 = TORSO[i]
		var f := clampf((-v.y - 46.0) / 92.0, 0.0, 1.0)
		var br := sin(t * 1.6) * 1.5 * f
		pts.append(v + _off(f) + Vector2(0, -br))
	var outline := PackedVector2Array()
	var cen := Vector2(0, -90) + _off(0.5)
	for v: Vector2 in pts:
		outline.append(v + (v - cen).normalized() * 2.0)
	draw_colored_polygon(outline, Palette.OUTLINE)
	draw_colored_polygon(pts, body)
	# 등 쪽 밝은 면
	draw_polyline(PackedVector2Array([pts[1] + Vector2(3, 0), pts[2] + Vector2(3, 0), pts[3] + Vector2(3, 2), pts[4] + Vector2(2, 3)]), body_light, 3.0)
	# 등뼈 마디
	for i in 5:
		var s := i / 4.0
		var sp := pts[1].lerp(pts[4], s) + Vector2(-1, 0)
		draw_circle(sp, 2.5, body_light)
	# 2페이즈: 등줄기를 따라 보랏빛 불꽃
	if p2:
		for i in 5:
			var s2 := (i + 0.5) / 5.0
			var sp2 := pts[2].lerp(pts[5], s2)
			var hh := 4.0 + 3.0 * sin(t * 12.0 + i * 1.7)
			draw_line(sp2, sp2 + Vector2(-2, -hh), Color(GLOW, 0.75), 2.0)
	# 갈비뼈
	for i in 4:
		var y := -86.0 - i * 8.0
		var a2 := Vector2(-16 + i * 2, y) + _off(clampf((-y - 46.0) / 92.0, 0.0, 1.0))
		var b2 := Vector2(20 - i, y - 5) + _off(clampf((-y - 46.0) / 92.0, 0.0, 1.0))
		draw_line(a2, b2, RIB.lerp(Color.WHITE, fl), 2.0)
	# 부푼 배 (아귀의 상징): 아래로 처진 타원, 갈비뼈 아래로 불룩
	var bc := Vector2(9, -58) + _off(0.15) + Vector2(0, sin(t * 1.6) * 0.8)
	_ellipse(bc, 21.0, 24.0, Palette.OUTLINE)
	_ellipse(bc, 19.0, 22.0, BELLY.lerp(Color.WHITE, fl))
	_ellipse(bc + Vector2(-5, 6), 13.0, 13.0, Color(BODY, 0.55))
	draw_arc(bc + Vector2(2, -4), 13.0, -0.4, 0.9, 8, Color(1, 1, 1, 0.12), 2.0)
	draw_arc(bc, 15.0, 1.2, 2.2, 6, Color(RIB, 0.7), 1.0)
	draw_circle(bc + Vector2(4, 4), 1.5, Color(RIB, 0.9)) # 배꼽
	# 배의 봉인 문양 (2페이즈엔 금이 가고 붉어짐)
	var seal_col := SEAL if not p2 else Color(1.0, 0.35, 0.55)
	var pulse := 0.45 + 0.35 * sin(t * 3.0)
	var sc := bc + Vector2(2, -6)
	draw_arc(sc, 6.0, 0.0, TAU, 16, Color(seal_col, pulse), 1.0)
	draw_line(sc + Vector2(-4, -3), sc + Vector2(4, 3), Color(seal_col, pulse), 1.0)
	draw_line(sc + Vector2(-4, 3), sc + Vector2(4, -3), Color(seal_col, pulse), 1.0)
	if p2:
		draw_polyline(PackedVector2Array([sc + Vector2(-3, -9), sc + Vector2(0, -3), sc + Vector2(-4, 3), sc + Vector2(-1, 10)]), Color(1.0, 0.5, 0.7, 0.9), 1.0)

	# 앞다리
	_draw_leg(Vector2(2, -46) + hip_off, Vector2(20, -24) + hip_off * 0.5 + Vector2(_crouch * 6.0, 0), Vector2(14, 0), Palette.OUTLINE, body)

	# 사슬 (몸 위로 감김)
	var collar := Vector2(26, -118) + _off(0.95)
	var waist := Vector2(-6, -56) + _off(0.1)
	if enemy.chains_intact and enemy.anchored:
		var anchors := enemy.chain_anchors()
		var strain := st == Agwi.S.CHAIN_BREAK
		for i in anchors.size():
			_draw_chain(collar if i < 2 else waist, to_local(anchors[i]), t, strain, i)
		draw_line(collar + Vector2(-6, 2), collar + Vector2(6, -2), CHAIN, 3.0) # 목줄
	elif not enemy.chains_intact:
		_draw_dangling(collar, t, 0.0)
		_draw_dangling(waist, t, 1.7)

	# 머리
	var hc := to_local(enemy.mouth_global()) - Vector2(16, 4) + _off(1.0)
	var neck_a := (pts[6] + pts[7]) * 0.5
	draw_line(neck_a, hc + Vector2(-14, 0), Palette.OUTLINE, 13.0)
	draw_line(neck_a, hc + Vector2(-14, 0), body, 10.0)
	_draw_head(hc, t, st, k, fl, p2)

	# 앞팔 (밝게, 예고 색)
	var glow := Color(0, 0, 0, 0)
	if st == Agwi.S.SWEEP_WIND or st == Agwi.S.SWEEP:
		var gc := HIGH_COL if enemy.sweep_high else Palette.DANGER
		var amt := (0.4 + 0.6 * k) if st == Agwi.S.SWEEP_WIND else 1.0
		glow = Color(gc, amt)
	elif st == Agwi.S.GRAB_WIND or st == Agwi.S.GRAB:
		glow = Color(Palette.DANGER, 0.5 + 0.5 * k)
	_draw_arm(fs, _fh, Palette.OUTLINE, body_light, 1.0, true, t, glow)
	if st == Agwi.S.GRAB_WIND or st == Agwi.S.GRAB:
		# 뒷손도 붉게 (두 팔로 끌어안는 잡기)
		draw_circle(_bh, 10.0, Color(Palette.DANGER, 0.3 * glow.a))

	# 등 위로 피어오르는 재·연기
	for i in 8:
		var ph := fmod(t * 0.35 + i * 0.13, 1.0)
		var sx := lerpf(-24.0, 20.0, fmod(i * 0.37, 1.0)) + sin(t + i) * 3.0
		var base := Vector2(sx, -128.0) + _off(1.0)
		var sz := 3.0 - 2.0 * ph
		draw_rect(Rect2(base + Vector2(0, -ph * 34.0), Vector2(sz, sz)), Color(0.55, 0.45, 0.7, 0.55 * (1.0 - ph)))
	_base = Transform2D.IDENTITY
	_xf_reset()

	# ─ 앞쪽 효과 ─
	if st == Agwi.S.INHALE:
		_draw_inhale(t)
	for h in enemy.hands:
		_draw_shadow_hand(h, t, true)
	for w in enemy.waves:
		_draw_wave(w, t)


# ─── 몸 부분 ────────────────────────────────────────────

func _elbow(a: Vector2, b: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := b - a
	var dist := maxf(d.length(), 0.001)
	var dirv := d / dist
	var perp := Vector2(dirv.y, -dirv.x) * bend
	if dist >= l1 + l2 - 1.0:
		return a + d * (l1 / (l1 + l2)) + perp * 4.0
	var x := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(l1 * l1 - x * x, 0.0))
	return a + dirv * x + perp * h


func _draw_arm(sh: Vector2, hand: Vector2, out_col: Color, col: Color, bend: float, front: bool, t: float, glow := Color(0, 0, 0, 0)) -> void:
	var el := _elbow(sh, hand, 60.0, 64.0, bend)
	var dist := sh.distance_to(hand)
	var thin := clampf(124.0 / maxf(dist, 1.0), 0.45, 1.0)
	var w := (5.0 if front else 4.0) * thin + 1.0
	draw_polyline(PackedVector2Array([sh, el, hand]), out_col, w + 2.0)
	draw_polyline(PackedVector2Array([sh, el, hand]), col, w)
	draw_circle(el, w * 0.7 + 1.0, col) # 마디 굵은 팔꿈치
	if glow.a > 0.0:
		draw_circle(hand, 16.0, Color(glow, 0.22 * glow.a))
		draw_circle(hand, 9.0, Color(glow, 0.45 * glow.a))
	# 손바닥 + 긴 발톱 4개
	draw_circle(hand, 5.5, out_col)
	draw_circle(hand, 4.5, col)
	var base_a := (hand - el).angle()
	var curl := 0.5 + 0.1 * sin(t * 3.0)
	for i in 4:
		var a := base_a + (-0.65 + i * 0.43)
		var p1 := hand + Vector2.from_angle(a) * 8.0
		var p2 := p1 + Vector2.from_angle(a + curl) * 6.0
		draw_polyline(PackedVector2Array([hand, p1, p2]), out_col, 3.0)
		draw_line(hand, p1, col, 1.5)
		draw_line(p1, p2, glow if glow.a > 0.3 else CLAW, 1.0)


func _draw_leg(hip: Vector2, knee: Vector2, foot: Vector2, out_col: Color, col: Color) -> void:
	var step := sin(enemy._t * 6.0) * 5.0 if absf(enemy.velocity.x) > 5.0 and enemy.is_on_floor() else 0.0
	var ft := foot + Vector2(step if foot.x > 0.0 else -step, 0)
	draw_polyline(PackedVector2Array([hip, knee, ft]), out_col, 9.0)
	draw_polyline(PackedVector2Array([hip, knee, ft]), col, 6.0)
	for i in 3:
		draw_line(ft, ft + Vector2(3 + i * 3, 0), CLAW.darkened(0.3), 1.0)


func _draw_head(head_pos: Vector2, t: float, st: Agwi.S, _k: float, fl: float, p2: bool) -> void:
	var open := enemy.mouth_open
	var skull_col := BODY_LIGHT.lerp(Color.WHITE, fl)
	# 머리는 HS배로 크게: 이 안에서는 머리 중심이 원점
	_xf(head_pos, 0.0, Vector2(HS, HS))
	var hc := Vector2.ZERO
	# 늘어진 머리카락 (머리 뒤)
	for i in 7:
		var root := hc + Vector2(-13 + i * 3.5, -12 + absf(i - 3) * 1.0)
		var line := PackedVector2Array([root])
		var hl := 34.0 + 10.0 * fmod(i * 0.53, 1.0)
		for j in 4:
			var s := (j + 1) / 4.0
			line.append(root + Vector2(sin(t * 1.4 + i * 0.9 + s * 2.0) * 3.0 * s - 4.0 * s, hl * s))
		draw_polyline(line, Color(HAIR, 0.55), 1.0)
	# 두개골 + 윗턱
	var skull := PackedVector2Array([
		Vector2(-15, 2), Vector2(-14, -9), Vector2(-6, -17), Vector2(7, -19), Vector2(17, -13),
		Vector2(22, -3), Vector2(20, 2), Vector2(4, 4), Vector2(-6, 4),
	])
	var so := PackedVector2Array()
	for v: Vector2 in skull:
		so.append(hc + v * 1.12)
	draw_colored_polygon(so, Palette.OUTLINE)
	var sk := PackedVector2Array()
	for v: Vector2 in skull:
		sk.append(hc + v)
	draw_colored_polygon(sk, skull_col)
	# 아래턱 (경첩 기준으로 벌어짐)
	var hinge := hc + Vector2(-8, 3)
	var rot := open * 0.8
	var jaw := PackedVector2Array()
	for v: Vector2 in [Vector2(0, 0), Vector2(29, 0), Vector2(27, 5), Vector2(14, 9), Vector2(2, 7)]:
		jaw.append(hinge + v.rotated(rot))
	# 입 속 (희미한 보랏빛)
	var lip_front := hc + Vector2(20, 2)
	var jaw_tip := hinge + Vector2(29, 0).rotated(rot)
	draw_colored_polygon(PackedVector2Array([hinge, lip_front, jaw_tip, hinge + Vector2(14, 0).rotated(rot)]), Color(0.06, 0.01, 0.09))
	var mc := (hinge + lip_front + jaw_tip) / 3.0
	var inner := GLOW
	if st == Agwi.S.SPIT_WIND or st == Agwi.S.SPIT or st == Agwi.S.GRAB_WIND or st == Agwi.S.GRAB:
		inner = GLOW.lerp(Palette.DANGER, 0.6)
	draw_circle(mc, 3.0 + 9.0 * open, Color(inner, 0.18 + 0.3 * open))
	draw_circle(mc, 2.0 + 4.0 * open, Color(inner.lightened(0.3), 0.25 + 0.45 * open))
	if st == Agwi.S.INHALE:
		for i in 2:
			var a0 := -t * 9.0 + i * PI
			draw_arc(mc, 4.0 + 3.0 * i, a0, a0 + 2.2, 8, Color(0.9, 0.8, 1.0, 0.7), 1.0)
	draw_colored_polygon(jaw, Palette.OUTLINE)
	var jaw_in := PackedVector2Array()
	for v: Vector2 in [Vector2(1, 1), Vector2(27, 1), Vector2(25, 4), Vector2(14, 7), Vector2(3, 6)]:
		jaw_in.append(hinge + v.rotated(rot))
	draw_colored_polygon(jaw_in, skull_col.darkened(0.15))
	# 이빨
	for i in 6:
		var u := hc + Vector2(-3 + i * 4, 2)
		draw_line(u, u + Vector2(0, 3), CLAW, 1.0)
		var l := hinge + Vector2(5 + i * 4, 0).rotated(rot)
		draw_line(l, l + Vector2(0, -3).rotated(rot), CLAW, 1.0)
	# 눈: 움푹 꺼진 눈구멍 + 희미한 눈빛 (예고 때 색이 바뀜)
	var eye_col := Color(0.85, 0.75, 1.0)
	var eye_glow := 0.25
	match st:
		Agwi.S.SWEEP_WIND, Agwi.S.SWEEP:
			eye_col = HIGH_COL if enemy.sweep_high else Palette.DANGER
			eye_glow = 0.6
		Agwi.S.GRAB_WIND, Agwi.S.GRAB, Agwi.S.LEAP_WIND, Agwi.S.HANDS_WIND, Agwi.S.SPIT_WIND:
			eye_col = Palette.DANGER
			eye_glow = 0.6
		Agwi.S.FLINCH:
			eye_col = Color(0.6, 0.85, 1.0)
		Agwi.S.CHAIN_BREAK:
			eye_col = Color(1.0, 0.5, 0.8)
			eye_glow = 0.7
	if enemy.is_enraged():
		eye_glow += 0.2
	for e: Vector2 in [Vector2(5, -9), Vector2(13, -8)]:
		draw_circle(hc + e, 3.5, Color(0.03, 0.01, 0.05))
		draw_circle(hc + e, 4.5, Color(eye_col, eye_glow * 0.4))
		draw_rect(Rect2(hc + e + Vector2(-1, -1), Vector2(2, 2)), eye_col)
	# 이마의 봉인 부적 (2페이즈엔 반쯤 찢어짐)
	_xf(head_pos + Vector2(1, -16) * HS, 0.12 + sin(t * 2.5) * 0.08, Vector2(HS, HS))
	var tal_h := 6.0 if p2 else 14.0
	draw_rect(Rect2(-3.5, 0, 7, tal_h), TALISMAN.lerp(Color.WHITE, fl))
	draw_line(Vector2(0, 1), Vector2(0, tal_h - 1), Color(0.75, 0.12, 0.12), 1.0)
	draw_line(Vector2(-2, 3), Vector2(2, 3), Color(0.75, 0.12, 0.12), 1.0)
	if not p2:
		draw_line(Vector2(-2, 8), Vector2(2, 10), Color(0.75, 0.12, 0.12), 1.0)
	_xf_reset()
	# 움찔: 푸른 여우불이 얼굴에 비침
	if st == Agwi.S.FLINCH:
		draw_circle(head_pos + Vector2(6, -4) * HS, 26.0, Color(0.5, 0.8, 1.0, 0.25))


# ─── 사슬 ───────────────────────────────────────────────

func _draw_chain(a: Vector2, b: Vector2, t: float, strain: bool, idx: int) -> void:
	var dist := a.distance_to(b)
	var n := maxi(int(dist / 7.0), 2)
	var dirv := (b - a) / maxf(dist, 0.001)
	var sag := 0.0 if strain else 10.0 + 3.0 * sin(t * 1.3 + idx)
	var jit := Vector2(sin(t * 50.0 + idx), cos(t * 47.0 + idx)) * (1.5 if strain else 0.0)
	var col := CHAIN.lightened(0.35 * (0.5 + 0.5 * sin(t * 20.0))) if strain else CHAIN
	draw_line(a, b, Color(SEAL, 0.25 if strain else 0.1), 5.0 if strain else 3.0)
	for i in n:
		var s := (i + 0.5) / n
		var p := a.lerp(b, s) + Vector2(0, sin(PI * s) * sag) + jit
		if i % 2 == 0:
			draw_rect(Rect2(p - Vector2(3, 2), Vector2(6, 4)), col, false, 1.0)
		else:
			draw_line(p - dirv * 2.5, p + dirv * 2.5, col.darkened(0.2), 2.0)
	# 사슬에 붙은 부적
	var mid := a.lerp(b, 0.45) + Vector2(0, sin(PI * 0.45) * sag)
	draw_rect(Rect2(mid + Vector2(-2, 1), Vector2(4, 8)), TALISMAN)
	draw_line(mid + Vector2(0, 2), mid + Vector2(0, 8), Color(0.75, 0.12, 0.12), 1.0)


func _draw_anchor(a: Vector2, t: float) -> void:
	_ring(a + Vector2(0, -1), 11.0, 0.25, Color(SEAL, 0.45 + 0.2 * sin(t * 2.0)), 1.0)
	draw_rect(Rect2(a + Vector2(-3, -11), Vector2(6, 11)), BODY_DARK)
	draw_rect(Rect2(a + Vector2(-3, -11), Vector2(6, 2)), BODY_LIGHT)
	draw_arc(a + Vector2(0, -12), 3.5, 0.0, TAU, 10, CHAIN, 1.0)


func _draw_broken_anchor(a: Vector2) -> void:
	draw_rect(Rect2(a + Vector2(-3, -11), Vector2(6, 11)), BODY_DARK)
	for i in 3:
		var p := a + Vector2(-8.0 + i * 6.0, -2)
		draw_rect(Rect2(p - Vector2(3, 2), Vector2(6, 4)), CHAIN.darkened(0.3), false, 1.0)


## 끊어진 사슬 토막이 매달려 흔들림
func _draw_dangling(from: Vector2, t: float, ph: float) -> void:
	var sway := sin(t * 2.2 + ph) * 0.35
	var dirv := Vector2(sin(sway), cos(sway))
	for i in 6:
		var p := from + dirv * (4.0 + i * 6.0)
		if i % 2 == 0:
			draw_rect(Rect2(p - Vector2(2, 3), Vector2(4, 6)), CHAIN, false, 1.0)
		else:
			draw_line(p - dirv * 2.5, p + dirv * 2.5, CHAIN.darkened(0.2), 2.0)


# ─── 예고·효과 ──────────────────────────────────────────

func _draw_sweep_band(t: float, st: Agwi.S, k: float) -> void:
	if st != Agwi.S.SWEEP_WIND and st != Agwi.S.SWEEP:
		return
	var high := enemy.sweep_high
	var col := HIGH_COL if high else Palette.DANGER
	var yc := Agwi.SWEEP_HIGH_Y if high else Agwi.SWEEP_LOW_Y
	var hh := Agwi.SWEEP_HIGH_H if high else Agwi.SWEEP_LOW_H
	var a := to_local(Vector2(enemy.sweep_from_x, enemy.floor_y + yc - hh * 0.5))
	var b := to_local(Vector2(enemy.sweep_to_x, enemy.floor_y + yc + hh * 0.5))
	var r := Rect2(a, b - a).abs()
	var floor_l := to_local(Vector2(enemy.sweep_from_x, enemy.floor_y)).y
	if st == Agwi.S.SWEEP_WIND:
		var blink := k > 0.7 and int(t * 16.0) % 2 == 0
		draw_rect(r, Color(col, 0.1 + 0.16 * k + (0.12 if blink else 0.0)))
		draw_line(r.position, r.position + Vector2(r.size.x, 0), Color(col, 0.75), 1.0)
		draw_line(r.position + Vector2(0, r.size.y), r.end, Color(col, 0.75), 1.0)
		# 진행 방향 꺾쇠
		var cy := r.position.y + r.size.y * 0.5
		for i in int(r.size.x / 28.0):
			var x := r.position.x + fmod(i * 28.0 + t * 90.0, r.size.x)
			draw_line(Vector2(x - 3, cy - 4), Vector2(x + 1, cy), Color(col, 0.6), 1.0)
			draw_line(Vector2(x - 3, cy + 4), Vector2(x + 1, cy), Color(col, 0.6), 1.0)
		# 행동 표시: 높게 = 아래 화살표(땅에 붙어라), 낮게 = 위 화살표(뛰어라)
		for i in int(r.size.x / 48.0):
			var x2 := r.position.x + 20.0 + i * 48.0
			if high:
				var y0 := r.end.y + 4.0
				var y1 := floor_l - 4.0
				draw_line(Vector2(x2, y0), Vector2(x2, y1), Color(col, 0.5), 1.0)
				draw_line(Vector2(x2 - 3, y1 - 3), Vector2(x2, y1), Color(col, 0.5), 1.0)
				draw_line(Vector2(x2 + 3, y1 - 3), Vector2(x2, y1), Color(col, 0.5), 1.0)
			else:
				var y2 := r.position.y - 4.0
				var y3 := r.position.y - 16.0 - 4.0 * sin(t * 8.0)
				draw_line(Vector2(x2, y2), Vector2(x2, y3), Color(col, 0.6), 1.0)
				draw_line(Vector2(x2 - 3, y3 + 3), Vector2(x2, y3), Color(col, 0.6), 1.0)
				draw_line(Vector2(x2 + 3, y3 + 3), Vector2(x2, y3), Color(col, 0.6), 1.0)
	else:
		# 휩쓴 자리의 잔상
		var hand_l := to_local(enemy.sweep_hand)
		var tr := Rect2(Vector2(minf(a.x, hand_l.x), r.position.y), Vector2(absf(hand_l.x - a.x), r.size.y))
		draw_rect(tr, Color(col, 0.16))
		draw_rect(Rect2(Vector2(hand_l.x - 24.0, r.position.y), Vector2(24, r.size.y)), Color(col, 0.3))


func _draw_leap_marker(t: float, st: Agwi.S) -> void:
	if st != Agwi.S.LEAP_WIND and st != Agwi.S.LEAP:
		return
	var at := to_local(Vector2(enemy.leap_x, enemy.floor_y))
	var locked := st == Agwi.S.LEAP or enemy._timer <= Agwi.LEAP_LOCK
	var col := Color.WHITE if locked and int(t * 18.0) % 2 == 0 else Palette.DANGER
	_ellipse(at + Vector2(0, -1), 3.0 * 16.0, 4.0, Color(0.0, 0.0, 0.0, 0.35))
	_ring(at + Vector2(0, -1), 3.0 * 16.0, 0.12, Color(col, 0.9), 2.0)
	_ring(at + Vector2(0, -1), 3.0 * 16.0 + 8.0 - 8.0 * fmod(t * 2.0, 1.0), 0.12, Color(Palette.DANGER, 0.5), 1.0)
	for i in 3:
		var y := -30.0 - i * 10.0 - 6.0 * fmod(t * 3.0, 1.0)
		draw_line(at + Vector2(-6, y), at + Vector2(0, y + 5), Color(Palette.DANGER, 0.6), 2.0)
		draw_line(at + Vector2(6, y), at + Vector2(0, y + 5), Color(Palette.DANGER, 0.6), 2.0)


## 그림자 손: front=false면 바닥 예고, true면 솟은 손
func _draw_shadow_hand(h: Agwi.ShadowHand, t: float, front: bool) -> void:
	var base := to_local(Vector2(h.x, h.y))
	if not front:
		var wk := clampf(h.t / Agwi.HAND_WARN, 0.0, 1.0)
		var rx := 13.0 + 6.0 * wk
		_ellipse(base + Vector2(0, -1), rx + 3.0, 4.5, Color(0.0, 0.0, 0.0, 0.55))
		_ellipse(base + Vector2(0, -1), rx, 3.2, Color(0.1, 0.02, 0.16, 0.95))
		if h.t < Agwi.HAND_WARN:
			var blink := wk > 0.65 and int(t * 20.0) % 2 == 0
			var rim := Color.WHITE if blink else Palette.DANGER
			_ring(base + Vector2(0, -1), rx + 4.0, 0.25, rim, 2.0)
			_ring(base + Vector2(0, -1), rx + 12.0 - 8.0 * wk, 0.25, Color(Palette.DANGER, 0.5 * wk), 1.0)
			draw_rect(Rect2(base + Vector2(-11, -48), Vector2(22, 47)), Color(Palette.DANGER, 0.08 + 0.17 * wk))
			# 바닥에서 비죽 나온 손가락 끝
			for i in 3:
				var fx := -6.0 + i * 6.0
				draw_line(base + Vector2(fx, -1), base + Vector2(fx + 1, -2.0 - 4.0 * wk), Color(0.35, 0.2, 0.6), 2.0)
		return
	if h.t < Agwi.HAND_WARN:
		return
	var up_t := h.t - Agwi.HAND_WARN
	var rise := clampf(up_t / 0.08, 0.0, 1.0)
	if up_t > Agwi.HAND_UP:
		rise = 1.0 - clampf((up_t - Agwi.HAND_UP) / Agwi.HAND_DOWN, 0.0, 1.0)
	var hh := 46.0 * rise
	if hh < 1.0:
		return
	var col := Color(0.1, 0.04, 0.18)
	var rim := Color(0.6, 0.35, 0.95)
	draw_rect(Rect2(base + Vector2(-6, -hh + 6), Vector2(12, hh - 6)), col)
	draw_line(base + Vector2(-6, -hh + 6), base + Vector2(-6, 0), rim, 1.0)
	draw_line(base + Vector2(6, -hh + 6), base + Vector2(6, 0), rim, 1.0)
	var palm := base + Vector2(0, -hh + 4)
	draw_circle(palm, 8.0, col)
	for i in 4:
		var a := -PI * 0.5 + (-0.7 + i * 0.47)
		var p1 := palm + Vector2.from_angle(a) * 9.0
		var p2 := p1 + Vector2.from_angle(a + (0.6 if i < 2 else -0.6)) * 7.0
		draw_polyline(PackedVector2Array([palm, p1, p2]), col, 3.0)
		draw_line(p1, p2, rim, 1.0)
	draw_arc(palm, 8.0, PI, TAU, 10, rim, 1.0)


func _draw_wave(w: Agwi.ShockWave, t: float) -> void:
	var base := to_local(Vector2(w.x, w.y))
	var fade := 1.0 - clampf(w.t / Agwi.WAVE_TIME, 0.0, 1.0) * 0.5
	for j in 3:
		var hh := 10.0 + 6.0 * sin(t * 30.0 + j * 2.0 + w.x * 0.1)
		draw_rect(Rect2(base + Vector2(-7 + j * 5, -hh), Vector2(4, hh)), Color(0.12, 0.04, 0.22, fade))
		draw_rect(Rect2(base + Vector2(-7 + j * 5, -hh), Vector2(4, 2)), Color(0.75, 0.45, 1.0, fade))


func _draw_inhale(t: float) -> void:
	var m := to_local(enemy.mouth_global())
	var floor_l := to_local(Vector2(enemy.global_position.x, enemy.floor_y)).y
	for i in 16:
		var ph := fmod(i * 0.137 + t * 1.4, 1.0)
		var d := (1.0 - ph) * 16.0 * 16.0 + 12.0
		var y0 := floor_l - (0.4 + fmod(i * 0.61, 1.0) * 5.0) * 16.0
		var pos := Vector2(m.x + d, lerpf(y0, m.y, ph * ph))
		var dirv := (m - pos).normalized()
		draw_line(pos, pos + dirv * (8.0 + 10.0 * ph), Color(0.8, 0.7, 1.0, 0.12 + 0.4 * ph), 1.0)
	for i in 2:
		var r := 30.0 - fmod(t * 40.0 + i * 15.0, 30.0)
		draw_arc(m, r, -PI * 0.5, PI * 0.5, 12, Color(0.75, 0.55, 1.0, 0.35 * (1.0 - r / 30.0)), 1.0)
