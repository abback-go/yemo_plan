class_name TUnit
extends RefCounted
## 턴제 전투의 한 명 (마녀 또는 적) — 능력치·게이지·크레딧·버프·징표·상태. 그림·노드는 TActor가 따로 든다.
## 버프 사전: {cat, v, dur, clock("own"|"enemy"), mark?, el?, name, per_mark?, count?, on?, born?}
##   per_mark    = 대상의 그 징표 겹 수를 곱한다 (특공은 늘 곱함)
##   count · on  = 횟수제 (§16.8): on("basic" 기본 공격 | "skill" 공격 마법 | "attack" 둘 다)을 마칠 때마다 count −1, 0이면 사라짐. born = 건 차례 번호 (그 차례엔 닳지 않음)
##   clock own   = 이 유닛이 행동(또는 쉼)을 마칠 때마다 dur −1 (아군에게 건 버프 · 적에게 건 디버프·징표)
##   clock enemy = 적이 행동을 마칠 때마다 dur −1 (무적 · 받는 피해 감소 · 도발 · 근성처럼 "다음 적 공격"을 막는 것)
## 징표: marks[kind] = {n: 겹 1~5, dur: 남은 행동 수} (combat_proto.md §17.1)
## [단계 F-2] 적이 마녀에게 건 나쁜 효과(약화)는 버프 목록에 bad = true — 보스 해제가 남긴다 (review_H §2.1). 적의 자기 보호: dmg_cut(방어 태세) · cover(막아서기)
## [R5 — review_M M1] max_hp {v, add(실제로 더한 최대 체력)} · debuff_block {n(남은 막기 수)} · cost_down {v(줄일 비용)} — 버프 칸. 예약(delay)은 버프가 아니라 delayed 목록

var id := ""
var name := ""
var side := "witch" ## "witch" | "enemy"
var slot := 0 ## 자리 (앞 0 · 중 1 · 뒤 2)
var base_atk := 0
var atk := 0
var max_hp := 1
var hp := 1
var speed := 100
var def_rate := 0.0
var element := "none"
var special := false ## 무상성 (특수 속성 1.2배)
var gauge := 0.0
var credits := 0
var buffs: Array[Dictionary] = []
var marks := {} ## kind → {n, dur}
var alive := true
var equip := "" ## 장비 id (마녀)
var equip_lv := 1 ## 장비 강화 레벨 1~3
var skill_lv := {} ## 마법 id → 강화 레벨 (없으면 1)
var equipped: Array[String] = [] ## 장착 마법 id (마녀)
var passive: Array = [] ## 패시브 효과 목록 (마녀, §15.6). 버프가 아니므로 해제되지 않는다
var pattern: Array = [] ## 적 행동 패턴 (조건 규칙이 바꿀 수 있다)
var intent_i := 0
var intent_now := {} ## 확정된 다음 의도 (§18.2). 비어 있으면 패턴 위치의 것
var intent_src := "pattern" ## intent_now의 출처: pattern · insert · charge · break (pattern일 때만 실행 뒤 패턴 위치가 넘어간다)
var rule_pat := -1 ## 패턴을 바꾼 규칙 번호 (-1 = 기본 패턴)
var tier := "normal" ## 적 등급 normal · elite · boss
var resist := 0.0 ## 디버프 내성 (§16.5)
var stun_immune := false
var weak: Array = [] ## 약점인 공격 속성 (적)
var charge := 0 ## 차지 칸 (§18.5)
var charge_max := 0
var bars: Array = [] ## 여러 줄 체력 (§18.6). 비어 있으면 한 줄
var bar_i := 0
var boss := false
var stunned := false ## 기절: 다음 차례를 쉰다 (§17.2)
var stun_guard := false ## 기절로 쉰 뒤 다음 자기 차례가 끝날 때까지 기절에 걸리지 않음
var guts_used := false ## 장비 근성을 썼나 (전투당 1번)
var inv_guard := 0 ## 무적 내성 (§17.12): 무적이 공격을 막으면 3 → 적 행동이 끝날 때마다 −1. 0보다 크면 새 무적이 걸리지 않음 (= 막은 뒤 적 행동 2번 동안)
var zero_after_turn := -1 ## 불의 신 강림의 대가: 이 차례 번호보다 뒤의 행동이 끝나면 크레딧 0
var pending_gauge := 0.0 ## 자기 게이지 +N% — 행동이 끝나 0이 된 뒤 더한다
var last_k := "" ## 적: 마지막으로 실행한 의도 종류
var hit_kind := "" ## 피해 계산 중인 공격의 종류 basic · skill (횟수제 버프는 자기 종류의 공격에만 붙는다, TBattle._terms가 정함)
var last_act := "" ## 마녀: 이번 행동의 종류 basic · attack · support · rest (횟수제 버프가 닳는 기준)
var data := {} ## 원본 데이터 (그림 색 등)
var acted := 0 ## 행동(쉼 포함) 횟수 (통계)
var acts := 0 ## 실제로 행동한 횟수 (적의 조건 규칙 acted)
var dealt := 0 ## 준 피해 합 (통계)
# ── 단계 F-2 (review_H_enemies.md)
var traits: Array = [] ## 적 특성 (TData.TRAIT_NAME)
var ecrit := TData.ENEMY_CRIT_BASE ## 적 크리 확률 (크리 다운 디버프 전)
var leader := false ## 우두머리: 쓰러지면 같은 웨이브의 나머지도 사라짐 (§18.6)
var summon_cap := 0 ## 이 적이 한 웨이브에 부를 수 있는 수
var sealed := 0 ## 마녀 봉인: 1 = 장착 마법·대마법 못 씀 · 2 = 대마법만 못 씀. 다음 자기 차례가 끝나면 풀림
var seal_guard := false ## 봉인이 풀린 뒤 그다음 자기 차례가 끝날 때까지 봉인되지 않음
# ── R5 (review_M M1)
var base_max_hp := 1 ## 장비를 반영한 기본 최대 체력 (최대 체력 버프의 기준 · 상한)
var delayed: Array = [] ## 예약: [{effects}] — 다음 자기 차례가 시작될 때 실행 (TBattle.next_actor)
var _eq := {}


static func make_witch(wid: String, setup: Dictionary, slot_i: int) -> TUnit:
	var d: Dictionary = TData.WITCHES[wid]
	var u := TUnit.new()
	u.id = wid
	u.name = d.name
	u.side = "witch"
	u.slot = slot_i
	u.data = d
	u.base_atk = int(d.atk)
	u.max_hp = int(d.hp)
	u.hp = u.max_hp
	u.speed = int(d.speed)
	u.def_rate = float(d.def)
	u.element = String(d.element)
	u.special = bool(d.special)
	u.equip = String(setup.get("equip", ""))
	u.equip_lv = clampi(int(setup.get("equip_lv", 1)), 1, 3)
	u.skill_lv = setup.get("skill_lv", {})
	for s in setup.get("equipped", d.default):
		u.equipped.append(String(s))
	u.passive = d.get("passive", {}).get("effects", [])
	u._eq = TData.equip_at(u.equip, u.equip_lv)
	var eq := u._eq
	u.atk = int(round(float(u.base_atk) * (1.0 + float(eq.get("atk", 0.0)))))
	u.max_hp = int(round(float(u.max_hp) * (1.0 + float(eq.get("hp", 0.0)))))
	u.base_max_hp = u.max_hp
	u.hp = u.max_hp
	u.speed += int(eq.get("speed", 0))
	u.gauge = TData.GAUGE_MAX * float(eq.get("start_gauge", 0.0))
	u.credits = mini(int(eq.get("start_credits", 0)), TData.CREDIT_MAX)
	return u


## over: 전투 데이터의 덮어쓰기 {hp}
static func make_enemy(eid: String, slot_i: int, over := {}) -> TUnit:
	var d: Dictionary = TData.ENEMIES[eid]
	var u := TUnit.new()
	u.id = eid
	u.name = d.name
	u.side = "enemy"
	u.slot = slot_i
	u.data = d
	u.base_atk = int(d.atk)
	u.atk = u.base_atk
	u.bars = d.get("bars", [])
	u.max_hp = int(u.bars[0]) if not u.bars.is_empty() else int(over.get("hp", d.get("hp", 1)))
	u.base_max_hp = u.max_hp
	u.hp = u.max_hp
	u.speed = int(d.speed)
	u.def_rate = float(d.def)
	u.element = String(d.element)
	if d.has("weak"):
		u.weak = d.weak
	elif String(TData.WEAK_TO.get(u.element, "")) != "":
		u.weak = [String(TData.WEAK_TO[u.element])]
	u.tier = String(d.get("tier", "normal"))
	u.resist = float(d.get("resist", TData.RESIST.get(u.tier, 0.0)))
	u.stun_immune = bool(d.get("stun_immune", u.tier == "boss"))
	u.boss = u.tier == "boss"
	u.charge_max = int(d.get("charge_max", 0))
	u.pattern = d.pattern
	u.traits = d.get("traits", [])
	u.passive = d.get("passive", []) # 적 고유 효과 (mark_cap · guard_allies · first_strike) — 마녀 패시브와 같은 칸, t가 겹치지 않음
	u.ecrit = float(d.get("crit", TData.ENEMY_CRIT_BASE))
	u.leader = bool(d.get("leader", false))
	u.summon_cap = int(d.get("summon_cap", 0))
	return u


func is_witch() -> bool:
	return side == "witch"


func hp_ratio() -> float:
	return clampf(float(hp) / float(max_hp), 0.0, 1.0)


## 남은 줄 수 (지금 줄 포함, 한 줄이면 1)
func bars_left() -> int:
	return maxi(bars.size() - bar_i, 1)


## 머리 위에 보이는 다음 의도 (확정된 것, 없으면 패턴 위치)
func intent() -> Dictionary:
	if not intent_now.is_empty():
		return intent_now
	if pattern.is_empty():
		return {}
	return pattern[intent_i % pattern.size()]


func equip_data() -> Dictionary:
	return _eq


# ── 징표 (겹 · 남은 수)

func mark_n(kind: String) -> int:
	return int(marks[kind].n) if marks.has(kind) else 0


func mark_dur(kind: String) -> int:
	return int(marks[kind].dur) if marks.has(kind) else 0


## 그 징표의 최대 겹 (고유 효과 mark_cap)
func mark_cap(kind: String) -> int:
	var cap := TData.MARK_MAX
	for e in passive:
		if String(e.get("t", "")) == "mark_cap" and String(e.get("kind", "")) == kind:
			cap = mini(cap, int(e.n))
	return cap


## 징표 겹 합 (조건 self_marks)
func marks_total() -> int:
	var n := 0
	for k in marks:
		n += int(marks[k].n)
	return n


## 징표 n겹을 건다: 겹 = min(지금 + n, 상한), 남은 수 = max(지금, dur). 돌려준 값 = 새 겹 수.
## 상한 = MARK_MAX, 적 고유 효과 mark_cap(그 징표 최대 n겹 — 반감이 아니라 겹만 막음, review_H §3)이 있으면 그것
func add_mark(kind: String, dur: int, n := 1) -> int:
	var m: Dictionary = marks.get(kind, {"n": 0, "dur": 0})
	m["n"] = mini(int(m.n) + maxi(n, 1), mark_cap(kind))
	m["dur"] = maxi(int(m.dur), dur)
	marks[kind] = m
	return int(m.n)


# ── 패시브

## 패시브 효과 중 t인 것의 v 합
func passive_val(t: String) -> float:
	var s := 0.0
	for e in passive:
		if String(e.t) == t:
			s += float(e.get("v", 0.0))
	return s


## 패시브 효과 중 t이고 cat이 맞는 것의 v 합 (엠버 buff_plus 등)
func passive_cat_val(t: String, cat: String) -> float:
	var s := 0.0
	for e in passive:
		if String(e.t) == t and String(e.get("cat", "")) == cat:
			s += float(e.get("v", 0.0))
	return s


## 내가 거는 그 징표에 더해지는 겹 수 (신더)
func passive_mark_plus(kind: String) -> int:
	var n := 0
	for e in passive:
		if String(e.t) == "mark_plus" and String(e.kind) == kind:
			n += int(e.n)
	return n


## 지금 공격 속성 (속성 부여 버프가 있으면 그것 — 마지막에 건 것)
func attack_element() -> String:
	var el := element
	var eq_el := String(equip_data().get("element", ""))
	if eq_el != "":
		el = eq_el
	for b in buffs:
		if b.cat == "element":
			el = String(b.el)
	return el


## 속성 부여가 있나 (버프 또는 장비) — 있으면 무상성 1.2배 대신 그 속성의 약점 판정
func has_element_buff() -> bool:
	if String(equip_data().get("element", "")) != "":
		return true
	for b in buffs:
		if b.cat == "element":
			return true
	return false


## 종류별 합 (상한 적용). mark 조건이 있는 것은 대상에게 그 징표가 있을 때만 — 특공(special)·per_mark는 그 징표의 겹을 곱한다
## (특공은 attack_el이 그 징표의 속성 TData.MARK_EL일 때만 겹을 곱하고, 아니면 1겹 값 — F-4 P1).
## el 조건이 있는 버프는 공격 속성이 맞을 때만. 패시브 상시 보정(stat)도 여기서 더한다:
##   stat {cat, v, mark?, per_mark?, own_el?, max?} — own_el이면 자기 속성 공격일 때만(부여받은 속성엔 안 붙음), max는 이 패시브의 상한
func cat_sum(cat: String, target: TUnit = null, attack_el := "") -> float:
	var s := 0.0
	for b in buffs:
		if b.cat != cat:
			continue
		if b.has("count") and hit_kind != "":
			var on := String(b.get("on", "attack"))
			if (on == "basic" and hit_kind != "basic") or (on == "skill" and hit_kind != "skill"):
				continue # 횟수제: 기본 공격 버프는 기본 공격에만, 공격 마법 버프는 공격 마법에만
		var v := float(b.get("v", 0.0))
		if b.has("mark"):
			if target == null or not target.marks.has(b.mark):
				continue
			if cat == "special" or bool(b.get("per_mark", false)):
				var n := target.mark_n(String(b.mark))
				if cat == "special" and attack_el != String(TData.MARK_EL.get(String(b.mark), "")):
					n = mini(n, 1) # 징표 특공은 그 속성 공격일 때만 겹을 곱한다 — 다른 속성은 1겹 값 (F-4 P1)
				v *= float(n)
		if b.has("el") and cat != "element" and attack_el != String(b.el):
			continue
		s += v
	for e in passive:
		if String(e.t) != "stat" or String(e.cat) != cat:
			continue
		if e.has("mark") and (target == null or not target.marks.has(e.mark)):
			continue
		if bool(e.get("own_el", false)) and attack_el != element:
			continue
		var pv := float(e.v)
		if e.has("mark") and bool(e.get("per_mark", false)):
			pv *= float(target.mark_n(String(e.mark)))
		if e.has("max"):
			pv = minf(pv, float(e.max))
		s += pv
	var cap := float(TData.CAP.get(cat, 99.0))
	if cat == "dmg_taken":
		return clampf(s, -0.7, cap)
	return minf(s, cap)


func add_buff(b: Dictionary) -> void:
	buffs.append(b)


func has_buff(cat: String) -> bool:
	for b in buffs:
		if b.cat == cat:
			return true
	return false


## 이로운 버프 수 (적이 건 나쁜 효과 bad는 빼고 — 해제 조건 witch_buffs · 해제 알약 "버프 n")
func good_buffs() -> int:
	var n := 0
	for b in buffs:
		if not bool(b.get("bad", false)):
			n += 1
	return n


## 그 마법이 건 버프가 남아 있나 (자동 선택용)
func has_skill_buff(sid: String) -> bool:
	for b in buffs:
		if String(b.get("sid", "")) == sid:
			return true
	return false


func is_invincible() -> bool:
	return has_buff("invincible")


## 도발 중인가 (마법 도발 또는 장비 상시 도발)
func is_taunting() -> bool:
	return alive and (has_buff("taunt") or bool(equip_data().get("taunt", false)))


## 횟수제 버프를 닳게 한다 (§16.8): 이번 행동 종류 kind가 버프의 on과 맞고, 이번 차례 전에 건 것만
func consume_counts(kind: String, turn: int) -> void:
	var keep: Array[Dictionary] = []
	for b in buffs:
		if b.has("count") and int(b.get("born", -1)) < turn:
			var on := String(b.get("on", "attack"))
			if (on == "basic" and kind == "basic") or (on == "skill" and kind == "attack") or (on == "attack" and kind in ["basic", "attack"]):
				b.count = int(b.count) - 1
				if int(b.count) <= 0:
					continue
		keep.append(b)
	buffs = keep


## 이 유닛이 행동(또는 쉼)을 마침: own 시계 버프·징표 −1
func on_own_acted() -> void:
	acted += 1
	_tick("own")
	var gone: Array = []
	for k in marks:
		marks[k].dur = int(marks[k].dur) - 1
		if int(marks[k].dur) <= 0:
			gone.append(k)
	for k in gone:
		marks.erase(k) # 겹째로 사라진다


## 적이 행동을 마침 (마녀에게): enemy 시계 버프 −1 · 무적 내성 −1
func on_enemy_acted() -> void:
	_tick("enemy")
	inv_guard = maxi(inv_guard - 1, 0)


func _tick(clock: String) -> void:
	var keep: Array[Dictionary] = []
	for b in buffs:
		if b.get("clock", "own") == clock:
			b.dur = int(b.dur) - 1
			if int(b.dur) <= 0:
				_buff_gone(b)
				continue
		keep.append(b)
	buffs = keep


## 버프를 거른다 (keep이 true인 것만 남김) — 사라지는 최대 체력 버프는 최대 체력을 되돌린다 (적의 해제 · 정화). 지운 수
func drop_buffs(keep: Callable) -> int:
	var out: Array[Dictionary] = []
	var n := 0
	for b in buffs:
		if keep.call(b):
			out.append(b)
		else:
			_buff_gone(b)
			n += 1
	buffs = out
	return n


## 버프 하나가 사라짐: 최대 체력 버프면 더했던 만큼 최대에서 빼고 지금 체력을 새 최대로 자른다 (1 아래로 안 감, R5 §17.13)
func _buff_gone(b: Dictionary) -> void:
	if String(b.get("cat", "")) == "max_hp" and int(b.get("add", 0)) > 0:
		max_hp = maxi(max_hp - int(b.add), 1)
		if alive:
			hp = clampi(hp, 1, max_hp)


## 최대 체력 +기본 × v (지금 체력도 같은 만큼 +). 합 상한 기본 × CAP.max_hp — 넘는 몫은 버림. 더한 값
func gain_max_hp(v: float) -> int:
	var now := 0
	for b in buffs:
		if String(b.get("cat", "")) == "max_hp":
			now += int(b.get("add", 0))
	var add := clampi(int(round(float(base_max_hp) * v)), 0, maxi(int(round(float(base_max_hp) * float(TData.CAP.max_hp))) - now, 0))
	max_hp += add
	hp += add
	return add


## 이 공격에 붙는 쌓인 힘 겹 수 (맞으며 쌓기로 받은 공격력 겹 — stack_src가 있는 버프, §17.11)
func stack_n() -> int:
	var n := 0
	for b in buffs:
		if b.has("stack_src"):
			n += 1
	return n


## 다음 장착 마법에서 줄어드는 비용 (비용 감소 버프 합)
func cost_cut() -> int:
	var n := 0
	for b in buffs:
		if String(b.get("cat", "")) == "cost_down":
			n += int(round(float(b.get("v", 0.0))))
	return n


## 남은 약화 막기 수
func blocks_left() -> int:
	var n := 0
	for b in buffs:
		if String(b.get("cat", "")) == "debuff_block":
			n += int(b.get("n", 0))
	return n


## own 시계 버프 전부 지속 +v (시간의 마녀)
func extend_buffs(v: int) -> int:
	var n := 0
	for b in buffs:
		if b.get("clock", "own") == "own":
			b.dur = int(b.dur) + v
			n += 1
	return n


## 피해를 받는다. 돌려줌 {killed, guts, broke}: 줄이 깨지면(broke) 넘친 피해는 버리고 다음 줄로 (§18.6),
## 쓰러질 피해면 근성(마법 근성 지속 짧은 것부터 → 장비 근성)으로 버틴다 (§17.4)
func take_damage(v: int) -> Dictionary:
	var r := {"killed": false, "guts": false, "broke": false}
	if not alive:
		return r
	hp = maxi(hp - v, 0)
	if hp > 0:
		return r
	if bar_i < bars.size() - 1:
		bar_i += 1
		max_hp = int(bars[bar_i])
		hp = max_hp
		r.broke = true
		return r
	if _use_guts():
		r.guts = true
		return r
	alive = false
	for b in buffs:
		_buff_gone(b) # 최대 체력 버프는 되돌림 (되살림이 기본 최대 기준이 되게)
	buffs.clear()
	delayed.clear()
	marks.clear()
	stunned = false
	stun_guard = false
	sealed = 0
	seal_guard = false
	inv_guard = 0
	gauge = 0.0
	pending_gauge = 0.0
	r.killed = true
	return r


func _use_guts() -> bool:
	var best := -1
	for i in buffs.size():
		if buffs[i].cat == "guts" and (best < 0 or int(buffs[i].dur) < int(buffs[best].dur)):
			best = i
	if best >= 0:
		var pct := float(buffs[best].get("v", 0.0))
		buffs.remove_at(best)
		hp = maxi(int(round(float(max_hp) * pct)), 1)
		return true
	var once := float(equip_data().get("guts_once", 0.0))
	if once > 0.0 and not guts_used:
		guts_used = true
		hp = maxi(int(round(float(max_hp) * once)), 1)
		return true
	return false


func heal(v: int) -> int:
	if not alive:
		return 0
	var before := hp
	hp = mini(hp + v, max_hp)
	return hp - before


func revive(pct: float) -> void:
	alive = true
	hp = maxi(int(round(float(max_hp) * pct)), 1)
	gauge = 0.0
	pending_gauge = 0.0
	stunned = false
	stun_guard = false
	sealed = 0
	seal_guard = false


## 머리 위·바퀴에 보여 줄 버프 아이콘 목록 [{cat, v, dur, el?, mark?}] (같은 종류는 하나로 합침)
func buff_icons() -> Array:
	var by := {}
	var order: Array = []
	for b in buffs:
		var key := String(b.cat)
		if b.cat == "special":
			key += ":" + String(b.get("mark", ""))
		if not by.has(key):
			by[key] = {"cat": b.cat, "v": 0.0, "dur": 0, "el": b.get("el", ""), "mark": b.get("mark", "")}
			order.append(key)
		by[key].v = float(by[key].v) + float(b.get("v", 0.0))
		by[key].dur = maxi(int(by[key].dur), int(b.count) if b.has("count") else (int(b.get("n", 0)) if b.cat == "debuff_block" else int(b.dur))) # 횟수제·약화 막기는 남은 횟수
	var out: Array = []
	for k in order:
		out.append(by[k])
	return out


# ── 저장 (전투 이어하기, combat_proto.md §28.4): 데이터(data·_eq)는 id로 다시 만들고 바뀌는 값만 담는다
const SAVE_KEYS := ["hp", "max_hp", "atk", "speed", "def_rate", "element", "gauge", "credits", "buffs", "marks", "alive", "pattern", "intent_i", "intent_now",
	"intent_src", "rule_pat", "charge", "bar_i", "stunned", "stun_guard", "guts_used", "inv_guard", "zero_after_turn", "pending_gauge", "last_k", "last_act",
	"acted", "acts", "dealt", "weak", "resist", "passive", "sealed", "seal_guard", "delayed"]


func to_dict() -> Dictionary:
	var d := {"id": id, "side": side, "slot": slot}
	if is_witch():
		d["setup"] = {"equipped": equipped.duplicate(), "equip": equip, "equip_lv": equip_lv, "skill_lv": skill_lv.duplicate()}
	for k in SAVE_KEYS:
		var v = get(k)
		d[k] = v.duplicate(true) if (v is Array or v is Dictionary) else v
	return d


static func from_dict(d: Dictionary) -> TUnit:
	var u: TUnit
	if String(d.side) == "witch":
		u = make_witch(String(d.id), d.setup, int(d.slot))
	else:
		u = make_enemy(String(d.id), int(d.slot))
	for k in SAVE_KEYS:
		if not d.has(k):
			continue
		var v = d[k]
		if k == "buffs":
			u.buffs.assign(v)
		else:
			u.set(k, v.duplicate(true) if (v is Array or v is Dictionary) else v)
	return u

