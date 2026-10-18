class_name TStage
extends Node2D
## 턴제 전투 프로토타입 장면 (웹 주소 끝 ?turn). docs/eska-turn/combat_proto.md.
## 편성(TSetup) → 전투(TBattle 규칙 + TActor 그림 + THud 표시 + TFx 연출) → 승리(편성으로) / 패배(바로 다시).
## 전투는 코루틴 _run()이 돈다: 다음 차례 → 마녀면 바퀴에서 고르기를 기다림 / 적이면 의도대로 → 연출의 맞는 시각에 피해·숫자 → 다음.
## 배경·마녀·적은 모두 코드 그림. Esc 또는 오른쪽 위 X → 철수 확인 → 편성. 전투는 편성의 "전투 고르기"(S-03)에서 고른다.

const ArenaScript := preload("res://proto/p_arena.gd")
const WITCH_AT: Array[Vector2] = [Vector2(214, 288), Vector2(160, 258), Vector2(106, 228)] ## 앞 · 중 · 뒤 (대각선, 아래 띠 y 302 위)
const ENEMY_AT: Array[Vector2] = [Vector2(424, 290), Vector2(507, 256), Vector2(590, 222)] ## 적 1명 = 가운데 · 2명 = 앞·뒤 (THud.pos_index). 간격 83 (review_C2 L11)

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
var battle_id: String = TData.BATTLE.battle ## 전투 데이터 id (TData.BATTLES)
var _bg: TBackdrop
var auto := false ## 시험용 자동 플레이: 바퀴를 잠깐 보여 준 뒤 간단한 규칙으로 고른다 (tools/test/scenarios/turn_*.json)


func _ready() -> void:
	EKeys.register()
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.reset()
	var bg := TBackdrop.new()
	add_child(bg)
	_bg = bg
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
	setup.start_pressed.connect(_on_setup_start)
	setup.exit_pressed.connect(_exit)
	hud.visible = false
	Music.play("boss")


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
	var ul := get_node_or_null("UltLayer")
	if ul != null:
		for c in ul.get_children():
			c.queue_free()
	hud.modulate.a = 1.0
	setup.back_to_roster()
	setup.visible = true


## 편성의 전투 고르기(S-03)에서 "출격"
func _on_setup_start() -> void:
	battle_id = TSetup.battle_pick
	start_battle()


func start_battle() -> void:
	TSetup.ensure_state()
	setup.visible = false
	hud.visible = true
	for u in actors:
		(actors[u] as TActor).queue_free()
	actors.clear()
	battle = TBattle.new()
	battle.setup(TSetup.party(), battle_id, TSetup.state)
	for i in battle.witches.size():
		_add_actor(battle.witches[i], WITCH_AT[i])
	_add_enemies()
	_bg.set_boss(_wave_has_boss(), true)
	hud.bind(battle, actors)
	stats = {"turns": 0, "biggest": 0}
	_in_battle = true
	_run_id += 1
	_run(_run_id)


func _add_actor(u: TUnit, at: Vector2) -> void:
	var a := TActor.new()
	units_node.add_child(a)
	a.setup(u, at)
	a.z_index = 1 + int((at.y - 218.0) / 25.0) # 앞(아래)이 위에 그려짐 (1~3)
	actors[u] = a


## 지금 웨이브의 적을 세운다: 1명 = 가운데(10px 아래 — 큰 보스 머리가 보스 카드 밑에 들어가지 않게) · 2명 = 앞·뒤 · 3명 = 앞·중·뒤
func _add_enemies() -> void:
	var n := battle.enemies.size()
	for i in n:
		_add_actor(battle.enemies[i], ENEMY_AT[THud.pos_index(n, i)] + (Vector2(0, 10) if n == 1 else Vector2.ZERO))


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
		while hud.confirm_open and token == _run_id: # 철수 확인 판이 열려 있는 동안 멈춤
			await _wait(0.1)
		if token != _run_id:
			return
		var u := battle.next_actor()
		if u == null:
			return
		hud.refresh()
		var a: TActor = actors[u]
		if u.stunned:
			# 기절로 쉬는 차례 (§17.2): 행동 없음, 0.6초
			battle.rest(u)
			hud.show_msg("%s — 기절 — 쉼" % u.name, TTheme.STUN)
			hud.pop(u, "기절 — 쉼", "status")
			await _wait(0.6)
		elif u.is_witch():
			a.set_turn(true)
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
				return # 철수·다시 시작으로 이 전투가 끝났다 (그림 a는 이미 지워졌을 수 있다 — 다음 전투의 고르기에 깨어나도 건드리지 않음)
			a.set_turn(false)
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
				hud.pop(e.tgt, "크레딧 0", "zero")
		hud.refresh()
		var oc := battle.outcome()
		if oc == "wave":
			await _wave_change(token)
		elif oc != "":
			await _finish(oc, token)
			return


## 웨이브 전환 (§6.3 · §22.2): 배너 "웨이브 N/M" 1.0초 + 북 소리 → 다음 웨이브의 적이 오른쪽 밖에서 0.4초 걸어 들어온다 (마녀 쪽은 그대로).
## 보스 웨이브면 하늘 아래쪽이 붉어지고 보스가 땅을 울린다
func _wave_change(token: int) -> void:
	await _wait(0.3)
	if token != _run_id:
		return
	hud.wave_banner(battle.wave_i + 2, battle.wave_count())
	Sfx.play(&"tn_wave", -2.0)
	await _wait(1.0)
	if token != _run_id:
		return
	for e in battle.enemies:
		if actors.has(e):
			(actors[e] as TActor).queue_free()
			actors.erase(e)
	battle.next_wave()
	_add_enemies()
	var boss := _wave_has_boss()
	for e in battle.enemies:
		var ea: TActor = actors[e]
		ea.walk_in(260.0 if not e.boss else 300.0, 0.4)
		TFx.walk_dust(ea.feet() + Vector2(260, 0))
	if boss:
		_bg.set_boss(true)
		TFx.after(0.4, func() -> void:
			Fx.shake(0.8, 0.35)
			Sfx.play(&"tn_wave", 0.0, 0.0)
			for e in battle.enemies:
				if actors.has(e):
					var sw := TFx.Shockwave.new()
					TFx.add(sw, (actors[e] as TActor).feet(), false))
	hud.refresh()
	await _wait(0.4)


func _wave_has_boss() -> bool:
	for e in battle.enemies:
		if e.boss:
			return true
	return false


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
	var el := String(u.data.element)
	if action.kind == "basic":
		fx_id = "basic_fire"
		if el in ["space", "time"]:
			fx_id = "basic_eska"
		elif el == "sword":
			fx_id = "slash"
		hud.hold_view()
		ev = battle.basic_attack(u, tgt)
		a.lunge()
		a.pose("cast")
	var ult := ""
	if action.kind != "basic":
		var s := TData.skill(String(action.skill))
		fx_id = String(s.fx)
		big = int(s.cost) >= 4
		hud.hold_view()
		ev = battle.use_skill(u, String(action.skill), tgt)
		if bool(s.get("ultimate", false)) and TFx.is_ult(String(action.skill)):
			ult = String(action.skill)
		elif String(s.kind) == "attack":
			a.lunge()
		a.pose("cast_big" if big else "cast")
	hud.show_msg("%s — %s" % [u.name, battle.last_action], TData.ELEMENT_COLOR.get(el, TTheme.LINE))
	hud.refresh()
	var timing: Dictionary
	if ult != "":
		# 대마법 2.0초 (§13.4 · §22.2): HUD를 잠깐 걷고 컷인 → 효과 → 숫자
		var stage := maxi(battle.chain_stage, 1)
		for e in ev:
			if String(e.t) == "chain":
				stage = int(e.stage)
		_ult_hud_fade()
		timing = TFx.ultimate(ult, a, targets, stage, _alive_actors(battle.enemies), _alive_actors(battle.witches))
	else:
		timing = TFx.play(fx_id, a, targets)
	await _show_events(ev, targets, timing, "space" if el in ["space", "time", "sword"] else "fire")
	_show_total(ev)
	hud.release_view()
	a.pose("idle")
	hud.refresh()


func _perform_enemy(a: TActor) -> void:
	var u := a.unit
	var it := u.intent()
	var kind := String(it.get("k", "attack"))
	# 해제 연출용: 행동 전 마녀들의 버프 아이콘 · 관통용: 행동 전 무적
	var icons_before := {}
	var inv_before := {}
	for w in battle.witches:
		if w.alive:
			icons_before[w] = w.buff_icons()
			inv_before[w] = w.is_invincible()
	a.set_acting(true)
	if kind == "finisher":
		# 필살기 예고 0.35초 (화면 가장자리 붉게 + 그 적 둘레 붉은 기운)
		hud.show_msg("%s — %s" % [u.name, String(it.get("name", "필살기"))], TTheme.DANGER)
		a.pose("buff")
		TFx.finisher_warn(a)
		await _wait(0.35)
	hud.hold_view()
	var ev := battle.enemy_action(u)
	hud.show_msg("%s — %s" % [u.name, battle.last_action], TTheme.DANGER)
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
	match kind:
		"stun_attack": fx_id = "enemy_heavy"
		"finisher": fx_id = "enemy_aoe" if bool(it.get("aoe", false)) else "enemy_heavy"
		"dispel": fx_id = "enemy_buff"
	var timing := TFx.play(fx_id, a, targets)
	if bool(it.get("pierce", false)) and targets[0] != a:
		var ps := TFx.PierceSpear.new()
		ps.from = a.center()
		ps.to = (targets[0] as TActor).center()
		ps.barrier = bool(inv_before.get((targets[0] as TActor).unit, false))
		TFx.add(ps, Vector2.ZERO, true)
	var lost := {}
	for e in ev:
		if String(e.t) == "dispel" and icons_before.has(e.tgt):
			lost[e.tgt] = icons_before[e.tgt]
	if not lost.is_empty():
		TFx.after(0.3, func() -> void: TFx.dispel_fx(_alive_actors(battle.witches), lost, hud))
	await _show_events(ev, targets, timing, "enemy")
	await _wait(0.2)
	hud.release_view()
	a.set_acting(false)
	a.pose("idle")
	hud.refresh()


func _alive_actors(units: Array) -> Array:
	var out: Array = []
	for u in units:
		if u.alive and actors.has(u):
			out.append(actors[u])
	return out


## 대마법 동안 HUD를 걷었다가(컷인 0.15~0.62초) 피해 숫자 전에 되돌린다
func _ult_hud_fade() -> void:
	var tw := create_tween()
	tw.tween_property(hud, "modulate:a", 0.12, 0.15)
	tw.tween_interval(0.47)
	tw.tween_property(hud, "modulate:a", 1.0, 0.18)


## 연출의 시각표에 맞춰 사건을 보여 준다: 맞는 순간마다 그 대상의 사건(피해·징표·디버프), 그 뒤 나머지(버프·크레딧 …)
func _show_events(ev: Array, targets: Array, timing: Dictionary, kind: String) -> void:
	var hits: Array = timing.get("hits", [0.2])
	var total := float(timing.get("total", 0.8))
	var sub := float(timing.get("sub", 0.09)) # 같은 대상의 다단 타격 간격
	var shown := {}
	var t_prev := 0.0
	for i in hits.size():
		var ht := float(hits[i])
		await _wait(ht - t_prev)
		t_prev = ht
		var ta: TActor = targets[i] if i < targets.size() else (targets[0] if not targets.is_empty() else null)
		var nth := 0
		for j in ev.size():
			if shown.has(j):
				continue
			var e: Dictionary = ev[j]
			if ta != null and e.get("tgt") == ta.unit and e.t in ["hit", "mark", "debuff", "invincible", "enemy_gauge", "gauge_zero", "extend_mark", "resist", "stun", "immune", "stun_resist", "burst", "charge_down"]:
				if e.t == "hit" and int(e.get("sub", 0)) > 0:
					nth += 1
					await _wait(sub)
					t_prev += sub
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
	hud.view_event(e) # 화면의 보이는 값 (체력·징표·버프)을 이 사건이 뜨는 순간에 맞춤
	match String(e.t):
		"hit":
			if bool(e.invincible):
				hud.pop(tgt, "무적", "status")
				var b := TFx.Barrier.new()
				TFx.add(b, ta.center(), false)
				Sfx.play(&"bl_unfold", -10.0)
				return
			var dmg := int(e.dmg)
			var heavy := dmg >= 100000 or bool(e.crit)
			stats.biggest = maxi(int(stats.biggest), dmg if tgt.is_witch() == false else 0)
			ta.hurt(heavy)
			if bool(e.crit) and not tgt.is_witch():
				TFx.crit_flash(ta.center())
			if dmg >= 10000000:
				Fx.flash(Color(1, 1, 1, 0.5), 0.12) # 1,000만 이상 (§22.3)
			var dir := -1.0 if tgt.is_witch() else 1.0
			TFx.impact(ta.center() + Vector2(randf_range(-4, 4), randf_range(-6, 2)), kind, heavy, dir)
			# 숫자 (§21.12): 일반 12 · 크리 24 금빛 "!" · 약점 15 + "약점" 꼬리표 · 한 히트 30만 이상 24 · 받은 피해 15
			var nk := "dmg"
			var txt := TData.fmt_short(dmg)
			if tgt.is_witch():
				nk = "hurt"
				Fx.flash(Color(1.0, 0.2, 0.3, 0.18), 0.12)
				Sfx.play(&"hurt", -6.0)
			elif bool(e.crit):
				nk = "crit"
				txt += "!"
				Sfx.play(&"tn_crit", -4.0)
			elif dmg >= 300000:
				nk = "big"
			elif bool(e.weak):
				nk = "weak"
			hud.pop(tgt, txt, nk, bool(e.weak) and not tgt.is_witch())
			if dmg >= 300000:
				Fx.hitstop(0.1)
				Fx.shake(0.7, 0.3)
			elif heavy:
				Fx.hitstop(0.05)
				Fx.shake(0.4, 0.2)
			if bool(e.broke):
				# 브레이크 1.0초 (§22.2): 멈춤 0.15 · 막대 깨짐 0.5 · 다음 줄 차오름 0.35 — "브레이크" 글은 BarShatter가 30px로
				var cr: Rect2 = hud._card_rect(tgt)
				var bar := Rect2(cr.position + Vector2(4, 32), Vector2(300, 6)) if hud._boss_card_on() else Rect2(cr.position + Vector2(4, 31), Vector2(92, 5))
				TFx.break_fx(ta, bar, hud)
			if bool(e.guts):
				hud.pop(tgt, "근성", "status")
				TFx.guts_fx(ta)
			if bool(e.killed):
				var tw := create_tween()
				tw.tween_interval(0.25)
				tw.tween_callback(func() -> void:
					hud.view_event({"t": "down", "tgt": tgt})
					ta.set_down(true)
					if not tgt.is_witch():
						TFx.ash_dissolve(ta)
					hud.pop(tgt, "쓰러짐", "status")
					Sfx.play(&"bl_fold", -6.0))
		"buff":
			var cat := String(e.cat)
			var txt := ""
			if cat == "element":
				txt = "%s 속성 부여" % TData.ELEMENT_NAME.get(e.get("el", ""), "")
			elif cat == "dmg_taken":
				txt = "받는 피해 %+d%%" % int(round(float(e.v) * 100.0))
			else:
				var nm: String = TData.CAT_NAME.get(cat, cat)
				if cat == "special":
					nm = "%s 특공" % TData.MARK_NAME.get(e.get("mark", ""), "")
				txt = "%s +%d%%" % [nm, int(round(float(e.v) * 100.0))]
			hud.pop(tgt, txt, "buff")
		"debuff":
			hud.pop(tgt, "%s %d%%" % [TData.CAT_NAME.get(e.cat, e.cat), int(round(float(e.v) * 100.0))], "debuff")
		"mark":
			var mn := int(e.get("n", 1))
			hud.pop(tgt, TData.MARK_NAME.get(e.kind, e.kind) + (" %d겹" % mn if mn > 1 else ""), "mark")
		"burst":
			hud.pop(tgt, "%s %d겹 터뜨림" % [TData.MARK_NAME.get(e.kind, e.kind), int(e.n)], "mark")
		"resist":
			hud.pop(tgt, "저항", "status")
			TFx.resist_fx(ta, false)
		"stun":
			hud.pop(tgt, "기절", "status")
			TFx.stun_fx(ta)
		"immune":
			hud.pop(tgt, "면역", "status")
			TFx.resist_fx(ta, true)
		"stun_resist":
			hud.pop(tgt, "기절 내성", "status")
			TFx.resist_fx(ta, true)
		"taunt":
			hud.pop(tgt, "도발", "buff")
			TFx.taunt_fx(ta)
		"guts_on":
			hud.pop(tgt, "근성", "buff")
		"dispel":
			hud.pop(tgt, "버프 해제", "debuff")
		"credits":
			if int(e.v) > 0:
				hud.pop(tgt, "크레딧 +%d" % int(e.v), "credit")
		"gauge":
			if float(e.v) > 0.0:
				hud.pop(tgt, "게이지 +%d%%" % int(round(float(e.v) * 100.0)), "buff")
		"heal":
			if int(e.v) > 0:
				hud.pop(tgt, "+" + TData.fmt_short(int(e.v)), "heal")
		"revive":
			ta.set_down(false)
			hud.pop(tgt, "되살아남", "revive")
		"invincible":
			hud.pop(tgt, "무적", "buff")
		"inv_guard":
			hud.pop(tgt, "무적 내성", "status")
		"enemy_buff":
			hud.pop(tgt, "공격력 +%d%%" % int(round(float(e.v) * 100.0)), "debuff")
		"demerit":
			hud.pop(tgt, "다음 행동 뒤 크레딧 0", "zero")
		"enemy_gauge":
			hud.pop(tgt, "게이지 −%d%%" % int(round(float(e.v) * 100.0)), "debuff")
		"gauge_zero":
			hud.pop(tgt, "게이지 0", "debuff")
		"extend_buffs":
			hud.pop(tgt, "버프 지속 +%d" % int(e.v), "buff")
		"extend_mark":
			hud.pop(tgt, "%s +%d" % [TData.MARK_NAME.get(e.kind, e.kind), int(e.v)], "mark")
		# 단계 B
		"chain":
			hud.pop(tgt, "연쇄 %d단계" % int(e.stage), "break")
		"charge_down":
			if int(e.v) > 0:
				hud.pop(tgt, "차지 −%d" % int(e.v), "debuff")
		"hp_cost":
			if int(e.v) > 0:
				hud.pop(tgt, "−" + TData.fmt_short(int(e.v)), "hurt")
		"stack":
			hud.pop(tgt, "공격력 +%d%% (%d겹)" % [int(round(float(e.v) * 100.0)), int(e.n)], "buff")
		"hit_stack":
			hud.pop(tgt, "맞으며 쌓기", "buff")


## 한 행동의 적 피해 합계 (히트가 2번 이상일 때, §21.12 [하면 좋음 G1]) — 행동 띠 끝에 금빛으로 (review_C2 L4)
func _show_total(ev: Array) -> void:
	var sum := 0
	var n := 0
	var first: TUnit = null
	for e in ev:
		if String(e.t) == "hit" and e.tgt is TUnit and not (e.tgt as TUnit).is_witch() and not bool(e.invincible):
			sum += int(e.dmg)
			n += 1
			if first == null:
				first = e.tgt
	if n >= 2 and first != null:
		hud.show_total(sum)


func _finish(oc: String, token: int) -> void:
	await _wait(0.5)
	if token != _run_id:
		return
	_in_battle = false
	if oc == "win":
		for u in actors:
			if u.is_witch() and u.alive:
				(actors[u] as TActor).pose("win")
				TFx.victory_sparkle(actors[u])
		Sfx.play(&"tn_victory", -2.0)
		hud.banner("승리", "눌러서 편성으로")
	else:
		Sfx.play(&"tn_defeat", -2.0)
		hud.banner("패배", "")


## 배너 누름: 승리 → 편성 · 패배 → "다시 도전"(같은 전투) 또는 "편성으로"
func _on_banner(choice: String) -> void:
	if hud.banner_text == "패배" and choice == "retry":
		hud.clear_banner()
		start_battle()
	else:
		_to_setup()


func set_auto(v: bool) -> void:
	auto = v


## 시험용: 전투 데이터를 바꾼다 (normal_01 · boss_01 · trial_01) — 편성의 전투 고르기에서 고른 것과 같다
func set_battle(id: String) -> void:
	battle_id = id
	TSetup.battle_pick = id


## 시험용: 파티를 바꾼다 (편성 화면을 거치지 않고)
func set_party(ids: Array) -> void:
	TSetup.ensure_state()
	var p: Array = []
	for i in ids:
		p.append(String(i))
	TSetup.state.party = p


## 시험용 자동 선택: TAuto (turn_sim과 같은 규칙)
func _auto_pick(a: TActor) -> Dictionary:
	return TAuto.pick(battle, a.unit)


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


## 시험용: 대마법 연출 하나를 그냥 띄운다 (규칙은 건드리지 않음 — tools/test/scenarios/turn_ult.json). 맞는 시각마다 가짜 숫자
func demo_ult(sid: String, stage := 1) -> String:
	var caster: TActor = null
	for u in actors:
		if u.is_witch() and String(u.data.get("ultimate", "")) == sid:
			caster = actors[u]
	if caster == null:
		return "no caster for " + sid
	hud.close_wheel()
	var sk := TData.skill(sid)
	var targets: Array = []
	match String(sk.get("target", "enemy")):
		"enemy":
			targets = _alive_actors(battle.enemies).slice(0, 1)
		"enemies":
			targets = _alive_actors(battle.enemies)
		_:
			targets = _alive_actors(battle.witches)
	caster.pose("cast_big")
	_ult_hud_fade()
	hud.show_msg("%s — %s" % [caster.unit.name, String(sk.get("name", sid))], TData.ELEMENT_COLOR.get(caster.unit.element, TTheme.LINE))
	var timing := TFx.ultimate(sid, caster, targets, stage, _alive_actors(battle.enemies), _alive_actors(battle.witches))
	var hits: Array = timing.hits
	var sub := float(timing.get("sub", 0.09))
	var n := int(sk.get("effects", [{}])[0].get("n", 1)) if String(sk.get("effects", [{}])[0].get("t", "")) == "multi" else 1
	var attack := String(sk.get("kind", "")) == "attack"
	for i in hits.size():
		var ta: TActor = targets[i] if i < targets.size() else null
		if ta == null:
			continue
		for j in (n if attack else 1):
			var at := float(hits[i]) + sub * float(j)
			TFx.after(at, func() -> void:
				if not is_instance_valid(ta):
					return
				if attack:
					ta.hurt(true)
					TFx.impact(ta.center(), "space" if caster.unit.element in ["space", "sword"] else "fire", true, 1.0)
					hud.pop(ta.unit, TData.fmt_short(1234567 * (j + 1)) + ("!" if sid == "ult_harpe" else ""), "crit" if sid in ["ult_harpe", "ult_fulgur"] else "big")
				else:
					hud.pop(ta.unit, "버프", "buff"))
	var tw := create_tween()
	tw.tween_interval(float(timing.total))
	tw.tween_callback(func() -> void: caster.pose("idle"))
	return "%s stage=%d hits=%s total=%.2f" % [sid, stage, str(hits), float(timing.total)]


## 시험용: 지금 프레임의 그리기 호출 · 입자 수 · 연출 노드 수 (대마법 성능 확인, §22)
func perf() -> String:
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var pa := PParticles.get_layer(true).count()
	var pn := PParticles.get_layer(false).count()
	var fxn := get_node("Effects").get_child_count()
	var ul := get_node_or_null("UltLayer")
	return "draw_calls=%d objects=%d particles=%d+%d fx_nodes=%d ult_nodes=%d" % [dc, obj, pa, pn, fxn, ul.get_child_count() if ul != null else 0]


## 시험용: 상태 연출 하나를 띄운다 (break · stun · dispel · guts · taunt · resist · immune · pierce · finisher · crit). 규칙은 브레이크의 줄 번호만 넘긴다
func demo_event(kind: String) -> String:
	hud.close_wheel()
	var foe: TUnit = battle.alive_of(battle.enemies)[0]
	var w: TUnit = battle.alive_of(battle.witches)[0]
	var hit := {"t": "hit", "tgt": foe, "dmg": 1500000, "crit": false, "weak": false, "invincible": false, "broke": false, "guts": false, "killed": false}
	match kind:
		"break":
			if foe.bars.size() > foe.bar_i + 1:
				foe.bar_i += 1
				foe.max_hp = int(foe.bars[foe.bar_i])
				foe.hp = foe.max_hp
			hit.broke = true
			_show_event(hit, "fire")
		"crit":
			hit.crit = true
			_show_event(hit, "fire")
		"stun":
			w.stunned = true
			_show_event({"t": "stun", "tgt": w}, "enemy")
		"guts":
			_show_event({"t": "hit", "tgt": w, "dmg": 30000, "crit": false, "weak": false, "invincible": false, "broke": false, "guts": true, "killed": false}, "enemy")
		"taunt", "resist", "immune":
			_show_event({"t": kind, "tgt": w if kind == "taunt" else foe}, "enemy")
		"dispel":
			var lost := {}
			for u in battle.alive_of(battle.witches):
				lost[u] = [{"cat": "atk"}, {"cat": "crit_dmg"}, {"cat": "invincible"}, {"cat": "dmg_taken", "v": -0.3}]
				hud.pop(u, "버프 해제", "debuff")
			TFx.dispel_fx(_alive_actors(battle.witches), lost, hud)
		"pierce", "finisher":
			var fa: TActor = actors[foe]
			TFx.finisher_warn(fa)
			fa.set_acting(true)
			TFx.after(0.35, func() -> void:
				var ps := TFx.PierceSpear.new()
				ps.from = fa.center()
				ps.to = (actors[w] as TActor).center()
				ps.barrier = kind == "pierce"
				TFx.add(ps, Vector2.ZERO, true)
				fa.set_acting(false))
	return kind


## 시험용: 지금 웨이브의 적을 모두 쓰러뜨리고 다음 웨이브로 넘긴다 (웨이브 전환 연출 확인 — 규칙의 다음 웨이브를 그대로 씀)
func demo_wave() -> String:
	hud.close_wheel()
	for e in battle.enemies:
		e.alive = false
		e.hp = 0
		if actors.has(e):
			(actors[e] as TActor).set_down(true)
			TFx.ash_dissolve(actors[e])
	if battle.wave_i + 1 >= battle.wave_count():
		return "last wave"
	_wave_change(_run_id)
	return "wave %d" % (battle.wave_i + 2)
