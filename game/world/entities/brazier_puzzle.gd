class_name BrazierPuzzle
extends Node
## 퍼즐 처리기 (entity "puzzle"). mode:
##   all      같은 group의 봉화가 모두 켜지면 done_flag
##   order    order 번호 순서대로 켜야 함. 틀리면 그룹 전체가 꺼짐
##   targets  같은 group의 과녁이 동시에 모두 켜지고, max_overload(기본 70) 미만이면 done_flag

var group := ""
var mode := "all"
var done_flag := ""
var max_overload := 70.0
var _next := 1
var _done := false
var _warn_t := 0.0


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	group = String(e.get("group", ""))
	mode = String(e.get("mode", "all"))
	done_flag = String(e.get("done_flag", ""))
	max_overload = float(e.get("max_overload", 70.0))
	_done = done_flag != "" and GameState.has_flag(done_flag)


func _ready() -> void:
	await get_tree().process_frame
	for b in _braziers():
		b.lit_changed.connect(_on_lit)
		if _done:
			b.set_lit(true, true)


func _braziers() -> Array:
	var out := []
	for b in get_tree().get_nodes_in_group(&"brazier"):
		if b.group == group:
			out.append(b)
	return out


func _on_lit(b: Brazier) -> void:
	if _done or not b.lit:
		return
	if mode == "order":
		if b.order != _next:
			Sfx.play(&"block", 0.0, 0.0)
			var bs := _braziers()
			for x in bs:
				x.flash_fail()
			await get_tree().create_timer(0.5, false).timeout
			for x in bs:
				x.set_lit(false, true)
			_next = 1
			Story.toast("불꽃이 꺼졌다… 순서가 틀린 것 같다.")
			return
		_next += 1
	for x in _braziers():
		if not x.lit:
			return
	_solve()


func _solve() -> void:
	_done = true
	if done_flag != "":
		GameState.set_flag(done_flag)
	Sfx.play(&"clear", 0.0, 0.0)
	Fx.flash(Color(1.0, 0.85, 0.6, 0.25), 0.4)


func _physics_process(delta: float) -> void:
	if _done or mode != "targets":
		return
	_warn_t -= delta
	var all_lit := true
	var any := false
	for t in get_tree().get_nodes_in_group(&"practice_target"):
		if t.group != group:
			continue
		any = true
		if not t.is_lit():
			all_lit = false
	if not any or not all_lit:
		return
	var w := World.get_world()
	if w and w.player.overload >= max_overload:
		if _warn_t <= 0.0:
			_warn_t = 2.0
			Story.toast("과녁은 맞혔지만 폭주 게이지가 70을 넘었다. 다시!")
			for t in get_tree().get_nodes_in_group(&"practice_target"):
				if t.group == group:
					t.lit_t = 0.0
		return
	_solve()
