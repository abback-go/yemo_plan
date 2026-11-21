## autoplay.gd — 자동 진행(시험용, ?autoplay=1 또는 -- --autoplay). 사람이 하듯 카드를 낸다.
##  · 낼 수 있는 카드를 앞에서부터 (공격은 첫 적, 피해 옮기기·예고 지우기는 첫 예고, 동료 회복은 HP 가 가장 낮은 동료), 없으면 턴 종료
##  · 죽음 카드는 낼 수 없다(2026-11-21). 거대한 발 전투도 카드를 내며 버티면 3턴 「짓밟기」에서 운명이 온다
##  · 노엘 HP 가 낮으면(8 이하) 노엘 HP 를 쓰는 카드(유품·이름 없는 마녀의 카드)는 아낀다
## 지도·선택지·카드 고르기·운명 선택은 각 화면이 --autoguide 일 때 스스로 고른다(--rooms · --choice · --reward · --train · --fates)
class_name AutoPlay
extends Node

var t := 0.0


func _process(delta: float) -> void:
	t += delta * FX.speed
	if t < 0.35:
		return
	t = 0.0
	var c := G.ctl
	if G.dialog.guide_open():
		G.dialog.advance()
		return
	if not c.in_battle or c.busy or c.st.is_empty() or c.st.battle == null:
		return
	var st: Dictionary = c.st
	var b: Dictionary = st.battle
	if b.phase != "player" or b.result != null or G.scenes.is_open() or G.scenes.overlay_open():
		return
	for u in b.hand:
		if not Rules.can_play(st, u).ok:
			continue
		var d := Rules.def(st, u)
		if _self_cost(st, u) > 0 and int(st.party.witch.hp) <= 8:
			continue   # 노엘 HP 가 낮으면 HP 를 쓰는 카드는 아낀다
		if d.target == "none":
			c.play_card(u, {})
			return
		var vt := Rules.valid_targets(st, u)
		if vt.is_empty():
			continue
		if d.target == "ally":
			var best := ""
			var bk := 2.0
			for id in vt:
				var a: Dictionary = st.party.allies[id]
				var k := float(a.hp) / maxf(1.0, float(a.maxHp))
				if k < bk:
					bk = k
					best = id
			if bk >= 1.0:
				continue   # 다친 동료가 없으면 아낀다
			c.play_card(u, {"ally": best})
			return
		var target := {"enemy": vt[0]}
		if Rules.needs_second_target(st, u):
			var ch := Rules.redirect_choices(st, vt[0])
			target.to = "warrior" if ch.has("warrior") else ch[0]
		c.play_card(u, target)
		return
	c.end_turn()


## 그 카드가 노엘 HP 를 얼마나 쓰는가 (selfDamage 효과)
func _self_cost(st: Dictionary, u: String) -> int:
	var n := 0
	for e in Rules.effects_of(st, u):
		if e.type == "selfDamage":
			n += int(e.amount)
		if e.type == "redirect" and str(e.get("to", "")) == "witch":
			n += 1   # 「대신 받기」: 노엘이 맞는다
	return n
