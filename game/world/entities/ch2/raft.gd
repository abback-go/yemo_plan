extends AnimatableBody2D
## 물에 뜬 나무 뗏목 (통과 발판처럼 위에서만 밟힘). 같은 방의 k_water 수면을 따라 오르내리고, 물이 빠지면 바닥에 내려앉는다.
## {t = "k_raft", x, y, w = 3, rest_y}  (y = 높은 수면 행, rest_y = 물이 빠졌을 때 앉는 행 — 비우면 물 바닥)

var w_px := 48.0
var rest_px := INF
var _water: Node2D
var _t := 0.0
var _phase := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	var T := GameConst.TILE
	w_px = float(e.get("w", 3)) * T
	position = Vector2(float(e.get("x", 0)) * T, float(e.get("y", 0)) * T)
	if e.has("rest_y"):
		rest_px = float(e.get("rest_y")) * T
	collision_layer = GameConst.L_PLATFORM
	collision_mask = 0
	sync_to_physics = false
	z_index = 4
	_phase = position.x * 0.03
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w_px, 6)
	cs.shape = rs
	cs.one_way_collision = true
	cs.position = Vector2(w_px * 0.5, 3)
	add_child(cs)


func _ready() -> void:
	for n in get_tree().get_nodes_in_group(&"k_water"):
		_water = n as Node2D
	if _water:
		position.y = _surface_y()


func _surface_y() -> float:
	var s: float = _water.get("surface")
	if rest_px != INF:
		s = minf(s, rest_px)
	return s - 2.0


func _physics_process(delta: float) -> void:
	_t += delta
	if _water == null:
		return
	var bob := sin(_t * 2.0 + _phase) * 1.0
	position.y = _surface_y() + bob


func _draw() -> void:
	var wood := Color("#6a4a30")
	draw_rect(Rect2(0, 0, w_px, 5), wood)
	draw_rect(Rect2(0, 0, w_px, 1), wood.lightened(0.3))
	var x := 0.0
	while x < w_px - 1:
		draw_rect(Rect2(x, 0, 1, 5), wood.darkened(0.35))
		x += 6.0
	draw_rect(Rect2(2, 5, w_px - 4, 2), Color("#3a2a1a"))
	draw_rect(Rect2(w_px * 0.5 - 4, 2, 8, 1), Color("#a8906a"))


func _process(_d: float) -> void:
	queue_redraw()
