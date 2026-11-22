## board_pieces.gd — 전투 시험판 v2 「맡기기」 화면 조각 (scenes/board_battle.gd 가 만든다). 모두 코드로 그린다 — 새 그림 없음.
##  · EnemyCard: ① 적 카드(검은 틀 · 광신도·무덤지기 그림을 잘라 넣음 · HP = 검은 봉인 + 숫자). 하수인(해골 병사)은 뼈색 테두리 + 코드로 그린 해골.
##               쓰러지면 뒷면(card_back.png). SummonGhost: 강적이 하수인을 부르는 중 — 하수인이 나올 자리(강적 앞)에 점선 윤곽
##  · ActCard: ② 적 행동 카드(가로로 낮은 카드 · 보낸 적의 작은 얼굴). '모두' 공격은 세 칸을 가로지르는 긴 카드
##  · PlacedCard: ③ 맡긴 카드(가로로 낮은 카드 · 특성·버프가 붙은 결과 숫자 · 대상 적의 작은 얼굴)
##  · AllyCard: ④ 동료 초상 카드(스탠딩의 얼굴~가슴 · 노려지면 놀란 표정 · 붉은 봉인 HP · 특성 · 막기 · 옆에 버팀/배율)
##  · NoelTag: 노엘이 ②·①·④ 에 직접 놓은 카드(운명 전가·저주·취약·축복)의 작은 표
## 누르기·끌기는 BoardBattle 이 자리(Rect2)로 판단한다 — 조각은 모두 마우스를 통과시킨다.
class_name BoardPieces
extends Object

const GOLD := Color("#e0b862")
const BONE := Color("#d9ccae")

static var _grad_bottom: Texture2D = null
static var _tex := {}


## _draw 안에서 그리는 그림은 참조를 잡아 둔다 — 그리는 함수의 지역 변수로만 들고 있으면 그린 뒤 바로 메모리에서 내려가 흰 사각형이 된다
static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = Assets.tex(name)
	return _tex[name]


static func grad_bottom() -> Texture2D:
	if _grad_bottom == null:
		_grad_bottom = UI.grad([[0, Color(0, 0, 0, 0)], [0.45, Color(0.02, 0.01, 0.01, 0.72)], [1, Color(0.02, 0.0, 0.01, 0.96)]], "v", 4, 64)
	return _grad_bottom


## 글자를 상자 안에(가로 정렬 · 세로 가운데). 줄바꿈(\n)이 있으면 줄마다
static func text_in(ci: CanvasItem, r: Rect2, s: String, size: int, col: Color, font := "sans_bold", align := HORIZONTAL_ALIGNMENT_CENTER, outline := 0) -> void:
	var f := Assets.font(font)
	var lines := s.split("\n")
	var lh := f.get_height(size)
	var y := r.position.y + (r.size.y - lh * lines.size()) / 2.0 + f.get_ascent(size)
	for ln in lines:
		if outline > 0:
			ci.draw_string_outline(f, Vector2(r.position.x, y), ln, align, r.size.x, size, outline, Color(0, 0, 0, 0.85))
		ci.draw_string(f, Vector2(r.position.x, y), ln, align, r.size.x, size, col)
		y += lh


## 밀랍 봉인 (HP): 물결진 가장자리 + 안쪽 둥근 판 + 숫자. 동료는 붉은 봉인, 적은 검은 봉인
static func seal(ci: CanvasItem, c: Vector2, r: float, base: Color, num: String, size: int, sub := "") -> void:
	var pts := PackedVector2Array()
	var sh := PackedVector2Array()
	for i in 30:
		var a := TAU * i / 30.0
		var k := 1.0 + 0.065 * sin(a * 5.0 + 0.7) + 0.035 * sin(a * 13.0 + 1.3)
		pts.append(c + Vector2(cos(a), sin(a)) * r * k)
		sh.append(c + Vector2(2, 4) + Vector2(cos(a), sin(a)) * r * k)
	ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.55))
	ci.draw_colored_polygon(pts, base)
	ci.draw_circle(c, r * 0.76, base.darkened(0.28))
	ci.draw_arc(c, r * 0.76, 0, TAU, 40, Color(base.lightened(0.35), 0.55), 2.0, true)
	ci.draw_arc(c + Vector2(-r * 0.12, -r * 0.12), r * 0.5, PI * 1.05, PI * 1.55, 12, Color(1, 1, 1, 0.16), 3.0, true)
	var f := Assets.font("serif_black")
	var y := c.y + f.get_ascent(size) / 2.0 - (5.0 if sub != "" else 2.0)
	ci.draw_string_outline(f, Vector2(c.x - r, y), num, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, 6, Color(0, 0, 0, 0.7))
	ci.draw_string(f, Vector2(c.x - r, y), num, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, Color("#fbf1ea"))
	if sub != "":
		var fs := Assets.font("sans_bold")
		ci.draw_string(fs, Vector2(c.x - r, y + 16), sub, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 13, Color(1, 0.92, 0.9, 0.8))


## 고를 수 있음(금빛) 테두리 빛
static func glow_border(ci: CanvasItem, r: Rect2, col: Color, k: float, radius := 10) -> void:
	if k <= 0.0:
		return
	var sb := UI.box(Color(0, 0, 0, 0), Color(col.r, col.g, col.b, 0.3 * minf(1.0, k)), radius + 6, 7)
	sb.draw_center = false
	ci.draw_style_box(sb, r.grow(5))
	var sb2 := UI.box(Color(0, 0, 0, 0), Color(col.r, col.g, col.b, 0.95 * minf(1.0, k)), radius, 3 if k < 1.5 else 5)
	sb2.draw_center = false
	ci.draw_style_box(sb2, r)


## 방패 모양 (막기 수치)
static func shield(ci: CanvasItem, c: Vector2, s: float, num: String) -> void:
	var pts := PackedVector2Array([c + Vector2(-s, -s * 0.9), c + Vector2(s, -s * 0.9), c + Vector2(s * 0.92, s * 0.2), c + Vector2(0, s * 1.1), c + Vector2(-s * 0.92, s * 0.2)])
	ci.draw_colored_polygon(pts, Color("#3c434b"))
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, Color("#a9b4bf"), 2.5, true)
	var f := Assets.font("serif_black")
	ci.draw_string_outline(f, Vector2(c.x - s, c.y + 9), num, HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, 26, 5, Color(0, 0, 0, 0.8))
	ci.draw_string(f, Vector2(c.x - s, c.y + 9), num, HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, 26, Color.WHITE)


static func _shadow(ci: CanvasItem, r: Rect2, radius := 12) -> void:
	ci.draw_style_box(UI.box(Color(0, 0, 0, 0.5), Color.TRANSPARENT, radius), Rect2(r.position + Vector2(3, 7), r.size))


## 적의 작은 얼굴(②·③ 카드): 광신도·무덤지기는 그림에서 얼굴을 잘라, 해골 병사는 코드로 그린 해골. tag(A·B)는 오른쪽 아래에
static func enemy_face(ci: CanvasItem, r: Rect2, type: String, tag := "") -> void:
	var E: Dictionary = BattleV2Data.D.enemies.get(type, {})
	ci.draw_style_box(UI.box(Color("#0b0809"), BONE if E.get("isMinion", false) else Color("#5a1a22"), 6, 2), r)
	var inner := r.grow(-3)
	if str(E.get("sprite", "")) != "" and E.has("face"):
		var fc: Array = E.face
		ci.draw_texture_rect_region(BoardPieces.tex(str(E.sprite)), inner, Rect2(fc[0], fc[1], fc[2], fc[3]))
	else:
		Icons.draw(ci, "skull", inner.get_center() + Vector2(0, inner.size.y * 0.04), inner.size.y * 0.46, BONE)
	if tag != "":
		var tr := Rect2(r.end.x - 20, r.end.y - 20, 20, 20)
		ci.draw_style_box(UI.box(Color(0.1, 0.02, 0.03, 0.95), Color("#ff6b76"), 4, 1), tr)
		text_in(ci, tr, tag, 15, Color.WHITE, "serif_black")


## 카드 그림 조각(③·노엘 표의 작은 그림). art "" 이면 코드로 그린 빛(축복)
static func art_thumb(ci: CanvasItem, r: Rect2, art: String, dark := false) -> void:
	if art != "" and Assets.ok(art):
		var t := BoardPieces.tex(art)
		var s := t.get_size()
		var h := s.x * r.size.y / r.size.x
		ci.draw_texture_rect_region(t, r, Rect2(0, (s.y - minf(h, s.y)) * 0.42, s.x, minf(h, s.y)), Color(0.62, 0.58, 0.6) if dark else Color.WHITE)
	else:
		bless_art(ci, r)


## 축복(그림 없음): 어두운 바탕에 금빛 빛살과 둥근 빛
static func bless_art(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color("#1a1208"))
	var c := r.get_center()
	var rr := minf(r.size.x, r.size.y)
	for i in 12:
		var a := TAU * i / 12.0
		ci.draw_line(c + Vector2.from_angle(a) * rr * 0.16, c + Vector2.from_angle(a) * rr * (0.42 if i % 2 == 0 else 0.32), Color(1, 0.86, 0.5, 0.7), maxf(1.5, rr * 0.03), true)
	ci.draw_circle(c, rr * 0.15, Color(1, 0.92, 0.66, 0.95))
	ci.draw_arc(c, rr * 0.22, 0, TAU, 32, Color(1, 0.8, 0.4, 0.6), maxf(1.0, rr * 0.02), true)


# ───────── ① 적 카드 ─────────
class EnemyCard extends Control:
	var eid := ""
	var type := ""
	var title := ""
	var hp := 0
	var max_hp := 0
	var alive := true
	var minion := false
	var pick := 0.0        # 1: 고를 수 있음(금빛) · 2: 손가락이 올라감
	var link := false      # 이 적의 행동 카드에 마우스를 올렸다
	var back: Texture2D

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		BoardPieces._shadow(self, r)
		if not alive:
			if back != null:
				draw_texture_rect(back, r, false, Color(0.5, 0.44, 0.46))
			return
		var E: Dictionary = BattleV2Data.D.enemies[type]
		draw_style_box(UI.box(Color("#0b0809"), BoardPieces.BONE if minion else Color("#3a0c12"), 10, 3 if minion else 2), r)
		var img := Rect2(6, 36, size.x - 12, size.y - 42)
		if str(E.get("sprite", "")) != "":
			var c: Array = E.crop
			var src := Rect2(c[0], c[1], c[2], c[3])
			# 창 비율에 맞춰 위쪽(머리)부터 자른다
			var want := src.size.x * img.size.y / img.size.x
			if want < src.size.y:
				src.size.y = want
			else:
				var w2 := src.size.y * img.size.x / img.size.y
				src.position.x += (src.size.x - w2) / 2.0
				src.size.x = w2
			draw_texture_rect_region(BoardPieces.tex(str(E.sprite)), img, src)
		else:
			# 하수인(그림 없음): 코드로 그린 해골 + 녹슨 칼
			draw_rect(img, Color("#16110d"))
			Icons.draw(self, "sword", img.get_center() + Vector2(0, img.size.y * 0.12), img.size.y * 0.42, Color("#7a5a3a"))
			Icons.draw(self, "skull", img.get_center() + Vector2(0, -img.size.y * 0.06), img.size.x * 0.36, BoardPieces.BONE)
		draw_texture_rect(BoardPieces.grad_bottom(), Rect2(img.position.x, img.end.y - 40, img.size.x, 40), false)
		draw_rect(Rect2(4, 4, size.x - 8, 32), Color(0.03, 0.01, 0.015, 0.96))
		BoardPieces.text_in(self, Rect2(40, 4, size.x - 44, 32), title, 19 if not minion else 17, Color("#e6d6d2"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
		BoardPieces.seal(self, Vector2(18, 18), 26 if minion else 28, Color("#1d1517"), str(hp), 24 if minion else 27)
		if link:
			BoardPieces.glow_border(self, r, Color("#ff5a66"), 0.8)
		BoardPieces.glow_border(self, r, BoardPieces.GOLD, pick)


## 강적이 하수인을 부르는 중: 하수인이 나올 자리에 점선 윤곽 + 해골 + 「해골 병사 부르기」
class SummonGhost extends Control:
	var label := ""
	var sub := ""
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(UI.box(Color(0.05, 0.03, 0.03, 0.78), Color.TRANSPARENT, 10), r)
		var a := 0.55 + 0.25 * sin(_t * 3.0)
		var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		for i in 4:
			draw_dashed_line(pts[i], pts[i + 1], Color(BoardPieces.BONE, a), 2.0, 9.0)
		Icons.draw(self, "skull", Vector2(size.x / 2.0, size.y * 0.36), size.x * 0.22, Color(BoardPieces.BONE, 0.5))
		BoardPieces.text_in(self, Rect2(4, size.y * 0.58, size.x - 8, size.y * 0.22), label, 16, Color("#f0e2cc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
		BoardPieces.text_in(self, Rect2(4, size.y * 0.78, size.x - 8, size.y * 0.18), sub, 13, Color("#bfae98"), "sans", HORIZONTAL_ALIGNMENT_CENTER, 2)


# ───────── ② 적 행동 카드 ─────────
class ActCard extends Control:
	var eid := ""
	var type := ""
	var tag := ""
	var kind := "hit"
	var value := 0
	var minus := 0
	var slot := ""
	var label := ""
	var all_text := ""
	var movable := 0.0     # 1: 놓을 수 있음(노엘 카드를 끄는 중) · 2: 손가락이 올라감 · 옮기는 중
	var link := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		BoardPieces._shadow(self, r, 8)
		draw_style_box(UI.box(Color("#1c070a"), Color("#8e1220"), 8, 2), r)
		var f := Assets.font("serif_black")
		var v := maxi(0, value - minus)
		var vcol := Color("#ff4b5a") if minus == 0 else Color("#c9a0ff")
		if kind == "sweep":
			var fr := Rect2(5, 3, size.y - 6, size.y - 6)
			BoardPieces.enemy_face(self, fr, type, tag)
			BoardPieces.enemy_face(self, Rect2(size.x - size.y + 1, 3, size.y - 6, size.y - 6), type, tag)
			var s := "%s  %d  —  %s" % [label, v, all_text]
			if minus > 0:
				s = "%s  %d(-%d)  —  %s" % [label, v, minus, all_text]
			BoardPieces.text_in(self, Rect2(0, 0, size.x, size.y), s, 22, Color("#ffd9dc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
		else:
			# 왼쪽부터 [보낸 적의 얼굴][피해][이름] — 한 칸에 겹쳐 쌓여 오른쪽이 가려져도 누가 얼마나 치는지는 보인다
			BoardPieces.enemy_face(self, Rect2(5, 5, size.y - 10, size.y - 10), type, tag)
			var vx := size.y + 2
			var vs := str(v)
			draw_string_outline(f, Vector2(vx, size.y / 2.0 + 14), vs, HORIZONTAL_ALIGNMENT_CENTER, 46, 38, 6, Color(0, 0, 0, 0.8))
			draw_string(f, Vector2(vx, size.y / 2.0 + 14), vs, HORIZONTAL_ALIGNMENT_CENTER, 46, 38, vcol)
			var lab := label if minus == 0 else "%s (-%d)" % [label, minus]
			BoardPieces.text_in(self, Rect2(vx + 50, 0, size.x - vx - 54, size.y), lab, 18, Color("#f0d8da"), "sans_bold", HORIZONTAL_ALIGNMENT_LEFT, 2)
		if link:
			BoardPieces.glow_border(self, r, Color("#ff5a66"), 0.8, 8)
		BoardPieces.glow_border(self, r, BoardPieces.GOLD, movable, 8)


# ───────── ③ 맡긴 카드 ─────────
class PlacedCard extends Control:
	var uid := ""
	var card_id := ""
	var ally := ""
	var title := ""
	var line := ""         # 특성·버프가 붙은 결과: 「피해 14」·「막기 7 · 반격 3」·「배율 ×3」
	var target_type := ""  # 공격이 들어갈 적의 종류(작은 얼굴) · "" 없음
	var target_tag := ""
	var pending := false   # 대상을 고르는 중
	var hot := false
	var act := 0.0
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if pending:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		BoardPieces._shadow(self, r, 8)
		draw_style_box(UI.box(Color("#140c0f"), Color("#8a6a3a"), 8, 2), r)
		var d: Dictionary = BattleV2Data.D.cards.get(card_id, {})
		BoardPieces.art_thumb(self, Rect2(4, 4, 40, size.y - 8), str(d.get("art", "")), bool(d.get("dark", false)))
		var x := 52.0
		var right := 50.0 if target_type != "" else 8.0
		BoardPieces.text_in(self, Rect2(x, 2, size.x - x - right, size.y * 0.5), title, 18, Color("#f4ead6"), "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, 3)
		BoardPieces.text_in(self, Rect2(x, size.y * 0.46, size.x - x - right + 6, size.y * 0.52), line, 16, Color("#ffcf6a"), "sans_bold", HORIZONTAL_ALIGNMENT_LEFT, 3)
		if target_type != "":
			var fr := Rect2(size.x - 46, 6, 40, size.y - 12)
			BoardPieces.enemy_face(self, fr, target_type, target_tag)
		if pending:
			BoardPieces.glow_border(self, r, Color("#ff5a66"), 0.55 + 0.45 * sin(_t * 6.0), 8)
		elif hot:
			BoardPieces.glow_border(self, r, BoardPieces.GOLD, 1.0, 8)
		BoardPieces.glow_border(self, r, Color.WHITE, act, 8)


# ───────── 노엘이 직접 놓은 카드의 표 (② 적 행동 · ① 적 · ④ 동료 위) ─────────
class NoelTag extends Control:
	var index := 0
	var card_id := ""
	var text := ""
	var hot := false
	var pending := false
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if pending:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		BoardPieces._shadow(self, r, 6)
		draw_style_box(UI.box(Color("#1d0c1c"), Color("#c79ab0"), 6, 2), r)
		var d: Dictionary = BattleV2Data.D.cards.get(card_id, {})
		BoardPieces.art_thumb(self, Rect2(3, 3, size.y - 6, size.y - 6), str(d.get("art", "")), bool(d.get("dark", false)))
		BoardPieces.text_in(self, Rect2(size.y + 2, 0, size.x - size.y - 6, size.y), text, 16, Color("#f3dcec"), "sans_bold", HORIZONTAL_ALIGNMENT_LEFT, 3)
		if pending:
			BoardPieces.glow_border(self, r, Color("#ff5a66"), 0.55 + 0.45 * sin(_t * 6.0), 6)
		elif hot:
			BoardPieces.glow_border(self, r, BoardPieces.GOLD, 1.0, 6)


# ───────── ④ 동료 초상 카드 ─────────
class AllyCard extends Control:
	var aid := ""
	var title := ""
	var trait_name := ""
	var trait_text := ""
	var color := Color.WHITE
	var hp := 0
	var max_hp := 0
	var block := 0
	var down := false
	var shocked := false
	var drop := 0.0        # 1: 놓을 수 있음 · 2: 끄는 카드가 이 칸 위
	var act := 0.0         # 행동하는 순간 빛
	var calm: Texture2D
	var shock: Texture2D
	var crop := Rect2()
	var down_text := ""
	var status_label := ""   # 초상 옆: 「버팀」·「배율」
	var status_value := ""   # 「7」·「×3」
	var status_rect := Rect2()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		BoardPieces._shadow(self, r)
		draw_style_box(UI.box(Color("#0e0a0b"), Color(color, 0.75), 10, 2), r)
		var img := Rect2(5, 5, size.x - 10, size.y - 10)
		var t: Texture2D = shock if shocked and not down and shock != null else calm
		if t != null:
			draw_texture_rect_region(t, img, crop, Color(0.42, 0.4, 0.41) if down else Color.WHITE)
		draw_texture_rect(BoardPieces.grad_bottom(), Rect2(img.position.x, img.end.y - 128, img.size.x, 128), false)
		BoardPieces.text_in(self, Rect2(16, size.y - 122, size.x - 32, 32), title, 26, Color("#f6e7c8"), "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, 4)
		BoardPieces.text_in(self, Rect2(16, size.y - 90, size.x - 32, 26), trait_name, 19, Color("#ffcf6a"), "sans_bold", HORIZONTAL_ALIGNMENT_LEFT, 3)
		BoardPieces.text_in(self, Rect2(16, size.y - 62, size.x - 22, 52), trait_text, 14, Color("#e4d6cc"), "sans", HORIZONTAL_ALIGNMENT_LEFT, 2)
		BoardPieces.seal(self, Vector2(26, 26), 32, Color("#8e1220"), str(hp), 28, "/" + str(max_hp))
		if block > 0:
			BoardPieces.shield(self, Vector2(size.x - 30, 34), 24, str(block))
		if down:
			draw_set_transform(size / 2.0, deg_to_rad(-12), Vector2.ONE)
			var sr := Rect2(-104, -30, 208, 60)
			draw_style_box(UI.box(Color(0.12, 0.0, 0.02, 0.85), Color("#ff4b5a"), 6, 3), sr)
			BoardPieces.text_in(self, sr, down_text, 34, Color("#ff6b76"), "serif_black", HORIZONTAL_ALIGNMENT_CENTER, 4)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		elif shocked:
			draw_style_box(UI.box(Color(0, 0, 0, 0), Color(1, 0.2, 0.26, 0.55), 10, 2), r.grow(-3))
		BoardPieces.glow_border(self, r, Color.WHITE, act)
		BoardPieces.glow_border(self, r, BoardPieces.GOLD, drop)
		# 초상 옆: 브룬힐드 버팀 · 엘리안 배율 (늘 보인다)
		if status_label != "":
			var sr2 := status_rect
			BoardPieces._shadow(self, sr2, 8)
			draw_style_box(UI.box(Color(0.05, 0.03, 0.03, 0.92), Color(color, 0.8), 8, 2), sr2)
			BoardPieces.text_in(self, Rect2(sr2.position.x, sr2.position.y + 4, sr2.size.x, 24), status_label, 17, Color("#e4d6cc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 2)
			BoardPieces.text_in(self, Rect2(sr2.position.x, sr2.position.y + 28, sr2.size.x, sr2.size.y - 32), status_value, 34, Color("#ffcf6a"), "serif_black", HORIZONTAL_ALIGNMENT_CENTER, 4)
