## ctl.gd — 장면 흐름과 전투 진행 (버티컬 슬라이스: 배경 위 비주얼노벨 장면 + 지도 거점 + 1인칭 카드 전투 + 운명).
## 1층(튜토리얼, 대본 v3 — 장례 탑 1층): 곁방(캠프) → 장례 회랑(VN → 전투 ①) → 안치 홀(VN → 지도·촛불 안내)
##   → 지도: 골라 들어가는 방 8개(전투·강적·사건·휴식·훈련·거래·전조) · 계단 앞 홀 → 가장 깊은 곳(광신도 → 거대한 발 →
##   3턴 「짓밟기」: 뒤집힌 카드가 뒤집힘 → 데스신 → 사망 직후 안내) → 빈 캠프(다음 죽음: 브룬힐드) → 1층 끝
## 2층: 창 함정 회랑(VN·전조) → 기사단 납골당(VN → 창 기사 전투, 운명의 시도: 받아들인다/거스른다) → 계단(Lv업·새 운명: 엘리안)
## 3층: 불탄 예배당 회랑(VN·전조) → 화형대 광장(VN → 화형 사제 전투) → 결과 요약
## 전멸: 어느 전투든 전멸 화면 → 그 전투 처음부터 (튜토리얼의 "카드를 내지 않은 미래" 되감기는 없앴다 — 2026-11-21)
## 자동 저장(core/save_game.gd): 흐름의 단계(곁방·장례 회랑·안치 홀·빈 곁방·1층 끝·2·3층 장면)와 지도의 방에 들어갈 때.
##   이어하기는 마지막으로 들어간 곳의 처음부터. 결과 요약(시험판 끝)에 닿으면 저장을 지운다. --nosave(?nosave=1)면 쓰지도 읽지도 않는다
class_name Ctl
extends Node

const STEPS := ["camp", "corridor", "hall", "map", "emptycamp", "chapter1", "f2corridor", "f2ossuary", "f2stairs", "f3chapel", "f3pyre", "result"]

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
		if s == "result":
			clear_save()
		elif s != "map":
			autosave(s)   # 지도는 방마다(_step_map)
		var ok := false
		match s:
			"camp": ok = await _step_camp(my)
			"corridor": ok = await _step_corridor(my)
			"hall": ok = await _step_hall(my)
			"map": ok = await _step_map(my)
			"emptycamp": ok = await _step_vn("emptycamp", my)
			"chapter1": ok = await _step_chapter1(my)
			"f2corridor": ok = await _step_vn("f2corridor", my)
			"f2ossuary": ok = await _step_vn_battle("f2ossuary", "ossuary", my)
			"f2stairs": ok = await _step_f2stairs(my)
			"f3chapel": ok = await _step_vn("f3chapel", my)
			"f3pyre": ok = await _step_vn_battle("f3pyre", "pyre", my)
			"result": ok = await _step_result(my)
		if not ok or not _alive(my):
			return


## 2·3층처럼 지도가 없는 곳: 지나온 곳만 기록 (결과 요약·시험용)
func _visit(room: String) -> void:
	st.progress.room = room
	if not st.progress.visited.has(room):
		st.progress.visited.append(room)


# ───────── 1층 (대본 v3) ─────────
func _step_camp(my: int) -> bool:
	stage = "vn:camp"
	await G.scenes.vn("camp")
	return _alive(my)


## 1. 장례 회랑 — VN → 같은 배경에서 전투 ① (정해진 길, 촛불은 타지 않는다)
func _step_corridor(my: int) -> bool:
	Rules.enter_room(st, "corridor")
	return await _room("corridor", my)


## 2. 안치 홀 — VN 뒤 지도가 열린다 (지도·촛불 안내는 _step_map 의 처음에)
func _step_hall(my: int) -> bool:
	Rules.enter_room(st, "hall")
	stage = "vn:hall"
	await G.scenes.vn("hall")
	return _alive(my)


## 지도 거점: 방을 골라 들어간다 → 방 → 다시 지도. 층의 끝 방(가장 깊은 곳)을 마치면 끝
func _step_map(my: int) -> bool:
	while _alive(my):
		var fm := FloorMap.new()
		fm.setup(st)
		G.view.clear()
		in_battle = false
		G.scenes.mount(fm, "map")
		stage = "map"
		await FX.fade(0, 400)
		if not _alive(my) or not is_instance_valid(fm):
			return false
		if not bool(st.flags.get("mapSeen", false)):
			st.flags.mapSeen = true
			await fm.intro()
			if not _alive(my) or not is_instance_valid(fm):
				return false
		var id := await fm.run()
		if not _alive(my):
			return false
		var r := Rules.enter_room(st, id)
		if not r.ok:
			continue
		autosave("map", id)
		note("enter %s burned=%s dark=%d candles=%d darkness=%d" % [id, r.burned, int(r.dark), int(r.candles), int(r.darkness)])
		# 촛불이 타는 것(또는 어둠이 깊어지는 것)을 지도 위에서 보여 준다
		if is_instance_valid(fm):
			fm.sel = ""
			fm._refresh()
		if r.burned:
			FX.toast(str(G.S.map.burned).replace("{n}", str(r.candles)), 1400)
		elif int(r.dark) > 0:
			FX.toast(str(G.S.map.darker).replace("{n}", str(r.darkness)), 1600)
		await FX.wait(650)
		await FX.fade(1, 400)
		if not _alive(my):
			return false
		if not await _room(id, my):
			return false
		if bool(Rules.room_def(st, id).get("end", false)):
			return true
	return false


## 방 하나: VN 장면(대사·사건·휴식·훈련·거래·전조는 VN 안의 call) → 전투가 있으면 같은 배경에서 전투
## → 강적이면 이기고 카드 1장을 얻는다(winCard). 전투 승리 뒤 '카드 3장 중 1장' 보상 화면은 2026-11-21 사용자 지시로 뺐다
func _room(id: String, my: int) -> bool:
	var R := Rules.room_def(st, id)
	stage = "room:" + id
	note("room " + id)
	if G.S.events.has(id):
		stage = "vn:" + id
		await G.scenes.vn(id)
		if not _alive(my):
			return false
	if id == str(Rules.map_def(st).get("end", "deep")):
		return await _deep(my)
	if R.has("enc"):
		var won := await battle(str(R.enc), false, my)
		if not won or not _alive(my):
			return false
		if R.has("winCard"):
			await _win_card(str(R.winCard), my)
		await _leave_battle()
	return _alive(my)


## 강적을 이기면 [기본안 2026-11-21]: 고르는 화면 없이 목록(rewards.<pool>)의 카드 1장이 강화된 채 바로 덱에 들어온다.
## 순장된 자의 방·핏자국 통로 끝처럼 '얻는' 연출(카드 획득 화면 + 「○○ — 덱에 들어왔다」)
func _win_card(pool: String, my: int) -> void:
	var u := Rules.win_card(st, pool)
	if u == "" or not _alive(my):
		return
	var id: String = st.cards[u].id
	var up := Rules.is_up(st, u)
	stage = "winCard:" + pool
	note("win card " + id + (" up" if up else ""))
	await G.scenes.card_gain([u], "inherit", G.ui("gainCard", {"card": Rules.card_name(id, up)}))


func _leave_battle() -> void:
	await FX.fade(1, 500)
	if st.battle != null:
		Rules.finish_battle(st)
	in_battle = false
	G.view.clear()
	G.scenes.clear()


## 5. 가장 깊은 곳 (층 끝): 광신도 전투 → 1명 남으면 발이 내려옴 → 거대한 발 보스 전투 → 세라피나의 운명 → 물러남
func _deep(my: int) -> bool:
	var ok := await battle("deep", false, my)
	if not ok or not _alive(my):
		return false
	await FX.fade(1, 900)
	if st.battle != null:
		Rules.finish_battle(st)
	in_battle = false
	G.view.clear()
	return _alive(my)


## VN 장면 하나 (빈 캠프·2·3층 장면)
func _step_vn(name: String, my: int) -> bool:
	_visit(name)
	stage = "vn:" + name
	await G.scenes.vn(name)
	return _alive(my)


## VN 장면 → 같은 배경에서 전투 (2층 납골당·3층 화형대)
func _step_vn_battle(name: String, enc: String, my: int) -> bool:
	if not await _step_vn(name, my):
		return false
	var won := await battle(enc, false, my)
	if not won or not _alive(my):
		return false
	await _leave_battle()
	return _alive(my)


func _step_chapter1(my: int) -> bool:
	await G.scenes.chapter(G.S.chapter1)
	if not _alive(my):
		return false
	descend_events = Rules.descend(st)
	return true


func _step_f2stairs(my: int) -> bool:
	st.flags.brun = "dead" if st.party.allies.warrior.status == "dead" else "alive"
	return await _step_vn("f2stairs", my)   # 살아서 내려간 운명 Lv2 · 새 운명(엘리안 화형 Lv1) · 3층


func _step_result(my: int) -> bool:
	_visit("f3stairs")
	await FX.fade(1, 500)
	G.scenes.result()
	return _alive(my)


# ───────── 전투 ─────────
## 반환: 이겼으면(또는 거대한 발 앞에서 물러나 끝났으면) true
func battle(enc: String, from_snapshot := false, my := -1) -> bool:
	if my < 0:
		flow += 1
		my = flow
	G.dialog.clear()
	G.scenes.clear()
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
	note("battle " + enc + (" (restart)" if from_snapshot else "") + (" darkness=%d" % int(st.battle.darkness) if int(st.battle.darkness) > 0 else ""))
	await FX.fade(0, 500)
	if not _alive(my):
		return false
	await G.guide.fire("battleStart", {"enc": enc})
	if not _alive(my):
		return false
	# 손에 든 (앞면) 죽음 카드: 낼 수 없는 '미리 보는' 카드라는 안내, 두 장이면 두 장 안내 (2·3층). 뒤집힌 카드는 1턴 안내가 맡는다
	var ndc := 0
	for u in st.battle.hand:
		if Rules.def(st, u).kind == "death" and not Rules.is_face_down(st, u):
			ndc += 1
	if ndc > 0:
		await G.guide.fire("deathInHand", {"n": ndc})
	if ndc > 1:
		await G.guide.fire("twoDeathCards", {"n": ndc})
	if int(st.battle.darkness) > 0:
		await G.guide.fire("darkness", {"enc": enc})
	if not _alive(my):
		return false
	await begin_turn()
	# 전투가 끝날 때까지 기다린다 (카드·턴 종료는 입력이 진행). 프레임은 G(자동 로드)에서 기다린다 —
	# 타이틀로 돌아가며 이 노드가 트리에서 빠진 프레임에 get_tree() 가 null 이 되어 같은 프레임 안에서 끝없이 돌지 않게
	while _alive(my) and in_battle and st.battle != null and st.battle.enc == enc and not result_ready:
		await G.get_tree().process_frame
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


func play_card(uid: String, target := {}) -> Dictionary:
	if busy or st.is_empty() or st.battle == null or G.dialog.guide_open():
		G.input.cancel_drag()
		return {"ok": false, "reason": "busy"}
	var chk := Rules.can_play(st, uid)
	if not chk.ok:
		G.input.cancel_drag()
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
	var my := flow
	await G.view.play_events(res.events)
	G.guide.fire("cardPlayed", {"enc": st.battle.enc if st.battle != null else "", "card": id})
	# 운명을 집행할 적을 먼저 쓰러뜨렸다: 쓰러지는 그 순간 운명의 시도가 온다
	while _alive(my) and st.battle != null and st.battle.result == null and st.battle.awaitFate != null:
		await battle_fate(my)
	if not _alive(my):
		return res
	if st.battle != null and st.battle.result == null:
		_set_busy(false)
	elif st.battle != null:
		result_ready = true
	return res


## 운명의 죽음이 일어난 뒤: 남은 동료의 반응(C8) → 사망 직후 안내
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


## 전투 중 운명의 시도. 운명의 시도는 전투 안에서만 온다(2026-11-18). 집행자가 먼저 쓰러졌으면(byDeath) 그 순간에 온다
##  · 거스를 수 없는 운명(튜토리얼의 세라피나, 대본 v3 5.2~5.4): 화면이 멈춘다 → 손패의 뒤집힌 카드가 저절로 뒤집힌다 → "알고 있었는데."
##    → 데스신 → 노엘의 손에 남은 카드(이제야 문구가 보인다) → 죽음 카드·상속·유품 안내 → 동료 반응 → 물러남(전투 끝)
##  · 그 밖(2·3층): 받아들인다(죽음이 일어남: 상속 + 유품) / 거스른다(산다: 흉터 — 붉은 실은 나중)
func battle_fate(my: int) -> void:
	var af: Dictionary = st.battle.awaitFate
	var f = Rules.fate_by_id(st, str(af.fate))
	var L: Dictionary = G.S.fate.get(str(af.fate), {})
	note("fate trial battle " + str(af.fate) + " lv" + str(af.level) + (" byDeath" if af.get("byDeath", false) else ""))
	var prev_stage := stage
	stage = "fate:" + str(af.fate)
	if not Rules.can_defy(str(af.fate)):
		await _fate_tutorial(af, f, L, my)
		stage = prev_stage
		return
	await G.view.fate_freeze(str(af.who), true)
	if af.get("byDeath", false):
		await G.dialog.say(G.S.fate.dying)
	await G.dialog.say(L.trap2 if int(af.level) >= 2 and L.has("trap2") else L.get("trap", []))
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


func _fate_tutorial(af: Dictionary, f, L: Dictionary, my: int) -> void:
	var who := str(af.who)
	var uid: String = str(f.card) if f != null else ""
	await G.view.fate_freeze(who, true)
	# 손패 맨 오른쪽의 뒤집힌 카드가 저절로 뒤집힌다 — 세라피나의 얼굴
	await G.view.play_events(Rules.flip_card(st, uid))
	await G.dialog.say(L.get("trap", []))   # 속마음: 알고 있었는데. (안내 상자는 띄우지 않는다)
	if not _alive(my):
		return
	note("fate accept (no choice) " + str(af.fate))
	var ev := Rules.fate_trial_choice(st, "offer")
	await G.view.play_events(ev)   # 카드가 들려 실이 팽팽 → 데스신 → 유품 → 「짓밟힘」
	await G.view.fate_freeze(who, false)
	if not _alive(my):
		return
	# 5.4 노엘의 손에 남은 카드. 이제야 문구가 보인다
	if st.cards.has(uid):
		var cid: String = st.cards[uid].id
		var cap := str(G.S.deathCardShown).replace("{card}", Rules.card_name(cid)).replace("{text}", Rules.card_text(cid))
		await G.scenes.card_gain([uid], "note", cap)
		await G.guide.fire("afterDeath", {"card": cid})
	if not _alive(my):
		return
	await G.view.reactions(who)
	await G.view.play_events(Rules.fate_end_battle(st, str(af.fate)))


## 전투 결과 처리. 이겼으면(물러났으면) true
func after_result(my: int) -> bool:
	var b: Dictionary = st.battle
	note("battle end " + _battle_summary())
	match str(b.result):
		"giant":
			note("giant appears")
			return await battle("giant", false, my)
		"retreat":
			note("retreat")
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
			note("wipe " + str(b.enc))
			await FX.fade(1, 600)
			G.dialog.clear()
			in_battle = false
			await G.scenes.wipe(str(b.kind))
			if not _alive(my):
				return false
			await FX.fade(1, 200)
			return await battle(str(b.enc), true, my)
	return false


## 전투가 끝난 순간의 요약(--trace 기록용, 난이도 보고서 tools/batch_autoplay.py 가 읽는다): 전투·결과·턴·덱 장수·노엘과 동료 HP·상태
func _battle_summary() -> String:
	var b: Dictionary = st.battle
	var s := "enc=%s result=%s turn=%d deck=%d witch=%d/%d" % [b.enc, str(b.result), int(b.turn), st.party.deck.size(),
		int(st.party.witch.hp), int(st.party.witch.maxHp)]
	for id in st.party.order:
		var a: Dictionary = st.party.allies[id]
		s += " %s=%d/%d:%s" % [id, int(a.hp), int(a.maxHp), str(a.status)]
	return s


## 지도의 방 하나를 마치고 지도로 (층의 끝 방이면 빈 곁방으로)
func _room_then_map(room: String, my: int) -> void:
	if await _room(room, my) and _alive(my):
		if bool(Rules.room_def(st, room).get("end", false)):
			await run_from("emptycamp", my)
		else:
			await run_from("map", my)


# ───────── 자동 저장 · 이어하기 ─────────
func saving() -> bool:
	return not G.params.has("nosave")


## 지금 상태를 저장한다. step: STEPS 의 단계 이름(지도의 방이면 "map" + room)
func autosave(step: String, room := "") -> void:
	if not saving() or st.is_empty():
		return
	var ok := SaveGame.write_text(SaveGame.pack(st, step, room, G.guide.done))
	note("save %s%s%s" % [step, (" " + room) if room != "" else "", "" if ok else " (실패)"])


func clear_save() -> void:
	if saving():
		SaveGame.clear()
		note("save cleared")


## 이어 할 저장 ({} = 없음)
func load_save() -> Dictionary:
	return SaveGame.read() if saving() else {}


## 이어하기: 저장한 방·장면의 처음부터. 지도의 방이면 그 방(촛불은 이미 탄 상태) → 지도
func continue_game() -> bool:
	var sv := load_save()
	if sv.is_empty():
		return false
	flow += 1
	var my := flow
	note("continue %s %s" % [sv.step, sv.room])
	await FX.fade(1, 300)
	if not _alive(my):
		return true
	G.dialog.clear()
	G.scenes.clear()
	G.view.clear()
	G.input.cancel_drag()
	in_battle = false
	busy = false
	snaps = {}
	st = sv.st
	G.guide.reset()
	G.guide.done = sv.guide.duplicate()
	if sv.step == "map":
		await _room_then_map(str(sv.room), my)
	else:
		await run_from(str(sv.step), my)
	return true


# ───────── 시험용 바로 가기 ─────────
## scene: title | camp | corridor(=normal) | hall | map | room:<방 id>(또는 방 id: prayer · gravekeeper · buried · corpse · chapel · training · stall
##        · footprints · stairs · deep) | giant | emptycamp | floor2 | ossuary | f2stairs | floor3 (brun=alive|dead) | pyre | result
func jump(scene: String, opts := {}) -> void:
	if G.menu != null:
		G.menu.resume()   # 시험 훅이 일시정지·설정이 열린 채 부르더라도 막히지 않게
	flow += 1
	var my := flow
	G.dialog.clear()
	G.scenes.clear()
	G.view.clear()
	in_battle = false
	busy = false
	FX.set_fade(0)
	new_game()
	var brun := str(opts.get("brun", G.params.get("brun", "alive")))
	var room := scene.trim_prefix("room:")
	if room != scene or (Rules.room_def(st, room).size() > 0 and not room in ["camp", "corridor", "hall"]):
		# 지도의 방 하나부터: 그 방까지 지나온 상태(안치 홀까지 + 필요하면 기도실·계단 앞 홀)로 만들고, 그 방 → 지도로
		_prep_map(room)
		Rules.enter_room(st, room)
		autosave("map", room)
		await _room_then_map(room, my)
		return
	match scene:
		"title":
			G.scenes.title()
		"camp":
			await start_tutorial()
		"corridor", "normal":
			await run_from("corridor", my)
		"hall":
			Rules.enter_room(st, "corridor")
			await run_from("hall", my)
		"map":
			_prep_map("")
			await run_from("map", my)
		"giant":
			_prep_map("deep")
			Rules.enter_room(st, "deep")
			if await battle("giant", false, my) and _alive(my):
				await FX.fade(1, 600)
				if st.battle != null:
					Rules.finish_battle(st)
				in_battle = false
				G.view.clear()
				await run_from("emptycamp", my)
		"emptycamp":
			_tutorial_done_state()
			await run_from("emptycamp", my)
		"floor2", "ossuary", "f2stairs":
			st = Rules.state_after_tutorial(seed)
			await run_from({"floor2": "f2corridor", "ossuary": "f2ossuary", "f2stairs": "f2stairs"}[scene], my)
		"floor3", "pyre":
			st = Rules.state_floor3(seed, brun)
			await run_from("f3chapel" if scene == "floor3" else "f3pyre", my)
		"result":
			st = Rules.state_floor3(seed, brun)
			await run_from("result", my)


## 바로 가기용: 지도를 그 방 앞까지 지나온 상태로 (지도 안내는 본 것으로)
func _prep_map(room: String) -> void:
	for r in ["corridor", "hall"]:
		Rules.enter_room(st, r)
	st.flags.mapSeen = true
	var need := []
	if room == "gravekeeper":
		need = ["prayer"]
	elif room in ["chapel", "training", "footprints", "deep"]:
		need = ["stairs"]
	for r in need:
		Rules.enter_room(st, r)
	# 시험용: ?darkness=N (이 층의 어둠 단계) · ?omen=1 (전조를 본 상태)
	if G.params.has("darkness"):
		st.progress.darkness = int(G.params.darkness)
	if G.params.has("omen"):
		st.progress.omen = true
	# 시험용: ?hp=warrior:3,archer:4 (노엘 witch·동료 HP) — CI 헤드리스 경로 6(거대한 발 끝없는 전멸 되풀이 막힘 재현)
	if G.params.has("hp"):
		for kv in str(G.params.hp).split(",", false):
			var p := kv.split(":")
			if p.size() == 2:
				Rules.debug_set_hp(st, p[0], int(p[1]))


## 바로 가기용: 세라피나가 죽은 뒤(빈 캠프 직전) 상태 — 유품·짓밟힘. 빈 캠프에서 브룬힐드의 운명이 들어온다
func _tutorial_done_state() -> void:
	var s := Rules.state_after_tutorial(seed)
	s.fates = s.fates.filter(func(f): return f.id == "hero_stomp")
	s.party.deathCards = []
	s.progress.floor = 1
	st = s
