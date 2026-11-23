## board_pieces.gd — 전투 시험판 v2.1 「3D 탁자」 카드 앞면 그리기 (한 곳). 탁자의 3D 카드(ui/board_table.gd)·손패 카드(ui/board_hand.gd)·크게 보기(scenes/board_battle.gd)가
## 모두 draw_face() 하나로 같은 앞면을 그린다. 카드는 240×360(2:3) 기준 좌표를 r 의 크기에 맞춰 늘려 그린다.
## 카드 틀: 그림체 F 카드 틀 3종(art/raw/vs_f/76 → tools/vs_f_import.py → card_frame_f_*.png)을 frame() 한 곳에서 그린다.
##   틀 비율(약 0.6)을 카드 비율(2:3)에 맞춰 가로로 조금 늘려 그린다(DECISIONS.md). 틀 파일이 없으면 코드 테두리.
##   틀 안쪽 그림 자리(투명)에 카드 그림을 먼저 깔고, 아래쪽 이름 띠에 이름을 넣는다. 같은 이름의 파일만 바꾸면 새 틀이 된다.
## 앞면 종류(f.kind): mine(손패·맡긴 카드·노엘 카드) · enemy · minion · act(적 행동) · death(죽음 카드) · ally(동료 초상) · dead(죽은 동료 — 뒤집힌 면) · note(설명) · slot(빈칸)
## 한 칸에 여러 장을 옆으로 겹치면(A안) 뒤 카드는 왼쪽 띠만 보인다 → 숫자(왼쪽 위 봉인·보석)와 이름(왼쪽 정렬)이 왼쪽 띠에 오게 그린다.
class_name BoardPieces
extends Object

const GOLD := Color("#e0b862")
const BONE := Color("#d9ccae")
const CW := 240.0
const CH := 360.0
# 카드 기준 좌표(240×360 의 비율): 그림 창 · 이름 띠 글자 자리 · 왼쪽 위 봉인
const ART := Rect2(0.075, 0.05, 0.85, 0.765)
const NAME := Rect2(0.19, 0.826, 0.67, 0.118)
const BADGE := Vector2(0.175, 0.125)

const FRAMES := {"ally": "card_frame_f_ally.png", "enemy": "card_frame_f_enemy.png", "minion": "card_frame_f_minion.png"}

static var _grad_bottom: Texture2D = null
static var _tex := {}


## _draw 안에서 그리는 그림은 참조를 잡아 둔다 — 그리는 함수의 지역 변수로만 들고 있으면 그린 뒤 바로 메모리에서 내려가 흰 사각형이 된다
static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = Assets.tex(name) if Assets.ok(name) else null
	return _tex[name]


## 후보 가운데 처음으로 있는 파일 ("" = 없음)
static func first_file(list: Array) -> String:
	for f in list:
		if Assets.ok(str(f)):
			return str(f)
	return ""


## 새 전투의 카드 뒷면(BattleV2Data cardBack — 그림체 F 82, 없으면 옛 뒷면)
static func back_tex() -> Texture2D:
	return tex(first_file(BattleV2Data.D.cardBack))


static func grad_bottom() -> Texture2D:
	if _grad_bottom == null:
		_grad_bottom = UI.grad([[0, Color(0, 0, 0, 0)], [0.45, Color(0.02, 0.01, 0.01, 0.72)], [1, Color(0.02, 0.0, 0.01, 0.96)]], "v", 4, 64)
	return _grad_bottom


## 적 그림: data enemies[type].art 의 후보 중 파일이 있는 것 → {tex, crop: Rect2(픽셀), face: Rect2(픽셀)} · 없으면 {}
static func enemy_art(type: String) -> Dictionary:
	var E: Dictionary = BattleV2Data.D.enemies.get(type, {})
	for a in E.get("art", []):
		var t := tex(str(a.file))
		if t == null:
			continue
		var s := t.get_size()
		var c: Array = a.crop
		var f: Array = a.face
		return {"tex": t, "crop": Rect2(c[0] * s.x, c[1] * s.y, c[2] * s.x, c[3] * s.y), "face": Rect2(f[0] * s.x, f[1] * s.y, f[2] * s.x, f[3] * s.y)}
	return {}


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


## 상자 너비에 맞게 글자 크기를 줄인다
static func fit_size(s: String, font: String, size: int, max_w: float) -> int:
	var f := Assets.font(font)
	var k := size
	for ln in s.split("\n"):
		while k > 8 and f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, k).x > max_w:
			k -= 1
	return k


## 밀랍 봉인 (HP): 물결진 가장자리 + 안쪽 둥근 판 + 숫자. 동료는 붉은 봉인, 적은 검은 봉인
static func seal(ci: CanvasItem, c: Vector2, r: float, base: Color, num: String, size: int, sub := "") -> void:
	var pts := PackedVector2Array()
	var sh := PackedVector2Array()
	for i in 30:
		var a := TAU * i / 30.0
		var k := 1.0 + 0.065 * sin(a * 5.0 + 0.7) + 0.035 * sin(a * 13.0 + 1.3)
		pts.append(c + Vector2(cos(a), sin(a)) * r * k)
		sh.append(c + Vector2(r * 0.06, r * 0.12) + Vector2(cos(a), sin(a)) * r * k)
	ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.55))
	ci.draw_colored_polygon(pts, base)
	ci.draw_circle(c, r * 0.76, base.darkened(0.28))
	ci.draw_arc(c, r * 0.76, 0, TAU, 40, Color(base.lightened(0.35), 0.55), maxf(1.0, r * 0.06), true)
	var f := Assets.font("serif_black")
	var y := c.y + f.get_ascent(size) / 2.0 - (r * 0.16 if sub != "" else r * 0.06)
	ci.draw_string_outline(f, Vector2(c.x - r, y), num, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, maxi(2, int(size * 0.2)), Color(0, 0, 0, 0.7))
	ci.draw_string(f, Vector2(c.x - r, y), num, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, Color("#fbf1ea"))
	if sub != "":
		var fs := Assets.font("sans_bold")
		var ss := maxi(8, int(size * 0.46))
		ci.draw_string(fs, Vector2(c.x - r, y + ss * 1.15), sub, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, ss, Color(1, 0.92, 0.9, 0.85))


## 행동 에너지 보석(비용): 붉은 마름모 + 숫자
static func gem(ci: CanvasItem, c: Vector2, r: float, num: String, size: int) -> void:
	var p := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.8, -r * 0.2)])
	var sh := PackedVector2Array()
	for q in p:
		sh.append(q + Vector2(r * 0.06, r * 0.12))
	ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.6))
	ci.draw_colored_polygon(p, Color("#b3121f"))
	var loop := p.duplicate()
	loop.append(p[0])
	ci.draw_polyline(loop, Color("#ff8a94"), maxf(1.0, r * 0.08), true)
	var f := Assets.font("serif_black")
	var y := c.y + f.get_ascent(size) / 2.0 - r * 0.1
	ci.draw_string_outline(f, Vector2(c.x - r, y), num, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, maxi(2, int(size * 0.2)), Color(0, 0, 0, 0.8))
	ci.draw_string(f, Vector2(c.x - r, y), num, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, Color.WHITE)


## 고를 수 있음(금빛) 테두리 빛 — 2D 겹침용
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
	ci.draw_polyline(loop, Color("#a9b4bf"), maxf(1.0, s * 0.1), true)
	var f := Assets.font("serif_black")
	var fs := int(s * 1.05)
	ci.draw_string_outline(f, Vector2(c.x - s, c.y + fs * 0.36), num, HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, fs, maxi(2, int(fs * 0.2)), Color(0, 0, 0, 0.8))
	ci.draw_string(f, Vector2(c.x - s, c.y + fs * 0.36), num, HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, fs, Color.WHITE)


## 해골 표시(죽음 카드)
static func skull(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	Icons.draw(ci, "skull", c, s, col)


## 그림을 상자에 꽉 차게(넘치는 쪽을 가운데에서 자름). src: 그림에서 쓸 영역(없으면 전체)
static func cover(ci: CanvasItem, t: Texture2D, r: Rect2, src := Rect2(), mod := Color.WHITE, top := false) -> void:
	if t == null:
		return
	var s := src if src.size != Vector2.ZERO else Rect2(Vector2.ZERO, t.get_size())
	var want := r.size.x / r.size.y
	if s.size.x / s.size.y > want:
		var w := s.size.y * want
		s.position.x += (s.size.x - w) / 2.0
		s.size.x = w
	else:
		var h := s.size.x / want
		s.position.y += 0.0 if top else (s.size.y - h) * 0.42
		s.size.y = h
	ci.draw_texture_rect_region(t, r, s, mod)


## 카드 틀(그림체 F) — kind: ally(동료·노엘 카드) · enemy(적·적 행동) · minion(하수인). 틀이 없으면 코드 테두리
static func frame(ci: CanvasItem, r: Rect2, kind: String, mod := Color.WHITE) -> void:
	var t := tex(str(FRAMES.get(kind, "")))
	if t != null:
		ci.draw_texture_rect(t, r, false, mod)
		return
	var col: Color = {"ally": Color("#b89a6a"), "enemy": Color("#6a1a20"), "minion": BONE}.get(kind, Color("#888888"))
	var s := r.size.x / CW
	var sb := UI.box(Color(0, 0, 0, 0), col, int(14 * s), maxi(2, int(5 * s)))
	sb.draw_center = false
	ci.draw_style_box(sb, r)
	ci.draw_rect(_rr(r, NAME).grow(4 * s), Color(col.darkened(0.5), 0.95))


static func _rr(r: Rect2, k: Rect2) -> Rect2:
	return Rect2(r.position + Vector2(k.position.x * r.size.x, k.position.y * r.size.y), Vector2(k.size.x * r.size.x, k.size.y * r.size.y))


static func _pt(r: Rect2, k: Vector2) -> Vector2:
	return r.position + Vector2(k.x * r.size.x, k.y * r.size.y)


## 이름 띠: 왼쪽 정렬(겹친 카드의 왼쪽 띠에서도 앞 글자가 보이게). 길면 줄인다. right: 띠 오른쪽의 작은 글자(특성 등)
static func name_band(ci: CanvasItem, r: Rect2, name: String, col: Color, right := "", rcol := GOLD, dark_band := false, size := 21) -> void:
	var s := r.size.x / CW
	var nr := _rr(r, NAME)
	var rw := 0.0
	if right != "":
		var fsr := int(13 * s)
		rw = Assets.font("sans_bold").get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, fsr).x + 6 * s
		text_in(ci, Rect2(nr.end.x - rw, nr.position.y, rw, nr.size.y), right, fsr, rcol, "sans_bold", HORIZONTAL_ALIGNMENT_RIGHT, maxi(1, int(2 * s)))
	var fs := fit_size(name, "serif_bold", int(size * s), nr.size.x - rw - 2 * s)
	var ink := col if dark_band else col
	text_in(ci, Rect2(nr.position, Vector2(nr.size.x - rw, nr.size.y)), name, fs, ink, "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, maxi(1, int(3 * s)))


## 설명 글자가 들어가는 가로 자리(카드 너비 비율): 카드 틀(그림체 F 76) 안쪽의 투명한 곳만 — 틀의 가시·장식이 그림 창 안으로 들어와
## 예전 자리(그림 창 너비)에서는 설명 양끝이 가려졌다(밤샘 계획 2 D). 틀 그림의 안쪽을 재어 정함: 동료 틀은 y 0.58~0.72 에서 x 0.165~0.815 가 비고(조금 더 안쪽 0.18~0.82)
## 그 아래(0.74~)는 안으로 좁아진다 → 글자는 bottom(동료 틀 0.735 · 적 틀 0.765) 위에만
const DESC_X := Vector2(0.18, 0.82)


## 그림 창 아래쪽 설명(어두운 그라디언트 위). top: 그라디언트가 시작하는 높이(카드 높이 비율) · bottom: 글자 아래 끝(틀이 좁아지기 전)
static func desc(ci: CanvasItem, r: Rect2, s_txt: String, top := 0.58, size := 15, bottom := 0.735) -> void:
	if s_txt == "":
		return
	var s := r.size.x / CW
	var ar := _rr(r, ART)
	var gy := r.position.y + top * r.size.y
	ci.draw_texture_rect(grad_bottom(), Rect2(ar.position.x, gy, ar.size.x, ar.end.y - gy), false)
	var tr := Rect2(r.position.x + DESC_X.x * r.size.x, gy + 0.015 * r.size.y, (DESC_X.y - DESC_X.x) * r.size.x, (bottom - top - 0.015) * r.size.y)
	var fs := fit_size(s_txt, "sans_bold", int(size * s), tr.size.x)
	text_in(ci, tr, s_txt, fs, Color("#efe5d6"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(2 * s)))


## 적의 작은 얼굴(맡긴 카드의 대상 등): 그림에서 얼굴만, 해골 병사는 코드 해골. tag(A·B)는 오른쪽 아래에
static func enemy_face(ci: CanvasItem, r: Rect2, type: String, tag := "") -> void:
	var E: Dictionary = BattleV2Data.D.enemies.get(type, {})
	var s := r.size.x / 40.0
	ci.draw_style_box(UI.box(Color("#0b0809"), BONE if E.get("isMinion", false) else Color("#7a1a22"), int(6 * s), maxi(1, int(2 * s))), r)
	var inner := r.grow(-2 * s)
	var ea := enemy_art(type)
	if not ea.is_empty():
		cover(ci, ea.tex, inner, ea.face)
	else:
		Icons.draw(ci, "skull", inner.get_center() + Vector2(0, inner.size.y * 0.04), inner.size.y * 0.46, BONE)
	if tag != "":
		var tr := Rect2(r.end.x - r.size.x * 0.48, r.end.y - r.size.x * 0.48, r.size.x * 0.48, r.size.x * 0.48)
		ci.draw_style_box(UI.box(Color(0.1, 0.02, 0.03, 0.95), Color("#ff6b76"), int(4 * s), 1), tr)
		text_in(ci, tr, tag, int(tr.size.y * 0.78), Color.WHITE, "serif_black")


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


# ───────── 카드 앞면 ─────────
## r: 카드 사각형(2:3) · f: 앞면 자료 (board_battle.gd 의 face_*() 가 만든다)
static func draw_face(ci: CanvasItem, r: Rect2, f: Dictionary) -> void:
	var kind := str(f.get("kind", "mine"))
	var s := r.size.x / CW
	var ar := _rr(r, ART)
	var bp := _pt(r, BADGE)
	var br := 30.0 * s
	if kind == "slot":
		_slot_face(ci, r, f)
		return
	if kind == "giant":
		_giant_face(ci, r, f)
		return
	# 바탕(그림 창 뒤 · 틀 바깥 둥근 모서리는 투명)
	ci.draw_style_box(UI.box(Color("#0d090b"), Color.TRANSPARENT, int(16 * s)), r.grow(-3 * s))
	match kind:
		"mine":
			var art := str(f.get("art", ""))
			if art != "" and tex(art) != null:
				cover(ci, tex(art), ar, Rect2(), Color(0.62, 0.58, 0.6) if bool(f.get("dark", false)) else Color.WHITE)
			else:
				bless_art(ci, ar)
			desc(ci, r, str(f.get("text", "")))
			frame(ci, r, "ally")
			var own := str(f.get("owner", ""))
			var ocol: Color = {"hero": Color("#e4e8f0"), "warrior": Color("#f0c89a"), "archer": Color("#c2e6b0"), "noel": Color("#f0b8d4")}.get(own, Color("#e0dad6"))
			name_band(ci, r, str(f.get("name", "")), Color("#2a1810"), str(BattleV2Data.D.owners.get(own, "")), ocol.darkened(0.55))
			gem(ci, bp, br * 0.95, str(f.get("cost", 0)), int(26 * s))
			# 맡긴 카드: 특성·버프가 붙은 결과(왼쪽 띠에 보이게 봉인 아래) · 대상 적의 작은 얼굴(오른쪽 위)
			var res := str(f.get("result", ""))
			if res != "":
				var rr := Rect2(r.position.x + 0.06 * r.size.x, bp.y + br * 1.25, 0.5 * r.size.x, 34 * s)
				ci.draw_style_box(UI.box(Color(0.05, 0.02, 0.01, 0.9), GOLD, int(8 * s), maxi(1, int(2 * s))), rr)
				var rfs := fit_size(res, "sans_bold", int(19 * s), rr.size.x - 8 * s)
				text_in(ci, rr, res, rfs, Color("#ffd36b"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(2 * s)))
			if str(f.get("target_type", "")) != "":
				var fr := Rect2(r.end.x - 0.33 * r.size.x, r.position.y + 0.07 * r.size.y, 0.25 * r.size.x, 0.25 * r.size.x)
				enemy_face(ci, fr, str(f.target_type), str(f.get("target_tag", "")))
		"enemy", "minion":
			var ea := enemy_art(str(f.get("type", "")))
			if not ea.is_empty():
				cover(ci, ea.tex, ar, ea.crop, Color.WHITE, true)
			else:
				ci.draw_rect(ar, Color("#16110d"))
				Icons.draw(ci, "sword", ar.get_center() + Vector2(0, ar.size.y * 0.14), ar.size.y * 0.4, Color("#7a5a3a"))
				Icons.draw(ci, "skull", ar.get_center() + Vector2(0, -ar.size.y * 0.06), ar.size.x * 0.42, BONE)
			ci.draw_texture_rect(grad_bottom(), Rect2(ar.position.x, ar.end.y - ar.size.y * 0.3, ar.size.x, ar.size.y * 0.3), false)
			if bool(f.get("summon", false)):
				var stx := str(f.get("summonText", ""))
				var srr := Rect2(r.position.x + DESC_X.x * r.size.x, r.position.y + 0.6 * r.size.y, (DESC_X.y - DESC_X.x) * r.size.x, 0.15 * r.size.y)
				text_in(ci, srr, stx, fit_size(stx, "sans_bold", int(14 * s), srr.size.x), Color("#f0e2cc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(2 * s)))
			frame(ci, r, "minion" if kind == "minion" else "enemy")
			name_band(ci, r, str(f.get("name", "")), Color("#f0e2dc") if kind == "enemy" else Color("#2a1810"))
			if f.has("hpText"):
				seal(ci, bp, br, Color("#1d1517"), str(f.hpText), int(20 * s))
			else:
				seal(ci, bp, br, Color("#1d1517"), str(f.get("hp", 0)), int(26 * s), "/" + str(f.get("maxHp", 0)))
		"act":
			var minion := bool(f.get("minion", false))
			var ea2 := enemy_art(str(f.get("type", "")))
			ci.draw_rect(ar, Color("#1a0709"))
			if not ea2.is_empty():
				cover(ci, ea2.tex, ar, ea2.face, Color(0.55, 0.42, 0.42))
			else:
				Icons.draw(ci, "skull", ar.get_center(), ar.size.x * 0.5, Color(BONE, 0.6))
			# 피해 숫자를 크게(가운데) — 겹쳐도 왼쪽 위 봉인에 같은 숫자
			var v := int(f.get("value", 0))
			var mn := int(f.get("minus", 0))
			var no_value := bool(f.get("noValue", false))   # 행동 없음(거대한 발의 그림자)
			var big := "" if no_value else str(v)
			var bf := Assets.font("serif_black")
			var bfs := int(96 * s)
			var vcol := Color("#ff4b5a") if mn == 0 else Color("#c9a0ff")
			var by := ar.position.y + ar.size.y * 0.58
			ci.draw_string_outline(bf, Vector2(ar.position.x, by), big, HORIZONTAL_ALIGNMENT_CENTER, ar.size.x, bfs, int(10 * s), Color(0, 0, 0, 0.85))
			ci.draw_string(bf, Vector2(ar.position.x, by), big, HORIZONTAL_ALIGNMENT_CENTER, ar.size.x, bfs, vcol)
			if bool(f.get("erased", false)):   # 이름 없는 마녀의 카드로 없앤 행동: 숫자에 빗금
				ci.draw_line(Vector2(ar.position.x + ar.size.x * 0.22, by - 6 * s), Vector2(ar.end.x - ar.size.x * 0.22, by - bfs * 0.62), Color("#f0e2dc"), maxf(2.0, 8 * s), true)
			var sub := str(f.get("sub", ""))
			if mn > 0:
				sub = "저주 -%d" % mn + (" · " + sub if sub != "" else "")
			if sub != "":
				text_in(ci, Rect2(ar.position.x, by + 8 * s, ar.size.x, 30 * s), sub, int(17 * s), Color("#f0d8da"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(2 * s)))
			frame(ci, r, "minion" if minion else "enemy")
			name_band(ci, r, str(f.get("name", "")), Color("#2a1810") if minion else Color("#f0e2dc"))
			ci.draw_circle(bp, br * 0.92, Color(0.08, 0.0, 0.01, 0.95))
			ci.draw_arc(bp, br * 0.92, 0, TAU, 32, Color("#ff4b5a"), maxf(1.0, 2.5 * s), true)
			text_in(ci, Rect2(bp - Vector2(br, br), Vector2(br, br) * 2), "–" if no_value else str(maxi(0, v)), int(30 * s), vcol, "serif_black", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(3 * s)))
			if str(f.get("tag", "")) != "":
				var tr := Rect2(r.end.x - 0.27 * r.size.x, r.position.y + 0.07 * r.size.y, 0.19 * r.size.x, 0.19 * r.size.x)
				ci.draw_style_box(UI.box(Color(0.1, 0.02, 0.03, 0.95), Color("#ff6b76"), int(5 * s), 1), tr)
				text_in(ci, tr, str(f.tag), int(tr.size.y * 0.75), Color.WHITE, "serif_black")
		"death":
			# 검은 카드에 진홍 테두리 + 해골 — 다른 행동 카드와 확실히 다르게
			ci.draw_rect(ar, Color("#050203"))
			var da := str(f.get("art", ""))
			if da != "" and tex(da) != null:
				cover(ci, tex(da), ar, Rect2(), Color(0.55, 0.32, 0.34))
			skull(ci, ar.get_center() + Vector2(0, -ar.size.y * 0.06), ar.size.x * 0.62, Color(0.96, 0.88, 0.84, 0.92))
			desc(ci, r, str(f.get("text", "")), 0.62, 15, 0.765)
			frame(ci, r, "enemy", Color(1.0, 0.75, 0.75))
			var cr := r.grow(-7 * s)
			var sb := UI.box(Color(0, 0, 0, 0), Color("#d4142a"), int(14 * s), maxi(2, int(6 * s)))
			sb.draw_center = false
			ci.draw_style_box(sb, cr)
			name_band(ci, r, str(f.get("name", "")), Color("#ff6b76"))
			ci.draw_circle(bp, br * 0.95, Color("#120204"))
			ci.draw_arc(bp, br * 0.95, 0, TAU, 32, Color("#d4142a"), maxf(1.5, 3 * s), true)
			skull(ci, bp, br * 1.25, Color("#ff8a94"))
		"ally", "dead":
			var dead := kind == "dead"
			var down := bool(f.get("down", false))
			var bt := tex(str(f.get("art", "")))
			if bt != null:
				var m := Color(0.32, 0.26, 0.27) if dead else (Color(0.45, 0.43, 0.44) if down else Color.WHITE)
				cover(ci, bt, ar, Rect2(), m, true)
			if dead:
				ci.draw_rect(ar, Color(0.12, 0.0, 0.02, 0.45))
				skull(ci, ar.get_center() + Vector2(0, -ar.size.y * 0.05), ar.size.x * 0.55, Color(0.95, 0.85, 0.82, 0.85))
				text_in(ci, Rect2(ar.position.x, ar.position.y + ar.size.y * 0.66, ar.size.x, ar.size.y * 0.2), str(f.get("deadText", "")), int(34 * s), Color("#ff6b76"), "serif_black", HORIZONTAL_ALIGNMENT_CENTER, maxi(2, int(4 * s)))
			elif bool(f.get("big", false)):
				desc(ci, r, str(f.get("text", "")), 0.58)   # 특성 설명은 크게 보기에서만(탁자 위에서는 너무 작다)
			frame(ci, r, "ally", Color(0.7, 0.62, 0.62) if dead else Color.WHITE)
			name_band(ci, r, str(f.get("name", "")), Color("#2a1810"), "" if dead else str(f.get("trait", "")), Color("#6a3a10"))
			if not dead:
				seal(ci, bp, br * 1.05, Color("#8e1220"), str(f.get("hp", 0)), int(27 * s), "/" + str(f.get("maxHp", 0)))
				if int(f.get("block", 0)) > 0:
					shield(ci, Vector2(r.end.x - 0.19 * r.size.x, r.position.y + 0.14 * r.size.y), 24 * s, str(f.block))
				if str(f.get("statusLabel", "")) != "":
					var sr := Rect2(r.end.x - 0.36 * r.size.x, ar.position.y + ar.size.y * 0.36, 0.28 * r.size.x, 0.17 * r.size.y)
					ci.draw_style_box(UI.box(Color(0.05, 0.03, 0.03, 0.9), Color(GOLD, 0.8), int(8 * s), maxi(1, int(2 * s))), sr)
					text_in(ci, Rect2(sr.position.x, sr.position.y + 2 * s, sr.size.x, sr.size.y * 0.38), str(f.statusLabel), int(14 * s), Color("#e4d6cc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 1)
					text_in(ci, Rect2(sr.position.x, sr.position.y + sr.size.y * 0.36, sr.size.x, sr.size.y * 0.62), str(f.get("statusValue", "")), int(30 * s), Color("#ffcf6a"), "serif_black", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(3 * s)))
				if down:
					var cc := ar.get_center()
					ci.draw_set_transform(cc, deg_to_rad(-12), Vector2.ONE)
					var stamp := Rect2(-90 * s, -26 * s, 180 * s, 52 * s)
					ci.draw_style_box(UI.box(Color(0.12, 0.0, 0.02, 0.85), Color("#ff4b5a"), int(6 * s), maxi(1, int(3 * s))), stamp)
					text_in(ci, stamp, str(f.get("downText", "")), int(30 * s), Color("#ff6b76"), "serif_black", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(3 * s)))
					ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"note":
			ci.draw_rect(ar, Color("#140c0c"))
			var nr := Rect2(r.position.x + DESC_X.x * r.size.x, ar.position.y + 10 * s, (DESC_X.y - DESC_X.x) * r.size.x, 0.75 * r.size.y - ar.position.y + r.position.y - 10 * s)
			text_in(ci, nr, str(f.get("text", "")), fit_size(str(f.get("text", "")), "sans_bold", int(17 * s), nr.size.x), Color("#e8dcd0"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(2 * s)))
			frame(ci, r, "enemy")
			name_band(ci, r, str(f.get("name", "")), Color("#f0e2dc"))


## 거대한 발(세 칸을 덮는 큰 카드, 밤샘 계획 2 A): 발 그림을 가로로 꽉 채우고 진홍 두 겹 테두리 · 왼쪽 아래 이름 · 왼쪽 위 HP 봉인 「???」. 크기는 카드 높이 기준
static func _giant_face(ci: CanvasItem, r: Rect2, f: Dictionary) -> void:
	var s := r.size.y / CH
	ci.draw_style_box(UI.box(Color("#0d090b"), Color.TRANSPARENT, int(16 * s)), r.grow(-3 * s))
	var ar := r.grow(-14 * s)
	var ea := enemy_art(str(f.get("type", "")))
	if not ea.is_empty():
		cover(ci, ea.tex, ar, ea.crop, Color(0.8, 0.74, 0.74), true)
	ci.draw_texture_rect(grad_bottom(), Rect2(ar.position.x, ar.end.y - ar.size.y * 0.45, ar.size.x, ar.size.y * 0.45), false)
	var sb := UI.box(Color(0, 0, 0, 0), Color("#6a1a20"), int(16 * s), maxi(2, int(7 * s)))
	sb.draw_center = false
	ci.draw_style_box(sb, r.grow(-4 * s))
	var sb2 := UI.box(Color(0, 0, 0, 0), Color("#c8a46a"), int(12 * s), maxi(1, int(2 * s)))
	sb2.draw_center = false
	ci.draw_style_box(sb2, r.grow(-12 * s))
	text_in(ci, Rect2(ar.position.x + 24 * s, ar.end.y - 64 * s, ar.size.x * 0.5, 56 * s), str(f.get("name", "")), int(40 * s), Color("#f0e2dc"), "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, maxi(1, int(4 * s)))
	seal(ci, r.position + Vector2(66 * s, 64 * s), 44.0 * s, Color("#1d1517"), str(f.get("hpText", "???")), int(30 * s))


## 빈칸 표시: 점선 둥근 상자 + 글자 (틀 없음, 반투명)
static func _slot_face(ci: CanvasItem, r: Rect2, f: Dictionary) -> void:
	var s := r.size.x / CW
	var rr := r.grow(-10 * s)
	ci.draw_style_box(UI.box(Color(0.05, 0.02, 0.03, 0.35), Color.TRANSPARENT, int(14 * s)), rr)
	var col := Color(0.95, 0.55, 0.55, 0.75) if bool(f.get("hot", false)) else Color(0.85, 0.75, 0.7, 0.55)
	var pts := [rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y), rr.position]
	for i in 4:
		ci.draw_dashed_line(pts[i], pts[i + 1], col, maxf(1.5, 3 * s), 12 * s)
	text_in(ci, rr, str(f.get("text", "")), int(22 * s), col, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(2 * s)))
