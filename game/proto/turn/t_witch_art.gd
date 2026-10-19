class_name TWitchArt
extends PDraw.Canvas
## 마녀 11명(에스카 제외)의 코드 그림 틀 (키 약 40px, 원점 = 발밑 가운데, 오른쪽을 보는 모습 — 부모가 scale.x로 뒤집는다). 에스카(EArt)와 같은 비례·말투.
## "코드 그림 변형": 한 틀에 STYLE(모자·머리·옷·소품)과 PAL(색)을 조합해 마녀마다 다르게 그린다 (2026-10-18 사용자 선택).
##   모자  point_fwd(끝이 앞으로 꺾인 뾰족 모자, brim burnt=그을린 불씨 / fur=털) · soft_back(둥글고 끝이 뒤로 늘어짐, charm bell/star/clock)
##         wide(챙 넓고 낮은 모자) · wave(물결 챙) · hood(두건 망토) · crown_tall(높고 좁은 모자, 번개 문장) · band(모자 없이 리본 머리띠) · veil(검은 베일)
##   마녀별 실루엣 소품 (review_D C1): 이그니스 불꽃 모자 끝 · 신더 베일 · 글라시아 얼음 결정 · 풀구르 등의 망치 + 쌍갈래 · 토난 높은 모자 + 구름 장식 · 호라 시계 고리 후광
##   머리  fringe(앞머리) / spiky(뻗침) / bob(단발) + 뒤: braid(땋음) / long(긴 머리) / ponytail / none, 앞 줄: braid / lock
##   옷    coat(짧은 외투 + 비대칭 치마 + 긴 부츠) · coat_long(긴 외투) · robe(넓은 소매 로브) · dress(긴 드레스)
##   소품  glove(불타는 장갑) · lantern(등불) · censer(향로) · staff_orb(구슬 지팡이) · orb(떠 있는 구슬) · fan(부채) · staff_rod(피뢰침 지팡이) · watch(회중시계) · sword(흑백 검)
## 자세(pose): idle · cast(앞손을 뻗어 빛) · cast_big(두 팔을 펼치고 떠오름) · hit · win

const OUT := Color("#0a090e")
const RIM_LIGHT := Color(0.9, 0.86, 1.0, 0.5) ## 테두리 빛 (review_C §8.1 — 어두운 땅·보라 하늘과 떼어 읽히게)
const RIM_OFFS: Array[Vector2] = [Vector2(-0.5, -0.5), Vector2(0.5, 0.5)] ## 로컬 px (마녀 배율 2 → 화면 1px)
static var _rim_shader: Shader
static var _rim_mats := {} ## 색 → 재질
static var _shade_shader: Shader
static var _shade_mats := {} ## 키 → 재질
const RIM_OFFS_LIT: Array[Vector2] = [Vector2(-0.9, -0.9), Vector2(0.9, 0.9)] ## 차례인 마녀: 테두리 빛 2px · 속성 색 (검토 O §3)
## 검토 O §2·§3: 그림 전체 명암을 셰이더 하나로 (CPU 0 · 그리기 호출 그대로). 원점 = 발, 위 = −y.
## h = 그림 키 · hw = 반폭 · lift = 위 1/2을 흰빛 쪽으로 · drop = 아래 1/2을 어둡게 · side = 달 반대쪽(away 부호) 어둡게 ·
## black = 어두운 색(밝기 0.35 아래)만 달빛 색으로 들어 올림 — 밤 배경에서 검정·남색 옷이 묻히지 않게. 알파 0.85 아래(빛무리·그림자)는 그대로
const SHADE_SHADER := """
shader_type canvas_item;
uniform float h = 40.0;
uniform float hw = 12.0;
uniform float lift = 0.12;
uniform float drop = 0.28;
uniform float side = 0.10;
uniform float away = 1.0;
uniform float black = 0.0;
uniform vec3 black_tint = vec3(0.55, 0.5, 0.85);
varying vec2 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float solid = step(0.85, COLOR.a);
	float k = clamp(-lp.y / h, 0.0, 1.0);
	vec3 c = COLOR.rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c += black_tint * black * (1.0 - smoothstep(0.0, 0.35, luma)) * solid;
	c = mix(c, vec3(1.0), smoothstep(0.5, 1.0, k) * lift * solid);
	c *= 1.0 - ((1.0 - smoothstep(0.0, 0.5, k)) * drop + smoothstep(0.0, hw, lp.x * away) * side) * solid;
	COLOR.rgb = c;
}
"""

const STYLE := {
	"ignis": {"hat": "point_fwd", "brim": "burnt", "hair": "spiky", "back": "braid", "front": "lock", "outfit": "coat", "prop": "glove"},
	"ember": {"hat": "soft_back", "charm": "bell", "hair": "fringe", "back": "braid", "front": "braid", "outfit": "robe", "prop": "lantern"},
	"cinder": {"hat": "veil", "hair": "fringe", "back": "long", "front": "lock", "outfit": "dress", "prop": "censer"},
	"undine": {"hat": "wave", "hair": "fringe", "back": "long", "front": "lock", "outfit": "dress", "prop": "staff_orb"},
	"nerei": {"hat": "hood", "hair": "fringe", "back": "long", "front": "lock", "outfit": "robe", "prop": "orb"},
	"glacia": {"hat": "point_fwd", "brim": "fur", "hair": "bob", "back": "none", "front": "lock", "outfit": "coat", "prop": "fan"},
	"fulgur": {"hat": "crown_tall", "hair": "spiky", "back": "twin", "front": "lock", "outfit": "coat", "prop": "glove"},
	"astra": {"hat": "soft_back", "charm": "star", "hair": "fringe", "back": "ponytail", "front": "lock", "outfit": "robe", "prop": "orb"},
	"tonan": {"hat": "wide", "hair": "fringe", "back": "long", "front": "lock", "outfit": "coat_long", "prop": "staff_rod"},
	"hora": {"hat": "soft_back", "charm": "clock", "hair": "fringe", "back": "long", "front": "lock", "outfit": "dress", "prop": "watch"},
	"harpe": {"hat": "band", "hair": "bob", "back": "none", "front": "lock", "outfit": "coat", "prop": "sword"},
}

const PAL := {
	"ignis": {"hair": "#d8432b", "hair_hi": "#ff9a4a", "hair_sh": "#8e2418", "skin": "#efc9a6", "skin_sh": "#c99a78", "skin_hi": "#fbe6d2",
		"cloth": "#33262a", "cloth_hi": "#4a3639", "cloth_edge": "#5a3b3b", "inner": "#b8341f", "inner_hi": "#e0582f", "band": "#7a1e16",
		"hat": "#2a2030", "hat_hi": "#3e3046", "brim_edge": "#ff7a2a", "glow": "#ff8a3a", "glow_pale": "#ffd9a0", "eye": "#ffb347", "boot": "#120d10", "metal": "#d9a441"},
	"ember": {"hair": "#f0a850", "hair_hi": "#ffd28a", "hair_sh": "#b86f2a", "skin": "#f6dcc8", "skin_sh": "#d4ac92", "skin_hi": "#fff1e6",
		"cloth": "#f6e7cf", "cloth_hi": "#fff8ea", "cloth_edge": "#d9c3a2", "inner": "#f1a662", "inner_hi": "#ffc98a", "band": "#c4512e",
		"hat": "#efdcc0", "hat_hi": "#fbf0dc", "brim_edge": "#c4512e", "glow": "#ffb95a", "glow_pale": "#fff0c8", "eye": "#8a4a22", "boot": "#6b3a24", "metal": "#c9933a"},
	"cinder": {"hair": "#7a6f7a", "hair_hi": "#ffb067", "hair_sh": "#4a414b", "skin": "#ead9cf", "skin_sh": "#c4ada3", "skin_hi": "#f8ede6",
		"cloth": "#5a5460", "cloth_hi": "#746d7a", "cloth_edge": "#8a8290", "inner": "#8a3a2a", "inner_hi": "#c9623a", "band": "#5a2a22",
		"hat": "#1a1520", "hat_hi": "#40353f", "brim_edge": "#c9623a", "glow": "#ff8a3a", "glow_pale": "#ffd9a0", "eye": "#ff9a4a", "boot": "#15101a", "metal": "#b08a4a"},
	"undine": {"hair": "#2f7fd6", "hair_hi": "#8fd4ff", "hair_sh": "#1c4f8f", "skin": "#f3e2d6", "skin_sh": "#cdb3a6", "skin_hi": "#fbf0ea",
		"cloth": "#1d3b6b", "cloth_hi": "#2c5c9c", "cloth_edge": "#4a86c9", "inner": "#8fd4ff", "inner_hi": "#dff6ff", "band": "#dff6ff",
		"hat": "#1a2f55", "hat_hi": "#28457a", "brim_edge": "#8fd4ff", "glow": "#3fb0ff", "glow_pale": "#dff6ff", "eye": "#9fe8ff", "boot": "#12213d", "metal": "#c9d9e8"},
	"nerei": {"hair": "#a8dcf5", "hair_hi": "#f0fbff", "hair_sh": "#6fa9cc", "skin": "#f7e6dc", "skin_sh": "#d6b9ab", "skin_hi": "#fff4ee",
		"cloth": "#eef7fb", "cloth_hi": "#ffffff", "cloth_edge": "#c9dde8", "inner": "#7fc4e8", "inner_hi": "#bfe6f7", "band": "#4f93c2",
		"hat": "#dcedf7", "hat_hi": "#f3fafd", "brim_edge": "#4f93c2", "glow": "#9fe8ff", "glow_pale": "#ffffff", "eye": "#3a7ab8", "boot": "#5c7f99", "metal": "#d8c38a"},
	"glacia": {"hair": "#eaf6ff", "hair_hi": "#ffffff", "hair_sh": "#a9c7dd", "skin": "#f4ece9", "skin_sh": "#cbbfbc", "skin_hi": "#ffffff",
		"cloth": "#4a83b0", "cloth_hi": "#6aa2cc", "cloth_edge": "#ffffff", "inner": "#bfe9ff", "inner_hi": "#ffffff", "band": "#9fd0ee",
		"hat": "#253a52", "hat_hi": "#33506d", "brim_edge": "#ffffff", "glow": "#bfe9ff", "glow_pale": "#ffffff", "eye": "#79c6ff", "boot": "#15202e", "metal": "#c8dbe8"},
	"fulgur": {"hair": "#fff1a8", "hair_hi": "#ffffff", "hair_sh": "#d1b24a", "skin": "#f0cfa8", "skin_sh": "#c9a47e", "skin_hi": "#fbe6cc",
		"cloth": "#4a3a78", "cloth_hi": "#5e4c96", "cloth_edge": "#ffe34a", "inner": "#ffe34a", "inner_hi": "#fff6b0", "band": "#9a7cff",
		"hat": "#2e2546", "hat_hi": "#41365e", "brim_edge": "#ffe34a", "glow": "#ffe34a", "glow_pale": "#fff8d0", "eye": "#ffe34a", "boot": "#141022", "metal": "#ffd84a"},
	"astra": {"hair": "#8c6fe0", "hair_hi": "#c9b3ff", "hair_sh": "#5a44a0", "skin": "#f6e3d8", "skin_sh": "#d4b9ac", "skin_hi": "#fff2ea",
		"cloth": "#f4efff", "cloth_hi": "#ffffff", "cloth_edge": "#cfc1ea", "inner": "#ffe34a", "inner_hi": "#fff8d0", "band": "#7a5fd0",
		"hat": "#5a3fa8", "hat_hi": "#7a5fd0", "brim_edge": "#ffe34a", "glow": "#ffe34a", "glow_pale": "#fff8d0", "eye": "#7a5fd0", "boot": "#4a3a7a", "metal": "#ffe34a"},
	"tonan": {"hair": "#2c3466", "hair_hi": "#ffe34a", "hair_sh": "#1b2040", "skin": "#e8d2c0", "skin_sh": "#c2a994", "skin_hi": "#f6e6d8",
		"cloth": "#2a3054", "cloth_hi": "#3a4270", "cloth_edge": "#515aa0", "inner": "#ffe34a", "inner_hi": "#fff6b0", "band": "#3f4a9a",
		"hat": "#252a4a", "hat_hi": "#343b63", "brim_edge": "#ffe34a", "glow": "#ffe34a", "glow_pale": "#ffffff", "eye": "#ffe34a", "boot": "#10132a", "metal": "#b9c0e8"},
	"hora": {"hair": "#e9d8a8", "hair_hi": "#fff8e0", "hair_sh": "#b39a66", "skin": "#f6e8dc", "skin_sh": "#d2bcae", "skin_hi": "#fff6ee",
		"cloth": "#8a5a2c", "cloth_hi": "#a8743e", "cloth_edge": "#f3e4c4", "inner": "#f6e8c8", "inner_hi": "#fffaf0", "band": "#f2d27a",
		"hat": "#382a46", "hat_hi": "#4c3a5e", "brim_edge": "#f2d27a", "glow": "#f2d27a", "glow_pale": "#fff8e0", "eye": "#c9a24a", "boot": "#1f1628", "metal": "#f2d27a"},
	"harpe": {"hair": "#15121b", "hair_hi": "#f2eff7", "hair_sh": "#0a090e", "skin": "#f0e6e2", "skin_sh": "#c9b4b4", "skin_hi": "#fff8f4",
		"cloth": "#f2eff7", "cloth_hi": "#ffffff", "cloth_edge": "#cfc9dc", "inner": "#14081f", "inner_hi": "#3b1268", "band": "#14081f",
		"hat": "#14081f", "hat_hi": "#2a1540", "brim_edge": "#f2eff7", "glow": "#e6dcff", "glow_pale": "#ffffff", "eye": "#b9a2ff", "boot": "#14081f", "metal": "#cfc9dc"},
}

var kind := "ignis"
var pose := "idle"
var fade := 1.0 ## 쓰러지면 옅어짐 (TActor가 내린다)
var glow := 0.0 ## 손·소품의 빛 (0~1) — 시전 중 1

var _s: Dictionary
var _p := {}
var _t := 0.0
var _sq := Vector2.ONE
var _sq_v := Vector2.ZERO
var _lean := 0.0
var _lean_v := 0.0
var _lift := 0.0
var _big := 0.0
var _hand := Vector2(3, -15.5)
var _back_hand := Vector2(-2.0, -15.0)
var _hurt_flash := 0.0
var _tip := 0.0
var _tip_v := 0.0
var _hair: EArt.Chain
var _hair2: EArt.Chain
var _sleeve: EArt.Chain
var _ready_done := false
var _flicker := 0.0
var _white := 0.0 ## 맞은 순간 흰 번쩍 (0.06초)
var _kneel := 0.0 ## 쓰러짐 무릎 자세 (0~1)
var _blink := 0.0
var _rim_ci := RID()
var _rng := RandomNumberGenerator.new() ## 눈 깜빡임 (전역 난수를 건드리지 않게)
var lit := false ## 차례인 마녀 (TActor.set_turn) — 테두리 빛이 속성 색 2px


func _ready() -> void:
	_s = STYLE.get(kind, STYLE.ember)
	for k in PAL.get(kind, PAL.ember):
		_p[k] = Color(String(PAL.get(kind, PAL.ember)[k]))
	_rim_ci = rim_make(self, RIM_LIGHT)
	material = shade_mat(44.0, 11.0, 0.12, 0.16, 0.06, -1.0, 0.16) # 달(화면 가운데 위)이 마녀의 오른쪽 위 — 왼쪽(뒤)이 그늘


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rim_ci.is_valid():
		RenderingServer.free_rid(_rim_ci)


func _draw() -> void:
	_paint()
	rim_paint(_rim_ci, pd, (RIM_OFFS_LIT if lit else RIM_OFFS) if fade >= 0.99 else []) # 옅어지는 중엔 끔 (흰 실루엣이 비침)
	pd.flush(self)


## 테두리 빛 그림 자리 (EArt와 같은 방법 — 몸 뒤에 한 색으로). 적 그림(TEnemyArt)도 같이 쓴다
static func rim_make(ci: CanvasItem, col: Color, shaded := true) -> RID:
	var rid := RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(rid, ci.get_canvas_item())
	RenderingServer.canvas_item_set_draw_behind_parent(rid, true)
	if shaded:
		rim_set(rid, col)
	return rid


## 테두리 빛 색 바꾸기 (차례인 마녀 = 속성 색 — 검토 O §3). 색마다 재질 하나를 나눠 씀
static func rim_set(rid: RID, col: Color) -> void:
	if _rim_shader == null:
		_rim_shader = Shader.new()
		# 턴제만: 알파를 0/1로 자르지 않고 그대로 곱함 — 부모(HUD 초상)가 옅어질 때 테두리만 흰 유령으로 남던 것 (review_D A4)
		_rim_shader.code = EArt.RIM_SHADER.replace("step(0.001, COLOR.a)", "COLOR.a")
	var mat: ShaderMaterial = _rim_mats.get(col)
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = _rim_shader
		mat.set_shader_parameter("rim", col)
		_rim_mats[col] = mat
	RenderingServer.canvas_item_set_material(rid, mat.get_rid())


## 명암 재질 (SHADE_SHADER) — 같은 값이면 하나를 나눠 씀
static func shade_mat(h: float, hw: float, lift: float, drop: float, side: float, away: float, black := 0.0) -> ShaderMaterial:
	var key := "%.1f|%.1f|%.2f|%.2f|%.2f|%.0f|%.2f" % [h, hw, lift, drop, side, away, black]
	var mat: ShaderMaterial = _shade_mats.get(key)
	if mat == null:
		if _shade_shader == null:
			_shade_shader = Shader.new()
			_shade_shader.code = SHADE_SHADER
		mat = ShaderMaterial.new()
		mat.shader = _shade_shader
		for kv: Array in [["h", h], ["hw", hw], ["lift", lift], ["drop", drop], ["side", side], ["away", away], ["black", black]]:
			mat.set_shader_parameter(kv[0], kv[1])
		_shade_mats[key] = mat
	return mat


## 방향마다 색이 다른 테두리 (적 — 검토 O §2): 재질 없는 rid에 offs[i]만큼 밀어 cols[i] 한 색으로. 그리기 명령 수 = offs 수 (전과 같이 2)
static func rim_paint_cols(rid: RID, pd: PDraw, offs: Array, cols: Array) -> void:
	if not rid.is_valid():
		return
	RenderingServer.canvas_item_clear(rid)
	var n := pd.idx.size()
	if n == 0 or offs.is_empty():
		return
	var cs := pd.c
	var keep := PackedInt32Array()
	keep.resize(n)
	var k := 0
	var idx := pd.idx
	for i in range(0, n, 3):
		if cs[idx[i]].a >= EArt.RIM_SOLID and cs[idx[i + 1]].a >= EArt.RIM_SOLID and cs[idx[i + 2]].a >= EArt.RIM_SOLID:
			keep[k] = idx[i]
			keep[k + 1] = idx[i + 1]
			keep[k + 2] = idx[i + 2]
			k += 3
	if k == 0:
		return
	keep.resize(k)
	var fill := PackedColorArray()
	fill.resize(cs.size())
	for j in offs.size():
		fill.fill(cols[j])
		RenderingServer.canvas_item_add_set_transform(rid, Transform2D(0.0, offs[j]))
		RenderingServer.canvas_item_add_triangle_array(rid, keep, pd.v, fill)


## 모은 그림 중 진한 삼각형(세 꼭짓점 알파 EArt.RIM_SOLID 이상)만 골라 offs만큼 밀어 rid에 그린다 (pd.flush 전에)
static func rim_paint(rid: RID, pd: PDraw, offs: Array) -> void:
	if not rid.is_valid():
		return
	RenderingServer.canvas_item_clear(rid)
	var idx := pd.idx
	var n := idx.size()
	if n == 0:
		return
	var cols := pd.c
	var keep := PackedInt32Array()
	keep.resize(n)
	var k := 0
	for i in range(0, n, 3):
		var a := idx[i]
		var b := idx[i + 1]
		var c := idx[i + 2]
		if cols[a].a >= EArt.RIM_SOLID and cols[b].a >= EArt.RIM_SOLID and cols[c].a >= EArt.RIM_SOLID:
			keep[k] = a
			keep[k + 1] = b
			keep[k + 2] = c
			k += 3
	if k == 0:
		return
	keep.resize(k)
	for off: Vector2 in offs:
		RenderingServer.canvas_item_add_set_transform(rid, Transform2D(0.0, off))
		RenderingServer.canvas_item_add_triangle_array(rid, keep, pd.v, cols)


func _ensure() -> void:
	if _ready_done:
		return
	_ready_done = true
	_hair = EArt.Chain.new()
	_hair.setup(_to_g(_hair_rest()), 2.9)
	_hair2 = EArt.Chain.new()
	_hair2.setup(_to_g(_hair2_rest()), 2.6)
	_sleeve = EArt.Chain.new()
	_sleeve.setup(_to_g(_sleeve_rest(Vector2(1.5, -21.0))), 2.6)


func _to_g(pts: PackedVector2Array) -> PackedVector2Array:
	return global_transform * pts


func _hair_root() -> Vector2:
	if _s.back == "ponytail":
		return Vector2(-3.0, -33.0)
	return Vector2(-2.6, -30.5)


func _hair_rest() -> PackedVector2Array:
	var r := PackedVector2Array()
	var root := _hair_root()
	var n := 8 if _s.back in ["long", "ponytail"] else 7
	for i in n:
		r.append(root + Vector2(-0.5 * float(i), 2.9 * float(i)))
	return r


func _hair2_rest() -> PackedVector2Array:
	var r := PackedVector2Array()
	var n := 5 if _s.front == "braid" else 3
	for i in n:
		r.append(Vector2(3.4 + 0.25 * float(i), -29.0 + 2.6 * float(i)))
	return r


func _sleeve_rest(root: Vector2) -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in 4:
		r.append(root + Vector2(-1.0 * float(i), 2.6 * float(i)))
	return r


func set_pose(p: String) -> void:
	if p == "cast_big" and pose != "cast_big":
		squash(Vector2(1.14, 0.84)) # 0.15초 웅크렸다 펼침 (예비 동작)
	pose = p


func squash(s: Vector2) -> void:
	_sq = s
	_sq_v = Vector2.ZERO


func hurt() -> void:
	_hurt_flash = 1.0
	_white = 0.06
	squash(Vector2(1.18, 0.84))


func reset_chains() -> void:
	if not _ready_done:
		return
	_hair.snap_to(_to_g(_hair_rest()))
	_hair2.snap_to(_to_g(_hair2_rest()))
	_sleeve.snap_to(_to_g(_sleeve_rest(Vector2(1.5, -21.0))))


func _bob() -> float:
	return -0.5 * (0.5 + 0.5 * sin(_t * 2.4)) if pose == "idle" else 0.0


func _hand_target() -> Vector2:
	match pose:
		"cast":
			return Vector2(12.0, -24.0)
		"cast_big":
			return Vector2(11.5, -32.0)
		"hit":
			return Vector2(5.0, -19.0)
		"win":
			return Vector2(8.0, -36.0)
	match String(_s.prop):
		"lantern", "censer", "watch":
			return Vector2(5.5, -17.5)
		"staff_orb", "staff_rod":
			return Vector2(6.5, -19.0)
		"sword":
			return Vector2(4.0, -16.0)
	return Vector2(3.0, -15.5)


func _back_hand_target() -> Vector2:
	match pose:
		"cast_big":
			return Vector2(-10.5, -31.0)
		"cast":
			return Vector2(-4.5, -17.0)
	return Vector2(-2.0, -15.0)


func hand_global() -> Vector2:
	return to_global(_hand + Vector2(0, _bob()))


## 소품의 빛나는 자리(전역)
func prop_global() -> Vector2:
	match String(_s.prop):
		"lantern", "censer", "watch":
			return to_global(_hand + Vector2(1.5, 4.5 + _bob()))
		"staff_orb", "staff_rod":
			return to_global(_hand + Vector2(1.0, -14.0 + _bob()))
		"orb":
			return to_global(_hand + Vector2(2.0, -7.0 + _bob()))
	return hand_global()


func tick(delta: float) -> void:
	_ensure()
	if delta <= 0.0:
		return
	_t += delta
	var dt := minf(delta, 1.0 / 30.0)
	_sq_v += (Vector2.ONE - _sq) * 320.0 * dt - _sq_v * 20.0 * dt
	_sq += _sq_v * dt
	var lean_want := 0.0
	match pose:
		"cast": lean_want = 0.12
		"cast_big": lean_want = -0.07
		"hit": lean_want = -0.1
		"down": lean_want = 0.3
	_kneel = move_toward(_kneel, 1.0 if pose == "down" else 0.0, dt * 4.0)
	_lean_v += (lean_want - _lean) * 260.0 * dt - _lean_v * 18.0 * dt
	_lean += _lean_v * dt
	_big = move_toward(_big, 1.0 if pose == "cast_big" else 0.0, dt * (5.0 if pose == "cast_big" else 3.0))
	_lift = lerpf(_lift, 9.0 * _big, 1.0 - exp(-dt * 6.0))
	_tip_v += (-_tip * 140.0 - _tip_v * 6.0 + (_big * 60.0)) * dt
	_tip += _tip_v * dt
	_hand = _hand.lerp(_hand_target(), 1.0 - exp(-dt * 30.0))
	_back_hand = _back_hand.lerp(_back_hand_target(), 1.0 - exp(-dt * 24.0))
	var glow_want := 1.0 if pose in ["cast", "cast_big", "win"] else 0.0
	glow = move_toward(glow, glow_want, dt * 6.0)
	_hurt_flash = maxf(_hurt_flash - dt * 5.0, 0.0)
	_white = maxf(_white - delta, 0.0)
	_blink = maxf(_blink - delta, 0.0)
	if _blink <= 0.0 and pose == "idle" and _rng.randf() < dt * 0.35:
		_blink = 0.12
	_flicker = 0.75 + 0.25 * sin(_t * 23.0) * sin(_t * 7.3 + 1.0)
	if _white > 0.0:
		modulate = Color(2.4, 2.4, 2.4, fade)
	else:
		modulate = Color(1.0, 1.0 - 0.55 * _hurt_flash, 1.0 - 0.5 * _hurt_flash, fade)
	scale = _sq * Vector2(1.0 + 0.06 * _kneel, 1.0 - 0.2 * _kneel)
	rotation = _lean
	var pivot := Vector2(0, -18.0 * _sq.y)
	position = Vector2(0, -_lift) + pivot.rotated(_lean) - pivot.rotated(rotation)
	var grav := Vector2(0, 460).lerp(Vector2(-90.0 + sin(_t * 7.0) * 120.0, -380.0), _big)
	var stiff := 0.12 * (1.0 - 0.6 * _big)
	var bob := _bob()
	_hair.step(to_global(_hair_root() + Vector2(0, bob)), _to_g(_hair_rest()), grav, dt, 0.82, stiff)
	_hair2.step(to_global(Vector2(3.4, -29.0 + bob)), _to_g(_hair2_rest()), grav, dt, 0.86, 0.14)
	var sh := Vector2(1.5, -23.5 + bob)
	var el := sh.lerp(_hand, 0.5)
	var sleeve_g := Vector2(0, 300.0).lerp(Vector2(sin(_t * 9.0) * 80.0, -260.0), _big)
	_sleeve.step(to_global(el), _to_g(_sleeve_rest(el)), sleeve_g, dt, 0.86, 0.08)
	queue_redraw()


func _ribbon(ch: PackedVector2Array, w0: float, w1: float, off := 0.0) -> Array:
	var inv := global_transform.affine_inverse()
	var loc := inv * ch
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	var n := loc.size()
	for i in n:
		var a := loc[maxi(i - 1, 0)]
		var b := loc[mini(i + 1, n - 1)]
		var nrm := (b - a).normalized().orthogonal()
		var w := lerpf(w0, w1, float(i) / float(n - 1)) * 0.5
		l.append(loc[i] + nrm * (w + off))
		r.append(loc[i] - nrm * (w - off))
	return [l, r, loc]


func _grow(edge: PackedVector2Array, center: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in edge.size():
		var dv := edge[i] - center[i]
		var l := dv.length()
		out.append(edge[i] + (dv / l * d if l > 0.0001 else Vector2.ZERO))
	return out


func _braid(ch: PackedVector2Array, w0: float, w1: float) -> void:
	var r := _ribbon(ch, w0, w1)
	pd.strip(_grow(r[0], r[2], 0.8), _grow(r[1], r[2], 0.8), OUT)
	pd.strip(r[0], r[1], _p.hair_sh)
	var hi := _ribbon(ch, w0 * 0.55, w1 * 0.5, -0.5)
	pd.strip(hi[0], hi[1], _p.hair)
	var loc: PackedVector2Array = r[2]
	for i in range(1, loc.size() - 1):
		var a := loc[i - 1]
		var b := loc[i]
		var nrm := (b - a).normalized().orthogonal()
		var w := lerpf(w0, w1, float(i) / float(loc.size() - 1)) * 0.5
		var s := 1.0 if i % 2 == 0 else -1.0
		pd.draw_line(b + nrm * w * s, a - nrm * w * 0.4 * s, _p.hair_hi, 0.7)


## 긴 머리: 먹 테 + 그늘 + 중간 + 빛 세 겹 (EArt의 뒤 머리와 같은 말투)
func _long_hair(ch: PackedVector2Array) -> void:
	var hr := _ribbon(ch, 7.0, 2.4)
	pd.strip(_grow(hr[0], hr[2], 0.8), _grow(hr[1], hr[2], 0.8), OUT)
	pd.strip(hr[0], hr[1], _p.hair_sh)
	var hi := _ribbon(ch, 4.0, 1.2, -0.9)
	pd.strip(hi[0], hi[1], _p.hair)
	var hl := _ribbon(ch, 1.6, 0.4, -1.6)
	pd.strip(hl[0], hl[1], _p.hair_hi)


func _tip_of(ch: PackedVector2Array) -> Vector2:
	var pts: PackedVector2Array = _ribbon(ch, 1.0, 1.0)[2]
	return pts[pts.size() - 1]


func _paint() -> void:
	if not _ready_done:
		return
	var bob := _bob()
	var o := Vector2(0, bob)
	# 바닥 그림자
	pd.draw_set_transform(Vector2(0, _lift), 0.0, Vector2(1.0, 0.24))
	pd.glow(Vector2.ZERO, 10.0 - _lift * 0.6, Color(0, 0, 0, 0.55), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	if _big > 0.0:
		_paint_big_ring(o)
	# 뒷팔
	var bsh := o + Vector2(-1.6, -23.0)
	var bh := _back_hand + o
	var bel := bsh.lerp(bh, 0.5) + Vector2(0, 1.2)
	if _s.outfit == "robe":
		var bs := _ribbon(PackedVector2Array([to_global(bsh), to_global(bel), to_global(bh + Vector2(-1.0, 2.0))]), 3.6, 6.0)
		pd.strip(bs[0], bs[1], Color(_p.cloth, 0.75))
	pd.draw_line(bsh, bel, _p.skin_sh, 1.6)
	pd.draw_line(bel, bh, _p.skin_sh, 1.4)
	pd.draw_circle(bh, 1.1, _p.skin_sh)
	if _big > 0.0:
		pd.glow(bh, 5.0, Color(_p.glow, 0.45 * _big), 0.0)
		pd.draw_circle(bh, 1.2, Color(1, 1, 1, 0.9 * _big))
	# 두건은 몸 뒤에 망토부터
	if _s.hat == "hood":
		_paint_cape(o)
	if kind == "hora": # 머리 뒤 시계 고리 후광
		var hc := o + Vector2(0.6, -31.0)
		pd.glow(hc, 11.0, Color(_p.glow, 0.18), 0.0)
		pd.draw_arc(hc, 9.0, 0.0, TAU, 28, Color(_p.metal, 0.6), 0.9)
		for i in 12:
			var d := Vector2.from_angle(TAU * float(i) / 12.0)
			pd.draw_line(hc + d * (8.0 if i % 3 == 0 else 8.5), hc + d * 9.6, Color(_p.metal, 0.75), 0.6)
		pd.draw_line(hc, hc + Vector2.from_angle(_t * 0.6) * 7.0, Color(_p.metal, 0.35), 0.5)
	elif kind == "fulgur": # 등에 멘 작은 망치 (대마법 뇌신의 철퇴와 같은 모양)
		var hb := o + Vector2(-5.4, -15.0)
		pd.draw_line(hb, hb + Vector2(3.0, -13.0), OUT, 2.0)
		pd.draw_line(hb, hb + Vector2(3.0, -13.0), Color("#6a4a2a"), 1.1)
		var hh := hb + Vector2(3.4, -14.0)
		var head := PackedVector2Array([hh + Vector2(-4.0, -1.0), hh + Vector2(3.4, -2.6), hh + Vector2(4.4, 1.8), hh + Vector2(-3.4, 3.2)])
		pd.outlined(head, _p.cloth, OUT, 0.7)
		pd.draw_line(hh + Vector2(-0.6, -1.4), hh + Vector2(0.8, 1.6), _p.metal, 0.7)
	# 뒤 머리
	match String(_s.back):
		"braid":
			_braid(_hair.p, 3.6 if kind == "ember" else 2.6, 2.2 if kind == "ember" else 1.4)
			var tipp := _tip_of(_hair.p)
			if kind == "ember":
				pd.draw_line(tipp + Vector2(-1.6, 0.0), tipp + Vector2(1.6, 0.0), _p.band, 1.4)
				pd.draw_circle(tipp + Vector2(0, 1.6), 1.0, _p.hair_hi)
			else:
				pd.draw_circle(tipp + Vector2(0, 1.0), 1.4, OUT)
				pd.draw_circle(tipp + Vector2(0, 1.0), 0.9, _p.metal)
		"long":
			_long_hair(_hair.p)
		"ponytail":
			_long_hair(_hair.p)
			pd.draw_line(o + Vector2(-4.4, -33.0), o + Vector2(-1.6, -33.4), _p.band, 1.6) # 묶은 리본
		"twin": # 쌍갈래 (풀구르): 머리 양옆 뒤로 짧게 뻗친 두 갈래
			for i in 2:
				var root := o + Vector2(-3.6 + 1.0 * float(i), -31.0 + 1.6 * float(i))
				var sway := sin(_t * 4.0 + float(i) * 1.7) * 0.8
				var tip := root + Vector2(-6.0 - _big * 2.0, 4.0 + 3.0 * float(i) + sway)
				var mid := root.lerp(tip, 0.5) + Vector2(0, -1.4)
				pd.draw_polyline(PackedVector2Array([root, mid, tip]), OUT, 3.2)
				pd.draw_polyline(PackedVector2Array([root, mid, tip]), _p.hair, 2.0)
				pd.draw_line(mid, tip, _p.hair_hi, 0.6)
				pd.draw_circle(root, 1.0, _p.band)
	_paint_outfit(o)
	_paint_head(o)
	_paint_hat(o)
	_paint_front_arm(o)


# ═══════════════════════════════════════════════════════════
# 옷
# ═══════════════════════════════════════════════════════════

func _paint_outfit(o: Vector2) -> void:
	var waist := -16.0 + o.y
	match String(_s.outfit):
		"coat":
			# 비대칭 짧은 치마 + 긴 부츠, 안감이 비침
			var hem := PackedVector2Array([Vector2(-3.4, waist), Vector2(3.6, waist), Vector2(6.0, waist + 6.0), Vector2(2.0, waist + 7.5),
				Vector2(-3.0, waist + 9.5), Vector2(-7.5 - _big * 1.5, waist + 11.0), Vector2(-6.5, waist + 4.0)])
			pd.outlined(hem, _p.cloth, OUT, 0.8)
			pd.draw_line(Vector2(-5.4, waist + 9.4), Vector2(-7.0 - _big * 1.5, waist + 10.6), _p.inner, 1.2)
			pd.draw_line(Vector2(0.5, waist + 1.0), Vector2(4.6, waist + 5.6), _p.cloth_hi, 1.0)
			var hip := Vector2(1.6, waist + 5.0)
			var foot := Vector2(3.8, -1.0)
			pd.draw_line(hip, foot, _p.skin, 1.8)
			pd.draw_line(hip + Vector2(0, 4.0), foot, _p.boot, 2.6)
			pd.draw_line(hip + Vector2(0.4, 4.5), foot + Vector2(0.4, -1.0), _p.cloth_edge, 0.6)
			pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.6, -1.0), foot + Vector2(2.4, -0.4), foot + Vector2(2.8, 0.8), foot + Vector2(-1.4, 0.8)]), _p.boot)
			var hip2 := Vector2(-1.8, waist + 5.0)
			var foot2 := Vector2(-2.6, -1.0)
			pd.draw_line(hip2, foot2, _p.boot, 2.4)
			pd.draw_colored_polygon(PackedVector2Array([foot2 + Vector2(-1.4, -1.0), foot2 + Vector2(2.0, -0.4), foot2 + Vector2(2.2, 0.8), foot2 + Vector2(-1.2, 0.8)]), OUT)
			_paint_torso_coat(waist)
		"coat_long":
			var flare := 1.0 + 0.4 * _big
			var hem := PackedVector2Array([Vector2(-3.6, waist), Vector2(3.6, waist), Vector2(6.8 * flare, -0.8), Vector2(1.2, -1.6), Vector2(-7.6 * flare, -1.2), Vector2(-6.2, waist + 6.0)])
			pd.outlined(hem, _p.cloth, OUT, 0.8)
			pd.draw_line(Vector2(0.4, waist + 1.0), Vector2(0.8, -1.6), _p.inner, 0.9) # 앞트임 사이 안감
			pd.draw_line(Vector2(1.6, waist + 1.5), Vector2(5.0 * flare, -3.0), _p.cloth_hi, 1.0)
			pd.draw_line(Vector2(-1.8, waist + 2.0), Vector2(-5.2 * flare, -3.5), _p.cloth_edge, 0.8)
			var foot := Vector2(2.6, -0.6)
			pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.6, -1.6), foot + Vector2(2.0, -1.0), foot + Vector2(2.4, 0.6), foot + Vector2(-1.4, 0.6)]), _p.boot)
			_paint_torso_coat(waist)
		"robe":
			var flare := 1.0 + 0.5 * _big
			var hem := PackedVector2Array([Vector2(-3.6, waist), Vector2(3.6, waist), Vector2(7.6 * flare, -0.6), Vector2(2.0, -1.8), Vector2(-2.5, -0.8), Vector2(-8.4 * flare, -1.4), Vector2(-6.6, waist + 6.0)])
			pd.outlined(hem, _p.cloth, OUT, 0.8)
			pd.draw_line(Vector2(6.4 * flare, -1.4), Vector2(-7.2 * flare, -2.2), _p.band, 1.2)
			pd.draw_line(Vector2(1.2, waist + 1.5), Vector2(4.8 * flare, -3.0), _p.cloth_hi, 1.0)
			pd.draw_line(Vector2(-1.6, waist + 2.0), Vector2(-4.8 * flare, -3.5), _p.cloth_edge, 1.0)
			pd.draw_line(Vector2(0.2, -2.2), Vector2(0.6, waist + 3.0), _p.inner, 0.9)
			var foot := Vector2(2.4, -0.6)
			pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.6, -1.6), foot + Vector2(2.0, -1.0), foot + Vector2(2.4, 0.6), foot + Vector2(-1.4, 0.6)]), _p.boot)
			_paint_torso_robe(waist)
		"dress":
			# 긴 드레스: 높은 트임, 주름, 안감 (EArt의 치마 구조)
			var fl := 0.6 + 2.0 * _big
			var back := -8.6 - fl * 1.5
			var front := 6.6 + fl * 0.6
			pd.draw_colored_polygon(PackedVector2Array([Vector2(-2.5, waist + 1), Vector2(back + 0.2, -2.0 - fl * 0.6), Vector2(back + 3.4, -0.8), Vector2(-0.6, waist + 4)]), _p.inner)
			var hem := PackedVector2Array([Vector2(-3.4, waist), Vector2(3.4, waist), Vector2(front - 1.6, -7.0)])
			var n := 8
			for i in n + 1:
				var f := float(i) / float(n)
				var x := lerpf(front, back, f)
				var y := -0.6 if i % 2 == 0 else -3.2
				if i == n:
					y = -1.6 - fl * 0.5
				y -= fl * 0.4 * f
				hem.append(Vector2(x, y))
			hem.append(Vector2(back + 1.6, -9.0))
			pd.outlined(hem, _p.cloth, OUT, 0.8)
			pd.draw_line(Vector2(0.5, waist + 1.5), Vector2(front - 2.0, -2.5), _p.cloth_hi, 1.0)
			pd.draw_line(Vector2(-1.4, waist + 2.0), Vector2(-3.6 - fl * 0.6, -2.0), _p.cloth_hi, 1.0)
			var hip := Vector2(2.2, waist + 3.0)
			var foot := Vector2(3.6, -1.0)
			pd.draw_line(hip, foot, _p.skin_sh, 1.6)
			pd.draw_line(hip + Vector2(0.4, 0), foot + Vector2(0.4, -1.2), _p.skin, 0.8)
			pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.4, -1.0), foot + Vector2(1.8, -0.4), foot + Vector2(2.2, 0.8), foot + Vector2(-1.2, 0.8)]), _p.boot)
			for i in 3: # 자락 끝의 빛 점 (속성 색)
				var f := (float(i) + 0.5) / 3.0
				var x := lerpf(front - 1.0, back + 1.4, f)
				pd.draw_rect(Rect2(Vector2(x - 0.5, -2.4 - fl * 0.4 * f), Vector2(1.0, 1.0)), Color(_p.inner_hi, 0.9))
			_paint_torso_robe(waist)


func _paint_torso_coat(waist: float) -> void:
	var torso := PackedVector2Array([Vector2(-3.1, waist), Vector2(3.2, waist), Vector2(4.4, waist - 3.6), Vector2(3.6, waist - 7.2), Vector2(-3.1, waist - 7.2)])
	pd.outlined(torso, _p.cloth, OUT, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0.4, waist - 7.0), Vector2(3.0, waist - 6.6), Vector2(3.4, waist - 1.0), Vector2(0.8, waist)]), _p.inner)
	pd.draw_line(Vector2(1.2, waist - 6.0), Vector2(1.6, waist - 1.0), _p.inner_hi, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-3.4, waist - 7.2), Vector2(3.8, waist - 7.4), Vector2(3.2, waist - 10.4), Vector2(-3.0, waist - 10.0)]), _p.cloth_hi)
	pd.draw_line(Vector2(-2.6, waist - 0.6), Vector2(3.0, waist - 0.6), _p.band, 1.0)
	pd.draw_rect(Rect2(Vector2(-0.2, waist - 10.6), Vector2(2.0, 1.6)), _p.skin_sh)


func _paint_torso_robe(waist: float) -> void:
	var torso := PackedVector2Array([Vector2(-3.1, waist), Vector2(3.2, waist), Vector2(4.4, waist - 3.6), Vector2(3.6, waist - 7.2), Vector2(-3.1, waist - 7.2)])
	pd.outlined(torso, _p.cloth, OUT, 0.8)
	pd.draw_line(Vector2(-2.8, waist - 1.0), Vector2(3.2, waist - 1.0), _p.inner, 2.0)
	pd.draw_line(Vector2(-2.8, waist - 1.4), Vector2(3.2, waist - 1.4), _p.inner_hi, 0.6)
	pd.draw_line(Vector2(3.6, waist - 6.4), Vector2(4.0, waist - 3.6), _p.cloth_hi, 1.0)
	pd.draw_rect(Rect2(Vector2(-3.4, waist - 9.0), Vector2(7.2, 2.0)), _p.skin)
	pd.draw_rect(Rect2(Vector2(-3.4, waist - 9.0), Vector2(7.2, 0.8)), _p.skin_hi)
	pd.draw_rect(Rect2(Vector2(-0.2, waist - 10.6), Vector2(2.2, 1.8)), _p.skin_sh)


## 두건 망토 (네레이): 어깨에서 흘러내리는 망토 + 머리를 감싸는 두건은 _paint_hat에서
func _paint_cape(o: Vector2) -> void:
	var waist := -16.0 + o.y
	var cape := PackedVector2Array([o + Vector2(-4.0, -31.0), o + Vector2(2.0, -32.0), o + Vector2(-1.0, waist - 2.0), o + Vector2(-5.0 - _big * 2.0, waist + 2.0), o + Vector2(-9.0 - _big * 3.0, -4.0), o + Vector2(-7.0, waist - 6.0)])
	pd.outlined(cape, _p.hat, OUT, 0.8)
	pd.draw_line(o + Vector2(-5.0, -26.0), o + Vector2(-8.0, -6.0), _p.hat_hi, 0.8)


# ═══════════════════════════════════════════════════════════
# 머리·얼굴
# ═══════════════════════════════════════════════════════════

func _paint_head(o: Vector2) -> void:
	var hc := o + Vector2(1.3, -29.2)
	pd.draw_circle(hc, 3.85, OUT) # 얼굴 외곽선
	pd.draw_circle(hc, 3.3, _p.skin)
	pd.draw_circle(hc + Vector2(-1.0, 0.9), 2.0, Color(_p.skin_sh, 0.55)) # 뒤쪽 볼 그늘 (명암)
	pd.draw_circle(hc + Vector2(1.2, -1.0), 1.2, Color(_p.skin_hi, 0.7))
	if not (_s.hat in ["band", "hood", "veil"]):
		pd.draw_rect(Rect2(hc + Vector2(-2.6, -3.2), Vector2(5.6, 1.6)), Color(_p.skin_sh, 0.9)) # 챙 그늘
	pd.draw_rect(Rect2(hc + Vector2(1.6, 1.5), Vector2(1.2, 0.8)), _p.skin_sh)
	pd.draw_rect(Rect2(hc + Vector2(2.1, 0.6), Vector2(1.0, 0.5)), Color("#c9736e"))
	# 정수리
	pd.draw_circle(o + Vector2(0.1, -30.7), 3.6, _p.hair_sh)
	pd.draw_circle(o + Vector2(0.6, -31.4), 2.4, _p.hair)
	match String(_s.hair):
		"spiky":
			var fringe := PackedVector2Array([o + Vector2(-1.0, -33.0), o + Vector2(2.0, -34.6), o + Vector2(4.6, -32.4), o + Vector2(5.4, -29.0),
				o + Vector2(3.6, -27.4), o + Vector2(2.8, -29.6), o + Vector2(0.4, -30.4), o + Vector2(-0.6, -31.8)])
			pd.outlined(fringe, _p.hair, OUT, 0.6)
			pd.draw_line(o + Vector2(3.6, -32.0), o + Vector2(4.6, -29.2), _p.hair_hi, 0.9)
			pd.draw_line(o + Vector2(1.4, -33.4), o + Vector2(2.2, -30.6), _p.hair_hi, 0.7)
			for i in 3:
				var a := -2.4 + 0.5 * float(i)
				var base := o + Vector2(-2.0 - 0.6 * float(i), -31.6 + 0.8 * float(i))
				pd.draw_line(base, base + Vector2.from_angle(a) * 3.6, _p.hair, 1.4)
				pd.draw_line(base, base + Vector2.from_angle(a) * 3.0, _p.hair_hi, 0.5)
		"bob":
			# 단발: 머리를 감싸는 둥근 덩어리 + 턱선에서 안으로 말림
			var bobp := PackedVector2Array([o + Vector2(-4.2, -33.0), o + Vector2(2.4, -34.4), o + Vector2(5.0, -31.0), o + Vector2(5.2, -26.0), o + Vector2(3.4, -25.0),
				o + Vector2(3.2, -28.0), o + Vector2(0.4, -30.2), o + Vector2(-2.4, -28.6), o + Vector2(-3.0, -24.6), o + Vector2(-5.0, -25.4), o + Vector2(-5.4, -29.6)])
			pd.outlined(bobp, _p.hair, OUT, 0.6)
			pd.draw_line(o + Vector2(-4.0, -31.0), o + Vector2(-4.2, -26.0), _p.hair_sh, 0.9)
			pd.draw_line(o + Vector2(3.8, -31.0), o + Vector2(4.4, -27.0), _p.hair_hi, 0.9) # 흰 줄기 (하르페) / 빛
			pd.draw_line(o + Vector2(1.0, -33.4), o + Vector2(2.6, -31.0), _p.hair_hi, 0.6)
		_:
			var fringe := PackedVector2Array([o + Vector2(0.4, -33.4), o + Vector2(4.4, -31.8), o + Vector2(4.9, -28.2),
				o + Vector2(3.6, -27.4), o + Vector2(2.6, -29.0), o + Vector2(0.0, -30.6)])
			pd.outlined(fringe, _p.hair, OUT, 0.6)
			pd.draw_line(o + Vector2(3.5, -31.4), o + Vector2(4.0, -28.4), _p.hair_hi, 0.8)
	# 앞 줄
	if _s.front == "braid":
		_braid(_hair2.p, 2.4, 1.6)
		var tipp := _tip_of(_hair2.p)
		pd.draw_line(tipp + Vector2(-1.3, 0.0), tipp + Vector2(1.3, 0.0), _p.band, 1.2)
	elif _s.hair != "bob":
		var lk := _ribbon(_hair2.p, 2.2, 0.8)
		pd.strip(_grow(lk[0], lk[2], 0.5), _grow(lk[1], lk[2], 0.5), OUT)
		pd.strip(lk[0], lk[1], _p.hair)
	# 눈
	var eye := o + Vector2(3.5, -28.9)
	if _blink > 0.0 or _kneel > 0.5:
		pd.draw_line(eye + Vector2(-0.8, 0.2), eye + Vector2(0.8, 0.2), OUT, 0.7) # 감은 눈
	elif kind in ["ignis", "fulgur", "cinder", "tonan"]:
		var ea := 0.7 + 0.3 * sin(_t * 3.0) + glow * 0.3
		pd.glow(eye, 3.0, Color(_p.eye, 0.5 * ea), 0.0)
		pd.draw_rect(Rect2(eye - Vector2(0.7, 0.5), Vector2(1.4, 1.0)), Color(_p.eye, minf(ea, 1.0)))
		pd.draw_rect(Rect2(eye - Vector2(0.2, 0.3), Vector2(0.6, 0.5)), Color(1, 1, 1, minf(ea, 1.0)))
	else:
		pd.draw_rect(Rect2(eye - Vector2(0.7, 0.6), Vector2(1.4, 1.2)), _p.eye)
		pd.draw_rect(Rect2(eye - Vector2(0.4, 0.5), Vector2(0.5, 0.5)), Color(1, 1, 1, 0.95))


# ═══════════════════════════════════════════════════════════
# 모자
# ═══════════════════════════════════════════════════════════

func _brim(center: Vector2, rx: float, ry: float, tilt: float, wavy := false, jag := false) -> void:
	pd.draw_set_transform_matrix(Transform2D(tilt + _tip * 0.05, center))
	var brim := PackedVector2Array()
	var brim_top := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		var r := rx
		if jag:
			r += 0.6 * sin(a * 7.0) * (0.5 + 0.5 * cos(a))
		if wavy:
			r += 1.1 * sin(a * 5.0 + _t * 2.0)
		brim.append(Vector2(cos(a) * r, sin(a) * ry))
		brim_top.append(Vector2(cos(a) * (rx - 1.2), sin(a) * (ry - 1.0) - 0.5))
	pd.outlined(brim, _p.hat, OUT, 0.8)
	pd.convex(brim_top, _p.hat_hi)
	pd.draw_line(Vector2(-rx * 0.85, -0.9), Vector2(rx * 0.75, -1.2), _p.cloth_hi if _s.outfit in ["robe", "dress"] and kind != "cinder" else Color(_p.hat_hi).lightened(0.2), 0.7)


func _paint_hat(o: Vector2) -> void:
	var brim_c := o + Vector2(0.4, -33.5)
	var fl := _flicker
	match String(_s.hat):
		"point_fwd":
			_brim(brim_c, 13.8, 2.4, -0.12, false, _s.get("brim", "") == "burnt")
			if _s.get("brim", "") == "burnt":
				for spec: Array in [[13.2, 0.0], [11.0, 1.4], [-12.6, 0.4]]:
					var bx: float = spec[0]
					var by: float = spec[1]
					var k := fl * (0.8 + 0.2 * sin(_t * 11.0 + bx))
					pd.glow(Vector2(bx, by - 0.5), 3.2, Color(_p.glow, 0.35 * k), 0.0)
					pd.draw_line(Vector2(bx - 1.6, by + 0.6), Vector2(bx + 1.6, by + 0.2), Color(_p.brim_edge, 0.9 * k), 0.9)
					pd.draw_rect(Rect2(Vector2(bx - 0.4, by - 1.4 - 0.8 * k), Vector2(0.8, 0.8)), Color(_p.glow_pale, k))
			elif _s.get("brim", "") == "fur":
				for i in 12: # 챙 둘레의 흰 털
					var a := float(i) / 12.0 * TAU
					var p := Vector2(cos(a) * 13.4, sin(a) * 2.2)
					pd.draw_circle(p, 1.3, _p.brim_edge)
			pd.draw_set_transform(Vector2.ZERO)
			var tip := Vector2(5.2 + _tip * 2.0, -46.5 + absf(_tip) * 0.5)
			var crown := PackedVector2Array([o + Vector2(-5.2, -34.3), o + Vector2(5.4, -34.5), o + Vector2(5.0, -38.6),
				o + Vector2(2.4, -42.6), o + tip, o + tip + Vector2(-2.0, 1.4), o + Vector2(-1.2, -41.4), o + Vector2(-4.8, -38.0)])
			pd.outlined(crown, _p.hat, OUT, 0.8)
			pd.draw_colored_polygon(PackedVector2Array([o + Vector2(1.6, -34.5), o + Vector2(5.4, -34.5), o + Vector2(4.6, -38.6), o + Vector2(1.6, -40.0)]), _p.hat_hi)
			pd.draw_line(o + Vector2(-4.8, -35.4), o + Vector2(5.0, -35.6), _p.band, 1.6)
			pd.draw_rect(Rect2(o + Vector2(2.2, -36.6), Vector2(1.6, 1.6)), _p.metal)
			if kind == "ignis": # 모자 끝이 불꽃 혀 두 갈래로 갈라짐
				for i in 2:
					var base := o + tip + Vector2(-1.0 * float(i), 0.6 * float(i))
					var h := (3.6 + 0.8 * sin(_t * 12.0 + float(i) * 2.0)) * (1.0 - 0.3 * float(i))
					var d := Vector2(0.55 - 0.5 * float(i), -1.0).normalized()
					pd.glow(base, 3.4, Color(_p.glow, 0.35 * fl), 0.0)
					pd.draw_colored_polygon(PackedVector2Array([base + d.orthogonal() * 1.1, base + d * h, base - d.orthogonal() * 1.1]), Color(_p.glow, 0.95))
					pd.draw_colored_polygon(PackedVector2Array([base + d.orthogonal() * 0.5, base + d * h * 0.6, base - d.orthogonal() * 0.5]), Color(_p.glow_pale, 0.95))
			elif kind == "glacia": # 모자에 얼음 결정 장식 셋
				for spec: Array in [[Vector2(-2.6, -37.6), 1.8], [Vector2(0.6, -39.8), 1.4], [Vector2(3.6, -37.0), 1.6]]:
					var c: Vector2 = o + (spec[0] as Vector2)
					var r: float = spec[1]
					for q in 3:
						var d := Vector2.from_angle(PI * float(q) / 3.0 + 0.3) * r
						pd.draw_line(c - d, c + d, OUT, 1.2)
					for q in 3:
						var d := Vector2.from_angle(PI * float(q) / 3.0 + 0.3) * r
						pd.draw_line(c - d, c + d, _p.brim_edge, 0.6)
					pd.draw_circle(c, 0.5, Color(_p.inner, 0.9))
		"soft_back":
			_brim(brim_c, 10.6, 2.2, -0.05)
			pd.draw_set_transform(Vector2.ZERO)
			var tip := Vector2(-9.0 - _tip * 2.0, -40.0 + absf(_tip) * 0.6)
			var crown := PackedVector2Array([o + Vector2(-4.6, -34.3), o + Vector2(4.8, -34.5), o + Vector2(4.4, -38.8), o + Vector2(1.8, -41.8),
				o + Vector2(-2.6, -42.4), o + tip, o + tip + Vector2(0.4, 1.8), o + Vector2(-4.0, -39.6)])
			pd.outlined(crown, _p.hat, OUT, 0.8)
			pd.draw_colored_polygon(PackedVector2Array([o + Vector2(1.2, -34.5), o + Vector2(4.8, -34.5), o + Vector2(4.2, -38.6), o + Vector2(1.4, -40.2)]), _p.hat_hi)
			pd.draw_line(o + Vector2(-4.4, -35.4), o + Vector2(4.6, -35.6), _p.band, 1.6)
			var ch := o + tip + Vector2(-0.6, 1.4)
			match String(_s.get("charm", "bell")):
				"bell":
					pd.draw_circle(ch, 1.3, OUT)
					pd.draw_circle(ch, 0.8, _p.metal)
				"star":
					EVfx.star4(pd, ch, 2.6 + 0.4 * sin(_t * 5.0), 0.3, _p.metal, Color(_p.glow, 0.0))
				"clock":
					pd.draw_circle(ch, 2.2, OUT)
					pd.draw_circle(ch, 1.6, _p.metal)
					pd.draw_line(ch, ch + Vector2.from_angle(_t * 1.2) * 1.2, OUT, 0.5)
					pd.draw_line(ch, ch + Vector2.from_angle(_t * 0.2 - 1.0) * 0.8, OUT, 0.6)
		"wide":
			_brim(brim_c + Vector2(0, 0.6), 16.0, 2.8, -0.04)
			pd.draw_set_transform(Vector2.ZERO)
			var top_y := -49.0 if kind == "tonan" else -41.2 # 토난: 아주 높은 모자
			var crown := PackedVector2Array([o + Vector2(-5.6, -34.3), o + Vector2(5.6, -34.5), o + Vector2(4.4, top_y + 1.6), o + Vector2(0.4 - _tip, top_y), o + Vector2(-4.6, top_y + 2.2)])
			pd.outlined(crown, _p.hat, OUT, 0.8)
			pd.draw_colored_polygon(PackedVector2Array([o + Vector2(1.2, -34.5), o + Vector2(5.6, -34.5), o + Vector2(4.4, -39.6), o + Vector2(1.6, -40.4)]), _p.hat_hi)
			pd.draw_line(o + Vector2(-5.2, -35.6), o + Vector2(5.2, -35.8), _p.band, 1.6)
			if kind == "cinder": # 챙 가장자리에서 흘러내리는 재 베일
				for i in 5:
					var x := -14.0 + 3.0 * float(i)
					pd.draw_line(o + Vector2(x, -32.8), o + Vector2(x - 0.6 + sin(_t * 2.0 + float(i)) * 0.6, -29.0 + float(i % 2)), Color(_p.hat_hi, 0.7), 0.7)
			else: # 토난: 챙 끝 구름 장식 + 노란 번개 술 + 모자 금 줄
				pd.draw_line(o + Vector2(-5.0, -38.0), o + Vector2(4.8, -38.4), _p.brim_edge, 0.7)
				for cc: Array in [[Vector2(-15.4, -33.6), 1.9], [Vector2(-13.2, -34.6), 2.3], [Vector2(-11.0, -33.6), 1.7]]:
					pd.draw_circle(o + (cc[0] as Vector2), float(cc[1]) + 0.6, OUT)
				for cc: Array in [[Vector2(-15.4, -33.6), 1.9], [Vector2(-13.2, -34.6), 2.3], [Vector2(-11.0, -33.6), 1.7]]:
					pd.draw_circle(o + (cc[0] as Vector2), float(cc[1]), Color("#b9c0e8"))
				pd.draw_line(o + Vector2(-14.0, -32.0), o + Vector2(-15.0, -29.5), _p.brim_edge, 0.8)
				pd.draw_line(o + Vector2(-15.0, -29.5), o + Vector2(-13.8, -27.5), _p.brim_edge, 0.8)
		"wave":
			_brim(brim_c + Vector2(0, 0.4), 14.5, 2.6, -0.06, true)
			pd.draw_set_transform(Vector2.ZERO)
			# 소라처럼 말린 꼭대기
			var crown := PackedVector2Array([o + Vector2(-5.2, -34.3), o + Vector2(5.2, -34.5), o + Vector2(4.8, -38.4), o + Vector2(1.6, -42.0), o + Vector2(-3.4 - _tip, -43.6), o + Vector2(-6.2, -40.4), o + Vector2(-4.8, -37.6)])
			pd.outlined(crown, _p.hat, OUT, 0.8)
			pd.draw_arc(o + Vector2(-2.6, -39.6), 2.6, 0.0, TAU * 0.8, 12, _p.hat_hi, 0.9)
			pd.draw_line(o + Vector2(-4.8, -35.4), o + Vector2(4.8, -35.6), _p.band, 1.4)
			for i in 3: # 챙 위 물방울
				var p := brim_c + Vector2(-8.0 + 7.0 * float(i), -1.6 - 0.6 * sin(_t * 4.0 + float(i)))
				pd.draw_circle(p, 0.9, Color(_p.inner_hi, 0.9))
		"hood":
			# 두건: 머리를 감싸는 둥근 덮개 + 이마 위 밝은 테
			var hood := PackedVector2Array([o + Vector2(-5.6, -26.0), o + Vector2(-6.0, -33.0), o + Vector2(-2.6, -37.4), o + Vector2(3.0, -37.0), o + Vector2(5.8, -33.6), o + Vector2(5.2, -30.6),
				o + Vector2(3.2, -32.6), o + Vector2(-0.4, -33.0), o + Vector2(-3.0, -30.6), o + Vector2(-3.2, -26.4)])
			pd.outlined(hood, _p.hat, OUT, 0.8)
			pd.draw_line(o + Vector2(-2.2, -36.2), o + Vector2(3.4, -35.4), _p.hat_hi, 1.0)
			pd.draw_line(o + Vector2(5.0, -33.0), o + Vector2(3.6, -32.4), _p.brim_edge, 1.0)
			pd.draw_circle(o + Vector2(4.6, -34.2), 1.0, _p.metal) # 조개 장식
		"crown_tall":
			_brim(brim_c, 9.6, 2.0, -0.08)
			pd.draw_set_transform(Vector2.ZERO)
			var crown := PackedVector2Array([o + Vector2(-3.8, -34.3), o + Vector2(4.0, -34.5), o + Vector2(3.2, -44.0), o + Vector2(1.2 + _tip * 1.5, -50.0), o + Vector2(-1.6, -44.4), o + Vector2(-3.4, -40.0)])
			pd.outlined(crown, _p.hat, OUT, 0.8)
			pd.draw_colored_polygon(PackedVector2Array([o + Vector2(0.8, -34.5), o + Vector2(4.0, -34.5), o + Vector2(3.2, -44.0), o + Vector2(1.0, -45.0)]), _p.hat_hi)
			pd.draw_line(o + Vector2(-3.6, -35.6), o + Vector2(3.8, -35.8), _p.band, 1.4)
			# 번개 문장
			var z := o + Vector2(0.6, -40.0)
			pd.draw_line(z + Vector2(0.6, -2.2), z + Vector2(-0.8, 0.0), _p.brim_edge, 1.0)
			pd.draw_line(z + Vector2(-0.8, 0.0), z + Vector2(0.6, 0.0), _p.brim_edge, 1.0)
			pd.draw_line(z + Vector2(0.6, 0.0), z + Vector2(-0.6, 2.2), _p.brim_edge, 1.0)
		"veil":
			# 신더: 모자 대신 얇은 검은 베일 — 정수리 작은 관 + 어깨까지 흘러내리는 반투명 천 + 재 장식
			var sway := sin(_t * 1.6) * 0.6
			var veil := PackedVector2Array([o + Vector2(-4.6, -34.2), o + Vector2(2.2, -35.4), o + Vector2(5.4, -33.0), o + Vector2(6.0, -29.6),
				o + Vector2(3.8, -31.6), o + Vector2(0.0, -32.4), o + Vector2(-4.4, -30.0), o + Vector2(-7.6 + sway, -22.0), o + Vector2(-9.6 + sway, -19.0), o + Vector2(-6.4, -27.0)])
			pd.draw_colored_polygon(veil, Color(_p.hat, 0.82))
			var edge := PackedVector2Array(veil)
			edge.append(veil[0])
			pd.draw_polyline(edge, OUT, 0.7)
			pd.draw_line(o + Vector2(-5.0, -31.0), o + Vector2(-8.6 + sway, -20.6), Color(_p.hat_hi, 0.8), 0.6)
			pd.draw_line(o + Vector2(-3.8, -34.6), o + Vector2(2.6, -35.8), _p.inner_hi, 0.8) # 관
			for i in 3: # 관 위 불씨 점
				pd.draw_rect(Rect2(o + Vector2(-2.6 + 2.2 * float(i), -36.8 - 0.6 * float(i % 2)), Vector2(0.8, 0.8)), Color(_p.glow, 0.7 + 0.3 * sin(_t * 6.0 + float(i))))
		"band":
			# 모자 없음: 리본 머리띠 + 뒤로 날리는 리본 두 가닥
			pd.draw_line(o + Vector2(-4.6, -32.4), o + Vector2(4.8, -33.2), _p.band, 1.6)
			pd.draw_line(o + Vector2(-4.0, -32.9), o + Vector2(4.2, -33.6), Color(_p.brim_edge, 0.8), 0.5)
			var k := o + Vector2(-4.6, -32.4)
			for i in 2:
				var sway := sin(_t * 3.0 + float(i) * 1.5) * 1.5
				var e := k + Vector2(-7.0 - 2.0 * float(i) - _big * 3.0, 2.0 + 4.0 * float(i) + sway - _big * 6.0)
				var m := k.lerp(e, 0.5) + Vector2(0, -1.5 + sway * 0.5)
				pd.draw_line(k, m, _p.band, 1.4)
				pd.draw_line(m, e, _p.band, 1.1)
			pd.draw_circle(k, 1.4, _p.band)
	pd.draw_set_transform(Vector2.ZERO)


# ═══════════════════════════════════════════════════════════
# 앞팔 + 소품
# ═══════════════════════════════════════════════════════════

func _paint_front_arm(o: Vector2) -> void:
	var bob := o.y
	var sh := o + Vector2(1.5, -23.5)
	var hand := _hand + Vector2(0, bob)
	var mid := sh.lerp(hand, 0.5)
	var bend := (hand - sh).orthogonal().normalized() * 1.4
	var el := mid + (bend if bend.y > 0.0 else -bend)
	if _s.outfit == "robe":
		var sl := _ribbon(_sleeve.p, 4.6, 7.0)
		pd.strip(_grow(sl[0], sl[2], 0.6), _grow(sl[1], sl[2], 0.6), OUT)
		pd.strip(sl[0], sl[1], _p.cloth)
		var sll: PackedVector2Array = sl[0]
		pd.draw_polyline(sll, _p.cloth_hi, 0.6)
		var tipp := _tip_of(_sleeve.p)
		pd.draw_line(tipp + Vector2(-3.0, 0), tipp + Vector2(3.0, 0), _p.band, 1.0)
		pd.draw_line(sh, el, _p.skin, 1.7)
		pd.draw_line(el, hand, _p.skin, 1.5)
		pd.draw_circle(hand, 1.15, _p.skin)
	elif _s.outfit == "dress":
		var sl := _ribbon(_sleeve.p, 4.0, 6.0)
		pd.strip(sl[0], sl[1], Color(_p.cloth_edge, 0.5)) # 시스루 소매
		pd.draw_line(sh, el, _p.skin, 1.7)
		pd.draw_line(el, hand, _p.skin, 1.5)
		pd.draw_circle(hand, 1.15, _p.skin)
	else:
		pd.draw_line(sh, el, _p.cloth, 2.4)
		pd.draw_line(sh + Vector2(0, -0.5), el + Vector2(0, -0.5), _p.cloth_hi, 0.6)
		if _s.prop == "glove":
			pd.draw_line(el, hand, _p.band, 2.2)
			pd.draw_circle(hand, 1.3, _p.band)
			pd.draw_circle(hand + Vector2(0.4, -0.3), 0.5, _p.inner_hi)
		else:
			pd.draw_line(el, hand, _p.skin, 1.5)
			pd.draw_circle(hand, 1.15, _p.skin)
	match String(_s.prop):
		"glove": _paint_glove_fire(hand)
		"lantern": _paint_lantern(hand)
		"censer": _paint_censer(hand)
		"staff_orb": _paint_staff(hand, true)
		"staff_rod": _paint_staff(hand, false)
		"orb": _paint_orb(hand)
		"fan": _paint_fan(hand)
		"watch": _paint_watch(hand)
		"sword": _paint_sword(hand)


func _paint_glove_fire(hand: Vector2) -> void:
	var k := 0.25 + 0.75 * glow
	var fl := _flicker
	pd.glow(hand, (4.0 + 9.0 * glow) * fl, Color(_p.glow, 0.45 * k), 0.0)
	if kind == "fulgur": # 번개 장갑: 지직거리는 짧은 번개
		var seed := int(_t * 24.0)
		for i in 3:
			var an := EVfx.hash01(seed * 7 + i * 13) * TAU
			var len := (3.0 + 9.0 * glow) * (0.6 + 0.4 * EVfx.hash01(seed + i))
			var d := Vector2.from_angle(an)
			var m := hand + d * len * 0.5 + d.orthogonal() * (EVfx.hash01(seed * 3 + i) - 0.5) * 3.0
			pd.draw_line(hand, m, Color(_p.glow_pale, 0.9 * k), 0.8)
			pd.draw_line(m, hand + d * len, Color(_p.glow, 0.8 * k), 0.8)
	else:
		for i in 3:
			var ph := _t * 9.0 + float(i) * 2.1
			var h := (2.0 + 5.0 * glow) * (0.7 + 0.3 * sin(ph))
			var base := hand + Vector2(-1.0 + float(i), 0.0)
			var tip := base + Vector2(sin(ph * 0.7) * 1.2, -h)
			pd.line2(base, tip, Color(_p.glow, 0.9 * k), Color(_p.glow_pale, 0.0), 1.8 + glow, 0.4)
	pd.draw_circle(hand, 1.0 + 1.2 * glow, Color(_p.glow_pale, 0.6 + 0.4 * glow))


func _paint_lantern(hand: Vector2) -> void:
	var top := hand + Vector2(1.5, 1.6)
	var c := hand + Vector2(1.5, 4.6)
	var k := 0.7 + 0.3 * glow # 등불 빛을 밝게 (review_D C1)
	var fl := _flicker
	pd.glow(c, (9.0 + 10.0 * glow) * fl, Color(_p.glow, 0.5 * k), 0.0)
	pd.draw_line(hand, top, _p.metal, 0.8)
	pd.outlined(PackedVector2Array([c + Vector2(-2.2, -2.6), c + Vector2(2.2, -2.6), c + Vector2(2.6, 2.4), c + Vector2(-2.6, 2.4)]), Color(_p.glow_pale, 0.55 + 0.3 * glow), OUT, 0.7)
	pd.draw_rect(Rect2(c + Vector2(-2.8, -3.4), Vector2(5.6, 1.0)), _p.metal)
	pd.draw_rect(Rect2(c + Vector2(-2.9, 2.2), Vector2(5.8, 0.9)), _p.metal)
	pd.draw_line(c + Vector2(-0.3, -2.4), c + Vector2(-0.3, 2.2), Color(_p.metal, 0.6), 0.5)
	var h := (2.0 + 2.4 * glow) * (0.8 + 0.2 * sin(_t * 13.0))
	pd.line2(c + Vector2(0, 1.8), c + Vector2(sin(_t * 8.0) * 0.5, 1.8 - h), Color(_p.glow, 0.95), Color(_p.glow_pale, 0.1), 1.8, 0.5)
	pd.draw_circle(c + Vector2(0, 1.2), 0.7, Color(1, 1, 1, 0.9 * k))


## 향로 (신더): 사슬에 매달린 그릇에서 재와 불씨가 피어오른다
func _paint_censer(hand: Vector2) -> void:
	var c := hand + Vector2(1.5, 5.2)
	var k := 0.4 + 0.6 * glow
	pd.draw_line(hand, c + Vector2(0, -2.6), _p.metal, 0.7)
	pd.draw_line(hand + Vector2(0.6, 0), c + Vector2(1.4, -2.4), Color(_p.metal, 0.7), 0.5)
	pd.outlined(PackedVector2Array([c + Vector2(-3.0, -2.2), c + Vector2(3.0, -2.2), c + Vector2(2.2, 1.6), c + Vector2(-2.2, 1.6)]), _p.metal, OUT, 0.7)
	pd.draw_line(c + Vector2(-2.6, -1.6), c + Vector2(2.6, -1.6), Color(1, 1, 1, 0.35), 0.5)
	pd.glow(c + Vector2(0, -2.6), 4.0 + 6.0 * glow, Color(_p.glow, 0.35 * k), 0.0)
	for i in 3: # 피어오르는 연기 + 불씨
		var ph := fmod(_t * 0.6 + float(i) / 3.0, 1.0)
		var p := c + Vector2(sin(_t * 2.0 + float(i) * 2.0) * 2.0 * ph, -2.6 - ph * (8.0 + 6.0 * glow))
		pd.glow(p, 2.0 + 2.0 * ph, Color(_p.hair, 0.35 * (1.0 - ph)), 0.0)
		pd.draw_rect(Rect2(p, Vector2(0.8, 0.8)), Color(_p.glow_pale, (1.0 - ph) * k))


## 지팡이: 손에 쥔 긴 자루, 끝에 구슬(물) 또는 피뢰침(번개)
func _paint_staff(hand: Vector2, orb: bool) -> void:
	var top := hand + Vector2(1.0, -14.0 - 3.0 * glow)
	var bot := hand + Vector2(-0.6, 9.0)
	pd.draw_line(bot, top, OUT, 2.4)
	pd.draw_line(bot, top, Color(_p.boot).lightened(0.25), 1.2)
	pd.draw_line(bot + Vector2(0.3, 0), top + Vector2(0.3, 0), Color(_p.metal, 0.5), 0.4)
	var k := 0.35 + 0.65 * glow
	if orb:
		pd.glow(top, 5.0 + 8.0 * glow, Color(_p.glow, 0.45 * k), 0.0)
		pd.draw_circle(top, 2.6, OUT)
		pd.draw_circle(top, 2.0, _p.glow)
		pd.draw_circle(top + Vector2(-0.6, -0.6), 0.8, _p.glow_pale)
		for i in 2: # 구슬 둘레를 도는 물방울
			var an := _t * 4.0 + float(i) * PI
			pd.draw_circle(top + Vector2(cos(an) * 4.0, sin(an) * 2.0), 0.7, Color(_p.inner_hi, 0.9))
	else:
		pd.draw_line(top + Vector2(-2.0, 1.6), top + Vector2(0, -3.0), _p.metal, 1.2)
		pd.draw_line(top + Vector2(2.0, 1.6), top + Vector2(0, -3.0), _p.metal, 1.2)
		pd.glow(top + Vector2(0, -2.0), 4.0 + 8.0 * glow, Color(_p.glow, 0.4 * k), 0.0)
		var seed := int(_t * 20.0)
		for i in 2:
			var an := EVfx.hash01(seed * 5 + i * 11) * TAU
			var d := Vector2.from_angle(an)
			var len := 2.5 + 7.0 * glow
			pd.draw_line(top + Vector2(0, -2.0), top + Vector2(0, -2.0) + d * len, Color(_p.glow_pale, 0.9 * k), 0.8)


## 떠 있는 구슬 (네레이: 진주 / 아스트라: 별)
func _paint_orb(hand: Vector2) -> void:
	var c := hand + Vector2(2.0, -7.0 + sin(_t * 2.5) * 1.2)
	var k := 0.4 + 0.6 * glow
	pd.glow(c, 5.0 + 8.0 * glow, Color(_p.glow, 0.4 * k), 0.0)
	if kind == "astra":
		EVfx.star4(pd, c, 4.0 + 1.5 * glow, _t * 1.5, _p.glow_pale, Color(_p.glow, 0.0))
		EVfx.star4(pd, c, 2.4, _t * 1.5 + 0.785, _p.metal, Color(_p.glow, 0.0))
	else:
		pd.draw_circle(c, 2.8, OUT)
		pd.draw_circle(c, 2.2, _p.glow)
		pd.draw_circle(c + Vector2(-0.7, -0.7), 0.9, _p.glow_pale)
	for i in 3: # 손에서 구슬로 오르는 빛
		var ph := fmod(_t * 0.9 + float(i) / 3.0, 1.0)
		pd.draw_rect(Rect2(hand.lerp(c, ph) + Vector2(sin(ph * 9.0) * 1.5, 0), Vector2(0.8, 0.8)), Color(_p.glow_pale, (1.0 - ph) * k))


## 부채 (글라시아): 접힌 채 들고, 시전하면 활짝 펴진다
func _paint_fan(hand: Vector2) -> void:
	var open := glow
	var n := 7
	var a0 := -1.5
	var a1 := a0 + lerpf(0.25, 1.9, open)
	for i in n:
		var a := lerpf(a0, a1, float(i) / float(n - 1))
		var d := Vector2.from_angle(a)
		pd.draw_line(hand, hand + d * 9.0, OUT, 1.6)
		pd.draw_line(hand, hand + d * 9.0, _p.inner if i % 2 == 0 else _p.inner_hi, 0.9)
	if open > 0.3:
		var pts := PackedVector2Array([hand])
		for i in 9:
			var a := lerpf(a0, a1, float(i) / 8.0)
			pts.append(hand + Vector2.from_angle(a) * 9.5)
		pd.draw_colored_polygon(pts, Color(_p.inner_hi, 0.55 * open))
		pd.glow(hand + Vector2.from_angle((a0 + a1) * 0.5) * 6.0, 8.0, Color(_p.glow, 0.3 * open), 0.0)
	pd.draw_circle(hand, 1.0, _p.metal)


## 회중시계 (호라): 사슬에 매달려 흔들리고, 시전 중 금빛 고리가 돈다
func _paint_watch(hand: Vector2) -> void:
	var sway := sin(_t * 2.2) * 1.5
	var c := hand + Vector2(1.5 + sway, 5.0)
	var k := 0.35 + 0.65 * glow
	pd.draw_line(hand, c + Vector2(0, -2.4), _p.metal, 0.7)
	pd.glow(c, 4.0 + 9.0 * glow, Color(_p.glow, 0.4 * k), 0.0)
	pd.draw_circle(c, 2.9, OUT)
	pd.draw_circle(c, 2.3, _p.metal)
	pd.draw_circle(c, 1.7, _p.glow_pale)
	pd.draw_line(c, c + Vector2.from_angle(_t * 2.0 * (1.0 + 3.0 * glow)) * 1.3, OUT, 0.5)
	pd.draw_line(c, c + Vector2.from_angle(_t * 0.3 - 1.5) * 0.9, OUT, 0.6)
	if glow > 0.0:
		for i in 12:
			var an := _t * 3.0 + float(i) * TAU / 12.0
			pd.draw_rect(Rect2(c + Vector2(cos(an), sin(an)) * (5.0 + 3.0 * glow) - Vector2(0.4, 0.4), Vector2(0.8, 0.8)), Color(_p.glow, glow * (0.4 + 0.6 * float(i % 3 == 0))))


## 흑백 검 (하르페): 먹 테두리의 가는 흰 날. 서 있을 땐 낮게 뒤로, 시전하면 앞으로 치켜든다
func _paint_sword(hand: Vector2) -> void:
	var a := lerpf(2.5, -0.6, glow)
	var d := Vector2.from_angle(a)
	var side := d.orthogonal()
	var pommel := hand - d * 3.5
	var guard := hand + d * 1.6
	var tip := guard + d * 24.0
	pd.draw_line(pommel, guard, OUT, 2.6)
	pd.draw_line(pommel, guard, _p.inner_hi, 1.4)
	pd.line2(guard, tip + d * 0.6, OUT, OUT, 3.2, 1.0)
	pd.line2(guard, tip, Color("#e9e4f2"), Color(1, 1, 1), 1.8, 0.4)
	pd.line2(guard + side * 0.5, tip, Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), 0.6, 0.2)
	pd.line2(guard, guard.lerp(tip, 0.6), Color(_p.glow, 0.85), Color(_p.glow, 0.0), 0.6, 0.3)
	pd.draw_line(guard + side * 3.0, guard - side * 3.0, OUT, 2.4)
	pd.draw_line(guard + side * 2.4, guard - side * 2.4, _p.inner_hi, 1.0)
	pd.draw_circle(guard, 1.0, _p.glow_pale)
	if glow > 0.0:
		pd.line2(guard, guard.lerp(tip, glow), Color(_p.glow_pale, 0.9), Color(1, 1, 1, 1), 2.2, 1.0)
		pd.glow(tip, 6.0 + 4.0 * glow, Color(_p.glow, 0.45 * glow), 0.0)
	pd.draw_circle(hand, 1.15, _p.skin)


func _paint_big_ring(o: Vector2) -> void:
	var k := _big
	var c := o + Vector2(-1.0, -22.0)
	var r := 17.0 * (0.6 + 0.4 * k)
	pd.glow(c, r + 8.0, Color(_p.glow, 0.22 * k), 0.0)
	var spin := _t * 2.6
	for i in 7:
		var a0 := spin + TAU * float(i) / 7.0
		pd.draw_arc(c, r, a0, a0 + TAU / 7.0 * 0.7, 6, Color(_p.glow_pale, 0.75 * k), 1.0)
		var tip := c + Vector2(cos(a0), sin(a0)) * (r + 2.5)
		pd.draw_line(c + Vector2(cos(a0), sin(a0)) * (r - 1.5), tip, Color(_p.glow, 0.8 * k), 1.0)
	pd.draw_arc(c, r * 0.68, -spin * 1.4, -spin * 1.4 + TAU * 0.8, 18, Color(_p.glow, 0.45 * k), 0.8)
