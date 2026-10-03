class_name FireStorm
extends Node2D
## 스킬 2 화염 폭풍 (docs/prototype.md 5.5절). 전방 근거리 부채꼴, 0.3초 동안 3번 피해.
## 세라의 자식으로 붙어 따라다니며, 방향은 시전 순간의 방향으로 고정.
## 1번째 타격: 히트스톱·흔들림 + 돌진 끊기, 마지막 타격: 큰 넉백 (몰아친 뒤 날려 보냄)

var tuning: Tuning
var direction := 1

var _t := 0.0
var _ticks_done := 0
var _area: Area2D
var _particles: CPUParticles2D
var _seed := 0.0


func setup(p_dir: int, p_tuning: Tuning) -> void:
	direction = p_dir
	tuning = p_tuning


func _ready() -> void:
	z_index = 4
	_seed = randf() * 10.0
	var r := tuning.storm_radius_t * GameConst.TILE
	var half := deg_to_rad(tuning.storm_angle_deg) * 0.5

	_area = Area2D.new()
	_area.collision_layer = GameConst.L_PLAYER_ATTACK
	_area.collision_mask = GameConst.L_ENEMY_HURT
	var poly := CollisionPolygon2D.new()
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 9:
		var a := lerpf(-half, half, i / 8.0)
		pts.append(Vector2(cos(a) * direction, sin(a)) * r)
	poly.polygon = pts
	_area.add_child(poly)
	add_child(_area)

	_particles = CPUParticles2D.new()
	_particles.amount = 70
	_particles.lifetime = 0.32
	_particles.explosiveness = 0.15
	_particles.local_coords = false
	_particles.direction = Vector2(direction, 0)
	_particles.spread = tuning.storm_angle_deg * 0.5
	_particles.initial_velocity_min = r * 2.2
	_particles.initial_velocity_max = r * 3.4
	_particles.damping_min = r * 4.0
	_particles.damping_max = r * 6.0
	_particles.gravity = Vector2(0, -60)
	_particles.scale_amount_min = 1.5
	_particles.scale_amount_max = 4.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0))
	_particles.scale_amount_curve = curve
	_particles.color_ramp = Palette.fire_gradient()
	add_child(_particles)
	_particles.emitting = true

	Sfx.play(&"storm")


func _physics_process(delta: float) -> void:
	_t += delta
	var dur := tuning.storm_duration
	var tick_gap := dur / tuning.storm_ticks
	# 첫 판정은 Area2D 겹침 목록이 채워진 다음 프레임부터
	while _ticks_done < tuning.storm_ticks and _t >= 0.02 + _ticks_done * tick_gap:
		_tick(_ticks_done)
		_ticks_done += 1
	if _t >= dur:
		_particles.emitting = false
		_area.monitoring = false
		if _t >= dur + _particles.lifetime:
			queue_free()
	queue_redraw()


func _tick(index: int) -> void:
	var last := index == tuning.storm_ticks - 1
	var any := false
	for a in _area.get_overlapping_areas():
		var e := a.get_parent()
		if e and e.has_method("take_hit") and e.is_alive():
			var hit := Hit.make(tuning.storm_tick_damage, &"storm", global_position, direction)
			hit.breaks_charge = true
			hit.ignores_knock_resist = true
			hit.knockback_t = tuning.storm_knockback_t if last else 0.4
			if index == 0:
				hit.hitstop = tuning.hitstop_storm
				hit.shake_t = tuning.shake_storm_t
			e.take_hit(hit)
			any = true
	if any:
		Sfx.play(&"hit_heavy" if last else &"hit", -2.0)


func _draw() -> void:
	if _t >= tuning.storm_duration:
		return
	var k := _t / tuning.storm_duration
	var r := tuning.storm_radius_t * GameConst.TILE
	var half := deg_to_rad(tuning.storm_angle_deg) * 0.5
	var grow := clampf(_t / 0.06, 0.0, 1.0)
	var fade := 1.0 - k * k
	# 혀처럼 날카로운 불꽃 5갈래
	for i in 5:
		var a := lerpf(-half * 0.85, half * 0.85, i / 4.0) + sin(_t * 35.0 + i * 1.3 + _seed) * 0.08
		var flen := r * grow * (0.75 + 0.25 * sin(_t * 47.0 + i * 2.0 + _seed))
		var dir := Vector2(cos(a) * direction, sin(a))
		var side := Vector2(-dir.y, dir.x)
		var base_w := 5.0 * fade
		draw_colored_polygon(PackedVector2Array([
			side * base_w, dir * flen, -side * base_w,
		]), Color(Palette.FIRE_OUT, 0.75 * fade))
		draw_colored_polygon(PackedVector2Array([
			side * base_w * 0.45, dir * flen * 0.7, -side * base_w * 0.45,
		]), Color(Palette.FIRE_HOT, 0.85 * fade))
	draw_circle(Vector2.ZERO, 5.0 * fade + 1.0, Color(Palette.FIRE_CORE, 0.8 * fade))
