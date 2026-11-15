## ctl.gd — 장면 흐름과 전투 진행 (HTML 판 controller.js + 탐색·이벤트·빈 캠프).
## 타이틀 → 캠프 → 1층 전투(광신도 3, 완전히 끝남) → 걸어 들어감 → 지도·갈림길 3택 → 이벤트 → 계단(세라피나와의 대화)
## → 이동 → 2층 전투(광신도 2 → 거대 존재 등장) → 거대 존재 전투 → (죽음 카드 → 컷신 → 짓밟힘 → 탈출 → 빈 캠프 → 종료)
## / (전멸 → "카드를 내지 않은 미래" → 등장 직후부터 재시작)
class_name Ctl
extends Node

var st := {}
var busy := false
var in_battle := false
var snaps := {}           # 전투 처음 상태 (재시작용) enc → 스냅샷
var seed = null
var flow := 0             # 흐름 번호: 장면을 건너뛰면(시험용 바로 가기) 이전 흐름은 멈춘다
var log: Array = []
var stage := ""           # 지금 단계 이름 (시험용)
var result_ready := false # 카드·턴 종료 연출이 끝나고 전투 결과를 처리할 차례


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
	new_game()
	stage = "camp"
	await G.scenes.camp()
	if not _alive(my):
		return
	await run_from("normal", my)


## 지정한 단계부터 끝까지 진행한다 (시험용 바로 가기도 이 함수를 쓴다)
func run_from(step: String, my: int) -> void:
	var steps := ["normal", "explore1", "fork", "event", "stairs", "explore2", "floor2"]
	var i := steps.find(step)
	if i < 0:
		return
	for k in range(i, steps.size()):
		if not _alive(my):
			return
		match steps[k]:
			"normal":
				var won := await battle("normal", false, my)
				if not won:
					return
			"explore1":
				await after_floor1(my)
			"fork":
				st.progress.room = "fork"
				_visit("fork")
				stage = "fork"
				var path: String = await G.scenes.explore("fork")
				if not _alive(my):
					return
				st.flags.path = path
			"event":
				var path2: String = st.flags.get("path", "corpse")
				st.progress.room = path2
				_visit(path2)
				stage = "event:" + path2
				await G.scenes.vn(path2)
			"stairs":
				st.progress.room = "stairs"
				_visit("stairs")
				stage = "stairs"
				await G.scenes.vn("stairs")
			"explore2":
				st.progress.floor = 2
				st.progress.room = "f2hall"
				_visit("f2hall")
				stage = "explore2"
				await G.scenes.explore("stairs")
			"floor2":
				await battle("floor2", false, my)
				return


func _visit(room: String) -> void:
	if not st.progress.visited.has(room):
		st.progress.visited.append(room)


## 1층 승리 → 전투 정리(쓰러진 동료 복귀·상처) → 1인칭으로 걸어 들어간다 → 지도 (대본 3.1)
func after_floor1(my: int) -> void:
	stage = "walk1"
	in_battle = false
	await FX.fade(1, 600)
	if not _alive(my):
		return
	G.dialog.clear()
	G.view.clear()
	st.progress.room = "hall"
	_visit("hall")
	await G.scenes.walk_in("hall")


# ───────── 전투 ─────────
## 반환: 이겼으면(1층) true. 2층·거대 존재는 끝까지 진행한다
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
	note("battle " + enc + (" (restart)" if from_snapshot else ""))
	await FX.fade(0, 500)
	if not _alive(my):
		return false
	if from_snapshot and enc == "giant":
		await G.guide.fire("restart", {})
	await G.guide.fire("battleStart", {"enc": enc})
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
	var died := false
	for e in res.events:
		if e.t == "allyDeath":
			died = true
	if died:
		note("reactions")
		await G.view.reactions()
		note("afterDeath")
		await G.guide.fire("afterDeath", {})
		note("afterDeath done")
	if st.battle != null and st.battle.result == null:
		_set_busy(false)
	elif st.battle != null:
		result_ready = true
	return res


func end_turn() -> void:
	if busy or st.is_empty() or st.battle == null or st.battle.phase != "player" or st.battle.result != null or G.dialog.guide_open():
		return
	_set_busy(true)
	G.input.cancel_drag()
	note("endTurn %d" % int(st.battle.turn))
	var ev := Rules.end_turn(st)
	await G.view.play_events(ev)
	if st.battle == null or st.battle.result != null:
		busy = true
		result_ready = true
		return
	await G.guide.fire("enemyPhaseEnd", {"enc": st.battle.enc})
	await begin_turn()


## 전투 결과 처리. 1층 승리면 true
func after_result(my: int) -> bool:
	var b: Dictionary = st.battle
	match str(b.result):
		"giant":
			note("giant appears")
			await battle("giant", false, my)
			return false
		"retreat":
			note("retreat → escape")
			await ending_flow(my)
			return false
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
				await battle("giant", true, my)
				return false
			await FX.fade(1, 600)
			G.dialog.clear()
			in_battle = false
			await G.scenes.wipe(str(b.kind))
			if not _alive(my):
				return false
			await FX.fade(1, 200)
			return await battle(str(b.enc), true, my)
	return false


## 짓밟힘 → 존재가 물러남 → 탈출 → 빈 캠프 → 종료
func ending_flow(my: int) -> void:
	stage = "escape"
	await G.dialog.say(G.S.escape.lines)
	if not _alive(my):
		return
	await G.scenes.escape()
	if not _alive(my):
		return
	in_battle = false
	G.view.clear()
	stage = "emptycamp"
	await G.scenes.vn("emptycamp")
	if not _alive(my):
		return
	stage = "ending"
	G.scenes.ending()


# ───────── 시험용 바로 가기 ─────────
## scene: title | camp | normal | fork | corpse | rest | train | stairs | explore2 | floor2 | giant | cutscene | emptycamp | ending
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
	match scene:
		"title":
			G.scenes.title()
		"camp":
			await start_tutorial()
		"normal", "fork", "stairs", "explore2", "floor2":
			await run_from(scene, my)
		"corpse", "rest", "train":
			st.flags.path = scene
			await run_from("event", my)
		"giant":
			await battle("giant", false, my)
		"emptycamp":
			st.party.allies.hero.status = "dead"
			await G.scenes.vn("emptycamp")
			if _alive(my):
				G.scenes.ending()
		"ending":
			G.scenes.ending()
