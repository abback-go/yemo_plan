extends EnemyBase
## 하늘의 문 — 5장 최종 보스 14000 (docs/chapter5.md 4절, 8.11절). 바깥 신들에게 붙잡혀 "문"이 된 리라가
## 하늘 한가운데 거대한 흰 고리(문)의 중심에 매달려 있다. 고리에는 눈 여섯, 양옆에서 촉수 넷.
## 세라는 아홉 꼬리 구미호 완전 빙의(여우 모드 상시) — 플레이어 코드 담당. 모든 동료가 아래 지원 API로 돕는다.
##
## 싸움의 고리
##   · 눈(SkyGateEye, 각 500): 세라를 따라오는 흰 예고선 → 굳음 → 흰 빛줄기. 맞혀서 감기면 9초 뒤 다시 뜬다.
##     눈이 감길 때마다 문 가운데(리라)가 흔들려 큰 피해(최대 체력 2%).
##   · 장막: 눈이 셋 이상 떠 있으면 리라를 감싼 흰 장막 — 리라가 받는 피해 35%. 둘 이하면 100%.
##   · 촉수(SkyGateTendril, 각 700): 들어 올림(흰 예고) → 발판을 내리침. 잘리면 10초 동안 움츠림.
##   1페이즈(100~65%) 눈 + 촉수 / 2페이즈(65~30%) + 문 너머에서 거신의 손이 내려찍음 · 흰 빛의 비
##   3페이즈(30~10%) + 문이 빨아들임(가운데로 끌림) · 빙의된 리라의 흰 일섬
##   봉인(10% 이하) phase_changed(4): 문이 멎고 리라가 드러남(피해 2배). 대본이 푸른 불로 문을 잠재우는 장면을 넣는다.
##     0이 되면 seal 연출(문이 닫히며 흰빛이 푸른 불에 덮임) → defeated.
##
## 동료 지원 API (docs/chapter5.md 8.11절) — 대본·동료 AI가 부른다. from = 동료 위치(연출선의 시작), 없으면 화면 밖에서
##   signal support_needed(kind, pos)  kind: "tendril"(촉수가 내리치려 함) · "eye"(눈이 빛줄기를 모음) · "veil"(장막이 오래 유지됨)
##                                     · "shield"(화면 전체 공격이 옴) · "hand"(거신의 손) — pos = 그 대상 위치
##   cut_tendril(i = -1, from)  레오니: 촉수 하나를 벤다(가장 위험한 것). 성공하면 true
##   snipe_eye(i = -1, from)    엘라리엔: 눈 하나를 꿰뚫어 감김(빛을 모으는 눈 우선). 성공하면 true
##   holy_lance(sec = 5, from)  아우렐리아: 장막을 꿰뚫음 — sec초 동안 리라가 받는 피해 160%
##   star_shield(sec = 3)       아스트리드: 세라 둘레 별빛 결계 — sec초 동안 문의 공격이 세라에게 닿지 않음
##   frost_bind(sec = 4)        이졸데: 촉수를 얼림(공격 멈춤), 눈의 예고가 느려짐
##   stagger(sec)               동료 공용(Ally.special): 다음 공격을 늦추고 리라가 움찔
##   fire_volley(dmg = 300)     엠버린: 떠 있는 눈 모두에 불꽃
##   support_target(kind) -> Vector2  그 지원이 노릴 위치 (동료가 그쪽을 바라보거나 이동)
##   auto_support = true         동료 시스템 없이 시험할 때: support_needed가 나면 문이 스스로 지원을 흉내 낸다

signal support_needed(kind: String, pos: Vector2)

const T := GameConst.TILE
const RING_R := 150.0
const EYE_N := 6
const TENDRIL_N := 4
const P2_AT := 0.65
const P3_AT := 0.30
const SEAL_AT := 0.10

var phase := 1
var state := "dormant"
var auto_support := false
var lyra: CharacterVisual
var eyes: Array = []
var tendrils: Array = []
var pierce_t := 0.0
var shield_t := 0.0
var frost_t := 0.0
var suction := 0.0 ## 0~1 빨아들임 세기 (그림·물리)
var hand_pos := Vector2.INF ## 문 너머에서 내려오는 거신의 손 (전역)
var sealing := 0.0 ## 0~1 닫힘 연출
var _timer := 0.0
var _state_len := 1.0
var _cd := 2.0
var _attacks := 0
var _veil_t := 0.0
var _seq := 0
var _seq_t := 0.0
var _shield_node: Node2D
var _supports: Array = [] ## auto_support 예약: [{kind, t}]
var _dead_done := false


func _build() -> void:
	max_hp = 14000
	body_size = Vector2(20, 44)
	display_name = "하늘의 문"
	subtitle = "바깥 신들에게 붙잡힌 별"
	kind_id = "sky_gate"
	is_boss = true
	flying = true
	knock_mult = 0.0
	launch_mult = 0.0
	engaged = false
	collision_mask = 0
	var gv := GateVisual.new()
	gv.gate = self
	add_child(gv)
	lyra = CharacterVisual.new()
	lyra.setup("lyra")
	lyra.set_pose("possessed")
	lyra.position = Vector2(0, 8)
	_visual = lyra
	add_child(lyra)


func _ready() -> void:
	super._ready()
	_spawn_parts.call_deferred()


func _spawn_parts() -> void:
	for i in EYE_N:
		var e := SkyGateEye.new()
		e.gate = self
		e.index = i
		e.uid = uid + ":eye%d" % i
		e.respawns = true
		var a := -PI * 0.5 + (i - (EYE_N - 1) * 0.5) * 0.52
		e.position = Vector2(cos(a), sin(a)) * RING_R * Vector2(1.0, 0.75) + Vector2(0, -20)
		add_child(e)
		eyes.append(e)
	for i in TENDRIL_N:
		var td := SkyGateTendril.new()
		td.gate = self
		td.index = i
		td.side = -1.0 if i % 2 == 0 else 1.0
		td.uid = uid + ":tendril%d" % i
		td.respawns = true
		td.position = Vector2(td.side * RING_R * 0.98, -10.0 + (i / 2) * 70.0 - 30.0)
		add_child(td)
		tendrils.append(td)


func set_state(s: String, time := 0.0) -> void:
	state = s
	_timer = time
	_state_len = maxf(time, 0.001)


func progress() -> float:
	return clampf(1.0 - _timer / _state_len, 0.0, 1.0)


func open_eyes() -> int:
	var n := 0
	for e in eyes:
		if is_instance_valid(e) and e.is_open():
			n += 1
	return n


## 장막 (눈이 셋 이상 떠 있음)
func veiled() -> bool:
	return phase < 4 and open_eyes() >= 3 and pierce_t <= 0.0


func exposed() -> bool:
	return pierce_t > 0.0 or phase >= 4


func core() -> Vector2:
	return global_position + Vector2(0, -14)


# ─── 매 프레임 ──────────────────────────────────────────

func _ai(delta: float) -> void:
	_timer -= delta
	_seq_t += delta
	pierce_t = maxf(pierce_t - delta, 0.0)
	shield_t = maxf(shield_t - delta, 0.0)
	frost_t = maxf(frost_t - delta, 0.0)
	velocity = Vector2.ZERO
	_tick_auto_support(delta)
	_tick_shield()
	if veiled():
		_veil_t += delta
		if _veil_t > 8.0:
			_veil_t = 0.0
			_need("veil", core())
	else:
		_veil_t = 0.0
	if state == "dead":
		sealing = minf(sealing + delta * 0.5, 1.0)
		return
	if not engaged:
		return
	if state == "dormant":
		set_state("idle", 1.5)
		for e in eyes:
			e.engaged = true
		for td in tendrils:
			td.engaged = true
	_check_phase()
	var p := player()
	if p == null or not p.is_alive():
		return
	# 3페이즈: 문이 빨아들인다
	suction = move_toward(suction, 1.0 if (phase == 3 and state == "suction") else 0.0, delta * 2.0)
	if suction > 0.0 and shield_t <= 0.0:
		var to := core() - p.global_position
		if to.length() > 2.0 * T and p.state != Player.State.DASH:
			p.move_and_collide(to.normalized() * 2.6 * T * suction * delta)
	match state:
		"idle":
			_cd -= delta
			if _cd <= 0.0:
				_choose(p)
		"hand_wind":
			var k := progress()
			var gx: float = hand_pos.x
			var gy := _ground_at(gx, p.global_position.y - 4.0 * T)
			hand_pos = Vector2(gx, lerpf(global_position.y - RING_R, gy - 6.0 * T, k * k))
			if _timer <= 0.0:
				hand_pos.y = gy
				set_state("hand_rest", 0.8)
				Fx.shake(0.7, 0.4)
				StArt.sfx(&"colossus_step", &"slam", 2.0)
		"hand_rest":
			if _timer <= 0.0:
				set_state("hand_lift", 0.6)
		"hand_lift":
			hand_pos.y -= 600.0 * delta
			if _timer <= 0.0:
				hand_pos = Vector2.INF
				_end(1.0)
		"rain":
			if _seq < 3 and _seq_t > _seq * 0.9:
				for i in 4:
					var x := p.global_position.x + randf_range(-9.0, 9.0) * T
					var gy2 := _ground_at(x, p.global_position.y - 6.0 * T)
					StStrike.spawn(Vector2(x, gy2), "pillar", Vector2(18, 14.0 * T), Difficulty.telegraph(1.0), {"style": "white", "damage": 1, "cause": "sky_gate", "hold": 0.14, "fade": 0.4})
				_seq += 1
			if _timer <= 0.0:
				_end(1.0)
		"suction":
			if _timer <= 0.0:
				_end(1.2)
		"white_cut":
			if _timer <= 0.0:
				_end(1.4)
		"sealed":
			pass


func _end(rest: float) -> void:
	_cd = Difficulty.rest(rest)
	set_state("idle", 0.0)


func _choose(p: Player) -> void:
	_attacks += 1
	_seq = 0
	_seq_t = 0.0
	# 눈·촉수는 각자 알아서 공격한다. 문 자신은 큰 기술을 맡는다
	var opts: Array[String] = []
	if phase >= 2:
		opts.append_array(["hand", "rain"])
	if phase >= 3:
		opts.append_array(["suction", "white_cut"])
	if opts.is_empty():
		_cd = 1.5
		return
	var pick: String = opts[_attacks % opts.size()]
	match pick:
		"hand":
			hand_pos = Vector2(p.global_position.x, global_position.y - RING_R)
			var gy := _ground_at(p.global_position.x, p.global_position.y - 4.0 * T)
			set_state("hand_wind", Difficulty.telegraph(1.4))
			StStrike.spawn(Vector2(p.global_position.x, gy - 2.5 * T), "band", Vector2(6.0 * T, 5.0 * T), _timer, {"style": "white", "damage": 1, "cause": "sky_gate", "hold": 0.18, "fade": 0.4})
			_need("hand", Vector2(p.global_position.x, gy))
			StArt.sfx(&"sky_crack", &"growl", -2.0)
		"rain":
			set_state("rain", 3.4)
			StArt.sfx(&"sky_crack", &"pillar_warn", -2.0)
		"suction":
			set_state("suction", 4.0)
			StArt.sfx(&"sky_crack", &"storm", -2.0)
		"white_cut":
			# 빙의된 리라의 흰 일섬: 세라 높이로 화면을 가르는 띠
			var y := p.center().y
			set_state("white_cut", Difficulty.telegraph(1.3) + 0.6)
			StStrike.spawn(Vector2(global_position.x, y), "band", Vector2(60.0 * T, 2.6 * T), Difficulty.telegraph(1.3), {"style": "white", "damage": 2, "cause": "sky_gate", "hold": 0.16, "fade": 0.45, "shake": 0.4})
			_need("shield", Vector2(p.global_position.x, y))
			lyra.set_pose("sword_windup")
			var tw := create_tween()
			tw.tween_interval(_timer - 0.6)
			tw.tween_callback(func() -> void: lyra.set_pose("possessed"))


func _ground_at(x: float, from_y: float) -> float:
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 24.0 * T), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return from_y + 8.0 * T
	return (r["position"] as Vector2).y


func _check_phase() -> void:
	var k := float(hp) / max_hp
	if phase == 1 and k <= P2_AT:
		_go_phase(2)
	elif phase == 2 and k <= P3_AT:
		_go_phase(3)
	elif phase == 3 and k <= SEAL_AT:
		_go_phase(4)


func _go_phase(n: int) -> void:
	phase = n
	phase_changed.emit(n)
	Fx.flash(Color(1, 1, 1, 0.4), 0.3)
	Fx.shake(0.6, 0.5)
	StArt.sfx(&"sky_crack", &"explode", 2.0)
	if n == 4:
		# 봉인: 문이 멎는다
		set_state("sealed", 0.0)
		for td in tendrils:
			td.retract(999.0)
		hand_pos = Vector2.INF
		lyra.set_pose("hurt")


# ─── 지원 API ───────────────────────────────────────────

func _need(kind: String, pos: Vector2) -> void:
	support_needed.emit(kind, pos)
	if auto_support:
		_supports.append({"kind": kind, "t": 0.5})


func _tick_auto_support(delta: float) -> void:
	for s in _supports:
		s.t -= delta
	for i in range(_supports.size() - 1, -1, -1):
		var s: Dictionary = _supports[i]
		if float(s.t) <= 0.0:
			_supports.remove_at(i)
			match String(s.kind):
				"tendril", "hand": cut_tendril()
				"eye": snipe_eye()
				"veil": holy_lance()
				"shield": star_shield()


func support_target(kind: String) -> Vector2:
	match kind:
		"tendril":
			var td := _pick_tendril()
			return td.tip() if td else core()
		"eye":
			var e := _pick_eye()
			return e.global_position if e else core()
	return core()


func _pick_tendril() -> SkyGateTendril:
	var best: SkyGateTendril = null
	for td in tendrils:
		if not td.is_out():
			continue
		if best == null or td.danger() > best.danger():
			best = td
	return best


func _pick_eye() -> SkyGateEye:
	var best: SkyGateEye = null
	for e in eyes:
		if not e.is_open():
			continue
		if best == null or e.charge() > best.charge():
			best = e
	return best


func cut_tendril(i := -1, from := Vector2.INF) -> bool:
	var td: SkyGateTendril = tendrils[i] if i >= 0 and i < tendrils.size() else _pick_tendril()
	if td == null or not td.is_out():
		return false
	var at := td.tip()
	_slash_fx(from if from != Vector2.INF else at + Vector2(-60, 40), at, Color(1.0, 0.95, 0.8))
	td.retract(10.0)
	StArt.sfx(&"sword_slash", &"swing", 2.0)
	return true


func snipe_eye(i := -1, from := Vector2.INF) -> bool:
	var e: SkyGateEye = eyes[i] if i >= 0 and i < eyes.size() else _pick_eye()
	if e == null or not e.is_open():
		return false
	var src := from if from != Vector2.INF else e.global_position + Vector2(-260, 120)
	_slash_fx(src, e.global_position, Color(0.85, 1.0, 0.7))
	e.close_eye(9.0)
	StArt.sfx(&"arrow_hit", &"sniper_shot", 0.0)
	return true


func holy_lance(sec := 5.0, from := Vector2.INF) -> void:
	pierce_t = maxf(pierce_t, sec)
	var src := from if from != Vector2.INF else core() + Vector2(-300, 160)
	_slash_fx(src, core(), Color(1.0, 0.86, 0.45))
	Fx.ring(core(), 8.0, 60.0, Color(1.0, 0.86, 0.45), 0.5, 3.0)
	StArt.sfx(&"holy_charge", &"charger_charge", 2.0)


## 동료의 강한 일격 (Ally.special이 부름): 다음 공격이 sec초 늦어지고, 촉수가 잠깐 굳고, 가운데 리라가 움찔한다
func stagger(sec: float) -> void:
	if not engaged or state in ["dormant", "dead"]:
		return
	_cd = maxf(_cd, 0.0) + clampf(sec, 0.3, 2.5)
	frost_t = maxf(frost_t, sec * 0.5)
	if lyra:
		lyra.set_pose("hurt")
	Fx.ring(core(), 6.0, 50.0, StArt.STAR, 0.4, 2.0)


func star_shield(sec := 3.0) -> void:
	shield_t = maxf(shield_t, sec)
	StArt.sfx(&"ward", &"window", 0.0)


func frost_bind(sec := 4.0) -> void:
	frost_t = maxf(frost_t, sec)
	for td in tendrils:
		Fx.burst(td.tip(), 10, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.5, gradient = Palette.fade_gradient(Color(0.7, 0.9, 1.0)), add = true})
	StArt.sfx(&"ward", &"window", -2.0)


func fire_volley(dmg := 300) -> void:
	for e in eyes:
		if e.is_open():
			_slash_fx(e.global_position + Vector2(-200, 140), e.global_position, Color(1.0, 0.6, 0.3))
			var h := Hit.make(dmg, &"ally", e.global_position + Vector2(-10, 10))
			e.take_hit(h)


func _slash_fx(from: Vector2, to: Vector2, col: Color) -> void:
	var s := StStrike.spawn(from, "beam", Vector2(0, 5), 0.01, {"to": to, "damage": 0, "hold": 0.05, "fade": 0.35})
	s.modulate = col
	Fx.burst(to, 16, {spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.45, gradient = Palette.fade_gradient(col), add = true})


## 별빛 결계: 세라 둘레를 따라다니며, 그동안 문 쪽 공격(흰 탄·띠)을 지운다
func _tick_shield() -> void:
	var p := player()
	if shield_t > 0.0 and p:
		if _shield_node == null:
			_shield_node = ShieldDome.new()
			Fx.effect_parent().add_child(_shield_node)
		_shield_node.global_position = p.center()
		_shield_node.set("k", minf(shield_t, 1.0))
		p.set("_hurt_iframe", maxf(float(p.get("_hurt_iframe")), 0.1))
		for a in get_tree().get_nodes_in_group(&"enemy_attack"):
			if a is EnemyProjectile and (a as Node2D).global_position.distance_to(p.center()) < 30.0:
				(a as EnemyProjectile).pop()
	elif _shield_node != null:
		_shield_node.queue_free()
		_shield_node = null


# ─── 피격 ───────────────────────────────────────────────

func modify_damage(_hit: Hit) -> float:
	if not engaged or state in ["dormant", "dead"]:
		return 0.0
	if phase >= 4:
		return 2.0
	if pierce_t > 0.0:
		return 1.6
	if veiled():
		return 0.35
	return 1.0


## 눈이 감기면 문 가운데가 흔들림
func on_eye_closed(e: SkyGateEye) -> void:
	if state == "dead":
		return
	var dmg := int(max_hp * 0.02)
	hp = maxi(hp - dmg, int(max_hp * SEAL_AT) if phase < 4 else 1)
	Fx.damage_number(core() + Vector2(0, -30), dmg, true, true)
	Fx.ring(e.global_position, 4.0, 40.0, StArt.GOD_GLOW, 0.4, 2.0, false)
	StArt.sfx(&"sky_crack", &"crumble", 0.0)


func _die(_dir: int) -> void:
	if state == "dead":
		return
	state = "dead"
	hp = 0
	_alive = false
	GameState.add("kills")
	if not respawns:
		GameState.mark_killed(uid)
	_hurtbox.set_deferred("monitorable", false)
	for e in eyes:
		e.close_eye(9999.0)
	for td in tendrils:
		td.retract(9999.0)
	hand_pos = Vector2.INF
	suction = 0.0
	lyra.set_pose("down")
	var tw := create_tween()
	tw.tween_property(lyra, "position:y", lyra.position.y + 40.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Fx.slowmo(0.3, 1.2)
	Fx.flash(Color(0.6, 0.85, 1.0, 0.7), 0.8)
	Fx.ring(core(), 10.0, 26.0 * T, StArt.FOX_BLUE, 1.4, 4.0)
	StArt.sfx(&"sky_crack", &"explode", 4.0)
	defeated.emit(self)


## 별빛 결계 그림 (아스트리드)
class ShieldDome extends Node2D:
	var k := 1.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 8
		material = Fx.add_material

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var hexp := PackedVector2Array()
		for i in 7:
			var a := TAU * i / 6.0 + _t * 0.5
			hexp.append(Vector2(cos(a), sin(a)) * 28.0)
		draw_colored_polygon(hexp, Color(0.9, 0.88, 1.0, 0.1 * k))
		draw_polyline(hexp, Color(0.9, 0.88, 1.0, 0.8 * k), 1.0)
		for i in 6:
			StArt.star(self, hexp[i], 2.0, Color(1, 1, 1, k), _t)


## 고리에 박힌 눈 (맞히면 감김, 9초 뒤 다시 뜸)
class SkyGateEye extends EnemyBase:
	var gate: Node
	var index := 0
	var state := "open"
	var _timer := 2.0
	var _aim: StStrike
	var _closed_t := 0.0
	var _charge := 0.0

	func _build() -> void:
		max_hp = 500
		body_size = Vector2(20, 14)
		display_name = ""
		kind_id = "sky_gate_eye"
		is_elite = true
		flying = true
		knock_mult = 0.0
		launch_mult = 0.0
		collision_mask = 0
		engaged = false
		_timer = 2.0 + index * 0.7

	func is_open() -> bool:
		return state != "closed"

	func charge() -> float:
		return _charge

	func close_eye(sec: float) -> void:
		if state == "closed":
			_closed_t = maxf(_closed_t, sec)
			return
		state = "closed"
		_closed_t = sec
		_charge = 0.0
		if is_instance_valid(_aim):
			_aim.queue_free()
		_hurtbox.set_deferred("monitorable", false)
		if gate:
			gate.on_eye_closed(self)

	func _ai(delta: float) -> void:
		velocity = Vector2.ZERO
		if not engaged:
			return
		var p := player()
		var slow := 1.6 if gate and float(gate.frost_t) > 0.0 else 1.0
		match state:
			"closed":
				_closed_t -= delta
				if _closed_t <= 0.0:
					state = "open"
					hp = max_hp
					_hurtbox.set_deferred("monitorable", true)
					_timer = randf_range(1.5, 3.0)
			"open":
				_timer -= delta
				if _timer <= 0.0 and p and p.is_alive():
					state = "aim"
					_timer = Difficulty.telegraph(1.1) * slow
					_charge = 0.0
					_aim = StStrike.spawn(global_position, "beam", Vector2(0, 10), _timer, {"to": p.center(), "style": "white", "damage": 1, "cause": "sky_gate", "hold": 0.2, "fade": 0.3})
					if gate:
						gate._need("eye", global_position)
			"aim":
				_timer -= delta
				_charge = 1.0 - _timer / maxf(Difficulty.telegraph(1.1) * slow, 0.01)
				if is_instance_valid(_aim) and p and _timer > 0.3:
					_aim.to = global_position + (p.center() - global_position).normalized() * 40.0 * T
				if _timer <= 0.0:
					state = "open"
					_charge = 0.0
					_timer = Difficulty.rest(randf_range(3.5, 5.5)) + (2.0 if gate and gate.phase == 1 else 0.0)

	func _die(_dir: int) -> void:
		close_eye(9.0)

	func take_hit(hit: Hit) -> void:
		if state == "closed":
			return
		super.take_hit(hit)


## 고리 옆에서 뻗는 촉수 (들어 올림 → 내리침, 잘리면 움츠림)
class SkyGateTendril extends EnemyBase:
	var gate: Node
	var index := 0
	var side := 1.0
	var state := "idle"
	var out := 1.0 ## 0 = 움츠림, 1 = 뻗음
	var _timer := 3.0
	var _retract_t := 0.0
	var _target := Vector2.ZERO
	var _slam: EnemyAttackArea

	func _build() -> void:
		max_hp = 700
		body_size = Vector2(26, 26)
		display_name = ""
		kind_id = "sky_gate_tendril"
		is_elite = true
		flying = true
		knock_mult = 0.0
		launch_mult = 0.0
		collision_mask = 0
		engaged = false
		_timer = 3.0 + index * 1.3
		_slam = add_attack_area(Vector2(3.5 * T, 2.0 * T), Vector2.ZERO, &"sky_gate", 1)
		_slam.active = false

	func is_out() -> bool:
		return out > 0.5 and state != "retracted"

	func danger() -> float:
		return 2.0 if state == "raise" else (1.0 if state == "idle" else 0.0)

	## 촉수 끝 (전역)
	func tip() -> Vector2:
		var base := global_position
		match state:
			"raise":
				return base + Vector2(-side * 70.0, -90.0).lerp(Vector2(-side * 60.0, -110.0), 0.5)
			"slam", "rest":
				return _target
		var t := _t
		return base + Vector2(-side * (60.0 + sin(t * 1.3 + index) * 12.0), 40.0 + cos(t * 1.1 + index) * 16.0) * out

	func retract(sec: float) -> void:
		state = "retracted"
		_retract_t = sec
		_slam.active = false
		_hurtbox.set_deferred("monitorable", false)

	func _ai(delta: float) -> void:
		velocity = Vector2.ZERO
		if not engaged:
			return
		var frozen := gate != null and float(gate.frost_t) > 0.0
		var p := player()
		match state:
			"retracted":
				out = move_toward(out, 0.0, delta * 3.0)
				_retract_t -= delta
				if _retract_t <= 0.0:
					state = "idle"
					hp = max_hp
					_hurtbox.set_deferred("monitorable", true)
					_timer = 2.0
			"idle":
				out = move_toward(out, 1.0, delta * 1.5)
				if not frozen:
					_timer -= delta
				if _timer <= 0.0 and p and p.is_alive() and out > 0.9:
					state = "raise"
					_timer = Difficulty.telegraph(1.1)
					var gy := _ground(p.global_position.x, p.global_position.y - 3.0 * T)
					_target = Vector2(p.global_position.x, gy)
					StStrike.spawn(_target + Vector2(0, -T), "band", Vector2(3.5 * T, 2.0 * T), _timer, {"style": "white", "damage": 0, "hold": 0.0, "fade": 0.05})
					if gate:
						gate._need("tendril", _target)
			"raise":
				if not frozen:
					_timer -= delta
				if _timer <= 0.0:
					state = "slam"
					_timer = 0.12
			"slam":
				_timer -= delta
				if _timer <= 0.0:
					_slam.global_position = _target + Vector2(0, -T)
					_slam.active = true
					Fx.shake(0.35, 0.25)
					StArt.sfx(&"slam", &"slam", 0.0)
					Fx.burst(_target, 14, {direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 150.0, lifetime = 0.5,
						gradient = Palette.fade_gradient(StArt.GOD_WHITE), add = false})
					state = "rest"
					_timer = 0.7
			"rest":
				_timer -= delta
				if _timer < 0.55:
					_slam.active = false
				if _timer <= 0.0:
					state = "idle"
					_timer = Difficulty.rest(randf_range(3.0, 4.5))

	func _ground(x: float, from_y: float) -> float:
		var q := PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 20.0 * T), GameConst.L_WORLD | GameConst.L_PLATFORM)
		var r := get_world_2d().direct_space_state.intersect_ray(q)
		if r.is_empty():
			return from_y + 4.0 * T
		return (r["position"] as Vector2).y

	func _die(_dir: int) -> void:
		retract(10.0)
		Fx.burst(tip(), 20, {spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.6, gradient = Palette.fade_gradient(StArt.GOD_WHITE), add = false})

	func take_hit(hit: Hit) -> void:
		if state == "retracted":
			return
		super.take_hit(hit)


## 문 그림: 화면을 넘는 흰 고리, 그 안의 검은 바깥 하늘, 금(선), 촉수, 눈, 거신의 손, 장막
class GateVisual extends Node2D:
	var gate: Node

	func _ready() -> void:
		z_index = -4

	func _process(d: float) -> void:
		# 쓰러진 뒤(적 처리 멈춤)에도 문이 닫히는 연출은 계속
		if gate and gate.state == "dead":
			gate.sealing = minf(float(gate.sealing) + d * 0.45, 1.0)
		queue_redraw()

	func _draw() -> void:
		if gate == null:
			return
		var t: float = gate._t
		var seal: float = gate.sealing
		var r: float = RING_R
		var c := Vector2(0, -20)
		var open_k := 1.0 - seal
		# 안쪽: 검은 바깥 하늘 + 먼 별 + 소용돌이
		var inner := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			inner.append(c + Vector2(cos(a) * r * 0.86, sin(a) * r * 0.65) * open_k)
		if open_k > 0.02:
			draw_colored_polygon(inner, Color(0.02, 0.01, 0.05))
			for i in 30:
				var a2 := t * (0.05 + (i % 5) * 0.01) + i * 2.4
				var rr := fmod(i * 37.0, r * 0.8)
				draw_rect(Rect2(c + Vector2(cos(a2) * rr, sin(a2) * rr * 0.75) * open_k, Vector2.ONE), Color(0.8, 0.8, 1.0, 0.5))
			for k in 4:
				var sp := PackedVector2Array()
				for i in 24:
					var a3 := t * 0.4 + k * PI * 0.5 + i * 0.25
					var rr2 := (8.0 + i * 4.5) * open_k
					sp.append(c + Vector2(cos(a3) * rr2, sin(a3) * rr2 * 0.75))
				draw_polyline(sp, Color(0.9, 0.9, 1.0, 0.12), 1.0)
		# 흰 고리 (기하학 마디)
		var ring_col := StArt.GOD_WHITE.lerp(Color(0.55, 0.8, 1.0), seal)
		for i in 24:
			var a0 := TAU * i / 24.0 + t * 0.02
			var a1 := a0 + TAU / 24.0 * 0.86
			var p0 := c + Vector2(cos(a0) * r, sin(a0) * r * 0.75)
			var p1 := c + Vector2(cos(a1) * r, sin(a1) * r * 0.75)
			var q0 := c + Vector2(cos(a0) * r * 0.86, sin(a0) * r * 0.65)
			var q1 := c + Vector2(cos(a1) * r * 0.86, sin(a1) * r * 0.65)
			draw_colored_polygon(PackedVector2Array([p0, p1, q1, q0]), ring_col if i % 2 == 0 else StArt.GOD_SHADE.lerp(Color(0.4, 0.6, 0.9), seal))
			draw_line(p0, q0, StArt.GOD_LINE, 1.0)
		draw_arc(c, r + 6.0, 0, TAU, 64, Color(1, 1, 1, 0.25), 2.0)
		for i in 12:
			var a4 := TAU * i / 12.0 - t * 0.05
			draw_line(c + Vector2(cos(a4) * (r + 6.0), sin(a4) * (r + 6.0) * 0.75), c + Vector2(cos(a4) * (r + 30.0), sin(a4) * (r + 30.0) * 0.75), Color(1, 1, 1, 0.3), 1.0)
		# 봉인되는 푸른 불 (닫히는 중)
		if seal > 0.0:
			for i in 16:
				var a5 := TAU * i / 16.0
				StArt.foxfire(self, c + Vector2(cos(a5) * r, sin(a5) * r * 0.75), 6.0, t + i, seal)
		# 장막 (리라를 감싼 흰 막)
		if gate.veiled():
			var vk := 0.5 + 0.2 * sin(t * 3.0)
			draw_circle(Vector2(0, -14), 34.0, Color(1, 1, 1, 0.12 * vk))
			for i in 6:
				var a6 := TAU * i / 6.0 + t * 0.4
				draw_line(Vector2(0, -14) + Vector2.from_angle(a6) * 34.0, Vector2(0, -14) + Vector2.from_angle(a6 + TAU / 6.0) * 34.0, Color(1, 1, 1, 0.6 * vk), 1.0)
		elif gate.exposed():
			draw_arc(Vector2(0, -14), 30.0 + sin(t * 8.0) * 2.0, 0, TAU, 24, Color(1.0, 0.86, 0.45, 0.6), 2.0)
		# 리라를 붙든 흰 사슬(선)
		for i in 4:
			var a7 := -PI * 0.75 + i * PI * 0.5
			var far := c + Vector2(cos(a7) * r * 0.86, sin(a7) * r * 0.65)
			draw_line(Vector2(0, -14), far, Color(1, 1, 1, 0.35 * open_k), 1.0)
		# 촉수
		for td in gate.tendrils:
			_draw_tendril(td, t)
		# 눈
		for e in gate.eyes:
			var ep: Vector2 = to_local(e.global_position)
			var open: float = 0.0 if not e.is_open() else (0.7 + 0.3 * e.charge())
			var look: Vector2 = (to_local(_player_pos()) - ep).normalized()
			draw_circle(ep, 13.0, Color(0.05, 0.05, 0.1))
			StArt.god_eye(self, ep, 11.0, open, look, e.charge())
			if e.flash_amount() > 0.0:
				draw_circle(ep, 12.0, Color(1, 1, 1, 0.6))
		# 문 너머에서 내려오는 거신의 손
		var hp2: Vector2 = gate.hand_pos
		if hp2 != Vector2.INF:
			StColossusArt.draw_slam_hand(self, to_local(hp2), 70.0, StColossusArt.palette(0.05, 1.0))

	func _player_pos() -> Vector2:
		var w := World.get_world()
		if w and w.player:
			return w.player.center()
		return global_position + Vector2(0, 100)

	func _draw_tendril(td: Node, t: float) -> void:
		var base: Vector2 = to_local(td.global_position)
		var tip: Vector2 = to_local(td.tip())
		var out: float = td.out
		if out < 0.05:
			return
		var mid: Vector2 = base.lerp(tip, 0.5) + Vector2(sin(t * 1.7 + td.index) * 18.0, -30.0)
		var pts := PackedVector2Array()
		var n := 14
		for i in n + 1:
			var u := float(i) / n
			pts.append(base.lerp(mid, u).lerp(mid.lerp(tip, u), u))
		for i in n:
			var u2 := float(i) / n
			var w := lerpf(11.0, 3.0, u2) * out
			var col := StArt.GOD_WHITE if i % 2 == 0 else StArt.GOD_SHADE
			if td.flash_amount() > 0.0:
				col = Color.WHITE
			draw_line(pts[i], pts[i + 1], col, w)
			draw_circle(pts[i], w * 0.5, col)
			if i % 3 == 0:
				draw_line(pts[i] + (pts[i + 1] - pts[i]).orthogonal().normalized() * w * 0.5, pts[i] - (pts[i + 1] - pts[i]).orthogonal().normalized() * w * 0.5, StArt.GOD_LINE, 1.0)
		if td.state == "raise":
			draw_circle(tip, 6.0, Color(1, 1, 1, 0.5 + 0.3 * sin(t * 20.0)))
		if gate and float(gate.frost_t) > 0.0:
			for i in range(0, n, 3):
				draw_rect(Rect2(pts[i] - Vector2(2, 2), Vector2(4, 4)), Color(0.7, 0.9, 1.0, 0.8))

