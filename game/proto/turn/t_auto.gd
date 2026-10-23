class_name TAuto
extends RefCounted
## 마녀의 자동 선택 (시험·시연용 — 사람 대신 고른다). 장착한 마법을 "지금 새로 주는 것"으로 점수 매겨 가장 높은 것을 쓰고,
## 점수가 낮으면 기본 공격으로 크레딧을 모은다. tools/test/turn_sim.gd(밸런스)와 TStage(자동 플레이)가 같이 쓴다.
## 크레딧 7이면 대마법, 5~6이면 큰 공격 마법을 아껴 7로 모은다. 징표는 겹을 쌓고, 터뜨리기는 겹이 3 이상일 때, 기절은 위험한 의도 앞에서.
## 단계 E (review_E E0): 공격 대마법이 있는 마녀는 대마법을 모은다 (크레딧이 적어도 — 1비용 공격만 돌리다 7에 못 닿는 일을 막음) — 공격 마법은
##   "값 − 실제 비용 × 대마법 크레딧당 값 ≥ 기본 공격 값 + 크레딧 1 × 대마법 크레딧당 값"일 때만 쓴다 (값 = 배율 × 맞는 적 수 × 크리 확정 1.4 × 이 공격만 특공,
##   실제 비용 = 비용 − 조건이 맞는 환급). 징표가 없을 때의 징표 심기 · 3겹 이상 터뜨리기는 예외 · 게이지 점수 = v × 2.5 (딜러 게이지 < 60%) ·
##   보조·디버프는 1.8부터 쓴다 · 3비용 이상 아끼기(×0.4)는 공격 마법에만.
## D2·E2 (combat_proto.md §27.3): 크레딧 한 개의 값 λ = (대마법 값 − 기본 공격 값) / (7 − 환급 + 덤 1) — "기본 공격 + 대마법" 순환과 비기는 값 (예전 값/7은 27% 컸다) ·
##   공격 마법 값에 공격 직전 자기 강화·방어 무시·지금 크리 확률을 넣고, 비교할 기본 공격엔 횟수제 기본 공격 버프를 곱함 · 크레딧 6부터는 3비용 이상 공격 마법을 쓰지 않고
##   대마법을 마저 모음(SAVE_AT) · 대가(이 행동 뒤 크레딧 0)가 걸린 차례엔 가장 센 공격 마법을 바로 씀 · trigger는 비용 + 1을 남김.
## 단계 B: 횟수제 기본 공격 버프가 있으면 기본 공격 · 차지가 차면 차지 감소 · 관통 필살기 앞에선 무적 대신 받는 피해 감소.
## 빌드 원형 시험(tools/test/turn_sim.gd)은 plan으로 역할을 정해 준다 (비어 있으면 위 규칙만):
##   dealer: 딜러 id · ult_only: [대마법·기본 공격만 쓰는 id] · battery: [딜러에게 크레딧을 몰아주는 id — 자기 대마법은 안 씀]
##   push: [딜러 게이지를 올려 차례를 몰아주는 id]
##   trigger: {id: {skill, at}} — 딜러가 다음 차례에 at 크레딧이 되고 공격력 버프가 있을 때 그 마법을 딜러에게 (대가 몰빵의 마지막 신호)
##   guard: [지키는 id] — 가장 큰 보호 마법(받는 피해 감소·무적·공격력 다운·되살림)의 비용을 남겨 두고, 위험한 의도·차지 가득 앞에서 쓴다 (버티기 원형, 단계 E)
## 단계 F-2 (review_H §10.4 — 새 적 행동에 대응): ① 막아서는 적이 있으면 그 적만 · 방어 태세 중인 적은 다른 적이 있으면 피함 · 자폭 차지가 찬 적을 먼저
##   ② 방어 태세 중인 적 하나만 남았으면 공격 대마법·3비용 이상 공격 마법을 미룸(위험이 없을 때) · 태세 알약이 보이면 지금 큰 공격(모으기 예외)
##   ③ 크레딧 흩기·봉인 알약이 보이면 모으지 않고 씀 ④ 징표 털기가 보이면 1겹부터 터뜨리기 ⑥ 맞는 적이 셋 이상이면 광역 공격 마법은 모으기·횟수제 기본 공격보다 먼저
## 단계 F-3 (combat_proto.md §27.8 — 무리 판단): 적 셋 이상이고 광역 공격 마법을 장착했으면 ⑦ 단일 공격 대마법 차례에 크레딧당 값이 더 큰 광역 공격 마법을 먼저
##   ⑧ 한 명에게 거는 징표 디버프 점수 ×0.3 (크레딧을 광역에) · 특성 특공(this_special trait)은 TBattle.special_hits로
## R5 (review_M M1·M2 — combat_proto.md §27.14): 비용은 TBattle.cost_now(비용 감소 반영) · 최대 체력 = 받는 피해 감소와 같은 때 · 정화 = 나쁜 효과·봉인이 걸린 아군 수 ·
##   약화 막기 = 약화·봉인·흩기·기절 공격 알약이 보일 때 · 예약 크레딧 = 받는 마녀가 다음 차례에 대마법을 쓸 때(넘치지 않음)도 값 · 비용 감소 = 받는 마녀의 3비용 이상 장착 마법 ·
##   조건 비례(scale)는 값·점수에 곱함 — 자기 체력 비례 마법엔 "체력 45% 아래 대가 ×0.3"을 빼고, 쌓인 힘 4겹 이상이면 되돌려 베기 점수 ×1.3 (종언참 앞 준비)

const USE_AT := 2.2 ## 공격 마법: 이 점수 아래면 기본 공격
const USE_AT_SUP := 1.8 ## 보조·디버프 마법의 기준 (review_E E0 ④)
const SAVE_AT := 6 ## 공격 대마법이 있는 마녀: 크레딧이 이만큼이면 3비용 이상 공격 마법을 쓰지 않고 대마법을 마저 모은다 (D2·E2)
const DANGER := ["heavy", "aoe", "stun_attack", "finisher"] ## 미리 막을 만한 적 의도
static var plan := {}


static func _in(key: String, u: TUnit) -> bool:
	return (plan.get(key, []) as Array).has(u.id)


static func pick(b: TBattle, u: TUnit) -> Dictionary:
	var a := _pick(b, u)
	if String(a.get("kind", "")) == "skill" and a.get("target") is TUnit and not (a.target as TUnit).is_witch():
		a["target"] = big_target(b, u, String(a.skill), a.target) # 큰 한 방은 넘치지 않는 적에게 (F-4 — 총괄 결정 ①)
	return a


## 큰 단일 공격(3비용 이상·대마법)의 대상: 고를 수 있는 적 중 "넘치지 않는 피해" min(예상 기대 피해, 지금 줄 체력)이 가장 큰 적 (5% 넘게 클 때만 바꿈).
## 자폭 직전 졸개를 노린 것은 그대로. 이그니스의 체력 비례(hp_bonus)·약점·특공·터뜨리기는 est_info가 다 셈 (F-4 — review_J §2.2 넘친 피해 43%)
static func big_target(b: TBattle, u: TUnit, sid: String, en: TUnit) -> TUnit:
	var sk := TData.skill(sid)
	if en == null or String(sk.get("kind", "")) != "attack" or String(sk.get("target", "")) != "enemy":
		return en
	if not (bool(sk.get("ultimate", false)) or int(sk.get("cost", 0)) >= 3):
		return en
	if String(en.intent().get("k", "")) == "finisher" and bool(en.intent().get("self_ko", false)):
		return en
	var cands := b.foe_targets()
	var open: Array[TUnit] = []
	for e in cands:
		if not e.has_buff("dmg_cut"):
			open.append(e)
	if not open.is_empty():
		cands = open
	var best := en
	var best_v := _eff_dmg(b, u, sid, en)
	for t in cands:
		var v := _eff_dmg(b, u, sid, t)
		if v > best_v * 1.05:
			best = t
			best_v = v
	return best


## 넘치지 않는 기대 피해: min(예상 × 크리 기대, 지금 줄 체력)
static func _eff_dmg(b: TBattle, u: TUnit, sid: String, t: TUnit) -> float:
	var info := b.est_info(u, t, sid)
	if info.is_empty():
		return 0.0
	var ex := float(info.est) if bool(info.sure) else float(info.est) + float(info.rate) * (float(info.crit) - float(info.est))
	return minf(ex, float(t.hp))


static func _pick(b: TBattle, u: TUnit) -> Dictionary:
	var en := enemy_for(b, u)
	var dealer := dealer_of(b)
	var ult := String(u.data.get("ultimate", ""))
	var spend := _spend_now(b, u)
	if _in("battery", u) and dealer != u and dealer.alive:
		ult = "" # 배터리는 자기 대마법을 아끼고 딜러에게 몰아준다
	if ult != "" and b.can_use(u, ult) and String(TData.skill(ult).kind) == "support" and _protective(ult) and not _danger(b):
		ult = "" # 지키는 대마법(무적·받는 피해·회복·되살림)은 위험한 의도·쓰러진/낮은 아군이 있을 때까지 아낀다
	if ult != "" and b.can_use(u, ult) and String(TData.skill(ult).kind) == "attack" and _guarded(en) and not _danger(b) and not spend:
		ult = "" # ② 방어 태세 중인 적만 남음: 공격 대마법은 태세가 풀린 차례로 미룬다 (F-2)
	if ult != "" and b.can_use(u, ult) and String(TData.skill(ult).kind) == "attack" and String(TData.skill(ult).target) == "enemy" and not spend:
		var crowd := _aoe_pick(b, u, en, true)
		if not crowd.is_empty():
			return crowd # 무리(적 셋 이상): 단일 대마법보다 크레딧당 값이 큰 광역 공격 마법 (F-3 — 광역 원형이 무리 전투에서 크레딧을 단일 대마법에 쓰던 것)
	if ult != "" and b.can_use(u, ult):
		var t: TUnit = en
		if not b.needs_target_pick(ult) or String(TData.skill(ult).target) != "enemy":
			t = b.valid_targets(u, ult)[0]
		return {"kind": "skill", "skill": ult, "target": t}
	if u.zero_after_turn >= 0 and en != null:
		# 대가(이 행동 뒤 크레딧 0)가 걸려 있으면 남는 크레딧의 값이 0 — 쓸 수 있는 가장 센 공격 마법을 바로 쓴다 (D2·E2)
		var dump := ""
		var dv := float(u.data.basic.mult) * 1.5
		for sid in u.equipped:
			var sk := TData.skill(sid)
			if String(sk.kind) == "attack" and b.can_use(u, sid) and _attack_value(b, sk, en, u) > dv:
				dump = sid
				dv = _attack_value(b, sk, en, u)
		if dump != "":
			return {"kind": "skill", "skill": dump, "target": en}
	if _in("ult_only", u):
		return {"kind": "basic", "skill": "basic", "target": en}
	if _in("battery", u):
		var fd := _feed(b, u, dealer)
		if not fd.is_empty():
			return fd
		if b.chain_stage == 0 and dealer.alive and dealer.credits < TData.ULT_COST and not spend:
			var hl := _heal_pick(b, u, en, dealer)
			if not hl.is_empty():
				return hl # 모으는 배터리도 다친 아군은 고친다 (F-4 — 배터리 plan이 회복을 안 써 전멸하던 것, review_J §2.2 C1·C2)
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
		if u.credits < TData.cost_of(tsid) + 1: # 비용 + 1을 남겨 둔다 (D2·E2: + 2면 별빛 역류보다 자기 대마법이 먼저 차서 역류가 판당 5번뿐이었다)
			return {"kind": "basic", "skill": "basic", "target": en}
	var aoe := _aoe_pick(b, u, en)
	if not aoe.is_empty():
		return aoe # ⑥ 맞는 적이 셋 이상: 광역 공격 마법 (F-2 — 예전엔 대마법 모으기·횟수제 기본 공격에 밀려 무리 전투에서 한 번도 안 씀)
	if _counting(u, "basic"):
		return {"kind": "basic", "skill": "basic", "target": en} # 횟수제 기본 공격 버프가 남아 있으면 기본 공격 (D2·E2에서 "곧 끝날 때만"을 재 봤으나 버프가 겹쳐 버려지고 충전을 다시 걸어 B1 보스가 20.9 → 24.7분 — 되돌림)
	var guard_cost := 0
	if _in("guard", u):
		var gd := _guard_pick(b, u, en, dealer)
		if not gd.is_empty():
			return gd
		for sid in u.equipped:
			if _guards(sid):
				guard_cost = maxi(guard_cost, TData.cost_of(sid))
	# 공격 대마법을 모으는 중 (E0 ①): 기본 공격(+크레딧)보다 값이 낮은 공격 마법은 쓰지 않는다
	var ult_pc := 0.0
	var basic_v := float(u.data.basic.mult) * _count_boost(u, "basic") # 횟수제 기본 공격 버프가 있으면 그만큼 센 기본 공격과 비교 (D2·E2)
	if ult != "" and not _in("battery", u) and String(TData.skill(ult).kind) == "attack" and not spend:
		# 크레딧 한 개의 값 λ (D2·E2): "기본 공격만 + 대마법" 순환과 비기는 값 — 기본 공격 b + (차례 1 + 덤 1)λ = 대마법 M + (차례 1 − (7 − 환급))λ
		#   → λ = (M − b) / (7 − 환급 + 덤). 예전 M / (7 − 환급)은 차례마다 오는 +1과 기본 공격이 대신 못 하는 몫을 빼먹어 λ를 27% 크게 잡았다 (10배: 1.43 → 1.125)
		var us := TData.skill(ult)
		ult_pc = maxf(_attack_value(b, us, en, u) - basic_v, 0.1) / float(maxi(TData.ULT_COST - _refund(us, en) + TData.BASIC_BONUS, 1))
	var best_sid := ""
	var best_tgt: TUnit = null
	var best := 0.0
	for sid in u.equipped:
		if not b.can_use(u, sid):
			continue
		var sk := TData.skill(sid)
		var atk := String(sk.kind) == "attack"
		if guard_cost > 0 and not _guards(sid) and u.credits - TBattle.cost_now(u, sid) < guard_cost and not _has(sk.get("effects", []), "taunt") and not _heals(sk.get("effects", [])):
			continue # 지키는 마녀: 큰 보호 마법 비용은 남긴다 (도발·회복은 예외)
		if ult_pc > 0.0 and String(sk.kind) == "support" and String(sk.target) == "self" and not _has_count(sk):
			continue # 모으는 중엔 자기 강화(검기 두르기 등)에 크레딧을 쓰지 않는다 — 횟수제(다음 공격 1번·기본 공격 3번)는 대마법·기본 공격에 붙으므로 예외
		if atk and int(sk.cost) >= 3 and _guarded(en) and String(sk.target) != "enemies" and not spend and not _danger(b):
			continue # ② 방어 태세 중인 적 하나: 큰 단일 공격은 미룬다
		if atk and ult_pc > 0.0 and not _save_exempt(sk, en):
			var net := float(TBattle.cost_now(u, sid) - _refund(sk, en))
			if _attack_value(b, sk, en, u) - net * ult_pc < basic_v + float(TData.BASIC_BONUS) * ult_pc:
				continue
		var r := score(b, u, sid, en, dealer)
		var sc := float(r.score)
		if atk and ult_pc > 0.0 and u.credits >= SAVE_AT and int(sk.cost) >= 3 and not _save_exempt(sk, en):
			continue # 공격 대마법이 두 차례 안: 크레딧 5부터는 대마법을 마저 모은다 (D2·E2 — ×0.4로는 배율 높은 마법을 못 막아 대마법이 사라졌다)
		if atk and ult != "" and u.credits >= 5 and int(sk.cost) >= 3 and not _in("battery", u):
			sc *= 0.4 # 대마법까지 한 차례 — 큰 공격 마법은 아낀다
		var need := USE_AT if atk else USE_AT_SUP
		if sc >= need and sc - need > best:
			best = sc - need
			best_sid = sid
			best_tgt = r.tgt
	if best_sid != "":
		return {"kind": "skill", "skill": best_sid, "target": best_tgt}
	return {"kind": "basic", "skill": "basic", "target": en}


## 공격 마법의 대략 값 (배율 × 맞는 적 수 × 크리 확정 1.4 × 이 공격만 특공 × 공격 직전 자기 강화 × 방어 무시 + 터뜨리기 겹) — 대마법 모으기 판단용
static func _attack_value(b: TBattle, sk: Dictionary, en: TUnit, u: TUnit = null) -> float:
	var v := float(sk.get("mult", 0.0))
	# 지금 크리 확률 (u가 있으면) — 이미 크리가 거의 확정인 마녀에게 크리 강화·확정 크리의 값은 작다
	var cr := 0.2
	if u != null:
		cr = minf(TData.CRIT_BASE + u.cat_sum("crit_rate") + float(u.equip_data().get("crit_rate", 0.0)) + (en.cat_sum("crit_taken") if en != null else 0.0), 1.0)
	var ck := TData.CRIT_MULT - 1.0
	if String(sk.get("target", "")) == "enemies":
		v *= float(maxi(b.alive_of(b.enemies).size(), 1))
	for e in sk.get("effects", []):
		match String(e.t):
			"buff": # 공격 직전 자기 강화 (pre) — 이 공격에 바로 붙는다 (D2·E2: 예전엔 값에 안 넣어 강한 마법을 낮게 봤다)
				if bool(e.get("pre", false)) and String(e.get("who", "self")) == "self":
					match String(e.get("cat", "")):
						"atk", "final":
							v *= 1.0 + float(e.v)
						"crit_rate":
							v *= (1.0 + minf(cr + float(e.v), 1.0) * ck) / (1.0 + cr * ck)
						"crit_dmg":
							v *= 1.0 + float(e.v) * 0.3
			"sure_crit":
				v *= (1.0 + ck) / (1.0 + cr * ck)
			"ignore_def": # 이 공격만 방어 무시 — 방어가 높은 보스에게 큰 몫 (D2·E2)
				if en != null:
					var dd := en.cat_sum("def_down")
					v *= clampf(1.0 + dd, TData.DEF_MIN, TData.DEF_MAX) / clampf(1.0 - en.def_rate + dd, TData.DEF_MIN, TData.DEF_MAX)
			"burst":
				if en != null:
					v += float(e.per) * float(en.mark_n(String(e.mark)))
			"this_special":
				if TBattle.special_hits(e, en):
					v *= 1.0 + float(e.v)
			"hp_bonus": # 체력 비례 (F-4)
				v *= 1.0 + TBattle.hp_bonus_of(e, en)
			"scale": # 조건 비례 (R5)
				v *= 1.0 + TBattle.scale_of(e, u)
	if bool(sk.get("ultimate", false)) and u != null:
		v *= 1.0 + u.cat_sum("ult_dmg") # 대마법 위력 버프 (F-4)
	return v


## 이 공격으로 자신에게 돌아오는 크레딧 (조건 없는 것 + 맞기 전 조건이 맞는 환급)
static func _refund(sk: Dictionary, en: TUnit) -> int:
	var n := 0
	for e in sk.get("effects", []):
		if String(e.t) == "credits" and String(e.get("who", "target")) == "self":
			if not e.has("if_mark") or (en != null and en.marks.has(String(e.if_mark))):
				n += int(e.v)
	return n


static func _has_count(sk: Dictionary) -> bool:
	for e in sk.get("effects", []):
		if e.has("count"):
			return true
	return false


## 모으는 중에도 쓸 공격: 징표가 없을 때의 징표 심기 · 3겹 이상 터뜨리기 (징표 털기가 보이면 1겹부터) · 태세 알약이 보이는 적에게 지금 (F-2 ②④)
static func _save_exempt(sk: Dictionary, en: TUnit) -> bool:
	if en == null:
		return false
	var ek := String(en.intent().get("k", ""))
	if ek == "guard" and not en.has_buff("dmg_cut"):
		return true
	for e in sk.get("effects", []):
		match String(e.t):
			"mark":
				if String(e.get("who", "target")) == "target" and not en.marks.has(String(e.kind)):
					return true
			"burst":
				if en.mark_n(String(e.mark)) >= (1 if ek == "purge" else 3):
					return true
	return false


## 방어 태세 중인 적인가 (받는 피해 감소 30% 이상)
static func _guarded(en: TUnit) -> bool:
	return en != null and en.cat_sum("dmg_cut") >= 0.3


## 크레딧을 들고 있으면 잃는 의도가 보임: 크레딧 흩기(전원) · 봉인(크레딧 5 이상일 때) (F-2 ③)
static func _spend_now(b: TBattle, u: TUnit) -> bool:
	for e in b.alive_of(b.enemies):
		var k := String(e.intent().get("k", ""))
		if k == "scatter" and u.credits >= 3:
			return true
		if k == "seal" and u.credits >= 5:
			return true
	return false


## ⑥ 광역: 맞는 적이 셋 이상이면 장착한 광역 공격 마법 중 값(배율 × 적 수)이 가장 큰 것 — 순 비용 × 크레딧 값을 빼고도 기본 공격 + 크레딧 1개보다 크면
## vs_ult: 대마법을 쓸 수 있는 차례 — 크레딧당 값이 단일 대마법(값 ÷ 7)보다 큰 광역 공격 마법만 (F-3)
static func _aoe_pick(b: TBattle, u: TUnit, en: TUnit, vs_ult := false) -> Dictionary:
	var n := b.alive_of(b.enemies).size()
	if n < 3 or en == null or _in("ult_only", u) or _in("battery", u):
		return {}
	var basic_v := float(u.data.basic.mult) * _count_boost(u, "basic")
	var lam := 0.0
	var ult := String(u.data.get("ultimate", ""))
	if ult != "" and String(TData.skill(ult).kind) == "attack":
		var us := TData.skill(ult)
		lam = maxf(_attack_value(b, us, en, u) - basic_v, 0.1) / float(maxi(TData.ULT_COST - _refund(us, en) + TData.BASIC_BONUS, 1))
	var best := ""
	var best_v := basic_v + float(TData.BASIC_BONUS) * lam
	if vs_ult:
		best_v = 0.0
		var uv := _attack_value(b, TData.skill(ult), en, u) / float(TData.ULT_COST)
		for sid in u.equipped:
			var sk := TData.skill(sid)
			if String(sk.kind) != "attack" or String(sk.target) != "enemies" or not b.can_use(u, sid):
				continue
			var pc := _attack_value(b, sk, en, u) / float(maxi(int(sk.cost) - _refund(sk, en), 1))
			if pc > uv and pc > best_v:
				best_v = pc
				best = sid
		return {} if best == "" else {"kind": "skill", "skill": best, "target": en}
	for sid in u.equipped:
		var sk := TData.skill(sid)
		if String(sk.kind) != "attack" or String(sk.target) != "enemies" or not b.can_use(u, sid):
			continue
		var v := _attack_value(b, sk, en, u) - float(int(sk.cost) - _refund(sk, en)) * lam
		if v > best_v:
			best_v = v
			best = sid
	if best == "":
		return {}
	return {"kind": "skill", "skill": best, "target": en}


## 단일 대상 후보(막아서는 적이 있으면 그 적만) 중: 자폭 차지가 찬 적 → 이 마녀의 공격 속성이 약점인 적 → 불 약점(짚 골렘) → 체력이 가장 적은 적.
## 방어 태세 중인 적은 다른 적이 있으면 뺀다 (F-2 ①)
static func enemy_for(b: TBattle, u: TUnit = null) -> TUnit:
	var a := b.foe_targets()
	if a.is_empty():
		return null
	var open: Array[TUnit] = []
	for e in a:
		if not e.has_buff("dmg_cut"):
			open.append(e)
	if not open.is_empty():
		a = open
	for e in a:
		var it := e.intent()
		if String(it.get("k", "")) == "finisher" and bool(it.get("self_ko", false)):
			return e # 자폭 직전 졸개를 먼저 (F-2 ⑤)
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
	if dealer == null or not dealer.alive or dealer == u:
		return {}
	var best := ""
	var best_g := 0
	var late := "" ## 예약 크레딧 마법 (R5): 딜러가 대마법을 쓸 차례에 걸어도 넘치지 않음 — 대마법 뒤 차례에 들어온다
	var late_g := 0
	for sid in u.equipped:
		if not b.can_use(u, sid):
			continue
		var sk := TData.skill(sid)
		if String(sk.target) not in ["ally", "ally_any"]:
			continue
		var dg := _delay_credits(sk)
		if dg > late_g:
			late = sid
			late_g = dg
		for e in sk.get("effects", []):
			if String(e.t) == "credits" and String(e.get("who", "target")) == "target" and int(e.v) > best_g:
				best = sid
				best_g = int(e.v)
	if late != "" and dealer.delayed.is_empty() and (b.chain_stage > 0 or dealer.credits + 1 >= TData.ULT_COST):
		return {"kind": "skill", "skill": late, "target": dealer}
	if best == "" or dealer.credits >= TData.ULT_COST:
		return {}
	if b.chain_stage > 0 or dealer.credits + best_g + 1 >= TData.ULT_COST:
		return {"kind": "skill", "skill": best, "target": dealer}
	return {}


## 예약으로 들어오는 크레딧 합 (R5)
static func _delay_credits(sk: Dictionary) -> int:
	var n := 0
	for e in sk.get("effects", []):
		if String(e.t) == "delay":
			for e2 in e.get("effects", []):
				if String(e2.get("t", "")) == "credits":
					n += int(e2.v)
	return n


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


## 그 종류(on)의 횟수제 버프가 그 공격에 곱하는 대략 배수 (공격력·최종 = 1 + v · 크리 데미지 = 1 + 크리 확률 × v / 1.5 · 크리 확률 = 크리 기대값 비)
static func _count_boost(u: TUnit, on: String) -> float:
	var cr := minf(TData.CRIT_BASE + u.cat_sum("crit_rate") + float(u.equip_data().get("crit_rate", 0.0)), 1.0)
	var k := 1.0
	for bf in u.buffs:
		if not bf.has("count") or String(bf.get("on", "")) != on:
			continue
		match String(bf.get("cat", "")):
			"atk", "final":
				k *= 1.0 + float(bf.v)
			"crit_dmg":
				k *= 1.0 + cr * float(bf.v) / TData.CRIT_MULT
			"crit_rate":
				k *= (1.0 + minf(cr + float(bf.v), 1.0) * (TData.CRIT_MULT - 1.0)) / (1.0 + cr * (TData.CRIT_MULT - 1.0))
	return k


## 그 종류(on)의 횟수제 버프가 남아 있나. urgent = 남은 지속이 남은 횟수 이하 (지금 쓰지 않으면 일부를 버림)
static func _counting(u: TUnit, on: String, urgent := false) -> bool:
	for bf in u.buffs:
		if bf.has("count") and String(bf.get("on", "")) == on:
			if not urgent or int(bf.get("dur", 0)) <= int(bf.count):
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
					if e.has("trait"):
						s *= 1.0 + (float(e.v) if TBattle.special_hits(e, en) else 0.0) # 특성 특공 (F-3)
					else:
						s *= 1.0 + float(e.v) * float(en.mark_n(String(e.mark)))
				"burst":
					var n := en.mark_n(String(e.mark))
					var purge := String(en.intent().get("k", "")) == "purge"
					if bool(e.get("keep", false)):
						s *= (mult + float(e.per) * float(n)) / mult # 징표를 남기는 것(대화재)은 쌓을 필요 없이 겹만큼
					else:
						s *= (mult + float(e.per) * float(n)) / mult if (n >= 3 or (purge and n >= 1)) else 0.5 # 3겹 전에는 쌓아 둔다 (징표 털기가 보이면 지금)
				"hp_bonus":
					s *= 1.0 + TBattle.hp_bonus_of(e, en) # 체력이 많은 적일수록 (F-4)
				"hp_cost":
					if u.hp_ratio() < 0.45 and not _scales(effects, "self_hp_low"):
						s *= 0.3 # 체력이 낮으면 대가 마법을 아낌 — 자기 체력 비례(피 끓는 일격)는 낮을수록 세므로 뺌 (R5)
				"scale": # 조건 비례 (R5 — review_M M2)
					s *= 1.0 + TBattle.scale_of(e, u)
					if String(e.get("by", "")) == "stack" and u.stack_n() >= 4:
						s *= 1.3 # 쌓인 힘 4겹 이상: 되돌려 베기 → 다음 차례 종언참 (크리 데미지 준비)
				"credits":
					if not e.has("if_mark") or en.marks.has(e.if_mark):
						s *= 1.0 + 0.25 * float(e.v)
				"stun":
					if stun_worth(en) and (not e.has("if_mark") or en.marks.has(e.if_mark)):
						s *= 1.6
					elif en.stun_immune and e.has("else_charge") and charge_target(b) == en and (not e.has("if_mark") or en.marks.has(e.if_mark)):
						s *= 1.6 # 뇌격: 보스면 차지 −1 (F-4)
					elif en.stun_immune and e.has("else_debuff") and (not e.has("if_mark") or en.marks.has(e.if_mark)) and not en.has_buff(String(e.else_debuff.cat)):
						s *= 1.3 # 뇌격: 보스면 받는 크리 확률 (R2)
		if _counting(u, "skill"):
			s *= 1.6 if cost >= 3 else 0.3 # "다음 공격 마법 1번" 강화는 큰 공격에 쓴다
		if u.credits >= 5 and cost >= 4:
			s *= 1.6 # 모았으면 큰 것
		s *= 1.0 + 0.4 * u.cat_sum("atk") # 버프를 받았으면 지금 때린다
		if String(en.intent().get("k", "")) == "guard" and not en.has_buff("dmg_cut") and cost >= 3:
			s *= 1.3 # 태세 알약: 태세 전에 큰 공격 (F-2 ②)
		s *= 1.0 - minf(en.cat_sum("dmg_cut"), 0.7) * 0.5
	elif kind == "debuff":
		var fresh := 0.0
		var crowd := target == "enemy" and b.alive_of(b.enemies).size() >= 3 and _aoe_attacker(u)
		for e in effects:
			match String(e.t):
				"mark": fresh += (1.0 if en.mark_n(String(e.kind)) < 3 else 0.2) * (0.3 if crowd else 1.0) # 겹을 쌓는다 (적 셋 이상이고 광역 공격 마법이 있으면 한 명에게 거는 징표는 덜 — 크레딧을 광역에)
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
				"regen": # 지속 회복 (F-4): 다친 아군이 있고 아직 없으면
					var hurt := false
					for w in b.alive_of(b.witches):
						hurt = hurt or w.hp_ratio() < 0.75
					fresh += (1.4 if hurt else 0.3) if not who.has_buff("regen") else 0.0
				"buff":
					if e.cat == "ult_dmg": # 대마법 위력 (F-4): 공격 대마법이 있는 마녀가 이 마법의 크레딧까지 받으면 다음 차례에 대마법을 쓸 수 있을 때만
						var wu := String(who.data.get("ultimate", ""))
						var atk_ult := wu != "" and String(TData.skill(wu).kind) == "attack"
						var gain := 0
						for e2 in effects:
							if String(e2.t) == "credits" and String(e2.get("who", "target")) == "target":
								gain += int(e2.v)
						fresh += 1.0 if atk_ult and not who.has_buff("ult_dmg") and who.credits + gain + 1 >= TData.ULT_COST else 0.0
					elif e.cat == "dmg_taken":
						fresh += (2.5 if pierce_coming(b) else 1.2) if heavy_coming(b) else 0.2
					elif e.has("count"):
						if who.has_skill_buff(sid):
							pass
						elif String(e.get("on", "")) == "skill" and who.credits - (cost if who == u else 0) + 1 < 3:
							pass # 다음 공격 1번 강화: 뒤따를 3비용 이상 공격이 없으면 걸지 않는다
						else:
							fresh += 1.4
					elif e.cat == "element":
						fresh += 1.0 if _element_worth(who, en, String(e.get("el", ""))) else 0.0
					elif e.has("el") and who.attack_element() != String(e.el) and not _element_worth(who, en, String(e.el)):
						pass # 그 속성 공격에만 붙는 버프(장작 얹기의 화염 크리 데미지) — 속성이 안 바뀌면 0
					else:
						fresh += 0.0 if who.has_buff(e.cat) else 1.0
				"credits":
					if String(e.get("who", "target")) == "target" and target in ["ally", "ally_any"]:
						fresh += 0.0 if who.credits >= TData.ULT_COST else (2.0 if who.credits + int(e.v) + 1 >= TData.ULT_COST else 0.7)
					else:
						fresh += 0.7
				"hit_stack": fresh += 0.0 if u.has_buff("hit_stack") else 1.6
				# ── R5 지원 효과 넷 (review_M M1)
				"max_hp": # 최대 체력: 받는 피해 감소와 같은 때 (관통 필살기 앞이 가장 큼 — 무적이 안 통함)
					if not who.has_buff("max_hp"):
						fresh += (2.0 if pierce_coming(b) else 1.0) if heavy_coming(b) else 0.2
				"cleanse": # 정화: 나쁜 효과·봉인이 걸린 아군마다
					for w in b.alive_of(b.witches):
						if w.sealed > 0 or w.good_buffs() < w.buffs.size():
							fresh += 1.2
				"debuff_block": # 약화 막기: 약화·봉인·흩기·기절 공격 알약이 보이고 아직 막기가 없으면
					if _weaken_coming(b) and who.blocks_left() <= 0:
						fresh += 1.2
				"delay": # 예약 크레딧: 받는 마녀가 다음 차례에 대마법을 쓰면(넘침 없음) 큰 값
					var dg := 0
					for e2 in e.get("effects", []):
						if String(e2.get("t", "")) == "credits":
							dg += int(e2.v)
					if dg > 0 and who != u and who.delayed.is_empty():
						fresh += 2.0 if who.credits + 1 >= TData.ULT_COST or who.credits + 1 + dg >= TData.ULT_COST else 0.7
				"cost_down": # 비용 감소: 받는 마녀에게 3비용 이상 장착 마법이 있으면
					var big := 0
					for sid2 in who.equipped:
						if String(TData.skill(sid2).get("kind", "")) == "attack":
							big = maxi(big, TData.cost_of(sid2))
					fresh += 0.6 if big >= 3 and who.cost_cut() <= 0 else 0.0
				"hp_cost":
					for w in b.alive_of(b.witches):
						if w.hp_ratio() < 0.4:
							fresh -= 1.0
				"gauge": fresh += float(e.v) * 2.5 if who != u and who.gauge < 600.0 else 0.1 # 딜러 게이지 +60% = 딜러 0.6행동 (E0 ②)
				"heal": fresh += 2.5 if low != null else 0.0
				"revive":
					fresh += (1.0 if pierce_coming(b) else 5.0) if dead != null else (2.0 if low != null else 0.0) # 관통 필살기 직전에 되살리면 바로 쓰러진다
				"invincible":
					if _inv_open(b):
						fresh += 0.2 if pierce_coming(b) else (1.6 if heavy_coming(b) else 0.2)
				"taunt":
					if String(e.get("who", "target")) == "self":
						fresh += 0.0 if u.is_taunting() and u.has_buff("taunt") else 1.0
					else:
						fresh += 1.0 if heavy_coming(b) and tank != null and not tank.is_taunting() else 0.0
				"guts": fresh += 1.2 if low != null and not low.has_buff("guts") else 0.0
				"extend_buffs": fresh += 0.8 if who.buffs.size() >= 2 else 0.1
				"demerit_zero": fresh += 1.0 if who.credits + 1 >= TData.ULT_COST else -3.0 # 대가(크레딧 0)는 받는 마녀가 바로 대마법을 쓸 수 있을 때만
		s = 0.6 + 1.3 * fresh
		if cost >= 4 and u.credits < 5:
			s *= 0.6
		if target == "ally" and bool(sk.get("no_self", false)) and who == u:
			s = 0.0 # 자신 제외 마법을 받을 아군이 자신뿐 (R5 — 초침 밀기)
		if target == "ally_any" and dead != null:
			tgt = dead
		elif target == "ally" and _has(effects, "taunt") and tank != null:
			tgt = tank # 도발이 붙은 마법은 맞을 사람(체력이 가장 많은 마녀)에게 — 회복이 같이 있어도
		elif target in ["ally", "ally_any"] and low != null and _heals(effects):
			tgt = low
		else:
			tgt = who
	return {"score": s, "tgt": tgt}


## 그 by의 조건 비례(scale)가 있나 (R5)
static func _scales(effects: Array, by: String) -> bool:
	for e in effects:
		if String(e.get("t", "")) == "scale" and String(e.get("by", "")) == by:
			return true
	return false


## 약화·봉인·크레딧 흩기·기절 공격 알약이 보이는 적이 있나 (R5 — 약화 막기를 걸 때)
static func _weaken_coming(b: TBattle) -> bool:
	for e in b.alive_of(b.enemies):
		if String(e.intent().get("k", "")) in ["weaken", "seal", "scatter", "stun_attack"]:
			return true
	return false


## 속성 부여를 걸 가치: 이미 그 속성이 아니고, 적 약점이 그 속성이거나(지금 속성은 약점이 아님) 받은 징표 특공이 그 속성의 겹을 곱하게 될 때 (F-4 P1)
static func _element_worth(who: TUnit, en: TUnit, el: String) -> bool:
	if el == "" or who.attack_element() == el:
		return false
	if en != null and en.weak.has(el) and not en.weak.has(who.attack_element()):
		return true
	for bf in who.buffs:
		if String(bf.get("cat", "")) == "special" and String(TData.MARK_EL.get(String(bf.get("mark", "")), "")) == el:
			return true
	return false


## 광역 공격 마법을 장착했나
static func _aoe_attacker(u: TUnit) -> bool:
	for sid in u.equipped:
		var sk := TData.skill(sid)
		if String(sk.kind) == "attack" and String(sk.target) == "enemies":
			return true
	return false


## 보호 마법인가 (받는 피해 감소 · 무적 · 공격력 다운 · 되살림)
static func _guards(sid: String) -> bool:
	for e in TData.skill(sid).get("effects", []):
		var t := String(e.t)
		if t in ["invincible", "revive"] or (t == "buff" and String(e.get("cat", "")) == "dmg_taken") or (t == "debuff" and String(e.get("cat", "")) == "atk_down"):
			return true
	return false


## 회복·되살림·지속 회복 마법 중 점수가 기준을 넘는 것 (아군 체력 45% 미만 또는 쓰러짐이 있을 때만)
static func _heal_pick(b: TBattle, u: TUnit, en: TUnit, dealer: TUnit) -> Dictionary:
	var need := false
	for w in b.witches:
		need = need or not w.alive or w.hp_ratio() < 0.45
	if not need:
		return {}
	var best := ""
	var best_s := USE_AT_SUP
	var best_t: TUnit = null
	for sid in u.equipped:
		var effs: Array = TData.skill(sid).get("effects", [])
		if not (_heals(effs) or _has(effs, "regen")) or not b.can_use(u, sid):
			continue
		var r := score(b, u, sid, en, dealer)
		if float(r.score) > best_s:
			best_s = float(r.score)
			best = sid
			best_t = r.tgt
	return {} if best == "" else {"kind": "skill", "skill": best, "target": best_t}


## 지키는 마녀: 위험한 의도(강공격·전체·필살기)나 차지 가득 앞이면 쓸 수 있는 보호 마법 중 점수가 가장 높은 것
static func _guard_pick(b: TBattle, u: TUnit, en: TUnit, dealer: TUnit) -> Dictionary:
	if not heavy_coming(b):
		return {}
	var best := ""
	var best_s := USE_AT_SUP
	var best_t: TUnit = null
	for sid in u.equipped:
		if not _guards(sid) or not b.can_use(u, sid):
			continue
		var r := score(b, u, sid, en, dealer)
		if float(r.score) > best_s:
			best_s = float(r.score)
			best = sid
			best_t = r.tgt
	if best == "":
		return {}
	return {"kind": "skill", "skill": best, "target": best_t}


## 무적이 걸릴 마녀가 있나 (무적 내성 중이 아닌 살아 있는 마녀, §17.12)
static func _inv_open(b: TBattle) -> bool:
	for w in b.alive_of(b.witches):
		if w.inv_guard <= 0:
			return true
	return false


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
