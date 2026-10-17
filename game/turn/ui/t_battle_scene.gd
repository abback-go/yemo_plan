class_name TBattleScene
extends Node2D
## 전투 장면 v2 — 라운드제. 코어(TBattle)의 사건을 차례로 연출하고, 내 턴엔 판(THud)의 탭으로 행동을 고른다.
## 2.5D 구도: 카메라가 파티 뒤에 있다. 파티는 왼쪽 아래 앞(뒷모습, 크게), 적은 오른쪽 가운데 멀리(정면). 카메라는 수수하게 당기기만.
## 흐름: start() → 소개 → { 내 턴(행동 4개: 마녀 카드 → 옆 마법창 → 대상) → 적 턴(코어가 한 번에 처리, 연출은 차례로) } → 끝 → finished

signal finished(won: bool, summary: Dictionary)
signal chosen

enum Phase { INTRO, WAITING, PLAYING, OVER }

## 파티 자리 [x, y, 그림 배율] — 뒤에서 본 비스듬한 열
const ALLY_SPOTS := {"eska": [190.0, 348.0, 3.0], "sera": [78.0, 330.0, 2.7], "ashe": [340.0, 312.0, 2.5]}
## 적 자리 (수에 따라) [x, y, 배율]
const ENEMY_SPOTS := {
	1: [[540.0, 268.0, 2.2]],
	2: [[472.0, 262.0, 2.3], [574.0, 242.0, 2.1]],
	3: [[446.0, 268.0, 2.2], [528.0, 240.0, 1.9], [604.0, 262.0, 2.1]],
}

var run: TRun
var battle: TBattle
var battle_index := 0
var world: Node2D
var hud: THud
var ui_layer: CanvasLayer
var cam: Camera2D
var actors := {}
var phase := Phase.INTRO
var sel_unit: TBattle.Unit
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
var _last_ally_target := {}
var _ended := false
var _cam_target := Vector2(320, 180)
var _cam_zoom := 1.0
var _multi := {} ## (유닛:마법) → 여러 타 합계 (마지막 타에 "합계" 표시)


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
	cam = Camera2D.new()
	cam.position = Vector2(320, 180)
	add_child(cam)
	cam.make_current()
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
	for spec: Array in [[EScenery.FAR, 0.5, 1, -8], [EScenery.MID, 0.7, 2, -7]]:
		var sp := EScenery.Spires.new()
		sp.col = spec[0]
		sp.scale_k = float(spec[1])
		sp.seed_n = int(spec[2])
		sp.width = 640.0
		sp.floor_y = TStage.HORIZON_Y + 6.0
		sp.z_index = int(spec[3])
		world.add_child(sp)
	var shafts := EScenery.Shafts.new()
	shafts.floor_y = TStage.HORIZON_Y + 40.0
	shafts.width = 640.0
	shafts.material = Fx.add_material
	shafts.z_index = -6
	world.add_child(shafts)
	var stage := TStage.new()
	world.add_child(stage)
	var motes := EScenery.Motes.new()
	motes.width = 640.0
	motes.floor_y = 360.0
	motes.z_index = 9
	motes.material = Fx.add_material
	world.add_child(motes)


func _build_actors() -> void:
	var es := battle.enemies(false)
	var spots: Array = ENEMY_SPOTS.get(es.size(), ENEMY_SPOTS[3])
	for u in battle.units:
		var a := TActor.new()
		var spec: Array = ALLY_SPOTS.get(u.base, [190.0, 348.0, 3.0]) if u.ally else spots[mini(u.slot, spots.size() - 1)]
		a.setup(u, battle, float(spec[2]))
		a.position = Vector2(float(spec[0]), float(spec[1]))
		a.z_index = int(a.position.y / 8.0) - 20 ## 무대(-4)·빛줄기(-6)보다 앞, 가까울수록(아래쪽) 앞
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
	# 수수한 카메라: 메뉴가 열린 마녀 쪽으로 살짝, 적 턴엔 적 쪽으로 살짝
	var want := Vector2(320, 180)
	var zoom := 1.0
	if sel_unit != null and waiting():
		var a := actor_of(sel_unit.id)
		if a:
			want = Vector2(320, 180).lerp(a.center(), 0.18)
			zoom = 1.05
	elif battle and not battle.player_phase and phase != Phase.OVER:
		want = Vector2(336, 176)
		zoom = 1.03
	_cam_target = _cam_target.lerp(want, 1.0 - exp(-delta * 4.0))
	_cam_zoom = lerpf(_cam_zoom, zoom, 1.0 - exp(-delta * 4.0))
	cam.position = _cam_target
	cam.zoom = Vector2(_cam_zoom, _cam_zoom)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func waiting() -> bool:
	return phase == Phase.WAITING and battle.player_phase and not battle.over


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
		hud.show_tip("왼쪽 위 마녀 카드를 누르면 옆에 마법창이 펼쳐져요. 한 턴에 행동 4개, 누구의 마법이든.", 8.0)
	while not battle.over:
		if not await _play(battle.take_events()):
			return
		if battle.over:
			break
		hud.show_turn("내 턴", TUi.GOLD)
		if auto:
			if not await _auto_turn():
				return
		else:
			if not await _player_turn():
				return
		if battle.over:
			break
		_cancel_select()
		sel_unit = null
		_refresh_active()
		hud.show_turn("적 턴", TUi.ENEMY_C)
		phase = Phase.PLAYING
		if not await _wait(0.6):
			return
		battle.end_player_turn()
	_finish()


func _player_turn() -> bool:
	while battle.player_phase and battle.actions_left > 0 and not battle.over:
		phase = Phase.WAITING
		_decision = {}
		if auto:
			return await _auto_turn()
		await chosen
		if not is_inside_tree():
			return false
		phase = Phase.PLAYING
		if _decision.has("end"):
			break
		if _decision.has("potion"):
			battle.use_potion(battle.find(String(_decision.unit)), String(_decision.potion), String(_decision.get("target", "")))
		elif _decision.has("spell"):
			battle.act(battle.find(String(_decision.unit)), String(_decision.spell), String(_decision.get("target", "")))
		if not await _play(battle.take_events()):
			return false
	return true


func _auto_turn() -> bool:
	phase = Phase.PLAYING
	var guard := 0
	while battle.player_phase and battle.actions_left > 0 and not battle.over and guard < 12:
		guard += 1
		if not await _wait(0.3):
			return false
		var p := policy.potion(battle)
		if not p.is_empty():
			battle.use_potion(battle.find(String(p.unit)), String(p.potion), String(p.get("target", "")))
			if not await _play(battle.take_events()):
				return false
		var c := policy.choose(battle)
		if c.has("end"):
			break
		var u := battle.find(String(c.unit))
		sel_unit = u
		_refresh_active()
		if not battle.act(u, String(c.spell), String(c.get("target", ""))):
			break
		if not await _play(battle.take_events()):
			return false
	return true


func _finish() -> void:
	if _ended:
		return
	_ended = true
	phase = Phase.OVER
	sel_unit = null
	_cancel_select()
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
			"round_start":
				if int(ev.round) > 1:
					TFx.label(Vector2(320, 120), "라운드 " + str(int(ev.round)), TUi.PALE, 14, 1.0)
				ok = await _wait(0.2)
			"turn":
				var a := actor_of(String(ev.unit))
				if a:
					a.active = true
				ok = await _wait(0.25)
			"skipped":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -36), "봉쇄 — 움직이지 못함", TUi.PALE, 12, 1.2)
					a.active = false
				ok = await _wait(0.6)
			"skip":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -44), "다음 행동 봉쇄", TUi.PALE, 11, 1.0)
			"actions":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -14), "행동 +" + str(int(ev.amount)), TUi.FIRE_HOT, 13, 1.1)
					Sfx.play(&"levelup", -8.0, 0.0)
			"cast_start":
				var a := actor_of(String(ev.unit))
				if a:
					a.pose("cast", 0.7)
					var heavy := bool(ev.get("heavy", false))
					TFx.label(a.head() + Vector2(0, -40), "시전 " + String(ev.name) + (" — 굳센 시전!" if heavy else " — 다음 적 턴에 발동"), TUi.RED if heavy else Color("#ffb0a6"), 12, 1.6)
					Sfx.play(&"charger_windup", -8.0)
					a.active = false
				ok = await _wait(0.7)
			"cast_fire":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -40), String(ev.name) + " 발동!", TUi.RED, 14, 1.2)
				ok = await _wait(0.35)
			"act":
				ok = await _play_act(ev)
				var a := actor_of(String(ev.unit))
				if a and not a.unit.ally:
					a.active = false
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
						s += " (다음 턴 행동 +1)"
					else:
						s += (" +" if amt >= 0.0 else " ") + TUi.pct(amt)
					if int(ev.stacks) > 1:
						s += " ×" + str(int(ev.stacks))
					var bad := (kind == "vuln") or (kind == "def" and amt < 0.0)
					var col: Color = TUi.BUFF_COLORS.get(kind, TUi.TEXT)
					TFx.label(a.head() + Vector2(0, -26), s, col if not bad else TUi.RED.lerp(col, 0.4), 11, 1.0)
				ok = await _wait(0.22)
			"interrupt":
				var a := actor_of(String(ev.unit))
				if a:
					a.pose("hurt", 0.5)
					TFx.label(a.head() + Vector2(0, -44), "끊김!", TUi.GOLD, 16, 1.2)
					EVfx.shards(a.center(), 8, 160.0, Vector2(6, 6), 70.0)
					Sfx.play(&"es_deflect", -3.0)
					shake(3.0)
				ok = await _wait(0.45)
			"resist_interrupt":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.head() + Vector2(0, -44), "굳센 시전 — 봉공·물약만 끊음", TUi.RED, 11, 1.4)
				ok = await _wait(0.3)
			"die":
				var a := actor_of(String(ev.unit))
				if a:
					a.pose("die", 2.0)
					a.ring = 0
					a.active = false
					if a.unit.ally:
						Sfx.play(&"hurt", -4.0)
						TFx.label(a.head(), "쓰러짐", TUi.RED, 13, 1.4)
					else:
						EVfx.dark_burst(a.center(), 14.0 * a.draw_scale * a.unit.size)
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
					hud.show_tip("불씨가 드러났다 — 이제 화염에 약하다(×1.5). 공간은 그대로 ×1.2. 다음 적 턴은 비틀거려 쉰다.", 6.0)
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
					elif tt == "self":
						targets.append(a.info())
					else:
						var ta := actor_of(String(ev.target))
						if ta:
							targets.append(ta.info())
					a.pose("support", 0.5)
					var lead := TFx.potion(String(ev.potion), sp, a.hand(), targets)
					TFx.label(a.head() + Vector2(0, -8), "물약 · " + String(ev.name), Color(String(sp.color)), 11, 1.0)
					ok = await _wait(lead)
			"shield":
				var a := actor_of(String(ev.unit))
				if a:
					TFx.label(a.center() + Vector2(0, -24), "방벽 −" + str(int(ev.absorbed)), TUi.SHIELD_C, 11, 0.9)
			_:
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
		a.pose("ult" if kind == "ult" else ("attack" if kind == "attack" else "support"), 0.8 if kind != "ult" else 1.3)
		if kind == "ult":
			hud.show_banner(String(ev.name), TUi.ULT_C, 1.6)
		else:
			TFx.label(a.head() + Vector2(0, -8), String(ev.name), TUi.kind_color(kind), 12, 1.0)
	else:
		a.pose("attack" if kind == "attack" else "cast", 0.7)
		TFx.label(a.head() + Vector2(0, -40), String(ev.name), TUi.ENEMY_C, 12, 1.0)
		if a.unit.boss and kind == "attack":
			shake(2.0)
	_multi[String(ev.unit) + ":" + String(ev.spell)] = 0
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
	var heavy := dmg >= 400 or crit
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
	var col := TUi.RED
	if not tgt.unit.ally:
		col = TUi.PALE if elem == TData.ELEM_SPACE else TUi.FIRE_HOT
		if crit:
			col = Color("#fff7c8")
	if dmg >= 1500 and not tgt.unit.ally:
		var m: Dictionary = ev.mult
		var parts: Array[String] = []
		for key in ["atk", "elem", "crit", "final", "vuln"]:
			var v := float(m.get(key, 1.0))
			if v > 1.05:
				parts.append({"atk": "공격", "elem": "속성", "crit": "치명", "final": "최종", "vuln": "취약"}[key] + " ×%.2f" % v)
		if not parts.is_empty():
			tags.append(" · ".join(parts))
	TFx.number(tgt.center() + Vector2(0, -14), dmg, col, tags, 1.0 if not tgt.unit.boss else 1.1)
	if dmg >= 2500:
		shake(6.0 if dmg < 6000 else 10.0)
		Fx.flash(Color(col, 0.22 if dmg < 6000 else 0.4), 0.12)
	elif heavy:
		shake(2.5)
	if run and dmg >= run.best_hit and dmg >= 1500 and not tgt.unit.ally:
		TFx.label(tgt.head() + Vector2(0, -52), "최고 기록!", TUi.GOLD, 13, 1.4)
	# 여러 타 합계
	var key := String(ev.unit) + ":" + String(ev.spell)
	_multi[key] = int(_multi.get(key, 0)) + dmg
	var gap := 0.3
	if int(ev.hits) > 1 and int(ev.hit_i) < int(ev.hits) - 1:
		gap = 0.14
	elif int(ev.hits) > 1:
		var total := int(_multi.get(key, 0))
		if total > dmg:
			TFx.label(tgt.head() + Vector2(0, -34), "합계 " + TUi.fmt(total), col, 15 if total < 5000 else 19, 1.5)
		gap = 0.4
	if dmg >= 6000:
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
	if hud.auto_rect().has_point(p) and phase != Phase.OVER:
		auto = not auto
		run.auto = auto
		Sfx.play(&"ui_ok", -6.0, 0.0)
		if auto and waiting():
			_cancel_select()
			_decide({"auto": true})
		return true
	if not waiting():
		return false
	if hud.end_rect().has_point(p):
		_decide({"end": true})
		return true
	# 파티 카드 → 그 마녀의 마법창
	for u in battle.allies():
		if hud.card_rect(u.slot).has_point(p):
			_open_menu(u)
			return true
	if sel_unit != null:
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
			if hud.potion_btn_rect().has_point(p):
				if battle.bag.is_empty():
					return true
				potion_menu = true
				_cancel_select()
				Sfx.play(&"ui_move", -6.0, 0.0)
				return true
			var spells: Array = TData.witch(sel_unit.base).get("spells", [])
			for i in spells.size():
				if hud.menu_rect(i).has_point(p):
					_pick_spell(String(spells[i]))
					return true
	# 배우 누르기: 대상 고르는 중이면 대상, 아니면 아군이면 그 마녀의 창
	for id in actors.keys():
		var a: TActor = actors[id]
		if a.unit.alive and a.hit_rect().has_point(p):
			if sel_spell != "" or sel_potion != "":
				return _tap_target(a.unit)
			if a.unit.ally:
				_open_menu(a.unit)
				return true
			return false
	if sel_spell != "" or sel_potion != "":
		_cancel_select()
		return true
	if sel_unit != null:
		sel_unit = null
		potion_menu = false
		_refresh_active()
		return true
	return false


func on_key(ev: InputEventKey) -> bool:
	if ev.keycode == KEY_SPACE:
		fast = not fast
		return true
	if ev.keycode == KEY_A and phase != Phase.OVER:
		return on_tap(hud.auto_rect().get_center())
	if not waiting():
		return false
	match ev.keycode:
		KEY_E:
			_decide({"end": true})
			return true
		KEY_TAB:
			var al := battle.allies()
			if al.is_empty():
				return true
			var i := -1
			if sel_unit:
				for k in al.size():
					if al[k].id == sel_unit.id:
						i = k
			_open_menu(al[(i + 1) % al.size()])
			return true
		KEY_P, KEY_Q:
			if sel_unit:
				return on_tap(hud.potion_btn_rect().get_center())
			return false
		KEY_ESCAPE:
			_cancel_select()
			potion_menu = false
			sel_unit = null
			_refresh_active()
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
	if idx < 0:
		return false
	if sel_unit == null:
		var al := battle.allies()
		if idx < al.size():
			_open_menu(al[idx])
		return true
	var spells: Array = TData.witch(sel_unit.base).get("spells", [])
	if idx < spells.size():
		potion_menu = false
		_pick_spell(String(spells[idx]))
	return true


func _open_menu(u: TBattle.Unit) -> void:
	if not u.alive:
		return
	_cancel_select()
	potion_menu = false
	sel_unit = u
	_refresh_active()
	Sfx.play(&"ui_move", -6.0, 0.0)


func _refresh_active() -> void:
	for id in actors.keys():
		var a: TActor = actors[id]
		if a.unit.ally:
			a.active = sel_unit != null and a.unit.id == sel_unit.id


func _tap_target(u: TBattle.Unit) -> bool:
	var i := cand.find(u)
	if i < 0:
		return true
	cand_i = i
	_confirm()
	return true


func _pick_spell(sid: String) -> void:
	var u := sel_unit
	if u == null:
		return
	if not battle.can_use(u, sid):
		var a := actor_of(u.id)
		if a:
			TFx.label(a.head() + Vector2(0, -6), battle.why_not(u, sid), TUi.DIM, 11, 0.9)
		Sfx.play(&"block", -8.0, 0.0)
		return
	if sel_spell == sid and not cand.is_empty():
		_confirm()
		return
	var sp := TData.spell(sid)
	sel_spell = sid
	sel_potion = ""
	Sfx.play(&"ui_move", -6.0, 0.0)
	if not battle.needs_target(sp):
		_decide({"unit": u.id, "spell": sid, "target": ""})
		return
	cand = battle.targets_for(u, sp)
	cand_i = _default_target(u, sp, cand)
	_mark_rings()


func _pick_potion(pid: String) -> void:
	var u := sel_unit
	if u == null:
		return
	var sp: Dictionary = TData.POTIONS[pid]
	if sel_potion == pid and not cand.is_empty():
		_confirm()
		return
	sel_potion = pid
	sel_spell = ""
	Sfx.play(&"ui_move", -6.0, 0.0)
	var tt := String(sp.get("target", ""))
	if tt == "enemies" or tt == "self":
		_decide({"unit": u.id, "potion": pid, "target": u.id if tt == "self" else ""})
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
		if list[i].id == run.dealer:
			return i
	return 0


func _mark_rings() -> void:
	for id in actors.keys():
		(actors[id] as TActor).ring = 0
	for i in cand.size():
		var a := actor_of(cand[i].id)
		if a:
			a.ring = 2 if i == cand_i else 1


func _cancel_select() -> void:
	sel_spell = ""
	sel_potion = ""
	cand = []
	cand_i = 0
	for id in actors.keys():
		(actors[id] as TActor).ring = 0


func _confirm() -> void:
	if cand.is_empty() or sel_unit == null:
		return
	var t := cand[cand_i]
	if sel_spell != "":
		if t.ally:
			_last_ally_target[sel_unit.id] = t.id
		_decide({"unit": sel_unit.id, "spell": sel_spell, "target": t.id})
	elif sel_potion != "":
		_decide({"unit": sel_unit.id, "potion": sel_potion, "target": t.id})


func _decide(d: Dictionary) -> void:
	_decision = d
	_cancel_select()
	potion_menu = false
	Sfx.play(&"ui_ok", -8.0, 0.0)
	chosen.emit()
