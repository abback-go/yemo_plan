extends Node2D
## 컷신 전용 등장물 (entity "actor"). 대본이 Cut.actor(id)로 받아 움직인다.
## kind:
##   neoul_god   너울의 본모습 — 얼굴을 가린 너울(천)을 쓴 거대한 여신, 아홉 꼬리 그림자, 푸른 여우불
##   bead        여우구슬 — 제단 위에 떠 있는 푸른 구슬
##   chains      푸른 여우불 사슬 — 세라를 양쪽에서 묶음 (세라 위치를 따라감)
##   seal        봉인 마법진 — 바닥의 보랏빛 큰 원 (crack로 금이 감)
##   founder     창립자의 환영 — 금서 기록을 읽을 때 떠오르는 희미한 마녀 그림자
##   book        폭주한 마도서 — 열쇠를 물고 날아다님 (도서관 컷신)
## 공용: appear(t) · vanish(t) · move_to(전역 좌표, 초) · walk_to(x, 속도) · face(dir) · set_talking · emote · pulse(세기)

var actor_name := ""
var kind := "bead"
var facing := 1
var power := 0.0 ## 연출 세기 0~1 (너울 분노·구슬 공명·봉인 균열)
var _alpha := 1.0
var _t := 0.0
var _talking := false
var _pulse := 0.0
var _glow: LightGlow
var _broken := false
var _break_t := 0.0
var _links: Array = [] ## 사슬이 끊어질 때 흩어지는 고리


func setup(room: Room, e: Dictionary, eid: String) -> void:
	actor_name = String(e.get("who", eid))
	kind = String(e.get("kind", "bead"))
	position = room.tile_pos(e) + Vector2(8, 0)
	facing = -1 if String(e.get("face", "right")) == "left" else 1
	_alpha = 0.0 if bool(e.get("hidden", false)) else 1.0
	match kind:
		"neoul_god":
			z_index = -1
			_glow = LightGlow.make(Vector2(0, -70), 150.0, Color(0.45, 0.75, 1.0), 0.45)
		"bead":
			z_index = 3
			_glow = LightGlow.make(Vector2.ZERO, 46.0, Color(0.55, 0.85, 1.0), 0.6)
		"seal":
			z_index = -2
			_glow = LightGlow.make(Vector2(0, -6), 120.0, Color(0.6, 0.35, 0.95), 0.35)
		"founder":
			z_index = -1
			_glow = LightGlow.make(Vector2(0, -30), 70.0, Color(0.6, 0.85, 1.0), 0.3)
		"book":
			z_index = 6
			_glow = LightGlow.make(Vector2.ZERO, 40.0, Color(0.7, 0.4, 1.0), 0.4)
		_:
			z_index = 6
	if _glow:
		_glow.z_index = -1
		add_child(_glow)
	modulate.a = _alpha


func actor_id() -> String:
	return actor_name


func appear(time := 0.6) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, time)
	await t.finished


func vanish(time := 0.6) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, time)
	await t.finished


func move_to(pos: Vector2, time := 0.8, trans := Tween.TRANS_SINE) -> void:
	var t := create_tween()
	t.tween_property(self, "global_position", pos, time).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	await t.finished


func walk_to(x: float, speed := 60.0) -> void:
	var d := absf(x - global_position.x)
	if d < 1.0:
		return
	face(1 if x > global_position.x else -1)
	await move_to(Vector2(x, global_position.y), d / speed)


func face(dir: int) -> void:
	if dir != 0:
		facing = dir


func set_talking(on: bool) -> void:
	_talking = on


func emote(_kind: String, _time := 1.2) -> void:
	pulse(0.6)


func pulse(amount := 1.0) -> void:
	_pulse = maxf(_pulse, amount)


func set_power(v: float, time := 0.5) -> void:
	var t := create_tween()
	t.tween_property(self, "power", v, time)


## 사슬: 끊어짐 (고리가 흩어진다)
func break_chains() -> void:
	_broken = true
	_break_t = 0.0
	_links.clear()
	var c := _player_center()
	for side in [-1, 1]:
		for i in 7:
			var p: Vector2 = c + Vector2(side * (10 + i * 9), -4 + i * 2)
			_links.append({"p": p - global_position, "v": Vector2(side * randf_range(60, 160), randf_range(-160, -40)), "r": randf() * TAU})
	Sfx.play(&"chain", 2.0, 0.0)


func _player_center() -> Vector2:
	var w := World.get_world()
	if w and w.player:
		return w.player.center()
	return global_position


func _process(delta: float) -> void:
	_t += delta
	_pulse = maxf(_pulse - delta * 1.5, 0.0)
	if _broken:
		_break_t += delta
		for l in _links:
			l.v.y += 500.0 * delta
			l.p += l.v * delta
			l.r += delta * 8.0
	if _glow:
		_glow.modulate.a = (0.7 + 0.3 * sin(_t * 2.0) + _pulse * 0.6 + power * 0.5) * modulate.a
	queue_redraw()


func _draw() -> void:
	match kind:
		"neoul_god": _draw_god()
		"bead": _draw_bead()
		"chains": _draw_chains()
		"seal": _draw_seal()
		"founder": _draw_founder()
		"book": _draw_book()


# ─── 너울 본모습 (약 120px) ─────────────────────────────

func _draw_god() -> void:
	var f := float(facing)
	var hover := sin(_t * 1.2) * 3.0
	var base := Vector2(0, -18 + hover)
	var blue := Color(0.45, 0.78, 1.0)
	var core := Color(0.85, 0.96, 1.0)
	var anger := power
	# 아홉 꼬리 그림자 (뒤에서 부채꼴로)
	for i in 9:
		var a := -PI * 0.5 + (i - 4) * 0.28 + sin(_t * 1.3 + i) * 0.06
		var root := base + Vector2(-8 * f, -40)
		var len := 92.0 + 10.0 * sin(_t + i * 0.7) + anger * 20.0
		var tip := root + Vector2(cos(a) * len * 0.75 - 18 * f, sin(a) * len)
		var mid := root.lerp(tip, 0.55) + Vector2(sin(_t * 2.0 + i) * 6.0, 0)
		var wdt := 9.0
		var n := (tip - root).normalized().orthogonal()
		var shade := Color(0.06, 0.1, 0.22, 0.55 + anger * 0.25)
		draw_colored_polygon(PackedVector2Array([root + n * wdt * 0.6, mid + n * wdt, tip, mid - n * wdt, root - n * wdt * 0.6]), shade)
		draw_circle(tip, 4.0 + 1.5 * sin(_t * 5.0 + i), Color(blue, 0.55))
		draw_circle(tip, 2.0, Color(core, 0.7))
	# 치맛자락 (아래가 여우불처럼 흩어짐)
	var robe := Color("#e8eef6")
	var robe_d := Color("#9aa8c8")
	var hem := PackedVector2Array()
	hem.append(base + Vector2(-10, -64))
	hem.append(base + Vector2(10, -64))
	for i in 7:
		var x := 26.0 - i * 8.6
		var y := 6.0 + sin(_t * 3.0 + i * 1.3) * 4.0 + (6.0 if i % 2 == 0 else 0.0)
		hem.append(base + Vector2(x, y))
	draw_colored_polygon(hem, robe_d)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-8, -64), base + Vector2(8, -64), base + Vector2(18, 0), base + Vector2(-18, 0)]), robe)
	for i in 5:
		var fx := -16.0 + i * 8.0
		draw_rect(Rect2(base + Vector2(fx, -2 + sin(_t * 6.0 + i) * 2.0), Vector2(2, 3)), Color(blue, 0.8))
	# 띠·옷깃 (남색)
	draw_rect(Rect2(base + Vector2(-9, -46), Vector2(18, 4)), Color("#2a3a7a"))
	draw_rect(Rect2(base + Vector2(-2, -46), Vector2(4, 14)), Color("#2a3a7a"))
	# 소매 (넓게 늘어짐)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-8, -62), base + Vector2(-26, -36), base + Vector2(-18, -30), base + Vector2(-6, -50)]), robe_d)
	draw_colored_polygon(PackedVector2Array([base + Vector2(8, -62), base + Vector2(26, -36), base + Vector2(18, -30), base + Vector2(6, -50)]), robe_d)
	# 손 끝 여우불
	for s in [-1.0, 1.0]:
		var hp := base + Vector2(s * 24, -32)
		draw_circle(hp, 5.0 + sin(_t * 7.0) * 1.5 + anger * 2.0, Color(blue, 0.5))
		draw_circle(hp, 2.5, core)
	# 머리·긴 은백 머리카락
	var head := base + Vector2(0, -74)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-9, -6), head + Vector2(9, -6), head + Vector2(13, 40), head + Vector2(-13, 40)]), Color("#d8e0ee"))
	draw_circle(head, 8.0, Color("#f2e6e0"))
	# 여우귀
	draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -4), head + Vector2(-11, -19), head + Vector2(-2, -8)]), Color("#f4f0ea"))
	draw_colored_polygon(PackedVector2Array([head + Vector2(8, -4), head + Vector2(11, -19), head + Vector2(2, -8)]), Color("#f4f0ea"))
	draw_rect(Rect2(head + Vector2(-10, -17), Vector2(2, 4)), blue)
	draw_rect(Rect2(head + Vector2(8, -17), Vector2(2, 4)), blue)
	# 너울(얼굴 가리는 천): 반투명, 푸른 수 무늬. 화나면 천 아래 눈빛이 비침
	var veil := PackedVector2Array([head + Vector2(-11, -9), head + Vector2(11, -9), head + Vector2(14 + sin(_t * 1.7) * 2.0, 26), head + Vector2(-14 + sin(_t * 1.9) * 2.0, 26)])
	draw_colored_polygon(veil, Color(0.9, 0.94, 1.0, 0.72))
	draw_rect(Rect2(head + Vector2(-11, -10), Vector2(22, 2)), Color("#3a4a9a"))
	for i in 4:
		draw_rect(Rect2(head + Vector2(-9 + i * 6, 18 + sin(_t + i) * 1.0), Vector2(2, 2)), Color(blue, 0.8))
	if anger > 0.05 or _talking:
		var eye_a := clampf(anger + (0.4 if _talking else 0.0), 0.0, 1.0)
		draw_rect(Rect2(head + Vector2(-5, -1), Vector2(3, 1)), Color(0.6, 0.9, 1.0, eye_a))
		draw_rect(Rect2(head + Vector2(2, -1), Vector2(3, 1)), Color(0.6, 0.9, 1.0, eye_a))
	# 머리 위 비녀 여우불
	draw_circle(head + Vector2(0, -12), 3.0 + _pulse * 2.0, Color(blue, 0.8))


# ─── 여우구슬 ───────────────────────────────────────────

func _draw_bead() -> void:
	var y := sin(_t * 2.0) * 2.0
	var c := Vector2(0, y)
	var r := 6.0 + power * 2.0 + _pulse * 2.0
	for i in 3:
		draw_arc(c, r + 4.0 + i * 3.0 + sin(_t * 3.0 + i) * 1.0, 0, TAU, 20, Color(0.55, 0.85, 1.0, (0.35 - i * 0.1) * (0.6 + power)), 1.0)
	draw_circle(c, r + 2.0, Color(0.35, 0.65, 1.0, 0.5))
	draw_circle(c, r, Color(0.65, 0.9, 1.0))
	draw_circle(c + Vector2(-2, -2), r * 0.35, Color(1, 1, 1, 0.9))
	# 구슬 속 여우불
	var fl := sin(_t * 6.0) * 1.0
	draw_colored_polygon(PackedVector2Array([c + Vector2(-2, 3), c + Vector2(fl, -3), c + Vector2(2, 3)]), Color(0.3, 0.55, 1.0, 0.8))


# ─── 푸른 사슬 ──────────────────────────────────────────

func _draw_chains() -> void:
	var blue := Color(0.5, 0.8, 1.0)
	if _broken:
		for l in _links:
			var a := clampf(1.0 - _break_t * 0.8, 0.0, 1.0)
			var p: Vector2 = l.p
			draw_arc(p, 3.0, l.r, l.r + PI * 1.6, 6, Color(blue, a), 2.0)
		return
	var target := to_local(_player_center())
	for side in [-1.0, 1.0]:
		var anchor := Vector2(side * 70.0, 6.0)
		var d := target - anchor
		var n := int(d.length() / 7.0)
		for i in n:
			var k := float(i) / maxf(n, 1)
			var sag := sin(k * PI) * 8.0
			var p := anchor + d * k + Vector2(0, sag)
			var rot := 0.0 if i % 2 == 0 else PI * 0.5
			draw_arc(p, 3.0, rot, rot + TAU, 8, Color(blue, 0.85), 1.5)
		# 땅에 박힌 말뚝
		draw_rect(Rect2(anchor + Vector2(-3, -10), Vector2(6, 12)), Color("#3a4a6a"))
		draw_circle(anchor + Vector2(0, -11), 3.0 + sin(_t * 5.0) * 0.8, Color(blue, 0.7))
	# 세라를 감은 고리
	draw_arc(target, 11.0, 0, TAU, 16, Color(blue, 0.7 + 0.2 * sin(_t * 6.0)), 1.5)


# ─── 봉인 마법진 ────────────────────────────────────────

func _draw_seal() -> void:
	var purple := Color(0.62, 0.38, 0.95)
	var a := 0.55 + 0.25 * sin(_t * 1.5) + _pulse * 0.4
	var crack := power
	var c := Vector2(0, -2)
	# 바닥에 납작하게 (타원)
	for ring in 3:
		var rr := 70.0 - ring * 18.0
		var pts := PackedVector2Array()
		for i in 33:
			var ang := TAU * i / 32.0 + _t * (0.2 if ring % 2 == 0 else -0.3)
			pts.append(c + Vector2(cos(ang) * rr, sin(ang) * rr * 0.18))
		draw_polyline(pts, Color(purple, a * (1.0 - ring * 0.2)), 1.5)
	# 룬 (작은 네모)
	for i in 12:
		var ang := TAU * i / 12.0 + _t * 0.2
		var p := c + Vector2(cos(ang) * 61.0, sin(ang) * 61.0 * 0.18)
		draw_rect(Rect2(p - Vector2(2, 1), Vector2(4, 2)), Color(purple.lightened(0.3), a))
	# 금: 붉은 갈라짐
	if crack > 0.0:
		var red := Color(1.0, 0.3, 0.35, crack)
		draw_line(c + Vector2(-50, 2), c + Vector2(-10, -1), red, 1.5)
		draw_line(c + Vector2(-10, -1), c + Vector2(12, 3), red, 1.5)
		draw_line(c + Vector2(12, 3), c + Vector2(55, -2), red, 1.5)
		draw_line(c + Vector2(-10, -1), c + Vector2(-20, -6), red, 1.0)
	# 위로 솟는 빛기둥
	draw_rect(Rect2(c + Vector2(-60, -60), Vector2(120, 60)), Color(purple, 0.05 + _pulse * 0.1))


# ─── 창립자의 환영 ──────────────────────────────────────

func _draw_founder() -> void:
	var blue := Color(0.6, 0.85, 1.0)
	var hover := sin(_t * 1.5) * 2.0
	var b := Vector2(0, hover)
	var col := Color(blue, 0.35)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-5, -34), b + Vector2(5, -34), b + Vector2(10, 0), b + Vector2(-10, 0)]), col)
	draw_circle(b + Vector2(0, -38), 5.0, col)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-12, -40), b + Vector2(12, -40), b + Vector2(2, -60)]), Color(blue, 0.4))
	# 손에 든 푸른 불
	draw_circle(b + Vector2(9 * facing, -24), 3.0 + sin(_t * 6.0), Color(blue, 0.7))


# ─── 마도서 (열쇠를 문 책) ──────────────────────────────

func _draw_book() -> void:
	var flap := sin(_t * 14.0) * 5.0
	var c := Vector2(0, sin(_t * 3.0) * 2.0)
	var cover := Color("#4a2a6a")
	var page := Color("#e8dcc0")
	var f := float(facing)
	# 펼쳐진 표지 (날개처럼 퍼덕임)
	draw_colored_polygon(PackedVector2Array([c, c + Vector2(-12, -4 - flap), c + Vector2(-13, 4 - flap * 0.5), c + Vector2(0, 5)]), cover)
	draw_colored_polygon(PackedVector2Array([c, c + Vector2(12, -4 - flap), c + Vector2(13, 4 - flap * 0.5), c + Vector2(0, 5)]), cover.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, 1), c + Vector2(-10, -3 - flap), c + Vector2(-10, 2 - flap * 0.5), c + Vector2(0, 4)]), page)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, 1), c + Vector2(10, -3 - flap), c + Vector2(10, 2 - flap * 0.5), c + Vector2(0, 4)]), page.darkened(0.1))
	# 눈 (보라 폭주 마력)
	draw_rect(Rect2(c + Vector2(-4 * f - 1, -1), Vector2(2, 2)), Color(1.0, 0.4, 0.9))
	# 문 열쇠
	if power > 0.5:
		var k := c + Vector2(8 * f, 5)
		draw_line(k, k + Vector2(0, 7), Color("#e8c060"), 2.0)
		draw_circle(k, 2.5, Color("#e8c060"))
		draw_rect(Rect2(k + Vector2(0, 5), Vector2(3 * f, 2)), Color("#e8c060"))
	# 새어 나오는 보라 불씨
	draw_rect(Rect2(c + Vector2(sin(_t * 7.0) * 8.0, -8.0 - fmod(_t * 12.0, 6.0)), Vector2(1, 1)), Color(0.8, 0.5, 1.0, 0.8))
