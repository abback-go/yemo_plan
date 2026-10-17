class_name TRun
extends RefCounted
## 한 판(런)의 상태: 파티·레벨·해금한 마법·빗자루·물약 가방·수업 점수·최고 한 방. 저장하지 않는다(세션 메모리).
## 전투 코어(TBattle)는 여기서 stats()로 마녀의 시작 능력치를 받는다.

static var current: TRun

var party: Array[String] = ["eska", "sera", "ashe"]
var levels := {}
var unlocked := {} ## 마녀 → 해금한 마법 id 목록
var brooms := {} ## 마녀 → 빗자루 id ("" = 없음)
var pouch := {} ## 물약 id → 가진 수
var bag: Array[String] = [] ## 이번 전투에 들고 갈 물약 (TData.BAG_SIZE개까지, 쓰면 pouch에서 빠짐)
var points := 0 ## 수업 점수 (마법 해금에 씀)
var battle_i := 0 ## 다음에 할 전투 번호
var best_hit := 0
var best_hit_info := {}
var won := 0
var summaries: Array[Dictionary] = []
var auto := false ## 자동 전투 (TPolicy가 아군을 조작)
var dealer := "eska" ## 자동 전투의 딜러


func _init() -> void:
	reset()


func reset() -> void:
	levels = {}
	unlocked = {}
	brooms = {}
	for w in party:
		levels[w] = 1
		var starts: Array = TData.witch(w).get("start", [])
		var arr: Array[String] = []
		for s in starts:
			arr.append(String(s))
		unlocked[w] = arr
	brooms = {"eska": "glass", "sera": "cinder", "ashe": "raven"}
	pouch = TData.POUCH_START.duplicate()
	bag = ["heal", "haste", "bind"]
	points = 0
	battle_i = 0
	best_hit = 0
	best_hit_info = {}
	won = 0
	summaries = []


## 마녀의 시작 능력치 (레벨·빗자루 반영)
func stats(w: String) -> Dictionary:
	var base: Dictionary = TData.witch(w)
	var lv: int = levels.get(w, 1)
	var g: Dictionary = base.get("growth", {})
	var hp := int(round(float(base.hp) * (1.0 + float(g.get("hp", 0.0)) * float(lv - 1))))
	var atk := float(base.atk) * (1.0 + float(g.get("atk", 0.0)) * float(lv - 1))
	var b: Dictionary = TData.BROOMS.get(brooms.get(w, ""), {})
	return {
		"hp": hp, "atk": atk, "wait": maxf(float(base.wait) + float(b.get("wait", 0.0)), 1.0),
		"crit_rate": float(b.get("crit_rate", 0.0)), "crit_dmg": float(b.get("crit_dmg", 0.0)),
		"elem": float(b.get("elem", 0.0)), "gauge_mult": float(b.get("gauge_mult", 1.0)),
		"level": lv,
	}


func is_unlocked(w: String, spell_id: String) -> bool:
	return spell_id in (unlocked.get(w, []) as Array)


func spell_cost(spell_id: String) -> int:
	return int(TData.spell(spell_id).get("cost", 1))


func can_learn(w: String, spell_id: String) -> bool:
	return not is_unlocked(w, spell_id) and points >= spell_cost(spell_id)


func learn(w: String, spell_id: String) -> bool:
	if not can_learn(w, spell_id):
		return false
	points -= spell_cost(spell_id)
	(unlocked[w] as Array[String]).append(spell_id)
	return true


## 해금한 마법을 마녀 표의 순서대로
func spells_of(w: String) -> Array[String]:
	var out: Array[String] = []
	for s in TData.witch(w).get("spells", []):
		if is_unlocked(w, String(s)):
			out.append(String(s))
	return out


## 빗자루 끼우기 — 한 자루는 한 마녀만. 다른 마녀가 들고 있으면 서로 바꾼다
func set_broom(w: String, broom: String) -> void:
	var prev: String = brooms.get(w, "")
	for other in party:
		if other != w and brooms.get(other, "") == broom:
			brooms[other] = prev
	brooms[w] = broom


func broom_owner(broom: String) -> String:
	for w in party:
		if brooms.get(w, "") == broom:
			return w
	return ""


## 가방에 물약 넣기/빼기 (가진 수 안에서, BAG_SIZE까지)
func toggle_bag(potion: String) -> void:
	var idx := bag.find(potion)
	if idx >= 0:
		bag.remove_at(idx)
		return
	if bag.size() >= TData.BAG_SIZE:
		return
	if bag.count(potion) < int(pouch.get(potion, 0)):
		bag.append(potion)


## 전투에서 물약을 썼다
func consume_potion(potion: String) -> void:
	pouch[potion] = maxi(int(pouch.get(potion, 0)) - 1, 0)
	var idx := bag.find(potion)
	if idx >= 0:
		bag.remove_at(idx)


## 가방 정리: 가진 수보다 많이 들어 있으면 뺀다
func tidy_bag() -> void:
	var fixed: Array[String] = []
	for p in bag:
		if fixed.count(p) < int(pouch.get(p, 0)) and fixed.size() < TData.BAG_SIZE:
			fixed.append(p)
	bag = fixed


func current_battle() -> Dictionary:
	if battle_i < 0 or battle_i >= TData.BATTLES.size():
		return {}
	return TData.BATTLES[battle_i]


func finished() -> bool:
	return battle_i >= TData.BATTLES.size()


## 이긴 뒤: 점수·경험치(레벨)·요약
func battle_won(summary: Dictionary) -> void:
	var b := current_battle()
	points += int(b.get("points", 0))
	for w in party:
		var g: Dictionary = TData.witch(w).get("growth", {})
		if float(g.get("atk", 0.0)) > 0.0 or float(g.get("hp", 0.0)) > 0.0:
			levels[w] = mini(int(levels[w]) + int(b.get("xp", 1)), TData.LEVEL_MAX)
	won += 1
	battle_i += 1
	summaries.append(summary)
	tidy_bag()


func record_hit(dmg: int, info: Dictionary) -> void:
	if dmg > best_hit:
		best_hit = dmg
		best_hit_info = info
