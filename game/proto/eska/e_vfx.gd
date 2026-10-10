class_name EVfx
extends RefCounted
## 에스카 이펙트 v2 (전부 코드 그림, 수명이 끝나면 스스로 사라짐).
## 색 언어(다크 참격, 스컬 '다크팔라딘' 참고): 검보라 테두리 → 짙은 자두빛 → 보라·마젠타 몸통(결 따라 가는 줄무늬) → 분홍빛 흰 앞날.
## 한두 프레임 꽉 찼다가 조각으로 부서지며 보랏빛 조각·연기로 흩어진다. 맞은 자리엔 빨강·흰 바늘 X자, 큰 타격엔 어둠 폭발.
## 파랑은 쓰지 않는다. 참격은 보통 섞기(검은 테두리가 보이게), 빛·불티만 가산 섞기.
## 참격 레퍼런스 = 던전슬래셔 기본공격(캐릭터보다 몇 배 큰 초승달, 들쭉날쭉한 가장자리, 얇은 궤적선, 네모 픽셀 불티, 맞은 자리의 흰 금),
## 천열 = 백목련(초승달 참격 여러 장이 부채처럼 흩어져 날아감), 단공 = 단혼파(공간 한 구역을 초승달 참격이 위로 베어 올림),
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
	var sg := maxi(seg, 6)
	if not lite:
		band(pd, r + w * 0.45, a0 + span * 0.1, a1, w * 2.3, Color(MAGENTA, 0.0), Color(MAGENTA, 0.16 * a), maxi(sg - 8, 6)) # 번짐
	band(pd, r + w * 0.18, a0, a1, w * 1.42, Color(INK, 0.92 * a * tail_a), Color(INK, 0.92 * a), sg, w * 0.55, jseed)
	band(pd, r + w * 0.06, a0 + span * 0.03, a1, w * 1.14, Color(PLUM, a * tail_a), Color(PLUM, a), sg, w * 0.35, jseed + 5)
	band(pd, r, a0 + span * 0.07, a1, w, Color(BODY, a * tail_a), Color(MAGENTA, a), sg, w * 0.2, jseed + 9)
	for k in (1 if lite else 3):
		var fk := float(k)
		band(pd, r - w * (0.2 + 0.19 * fk), a0 + span * (0.16 + 0.12 * fk), a1 - span * 0.03 * fk, w * (0.1 - 0.018 * fk),
			Color(STREAK, 0.4 * a * tail_a), Color(STREAK, (0.75 - 0.15 * fk) * a), maxi(sg - 6, 6))
	band(pd, r + 0.5, a0 + span * 0.2, a1, w * 0.3, Color(EDGE, a * tail_a), Color(EDGE, a), maxi(sg - 4, 6))


## 부서지는 다크 참격: 띠가 8조각으로 갈라져 조각마다 줄어들며 바깥으로 밀려난다 (erode 0 → 1)
static func dark_band_broken(pd: PDraw, r: float, a0: float, a1: float, w: float, a: float, erode: float, jseed := 0) -> void:
	var n := 8
	for c in n:
		var h1 := fposmod(sin(float(c * 31 + jseed) * 12.9898) * 43758.5453, 1.0)
		var h2 := fposmod(sin(float(c * 17 + jseed * 3) * 78.233) * 24634.6345, 1.0)
		var fc := (float(c) + 0.5) / float(n)
		var half := 0.5 / float(n) * (1.0 - erode * (0.55 + 0.45 * h1)) * 1.08
		if half <= 0.004:
			continue
		var rr := r + erode * w * (0.15 + 0.5 * h2)
		dark_band(pd, rr, lerpf(a0, a1, fc - half), lerpf(a0, a1, fc + half), w * (1.0 - 0.78 * erode), a * (0.75 + 0.25 * h1), jseed + c * 7, 6, 0.55, true)


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


## 초승달 참격 한 장: 볼록한 앞날(꼭짓점 c)이 dir을 향한다. r = 호의 반지름, half = 양쪽으로 벌어진 각(라디안), w = 가운데 두께.
## 다크 질감 겹: 검보라 테두리(앞으로 삐져나옴) → 자두빛 → 보라 → 마젠타 → 분홍빛 흰 앞날 + 결무늬. 양 끝은 뾰족하다.
static func crescent(pd: PDraw, c: Vector2, dir: Vector2, r: float, half: float, w: float, a: float, seg := 12, simple := false) -> void:
	if a <= 0.01 or w < 0.3:
		return
	var o := c - dir * r
	var base := dir.angle()
	# [바깥으로 더 나오는 정도, 두께 배율, 색] — simple = 잔상용 한 겹
	var layers: Array = [[0.0, 1.0, Color(BODY, a)]] if simple else [[0.5, 2.3, Color(MAGENTA, 0.14 * a)], [0.22, 1.55, Color(INK, 0.92 * a)],
		[0.0, 0.95, Color(PLUM.lerp(BODY, 0.5), a)], [0.0, 0.62, Color(MAGENTA, a)], [0.0, 0.32, Color(EDGE, a)]]
	for layer: Array in layers:
		var lw: float = w * float(layer[1])
		var rr := r + w * float(layer[0])
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in seg + 1:
			var f := float(i) / float(seg)
			var ang := base + lerpf(-half, half, f)
			var d := Vector2(cos(ang), sin(ang))
			var thick := lw * pow(sin(f * PI), 0.85)
			outer.append(o + d * rr)
			inner.append(o + d * (rr - thick))
		pd.strip(outer, inner, layer[2])
	if simple:
		return
	# 몸통 안 결무늬 한 줄
	var sl := PackedVector2Array()
	var sr := PackedVector2Array()
	for i in seg + 1:
		var f := lerpf(0.15, 0.9, float(i) / float(seg))
		var ang := base + lerpf(-half, half, f)
		var d := Vector2(cos(ang), sin(ang))
		var mid := r - w * 0.48 * pow(sin(f * PI), 0.85)
		var tw := w * 0.07 * sin(f * PI)
		sl.append(o + d * (mid + tw))
		sr.append(o + d * (mid - tw))
	pd.strip(sl, sr, Color(STREAK, 0.7 * a))


## n번째 참격의 기울기(라디안): 황금비 수열로 -max~+max에 골고루 흩어 이웃한 참격끼리 각도가 겹치지 않게
static func tilt_of(n: int, max_deg: float) -> float:
	return deg_to_rad(lerpf(-max_deg, max_deg, fposmod(float(n) * 0.618034 + 0.31, 1.0)) + randf_range(-4.0, 4.0))


## 초승달의 앞날·양 끝 (맞았는지 볼 때)
static func crescent_points(c: Vector2, dir: Vector2, r: float, half: float) -> Array[Vector2]:
	var o := c - dir * r
	return [c, o + dir.rotated(half * 0.55) * r, o + dir.rotated(-half * 0.55) * r, o + dir.rotated(half) * r, o + dir.rotated(-half) * r]


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


## 순간이동: 떠난 자리에 공간이 세로로 갈라졌다 닫힘
static func blink_out(pos: Vector2, dir: int) -> void:
	var r := Rift.new()
	r.dir = dir
	add(r, pos, true)
	pixels(pos, 8, 120.0, Vector2(-dir, 0), 50.0, 0.25)


static func blink_in(pos: Vector2, dir: int) -> void:
	var r := Rift.new()
	r.dir = dir
	r.arrive = true
	add(r, pos, true)
	pixels(pos, 6, 90.0, Vector2(dir, 0), 60.0, 0.22)


static func blink_trail(from: Vector2, to: Vector2) -> void:
	var s := Streak.new()
	s.to = to - from
	add(s, from, true)


## 잔상: 에스카의 마지막 그림을 그대로 보랏빛으로
static func afterimage(art: EArt, life := 0.25, tint := VIOLET) -> void:
	if art.snap_i.is_empty():
		return
	var a := Afterimage.new()
	a.v = art.snap_v
	a.idx = art.snap_i
	a.life = life
	a.tint = tint
	a.z_index = -6 # 이펙트 층(5) 기준 → 캐릭터 뒤
	a.material = Fx.add_material
	Fx.effect_parent().add_child(a)
	a.global_transform = art.snap_xf


class Afterimage extends Node2D:
	var v := PackedVector2Array()
	var idx := PackedInt32Array()
	var life := 0.25
	var tint := VIOLET
	var t := 0.0
	var _cols := PackedColorArray()

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := (1.0 - t / life)
		_cols.resize(v.size())
		_cols.fill(Color(tint, 0.5 * a * a))
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


# ═══════════════════════════════════════════════════════════
# 기본공격 참격
# ═══════════════════════════════════════════════════════════

class Slash extends PVfx.Base:
	const SWEEP := 0.05 ## 호가 끝까지 그려지는 시간
	const HOLD := 0.035 ## 꽉 찬 채로 머무는 시간 (그 뒤 조각나며 흩어짐)
	var r := 60.0
	var w := 15.0
	var a0 := 0.0
	var a1 := 1.0
	var sq := 1.0
	var rot := 0.0 ## 납작한 회오리를 기울이는 각
	var dir := 1
	var big := false
	var _seed := 0
	var _broke := false

	func setup(a: Dictionary, facing: int, is_big: bool) -> void:
		r = float(a.r)
		w = float(a.w)
		a0 = deg_to_rad(float(a.a0))
		a1 = deg_to_rad(float(a.a1))
		sq = float(a.sq)
		rot = deg_to_rad(float(a.get("rot", 0.0)))
		dir = facing
		big = is_big
		life = 0.42 if big else 0.28
		z_index = 6
		_seed = randi() % 997

	## 호 위의 각 an 자리 (전역 좌표) — 납작하게 누르고 기울인 그대로
	func _arc_point(an: float, rr: float) -> Vector2:
		return position + Vector2(cos(an) * rr * dir, sin(an) * rr * sq).rotated(rot * dir)

	func _tick(_delta: float) -> void:
		if not _broke and t >= SWEEP + HOLD:
			_broke = true
			# 부서지는 순간 호를 따라 보랏빛 조각·연기가 결 방향으로 흩어진다
			var n := 14 if big else 7
			var pp := PParticles.get_layer(false)
			for i in n:
				var an := lerpf(a0, a1, randf_range(0.1, 1.0))
				var p := _arc_point(an, r - w * 0.4)
				var tang := (_arc_point(an + 0.05 * signf(a1 - a0), r) - _arc_point(an, r)).normalized()
				pp.spawn(p, tang * randf_range(60, 200) + (p - position).normalized() * randf_range(20, 70), Vector2(0, 40),
					randf_range(0.2, 0.38), randf_range(1.6, 3.4), MAGENTA if i % 3 else STREAK, PLUM, 0, 4.0)
			for i in (4 if big else 2):
				var p := _arc_point(lerpf(a0, a1, randf_range(0.3, 1.0)), r - w * 0.5)
				pp.spawn(p, Vector2(randf_range(-20, 20), randf_range(-30, -8)), Vector2.ZERO, randf_range(0.35, 0.55), randf_range(5.0, 8.0),
					Color(PLUM, 0.5), Color(INK, 0.0), 2, 3.0)

	func _paint() -> void:
		pd.draw_set_transform(Vector2.ZERO, rot * dir, Vector2(dir, sq))
		if t < SWEEP + HOLD:
			var p := clampf(t / SWEEP, 0.0, 1.0)
			var head := lerpf(a0, a1, 1.0 - pow(1.0 - p, 2.0))
			EVfx.dark_band(pd, r, a0, head, w, 1.0, _seed, 30 if big else 24)
			if p < 1.0:
				# 휘두르는 머리의 분홍빛 섬광
				var hp := Vector2(cos(head), sin(head)) * (r - w * 0.25)
				pd.glow(hp, w * 1.1, Color(EDGE, 0.8), 0.0)
				pd.draw_line(hp - Vector2(w * 1.3, 0), hp + Vector2(w * 1.3, 0), Color(EDGE, 0.9), 1.4)
		else:
			var e := clampf((t - SWEEP - HOLD) / maxf(life - SWEEP - HOLD, 0.01), 0.0, 1.0)
			EVfx.dark_band_broken(pd, r, a0, a1, w, 1.0 - e * e, 1.0 - pow(1.0 - e, 2.0), _seed)
		pd.draw_set_transform(Vector2.ZERO)


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


# ═══════════════════════════════════════════════════════════
# 순간이동
# ═══════════════════════════════════════════════════════════

## 세로로 갈라졌다 닫히는 공간의 틈
class Rift extends PVfx.Base:
	var dir := 1
	var arrive := false

	func _ready() -> void:
		life = 0.22
		z_index = 6

	func _paint() -> void:
		var x := k()
		var open := sin(x * PI)
		var h := 24.0
		var w := 5.5 * open
		var pts := PackedVector2Array([Vector2(0, -h), Vector2(w * 0.6, -h * 0.4), Vector2(w, 0), Vector2(w * 0.5, h * 0.5), Vector2(0, h),
			Vector2(-w * 0.5, h * 0.4), Vector2(-w, 0), Vector2(-w * 0.6, -h * 0.5)])
		if w > 0.3:
			pd.draw_colored_polygon(pts, Color(VIOLET, 0.6 * open))
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.42, 1.0))
			pd.draw_colored_polygon(pts, Color(WHITE, 0.95))
			pd.draw_set_transform(Vector2.ZERO)
		pd.glow(Vector2.ZERO, 16.0 * open, Color(PALE, 0.35), 0.0)
		# 가로로 스치는 공간 흔들림 두 줄
		var sx := float(-dir if not arrive else dir) * (6.0 + 18.0 * x)
		pd.draw_line(Vector2(sx - 6, -h * 0.3), Vector2(sx + 6, -h * 0.3), Color(PALE, 0.6 * (1.0 - x)), 1.0)
		pd.draw_line(Vector2(sx * 0.7 - 5, h * 0.25), Vector2(sx * 0.7 + 5, h * 0.25), Color(PALE, 0.5 * (1.0 - x)), 1.0)


## 출발점 → 도착점 한 줄 (아주 짧게)
class Streak extends PVfx.Base:
	var to := Vector2.ZERO

	func _ready() -> void:
		life = 0.14
		z_index = 5

	func _paint() -> void:
		var f := 1.0 - k()
		pd.line2(Vector2.ZERO, to, Color(VIOLET, 0.0), Color(WHITE, 0.95 * f), 1.0, 3.0 * f)
		pd.line2(Vector2(0, -6), to + Vector2(0, -6), Color(VIOLET, 0.0), Color(PALE, 0.5 * f), 0.6, 1.2 * f)
		pd.line2(Vector2(0, 7), to + Vector2(0, 7), Color(VIOLET, 0.0), Color(PALE, 0.4 * f), 0.6, 1.0 * f)


# ═══════════════════════════════════════════════════════════
# 천열 — 손가락을 튕기면 초승달 참격 여러 장이 부채처럼 흩어져 날아간다 (백목련)
# ═══════════════════════════════════════════════════════════

class Fan extends PVfx.Base:
	const N := 14
	const SPREAD := 42.0 ## 위아래 각도(도)
	const GAP := 0.022 ## 참격 사이 시간
	const FLY := 0.36 ## 한 장이 날아가는 시간
	const DMG := 16
	var eska: EEska
	var dir := 1
	var _ang := PackedFloat32Array()
	var _spd := PackedFloat32Array()
	var _r := PackedFloat32Array()
	var _half := PackedFloat32Array()
	var _tilt := PackedFloat32Array() ## 초승달 모양이 날아가는 방향에서 돌아간 각 (장마다 다름)
	var _spin := PackedFloat32Array() ## 날아가며 더 도는 각
	var _w := PackedFloat32Array()
	var _hit: Array = [] ## 장마다 이미 벤 허수아비 (한 장은 한 번만)
	var _hits := 0
	var _ended := PackedByteArray() ## 다 날아가 부서졌는지

	func _ready() -> void:
		life = N * GAP + FLY + 0.02
		z_index = 6
		var order := range(N)
		order.shuffle()
		for i in N:
			var f := float(order[i]) / float(N - 1)
			_ang.append(deg_to_rad(lerpf(-SPREAD, SPREAD, f) + randf_range(-3.0, 3.0)))
			_spd.append(randf_range(660.0, 820.0))
			_r.append(randf_range(32.0, 46.0))
			_half.append(deg_to_rad(randf_range(58.0, 72.0)))
			_tilt.append(EVfx.tilt_of(i, 55.0))
			_spin.append(randf_range(-0.5, 0.5))
			_w.append(randf_range(9.0, 13.0))
			_hit.append({})
			_ended.append(0)
		EVfx.pixels(position, 10, 90.0, Vector2(dir, 0), 90.0, 0.22)

	func _dirv(i: int) -> Vector2:
		return Vector2(cos(_ang[i]) * dir, sin(_ang[i]))

	## 나간 지 age초 뒤 앞날 위치 (처음엔 빠르고 끝에서 살짝 느려진다)
	func _pos(i: int, age: float) -> Vector2:
		var k := clampf(age / FLY, 0.0, 1.0)
		return _dirv(i) * _spd[i] * FLY * (k - 0.3 * k * k)

	## 초승달 앞날이 향하는 쪽 = 날아가는 방향을 장마다 다른 각만큼 돌린 것
	func _facev(i: int, age: float) -> Vector2:
		return _dirv(i).rotated((_tilt[i] + _spin[i] * clampf(age / FLY, 0.0, 1.0)) * float(dir))

	func _tick(_delta: float) -> void:
		if not is_instance_valid(eska):
			return
		for i in N:
			var age := t - float(i) * GAP
			if _ended[i] == 0 and age >= FLY * 0.82:
				_ended[i] = 1 # 날아간 끝에서 조각으로 부서진다
				EVfx.dark_bits(global_position + _pos(i, FLY * 0.82), 3, 90.0, _dirv(i), 60.0, 0.3)
			if age < 0.0 or age > FLY:
				continue
			var pts := EVfx.crescent_points(global_position + _pos(i, age), _facev(i, age), _r[i], _half[i])
			for d: PDummy in PDummy.all(get_tree()):
				if (_hit[i] as Dictionary).has(d.get_instance_id()):
					continue
				var rect := d.hit_rect().grow(6.0) # 번짐까지 맞은 것으로
				for p: Vector2 in pts:
					if rect.has_point(p):
						(_hit[i] as Dictionary)[d.get_instance_id()] = true
						eska.deal(d, DMG, false, global_position)
						_hits += 1
						if _hits == 1:
							Fx.hitstop(0.03)
							Fx.shake(0.12, 0.1)
						break

	func _paint() -> void:
		# 손끝 튕김 고리
		if t < 0.14:
			var sf := 1.0 - t / 0.14
			pd.glow(Vector2.ZERO, 14.0 * (1.0 + (1.0 - sf)), Color(WHITE, 0.9 * sf), 0.0)
			pd.draw_arc(Vector2.ZERO, lerpf(3.0, 26.0, 1.0 - sf), 0.0, TAU, 22, Color(PALE, sf), 1.6)
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.35, 1.0))
			pd.draw_arc(Vector2.ZERO, lerpf(6.0, 34.0, 1.0 - sf), 0.0, TAU, 22, Color(VIOLET, 0.8 * sf), 1.4)
			pd.draw_set_transform(Vector2.ZERO)
		for i in N:
			var age := t - float(i) * GAP
			if age < 0.0 or age > FLY:
				continue
			var k := age / FLY
			var grow := 0.45 + 0.55 * (1.0 - pow(1.0 - clampf(age / 0.06, 0.0, 1.0), 3.0)) # 손끝에서 작게 나와 커진다
			var a := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
			var fv := _facev(i, age)
			var p := _pos(i, age)
			# 잔상 두 장 (지나온 자리에 희미하게)
			for g in 2:
				var gp := _pos(i, maxf(age - 0.022 * float(g + 1), 0.0))
				EVfx.crescent(pd, gp, fv, _r[i] * grow, _half[i], _w[i] * grow * 0.7, a * (0.3 - 0.1 * float(g)), 8, true)
			EVfx.crescent(pd, p, fv, _r[i] * grow, _half[i], _w[i] * grow, a)
			if age < 0.05:
				pd.glow(p, 9.0, Color(EDGE, 0.8), 0.0)


# ═══════════════════════════════════════════════════════════
# 단공 — 위쪽 공간 한 구역을 다크 초승달 참격이 잇달아 베어 올리고, 마지막에 어둠 폭발 (지상·공중)
# ═══════════════════════════════════════════════════════════

class Storm extends PVfx.Base:
	const TICKS := 8
	const DMG := 11
	const FINAL_DMG := 36
	var eska: EEska
	var area := Rect2() ## 전역 좌표
	var _streaks: Array = [] ## 초승달 한 장: [나온 시각, 출발점, 방향, 속도, 반지름, 벌어진 각, 두께, 앞날 방향(장마다 다르게 기울어짐)]
	var _next := 0.0
	var _ticks := 0
	var _final := false

	func _ready() -> void:
		life = 0.72
		z_index = 6

	func _tick(_delta: float) -> void:
		# 아래에서 위로 초승달 참격이 잇달아 솟구친다 (단혼파처럼 공간 한 구역을 위로 베어 올림)
		while _next <= t and t < 0.44:
			_next += 0.026
			var x := randf_range(area.position.x + 10.0, area.end.x - 10.0)
			var p0 := Vector2(x, area.end.y - randf_range(0.0, 14.0))
			var dv := Vector2.UP.rotated(randf_range(-0.3, 0.3))
			_streaks.append([t, p0, dv, randf_range(700.0, 860.0), randf_range(26.0, 40.0), deg_to_rad(randf_range(58.0, 70.0)), randf_range(8.0, 12.0), dv.rotated(EVfx.tilt_of(_streaks.size(), 60.0))])
		if not is_instance_valid(eska):
			return
		if _ticks < TICKS and t >= 0.04 + float(_ticks) * 0.052:
			_ticks += 1
			_hit_all(DMG, false)
		if not _final and t >= 0.5:
			_final = true
			if _hit_all(FINAL_DMG, true):
				Fx.hitstop(0.06)
				Fx.shake(0.32, 0.16)
			EVfx.pixels(area.get_center(), 10, 220.0, Vector2.UP, 160.0, 0.32, Vector2(0, 220))
			EVfx.dark_burst(area.get_center() + Vector2(0, area.size.y * 0.15), 48.0)
			EVfx.shards(area.get_center(), 10, 180.0, area.size * 0.3, 60.0)
			Sfx.play(&"sword_slash", -2.0)

	func _hit_all(dmg: int, heavy: bool) -> bool:
		var any := false
		for d: PDummy in PDummy.all(get_tree()):
			if area.intersects(d.hit_rect()):
				eska.deal(d, dmg, heavy, Vector2(d.center().x - float(eska.facing), area.end.y))
				any = true
		if any and not heavy and _ticks % 3 == 1:
			Fx.hitstop(0.018)
		return any

	func _paint() -> void:
		var env := clampf(t / 0.06, 0.0, 1.0) * (1.0 - clampf((t - 0.46) / 0.22, 0.0, 1.0))
		# 찢기는 공간: 아래가 밝은 보랏빛 + 흰 바닥선 + 위아래 테두리
		pd.rect_grad(area, Color(PLUM, 0.0), Color(BODY, 0.3 * env))
		pd.draw_rect(Rect2(area.position.x, area.end.y - 3.0, area.size.x, 3.0), Color(MAGENTA, 0.8 * env))
		pd.draw_rect(Rect2(area.position.x, area.position.y, area.size.x, 1.0), Color(STREAK, 0.35 * env))
		# 열리는 순간의 세로 섬광
		if t < 0.1:
			var of := 1.0 - t / 0.1
			pd.draw_rect(Rect2(area.get_center().x - area.size.x * 0.5 * (1.0 - of), area.position.y, area.size.x * (1.0 - of), area.size.y), Color(EDGE, 0.35 * of))
		for s: Array in _streaks:
			var age: float = t - float(s[0])
			if age > 0.22:
				continue
			var dv: Vector2 = s[2]
			var p: Vector2 = s[1] + dv * float(s[3]) * age
			var grow := 0.5 + 0.5 * (1.0 - pow(1.0 - clampf(age / 0.05, 0.0, 1.0), 2.0))
			var a := 1.0 - clampf((age - 0.12) / 0.1, 0.0, 1.0)
			var fv: Vector2 = s[7]
			EVfx.crescent(pd, p - dv * 14.0, fv, float(s[4]) * grow, float(s[5]), float(s[6]) * grow * 0.7, a * 0.3, 8, true) # 잔상
			EVfx.crescent(pd, p, fv, float(s[4]) * grow, float(s[5]), float(s[6]) * grow, a)
		if _final:
			# 마지막: 구역 전체 폭의 큰 초승달 두 장이 엇갈려 솟구친다
			var age := t - 0.5
			var ff := 1.0 - clampf(age / 0.2, 0.0, 1.0)
			if ff > 0.0:
				var bottom := Vector2(area.get_center().x, area.end.y)
				for side: float in [-1.0, 1.0]:
					var dv := Vector2.UP.rotated(0.16 * side)
					var p := bottom + dv * lerpf(20.0, area.size.y + 20.0, 1.0 - pow(1.0 - clampf(age / 0.18, 0.0, 1.0), 2.0))
					EVfx.crescent(pd, p, dv.rotated(0.3 * side), area.size.x * 0.55, deg_to_rad(66.0), 20.0 * ff, ff, 18)
				pd.glow(area.get_center(), area.size.x * 0.7, Color(MAGENTA, 0.3 * ff), 0.0)


# ═══════════════════════════════════════════════════════════
# 봉공 — 납작한 다크 회오리가 대상을 휘감고 공간을 틀로 가둔다. 끝나면 X자로 베어 깨뜨리고 어둠 폭발.
# ═══════════════════════════════════════════════════════════

class BindFrame extends PVfx.Base:
	const HOLD := 2.4
	const SHATTER_DMG := 40
	var eska: EEska
	var target: PDummy
	var _size := Vector2(46, 58)
	var _cracks: Array[PackedVector2Array] = []
	var _broken := false
	var _break_at := HOLD

	func _ready() -> void:
		z_index = 6
		if is_instance_valid(target):
			var r := target.hit_rect().grow(9.0)
			_size = r.size
			position = r.get_center()
			target.bind(HOLD, true, true, "void")
			life = HOLD + 0.32
		else:
			_break_at = 0.3
			life = 0.6
		var hs := _size * 0.5
		for i in 7:
			var side := i % 4
			var start := Vector2.ZERO
			match side:
				0: start = Vector2(randf_range(-hs.x, hs.x), -hs.y)
				1: start = Vector2(hs.x, randf_range(-hs.y, hs.y))
				2: start = Vector2(randf_range(-hs.x, hs.x), hs.y)
				_: start = Vector2(-hs.x, randf_range(-hs.y, hs.y))
			var pts := PackedVector2Array([start])
			var p := start
			var aim := (-start).normalized()
			for s in 3:
				aim = aim.rotated(randf_range(-0.7, 0.7))
				p += aim * randf_range(5.0, 11.0)
				pts.append(p)
			_cracks.append(pts)
		EVfx.pixels(position, 10, 90.0, Vector2.ZERO, 180.0, 0.25)

	func _tick(_delta: float) -> void:
		if not _broken and is_instance_valid(target):
			position = target.hit_rect().get_center()
		if not _broken and t >= _break_at:
			_broken = true
			if is_instance_valid(target) and is_instance_valid(eska):
				target.unbind()
				eska.deal(target, SHATTER_DMG, true, position + Vector2(-eska.facing, 0))
				Fx.hitstop(0.05)
				Fx.shake(0.28, 0.14)
			Sfx.play(&"crumble", -4.0)
			EVfx.dark_burst(position, 40.0)
			EVfx.shards(position, 26, 200.0, _size * 0.5, 60.0)
			EVfx.pixels(position, 12, 160.0, Vector2.ZERO, 180.0, 0.3)

	func _paint() -> void:
		var hs := _size * 0.5
		if _broken:
			var s := t - _break_at
			var bf := 1.0 - clampf(s / 0.25, 0.0, 1.0)
			pd.draw_rect(Rect2(-hs * (1.0 + (1.0 - bf) * 0.35), _size * (1.0 + (1.0 - bf) * 0.35)), Color(STREAK, 0.55 * bf), false, 2.0)
			# 틀을 X자로 가르는 두 줄기 다크 참격
			var L := _size.length() * 1.7
			var grow := 1.0 - pow(1.0 - clampf(s / 0.05, 0.0, 1.0), 2.0)
			for side: float in [-1.0, 1.0]:
				var dv := Vector2(1.0, side * 1.15).normalized()
				EVfx.feather(pd, -dv * L * 0.5, dv, L, 0.06 * side, 15.0 * (0.4 + 0.6 * bf), bf, 0.75 * (1.0 - bf), maxf(grow, 0.75 * (1.0 - bf) + 0.02))
			return
		# 걸리는 순간: 납작한 다크 회오리가 대상을 한 바퀴 휘감고 부서진다
		if t < 0.34:
			var rr := hs.x + 36.0
			pd.draw_set_transform(Vector2(0, hs.y * 0.15), -0.14, Vector2(1.0, 0.34))
			var a0 := -PI * 0.75
			if t < 0.1:
				var sw := 1.0 - pow(1.0 - t / 0.1, 2.0)
				EVfx.dark_band(pd, rr, a0, a0 + TAU * 1.02 * sw, 24.0, 1.0, 11, 40)
			else:
				var e := clampf((t - 0.1) / 0.24, 0.0, 1.0)
				EVfx.dark_band_broken(pd, rr, a0, a0 + TAU * 1.02, 24.0, 1.0 - e * e, 1.0 - pow(1.0 - e, 2.0), 11)
			pd.draw_set_transform(Vector2.ZERO)
		# 모서리 넷이 바깥에서 날아와 맞물린다
		var form := clampf(t / 0.14, 0.0, 1.0)
		var fe := 1.0 - pow(1.0 - form, 3.0)
		var pulse := 0.85 + 0.15 * sin(t * 10.0)
		var spread := (1.0 - fe) * 26.0
		pd.draw_rect(Rect2(-hs, _size), Color(DEEP, 0.2 * fe))
		var col := Color(WHITE, 0.85 * pulse * fe)
		if fe > 0.95:
			pd.draw_rect(Rect2(-hs, _size), col, false, 1.5)
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				var cpt := Vector2((hs.x + spread) * sx, (hs.y + spread) * sy)
				pd.draw_line(cpt, cpt + Vector2(-sx * 11.0, 0), Color(VIOLET, fe), 3.0)
				pd.draw_line(cpt, cpt + Vector2(0, -sy * 11.0), Color(VIOLET, fe), 3.0)
				pd.draw_line(cpt, cpt + Vector2(-sx * 9.0, 0), Color(WHITE, fe), 1.0)
				pd.draw_line(cpt, cpt + Vector2(0, -sy * 9.0), Color(WHITE, fe), 1.0)
				pd.draw_rect(Rect2(cpt - Vector2(2, 2), Vector2(4, 4)), Color(WHITE, fe))
		# 갇힌 공간의 금 + 흐르는 세로 일그러짐
		for pts in _cracks:
			pd.draw_polyline(pts, Color(WHITE, 0.6 * fe), 1.0)
		for i in 3:
			var x := lerpf(-hs.x, hs.x, fmod(t * 0.7 + float(i) / 3.0, 1.0))
			pd.draw_line(Vector2(x, -hs.y + 2), Vector2(x, hs.y - 2), Color(PALE, 0.2 * fe), 1.0)
		# 깨지기 직전 경고 깜빡임 + 금이 번짐
		if t > _break_at - 0.35:
			var wf := 0.5 + 0.5 * sin(t * 40.0)
			pd.draw_rect(Rect2(-hs, _size), Color(WHITE, 0.3 * wf), false, 1.0)
			pd.glow(Vector2.ZERO, maxf(hs.x, hs.y), Color(PALE, 0.15 * wf), 0.0)


# ═══════════════════════════════════════════════════════════
# 종언참 — 세상이 어두워지고(레터박스·확대·감속), 사방으로 참격이 몰아친 뒤,
# 하늘의 거대한 공허의 칼날이 화면을 세로로 가른다. 바닥을 따라 충격파.
# ═══════════════════════════════════════════════════════════

class Ult extends Node2D:
	const SLAM := 0.62
	const END := 1.8
	const SLAM_DMG := 220
	const AFTER_DMG := 24
	var eska: EEska
	var target_x := 0.0
	var floor_y := 300.0
	var t := 0.0
	var lines: Array = [] ## [각도, 길이, 시작]
	var _slammed := false
	var _after := 0
	var _dark: UltDark
	var _glow: UltGlow
	var _banner: UltBanner

	func _ready() -> void:
		for i in 30:
			var a := -PI / 2.0 + randf_range(-PI * 0.95, PI * 0.95)
			lines.append([a, randf_range(110.0, 340.0), randf_range(0.04, 0.42), randf_range(0.2, 0.4) * (-1.0 if randf() < 0.5 else 1.0), randf_range(7.0, 12.0)])
		_dark = UltDark.new()
		_dark.u = self
		_dark.z_index = 4
		add_child(_dark)
		_glow = UltGlow.new()
		_glow.u = self
		_glow.z_index = 7
		_glow.material = Fx.add_material
		add_child(_glow)
		var layer := CanvasLayer.new()
		layer.layer = 15
		add_child(layer)
		_banner = UltBanner.new()
		_banner.u = self
		_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_banner)
		Fx.slowmo(0.55, 0.42) # 형성되는 동안 세상이 느려진다

	func _exit_tree() -> void:
		var cam = Fx.camera
		if cam and cam.get("zoom_extra") != null:
			cam.zoom_extra = 0.0
			cam.focus_w = 0.0

	func hand() -> Vector2:
		if is_instance_valid(eska):
			return eska.global_position + Vector2(eska.facing * 2.5, -44.0)
		return Vector2(target_x, floor_y - 40.0)

	func _process(delta: float) -> void:
		t += delta
		_camera()
		if not _slammed and t >= SLAM:
			_slammed = true
			_slam()
		if _slammed and _after < 4 and t >= SLAM + 0.16 * float(_after + 1):
			_after += 1
			_hit_column(AFTER_DMG, false, 30.0)
			EVfx.pixels(Vector2(target_x, floor_y - randf_range(20.0, 140.0)), 6, 160.0, Vector2.ZERO, 180.0, 0.3)
		if t >= END:
			queue_free()
			return
		_dark.queue_redraw()
		_glow.queue_redraw()
		_banner.queue_redraw()

	## 형성 중에는 에스카와 표적 사이로 다가가 확대, 내리꽂는 순간 한 번에 물러남
	func _camera() -> void:
		var cam = Fx.camera
		if cam == null or cam.get("zoom_extra") == null:
			return
		if t < SLAM:
			var k := clampf(t / 0.35, 0.0, 1.0)
			var e := k * k * (3.0 - 2.0 * k)
			cam.zoom_extra = 0.2 * e
			cam.focus_w = 0.55 * e
			var ex := eska.global_position.x if is_instance_valid(eska) else target_x
			cam.focus_p = Vector2((ex + target_x) * 0.5, floor_y - 80.0)
		else:
			var s := clampf((t - SLAM) / 0.5, 0.0, 1.0)
			cam.zoom_extra = lerpf(-0.06, 0.0, s)
			cam.focus_w = lerpf(0.3, 0.0, s)

	func _slam() -> void:
		Fx.flash(Color(0.92, 0.88, 1.0, 0.5), 0.18)
		Fx.hitstop(0.12)
		Fx.shake(1.2, 0.5)
		Fx.zoom_punch(0.1)
		PVfx.kick(Vector2(0, 7))
		Sfx.play(&"explode", 0.0)
		Sfx.play(&"slam", -2.0)
		_hit_column(SLAM_DMG, true, 48.0)
		EVfx.dark_burst(Vector2(target_x, floor_y - 70.0), 84.0)
		var pp := PParticles.get_layer(true)
		for i in 44:
			var p := Vector2(target_x + randf_range(-10, 10), floor_y - randf_range(0, 220))
			pp.spawn(p, Vector2(randf_range(-280, 280), randf_range(-240, 40)), Vector2(0, 420), randf_range(0.35, 0.75), randf_range(1.5, 3.0), WHITE, VIOLET, 0, 1.5)
		EVfx.shards(Vector2(target_x, floor_y - 30.0), 30, 260.0, Vector2(14, 30), 120.0)
		PVfx.dust(Vector2(target_x, floor_y), 10, 3.0, 26.0)

	func _hit_column(dmg: int, heavy: bool, half_w: float) -> void:
		if not is_instance_valid(eska):
			return
		var col := Rect2(target_x - half_w, floor_y - 420.0, half_w * 2.0, 460.0)
		for d: PDummy in PDummy.all(get_tree()):
			if col.intersects(d.hit_rect()):
				eska.deal(d, dmg, heavy, Vector2(target_x, floor_y - 300.0))

	## 0 → 1 → 0 (어둠·현수막·레터박스)
	func env() -> float:
		return clampf(t / 0.12, 0.0, 1.0) * (1.0 - clampf((t - (END - 0.35)) / 0.35, 0.0, 1.0))


## 세상을 어둡게 (보통 섞기 — 캐릭터·허수아비도 함께 어두워져 실루엣이 된다) + 그 위에 다크 참격선·X자
class UltDark extends PDraw.Canvas:
	var u: Ult

	func _paint() -> void:
		var cam := get_viewport().get_camera_2d()
		var c := cam.get_screen_center_position() if cam else Vector2(320, 180)
		var a := 0.8 * u.env()
		pd.draw_rect(Rect2(c - Vector2(700, 450), Vector2(1400, 900)), Color(0.03, 0.01, 0.07, a))
		var t := u.t
		var h := u.hand()
		# 사방으로 몰아치는 휘어진 다크 참격 (폭풍 속 거대 검) — 검은 테두리가 보이게 보통 섞기로
		for l: Array in u.lines:
			var age: float = t - float(l[2])
			if age < 0.0 or age > 0.34:
				continue
			var f := age / 0.34
			var dv := Vector2(cos(float(l[0])), sin(float(l[0])))
			var grow := minf(f * 2.2, 1.0)
			EVfx.feather(pd, h + dv * 10.0, dv, float(l[1]), float(l[3]), float(l[4]) * (1.0 - f * 0.6), 1.0 - f, f * 0.7, maxf(grow, f * 0.7 + 0.02), 8)
		# 내리꽂은 자리를 X자로 가르는 거대한 두 줄기
		var s := t - Ult.SLAM
		if s >= 0.0 and s < 0.42:
			var xf := 1.0 - clampf((s - 0.06) / 0.36, 0.0, 1.0)
			var grow := 1.0 - pow(1.0 - clampf(s / 0.06, 0.0, 1.0), 2.0)
			var cen := Vector2(u.target_x, u.floor_y - 100.0)
			for side: float in [-1.0, 1.0]:
				var dv := Vector2(1.0, side * 1.2).normalized()
				EVfx.feather(pd, cen - dv * 170.0, dv, 340.0, 0.05 * side, 26.0 * (0.4 + 0.6 * xf), xf, 0.7 * (1.0 - xf), maxf(grow, 0.7 * (1.0 - xf) + 0.02))


## 빛나는 것들 (가산): 손의 빛 · 공허의 칼날 · 세로로 갈라진 화면 · 바닥 충격파 (참격선·X자는 UltDark가 보통 섞기로)
class UltGlow extends PDraw.Canvas:
	var u: Ult

	func _paint() -> void:
		var t := u.t
		var h := u.hand()
		var tx := u.target_x
		var fy := u.floor_y
		# 손 위의 빛 (모이는 고리)
		if t < Ult.SLAM + 0.1:
			var hf := clampf(t / 0.2, 0.0, 1.0)
			pd.glow(h, 11.0 + 6.0 * sin(t * 30.0), Color(WHITE, 0.95 * hf), 0.0)
			var rr := lerpf(40.0, 4.0, fmod(t * 2.6, 1.0))
			pd.draw_arc(h, rr, 0.0, TAU, 24, Color(PALE, 0.6 * hf), 1.2)
		# 공허의 칼날 (하늘에서 형성 → 내리꽂힘)
		if t < Ult.SLAM:
			var form := clampf((t - 0.1) / (Ult.SLAM - 0.1), 0.0, 1.0)
			var len := 300.0
			var top := fy - 430.0 + 46.0 * form * form
			var w := 19.0 * form
			var tip := Vector2(tx, top + len)
			var blade := PackedVector2Array([Vector2(tx, top), Vector2(tx + w, top + len * 0.22), tip, Vector2(tx - w, top + len * 0.22)])
			pd.draw_colored_polygon(blade, Color(DEEP, 0.55 * form))
			pd.draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[0]]), Color(WHITE, form), 1.5)
			pd.draw_set_transform(Vector2(tx, top + len * 0.5), 0.0, Vector2(0.35, 0.92))
			pd.draw_colored_polygon(PackedVector2Array([Vector2(0, -len * 0.5), Vector2(w, -len * 0.28), Vector2(0, len * 0.5), Vector2(-w, -len * 0.28)]),
				Color(WHITE, 0.6 * form + 0.3 * form * sin(t * 40.0)))
			pd.draw_set_transform(Vector2.ZERO)
			pd.glow(tip, 20.0 * form, Color(PALE, 0.55 * form), 0.0)
			# 칼날이 겨누는 바닥의 표식
			pd.draw_set_transform(Vector2(tx, fy), 0.0, Vector2(1.0, 0.22))
			pd.draw_arc(Vector2.ZERO, 26.0 * (1.2 - form * 0.4), 0.0, TAU, 28, Color(VIOLET, 0.8 * form), 2.0)
			pd.draw_set_transform(Vector2.ZERO)
		else:
			var s := t - Ult.SLAM
			# 화면을 세로로 가르는 일격
			var cf := 1.0 - clampf(s / 0.3, 0.0, 1.0)
			if cf > 0.0:
				pd.draw_rect(Rect2(tx - 28.0 * cf, fy - 440.0, 56.0 * cf, 480.0), Color(WHITE, cf))
				pd.glow(Vector2(tx, fy - 110.0), 170.0 * cf, Color(PALE, 0.4 * cf), 0.0)
			# 바닥을 따라 퍼지는 충격파 (납작한 고리 둘)
			var sw := clampf(s / 0.45, 0.0, 1.0)
			if sw < 1.0:
				pd.draw_set_transform(Vector2(tx, fy), 0.0, Vector2(1.0, 0.16))
				pd.draw_arc(Vector2.ZERO, lerpf(20.0, 260.0, sw), 0.0, TAU, 40, Color(PALE, 0.9 * (1.0 - sw)), 6.0 * (1.0 - sw) + 1.0)
				pd.draw_arc(Vector2.ZERO, lerpf(10.0, 170.0, sw), 0.0, TAU, 40, Color(VIOLET, 0.7 * (1.0 - sw)), 3.0)
				pd.draw_set_transform(Vector2.ZERO)
			# 남아서 천천히 닫히는 공간의 금
			var close := 1.0 - clampf(s / (Ult.END - Ult.SLAM - 0.1), 0.0, 1.0)
			if close > 0.0:
				var pts := PackedVector2Array()
				var n := 16
				for i in n + 1:
					var y := lerpf(fy - 420.0, fy, float(i) / float(n))
					var jx := (5.0 if i % 2 == 0 else -5.0) * close + sin(float(i) * 1.7) * 2.0
					pts.append(Vector2(tx + jx, y))
				pd.draw_polyline(pts, Color(VIOLET, 0.7 * close), 8.0 * close + 1.0)
				pd.draw_polyline(pts, Color(WHITE, close), 3.0 * close + 0.6)
				pd.draw_rect(Rect2(tx - 44.0, fy - 2.0, 88.0, 3.0), Color(PALE, 0.6 * close))


## 기술명 현수막 + 레터박스 (화면 고정)
class UltBanner extends Control:
	var u: Ult

	func _draw() -> void:
		var e := u.env()
		if e <= 0.0:
			return
		var W := size.x
		var H := size.y
		var mid := W * 0.5
		var bar := 26.0 * e
		draw_rect(Rect2(0, 0, W, bar), Color(0, 0, 0, 0.92))
		draw_rect(Rect2(0, H - bar, W, bar), Color(0, 0, 0, 0.92))
		var font := get_theme_default_font()
		var txt := "종언참"
		var fs := 22
		var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var cy := 70.0
		var slide := (1.0 - clampf(u.t / 0.18, 0.0, 1.0)) * 24.0
		draw_rect(Rect2(0, cy - 20, W, 30), Color(0.02, 0.0, 0.05, 0.5 * e))
		draw_line(Vector2(mid - 150 + slide, cy - 20), Vector2(mid + 150 + slide, cy - 20), Color(VIOLET, 0.85 * e), 1.0)
		draw_line(Vector2(mid - 150 - slide, cy + 10), Vector2(mid + 150 - slide, cy + 10), Color(VIOLET, 0.85 * e), 1.0)
		var pos := Vector2(mid - sz.x * 0.5 + slide, cy + 2)
		draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.05, 0.0, 0.1, e))
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, e))
		var sub := "끝은, 내가 정한다."
		var ssz := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		draw_string_outline(font, Vector2(mid - ssz.x * 0.5, cy + 24), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(0, 0, 0, 0.8 * e))
		draw_string(font, Vector2(mid - ssz.x * 0.5, cy + 24), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(PALE, 0.9 * e))
