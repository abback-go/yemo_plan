class_name EFoeFx
extends RefCounted
## 적 쪽 이펙트 (검정·뼈흰색·핏빛 빨강 — 에스카의 보라와 구별되게):
## 나타나는 붉은 틈 · 쓰러질 때 뼈 조각과 검은 연기 · 거구의 땅 충격파 · 경고 표시.

const BLACK := EEnemy.BLACK
const BONE := EEnemy.BONE
const RED := EEnemy.RED
const RED_DEEP := EEnemy.RED_DEEP
const RED_HOT := EEnemy.RED_HOT


## 적이 나타나는 붉은 틈 (세로로 찢어졌다 닫힘)
static func rift(pos: Vector2, h: float) -> void:
	var r := Rift.new()
	r.h = h
	PVfx.add(r, pos, false)
	var pp := PParticles.get_layer(true)
	for i in 8:
		pp.spawn(pos + Vector2(randf_range(-3, 3), randf_range(-h, h)), Vector2(randf_range(-70, 70), randf_range(-40, 20)), Vector2(0, 80),
			randf_range(0.25, 0.45), randf_range(1.0, 2.0), RED_HOT, RED_DEEP, 0, 3.0)


## 쓰러짐: 뼈 조각이 튀고 검은 연기가 피어오르며 붉은 고리가 번진다
static func death(pos: Vector2, sz: Vector2, dir: float) -> void:
	var pp := PParticles.get_layer(false)
	var n := int(8 + sz.x * 0.3)
	for i in n:
		var v := Vector2(dir * randf_range(30, 170) + randf_range(-60, 60), randf_range(-220, -60))
		pp.spawn(pos + Vector2(randf_range(-sz.x, sz.x) * 0.4, randf_range(-sz.y, sz.y) * 0.4), v, Vector2(0, 600),
			randf_range(0.45, 0.8), randf_range(1.5, 3.0), BONE, Color("#6e6358"), 0, 1.2)
	for i in n:
		var v := Vector2(randf_range(-40, 40), randf_range(-60, -10))
		pp.spawn(pos + Vector2(randf_range(-sz.x, sz.x) * 0.5, randf_range(-sz.y, sz.y) * 0.5), v, Vector2.ZERO,
			randf_range(0.5, 0.9), randf_range(5.0, 9.0), Color(BLACK, 0.7), Color(RED_DEEP, 0.0), 2, 2.5)
	var b := Burst.new()
	b.rad = maxf(sz.x, sz.y) * 0.9
	PVfx.add(b, pos, true)


## 땅을 따라 양쪽으로 번지는 충격파 (거구의 내려찍기)
static func shock(pos: Vector2, reach: float) -> void:
	var s := Shock.new()
	s.reach = reach
	PVfx.add(s, pos, true)
	var pp := PParticles.get_layer(false)
	for i in 22:
		var x := randf_range(-reach, reach)
		pp.spawn(pos + Vector2(x, -2), Vector2(signf(x) * randf_range(20, 90), randf_range(-260, -80)), Vector2(0, 700),
			randf_range(0.4, 0.7), randf_range(1.5, 3.5), Color("#3b3238"), Color("#151015"), 0, 1.0)


## 틈: 들쭉날쭉한 세로 틈(검은 속 + 붉은 테두리)
class Rift extends PVfx.Base:
	var h := 20.0
	var _j := PackedFloat32Array()

	func _ready() -> void:
		life = 0.5
		z_index = 3
		for i in 14:
			_j.append(randf_range(0.5, 1.0))

	func _paint() -> void:
		var x := k()
		var open := minf(x / 0.25, 1.0) * (1.0 - smoothstep(0.45, 1.0, x))
		if open <= 0.01:
			return
		var w := 9.0 * open
		var hh := h * (0.7 + 0.3 * open)
		pd.glow(Vector2.ZERO, hh * 1.2, Color(RED, 0.25 * open), 0.0)
		pd.draw_colored_polygon(_shape(hh + 3.0, w + 2.5), Color(RED, 0.95 * open))
		pd.draw_colored_polygon(_shape(hh, w), Color(BLACK, 0.95))
		pd.draw_line(Vector2(0, -hh * 0.7), Vector2(0, hh * 0.7), Color(RED_HOT, 0.7 * open), 1.0)

	func _shape(hh: float, w: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var n := _j.size() / 2
		for i in n:
			var f := float(i) / float(n - 1)
			pts.append(Vector2(w * pow(sin(f * PI), 0.8) * _j[i], lerpf(-hh, hh, f)))
		for i in range(n - 1, -1, -1):
			var f := float(i) / float(n - 1)
			pts.append(Vector2(-w * pow(sin(f * PI), 0.8) * _j[n + i], lerpf(-hh, hh, f)))
		return pts


## 쓰러질 때 붉은 고리 + 십자 섬광 (가산)
class Burst extends PVfx.Base:
	var rad := 20.0

	func _ready() -> void:
		life = 0.4
		z_index = 6

	func _paint() -> void:
		var x := k()
		var a := 1.0 - x
		var r := rad * (0.5 + 1.1 * (1.0 - pow(1.0 - x, 3.0)))
		pd.glow(Vector2.ZERO, r * 1.2, Color(RED, 0.35 * a), 0.0)
		pd.draw_arc(Vector2.ZERO, r, 0.0, TAU, 30, Color(RED, 0.9 * a), 2.5 * a + 0.5)
		if x < 0.35:
			var f := 1.0 - x / 0.35
			pd.draw_line(Vector2(-r * 1.5 * f, 0), Vector2(r * 1.5 * f, 0), Color(RED_HOT, f), 2.0 * f)
			pd.draw_line(Vector2(0, -r * 1.1 * f), Vector2(0, r * 1.1 * f), Color(RED_HOT, f), 1.5 * f)


## 땅 충격파: 양쪽으로 달려 나가는 붉은 물결 + 갈라진 금
class Shock extends PVfx.Base:
	var reach := 85.0
	var _cracks: Array = []

	func _ready() -> void:
		life = 0.55
		z_index = 4
		for s in [-1.0, 1.0]:
			for i in 3:
				var pts := PackedVector2Array([Vector2.ZERO])
				var p := Vector2.ZERO
				for j in 5:
					p += Vector2(s * randf_range(10, 22), randf_range(-3, 3))
					pts.append(p)
				_cracks.append(pts)

	func _paint() -> void:
		var x := k()
		var go := 1.0 - pow(1.0 - minf(x / 0.35, 1.0), 2.0)
		var a := 1.0 - smoothstep(0.3, 1.0, x)
		var front := reach * go
		pd.glow(Vector2(0, -4), reach * 0.7, Color(RED, 0.35 * a), 0.0)
		for s in [-1.0, 1.0]:
			# 물결 머리: 땅 위로 솟은 붉은 날
			var hx: float = s * front
			var hh := 18.0 * a * (1.0 - 0.5 * go)
			pd.draw_colored_polygon(PackedVector2Array([Vector2(hx - s * 26.0, 0), Vector2(hx - s * 6.0, -hh), Vector2(hx + s * 4.0, 0)]), Color(RED, 0.85 * a))
			pd.draw_colored_polygon(PackedVector2Array([Vector2(hx - s * 18.0, 0), Vector2(hx - s * 6.0, -hh * 0.6), Vector2(hx, 0)]), Color(RED_HOT, 0.9 * a))
			pd.line2(Vector2.ZERO, Vector2(hx, 0), Color(RED_DEEP, 0.0), Color(RED, 0.9 * a), 1.0, 3.0)
		for c: PackedVector2Array in _cracks:
			var n := int(ceil(float(c.size()) * go))
			if n >= 2:
				pd.draw_polyline(c.slice(0, n), Color(RED_HOT, 0.8 * a), 1.0)
