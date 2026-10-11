class_name FireStorm
extends Node2D
## 스킬 2 화염 폭풍 (docs/archive/sera/prototype.md 5.5절, v0.3 대형화).
## 전방 5.5T 부채꼴로 0.45초 동안 몰아치는 화염(작은 피해 여러 번) → 마지막에 큰 폭발로 날려 보낸다.
## 세라의 자식으로 붙어 따라다니며, 방향은 시전 순간의 방향으로 고정. 돌진 중인 적의 돌진을 끊는다.

var tuning: Tuning
var direction := 1

var _t := 0.0
var _ticks_done := 0
var _area: Area2D
var _particles: CPUParticles2D
var _seed := 0.0
var _final_done := false

const GROW_TIME := 0.06 ## 부채꼴이 다 펼쳐지는 시간


func setup(p_dir: int, p_tuning: Tuning) -> void:
	direction = p_dir
	tuning = p_tuning


func _ready() -> void:
	z_index = 4
	material = Fx.add_material
	_seed = randf() * 10.0
	var r := tuning.storm_radius_t * GameConst.TILE
	var half := deg_to_rad(tuning.storm_angle_deg) * 0.5

	_area = Area2D.new()
	_area.collision_layer = GameConst.L_PLAYER_ATTACK
	_area.collision_mask = GameConst.L_ENEMY_HURT
	var poly := CollisionPolygon2D.new()
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 11:
		var a := lerpf(-half, half, i / 10.0)
		pts.append(Vector2(cos(a) * direction, sin(a)) * r)
	poly.polygon = pts
	_area.add_child(poly)
	add_child(_area)

	_particles = CPUParticles2D.new()
	_particles.amount = 130
	_particles.lifetime = 0.38
	_particles.explosiveness = 0.1
	_particles.local_coords = false
	_particles.direction = Vector2(direction, 0)
	_particles.spread = tuning.storm_angle_deg * 0.5
	_particles.initial_velocity_min = r * 2.4
	_particles.initial_velocity_max = r * 3.6
	_particles.damping_min = r * 4.0
	_particles.damping_max = r * 6.0
	_particles.gravity = Vector2(0, -80)
	_particles.scale_amount_min = 2.0
	_particles.scale_amount_max = 5.5
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0))
	_particles.scale_amount_curve = curve
	_particles.color_ramp = Palette.fire_gradient()
	_particles.material = Fx.add_material
	add_child(_particles)
	_particles.emitting = true

	Sfx.play(&"storm", 1.0)
	Fx.shake(tuning.shake_storm_t * 0.5, 0.45)


func _physics_process(delta: float) -> void:
	_t += delta
	var dur := tuning.storm_duration
	var tick_gap := dur / tuning.storm_ticks
	# 첫 판정은 부채꼴이 다 펼쳐진 뒤(GROW_TIME)부터 → 히트스톱으로 멈춘 화면에 다 펼쳐진 불길이 보이게
	while _ticks_done < tuning.storm_ticks and _t >= GROW_TIME + _ticks_done * tick_gap:
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
			var hit := Hit.make(tuning.storm_final_damage if last else tuning.storm_tick_damage, \
				&"storm_final" if last else &"storm", global_position, direction)
			hit.breaks_charge = true
			hit.ignores_knock_resist = true
			hit.knockback_t = tuning.storm_knockback_t if last else 0.3
			if last:
				hit.launch_t = 1.2
			if index == 0 or last:
				hit.hitstop = tuning.hitstop_storm * (1.5 if last else 1.0)
				hit.shake_t = tuning.shake_storm_t
			e.take_hit(hit)
			any = true
	if any:
		Sfx.play(&"hit_heavy" if last else &"hit", -2.0)
	if last:
		_final_blast()


func _final_blast() -> void:
	_final_done = true
	var r := tuning.storm_radius_t * GameConst.TILE
	var tip := global_position + Vector2(direction * r * 0.6, 0)
	Sfx.play(&"storm_final", -1.0)
	Fx.shake(tuning.shake_storm_t, 0.3)
	Fx.zoom_punch(tuning.zoom_punch)
	Fx.ring(tip, 6.0, r * 0.8, Palette.FIRE_CORE, 0.3, 3.0)
	Fx.burst(tip, 40, {
		spread = 180.0, speed_min = 60.0, speed_max = r * 3.0, damping = r * 2.5,
		lifetime = 0.5, size_min = 1.5, size_max = 4.0, gravity = Vector2(0, -60),
	})


func _draw() -> void:
	if _t >= tuning.storm_duration + 0.1:
		return
	var k := clampf(_t / tuning.storm_duration, 0.0, 1.0)
	var r := tuning.storm_radius_t * GameConst.TILE
	var half := deg_to_rad(tuning.storm_angle_deg) * 0.5
	var grow := clampf(_t / GROW_TIME, 0.0, 1.0)
	var fade := 1.0 - k * k
	# 부채꼴 전체를 은은하게 채우는 열기
	var fan := PackedVector2Array([Vector2.ZERO])
	for i in 13:
		var a := lerpf(-half, half, i / 12.0)
		fan.append(Vector2(cos(a) * direction, sin(a)) * r * grow * 0.9)
	draw_colored_polygon(fan, Color(Palette.FIRE_OUT, 0.13 * fade))
	# 혀처럼 날카로운 불꽃 7갈래
	for i in 7:
		var a := lerpf(-half * 0.85, half * 0.85, i / 6.0) + sin(_t * 35.0 + i * 1.3 + _seed) * 0.08
		var flen := r * grow * (0.7 + 0.3 * sin(_t * 47.0 + i * 2.0 + _seed))
		var dir := Vector2(cos(a) * direction, sin(a))
		var side := Vector2(-dir.y, dir.x)
		var base_w := 8.0 * fade
		draw_colored_polygon(PackedVector2Array([
			side * base_w, dir * flen, -side * base_w,
		]), Color(Palette.FIRE_OUT, 0.7 * fade))
		draw_colored_polygon(PackedVector2Array([
			side * base_w * 0.45, dir * flen * 0.75, -side * base_w * 0.45,
		]), Color(Palette.FIRE_HOT, 0.85 * fade))
	draw_circle(Vector2.ZERO, 8.0 * fade + 2.0, Color(Palette.FIRE_CORE, 0.9 * fade))
