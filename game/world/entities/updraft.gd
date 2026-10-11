class_name Updraft
extends Node2D
## 상승 기류 (docs/archive/sera/systems2.md 6절): 굴뚝 열기·대장간·엘프 바람길·별빛 기둥.
## 불꽃 날개로 **활공 중**인 세라가 이 안에 들어오면 위로 솟아오른다(꼭대기 근처에선 그 높이에 머묾).
## 방 데이터: {t = "updraft", x, y, w, h, style = "heat"|"wind"|"star", power = 1.0, on_if = "플래그,!플래그"}
## on_if 조건이 거짓이면 꺼짐(바람 밸브 퍼즐 등). x·y는 왼쪽 위 칸, w·h는 칸 수.

var rect := Rect2()
var style := "heat"
var power := 1.0
var on_if := ""
var _t := 0.0
var _on := true
var _cond_dirty := true ## on_if를 다시 볼 차례 (처음 + GameState.flag_changed마다) — 매 프레임 문자열을 나누지 않게
var _streaks: Array = []
var _player: Player


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	var T := GameConst.TILE
	var x := float(e.get("x", 0))
	var y := float(e.get("y", 0))
	var w := float(e.get("w", 2))
	var h := float(e.get("h", 8))
	rect = Rect2(x * T, y * T, w * T, h * T)
	style = String(e.get("style", "heat"))
	power = float(e.get("power", 1.0))
	on_if = String(e.get("on_if", ""))
	z_index = -2
	if style != "wind":
		material = Fx.add_material
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room.data.id) + int(x * 31 + y)
	for i in maxi(int(w * h / 3.0), 6):
		_streaks.append([rng.randf(), rng.randf(), rng.randf_range(0.6, 1.4)])
	if on_if != "":
		GameState.flag_changed.connect(_on_flag)


func _on_flag(_key: String) -> void:
	_cond_dirty = true


func is_on() -> bool:
	return _on


func _physics_process(delta: float) -> void:
	_t += delta
	# 조건은 예전처럼 물리 프레임 처음에 평가하되, 플래그가 바뀐 뒤에만 (빈 조건은 언제나 참)
	if _cond_dirty:
		_cond_dirty = false
		_on = RoomData.cond_ok(on_if)
	if _on:
		if not is_instance_valid(_player):
			_player = get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if _player:
			var c := _player.global_position + Vector2(0, -12)
			if rect.grow_individual(4, 24, 4, 0).has_point(c):
				_player.apply_updraft(power, rect.position.y)
	# 빛줄기는 화면(+여유) 근처일 때만 다시 그림 (시간 _t는 계속 흐름)
	if Prop.near_view(self, Rect2(global_position + rect.position, rect.size).grow(32.0)):
		queue_redraw()


func _col() -> Color:
	match style:
		"wind": return Color(0.75, 1.0, 0.85)
		"star": return Color(1.0, 0.95, 0.7)
	return Color(1.0, 0.6, 0.3)


func _draw() -> void:
	var col := _col()
	var a := 1.0 if _on else 0.15
	# 바닥에서 피어오르는 빛 띠
	draw_rect(Rect2(rect.position.x, rect.end.y - 6, rect.size.x, 6), Color(col, 0.18 * a))
	for s in _streaks:
		var fx: float = s[0]
		var phase: float = s[1]
		var spd: float = s[2]
		var k := fmod(phase + _t * 0.6 * spd * (1.0 if _on else 0.2), 1.0)
		var x := rect.position.x + fx * rect.size.x + sin(_t * 2.0 + phase * 9.0) * 3.0
		var y := rect.end.y - k * rect.size.y
		var ln := 10.0 + 8.0 * spd
		var fade := sin(k * PI)
		match style:
			"wind":
				draw_line(Vector2(x, y), Vector2(x + sin(_t * 3.0 + phase * 7.0) * 3.0, y - ln), Color(col, 0.35 * fade * a), 1.0)
			"star":
				draw_rect(Rect2(x, y, 2, 2), Color(col, 0.8 * fade * a))
			_:
				draw_line(Vector2(x, y), Vector2(x + sin(_t * 6.0 + phase * 5.0) * 2.0, y - ln * 0.7), Color(col, 0.45 * fade * a), 2.0)
