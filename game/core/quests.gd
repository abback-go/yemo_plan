class_name Quests
extends RefCounted
## 퀘스트 (docs/systems2.md 4절): 장별 data 파일의 QUESTS를 모아 상태를 GameState 플래그로 관리한다.
##   q_<id> = 0 없음 · 1 진행 · 2 완료, q_<id>_step = 지금 단계(0부터)
## kind: side(서브) · class(마법 수업) · main(메인 곁가지)

static func all() -> Dictionary:
	return ChapterRegistry.quests()


static func def(id: String) -> Dictionary:
	return all().get(id, {})


static func state(id: String) -> int:
	return int(GameState.flag("q_" + id, 0))


static func step(id: String) -> int:
	return int(GameState.flag("q_" + id + "_step", 0))


static func active(id: String) -> bool:
	return state(id) == 1


static func done(id: String) -> bool:
	return state(id) == 2


static func start(id: String) -> void:
	if state(id) != 0:
		return
	GameState.set_flag("q_" + id, 1)
	GameState.set_flag("q_" + id + "_step", 0)
	GameState.set_flag("q_last", id)
	Sfx.play(&"quest", -2.0, 0.0)
	var d := def(id)
	if not d.is_empty():
		Story.toast("퀘스트 — %s" % String(d.get("title", id)), 2.4)


static func set_step(id: String, n: int) -> void:
	if state(id) == 0:
		start(id)
	if state(id) != 1:
		return
	GameState.set_flag("q_" + id + "_step", n)
	GameState.set_flag("q_last", id)
	var steps: Array = def(id).get("steps", [])
	if n < steps.size():
		Story.toast("▶ " + String(steps[n]), 2.2)


## 완료 + 보상 지급. 보상 문구 목록을 돌려준다(알림 창이 씀)
static func complete(id: String) -> Array:
	if state(id) == 2:
		return []
	GameState.set_flag("q_" + id, 2)
	var out := Rewards.grant(def(id).get("reward", {}))
	GameState.add("quests_done")
	return out


## 이 인물이 줄 수 있는(받지 않았고 need가 선) 퀘스트 ID, 없으면 ""
static func available_for(who: String) -> String:
	for id in all():
		var d: Dictionary = all()[id]
		if String(d.get("giver", "")) != who or state(id) != 0 or String(d.get("kind", "side")) == "class":
			continue
		var need := String(d.get("need", ""))
		if not Cond.ok(need):
			continue
		return id
	return ""


## 이 인물에게 진행 중인 퀘스트가 있는가
static func active_for(who: String) -> bool:
	for id in all():
		var d: Dictionary = all()[id]
		if String(d.get("giver", "")) == who and state(id) == 1:
			return true
	return false


## 목록 (kind가 ""이면 전부): [[id, 정의], ...] — 진행 중 먼저, 장 순서대로
static func listed(want_state: int, kind := "") -> Array:
	var out: Array = []
	for id in all():
		var d: Dictionary = all()[id]
		if kind != "" and String(d.get("kind", "side")) != kind:
			continue
		if state(id) == want_state:
			out.append([id, d])
	return out


## HUD 한 줄: 가장 최근에 움직인 서브 퀘스트의 지금 단계
static func tracker_line() -> String:
	var id := String(GameState.flag("q_last", ""))
	if id == "" or state(id) != 1:
		return ""
	var d := def(id)
	var steps: Array = d.get("steps", [])
	var n := step(id)
	var line := String(d.get("title", id))
	if n < steps.size():
		line += " — " + String(steps[n])
	return line


## 진행 중 퀘스트 중 지금 단계에서 이 인물(who)에게 말을 걸면 실행할 대본 ID ("" = 없음)
static func talk_hook(who: String) -> String:
	for id in all():
		if state(id) != 1:
			continue
		var d: Dictionary = all()[id]
		for h in d.get("talk", []):
			var hh: Array = h
			if hh.size() >= 3 and int(hh[0]) == step(id) and String(hh[1]) == who:
				return String(hh[2])
	return ""


# ─── 마법 수업 (kind = "class") — 수업 게시판 창(ClassBoardUI)·게시판 "!"(class_board)이 부른다 ───

## 마법 ID → 그 마법의 수업 퀘스트 ID ("" = 수업 없음, 1장 기본)
static func class_of(spell: String) -> String:
	for id in all():
		var d: Dictionary = all()[id]
		if String(d.get("kind", "")) == "class" and String(d.get("spell", "")) == spell:
			return id
	return ""


## 수업 상태: 0 습득 · 1 진행 중 · 2 신청 가능 · 3 잠김
static func class_status(spell: String) -> int:
	var q := class_of(spell)
	# 수업 중엔 임시로 쓸 수 있어서(temp_) learned가 참 — 진행 중을 먼저 본다
	if q != "" and state(q) == 1:
		return 1
	if Spells.learned(spell):
		return 0
	if q == "":
		return 3
	if Cond.ok(String(def(q).get("unlock", ""))):
		return 2
	return 3


## 새로 신청할 수 있는 수업이 있는가 (게시판 "!")
static func has_new_class() -> bool:
	for sp in Spells.ORDER:
		if class_status(sp) == 2:
			return true
	return false


## 진행 중인 수업의 마법 ID ("" = 없음)
static func active_class() -> String:
	for sp in Spells.ORDER:
		if class_status(sp) == 1:
			return sp
	return ""
