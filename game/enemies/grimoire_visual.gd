class_name GrimoireVisual
extends Node2D
## 마도서 그림: 금테 두른 가죽 표지에 커다란 외눈, 펄럭이는 페이지, 보라 책갈피 끈.
## 책등(경첩)이 뒤쪽, 표지가 앞쪽(세라 쪽)에서 열린다. 예고는 붉게 달아오르는 페이지 + 붉은 눈,
## 덮였을 때는 금 걸쇠·사슬과 보라 결계, 여우불에 타면 페이지 끝에 푸른 불.

const COVER := Color("#5a2a3e")
const COVER_DARK := Color("#34162a")
const COVER_LIGHT := Color("#7c3c56")
const GOLD := Color("#d8a84a")
const PAGE := Color("#e8dcc0")
const PAGE_SHADE := Color("#b8a888")
const INK := Color("#6a5a6a")
const RIBBON := Color("#8a3ac8")
const EYE_WHITE := Color("#f4ecdc")
const W := 28.0 ## 책 너비
const H := 32.0 ## 책 높이

var enemy: Grimoire
var _white := false


func _process(_delta: float) -> void:
	if enemy == null:
		return
	position = Vector2(0, -16)
	z_index = 2
	var k := enemy.tele_scale()
	scale = Vector2(enemy.facing * maxf(k, 0.01), maxf(k, 0.01) * (1.0 + (1.0 - k) * 0.6))
	modulate.a = k
	if enemy.state == Grimoire.S.CLOSED:
		rotation = sin(enemy._t * 50.0) * 0.06
	else:
		rotation = sin(enemy._t * 2.0) * 0.06


func _col(c: Color) -> Color:
	return Color.WHITE if _white else c


func _draw() -> void:
	if enemy == null:
		return
	_white = enemy.flash_amount() > 0.0
	var st := enemy.state
	var t := enemy._t
	var outline := Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9)
	var windup := st == Grimoire.S.WINDUP
	var closed := st == Grimoire.S.CLOSED
	var heat := enemy.progress() if windup else (1.0 if st == Grimoire.S.VOLLEY else 0.0)
	var hx := -W * 0.5 # 책등(경첩) x
	var top := -H * 0.5

	# 덮였을 때: 보라 결계
	if closed and not _white:
		var pulse := 0.5 + 0.5 * sin(t * 20.0)
		draw_arc(Vector2.ZERO, 20.0 + pulse * 2.0, 0.0, TAU, 24, Color(Grimoire.MANA, 0.35 + 0.3 * pulse), 2.0)
	# 위험 예고: 페이지 뒤 붉은 빛
	if heat > 0.0 and not _white:
		var pulse2 := 0.5 + 0.5 * sin(t * 40.0)
		draw_circle(Vector2(2, 0), 17.0 + 5.0 * heat, Color(Palette.DANGER, 0.18 + 0.32 * heat * pulse2))

	# 뒤표지 (가장자리만 보임)
	draw_rect(Rect2(hx - 1.0, top - 1.0, W + 2.0, H + 2.0), outline)
	draw_rect(Rect2(hx, top, W, H), _col(COVER_DARK))
	# 페이지 묶음
	var pages := Rect2(hx + 1.5, top + 1.5, W - 2.0, H - 3.0)
	draw_rect(pages, _col(PAGE_SHADE))
	draw_rect(Rect2(pages.position, Vector2(pages.size.x - 1.5, pages.size.y)), _col(PAGE.lerp(Color(1.0, 0.55, 0.5), heat * 0.6)))
	if not _white:
		# 글줄
		for i in 7:
			var y := top + 5.0 + i * 3.6
			var ln := 15.0 - float((i * 7) % 5)
			draw_line(Vector2(hx + 5.0, y), Vector2(hx + 5.0 + ln, y), Color(INK, 0.7), 1.0)
		# 펼친 페이지 가운데 룬 (예고 때 붉게 빛남)
		if enemy.open_amount > 0.35:
			var rc := Grimoire.MANA.lerp(Palette.DANGER, heat)
			draw_arc(Vector2(3, 0), 5.0, 0.0, TAU, 12, Color(rc, 0.4 + 0.5 * enemy.open_amount), 1.0)
			draw_rect(Rect2(Vector2(2, -1), Vector2(2, 2)), Color(rc, 0.8))
		# 여우불에 탐: 페이지 위쪽 가장자리의 푸른 불
		if enemy.burn > 0.0:
			for i in 6:
				var fx := hx + 3.0 + i * 4.4
				var fh := 3.0 + 2.0 * absf(sin(t * 18.0 + i * 1.7))
				draw_rect(Rect2(fx, top + 1.0 - fh, 2.0, fh), Color(Grimoire.FOX_BLUE, 0.85))
				draw_rect(Rect2(fx, top + 1.0 - fh * 0.5, 2.0, fh * 0.5), Color(1, 1, 1, 0.7))

	# 날리는 낱장 (열려 있을수록 많이)
	if enemy.open_amount > 0.25 and not closed:
		for i in 2:
			var ph := fmod(t * (1.6 + i * 0.7) + i * 0.5, 1.0)
			var p := Vector2(hx + 5.0 + ph * 22.0, top + 5.0 + i * 11.0 - sin(ph * PI) * 12.0)
			draw_set_transform(p, ph * TAU * (1.0 if i == 0 else -1.0), Vector2(1.0, absf(cos(ph * TAU)) + 0.2))
			draw_rect(Rect2(-3, -2, 6, 4), _col(PAGE))
			draw_rect(Rect2(-3, -2, 6, 1), _col(PAGE_SHADE))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 책갈피 끈 (아래로 늘어져 흔들림)
	var sway := sin(t * 3.0) * 2.0
	draw_polyline(PackedVector2Array([Vector2(4, H * 0.5 - 1.0), Vector2(5 + sway * 0.5, H * 0.5 + 4.0), Vector2(4 + sway, H * 0.5 + 9.0)]),
		_col(RIBBON), 2.0)

	# 앞표지: 경첩(뒤쪽)에서 열린다. 열린 각도에 따라 너비가 줄고 바깥 가장자리가 원근으로 커진다
	var ang := enemy.open_amount * deg_to_rad(150.0)
	var w := W * cos(ang)
	var grow := 3.0 * sin(ang)
	var far := hx + w
	var cover := PackedVector2Array([
		Vector2(hx, top), Vector2(far, top - grow), Vector2(far, -top + grow), Vector2(hx, -top),
	])
	var cover_out := PackedVector2Array([
		Vector2(hx - 1.0, top - 1.0), Vector2(far + signf(w) * 1.0, top - grow - 1.0),
		Vector2(far + signf(w) * 1.0, -top + grow + 1.0), Vector2(hx - 1.0, -top + 1.0),
	])
	if absf(w) > 0.5:
		draw_colored_polygon(cover_out, outline)
		draw_colored_polygon(cover, _col(COVER if w > 0.0 else COVER_DARK))
	else:
		draw_line(Vector2(hx, top - grow), Vector2(hx, -top + grow), outline, 2.0)
	# 책등 금띠
	draw_rect(Rect2(hx - 1.5, top + 3.0, 3.0, 2.0), _col(GOLD))
	draw_rect(Rect2(hx - 1.5, -top - 5.0, 3.0, 2.0), _col(GOLD))
	if w > 4.0:
		var sx := w / W
		# 금 모서리
		draw_rect(Rect2(far - 3.0 * sx, top - grow, 3.0 * sx, 3.0), _col(GOLD))
		draw_rect(Rect2(far - 3.0 * sx, -top + grow - 3.0, 3.0 * sx, 3.0), _col(GOLD))
		if not _white:
			draw_line(Vector2(hx + 1.0, top + 1.5), Vector2(far - 1.0, top - grow + 1.5), COVER_LIGHT, 1.0)
		# 외눈
		_eye(Vector2(hx + w * 0.52, 0.0), sx, closed, windup or st == Grimoire.S.VOLLEY)
		# 덮였을 때 금 걸쇠 + 사슬
		if closed:
			draw_rect(Rect2(far - 2.0, -3.0, 4.0, 6.0), _col(GOLD))
			if not _white:
				draw_rect(Rect2(far - 1.0, -1.0, 2.0, 2.0), Grimoire.MANA)
				for i in 4:
					var cy := top + 3.0 + i * 8.5
					draw_rect(Rect2(hx + 2.0, cy, w - 4.0, 1.5), Color("#8a8aa0"))


## 표지의 외눈. sx = 표지가 보이는 너비 비율 (열릴수록 납작해짐)
func _eye(c: Vector2, sx: float, shut: bool, angry: bool) -> void:
	var t := enemy._t
	if shut:
		# 꽉 감은 눈 + 찡그린 눈썹
		draw_line(c + Vector2(-6.0 * sx, 0), c + Vector2(6.0 * sx, 0), _col(Palette.OUTLINE), 1.5)
		draw_line(c + Vector2(-6.0 * sx, -5), c + Vector2(5.0 * sx, -3), _col(Palette.OUTLINE), 1.0)
		return
	var blink := fmod(t, 3.1) < 0.12 and not angry
	draw_set_transform(c, 0.0, Vector2(maxf(sx, 0.15), 1.0))
	draw_circle(Vector2.ZERO, 8.0, _col(Palette.OUTLINE))
	if blink:
		draw_circle(Vector2.ZERO, 7.0, _col(COVER))
		draw_line(Vector2(-6, 0), Vector2(6, 0), _col(Palette.OUTLINE), 1.0)
	else:
		draw_circle(Vector2.ZERO, 7.0, _col(EYE_WHITE))
		var iris := Grimoire.MANA.lerp(Palette.DANGER, 1.0 if angry else 0.0)
		# 세라 쪽을 본다 (그림은 오른쪽 기준이라 앞쪽 = +x)
		var look := Vector2(1.6, 0.0)
		var p := enemy.player()
		if p:
			var d := (p.center() - enemy.center()).normalized()
			look = Vector2(absf(d.x) * 2.4, d.y * 2.4)
		draw_circle(look, 4.0, _col(iris))
		draw_rect(Rect2(look + Vector2(-1.0, -2.8), Vector2(2.0, 5.6)), _col(Palette.OUTLINE))
		if not _white:
			draw_rect(Rect2(look + Vector2(-2.0, -2.5), Vector2(1.2, 1.2)), Color.WHITE)
		if angry:
			# 성난 눈꺼풀
			draw_rect(Rect2(-8.0, -8.0, 16.0, 3.5), _col(COVER))
			draw_line(Vector2(-7, -4.5), Vector2(7, -2.5), _col(Palette.OUTLINE), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
