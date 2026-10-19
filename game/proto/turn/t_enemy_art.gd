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
const RIM_OFFS: Array[Vector2] = [Vector2(0.7, 0.8), Vector2(-0.6, -0.6)] ## 검토 O §2: 오른쪽 아래 = 어두운 외곽선 · 왼쪽 위(달 쪽) = 테 빛 (그리기 명령 2개 그대로)
const RIM_COLS: Array[Color] = [Color(0.04, 0.035, 0.055, 0.95), Color(0.93, 0.9, 1.0, 0.6)]
const OWN_ART := ["ash_king", "trial_colossus"] ## 데이터의 art 대신 id로 그리는 전용 그림
## 그림 크기 (원점 = 발밑, 그림 단위 — TActor가 데이터 size × 1.8배): kind → [키, 반폭]
## 키 = 진하게 그린 꼭대기 (R4: 짚 골렘 50 → 60 = 검토 O 자루 머리의 묶은 귀 · 재의 기사 60 → 69 = 투구 꼭대기, 연기 깃은 뺌 ·
## 서리 기사 62 → 72 = 얼음 왕관 · 빈 갑주 64 → 72 = 투구 깃 —
## 머리 위 의도 아이콘·게이지가 귀·투구에 얹혔다. 키 큰 적을 내려 세우는 TStage._add_actor가 이 값을 씀)
const DIMS := {"straw_golem": [60.0, 13.0], "swamp_toad": [30.0, 26.0], "ash_knight": [69.0, 16.0], "ash_king": [60.0, 19.0], "trial_colossus": [62.0, 22.0],
	"will_o": [40.0, 12.0], "hearth_turtle": [32.0, 26.0], "flame_priest": [60.0, 15.0], "mist_jelly": [44.0, 14.0], "frost_knight": [72.0, 20.0],
	"thunder_crow": [36.0, 14.0], "volt_golem": [58.0, 20.0], "ash_servant": [42.0, 12.0], "lantern_keeper": [62.0, 15.0], "shade_scribe": [46.0, 14.0],
	"hollow_armor": [72.0, 16.0], "prism_doll": [66.0, 18.0], "ash_brood": [44.0, 30.0]}

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
var guarding := false ## 방어 태세 중 (단계 F-2 — TActor가 넣음)
var covering := false ## 막아서기 중
var charge_k := 0.0 ## 차지 0~1 (뇌석 골렘 금 · 잿빛 시종 불씨)
var guard_link := false ## 등불 가림이 켜짐 (다른 적이 살아 있음)


## 유닛 id·데이터 art → 그릴 그림 (전용 그림이 있으면 id)
static func kind_for(id: String, art: String) -> String:
	return id if id in OWN_ART else art


func _ready() -> void:
	_rng.seed = hash(kind)
	_rim_ci = TWitchArt.rim_make(self, RIM_LIGHT, false)
	material = TWitchArt.shade_mat(height(), half_w(), 0.18, 0.30, 0.14, 1.0) # 위 빛 · 아래 그림자 · 달 반대(오른쪽) 그늘 — 마녀와 같은 셰이더


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rim_ci.is_valid():
		RenderingServer.free_rid(_rim_ci)


func _draw() -> void:
	_paint()
	TWitchArt.rim_paint_cols(_rim_ci, pd, RIM_OFFS if fade >= 0.99 else [], RIM_COLS) # 옅어지는 중엔 테두리 빛이 비쳐 흰 실루엣이 되므로 끔
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
	return float(DIMS.get(kind, [40.0, 12.0])[0])


func half_w() -> float:
	return float(DIMS.get(kind, [40.0, 12.0])[1])


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
		_bits_t = 0.35 if kind in ["ash_knight", "ash_king", "will_o", "ash_brood", "prism_doll"] else (0.5 if kind in ["trial_colossus", "thunder_crow", "volt_golem", "mist_jelly", "shade_scribe", "lantern_keeper", "hearth_turtle"] else 0.9)
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
	# ── 단계 F-2
	elif kind in ["will_o", "ash_brood", "ash_servant"]:
		var p := to_global(Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-30.0, -10.0)))
		pp.spawn(p, Vector2(_rng.randf_range(-8.0, 8.0), -_rng.randf_range(20.0, 40.0)), Vector2.ZERO, 0.8, 1.3, EMBER_PALE, Color(EMBER, 0.0), 0, 0.5)
	elif kind in ["thunder_crow", "volt_golem"]:
		var p := to_global(Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-height(), -10.0)))
		pp.spawn(p, Vector2.from_angle(_rng.randf() * TAU) * 40.0, Vector2.ZERO, 0.25, 1.2, Color("#fffbe0"), Color("#ffe34a", 0.0), 0, 2.0)
	elif kind == "mist_jelly":
		var p := to_global(Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-20.0, -8.0)))
		PParticles.get_layer(false).spawn(p, Vector2(_rng.randf_range(-4.0, 4.0), 12.0), Vector2(0, 30), 0.9, 1.4, Color("#bfeaff", 0.8), Color("#8fd8ff", 0.0), 0, 0.5)
	elif kind == "shade_scribe":
		var p := to_global(Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-30.0, -10.0)))
		PParticles.get_layer(false).spawn(p, Vector2(_rng.randf_range(-6.0, 6.0), -14.0), Vector2.ZERO, 1.0, 2.0, Color("#5a4a78", 0.7), Color("#2a2040", 0.0), 0, 0.5)
	elif kind == "lantern_keeper":
		var p := to_global(Vector2(_rng.randf_range(-24.0, -10.0), _rng.randf_range(-56.0, -40.0)))
		pp.spawn(p, Vector2(_rng.randf_range(-6.0, 6.0), -10.0), Vector2.ZERO, 1.0, 1.2, Color("#ffe8b0"), Color("#ffcf7a", 0.0), 0, 0.5)
	elif kind == "hearth_turtle" and not guarding:
		PParticles.get_layer(false).spawn(to_global(Vector2(8.5, -34.0)), Vector2(_rng.randf_range(4.0, 12.0), -_rng.randf_range(16.0, 26.0)), Vector2(6, -6), 1.2, _rng.randf_range(2.0, 3.0), Color("#6a5a5a", 0.6), Color("#3a3030", 0.0), 0, 0.5)
	elif kind == "prism_doll":
		var p := to_global(Vector2(_rng.randf_range(-16.0, 16.0), _rng.randf_range(-60.0, -16.0)))
		var el: String = ["water", "bolt", "fire"][clampi(phase, 0, 2)]
		pp.spawn(p, Vector2(0, -_rng.randf_range(10.0, 24.0)), Vector2.ZERO, 0.8, 1.2, Color.WHITE, Color(TData.ELEMENT_COLOR.get(el, Color.WHITE), 0.0), 0, 0.5)


func _paint() -> void:
	if not _ready_done:
		return
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
	pd.glow(Vector2.ZERO, half_w() * 0.9, Color(0, 0, 0, 0.5), 0.0)
	pd.glow(Vector2(0, 1.0), half_w() * 0.55, Color(0, 0, 0, 0.6), 0.0) # 접지 그림자 (발이 땅에 붙게 — 검토 O §2)
	pd.draw_set_transform(Vector2.ZERO)
	match kind:
		"straw_golem": _paint_golem()
		"swamp_toad": _paint_toad()
		"ash_knight": _paint_knight()
		"ash_king": _paint_king()
		"trial_colossus": _paint_colossus()
		"will_o": _paint_will_o()
		"hearth_turtle": _paint_turtle()
		"flame_priest": _paint_priest()
		"mist_jelly": _paint_jelly()
		"frost_knight": _paint_frost_knight()
		"thunder_crow": _paint_crow()
		"volt_golem": _paint_volt()
		"ash_servant": _paint_servant()
		"lantern_keeper": _paint_lantern()
		"shade_scribe": _paint_scribe()
		"hollow_armor": _paint_hollow()
		"prism_doll": _paint_doll()
		"ash_brood": _paint_brood()


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
	# 명암 3단 (검토 O §2): 왼쪽 위 빛 · 오른쪽(달 반대) 그늘 — 결 위에 옅게 덮음
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-11 + sway, -40), Vector2(-5 + sway, -40), Vector2(-6.5, -13), Vector2(-10, -13), Vector2(-12.5, -24)]), Color("#f2dc9a", 0.22))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(5 + sway, -40), Vector2(11 + sway, -40), Vector2(12.5, -24), Vector2(10, -13), Vector2(4, -13)]), Color("#6b4a1e", 0.38))
	for y: float in [-33.0, -20.0]:
		pd.draw_line(Vector2(-12.6 + sway * 0.5, y), Vector2(12.6 + sway * 0.5, y + 0.8), Color("#6b3f1f"), 2.2)
		pd.draw_line(Vector2(-12.0 + sway * 0.5, y - 0.6), Vector2(12.0 + sway * 0.5, y + 0.2), Color("#9a6a3a"), 0.6)
	pd.draw_rect(Rect2(Vector2(-13.5, -34.5), Vector2(2.4, 3.0)), Color("#6b3f1f")) # 매듭
	for y: float in [-31.0, -18.0]: # 밧줄 아래 그림자 (짚이 조여 패인 결)
		pd.draw_line(Vector2(-12.0 + sway * 0.5, y + 0.4), Vector2(12.0 + sway * 0.5, y + 1.2), Color("#7a5a2a", 0.6), 1.2)
	# 몸통 가장자리로 삐친 짚 끝 (review_K K-20: 상자 몸 → 짚단 실루엣)
	for i in 7:
		var side := -1.0 if i % 2 == 0 else 1.0
		var y := -38.0 + float(i) * 3.6
		var x0 := side * (11.5 + (1.0 if y > -30.0 and y < -18.0 else 0.0)) + sway * 0.5
		pd.draw_line(Vector2(x0, y), Vector2(x0 + side * (2.5 + float(i % 3)), y - 1.5 + float(i % 2) * 2.5), Color("#d8bc72"), 0.8)
	for i in 5: # 어깨 위 짚 끝
		pd.draw_line(Vector2(-8.0 + float(i) * 4.0 + sway, -40), Vector2(-9.0 + float(i) * 4.5 + sway, -42.5 - float(i % 2)), Color("#d8bc72"), 0.8)
	# 팔 (앞팔은 공격 때 들린다)
	var arm_back := PackedVector2Array([Vector2(8, -37), Vector2(13, -36), Vector2(16, -18), Vector2(11, -17)])
	_straw(arm_back, Color("#b08c48"), 3, 21)
	var lift := atk * 14.0
	var arm := PackedVector2Array([Vector2(-9, -37), Vector2(-14, -36 - lift * 0.3), Vector2(-20 - lift * 0.6, -18 - lift), Vector2(-14, -16 - lift)])
	_straw(arm, Color("#c9a85c"), 3, 22)
	for i in 4: # 팔 끝 풀린 짚
		var e := Vector2(-18 - lift * 0.6 + float(i) * 1.6, -16.5 - lift)
		pd.draw_line(e, e + Vector2(-1.5 + float(i) * 0.8, 3.0), Color("#8a6a2e"), 0.8)
	# 머리: 자루 (목 밧줄) — 아래가 불룩한 천 자루 + 위로 묶어 올린 두 귀 (검토 O §2: 상자 머리 → 자루)
	var hc := Vector2(sway * 1.4, -48)
	var head := PackedVector2Array([hc + Vector2(-6.5, -8), hc + Vector2(-3.5, -10.5), hc + Vector2(0, -8.8), hc + Vector2(3.5, -10.5), hc + Vector2(7, -7.5),
		hc + Vector2(8.4, -1.5), hc + Vector2(7.8, 4.2), hc + Vector2(5, 6.8), hc + Vector2(-5, 6.8), hc + Vector2(-7.8, 4.2), hc + Vector2(-8.6, -1.5)])
	pd.outlined(head, Color("#a6894a"), OUT, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(3.0, -9.6), hc + Vector2(7, -7.5), hc + Vector2(8.4, -1.5), hc + Vector2(7.8, 4.2), hc + Vector2(5, 6.8), hc + Vector2(2.4, 6.8), hc + Vector2(4.2, -0.5)]), Color("#7c6232")) # 그늘
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(-6.5, -8), hc + Vector2(-3.5, -10.5), hc + Vector2(-2.2, -6.5), hc + Vector2(-4.5, -1.5), hc + Vector2(-8.6, -1.5)]), Color("#c4a762")) # 빛
	for j in 4: # 성긴 천 결 (가로 점선)
		for i in 5:
			pd.draw_rect(Rect2(hc + Vector2(-6.5 + float(i) * 3.0 + float(j % 2) * 1.5, -6.0 + float(j) * 3.4), Vector2(1.0, 0.6)), Color("#6b4f22", 0.45))
	pd.draw_line(hc + Vector2(-5.5, -7), hc + Vector2(-2, 5), Color("#8a6a2e"), 0.6) # 솔기 + 바늘땀
	for k in 4:
		var q := hc + Vector2(-5.5, -7).lerp(Vector2(-2, 5), (float(k) + 0.5) / 4.0)
		pd.draw_line(q + Vector2(-1.2, -0.3), q + Vector2(1.2, 0.3), Color("#e8d8a8", 0.8), 0.6)
	pd.draw_line(hc + Vector2(-7.4, 6.5), hc + Vector2(7.4, 7), Color("#6b3f1f"), 2.0) # 목 밧줄
	pd.draw_line(hc + Vector2(-7.0, 5.9), hc + Vector2(7.0, 6.4), Color("#9a6a3a"), 0.6)
	for k in 3: # 묶은 두 귀 끝 (풀린 짚)
		pd.draw_line(hc + Vector2(-3.5, -10.5), hc + Vector2(-5.0 + float(k) * 1.5, -14.0 + absf(float(k) - 1.0)), Color("#8a6a2e"), 0.9)
		pd.draw_line(hc + Vector2(3.5, -10.5), hc + Vector2(2.5 + float(k) * 1.6, -13.5 + absf(float(k) - 1.0)), Color("#8a6a2e"), 0.9)
	# 눈구멍 둘 (어둡고 깊음, 안에서 아주 옅은 불씨)
	for ex: float in [-4.0, 2.0]:
		var e := hc + Vector2(ex, -2)
		pd.draw_colored_polygon(PackedVector2Array([e + Vector2(-2, -1.5), e + Vector2(2.4, -2), e + Vector2(2, 1.5), e + Vector2(-2.2, 1.2)]), OUT)
		pd.glow(e + Vector2(0.1, 0.1), 2.6, Color(EMBER, 0.25 + 0.15 * sin(_t * 3.0 + ex)), 0.0)
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
	# 명암 (검토 O §2): 아래 가장자리 그늘 띠 · 등 위 달빛 테 — 원 덩어리가 둥근 몸으로 읽히게
	var ry0 := 14.0 + atk * 2.0
	var lo_o := PackedVector2Array()
	var lo_i := PackedVector2Array()
	for i in 13:
		var a := lerpf(0.15, PI - 0.15, float(i) / 12.0)
		var rx := 24.0 + 1.5 * sin(a * 3.0)
		lo_o.append(Vector2(cos(a) * (rx - 0.6), -14.0 + sin(a) * ry0 * 1.15 - 0.6))
		lo_i.append(Vector2(cos(a) * (rx - 4.0), -14.0 + sin(a) * ry0 * 0.62))
	pd.strip(lo_o, lo_i, Color("#2e3c18", 0.55))
	var top_l := PackedVector2Array()
	for i in 9:
		var a := lerpf(PI * 1.08, PI * 1.62, float(i) / 8.0)
		var rx := 24.0 + 1.5 * sin(a * 3.0)
		top_l.append(Vector2(cos(a) * (rx - 1.4), -14.0 + sin(a) * (ry0 - 1.4)))
	pd.draw_polyline(top_l, Color("#c8dc8a", 0.7), 1.0)
	# 등의 검은 점·사마귀 (크기 3단)
	for spec: Array in [[-10, -22, 3.0], [-2, -25, 2.4], [8, -22, 3.2], [14, -17, 2.0], [-16, -16, 2.0], [3, -19, 1.6], [-6, -18, 1.0], [11, -26, 1.1], [18, -22, 0.9], [-13, -21, 0.9]]:
		var c := Vector2(spec[0], spec[1])
		pd.draw_circle(c, float(spec[2]) + 0.5, Color("#3a4c1e"))
		pd.draw_circle(c, float(spec[2]), Color("#4b6128"))
		pd.draw_circle(c + Vector2(-0.6, -0.6), float(spec[2]) * 0.45, Color("#88a34a"))
	for g: Vector2 in [Vector2(-4, -26.5), Vector2(6, -25), Vector2(-12, -23.5)]: # 젖은 살갗 반짝
		pd.draw_rect(Rect2(g, Vector2(1.2, 0.8)), Color(1, 1, 0.9, 0.7))
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
		pd.draw_line(Vector2(x + 2.0, -21), Vector2(x + 1.8, -3), plate_dk, 1.4) # 정강이 그늘
		pd.outlined(PackedVector2Array([Vector2(x - 4.2, -2.5), Vector2(x + 4.6, -2.5), Vector2(x + 5.4, 0.5), Vector2(x - 4.4, 0.5)]), plate_dk, OUT, 0.8) # 발
		pd.draw_line(Vector2(x - 3.2, -12), Vector2(x + 3.2, -12), plate_dk, 1.2) # 무릎 이음
	# 허리·몸통 (가슴판에 균열)
	var torso := PackedVector2Array([Vector2(-10, -48), Vector2(10, -48), Vector2(11.5, -36), Vector2(8, -22), Vector2(-8, -22), Vector2(-11.5, -36)])
	pd.outlined(torso, plate, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-10, -48), Vector2(-2, -48), Vector2(-3, -24), Vector2(-8, -22), Vector2(-11.5, -36)]), plate_hi)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(5, -48), Vector2(10, -48), Vector2(11.5, -36), Vector2(8, -22), Vector2(4, -22)]), Color(plate_dk, 0.75)) # 오른쪽 그늘 (검토 O §2: 판 3단)
	pd.draw_line(Vector2(-9, -34), Vector2(9, -34), plate_dk, 1.4)
	pd.draw_line(Vector2(-8, -26), Vector2(8, -26), plate_dk, 1.0)
	pd.draw_line(Vector2(-9, -33.0), Vector2(5, -33.0), Color("#a8a1b4", 0.7), 0.6) # 판 경계 아래 1px 밝은 선 (윗판이 겹쳐 보이게)
	pd.draw_line(Vector2(-8, -25.0), Vector2(4, -25.0), Color("#a8a1b4", 0.6), 0.6)
	pd.draw_line(Vector2(-9.6, -47.4), Vector2(4, -47.4), Color("#b8b1c4", 0.8), 0.6) # 가슴판 윗모서리
	# 균열 (불씨가 비침) — 버프 때 환해진다
	var ca := 0.55 + 0.45 * pulse + fl
	pd.glow(Vector2(-1, -38), 9.0 + 10.0 * fl, Color(EMBER, 0.25 * ca), 0.0)
	pd.glow(Vector2(-1, -36), 4.0 + 4.0 * fl, Color(EMBER_PALE, 0.3 * minf(ca, 1.0)), 0.0) # 틈에서 번지는 속불
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
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(3, -12), hc + Vector2(6.5, -7), hc + Vector2(6.5, 5), hc + Vector2(3, 8), hc + Vector2(1.5, 8)]), Color(plate_dk, 0.75)) # 투구 그늘
	pd.draw_line(hc + Vector2(-6.5, 0), hc + Vector2(6.5, 0), plate_dk, 1.0)
	pd.draw_line(hc + Vector2(-5.6, -8.2), hc + Vector2(-2, -11.4), Color("#b8b1c4", 0.8), 0.6) # 투구 윗모서리 빛
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
	var sdir := Vector2(0, 1).lerp(Vector2(-0.9, -0.45).normalized(), atk).normalized() # 들어 올린 칼끝이 투구 위(적 카드)까지 오르지 않게 눕힘 (review_K K-26)
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


# ═══════════════════════════════════════════════════════════
# 단계 F-2 새 적 11 · 보스 2 (review_H §9 그림 방향) — 정령(둥근 몸 + 꼬리, 다리 없이 1.6초 주기로 떠다님) · 마름모 인형 두 체형을 새로 그리고,
# 나머지는 기존 체형(두꺼비·기사·거상)을 바탕으로 색·소품. 상태: guarding(방어 태세) · covering(막아서기) · charge_k(차지 0~1) — TActor가 넣는다
# ═══════════════════════════════════════════════════════════

## 떠다니는 높이 (정령·까마귀·해파리·서기·인형)
func _bob(amp := 2.5) -> float:
	return sin(_t * TAU / 1.6) * amp


## 불꽃 혀 하나 (base에서 위로 h, 폭 w) — 끝이 흔들림
func _flame(base: Vector2, h: float, w: float, col: Color, core: Color, ph := 0.0) -> void:
	var wob := sin(_t * 9.0 + ph) * w * 0.35
	pd.convex(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.55, -h * 0.55), base + Vector2(wob, -h), base + Vector2(w * 0.55, -h * 0.5), base + Vector2(w, 0)]), col)
	pd.convex(PackedVector2Array([base + Vector2(-w * 0.45, 0), base + Vector2(wob * 0.6, -h * 0.6), base + Vector2(w * 0.45, 0)]), core)


## 지그재그 금 (번개·뇌석) — from에서 to로 n 마디
func _zig(from: Vector2, to: Vector2, n: int, amp: float, col: Color, w: float, seed_i: int) -> void:
	var prev := from
	for i in range(1, n + 1):
		var f := float(i) / float(n)
		var p := from.lerp(to, f)
		if i < n:
			p += (to - from).orthogonal().normalized() * amp * (1.0 if (i + seed_i) % 2 == 0 else -1.0)
		pd.draw_line(prev, p, col, w)
		prev = p


## 정령 몸: 물방울(위가 가늘고 아래가 둥근) 반지름 r, 중심 c
func _drop(c: Vector2, r: float, col: Color, up := true) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		var p := Vector2(cos(a) * r, sin(a) * r)
		var top := -sin(a) if up else sin(a) # 꼬리 쪽
		if top > 0.0:
			p.x *= 1.0 - 0.75 * top
			p.y -= (r * 0.9) * top * (1.0 if up else -1.0)
		pts.append(c + p)
	pd.outlined(pts, col, OUT, 0.8)
	return pts


## 정령 눈 둘 (흰 눈, 깜빡임)
func _eyes(c: Vector2, gap: float, r: float, col := Color(1, 1, 1)) -> void:
	var open := 1.0 if _blink <= 0.0 else 0.2
	for dx: float in [-gap, gap * 0.4]:
		var e := c + Vector2(dx, 0)
		pd.draw_set_transform(e, 0.0, Vector2(1.0, open))
		pd.draw_circle(Vector2.ZERO, r + 0.6, OUT)
		pd.draw_circle(Vector2.ZERO, r, col)
		pd.draw_set_transform(Vector2.ZERO)


# ── 도깨비불: 주황 물방울 몸이 위로 타오르는 불꽃 꼬리, 흰 눈 둘, 둘레에 불씨 점 셋 (재촉 때 꼬리가 길게)
func _paint_will_o() -> void:
	var c := Vector2(0, -16 + _bob())
	var body := Color("#ff8a3a")
	var core := Color("#ffe0a0")
	var tail := 1.6 if pose == "buff" else 1.0
	pd.glow(c, 18.0, Color(EMBER, 0.35), 0.0)
	for i in 3:
		_flame(c + Vector2(-4.0 + 4.0 * float(i), -4), (12.0 + 4.0 * float(i % 2)) * tail, 3.2, Color(body, 0.9), core, float(i) * 1.7)
	_drop(c, 9.0, body)
	pd.glow(c + Vector2(-1, 1), 6.0, Color(core, 0.6), 0.0)
	_eyes(c + Vector2(-2, -1), 3.6, 1.6)
	for i in 3:
		var an := _t * 2.4 + TAU * float(i) / 3.0
		var p := c + Vector2(cos(an) * 15.0, sin(an) * 5.0 + 2.0)
		pd.glow(p, 3.0, Color(EMBER, 0.6), 0.0)
		pd.draw_circle(p, 1.1, EMBER_PALE)


# ── 화로 거북: 납작 몸 + 반원 등딱지(어두운 적갈, 틈마다 주황 빛 셋) + 등 굴뚝 연기 · 방어 태세 때 머리를 넣고 틈 빛이 꺼짐
func _paint_turtle() -> void:
	var sh := Color("#a8442a")
	var sh_dk := Color("#6a2a1c")
	var skin := Color("#7a5a3a")
	var hot := Color(EMBER, 0.25 if guarding else 0.85 + 0.15 * sin(_t * 3.0))
	# 다리 넷
	for x: float in [-17.0, -7.0, 8.0, 18.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 3, -6), Vector2(x + 3, -6), Vector2(x + 3.5, 0), Vector2(x - 3.5, 0)]), skin, OUT, 0.7)
	# 머리 (방어 태세면 껍질 안으로)
	var hx := -27.0 + (8.0 if guarding else 0.0) - (4.0 if pose == "attack" else 0.0)
	pd.outlined(PackedVector2Array([Vector2(hx - 6, -12), Vector2(hx + 4, -15), Vector2(hx + 8, -9), Vector2(hx + 3, -5), Vector2(hx - 6, -6)]), skin, OUT, 0.8)
	if not guarding:
		pd.draw_circle(Vector2(hx - 2, -11), 1.4, OUT)
		pd.draw_rect(Rect2(Vector2(hx - 2.4, -11.6), Vector2(1, 1)), Color(EMBER_PALE, 0.9))
	# 등딱지 (반원, 육각 판)
	var shell := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		shell.append(Vector2(cos(a) * 24.0, -7.0 + sin(a) * 19.0))
	pd.outlined(shell, sh, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-24, -7), Vector2(-20, -18), Vector2(-10, -24), Vector2(-6, -7)]), Color(sh.lightened(0.15), 0.9))
	pd.draw_line(Vector2(-24, -7), Vector2(24, -7), sh_dk, 2.0)
	# 틈 빛 셋 (판 사이)
	for seg: Array in [[Vector2(-14, -8), Vector2(-12, -18), Vector2(-4, -23)], [Vector2(0, -8), Vector2(2, -18), Vector2(10, -22)], [Vector2(13, -8), Vector2(16, -15)]]:
		for i in range(1, seg.size()):
			pd.draw_line(seg[i - 1], seg[i], Color(EMBER, hot.a * 0.4), 3.0)
			pd.draw_line(seg[i - 1], seg[i], hot, 1.2)
	# 굴뚝
	pd.outlined(PackedVector2Array([Vector2(6, -24), Vector2(11, -24), Vector2(12, -32), Vector2(5, -32)]), sh_dk, OUT, 0.8)
	pd.draw_rect(Rect2(Vector2(5.5, -33), Vector2(7, 2)), Color("#3a1e18"))
	if not guarding:
		pd.glow(Vector2(8.5, -32), 4.0, Color(EMBER, 0.5), 0.0)


# ── 불꽃 사제: 사다리꼴 붉은 옷(아래가 넓게) + 두건 아래 눈 빛 둘 + 긴 지팡이 끝 불꽃
func _paint_priest() -> void:
	var robe := Color("#c0402a")
	var robe_dk := Color("#7a2418")
	var trim := Color("#ffb04a")
	var atk := 1.0 if pose == "attack" else 0.0
	var robe_pts := PackedVector2Array([Vector2(-7, -44), Vector2(7, -44), Vector2(13, -2), Vector2(9, 0), Vector2(-9, 0), Vector2(-14, -2)])
	pd.outlined(robe_pts, robe, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(2, -44), Vector2(7, -44), Vector2(13, -2), Vector2(9, 0), Vector2(4, 0)]), robe_dk)
	pd.draw_line(Vector2(-14, -2), Vector2(13, -2), trim, 1.2)
	pd.draw_line(Vector2(-1, -40), Vector2(-2, -2), Color(trim, 0.8), 1.0)
	# 두건
	var h := Vector2(-1, -50)
	pd.outlined(PackedVector2Array([h + Vector2(-7, 6), h + Vector2(-6, -4), h + Vector2(0, -10), h + Vector2(6, -4), h + Vector2(8, 6)]), robe_dk, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-5, 5), h + Vector2(-4, -2), h + Vector2(4, -2), h + Vector2(5, 5)]), Color("#1a0a0a"))
	for ex: float in [-3.0, 1.0]:
		pd.glow(h + Vector2(ex, 1), 2.6, Color(EMBER, 0.7), 0.0)
		pd.draw_rect(Rect2(h + Vector2(ex - 0.7, 0.4), Vector2(1.4, 1.2)), EMBER_PALE)
	# 지팡이 (앞 손)
	var hand := Vector2(-11, -28).lerp(Vector2(-14, -40), atk)
	pd.draw_line(Vector2(-6, -38), hand, robe, 3.0)
	var top := hand + Vector2(-2, -24)
	var bot := hand + Vector2(2, 26)
	pd.line2(bot, top, Color("#4a2a1a"), Color("#6a4028"), 2.2, 1.6)
	pd.glow(top, 10.0 + 4.0 * flare, Color(EMBER, 0.5), 0.0)
	_flame(top + Vector2(0, 2), 12.0 + 4.0 * atk, 4.0, Color("#ff7a2a"), Color("#ffe0a0"), 0.0)
	pd.draw_circle(hand, 2.2, Color("#d8b8a0"))


# ── 물안개 해파리: 하늘색 반원 갓 + 아래로 흔들리는 촉수 다섯, 갓 안 흰 점 (약화 때 몸이 옅게 퍼짐)
func _paint_jelly() -> void:
	var c := Vector2(0, -30 + _bob(3.0))
	var col := Color("#8fd8ff")
	var spread := 1.25 if pose == "buff" else 1.0
	for i in 5:
		var x0 := -9.0 + 4.5 * float(i)
		var pts := PackedVector2Array()
		for k in 8:
			var f := float(k) / 7.0
			pts.append(c + Vector2(x0 * (1.0 + 0.2 * f) + sin(_t * 3.0 + float(i) + f * 4.0) * 2.5 * f, 4.0 + f * 24.0))
		pd.draw_polyline(pts, Color(col.darkened(0.2), 0.85), 1.4 - 0.2 * float(i % 2))
	var dome := PackedVector2Array()
	for i in 15:
		var a := PI + PI * float(i) / 14.0
		dome.append(c + Vector2(cos(a) * 13.0 * spread, sin(a) * 11.0 + 4.0))
	pd.glow(c, 20.0 * spread, Color(col, 0.25), 0.0)
	pd.outlined(dome, Color(col, 0.8), OUT, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 4), c + Vector2(-9, -4), c + Vector2(-3, -6), c + Vector2(-4, 4)]), Color(1, 1, 1, 0.3))
	pd.draw_line(c + Vector2(-13 * spread, 4), c + Vector2(13 * spread, 4), Color(col.darkened(0.3), 0.9), 1.4)
	for p: Vector2 in [Vector2(-5, -1), Vector2(2, -3), Vector2(6, 1), Vector2(-1, 2)]:
		pd.draw_circle(c + p, 1.0, Color(1, 1, 1, 0.85))
	_eyes(c + Vector2(-3, 0.5), 3.0, 1.1, Color("#14304a"))


# ── 서리 기사: 회청 갑옷 + 어깨 위 얼음 가시 셋 + 큰 사다리꼴 방패 (막아서기 때 방패를 앞으로, 빛)
func _paint_frost_knight() -> void:
	var plate := Color("#5a86b8")
	var plate_hi := Color("#8ab0d8")
	var plate_dk := Color("#34506e")
	var ice := Color("#d8f4ff")
	for x: float in [-5.0, 5.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 3.6, -24), Vector2(x + 3.6, -24), Vector2(x + 3.2, -2), Vector2(x - 3.2, -2)]), plate, OUT, 0.8)
		pd.outlined(PackedVector2Array([Vector2(x - 4.4, -2.5), Vector2(x + 4.8, -2.5), Vector2(x + 5.4, 0.6), Vector2(x - 4.6, 0.6)]), plate_dk, OUT, 0.8)
	var torso := PackedVector2Array([Vector2(-11, -50), Vector2(11, -50), Vector2(12.5, -38), Vector2(9, -24), Vector2(-9, -24), Vector2(-12.5, -38)])
	pd.outlined(torso, plate, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-11, -50), Vector2(-2, -50), Vector2(-3, -25), Vector2(-9, -24), Vector2(-12.5, -38)]), plate_hi)
	pd.draw_line(Vector2(-10, -36), Vector2(10, -36), plate_dk, 1.4)
	# 어깨 + 얼음 가시
	for sgn: float in [-1.0, 1.0]:
		var sx := sgn * 12.0
		pd.outlined(PackedVector2Array([Vector2(sx - 6 * sgn, -52), Vector2(sx + 6 * sgn, -49), Vector2(sx + 4 * sgn, -42), Vector2(sx - 4 * sgn, -44)]), plate_hi if sgn < 0 else plate, OUT, 0.8)
		for k in 3:
			var b := Vector2(sx + sgn * (float(k) * 3.0 - 2.0), -51.0 + float(k) * 0.8)
			pd.outlined(PackedVector2Array([b + Vector2(-1.4, 0), b + Vector2(sgn * 1.5, -6.0 - float(k % 2) * 3.0), b + Vector2(1.4, 0)]), ice, OUT, 0.5)
	# 투구 (가로 눈구멍, 하늘빛)
	var h := Vector2(0, -58)
	pd.outlined(PackedVector2Array([h + Vector2(-6.5, -7), h + Vector2(6.5, -7), h + Vector2(7, 5), h + Vector2(3, 8), h + Vector2(-5, 8), h + Vector2(-7.5, 1)]), plate, OUT, 0.9)
	pd.draw_line(h + Vector2(-7, -1), h + Vector2(0, -0.5), Color("#bff0ff"), 1.5)
	pd.glow(h + Vector2(-3, -1), 4.0, Color("#8fd8ff", 0.5), 0.0)
	pd.outlined(PackedVector2Array([h + Vector2(-2, -7), h + Vector2(0, -14), h + Vector2(2, -7)]), ice, OUT, 0.5)
	# 큰 방패 (앞, 막아서기 때 더 앞으로 + 빛)
	var fx := -18.0 - (6.0 if covering else 0.0)
	var shp := PackedVector2Array([Vector2(fx - 7, -46), Vector2(fx + 7, -46), Vector2(fx + 8, -20), Vector2(fx, -10), Vector2(fx - 8, -20)])
	if covering:
		pd.glow(Vector2(fx, -30), 22.0, Color("#c8d070", 0.3 + 0.1 * sin(_t * 5.0)), 0.0)
	pd.outlined(shp, plate_dk, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(fx - 5.5, -44), Vector2(fx + 5.5, -44), Vector2(fx + 6, -21), Vector2(fx, -13), Vector2(fx - 6, -21)]), plate)
	pd.draw_line(Vector2(fx, -43), Vector2(fx, -14), ice, 1.2)
	pd.draw_line(Vector2(fx - 5, -32), Vector2(fx + 5, -32), ice, 1.0)


# ── 번개 까마귀: 노란 작은 몸 + 퍼덕이는 삼각 날개 둘 + 부리 + 꼬리 끝 지그재그 번개 · 몸 둘레 깜빡이는 전기 선
func _paint_crow() -> void:
	var c := Vector2(0, -22 + _bob(3.0))
	var col := Color("#ffe34a")
	var dk := Color("#b89a1a")
	var flap := sin(_t * 14.0) * (1.0 if pose != "idle" else 0.7)
	# 뒤 날개
	pd.outlined(PackedVector2Array([c + Vector2(2, -2), c + Vector2(12, -10 - 8.0 * flap), c + Vector2(16, -2 - 4.0 * flap), c + Vector2(6, 2)]), dk, OUT, 0.7)
	# 꼬리 (오른쪽 뒤) + 번개
	pd.outlined(PackedVector2Array([c + Vector2(6, 0), c + Vector2(15, 3), c + Vector2(14, 6), c + Vector2(5, 4)]), dk, OUT, 0.7)
	_zig(c + Vector2(15, 4), c + Vector2(23, 10), 4, 1.6, Color("#fff6b0"), 1.2, int(_t * 8.0))
	# 몸
	var body := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		body.append(c + Vector2(cos(a) * 8.0, sin(a) * 6.0))
	pd.glow(c, 14.0, Color(col, 0.25), 0.0)
	pd.outlined(body, col, OUT, 0.8)
	# R4 (검토 O 언어 한 단계 더): 배 아래 그늘 반달 · 등 윗모서리 빛 — 납작한 노란 원이 둥근 몸으로
	var belly := PackedVector2Array()
	for i in 9:
		var a := PI * 0.08 + PI * 0.84 * float(i) / 8.0
		belly.append(c + Vector2(cos(a) * 7.4, sin(a) * 5.4))
	belly.append(c + Vector2(-6.0, 1.2))
	belly.append(c + Vector2(6.0, 1.2))
	pd.draw_colored_polygon(belly, Color(dk, 0.6))
	pd.draw_arc(c, 6.6, PI * 1.1, PI * 1.62, 6, Color("#fff6b0", 0.8), 0.8)
	# 머리 + 부리 (왼쪽)
	var h := c + Vector2(-7, -4)
	pd.draw_circle(h, 4.6, OUT)
	pd.draw_circle(h, 4.0, col)
	pd.outlined(PackedVector2Array([h + Vector2(-3, -1), h + Vector2(-9, 0.5), h + Vector2(-3, 1.6)]), Color("#ff9a3a"), OUT, 0.6)
	pd.draw_circle(h + Vector2(-1, -1.2), 1.1, OUT)
	pd.draw_rect(Rect2(h + Vector2(-1.4, -1.8), Vector2(0.7, 0.7)), Color(1, 1, 1, 0.9))
	# 앞 날개 (깃 결 두 줄)
	pd.outlined(PackedVector2Array([c + Vector2(-2, -1), c + Vector2(6, -12 - 9.0 * flap), c + Vector2(11, -3 - 5.0 * flap), c + Vector2(2, 3)]), col.darkened(0.1), OUT, 0.7)
	for fk: float in [0.4, 0.7]:
		pd.draw_line(c + Vector2(1, 1), c + Vector2(6, -12 - 9.0 * flap).lerp(c + Vector2(11, -3 - 5.0 * flap), fk), Color(dk, 0.75), 0.5)
	# 전기 선 (깜빡)
	if fmod(_t, 0.5) < 0.18:
		var a0 := _t * 7.0
		_zig(c + Vector2.from_angle(a0) * 10.0, c + Vector2.from_angle(a0 + 1.2) * 12.0, 3, 1.5, Color("#fffbe0", 0.9), 0.8, 1)


# ── 뇌석 골렘: 회갈 돌 몸(거상 축소) + 노란 금 넷 + 노란 외눈 · 방어 태세 때 팔을 X로 모으고 금이 어두워짐 · 차지마다 금이 하나씩 밝아짐
func _paint_volt() -> void:
	var st := Color("#8a8070")
	var st_hi := Color("#a89c88")
	var st_dk := Color("#5a5248")
	var bolt := Color("#ffe34a")
	var atk := 1.0 if pose == "attack" else 0.0
	# 다리
	for x: float in [-9.0, 7.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 5, -18), Vector2(x + 5, -18), Vector2(x + 5.5, -1), Vector2(x - 5.5, -1)]), st, OUT, 0.9)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x + 1.5, -18), Vector2(x + 5, -18), Vector2(x + 5.5, -1), Vector2(x + 1.5, -1)]), Color(st_dk, 0.5)) # 다리 그늘
		pd.outlined(PackedVector2Array([Vector2(x - 6.5, -2), Vector2(x + 6.5, -2), Vector2(x + 7, 0.8), Vector2(x - 7, 0.8)]), st_dk, OUT, 0.8)
	# 몸통 (큰 돌)
	var torso := PackedVector2Array([Vector2(-16, -46), Vector2(14, -48), Vector2(18, -32), Vector2(14, -17), Vector2(-14, -16), Vector2(-18, -30)])
	pd.outlined(torso, st, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-16, -46), Vector2(-4, -47), Vector2(-5, -17), Vector2(-14, -16), Vector2(-18, -30)]), st_hi)
	# R4 (검토 O 언어 한 단계 더): 오른쪽 그늘 면 · 윗모서리 빛 · 깎인 돌 자국 — 납작한 베이지 판이 돌덩이로 읽히게
	pd.draw_colored_polygon(PackedVector2Array([Vector2(5, -47.3), Vector2(14, -48), Vector2(18, -32), Vector2(14, -17), Vector2(5, -16.6)]), Color(st_dk, 0.55))
	pd.draw_line(Vector2(-15.6, -45.6), Vector2(13.6, -47.6), Color(st_hi.lightened(0.25), 0.8), 0.7)
	pd.draw_line(Vector2(-17.4, -30.5), Vector2(-15.6, -45.4), Color(st_hi.lightened(0.15), 0.6), 0.6)
	for ch: Vector2 in [Vector2(-9, -34), Vector2(9, -38), Vector2(-3, -21), Vector2(12, -24), Vector2(-12, -21)]:
		pd.draw_colored_polygon(PackedVector2Array([ch + Vector2(-1.4, -0.6), ch + Vector2(0.4, -1.2), ch + Vector2(1.4, 0.4), ch + Vector2(-0.6, 1.0)]), Color(st_dk.darkened(0.2), 0.7))
		pd.draw_line(ch + Vector2(-1.4, -0.8), ch + Vector2(0.4, -1.4), Color(st_hi, 0.6), 0.4)
	# 노란 금 넷 — 차지 k칸이 차면 k개 밝음 (방어 태세면 모두 어둡게)
	var n_lit := int(round(charge_k * 4.0))
	var cracks := [[Vector2(-12, -42), Vector2(-6, -24)], [Vector2(8, -44), Vector2(12, -24)], [Vector2(-2, -46), Vector2(2, -30)], [Vector2(-14, -26), Vector2(6, -19)]]
	for i in cracks.size():
		var lit := (i < n_lit or i == 0) and not guarding
		var cc := Color(bolt, (0.9 + 0.1 * sin(_t * 12.0 + float(i))) if lit else 0.3)
		if lit:
			_zig(cracks[i][0], cracks[i][1], 4, 1.8, Color(bolt, 0.3), 3.0, i)
		_zig(cracks[i][0], cracks[i][1], 4, 1.8, cc, 1.1, i)
	# 머리 (작은 돌 + 외눈)
	var h := Vector2(-1, -54)
	pd.outlined(PackedVector2Array([h + Vector2(-6, -5), h + Vector2(5, -6), h + Vector2(7, 1), h + Vector2(4, 6), h + Vector2(-5, 6), h + Vector2(-7, 0)]), st, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(1.5, -5.7), h + Vector2(5, -6), h + Vector2(7, 1), h + Vector2(4, 6), h + Vector2(1, 6)]), Color(st_dk, 0.55)) # 머리 그늘
	pd.draw_line(h + Vector2(-5.6, -4.8), h + Vector2(4.6, -5.7), Color(st_hi.lightened(0.25), 0.8), 0.6)
	var ec := h + Vector2(-2.5, -0.5)
	pd.glow(ec, 6.0, Color(bolt, 0.6 if not guarding else 0.25), 0.0)
	pd.draw_circle(ec, 2.0, OUT)
	pd.draw_circle(ec, 1.4, bolt)
	# 팔: 서 있을 땐 늘어뜨림 · 방어 태세 땐 가슴 앞 X · 공격 땐 앞 팔을 듦
	var sh_f := Vector2(-15, -44)
	var sh_b := Vector2(13, -44)
	var fist_f := Vector2(-20, -18).lerp(Vector2(-18, -60), atk)
	var fist_b := Vector2(18, -18)
	if guarding:
		fist_f = Vector2(10, -32)
		fist_b = Vector2(-12, -32)
	for arm: Array in [[sh_b, fist_b, st_dk], [sh_f, fist_f, st]]:
		pd.line2(arm[0], arm[1], OUT, OUT, 8.0, 7.0)
		pd.line2(arm[0], arm[1], arm[2], arm[2], 6.0, 5.0)
		pd.outlined(PackedVector2Array([arm[1] + Vector2(-5, -5), arm[1] + Vector2(5, -5), arm[1] + Vector2(6, 4), arm[1] + Vector2(-5, 5)]), st_hi if arm[2] == st else st_dk, OUT, 0.9)
	if atk > 0.0:
		pd.glow(fist_f, 12.0, Color(bolt, 0.45), 0.0)


# ── 잿빛 시종: 회색 웅크린 작은 기사(대검 없음) + 가슴 불씨 — 차지가 찰수록 불씨가 커지고 가득이면 몸이 붉게 깜빡(자폭 예고)
func _paint_servant() -> void:
	var plate := Color("#8a8090")
	var plate_dk := Color("#5a5262")
	var hot := charge_k >= 0.99
	var blink := 0.5 + 0.5 * sin(_t * 12.0)
	if hot:
		plate = plate.lerp(Color("#d04a3a"), 0.45 * blink)
	# 재 날림 꼬리 (등 뒤로 흩어지는 재 — review_K K-20: 회색 상자 하나처럼 보였다)
	for i in 3:
		var ph := float(i) * 0.9
		var pts := PackedVector2Array()
		for k in 7:
			var f := float(k) / 6.0
			pts.append(Vector2(9.0 + f * 16.0, -30.0 + f * 6.0 + sin(_t * 2.2 + ph + f * 4.0) * (1.0 + 2.5 * f) - float(i) * 3.0))
		pd.draw_polyline(pts, Color("#6a6070", 0.55 - 0.15 * float(i)), 2.4 - 0.6 * float(i))
	for i in 4: # 꼬리 끝 재 조각
		var f := fmod(_t * 0.6 + float(i) * 0.25, 1.0)
		pd.draw_rect(Rect2(Vector2(24.0 + f * 10.0, -26.0 - f * 8.0 + float(i) * 2.0), Vector2(1.2, 1.2)), Color("#9a8a9a", 0.7 * (1.0 - f)))
	for x: float in [-4.0, 4.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 3, -14), Vector2(x + 3, -14), Vector2(x + 3.4, -1), Vector2(x - 3.4, -1)]), plate_dk, OUT, 0.8)
	# 웅크린 몸 (앞으로 기울어진 둥근 등)
	var body := PackedVector2Array([Vector2(-11, -24), Vector2(-6, -36), Vector2(4, -38), Vector2(11, -30), Vector2(10, -14), Vector2(-9, -13)])
	pd.outlined(body, plate, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-6, -36), Vector2(4, -38), Vector2(6, -33), Vector2(-4, -31)]), plate.lightened(0.15))
	# 어깨 실루엣 (뾰족한 견갑 둘) + 등 테 조명 (D2 기준 — 바탕과 몸을 떼어 냄)
	for sp: Array in [[Vector2(-5, -35), Vector2(-9, -42), Vector2(-1, -37)], [Vector2(3, -37), Vector2(4, -45), Vector2(8, -35)]]:
		pd.outlined(PackedVector2Array(sp), plate_dk, OUT, 0.7)
	pd.draw_polyline(PackedVector2Array([Vector2(-6, -36.6), Vector2(4, -38.6), Vector2(11.6, -30), Vector2(10.6, -15)]), Color("#ffb08a", 0.55), 0.8)
	for k in 3: # 등의 갈라진 틈 (속불)
		var c0 := Vector2(2.0 + float(k) * 2.5, -33.0 + float(k) * 5.0)
		pd.draw_line(c0, c0 + Vector2(2.2, 2.6), Color(EMBER, 0.55 + 0.25 * sin(_t * 3.0 + float(k))), 0.9)
	# 가슴 불씨
	var ec := Vector2(-3, -24)
	var er := 2.0 + 4.0 * charge_k
	pd.glow(ec, er * 2.4, Color(EMBER, 0.45 + 0.3 * (blink if hot else 0.5)), 0.0)
	pd.draw_circle(ec, er, Color(EMBER).lerp(EMBER_PALE, 0.3))
	pd.draw_circle(ec, er * 0.45, EMBER_PALE)
	# 머리 (작은 투구, 몸 앞쪽 아래로)
	var h := Vector2(-9, -36)
	pd.outlined(PackedVector2Array([h + Vector2(-5, -4), h + Vector2(4, -6), h + Vector2(6, 2), h + Vector2(-4, 5)]), plate_dk, OUT, 0.8)
	pd.draw_line(h + Vector2(-5, -0.5), h + Vector2(0, -1), Color(EMBER, 0.9), 1.2)
	# 팔 (늘어뜨림)
	pd.draw_line(Vector2(-6, -30), Vector2(-13, -16), plate_dk, 2.6)
	pd.draw_circle(Vector2(-13, -16), 1.8, plate_dk)


# ── 등불지기: 두건 쓴 긴 옷 + 장대 끝 등불(둥근 번짐) — 졸개가 살아 있는 동안 등불 빛이 크다(가림)
func _paint_lantern() -> void:
	var robe := Color("#5a4a46")
	var robe_dk := Color("#3a2e2c")
	var lamp := Color("#ffcf7a")
	var atk := 1.0 if pose == "attack" else 0.0
	pd.outlined(PackedVector2Array([Vector2(-7, -46), Vector2(7, -46), Vector2(12, -1), Vector2(-12, -1)]), robe, OUT, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(2, -46), Vector2(7, -46), Vector2(12, -1), Vector2(5, -1)]), robe_dk)
	for k in 4: # 해진 옷자락 끝
		var x := -11.0 + 6.0 * float(k)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x, -1), Vector2(x + 3, 2.0 + sin(_t * 2.0 + float(k))), Vector2(x + 6, -1)]), robe_dk)
	# 두건 (깊은 그늘 + 눈 빛 하나)
	var h := Vector2(-1, -52)
	pd.outlined(PackedVector2Array([h + Vector2(-7, 7), h + Vector2(-6, -3), h + Vector2(1, -11), h + Vector2(7, -3), h + Vector2(8, 7)]), robe_dk, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-5, 6), h + Vector2(-3, -1), h + Vector2(4, -1), h + Vector2(5, 6)]), Color("#120a0a"))
	pd.glow(h + Vector2(-1, 2), 3.0, Color(lamp, 0.6), 0.0)
	pd.draw_rect(Rect2(h + Vector2(-1.6, 1.4), Vector2(1.4, 1.2)), lamp)
	# 장대 + 등불
	var hand := Vector2(-11, -30).lerp(Vector2(-15, -40), atk)
	pd.draw_line(Vector2(-5, -40), hand, robe, 3.0)
	var top := hand + Vector2(-1, -26)
	pd.line2(hand + Vector2(1, 28), top, Color("#2a2018"), Color("#4a3a2a"), 2.0, 1.6)
	pd.draw_line(top, top + Vector2(-6, 0), Color("#2a2018"), 1.6)
	var lc := top + Vector2(-6, 6 + sin(_t * 2.4) * 1.2)
	pd.draw_line(top + Vector2(-6, 0), lc + Vector2(0, -4), Color("#2a2018"), 0.8)
	var gl := 1.0 + 0.15 * sin(_t * 5.0) + (0.6 if guard_link else 0.0)
	pd.glow(lc, 14.0 * gl, Color(lamp, 0.35), 0.0)
	pd.outlined(PackedVector2Array([lc + Vector2(-3, -4), lc + Vector2(3, -4), lc + Vector2(4, 3), lc + Vector2(-4, 3)]), Color("#3a2a20"), OUT, 0.6)
	pd.draw_rect(Rect2(lc + Vector2(-2.4, -3), Vector2(4.8, 5.4)), Color(lamp, 0.95))
	pd.draw_circle(lc + Vector2(0, 0), 1.3, Color(1, 1, 0.9))


# ── 그림자 서기: 보라 그림자 몸(정령) + 앞에 펼친 책(사각 둘) + 깃펜, 눈은 가는 흰 선 · 흩기 때 책장에서 마름모가 날아감
func _paint_scribe() -> void:
	var c := Vector2(0, -24 + _bob(2.0))
	var col := Color("#5a4a78")
	var dk := Color("#3a2e52")
	# 그림자 꼬리 (아래로 흐름)
	for k in 3:
		var x := -5.0 + 5.0 * float(k)
		pd.draw_colored_polygon(PackedVector2Array([c + Vector2(x - 3, 8), c + Vector2(x + sin(_t * 2.0 + float(k)) * 3.0, 22.0 + float(k % 2) * 3.0), c + Vector2(x + 3, 8)]), Color(dk, 0.8))
	# 몸 (두건 꼴 물방울)
	_drop(c + Vector2(0, -2), 11.0, col)
	pd.glow(c, 18.0, Color("#b9a2ff", 0.15), 0.0)
	pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -6), c + Vector2(-2, -9), c + Vector2(4, -7), c + Vector2(4, 0), c + Vector2(-7, 0)]), Color("#120a1e"))
	# 눈: 가는 흰 선
	var open := 1.0 if _blink <= 0.0 else 0.3
	pd.draw_line(c + Vector2(-6, -4), c + Vector2(-3, -4 + 0.5 * open), Color(1, 1, 1, 0.9 * open + 0.1), 1.0)
	pd.draw_line(c + Vector2(-1, -4), c + Vector2(2, -4 + 0.5 * open), Color(1, 1, 1, 0.9 * open + 0.1), 1.0)
	# 펼친 책 (앞 아래)
	var b := c + Vector2(-12, 4)
	var tilt := sin(_t * 1.5) * 0.08
	pd.draw_set_transform(b, tilt, Vector2.ONE)
	pd.outlined(PackedVector2Array([Vector2(-8, -1), Vector2(0, 1), Vector2(0, 7), Vector2(-8, 5)]), Color("#e8e0d0"), OUT, 0.6)
	pd.outlined(PackedVector2Array([Vector2(0, 1), Vector2(8, -1), Vector2(8, 5), Vector2(0, 7)]), Color("#d8d0c0"), OUT, 0.6)
	for k in 3:
		pd.draw_line(Vector2(-6, 1.5 + 1.4 * float(k)), Vector2(-2, 2.2 + 1.4 * float(k)), Color(dk, 0.7), 0.5)
		pd.draw_line(Vector2(2, 2.2 + 1.4 * float(k)), Vector2(6, 1.5 + 1.4 * float(k)), Color(dk, 0.7), 0.5)
	pd.draw_set_transform(Vector2.ZERO)
	# 깃펜 (오른손)
	var q := c + Vector2(8, -2 + sin(_t * 3.0))
	pd.draw_line(q, q + Vector2(-6, 8), Color("#e6dcff"), 1.2)
	pd.draw_colored_polygon(PackedVector2Array([q, q + Vector2(3, -6), q + Vector2(-1, -2)]), Color("#e6dcff"))
	if pose == "buff":
		for k in 3:
			TTheme.diamond(pd, b + Vector2(-6.0 + 6.0 * float(k), -6.0 - 10.0 * fmod(_t * 2.0 + float(k) * 0.3, 1.0)), 2.2, Color("#b07a3a"))


# ── 빈 갑주: 은회 판금 + 비어 있는 투구 눈구멍(검은 띠, 빛 없음) + 이음새 사이 아무것도 없는 틈 · 방어 태세 땐 팔짱
func _paint_hollow() -> void:
	# R4 (검토 O 언어 한 단계 더): 판 색을 한 톤 낮춤(명암 셰이더가 위를 밝혀 흰 장난감처럼 보였다) · 판마다 오른쪽 그늘 · 판 경계 밝은 선 ·
	# 빈 틈(눈·허리·목) 속 옅은 유령 빛 — 재의 기사 판금과 같은 3단
	var plate := Color("#8a889a")
	var plate_hi := Color("#b4b2c4")
	var plate_dk := Color("#4e4c5c")
	var edge := Color("#e2e0ee", 0.75)
	var ghost := Color("#b9a2ff")
	var void_c := Color("#05040a")
	for x: float in [-5.0, 5.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 3.4, -22), Vector2(x + 3.4, -22), Vector2(x + 3.0, -12), Vector2(x - 3.0, -12)]), plate, OUT, 0.8)
		pd.draw_rect(Rect2(Vector2(x - 2.4, -12), Vector2(4.8, 1.6)), void_c) # 무릎 틈
		pd.outlined(PackedVector2Array([Vector2(x - 3.2, -10.4), Vector2(x + 3.2, -10.4), Vector2(x + 3.0, -2), Vector2(x - 3.0, -2)]), plate, OUT, 0.8)
		pd.draw_line(Vector2(x + 1.8, -21), Vector2(x + 1.6, -13), plate_dk, 1.4) # 정강이·허벅지 그늘
		pd.draw_line(Vector2(x + 1.8, -9.6), Vector2(x + 1.6, -3), plate_dk, 1.4)
		pd.draw_line(Vector2(x - 2.6, -21.4), Vector2(x + 2.6, -21.4), edge, 0.5)
		pd.outlined(PackedVector2Array([Vector2(x - 4.2, -2.5), Vector2(x + 4.6, -2.5), Vector2(x + 5.4, 0.5), Vector2(x - 4.4, 0.5)]), plate_dk, OUT, 0.8)
	# 허리 틈 (몸통과 다리 사이가 비어 있음)
	pd.draw_rect(Rect2(Vector2(-7, -25), Vector2(14, 2.4)), void_c)
	pd.draw_line(Vector2(-5, -23.8), Vector2(5, -23.8), Color(ghost, 0.35), 0.8) # 빈 속의 유령 빛
	var torso := PackedVector2Array([Vector2(-10, -48), Vector2(10, -48), Vector2(11.5, -37), Vector2(8, -26), Vector2(-8, -26), Vector2(-11.5, -37)])
	pd.outlined(torso, plate, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-10, -48), Vector2(-2, -48), Vector2(-3, -27), Vector2(-8, -26), Vector2(-11.5, -37)]), plate_hi)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(4, -48), Vector2(10, -48), Vector2(11.5, -37), Vector2(8, -26), Vector2(3.5, -26.5)]), Color(plate_dk, 0.6)) # 가슴판 오른쪽 그늘
	pd.draw_line(Vector2(-9, -36), Vector2(9, -36), plate_dk, 1.2)
	pd.draw_line(Vector2(-9, -35.1), Vector2(9, -35.1), Color(edge, 0.5), 0.5) # 판 경계 아래 밝은 선
	pd.draw_line(Vector2(-9.6, -47.6), Vector2(9.6, -47.6), edge, 0.6) # 가슴판 윗모서리
	# 목 틈 + 투구 (눈구멍이 비어 있음)
	pd.draw_rect(Rect2(Vector2(-4, -50.5), Vector2(8, 2.4)), void_c)
	var h := Vector2(0, -57)
	pd.outlined(PackedVector2Array([h + Vector2(-6, -7), h + Vector2(-2, -10), h + Vector2(3, -10), h + Vector2(6.5, -6), h + Vector2(6.5, 5), h + Vector2(-6.5, 5)]), plate, OUT, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-6, -7), h + Vector2(-2, -10), h + Vector2(-2, 5), h + Vector2(-6.5, 5)]), plate_hi)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(3, -10), h + Vector2(6.5, -6), h + Vector2(6.5, 5), h + Vector2(2.5, 5)]), Color(plate_dk, 0.6)) # 투구 그늘
	pd.draw_line(h + Vector2(-5.6, -7.2), h + Vector2(-2, -9.6), edge, 0.6) # 투구 윗모서리 빛
	pd.draw_rect(Rect2(h + Vector2(-6.5, -2), Vector2(9, 2.4)), void_c)
	pd.glow(h + Vector2(-2.5, -0.8), 4.0, Color(ghost, 0.3), 0.0) # 빈 눈구멍 속 유령 빛
	pd.draw_line(h + Vector2(-5.5, -0.8), h + Vector2(0.5, -0.8), Color(ghost.lightened(0.3), 0.55), 0.6)
	pd.draw_line(h + Vector2(0, -10), h + Vector2(0, -15), plate_dk, 1.4)
	# 어깨 (판 둘) · 팔: 서 있을 땐 늘어뜨림, 방어 태세 땐 팔짱 (방패 없음)
	for sgn: float in [-1.0, 1.0]:
		pd.outlined(PackedVector2Array([Vector2(sgn * 7, -50), Vector2(sgn * 15, -47), Vector2(sgn * 13, -40), Vector2(sgn * 6, -42)]), plate_hi if sgn < 0 else plate, OUT, 0.8)
		pd.draw_rect(Rect2(Vector2(sgn * 12 - 1.5, -41), Vector2(3, 2)), void_c) # 어깨 틈
	if guarding:
		pd.line2(Vector2(-12, -39), Vector2(8, -33), OUT, OUT, 5.0, 5.0)
		pd.line2(Vector2(-12, -39), Vector2(8, -33), plate, plate, 3.6, 3.6)
		pd.line2(Vector2(12, -39), Vector2(-8, -31), OUT, OUT, 5.0, 5.0)
		pd.line2(Vector2(12, -39), Vector2(-8, -31), plate_hi, plate_hi, 3.6, 3.6)
	else:
		var atk := 1.0 if pose == "attack" else 0.0
		var hand := Vector2(-15, -24).lerp(Vector2(-20, -42), atk)
		pd.line2(Vector2(-12, -40), hand, OUT, OUT, 5.0, 4.4)
		pd.line2(Vector2(-12, -40), hand, plate, plate, 3.6, 3.0)
		pd.draw_circle(hand, 2.6, plate_dk)
		pd.line2(Vector2(12, -40), Vector2(14, -24), OUT, OUT, 5.0, 4.4)
		pd.line2(Vector2(12, -40), Vector2(14, -24), plate_dk, plate_dk, 3.6, 3.0)


# ── 세 빛의 인형 (보스): 세로로 긴 마름모 몸(연보라) + 면 셋 중 지금 줄 속성 면이 그 색으로 빛남(물 → 번개 → 불) +
#    작은 마름모 머리 + 떠 있는 프리즘 조각 둘 · 줄 3에서 몸에 금
func _paint_doll() -> void:
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.9, 0.9))
	var el: String = ["water", "bolt", "fire"][clampi(phase, 0, 2)]
	var ecol: Color = TData.ELEMENT_COLOR.get(el, Color.WHITE)
	var body := Color("#c8c0e0")
	var body_dk := Color("#8a80a8")
	var c := Vector2(0, -38 + _bob(2.0))
	var beat := 0.5 + 0.5 * sin(_t * 2.6)
	# 아래 받침 빛 (떠 있음)
	pd.draw_set_transform(Vector2(0, -2), 0.0, Vector2(0.9, 0.9 * 0.3))
	pd.glow(Vector2.ZERO, 22.0, Color(ecol, 0.35), 0.0)
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.9, 0.9))
	# 뒤 조각 (몸 뒤 반을 지나는 것)
	for i in 2:
		var an := _t * 1.3 + PI * float(i)
		_shard(c + Vector2(cos(an) * 24.0, -6.0 + sin(an) * 6.0), _t * 1.7 * (1.0 if i == 0 else -0.8), ecol, sin(an) < 0.0, true)
	# 몸: 마름모 + 면 셋 (왼 · 가운데 · 오른)
	var top := c + Vector2(0, -24)
	var bot := c + Vector2(0, 30)
	var lft := c + Vector2(-15, 0)
	var rgt := c + Vector2(15, 0)
	pd.glow(c, 34.0, Color(ecol, 0.18 + 0.1 * beat), 0.0)
	pd.outlined(PackedVector2Array([top, rgt, bot, lft]), body, OUT, 1.2)
	var mid_l := c + Vector2(-5, 0)
	var mid_r := c + Vector2(5, 0)
	var faces := [[top, mid_l, bot, lft], [top, mid_r, bot, mid_l], [top, rgt, bot, mid_r]]
	var face_el := ["water", "bolt", "fire"]
	for i in 3:
		var on: bool = String(face_el[i]) == el
		var fc: Color = TData.ELEMENT_COLOR.get(String(face_el[i]), body)
		var col := fc.lerp(Color.WHITE, 0.15 * beat) if on else body.lerp(fc, 0.18).darkened(0.12 * float(i == 2))
		pd.convex(PackedVector2Array(faces[i]), Color(col, 0.95 if on else 0.85))
	pd.draw_line(top, mid_l, Color(body_dk, 0.8), 0.8)
	pd.draw_line(top, mid_r, Color(body_dk, 0.8), 0.8)
	pd.draw_line(mid_l, bot, Color(body_dk, 0.8), 0.8)
	pd.draw_line(mid_r, bot, Color(body_dk, 0.8), 0.8)
	pd.draw_line(top + Vector2(-1, 4), lft + Vector2(3, 0), Color(1, 1, 1, 0.6), 0.8) # 왼쪽 위 빛
	# 가운데 핵
	pd.glow(c + Vector2(0, -2), 6.0 + 2.0 * beat, Color(ecol, 0.7), 0.0)
	TTheme.diamond(pd, c + Vector2(0, -2), 3.0, Color.WHITE)
	# 줄 3: 몸에 금
	if phase >= 2:
		_zig(c + Vector2(-8, -12), c + Vector2(4, 14), 5, 2.0, Color(OUT, 0.9), 1.4, 2)
		_zig(c + Vector2(-8, -12), c + Vector2(4, 14), 5, 2.0, Color(ecol, 0.9), 0.7, 2)
	# 머리: 작은 마름모 + 눈 하나
	var h := top + Vector2(0, -9)
	pd.outlined(PackedVector2Array([h + Vector2(0, -7), h + Vector2(6, 0), h + Vector2(0, 7), h + Vector2(-6, 0)]), body, OUT, 0.9)
	pd.convex(PackedVector2Array([h + Vector2(0, -7), h + Vector2(0, 7), h + Vector2(-6, 0)]), body.lightened(0.15))
	pd.glow(h + Vector2(-1.5, 0), 4.0, Color(ecol, 0.8), 0.0)
	pd.draw_circle(h + Vector2(-1.5, 0), 1.4, ecol.lightened(0.4))
	# 앞 조각 (몸 앞 반을 지나는 것)
	for i in 2:
		var an := _t * 1.3 + PI * float(i)
		_shard(c + Vector2(cos(an) * 24.0, -6.0 + sin(an) * 6.0), _t * 1.7 * (1.0 if i == 0 else -0.8), ecol, sin(an) < 0.0, false)
	if _phase_flash > 0.0:
		pd.glow(c, 60.0 * _phase_flash, Color(ecol, 0.5 * _phase_flash), 0.0)
	pd.draw_set_transform(Vector2.ZERO)


## 프리즘 조각 (behind면 뒤 반에서만 그림 — 몸 앞뒤를 오감)
func _shard(p: Vector2, rot: float, ecol: Color, behind: bool, back: bool) -> void:
	if behind != back:
		return
	var r := 6.0
	var pts := PackedVector2Array()
	for k in 3:
		pts.append(p + Vector2.from_angle(rot + TAU * float(k) / 3.0) * r)
	pd.glow(p, 8.0, Color(ecol, 0.35), 0.0)
	pd.outlined(pts, Color("#ece8fa"), OUT, 0.7)
	pd.draw_line(pts[0], p, Color(ecol, 0.9), 1.0)


# ── 잿빛 둥지어미 (보스): 낮고 넓은 몸(어두운 적회) + 등에 접힌 재 날개(삼각 넷) + 배 아래 빛나는 알 셋 · 줄 2에서 날개를 펼침
func _paint_brood() -> void:
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.95, 0.95))
	var skin := Color("#5a4048")
	var skin_hi := Color("#7a5a62")
	var skin_dk := Color("#3a2830")
	var atk := 1.0 if pose == "attack" else 0.0
	var open := 1.0 if phase >= 1 else 0.0
	var beat := 0.5 + 0.5 * sin(_t * 2.0)
	# 날개 (뒤): 접힘 → 펼침
	for i in 4:
		var base := Vector2(-6.0 + 8.0 * float(i), -26)
		var ang := lerpf(-0.35 - 0.12 * float(i), -1.2 + 0.45 * float(i), open) + sin(_t * 1.6 + float(i)) * 0.05
		var tip := base + Vector2.from_angle(-PI * 0.5 + ang) * (22.0 + 8.0 * open)
		var side := base + Vector2(10, 4)
		pd.outlined(PackedVector2Array([base, tip, side]), Color("#4a3a42").darkened(0.08 * float(i)), OUT, 0.8)
		pd.draw_line(base, tip, Color("#8a7a80", 0.8), 0.8)
		if open > 0.0:
			pd.glow(tip, 4.0, Color(EMBER, 0.35), 0.0)
	# 다리 (짧고 굵게)
	for x: float in [-20.0, -8.0, 10.0, 22.0]:
		pd.outlined(PackedVector2Array([Vector2(x - 3.5, -9), Vector2(x + 3.5, -9), Vector2(x + 4.5, 0), Vector2(x - 4.5, 0)]), skin_dk, OUT, 0.8)
		for k in 3:
			pd.draw_line(Vector2(x - 3 + 3.0 * float(k), 0), Vector2(x - 4 + 4.0 * float(k), 2), skin_dk, 1.2)
	# 몸 (넓은 타원)
	var body := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		body.append(Vector2(cos(a) * 28.0, -17.0 + sin(a) * (11.0 + atk * 1.5)))
	pd.outlined(body, skin, OUT, 1.0)
	pd.draw_set_transform(Vector2(-4, -22), 0.0, Vector2(0.95, 0.95 * 0.4))
	pd.glow(Vector2.ZERO, 18.0, Color(skin_hi, 0.8), 0.0)
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.95, 0.95))
	# 등의 재 비늘 점
	for p: Vector2 in [Vector2(-10, -25), Vector2(0, -27), Vector2(10, -25), Vector2(16, -21), Vector2(-17, -21)]:
		pd.draw_circle(p, 1.6, skin_dk)
	# 배 아래 알 셋 (빛남, 맥박)
	for i in 3:
		var ep := Vector2(-8.0 + 8.0 * float(i), -7.0)
		pd.glow(ep, 6.0 + 2.0 * beat, Color(EMBER, 0.5), 0.0)
		pd.draw_set_transform(ep, 0.0, Vector2(0.95, 0.95 * 1.25))
		pd.draw_circle(Vector2.ZERO, 3.4, OUT)
		pd.draw_circle(Vector2.ZERO, 2.8, Color(EMBER).lerp(EMBER_PALE, 0.3 * beat))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.95, 0.95))
	# 머리 (왼쪽, 낮게 내민 목) + 붉은 눈 둘 + 턱
	var h := Vector2(-31, -20 - 3.0 * atk)
	pd.outlined(PackedVector2Array([h + Vector2(-8, -3), h + Vector2(0, -8), h + Vector2(8, -5), h + Vector2(8, 4), h + Vector2(-2, 5), h + Vector2(-9, 2)]), skin, OUT, 0.9)
	pd.draw_line(h + Vector2(-9, 2), h + Vector2(4, 3.5 + 2.0 * atk), OUT, 1.0)
	for ex: float in [-4.0, 0.0]:
		pd.glow(h + Vector2(ex, -2), 2.6, Color("#ff3a2a", 0.7), 0.0)
		pd.draw_rect(Rect2(h + Vector2(ex - 0.8, -2.6), Vector2(1.6, 1.2)), Color("#ffb0a0"))
	pd.outlined(PackedVector2Array([h + Vector2(2, -7), h + Vector2(5, -13), h + Vector2(6, -6)]), skin_dk, OUT, 0.6) # 뿔
	if _phase_flash > 0.0:
		pd.glow(Vector2(0, -20), 50.0 * _phase_flash, Color(EMBER, 0.45 * _phase_flash), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
