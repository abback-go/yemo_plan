class_name PVfx
extends RefCounted
## 훈련장 이펙트 모음. 모두 코드 그림(Node2D._draw)이고, 수명이 끝나면 스스로 사라진다.
## 기준 그림: 할로우 나이트·실크송 — 발톱 참격은 굵은 흰 초승달 + 속도선, 대시는 출발점에서 뒤로 터지는 흰 가시 다발.
## 세라의 것은 "여우 의태"가 겹친다: 참격에 발톱 자국 세 줄, 대시에 여우 발자국.

## 공통 바탕: life초 동안 k(0→1)로 그리고 사라진다
class Base extends Node2D:
	var life := 0.3
	var t := 0.0
	var fox := false

	func k() -> float:
		return clampf(t / life, 0.0, 1.0)

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		_tick(delta)
		queue_redraw()

	func _tick(_delta: float) -> void:
		pass


static func add(n: Node2D, pos: Vector2, additive := false) -> Node2D:
	n.position = pos
	if additive:
		n.material = Fx.add_material
	Fx.effect_parent().add_child(n)
	return n


static func sparks(pos: Vector2, n: int, col: Color, speed := 120.0, life := 0.35, dir := Vector2.UP, spread := 180.0, grav := Vector2(0, 220)) -> void:
	Fx.burst(pos, n, {"gradient": Palette.fade_gradient(col), "add": true, "speed_min": speed * 0.4, "speed_max": speed,
		"lifetime": life, "direction": dir, "spread": spread, "gravity": grav, "size_min": 1.0, "size_max": 2.0})


static func embers(pos: Vector2, n: int, fox_fire: bool, speed := 90.0, box := Vector2.ZERO) -> void:
	var o := {"gradient": Palette.fade_gradient(PData.FOX_HOT if fox_fire else PData.FIRE_HOT), "add": true,
		"speed_min": speed * 0.3, "speed_max": speed, "lifetime": 0.7, "direction": Vector2.UP, "spread": 70.0,
		"gravity": Vector2(0, -40), "size_min": 1.0, "size_max": 2.2, "explosiveness": 0.6}
	if box != Vector2.ZERO:
		o["box"] = box
	Fx.burst(pos, n, o)


## 초승달 하나 (가운데 굵고 양끝 뾰족). a0→a1 각도, r 바깥 반지름, w 가장 굵은 곳
static func crescent(c: CanvasItem, center: Vector2, r: float, a0: float, a1: float, w: float, col: Color, seg := 18) -> void:
	if absf(a1 - a0) < 0.03 or w < 0.3 or r - w < 0.0 or col.a <= 0.01:
		return
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in seg + 1:
		var f := float(i) / float(seg)
		var a := lerpf(a0, a1, f)
		var thick := w * sin(f * PI)
		outer.append(center + Vector2(cos(a), sin(a)) * r)
		inner.append(center + Vector2(cos(a), sin(a)) * (r - thick))
	inner.reverse()
	outer.append_array(inner)
	safe_poly(c, outer, col)


## 삼각분할이 안 되는(꼬인) 다각형은 건너뛴다 — 엔진 오류("Invalid polygon data") 방지
static func safe_poly(c: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3 and not Geometry2D.triangulate_polygon(pts).is_empty():
		c.draw_colored_polygon(pts, col)


## 뾰족한 가시(삼각형): from에서 dir 방향으로 len, 밑변 w
static func spike(c: CanvasItem, from: Vector2, dir: Vector2, length: float, w: float, col: Color) -> void:
	var n := dir.orthogonal().normalized() * w * 0.5
	c.draw_colored_polygon(PackedVector2Array([from + n, from - n, from + dir.normalized() * length]), col)


# ═══════════════════════════════════════════════════════════
# 발톱 참격 (할로우 나이트 기본 공격 느낌 + 여우 발톱 의태)
# ═══════════════════════════════════════════════════════════

## dir: 1 오른쪽 / -1 왼쪽, aim: 0 앞 · -1 위 · 1 아래, step: 0~2 (콤보마다 휘는 방향이 다름)
class ClawSlash extends Base:
	var dir := 1
	var aim := 0
	var step := 0
	var reach := 30.0
	var follow: Node2D ## 세라를 따라 움직임(참격이 몸에 붙어 있게)
	var offset := Vector2.ZERO

	func _init() -> void:
		life = 0.16
		z_index = 6

	func _tick(_d: float) -> void:
		if is_instance_valid(follow):
			global_position = follow.global_position + offset

	func _draw() -> void:
		var kk := k()
		var grow := clampf(kk / 0.22, 0.0, 1.0) # 앞쪽 22%에 휘둘러 나타나고
		var fade := 1.0 - clampf((kk - 0.35) / 0.65, 0.0, 1.0) # 나머지에 사라짐
		var base_col := PData.FOX_CORE if fox else Color(1, 1, 1)
		var glow_col := PData.FOX_MID if fox else Color(0.75, 0.88, 1.0)
		var R := (reach + 6.0) * (1.25 if fox else 1.0)
		# 방향별 각도: 앞(dir) / 위 / 아래. step마다 위→아래·아래→위로 휘두름
		var mid := 0.0 if dir > 0 else PI
		if aim == -1:
			mid = -PI / 2
		elif aim == 1:
			mid = PI / 2
		var span := 2.3 if aim == 0 else 2.0
		var sweep := (1.0 if (step % 2 == 0) else -1.0) * (dir if aim == 0 else 1)
		var a0 := mid - span / 2 * sweep
		var a1 := lerpf(a0, mid + span / 2 * sweep, grow)
		var ctr := Vector2.ZERO
		# 은은한 바깥 빛 → 흰 초승달 → 안쪽 발톱 자국 세 줄
		PVfx.crescent(self, ctr, R + 4, a0, a1, 15.0, Color(glow_col, 0.3 * fade))
		PVfx.crescent(self, ctr, R, a0, a1, 12.0 if step == 2 else 11.0, Color(base_col, 0.96 * fade))
		for i in 3:
			var rr := R - 10.0 - i * 3.2
			PVfx.crescent(self, ctr, rr, lerpf(a0, a1, 0.15), lerpf(a0, a1, 0.92), 1.6, Color(glow_col, 0.75 * fade), 12)
		# 끝에서 뻗는 속도선
		if grow > 0.6:
			var tip := Vector2(cos(a1), sin(a1)) * R
			var tang := Vector2(-sin(a1), cos(a1)) * sweep
			for i in 3:
				var off := tip + tang.orthogonal() * (i - 1) * 3.0
				draw_line(off, off + tang * (10.0 + i * 4.0) * fade, Color(base_col, 0.6 * fade), 1.0)


## 맞힌 자리의 하얀 섬광 (가시 별 + 짧은 선)
class HitFlash extends Base:
	var dir := 1
	var big := false

	func _init() -> void:
		life = 0.14
		z_index = 8

	func _draw() -> void:
		var kk := k()
		var s := (1.0 + kk * 0.6) * (1.4 if big else 1.0)
		var a := 1.0 - kk
		var col := Color(PData.FOX_CORE, a) if fox else Color(1, 1, 1, a)
		for i in 6:
			var ang := float(i) / 6.0 * TAU + 0.3
			var l := (14.0 if i % 2 == 0 else 8.0) * s
			PVfx.spike(self, Vector2.ZERO, Vector2(cos(ang), sin(ang)), l, 3.0 * a + 1.0, col)
		draw_circle(Vector2.ZERO, 3.5 * s * a, col)
		# 맞은 방향으로 길게 뻗는 선 두 줄
		for i in 2:
			var y := (i * 2 - 1) * 3.0
			draw_line(Vector2(0, y), Vector2(dir * 26.0 * s * (0.4 + kk), y * 1.5), Color(col, a * 0.7), 1.0)


# ═══════════════════════════════════════════════════════════
# 대시 — 출발점에서 뒤로 터지는 흰 가시 다발 + 여우 발자국 (잔상 아님)
# ═══════════════════════════════════════════════════════════

class DashBurst extends Base:
	var dir := 1
	var _rays: Array = [] ## [각도 흔들림, 길이, 굵기, 지연]
	var air := false

	func _init() -> void:
		life = 0.32
		z_index = 4
		for i in 13:
			var spread := randf_range(-0.36, 0.36)
			_rays.append([spread, randf_range(26.0, 64.0) * (1.0 - absf(spread)), randf_range(2.0, 4.6), randf_range(0.0, 0.3)])

	func _draw() -> void:
		var kk := k()
		var col := PData.FOX_CORE if fox else Color(1, 1, 1)
		# 출발점 뒤쪽(dir 반대)으로 퍼지는 뾰족한 흰 가시들
		for r: Array in _rays:
			var local := clampf((kk - float(r[3]) * 0.4) / 0.75, 0.0, 1.0)
			if local <= 0.0:
				continue
			var ang := (PI if dir > 0 else 0.0) + float(r[0])
			var d := Vector2(cos(ang), sin(ang) * 0.7)
			var start := d * 6.0 * local
			var length := float(r[1]) * (0.35 + 0.65 * sqrt(local))
			var a := (1.0 - local)
			PVfx.spike(self, start, d, length, float(r[2]) * (1.0 - local * 0.6), Color(col, 0.95 * a))
		# 반짝이는 작은 점
		for i in 5:
			var p := Vector2(-dir * (14.0 + i * 9.0) * (0.5 + kk), sin(i * 2.1) * 8.0 - 4.0)
			draw_circle(p, 1.2 * (1.0 - kk), Color(col, 0.9 * (1.0 - kk)))


## 여우 발자국(의태) — 발밑에 투명한 여우 발이 찍히고 흩어짐
class FoxPaw extends Base:
	var dir := 1
	var size := 1.0

	func _init() -> void:
		life = 0.42
		z_index = 3

	func _draw() -> void:
		var kk := k()
		var a := (1.0 - kk) * 0.85
		var s := size * (1.0 + kk * 0.25)
		var col := Color(PData.FOX_HOT, a)
		var core := Color(PData.FOX_CORE, a)
		draw_set_transform(Vector2.ZERO, -0.25 * dir, Vector2(s * dir, s))
		# 발바닥(큰 볼록) + 발가락 넷 + 발톱
		draw_colored_polygon(_blob(Vector2(0, 2), 6.0, 4.6), col)
		draw_colored_polygon(_blob(Vector2(0, 2.5), 3.8, 2.8), core)
		var toes := [Vector2(-6.5, -4), Vector2(-2.4, -7.2), Vector2(2.4, -7.2), Vector2(6.5, -4)]
		for tpos: Vector2 in toes:
			draw_colored_polygon(_blob(tpos, 2.3, 2.6), col)
			PVfx.spike(self, tpos + Vector2(0, -2.2), (tpos - Vector2(0, 2)).normalized(), 4.0, 1.6, core)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _blob(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in 12:
			var a := float(i) / 12.0 * TAU
			p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return p


## 대시 중 몸 뒤로 짧게 그어지는 속도선 (매 프레임 하나씩)
class SpeedLine extends Base:
	var dir := 1
	var length := 22.0

	func _init() -> void:
		life = 0.12
		z_index = 2

	func _draw() -> void:
		var a := 1.0 - k()
		var col := PData.FOX_CORE if fox else Color(1, 1, 1)
		draw_line(Vector2.ZERO, Vector2(-dir * length * (0.5 + k()), 0), Color(col, 0.55 * a), 1.0)


# ═══════════════════════════════════════════════════════════
# 이동 먼지·착지·점프
# ═══════════════════════════════════════════════════════════

class Dust extends Base:
	var vel := Vector2.ZERO
	var r := 3.0

	func _init() -> void:
		life = 0.38
		z_index = 1

	func _tick(delta: float) -> void:
		position += vel * delta
		vel *= 0.9

	func _draw() -> void:
		var kk := k()
		draw_circle(Vector2.ZERO, r * (0.6 + kk * 0.9), Color(0.82, 0.8, 0.86, 0.45 * (1.0 - kk)))


static func dust(pos: Vector2, n: int, spread_x := 1.0, up := 18.0) -> void:
	for i in n:
		var d := Dust.new()
		d.vel = Vector2(randf_range(-40, 40) * spread_x, -randf_range(4, up))
		d.r = randf_range(2.0, 3.6)
		add(d, pos + Vector2(randf_range(-4, 4), 0))


## 2단 점프 — 발밑에 푸른 여우불 고리 + 날개처럼 퍼지는 두 줄기
class AirRing extends Base:
	func _init() -> void:
		life = 0.3
		z_index = 2

	func _draw() -> void:
		var kk := k()
		var a := 1.0 - kk
		draw_arc(Vector2.ZERO, 5.0 + kk * 14.0, 0, TAU, 20, Color(PData.FOX_HOT, 0.8 * a), 2.0 * a + 0.5)
		for s in [-1, 1]:
			PVfx.crescent(self, Vector2(0, -2), 10.0 + kk * 8.0, PI / 2 + s * 0.3, PI / 2 + s * 1.6, 3.0, Color(PData.FOX_CORE, 0.7 * a), 10)


# ═══════════════════════════════════════════════════════════
# 집중 · 방패 · 변신
# ═══════════════════════════════════════════════════════════

## 집중 중 손으로 모여드는 빛 알갱이 하나
class Mote extends Base:
	var from := Vector2.ZERO
	var to: Node2D
	var to_off := Vector2.ZERO

	func _init() -> void:
		life = 0.5
		z_index = 7

	func _tick(_d: float) -> void:
		if is_instance_valid(to):
			var kk := k()
			global_position = from.lerp(to.global_position + to_off, kk * kk)

	func _draw() -> void:
		var a := sin(k() * PI)
		draw_circle(Vector2.ZERO, 1.6, Color(PData.FIRE_HOT, a))
		draw_circle(Vector2.ZERO, 3.0, Color(PData.FIRE_MID, 0.3 * a))


## 마나 한 칸이 찼을 때 몸에서 퍼지는 빛
class FocusPulse extends Base:
	func _init() -> void:
		life = 0.35
		z_index = 7

	func _draw() -> void:
		var kk := k()
		var a := 1.0 - kk
		draw_arc(Vector2.ZERO, 6.0 + kk * 22.0, 0, TAU, 28, Color(PData.FIRE_HOT, 0.9 * a), 2.0 * a + 0.5)
		for i in 8:
			var ang := float(i) / 8.0 * TAU
			PVfx.spike(self, Vector2(cos(ang), sin(ang)) * (8.0 + kk * 14.0), Vector2(cos(ang), sin(ang)), 6.0 * a, 2.0, Color(PData.FIRE_CORE, a))
