class_name FirePillar
extends Node2D
## 스킬 1 발밑 불기둥 (docs/archive/sera/prototype.md 5.4절, v0.3 대형화).
## 예고(바닥 균열) 동안 대상의 발밑을 따라가다가 거대한 불기둥이 솟아 적을 높이 띄운다.
## 이어서 양옆으로 작은 불기둥이 연쇄로 솟는다(side > 0이면 연쇄 기둥 자신).

var tuning: Tuning
var target: Node2D = null ## 따라갈 적. 없으면 처음 자리에서 솟음
var facing := 1
var side := 0 ## 0 = 중심 기둥, 1·2… = 연쇄 기둥 순번
var side_dir := 0
var blue := false ## 여우 모드(여우비 마무리)의 푸른 여우불 기둥
var damage_override := 0

var _t := 0.0
var _erupted := false
var _hit_done := false
var _area: Area2D
var _seed := 0.0
var _w := 32.0
var _h := 112.0
var _warn := 0.22

const ERUPT_LIFE := 0.55
const RISE_TIME := 0.05 ## 분출 후 기둥이 끝까지 솟는 시간
const FOLLOW_SPEED := 420.0 ## 예고 중 대상을 따라가는 속도 (px/s)


func setup(pos: Vector2, p_target: Node2D, p_tuning: Tuning, p_facing := 1, p_side := 0, p_side_dir := 0) -> void:
	global_position = pos
	target = p_target
	tuning = p_tuning
	facing = p_facing
	side = p_side
	side_dir = p_side_dir


func _ready() -> void:
	z_index = 3
	material = Fx.add_material
	_seed = randf() * 10.0
	var t := GameConst.TILE
	var k := 1.0 if side == 0 else 0.7 - 0.1 * (side - 1)
	_w = tuning.pillar_width_t * t * k
	_h = tuning.pillar_height_t * t * k
	_warn = tuning.pillar_warn_time if side == 0 else 0.06
	if blue:
		_warn = 0.12
		_w *= 1.3
		_h *= 1.25
	_area = Area2D.new()
	_area.collision_layer = GameConst.L_PLAYER_ATTACK
	_area.collision_mask = GameConst.L_ENEMY_HURT
	_area.monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_w, _h)
	shape.shape = rect
	shape.position = Vector2(0, -_h / 2.0)
	_area.add_child(shape)
	add_child(_area)
	if side == 0:
		Sfx.play(&"pillar_warn", -2.0)


func _physics_process(delta: float) -> void:
	_t += delta
	if not _erupted:
		if is_instance_valid(target) and target.is_alive() and target.is_on_floor():
			# 돌진 중인 돌진형(17T/s)보다 빠르게 따라간다
			global_position.x = move_toward(global_position.x, target.global_position.x, FOLLOW_SPEED * delta)
			global_position.y = target.global_position.y
		if _t >= _warn:
			_erupt()
	else:
		var e := _t - _warn
		# 기둥이 끝까지 솟은 뒤 판정 → 히트스톱으로 멈춘 화면에 다 솟은 기둥이 보이게
		if not _hit_done and e >= RISE_TIME:
			_apply_hits()
		if e >= ERUPT_LIFE:
			queue_free()
	queue_redraw()


func _erupt() -> void:
	_erupted = true
	_area.monitoring = true
	var big := side == 0
	Sfx.play(&"pillar", 0.0 if big else -5.0, 0.1)
	Fx.shake(tuning.shake_pillar_t * (0.8 if big else 0.35), 0.25)
	if big:
		Fx.zoom_punch(tuning.zoom_punch * 0.8)
		Fx.flash(Color(1.0, 0.6, 0.3, 0.18) if not blue else Color(0.5, 0.8, 1.0, 0.22), 0.12)
	Fx.burst(global_position + Vector2(0, -_h * 0.5), 46 if big else 20, {
		direction = Vector2.UP, spread = 14.0, speed_min = 120.0, speed_max = 420.0,
		lifetime = 0.55, size_min = 1.5, size_max = 4.5, gravity = Vector2(0, -80),
		box = Vector2(_w * 0.35, _h * 0.5),
		gradient = Palette.fade_gradient(Color(0.55, 0.85, 1.0)) if blue else null, add = true,
	})
	Fx.burst(global_position, 18 if big else 8, {
		direction = Vector2.UP, spread = 85.0, speed_min = 60.0, speed_max = 180.0,
		lifetime = 0.4, size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 400),
		gradient = Palette.fade_gradient(Palette.GROUND_TOP),
	})
	Fx.ring(global_position, 4.0, _w * 1.6, Palette.FIRE_HOT if not blue else Color(0.6, 0.85, 1.0), 0.3, 2.0)
	if big and not blue:
		_spawn_chain()


## 양옆으로 연쇄 불기둥
func _spawn_chain() -> void:
	var gap := tuning.pillar_side_gap_t * GameConst.TILE
	for dir: int in [-1, 1]:
		for i in tuning.pillar_side_count:
			var x := global_position.x + dir * gap * (i + 1)
			var pos := _ground_at(x)
			if pos == Vector2.INF:
				continue
			# 중심 기둥의 자식 Timer (중심 기둥은 연쇄가 끝난 뒤에 사라지고, 씬이 바뀌면 함께 사라짐)
			var timer := Timer.new()
			timer.one_shot = true
			timer.wait_time = tuning.pillar_side_delay * (i + 1)
			var side_i: int = i + 1
			timer.timeout.connect(func() -> void:
				var p := FirePillar.new()
				p.setup(pos, null, tuning, facing, side_i, dir)
				get_parent().add_child(p)
				timer.queue_free()
			)
			add_child(timer)
			timer.start()


func _ground_at(x: float) -> Vector2:
	var space := get_world_2d().direct_space_state
	var from := Vector2(x, global_position.y - 2.0 * GameConst.TILE)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 4.0 * GameConst.TILE), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	return r.position if r else Vector2.INF


func _apply_hits() -> void:
	_hit_done = true
	var any := false
	for a in _area.get_overlapping_areas():
		var e := a.get_parent()
		if e and e.has_method("take_hit") and e.is_alive():
			if side > 0 and e is Brazier:
				continue # 연쇄 기둥은 봉화를 켜지 않음 (퍼즐이 꼬이지 않게)
			var dmg := tuning.pillar_damage if side == 0 else tuning.pillar_side_damage
			if damage_override > 0:
				dmg = damage_override
			var hit := Hit.make(dmg, &"fox_pillar" if blue else &"pillar", global_position + Vector2(0, 8))
			hit.launch_t = tuning.pillar_launch_t if side == 0 else tuning.pillar_launch_t * 0.6
			hit.hitstop = tuning.hitstop_pillar if side == 0 else 0.03
			hit.shake_t = tuning.shake_pillar_t if side == 0 else 0.1
			hit.zoom = tuning.zoom_punch if side == 0 else 0.0
			e.take_hit(hit)
			any = true
	_area.set_deferred("monitoring", false)
	if any:
		Sfx.play(&"hit_heavy")


func _draw() -> void:
	var w := _w
	var h := _h
	if not _erupted:
		# 예고: 바닥 균열이 점점 벌어지고 밝아짐 + 빛기둥 윤곽
		var k := clampf(_t / _warn, 0.0, 1.0)
		var half := w * (0.5 + k * 0.5)
		var col := Palette.FIRE_OUT.lerp(Palette.FIRE_CORE, k)
		draw_rect(Rect2(-half, -h, half * 2.0, h), Color(Palette.FIRE_OUT, 0.05 + 0.1 * k))
		draw_line(Vector2(-half, -0.5), Vector2(half, -0.5), Color(col, 0.6 + 0.4 * k), 1.0)
		var jag := PackedVector2Array([
			Vector2(-half, 0), Vector2(-half * 0.5, -2 - k * 2.0), Vector2(-half * 0.1, 0), Vector2(half * 0.3, -2 - k * 3.0), Vector2(half * 0.7, -1), Vector2(half, 0),
		])
		draw_polyline(jag, Color(Palette.FIRE_HOT, 0.4 + 0.6 * k), 1.0)
		draw_rect(Rect2(-half, -3.0 - k * 4.0, half * 2.0, 3.0 + k * 4.0), Color(Palette.FIRE_OUT, 0.2 + 0.3 * k))
		for i in 6:
			var ph := fmod(_t * 3.0 + i * 0.19 + _seed, 1.0)
			draw_rect(Rect2(Vector2(sin(i * 2.3 + _seed) * half * 0.9, -ph * 22.0), Vector2(1, 1)), Color(Palette.FIRE_HOT, 1.0 - ph))
		return

	# 분출: 들쭉날쭉한 거대 불기둥이 솟았다가 가늘어지며 사라짐
	var e := _t - _warn
	var k2 := clampf(e / ERUPT_LIFE, 0.0, 1.0)
	var rise := clampf(e / RISE_TIME, 0.0, 1.0)
	var width_k := (1.0 - k2 * k2) * (1.0 + 0.2 * sin(e * 50.0))
	var top := -h * rise
	# 기둥 둘레 빛 (중심 기둥만. 연쇄 기둥까지 그리면 빛 사각형이 겹쳐 각져 보임)
	if side == 0:
		draw_rect(Rect2(-w * 0.9, top, w * 1.8, -top), Color(Palette.FIRE_OUT, 0.09 * (1.0 - k2)))
	var layers := [
		[Palette.FIRE_DARK, 1.0], [Palette.FIRE_OUT, 0.8], [Palette.FIRE_HOT, 0.5], [Palette.FIRE_CORE, 0.24],
	]
	if blue:
		layers = [[Color("#1a3a8a"), 1.0], [Color("#3a78e0"), 0.8], [Color("#8ad0ff"), 0.5], [Color("#eef8ff"), 0.24]]
	for L in layers:
		var col: Color = L[0]
		var hw: float = w * 0.5 * float(L[1]) * width_k
		if hw < 0.75 or top > -2.0:
			continue
		# 좌우 가장자리가 서로 엇갈리지 않도록 흔들림을 폭의 40% 이내로 제한
		var wob_amp := minf(2.5, hw * 0.4)
		var pts := PackedVector2Array()
		var steps := 9
		for i in steps + 1:
			var y := lerpf(0.0, top, float(i) / steps)
			var wob := sin(e * 40.0 + i * 1.7 + _seed) * wob_amp
			pts.append(Vector2(-hw * (1.0 - float(i) / steps * 0.3) + wob, y))
		pts.append(Vector2(sin(e * 30.0 + _seed) * wob_amp, top - 10.0 * float(L[1])))
		for i in range(steps, -1, -1):
			var y := lerpf(0.0, top, float(i) / steps)
			var wob := sin(e * 37.0 + i * 2.1 + _seed + 1.0) * wob_amp
			pts.append(Vector2(hw * (1.0 - float(i) / steps * 0.3) + wob, y))
		draw_colored_polygon(pts, Color(col, 1.0 - k2 * 0.6))
	# 바닥 불꽃 고리
	draw_rect(Rect2(-w * 1.3, -4, w * 2.6, 4), Color(Palette.FIRE_OUT, 0.7 * (1.0 - k2)))
