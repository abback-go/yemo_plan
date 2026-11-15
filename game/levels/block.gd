@tool
class_name Block
extends StaticBody2D
## 지형 블록. 원점은 왼쪽 위, size만큼 차지한다. 에디터에서도 그림이 보인다(@tool).
## 인스펙터에서 size·style·one_way를 바꾸면 충돌 판정과 그림이 함께 바뀐다.

enum Style { GROUND, PLATFORM }

@export var size := Vector2(64, 16):
	set(v):
		size = v
		_rebuild()
@export var style: Style = Style.GROUND:
	set(v):
		style = v
		_rebuild()
## 아래에서는 통과하고 위에서만 밟히는 발판
@export var one_way := false:
	set(v):
		one_way = v
		_rebuild()

var _shape: CollisionShape2D


func _ready() -> void:
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape) # owner를 정하지 않으므로 씬 파일에는 저장되지 않음
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2.0
	_shape.one_way_collision = one_way
	collision_layer = GameConst.L_PLATFORM if one_way else GameConst.L_WORLD
	queue_redraw()


func _hash(i: int) -> float:
	var x := sin(float(i) * 12.9898 + position.x * 0.071 + position.y * 0.37) * 43758.5453
	return x - floorf(x)


func _draw() -> void:
	if style == Style.PLATFORM:
		_draw_platform()
	else:
		_draw_ground()


func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.GROUND)
	# 아래로 갈수록 어두운 띠
	var bands := int(size.y / 6.0)
	for i in bands:
		var y := 6.0 + i * 6.0
		draw_rect(Rect2(0, y, size.x, 6), Color(Palette.GROUND_DARK, clampf(0.15 + i * 0.12, 0.0, 0.85)))
	# 돌 틈 무늬
	var count := int(size.x * size.y / 260.0)
	for i in count:
		var p := Vector2(_hash(i) * size.x, 5.0 + _hash(i + 999) * maxf(size.y - 7.0, 1.0))
		var w := 3.0 + _hash(i + 77) * 6.0
		draw_line(p, p + Vector2(w, 0), Color(Palette.GROUND_DARK, 0.9), 1.0)
		if _hash(i + 5) > 0.6:
			draw_line(p + Vector2(w, 0), p + Vector2(w, 2), Color(Palette.GROUND_DARK, 0.9), 1.0)
	# 윗면과 이끼
	draw_rect(Rect2(0, 0, size.x, 2), Palette.GROUND_TOP)
	draw_rect(Rect2(0, 2, size.x, 1), Color(Palette.GROUND_TOP, 0.35))
	var tufts := int(size.x / 7.0)
	for i in tufts:
		var x := _hash(i + 300) * size.x
		var h := 1.0 + floorf(_hash(i + 400) * 3.0)
		draw_rect(Rect2(x, -h, 1, h), Color("#6f5d8f"))
	# 옆면 모서리
	draw_rect(Rect2(0, 0, 1, size.y), Color(Palette.GROUND_TOP, 0.25))
	draw_rect(Rect2(size.x - 1, 0, 1, size.y), Color(Palette.GROUND_DARK, 0.6))


func _draw_platform() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PLATFORM)
	draw_rect(Rect2(0, 0, size.x, 2), Palette.PLATFORM_TOP)
	draw_rect(Rect2(0, size.y - 1, size.x, 1), Color(0, 0, 0, 0.35))
	var x := 16.0
	while x < size.x - 2:
		draw_line(Vector2(x, 2), Vector2(x, size.y - 1), Color(0, 0, 0, 0.3), 1.0)
		x += 16.0
	# 받침대
	for bx in [3.0, size.x - 7.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx, size.y), Vector2(bx + 4, size.y), Vector2(bx + 2, size.y + 5),
		]), Palette.PLATFORM.darkened(0.3))
