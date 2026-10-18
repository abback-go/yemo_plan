class_name TAuto
extends RefCounted
## 마녀의 자동 선택 (시험·시연용 — 사람 대신 고른다). 장착한 마법을 "지금 새로 주는 것"으로 점수 매겨 가장 높은 것을 쓰고,
## 점수가 낮으면 기본 공격으로 크레딧을 모은다. tools/test/turn_sim.gd(밸런스)와 TStage(자동 플레이)가 같이 쓴다.

const USE_AT := 2.2 ## 이 점수 아래면 기본 공격


static func pick(b: TBattle, u: TUnit) -> Dictionary:
	var en := enemy_for(b)
	var dealer := dealer_of(b)
	var best_sid := ""
	var best_tgt: TUnit = null
	var best := 0.0
	for sid in u.equipped:
		if not b.can_use(u, sid):
			continue
		var r := score(b, u, sid, en, dealer)
		if float(r.score) > best:
			best = float(r.score)
			best_sid = sid
			best_tgt = r.tgt
	if best_sid != "" and best >= USE_AT:
		return {"kind": "skill", "skill": best_sid, "target": best_tgt}
	return {"kind": "basic", "skill": "basic", "target": en}


## 불 약점(짚 골렘)이 살아 있으면 그쪽, 아니면 체력이 가장 적은 적
static func enemy_for(b: TBattle) -> TUnit:
	var a := b.alive_of(b.enemies)
	if a.is_empty():
		return null
	for e in a:
		if e.element == "straw":
			return e
	var best: TUnit = a[0]
	for e in a:
		if e.hp < best.hp:
			best = e
	return best


## 공격력이 가장 높은 살아 있는 마녀
static func dealer_of(b: TBattle) -> TUnit:
	var d: TUnit = null
	for w in b.alive_of(b.witches):
		if d == null or w.atk > d.atk:
			d = w
	return d


static func heavy_coming(b: TBattle) -> bool:
	for e in b.alive_of(b.enemies):
		var k := String(e.intent().get("k", ""))
		if k == "heavy" or k == "aoe":
			return true
	return false


static func score(b: TBattle, u: TUnit, sid: String, en: TUnit, dealer: TUnit) -> Dictionary:
	var sk := TData.skill(sid)
	var cost := int(sk.cost)
	var kind := String(sk.kind)
	var target := String(sk.target)
	var effects: Array = sk.get("effects", [])
	var s := 0.0
	var tgt: TUnit = en
	if kind == "attack":
		s = float(sk.mult) * (2.5 if target == "enemies" else 1.0)
		for e in effects:
			if e.t == "this_special" and en.marks.has(e.mark):
				s *= 1.0 + float(e.v)
		if u.credits >= 5 and cost >= 4:
			s *= 1.6 # 모았으면 큰 것
		elif cost >= 3 and u.credits < 5:
			s *= 0.45 # 아직 모으는 중
		s *= 1.0 + 0.4 * u.cat_sum("atk") # 버프를 받았으면 지금 때린다
	elif kind == "debuff":
		var fresh := 0.0
		for e in effects:
			match String(e.t):
				"mark": fresh += 0.0 if en.marks.has(e.kind) else 1.0
				"debuff": fresh += 0.0 if en.has_buff(e.cat) else 1.0
				"enemy_gauge", "gauge_zero": fresh += 0.5 if en.gauge > 500.0 else 0.1
				"buff": fresh += 0.8
		s = 0.6 + 1.3 * fresh
		if cost >= 4 and u.credits < 5:
			s *= 0.5
	else:
		var who := dealer if dealer != null else u
		if target == "self":
			who = u
		var fresh := 0.0
		var low: TUnit = null
		var dead: TUnit = null
		for w in b.witches:
			if not w.alive:
				dead = w
			elif w.hp_ratio() < 0.45 and (low == null or w.hp_ratio() < low.hp_ratio()):
				low = w
		for e in effects:
			match String(e.t):
				"buff": fresh += 0.0 if who.has_buff(e.cat) else 1.0
				"credits": fresh += 0.7
				"gauge": fresh += 0.5 if who != u and who.gauge < 400.0 else 0.1
				"heal": fresh += 2.5 if low != null else 0.0
				"revive":
					fresh += 5.0 if dead != null else (2.0 if low != null else 0.0)
				"invincible": fresh += 1.6 if heavy_coming(b) else 0.2
				"extend_buffs": fresh += 0.8 if who.buffs.size() >= 2 else 0.1
				"demerit_zero": fresh -= 0.5 if who.credits < 5 else 0.0
		s = 0.6 + 1.3 * fresh
		if cost >= 4 and u.credits < 5:
			s *= 0.6
		if target == "ally_any" and dead != null:
			tgt = dead
		elif target in ["ally", "ally_any"] and low != null and _heals(effects):
			tgt = low
		else:
			tgt = who
	return {"score": s, "tgt": tgt}


static func _heals(effects: Array) -> bool:
	for e in effects:
		if e.t in ["heal", "revive"]:
			return true
	return false
