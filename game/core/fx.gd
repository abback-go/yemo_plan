## FX (autoload) — 연출 도구: 대기, 키프레임 애니메이션(웹 애니메이션 API처럼), 화면 흔들림, 피해 숫자,
## 섬광·암전, 배너·토스트, 입자(먼지·파편·불꽃·재), 칼날 선·빠른 선. prototype/js/fx.js 를 옮긴 것.
## FX.speed 를 올리면 모든 연출이 빨라진다(자동 테스트용, 주소 ?speed=4).
extends Node

var speed := 1.0
var reduced := false     # 움직임 줄이기
var touch := false       # 터치 기기
var low := false         # 터치 기기: 입자 수를 줄인다
# 작은 화면(휴대폰) 보정 — Main 이 창 크기가 바뀔 때 update_screen() 으로 정한다
var css_scale := 1.0     # 무대 1920×1080 이 실제 화면(CSS px)에서 보이는 배율
var small := false
var ui := 1.0            # 대사창·안내·HUD 글씨 배율
var card_preview := 1.12 # 카드 확대 보기 배율

var particles: Array = []
var overlays: Array = []
var anims: Array = []

# Main 이 연결하는 노드
var world: Node2D
var flash_rect: ColorRect
var fade_rect: ColorRect
var banner_label: Label
var toast_box: Control
var toast_label: Label
var float_layer: Node2D
var fx_draw: Node2D

var _toast_timer: SceneTreeTimer


class Anim extends RefCounted:
	signal finished
	var done := false
	var t0 := 0.0
	var dur := 1.0
	var frames: Array = []
	var easing = "linear"
	var apply: Callable
	var key = null
	var wrs: Array = []       # 이 노드들이 사라지면 애니메이션도 멈춘다(opts "node")

	func alive() -> bool:
		for w in wrs:
			if w.get_ref() == null:
				return false
		return true

	func cancel() -> void:
		if done:
			return
		done = true
		finished.emit()


func _ready() -> void:
	process_priority = -10
	touch = DisplayServer.is_touchscreen_available()
	low = touch


func now_ms() -> float:
	return Time.get_ticks_usec() / 1000.0


func ms(v: float) -> float:
	return maxf(0.0, v / speed)


## await FX.wait(300)
func wait(v: float) -> void:
	var t := ms(v)
	if t <= 0.0:
		await get_tree().process_frame
		return
	await get_tree().create_timer(t / 1000.0).timeout


## 애니메이션이 끝날 때까지 (이미 끝났으면 바로)
func until(a) -> void:
	if a == null:
		return
	if a is Anim:
		if not a.done:
			await a.finished
	elif a is Signal:
		await a


## 여러 개를 모두 기다린다 (Anim 배열)
func all(list: Array) -> void:
	for a in list:
		if a is Anim and not a.done:
			await a.finished


# ───────── 키프레임 애니메이션 ─────────
# frames: [{"o": 0~1(생략하면 고르게), "e": 이 구간의 이징, 값 이름: 값(float·Vector2·Color)}, ...]
# opts: {"easing": 전체 이징, "delay": ms, "key": 같은 key 의 이전 애니메이션은 취소}
func anim(dur_ms: float, frames: Array, apply: Callable, opts := {}) -> Anim:
	var a := Anim.new()
	a.dur = maxf(1.0, ms(dur_ms))
	a.t0 = now_ms() + ms(float(opts.get("delay", 0.0)))
	a.frames = _norm(frames)
	a.easing = opts.get("easing", "linear")
	a.apply = apply
	a.key = opts.get("key", null)
	var nd = opts.get("node", null)
	if nd is Object:
		a.wrs.append(weakref(nd))
	elif nd is Array:
		for n in nd:
			if n is Object:
				a.wrs.append(weakref(n))
	if a.key != null:
		for o in anims:
			if not o.done and o.key == a.key:
				o.cancel()
	anims.append(a)
	if opts.get("delay", 0.0) == 0.0 and apply.is_valid():
		apply.call(_values(a.frames, 0.0))
	return a


func cancel_key(key) -> void:
	for o in anims:
		if not o.done and o.key == key:
			o.cancel()


func _norm(frames: Array) -> Array:
	var n := frames.size()
	var out := []
	for f in frames:
		out.append(f.duplicate())
	if n == 0:
		return out
	if not out[0].has("o"):
		out[0]["o"] = 0.0
	if not out[n - 1].has("o"):
		out[n - 1]["o"] = 1.0
	# 비어 있는 오프셋은 앞뒤 사이에 고르게
	var i := 0
	while i < n:
		if out[i].has("o"):
			i += 1
			continue
		var j := i
		while j < n and not out[j].has("o"):
			j += 1
		var a: float = out[i - 1]["o"]
		var b: float = out[j]["o"]
		for k in range(i, j):
			out[k]["o"] = a + (b - a) * float(k - i + 1) / float(j - i + 1)
		i = j
	# 빠진 값은 앞 프레임 값으로 채운다
	var keys := {}
	for f in out:
		for k in f:
			if k != "o" and k != "e":
				keys[k] = true
	for k in keys:
		var last = null
		for f in out:
			if f.has(k):
				last = f[k]
			elif last != null:
				f[k] = last
		# 앞쪽이 비었으면 처음 나온 값으로
		var first = null
		for f in out:
			if f.has(k):
				first = f[k]
				break
		for f in out:
			if not f.has(k):
				f[k] = first
	return out


func _values(frames: Array, k: float) -> Dictionary:
	var n := frames.size()
	if n == 1:
		return frames[0]
	var i := 0
	while i < n - 2 and k > float(frames[i + 1]["o"]):
		i += 1
	var a: Dictionary = frames[i]
	var b: Dictionary = frames[i + 1]
	var span := float(b["o"]) - float(a["o"])
	var t := 1.0 if span <= 0.0 else clampf((k - float(a["o"])) / span, 0.0, 1.0)
	if a.has("e"):
		t = Ease.apply(a["e"], t)
	var out := {}
	for key in a:
		if key == "o" or key == "e":
			continue
		var va = a[key]
		var vb = b.get(key, va)
		if va is float or va is int:
			out[key] = lerpf(float(va), float(vb), t)
		elif va is Vector2 or va is Color:
			out[key] = va.lerp(vb, t)
		else:
			out[key] = vb if t >= 1.0 else va
	return out


func _process(delta: float) -> void:
	var now := now_ms()
	if not anims.is_empty():
		var list := anims.duplicate()
		for a in list:
			if a.done:
				continue
			if now < a.t0:
				continue
			if not a.wrs.is_empty() and not a.alive():
				a.done = true
				a.finished.emit()
				continue
			var k: float = (now - a.t0) / a.dur
			if k >= 1.0:
				if a.apply.is_valid():
					a.apply.call(_values(a.frames, 1.0))
				a.done = true
				a.finished.emit()
			else:
				if a.apply.is_valid():
					a.apply.call(_values(a.frames, Ease.apply(a.easing, k)))
		anims = anims.filter(func(x): return not x.done)
	_update_particles(minf(100.0, delta * 1000.0))
	if fx_draw:
		fx_draw.queue_redraw()


# ───────── 화면 흔들림 ─────────
func shake(power := 10.0, dur := 380.0) -> Anim:
	if not is_instance_valid(world):
		return null
	return shake_node(world, power, dur, 0.0, "shake_world")


## 쉬는 위치가 (0,0) 인 노드를 흔든다(컷신 등)
func shake_node(node: Node2D, power: float, dur: float, rot := 0.0, key = null) -> Anim:
	if reduced:
		power *= 0.3
		rot *= 0.3
	var frames := []
	var n := 12 if key != "shake_world" else 10
	for i in n:
		var k := 1.0 - float(i) / n
		frames.append({"p": Vector2(randf_range(-1, 1) * power * k, randf_range(-1, 1) * power * k), "r": randf_range(-1, 1) * rot * k})
	frames.append({"p": Vector2.ZERO, "r": 0.0})
	var wr: WeakRef = weakref(node)
	return anim(dur, frames, func(v):
		var nd = wr.get_ref()
		if nd:
			nd.position = v.p
			nd.rotation_degrees = v.r, {"key": key if key != null else "shake_%d" % node.get_instance_id()})


# ───────── 섬광·암전 ─────────
func flash(color = "#ffffff", dur := 260.0, peak := 0.9) -> Anim:
	if not flash_rect:
		return null
	var c: Color = Color(color) if color is String else color
	flash_rect.color = Color(c.r, c.g, c.b, 1.0)
	return anim(dur, [{"a": peak, "e": "ease-out"}, {"a": 0.0}], func(v): flash_rect.modulate.a = v.a, {"key": "flash"})


## 암전(1)·밝힘(0). CSS transition 처럼 'ease'
func fade(to: float, dur := 400.0) -> void:
	if not fade_rect:
		return
	var from := fade_rect.modulate.a
	var a := anim(dur, [{"a": from, "e": "ease"}, {"a": to}], func(v): fade_rect.modulate.a = v.a, {"key": "fade"})
	await until(a)


func set_fade(v: float) -> void:
	cancel_key("fade")
	if fade_rect:
		fade_rect.modulate.a = v


# ───────── 글자 연출 ─────────
## 피해 숫자 등 떠오르는 글자. cls: enemy | ally | immune | small
func float_text(x: float, y: float, text, cls := "") -> void:
	if not float_layer:
		return
	var l := Label.new()
	l.text = str(text)
	var size := 56
	var col := Color.WHITE
	if cls.contains("ally"):
		col = Color("#ff4b5a")
	elif cls.contains("enemy"):
		col = Color("#ffe9a8")
	if cls.contains("immune"):
		col = Color("#b9bcc4")
		size = 34
	if cls.contains("small"):
		size = 30
	l.add_theme_font_override("font", Assets.font("serif_black"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var holder := Node2D.new()
	holder.position = Vector2(x, y)
	float_layer.add_child(holder)
	holder.add_child(l)
	l.reset_size()
	var sz := l.get_combined_minimum_size()
	l.position = -sz * 0.5
	l.pivot_offset = sz * 0.5
	var a := anim(1100, [
		{"o": 0.0, "y": 0.0, "s": 0.6, "a": 0.0},
		{"o": 0.18, "y": -0.4, "s": 1.15, "a": 1.0},
		{"o": 0.7, "y": -0.9, "s": 1.0, "a": 1.0},
		{"o": 1.0, "y": -1.4, "s": 0.95, "a": 0.0}], func(v):
			if is_instance_valid(l):
				l.position = Vector2(-sz.x * 0.5, -sz.y * 0.5 + v.y * sz.y)
				l.scale = Vector2(v.s, v.s)
				l.modulate.a = v.a, {"easing": "ease-out"})
	a.finished.connect(func(): if is_instance_valid(holder): holder.queue_free())


func toast(text: String, dur := 1400.0) -> void:
	if not toast_box:
		return
	toast_label.text = text
	toast_box.visible = true
	toast_box.reset_size()
	toast_box.position = Vector2(960 - toast_box.size.x * toast_box.scale.x * 0.5, 560)
	var tm := get_tree().create_timer(dur / 1000.0)
	_toast_timer = tm
	tm.timeout.connect(func(): if _toast_timer == tm and toast_box: toast_box.visible = false)


func banner(text: String, dur := 900.0) -> void:
	if not banner_label:
		return
	banner_label.text = text
	banner_label.visible = true
	banner_label.pivot_offset = banner_label.size * 0.5
	var a := anim(dur, [
		{"o": 0.0, "a": 0.0, "s": 1.2}, {"o": 0.25, "a": 1.0, "s": 1.0}, {"o": 0.75, "a": 1.0, "s": 1.0}, {"o": 1.0, "a": 0.0, "s": 1.0}],
		func(v):
			banner_label.modulate.a = v.a
			banner_label.scale = Vector2(v.s, v.s), {"key": "banner"})
	await until(a)
	banner_label.visible = false


# ───────── 입자 ─────────
# opts: count, colors, speed, spread(각도 범위), angle, gravity, life, size, shape(dot|rock|flake|line), drag, jitterX/Y, alpha
func burst(x: float, y: float, opts := {}) -> void:
	var n := roundi(float(opts.get("count", 20)) * (0.55 if low else 1.0))
	var colors: Array = opts.get("colors", [opts.get("color", "#cccccc")])
	for i in n:
		var ang: float = float(opts.get("angle", -PI / 2)) + (randf() - 0.5) * float(opts.get("spread", PI * 2))
		var sp: float = float(opts.get("speed", 300)) * (0.35 + randf() * 0.75)
		particles.append({
			"x": x + (randf() - 0.5) * float(opts.get("jitterX", 0)), "y": y + (randf() - 0.5) * float(opts.get("jitterY", 0)),
			"vx": cos(ang) * sp, "vy": sin(ang) * sp,
			"g": float(opts.get("gravity", 600)), "drag": float(opts.get("drag", 0.6)),
			"life": float(opts.get("life", 900)) * (0.6 + randf() * 0.6), "age": 0.0,
			"size": float(opts.get("size", 4)) * (0.5 + randf()), "rot": randf() * 6.0, "vr": (randf() - 0.5) * 8.0,
			"color": Color(colors[randi() % colors.size()]), "shape": opts.get("shape", "dot"), "alpha": float(opts.get("alpha", 1.0))})


## 위에서 떨어지는 먼지·돌
func rain(x0: float, x1: float, y: float, opts := {}) -> void:
	var n := roundi(float(opts.get("count", 30)) * (0.55 if low else 1.0))
	var colors: Array = opts.get("colors", ["#888888"])
	for i in n:
		particles.append({
			"x": x0 + randf() * (x1 - x0), "y": y - randf() * 120.0,
			"vx": (randf() - 0.5) * 40.0, "vy": 60.0 + randf() * 160.0,
			"g": float(opts.get("gravity", 500)), "drag": 0.1,
			"life": float(opts.get("life", 1600)) * (0.6 + randf() * 0.6), "age": -randf() * float(opts.get("stagger", 400)),
			"size": float(opts.get("size", 4)) * (0.5 + randf()), "rot": randf() * 6.0, "vr": (randf() - 0.5) * 4.0,
			"color": Color(colors[randi() % colors.size()]), "shape": opts.get("shape", "dot"), "alpha": float(opts.get("alpha", 0.9))})


func _update_particles(dt: float) -> void:
	if particles.is_empty():
		return
	var s := dt * speed / 1000.0
	var keep := []
	for p in particles:
		p.age += dt * speed
		if p.age < 0:
			keep.append(p)
			continue
		if p.age > p.life:
			continue
		p.vy += p.g * s
		p.vx *= (1.0 - p.drag * s)
		p.vy *= (1.0 - p.drag * s * 0.3)
		p.x += p.vx * s
		p.y += p.vy * s
		p.rot += p.vr * s
		keep.append(p)
	particles = keep


func draw_particles(ci: CanvasItem) -> void:
	for p in particles:
		if p.age < 0:
			continue
		var k: float = 1.0 - p.age / p.life
		var c: Color = p.color
		c.a = clampf(k * 1.4, 0.0, 1.0) * p.alpha
		var pos := Vector2(p.x, p.y)
		var r: float = p.size
		match p.shape:
			"rock":
				var tr := Transform2D(p.rot, pos)
				ci.draw_colored_polygon(PackedVector2Array([tr * Vector2(-r, -r * 0.6), tr * Vector2(r * 0.7, -r), tr * Vector2(r, r * 0.5), tr * Vector2(-r * 0.4, r)]), c)
			"flake":
				var tr2 := Transform2D(p.rot, pos)
				ci.draw_colored_polygon(PackedVector2Array([tr2 * Vector2(-r, -r * 0.35), tr2 * Vector2(r, -r * 0.35), tr2 * Vector2(r, r * 0.35), tr2 * Vector2(-r, r * 0.35)]), c)
			"line":
				ci.draw_line(pos, pos - Vector2(p.vx, p.vy) * 0.04, c, maxf(1.0, r * 0.5))
			_:
				ci.draw_circle(pos, maxf(0.5, r), c)


# ───────── 선 연출 (효과 레이어에 짧게) ─────────
## 칼날 베기 선
func slash(x: float, y: float, opts := {}) -> void:
	var o := {"t0": now_ms(), "dur": ms(float(opts.get("dur", 320))), "x": x, "y": y, "len": float(opts.get("len", 160)),
		"ang": float(opts.get("ang", -0.7)), "color": Color(opts.get("color", "#ffffff")), "width": float(opts.get("width", 8)), "count": int(opts.get("count", 1)), "kind": "slash"}
	overlays.append(o)


## 두 점 사이를 빠르게 지나가는 선(화살 등). await 하면 다 지나갈 때까지
func streak(x0: float, y0: float, x1: float, y1: float, opts := {}) -> void:
	var o := {"t0": now_ms(), "dur": ms(float(opts.get("dur", 240))), "a": Vector2(x0, y0), "b": Vector2(x1, y1),
		"color": Color(opts.get("color", "#ffffff")), "width": float(opts.get("width", 4)), "kind": "streak"}
	overlays.append(o)
	await wait(float(opts.get("dur", 240)))


func draw_overlays(ci: CanvasItem) -> void:
	var now := now_ms()
	var keep := []
	for o in overlays:
		var k: float = (now - o.t0) / o.dur
		if k >= 1.0:
			continue
		keep.append(o)
		if o.kind == "slash":
			for i in o.count:
				var off: float = (i - (o.count - 1) / 2.0) * 26.0
				var d: Vector2 = Vector2(cos(o.ang), sin(o.ang)) * float(o.len) / 2.0
				var pp: Vector2 = Vector2(-sin(o.ang), cos(o.ang)) * off
				var grow := minf(1.0, k * 3.0)
				var a: Vector2 = Vector2(o.x, o.y) + pp - d
				var b := a + d * 2.0 * grow
				var c: Color = o.color
				var w: float = o.width * (1.0 - k * 0.6)
				ci.draw_line(a, b, Color(c.r, c.g, c.b, (1.0 - k) * 0.25), w * 3.2)
				ci.draw_line(a, b, Color(c.r, c.g, c.b, 1.0 - k), w, true)
		else:
			var h: Vector2 = o.a.lerp(o.b, k)
			var t: Vector2 = o.a.lerp(o.b, maxf(0.0, k - 0.25))
			var c2: Color = o.color
			ci.draw_line(t, h, Color(c2.r, c2.g, c2.b, 0.3), o.width * 3.0)
			ci.draw_line(t, h, c2, o.width, true)
	overlays = keep


# ───────── 작은 화면 보정 ─────────
func update_screen() -> void:
	var ws := Vector2(DisplayServer.window_get_size())
	var dpr := 1.0
	if OS.has_feature("web"):
		dpr = maxf(1.0, DisplayServer.screen_get_scale())
	var css := ws / dpr
	css_scale = minf(css.x / 1920.0, css.y / 1080.0)
	var m: Dictionary = GameData.D.mobile
	small = css_scale < float(m.smallScale)
	var hover: float = GameData.D.layout.hand.hoverScale
	if small:
		ui = clampf(float(m.minTextPx) / (20.0 * css_scale), 1.0, float(m.maxUi))
		card_preview = clampf(float(m.minCardTextPx) / (15.0 * css_scale), hover, float(m.maxCard))
	else:
		ui = 1.0
		card_preview = hover
