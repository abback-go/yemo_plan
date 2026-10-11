class_name BlightVine
extends StaticBody2D
## 흰 역병 덩굴 (docs/archive/sera/chapter3.md 5절·7.3절 — 정화 게이트). 하얗게 굳은 기하학 덩굴이 길을 막는다(벽처럼 막음).
## 불 종류 공격(화염탄·불기둥·화염 폭풍·폭주·여우불·방벽·되쏘기·유성·불사조)에 hp번 맞으면 정화된다:
## 흰 결정이 금 가며 타서 떨어지고 → 잠깐 초록 새순이 돋았다가 사라짐 → 길이 열림. 동료 공격(ally)은 통하지 않는다.
## 정화 기록: done_flag(주면) 또는 "pure_<방ID>_<id>". 처음 정화할 때 first 대본 실행(있으면).
## need(플래그 식)가 서기 전에는 불이 흰 결정에 먹혀 튕겨 나간다(달샘에서 "잠재우는 불"을 배우기 전 — 대본 hint 실행).
## 방 데이터: {t = "blight_vine", x, y, w = 1, h = 4, hp = 3, done_flag = "", first = "", need = "", hint = ""}

const WHITE := Color("#e6e6f0")
const SHADE := Color("#9c9cae")
const GREEN := Color("#7ab450")

var size_px := Vector2(16, 64)
var hits_needed := 3
var key := ""
var first := ""
var need := ""
var hint := ""
var _hits := 0
var _bounce := 0.0
var _purify := -1.0
var _t := 0.0
var _shake := 0.0
var _shape: CollisionShape2D
var _hurt: Area2D
var _seed := 0


func setup(room: Room, e: Dictionary, eid: String) -> void:
	size_px = Vector2(float(e.get("w", 1)), float(e.get("h", 4))) * 16.0
	position = room.tile_pos(e)
	hits_needed = int(e.get("hp", 3))
	key = String(e.get("done_flag", "pure_%s_%s" % [room.data.id, eid]))
	first = String(e.get("first", ""))
	need = String(e.get("need", ""))
	hint = String(e.get("hint", ""))
	_seed = hash(room.data.id + eid)
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	add_to_group(&"blight_vine")
	if GameState.has_flag(key):
		_purify = 99.0
		return
	add_to_group(&"pillar_target")
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size_px
	_shape.shape = rs
	_shape.position = size_px * 0.5
	add_child(_shape)
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = size_px + Vector2(8, 0)
	cs.shape = r2
	cs.position = size_px * 0.5
	_hurt.add_child(cs)
	add_child(_hurt)
	z_index = -1


func is_alive() -> bool:
	return _purify < 0.0


func is_on_floor() -> bool:
	return true


func take_hit(hit: Hit) -> void:
	if _purify >= 0.0 or hit.kind == &"ally":
		return
	if not RoomData.cond_ok(need):
		# 아직은 불이 흰 결정에 먹혀 튕겨 나간다
		if _bounce <= 0.0:
			_bounce = 1.0
			Ch3Sfx.play(&"ch3_glass", -6.0, 0.1)
			Fx.burst(hit.source_pos if hit.source_pos != Vector2.ZERO else global_position, 10, {spread = 120.0, speed_min = 40.0,
				speed_max = 120.0, lifetime = 0.3, gradient = Palette.fade_gradient(WHITE), size_min = 1.0, size_max = 2.0})
			if hint != "" and Story.has_script(hint) and not Story.busy():
				Story.run(hint, true)
		return
	_hits += 1
	_shake = 0.25
	Ch3Sfx.play(&"ch3_crystal_break", -8.0, 0.15)
	Fx.burst(global_position + Vector2(size_px.x * 0.5, size_px.y * randf_range(0.2, 0.8)), 10, {spread = 160.0, speed_min = 30.0,
		speed_max = 90.0, lifetime = 0.4, gradient = Palette.fade_gradient(WHITE), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 200)})
	if _hits >= hits_needed:
		_start_purify()


func _start_purify() -> void:
	_purify = 0.0
	GameState.set_flag(key)
	_shape.set_deferred("disabled", true)
	_hurt.set_deferred("monitorable", false)
	remove_from_group(&"pillar_target")
	Ch3Sfx.play(&"ch3_purify", 0.0, 0.0)
	Sfx.play(&"ignite", 0.0, 0.0)
	Fx.flash(Color(0.9, 1.0, 0.8, 0.15), 0.25)
	Fx.burst(global_position + size_px * 0.5, 30, {box = size_px * 0.5, direction = Vector2.UP, spread = 50.0, speed_min = 20.0,
		speed_max = 80.0, lifetime = 0.9, gravity = Vector2(0, -60)})
	if first != "" and Story.has_script(first) and not GameState.has_flag("seen_" + first):
		GameState.set_flag("seen_" + first)
		Story.run(first, true)


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(_shake - delta, 0.0)
	_bounce = maxf(_bounce - delta, 0.0)
	if _purify >= 0.0 and _purify < 99.0:
		_purify += delta
	queue_redraw()


func _draw() -> void:
	if _purify >= 2.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var sx := sin(_t * 60.0) * 1.5 * _shake
	var burn := clampf(_purify / 0.9, 0.0, 1.0) if _purify >= 0.0 else 0.0
	var sprout := clampf((_purify - 0.6) / 0.6, 0.0, 1.0) if _purify >= 0.0 else 0.0
	var fade := 1.0 - clampf((_purify - 1.4) / 0.6, 0.0, 1.0) if _purify >= 0.0 else 1.0
	var crack := float(_hits) / maxf(hits_needed, 1)
	# 굳은 줄기 (직선 마디, 60도로만 꺾임) 여러 가닥
	var strands := maxi(int(size_px.x / 6.0), 2)
	for s in strands:
		var x := size_px.x * (s + 0.5) / strands + sx
		var p := Vector2(x, size_px.y)
		var pts := PackedVector2Array([p])
		while p.y > 0.0:
			var step := rng.randf_range(6, 12)
			var dx := (1.0 if rng.randf() < 0.5 else -1.0) * step * 0.5
			p = Vector2(clampf(p.x + dx, 1.0, size_px.x - 1.0), p.y - step)
			pts.append(p)
		var col := WHITE.lerp(Palette.FIRE_OUT, burn * 0.7)
		col.a = fade * (1.0 - burn * 0.6)
		draw_polyline(pts, Color(SHADE, col.a), 4.0)
		draw_polyline(pts, col, 2.0)
		# 마디의 육각 결정
		for i in range(1, pts.size(), 2):
			var c := pts[i]
			var hp := PackedVector2Array()
			for k in 6:
				var a := TAU * k / 6.0 + PI / 6.0
				hp.append(c + Vector2(cos(a), sin(a)) * 3.0)
			draw_colored_polygon(hp, col)
			if crack > 0.0 and (i + s) % 3 == 0:
				draw_line(c + Vector2(-2, -2), c + Vector2(2, 2), Color(0.2, 0.2, 0.3, col.a * crack), 1.0)
	# 흰빛 맥동 (바깥 신들의 숨)
	if _purify < 0.0:
		var k2 := clampf(sin(_t * 1.3) * 1.4, 0.0, 1.0)
		draw_rect(Rect2(Vector2(sx, 0), size_px), Color(1, 1, 1, 0.05 * k2))
	# 정화: 타는 불꽃 → 초록 새순
	if burn > 0.0 and burn < 1.0:
		for i in int(size_px.y / 8.0):
			var y := size_px.y - i * 8.0
			var h := 5.0 + 4.0 * sin(_t * 30.0 + i)
			draw_colored_polygon(PackedVector2Array([Vector2(size_px.x * 0.2, y), Vector2(size_px.x * 0.5, y - h), Vector2(size_px.x * 0.8, y)]), Color(Palette.FIRE_MID, (1.0 - burn) * 0.8))
	if sprout > 0.0:
		for i in 4:
			var b := Vector2(size_px.x * (0.2 + i * 0.2), size_px.y)
			var tip := b + Vector2(sin(i * 2.0) * 3.0, -10.0 * sprout - i * 2.0)
			draw_line(b, tip, Color(GREEN, fade), 1.0)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(3, -1), tip + Vector2(1, 2)]), Color(GREEN.lightened(0.2), fade))
