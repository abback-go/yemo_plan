extends Node2D
## 날개 조각상 그림: 얼굴 없는 천사상, 등 뒤 큰 돌 날개 두 쌍, 앞 날개 끝이 칼날. 돌 결(회색 3단 명암).
## 움직일 때(stone < 1)는 갈라진 틈과 얼굴 자리에서 금빛이 새고, 굳으면 다시 잿빛 돌. 예고: 앞 날개 칼끝이 붉게.

const OUTL := Color("#16101f")
const STONE := Color("#8a8aa2")
const STONE_L := Color("#b8b8cc")
const STONE_S := Color("#5a5a72")
const GOLD := Color(1.0, 0.86, 0.45)
const DANGER := Color("#ff3b3b")

var enemy: SeraphStatue


func _process(_d: float) -> void:
	if enemy:
		scale.x = float(enemy.facing)


func _poly(pts: PackedVector2Array, col: Color, white: bool) -> void:
	for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var q := PackedVector2Array()
		for p in pts:
			q.append(p + o)
		draw_colored_polygon(q, OUTL if not white else Color(0.9, 0.9, 0.95))
	draw_colored_polygon(pts, Color.WHITE if white else col)


func _draw() -> void:
	if enemy == null:
		return
	var white := enemy.flash_amount() > 0.0
	var t := enemy._t
	var st := enemy.state
	var live := 1.0 - enemy.stone
	var k := enemy.progress()
	var jitter := Vector2(sin(t * 47.0), 0) * 0.6 * live if st == SeraphStatue.S.MOVE else Vector2.ZERO
	var o := jitter
	# 받침 그림자
	draw_rect(Rect2(-12, -2, 24, 2), Color(0, 0, 0, 0.25))
	# 뒤 날개 (부채꼴 깃털)
	var wing_lift := 0.0
	if st == SeraphStatue.S.WINDUP:
		wing_lift = k
	elif st == SeraphStatue.S.SLASH:
		wing_lift = -0.6
	for i in 5:
		var a := -PI * 0.5 - 0.35 - i * 0.24
		var ln := 22.0 - i * 2.5
		var root := Vector2(-3, -30) + o
		_poly(PackedVector2Array([root, root + Vector2(cos(a - 0.11), sin(a - 0.11)) * ln, root + Vector2(cos(a + 0.11), sin(a + 0.11)) * ln]), STONE_S if i % 2 == 0 else STONE, white)
	# 로브 몸
	var body := PackedVector2Array([Vector2(-6, -32) + o, Vector2(6, -32) + o, Vector2(10, -2), Vector2(-10, -2)])
	_poly(body, STONE, white)
	if not white:
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -32) + o, Vector2(-2, -32) + o, Vector2(-4, -2), Vector2(-10, -2)]), STONE_S)
		draw_line(Vector2(2, -30) + o, Vector2(4, -3), STONE_L, 1.0)
		for i in 3:
			draw_line(Vector2(-6 + i * 5, -14) + o, Vector2(-7 + i * 6, -3), STONE_S, 1.0)
	# 머리 (얼굴 없음) + 돌 광륜
	var hc := Vector2(1, -37) + o
	draw_arc(hc + Vector2(-1, -1), 8.0, 0, TAU, 20, Color(OUTL, 0.6), 3.0)
	draw_arc(hc + Vector2(-1, -1), 8.0, 0, TAU, 20, STONE_L if not white else Color.WHITE, 1.5)
	draw_circle(hc, 5.5, OUTL)
	draw_circle(hc, 4.5, STONE if not white else Color.WHITE)
	if not white:
		draw_circle(hc + Vector2(-1.5, -1.5), 2.0, STONE_L)
	# 앞 날개 = 칼날
	var wroot := Vector2(3, -28) + o
	var wtip := wroot + Vector2(16, -10).rotated(-wing_lift * 1.2)
	if st == SeraphStatue.S.SLASH or st == SeraphStatue.S.RECOVER:
		wtip = wroot + Vector2(22, 8)
	var wn := (wtip - wroot).normalized()
	var wp := Vector2(-wn.y, wn.x)
	_poly(PackedVector2Array([wroot - wp * 3.0, wtip, wroot + wp * 3.0, wroot - wn * 3.0]), STONE_L, white)
	for i in 3:
		var fp := wroot.lerp(wtip, 0.3 + i * 0.22)
		draw_line(fp - wp * 2.0, fp + wp * 2.0 - wn * 2.0, STONE_S if not white else Color.WHITE, 1.0)
	if st == SeraphStatue.S.WINDUP and not white:
		var pulse := 0.5 + 0.5 * sin(t * 40.0)
		draw_line(wroot.lerp(wtip, 0.4), wtip, Color(DANGER, 0.5 + 0.4 * pulse * k), 3.0)
		draw_circle(wtip, 2.0 + 2.0 * k, Color(DANGER, 0.6 * k))
	if st == SeraphStatue.S.SLASH and not white:
		var arc := PackedVector2Array()
		for i in 7:
			var a2 := -0.9 + i * 0.32
			arc.append(wroot + Vector2(cos(a2), sin(a2)) * 22.0)
		draw_polyline(arc, Color(GOLD, 0.8), 3.0)
		draw_polyline(arc, Color(1, 1, 1, 0.9), 1.0)
	# 살아 움직일 때: 갈라진 틈과 얼굴 자리에서 금빛
	if live > 0.02 and not white:
		var g := Color(GOLD, live)
		draw_polyline(PackedVector2Array([Vector2(-2, -31) + o, Vector2(0, -24) + o, Vector2(-3, -17) + o, Vector2(1, -9)]), g, 1.0)
		draw_polyline(PackedVector2Array([Vector2(5, -28) + o, Vector2(3, -20) + o, Vector2(6, -12)]), g, 1.0)
		draw_rect(Rect2(hc + Vector2(1, -1), Vector2(3, 1)), Color(1.0, 0.95, 0.7, live))
		draw_circle(hc + Vector2(2.5, -0.5), 3.0, Color(GOLD, 0.25 * live))
