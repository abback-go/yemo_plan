class_name TPolicy
extends RefCounted
## 아군 자동 조작 (헤드리스 시뮬레이션 · 화면의 "자동" 버튼). dealer = 버프를 몰아줄 딜러 id.
## 규칙(위에서부터): 위험한 시전을 끊는다 → 쓰러질 아군을 살린다 → 서포터는 딜러에게 버프를 겹친다 → 딜러는 버프가 있을 때 대마법을 쓴다 → 남는 차례는 공격.
## 돌려주는 값: {"spell": id, "target": id} 또는 {"wait": true}. 물약은 potion()으로 따로 묻는다.

var dealer := "eska"


func _init(p_dealer := "eska") -> void:
	dealer = p_dealer


## 물약을 쓸까 (차례를 쓰지 않으므로 행동 전에 묻는다). 없으면 {}
func potion(b: TBattle, u: TBattle.Unit) -> Dictionary:
	if b.bag.is_empty():
		return {}
	for a in b.allies():
		if a.hp_ratio() < 0.35 and "heal" in b.bag:
			return {"potion": "heal", "target": a.id}
	for e in b.casting_enemies():
		var sp := b.spec_of(e, String(e.casting.spell))
		if float(sp.get("power", 0.0)) >= 200.0:
			if "bind" in b.bag:
				return {"potion": "bind", "target": e.id}
			if "scream" in b.bag:
				return {"potion": "scream", "target": ""}
	var boss := _main_enemy(b)
	if boss != null and boss.boss and "rot" in b.bag and boss.stacks_of_spell("potion_rot") == 0:
		return {"potion": "rot", "target": boss.id}
	if u.id == dealer and "haste" in b.bag and u.has_gauge and u.gauge >= TData.GAUGE_MAX - 0.001 and _buffed(u) and b.enemies().size() >= 1:
		return {} # 대마법 직전엔 굳이 가속 안 씀
	return {}


func choose(b: TBattle, u: TBattle.Unit) -> Dictionary:
	var d := b.find(dealer)
	if d == null or not d.alive:
		d = _best_dealer(b)
	var main := _main_enemy(b)
	if main == null:
		return {"wait": true}
	# 1. 위험한 시전 끊기 (굳센 시전은 봉공만)
	for e in b.casting_enemies():
		var sp := b.spec_of(e, String(e.casting.spell))
		if float(sp.get("power", 0.0)) >= 140.0:
			if b.can_use(u, "seal"):
				return {"spell": "seal", "target": e.id}
			if b.can_use(u, "skytear") and not b.is_heavy_cast(e):
				return {"spell": "skytear", "target": e.id}
	# 2. 살리기
	for a in b.allies():
		if a.hp_ratio() < 0.4 and b.can_use(u, "warmth"):
			return {"spell": "warmth", "target": a.id}
	match u.id:
		"eska":
			return _eska(b, u, d, main)
		"sera":
			return _sera(b, u, d, main)
		"ashe":
			return _ashe(b, u, d, main)
	return _any_attack(b, u, main)


func _eska(b: TBattle, u: TBattle.Unit, d: TBattle.Unit, main: TBattle.Unit) -> Dictionary:
	var is_dealer := d.id == u.id
	var tgt := d
	if is_dealer:
		# 딜러 에스카: 한 겹씩만 깔고 공격, 대마법은 버프 위에서. 적이 많이 남았을 때만 두 겹째
		var big := _enemy_hp_total(b) > 1500
		if b.can_use(u, "rift") and tgt.stacks_of_spell("rift") < (2 if big else 1):
			return {"spell": "rift", "target": tgt.id}
		if b.can_use(u, "stareyes") and tgt.stacks_of_spell("stareyes") < (2 if big else 1):
			return {"spell": "stareyes", "target": tgt.id}
		if b.can_use(u, "blackstar") and _buffed(u):
			return {"spell": "blackstar", "target": ""}
		if b.can_use(u, "skytear"):
			return {"spell": "skytear", "target": main.id}
		if b.can_use(u, "crack"):
			return {"spell": "crack", "target": main.id}
	else:
		if b.can_use(u, "rift") and tgt.stacks_of_spell("rift") < 2:
			return {"spell": "rift", "target": tgt.id}
		if b.can_use(u, "stareyes") and tgt.stacks_of_spell("stareyes") < 2:
			return {"spell": "stareyes", "target": tgt.id}
		# 서포터 에스카: 봉공으로 취약을 걸고, 게이지가 차면 흑성도 쓴다
		if b.can_use(u, "seal") and main.stacks_of_spell("seal") == 0:
			return {"spell": "seal", "target": main.id}
		if b.can_use(u, "blackstar") and b.enemies().size() >= 2:
			return {"spell": "blackstar", "target": ""}
		if b.can_use(u, "skytear"):
			return {"spell": "skytear", "target": main.id}
		if b.can_use(u, "crack"):
			return {"spell": "crack", "target": main.id}
	return {"wait": true}


func _sera(b: TBattle, u: TBattle.Unit, d: TBattle.Unit, main: TBattle.Unit) -> Dictionary:
	var is_dealer := d.id == u.id
	if not is_dealer:
		if b.can_use(u, "embers") and d.alive and not d.is_casting() and d.wait > 1.5:
			return {"spell": "embers", "target": d.id}
		if b.can_use(u, "ward"):
			for e in b.casting_enemies():
				var sp := b.spec_of(e, String(e.casting.spell))
				if float(sp.get("power", 0.0)) >= 140.0:
					var t := b.find(String(e.casting.get("target", "")))
					return {"spell": "ward", "target": (t.id if t != null and t.alive else d.id)}
	if is_dealer and b.can_use(u, "meteor") and _buffed(u):
		return {"spell": "meteor", "target": ""}
	if b.can_use(u, "storm") and b.enemies().size() >= 2:
		return {"spell": "storm", "target": ""}
	if b.can_use(u, "pillar"):
		return {"spell": "pillar", "target": main.id}
	if not is_dealer and b.can_use(u, "meteor") and b.enemies().size() >= 2:
		return {"spell": "meteor", "target": ""}
	if b.can_use(u, "firebolt"):
		return {"spell": "firebolt", "target": main.id}
	return {"wait": true}


func _ashe(b: TBattle, u: TBattle.Unit, d: TBattle.Unit, main: TBattle.Unit) -> Dictionary:
	if b.can_use(u, "oil") and main.stacks_of_spell("oil") < 2:
		return {"spell": "oil", "target": main.id}
	if d.elem == TData.ELEM_FIRE and b.can_use(u, "bellows") and d.stacks_of_spell("bellows") < 2:
		return {"spell": "bellows", "target": d.id}
	if b.can_use(u, "festival") and d.stacks_of_spell("festival") == 0:
		return {"spell": "festival", "target": ""}
	if b.can_use(u, "sparks") and (b.enemies().size() >= 2 or main.stacks_of_spell("sparks") == 0):
		return {"spell": "sparks", "target": ""}
	if b.can_use(u, "warmth"):
		for a in b.allies():
			if a.hp_ratio() < 0.6:
				return {"spell": "warmth", "target": a.id}
	if b.can_use(u, "flick"):
		return {"spell": "flick", "target": main.id}
	return {"wait": true}


func _any_attack(b: TBattle, u: TBattle.Unit, main: TBattle.Unit) -> Dictionary:
	for s in u.spells:
		var sp := TData.spell(s)
		if String(sp.get("kind", "")) == "attack" and b.can_use(u, s):
			return {"spell": s, "target": main.id}
	return {"wait": true}


## 딜러에게 버프가 하나라도 걸려 있는가 (대마법은 버프 위에서)
func _buffed(u: TBattle.Unit) -> bool:
	for bf in u.buffs:
		if bf.kind in ["final", "crit_dmg", "elem", "atk"]:
			return true
	return false


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
