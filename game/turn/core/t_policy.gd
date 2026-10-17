class_name TPolicy
extends RefCounted
## 아군 자동 조작 v0.3 (헤드리스 시뮬레이션 · 화면의 "자동"). 내 턴의 마법을 하나씩 고른다 — choose()를 마력이 남는 동안 되풀이.
## 생각: 이번 턴의 "한 방"(대마법 > 딜러의 큰 공격)을 정하고 그 비용을 남겨 둔 채, 나머지 마력으로 그 한 방을 키우는 준비를 깐다.
##   에스카 딜러: 금×3 → 틈 → 축제 → (별빛 눈은 맨 마지막) → 천열/흑성.   세라 딜러: 기름×2 → 풀무 → 틈 → 축제 → 별빛 → 불기둥/폭풍/유성.
## 한 방이 쿨이면 오래 가는 준비(금·기름·틈·풀무·축제)만 깔고 별빛은 아낀다(싼 공격이 먹어 버리므로).
## 위에서부터: 위험한 시전 끊기 → 살리기 → 잉걸불(공짜) → 준비 → 한 방 → 남는 마력은 금(에스카) 같은 싼 공격.
## 돌려주는 값: {"unit": id, "spell": id, "target": id} 또는 {"end": true}. 물약은 potion()으로 따로 묻는다.

var dealer := "eska"


func _init(p_dealer := "eska") -> void:
	dealer = p_dealer


## 물약을 쓸까 (마력을 쓰지 않으므로 마법 전에 묻는다). 없으면 {}
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
	if d != null and d.alive and "haste" in b.bag and b.mana_left <= 2 and _payoff(b, d, boss) != "":
		return {"unit": d.id, "potion": "haste", "target": d.id}
	return {}


func choose(b: TBattle) -> Dictionary:
	if b.mana_left <= 0 or b.over:
		return {"end": true}
	var main := _main_enemy(b)
	if main == null:
		return {"end": true}
	var d := b.find(dealer)
	if d == null or not d.alive:
		d = _best_dealer(b)
	# 지금 적이 딜러의 속성을 저항하면(기사왕 1줄 vs 화염) 그 줄은 에스카가 딜러 — 화염 딜러는 다음 줄까지 게이지를 모은다
	if b.affinity(d.elem, main) < 0.99:
		var alt := _best_dealer_vs(b, main)
		if alt != null:
			d = alt
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
	# 3. 잉걸불은 공짜 — 늘 먼저
	if sera and b.can_use(sera, "embers"):
		return {"unit": "sera", "spell": "embers", "target": "sera"}
	# 4. 이번 턴의 한 방과 그 비용
	var pay := _payoff(b, d, main)
	var reserve := b.cost_of(pay) if pay != "" else 0
	var budget := b.mana_left - reserve
	# 5. 준비 (한 방 비용은 남겨 두고). 한 방이 없으면 오래 가는 준비만
	var setup := _setup(b, d, main, budget, pay != "")
	if not setup.is_empty():
		return setup
	# 6. 한 방
	if pay != "":
		var sp := TData.spell(pay)
		return {"unit": d.id, "spell": pay, "target": "" if String(sp.get("target", "")) == "all" else main.id}
	# 7. 남는 마력: 싼 공격 (기름은 딜러가 태우도록 화염 마녀는 피함)
	var filler := _filler(b, d, main)
	if not filler.is_empty():
		return filler
	return {"end": true}


## 이번 턴의 한 방: 대마법(준비됐고 아낄 이유가 없으면) > 딜러의 가장 센 쓸 수 있는 공격. 없으면 ""
func _payoff(b: TBattle, d: TBattle.Unit, main: TBattle.Unit) -> String:
	if d == null or not d.alive or main == null:
		return ""
	var ult_id := _ult_of(d)
	if ult_id != "" and b.can_use(d, ult_id):
		# 보스가 아직 줄이 남았고 지금 줄이 내 속성을 저항하면 아낀다 (다음 줄에서 터뜨림)
		var hold := main.boss and main.bar_i < main.bars.size() - 1 and b.affinity(String(TData.spell(ult_id).get("elem", "")), main) < 0.99
		if not hold:
			return ult_id
	var many := b.enemies().size() >= 2
	var order: Array = []
	match d.id:
		"eska":
			order = ["skytear"]
		"sera":
			order = ["storm", "pillar"] if (many or main.burn_left >= 2) else ["pillar", "storm"]
		"ashe":
			order = ["sparks"]
	for s0 in order:
		var s := String(s0)
		if b.can_use(d, s):
			return s
	return ""


## 한 방을 키우는 준비 하나. budget 안에서, 쓸모 있는 것만. 별빛 눈은 한 방이 있을 때 맨 마지막에
func _setup(b: TBattle, d: TBattle.Unit, main: TBattle.Unit, budget: int, has_pay: bool) -> Dictionary:
	var eska := b.find("eska")
	var ashe := b.find("ashe")
	var fire := d.elem == TData.ELEM_FIRE
	var c := func(u: TBattle.Unit, s: String) -> bool:
		return u != null and b.can_use(u, s) and b.cost_of(s) <= budget
	if not fire:
		if c.call(eska, "crack") and main.marks("crack") < 3:
			return {"unit": "eska", "spell": "crack", "target": main.id}
	else:
		if c.call(ashe, "oil") and main.marks("oil") < 2:
			return {"unit": "ashe", "spell": "oil", "target": main.id}
		if c.call(ashe, "bellows") and d.stacks_of_spell("bellows") < 2:
			return {"unit": "ashe", "spell": "bellows", "target": d.id}
	if c.call(eska, "rift") and d.stacks_of_spell("rift") < 2:
		return {"unit": "eska", "spell": "rift", "target": d.id}
	if c.call(ashe, "festival") and d.stacks_of_spell("festival") == 0:
		return {"unit": "ashe", "spell": "festival", "target": ""}
	if main.boss and c.call(eska, "seal") and main.stacks_of_spell("seal") == 0 and has_pay:
		return {"unit": "eska", "spell": "seal", "target": main.id}
	if has_pay and c.call(eska, "stareyes") and d.marks("sure") == 0:
		return {"unit": "eska", "spell": "stareyes", "target": d.id}
	return {}


## 남는 마력으로 하는 싼 공격. 별빛을 든 마녀는 쏘지 않는다(한 방에 써야 하므로). 기름이 깔린 적에게 화염 마녀의 싼 공격은 피한다
func _filler(b: TBattle, d: TBattle.Unit, main: TBattle.Unit) -> Dictionary:
	for a in b.allies():
		if a.marks("sure") > 0:
			continue
		var s := ""
		match a.id:
			"eska":
				s = "crack"
			"sera":
				s = "firebolt"
			"ashe":
				s = "flick"
		if s == "" or not b.can_use(a, s):
			continue
		if a.elem == TData.ELEM_FIRE and main.marks("oil") > 0 and d.elem == TData.ELEM_FIRE and a.id != d.id:
			continue
		return {"unit": a.id, "spell": s, "target": main.id}
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


## 집중할 적: 보스 → 상태(금·기름·취약)가 많이 깔린 적 → 체력이 가장 적은 적
func _main_enemy(b: TBattle) -> TBattle.Unit:
	var es := b.enemies()
	if es.is_empty():
		return null
	for e in es:
		if e.boss:
			return e
	var best := es[0]
	for e in es:
		var se := e.marks("crack") + e.marks("oil") + int(e.sum("vuln") * 4.0)
		var sb := best.marks("crack") + best.marks("oil") + int(best.sum("vuln") * 4.0)
		if se > sb or (se == sb and e.hp < best.hp):
			best = e
	return best


## 이 적에게 저항당하지 않는 가장 센 아군
func _best_dealer_vs(b: TBattle, main: TBattle.Unit) -> TBattle.Unit:
	var best: TBattle.Unit = null
	for a in b.allies():
		if b.affinity(a.elem, main) < 0.99:
			continue
		if best == null or a.atk * b.affinity(a.elem, main) > best.atk * b.affinity(best.elem, main):
			best = a
	return best


func _best_dealer(b: TBattle) -> TBattle.Unit:
	var best: TBattle.Unit = null
	for a in b.allies():
		if best == null or a.atk > best.atk:
			best = a
	return best
