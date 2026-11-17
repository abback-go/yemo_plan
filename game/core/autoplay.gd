## autoplay.gd — 자동 진행(시험용, ?autoplay=1 또는 -- --autoplay). 사람이 하듯 카드를 낸다.
##  · 거대 존재 전투: autoplay=wipe 이면 카드를 내지 않고 3턴을 버텨 전멸(→ 재시작 경로), 아니면 2턴에 죽음 카드 → 짓밟힘
##  · 그 밖: 낼 수 있는 카드를 앞에서부터 (공격은 첫 적, 피해 옮기기는 엘리안을 노리는 예고), 없으면 턴 종료
##  · 1층에서는 한 번 잠긴 죽음 카드를 내려다 실패한다(대본 2장의 반응 확인)
class_name AutoPlay
extends Node

var t := 0.0
var tried_locked := false


func _process(delta: float) -> void:
	t += delta * FX.speed
	if t < 0.35:
		return
	t = 0.0
	var c := G.ctl
	if G.dialog.guide_open():
		G.dialog.advance()
		return
	_walk()
	if not c.in_battle or c.busy or c.st.is_empty() or c.st.battle == null:
		return
	var st: Dictionary = c.st
	var b: Dictionary = st.battle
	if b.phase != "player" or b.result != null or G.scenes.is_open():
		return
	var mode := str(G.params.get("autoplay", ""))
	# 잠긴 죽음 카드를 한 번 내려다 실패
	if not tried_locked:
		for u in b.hand:
			if Rules.is_locked(st, u):
				tried_locked = true
				c.locked_try(u)
				return
	if b.kind == "giant":
		if mode == "wipe" and not c.log.has("rewind"):
			c.end_turn()
			return
		for u in b.hand:
			var id: String = st.cards[u].id
			if (id == "hero_death" or id == "trample") and Rules.can_play(st, u).ok:
				c.play_card(u, {})
				return
		c.end_turn()
		return
	for u in b.hand:
		if not Rules.can_play(st, u).ok:
			continue
		var d := Rules.def(st, u)
		if d.kind == "death":
			continue
		if d.kind == "relic" and int(st.party.witch.hp) <= 8:
			continue   # 노엘 HP 가 낮으면 유품(HP 소모)은 아낀다
		if d.target == "none":
			c.play_card(u, {})
			return
		var vt := Rules.valid_targets(st, u)
		if vt.is_empty():
			continue
		var target := {"enemy": vt[0]}
		if Rules.needs_second_target(st, u):
			var ch := Rules.redirect_choices(st, vt[0])
			target.to = "warrior" if ch.has("warrior") else ch[0]
		c.play_card(u, target)
		return
	c.end_turn()


## 탑뷰 자동 걷기: 켜진 트리거가 있으면 그 안으로, 없으면 열린 출구로 (갈림길은 --path 의 출구)
var _walk_wait := 0.0
func _walk() -> void:
	var td = G.scenes.current
	if not (td is TopdownScene) or td.mode != "free" or G.dialog.is_busy() or td.vn != null:
		return
	if td.moving or td.path.size() > 0:
		return
	_walk_wait += 0.35
	if _walk_wait < 0.7:
		return
	_walk_wait = 0.0
	if td.exit_sel != "" and not td.locked_exits.has(td.exit_sel):
		td.confirm()
		return
	if not td.armed.is_empty():
		td.auto_trigger(str(td.armed[0]))
		return
	var want := str(G.params.get("path", "rest")) if td.map_id == "fork" else ""
	for e in td.C.get("exits", []):
		if td.locked_exits.has(e.id):
			continue
		if want != "" and e.id != want:
			continue
		td.auto_exit(str(e.id))
		return
