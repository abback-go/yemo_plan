class_name CandleSwitch
extends Node2D
## 촛대 스위치 (docs/chapter1.md 12.6절 시간 문): 불로 켜면 flag를 time초 동안 세운다 → FlagGate가 열렸다 닫힌다.
## time이 0이면 한 번 켜면 계속.

var flag_key := ""
var time := 3.0
var _left := 0.0
var _hurt: Area2D
var _t := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	flag_key = String(e.get("flag", ""))
	time = float(e.get("time", 3.0))
	position = room.tile_pos(e) + Vector2(8, 0)
	add_to_group(&"pillar_target")
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 22)
	cs.shape = r
	cs.position = Vector2(0, -11)
	_hurt.add_child(cs)
	add_child(_hurt)
	if time <= 0.0 and GameState.has_flag(flag_key):
		_left = INF


func is_alive() -> bool:
	return _left <= 0.0


func is_on_floor() -> bool:
	return true


func take_hit(_hit: Hit) -> void:
	if _left > 0.0:
		return
	_left = time if time > 0.0 else INF
	GameState.set_flag(flag_key, true)
	Sfx.play(&"ignite", 0.0, 0.0)
	Sfx.play(&"door", -4.0, 0.0)


func _physics_process(delta: float) -> void:
	_t += delta
	if _left > 0.0 and _left != INF:
		_left -= delta
		if _left <= 0.0:
			GameState.set_flag(flag_key, false)
			Sfx.play(&"door", -6.0, 0.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-6, -2, 12, 2), Color("#8a6a3a"))
	draw_rect(Rect2(-2, -16, 4, 14), Color("#a8884a"))
	draw_rect(Rect2(-3, -20, 6, 4), Color("#efe4c8"))
	if _left > 0.0:
		var f := sin(_t * 10.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -20), Vector2(f, -30), Vector2(3, -20)]), Palette.FIRE_HOT)
		if _left != INF:
			draw_arc(Vector2(0, -24), 10, -PI * 0.5, -PI * 0.5 + TAU * (_left / time), 16, Color(Palette.FIRE_HOT, 0.8), 1.0)
	else:
		draw_rect(Rect2(-1, -22, 2, 2), Color("#3a2a20"))
		draw_arc(Vector2(0, -24), 9, 0, TAU, 12, Color(1.0, 0.6, 0.3, 0.25 + 0.2 * sin(_t * 3.0)), 1.0)
