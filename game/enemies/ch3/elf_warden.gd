class_name ElfWarden
extends EnemyBase
## 엘프 파수꾼 (docs/chapter3.md 4절) — 잎날 창 + 커다란 잎 방패. 숲 경계를 지키는 엘프. **비살상**:
## 체력이 다하면 쓰러지지 않고 창을 내려놓고 무릎 꿇은 뒤 "…물러나겠다." 하고 숲으로 사라진다.
## - 방패 막기: 앞에서 날아오는 화염탄을 보면 잎 방패를 든다(정면 화염탄 피해 0, "팅") → 막은 직후 바로 찌르기로 반격.
##   불기둥(발밑)·화염 폭풍·여우불·되쏜 화살은 방패를 넘는다. 등 뒤는 열려 있다.
## - 찌르기: 창을 뒤로 당김(창끝 붉게 번쩍 0.55초) → 3T 앞으로 내찌르며 미끄러짐.
## - 뛰어 찌르기: 세라가 멀거나 높으면 웅크림(착지 지점 붉은 표시 0.6초) → 포물선으로 뛰어 창을 아래로 내리꽂음.
## - 뒷걸음: 너무 가까우면 뒤로 한 번 뛰어 창 거리를 만든다.
## 그림은 인물 그림(CharacterVisual "elf_warden", elf_folk_draw.gd)을 자세로 바꿔 쓴다.

enum S { IDLE, ADVANCE, GUARD, THRUST_WINDUP, THRUST, LEAP_WINDUP, LEAP, LAND, BACKSTEP, RECOVER, FLINCH, YIELD }

const HP := 900
const WALK_T := 3.2
const THRUST_WINDUP := 0.55
const THRUST_TIME := 0.22
const THRUST_SPEED_T := 13.0
const LEAP_WINDUP := 0.6
const GUARD_TIME := 1.1
const RECOVER_TIME := 0.55
const REST := Vector2(0.9, 1.4)
const SHIELD_BYPASS: Array[StringName] = [&"pillar", &"fox_pillar", &"blast", &"storm", &"storm_final", &"reflect", &"meteor", &"phoenix", &"ward", &"ally"]

var state: S = S.IDLE
var leap_target := Vector2.INF
var _timer := 0.0
var _dur := 0.0
var _cd := 1.0
var _guard_cd := 0.0
var _yield_t := 0.0
var _flip: Node2D
var _cv: CharacterVisual
var _contact: EnemyAttackArea
var _spear: EnemyAttackArea
var _stomp: EnemyAttackArea
var _marker: LandMarker


func _build() -> void:
	max_hp = HP
	body_size = Vector2(14, 30)
	knock_mult = 0.6
	launch_mult = 0.6
	kind_id = "elf_warden"
	display_name = "엘프 파수꾼"
	subtitle = "숲 경계의 창"
	_flip = Node2D.new()
	add_child(_flip)
	_cv = CharacterVisual.new()
	_cv.setup("elf_warden")
	_flip.add_child(_cv)
	_visual = _flip
	_spear = add_attack_area(Vector2(42, 10), Vector2(26, -17), &"elf_warden")
	_spear.active = false
	_stomp = add_attack_area(Vector2(34, 16), Vector2(0, -8), &"elf_warden")
	_stomp.active = false
	_contact = add_attack_area(Vector2(12, 26), Vector2(0, -14), &"elf_warden")
	_contact.active = false


func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur
	var pose := "idle"
	match s:
		S.GUARD: pose = "guard"
		S.THRUST_WINDUP: pose = "windup"
		S.THRUST: pose = "attack"
		S.LEAP_WINDUP: pose = "guard"
		S.LEAP: pose = "attack"
		S.LAND: pose = "attack"
		S.FLINCH: pose = "hurt"
		S.YIELD: pose = "kneel"
		S.BACKSTEP: pose = "guard"
	_cv.set_pose(pose)


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_place(_spear, Vector2(26, -17))
	_flip.scale.x = facing
	_cv.walking = state == S.ADVANCE and absf(velocity.x) > 8.0
	_cv.modulate = Color(2, 2, 2) if flash_amount() > 0.0 else Color.WHITE
	_timer -= delta
	_guard_cd -= delta
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	var dy := p.global_position.y - global_position.y
	match state:
		S.IDLE:
			_enter(S.ADVANCE)
		S.ADVANCE:
			face_player()
			_cd -= delta
			var want := 0.0
			if adx > 3.0 * t and not _ledge(facing):
				want = facing * WALK_T * t
			velocity.x = move_toward(velocity.x, want, 700.0 * delta)
			if _guard_cd <= 0.0 and _bolt_incoming():
				_enter(S.GUARD, GUARD_TIME)
				_guard_cd = 2.5
				Sfx.play(&"block", -8.0)
			elif adx < 1.5 * t and absf(dy) < 2.0 * t and not _ledge(-facing):
				_enter(S.BACKSTEP, 0.35)
				velocity = Vector2(-facing * 7.0 * t, -200.0)
			elif _cd <= 0.0:
				if (adx > 7.0 * t or dy < -3.0 * t) and adx < 12.0 * t and is_on_floor():
					_start_leap(p)
				elif adx < 4.2 * t and absf(dy) < 2.0 * t:
					_enter(S.THRUST_WINDUP, Difficulty.telegraph(THRUST_WINDUP))
					Sfx.play(&"charger_windup", -4.0, 0.05)
		S.GUARD:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			face_player()
			if _timer <= 0.0:
				if adx < 5.0 * t:
					_enter(S.THRUST_WINDUP, Difficulty.telegraph(THRUST_WINDUP * 0.8))
				else:
					_enter(S.ADVANCE)
		S.THRUST_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter(S.THRUST, THRUST_TIME)
				_spear.active = true
				_spear.dodgeable = true
				velocity.x = facing * THRUST_SPEED_T * t
				Sfx.play(&"swing", 0.0, 0.1)
		S.THRUST:
			velocity.x = facing * THRUST_SPEED_T * t * clampf(_timer / _dur, 0.0, 1.0)
			if _ledge(facing):
				velocity.x = 0.0
			if _timer <= 0.0:
				_spear.active = false
				_enter(S.RECOVER, RECOVER_TIME)
		S.LEAP_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter(S.LEAP, 2.0)
				var to := leap_target - global_position
				var air := 0.62
				velocity = Vector2(to.x / air, -_gravity * air * 0.5 + to.y / air)
				_contact.active = true
				_contact.dodgeable = true
				Sfx.play(&"jump", -2.0, 0.1)
		S.LEAP:
			if is_on_floor() and _timer < 1.9:
				_land()
			elif _timer <= 0.0:
				_land()
		S.LAND:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_stomp.active = false
				_enter(S.RECOVER, RECOVER_TIME)
		S.BACKSTEP:
			if is_on_floor() and _timer <= 0.0:
				velocity.x = 0.0
				_enter(S.ADVANCE)
				_cd = minf(_cd, 0.3)
		S.RECOVER, S.FLINCH:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _timer <= 0.0:
				_enter(S.ADVANCE)
				_cd = Difficulty.rest(randf_range(REST.x, REST.y))


func _start_leap(p: Player) -> void:
	face_player()
	leap_target = _floor_under(p.global_position)
	_enter(S.LEAP_WINDUP, Difficulty.telegraph(LEAP_WINDUP))
	_marker = LandMarker.new()
	_marker.global_position = leap_target
	_marker.dur = _dur
	Fx.effect_parent().add_child(_marker)
	Sfx.play(&"charger_windup", -4.0, 0.05)


func _land() -> void:
	_contact.active = false
	_stomp.active = true
	_stomp.dodgeable = true
	_enter(S.LAND, 0.18)
	Sfx.play(&"slam", -3.0, 0.1)
	Fx.shake(0.15, 0.2)
	Fx.burst(global_position, 12, {direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 110.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(Color("#8ab060")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300)})
	if _marker and is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null


func _floor_under(pos: Vector2) -> Vector2:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(pos + Vector2(0, -8), pos + Vector2(0, 240), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	return pos if r.is_empty() else (r.position as Vector2)


## 앞에서 화염탄이 날아오는가 (막기 반응)
func _bolt_incoming() -> bool:
	for n in Fx.effect_parent().get_children():
		if n is FireBolt:
			var b := n as FireBolt
			var to := global_position.x - b.global_position.x
			if signf(to) == float(b.direction) and absf(to) < 6.0 * GameConst.TILE and absf(b.global_position.y - (global_position.y - 16.0)) < 20.0 \
					and signf(-to) == float(facing):
				return true
	return false


func _ledge(dir: int) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * 12, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 20), GameConst.L_WORLD | GameConst.L_PLATFORM)
	return space.intersect_ray(q).is_empty()


func _place(a: EnemyAttackArea, off: Vector2) -> void:
	var cs := a.get_child(0) as CollisionShape2D
	if cs:
		cs.position = Vector2(off.x * facing, off.y)


func modify_damage(hit: Hit) -> float:
	if state == S.GUARD and not hit.kind in SHIELD_BYPASS and not is_fox_hit(hit):
		var from := signf(hit.source_pos.x - global_position.x)
		if from == float(facing) or hit.direction == -facing:
			return 0.0
	return 1.0


func _on_blocked(hit: Hit) -> void:
	super(hit)
	# 막았다 → 가까우면 곧장 반격, 멀면 방패를 든 채 다가감
	if dist_to_player() < 5.0 * GameConst.TILE:
		_enter(S.THRUST_WINDUP, Difficulty.telegraph(THRUST_WINDUP * 0.7))


func _on_hit(hit: Hit, _dir: int) -> void:
	if state in [S.ADVANCE, S.RECOVER] and hit.damage >= 150:
		_enter(S.FLINCH, 0.3)
	if state == S.THRUST_WINDUP and hit.breaks_charge:
		_enter(S.FLINCH, 0.4)


func _resists_knockback(_hit: Hit) -> bool:
	return state == S.THRUST or state == S.LEAP


## 비살상: 쓰러지지 않고 물러난다
func _die(_dir: int) -> void:
	_alive = false
	if not respawns:
		GameState.mark_killed(uid)
	GameState.add("wardens_yielded")
	StyleRank.on_kill()
	Fx.hitstop(tuning.hitstop_kill)
	defeated.emit(self)
	collision_layer = 0
	_hurtbox.set_deferred("monitorable", false)
	for c in get_children():
		if c is EnemyAttackArea:
			(c as EnemyAttackArea).active = false
	if _marker and is_instance_valid(_marker):
		_marker.queue_free()
	_enter(S.YIELD)
	_yield_t = 0.0
	velocity.x = 0.0
	_cv.modulate = Color.WHITE
	Sfx.play(&"block", -4.0, 0.0)
	_float_text("…물러나겠다.")


func _float_text(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color("#d8f0c0"))
	l.add_theme_color_override("font_outline_color", Color("#0a140a"))
	l.add_theme_constant_override("outline_size", 3)
	l.position = global_position + Vector2(-26, -50)
	l.z_index = 30
	Fx.effect_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(l, "position:y", l.position.y - 8.0, 0.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func _physics_process(delta: float) -> void:
	super(delta)
	if _alive:
		return
	_yield_t += delta
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity * delta, 600.0)
		move_and_slide()
	# 무릎 꿇고(1.4초) → 잎이 흩날리며 숲으로 사라짐
	if _yield_t > 1.4:
		_cv.modulate.a = clampf(1.0 - (_yield_t - 1.4) / 0.6, 0.0, 1.0)
		if Engine.get_physics_frames() % 3 == 0:
			Fx.burst(global_position + Vector2(randf_range(-6, 6), -14), 2, {direction = Vector2(0.5, -1), spread = 40.0, speed_min = 20.0,
				speed_max = 50.0, lifetime = 0.8, gradient = Palette.fade_gradient(Color("#7ab450")), size_min = 1.0, size_max = 2.0, gravity = Vector2(10, -10)})
	if _yield_t > 2.1:
		queue_free()


## 뛰어 찌르기 착지 지점 표시 (붉은 고리)
class LandMarker extends Node2D:
	var dur := 0.6
	var _t := 0.0

	func _ready() -> void:
		z_index = 4

	func _process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		if _t > dur + 1.2:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / dur, 0.0, 1.0)
		var pulse := 0.6 + 0.4 * sin(_t * 30.0)
		var w := 22.0 - 8.0 * k
		draw_rect(Rect2(-w * 0.5, -2, w, 2), Color(Palette.DANGER, (0.35 + 0.55 * k) * pulse))
		draw_line(Vector2(0, -2), Vector2(0, -10 - 6.0 * (1.0 - k)), Color(Palette.DANGER, 0.5 * k * pulse), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -6), Vector2(3, -6), Vector2(0, -2)]), Color(Palette.DANGER, 0.7 * k * pulse))
