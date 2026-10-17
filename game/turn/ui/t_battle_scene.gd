class_name TBattleScene
extends Node2D
## 전투 장면 — 코어(TBattle)의 사건을 차례로 연출하고, 아군 차례엔 판(THud)의 탭을 받아 결정한다.
## 흐름: start() → 소개 띠 → { advance → 사건 연출 → 아군이면 결정을 기다림(또는 자동) / 적이면 auto } → 끝 띠 → finished.
## 사이드뷰: 아군 왼쪽(오른쪽을 봄) · 적 오른쪽(왼쪽을 봄). 배경은 실시간판의 마녀 마당(EScenery 층)을 가져와 씀.

signal finished(won: bool, summary: Dictionary)
signal chosen

enum Phase { INTRO, WAITING, PLAYING, OVER }

var run: TRun
var battle: TBattle
var battle_index := 0
var world: Node2D
var hud: THud
var ui_layer: CanvasLayer
var actors := {} ## 유닛 id → TActor
var phase := Phase.INTRO
var active: TBattle.Unit
var sel_spell := ""
var sel_potion := ""
var potion_menu := false
var cand: Array[TBattle.Unit] = []
var cand_i := 0
var auto := false
var fast := false
var policy: TPolicy
var _decision := {}
var _shake := 0.0
var _t := 0.0
var _last_ally_target := {} ## 시전자 id → 마지막으로 고른 아군 id
var _ended := false


func setup(p_run: TRun, index: int, p_ui_layer: CanvasLayer) -> void:
	run = p_run
	battle_index = index
	ui_layer = p_ui_layer
	battle = TBattle.new()
	battle.setup(run, TData.BATTLES[index])
	policy = TPolicy.new(run.dealer)
	auto = run.auto
	world = Node2D.new()
	add_child(world)
	_build_background()
	_build_actors()
	hud = THud.new()
	hud.scene = self
	ui_layer.add_child(hud)


func _exit_tree() -> void:
	if is_instance_valid(hud):
		hud.queue_free()


func _build_background() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	sky_layer.add_child(EScenery.SkyBack.new())
	var fy := TUi.GROUND_Y + 10.0
	for spec: Array in [[EScenery.FAR, 0.55, 1, -8], [EScenery.MID, 0.8, 2, -7]]:
		var sp := EScenery.Spires.new()
		sp.col = spec[0]
		sp.scale_k = float(spec[1])
		sp.seed_n = int(spec[2])
		sp.width = 640.0
		sp.floor_y = fy
		sp.z_index = int(spec[3])
		world.add_child(sp)
	var shafts := EScenery.Shafts.new()
	shafts.floor_y = fy
	shafts.width = 640.0
	shafts.material = Fx.add_material
	shafts.z_index = -6
	world.add_child(shafts)
	var mist := EScenery.Mist.new()
	mist.width = 640.0
	mist.floor_y = fy
	mist.z_index = -5
	world.add_child(mist)
	var ground := EScenery.Ground.new()
	ground.width = 640.0
	ground.floor_y = fy
	ground.z_index = -2
	world.add_child(ground)
	var candles := EScenery.Candles.new()
	candles.floor_y = fy
	candles.z_index = -1
	world.add_child(candles)
	var motes := EScenery.Motes.new()
	motes.width = 640.0
	motes.floor_y = fy
	motes.z_index = 9
	motes.material = Fx.add_material
	world.add_child(motes)


func _build_actors() -> void:
	var es := battle.enemies(false)
	var poss: Array = TUi.ENEMY_POS.get(es.size(), TUi.ENEMY_POS[3])
	for u in battle.units:
		var a := TActor.new()
		a.setup(u, battle)
		if u.ally:
			a.position = TUi.ALLY_POS[u.slot]
		else:
			a.position = poss[mini(u.slot, poss.size() - 1)]
		a.z_index = 1 + int(a.position.y / 12.0) - 18
		world.add_child(a)
		actors[u.id] = a


func start() -> void:
	Music.play(String(TData.BATTLES[battle_index].get("music", "basement")), 1.2)
	_loop()


func _process(delta: float) -> void:
	_t += delta
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 18.0, 0.0)
		world.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	else:
		world.position = Vector2.ZERO


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func waiting() -> bool:
	return phase == Phase.WAITING and active != null


func actor_of(id: String) -> TActor:
	return actors.get(id)


# ═══════════════════════════════════════════════════════════
# 큰 흐름
# ═══════════════════════════════════════════════════════════

func _wait(sec: float) -> bool:
	if sec <= 0.0:
		return is_inside_tree()
	await get_tree().create_timer(sec * (0.45 if fast else 1.0)).timeout
	return is_inside_tree()


func _loop() -> void:
	phase = Phase.INTRO
	var b: Dictionary = TData.BATTLES[battle_index]
	hud.show_banner(String(b.name), TUi.PALE, 1.8)
	if not await _wait(1.1):
		return
	hud.show_tip(String(b.get("intro", "")), 6.0)
	if battle_index == 0 and not auto:
		hud.show_tip("마법을 누르고 대상을 누르세요. 버프는 겹쳐요(2겹). 대마법은 게이지가 차면.", 7.0)
	while not battle.over:
		var u := battle.advance()
		if not await _play(battle.take_events()):
			return
		if battle.over or u == null:
			break
		if u.ally:
			active = u
			if auto:
				phase = Phase.PLAYING
				if not await _wait(0.3):
					return
				var p := policy.potion(battle, u)
				if not p.is_empty():
					battle.use_potion(u, String(p.potion), String(p.get("target", "")))
					if not await _play(battle.take_events()):
						return
				if not battle.over:
					_apply_decision(u, policy.choose(battle, u))
			else:
				var done := false
				while not done:
					phase = Phase.WAITING
					_decision = {}
					await chosen
					if not is_inside_tree():
						return
					phase = Phase.PLAYING
					if _decision.has("potion"):
						battle.use_potion(u, String(_decision.potion), String(_decision.get("target", "")))
						if not await _play(battle.take_events()):
							return
						done = battle.over or not u.alive
					else:
						_apply_decision(u, _decision)
						done = true
			if not await _play(battle.take_events()):
				return
			active = null
			_clear_rings()
		else:
			phase = Phase.PLAYING
			active = null
			var a := actor_of(u.id)
			if a:
				a.active = true
			if not await _wait(0.35):
				return
			battle.auto(u)
			if a:
				a.active = false
			if not await _play(battle.take_events()):
				return
	_finish()


func _apply_decision(u: TBattle.Unit, d: Dictionary) -> void:
	if d.has("wait") or d.is_empty():
		battle.wait_turn(u)
	elif not battle.act(u, String(d.spell), String(d.get("target", ""))):
		battle.wait_turn(u)


func _finish() -> void:
	if _ended:
		return
	_ended = true
	phase = Phase.OVER
	active = null
	_clear_rings()
	if battle.won:
		hud.show_banner("승리!", TUi.GOLD, 2.5)
		Sfx.play(&"clear", -2.0, 0.0)
	else:
		hud.show_banner("쓰러졌다…", TUi.RED, 2.5)
		Music.stop(1.0)
	if not await _wait(1.6):
		return
	finished.emit(battle.won, battle.summary())


# ═══════════════════════════════════════════════════════════
# 사건 연출
# ═══════════════════════════════════════════════════════════

func _play(events: Array[Dictionary]) -> bool:
	for ev in events:
		if not is_inside_tree():
			return false
		var ok := true
		match String(ev.type):
			"turn":
				var a := actor_of(String(ev.unit))
				if a and not a.unit.ally:
					ok = await _wait(0.1)
			"cast_start":
				var a := actor_of(String(ev.unit))
				if a:
					a.pose("cast", 0.5)
					TFx.label(a.head() + Vector2(0, -8), "시전 " + String(ev.name), TUi.CAST_C if a.unit.ally else TUi.RED, 12, 1.1)
					Sfx.play(&"es_sigil" if a.unit.ally else &"charger_windup", -8.0)
				ok = await _wait(0.55)
			"cast_fire":
				var a := actor_of(String(ev.unit))
				if a and a.unit.ally:
					hud.show_banner(String(ev.name), TUi.ULT_C, 1.6)
					a.pose("ult", 1.4)
					ok = await _wait(0.5)
			"act":
				ok = await _play_act(ev)
			"hit":
				ok = await _play_hit(ev)
			"heal":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.number(a.center() + Vector2(0, -12), int(ev.amount), TUi.GREEN)
					Sfx.play(&"pickup", -6.0)
				ok = await _wait(0.3)
			"buff":
				var a := actor_of(String(ev.unit))
				if a:
					var kind := String(ev.kind)
					var amt := float(ev.amt)
					var s := TData.kind_name(kind)
					if kind == "shield":
						s += " " + str(int(amt))
					elif kind == "haste":
						s += " +" + TUi.pct(amt)
					else:
						s += (" +" if amt >= 0.0 else " ") + TUi.pct(amt)
					if int(ev.stacks) > 1:
						s += " ×" + str(int(ev.stacks))
					var bad := (kind == "vuln") or (kind == "def" and amt < 0.0)
					var col: Color = TUi.BUFF_COLORS.get(kind, TUi.TEXT)
					TFx.label(a.head() + Vector2(0, -4), s, col if not bad else TUi.RED.lerp(col, 0.4), 11, 1.0)
					if a.unit.ally and not bad:
						a.pose("idle", 0.0)
				ok = await _wait(0.22)
			"interrupt":
				var a := actor_of(String(ev.unit))
				if a:
					a.pose("hurt", 0.5)
					TFx.label(a.head() + Vector2(0, -14), "끊김!", TUi.GOLD if not a.unit.ally else TUi.RED, 16, 1.2)
					EVfx.shards(a.center(), 8, 160.0, Vector2(6, 6), 70.0)
					Sfx.play(&"es_deflect", -3.0)
					shake(3.0)
				ok = await _wait(0.45)
			"resist_interrupt":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -14), "굳센 시전 — 봉공·물약만 끊음", TUi.RED, 11, 1.4)
				ok = await _wait(0.3)
			"push":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -26), "차례 +%.1f칸" % float(ev.amount), TUi.PALE, 11, 1.0)
			"pull":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -26), "차례 −%.1f칸" % float(ev.amount), TUi.FIRE_HOT, 11, 1.0)
			"die":
				var a := actor_of(String(ev.unit))
				if a:
					a.pose("die", 2.0)
					a.ring = 0
					if a.unit.ally:
						Sfx.play(&"hurt", -4.0)
						TFx.label(a.head(), "쓰러짐", TUi.RED, 13, 1.4)
					else:
						EVfx.dark_burst(a.center(), 28.0 * a.unit.size)
						Sfx.play(&"enemy_die", -4.0)
				ok = await _wait(0.55)
			"break":
				var a := actor_of(String(ev.unit))
				hud.show_banner("갑옷이 깨진다! — " + String(ev.label), TUi.FIRE_HOT, 2.4)
				if a:
					EVfx.shards(a.center(), 20, 260.0, Vector2(16, 20), 120.0)
					PVfx.embers(a.center(), 24, false, 160.0, Vector2(16, 24))
					a.pose("hurt", 0.8)
				Fx.flash(Color(TUi.FIRE_HOT, 0.5), 0.2)
				shake(8.0)
				Sfx.play(&"kb_break", -2.0, 0.0)
				if String(ev.weak) == TData.ELEM_FIRE:
					hud.show_tip("불씨가 드러났다 — 이제 화염에 약하다(×1.5). 공간은 그대로 ×1.2.", 5.0)
				ok = await _wait(1.3)
			"burn":
				var a := actor_of(String(ev.unit))
				if a and int(ev.dmg) > 0:
					TFx.number(a.center() + Vector2(0, -10), int(ev.dmg), TUi.FIRE_OUT, ["화상"])
					PVfx.embers(a.center(), 6, false, 80.0, Vector2(8, 10))
				ok = await _wait(0.25)
			"burn_set":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -4), "화상 (" + str(int(ev.dmg)) + " ×3)", TUi.FIRE_OUT, 10, 1.0)
			"gauge_full":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -16), "대마법 준비!", TUi.ULT_C, 13, 1.3)
					Sfx.play(&"star_burst", -5.0)
			"potion":
				var a := actor_of(String(ev.unit))
				if a:
					var sp: Dictionary = TData.POTIONS[String(ev.potion)]
					var targets: Array = []
					var tt := String(sp.get("target", ""))
					if tt == "enemies":
						for e in battle.enemies():
							var ea := actor_of(e.id)
							if ea:
								targets.append(ea.info())
					else:
						var ta := actor_of(String(ev.target))
						if ta:
							targets.append(ta.info())
					a.pose("support", 0.5)
					var lead := TFx.potion(String(ev.potion), sp, a.hand(), targets)
					TFx.label(a.head() + Vector2(0, -8), "물약 · " + String(ev.name), Color(String(sp.color)), 11, 1.0)
					ok = await _wait(lead)
			"wait":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -6), "기다림 (+게이지)", TUi.DIM, 11, 0.9)
				ok = await _wait(0.25)
			"shield":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.center() + Vector2(0, -24), "방벽 −" + str(int(ev.absorbed)), TUi.SHIELD_C, 11, 0.9)
			"end":
				pass
		if not ok:
			return false
	return true


func _play_act(ev: Dictionary) -> bool:
	var a := actor_of(String(ev.unit))
	if a == null:
		return true
	var spec := battle.spec_of(a.unit, String(ev.spell))
	var targets: Array = []
	for tid in ev.targets:
		var ta := actor_of(String(tid))
		if ta:
			targets.append(ta.info())
	var kind := String(ev.kind)
	if a.unit.ally:
		if kind == "attack":
			a.pose("attack", 0.5)
		elif kind == "ult":
			a.pose("ult", 1.2)
		else:
			a.pose("support", 0.5)
		if not bool(ev.from_cast):
			TFx.label(a.head() + Vector2(0, -8), String(ev.name), TUi.kind_color(kind), 12, 1.0)
	else:
		if kind == "attack":
			a.pose("attack", 0.6)
		else:
			a.pose("cast", 0.6)
		TFx.label(a.head() + Vector2(0, -8), String(ev.name), TUi.ENEMY_C, 12, 1.0)
	if a.unit.boss and kind == "attack":
		shake(2.0)
	var lead := TFx.cast(String(ev.spell), spec, a.hand(), a.info(), targets, a.unit.ally)
	return await _wait(lead)


func _play_hit(ev: Dictionary) -> bool:
	var tgt := actor_of(String(ev.target))
	var src := actor_of(String(ev.unit))
	if tgt == null:
		return true
	var dmg := int(ev.dmg)
	var spec := battle.spec_of(src.unit, String(ev.spell)) if src else {}
	var elem := String(spec.get("elem", ""))
	var crit := bool(ev.crit)
	var heavy := dmg >= 260 or crit
	TFx.impact(elem, tgt.center(), heavy, tgt.unit.ally)
	tgt.pose("hurt", 0.35)
	var tags: Array[String] = []
	if crit:
		tags.append("치명!")
	if bool(ev.weak):
		tags.append("약점 ×1.5")
	if bool(ev.space):
		tags.append("무상성 ×1.2")
	if bool(ev.resist):
		tags.append("저항 ×0.5")
	if int(ev.absorbed) > 0:
		tags.append("방벽 흡수")
	var col := TUi.RED
	if not tgt.unit.ally:
		col = TUi.PALE if elem == TData.ELEM_SPACE else TUi.FIRE_HOT
		if crit:
			col = Color("#fff7c8")
	if dmg >= 800 and not tgt.unit.ally:
		var m: Dictionary = ev.mult
		var parts: Array[String] = []
		for key in ["atk", "elem", "crit", "final", "vuln"]:
			var v := float(m.get(key, 1.0))
			if v > 1.05:
				parts.append({"atk": "공격", "elem": "속성", "crit": "치명", "final": "최종", "vuln": "취약"}[key] + " ×%.2f" % v)
		if not parts.is_empty():
			tags.append(" · ".join(parts))
	TFx.number(tgt.center() + Vector2(0, -14), dmg, col, tags, 1.0 if not tgt.unit.boss else 1.1)
	if dmg >= 1200:
		shake(6.0 if dmg < 3000 else 10.0)
		Fx.flash(Color(col, 0.22 if dmg < 3000 else 0.4), 0.12)
	elif heavy:
		shake(2.5)
	if run and dmg >= run.best_hit and dmg >= 1000 and not tgt.unit.ally:
		TFx.label(tgt.head() + Vector2(0, -40), "최고 기록!", TUi.GOLD, 13, 1.4)
	var gap := 0.3
	if int(ev.hits) > 1 and int(ev.hit_i) < int(ev.hits) - 1:
		gap = 0.14
	if dmg >= 3000:
		gap += 0.3
	return await _wait(gap)


# ═══════════════════════════════════════════════════════════
# 입력 (탭·키)
# ═══════════════════════════════════════════════════════════

func on_tap(p: Vector2) -> bool:
	if hud.speed_rect().has_point(p):
		fast = not fast
		Sfx.play(&"ui_move", -6.0, 0.0)
		return true
	if hud.side_rect(2).has_point(p) and phase != Phase.OVER:
		auto = not auto
		run.auto = auto
		Sfx.play(&"ui_ok", -6.0, 0.0)
		if auto and waiting():
			_cancel_select()
			var u := active
			var pot := policy.potion(battle, u)
			if not pot.is_empty():
				_decide({"potion": String(pot.potion), "target": String(pot.get("target", ""))})
			else:
				_decide(policy.choose(battle, u))
		return true
	if not waiting():
		return false
	var u := active
	if hud.side_rect(0).has_point(p):
		if battle.bag.is_empty():
			return true
		potion_menu = not potion_menu
		_cancel_select()
		Sfx.play(&"ui_move", -6.0, 0.0)
		return true
	if hud.side_rect(1).has_point(p):
		_decide({"wait": true})
		return true
	if potion_menu:
		if hud.potion_close_rect().has_point(p):
			potion_menu = false
			_cancel_select()
			return true
		for i in mini(battle.bag.size(), 3):
			if hud.potion_rect(i).has_point(p):
				_pick_potion(battle.bag[i])
				return true
	else:
		var spells: Array = TData.witch(u.base).get("spells", [])
		for i in spells.size():
			if hud.spell_rect(i).has_point(p):
				_pick_spell(String(spells[i]))
				return true
	# 배우 누르기
	for id in actors.keys():
		var a: TActor = actors[id]
		if a.unit.alive and a.hit_rect().has_point(p):
			return _tap_actor(a.unit)
	if sel_spell != "" or sel_potion != "":
		_cancel_select()
		return true
	return false


func on_key(ev: InputEventKey) -> bool:
	if ev.keycode == KEY_SPACE:
		fast = not fast
		return true
	if ev.keycode == KEY_A and phase != Phase.OVER:
		return on_tap(hud.side_rect(2).position + Vector2(2, 2))
	if not waiting():
		return false
	var u := active
	var spells: Array = TData.witch(u.base).get("spells", [])
	var idx := -1
	match ev.keycode:
		KEY_1, KEY_KP_1:
			idx = 0
		KEY_2, KEY_KP_2:
			idx = 1
		KEY_3, KEY_KP_3:
			idx = 2
		KEY_4, KEY_KP_4:
			idx = 3
		KEY_5, KEY_KP_5:
			idx = 4
		KEY_6, KEY_KP_6:
			idx = 5
	if idx >= 0 and idx < spells.size():
		potion_menu = false
		_pick_spell(String(spells[idx]))
		return true
	match ev.keycode:
		KEY_Q:
			return on_tap(hud.side_rect(0).position + Vector2(2, 2))
		KEY_W:
			_decide({"wait": true})
			return true
		KEY_ESCAPE:
			_cancel_select()
			potion_menu = false
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_Z:
			if (sel_spell != "" or sel_potion != "") and not cand.is_empty():
				_confirm()
				return true
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			if not cand.is_empty():
				var d := 1 if ev.keycode in [KEY_RIGHT, KEY_DOWN] else -1
				cand_i = (cand_i + d + cand.size()) % cand.size()
				_mark_rings()
				return true
	return false


func _tap_actor(u: TBattle.Unit) -> bool:
	if sel_spell == "" and sel_potion == "":
		return false
	var i := cand.find(u)
	if i < 0:
		return true
	cand_i = i
	_confirm()
	return true


func _pick_spell(sid: String) -> void:
	var u := active
	if not battle.can_use(u, sid):
		var a := actor_of(u.id)
		var why := "아직 못 배운 마법" if not (sid in u.spells) else ("게이지가 모자람" if String(TData.spell(sid).get("kind", "")) == "ult" else "재사용 대기 중")
		if a:
			TFx.label(a.head() + Vector2(0, -6), why, TUi.DIM, 11, 0.9)
		Sfx.play(&"block", -8.0, 0.0)
		return
	if sel_spell == sid and not cand.is_empty():
		_confirm()
		return
	var sp := TData.spell(sid)
	sel_spell = sid
	sel_potion = ""
	potion_menu = false
	Sfx.play(&"ui_move", -6.0, 0.0)
	if not battle.needs_target(sp):
		_decide({"spell": sid, "target": ""})
		return
	cand = battle.targets_for(u, sp)
	cand_i = _default_target(u, sp, cand)
	_mark_rings()


func _pick_potion(pid: String) -> void:
	var u := active
	var sp: Dictionary = TData.POTIONS[pid]
	if sel_potion == pid and not cand.is_empty():
		_confirm()
		return
	sel_potion = pid
	sel_spell = ""
	Sfx.play(&"ui_move", -6.0, 0.0)
	var tt := String(sp.get("target", ""))
	if tt == "enemies":
		_decide({"potion": pid, "target": ""})
		return
	cand = battle.targets_for(u, sp)
	cand_i = _default_target(u, sp, cand)
	_mark_rings()


## 기본 대상: 적 → 보스 > 취약이 걸린 적 > 체력이 적은 적 / 아군 → 치유는 가장 아픈 아군, 그 밖엔 지난번 고른 아군 > 딜러 > 자신
func _default_target(u: TBattle.Unit, sp: Dictionary, list: Array[TBattle.Unit]) -> int:
	if list.is_empty():
		return 0
	var tt := String(sp.get("target", "enemy"))
	if tt == "enemy":
		var best := 0
		for i in list.size():
			var e := list[i]
			var b := list[best]
			if e.boss or e.sum("vuln") > b.sum("vuln") or (e.sum("vuln") == b.sum("vuln") and e.hp < b.hp and not b.boss):
				best = i
		return best
	if float(sp.get("heal", 0.0)) > 0.0:
		var best := 0
		for i in list.size():
			if list[i].hp_ratio() < list[best].hp_ratio():
				best = i
		return best
	var last := String(_last_ally_target.get(u.id, ""))
	for i in list.size():
		if list[i].id == last:
			return i
	for i in list.size():
		if list[i].id == run.dealer and (run.dealer != u.id or String(sp.get("target", "")) == "ally"):
			if run.dealer != u.id or not sp.has("pull"):
				return i
	for i in list.size():
		if list[i].id != u.id:
			return i
	return 0


func _mark_rings() -> void:
	for id in actors.keys():
		var a: TActor = actors[id]
		a.ring = 0
	for i in cand.size():
		var a := actor_of(cand[i].id)
		if a:
			a.ring = 2 if i == cand_i else 1


func _clear_rings() -> void:
	for id in actors.keys():
		(actors[id] as TActor).ring = 0


func _cancel_select() -> void:
	sel_spell = ""
	sel_potion = ""
	cand = []
	cand_i = 0
	_clear_rings()


func _confirm() -> void:
	if cand.is_empty():
		return
	var t := cand[cand_i]
	if sel_spell != "":
		if t.ally and active != null:
			_last_ally_target[active.id] = t.id
		_decide({"spell": sel_spell, "target": t.id})
	elif sel_potion != "":
		_decide({"potion": sel_potion, "target": t.id})


func _decide(d: Dictionary) -> void:
	_decision = d
	_cancel_select()
	potion_menu = false
	Sfx.play(&"ui_ok", -8.0, 0.0)
	chosen.emit()
