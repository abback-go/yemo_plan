class_name FoxWindow
extends Node2D
## 여우창문 (docs/archive/sera/chapter1.md 4.9절): 세라 주위 반경 6타일 원 안이 6초 동안 "참모습"으로 보인다.
## 원 안의 환영 벽은 사라지고 숨은 발판은 생긴다(영구). 원 밖은 어둡게. 그림자 늑대는 원 안에서 잠행하지 못한다.

const RADIUS_T := 6.0
const DURATION := 6.0

var player: Player
var _t := 0.0


func setup(p: Player) -> void:
	player = p
	global_position = p.center()


func radius() -> float:
	return RADIUS_T * GameConst.TILE * clampf(_t / 0.3, 0.0, 1.0)


func _ready() -> void:
	add_to_group(&"fox_window")
	z_index = 25


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(player):
		global_position = player.center()
	var r := radius()
	for n in get_tree().get_nodes_in_group(&"illusion"):
		n.try_reveal(global_position, r)
	for n in get_tree().get_nodes_in_group(&"hint_mural"):
		n.try_reveal(global_position, r)
	if _t >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var r := radius()
	var fade := clampf((DURATION - _t) / 0.5, 0.0, 1.0)
	# 원 밖을 어둡게 (두꺼운 고리)
	draw_arc(Vector2.ZERO, r + 340.0, 0, TAU, 48, Color(0.01, 0.02, 0.06, 0.45 * fade), 680.0)
	# 창틀: 여우 손가락 모양의 마름모 테두리 + 푸른 빛
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.6, 0.85, 1.0, 0.8 * fade), 2.0)
	draw_arc(Vector2.ZERO, r - 4.0, 0, TAU, 48, Color(0.6, 0.85, 1.0, 0.25 * fade), 1.0)
	for i in 4:
		var a := _t * 0.4 + TAU * i / 4.0
		var p := Vector2(cos(a), sin(a)) * r
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(0, -6), p + Vector2(4, 0), p + Vector2(0, 6)]), Color(0.85, 0.95, 1.0, 0.8 * fade))
	# 남은 시간 표시 (위쪽 호)
	draw_arc(Vector2.ZERO, r + 6.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - _t / DURATION), 32, Color(0.6, 0.85, 1.0, 0.5 * fade), 1.0)
