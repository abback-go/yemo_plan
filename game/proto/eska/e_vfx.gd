class_name EVfx
extends RefCounted
## 에스카 이펙트 v2 (전부 코드 그림, 수명이 끝나면 스스로 사라짐).
## 색 언어(다크 참격, 스컬 '다크팔라딘' 참고): 검보라 테두리 → 짙은 자두빛 → 보라·마젠타 몸통(결 따라 가는 줄무늬) → 분홍빛 흰 앞날.
## 한두 프레임 꽉 찼다가 꼬리부터 걷히며 가늘어지고 옅어진다. 맞은 자리엔 빨강·흰 바늘 X자, 큰 타격엔 어둠 폭발.
## 파랑은 쓰지 않는다. 참격은 보통 섞기(검은 테두리가 보이게), 빛·불티만 가산 섞기.
## 참격 레퍼런스 = 던전슬래셔 기본공격(캐릭터보다 몇 배 큰 초승달, 들쭉날쭉한 가장자리, 얇은 궤적선, 네모 픽셀 불티, 맞은 자리의 흰 금),
## 천열 = 앞으로 크고 긴 다크 참격 열 번, 단공 = 머리 위를 납작한 다크 회오리가 연달아 휘감음 + 어둠 폭발,
## 종언참 = 폭풍 속 거대 검(세상이 어두워지고 사방 참격선 → 하늘의 칼날이 화면을 세로로 가름).
## 성능: 이펙트 하나 = 노드 하나 = 그리기 호출 하나(PDraw 묶음). 입자는 PParticles 한 노드, 유리 파편은 Shards 한 노드.

const WHITE := Color(1, 1, 1)
const PALE := Color("#d9ccff")
const VIOLET := Color("#a98bff")
const DEEP := Color("#5b3fc0")
const CLEAR := Color(0.66, 0.55, 1.0, 0.0)
const INK := Color("#14081f") ## 참격 바깥 검보라 테두리
const PLUM := Color("#3b1268")
const BODY := Color("#9b3cff")
const MAGENTA := Color("#e352ff")
const STREAK := Color("#f293ff") ## 몸통 안 결무늬
const EDGE := Color("#ffe4fb") ## 앞날 분홍빛 흰색
const HIT_RED := Color("#ff2f58")


static func add(n: Node2D, pos: Vector2, additive := false) -> Node2D:
	return PVfx.add(n, pos, additive)


## 호 띠: 바깥 반지름 r, 가장 굵은 곳 w, a0(꼬리) → a1(머리), 꼬리색 → 머리색. jag = 바깥 가장자리 들쭉날쭉(찢긴 공간)
static func band(pd: PDraw, r: float, a0: float, a1: float, w: float, c_tail: Color, c_head: Color, seg := 22, jag := 0.0, jseed := 0) -> void:
	if absf(a1 - a0) < 0.03 or w < 0.3:
		return
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in seg + 1:
		var f := float(i) / float(seg)
		var a := lerpf(a0, a1, f)
		var thick := w * sin(pow(f, 0.72) * PI)
		var jr := 0.0
		if jag > 0.0 and i > 0 and i < seg:
			jr = (fposmod(sin(float(i * 37 + jseed) * 12.9898) * 43758.5453, 1.0) - 0.35) * jag * (thick / w)
		var d := Vector2(cos(a), sin(a))
		outer.append(d * (r + jr))
		inner.append(d * (r - thick))
	pd.strip_grad(outer, inner, c_tail, c_head)


## 휘어진 칼날 위의 한 점: p0에서 dir로 len만큼 나아가며 옆(dir의 수직)으로 bend×len×f² 만큼 휜다
static func curve_point(p0: Vector2, dir: Vector2, len: float, bend: float, f: float) -> Vector2:
	return p0 + dir * len * f + dir.orthogonal() * bend * len * f * f


## 휘어진 칼날(초승달 깃): 양 끝이 뾰족하고 가운데가 굵다. f0~f1 구간만 그린다(자라나기·걷히기). 뿌리색 → 끝색
static func curve_blade(pd: PDraw, p0: Vector2, dir: Vector2, len: float, bend: float, w: float, c_tail: Color, c_head: Color, f0 := 0.0, f1 := 1.0, seg := 12) -> void:
	if f1 - f0 < 0.02 or w < 0.3:
		return
	var nrm := dir.orthogonal()
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	for i in seg + 1:
		var f := lerpf(f0, f1, float(i) / float(seg))
		var c := p0 + dir * len * f + nrm * bend * len * f * f
		var tan := (dir + nrm * bend * 2.0 * f).normalized()
		var n := tan.orthogonal()
		var ww := w * pow(sin(f * PI), 0.75) * 0.5
		l.append(c + n * ww)
		r.append(c - n * ww)
	pd.strip_grad(l, r, c_tail, c_head)


## 휘어진 칼날 한 자루 (다크 질감: 검보라 테두리 → 자두빛 → 보라·마젠타 → 분홍빛 흰 심) — 종언참·봉공 X자가 같이 쓴다
static func feather(pd: PDraw, p0: Vector2, dir: Vector2, len: float, bend: float, w: float, a: float, f0 := 0.0, f1 := 1.0, seg := 12) -> void:
	curve_blade(pd, p0, dir, len, bend, w * 3.2, Color(MAGENTA, 0.0), Color(MAGENTA, 0.15 * a), f0, f1, maxi(seg - 4, 6))
	curve_blade(pd, p0, dir, len, bend, w * 2.1, Color(INK, 0.0), Color(INK, 0.9 * a), f0, f1, seg)
	curve_blade(pd, p0, dir, len, bend, w, Color(PLUM, 0.3 * a), Color(MAGENTA, a), f0, f1, seg)
	curve_blade(pd, p0, dir, len, bend, w * 0.35, Color(STREAK, 0.0), Color(EDGE, a), f0, f1, seg)


## 다크 참격 띠 (호): 바깥 반지름 r, 굵기 w, a0(꼬리) → a1(머리). tail_a = 꼬리 쪽 진하기(0이면 투명하게 사라짐)
## 겹: 검보라 테두리(바깥으로 삐져나옴) · 자두빛 · 보라→마젠타 몸통 · 결무늬 3줄 · 분홍빛 흰 앞날
static func dark_band(pd: PDraw, r: float, a0: float, a1: float, w: float, a: float, jseed := 0, seg := 26, tail_a := 0.0, lite := false) -> void:
	if a <= 0.01 or absf(a1 - a0) < 0.03:
		return
	var span := a1 - a0
	# 큰 호도 각지지 않게 호 길이(약 9px)마다 한 마디
	var sg := clampi(maxi(seg, int(absf(span) * r / 9.0)), 6, 48)
	if not lite:
		band(pd, r + w * 0.45, a0 + span * 0.1, a1, w * 2.3, Color(MAGENTA, 0.0), Color(MAGENTA, 0.16 * a), maxi(sg - 8, 6)) # 번짐
	band(pd, r + w * 0.18, a0, a1, w * 1.42, Color(INK, 0.92 * a * tail_a), Color(INK, 0.92 * a), sg, w * 0.16, jseed)
	band(pd, r + w * 0.06, a0 + span * 0.03, a1, w * 1.14, Color(PLUM, a * tail_a), Color(PLUM, a), sg, w * 0.08, jseed + 5)
	band(pd, r, a0 + span * 0.07, a1, w, Color(BODY, a * tail_a), Color(MAGENTA, a), sg)
	for k in (1 if lite else 3):
		var fk := float(k)
		band(pd, r - w * (0.2 + 0.19 * fk), a0 + span * (0.16 + 0.12 * fk), a1 - span * 0.03 * fk, w * (0.1 - 0.018 * fk),
			Color(STREAK, 0.4 * a * tail_a), Color(STREAK, (0.75 - 0.15 * fk) * a), maxi(sg - 6, 6))
	band(pd, r + 0.5, a0 + span * 0.2, a1, w * 0.3, Color(EDGE, a * tail_a), Color(EDGE, a), maxi(sg - 4, 6))


## 보랏빛 조각 + 연기 (보통 섞기 — 부서진 참격이 흩어지는 것)
static func dark_bits(pos: Vector2, n: int, speed: float, dir := Vector2.ZERO, spread := 180.0, life := 0.35, smoke := 0) -> void:
	var pp := PParticles.get_layer(false)
	var base := dir.angle() if dir != Vector2.ZERO else 0.0
	for i in n:
		var an := base + deg_to_rad(randf_range(-spread, spread))
		var v := Vector2(cos(an), sin(an)) * randf_range(speed * 0.3, speed)
		var col := MAGENTA if randf() < 0.6 else STREAK
		pp.spawn(pos, v, Vector2(0, 60), life * randf_range(0.6, 1.0), randf_range(1.6, 3.2), col, PLUM, 0, 3.5)
	for i in smoke:
		var v := Vector2(randf_range(-30, 30), randf_range(-36, -6)) + dir * randf_range(10, 40)
		pp.spawn(pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)), v, Vector2.ZERO, randf_range(0.35, 0.6), randf_range(4.0, 7.0),
			Color(PLUM, 0.55), Color(INK, 0.0), 2, 3.0)


## 어둠 폭발 (큰 타격·마무리): 무늬 있는 검보라 구체가 순간 부풀었다 연기로 흩어진다
static func dark_burst(pos: Vector2, rad: float) -> void:
	var b := DarkBurst.new()
	b.rad = rad
	add(b, pos, false)


## 네모 픽셀 불티 (흰색 → 보라로 사라짐)
static func pixels(pos: Vector2, n: int, speed: float, dir := Vector2.ZERO, spread := 180.0, life := 0.3, grav := Vector2.ZERO) -> void:
	var pp := PParticles.get_layer(true)
	var base := dir.angle() if dir != Vector2.ZERO else 0.0
	for i in n:
		var a := base + deg_to_rad(randf_range(-spread, spread))
		var sp := randf_range(speed * 0.35, speed)
		pp.spawn(pos, Vector2(cos(a), sin(a)) * sp, grav, life * randf_range(0.6, 1.0), randf_range(1.0, 2.2), WHITE, VIOLET, 0, 3.0)


## 유리 파편 (돌며 떨어지는 작은 삼각형)
static func shards(pos: Vector2, n: int, speed: float, area := Vector2.ZERO, up := 60.0) -> void:
	var s := Shards.get_layer()
	for i in n:
		var p := pos + Vector2(randf_range(-area.x, area.x), randf_range(-area.y, area.y))
		var dir := (p - pos).normalized() if area != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
		if dir == Vector2.ZERO:
			dir = Vector2.from_angle(randf() * TAU)
		s.spawn(p, dir * randf_range(speed * 0.4, speed) + Vector2(0, -up), randf_range(1.6, 3.4))


## 맞은 자리: 십자 섬광 + 흰 금 + 고리 + 파편 (모든 타격 섬광은 Impacts 한 노드가 그린다 — 다단히트 스킬에서 노드가 수십 개 생기지 않게)
static func hit_crack(pos: Vector2, heavy: bool, dir: float) -> void:
	var d := dir if dir != 0.0 else 1.0
	Impacts.get_layer().spawn(pos, heavy)
	pixels(pos, 6 if heavy else 3, 210.0 if heavy else 140.0, Vector2(d, -0.3), 70.0, 0.28, Vector2(0, 300))
	dark_bits(pos, 8 if heavy else 4, 190.0 if heavy else 120.0, Vector2(d, -0.2), 80.0, 0.34, 2 if heavy else 0)
	if heavy:
		dark_burst(pos, 26.0)
		shards(pos, 6, 150.0, Vector2(3, 3), 80.0)


static func land_dust(pos: Vector2) -> void:
	PVfx.dust(pos, 5, 1.4, 12.0)


## 잔상: 에스카의 마지막 그림을 그대로 보랏빛으로
static func afterimage(art: EArt, life := 0.25, tint := VIOLET, offset := Vector2.ZERO, strength := 1.0) -> void:
	if art.snap_i.is_empty():
		return
	var a := Afterimage.new()
	a.v = art.snap_v
	a.idx = art.snap_i
	a.life = life
	a.tint = tint
	a.strength = strength
	a.z_index = -6 # 이펙트 층(5) 기준 → 캐릭터 뒤
	a.material = Fx.add_material
	Fx.effect_parent().add_child(a)
	a.global_transform = art.snap_xf.translated(offset)


class Afterimage extends Node2D:
	var v := PackedVector2Array()
	var idx := PackedInt32Array()
	var life := 0.25
	var tint := VIOLET
	var strength := 1.0 ## 진하기 (1 = 기본)
	var t := 0.0
	var _cols := PackedColorArray()
	var stretch_dir := 0 ## 0이 아니면: 이 방향으로 가늘고 길게 늘어나며 빨려 들어감 (순간이동 출발)
	var stretch_c := Vector2.ZERO ## 늘어나는 축의 중심 (전역)
	var base_xf := Transform2D.IDENTITY

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		if stretch_dir != 0:
			var e := 1.0 - pow(1.0 - t / life, 2.0)
			var sx := lerpf(1.0, 3.2, e)
			var sy := lerpf(1.0, 0.12, e)
			var shift := float(stretch_dir) * 26.0 * e
			var c := stretch_c
			global_transform = Transform2D(Vector2(sx, 0), Vector2(0, sy), Vector2(c.x + shift - c.x * sx, c.y - c.y * sy)) * base_xf
		queue_redraw()

	func _draw() -> void:
		var a := (1.0 - t / life)
		_cols.resize(v.size())
		_cols.fill(Color(tint, 0.5 * strength * a * a))
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, v, _cols)


## 돌며 떨어지는 유리 파편 — 장면에 한 노드
class Shards extends PDraw.Canvas:
	static var _inst: Shards
	var pos := PackedVector2Array()
	var vel := PackedVector2Array()
	var rot := PackedFloat32Array()
	var rv := PackedFloat32Array()
	var sz := PackedFloat32Array()
	var age := PackedFloat32Array()
	var life := PackedFloat32Array()

	static func get_layer() -> Shards:
		if is_instance_valid(_inst) and _inst.is_inside_tree():
			return _inst
		_inst = Shards.new()
		_inst.z_index = 3
		_inst.material = Fx.add_material
		Fx.effect_parent().add_child(_inst)
		return _inst

	func spawn(p: Vector2, v: Vector2, s: float) -> void:
		if pos.size() > 260:
			return
		pos.append(p)
		vel.append(v)
		rot.append(randf() * TAU)
		rv.append(randf_range(-18.0, 18.0))
		sz.append(s)
		age.append(0.0)
		life.append(randf_range(0.45, 0.8))

	func _process(delta: float) -> void:
		var i := 0
		while i < pos.size():
			age[i] += delta
			if age[i] >= life[i]:
				pos.remove_at(i)
				vel.remove_at(i)
				rot.remove_at(i)
				rv.remove_at(i)
				sz.remove_at(i)
				age.remove_at(i)
				life.remove_at(i)
				continue
			vel[i] += Vector2(0, 520) * delta
			vel[i] *= 1.0 - 1.5 * delta
			pos[i] += vel[i] * delta
			rot[i] += rv[i] * delta
			i += 1
		if not pos.is_empty() or not pd.is_empty():
			queue_redraw()

	func _paint() -> void:
		for i in pos.size():
			var f := 1.0 - age[i] / life[i]
			var d := Vector2.from_angle(rot[i]) * sz[i]
			var n := d.orthogonal() * 0.45
			var flick := 0.6 + 0.4 * absf(sin(rot[i] * 2.0)) # 돌면서 빛을 받았다 잃었다
			pd.draw_colored_polygon(PackedVector2Array([pos[i] + d, pos[i] + n - d * 0.6, pos[i] - n - d * 0.3]), Color(PALE.lerp(WHITE, flick), f * flick))


## 어둠 폭발: 검보라 구체가 순간 부풀며(무늬 고리·십자) 터지고, 테두리가 흩어지며 연기로 사라진다 — 보통 섞기
class DarkBurst extends PVfx.Base:
	var rad := 40.0
	var _spin := 0.0

	func _ready() -> void:
		life = 0.42 + rad * 0.003
		z_index = 6
		_spin = randf() * TAU
		EVfx.dark_bits(position, int(6 + rad * 0.25), rad * 4.5, Vector2.ZERO, 180.0, 0.4, int(2 + rad * 0.06))

	func _paint() -> void:
		var grow := 1.0 - pow(1.0 - clampf(t / 0.07, 0.0, 1.0), 3.0)
		var fade := 1.0 - clampf((t - 0.09) / (life - 0.09), 0.0, 1.0)
		if fade <= 0.0:
			return
		var R := rad * (0.35 + 0.65 * grow) * (1.0 + 0.18 * (1.0 - fade))
		var a := fade * fade
		pd.glow(Vector2.ZERO, R * 1.7, Color(MAGENTA, 0.3 * a), 0.0)
		pd.draw_circle(Vector2.ZERO, R * 1.04, Color(INK, 0.9 * a))
		pd.draw_circle(Vector2.ZERO, R * 0.86, Color(PLUM, 0.95 * a))
		pd.glow(Vector2.ZERO, R * 0.8, Color(BODY, 0.6 * a), 0.0)
		# 무늬: 도는 고리 조각 + 십자
		var sp := _spin + t * 3.0
		for i in 6:
			var s0 := sp + float(i) * TAU / 6.0
			pd.draw_arc(Vector2.ZERO, R * 0.6, s0, s0 + 0.62, 6, Color(STREAK, 0.8 * a), maxf(R * 0.05, 1.0))
		for q in 2:
			var d := Vector2.from_angle(sp * 0.5 + float(q) * PI / 2.0 + PI / 4.0) * R * 0.78
			pd.draw_line(-d, d, Color(MAGENTA, 0.85 * a), maxf(R * 0.06, 1.0))
		pd.draw_arc(Vector2.ZERO, R * 0.95, 0.0, TAU, 32, Color(MAGENTA, a), maxf(R * 0.07, 1.4))
		pd.draw_arc(Vector2.ZERO, R * 0.99, 0.0, TAU, 32, Color(EDGE, 0.7 * a), 1.0)
		# 터지는 순간의 분홍빛 흰 심
		if t < 0.1:
			var cf := 1.0 - t / 0.1
			pd.glow(Vector2.ZERO, R * 0.6, Color(EDGE, 0.9 * cf), 0.0)


## 맞은 자리: 가늘고 긴 빨강·흰 바늘이 X자로 교차 + 작은 섬광 + 마젠타 고리 — 장면에 한 노드, 여러 타격을 함께 그린다 (가산)
class Impacts extends PDraw.Canvas:
	static var _inst: Impacts
	var items: Array = [] ## [위치, 나이, 수명, 큼, 바늘 각도들]

	static func get_layer() -> Impacts:
		if is_instance_valid(_inst) and _inst.is_inside_tree():
			return _inst
		_inst = Impacts.new()
		_inst.z_index = 7
		_inst.material = Fx.add_material
		Fx.effect_parent().add_child(_inst)
		return _inst

	func spawn(pos: Vector2, heavy: bool) -> void:
		if items.size() > 40:
			items.pop_front()
		var base := randf_range(0.5, 1.1) * (-1.0 if randf() < 0.5 else 1.0)
		var angs := PackedFloat32Array([base, base + randf_range(1.2, 1.9)])
		if heavy:
			angs.append(base + randf_range(0.5, 0.9))
		items.append([pos, 0.0, 0.24 if heavy else 0.16, heavy, angs])

	func _process(delta: float) -> void:
		var i := 0
		while i < items.size():
			items[i][1] += delta
			if float(items[i][1]) >= float(items[i][2]):
				items.remove_at(i)
				continue
			i += 1
		if not items.is_empty() or not pd.is_empty():
			queue_redraw()

	func _paint() -> void:
		for it: Array in items:
			var pos: Vector2 = it[0]
			var heavy: bool = it[3]
			var k := float(it[1]) / float(it[2])
			var f := 1.0 - k
			var reach := (46.0 if heavy else 30.0) * (1.0 - pow(1.0 - minf(k * 4.0, 1.0), 2.0)) # 순식간에 뻗는다
			pd.glow(pos, (16.0 if heavy else 10.0) * (0.6 + 0.4 * f), Color(EDGE, 0.7 * f), 0.0)
			for an: float in it[4]:
				var d := Vector2.from_angle(an)
				var n := d.orthogonal()
				var hw := (2.4 if heavy else 1.7) * f
				pd.draw_colored_polygon(PackedVector2Array([pos - d * reach, pos + n * hw, pos + d * reach, pos - n * hw]), Color(HIT_RED, 0.95 * f))
				pd.draw_colored_polygon(PackedVector2Array([pos - d * reach * 0.8, pos + n * hw * 0.35, pos + d * reach * 0.8, pos - n * hw * 0.35]), Color(WHITE, f))
			pd.draw_arc(pos, lerpf(4.0, 24.0 if heavy else 14.0, k), 0.0, TAU, 20, Color(MAGENTA, 0.85 * f), 1.6 if heavy else 1.2)
