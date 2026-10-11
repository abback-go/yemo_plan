class_name OverloadBurst
extends Node2D
## 폭주 게이지가 가득 찼을 때의 강제 화염 폭발 (docs/archive/sera/prototype.md 5.6절, v0.3 대형화).
## 반경 6.5T 안의 적에게 큰 피해 + 띄우기. 세라의 자기 피해는 Player 쪽에서 처리한다.

var tuning: Tuning
var _t := 0.0
const LIFE := 0.7


func setup(pos: Vector2, p_tuning: Tuning) -> void:
	global_position = pos
	tuning = p_tuning


func _ready() -> void:
	z_index = 6
	material = Fx.add_material
	var r := tuning.burst_radius_t * GameConst.TILE
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if not e.is_alive():
			continue
		if EnemyBase.dist_to_body(e, global_position) <= r + 8.0:
			var hit := Hit.make(tuning.burst_damage, &"burst", global_position)
			hit.knockback_t = 3.0
			hit.breaks_charge = true
			hit.ignores_knock_resist = true
			hit.launch_t = 2.0
			e.take_hit(hit)
	# 금 간 벽도 무너뜨림 (docs/archive/sera/chapter1.md 12.6절)
	for w in get_tree().get_nodes_in_group(&"cracked_wall"):
		var wc: Vector2 = w.global_position + w.size_px * 0.5
		if wc.distance_to(global_position) <= r + 24.0:
			w.crack_break()
	Fx.hitstop(tuning.hitstop_burst)
	Fx.slowmo(0.4, 0.35)
	Fx.shake(tuning.shake_burst_t, 0.5)
	Fx.zoom_punch(tuning.zoom_punch * 1.6)
	Fx.flash(Color(1.0, 0.75, 0.5, 0.6), 0.3)
	Fx.ring(global_position, 6.0, r, Palette.FIRE_CORE, 0.4, 4.0)
	Fx.ring(global_position, 2.0, r * 0.75, Palette.FIRE_OUT, 0.5, 3.0)
	Fx.ring(global_position, 2.0, r * 1.2, Palette.FIRE_DARK, 0.6, 2.0)
	Fx.burst(global_position, 90, {
		spread = 180.0, speed_min = 80.0, speed_max = r * 4.5, damping = r * 3.0,
		lifetime = 0.7, size_min = 2.0, size_max = 5.0, gravity = Vector2(0, -40),
	})
	Fx.burst(global_position, 30, {
		spread = 180.0, speed_min = 30.0, speed_max = 100.0, lifetime = 1.0,
		size_min = 2.0, size_max = 5.0, gravity = Vector2(0, -70),
		gradient = Palette.fade_gradient(Color(0.15, 0.1, 0.15, 0.8)),
	})
	# 바닥에 잠깐 남는 불꽃
	Fx.burst(global_position + Vector2(0, 16), 30, {
		direction = Vector2.UP, spread = 20.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.8,
		box = Vector2(r * 0.8, 2), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, -30),
		explosiveness = 0.3,
	})
	Sfx.play(&"explode", 2.0)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var r := tuning.burst_radius_t * GameConst.TILE
	var e := 1.0 - pow(1.0 - k, 3.0)
	draw_circle(Vector2.ZERO, r * e, Color(Palette.FIRE_OUT, 0.3 * (1.0 - k)))
	draw_circle(Vector2.ZERO, r * 0.6 * e, Color(Palette.FIRE_HOT, 0.45 * (1.0 - k)))
	draw_circle(Vector2.ZERO, r * 0.35 * (1.0 - k), Color(Palette.FIRE_CORE, 0.9 * (1.0 - k)))
	# 사방으로 뻗는 불꽃 줄기
	for i in 12:
		var a := TAU * i / 12.0 + 0.2
		var d := Vector2(cos(a), sin(a))
		var len_k := r * (0.4 + 0.6 * e)
		draw_colored_polygon(PackedVector2Array([
			d.orthogonal() * 4.0 * (1.0 - k), d * len_k, -d.orthogonal() * 4.0 * (1.0 - k),
		]), Color(Palette.FIRE_HOT, 0.6 * (1.0 - k)))
