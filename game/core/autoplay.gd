## autoplay.gd — 자동 진행(시험용, ?autoplay=1 또는 -- --autoplay). 사람이 하듯 카드를 낸다.
##  · 낼 수 있는 카드를 앞에서부터 (공격은 첫 적, 피해 옮기기·예고 지우기는 첫 예고, 동료 회복은 HP 가 가장 낮은 동료), 없으면 턴 종료
##  · 「운명 전가」로 옮길 곳은 브룬힐드, 없으면 HP 가 가장 높은 동료 — 노엘에게는 옮기지 않는다(2026-11-22 고침: 예전에는 브룬힐드가 맞을
##    공격을 노엘에게 옮겨 노엘이 쓰러져 전멸하곤 했다 — docs/balance-report.md). 옮길 동료가 없으면 그 카드는 아낀다
##  · 죽음 카드는 낼 수 없다(2026-11-21). 거대한 발 전투도 카드를 내며 버티면 3턴 「짓밟기」에서 운명이 온다
##  · 노엘 HP 가 낮으면(8 이하) 노엘 HP 를 쓰는 카드(유품·이름 없는 마녀의 카드)는 아낀다
##  · --ai=careful(?ai=careful): 난이도 비교용으로 조금 생각하는 방식 — 낼 수 있는 카드·대상마다 규칙을 복사본에 적용하고 이번 적 차례까지
##    미리 돌려 본 뒤 가장 나은 것을 낸다(나아지는 것이 없으면 턴 종료). 어둠에 가려진 예고('?')는 모르는 것으로 친다. CI 는 기본 방식
## 지도·선택지·카드 고르기(좌판·훈련)·운명 선택은 각 화면이 --autoguide 일 때 스스로 고른다(--rooms · --choice · --reward(좌판) · --train · --fates)
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
	if str(G.params.get("ai", "")) == "careful":
		var pick := _careful(st)
		if pick.is_empty():
			c.end_turn()
		else:
			c.play_card(pick.uid, pick.target)
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
			var to := _shift_to(st, Rules.redirect_choices(st, vt[0]))
			if to == "":
				continue   # 노엘 말고 옮길 동료가 없다
			target.to = to
		c.play_card(u, target)
		return
	c.end_turn()


## 「운명 전가」로 옮길 곳: 브룬힐드, 없으면 HP 가 가장 높은 동료. 노엘은 고르지 않는다("" = 없음)
func _shift_to(st: Dictionary, ch: Array) -> String:
	if ch.has("warrior"):
		return "warrior"
	var best := ""
	var bh := -1
	for id in ch:
		if id != "witch" and int(st.party.allies[id].hp) > bh:
			bh = int(st.party.allies[id].hp)
			best = id
	return best


## 그 카드가 노엘 HP 를 얼마나 쓰는가 (selfDamage 효과)
func _self_cost(st: Dictionary, u: String) -> int:
	var n := 0
	for e in Rules.effects_of(st, u):
		if e.type == "selfDamage":
			n += int(e.amount)
		if e.type == "redirect" and str(e.get("to", "")) == "witch":
			n += 1   # 「대신 받기」: 노엘이 맞는다
	return n


# ───────── --ai=careful: 한 수 앞을 돌려 보고 고르기 ─────────
## 반환: {uid, target} 또는 {}(턴 종료)
func _careful(st: Dictionary) -> Dictionary:
	var base := _score_after(st, "", {})
	var best := {}
	var bs := base + 0.01
	for u in st.battle.hand:
		if not Rules.can_play(st, u).ok:
			continue
		for tg in _targets(st, u):
			var s := _score_after(st, u, tg)
			if _draws(st, u):
				s += 3.0   # 뽑기는 결과에 바로 안 보이지만 먼저 내는 것이 낫다
			if s > bs:
				bs = s
				best = {"uid": u, "target": tg}
	return best


func _targets(st: Dictionary, u: String) -> Array:
	var d := Rules.def(st, u)
	if d.target == "none":
		return [{}]
	var out := []
	for id in Rules.valid_targets(st, u):
		if d.target == "ally":
			out.append({"ally": id})
		elif Rules.needs_second_target(st, u):
			for to in Rules.redirect_choices(st, id):
				out.append({"enemy": id, "to": to})
		else:
			out.append({"enemy": id})
	return out


func _draws(st: Dictionary, u: String) -> bool:
	for e in Rules.effects_of(st, u):
		if e.type == "draw":
			return true
	return false


## 복사본에서 (그 카드를 내고) 턴을 끝내 적 차례까지 돌린 뒤의 점수. 진짜 상태(난수 포함)는 건드리지 않는다
func _score_after(st: Dictionary, u: String, tg: Dictionary) -> float:
	var s: Dictionary = st.duplicate(true)
	for e in s.battle.enemies:
		if e.intent != null and e.intent.get("hidden", false):
			e.intent.blocked = true   # 가려진 예고는 누구를 얼마나 칠지 모른다 — 계산에서 뺀다
	if u != "":
		if not Rules.play(s, u, tg).ok:
			return -1.0e9
	if s.battle != null and s.battle.result == null and s.battle.awaitFate == null:
		Rules.end_turn(s)
	return _score(s)


## 점수: 노엘 HP 가 가장 귀하다(회복이 거의 없고 0 이면 전멸). 동료가 쓰러지면 상처 카드가 덱에 남는다. 적 HP 는 적을수록 좋다
func _score(s: Dictionary) -> float:
	var b = s.battle
	if Rules.is_defeat(s) or (b != null and str(b.result) == "lose"):
		return -10000.0
	var v := 4.0 * float(s.party.witch.hp)
	for id in s.party.order:
		var a: Dictionary = s.party.allies[id]
		if a.status == "ok":
			v += float(a.hp) + 10.0
		elif a.status == "down":
			v -= 25.0
	if b != null:
		if str(b.result) in ["win", "giant", "retreat"]:
			v += 200.0
		for e in b.enemies:
			if bool(e.get("immune", false)):
				continue
			if e.alive:
				v -= 0.6 * float(e.hp)
			else:
				v += 15.0
	return v
