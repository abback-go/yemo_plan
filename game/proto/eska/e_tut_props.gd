class_name ETutProps
extends RefCounted
## 튜토리얼 지형·장치 (모두 코드 그림, 배경 EScenery와 같은 돌·보라 빛):
## Ledge 돌 턱 · Gate 봉인 문(닫히면 막힘, 열릴 때 문양이 깨짐) · Veil 장막(순간이동으로만 통과) · Pit 공허 틈 · Lantern 확인점 등불.

const STONE := EScenery.STONE
const STONE_TOP := EScenery.STONE_TOP
const CRACK := EScenery.CRACK
const INK := EVfx.INK
const PLUM := EVfx.PLUM
const BODY := EVfx.BODY
const MAGENTA := EVfx.MAGENTA
const EDGE := EVfx.EDGE
const PALE := EVfx.PALE


## 막힌 사각형 몸 (StaticBody2D, 바닥 층 1)
static func body(r: Rect2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.get_center()
	b.add_child(cs)
	return b


## 돌 턱(Ledge): 윗면에 밝은 선 + 세로 줄눈 + 아래로 갈수록 어둡게
class Ledge extends PDraw.Canvas:
	var rect := Rect2()

	func _ready() -> void:
		z_index = -1
		add_child(ETutProps.body(rect))

	func _paint() -> void:
		var r := rect
		pd.rect_grad(r, STONE.lightened(0.04), STONE.darkened(0.3))
		pd.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), STONE_TOP)
		pd.draw_rect(Rect2(r.position + Vector2(0, 2), Vector2(r.size.x, 1)), Color(CRACK, 0.25))
		var x := r.position.x + 18.0
		var i := 0
		while x < r.end.x - 6.0:
			pd.draw_line(Vector2(x, r.position.y + 3), Vector2(x, minf(r.position.y + 12.0 + float(i % 3) * 6.0, r.end.y)), Color(0, 0, 0, 0.5), 1.0)
			x += 26.0 + float((i * 7) % 11)
			i += 1
		pd.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color(STONE_TOP, 0.6))
		pd.draw_rect(Rect2(Vector2(r.end.x - 1, r.position.y), Vector2(1, r.size.y)), Color(0, 0, 0, 0.5))


## 봉인 문: 돌 받침·머릿돌 사이에 보라 결계(폭 18, 높이 h)가 서고 문양이 위로 흐른다.
## open() — 결계가 위에서부터 걷히며 깨짐(받침·머릿돌은 남음) / close() — 아래에서 솟아오름
class Gate extends PDraw.Canvas:
	const FW := 18.0
	var h := 150.0
	var closed := true
	var _k := 1.0 ## 1 = 닫힘, 0 = 열림
	var _t := 0.0
	var _body: StaticBody2D

	func _ready() -> void:
		z_index = 1
		_k = 1.0 if closed else 0.0
		if closed:
			_add_body()

	func _add_body() -> void:
		if _body == null:
			_body = ETutProps.body(Rect2(-FW * 0.5, -h, FW, h))
			add_child(_body)

	func open() -> void:
		if not closed:
			return
		closed = false
		if _body:
			_body.queue_free()
			_body = null
		EVfx.dark_burst(global_position + Vector2(0, -h * 0.5), 30.0)
		EVfx.shards(global_position + Vector2(0, -h * 0.5), 18, 160.0, Vector2(10, h * 0.6), 80.0)
		Fx.shake(0.6, 0.25)
		Sfx.play(&"crumble", -2.0)
		Sfx.play(&"es_tear", -4.0)

	func close() -> void:
		if closed:
			return
		closed = true
		_add_body()
		Fx.shake(0.4, 0.18)
		Sfx.play_pitch(&"slam", 1.3, -6.0)

	func _process(delta: float) -> void:
		_t += delta
		_k = move_toward(_k, 1.0 if closed else 0.0, delta * (2.2 if closed else 1.6))
		queue_redraw()

	func _paint() -> void:
		# 돌 받침 · 머릿돌 (늘 있음)
		pd.draw_rect(Rect2(-15, -10, 30, 10), STONE.lightened(0.06))
		pd.draw_rect(Rect2(-15, -10, 30, 2), STONE_TOP)
		pd.draw_rect(Rect2(-13, -h - 10, 26, 9), STONE.lightened(0.06))
		pd.draw_rect(Rect2(-13, -h - 10, 26, 2), STONE_TOP)
		var a := clampf(_k * 1.4, 0.0, 1.0)
		var rune := 0.35 + 0.65 * a
		pd.draw_colored_polygon(PackedVector2Array([Vector2(0, -h - 9), Vector2(3, -h - 5.5), Vector2(0, -h - 2), Vector2(-3, -h - 5.5)]), Color(MAGENTA.lerp(EDGE, 0.3), rune))
		pd.draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(3, -5), Vector2(0, -2), Vector2(-3, -5)]), Color(MAGENTA, rune * 0.8))
		if _k <= 0.0:
			return
		# 결계: 닫힐 때는 아래에서 솟고, 열릴 때는 위에서부터 걷힌다 (둘 다 윗끝이 -10 - (h-10)·k)
		var bot := -10.0
		var top := bot - (h - 11.0) * _k
		var mid := (top + bot) * 0.5
		pd.glow(Vector2(0, mid), h * 0.45, Color(MAGENTA, 0.16 * a), 0.0)
		pd.rect_hgrad(Rect2(-FW * 0.5, top, FW * 0.5, bot - top), Color(PLUM, 0.15 * a), Color(BODY, 0.55 * a))
		pd.rect_hgrad(Rect2(0, top, FW * 0.5, bot - top), Color(BODY, 0.55 * a), Color(PLUM, 0.15 * a))
		# 위로 흐르는 문양 세 줄 (마름모 + 가는 획)
		for col in 3:
			var x := (float(col) - 1.0) * 5.0
			var step := 16.0 + float(col) * 3.0
			var off := fmod(_t * (22.0 + float(col) * 6.0), step)
			var y := bot - 4.0 - off
			while y > top + 3.0:
				var f := 0.5 + 0.5 * sin(_t * 3.0 + y * 0.09 + float(col))
				var c := Color(MAGENTA.lerp(EDGE, f * 0.6), (0.3 + 0.55 * f) * a)
				var s := 2.0 if col == 1 else 1.4
				pd.draw_colored_polygon(PackedVector2Array([Vector2(x, y - s - 1), Vector2(x + s, y), Vector2(x, y + s + 1), Vector2(x - s, y)]), c)
				y -= step
		pd.draw_line(Vector2(-FW * 0.5, top), Vector2(-FW * 0.5, bot), Color(EDGE, 0.5 * a), 1.0)
		pd.draw_line(Vector2(FW * 0.5, top), Vector2(FW * 0.5, bot), Color(EDGE, 0.5 * a), 1.0)
		if not closed:
			# 걷히는 윗끝: 밝은 금
			pd.draw_line(Vector2(-FW * 0.6, top), Vector2(FW * 0.6, top), Color(EDGE, a), 2.0)


## 장막: 반투명 보라 막이 일렁인다. 걸어서 닿으면 물결치며 밀어냄 — 순간이동으로만 지나간다 (몸이 아니라 직접 밀어내서 순간이동 판정에 걸리지 않음)
class Veil extends PDraw.Canvas:
	const W := 20.0
	var h := 300.0
	var eska: EEska
	var _t := 0.0
	var _ripple := 0.0
	var _ripple_y := 0.0
	var passed := false

	func _ready() -> void:
		z_index = 3

	func _physics_process(delta: float) -> void:
		_t += delta
		_ripple = maxf(_ripple - delta * 2.5, 0.0)
		if not is_instance_valid(eska):
			eska = EEska.find(get_tree())
			return
		var x := global_position.x
		var r := eska.hurt_rect()
		if eska.global_position.x > x + W:
			passed = true
		if r.end.x > x - W * 0.5 and r.position.x < x + W * 0.5 and eska.st != EEska.St.BLINK:
			# 몸이 더 많이 걸친 쪽으로 밀어냄
			var side := 1.0 if eska.global_position.x > x else -1.0
			eska.global_position.x = x + side * (W * 0.5 + EEska.SIZE.x * 0.5 + 1.0)
			eska.velocity.x = side * 160.0
			if _ripple < 0.5:
				_ripple = 1.0
				_ripple_y = eska.center().y - global_position.y
				Sfx.play_pitch(&"ward", 1.4, -12.0)
				EVfx.dark_bits(Vector2(x, eska.center().y), 5, 90.0, Vector2(side, 0), 60.0, 0.3)
		queue_redraw()

	func _paint() -> void:
		var n := 18
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in n + 1:
			var y := -h + h * float(i) / float(n)
			var wob := sin(_t * 2.6 + y * 0.05) * 2.0
			var rip := _ripple * 6.0 * exp(-absf(y - _ripple_y) / 30.0) * sin(_t * 30.0)
			left.append(Vector2(-W * 0.5 + wob + rip, y))
			right.append(Vector2(W * 0.5 + wob + rip, y))
		pd.glow(Vector2(0, -h * 0.4), h * 0.5, Color(BODY, 0.08), 0.0)
		pd.strip_grad(left, right, Color(PLUM, 0.15), Color(BODY, 0.45))
		for i in 3:
			var x := -W * 0.5 + W * (float(i) + 0.5) / 3.0
			var pts := PackedVector2Array()
			for j in n + 1:
				var y := -h + h * float(j) / float(n)
				pts.append(Vector2(x + sin(_t * (3.0 + float(i)) + y * 0.07 + float(i)) * 3.0, y))
			pd.draw_polyline(pts, Color(MAGENTA, 0.35), 1.0)
		pd.draw_polyline(left, Color(EDGE, 0.4), 1.0)
		pd.draw_polyline(right, Color(EDGE, 0.4), 1.0)


## 공허 틈: 바닥이 끊긴 자리 — 양옆 돌벽 단면, 아래는 끝없는 어둠 속 보랏빛 소용돌이와 빨려 드는 빛 알갱이
class Pit extends PDraw.Canvas:
	var w := 250.0
	var depth := 260.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _paint() -> void:
		pd.draw_rect(Rect2(0, -1, w, depth), Color(0.02, 0.0, 0.04))
		var c := Vector2(w * 0.5, 120.0)
		pd.glow(c, w * 0.55, Color(PLUM, 0.5), 0.0)
		pd.glow(c, w * 0.22, Color(MAGENTA, 0.18 + 0.06 * sin(_t * 2.0)), 0.0)
		# 소용돌이 팔 (납작한 타원 호 셋이 돈다)
		for i in 3:
			var a0 := _t * 0.8 + float(i) * TAU / 3.0
			pd.draw_set_transform(c, 0.0, Vector2(1.0, 0.32))
			pd.draw_arc(Vector2.ZERO, w * (0.18 + 0.1 * float(i)), a0, a0 + 2.2, 16, Color(MAGENTA, 0.22), 2.0)
		pd.draw_set_transform(Vector2.ZERO)
		# 빛 알갱이 (가장자리에서 가운데 아래로 빨려 듦)
		for i in 16:
			var f := fmod(_t * 0.3 + float(i) / 16.0, 1.0)
			var ang := float(i) * 2.4 + _t * 1.2
			var p := c + Vector2(cos(ang) * w * 0.48 * (1.0 - f), -100.0 * (1.0 - f) + sin(ang) * 10.0 * (1.0 - f))
			pd.draw_rect(Rect2(p.round(), Vector2(1, 1) * (2.0 if i % 3 == 0 else 1.0)), Color(EDGE.lerp(MAGENTA, f), 0.75 * (1.0 - f)))
		# 양옆 돌벽 단면 + 위로 번지는 마젠타 가장자리
		for sd in 2:
			var x := 0.0 if sd == 0 else w - 8.0
			pd.rect_grad(Rect2(x, -1, 8, 70), STONE.lightened(0.05), Color(STONE, 0.0))
			pd.draw_rect(Rect2(x + (7.0 if sd == 0 else 0.0), -1, 1, 50), Color(MAGENTA, 0.5))
		pd.rect_grad(Rect2(0, -1, w, 24), Color(0, 0, 0, 0.8), Color(0, 0, 0, 0.0))
		pd.draw_rect(Rect2(-2, -2, 10, 2), STONE_TOP)
		pd.draw_rect(Rect2(w - 8, -2, 10, 2), STONE_TOP)


## 확인점 등불: 꺼진 돌 등 → light() 하면 보라 불꽃이 확 켜지고 계속 일렁임
class Lantern extends PDraw.Canvas:
	var lit := false
	var _t := 0.0
	var _flare := 0.0

	func _ready() -> void:
		z_index = -1

	func light() -> void:
		if lit:
			return
		lit = true
		_flare = 1.0
		Sfx.play(&"checkpoint", -6.0)
		EVfx.pixels(global_position + Vector2(0, -34), 10, 70.0, Vector2.UP, 70.0, 0.5)

	func _process(delta: float) -> void:
		_t += delta
		_flare = maxf(_flare - delta * 1.5, 0.0)
		if lit or _flare > 0.0:
			queue_redraw()

	func _paint() -> void:
		# 돌 기둥 + 머리
		pd.draw_rect(Rect2(-3, -26, 6, 26), STONE.lightened(0.05))
		pd.draw_rect(Rect2(-6, -2, 12, 2), STONE_TOP)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(-7, -26), Vector2(7, -26), Vector2(5, -38), Vector2(-5, -38)]), STONE.lightened(0.08))
		pd.draw_rect(Rect2(-8, -40, 16, 2), STONE_TOP)
		if not lit:
			pd.draw_rect(Rect2(-2, -35, 4, 6), Color(PLUM, 0.6))
			return
		var fl := 1.0 + 0.12 * sin(_t * 9.0) + 0.08 * sin(_t * 23.0)
		pd.glow(Vector2(0, -32), (22.0 + 30.0 * _flare) * fl, Color(MAGENTA, 0.22 + 0.3 * _flare), 0.0)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(-3, -29), Vector2(0, -38.0 - 3.0 * fl), Vector2(3, -29)]), Color(BODY, 0.95))
		pd.draw_colored_polygon(PackedVector2Array([Vector2(-1.5, -29.5), Vector2(0, -35.0 - 2.0 * fl), Vector2(1.5, -29.5)]), EDGE)
