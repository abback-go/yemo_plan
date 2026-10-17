class_name RoomExit
extends Area2D
## 방 가장자리 출구. 세라가 닿으면 이어진 방의 짝 출구로 옮긴다.

var exit_id := ""
var to_room := ""
var to_id := ""
var side := "left"
var rect_t := Rect2i()
var room: Room


func setup(p_room: Room, e: Dictionary, eid: String) -> void:
	room = p_room
	exit_id = eid
	to_room = String(e.get("to", ""))
	to_id = String(e.get("to_id", ""))
	rect_t = Rect2i(int(e.get("x", 0)), int(e.get("y", 0)), int(e.get("w", 1)), int(e.get("h", 3)))
	var cols := room.data.cols()
	var rows := room.data.row_count()
	if rect_t.position.x <= 0:
		side = "left"
	elif rect_t.end.x >= cols:
		side = "right"
	elif rect_t.position.y <= 0:
		side = "top"
	else:
		side = "bottom"
	if e.has("side"):
		side = String(e.side)
	collision_layer = 0
	collision_mask = GameConst.L_PLAYER
	monitoring = true
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(rect_t.size) * 16.0
	cs.shape = rs
	cs.position = (Vector2(rect_t.position) + Vector2(rect_t.size) * 0.5) * 16.0
	add_child(cs)
	body_entered.connect(_on_body)


var _armed_t := 0.15 ## 방이 막 만들어졌을 때 직전 방의 위치로 잘못 닿는 것을 막음


func _physics_process(delta: float) -> void:
	if _armed_t > 0.0:
		_armed_t -= delta
		return
	# 진입 신호를 놓쳤어도(무장 전 겹침) 지금 겹쳐 있으면 나감
	for b in get_overlapping_bodies():
		_on_body(b)


func _on_body(b: Node) -> void:
	if _armed_t > 0.0:
		return
	if b is Player and to_room != "":
		var r := Rect2(Vector2(rect_t.position) * 16.0, Vector2(rect_t.size) * 16.0).grow(12.0)
		if not r.has_point((b as Player).global_position + Vector2(0, -8)):
			return
		var w := World.get_world()
		if w:
			w.request_exit(self)


## 이 출구로 들어올 때 세라가 설 곳
func arrival() -> Dictionary:
	var r := Rect2(Vector2(rect_t.position) * 16.0, Vector2(rect_t.size) * 16.0)
	match side:
		"left":
			return {"pos": Vector2(r.end.x + 24.0, r.end.y), "face": 1}
		"right":
			return {"pos": Vector2(r.position.x - 24.0, r.end.y), "face": -1}
		"top":
			return {"pos": Vector2(r.get_center().x, r.end.y + 24.0), "face": 1, "fall": true}
		_:
			return {"pos": Vector2(r.get_center().x, r.position.y - 8.0), "face": 1, "jump": true}
