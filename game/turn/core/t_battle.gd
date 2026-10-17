class_name TBattle
extends RefCounted
## 턴제 전투 코어 v2 — 노드 없음. 화면(TBattleScene)과 헤드리스 시뮬레이션(tools/test/turn_sim.gd)이 같은 코드를 쓴다.
##
## 라운드: [내 턴] 행동 ACTIONS개(가속으로 +) — 어느 마녀의 마법이든 순서대로 act() → 다 쓰거나 end_player_turn() →
##         [적 턴] 적마다 1행동(시전은 이번엔 예고만, 다음 적 턴에 발동 — 내 턴에 끊을 수 있다) → 다음 라운드(쿨·버프 1 감소).
## 물약은 행동을 쓰지 않는다. 대마법은 게이지 100을 쓰고 즉시 발동한다.
## 피해 = 위력 × 공격력/100 × (1+공격) × (1+속성) × 치명 × (1+최종) × (1+취약) × 상성 × 방어 × 난수(0.95~1.05)
## — 같은 범주는 더하고(상한 TData.CAPS) 범주끼리는 곱한다. 같은 마법의 버프는 stack겹까지.

class Unit extends RefCounted:
	var id := ""
	var base := ""
	var name := ""
	var short := ""
	var ally := false
	var slot := 0
	var elem := ""
	var max_hp := 1
	var hp := 1
	var atk := 100.0
	var def_ := 0.0
	var alive := true
	var has_gauge := false
	var gauge := 0.0
	var gauge_mult := 1.0
	var gauge_name := ""
	var bonus := {} ## 상시 보정 (빗자루): crit_rate · crit_dmg · elem(자기 속성)
	var cd_cut := 0 ## 빗자루: 쿨 2턴 이상인 마법의 재사용 단축
	var buffs: Array[Dictionary] = [] ## {key, kind, amt, left(턴), elem, src, spell}
	var cooldowns := {} ## 마법 id → 남은 내 턴 수
	var casting := {} ## 적: {spell, target} — 다음 적 턴에 발동
	var skip_next := false ## 적: 다음 행동 봉쇄 (봉공·속박·브레이크)
	var burn_dmg := 0
	var burn_left := 0
	var weak := ""
	var resist := ""
	var spells: Array[String] = []
	var pattern: Array = []
	var pattern_i := 0
	var bars: Array = []
	var bar_i := 0
	var aggro := 1.0
	var acted := 0
	var dealt := 0
	var taken := 0
	var boss := false
	var size := 1.0
	var color := ""
	var level := 1

	func is_casting() -> bool:
		return not casting.is_empty()

	func hp_ratio() -> float:
		return float(hp) / float(maxi(max_hp, 1))

	## 범주 합 (elem 범주는 마법 속성이 맞는 것만)
	func sum(kind: String, spell_elem := "") -> float:
		var s := 0.0
		for b in buffs:
			if b.kind != kind:
				continue
			if kind == "elem" and String(b.get("elem", "")) != "" and String(b.get("elem", "")) != spell_elem:
				continue
			s += float(b.amt)
		return s

	func stacks(key: String) -> int:
		var n := 0
		for b in buffs:
			if b.key == key:
				n += 1
		return n

	func stacks_of_spell(spell_id: String) -> int:
		var n := 0
		for b in buffs:
			if b.spell == spell_id:
				n += 1
		return n

	func shield_left() -> float:
		var s := 0.0
		for b in buffs:
			if b.kind == "shield":
				s += float(b.amt)
		return s

	func cd_left(spell_id: String) -> int:
		return int(cooldowns.get(spell_id, 0))


var units: Array[Unit] = []
var events: Array[Dictionary] = []
var over := false
var won := false
var round := 1
var actions_max := TData.ACTIONS
var actions_left := TData.ACTIONS
var player_phase := true
var max_hit := 0
var max_hit_info := {}
var bag: Array[String] = []
var rng := RandomNumberGenerator.new()
var battle := {}
var run: TRun
var turns := 0 ## 아군이 쓴 행동 수
var potions_used := 0


func setup(p_run: TRun, p_battle: Dictionary, seed_v := 0) -> void:
	run = p_run
	battle = p_battle
	rng.seed = seed_v if seed_v != 0 else randi()
	units.clear()
	events.clear()
	over = false
	won = false
	round = 1
	max_hit = 0
	max_hit_info = {}
	turns = 0
	potions_used = 0
	bag = run.bag.duplicate()
	var i := 0
	for w in run.party:
		var d: Dictionary = TData.witch(w)
		var st := run.stats(w)
		var u := Unit.new()
		u.id = w
		u.base = w
		u.name = String(d.name)
		u.short = u.name.substr(0, 1)
		u.ally = true
		u.slot = i
		u.elem = String(d.elem)
		u.max_hp = int(st.hp)
		u.hp = u.max_hp
		u.atk = float(st.atk)
		u.has_gauge = String(d.get("gauge", "")) != ""
		u.gauge_name = String(d.get("gauge", ""))
		u.gauge = float(d.get("gauge_start", 0.0)) if u.has_gauge else 0.0
		u.gauge_mult = float(st.gauge_mult)
		u.cd_cut = int(st.cd_cut)
		u.bonus = {"crit_rate": float(st.crit_rate), "crit_dmg": float(st.crit_dmg), "elem": float(st.elem)}
		u.spells = run.spells_of(w)
		u.aggro = float(d.get("aggro", 1.0))
		u.color = String(d.get("color", "#ffffff"))
		u.level = int(st.level)
		units.append(u)
		i += 1
	var counts := {}
	var k := 0
	for e in battle.get("enemies", []):
		var key := String(e)
		var d: Dictionary = TData.enemy(key)
		counts[key] = int(counts.get(key, 0)) + 1
		var u := Unit.new()
		u.id = key + "_" + str(counts[key])
		u.base = key
		u.name = String(d.name)
		u.short = String(d.get("short", u.name.substr(0, 1)))
		if (battle.get("enemies", []) as Array).count(e) > 1:
			u.name += " " + ["Ⅰ", "Ⅱ", "Ⅲ"][counts[key] - 1]
			u.short += ["¹", "²", "³"][counts[key] - 1]
		u.ally = false
		u.slot = k
		u.atk = float(d.atk)
		u.pattern = (d.get("pattern", []) as Array).duplicate()
		u.boss = bool(d.get("boss", false))
		u.size = float(d.get("size", 1.0))
		u.color = String(d.get("color", "#000000"))
		u.bars = (d.get("bars", []) as Array)
		if not u.bars.is_empty():
			_enter_bar(u, 0, false)
		else:
			u.max_hp = int(d.hp)
			u.hp = u.max_hp
			u.def_ = float(d.def)
			u.weak = String(d.get("weak", ""))
			u.resist = String(d.get("resist", ""))
		units.append(u)
		k += 1
	player_phase = true
	actions_left = actions_max
	events.append({"type": "round_start", "round": round, "actions": actions_left})


func take_events() -> Array[Dictionary]:
	var out := events.duplicate()
	events.clear()
	return out


func allies(alive_only := true) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if u.ally and (u.alive or not alive_only):
			out.append(u)
	return out


func enemies(alive_only := true) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if not u.ally and (u.alive or not alive_only):
			out.append(u)
	return out


func find(id: String) -> Unit:
	for u in units:
		if u.id == id:
			return u
	return null


## 아군 마법의 사양 (적이면 행동 표)
func spec_of(u: Unit, id: String) -> Dictionary:
	if u.ally:
		return TData.spell(id)
	return (TData.enemy(u.base).get("actions", {}) as Dictionary).get(id, {})


func can_use(u: Unit, spell_id: String) -> bool:
	if not player_phase or actions_left <= 0 or over:
		return false
	if u == null or not u.alive or not u.ally or not (spell_id in u.spells):
		return false
	if u.cd_left(spell_id) > 0:
		return false
	var sp := TData.spell(spell_id)
	if String(sp.get("kind", "")) == "ult" and u.gauge < TData.GAUGE_MAX - 0.001:
		return false
	return true


## 쓸 수 없는 이유 (화면 안내용)
func why_not(u: Unit, spell_id: String) -> String:
	if not (spell_id in u.spells):
		return "아직 못 배운 마법"
	if u.cd_left(spell_id) > 0:
		return "재사용까지 %d턴" % u.cd_left(spell_id)
	var sp := TData.spell(spell_id)
	if String(sp.get("kind", "")) == "ult" and u.gauge < TData.GAUGE_MAX - 0.001:
		return "게이지 %d%% — 100이 되면" % int(u.gauge)
	if actions_left <= 0:
		return "행동을 다 썼다"
	return ""


## 마법의 대상 후보
func targets_for(u: Unit, sp: Dictionary) -> Array[Unit]:
	var t := String(sp.get("target", "enemy"))
	var foes := enemies() if u.ally else allies()
	var friends := allies() if u.ally else enemies()
	match t:
		"enemy", "all", "enemies", "weakest":
			return foes
		"ally", "allies":
			return friends
		"self":
			return [u]
	return foes


func needs_target(sp: Dictionary) -> bool:
	return String(sp.get("target", "enemy")) in ["enemy", "ally"]


# ═══════════════════════════════════════════════════════════
# 라운드
# ═══════════════════════════════════════════════════════════

func _start_player_turn() -> void:
	player_phase = true
	round += 1
	for u in units:
		if not u.alive:
			continue
		if u.ally:
			for key in u.cooldowns.keys():
				u.cooldowns[key] = maxi(int(u.cooldowns[key]) - 1, 0)
	_tick_buffs()
	var bonus := 0
	for a in allies():
		bonus += int(round(a.sum("haste")))
	actions_left = actions_max + mini(bonus, TData.ACTIONS_BONUS_MAX)
	events.append({"type": "round_start", "round": round, "actions": actions_left})


func _tick_buffs() -> void:
	for u in units:
		if not u.alive:
			continue
		var i := u.buffs.size() - 1
		while i >= 0:
			var b := u.buffs[i]
			b.left = int(b.left) - 1
			if int(b.left) <= 0:
				u.buffs.remove_at(i)
				events.append({"type": "buff_end", "unit": u.id, "kind": b.kind, "spell": b.spell})
			i -= 1


## 내 턴 끝 → 적 턴 전부 → 다음 라운드 시작. 사건은 events에 쌓인다
func end_player_turn() -> void:
	if over or not player_phase:
		return
	player_phase = false
	events.append({"type": "enemy_phase", "round": round})
	for e in enemies():
		if over:
			break
		if not e.alive:
			continue
		if e.burn_left > 0:
			_burn_tick(e)
			if not e.alive:
				_check_end()
				continue
		if e.skip_next:
			e.skip_next = false
			events.append({"type": "skipped", "unit": e.id})
			continue
		events.append({"type": "turn", "unit": e.id})
		if e.is_casting():
			_fire_cast(e)
		else:
			_enemy_act(e)
		_check_end()
	if not over:
		_start_player_turn()


# ═══════════════════════════════════════════════════════════
# 행동
# ═══════════════════════════════════════════════════════════

## 아군 행동 하나 (행동 1 소모). 즉시 발동
func act(u: Unit, spell_id: String, target_id := "") -> bool:
	if not can_use(u, spell_id):
		return false
	var sp := TData.spell(spell_id)
	actions_left -= 1
	turns += 1
	u.acted += 1
	var ult := String(sp.get("kind", "")) == "ult"
	if ult:
		u.gauge = 0.0
	events.append({"type": "action", "unit": u.id, "spell": spell_id, "left": actions_left})
	_execute(u, sp, spell_id, target_id, false)
	var cd := int(sp.get("cd", 0))
	if cd > 0:
		if cd >= 2 and u.cd_cut > 0:
			cd = maxi(cd - u.cd_cut, 1)
		u.cooldowns[spell_id] = cd
	if not ult:
		_gain_gauge(u, float(sp.get("gauge", 0.0)))
	_check_end()
	return true


## 물약 — 행동을 쓰지 않는다. 가방에 있어야 한다
func use_potion(u: Unit, potion_id: String, target_id := "") -> bool:
	if not player_phase or over or not (potion_id in bag) or u == null or not u.alive:
		return false
	var sp: Dictionary = TData.POTIONS.get(potion_id, {})
	if sp.is_empty():
		return false
	bag.erase(potion_id)
	if run:
		run.consume_potion(potion_id)
	potions_used += 1
	events.append({"type": "potion", "unit": u.id, "potion": potion_id, "name": String(sp.name), "target": target_id})
	_execute(u, sp, "potion_" + potion_id, target_id, false)
	_check_end()
	return true


func _enemy_act(u: Unit) -> void:
	if u.pattern.is_empty():
		return
	var act_id := String(u.pattern[u.pattern_i % u.pattern.size()])
	u.pattern_i += 1
	u.acted += 1
	var spec := spec_of(u, act_id)
	var target_id := _pick_target(u, spec)
	if String(spec.get("kind", "")) == "cast":
		u.casting = {"spell": act_id, "target": target_id}
		events.append({"type": "cast_start", "unit": u.id, "spell": act_id, "name": String(spec.name), "target": target_id, "heavy": bool(spec.get("heavy", false))})
		return
	_execute(u, spec, act_id, target_id, false)


func _pick_target(u: Unit, spec: Dictionary) -> String:
	var t := String(spec.get("target", "ally"))
	var foes := allies() if not u.ally else enemies()
	if foes.is_empty():
		return ""
	match t:
		"ally", "enemy":
			var total := 0.0
			for f in foes:
				total += f.aggro
			var r := rng.randf() * total
			for f in foes:
				r -= f.aggro
				if r <= 0.0:
					return f.id
			return foes[0].id
		"weakest":
			var best := foes[0]
			for f in foes:
				if f.hp_ratio() < best.hp_ratio():
					best = f
			return best.id
	return ""


func _fire_cast(u: Unit) -> void:
	var c := u.casting
	u.casting = {}
	var id := String(c.spell)
	var spec := spec_of(u, id)
	var target_id := String(c.get("target", ""))
	var t := find(target_id)
	if String(spec.get("target", "")) in ["ally", "enemy", "weakest"] and (t == null or not t.alive):
		var cands := targets_for(u, spec)
		target_id = cands[0].id if not cands.is_empty() else ""
	events.append({"type": "cast_fire", "unit": u.id, "spell": id, "name": String(spec.get("name", id))})
	_execute(u, spec, id, target_id, true)


func _gain_gauge(u: Unit, amount: float) -> void:
	if not u.has_gauge or amount <= 0.0 or not u.alive:
		return
	var before := u.gauge
	u.gauge = minf(u.gauge + amount * u.gauge_mult, TData.GAUGE_MAX)
	if u.gauge >= TData.GAUGE_MAX - 0.001 and before < TData.GAUGE_MAX - 0.001:
		events.append({"type": "gauge_full", "unit": u.id})


## 마법·행동·물약의 효과를 적용한다. spec은 TData.SPELLS / 적 actions / POTIONS 사양
func _execute(u: Unit, spec: Dictionary, id: String, target_id: String, from_cast: bool) -> void:
	var tt := String(spec.get("target", "enemy"))
	var targets: Array[Unit] = []
	match tt:
		"enemy", "ally", "weakest":
			var t := find(target_id)
			if t == null or not t.alive or (tt == "ally") != t.ally and u.ally:
				var cands := targets_for(u, spec)
				if cands.is_empty():
					return
				t = cands[0]
			targets = [t]
		"all", "enemies", "allies":
			targets = targets_for(u, spec)
		"self":
			targets = [u]
	if targets.is_empty():
		return
	var tids: Array[String] = []
	for t in targets:
		tids.append(t.id)
	events.append({"type": "act", "unit": u.id, "spell": id, "name": String(spec.get("name", id)), "kind": String(spec.get("kind", "")),
		"targets": tids, "from_cast": from_cast, "elem": String(spec.get("elem", ""))})
	if int(spec.get("actions", 0)) > 0 and player_phase:
		actions_left += int(spec.actions)
		events.append({"type": "actions", "unit": u.id, "amount": int(spec.actions), "left": actions_left})
	var power := float(spec.get("power", 0.0))
	var hits := int(spec.get("hits", 1))
	var interrupt := bool(spec.get("interrupt", false))
	var heavy := bool(spec.get("heavy", false))
	for t in targets:
		if interrupt and t.is_casting():
			if heavy or not is_heavy_cast(t):
				_interrupt(t, u)
			else:
				events.append({"type": "resist_interrupt", "unit": t.id, "by": u.id})
		if power > 0.0:
			for h in hits:
				if not t.alive:
					break
				var r := _calc(u, spec, t, power / float(hits))
				var dealt := _apply_damage(t, int(r.dmg), u)
				events.append({"type": "hit", "unit": u.id, "target": t.id, "spell": id, "dmg": dealt, "raw": int(r.dmg), "crit": r.crit, "weak": r.weak,
					"resist": r.resist, "space": r.space, "mult": r.mult, "hit_i": h, "hits": hits, "killed": not t.alive})
				if u.ally and dealt > max_hit:
					max_hit = dealt
					max_hit_info = {"unit": u.id, "spell": id, "target": t.id, "mult": r.mult, "crit": r.crit, "weak": r.weak, "dmg": dealt}
					if run:
						run.record_hit(dealt, max_hit_info)
				if t.alive and float(spec.get("burn", 0.0)) > 0.0 and h == hits - 1:
					t.burn_dmg = maxi(int(round(float(dealt) * float(spec.burn))), 1)
					t.burn_left = 3
					events.append({"type": "burn_set", "unit": t.id, "dmg": t.burn_dmg})
		if not t.alive:
			continue
		if bool(spec.get("skip", false)) and not t.ally:
			t.skip_next = true
			events.append({"type": "skip", "unit": t.id})
		if float(spec.get("heal", 0.0)) > 0.0:
			var amt := int(round(float(t.max_hp) * float(spec.heal)))
			var before := t.hp
			t.hp = mini(t.hp + amt, t.max_hp)
			events.append({"type": "heal", "unit": t.id, "amount": t.hp - before})
		for b in spec.get("buffs", []):
			_apply_buff(t, b, u.id, id)
		if float(spec.get("gauge_give", 0.0)) > 0.0:
			_gain_gauge(t, float(spec.gauge_give))


## 굳센 시전(heavy): 봉공·물약처럼 굳센 끊기만 멈춘다
func is_heavy_cast(t: Unit) -> bool:
	if not t.is_casting():
		return false
	return bool(spec_of(t, String(t.casting.spell)).get("heavy", false))


func _interrupt(t: Unit, by: Unit) -> void:
	var c := t.casting
	t.casting = {}
	var sp := spec_of(t, String(c.spell))
	events.append({"type": "interrupt", "unit": t.id, "by": by.id, "spell": String(c.spell), "name": String(sp.get("name", c.spell))})


func _apply_buff(t: Unit, spec: Dictionary, src_id: String, spell_id: String) -> void:
	if not t.alive:
		return
	var kind := String(spec.kind)
	var key := spell_id + ":" + kind
	var same: Array[Dictionary] = []
	for b in t.buffs:
		if b.key == key:
			same.append(b)
	var max_stack := int(spec.get("stack", 1))
	if same.size() >= max_stack:
		var oldest := same[0]
		for b in same:
			if int(b.left) < int(oldest.left):
				oldest = b
		oldest.left = int(spec.dur)
		if kind == "shield":
			oldest.amt = float(spec.amt)
	else:
		t.buffs.append({"key": key, "kind": kind, "amt": float(spec.amt), "left": int(spec.dur), "elem": String(spec.get("elem", "")), "src": src_id, "spell": spell_id})
	events.append({"type": "buff", "unit": t.id, "kind": kind, "amt": float(spec.amt), "stacks": t.stacks(key), "spell": spell_id, "src": src_id, "dur": int(spec.dur)})


func _cap(kind: String, raw: float) -> float:
	if kind == "def":
		return clampf(raw, TData.DEF_FLOOR, float(TData.CAPS.def))
	return minf(raw, float(TData.CAPS.get(kind, 9.0)))


func affinity(elem: String, t: Unit) -> float:
	if elem == TData.ELEM_SPACE:
		return TData.SPACE_MULT
	if elem != "" and elem == t.weak:
		return TData.WEAK_MULT
	if elem != "" and elem == t.resist:
		return TData.RESIST_MULT
	return 1.0


## 한 타의 피해와 배율 풀이
func _calc(u: Unit, sp: Dictionary, t: Unit, power: float) -> Dictionary:
	var elem := String(sp.get("elem", ""))
	var atk_k := 1.0 + _cap("atk", u.sum("atk"))
	var elem_raw := u.sum("elem", elem)
	if elem != "" and elem == u.elem:
		elem_raw += float(u.bonus.get("elem", 0.0))
	var elem_k := 1.0 + _cap("elem", elem_raw)
	var crit_rate := minf(TData.BASE_CRIT + u.sum("crit_rate") + float(u.bonus.get("crit_rate", 0.0)), float(TData.CAPS.crit_rate))
	var crit := rng.randf() < crit_rate
	var crit_k := 1.0
	if crit:
		crit_k = TData.BASE_CRIT_DMG + _cap("crit_dmg", u.sum("crit_dmg") + float(u.bonus.get("crit_dmg", 0.0)))
	var final_k := 1.0 + _cap("final", u.sum("final"))
	var vuln_k := 1.0 + _cap("vuln", t.sum("vuln"))
	var aff := affinity(elem, t)
	var def_val := t.def_ * (1.0 + _cap("def", t.sum("def")))
	var def_k := 100.0 / (100.0 + maxf(def_val, 0.0))
	var r := rng.randf_range(0.95, 1.05)
	var dmg := power * (u.atk / 100.0) * atk_k * elem_k * crit_k * final_k * vuln_k * aff * def_k * r
	return {"dmg": maxi(int(round(dmg)), 1), "crit": crit, "weak": aff > 1.01 and elem != TData.ELEM_SPACE, "space": elem == TData.ELEM_SPACE,
		"resist": aff < 0.99, "mult": {"atk": atk_k, "elem": elem_k, "crit": crit_k, "final": final_k, "vuln": vuln_k, "aff": aff, "def": def_k}}


## 피해 적용 (방벽 흡수 → 체력). 돌려주는 값 = 실제로 깎인 체력
func _apply_damage(t: Unit, dmg: int, src: Unit) -> int:
	var left := dmg
	for b in t.buffs:
		if b.kind == "shield" and left > 0:
			var absorb := mini(int(floor(float(b.amt))), left)
			b.amt = float(b.amt) - float(absorb)
			left -= absorb
			events.append({"type": "shield", "unit": t.id, "absorbed": absorb})
	var i := t.buffs.size() - 1
	while i >= 0:
		if t.buffs[i].kind == "shield" and float(t.buffs[i].amt) <= 0.5:
			t.buffs.remove_at(i)
		i -= 1
	if left <= 0:
		return 0
	t.hp -= left
	t.taken += left
	if src != null:
		src.dealt += left
		if src.ally:
			_gain_gauge(src, TData.HIT_GAUGE)
	_gain_gauge(t, TData.HURT_GAUGE)
	if t.hp <= 0:
		if not t.bars.is_empty() and t.bar_i < t.bars.size() - 1:
			_enter_bar(t, t.bar_i + 1, true)
		else:
			t.hp = 0
			t.alive = false
			t.casting = {}
			t.buffs.clear()
			events.append({"type": "die", "unit": t.id})
	return left


func _enter_bar(t: Unit, i: int, broke: bool) -> void:
	t.bar_i = i
	var bar: Dictionary = t.bars[i]
	t.max_hp = int(bar.hp)
	t.hp = t.max_hp
	t.def_ = float(bar.get("def", 0.0))
	t.weak = String(bar.get("weak", ""))
	t.resist = String(bar.get("resist", ""))
	t.pattern = (bar.get("pattern", t.pattern) as Array).duplicate()
	t.pattern_i = 0
	if broke:
		t.buffs.clear()
		t.casting = {}
		t.burn_left = 0
		t.skip_next = true
		events.append({"type": "break", "unit": t.id, "bar": i, "label": String(bar.get("label", "")), "weak": t.weak, "resist": t.resist})
	for b in bar.get("enter_buffs", []):
		_apply_buff(t, b, t.id, "bar" + str(i))


func _burn_tick(u: Unit) -> void:
	var dmg := u.burn_dmg
	u.burn_left -= 1
	if u.burn_left <= 0:
		u.burn_dmg = 0
	var dealt := _apply_damage(u, dmg, null)
	events.append({"type": "burn", "unit": u.id, "dmg": dealt, "killed": not u.alive})


func _check_end() -> void:
	if over:
		return
	if enemies().is_empty():
		over = true
		won = true
		events.append({"type": "end", "won": true})
	elif allies().is_empty():
		over = true
		won = false
		events.append({"type": "end", "won": false})


## 지금 시전 중인 적
func casting_enemies() -> Array[Unit]:
	var out: Array[Unit] = []
	for e in enemies():
		if e.is_casting():
			out.append(e)
	return out


func summary() -> Dictionary:
	var dealt := {}
	for u in allies(false):
		dealt[u.id] = u.dealt
	return {"won": won, "rounds": round, "turns": turns, "max_hit": max_hit, "max_hit_info": max_hit_info, "dealt": dealt, "potions": potions_used,
		"battle": String(battle.get("name", ""))}
