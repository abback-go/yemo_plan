class_name FirePillar
extends Node2D
## 스킬 1 발밑 불기둥 (docs/prototype.md 5.4절).
## 예고(바닥 균열과 불씨) 동안 대상의 발밑을 따라가다가, 시간이 되면 불기둥이 솟아 적을 띄운다.

var tuning: Tuning
var target: Node2D = null ## 따라갈 적. 없으면 처음 자리에서 솟음

var _t := 0.0
var _erupted := false
var _hit_done := false
var _area: Area2D
var _seed := 0.0

const ERUPT_LIFE := 0.45


func setup(pos: Vector2, p_target: Node2D, p_tuning: Tuning) -> void:
	global_position = pos
	target = p_target
	tuning = p_tuning


func _ready() -> void:
	z_index = 3
	_seed = randf() * 10.0
	var t := GameConst.TILE
	_area = Area2D.new()
	_area.collision_layer = GameConst.L_PLAYER_ATTACK
	_area.collision_mask = GameConst.L_ENEMY_HURT
	_area.monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tuning.pillar_width_t * t, tuning.pillar_height_t * t)
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y / 2.0)
	_area.add_child(shape)
	add_child(_area)
	Sfx.play(&"pillar_warn", -2.0)


func _physics_process(delta: float) -> void:
	_t += delta
	if not _erupted:
		if is_instance_valid(target) and target.is_alive() and target.is_on_floor():
			global_position.x = move_toward(global_position.x, target.global_position.x, 200.0 * delta)
			global_position.y = target.global_position.y
		if _t >= tuning.pillar_warn_time:
			_erupt()
	else:
		var e := _t - tuning.pillar_warn_time
		# 분출 후 두 번째 물리 프레임에 판정 (Area2D 겹침 목록이 갱신된 뒤)
		if not _hit_done and e > 0.02:
			_apply_hits()
		if e >= ERUPT_LIFE:
			queue_free()
	queue_redraw()


func _erupt() -> void:
	_erupted = true
	_area.monitoring = true
	Sfx.play(&"pillar")
	Fx.shake(tuning.shake_pillar_t * 0.6, 0.18)
	var h := tuning.pillar_height_t * GameConst.TILE
	Fx.burst(global_position + Vector2(0, -h * 0.5), 28, {
		direction = Vector2.UP, spread = 18.0, speed_min = 80.0, speed_max = 260.0,
		lifetime = 0.5, size_min = 1.5, size_max = 3.5, gravity = Vector2(0, -60),
		box = Vector2(6, h * 0.5),
	})
	Fx.burst(global_position, 12, {
		direction = Vector2.UP, spread = 80.0, speed_min = 40.0, speed_max = 120.0,
		lifetime = 0.35, size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300),
		gradient = Palette.fade_gradient(Palette.GROUND_TOP),
	})


func _apply_hits() -> void:
	_hit_done = true
	var any := false
	for a in _area.get_overlapping_areas():
		var e := a.get_parent()
		if e and e.has_method("take_hit") and e.is_alive():
			var hit := Hit.make(tuning.pillar_damage, &"pillar", global_position + Vector2(0, 8))
			hit.launch_t = tuning.pillar_launch_t
			hit.hitstop = tuning.hitstop_pillar
			hit.shake_t = tuning.shake_pillar_t
			e.take_hit(hit)
			any = true
	_area.set_deferred("monitoring", false)
	if any:
		Sfx.play(&"hit_heavy")


func _draw() -> void:
	var t := GameConst.TILE
	var w := tuning.pillar_width_t * t
	var h := tuning.pillar_height_t * t
	if not _erupted:
		# 예고: 바닥 균열이 점점 벌어지고 밝아짐
		var k := clampf(_t / tuning.pillar_warn_time, 0.0, 1.0)
		var half := w * (0.6 + k * 0.6)
		var col := Palette.FIRE_OUT.lerp(Palette.FIRE_CORE, k)
		draw_line(Vector2(-half, -0.5), Vector2(half, -0.5), Color(col, 0.6 + 0.4 * k), 1.0)
		var jag := PackedVector2Array([
			Vector2(-half, 0), Vector2(-half * 0.4, -1.5 - k * 1.5), Vector2(0, 0), Vector2(half * 0.5, -1 - k * 2.0), Vector2(half, 0),
		])
		draw_polyline(jag, Color(Palette.FIRE_HOT, 0.4 + 0.6 * k), 1.0)
		draw_rect(Rect2(-half, -2.0 - k * 3.0, half * 2.0, 2.0 + k * 3.0), Color(Palette.FIRE_OUT, 0.15 + 0.25 * k))
		# 위로 떠오르는 불씨
		for i in 4:
			var ph := fmod(_t * 2.5 + i * 0.27 + _seed, 1.0)
			draw_rect(Rect2(Vector2(sin(i * 2.3 + _seed) * half * 0.8, -ph * 14.0), Vector2(1, 1)), Color(Palette.FIRE_HOT, 1.0 - ph))
		return

	# 분출: 들쭉날쭉한 불기둥이 솟았다가 가늘어지며 사라짐
	var e := _t - tuning.pillar_warn_time
	var k2 := clampf(e / ERUPT_LIFE, 0.0, 1.0)
	var rise := clampf(e / 0.06, 0.0, 1.0)
	var width_k := (1.0 - k2 * k2) * (1.0 + 0.25 * sin(e * 50.0))
	var top := -h * rise
	var layers := [
		[Palette.FIRE_DARK, 1.0], [Palette.FIRE_OUT, 0.8], [Palette.FIRE_HOT, 0.5], [Palette.FIRE_CORE, 0.22],
	]
	for L in layers:
		var col: Color = L[0]
		var hw: float = w * 0.5 * float(L[1]) * width_k
		var pts := PackedVector2Array()
		var steps := 7
		if hw < 0.75 or top > -2.0:
			continue
		# 좌우 가장자리가 서로 엇갈리지 않도록 흔들림을 폭의 40% 이내로 제한
		var wob_amp := minf(1.5, hw * 0.4)
		for i in steps + 1:
			var y := lerpf(0.0, top, float(i) / steps)
			var wob := sin(e * 40.0 + i * 1.7 + _seed) * wob_amp
			pts.append(Vector2(-hw * (1.0 - float(i) / steps * 0.35) + wob, y))
		pts.append(Vector2(sin(e * 30.0 + _seed) * wob_amp, top - 6.0 * float(L[1])))
		for i in range(steps, -1, -1):
			var y := lerpf(0.0, top, float(i) / steps)
			var wob := sin(e * 37.0 + i * 2.1 + _seed + 1.0) * wob_amp
			pts.append(Vector2(hw * (1.0 - float(i) / steps * 0.35) + wob, y))
		draw_colored_polygon(pts, Color(col, 1.0 - k2 * 0.6))
	# 바닥 불꽃 고리
	draw_rect(Rect2(-w, -3, w * 2.0, 3), Color(Palette.FIRE_OUT, 0.6 * (1.0 - k2)))
