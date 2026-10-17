extends Node2D
## 마력탄 발사대 (불꽃 방벽 수업): 일정한 간격으로 느린 보라 마력탄을 세라에게 쏜다. 방벽으로 되쏘면 과녁을 맞힐 수 있다.
## {t = "orb_turret", x, y, period = 2.4, phase = 0.0, on_if = "플래그 식"} — on_if가 거짓이면 쉬며 희미해짐

var period := 2.4
var on_if := ""
var _t := 0.0
var _warn := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, -8)
	period = float(e.get("period", 2.4))
	_t = -float(e.get("phase", 0.0))
	on_if = String(e.get("on_if", ""))
	z_index = 1


func _physics_process(delta: float) -> void:
	var on := on_if == "" or RoomData.cond_ok(on_if)
	modulate.a = 1.0 if on else 0.35
	if Story.busy() or not on:
		_warn = 0.0
		queue_redraw()
		return
	_t += delta
	_warn = clampf((_t - (period - 0.6)) / 0.6, 0.0, 1.0)
	if _t >= period:
		_t = 0.0
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p and p.global_position.distance_to(global_position) < 22.0 * GameConst.TILE:
			var pr := EnemyProjectile.new()
			pr.setup(global_position, p.center() - global_position, 130.0, "dark", {"radius": 5.0, "life": 6.0})
			Fx.effect_parent().add_child(pr)
			Sfx.play(&"shoot", -8.0, 0.1)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-7, -2, 14, 10), Color("#2a2238"))
	draw_rect(Rect2(-7, -2, 14, 2), Color("#5a4a7a"))
	draw_circle(Vector2(0, -4), 5.0, Color(0.55, 0.3, 0.9, 0.5 + 0.5 * _warn))
	draw_circle(Vector2(0, -4), 2.0, Color(0.95, 0.85, 1.0))
