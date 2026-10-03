class_name StarConstructVisual
extends Node2D
## 별빛 구조체 그림. kind: knight(레오니의 그림자: 단발+땋은 머리, 망토, 가늘고 긴 검) ·
## archer(엘라리엔의 그림자: 두건과 긴 귀, 키만 한 활) · lancer(아우렐리아의 그림자: 왕관 머리, 등 뒤 광륜, 날개 날 창).
## 몸은 남색 유리 + 금빛 테, 관절마다 별, 몸을 가로지르는 별자리 선, 얼굴 자리엔 별 하나(눈).
## 예고는 붉은 빛(무기 끝·눈), 잔상은 엷은 별빛 실루엣.

const GLASS := Color(0.09, 0.11, 0.32, 0.9)
const GLASS_HI := Color(0.18, 0.24, 0.55, 0.9)
const RIM := Color(1.0, 0.94, 0.72)
const CORE := Color(1.0, 0.98, 0.9)

var enemy: StarConstruct
var kind := "knight"
var scale_k := 1.0
var _walk := 0.0


func _process(delta: float) -> void:
	if enemy == null:
		return
	scale = Vector2(float(enemy.facing) * scale_k, scale_k)
	if absf(enemy.velocity.x) > 5.0 and enemy.is_on_floor():
		_walk += delta * 9.0
	queue_redraw()


func _draw() -> void:
	if enemy == null:
		return
	var t := enemy._t
	# 잔상 (전역 위치 → 지역)
	for a in enemy.afterimages:
		var k := 1.0 - float(a.t) / 0.45
		var lp := (to_local(a.pos as Vector2))
		_figure(lp * Vector2(1, 1), String(a.pose), t, k * 0.45, true)
	var white := enemy.flash_amount() > 0.0
	_figure(Vector2.ZERO, enemy.state, t, 1.0, false, white)


## pose → 관절 위치 (오른쪽을 볼 때, 발밑 원점)
func _pose(pose: String, t: float, k: float) -> Dictionary:
	var walk := sin(_walk)
	var breathe := sin(t * 2.0) * 0.5
	var d := {
		"lean": 0.0, "crouch": 0.0, "hf": Vector2(9, -16), "hb": Vector2(-6, -15), "step": walk * 2.5,
		"weapon": 0.4, "glow": 0.0, "eye": RIM, "breathe": breathe,
	}
	match kind:
		"knight":
			match pose:
				"windup":
					d.crouch = 3.0 * k
					d.lean = 0.2
					d.hf = Vector2(-6, -15)
					d.hb = Vector2(-8, -16)
					d.weapon = PI * 0.92
					d.glow = k
					d.eye = Palette.DANGER
				"dash":
					d.lean = 0.45
					d.crouch = 2.0
					d.hf = Vector2(-4, -14)
					d.hb = Vector2(-7, -15)
					d.weapon = PI * 0.95
				"slash", "combo":
					d.lean = 0.2
					d.hf = Vector2(13, -20)
					d.hb = Vector2(-6, -18)
					d.weapon = -0.15
					d.glow = 1.0 - k
				"combo_wind":
					d.hf = Vector2(-2, -26)
					d.hb = Vector2(-6, -20)
					d.weapon = -2.2
					d.eye = Palette.DANGER
				"guard":
					d.hf = Vector2(8, -18)
					d.hb = Vector2(6, -22)
					d.weapon = -PI * 0.5
					d.glow = 0.5 + 0.5 * sin(t * 10.0)
				"counter":
					d.lean = 0.4
					d.hf = Vector2(14, -18)
					d.weapon = 0.0
				"wave_wind":
					d.hf = Vector2(2, -30)
					d.hb = Vector2(-2, -28)
					d.weapon = -1.9
					d.eye = Palette.DANGER
					d.glow = k
				"wave":
					d.crouch = 3.0
					d.hf = Vector2(12, -6)
					d.hb = Vector2(6, -8)
					d.weapon = 1.1
				"iai":
					d.crouch = 4.0
					d.lean = 0.25
					d.hf = Vector2(-1, -14)
					d.hb = Vector2(-4, -14)
					d.weapon = PI * 0.96
					d.glow = k
					d.eye = Palette.DANGER if k > 0.6 else RIM
				"iai_cut":
					d.lean = 0.3
					d.hf = Vector2(15, -18)
					d.hb = Vector2(-8, -16)
					d.weapon = 0.05
				"stagger", "recover":
					d.lean = -0.25
					d.hf = Vector2(4, -10)
					d.weapon = 1.3
		"archer":
			d.hf = Vector2(8, -18)
			d.hb = Vector2(-4, -15)
			match pose:
				"aim", "fan_wind", "rain_wind":
					d.hf = Vector2(12, -22) if pose != "rain_wind" else Vector2(6, -32)
					d.hb = Vector2(-2, -22) if pose != "rain_wind" else Vector2(-1, -27)
					d.glow = k
					d.eye = Palette.DANGER if k > 0.65 else RIM
				"release":
					d.hf = Vector2(12, -22)
					d.hb = Vector2(-7, -24)
		"lancer":
			d.hf = Vector2(8, -20)
			d.hb = Vector2(-3, -17)
			match pose:
				"windup", "thrust_wind":
					d.crouch = 3.0 * k
					d.lean = -0.18
					d.hf = Vector2(-1, -20)
					d.hb = Vector2(-8, -20)
					d.glow = k
					d.eye = Palette.DANGER
				"charge":
					d.lean = 0.42
					d.crouch = 2.0
					d.hf = Vector2(13, -19)
					d.hb = Vector2(5, -19)
				"thrust":
					d.lean = 0.25
					d.hf = Vector2(15, -20)
					d.hb = Vector2(7, -20)
				"rain_wind":
					d.hf = Vector2(7, -36)
					d.hb = Vector2(-4, -30)
					d.glow = k
					d.eye = Palette.DANGER
				"recover":
					d.lean = -0.15
					d.crouch = 2.0
					d.hf = Vector2(9, -12)
	return d


func _figure(o: Vector2, pose: String, t: float, alpha: float, ghost: bool, white := false) -> void:
	var k := enemy.progress() if not ghost else 1.0
	var d := _pose(pose, t, k)
	var glass := Color(GLASS, GLASS.a * alpha) if not white else Color(1, 1, 1, alpha)
	var rim := Color(RIM, 0.95 * alpha)
	if ghost:
		glass = Color(0.6, 0.65, 1.0, 0.25 * alpha)
		rim = Color(RIM, 0.35 * alpha)
	var h := 38.0 if kind == "knight" else (36.0 if kind == "archer" else 42.0)
	var lean: float = d.lean
	var crouch: float = d.crouch
	var hip := o + Vector2(0, -h * 0.42 + crouch + float(d.breathe) * 0.3)
	var sh := hip + Vector2(lean * 10.0, -h * 0.3)
	var head := sh + Vector2(1 + lean * 3.0, -h * 0.17)
	var step: float = d.step
	var knee_f := hip + Vector2(3 + step, h * 0.2)
	var foot_f := o + Vector2(4 + step * 1.5, 0)
	var knee_b := hip + Vector2(-2 - step, h * 0.21)
	var foot_b := o + Vector2(-4 - step * 1.5, 0)
	var hf: Vector2 = o + (d.hf as Vector2) + Vector2(lean * 6.0, crouch)
	var hb: Vector2 = o + (d.hb as Vector2) + Vector2(lean * 5.0, crouch)
	var glow: float = d.glow

	# 등 뒤 장식: 망토(기사) / 광륜(창기사)
	if kind == "knight":
		var wav := sin(t * 3.0) * 2.0
		var cape := PackedVector2Array([sh + Vector2(-3, 0), sh + Vector2(3, 0), o + Vector2(-6 - lean * 8.0, -3 + wav * 0.3), o + Vector2(-14 - lean * 14.0 + wav, -6)])
		draw_colored_polygon(cape, Color(0.12, 0.08, 0.3, 0.6 * alpha) if not ghost else glass)
		draw_polyline(cape + PackedVector2Array([cape[0]]), Color(rim, rim.a * 0.6), 1.0)
		for i in 3:
			draw_rect(Rect2(sh.lerp(o + Vector2(-10, -5), 0.3 + i * 0.22) - Vector2(1, 0), Vector2(1, 1)), Color(CORE, 0.7 * alpha))
	elif kind == "lancer":
		var hc := sh + Vector2(-5, -6)
		draw_arc(hc, 11.0, 0, TAU, 24, Color(RIM, 0.6 * alpha), 2.0)
		draw_arc(hc, 8.5, 0, TAU, 20, Color(RIM, 0.25 * alpha), 1.0)
		for i in 6:
			var a := t * 0.6 + TAU * i / 6.0
			draw_rect(Rect2(hc + Vector2(cos(a), sin(a)) * 11.0 - Vector2(1, 1), Vector2(2, 2)), Color(CORE, alpha))

	# 다리
	_limb(hip + Vector2(-1, 0), knee_b, 2.6, 2.2, glass, rim)
	_limb(knee_b, foot_b, 2.2, 1.8, glass, rim)
	if kind == "lancer":
		# 천 치마 갑옷
		var sk := PackedVector2Array([hip + Vector2(-5, -2), hip + Vector2(6, -2), hip + Vector2(9, 9), hip + Vector2(-8, 9)])
		draw_colored_polygon(sk, glass)
		draw_polyline(sk + PackedVector2Array([sk[0]]), rim, 1.0)
	_limb(hip + Vector2(1, 0), knee_f, 2.8, 2.3, glass, rim)
	_limb(knee_f, foot_f, 2.3, 1.9, glass, rim)
	# 뒷팔
	_limb(sh + Vector2(-2, 1), hb, 2.0, 1.6, glass, rim)
	# 활(궁수)은 몸 뒤쪽 팔과 함께
	# 몸통
	var torso := PackedVector2Array([hip + Vector2(-4, 0), hip + Vector2(4, 0), sh + Vector2(5, 0), sh + Vector2(-4, 0)])
	draw_colored_polygon(torso, glass)
	draw_colored_polygon(PackedVector2Array([hip + Vector2(1, -1), hip + Vector2(4, -1), sh + Vector2(5, 1), sh + Vector2(2, 1)]), Color(GLASS_HI, GLASS_HI.a * alpha) if not ghost else glass)
	draw_polyline(torso + PackedVector2Array([torso[0]]), rim, 1.0)
	# 머리 (얼굴 없는 별빛 머리 + 실루엣 장식)
	var hr := 5.0
	draw_circle(head, hr + 1.0, rim)
	draw_circle(head, hr, glass if not white else Color(1, 1, 1, alpha))
	match kind:
		"knight":
			# 단발 + 귀 뒤로 땋은 머리
			draw_colored_polygon(PackedVector2Array([head + Vector2(-5.5, -1), head + Vector2(-3, -6), head + Vector2(3, -6), head + Vector2(5.5, -2), head + Vector2(4, 1), head + Vector2(-4, 3)]), Color(0.15, 0.18, 0.45, alpha))
			draw_line(head + Vector2(-4, 2), head + Vector2(-6, 8), rim, 1.0)
			draw_rect(Rect2(head + Vector2(-7, 7), Vector2(2, 2)), Color(CORE, alpha))
		"archer":
			# 두건 + 긴 귀
			draw_colored_polygon(PackedVector2Array([head + Vector2(-6, 3), head + Vector2(-5, -5), head + Vector2(1, -7), head + Vector2(6, -3), head + Vector2(4, 0), head + Vector2(-2, -1)]), Color(0.1, 0.2, 0.25, 0.8 * alpha))
			draw_colored_polygon(PackedVector2Array([head + Vector2(3, -2), head + Vector2(10, -6), head + Vector2(4, 0)]), glass)
			draw_line(head + Vector2(4, -2), head + Vector2(10, -6), rim, 1.0)
			draw_line(head + Vector2(-5, 3), sh + Vector2(-6, 6), Color(rim, rim.a * 0.6), 1.0)
		"lancer":
			# 정수리에 땋아 올린 왕관 머리 + 허리까지 긴 머리
			draw_arc(head + Vector2(0, -4), 4.0, PI, TAU, 8, rim, 2.0)
			var hair := PackedVector2Array([head + Vector2(-5, -2), head + Vector2(-2, 2), hip + Vector2(-5, 0), hip + Vector2(-9, -2)])
			draw_colored_polygon(hair, Color(0.2, 0.18, 0.4, 0.7 * alpha))
			draw_line(head + Vector2(-5, -2), hip + Vector2(-9, -2), Color(rim, rim.a * 0.5), 1.0)
	# 얼굴 자리의 별 (눈) — 예고 때 붉게
	var eye_col: Color = d.eye
	var ep := head + Vector2(2, 0)
	draw_circle(ep, 2.5, Color(eye_col, 0.25 * alpha))
	StArt.star(self, ep, 2.0, Color(eye_col, alpha), -PI * 0.5 + t * 2.0)
	# 무기
	if not ghost or kind == "knight":
		_weapon(hf, hb, d, t, alpha, ghost, pose)
	# 앞팔
	_limb(sh + Vector2(2, 1), hf, 2.2, 1.7, glass, rim)
	# 관절의 별 + 몸을 가로지르는 별자리 선
	var joints := [head + Vector2(-1, 3), sh + Vector2(4, 0), hf, hip + Vector2(3, 0), knee_f, foot_f + Vector2(0, -1)]
	for i in range(1, joints.size()):
		draw_line(joints[i - 1], joints[i], Color(CORE, 0.25 * alpha), 1.0)
	for i in joints.size():
		var tw := StArt.twinkle(t, i * 1.3, 1.5)
		draw_rect(Rect2((joints[i] as Vector2) - Vector2(1, 1), Vector2(2, 2)), Color(CORE, (0.5 + 0.5 * tw) * alpha))
	if glow > 0.02 and not ghost:
		draw_circle(hf, 3.0 + glow * 4.0, Color(Palette.DANGER if kind != "archer" or glow > 0.65 else StArt.STAR, 0.18 * glow))


func _limb(a: Vector2, b: Vector2, w1: float, w2: float, fill: Color, rim: Color) -> void:
	var dd := b - a
	if dd.length() < 0.5:
		return
	var n := dd.orthogonal().normalized()
	var poly := PackedVector2Array([a + n * w1, b + n * w2, b - n * w2, a - n * w1])
	draw_colored_polygon(poly, fill)
	draw_line(a + n * w1, b + n * w2, rim, 1.0)
	draw_line(a - n * w1, b - n * w2, Color(rim, rim.a * 0.6), 1.0)


func _weapon(hf: Vector2, hb: Vector2, d: Dictionary, t: float, alpha: float, ghost: bool, pose: String) -> void:
	var glow: float = d.glow
	match kind:
		"knight":
			var ang: float = d.weapon
			var dir := Vector2(cos(ang), sin(ang))
			var len := 24.0
			var tip := hf + dir * len
			var col := Color(StArt.STAR, (0.4 if ghost else 0.9) * alpha)
			draw_line(hf - dir * 3.0, hf, Color(0.3, 0.2, 0.5, alpha), 2.0)
			draw_line(hf, tip, Color(col, col.a * 0.35), 3.0)
			draw_line(hf, tip, col, 1.0)
			draw_line(hf + dir.orthogonal() * 3.0, hf - dir.orthogonal() * 3.0, Color(RIM, alpha), 1.0)
			if glow > 0.0 and not ghost:
				draw_circle(tip, 2.0 + glow * 3.0, Color(Palette.DANGER, 0.35 * glow))
			if (pose == "slash" or pose == "combo" or pose == "iai_cut") and not ghost:
				var k := enemy.progress()
				var arc := PackedVector2Array()
				for i in 10:
					var a := lerpf(-1.6, 0.4, float(i) / 9.0)
					arc.append(hf + Vector2(cos(a), sin(a)) * 22.0)
				draw_polyline(arc, Color(StArt.STAR, 0.7 * (1.0 - k) * alpha), 3.0)
		"archer":
			# 키만 한 활: 별 점으로 이은 활대 + 빛 시위
			var c := hf
			var arc2: Array = []
			for i in 7:
				var a := lerpf(-1.2, 1.2, float(i) / 6.0)
				arc2.append(c + Vector2(cos(a) * 4.0, sin(a) * 16.0))
			for i in range(1, arc2.size()):
				draw_line(arc2[i - 1], arc2[i], Color(RIM, 0.9 * alpha), 1.0)
			var pull := hb if pose in ["aim", "fan_wind", "rain_wind"] else c + Vector2(-1, 0)
			draw_line(arc2[0], pull, Color(StArt.STAR, 0.6 * alpha), 1.0)
			draw_line(pull, arc2[arc2.size() - 1], Color(StArt.STAR, 0.6 * alpha), 1.0)
			if pose in ["aim", "fan_wind", "rain_wind"]:
				var tip2 := c + (c - pull).normalized() * 8.0
				draw_line(pull, tip2, Color(StArt.STAR_CORE, alpha), 1.0)
				draw_circle(tip2, 2.0 + glow * 2.0, Color(Palette.DANGER if glow > 0.65 else StArt.STAR, 0.4 * alpha))
		"lancer":
			var dir2 := (hf - hb).normalized() if hf.distance_to(hb) > 2.0 else Vector2(0, -1)
			if pose in ["idle", "walk", "recover"]:
				dir2 = Vector2(0.15, -1).normalized()
			if pose == "rain_wind":
				dir2 = Vector2(0.1, -1).normalized()
			var butt := hf - dir2 * 16.0
			var tip3 := hf + dir2 * 20.0
			draw_line(butt, tip3, Color(RIM, 0.8 * alpha), 2.0)
			var n := dir2.orthogonal()
			var head := PackedVector2Array([tip3 + dir2 * 6.0, tip3 + n * 3.0, tip3 + dir2 * 1.0 + n * 6.0, tip3 - dir2 * 2.0, tip3 + dir2 * 1.0 - n * 6.0, tip3 - n * 3.0])
			draw_colored_polygon(head, Color(StArt.STAR, 0.9 * alpha))
			if glow > 0.0:
				draw_circle(tip3 + dir2 * 3.0, 3.0 + glow * 4.0, Color(Palette.DANGER, 0.3 * glow))
			if pose == "charge":
				for i in 4:
					draw_line(butt - dir2 * (4.0 + i * 3.0) + n * (i - 1.5) * 3.0, butt - dir2 * (16.0 + i * 5.0) + n * (i - 1.5) * 3.0, Color(StArt.STAR, 0.4 * alpha), 1.0)
