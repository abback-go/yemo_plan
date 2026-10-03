extends Node
## 플래그가 서면 대본 실행 (entity "event"): {flag, run, done}
## done(기본 evt_<방>_<id>)이 서 있으면 다시 실행하지 않는다. 다른 대본이 도는 중이면 끝날 때까지 기다린다.

var flag := ""
var run := ""
var done := ""


func setup(room: Room, e: Dictionary, eid: String) -> void:
	flag = String(e.get("flag", ""))
	run = String(e.get("run", ""))
	done = String(e.get("done", "evt_%s_%s" % [room.data.id, eid]))


func _physics_process(_delta: float) -> void:
	if flag == "" or GameState.has_flag(done) or not GameState.has_flag(flag):
		return
	if Story.busy():
		return
	var w := World.get_world()
	if w == null or w.transitioning or not w.player.is_alive():
		return
	GameState.set_flag(done)
	Story.run(run)
