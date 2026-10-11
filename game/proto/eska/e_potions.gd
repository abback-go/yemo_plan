class_name EPotions
extends RefCounted
## 에스카 물약: 재료·조합표·물약 자료 + 허리띠(3칸) + 마시기·던지기. 기준서: docs/eska/design.md 4장, 수치: docs/eska/potions.md
## 에스카(EEska)는 belt를 하나 들고, F(+↑/↓)를 누르면 EPotions.use(eska, 칸 번호)를 부른다.
## 마시기·던지기 동작 시간은 eska.start_item(...)으로 맡긴다. 쓰러지거나 가마솥에 들르면 belt.refill().
## 그림(병·재료 아이콘·던진 병·터짐·몸에 도는 빛)은 EPotionFx(e_potion_fx.gd), 가마솥 화면은 EBrewUI(e_brew_ui.gd).
## 화면 표시(EHud)가 읽는 것: display_name(id) · color(id) · kind(id) · desc(id) · active_buffs(eska) · belt.slots

# ─── 재료 6가지 (이름만 봐도 뜻이 짐작되게) ─────────────────
const ING_ORDER: Array[String] = ["mandrake", "web", "toadstool", "dew", "feather", "soil"]
const INGREDIENTS := {
	"mandrake": {"name": "맨드레이크 뿌리", "short": "맨드레이크", "mean": "생명·비명"},
	"web": {"name": "거미줄", "short": "거미줄", "mean": "묶음"},
	"toadstool": {"name": "독버섯", "short": "독버섯", "mean": "썩음"},
	"dew": {"name": "달이슬", "short": "달이슬", "mean": "마력"},
	"feather": {"name": "까마귀 깃털", "short": "깃털", "mean": "메아리·가벼움"},
	"soil": {"name": "묘지 흙", "short": "묘지 흙", "mean": "죽음·먹어치움"},
}
const STRONG_ING := "dew" ## 세 번째 칸에 넣을 수 있는 재료 → "진한" 물약
const STRONG_MULT := 1.5 ## 진한 물약: 지속 시간(또는 즉시 양) × 이만큼
const STRONG_DOSE := -1 ## 진한 물약: 병 수 (최소 1병)

# ─── 효과 수치 (design.md 4-2, 시험으로 조정) ───────────────
const HEAL_HP := 2 ## 치유: 체력 +2 (진한 = 3)
const ECHO := 0.5 ## 메아리: 고급 마법이 이 세기로 한 번 더
const ECHO_T := 12.0
const LEECH := 1200 ## 포식: 주는 피해 이만큼마다 체력 +1
const LEECH_T := 12.0
const SURGE := 0.35 ## 충만: 종언 게이지 + 가득의 35%
const HASTE_CD := 2.0 ## 가속: 고급 마법 쿨다운이 2배 빠르게 줄어듦
const HASTE_SPEED := 1.15 ## 가속: 이동 +15%
const HASTE_T := 10.0
const GROW := 1.35 ## 확장: 모든 마법 범위 × 1.35
const GROW_T := 12.0
const BIND_T := 3.0 ## 속박: 묶는 시간 (강자는 status_resist만큼 짧게 — EEnemy.root)
const BIND_R := 56.0
const SCREAM_T := 1.2 ## 비명: 기절 시간 (하던 동작 끊김)
const SCREAM_R := 70.0
const SCREAM_POISE := 400 ## 비명: 강자 버팀 피해 (EEnemy.poise_damage — 버팀이 없는 적은 아무 일 없음)
const ROT_R := 56.0 ## 부식: 독안개 반경
const ROT_CLOUD_T := 4.0 ## 독안개가 남는 시간
const ROT_VULN_T := 8.0 ## 안개에 들어간 적: 이 시간 동안 받는 피해 × ROT_VULN
const ROT_VULN := 1.3
const BITTER_T := 1.0 ## 쓴 물(마심): 비틀거리며 느려지는 시간
const BITTER_SLOW := 0.45 ## 쓴 물(마심): 이동 배수
const BITTER_HASTE_T := 2.5 ## 쓴 물(던짐): 맞은 적이 빨라지는 시간
const BITTER_HASTE := 1.5 ## 쓴 물(던짐): 적 빠르기 배수
const MURKY_R := 44.0 ## 흐린 물(던짐): 아무 일도 없는 물보라 반경

# ─── 마시기·던지기 동작 시간 (eska.start_item에 넘김) ────────
const HEAL_DRINK := 0.45 ## 치유는 길게 들이켬 (그동안 맞으면 끊김 — 동작은 EEska가 맡음)
const HEAL_FIRE := 0.4
const DRINK := 0.3 ## 나머지 마시는 물약
const DRINK_FIRE := 0.22
const THROW := 0.22
const THROW_FIRE := 0.08

## 물약 자료: name 이름 · kind "drink"(마심)/"throw"(던짐) · doses 병 수 · color 물빛 · accent 반짝이 · desc 한 줄 설명
## 파랑 없음 — 치유 장밋빛, 버프는 보랏빛 변주(각자 반짝이 색), 속박 호박색, 비명 은백, 부식 독초록, 흐린 물 잿빛, 쓴 물 쓴 갈색
const POTIONS := {
	"heal": {"name": "치유", "kind": "drink", "doses": 3, "color": Color("#ff4d6d"), "accent": Color("#ffd3dc"), "desc": "들이켜 체력 +2"},
	"echo": {"name": "메아리", "kind": "drink", "doses": 2, "color": Color("#b9a2ff"), "accent": Color("#ffffff"), "desc": "12초: 고급 마법이 50% 세기로 한 번 더"},
	"feast": {"name": "포식", "kind": "drink", "doses": 2, "color": Color("#b42a63"), "accent": Color("#ff8fb8"), "desc": "12초: 피해 1200마다 체력 +1"},
	"surge": {"name": "충만", "kind": "drink", "doses": 2, "color": Color("#e352ff"), "accent": Color("#ffe9a8"), "desc": "종언 게이지 +35%"},
	"haste": {"name": "가속", "kind": "drink", "doses": 2, "color": Color("#ff8ad8"), "accent": Color("#fff3b0"), "desc": "10초: 고급 마법 쿨다운 2배 빠르게 · 이동 +15%"},
	"grow": {"name": "확장", "kind": "drink", "doses": 2, "color": Color("#9150e8"), "accent": Color("#ffb3f2"), "desc": "12초: 모든 마법 범위 1.35배"},
	"bind": {"name": "속박", "kind": "throw", "doses": 3, "color": Color("#ffb347"), "accent": Color("#fff0c8"), "desc": "깨진 자리 반경 56: 3초 묶음"},
	"scream": {"name": "비명", "kind": "throw", "doses": 2, "color": Color("#e9e4f2"), "accent": Color("#ffffff"), "desc": "반경 70: 하던 동작이 끊기고 1.2초 기절"},
	"rot": {"name": "부식", "kind": "throw", "doses": 3, "color": Color("#8fe04a"), "accent": Color("#e6ffb0"), "desc": "독안개 4초: 들어간 적은 8초 동안 받는 피해 +30%"},
	"murky": {"name": "흐린 물", "kind": "drink", "doses": 2, "color": Color("#8f877c"), "accent": Color("#d6d0c6"), "desc": "밍밍하다. 아무 일도 없다"},
	"murky_t": {"name": "흐린 물", "kind": "throw", "doses": 2, "color": Color("#8f877c"), "accent": Color("#d6d0c6"), "desc": "물보라만 튄다. 아무 일도 없다"},
	"bitter": {"name": "쓴 물", "kind": "drink", "doses": 2, "color": Color("#a2793a"), "accent": Color("#e8c98a"), "desc": "마시면 1초 비틀거리며 느려진다"},
	"bitter_t": {"name": "쓴 물", "kind": "throw", "doses": 2, "color": Color("#a2793a"), "accent": Color("#e8c98a"), "desc": "맞은 적이 잠깐 빨라진다"},
}
## 수첩에 한 칸씩 보이는 물약 (흐린 물·쓴 물은 마심/던짐을 한 칸으로)
const NOTEBOOK_ORDER: Array[String] = ["heal", "echo", "feast", "surge", "haste", "grow", "bind", "scream", "rot", "murky", "bitter"]

## 조합 = 재료 2개 (같은 것 둘도 가능, 21가지). 열쇠는 ING_ORDER 순서로 "앞+뒤"
const RECIPES := {
	# 의미 있는 조합 9개
	"mandrake+soil": "heal",
	"dew+feather": "echo",
	"toadstool+soil": "feast",
	"dew+dew": "surge",
	"feather+feather": "haste",
	"web+toadstool": "grow",
	"web+web": "bind",
	"mandrake+mandrake": "scream",
	"toadstool+toadstool": "rot",
	# 쓴 물 5개 (상극: 생명+썩음, 마력+썩음, 마력+죽음, 가벼움+흙, 흙뿐)
	"mandrake+toadstool": "bitter_t",
	"toadstool+dew": "bitter_t",
	"dew+soil": "bitter",
	"feather+soil": "bitter",
	"soil+soil": "bitter",
	# 흐린 물 7개 (서로 아무 상관 없는 것끼리)
	"mandrake+web": "murky_t",
	"mandrake+dew": "murky",
	"mandrake+feather": "murky",
	"web+dew": "murky_t",
	"web+feather": "murky_t",
	"web+soil": "murky_t",
	"toadstool+feather": "murky_t",
}

## 처음 허리띠 (훈련장에 들어가자마자 쓸 수 있게): 없음 = 치유 · ↑ = 메아리 · ↓ = 속박
const DEFAULT_LOADOUT: Array[String] = ["heal", "echo", "bind"]
const SLOT_KEYS: Array[String] = ["F", "↑F", "↓F"]

## 마녀 수첩: 처음 달인 조합을 적어 둔다 (열쇠 → 물약 id). 들고 시작하는 물약 셋은 처음부터 안다
static var notebook := {"mandrake+soil": "heal", "dew+feather": "echo", "web+web": "bind"}
## 시험용: 마지막으로 깨진 병 {id, pos, hits}
static var last_splash := {}


# ═══════════════════════════════════════════════════════════
# 자료 읽기 (화면 표시가 쓴다)
# ═══════════════════════════════════════════════════════════

static func has(id: String) -> bool:
	return POTIONS.has(id)


static func display_name(id: String) -> String:
	return String(POTIONS[id]["name"]) if POTIONS.has(id) else ""


static func color(id: String) -> Color:
	return POTIONS[id]["color"] if POTIONS.has(id) else Color("#5c5470")


static func accent(id: String) -> Color:
	return POTIONS[id]["accent"] if POTIONS.has(id) else Color("#d9ccff")


## "drink"(마심) · "throw"(던짐) · "" (빈 칸)
static func kind(id: String) -> String:
	return String(POTIONS[id]["kind"]) if POTIONS.has(id) else ""


static func desc(id: String) -> String:
	return String(POTIONS[id]["desc"]) if POTIONS.has(id) else ""


## 가득일 때 병 수 (진한 물약은 -1, 최소 1)
static func doses_of(id: String, strong := false) -> int:
	if not POTIONS.has(id):
		return 0
	var n := int(POTIONS[id]["doses"])
	return maxi(n + STRONG_DOSE, 1) if strong else n


## 좋은 물약인가 (흐린 물·쓴 물이 아님)
static func is_good(id: String) -> bool:
	return POTIONS.has(id) and not id.begins_with("murky") and not id.begins_with("bitter")


## 수첩 칸 id (흐린 물·쓴 물의 마심/던짐을 한 칸으로)
static func book_id(id: String) -> String:
	return id.trim_suffix("_t")


static func ing_name(ing: String, short := false) -> String:
	if not INGREDIENTS.has(ing):
		return ""
	return String(INGREDIENTS[ing]["short" if short else "name"])


# ═══════════════════════════════════════════════════════════
# 조합 · 달이기
# ═══════════════════════════════════════════════════════════

## 재료 두 개의 조합 열쇠 (순서 상관없이 같은 열쇠)
static func recipe_key(a: String, b: String) -> String:
	if ING_ORDER.find(a) > ING_ORDER.find(b):
		var t := a
		a = b
		b = t
	return a + "+" + b


static func recipe_of(a: String, b: String) -> String:
	return String(RECIPES.get(recipe_key(a, b), ""))


## 수첩에 적힌 조합인가
static func known(a: String, b: String) -> bool:
	return notebook.has(recipe_key(a, b))


## 이 물약(수첩 칸 id)을 하나라도 발견했나
static func discovered(book: String) -> bool:
	for k: String in notebook:
		if book_id(String(notebook[k])) == book:
			return true
	return false


## 이 물약(수첩 칸 id)을 만드는 알려진 조합들 [[a, b], ...]
static func known_recipes(book: String) -> Array:
	var out := []
	for k: String in notebook:
		if book_id(String(notebook[k])) == book:
			out.append(k.split("+"))
	return out


## 달이기: 재료 a·b (+ 세 번째 칸 달이슬이면 strong). 결과 {id, strong, new(처음 만든 조합인가)}
static func brew(a: String, b: String, strong := false) -> Dictionary:
	var key := recipe_key(a, b)
	var id := String(RECIPES.get(key, "murky"))
	var is_new := not notebook.has(key)
	var book_new := is_new and not discovered(book_id(id))
	notebook[key] = id
	return {"id": id, "strong": strong, "new": is_new, "new_kind": book_new}


# ═══════════════════════════════════════════════════════════
# 허리띠
# ═══════════════════════════════════════════════════════════

## 허리띠: 칸 3개. 칸 = {"id": 물약 id ("" = 빈 칸), "left": 남은 병, "max": 가득일 때 병, "strong": 진한 물약인가}
class Belt extends RefCounted:
	var slots: Array = [{}, {}, {}]

	func _init() -> void:
		for i in EPotions.DEFAULT_LOADOUT.size():
			set_slot(i, EPotions.DEFAULT_LOADOUT[i], false)

	## 칸 i에 물약을 넣는다 (가득)
	func set_slot(i: int, id: String, strong := false) -> void:
		var n := EPotions.doses_of(id, strong)
		slots[i] = {"id": id, "left": n, "max": n, "strong": strong}

	func slot(i: int) -> Dictionary:
		return slots[i] if i >= 0 and i < slots.size() else {}

	func refill() -> void:
		for s: Dictionary in slots:
			if s.has("max"):
				s["left"] = s["max"]

	## 물약 자료 스크립트(EPotions) — 시험 실행기 식(Expression)은 전역 클래스 이름을 못 써서 이것으로 정적 함수를 부른다
	## 예: eska.belt.potions().use(eska, 0)
	func potions() -> GDScript:
		return EPotions

	## 다 차 있나
	func is_full() -> bool:
		for s: Dictionary in slots:
			if int(s.get("left", 0)) < int(s.get("max", 0)):
				return false
		return true


# ═══════════════════════════════════════════════════════════
# 쓰기 (마시기 · 던지기)
# ═══════════════════════════════════════════════════════════

## 칸 번호(0 없음 · 1 ↑ · 2 ↓)의 물약을 쓴다. 썼으면 true
## 빈 칸·남은 병 0이면 작은 "없음" 표시만 하고 false. 다른 동작 중(순간이동·시전·맞음·쓰러짐)이면 그냥 false
static func use(eska: EEska, slot: int) -> bool:
	if not is_instance_valid(eska) or eska.is_dead():
		return false
	var s: Dictionary = eska.belt.slot(slot)
	var id := String(s.get("id", ""))
	if id == "" or int(s.get("left", 0)) <= 0:
		EPotionFx.no_potion(eska)
		Sfx.play(&"es_pot_no", -6.0)
		return false
	if eska.st != EEska.St.NORMAL:
		return false
	s["left"] = int(s["left"]) - 1
	var strong := bool(s.get("strong", false))
	buffs_of(eska) # 쓰러짐·부활 연결을 미리 걸어 둠
	if kind(id) == "drink":
		Sfx.play(&"es_pot_uncork", -5.0)
		var heal := id == "heal"
		eska.start_item("drink", HEAL_DRINK if heal else DRINK, HEAL_FIRE if heal else DRINK_FIRE,
			func() -> void: _drink(eska, id, strong))
	else:
		eska.start_item("throw", THROW, THROW_FIRE, func() -> void: _throw(eska, id, strong))
	return true


## 마신 순간 (들이켜기가 끝까지 됐을 때만 불림)
static func _drink(eska: EEska, id: String, strong: bool) -> void:
	if not is_instance_valid(eska) or eska.is_dead():
		return
	var k := STRONG_MULT if strong else 1.0
	Sfx.play(&"es_pot_gulp", -3.0)
	EPotionFx.drink_burst(eska, id)
	match id:
		"heal":
			eska.hp = mini(eska.hp + int(round(HEAL_HP * k)), EEska.MAX_HP)
			EPotionFx.heal_rise(eska)
		"surge":
			eska.gauge = minf(eska.gauge + EEska.GAUGE_MAX * SURGE * k, EEska.GAUGE_MAX)
		"echo":
			buffs_of(eska).add(id, ECHO_T * k)
		"feast":
			buffs_of(eska).add(id, LEECH_T * k)
		"haste":
			buffs_of(eska).add(id, HASTE_T * k)
		"grow":
			buffs_of(eska).add(id, GROW_T * k)
		"bitter":
			buffs_of(eska).add(id, BITTER_T * k)
			eska.art.squash(Vector2(1.15, 0.85))
			Sfx.play(&"es_pot_no", -2.0)
		_:
			pass # 흐린 물: 밍밍하다


## 던지는 순간: 손에서 병이 돌며 포물선으로 날아간다 (필중 아님)
static func _throw(eska: EEska, id: String, strong: bool) -> void:
	if not is_instance_valid(eska) or eska.is_dead():
		return
	Sfx.play(&"es_pot_throw", -3.0)
	EPotionFx.throw_bottle(eska, id, strong)


## 병이 깨진 자리에 효과를 건다 (EPotionFx.Bottle이 부름). 맞은 표적 수를 돌려준다
static func splash(tree: SceneTree, eska: EEska, id: String, strong: bool, pos: Vector2) -> int:
	var k := STRONG_MULT if strong else 1.0
	var hits := 0
	var fx := EPotionFx.splash(id, strong, pos)
	match id:
		"bind":
			for d: Node2D in in_radius(tree, pos, BIND_R):
				hits += 1
				if d.has_method("root"):
					d.root(BIND_T * k)
				fx.track(d)
		"scream":
			for d: Node2D in in_radius(tree, pos, SCREAM_R):
				hits += 1
				if d.has_method("stun"):
					d.stun(SCREAM_T * k)
				if d.has_method("poise_damage"):
					d.poise_damage(SCREAM_POISE)
				fx.track(d)
		"rot":
			fx.rot_k = k # 안개가 남아 있는 동안 스스로 들어온 적에게 건다 (EPotionFx.Splash)
			hits = in_radius(tree, pos, ROT_R).size()
		"bitter_t":
			for d: Node2D in in_radius(tree, pos, BIND_R):
				hits += 1
				if d.has_method("haste"):
					d.haste(BITTER_HASTE_T * k, BITTER_HASTE)
				elif d is EEnemy:
					EPotionFx.hasten(d as EEnemy, BITTER_HASTE_T * k, BITTER_HASTE)
		_:
			hits = in_radius(tree, pos, MURKY_R).size()
	last_splash = {"id": id, "pos": pos, "hits": hits}
	return hits


## 반경 r 원에 맞히는 판정 사각형이 걸치는 살아 있는 표적들
static func in_radius(tree: SceneTree, pos: Vector2, r: float) -> Array:
	var out := []
	for d: Node2D in ETarget.alive(tree):
		var rc: Rect2 = d.hit_rect()
		var q := Vector2(clampf(pos.x, rc.position.x, rc.end.x), clampf(pos.y, rc.position.y, rc.end.y))
		if q.distance_to(pos) <= r:
			out.append(d)
	return out


# ═══════════════════════════════════════════════════════════
# 몸에 도는 물약 (버프)
# ═══════════════════════════════════════════════════════════

## 지금 걸린 물약들 [{id, left, dur}] — 화면 표시용
static func active_buffs(eska: EEska) -> Array:
	var b := find_buffs(eska)
	return b.list_view() if b else []


static func find_buffs(eska: EEska) -> Buffs:
	if not is_instance_valid(eska):
		return null
	return eska.get_node_or_null("PotionBuffs") as Buffs


## 에스카에게 붙은 버프 노드 (없으면 만든다)
static func buffs_of(eska: EEska) -> Buffs:
	var b := find_buffs(eska)
	if b == null:
		b = Buffs.new()
		b.name = "PotionBuffs"
		b.eska = eska
		eska.add_child(b)
	return b


## 버프 모음: 에스카의 자식 노드. 걸린 동안 eska.mods를 바꾸고, 끝나면 되돌린다.
## 같은 물약을 또 마시면 시간만 처음부터(겹치지 않음). 다른 물약끼리는 같이 걸린다(배수는 곱, 메아리는 큰 쪽, 포식은 작은 간격).
## 쓰러지면 모두 풀리고 허리띠가 다시 가득 찬다 (design.md 4-2).
class Buffs extends Node2D:
	## 물약이 건드리는 mods 열쇠와 기본값 (나머지 열쇠는 건드리지 않는다)
	const BASE := {"size": 1.0, "cd_rate": 1.0, "speed": 1.0, "echo": 0.0, "leech": 0}
	## 버프마다 바꾸는 값
	const EFFECT := {
		"echo": {"echo": EPotions.ECHO},
		"feast": {"leech": EPotions.LEECH},
		"haste": {"cd_rate": EPotions.HASTE_CD, "speed": EPotions.HASTE_SPEED},
		"grow": {"size": EPotions.GROW},
		"bitter": {"speed": EPotions.BITTER_SLOW},
	}
	var eska: EEska
	var list := {} ## id → {"left": 남은 초, "dur": 처음 초}

	func _ready() -> void:
		for icons: bool in [false, true]: # 몸 둘레 빛(가산, 몸 뒤) · 머리 위 시간 아이콘
			var v := EPotionFx.BuffView.new()
			v.buffs = self
			v.icons = icons
			add_child(v)
		if is_instance_valid(eska) and not eska.died.is_connected(_on_died):
			eska.died.connect(_on_died)

	func add(id: String, dur: float) -> void:
		list[id] = {"left": dur, "dur": dur}
		_apply()

	func clear() -> void:
		list.clear()
		_apply()

	func list_view() -> Array:
		var out := []
		for id: String in list:
			out.append({"id": id, "left": float(list[id]["left"]), "dur": float(list[id]["dur"])})
		return out

	func _physics_process(delta: float) -> void:
		if list.is_empty():
			return
		var gone := false
		for id: String in list.keys():
			list[id]["left"] = float(list[id]["left"]) - delta
			if float(list[id]["left"]) <= 0.0:
				list.erase(id)
				gone = true
				Sfx.play_pitch(&"es_pot_no", 1.6, -16.0) # 풀리는 작은 소리
		if gone:
			_apply()

	## 걸린 버프들로 mods를 처음부터 다시 계산
	func _apply() -> void:
		if not is_instance_valid(eska):
			return
		var m := BASE.duplicate()
		for id: String in list:
			var eff: Dictionary = EFFECT.get(id, {})
			for key: String in eff:
				match key:
					"echo":
						m[key] = maxf(float(m[key]), float(eff[key]))
					"leech":
						m[key] = int(eff[key]) if int(m[key]) == 0 else mini(int(m[key]), int(eff[key]))
					_:
						m[key] = float(m[key]) * float(eff[key])
		for key: String in m:
			eska.mods[key] = m[key]

	func _on_died() -> void:
		clear()
		eska.belt.refill()
