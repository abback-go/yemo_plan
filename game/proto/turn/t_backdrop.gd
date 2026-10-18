class_name TBackdrop
extends PDraw.Canvas
## 턴제 전투 배경 (640×360). 기본은 재의 들판의 밤: 자줏빛 밤하늘 · 큰 달 · 지평선의 불탄 나무와 무너진 탑 실루엣 ·
## 왼쪽 아래에서 오른쪽 위로 비스듬히 뻗은 길(대각선 사이드뷰의 깊이) · 떠다니는 재 · 가장자리 어둡게.
## 움직이는 것(재·안개·물결·빗줄기·등불)만 있으므로 20Hz로 다시 그린다.
## 단계 D: 깊이 세 겹(먼 산등성이 · 무너진 성벽 · 앞쪽 바위 테두리) + 달빛 줄기 · 흐르는 안개 띠.
## D2 (review_D C3): 허리 높이 옅은 안개 띠 · 왼쪽 아래 따뜻한 키 라이트 · 바위 덤불 두 줄.
## F-3 (review_F F20 · review_H §7.2 규칙 4): 전투·웨이브마다 배경 테마 (TData.BATTLES의 bg · bgs[웨이브]) — 바뀔 때 0.35초 어두워졌다 밝아짐.
##   field 들판 · ash_sky 재의 왕(하늘 아래 붉게) · fire 불길의 골짜기(붉은 해·용암 금·불티) · lake 안개 호수(물 띠·달 그림자·반딧불) ·
##   storm 뇌운 고개(먹구름·번개·빗줄기·바위 봉우리) · corridor 등불 회랑(돌기둥·아치·흔들리는 등불·잿불) · library 틈새 서고(책장·보랏빛 틈·떠도는 책장) ·
##   prism 세 빛의 인형(오로라 띠 + 줄 속성 색 달 — set_tint) · brood 잿빛 둥지(잿빛 안개·마른 가지·둥지 언덕) · trial 시련의 터(돌기둥 원·찬 빛 기둥)
##   모든 테마는 같은 자리(지평선 y 206 · 길 · 빛 웅덩이 · 아래 띠 어둡게)를 지켜 그림·카드·패널이 같은 곳에 놓인다.

const RIDGE_Y := 206.0 ## 지평선

## 테마 색 (sky 셋 = 위·가운데·지평선 · ground 둘 = 지평선 쪽·앞쪽 · path · lit = 길 밝은 결 · grass · fog · ridge · far = 먼 실루엣 ·
## moon = 달 색(a 0이면 달 없음) · mpos·mr = 달 자리·반지름 · stars = 별 밝기 · dust = 떠다니는 것 종류 · dcol = 그 색 ·
## pa·pf = 아군·적 쪽 빛 웅덩이 · key = 왼쪽 아래 키 라이트)
const THEMES := {
	"field": {"sky": [Color("#120a22"), Color("#2a1740"), Color("#4a2a4e")], "ground": [Color("#1d1727"), Color("#2a2236")], "path": Color("#3f3550"), "lit": Color("#3a2f48"),
		"grass": Color("#3b4a3a"), "fog": Color("#5a4466"), "ridge": Color("#1d1230"), "far": Color("#160d24"), "moon": Color("#f3e6c8"), "mpos": Vector2(300, 108), "mr": 22.0,
		"stars": 1.0, "dust": "ash", "dcol": Color("#9a8aa6"), "pa": Color("#6a4a5a"), "pf": Color("#ff6a4a"), "key": Color("#ff9a5a")},
	"ash_sky": {"base": "field", "sky": [Color("#120a22"), Color("#311836"), Color("#6a2a3a")], "horizon": Color("#ff5a3a"), "hz": 0.22},
	"fire": {"sky": [Color("#16060c"), Color("#3e1016"), Color("#8a2e1a")], "ground": [Color("#170b0b"), Color("#2c1914")], "path": Color("#3c241c"), "lit": Color("#4c2c20"),
		"grass": Color("#5a3a22"), "fog": Color("#7a3424"), "ridge": Color("#260a0e"), "far": Color("#16080a"), "moon": Color("#ffb070"), "mpos": Vector2(300, 150), "mr": 30.0,
		"stars": 0.25, "dust": "ember", "dcol": Color("#ffa04a"), "pa": Color("#6a3a3a"), "pf": Color("#ff7a3a"), "key": Color("#ff8a4a"), "horizon": Color("#ff6a2a"), "hz": 0.32, "motif": "lava"},
	"lake": {"sky": [Color("#050d1a"), Color("#0e2442"), Color("#20486a")], "ground": [Color("#0b141e"), Color("#15212c")], "path": Color("#1c2c3c"), "lit": Color("#22384a"),
		"grass": Color("#2a4a46"), "fog": Color("#6a8aa8"), "ridge": Color("#0b1828"), "far": Color("#07101c"), "moon": Color("#e6f2ff"), "mpos": Vector2(300, 96), "mr": 20.0,
		"stars": 1.0, "dust": "mote", "dcol": Color("#9af0d8"), "pa": Color("#3a5a6a"), "pf": Color("#5ac8ff"), "key": Color("#9ad0ff"), "motif": "lake", "fog_k": 1.6},
	"storm": {"sky": [Color("#080a12"), Color("#181e2c"), Color("#2e3446")], "ground": [Color("#12141c"), Color("#1e222c")], "path": Color("#2c303e"), "lit": Color("#363a4a"),
		"grass": Color("#2c3832"), "fog": Color("#4a5268"), "ridge": Color("#10121c"), "far": Color("#0a0c14"), "moon": Color(0, 0, 0, 0), "mpos": Vector2(300, 100), "mr": 0.0,
		"stars": 0.0, "dust": "rain", "dcol": Color("#9aaacc"), "pa": Color("#3a3e5a"), "pf": Color("#ffe34a"), "key": Color("#c8d0ff"), "motif": "peaks"},
	"corridor": {"sky": [Color("#0a0607"), Color("#170f0d"), Color("#261a14")], "ground": [Color("#150f0d"), Color("#281e18")], "path": Color("#33251c"), "lit": Color("#40301f"),
		"grass": Color("#3a2a1c"), "fog": Color("#5a3e2c"), "ridge": Color("#0e0908"), "far": Color("#0e0908"), "moon": Color(0, 0, 0, 0), "mpos": Vector2(300, 100), "mr": 0.0,
		"stars": 0.0, "dust": "cinder", "dcol": Color("#ffb86a"), "pa": Color("#6a4a3a"), "pf": Color("#ffb04a"), "key": Color("#ffb06a"), "motif": "corridor"},
	"library": {"sky": [Color("#09050f"), Color("#190e2a"), Color("#2c1a40")], "ground": [Color("#110b16"), Color("#1f1726")], "path": Color("#3a1e30"), "lit": Color("#4a2840"),
		"grass": Color("#30243a"), "fog": Color("#5a4878"), "ridge": Color("#0e0816"), "far": Color("#0c0712"), "moon": Color(0, 0, 0, 0), "mpos": Vector2(300, 100), "mr": 0.0,
		"stars": 0.35, "dust": "page", "dcol": Color("#e8e0f8"), "pa": Color("#5a4a7a"), "pf": Color("#b9a2ff"), "key": Color("#d8a0ff"), "motif": "library"},
	"prism": {"base": "field", "sky": [Color("#080818"), Color("#1a1838"), Color("#36284e")], "moon": Color("#e8e0ff"), "mr": 24.0, "motif": "prism", "stars": 1.2},
	"brood": {"sky": [Color("#121014"), Color("#262228"), Color("#46403f")], "ground": [Color("#18151a"), Color("#262128")], "path": Color("#332d34"), "lit": Color("#3e3740"),
		"grass": Color("#3a3832"), "fog": Color("#8a8086"), "ridge": Color("#1a161c"), "far": Color("#141116"), "moon": Color("#d8d0c4"), "mpos": Vector2(300, 112), "mr": 26.0,
		"stars": 0.0, "dust": "ash", "dcol": Color("#b8acb0"), "pa": Color("#5a4a4a"), "pf": Color("#ff8a5a"), "key": Color("#ffa06a"), "motif": "nest", "fog_k": 1.8, "moon_a": 0.45},
	"trial": {"sky": [Color("#060409"), Color("#120e1c"), Color("#201a2e")], "ground": [Color("#0f0c13"), Color("#1c1823")], "path": Color("#2a2533"), "lit": Color("#34303e"),
		"grass": Color("#262a2c"), "fog": Color("#4a4460"), "ridge": Color("#0c0a12"), "far": Color("#0a0810"), "moon": Color("#f0f0ff"), "mpos": Vector2(300, 70), "mr": 12.0,
		"stars": 0.6, "dust": "dust", "dcol": Color("#c8c4e0"), "pa": Color("#4a4a6a"), "pf": Color("#c8c8ff"), "key": Color("#c8c8ff"), "motif": "arena"},
}

var theme := "field"
var _p: Dictionary = {} ## 지금 테마의 칸 (base를 펼친 것)
var _next := "" ## 바꿀 테마 (어두워진 순간에 바뀜)
var _veil := 0.0 ## 테마를 바꾸는 동안 덮는 어둠 (0~1)
var _t := 0.0
var _acc := 0.0
var _dust: Array = [] ## [pos, vel, size, phase]
var _rng := RandomNumberGenerator.new()
var _tint := Color("#e8e0ff") ## prism 달 색 (줄 속성 색, TStage가 set_tint)
var _tint_to := Color("#e8e0ff")
var _bolt_t := 3.0 ## storm: 다음 번개까지
var _bolt := 0.0 ## storm: 번개 밝기 (1 → 0)
var _bolt_x := 200.0


## 테마를 바꾼다 (instant면 바로, 아니면 0.35초 어두워졌다가 밝아짐)
func set_theme(key: String, instant := false) -> void:
	if not THEMES.has(key):
		key = "field"
	if instant:
		theme = key
		_p = _resolve(key)
		_next = ""
		_veil = 0.0
		_seed_dust()
	elif key != theme:
		_next = key


## 옛 이름 (보스 웨이브 = 재의 왕 하늘) — set_theme을 쓴다
func set_boss(on: bool, instant := false) -> void:
	set_theme("ash_sky" if on else "field", instant)


## prism 테마의 달 색 (세 빛의 인형 지금 줄의 속성 색 — review_H §7.2 [제안])
func set_tint(col: Color, instant := false) -> void:
	_tint_to = col
	if instant:
		_tint = col


static func _resolve(key: String) -> Dictionary:
	var d: Dictionary = THEMES[key]
	if not d.has("base"):
		return d
	var out: Dictionary = (_resolve(String(d.base)) as Dictionary).duplicate()
	for k in d:
		if k != "base":
			out[k] = d[k]
	if not d.has("motif"):
		out.erase("motif")
	return out


func _ready() -> void:
	z_index = -10
	_rng.seed = 7
	_p = _resolve(theme)
	_seed_dust()


func _seed_dust() -> void:
	_dust.clear()
	var kind := String(_p.get("dust", "ash"))
	var n := 40
	match kind:
		"rain": n = 70
		"page": n = 12
		"mote": n = 26
		"ember", "cinder": n = 34
	for i in n:
		var pos := Vector2(_rng.randf_range(0, 640), _rng.randf_range(0, 360))
		var vel := Vector2(_rng.randf_range(-14, -4), _rng.randf_range(-6, 4))
		match kind:
			"ember", "cinder": vel = Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-26, -10))
			"rain": vel = Vector2(-90, 300)
			"page": vel = Vector2(_rng.randf_range(-10, -4), _rng.randf_range(-3, 3))
			"mote": vel = Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 4))
			"dust": vel = Vector2(_rng.randf_range(-5, -1), _rng.randf_range(-2, 2))
		_dust.append([pos, vel, _rng.randf_range(0.8, 1.8), _rng.randf() * TAU])


func _process(delta: float) -> void:
	_t += delta
	if _next != "":
		_veil = minf(_veil + delta / 0.35, 1.0)
		if _veil >= 1.0:
			theme = _next
			_p = _resolve(theme)
			_next = ""
			_seed_dust()
	elif _veil > 0.0:
		_veil = maxf(_veil - delta / 0.45, 0.0)
	_tint = _tint.lerp(_tint_to, minf(delta * 3.0, 1.0))
	if String(_p.get("motif", "")) == "peaks":
		_bolt = maxf(_bolt - delta * 3.0, 0.0)
		_bolt_t -= delta
		if _bolt_t <= 0.0:
			_bolt_t = _rng.randf_range(3.0, 6.0)
			_bolt = 1.0
			_bolt_x = _rng.randf_range(120, 560)
	var kind := String(_p.get("dust", "ash"))
	for a: Array in _dust:
		var p: Vector2 = a[0]
		var wob := Vector2(sin(_t * 1.3 + float(a[3])) * 6.0, 0.0) if kind in ["ash", "page", "dust"] else Vector2(sin(_t * 2.0 + float(a[3])) * 8.0, 0.0)
		p += ((a[1] as Vector2) + wob) * delta
		if p.x < -8.0:
			p = Vector2(648.0, _rng.randf_range(0, 360))
		elif p.x > 648.0:
			p.x = -8.0
		if p.y < -8.0:
			p = Vector2(_rng.randf_range(0, 640), 368.0)
		elif p.y > 368.0:
			p = Vector2(_rng.randf_range(0, 700), -8.0)
		a[0] = p
	_acc += delta
	if _acc >= 1.0 / 20.0:
		_acc = 0.0
		queue_redraw()


func _c(k: String) -> Color:
	return _p.get(k, THEMES.field.get(k, Color.BLACK))


func _paint() -> void:
	var motif := String(_p.get("motif", "ruins"))
	var sky: Array = _p.sky
	var interior := motif in ["corridor"]
	# 하늘 (실내면 천장)
	pd.rect_grad(Rect2(0, 0, 640, 150), sky[0], sky[1])
	pd.rect_grad(Rect2(0, 150, 640, 60), sky[1], sky[2])
	# 별
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var sb := float(_p.get("stars", 1.0))
	if sb > 0.0:
		for i in 70:
			var p := Vector2(r.randf_range(0, 640), r.randf_range(0, 170))
			var tw := 0.5 + 0.5 * sin(_t * r.randf_range(1.0, 3.0) + r.randf() * TAU)
			pd.draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, minf((0.25 + 0.5 * tw * (1.0 - p.y / 200.0)) * sb, 1.0)))
	match motif:
		"prism": _aurora()
		"library": _rift_sky()
		"peaks": _clouds()
	# 달 (가운데 빈 하늘 — 오른쪽 위는 적 카드 자리) + 번짐
	var moon := _c("moon")
	if motif == "prism":
		moon = moon.lerp(_tint, 0.7)
	if moon.a > 0.0 and float(_p.get("mr", 0.0)) > 0.0:
		var mc: Vector2 = _p.get("mpos", Vector2(300, 108))
		var mr := float(_p.mr)
		var ma := float(_p.get("moon_a", 1.0))
		pd.glow(mc, mr * 2.6, Color(moon, 0.16 * ma + (0.08 if motif == "lava" else 0.0)), 0.0)
		if motif == "lava":
			pd.glow(mc, mr * 4.0, Color(moon, 0.08), 0.0) # 붉은 해 아지랑이
		pd.draw_circle(mc, mr, Color(moon, ma))
		if motif in ["ruins", "prism", "arena", "nest"]:
			var crater := moon.darkened(0.08)
			pd.draw_circle(mc + Vector2(-5, -3) * mr / 22.0, 3.5 * mr / 22.0, Color(crater, ma))
			pd.draw_circle(mc + Vector2(7, 6) * mr / 22.0, 2.5 * mr / 22.0, Color(crater, ma))
			pd.draw_circle(mc + Vector2(-8, 8) * mr / 22.0, 2.0 * mr / 22.0, Color(crater, ma))
		if motif != "lake":
			pd.draw_colored_polygon(PackedVector2Array([mc + Vector2(-10, 10), mc + Vector2(10, 10), Vector2(420, 300), Vector2(250, 300)]), Color(moon, 0.035 * ma)) # 달빛 줄기
	if motif == "arena":
		# 찬 빛 기둥 (위에서 가운데로)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(286, 0), Vector2(314, 0), Vector2(380, 300), Vector2(220, 300)]), Color("#c8c8ff", 0.05))
	# 먼 산등성이 (가장 먼 층) — 실내는 없음
	if not interior:
		var ridge := PackedVector2Array([Vector2(0, 210), Vector2(0, 182)])
		var rough := 2.2 if motif == "peaks" else 1.0
		for i in 17:
			var x := 40.0 * float(i)
			ridge.append(Vector2(x, 180.0 + 9.0 * rough * sin(float(i) * 1.3) + 5.0 * rough * sin(float(i) * 3.1) - (14.0 if motif == "peaks" and i % 4 == 1 else 0.0)))
		ridge.append(Vector2(640, 184))
		ridge.append(Vector2(640, 210))
		pd.draw_colored_polygon(ridge, Color(_c("ridge"), 0.85))
	# 지평선 불빛 (재의 왕·불길)
	if _p.has("horizon"):
		pd.rect_grad(Rect2(0, 158, 640, 44), Color(_c("horizon"), 0.0), Color(_c("horizon"), float(_p.get("hz", 0.22))))
	# 지평선 안개 (천천히 흐르는 띠 둘)
	var fk := float(_p.get("fog_k", 1.0))
	var fog := _c("fog")
	pd.rect_grad(Rect2(0, 170, 640, 40), Color(fog, 0.0), Color(fog, minf(0.35 * fk, 0.7)))
	for i in 2:
		var fx := fposmod(_t * (6.0 + 4.0 * float(i)) + 300.0 * float(i), 900.0) - 130.0
		pd.draw_set_transform(Vector2(fx, 200.0 + 6.0 * float(i)), 0.0, Vector2(1.0, 0.18))
		pd.glow(Vector2.ZERO, 130.0, Color(fog, 0.22 * fk), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
	# 먼 실루엣 (테마마다)
	match motif:
		"ruins", "prism", "lava": _ruins(motif)
		"lake": _far_trees()
		"peaks": _peaks()
		"corridor": _corridor_back()
		"library": _shelves()
		"nest": _nest_back()
		"arena": _arena_back()
	# 땅: 지평선 아래 (깊이: 위가 어둡고 아래가 밝음)
	var gr: Array = _p.ground
	pd.rect_grad(Rect2(0, RIDGE_Y, 640, 154), gr[0], gr[1])
	pd.draw_line(Vector2(0, RIDGE_Y), Vector2(640, RIDGE_Y), Color(fog, 0.5), 1.0)
	if motif == "lake":
		_lake()
	# 비스듬한 길 (왼쪽 아래 → 오른쪽 위)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0, 360), Vector2(150, 360), Vector2(640, 232), Vector2(640, 214), Vector2(560, 212)]), _c("path"))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(40, 360), Vector2(110, 360), Vector2(600, 236), Vector2(580, 226)]), Color(_c("lit"), 0.6))
	if motif in ["corridor", "arena", "library"]:
		_floor_tiles(motif)
	else:
		# 길 가장자리 결 (대각선 줄 몇 개 — 원근)
		for i in 7:
			var f := float(i) / 6.0
			pd.draw_line(Vector2(lerpf(-40, 180, f), 360), Vector2(640, lerpf(226, 290, f)), Color(_c("lit"), 0.18 + 0.1 * (1.0 - f)), 1.0)
	# 가로 띠 (바닥 층을 읽히게)
	for i in 5:
		var y := lerpf(215, 352, pow(float(i) / 4.0, 1.3))
		pd.draw_line(Vector2(0, y), Vector2(640, y + 2), Color(gr[0], 0.5), 1.0)
	if motif == "lava":
		_lava_cracks()
	# 바위·풀 (실내·서고는 돌 부스러기만)
	r.seed = 11
	var grass := _c("grass")
	for i in 26:
		var p := Vector2(r.randf_range(0, 640), r.randf_range(214, 356))
		var depth := (p.y - RIDGE_Y) / 154.0
		var s := 1.0 + depth * 1.6
		if i % 3 == 0 or interior or motif in ["library", "arena"]:
			pd.draw_colored_polygon(PackedVector2Array([p + Vector2(-3 * s, 0), p + Vector2(-1 * s, -2.4 * s), p + Vector2(2.4 * s, -1.6 * s), p + Vector2(3.2 * s, 0)]), gr[1].lightened(0.12))
			pd.draw_line(p + Vector2(-1 * s, -2.4 * s), p + Vector2(2.4 * s, -1.6 * s), gr[1].lightened(0.25), 0.8)
		else:
			var tall := 1.6 if motif == "lake" else 1.0 # 호수: 갈대
			for j in 4:
				var b := p + Vector2((float(j) - 1.5) * 1.6 * s, 0)
				pd.draw_line(b, b + Vector2(r.randf_range(-1.5, 1.5) * s + sin(_t * 1.5 + p.x) * 0.6, -r.randf_range(3.0, 6.0) * s * tall), grass, 0.9)
	# 양 진영 아래 빛 웅덩이 — 그림이 바닥에서 떠오르게 (마녀 쪽 · 적 쪽, review_C §8.3)
	pd.draw_set_transform(Vector2(160, 262), 0.0, Vector2(1.0, 0.35))
	pd.glow(Vector2.ZERO, 130.0, Color(_c("pa"), 0.35), 0.0)
	pd.glow(Vector2.ZERO, 120.0, Color("#b9a2ff", 0.10), 0.0)
	pd.draw_set_transform(Vector2(506, 262), 0.0, Vector2(1.0, 0.35))
	pd.glow(Vector2.ZERO, 130.0, Color("#3a4a4a", 0.30), 0.0)
	pd.glow(Vector2.ZERO, 120.0, Color(_c("pf"), 0.08), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	if motif in ["ruins", "prism", "lava", "lake", "peaks", "nest"]:
		_bushes(grass)
	# 캐릭터 허리 높이 옅은 안개 띠 (y 200~240) — 짙은 옷의 실루엣을 땅에서 뗌
	for i in 2:
		var fx := fposmod(_t * (5.0 + 3.0 * float(i)) + 420.0 * float(i), 1000.0) - 180.0
		pd.draw_set_transform(Vector2(fx, 222.0 + 10.0 * float(i)), 0.0, Vector2(1.0, 0.14))
		pd.glow(Vector2.ZERO, 200.0, Color(1, 1, 1, 0.06 * fk), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
	pd.rect_grad(Rect2(0, 200, 640, 20), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.035))
	pd.rect_grad(Rect2(0, 220, 640, 20), Color(1, 1, 1, 0.035), Color(1, 1, 1, 0.0))
	if motif == "corridor":
		_lanterns()
	# 아군 쪽 왼편 키 라이트 (적 쪽 차가운 빛과 온도를 나눔)
	pd.glow(Vector2(40, 330), 240.0, Color(_c("key"), 0.08), 0.0)
	# 앞쪽 바위 테두리 (아래 모서리 — 화면 앞 층, 아래 띠 뒤라 그림을 가리지 않음)
	var near: Color = _c("ridge").darkened(0.35)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0, 360), Vector2(0, 286), Vector2(18, 290), Vector2(34, 302), Vector2(52, 300), Vector2(70, 312), Vector2(76, 360)]), near)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(640, 360), Vector2(640, 280), Vector2(622, 286), Vector2(606, 298), Vector2(590, 296), Vector2(574, 310), Vector2(566, 360)]), near)
	pd.draw_line(Vector2(0, 286), Vector2(18, 290), Color(_c("lit"), 0.8), 1.0)
	pd.draw_line(Vector2(640, 280), Vector2(622, 286), Color(_c("lit"), 0.8), 1.0)
	_dust_draw()
	if motif == "peaks" and _bolt > 0.0:
		_lightning()
	# 가장자리 어둡게 + 아래 띠(아군 패널) 뒤를 더 어둡게 — 패널이 바탕과 섞이지 않게
	pd.ring_grad(Vector2(320, 180), Vector2(300, 170), Vector2(520, 330), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6), 40)
	pd.rect_grad(Rect2(0, 290, 640, 12), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.35))
	pd.draw_rect(Rect2(0, 302, 640, 58), Color(0, 0, 0, 0.35))
	if _veil > 0.0:
		pd.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.85 * _veil)) # 테마가 바뀌는 순간


# ── 먼 실루엣 ───────────────────────────────────────────────

## 들판·불길·프리즘: 무너진 탑(오른쪽 끝) + 불탄 나무
func _ruins(motif: String) -> void:
	var far := _c("far")
	pd.draw_colored_polygon(PackedVector2Array([Vector2(606, 206), Vector2(609, 142), Vector2(620, 136), Vector2(625, 150), Vector2(630, 146), Vector2(636, 206)]), far)
	pd.draw_rect(Rect2(616, 166, 3, 5), Color(_p.sky[2], 0.8)) # 창
	for tx: Array in [[60, 32], [96, 22], [150, 28], [230, 18], [410, 26], [470, 16], [620, 30]]:
		var x := float(tx[0])
		var h := float(tx[1]) * (1.2 if motif == "lava" else 1.0)
		pd.draw_line(Vector2(x, 208), Vector2(x + 2, 208 - h), far, 2.4)
		pd.draw_line(Vector2(x + 1, 208 - h * 0.6), Vector2(x - 7, 208 - h * 0.9), far, 1.4)
		pd.draw_line(Vector2(x + 1, 208 - h * 0.75), Vector2(x + 8, 208 - h), far, 1.4)
		pd.draw_line(Vector2(x, 208 - h * 0.4), Vector2(x - 5, 208 - h * 0.5), far, 1.0)
	if motif == "prism":
		# 떠 있는 빛 조각 셋 (세 속성 색) — 천천히 돈다
		for i in 3:
			var col: Color = [Color("#5ec8ff"), Color("#ffe34a"), Color("#ff8a3a")][i]
			var c := Vector2(170.0 + 150.0 * float(i), 150.0 + 8.0 * sin(_t * 0.8 + float(i) * 2.1))
			var a := _t * 0.6 + float(i)
			var pts := PackedVector2Array()
			for k in 4:
				var ang := a + float(k) * PI * 0.5
				pts.append(c + Vector2(cos(ang) * (5.0 if k % 2 == 0 else 3.0), sin(ang) * (9.0 if k % 2 == 0 else 3.5)))
			pd.glow(c, 16.0, Color(col, 0.18), 0.0)
			pd.draw_colored_polygon(pts, Color(col, 0.8))


## 호수: 맞은편 기슭의 침엽수 줄
func _far_trees() -> void:
	var far := _c("far")
	for i in 22:
		var x := 8.0 + 30.0 * float(i) + 9.0 * sin(float(i) * 2.3)
		var h := 14.0 + 9.0 * (0.5 + 0.5 * sin(float(i) * 1.7))
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 200), Vector2(x, 200 - h), Vector2(x + 6, 200)]), far)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 200 - h * 0.4), Vector2(x, 200 - h * 1.1), Vector2(x + 4, 200 - h * 0.4)]), far)


## 뇌운 고개: 가까운 바위 봉우리 둘 (양 옆)
func _peaks() -> void:
	var far := _c("far")
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0, 208), Vector2(0, 130), Vector2(22, 112), Vector2(46, 140), Vector2(70, 120), Vector2(104, 170), Vector2(130, 208)]), far)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(520, 208), Vector2(556, 150), Vector2(574, 160), Vector2(600, 118), Vector2(624, 136), Vector2(640, 128), Vector2(640, 208)]), far)
	pd.draw_line(Vector2(22, 112), Vector2(46, 140), Color(_c("lit"), 0.5 + 0.5 * _bolt), 1.0)
	pd.draw_line(Vector2(600, 118), Vector2(624, 136), Color(_c("lit"), 0.5 + 0.5 * _bolt), 1.0)


## 뇌운: 하늘을 덮는 먹구름 덩이 (천천히 흐름 · 번개 때 아래가 밝아짐)
func _clouds() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 21
	for i in 16:
		var x := fposmod(r.randf_range(0, 760) + _t * r.randf_range(3.0, 7.0), 760.0) - 60.0
		var y := r.randf_range(10, 110)
		var rad := r.randf_range(40, 80)
		var lit := _bolt * clampf(1.0 - absf(x - _bolt_x) / 260.0, 0.0, 1.0)
		pd.draw_set_transform(Vector2(x, y), 0.0, Vector2(1.0, 0.45))
		pd.glow(Vector2.ZERO, rad, Color("#2a3042", 0.7).lerp(Color("#c8d0ff", 0.7), lit * 0.5), 0.2)
		pd.draw_set_transform(Vector2.ZERO)


## 번개: 구름에서 지평선으로 꺾인 줄기 + 하늘이 잠깐 밝아짐 (화면 번쩍임 끔이면 밝아짐을 1/3로)
func _lightning() -> void:
	var fl := 1.0 if bool(GameState.settings.get("flash", true)) else 0.33
	pd.draw_rect(Rect2(0, 0, 640, 206), Color("#c8d0ff", 0.12 * _bolt * fl))
	var r := RandomNumberGenerator.new()
	r.seed = int(_bolt_x)
	var p := Vector2(_bolt_x, 40)
	var pts := PackedVector2Array([p])
	while p.y < 196.0:
		p += Vector2(r.randf_range(-16, 16), r.randf_range(14, 26))
		pts.append(p)
	for i in pts.size() - 1:
		pd.line2(pts[i], pts[i + 1], Color("#f0f4ff", _bolt), Color("#f0f4ff", _bolt), 2.0, 1.4)
	pd.glow(pts[pts.size() - 1], 30.0, Color("#c8d0ff", 0.3 * _bolt), 0.0)


## 세 빛의 인형: 하늘의 오로라 띠 셋 (물·번개·불 색, 천천히 물결)
func _aurora() -> void:
	var cols: Array = [Color("#5ec8ff"), Color("#ffe34a"), Color("#ff8a3a")]
	for b in 3:
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in 17:
			var x := 40.0 * float(i)
			var y := 38.0 + 22.0 * float(b) + 10.0 * sin(x * 0.012 + _t * 0.5 + float(b) * 1.7)
			left.append(Vector2(x, y))
			right.append(Vector2(x, y + 16.0))
		pd.strip_grad(left, right, Color(cols[b], 0.0), Color(cols[b], 0.10))


## 틈새 서고: 하늘에 갈라진 보랏빛 틈 (숨쉬듯 밝아짐)
func _rift_sky() -> void:
	var br := 0.7 + 0.3 * sin(_t * 1.6)
	var pts := PackedVector2Array([Vector2(260, 30), Vector2(282, 58), Vector2(270, 80), Vector2(298, 108), Vector2(290, 132), Vector2(318, 150)])
	pd.glow(Vector2(290, 92), 90.0, Color("#b9a2ff", 0.10 * br), 0.0)
	for i in pts.size() - 1:
		pd.line2(pts[i], pts[i + 1], Color("#e8dcff", 0.9 * br), Color("#e8dcff", 0.9 * br), 2.2, 1.6)
		pd.line2(pts[i], pts[i + 1], Color("#b9a2ff", 0.35 * br), Color("#b9a2ff", 0.35 * br), 6.0, 5.0)
	pd.draw_line(Vector2(282, 58), Vector2(306, 52), Color("#e8dcff", 0.6 * br), 1.0)
	pd.draw_line(Vector2(298, 108), Vector2(276, 116), Color("#e8dcff", 0.6 * br), 1.0)


## 틈새 서고: 지평선에 줄지어 선 책장 (책등 색 줄)
func _shelves() -> void:
	var far := _c("far")
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for s in 6:
		var x0 := -10.0 + 112.0 * float(s)
		var top := 128.0 + 10.0 * float(s % 2)
		pd.draw_rect(Rect2(x0, top, 92, RIDGE_Y - top), far)
		for row in 3:
			var y := top + 8.0 + 24.0 * float(row)
			pd.draw_rect(Rect2(x0 + 4, y + 16, 84, 2), Color(_c("lit"), 0.5))
			var bx := x0 + 6.0
			while bx < x0 + 86.0:
				var bw := r.randf_range(3.0, 6.0)
				var bh := r.randf_range(10.0, 15.0)
				pd.draw_rect(Rect2(bx, y + 16.0 - bh, bw - 1.0, bh), Color(["#3a2850", "#4a2a3a", "#2a3050", "#4a3a28"][r.randi() % 4], 0.85))
				bx += bw
		if s == 3: # 가운데 책장 하나는 틈이 지나가며 갈라짐
			pd.draw_line(Vector2(x0 + 40, top), Vector2(x0 + 52, RIDGE_Y), Color("#b9a2ff", 0.5), 1.4)


## 등불 회랑: 둥근 천장 아치 + 돌기둥 줄 (뒤) — 하늘 대신 천장
func _corridor_back() -> void:
	var far := _c("far")
	var stone: Color = (_p.ground as Array)[1]
	# 뒤 벽
	pd.rect_grad(Rect2(0, 90, 640, RIDGE_Y - 90), Color(stone.darkened(0.4), 0.9), Color(stone.darkened(0.2), 0.95))
	# 아치 (기둥 사이 둥근 천장)
	for i in 6:
		var x0 := -20.0 + 120.0 * float(i)
		var pts := PackedVector2Array()
		for k in 13:
			var a := PI + PI * float(k) / 12.0
			pts.append(Vector2(x0 + 60.0 + cos(a) * 52.0, 96.0 + sin(a) * 40.0))
		pd.draw_polyline(pts, Color(stone.lightened(0.08), 0.9), 3.0)
	# 기둥
	for i in 7:
		var x := -20.0 + 120.0 * float(i)
		pd.draw_rect(Rect2(x - 9, 40, 18, RIDGE_Y - 40), far)
		pd.draw_rect(Rect2(x - 12, 40, 24, 8), stone.lightened(0.05))
		pd.draw_rect(Rect2(x - 12, RIDGE_Y - 8, 24, 8), stone.lightened(0.05))
		pd.draw_line(Vector2(x - 4, 50), Vector2(x - 4, RIDGE_Y - 10), Color(_c("lit"), 0.35), 1.0)
	# 천장 그늘
	pd.rect_grad(Rect2(0, 0, 640, 60), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.0))


## 등불 회랑: 기둥 사이 매달린 등불 (흔들림 + 따뜻한 빛무리)
func _lanterns() -> void:
	for i in 6:
		var x := 40.0 + 120.0 * float(i)
		var sw := sin(_t * 1.4 + float(i) * 1.3) * 0.12
		var top := Vector2(x, 44)
		var c := top + Vector2(sin(sw) * 34.0, cos(sw) * 34.0)
		var fl := 0.85 + 0.15 * sin(_t * 9.0 + float(i) * 3.0)
		pd.draw_line(top, c, Color("#1a1210", 0.9), 1.0)
		pd.glow(c, 40.0, Color("#ffb04a", 0.14 * fl), 0.0)
		pd.glow(c, 14.0, Color("#ffd27a", 0.45 * fl), 0.0)
		pd.draw_rect(Rect2(c + Vector2(-3, -4), Vector2(6, 8)), Color("#ffd890", fl))
		pd.draw_rect(Rect2(c + Vector2(-4, -5), Vector2(8, 2)), Color("#2a1a12"))
		pd.draw_rect(Rect2(c + Vector2(-4, 3), Vector2(8, 2)), Color("#2a1a12"))
		pd.draw_set_transform(Vector2(c.x, 300), 0.0, Vector2(1.0, 0.25)) # 바닥에 비친 빛
		pd.glow(Vector2.ZERO, 50.0, Color("#ffb04a", 0.05 * fl), 0.0)
		pd.draw_set_transform(Vector2.ZERO)


## 바닥 돌판 결 (실내·서고·시련): 원근 세로줄 + 가로줄
func _floor_tiles(motif: String) -> void:
	var lit := _c("lit")
	for i in 12:
		var xb := -120.0 + 80.0 * float(i)
		pd.draw_line(Vector2(320.0 + (xb - 320.0) * 0.35, RIDGE_Y + 2.0), Vector2(xb, 360), Color(lit, 0.16), 1.0)
	if motif == "library":
		# 긴 양탄자 (자줏빛, 금테)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(60, 360), Vector2(120, 360), Vector2(620, 232), Vector2(598, 226)]), Color("#4a2240", 0.55))
		pd.draw_line(Vector2(60, 360), Vector2(598, 226), Color("#c8a060", 0.25), 1.0)
		pd.draw_line(Vector2(120, 360), Vector2(620, 232), Color("#c8a060", 0.25), 1.0)


## 불길의 골짜기: 땅의 용암 금 (숨쉬듯 빛남)
func _lava_cracks() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 17
	for i in 9:
		var p := Vector2(r.randf_range(20, 620), r.randf_range(222, 300))
		if p.x > 70.0 and p.x < 260.0 and p.y > 220.0:
			p.x += 220.0 # 마녀 발밑은 비움
		var br := 0.55 + 0.45 * sin(_t * 1.8 + float(i) * 1.7)
		var pts := PackedVector2Array([p])
		for k in 4:
			p += Vector2(r.randf_range(8, 18), r.randf_range(-4, 4))
			pts.append(p)
		for k in pts.size() - 1:
			pd.line2(pts[k], pts[k + 1], Color("#ff6a2a", 0.25 * br), Color("#ff6a2a", 0.25 * br), 4.0, 3.0)
			pd.line2(pts[k], pts[k + 1], Color("#ffc070", 0.8 * br), Color("#ffc070", 0.8 * br), 1.2, 1.0)


## 안개 호수: 지평선 아래 물 띠 + 달 그림자 + 물결 줄
func _lake() -> void:
	var w0 := RIDGE_Y
	var w1 := 236.0
	pd.rect_grad(Rect2(0, w0, 640, w1 - w0), Color("#1a3a5a", 0.85), Color("#10263a", 0.85))
	var mc: Vector2 = _p.get("mpos", Vector2(300, 96))
	for i in 8:
		var y := w0 + 3.0 + 3.6 * float(i)
		var half := 26.0 - 2.2 * float(i) + 3.0 * sin(_t * 2.0 + float(i))
		pd.draw_rect(Rect2(mc.x - half, y, half * 2.0, 1), Color(_c("moon"), 0.5 - 0.05 * float(i)))
	for i in 10:
		var x := fposmod(64.0 * float(i) + _t * 8.0, 680.0) - 20.0
		var y := w0 + 6.0 + 22.0 * float(i % 3) / 2.0
		pd.draw_line(Vector2(x, y), Vector2(x + 18, y), Color("#6a9ac8", 0.25), 1.0)
	pd.draw_line(Vector2(0, w1), Vector2(640, w1), Color("#4a6a88", 0.4), 1.0)


## 잿빛 둥지: 마른 가지 큰 실루엣 + 오른쪽 둥지 언덕
func _nest_back() -> void:
	var far := _c("far")
	for b: Array in [[40.0, 70.0], [130.0, 46.0], [470.0, 60.0], [560.0, 52.0]]:
		var x := float(b[0])
		var h := float(b[1])
		pd.line2(Vector2(x, 208), Vector2(x + 6, 208 - h), far, far, 5.0, 2.0)
		pd.line2(Vector2(x + 4, 208 - h * 0.55), Vector2(x - 18, 208 - h * 0.85), far, far, 2.6, 1.0)
		pd.line2(Vector2(x + 5, 208 - h * 0.75), Vector2(x + 24, 208 - h * 1.05), far, far, 2.4, 1.0)
		pd.line2(Vector2(x - 10, 208 - h * 0.78), Vector2(x - 20, 208 - h * 1.0), far, far, 1.4, 0.8)
	# 둥지 언덕 (오른쪽, 보스 뒤)
	var pts := PackedVector2Array()
	for k in 13:
		var a := PI + PI * float(k) / 12.0
		pts.append(Vector2(510.0 + cos(a) * 110.0, 208.0 + sin(a) * 34.0))
	pd.draw_colored_polygon(pts, far.lightened(0.04))
	for k in 9:
		var x := 420.0 + 22.0 * float(k)
		pd.draw_line(Vector2(x, 196 - 8.0 * sin(float(k) * 0.7)), Vector2(x + 26, 186 + 6.0 * sin(float(k))), Color(_c("lit"), 0.4), 1.0)


## 시련의 터: 반원으로 선 큰 돌기둥 (부러진 것 섞임)
func _arena_back() -> void:
	var far := _c("far")
	var lit := _c("lit")
	for i in 9:
		var x := 20.0 + 75.0 * float(i)
		var top := 96.0 + 14.0 * absf(float(i) - 4.0)
		if i == 2 or i == 6:
			top += 30.0 # 부러진 기둥
		pd.draw_rect(Rect2(x - 10, top, 20, RIDGE_Y - top), far)
		pd.draw_line(Vector2(x - 5, top + 4), Vector2(x - 5, RIDGE_Y - 4), Color(lit, 0.4), 1.0)
		pd.draw_rect(Rect2(x - 13, top - 5, 26, 6), far.lightened(0.06))


## 들판·불길·호수·고개·둥지: 땅의 바위 덤불 두 줄 (뒤 줄 y ≈ 214~222 · 앞 줄 y ≈ 296~300, 마녀·적이 서는 자리는 비움) — review_D C3
func _bushes(grass: Color) -> void:
	var gr: Array = _p.ground
	for row: Array in [[216.0, 0.8, [24, 250, 300, 360, 610]], [298.0, 1.6, [40, 300, 340, 400, 540]]]:
		var y0: float = row[0]
		var sc: float = row[1]
		for x0 in row[2]:
			var b := Vector2(float(x0), y0 + 3.0 * sin(float(x0)))
			for j in 3:
				var q := b + Vector2((float(j) - 1.0) * 5.0 * sc, -float(j % 2) * 1.0 * sc)
				pd.draw_colored_polygon(PackedVector2Array([q + Vector2(-3.4 * sc, 0), q + Vector2(-1.4 * sc, -3.0 * sc), q + Vector2(2.0 * sc, -2.6 * sc), q + Vector2(3.6 * sc, 0)]), (gr[1] as Color).lerp((gr[1] as Color).lightened(0.12), 0.5 * float(j % 2)))
				pd.draw_line(q + Vector2(-1.4 * sc, -3.0 * sc), q + Vector2(2.0 * sc, -2.6 * sc), Color((gr[1] as Color).lightened(0.25), 0.8), 0.8)
			for j in 5:
				var g := b + Vector2((float(j) - 2.0) * 3.2 * sc, 0)
				pd.draw_line(g, g + Vector2(sin(_t * 1.5 + float(x0) + float(j)) * 0.8, -(4.0 + 2.0 * float(j % 3)) * sc), grass.lightened(0.1), 0.9)


## 떠다니는 것: 재 · 불티(위로) · 반딧불 · 빗줄기 · 잿불 · 책장 · 먼지
func _dust_draw() -> void:
	var kind := String(_p.get("dust", "ash"))
	var col := _c("dcol")
	for a: Array in _dust:
		var p: Vector2 = a[0]
		var s := float(a[2])
		var ph := float(a[3])
		match kind:
			"ember", "cinder":
				var al := 0.35 + 0.45 * (0.5 + 0.5 * sin(_t * 4.0 + ph))
				pd.glow(p, 3.0 * s, Color(col, 0.25 * al), 0.0)
				pd.draw_rect(Rect2(p, Vector2(s, s)), Color(col.lightened(0.3), al))
			"mote":
				var al := 0.2 + 0.6 * pow(0.5 + 0.5 * sin(_t * 1.6 + ph), 3.0)
				pd.glow(p, 4.0 * s, Color(col, 0.22 * al), 0.0)
				pd.draw_rect(Rect2(p, Vector2(1, 1)), Color(col, al))
			"rain":
				pd.draw_line(p, p + Vector2(-3, 10), Color(col, 0.22), 1.0)
			"page":
				var ang := _t * 1.2 + ph
				var w := 5.0 * absf(cos(ang))
				pd.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, -3), p + Vector2(w, -2.5), p + Vector2(w, 3), p + Vector2(-w, 2.5)]), Color(col, 0.55))
			_:
				var al := 0.25 + 0.35 * (0.5 + 0.5 * sin(_t * 2.0 + ph))
				pd.draw_rect(Rect2(p, Vector2(s, s)), Color(col, al))
