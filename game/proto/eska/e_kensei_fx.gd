class_name EKenseiFx
extends RefCounted
## 검성(EKensei) 이펙트: 차가운 흰 칼빛 + 붉은 잔광, 먹빛 (파랑 없음 — design.md 6장).
## - SlashLine: 벤 자리에 머리카락 같은 흰 선이 남았다가 한 박자 늦게 터지는 참격선 (검성의 상징)
## - Arc: 눈 깜빡할 새 지나가는 초승달 칼자국 (삼연참·반격)
## - CutMark: 이미 베인 에스카 몸에 걸린 흰 선 (발도 일섬에 맞으면 터질 때까지)
## - Wave(비검) · RainBlade(천검)는 에스카를 다치게 하는 위험물 — 봉공(공간 고정) 중에는 검성의 버팀(still_resist)만큼만 흐른다
## - Impact: 낙화 착지 충격 · Sheath: 2막에 내던진 칼집 · Drift: 바람에 날리는 꽃잎·잎(먹·붉은빛·뼈흰)
## 위험물은 GROUP에 들어 장면이 한꺼번에 거둘 수 있다(에스카가 쓰러져 처음부터 할 때).

const INK := Color("#0b090c")
const BONE := Color("#ece4d6")
const WHITE := Color("#f6f4f0") ## 차가운 흰 칼빛 (푸른 기 없음)
const RED := Color("#e0182f")
const RED_HOT := Color("#ff6a5c")
const RED_DEEP := Color("#6e0a16")
const GROUP := &"kensei_hazard"

static var wind := Vector2(46.0, 0.0) ## 지금 바람 (왼쪽 → 오른쪽: 입구에서 검성 쪽으로) (장면이 정함 — 꽃잎·머리칼·옷자락이 같이 쓴다)


## 봉공(공간 고정) 중 이 이펙트가 흐르는 빠르기: 검성이 굳은 공간을 버티는 만큼만
static func time_k(boss: Node) -> float:
	if not EStill.active():
		return 1.0
	if is_instance_valid(boss) and boss is EEnemy:
		return (boss as EEnemy).still_resist
	return 0.0


## 흰 칼빛 줄 하나 (바깥 붉은 잔광 → 흰 심): 굵기 w, 진하기 a
static func blade_light(pd: PDraw, a: Vector2, b: Vector2, w: float, al: float) -> void:
	if al <= 0.01 or w <= 0.05:
		return
	var d := (b - a)
	var n := d.normalized().orthogonal()
	# 양 끝이 뾰족한 마름모꼴 띠 3겹
	for spec: Array in [[2.6, Color(RED, 0.32 * al)], [1.5, Color(RED_HOT, 0.75 * al)], [0.7, Color(WHITE, al)]]:
		var k: float = spec[0]
		var c: Color = spec[1]
		var hw := w * 0.5 * k
		pd.draw_colored_polygon(PackedVector2Array([a, a + d * 0.5 + n * hw, b, a + d * 0.5 - n * hw]), c)


## 십자 반짝임 (칼코등이·눈·칼끝 번뜩임): 크기 s, 진하기 a — 가산 노드에서 그린다
static func glint(pd: PDraw, p: Vector2, s: float, al: float, red_rim := true) -> void:
	if al <= 0.01:
		return
	if red_rim:
		pd.glow(p, s * 1.6, Color(RED, 0.25 * al), 0.0)
	pd.glow(p, s * 0.8, Color(WHITE, 0.6 * al), 0.0)
	for spec: Array in [[Vector2(1, 0), 1.0], [Vector2(0, 1), 0.7], [Vector2(0.7, 0.7), 0.3], [Vector2(0.7, -0.7), 0.3]]:
		var dv: Vector2 = spec[0]
		var l: float = s * float(spec[1])
		pd.draw_colored_polygon(PackedVector2Array([p - dv * l, p + dv.orthogonal() * 0.7, p + dv * l, p - dv.orthogonal() * 0.7]), Color(WHITE, al))


## 흰 불티 + 붉은 잔불 (칼이 스친 자리)
static func sparks(pos: Vector2, n: int, dir: Vector2, speed := 160.0, spread := 60.0) -> void:
	var pp := PParticles.get_layer(true)
	var base := dir.angle() if dir != Vector2.ZERO else 0.0
	for i in n:
		var an := base + deg_to_rad(randf_range(-spread, spread))
		var v := Vector2(cos(an), sin(an)) * randf_range(speed * 0.3, speed)
		var c := WHITE if randf() < 0.6 else RED_HOT
		pp.spawn(pos, v, Vector2(0, 260), randf_range(0.2, 0.42), randf_range(1.0, 2.0), c, RED_DEEP, 1 if randf() < 0.5 else 0, 3.0)


## 꽃잎·잎을 한 번에 흩뿌림 (사라지기·쓰러짐·바람)
static func petals(pos: Vector2, n: int, area: Vector2, speed := 60.0) -> void:
	var d := Drift.get_layer()
	if d == null:
		return
	for i in n:
		var p := pos + Vector2(randf_range(-area.x, area.x), randf_range(-area.y, area.y))
		d.spawn(p, Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.3, speed) + Vector2(0, -20), randf_range(0.9, 1.8))


## 위험물 공통 바탕: 시간은 time_k로 흐르고, 장면이 GROUP으로 거둔다
class KenseiHazard extends PDraw.Canvas:
	var boss: Node
	var t := 0.0
	var life := 1.0

	func _ready() -> void:
		add_to_group(GROUP)

	func _process(delta: float) -> void:
		var d := delta * EKenseiFx.time_k(boss)
		t += d
		if t >= life:
			queue_free()
			return
		_tick(d)
		queue_redraw()

	func _tick(_delta: float) -> void:
		pass

	## 에스카가 이 사각형(전역)에 걸리면 피해 (맞혔으면 true)
	func hurt_eska(r: Rect2, dmg: int, from: Vector2) -> bool:
		var e := EEska.find(get_tree())
		if not is_instance_valid(e) or e.is_dead():
			return false
		if e.hurt_rect().intersects(r) and e.hurt(dmg, from):
			Fx.hitstop(0.05)
			EKenseiFx.sparks(e.center(), 8, (e.center() - from).normalized(), 150.0, 70.0)
			return true
		return false


## 참격선: 벤 순간 a→b(전역)에 가는 흰 선이 남았다가 delay초 뒤 터진다 (on_burst 호출 · 소리)
class SlashLine extends KenseiHazard:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var delay := 0.5
	var w := 10.0 ## 터질 때 굵기
	var loud := true ## 터지는 소리·흔들림
	var on_burst := Callable()
	var _burst := false

	func _ready() -> void:
		super._ready()
		life = delay + 0.42
		z_index = 6
		material = Fx.add_material

	func _tick(_delta: float) -> void:
		if not _burst and t >= delay:
			_burst = true
			if loud:
				Sfx.play_pitch(&"kb_burst", randf_range(0.95, 1.05), -1.0)
				Fx.shake(0.5, 0.16)
			var dv := (b - a)
			for i in 10:
				var p := a + dv * randf()
				EKenseiFx.sparks(p, 1, dv.normalized().orthogonal() * (1.0 if randf() < 0.5 else -1.0), 120.0, 40.0)
			if on_burst.is_valid():
				on_burst.call()

	func _paint() -> void:
		var la := a - position
		var lb := b - position
		if t < delay:
			# 벤 순간의 섬광 → 머리카락 같은 선 (가늘게 떨림)
			var f := clampf(t / 0.08, 0.0, 1.0)
			var hair := 0.55 + 0.25 * sin(t * 40.0)
			EKenseiFx.blade_light(pd, la, lb, lerpf(w * 0.7, 1.4, f), lerpf(1.0, hair, f))
			# 터지기 직전: 선이 조여들며 밝아짐
			var pre := clampf((t - (delay - 0.12)) / 0.12, 0.0, 1.0)
			if pre > 0.0:
				pd.line2(la, lb, Color(WHITE, 0.9 * pre), Color(WHITE, 0.9 * pre), 1.0)
		else:
			var k := (t - delay) / 0.42
			var grow := 1.0 - pow(1.0 - minf(k / 0.18, 1.0), 3.0)
			var fade := 1.0 - smoothstep(0.25, 1.0, k)
			var dv := lb - la
			var ext := dv.normalized() * 10.0 * grow
			EKenseiFx.blade_light(pd, la - ext, lb + ext, w * (0.5 + 0.9 * grow) * fade + 0.5, fade)
			# 잘린 공기: 위아래로 벌어지는 먹빛 틈
			var n := dv.normalized().orthogonal() * (2.0 + 5.0 * grow)
			pd.line2(la + n, lb + n, Color(RED, 0.0), Color(RED, 0.5 * fade), 1.0)
			pd.line2(la - n, lb - n, Color(RED, 0.5 * fade), Color(RED, 0.0), 1.0)


## 초승달 칼자국: 가운데 c(전역) 기준, 오른쪽을 보는 각도 a0 → a1 (dir이 -1이면 뒤집힘), 반지름 r, 굵기 w
class Arc extends PVfx.Base:
	var r := 30.0
	var a0 := -1.2
	var a1 := 1.0
	var w := 7.0
	var dir := 1
	var squash := 0.7 ## 세로 납작함

	func _ready() -> void:
		life = 0.22
		z_index = 6

	func _paint() -> void:
		var x := k()
		var grow := minf(x / 0.25, 1.0)
		var al := 1.0 - smoothstep(0.35, 1.0, x)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(dir), squash))
		var head := lerpf(a0, a1, 1.0 - pow(1.0 - grow, 3.0))
		EVfx.band(pd, r + 2.0, a0, head, w * 1.8, Color(RED, 0.0), Color(RED, 0.45 * al), 16)
		EVfx.band(pd, r, a0, head, w, Color(RED_HOT, 0.2 * al), Color(WHITE, al), 18)
		EVfx.band(pd, r - w * 0.3, a0 + (head - a0) * 0.3, head, w * 0.25, Color(WHITE, 0.0), Color(WHITE, al), 12)
		pd.draw_set_transform(Vector2.ZERO)


## 이미 베인 표시: 에스카 몸에 비스듬한 흰 선이 걸려 따라다니다 터짐 (피해는 검성이 준다)
class CutMark extends PVfx.Base:
	var target: Node2D
	var ang := -0.25

	func _ready() -> void:
		z_index = 7

	func _tick(_delta: float) -> void:
		if is_instance_valid(target):
			global_position = (target as EEska).center() if target is EEska else target.global_position

	func _paint() -> void:
		var x := k()
		var al := 0.6 + 0.4 * sin(t * 50.0)
		var len := 12.0 + 4.0 * x
		var d := Vector2.from_angle(ang) * len
		EKenseiFx.blade_light(pd, -d, d, 1.6 + 1.5 * x, al)


## 비검: 땅을 타고 미끄러지는 초승달 참격파 (높이 HEIGHT — 점프로 넘는다), 벽에 닿으면 흩어짐
class Wave extends KenseiHazard:
	const HEIGHT := 20.0
	const HALF_W := 9.0
	var dir := 1
	var speed := 250.0
	var x_min := 0.0
	var x_max := 99999.0
	var dmg := 1
	var _hit := false
	var _trail_t := 0.0

	func _ready() -> void:
		super._ready()
		life = 6.0
		z_index = 6
		material = Fx.add_material

	func _tick(delta: float) -> void:
		position.x += float(dir) * speed * delta
		_trail_t -= delta
		if _trail_t <= 0.0:
			_trail_t = 0.03
			PParticles.get_layer(false).spawn(position + Vector2(-dir * 6.0, -1.0), Vector2(-dir * randf_range(10, 40), randf_range(-40, -10)), Vector2(0, 120),
				randf_range(0.2, 0.4), randf_range(1.5, 3.0), Color("#3a3234"), Color("#120e10"), 0, 1.0)
		if not _hit:
			var r := Rect2(position + Vector2(-HALF_W, -HEIGHT), Vector2(HALF_W * 2.0, HEIGHT))
			if hurt_eska(r, dmg, position + Vector2(-dir * 20.0, -8.0)):
				_hit = true
		if position.x < x_min or position.x > x_max:
			EKenseiFx.sparks(position + Vector2(0, -8), 10, Vector2(-dir, -0.6), 140.0, 50.0)
			queue_free()

	func _paint() -> void:
		var flick := 0.85 + 0.15 * sin(t * 37.0)
		# 앞으로 볼록한 세로 초승달 ")" — 땅에 붙어 미끄러짐 + 뒤로 끌리는 속도선
		pd.draw_set_transform(Vector2(-12.0 * float(dir), -HEIGHT * 0.5), 0.0, Vector2(float(dir), 0.86))
		EVfx.band(pd, 15.0, -1.05, 1.05, 9.0, Color(RED, 0.35 * flick), Color(RED, 0.35 * flick), 14)
		EVfx.band(pd, 13.5, -1.0, 1.0, 6.0, Color(RED_HOT, 0.9 * flick), Color(RED_HOT, 0.9 * flick), 14)
		EVfx.band(pd, 12.5, -0.95, 0.95, 3.0, Color(WHITE, flick), Color(WHITE, flick), 14)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(dir), 1.0))
		for i in 4:
			var y := -2.0 - float(i) * 5.0
			var l := 14.0 + float(i % 2) * 10.0 + sin(t * 20.0 + float(i)) * 3.0
			pd.line2(Vector2(-2, y), Vector2(-2 - l, y + 0.5), Color(WHITE, 0.55 * flick), Color(RED, 0.0), 1.2, 0.4)
		pd.draw_set_transform(Vector2.ZERO)


## 천검: 땅에 예고선(warn초) → 하늘에서 칼빛 한 줄이 내리꽂힘(피해) → 잔광
class RainBlade extends KenseiHazard:
	const HALF_W := 6.0
	var warn := 0.75
	var top := -340.0 ## 칼빛이 시작하는 높이 (이 노드 기준 — 노드는 바닥에 놓임)
	var dmg := 1
	var _fell := false

	func _ready() -> void:
		super._ready()
		life = warn + 0.45
		z_index = 6
		material = Fx.add_material

	func _tick(_delta: float) -> void:
		if not _fell and t >= warn:
			_fell = true
			Sfx.play_pitch(&"kb_rain", randf_range(0.92, 1.1), -6.0)
			Fx.shake(0.25, 0.08)
			EKenseiFx.sparks(position + Vector2(0, -2), 6, Vector2.UP, 150.0, 70.0)
		if _fell and t < warn + 0.1:
			hurt_eska(Rect2(position + Vector2(-HALF_W, top), Vector2(HALF_W * 2.0, -top)), dmg, position + Vector2(0, -40))

	func _paint() -> void:
		if t < warn:
			var f := t / warn
			var blink := 0.65 + 0.35 * sin(t * (16.0 + 34.0 * f))
			# 땅에서 솟는 붉은 기둥(위로 옅어짐) + 하늘에서 내려오는 흰 실선 — 떨어질 자리
			var colh := 70.0 + 70.0 * f
			pd.convex_colors(PackedVector2Array([Vector2(-HALF_W, 0), Vector2(HALF_W, 0), Vector2(HALF_W, -colh), Vector2(-HALF_W, -colh)]),
				PackedColorArray([Color(RED, 0.32 * blink), Color(RED, 0.32 * blink), Color(RED, 0.0), Color(RED, 0.0)]))
			pd.draw_line(Vector2(-HALF_W, 0), Vector2(-HALF_W, -colh * 0.6), Color(RED_HOT, 0.5 * blink), 1.0)
			pd.draw_line(Vector2(HALF_W, 0), Vector2(HALF_W, -colh * 0.6), Color(RED_HOT, 0.5 * blink), 1.0)
			pd.line2(Vector2(0, top), Vector2(0, 0), Color(WHITE, 0.0), Color(WHITE, (0.25 + 0.6 * f) * blink), 1.0, 1.0)
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
			pd.glow(Vector2.ZERO, 12.0 + 6.0 * f, Color(RED_HOT, 0.6 * blink), 0.0)
			pd.draw_set_transform(Vector2.ZERO)
			pd.draw_rect(Rect2(-HALF_W - 2.0, -1.5, HALF_W * 2.0 + 4.0, 1.5), Color(WHITE, 0.7 * blink * f))
			return
		var k := (t - warn) / 0.45
		var drop := minf(k / 0.12, 1.0) # 위에서 땅까지 내리꽂힘
		var fade := 1.0 - smoothstep(0.2, 1.0, k)
		var y1 := lerpf(top, 0.0, drop)
		EKenseiFx.blade_light(pd, Vector2(0, top), Vector2(0, y1 + 4.0), HALF_W * 1.2 * fade + 1.0, fade)
		if drop >= 1.0:
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
			pd.glow(Vector2.ZERO, 24.0 * fade + 6.0, Color(RED_HOT, 0.6 * fade), 0.0)
			pd.glow(Vector2.ZERO, 10.0, Color(WHITE, 0.8 * fade), 0.0)
			pd.draw_set_transform(Vector2.ZERO)


## 낙화 착지: 흰 고리 + 땅을 달리는 칼빛 물결 + 갈라진 금 (가산)
class Impact extends PVfx.Base:
	var reach := 76.0
	var _cracks: Array = []

	func _ready() -> void:
		life = 0.55
		z_index = 6
		for s in [-1.0, 1.0]:
			for i in 2:
				var pts := PackedVector2Array([Vector2.ZERO])
				var p := Vector2.ZERO
				for j in 5:
					p += Vector2(s * randf_range(9, 18), randf_range(-2, 2))
					pts.append(p)
				_cracks.append(pts)

	func _paint() -> void:
		var x := k()
		var go := 1.0 - pow(1.0 - minf(x / 0.3, 1.0), 2.0)
		var a := 1.0 - smoothstep(0.25, 1.0, x)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		pd.draw_arc(Vector2.ZERO, reach * go, 0.0, TAU, 36, Color(WHITE, 0.8 * a), 3.0 * a + 0.5)
		pd.glow(Vector2.ZERO, reach * 0.7, Color(RED, 0.3 * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
		for s in [-1.0, 1.0]:
			var hx: float = s * reach * go
			var hh := 14.0 * a
			pd.draw_colored_polygon(PackedVector2Array([Vector2(hx - s * 20.0, 0), Vector2(hx - s * 4.0, -hh), Vector2(hx + s * 3.0, 0)]), Color(RED_HOT, 0.8 * a))
			pd.draw_colored_polygon(PackedVector2Array([Vector2(hx - s * 13.0, 0), Vector2(hx - s * 4.0, -hh * 0.6), Vector2(hx, 0)]), Color(WHITE, 0.9 * a))
		for c: PackedVector2Array in _cracks:
			var n := int(ceil(float(c.size()) * go))
			if n >= 2:
				pd.draw_polyline(c.slice(0, n), Color(WHITE, 0.7 * a), 1.0)
		if x < 0.2:
			var f := 1.0 - x / 0.2
			pd.line2(Vector2(0, 0), Vector2(0, -60.0 * f), Color(WHITE, f), Color(WHITE, 0.0), 4.0 * f)


## 2막에 내던진 칼집: 돌며 날아가 땅에 비스듬히 꽂힌다 (붉은 끈이 바람에 흔들림) — 쓰러짐 연출이 거둔다
class Sheath extends PDraw.Canvas:
	const LEN := 30.0
	var vel := Vector2.ZERO
	var spin := 14.0
	var ang := 0.0
	var floor_y := 300.0
	var stuck := false
	var fade := 1.0
	var _t := 0.0
	var _fading := false

	func _ready() -> void:
		z_index = 1

	func vanish() -> void:
		_fading = true

	func _process(delta: float) -> void:
		_t += delta
		if _fading:
			fade -= delta * 0.8
			if fade <= 0.0:
				queue_free()
				return
		if not stuck:
			vel.y += 900.0 * delta
			position += vel * delta
			ang += spin * delta
			var tip := position + Vector2.from_angle(ang) * LEN * 0.5
			if tip.y >= floor_y + 3.0 and vel.y > 0.0:
				stuck = true
				ang = deg_to_rad(68.0 if vel.x > 0.0 else 112.0) # 끝이 땅에 박힘
				position = Vector2(position.x, floor_y + 3.0) - Vector2.from_angle(ang) * LEN * 0.5
				EVfx.land_dust(Vector2(position.x, floor_y))
				Sfx.play_pitch(&"kb_sheath", 0.6, -6.0)
		queue_redraw()

	func _paint() -> void:
		var d := Vector2.from_angle(ang)
		var a := -d * LEN * 0.5
		var b := d * LEN * 0.5
		var n := d.orthogonal()
		pd.draw_colored_polygon(PackedVector2Array([a + n * 1.8, b + n * 1.3, b - n * 1.3, a - n * 1.8]), Color(INK, fade))
		pd.draw_line(a + n * 0.8, b + n * 0.6, Color("#3a3036", fade), 0.7)
		pd.draw_line(a, a + d * 2.0, Color(BONE, 0.8 * fade), 3.2) # 칼집 입구 (뼈빛 고리)
		# 붉은 끈: 바람에 날림
		var p := a + d * 5.0
		var sway := sin(_t * 3.0) * 0.5 + 0.3
		var w := EKenseiFx.wind.x / 46.0
		var pts := PackedVector2Array([p])
		for i in 4:
			p += Vector2(w * 1.6 + sway, 2.2)
			pts.append(p)
		pd.draw_polyline(pts, Color(RED, fade), 1.0)


## 바람에 날리는 꽃잎·잎 (먹·붉은빛·뼈흰): 장면에 한 노드. 돌며 흔들리며 바람 쪽으로 흐른다
class Drift extends PDraw.Canvas:
	static var _inst: Drift
	var pos := PackedVector2Array()
	var vel := PackedVector2Array()
	var age := PackedFloat32Array()
	var life := PackedFloat32Array()
	var spin := PackedFloat32Array()
	var kind := PackedInt32Array()
	const MAX := 240

	## 지금 장면의 꽃잎 층 (장면이 만들어 둔 것만 — 없으면 null)
	static func get_layer() -> Drift:
		return _inst if is_instance_valid(_inst) and _inst.is_inside_tree() else null

	func _ready() -> void:
		_inst = self

	func _exit_tree() -> void:
		if _inst == self:
			_inst = null

	func spawn(p: Vector2, v: Vector2, l: float, k := -1) -> void:
		if pos.size() >= MAX:
			return
		pos.append(p)
		vel.append(v)
		age.append(0.0)
		life.append(l)
		spin.append(randf() * TAU)
		kind.append(k if k >= 0 else (0 if randf() < 0.5 else (1 if randf() < 0.6 else 2)))

	func _process(delta: float) -> void:
		var w := EKenseiFx.wind
		var n := pos.size()
		var keep := 0
		for i in n:
			var a := age[i] + delta
			if a >= life[i]:
				continue
			var v := vel[i]
			v = v.lerp(Vector2(w.x * (0.9 + 0.3 * sin(a * 3.0 + float(i))), 18.0 + sin(a * 5.0 + float(i)) * 22.0), 1.0 - exp(-delta * 1.6))
			pos[keep] = pos[i] + v * delta
			vel[keep] = v
			age[keep] = a
			life[keep] = life[i]
			spin[keep] = spin[i] + delta * (4.0 + float(i % 5))
			kind[keep] = kind[i]
			keep += 1
		pos.resize(keep)
		vel.resize(keep)
		age.resize(keep)
		life.resize(keep)
		spin.resize(keep)
		kind.resize(keep)
		queue_redraw()

	func _paint() -> void:
		for i in pos.size():
			var f := age[i] / life[i]
			var al := minf(f / 0.1, 1.0) * (1.0 - smoothstep(0.7, 1.0, f))
			var c: Color
			match kind[i]:
				0: c = Color("#1a1416", al)
				1: c = Color(RED, 0.85 * al)
				_: c = Color(BONE, 0.7 * al)
			var s := sin(spin[i])
			var d := Vector2(cos(spin[i] * 0.7), 0.0) * 2.2
			var up := Vector2(0, 1.0 + absf(s) * 0.6)
			var p := pos[i]
			pd.draw_colored_polygon(PackedVector2Array([p - d, p - up, p + d, p + up * 0.6]), c)
