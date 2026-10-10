class_name EArt
extends PDraw.Canvas
## 에스카 코드 그림 v2 (키 약 40px — 모자 포함, 이나리 주인공과 비슷한 화면 비율).
## 컨셉아트 기준: 백발 장발(오른쪽 눈을 덮는 앞머리), 챙 넓은 검은 마녀 모자(챙 끝이 갈라져 흰 공허가 비침),
## 검은 롱드레스(높은 트임, 자락 끝이 갈라져 흰 공허), 회보라 시스루 소매, 보라 안감. 흑백이 바탕이고 보라는 포인트만.
## 원점 = 발밑 가운데, 오른쪽을 보는 모습으로 그리고 scale.x로 뒤집는다.
##
## 살아 움직이는 부분
## - 머리카락·소매·옆머리: 전역 좌표에서 흔들리는 줄(Chain, 베를레 적분 + 길이 제약 + 쉬는 모양으로 당김). 몸이 움직이면 늦게 따라온다.
## - 몸: 늘이고 누르기(점프·착지·타격), 앞으로 기울기(달리기·공격), 모자 끝·치마 자락은 용수철.
## - 눈빛: 빠르게 움직일 때 보랏빛 꼬리를 남긴다.
## - 잔상: 마지막 그림(삼각형 묶음)을 남겨 두고 EVfx.Afterimage가 보라빛으로 그린다.

const OUT := Color("#0a090e")
const CLOTH := Color("#15121b")
const CLOTH_HI := Color("#2b2436")
const CLOTH_EDGE := Color("#3d3450")
const CLOTH_SH := Color("#0e0b13")
const RIM := Color("#5c5470") ## 어두운 배경에서 실루엣이 읽히게 두르는 보랏빛 테두리
const LINING := Color("#4a2f6e")
const LINING_HI := Color("#6a46a0")
const SLEEVE := Color("#6b5a86")
const GLOW := Color("#a98bff")
const GLOW_PALE := Color("#d9ccff")
const HAIR := Color("#f2eff7")
const HAIR_MID := Color("#cfc9dc")
const HAIR_SH := Color("#a49db5")
const HAIR_DEEP := Color("#7a7290")
const SKIN := Color("#f0e6e2")
const SKIN_SH := Color("#c9b4b4")
const SKIN_HI := Color("#fff8f4")

var body: EEska
var snap_xf := Transform2D.IDENTITY ## 마지막 그림의 전역 변환 (잔상용)
var snap_v := PackedVector2Array()
var snap_c := PackedColorArray()
var snap_i := PackedInt32Array()

var _t := 0.0
var _sq := Vector2.ONE ## 늘이고 누르기
var _sq_v := Vector2.ZERO
var _lean := 0.0
var _lean_v := 0.0
var _tip := 0.0 ## 모자 끝 흔들림
var _tip_v := 0.0
var _flare := 0.0 ## 치마 펄럭임
var _flare_v := 0.0
var _lift := 0.0
var _hand := Vector2(3, -15)
var _hand_glow := 0.0
var _step := 0.0 ## 달리기 걸음 위상
var _was_floor := true
var _prev_vy := 0.0
var _snap_flash := 0.0 ## 천열 손끝 튕김 섬광
var _spin := 1.0 ## 이단점프 한 바퀴 (0 → 1)
var _glide := 0.0 ## 활주 정도 (0 = 서 있음, 1 = 최고 속도로 떠서 미끄러짐)
var _hair: Chain
var _lock: Chain ## 앞쪽 옆머리
var _sleeve: Chain
var _sleeve_b: Chain
var _eye_hist := PackedVector2Array()
var _ready_done := false


class Chain:
	var p := PackedVector2Array()
	var q := PackedVector2Array() ## 이전 위치
	var seg := 3.0

	func setup(points: PackedVector2Array, seg_len: float) -> void:
		p = points.duplicate()
		q = points.duplicate()
		seg = seg_len

	## anchor·rest는 전역 좌표. stiff = 쉬는 모양으로 당기는 세기(0~1), damp = 속도 보존(0~1)
	func step(anchor: Vector2, rest: PackedVector2Array, grav: Vector2, dt: float, damp: float, stiff: float) -> void:
		var n := p.size()
		p[0] = anchor
		q[0] = anchor
		var g := grav * dt * dt
		for i in range(1, n):
			var v := (p[i] - q[i]) * damp
			q[i] = p[i]
			var np := p[i] + v + g
			p[i] = np.lerp(rest[i], stiff * (0.5 + 0.5 * float(i) / float(n)))
		for it in 2:
			for i in range(1, n):
				var d := p[i] - p[i - 1]
				var l := d.length()
				if l > 0.0001:
					p[i] = p[i - 1] + d * (seg / l)

	func snap_to(rest: PackedVector2Array) -> void:
		p = rest.duplicate()
		q = rest.duplicate()


# ═══════════════════════════════════════════════════════════
# 쉬는 모양 (몸 기준 좌표)
# ═══════════════════════════════════════════════════════════

const HAIR_N := 8
const HAIR_SEG := 3.1
const SLEEVE_N := 4

func _hair_rest() -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in HAIR_N:
		r.append(Vector2(-2.6 - 0.55 * float(i), -31.0 + HAIR_SEG * float(i)))
	return r


func _lock_rest() -> PackedVector2Array:
	return PackedVector2Array([Vector2(2.6, -29.5), Vector2(2.9, -26.8), Vector2(3.0, -24.1), Vector2(3.0, -21.5)])


func _sleeve_rest(root: Vector2) -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in SLEEVE_N:
		r.append(root + Vector2(-1.2 * float(i), 2.6 * float(i)))
	return r


func _to_g(pts: PackedVector2Array) -> PackedVector2Array:
	var xf := global_transform
	return xf * pts


func _ensure() -> void:
	if _ready_done:
		return
	_ready_done = true
	_hair = Chain.new()
	_hair.setup(_to_g(_hair_rest()), HAIR_SEG)
	_lock = Chain.new()
	_lock.setup(_to_g(_lock_rest()), 2.7)
	_sleeve = Chain.new()
	_sleeve.setup(_to_g(_sleeve_rest(Vector2(1.5, -21))), 2.6)
	_sleeve_b = Chain.new()
	_sleeve_b.setup(_to_g(_sleeve_rest(Vector2(-1.5, -22))), 2.6)


## 순간이동처럼 몸이 순간 옮겨질 때 줄이 길게 끌리지 않게
func reset_chains() -> void:
	if not _ready_done:
		return
	_hair.snap_to(_to_g(_hair_rest()))
	_lock.snap_to(_to_g(_lock_rest()))
	_sleeve.snap_to(_to_g(_sleeve_rest(Vector2(1.5, -21))))
	_sleeve_b.snap_to(_to_g(_sleeve_rest(Vector2(-1.5, -22))))
	_eye_hist.clear()


## 늘이고 누르기 순간 주기 (점프·착지·타격에서 부른다)
func squash(s: Vector2) -> void:
	_sq = s
	_sq_v = Vector2.ZERO


func snap_flash() -> void:
	_snap_flash = 1.0


## 이단점프: 몸 가운데를 축으로 한 바퀴
func spin() -> void:
	_spin = 0.0


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func tick(delta: float) -> void:
	_ensure()
	if delta <= 0.0:
		return
	_t += delta
	var on_floor := body.is_on_floor()
	var vx := body.velocity.x
	var vy := body.velocity.y
	# 착지 누르기 (떨어진 속도만큼)
	if on_floor and not _was_floor:
		var f := clampf(_prev_vy / EEska.FALL_MAX, 0.2, 1.0)
		squash(Vector2(1.0 + 0.22 * f, 1.0 - 0.2 * f))
	_was_floor = on_floor
	_prev_vy = vy
	# 용수철들 (프레임이 길어도 폭주하지 않게 자름)
	var dt := minf(delta, 1.0 / 30.0)
	_sq_v += (Vector2.ONE - _sq) * 320.0 * dt - _sq_v * 20.0 * dt
	_sq += _sq_v * dt
	var lean_want := 0.0
	match body.st:
		EEska.St.ATTACK:
			lean_want = 0.03 if body.combo_i < 3 else 0.05 # 몸은 거의 그대로, 손짓만
		EEska.St.CAST:
			lean_want = -0.06 if body.cast_kind == "dangong" else 0.1
		EEska.St.NORMAL:
			# 활주할수록 상체(몸 전체)를 앞으로 크게 숙인다, 공중에서도 조금
			lean_want = clampf(vx * float(body.facing) / EEska.RUN_SPEED, -1.0, 1.0) * (0.34 if on_floor else 0.14)
	_lean_v += (lean_want - _lean) * 260.0 * dt - _lean_v * 18.0 * dt
	_lean += _lean_v * dt
	_tip_v += (-_tip * 140.0 - _tip_v * 6.0 - vx * float(body.facing) * 0.02 + vy * 0.006) * dt
	_tip += _tip_v * dt
	var glide_want := clampf(absf(vx) / EEska.RUN_SPEED, 0.0, 1.0) if on_floor and body.st == EEska.St.NORMAL else 0.0
	_glide = lerpf(_glide, glide_want, 1.0 - exp(-dt * 10.0))
	var flare_want := 0.0
	if not on_floor:
		flare_want = clampf(-vy / 300.0, -1.0, 1.0) * -1.6 + 0.6
	elif absf(vx) > 20.0:
		flare_want = 0.8 + 1.4 * _glide # 활주하면 치맛자락이 뒤로 길게 날림
	if body.st == EEska.St.ULT:
		flare_want = 2.6
	_flare_v += (flare_want - _flare) * 160.0 * dt - _flare_v * 12.0 * dt
	_flare += _flare_v * dt
	var lift_want := 3.0 + sin(_t * 3.0) if body.st == EEska.St.ULT else 0.0
	lift_want = maxf(lift_want, _glide * (3.5 + 0.8 * sin(_t * 9.0))) # 활주: 발이 땅에서 살짝 떠 있다
	_lift = lerpf(_lift, lift_want, 1.0 - exp(-dt * 8.0))
	if on_floor and absf(vx) > 20.0:
		_step += dt * absf(vx) / 9.0
	else:
		_step = lerpf(_step, roundf(_step / PI) * PI, 1.0 - exp(-dt * 12.0))
	_hand = _hand.lerp(_hand_target(), 1.0 - exp(-dt * 46.0))
	_hand_glow = maxf(_hand_glow - dt * 5.0, 0.0)
	if body.st in [EEska.St.ATTACK, EEska.St.CAST, EEska.St.ULT]:
		_hand_glow = 1.0
	_snap_flash = maxf(_snap_flash - dt * 7.0, 0.0)
	_spin = minf(_spin + delta / 0.34, 1.0)
	scale = Vector2(float(body.facing) * _sq.x, _sq.y)
	# 이단점프 한 바퀴: 몸 가운데(발에서 18px 위)를 축으로 앞으로 돈다 (처음 빠르게, 끝에 느리게)
	var spin_a := TAU * (1.0 - pow(1.0 - _spin, 3.0)) if _spin < 1.0 else 0.0
	rotation = (_lean + spin_a) * float(body.facing)
	# 숙이기는 발을 축으로, 한 바퀴는 몸 가운데를 축으로
	var pivot := Vector2(0, -18.0 * _sq.y)
	position = Vector2(0, -_lift) + pivot.rotated(_lean * float(body.facing)) - pivot.rotated(rotation)
	# 흔들리는 줄
	var grav := Vector2(0, 460) + Vector2(-float(body.facing) * 520.0 * _glide, -80.0 * _glide)
	var stiff := 0.11 - 0.05 * _glide
	if body.st == EEska.St.ULT:
		grav = Vector2(0, -160) # 떠오르는 힘에 머리카락이 위로 흩날림
		stiff = 0.02
	var bob := _bob()
	_hair.step(to_global(Vector2(-2.6, -31.0 + bob)), _to_g(_hair_rest()), grav, dt, 0.82, stiff)
	_lock.step(to_global(Vector2(2.6, -29.5 + bob)), _to_g(_lock_rest()), grav, dt, 0.86, 0.12)
	var sh := Vector2(1.5, -23.5 + bob)
	var el := sh.lerp(_hand, 0.5)
	var sleeve_g := Vector2(-float(body.facing) * 380.0 * _glide, 300.0 - 120.0 * _glide)
	_sleeve.step(to_global(el), _to_g(_sleeve_rest(el)), sleeve_g, dt, 0.86, 0.08)
	_sleeve_b.step(to_global(Vector2(-1.8, -22.5 + bob)), _to_g(_sleeve_rest(Vector2(-1.8, -22.5))), sleeve_g, dt, 0.86, 0.08)
	# 눈빛 꼬리 (빠를 때만)
	var fast := absf(vx) > 170.0 or body.st == EEska.St.ATTACK or body.st == EEska.St.ULT
	if fast:
		_eye_hist.append(to_global(Vector2(3.6, -28.9 + bob)))
		if _eye_hist.size() > 7:
			_eye_hist.remove_at(0)
	elif not _eye_hist.is_empty():
		_eye_hist.remove_at(0)
	queue_redraw()


func _bob() -> float:
	if _glide > 0.3:
		return 0.0 # 떠서 미끄러지는 중엔 걸음 출렁임 없음 (높이 출렁임은 _lift가)
	if body.is_on_floor() and absf(body.velocity.x) > 20.0:
		return -absf(sin(_step)) * 1.2
	if body.is_on_floor() and body.st == EEska.St.NORMAL:
		return -0.5 * (0.5 + 0.5 * sin(_t * 2.4))
	return 0.0


func _hand_target() -> Vector2:
	var s := Vector2(1.5, -23.5)
	match body.st:
		EEska.St.ATTACK:
			# 가벼운 손짓: 1타 가리키기 · 2타 손끝 튀기기 · 3타 가슴 앞에서 손가락 튕기기 · 4타 손가락을 들었다 내려 가리키기
			var a: Dictionary = EEska.COMBO[body.combo_i]
			var k := clampf(body.st_t / maxf(float(a.hit) * 1.3, 0.001), 0.0, 1.0)
			k = 1.0 - pow(1.0 - k, 3.0)
			match body.combo_i:
				0:
					return Vector2(9.0, -22.0).lerp(Vector2(12.5, -25.0), k)
				1:
					return Vector2(10.0, -28.0).lerp(Vector2(12.5, -22.5), k)
				2:
					return Vector2(7.5, -23.0).lerp(Vector2(9.0, -25.5), k)
				_:
					return Vector2(7.0, -34.0).lerp(Vector2(13.0, -25.5), k)
		EEska.St.CAST:
			match body.cast_kind:
				"cheonyeol":
					return Vector2(12.5, -23.5)
				"dangong":
					return Vector2(5.5, -38)
				_:
					return Vector2(11.5, -21)
		EEska.St.ULT:
			return Vector2(2.5, -42)
	if not body.is_on_floor():
		return Vector2(5.5, -18.5) if body.velocity.y < 0.0 else Vector2(6.5, -21)
	if absf(body.velocity.x) > 20.0:
		return Vector2(2.5 + sin(_step) * 3.0, -15.5 - absf(cos(_step)) * 0.8)
	return Vector2(3, -15.5)


func _draw() -> void:
	_paint()
	# 잔상용으로 마지막 그림을 남겨 둔다 (삼각형 수백 개라 복사는 가볍다)
	snap_v = pd.v.duplicate()
	snap_c = pd.c.duplicate()
	snap_i = pd.idx.duplicate()
	snap_xf = global_transform
	pd.flush(self)


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

## 줄(전역 좌표)을 이 노드 좌표의 띠 두 줄로 — 위에서 w0, 끝에서 w1 두께
func _ribbon(ch: PackedVector2Array, w0: float, w1: float, off := 0.0) -> Array:
	var inv := global_transform.affine_inverse()
	var loc := inv * ch
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	var n := loc.size()
	for i in n:
		var a := loc[maxi(i - 1, 0)]
		var b := loc[mini(i + 1, n - 1)]
		var nrm := (b - a).normalized().orthogonal()
		var w := lerpf(w0, w1, float(i) / float(n - 1)) * 0.5
		l.append(loc[i] + nrm * (w + off))
		r.append(loc[i] - nrm * (w - off))
	return [l, r, loc]


func _paint() -> void:
	if not _ready_done:
		return
	var bob := _bob()
	var o := Vector2(0, bob)
	var air := not body.is_on_floor()
	var run := body.is_on_floor() and absf(body.velocity.x) > 20.0
	var shimmer := 0.78 + 0.22 * sin(_t * 7.0)
	var ult := body.st == EEska.St.ULT

	# 바닥 그림자 (떠오르면 작아짐)
	pd.draw_set_transform(Vector2(0, _lift), 0.0, Vector2(1.0, 0.24))
	pd.glow(Vector2.ZERO, 10.0 - _lift * 0.8, Color(0, 0, 0, 0.55), 0.0)
	pd.draw_set_transform(Vector2.ZERO)

	# ── 뒤 소매 (몸 뒤, 반투명)
	var sb := _ribbon(_sleeve_b.p, 3.6, 5.2)
	pd.strip(sb[0], sb[1], Color(SLEEVE, 0.4))

	# ── 뒤 머리 (긴 백발, 흔들리는 줄)
	var hr := _ribbon(_hair.p, 7.4, 2.4)
	pd.strip(_grow(hr[0], hr[2], 0.8), _grow(hr[1], hr[2], 0.8), OUT)
	pd.strip(hr[0], hr[1], HAIR_SH)
	var hi := _ribbon(_hair.p, 4.2, 1.2, -0.9)
	pd.strip(hi[0], hi[1], HAIR_MID)
	var hl := _ribbon(_hair.p, 1.8, 0.4, -1.6)
	pd.strip(hl[0], hl[1], HAIR)
	var hloc: PackedVector2Array = hr[2]
	for i in range(1, hloc.size() - 2):
		pd.draw_line(hloc[i] + Vector2(0.6, 0), hloc[i + 1] + Vector2(0.6, 0), Color(HAIR_DEEP, 0.7), 0.6)

	# ── 치마 (검은 롱드레스: 뒤로 보라 안감, 주름, 자락 끝 갈라짐 = 흰 공허)
	var fl := _flare
	var back := -8.6 - fl * 1.5
	var front := 6.6 + fl * 0.6
	var stride := sin(_step) * (1.6 if run else 0.0) * (1.0 - _glide)
	var waist := -16.0 + bob
	# 안감 (뒤쪽으로 비침)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-2.5, waist + 1), Vector2(back + 0.2, -2.0 - fl * 0.6), Vector2(back + 3.4, -0.8), Vector2(-0.6, waist + 4)]), LINING)
	pd.draw_line(Vector2(-2.0, waist + 2), Vector2(back + 1.4, -1.6 - fl * 0.6), LINING_HI, 1.0)
	var hem := PackedVector2Array([Vector2(-3.4, waist), Vector2(3.4, waist), Vector2(front - 1.6 + stride * 0.3, -7.0)])
	var n := 8
	for i in n + 1:
		var f := float(i) / float(n)
		var x := lerpf(front + stride * 0.5, back, f)
		var y := -0.6 if i % 2 == 0 else -3.8
		if i == n:
			y = -1.6 - fl * 0.5
		y -= fl * 0.4 * f
		hem.append(Vector2(x, y))
	hem.append(Vector2(back + 1.6, -9.0))
	pd.outlined(hem, CLOTH, RIM, 0.8)
	# 주름 (빛 받는 결 두 줄 + 그늘 한 줄)
	pd.draw_line(Vector2(0.5, waist + 1.5), Vector2(front - 2.0 + stride * 0.4, -2.5), CLOTH_HI, 1.0)
	pd.draw_line(Vector2(-1.4, waist + 2.0), Vector2(-3.6 - fl * 0.6, -2.0), CLOTH_HI, 1.0)
	pd.draw_line(Vector2(-0.4, waist + 3.0), Vector2(-0.8 - fl * 0.2, -3.0), CLOTH_SH, 1.0)
	# 높은 트임 사이 다리 (달리면 앞뒤로)
	var hip := Vector2(2.2, waist + 3.0)
	var foot := Vector2(3.6 + stride * 1.6 + (1.4 if air else 0.0), -1.0 - (2.0 if air else maxf(0.0, -sin(_step)) * 1.4 * (1.0 - _glide)))
	foot = foot.lerp(Vector2(-1.2, -2.6), _glide) # 활주: 발끝을 뒤로 모아 끈다
	pd.draw_line(hip, foot, SKIN_SH, 1.6)
	pd.draw_line(hip + Vector2(0.4, 0), foot + Vector2(0.4, -1.2), SKIN, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.4, -1.0), foot + Vector2(1.8, -0.4), foot + Vector2(2.2, 0.8), foot + Vector2(-1.2, 0.8)]), OUT) # 검은 구두
	# 갈라진 자락의 흰 공허
	for i in 3:
		var f := (float(i) + 0.5) / 3.0
		var x := lerpf(front - 1.0, back + 1.4, f)
		var y := -1.0 - fl * 0.4 * f
		pd.glow(Vector2(x, y - 1.5), 3.4, Color(GLOW_PALE, 0.35 * shimmer), 0.0)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.4, y), Vector2(x + 1.4, y), Vector2(x + 0.2, y - 3.4)]), Color(1, 1, 1, shimmer))

	# ── 몸통 (몸에 맞는 검은 드레스) + 드러난 어깨·목
	var torso := PackedVector2Array([Vector2(-3.1, waist), Vector2(3.2, waist), Vector2(4.4, waist - 3.6), Vector2(3.6, waist - 7.2), Vector2(-3.1, waist - 7.2)])
	pd.outlined(torso, CLOTH, RIM, 0.8)
	pd.draw_line(Vector2(3.6, waist - 6.4), Vector2(4.0, waist - 3.6), CLOTH_EDGE, 1.0) # 가슴선 빛
	pd.draw_line(Vector2(-2.6, waist - 0.6), Vector2(3.0, waist - 0.6), LINING, 1.0) # 허리 보라 띠
	pd.draw_rect(Rect2(Vector2(-3.4, waist - 9.0), Vector2(7.2, 2.0)), SKIN)
	pd.draw_rect(Rect2(Vector2(-3.4, waist - 9.0), Vector2(7.2, 0.8)), SKIN_HI)
	pd.draw_rect(Rect2(Vector2(-0.2, waist - 10.6), Vector2(2.2, 1.8)), SKIN_SH)

	# ── 얼굴 (모자 챙 그늘, 앞머리가 오른쪽 눈을 덮는다)
	var hc := o + Vector2(1.3, -29.2)
	pd.draw_circle(hc, 3.3, SKIN)
	pd.draw_rect(Rect2(hc + Vector2(-2.6, -3.2), Vector2(5.6, 1.6)), Color(SKIN_SH, 0.9)) # 챙 그늘
	pd.draw_rect(Rect2(hc + Vector2(1.6, 1.5), Vector2(1.2, 0.8)), SKIN_SH) # 턱 그늘
	pd.draw_rect(Rect2(hc + Vector2(2.1, 0.6), Vector2(1.0, 0.5)), Color("#b98f9a")) # 입술
	# 정수리 + 앞머리
	pd.draw_circle(o + Vector2(0.1, -30.7), 3.6, HAIR_MID)
	pd.draw_circle(o + Vector2(0.6, -31.4), 2.4, HAIR)
	var fringe := PackedVector2Array([o + Vector2(0.4, -33.4), o + Vector2(4.4, -31.6), o + Vector2(4.8, -27.2),
		o + Vector2(3.2, -26.0), o + Vector2(2.4, -28.4), o + Vector2(-0.2, -30.6)])
	pd.outlined(fringe, HAIR, OUT, 0.6)
	pd.draw_line(o + Vector2(3.7, -31.0), o + Vector2(4.0, -27.2), HAIR_SH, 0.8)
	pd.draw_line(o + Vector2(2.6, -32.6), o + Vector2(3.0, -28.6), HAIR_MID, 0.6)
	# 앞쪽 옆머리 (흔들리는 줄)
	var lk := _ribbon(_lock.p, 2.4, 1.0)
	pd.strip(_grow(lk[0], lk[2], 0.5), _grow(lk[1], lk[2], 0.5), OUT)
	pd.strip(lk[0], lk[1], HAIR)
	# 앞머리 사이로 비치는 눈빛 (흰빛 + 보라 번짐)
	var eye := o + Vector2(3.5, -28.9)
	var eye_a := 0.7 + 0.3 * sin(_t * 3.0)
	if body.st != EEska.St.NORMAL:
		eye_a = 1.0
	pd.glow(eye, 3.2 if not ult else 6.0, Color(GLOW, 0.55 * eye_a), 0.0)
	pd.draw_rect(Rect2(eye - Vector2(0.6, 0.5), Vector2(1.3, 1.0)), Color(GLOW_PALE, eye_a))
	pd.draw_rect(Rect2(eye - Vector2(0.2, 0.3), Vector2(0.6, 0.5)), Color(1, 1, 1, eye_a))
	# 눈빛 꼬리
	if _eye_hist.size() >= 2:
		var inv := global_transform.affine_inverse()
		var loc := inv * _eye_hist
		for i in range(1, loc.size()):
			var f := float(i) / float(loc.size())
			pd.draw_line(loc[i - 1], loc[i], Color(GLOW, 0.75 * f), 0.6 + 0.9 * f)

	# ── 모자: 챙 (윗면·아랫면, 갈라진 끝에 흰 공허) + 꺾인 뾰족 머리
	var brim_c := o + Vector2(0.4, -33.5)
	pd.draw_set_transform(brim_c, -0.07 + _tip * 0.05, Vector2.ONE)
	var brim := PackedVector2Array()
	var brim_top := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		brim.append(Vector2(cos(a) * 14.4, sin(a) * 2.5))
		brim_top.append(Vector2(cos(a) * 13.2, sin(a) * 1.5 - 0.5))
	pd.outlined(brim, CLOTH_SH, RIM, 0.8)
	pd.convex(brim_top, CLOTH)
	pd.draw_line(Vector2(-12.0, -0.9), Vector2(10.5, -1.3), CLOTH_EDGE, 0.8) # 챙 윗면 빛
	for spec: Array in [[11.8, 1.0], [7.8, 1.2], [-11.4, 0.9], [-6.0, 0.8]]:
		var x: float = spec[0]
		var sgn := signf(x)
		var sz: float = spec[1]
		pd.glow(Vector2(x + sgn * 1.5, 0.4), 3.0, Color(GLOW_PALE, 0.3 * shimmer), 0.0)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x + sgn * 2.8 * sz, -0.6), Vector2(x - sgn * 0.7, 0.1), Vector2(x + sgn * 2.4 * sz, 1.6)]), Color(1, 1, 1, shimmer))
	pd.draw_set_transform(Vector2.ZERO)
	var tip := Vector2(-4.4 - _tip * 2.0, -45.8 + absf(_tip) * 0.6)
	var crown := PackedVector2Array([o + Vector2(-5.0, -34.3), o + Vector2(5.2, -34.5), o + Vector2(2.6, -39.2),
		o + Vector2(-0.4, -42.4), o + tip, o + tip + Vector2(-1.6, 0.9), o + Vector2(-3.4, -41.6), o + Vector2(-4.6, -38.0)])
	pd.outlined(crown, CLOTH, RIM, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([o + Vector2(1.6, -34.5), o + Vector2(5.2, -34.5), o + Vector2(2.6, -39.2), o + Vector2(0.4, -40.6)]), CLOTH_HI) # 빛 받는 쪽
	pd.draw_line(o + Vector2(-4.6, -35.3), o + Vector2(4.6, -35.5), LINING, 1.4) # 보라 띠
	pd.draw_line(o + Vector2(-4.2, -36.0), o + Vector2(4.2, -36.2), Color(LINING_HI, 0.6), 0.6)

	# ── 앞팔 + 시스루 소매 + 손빛
	var sh := o + Vector2(1.5, -23.5)
	var hand := _hand + Vector2(0, bob)
	var mid := sh.lerp(hand, 0.5)
	var bend := (hand - sh).orthogonal().normalized() * 1.4
	var el := mid + (bend if bend.y > 0.0 else -bend)
	var sl := _ribbon(_sleeve.p, 4.4, 6.4)
	pd.strip(sl[0], sl[1], Color(SLEEVE, 0.5))
	var sll: PackedVector2Array = sl[0]
	pd.draw_polyline(sll, Color(GLOW_PALE, 0.3), 0.6)
	pd.draw_line(sh, el, SKIN, 1.7)
	pd.draw_line(el, hand, SKIN, 1.5)
	pd.draw_line(sh + Vector2(0, -0.5), el + Vector2(0, -0.5), SKIN_HI, 0.6)
	pd.draw_circle(hand, 1.15, SKIN)
	if _hand_glow > 0.0:
		pd.glow(hand, 6.0, Color(GLOW, 0.5 * _hand_glow), 0.0)
		pd.draw_circle(hand, 1.4, Color(1, 1, 1, 0.95 * _hand_glow))
	if _snap_flash > 0.0:
		var sf := _snap_flash
		pd.glow(hand, 14.0 * (1.5 - sf * 0.5), Color(GLOW_PALE, 0.7 * sf), 0.0)
		for k in 4:
			var a := float(k) * PI / 2.0 + PI / 4.0
			pd.draw_line(hand, hand + Vector2(cos(a), sin(a)) * (4.0 + 8.0 * (1.0 - sf)), Color(1, 1, 1, sf), 1.0)


## 띠 가장자리를 중심선에서 d만큼 더 바깥으로 (윤곽용)
func _grow(edge: PackedVector2Array, center: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in edge.size():
		var dv := edge[i] - center[i]
		var l := dv.length()
		out.append(edge[i] + (dv / l * d if l > 0.0001 else Vector2.ZERO))
	return out
