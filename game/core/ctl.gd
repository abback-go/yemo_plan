## ctl.gd — 장면 흐름과 전투 진행 (1차 시험판 v2: 탑뷰 탐사 + 1인칭 카드 전투 + 운명).
## 1층(튜토리얼): 곁방(캠프 대화) → 광신도의 회랑(의식 원 → 전투) → 갈림길(출구 하나 → 이벤트 → 계단 대화)
##   → 1층의 깊은 곳(광신도 → 거대 존재 → 죽음 카드 → 탈출) → 빈 캠프(다음 운명: 브룬힐드) → 1층 끝
## 2층: 창 함정 회랑(운명의 시도: 브룬힐드 관통 Lv1, 필드) → 기사단 납골당(창 기사 전투) → 계단(Lv업·새 운명: 엘리안)
## 3층: 불탄 예배당 회랑(브룬힐드가 살았다면 Lv2 시도) → 화형대 광장(화형 사제 전투, 2턴 엘리안 운명의 시도) → 결과 요약
## 전멸: 1층 광신도·2·3층은 그 전투 처음부터 / 거대 존재는 "카드를 내지 않은 미래"(붉게 번짐 → 유리 깨짐 → 등장 직후부터)
class_name Ctl
extends Node

const STEPS := ["camp", "cult", "fork", "deep", "emptycamp", "chapter1", "f2corridor", "f2ossuary", "f2stairs", "f3chapel", "f3pyre", "result"]
const FOLLOWER_OF := {"hero": "seraphina", "warrior": "brunhild", "archer": "elian"}

var st := {}
var busy := false
var in_battle := false
var snaps := {}           # 전투 처음 상태 (재시작용) enc → 스냅샷
var seed = null
var flow := 0             # 흐름 번호: 장면을 건너뛰면(시험용 바로 가기) 이전 흐름은 멈춘다
var log: Array = []
var stage := ""           # 지금 단계 이름 (시험용)
var result_ready := false # 카드·턴 종료 연출이 끝나고 전투 결과를 처리할 차례
var descend_events: Array = []
var td: TopdownScene = null   # 지금 탑뷰 장면


func note(s: String) -> void:
	if G.params.has("trace"):
		print("[%7.1f] %s" % [Time.get_ticks_msec() / 1000.0, s])
	log.append(s)
	if log.size() > 300:
		log.pop_front()


func new_game() -> Dictionary:
	st = Rules.new_game(seed)
	if G.params.has("run"):
		st.run = int(G.params.run)
	G.guide.reset()
	snaps = {}
	note("newGame seed=%d" % int(st.seed))
	return st


func reason_text(r: String) -> String:
	return str(G.S.reasons.get(r, r))


func _set_busy(b: bool) -> void:
	busy = b
	if not G.view.vm.is_empty():
		G.view.render()


func _alive(my: int) -> bool:
	return my == flow


# ───────── 처음부터 ─────────
func start_tutorial() -> void:
	flow += 1
	var my := flow
	G.dialog.clear()
	G.scenes.clear()
	new_game()
	await run_from("camp", my)


## 지정한 단계부터 끝까지 진행한다 (시험용 바로 가기도 이 함수를 쓴다)
func run_from(step: String, my: int) -> void:
	var i := STEPS.find(step)
	if i < 0:
		return
	for k in range(i, STEPS.size()):
		if not _alive(my):
			return
		var s: String = STEPS[k]
		stage = s
		note("step " + s)
		var ok := false
		match s:
			"camp": ok = await _step_camp(my)
			"cult": ok = await _step_cult(my)
			"fork": ok = await _step_fork(my)
			"deep": ok = await _step_deep(my)
			"emptycamp": ok = await _step_emptycamp(my)
			"chapter1": ok = await _step_chapter1(my)
			"f2corridor": ok = await _step_f2corridor(my)
			"f2ossuary": ok = await _step_f2ossuary(my)
			"f2stairs": ok = await _step_f2stairs(my)
			"f3chapel": ok = await _step_f3chapel(my)
			"f3pyre": ok = await _step_f3pyre(my)
			"result": ok = await _step_result(my)
		if not ok or not _alive(my):
			return


func _visit(room: String) -> void:
	st.progress.room = room
	if not st.progress.visited.has(room):
		st.progress.visited.append(room)


## 따라 걷는 동료 (살아 있는 사람만, 순서: 세라피나 · 브룬힐드 · 엘리안)
func party_followers() -> Array:
	var out := []
	for id in ["hero", "warrior", "archer"]:
		if st.party.allies.has(id) and st.party.allies[id].status != "dead":
			out.append(FOLLOWER_OF[id])
	return out


## 탑뷰 맵을 연다 (지금 장면을 바꾼다)
func td_open(map_id: String, o := {}) -> TopdownScene:
	in_battle = false
	G.view.clear()
	G.dialog.clear()
	if not o.has("party"):
		o.party = party_followers()
	var t := TopdownScene.new()
	t.setup(map_id, o)
	G.scenes.mount(t, "td:" + map_id)
	td = t
	stage = "td:" + map_id
	return t


func _td_ok(t: TopdownScene, my: int) -> bool:
	return _alive(my) and is_instance_valid(t) and t.is_inside_tree()


## 사건(트리거·출구)을 기다린다. want: 기다리는 트리거 id 들(없으면 출구만)
func _wait_event(t: TopdownScene, my: int) -> Dictionary:
	if not _td_ok(t, my):
		return {}
	var ev: Dictionary = await t.next_event()
	if not _td_ok(t, my):
		return {}
	return ev


## 트리거에 들어서면 전투 → 이긴 뒤 같은 자리에서 맵을 다시 열고 출구로. 반환: 다시 연 맵(null = 흐름이 끊김)
func _battle_on_map(t: TopdownScene, map_id: String, trig: String, enc: String, my: int, hide := []) -> TopdownScene:
	t.arm([trig])
	while true:
		var ev := await _wait_event(t, my)
		if ev.is_empty():
			return null
		if ev.type == "trigger" and ev.id == trig:
			break
	var at := [t.foot.x, t.foot.y]
	var dir := t.dir
	var appear: Array = t.T.get("appear", [])
	var grp: String = hide[0] if not hide.is_empty() else "enemies"
	if t.npcs.size() > 0 and not appear.is_empty():
		await t.npc_walk_out(grp)
		if not _td_ok(t, my):
			return null
	await t.npc_alert(grp)
	if not _td_ok(t, my):
		return null
	if not appear.is_empty():
		await t.say(appear)
	if not _alive(my):
		return null
	await FX.fade(1, 450)
	var won := await battle(enc, false, my)
	if not won or not _alive(my):
		return null
	await FX.fade(1, 400)
	var t2 := td_open(map_id, {"at": at, "dir": dir, "hide": hide})
	await t2.run()
	return t2


## 출구까지 기다렸다가 나간다
func _leave_by_exit(t: TopdownScene, my: int) -> bool:
	while true:
		var ev := await _wait_event(t, my)
		if ev.is_empty():
			return false
		if ev.type == "exit":
			await t.walk_out()
			return _alive(my)
	return false


# ───────── 1층 ─────────
func _step_camp(my: int) -> bool:
	_visit("camp")
	var C: Dictionary = MapsData.M.camp
	var t := td_open("camp", {"at": C.start, "dir": str(C.dir), "seated": true})
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.play_vn("camp")
	if not _td_ok(t, my):
		return false
	await G.dialog.say(G.S.topdown.moveGuide)
	return await _leave_by_exit(t, my)


func _step_cult(my: int) -> bool:
	_visit("hall")
	var t := td_open("cult_hall")
	t.locked_exits = ["east"]
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.say(t.T.intro)
	var t2 := await _battle_on_map(t, "cult_hall", "circle", "normal", my, ["cultists"])
	if t2 == null:
		return false
	return await _leave_by_exit(t2, my)


func _step_fork(my: int) -> bool:
	_visit("fork")
	var t := td_open("fork")
	await t.run()
	if not _td_ok(t, my):
		return false
	# 처음 지도가 열릴 때 (대본 3.1)
	if not st.flags.get("mapSeen", false):
		st.flags.mapSeen = true
		await FX.wait(300)
		await t.hud.open_map_first()
		if not _td_ok(t, my):
			return false
	await G.guide.fire("exploreShown", {"explore": "fork"})
	var ev := await _wait_event(t, my)
	if ev.is_empty():
		return false
	st.flags.path = ev.id
	note("path " + str(ev.id))
	await t.walk_out()
	if not _alive(my):
		return false
	_visit(str(ev.id))
	stage = "event:" + str(ev.id)
	await G.scenes.vn(str(ev.id))
	if not _alive(my):
		return false
	_visit("stairs")
	stage = "stairs"
	await G.scenes.vn("stairs")
	return _alive(my)


func _step_deep(my: int) -> bool:
	_visit("deep")
	var t := td_open("deep_hall")
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.say(t.T.intro)
	t.arm(["altar"])
	while true:
		var ev := await _wait_event(t, my)
		if ev.is_empty():
			return false
		if ev.type == "trigger":
			break
	await t.npc_alert("cultists")
	if not _td_ok(t, my):
		return false
	await FX.fade(1, 450)
	var ok := await battle("deep", false, my)   # 광신도 → 거대 존재 → 죽음 카드 → 물러남
	if not ok or not _alive(my):
		return false
	# 탈출
	stage = "escape"
	await G.dialog.say(G.S.escape.lines)
	if not _alive(my):
		return false
	await G.scenes.escape()
	if not _alive(my):
		return false
	if st.battle != null:
		Rules.finish_battle(st)
	in_battle = false
	G.view.clear()
	return true


func _step_emptycamp(my: int) -> bool:
	_visit("camp")
	stage = "emptycamp"
	var C: Dictionary = MapsData.M.camp
	var t := td_open("camp", {"at": C.start, "dir": str(C.dir), "seated": true})
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.play_vn("emptycamp")   # 끝에 다음 운명(브룬힐드 관통 Lv1)이 또렷해진다
	if not _alive(my):
		return false
	await FX.fade(1, 700)
	return _alive(my)


func _step_chapter1(my: int) -> bool:
	await G.scenes.chapter(G.S.chapter1)
	if not _alive(my):
		return false
	descend_events = Rules.descend(st)
	return true


# ───────── 2층 ─────────
func _step_f2corridor(my: int) -> bool:
	_visit("f2corridor")
	var t := td_open("spike_corridor")
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.say(t.T.intro)
	return await _fate_map(t, ["fate"], "warrior_pierce", my)


## 맵을 걸으며 운명의 트리거(있으면)를 지나 출구로
func _fate_map(t: TopdownScene, trigs: Array, fate_id: String, my: int) -> bool:
	var f = Rules.fate_by_id(st, fate_id)
	if f != null and f.alive and int(f.floor) == Rules.floor_now(st) and int(f.get("triedFloor", 0)) != Rules.floor_now(st):
		t.arm(trigs)
	while true:
		var ev := await _wait_event(t, my)
		if ev.is_empty():
			return false
		if ev.type == "trigger":
			await field_fate(t, fate_id, my)
			if not _td_ok(t, my):
				return false
			continue
		if ev.type == "exit":
			await t.walk_out()
			return _alive(my)
	return false


func _step_f2ossuary(my: int) -> bool:
	_visit("f2ossuary")
	var t := td_open("ossuary")
	t.locked_exits = ["north"]
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.say(t.T.intro)
	var t2 := await _battle_on_map(t, "ossuary", "altar", "ossuary", my, ["enemies"])
	if t2 == null:
		return false
	return await _leave_by_exit(t2, my)


func _step_f2stairs(my: int) -> bool:
	_visit("f2stairs")
	st.flags.brun = "dead" if st.party.allies.warrior.status == "dead" else "alive"
	stage = "f2stairs"
	await G.scenes.vn("f2stairs")   # 살아서 내려간 운명 Lv2 · 새 운명(엘리안 화형 Lv1) · 3층
	return _alive(my)


# ───────── 3층 ─────────
func _step_f3chapel(my: int) -> bool:
	_visit("f3chapel")
	var t := td_open("burnt_chapel")
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.say(t.T.intro)
	return await _fate_map(t, ["fate"], "warrior_pierce", my)


func _step_f3pyre(my: int) -> bool:
	_visit("f3pyre")
	var t := td_open("pyre_court")
	t.locked_exits = ["north"]
	await t.run()
	if not _td_ok(t, my):
		return false
	await t.say(t.T.intro)
	var t2 := await _battle_on_map(t, "pyre_court", "pyre", "pyre", my, ["enemies"])
	if t2 == null:
		return false
	return await _leave_by_exit(t2, my)


func _step_result(my: int) -> bool:
	_visit("f3stairs")
	await FX.fade(1, 500)
	G.scenes.result()
	return _alive(my)


# ───────── 운명의 시도 (필드: 탑뷰에서) ─────────
## 함정 판 철컥 → 시간 정지(붉게) → 속마음 → [바친다]/[거스른다]
## 바친다: 창이 솟음 → 데스신 → 동료가 줄에서 빠짐 → 대사 → 상속 카드(같은 Lv) / 거스른다: 창이 부서짐 → 흉터 → 대사 → "운명이 미뤄졌다"
func field_fate(t: TopdownScene, fate_id: String, my: int) -> void:
	var f = Rules.fate_by_id(st, fate_id)
	if f == null or not f.alive or int(f.get("triedFloor", 0)) == Rules.floor_now(st):
		return
	var fid := t.follower_of_ally(str(f.who))
	if t.follower(fid).is_empty():
		return
	stage = "fate:" + fate_id
	note("fate trial field " + fate_id + " lv" + str(f.level))
	var L: Dictionary = G.S.fate[fate_id]
	await t.fate_trap(fid)
	if not _td_ok(t, my):
		return
	await t.say(L.trap2 if int(f.level) >= 2 and L.has("trap2") else L.trap)
	await G.guide.fire("fateFirst", {})
	var choice := await G.scenes.fate_choice(f)
	if not _td_ok(t, my):
		return
	var lv := int(f.level)
	if choice == "offer":
		await t.fate_spikes()
		var ev := Rules.offer_fate(st, fate_id)
		await G.scenes.cutscene(fate_id, lv)
		if not _td_ok(t, my):
			return
		t.remove_follower(fid)
		await G.scenes.close_cutscene(300)
		await t.fate_clear(true)
		await t.say(L.offered)
		var gain := []
		var relic_n := 0
		for e in ev:
			if e.t == "gainCard":
				gain.append(e.uid)
			if e.t == "relicize":
				relic_n = e.changes.size()
		var sub := G.ui("relic", {"name": G.name_of(str(f.who)), "n": relic_n}) if relic_n > 0 else ""
		await G.scenes.card_gain(gain, "inherit", "", sub)
		t.fate_trap_fade()
		# 상속 카드 안내(전투 중 바친 것과 같은 안내)
		await G.guide.fire("afterDeath", {"card": str(GameData.D.fates[fate_id].card)})
	else:
		var ev2 := Rules.defy_fate(st, fate_id)
		await t.fate_defy_fx()
		await t.fate_clear()
		var scars: Array = ev2[0].scars if not ev2.is_empty() else []
		await G.scenes.card_gain(scars, "scar")
		await t.say(L.defied)
		await G.scenes.card_gain([f.card], "note", str(G.S.fate.postponed))
		await G.guide.fire("scarFirst", {})
	stage = "td:" + t.map_id


# ───────── 전투 ─────────
## 반환: 이겼으면(또는 거대 존재가 물러나 끝났으면) true
func battle(enc: String, from_snapshot := false, my := -1) -> bool:
	if my < 0:
		flow += 1
		my = flow
	G.dialog.clear()
	G.scenes.clear()
	td = null
	G.input.cancel_drag()
	if from_snapshot and snaps.has(enc):
		st = Rules.restore(snaps[enc], st.rng)
	else:
		if st.is_empty():
			new_game()
		if st.battle != null:
			await G.view.play_events(Rules.finish_battle(st))
		Rules.start_battle(st, enc)
		snaps[enc] = Rules.snapshot(st)
	stage = "battle:" + enc
	result_ready = false
	busy = true
	G.view.build(st)
	in_battle = true
	note("battle " + enc + (" (restart)" if from_snapshot else ""))
	await FX.fade(0, 500)
	if not _alive(my):
		return false
	if from_snapshot and enc == "giant":
		await G.guide.fire("restart", {})
	await G.guide.fire("battleStart", {"enc": enc})
	if not _alive(my):
		return false
	# 손에 낼 수 있는 죽음 카드가 있으면 (2·3층) 그 안내, 두 장이면 두 장 안내
	var ndc := 0
	for u in st.battle.hand:
		if Rules.def(st, u).kind == "death" and not Rules.is_locked(st, u):
			ndc += 1
	if ndc > 0:
		await G.guide.fire("deathInHand", {"n": ndc})
	if ndc > 1:
		await G.guide.fire("twoDeathCards", {"n": ndc})
	if not _alive(my):
		return false
	await begin_turn()
	# 전투가 끝날 때까지 기다린다 (카드·턴 종료는 입력이 진행)
	while _alive(my) and in_battle and st.battle != null and st.battle.enc == enc and not result_ready:
		await get_tree().process_frame
	if not _alive(my) or st.battle == null or st.battle.enc != enc:
		return false
	return await after_result(my)


func begin_turn() -> void:
	_set_busy(true)
	var b: Dictionary = st.battle
	var ev := Rules.start_turn(st)
	await G.view.play_events(ev)
	G.guide.fire("turnStart", {"enc": b.enc, "turn": b.turn})
	for e in b.enemies:
		if e.alive and e.intent != null and e.intent.kind == "fate":
			G.guide.fire("fateIntent", {})
	_set_busy(false)


## 잠긴 죽음 카드를 끌거나 눌렀다 → 손패로 돌아가고 속마음 (대본 2장, 매번)
func locked_try(uid: String) -> void:
	note("locked " + str(st.cards[uid].id))
	G.view.render()
	G.dialog.drop_pending()
	G.dialog.say(G.S.lockedTry)


func play_card(uid: String, target := {}) -> Dictionary:
	if busy or st.is_empty() or st.battle == null or G.dialog.guide_open():
		G.input.cancel_drag()
		return {"ok": false, "reason": "busy"}
	var chk := Rules.can_play(st, uid)
	if not chk.ok:
		G.input.cancel_drag()
		if chk.get("locked", false):
			locked_try(uid)
		else:
			FX.toast(reason_text(chk.reason))
		return chk
	_set_busy(true)
	var id: String = st.cards[uid].id
	var res := Rules.play(st, uid, target)
	if not res.ok:
		FX.toast(reason_text(res.reason))
		G.input.cancel_drag()
		_set_busy(false)
		return res
	G.input.end_drag()
	note("play " + id + " " + str(target))
	await G.view.play_events(res.events)
	G.guide.fire("cardPlayed", {"enc": st.battle.enc if st.battle != null else "", "card": id})
	await _after_deaths(res.events)
	if st.battle != null and st.battle.result == null:
		_set_busy(false)
	elif st.battle != null:
		result_ready = true
	return res


## 죽음 카드로 동료가 죽었으면: 남은 동료의 반응(C8) → 사망 직후 안내
func _after_deaths(events: Array) -> void:
	for e in events:
		if e.t == "allyDeath":
			note("reactions " + str(e.ally))
			await G.view.reactions(str(e.ally))
			note("afterDeath")
			await G.guide.fire("afterDeath", {"card": str(e.get("card", ""))})
			note("afterDeath done")


func end_turn() -> void:
	if busy or st.is_empty() or st.battle == null or st.battle.phase != "player" or st.battle.result != null or G.dialog.guide_open():
		return
	_set_busy(true)
	G.input.cancel_drag()
	note("endTurn %d" % int(st.battle.turn))
	var my := flow
	var ev := Rules.end_turn(st)
	await G.view.play_events(ev)
	# 운명의 시도: 적의 행동이 운명이면 전투가 멈추고 고른다 → 남은 적 행동
	while _alive(my) and st.battle != null and st.battle.result == null and st.battle.awaitFate != null:
		await battle_fate(my)
	if not _alive(my):
		return
	if st.battle == null or st.battle.result != null:
		busy = true
		result_ready = true
		return
	await G.guide.fire("enemyPhaseEnd", {"enc": st.battle.enc})
	await begin_turn()


## 전투 중 운명의 시도 (3층 화형 사제 「운명의 불길 → 엘리안」)
func battle_fate(my: int) -> void:
	var af: Dictionary = st.battle.awaitFate
	var f = Rules.fate_by_id(st, str(af.fate))
	var L: Dictionary = G.S.fate.get(str(af.fate), {})
	note("fate trial battle " + str(af.fate) + " lv" + str(af.level))
	var prev_stage := stage
	stage = "fate:" + str(af.fate)
	await G.view.fate_freeze(str(af.who), true)
	await G.dialog.say(L.get("trap", []))
	await G.guide.fire("fateFirst", {})
	if not _alive(my):
		return
	var choice := await G.scenes.fate_choice(f)
	if not _alive(my):
		return
	var ev := Rules.fate_trial_choice(st, choice)
	if choice != "offer":
		await G.view.fate_freeze(str(af.who), false)
	await G.view.play_events(ev)
	if choice == "offer":
		await G.view.fate_freeze(str(af.who), false)
		await _after_deaths(ev)
		await G.dialog.say(L.get("offered", []))
	else:
		var scars: Array = []
		for e in ev:
			if e.t == "fateDefied":
				scars = e.scars
		await G.scenes.card_gain(scars, "scar")
		await G.dialog.say(L.get("defied", []))
		await G.guide.fire("scarFirst", {})
	stage = prev_stage
	if st.battle == null:
		return
	var ev3 := Rules.resume_enemy_phase(st)
	await G.view.play_events(ev3)


## 전투 결과 처리. 이겼으면(물러났으면) true
func after_result(my: int) -> bool:
	var b: Dictionary = st.battle
	match str(b.result):
		"giant":
			note("giant appears")
			return await battle("giant", false, my)
		"retreat":
			note("retreat → escape")
			return true
		"win":
			note("win " + str(b.enc))
			await G.guide.fire("battleWin", {"enc": b.enc})
			if not _alive(my):
				return false
			var ev := Rules.finish_battle(st)
			G.view.vm.enc = b.enc
			await G.view.play_events(ev)
			return true
		"lose":
			note("wipe " + str(b.kind))
			if b.kind == "giant":
				# 카드를 내지 않은 미래 (대본 5.7): 붉게 번진 화면이 유리처럼 깨지고 되돌아간다
				await G.scenes.rewind()
				if not _alive(my):
					return false
				in_battle = false
				return await battle("giant", true, my)
			await FX.fade(1, 600)
			G.dialog.clear()
			in_battle = false
			await G.scenes.wipe(str(b.kind))
			if not _alive(my):
				return false
			await FX.fade(1, 200)
			return await battle(str(b.enc), true, my)
	return false


# ───────── 시험용 바로 가기 ─────────
## scene: title | camp | cult | normal | fork | corpse | rest | train | stairs | deep | giant | emptycamp
##        | floor2 (2층 회랑) | ossuary | f2stairs | floor3 (3층, brun=alive|dead) | pyre | result | topdown (갈림길 탑뷰 시험판)
func jump(scene: String, opts := {}) -> void:
	flow += 1
	var my := flow
	G.dialog.clear()
	G.scenes.clear()
	G.view.clear()
	in_battle = false
	busy = false
	FX.set_fade(0)
	new_game()
	if opts.has("sera"):
		st.flags.sera = opts.sera
	var brun := str(opts.get("brun", G.params.get("brun", "alive")))
	match scene:
		"title":
			G.scenes.title()
		"camp":
			await start_tutorial()
		"cult", "fork", "deep", "emptycamp":
			if scene == "emptycamp":
				_tutorial_done_state(false)
			await run_from(scene, my)
		"normal":
			_visit("hall")
			if await battle("normal", false, my):
				await run_from("fork", my)
		"corpse", "rest", "train":
			st.flags.path = scene
			stage = "event:" + scene
			await G.scenes.vn(scene)
			if _alive(my):
				await G.scenes.vn("stairs")
			if _alive(my):
				await run_from("deep", my)
		"stairs":
			await G.scenes.vn("stairs")
			if _alive(my):
				await run_from("deep", my)
		"giant":
			if await battle("giant", false, my):
				await G.scenes.escape()
		"floor2", "ossuary", "f2stairs":
			st = Rules.state_after_tutorial(seed, str(opts.get("sera", "none")))
			await run_from({"floor2": "f2corridor", "ossuary": "f2ossuary", "f2stairs": "f2stairs"}[scene], my)
		"floor3", "pyre":
			st = Rules.state_floor3(seed, brun)
			await run_from("f3chapel" if scene == "floor3" else "f3pyre", my)
		"result":
			st = Rules.state_floor3(seed, brun)
			await run_from("result", my)
		"ending":
			await run_from("chapter1", my)
		"topdown":
			stage = "topdown"
			await G.scenes.topdown()


## 바로 가기용: 세라피나가 죽은 뒤(빈 캠프 직전) 상태 — 유품·짓밟힘
func _tutorial_done_state(with_fate: bool) -> void:
	var s := Rules.state_after_tutorial(seed, str(st.get("flags", {}).get("sera", "none")))
	if not with_fate:
		# 빈 캠프에서 운명이 들어오므로 지운다
		s.fates = []
		s.party.deathCards = []
		s.progress.floor = 1
	st = s
