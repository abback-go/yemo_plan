class_name AimLine
extends Node2D
## 화살 예고선 (1장 저격형 규칙과 같게): 따라오는 동안 가는 붉은 선(점점 진해짐) → 고정되면 흰 선이 깜빡임 → 발사.
## 전역 좌표 from에서 dir 방향으로 지형(L_WORLD)에 막힐 때까지 그린다. 막힌 곳엔 작은 표시.
## band > 0 이면 굵은 띠(바깥 신들의 빛창 — 흰색 허용, 대신 굵고 깜빡이게).
##   var l := AimLine.new(); Fx.effect_parent().add_child(l); l.aim(from, dir); l.k = 0.5 → l.lock() → l.queue_free()

var from := Vector2.ZERO
var dir := Vector2.RIGHT
var max_len := 640.0
var k := 0.0 ## 따라오는 동안 진하기 0~1
var locked := false
var band := 0.0 ## 띠 너비(px). 0이면 가는 선
var end := Vector2.ZERO
var blocked := false
var white := false ## 바깥 신들 계열: 흰 예고
var _t := 0.0


func _ready() -> void:
	z_index = 6
	top_level = true


func aim(p_from: Vector2, p_dir: Vector2) -> void:
	from = p_from
	dir = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.RIGHT
	_ray()


func lock() -> void:
	locked = true


func _ray() -> void:
	var to := from + dir * max_len
	end = to
	blocked = false
	if not is_inside_tree():
		return
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to, GameConst.L_WORLD)
	var r := space.intersect_ray(q)
	if r:
		end = r.position
		blocked = true


func _process(delta: float) -> void:
	_t += delta
	_ray()
	queue_redraw()


func _draw() -> void:
	var a := from
	var b := end
	if band > 0.0:
		var n := Vector2(-dir.y, dir.x) * band * 0.5
		var col := Color(1, 1, 1) if white else Palette.DANGER
		var blink := 0.55 + 0.45 * sin(_t * (30.0 if locked else 12.0))
		var al := (0.12 + 0.18 * k) * blink if not locked else 0.35 * blink
		draw_colored_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), Color(col, al))
		draw_line(a + n, b + n, Color(col, 0.6 * blink), 1.0)
		draw_line(a - n, b - n, Color(col, 0.6 * blink), 1.0)
		return
	if not locked:
		var c := Palette.DANGER if not white else Color(1, 1, 1)
		draw_line(a, b, Color(c, 0.2 + 0.45 * k), 1.0)
		# 끝에 작은 과녁 표시
		draw_arc(b, 3.0 + (1.0 - k) * 3.0, 0, TAU, 10, Color(c, 0.35 + 0.4 * k), 1.0)
	else:
		var on := int(_t * 30.0) % 2 == 0
		draw_line(a, b, Color(1, 1, 1, 0.95 if on else 0.5), 1.0 if on else 2.0)
		draw_circle(b, 2.0, Color(1, 1, 1, 0.85))
	if blocked:
		draw_rect(Rect2(b - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 1, 1, 0.5))
