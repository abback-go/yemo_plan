@tool
class_name Door
extends StaticBody2D
## 아레나 봉인 문. 원점은 왼쪽 위. 열려 있으면 통과, 닫히면 붉은 마법 창살이 길을 막는다.

@export var size := Vector2(16, 96):
	set(v):
		size = v
		_rebuild()
@export var start_closed := false

var closed := false
var _k := 0.0 ## 닫힘 정도 0~1 (연출)
var _t := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	_rebuild()
	if start_closed:
		closed = true
		_k = 1.0
	_shape.disabled = not closed


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2.0
	queue_redraw()


func close() -> void:
	if closed:
		return
	closed = true
	_shape.set_deferred("disabled", false)
	Sfx.play(&"door")
	Fx.shake(0.15, 0.2)
	create_tween().tween_property(self, "_k", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func open() -> void:
	if not closed:
		return
	closed = false
	_shape.set_deferred("disabled", true)
	Sfx.play(&"door")
	create_tween().tween_property(self, "_k", 0.0, 0.4)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# 기둥 받침은 항상 보임
	draw_rect(Rect2(-2, size.y - 4, size.x + 4, 4), Palette.GROUND_TOP)
	draw_rect(Rect2(-2, 0, size.x + 4, 4), Palette.GROUND_TOP)
	if _k <= 0.01:
		return
	var h := size.y * _k
	var glow := 0.6 + 0.4 * sin(_t * 6.0)
	draw_rect(Rect2(0, 0, size.x, h), Color(Palette.DOOR, 0.55))
	var bars := maxi(int(size.x / 5.0), 2)
	for i in bars:
		var x := (i + 0.5) * size.x / bars
		draw_line(Vector2(x, 0), Vector2(x, h), Color(Palette.DOOR_GLOW, 0.5 + 0.5 * glow), 1.0)
	for j in int(h / 12.0):
		var y := 6.0 + j * 12.0 + fmod(_t * 20.0, 12.0)
		if y < h:
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(Palette.DOOR_GLOW, 0.25 * glow), 1.0)
	draw_rect(Rect2(0, h - 2, size.x, 2), Palette.DOOR_GLOW)
