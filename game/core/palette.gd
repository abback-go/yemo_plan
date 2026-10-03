class_name Palette
## 코드 그래픽에 쓰는 색 모음 (docs/prototype.md 13.1절).
## 세라와 불은 붉은·주황 계열, 적은 차가운 청록 계열, 위험 예고는 붉은색으로 통일.

# 배경
const SKY_TOP := Color("#0b0914")
const SKY_BOTTOM := Color("#241a35")
const MOON := Color("#f3e6d0")
const FAR := Color("#1f1a30")
const MID := Color("#171326")
const NEAR := Color("#0e0b16")

# 지형
const GROUND := Color("#3a3350")
const GROUND_DARK := Color("#2a2440")
const GROUND_TOP := Color("#5b5078")
const PLATFORM := Color("#4a3b52")
const PLATFORM_TOP := Color("#7a6283")
const DOOR := Color("#6b2a3a")
const DOOR_GLOW := Color("#ff5a4a")

# 세라
const HAT := Color("#231a33")
const HAT_EDGE := Color("#5e4a85")
const HAT_BAND := Color("#c8323c")
const HAIR := Color("#1d1a2e")
const HAIR_TIP := Color("#b4282d")
const HAIR_GLOW := Color("#ff7a3a")
const SKIN := Color("#f2d3c0")
const EYE := Color("#2a1020")
const ROBE := Color("#2b2140")
const ROBE_LIGHT := Color("#3d3058")
const ROBE_ACCENT := Color("#8e2b3a")
const CAPE := Color("#1a1428")
const CAPE_INNER := Color("#5a1d2a")
const BOOT := Color("#151020")

# 불
const FIRE_CORE := Color("#fff4d6")
const FIRE_HOT := Color("#ffd27a")
const FIRE_MID := Color("#ffb347")
const FIRE_OUT := Color("#ff5a2a")
const FIRE_DARK := Color("#b3241d")

# 적
const ENEMY_BODY := Color("#3e6a73")
const ENEMY_BODY_LIGHT := Color("#5f9aa2")
const ENEMY_DARK := Color("#22383f")
const ENEMY_EYE := Color("#7ff0ff")
const ENEMY_SOUL := Color("#9ff6ff")
const DANGER := Color("#ff3b3b")
const OUTLINE := Color("#07060c")
const SHOT := Color("#ff6b8a")

# UI
const UI_TEXT := Color("#efe6ff")
const UI_DIM := Color("#8a7fa3")
const UI_PANEL := Color("#120e1c")
const HP := Color("#ff5a4a")
const HP_EMPTY := Color("#3a2a3a")
const GOLD := Color("#ffd27a")


## 불꽃 파티클용 색 변화: 흰 심지 → 노랑 → 주황 → 붉은색 → 투명
static func fire_gradient() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	g.colors = PackedColorArray([FIRE_CORE, FIRE_HOT, FIRE_OUT, FIRE_DARK, Color(FIRE_DARK, 0.0)])
	return g


static func soul_gradient() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color.WHITE, ENEMY_SOUL, Color(ENEMY_BODY_LIGHT, 0.0)])
	return g


static func fade_gradient(c: Color) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([c, Color(c, 0.0)])
	return g
