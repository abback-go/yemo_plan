class_name StArt
extends RefCounted
## 5장 공용 그림·소리 도우미 (별빛·바깥 신들·푸른 여우불). 배경·인물·적·장치가 같이 쓴다.
## 색 규칙 (docs/bible/world.md 5절, art.md): 별의 마녀 = 깊은 남색 + 따뜻한 별빛(연한 금·흰),
## 바깥 신들 = 흰색·무채색·기하학 (차가운 흰빛), 너울 = 푸른 여우불, 세라 = 붉은 불.

# 별빛 (리라·별의 탑)
const STAR := Color("#fff3c0") ## 별빛 강조색
const STAR_GOLD := Color("#ffd98a")
const STAR_CORE := Color("#fffbea")
const NAVY := Color("#1b2052")
const NAVY_DARK := Color("#0d1030")
const NAVY_LIGHT := Color("#2f3c86")
const EMBROIDER := Color("#e8cf86") ## 별자리 자수(금실)

# 바깥 신들 (흰 거신·사도·하늘의 균열)
const GOD_WHITE := Color("#eceaf2")
const GOD_SHADE := Color("#b9b7c9")
const GOD_DEEP := Color("#8b899e")
const GOD_LINE := Color("#5e5c72")
const GOD_GLOW := Color("#f4f8ff")
const VOID_BLACK := Color("#05040a")

# 너울의 푸른 여우불
const FOX_BLUE := Color(0.45, 0.78, 1.0)
const FOX_CORE := Color(0.88, 0.97, 1.0)
const FOX_GOLD := Color(1.0, 0.86, 0.5)

# 불타는 폐허
const RUIN_FIRE := Color("#ff6a3a")
const RUIN_EMBER := Color("#ffb05a")


## 소리: 공통 소리 목록에 없으면(오디오 담당이 아직 안 만듦) 대체 소리로. 경고를 남기지 않는다.
static func sfx(name: StringName, fallback: StringName = &"", vol := 0.0, var_pitch := 0.06) -> void:
	EnemyBase.play_sfx(name, fallback, vol, var_pitch)


static func sfx_pitch(name: StringName, fallback: StringName, pitch: float, vol := 0.0) -> void:
	EnemyBase.play_sfx_pitch(name, fallback, pitch, vol)


## 다섯 꼭짓점 별 (채움)
static func star(c: CanvasItem, p: Vector2, r: float, col: Color, rot := -PI * 0.5, inner := 0.45) -> void:
	if r < 0.8:
		c.draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2.ONE), col)
		return
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot + TAU * i / 10.0
		var rr := r if i % 2 == 0 else r * inner
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	c.draw_colored_polygon(pts, col)


## 네 갈래 반짝임 (+자 빛살). k = 0~1 밝기
static func sparkle(c: CanvasItem, p: Vector2, r: float, col: Color, k := 1.0) -> void:
	if k <= 0.02:
		return
	var a := Color(col, col.a * k)
	var rr := r * (0.6 + 0.4 * k)
	c.draw_line(p + Vector2(-rr, 0), p + Vector2(rr, 0), a, 1.0)
	c.draw_line(p + Vector2(0, -rr), p + Vector2(0, rr), a, 1.0)
	c.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(STAR_CORE, a.a))


## 부드러운 빛 덩이 (겹친 반투명 원)
static func glow(c: CanvasItem, p: Vector2, r: float, col: Color, a := 0.25) -> void:
	c.draw_circle(p, r, Color(col, a * 0.35))
	c.draw_circle(p, r * 0.62, Color(col, a * 0.6))
	c.draw_circle(p, r * 0.3, Color(col, a))


## 별자리 선 (점과 점 사이 가는 선 + 점)
static func constellation(c: CanvasItem, pts: Array, col: Color, k := 1.0, dot := 1.5) -> void:
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		c.draw_line(a, b, Color(col, col.a * 0.55 * k), 1.0)
	for p in pts:
		var pv: Vector2 = p
		c.draw_circle(pv, dot + 1.0, Color(col, 0.25 * k))
		c.draw_rect(Rect2(pv - Vector2(1, 1), Vector2(2, 2)), Color(STAR_CORE, k))


## 바깥 신들의 눈: 흰자 + 검은 동공(보는 쪽으로), open 0~1 (눈꺼풀). 세로로 갈라진 틈 안에 그린다
static func god_eye(c: CanvasItem, p: Vector2, w: float, open: float, look: Vector2, glow_k := 0.0) -> void:
	if open <= 0.02:
		c.draw_line(p + Vector2(-w, 0), p + Vector2(w, 0), Color(GOD_LINE, 0.9), 1.0)
		return
	var h := w * 0.55 * open
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(p + Vector2(-cos(a) * w, -sin(a) * h))
	for i in range(1, 12):
		var a := PI * i / 12.0
		pts.append(p + Vector2(cos(a) * w, sin(a) * h))
	c.draw_colored_polygon(pts, Color(0.02, 0.02, 0.05))
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(p + (q - p) * 0.82)
	c.draw_colored_polygon(inner, GOD_WHITE)
	var lk := look.limit_length(1.0)
	var pc := p + Vector2(lk.x * w * 0.35, lk.y * h * 0.3)
	var pr := minf(w * 0.32, h * 0.8)
	c.draw_circle(pc, pr, Color(0.03, 0.03, 0.06))
	c.draw_circle(pc, pr * 0.45, Color(GOD_GLOW, 0.25 + glow_k * 0.6))
	if glow_k > 0.0:
		c.draw_circle(p, w * 1.3, Color(GOD_GLOW, 0.08 * glow_k))


## 금(갈라짐): 시드 고정 지그재그 선. 가지가 칠 수 있다
static func crack(c: CanvasItem, from: Vector2, to: Vector2, seed: int, col: Color, width := 1.0, branches := 2, jag := 0.18) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pts := PackedVector2Array([from])
	var n := 6
	var d := to - from
	var nrm := d.orthogonal().normalized()
	for i in range(1, n):
		var k := float(i) / n
		pts.append(from + d * k + nrm * rng.randf_range(-1.0, 1.0) * d.length() * jag)
	pts.append(to)
	c.draw_polyline(pts, col, width)
	for b in branches:
		var i0 := rng.randi_range(1, n - 1)
		var bp: Vector2 = pts[i0]
		var bd := d.rotated(rng.randf_range(-1.0, 1.0)) * rng.randf_range(0.2, 0.4)
		c.draw_line(bp, bp + bd, col, maxf(width - 0.5, 1.0))


## 푸른 여우불 한 송이 (위로 너울거리는 불꽃)
static func foxfire(c: CanvasItem, p: Vector2, r: float, t: float, a := 1.0) -> void:
	var f := sin(t * 7.0) * r * 0.25
	c.draw_circle(p, r * 1.6, Color(FOX_BLUE, 0.12 * a))
	c.draw_colored_polygon(PackedVector2Array([
		p + Vector2(-r, r * 0.3), p + Vector2(-r * 0.5, -r * 0.6), p + Vector2(f, -r * 2.0),
		p + Vector2(r * 0.5, -r * 0.6), p + Vector2(r, r * 0.3), p + Vector2(0, r),
	]), Color(FOX_BLUE, 0.75 * a))
	c.draw_circle(p, r * 0.55, Color(FOX_CORE, 0.95 * a))


## 시간 → 0~1 (켜졌다 꺼지는 반짝임). seed로 위상이 다름
static func twinkle(t: float, seed: float, speed := 1.0) -> float:
	return 0.5 + 0.5 * sin(t * (1.3 + fmod(seed * 0.37, 1.7)) * speed + seed * 2.39)
