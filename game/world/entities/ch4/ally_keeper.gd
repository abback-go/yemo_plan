extends Node
## 4장 동료 유지 (docs/archive/sera/chapter4.md 7.5절): 동료는 저장되지 않는다(docs/archive/sera/bible/progression.md 5절) — 기록에서 이어하거나 쓰러져 다시 서도
## 레오니가 곁에 있도록, 4장 방마다 하나씩 둔다(tools/rooms/ch4.py가 자동으로 넣음).
## 방 데이터: {t:"tp_ally", kind(기본 "leonie"), flag(기본 "tp_leonie_on")} — 플래그가 서 있는데 동료가 없으면 합류, 내려가 있는데 있으면 떠남.

var kind := "leonie"
var flag := "tp_leonie_on"


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	kind = String(e.get("kind", "leonie"))
	flag = String(e.get("flag", "tp_leonie_on"))


func _ready() -> void:
	# 방을 다 만들고 세라를 세운 뒤에
	call_deferred("_apply")


func _apply() -> void:
	var w := World.get_world()
	if w == null or Story.busy():
		return
	var want := GameState.has_flag(flag)
	var a := w.ally(kind)
	if want and a == null:
		w.ally_join(kind)
	elif not want and a != null:
		w.ally_leave(kind)
