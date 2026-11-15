class_name PhoenixCall
extends Node2D
## 불사조 (고급·금서, docs/archive/sera/magic.md): 세라의 몸에서 거대한 불사조(날개폭 약 90px)가 솟아 화면을 세 번 가른다.
## 지날 때마다 그 길의 적에게 큰 피해(관통, Hit.kind = phoenix), 불씨 비. 시작할 때 세라 체력 회복(Lv1 1, Lv2+ 2).
## Lv3의 "부활의 불꽃"은 Player가 처리하고, 연출만 이 노드로 한다(revive = true).

const RISE := 0.45
const PASS := 0.55
const PASSES := 3

var player: Player
var tuning: Tuning
var level := 1
var fox := false
var revive := false
var _t := 0.0
var _pos := Vector2.ZERO
var _dir := 1
var _pass := -1
var _hit := {}
var _flap := 0.0
var _trail: Array[Vector2] = []
var _y := 0.0


func setup(p: Player, p_tuning: Tuning, p_level: int, p_fox: bool, p_revive := false) -> void:
	player = p
	tuning = p_tuning
	level = p_level
	fox = p_fox
	revive = p_revive
	_dir = p.facing


func _ready() -> void:
	z_index = 9
	material = Fx.add_material
	_pos = player.center()
	global_position = Vector2.ZERO
	Sfx.play(&"phoenix_cry", 0.0, 0.0)
	Fx.flash(Color(_hot(), 0.35), 0.2)
	Fx.zoom_punch(0.08)
	Fx.burst(player.center(), 36, {spread = 180.0, speed_min = 60.0, speed_max = 220.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(_col()), add = true, gravity = Vector2(0, -60)})


func _col() -> Color:
	return Color(0.45, 0.8, 1.0) if fox else Palette.FIRE_OUT


func _hot() -> Color:
	return Color(0.85, 0.97, 1.0) if fox else Palette.FIRE_HOT


func _screen_rect() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var tl := inv * Vector2.ZERO
	var br := inv * Vector2(640, 360)
	return Rect2(tl, br - tl)


func _physics_process(delta: float) -> void:
	_t += delta
	_flap += delta * 9.0
	var sr := _screen_rect()
	if _t < RISE:
		var k := _t / RISE
		_pos = player.center().lerp(Vector2(player.center().x, sr.position.y + sr.size.y * 0.35), k * k)
		_y = _pos.y
	else:
		var p := int((_t - RISE) / PASS)
		if p >= PASSES:
			_pos += Vector2(_dir * 160.0, -260.0) * delta
			modulate.a = maxf(modulate.a - delta * 2.0, 0.0)
			if modulate.a <= 0.0:
				queue_free()
			_record()
			queue_redraw()
			return
		if p != _pass:
			_pass = p
			_hit.clear()
			if p > 0:
				_dir = -_dir
			_y = player.center().y - 20.0 + (p - 1) * 26.0
			Sfx.play(&"whoosh", -2.0, 0.1)
		var k2 := fmod(_t - RISE, PASS) / PASS
		var x0 := sr.position.x - 60.0
		var x1 := sr.end.x + 60.0
		var x := lerpf(x0, x1, k2) if _dir > 0 else lerpf(x1, x0, k2)
		_pos = Vector2(x, _y + sin(k2 * PI * 2.0) * 10.0)
		_strike()
		if Engine.get_physics_frames() % 2 == 0:
			Fx.burst(_pos + Vector2(-_dir * 20, 4), 3, {direction = Vector2(-_dir, 0.6), spread = 40.0, speed_min = 30.0, speed_max = 90.0,
				lifetime = 0.6, gradient = Palette.fade_gradient(_col()), gravity = Vector2(0, 160), add = true})
	_record()
	queue_redraw()


func _record() -> void:
	_trail.push_front(_pos)
	if _trail.size() > 18:
		_trail.pop_back()


func _strike() -> void:
	var dmg := int(round(tuning.phoenix_damage * Spells.dmg_mult("phoenix") * (1.2 if fox else 1.0)))
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en == null or not en.is_alive() or _hit.has(en):
			continue
		if EnemyBase.dist_to_body(en, _pos) <= 40.0:
			_hit[en] = true
			var h := Hit.make(dmg, &"phoenix", _pos, _dir)
			h.knockback_t = 2.0
			h.launch_t = 1.4
			h.hitstop = 0.06
			h.shake_t = 0.3
			h.breaks_charge = true
			en.take_hit(h)
			Fx.burst(en.global_position + Vector2(0, -en.body_size.y * 0.5), 16, {spread = 180.0, speed_min = 60.0, speed_max = 200.0,
				lifetime = 0.4, gradient = Palette.fade_gradient(_hot()), add = true})


func _draw() -> void:
	var col := _col()
	var hot := _hot()
	# 꼬리 깃(지나온 길을 따라 긴 불꽃)
	var prev := to_local(_pos)
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		draw_line(prev, p, Color(col, 0.7 * k), 16.0 * k + 1.0)
		draw_line(prev, p, Color(hot, 0.5 * k), 6.0 * k + 0.5)
		prev = p
	var c := to_local(_pos)
	var d := float(_dir)
	var flap := sin(_flap)
	draw_circle(c, 26.0, Color(col, 0.15))
	# 날개 (위아래로 퍼덕)
	for side in [-1.0, 1.0]:
		var tip := c + Vector2(-d * 18.0, side * (34.0 + flap * 10.0 * side))
		var mid := c + Vector2(d * 4.0, side * (16.0 + flap * 4.0 * side))
		draw_colored_polygon(PackedVector2Array([c + Vector2(d * 8.0, 0), mid, tip, c + Vector2(-d * 22.0, side * 8.0)]), Color(col, 0.85))
		draw_line(c + Vector2(d * 6.0, 0), tip, Color(hot, 0.8), 2.0)
	# 몸통·머리·부리
	draw_colored_polygon(PackedVector2Array([c + Vector2(d * 22.0, -2), c + Vector2(d * 6.0, -9), c + Vector2(-d * 16.0, -3),
		c + Vector2(-d * 16.0, 4), c + Vector2(d * 6.0, 8)]), hot)
	draw_circle(c + Vector2(d * 18.0, -4), 5.0, Color(1, 1, 0.92))
	draw_colored_polygon(PackedVector2Array([c + Vector2(d * 22.0, -6), c + Vector2(d * 31.0, -3), c + Vector2(d * 22.0, -1)]), Color("#ffd27a"))
	draw_circle(c + Vector2(d * 19.0, -5), 1.2, Color(0.3, 0.05, 0.05))
	# 볏
	for j in 3:
		draw_line(c + Vector2(d * (15.0 - j * 3.0), -8), c + Vector2(d * (12.0 - j * 4.0), -16 - j * 2 + flap * 2.0), Color(hot, 0.9), 1.5)
