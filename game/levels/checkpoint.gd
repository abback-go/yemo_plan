@tool
class_name Checkpoint
extends Area2D
## 체크포인트 등불 (docs/archive/sera/prototype.md 5.7절). 닿으면 불이 켜지고 체력을 모두 회복한다.
## 사망하면 마지막으로 켠 체크포인트에서 다시 시작한다. 원점은 땅 위.

@export var index := 0 ## 0 = 시작 지점, 구간 번호와 같게 둔다

var _t := 0.0
var _lit_flash := 0.0


func _ready() -> void:
	add_to_group(&"checkpoint")
	collision_layer = GameConst.L_TRIGGER
	collision_mask = GameConst.L_PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func is_lit() -> bool:
	if Engine.is_editor_hint():
		return true
	return GameState.checkpoint_index >= index


func _on_body_entered(body: Node) -> void:
	if not body is Player:
		return
	var player := body as Player
	if not player.is_alive():
		return
	player.heal_full()
	if GameState.checkpoint_index < index:
		GameState.checkpoint_index = index
		_lit_flash = 1.0
		Sfx.play(&"checkpoint")
		Fx.burst(global_position + Vector2(0, -34), 20, {
			spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.6, gravity = Vector2(0, -30),
		})
		Fx.ring(global_position + Vector2(0, -34), 4.0, 26.0, Palette.FIRE_HOT, 0.4, 2.0)
		var hud := get_tree().get_first_node_in_group(&"hud")
		if hud:
			hud.banner("체크포인트 — 체력 회복", 1.4)


func _process(delta: float) -> void:
	_t += delta
	_lit_flash = maxf(_lit_flash - delta * 2.0, 0.0)
	queue_redraw()


func _draw() -> void:
	var lit := is_lit()
	# 기둥과 걸이
	draw_rect(Rect2(-1, -40, 2, 40), Color("#4a3b52"))
	draw_rect(Rect2(-4, -1, 8, 1), Palette.GROUND_TOP)
	draw_line(Vector2(0, -40), Vector2(6, -40), Color("#4a3b52"), 1.0)
	var lamp := Vector2(6, -33)
	# 등불 몸체
	draw_rect(Rect2(lamp + Vector2(-3, -5), Vector2(6, 9)), Color("#2a2033"))
	draw_rect(Rect2(lamp + Vector2(-4, -6), Vector2(8, 1)), Color("#5b4a66"))
	draw_rect(Rect2(lamp + Vector2(-4, 4), Vector2(8, 1)), Color("#5b4a66"))
	if lit:
		var f := 0.8 + 0.2 * sin(_t * 9.0) + _lit_flash
		draw_circle(lamp, 10.0 + 2.0 * sin(_t * 3.0), Color(Palette.FIRE_OUT, 0.12 * f))
		draw_circle(lamp, 5.0, Color(Palette.FIRE_HOT, 0.25 * f))
		draw_rect(Rect2(lamp + Vector2(-2, -3), Vector2(4, 6)), Color(Palette.FIRE_MID, 0.9))
		draw_rect(Rect2(lamp + Vector2(-1, -2), Vector2(2, 4)), Palette.FIRE_CORE)
	else:
		draw_rect(Rect2(lamp + Vector2(-2, -3), Vector2(4, 6)), Color("#1a1422"))
