class_name FireBolt
extends Area2D
## 기본 공격 화염탄 (docs/prototype.md 5.3절, v0.3 강화).
## 가늘고 긴 탄 + 꼬리. 3타는 커다란 화염창이 되어 맞은 자리에서 폭발한다(주변 적에게도 피해).
## 과열(폭주 70% 이상) 상태에서는 더 크고 강해진다. 가산 합성으로 빛난다.

var direction := 1
var speed := 480.0
var max_distance := 176.0
var damage := 12
var knockback_t := 0.25
var heavy := false
var overheated := false
var tuning: Tuning

var _traveled := 0.0
var _done := false
var _trail: Array[Vector2] = []
var _t := 0.0
var _scale := 1.0


func setup(p_dir: int, p_heavy: bool, p_tuning: Tuning, p_overheated := false) -> void:
	direction = p_dir
	heavy = p_heavy
	tuning = p_tuning
	overheated = p_overheated
	var t := GameConst.TILE
	if heavy:
		speed = tuning.bolt_speed_heavy_t * t
		max_distance = tuning.bolt_range_heavy_t * t
		damage = tuning.bolt_damage_heavy
		knockback_t = tuning.bolt_knockback_heavy_t
	else:
		speed = tuning.bolt_speed_light_t * t
		max_distance = tuning.bolt_range_light_t * t
		damage = tuning.bolt_damage_light
		knockback_t = tuning.bolt_knockback_light_t
	if overheated:
		damage = int(round(damage * tuning.overheat_damage_mult))
		_scale = tuning.overheat_bolt_scale


func _ready() -> void:
	collision_layer = GameConst.L_PLAYER_ATTACK
	collision_mask = GameConst.L_ENEMY_HURT | GameConst.L_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22 if heavy else 14, 9 if heavy else 5) * _scale
	shape.shape = rect
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	material = Fx.add_material
	z_index = 4


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var step := speed * delta
	_trail.push_front(global_position)
	if _trail.size() > (9 if heavy else 6):
		_trail.pop_back()
	position.x += direction * step
	_traveled += step
	if _traveled >= max_distance:
		if heavy:
			_impact(false) # 화염창은 사거리 끝에서도 터진다
		else:
			_fizzle()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if _done:
		return
	var target := area.get_parent()
	if target and target.has_method("take_hit") and target.is_alive():
		var hit := Hit.make(damage, &"bolt_heavy" if heavy else &"bolt", global_position, direction)
		hit.knockback_t = knockback_t
		hit.hitstop = tuning.hitstop_heavy if heavy else tuning.hitstop_light
		hit.shake_t = tuning.shake_heavy_t if heavy else tuning.shake_light_t
		hit.zoom = tuning.zoom_punch * 0.6 if heavy else 0.0
		target.take_hit(hit)
		GameState.add("bolts_hit")
		_impact(true, target)


func _on_body_entered(_body: Node) -> void:
	if not _done:
		_impact(false)


func _impact(on_enemy: bool, direct_target: Node = null) -> void:
	_done = true
	set_deferred("monitoring", false)
	var pos := global_position + Vector2(direction * 4, 0)
	Fx.burst(pos, (18 if heavy else 9) + (6 if overheated else 0), {
		direction = Vector2(-direction, -0.3), spread = 75.0,
		speed_min = 70.0, speed_max = 230.0 if heavy else 150.0,
		lifetime = 0.3, size_min = 1.0, size_max = 3.0 if heavy else 2.0,
	})
	_spark(pos)
	Fx.ring(pos, 2.0, (16.0 if heavy else 10.0) * _scale, Palette.FIRE_HOT, 0.18, 2.0 if heavy else 1.0)
	if heavy:
		_blast(pos, direct_target)
	elif not on_enemy:
		Sfx.play(&"land", -8.0, 0.2)
	queue_free()


## 3타 화염창 폭발: 직접 맞은 적을 뺀 주변 적에게 추가 피해
func _blast(pos: Vector2, direct_target: Node) -> void:
	var r := tuning.heavy_blast_radius_t * GameConst.TILE * _scale
	Sfx.play(&"blast", -2.0)
	Fx.ring(pos, 4.0, r, Palette.FIRE_OUT, 0.25, 2.0)
	Fx.burst(pos, 22, {
		spread = 180.0, speed_min = 40.0, speed_max = r * 4.0, damping = r * 3.0,
		lifetime = 0.4, size_min = 1.5, size_max = 3.5, gravity = Vector2(0, -60),
	})
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if e == direct_target or not e.is_alive():
			continue
		var c: Vector2 = e.global_position + Vector2(0, -10)
		if c.distance_to(pos) <= r + 8.0:
			var hit := Hit.make(tuning.heavy_blast_damage, &"blast", pos, direction)
			hit.knockback_t = 0.8
			e.take_hit(hit)


## 십자형 불꽃 섬광 (짧게 번쩍)
func _spark(pos: Vector2) -> void:
	var s := SparkFx.new()
	s.position = pos
	s.size = (12.0 if heavy else 7.0) * _scale
	s.material = Fx.add_material
	Fx.effect_parent().add_child(s)


func _fizzle() -> void:
	_done = true
	set_deferred("monitoring", false)
	Fx.burst(global_position, 6, {
		direction = Vector2(direction, -0.5), spread = 50.0, speed_min = 20.0, speed_max = 70.0,
		lifetime = 0.25, size_min = 1.0, size_max = 1.5, gravity = Vector2(0, -40),
	})
	queue_free()


func _draw() -> void:
	var s := _scale
	# 은은한 빛
	draw_circle(Vector2.ZERO, (14.0 if heavy else 8.0) * s, Color(Palette.FIRE_OUT, 0.12))
	# 꼬리: 지나온 자리를 점점 가늘고 옅게
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		var col := Palette.FIRE_OUT.lerp(Palette.FIRE_DARK, 1.0 - k)
		col.a = 0.8 * k
		draw_line(prev, p, col, ((5.0 if heavy else 3.0) * k + 0.5) * s)
		prev = p
	# 몸통: 앞이 뾰족하고 긴 마름모 (둥근 불덩이 금지)
	var d := float(direction)
	var flick := sin(_t * 60.0) * 0.6
	var length := (24.0 if heavy else 14.0) * s
	var half_h := (4.5 if heavy else 2.6) * s
	var outer := PackedVector2Array([
		Vector2(d * length * 0.6, 0), Vector2(0, -half_h - flick * 0.3), Vector2(-d * length * 0.55, 0), Vector2(0, half_h + flick * 0.3),
	])
	draw_colored_polygon(outer, Palette.FIRE_OUT)
	var inner := PackedVector2Array([
		Vector2(d * length * 0.55, 0), Vector2(d * 1.0, -half_h * 0.5), Vector2(-d * length * 0.3, 0), Vector2(d * 1.0, half_h * 0.5),
	])
	draw_colored_polygon(inner, Palette.FIRE_HOT)
	draw_line(Vector2(-d * 2.0, 0), Vector2(d * length * 0.5, 0), Palette.FIRE_CORE, 1.0 + (1.0 if heavy else 0.0))
	if heavy:
		# 화염창 날개
		draw_colored_polygon(PackedVector2Array([
			Vector2(-d * 2, 0), Vector2(-d * 10 * s, -7 * s), Vector2(-d * 6 * s, 0),
		]), Color(Palette.FIRE_OUT, 0.8))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-d * 2, 0), Vector2(-d * 10 * s, 7 * s), Vector2(-d * 6 * s, 0),
		]), Color(Palette.FIRE_OUT, 0.8))
