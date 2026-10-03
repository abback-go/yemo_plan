class_name PlayerVisual
extends Node2D
## 세라를 도형으로 그린다 (docs/prototype.md 13.1절).
## 원점은 발밑, +x가 바라보는 쪽(좌우 반전은 부모 Flip 노드가 처리), 위쪽이 -y.
## 몸 높이 약 32px + 마녀 모자. 자세 값은 Player가 매 프레임 update_pose()로 넘긴다.

const HIP := Vector2(0, -9)
const HAT_TIP_REST := Vector2(-4, -45)

enum Pose { IDLE, RUN, JUMP, FALL, DASH, HURT, STUN, DEAD }

var pose: Pose = Pose.IDLE
var speed_x := 0.0 ## 바라보는 방향 기준 수평 속도 (px/s, 앞으로 갈수록 +)
var speed_y := 0.0
var cast := 0.0 ## 시전 자세 강도 0~1 (화염탄·스킬 발사 직후)
var cast_kind := 0 ## 0 화염탄, 1 불기둥(손이 아래로), 2 화염 폭풍(두 팔 앞으로)
var overload_ratio := 0.0
var overload_fuse := false
var ghost := false ## 대시 잔상용 단색 모드
var ghost_color := Color(1.0, 0.45, 0.25, 0.55)

var _t := 0.0
var _run_phase := 0.0
var _lean := 0.0
var _hat_tip := HAT_TIP_REST
var _hat_vel := Vector2.ZERO
var _cape_flow := 0.0


func update_pose(delta: float) -> void:
	_t += delta
	var run_k := clampf(absf(speed_x) / 112.0, 0.0, 1.0)
	if pose == Pose.RUN:
		_run_phase += delta * (6.0 + 10.0 * run_k)

	var target_lean := 0.0
	match pose:
		Pose.RUN: target_lean = 0.14 * run_k
		Pose.DASH: target_lean = 0.38
		Pose.HURT, Pose.STUN: target_lean = -0.3
		Pose.JUMP: target_lean = 0.05
		Pose.FALL: target_lean = -0.05
	if cast > 0.0 and cast_kind == 0:
		target_lean -= 0.08 * cast # 발사 반동으로 살짝 뒤로
	_lean = lerpf(_lean, target_lean, minf(delta * 18.0, 1.0))

	# 모자 끝: 속도 반대 방향으로 끌려가는 스프링
	var target := HAT_TIP_REST + Vector2(clampf(-speed_x * 0.03, -9, 6), clampf(speed_y * 0.012, -4, 5))
	if pose == Pose.DASH:
		target += Vector2(-6, 3)
	var acc := (target - _hat_tip) * 320.0 - _hat_vel * 13.0
	_hat_vel += acc * delta
	_hat_tip += _hat_vel * delta

	var flow_target := clampf(absf(speed_x) / 160.0 + absf(speed_y) / 400.0, 0.0, 1.2)
	_cape_flow = lerpf(_cape_flow, flow_target, minf(delta * 8.0, 1.0))
	queue_redraw()


func copy_pose_from(other: PlayerVisual) -> void:
	pose = other.pose
	speed_x = other.speed_x
	speed_y = other.speed_y
	cast = other.cast
	cast_kind = other.cast_kind
	_t = other._t
	_run_phase = other._run_phase
	_lean = other._lean
	_hat_tip = other._hat_tip
	_cape_flow = other._cape_flow


# ─── 그리기 ──────────────────────────────────────────────

func _c(col: Color) -> Color:
	return ghost_color if ghost else col


## 상체 점: 엉덩이 기준으로 기울이고 숨쉬기만큼 들썩인다
func _u(p: Vector2) -> Vector2:
	var bob := 0.0
	match pose:
		Pose.IDLE: bob = sin(_t * 3.0) * 0.6
		Pose.RUN: bob = -absf(sin(_run_phase)) * 1.2
	return HIP + (p - HIP).rotated(_lean) + Vector2(0, bob)


func _draw() -> void:
	var tip_col := Palette.HAIR_TIP.lerp(Palette.HAIR_GLOW, overload_ratio)
	if overload_ratio >= 0.7 or overload_fuse:
		var flick := 0.5 + 0.5 * sin(_t * (30.0 if overload_fuse else 14.0))
		tip_col = tip_col.lerp(Palette.FIRE_CORE, flick * (0.8 if overload_fuse else 0.45))
		if not ghost:
			var aura := Color(Palette.FIRE_OUT, 0.18 + 0.18 * flick)
			draw_circle(_u(Vector2(-1, -24)), 9.0 + flick * 2.0, aura)

	if not ghost:
		# 배경과 분리되도록 몸 뒤에 은은한 불빛
		draw_circle(_u(Vector2(0, -20)), 15.0, Color(Palette.FIRE_OUT, 0.07))
		draw_circle(_u(Vector2(0, -22)), 10.0, Color(Palette.FIRE_MID, 0.05))
	_draw_cape()
	_draw_legs()
	_draw_back_arm()
	_draw_body()
	_draw_head(tip_col)
	_draw_front_arm()
	_draw_hat()


func _draw_cape() -> void:
	var sway := sin(_t * 4.0 + _run_phase * 0.5) * (0.6 + _cape_flow)
	var tip_x := -5.0 - _cape_flow * 7.0
	var tip_y := -6.0 - _cape_flow * 4.0 + sway
	var pts := PackedVector2Array([
		_u(Vector2(-1, -21)),
		_u(Vector2(-4, -20)),
		Vector2(tip_x - 2.0, tip_y + 1.0),
		Vector2(tip_x + 3.0, tip_y + 2.5),
		_u(Vector2(0, -12)),
	])
	draw_colored_polygon(pts, _c(Palette.CAPE))
	draw_line(pts[2], pts[3], _c(Palette.CAPE_INNER), 1.0)


func _leg_offsets() -> Array[Vector2]:
	match pose:
		Pose.RUN:
			var s := sin(_run_phase)
			return [Vector2(s * 4.0, -absf(cos(_run_phase)) * 2.0), Vector2(-s * 4.0, -absf(sin(_run_phase + 1.57)) * 2.0)]
		Pose.JUMP:
			return [Vector2(2, -3), Vector2(-2, -1)]
		Pose.FALL:
			return [Vector2(3, -1), Vector2(-3, 0)]
		Pose.DASH:
			return [Vector2(4, -2), Vector2(-5, -1)]
		Pose.HURT, Pose.STUN:
			return [Vector2(-2, 0), Vector2(2, -1)]
	return [Vector2(1.5, 0), Vector2(-1.5, 0)]


func _draw_legs() -> void:
	var offs := _leg_offsets()
	var hip := HIP + Vector2(0, -1)
	for i in 2:
		var foot := Vector2(offs[i].x, offs[i].y)
		var hip_i := hip + Vector2(1.0 if i == 0 else -1.0, 0)
		var col := Palette.BOOT if i == 1 else Palette.BOOT.lightened(0.08)
		draw_line(hip_i, foot + Vector2(0, -2), _c(col), 2.0)
		draw_rect(Rect2(foot + Vector2(-1.5, -2.5), Vector2(4, 2.5)), _c(col))


func _arm_hand(front: bool) -> Vector2:
	if not front:
		match pose:
			Pose.RUN: return _u(Vector2(-3 - sin(_run_phase) * 3.0, -13))
			Pose.DASH: return _u(Vector2(-7, -17))
			Pose.HURT, Pose.STUN: return _u(Vector2(-6, -24))
		return _u(Vector2(-3, -13))
	if cast > 0.0:
		var aim := Vector2(11, -19)
		if cast_kind == 1:
			aim = Vector2(8, -11)
		elif cast_kind == 2:
			aim = Vector2(12, -17)
		return _u(Vector2(3, -13).lerp(aim, clampf(cast * 1.6, 0.0, 1.0)))
	match pose:
		Pose.RUN: return _u(Vector2(3 + sin(_run_phase) * 3.0, -13))
		Pose.JUMP: return _u(Vector2(6, -22))
		Pose.FALL: return _u(Vector2(7, -20))
		Pose.DASH: return _u(Vector2(8, -15))
		Pose.HURT, Pose.STUN: return _u(Vector2(5, -25))
	return _u(Vector2(3.5, -13))


func _draw_back_arm() -> void:
	var shoulder := _u(Vector2(-2, -20))
	var hand := _arm_hand(false)
	if cast > 0.0 and cast_kind == 2:
		hand = _u(Vector2(10, -15))
	draw_line(shoulder, hand, _c(Palette.ROBE.darkened(0.25)), 2.0)
	draw_rect(Rect2(hand - Vector2(1, 1), Vector2(2, 2)), _c(Palette.SKIN.darkened(0.2)))


func _draw_body() -> void:
	var hem_sway := 0.0
	if pose == Pose.RUN:
		hem_sway = sin(_run_phase) * 1.0
	elif pose == Pose.JUMP or pose == Pose.FALL:
		hem_sway = -1.0
	var robe := PackedVector2Array([
		_u(Vector2(-3, -21)),
		_u(Vector2(3, -21)),
		_u(Vector2(4, -15)),
		Vector2(7 + hem_sway, -7),
		Vector2(-7 + hem_sway * 0.5 - _cape_flow, -7),
		_u(Vector2(-4, -15)),
	])
	draw_colored_polygon(robe, _c(Palette.ROBE))
	# 앞섶 밝은 면과 붉은 밑단
	draw_colored_polygon(PackedVector2Array([
		_u(Vector2(1, -21)), _u(Vector2(3, -21)), _u(Vector2(4, -15)), Vector2(7 + hem_sway, -7), Vector2(2 + hem_sway, -7),
	]), _c(Palette.ROBE_LIGHT))
	draw_line(Vector2(-7 + hem_sway * 0.5 - _cape_flow, -7.5), Vector2(7 + hem_sway, -7.5), _c(Palette.ROBE_ACCENT), 1.0)
	# 허리끈
	draw_line(_u(Vector2(-4, -15.5)), _u(Vector2(4, -15.5)), _c(Palette.ROBE_ACCENT), 1.0)


func _draw_head(tip_col: Color) -> void:
	var head := _u(Vector2(1, -26))
	# 뒷머리와 머리끝 (붉은 그라데이션 — 폭주할수록 밝아짐)
	var back := _u(Vector2(-3, -22))
	draw_circle(_u(Vector2(-1, -26.5)), 5.6, _c(Palette.HAIR))
	var strands := PackedVector2Array([
		_u(Vector2(-5, -27)), _u(Vector2(-2, -26)), back + Vector2(0, 3), back + Vector2(-3, 5 + _cape_flow), back + Vector2(-5 - _cape_flow * 2.0, 2),
	])
	draw_colored_polygon(strands, _c(Palette.HAIR))
	var tips := PackedVector2Array([
		back + Vector2(0, 3), back + Vector2(-3, 5 + _cape_flow), back + Vector2(-5 - _cape_flow * 2.0, 2), back + Vector2(-2, 1.5),
	])
	draw_colored_polygon(tips, _c(tip_col))
	# 얼굴
	draw_circle(head, 4.6, _c(Palette.SKIN))
	# 앞머리
	draw_colored_polygon(PackedVector2Array([
		_u(Vector2(-4, -30)), _u(Vector2(5, -30.5)), _u(Vector2(5.5, -27.5)), _u(Vector2(3, -28.5)), _u(Vector2(1, -27)), _u(Vector2(-1, -28.5)),
	]), _c(Palette.HAIR))
	draw_line(_u(Vector2(5.2, -28)), _u(Vector2(5.0, -26.5)), _c(tip_col), 1.0)
	# 눈
	if not ghost:
		var blink := fmod(_t, 3.7) < 0.12
		var eye := _u(Vector2(3.4, -26))
		if pose == Pose.HURT or pose == Pose.STUN or pose == Pose.DEAD:
			draw_line(eye + Vector2(-1, -1), eye + Vector2(1, 1), Palette.EYE, 1.0)
		elif blink:
			draw_line(eye + Vector2(-1, 0.5), eye + Vector2(1, 0.5), Palette.EYE, 1.0)
		else:
			draw_rect(Rect2(eye + Vector2(-0.5, -1), Vector2(1.5, 2.5)), Palette.EYE)
			draw_rect(Rect2(eye + Vector2(0.5, -1), Vector2(0.8, 0.8)), Palette.FIRE_CORE)


func _draw_front_arm() -> void:
	var shoulder := _u(Vector2(2, -20))
	var hand := _arm_hand(true)
	draw_line(shoulder, hand, _c(Palette.ROBE_LIGHT), 2.0)
	draw_rect(Rect2(hand - Vector2(1, 1), Vector2(2.5, 2.5)), _c(Palette.SKIN))
	if cast > 0.0 and not ghost:
		var glow := Color(Palette.FIRE_HOT, 0.8 * cast)
		draw_circle(hand + Vector2(1, 0), 2.0 + cast * 2.5, Color(Palette.FIRE_OUT, 0.35 * cast))
		draw_circle(hand + Vector2(1, 0), 1.0 + cast * 1.2, glow)


func _draw_hat() -> void:
	var base_l := _u(Vector2(-5, -30.5))
	var base_r := _u(Vector2(5, -30.5))
	var tip := _u(_hat_tip)
	var mid_r := base_r.lerp(tip, 0.45) + Vector2(1.5, -1)
	var mid_l := base_l.lerp(tip, 0.55) + Vector2(-0.5, 0.5)
	var bend := tip + Vector2(-3, 3) # 끝이 꺾여 내려옴
	var cone := PackedVector2Array([base_l, base_r, mid_r, tip, bend, mid_l])
	draw_colored_polygon(cone, _c(Palette.HAT))
	if not ghost:
		draw_polyline(PackedVector2Array([base_l, mid_l, bend, tip, mid_r, base_r]), Palette.HAT_EDGE, 1.0)
	# 모자 띠
	draw_colored_polygon(PackedVector2Array([
		base_l + Vector2(0.5, -0.5), base_r + Vector2(-0.5, -0.5), base_r + Vector2(-0.3, -2.0), base_l + Vector2(0.7, -2.0),
	]), _c(Palette.HAT_BAND))
	# 챙: 납작한 타원
	var brim_c := _u(Vector2(0.5, -30))
	var brim := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		brim.append(brim_c + Vector2(cos(a) * 11.0, sin(a) * 2.0).rotated(_lean))
	draw_colored_polygon(brim, _c(Palette.HAT))
	draw_line(brim_c + Vector2(-11, 0).rotated(_lean), brim_c + Vector2(11, 0).rotated(_lean), _c(Palette.HAT_EDGE), 1.0)
