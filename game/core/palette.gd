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


# ─── 파티클 색 변화(Gradient) ───────────────────────────
# Fx.burst 등이 부를 때마다 Gradient.new()를 하지 않도록 같은 색이면 같은 자원을 돌려준다.
# 돌려받은 Gradient를 고치면 같은 색을 쓰는 모든 곳이 바뀐다 — 고칠 일이 있으면 duplicate()해서 쓸 것.

const _GRAD_CACHE_MAX := 512 ## 색이 계속 변하는 호출(보간 색 등)로 캐시가 끝없이 커지지 않게 이만큼 넘으면 비운다
static var _grad_cache := {}
static var _fade_cache := {}
static var _grad2_cache := {} ## c0 → {c1 → Gradient}
static var _fire_grad: Gradient
static var _soul_grad: Gradient


## offsets·colors가 같으면 같은 Gradient를 돌려준다 (장별 도우미 KE.grad, H.gold_grad 등도 이것을 쓴다)
static func cached_gradient(offsets: PackedFloat32Array, colors: PackedColorArray) -> Gradient:
	var key := [offsets, colors]
	var g: Gradient = _grad_cache.get(key)
	if g:
		return g
	if _grad_cache.size() >= _GRAD_CACHE_MAX:
		_grad_cache.clear()
	g = Gradient.new()
	g.offsets = offsets
	g.colors = colors
	_grad_cache[key] = g
	return g


## 불꽃 파티클용 색 변화: 흰 심지 → 노랑 → 주황 → 붉은색 → 투명
static func fire_gradient() -> Gradient:
	if _fire_grad == null:
		_fire_grad = Gradient.new()
		_fire_grad.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
		_fire_grad.colors = PackedColorArray([FIRE_CORE, FIRE_HOT, FIRE_OUT, FIRE_DARK, Color(FIRE_DARK, 0.0)])
	return _fire_grad


static func soul_gradient() -> Gradient:
	if _soul_grad == null:
		_soul_grad = Gradient.new()
		_soul_grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
		_soul_grad.colors = PackedColorArray([Color.WHITE, ENEMY_SOUL, Color(ENEMY_BODY_LIGHT, 0.0)])
	return _soul_grad


## 두 색 사이 (c0 → c1). 장별 도우미 KE.grad가 쓴다
static func grad2(c0: Color, c1: Color) -> Gradient:
	var inner: Dictionary = _grad2_cache.get(c0, {})
	var g: Gradient = inner.get(c1)
	if g == null:
		if _grad2_cache.size() >= _GRAD_CACHE_MAX:
			_grad2_cache.clear()
		g = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([c0, c1])
		inner[c1] = g
		_grad2_cache[c0] = inner
	return g


## 색 c에서 같은 색 투명으로 (가장 많이 불려서 색 하나를 키로 바로 찾는다)
static func fade_gradient(c: Color) -> Gradient:
	var g: Gradient = _fade_cache.get(c)
	if g == null:
		if _fade_cache.size() >= _GRAD_CACHE_MAX:
			_fade_cache.clear()
		g = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([c, Color(c, 0.0)])
		_fade_cache[c] = g
	return g
