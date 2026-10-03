class_name FireBolt
extends Area2D
## 기본 공격 화염탄 (v0.4, 플레이 피드백 "연발 대신 강력한 한 발이 툭 툭"): 약 1.2초마다 한 발.
## 앞이 날카로운 큰 불꽃덩이가 곧게 날아가 처음 맞은 적 하나에게만 큰 피해 (폭발·관통 없음).
## 과열(폭주 70% 이상)이면 더 크고 강해진다. 가산 합성으로 빛난다.

var direction := 1
var speed := 640.0
var max_distance := 224.0
var damage := 200
var knockback_t := 1.6
var overheated := false
var tuning: Tuning

var _traveled := 0.0
var _done := false
var _trail: Array[Vector2] = []
var _t := 0.0
var _scale := 1.0


func setup(p_dir: int, p_tuning: Tuning, p_overheated := false) -> void:
	direction = p_dir
	tuning = p_tuning
	overheated = p_overheated
	var t := GameConst.TILE
	speed = tuning.shot_speed_t * t
	max_distance = tuning.shot_range_t * t
	damage = tuning.shot_damage
	knockback_t = tuning.shot_knockback_t
	if overheated:
		damage = int(round(damage * tuning.overheat_damage_mult))
		_scale = tuning.overheat_bolt_scale


func _ready() -> void:
	collision_layer = GameConst.L_PLAYER_ATTACK
	collision_mask = GameConst.L_ENEMY_HURT | GameConst.L_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 12) * _scale
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
	if _trail.size() > 10:
		_trail.pop_back()
	position.x += direction * step
	_traveled += step
	# 날아가며 떨어지는 불씨
	if Engine.get_physics_frames() % 2 == 0:
		Fx.burst(global_position - Vector2(direction * 10, 0), 1, {
			direction = Vector2(-direction, -0.4), spread = 30.0, speed_min = 20.0, speed_max = 60.0,
			lifetime = 0.25, size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -40),
		})
	if _traveled >= max_distance:
		_fizzle()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if _done:
		return
	var target := area.get_parent()
	if target and target.has_method("take_hit") and target.is_alive():
		var hit := Hit.make(damage, &"bolt_heavy", global_position, direction)
		hit.knockback_t = knockback_t
		hit.hitstop = tuning.hitstop_heavy * 1.6
		hit.shake_t = tuning.shake_heavy_t
		hit.zoom = tuning.zoom_punch * 0.8
		hit.breaks_charge = true
		target.take_hit(hit)
		GameState.add("bolts_hit")
		_impact(true)


func _on_body_entered(_body: Node) -> void:
	if not _done:
		_impact(false)


func _impact(on_enemy: bool) -> void:
	_done = true
	set_deferred("monitoring", false)
	var pos := global_position + Vector2(direction * 8, 0)
	Fx.burst(pos, (26 if on_enemy else 14) + (8 if overheated else 0), {
		direction = Vector2(-direction, -0.3), spread = 80.0,
		speed_min = 80.0, speed_max = 260.0,
		lifetime = 0.35, size_min = 1.5, size_max = 3.5,
	})
	_spark(pos, 20.0 if on_enemy else 12.0)
	Fx.ring(pos, 3.0, 20.0 * _scale, Palette.FIRE_HOT, 0.2, 2.0)
	if not on_enemy:
		Sfx.play(&"land", -6.0, 0.2)
	queue_free()


## 십자형 불꽃 섬광 (짧게 번쩍)
func _spark(pos: Vector2, size: float) -> void:
	var s := SparkFx.new()
	s.position = pos
	s.size = size * _scale
	s.material = Fx.add_material
	Fx.effect_parent().add_child(s)


func _fizzle() -> void:
	_done = true
	set_deferred("monitoring", false)
	Fx.burst(global_position, 10, {
		direction = Vector2(direction, -0.5), spread = 60.0, speed_min = 30.0, speed_max = 90.0,
		lifetime = 0.3, size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -40),
	})
	queue_free()


func _draw() -> void:
	var s := _scale
	var d := float(direction)
	# 은은한 빛
	draw_circle(Vector2.ZERO, 20.0 * s, Color(Palette.FIRE_OUT, 0.14))
	# 꼬리: 지나온 자리를 점점 가늘고 옅게
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		var col := Palette.FIRE_OUT.lerp(Palette.FIRE_DARK, 1.0 - k)
		col.a = 0.85 * k
		draw_line(prev, p, col, (8.0 * k + 0.5) * s)
		prev = p
	# 몸통: 앞이 날카로운 큰 불꽃덩이 + 뒤로 갈라지는 불꽃 혀
	var flick := sin(_t * 50.0)
	var length := 34.0 * s
	var half_h := 6.5 * s
	var tongue := 7.0 * s + flick * 1.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(d * length * 0.62, 0), Vector2(d * length * 0.05, -half_h), Vector2(-d * length * 0.3, -half_h * 0.6),
		Vector2(-d * (length * 0.5 + tongue), -half_h * 0.9), Vector2(-d * length * 0.42, 0),
		Vector2(-d * (length * 0.5 + tongue * 0.8), half_h * 0.9), Vector2(-d * length * 0.3, half_h * 0.6), Vector2(d * length * 0.05, half_h),
	]), Palette.FIRE_OUT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(d * length * 0.58, 0), Vector2(d * length * 0.08, -half_h * 0.55), Vector2(-d * length * 0.28, 0), Vector2(d * length * 0.08, half_h * 0.55),
	]), Palette.FIRE_HOT)
	draw_line(Vector2(-d * length * 0.15, 0), Vector2(d * length * 0.55, 0), Palette.FIRE_CORE, 2.0 * s)
	draw_circle(Vector2(d * length * 0.3, 0), 2.0 * s, Color(1, 1, 0.95))
