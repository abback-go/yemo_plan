extends Node2D
## 불사조의 알 (불사조 수업 3단계): 둘레의 불(flame)이 적에게 닿을 때마다 줄어든다. 0이 되면 실패(대본이 다시).
## 세라가 가까이 서 있으면 조금씩 다시 찬다. {t = "phoenix_egg", x, y}

var flame := 100.0
var progress := -1.0 ## 대본이 0~1로 채움: 부화까지 (알 위에 금빛 고리)
var _t := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 0)
	add_to_group(&"phoenix_egg")
	material = Fx.add_material
	z_index = 1


func _physics_process(delta: float) -> void:
	_t += delta
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en and en.is_alive() and EnemyBase.dist_to_body(en, global_position + Vector2(0, -14)) < 18.0:
			flame = maxf(flame - 14.0 * delta, 0.0)
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	if p and p.global_position.distance_to(global_position) < 40.0:
		flame = minf(flame + 3.0 * delta, 100.0)
	queue_redraw()


func _draw() -> void:
	var k := flame / 100.0
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	draw_circle(Vector2(0, -14), 22.0 + pulse * 3.0, Color(Palette.FIRE_OUT, 0.12 + 0.12 * k))
	# 알
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 9.0, sin(a) * 12.0 - 14.0 + (2.0 if sin(a) > 0.0 else 0.0)))
	draw_colored_polygon(pts, Color("#e8c890").lerp(Palette.FIRE_HOT, 0.3 * pulse))
	draw_line(Vector2(-3, -20), Vector2(2, -12), Color("#b8783a"), 1.0)
	# 둘레 불꽃 (남은 불만큼)
	var n := int(12 * k)
	for i in n:
		var a2 := TAU * i / 12.0 + _t * 1.5
		var p0 := Vector2(cos(a2) * 15.0, sin(a2) * 18.0 - 14.0)
		draw_colored_polygon(PackedVector2Array([p0 + Vector2(-2, 0), p0 + Vector2(0, -6 - pulse * 2.0), p0 + Vector2(2, 0)]), Palette.FIRE_OUT)
	draw_rect(Rect2(-16, 4, 32, 3), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(-16, 4, 32 * k, 3), Palette.FIRE_HOT)
	if progress >= 0.0:
		draw_arc(Vector2(0, -14), 26.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(progress, 0.0, 1.0), 40, Color(Palette.GOLD, 0.85), 2.0)
		draw_arc(Vector2(0, -14), 26.0, 0.0, TAU, 40, Color(Palette.GOLD, 0.15), 1.0)
	if flame < 35.0:
		draw_circle(Vector2(0, -14), 14.0, Color(1.0, 0.2, 0.2, 0.25 + 0.25 * sin(_t * 10.0)))
