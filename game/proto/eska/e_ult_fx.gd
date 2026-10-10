class_name EUltFx
extends RefCounted
## 에스카 필살기 종언참 연출·판정 (어두워짐·레터박스·사방 참격·공허의 칼날·X자·어둠 폭발).

const WHITE := EVfx.WHITE
const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const DEEP := EVfx.DEEP
const INK := EVfx.INK
const PLUM := EVfx.PLUM
const BODY := EVfx.BODY
const MAGENTA := EVfx.MAGENTA
const STREAK := EVfx.STREAK
const EDGE := EVfx.EDGE


# ═══════════════════════════════════════════════════════════
# 종언참 — 세상이 어두워지고(레터박스·확대·감속), 사방으로 참격이 몰아친 뒤,
# 하늘의 거대한 공허의 칼날이 화면을 세로로 가른다. 바닥을 따라 충격파.
# ═══════════════════════════════════════════════════════════

class Ult extends Node2D:
	const SLAM := 0.62
	const END := 1.8
	const SLAM_DMG := 220
	const AFTER_DMG := 24
	var eska: EEska
	var target_x := 0.0
	var floor_y := 300.0
	var t := 0.0
	var lines: Array = [] ## [각도, 길이, 시작]
	var _slammed := false
	var _after := 0
	var _dark: UltDark
	var _glow: UltGlow
	var _banner: UltBanner

	func _ready() -> void:
		for i in 30:
			var a := -PI / 2.0 + randf_range(-PI * 0.95, PI * 0.95)
			lines.append([a, randf_range(110.0, 340.0), randf_range(0.04, 0.42), randf_range(0.2, 0.4) * (-1.0 if randf() < 0.5 else 1.0), randf_range(7.0, 12.0)])
		_dark = UltDark.new()
		_dark.u = self
		_dark.z_index = 4
		add_child(_dark)
		_glow = UltGlow.new()
		_glow.u = self
		_glow.z_index = 7
		_glow.material = Fx.add_material
		add_child(_glow)
		var layer := CanvasLayer.new()
		layer.layer = 15
		add_child(layer)
		_banner = UltBanner.new()
		_banner.u = self
		_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_banner)
		Fx.slowmo(0.55, 0.42) # 형성되는 동안 세상이 느려진다

	func _exit_tree() -> void:
		var cam = Fx.camera
		if cam and cam.get("zoom_extra") != null:
			cam.zoom_extra = 0.0
			cam.focus_w = 0.0

	func hand() -> Vector2:
		if is_instance_valid(eska):
			return eska.global_position + Vector2(eska.facing * 2.5, -44.0)
		return Vector2(target_x, floor_y - 40.0)

	func _process(delta: float) -> void:
		t += delta
		_camera()
		if not _slammed and t >= SLAM:
			_slammed = true
			_slam()
		if _slammed and _after < 4 and t >= SLAM + 0.16 * float(_after + 1):
			_after += 1
			_hit_column(AFTER_DMG, false, 30.0)
			EVfx.pixels(Vector2(target_x, floor_y - randf_range(20.0, 140.0)), 6, 160.0, Vector2.ZERO, 180.0, 0.3)
		if t >= END:
			queue_free()
			return
		_dark.queue_redraw()
		_glow.queue_redraw()
		_banner.queue_redraw()

	## 형성 중에는 에스카와 표적 사이로 다가가 확대, 내리꽂는 순간 한 번에 물러남
	func _camera() -> void:
		var cam = Fx.camera
		if cam == null or cam.get("zoom_extra") == null:
			return
		if t < SLAM:
			var k := clampf(t / 0.35, 0.0, 1.0)
			var e := k * k * (3.0 - 2.0 * k)
			cam.zoom_extra = 0.2 * e
			cam.focus_w = 0.55 * e
			var ex := eska.global_position.x if is_instance_valid(eska) else target_x
			cam.focus_p = Vector2((ex + target_x) * 0.5, floor_y - 80.0)
		else:
			var s := clampf((t - SLAM) / 0.5, 0.0, 1.0)
			cam.zoom_extra = lerpf(-0.06, 0.0, s)
			cam.focus_w = lerpf(0.3, 0.0, s)

	func _slam() -> void:
		Fx.flash(Color(0.92, 0.88, 1.0, 0.5), 0.18)
		Fx.hitstop(0.12)
		Fx.shake(1.2, 0.5)
		Fx.zoom_punch(0.1)
		PVfx.kick(Vector2(0, 7))
		Sfx.play(&"explode", 0.0)
		Sfx.play(&"slam", -2.0)
		_hit_column(SLAM_DMG, true, 48.0)
		EVfx.dark_burst(Vector2(target_x, floor_y - 70.0), 84.0)
		var pp := PParticles.get_layer(true)
		for i in 44:
			var p := Vector2(target_x + randf_range(-10, 10), floor_y - randf_range(0, 220))
			pp.spawn(p, Vector2(randf_range(-280, 280), randf_range(-240, 40)), Vector2(0, 420), randf_range(0.35, 0.75), randf_range(1.5, 3.0), WHITE, VIOLET, 0, 1.5)
		EVfx.shards(Vector2(target_x, floor_y - 30.0), 30, 260.0, Vector2(14, 30), 120.0)
		PVfx.dust(Vector2(target_x, floor_y), 10, 3.0, 26.0)

	func _hit_column(dmg: int, heavy: bool, half_w: float) -> void:
		if not is_instance_valid(eska):
			return
		var col := Rect2(target_x - half_w, floor_y - 420.0, half_w * 2.0, 460.0)
		for d: Node2D in ETarget.alive(get_tree()):
			if col.intersects(d.hit_rect()):
				eska.deal(d, dmg, heavy, Vector2(target_x, floor_y - 300.0))

	## 0 → 1 → 0 (어둠·현수막·레터박스)
	func env() -> float:
		return clampf(t / 0.12, 0.0, 1.0) * (1.0 - clampf((t - (END - 0.35)) / 0.35, 0.0, 1.0))


## 세상을 어둡게 (보통 섞기 — 캐릭터·허수아비도 함께 어두워져 실루엣이 된다) + 그 위에 다크 참격선·X자
class UltDark extends PDraw.Canvas:
	var u: Ult

	func _paint() -> void:
		var cam := get_viewport().get_camera_2d()
		var c := cam.get_screen_center_position() if cam else Vector2(320, 180)
		var a := 0.8 * u.env()
		pd.draw_rect(Rect2(c - Vector2(700, 450), Vector2(1400, 900)), Color(0.03, 0.01, 0.07, a))
		var t := u.t
		var h := u.hand()
		# 사방으로 몰아치는 휘어진 다크 참격 (폭풍 속 거대 검) — 검은 테두리가 보이게 보통 섞기로
		for l: Array in u.lines:
			var age: float = t - float(l[2])
			if age < 0.0 or age > 0.34:
				continue
			var f := age / 0.34
			var dv := Vector2(cos(float(l[0])), sin(float(l[0])))
			var grow := minf(f * 2.2, 1.0)
			EVfx.feather(pd, h + dv * 10.0, dv, float(l[1]), float(l[3]), float(l[4]) * (1.0 - f * 0.6), 1.0 - f, f * 0.7, maxf(grow, f * 0.7 + 0.02), 8)
		# 내리꽂은 자리를 X자로 가르는 거대한 두 줄기
		var s := t - Ult.SLAM
		if s >= 0.0 and s < 0.42:
			var xf := 1.0 - clampf((s - 0.06) / 0.36, 0.0, 1.0)
			var grow := 1.0 - pow(1.0 - clampf(s / 0.06, 0.0, 1.0), 2.0)
			var cen := Vector2(u.target_x, u.floor_y - 100.0)
			for side: float in [-1.0, 1.0]:
				var dv := Vector2(1.0, side * 1.2).normalized()
				EVfx.feather(pd, cen - dv * 170.0, dv, 340.0, 0.05 * side, 26.0 * (0.4 + 0.6 * xf), xf, 0.7 * (1.0 - xf), maxf(grow, 0.7 * (1.0 - xf) + 0.02))


## 빛나는 것들 (가산): 손의 빛 · 공허의 칼날 · 세로로 갈라진 화면 · 바닥 충격파 (참격선·X자는 UltDark가 보통 섞기로)
class UltGlow extends PDraw.Canvas:
	var u: Ult

	func _paint() -> void:
		var t := u.t
		var h := u.hand()
		var tx := u.target_x
		var fy := u.floor_y
		# 손 위의 빛 (모이는 고리)
		if t < Ult.SLAM + 0.1:
			var hf := clampf(t / 0.2, 0.0, 1.0)
			pd.glow(h, 11.0 + 6.0 * sin(t * 30.0), Color(WHITE, 0.95 * hf), 0.0)
			var rr := lerpf(40.0, 4.0, fmod(t * 2.6, 1.0))
			pd.draw_arc(h, rr, 0.0, TAU, 24, Color(PALE, 0.6 * hf), 1.2)
		# 공허의 칼날 (하늘에서 형성 → 내리꽂힘)
		if t < Ult.SLAM:
			var form := clampf((t - 0.1) / (Ult.SLAM - 0.1), 0.0, 1.0)
			var len := 300.0
			var top := fy - 430.0 + 46.0 * form * form
			var w := 19.0 * form
			var tip := Vector2(tx, top + len)
			var blade := PackedVector2Array([Vector2(tx, top), Vector2(tx + w, top + len * 0.22), tip, Vector2(tx - w, top + len * 0.22)])
			pd.draw_colored_polygon(blade, Color(DEEP, 0.55 * form))
			pd.draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[0]]), Color(WHITE, form), 1.5)
			pd.draw_set_transform(Vector2(tx, top + len * 0.5), 0.0, Vector2(0.35, 0.92))
			pd.draw_colored_polygon(PackedVector2Array([Vector2(0, -len * 0.5), Vector2(w, -len * 0.28), Vector2(0, len * 0.5), Vector2(-w, -len * 0.28)]),
				Color(WHITE, 0.6 * form + 0.3 * form * sin(t * 40.0)))
			pd.draw_set_transform(Vector2.ZERO)
			pd.glow(tip, 20.0 * form, Color(PALE, 0.55 * form), 0.0)
			# 칼날이 겨누는 바닥의 표식
			pd.draw_set_transform(Vector2(tx, fy), 0.0, Vector2(1.0, 0.22))
			pd.draw_arc(Vector2.ZERO, 26.0 * (1.2 - form * 0.4), 0.0, TAU, 28, Color(VIOLET, 0.8 * form), 2.0)
			pd.draw_set_transform(Vector2.ZERO)
		else:
			var s := t - Ult.SLAM
			# 화면을 세로로 가르는 일격
			var cf := 1.0 - clampf(s / 0.3, 0.0, 1.0)
			if cf > 0.0:
				pd.draw_rect(Rect2(tx - 28.0 * cf, fy - 440.0, 56.0 * cf, 480.0), Color(WHITE, cf))
				pd.glow(Vector2(tx, fy - 110.0), 170.0 * cf, Color(PALE, 0.4 * cf), 0.0)
			# 바닥을 따라 퍼지는 충격파 (납작한 고리 둘)
			var sw := clampf(s / 0.45, 0.0, 1.0)
			if sw < 1.0:
				pd.draw_set_transform(Vector2(tx, fy), 0.0, Vector2(1.0, 0.16))
				pd.draw_arc(Vector2.ZERO, lerpf(20.0, 260.0, sw), 0.0, TAU, 40, Color(PALE, 0.9 * (1.0 - sw)), 6.0 * (1.0 - sw) + 1.0)
				pd.draw_arc(Vector2.ZERO, lerpf(10.0, 170.0, sw), 0.0, TAU, 40, Color(VIOLET, 0.7 * (1.0 - sw)), 3.0)
				pd.draw_set_transform(Vector2.ZERO)
			# 남아서 천천히 닫히는 공간의 금
			var close := 1.0 - clampf(s / (Ult.END - Ult.SLAM - 0.1), 0.0, 1.0)
			if close > 0.0:
				var pts := PackedVector2Array()
				var n := 16
				for i in n + 1:
					var y := lerpf(fy - 420.0, fy, float(i) / float(n))
					var jx := (5.0 if i % 2 == 0 else -5.0) * close + sin(float(i) * 1.7) * 2.0
					pts.append(Vector2(tx + jx, y))
				pd.draw_polyline(pts, Color(VIOLET, 0.7 * close), 8.0 * close + 1.0)
				pd.draw_polyline(pts, Color(WHITE, close), 3.0 * close + 0.6)
				pd.draw_rect(Rect2(tx - 44.0, fy - 2.0, 88.0, 3.0), Color(PALE, 0.6 * close))


## 기술명 현수막 + 레터박스 (화면 고정)
class UltBanner extends Control:
	var u: Ult

	func _draw() -> void:
		var e := u.env()
		if e <= 0.0:
			return
		var W := size.x
		var H := size.y
		var mid := W * 0.5
		var bar := 26.0 * e
		draw_rect(Rect2(0, 0, W, bar), Color(0, 0, 0, 0.92))
		draw_rect(Rect2(0, H - bar, W, bar), Color(0, 0, 0, 0.92))
		var font := get_theme_default_font()
		var txt := "종언참"
		var fs := 22
		var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var cy := 70.0
		var slide := (1.0 - clampf(u.t / 0.18, 0.0, 1.0)) * 24.0
		draw_rect(Rect2(0, cy - 20, W, 30), Color(0.02, 0.0, 0.05, 0.5 * e))
		draw_line(Vector2(mid - 150 + slide, cy - 20), Vector2(mid + 150 + slide, cy - 20), Color(VIOLET, 0.85 * e), 1.0)
		draw_line(Vector2(mid - 150 - slide, cy + 10), Vector2(mid + 150 - slide, cy + 10), Color(VIOLET, 0.85 * e), 1.0)
		var pos := Vector2(mid - sz.x * 0.5 + slide, cy + 2)
		draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.05, 0.0, 0.1, e))
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, e))
		var sub := "끝은, 내가 정한다."
		var ssz := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		draw_string_outline(font, Vector2(mid - ssz.x * 0.5, cy + 24), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(0, 0, 0, 0.8 * e))
		draw_string(font, Vector2(mid - ssz.x * 0.5, cy + 24), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(PALE, 0.9 * e))
