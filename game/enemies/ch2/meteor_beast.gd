extends EnemyBase
## 운석수 (docs/chapter2.md 2절 10, 4절) — 2장 절정. 10년 전 떨어진 운석이 녹시스의 의식으로 깨어난 거대한 별의 짐승. 체력 6000.
## 등에 **별 수정 갑피** 셋: 갑피가 남아 있으면 몸에 들어가는 피해가 줄어든다(40% → 하나 깰 때마다 +20%).
##   갑피는 **되쏜 탄(Hit.kind = reflect)** 에만 깨진다 → 운석수가 뱉는 수정 조각을 불꽃 방벽으로 되쏘자.
## stagger(초): 동료 레오니가 "다리를 벤다!"로 부르는 공개 함수 — 무너져 엎드리고 **가슴의 핵이 드러남(피해 250%)**.
## ultimate(): 대본용 큰 일격(교장의 별 브로치가 막는 장면) — 하늘의 거대한 운석을 끌어내려 세라 자리에 떨어뜨림.
##   ultimate_harmless = true면 피해 없이 연출만. 신호 ultimate_started · ultimate_hit.
## 패턴: 앞발 내려찍기(돌 충격파 양옆 — 점프) · 돌진(벽에 박히면 1.2초 비틀) · 수정 조각 뱉기(되쏘기 재료) ·
##        유성우(2페이즈부터, 붉은 원) · 3페이즈(30%)는 모든 동작이 빨라진다.

signal staggered
signal ultimate_started
signal ultimate_hit

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")

enum S { DORMANT, RISE, STALK, STOMP_WINDUP, STOMP, CHARGE_WINDUP, CHARGE, WALL_STUN, SPIT_WINDUP, SPIT, RAIN_WINDUP, RAIN,
	STAGGER, ULT_GATHER, ULT_FALL, RECOVER, DEFEATED }

const HP := 6000
const BODY := Vector2(124, 84)
const SC := 1.35 ## 그림 배율 (화면을 압도하는 크기)
const WALK_T := 1.6
const STOMP_WINDUP := 0.75
const CHARGE_WINDUP := 0.9
const CHARGE_SPEED_T := 13.0
const WALL_STUN := 1.3
const SPIT_WINDUP := 0.55
const RAIN_WINDUP := 1.0
const ULT_GATHER := 2.6
const CARAPACE_BASE := 0.4
const CORE_MULT := 2.5
const ROCK := Color("#2a2434")
const ROCK_L := Color("#4a4060")
const ROCK_D := Color("#141018")
const CRACK := Color("#c89aff")
const CORE := Color("#f4e8ff")

var carapace := 3 ## 남은 별 수정 갑피 수
var phase := 1
var ultimate_harmless := false
var state: S = S.DORMANT
var _timer := 0.0
var _dur := 0.0
var _stagger_left := 0.0
var _last := ""
var _walk := 0.0
var _charge_frames := 0
var _rain_left := 0
var _rain_t := 0.0
var _broken_fx: Array[float] = [] ## 깨진 수정 자리 반짝임 시간
var _ult_target := Vector2.ZERO
var _contact: EnemyAttackArea
var _horn: EnemyAttackArea


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = HP
	body_size = BODY
	knock_mult = 0.0
	launch_mult = 0.0
	is_boss = true
	is_elite = false
	display_name = "운석수"
	subtitle = "10년 전 떨어진 별의 짐승"
	kind_id = "meteor_beast"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	_visual = v
	add_child(v)
	var fx := KE.Vis.new()
	fx.enemy = self
	fx.fn = _draw_fx
	fx.flip = false
	fx.z_index = 6
	add_child(fx)
	_contact = add_attack_area(Vector2(110, 66), Vector2(0, -40), &"meteor_beast", 1)
	_contact.dodgeable = false
	_horn = add_attack_area(Vector2(40, 44), Vector2(70, -40), &"meteor_beast", 1)
	_horn.active = false
	_broken_fx = [-9.0, -9.0, -9.0]


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD


func _enter(s: S, d: float) -> void:
	state = s
	_timer = d
	_dur = d


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _tg(sec: float) -> float:
	return Difficulty.telegraph(sec * (0.8 if phase >= 3 else 1.0))


func _rest(sec: float) -> float:
	return Difficulty.rest(sec * (0.75 if phase >= 3 else 1.0))


func _place(a: EnemyAttackArea, off: Vector2) -> void:
	var cs := a.get_child(0) as CollisionShape2D
	if cs:
		cs.position = Vector2(off.x * facing, off.y)


## 동료 레오니의 다리 베기: sec초 동안 무너져 핵을 드러낸다
func stagger(sec: float) -> void:
	if not _alive or state in [S.DORMANT, S.ULT_GATHER, S.ULT_FALL]:
		return
	_stagger_left = sec
	_horn.active = false
	_rain_left = 0
	_enter(S.STAGGER, sec)
	staggered.emit()
	Fx.shake(0.5, 0.4)
	KE.snd(&"colossus_step", &"slam", 4.0)
	KE.snd(&"crumble", &"crumble", 0.0)
	KE.debris(global_position + Vector2(0, -6), 24, Color("#8a8094"), Vector2.UP, 200.0)
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud and hud.has_method("banner"):
		hud.banner("핵이 드러났다!", 1.2)


## 대본용 큰 일격 (교장의 별 브로치 장면)
func ultimate() -> void:
	if not _alive:
		return
	_horn.active = false
	_enter(S.ULT_GATHER, ULT_GATHER)
	ultimate_started.emit()
	KE.snd(&"roar", &"roar", 4.0)
	Fx.shake(0.4, 1.0)


func is_staggered() -> bool:
	return state == S.STAGGER


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	_place(_horn, Vector2(70, -40))
	var p := player()
	_contact.active = engaged and _alive and state != S.DORMANT
	if state == S.DORMANT:
		velocity.x = 0.0
		if engaged:
			_enter(S.RISE, 1.2)
			KE.snd(&"roar", &"roar", 2.0)
			Fx.shake(0.5, 1.0)
		return
	if p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		return
	# 유성우 진행
	if _rain_left > 0:
		_rain_t -= delta
		if _rain_t <= 0.0:
			_rain_left -= 1
			_rain_t = 0.32 if phase < 3 else 0.24
			var x := p.global_position.x + randf_range(-6.0, 6.0) * t
			if _rain_left % 3 == 0:
				x = p.global_position.x
			KE.meteor(Vector2(x, KE.floor_at(self, x, p.global_position.y)), _tg(1.1), 24.0)
	var dx := p.global_position.x - global_position.x
	match state:
		S.RISE:
			if _timer <= 0.0:
				_enter(S.STALK, 0.8)
		S.STALK:
			face_player()
			var want := signf(dx) * WALK_T * t if absf(dx) > 7.0 * t else 0.0
			velocity.x = move_toward(velocity.x, want, 200.0 * delta)
			if absf(velocity.x) > 5.0:
				_walk += delta * 3.0
				if int(_walk * 2.0) != int((_walk - delta * 3.0) * 2.0):
					KE.snd(&"colossus_step", &"land", -6.0)
					Fx.shake(0.08, 0.1)
			if _timer <= 0.0:
				_choose(absf(dx) / t)
		S.STOMP_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_enter(S.STOMP, _rest(0.8))
				Fx.shake(0.6, 0.35)
				KE.snd(&"colossus_step", &"slam", 4.0)
				KE.debris(global_position + Vector2(facing * 40.0, 0), 20, Color("#8a8094"), Vector2.UP, 200.0)
				for d in [-1, 1]:
					KE.wave(global_position + Vector2(d * 68.0, 0), d, 11.0 * t, 20.0 * t, "rock", 18.0)
				if phase >= 2:
					var tw := create_tween()
					tw.tween_interval(0.5)
					tw.tween_callback(func() -> void:
						if _alive and state == S.STOMP:
							for d2 in [-1, 1]:
								KE.wave(global_position + Vector2(d2 * 68.0, 0), d2, 11.0 * t, 20.0 * t, "rock", 18.0))
		S.STOMP, S.RECOVER, S.SPIT, S.RAIN:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if _timer <= 0.0:
				_enter(S.STALK, _rest(0.6))
		S.CHARGE_WINDUP:
			velocity.x = 0.0
			if int(_t * 8.0) != int((_t - delta) * 8.0):
				KE.debris(global_position + Vector2(-facing * 40.0, 0), 4, Color("#8a8094"), Vector2(-facing, -1), 100.0)
			if _timer <= 0.0:
				_enter(S.CHARGE, 3.0)
				_charge_frames = 0
				_horn.active = true
				_horn.dodgeable = true
				_contact.dodgeable = true
				KE.snd(&"roar", &"charger_charge", 0.0)
		S.CHARGE:
			velocity.x = facing * CHARGE_SPEED_T * t * (1.15 if phase >= 3 else 1.0)
			_charge_frames += 1
			if int(_t * 5.0) != int((_t - delta) * 5.0):
				KE.snd(&"colossus_step", &"land", -2.0)
				Fx.shake(0.15, 0.1)
			if (is_on_wall() and _charge_frames > 3) or _timer <= 0.0:
				_horn.active = false
				_contact.dodgeable = false
				velocity.x = -facing * 60.0
				_enter(S.WALL_STUN, _rest(WALL_STUN))
				Fx.shake(0.8, 0.4)
				Fx.hitstop(0.06)
				KE.snd(&"slam", &"slam", 4.0)
				KE.snd(&"crumble", &"crumble", 0.0)
				KE.debris(global_position + Vector2(facing * 50.0, -30), 26, Color("#8a8094"), Vector2(-facing, -0.6), 200.0)
		S.WALL_STUN:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if _timer <= 0.0:
				_enter(S.STALK, _rest(0.4))
		S.SPIT_WINDUP:
			velocity.x = 0.0
			face_player()
			if _timer <= 0.0:
				var mouth := global_position + Vector2(facing * 76.0, -50)
				var aim := (p.center() - mouth).normalized()
				for i in 3:
					KE.shard(mouth, aim.rotated((i - 1) * 0.16), 6.5 * t, {"radius": 5.0, "life": 4.0, "cause": "meteor_shard"})
				KE.snd(&"star_burst", &"sniper_shot", 0.0)
				_enter(S.SPIT, _rest(0.7))
		S.RAIN_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_rain_left = 7 if phase < 3 else 10
				_rain_t = 0.0
				KE.snd(&"meteor_fall", &"whoosh", 2.0)
				_enter(S.RAIN, _rest(1.6))
		S.STAGGER:
			velocity.x = 0.0
			_stagger_left = _timer
			if int(_t * 6.0) != int((_t - delta) * 6.0):
				KE.star_burst(global_position + Vector2(facing * 40.0, -10), 4, CORE, 60.0, 0.4)
			if _timer <= 0.0:
				_enter(S.RECOVER, 0.8)
				KE.snd(&"roar", &"roar", 0.0)
		S.ULT_GATHER:
			velocity.x = 0.0
			_ult_target = Vector2(p.global_position.x, KE.floor_at(self, p.global_position.x, p.global_position.y))
			if _timer <= 0.0:
				var m := KE.meteor(_ult_target, 0.6, 64.0, CRACK, true)
				m.harmless = ultimate_harmless
				_enter(S.ULT_FALL, 1.0)
				KE.snd(&"meteor_fall", &"whoosh", 4.0)
				var tw2 := create_tween()
				tw2.tween_interval(0.6)
				tw2.tween_callback(func() -> void: ultimate_hit.emit())
		S.ULT_FALL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_enter(S.STALK, 1.0)


func _choose(adx: float) -> void:
	face_player()
	var options: Array[String] = ["stomp", "charge", "spit"]
	if adx < 6.0:
		options = ["stomp", "stomp", "spit", "charge"]
	elif adx > 12.0:
		options = ["charge", "spit", "spit"]
	if phase >= 2:
		options.append("rain")
	if carapace > 0:
		options.append("spit") # 되쏘기 재료를 자주 준다
	var pick: String = options[randi() % options.size()]
	if pick == _last:
		pick = options[(options.find(pick) + 1) % options.size()]
	_last = pick
	match pick:
		"stomp":
			_enter(S.STOMP_WINDUP, _tg(STOMP_WINDUP))
			KE.snd(&"growl", &"growl", 0.0)
		"charge":
			_enter(S.CHARGE_WINDUP, _tg(CHARGE_WINDUP))
			KE.snd(&"growl", &"charger_windup", 2.0)
		"spit":
			_enter(S.SPIT_WINDUP, _tg(SPIT_WINDUP))
			KE.snd(&"star_twinkle", &"pillar_warn", 0.0)
		"rain":
			_enter(S.RAIN_WINDUP, _tg(RAIN_WINDUP))
			KE.snd(&"roar", &"roar", 2.0)


func _body_mult() -> float:
	return CARAPACE_BASE + (3 - carapace) * 0.2


func modify_damage(hit: Hit) -> float:
	if not engaged or state in [S.DORMANT, S.DEFEATED]:
		return 0.0
	if state == S.STAGGER:
		return CORE_MULT
	if hit.kind == &"ally":
		return 1.0
	return _body_mult()


func _on_hit(hit: Hit, _dir: int) -> void:
	if hit.kind == &"reflect" and carapace > 0:
		carapace -= 1
		_broken_fx[carapace] = _t
		Fx.shake(0.3, 0.25)
		KE.snd(&"crumble", &"crumble", 2.0)
		KE.snd(&"star_burst", &"explode", -2.0)
		var at := _crystal_world(carapace)
		KE.star_burst(global_position + Vector2(at.x * facing, at.y), 30, CRACK, 200.0, 0.7)
		Fx.ring(global_position + Vector2(at.x * facing, at.y), 6.0, 40.0, CRACK, 0.4, 3.0)
		var hud := get_tree().get_first_node_in_group(&"hud")
		if hud and hud.has_method("banner"):
			hud.banner("별 수정 갑피가 깨졌다! (%d 남음)" % carapace if carapace > 0 else "갑피가 모두 깨졌다!", 1.2)
	elif hit.kind != &"reflect" and carapace > 0 and state != S.STAGGER and randf() < 0.3:
		# 갑피에 튕기는 불 — 줄어든 피해라는 걸 보여 줌
		KE.star_burst(global_position + Vector2(0, -50), 4, CRACK, 60.0, 0.25)
	if phase == 1 and hp < max_hp * 0.6:
		phase = 2
		phase_changed.emit(2)
		KE.snd(&"roar", &"roar", 4.0)
		Fx.shake(0.5, 0.6)
	elif phase == 2 and hp < max_hp * 0.3:
		phase = 3
		phase_changed.emit(3)
		enraged.emit()
		KE.snd(&"roar", &"roar", 6.0)
		Fx.shake(0.6, 0.8)
		Fx.flash(Color(CRACK, 0.25), 0.3)


func _resists_knockback(_hit: Hit) -> bool:
	return true


func _die(dir: int) -> void:
	_alive = false
	if not respawns:
		GameState.mark_killed(uid)
	GameState.add("kills")
	_enter(S.DEFEATED, 0.0)
	_rain_left = 0
	defeated.emit(self)
	collision_layer = 0
	_hurtbox.set_deferred("monitorable", false)
	for c in get_children():
		if c is EnemyAttackArea:
			(c as EnemyAttackArea).active = false
	Fx.hitstop(0.25)
	Fx.slowmo(0.3, 1.2)
	Fx.flash(Color(1, 1, 1, 0.6), 0.4)
	Fx.shake(0.8, 1.2)
	KE.snd(&"roar", &"roar", 4.0)
	KE.snd(&"star_burst", &"explode", 4.0)
	var c := global_position + Vector2(0, -34)
	var tw := create_tween()
	for i in 6:
		tw.tween_callback(func() -> void:
			KE.star_burst(c + Vector2(randf_range(-44, 44), randf_range(-24, 20)), 24, CRACK, 180.0, 0.8)
			KE.debris(c + Vector2(randf_range(-40, 40), 0), 10, Color("#5a5068"), Vector2(dir, -1), 220.0)
			KE.snd(&"crumble", &"crumble", 0.0))
		tw.tween_interval(0.22)
	tw.tween_callback(func() -> void:
		KE.death_fx(c, CRACK, true)
		Fx.ring(c, 10.0, 160.0, Color(1, 1, 1, 0.9), 0.8, 4.0))
	tw.tween_property(_visual, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)


# ─── 그림 ───────────────────────────────────────────────

func _crystal_pos(i: int) -> Vector2:
	var p: Vector2 = [Vector2(-22, -60), Vector2(-2, -66), Vector2(18, -60)][i]
	return p


## 화면(적 원점 기준)에서의 수정 자리 — 그림 배율 반영
func _crystal_world(i: int) -> Vector2:
	return _crystal_pos(i) * SC


func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var k := progress()
	var rock := Color.WHITE if white else ROCK
	var rock_l := Color.WHITE if white else ROCK_L
	var rock_d := Color(0.85, 0.85, 0.9) if white else ROCK_D
	var crack_a := 0.65 + 0.35 * sin(_t * 3.0)
	var o := Vector2.ZERO
	var head_drop := 0.0
	var rear := 0.0
	var mouth := 0.0
	var red := 0.0
	match state:
		S.DORMANT:
			o = Vector2(0, 10)
			head_drop = 10.0
			crack_a *= 0.3
		S.RISE:
			o = Vector2(0, 10.0 * (1.0 - k))
			head_drop = 10.0 * (1.0 - k)
		S.STOMP_WINDUP:
			rear = k
			red = KE.warn_pulse(_t, k)
		S.STOMP:
			o = Vector2(0, 3)
		S.CHARGE_WINDUP:
			head_drop = 8.0 * k
			o = Vector2(-4.0 * k, 2.0 * k)
			red = KE.warn_pulse(_t, k)
		S.CHARGE:
			head_drop = 8.0
			o = Vector2(0, sin(_t * 30.0) * 1.5)
		S.WALL_STUN:
			head_drop = 4.0
			o = Vector2(sin(_t * 40.0) * 1.5, 0)
		S.SPIT_WINDUP:
			mouth = k
			red = KE.warn_pulse(_t, k) * 0.6
		S.SPIT:
			mouth = 1.0 - k
		S.RAIN_WINDUP, S.ULT_GATHER:
			rear = 0.6
			mouth = 1.0
			red = KE.warn_pulse(_t, k)
		S.STAGGER:
			o = Vector2(0, 16)
			head_drop = 14.0
	var walk := sin(_walk * 3.0) if state == S.STALK else 0.0
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(SC, SC))
	# 다리 넷 (돌기둥, 뒤 → 앞)
	for i in 4:
		var front := i >= 2
		var lx := (-34.0 if not front else 24.0) + (8.0 if i % 2 == 1 else 0.0)
		var lift := maxf(walk * (1.0 if i % 2 == 0 else -1.0), 0.0) * 4.0
		var top := Vector2(lx, -24) + o
		if state == S.STAGGER:
			top += Vector2(0, 6)
		if rear > 0.0 and front:
			lift += rear * 14.0
		var col := rock_d if i % 2 == 0 else rock
		var leg := PackedVector2Array([top + Vector2(-7, 0), top + Vector2(7, 0), Vector2(lx + 6, -lift), Vector2(lx - 7, -lift)])
		c.draw_colored_polygon(leg, KE.OUT)
		c.draw_colored_polygon(PackedVector2Array([leg[0] + Vector2(1, 0), leg[1] + Vector2(-1, 0), leg[2] + Vector2(-1, -1), leg[3] + Vector2(1, -1)]), col)
		if not white:
			c.draw_line(top + Vector2(-2, 4), Vector2(lx - 1, -lift - 6), Color(CRACK, 0.5 * crack_a), 1.0)
		c.draw_rect(Rect2(Vector2(lx - 9, -lift - 4), Vector2(17, 4)), rock_d)
	# 몸통 (울퉁불퉁 운석 덩어리)
	var b := o + Vector2(0, -rear * 10.0)
	var body := PackedVector2Array([b + Vector2(-50, -26), b + Vector2(-40, -50), b + Vector2(-14, -62), b + Vector2(14, -60), b + Vector2(38, -50),
		b + Vector2(48, -34), b + Vector2(44, -18), b + Vector2(20, -12), b + Vector2(-20, -12), b + Vector2(-46, -16)])
	var outline := PackedVector2Array()
	for pt in body:
		outline.append(pt + (pt - (b + Vector2(0, -36))).normalized() * 1.5)
	c.draw_colored_polygon(outline, KE.OUT)
	c.draw_colored_polygon(body, rock)
	c.draw_colored_polygon(PackedVector2Array([b + Vector2(-40, -48), b + Vector2(-14, -60), b + Vector2(14, -58), b + Vector2(-4, -44), b + Vector2(-30, -40)]), rock_l)
	c.draw_colored_polygon(PackedVector2Array([b + Vector2(-46, -16), b + Vector2(-20, -12), b + Vector2(20, -12), b + Vector2(10, -20), b + Vector2(-30, -22)]), rock_d)
	# 빛나는 균열
	if not white:
		var cc := Color(CRACK.lerp(KE.DANGER, red), crack_a)
		c.draw_polyline(PackedVector2Array([b + Vector2(-44, -28), b + Vector2(-26, -34), b + Vector2(-10, -26), b + Vector2(8, -38), b + Vector2(30, -30), b + Vector2(44, -38)]), cc, 1.5)
		c.draw_line(b + Vector2(-26, -34), b + Vector2(-30, -48), cc, 1.0)
		c.draw_line(b + Vector2(8, -38), b + Vector2(6, -54), cc, 1.0)
		c.draw_line(b + Vector2(-10, -26), b + Vector2(-12, -14), cc, 1.0)
	# 가슴의 핵 (무너지면 드러나 크게 빛남)
	var core_c := b + Vector2(30, -22)
	if state == S.STAGGER and not white:
		var pk := 0.8 + 0.2 * sin(_t * 10.0)
		KArt.glow(c, core_c, 26.0, Color(CORE, 0.9), 4)
		c.draw_circle(core_c, 8.0, Color(CRACK, pk))
		c.draw_circle(core_c, 5.0, Color(CORE, 1.0))
		KArt.star4(c, core_c, 10.0 * pk, Color(1, 1, 1, 0.9))
	else:
		c.draw_circle(core_c, 3.0, Color(CRACK, 0.35 * crack_a) if not white else Color.WHITE)
	# 등의 별 수정 갑피 셋 (깨지면 그루터기만)
	for i in 3:
		var cp := _crystal_pos(i) + b
		if i < carapace:
			var cc2 := CRACK.lerp(Color.WHITE, 0.1)
			if white:
				cc2 = Color.WHITE
			KArt.crystal(c, cp + Vector2(0, 8), 20.0 + (4.0 if i == 1 else 0.0), cc2, crack_a, i)
		else:
			c.draw_colored_polygon(PackedVector2Array([cp + Vector2(-5, 8), cp + Vector2(-2, 2), cp + Vector2(3, 4), cp + Vector2(5, 8)]), rock_l)
			var since := _t - _broken_fx[i]
			if since < 1.0 and not white:
				for j in 5:
					var ang := TAU * j / 5.0
					KArt.star4(c, cp + Vector2(cos(ang), sin(ang)) * (4.0 + since * 30.0), 2.0 * (1.0 - since), Color(CRACK, 1.0 - since))
	# 머리: 수정 뿔 + 빛나는 눈 + 턱
	var hc := b + Vector2(52, -36 + head_drop)
	var head := PackedVector2Array([hc + Vector2(-12, -10), hc + Vector2(6, -14), hc + Vector2(18, -6), hc + Vector2(20, 4), hc + Vector2(6, 6 + mouth * 2.0), hc + Vector2(-10, 8)])
	var hout := PackedVector2Array()
	for pt2 in head:
		hout.append(pt2 + (pt2 - hc).normalized() * 1.5)
	c.draw_colored_polygon(hout, KE.OUT)
	c.draw_colored_polygon(head, rock)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-8, 6), hc + Vector2(16, 4 + mouth * 6.0), hc + Vector2(14, 10 + mouth * 8.0), hc + Vector2(-6, 12)]), rock_d)
	if mouth > 0.2 and not white:
		KArt.glow(c, hc + Vector2(14, 6 + mouth * 4.0), 10.0, Color(CRACK.lerp(KE.DANGER, red), 0.8), 3)
	# 뿔 (수정)
	var horn_col := CRACK.lerp(KE.DANGER, red) if not white else Color.WHITE
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-4, -11), hc + Vector2(-14, -30), hc + Vector2(2, -13)]), horn_col.darkened(0.2))
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(4, -13), hc + Vector2(8, -28), hc + Vector2(10, -11)]), horn_col)
	# 눈
	var eye_col := KE.DANGER if red > 0.0 or state == S.CHARGE else CORE
	c.draw_rect(Rect2(hc + Vector2(8, -6), Vector2(4, 2)), eye_col if not white else Color.WHITE)
	if not white:
		KArt.glow(c, hc + Vector2(10, -5), 7.0, Color(eye_col, 0.7), 2)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_fx(c: Node2D) -> void:
	var t := GameConst.TILE
	match state:
		S.STOMP_WINDUP:
			var a := KE.warn_pulse(_t, progress())
			for d in [-1.0, 1.0]:
				c.draw_line(Vector2(d * 72.0, -1), Vector2(d * (72.0 + 10.0 * t), -1), Color(KE.DANGER, 0.25 + 0.5 * a), 2.0)
		S.CHARGE_WINDUP:
			var a2 := KE.warn_pulse(_t, progress())
			c.draw_rect(Rect2(Vector2(80.0 if facing > 0 else -80.0 - 30.0 * t, -BODY.y * 0.8), Vector2(30.0 * t, BODY.y * 0.8)), Color(KE.DANGER, 0.06 + 0.1 * a2))
			c.draw_line(Vector2(facing * 80.0, -2), Vector2(facing * 30.0 * t, -2), Color(KE.DANGER, 0.3 + 0.5 * a2), 2.0)
		S.ULT_GATHER:
			# 하늘의 거대한 운석이 점점 커지며 다가온다 + 세라 자리의 붉은 원
			var k := progress()
			var rel := _ult_target - global_position
			var sky := Vector2(rel.x, -260.0 + k * 40.0)
			var r := 14.0 + k * 36.0
			KArt.glow(c, sky, r * 2.0, Color(CRACK, 0.7), 4)
			c.draw_circle(sky, r, ROCK_D)
			c.draw_circle(sky, r * 0.8, ROCK)
			c.draw_arc(sky, r, 0, TAU, 24, Color(CRACK, 0.8), 2.0)
			var a3 := KE.warn_pulse(_t, k)
			c.draw_set_transform(rel + Vector2(0, -2), 0.0, Vector2(1.0, 0.3))
			c.draw_arc(Vector2.ZERO, 64.0, 0, TAU, 32, Color(KE.DANGER, 0.4 + 0.5 * a3), 3.0)
			c.draw_circle(Vector2.ZERO, 64.0 * k, Color(KE.DANGER, 0.2 * a3))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
