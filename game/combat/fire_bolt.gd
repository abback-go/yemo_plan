class_name FireBolt
extends Area2D
## 기본 공격 화염탄 (docs/prototype.md 5.3절). 가늘고 긴 탄 + 짧은 꼬리, 첫 적중에서 사라짐.

var direction := 1
var speed := 320.0
var max_distance := 144.0
var damage := 10
var knockback_t := 0.2
var heavy := false
var tuning: Tuning

var _traveled := 0.0
var _done := false
var _trail: Array[Vector2] = []
var _t := 0.0


func setup(p_dir: int, p_heavy: bool, p_tuning: Tuning) -> void:
	direction = p_dir
	heavy = p_heavy
	tuning = p_tuning
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


func _ready() -> void:
	collision_layer = GameConst.L_PLAYER_ATTACK
	collision_mask = GameConst.L_ENEMY_HURT | GameConst.L_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16 if heavy else 12, 6 if heavy else 4)
	shape.shape = rect
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	z_index = 4


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var step := speed * delta
	_trail.push_front(global_position)
	if _trail.size() > (7 if heavy else 5):
		_trail.pop_back()
	position.x += direction * step
	_traveled += step
	if _traveled >= max_distance:
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
		hit.shake_t = tuning.shake_heavy_t if heavy else 0.0
		target.take_hit(hit)
		GameState.add("bolts_hit")
		_impact(true)


func _on_body_entered(_body: Node) -> void:
	if not _done:
		_impact(false)


func _impact(on_enemy: bool) -> void:
	_done = true
	set_deferred("monitoring", false)
	var pos := global_position + Vector2(direction * 4, 0)
	Fx.burst(pos, 14 if heavy else 8, {
		direction = Vector2(-direction, -0.3), spread = 70.0,
		speed_min = 60.0, speed_max = 180.0 if heavy else 130.0,
		lifetime = 0.3, size_min = 1.0, size_max = 2.5 if heavy else 2.0,
	})
	Fx.ring(pos, 2.0, 14.0 if heavy else 9.0, Palette.FIRE_HOT, 0.18, 2.0 if heavy else 1.0)
	if not on_enemy:
		Sfx.play(&"land", -8.0, 0.2)
	queue_free()


func _fizzle() -> void:
	_done = true
	set_deferred("monitoring", false)
	Fx.burst(global_position, 5, {
		direction = Vector2(direction, -0.5), spread = 50.0, speed_min = 20.0, speed_max = 60.0,
		lifetime = 0.25, size_min = 1.0, size_max = 1.5, gravity = Vector2(0, -40),
	})
	queue_free()


func _draw() -> void:
	# 꼬리: 지나온 자리를 점점 가늘고 옅게
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		var col := Palette.FIRE_OUT.lerp(Palette.FIRE_DARK, 1.0 - k)
		col.a = 0.7 * k
		draw_line(prev, p, col, (3.0 if heavy else 2.0) * k + 0.5)
		prev = p
	# 몸통: 앞이 뾰족하고 긴 마름모 (둥근 불덩이 금지)
	var d := float(direction)
	var flick := sin(_t * 60.0) * 0.6
	var length := 16.0 if heavy else 11.0
	var half_h := 3.2 if heavy else 2.2
	var outer := PackedVector2Array([
		Vector2(d * length * 0.6, 0), Vector2(0, -half_h - flick * 0.3), Vector2(-d * length * 0.55, 0), Vector2(0, half_h + flick * 0.3),
	])
	draw_colored_polygon(outer, Palette.FIRE_OUT)
	var inner := PackedVector2Array([
		Vector2(d * length * 0.55, 0), Vector2(d * 1.0, -half_h * 0.5), Vector2(-d * length * 0.3, 0), Vector2(d * 1.0, half_h * 0.5),
	])
	draw_colored_polygon(inner, Palette.FIRE_HOT)
	draw_line(Vector2(-d * 2.0, 0), Vector2(d * length * 0.5, 0), Palette.FIRE_CORE, 1.0)
