## blood.gd — 코드로 그리는 피 튄 자국(화면 위)과 피 번짐(돌 틈). 천천히 흘러내린다. HTML 판 blood.js 를 옮긴 것.
## 겹친 곳이 진해지지 않게 CanvasGroup 으로 한 장으로 합쳐 칠하고, 전체 진하기는 modulate.a 로 바꾼다.
## (고어는 글로 묘사하지 않는다 — 화면 연출은 HTML 판과 같은 정도)
class_name BloodLayer
extends CanvasGroup

var items: Array = []
var drawer: Node2D
var _now := 0.0


func _ready() -> void:
	drawer = Node2D.new()
	add_child(drawer)
	drawer.draw.connect(_draw_items)


func clear_all() -> void:
	items = []
	modulate.a = 1.0
	if drawer:
		drawer.queue_redraw()


static func _rng(seed: int) -> Callable:
	var s := [seed & 0xFFFFFFFF]
	return func() -> float:
		s[0] = (s[0] + 0x6D2B79F5) & 0xFFFFFFFF
		var t: int = s[0]
		t = Rules._imul(t ^ (t >> 15), t | 1)
		t = (t ^ ((t + Rules._imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF
		return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


static func _blob(r: Callable, c: Vector2, rad: float, n: int, rough: float, sx := 1.0, sy := 1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ph: float = r.call() * 6.28
	var ph2: float = r.call() * 6.28
	for i in n:
		var a := float(i) / n * TAU
		var k: float = 1.0 + rough * (0.55 * sin(a * 3 + ph) + 0.3 * sin(a * 7 + ph2) + (r.call() - 0.5) * 0.5)
		pts.append(c + Vector2(cos(a) * rad * k * sx, sin(a) * rad * k * sy))
	return pts


## 튄 자국 하나. size: 크기 / dir: 튄 방향(라디안, null 이면 사방)
func splat(cx: float, cy: float, size: float, seed := 1, dir = null) -> Dictionary:
	var r := _rng(seed)
	var c := Vector2(cx, cy)
	var s := {"kind": "splat", "c": c, "size": size, "polys": [], "drops": [], "drips": [], "t0": _now}
	var n := 3 + int(r.call() * 4)
	for i in n:
		var a: float = r.call() * TAU
		var d: float = r.call() * size * 0.38
		s.polys.append(_blob(r, c + Vector2(cos(a), sin(a)) * d, size * (0.22 + r.call() * 0.26), 22, 0.28))
	var k := 6 + int(r.call() * 7)
	for q in k:
		var a3: float = (float(dir) + (r.call() - 0.5) * 1.5) if dir != null else r.call() * TAU
		var ln: float = size * (0.42 + pow(r.call(), 1.6) * 0.85)
		var w: float = size * (0.035 + r.call() * 0.05)
		var u := Vector2(cos(a3), sin(a3))
		var pp := Vector2(-u.y, u.x)
		var b := c + u * size * 0.2
		var t := c + u * ln
		var tip: float = w * (0.15 + r.call() * 0.25)
		s.polys.append(PackedVector2Array([b + pp * w, t + pp * tip, t - pp * tip, b - pp * w]))
		if r.call() < 0.75:
			s.drops.append({"p": t + u * w * 1.4, "r": w * (0.5 + r.call() * 0.6)})
	var m := 26 + int(r.call() * 30)
	for j in m:
		var a2: float = (float(dir) + (r.call() - 0.5) * 1.8) if dir != null else r.call() * TAU
		var d2: float = size * (0.5 + pow(r.call(), 0.8) * 1.9)
		s.drops.append({"p": c + Vector2(cos(a2), sin(a2)) * d2, "r": maxf(1.2, size * (0.012 + r.call() * 0.05) * (1.5 - d2 / (size * 2.6)))})
	var dn := 2 + int(r.call() * 4)
	for t2 in dn:
		s.drips.append({"x": cx + (r.call() - 0.5) * size * 0.7, "y": cy + size * (0.1 + r.call() * 0.2), "w": size * (0.04 + r.call() * 0.05),
			"max": size * (0.7 + r.call() * 2.4), "speed": 8 + r.call() * 22, "delay": 200 + r.call() * 1200})
	items.append(s)
	return s


## 여러 개를 흩뿌린다. opts: count, x0,x1,y0,y1, min, max, seed, stagger(ms)
func spray(o: Dictionary) -> void:
	var r := _rng(int(o.get("seed", 1)))
	var n: int = o.get("count", 4)
	for i in n:
		var x: float = lerpf(float(o.get("x0", 200)), float(o.get("x1", 1720)), r.call())
		var y: float = lerpf(float(o.get("y0", 120)), float(o.get("y1", 960)), r.call())
		var sz: float = lerpf(float(o.get("min", 40)), float(o.get("max", 120)), r.call())
		var sd := int(r.call() * 100000) + 1
		var delay := float(o.get("stagger", 0)) * i
		if delay > 0:
			get_tree().create_timer(FX.ms(delay) / 1000.0, false).timeout.connect(func(): splat(x, y, sz, sd))
		else:
			splat(x, y, sz, sd)


## 돌 틈으로 번지는 피 (C5). level 이 오를수록 넓어진다
func pool(x0: float, x1: float, y: float, seed := 7) -> Dictionary:
	var r := _rng(seed)
	var p := {"kind": "pool", "polys": [], "level": 0.0, "shown": 0.0, "cracks": [], "c": Vector2((x0 + x1) / 2.0, y)}
	for i in 16:
		var t: float = r.call()
		var bx := x0 + t * (x1 - x0)
		var by: float = y + (r.call() - 0.45) * 70.0 + sin(t * 6.0) * 18.0
		p.polys.append({"p": Vector2(bx, by), "rad": 26.0 + r.call() * 46.0, "grow": 0.6 + r.call() * 0.8,
			"pts": _blob(r, Vector2.ZERO, 1.0, 28, 0.42, 1.5 + r.call() * 0.8, 0.45 + r.call() * 0.25)})
	for c in 14:
		var pts := PackedVector2Array()
		var px: float = x0 + r.call() * (x1 - x0)
		var py: float = y + (r.call() - 0.5) * 40.0
		var dr := -1.0 if r.call() < 0.5 else 1.0
		pts.append(Vector2(px, py))
		for s2 in 7:
			px += dr * (20.0 + r.call() * 60.0)
			py += (r.call() - 0.35) * 40.0
			pts.append(Vector2(px, py))
		p.cracks.append({"pts": pts, "w": 1.5 + r.call() * 2.5})
	items.append(p)
	return p


func _process(delta: float) -> void:
	_now += delta * 1000.0 * FX.speed
	if not items.is_empty():
		for it in items:
			if it.kind == "pool":
				it.shown += (it.level - it.shown) * minf(1.0, delta * 1000.0 / 240.0)
		drawer.queue_redraw()


func _draw_items() -> void:
	for it in items:
		if it.kind == "pool":
			_draw_pool(it)
		else:
			_draw_splat(it)


func _draw_splat(s: Dictionary) -> void:
	var age: float = _now - float(s.t0)
	var grow := minf(1.0, age / 120.0)
	var c: Vector2 = s.c
	var col := Color(0.44, 0.012, 0.063)
	for p in s.polys:
		var q := PackedVector2Array()
		for v in p:
			q.append(c + (v - c) * grow)
		drawer.draw_colored_polygon(q, col)
	for d in s.drops:
		drawer.draw_circle(c + (d.p - c) * grow, d.r * grow, col)
	for d in s.drips:
		var t := maxf(0.0, age - float(d.delay)) / 1000.0
		var ln := minf(float(d.max), float(d.speed) * t * (1.0 + t * 0.2)) * grow
		if ln <= 1.0:
			continue
		var x: float = d.x
		var y: float = d.y
		var w: float = d.w
		drawer.draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2, y), Vector2(x + w / 2, y), Vector2(x + w * 0.32, y + ln), Vector2(x - w * 0.32, y + ln)]), col)
		drawer.draw_circle(Vector2(x, y + ln), w * 0.55, col)
	# 젖은 윤기 (아주 약하게)
	drawer.draw_circle(c - Vector2(s.size, s.size) * 0.25, float(s.size) * 0.2 * grow, Color(0.6, 0.06, 0.1, 0.5))


func _draw_pool(p: Dictionary) -> void:
	var L: float = p.shown
	if L <= 0.01:
		return
	var col := Color(0.65, 0.06, 0.11)
	for c in p.cracks:
		var n := mini(c.pts.size(), 1 + int(L * 2.4))
		if n < 2:
			continue
		drawer.draw_polyline(c.pts.slice(0, n), col, float(c.w) * minf(1.8, 0.6 + L * 0.4), true)
	for b in p.polys:
		var k: float = float(b.rad) * (0.35 + minf(3.0, L) * 0.4 * float(b.grow))
		var q := PackedVector2Array()
		for v in b.pts:
			q.append(b.p + v * k)
		drawer.draw_colored_polygon(q, col)
