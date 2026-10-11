extends Node
## 플래그가 서면 대본 실행 (entity "event"): {flag, run, done}
## done(기본 evt_<방>_<id>)이 서 있으면 다시 실행하지 않는다. 다른 대본이 도는 중이면 끝날 때까지 기다린다.

var flag := ""
var run := ""
var done := ""
## flag가 서 있고 done이 아직 없음 — GameState.flag_changed가 올 때만 다시 계산한다(매 물리 프레임 플래그 두 개를 찾지 않게).
## 기다리는 동안의 확인(대본 중·방 이동 중·쓰러짐)은 예전처럼 매 물리 프레임 한다.
var _armed := false


func setup(room: Room, e: Dictionary, eid: String) -> void:
	flag = String(e.get("flag", ""))
	run = String(e.get("run", ""))
	done = String(e.get("done", "evt_%s_%s" % [room.data.id, eid]))
	_rearm()
	GameState.flag_changed.connect(_on_flag)


func _on_flag(key: String) -> void:
	if key == flag or key == done:
		_rearm()


func _rearm() -> void:
	_armed = flag != "" and GameState.has_flag(flag) and not GameState.has_flag(done)


func _physics_process(_delta: float) -> void:
	if not _armed:
		return
	# 신호 없이 플래그 사전이 통째로 바뀌는 경우(이어하기 직전 등)를 위해 원래 조건을 그대로 한 번 더 본다
	if flag == "" or GameState.has_flag(done) or not GameState.has_flag(flag):
		return
	if Story.busy():
		return
	var w := World.get_world()
	if w == null or w.transitioning or not w.player.is_alive():
		return
	GameState.set_flag(done)
	Story.run(run)
