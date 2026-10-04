extends Node2D
## 아홉 꼬리 각성 (방 개체 "st_awaken", docs/chapter5.md 8.9절 어둠): 너울의 본모습(약 130px)과 꼬리, 푸른 여우불, 금빛·푸른 기운.
## 1장 컷신의 본모습(story/actor.gd neoul_god)과 같은 사람: 얼굴을 가린 너울(천), 은백 머리, 여우귀, 흰 옷의 붉은 깃·남색 띠.
## 대본: var g = c.actor("neoul_god")  (방 데이터 who로 이름을 바꿀 수 있음)
##   g.appear(t) · g.vanish(t) · g.face(dir) · g.set_talking(on) · g.pulse(세기) · g.set_power(0~1, t)
##   g.set_tails(n)              꼬리 수 즉시 (4장 끝 = 4)
##   await g.awaken()            각성: 꼬리가 하나씩 돋아 9개 → 거대한 푸른 여우불 기둥 + 금빛 고리 (약 4초)
##   g.unveil(true)              너울(천)을 걷어 얼굴을 보인다 ("세라야." 장면)
##   await g.merge_into(전역 위치, 초)  빛이 되어 세라에게 흘러든다(구미호 완전 빙의 직전)
## 방 데이터 키: who(기본 neoul_god), tails(기본 4), hidden(true면 처음엔 안 보임), face

var who := "neoul_god"
var tails := 4
var facing := -1
var power := 0.0 ## 0~1 기운
var unveiled := 0.0 ## 0 = 천을 씀, 1 = 걷음
var awakened := 0.0 ## 0~1 각성 연출(금빛 고리·불기둥)
var _grow: Array[float] = [] ## 꼬리마다 자라난 정도 0~1
var _t := 0.0
var _talking := false
var _pulse := 0.0
var _merge := 0.0
var _glow: LightGlow
var _gold: LightGlow


func setup(room: Room, e: Dictionary, eid: String) -> void:
	who = String(e.get("who", eid if eid != "" else "neoul_god"))
	tails = clampi(int(e.get("tails", 4)), 1, 9)
	position = room.tile_pos(e) + Vector2(8, 0)
	facing = -1 if String(e.get("face", "left")) == "left" else 1
	modulate.a = 0.0 if bool(e.get("hidden", false)) else 1.0
	z_index = -1
	_grow.clear()
	for i in 9:
		_grow.append(1.0 if i < tails else 0.0)
	_glow = LightGlow.make(Vector2(0, -70), 170.0, Color(0.45, 0.75, 1.0), 0.45)
	_glow.z_index = -1
	add_child(_glow)
	_gold = LightGlow.make(Vector2(0, -70), 200.0, StArt.FOX_GOLD, 0.0)
	_gold.z_index = -1
	add_child(_gold)


func actor_id() -> String:
	return who


func appear(time := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, time)
	await tw.finished


func vanish(time := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, time)
	await tw.finished


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
	var tw := create_tween()
	tw.tween_property(self, "power", v, time)


func set_tails(n: int) -> void:
	tails = clampi(n, 1, 9)
	for i in 9:
		_grow[i] = 1.0 if i < tails else 0.0


func unveil(on := true, time := 1.2) -> void:
	var tw := create_tween()
	tw.tween_property(self, "unveiled", 1.0 if on else 0.0, time).set_trans(Tween.TRANS_SINE)


func move_to(pos: Vector2, time := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(self, "global_position", pos, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


## 각성: 남은 꼬리가 하나씩 돋는다 → 아홉 개 → 푸른 여우불 기둥과 금빛 고리
func awaken() -> void:
	set_power(1.0, 1.0)
	var root := global_position + Vector2(0, -70)
	for i in range(tails, 9):
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: _grow[i] = v, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.flash(Color(0.55, 0.85, 1.0, 0.25), 0.2)
		Fx.shake(0.2 + i * 0.03, 0.25)
		Fx.ring(root, 10.0, 90.0 + i * 12.0, StArt.FOX_BLUE, 0.5, 3.0)
		StArt.sfx_pitch(&"fox_transform", &"foxfire", 0.8 + i * 0.08, -2.0)
		tails = i + 1
		await get_tree().create_timer(0.45, true, false, true).timeout
	tails = 9
	# 각성의 정점
	Fx.hitstop(0.2)
	Fx.flash(Color(0.75, 0.92, 1.0, 0.75), 0.9)
	Fx.shake(1.0, 0.8)
	Fx.zoom_punch(0.08)
	Fx.ring(root, 16.0, 420.0, StArt.FOX_BLUE, 1.2, 5.0)
	Fx.ring(root, 16.0, 300.0, StArt.FOX_GOLD, 1.0, 3.0)
	Fx.burst(root, 120, {spread = 180.0, speed_min = 80.0, speed_max = 360.0, damping = 120.0, lifetime = 1.4,
		gradient = Palette.fade_gradient(StArt.FOX_BLUE), size_min = 1.5, size_max = 4.0, add = true})
	StArt.sfx(&"fox_storm", &"storm_final", 4.0)
	var tw2 := create_tween()
	tw2.tween_property(self, "awakened", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	await tw2.finished


## 빛이 되어 세라에게 흘러듦
func merge_into(pos: Vector2, time := 1.2) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_merge", 1.0, time * 0.5)
	tw.parallel().tween_property(self, "global_position", pos + Vector2(0, 40), time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector2(0.15, 0.15), time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	Fx.flash(Color(0.6, 0.88, 1.0, 0.8), 0.6)
	Fx.ring(pos, 6.0, 160.0, StArt.FOX_BLUE, 0.8, 4.0)
	StArt.sfx(&"fox_transform", &"foxfire", 4.0)
	visible = false


func _process(delta: float) -> void:
	_t += delta
	_pulse = maxf(_pulse - delta * 1.5, 0.0)
	if _glow:
		_glow.modulate.a = (0.45 + 0.25 * sin(_t * 2.0) + power * 0.35 + _pulse * 0.4) * modulate.a
	if _gold:
		_gold.modulate.a = awakened * (0.35 + 0.1 * sin(_t * 3.0)) * modulate.a
	queue_redraw()


func _draw() -> void:
	var f := float(facing)
	var hover := sin(_t * 1.1) * 3.0
	var base := Vector2(0, -16 + hover)
	var blue := StArt.FOX_BLUE
	var core := StArt.FOX_CORE
	var root := base + Vector2(-6 * f, -52)
	# 금빛 고리 + 불기둥 (각성)
	if awakened > 0.0:
		var a := awakened
		draw_rect(Rect2(-30, -600, 60, 600), Color(blue, 0.06 * a))
		draw_rect(Rect2(-8, -600, 16, 600), Color(core, 0.12 * a))
		draw_arc(root, 70.0 + sin(_t * 2.0) * 3.0, 0, TAU, 48, Color(StArt.FOX_GOLD, 0.65 * a), 2.0)
		draw_arc(root, 82.0, 0, TAU, 48, Color(StArt.FOX_GOLD, 0.25 * a), 1.0)
		for i in 12:
			var ang := _t * 0.4 + TAU * i / 12.0
			StArt.foxfire(self, root + Vector2.from_angle(ang) * 76.0, 3.0, _t + i, a)
	# 꼬리 (뒤에서 부채꼴, 털이 풍성하게)
	var shown := 0
	for i in 9:
		if _grow[i] > 0.01:
			shown += 1
	var idx := 0
	for i in 9:
		var g := _grow[i]
		if g <= 0.01:
			continue
		var spread := (idx - (shown - 1) * 0.5) * (0.3 if shown > 4 else 0.42)
		idx += 1
		var ang := -PI * 0.5 + spread + sin(_t * 1.2 + i) * 0.05
		var len := (96.0 + 10.0 * sin(_t + i * 0.7) + power * 18.0) * g
		var bend := sin(_t * 0.9 + i * 1.3) * 0.25
		for k in 14:
			var u := float(k) / 13.0
			var aa := ang + bend * u * u
			var p := root + Vector2(cos(aa) * len * u - 14.0 * f * u, sin(aa) * len * u)
			var rad := (4.0 + 13.0 * sin(u * PI * 0.92)) * g
			var col := Color("#f2f0ee").lerp(Color(0.7, 0.85, 1.0), u * 0.6)
			draw_circle(p, rad + 1.0, Color(0.55, 0.7, 0.95, 0.35))
			draw_circle(p, rad, col)
			if k == 13:
				StArt.foxfire(self, p, 5.0 + power * 3.0, _t + i, 1.0)
	# 치맛자락 (아래가 여우불처럼 흩어짐)
	var robe := Color("#eceff6")
	var robe_d := Color("#a6b2cc")
	var hem := PackedVector2Array([base + Vector2(-11, -62), base + Vector2(11, -62)])
	for i in 7:
		var x := 28.0 - i * 9.3
		var y := 6.0 + sin(_t * 3.0 + i * 1.3) * 4.0 + (6.0 if i % 2 == 0 else 0.0)
		hem.append(base + Vector2(x, y))
	draw_colored_polygon(hem, robe_d)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-9, -62), base + Vector2(9, -62), base + Vector2(20, 0), base + Vector2(-20, 0)]), robe)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-9, -62), base + Vector2(-3, -62), base + Vector2(-8, 0), base + Vector2(-20, 0)]), robe_d)
	for i in 5:
		StArt.foxfire(self, base + Vector2(-16.0 + i * 8.0, -1 + sin(_t * 6.0 + i) * 2.0), 2.5, _t + i * 0.7, 0.9)
	# 붉은 깃 + 남색 띠
	draw_colored_polygon(PackedVector2Array([base + Vector2(-6, -62), base + Vector2(0, -50), base + Vector2(6, -62), base + Vector2(3, -62), base + Vector2(0, -55), base + Vector2(-3, -62)]), Color("#b83a3a"))
	draw_rect(Rect2(base + Vector2(-10, -44), Vector2(20, 4)), Color("#2a3a7a"))
	draw_rect(Rect2(base + Vector2(-2, -44), Vector2(4, 16)), Color("#2a3a7a"))
	# 넓은 소매 + 손끝 여우불
	for s: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([base + Vector2(s * 9, -60), base + Vector2(s * 28, -34), base + Vector2(s * 19, -28), base + Vector2(s * 7, -48)]), robe_d)
		var hp := base + Vector2(s * 26, -30)
		StArt.foxfire(self, hp, 5.0 + sin(_t * 7.0) * 1.0 + power * 3.0 + _pulse * 3.0, _t + s, 1.0)
	# 머리·긴 은백 머리카락
	var head := base + Vector2(0, -72)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-10, -6), head + Vector2(10, -6), head + Vector2(15 + sin(_t) * 1.5, 46), head + Vector2(-15 + sin(_t * 1.1) * 1.5, 46)]), Color("#d8e0ee"))
	draw_line(head + Vector2(-8, 0), head + Vector2(-12, 44), Color("#f2f6ff"), 1.0)
	draw_circle(head, 8.5, Color("#f6ece8"))
	# 여우귀 (푸른 끝)
	for s2: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([head + Vector2(s2 * 9, -4), head + Vector2(s2 * 12, -21), head + Vector2(s2 * 2, -8)]), Color("#f4f0ea"))
		draw_colored_polygon(PackedVector2Array([head + Vector2(s2 * 8, -6), head + Vector2(s2 * 11, -17), head + Vector2(s2 * 4, -8)]), Color("#f0c8cc"))
		StArt.foxfire(self, head + Vector2(s2 * 12, -20), 2.5, _t + s2 * 3.0, 0.9)
	# 얼굴: 너울(천) 또는 걷은 얼굴
	if unveiled < 1.0:
		var va := 0.75 * (1.0 - unveiled)
		var lift := unveiled * 14.0
		var veil := PackedVector2Array([head + Vector2(-12, -10 - lift), head + Vector2(12, -10 - lift), head + Vector2(15 + sin(_t * 1.7) * 2.0, 26 - lift * 2.0), head + Vector2(-15 + sin(_t * 1.9) * 2.0, 26 - lift * 2.0)])
		draw_colored_polygon(veil, Color(0.9, 0.94, 1.0, va))
		draw_rect(Rect2(head + Vector2(-12, -11 - lift), Vector2(24, 2)), Color(0.23, 0.29, 0.6, va + 0.2))
		for i in 4:
			draw_rect(Rect2(head + Vector2(-9 + i * 6, 18 - lift * 2.0 + sin(_t + i) * 1.0), Vector2(2, 2)), Color(blue, va + 0.1))
		var eye_a := clampf(power + (0.4 if _talking else 0.2), 0.0, 1.0) * (1.0 - unveiled)
		draw_rect(Rect2(head + Vector2(-5, -1), Vector2(3, 1)), Color(0.6, 0.9, 1.0, eye_a))
		draw_rect(Rect2(head + Vector2(2, -1), Vector2(3, 1)), Color(0.6, 0.9, 1.0, eye_a))
	if unveiled > 0.0:
		var ua := unveiled
		for s3: float in [-1.0, 1.0]:
			var e := head + Vector2(s3 * 3.5, 0)
			draw_rect(Rect2(e + Vector2(-1.5, -1), Vector2(3, 2)), Color(0.3, 0.6, 1.0, ua))
			draw_rect(Rect2(e + Vector2(-0.5, -1), Vector2(1, 2)), Color(0.05, 0.08, 0.2, ua))
			draw_line(e + Vector2(s3 * 1.5, -1.5), e + Vector2(s3 * 4.0, -3.0), Color(0.72, 0.22, 0.22, ua), 1.0)
		if _talking and int(_t * 10.0) % 2 == 0:
			draw_rect(Rect2(head + Vector2(-1, 4), Vector2(2, 1)), Color(0.6, 0.3, 0.35, ua))
		else:
			draw_line(head + Vector2(-1.5, 4.5), head + Vector2(1.5, 4.5), Color(0.7, 0.35, 0.4, ua), 1.0)
	# 이마의 금 띠 + 비녀 여우불
	draw_rect(Rect2(head + Vector2(-9, -9), Vector2(18, 2)), Color("#d8b050"))
	StArt.foxfire(self, head + Vector2(0, -14), 3.0 + _pulse * 2.0 + power * 2.0, _t, 1.0)
	# 빛이 되어 흘러드는 중
	if _merge > 0.0:
		draw_circle(Vector2(0, -60), 80.0 * _merge, Color(core, 0.35 * _merge))
