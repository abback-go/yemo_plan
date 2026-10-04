extends RefCounted
## 5장 지역 배경 (RoomBackdrop가 부름). 1장 room_backdrop.gd의 층 그림을 참고.
##   star      별의 탑: 은하수·별자리(구미호·마녀 모자)·고리 행성 / 먼 층 떠 있는 섬과 별빛 다리 / 중간 층 거대한 천구의 고리 / 가까운 층 별자리 기둥과 별 등롱
##   void      어둠: 검은 하늘, 아주 희미한 아홉 꼬리 그림자, 떠오르는 푸른 여우불, 물거울 같은 바닥 반사
##   sky       하늘의 문: 갈라진 흰 하늘 속의 눈들, 기하학 무늬, 흰 빛줄기 / 구름 바다 위로 솟은 거신의 머리 / 떠다니는 세계의 조각
##   festival  축제 저녁: 노을·불꽃놀이 / 불 켜진 학교와 등불 줄 / 천막
##   ruin_*    침공(땅울림): 불타는 지평선, 하늘의 균열과 눈, 떨어지는 흰 빛 / 먼 층·중간 층에서 행진하는 하얀 거신들 / 무너진 지역 구조물과 불길
##   rise      반격의 새벽: 같은 폐허지만 푸른 여우불이 하늘 균열을 꿰매고 거신들에게 번진다
##   st_kingdom·st_elf·st_temple·st_garden  별의 시련: 리라의 별하늘(별이 떨어지는 줄기) 아래 각 지역의 밤 실루엣
##   star_flip 별의 탑 4층(뒤집힘): star를 위아래로 뒤집어 그림 — 탑과 은하수가 머리 위에 매달린다
##   dawn      에필로그: 복숭앗빛 아침, 푸른 실로 꿰맨 하늘의 흉터, 비계를 두른 학교(부러진 시계탑을 다시 세우는 중)
## 거신의 걸음은 전역 시계(march_clock)를 써서 땅 흔들림 장치(world/entities/ch5/quake.gd)와 박자가 맞는다.

const RUINS := ["ruin_school", "ruin_kingdom", "ruin_elf", "ruin_temple"]
const TRIALS := ["st_kingdom", "st_elf", "st_temple", "st_garden"]
const MINE := ["star", "void", "sky", "festival", "ruin_school", "ruin_kingdom", "ruin_elf", "ruin_temple", "rise",
	"st_kingdom", "st_elf", "st_temple", "st_garden", "dawn", "star_flip"]
const Kit := preload("res://world/themes/backdrop_kit.gd")
const MARCH_PERIOD := 3.6 ## 중간 층 거신 한 걸음 주기의 두 배(두 걸음). 발이 닿는 순간 = 위상 0.25·0.75


static func march_clock() -> float:
	return Time.get_ticks_msec() / 1000.0


## 중간 층 거신의 발이 막 닿았는가 (흔들림 장치가 묻는다). 직전 확인 시각 이후 0.25/0.75 위상을 지났으면 true
static func step_between(t0: float, t1: float) -> bool:
	var a := t0 / MARCH_PERIOD
	var b := t1 / MARCH_PERIOD
	for k in [0.25, 0.75]:
		var n := floorf(b - k)
		if a - k < n and b - k >= n:
			return true
	return false


## 움직이는 층(예전 is_animated): 시련·새벽은 먼·중간 층, 나머지는 전경을 뺀 모든 층(폐허·반격·축제는 전경도).
## 그 밖의 층에서 t는 0으로 멈춘 그림이다. 그리기 계약(l = Pen, 움직이는 것만 l.anim)은 backdrop_kit.gd 머리말.
## 주의: _bot()은 층마다 바뀌는 정적 변수라 l.anim 람다 안에서 부르지 말고 기록할 때 값을 잡아 둔다.
static func has_theme(theme: String) -> bool:
	return theme in MINE


static func has_sky(theme: String) -> bool:
	return theme in MINE


# ═══════════════════════════════════════════════════════════
# 하늘 (화면 고정 640×360)
# ═══════════════════════════════════════════════════════════

## c = Pen (방 진입 때 한 번). t를 쓰는 것만 c.anim
static func draw_sky(c, theme: String, pal: Dictionary, _t: float) -> void:
	match theme:
		"star": _sky_star(c, pal)
		"star_flip":
			c.draw_set_transform(Vector2(0, 360), 0.0, Vector2(1, -1))
			_sky_star(c, pal)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"void": _sky_void(c, pal)
		"sky": _sky_gate(c, pal)
		"festival": _sky_festival(c, pal)
		"rise": _sky_ruin(c, pal, true)
		"st_kingdom", "st_elf", "st_temple", "st_garden": _sky_trial(c, pal)
		"dawn": _sky_dawn(c, pal)
		_: _sky_ruin(c, pal, false)


static func _gradient(c, cols: Array, steps := 24) -> void:
	Kit.grad_keyed(c, cols, steps)


## 반짝이는 별밭 (위치는 기록할 때 뽑아 두고 반짝임만 움직임)
static func _starfield(c, n: int, seed: int, h := 360.0, a := 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var ps := PackedVector2Array()
	for i in n:
		ps.append(Vector2(rng.randf() * 640, rng.randf() * h))
	c.anim(Rect2(-4, -4, 648, h + 8), func(cv: CanvasItem, t: float) -> void:
		for i in n:
			var p := ps[i]
			var tw := StArt.twinkle(t, float(i), 1.2)
			var big := i % 13 == 0
			var col := Color(1.0, 0.96, 0.85) if i % 3 == 0 else Color(0.85, 0.9, 1.0)
			cv.draw_rect(Rect2(p, Vector2.ONE * (2 if big else 1)), Color(col, (0.25 + 0.75 * tw) * a))
			if big and tw > 0.8:
				StArt.sparkle(cv, p + Vector2(1, 1), 3.0, Color(col, a), (tw - 0.8) * 5.0))


## StArt(CanvasItem 타입 도우미)의 정적 빛 덩이를 Pen에 기록
static func _st_glow(l, p: Vector2, r: float, col: Color, a := 0.25) -> void:
	l.fn(Kit.bb_circle(p, r), func(cv: CanvasItem) -> void: StArt.glow(cv, p, r, col, a))


# ─── 별의 탑 ────────────────────────────────────────────

const FOX_CONST := [Vector2(70, 120), Vector2(92, 100), Vector2(118, 104), Vector2(132, 86), Vector2(120, 70), Vector2(132, 86), Vector2(156, 92), Vector2(178, 76), Vector2(190, 52), Vector2(178, 76), Vector2(196, 84), Vector2(222, 70)]
const HAT_CONST := [Vector2(398, 150), Vector2(424, 146), Vector2(450, 140), Vector2(436, 116), Vector2(430, 94), Vector2(446, 82), Vector2(462, 90)]


static func _sky_star(c, pal: Dictionary) -> void:
	_gradient(c, [[0.0, pal.sky_top], [0.55, Color("#0c1240")], [1.0, pal.sky_bottom]])
	# 은하수 (비스듬한 띠)
	for i in 40:
		var k := float(i) / 39.0
		var p := Vector2(-40 + k * 720, 300 - k * 260)
		c.draw_circle(p, 46.0 + 14.0 * sin(i * 1.7), Color(0.35, 0.4, 0.85, 0.035))
		c.draw_circle(p + Vector2(10, -6), 24.0, Color(0.75, 0.7, 1.0, 0.03))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var mw := PackedVector2Array()
	for i in 140:
		var k := rng.randf()
		mw.append(Vector2(-40 + k * 720, 300 - k * 260) + Vector2(rng.randfn(0, 1) * 30, rng.randfn(0, 1) * 22))
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 140:
			cv.draw_rect(Rect2(mw[i], Vector2.ONE), Color(0.9, 0.9, 1.0, 0.25 + 0.5 * StArt.twinkle(t, i * 0.7, 0.6))))
	_starfield(c, 150, 5)
	# 별자리: 구미호(너울)와 마녀 모자(리라) — 선이 천천히 숨쉰다
	c.anim(Rect2(60, 40, 180, 90), func(cv: CanvasItem, t: float) -> void: StArt.constellation(cv, FOX_CONST, StArt.STAR, 0.55 + 0.35 * sin(t * 0.7)))
	c.anim(Rect2(390, 74, 80, 84), func(cv: CanvasItem, t: float) -> void: StArt.constellation(cv, HAT_CONST, StArt.STAR, 0.55 + 0.35 * sin(t * 0.7 + 2.0)))
	# 고리 행성 + 도는 달
	var pc := Vector2(540, 74)
	_ring_half(c, pc, 62.0, 13.0, -0.25, true)
	c.draw_circle(pc, 30, Color("#3a3c8a"))
	c.draw_circle(pc + Vector2(-5, -5), 26, Color("#4a4ea0"))
	for b in 4:
		var by := -18.0 + b * 10.0
		var half := sqrt(maxf(30.0 * 30.0 - by * by, 0.0))
		c.draw_line(pc + Vector2(-half, by), pc + Vector2(half, by), Color("#5a5eb8", 0.5), 2.0)
	c.draw_arc(pc, 30, PI * 0.15, PI * 1.05, 16, Color(0.05, 0.06, 0.2, 0.6), 7.0)
	_ring_half(c, pc, 62.0, 13.0, -0.25, false)
	c.anim(Kit.bb_circle(pc, 94.0), func(cv: CanvasItem, t: float) -> void:
		var ma := t * 0.25
		var mp := pc + Vector2(cos(ma) * 84.0, sin(ma) * 22.0)
		if sin(ma) < 0.0:
			cv.draw_circle(mp, 6, Color("#c8c4e8"))
		else:
			cv.draw_circle(mp, 7, Color("#e8e4ff"))
			cv.draw_circle(mp + Vector2(-2, -1), 5, Color("#ffffff", 0.3)))
	# 별똥별 (가끔)
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		var slot := floorf(t / 4.0)
		var lt := fmod(t, 4.0)
		if lt < 0.8:
			var sx := fmod(slot * 211.0, 600.0) + 20.0
			var sp := Vector2(sx, 30 + fmod(slot * 57.0, 90.0)) + Vector2(1, 0.45) * lt * 260.0
			cv.draw_line(sp, sp - Vector2(1, 0.45) * 30.0, Color(StArt.STAR, 0.8 * (1.0 - lt / 0.8)), 1.0))


static func _ring_half(c, p: Vector2, rx: float, ry: float, tilt: float, back: bool) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a := (PI if back else 0.0) + PI * i / 24.0
		pts.append(p + Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt))
	c.draw_polyline(pts, Color("#c8b880", 0.75 if not back else 0.45), 3.0)
	c.draw_polyline(pts, Color("#fff0c0", 0.5 if not back else 0.25), 1.0)


# ─── 어둠 ───────────────────────────────────────────────

static func _sky_void(c, pal: Dictionary) -> void:
	_gradient(c, [[0.0, pal.sky_top], [0.7, Color("#01020a")], [1.0, pal.sky_bottom]])
	# 아주 느리게 떠오르는 푸른 불티
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var ex := PackedFloat64Array()
	var es := PackedFloat64Array()
	var eo := PackedFloat64Array()
	for i in 46:
		ex.append(rng.randf() * 640.0)
		es.append(rng.randf_range(4.0, 12.0))
		eo.append(rng.randf() * 400.0)
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 46:
			var y := 380.0 - fmod(t * es[i] + eo[i], 420.0)
			var a := 0.15 + 0.35 * StArt.twinkle(t, i, 0.8)
			cv.draw_rect(Rect2(Vector2(ex[i] + sin(t * 0.6 + i) * 6.0, y), Vector2.ONE * (2 if i % 7 == 0 else 1)), Color(StArt.FOX_BLUE, a)))


# ─── 하늘의 문 ──────────────────────────────────────────

static func _sky_gate(c, pal: Dictionary) -> void:
	# 구름 위, 갈라진 검은 하늘. 위쪽 가운데(문이 열리는 자리)가 가장 어둡고, 지평선은 구름빛으로 밝아진다
	_gradient(c, [[0.0, pal.sky_top], [0.5, Color("#110f1c")], [0.85, pal.sky_bottom], [1.0, Color("#5a5870")]])
	_starfield(c, 60, 31, 240.0, 0.5)
	# 바깥 신들의 기하학 무늬 (동심원·육각·방사선) — 문 자리를 중심으로 천천히 돈다
	var gc := Vector2(320, 96)
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 6:
			var r := 70.0 + i * 62.0
			cv.draw_arc(gc, r + sin(t * 0.3 + i) * 3.0, 0, TAU, 56, Color(0.85, 0.85, 1.0, 0.07 - i * 0.008), 1.0)
		for i in 12:
			var a := TAU * i / 12.0 + t * 0.015
			cv.draw_line(gc + Vector2(cos(a), sin(a)) * 70.0, gc + Vector2(cos(a), sin(a)) * 420.0, Color(0.85, 0.85, 1.0, 0.04), 1.0)
		var hexp := PackedVector2Array()
		for i in 7:
			var a := TAU * i / 6.0 - t * 0.02
			hexp.append(gc + Vector2(cos(a), sin(a)) * 150.0)
		cv.draw_polyline(hexp, Color(0.9, 0.9, 1.0, 0.08), 1.0))
	# 갈라진 하늘: 흰 빛이 새는 틈과 그 안의 눈
	var cracks := [
		[Vector2(20, -10), Vector2(170, 160), 11, 30.0], [Vector2(230, -10), Vector2(255, 70), 23, 18.0],
		[Vector2(430, -10), Vector2(395, 90), 37, 20.0], [Vector2(660, 10), Vector2(500, 170), 41, 34.0],
		[Vector2(-10, 220), Vector2(110, 250), 53, 16.0], [Vector2(650, 230), Vector2(540, 250), 61, 18.0],
	]
	for i in cracks.size():
		var cr: Array = cracks[i]
		var ca: Vector2 = cr[0]
		var cb: Vector2 = cr[1]
		c.anim(_bb_crack(ca, cb, float(cr[3]) * 1.06), func(cv: CanvasItem, t: float) -> void:
			_sky_crack(cv, ca, cb, int(cr[2]), float(cr[3]) * (1.0 + 0.06 * sin(t * 0.8 + i)), t, i, Vector2(320, 280), false))
	# 떨어지는 흰 빛
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void: _falling_light(cv, t, 2.4, Color(1, 1, 1), 0.0, 300.0))


## 하늘 균열 하나의 bbox (틈 폭·잔금·눈·바늘땀을 덮게)
static func _bb_crack(a: Vector2, b: Vector2, width: float) -> Rect2:
	return Rect2(a, Vector2.ZERO).expand(b).grow(width + (b - a).length() * 0.1 + 30.0)


## 하늘의 균열 하나 (bible/art.md 4절 "검은 하늘에 흰 선이 갈라지고 그 안에 눈"):
## 들쭉날쭉한 틈 안쪽은 하얗게 쏟아지는 빛, 넓은 곳에 눈 하나. sealed = 푸른 불로 꿰매지는 중(seal_k 0~1)
static func _sky_crack(c, a: Vector2, b: Vector2, seed: int, width: float, t: float, idx: int, look_at: Vector2, sealed: bool, seal_k := 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := 9
	var d := b - a
	var nrm := d.orthogonal().normalized()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var center: Array[Vector2] = []
	var close := seal_k if sealed else 0.0
	for i in n + 1:
		var k := float(i) / n
		var bulge := sin(k * PI) * width * (0.6 + 0.4 * rng.randf()) * (1.0 - close * 0.8)
		var p := a + d * k + nrm * rng.randf_range(-1.0, 1.0) * d.length() * 0.08
		center.append(p)
		left.append(p + nrm * bulge * 0.5)
		right.append(p - nrm * bulge * 0.5)
	var poly := left.duplicate()
	var rr := right.duplicate()
	rr.reverse()
	poly.append_array(rr)
	var edge := StArt.GOD_GLOW if not sealed else StArt.FOX_BLUE
	# 바깥 번짐 → 하얀 속 → 가장자리 선
	c.draw_polyline(poly + PackedVector2Array([poly[0]]), Color(edge, 0.12), 9.0)
	c.draw_polyline(poly + PackedVector2Array([poly[0]]), Color(edge, 0.25), 4.0)
	c.draw_colored_polygon(poly, Color(0.96, 0.96, 1.0).lerp(Color(0.6, 0.85, 1.0), close))
	c.draw_polyline(poly + PackedVector2Array([poly[0]]), Color(0.05, 0.05, 0.1, 0.7), 1.0)
	# 갈라짐에서 뻗는 가는 금
	for i in range(2, n - 1, 3):
		var p0: Vector2 = left[i]
		c.draw_line(p0, p0 + nrm * rng.randf_range(8, 22) + d.normalized() * rng.randf_range(-10, 10), Color(edge, 0.5), 1.0)
		var p1: Vector2 = right[i]
		c.draw_line(p1, p1 - nrm * rng.randf_range(8, 22) + d.normalized() * rng.randf_range(-10, 10), Color(edge, 0.5), 1.0)
	# 눈: 가장 넓은 곳(가운데)에, 천천히 깜빡이며 아래(세라)를 본다
	var ep: Vector2 = center[n / 2]
	var blink_t := fmod(t + idx * 1.37, 6.5)
	var open := 1.0
	if blink_t < 0.35:
		open = absf(blink_t - 0.175) / 0.175
	open *= 1.0 - close
	var look := (look_at - ep).normalized() + Vector2(sin(t * 0.4 + idx) * 0.3, 0)
	StArt.god_eye(c, ep, width * 0.38, open * (0.85 + 0.15 * sin(t + idx)), look, 0.0)
	if sealed and seal_k > 0.0:
		# 푸른 불 바늘땀
		for i in range(1, n, 2):
			var q0: Vector2 = left[i]
			var q1: Vector2 = right[i]
			c.draw_line(q0 + nrm * 3.0, q1 - nrm * 3.0, Color(StArt.FOX_CORE, 0.85 * seal_k), 1.0)
			StArt.foxfire(c, q0.lerp(q1, 0.5), 2.0, t + i, seal_k)


static func _falling_light(c, t: float, every: float, col: Color, top := 0.0, bottom := 300.0) -> void:
	for lane in 2:
		var tt := t + lane * every * 0.5
		var slot := floorf(tt / every)
		var lt := fmod(tt, every) / every
		var x := fmod(slot * 263.0 + lane * 171.0, 600.0) + 20.0
		var a := sin(lt * PI)
		var w := 3.0 + 6.0 * a
		c.draw_rect(Rect2(x - w * 2.0, top, w * 4.0, bottom - top), Color(col, 0.05 * a))
		c.draw_rect(Rect2(x - w * 0.5, top, w, bottom - top), Color(col, 0.18 * a))
		c.draw_rect(Rect2(x - 0.5, top, 1, bottom - top), Color(col, 0.6 * a))
		c.draw_circle(Vector2(x, bottom), 12.0 * a, Color(col, 0.2 * a))


# ─── 축제 ───────────────────────────────────────────────

static func _sky_festival(c, pal: Dictionary) -> void:
	_gradient(c, [[0.0, pal.sky_top], [0.45, Color("#3a2450")], [0.8, Color("#8a4a5a")], [1.0, Color("#d8805a")]])
	_starfield(c, 50, 21, 160.0, 0.7)
	# 초승달
	var mc := Vector2(118, 58)
	c.draw_circle(mc, 30, Color(1, 0.9, 0.75, 0.05))
	c.draw_circle(mc, 13, Color("#f6e6c8"))
	c.draw_circle(mc + Vector2(6, -4), 12, Color("#1c1636"))
	# 별 하나가 너무 가깝다 (오필리아의 복선) — 다른 별보다 크고 따뜻하게 떨린다
	var near_star := Vector2(498, 40)
	c.anim(Kit.bb_circle(near_star, 14.0), func(cv: CanvasItem, t: float) -> void:
		StArt.glow(cv, near_star, 14.0, StArt.STAR, 0.35 + 0.1 * sin(t * 3.0))
		StArt.sparkle(cv, near_star, 6.0, StArt.STAR, 0.7 + 0.3 * sin(t * 3.0)))
	# 불꽃놀이 (시간 칸마다 한 송이)
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		var cols := [Color("#ffd27a"), Color("#ff7a6a"), Color("#8ad0ff"), Color("#c8a0ff"), Color("#9aff9a")]
		for lane in 3:
			var period := 2.6 + lane * 0.7
			var tt := t + lane * 1.1
			var slot := floorf(tt / period)
			var lt := fmod(tt, period)
			var p := Vector2(fmod(slot * 197.0 + lane * 233.0, 520.0) + 60.0, 50.0 + fmod(slot * 83.0 + lane * 41.0, 80.0))
			var col: Color = cols[int(slot + lane) % cols.size()]
			if lt < 0.5:
				# 솟아오름
				var rise := p + Vector2(0, (0.5 - lt) * 220.0)
				cv.draw_line(rise, rise + Vector2(0, 8), Color(col, 0.6), 1.0)
			elif lt < 2.0:
				var k := (lt - 0.5) / 1.5
				var r := 6.0 + 30.0 * sqrt(k)
				for i in 16:
					var a := TAU * i / 16.0 + slot
					var q := p + Vector2(cos(a), sin(a)) * r + Vector2(0, k * k * 14.0)
					cv.draw_rect(Rect2(q, Vector2.ONE * (2 if k < 0.4 else 1)), Color(col, 1.0 - k))
					cv.draw_line(q, q - Vector2(cos(a), sin(a)) * 4.0, Color(col, (1.0 - k) * 0.4), 1.0)
				if k < 0.15:
					cv.draw_circle(p, 10.0, Color(col, 0.3)))


# ─── 침공 (폐허) ────────────────────────────────────────

static func _sky_ruin(c, pal: Dictionary, rise: bool) -> void:
	if rise:
		_gradient(c, [[0.0, pal.sky_top], [0.45, Color("#0e1a40")], [0.8, Color("#2a4a8a")], [1.0, Color("#7ab0e8")]])
	else:
		_gradient(c, [[0.0, pal.sky_top], [0.35, Color("#24121a")], [0.7, pal.sky_bottom], [1.0, Color("#e0603a")]])
	# 연기 덩어리 (위쪽, 천천히 흐름)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var sm: Array = [] ## [y, x0, speed, r]
	for i in 14:
		var y := rng.randf_range(-20, 120)
		var x0 := rng.randf() * 900.0
		var sp := rng.randf_range(3.0, 8.0)
		sm.append([y, x0, sp, rng.randf_range(40, 90)])
	var scol := Color(0.04, 0.03, 0.05, 0.45) if not rise else Color(0.02, 0.04, 0.1, 0.4)
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for e: Array in sm:
			var y: float = e[0]
			var x := fmod(float(e[1]) + t * float(e[2]), 900.0) - 130.0
			var r: float = e[3]
			cv.draw_circle(Vector2(x, y), r, scol)
			cv.draw_circle(Vector2(x + r * 0.6, y + r * 0.2), r * 0.7, scol))
	# 하늘의 균열과 눈 (반격이면 푸른 불로 꿰매는 정도 seal_k = 0.55 + 0.25 * sin(t * 0.5))
	var look := Vector2(320, 300)
	for cr in [[Vector2(80, -10), Vector2(220, 140), 101, 28.0, 0], [Vector2(340, -10), Vector2(300, 100), 113, 20.0, 1], [Vector2(580, -10), Vector2(460, 160), 127, 32.0, 2]]:
		var ca: Vector2 = cr[0]
		var cb: Vector2 = cr[1]
		var cs: int = cr[2]
		var cw: float = cr[3]
		var ci: int = cr[4]
		c.anim(_bb_crack(ca, cb, cw), func(cv: CanvasItem, t: float) -> void:
			var seal_k := 0.0
			if rise:
				seal_k = 0.55 + 0.25 * sin(t * 0.5)
			_sky_crack(cv, ca, cb, cs, cw, t, ci, look, rise, seal_k))
	if not rise:
		c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void: _falling_light(cv, t, 3.0, Color(1, 1, 1), 60.0, 250.0))
	else:
		# 푸른 오로라
		c.anim(Rect2(-10, 20, 670, 110), func(cv: CanvasItem, t: float) -> void:
			for i in 5:
				var y0 := 40.0 + i * 14.0
				var pts := PackedVector2Array()
				for k in 17:
					var x := k * 40.0
					pts.append(Vector2(x, y0 + sin(t * 0.6 + k * 0.5 + i) * 10.0))
				cv.draw_polyline(pts, Color(StArt.FOX_BLUE, 0.07), 10.0))
	# 지평선의 불빛 (깜빡임)
	var hz := Color(1.0, 0.45, 0.2) if not rise else Color(0.45, 0.75, 1.0)
	c.anim(Rect2(0, 300, 640, 60), func(cv: CanvasItem, t: float) -> void:
		cv.draw_rect(Rect2(0, 300, 640, 60), Color(hz, 0.12 + 0.04 * sin(t * 3.0)))
		cv.draw_rect(Rect2(0, 320, 640, 40), Color(hz, 0.1 + 0.05 * sin(t * 4.7))))


# ═══════════════════════════════════════════════════════════
# 시차 층
# ═══════════════════════════════════════════════════════════

## l = Pen (방 진입 때 한 번). 움직이는 것만 l.anim, 층 흔들기(땅울림)는 l.on_process
static func draw_layer(l, theme: String, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> bool:
	if not theme in MINE:
		return false
	var th: Dictionary = l.theme
	# 세로로 긴 방: 카메라가 맨 아래일 때 지평선·바닥이 화면 아래에 오도록 (Parallax2D 세로 배율 = 가로 배율 × 0.6 + 0.4, 전경 1.05)
	var rs: Vector2 = l.room_size
	var sc: float = l.scroll
	var sy := 1.05 if depth == 3 else sc * 0.6 + 0.4
	_bot_y = 360.0 + maxf(rs.y - 368.0, 0.0) * sy
	match theme:
		"star": _layer_star(l, th, depth, span, rng, t)
		"star_flip":
			l.draw_set_transform(Vector2(0, _bot_y), 0.0, Vector2(1, -1))
			_layer_star(l, th, depth, span, rng, t)
			l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"void": _layer_void(l, th, depth, span, rng, t)
		"sky": _layer_sky(l, th, depth, span, rng, t)
		"festival": _layer_festival(l, th, depth, span, rng, t)
		"st_kingdom", "st_elf", "st_temple", "st_garden": _layer_trial(l, theme, th, depth, span, rng, t)
		"dawn": _layer_dawn(l, th, depth, span, rng, t)
		_: _layer_ruin(l, theme, th, depth, span, rng, t)
	return true


static var _bot_y := 360.0


## 이 층에서 (카메라가 방 맨 아래일 때) 화면에 보이는 가장 아래 y. 1칸 높이 방에서 약 360, 세로로 긴 방은 그만큼 아래
static func _bot(_span: Vector2) -> float:
	return _bot_y


static func _layer_col(th: Dictionary, depth: int) -> Color:
	match depth:
		0: return th.far
		1: return th.mid
		2: return th.near
	return Color(0.02, 0.015, 0.03)


## 전경: 화면 아래 가장자리를 스치는 검은 덩어리 (+ 불씨)
static func _front_rubble(l, span: Vector2, rng: RandomNumberGenerator, _t: float, fire: Color, flames := true) -> void:
	var dark := Color(0.015, 0.012, 0.022, 0.94)
	var x := rng.randf_range(0, 260)
	while x < span.x:
		var w := rng.randf_range(70, 170)
		var h := rng.randf_range(18, 46)
		var bottom := _bot(span) + 14.0
		var pts := PackedVector2Array([Vector2(x, bottom)])
		var k := 0.0
		while k < 1.0:
			pts.append(Vector2(x + w * k, bottom - h * (0.4 + 0.6 * sin(k * PI)) * rng.randf_range(0.7, 1.0)))
			k += rng.randf_range(0.12, 0.25)
		pts.append(Vector2(x + w, bottom))
		l.draw_colored_polygon(pts, dark)
		# 비죽 나온 들보
		var bx := x + w * rng.randf_range(0.2, 0.8)
		l.draw_line(Vector2(bx, bottom - h * 0.6), Vector2(bx + rng.randf_range(-30, 30), bottom - h - rng.randf_range(10, 30)), dark, 5.0)
		if flames:
			for i in 3:
				var fx := x + w * (0.25 + i * 0.25)
				var fy := bottom - h * 0.7
				l.anim(Rect2(fx - 4, fy - 16, 8, 17), func(cv: CanvasItem, tt: float) -> void:
					var f := sin(tt * 9.0 + fx) * 2.0
					cv.draw_colored_polygon(PackedVector2Array([Vector2(fx - 4, fy), Vector2(fx + f, fy - 12 - 3.0 * sin(tt * 7.0 + i)), Vector2(fx + 4, fy)]), Color(fire, 0.55)))
		x += w + rng.randf_range(240, 480)


# ─── 별의 탑 층 ─────────────────────────────────────────

static func _layer_star(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	var col := _layer_col(th, depth)
	match depth:
		0:
			# 떠 있는 섬들과 그 사이를 잇는 별빛 다리 (섬이 오르내려 통째로 움직이는 요소)
			var isles: Array[Vector2] = []
			var x := rng.randf_range(20, 120)
			while x < span.x + 100:
				isles.append(Vector2(x, span.y * rng.randf_range(0.35, 0.62)))
				x += rng.randf_range(170, 260)
			for i in isles.size():
				var p0 := isles[i]
				var w := rng.randf_range(40, 70)
				var sh := rng.randf_range(30, 70)
				var q0: Vector2 = isles[i - 1] if i > 0 else p0
				var bb := Rect2(p0 - Vector2(w + 4, sh + 30), Vector2(w * 2 + 8, sh + 72))
				if i > 0:
					bb = bb.merge(Rect2(q0 + Vector2(26, -40), Vector2(8, 46)))
				l.anim(bb, func(cv: CanvasItem, tt: float) -> void:
					var p := p0 + Vector2(0, sin(tt * 0.5 + i) * 3.0)
					cv.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, 0), p + Vector2(w, 0), p + Vector2(w * 0.5, 16), p + Vector2(0, 36), p + Vector2(-w * 0.6, 14)]), col.lightened(0.05))
					# 작은 첨탑
					cv.draw_rect(Rect2(p.x - 7, p.y - sh, 14, sh), col.lightened(0.08))
					cv.draw_colored_polygon(PackedVector2Array([Vector2(p.x - 10, p.y - sh), Vector2(p.x, p.y - sh - 22), Vector2(p.x + 10, p.y - sh)]), col.lightened(0.1))
					cv.draw_rect(Rect2(p.x - 2, p.y - sh + 8, 4, 6), Color(StArt.STAR, 0.5 + 0.3 * StArt.twinkle(tt, i)))
					if i > 0:
						var q := q0 + Vector2(0, sin(tt * 0.5 + i - 1) * 3.0)
						_star_bridge(cv, q + Vector2(30, -2), p + Vector2(-30, -2), tt, i))
		1:
			# 천구의(오러리) 고리: 거대한 금 고리들과 그 위를 도는 행성
			var cx := span.x * 0.5
			var cy := span.y * 0.42
			for r in 3:
				var rx := 260.0 + r * 110.0
				var ry := 60.0 + r * 22.0
				var tilt := -0.12 + r * 0.1
				var pts := PackedVector2Array()
				for i in 49:
					var a := TAU * i / 48.0
					pts.append(Vector2(cx, cy) + Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt))
				l.draw_polyline(pts, Color("#8a7a4a", 0.35), 3.0)
				l.draw_polyline(pts, Color("#e8d08a", 0.22), 1.0)
				var pr := 7.0 + r * 3.0
				var pcol := [Color("#6a7ae8"), Color("#e89a6a"), Color("#9ae8c8")][r] as Color
				var orbit := Rect2(cx - rx, cy - ry - rx * 0.25, rx * 2.0, ry * 2.0 + rx * 0.5).grow(pr + 4.0)
				for j in 2:
					l.anim(orbit, func(cv: CanvasItem, tt: float) -> void:
						var a2 := tt * (0.12 - r * 0.03) * (1 if j == 0 else -1) + j * PI + r
						var pp := Vector2(cx, cy) + Vector2(cos(a2) * rx, sin(a2) * ry).rotated(tilt)
						cv.draw_circle(pp, pr + 3.0, Color(pcol, 0.15))
						cv.draw_circle(pp, pr, pcol.darkened(0.35))
						cv.draw_circle(pp + Vector2(-pr * 0.25, -pr * 0.25), pr * 0.7, pcol.darkened(0.1)))
			# 가운데 거대한 별 (탑의 심장)
			l.anim(Kit.bb_circle(Vector2(cx, cy), 40.0), func(cv: CanvasItem, tt: float) -> void:
				StArt.glow(cv, Vector2(cx, cy), 40.0, StArt.STAR, 0.25 + 0.05 * sin(tt * 2.0))
				StArt.star(cv, Vector2(cx, cy), 9.0, Color(StArt.STAR, 0.7), -PI * 0.5 + tt * 0.1))
		2:
			# 별자리가 새겨진 기둥과 아치, 매달린 별 등롱
			var x := rng.randf_range(0, 200)
			while x < span.x:
				var w := 30.0
				l.draw_rect(Rect2(x, -20, w, span.y + 40), col)
				l.draw_rect(Rect2(x + 3, -20, 2, span.y + 40), col.lightened(0.06))
				l.draw_rect(Rect2(x - 6, span.y * 0.12, w + 12, 8), col.lightened(0.05))
				# 기둥의 별자리 상감
				var pts: Array = []
				var y := span.y * 0.22
				for i in 5:
					pts.append(Vector2(x + 8 + rng.randf_range(0, 14), y))
					y += rng.randf_range(24, 40)
				var px := x
				l.anim(Rect2(x + 4, span.y * 0.22 - 4, 26, y - span.y * 0.22 + 8), func(cv: CanvasItem, tt: float) -> void: StArt.constellation(cv, pts, Color("#e8cf86"), 0.35 + 0.3 * StArt.twinkle(tt, px)))
				# 아치
				var arch := PackedVector2Array()
				var aw := 150.0
				for i in 13:
					var a := PI + PI * i / 12.0
					arch.append(Vector2(x + w + aw * 0.5 + cos(a) * aw * 0.5, span.y * 0.16 + sin(a) * 50.0))
				l.draw_polyline(arch, col, 9.0)
				# 등롱
				var lx := x + w + aw * 0.5 + rng.randf_range(-30, 30)
				var ll := rng.randf_range(40, 110)
				l.draw_line(Vector2(lx, span.y * 0.12), Vector2(lx, span.y * 0.12 + ll), col.lightened(0.1), 1.0)
				var lx0 := x
				var ly := span.y * 0.12 + ll + 8
				l.anim(Kit.bb_circle(Vector2(lx, ly), 18.0), func(cv: CanvasItem, tt: float) -> void:
					var lp := Vector2(lx + sin(tt * 1.3 + lx0) * 1.5, ly)
					StArt.glow(cv, lp, 16.0, StArt.STAR, 0.22)
					StArt.star(cv, lp, 5.0, StArt.STAR_GOLD, -PI * 0.5 + sin(tt + lx0) * 0.2))
				x += w + aw + rng.randf_range(60, 200)
		3:
			_front_rubble(l, span, rng, t, StArt.STAR, false)


static func _star_bridge(l, a: Vector2, b: Vector2, t: float, i: int) -> void:
	var mid := (a + b) * 0.5 + Vector2(0, -28)
	var pts := PackedVector2Array()
	for k in 17:
		var u := float(k) / 16.0
		pts.append(a.lerp(mid, u).lerp(mid.lerp(b, u), u))
	l.draw_polyline(pts, Color(StArt.STAR, 0.12), 5.0)
	l.draw_polyline(pts, Color(StArt.STAR, 0.4), 1.0)
	for k in range(0, 17, 3):
		var tw := StArt.twinkle(t, i * 17 + k)
		l.draw_rect(Rect2(pts[k] - Vector2(1, 1), Vector2(2, 2)), Color(StArt.STAR_CORE, 0.4 + 0.6 * tw))
	# 다리를 따라 흐르는 빛
	var flow := int(fmod(t * 6.0 + i * 3.0, 17.0))
	l.draw_circle(pts[flow], 2.5, Color(StArt.STAR, 0.7))


# ─── 어둠 층 ────────────────────────────────────────────

static func _layer_void(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	match depth:
		0:
			# 아주 희미한 아홉 꼬리 그림자 (너울이 거기 있다) — 꼬리가 흔들려 통째로 움직이는 요소
			var c := Vector2(span.x * 0.5, _bot(span) - 20.0)
			l.anim(Kit.bb_circle(c, 312.0), func(cv: CanvasItem, tt: float) -> void:
				for i in 9:
					# 털이 풍성한 꼬리: 휘어진 길을 따라 커지는 원들 (끝으로 갈수록 굵다가 뾰족)
					var a := -PI * 0.5 + (i - 4) * 0.26 + sin(tt * 0.35 + i) * 0.05
					var bend := (i - 4) * 0.05 + sin(tt * 0.5 + i * 1.3) * 0.08
					for k in 16:
						var u := float(k) / 15.0
						var aa := a + bend * u * u * 3.0
						var rr := 40.0 + u * 230.0
						var p := c + Vector2(cos(aa) * rr, sin(aa) * rr * 0.9)
						var rad := (6.0 + 26.0 * sin(u * PI * 0.92)) * (1.0 - u * 0.25)
						cv.draw_circle(p, rad, Color(0.07, 0.12, 0.26, 0.09))
						if k == 15:
							StArt.foxfire(cv, p, 4.0, tt + i, 0.25 + 0.15 * sin(tt + i)))
		1:
			# 천천히 떠오르는 푸른 여우불 등롱
			var sy := span.y
			for i in 14:
				var x := rng.randf() * span.x
				var sp := rng.randf_range(5.0, 11.0)
				var y0 := rng.randf() * span.y
				var fr := rng.randf_range(2.0, 3.5)
				l.anim(Rect2(x - 8 - fr * 1.6, -40 - fr * 2.0, 16 + fr * 3.2, sy + 80 + fr * 4.0), func(cv: CanvasItem, tt: float) -> void:
					var y := sy + 40.0 - fmod(tt * sp + y0, sy + 80.0)
					StArt.foxfire(cv, Vector2(x + sin(tt * 0.7 + i) * 8.0, y), fr, tt + i, 0.45))
		2:
			# 바닥의 물거울: 가로 물결선
			var fy := _bot(span) - 56.0
			var sx := span.x
			l.anim(Rect2(-22, fy - 4, sx + 46, 50), func(cv: CanvasItem, tt: float) -> void:
				for i in 6:
					var y := fy + i * 7.0
					var pts := PackedVector2Array()
					var x := -20.0
					while x < sx + 20:
						pts.append(Vector2(x, y + sin(tt * 0.8 + x * 0.02 + i) * 1.5))
						x += 24.0
					cv.draw_polyline(pts, Color(StArt.FOX_BLUE, 0.05 + 0.02 * i), 1.0))
		3:
			pass


# ─── 하늘의 문 층 ───────────────────────────────────────

static func _layer_sky(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	match depth:
		0:
			# 아래 구름 바다(위에서 흰 빛을 받음) + 구름을 뚫고 선 거신들의 머리·어깨 + 구름 틈의 불빛(불타는 세상)
			var cy := _bot(span) - 70.0
			var pal := StColossusArt.palette(0.35, 1.0, Color("#3a384a"))
			for i in 5:
				var gx := rng.randf_range(0, span.x)
				var gh := rng.randf_range(380, 520)
				var foot := Vector2(gx, cy + gh * 0.55)
				# 거신의 걸음은 실제 시각(march_clock)이라 t와 무관하게 움직인다
				l.anim(_bb_giant(foot, gh), func(cv: CanvasItem, _tt: float) -> void:
					var ph := fmod(march_clock() / (MARCH_PERIOD * 1.6) + i * 0.31, 1.0)
					StColossusArt.draw_giant(cv, foot, gh, ph, -1.0 if i % 2 == 0 else 1.0, pal, 1))
			var cloud := Color(th.far)
			for row in 3:
				var yy := cy + row * 16.0
				var x := -120.0 + row * 30.0
				var k := 0
				while x < span.x + 120:
					var r := 30.0 + 18.0 * sin(k * 1.9 + row) + rng.randf_range(0, 12)
					var cc := cloud.darkened(0.08 * row + 0.1)
					var cx := x
					var ck := k
					l.anim(Rect2(x - r - 8, yy - r - 2, r * 2 + 16, r * 2 + 12), func(cv: CanvasItem, tt: float) -> void:
						var drift := sin(tt * 0.15 + ck + row) * 6.0
						cv.draw_circle(Vector2(cx + drift, yy + 8.0), r, cc.darkened(0.25))
						cv.draw_circle(Vector2(cx + drift, yy), r, cc)
						cv.draw_circle(Vector2(cx + drift - r * 0.3, yy - r * 0.35), r * 0.55, cc.lightened(0.12)))
					x += r * 1.3
					k += 1
			for i in 5:
				var hx := rng.randf_range(0, span.x)
				l.anim(Kit.bb_circle(Vector2(hx, cy + 40), 26.0), func(cv: CanvasItem, tt: float) -> void:
					cv.draw_circle(Vector2(hx, cy + 40), 26, Color(1.0, 0.45, 0.25, 0.22 + 0.1 * sin(tt * 2.0 + i))))
			l.draw_rect(Rect2(-100, cy + 46, span.x + 200, span.y), cloud.darkened(0.3))
		1:
			# 떠다니는 세계의 조각: 학교 탑·성벽·가지·기둥이 천천히 떠오른다
			var x := rng.randf_range(0, 160)
			var k := 0
			var dcol := Color(th.mid)
			while x < span.x:
				var b0 := Vector2(x, _bot(span) * rng.randf_range(0.3, 0.72))
				var dk := k
				l.anim(Rect2(b0.x - 42, b0.y - 18 - 88, 96, 88 + 18 + 34), func(cv: CanvasItem, tt: float) -> void:
					_debris(cv, Vector2(b0.x, b0.y - fmod(tt * 4.0 + dk * 30.0, 60.0) * 0.3), dk % 4, dcol))
				x += rng.randf_range(170, 290)
				k += 1
		2:
			# 흰 기하학 파편 (천천히 돈다)
			var bot := _bot(span)
			for i in 10:
				var p := Vector2(rng.randf() * span.x, rng.randf() * bot * 0.85)
				var s := rng.randf_range(5, 13)
				var w := rng.randf_range(-0.4, 0.4)
				l.anim(Kit.bb_circle(p, s + 2.0), func(cv: CanvasItem, tt: float) -> void:
					var a := tt * w + i
					var tri := PackedVector2Array()
					for j in 3:
						tri.append(p + Vector2(cos(a + TAU * j / 3.0), sin(a + TAU * j / 3.0)) * s)
					cv.draw_colored_polygon(tri, Color(0.92, 0.92, 1.0, 0.5))
					cv.draw_polyline(tri + PackedVector2Array([tri[0]]), Color(1, 1, 1, 0.7), 1.0))
		3:
			pass


## 걷는 거신 하나(StColossusArt.draw_giant, 발 위치 고정)의 bbox
static func _bb_giant(foot: Vector2, h: float) -> Rect2:
	return Rect2(foot.x - h * 0.6, foot.y - h * 1.15, h * 1.2, h * 1.25 + 10.0)


## 떠다니는 조각 (0 학교 탑, 1 성벽, 2 세계수 가지, 3 신전 기둥)
static func _debris(l, p: Vector2, kind: int, col: Color) -> void:
	var rock := col.darkened(0.15)
	l.draw_colored_polygon(PackedVector2Array([p + Vector2(-34, 0), p + Vector2(34, 0), p + Vector2(18, 18), p + Vector2(0, 30), p + Vector2(-20, 16)]), rock)
	match kind:
		0:
			l.draw_rect(Rect2(p.x - 10, p.y - 60, 20, 60), col)
			l.draw_colored_polygon(PackedVector2Array([Vector2(p.x - 14, p.y - 60), Vector2(p.x, p.y - 84), Vector2(p.x + 6, p.y - 70), Vector2(p.x + 14, p.y - 60)]), col.lightened(0.05))
			l.draw_rect(Rect2(p.x - 3, p.y - 46, 6, 8), Color(1.0, 0.6, 0.3, 0.5))
		1:
			l.draw_rect(Rect2(p.x - 30, p.y - 26, 60, 26), col)
			for i in 4:
				l.draw_rect(Rect2(p.x - 30 + i * 16, p.y - 34, 9, 8), col)
		2:
			l.draw_line(p + Vector2(-30, -6), p + Vector2(40, -40), col.darkened(0.1), 7.0)
			l.draw_line(p + Vector2(10, -24), p + Vector2(20, -52), col.darkened(0.1), 4.0)
			l.draw_circle(p + Vector2(40, -44), 12, Color(0.35, 0.3, 0.25, 0.8))
		_:
			l.draw_rect(Rect2(p.x - 8, p.y - 70, 16, 70), col.lightened(0.15))
			l.draw_rect(Rect2(p.x - 12, p.y - 74, 24, 6), col.lightened(0.2))
			l.draw_line(Vector2(p.x - 8, p.y - 40), Vector2(p.x + 8, p.y - 30), col.darkened(0.2), 1.0)


# ─── 축제 층 ────────────────────────────────────────────

static func _layer_festival(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	var col := _layer_col(th, depth)
	match depth:
		0:
			# 불 켜진 학교 실루엣 + 탑 사이 등불 줄 + 깃발
			var cx := span.x * 0.5
			var by := _bot(span) - 30.0
			l.draw_rect(Rect2(cx - 260, by - 110, 520, 200), col)
			var towers := [[-220, 170, 24], [-130, 220, 30], [-40, 290, 40], [60, 250, 32], [150, 200, 28], [230, 150, 22]]
			var tops: Array[Vector2] = []
			for tw in towers:
				var tx: float = cx + tw[0]
				var h: float = tw[1]
				var w: float = tw[2]
				l.draw_rect(Rect2(tx - w * 0.5, by - h, w, h), col)
				l.draw_colored_polygon(PackedVector2Array([Vector2(tx - w * 0.7, by - h), Vector2(tx, by - h - w * 1.4), Vector2(tx + w * 0.7, by - h)]), col)
				tops.append(Vector2(tx, by - h + 6))
				for wi in 3:
					var wr := Rect2(tx - 3, by - h + 22 + wi * 24, 6, 9)
					l.anim(wr, func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(wr, Color(1.0, 0.8, 0.45, 0.65 + 0.2 * StArt.twinkle(tt, tx + wi))))
				# 깃발
				var fy := by - h - w * 1.4
				l.anim(Rect2(tx, fy - 2, 13, 12), func(cv: CanvasItem, tt: float) -> void:
					var fl := sin(tt * 2.0 + tx) * 2.0
					cv.draw_colored_polygon(PackedVector2Array([Vector2(tx, fy), Vector2(tx + 12, fy + 3 + fl), Vector2(tx, fy + 7)]), Color("#c8484a").darkened(0.3)))
			for i in range(1, tops.size()):
				_anim_lantern_string(l, tops[i - 1], tops[i], 24.0, i, 0.6)
		1:
			# 천막과 노점 실루엣, 사이사이 등불 줄
			var x := rng.randf_range(0, 120)
			var prev := Vector2(-40, _bot(span) - 120.0)
			var i := 0
			while x < span.x + 60:
				var by := _bot(span) - 24.0
				var w := rng.randf_range(60, 90)
				var h := rng.randf_range(50, 70)
				l.draw_rect(Rect2(x - w * 0.5, by - h * 0.5, w, h), col)
				l.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.6, by - h * 0.5), Vector2(x, by - h * 1.1), Vector2(x + w * 0.6, by - h * 0.5)]), col.lightened(0.04))
				l.draw_rect(Rect2(x - w * 0.35, by - h * 0.35, w * 0.7, h * 0.3), Color(1.0, 0.7, 0.4, 0.28))
				var top := Vector2(x, by - h * 1.1)
				_anim_lantern_string(l, prev, top, 30.0, i, 0.5)
				prev = top
				x += w + rng.randf_range(60, 140)
				i += 1
			l.draw_rect(Rect2(-100, _bot(span) + 6.0, span.x + 200, span.y), col)
		2:
			# 가까운 나무들 + 화환
			var base_y := _bot(span) - 6.0
			for i in int(span.x / 160) + 2:
				var tx := i * 160.0 + rng.randf_range(-30, 30)
				var r := rng.randf_range(30, 46)
				l.draw_rect(Rect2(tx - 4, base_y - r, 8, r + 60), col)
				l.draw_circle(Vector2(tx, base_y - r * 1.5), r, col)
				l.draw_circle(Vector2(tx - r * 0.6, base_y - r), r * 0.7, col)
				# 나무에 감긴 작은 등
				var ty := base_y - r * 1.5
				l.anim(Rect2(tx - r * 0.7 - 1, ty - r * 0.5 - 1, r * 1.4 + 4, r + 4), func(cv: CanvasItem, tt: float) -> void:
					for j in 5:
						var a := float(j) / 5.0 * TAU + tt * 0.2
						var p := Vector2(tx + cos(a) * r * 0.7, ty + sin(a) * r * 0.5)
						cv.draw_rect(Rect2(p, Vector2(2, 2)), Color(1.0, 0.85, 0.5, 0.4 + 0.5 * StArt.twinkle(tt, i * 5 + j))))
		3:
			var dark := Color(0.015, 0.012, 0.025, 0.92)
			var x := rng.randf_range(0, 300)
			while x < span.x:
				var w := rng.randf_range(60, 140)
				var h := rng.randf_range(16, 40)
				var bottom := _bot(span) + 14.0
				l.draw_circle(Vector2(x + w * 0.3, bottom - h * 0.4), h, dark)
				l.draw_circle(Vector2(x + w * 0.7, bottom - h * 0.2), h * 0.8, dark)
				x += w + rng.randf_range(260, 520)


## _lantern_string을 Pen에 움직이는 요소로
static func _anim_lantern_string(l, a: Vector2, b: Vector2, sag: float, seed: int, alpha := 1.0) -> void:
	l.anim(Rect2(a, Vector2.ZERO).expand(b).grow_individual(7, 7, 7, sag + 12.0), func(cv: CanvasItem, tt: float) -> void: _lantern_string(cv, a, b, sag, tt, seed, alpha))


## 늘어진 줄에 매단 등불들
static func _lantern_string(l, a: Vector2, b: Vector2, sag: float, t: float, seed: int, alpha := 1.0) -> void:
	var pts := PackedVector2Array()
	for k in 13:
		var u := float(k) / 12.0
		pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * sag))
	l.draw_polyline(pts, Color(0.1, 0.07, 0.1, alpha), 1.0)
	var cols := [Color("#ff9a5a"), Color("#ffd27a"), Color("#ff6a7a"), Color("#8ad0ff")]
	for k in range(1, 12, 2):
		var p: Vector2 = pts[k] + Vector2(sin(t * 1.5 + k + seed) * 1.0, 3)
		var c: Color = cols[(k + seed) % cols.size()]
		l.draw_circle(p, 5.0, Color(c, 0.12 * alpha))
		l.draw_rect(Rect2(p - Vector2(1.5, 2), Vector2(3, 4)), Color(c, alpha))


# ─── 폐허 층 (침공) ─────────────────────────────────────

static func _layer_ruin(l, theme: String, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	var col := _layer_col(th, depth)
	var rise := theme == "rise"
	var fire := StArt.RUIN_FIRE if not rise else StArt.FOX_BLUE
	var glow_col := Color(1.0, 0.42, 0.18) if not rise else Color(0.4, 0.7, 1.0)
	# 땅울림: 중간 층 거신의 발이 닿을 때 층이 살짝 튄다 (예전엔 _draw 안에서 바꿨다 → 이제 매 프레임 _process)
	var k1 := 1.0 if depth == 0 else (2.0 if depth == 1 else 0.0)
	var k2 := 0.4 if rise else 1.0
	l.on_process(func(n: Node2D, _tt: float) -> void:
		var since := fmod(march_clock() / MARCH_PERIOD + 0.75, 0.5) * MARCH_PERIOD # 마지막 착지 뒤 지난 초
		var jolt := maxf(0.0, 1.0 - since / 0.35)
		n.position.y = jolt * k1 * k2)
	# 거신의 걸음(march_clock)은 실제 시각이라 t와 무관하게 움직인다
	match depth:
		0:
			var hy := _bot(span) - 66.0
			# 지평선을 메운 거신의 행렬 (도시보다 크다). 안개에 묻혀 흐릿하게, 발은 불빛에 잠긴다
			var pal := StColossusArt.palette(0.5, 1.0, Color("#4e4a5a") if not rise else Color("#3a4a72"), 0.55 if rise else 0.0)
			var n := 7 + int(span.x / 500.0)
			var gs: Array = [] ## [gh, per, off, x0]
			for i in n:
				var gh := rng.randf_range(210, 300)
				var per := MARCH_PERIOD * rng.randf_range(1.2, 1.55)
				var off := rng.randf()
				gs.append([gh, per, off, float(i) / n * (span.x + 400.0) + rng.randf_range(-40, 40)])
			var sx_all := span.x
			l.anim(Rect2(-200 - 300 * 0.6, hy + 10 - 300 * 1.15, span.x + 400 + 300 * 1.2, 300 * 1.25 + 20), func(cv: CanvasItem, tt: float) -> void:
				var mt := march_clock()
				for i in gs.size():
					var g: Array = gs[i]
					var gh: float = g[0]
					var per: float = g[1]
					var sp := gh * 0.68 / per * 0.45 * (0.3 if rise else 1.0)
					var x := fposmod(float(g[3]) - mt * sp, sx_all + 400.0) - 200.0
					var r := StColossusArt.draw_giant(cv, Vector2(x, hy + 10), gh, fmod(mt / per + float(g[2]), 1.0), -1.0, pal, 1)
					if rise:
						_giant_blue_fire(cv, Vector2(x, hy), gh, tt, i, 0.55)
					else:
						# 틈 사이로 새는 흰빛
						var sp2: Vector2 = r.slit
						cv.draw_circle(sp2, 3.0, Color(1, 1, 1, 0.25)))
			# 불빛이 거신의 다리를 아래에서 물들인다
			for b in 6:
				var y0 := hy - 90.0 + b * 16.0
				l.draw_rect(Rect2(-100, y0, span.x + 200, 16), Color(glow_col, 0.035 + b * 0.022))
			# 불타는 지평선 실루엣 (지역별)
			_far_skyline(l, theme, span, hy, col, rng, fire)
			# 지평선 불길
			for i in int(span.x / 40) + 2:
				var fx := i * 40.0 + rng.randf_range(-10, 10)
				var fh0 := rng.randf_range(8, 22)
				l.anim(Rect2(fx - 14, hy - fh0 * 1.25 - 1, 28, fh0 * 1.25 + 6), func(cv: CanvasItem, tt: float) -> void:
					var fh := fh0 * (1.0 + 0.25 * sin(tt * 3.0 + i))
					cv.draw_colored_polygon(PackedVector2Array([Vector2(fx - 14, hy + 4), Vector2(fx, hy - fh), Vector2(fx + 14, hy + 4)]), Color(fire, 0.35)))
			l.draw_rect(Rect2(-100, hy + 2, span.x + 200, span.y), col)
			# 솟는 연기 기둥
			for i in 4:
				var sx := rng.randf_range(0, span.x)
				l.anim(Rect2(sx - 70, hy - 232, 140, 244), func(cv: CanvasItem, tt: float) -> void:
					for k in 7:
						var yy := hy - k * 26.0 - fmod(tt * 6.0, 26.0)
						cv.draw_circle(Vector2(sx + sin(tt * 0.3 + k + i) * (4.0 + k * 3.0), yy), 10.0 + k * 6.0, Color(0.05, 0.04, 0.06, 0.24 - k * 0.03)))
		1:
			# 바로 뒤를 지나는 거신: 화면보다 훨씬 커서 다리만 보인다. 걸음마다 흙먼지
			var fy := _bot(span) + 30.0
			var pal2 := StColossusArt.palette(0.74, 1.0, Color("#2a2228") if not rise else Color("#1c2a4a"), 0.65 if rise else 0.0)
			var n2 := 1 + int(span.x / 900.0)
			var sx_all := span.x
			for i in n2:
				var gh := rng.randf_range(980, 1150)
				var off := 0.0 if i % 2 == 0 else 0.5
				var x0 := rng.randf_range(0, span.x + 900)
				l.anim(Rect2(-500 - gh * 0.6, fy - gh * 1.15, span.x + 1000 + gh * 1.2, gh * 1.25 + 80), func(cv: CanvasItem, tt: float) -> void:
					var mt := march_clock()
					var sp := gh * 0.68 / MARCH_PERIOD * 0.3 * (0.3 if rise else 1.0)
					var x := fposmod(x0 - mt * sp, sx_all + 1000.0) - 500.0
					var ph := fmod(mt / MARCH_PERIOD + off, 1.0)
					var r := StColossusArt.draw_giant(cv, Vector2(x, fy), gh, ph, -1.0, pal2, 1)
					var strike := fmod(ph + 0.75, 0.5) # 0 = 막 닿음
					if strike < 0.14:
						var fp: Vector2 = r.foot_front if fmod(ph, 1.0) < 0.5 else r.foot_back
						var k := strike / 0.14
						for j in 7:
							cv.draw_circle(fp + Vector2((j - 3) * 26.0 * (0.5 + k), -10.0 - k * 26.0), 16.0 + k * 30.0, Color(0.16, 0.13, 0.15, 0.5 * (1.0 - k)))
					if rise:
						_giant_blue_fire(cv, Vector2(x, fy), gh, tt, i + 7, 0.9))
			# 연기 띠가 거신의 몸을 가린다 (깊이감)
			var bot := _bot(span)
			l.anim(Rect2(-372, bot * 0.2 - 78, span.x + 744, bot * 0.4 + 156), func(cv: CanvasItem, tt: float) -> void:
				for b in 3:
					var by := bot * (0.2 + b * 0.2) + sin(tt * 0.2 + b) * 6.0
					var bx := fposmod(tt * (6.0 + b * 3.0), 300.0) - 300.0
					while bx < sx_all + 300:
						cv.draw_circle(Vector2(bx, by), 70.0, Color(0.06, 0.045, 0.06, 0.18) if not rise else Color(0.03, 0.06, 0.14, 0.18))
						bx += 110.0)
			l.draw_rect(Rect2(-100, _bot(span) - 14.0, span.x + 200, span.y), col)
		2:
			_near_ruins(l, theme, span, col, rng, fire)
		3:
			_front_rubble(l, span, rng, t, fire)


## 반격: 거신의 몸을 타고 오르는 푸른 여우불
static func _giant_blue_fire(l, foot: Vector2, h: float, t: float, seed: int, a: float) -> void:
	for i in 7:
		var y := foot.y - h * (0.08 + i * 0.11)
		var x := foot.x + sin(seed * 3.1 + i * 1.7) * h * 0.06
		StArt.foxfire(l, Vector2(x, y), h * 0.012 + 2.0, t + i + seed, a * (0.55 + 0.45 * sin(t * 2.0 + i)))


## 먼 지평선 실루엣 (지역별), 창문은 불빛
static func _far_skyline(l, theme: String, span: Vector2, hy: float, col: Color, rng: RandomNumberGenerator, fire: Color) -> void:
	var c2 := col.lightened(0.03)
	match theme:
		"ruin_kingdom":
			# 성벽 + 대성당 돔(무너짐) + 집들
			l.draw_rect(Rect2(-100, hy - 40, span.x + 200, 44), c2)
			var x := -40.0
			while x < span.x + 40:
				l.draw_rect(Rect2(x, hy - 50, 12, 10), c2)
				x += 24.0
			var dc := Vector2(span.x * 0.55, hy - 40)
			l.draw_arc(dc + Vector2(0, -50), 50, PI, TAU * 0.9, 16, c2, 26.0)
			l.draw_rect(Rect2(dc.x - 50, dc.y - 50, 100, 50), c2)
			for i in 6:
				var hx := rng.randf_range(0, span.x)
				l.draw_colored_polygon(PackedVector2Array([Vector2(hx - 20, hy - 40), Vector2(hx, hy - 64), Vector2(hx + 14, hy - 52), Vector2(hx + 20, hy - 40)]), c2)
				l.draw_rect(Rect2(hx - 3, hy - 36, 5, 6), Color(fire, 0.55))
		"ruin_elf":
			# 불타는 세계수: 거대한 줄기와 타오르는 수관
			var tx := span.x * 0.5
			l.draw_colored_polygon(PackedVector2Array([Vector2(tx - 60, hy), Vector2(tx - 30, hy - 160), Vector2(tx - 18, hy - 240), Vector2(tx + 18, hy - 240), Vector2(tx + 34, hy - 160), Vector2(tx + 66, hy)]), c2)
			for i in 9:
				var a := -PI * 0.5 + (i - 4) * 0.32
				var cp := Vector2(tx, hy - 240) + Vector2(cos(a) * 150.0, sin(a) * 70.0)
				l.draw_line(Vector2(tx, hy - 230), cp, c2, 8.0)
				l.draw_circle(cp, 40.0, c2)
				l.anim(Kit.bb_circle(cp + Vector2(0, -10), 30.0), func(cv: CanvasItem, tt: float) -> void:
					cv.draw_circle(cp + Vector2(0, -10), 26.0 + 4.0 * sin(tt * 2.0 + i), Color(fire, 0.25)))
			for i in 12:
				var fx := tx + rng.randf_range(-170, 170)
				var fy := hy - 240 + rng.randf_range(-60, 40)
				l.anim(Rect2(fx - 8, fy - 19, 16, 20), func(cv: CanvasItem, tt: float) -> void:
					cv.draw_colored_polygon(PackedVector2Array([Vector2(fx - 8, fy), Vector2(fx + sin(tt * 5.0 + i) * 3.0, fy - 18), Vector2(fx + 8, fy)]), Color(fire, 0.45)))
		"ruin_temple":
			# 성산 + 부러진 첨탑
			var mx := span.x * 0.5
			l.draw_colored_polygon(PackedVector2Array([Vector2(mx - 360, hy), Vector2(mx - 60, hy - 170), Vector2(mx + 40, hy - 150), Vector2(mx + 380, hy)]), c2)
			l.draw_rect(Rect2(mx - 30, hy - 230, 50, 80), c2)
			l.draw_colored_polygon(PackedVector2Array([Vector2(mx - 30, hy - 230), Vector2(mx - 4, hy - 262), Vector2(mx + 4, hy - 240), Vector2(mx + 20, hy - 230)]), c2)
			l.draw_rect(Rect2(mx - 10, hy - 210, 8, 10), Color(fire, 0.6))
			l.draw_circle(Vector2(mx - 6, hy - 205), 18, Color(fire, 0.15))
		_:
			# 마녀학교: 탑들 (시계탑은 꼭대기가 부러짐), 창문마다 불길
			var cx := span.x * 0.5
			l.draw_rect(Rect2(cx - 240, hy - 90, 480, 92), c2)
			var towers := [[-200, 150, 24, false], [-110, 200, 30, false], [-20, 260, 40, true], [80, 210, 32, false], [170, 160, 24, false]]
			for tw in towers:
				var tx: float = cx + tw[0]
				var h: float = tw[1]
				var w: float = tw[2]
				var broken: bool = tw[3]
				l.draw_rect(Rect2(tx - w * 0.5, hy - h, w, h), c2)
				if broken:
					l.draw_colored_polygon(PackedVector2Array([Vector2(tx - w * 0.5, hy - h), Vector2(tx - w * 0.2, hy - h - 26), Vector2(tx + w * 0.1, hy - h - 8), Vector2(tx + w * 0.5, hy - h - 18), Vector2(tx + w * 0.5, hy - h)]), c2)
					l.draw_circle(Vector2(tx, hy - h + 30), 14, Color(c2.lightened(0.05)))
				else:
					l.draw_colored_polygon(PackedVector2Array([Vector2(tx - w * 0.7, hy - h), Vector2(tx, hy - h - w * 1.4), Vector2(tx + w * 0.7, hy - h)]), c2)
				for wi in 3:
					var wr := Rect2(tx - 3, hy - h + 20 + wi * 24, 6, 9)
					l.anim(wr, func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(wr, Color(fire, 0.45 + 0.3 * sin(tt * 4.0 + tx + wi))))


## 가까운 층: 무너진 구조물(지역별) + 불길 + 그 뒤의 불빛
static func _near_ruins(l, theme: String, span: Vector2, col: Color, rng: RandomNumberGenerator, fire: Color) -> void:
	var by := _bot(span) + 8.0
	var x := rng.randf_range(0, 160)
	var k := 0
	var glass := fire if fire == StArt.FOX_BLUE else Color(1.0, 0.55, 0.25)
	while x < span.x + 40:
		var w := rng.randf_range(80, 140)
		var h := rng.randf_range(100, 190)
		var bk := k
		# 뒤의 불빛
		var gpos := Vector2(x + w * 0.5, by - h * 0.4)
		var gr := h * 0.6
		l.anim(Kit.bb_circle(gpos, gr), func(cv: CanvasItem, tt: float) -> void: cv.draw_circle(gpos, gr, Color(fire, 0.06 + 0.02 * sin(tt * 3.0 + bk))))
		match theme:
			"ruin_kingdom":
				# 반쯤 무너진 집: 붉은 지붕 일부와 굴뚝, 불 꺼진 창
				l.draw_colored_polygon(PackedVector2Array([Vector2(x, by), Vector2(x, by - h * 0.6), Vector2(x + w * 0.4, by - h * 0.85), Vector2(x + w * 0.55, by - h * 0.7), Vector2(x + w * 0.7, by - h * 0.5), Vector2(x + w, by - h * 0.45), Vector2(x + w, by)]), col)
				l.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, by - h * 0.6), Vector2(x + w * 0.4, by - h * 0.9), Vector2(x + w * 0.45, by - h * 0.8), Vector2(x, by - h * 0.5)]), Color("#3a1a18"))
				l.draw_rect(Rect2(x + w * 0.15, by - h * 0.95, 10, h * 0.3), col)
				var wr := Rect2(x + w * 0.3, by - h * 0.4, 12, 16)
				l.anim(wr, func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(wr, Color(glass, 0.35 + 0.15 * sin(tt * 5.0 + bk))))
			"ruin_elf":
				# 부러진 가지와 타 버린 오두막
				l.draw_line(Vector2(x, by), Vector2(x + w * 0.3, by - h), col, 14.0)
				l.draw_line(Vector2(x + w * 0.3, by - h * 0.6), Vector2(x + w, by - h * 0.8), col, 8.0)
				l.draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.4, by), Vector2(x + w * 0.4, by - h * 0.35), Vector2(x + w * 0.7, by - h * 0.55), Vector2(x + w, by - h * 0.35), Vector2(x + w, by)]), col)
				l.draw_circle(Vector2(x + w * 0.7, by - h * 0.2), 6.0, Color(glass, 0.4))
			"ruin_temple":
				# 부러진 흰 기둥(세로 홈) + 기울어진 들보
				for ci in 2:
					var cx := x + ci * w * 0.6
					var ch := h * (1.0 - ci * 0.35)
					l.draw_rect(Rect2(cx, by - ch, 24, ch), col)
					for g in 3:
						l.draw_line(Vector2(cx + 5 + g * 7, by - ch + 4), Vector2(cx + 5 + g * 7, by), col.lightened(0.04), 1.0)
					l.draw_colored_polygon(PackedVector2Array([Vector2(cx - 3, by - ch), Vector2(cx + 8, by - ch - 9), Vector2(cx + 14, by - ch - 2), Vector2(cx + 20, by - ch - 7), Vector2(cx + 27, by - ch)]), col)
				l.draw_line(Vector2(x + 20, by - h * 0.85), Vector2(x + w + 10, by - h * 0.45), col, 12.0)
			_:
				# 학교: 위가 부서진 고딕 벽 + 뾰족 아치 창(뒤의 불빛이 비침)
				var top := PackedVector2Array([Vector2(x, by)])
				top.append(Vector2(x, by - h))
				var steps := 6
				for i in range(1, steps):
					top.append(Vector2(x + w * float(i) / steps, by - h * rng.randf_range(0.55, 1.0)))
				top.append(Vector2(x + w, by - h * 0.5))
				top.append(Vector2(x + w, by))
				l.draw_colored_polygon(top, col)
				var wx := x + w * 0.5
				var wy := by - h * 0.25
				var ww := w * 0.22
				var wh := h * 0.42
				var win := PackedVector2Array([Vector2(wx - ww, wy), Vector2(wx - ww, wy - wh * 0.65), Vector2(wx, wy - wh), Vector2(wx + ww, wy - wh * 0.65), Vector2(wx + ww, wy)])
				l.anim(Kit.Pen._bounds(win, 1.0), func(cv: CanvasItem, tt: float) -> void: cv.draw_colored_polygon(win, Color(glass, 0.28 + 0.12 * sin(tt * 4.0 + bk))))
				l.draw_line(Vector2(wx, wy), Vector2(wx, wy - wh * 0.9), col, 2.0)
				l.draw_line(Vector2(wx - ww, wy - wh * 0.4), Vector2(wx + ww, wy - wh * 0.4), col, 2.0)
				# 깨진 유리 조각 색
				var gcols := [Color("#3a4a8a"), Color("#8a3a5a"), Color("#c8a040")]
				for gi in 3:
					var gp := Vector2(wx - ww * 0.6 + gi * ww * 0.6, wy - wh * 0.62)
					l.draw_rect(Rect2(gp, Vector2(4, 5)), Color(gcols[gi], 0.6))
		# 불길
		for i in 3:
			var fx := x + rng.randf_range(0, w)
			var fy := by - rng.randf_range(0, h * 0.5)
			l.anim(Rect2(fx - 7, fy - 21, 14, 22), func(cv: CanvasItem, tt: float) -> void:
				var fh := 14.0 + 6.0 * sin(tt * 6.0 + fx)
				cv.draw_colored_polygon(PackedVector2Array([Vector2(fx - 7, fy), Vector2(fx - 3, fy - fh * 0.6), Vector2(fx + sin(tt * 8.0 + i) * 2.0, fy - fh), Vector2(fx + 4, fy - fh * 0.5), Vector2(fx + 7, fy)]), Color(fire, 0.6))
				cv.draw_colored_polygon(PackedVector2Array([Vector2(fx - 3, fy), Vector2(fx, fy - fh * 0.55), Vector2(fx + 3, fy)]), Color(1.0, 0.9, 0.6, 0.6) if fire != StArt.FOX_BLUE else Color(StArt.FOX_CORE, 0.6)))
		x += w + rng.randf_range(90, 220)
		k += 1
	l.draw_rect(Rect2(-100, by, span.x + 200, span.y), col)


# ═══════════════════════════════════════════════════════════
# 2단계: 별의 시련 (각 지역의 밤) · 에필로그의 아침
# ═══════════════════════════════════════════════════════════

## 별의 시련 하늘: 리라의 별하늘 + 시련의 자리로 떨어져 내리는 별줄기(가운데 위에서 지평선으로)
static func _sky_trial(c, pal: Dictionary) -> void:
	_sky_star(c, pal)
	# 시련의 별: 하늘에서 내려와 박힌 빛줄기 (천천히 숨쉰다) + 그 별에서 흩어지는 작은 별똥 (리라의 사역마들)
	var x := 352.0
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		var a := 0.5 + 0.2 * sin(t * 1.4)
		cv.draw_rect(Rect2(x - 10, 0, 20, 300), Color(StArt.STAR, 0.035 * a))
		cv.draw_rect(Rect2(x - 2, 0, 4, 300), Color(StArt.STAR, 0.12 * a))
		cv.draw_rect(Rect2(x - 0.5, 0, 1, 300), Color(StArt.STAR_CORE, 0.45 * a))
		StArt.glow(cv, Vector2(x, 26), 22.0, StArt.STAR, 0.3 * a)
		StArt.star(cv, Vector2(x, 26), 6.0, Color(StArt.STAR_CORE, 0.9), -PI * 0.5 + t * 0.2)
		for i in 3:
			var lt := fmod(t * 0.35 + i * 0.33, 1.0)
			var d := Vector2(-1.0 + i, 1.2).normalized()
			var p := Vector2(x, 26) + d * lt * 220.0
			cv.draw_line(p, p - d * 14.0, Color(StArt.STAR, 0.5 * (1.0 - lt)), 1.0))


static func _layer_trial(l, theme: String, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, _t: float) -> void:
	var col := _layer_col(th, depth)
	var lamp: Color = th.accent
	var by := _bot(span)
	match depth:
		0:
			_night_skyline(l, theme, span, by - 70.0, col, rng, lamp)
		1:
			match theme:
				"st_kingdom": _mid_kingdom(l, span, col, rng, lamp)
				"st_elf": _mid_elf(l, span, col, rng, lamp)
				"st_temple": _mid_temple(l, span, col, rng, lamp)
				_: _mid_garden(l, span, col, rng, lamp)
		2:
			_near_trial(l, theme, span, col, rng, lamp)


## 먼 지평선: 각 지역의 온전한 실루엣과 불 켜진 창 (침공 판 _far_skyline의 온전한 모습)
static func _night_skyline(l, theme: String, span: Vector2, hy: float, col: Color, rng: RandomNumberGenerator, lamp: Color) -> void:
	var c2 := col.lightened(0.04)
	match theme:
		"st_kingdom":
			l.draw_rect(Rect2(-100, hy - 36, span.x + 200, 40), c2)
			var x := -40.0
			while x < span.x + 40:
				l.draw_rect(Rect2(x, hy - 46, 12, 10), c2)
				x += 24.0
			var dc := Vector2(span.x * 0.55, hy - 36)
			l.draw_rect(Rect2(dc.x - 50, dc.y - 50, 100, 50), c2)
			l.draw_circle(dc + Vector2(0, -50), 48, c2)
			l.draw_rect(Rect2(dc.x - 3, dc.y - 128, 6, 32), c2)
			l.draw_circle(dc + Vector2(0, -130), 4, Color(lamp, 0.8))
			for i in 9:
				var hx := rng.randf_range(0, span.x)
				l.draw_colored_polygon(PackedVector2Array([Vector2(hx - 20, hy - 36), Vector2(hx, hy - 62), Vector2(hx + 20, hy - 36)]), c2)
				var wr := Rect2(hx - 3, hy - 32, 5, 6)
				l.anim(wr, func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(wr, Color(lamp, 0.4 + 0.25 * StArt.twinkle(tt, i * 1.3, 0.3))))
		"st_elf":
			# 세계수: 별빛 잎이 반짝이는 수관
			var tx := span.x * 0.5
			l.draw_colored_polygon(PackedVector2Array([Vector2(tx - 70, hy), Vector2(tx - 30, hy - 170), Vector2(tx - 20, hy - 250), Vector2(tx + 20, hy - 250), Vector2(tx + 34, hy - 170), Vector2(tx + 76, hy)]), c2)
			for i in 11:
				var a := -PI * 0.5 + (i - 5) * 0.28
				var cp := Vector2(tx, hy - 250) + Vector2(cos(a) * 170.0, sin(a) * 80.0)
				l.draw_line(Vector2(tx, hy - 240), cp, c2, 8.0)
				l.draw_circle(cp, 44.0, c2)
			for i in 40:
				var lp := Vector2(tx + rng.randf_range(-210, 210), hy - 250 + rng.randf_range(-90, 50))
				l.anim(Rect2(lp, Vector2.ONE * 2.0), func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(Rect2(lp, Vector2.ONE * 2.0), Color(lamp, 0.25 + 0.5 * StArt.twinkle(tt, i * 0.9, 0.5))))
		"st_temple":
			var mx := span.x * 0.5
			l.draw_colored_polygon(PackedVector2Array([Vector2(mx - 380, hy), Vector2(mx - 70, hy - 180), Vector2(mx + 50, hy - 160), Vector2(mx + 400, hy)]), c2)
			l.draw_rect(Rect2(mx - 34, hy - 250, 56, 90), c2)
			l.draw_colored_polygon(PackedVector2Array([Vector2(mx - 40, hy - 250), Vector2(mx - 6, hy - 300), Vector2(mx + 28, hy - 250)]), c2)
			# 종루의 종빛
			l.anim(Kit.bb_circle(Vector2(mx - 6, hy - 226), 22.0), func(cv: CanvasItem, tt: float) -> void: cv.draw_circle(Vector2(mx - 6, hy - 226), 22, Color(lamp, 0.12 + 0.05 * sin(tt * 1.5))))
			l.draw_rect(Rect2(mx - 12, hy - 234, 12, 12), Color(lamp, 0.6))
			for i in 7:
				var px := mx - 200 + i * 66.0
				l.draw_rect(Rect2(px, hy - 60 - (i % 3) * 14, 18, 60), c2)
				l.draw_rect(Rect2(px + 6, hy - 50 - (i % 3) * 14, 5, 7), Color(lamp, 0.45))
		_:
			# 마녀학교: 온전한 탑들, 불 켜진 창
			var cx := span.x * 0.5
			l.draw_rect(Rect2(cx - 240, hy - 90, 480, 92), c2)
			var towers := [[-200, 150, 24], [-110, 200, 30], [-20, 270, 40], [80, 210, 32], [170, 160, 24]]
			for tw in towers:
				var tx: float = cx + tw[0]
				var h: float = tw[1]
				var w: float = tw[2]
				l.draw_rect(Rect2(tx - w * 0.5, hy - h, w, h), c2)
				l.draw_colored_polygon(PackedVector2Array([Vector2(tx - w * 0.7, hy - h), Vector2(tx, hy - h - w * 1.4), Vector2(tx + w * 0.7, hy - h)]), c2)
				for wi in 3:
					var wr := Rect2(tx - 3, hy - h + 20 + wi * 24, 6, 9)
					l.anim(wr, func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(wr, Color(lamp, 0.35 + 0.25 * StArt.twinkle(tt, tx + wi, 0.3))))
			# 시계탑 문자판
			l.draw_circle(Vector2(cx - 20, hy - 230), 12, Color(lamp, 0.25))
	l.draw_rect(Rect2(-100, hy + 2, span.x + 200, span.y), c2)


static func _mid_kingdom(l, span: Vector2, col: Color, rng: RandomNumberGenerator, lamp: Color) -> void:
	var by := _bot(span) - 20.0
	var x := rng.randf_range(-40, 40)
	var i := 0
	while x < span.x + 60:
		var w := rng.randf_range(60, 110)
		var h := rng.randf_range(90, 160)
		l.draw_rect(Rect2(x, by - h, w, h + 40), col)
		# 박공 지붕
		l.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, by - h), Vector2(x + w * 0.5, by - h - w * 0.45), Vector2(x + w + 6, by - h)]), col.darkened(0.15))
		if i % 2 == 0:
			l.draw_rect(Rect2(x + w * 0.7, by - h - w * 0.4, 9, w * 0.3), col)
		# 창: 몇 개는 불이 켜짐
		for r in 2:
			for k in 2:
				var wx := x + w * (0.25 + k * 0.4) - 4
				var wy := by - h + 18 + r * 34
				var on := rng.randf() < 0.55
				if on:
					l.anim(Rect2(wx, wy, 8, 11), func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(Rect2(wx, wy, 8, 11), Color(lamp, 0.55 + 0.15 * sin(tt * 0.8 + wx))))
				else:
					l.draw_rect(Rect2(wx, wy, 8, 11), col.darkened(0.3))
		# 깃발
		if i % 3 == 1:
			var fx := x + w * 0.5
			var top := by - h - w * 0.45
			l.draw_line(Vector2(fx, top), Vector2(fx, top - 26), col.lightened(0.1), 1.0)
			l.anim(Rect2(fx, top - 27, 15, 10), func(cv: CanvasItem, tt: float) -> void:
				var wave := sin(tt * 2.0 + fx) * 2.0
				cv.draw_colored_polygon(PackedVector2Array([Vector2(fx, top - 26), Vector2(fx + 14, top - 22 + wave), Vector2(fx, top - 18)]), Color("#6a2a3a")))
		x += w + rng.randf_range(4, 30)
		i += 1


static func _mid_elf(l, span: Vector2, col: Color, rng: RandomNumberGenerator, lamp: Color) -> void:
	var by := _bot(span)
	var x := rng.randf_range(-20, 80)
	var i := 0
	while x < span.x + 80:
		var w := rng.randf_range(34, 60)
		# 거대한 줄기 (위로 화면을 넘어감)
		l.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.8, by), Vector2(x - w * 0.5, -40), Vector2(x + w * 0.5, -40), Vector2(x + w * 0.8, by)]), col)
		l.draw_line(Vector2(x - w * 0.2, by), Vector2(x - w * 0.1, -40), col.lightened(0.05), 2.0)
		# 가지와 매달린 별빛 열매
		var yy := rng.randf_range(60, 160)
		var dir := 1.0 if i % 2 == 0 else -1.0
		l.draw_line(Vector2(x, yy), Vector2(x + dir * rng.randf_range(80, 140), yy - 30), col, 7.0)
		for k in 3:
			var fx := x + dir * (30.0 + k * 30.0)
			var fi := i
			l.anim(Rect2(fx - 10, yy - 10.0 * k - 5, 20, 37), func(cv: CanvasItem, tt: float) -> void:
				var fy := yy - 10.0 * k + 20.0 + sin(tt * 1.2 + k + fi) * 2.0
				cv.draw_line(Vector2(fx, yy - 10.0 * k - 4), Vector2(fx, fy), col.lightened(0.1), 1.0)
				StArt.glow(cv, Vector2(fx, fy), 9.0, lamp, 0.25)
				cv.draw_circle(Vector2(fx, fy), 2.5, Color(lamp, 0.8)))
		x += w + rng.randf_range(140, 260)
		i += 1
	l.draw_rect(Rect2(-100, by - 6, span.x + 200, span.y), col)


static func _mid_temple(l, span: Vector2, col: Color, rng: RandomNumberGenerator, lamp: Color) -> void:
	var by := _bot(span) - 10.0
	# 열주 회랑: 기둥 줄과 위의 들보, 기둥 사이 매달린 작은 종
	l.draw_rect(Rect2(-100, by - 170, span.x + 200, 16), col)
	var x := rng.randf_range(0, 40)
	var i := 0
	while x < span.x + 40:
		l.draw_rect(Rect2(x, by - 154, 22, 160), col)
		for g in 3:
			l.draw_line(Vector2(x + 5 + g * 6, by - 150), Vector2(x + 5 + g * 6, by), col.lightened(0.05), 1.0)
		l.draw_rect(Rect2(x - 4, by - 158, 30, 6), col.lightened(0.04))
		if i % 2 == 0:
			var bx := x + 54.0
			var bi := i
			l.anim(Rect2(bx - 10, by - 155, 20, 46), func(cv: CanvasItem, tt: float) -> void:
				var sw := sin(tt * 1.4 + bi) * 0.1
				var bt := Vector2(bx, by - 154) + Vector2(sin(sw), cos(sw)) * 30.0
				cv.draw_line(Vector2(bx, by - 154), bt, col.lightened(0.1), 1.0)
				cv.draw_colored_polygon(PackedVector2Array([bt + Vector2(-6, 10), bt + Vector2(-4, 0), bt + Vector2(4, 0), bt + Vector2(6, 10)]), Color(lamp, 0.55)))
		x += 110.0
		i += 1
	l.draw_rect(Rect2(-100, by, span.x + 200, span.y), col)


static func _mid_garden(l, span: Vector2, col: Color, rng: RandomNumberGenerator, lamp: Color) -> void:
	var by := _bot(span) - 10.0
	var x := rng.randf_range(-20, 60)
	var i := 0
	while x < span.x + 60:
		match i % 3:
			0:
				# 둥근 생울타리 아치
				var w := 120.0
				l.draw_rect(Rect2(x, by - 70, 22, 80), col)
				l.draw_rect(Rect2(x + w - 22, by - 70, 22, 80), col)
				l.draw_arc(Vector2(x + w * 0.5, by - 70), w * 0.5 - 11, PI, TAU, 18, col, 22.0)
				x += w
			1:
				# 유리 온실 (안에서 보랏빛 별이 피어남)
				var w2 := 130.0
				l.draw_rect(Rect2(x, by - 90, w2, 100), col)
				l.draw_colored_polygon(PackedVector2Array([Vector2(x, by - 90), Vector2(x + w2 * 0.5, by - 140), Vector2(x + w2, by - 90)]), col)
				for k in 4:
					var gx := x + 12 + k * 30.0
					l.anim(Rect2(gx, by - 80, 22, 60), func(cv: CanvasItem, tt: float) -> void: cv.draw_rect(Rect2(gx, by - 80, 22, 60), Color(lamp, 0.12 + 0.06 * StArt.twinkle(tt, gx, 0.4))))
				x += w2
			_:
				# 줄지은 등불 기둥
				for k in 3:
					var px := x + k * 40.0
					l.draw_rect(Rect2(px, by - 60, 4, 70), col)
					_st_glow(l, Vector2(px + 2, by - 66), 10.0, lamp, 0.3)
					l.draw_circle(Vector2(px + 2, by - 66), 3.0, Color(lamp, 0.8))
				x += 120.0
		x += rng.randf_range(40, 120)
		i += 1
	l.draw_rect(Rect2(-100, by, span.x + 200, span.y), col)


## 가까운 층 (정적): 지역별 검은 실루엣 소품
static func _near_trial(l, theme: String, span: Vector2, col: Color, rng: RandomNumberGenerator, lamp: Color) -> void:
	var by := _bot(span) + 10.0
	var x := rng.randf_range(0, 200)
	while x < span.x + 40:
		match theme:
			"st_kingdom":
				# 가로등과 쇠울타리
				l.draw_rect(Rect2(x, by - 90, 4, 90), col)
				l.draw_rect(Rect2(x - 5, by - 98, 14, 9), col)
				l.draw_circle(Vector2(x + 2, by - 93), 3.0, Color(lamp, 0.85))
				_st_glow(l, Vector2(x + 2, by - 93), 22.0, lamp, 0.18)
				for k in 10:
					l.draw_rect(Rect2(x + 14 + k * 7, by - 30, 2, 30), col)
				l.draw_rect(Rect2(x + 12, by - 26, 72, 2), col)
			"st_elf":
				# 뿌리와 고사리
				l.draw_colored_polygon(PackedVector2Array([Vector2(x - 40, by), Vector2(x - 10, by - 40), Vector2(x + 10, by - 50), Vector2(x + 20, by - 20), Vector2(x + 60, by)]), col)
				for k in 5:
					var a := -PI * 0.5 + (k - 2) * 0.4
					l.draw_line(Vector2(x + 80, by), Vector2(x + 80, by) + Vector2(cos(a), sin(a)) * 34.0, col, 3.0)
			"st_temple":
				# 계단 난간과 향로
				l.draw_rect(Rect2(x, by - 50, 26, 50), col)
				l.draw_rect(Rect2(x - 4, by - 56, 34, 6), col)
				l.draw_colored_polygon(PackedVector2Array([Vector2(x + 60, by), Vector2(x + 66, by - 22), Vector2(x + 84, by - 22), Vector2(x + 90, by)]), col)
				l.draw_circle(Vector2(x + 75, by - 26), 4.0, Color(lamp, 0.6))
			_:
				# 다듬은 나무(토피어리)와 꽃
				l.draw_rect(Rect2(x + 8, by - 30, 6, 30), col)
				l.draw_circle(Vector2(x + 11, by - 44), 18.0, col)
				l.draw_circle(Vector2(x + 11, by - 70), 12.0, col)
				for k in 6:
					l.draw_circle(Vector2(x + 40 + k * 9, by - 6 - (k % 2) * 3), 3.0, Color(lamp, 0.35))
		x += rng.randf_range(220, 420)
	l.draw_rect(Rect2(-100, by, span.x + 200, span.y), col)


# ─── 에필로그 아침 ──────────────────────────────────────

static func _sky_dawn(c, pal: Dictionary) -> void:
	_gradient(c, [[0.0, pal.sky_top], [0.4, Color("#7a7ab0")], [0.75, Color("#e8a8a0")], [1.0, pal.sky_bottom]])
	# 떠오르는 해
	var sc := Vector2(440, 300)
	c.draw_circle(sc, 120, Color(1.0, 0.85, 0.6, 0.08))
	c.draw_circle(sc, 70, Color(1.0, 0.88, 0.65, 0.12))
	c.draw_circle(sc, 34, Color("#ffe8c0"))
	# 아문 하늘의 흉터 (푸른 실로 꿰맨 균열) — 이제 눈은 없다
	c.anim(_bb_crack(Vector2(80, -10), Vector2(220, 140), 6.0), func(cv: CanvasItem, t: float) -> void: _sky_crack(cv, Vector2(80, -10), Vector2(220, 140), 101, 6.0, t, 0, Vector2(320, 300), true, 1.0))
	c.anim(_bb_crack(Vector2(580, -10), Vector2(470, 120), 6.0), func(cv: CanvasItem, t: float) -> void: _sky_crack(cv, Vector2(580, -10), Vector2(470, 120), 127, 6.0, t, 2, Vector2(320, 300), true, 1.0))
	# 구름
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var cl: Array = [] ## [y, x0, speed, r]
	for i in 8:
		var y := rng.randf_range(60, 220)
		var x0 := rng.randf() * 900.0
		var sp := rng.randf_range(2.0, 5.0)
		cl.append([y, x0, sp, rng.randf_range(18, 36)])
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for e: Array in cl:
			var y: float = e[0]
			var x := fmod(float(e[1]) + t * float(e[2]), 900.0) - 130.0
			var r: float = e[3]
			var cc := Color(1.0, 0.92, 0.88, 0.35)
			cv.draw_circle(Vector2(x, y), r, cc)
			cv.draw_circle(Vector2(x + r * 0.9, y + 4), r * 0.75, cc)
			cv.draw_circle(Vector2(x - r * 0.9, y + 6), r * 0.6, cc))
	# 새 떼
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 5:
			var bx := fmod(t * 14.0 + i * 23.0, 760.0) - 60.0
			var byy := 120.0 + sin(t * 0.6 + i) * 8.0 + i * 6.0
			var f := sin(t * 8.0 + i) * 2.0
			cv.draw_line(Vector2(bx - 4, byy - f), Vector2(bx, byy), Color(0.2, 0.15, 0.25, 0.7), 1.0)
			cv.draw_line(Vector2(bx, byy), Vector2(bx + 4, byy - f), Color(0.2, 0.15, 0.25, 0.7), 1.0))


static func _layer_dawn(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	var col := _layer_col(th, depth)
	var warm := Color(1.0, 0.85, 0.55)
	match depth:
		0:
			# 부러진 시계탑을 두른 비계 (학교 실루엣은 폐허 판과 같은 모양)
			var hy := _bot(span) - 66.0
			_far_skyline(l, "ruin_school", span, hy, col, rng, warm)
			var cx := span.x * 0.5 - 20.0
			for k in 6:
				var yy := hy - 40.0 - k * 40.0
				l.draw_line(Vector2(cx - 34, yy), Vector2(cx + 34, yy), col.darkened(0.2), 2.0)
			l.draw_line(Vector2(cx - 34, hy), Vector2(cx - 34, hy - 270), col.darkened(0.2), 2.0)
			l.draw_line(Vector2(cx + 34, hy), Vector2(cx + 34, hy - 270), col.darkened(0.2), 2.0)
			# 기중기 팔과 들어 올리는 새 종
			l.draw_line(Vector2(cx + 34, hy - 270), Vector2(cx - 60, hy - 300), col.darkened(0.25), 3.0)
			l.anim(Rect2(cx - 62, hy - 297, 24, 62), func(cv: CanvasItem, tt: float) -> void:
				var sw := sin(tt * 0.7) * 3.0
				cv.draw_line(Vector2(cx - 50, hy - 296), Vector2(cx - 50 + sw, hy - 250), col.darkened(0.25), 1.0)
				cv.draw_colored_polygon(PackedVector2Array([Vector2(cx - 58 + sw, hy - 236), Vector2(cx - 55 + sw, hy - 250), Vector2(cx - 45 + sw, hy - 250), Vector2(cx - 42 + sw, hy - 236)]), Color("#c8a050")))
			l.draw_rect(Rect2(-100, hy + 2, span.x + 200, span.y), col)
		1:
			# 고쳐 세우는 벽과 비계, 걸어 둔 축제 깃발 줄 (다시 열 축제)
			var by := _bot(span) - 10.0
			var x := rng.randf_range(-20, 60)
			var i := 0
			while x < span.x + 60:
				var w := rng.randf_range(90, 150)
				var h := rng.randf_range(80, 140)
				l.draw_rect(Rect2(x, by - h, w, h + 20), col)
				for k in 3:
					var yy := by - h * (0.3 + k * 0.3)
					l.draw_line(Vector2(x - 6, yy), Vector2(x + w + 6, yy), col.darkened(0.3), 2.0)
				l.draw_line(Vector2(x - 6, by), Vector2(x - 6, by - h - 10), col.darkened(0.3), 2.0)
				l.draw_line(Vector2(x + w + 6, by), Vector2(x + w + 6, by - h - 10), col.darkened(0.3), 2.0)
				if i % 2 == 0:
					_anim_lantern_string(l, Vector2(x + w + 6, by - h - 10), Vector2(x + w + 120, by - h + 10), 14.0, i, 0.8)
				x += w + rng.randf_range(80, 160)
				i += 1
			l.draw_rect(Rect2(-100, by, span.x + 200, span.y), col)
		2:
			_front_rubble(l, span, rng, t, warm, false)
