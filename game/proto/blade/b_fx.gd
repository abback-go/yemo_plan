class_name BFx
extends RefCounted
## 빗자루 검 손맛 데모 이펙트 (docs/eska-turn/README.md §0-2). 전부 코드 그림, 이펙트 하나 = 노드 하나 = 그리기 호출 하나(PDraw).
## 참격(Slash): 레퍼런스(마엘)보다 날카롭고 빠르게 —
##   칼끝을 따라 2~3프레임에 펼쳐지고(앞 70%가 첫 프레임에), 꼬리가 바로 쫓아와 약 0.14초에 바늘 끝으로 사라진다.
##   앞쪽이 가장 두껍고 양 끝은 바늘. 바깥부터: 먹빛 테두리 1.5px → 흰 칼끝 선 → 옅은 라벤더 → 라벤더 → 마젠타로 투명하게.
##   안쪽엔 길이가 다른 결 4줄(흰·자두빛이 번갈아 붓결처럼), 칼끝이 지나간 자리 바깥으로 속도선이 접선 방향으로 튀어 나간다.
## 맞은 자리(CutLine): 표적을 길게 관통하는 가는 참격선 — 2프레임 하얗게 번쩍인 뒤 두 줄로 벌어지며(사이는 검은 무) 사라진다.
## 파랑은 쓰지 않는다.

const WHITE := Color(1, 1, 1)
const EDGE := Color("#fbf7ff")
const PALE := Color("#e6dcff")
const LAV := Color("#b9a2ff")
const MAG := Color("#e352ff")
const PLUM := Color("#3b1268")
const INK := Color("#14081f")
const VIOLET := Color("#9b3cff")
const PROF_MAX := 0.549 ## 두께 모양 함수의 최댓값 (1로 맞추려고 나눔 — s ≈ 0.79에서)


## 휘두름 진행도 → 칼끝 진행도 (첫 프레임에 약 70%: 아주 빠르게 나갔다가 끝에서 멈춤). 에스카의 손·칼과 참격 그림이 같이 쓴다
static func head_f(t: float, sw: float) -> float:
	var p := clampf(t / maxf(sw, 0.001), 0.0, 1.0)
	return 1.0 - pow(1.0 - p, 3.0)


## 두께 모양 (s: 0 꼬리 → 1 머리): 꼬리는 길게 가늘어지고, 머리 쪽 80% 자리가 가장 두껍고, 끝 20%는 긴 바늘로 빠진다
static func prof(s: float) -> float:
	return pow(s, 1.6) * pow(maxf(1.0 - pow(s, 6.0), 0.0), 0.8) / PROF_MAX


## 기울인(rot) 납작한(sq) 타원 위의 점 · 바깥 법선 · 휘두르는 방향 접선 (각도는 라디안, 오른쪽을 보는 기준)
static func ell(r: float, sq: float, rot: float, a: float) -> Vector2:
	return Vector2(r * cos(a), r * sq * sin(a)).rotated(rot)


static func ell_n(sq: float, rot: float, a: float) -> Vector2:
	return Vector2(sq * cos(a), sin(a)).normalized().rotated(rot)


static func ell_t(sq: float, rot: float, a: float, dirn: float) -> Vector2:
	return (Vector2(-sin(a), sq * cos(a)) * dirn).normalized().rotated(rot)


## 여러 줄 띠: rows[k]는 같은 개수의 점, cols[k]는 점마다 색. 이웃한 두 줄 사이를 삼각형으로 메운다 (그리기 변환 없이 노드 좌표 그대로)
static func grid(pd: PDraw, rows: Array, cols: Array) -> void:
	var m := rows.size()
	if m < 2:
		return
	var n: int = (rows[0] as PackedVector2Array).size()
	if n < 2:
		return
	var base := pd.v.size()
	for k in m:
		pd.v.append_array(rows[k])
		pd.c.append_array(cols[k])
	var ids := PackedInt32Array()
	ids.resize((m - 1) * (n - 1) * 6)
	var q := 0
	for k in m - 1:
		var r0 := base + k * n
		var r1 := r0 + n
		for i in n - 1:
			ids[q] = r0 + i
			ids[q + 1] = r0 + i + 1
			ids[q + 2] = r1 + i
			ids[q + 3] = r1 + i
			ids[q + 4] = r0 + i + 1
			ids[q + 5] = r1 + i + 1
			q += 6
	pd.idx.append_array(ids)


## 바늘(마름모): x0 → x1 직선, 가운데가 굵기 w. y = 옆으로 비킨 자리
static func needle(pd: PDraw, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	if w <= 0.05 or col.a <= 0.01:
		return
	var m := a.lerp(b, 0.5)
	var o := (b - a).normalized().orthogonal() * w * 0.5
	pd.convex(PackedVector2Array([a, m + o, b, m - o]), col)


## 참격 하나를 at(전역)에 건다. spec: r · w · a0 · a1(도) · sq · rot(도) · sw(휘두르는 시간) · heavy
static func slash(at: Vector2, spec: Dictionary, facing: int) -> Slash:
	var s := Slash.new()
	s.setup(spec, facing)
	PVfx.add(s, at, false)
	return s


## 맞은 자리 참격선: pos(전역)를 지나 tan 방향으로 길이 len
static func cut(pos: Vector2, tan: Vector2, len: float, heavy: bool) -> void:
	var c := CutLine.new()
	c.len = len
	c.heavy = heavy
	c.rotation = tan.angle()
	PVfx.add(c, pos, false)


# ═══════════════════════════════════════════════════════════
# 참격
# ═══════════════════════════════════════════════════════════

class Slash extends PVfx.Base:
	const CHASE := 0.09 ## 휘두름이 끝난 뒤 꼬리가 머리를 따라잡는 시간
	## 몸통 줄: 칼끝에서 안쪽으로의 깊이(두께 비율 — 0·1번은 px로 따로) · 색 · 진하기. 2→3, 4→5에서 색이 단단하게 꺾인다
	const ROW_D := [0.0, 0.0, 0.3, 0.33, 0.68, 0.71, 1.0]
	const ROW_C := [BFx.WHITE, BFx.WHITE, BFx.PALE, BFx.LAV, BFx.VIOLET, BFx.PLUM, BFx.PLUM]
	const ROW_A := [1.0, 1.0, 0.95, 0.92, 0.8, 0.6, 0.0]
	const LINE_LIFE := 0.1
	const LINE_SPEED := 520.0
	var r := 50.0
	var w := 18.0
	var a0 := 0.0
	var a1 := 0.0
	var sq := 1.0
	var rot := 0.0
	var sw := 0.05
	var heavy := false
	var _dirn := 1.0
	var _lines: Array = [] ## [칼끝이 지나간 몫, 바깥으로 비킨 거리, 길이, 태어나는 시각]
	var _seed := 0

	func setup(spec: Dictionary, facing: int) -> void:
		r = float(spec.r)
		w = float(spec.w)
		a0 = deg_to_rad(float(spec.a0))
		a1 = deg_to_rad(float(spec.a1))
		sq = float(spec.get("sq", 1.0))
		rot = deg_to_rad(float(spec.get("rot", 0.0)))
		sw = float(spec.sw)
		heavy = bool(spec.get("heavy", false))
		_dirn = signf(a1 - a0)
		scale = Vector2(float(facing), 1.0)
		life = sw + CHASE + LINE_LIFE
		z_index = 6
		_seed = randi() % 1000
		var k := r / 50.0
		for i in (8 if heavy else 5):
			var f := randf_range(0.3, 1.0)
			var born := sw * (1.0 - pow(1.0 - f, 1.0 / 3.0)) # head_f의 역: 칼끝이 그 자리를 지나는 순간
			_lines.append([f, randf_range(4.0, 14.0) * k, randf_range(14.0, 30.0) * k * (1.3 if heavy else 1.0), born])

	func _tail_f() -> float:
		var td := sw * 0.4
		var q := clampf((t - td) / (sw + CHASE - td), 0.0, 1.0)
		return q * q

	func _paint() -> void:
		var hf := BFx.head_f(t, sw)
		var tf := _tail_f()
		_paint_lines()
		if hf - tf < 0.012:
			return
		var th_a := lerpf(a0, a1, tf)
		var hd_a := lerpf(a0, a1, hf)
		var vis := absf(hd_a - th_a)
		var after := clampf((t - sw) / CHASE, 0.0, 1.0)
		var wk := w * (1.0 - 0.55 * after) * clampf(vis / 0.7, 0.35, 1.0)
		var n := clampi(int(vis * r / 4.0), 6, 56)
		var es := PackedVector2Array()
		var ns := PackedVector2Array()
		var th := PackedFloat32Array()
		var la := PackedFloat32Array()
		es.resize(n)
		ns.resize(n)
		th.resize(n)
		la.resize(n)
		for i in n:
			var s := float(i) / float(n - 1)
			var a := lerpf(th_a, hd_a, s)
			es[i] = BFx.ell(r, sq, rot, a)
			ns[i] = BFx.ell_n(sq, rot, a)
			th[i] = wk * BFx.prof(s)
			la[i] = (0.35 + 0.65 * smoothstep(0.0, 0.5, s)) * (1.0 - 0.35 * after)
		# 먹빛 테두리 (칼끝 선 바깥으로 1.5px만 보임)
		var ink_o := PackedVector2Array()
		var ink_i := PackedVector2Array()
		var ink_c := PackedColorArray()
		ink_o.resize(n)
		ink_i.resize(n)
		ink_c.resize(n)
		for i in n:
			ink_o[i] = es[i] + ns[i] * (1.5 + th[i] * 0.06)
			ink_i[i] = es[i] - ns[i] * minf(th[i] * 0.35, 2.5)
			ink_c[i] = Color(BFx.INK, 0.85 * la[i])
		BFx.grid(pd, [ink_o, ink_i], [ink_c, ink_c])
		# 몸통 (셀 그림처럼 단단한 경계): 흰 칼끝 심 → 옅은 라벤더 | 라벤더 → 보라 | 자두빛 그늘 → 투명
		var rows: Array = []
		var cols: Array = []
		for k in ROW_D.size():
			var row := PackedVector2Array()
			var col := PackedColorArray()
			row.resize(n)
			col.resize(n)
			for i in n:
				var d := float(ROW_D[k]) * th[i]
				if k == 0:
					d = -0.5
				elif k == 1:
					d = minf(1.4, th[i] * 0.28)
				row[i] = es[i] - ns[i] * d
				col[i] = Color(ROW_C[k], float(ROW_A[k]) * la[i])
			rows.append(row)
			cols.append(col)
		BFx.grid(pd, rows, cols)
		# 결무늬: 흰 결·자두빛 결이 번갈아 (길이가 서로 달라 붓으로 그은 듯)
		for k in 4:
			var df := 0.3 + 0.16 * float(k)
			var s0 := 0.14 + 0.11 * float(k) + 0.05 * EVfx.hash01(_seed + k)
			var s1 := 0.98 - 0.05 * float(k)
			var i0 := int(s0 * float(n - 1))
			var i1 := int(s1 * float(n - 1))
			if i1 - i0 < 2:
				continue
			var l := PackedVector2Array()
			var rr := PackedVector2Array()
			for i in range(i0, i1 + 1):
				var c := es[i] - ns[i] * th[i] * df
				l.append(c + ns[i] * 0.5)
				rr.append(c - ns[i] * 0.5)
			var sc := Color(BFx.WHITE if k % 2 == 0 else BFx.INK, 0.0)
			var ec := Color(sc, (0.75 if k % 2 == 0 else 0.5) * la[i1])
			pd.strip_grad(l, rr, sc, ec)
		# 칼끝 흰 심 (꼬리 쪽은 옅게) + 휘두르는 동안 머리 쪽이 더 굵고 하얗게
		var core_l := PackedVector2Array()
		var core_r := PackedVector2Array()
		var i_core := int(0.25 * float(n - 1))
		var hot := 1.0 - clampf(t / (sw * 1.2), 0.0, 1.0)
		for i in range(i_core, n):
			var cw := 1.3 + 1.6 * hot * smoothstep(0.55, 0.95, float(i) / float(n - 1))
			core_l.append(es[i] + ns[i] * 0.4)
			core_r.append(es[i] - ns[i] * (cw - 0.4))
		pd.strip_grad(core_l, core_r, Color(BFx.WHITE, 0.0), Color(BFx.WHITE, la[n - 1]))
		# 칼끝 반짝임 + 앞으로 뻗는 흰 바늘 (휘두르는 동안만)
		if t < sw + 0.03:
			var hp := es[n - 1]
			var g := 1.0 - clampf(t / (sw + 0.03), 0.0, 1.0)
			var tn := BFx.ell_t(sq, rot, hd_a, _dirn)
			pd.line2(hp, hp + tn * (8.0 + 12.0 * g) * (r / 50.0), Color(BFx.WHITE, g), Color(BFx.WHITE, 0.0), 1.4, 0.2)
			EVfx.star4(pd, hp, (5.0 if not heavy else 8.0) * (0.6 + 0.4 * g), tn.angle(), Color(BFx.WHITE, g), Color(BFx.LAV, 0.35 * g))

	## 속도선: 칼끝이 지나간 자리 바깥에서 휘두르는 방향(접선)으로 튀어 나가며 짧아진다
	func _paint_lines() -> void:
		for ln: Array in _lines:
			var age := t - float(ln[3])
			if age < 0.0 or age >= LINE_LIFE:
				continue
			var q := age / LINE_LIFE
			var a := lerpf(a0, a1, float(ln[0]))
			var tn := BFx.ell_t(sq, rot, a, _dirn)
			var p := BFx.ell(r, sq, rot, a) + BFx.ell_n(sq, rot, a) * float(ln[1]) + tn * LINE_SPEED * age
			var tail := p - tn * float(ln[2]) * (1.0 - q)
			pd.line2(tail, p, Color(BFx.LAV, 0.0), Color(BFx.WHITE, 0.9 * (1.0 - q)), 0.4, 1.4)


# ═══════════════════════════════════════════════════════════
# 맞은 자리 참격선
# ═══════════════════════════════════════════════════════════

class CutLine extends PVfx.Base:
	const BRIGHT := 0.035 ## 처음 하얗게 번쩍이는 시간 (2프레임)
	var len := 64.0
	var heavy := false

	func _ready() -> void:
		life = 0.26 if heavy else 0.2
		z_index = 7

	func _paint() -> void:
		var x := k()
		var hl := len * 0.5 * (1.0 + 0.2 * (1.0 - pow(1.0 - x, 2.0)))
		var a := Vector2(-hl, 0)
		var b := Vector2(hl, 0)
		if t < BRIGHT:
			BFx.needle(pd, a * 1.1, b * 1.1, 7.0 if heavy else 5.0, Color(BFx.LAV, 0.4))
			BFx.needle(pd, a, b, 4.0 if heavy else 3.0, BFx.WHITE)
			var cr := 10.0 if heavy else 7.0
			BFx.needle(pd, Vector2(0, -cr), Vector2(0, cr), 1.6, BFx.WHITE) # 가로지르는 짧은 섬광
			pd.glow(Vector2.ZERO, 5.0 if heavy else 3.5, Color(BFx.WHITE, 0.55), 0.0)
			return
		var q := (t - BRIGHT) / (life - BRIGHT)
		var open := (2.6 if heavy else 1.8) * (1.0 - pow(1.0 - q, 3.0)) + 0.4
		var al := 1.0 - q * q
		var o := Vector2(0, open)
		BFx.needle(pd, a, b, open * 2.0, Color(BFx.INK, 0.85 * al)) # 벌어진 틈 = 검은 무
		var ew := 1.8 * (1.0 - q) + 0.5
		BFx.needle(pd, a - o, b - o, ew, Color(BFx.PALE, al))
		BFx.needle(pd, a + o, b + o, ew, Color(BFx.LAV, al))
		if heavy:
			for i in 3: # 틈 안의 별빛
				var f := (float(i) + 0.5) / 3.0 - 0.5
				pd.draw_rect(Rect2(Vector2(f * hl * 1.2 - 0.5, -0.5), Vector2(1, 1)), Color(BFx.WHITE, al))


# ═══════════════════════════════════════════════════════════
# 모드 바꾸기 그림
# ═══════════════════════════════════════════════════════════

## 빗자루 → 검: 솔이 칼날로 접혀 뻗는 흰 섬광 (dir = 칼 방향 전역, len = 칼 길이)
class Unfold extends PVfx.Base:
	var dir := Vector2.RIGHT
	var len := 26.0

	func _ready() -> void:
		life = 0.22
		z_index = 7

	func _paint() -> void:
		var g := minf(t / 0.05, 1.0)
		var x := k()
		var tip := dir * len * 1.5 * (1.0 - pow(1.0 - g, 3.0))
		pd.ring_grad(Vector2.ZERO, Vector2.ONE * (3.0 + 14.0 * x), Vector2.ONE * (4.5 + 14.0 * x), Color(BFx.LAV, 0.0), Color(BFx.PALE, 0.8 * (1.0 - x)), 20)
		pd.line2(Vector2.ZERO, tip, Color(BFx.WHITE, 1.0 - x), Color(BFx.PALE, 1.0 - x), 3.0 * (1.0 - x) + 0.6, 0.6)
		EVfx.star4(pd, tip, 8.0 * (1.0 - x) + 2.0, dir.angle() + PI * 0.25, Color(BFx.WHITE, 1.0 - x), Color(BFx.LAV, 0.5 * (1.0 - x)))
		pd.glow(Vector2.ZERO, 10.0 * (1.0 - x * 0.5), Color(BFx.LAV, 0.4 * (1.0 - x)), 0.0)


## 검 → 빗자루: 몸을 둘러 퍼지는 라벤더 파동 (납작한 고리 + 바깥으로 튀는 결)
class Wave extends PVfx.Base:
	const R1 := 66.0
	const SQ := 0.62

	func _ready() -> void:
		life = 0.26
		z_index = 6

	func _paint() -> void:
		var x := k()
		var e := 1.0 - pow(1.0 - x, 3.0)
		var r := lerpf(10.0, R1, e)
		var th := 8.0 * (1.0 - x) + 1.0
		var a := 1.0 - x * x
		pd.ring_grad(Vector2.ZERO, Vector2(r - th, (r - th) * SQ), Vector2(r, r * SQ), Color(BFx.MAG, 0.0), Color(BFx.LAV, 0.8 * a), 40)
		pd.ring_grad(Vector2.ZERO, Vector2(r - 1.2, (r - 1.2) * SQ), Vector2(r + 0.6, (r + 0.6) * SQ), Color(BFx.WHITE, a), Color(BFx.WHITE, a), 40)
		for i in 10:
			var an := TAU * float(i) / 10.0 + 0.3
			var d := Vector2(cos(an), sin(an) * SQ)
			pd.line2(d * (r + 2.0), d * (r + 2.0 + 10.0 * (1.0 - x)), Color(BFx.WHITE, a), Color(BFx.LAV, 0.0), 1.2, 0.3)


# ═══════════════════════════════════════════════════════════
# 마검술 「공간참」: 앞을 곧게 가른 선이 한 박자 뒤 틈으로 벌어져 터진다
# ═══════════════════════════════════════════════════════════

class SpaceCut extends PVfx.Base:
	const HOLD := 0.2 ## 가른 선이 머무는 시간 (그 뒤 틈이 터짐)
	const OPEN := 0.05
	const HALF_W := 7.0
	var len := 250.0
	var on_burst := Callable() ## 틈이 터지는 순간 (피해는 부르는 쪽이)
	var _burst := false
	var _shape: Array = []
	var _seed := 0

	func _ready() -> void:
		life = 0.75
		z_index = 6
		_seed = randi() % 997
		_shape = EVfx.rift_line(Vector2.ZERO, Vector2(len, 0), HALF_W, 20, _seed, 1.5)

	func _tick(_delta: float) -> void:
		if not _burst and t >= HOLD:
			_burst = true
			if on_burst.is_valid():
				on_burst.call()

	func _paint() -> void:
		if t < HOLD:
			# 가는 흰 선 (처음 2프레임은 굵게) + 선을 따라 미세하게 떨리는 빛
			var hot := 1.0 - clampf(t / 0.04, 0.0, 1.0)
			BFx.needle(pd, Vector2(-6, 0), Vector2(len + 10.0, 0), 1.4 + 3.0 * hot, BFx.WHITE)
			BFx.needle(pd, Vector2(-6, 0), Vector2(len + 10.0, 0), 5.0 + 4.0 * hot, Color(BFx.LAV, 0.35))
			var shimmer := 0.5 + 0.5 * sin(t * 90.0)
			for i in 5:
				var x := len * (float(i) + 0.5) / 5.0
				pd.draw_rect(Rect2(Vector2(x - 0.5, -1.5 - shimmer), Vector2(1, 1)), Color(BFx.PALE, 0.8))
			return
		var q := (t - HOLD) / (life - HOLD)
		var open := minf((t - HOLD) / OPEN, 1.0)
		var zip := clampf((q - 0.25) / 0.75, 0.0, 1.0)
		var oa: Array = EVfx.rift_open(_shape[2], open, zip, 0.6, 1.0 - q * q)
		EVfx.rift(pd, _shape[0], _shape[1], oa[0], oa[1], _seed, t)
		if q < 0.2: # 터지는 순간 선 전체가 하얗게
			var g := 1.0 - q / 0.2
			BFx.needle(pd, Vector2(-10, 0), Vector2(len + 14.0, 0), 6.0 * g, Color(BFx.WHITE, g))
