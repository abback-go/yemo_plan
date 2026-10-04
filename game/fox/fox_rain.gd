class_name FoxRain
extends Node2D
## 여우 모드 A — 여우비 (docs/chapter1.md 4.8절): 앞쪽 14타일 폭에 1.2초 동안 푸른 불비가 쏟아지고,
## 마지막에 가장 가까운 적(없으면 가운데) 발밑에서 거대한 푸른 여우불 기둥.

const WIDTH_T := 14.0
const DURATION := 1.2
const TICK := 0.15
const TICK_DMG := 9

var tuning: Tuning
var rect := Rect2()
var _t := 0.0
var _tick := 0.0
var _drops: Array = [] ## [x, y, speed]
var _finished := false
var _dir := 1


func setup(p: Player, p_tuning: Tuning) -> void:
	tuning = p_tuning
	_dir = p.facing
	var w := WIDTH_T * GameConst.TILE
	var cx := p.global_position.x + _dir * w * 0.5
	rect = Rect2(cx - w * 0.5, p.global_position.y - 12.0 * GameConst.TILE, w, 13.0 * GameConst.TILE)


func _ready() -> void:
	z_index = 6
	material = Fx.add_material
	Sfx.play(&"fox_rain", 0.0, 0.0)
	Fx.flash(Color(0.4, 0.7, 1.0, 0.15), 0.3)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t < DURATION:
		for i in 6:
			_drops.append([rect.position.x + randf() * rect.size.x, rect.position.y + randf() * 30.0, randf_range(380.0, 520.0)])
		_tick -= delta
		if _tick <= 0.0:
			_tick = TICK
			_damage_tick()
	elif not _finished:
		_finished = true
		_final_pillar()
	var floor_y := rect.end.y
	for d in _drops:
		d[1] += d[2] * delta
		if d[1] > floor_y and randf() < 0.3:
			Fx.burst(Vector2(d[0], floor_y), 1, {direction = Vector2.UP, spread = 50.0, speed_min = 20.0,
				speed_max = 50.0, lifetime = 0.2, gradient = Palette.fade_gradient(FoxPalette.SPARK), add = true})
	_drops = _drops.filter(func(d: Array) -> bool: return d[1] <= floor_y)
	if _finished and _drops.is_empty():
		queue_free()
	queue_redraw()


func _damage_tick() -> void:
	EnemyQuery.within(get_tree(), _in_rain, _rain_hit)
	for b in get_tree().get_nodes_in_group(&"brazier"):
		if rect.has_point(b.global_position + Vector2(0, -12)):
			b.take_hit(Hit.make(1, &"fox_rain", b.global_position))


func _in_rain(e: EnemyBase) -> bool:
	return rect.has_point(e.global_position + Vector2(0, -8))


func _rain_hit(e: EnemyBase) -> void:
	var h := Hit.make(TICK_DMG, &"fox_rain", Vector2(e.global_position.x, rect.position.y))
	h.knockback_t = 0.0
	e.take_hit(h)


func _final_pillar() -> void:
	var c := rect.get_center()
	# 비가 내린 곳(조금 넓게) 안에서 가운데에 가장 가까운 적
	var target := EnemyQuery.nearest(get_tree(), func(e: EnemyBase) -> float:
		return e.global_position.distance_to(c) if rect.grow(32).has_point(e.global_position) else INF)
	var pos := Vector2(c.x, rect.end.y - 16.0)
	if target:
		pos = target.global_position
	else:
		var space := get_world_2d().direct_space_state
		var q := PhysicsRayQueryParameters2D.create(Vector2(c.x, rect.position.y + 100), Vector2(c.x, rect.end.y + 120), GameConst.L_WORLD | GameConst.L_PLATFORM)
		var r := space.intersect_ray(q)
		if r:
			pos = r.position
	var p := FirePillar.new()
	p.blue = true
	p.damage_override = 60
	p.setup(pos, target, tuning, _dir)
	Fx.effect_parent().add_child(p)


func _draw() -> void:
	var k := clampf(_t / 0.2, 0.0, 1.0) * clampf((DURATION + 0.3 - _t) / 0.4, 0.0, 1.0)
	if k > 0.0:
		draw_rect(rect, Color(0.3, 0.55, 1.0, 0.06 * k))
	for d in _drops:
		var p := Vector2(d[0], d[1]) - global_position
		draw_line(p, p + Vector2(-2, -10), Color(0.55, 0.85, 1.0, 0.8), 2.0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(0.9, 0.97, 1.0))
