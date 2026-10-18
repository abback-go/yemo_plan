class_name TStage
extends Node2D
## 턴제 전투 프로토타입 장면 (웹 주소 끝 ?turn). docs/eska-turn/combat_proto.md.
## 편성(TSetup) → 전투(TBattle 규칙 + TActor 그림 + THud 표시 + TFx 연출) → 승리(편성으로) / 패배(바로 다시).
## 전투는 코루틴 _run()이 돈다: 다음 차례 → 마녀면 바퀴에서 고르기를 기다림 / 적이면 의도대로 → 연출의 맞는 시각에 피해·숫자 → 다음.
## 배경·마녀·적은 모두 코드 그림. Esc 또는 오른쪽 위 X로 나간다.

const ArenaScript := preload("res://proto/p_arena.gd")
const WITCH_AT: Array[Vector2] = [Vector2(206, 300), Vector2(152, 270), Vector2(100, 240)] ## 앞 · 중 · 뒤 (대각선)
const ENEMY_AT: Array[Vector2] = [Vector2(436, 300), Vector2(500, 270), Vector2(566, 240)]

var battle: TBattle
var actors := {} ## TUnit → TActor
var hud: THud
var setup: TSetup
var cam: Camera2D
var units_node: Node2D
var _run_id := 0
var _in_battle := false
var _hud_layer: CanvasLayer
var _setup_layer: CanvasLayer
var stats := {"turns": 0, "biggest": 0} ## 시험용
var auto := false ## 시험용 자동 플레이: 바퀴를 잠깐 보여 준 뒤 간단한 규칙으로 고른다 (tools/test/scenarios/turn_*.json)


func _ready() -> void:
	EKeys.register()
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.reset()
	var bg := TBackdrop.new()
	add_child(bg)
	units_node = Node2D.new()
	units_node.name = "Units"
	units_node.z_index = 0
	add_child(units_node)
	var fx := Node2D.new()
	fx.name = "Effects"
	fx.z_index = 0
	add_child(fx)
	cam = ArenaScript.PCamera.new()
	cam.position_smoothing_enabled = false
	add_child(cam)
	cam.global_position = Vector2(320, 180)
	cam.reset_smoothing()
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 20
	add_child(_hud_layer)
	hud = THud.new()
	hud.stage = self
	_hud_layer.add_child(hud)
	hud.exit_tapped.connect(_on_hud_exit)
	hud.banner_tapped.connect(_on_banner)
	_setup_layer = CanvasLayer.new()
	_setup_layer.layer = 30
	add_child(_setup_layer)
	setup = TSetup.new()
	_setup_layer.add_child(setup)
	setup.start_pressed.connect(start_battle)
	setup.exit_pressed.connect(_exit)
	hud.visible = false
	Music.play("boss")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("es_exit") and _in_battle:
		_to_setup()


func _exit() -> void:
	Fx.reset()
	GameState.go_title()


func _on_hud_exit() -> void:
	_to_setup()


## 전투를 접고 편성으로
func _to_setup() -> void:
	_run_id += 1
	_in_battle = false
	Engine.time_scale = 1.0
	hud.visible = false
	hud.close_wheel()
	hud.clear_banner()
	for u in actors:
		(actors[u] as TActor).queue_free()
	actors.clear()
	for c in get_node("Effects").get_children():
		c.queue_free()
	setup.visible = true


func start_battle() -> void:
	TSetup.ensure_state()
	setup.visible = false
	hud.visible = true
	for u in actors:
		(actors[u] as TActor).queue_free()
	actors.clear()
	battle = TBattle.new()
	battle.setup(TData.BATTLE.party, TData.BATTLE.enemies, TSetup.state)
	for i in battle.witches.size():
		_add_actor(battle.witches[i], WITCH_AT[i])
	for i in battle.enemies.size():
		_add_actor(battle.enemies[i], ENEMY_AT[i])
	hud.bind(battle, actors)
	stats = {"turns": 0, "biggest": 0}
	_in_battle = true
	_run_id += 1
	_run(_run_id)


func _add_actor(u: TUnit, at: Vector2) -> void:
	var a := TActor.new()
	units_node.add_child(a)
	a.setup(u, at)
	a.z_index = 1 + int((at.y - 230.0) / 25.0) # 앞(아래)이 위에 그려짐 (1~4)
	actors[u] = a


func _wait(sec: float) -> void:
	if sec <= 0.0:
		return
	await get_tree().create_timer(sec).timeout


# ═══════════════════════════════════════════════════════════
# 전투 흐름
# ═══════════════════════════════════════════════════════════

func _run(token: int) -> void:
	await _wait(0.5)
	Sfx.play(&"tn_bless", -10.0)
	hud.show_msg("전투 시작")
	await _wait(0.6)
	while token == _run_id and is_inside_tree():
		var u := battle.next_actor()
		if u == null:
			return
		hud.refresh()
		var a: TActor = actors[u]
		if u.is_witch():
			hud.open_wheel(a)
			var action: Dictionary
			if auto:
				await _wait(0.5)
				if token != _run_id:
					return
				action = _auto_pick(a)
				hud.close_wheel()
			else:
				action = await hud.chosen
			if token != _run_id:
				return
			stats.turns = int(stats.turns) + 1
			await _perform_witch(a, action)
		else:
			await _wait(0.4)
			if token != _run_id:
				return
			await _perform_enemy(a)
		if token != _run_id:
			return
		var ev := battle.end_action(u)
		for e in ev:
			if e.t == "zeroed":
				hud.number((actors[e.tgt] as TActor).head(), "크레딧 0", "zero")
		hud.refresh()
		var oc := battle.outcome()
		if oc != "":
			await _finish(oc, token)
			return


func _targets_for(a: TActor, action: Dictionary) -> Array:
	var out: Array = []
	var tgt: TUnit = action.get("target")
	if action.kind == "basic":
		if tgt != null and actors.has(tgt):
			out.append(actors[tgt])
		return out
	var s := TData.skill(String(action.skill))
	match String(s.get("target", "enemy")):
		"enemy", "ally", "ally_any":
			if tgt != null and actors.has(tgt):
				out.append(actors[tgt])
		"enemies":
			for e in battle.alive_of(battle.enemies):
				out.append(actors[e])
		"allies":
			for w in battle.alive_of(battle.witches):
				out.append(actors[w])
		"self":
			out.append(a)
	return out


func _perform_witch(a: TActor, action: Dictionary) -> void:
	var u := a.unit
	var targets := _targets_for(a, action)
	var tgt: TUnit = action.get("target")
	var fx_id := ""
	var ev: Array = []
	var big := false
	if action.kind == "basic":
		fx_id = "basic_eska" if u.id == "eska" else "basic_fire"
		ev = battle.basic_attack(u, tgt)
		a.lunge()
		a.pose("cast")
	else:
		var s := TData.skill(String(action.skill))
		fx_id = String(s.fx)
		big = int(s.cost) >= 4
		ev = battle.use_skill(u, String(action.skill), tgt)
		if String(s.kind) == "attack":
			a.lunge()
		a.pose("cast_big" if big else "cast")
	hud.show_msg("%s — %s" % [u.name, battle.last_action])
	hud.refresh()
	var timing := TFx.play(fx_id, a, targets)
	await _show_events(ev, targets, timing, "space" if u.id == "eska" else "fire")
	a.pose("idle")
	hud.refresh()


func _perform_enemy(a: TActor) -> void:
	var u := a.unit
	var it := u.intent()
	var kind := String(it.get("k", "attack"))
	var ev := battle.enemy_action(u)
	hud.show_msg("%s — %s" % [u.name, battle.last_action])
	a.pose("buff" if kind == "buff" else "attack")
	if kind != "buff":
		a.lunge()
	var targets: Array = []
	for e in ev:
		if e.t == "hit" and actors.has(e.tgt):
			targets.append(actors[e.tgt])
	if targets.is_empty():
		targets.append(a)
	var fx_id := "enemy_" + kind
	var timing := TFx.play(fx_id, a, targets)
	await _show_events(ev, targets, timing, "enemy")
	await _wait(0.2)
	a.pose("idle")
	hud.refresh()


## 연출의 시각표에 맞춰 사건을 보여 준다: 맞는 순간마다 그 대상의 사건(피해·징표·디버프), 그 뒤 나머지(버프·크레딧 …)
func _show_events(ev: Array, targets: Array, timing: Dictionary, kind: String) -> void:
	var hits: Array = timing.get("hits", [0.2])
	var total := float(timing.get("total", 0.8))
	var shown := {}
	var t_prev := 0.0
	for i in hits.size():
		var ht := float(hits[i])
		await _wait(ht - t_prev)
		t_prev = ht
		var ta: TActor = targets[i] if i < targets.size() else (targets[0] if not targets.is_empty() else null)
		for j in ev.size():
			if shown.has(j):
				continue
			var e: Dictionary = ev[j]
			if ta != null and e.get("tgt") == ta.unit and e.t in ["hit", "mark", "debuff", "invincible"]:
				_show_event(e, kind)
				shown[j] = true
			elif e.t == "hit" and i == hits.size() - 1: # 시각표보다 사건이 많으면 마지막 때에 몰아서
				_show_event(e, kind)
				shown[j] = true
		if hits.size() == 1 or i == hits.size() - 1:
			for j in ev.size():
				if shown.has(j):
					continue
				_show_event(ev[j], kind)
				shown[j] = true
	await _wait(maxf(total - t_prev, 0.1))


func _show_event(e: Dictionary, kind: String) -> void:
	var tgt: TUnit = e.get("tgt")
	if tgt == null or not actors.has(tgt):
		return
	var ta: TActor = actors[tgt]
	match String(e.t):
		"hit":
			if bool(e.invincible):
				hud.number(ta.center(), "무적", "miss")
				var b := TFx.Barrier.new()
				TFx.add(b, ta.center(), false)
				Sfx.play(&"bl_unfold", -10.0)
				return
			var dmg := int(e.dmg)
			var heavy := dmg >= 100000 or bool(e.crit)
			stats.biggest = maxi(int(stats.biggest), dmg if tgt.is_witch() == false else 0)
			ta.hurt(heavy)
			var dir := -1.0 if tgt.is_witch() else 1.0
			TFx.impact(ta.center() + Vector2(randf_range(-4, 4), randf_range(-6, 2)), kind, heavy, dir)
			var nk := "dmg"
			var txt := TData.fmt(dmg)
			if tgt.is_witch():
				nk = "hurt"
				Fx.flash(Color(1.0, 0.2, 0.3, 0.18), 0.12)
				Sfx.play(&"hurt", -6.0)
			elif bool(e.crit):
				nk = "crit"
				txt += "!"
				Sfx.play(&"tn_crit", -4.0)
			elif bool(e.weak):
				nk = "weak"
			if bool(e.weak) and not bool(e.crit):
				txt = "약점 " + txt
			elif bool(e.weak):
				txt = "약점 " + txt
			hud.number(ta.center() + Vector2(0, -10), txt, nk)
			if dmg >= 300000:
				Fx.hitstop(0.1)
				Fx.shake(0.7, 0.3)
			elif heavy:
				Fx.hitstop(0.05)
				Fx.shake(0.4, 0.2)
			if bool(e.killed):
				var tw := create_tween()
				tw.tween_interval(0.25)
				tw.tween_callback(func() -> void:
					ta.set_down(true)
					hud.number(ta.center(), "쓰러짐", "miss")
					Sfx.play(&"bl_fold", -6.0))
		"buff":
			var cat := String(e.cat)
			var txt := ""
			if cat == "element":
				txt = "%s 속성 부여" % TData.ELEMENT_NAME.get(e.get("el", ""), "")
			elif cat == "dmg_taken":
				txt = "받는 피해 %d%%" % int(round(float(e.v) * 100.0))
			else:
				var nm: String = TData.CAT_NAME.get(cat, cat)
				if cat == "special":
					nm = "%s 특공" % TData.MARK_NAME.get(e.get("mark", ""), "")
				txt = "%s +%d%%" % [nm, int(round(float(e.v) * 100.0))]
			hud.number(ta.head() + Vector2(0, -4), txt, "buff")
		"debuff":
			hud.number(ta.head() + Vector2(0, -4), "%s %d%%" % [TData.CAT_NAME.get(e.cat, e.cat), int(round(float(e.v) * 100.0))], "debuff")
		"mark":
			hud.number(ta.center() + Vector2(0, 6), TData.MARK_NAME.get(e.kind, e.kind), "mark")
		"credits":
			if int(e.v) > 0:
				hud.number(ta.head() + Vector2(0, 6), "크레딧 +%d" % int(e.v), "credit")
		"gauge":
			if float(e.v) > 0.0:
				hud.number(ta.head() + Vector2(0, 6), "게이지 +%d%%" % int(round(float(e.v) * 100.0)), "buff")
		"heal":
			if int(e.v) > 0:
				hud.number(ta.center(), "+" + TData.fmt(int(e.v)), "heal")
		"revive":
			ta.set_down(false)
			hud.number(ta.center(), "되살아남", "revive")
		"invincible":
			hud.number(ta.head() + Vector2(0, -4), "무적", "buff")
		"enemy_buff":
			hud.number(ta.head() + Vector2(0, -4), "공격력 +%d%%" % int(round(float(e.v) * 100.0)), "buff")
		"demerit":
			hud.number(ta.head() + Vector2(0, 8), "다음 행동 뒤 크레딧 0", "zero")


func _finish(oc: String, token: int) -> void:
	await _wait(0.5)
	if token != _run_id:
		return
	_in_battle = false
	if oc == "win":
		for u in actors:
			if u.is_witch() and u.alive:
				(actors[u] as TActor).pose("win")
		Sfx.play(&"tn_victory", -2.0)
		hud.banner("승리", "눌러서 편성으로")
	else:
		Sfx.play(&"tn_defeat", -2.0)
		hud.banner("패배", "눌러서 다시 시작")


func _on_banner() -> void:
	if hud.banner_text == "승리":
		_to_setup()
	else:
		hud.clear_banner()
		start_battle()


func set_auto(v: bool) -> void:
	auto = v


## 시험용 자동 선택 (tools/test/turn_sim.gd의 default 전략과 같은 뼈대): 장착한 마법 안에서만 고른다
func _auto_pick(a: TActor) -> Dictionary:
	var u := a.unit
	var en := _auto_enemy()
	var ignis := _by_id("ignis")
	var eska := _by_id("eska")
	var dealer: TUnit = ignis if (ignis != null and ignis.alive) else eska
	match u.id:
		"ember":
			var low: TUnit = null
			for w in battle.alive_of(battle.witches):
				if w.hp_ratio() < 0.5:
					low = w
			if low != null and _can(u, "warmth"):
				return _act("warmth", null)
			if dealer != null and dealer.alive:
				if dealer.id == "eska" and not dealer.has_buff("element") and _can(u, "kindling"):
					return _act("kindling", dealer)
				if not dealer.has_buff("special") and _can(u, "bellows"):
					return _act("bellows", dealer)
				if not u.has_buff("atk") and _can(u, "blessing"):
					return _act("blessing", null)
				if dealer.credits <= 3 and _can(u, "share_ember"):
					return _act("share_ember", dealer)
				if dealer.credits >= 5 and not dealer.has_buff("atk") and _can(u, "god_descent"):
					return _act("god_descent", dealer)
			if u.credits >= 3 and _can(u, "flame_breath"):
				return _act("flame_breath", en)
		"ignis":
			if u.credits >= 7 and not u.has_buff("atk") and _can(u, "focus"):
				return _act("focus", u)
			if u.credits >= 5:
				for sid in ["sun_spear", "conflagration", "ash_storm", "blaze"]:
					if _can(u, sid):
						return _act(sid, en)
			if not en.marks.has("burn") and _can(u, "spark"):
				return _act("spark", en)
			if u.credits >= 3 and en.marks.has("burn") and _can(u, "pillar"):
				return _act("pillar", en)
		"eska":
			if dealer != null and dealer != u and dealer.alive and not dealer.has_buff("final") and _can(u, "void_gate"):
				return _act("void_gate", dealer)
			if u.credits >= 3 and _heavy_coming() and _can(u, "seal"):
				return _act("seal", null)
			if u.credits >= 5 and _can(u, "blackstar"):
				return _act("blackstar", en)
			if u.credits >= 4 and _can(u, "doom"):
				return _act("doom", en)
			if u.credits >= 2 and _can(u, "crack"):
				return _act("crack", en)
	return {"kind": "basic", "skill": "basic", "target": en}


func _act(sid: String, tgt: TUnit) -> Dictionary:
	return {"kind": "skill", "skill": sid, "target": tgt}


func _can(u: TUnit, sid: String) -> bool:
	return u.equipped.has(sid) and battle.can_use(u, sid)


func _by_id(wid: String) -> TUnit:
	for w in battle.witches:
		if w.id == wid:
			return w
	return null


func _auto_enemy() -> TUnit:
	var a := battle.alive_of(battle.enemies)
	for e in a:
		if e.element == "straw":
			return e
	var best: TUnit = a[0]
	for e in a:
		if e.hp < best.hp:
			best = e
	return best


func _heavy_coming() -> bool:
	for e in battle.alive_of(battle.enemies):
		var k := String(e.intent().get("k", ""))
		if k == "heavy" or k == "aoe":
			return true
	return false


## 시험용: 마법 연출 하나를 그냥 띄운다 (규칙은 건드리지 않음). 시전자는 마법 주인 마녀, 대상은 종류에 맞춰 고른다
func demo_fx(sid: String) -> String:
	var fx_id := sid
	var caster_id := "ignis"
	var target := "enemy"
	if TData.SKILLS.has(sid):
		var sk := TData.skill(sid)
		fx_id = String(sk.fx)
		target = String(sk.target)
		for wid in TData.WITCHES:
			if (TData.WITCHES[wid].skills as Array).has(sid):
				caster_id = wid
	elif sid.begins_with("enemy_"):
		caster_id = "straw_golem"
		target = "allies" if sid == "enemy_aoe" else ("self" if sid == "enemy_buff" else "ally")
	elif sid == "basic_eska":
		caster_id = "eska"
	var caster: TActor = null
	for u in actors:
		if u.id == caster_id:
			caster = actors[u]
	if caster == null:
		return "no caster"
	var targets: Array = []
	match target:
		"enemy":
			for e in battle.alive_of(battle.enemies):
				targets.append(actors[e])
				break
		"enemies":
			for e in battle.alive_of(battle.enemies):
				targets.append(actors[e])
		"ally", "ally_any":
			for w in battle.alive_of(battle.witches):
				if w.id == "eska":
					targets.append(actors[w])
		"allies":
			for w in battle.alive_of(battle.witches):
				targets.append(actors[w])
		"self":
			targets.append(caster)
	caster.pose("cast_big" if TData.cost_of(sid) >= 4 else "cast")
	var timing := TFx.play(fx_id, caster, targets)
	var tw := create_tween()
	tw.tween_interval(float(timing.total))
	tw.tween_callback(func() -> void: caster.pose("idle"))
	hud.show_msg("%s — %s" % [caster.unit.name, TData.skill(sid).get("name", sid)])
	return "%s %s hits=%s total=%.2f" % [fx_id, caster_id, str(timing.hits), float(timing.total)]


## 시험용: 지금 상태 한 줄
func status() -> String:
	if battle == null:
		return "no battle"
	var s := "turn=%d actor=%s outcome=%s" % [battle.turn_no, battle.actor.name if battle.actor else "-", battle.outcome()]
	for u in battle.all_units():
		s += " | %s hp=%d g=%d c=%d%s" % [u.name, u.hp, int(u.gauge), u.credits, "" if u.alive else " X"]
	return s
