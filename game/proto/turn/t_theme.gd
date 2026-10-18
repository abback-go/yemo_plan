class_name TTheme
extends RefCounted
## 턴제 화면(THud 전투 · TSetup 편성)이 같이 쓰는 글꼴·색 토큰·작은 그림 도우미 (combat_proto.md §21.2, review_C_ui_reqs.md §6.1·§6.2).
## 글꼴: 갈무리는 크기마다 다른 글꼴이고 안티에일리어싱이 꺼져 있어 **설계 크기로만** 그린다 —
##   8 = Galmuri7 (아이콘 위 숫자) · 10 = Galmuri9 (보조·본문) · 12 = Galmuri11 (이름·제목) · 15 = Galmuri14 (화면 제목·약점 숫자)
##   24 = Galmuri11 두 배 (큰 피해 숫자) · 30 = Galmuri14 두 배 (배너). 다른 크기를 넣으면 가장 가까운 것으로 맞춘다.
## 색: 속성 색(TData.ELEMENT_COLOR)은 속성에만 쓰고, 공격·약점·경고 같은 뜻은 아래 의미 토큰으로 칠한다.

const INK := Color("#14081f") ## 판 바탕·글자 테두리
const PANEL := Color("#1a1226") ## 카드·패널 바탕
const PANEL_HI := Color("#2a1e3d") ## 지금 차례 패널·고른 카드 바탕
const LINE := Color("#b9a2ff") ## 판 테두리 (0.55로)
const TEXT := Color("#e6dcff") ## 기본 글자
const TEXT_SUB := Color("#b3a8c9") ## 보조 글자
const TEXT_OFF := Color("#8a7fa3") ## 꺼진 것 (글자는 10px 이상만)
const GOLD := Color("#ffe08a") ## 크레딧·크리·고른 대상·대마법·지금 차례
const HP_ALLY := Color("#7ddc8a")
const HP_LOW := Color("#ff6a5a")
const HP_FOE := Color("#e2564a")
const HP_FOE_TRAIL := Color("#ffb0a0")
const GAUGE := Color("#c9b8ff")
const KIND_ATK := Color("#ffb08a") ## 공격 칸 테
const KIND_SUP := Color("#b9a2ff") ## 보조 칸 테
const KIND_DEB := Color("#c07aff") ## 디버프 칸 테
const WEAK := Color("#ffcf4a") ## 약점
const DANGER := Color("#ff4f6a") ## 강공격·필살기·차지 가득·크레딧 모자람·패배
const HEAL := Color("#b8f0a0")
const EMPTY := Color("#4a4058") ## 빈 칸 (크레딧·차지)
const STUN := Color("#ffe34a") ## 기절 별
const BG := Color("#0e0916") ## 편성 화면 바탕
## 의도 색 (combat_proto.md §18.3)
const INTENT_COL := {"attack": Color("#ff9a7a"), "heavy": Color("#ff4f6a"), "aoe": Color("#ffcf7a"), "buff": Color("#c9a0ff"),
	"stun_attack": Color("#8fd8ff"), "dispel": Color("#a070ff"), "finisher": Color("#ff2a4a")}
const KIND_NAME := {"attack": "공격", "support": "보조", "debuff": "디버프"}
const TARGET_NAME := {"enemy": "적 1", "enemies": "적 전체", "ally": "아군 1", "ally_any": "아군 1", "allies": "아군 전체", "self": "자신"}
const SLOT_NAME := ["앞", "중", "뒤"]
## 속성 → 아이콘 모양 (TIcon)
const ELEMENT_ICON := {"fire": "flame", "water": "drop", "bolt": "bolt", "space": "rift", "time": "clock", "sword": "slash"}
## 나쁜 버프 종류 (테 DANGER)
const BAD_CATS := ["def_down", "atk_down", "crit_taken", "final_taken", "crit_down"]
const SIZES := [8, 10, 12, 15, 24, 30]

static var _fonts := {}
static var _box: StyleBoxFlat


## 크기 → 글꼴 (설계 크기에 맞춘 파일)
static func font(fs: int) -> Font:
	fs = size_of(fs)
	var file := "Galmuri11"
	match fs:
		8: file = "Galmuri7"
		10: file = "Galmuri9"
		15, 30: file = "Galmuri14"
	if not _fonts.has(file):
		var f := load("res://assets/fonts/%s.ttf" % file) as FontFile
		if f == null:
			return ThemeDB.fallback_font
		if file != "Galmuri11":
			# 부분 집합에 없는 글자는 Galmuri11로 (assets/fonts/README.md)
			var fb: Array[Font] = []
			if file == "Galmuri7":
				fb.append(font(10))
			fb.append(load("res://assets/fonts/Galmuri11.ttf") as Font)
			f.fallbacks = fb
		_fonts[file] = f
	return _fonts[file]


## 정적 캐시(글꼴 4 · 판 StyleBox)를 놓는다 — 전투·편성 장면이 나갈 때. 글꼴이 글리프 아틀라스·TextLine 캐시를 종료 때까지 붙잡아
## 엔진 누수 경고(텍스처·ShapedText·FontAdvanced)가 나던 것 (review_D §8.1). 다음에 그리면 다시 불러온다.
static func release() -> void:
	_fonts.clear()
	_box = null


## 허용 크기 중 가장 가까운 것
static func size_of(fs: int) -> int:
	var best := 12
	for s: int in SIZES:
		if absi(s - fs) < absi(best - fs):
			best = s
	return best


static func width(s: String, fs: int) -> float:
	fs = size_of(fs)
	return font(fs).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## 글자 + 먹 테두리 (10px 이하 2px · 12~15px 3px · 24px 이상 4px). 오른쪽·가운데 맞춤은 글자 폭으로 자리를 옮긴다. 좌표는 정수로 맞춤 (픽셀 글꼴)
static func text(ci: CanvasItem, p: Vector2, s: String, fs: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, outline := -1) -> void:
	if s == "":
		return
	fs = size_of(fs)
	var f := font(fs)
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		p.x -= tw if align == HORIZONTAL_ALIGNMENT_RIGHT else tw * 0.5
	p = p.round()
	var ow := outline if outline >= 0 else (2 if fs <= 10 else (3 if fs <= 15 else 4))
	if ow > 0:
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ow, Color(INK, 0.92 * col.a))
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## 여러 줄 글 (폭 w에서 줄바꿈, 줄 높이 lh). 그린 높이를 돌려준다. max_lines > 0이면 그만큼만 (넘치면 끝에 …)
static func wrap(ci: CanvasItem, p: Vector2, s: String, w: float, fs: int, col: Color, lh := 0.0, max_lines := 0) -> float:
	fs = size_of(fs)
	if lh <= 0.0:
		lh = float(fs) + 3.0
	var lines := split_lines(s, w, fs)
	if max_lines > 0 and lines.size() > max_lines:
		lines.resize(max_lines)
		lines[max_lines - 1] = clip(String(lines[max_lines - 1]) + "…", fs, w)
	for i in lines.size():
		text(ci, p + Vector2(0, lh * float(i)), String(lines[i]), fs, col)
	return lh * float(lines.size())


## 폭 w에 맞춰 줄로 나눈다 (띄어쓰기 우선, 긴 낱말은 글자 단위)
static func split_lines(s: String, w: float, fs: int) -> Array:
	var out: Array = []
	for para in s.split("\n"):
		var cur := ""
		for word in para.split(" "):
			var cand := word if cur == "" else cur + " " + word
			if width(cand, fs) <= w:
				cur = cand
				continue
			if cur != "":
				out.append(cur)
			cur = ""
			for ch in word:
				if width(cur + ch, fs) > w and cur != "":
					out.append(cur)
					cur = ""
				cur += ch
		out.append(cur)
	return out


## 폭 w를 넘으면 뒤를 잘라 …
static func clip(s: String, fs: int, w: float) -> String:
	if width(s, fs) <= w:
		return s
	var t := s
	while t.length() > 1 and width(t + "…", fs) > w:
		t = t.substr(0, t.length() - 1)
	return t + "…"


## 모서리가 둥근 판 (픽셀 그림이라 안티에일리어싱 끔). bw 0이면 테 없음
static func panel(ci: CanvasItem, r: Rect2, fill: Color, border := Color(0, 0, 0, 0), bw := 1, radius := 3) -> void:
	if _box == null:
		_box = StyleBoxFlat.new()
		_box.anti_aliasing = false
	_box.bg_color = fill
	_box.border_color = border
	_box.set_border_width_all(bw if border.a > 0.0 else 0)
	_box.set_corner_radius_all(radius)
	_box.draw(ci.get_canvas_item(), r)


## 비용 배지: 원 반지름 6 + 숫자 (쓸 수 있음 GOLD 바탕 · 모자람 DANGER 바탕 · 기본 공격 "+1"은 GAUGE 바탕)
static func cost_badge(ci: CanvasItem, c: Vector2, label: String, mode := "ok") -> void:
	var bg := GOLD
	var fg := INK
	match mode:
		"short":
			bg = DANGER
			fg = TEXT
		"gain":
			bg = GAUGE
	var r := 6.0 if label.length() <= 1 else 7.0
	ci.draw_circle(c, r + 1.0, Color(INK, 0.95))
	ci.draw_circle(c, r, bg)
	text(ci, c + Vector2(0, 3), label, 8, fg, HORIZONTAL_ALIGNMENT_CENTER, 0)


## 마름모 (크레딧 칸)
static func diamond(ci: CanvasItem, c: Vector2, half: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -half), c + Vector2(half, 0), c + Vector2(0, half), c + Vector2(-half, 0)]), col)


## 크레딧 n/7 줄: 마름모 7개 (중심 간격 gap)
static func credit_row(ci: CanvasItem, p: Vector2, n: int, gap := 10.0, half := 3.5, pulse := 1.0) -> void:
	for k in TData.CREDIT_MAX:
		var c := p + Vector2(gap * float(k), 0)
		diamond(ci, c, half + 1.0, Color(INK, 0.95))
		diamond(ci, c, half, Color(GOLD, pulse) if k < n else EMPTY)


## 예상 피해 한 줄 (전투 설명 띠·편성 설명 상자가 같이 씀, review_C2 L9): "예상 n · 크리 m" / 크리 확정이면 "예상 n (크리 확정)"
static func est_text(est: int, est_c: int, head := "예상") -> String:
	if est_c != est:
		return "%s %s · 크리 %s" % [head, TData.fmt_short(est), TData.fmt_short(est_c)]
	return "%s %s (크리 확정)" % [head, TData.fmt_short(est)]


## 공격·보조·디버프 색
static func kind_col(kind: String) -> Color:
	match kind:
		"attack": return KIND_ATK
		"debuff": return KIND_DEB
	return KIND_SUP


## "공격 · 적 1"
static func kind_label(s: Dictionary) -> String:
	return "%s · %s" % [KIND_NAME.get(String(s.get("kind", "")), ""), TARGET_NAME.get(String(s.get("target", "")), "")]


## 속성 아이콘 (속성 색). r 5 이하(약점 칸 11×11 등)는 작게 그린 전용 모양 — 불꽃 · 물방울 · 번개
static func element_icon(ci: CanvasItem, c: Vector2, el: String, r: float, alpha := 1.0) -> void:
	var col := Color(TData.ELEMENT_COLOR.get(el, TEXT), alpha)
	if r > 5.0 or not (el in ["fire", "water", "bolt"]):
		TIcon.draw(ci, c, String(ELEMENT_ICON.get(el, "strike")), col, r)
		return
	match el:
		"fire":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, 4), c + Vector2(-3, 0), c + Vector2(-1, -2), c + Vector2(0, -4.5), c + Vector2(1.5, -1.5), c + Vector2(3, -2.5), c + Vector2(3.5, 4)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1.5, 4), c + Vector2(0, 0), c + Vector2(1.5, 4)]), Color("#fff3c0", alpha))
		"water":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4.5), c + Vector2(3, 0.5), c + Vector2(2.5, 3), c + Vector2(0, 4.5), c + Vector2(-2.5, 3), c + Vector2(-3, 0.5)]), col)
			ci.draw_rect(Rect2(c + Vector2(-1.5, 0), Vector2(1, 2)), Color(1, 1, 1, 0.7 * alpha))
		"bolt":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(1, -5), c + Vector2(-3, 0.5), c + Vector2(0, 0.5), c + Vector2(-1, 5), c + Vector2(3, -0.5), c + Vector2(0, -0.5)]), col)


## 의도 아이콘 (9×9 안, c = 가운데)
static func intent_icon(ci: CanvasItem, c: Vector2, kind: String, col: Color) -> void:
	match kind:
		"attack":
			ci.draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.6)
			ci.draw_line(c + Vector2(1, -3), c + Vector2(3, -3), col, 1.6)
			ci.draw_line(c + Vector2(3, -1), c + Vector2(3, -3), col, 1.6)
		"heavy":
			ci.draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 2.4)
			ci.draw_line(c + Vector2(-3, -1), c + Vector2(1, 3), col, 1.2)
		"aoe":
			ci.draw_arc(c, 3.5, 0.0, TAU, 12, col, 1.2)
			ci.draw_circle(c, 1.2, col)
		"buff":
			ci.draw_line(c + Vector2(0, 3), c + Vector2(0, -3), col, 1.6)
			ci.draw_line(c + Vector2(-3, 0), c + Vector2(0, -3), col, 1.6)
			ci.draw_line(c + Vector2(3, 0), c + Vector2(0, -3), col, 1.6)
		"stun_attack":
			ci.draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.6)
			ci.draw_circle(c + Vector2(-2, -2), 1.2, col)
		"dispel":
			ci.draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), col, 1.4)
			ci.draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.4)
		"finisher":
			ci.draw_arc(c, 3.5, 0.0, TAU, 12, col, 1.6)
			ci.draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.6)
		"stun":
			star(ci, c, 4.0, col)


## 작은 다섯 꼭짓점 별
static func star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + float(i) * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


## 징표 아이콘 (반지름 약 4, t = 깜빡임 시계)
static func mark_icon(ci: CanvasItem, c: Vector2, kind: String, t := 0.0) -> void:
	match kind:
		"burn":
			var f := 0.85 + 0.15 * sin(t * 12.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, 4), c + Vector2(-2.5, -1), c + Vector2(0, -4.5 * f), c + Vector2(2.5, -1), c + Vector2(3.5, 4)]), Color("#e2452a"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1.5, 4), c + Vector2(0, -1.0 * f), c + Vector2(1.5, 4)]), Color("#ffd27a"))
		"frost":
			for i in 3:
				var a := float(i) * PI / 3.0
				ci.draw_line(c - Vector2(cos(a), sin(a)) * 4.0, c + Vector2(cos(a), sin(a)) * 4.0, Color("#8ad0ff"), 1.0)
		"shock":
			ci.draw_line(c + Vector2(-1.5, -4), c + Vector2(1.5, -0.5), Color("#ffe08a"), 1.4)
			ci.draw_line(c + Vector2(1.5, -0.5), c + Vector2(-1.5, 0.5), Color("#ffe08a"), 1.4)
			ci.draw_line(c + Vector2(-1.5, 0.5), c + Vector2(1.5, 4), Color("#ffe08a"), 1.4)


## 버프·디버프 아이콘 10×10 (p = 왼쪽 위): 먹 바탕 + 종류 테 + 작은 모양 + 오른쪽 아래 바깥 알약에 남은 수 (Galmuri7). n < 0이면 숫자 없음
static func buff_icon(ci: CanvasItem, p: Vector2, ic: Dictionary, n := -1) -> void:
	var cat := String(ic.get("cat", ""))
	var v := float(ic.get("v", 0.0))
	var bad := cat in BAD_CATS or (cat == "dmg_taken" and v > 0.0)
	var col := DANGER if bad else Color("#d9ccff")
	match cat:
		"atk", "special", "crit_rate", "crit_dmg", "final":
			col = GOLD if cat in ["crit_rate", "crit_dmg"] else Color("#ffb08a")
		"invincible", "dmg_taken":
			col = Color("#8fd8ff") if not bad else DANGER
		"guts": col = HEAL
		"taunt": col = Color("#ff9a7a")
		"element": col = TData.ELEMENT_COLOR.get(String(ic.get("el", "")), TEXT)
	ci.draw_rect(Rect2(p, Vector2(10, 10)), Color(INK, 0.92))
	ci.draw_rect(Rect2(p + Vector2(0.5, 0.5), Vector2(9, 9)), Color(col, 0.9), false, 1.0)
	var c := p + Vector2(5, 5)
	match cat:
		"atk":
			ci.draw_line(c + Vector2(0, 3), c + Vector2(0, -3), col, 1.4)
			ci.draw_line(c + Vector2(-2.5, -0.5), c + Vector2(0, -3), col, 1.2)
			ci.draw_line(c + Vector2(2.5, -0.5), c + Vector2(0, -3), col, 1.2)
		"atk_down":
			ci.draw_line(c + Vector2(0, -3), c + Vector2(0, 3), col, 1.4)
			ci.draw_line(c + Vector2(-2.5, 0.5), c + Vector2(0, 3), col, 1.2)
			ci.draw_line(c + Vector2(2.5, 0.5), c + Vector2(0, 3), col, 1.2)
		"crit_rate", "crit_taken", "crit_down":
			star(ci, c, 3.6, col)
		"crit_dmg":
			star(ci, c + Vector2(-0.5, -0.5), 3.2, col)
			ci.draw_rect(Rect2(c + Vector2(2, 2), Vector2(1.5, 1.5)), col)
		"special":
			ci.draw_arc(c, 3.0, 0.0, TAU, 12, col, 1.0)
			ci.draw_rect(Rect2(c - Vector2(0.75, 0.75), Vector2(1.5, 1.5)), col)
		"final", "final_taken":
			diamond(ci, c, 3.2, col)
		"dmg_taken", "invincible", "def_down":
			var sh := PackedVector2Array([c + Vector2(-3, -3), c + Vector2(3, -3), c + Vector2(3, 0), c + Vector2(0, 3.5), c + Vector2(-3, 0)])
			if cat == "invincible":
				ci.draw_colored_polygon(sh, col)
			else:
				sh.append(sh[0])
				ci.draw_polyline(sh, col, 1.0)
			if bad:
				ci.draw_line(c + Vector2(-1, -3), c + Vector2(1, 1), col, 1.0)
		"taunt":
			ci.draw_line(c + Vector2(0, -3.5), c + Vector2(0, 1), col, 1.6)
			ci.draw_rect(Rect2(c + Vector2(-0.75, 2.2), Vector2(1.5, 1.5)), col)
		"guts":
			ci.draw_circle(c + Vector2(-1.4, -0.8), 1.6, col)
			ci.draw_circle(c + Vector2(1.4, -0.8), 1.6, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -0.4), c + Vector2(3, -0.4), c + Vector2(0, 3.2)]), col)
		"element":
			element_icon(ci, c, String(ic.get("el", "")), 3.6)
		"hit_stack":
			for k in 3:
				ci.draw_line(c + Vector2(-3, 2.5 - 2.5 * k), c + Vector2(3, 2.5 - 2.5 * k), col, 1.0)
		_:
			ci.draw_circle(c, 1.5, col)
	if bad:
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(7, 0), p + Vector2(10, 0), p + Vector2(10, 3)]), DANGER)
	if n >= 0:
		count_pill(ci, p, n)


## 아이콘(10×10, p = 왼쪽 위) 오른쪽 아래 바깥의 먹 알약 + 숫자 (겹 수·남은 수) — 옆 아이콘·테에 닿지 않게 (review_C2 L1)
static func count_pill(ci: CanvasItem, p: Vector2, n: int) -> void:
	var s := str(n)
	var w := maxf(width(s, 8) + 2.0, 6.0)
	ci.draw_rect(Rect2(p + Vector2(8, 4), Vector2(w, 8)), Color(INK, 0.95))
	text(ci, p + Vector2(8.0 + w * 0.5, 11), s, 8, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0)


## 버프 한 줄 글 (상세 판): "공격력 +50% · 2행동" / "공격력 +30% · 기본 공격 2번"
static func buff_line(b: Dictionary) -> String:
	var cat := String(b.cat)
	var nm: String = TData.CAT_NAME.get(cat, cat)
	var v := int(round(float(b.get("v", 0.0)) * 100.0))
	var head := ""
	match cat:
		"element": head = "%s 속성 부여" % TData.ELEMENT_NAME.get(String(b.get("el", "")), "")
		"invincible", "taunt": head = nm
		"guts": head = "근성 (체력 %d%%로)" % v if v > 0 else "근성"
		"hit_stack": head = "맞으며 쌓기 +%d%%" % v
		_:
			if cat == "special" and String(b.get("mark", "")) != "":
				nm = "%s 특공" % TData.MARK_NAME.get(String(b.mark), "")
			elif String(b.get("mark", "")) != "":
				nm = "%s 적 %s" % [TData.MARK_NAME.get(String(b.mark), ""), nm]
			head = "%s %+d%%" % [nm, v]
	var dur := ""
	if b.has("count"):
		dur = "%s %d번" % [{"basic": "기본 공격", "skill": "공격 마법", "attack": "공격"}.get(String(b.get("on", "attack")), "공격"), int(b.count)]
	elif String(b.get("clock", "own")) == "enemy":
		dur = "적 행동 %d번" % int(b.dur)
	else:
		dur = "%d행동" % int(b.dur)
	return "%s · %s" % [head, dur]
