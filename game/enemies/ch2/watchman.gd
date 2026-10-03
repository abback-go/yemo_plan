extends EnemyBase
## 태엽 경비병 (docs/chapter2.md 4절) — 시계 구역·귀족 구역을 지키는 태엽 인형 병사.
## 정해진 길(제자리 ±patrol칸)을 순찰하며 투구의 등불로 앞을 비춘다(호박색 시야 부채꼴).
## 시야에 세라가 들어오면 "!" + 경보 종 → 싸움: 미늘창 찌르기 돌진(0.6초 예고) / 내려베기(0.7초 예고).
## 정면 장갑(피해 50%), **등의 태엽 열쇠가 약점(피해 200%)** — 몸을 돌리는 게 느려서(0.5초) 뒤로 돌아가면 된다.
## 귀족 구역 잠입: alarm_flag 속성을 주면 들켰을 때 그 플래그를 세운다(실패가 아니라 다른 길). 신호 alarmed.

signal alarmed

const KE := preload("res://enemies/ch2/k_enemy.gd")

enum S { PATROL, LOOK, ALERT, ADVANCE, TURN, THRUST_WINDUP, THRUST, SWEEP_WINDUP, SWEEP, RECOVER, STAGGER }

const HP := 800
const WALK_T := 1.6
const ADVANCE_T := 2.2
const VIEW_T := 7.0
const VIEW_ANGLE := 0.36 ## 라디안 (시야 반각)
const LOOK_TIME := 0.7
const ALERT_TIME := 0.8
const TURN_TIME := 0.5
const THRUST_WINDUP := 0.6
const THRUST_TIME := 0.32
const THRUST_SPEED_T := 15.0
const SWEEP_WINDUP := 0.7
const SWEEP_TIME := 0.18
const RECOVER_TIME := 0.7
const FRONT_MULT := 0.5
const KEY_MULT := 2.0
const BRASS := Color("#b08a3a")
const BRASS_L := Color("#e8c870")
const BRASS_D := Color("#6a4e20")
const IRON := Color("#4a4c58")
const IRON_L := Color("#7a7e8e")
const IRON_D := Color("#2a2a34")
const LAMP := Color("#ffc870")

var patrol := 5.0 ## 순찰 반경(타일). 방 데이터에서 바꿀 수 있음
var alarm_flag := "" ## 들켰을 때 세울 플래그
var state: S = S.PATROL
var home_x := 0.0
var _timer := 0.0
var _dur := 0.0
var _turn_to := 1
var _lost := 0.0
var _key_rot := 0.0
var _contact: EnemyAttackArea
var _thrust: EnemyAttackArea
var _sweep: EnemyAttackArea
var _alerted := false


func _build() -> void:
	max_hp = HP
	body_size = Vector2(18, 38)
	knock_mult = 0.25
	launch_mult = 0.3
	display_name = "태엽 경비병"
	subtitle = "멈추지 않는 순찰"
	kind_id = "watchman"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(16, 34), Vector2(0, -18), &"watchman", 1)
	_contact.dodgeable = false
	_thrust = add_attack_area(Vector2(30, 10), Vector2(24, -20), &"watchman", 1)
	_thrust.active = false
	_sweep = add_attack_area(Vector2(40, 40), Vector2(22, -20), &"watchman", 1)
	_sweep.active = false


func _ready() -> void:
	super()
	home_x = global_position.x
	_enter(S.PATROL, 0.0)


func _enter(s: S, d: float) -> void:
	state = s
	_timer = d
	_dur = d


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _place(a: EnemyAttackArea, off: Vector2) -> void:
	var cs := a.get_child(0) as CollisionShape2D
	if cs:
		cs.position = Vector2(off.x * facing, off.y)


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	_key_rot += delta * (2.0 if state == S.PATROL else 5.0)
	_place(_thrust, Vector2(24, -20))
	_place(_sweep, Vector2(22, -20))
	var p := player()
	if not engaged or p == null:
		velocity.x = 0.0
		return
	match state:
		S.PATROL:
			velocity.x = facing * WALK_T * t
			if (facing > 0 and global_position.x > home_x + patrol * t) or (facing < 0 and global_position.x < home_x - patrol * t) or is_on_wall() or _ledge():
				velocity.x = 0.0
				_enter(S.LOOK, LOOK_TIME)
			if int(_t * 4.0) % 2 == 0 and int((_t - delta) * 4.0) % 2 == 1:
				KE.snd(&"chain", &"chain", -16.0, 0.2) # 째깍
			if _sees(p):
				_alert()
		S.LOOK:
			velocity.x = 0.0
			if _sees(p):
				_alert()
			elif _timer <= 0.0:
				facing = -facing
				_enter(S.PATROL, 0.0)
		S.ALERT:
			velocity.x = 0.0
			if _timer <= 0.0:
				_enter(S.ADVANCE, 0.8)
		S.ADVANCE:
			_combat(delta, p)
		S.TURN:
			velocity.x = 0.0
			if _timer <= 0.0:
				facing = _turn_to
				_enter(S.ADVANCE, 0.3)
		S.THRUST_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _timer <= 0.0:
				_enter(S.THRUST, THRUST_TIME)
				_thrust.active = true
				_thrust.dodgeable = true
				KE.snd(&"spear", &"charger_charge", 0.0)
		S.THRUST:
			velocity.x = facing * THRUST_SPEED_T * t
			if _timer <= 0.0 or is_on_wall() or _ledge():
				_thrust.active = false
				velocity.x = facing * 2.0 * t
				_enter(S.RECOVER, Difficulty.rest(RECOVER_TIME))
		S.SWEEP_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_enter(S.SWEEP, SWEEP_TIME)
				_sweep.active = true
				_sweep.dodgeable = true
				KE.snd(&"swing", &"swing", 0.0)
				Fx.shake(0.15, 0.15)
				KE.debris(global_position + Vector2(facing * 34.0, 0), 8, Color("#9a9aa8"), Vector2(-facing, -1), 120.0)
		S.SWEEP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_sweep.active = false
				_enter(S.RECOVER, Difficulty.rest(RECOVER_TIME))
		S.RECOVER, S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_enter(S.ADVANCE, Difficulty.rest(0.5))


func _combat(delta: float, p: Player) -> void:
	var t := GameConst.TILE
	var dx := p.global_position.x - global_position.x
	var ahead := signf(dx) == float(facing)
	if not ahead and absf(dx) > 4.0:
		# 몸을 돌리는 게 느리다 (태엽 소리)
		_turn_to = -facing
		_enter(S.TURN, TURN_TIME)
		KE.snd(&"chain", &"chain", -8.0, 0.1)
		return
	velocity.x = move_toward(velocity.x, facing * ADVANCE_T * t if absf(dx) > 2.0 * t else 0.0, 500.0 * delta)
	# 멀리 오래 떨어지면 순찰로 돌아감
	if absf(dx) > 15.0 * t:
		_lost += delta
		if _lost > 5.0:
			_lost = 0.0
			_alerted = false
			_enter(S.PATROL, 0.0)
			return
	else:
		_lost = 0.0
	if _timer > 0.0 or absf(p.global_position.y - global_position.y) > 3.0 * t:
		return
	if absf(dx) < 2.8 * t:
		_enter(S.SWEEP_WINDUP, Difficulty.telegraph(SWEEP_WINDUP))
		KE.snd(&"charger_windup", &"charger_windup", -4.0)
	elif absf(dx) < 7.0 * t:
		_enter(S.THRUST_WINDUP, Difficulty.telegraph(THRUST_WINDUP))
		KE.snd(&"charger_windup", &"charger_windup", -4.0)


## 등불 시야: 앞쪽 부채꼴 안 + 벽에 가리지 않음
func _sees(p: Player) -> bool:
	if not p.is_alive():
		return false
	var eye := global_position + Vector2(facing * 6.0, -34)
	var to := p.center() - eye
	if to.length() > VIEW_T * GameConst.TILE:
		return false
	var ang := absf(wrapf(to.angle() - Vector2(facing, 0.12).angle(), -PI, PI))
	if ang > VIEW_ANGLE:
		return false
	var q := PhysicsRayQueryParameters2D.create(eye, p.center(), GameConst.L_WORLD)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _alert() -> void:
	_enter(S.ALERT, Difficulty.telegraph(ALERT_TIME))
	velocity.x = 0.0
	if not _alerted:
		_alerted = true
		alarmed.emit()
		if alarm_flag != "":
			GameState.set_flag(alarm_flag)
	KE.snd(&"bell_small", &"blip", 0.0)
	KE.snd(&"bell", &"checkpoint", -6.0)
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud and hud.has_method("banner") and alarm_flag != "":
		hud.banner("들켰다!", 1.0)


func _ledge() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(facing * 12, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 18), GameConst.L_WORLD | GameConst.L_PLATFORM)
	return space.intersect_ray(q).is_empty()


## 맞은 쪽: 1 정면, -1 등
func _side(hit: Hit) -> int:
	var from := 0.0
	if hit.direction != 0:
		from = -float(hit.direction)
	else:
		var dxs := hit.source_pos.x - global_position.x
		if absf(dxs) < 4.0:
			return 1
		from = signf(dxs)
	return 1 if from == float(facing) else -1


func modify_damage(hit: Hit) -> float:
	if hit.kind in [&"pillar", &"fox_pillar", &"blast", &"meteor", &"phoenix", &"storm_final"]:
		return 1.0
	return KEY_MULT if _side(hit) < 0 else FRONT_MULT


func _on_hit(hit: Hit, _dir: int) -> void:
	if _side(hit) < 0:
		# 태엽 열쇠 명중: 불꽃·톱니 튐
		Fx.burst(global_position + Vector2(-facing * 10.0, -24), 10, {spread = 120.0, direction = Vector2(-facing, -0.5), speed_min = 60.0,
			speed_max = 150.0, lifetime = 0.35, gradient = Palette.fade_gradient(BRASS_L), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300)})
		KE.snd(&"block", &"block", -4.0, 0.15)
		if state in [S.PATROL, S.LOOK]:
			_alert()
	elif state in [S.PATROL, S.LOOK]:
		_alert()


func _die(dir: int) -> void:
	KE.death_fx(global_position + Vector2(0, -20), BRASS_L)
	KE.debris(global_position + Vector2(0, -20), 20, BRASS, Vector2(dir, -1), 200.0)
	KE.snd(&"crumble", &"crumble", 0.0)
	super(dir)


# ─── 그림 ───────────────────────────────────────────────

func _col(c: Color, white: bool) -> Color:
	return Color.WHITE if white else c


func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var k := progress()
	var walk := 0.0
	if state == S.PATROL or (state == S.ADVANCE and absf(velocity.x) > 5.0):
		walk = sin(_t * 9.0)
	var turn_sq := 1.0
	if state == S.TURN:
		turn_sq = absf(cos(k * PI)) * 0.7 + 0.3
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(turn_sq, 1.0))
	var o := Vector2.ZERO
	var spear_a := -PI * 0.5 + 0.15 # 미늘창 (세움)
	var spear_hand := Vector2(7, -20)
	var warn := 0.0
	match state:
		S.THRUST_WINDUP:
			o = Vector2(-2 * k, 1.5 * k)
			spear_a = lerpf(-PI * 0.4, 0.05, k)
			spear_hand = Vector2(4, -20).lerp(Vector2(-2, -19), k)
			warn = KE.warn_pulse(_t, k)
		S.THRUST:
			o = Vector2(3, 1)
			spear_a = 0.0
			spear_hand = Vector2(12, -20)
		S.SWEEP_WINDUP:
			o = Vector2(-1, -1) * k
			spear_a = lerpf(-PI * 0.4, -PI * 0.9, k)
			spear_hand = Vector2(4, -28)
			warn = KE.warn_pulse(_t, k)
		S.SWEEP:
			spear_a = 0.5
			spear_hand = Vector2(12, -18)
		S.RECOVER:
			spear_a = 0.35
			spear_hand = Vector2(10, -16)
		S.ALERT:
			o = Vector2(0, -1) * sin(_t * 30.0)
	var steel := _col(IRON, white)
	# 등 태엽 열쇠 (뒤쪽, 돌아감)
	var kc := Vector2(-9, -24) + o
	var kr := _key_rot
	for i in 2:
		var a := kr + PI * i
		var tip := kc + Vector2(cos(a) * 1.5, sin(a) * 5.0)
		c.draw_line(kc, tip, KE.OUT, 4.0)
		c.draw_line(kc, tip, _col(BRASS_L, white), 2.0)
		c.draw_circle(tip, 2.2, _col(BRASS, white))
	c.draw_line(kc, kc + Vector2(3, 0), _col(BRASS_D, white), 2.0)
	if not white:
		c.draw_circle(kc, 3.0, Color(BRASS_L, 0.25 + 0.15 * sin(_t * 6.0)))
	# 다리 (관절 마디)
	var lift_f := maxf(walk, 0.0) * 2.0
	var lift_b := maxf(-walk, 0.0) * 2.0
	for leg in [[-4.0, lift_b, true], [2.0, lift_f, false]]:
		var lx: float = leg[0]
		var lift: float = leg[1]
		var back: bool = leg[2]
		var col := _col(IRON_D if back else IRON, white)
		c.draw_rect(Rect2(Vector2(lx - 0.5, -14 - lift) + o * 0.3, Vector2(5, 7)).grow(1.0), KE.OUT)
		c.draw_rect(Rect2(Vector2(lx - 0.5, -14 - lift) + o * 0.3, Vector2(5, 7)), col)
		c.draw_rect(Rect2(Vector2(lx, -7 - lift), Vector2(4, 7)), col.darkened(0.1))
		c.draw_circle(Vector2(lx + 2, -7.5 - lift), 1.5, _col(BRASS, white))
		c.draw_rect(Rect2(Vector2(lx - 1, -1 - lift), Vector2(6, 2)), _col(IRON_D, white))
	# 몸통: 둥근 쇠 동체 + 놋쇠 띠 + 시계 문양
	var body := Rect2(Vector2(-7, -33) + o, Vector2(14, 20))
	c.draw_rect(body.grow(1.0), KE.OUT)
	c.draw_rect(body, steel)
	c.draw_rect(Rect2(body.position, Vector2(14, 2)), _col(IRON_L, white))
	c.draw_rect(Rect2(body.position + Vector2(0, 8), Vector2(14, 2)), _col(BRASS, white))
	c.draw_rect(Rect2(body.position + Vector2(9, 2), Vector2(2, 16)), _col(IRON_L, white))
	if not white:
		var cc := body.position + Vector2(5, 14)
		c.draw_circle(cc, 3.0, BRASS_D)
		c.draw_circle(cc, 2.2, Color("#e8dcb0"))
		c.draw_line(cc, cc + Vector2(cos(_t), sin(_t)) * 1.8, IRON_D, 1.0)
	# 머리: 원통 투구 + 앞의 등불 (경보 땐 붉게)
	var hc := Vector2(1, -38) + o
	var helm := Rect2(hc + Vector2(-5, -5), Vector2(10, 9))
	c.draw_rect(helm.grow(1.0), KE.OUT)
	c.draw_rect(helm, steel)
	c.draw_rect(Rect2(helm.position, Vector2(10, 2)), _col(IRON_L, white))
	c.draw_rect(Rect2(hc + Vector2(-6, -7), Vector2(12, 2)), _col(BRASS, white))
	var lamp_col := LAMP
	if state in [S.ALERT, S.ADVANCE, S.THRUST_WINDUP, S.THRUST, S.SWEEP_WINDUP, S.SWEEP, S.RECOVER, S.TURN]:
		lamp_col = Color("#ff5a3a")
	c.draw_rect(Rect2(hc + Vector2(4, -2), Vector2(3, 4)), _col(lamp_col, white))
	if not white:
		c.draw_circle(hc + Vector2(6, 0), 4.0, Color(lamp_col, 0.3))
	# 미늘창 + 팔
	var dir := Vector2.from_angle(spear_a)
	var hand := spear_hand + o
	var butt := hand - dir * 12.0
	var tip := hand + dir * 20.0
	if warn > 0.0:
		c.draw_line(hand, tip, Color(KE.DANGER, 0.35 * warn), 6.0)
	c.draw_line(butt, tip, KE.OUT, 3.0)
	c.draw_line(butt, tip, _col(Color("#5a4030"), white), 1.4)
	var side := dir.orthogonal()
	var blade := PackedVector2Array([tip - dir * 2.0 + side * 1.5, tip + dir * 5.0, tip - dir * 2.0 - side * 1.5])
	c.draw_colored_polygon(blade, _col(Color("#d8dce8") if warn <= 0.0 else Color("#ffb0a0"), white))
	c.draw_colored_polygon(PackedVector2Array([tip - side * 1.0, tip - dir * 3.0 - side * 5.0, tip - dir * 5.0 - side * 1.0]), _col(Color("#c8ccd8"), white)) # 도끼날
	c.draw_line(Vector2(3, -30) + o, hand, KE.OUT, 4.0)
	c.draw_line(Vector2(3, -30) + o, hand, _col(IRON_L, white), 2.0)
	c.draw_rect(Rect2(hand - Vector2(1.5, 1.5), Vector2(3, 3)), _col(BRASS, white))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 경보 "!" (좌우 뒤집지 않음 — 그래서 scale.x로 되돌려 그림)
	if state == S.ALERT and not white:
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(facing), 1.0))
		var pop := clampf(k * 4.0, 0.0, 1.0)
		var ep := Vector2(0, -56)
		c.draw_circle(ep, 6.0 * pop, Color("#f4eee4"))
		c.draw_rect(Rect2(ep + Vector2(-1, -4), Vector2(2, 5)), KE.DANGER)
		c.draw_rect(Rect2(ep + Vector2(-1, 2), Vector2(2, 2)), KE.DANGER)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 등불 시야 부채꼴 (순찰 중에만, 은은한 호박색)
	if state in [S.PATROL, S.LOOK] and not white:
		var eye := Vector2(6, -34)
		var r := VIEW_T * GameConst.TILE
		var a0 := Vector2(1, 0.12).angle() - VIEW_ANGLE
		var a1 := Vector2(1, 0.12).angle() + VIEW_ANGLE
		var pts := PackedVector2Array([eye])
		for i in 9:
			var aa := lerpf(a0, a1, i / 8.0)
			pts.append(eye + Vector2(cos(aa), sin(aa)) * r)
		c.draw_colored_polygon(pts, Color(LAMP, 0.07 + 0.02 * sin(_t * 3.0)))
		c.draw_line(eye, eye + Vector2(cos(a0), sin(a0)) * r, Color(LAMP, 0.12), 1.0)
		c.draw_line(eye, eye + Vector2(cos(a1), sin(a1)) * r, Color(LAMP, 0.12), 1.0)
