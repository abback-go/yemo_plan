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
	var out: Array = []
	var r: Dictionary = def(id).get("reward", {})
	var n_st := int(r.get("stones", 0))
	if n_st > 0:
		Spells.add_stones(n_st)
		out.append("마도석 %d개" % n_st)
	var n_pot := int(r.get("potion_slot", 0))
	if n_pot > 0:
		GameState.potions_max += n_pot
		GameState.potions = GameState.potions_max
		out.append("물약 최대 +%d" % n_pot)
	var n_heart := int(r.get("heart", 0)) + int(r.get("feather", 0))
	if n_heart > 0:
		GameState.max_hp += n_heart
		GameState.hp = GameState.max_hp
		var w := World.get_world()
		if w:
			w.player.restore_from_state()
		out.append("최대 체력 +%d" % n_heart)
	var txt := String(r.get("text", ""))
	if txt != "":
		out.append(txt)
	GameState.add("quests_done")
	return out


## 이 인물이 줄 수 있는(받지 않았고 need가 선) 퀘스트 ID, 없으면 ""
static func available_for(who: String) -> String:
	for id in all():
		var d: Dictionary = all()[id]
		if String(d.get("giver", "")) != who or state(id) != 0 or String(d.get("kind", "side")) == "class":
			continue
		var need := String(d.get("need", ""))
		if need != "" and not RoomData.cond_ok(need):
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
