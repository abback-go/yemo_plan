class_name TAuto
extends RefCounted
## 마녀의 자동 선택 (시험·시연용 — 사람 대신 고른다). 장착한 마법을 "지금 새로 주는 것"으로 점수 매겨 가장 높은 것을 쓰고,
## 점수가 낮으면 기본 공격으로 크레딧을 모은다. tools/test/turn_sim.gd(밸런스)와 TStage(자동 플레이)가 같이 쓴다.
## 크레딧 7이면 대마법, 5~6이면 큰 마법을 아껴 7로 모은다. 징표는 겹을 쌓고, 터뜨리기는 겹이 3 이상일 때, 기절은 위험한 의도 앞에서.
## 단계 B: 횟수제 기본 공격 버프가 있으면 기본 공격 · 차지가 차면 차지 감소 · 관통 필살기 앞에선 무적 대신 받는 피해 감소.
## 빌드 원형 시험(tools/test/turn_sim.gd)은 plan으로 역할을 정해 준다 (비어 있으면 위 규칙만):
##   dealer: 딜러 id · ult_only: [대마법·기본 공격만 쓰는 id] · battery: [딜러에게 크레딧을 몰아주는 id — 자기 대마법은 안 씀]
##   push: [딜러 게이지를 올려 차례를 몰아주는 id]
##   trigger: {id: {skill, at}} — 딜러가 다음 차례에 at 크레딧이 되고 공격력 버프가 있을 때 그 마법을 딜러에게 (대가 몰빵의 마지막 신호)

const USE_AT := 2.2 ## 이 점수 아래면 기본 공격
const DANGER := ["heavy", "aoe", "stun_attack", "finisher"] ## 미리 막을 만한 적 의도
static var plan := {}


static func _in(key: String, u: TUnit) -> bool:
	return (plan.get(key, []) as Array).has(u.id)


static func pick(b: TBattle, u: TUnit) -> Dictionary:
	var en := enemy_for(b, u)
	var dealer := dealer_of(b)
	var ult := String(u.data.get("ultimate", ""))
	if _in("battery", u) and dealer != u and dealer.alive:
		ult = "" # 배터리는 자기 대마법을 아끼고 딜러에게 몰아준다
	if ult != "" and b.can_use(u, ult) and String(TData.skill(ult).kind) == "support" and _protective(ult) and not _danger(b):
		ult = "" # 지키는 대마법(무적·받는 피해·회복·되살림)은 위험한 의도·쓰러진/낮은 아군이 있을 때까지 아낀다
	if ult != "" and b.can_use(u, ult):
		var t: TUnit = en
		if not b.needs_target_pick(ult) or String(TData.skill(ult).target) != "enemy":
			t = b.valid_targets(u, ult)[0]
		return {"kind": "skill", "skill": ult, "target": t}
	if _in("ult_only", u):
		return {"kind": "basic", "skill": "basic", "target": en}
	if _in("battery", u):
		var fd := _feed(b, u, dealer)
		if not fd.is_empty():
			return fd
		if b.chain_stage == 0 and dealer.alive and dealer.credits < TData.ULT_COST:
			return {"kind": "basic", "skill": "basic", "target": en} # 연쇄 전에는 모은다
	if _in("push", u) and dealer.alive and dealer != u:
		# 차례 몰아주기: 장착한 것 중 딜러 게이지를 가장 크게 올리는 마법 — 크레딧이 모자라면 모은다
		var best_p := ""
		var best_v := 0.0
		for sid in u.equipped:
			var sk := TData.skill(sid)
			if String(sk.target) not in ["ally", "allies"]:
				continue
			for e in sk.get("effects", []):
				if String(e.t) == "gauge" and String(e.get("who", "target")) in ["target", "allies"] and float(e.v) > best_v:
					best_p = sid
					best_v = float(e.v)
		if best_p != "":
			if b.can_use(u, best_p) and dealer.gauge < 600.0:
				return {"kind": "skill", "skill": best_p, "target": dealer}
			if u.credits < TData.cost_of(best_p):
				return {"kind": "basic", "skill": "basic", "target": en}
	var trig: Dictionary = (plan.get("trigger", {}) as Dictionary).get(u.id, {})
	if not trig.is_empty() and dealer.alive and dealer != u:
		# 몰빵 신호: 딜러가 다음 차례에 큰 마법(at 크레딧)을 쓸 수 있고 버프를 받아 두었으면 그때 건다. 그 전엔 비용을 남긴다
		var tsid := String(trig.skill)
		if dealer.credits + 1 >= int(trig.at) and dealer.has_buff("atk") and b.can_use(u, tsid):
			return {"kind": "skill", "skill": tsid, "target": dealer}
		if u.credits < TData.cost_of(tsid) + 2:
			return {"kind": "basic", "skill": "basic", "target": en}
	if _counting(u, "basic"):
		return {"kind": "basic", "skill": "basic", "target": en} # 횟수제 기본 공격 버프가 남아 있으면 기본 공격
	var best_sid := ""
	var best_tgt: TUnit = null
	var best := 0.0
	for sid in u.equipped:
		if not b.can_use(u, sid):
			continue
		var r := score(b, u, sid, en, dealer)
		var sc := float(r.score)
		if ult != "" and u.credits >= 5 and TData.cost_of(sid) >= 3 and not _in("battery", u):
			sc *= 0.4 # 대마법까지 한두 차례 — 큰 마법은 아낀다
		if sc > best:
			best = sc
			best_sid = sid
			best_tgt = r.tgt
	if best_sid != "" and best >= USE_AT:
		return {"kind": "skill", "skill": best_sid, "target": best_tgt}
	return {"kind": "basic", "skill": "basic", "target": en}


## 이 마녀의 공격 속성이 약점인 적 → 불 약점(짚 골렘) → 체력이 가장 적은 적
static func enemy_for(b: TBattle, u: TUnit = null) -> TUnit:
	var a := b.alive_of(b.enemies)
	if a.is_empty():
		return null
	if u != null:
		var el := u.attack_element()
		for e in a:
			if e.weak.has(el):
				return e
	for e in a:
		if e.element == "straw":
			return e
	var best: TUnit = a[0]
	for e in a:
		if e.hp < best.hp:
			best = e
	return best


## 배터리: 크레딧을 주는 마법으로 딜러가 다음 차례에 대마법을 쓸 수 있게 되면 (또는 연쇄 중이면) 준다
static func _feed(b: TBattle, u: TUnit, dealer: TUnit) -> Dictionary:
	if dealer == null or not dealer.alive or dealer == u or dealer.credits >= TData.ULT_COST:
		return {}
	var best := ""
	var best_g := 0
	for sid in u.equipped:
		if not b.can_use(u, sid):
			continue
		var sk := TData.skill(sid)
		if String(sk.target) not in ["ally", "ally_any"]:
			continue
		for e in sk.get("effects", []):
			if String(e.t) == "credits" and String(e.get("who", "target")) == "target" and int(e.v) > best_g:
				best = sid
				best_g = int(e.v)
	if best == "":
		return {}
	if b.chain_stage > 0 or dealer.credits + best_g + 1 >= TData.ULT_COST:
		return {"kind": "skill", "skill": best, "target": dealer}
	return {}


## 지키는 효과가 있는 마법인가 (무적·받는 피해 감소·회복·되살림)
static func _protective(sid: String) -> bool:
	for e in TData.skill(sid).get("effects", []):
		if String(e.t) in ["invincible", "heal", "revive"] or (String(e.t) == "buff" and String(e.get("cat", "")) == "dmg_taken"):
			return true
	return false


## 위험: 강한 의도가 다음에 오거나, 쓰러진 아군 또는 체력 45% 미만 아군이 있다
static func _danger(b: TBattle) -> bool:
	if heavy_coming(b):
		return true
	for w in b.witches:
		if not w.alive or w.hp_ratio() < 0.45:
			return true
	return false


## 그 종류(on)의 횟수제 버프가 남아 있나
static func _counting(u: TUnit, on: String) -> bool:
	for bf in u.buffs:
		if bf.has("count") and String(bf.get("on", "")) == on:
			return true
	return false


## 공격력이 가장 높은 살아 있는 마녀 (plan.dealer가 살아 있으면 그 마녀)
static func dealer_of(b: TBattle) -> TUnit:
	var d: TUnit = null
	for w in b.alive_of(b.witches):
		if w.id == String(plan.get("dealer", "")):
			return w
	for w in b.alive_of(b.witches):
		if d == null or w.atk > d.atk:
			d = w
	return d


static func heavy_coming(b: TBattle) -> bool:
	for e in b.alive_of(b.enemies):
		if String(e.intent().get("k", "")) in DANGER:
			return true
	return false


## 무적을 뚫는 필살기가 다음에 오나 (§18.10)
static func pierce_coming(b: TBattle) -> bool:
	for e in b.alive_of(b.enemies):
		if bool(e.intent().get("pierce", false)):
			return true
	return false


## 차지가 하나 남았거나 가득 찬 적 (차지 감소의 과녁)
static func charge_target(b: TBattle) -> TUnit:
	for e in b.alive_of(b.enemies):
		if e.charge_max > 0 and e.charge >= e.charge_max - 1:
			return e
	return null


## 기절시킬 가치가 있나: 위험한 의도이고, 면역·기절 내성·이미 기절이 아님
static func stun_worth(en: TUnit) -> bool:
	return en != null and not en.stun_immune and not en.stun_guard and not en.stunned and String(en.intent().get("k", "")) in DANGER


static func score(b: TBattle, u: TUnit, sid: String, en: TUnit, dealer: TUnit) -> Dictionary:
	var sk := TData.skill(sid)
	var cost := int(sk.cost)
	var kind := String(sk.kind)
	var target := String(sk.target)
	var effects: Array = sk.get("effects", [])
	var s := 0.0
	var tgt: TUnit = en
	if kind == "attack":
		var mult := float(sk.mult)
		s = mult * (2.5 if target == "enemies" else 1.0)
		for e in effects:
			match String(e.t):
				"this_special":
					s *= 1.0 + float(e.v) * float(en.mark_n(String(e.mark)))
				"burst":
					var n := en.mark_n(String(e.mark))
					s *= (mult + float(e.per) * float(n)) / mult if n >= 3 else 0.5 # 3겹 전에는 쌓아 둔다
				"hp_cost":
					if u.hp_ratio() < 0.45:
						s *= 0.3
				"credits":
					if not e.has("if_mark") or en.marks.has(e.if_mark):
						s *= 1.0 + 0.25 * float(e.v)
				"stun":
					if stun_worth(en) and (not e.has("if_mark") or en.marks.has(e.if_mark)):
						s *= 1.6
		if _counting(u, "skill"):
			s *= 1.6 if cost >= 3 else 0.3 # "다음 공격 마법 1번" 강화는 큰 공격에 쓴다
		if u.credits >= 5 and cost >= 4:
			s *= 1.6 # 모았으면 큰 것
		elif cost >= 3 and u.credits < 5:
			s *= 0.45 # 아직 모으는 중
		s *= 1.0 + 0.4 * u.cat_sum("atk") # 버프를 받았으면 지금 때린다
	elif kind == "debuff":
		var fresh := 0.0
		for e in effects:
			match String(e.t):
				"mark": fresh += 1.0 if en.mark_n(String(e.kind)) < 3 else 0.2 # 겹을 쌓는다
				"debuff": fresh += 0.0 if en.has_buff(e.cat) else 1.0
				"enemy_gauge", "gauge_zero": fresh += 0.5 if en.gauge > 500.0 else 0.1
				"stun": fresh += 1.5 if stun_worth(en) else 0.0
				"buff": fresh += 0.8
				"enemy_charge":
					var ct := charge_target(b)
					if ct != null:
						fresh += 2.5
						tgt = ct
				"spread":
					var mx := en
					for e2 in b.alive_of(b.enemies):
						if e2.mark_n(String(e.kind)) > mx.mark_n(String(e.kind)):
							mx = e2
					if b.alive_of(b.enemies).size() > 1 and mx.mark_n(String(e.kind)) >= 2:
						fresh += 0.6 * float(mx.mark_n(String(e.kind)))
						tgt = mx
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
		var tank := _tank(b)
		for e in effects:
			match String(e.t):
				"buff":
					if e.cat == "dmg_taken":
						fresh += (2.5 if pierce_coming(b) else 1.2) if heavy_coming(b) else 0.2
					elif e.has("count"):
						if who.has_skill_buff(sid):
							pass
						elif String(e.get("on", "")) == "skill" and who.credits - (cost if who == u else 0) + 1 < 3:
							pass # 다음 공격 1번 강화: 뒤따를 3비용 이상 공격이 없으면 걸지 않는다
						else:
							fresh += 1.4
					else:
						fresh += 0.0 if who.has_buff(e.cat) else 1.0
				"credits":
					if String(e.get("who", "target")) == "target" and target in ["ally", "ally_any"]:
						fresh += 0.0 if who.credits >= TData.ULT_COST else (2.0 if who.credits + int(e.v) + 1 >= TData.ULT_COST else 0.7)
					else:
						fresh += 0.7
				"hit_stack": fresh += 0.0 if u.has_buff("hit_stack") else 1.6
				"hp_cost":
					for w in b.alive_of(b.witches):
						if w.hp_ratio() < 0.4:
							fresh -= 1.0
				"gauge": fresh += 0.5 if who != u and who.gauge < 400.0 else 0.1
				"heal": fresh += 2.5 if low != null else 0.0
				"revive":
					fresh += (1.0 if pierce_coming(b) else 5.0) if dead != null else (2.0 if low != null else 0.0) # 관통 필살기 직전에 되살리면 바로 쓰러진다
				"invincible": fresh += 0.2 if pierce_coming(b) else (1.6 if heavy_coming(b) else 0.2)
				"taunt":
					if String(e.get("who", "target")) == "self":
						fresh += 0.0 if u.is_taunting() and u.has_buff("taunt") else 1.0
					else:
						fresh += 1.0 if heavy_coming(b) and tank != null and not tank.is_taunting() else 0.0
				"guts": fresh += 1.2 if low != null and not low.has_buff("guts") else 0.0
				"extend_buffs": fresh += 0.8 if who.buffs.size() >= 2 else 0.1
				"demerit_zero": fresh -= 0.5 if who.credits < 5 else 0.0
		s = 0.6 + 1.3 * fresh
		if cost >= 4 and u.credits < 5:
			s *= 0.6
		if target == "ally_any" and dead != null:
			tgt = dead
		elif target == "ally" and _has(effects, "taunt") and tank != null:
			tgt = tank # 도발이 붙은 마법은 맞을 사람(체력이 가장 많은 마녀)에게 — 회복이 같이 있어도
		elif target in ["ally", "ally_any"] and low != null and _heals(effects):
			tgt = low
		else:
			tgt = who
	return {"score": s, "tgt": tgt}


## 맞을 사람으로 세울 마녀: 체력이 가장 많은 살아 있는 마녀
static func _tank(b: TBattle) -> TUnit:
	var t: TUnit = null
	for w in b.alive_of(b.witches):
		if t == null or w.hp > t.hp:
			t = w
	return t


static func _heals(effects: Array) -> bool:
	for e in effects:
		if e.t in ["heal", "revive"]:
			return true
	return false


static func _has(effects: Array, t: String) -> bool:
	for e in effects:
		if String(e.t) == t:
			return true
	return false
