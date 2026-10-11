extends Node2D
## 자세를 잡은 인물 (방 개체 "k_pose"). 대화는 없고 그림만 — 연무장에서 검을 휘두르는 기사, 무릎 꿇은 레오니,
## 개발 방의 자세 견본 등. 컷신에서 Cut.actor(id)로 받아 set_pose·face를 부를 수 있다.
## 키: who(인물 ID), pose(자세 이름), face(left·right), loop(초: 0보다 크면 그 간격으로 자세를 처음부터 다시),
##     id(배우 ID — Cut.actor가 찾는 이름, 없으면 "pose_<who>"), label(개발 방에서 머리 위에 자세 이름 표시)

var who := "leonie"
var visual: CharacterVisual
var loop := 0.0
var zoom := 1.0 ## 개발 방 확대 견본용 (그림을 정수배로 키움)
var label := ""
var _id := ""
var _flip: Node2D
var _pose := "idle"
var _lt := 0.0
var _font: Font


func setup(room: Room, e: Dictionary, eid: String) -> void:
	who = String(e.get("who", "leonie"))
	_pose = String(e.get("pose", "idle"))
	loop = float(e.get("loop", 0.0))
	label = String(e.get("label", ""))
	zoom = float(e.get("zoom", 1.0))
	_id = String(e.get("actor", "pose_" + who if eid.begins_with("k_pose_") else eid))
	position = room.tile_pos(e) + Vector2(8, 0)
	z_index = 1
	_flip = Node2D.new()
	add_child(_flip)
	visual = CharacterVisual.new()
	visual.setup(who)
	visual.set_pose(_pose)
	visual.walking = bool(e.get("walk", false))
	if bool(e.get("wood", false)):
		var inf: Dictionary = visual.info.duplicate()
		inf["sword"] = "wood"
		visual.info = inf
	_flip.add_child(visual)
	face(-1 if String(e.get("face", "right")) == "left" else 1)
	_font = ThemeDB.fallback_font


func actor_id() -> String:
	return _id


func face(dir: int) -> void:
	if dir != 0:
		_flip.scale = Vector2(dir, 1) * zoom


func set_pose(p: String) -> void:
	_pose = p
	visual.set_pose(p)


func set_talking(on: bool) -> void:
	visual.talking = on


func _process(delta: float) -> void:
	if loop > 0.0:
		_lt += delta
		if _lt >= loop:
			_lt = 0.0
			visual.pose = ""
			visual.set_pose(_pose)
	if label != "":
		queue_redraw()


func _draw() -> void:
	if label == "":
		return
	draw_string(_font, Vector2(-20, -18 - 40 * zoom), label, HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color(1, 0.9, 0.7, 0.9))
