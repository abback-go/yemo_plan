class_name NineTailStorm
extends Node2D
## 여우 모드 S — 구미호 폭풍 (docs/chapter1.md 4.8절): 세라 주위 반경 8타일,
## 아홉 갈래 푸른 꼬리 환영이 몰아치며 여러 번 타격하고 마지막에 바깥으로 날려 보낸다.

const RADIUS_T := 8.0
const DURATION := 0.55
const TICKS := 4

var tuning: Tuning
var _t := 0.0
var _ticks := 0
var _done := false


func setup(_p: Player, p_tuning: Tuning) -> void:
	tuning = p_tuning
	position = Vector2(0, -16)


func _ready() -> void:
	z_index = 7
	material = Fx.add_material
	Sfx.play(&"fox_storm", 0.0, 0.0)
	Fx.flash(Color(0.55, 0.8, 1.0, 0.35), 0.25)
	Fx.zoom_punch(tuning.zoom_punch * 1.2)
	Fx.shake(0.25, 0.4)


func _physics_process(delta: float) -> void:
	_t += delta
	var gap := DURATION / (TICKS + 1)
	while _ticks < TICKS and _t >= 0.05 + _ticks * gap:
		_hit_all(false)
		_ticks += 1
	if not _done and _t >= DURATION:
		_done = true
		_hit_all(true)
		Fx.ring(global_position, 10.0, RADIUS_T * GameConst.TILE, Color(0.6, 0.85, 1.0), 0.35, 3.0)
		Fx.burst(global_position, 60, {spread = 180.0, speed_min = 80.0, speed_max = 260.0, damping = 160.0,
			lifetime = 0.5, gradient = Palette.fade_gradient(Color(0.6, 0.85, 1.0)), add = true})
		Sfx.play(&"storm_final", 0.0)
	if _t >= DURATION + 0.35:
		queue_free()
	queue_redraw()


func _hit_all(final: bool) -> void:
	var r := RADIUS_T * GameConst.TILE
	var c := global_position
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if not e.is_alive():
			continue
		if (e.global_position + Vector2(0, -10)).distance_to(c) > r + 8.0:
			continue
		var h := Hit.make(42 if final else 14, &"fox_storm", c)
		h.breaks_charge = true
		h.ignores_knock_resist = true
		h.knockback_t = 4.0 if final else 0.3
		if final:
			h.launch_t = 2.0
			h.hitstop = tuning.hitstop_storm * 1.5
			h.shake_t = tuning.shake_storm_t
		e.take_hit(h)
	for b in get_tree().get_nodes_in_group(&"brazier"):
		if b.global_position.distance_to(c) <= r:
			b.take_hit(Hit.make(1, &"fox_storm", c))


func _draw() -> void:
	var r := RADIUS_T * GameConst.TILE
	var k := clampf(_t / DURATION, 0.0, 1.0)
	var fade := 1.0 - clampf((_t - DURATION) / 0.35, 0.0, 1.0)
	var grow := clampf(_t / 0.12, 0.0, 1.0)
	draw_circle(Vector2.ZERO, r * grow, Color(0.3, 0.55, 1.0, 0.07 * fade))
	# 아홉 갈래 꼬리: 회전하며 휘어진 불꽃 띠
	for i in 9:
		var a0 := TAU * i / 9.0 + k * TAU * 1.2
		var pts := PackedVector2Array()
		var pts2 := PackedVector2Array()
		for j in 9:
			var u := float(j) / 8.0
			var a := a0 + u * 1.1
			var rr := r * grow * (0.2 + 0.8 * u)
			var w := 7.0 * (1.0 - u) * fade
			var p := Vector2(cos(a), sin(a)) * rr
			var nrm := Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5))
			pts.append(p + nrm * w)
			pts2.insert(0, p - nrm * w)
		pts.append_array(pts2)
		if pts.size() >= 3:
			draw_colored_polygon(pts, Color(0.45, 0.78, 1.0, 0.65 * fade))
	draw_circle(Vector2.ZERO, 10.0 * fade + 3.0, Color(0.88, 0.97, 1.0, 0.9 * fade))
