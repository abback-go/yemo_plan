class_name TWitchArt
extends PDraw.Canvas
## 불의 마녀 둘의 코드 그림 (키 약 40px, 원점 = 발밑 가운데, 오른쪽을 보는 모습 — 부모가 scale.x로 뒤집는다). 에스카(EArt)와 같은 비례·말투.
## 이그니스(딜러): 짧게 뻗친 주홍 머리 + 왼쪽에 길게 땋은 한 가닥(흔들리는 줄), 챙 끝이 그을려 불씨가 이는 검은 모자(끝이 앞으로 꺾임),
##                 높은 깃의 검은 외투 안에 붉은 조끼, 비대칭 짧은 치마와 긴 부츠, 앞손은 불이 붙는 장갑.
## 엠버(버퍼): 꿀빛 긴 머리를 두 갈래로 땋음(앞·뒤 줄), 챙이 짧고 끝이 뒤로 늘어진 크림색 모자(주황 띠·작은 종),
##             넓은 소매의 크림 로브에 살구색 허리띠, 손에는 놋쇠 등불 — 버프를 걸 때 등불이 환해진다.
## 자세(pose): idle(숨 쉬며 흔들림) · cast(앞손을 뻗어 빛) · cast_big(두 팔을 펼치고 떠오름, 머리칼이 위로) · hit(움찔·붉게) · down(옅어짐)

const OUT := Color("#0a090e")

const PAL := {
	"ignis": {
		"hair": Color("#d8432b"), "hair_hi": Color("#ff9a4a"), "hair_sh": Color("#8e2418"),
		"skin": Color("#efc9a6"), "skin_sh": Color("#c99a78"), "skin_hi": Color("#fbe6d2"),
		"cloth": Color("#241a1c"), "cloth_hi": Color("#3b2a2d"), "cloth_edge": Color("#5a3b3b"),
		"inner": Color("#b8341f"), "inner_hi": Color("#e0582f"), "band": Color("#7a1e16"),
		"hat": Color("#17121a"), "hat_hi": Color("#2b2130"), "brim_edge": Color("#ff7a2a"),
		"glow": Color("#ff8a3a"), "glow_pale": Color("#ffd9a0"), "eye": Color("#ffb347"),
		"boot": Color("#120d10"), "metal": Color("#d9a441"),
	},
	"ember": {
		"hair": Color("#f0a850"), "hair_hi": Color("#ffd28a"), "hair_sh": Color("#b86f2a"),
		"skin": Color("#f6dcc8"), "skin_sh": Color("#d4ac92"), "skin_hi": Color("#fff1e6"),
		"cloth": Color("#f6e7cf"), "cloth_hi": Color("#fff8ea"), "cloth_edge": Color("#d9c3a2"),
		"inner": Color("#f1a662"), "inner_hi": Color("#ffc98a"), "band": Color("#c4512e"),
		"hat": Color("#efdcc0"), "hat_hi": Color("#fbf0dc"), "brim_edge": Color("#c4512e"),
		"glow": Color("#ffb95a"), "glow_pale": Color("#fff0c8"), "eye": Color("#8a4a22"),
		"boot": Color("#6b3a24"), "metal": Color("#c9933a"),
	},
}

var kind := "ignis"
var pose := "idle"
var fade := 1.0 ## 쓰러지면 옅어짐 (TActor가 내린다)
var glow := 0.0 ## 손·소품의 빛 (0~1) — 시전 중 1

var _p: Dictionary
var _t := 0.0
var _sq := Vector2.ONE
var _sq_v := Vector2.ZERO
var _lean := 0.0
var _lean_v := 0.0
var _lift := 0.0 ## 큰 마법: 떠오름
var _big := 0.0 ## cast_big 정도 (0~1)
var _hand := Vector2(3, -15.5)
var _back_hand := Vector2(-2.0, -15.0)
var _hurt_flash := 0.0
var _tip := 0.0 ## 모자 끝 흔들림
var _tip_v := 0.0
var _hair: EArt.Chain
var _hair2: EArt.Chain
var _sleeve: EArt.Chain
var _ready_done := false
var _flicker := 0.0 ## 불빛 떨림 (프레임마다 조금씩)


func _ready() -> void:
	_p = PAL[kind]


func _ensure() -> void:
	if _ready_done:
		return
	_ready_done = true
	_hair = EArt.Chain.new()
	_hair.setup(_to_g(_hair_rest()), 2.9)
	_hair2 = EArt.Chain.new()
	_hair2.setup(_to_g(_hair2_rest()), 2.6)
	_sleeve = EArt.Chain.new()
	_sleeve.setup(_to_g(_sleeve_rest(Vector2(1.5, -21.0))), 2.6)


func _to_g(pts: PackedVector2Array) -> PackedVector2Array:
	return global_transform * pts


## 뒤로 늘어진 머리 줄 (이그니스: 땋은 한 가닥 / 엠버: 뒤 땋은 머리)
func _hair_rest() -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in 7:
		r.append(Vector2(-2.6 - 0.5 * float(i), -30.5 + 2.9 * float(i)))
	return r


## 앞쪽 줄 (이그니스: 뻗친 옆머리 짧게 / 엠버: 앞 땋은 머리)
func _hair2_rest() -> PackedVector2Array:
	var r := PackedVector2Array()
	var n := 5 if kind == "ember" else 3
	for i in n:
		r.append(Vector2(3.4 + 0.25 * float(i), -29.0 + 2.6 * float(i)))
	return r


func _sleeve_rest(root: Vector2) -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in 4:
		r.append(root + Vector2(-1.0 * float(i), 2.6 * float(i)))
	return r


func set_pose(p: String) -> void:
	pose = p


func squash(s: Vector2) -> void:
	_sq = s
	_sq_v = Vector2.ZERO


func hurt() -> void:
	_hurt_flash = 1.0
	squash(Vector2(1.18, 0.84))


func reset_chains() -> void:
	if not _ready_done:
		return
	_hair.snap_to(_to_g(_hair_rest()))
	_hair2.snap_to(_to_g(_hair2_rest()))
	_sleeve.snap_to(_to_g(_sleeve_rest(Vector2(1.5, -21.0))))


func _bob() -> float:
	return -0.5 * (0.5 + 0.5 * sin(_t * 2.4)) if pose == "idle" else 0.0


func _hand_target() -> Vector2:
	match pose:
		"cast":
			return Vector2(12.0, -24.0)
		"cast_big":
			return Vector2(11.5, -32.0)
		"hit":
			return Vector2(5.0, -19.0)
		"win":
			return Vector2(8.0, -36.0)
	if kind == "ember":
		return Vector2(5.5, -17.5) # 등불을 들어 몸 앞에
	return Vector2(3.0, -15.5)


func _back_hand_target() -> Vector2:
	match pose:
		"cast_big":
			return Vector2(-10.5, -31.0)
		"cast":
			return Vector2(-4.5, -17.0)
	return Vector2(-2.0, -15.0)


## 앞손(전역) — 마법이 나가는 자리
func hand_global() -> Vector2:
	return to_global(_hand + Vector2(0, _bob()))


## 소품의 빛나는 자리(전역): 이그니스는 장갑 끝, 엠버는 등불 유리
func prop_global() -> Vector2:
	if kind == "ember":
		return to_global(_hand + Vector2(1.5, 4.5 + _bob()))
	return hand_global()


func tick(delta: float) -> void:
	_ensure()
	if delta <= 0.0:
		return
	_t += delta
	var dt := minf(delta, 1.0 / 30.0)
	_sq_v += (Vector2.ONE - _sq) * 320.0 * dt - _sq_v * 20.0 * dt
	_sq += _sq_v * dt
	var lean_want := 0.0
	match pose:
		"cast": lean_want = 0.12
		"cast_big": lean_want = -0.07
		"hit": lean_want = -0.1
	_lean_v += (lean_want - _lean) * 260.0 * dt - _lean_v * 18.0 * dt
	_lean += _lean_v * dt
	_big = move_toward(_big, 1.0 if pose == "cast_big" else 0.0, dt * (5.0 if pose == "cast_big" else 3.0))
	_lift = lerpf(_lift, 9.0 * _big, 1.0 - exp(-dt * 6.0))
	_tip_v += (-_tip * 140.0 - _tip_v * 6.0 + (_big * 60.0)) * dt
	_tip += _tip_v * dt
	_hand = _hand.lerp(_hand_target(), 1.0 - exp(-dt * 30.0))
	_back_hand = _back_hand.lerp(_back_hand_target(), 1.0 - exp(-dt * 24.0))
	var glow_want := 1.0 if pose in ["cast", "cast_big", "win"] else 0.0
	glow = move_toward(glow, glow_want, dt * 6.0)
	_hurt_flash = maxf(_hurt_flash - dt * 5.0, 0.0)
	_flicker = 0.75 + 0.25 * sin(_t * 23.0) * sin(_t * 7.3 + 1.0)
	modulate = Color(1.0, 1.0 - 0.55 * _hurt_flash, 1.0 - 0.5 * _hurt_flash, fade)
	scale = _sq
	rotation = _lean
	var pivot := Vector2(0, -18.0 * _sq.y)
	position = Vector2(0, -_lift) + pivot.rotated(_lean) - pivot.rotated(rotation)
	# 흔들리는 줄: 큰 마법이면 아래에서 바람이 올라오듯 위로
	var grav := Vector2(0, 460).lerp(Vector2(-90.0 + sin(_t * 7.0) * 120.0, -380.0), _big)
	var stiff := 0.12 * (1.0 - 0.6 * _big)
	var bob := _bob()
	_hair.step(to_global(Vector2(-2.6, -30.5 + bob)), _to_g(_hair_rest()), grav, dt, 0.82, stiff)
	_hair2.step(to_global(Vector2(3.4, -29.0 + bob)), _to_g(_hair2_rest()), grav, dt, 0.86, 0.14)
	var sh := Vector2(1.5, -23.5 + bob)
	var el := sh.lerp(_hand, 0.5)
	var sleeve_g := Vector2(0, 300.0).lerp(Vector2(sin(_t * 9.0) * 80.0, -260.0), _big)
	_sleeve.step(to_global(el), _to_g(_sleeve_rest(el)), sleeve_g, dt, 0.86, 0.08)
	queue_redraw()


## 줄(전역 좌표)을 이 노드 좌표의 띠로 — 위에서 w0, 끝에서 w1 두께
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


func _grow(edge: PackedVector2Array, center: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in edge.size():
		var dv := edge[i] - center[i]
		var l := dv.length()
		out.append(edge[i] + (dv / l * d if l > 0.0001 else Vector2.ZERO))
	return out


## 땋은 머리: 바탕 띠 + 엇갈린 매듭 결
func _braid(ch: PackedVector2Array, w0: float, w1: float) -> void:
	var r := _ribbon(ch, w0, w1)
	pd.strip(_grow(r[0], r[2], 0.8), _grow(r[1], r[2], 0.8), OUT)
	pd.strip(r[0], r[1], _p.hair_sh)
	var hi := _ribbon(ch, w0 * 0.55, w1 * 0.5, -0.5)
	pd.strip(hi[0], hi[1], _p.hair)
	var loc: PackedVector2Array = r[2]
	for i in range(1, loc.size() - 1):
		var a := loc[i - 1]
		var b := loc[i]
		var nrm := (b - a).normalized().orthogonal()
		var w := lerpf(w0, w1, float(i) / float(loc.size() - 1)) * 0.5
		var s := 1.0 if i % 2 == 0 else -1.0
		pd.draw_line(b + nrm * w * s, a - nrm * w * 0.4 * s, _p.hair_hi, 0.7)


func _paint() -> void:
	if not _ready_done:
		return
	var bob := _bob()
	var o := Vector2(0, bob)
	var fl := _flicker
	# 바닥 그림자 (떠오르면 작아짐)
	pd.draw_set_transform(Vector2(0, _lift), 0.0, Vector2(1.0, 0.24))
	pd.glow(Vector2.ZERO, 10.0 - _lift * 0.6, Color(0, 0, 0, 0.55), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	# 큰 마법: 등 뒤 불의 고리
	if _big > 0.0:
		_paint_big_ring(o)
	# 뒷팔 (몸 뒤)
	var bsh := o + Vector2(-1.6, -23.0)
	var bh := _back_hand + o
	var bel := bsh.lerp(bh, 0.5) + Vector2(0, 1.2)
	if kind == "ember":
		var bs := _ribbon(PackedVector2Array([to_global(bsh), to_global(bel), to_global(bh + Vector2(-1.0, 2.0))]), 3.6, 6.0)
		pd.strip(bs[0], bs[1], Color(_p.cloth, 0.75))
	pd.draw_line(bsh, bel, _p.skin_sh, 1.6)
	pd.draw_line(bel, bh, _p.skin_sh, 1.4)
	pd.draw_circle(bh, 1.1, _p.skin_sh)
	if _big > 0.0:
		pd.glow(bh, 5.0, Color(_p.glow, 0.45 * _big), 0.0)
		pd.draw_circle(bh, 1.2, Color(1, 1, 1, 0.9 * _big))
	# 뒤 머리 줄
	if kind == "ember":
		_braid(_hair.p, 3.6, 2.2)
		var tip_pts: PackedVector2Array = _ribbon(_hair.p, 1.0, 1.0)[2]
		var tipp: Vector2 = tip_pts[tip_pts.size() - 1]
		pd.draw_line(tipp + Vector2(-1.6, 0.0), tipp + Vector2(1.6, 0.0), _p.band, 1.4) # 리본 매듭
		pd.draw_circle(tipp + Vector2(0, 1.6), 1.0, _p.hair_hi)
	else:
		_braid(_hair.p, 2.6, 1.4)
		var tip_pts: PackedVector2Array = _ribbon(_hair.p, 1.0, 1.0)[2]
		var tipp: Vector2 = tip_pts[tip_pts.size() - 1]
		pd.draw_circle(tipp + Vector2(0, 1.0), 1.4, OUT)
		pd.draw_circle(tipp + Vector2(0, 1.0), 0.9, _p.metal) # 놋쇠 고리
	# ── 치마 / 로브 자락
	var waist := -16.0 + bob
	if kind == "ignis":
		# 비대칭 짧은 치마: 앞은 짧고 뒤는 길게, 안쪽에 붉은 안감이 비침
		var hem := PackedVector2Array([Vector2(-3.4, waist), Vector2(3.6, waist), Vector2(6.0, waist + 6.0), Vector2(2.0, waist + 7.5),
			Vector2(-3.0, waist + 9.5), Vector2(-7.5 - _big * 1.5, waist + 11.0), Vector2(-6.5, waist + 4.0)])
		pd.outlined(hem, _p.cloth, OUT, 0.8)
		pd.draw_line(Vector2(-5.4, waist + 9.4), Vector2(-7.0 - _big * 1.5, waist + 10.6), _p.inner, 1.2)
		pd.draw_line(Vector2(0.5, waist + 1.0), Vector2(4.6, waist + 5.6), _p.cloth_hi, 1.0)
		# 긴 부츠 두 짝 (앞·뒤)
		var hip := Vector2(1.6, waist + 5.0)
		var foot := Vector2(3.8, -1.0)
		pd.draw_line(hip, foot, _p.skin, 1.8)
		pd.draw_line(hip + Vector2(0, 4.0), foot, _p.boot, 2.6)
		pd.draw_line(hip + Vector2(0.4, 4.5), foot + Vector2(0.4, -1.0), _p.cloth_edge, 0.6)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.6, -1.0), foot + Vector2(2.4, -0.4), foot + Vector2(2.8, 0.8), foot + Vector2(-1.4, 0.8)]), _p.boot)
		var hip2 := Vector2(-1.8, waist + 5.0)
		var foot2 := Vector2(-2.6, -1.0)
		pd.draw_line(hip2, foot2, _p.boot, 2.4)
		pd.draw_colored_polygon(PackedVector2Array([foot2 + Vector2(-1.4, -1.0), foot2 + Vector2(2.0, -0.4), foot2 + Vector2(2.2, 0.8), foot2 + Vector2(-1.2, 0.8)]), OUT)
	else:
		# 크림 로브: 넓게 퍼진 자락, 살구색 안단, 밑단에 주황 줄
		var flare := 1.0 + 0.5 * _big
		var hem := PackedVector2Array([Vector2(-3.6, waist), Vector2(3.6, waist), Vector2(7.6 * flare, -0.6), Vector2(2.0, -1.8), Vector2(-2.5, -0.8), Vector2(-8.4 * flare, -1.4), Vector2(-6.6, waist + 6.0)])
		pd.outlined(hem, _p.cloth, OUT, 0.8)
		pd.draw_line(Vector2(6.4 * flare, -1.4), Vector2(-7.2 * flare, -2.2), _p.band, 1.2) # 밑단 주황 줄
		pd.draw_line(Vector2(1.2, waist + 1.5), Vector2(4.8 * flare, -3.0), _p.cloth_hi, 1.0)
		pd.draw_line(Vector2(-1.6, waist + 2.0), Vector2(-4.8 * flare, -3.5), _p.cloth_edge, 1.0)
		pd.draw_line(Vector2(0.2, -2.2), Vector2(0.6, waist + 3.0), _p.inner, 0.9) # 앞트임 사이 살구색 안단
		var foot := Vector2(2.4, -0.6)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.6, -1.6), foot + Vector2(2.0, -1.0), foot + Vector2(2.4, 0.6), foot + Vector2(-1.4, 0.6)]), _p.boot)
	# ── 몸통
	var torso := PackedVector2Array([Vector2(-3.1, waist), Vector2(3.2, waist), Vector2(4.4, waist - 3.6), Vector2(3.6, waist - 7.2), Vector2(-3.1, waist - 7.2)])
	if kind == "ignis":
		pd.outlined(torso, _p.cloth, OUT, 0.8)
		# 열린 외투 사이 붉은 조끼 + 높은 깃
		pd.draw_colored_polygon(PackedVector2Array([Vector2(0.4, waist - 7.0), Vector2(3.0, waist - 6.6), Vector2(3.4, waist - 1.0), Vector2(0.8, waist)]), _p.inner)
		pd.draw_line(Vector2(1.2, waist - 6.0), Vector2(1.6, waist - 1.0), _p.inner_hi, 0.8)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(-3.4, waist - 7.2), Vector2(3.8, waist - 7.4), Vector2(3.2, waist - 10.4), Vector2(-3.0, waist - 10.0)]), _p.cloth_hi) # 깃
		pd.draw_line(Vector2(-2.6, waist - 0.6), Vector2(3.0, waist - 0.6), _p.band, 1.0) # 허리띠
		pd.draw_rect(Rect2(Vector2(-0.2, waist - 10.6), Vector2(2.0, 1.6)), _p.skin_sh) # 목
	else:
		pd.outlined(torso, _p.cloth, OUT, 0.8)
		pd.draw_line(Vector2(-2.8, waist - 1.0), Vector2(3.2, waist - 1.0), _p.inner, 2.0) # 살구 허리띠
		pd.draw_line(Vector2(-2.8, waist - 1.4), Vector2(3.2, waist - 1.4), _p.inner_hi, 0.6)
		pd.draw_line(Vector2(3.6, waist - 6.4), Vector2(4.0, waist - 3.6), _p.cloth_hi, 1.0)
		pd.draw_rect(Rect2(Vector2(-3.4, waist - 9.0), Vector2(7.2, 2.0)), _p.skin)
		pd.draw_rect(Rect2(Vector2(-3.4, waist - 9.0), Vector2(7.2, 0.8)), _p.skin_hi)
		pd.draw_rect(Rect2(Vector2(-0.2, waist - 10.6), Vector2(2.2, 1.8)), _p.skin_sh)
	# ── 얼굴
	var hc := o + Vector2(1.3, -29.2)
	pd.draw_circle(hc, 3.3, _p.skin)
	pd.draw_rect(Rect2(hc + Vector2(-2.6, -3.2), Vector2(5.6, 1.6)), Color(_p.skin_sh, 0.9)) # 챙 그늘
	pd.draw_rect(Rect2(hc + Vector2(1.6, 1.5), Vector2(1.2, 0.8)), _p.skin_sh)
	pd.draw_rect(Rect2(hc + Vector2(2.1, 0.6), Vector2(1.0, 0.5)), Color("#c9736e")) # 입술
	# 정수리 + 앞머리
	pd.draw_circle(o + Vector2(0.1, -30.7), 3.6, _p.hair_sh)
	pd.draw_circle(o + Vector2(0.6, -31.4), 2.4, _p.hair)
	if kind == "ignis":
		# 뻗친 앞머리 (불꽃처럼 몇 갈래)
		var fringe := PackedVector2Array([o + Vector2(-1.0, -33.0), o + Vector2(2.0, -34.6), o + Vector2(4.6, -32.4), o + Vector2(5.4, -29.0),
			o + Vector2(3.6, -27.4), o + Vector2(2.8, -29.6), o + Vector2(0.4, -30.4), o + Vector2(-0.6, -31.8)])
		pd.outlined(fringe, _p.hair, OUT, 0.6)
		pd.draw_line(o + Vector2(3.6, -32.0), o + Vector2(4.6, -29.2), _p.hair_hi, 0.9)
		pd.draw_line(o + Vector2(1.4, -33.4), o + Vector2(2.2, -30.6), _p.hair_hi, 0.7)
		for i in 3: # 뒤통수 뻗친 머리
			var a := -2.4 + 0.5 * float(i)
			var base := o + Vector2(-2.0 - 0.6 * float(i), -31.6 + 0.8 * float(i))
			pd.draw_line(base, base + Vector2.from_angle(a) * 3.6, _p.hair, 1.4)
			pd.draw_line(base, base + Vector2.from_angle(a) * 3.0, _p.hair_hi, 0.5)
	else:
		var fringe := PackedVector2Array([o + Vector2(0.4, -33.4), o + Vector2(4.4, -31.8), o + Vector2(4.9, -28.2),
			o + Vector2(3.6, -27.4), o + Vector2(2.6, -29.0), o + Vector2(0.0, -30.6)])
		pd.outlined(fringe, _p.hair, OUT, 0.6)
		pd.draw_line(o + Vector2(3.5, -31.4), o + Vector2(4.0, -28.4), _p.hair_hi, 0.8)
	# 앞 머리 줄 (이그니스: 뻗친 옆머리 / 엠버: 앞 땋은 머리)
	if kind == "ember":
		_braid(_hair2.p, 2.4, 1.6)
		var tp: PackedVector2Array = _ribbon(_hair2.p, 1.0, 1.0)[2]
		var tipp: Vector2 = tp[tp.size() - 1]
		pd.draw_line(tipp + Vector2(-1.3, 0.0), tipp + Vector2(1.3, 0.0), _p.band, 1.2)
	else:
		var lk := _ribbon(_hair2.p, 2.2, 0.8)
		pd.strip(_grow(lk[0], lk[2], 0.5), _grow(lk[1], lk[2], 0.5), OUT)
		pd.strip(lk[0], lk[1], _p.hair)
	# 눈 (이그니스: 호박빛이 빛남 / 엠버: 갈색 눈 + 반짝 점)
	var eye := o + Vector2(3.5, -28.9)
	if kind == "ignis":
		var ea := 0.7 + 0.3 * sin(_t * 3.0) + glow * 0.3
		pd.glow(eye, 3.0, Color(_p.eye, 0.5 * ea), 0.0)
		pd.draw_rect(Rect2(eye - Vector2(0.7, 0.5), Vector2(1.4, 1.0)), Color(_p.eye, minf(ea, 1.0)))
		pd.draw_rect(Rect2(eye - Vector2(0.2, 0.3), Vector2(0.6, 0.5)), Color(1, 1, 1, minf(ea, 1.0)))
	else:
		pd.draw_rect(Rect2(eye - Vector2(0.7, 0.6), Vector2(1.4, 1.2)), _p.eye)
		pd.draw_rect(Rect2(eye - Vector2(0.4, 0.5), Vector2(0.5, 0.5)), Color(1, 1, 1, 0.95))
	# ── 모자
	var brim_c := o + Vector2(0.4, -33.5)
	if kind == "ignis":
		pd.draw_set_transform_matrix(Transform2D(-0.12 + _tip * 0.05, brim_c))
		var brim := PackedVector2Array()
		var brim_top := PackedVector2Array()
		for i in 24:
			var a := float(i) / 24.0 * TAU
			var jag := 0.6 * sin(a * 7.0) * (0.5 + 0.5 * cos(a)) # 앞쪽 챙 끝이 그을려 들쭉날쭉
			brim.append(Vector2(cos(a) * (13.8 + jag), sin(a) * 2.4))
			brim_top.append(Vector2(cos(a) * 12.6, sin(a) * 1.4 - 0.5))
		pd.outlined(brim, _p.hat, OUT, 0.8)
		pd.convex(brim_top, _p.hat_hi)
		# 그을린 챙 끝에 이는 불씨 (앞쪽)
		for spec: Array in [[13.2, 0.0], [11.0, 1.4], [-12.6, 0.4]]:
			var bx: float = spec[0]
			var by: float = spec[1]
			var k := fl * (0.8 + 0.2 * sin(_t * 11.0 + bx))
			pd.glow(Vector2(bx, by - 0.5), 3.2, Color(_p.glow, 0.35 * k), 0.0)
			pd.draw_line(Vector2(bx - 1.6, by + 0.6), Vector2(bx + 1.6, by + 0.2), Color(_p.brim_edge, 0.9 * k), 0.9)
			pd.draw_rect(Rect2(Vector2(bx - 0.4, by - 1.4 - 0.8 * k), Vector2(0.8, 0.8)), Color(_p.glow_pale, k))
		pd.draw_set_transform(Vector2.ZERO)
		var tip := Vector2(5.2 + _tip * 2.0, -46.5 + absf(_tip) * 0.5) # 끝이 앞으로 꺾임
		var crown := PackedVector2Array([o + Vector2(-5.2, -34.3), o + Vector2(5.4, -34.5), o + Vector2(5.0, -38.6),
			o + Vector2(2.4, -42.6), o + tip, o + tip + Vector2(-2.0, 1.4), o + Vector2(-1.2, -41.4), o + Vector2(-4.8, -38.0)])
		pd.outlined(crown, _p.hat, OUT, 0.8)
		pd.draw_colored_polygon(PackedVector2Array([o + Vector2(1.6, -34.5), o + Vector2(5.4, -34.5), o + Vector2(4.6, -38.6), o + Vector2(1.6, -40.0)]), _p.hat_hi)
		pd.draw_line(o + Vector2(-4.8, -35.4), o + Vector2(5.0, -35.6), _p.band, 1.6) # 검붉은 띠
		pd.draw_rect(Rect2(o + Vector2(2.2, -36.6), Vector2(1.6, 1.6)), _p.metal) # 띠 쇠장식
	else:
		pd.draw_set_transform_matrix(Transform2D(-0.05 + _tip * 0.04, brim_c))
		var brim := PackedVector2Array()
		var brim_top := PackedVector2Array()
		for i in 24:
			var a := float(i) / 24.0 * TAU
			brim.append(Vector2(cos(a) * 10.6, sin(a) * 2.2))
			brim_top.append(Vector2(cos(a) * 9.4, sin(a) * 1.3 - 0.5))
		pd.outlined(brim, _p.hat, OUT, 0.8)
		pd.convex(brim_top, _p.hat_hi)
		pd.draw_line(Vector2(-9.0, -0.9), Vector2(8.0, -1.2), _p.cloth_hi, 0.7)
		pd.draw_set_transform(Vector2.ZERO)
		# 둥근 머리에 끝이 뒤로 늘어진 꼭대기 + 작은 종
		var tip := Vector2(-9.0 - _tip * 2.0, -40.0 + absf(_tip) * 0.6)
		var crown := PackedVector2Array([o + Vector2(-4.6, -34.3), o + Vector2(4.8, -34.5), o + Vector2(4.4, -38.8), o + Vector2(1.8, -41.8),
			o + Vector2(-2.6, -42.4), o + tip, o + tip + Vector2(0.4, 1.8), o + Vector2(-4.0, -39.6)])
		pd.outlined(crown, _p.hat, OUT, 0.8)
		pd.draw_colored_polygon(PackedVector2Array([o + Vector2(1.2, -34.5), o + Vector2(4.8, -34.5), o + Vector2(4.2, -38.6), o + Vector2(1.4, -40.2)]), _p.hat_hi)
		pd.draw_line(o + Vector2(-4.4, -35.4), o + Vector2(4.6, -35.6), _p.band, 1.6)
		pd.draw_circle(o + tip + Vector2(-0.6, 1.4), 1.3, OUT)
		pd.draw_circle(o + tip + Vector2(-0.6, 1.4), 0.8, _p.metal) # 종
	# ── 앞팔 + 소매 + 손 + 소품
	var sh := o + Vector2(1.5, -23.5)
	var hand := _hand + Vector2(0, bob)
	var mid := sh.lerp(hand, 0.5)
	var bend := (hand - sh).orthogonal().normalized() * 1.4
	var el := mid + (bend if bend.y > 0.0 else -bend)
	if kind == "ember":
		var sl := _ribbon(_sleeve.p, 4.6, 7.0)
		pd.strip(_grow(sl[0], sl[2], 0.6), _grow(sl[1], sl[2], 0.6), OUT)
		pd.strip(sl[0], sl[1], _p.cloth)
		var sll: PackedVector2Array = sl[0]
		pd.draw_polyline(sll, _p.cloth_hi, 0.6)
		var tip_pts: PackedVector2Array = sl[2]
		pd.draw_line(tip_pts[tip_pts.size() - 1] + Vector2(-3.0, 0), tip_pts[tip_pts.size() - 1] + Vector2(3.0, 0), _p.band, 1.0)
		pd.draw_line(sh, el, _p.skin, 1.7)
		pd.draw_line(el, hand, _p.skin, 1.5)
		pd.draw_circle(hand, 1.15, _p.skin)
		_paint_lantern(hand)
	else:
		pd.draw_line(sh, el, _p.cloth, 2.4) # 외투 소매
		pd.draw_line(sh + Vector2(0, -0.5), el + Vector2(0, -0.5), _p.cloth_hi, 0.6)
		pd.draw_line(el, hand, _p.band, 2.2) # 붉은 장갑
		pd.draw_circle(hand, 1.3, _p.band)
		pd.draw_circle(hand + Vector2(0.4, -0.3), 0.5, _p.inner_hi)
		_paint_glove_fire(hand)


## 이그니스: 장갑 끝에서 이는 불 (평소엔 작은 불씨, 시전 중엔 손 전체가 불길)
func _paint_glove_fire(hand: Vector2) -> void:
	var k := 0.25 + 0.75 * glow
	var fl := _flicker
	pd.glow(hand, (4.0 + 9.0 * glow) * fl, Color(_p.glow, 0.45 * k), 0.0)
	for i in 3:
		var ph := _t * 9.0 + float(i) * 2.1
		var h := (2.0 + 5.0 * glow) * (0.7 + 0.3 * sin(ph))
		var base := hand + Vector2(-1.0 + float(i), 0.0)
		var tip := base + Vector2(sin(ph * 0.7) * 1.2, -h)
		pd.line2(base, tip, Color(_p.glow, 0.9 * k), Color(_p.glow_pale, 0.0), 1.8 + glow, 0.4)
	pd.draw_circle(hand, 1.0 + 1.2 * glow, Color(_p.glow_pale, 0.6 + 0.4 * glow))


## 엠버: 놋쇠 등불 (손에서 아래로 매달림). 유리 안 불꽃은 버프를 걸 때 환해진다
func _paint_lantern(hand: Vector2) -> void:
	var top := hand + Vector2(1.5, 1.6)
	var c := hand + Vector2(1.5, 4.6)
	var k := 0.45 + 0.55 * glow
	var fl := _flicker
	pd.glow(c, (6.0 + 10.0 * glow) * fl, Color(_p.glow, 0.4 * k), 0.0)
	pd.draw_line(hand, top, _p.metal, 0.8) # 고리
	pd.outlined(PackedVector2Array([c + Vector2(-2.2, -2.6), c + Vector2(2.2, -2.6), c + Vector2(2.6, 2.4), c + Vector2(-2.6, 2.4)]), Color(_p.glow_pale, 0.55 + 0.3 * glow), OUT, 0.7)
	pd.draw_rect(Rect2(c + Vector2(-2.8, -3.4), Vector2(5.6, 1.0)), _p.metal) # 뚜껑
	pd.draw_rect(Rect2(c + Vector2(-2.9, 2.2), Vector2(5.8, 0.9)), _p.metal) # 받침
	pd.draw_line(c + Vector2(-0.3, -2.4), c + Vector2(-0.3, 2.2), Color(_p.metal, 0.6), 0.5) # 살
	var h := (2.0 + 2.4 * glow) * (0.8 + 0.2 * sin(_t * 13.0))
	pd.line2(c + Vector2(0, 1.8), c + Vector2(sin(_t * 8.0) * 0.5, 1.8 - h), Color(_p.glow, 0.95), Color(_p.glow_pale, 0.1), 1.8, 0.5)
	pd.draw_circle(c + Vector2(0, 1.2), 0.7, Color(1, 1, 1, 0.9 * k))


## 큰 마법: 등 뒤 불의 고리 (일곱 마디) + 번짐
func _paint_big_ring(o: Vector2) -> void:
	var k := _big
	var c := o + Vector2(-1.0, -22.0)
	var r := 17.0 * (0.6 + 0.4 * k)
	pd.glow(c, r + 8.0, Color(_p.glow, 0.22 * k), 0.0)
	var spin := _t * 2.6
	for i in 7:
		var a0 := spin + TAU * float(i) / 7.0
		pd.draw_arc(c, r, a0, a0 + TAU / 7.0 * 0.7, 6, Color(_p.glow_pale, 0.75 * k), 1.0)
		var tip := c + Vector2(cos(a0), sin(a0)) * (r + 2.5)
		pd.draw_line(c + Vector2(cos(a0), sin(a0)) * (r - 1.5), tip, Color(_p.glow, 0.8 * k), 1.0)
	pd.draw_arc(c, r * 0.68, -spin * 1.4, -spin * 1.4 + TAU * 0.8, 18, Color(_p.glow, 0.45 * k), 0.8)
