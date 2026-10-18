class_name TBattle
extends RefCounted
## 턴제 전투 규칙 엔진 — 노드 없이 숫자만 다룬다 (장면 TStage가 연출을 입히고, tools/test/turn_sim.gd가 헤드리스로 돌려 밸런스를 잰다).
## 흐름: next_actor() → (기절이면 rest() / 마녀면 플레이어가 고름 / 적이면 enemy_action()) → end_action() → outcome()
##   outcome() == "wave"면 next_wave()로 다음 웨이브를 세운다 (combat_proto.md §6.3).
## 모든 변화는 사건(Dictionary) 목록으로 돌려주어 연출이 순서대로 보여 줄 수 있다.
##   {"t":"hit", src, tgt, dmg, crit, weak, special, killed, guts, broke, invincible, hp, max_hp, bar_i(맞은 뒤 — 화면의 보이는 값)}  {"t":"buff"|"debuff", tgt, cat, v, dur}
##   {"t":"mark", tgt, kind, n}  {"t":"burst", tgt, kind, n}  {"t":"credits", tgt, v}  {"t":"gauge", tgt, v}  {"t":"heal", tgt, v}  {"t":"revive", tgt}
##   {"t":"invincible", tgt}  {"t":"zeroed", tgt}  {"t":"enemy_buff", tgt, v}  {"t":"resist", tgt}  {"t":"stun"|"immune"|"stun_resist", tgt}
##   {"t":"taunt", tgt}  {"t":"guts_on", tgt}  {"t":"dispel", tgt}  {"t":"stun_skip", tgt}  [단계 E] {"t":"inv_guard", tgt} (무적 내성으로 무적이 안 걸림)
##   [단계 B] {"t":"chain", tgt, stage}  {"t":"charge_down", tgt, v}  {"t":"hp_cost", tgt, v}  {"t":"stack", tgt, n, v}  {"t":"hit_stack", tgt}
##   [단계 F-2 — review_H] {"t":"seal", tgt, ult}  {"t":"seal_resist", tgt}  {"t":"weaken", tgt, cat, v, dur}  {"t":"guard", tgt, v}  {"t":"cover", tgt}
##   {"t":"charge_up", tgt, v}  {"t":"summon", tgt(새 적), old(쓰러진 적), slot}  {"t":"self_ko", tgt}  {"t":"purge", tgt, n}  {"t":"credits", tgt, v < 0}(흩기)
##   hit 사건의 fall = 우두머리와 함께 사라진 적 목록
## 시험 훅 (tools/test/turn_rules_test.gd): fix_rand(피해 난수) · fix_crit(-1 판정 / 0 아님 / 1 크리) · fix_roll(디버프 성공 판정 난수)

var witches: Array[TUnit] = []
var enemies: Array[TUnit] = []
var rng := RandomNumberGenerator.new()
var turn_no := 0
var actor: TUnit = null
var log: Array[String] = []
var last_action := "" ## 마지막 행동 이름 (화면 표시)
var battle_id := ""
var waves: Array = [] ## 웨이브마다 적 항목 목록 (id 또는 {id, hp})
var wave_i := 0
var fix_rand := -1.0 ## ≥ 0이면 피해 난수를 이 값으로
var fix_crit := -1 ## 0/1이면 크리 판정을 이 값으로 (크리 확정은 그대로 크리)
var fix_roll := -1.0 ## ≥ 0이면 디버프 성공 판정 난수를 이 값으로
## 대마법 연쇄 (§13.6): 대마법을 쓴 마녀(chain_owner)의 다음 행동이 끝나기 전에 파티가 다시 대마법을 쓰면 단계 +1 (최대 3)
var chain_stage := 0
var chain_owner: TUnit = null
var chain_turn := -1
var max_chain := 0 ## 이 전투에서 닿은 가장 높은 연쇄 단계 (통계)
var _cur_skill := "" ## 지금 실행 중인 마법 id (버프에 sid로 남김 — 자동 선택이 "이 마법의 버프가 이미 있나"를 본다)
var resume := false ## 불러온 전투: 다음 next_actor()는 저장된 차례(actor)를 그대로 돌려준다 (크레딧 +1은 저장 전에 받음)
var _pre := {} ## 이번 마법을 맞기 전의 징표 (TUnit → [kind]) — if_mark 조건은 이것으로 본다 (§17.1)
var summoned := 0 ## 이 웨이브에서 부르기로 세운 적 수 (적 summon_cap과 견줌, review_H §2.1)


## party: 마녀 id 1~3개 (앞·중·뒤). foes: 전투 id(TData.BATTLES) 또는 적 id 목록(1웨이브).
## state: 마녀 id → {"equipped": [...], "equip": "", "equip_lv": 1, "skill_lv": {id: lv}}
func setup(party: Array, foes, state: Dictionary, seed_v := 0) -> void:
	rng.seed = seed_v if seed_v != 0 else randi()
	witches.clear()
	enemies.clear()
	if foes is String:
		battle_id = foes
		waves = TData.BATTLES[foes].waves
	else:
		battle_id = ""
		waves = [foes]
	for i in party.size():
		var wid := String(party[i])
		witches.append(TUnit.make_witch(wid, state.get(wid, {}), i))
	turn_no = 0
	actor = null
	wave_i = 0
	_spawn_wave(0)
	if foes is String:
		var sc := int(TData.BATTLES[foes].get("start_credits", 0))
		for w in witches:
			w.credits = maxi(w.credits, mini(sc, TData.CREDIT_MAX))
	# 패시브: 전투 시작 효과 (호라 — 첫 웨이브 때만)
	for w in witches:
		for e in w.passive:
			if String(e.t) == "start_gauge":
				var recv: Array[TUnit] = [w]
				if String(e.get("who", "self")) == "allies":
					recv = alive_of(witches)
				for r in recv:
					r.gauge += TData.GAUGE_MAX * float(e.v)


func _spawn_wave(i: int) -> void:
	enemies.clear()
	summoned = 0
	var list: Array = waves[i]
	for j in list.size():
		var item = list[j]
		var eid := String(item.id) if item is Dictionary else String(item)
		var over: Dictionary = item if item is Dictionary else {}
		enemies.append(TUnit.make_enemy(eid, j, over))
	for e in enemies:
		for p in e.passive:
			if String(p.get("t", "")) == "first_strike":
				e.gauge += TData.GAUGE_MAX * float(p.v) # 먼저 날아듦 (웨이브 시작 게이지 +v)
		decide_intent(e)


## 다음 웨이브를 세운다 (마녀 쪽은 그대로, §6.3). 새 적 목록을 돌려준다
func next_wave() -> Array[TUnit]:
	wave_i += 1
	_spawn_wave(wave_i)
	actor = null
	return enemies


func wave_count() -> int:
	return waves.size()


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


## "win" · "lose" · "wave"(지금 웨이브 전멸, 다음 웨이브 있음) · ""
func outcome() -> String:
	if alive_of(enemies).is_empty():
		return "wave" if wave_i < waves.size() - 1 else "win"
	if alive_of(witches).is_empty():
		return "lose"
	return ""


## 다음에 1000에 닿는 사람까지 시간을 흘린다. 돌려준 사람이 지금 행동할 차례 (게이지는 1000으로 맞춰 보임).
## 마녀면 크레딧 +1 (기절로 쉬는 차례는 없음 — 그 차례는 rest())
func next_actor() -> TUnit:
	if resume:
		resume = false
		if actor != null and actor.alive:
			return actor
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
	if best.is_witch() and not best.stunned:
		best.credits = mini(best.credits + 1 + int(best.equip_data().get("credits_per_turn", 0)), TData.CREDIT_MAX)
	return best


## 기절로 쉬는 차례 (행동 없음). 뒤에 end_action
func rest(u: TUnit) -> Array:
	last_action = "기절 — 쉼"
	u.last_act = "rest"
	log.append("%s 기절 — 쉼" % u.name)
	return [{"t": "stun_skip", "tgt": u}]


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


## 강화 레벨을 반영한 마법
func skill_of(u: TUnit, skill_id: String) -> Dictionary:
	return TData.skill_at(skill_id, int(u.skill_lv.get(skill_id, 1)))


func can_use(u: TUnit, skill_id: String) -> bool:
	var s := TData.skill(skill_id)
	if s.is_empty():
		return false
	if u.credits < int(s.cost):
		return false
	if sealed_out(u, skill_id):
		return false
	return not valid_targets(u, skill_id).is_empty()


## 봉인으로 못 쓰는 마법인가 (봉인 1 = 장착 마법·대마법 전부 · 2 = 대마법만, review_H §2.1). 기본 공격은 늘 된다
func sealed_out(u: TUnit, skill_id: String) -> bool:
	if u.sealed <= 0 or skill_id == "" or skill_id == "basic":
		return false
	return u.sealed == 1 or bool(TData.skill(skill_id).get("ultimate", false))


## 마녀가 단일 대상으로 고를 수 있는 적: 막아서는 적이 있으면 그 적만 (review_H §2.1 cover), 없으면 살아 있는 적 전부
func foe_targets() -> Array[TUnit]:
	var a := alive_of(enemies)
	var cv: Array[TUnit] = []
	for e in a:
		if e.has_buff("cover"):
			cv.append(e)
	return cv if not cv.is_empty() else a


## 고를 수 있는 대상 (단일 대상 마법). 전체·자신 대상은 [대표 하나]만 돌려준다
func valid_targets(u: TUnit, skill_id: String) -> Array[TUnit]:
	var s := TData.skill(skill_id)
	var out: Array[TUnit] = []
	match String(s.get("target", "enemy")):
		"enemy":
			out = foe_targets()
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

## 마녀의 기본 공격. 데이터 hits(기본 1)면 배율을 나눠 여러 번 맞힌다 (풀구르, §14.4)
func basic_attack(u: TUnit, tgt: TUnit) -> Array:
	var ev: Array = []
	var b: Dictionary = u.data.basic
	last_action = String(b.name)
	u.last_act = "basic"
	_pre = {}
	if tgt == null:
		return ev # 고를 적이 없음 (시험이 적을 직접 쓰러뜨린 때 등)
	var hits := maxi(int(b.get("hits", 1)), 1)
	var crit := false
	for k in hits:
		if not tgt.alive:
			break
		var h := _hit(u, tgt, float(b.mult) / float(hits), {}, false)
		h["sub"] = k
		ev.append(h)
		crit = crit or bool(h.crit)
		if bool(h.broke):
			break
	if b.has("mark") and tgt.alive:
		ev.append(_add_mark(u, tgt, String(b.mark), int(b.get("mark_dur", 2)), 1))
	ev.append_array(_passive_on_hit(u, tgt))
	var before := u.credits
	u.credits = mini(u.credits + TData.BASIC_BONUS, TData.CREDIT_MAX)
	ev.append({"t": "credits", "tgt": u, "v": u.credits - before}) # 실제로 늘어난 만큼 (상한이면 0, §26 X02)
	ev.append_array(_passive_on_crit(u, crit))
	return ev


## 마법 (대마법 포함). tgt는 단일 대상 마법일 때만 쓰인다
func use_skill(u: TUnit, skill_id: String, tgt: TUnit) -> Array:
	var s := skill_of(u, skill_id)
	var ev: Array = []
	u.credits -= int(s.cost)
	last_action = String(s.name)
	u.last_act = "attack" if String(s.kind) == "attack" else "support"
	_cur_skill = skill_id
	if bool(s.get("ultimate", false)):
		# 대마법 연쇄 (§13.6): 앞 대마법의 주인이 아직 다음 행동을 마치지 않았으면 단계 +1. 부가 효과 수치 × CHAIN_MULT (배율은 그대로)
		var stage := mini(chain_stage + 1, 3) if (chain_owner != null and chain_stage > 0) else 1
		if stage > 1:
			s = TData.chain_scaled(s, stage)
			ev.append({"t": "chain", "tgt": u, "stage": stage})
		chain_stage = stage
		chain_owner = u
		chain_turn = turn_no
		max_chain = maxi(max_chain, stage)
	var effects: Array = s.get("effects", [])
	var targets := _resolve_targets(u, s, tgt)
	_pre = {}
	for t in targets:
		_pre[t] = t.marks.keys()
	# 공격 직전 자가 버프 (pre)
	for e in effects:
		if e.t == "buff" and bool(e.get("pre", false)):
			ev.append(_apply_buff(u, u, e))
	var opts := {"skill": true, "aoe": String(s.get("target", "")) == "enemies", "ult": bool(s.get("ultimate", false))}
	var multi := 1
	var multi_mark := "" ## 히트 수 + 그 징표 겹 (낙뢰 심판, F-4)
	var burst := {}
	var crit_gauge := 0.0
	for e in effects:
		if e.t == "this_special":
			opts["this_special"] = e
		elif e.t == "ignore_def":
			opts["ignore_def"] = true
		elif e.t == "sure_crit":
			opts["sure_crit"] = true
		elif e.t == "hp_bonus":
			opts["hp_bonus"] = e
		elif e.t == "multi":
			multi = maxi(int(e.n), 1)
			multi_mark = String(e.get("per_mark", ""))
		elif e.t == "burst":
			burst = e
		elif e.t == "crit_gauge":
			crit_gauge += float(e.v)
	var crit_any := false
	var crit_hits := 0
	if s.kind == "attack":
		for t in targets:
			# 터뜨리기: 맞히기 전에 겹을 센다 (배율 +per×N은 나누기 전 배율에, 특공은 N겹 그대로)
			var n_burst := t.mark_n(String(burst.mark)) if not burst.is_empty() else 0
			var mult := float(s.mult) + (float(burst.per) * float(n_burst) if n_burst > 0 else 0.0)
			var any_crit := false
			var hits := multi + (t.mark_n(multi_mark) if multi_mark != "" else 0)
			for k in hits:
				if not t.alive:
					break
				var h := _hit(u, t, mult / float(hits), opts, true)
				h["sub"] = k
				ev.append(h)
				any_crit = any_crit or bool(h.crit)
				if bool(h.crit):
					crit_hits += 1
				if bool(h.broke):
					break # 줄이 깨지면 이 행동에서 이 적에게 남은 히트는 버린다 (§10.6)
			crit_any = crit_any or any_crit
			for e in effects:
				if e.t == "on_crit" and any_crit:
					for e2 in e.effects:
						ev.append_array(_apply_effect(u, t, e2, targets))
			if n_burst > 0 and t.alive and not bool(burst.get("keep", false)): # keep(대화재): 겹만큼 더하고 징표는 남김 (F-4)
				t.marks.erase(String(burst.mark))
				ev.append({"t": "burst", "tgt": t, "kind": String(burst.mark), "n": n_burst})
			ev.append_array(_passive_on_hit(u, t))
		# 번개: 크리 히트 1번마다 자신 게이지 +v (§17.10)
		if crit_gauge > 0.0 and crit_hits > 0:
			ev.append(_gauge_add(u, crit_gauge * float(crit_hits)))
	for e in effects:
		if e.t in ["this_special", "ignore_def", "on_crit", "sure_crit", "multi", "burst", "crit_gauge", "hp_bonus"] or (e.t == "buff" and bool(e.get("pre", false))):
			continue
		for t in targets:
			ev.append_array(_apply_effect(u, t, e, targets))
			if String(e.get("who", "target")) != "target":
				break # allies·enemies·self는 한 번만
	# 패시브: 엠버 — 아군에게 보조 마법을 걸면 그 아군 게이지 +
	var sg := u.passive_val("support_gauge")
	if sg > 0.0 and s.kind == "support" and String(s.target) in ["ally", "ally_any", "allies"]:
		for t in targets:
			if t != u and t.alive:
				ev.append(_gauge_add(t, sg))
	ev.append_array(_passive_on_crit(u, crit_any))
	_pre = {}
	_cur_skill = ""
	return ev


## 패시브 "틈" (에스카): 내가 때린 적에게 받는 최종 데미지 +v (적 행동 dur번). 판정 없음, 따로 쌓지 않고 남은 수만 새로 (§15.6)
## kind = on_hit_debuff(때림) · on_slow_debuff(게이지·차지를 깎음 — 글라시아, F-4)
func _passive_on_hit(u: TUnit, t: TUnit, kind := "on_hit_debuff") -> Array:
	var ev: Array = []
	if not t.alive or t.is_witch():
		return ev
	for p in u.passive:
		if String(p.t) != kind:
			continue
		var found := false
		for b in t.buffs:
			if b.cat == p.cat and String(b.get("src", "")) == u.id:
				b.dur = maxi(int(b.dur), int(p.dur))
				found = true
		if not found:
			t.add_buff({"cat": p.cat, "v": float(p.v), "dur": int(p.dur), "clock": "own", "name": TData.CAT_NAME.get(p.cat, p.cat), "src": u.id})
			ev.append({"t": "debuff", "tgt": t, "cat": p.cat, "v": float(p.v), "dur": int(p.dur)})
	return ev


## 이번 마법을 맞기 전에 그 징표가 있었나 (마법 밖에서 부르면 지금 징표)
func _had(r: TUnit, kind: String) -> bool:
	if _pre.has(r):
		return (_pre[r] as Array).has(kind)
	return r.marks.has(kind)


## 패시브 사건 효과: 이 행동에서 크리가 났으면 (다단 히트·여러 대상이어도 한 번)
func _passive_on_crit(u: TUnit, crit: bool) -> Array:
	var ev: Array = []
	if not crit:
		return ev
	for p in u.passive:
		if String(p.t) == "on_crit":
			for e in p.effects:
				ev.append_array(_apply_effect(u, u, e, [u]))
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


func _apply_effect(u: TUnit, t: TUnit, e: Dictionary, _targets: Array) -> Array:
	var ev: Array = []
	var who := String(e.get("who", "target"))
	var recv: Array[TUnit] = []
	match who:
		"target": recv.append(t)
		"self": recv.append(u)
		"allies": recv = alive_of(witches)
		"enemies": recv = alive_of(enemies)
		"others":
			for e2 in alive_of(enemies):
				if e2 != t:
					recv.append(e2)
		"other_allies":
			for w in alive_of(witches):
				if w != u:
					recv.append(w)
		"dead_allies":
			for w in witches:
				if not w.alive:
					recv.append(w)
	match String(e.t):
		"buff":
			for r in recv:
				if r.alive:
					ev.append(_apply_buff(u, r, e))
		"debuff":
			for r in recv:
				if not r.alive:
					continue
				if _resisted(r, e, u):
					ev.append({"t": "resist", "tgt": r})
					continue
				var db := {"cat": e.cat, "v": float(e.v), "dur": int(e.dur), "clock": "own", "name": TData.CAT_NAME.get(e.cat, e.cat)}
				if e.has("mark"):
					db["mark"] = e.mark
					db["per_mark"] = bool(e.get("per_mark", false))
				r.add_buff(db)
				ev.append({"t": "debuff", "tgt": r, "cat": e.cat, "v": float(e.v), "dur": int(e.dur)})
		"mark":
			for r in recv:
				if r.alive and (not e.has("if_mark") or _had(r, String(e.if_mark))): # if_mark: 맞기 전 그 징표가 있던 적만 (불의 고리, F-4)
					ev.append(_add_mark(u, r, String(e.kind), int(e.dur), int(e.get("n", 1))))
		"credits":
			if e.has("if_mark") and not _had(t, String(e.if_mark)):
				return ev # 물: "빙결 적이면 크레딧 +N" — 맞기 전 대상의 징표로 본다
			for r in recv:
				if r.alive:
					var before := r.credits
					r.credits = mini(r.credits + int(e.v), TData.CREDIT_MAX)
					ev.append({"t": "credits", "tgt": r, "v": r.credits - before})
		"gauge":
			var gv := float(e.v)
			if gv > 0.0:
				gv += u.passive_val("gauge_plus") # 아스트라
			for r in recv:
				if r.alive:
					ev.append(_gauge_add(r, gv))
		"enemy_gauge":
			for r in recv:
				if not r.alive:
					continue
				if e.has("if_mark") and not _had(r, String(e.if_mark)):
					continue
				if _resisted(r, e, u):
					ev.append({"t": "resist", "tgt": r})
					continue
				var v := float(e.v) + u.passive_val("enemy_gauge_plus") # 글라시아 (빙결 두 배보다 먼저)
				if bool(e.get("frost_x2", false)) and r.marks.has("frost"):
					v *= 2.0
				r.gauge = maxf(r.gauge - TData.GAUGE_MAX * v, 0.0)
				ev.append({"t": "enemy_gauge", "tgt": r, "v": v})
				ev.append_array(_passive_on_hit(u, r, "on_slow_debuff"))
		"gauge_zero":
			for r in recv:
				if not r.alive:
					continue
				if e.has("if_mark") and not _had(r, String(e.if_mark)):
					continue
				if _resisted(r, e, u):
					ev.append({"t": "resist", "tgt": r})
					continue
				r.gauge = 0.0
				ev.append({"t": "gauge_zero", "tgt": r})
		"stun":
			for r in recv:
				if not r.alive:
					continue
				if e.has("if_mark") and not _had(r, String(e.if_mark)):
					continue
				if r.stun_immune and int(e.get("else_charge", 0)) > 0 and r.charge_max > 0:
					ev.append_array(_charge_down(u, r, {"v": int(e.else_charge), "rate": e.get("rate", 1.0)})) # 뇌격: 기절 면역(보스)이면 대신 차지 −n (F-4)
					continue
				ev.append_array(_try_stun(r))
		"taunt":
			for r in recv:
				if r.alive:
					r.add_buff({"cat": "taunt", "v": 1.0, "dur": int(e.dur), "clock": "enemy", "name": "도발"})
					ev.append({"t": "taunt", "tgt": r})
		"guts":
			for r in recv:
				if r.alive:
					r.add_buff({"cat": "guts", "v": float(e.get("pct", 0.0)), "dur": int(e.dur), "clock": "enemy", "name": "근성"})
					ev.append({"t": "guts_on", "tgt": r})
		"extend_buffs":
			for r in recv:
				if r.alive:
					r.extend_buffs(int(e.v))
					ev.append({"t": "extend_buffs", "tgt": r, "v": int(e.v)})
		"extend_mark":
			for r in recv:
				if r.alive and r.marks.has(e.kind):
					r.marks[e.kind].dur = int(r.marks[e.kind].dur) + int(e.v)
					ev.append({"t": "extend_mark", "tgt": r, "kind": e.kind, "v": int(e.v)})
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
				if not r.alive:
					continue
				if r.inv_guard > 0:
					ev.append({"t": "inv_guard", "tgt": r}) # 무적 내성: 막은 뒤 적 행동 2번 동안 새 무적이 걸리지 않음 (§17.12)
					continue
				r.add_buff({"cat": "invincible", "v": 1.0, "dur": int(e.dur), "clock": "enemy", "name": "무적"})
				ev.append({"t": "invincible", "tgt": r})
		"demerit_zero":
			for r in recv:
				r.zero_after_turn = turn_no
				ev.append({"t": "demerit", "tgt": r})
		"enemy_charge":
			for r in recv:
				if r.alive and (not e.has("if_mark") or _had(r, String(e.if_mark))): # if_mark: 심해의 창 (빙결 적만, F-4)
					ev.append_array(_charge_down(u, r, e))
		"regen":
			# 지속 회복 (§17.6, F-4 — 멀린 보구식): 받은 아군이 행동을 마칠 때마다 최대 체력 × pct (행동 dur번)
			for r in recv:
				if r.alive:
					ev.append(_apply_buff(u, r, {"cat": "regen", "v": float(e.pct), "dur": int(e.dur)}))
		"hp_cost":
			# 불의 대가 (§17.9): 체력 −최대 체력 × pct (1 아래로는 안 감, 쓰러지지 않음)
			for r in recv:
				if r.alive:
					var loss := maxi(mini(int(round(float(r.max_hp) * float(e.pct))), r.hp - 1), 0)
					r.hp -= loss
					ev.append({"t": "hp_cost", "tgt": r, "v": loss})
		"spread":
			# 징표 번짐 (§17.1): 대상의 그 징표 겹 수만큼, 같은 남은 수로 다른 적 전체에 (패시브 겹은 더함)
			var n := t.mark_n(String(e.kind))
			if n > 0:
				for r in alive_of(enemies):
					if r != t:
						ev.append(_add_mark(u, r, String(e.kind), t.mark_dur(String(e.kind)), n))
		"hit_stack":
			# 맞으며 쌓기 (§17.11): 이 버프가 있는 동안 적의 공격에 맞을 때마다 to(자신/아군 전체)에게 공격력 +v (최대 max겹, 각 겹은 행동 stack_dur번)
			for r in recv:
				if r.alive:
					r.add_buff({"cat": "hit_stack", "v": float(e.v), "dur": int(e.dur), "clock": "enemy", "name": "맞으며 쌓기",
						"max": int(e.get("max", 5)), "stack_dur": int(e.get("stack_dur", 6)), "to": String(e.get("to", "self"))})
					ev.append({"t": "hit_stack", "tgt": r})
	return ev


## 적 차지 −v (§18.5): 성공 판정은 디버프와 같다. 차지가 가득해 보이던 필살기는 거둬지고 의도를 다시 정한다. 깎았으면 글라시아 패시브 (F-4)
func _charge_down(u: TUnit, r: TUnit, e: Dictionary) -> Array:
	if not r.alive or r.is_witch() or r.charge_max <= 0:
		return []
	if _resisted(r, e, u):
		return [{"t": "resist", "tgt": r}]
	var before := r.charge
	r.charge = maxi(r.charge - int(e.v), 0)
	if r.intent_src == "charge" and r.charge < r.charge_max:
		decide_intent(r)
	var ev: Array = [{"t": "charge_down", "tgt": r, "v": before - r.charge}]
	if before > r.charge:
		ev.append_array(_passive_on_hit(u, r, "on_slow_debuff"))
	return ev


## 징표 걸기 (§17.1): n겹 + 패시브 겹, 남은 수 = max(지금, dur + 장비 mark_extra). 판정 없이 늘 걸린다
func _add_mark(u: TUnit, r: TUnit, kind: String, dur: int, n: int) -> Dictionary:
	var nn := r.add_mark(kind, dur + int(u.equip_data().get("mark_extra", 0)), n + u.passive_mark_plus(kind))
	return {"t": "mark", "tgt": r, "kind": kind, "n": nn}


## 아군 게이지 +v (행동 중인 자신이면 행동이 끝나 0이 된 뒤 더한다)
func _gauge_add(r: TUnit, v: float) -> Dictionary:
	if r == actor:
		r.pending_gauge += TData.GAUGE_MAX * v
	else:
		r.gauge += TData.GAUGE_MAX * v
	return {"t": "gauge", "tgt": r, "v": v}


## 디버프 성공 판정 (§16.5): 성공률 = rate + 거는 마녀의 패시브 rate_plus − 대상 내성. 적에게 거는 것만 판정한다
func _resisted(r: TUnit, e: Dictionary, src: TUnit = null) -> bool:
	if r.is_witch():
		return false
	var rate := float(e.get("rate", 1.0)) - r.resist + (src.passive_val("rate_plus") if src != null else 0.0)
	if rate >= 1.0:
		return false
	if rate <= 0.0:
		return true
	var roll := fix_roll if fix_roll >= 0.0 else rng.randf()
	return roll >= rate


## 기절 걸기 (§17.2). 면역 · 무적(적이 마녀에게) · 기절 내성 · 이미 기절이면 걸리지 않는다
func _try_stun(r: TUnit) -> Array:
	if not r.alive:
		return []
	if r.stun_immune:
		return [{"t": "immune", "tgt": r}]
	if r.is_witch() and r.is_invincible():
		return []
	if r.stun_guard:
		return [{"t": "stun_resist", "tgt": r}]
	if r.stunned:
		return []
	r.stunned = true
	log.append("%s 기절" % r.name)
	return [{"t": "stun", "tgt": r}]


func _apply_buff(u: TUnit, r: TUnit, e: Dictionary) -> Dictionary:
	var dur := int(e.dur)
	if not (e.cat in ["dmg_taken"]):
		dur += int(r.equip_data().get("buff_extra", 0)) # 모래시계 펜던트
	var v := float(e.get("v", 0.0))
	if v > 0.0 and u != null:
		v += u.passive_cat_val("buff_plus", String(e.cat)) # 엠버: 거는 공격력 버프 +10%p
	var b := {"cat": e.cat, "v": v, "dur": dur, "clock": "enemy" if e.cat in ["dmg_taken"] else "own", "name": TData.CAT_NAME.get(e.cat, e.cat)}
	if e.has("mark"):
		b["mark"] = e.mark
	if e.has("el"):
		b["el"] = e.el
	if bool(e.get("per_mark", false)):
		b["per_mark"] = true
	if _cur_skill != "":
		b["sid"] = _cur_skill
	if e.has("count"):
		b["count"] = int(e.count) # 횟수제 (§16.8)
		b["on"] = String(e.get("on", "attack"))
		b["born"] = turn_no
	r.add_buff(b)
	return {"t": "buff", "tgt": r, "cat": e.cat, "v": v, "dur": int(e.dur), "el": e.get("el", ""), "mark": e.get("mark", ""), "count": int(e.get("count", 0))}


# ═══════════════════════════════════════════════════════════
# 적 (combat_proto.md §18)
# ═══════════════════════════════════════════════════════════

## 적의 행동 (확정된 의도대로). 돌려준 사건을 연출한 뒤 end_action
func enemy_action(u: TUnit) -> Array:
	var ev: Array = []
	var it := u.intent()
	var k := String(it.get("k", "attack"))
	last_action = String(it.get("name", TData.INTENT_NAME.get(k, "공격")))
	var alive_w := alive_of(witches)
	match k:
		"attack", "heavy":
			var t := _enemy_target()
			if t != null:
				ev.append(_enemy_hit(u, t, float(it.get("mult", 1.0)), bool(it.get("pierce", false))))
		"stun_attack":
			var t := _enemy_target()
			if t != null:
				var h := _enemy_hit(u, t, float(it.get("mult", 1.0)), bool(it.get("pierce", false)))
				ev.append(h)
				if not bool(h.invincible):
					ev.append_array(_try_stun(t)) # 무적이면 피해와 함께 막힌다
		"aoe":
			for t in alive_w:
				ev.append(_enemy_hit(u, t, float(it.get("mult", 1.0)), bool(it.get("pierce", false))))
		"finisher":
			if bool(it.get("aoe", false)):
				for t in alive_w:
					ev.append(_enemy_hit(u, t, float(it.get("mult", 1.0)), bool(it.get("pierce", false))))
			else:
				var t := _enemy_target()
				if t != null:
					ev.append(_enemy_hit(u, t, float(it.get("mult", 1.0)), bool(it.get("pierce", false))))
			if bool(it.get("self_ko", false)):
				# 자폭 (review_H §2.1): 피해 뒤 그 적이 쓰러진다 — take_damage를 거치지 않아 근성·줄·우두머리 처리 없음, 막타 보상 없음 [10-1 A]
				u.alive = false
				u.hp = 0
				u.buffs.clear()
				u.marks.clear()
				u.stunned = false
				log.append("%s 자폭" % u.name)
				ev.append({"t": "self_ko", "tgt": u})
		"buff":
			u.add_buff({"cat": "atk", "v": float(it.get("v", 0.3)), "dur": int(it.get("dur", 3)), "clock": "own", "name": "공격력"})
			ev.append({"t": "enemy_buff", "tgt": u, "v": float(it.get("v", 0.3))})
		"dispel":
			# 마녀 전원의 이로운 버프를 지운다 (적이 건 나쁜 효과 bad · 패시브·장비·장비 근성·대가는 남음, §16.6 · review_H §2.1)
			for w in alive_w:
				if w.good_buffs() > 0:
					w.buffs = w.buffs.filter(func(b: Dictionary) -> bool: return bool(b.get("bad", false)))
					ev.append({"t": "dispel", "tgt": w})
		# ── 단계 F-2 새 의도 (review_H §2.1)
		"seal":
			var t := _enemy_target()
			if t != null:
				var blocked := false
				if float(it.get("mult", 0.0)) > 0.0:
					var h := _enemy_hit(u, t, float(it.mult), bool(it.get("pierce", false)))
					ev.append(h)
					blocked = bool(h.invincible) # 피해가 있는 봉인은 무적이면 피해와 함께 막힌다
				if not blocked and t.alive:
					ev.append(_try_seal(t, bool(it.get("ult", false))))
		"weaken":
			var recv: Array[TUnit] = []
			if bool(it.get("aoe", false)):
				recv = alive_w
			else:
				var t := _enemy_target()
				if t != null:
					recv.append(t)
			for t in recv:
				if float(it.get("mult", 0.0)) > 0.0:
					var h := _enemy_hit(u, t, float(it.mult), bool(it.get("pierce", false)))
					ev.append(h)
					if bool(h.invincible) or not t.alive:
						continue
				ev.append(_weaken(t, it))
		"guard":
			# 방어 태세: 그 적의 행동 dur번 (적 버프 §18.8과 같이 건 행동부터 셈 — dur 2 = 다음 자기 행동이 끝날 때까지)
			u.add_buff({"cat": "dmg_cut", "v": float(it.get("v", 0.5)), "dur": int(it.get("dur", 2)), "clock": "own", "name": "방어 태세"})
			ev.append({"t": "guard", "tgt": u, "v": float(it.get("v", 0.5))})
		"cover":
			u.add_buff({"cat": "cover", "v": 1.0, "dur": int(it.get("dur", 2)), "clock": "own", "name": "막아서기"})
			ev.append({"t": "cover", "tgt": u})
		"rally":
			if it.has("charge"):
				for e in alive_of(enemies):
					if e == u or e.charge_max <= 0:
						continue
					var before := e.charge
					e.charge = mini(e.charge + int(it.charge), e.charge_max)
					if e.charge >= e.charge_max and e.intent_src != "charge":
						decide_intent(e) # 가득 차면 바로 필살기 의도 (§18.2 ①)
					ev.append({"t": "charge_up", "tgt": e, "v": e.charge - before})
			elif it.has("gauge"):
				var low: TUnit = null
				for e in alive_of(enemies):
					if e != u and (low == null or e.gauge < low.gauge):
						low = e
				if low != null:
					low.gauge += TData.GAUGE_MAX * float(it.gauge)
					ev.append({"t": "gauge", "tgt": low, "v": float(it.gauge)})
		"summon":
			for i in enemies.size():
				if enemies[i].alive:
					continue
				var over := {"hp": int(it.hp)} if it.has("hp") else {}
				var nu := TUnit.make_enemy(String(it.id), i, over)
				var old := enemies[i]
				enemies[i] = nu
				decide_intent(nu)
				summoned += 1
				log.append("%s 부르기 → %s" % [u.name, nu.name])
				ev.append({"t": "summon", "tgt": nu, "old": old, "slot": i})
				break
		"purge":
			var n := u.marks_total()
			u.marks.clear()
			ev.append({"t": "purge", "tgt": u, "n": n})
		"scatter":
			for w in alive_w:
				var before := w.credits
				w.credits = maxi(w.credits - int(it.get("v", 2)), 0)
				ev.append({"t": "credits", "tgt": w, "v": w.credits - before})
	# 맞으며 쌓기 (§17.11): 이 행동에 실제로 맞은(피해 > 0) 마녀마다 한 겹
	var st: Array = []
	for e in ev:
		if e.t == "hit" and int(e.dmg) > 0 and e.tgt.alive:
			st.append_array(_on_hit_stack(e.tgt))
	ev.append_array(st)
	u.acts += 1
	u.last_k = k
	if u.intent_src == "pattern":
		u.intent_i += 1
	return ev


## 봉인 걸기 (review_H §2.1): 봉인 내성이면 막힘. 판정 없이 성공
func _try_seal(t: TUnit, ult_only: bool) -> Dictionary:
	if t.seal_guard:
		return {"t": "seal_resist", "tgt": t}
	t.sealed = 2 if ult_only else 1
	log.append("%s 봉인" % t.name)
	return {"t": "seal", "tgt": t, "ult": ult_only}


## 약화 (review_H §2.1): 마녀에게 나쁜 효과 (판정 없이 성공, bad — 해제가 남김). 공격력 다운 = 그 마녀 행동 dur번 · 받는 피해 = 적 행동 dur번 (건 행동부터 셈)
func _weaken(t: TUnit, it: Dictionary) -> Dictionary:
	var cat := String(it.get("cat", "atk_down"))
	var dur := int(it.get("dur", 2))
	var enemy_clock := cat == "dmg_taken"
	t.add_buff({"cat": cat, "v": float(it.get("v", 0.15)), "dur": dur, "clock": "enemy" if enemy_clock else "own",
		"name": TData.CAT_NAME.get(cat, cat), "bad": true})
	return {"t": "weaken", "tgt": t, "cat": cat, "v": float(it.get("v", 0.15)), "dur": dur}


## 맞으며 쌓기: w의 hit_stack 버프마다 받는 사람(to)에게 공격력 겹 하나 (이 출처의 겹이 max면 가장 오래된 겹의 남은 수만 새로)
func _on_hit_stack(w: TUnit) -> Array:
	var ev: Array = []
	for hs in w.buffs.duplicate():
		if hs.cat != "hit_stack":
			continue
		var recv: Array[TUnit] = [w]
		if String(hs.to) == "allies":
			recv = alive_of(witches)
		for r in recv:
			var mine: Array = []
			for b in r.buffs:
				if b.cat == "atk" and String(b.get("stack_src", "")) == w.id:
					mine.append(b)
			if mine.size() >= int(hs.max):
				var old: Dictionary = mine[0]
				for b in mine:
					if int(b.dur) < int(old.dur):
						old = b
				old.dur = int(hs.stack_dur)
			else:
				r.add_buff({"cat": "atk", "v": float(hs.v), "dur": int(hs.stack_dur), "clock": "own", "name": "쌓인 힘", "stack_src": w.id})
			ev.append({"t": "stack", "tgt": r, "n": mini(mine.size() + 1, int(hs.max)), "v": float(hs.v)})
	return ev


## 단일 대상: 도발한 마녀 중 균등 무작위, 없으면 살아 있는 마녀 중 균등 무작위 (§18.4)
func _enemy_target() -> TUnit:
	var alive_w := alive_of(witches)
	if alive_w.is_empty():
		return null
	var pool: Array[TUnit] = []
	for w in alive_w:
		if w.is_taunting():
			pool.append(w)
	if pool.is_empty():
		pool = alive_w
	return pool[rng.randi_range(0, pool.size() - 1)]


## 다음 의도를 정한다 (§18.2): 차지 가득 → 필살기 / 줄이 방금 깨짐 → on_break 의도 / 조건 규칙 / 패턴 순환
func decide_intent(u: TUnit, broke := false) -> void:
	if u.is_witch():
		return
	if u.charge_max > 0 and u.charge >= u.charge_max:
		u.intent_now = u.data.charge_act
		u.intent_src = "charge"
		return
	var ob: Dictionary = u.data.get("on_break", {})
	if broke and ob.has("intent"):
		u.intent_now = ob.intent
		u.intent_src = "break"
		return
	var rules: Array = u.data.get("rules", [])
	var pat_hit := false
	for i in rules.size():
		var r: Dictionary = rules[i]
		if not _rule_ok(u, r.when):
			continue
		if r.has("pattern"):
			pat_hit = true
			if u.rule_pat != i:
				u.rule_pat = i
				u.pattern = r.pattern
				u.intent_i = 0
			break
		if r.has("insert"):
			u.intent_now = r.insert
			u.intent_src = "insert"
			return
	if not pat_hit and u.rule_pat >= 0:
		u.rule_pat = -1
		u.pattern = u.data.pattern
		u.intent_i = 0
	u.intent_now = u.pattern[u.intent_i % u.pattern.size()] if not u.pattern.is_empty() else {}
	u.intent_src = "pattern"


## 조건 하나라도 안 맞으면 false (한 when 안의 조건은 모두 맞아야 함). not = self_buff를 뒤집는 표시 (조건 아님)
func _rule_ok(u: TUnit, when: Dictionary) -> bool:
	for c in when:
		var v = when[c]
		match String(c):
			"hp_below":
				if not (u.hp_ratio() < float(v)):
					return false
			"bar":
				if u.bar_i != int(v):
					return false
			"witch_buffs":
				var n := 0
				for w in alive_of(witches):
					n += w.good_buffs() # 적이 건 나쁜 효과는 세지 않음 (해제가 지우지 않으므로)
				if n < int(v):
					return false
			"allies_dead":
				var n := 0
				for e in enemies:
					if e != u and not e.alive:
						n += 1
				if n < int(v):
					return false
			"acted":
				if u.acts <= 0 or u.acts % int(v) != 0:
					return false
			# ── 단계 F-2 (review_H §4)
			"empty_slot": # 같은 웨이브 빈 칸 ≥ n 그리고 이 웨이브에 부른 수 < summon_cap
				var n := 0
				for e in enemies:
					if not e.alive:
						n += 1
				if n < int(v) or summoned >= u.summon_cap:
					return false
			"self_marks":
				if u.marks_total() < int(v):
					return false
			"witch_credits":
				var any := false
				for w in alive_of(witches):
					any = any or w.credits >= int(v)
				if not any:
					return false
			"self_buff":
				if u.has_buff(String(v)) == bool(when.get("not", false)):
					return false
			"allies_alive":
				var n := 0
				for e in enemies:
					if e != u and e.alive:
						n += 1
				if n < int(v):
					return false
	return true


## 줄이 깨짐 (§18.6): 징표·디버프는 남고, on_break(패턴·자기 버프) 뒤 다음 의도를 다시 정한다
func _on_break(u: TUnit) -> void:
	# 줄마다 데이터 (review_H §6.1): 그 줄의 phases 칸을 덮어씀 (적힌 칸만). 징표·디버프·버프는 그대로
	var ph: Array = u.data.get("phases", [])
	if u.bar_i < ph.size():
		var p: Dictionary = ph[u.bar_i]
		if p.has("weak"):
			u.weak = p.weak
		if p.has("element"):
			u.element = String(p.element)
		if p.has("def"):
			u.def_rate = float(p.def)
		if p.has("speed"):
			u.speed = int(p.speed)
	var ob: Dictionary = u.data.get("on_break", {})
	if ob.has("pattern"):
		u.pattern = ob.pattern
		u.intent_i = 0
	if ob.has("buff"):
		u.add_buff({"cat": "atk", "v": float(ob.buff.get("v", 0.3)), "dur": int(ob.buff.get("dur", 3)), "clock": "own", "name": "공격력"})
	decide_intent(u, true)
	log.append("%s 브레이크 → 줄 %d/%d" % [u.name, u.bar_i + 1, u.bars.size()])


## 행동(또는 쉼)이 끝남 (§7.7): 게이지 · 시계 감기 · 대가 · 차지 · 다음 의도 · 기절 처리
func end_action(u: TUnit) -> Array:
	var ev: Array = []
	var rested := u.stunned
	u.gauge = u.pending_gauge
	u.pending_gauge = 0.0
	if u.is_witch():
		u.consume_counts(u.last_act, turn_no)
		# 봉인 (review_H §2.1): 봉인된 차례(쉼 포함)가 끝나면 풀리고 봉인 내성 — 그다음 자기 차례 끝까지 봉인 무효
		if u.sealed > 0:
			u.sealed = 0
			u.seal_guard = true
		elif u.seal_guard:
			u.seal_guard = false
		# 대마법 연쇄가 끊기는 때: 주인의 다음 행동(대마법이 아닌 것·쉼)이 끝남, 또는 주인이 쓰러짐
		if chain_owner != null and ((chain_owner == u and turn_no > chain_turn) or not chain_owner.alive):
			chain_owner = null
			chain_stage = 0
		u.last_act = ""
		# 지속 회복 (F-4): 행동(쉼 포함)을 마칠 때마다 — 버프 시계가 줄기 전에
		if u.alive:
			var rg := u.cat_sum("regen")
			if rg > 0.0:
				var hv := u.heal(int(round(float(u.max_hp) * rg)))
				if hv > 0:
					ev.append({"t": "heal", "tgt": u, "v": hv, "regen": true})
	u.on_own_acted()
	if u.is_witch():
		if u.zero_after_turn >= 0 and turn_no > u.zero_after_turn:
			u.zero_after_turn = -1
			if u.credits > 0:
				u.credits = 0
				ev.append({"t": "zeroed", "tgt": u})
	elif not rested: # 적이 쉬었으면 마녀의 enemy 시계·차지·패턴은 그대로 (§17.2)
		for w in witches:
			if w.alive:
				w.on_enemy_acted()
		if u.charge_max > 0:
			if u.last_k == "finisher":
				u.charge = 0
			else:
				u.charge = mini(u.charge + 1, u.charge_max)
		decide_intent(u)
	if rested:
		u.stunned = false
		u.stun_guard = true
	elif u.stun_guard:
		u.stun_guard = false
	actor = null
	return ev


# ═══════════════════════════════════════════════════════════
# 피해 공식 (combat_proto.md §11)
# ═══════════════════════════════════════════════════════════

## 공식의 항들 (난수·크리 판정 전). base = 공격력 × 배율 × 속성 × (1+공격력) × (1+특공) × (1+최종) × 방어
func _terms(src: TUnit, tgt: TUnit, mult: float, opts: Dictionary, is_skill: bool) -> Dictionary:
	src.hit_kind = "skill" if is_skill else "basic"
	var r := _terms_in(src, tgt, mult, opts, is_skill)
	src.hit_kind = ""
	return r


func _terms_in(src: TUnit, tgt: TUnit, mult: float, opts: Dictionary, is_skill: bool) -> Dictionary:
	var el := src.attack_element()
	var elem := 1.0
	var weak := false
	if el != "" and tgt.weak.has(el):
		elem = TData.WEAK
		weak = true
	elif src.special and not src.has_element_buff():
		elem = TData.SPECIAL
	var eq := src.equip_data()
	var atk_sum := src.cat_sum("atk", tgt, el)
	var crit_rate := minf(TData.CRIT_BASE + src.cat_sum("crit_rate", tgt, el) + tgt.cat_sum("crit_taken", tgt) + float(eq.get("crit_rate", 0.0)), 1.0)
	var crit_dmg := src.cat_sum("crit_dmg", tgt, el) + float(eq.get("crit_dmg", 0.0))
	if src.is_witch():
		crit_dmg += _aura(tgt, "crit_dmg") # 토난: 감전 적을 때리는 아군 크리 데미지 +
	var crit_mult := TData.CRIT_MULT + minf(crit_dmg, float(TData.CAP.crit_dmg))
	if src.is_witch() and not tgt.is_witch():
		crit_mult += tgt.cat_sum("crit_dmg_taken", tgt) # 받는 크리 데미지 (과전류, F-4 P3): 크리 데미지 상한과 따로 (자기 상한 60%)
	var special := src.cat_sum("special", tgt, el)
	if opts.has("this_special"):
		var ts: Dictionary = opts.this_special
		if special_hits(ts, tgt):
			special += float(ts.v) # 이 공격만 특공은 겹을 곱하지 않는 고정값 (§11.4, 단계 B) — 징표 또는 특성 (F-3 특성 특공)
	if not tgt.marks.is_empty():
		special += float(eq.get("special", 0.0)) # 장비는 겹을 곱하지 않음
	special = minf(special, float(TData.CAP.special))
	var final_sum := src.cat_sum("final", tgt, el) + float(eq.get("final", 0.0)) + tgt.cat_sum("final_taken", tgt)
	if is_skill:
		final_sum += float(eq.get("skill_final", 0.0))
	if el != "" and el == String(eq.get("element", "")):
		final_sum += float(eq.get("el_final", 0.0)) # 속성 반지 Lv2~3
	final_sum = minf(final_sum, float(TData.CAP.final))
	var def_v := 0.0 if opts.get("ignore_def", false) else maxf(tgt.def_rate - src.passive_val("def_pierce"), 0.0)
	var def_f := clampf(1.0 - def_v + tgt.cat_sum("def_down", tgt), TData.DEF_MIN, TData.DEF_MAX)
	# 적이 건 마녀 공격력 다운 (약화, review_H §2.1): 공격력 항 = 1 + 공격력 합 − 다운(상한 50%), 하한 0.3
	var atk_f := maxf(1.0 + atk_sum - (src.cat_sum("atk_down") if src.is_witch() else 0.0), 0.3)
	var base := float(src.atk) * mult * elem * atk_f * (1.0 + special) * (1.0 + final_sum) * def_f
	# 대마법 위력 (F-4 — 배터리 마법의 몫): 대마법 공격에만 따로 곱함
	if bool(opts.get("ult", false)):
		base *= 1.0 + src.cat_sum("ult_dmg", tgt, el)
	# 체력 비례 (F-4 — 이그니스): 적 체력(지금 줄)이 at 넘게 남았을수록 × (1 + v × (비율 − at) / (1 − at)), 따로 곱함
	if opts.has("hp_bonus"):
		base *= 1.0 + hp_bonus_of(opts.hp_bonus, tgt)
	# 적의 방어 태세·보호 (review_H §2.1 · §3): × (1 − min(받는 피해 감소 합, 70%)) — 방어율이 아닌 축이라 방어 무시·에스카 패시브로 안 뚫림
	if not tgt.is_witch():
		base *= 1.0 - minf(tgt.cat_sum("dmg_cut") + _ally_guard(tgt), float(TData.CAP.dmg_cut))
		if bool(opts.get("aoe", false)):
			base *= 1.0 + _passive_v(tgt, "aoe_taken") # 적 고유 효과 aoe_taken (잿빛 무리 "흩날리는 재", F-3): 광역 공격에 받는 피해 +v
	return {"base": base, "crit_rate": crit_rate, "crit_mult": crit_mult, "weak": weak, "special": special, "el": el}


## 체력 비례 보너스 (hp_bonus {v, at}): 대상 체력 비율이 at 이하면 0, 가득이면 v
static func hp_bonus_of(e: Dictionary, tgt: TUnit) -> float:
	if tgt == null:
		return 0.0
	var at := float(e.get("at", 0.5))
	return float(e.v) * clampf((tgt.hp_ratio() - at) / maxf(1.0 - at, 0.01), 0.0, 1.0)


## "이 공격만 특공"이 그 대상에게 붙나: mark(징표가 있으면) 또는 trait(그 특성을 가지면 — 특성 특공, review_F F02 · combat_proto.md §11.4)
static func special_hits(ts: Dictionary, tgt: TUnit) -> bool:
	if tgt == null:
		return false
	if ts.has("trait"):
		return tgt.traits.has(String(ts.trait))
	return tgt.marks.has(String(ts.get("mark", "")))


## 적 고유 효과 t의 v 합 (없으면 0)
func _passive_v(tgt: TUnit, t: String) -> float:
	var v := 0.0
	for p in tgt.passive:
		if String(p.get("t", "")) == t:
			v += float(p.get("v", 0.0))
	return v


## 적 고유 효과 guard_allies: 다른 적이 하나라도 살아 있으면 v (등불 가림 · 둥지 보호)
func _ally_guard(tgt: TUnit) -> float:
	var v := 0.0
	for p in tgt.passive:
		if String(p.get("t", "")) == "guard_allies":
			v += float(p.v)
	if v <= 0.0:
		return 0.0
	for e in alive_of(enemies):
		if e != tgt:
			return v
	return 0.0


## 살아 있는 마녀들의 패시브 aura 중 cat인 것의 합 (mark 조건은 대상 tgt의 징표)
func _aura(tgt: TUnit, cat: String) -> float:
	var s := 0.0
	for w in alive_of(witches):
		for e in w.passive:
			if String(e.t) == "aura" and String(e.cat) == cat and (not e.has("mark") or (tgt != null and tgt.marks.has(e.mark))):
				s += float(e.v)
	return s


func _rand() -> float:
	return fix_rand if fix_rand >= 0.0 else rng.randf_range(TData.RAND_LO, TData.RAND_HI)


## 크리 판정: 크리 확정이면 난수를 뽑지 않는다 (§14.3)
func _crit_roll(rate: float, sure := false) -> bool:
	if sure:
		return true
	if fix_crit >= 0:
		return fix_crit == 1
	return rng.randf() < rate


func _hit(src: TUnit, tgt: TUnit, mult: float, opts: Dictionary, is_skill: bool) -> Dictionary:
	var tm := _terms(src, tgt, mult, opts, is_skill)
	var crit := _crit_roll(float(tm.crit_rate), bool(opts.get("sure_crit", false)))
	var r := _rand()
	var dmg := maxi(int(round(float(tm.base) * (float(tm.crit_mult) if crit else 1.0) * r)), 1) # 피해 최소 1
	var over := maxi(dmg - tgt.hp, 0) # 넘친 피해 (줄이 깨지거나 쓰러질 때 버려지는 몫 — 측정용, F-4)
	var res := deal(tgt, dmg)
	src.dealt += dmg
	var gbreak: bool = bool(tm.weak) and not bool(res.killed) and _guard_break(tgt)
	log.append("%s → %s %s%s%s %s" % [src.name, tgt.name, TData.fmt(dmg), " 크리" if crit else "", " 약점" if tm.weak else "", "쓰러짐" if res.killed else ("브레이크" if res.broke else "")])
	return {"t": "hit", "src": src, "tgt": tgt, "dmg": dmg, "crit": crit, "weak": tm.weak, "special": float(tm.special) > 0.0, "killed": res.killed, "guts": res.guts, "broke": res.broke, "invincible": false, "el": tm.el,
		"hp": tgt.hp, "max_hp": tgt.max_hp, "bar_i": tgt.bar_i, "fall": res.get("fall", []), "guard_break": gbreak, "over": over}


## 적 고유 효과 guard_break (세 빛의 인형 "갈라지는 빛", F-3): 약점 속성 공격을 맞으면 그 공격 뒤 방어 태세가 풀린다 → true
func _guard_break(tgt: TUnit) -> bool:
	if tgt.is_witch() or not tgt.has_buff("dmg_cut"):
		return false
	var has := false
	for p in tgt.passive:
		if String(p.get("t", "")) == "guard_break":
			has = true
	if not has:
		return false
	for i in range(tgt.buffs.size() - 1, -1, -1):
		if String(tgt.buffs[i].get("cat", "")) == "dmg_cut":
			tgt.buffs.remove_at(i)
	return true


## 피해를 넣는다: 쓰러짐·근성·브레이크 처리까지 (시험에서 직접 부르기도 한다)
func deal(tgt: TUnit, dmg: int) -> Dictionary:
	var res := tgt.take_damage(dmg)
	if bool(res.broke):
		_on_break(tgt)
	if bool(res.guts):
		log.append("%s 근성" % tgt.name)
	if bool(res.killed) and tgt.leader:
		# 우두머리 (review_H §6.2): 같은 웨이브의 나머지도 사라진다 → outcome()이 "wave"/"win"
		var fall: Array = []
		for e in enemies:
			if e != tgt and e.alive:
				e.alive = false
				e.hp = 0
				e.buffs.clear()
				e.marks.clear()
				fall.append(e)
		res["fall"] = fall
		log.append("%s 쓰러짐 — 졸개 %d 사라짐" % [tgt.name, fall.size()])
	return res


func _enemy_hit(src: TUnit, tgt: TUnit, mult: float, pierce := false) -> Dictionary:
	if tgt.is_invincible() and not pierce:
		log.append("%s → %s 무적" % [src.name, tgt.name])
		tgt.inv_guard = 3 # 무적 내성 (§17.12): 이 적 행동과 다음 적 행동 2번이 끝날 때까지
		return {"t": "hit", "src": src, "tgt": tgt, "dmg": 0, "crit": false, "weak": false, "special": false, "killed": false, "guts": false, "broke": false, "invincible": true, "el": ""}
	var atk_f := clampf(1.0 + src.cat_sum("atk") - src.cat_sum("atk_down"), 0.3, 4.0)
	var aura := _aura(null, "dmg_taken") # 네레이: 살아 있는 동안 아군 전체
	if tgt.is_taunting():
		aura += tgt.passive_val("taunt_guard") # 네레이: 도발 중 자신 받는 피해 −
	var taken := 1.0 + clampf(tgt.cat_sum("dmg_taken") + aura, -0.7, float(TData.CAP.dmg_taken)) + float(tgt.equip_data().get("dmg_taken", 0.0))
	var crit := _crit_roll(maxf(src.ecrit - src.cat_sum("crit_down"), 0.0)) # 적 크리 확률 (데이터 crit, 기본 5% — review_H §3)
	var r := _rand()
	var dmg := maxi(int(round(float(src.atk) * mult * atk_f * (1.0 - tgt.def_rate) * maxf(taken, 0.2) * (TData.CRIT_MULT if crit else 1.0) * r)), 1)
	var res := deal(tgt, dmg)
	log.append("%s → %s %s%s%s" % [src.name, tgt.name, TData.fmt(dmg), " 크리" if crit else "", " 쓰러짐" if res.killed else (" 근성" if res.guts else "")])
	return {"t": "hit", "src": src, "tgt": tgt, "dmg": dmg, "crit": crit, "weak": false, "special": false, "killed": res.killed, "guts": res.guts, "broke": false, "invincible": false, "el": "",
		"hp": tgt.hp, "max_hp": tgt.max_hp, "bar_i": tgt.bar_i}


## 예상 피해 (화면 안내용 §11.7: 난수 1.0, 크리 아님 — 크리 확정이면 크리, crit = true면 크리 값). 터뜨리기는 지금 겹으로.
## 그 마법의 선버프(pre)는 실제처럼 공격 직전에 걸린 셈으로 넣고 계산한 뒤 뺀다 (use_skill과 같은 순서, 대마법은 연쇄 단계 수치로 — review_F F06 a)
func estimate(src: TUnit, tgt: TUnit, skill_id: String, crit := false) -> int:
	var info := est_info(src, tgt, skill_id)
	if info.is_empty():
		return 0
	return int(info.crit) if crit or bool(info.sure) else int(info.est)


## 예상 한 벌 {est, crit, rate(크리 확률, 선버프 포함), sure} — 공격이 아니면 {} (review_F F06 b)
func est_info(src: TUnit, tgt: TUnit, skill_id: String) -> Dictionary:
	var mult := 1.0
	var opts := {}
	var is_skill := skill_id != "" and skill_id != "basic"
	var pre_n := 0
	if is_skill:
		var s := skill_of(src, skill_id)
		if s.get("kind", "") != "attack":
			return {}
		if bool(s.get("ultimate", false)) and chain_owner != null and chain_stage > 0:
			s = TData.chain_scaled(s, mini(chain_stage + 1, 3))
		mult = float(s.mult)
		opts["aoe"] = String(s.get("target", "")) == "enemies"
		opts["ult"] = bool(s.get("ultimate", false))
		for e in s.get("effects", []):
			if e.t == "buff" and bool(e.get("pre", false)):
				_apply_buff(src, src, e)
				pre_n += 1
		for e in s.get("effects", []):
			if e.t == "this_special":
				opts["this_special"] = e
			elif e.t == "ignore_def":
				opts["ignore_def"] = true
			elif e.t == "sure_crit":
				opts["sure_crit"] = true
			elif e.t == "hp_bonus":
				opts["hp_bonus"] = e
			elif e.t == "burst":
				mult += float(e.per) * float(tgt.mark_n(String(e.mark)))
	else:
		mult = float(src.data.basic.mult)
	var tm := _terms(src, tgt, mult, opts, is_skill)
	for k in pre_n:
		src.buffs.pop_back() # 넣었던 선버프를 뺀다 (add_buff는 뒤에 붙인다)
	var sure := bool(opts.get("sure_crit", false))
	var base := float(tm.base)
	var e1 := maxi(int(round(base * (float(tm.crit_mult) if sure else 1.0))), 1)
	var e2 := maxi(int(round(base * float(tm.crit_mult))), 1)
	return {"est": e1, "crit": e2, "rate": 1.0 if sure else float(tm.crit_rate), "sure": sure}


## 디버프·게이지 감소 같은 판정의 성공률 (화면 안내용, §16.5): rate + 거는 마녀 패시브 − 대상 내성 (0~1). 아군 대상이면 1
func success_rate(src: TUnit, tgt: TUnit, e: Dictionary) -> float:
	if tgt == null or tgt.is_witch():
		return 1.0
	return clampf(float(e.get("rate", 1.0)) - tgt.resist + (src.passive_val("rate_plus") if src != null else 0.0), 0.0, 1.0)


## 마법을 썼다고 치고(피해 난수 1.0 · 크리 아님 · 판정은 모두 성공) 행동을 끝낸 뒤의 전투 사본 (review_F F05 규칙 B "사용 뒤" 줄).
## 사본의 preview()가 그 마법을 쓴 뒤의 차례 순서다. 이 전투는 건드리지 않는다
func simulate(u: TUnit, skill_id: String, tgt: TUnit) -> TBattle:
	var c := TBattle.from_dict(to_dict())
	c.resume = false
	c.fix_rand = 1.0
	c.fix_crit = 0
	c.fix_roll = 0.0
	var cu := c.unit_by_key(unit_key(u))
	var ct := c.unit_by_key(unit_key(tgt))
	if cu == null:
		return c
	if skill_id == "" or skill_id == "basic":
		c.basic_attack(cu, ct)
	else:
		c.use_skill(cu, skill_id, ct)
	c.end_action(cu)
	return c


## 마법을 쓴 뒤의 차례 줄: [지금 차례 u] + 그 뒤 n − 1명 (preview와 같은 꼴)
func preview_if(u: TUnit, skill_id: String, tgt: TUnit, n := 8) -> Array[TUnit]:
	var c := simulate(u, skill_id, tgt)
	var out: Array[TUnit] = [u]
	for x in c.preview(n - 1):
		var k := c.unit_key(x)
		var mine := unit_by_key(k)
		if mine != null:
			out.append(mine)
	return out


## 다가오는 필살기 칸 (review_F F05 규칙 A): 차례 줄 q(이 전투의 유닛)에서 차지 적의 필살기 차례 번호 → {pierce}.
## 적 e의 앞으로 j번째 행동(쉼 빼고)이 필살기: 지금 의도가 필살기면 j = 1 + (m + 1)k, 아니면 j = (m − c + 1) + (m + 1)k.
## 기절 중인 적의 첫 차례는 쉼. 조건 규칙·차지 감소는 넣지 않은 예상 (행동이 끝날 때마다 다시 센다)
func finisher_slots(q: Array) -> Dictionary:
	var out := {}
	for e in enemies:
		if not e.alive or e.charge_max <= 0:
			continue
		var m := e.charge_max
		var c := clampi(e.charge, 0, m)
		var it := e.intent()
		var fin_now := String(it.get("k", "")) == "finisher"
		var pierce := bool((e.data.get("charge_act", {}) as Dictionary).get("pierce", false))
		var first := 1 if fin_now else (m - c + 1)
		var rest := e.stunned
		var k := 0
		for i in q.size():
			if q[i] != e:
				continue
			if rest:
				rest = false
				continue
			k += 1
			if k >= first and (k - first) % (m + 1) == 0:
				out[i] = {"pierce": pierce if not fin_now else bool(it.get("pierce", false))}
	return out


# ═══════════════════════════════════════════════════════════
# 웨이브 구성 규칙 검사 (review_F F04 · review_H §7.2) — 데이터 검사, 시험·시뮬이 부른다
# ═══════════════════════════════════════════════════════════

## 전투 bid가 어긴 규칙의 글 목록 (비면 통과).
##   1. 보스 전투: 웨이브 ①②(마지막 웨이브 앞) 체력 합 ≤ 전체의 35%
##   2. 필살기(차지)가 있는 적은 웨이브당 1체 — 자폭 졸개(self_ko)는 세지 않음. 보스 웨이브엔 보스 말고 차지 적이 없음
static func wave_rules(bid: String) -> Array:
	var out: Array = []
	var bd: Dictionary = TData.BATTLES[bid]
	var waves_d: Array = bd.waves
	var hp_w: Array = []
	for wi in waves_d.size():
		var sum := 0
		var chargers := 0
		var boss_wave := false
		var non_boss_charge := 0
		for item in waves_d[wi]:
			var eid := String(item.id) if item is Dictionary else String(item)
			var d: Dictionary = TData.ENEMIES[eid]
			if d.has("bars"):
				for h in d.bars:
					sum += int(h)
			else:
				sum += int(item.get("hp", d.get("hp", 0))) if item is Dictionary else int(d.get("hp", 0))
			var self_ko := bool((d.get("charge_act", {}) as Dictionary).get("self_ko", false))
			if int(d.get("charge_max", 0)) > 0 and not self_ko:
				chargers += 1
				if String(d.get("tier", "")) != "boss":
					non_boss_charge += 1
			boss_wave = boss_wave or String(d.get("tier", "")) == "boss"
		hp_w.append(sum)
		if chargers > 1:
			out.append("웨이브 %d: 필살기 적 %d체" % [wi + 1, chargers])
		if boss_wave and non_boss_charge > 0:
			out.append("웨이브 %d: 보스 웨이브에 다른 필살기 적" % (wi + 1))
	if String(bd.get("kind", "")) == "boss" and hp_w.size() > 1:
		var total := 0
		var front := 0
		for i in hp_w.size():
			total += int(hp_w[i])
			if i < hp_w.size() - 1:
				front += int(hp_w[i])
		var pct := 100.0 * float(front) / float(maxi(total, 1))
		if pct > 35.0:
			out.append("웨이브 ①② 체력 %d%% (> 35%%)" % int(round(pct)))
	return out


# ═══════════════════════════════════════════════════════════
# 저장·불러오기 (전투 이어하기 — combat_proto.md §28.4, review_F F07 규칙 2)
# 마녀 차례가 시작될 때(크레딧 +1을 준 뒤, 고르기 전) 찍는다. 유닛 참조는 "w0"~"w2" · "e0"~"e2"
# ═══════════════════════════════════════════════════════════

func unit_key(u: TUnit) -> String:
	if u == null:
		return ""
	var i := witches.find(u)
	if i >= 0:
		return "w%d" % i
	i = enemies.find(u)
	return "e%d" % i if i >= 0 else ""


func unit_by_key(k: String) -> TUnit:
	if k.length() < 2:
		return null
	var i := int(k.substr(1))
	var side_units: Array[TUnit] = witches if k[0] == "w" else enemies
	return side_units[i] if i >= 0 and i < side_units.size() else null


func to_dict() -> Dictionary:
	var ws: Array = []
	for w in witches:
		ws.append(w.to_dict())
	var es: Array = []
	for e in enemies:
		es.append(e.to_dict())
	return {"ver": 1, "battle_id": battle_id, "rng_seed": rng.seed, "rng_state": rng.state, "turn_no": turn_no, "wave_i": wave_i,
		"actor": unit_key(actor), "chain_stage": chain_stage, "chain_owner": unit_key(chain_owner), "chain_turn": chain_turn, "max_chain": max_chain,
		"data": TData.DATA_VER, "last_action": last_action, "witches": ws, "enemies": es, "waves": waves.duplicate(true), "log": log.slice(maxi(log.size() - 40, 0)), "summoned": summoned}


## 저장한 전투를 다시 세운다. 돌려준 전투의 next_actor()는 저장된 차례부터
static func from_dict(d: Dictionary) -> TBattle:
	var b := TBattle.new()
	b.battle_id = String(d.battle_id)
	b.waves = d.waves if d.has("waves") else TData.BATTLES[b.battle_id].waves
	b.wave_i = int(d.wave_i)
	for wd in d.witches:
		b.witches.append(TUnit.from_dict(wd))
	for ed in d.enemies:
		b.enemies.append(TUnit.from_dict(ed))
	b.rng.seed = int(d.rng_seed)
	b.rng.state = int(d.rng_state)
	b.turn_no = int(d.turn_no)
	b.actor = b.unit_by_key(String(d.actor))
	b.chain_stage = int(d.chain_stage)
	b.chain_owner = b.unit_by_key(String(d.chain_owner))
	b.chain_turn = int(d.chain_turn)
	b.max_chain = int(d.max_chain)
	b.last_action = String(d.get("last_action", ""))
	b.summoned = int(d.get("summoned", 0))
	for l in d.get("log", []):
		b.log.append(String(l))
	b.resume = b.actor != null
	return b

