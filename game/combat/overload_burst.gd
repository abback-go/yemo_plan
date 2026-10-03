class_name OverloadBurst
extends Node2D
## 폭주 게이지가 가득 찼을 때의 강제 화염 폭발 (docs/prototype.md 5.6절).
## 반경 안의 적에게 큰 피해. 세라의 자기 피해는 Player 쪽에서 처리한다.

var tuning: Tuning
var _t := 0.0
const LIFE := 0.5


func setup(pos: Vector2, p_tuning: Tuning) -> void:
	global_position = pos
	tuning = p_tuning


func _ready() -> void:
	z_index = 6
	var r := tuning.burst_radius_t * GameConst.TILE
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if not e.is_alive():
			continue
		var center: Vector2 = e.global_position + Vector2(0, -8)
		if center.distance_to(global_position) <= r + 8.0:
			var hit := Hit.make(tuning.burst_damage, &"burst", global_position)
			hit.knockback_t = 2.0
			hit.breaks_charge = true
			hit.ignores_knock_resist = true
			hit.launch_t = 1.0
			e.take_hit(hit)
	Fx.hitstop(tuning.hitstop_burst)
	Fx.shake(tuning.shake_burst_t, 0.4)
	Fx.flash(Color(1.0, 0.75, 0.5, 0.55), 0.25)
	Fx.ring(global_position, 6.0, r, Palette.FIRE_CORE, 0.35, 3.0)
	Fx.ring(global_position, 2.0, r * 0.7, Palette.FIRE_OUT, 0.45, 2.0)
	Fx.burst(global_position, 60, {
		spread = 180.0, speed_min = 80.0, speed_max = r * 4.0, damping = r * 3.0,
		lifetime = 0.6, size_min = 1.5, size_max = 4.0, gravity = Vector2(0, -40),
	})
	Fx.burst(global_position, 24, {
		spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.9,
		size_min = 2.0, size_max = 4.0, gravity = Vector2(0, -70),
		gradient = Palette.fade_gradient(Color(0.15, 0.1, 0.15, 0.8)),
	})
	Sfx.play(&"explode")


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var r := tuning.burst_radius_t * GameConst.TILE
	var e := 1.0 - pow(1.0 - k, 3.0)
	draw_circle(Vector2.ZERO, r * e, Color(Palette.FIRE_OUT, 0.35 * (1.0 - k)))
	draw_circle(Vector2.ZERO, r * 0.6 * e, Color(Palette.FIRE_HOT, 0.5 * (1.0 - k)))
	draw_circle(Vector2.ZERO, r * 0.3 * (1.0 - k), Color(Palette.FIRE_CORE, 0.9 * (1.0 - k)))
