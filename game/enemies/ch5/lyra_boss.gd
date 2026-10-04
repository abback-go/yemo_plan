extends EnemyBase
## 리라 — 별의 마녀 결전 (docs/chapter5.md 4절, 8.4절). 강자 보스 12000. 별의 탑 꼭대기(st_tower_top).
## "지금까지의 모든 인물을 합한 만큼 강하다": 아스트리드의 별 마법 → 레오니의 검 → 엘라리엔의 활 → 아우렐리아의 창을
## 모두 별빛으로 흉내 내고, 마지막엔 자기 자신의 마법 "별의 비".
##   1페이즈(100~75%) 별 마법: 별 다섯 개가 차례로 날아옴 · 세라 발밑의 별 마법진 셋(별기둥) · 비스듬히 떨어지는 혜성 넷
##   2페이즈(75~50%) 별검: 바닥 붉은 선 → 잔상 돌진 베기 · 3연 베기 · 받아치기 자세(화염탄을 베어 별로 되돌림) ·
##                   별의 일섬(1.4초 칼집 자세, 배경이 어두워지고 방을 가르는 빛의 띠 → 반대편에 나타남)
##   3페이즈(50~25%) 별자리 화살: 따라오는 예고선 → 붉게 굳음 → 저격(연속 두 발) · 다섯 갈래 부채 · 하늘에 별자리가 그려지고 그 별마다 빛기둥
##   4페이즈(25~10%) 별창: 광륜과 함께, 방을 가로지르는 신성 돌진(높이를 바꿔 세 번 연속) · 빛의 창 비
##   마지막(10% 이하) 별의 비: 하늘 가운데로 올라가 무적 — 레인 사이 빈칸만 남기고 쏟아지는 별 세 번 + 가운데 큰 별 →
##                     지쳐 내려옴(피해 1.5배), 느린 별만 쏘다 쓰러진다.
## 대본 연결: phase_changed(n) (2·3·4 = 페이즈, 5 = 별의 비), defeated. 전환 연출 동안 무적이며
##   hold_transition = true면 resume()을 부를 때까지 기다린다(그 사이 대본이 대사를 넣음). auto_lines = false면 기본 말풍선을 끈다.
##   say_line(text, sec)으로 머리 위 말풍선.

const T := GameConst.TILE
const P2_AT := 0.75
const P3_AT := 0.5
const P4_AT := 0.25
const FINALE_AT := 0.10
const LINES := {
	1: "나를 넘어 보렴, 나의 별.",
	2: "꼬마 아스트리드의 별은 이 정도. 이번엔… 검이야.",
	3: "맞히는 건 쉽대. 안 맞히는 게 어렵고.",
	4: "빛을 지키는 창. 정말 아름답지?",
	5: "이것이 나의 전부야. 받아 보렴!",
}

var phase := 1
var state := "dormant"
var hold_transition := false
var auto_lines := true
var weak := false ## 별의 비 뒤 지친 상태 (피해 1.5배)
var visual: CharacterVisual
var floor_y := 0.0
var left_x := 0.0
var right_x := 0.0
var _timer := 0.0
var _state_len := 1.0
var _cd := 1.0
var _attacks := 0
var _resume := false
var _pending_phase := 0
var _move_from := Vector2.ZERO
var _move_to := Vector2.ZERO
var _move_time := 0.0
var _move_t := 0.0
var _seq := 0
var _seq_t := 0.0
var _aim: StStrike
var _countered := false
var _dash_left := 0.0
var _bubble := ""
var _bubble_t := 0.0
var _dim := 0.0
var _dimmer: Node2D
var _const_pts: Array[Vector2] = [] ## 3페이즈 하늘의 별자리 (그림)
var _const_t := 0.0
var _orbs: Array[Vector2] = [] ## 1페이즈 준비된 별 (지역 오프셋)
var _contact: EnemyAttackArea
var _blade: EnemyAttackArea
var _body_hit: EnemyAttackArea
var _ghost_t := 0.0
var _down_done := false


func _build() -> void:
	max_hp = 12000
	body_size = Vector2(16, 40)
	display_name = "리라"
	subtitle = "별의 마녀"
	kind_id = "lyra_boss"
	is_boss = true
	flying = true
	knock_mult = 0.0
	launch_mult = 0.0
	engaged = false
	collision_mask = 0
	visual = CharacterVisual.new()
	visual.setup("lyra")
	visual.set_pose("idle")
	_visual = visual
	add_child(visual)
	_contact = add_attack_area(Vector2(12, 30), Vector2(0, -22), &"lyra", 1)
	_contact.dodgeable = false
	_contact.active = false
	_blade = add_attack_area(Vector2(40, 30), Vector2(20, -20), &"lyra", 1)
	_blade.active = false
	_body_hit = add_attack_area(Vector2(36, 34), Vector2(6, -20), &"lyra", 1)
	_body_hit.active = false
	_dimmer = Dimmer.new()
	_dimmer.boss = self
	add_child(_dimmer)
	var ov := Dimmer.new()
	ov.boss = self
	ov.overlay = true
	add_child(ov)


func _ready() -> void:
	super._ready()
	_setup_arena.call_deferred()


func _setup_arena() -> void:
	floor_y = global_position.y
	var w := World.get_world()
	var room_w := 640.0
	if w and w.room:
		room_w = w.room.size_px.x
	left_x = 2.5 * T
	right_x = room_w - 2.5 * T


func set_state(s: String, time := 0.0) -> void:
	state = s
	_timer = time
	_state_len = maxf(time, 0.001)


func progress() -> float:
	return clampf(1.0 - _timer / _state_len, 0.0, 1.0)


func dim() -> float:
	return _dim


func constellation() -> Array[Vector2]:
	return _const_pts


func constellation_k() -> float:
	return _const_t


func orbs() -> Array[Vector2]:
	return _orbs


func bubble() -> String:
	return _bubble if _bubble_t > 0.0 else ""


## 머리 위 말풍선 (대본·자동 대사)
func say_line(text: String, sec := 2.6) -> void:
	_bubble = text
	_bubble_t = sec


## 전환 연출을 붙잡아 둔 대본이 다 끝났을 때
func resume() -> void:
	_resume = true


func _pose(p: String) -> void:
	visual.set_pose(p)


# ─── 위치 ───────────────────────────────────────────────

func _glide(to: Vector2, time: float) -> void:
	_move_from = global_position
	_move_to = to
	_move_time = maxf(time, 0.01)
	_move_t = 0.0


func _blink(to: Vector2) -> void:
	_ghost("idle")
	Fx.burst(global_position + Vector2(0, -22), 22, {spread = 180.0, speed_min = 20.0, speed_max = 90.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(StArt.STAR), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -40), add = true})
	global_position = to
	_move_time = 0.0
	Fx.burst(global_position + Vector2(0, -22), 22, {spread = 180.0, speed_min = 80.0, speed_max = 20.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(StArt.STAR), size_min = 1.0, size_max = 2.5, add = true})
	StArt.sfx(&"star_twinkle", &"reveal", -4.0)


func _high(side: float) -> Vector2:
	return Vector2(left_x + 3.0 * T if side < 0.0 else right_x - 3.0 * T, floor_y - 8.0 * T)


func _low(side: float) -> Vector2:
	return Vector2(left_x + 2.0 * T if side < 0.0 else right_x - 2.0 * T, floor_y)


func _center_high() -> Vector2:
	return Vector2((left_x + right_x) * 0.5, floor_y - 10.0 * T)


## 잔상 (별빛 실루엣이 잠깐 남음)
func _ghost(pose: String) -> void:
	var g := CharacterVisual.new()
	g.setup("lyra")
	g.set_pose(pose)
	g.global_position = global_position
	g.scale = visual.scale
	g.modulate = Color(0.75, 0.82, 1.0, 0.55)
	g.material = Fx.add_material
	g.z_index = 4
	Fx.effect_parent().add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.45)
	tw.tween_callback(g.queue_free)


func _side_of_player() -> float:
	var p := player()
	if p == null:
		return 1.0
	return -1.0 if p.global_position.x < (left_x + right_x) * 0.5 else 1.0


# ─── 매 프레임 ──────────────────────────────────────────

func _ai(delta: float) -> void:
	if floor_y == 0.0:
		_setup_arena()
	_timer -= delta
	_bubble_t -= delta
	_const_t = maxf(_const_t - delta * 0.4, 0.0)
	visual.scale.x = float(facing)
	if _move_time > 0.0:
		_move_t += delta
		var k := clampf(_move_t / _move_time, 0.0, 1.0)
		global_position = _move_from.lerp(_move_to, k * k * (3.0 - 2.0 * k))
		if k >= 1.0:
			_move_time = 0.0
	velocity = Vector2.ZERO
	place_area(_blade, Vector2(20, -20))
	place_area(_body_hit, Vector2(6, -20))
	var want_dim := 0.0
	if state in ["ilseom", "rain_wind", "rain", "great_star"]:
		want_dim = 0.55
	_dim = move_toward(_dim, want_dim, delta * 2.0)
	if state == "dead":
		return
	if not engaged:
		if state == "dormant":
			_pose("idle")
		return
	if state == "dormant":
		_contact.active = true
		set_state("idle", 1.0)
		if auto_lines:
			say_line(LINES[1], 2.6)
	if _pending_phase == 0 and state != "transition":
		_check_phase(hp)
	if _pending_phase > 0 and state in ["idle", "recover"]:
		_start_transition(_pending_phase)
		_pending_phase = 0
	var p := player()
	if p == null or not p.is_alive():
		return
	match state:
		"idle":
			_cd -= delta
			if _move_time <= 0.0:
				face_player()
			if _cd <= 0.0 and _move_time <= 0.0:
				_choose(p)
		"recover":
			if _timer <= 0.0:
				set_state("idle", 0.0)
		"transition":
			_ai_transition(delta)
		_:
			match phase:
				1: _ai_p1(delta, p)
				2: _ai_p2(delta, p)
				3: _ai_p3(delta, p)
				4: _ai_p4(delta, p)
				_: _ai_finale(delta, p)


func _choose(p: Player) -> void:
	_attacks += 1
	_seq = 0
	_seq_t = 0.0
	face_player()
	match phase:
		1: _choose_p1(p)
		2: _choose_p2(p)
		3: _choose_p3(p)
		4: _choose_p4(p)
		_: _choose_weak(p)


func _end(rest: float) -> void:
	_cd = Difficulty.rest(rest)
	_blade.active = false
	_body_hit.active = false
	set_state("recover", 0.25)
	if phase == 1 or phase == 3:
		_pose("idle")
	elif phase == 2:
		_pose("sword")
	elif phase == 4:
		_pose("spear")


# ─── 1페이즈: 별 마법 (아스트리드식) ────────────────────

func _choose_p1(p: Player) -> void:
	if _attacks % 3 == 0 and _move_time <= 0.0:
		_glide(_high(-_side_of_player() if randf() < 0.5 else _side_of_player()) + Vector2(0, randf_range(-1, 1) * T), 0.8)
	match _attacks % 3:
		0:
			set_state("orbs", Difficulty.telegraph(0.6) + 5 * 0.16 + 0.8)
			_orbs.clear()
			_pose("cast")
		1:
			set_state("circles", 1.6)
			_pose("cast")
		_:
			set_state("comets_wind", Difficulty.telegraph(0.7))
			_pose("windup")
			StArt.sfx(&"star_twinkle", &"charger_windup", -2.0)


func _ai_p1(delta: float, p: Player) -> void:
	_seq_t += delta
	match state:
		"orbs":
			var wind := Difficulty.telegraph(0.6)
			# 하나씩 생겨남
			while _orbs.size() < 5 and _seq_t > _orbs.size() * 0.12:
				var a := -PI * 0.5 + (_orbs.size() - 2) * 0.55
				_orbs.append(Vector2(cos(a) * 20.0, sin(a) * 14.0 - 24.0))
				StArt.sfx_pitch(&"star_twinkle", &"blip", 1.0 + _orbs.size() * 0.1, -8.0)
			if _seq_t > wind + 0.4:
				var fired := int((_seq_t - wind - 0.4) / 0.16) + 1
				while _seq < mini(fired, 5) and not _orbs.is_empty():
					var o: Vector2 = _orbs.pop_front()
					var from := global_position + Vector2(o.x * facing, o.y)
					StShot.fire(from, (p.center() - from).normalized(), 9.5 * T, "star", {"radius": 4.0, "damage": 1, "cause": "lyra", "homing": 0.7, "life": 4.0})
					StArt.sfx(&"star_twinkle", &"shoot", -4.0)
					_pose("attack")
					_seq += 1
			if _timer <= 0.0:
				_orbs.clear()
				_end(0.9)
		"circles":
			if _seq < 3 and _seq_t > _seq * 0.42:
				var x := p.global_position.x + p.velocity.x * 0.15
				var gy := _ground_at(x, p.global_position.y - 8.0)
				StStrike.spawn(Vector2(x, gy), "pillar", Vector2(2.4 * T, 7.0 * T), Difficulty.telegraph(0.9), {"damage": 1, "cause": "lyra", "hold": 0.14, "fade": 0.35, "sound": "star_burst", "shake": 0.08})
				# 바닥의 별 마법진
				_seq += 1
				StArt.sfx(&"star_twinkle", &"pillar_warn", -4.0)
			if _timer <= 0.0:
				_end(0.8)
		"comets_wind":
			if _timer <= 0.0:
				set_state("comets", 1.4)
				_pose("special")
		"comets":
			if _seq < 4 and _seq_t > _seq * 0.26:
				var side := 1.0 if _seq % 2 == 0 else -1.0
				var gx := p.global_position.x + randf_range(-5.0, 5.0) * T
				var gy := _ground_at(gx, floor_y - 2.0 * T)
				var from := Vector2(gx - side * 9.0 * T, floor_y - 16.0 * T)
				StStrike.spawn(from, "beam", Vector2(0, 14), Difficulty.telegraph(0.85), {"to": Vector2(gx, gy), "damage": 1, "cause": "lyra", "hold": 0.12, "fade": 0.4, "sound": "meteor_impact", "shake": 0.15})
				_seq += 1
			if _timer <= 0.0:
				_end(1.0)


# ─── 2페이즈: 별검 (레오니식) ───────────────────────────

func _choose_p2(p: Player) -> void:
	var adx := absf(p.global_position.x - global_position.x)
	if _attacks % 4 == 0:
		# 별의 일섬: 세라 반대쪽 끝으로 가서 칼집 자세
		var side := -_side_of_player()
		_blink(_low(side))
		facing = -int(side)
		set_state("ilseom", Difficulty.telegraph(1.4))
		_pose("sword_windup")
		var band_y := floor_y - 1.4 * T
		StStrike.spawn(Vector2((left_x + right_x) * 0.5, band_y), "band", Vector2(right_x - left_x + 4.0 * T, 2.6 * T), _timer,
			{"damage": 2, "cause": "lyra", "hold": 0.14, "fade": 0.4, "shake": 0.5, "sound": "sword_slash"})
		StArt.sfx(&"bow_draw", &"charger_windup", 0.0)
		if auto_lines and _attacks <= 4:
			say_line("…일섬.", 1.6)
		return
	if adx < 3.5 * T and randf() < 0.55:
		_seq = 0
		set_state("triple_wind", Difficulty.telegraph(0.32))
		_pose("sword")
		return
	if adx > 6.0 * T and randf() < 0.3:
		set_state("guard", 1.3)
		_pose("guard")
		StArt.sfx(&"parry", &"block", -4.0)
		return
	# 잔상 돌진 베기
	if absf(global_position.y - floor_y) > 4.0:
		_glide(Vector2(global_position.x, floor_y), 0.3)
	set_state("dash_wind", Difficulty.telegraph(0.6))
	_pose("sword_windup")
	var reach := minf(absf((right_x if facing > 0 else left_x) - global_position.x), 13.0 * T)
	StStrike.spawn(Vector2(global_position.x + facing * reach * 0.5, floor_y - 18.0), "band", Vector2(reach, 30), _timer, {"damage": 0, "hold": 0.0, "fade": 0.05})
	StArt.sfx(&"charger_windup", &"charger_windup", -2.0)


func _ai_p2(delta: float, p: Player) -> void:
	_seq_t += delta
	match state:
		"dash_wind":
			if _timer <= 0.0:
				_dash_left = minf(absf((right_x if facing > 0 else left_x) - global_position.x), 13.0 * T)
				set_state("dash", 0.8)
				_body_hit.active = true
				_body_hit.dodgeable = true
				_pose("sword_attack")
				StArt.sfx(&"dash", &"dash", 0.0)
		"dash":
			var step := 28.0 * T * delta
			global_position.x += facing * step
			_dash_left -= step
			_ghost_t -= delta
			if _ghost_t <= 0.0:
				_ghost_t = 0.05
				_ghost("sword_attack")
			if _dash_left <= 0.0 or _timer <= 0.0:
				_body_hit.active = false
				_blade.active = true
				_blade.dodgeable = true
				set_state("dash_cut", 0.16)
				StArt.sfx(&"sword_slash", &"swing", 2.0)
		"dash_cut":
			if _timer <= 0.0:
				_end(0.8)
		"triple_wind":
			if _timer <= 0.0:
				_blade.active = true
				_blade.dodgeable = true
				global_position.x += facing * (6.0 + _seq * 3.0)
				set_state("triple_hit", 0.12)
				_pose("sword_attack")
				StArt.sfx(&"sword_slash", &"swing", -2.0 + _seq)
		"triple_hit":
			if _timer <= 0.0:
				_blade.active = false
				_seq += 1
				if _seq < 3:
					face_player()
					_pose("sword")
					set_state("triple_wind", Difficulty.telegraph(0.28 if _seq == 1 else 0.4))
				else:
					_end(0.9)
		"guard":
			face_player()
			if _countered:
				_countered = false
				# 베어 낸 불이 별이 되어 되돌아감
				for i in 3:
					var dir := (p.center() - global_position + Vector2(0, 22)).normalized().rotated((i - 1) * 0.18)
					StShot.fire(global_position + Vector2(facing * 12, -22), dir, 13.0 * T, "star", {"radius": 3.5, "damage": 1, "cause": "lyra", "life": 3.0})
				_pose("sword_attack")
				StArt.sfx(&"parry", &"block", 2.0)
				set_state("guard_out", 0.35)
			elif _timer <= 0.0:
				_end(0.5)
		"guard_out":
			if _timer <= 0.0:
				_end(0.7)
		"ilseom":
			if _timer <= 0.0:
				# 섬광 → 반대편에 나타남
				Fx.flash(Color(1.0, 0.97, 0.85, 0.5), 0.2)
				_ghost("sword_windup")
				var to_x := right_x - 2.0 * T if facing > 0 else left_x + 2.0 * T
				global_position.x = to_x
				_pose("sword_attack")
				set_state("ilseom_after", 0.9)
		"ilseom_after":
			if _timer <= 0.0:
				_end(1.1)


# ─── 3페이즈: 별자리 화살 (엘라리엔식) ──────────────────

func _choose_p3(p: Player) -> void:
	# 높은 곳에서 쏜다: 매번 다른 높은 자리로
	var side := -_side_of_player()
	if randf() < 0.5:
		_blink(_high(side) + Vector2(0, randf_range(-2.0, 1.0) * T))
	face_player()
	match _attacks % 3:
		0:
			_seq = 0
			_start_aim(p)
		1:
			set_state("fan_wind", Difficulty.telegraph(0.6))
			_pose("bow_draw")
			StArt.sfx(&"bow_draw", &"sniper_aim", -2.0)
		_:
			set_state("sky_wind", Difficulty.telegraph(0.55))
			_pose("bow_draw")
			StArt.sfx(&"bow_draw", &"sniper_aim", -2.0)


func _bow_pos() -> Vector2:
	return global_position + Vector2(facing * 14.0, -25.0 - visual.get_meta("ly_st", {}).get("float", 5.0))


func _start_aim(p: Player) -> void:
	set_state("aim", Difficulty.telegraph(0.8 + 0.25))
	_pose("bow_draw")
	StArt.sfx(&"bow_draw", &"sniper_aim", -2.0)
	_clear_aim()
	_aim = StStrike.spawn(_bow_pos(), "beam", Vector2(0, 3), _timer, {"to": p.center(), "damage": 0, "hold": 0.0, "fade": 0.05})


func _clear_aim() -> void:
	if is_instance_valid(_aim):
		_aim.queue_free()
	_aim = null


func _ai_p3(delta: float, p: Player) -> void:
	_seq_t += delta
	match state:
		"aim":
			face_player()
			if is_instance_valid(_aim):
				_aim.global_position = _bow_pos()
				if _timer > Difficulty.telegraph(0.25):
					_aim.to = _bow_pos() + (p.center() - _bow_pos()).normalized() * 40.0 * T
			if _timer <= 0.0:
				var to := _aim.to if is_instance_valid(_aim) else p.center()
				_clear_aim()
				var dir := (to - _bow_pos()).normalized()
				StShot.fire(_bow_pos(), dir, 32.0 * T, "arrow", {"radius": 3.0, "damage": 1, "cause": "lyra", "life": 2.0, "hits_world": false})
				StArt.sfx(&"arrow_shot", &"sniper_shot", 0.0)
				_pose("bow_release")
				_seq += 1
				set_state("aim_rel", 0.3)
		"aim_rel":
			if _timer <= 0.0:
				if _seq < 2:
					_start_aim(p)
				else:
					_end(0.8)
		"fan_wind":
			face_player()
			if _timer <= 0.0:
				var base := (p.center() - _bow_pos()).normalized()
				for i in 5:
					StShot.fire(_bow_pos(), base.rotated((i - 2) * 0.16), 20.0 * T, "arrow", {"radius": 3.0, "damage": 1, "cause": "lyra", "life": 2.5, "hits_world": false})
				StArt.sfx(&"arrow_shot", &"sniper_shot", 0.0)
				_pose("bow_release")
				set_state("fan_rel", 0.4)
		"fan_rel":
			if _timer <= 0.0:
				_end(0.8)
		"sky_wind":
			if _timer <= 0.0:
				# 하늘로 쏜 화살이 별자리가 된다
				for i in 4:
					StShot.fire(_bow_pos(), Vector2(randf_range(-0.15, 0.15), -1).normalized(), 30.0 * T, "arrow", {"radius": 2.0, "damage": 0, "life": 0.35, "hits_world": false})
				StArt.sfx(&"arrow_shot", &"sniper_shot", -2.0)
				_pose("bow_release")
				_make_constellation(p)
				set_state("sky_rain", 1.6)
		"sky_rain":
			if _timer <= 0.0:
				_end(0.9)


func _make_constellation(p: Player) -> void:
	_const_pts.clear()
	_const_t = 1.0
	var n := 7
	var span := 9.0 * T
	var cx := clampf(p.global_position.x, left_x + span, right_x - span)
	for i in n:
		var x := cx - span + span * 2.0 * float(i) / (n - 1) + randf_range(-10, 10)
		var y := floor_y - randf_range(11.0, 14.0) * T
		_const_pts.append(Vector2(x, y))
		var gy := _ground_at(x, floor_y - 2.0 * T)
		StStrike.spawn(Vector2(x, gy), "pillar", Vector2(18, gy - y), Difficulty.telegraph(1.0) + i * 0.08, {"damage": 1, "cause": "lyra", "hold": 0.14, "fade": 0.4, "sound": "arrow_hit"})


# ─── 4페이즈: 별창 (아우렐리아식) ───────────────────────

func _choose_p4(p: Player) -> void:
	if _attacks % 3 == 2:
		set_state("lance_rain_wind", Difficulty.telegraph(0.6))
		_pose("special")
		StArt.sfx(&"holy_charge", &"charger_windup", -4.0)
		return
	_seq = 0
	_charge_setup(p)


func _charge_setup(p: Player) -> void:
	# 높이: 1번째 바닥, 2번째 가운데, 3번째 바닥/높이 번갈아 (마지막 페이즈 25% 이하 연속 돌진)
	var heights := [0.0, 4.5 * T, 0.0] if hp > max_hp * 0.18 else [0.0, 4.5 * T, 8.5 * T]
	var side := -_side_of_player() if _seq == 0 else (1.0 if global_position.x < (left_x + right_x) * 0.5 else -1.0)
	var y := floor_y - float(heights[_seq % heights.size()])
	_blink(Vector2(_low(side).x, y))
	facing = -int(side)
	set_state("charge_wind", Difficulty.telegraph(0.9 if _seq == 0 else 0.7))
	_pose("spear_windup")
	StStrike.spawn(Vector2((left_x + right_x) * 0.5, y - 20.0), "band", Vector2(right_x - left_x + 3.0 * T, 2.4 * T), _timer, {"damage": 0, "hold": 0.0, "fade": 0.05})
	StArt.sfx(&"holy_charge", &"charger_windup", -2.0)


func _ai_p4(delta: float, p: Player) -> void:
	_seq_t += delta
	match state:
		"charge_wind":
			if _timer <= 0.0:
				set_state("charge", 1.2)
				_body_hit.active = true
				_body_hit.dodgeable = true
				_pose("spear_charge")
				StArt.sfx(&"holy_charge", &"charger_charge", 2.0)
				Fx.shake(0.25, 0.3)
		"charge":
			var step := 30.0 * T * delta
			global_position.x += facing * step
			_ghost_t -= delta
			if _ghost_t <= 0.0:
				_ghost_t = 0.04
				_ghost("spear_charge")
				Fx.burst(global_position + Vector2(-facing * 8, -20), 4, {direction = Vector2(-facing, 0), spread = 25.0, speed_min = 40.0, speed_max = 100.0,
					lifetime = 0.35, gradient = Palette.fade_gradient(StArt.STAR), add = true})
			if (facing > 0 and global_position.x >= right_x - T) or (facing < 0 and global_position.x <= left_x + T) or _timer <= 0.0:
				_body_hit.active = false
				Fx.shake(0.35, 0.25)
				StArt.sfx(&"holy_hit", &"slam", 0.0)
				_seq += 1
				var n := 3 if hp <= max_hp * 0.18 else 2
				if _seq < n:
					set_state("charge_gap", 0.25)
				else:
					_pose("spear")
					_end(1.1)
		"charge_gap":
			if _timer <= 0.0:
				_charge_setup(p)
		"lance_rain_wind":
			if _timer <= 0.0:
				var n := 6
				for i in n:
					var x := lerpf(left_x + 2.0 * T, right_x - 2.0 * T, float(i) / (n - 1)) + randf_range(-T, T)
					var gy := _ground_at(x, floor_y - 2.0 * T)
					StStrike.spawn(Vector2(x, gy), "pillar", Vector2(16, 13.0 * T), Difficulty.telegraph(0.95) + absf(i - 2.5) * 0.1, {"damage": 1, "cause": "lyra", "hold": 0.14, "fade": 0.4, "sound": "holy_hit", "shake": 0.08})
				# 세라 자리에 하나 더
				var px := p.global_position.x
				StStrike.spawn(Vector2(px, _ground_at(px, p.global_position.y - 8.0)), "pillar", Vector2(16, 13.0 * T), Difficulty.telegraph(1.25), {"damage": 1, "cause": "lyra", "hold": 0.14, "fade": 0.4})
				set_state("lance_rain", 1.6)
				_pose("spear")
		"lance_rain":
			if _timer <= 0.0:
				_end(0.9)


# ─── 마지막: 별의 비 ───────────────────────────────────

func _ai_finale(delta: float, p: Player) -> void:
	_seq_t += delta
	match state:
		"rain_wind":
			if _timer <= 0.0:
				set_state("rain", 5.4)
				_seq = 0
				_seq_t = 0.0
		"rain":
			# 세 번: 레인 10개 중 2~3칸만 비움
			if _seq < 3 and _seq_t > _seq * 1.6:
				var lanes := 10
				var lw := (right_x - left_x) / lanes
				var safe := randi_range(0, lanes - 3)
				var safe_w := 3 if _seq == 0 else 2
				for i in lanes:
					if i >= safe and i < safe + safe_w:
						continue
					var x := left_x + lw * (i + 0.5)
					var gy := _ground_at(x, floor_y - 2.0 * T)
					StStrike.spawn(Vector2(x, gy), "pillar", Vector2(lw * 0.85, 16.0 * T), Difficulty.telegraph(1.15), {"damage": 1, "cause": "lyra", "hold": 0.16, "fade": 0.45, "sound": "meteor_impact", "shake": 0.12})
				_seq += 1
				StArt.sfx(&"star_burst", &"pillar_warn", -2.0)
			if _timer <= 0.0:
				set_state("great_star", Difficulty.telegraph(1.6) + 0.6)
				var c := Vector2((left_x + right_x) * 0.5, floor_y - 1.0 * T)
				StStrike.spawn(c, "circle", Vector2((right_x - left_x) * 0.3, 0), Difficulty.telegraph(1.6), {"damage": 2, "cause": "lyra", "hold": 0.2, "fade": 0.6, "shake": 0.9, "sound": "meteor_impact"})
				if auto_lines:
					say_line("…!", 1.2)
		"great_star":
			if _timer <= 0.0:
				weak = true
				_glide(Vector2((left_x + right_x) * 0.5, floor_y), 1.2)
				_pose("idle")
				set_state("recover", 1.4)
		_:
			# 지친 상태의 공격 (느린 별)
			if state == "weak_orbs":
				if _seq < 3 and _seq_t > 0.6 + _seq * 0.4:
					var from := global_position + Vector2(facing * 10, -24)
					StShot.fire(from, (p.center() - from).normalized(), 7.0 * T, "star", {"radius": 4.0, "damage": 1, "cause": "lyra", "homing": 0.5, "life": 4.0})
					_seq += 1
				if _timer <= 0.0:
					_end(1.6)


func _choose_weak(_p: Player) -> void:
	_seq = 0
	set_state("weak_orbs", 2.0)
	_pose("cast")


# ─── 페이즈 전환 ────────────────────────────────────────

func _start_transition(n: int) -> void:
	_clear_aim()
	_blade.active = false
	_body_hit.active = false
	_orbs.clear()
	phase = n
	phase_changed.emit(n)
	_resume = false
	set_state("transition", 2.6)
	_glide(_center_high() if n < 5 else _center_high() + Vector2(0, -2.0 * T), 0.9)
	_pose("special")
	Fx.flash(Color(1.0, 0.95, 0.8, 0.35), 0.3)
	Fx.ring(global_position + Vector2(0, -22), 8.0, 10.0 * T, StArt.STAR, 0.6, 3.0)
	StArt.sfx(&"star_burst", &"explode", 0.0)
	if auto_lines and LINES.has(n):
		say_line(String(LINES[n]), 2.6)


func _ai_transition(_delta: float) -> void:
	var waiting := hold_transition and not _resume
	if _timer <= 0.0 and not waiting:
		_resume = false
		match phase:
			2: _pose("sword")
			3: _pose("bow")
			4: _pose("spear")
			5:
				set_state("rain_wind", Difficulty.telegraph(1.0))
				_pose("special")
				return
		# 무기를 빚어내는 별빛
		Fx.burst(global_position + Vector2(facing * 10, -22), 30, {spread = 180.0, speed_min = 80.0, speed_max = 20.0, lifetime = 0.5,
			gradient = Palette.fade_gradient(StArt.STAR), add = true})
		_cd = 0.6
		set_state("idle", 0.0)


# ─── 동료 지원 반응 (Ally.special이 부름) ───────────────

## 강한 일격에 흔들림: 지금 공격을 끊고 sec초 동안 숨을 고른다 (전환·별의 비·쓰러짐 중엔 무시)
func stagger(sec: float) -> void:
	if not engaged or state in ["dormant", "transition", "rain_wind", "rain", "great_star", "dead"]:
		return
	_clear_aim()
	_blade.active = false
	_body_hit.active = false
	_move_time = 0.0
	_cd = maxf(_cd, 0.3)
	set_state("recover", clampf(sec, 0.3, 2.5))
	_pose("hurt")
	say_line("…!", 1.0)
	Fx.burst(global_position + Vector2(0, -22), 12, {spread = 180.0, speed_min = 30.0, speed_max = 110.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(StArt.STAR), add = true})


# ─── 피격 ───────────────────────────────────────────────

func modify_damage(hit: Hit) -> float:
	if not engaged or state in ["transition", "rain_wind", "rain", "great_star", "dormant", "dead"]:
		return 0.0
	if state == "guard" and hit.kind in [&"bolt", &"bolt_heavy", &"fox_bolt", &"foxfire"]:
		_countered = true
		return 0.0
	if weak:
		return 1.5
	return 1.0


func take_hit(hit: Hit) -> void:
	if state == "dead":
		return
	var before := hp
	super.take_hit(hit)
	if hp <= 0 or state == "dead":
		return
	_check_phase(before)


## 페이즈 문턱은 한 방에 넘지 못한다 (전환 연출을 반드시 거침). 대본·시험이 체력을 직접 바꿔도 _ai에서 다시 확인
func _check_phase(before: int) -> void:
	if _pending_phase != 0:
		return
	var n := BossKit.phase_cross(self, phase, before, [P2_AT, P3_AT, P4_AT, FINALE_AT])
	if n == 0:
		return
	_pending_phase = n
	if state in ["idle", "recover"]:
		_start_transition(_pending_phase)
		_pending_phase = 0


func _on_blocked(hit: Hit) -> void:
	if state == "guard" or _countered:
		Fx.burst(global_position + Vector2(facing * 10, -22), 10, {direction = Vector2(facing, -0.3), spread = 50.0, speed_min = 60.0, speed_max = 150.0,
			lifetime = 0.25, gradient = Palette.fade_gradient(StArt.STAR), add = true})
		StArt.sfx(&"parry", &"block", 0.0)
	else:
		super._on_blocked(hit)


## 쓰러짐: 터지지 않는다. 별빛을 흘리며 내려와 무릎 꿇고, 그 자리에 남는다(대본이 진실 장면으로 이어 감)
func _die(_dir: int) -> void:
	if state == "dead":
		return
	if not weak:
		# 별의 비를 거치기 전에는 쓰러지지 않는다 (마지막 문턱에서 멈춤)
		hp = maxi(int(max_hp * FINALE_AT), 1)
		return
	state = "dead"
	hp = 0
	_clear_aim()
	_contact.active = false
	_blade.active = false
	_body_hit.active = false
	_alive = false
	_record_defeat("kills", false) # 등급 처치는 세지 않는다 (예전 동작 그대로)
	_disable_body(false) # 판정 셋은 위에서 직접 껐다
	Fx.hitstop(0.25)
	Fx.slowmo(0.35, 0.9)
	Fx.flash(Color(1.0, 0.96, 0.85, 0.6), 0.6)
	Fx.ring(global_position + Vector2(0, -22), 8.0, 14.0 * T, StArt.STAR, 0.9, 3.0)
	StArt.sfx(&"star_burst", &"explode", 2.0)
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", floor_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pose("kneel")
	_dim = 0.0
	defeated.emit(self)


func _ground_at(x: float, from_y: float) -> float:
	return floor_y_at(x, from_y, from_y + 20.0 * T, floor_y)


## 배경을 어둡게 하는 막 (일섬·별의 비) + 하늘의 별자리 + 1페이즈 준비된 별 + 말풍선
class Dimmer extends Node2D:
	var boss: Node
	var overlay := false ## true = 말풍선·준비된 별 (앞쪽), false = 어두운 막·별자리 (배경 바로 앞)

	func _ready() -> void:
		top_level = true
		z_as_relative = false
		z_index = 25 if overlay else -6

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if boss == null:
			return
		if overlay:
			_draw_overlay()
			return
		var d: float = boss.dim()
		if d > 0.01:
			draw_rect(Rect2(-200, -200, 4000, 1200), Color(0.0, 0.0, 0.04, d))
		var pts: Array[Vector2] = boss.constellation()
		var k: float = boss.constellation_k()
		if k > 0.01 and pts.size() > 1:
			StArt.constellation(self, pts, StArt.STAR, k, 2.0)
			for q in pts:
				StArt.sparkle(self, q, 4.0, StArt.STAR, k)

	func _draw_overlay() -> void:
		# 준비된 별 (1페이즈) — 보스 기준
		var o_list: Array[Vector2] = boss.orbs()
		var bp: Vector2 = boss.global_position
		var f := float(boss.facing)
		var t: float = boss._t
		for o in o_list:
			var q2 := bp + Vector2(o.x * f, o.y)
			draw_circle(q2, 6.0, Color(StArt.STAR, 0.15))
			StArt.star(self, q2, 4.0, StArt.STAR, t * 3.0)
		# 말풍선
		var text: String = boss.bubble()
		if text != "":
			var font := ThemeDB.fallback_font
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
			var p := bp + Vector2(-w * 0.5, -78)
			draw_rect(Rect2(p, Vector2(w, 18)), Color(0.04, 0.05, 0.15, 0.85))
			draw_rect(Rect2(p, Vector2(w, 1)), Color(StArt.STAR, 0.9))
			draw_colored_polygon(PackedVector2Array([bp + Vector2(-3, -60), bp + Vector2(3, -60), bp + Vector2(0, -55)]), Color(0.04, 0.05, 0.15, 0.85))
			draw_string(font, p + Vector2(6, 13), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.95, 0.8))
