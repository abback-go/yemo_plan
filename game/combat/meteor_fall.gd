class_name MeteorFall
extends Node2D
## 유성 낙화 (고급 마법, docs/magic.md): 세라가 떠올라 하늘에 마법진을 열고(0.8초, 무적) 모든 마력을 바친다 →
## 하늘이 붉게 물들고 2.5초 동안 넓은 범위(가로 24T)에 유성이 쏟아진 뒤 마지막 큰 유성.
## Lv2 유성 10개, Lv3 15개 + 떨어진 자리에 불바다. 여우 모드면 푸른 유성(피해 1.2배).
## 맞는 대상: 적(GROUP_ENEMY) + 금빛 봉인석 등 그룹 "meteor_target" (Hit.kind = meteor).

const CAST := 0.8
const RAIN := 2.5

var player: Player
var tuning: Tuning
var level := 1
var fox := false
var _t := 0.0
var _schedule: Array = [] ## [시간, 큰 유성인가]
var _tint: ColorRect
var _layer: CanvasLayer
var _circle_pos := Vector2.ZERO
var _done_big := false


func setup(p: Player, p_tuning: Tuning, p_level: int, p_fox: bool) -> void:
	player = p
	tuning = p_tuning
	level = p_level
	fox = p_fox
	var n := tuning.meteor_count
	if level == 2:
		n = 10
	elif level >= 3:
		n = 15
	for i in n:
		_schedule.append([CAST + RAIN * float(i) / n + randf_range(-0.05, 0.05), false])
	_schedule.append([CAST + RAIN + 0.35, true])


func _ready() -> void:
	z_index = 8
	material = Fx.add_material
	_circle_pos = player.global_position + Vector2(0, -150)
	_layer = CanvasLayer.new()
	_layer.layer = 5
	_tint = ColorRect.new()
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(0.25, 0.4, 0.9, 0.0) if fox else Color(0.9, 0.2, 0.05, 0.0)
	_layer.add_child(_tint)
	add_child(_layer)
	Sfx.play(&"magic_learn", -4.0, 0.0)
	Fx.zoom_punch(0.06)


func _col() -> Color:
	return Color(0.45, 0.8, 1.0) if fox else Palette.FIRE_OUT


func _hot() -> Color:
	return Color(0.85, 0.97, 1.0) if fox else Palette.FIRE_HOT


func _physics_process(delta: float) -> void:
	_t += delta
	var tint_a := 0.0
	if _t < CAST:
		tint_a = 0.22 * _t / CAST
	elif _t < CAST + RAIN + 0.8:
		tint_a = 0.22
	else:
		tint_a = maxf(0.22 - (_t - CAST - RAIN - 0.8) * 0.5, 0.0)
	_tint.color.a = tint_a
	while not _schedule.is_empty() and _t >= float(_schedule[0][0]):
		var item: Array = _schedule.pop_front()
		_spawn_meteor(bool(item[1]))
	if _schedule.is_empty() and _t > CAST + RAIN + 1.4:
		queue_free()
	queue_redraw()


## 화면 범위 안 적을 차례로 노린다(없으면 세라 앞쪽 아무 곳)
func _pick_target(big: bool) -> Vector2:
	var half := tuning.meteor_width_t * 0.5 * GameConst.TILE
	var cands: Array = []
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en and en.is_alive() and absf(en.global_position.x - player.global_position.x) < half \
				and absf(en.global_position.y - player.global_position.y) < 12.0 * GameConst.TILE:
			cands.append(en)
	for m in get_tree().get_nodes_in_group(&"meteor_target"):
		var n2 := m as Node2D
		if n2 and absf(n2.global_position.x - player.global_position.x) < half:
			cands.append(n2)
	if big:
		var best: Node2D = null
		var hp_best := -1
		for c in cands:
			var hp_v: int = int(c.get("hp")) if c.get("hp") != null else 0
			if hp_v > hp_best:
				hp_best = hp_v
				best = c
		if best:
			return best.global_position
	if not cands.is_empty() and randf() < 0.75:
		var c2: Node2D = cands[randi() % cands.size()]
		return c2.global_position + Vector2(randf_range(-10, 10), 0)
	var x := player.global_position.x + randf_range(-half, half)
	return _ground(x)


func _ground(x: float) -> Vector2:
	var space := player.get_world_2d().direct_space_state
	var from := Vector2(x, player.global_position.y - 10.0 * GameConst.TILE)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 24.0 * GameConst.TILE), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	if r:
		return r.position
	return Vector2(x, player.global_position.y)


func _spawn_meteor(big: bool) -> void:
	var m := Meteor.new()
	m.owner_fall = self
	m.target = _pick_target(big)
	m.big = big
	var mult := Spells.dmg_mult("meteor") * (1.2 if fox else 1.0)
	m.damage = int(round((tuning.meteor_big_damage if big else tuning.meteor_damage) * mult))
	m.radius = tuning.meteor_radius_t * GameConst.TILE * (1.8 if big else 1.0)
	m.fox = fox
	m.burn = level >= 3
	m.material = Fx.add_material
	Fx.effect_parent().add_child(m)
	Sfx.play(&"meteor_fall", -6.0 if not big else 0.0, 0.1)


func _draw() -> void:
	# 하늘의 마법진 (시전 중 크게 열리고 비가 끝나면 닫힘)
	var open := clampf(_t / CAST, 0.0, 1.0)
	if _t > CAST + RAIN + 0.5:
		open = clampf(1.0 - (_t - CAST - RAIN - 0.5) * 2.0, 0.0, 1.0)
	if open <= 0.0:
		return
	var c := to_local(_circle_pos)
	var r := 70.0 * open
	var col := _col()
	draw_arc(c, r, 0.0, TAU, 48, Color(col, 0.8 * open), 2.0)
	draw_arc(c, r * 0.72, 0.0, TAU, 48, Color(_hot(), 0.6 * open), 1.0)
	for i in 7:
		var a := _t * 0.8 + TAU * i / 7.0
		var a2 := a + TAU * 3.0 / 7.0
		draw_line(c + Vector2(cos(a), sin(a) * 0.35) * r, c + Vector2(cos(a2), sin(a2) * 0.35) * r, Color(col, 0.55 * open), 1.0)
	draw_circle(c, 8.0 * open, Color(_hot(), 0.8 * open))


class Meteor extends Node2D:
	var owner_fall: MeteorFall
	var target := Vector2.ZERO
	var big := false
	var damage := 200
	var radius := 40.0
	var fox := false
	var burn := false
	var _start := Vector2.ZERO
	var _t := 0.0
	var _dur := 0.38
	var _trail: Array[Vector2] = []

	func _ready() -> void:
		z_index = 9
		_start = target + Vector2(140 if not big else 60, -300)
		global_position = _start
		_dur = 0.55 if big else 0.36

	func _physics_process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / _dur, 0.0, 1.0)
		global_position = _start.lerp(target, k * k)
		_trail.push_front(global_position)
		if _trail.size() > 14:
			_trail.pop_back()
		if k >= 1.0:
			_impact()
			return
		queue_redraw()

	func _impact() -> void:
		set_physics_process(false)
		var c := target + Vector2(0, -6)
		for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
			var en := e as EnemyBase
			if en and en.is_alive() and EnemyBase.dist_to_body(en, c) <= radius:
				var h := Hit.make(damage, &"meteor", c)
				h.knockback_t = 3.0 if big else 1.6
				h.launch_t = 2.0 if big else 1.0
				h.hitstop = 0.12 if big else 0.04
				h.shake_t = 0.5 if big else 0.25
				h.breaks_charge = true
				h.ignores_knock_resist = true
				en.take_hit(h)
		for m in get_tree().get_nodes_in_group(&"meteor_target"):
			var n2 := m as Node2D
			if n2 and n2.global_position.distance_to(c) <= radius + 16.0 and n2.has_method("take_hit"):
				n2.take_hit(Hit.make(damage, &"meteor", c))
		var col := Color(0.45, 0.8, 1.0) if fox else Palette.FIRE_OUT
		var hot := Color(0.85, 0.97, 1.0) if fox else Palette.FIRE_HOT
		Fx.ring(c, 6.0, radius * 1.3, hot, 0.4 if big else 0.3, 3.0)
		Fx.burst(c, 40 if big else 22, {spread = 160.0, direction = Vector2.UP, speed_min = 60.0, speed_max = 320.0 if big else 220.0,
			lifetime = 0.6, size_min = 1.5, size_max = 4.0, gradient = Palette.fade_gradient(col), gravity = Vector2(0, 200), add = true})
		Fx.burst(c, 14, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.9,
			gradient = Palette.fade_gradient(Color(0.35, 0.3, 0.35)), gravity = Vector2(0, -20)})
		Fx.shake(0.7 if big else 0.3, 0.35 if big else 0.2)
		if big:
			Fx.flash(Color(hot, 0.5), 0.2)
			Fx.hitstop(0.08)
		Sfx.play(&"meteor_impact", 0.0 if big else -5.0, 0.12)
		if burn:
			BurnGround.spawn(target, radius * 1.6, 70.0, 3.0, &"meteor", fox)
		queue_free()

	func _draw() -> void:
		var col := Color(0.45, 0.8, 1.0) if fox else Palette.FIRE_OUT
		var hot := Color(0.85, 0.97, 1.0) if fox else Palette.FIRE_HOT
		var prev := Vector2.ZERO
		var w := 9.0 if big else 5.0
		for i in _trail.size():
			var p := to_local(_trail[i])
			var k := 1.0 - float(i) / _trail.size()
			draw_line(prev, p, Color(col, 0.8 * k), w * k + 1.0)
			prev = p
		var r := 9.0 if big else 5.0
		draw_circle(Vector2.ZERO, r + 4.0, Color(col, 0.35))
		draw_circle(Vector2.ZERO, r, hot)
		draw_circle(Vector2.ZERO, r * 0.5, Color(1, 1, 0.95))
