class_name TEnemyArt
extends PDraw.Canvas
## 적 3종 코드 그림 (원점 = 발밑 가운데, 왼쪽(마녀 쪽)을 보는 모습).
## 짚 골렘: 밧줄로 묶은 짚단 몸뚱이 + 자루 머리(검은 눈구멍), 흔들리며 짚 부스러기가 떨어짐 — 불에 약하다.
## 늪 두꺼비: 납작한 녹색 몸, 등의 검은 점·사마귀, 노란 눈(가로 눈동자), 숨 쉴 때 부푸는 목주머니.
## 재의 기사(보스): 잿빛 판금 갑옷에 불씨가 비치는 균열, 연기 같은 망토(흔들리는 줄), 땅에 세운 대검. 버프 때 균열이 환해진다.
## 자세: idle · attack(앞으로 기울어 팔/검을 듦) · hit(움찔·붉게) · buff(균열 번쩍) · down(무너져 옅어짐)

const OUT := Color("#0a090e")
const EMBER := Color("#ff7a2a")
const EMBER_PALE := Color("#ffd9a0")

var kind := "straw_golem"
var pose := "idle"
var fade := 1.0
var flare := 0.0 ## 버프 빛 (0~1)
var _t := 0.0
var _sq := Vector2.ONE
var _sq_v := Vector2.ZERO
var _lean := 0.0
var _lean_v := 0.0
var _hurt_flash := 0.0
var _blink := 0.0
var _cape: EArt.Chain
var _cape2: EArt.Chain
var _ready_done := false
var _bits_t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(kind)


func _ensure() -> void:
	if _ready_done:
		return
	_ready_done = true
	if kind == "ash_knight":
		_cape = EArt.Chain.new()
		_cape.setup(global_transform * _cape_rest(0.0), 4.2)
		_cape2 = EArt.Chain.new()
		_cape2.setup(global_transform * _cape_rest(3.0), 4.2)


func _cape_rest(off: float) -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in 7:
		r.append(Vector2(4.0 + off + 1.4 * float(i), -40.0 + 4.0 * float(i)))
	return r


func height() -> float:
	match kind:
		"straw_golem": return 50.0
		"swamp_toad": return 30.0
		"ash_knight": return 60.0
	return 40.0


func half_w() -> float:
	match kind:
		"straw_golem": return 13.0
		"swamp_toad": return 26.0
		"ash_knight": return 16.0
	return 12.0


func center_local() -> Vector2:
	return Vector2(0, -height() * 0.55)


func set_pose(p: String) -> void:
	pose = p


func hurt() -> void:
	_hurt_flash = 1.0
	_sq = Vector2(1.16, 0.86)
	_sq_v = Vector2.ZERO


func tick(delta: float) -> void:
	_ensure()
	if delta <= 0.0:
		return
	_t += delta
	var dt := minf(delta, 1.0 / 30.0)
	_sq_v += (Vector2.ONE - _sq) * 300.0 * dt - _sq_v * 18.0 * dt
	_sq += _sq_v * dt
	var lean_want := 0.0
	match pose:
		"attack": lean_want = -0.16
		"hit": lean_want = 0.08
	_lean_v += (lean_want - _lean) * 240.0 * dt - _lean_v * 16.0 * dt
	_lean += _lean_v * dt
	_hurt_flash = maxf(_hurt_flash - dt * 5.0, 0.0)
	flare = move_toward(flare, 1.0 if pose == "buff" else 0.0, dt * (4.0 if pose == "buff" else 1.5))
	_blink = maxf(_blink - dt, 0.0)
	if _blink <= 0.0 and _rng.randf() < dt * 0.25:
		_blink = 0.14
	modulate = Color(1.0, 1.0 - 0.5 * _hurt_flash, 1.0 - 0.5 * _hurt_flash, fade)
	var breathe := 1.0 + 0.012 * sin(_t * 1.7)
	scale = Vector2(_sq.x * (2.0 - breathe), _sq.y * breathe)
	rotation = _lean
	if kind == "ash_knight" and _cape != null:
		var grav := Vector2(70.0 + sin(_t * 1.3) * 30.0, -40.0 + sin(_t * 2.1) * 25.0) # 연기 망토: 뒤로 흘러 위로 떠오름
		_cape.step(to_global(Vector2(4.0, -40.0)), global_transform * _cape_rest(0.0), grav, dt, 0.9, 0.05)
		_cape2.step(to_global(Vector2(7.0, -40.0)), global_transform * _cape_rest(3.0), grav * 1.2, dt, 0.9, 0.05)
	_bits_t -= dt
	if _bits_t <= 0.0 and fade > 0.5:
		_bits_t = 0.35 if kind == "ash_knight" else 0.9
		_ambient_bits()
	queue_redraw()


## 가만히 있어도 떨어지는 것: 골렘은 짚 부스러기, 기사는 균열에서 떠오르는 불씨
func _ambient_bits() -> void:
	var pp := PParticles.get_layer(kind == "ash_knight")
	if kind == "straw_golem":
		var p := to_global(Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-40.0, -10.0)))
		pp.spawn(p, Vector2(_rng.randf_range(-6.0, 6.0), 10.0), Vector2(0, 60), 0.8, 1.4, Color("#e8cf86"), Color("#8a6a2e"), 0, 1.0)
	elif kind == "ash_knight":
		var p := to_global(Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-38.0, -24.0)))
		pp.spawn(p, Vector2(_rng.randf_range(-8.0, 8.0), -_rng.randf_range(14.0, 30.0)), Vector2.ZERO, 0.9, 1.4, EMBER_PALE, Color(EMBER, 0.0), 0, 0.5)


func _paint() -> void:
	if not _ready_done:
		return
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
	pd.glow(Vector2.ZERO, half_w() * 0.9, Color(0, 0, 0, 0.5), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	match kind:
		"straw_golem": _paint_golem()
		"swamp_toad": _paint_toad()
		"ash_knight": _paint_knight()


func _ribbon(ch: PackedVector2Array, w0: float, w1: float) -> Array:
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
		l.append(loc[i] + nrm * w)
		r.append(loc[i] - nrm * w)
	return [l, r, loc]


## 짚단: 윤곽 다각형 + 세로 결
func _straw(pts: PackedVector2Array, base: Color, strands: int, seed_v: int) -> void:
	pd.outlined(pts, base, OUT, 0.8)
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var top := pts[0].y
	var bot := pts[0].y
	var xl := pts[0].x
	var xr := pts[0].x
	for p in pts:
		top = minf(top, p.y)
		bot = maxf(bot, p.y)
		xl = minf(xl, p.x)
		xr = maxf(xr, p.x)
	for i in strands:
		var x := lerpf(xl + 1.5, xr - 1.5, (float(i) + 0.5) / float(strands)) + r.randf_range(-0.6, 0.6)
		var dark := i % 2 == 0
		pd.draw_line(Vector2(x, top + 1.5 + r.randf_range(0, 2)), Vector2(x + r.randf_range(-1.0, 1.0), bot - 1.5 - r.randf_range(0, 2)),
			Color("#8a6a2e") if dark else Color("#e8cf86"), 0.7 if dark else 0.5)


func _paint_golem() -> void:
	var sway := sin(_t * 1.1) * 0.6
	var atk := 1.0 if pose == "attack" else 0.0
	# 다리 (짚단 두 개)
	_straw(PackedVector2Array([Vector2(-8.5, -14), Vector2(-2.5, -14), Vector2(-1.5, -1), Vector2(-9.5, 0)]), Color("#b89650"), 3, 11)
	_straw(PackedVector2Array([Vector2(2.5, -14), Vector2(8.5, -14), Vector2(9.5, 0), Vector2(1.5, -1)]), Color("#b89650"), 3, 12)
	for x: float in [-5.5, 5.5]: # 발 끝 삐죽한 짚
		for i in 3:
			pd.draw_line(Vector2(x - 2 + float(i) * 2, -0.5), Vector2(x - 3 + float(i) * 3, 1.6), Color("#8a6a2e"), 0.7)
	# 몸통 (큰 짚단, 밧줄 두 줄)
	var torso := PackedVector2Array([Vector2(-11 + sway, -40), Vector2(11 + sway, -40), Vector2(12.5, -24), Vector2(10, -13), Vector2(-10, -13), Vector2(-12.5, -24)])
	_straw(torso, Color("#c9a85c"), 7, 3)
	for y: float in [-33.0, -20.0]:
		pd.draw_line(Vector2(-12.6 + sway * 0.5, y), Vector2(12.6 + sway * 0.5, y + 0.8), Color("#6b3f1f"), 2.2)
		pd.draw_line(Vector2(-12.0 + sway * 0.5, y - 0.6), Vector2(12.0 + sway * 0.5, y + 0.2), Color("#9a6a3a"), 0.6)
	pd.draw_rect(Rect2(Vector2(-13.5, -34.5), Vector2(2.4, 3.0)), Color("#6b3f1f")) # 매듭
	# 팔 (앞팔은 공격 때 들린다)
	var arm_back := PackedVector2Array([Vector2(8, -37), Vector2(13, -36), Vector2(16, -18), Vector2(11, -17)])
	_straw(arm_back, Color("#b08c48"), 3, 21)
	var lift := atk * 14.0
	var arm := PackedVector2Array([Vector2(-9, -37), Vector2(-14, -36 - lift * 0.3), Vector2(-20 - lift * 0.6, -18 - lift), Vector2(-14, -16 - lift)])
	_straw(arm, Color("#c9a85c"), 3, 22)
	for i in 4: # 팔 끝 풀린 짚
		var e := Vector2(-18 - lift * 0.6 + float(i) * 1.6, -16.5 - lift)
		pd.draw_line(e, e + Vector2(-1.5 + float(i) * 0.8, 3.0), Color("#8a6a2e"), 0.8)
	# 머리: 자루 (목 밧줄)
	var hc := Vector2(sway * 1.4, -48)
	var head := PackedVector2Array([hc + Vector2(-7, -7), hc + Vector2(-3, -10), hc + Vector2(4, -10), hc + Vector2(7.5, -6), hc + Vector2(7, 6), hc + Vector2(-7, 6)])
	pd.outlined(head, Color("#a6894a"), OUT, 0.8)
	pd.draw_line(hc + Vector2(-5.5, -7), hc + Vector2(-2, 5), Color("#8a6a2e"), 0.6)
	pd.draw_line(hc + Vector2(-7, 6.5), hc + Vector2(7, 7), Color("#6b3f1f"), 2.0)
	pd.draw_line(hc + Vector2(-3, -10), hc + Vector2(-1, -14), Color("#8a6a2e"), 1.6) # 자루 매듭 끝
	pd.draw_line(hc + Vector2(4, -10), hc + Vector2(6, -13), Color("#8a6a2e"), 1.6)
	# 눈구멍 둘 (어둡고 깊음, 안에서 아주 옅은 불씨)
	for ex: float in [-4.0, 2.0]:
		var e := hc + Vector2(ex, -2)
		pd.draw_colored_polygon(PackedVector2Array([e + Vector2(-2, -1.5), e + Vector2(2.4, -2), e + Vector2(2, 1.5), e + Vector2(-2.2, 1.2)]), OUT)
		pd.draw_rect(Rect2(e + Vector2(-0.4, -0.3), Vector2(1.0, 0.8)), Color(EMBER, 0.5 + 0.3 * sin(_t * 3.0 + ex)))
	pd.draw_line(hc + Vector2(-3, 3), hc + Vector2(3, 3.4), OUT, 0.8) # 꿰맨 입


func _paint_toad() -> void:
	var br := 0.5 + 0.5 * sin(_t * 1.9)
	var atk := 1.0 if pose == "attack" else 0.0
	var body := PackedVector2Array()
	for i in 26:
		var a := TAU * float(i) / 26.0
		var rx := 24.0 + 1.5 * sin(a * 3.0)
		var ry := 14.0 + atk * 2.0
		body.append(Vector2(cos(a) * rx, -14.0 + sin(a) * ry * (1.15 if sin(a) > 0 else 1.0)))
	pd.outlined(body, Color("#6f8a3a"), OUT, 0.9)
	# 배 (밝음)
	pd.draw_set_transform(Vector2(0, -8.0), 0.0, Vector2(1.0, 0.45))
	pd.glow(Vector2.ZERO, 20.0, Color("#b8c48a"), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	# 등의 검은 점·사마귀
	for spec: Array in [[-10, -22, 3.0], [-2, -25, 2.4], [8, -22, 3.2], [14, -17, 2.0], [-16, -16, 2.0], [3, -19, 1.6]]:
		var c := Vector2(spec[0], spec[1])
		pd.draw_circle(c, float(spec[2]), Color("#4b6128"))
		pd.draw_circle(c + Vector2(-0.6, -0.6), float(spec[2]) * 0.45, Color("#88a34a"))
	# 목주머니 (숨 쉴 때 부풂, 공격 때 크게)
	var sac := Vector2(-19.0, -8.0)
	var sr := 4.5 + 2.5 * br + atk * 4.0
	pd.draw_circle(sac, sr + 0.8, OUT)
	pd.draw_circle(sac, sr, Color("#d7e0a8"))
	pd.draw_circle(sac + Vector2(-1.0, -1.2), sr * 0.4, Color("#eef2cf"))
	# 앞다리 (벌림)
	for s: float in [-1.0, 1.0]:
		var hip := Vector2(-14.0 * (s if s > 0 else 1.0) + (6.0 if s < 0 else -24.0), -8.0)
		var knee := hip + Vector2(-5.0 if s < 0 else 5.0, 4.0)
		var foot := knee + Vector2(-5.0 if s < 0 else 4.0, 4.0)
		pd.draw_line(hip, knee, Color("#5d7531"), 4.0)
		pd.draw_line(knee, foot, Color("#5d7531"), 3.2)
		for j in 3:
			pd.draw_line(foot, foot + Vector2((-4.0 + float(j) * 1.6) * (1.0 if s < 0 else -1.0) - (0.0 if s < 0 else 2.0), 1.4), Color("#4b6128"), 1.4)
	# 머리 쪽: 눈 둘 (노랑, 가로 눈동자), 입선
	for ex: float in [-16.0, -8.0]:
		var e := Vector2(ex, -27.0)
		var open := 1.0 if _blink <= 0.0 else 0.2
		pd.draw_circle(e, 3.6, OUT)
		pd.draw_circle(e, 3.0 * open + 0.2, Color("#e9c93f"))
		pd.draw_rect(Rect2(e + Vector2(-2.2, -0.6 * open), Vector2(4.4, 1.2 * open + 0.2)), OUT)
		pd.draw_rect(Rect2(e + Vector2(-1.4, -2.0), Vector2(0.8, 0.8)), Color(1, 1, 1, 0.8 * open))
	pd.draw_line(Vector2(-25.5, -13.0), Vector2(-6.0, -11.0), OUT, 1.0)
	if atk > 0.0: # 공격: 혀
		pd.draw_line(Vector2(-25.0, -12.5), Vector2(-44.0, -16.0), Color("#d9607a"), 2.4)
		pd.draw_circle(Vector2(-44.0, -16.0), 2.0, Color("#d9607a"))


func _paint_knight() -> void:
	var fl := flare
	var atk := 1.0 if pose == "attack" else 0.0
	var pulse := 0.6 + 0.4 * sin(_t * 2.6)
	var ember := Color(EMBER).lerp(EMBER_PALE, 0.5 * fl)
	# 연기 망토 (몸 뒤)
	if _cape != null:
		for ch: EArt.Chain in [_cape2, _cape]:
			var r := _ribbon(ch.p, 7.0, 11.0)
			pd.strip(r[0], r[1], Color("#1e1a24", 0.85))
			var hi := _ribbon(ch.p, 3.0, 5.0)
			pd.strip(hi[0], hi[1], Color("#3a3342", 0.7))
	var plate := Color("#5a5560")
	var plate_hi := Color("#7d7686")
	var plate_dk := Color("#3a3540")
	# 다리
	for x: float in [-5.0, 4.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 3.4, -22), Vector2(x + 3.4, -22), Vector2(x + 3.0, -2), Vector2(x - 3.0, -2)]), plate, OUT, 0.8)
		pd.draw_line(Vector2(x - 1.6, -20), Vector2(x - 1.4, -4), plate_hi, 0.8)
		pd.outlined(PackedVector2Array([Vector2(x - 4.2, -2.5), Vector2(x + 4.6, -2.5), Vector2(x + 5.4, 0.5), Vector2(x - 4.4, 0.5)]), plate_dk, OUT, 0.8) # 발
		pd.draw_line(Vector2(x - 3.2, -12), Vector2(x + 3.2, -12), plate_dk, 1.2) # 무릎 이음
	# 허리·몸통 (가슴판에 균열)
	var torso := PackedVector2Array([Vector2(-10, -48), Vector2(10, -48), Vector2(11.5, -36), Vector2(8, -22), Vector2(-8, -22), Vector2(-11.5, -36)])
	pd.outlined(torso, plate, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-10, -48), Vector2(-2, -48), Vector2(-3, -24), Vector2(-8, -22), Vector2(-11.5, -36)]), plate_hi)
	pd.draw_line(Vector2(-9, -34), Vector2(9, -34), plate_dk, 1.4)
	pd.draw_line(Vector2(-8, -26), Vector2(8, -26), plate_dk, 1.0)
	# 균열 (불씨가 비침) — 버프 때 환해진다
	var ca := 0.55 + 0.45 * pulse + fl
	pd.glow(Vector2(-1, -38), 9.0 + 10.0 * fl, Color(EMBER, 0.25 * ca), 0.0)
	for seg: Array in [[Vector2(-2, -46), Vector2(0, -40), Vector2(-3, -34), Vector2(1, -28)], [Vector2(3, -42), Vector2(5, -37), Vector2(3, -33)], [Vector2(-6, -31), Vector2(-4, -27)]]:
		for i in range(1, seg.size()):
			pd.draw_line(seg[i - 1], seg[i], Color(ember, minf(ca, 1.0)), 1.2 + fl)
			pd.draw_line(seg[i - 1], seg[i], Color(EMBER_PALE, 0.6 * minf(ca, 1.0)), 0.5)
	# 어깨 갑옷 (양쪽, 뾰족)
	for s: float in [-1.0, 1.0]:
		var sx := s * 12.0
		pd.outlined(PackedVector2Array([Vector2(sx - 5 * s, -50), Vector2(sx + 6 * s, -47), Vector2(sx + 4 * s, -40), Vector2(sx - 4 * s, -42)]), plate_hi if s < 0 else plate, OUT, 0.8)
		pd.draw_line(Vector2(sx + 5 * s, -48), Vector2(sx + 8 * s, -53), plate_dk, 1.6) # 뿔
	# 투구 (높은 투구, 가는 눈구멍에 불빛)
	var hc := Vector2(0, -57)
	var helm := PackedVector2Array([hc + Vector2(-6, -8), hc + Vector2(-2, -12), hc + Vector2(3, -12), hc + Vector2(6.5, -7), hc + Vector2(6.5, 5), hc + Vector2(3, 8), hc + Vector2(-5, 8), hc + Vector2(-7, 2)])
	pd.outlined(helm, plate, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(-6, -8), hc + Vector2(-2, -12), hc + Vector2(-2, 7), hc + Vector2(-5, 8), hc + Vector2(-7, 2)]), plate_hi)
	pd.draw_line(hc + Vector2(-6.5, 0), hc + Vector2(6.5, 0), plate_dk, 1.0)
	pd.glow(hc + Vector2(-2, -2), 5.0 + 4.0 * fl, Color(EMBER, 0.4 * ca), 0.0)
	pd.draw_line(hc + Vector2(-7, -2.5), hc + Vector2(-1, -2.0), Color(ember, minf(ca, 1.0)), 1.4) # 눈구멍 빛
	pd.draw_line(hc + Vector2(-6.5, -2.5), hc + Vector2(-2, -2.1), EMBER_PALE, 0.5)
	pd.draw_line(hc + Vector2(0, -12), hc + Vector2(1, -20 - fl * 3.0), Color("#2a2430"), 2.0) # 투구 위 깃(연기)
	pd.draw_line(hc + Vector2(0, -12), hc + Vector2(-3, -18 - fl * 2.0), Color("#2a2430"), 1.4)
	# 팔 + 대검 (서 있을 땐 땅에 세움, 공격 때 들어 올림)
	var sh := Vector2(-11, -44)
	var hand := Vector2(-14, -30).lerp(Vector2(-18, -48), atk)
	var el := sh.lerp(hand, 0.5) + Vector2(-3, 1)
	pd.draw_line(sh, el, plate, 3.6)
	pd.draw_line(el, hand, plate, 3.2)
	pd.draw_circle(hand, 2.4, plate_dk)
	var sdir := Vector2(0, 1).lerp(Vector2(-0.6, -0.8).normalized(), atk).normalized()
	var guard := hand + sdir * 2.0
	var tip := guard + sdir * 34.0
	pd.draw_line(hand - sdir * 5.0, guard, Color("#2a2430"), 2.6) # 자루
	pd.draw_line(guard + sdir.orthogonal() * 6.0, guard - sdir.orthogonal() * 6.0, plate_dk, 2.6) # 날밑
	pd.line2(guard, tip + sdir * 1.0, OUT, OUT, 6.0, 1.6)
	pd.line2(guard, tip, Color("#8d8793"), Color("#b9b3c2"), 4.2, 0.8)
	pd.line2(guard + sdir.orthogonal() * 0.8, tip, Color(ember, 0.9), Color(EMBER_PALE, 0.4), 1.0, 0.3) # 불씨 서린 날
	if atk > 0.0:
		pd.glow(tip, 8.0, Color(EMBER, 0.5), 0.0)
