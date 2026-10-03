extends StaticBody2D
## 첨탑 비계 발판 (docs/chapter4.md 7.6절): 통과 발판처럼 위에서만 밟히는 나무·금 비계. 아우렐리아의 **신성 돌진**이 지나가면 부서져 떨어진다.
## 방 데이터: {t:"spire_plank", x, y(발판 행), w(칸), id}. 방을 다시 들어오면 다시 생긴다(추격을 다시 할 때).

const H := preload("res://enemies/ch4/holy.gd")

var w_px := 64.0
var broken := false
var _cs: CollisionShape2D
var _t := 0.0
var _shake := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e)
	w_px = float(e.get("w", 4)) * 16.0
	collision_layer = GameConst.L_PLATFORM
	collision_mask = 0
	z_index = -1


func _ready() -> void:
	add_to_group(&"spire_plank")
	_cs = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w_px, 6)
	_cs.shape = rs
	_cs.one_way_collision = true
	_cs.position = Vector2(w_px * 0.5, 3)
	add_child(_cs)


## 이 높이 띠(전역 y0~y1)와 겹치는가
func in_band(y0: float, y1: float) -> bool:
	var y := global_position.y + 3.0
	return y >= y0 - 4.0 and y <= y1 + 4.0


func tremble() -> void:
	_shake = 0.6


func shatter() -> void:
	if broken:
		return
	broken = true
	_cs.set_deferred("disabled", true)
	Sfx.play(&"crumble", -2.0, 0.1)
	for i in int(w_px / 12.0) + 1:
		var p := global_position + Vector2(6.0 + i * 12.0, 2)
		Fx.burst(p, 4, {
			direction = Vector2(randf_range(-0.3, 0.3), 1), spread = 40.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.9,
			gradient = Palette.fade_gradient(Color("#8a6440")), size_min = 2.0, size_max = 4.0, gravity = Vector2(0, 600),
		})
	H.sparkle(global_position + Vector2(w_px * 0.5, 0), 10, w_px * 0.3, 0.0, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(_shake - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if broken and modulate.a <= 0.01:
		return
	var o := Vector2(sin(_t * 60.0) * 1.5 * _shake, 0)
	var wood := Color("#6a4c30")
	var lit := Color("#e8c070")
	# 받침 버팀대
	for x: float in [6.0, w_px - 8.0]:
		draw_line(Vector2(x, 5) + o, Vector2(x + (6.0 if x < w_px * 0.5 else -6.0), 16) + o, Color("#3a281c"), 2.0)
	draw_rect(Rect2(Vector2(0, 0) + o, Vector2(w_px, 5)), wood)
	draw_rect(Rect2(Vector2(0, 0) + o, Vector2(w_px, 1)), lit)
	draw_rect(Rect2(Vector2(0, 5) + o, Vector2(w_px, 1)), Color("#2a1c12"))
	var x2 := 8.0
	while x2 < w_px - 2.0:
		draw_rect(Rect2(Vector2(x2, 1) + o, Vector2(1, 4)), Color("#4a3420"))
		x2 += 10.0
	# 금빛 못
	draw_rect(Rect2(Vector2(2, 2) + o, Vector2(2, 2)), lit)
	draw_rect(Rect2(Vector2(w_px - 4, 2) + o, Vector2(2, 2)), lit)
	if _shake > 0.0:
		draw_rect(Rect2(Vector2(0, -1) + o, Vector2(w_px, 7)), Color(1.0, 0.3, 0.25, 0.25 * _shake))
