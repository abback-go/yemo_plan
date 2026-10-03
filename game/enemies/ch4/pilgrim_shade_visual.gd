extends Node2D
## 순례자의 그림자 그림: 두건 망토의 순례자가 흰빛(바깥 신들의 색)에 물들어 반투명. 등불은 꺼질 듯 하얗다.
## 예고: 뻗은 손이 붉게. 풀려날 때(freed_k 0→1) 흰빛이 걷히며 원래 옷 빛깔이 돌아오고 고개를 숙인다.

const OUTL := Color("#16101f")
const SHADE := Color(0.9, 0.92, 1.0, 0.72)
const DANGER := Color("#ff3b3b")
const ROBES: Array[Color] = [Color("#6a5a48"), Color("#4e5a6a"), Color("#6a4a52")]
const SCARVES: Array[Color] = [Color("#a85a4a"), Color("#d8b860"), Color("#5a8a6a")]

var enemy: PilgrimShade


func _process(_d: float) -> void:
	if enemy:
		scale.x = float(enemy.facing)


func _draw() -> void:
	if enemy == null:
		return
	var white := enemy.flash_amount() > 0.0
	var t := enemy._t
	var st := enemy.state
	var fk := enemy.freed_k
	var robe := SHADE.lerp(ROBES[enemy.look], fk)
	var scarf := SHADE.lerp(SCARVES[enemy.look], fk)
	var skin := Color(0.92, 0.94, 1.0, 0.8).lerp(Color("#e6c4ac"), fk)
	if white:
		robe = Color.WHITE
		scarf = Color.WHITE
	var o := Vector2(0, sin(t * 1.4) * 0.6)
	var hunch := 0.0
	var reach := 0.0
	match st:
		PilgrimShade.S.REACH:
			reach = enemy.progress()
		PilgrimShade.S.GRAB:
			reach = 1.0
			o.x += 2.0
		PilgrimShade.S.SOB:
			hunch = 3.0
			o.x += sin(t * 30.0) * 0.6
		PilgrimShade.S.FREED:
			hunch = 3.0 * sin(fk * PI) # 고개 숙여 인사
	# 흰빛 아지랑이 (물든 정도)
	if fk < 1.0 and not white:
		for i in 3:
			var k := fmod(t * 0.6 + i * 0.33, 1.0)
			draw_circle(Vector2(-4 + i * 4, -26 - k * 14.0) + o, 2.0 + k * 2.0, Color(1, 1, 1, 0.18 * (1.0 - k) * (1.0 - fk)))
	# 다리·지팡이
	draw_rect(Rect2(Vector2(-3, -5) + Vector2(o.x, 0), Vector2(2, 5)), Color(robe.darkened(0.4), robe.a))
	draw_rect(Rect2(Vector2(1, -5) + Vector2(o.x, 0), Vector2(2, 5)), Color(robe.darkened(0.4), robe.a))
	draw_line(Vector2(-7, 0), Vector2(-6, -30) + o, Color(Color("#6a4a30"), robe.a), 2.0)
	# 망토 (구부정)
	var body := PackedVector2Array([Vector2(-5, -25 + hunch) + o, Vector2(5 + hunch * 0.5, -24 + hunch) + o, Vector2(8, -3), Vector2(-8, -3)])
	draw_colored_polygon(body, robe)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -25 + hunch) + o, Vector2(-1, -25 + hunch) + o, Vector2(-3, -3), Vector2(-8, -3)]), Color(robe.darkened(0.2), robe.a))
	draw_rect(Rect2(Vector2(-5, -22 + hunch) + o, Vector2(10, 3)), scarf)
	# 등불 (뒤 손): 꺼질 듯 흰빛 → 풀려나면 따뜻한 불빛
	var lp := Vector2(-6, -30) + o
	var lamp := Color(0.95, 0.97, 1.0, 0.7).lerp(Color(1.0, 0.82, 0.45), fk)
	draw_line(lp, lp + Vector2(0, 3), Color(0.3, 0.3, 0.35, 0.8), 1.0)
	draw_rect(Rect2(lp + Vector2(-2, 3), Vector2(4, 5)), lamp)
	draw_circle(lp + Vector2(0, 5), 5.0, Color(lamp, 0.15 + 0.1 * sin(t * 5.0)))
	# 두건 + 얼굴
	var hc := Vector2(2 + hunch * 0.6, -29 + hunch) + o
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-6, 4), hc + Vector2(-5, -3), hc + Vector2(0, -7), hc + Vector2(5, -5), hc + Vector2(7, 2), hc + Vector2(4, 5)]), robe.lightened(0.05))
	draw_circle(hc + Vector2(2, 0), 3.5, skin)
	if fk < 0.5:
		# 텅 빈 하얀 눈
		draw_rect(Rect2(hc + Vector2(2.5, -1), Vector2(2, 1)), Color(1, 1, 1, 0.9))
	else:
		draw_line(hc + Vector2(2.5, -0.5), hc + Vector2(4.5, 0.0), Color("#3a2a28"), 1.0)
		draw_arc(hc + Vector2(3.5, 2.5), 1.5, 0.2, PI - 0.2, 4, Color("#8a4a40"), 1.0)
	# 팔: 뻗어 붙잡기 (손이 붉게)
	var sh := Vector2(3, -21 + hunch) + o
	var hand := sh + Vector2(4 + reach * 9.0, 4 - reach * 2.0)
	if st == PilgrimShade.S.SOB:
		hand = hc + Vector2(3, 3)
	draw_line(sh, hand, robe, 2.0)
	var hc2 := skin.lerp(DANGER, reach * 0.8 if st == PilgrimShade.S.REACH else 0.0)
	draw_circle(hand, 1.6, hc2)
	if reach > 0.0 and st == PilgrimShade.S.REACH and not white:
		draw_circle(hand, 3.0 + 2.0 * reach, Color(DANGER, 0.25 * reach))
