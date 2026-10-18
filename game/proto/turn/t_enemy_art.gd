class_name TEnemyArt
extends PDraw.Canvas
## 적 3종 코드 그림 (원점 = 발밑 가운데, 왼쪽(마녀 쪽)을 보는 모습).
## 짚 골렘: 밧줄로 묶은 짚단 몸뚱이 + 자루 머리(검은 눈구멍), 흔들리며 짚 부스러기가 떨어짐 — 불에 약하다.
## 늪 두꺼비: 납작한 녹색 몸, 등의 검은 점·사마귀, 노란 눈(가로 눈동자), 숨 쉴 때 부푸는 목주머니.
## 재의 기사(보스): 잿빛 판금 갑옷에 불씨가 비치는 균열, 연기 같은 망토(흔들리는 줄), 땅에 세운 대검. 버프 때 균열이 환해진다.
## 재의 왕(보스, 단계 D 전용): 재의 기사 몸을 바탕으로 숯 왕관(뾰족 5, 틈에서 주황 빛) · 해진 망토 3장(끝이 재로 흩어짐) · 두 손 대검(1.4배) ·
##   가슴 화로가 1.2초 주기로 맥박 · 줄마다 모습이 바뀜: 2줄째 = 화로 빛 2배·눈 빨강, 3줄째 = 망토가 타 없어지고 몸 둘레에 불씨 고리.
## 시련의 거상(시련 보스, 단계 D 전용): 금빛 룬을 새긴 돌 거인, 외눈, 큰 돌 주먹 · 2줄째 = 금 간 틈에서 주황 빛, 3줄째 = 어깨 돌판이 떨어지고 녹은 심장 + 떠도는 돌.
## 자세: idle · attack(앞으로 기울어 팔/검을 듦) · hit(움찔·붉게) · buff(균열 번쩍) · down(무너져 옅어짐)

const OUT := Color("#0a090e")
const EMBER := Color("#ff7a2a")
const EMBER_PALE := Color("#ffd9a0")
const RIM_LIGHT := Color(0.85, 0.82, 1.0, 0.38) ## 테두리 빛 (마녀와 같은 방법, 조금 옅게)
const RIM_OFFS: Array[Vector2] = [Vector2(-0.5, -0.5), Vector2(0.5, 0.5)]
const OWN_ART := ["ash_king", "trial_colossus"] ## 데이터의 art 대신 id로 그리는 전용 그림

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
var phase := 0 ## 보스 줄 번호 (TActor가 unit.bar_i를 넣는다) — 줄마다 모습이 바뀜
var _phase_flash := 0.0
var _white := 0.0
var _rim_ci := RID()


## 유닛 id·데이터 art → 그릴 그림 (전용 그림이 있으면 id)
static func kind_for(id: String, art: String) -> String:
	return id if id in OWN_ART else art


func _ready() -> void:
	_rng.seed = hash(kind)
	_rim_ci = TWitchArt.rim_make(self, RIM_LIGHT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rim_ci.is_valid():
		RenderingServer.free_rid(_rim_ci)


func _draw() -> void:
	_paint()
	TWitchArt.rim_paint(_rim_ci, pd, RIM_OFFS if fade >= 0.99 else []) # 옅어지는 중엔 테두리 빛이 비쳐 흰 실루엣이 되므로 끔
	pd.flush(self)


## 줄이 깨져 다음 줄로: 모습이 바뀌며 불씨가 터진다
func set_phase(p: int) -> void:
	if p == phase:
		return
	phase = p
	_phase_flash = 1.0
	var pp := PParticles.get_layer(true)
	for i in 24:
		var an := _rng.randf() * TAU
		pp.spawn(to_global(Vector2(_rng.randf_range(-12, 12), -_rng.randf_range(10, height()))), Vector2.from_angle(an) * _rng.randf_range(60, 180), Vector2(0, 80), 0.7, _rng.randf_range(1.4, 2.6), EMBER_PALE, Color(EMBER, 0.0), 1, 1.5)


func _ensure() -> void:
	if _ready_done:
		return
	_ready_done = true
	if kind in ["ash_knight"]:
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
		"ash_king": return 60.0
		"trial_colossus": return 62.0
	return 40.0


func half_w() -> float:
	match kind:
		"straw_golem": return 13.0
		"swamp_toad": return 26.0
		"ash_knight": return 16.0
		"ash_king": return 19.0
		"trial_colossus": return 22.0
	return 12.0


func center_local() -> Vector2:
	return Vector2(0, -height() * 0.55)


func set_pose(p: String) -> void:
	pose = p


func hurt() -> void:
	_hurt_flash = 1.0
	_white = 0.06
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
	_white = maxf(_white - delta, 0.0)
	_phase_flash = maxf(_phase_flash - dt * 1.5, 0.0)
	if _white > 0.0 or _phase_flash > 0.8:
		modulate = Color(2.4, 2.4, 2.4, fade)
	else:
		modulate = Color(1.0, 1.0 - 0.5 * _hurt_flash, 1.0 - 0.5 * _hurt_flash, fade)
	var breathe := 1.0 + 0.015 * sin(_t * 1.7)
	scale = Vector2(_sq.x * (2.0 - breathe), _sq.y * breathe)
	rotation = _lean
	if kind == "ash_knight" and _cape != null:
		var grav := Vector2(70.0 + sin(_t * 1.3) * 30.0, -40.0 + sin(_t * 2.1) * 25.0) # 연기 망토: 뒤로 흘러 위로 떠오름
		_cape.step(to_global(Vector2(4.0, -40.0)), global_transform * _cape_rest(0.0), grav, dt, 0.9, 0.05)
		_cape2.step(to_global(Vector2(7.0, -40.0)), global_transform * _cape_rest(3.0), grav * 1.2, dt, 0.9, 0.05)
	_bits_t -= dt
	if _bits_t <= 0.0 and fade > 0.5:
		_bits_t = 0.35 if kind in ["ash_knight", "ash_king"] else (0.5 if kind == "trial_colossus" else 0.9)
		_ambient_bits()
	queue_redraw()


## 가만히 있어도 떨어지는 것: 골렘은 짚 부스러기, 기사는 균열에서 떠오르는 불씨
func _ambient_bits() -> void:
	var pp := PParticles.get_layer(kind in ["ash_knight", "ash_king", "trial_colossus"])
	if kind == "straw_golem":
		var p := to_global(Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-40.0, -10.0)))
		pp.spawn(p, Vector2(_rng.randf_range(-6.0, 6.0), 10.0), Vector2(0, 60), 0.8, 1.4, Color("#e8cf86"), Color("#8a6a2e"), 0, 1.0)
	elif kind == "ash_knight":
		var p := to_global(Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-38.0, -24.0)))
		pp.spawn(p, Vector2(_rng.randf_range(-8.0, 8.0), -_rng.randf_range(14.0, 30.0)), Vector2.ZERO, 0.9, 1.4, EMBER_PALE, Color(EMBER, 0.0), 0, 0.5)
	elif kind == "ash_king":
		# 망토 끝이 재로 흩어짐 (3줄째엔 몸 둘레 불씨)
		var ash := PParticles.get_layer(false)
		if phase < 2:
			var p := to_global(Vector2(_rng.randf_range(6.0, 24.0), _rng.randf_range(-6.0, 0.0)))
			ash.spawn(p, Vector2(_rng.randf_range(4.0, 20.0), -_rng.randf_range(10.0, 30.0)), Vector2(6, -10), 1.0, _rng.randf_range(1.2, 2.2), Color("#6a5f70"), Color("#3a3240", 0.0), 0, 0.5)
		var q := to_global(Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-50.0, -30.0)))
		pp.spawn(q, Vector2(_rng.randf_range(-10.0, 10.0), -_rng.randf_range(20.0, 40.0)), Vector2.ZERO, 0.9, 1.4, EMBER_PALE, Color(EMBER, 0.0), 0, 0.5)
	elif kind == "trial_colossus":
		# 몸에서 떨어지는 돌가루 · 룬에서 오르는 금빛
		var dust := PParticles.get_layer(false)
		var p := to_global(Vector2(_rng.randf_range(-16.0, 16.0), _rng.randf_range(-48.0, -20.0)))
		dust.spawn(p, Vector2(_rng.randf_range(-6.0, 6.0), 8.0), Vector2(0, 80), 0.8, 1.4, Color("#9a96a6"), Color("#5a5662", 0.0), 0, 1.0)
		var q := to_global(Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-44.0, -24.0)))
		pp.spawn(q, Vector2(0, -_rng.randf_range(16.0, 30.0)), Vector2.ZERO, 0.8, 1.2, Color("#ffe08a"), Color("#c9a24a", 0.0), 0, 0.5)


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
		"ash_king": _paint_king()
		"trial_colossus": _paint_colossus()


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


# ═══════════════════════════════════════════════════════════
# 보스 전용 그림 (단계 D)
# ═══════════════════════════════════════════════════════════

## 해진 망토 한 장: 어깨 top에서 아래로 len, 끝이 들쭉날쭉 (흔들림 sway)
func _cape_piece(top: Vector2, w: float, len: float, sway: float, col: Color, lining: Color, seed_i: int) -> void:
	var pts := PackedVector2Array([top, top + Vector2(w, 1.0)])
	var n := 5
	var br := top + Vector2(w + 4.0 + sway * 1.6, len)
	var bl := top + Vector2(-2.0 + sway, len - 3.0)
	pts.append(top + Vector2(w + 2.0 + sway * 0.6, len * 0.5))
	for i in n + 1: # 아래 끝 (오른쪽 → 왼쪽, 들쭉날쭉)
		var f := float(i) / float(n)
		var p := br.lerp(bl, f)
		p.y += (3.5 if i % 2 == 0 else -1.0) * (0.6 + 0.4 * EVfx.hash01(seed_i * 7 + i)) + sin(_t * 2.0 + float(i) + float(seed_i)) * 0.8
		pts.append(p)
	pts.append(top + Vector2(-1.0 + sway * 0.4, len * 0.5))
	pd.outlined(pts, col, OUT, 0.8)
	pd.draw_line(top + Vector2(1.0, 2.0), bl + Vector2(1.0, -3.0), lining, 1.0)


func _paint_king() -> void:
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.93, 0.93)) # 왕관 끝이 보스 카드(y 82) 아래에 오게 (화면 키 약 170)
	var fl := flare
	var atk := 1.0 if pose == "attack" else 0.0
	var beat := 0.5 + 0.5 * sin(_t * TAU / 0.8) # 가슴 화로 맥박 0.8초 (review_D C2)
	var core_k := 2.0 if phase >= 1 else 1.0
	var ember := Color(EMBER).lerp(EMBER_PALE, 0.5 * fl)
	var eye := Color("#ff2a2a") if phase >= 1 else EMBER
	var plate := Color("#4a4452")
	var plate_hi := Color("#6c6578")
	var plate_dk := Color("#2a2630")
	var gold := Color("#b8903e")
	var gold_hi := Color("#ffe08a")
	var bk := Color("#1a1418")
	# 3줄째: 몸 둘레 불씨 고리 (뒤 반)
	if phase >= 2:
		_ember_ring(true)
	# 해진 망토 3장 (몸 뒤, 등 쪽 +x로 흘러내림) — 3줄째엔 타서 없어지고 그을린 끝만
	if phase < 2:
		for i in [2, 1, 0]:
			var c := Color("#2a1e28").darkened(0.12 * float(i))
			_cape_piece(Vector2(-2.0 + 6.0 * float(i), -50.0), 9.0, 48.0 - 5.0 * float(i), sin(_t * 1.3 + float(i) * 0.9) * 2.0, c, Color("#6b1a22"), i)
	else:
		for i in 3:
			var top := Vector2(-2.0 + 6.0 * float(i), -50.0)
			var pts := PackedVector2Array([top, top + Vector2(9, 1), top + Vector2(10, 12 + 2.0 * sin(_t * 3.0 + float(i))), top + Vector2(4, 9), top + Vector2(-1, 13)])
			pd.outlined(pts, Color("#1e1418"), OUT, 0.8)
			pd.draw_line(top + Vector2(-1, 13), top + Vector2(10, 12), Color(EMBER, 0.8 + 0.2 * sin(_t * 9.0 + float(i))), 1.0)
	# 다리 (넓게 선 정강이 갑옷 + 금 무릎)
	for x: float in [-8.0, 6.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 4.0, -24), Vector2(x + 4.0, -24), Vector2(x + 3.4, -2), Vector2(x - 3.4, -2)]), plate, OUT, 0.8)
		pd.draw_line(Vector2(x - 2.0, -22), Vector2(x - 1.8, -4), plate_hi, 0.9)
		pd.draw_line(Vector2(x + 2.4, -22), Vector2(x + 2.0, -4), plate_dk, 0.9)
		pd.outlined(PackedVector2Array([Vector2(x - 3.0, -15), Vector2(x + 3.0, -15), Vector2(x + 2.4, -11), Vector2(x - 2.4, -11)]), gold, OUT, 0.6)
		pd.outlined(PackedVector2Array([Vector2(x - 5.0, -2.5), Vector2(x + 5.4, -2.5), Vector2(x + 6.2, 0.6), Vector2(x - 5.2, 0.6)]), plate_dk, OUT, 0.8)
	# 허리 갑옷 자락 (금테)
	var fauld := PackedVector2Array([Vector2(-12, -30), Vector2(12, -30), Vector2(14, -20), Vector2(5, -22), Vector2(0, -19), Vector2(-5, -22), Vector2(-14, -20)])
	pd.outlined(fauld, plate_dk, OUT, 0.8)
	pd.draw_line(Vector2(-13, -21), Vector2(13, -21), gold, 1.0)
	# 몸통: 위가 넓은 사다리꼴 가슴판 (허리 0.65배) — 왼쪽 빛 · 오른쪽 그늘 · 가운데 능선 (review_D C2: 예전엔 직사각 블록)
	var torso := PackedVector2Array([Vector2(-15, -52), Vector2(15, -52), Vector2(13.5, -41), Vector2(9.5, -28), Vector2(-9.5, -28), Vector2(-13.5, -41)])
	pd.outlined(torso, plate, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-15, -52), Vector2(-3, -52), Vector2(-3.5, -29), Vector2(-9.5, -28), Vector2(-13.5, -41)]), plate_hi)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(7, -52), Vector2(15, -52), Vector2(13.5, -41), Vector2(9.5, -28), Vector2(5.5, -29)]), plate_dk)
	pd.draw_line(Vector2(-0.5, -51), Vector2(-0.8, -30), Color(plate_hi, 0.7), 0.8)
	pd.draw_line(Vector2(-14, -51), Vector2(14, -51), gold, 1.2)
	# 몸 오른쪽(등 쪽) 붉은 테 조명 — 보스 하늘의 붉은 빛
	pd.draw_line(Vector2(15.4, -51), Vector2(13.9, -41), Color("#ff5a4a", 0.55), 1.0)
	pd.draw_line(Vector2(13.9, -41), Vector2(10.0, -28.5), Color("#ff5a4a", 0.45), 1.0)
	# 가슴 화로 (금 테 안의 불빛, 맥박) — 2줄째부터 2배
	var hc := Vector2(-1, -41)
	var glow_a := (0.35 + 0.35 * beat) * core_k
	pd.glow(hc, (10.0 + 6.0 * beat) * core_k, Color(EMBER, minf(0.35 * glow_a, 0.9)), 0.0)
	pd.outlined(PackedVector2Array([hc + Vector2(0, -6), hc + Vector2(5, 0), hc + Vector2(0, 6), hc + Vector2(-5, 0)]), gold, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(0, -4), hc + Vector2(3.4, 0), hc + Vector2(0, 4), hc + Vector2(-3.4, 0)]), Color(ember).lerp(EMBER_PALE, 0.4 * beat))
	pd.draw_circle(hc, 1.3 + 0.6 * beat, EMBER_PALE)
	# 균열 (화로에서 퍼짐) — 맥박에 맞춰 빛 번짐이 같이 숨쉼
	var ca := minf(0.5 + 0.4 * beat * core_k + fl, 1.0)
	for seg: Array in [[hc + Vector2(-3, -3), Vector2(-8, -48), Vector2(-11, -46)], [hc + Vector2(3, 2), Vector2(7, -34), Vector2(9, -30)], [hc + Vector2(-2, 4), Vector2(-6, -31)]]:
		for i in range(1, seg.size()):
			pd.draw_line(seg[i - 1], seg[i], Color(EMBER, 0.35 * ca * beat), 2.6)
			pd.draw_line(seg[i - 1], seg[i], Color(ember, ca), 1.1)
	# 어깨: 겹친 반원 판 셋 (위 큰 판 → 아래 작은 판), 금테 · 뿔 (review_D C2)
	for sgn: float in [1.0, -1.0]:
		var sx := sgn * 14.0
		var col := plate_hi if sgn < 0 else plate
		for q in 3:
			var c := Vector2(sx + sgn * 1.5 * float(q), -51.0 + 4.2 * float(q))
			var rr := 8.0 - 1.6 * float(q)
			var pts := PackedVector2Array()
			for k in 9:
				var an := PI + PI * float(k) / 8.0
				pts.append(c + Vector2(cos(an) * rr, sin(an) * rr * 0.75))
			pd.outlined(pts, col if q == 0 else (plate if q == 1 else plate_dk), OUT, 0.8)
			pd.draw_line(pts[0] + Vector2(0, -0.4), pts[8] + Vector2(0, -0.4), gold if q == 0 else Color(gold, 0.6), 0.9)
		pd.draw_line(Vector2(sx + 5 * sgn, -56), Vector2(sx + 10 * sgn, -62), bk, 2.0)
	# 투구
	var h := Vector2(-1, -57)
	var helm := PackedVector2Array([h + Vector2(-6.5, -5), h + Vector2(6.5, -5), h + Vector2(7, 5), h + Vector2(3, 8), h + Vector2(-5, 8), h + Vector2(-7.5, 2)])
	pd.outlined(helm, plate, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-6.5, -5), h + Vector2(-1.5, -5), h + Vector2(-1.5, 7.6), h + Vector2(-5, 8), h + Vector2(-7.5, 2)]), plate_hi)
	pd.glow(h + Vector2(-3, 0), 5.0 + 3.0 * float(phase), Color(eye, 0.5), 0.0)
	pd.draw_line(h + Vector2(-7.4, 0.0), h + Vector2(-0.5, 0.4), Color(eye, 1.0), 1.5) # T자 눈구멍 빛 (가로)
	pd.draw_line(h + Vector2(-3.6, 0.6), h + Vector2(-3.4, 6.4), Color(eye, 0.9), 1.3) # (세로)
	pd.draw_line(h + Vector2(-6.8, -0.1), h + Vector2(-2.0, 0.2), EMBER_PALE if phase == 0 else Color("#ffb0a0"), 0.5)
	# 숯 왕관 (뾰족 5, 틈에서 주황 빛)
	var cb := h + Vector2(0, -5)
	pd.glow(cb + Vector2(0, -3), 9.0, Color(EMBER, 0.45 + 0.25 * beat), 0.0)
	pd.outlined(PackedVector2Array([cb + Vector2(-7.2, 0.4), cb + Vector2(7.2, 0.4), cb + Vector2(7.0, -2.0), cb + Vector2(-7.0, -2.0)]), bk, OUT, 0.7)
	var spikes := [[-6.0, 4.0], [-3.0, 5.6], [0.0, 7.0], [3.0, 5.6], [6.0, 4.0]]
	for sp: Array in spikes:
		var x := float(sp[0])
		var tip := cb + Vector2(x, -2.0 - float(sp[1]))
		pd.outlined(PackedVector2Array([cb + Vector2(x - 1.4, -1.8), tip, cb + Vector2(x + 1.4, -1.8)]), bk, OUT, 0.6)
		pd.draw_line(tip + Vector2(0, 1.6), tip, Color(ember, 0.6 + 0.4 * beat), 0.7)
		var fk := 0.5 + 0.5 * sin(_t * 9.0 + x * 1.3) # 왕관 끝마다 불씨 점 (깜빡)
		pd.glow(tip, 2.6, Color(EMBER, 0.5 * fk), 0.0)
		pd.draw_rect(Rect2(tip + Vector2(-0.5, -1.4), Vector2(1, 1)), Color(EMBER_PALE, 0.6 + 0.4 * fk))
	for x: float in [-4.5, -1.5, 1.5, 4.5]: # 틈 빛
		pd.draw_rect(Rect2(cb + Vector2(x - 0.4, -2.6), Vector2(0.8, 0.8)), Color(EMBER_PALE, 0.7 + 0.3 * beat))
	# 대검 (두 손, 1.4배): 서 있을 땐 앞에 꽂아 두 손을 자루 끝에 · 공격 땐 머리 위로
	var hand := Vector2(-12, -38).lerp(Vector2(-16, -60), atk)
	var sdir := Vector2(0, 1).lerp(Vector2(-0.55, -0.83).normalized(), atk).normalized()
	var guard := hand + sdir * 3.0
	var tip2 := guard + sdir * 48.0
	var sh_f := Vector2(-13, -49)
	var sh_b := Vector2(9, -49)
	pd.draw_line(sh_b, hand + Vector2(3, -1), plate_dk, 3.4) # 뒤 팔
	pd.draw_line(sh_f, sh_f.lerp(hand, 0.5) + Vector2(-3, 1), plate, 3.8)
	pd.draw_line(sh_f.lerp(hand, 0.5) + Vector2(-3, 1), hand, plate, 3.4)
	pd.draw_line(hand - sdir * 6.0, guard, bk, 2.8) # 자루
	pd.draw_circle(hand - sdir * 6.5, 1.6, gold) # 자루 끝 구슬
	pd.draw_line(guard + sdir.orthogonal() * 8.0, guard - sdir.orthogonal() * 8.0, gold, 2.6) # 날밑
	pd.draw_line(guard + sdir.orthogonal() * 8.0, guard - sdir.orthogonal() * 8.0, OUT, 0.6)
	pd.line2(guard, tip2 + sdir * 1.2, OUT, OUT, 7.6, 2.0)
	pd.line2(guard, tip2, Color("#7d7686"), Color("#aaa3b6"), 5.6, 1.0)
	pd.line2(guard + sdir.orthogonal() * 1.2, tip2, Color("#cfc9dc"), Color("#cfc9dc", 0.3), 1.0, 0.3)
	pd.line2(guard - sdir.orthogonal() * 0.8, tip2, Color(ember, 0.9), Color(EMBER_PALE, 0.3), 1.2, 0.3) # 불씨 서린 날
	pd.draw_circle(hand, 2.6, plate_dk)
	pd.draw_circle(hand + Vector2(2.0, 1.0), 2.2, plate)
	if atk > 0.0:
		pd.glow(tip2, 10.0, Color(EMBER, 0.55), 0.0)
	if phase >= 2:
		_ember_ring(false)
	if _phase_flash > 0.0:
		pd.glow(Vector2(0, -34), 50.0 * _phase_flash, Color(EMBER, 0.5 * _phase_flash), 0.0)


## 재의 왕 3줄째: 몸 둘레를 도는 불씨 고리 (back = 뒤 반만 / 아니면 앞 반)
func _ember_ring(back: bool) -> void:
	var n := 14
	for i in n:
		var an := TAU * float(i) / float(n) + _t * 1.6
		var behind := sin(an) < 0.0
		if behind != back:
			continue
		var p := Vector2(cos(an) * 22.0, -26.0 + sin(an) * 6.0)
		var hh := 5.0 + 2.0 * sin(_t * 12.0 + float(i) * 1.7)
		pd.glow(p, 4.0, Color(EMBER, 0.4), 0.0)
		pd.convex(PackedVector2Array([p + Vector2(-1.6, 0), p + Vector2(0, -hh), p + Vector2(1.6, 0), p + Vector2(0, 1.2)]), Color(EMBER).lerp(EMBER_PALE, 0.3))
		pd.convex(PackedVector2Array([p + Vector2(-0.7, 0), p + Vector2(0, -hh * 0.5), p + Vector2(0.7, 0)]), EMBER_PALE)


## 시련의 거상: 금빛 룬을 새긴 돌 거인 (외눈 · 큰 돌 주먹). 2줄째 = 틈에서 주황 빛 · 3줄째 = 어깨 돌판이 떨어지고 녹은 심장 + 떠도는 돌
func _paint_colossus() -> void:
	# 0.92배: 줄 3의 떠도는 돌·공격 때 든 주먹이 보스 카드(y 82)에 닿지 않게 (review_D C2)
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.92, 0.92))
	var atk := 1.0 if pose == "attack" else 0.0
	var beat := 0.5 + 0.5 * sin(_t * 2.2)
	var st := Color("#666270")
	var st_hi := Color("#8a8696")
	var st_dk := Color("#45414f")
	var rune := Color("#ffd27a")
	var hot := Color(EMBER).lerp(EMBER_PALE, 0.3 * beat)
	var crack_a := 0.0 if phase == 0 else (0.6 + 0.4 * beat)
	# 3줄째: 떠도는 돌 (뒤)
	if phase >= 2:
		_float_rocks(true)
	# 뒤 팔 (몸 뒤, 어둡게)
	pd.outlined(PackedVector2Array([Vector2(14, -50), Vector2(22, -46), Vector2(24, -26), Vector2(17, -24)]), st_dk, OUT, 0.9)
	pd.outlined(PackedVector2Array([Vector2(16, -26), Vector2(26, -26), Vector2(27, -14), Vector2(16, -13)]), st_dk, OUT, 0.9)
	# 다리 (짧고 굵은 돌기둥)
	for x: float in [-10.0, 8.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 6, -20), Vector2(x + 6, -20), Vector2(x + 6.5, -1), Vector2(x - 6.5, -1)]), st, OUT, 0.9)
		pd.draw_line(Vector2(x - 4.5, -18), Vector2(x - 4.5, -3), st_hi, 1.0)
		pd.draw_line(Vector2(x - 6, -10), Vector2(x + 6, -10.5), st_dk, 1.0)
		pd.outlined(PackedVector2Array([Vector2(x - 7.5, -2), Vector2(x + 7.5, -2), Vector2(x + 8, 0.8), Vector2(x - 8, 0.8)]), st_dk, OUT, 0.8)
	# 몸통 (큰 돌 덩이, 블록 이음 + 금빛 룬)
	var torso := PackedVector2Array([Vector2(-17, -50), Vector2(15, -52), Vector2(19, -36), Vector2(15, -20), Vector2(-15, -19), Vector2(-19, -34)])
	pd.outlined(torso, st, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-17, -50), Vector2(-5, -51), Vector2(-6, -20), Vector2(-15, -19), Vector2(-19, -34)]), st_hi)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(8, -51.5), Vector2(15, -52), Vector2(19, -36), Vector2(15, -20), Vector2(9, -20)]), st_dk)
	pd.draw_line(Vector2(-18, -35), Vector2(18, -36), st_dk, 1.2)
	pd.draw_line(Vector2(-2, -50), Vector2(-3, -36), st_dk, 1.0)
	pd.draw_line(Vector2(4, -35), Vector2(3, -20), st_dk, 1.0)
	# 룬 (가슴 원 + 세로 획들)
	var rc := Vector2(-1, -42)
	var ra := 0.6 + 0.4 * beat
	pd.glow(rc, 9.0, Color(rune, 0.25 * ra), 0.0)
	pd.draw_arc(rc, 5.0, 0.0, TAU, 18, Color(rune, ra), 1.0)
	pd.draw_line(rc + Vector2(0, -3.5), rc + Vector2(0, 3.5), Color(rune, ra), 1.0)
	pd.draw_line(rc + Vector2(-3, 1), rc + Vector2(3, -1), Color(rune, ra), 0.8)
	for rx: float in [-12.0, -9.0, 10.0]:
		pd.draw_line(Vector2(rx, -31), Vector2(rx, -25), Color(rune, 0.5 * ra), 0.8)
		pd.draw_line(Vector2(rx - 1.5, -28), Vector2(rx + 1.5, -28), Color(rune, 0.5 * ra), 0.8)
	# 2줄째부터: 금 간 틈에서 주황 빛
	if crack_a > 0.0:
		for seg: Array in [[Vector2(-14, -46), Vector2(-9, -40), Vector2(-11, -32), Vector2(-6, -25)], [Vector2(12, -48), Vector2(8, -41), Vector2(13, -33)], [Vector2(2, -30), Vector2(-2, -24), Vector2(1, -20)]]:
			for i in range(1, seg.size()):
				pd.draw_line(seg[i - 1], seg[i], Color(hot, crack_a), 1.4)
				pd.draw_line(seg[i - 1], seg[i], Color(EMBER_PALE, crack_a * 0.7), 0.5)
	# 3줄째: 녹은 심장 (가슴 룬 자리가 열림)
	if phase >= 2:
		pd.glow(rc, 14.0 + 4.0 * beat, Color(EMBER, 0.5), 0.0)
		pd.draw_circle(rc, 4.0 + 0.6 * beat, hot)
		pd.draw_circle(rc, 2.2, EMBER_PALE)
	# 어깨 돌판 (3줄째엔 떨어져 없음)
	if phase < 2:
		for sgn: float in [-1.0, 1.0]:
			var sx := sgn * 15.0
			pd.outlined(PackedVector2Array([Vector2(sx - 7 * sgn, -56), Vector2(sx + 7 * sgn, -53), Vector2(sx + 8 * sgn, -44), Vector2(sx - 6 * sgn, -46)]), st_hi if sgn < 0 else st, OUT, 0.9)
			pd.draw_line(Vector2(sx - 5 * sgn, -54), Vector2(sx + 6 * sgn, -51.5), Color(rune, 0.6 * ra), 0.8)
	# 머리 (작은 돌, 외눈)
	var h := Vector2(-1, -58)
	pd.outlined(PackedVector2Array([h + Vector2(-6, -5), h + Vector2(5, -6), h + Vector2(7, 1), h + Vector2(4, 6), h + Vector2(-5, 6), h + Vector2(-7, 0)]), st, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-6, -5), h + Vector2(-1, -5.5), h + Vector2(-2, 5.8), h + Vector2(-5, 6), h + Vector2(-7, 0)]), st_hi)
	var ec := h + Vector2(-2.5, -0.5)
	var eye_col := Color("#ffe08a") if phase == 0 else Color("#ff8a3a")
	pd.glow(ec, 6.0 + 2.0 * beat, Color(eye_col, 0.55), 0.0)
	pd.draw_circle(ec, 2.0, OUT)
	pd.draw_circle(ec, 1.4, eye_col)
	pd.draw_circle(ec + Vector2(-0.3, -0.3), 0.5, Color(1, 1, 1, 0.9))
	# 앞 팔 + 큰 주먹 (공격 땐 머리 위로)
	var sh := Vector2(-15, -48)
	var fist := Vector2(-22, -16).lerp(Vector2(-20, -66), atk)
	var el := sh.lerp(fist, 0.5) + Vector2(-4, 0)
	pd.line2(sh, el, OUT, OUT, 9.0, 8.0)
	pd.line2(sh, el, st, st, 7.0, 6.0)
	pd.line2(el, fist, OUT, OUT, 8.0, 7.0)
	pd.line2(el, fist, st, st, 6.0, 5.0)
	pd.draw_line(el + Vector2(-2.4, -1), el + Vector2(2.4, 1), st_dk, 1.2)
	var fp := PackedVector2Array([fist + Vector2(-7, -6), fist + Vector2(6, -7), fist + Vector2(8, 4), fist + Vector2(4, 8), fist + Vector2(-6, 7), fist + Vector2(-9, 0)])
	pd.outlined(fp, st_hi, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([fist + Vector2(2, -7), fist + Vector2(6, -7), fist + Vector2(8, 4), fist + Vector2(4, 8), fist + Vector2(1, 7)]), st)
	for i in 3: # 손가락 마디
		pd.draw_line(fist + Vector2(-7 + 3.0 * float(i), -5.5), fist + Vector2(-7 + 3.0 * float(i), 1), st_dk, 0.9)
	pd.draw_line(fist + Vector2(-4, 3), fist + Vector2(3, 2), Color(rune, 0.7 * ra), 0.8)
	if atk > 0.0:
		pd.glow(fist, 12.0, Color(rune, 0.4), 0.0)
	if phase >= 2:
		_float_rocks(false)
	if _phase_flash > 0.0:
		pd.glow(Vector2(0, -34), 50.0 * _phase_flash, Color(EMBER, 0.45 * _phase_flash), 0.0)


## 시련의 거상 3줄째: 몸 둘레를 떠도는 돌 조각
func _float_rocks(back: bool) -> void:
	for i in 6:
		var an := TAU * float(i) / 6.0 + _t * 0.9
		var behind := sin(an) < 0.0
		if behind != back:
			continue
		var p := Vector2(cos(an) * 26.0, -34.0 + sin(an) * 5.0 + sin(_t * 2.0 + float(i)) * 3.0)
		var r := 2.4 + 1.2 * EVfx.hash01(i * 3)
		pd.outlined(PackedVector2Array([p + Vector2(-r, -r * 0.6), p + Vector2(r * 0.4, -r), p + Vector2(r, r * 0.2), p + Vector2(-r * 0.2, r)]), Color("#6a6672"), OUT, 0.6)
		pd.draw_rect(Rect2(p + Vector2(-r * 0.6, -r * 0.5), Vector2(1.2, 0.8)), Color("#5f7a4a", 0.9)) # 이끼 점 (고대 돌)
		pd.glow(p, 3.0, Color("#ffd27a", 0.3 + 0.2 * sin(_t * 4.0 + float(i))), 0.0) # 룬 빛
		pd.draw_rect(Rect2(p + Vector2(-0.5, -0.5), Vector2(1, 1)), Color("#ffe08a", 0.9))
