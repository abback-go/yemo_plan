class_name FlameWard
extends Node2D
## 불꽃 방벽 (docs/magic.md): 세라 주위에 잠깐 불의 원. 그동안 세라는 다치지 않고,
## 날아온 적 탄은 되쏘고(reflect), 닿은 적은 불에 덴다(Hit.kind = ward). Lv3: 무언가를 막으면 주위 불꽃 폭발.
## 세라의 자식으로 붙어 따라다닌다. 퍼즐 장치(빛줄기 등)는 player.is_warding()·ward_center()로 읽는다.

var player: Player
var tuning: Tuning
var duration := 0.5
var radius := 32.0
var level := 1
var fox := false
var _t := 0.0
var _burned := {}
var _blocked := false
var _nova_done := false
var _flash := 0.0


func setup(p: Player, p_tuning: Tuning, p_level: int, p_fox: bool) -> void:
	player = p
	tuning = p_tuning
	level = p_level
	fox = p_fox
	duration = tuning.ward_time + (0.15 if level >= 2 else 0.0)
	radius = tuning.ward_radius_t * GameConst.TILE
	position = Vector2(0, -16)
	z_index = 7
	material = Fx.add_material


func _col() -> Color:
	return Color(0.45, 0.8, 1.0) if fox else Palette.FIRE_OUT


func _hot() -> Color:
	return Color(0.85, 0.97, 1.0) if fox else Palette.FIRE_HOT


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta * 4.0, 0.0)
	if _t >= duration:
		_finish()
		return
	var c := global_position
	var mult := (1.25 if level >= 2 else 1.0) * (1.2 if fox else 1.0)
	# 적 탄 되쏘기
	for pr in get_tree().get_nodes_in_group(&"enemy_projectile"):
		var n := pr as Node2D
		if n == null or not is_instance_valid(n) or n.global_position.distance_to(c) > radius + 6.0:
			continue
		if n.get("reflected") == true or n.get("active") == false:
			continue
		var back := Vector2.ZERO
		var v: Variant = n.get("_vel")
		if typeof(v) == TYPE_VECTOR2 and (v as Vector2).length() > 1.0:
			back = -(v as Vector2)
		else:
			back = n.global_position - c
		if n.has_method("reflect"):
			n.reflect(back, int(round(tuning.ward_reflect_damage * mult)))
			_on_block(n.global_position)
	# 근접 공격 영역·몸에 닿은 적은 데게
	for a in get_tree().get_nodes_in_group(&"enemy_attack"):
		var area := a as EnemyAttackArea
		if area == null or not area.active or area is EnemyProjectile:
			continue
		var owner_e := area.get_parent() as EnemyBase
		if owner_e == null or _burned.has(owner_e):
			continue
		if EnemyBase.dist_to_body(owner_e, c) <= radius + 4.0 or area.global_position.distance_to(c) <= radius:
			_burn(owner_e, mult)
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en == null or not en.is_alive() or _burned.has(en):
			continue
		if EnemyBase.dist_to_body(en, c) <= radius * 0.8:
			_burn(en, mult)
	queue_redraw()


func _burn(en: EnemyBase, mult: float) -> void:
	_burned[en] = true
	var h := Hit.make(int(round(tuning.ward_burn_damage * mult)), &"ward", global_position, int(signf(en.global_position.x - global_position.x)))
	h.knockback_t = 2.2
	h.hitstop = 0.08
	h.shake_t = 0.2
	h.breaks_charge = true
	h.ignores_knock_resist = true
	en.take_hit(h)
	_on_block(en.global_position + Vector2(0, -en.body_size.y * 0.5))


func _on_block(at: Vector2) -> void:
	_flash = 1.0
	Sfx.play(&"reflect", -2.0, 0.05)
	Fx.hitstop(0.05)
	Fx.burst(at, 10, {spread = 180.0, speed_min = 50.0, speed_max = 150.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(_hot()), add = true})
	GameState.add("ward_blocks")
	if level >= 3 and not _nova_done:
		_nova_done = true
		_nova()


## Lv3: 막는 순간 주위 4T 불꽃 폭발
func _nova() -> void:
	var c := global_position
	var r := 4.0 * GameConst.TILE
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en and en.is_alive() and EnemyBase.dist_to_body(en, c) <= r:
			var h := Hit.make(int(round(tuning.ward_nova_damage * (1.2 if fox else 1.0))), &"ward", c)
			h.knockback_t = 3.0
			h.launch_t = 1.5
			h.hitstop = 0.1
			h.shake_t = 0.3
			en.take_hit(h)
	Fx.ring(c, 6.0, r, _hot(), 0.35, 3.0)
	Fx.burst(c, 30, {spread = 180.0, speed_min = 80.0, speed_max = 240.0, lifetime = 0.45,
		gradient = Palette.fade_gradient(_col()), add = true})
	Fx.shake(0.3)
	Sfx.play(&"blast", -4.0)


func _finish() -> void:
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var k := clampf(_t / 0.08, 0.0, 1.0)
	var r := radius * (0.6 + 0.4 * k)
	var col := _col()
	var hot := _hot()
	draw_circle(Vector2.ZERO, r, Color(col, 0.10 + 0.15 * _flash))
	# 도는 불꽃 혀 12개
	for i in 12:
		var a := TAU * i / 12.0 + _t * 9.0
		var flick := 0.8 + 0.2 * sin(_t * 40.0 + i * 1.7)
		var p0 := Vector2(cos(a), sin(a)) * r
		var p1 := Vector2(cos(a + 0.18), sin(a + 0.18)) * (r + 7.0 * flick)
		var p2 := Vector2(cos(a + 0.36), sin(a + 0.36)) * r
		draw_colored_polygon(PackedVector2Array([p0, p1, p2]), Color(col, 0.85))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(hot, 0.9), 2.0)
	draw_arc(Vector2.ZERO, r - 3.0, 0.0, TAU, 40, Color(col, 0.5), 1.0)
	if _flash > 0.0:
		draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 40, Color(1, 1, 1, _flash), 2.0)
