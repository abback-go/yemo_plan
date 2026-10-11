@tool
class_name Goal
extends Area2D
## 출구. 세라가 닿으면 결과 화면으로 넘어간다. 원점은 땅 위.

var _t := 0.0
var _used := false


func _ready() -> void:
	collision_layer = GameConst.L_TRIGGER
	collision_mask = GameConst.L_PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 44)
	shape.shape = rect
	shape.position = Vector2(0, -22)
	add_child(shape)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _used or not body is Player or not body.is_alive():
		return
	_used = true
	var p := body as Player
	p.controls_enabled = false
	GameState.running = false
	Sfx.play(&"clear")
	Fx.flash(Color(1, 0.9, 0.7, 0.6), 0.6)
	Fx.burst(global_position + Vector2(0, -22), 40, {
		spread = 180.0, speed_min = 30.0, speed_max = 140.0, lifetime = 0.8, gravity = Vector2(0, -40),
	})
	get_tree().create_timer(1.3, true, false, true).timeout.connect(GameState.finish_run)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# 세로로 긴 불꽃 고리 문
	var c := Vector2(0, -22)
	for i in 3:
		var r := 1.0 - i * 0.22
		var pts := PackedVector2Array()
		for j in 25:
			var a := TAU * j / 24.0
			var wob := sin(a * 3.0 + _t * (4.0 + i)) * 1.5
			pts.append(c + Vector2(cos(a) * (10.0 * r + wob * 0.3), sin(a) * (20.0 * r + wob)))
		draw_polyline(pts, [Palette.FIRE_OUT, Palette.FIRE_HOT, Palette.FIRE_CORE][i], 1.0 + (2 - i) * 0.5)
	draw_circle(c, 6.0 + sin(_t * 3.0), Color(Palette.FIRE_HOT, 0.2))
	for i in 5:
		var ph := fmod(_t * 0.8 + i * 0.2, 1.0)
		draw_rect(Rect2(c + Vector2(sin(i * 2.7 + _t) * 7.0, 18.0 - ph * 40.0), Vector2(1, 1)), Color(Palette.FIRE_CORE, 1.0 - ph))
