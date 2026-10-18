class_name TBackdrop
extends PDraw.Canvas
## 턴제 전투 배경 (640×360): 재의 들판의 밤. 자줏빛 밤하늘 · 큰 달 · 지평선의 불탄 나무와 무너진 탑 실루엣 ·
## 왼쪽 아래에서 오른쭉 위로 비스듬히 뻗은 길(대각선 사이드뷰의 깊이) · 떠다니는 재 · 가장자리 어둡게.
## 재와 안개만 움직이므로 20Hz로 다시 그린다.

const SKY_TOP := Color("#120a22")
const SKY_MID := Color("#2a1740")
const SKY_LOW := Color("#4a2a4e")
const MOON := Color("#f3e6c8")
const FAR := Color("#160d24")
const GROUND := Color("#2a2236")
const GROUND_LIT := Color("#3a2f48")
const GROUND_DARK := Color("#1d1727")
const PATH := Color("#3f3550")
const GRASS := Color("#3b4a3a")
const FOG := Color("#5a4466")

var _t := 0.0
var _acc := 0.0
var _ash: Array = [] ## [pos, vel, size, phase]
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = -10
	_rng.seed = 7
	for i in 40:
		_ash.append([Vector2(_rng.randf_range(0, 640), _rng.randf_range(0, 360)), Vector2(_rng.randf_range(-14, -4), _rng.randf_range(-6, 4)), _rng.randf_range(0.8, 1.8), _rng.randf() * TAU])


func _process(delta: float) -> void:
	_t += delta
	for a: Array in _ash:
		var p: Vector2 = a[0]
		p += (a[1] as Vector2) * delta + Vector2(sin(_t * 1.3 + float(a[3])) * 6.0, 0.0) * delta
		if p.x < -4.0:
			p = Vector2(644.0, _rng.randf_range(0, 360))
		if p.y < -4.0:
			p.y = 364.0
		elif p.y > 364.0:
			p.y = -4.0
		a[0] = p
	_acc += delta
	if _acc >= 1.0 / 20.0:
		_acc = 0.0
		queue_redraw()


func _paint() -> void:
	# 하늘
	pd.rect_grad(Rect2(0, 0, 640, 150), SKY_TOP, SKY_MID)
	pd.rect_grad(Rect2(0, 150, 640, 60), SKY_MID, SKY_LOW)
	# 별
	var r := RandomNumberGenerator.new()
	r.seed = 3
	for i in 70:
		var p := Vector2(r.randf_range(0, 640), r.randf_range(0, 170))
		var tw := 0.5 + 0.5 * sin(_t * r.randf_range(1.0, 3.0) + r.randf() * TAU)
		pd.draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, 0.25 + 0.5 * tw * (1.0 - p.y / 200.0)))
	# 달 (오른쪽 위) + 번짐
	var mc := Vector2(500, 62)
	pd.glow(mc, 70.0, Color(MOON, 0.16), 0.0)
	pd.draw_circle(mc, 26.0, MOON)
	pd.draw_circle(mc + Vector2(-6, -4), 4.0, Color("#e2d3b4"))
	pd.draw_circle(mc + Vector2(8, 7), 3.0, Color("#e2d3b4"))
	pd.draw_circle(mc + Vector2(-9, 10), 2.0, Color("#e2d3b4"))
	# 지평선 안개
	pd.rect_grad(Rect2(0, 170, 640, 40), Color(FOG, 0.0), Color(FOG, 0.35))
	# 먼 실루엣: 무너진 탑 + 불탄 나무
	pd.draw_colored_polygon(PackedVector2Array([Vector2(548, 206), Vector2(552, 120), Vector2(566, 112), Vector2(572, 130), Vector2(578, 124), Vector2(584, 206)]), FAR)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(584, 206), Vector2(586, 160), Vector2(596, 164), Vector2(600, 206)]), FAR)
	pd.draw_rect(Rect2(560, 150, 4, 6), Color(SKY_LOW, 0.8)) # 창
	for tx: Array in [[60, 32], [96, 22], [150, 28], [230, 18], [410, 26], [470, 16], [620, 30]]:
		var x := float(tx[0])
		var h := float(tx[1])
		pd.draw_line(Vector2(x, 208), Vector2(x + 2, 208 - h), FAR, 2.4)
		pd.draw_line(Vector2(x + 1, 208 - h * 0.6), Vector2(x - 7, 208 - h * 0.9), FAR, 1.4)
		pd.draw_line(Vector2(x + 1, 208 - h * 0.75), Vector2(x + 8, 208 - h), FAR, 1.4)
		pd.draw_line(Vector2(x, 208 - h * 0.4), Vector2(x - 5, 208 - h * 0.5), FAR, 1.0)
	# 땅: 지평선 아래 (깊이: 위가 어둡고 아래가 밝음)
	pd.rect_grad(Rect2(0, 206, 640, 154), GROUND_DARK, GROUND)
	pd.draw_line(Vector2(0, 206), Vector2(640, 206), Color(FOG, 0.5), 1.0)
	# 비스듬한 길 (왼쪽 아래 → 오른쪽 위)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0, 360), Vector2(150, 360), Vector2(640, 232), Vector2(640, 214), Vector2(560, 212)]), PATH)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(40, 360), Vector2(110, 360), Vector2(600, 236), Vector2(580, 226)]), Color(GROUND_LIT, 0.6))
	# 길 가장자리 결 (대각선 줄 몇 개 — 원근)
	for i in 7:
		var f := float(i) / 6.0
		var a := Vector2(lerpf(-40, 180, f), 360)
		var b := Vector2(640, lerpf(226, 290, f))
		pd.draw_line(a, b, Color(GROUND_LIT, 0.18 + 0.1 * (1.0 - f)), 1.0)
	# 가로 띠 (바닥 층을 읽히게)
	for i in 5:
		var y := lerpf(215, 352, pow(float(i) / 4.0, 1.3))
		pd.draw_line(Vector2(0, y), Vector2(640, y + 2), Color(GROUND_DARK, 0.5), 1.0)
	# 바위·풀
	r.seed = 11
	for i in 26:
		var p := Vector2(r.randf_range(0, 640), r.randf_range(214, 356))
		var depth := (p.y - 206.0) / 154.0
		var s := 1.0 + depth * 1.6
		if i % 3 == 0:
			pd.draw_colored_polygon(PackedVector2Array([p + Vector2(-3 * s, 0), p + Vector2(-1 * s, -2.4 * s), p + Vector2(2.4 * s, -1.6 * s), p + Vector2(3.2 * s, 0)]), Color("#3b3148"))
			pd.draw_line(p + Vector2(-1 * s, -2.4 * s), p + Vector2(2.4 * s, -1.6 * s), Color("#52465f"), 0.8)
		else:
			for j in 4:
				var b := p + Vector2((float(j) - 1.5) * 1.6 * s, 0)
				pd.draw_line(b, b + Vector2(r.randf_range(-1.5, 1.5) * s + sin(_t * 1.5 + p.x) * 0.6, -r.randf_range(3.0, 6.0) * s), GRASS, 0.9)
	# 양 진영 아래 빛 웅덩이 (마녀 쪽 따뜻하게, 적 쪽 차갑게)
	pd.draw_set_transform(Vector2(150, 300), 0.0, Vector2(1.0, 0.35))
	pd.glow(Vector2.ZERO, 110.0, Color("#6a4a5a", 0.35), 0.0)
	pd.draw_set_transform(Vector2(500, 300), 0.0, Vector2(1.0, 0.35))
	pd.glow(Vector2.ZERO, 120.0, Color("#3a4a4a", 0.35), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	# 떠다니는 재
	for a: Array in _ash:
		var p: Vector2 = a[0]
		var al := 0.25 + 0.35 * (0.5 + 0.5 * sin(_t * 2.0 + float(a[3])))
		pd.draw_rect(Rect2(p, Vector2(float(a[2]), float(a[2]))), Color("#9a8aa6", al))
	# 가장자리 어둡게
	pd.ring_grad(Vector2(320, 180), Vector2(300, 170), Vector2(520, 330), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6), 40)
