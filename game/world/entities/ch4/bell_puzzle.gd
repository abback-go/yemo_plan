extends Node
## 종 퍼즐 처리기 (docs/archive/sera/chapter4.md 5절·7.5절): 같은 group의 진짜 종(temple_bell)을 정해진 순서로, 박자를 지켜 울리면 done_flag.
## 방 데이터: {t:"bell_puzzle", group, seq([종의 order 값 차례] — 비우면 order 오름차순), beat(다음 종까지 허용 초, 기본 4.5),
##            done_flag, hint(처음 틀렸을 때 한 번 띄우는 말), need(이 조건식이 설 때만 셈 — 퀘스트를 받은 뒤 등), id}
## - 맞힌 종은 금빛으로 남는다(set_mark). 틀린 종을 치거나 박자를 놓치면 불협화음과 함께 처음부터.
## - 다 맞히면 모든 종이 함께 한 번 더 울리고 done_flag. 이미 풀었으면 종들은 금빛으로 남아 있다.

const H := preload("res://enemies/ch4/holy.gd")

var group := ""
var seq: Array = []
var beat := 4.5
var done_flag := ""
var hint := ""
var need := ""
var _i := 0
var _left := 0.0
var _done := false
var _hinted := false


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	group = String(e.get("group", ""))
	seq = e.get("seq", [])
	beat = float(e.get("beat", 4.5))
	done_flag = String(e.get("done_flag", ""))
	hint = String(e.get("hint", ""))
	need = String(e.get("need", ""))
	_done =done_flag != "" and GameState.has_flag(done_flag)


func _ready() -> void:
	await get_tree().process_frame
	var bs := _bells()
	if seq.is_empty():
		var orders: Array = []
		for b in bs:
			orders.append(int(b.get("order")))
		orders.sort()
		seq = orders
	for b in bs:
		b.connect("rung", _on_rung)
		if _done:
			b.call("set_mark", true)


func _bells() -> Array:
	var out: Array = []
	for b in get_tree().get_nodes_in_group(&"temple_bell"):
		if String(b.get("group")) == group:
			out.append(b)
	return out


func _on_rung(b: Node) -> void:
	if _done or seq.is_empty() or (need != "" and not RoomData.cond_ok(need)):
		return
	var want := int(seq[_i])
	if int(b.get("order")) != want:
		_fail(true)
		return
	b.call("set_mark", true)
	_i += 1
	_left = beat
	if _i >= seq.size():
		_solve()


func _fail(wrong: bool) -> void:
	_i = 0
	_left = 0.0
	H.snd_pitch(&"bell_small", &"block", 0.55, -2.0)
	H.snd_pitch(&"bell_small", &"block", 0.62, -4.0)
	Fx.shake(0.08, 0.25)
	for x in _bells():
		x.call("set_mark", false)
	if not _hinted:
		_hinted = true
		var msg := hint if hint != "" else ("종소리가 어긋났다… 순서가 틀렸다." if wrong else "박자를 놓쳤다… 종소리가 흩어졌다.")
		Story.toast(msg, 3.0)
	else:
		Story.toast("종소리가 어긋났다." if wrong else "박자를 놓쳤다.", 1.6)


func _solve() -> void:
	_done = true
	if done_flag != "":
		GameState.set_flag(done_flag)
	var bs := _bells()
	for i in bs.size():
		var b: Node = bs[i]
		var tw := create_tween()
		tw.tween_interval(0.35 + i * 0.12)
		tw.tween_callback(func() -> void:
			if is_instance_valid(b):
				b.call("ring"))
	Sfx.play(&"clear", 0.0, 0.0)
	Fx.flash(Color(1.0, 0.9, 0.6, 0.25), 0.5)


func _physics_process(delta: float) -> void:
	if _done or _i == 0:
		return
	_left -= delta
	if _left <= 0.0:
		_fail(false)
