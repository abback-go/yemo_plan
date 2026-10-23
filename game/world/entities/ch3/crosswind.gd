class_name Crosswind
extends Node2D
## 옆바람 (엘프 바람길 — 바람 밸브가 "옆"일 때). 영역 안에서 공중에 뜬 세라를 dir 쪽으로 민다(활공 중이면 더 세게).
## 바람에 실려 넓은 틈을 건너거나, 거꾸로 부는 바람을 피해 밸브를 돌린다. 연한 바람 띠가 흐른다.
## 방 데이터: {t = "crosswind", x, y, w, h, dir = 1, power = 1.0, on_if = ""}

const WIND := Color(0.82, 1.0, 0.85)
const PUSH := 180.0 ## px/s (활공 중 ×1.6)

var rect := Rect2()
var dir := 1.0
var power := 1.0
var on_if := ""
var _on := true
var _t := 0.0
var _streaks: Array = []


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	var T := GameConst.TILE
	rect = Rect2(float(e.get("x", 0)) * T, float(e.get("y", 0)) * T, float(e.get("w", 8)) * T, float(e.get("h", 4)) * T)
	dir = 1.0 if float(e.get("dir", 1)) >= 0.0 else -1.0
	power = float(e.get("power", 1.0))
	on_if = String(e.get("on_if", ""))
	z_index = -2
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room.data.id) + int(rect.position.x)
	for i in maxi(int(rect.size.x * rect.size.y / 900.0), 6):
		_streaks.append([rng.randf(), rng.randf(), rng.randf_range(0.6, 1.4)])


func is_on() -> bool:
	return _on


func _physics_process(delta: float) -> void:
	_t += delta
	_on = RoomData.cond_ok(on_if)
	if _on:
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p and p.is_alive() and not p.is_on_floor() and rect.has_point(p.center()):
			var k := PUSH * power * (1.6 if p.is_gliding() else 1.0)
			p.move_and_collide(Vector2(dir * k * delta, 0))
	queue_redraw()


func _draw() -> void:
	var a := 1.0 if _on else 0.12
	for s in _streaks:
		var fy: float = s[0]
		var ph: float = s[1]
		var spd: float = s[2]
		var k := fmod(ph + _t * 0.5 * spd * (1.0 if _on else 0.15), 1.0)
		var x := rect.position.x + (k if dir > 0.0 else 1.0 - k) * rect.size.x
		var y := rect.position.y + fy * rect.size.y + sin(_t * 2.0 + ph * 9.0) * 3.0
		var ln := 12.0 + 10.0 * spd
		var fade := sin(k * PI)
		draw_line(Vector2(x, y), Vector2(x - dir * ln, y + sin(_t * 3.0 + ph) * 1.5), Color(WIND, 0.35 * fade * a), 1.0)
	# 가장자리에 옅은 띠
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1), Color(WIND, 0.06 * a))
	draw_rect(Rect2(rect.position.x, rect.end.y - 1, rect.size.x, 1), Color(WIND, 0.06 * a))
