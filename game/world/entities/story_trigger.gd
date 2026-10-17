class_name StoryTrigger
extends Area2D
## 영역에 들어가면 컷신·멈춤 안내를 실행. once(기본 true)면 한 번만 (플래그 trig_<방>_<id>).

var run := ""
var once := true
var flag_key := ""
var _armed := true


func setup(room: Room, e: Dictionary, eid: String) -> void:
	run = String(e.get("run", ""))
	once = bool(e.get("once", true))
	flag_key = "trig_%s_%s" % [room.data.id, eid]
	if once and GameState.has_flag(flag_key):
		_armed = false
	collision_layer = 0
	collision_mask = GameConst.L_PLAYER
	monitoring = true
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	var size := Vector2(float(e.get("w", 2)), float(e.get("h", 4))) * 16.0
	rs.size = size
	cs.shape = rs
	cs.position = room.tile_pos(e) + size * 0.5
	add_child(cs)
	body_entered.connect(_on_body)


func _on_body(b: Node) -> void:
	if not _armed or not b is Player:
		return
	if Story.busy():
		return
	if once:
		_armed = false
		GameState.set_flag(flag_key)
	Story.run(run)
