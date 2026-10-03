class_name QuestCounter
extends Node
## 퀘스트 모으기 세기 (docs/chapter3.md 11절): 방에 두면, flags 가운데 하나가 새로 설 때(씨앗을 줍거나 밸브를 고치면)
## "이름 n/총" 알림을 띄우고, 모두 서면 그 퀘스트(quest)가 진행 중일 때 다음 단계(step — 보통 "돌려주기")로 넘긴다.
## 퀘스트를 받기 전에 모은 것도 센다(받을 때 대본이 한꺼번에 확인).
## 방 데이터: {t = "quest_counter", quest, flags = [...], step = 1, label = "반짝이 씨앗"}

var quest := ""
var flags: Array = []
var step := 1
var label := ""


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	quest = String(e.get("quest", ""))
	flags = e.get("flags", [])
	step = int(e.get("step", 1))
	label = String(e.get("label", ""))
	GameState.flag_changed.connect(_on_flag)


static func count_of(keys: Array) -> int:
	var n := 0
	for k in keys:
		if GameState.has_flag(String(k)):
			n += 1
	return n


func _on_flag(k: String) -> void:
	if not flags.has(k) or not GameState.has_flag(k):
		return
	var n := count_of(flags)
	if label != "":
		Story.toast("%s %d/%d" % [label, n, flags.size()], 2.2)
	if n >= flags.size() and quest != "" and Quests.state(quest) == 1 and Quests.step(quest) < step:
		Quests.set_step(quest, step)
