class_name PlayerCaster
extends RefCounted
## 세라 시전 — 화염탄(묵직한 한 발), 마법 7종(docs/magic.md)의 장착 칸 시전, 물약, 여우창문, 재사용 대기.
## 여우 모드면 화염탄 → 여우불, 불기둥 → 여우비, 화염 폭풍 → 구미호 폭풍.
## 새 마법을 더하는 절차는 docs/dev/player.md "새 마법/능력 추가".

var p: Player

## 마법 재사용 대기 남은 시간 (id → 초). HUD·터치 버튼은 Player.spell_cooldown()으로 읽는다.
var cooldowns := {"pillar": 0.0, "storm": 0.0, "ward": 0.0, "meteor": 0.0, "phoenix": 0.0}
var cast_pose := 0.0 ## 시전 자세 남은 시간 (PlayerVisual.cast)
var cast_kind := 0 ## 0 화염탄, 1 불기둥(손이 아래로), 2 두 팔 앞으로
var storm_timer := 0.0 ## 화염 폭풍 시전 중 (이동 느려짐, 방향 고정, 화염탄 막힘)
var potion_timer := 0.0 ## 물약 마시는 중
var ult_float := 0.0 ## 고급 마법 시전 중 떠 있는 시간 (무적, 조작 잠김)
var _attack_cooldown := 0.0
var _attack_buffer := 0.0
var _window_cooldown := 0.0


func _init(owner: Player) -> void:
	p = owner


func tick(delta: float) -> void:
	_attack_cooldown -= delta
	_attack_buffer -= delta
	cast_pose -= delta
	storm_timer -= delta
	_window_cooldown -= delta
	if potion_timer > 0.0:
		potion_timer -= delta
		if potion_timer <= 0.0:
			_finish_potion()
	for k in cooldowns:
		cooldowns[k] = maxf(float(cooldowns[k]) - delta, 0.0)
	p._ward_time = maxf(p._ward_time - delta, 0.0)
	if ult_float > 0.0:
		ult_float -= delta


## 마법 재사용 대기 [남은 시간, 전체] (여우 모드 배수 반영)
func spell_cooldown(id: String) -> Vector2:
	if not cooldowns.has(id):
		return Vector2.ZERO
	return Vector2(float(cooldowns[id]), _full_cooldown(id))


## 재사용 대기 전체 길이: 레벨 반영(Spells) × 여우 모드 배수(불기둥·화염 폭풍만)
func _full_cooldown(id: String) -> float:
	var cd := Spells.cooldown_for(id, p.tuning)
	match id:
		"pillar":
			return cd * (p.tuning.fox_pillar_cd_mult if p.is_fox() else 1.0)
		"storm":
			return cd * (p.tuning.fox_storm_cd_mult if p.is_fox() else 1.0)
	return cd


func is_ready(id: String) -> bool:
	return float(cooldowns[id]) <= 0.0


# ─── 화염탄 (묵직한 한 발) ──────────────────────────────

## 공격 입력을 잠깐 기억 (쿨다운이 끝나자마자 나가게)
func buffer_attack() -> void:
	_attack_buffer = p.tuning.attack_buffer_time


## 버퍼가 있거나 누르고 있으면, 쿨다운이 끝났고 화염 폭풍 중이 아닐 때 한 발
func try_fire(held: bool) -> void:
	var wants_attack := _attack_buffer > 0.0 or held
	if wants_attack and _attack_cooldown <= 0.0 and storm_timer <= 0.0:
		_fire_bolt()


## v0.4: 약 1.2초마다 커다란 한 발 (누르고 있으면 그 간격으로 계속). 여우 모드면 유도·관통 여우불
func _fire_bolt() -> void:
	var tu := p.tuning
	var facing := p.facing
	var hand := p.to_global(Vector2(Player.HAND.x * facing, Player.HAND.y))
	if p.is_fox():
		FoxfireBolt.fire(hand, facing, tu)
	else:
		var bolt := FireBolt.new()
		bolt.setup(facing, tu, p.is_overheated())
		bolt.global_position = hand
		Fx.effect_parent().add_child(bolt)
		Sfx.play(&"shoot_heavy", 0.0)

	_attack_cooldown = tu.shot_interval
	_attack_buffer = 0.0
	_pose(0.22, 0)
	GameState.add("bolts_fired")
	var col := FoxPalette.GLOW if p.is_fox() else Palette.FIRE_HOT
	Fx.burst(hand, 14, {
		direction = Vector2(facing, 0), spread = 40.0, speed_min = 80.0, speed_max = 220.0,
		lifetime = 0.2, size_min = 1.5, size_max = 3.0, gravity = Vector2.ZERO,
		gradient = Palette.fade_gradient(col), add = true,
	})
	Fx.ring(hand, 2.0, 14.0, col, 0.15, 2.0)
	Fx.shake(tu.shake_light_t)
	# 공중 사격: 낙하를 잠깐 멈춰 떠 있게 한다 (착지 전까지 정해진 횟수)
	var m := p.motor
	if not p.is_on_floor() and p.state != Player.State.DASH and m.air_hovers_left > 0 and p.velocity.y > -20.0:
		p.velocity.y = minf(p.velocity.y, tu.air_shot_hover_speed_t * GameConst.TILE)
		m.air_hovers_left -= 1
	if p.state != Player.State.DASH:
		# 반동: 뒤로 밀림 (공중에서는 절반)
		var k := 1.0 if p.is_on_floor() else 0.5
		p.velocity.x = -facing * 2.0 * tu.heavy_recoil_t * GameConst.TILE / 0.1 * k
		p._squash_to(Vector2(1.12, 0.9))


func _pose(time: float, kind: int) -> void:
	cast_pose = time
	cast_kind = kind


# ─── 장착 칸 시전 (마법 7종 — docs/magic.md) ────────────

## 장착 칸(a·s·f)의 마법을 쓴다. 여우 모드면 불기둥 → 여우비, 화염 폭풍 → 구미호 폭풍
func cast_slot(slot: String) -> void:
	var id := Spells.equipped(slot)
	if id == "" and slot == "s" and p.is_fox():
		id = "storm" # 1장 해태전: 화염 폭풍을 배우기 전에도 여우 모드 S는 구미호 폭풍
	if id == "":
		if slot == "s" and not GameState.has_ability("storm") and not GameState.has_ability("ward"):
			Story.toast(PlayerText.NOT_LEARNED)
		elif slot == "f" and (GameState.has_ability("meteor") or GameState.has_ability("phoenix")):
			Story.toast(PlayerText.EQUIP_ULT_HINT)
		return
	match id:
		"pillar":
			if is_ready("pillar") and storm_timer <= 0.0:
				_cast_skill_1()
		"storm":
			if is_ready("storm"):
				if p.state == Player.State.DASH:
					p.motor.end_dash()
				_cast_skill_2()
		"ward":
			if is_ready("ward"):
				cast_ward()
		"meteor", "phoenix":
			if is_ready(id) and ult_float <= 0.0:
				if id == "meteor":
					_cast_meteor()
				else:
					cast_phoenix()
			elif not is_ready(id):
				Sfx.play(&"block", -10.0, 0.0)


## 레벨을 반영한 수치 사본 (불기둥·화염 폭풍)
func _scaled(id: String) -> Tuning:
	var tu := p.tuning
	var t := tu.duplicate() as Tuning
	var m := Spells.dmg_mult(id)
	match id:
		"pillar":
			t.pillar_damage = int(round(tu.pillar_damage * m))
			t.pillar_side_damage = int(round(tu.pillar_side_damage * m))
			if Spells.level(id) >= 3:
				t.pillar_side_count = tu.pillar_side_count + tu.pillar_lv3_extra_sides
		"storm":
			t.storm_tick_damage = int(round(tu.storm_tick_damage * m))
			t.storm_final_damage = int(round(tu.storm_final_damage * m))
	return t


func cast_ward() -> void:
	var w := FlameWard.new()
	w.setup(p, p.tuning, Spells.level("ward"), p.is_fox())
	p.add_child(w)
	p._ward_time = w.duration
	cooldowns.ward = Spells.cooldown_for("ward", p.tuning)
	_pose(0.35, 2)
	Sfx.play(&"ward", -2.0, 0.05)
	GameState.add("ward")
	p.gauge.add(p.tuning.ward_overload)


func _cast_meteor() -> void:
	var m := MeteorFall.new()
	m.setup(p, p.tuning, Spells.level("meteor"), p.is_fox())
	Fx.effect_parent().add_child(m)
	cooldowns.meteor = Spells.cooldown_for("meteor", p.tuning)
	ult_float = MeteorFall.CAST
	_pose(MeteorFall.CAST, 2)
	cancel_storm()
	if p.state == Player.State.DASH:
		p.motor.end_dash()
	p.velocity = Vector2(0, -90)
	# 모든 마력을 하늘에: 폭주 게이지가 비워짐
	if not p.is_fox():
		p.gauge.clear()
	GameState.add("meteor")


## revive = 불사조 Lv3 부활의 불꽃 (회복·게이지 감소 없음)
func cast_phoenix(revive := false) -> void:
	var tu := p.tuning
	var ph := PhoenixCall.new()
	ph.setup(p, tu, Spells.level("phoenix"), p.is_fox(), revive)
	Fx.effect_parent().add_child(ph)
	cooldowns.phoenix = Spells.cooldown_for("phoenix", tu)
	ult_float = 0.45
	_pose(0.45, 2)
	if not revive:
		p.heal(tu.phoenix_heal_lv2 if Spells.level("phoenix") >= 2 else tu.phoenix_heal)
	if not p.is_fox():
		p.overload = maxf(p.overload - tu.phoenix_overload_drain, 0.0)
	GameState.add("phoenix")


## A칸 불기둥 (여우 모드: 여우비)
func _cast_skill_1() -> void:
	if p.is_fox():
		var r := FoxRain.new()
		r.setup(p, _scaled("pillar"))
		Fx.effect_parent().add_child(r)
		cooldowns.pillar = _full_cooldown("pillar")
		_pose(0.4, 1)
		GameState.add("pillar")
	else:
		_cast_pillar()


## S칸 화염 폭풍 (여우 모드: 구미호 폭풍)
func _cast_skill_2() -> void:
	if p.is_fox():
		var st := NineTailStorm.new()
		st.setup(p, _scaled("storm"))
		p.add_child(st)
		storm_timer = 0.5
		cooldowns.storm = _full_cooldown("storm")
		_pose(0.6, 2)
		if not p.is_on_floor():
			p.velocity.y = minf(p.velocity.y, 0.0)
		GameState.add("storm")
	else:
		_cast_storm()


func _cast_pillar() -> void:
	var tu := p.tuning
	var target := _find_pillar_target()
	var pos: Vector2
	if target:
		pos = target.global_position
	else:
		pos = ground_point(p.global_position.x + p.facing * tu.pillar_fallback_t * GameConst.TILE)
	var fp := FirePillar.new()
	fp.setup(pos, target, _scaled("pillar"), p.facing)
	Fx.effect_parent().add_child(fp)
	cooldowns.pillar = Spells.cooldown_for("pillar", tu)
	_pose(0.3, 1)
	GameState.add("pillar")
	p.gauge.add(tu.pillar_overload)


## 바라보는 방향 사거리 안, 땅에 서 있는 가장 가까운 적 (없으면 화로 등 불기둥 표적)
func _find_pillar_target() -> Node2D:
	var range_px := p.tuning.pillar_range_t * GameConst.TILE
	var origin := p.global_position
	var facing := p.facing
	# 앞쪽(뒤로 반 칸까지) 사거리·위아래 7칸 안이면 거리, 아니면 INF
	var reach := func(e) -> float:
		var dx: float = (e.global_position.x - origin.x) * facing
		var dy: float = absf(e.global_position.y - origin.y)
		if dx < -8.0 or dx > range_px or dy > 7.0 * GameConst.TILE:
			return INF
		return Vector2(dx, dy).length()
	var on_ground := func(e) -> float:
		return reach.call(e) if e.is_on_floor() else INF
	var best := EnemyQuery.nearest(p.get_tree(), on_ground)
	if best == null:
		best = EnemyQuery.nearest(p.get_tree(), reach, INF, &"pillar_target")
	return best


## x 위치의 땅(아래로 광선) — 없으면 세라 높이
func ground_point(x: float) -> Vector2:
	var space := p.get_world_2d().direct_space_state
	var from := Vector2(x, p.global_position.y - 2.0 * GameConst.TILE)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 12.0 * GameConst.TILE), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	if r:
		return r.position
	return Vector2(x, p.global_position.y)


func _cast_storm() -> void:
	var tu := p.tuning
	var facing := p.facing
	var s := FireStorm.new()
	s.setup(facing, _scaled("storm"))
	s.position = Vector2(facing * 6, -15)
	p.add_child(s)
	storm_timer = tu.storm_duration
	cooldowns.storm = Spells.cooldown_for("storm", tu)
	if Spells.level("storm") >= 3:
		# Lv3: 지나간 자리에 불바다
		var g := ground_point(p.global_position.x + facing * tu.storm_lv3_burn_offset_t * GameConst.TILE)
		BurnGround.spawn(g, tu.storm_lv3_burn_width_t * GameConst.TILE, tu.storm_lv3_burn_dps * Spells.dmg_mult("storm"), tu.storm_lv3_burn_time, &"storm")
	_pose(tu.storm_duration + 0.1, 2)
	# 시전 반동: 뒤로 밀려나며 내뿜는다
	p.velocity.x = -facing * 2.0 * tu.storm_recoil_t * GameConst.TILE / 0.2
	if not p.is_on_floor():
		p.velocity.y = minf(p.velocity.y, 0.0)
	GameState.add("storm")
	p.gauge.add(tu.storm_overload)


func cancel_storm() -> void:
	storm_timer = 0.0
	for c in p.get_children():
		if c is FireStorm:
			c.queue_free()


# ─── 물약·여우창문 ──────────────────────────────────────

func drink_potion() -> void:
	if potion_timer > 0.0 or GameState.potions <= 0:
		if GameState.potions_max > 0 and GameState.potions <= 0:
			Story.toast(PlayerText.NO_POTION)
		return
	if p.hp >= p.max_hp():
		Story.toast(PlayerText.HP_FULL)
		return
	potion_timer = p.tuning.potion_time
	p._body.drinking = true
	Sfx.play(&"potion", -2.0)


## 마시기를 멈춤 (컷신·사망)
func stop_potion() -> void:
	potion_timer = 0.0
	p._body.drinking = false


func _finish_potion() -> void:
	p._body.drinking = false
	if p.state == Player.State.DEAD or GameState.potions <= 0:
		return
	GameState.potions -= 1
	p.health.set_hp(mini(p.hp + p.tuning.potion_heal, p.max_hp()))
	var c := p.center()
	Fx.burst(c, 18, {spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(Color(1.0, 0.5, 0.6)), gravity = Vector2(0, -60), add = true})
	Fx.ring(c, 4.0, 22.0, Color(1.0, 0.6, 0.7), 0.3, 1.0)
	if GameState.has_flag("pippa_potion"):
		var lines := PlayerText.PIPPA_POTION
		Story.toast(lines[randi() % lines.size()], 1.8)


func open_window() -> void:
	if not GameState.has_ability("fox_window") or _window_cooldown > 0.0:
		return
	if p.get_tree().get_first_node_in_group(&"fox_window"):
		return
	var w := FoxWindow.new()
	w.setup(p)
	Fx.effect_parent().add_child(w)
	_window_cooldown = FoxWindow.DURATION + 2.0
	_pose(0.5, 2)
	Sfx.play(&"window", -2.0, 0.0)
