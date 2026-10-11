extends Node2D
## 아우렐리아 보스 그림: 전용 몸 그림(CharacterVisual "aurelia", 자세는 보스가 정함) + 잔상 + 화면을 가르는 예고·빛 효과.
##   돌진 예고: 투기장 끝에서 끝까지 금빛 띠(가장자리 붉음) + 돌진 방향으로 흐르는 꺾쇠, 끝 무렵 하얗게 깜빡
##   돌진 자국: 지나간 띠에 금빛(폭주면 흰금) 잔광
##   심판의 창: 하늘에 화면만 한 빛의 창 + 바닥의 붉은 위험 / 파란 "그늘"(안전) + 꽂힌 뒤 양쪽으로 달리는 흰금 충격파 벽
## 가산 합성 층(_glow)과 보통 층(_shade, 그늘·어두움)을 따로 둔다.

const H := preload("res://enemies/ch4/holy.gd")
const DANGER := Color("#ff3b3b")

var enemy: AureliaBoss
var ch: CharacterVisual
var _glow: GlowDraw
var _shade: ShadeDraw
var _wake := 0.0
var _wake_from := 0.0
var _wake_to := 0.0
var _wake_y := 0.0
var _mote_t := 0.0


class GlowDraw extends Node2D:
	var v: Node2D

	func _ready() -> void:
		material = Fx.add_material
		top_level = true
		z_index = 7

	func _process(_d: float) -> void:
		global_position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		if v and is_instance_valid(v):
			v.call("draw_glow", self)


class ShadeDraw extends Node2D:
	var v: Node2D

	func _ready() -> void:
		top_level = true
		z_index = -1

	func _process(_d: float) -> void:
		global_position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		if v and is_instance_valid(v):
			v.call("draw_shade", self)


## 잔상: 그 순간의 자세를 금빛으로 남기고 사라짐
class Ghost extends Node2D:
	var life := 0.24
	var _t := 0.0
	var col := Color(1.0, 0.85, 0.45, 0.55)

	func _process(delta: float) -> void:
		_t += delta
		modulate = Color(col, col.a * (1.0 - _t / life))
		if _t >= life:
			queue_free()


func _ready() -> void:
	ch = CharacterVisual.new()
	ch.setup("aurelia")
	add_child(ch)
	_glow = GlowDraw.new()
	_glow.v = self
	add_child(_glow)
	_shade = ShadeDraw.new()
	_shade.v = self
	add_child(_shade)


func _process(delta: float) -> void:
	if enemy == null:
		return
	ch.scale.x = float(enemy.facing)
	var white := enemy.flash_amount() > 0.0
	ch.modulate = Color(2.0, 2.0, 2.0) if white else Color.WHITE
	var halo := 1.0
	if enemy.halo_out:
		halo = 0.001
	elif enemy.state == AureliaBoss.S.HALO_WIND:
		halo = 1.0 + 0.5 * enemy.progress()
	elif enemy.state in [AureliaBoss.S.JUDG_RISE, AureliaBoss.S.JUDG_WIND]:
		halo = 2.2
	ch.set_meta("halo", halo)
	if enemy.state == AureliaBoss.S.CHARGE:
		_wake = 1.0
		_wake_from = enemy.charge_from
		_wake_to = enemy.global_position.x
		_wake_y = enemy.charge_y
	else:
		_wake = maxf(_wake - delta * 1.6, 0.0)
	# 폭주: 흰빛 알갱이가 몸에서 피어오름
	if enemy.berserk and enemy.is_alive():
		_mote_t -= delta
		if _mote_t <= 0.0:
			_mote_t = 0.12
			Fx.burst(enemy.global_position + Vector2(randf_range(-8, 8), -randf_range(4, 40)), 1, {
				direction = Vector2.UP, spread = 20.0, speed_min = 10.0, speed_max = 30.0, lifetime = 0.9,
				gradient = H.white_grad(), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -20), add = true,
			})


func afterimage() -> void:
	var g := Ghost.new()
	var cv := CharacterVisual.new()
	cv.setup("aurelia")
	cv.set_pose(ch.pose)
	cv.pose_t = 1.0
	if ch.has_meta("berserk"):
		cv.set_meta("berserk", ch.get_meta("berserk"))
	cv.set_meta("halo", 0.001)
	cv.scale.x = ch.scale.x
	g.add_child(cv)
	g.global_position = global_position
	g.col = Color(1.0, 0.85, 0.45, 0.6) if not enemy.berserk else Color(0.95, 0.97, 1.0, 0.6)
	g.z_index = 1
	Fx.effect_parent().add_child(g)


## 가산 합성 층 (전역 좌표)
func draw_glow(c: CanvasItem) -> void:
	var e := enemy
	if e == null or not is_instance_valid(e):
		return
	var t := e._t
	var gold := Color(1.0, 0.86, 0.45) if not e.berserk else Color(1.0, 0.97, 0.88)
	# 돌진 예고 띠
	if e.state == AureliaBoss.S.CHARGE_WIND:
		var k := e.progress()
		var y := e.charge_y
		var half := AureliaBoss.CHARGE_BAND * 0.5
		var x0 := e.arena_l
		var x1 := e.arena_r
		var pulse := 0.5 + 0.5 * sin(t * 26.0)
		var late := k > 0.75
		var fill := Color(gold, 0.08 + 0.14 * k)
		if late and pulse > 0.5:
			fill = Color(1, 1, 1, 0.25)
		c.draw_rect(Rect2(x0, y - half, x1 - x0, half * 2.0), fill)
		c.draw_line(Vector2(x0, y - half), Vector2(x1, y - half), Color(DANGER, 0.45 + 0.4 * pulse), 2.0)
		c.draw_line(Vector2(x0, y + half), Vector2(x1, y + half), Color(DANGER, 0.45 + 0.4 * pulse), 2.0)
		c.draw_line(Vector2(x0, y), Vector2(x1, y), Color(gold, 0.5 + 0.5 * k), 1.0 + 2.0 * k)
		# 돌진 방향으로 흐르는 꺾쇠
		var dir := float(e.charge_dir)
		var sp := 34.0
		var off := fmod(t * 240.0, sp)
		var x := x0 + off if dir > 0 else x1 - off
		while (x < x1 if dir > 0 else x > x0):
			c.draw_polyline(PackedVector2Array([Vector2(x - dir * 6, y - 8), Vector2(x, y), Vector2(x - dir * 6, y + 8)]), Color(gold, 0.35 + 0.4 * k), 2.0)
			x += dir * sp
		# 창끝에 모이는 빛
		var tip := e.global_position + Vector2(dir * 56, -18)
		c.draw_circle(tip, 4.0 + 8.0 * k, Color(gold, 0.35))
		c.draw_circle(tip, 2.0 + 3.0 * k, Color(1, 1, 1, 0.8))
	# 돌진 자국
	if _wake > 0.0:
		var y2 := _wake_y
		var a0 := minf(_wake_from, _wake_to)
		var a1 := maxf(_wake_from, _wake_to)
		c.draw_rect(Rect2(a0, y2 - 14, a1 - a0, 28), Color(gold, 0.18 * _wake))
		c.draw_rect(Rect2(a0, y2 - 5, a1 - a0, 10), Color(gold, 0.4 * _wake))
		c.draw_line(Vector2(a0, y2), Vector2(a1, y2), Color(1, 1, 1, 0.8 * _wake), 2.0)
	# 광륜 던지기 예고 (붉은 테)
	if e.state == AureliaBoss.S.HALO_WIND:
		var k2 := e.progress()
		var hc := e.global_position + Vector2(-3.8 * e.facing, -38)
		c.draw_arc(hc, 9.0 + 4.0 * k2, 0, TAU, 24, Color(DANGER, 0.4 + 0.5 * k2), 2.0)
	# 심판의 창
	if e.state in [AureliaBoss.S.JUDG_RISE, AureliaBoss.S.JUDG_WIND, AureliaBoss.S.JUDG_FALL]:
		var k3 := e.progress() if e.state == AureliaBoss.S.JUDG_WIND else (0.0 if e.state == AureliaBoss.S.JUDG_RISE else 1.0)
		var jx := e.jud_x
		var fy := e.jud_floor
		if e.state != AureliaBoss.S.JUDG_FALL:
			# 하늘에 만들어지는 거대한 창 (점점 내려오며 밝아짐)
			var tip_y := lerpf(e.top_y + 30.0, fy - 150.0, k3 * k3)
			var L := 220.0
			var W := 34.0
			var a := 0.35 + 0.5 * k3
			c.draw_rect(Rect2(jx - W * 1.6, tip_y - L * 1.5, W * 3.2, L * 1.5), Color(gold, 0.06 + 0.06 * k3))
			c.draw_colored_polygon(PackedVector2Array([Vector2(jx, tip_y), Vector2(jx - W * 0.5, tip_y - L * 0.3), Vector2(jx - W * 0.2, tip_y - L), Vector2(jx + W * 0.2, tip_y - L), Vector2(jx + W * 0.5, tip_y - L * 0.3)]), Color(gold, a))
			for s: float in [-1.0, 1.0]:
				c.draw_colored_polygon(PackedVector2Array([Vector2(jx + s * W * 0.45, tip_y - L * 0.28), Vector2(jx + s * W * 1.5, tip_y - L * 0.5), Vector2(jx + s * W * 0.4, tip_y - L * 0.45)]), Color(gold, a * 0.8))
			c.draw_line(Vector2(jx, tip_y - L), Vector2(jx, tip_y), Color(1, 1, 1, a), 3.0)
			# 꽂힐 자리: 하얀 기둥 예고 (바깥 신들의 힘 — 굵게 깜빡임)
			var blink := 0.5 + 0.5 * signf(sin(t * 18.0 + k3 * 10.0))
			c.draw_rect(Rect2(jx - 3, tip_y, 6, fy - tip_y), Color(1, 1, 1, (0.15 + 0.35 * k3) * blink))
			c.draw_rect(Rect2(jx - 24, fy - 4, 48, 4), Color(DANGER, 0.5 + 0.4 * blink))
	# 충격파 벽
	if e.jud_wave >= 0.0:
		var r := e.jud_wave
		var fy2 := e.jud_floor
		for s: float in [-1.0, 1.0]:
			var x := e.jud_x + s * r
			if x < e.arena_l - 8.0 or x > e.arena_r + 8.0:
				continue
			c.draw_rect(Rect2(x - 6, fy2 - 90, 12, 90), Color(1, 1, 1, 0.75))
			c.draw_rect(Rect2(x - 18, fy2 - 110, 36, 110), Color(gold, 0.25))
			c.draw_rect(Rect2(minf(x, e.jud_x), fy2 - 40, absf(x - e.jud_x), 40), Color(gold, 0.08))


## 보통 층: 심판의 창 예고 중 화면을 어둡게 하고 바닥에 위험(붉음)·그늘(파랑) 표시
func draw_shade(c: CanvasItem) -> void:
	var e := enemy
	if e == null or not is_instance_valid(e):
		return
	if not (e.state in [AureliaBoss.S.JUDG_RISE, AureliaBoss.S.JUDG_WIND]):
		return
	var k := e.progress() if e.state == AureliaBoss.S.JUDG_WIND else 0.2
	var fy := e.jud_floor
	c.draw_rect(Rect2(e.arena_l - 400, e.top_y - 200, e.arena_r - e.arena_l + 800, fy - e.top_y + 300), Color(0.02, 0.01, 0.06, 0.35 * minf(k * 2.0, 1.0)))
	var pulse := 0.5 + 0.5 * sin(e._t * 10.0)
	c.draw_rect(Rect2(e.arena_l, fy - 6, e.arena_r - e.arena_l, 6), Color(DANGER, 0.35 + 0.25 * pulse))
	for span in e.jud_safe:
		var x0: float = span[0]
		var x1: float = span[1]
		c.draw_rect(Rect2(x0, fy - 40, x1 - x0, 40), Color(0.3, 0.55, 1.0, 0.18 + 0.12 * pulse))
		c.draw_rect(Rect2(x0, fy - 6, x1 - x0, 6), Color(0.45, 0.75, 1.0, 0.8))
