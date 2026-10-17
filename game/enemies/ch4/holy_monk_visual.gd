extends Node2D
## 성갑 수도사 그림: 흰 두건(그늘 속 금빛 두 눈) + 금테 성갑 + 해 머리 지팡이 + 앞에 든 육각형 빛의 방패.
## 오른쪽을 보는 기준으로 그리고 scale.x로 뒤집는다. 예고: 내려치기 = 지팡이 머리가 붉게, 밀치기 = 방패 테두리가 붉게.

const OUTL := Color("#16101f")
const ROBE := Color("#dcd8e6")
const ROBE_S := Color("#9c96b8")
const ARMOR := Color("#f0ecf6")
const GOLD := Color("#e0b048")
const GOLD_S := Color("#9a7030")
const SKIN_SHADOW := Color("#2a2234")
const DANGER := Color("#ff3b3b")

var enemy: HolyMonk
var _walk := 0.0


func _process(delta: float) -> void:
	if enemy == null:
		return
	var sx := float(enemy.facing)
	if enemy.state == HolyMonk.S.TURN:
		sx *= 1.0 - sin(enemy.progress() * PI) * 0.6
	scale.x = sx
	rotation = enemy._airborne_spin * enemy._t * 8.0 if enemy._airborne_spin != 0.0 else 0.0
	if absf(enemy.velocity.x) > 5.0:
		_walk += delta * 7.0


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
	var st := enemy.state
	var k := enemy.progress()
	var t := enemy._t
	var o := Vector2(0, sin(t * 2.0) * 0.5)
	var lift := 0.0
	# 지팡이 (손잡이 → 머리)
	var hand := Vector2(-6, -18)
	var head := Vector2(-4, -44)
	var staff_glow := 0.0
	match st:
		HolyMonk.S.ADVANCE:
			o.y = -absf(sin(_walk)) * 0.8
			lift = maxf(sin(_walk), 0.0) * 1.5
		HolyMonk.S.SLAM_WINDUP:
			hand = Vector2(-2, -34)
			head = hand + Vector2(-10, -22).lerp(Vector2(-14, -16), k)
			staff_glow = k
			o += Vector2(-1.5 * k, 1.0 * k) + Vector2(sin(t * 50.0) * 0.4 * k, 0)
		HolyMonk.S.SLAM:
			hand = Vector2(8, -22)
			head = Vector2(18, 0)
			o += Vector2(2, 2)
		HolyMonk.S.SLAM_RECOVER:
			hand = Vector2(8, -20)
			head = Vector2(19, -1)
			o += Vector2(2, 2) * (1.0 - k * 0.6)
		HolyMonk.S.PUSH_WINDUP:
			o += Vector2(-2.0 * k, 1.0 * k)
		HolyMonk.S.PUSH:
			o += Vector2(2, 0)
		HolyMonk.S.STAGGER:
			o += Vector2(-2 + sin(t * 30.0) * 1.0, 1)
		HolyMonk.S.PRAY:
			o += Vector2(0, 3)
			hand = Vector2(2, -24)
			head = Vector2(2, -50)
	# 뒤쪽 지팡이
	draw_line(hand + o, head + o, OUTL if not white else Color.WHITE, 4.0)
	draw_line(hand + o, head + o, GOLD_S if not white else Color.WHITE, 2.0)
	var hd := head + o
	if staff_glow > 0.0 and not white:
		var pulse := 0.5 + 0.5 * sin(t * 40.0)
		draw_circle(hd, 7.0 + 3.0 * staff_glow, Color(DANGER, 0.25 + 0.4 * staff_glow * pulse))
	draw_circle(hd, 4.0, OUTL)
	draw_circle(hd, 3.0, GOLD.lerp(DANGER, staff_glow * 0.7) if not white else Color.WHITE)
	for i in 8:
		var a := TAU * i / 8.0 + t * 0.6
		draw_line(hd + Vector2(cos(a), sin(a)) * 3.5, hd + Vector2(cos(a), sin(a)) * 6.0, GOLD if not white else Color.WHITE, 1.0)
	# 다리
	draw_rect(Rect2(Vector2(-5, -6 - lift) + Vector2(o.x, 0), Vector2(4, 6)), OUTL)
	draw_rect(Rect2(Vector2(1, -6 + lift * 0.0) + Vector2(o.x, 0), Vector2(4, 6)), OUTL)
	# 로브
	var robe := PackedVector2Array([Vector2(-6, -27) + o, Vector2(7, -27) + o, Vector2(10, -3), Vector2(-10, -3)])
	_poly(robe, ROBE, white)
	if not white:
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -27) + o, Vector2(-2, -27) + o, Vector2(-4, -3), Vector2(-10, -3)]), ROBE_S)
		draw_line(Vector2(-10, -3), Vector2(10, -3), GOLD, 1.0)
		draw_line(Vector2(1, -12) + o, Vector2(2, -3), Color(GOLD, 0.6), 1.0)
	# 성갑 (가슴판)
	var plate := PackedVector2Array([Vector2(-5, -27) + o, Vector2(6, -27) + o, Vector2(7, -19) + o, Vector2(5, -14) + o, Vector2(-5, -14) + o])
	_poly(plate, ARMOR, white)
	if not white:
		draw_line(Vector2(-5, -15) + o, Vector2(5, -15) + o, GOLD, 1.0)
		draw_line(Vector2(1, -26) + o, Vector2(1, -16) + o, Color(GOLD, 0.7), 1.0)
		draw_circle(Vector2(2, -22) + o, 1.4, GOLD)
		draw_line(Vector2(-6, -13) + o, Vector2(7, -13) + o, GOLD_S, 2.0)
	# 두건 (얼굴은 그늘, 금빛 두 눈)
	var hc := Vector2(1, -32) + o
	var hood := PackedVector2Array([hc + Vector2(-7, 6), hc + Vector2(-7, -3), hc + Vector2(-3, -8), hc + Vector2(4, -8), hc + Vector2(7, -3), hc + Vector2(8, 5), hc + Vector2(5, 6)])
	_poly(hood, ROBE, white)
	if not white:
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-1, -4), hc + Vector2(6, -4), hc + Vector2(7, 4), hc + Vector2(0, 5)]), SKIN_SHADOW)
		var ec := Color(1.0, 0.85, 0.45) if st != HolyMonk.S.STAGGER else Color(1.0, 1.0, 1.0)
		if st == HolyMonk.S.SLAM_WINDUP or st == HolyMonk.S.PUSH_WINDUP:
			ec = ec.lerp(DANGER, k)
		draw_rect(Rect2(hc + Vector2(2, -1), Vector2(2, 1)), ec)
		draw_rect(Rect2(hc + Vector2(5, -1), Vector2(1, 1)), Color(ec, 0.7))
		draw_line(hc + Vector2(-3, -7), hc + Vector2(4, -7), GOLD, 1.0)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-7, -3), hc + Vector2(-3, -8), hc + Vector2(-2, -6), hc + Vector2(-5, -1)]), ROBE.lightened(0.15))
	# 앞팔
	var sh := Vector2(4, -25) + o
	var fh := Vector2(11, -19) + o
	draw_line(sh, fh, OUTL if not white else Color.WHITE, 4.0)
	draw_line(sh, fh, ROBE if not white else Color.WHITE, 2.0)
	# 빛의 방패
	_shield(o, white, st, k, t)
	# 휘청: 머리 위 금빛 별
	if st == HolyMonk.S.STAGGER and not white:
		for i in 3:
			var a := t * 6.0 + i * TAU / 3.0
			draw_rect(Rect2(Vector2(cos(a) * 7.0 + 1, -44 + sin(a) * 2.0) + o, Vector2(2, 2)), Color(1.0, 0.9, 0.5))
	# 충격파 (전역 위치 → 지역)
	for w in enemy.wave_positions():
		var gp: Vector2 = w[0]
		var wk: float = w[1]
		var dir: float = w[2]
		var lp := to_local(gp)
		var a2 := 1.0 - wk * 0.6
		var sx := dir * float(enemy.facing)
		draw_colored_polygon(PackedVector2Array([lp + Vector2(-6 * sx, 0), lp + Vector2(-2 * sx, -12), lp + Vector2(3 * sx, -9), lp + Vector2(6 * sx, 0)]), Color(1.0, 0.85, 0.45, 0.75 * a2))
		draw_colored_polygon(PackedVector2Array([lp + Vector2(-3 * sx, 0), lp + Vector2(-1 * sx, -8), lp + Vector2(3 * sx, 0)]), Color(1.0, 0.98, 0.85, a2))
		draw_line(lp + Vector2(-16 * sx, -1), lp + Vector2(-6 * sx, -1), Color(1.0, 0.85, 0.45, 0.4 * a2), 2.0)


func _shield(o: Vector2, white: bool, st: int, k: float, t: float) -> void:
	var c := HolyMonk.SHIELD_FRONT + o
	if st == HolyMonk.S.PUSH or st == HolyMonk.S.PUSH_WINDUP:
		c += Vector2(3, 0)
	if enemy.shield_hp <= 0.0:
		# 깨진 방패: 조각이 떠돌다 기도하면 모인다
		var gather := k if st == HolyMonk.S.PRAY else 0.0
		for i in 6:
			var a := t * 1.5 + i * TAU / 6.0
			var home := c + Vector2(cos(i * TAU / 6.0), sin(i * TAU / 6.0)) * 6.0
			var orbit := c + Vector2(cos(a) * 12.0, sin(a) * 9.0 + 4.0)
			var pp := orbit.lerp(home, gather)
			draw_colored_polygon(PackedVector2Array([pp + Vector2(-2, -2), pp + Vector2(2, -1), pp + Vector2(0, 3)]), Color(1.0, 0.9, 0.6, 0.6 + 0.3 * gather))
		return
	var r := 10.0
	var pts := PackedVector2Array()
	for i in 6:
		var a := PI / 6.0 + TAU * i / 6.0
		pts.append(c + Vector2(cos(a) * r * 0.75, sin(a) * r * 1.15))
	var rim := Color(1.0, 0.86, 0.45)
	if st == HolyMonk.S.PUSH_WINDUP:
		rim = rim.lerp(DANGER, k)
	if enemy.shield_flash > 0.0 or white:
		rim = Color.WHITE
	var fill := Color(1.0, 0.92, 0.65, 0.28 + 0.08 * sin(t * 3.0))
	if enemy.shield_flash > 0.0:
		fill = Color(1, 1, 1, 0.6)
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(rim, 0.35), 4.0)
	draw_polyline(closed, rim, 1.5)
	# 안쪽 해 문양 + 지나가는 반짝임
	draw_circle(c, 2.5, Color(rim, 0.8))
	for i in 6:
		var a := TAU * i / 6.0 + t * 0.8
		draw_line(c + Vector2(cos(a), sin(a)) * 3.5, c + Vector2(cos(a), sin(a)) * 5.5, Color(rim, 0.7), 1.0)
	var sy := fmod(t * 14.0, r * 2.6) - r * 1.3
	draw_line(c + Vector2(-r * 0.6, sy + 2), c + Vector2(r * 0.6, sy - 2), Color(1, 1, 1, 0.35), 1.0)
