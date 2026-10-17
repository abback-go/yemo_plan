class_name TPolicy
extends RefCounted
## 아군 자동 조작 v2 (헤드리스 시뮬레이션 · 화면의 "자동"). 내 턴의 행동을 하나씩 고른다 — choose()를 행동이 남을 때까지 되풀이.
## 규칙(위에서부터): 위험한 시전 끊기 → 쓰러질 아군 살리기 → 딜러의 대마법이 준비됐으면 버프 깔고 쏘기 →
## 버프가 모자라면 딜러에게 겹치기(행동 1개는 공격용으로 남김) → 딜러 공격 → 남는 행동은 다른 마녀의 공격.
## 돌려주는 값: {"unit": id, "spell": id, "target": id} 또는 {"end": true}. 물약은 potion()으로 따로 묻는다.

var dealer := "eska"


func _init(p_dealer := "eska") -> void:
	dealer = p_dealer


## 물약을 쓸까 (행동을 쓰지 않으므로 행동 전에 묻는다). 없으면 {}
func potion(b: TBattle) -> Dictionary:
	if b.bag.is_empty():
		return {}
	var any := _first_alive(b)
	if any == null:
		return {}
	for a in b.allies():
		if a.hp_ratio() < 0.35 and "heal" in b.bag:
			return {"unit": any.id, "potion": "heal", "target": a.id}
	for e in b.casting_enemies():
		var sp := b.spec_of(e, String(e.casting.spell))
		if float(sp.get("power", 0.0)) >= 150.0 and not _can_interrupt(b, e):
			if "bind" in b.bag:
				return {"unit": any.id, "potion": "bind", "target": e.id}
			if "scream" in b.bag:
				return {"unit": any.id, "potion": "scream", "target": ""}
	var boss := _main_enemy(b)
	if boss != null and boss.boss and "rot" in b.bag and boss.stacks_of_spell("potion_rot") == 0:
		return {"unit": any.id, "potion": "rot", "target": boss.id}
	var d := b.find(dealer)
	if d != null and d.alive and "haste" in b.bag and d.has_gauge and d.gauge >= TData.GAUGE_MAX - 0.001 and b.actions_left <= 2:
		return {"unit": d.id, "potion": "haste", "target": d.id}
	return {}


func choose(b: TBattle) -> Dictionary:
	if b.actions_left <= 0 or b.over:
		return {"end": true}
	var main := _main_enemy(b)
	if main == null:
		return {"end": true}
	var d := b.find(dealer)
	if d == null or not d.alive:
		d = _best_dealer(b)
	var eska := b.find("eska")
	var sera := b.find("sera")
	var ashe := b.find("ashe")
	# 1. 위험한 시전 끊기
	for e in b.casting_enemies():
		var sp := b.spec_of(e, String(e.casting.spell))
		if float(sp.get("power", 0.0)) >= 150.0:
			if eska and b.can_use(eska, "seal"):
				return {"unit": "eska", "spell": "seal", "target": e.id}
			if eska and b.can_use(eska, "skytear") and not b.is_heavy_cast(e):
				return {"unit": "eska", "spell": "skytear", "target": e.id}
	# 2. 살리기
	for a in b.allies():
		if a.hp_ratio() < 0.4 and ashe and b.can_use(ashe, "warmth"):
			return {"unit": "ashe", "spell": "warmth", "target": a.id}
	# 3. 가속은 먼저 (행동이 늘어남)
	if sera and b.can_use(sera, "embers") and b.actions_left <= 3:
		return {"unit": "sera", "spell": "embers", "target": "sera"}
	# 4. 딜러의 대마법이 준비됐으면: 행동이 2개 이상 남았을 때 버프를 하나 더 깔고, 마지막에 쏜다
	var ult_id := _ult_of(d)
	var ult_ready := ult_id != "" and b.can_use(d, ult_id)
	# 보스가 아직 줄이 남았고 지금 줄이 내 속성을 저항하면 대마법을 아낀다 (다음 줄에서 터뜨림)
	if ult_ready and main.boss and main.bar_i < main.bars.size() - 1 and b.affinity(String(TData.spell(ult_id).get("elem", "")), main) < 0.99:
		ult_ready = false
	if ult_ready:
		if b.actions_left >= 2:
			var bf := _missing_buff(b, d, main, 2)
			if not bf.is_empty():
				return bf
		return {"unit": d.id, "spell": ult_id, "target": ""}
	# 5. 버프 겹치기 (행동 1개는 공격용으로 남김) — 전투가 길 때만 두 겹째
	if b.actions_left >= 2:
		var big := _enemy_hp_total(b) > 1500
		var bf := _missing_buff(b, d, main, 2 if big else 1)
		if not bf.is_empty():
			return bf
	# 6. 딜러 공격
	var atk := _best_attack(b, d, main)
	if not atk.is_empty():
		return atk
	# 7. 남는 행동: 다른 마녀의 공격
	for a in b.allies():
		if a.id == d.id:
			continue
		var at := _best_attack(b, a, main)
		if not at.is_empty():
			return at
	return {"end": true}


## 딜러에게 빠진 버프 하나 (stacks < want). 우선순위: 틈 → 별빛 → 풀무(화염 딜러) → 기름(적) → 축제
func _missing_buff(b: TBattle, d: TBattle.Unit, main: TBattle.Unit, want: int) -> Dictionary:
	var eska := b.find("eska")
	var ashe := b.find("ashe")
	if eska and b.can_use(eska, "rift") and d.stacks_of_spell("rift") < want:
		return {"unit": "eska", "spell": "rift", "target": d.id}
	if eska and b.can_use(eska, "stareyes") and d.stacks_of_spell("stareyes") < want:
		return {"unit": "eska", "spell": "stareyes", "target": d.id}
	if ashe and d.elem == TData.ELEM_FIRE and b.can_use(ashe, "bellows") and d.stacks_of_spell("bellows") < want:
		return {"unit": "ashe", "spell": "bellows", "target": d.id}
	if ashe and b.can_use(ashe, "oil") and main.stacks_of_spell("oil") < want:
		return {"unit": "ashe", "spell": "oil", "target": main.id}
	if ashe and b.can_use(ashe, "festival") and d.stacks_of_spell("festival") == 0:
		return {"unit": "ashe", "spell": "festival", "target": ""}
	if eska and d.id != "eska" and b.can_use(eska, "seal") and main.stacks_of_spell("seal") == 0 and main.boss:
		return {"unit": "eska", "spell": "seal", "target": main.id}
	return {}


## 그 마녀의 가장 센 쓸 수 있는 공격 (적이 둘 이상이면 전체기 우선)
func _best_attack(b: TBattle, u: TBattle.Unit, main: TBattle.Unit) -> Dictionary:
	if u == null or not u.alive:
		return {}
	var many := b.enemies().size() >= 2
	var order: Array = []
	match u.id:
		"eska":
			order = ["skytear", "crack"]
		"sera":
			order = ["storm", "pillar", "firebolt"] if many else ["pillar", "storm", "firebolt"]
		"ashe":
			order = ["sparks", "flick"] if many else ["flick", "sparks"]
	for s0 in order:
		var s := String(s0)
		if b.can_use(u, s):
			var sp := TData.spell(s)
			return {"unit": u.id, "spell": s, "target": "" if String(sp.get("target", "")) == "all" else main.id}
	return {}


func _ult_of(u: TBattle.Unit) -> String:
	if u == null:
		return ""
	for s in u.spells:
		if String(TData.spell(s).get("kind", "")) == "ult":
			return s
	return ""


func _can_interrupt(b: TBattle, e: TBattle.Unit) -> bool:
	var eska := b.find("eska")
	if eska == null:
		return false
	if b.can_use(eska, "seal"):
		return true
	return b.can_use(eska, "skytear") and not b.is_heavy_cast(e)


func _first_alive(b: TBattle) -> TBattle.Unit:
	var al := b.allies()
	return al[0] if not al.is_empty() else null


## 집중할 적: 보스 → 취약이 걸린 적 → 체력이 가장 적은 적
func _main_enemy(b: TBattle) -> TBattle.Unit:
	var es := b.enemies()
	if es.is_empty():
		return null
	for e in es:
		if e.boss:
			return e
	var best := es[0]
	for e in es:
		if e.sum("vuln") > best.sum("vuln") or (e.sum("vuln") == best.sum("vuln") and e.hp < best.hp):
			best = e
	return best


func _enemy_hp_total(b: TBattle) -> int:
	var s := 0
	for e in b.enemies():
		s += e.hp
		for i in range(e.bar_i + 1, e.bars.size()):
			s += int(e.bars[i].hp)
	return s


func _best_dealer(b: TBattle) -> TBattle.Unit:
	var best: TBattle.Unit = null
	for a in b.allies():
		if best == null or a.atk > best.atk:
			best = a
	return best
