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
		life = 0.18
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
		if aim == 0:
			_draw_swing(grow, fade, base_col, glow_col, R)
			return
		# 위·아래 베기: 머리 위/발밑으로 둥글게
		var mid := -PI / 2 if aim == -1 else PI / 2
		var span := 2.0
		var sweep := 1.0 if (step % 2 == 0) else -1.0
		var a0 := mid - span / 2 * sweep
		var a1 := lerpf(a0, mid + span / 2 * sweep, grow)
		_arc_layers(a0, a1, sweep, grow, fade, base_col, glow_col, R, 12.0 if step == 2 else 11.0)
		var tip := Vector2(cos(a1), sin(a1)) * R * 0.78
		PVfx.fire_paw(self, tip, (Vector2(-sin(a1), cos(a1)) * sweep).angle(), R / 44.0, fox, fade * clampf(grow * 3.0, 0.0, 1.0))

	## 앞 베기 3타: 1타 = 위-뒤에서 앞-아래로 내려 긋는 대각선, 2타 = 몸 앞을 가로지르는 수평, 3타 = 아래-뒤에서 앞-위로 올려 긋는 대각선.
	## 몸을 감싸는 납작한 타원 궤적(기울기·납작함)을 돌려서 그린다 — 수직 반원이 아니라 옆·대각선으로 휘두르는 모양.
	func _draw_swing(grow: float, fade: float, base_col: Color, glow_col: Color, R: float) -> void:
		var s := step % 3
		var tilt: float = [0.55, -0.08, -0.6][s] # + = 앞쪽이 아래로
		var flat: float = [0.42, 0.3, 0.42][s] # 타원 세로 납작함
		var a0: float = [-2.75, -2.9, 2.75][s] # 뒤쪽에서 시작
		var a_end: float = [0.75, 0.85, -0.75][s] # 앞쪽 지나 끝
		var rr := R * (1.12 if s == 1 else 1.0) * (1.1 if s == 2 else 1.0)
		var sweep := signf(a_end - a0)
		var a1 := lerpf(a0, a_end, grow)
		draw_set_transform(Vector2.ZERO, tilt * dir, Vector2(dir, flat))
		_arc_layers(a0, a1, sweep, grow, fade, base_col, glow_col, rr, 13.0 if s == 2 else 12.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 휘두르는 끝에 붙은 커다란 여우손(불꽃 발) — 궤적 위 점과 진행 방향을 같은 기울기·납작함으로 옮겨 계산
		var rot := tilt * dir
		var q := Vector2(dir * cos(a1), flat * sin(a1)) * rr * 0.78
		var tq := Vector2(dir * -sin(a1), flat * cos(a1)) * sweep
		PVfx.fire_paw(self, q.rotated(rot), tq.rotated(rot).angle(), rr / 44.0, fox, fade * clampf(grow * 3.0, 0.0, 1.0))

	## 빛 → 흰 초승달 → 안쪽 발톱 자국 세 줄 → 끝 속도선
	func _arc_layers(a0: float, a1: float, sweep: float, grow: float, fade: float, base_col: Color, glow_col: Color, R: float, w: float) -> void:
		PVfx.crescent(self, Vector2.ZERO, R + 4, a0, a1, w + 4.0, Color(glow_col, 0.3 * fade), 22)
		PVfx.crescent(self, Vector2.ZERO, R, a0, a1, w, Color(base_col, 0.96 * fade), 22)
		for i in 3:
			var rr := R - 10.0 - i * 3.2
			PVfx.crescent(self, Vector2.ZERO, rr, lerpf(a0, a1, 0.15), lerpf(a0, a1, 0.92), 1.6, Color(glow_col, 0.75 * fade), 14)
		if grow > 0.6:
			var tip := Vector2(cos(a1), sin(a1)) * R
			var tang := Vector2(-sin(a1), cos(a1)) * sweep
			for i in 3:
				var off := tip + tang.orthogonal() * (i - 1) * 3.0
				draw_line(off, off + tang * (10.0 + i * 4.0) * fade, Color(base_col, 0.6 * fade), 1.0)


## 커다란 여우손(불꽃 발) — p에서 ang 방향으로 발톱을 세운 손. 평소 = 붉은 불, 변신 = 푸른 여우불. 손목엔 금 팔찌.
## 발톱 참격이 "여우손으로 할퀸다"는 느낌을 주는 의태 이펙트(사용자 참고: 불꽃 주먹 + 금 팔찌).
static func fire_paw(c: CanvasItem, p: Vector2, ang: float, s: float, fox_fire: bool, a: float) -> void:
	if a <= 0.02:
		return
	var core := PData.FOX_CORE if fox_fire else PData.FIRE_CORE
	var hot := PData.FOX_HOT if fox_fire else PData.FIRE_HOT
	var mid := PData.FOX_MID if fox_fire else PData.FIRE_MID
	var dark := PData.FOX_DARK if fox_fire else PData.FIRE_DARK
	c.draw_set_transform(p, ang, Vector2(s, s))
	# 뒤로 날리는 불꽃 혀가 달린 불의 기운
	var aura := PackedVector2Array()
	for i in 18:
		var t2 := float(i) / 18.0 * TAU
		var back := cos(t2) < -0.2
		var r := 1.0 + (0.55 if back else 0.18) * float(i % 2)
		aura.append(Vector2(-2.0 + cos(t2) * 19.0 * r * (1.25 if back else 1.0), sin(t2) * 13.0 * r))
	safe_poly(c, aura, Color(dark, 0.45 * a))
	safe_poly(c, _ellipse(Vector2(-1, 0), 16.0, 11.5), Color(mid, 0.7 * a))
	# 손바닥 + 발가락 넷 + 세운 발톱
	safe_poly(c, _ellipse(Vector2(-3, 0), 9.5, 8.5), Color(hot, 0.95 * a))
	safe_poly(c, _ellipse(Vector2(-3, 0), 5.5, 4.5), Color(core, a))
	for ty: float in [-8.5, -3.0, 3.0, 8.5]:
		var tp := Vector2(8.0 if absf(ty) > 5.0 else 10.5, ty)
		safe_poly(c, _ellipse(tp, 3.4, 3.0), Color(hot, a))
		spike(c, tp + Vector2(2.0, 0), Vector2(1.0, ty * 0.03).normalized(), 12.0, 2.8, Color(core, a))
	# 손목의 금 팔찌 두 줄
	var gold := Color(1.0, 0.8, 0.3, a)
	c.draw_line(Vector2(-13, -9), Vector2(-13, 9), gold, 3.0)
	c.draw_line(Vector2(-17, -8), Vector2(-17, 8), Color(gold, 0.7 * a), 1.5)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _ellipse(cen: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 14:
		var t2 := float(i) / 14.0 * TAU
		pts.append(cen + Vector2(cos(t2) * rx, sin(t2) * ry))
	return pts


## 양 끝이 뾰족하고 살짝 휜 칼날 모양 띠 (참격 줄기). bow = 휨 정도(굵기 대비)
static func blade(c: CanvasItem, p0: Vector2, p1: Vector2, w: float, col: Color, bow := 0.35) -> void:
	if w < 0.4 or p0.distance_to(p1) < 2.0:
		return
	var d := (p1 - p0).normalized()
	var n := d.orthogonal()
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in 9:
		var f := float(i) / 8.0
		var q := p0.lerp(p1, f) + n * sin(f * PI) * w * bow
		var ww := w * pow(sin(f * PI), 0.7)
		top.append(q + n * ww * 0.5)
		bot.append(q - n * ww * 0.5)
	bot.reverse()
	top.append_array(bot)
	safe_poly(c, top, col)


## 의태 돌진(변신 중 대시): 세라를 감싸고 앞으로 뛰어드는 거대한 푸른 여우 정령 + 뒤로 감기는 바람 줄기
class SpiritDash extends Base:
	var dir := 1
	var follow: Node2D

	func _init() -> void:
		life = PData.MIMIC_TIME + 0.22
		z_index = 7
		fox = true

	func _tick(_d: float) -> void:
		if is_instance_valid(follow) and t < PData.MIMIC_TIME:
			global_position = follow.global_position

	func _draw() -> void:
		var run := clampf(t / PData.MIMIC_TIME, 0.0, 1.0)
		var a := clampf(t / 0.05, 0.0, 1.0) * (1.0 - clampf((t - PData.MIMIC_TIME) / 0.22, 0.0, 1.0))
		var core := PData.FOX_CORE
		var hot := PData.FOX_HOT
		var mid := PData.FOX_MID
		var dark := PData.FOX_DARK
		var stretch := 1.0 + 0.15 * sin(run * PI)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir * stretch, 1.0))
		# 뒤로 감기는 바람 줄기(긴 초승달 여러 겹)
		for i in 6:
			var r := 70.0 + i * 13.0
			var y := -30.0 + (float(i) - 2.5) * 7.0
			PVfx.crescent(self, Vector2(20, y + r * 0.0), r, PI - 0.55 + i * 0.03, PI + 0.5 - i * 0.05, 5.0 - i * 0.5, Color(hot if i % 2 == 0 else mid, 0.55 * a), 18)
		# 흩날리는 꼬리 셋
		for i in 3:
			var wv := sin(t * 26.0 + i * 1.7) * 6.0
			var ty := -32.0 + (float(i) - 1.0) * 10.0
			PVfx.safe_poly(self, PackedVector2Array([Vector2(-26, ty - 6), Vector2(-62, ty - 12 + wv), Vector2(-96, ty - 4 + wv * 1.5), Vector2(-64, ty + 4 + wv), Vector2(-26, ty + 6)]), Color(mid, 0.6 * a))
			PVfx.safe_poly(self, PackedVector2Array([Vector2(-30, ty - 2), Vector2(-70, ty - 4 + wv), Vector2(-30, ty + 3)]), Color(hot, 0.7 * a))
		# 몸통 (앞으로 쭉 뻗은 도약 자세)
		var body := PackedVector2Array([Vector2(-34, -40), Vector2(0, -50), Vector2(34, -48), Vector2(44, -36), Vector2(30, -22), Vector2(-6, -20), Vector2(-32, -24)])
		PVfx.safe_poly(self, body, Color(dark, 0.55 * a))
		PVfx.safe_poly(self, PackedVector2Array([Vector2(-26, -40), Vector2(4, -46), Vector2(32, -44), Vector2(24, -32), Vector2(-20, -30)]), Color(mid, 0.6 * a))
		# 머리·귀·주둥이(벌린 턱)·빛나는 눈
		PVfx.safe_poly(self, PackedVector2Array([Vector2(30, -50), Vector2(36, -72), Vector2(44, -54), Vector2(52, -70), Vector2(54, -50), Vector2(76, -42), Vector2(56, -36), Vector2(72, -30), Vector2(46, -28), Vector2(32, -36)]), Color(hot, 0.8 * a))
		PVfx.safe_poly(self, PackedVector2Array([Vector2(36, -48), Vector2(54, -46), Vector2(70, -41), Vector2(48, -38)]), Color(core, 0.85 * a))
		draw_circle(Vector2(52, -46), 2.4, Color(1, 1, 1, a))
		# 앞다리는 앞으로, 뒷다리는 뒤로 쭉
		draw_line(Vector2(28, -26), Vector2(62, -12), Color(hot, 0.8 * a), 5.0)
		draw_line(Vector2(20, -24), Vector2(52, -6), Color(mid, 0.7 * a), 4.0)
		draw_line(Vector2(-24, -26), Vector2(-60, -14), Color(hot, 0.8 * a), 5.0)
		draw_line(Vector2(-18, -24), Vector2(-50, -8), Color(mid, 0.7 * a), 4.0)
		# 빛의 결 (몸을 가로지르는 흰 선)
		for i in 4:
			var y := -44.0 + i * 5.5
			draw_line(Vector2(-30 + i * 6, y), Vector2(40 - i * 4, y - 2), Color(core, 0.55 * a), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
