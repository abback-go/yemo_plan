class_name TUnit
extends RefCounted
## 턴제 전투의 한 명 (마녀 또는 적) — 능력치·게이지·크레딧·버프·징표. 그림·노드는 TActor가 따로 든다.
## 버프 사전: {cat, v, dur, clock("own"|"enemy"), mark?, el?, name}
##   clock own   = 이 유닛이 행동을 마칠 때마다 dur −1 (아군에게 건 버프 · 적에게 건 디버프·징표)
##   clock enemy = 적이 행동을 마칠 때마다 dur −1 (무적 · 받는 피해 감소처럼 "다음 적 공격"을 막는 것)

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
var marks := {} ## kind → 남은 적 행동 수
var alive := true
var equip := "" ## 장비 id (마녀)
var equipped: Array[String] = [] ## 장착 마법 id (마녀)
var pattern: Array = [] ## 적 행동 패턴
var intent_i := 0
var boss := false
var zero_after_turn := -1 ## 불의 신 강림의 대가: 이 차례 번호보다 뒤의 행동이 끝나면 크레딧 0
var pending_gauge := 0.0 ## 자기 게이지 +N% — 행동이 끝나 0이 된 뒤 더한다
var data := {} ## 원본 데이터 (그림 색 등)
var acted := 0 ## 행동 횟수 (통계)
var dealt := 0 ## 준 피해 합 (통계)


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
	for s in setup.get("equipped", d.default):
		u.equipped.append(String(s))
	var eq: Dictionary = TData.EQUIPS.get(u.equip, {})
	u.atk = int(round(float(u.base_atk) * (1.0 + float(eq.get("atk", 0.0)))))
	u.credits = mini(int(eq.get("start_credits", 0)), TData.CREDIT_MAX)
	return u


static func make_enemy(eid: String, slot_i: int) -> TUnit:
	var d: Dictionary = TData.ENEMIES[eid]
	var u := TUnit.new()
	u.id = eid
	u.name = d.name
	u.side = "enemy"
	u.slot = slot_i
	u.data = d
	u.base_atk = int(d.atk)
	u.atk = u.base_atk
	u.max_hp = int(d.hp)
	u.hp = u.max_hp
	u.speed = int(d.speed)
	u.def_rate = float(d.def)
	u.element = String(d.element)
	u.pattern = d.pattern
	u.boss = bool(d.get("boss", false))
	return u


func is_witch() -> bool:
	return side == "witch"


func hp_ratio() -> float:
	return clampf(float(hp) / float(max_hp), 0.0, 1.0)


func intent() -> Dictionary:
	if pattern.is_empty():
		return {}
	return pattern[intent_i % pattern.size()]


func equip_data() -> Dictionary:
	return TData.EQUIPS.get(equip, {})


## 지금 공격 속성 (속성 부여 버프가 있으면 그것 — 마지막에 건 것)
func attack_element() -> String:
	var el := element
	for b in buffs:
		if b.cat == "element":
			el = String(b.el)
	return el


func has_element_buff() -> bool:
	for b in buffs:
		if b.cat == "element":
			return true
	return false


## 종류별 합 (상한 적용). special은 대상에게 징표가 있는 것만, el 조건이 있는 버프는 공격 속성이 맞을 때만
func cat_sum(cat: String, target: TUnit = null, attack_el := "") -> float:
	var s := 0.0
	for b in buffs:
		if b.cat != cat:
			continue
		if b.has("mark"):
			if target == null or not target.marks.has(b.mark):
				continue
		if b.has("el") and cat != "element" and attack_el != String(b.el):
			continue
		s += float(b.get("v", 0.0))
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


func is_invincible() -> bool:
	return has_buff("invincible")


## 이 유닛이 행동을 마침: own 시계 버프·징표 −1
func on_own_acted() -> void:
	acted += 1
	_tick("own")
	var gone: Array = []
	for k in marks:
		marks[k] = int(marks[k]) - 1
		if int(marks[k]) <= 0:
			gone.append(k)
	for k in gone:
		marks.erase(k)


## 적이 행동을 마침 (마녀에게): enemy 시계 버프 −1
func on_enemy_acted() -> void:
	_tick("enemy")


func _tick(clock: String) -> void:
	var keep: Array[Dictionary] = []
	for b in buffs:
		if b.get("clock", "own") == clock:
			b.dur = int(b.dur) - 1
			if int(b.dur) <= 0:
				continue
		keep.append(b)
	buffs = keep


## own 시계 버프 전부 지속 +v (시간의 마녀)
func extend_buffs(v: int) -> int:
	var n := 0
	for b in buffs:
		if b.get("clock", "own") == "own":
			b.dur = int(b.dur) + v
			n += 1
	return n


func take_damage(v: int) -> bool:
	hp = maxi(hp - v, 0)
	if hp <= 0 and alive:
		alive = false
		buffs.clear()
		marks.clear()
		gauge = 0.0
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
		by[key].dur = maxi(int(by[key].dur), int(b.dur))
	var out: Array = []
	for k in order:
		out.append(by[k])
	return out
