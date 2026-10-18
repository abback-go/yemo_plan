class_name TBattle
extends RefCounted
## 턴제 전투 규칙 엔진 — 노드 없이 숫자만 다룬다 (장면 TStage가 연출을 입히고, tools/test/turn_sim.gd가 헤드리스로 돌려 밸런스를 잰다).
## 흐름: next_actor() → (마녀면 플레이어가 고름 / 적이면 enemy_action()) → act() → end_action() → outcome()
## 모든 변화는 사건(Dictionary) 목록으로 돌려주어 연출이 순서대로 보여 줄 수 있다.
##   {"t":"hit", src, tgt, dmg, crit, weak, special, killed, invincible}  {"t":"buff"|"debuff", tgt, cat, v, dur}
##   {"t":"mark", tgt, kind}  {"t":"credits", tgt, v}  {"t":"gauge", tgt, v}  {"t":"heal", tgt, v}  {"t":"revive", tgt}
##   {"t":"invincible", tgt}  {"t":"zeroed", tgt}  {"t":"turn_credit", tgt}  {"t":"enemy_buff", tgt, v}

var witches: Array[TUnit] = []
var enemies: Array[TUnit] = []
var rng := RandomNumberGenerator.new()
var turn_no := 0
var actor: TUnit = null
var log: Array[String] = []
var last_action := "" ## 마지막 행동 이름 (화면 표시)


func setup(party: Array, enemy_ids: Array, state: Dictionary, seed_v := 0) -> void:
	rng.seed = seed_v if seed_v != 0 else randi()
	witches.clear()
	enemies.clear()
	for i in party.size():
		var wid := String(party[i])
		witches.append(TUnit.make_witch(wid, state.get(wid, {}), i))
	for i in enemy_ids.size():
		enemies.append(TUnit.make_enemy(String(enemy_ids[i]), i))
	turn_no = 0
	actor = null


func all_units() -> Array[TUnit]:
	var a: Array[TUnit] = []
	a.append_array(witches)
	a.append_array(enemies)
	return a


func alive_of(side_units: Array[TUnit]) -> Array[TUnit]:
	var a: Array[TUnit] = []
	for u in side_units:
		if u.alive:
			a.append(u)
	return a


func outcome() -> String:
	if alive_of(enemies).is_empty():
		return "win"
	if alive_of(witches).is_empty():
		return "lose"
	return ""


## 다음에 1000에 닿는 사람까지 시간을 흘린다. 돌려준 사람이 지금 행동할 차례 (게이지는 1000으로 맞춰 보임). 마녀면 크레딧 +1
func next_actor() -> TUnit:
	var alive := alive_of(all_units())
	if alive.is_empty():
		return null
	var best: TUnit = null
	var best_t := INF
	for u in alive:
		var t := _time_to_full(u)
		if t < best_t - 0.000001 or (absf(t - best_t) <= 0.000001 and _tie_before(u, best)):
			best = u
			best_t = t
	for u in alive:
		u.gauge += float(u.speed) * best_t
	best.gauge = maxf(best.gauge, TData.GAUGE_MAX)
	actor = best
	turn_no += 1
	if best.is_witch():
		best.credits = mini(best.credits + 1, TData.CREDIT_MAX)
	return best


func _time_to_full(u: TUnit) -> float:
	if u.gauge >= TData.GAUGE_MAX:
		return 0.0
	return (TData.GAUGE_MAX - u.gauge) / float(u.speed)


## 동시면: 게이지가 더 많은 쪽 → 속도가 높은 쪽 → 마녀 → 앞자리
func _tie_before(a: TUnit, b: TUnit) -> bool:
	if b == null:
		return true
	if absf(a.gauge - b.gauge) > 0.5:
		return a.gauge > b.gauge
	if a.speed != b.speed:
		return a.speed > b.speed
	if a.is_witch() != b.is_witch():
		return a.is_witch()
	return a.slot < b.slot


## 앞으로 n명의 차례 (지금 행동하는 사람부터). 버프로 바뀔 수 있으므로 "지금 상태 기준"의 예상
func preview(n := 8) -> Array[TUnit]:
	var out: Array[TUnit] = []
	var alive := alive_of(all_units())
	if alive.is_empty():
		return out
	var g := {}
	for u in alive:
		g[u] = u.gauge
	if actor != null and actor.alive:
		out.append(actor)
		g[actor] = 0.0
	while out.size() < n:
		var best: TUnit = null
		var best_t := INF
		for u in alive:
			var t := 0.0 if float(g[u]) >= TData.GAUGE_MAX else (TData.GAUGE_MAX - float(g[u])) / float(u.speed)
			var better := t < best_t - 0.000001
			if not better and absf(t - best_t) <= 0.000001 and best != null:
				var ga := float(g[u])
				var gb := float(g[best])
				better = ga > gb + 0.5 or (absf(ga - gb) <= 0.5 and (u.speed > best.speed or (u.speed == best.speed and (u.is_witch() and not best.is_witch() or (u.is_witch() == best.is_witch() and u.slot < best.slot)))))
			if better:
				best = u
				best_t = t
		for u in alive:
			g[u] = float(g[u]) + float(u.speed) * best_t
		g[best] = 0.0
		out.append(best)
	return out


func can_use(u: TUnit, skill_id: String) -> bool:
	var s := TData.skill(skill_id)
	if s.is_empty():
		return false
	if u.credits < int(s.cost):
		return false
	return not valid_targets(u, skill_id).is_empty()


## 고를 수 있는 대상 (단일 대상 마법). 전체·자신 대상은 [대표 하나]만 돌려준다
func valid_targets(u: TUnit, skill_id: String) -> Array[TUnit]:
	var s := TData.skill(skill_id)
	var out: Array[TUnit] = []
	match String(s.get("target", "enemy")):
		"enemy":
			out = alive_of(enemies)
		"enemies":
			if not alive_of(enemies).is_empty():
				out.append(alive_of(enemies)[0])
		"ally":
			out = alive_of(witches)
		"ally_any":
			for w in witches:
				out.append(w)
		"allies":
			out.append(u)
		"self":
			out.append(u)
	return out


func needs_target_pick(skill_id: String) -> bool:
	return String(TData.skill(skill_id).get("target", "enemy")) in ["enemy", "ally", "ally_any"]


# ═══════════════════════════════════════════════════════════
# 행동
# ═══════════════════════════════════════════════════════════

## 마녀의 기본 공격
func basic_attack(u: TUnit, tgt: TUnit) -> Array:
	var ev: Array = []
	var b: Dictionary = u.data.basic
	last_action = String(b.name)
	ev.append(_hit(u, tgt, float(b.mult), {}, false))
	if b.has("mark") and tgt.alive:
		tgt.marks[b.mark] = maxi(int(tgt.marks.get(b.mark, 0)), int(b.get("mark_dur", 2)))
		ev.append({"t": "mark", "tgt": tgt, "kind": b.mark})
	u.credits = mini(u.credits + TData.BASIC_BONUS, TData.CREDIT_MAX)
	ev.append({"t": "credits", "tgt": u, "v": TData.BASIC_BONUS})
	return ev


## 마법. tgt는 단일 대상 마법일 때만 쓰인다
func use_skill(u: TUnit, skill_id: String, tgt: TUnit) -> Array:
	var s := TData.skill(skill_id)
	var ev: Array = []
	u.credits -= int(s.cost)
	last_action = String(s.name)
	var effects: Array = s.get("effects", [])
	var targets := _resolve_targets(u, s, tgt)
	# 공격 직전 자가 버프 (pre)
	for e in effects:
		if e.t == "buff" and bool(e.get("pre", false)):
			ev.append(_apply_buff(u, u, e))
	var opts := {"skill": true}
	for e in effects:
		if e.t == "this_special":
			opts["this_special"] = e
		elif e.t == "ignore_def":
			opts["ignore_def"] = true
	if s.kind == "attack":
		for t in targets:
			var h := _hit(u, t, float(s.mult), opts, true)
			ev.append(h)
			for e in effects:
				if e.t == "on_crit" and bool(h.crit):
					for e2 in e.effects:
						ev.append_array(_apply_effect(u, t, e2, targets))
	for e in effects:
		if e.t in ["this_special", "ignore_def", "on_crit"] or (e.t == "buff" and bool(e.get("pre", false))):
			continue
		for t in targets:
			ev.append_array(_apply_effect(u, t, e, targets))
			if String(e.get("who", "target")) != "target":
				break # allies·enemies·self는 한 번만
	return ev


func _resolve_targets(u: TUnit, s: Dictionary, tgt: TUnit) -> Array[TUnit]:
	var out: Array[TUnit] = []
	match String(s.get("target", "enemy")):
		"enemy", "ally", "ally_any":
			if tgt != null:
				out.append(tgt)
		"enemies":
			out = alive_of(enemies)
		"allies":
			out = alive_of(witches)
		"self":
			out.append(u)
	return out


func _apply_effect(u: TUnit, t: TUnit, e: Dictionary, targets: Array[TUnit]) -> Array:
	var ev: Array = []
	var who := String(e.get("who", "target"))
	var recv: Array[TUnit] = []
	match who:
		"target": recv.append(t)
		"self": recv.append(u)
		"allies": recv = alive_of(witches)
		"enemies": recv = alive_of(enemies)
	match String(e.t):
		"buff":
			for r in recv:
				if r.alive:
					ev.append(_apply_buff(u, r, e))
		"debuff":
			for r in recv:
				if r.alive:
					r.add_buff({"cat": e.cat, "v": float(e.v), "dur": int(e.dur), "clock": "own", "name": TData.CAT_NAME.get(e.cat, e.cat)})
					ev.append({"t": "debuff", "tgt": r, "cat": e.cat, "v": float(e.v), "dur": int(e.dur)})
		"mark":
			for r in recv:
				if r.alive:
					r.marks[e.kind] = maxi(int(r.marks.get(e.kind, 0)), int(e.dur))
					ev.append({"t": "mark", "tgt": r, "kind": e.kind})
		"credits":
			for r in recv:
				if r.alive:
					var before := r.credits
					r.credits = mini(r.credits + int(e.v), TData.CREDIT_MAX)
					ev.append({"t": "credits", "tgt": r, "v": r.credits - before})
		"gauge":
			for r in recv:
				if r.alive and r != actor:
					r.gauge += TData.GAUGE_MAX * float(e.v)
					ev.append({"t": "gauge", "tgt": r, "v": float(e.v)})
				elif r == actor:
					ev.append({"t": "gauge", "tgt": r, "v": 0.0}) # 자기 차례에 자기 게이지는 올려도 행동 뒤 0이 됨
		"heal":
			for r in recv:
				if r.alive:
					var v := r.heal(int(round(float(r.max_hp) * float(e.pct))))
					ev.append({"t": "heal", "tgt": r, "v": v})
		"revive":
			for r in recv:
				if r.alive:
					var v := r.heal(int(round(float(r.max_hp) * float(e.pct))))
					ev.append({"t": "heal", "tgt": r, "v": v})
				else:
					r.revive(float(e.pct))
					ev.append({"t": "revive", "tgt": r})
		"invincible":
			for r in recv:
				if r.alive:
					r.add_buff({"cat": "invincible", "v": 1.0, "dur": int(e.dur), "clock": "enemy", "name": "무적"})
					ev.append({"t": "invincible", "tgt": r})
		"demerit_zero":
			for r in recv:
				r.zero_after_turn = turn_no
				ev.append({"t": "demerit", "tgt": r})
	return ev


func _apply_buff(_u: TUnit, r: TUnit, e: Dictionary) -> Dictionary:
	var b := {"cat": e.cat, "v": float(e.get("v", 0.0)), "dur": int(e.dur), "clock": "enemy" if e.cat in ["dmg_taken"] else "own", "name": TData.CAT_NAME.get(e.cat, e.cat)}
	if e.has("mark"):
		b["mark"] = e.mark
	if e.has("el"):
		b["el"] = e.el
	r.add_buff(b)
	return {"t": "buff", "tgt": r, "cat": e.cat, "v": float(e.get("v", 0.0)), "dur": int(e.dur), "el": e.get("el", ""), "mark": e.get("mark", "")}


## 적의 행동 (의도대로). 돌려준 사건을 연출한 뒤 end_action
func enemy_action(u: TUnit) -> Array:
	var ev: Array = []
	var it := u.intent()
	last_action = TData.INTENT_NAME.get(it.get("k", "attack"), "공격")
	var alive_w := alive_of(witches)
	match String(it.get("k", "attack")):
		"attack", "heavy":
			if not alive_w.is_empty():
				var t: TUnit = alive_w[rng.randi_range(0, alive_w.size() - 1)]
				ev.append(_enemy_hit(u, t, float(it.get("mult", 1.0))))
		"aoe":
			for t in alive_w:
				ev.append(_enemy_hit(u, t, float(it.get("mult", 1.0))))
		"buff":
			u.add_buff({"cat": "atk", "v": float(it.get("v", 0.3)), "dur": int(it.get("dur", 3)), "clock": "own", "name": "공격력"})
			ev.append({"t": "enemy_buff", "tgt": u, "v": float(it.get("v", 0.3))})
	u.intent_i += 1
	return ev


## 행동이 끝남: 시계 감기 · 대가 · 게이지 0
func end_action(u: TUnit) -> Array:
	var ev: Array = []
	u.gauge = 0.0
	u.on_own_acted()
	if u.is_witch():
		if u.zero_after_turn >= 0 and turn_no > u.zero_after_turn:
			u.zero_after_turn = -1
			if u.credits > 0:
				u.credits = 0
				ev.append({"t": "zeroed", "tgt": u})
	else:
		for w in witches:
			if w.alive:
				w.on_enemy_acted()
	actor = null
	return ev


# ═══════════════════════════════════════════════════════════
# 피해 공식 (combat_proto.md §3)
# ═══════════════════════════════════════════════════════════

func _hit(src: TUnit, tgt: TUnit, mult: float, opts: Dictionary, is_skill: bool) -> Dictionary:
	var el := src.attack_element()
	var elem := 1.0
	var weak := false
	if el != "" and el == String(TData.WEAK_TO.get(tgt.element, "")):
		elem = TData.WEAK
		weak = true
	elif src.special and not src.has_element_buff():
		elem = TData.SPECIAL
	var atk_sum := src.cat_sum("atk")
	var crit_rate := minf(TData.CRIT_BASE + src.cat_sum("crit_rate"), 1.0)
	var crit := rng.randf() < crit_rate
	var crit_mult := 1.0
	if crit:
		crit_mult = TData.CRIT_MULT + src.cat_sum("crit_dmg", tgt, el)
	var special := src.cat_sum("special", tgt, el)
	if opts.has("this_special"):
		var ts: Dictionary = opts.this_special
		if tgt.marks.has(ts.mark):
			special += float(ts.v)
	special = minf(special, float(TData.CAP.special))
	var final_sum := src.cat_sum("final")
	if is_skill:
		final_sum += float(src.equip_data().get("skill_final", 0.0))
	final_sum = minf(final_sum, float(TData.CAP.final))
	var def_v := 0.0 if opts.get("ignore_def", false) else tgt.def_rate
	var def_f := clampf(1.0 - def_v + tgt.cat_sum("def_down"), TData.DEF_MIN, TData.DEF_MAX)
	var r := rng.randf_range(TData.RAND_LO, TData.RAND_HI)
	var dmg := int(round(float(src.atk) * mult * elem * (1.0 + atk_sum) * crit_mult * (1.0 + special) * (1.0 + final_sum) * def_f * r))
	var killed := tgt.take_damage(dmg)
	src.dealt += dmg
	log.append("%s → %s %s%s%s %s" % [src.name, tgt.name, TData.fmt(dmg), " 크리" if crit else "", " 약점" if weak else "", "쓰러짐" if killed else ""])
	return {"t": "hit", "src": src, "tgt": tgt, "dmg": dmg, "crit": crit, "weak": weak, "special": special > 0.0, "killed": killed, "invincible": false, "el": el}


func _enemy_hit(src: TUnit, tgt: TUnit, mult: float) -> Dictionary:
	if tgt.is_invincible():
		log.append("%s → %s 무적" % [src.name, tgt.name])
		return {"t": "hit", "src": src, "tgt": tgt, "dmg": 0, "crit": false, "weak": false, "special": false, "killed": false, "invincible": true, "el": ""}
	var atk_f := clampf(1.0 + src.cat_sum("atk") - src.cat_sum("atk_down"), 0.3, 4.0)
	var taken := 1.0 + tgt.cat_sum("dmg_taken") + float(tgt.equip_data().get("dmg_taken", 0.0))
	var r := rng.randf_range(TData.RAND_LO, TData.RAND_HI)
	var dmg := int(round(float(src.atk) * mult * atk_f * (1.0 - tgt.def_rate) * maxf(taken, 0.2) * r))
	var killed := tgt.take_damage(dmg)
	log.append("%s → %s %s%s" % [src.name, tgt.name, TData.fmt(dmg), " 쓰러짐" if killed else ""])
	return {"t": "hit", "src": src, "tgt": tgt, "dmg": dmg, "crit": false, "weak": false, "special": false, "killed": killed, "invincible": false, "el": ""}


## 예상 피해 (화면 안내용: 난수·크리 없이, 징표 특공은 지금 대상 기준)
func estimate(src: TUnit, tgt: TUnit, skill_id: String) -> int:
	var mult := 1.0
	var opts := {}
	var is_skill := skill_id != ""
	if is_skill:
		var s := TData.skill(skill_id)
		if s.get("kind", "") != "attack":
			return 0
		mult = float(s.mult)
		for e in s.get("effects", []):
			if e.t == "this_special":
				opts["this_special"] = e
			elif e.t == "ignore_def":
				opts["ignore_def"] = true
	else:
		mult = float(src.data.basic.mult)
	var el := src.attack_element()
	var elem := 1.0
	if el != "" and el == String(TData.WEAK_TO.get(tgt.element, "")):
		elem = TData.WEAK
	elif src.special and not src.has_element_buff():
		elem = TData.SPECIAL
	var special := src.cat_sum("special", tgt, el)
	if opts.has("this_special") and tgt.marks.has(opts.this_special.mark):
		special += float(opts.this_special.v)
	var final_sum := src.cat_sum("final") + (float(src.equip_data().get("skill_final", 0.0)) if is_skill else 0.0)
	var def_v := 0.0 if opts.get("ignore_def", false) else tgt.def_rate
	var def_f := clampf(1.0 - def_v + tgt.cat_sum("def_down"), TData.DEF_MIN, TData.DEF_MAX)
	return int(round(float(src.atk) * mult * elem * (1.0 + src.cat_sum("atk")) * (1.0 + minf(special, float(TData.CAP.special))) * (1.0 + minf(final_sum, float(TData.CAP.final))) * def_f))
