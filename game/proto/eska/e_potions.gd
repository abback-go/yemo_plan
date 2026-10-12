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
const STRONG_MULT := 1.5 ## 진한 물약: 지속 시간 × 이만큼 (속박·부식·쓴 물 — 나머지는 아래 따로)
const STRONG_DOSE := -1 ## 진한 물약: 병 수 (최소 1병). 병이 적은 대신 한 번에 강하게 — 총량은 같거나 약간 이득(×1.2 안쪽)

# ─── 마시는 물약 (loop2_plan.md 4장: 짧고 날카롭게) ─────────
const HEAL_HP := 2 ## 치유: 체력 +2 (3병 = 6)
const HEAL_HP_STRONG := 3 ## 진한 치유: +3 (2병 = 6)
const ECHO := 0.5 ## 메아리: 고급 마법이 이 세기로 한 번 더
const ECHO_N := 2 ## 메아리: 다음 고급 마법 이만큼이 메아리 (2병 = 4번)
const ECHO_STRONG := 0.6 ## 진한 메아리: 세기
const ECHO_N_STRONG := 4 ## 진한 메아리: 4번 × 0.6 = 2.4 (보통 2병 = 2.0의 1.2배)
const LEECH := 1200 ## 포식: 주는 피해 이만큼마다 체력 +1
const LEECH_T := 12.0
const LEECH_CAP := 2 ## 포식: 한 번 마시면 최대 +2 (다 채우면 바로 풀림)
const LEECH_T_STRONG := 18.0
const LEECH_CAP_STRONG := 5 ## 진한 포식: 최대 +5 (보통 2병 = +4)
const SURGE := 0.35 ## 충만: 종언 게이지 + 가득의 35%
const SURGE_STRONG := 0.84 ## 진한 충만: 84% (보통 2병 = 70%의 1.2배)
const HASTE_SPEED := 1.15 ## 가속: 마시면 고급 마법 쿨다운이 모두 0 + 이동 +15%
const HASTE_T := 4.0
const HASTE_T_STRONG := 6.0 ## 진한 가속: 6초 동안 이동 +15% + 쿨다운 2배 빠르게
const HASTE_CD_STRONG := 2.0
const GROW := 1.35 ## 확장: 모든 마법 범위 × 1.35
const GROW_T := 12.0
const GROW_STRONG := 1.5 ## 진한 확장: × 1.5로 18초
const GROW_T_STRONG := 18.0
const DRINK_GAP := 1.5 ## 마시는 버프: 같은 칸을 다시 쓰기까지 (전투 전 몰아 마시기 방지 — 치유는 빼고)

# ─── 던지는 물약 ────────────────────────────────────────────
const BIND_T := 3.0 ## 속박: 묶는 시간 (강자는 status_resist만큼 짧게 — EEnemy.root). 진한 = × 1.5
const BIND_R := 56.0
const BIND_RESIST_CUT := 0.5 ## 진한 속박: 강자의 status_resist를 이 몫만 적용 (덜 버팀)
const SCREAM_T := 1.2 ## 비명: 기절 시간 (하던 동작 끊김)
const SCREAM_T_STRONG := 2.4 ## 진한 비명: 한 병으로 보통 2병만큼
const SCREAM_R := 70.0
const SCREAM_POISE := 250 ## 비명: 강자 버팀 피해 (EEnemy.poise_damage — 버팀이 없는 적은 아무 일 없음) — loop3 3장
const SCREAM_POISE_STRONG := 700 ## 진한 비명: 반격 자세를 확실히 깨고 버팀 700
const ROT_R := 56.0 ## 부식: 독안개 반경
const ROT_CLOUD_T := 4.0 ## 독안개가 남는 시간 (진한 = × 1.5)
const ROT_VULN_T := 8.0 ## 안개에 들어간 적: 이 시간 동안 받는 피해 × ROT_VULN (진한 = × 1.5)
const ROT_VULN := 1.3
const ROT_VULN_STRONG := 1.45 ## 진한 부식: +45%
const BITTER_T := 1.0 ## 쓴 물(마심): 비틀거리며 느려지는 시간
const BITTER_SLOW := 0.45 ## 쓴 물(마심): 이동 배수
const BITTER_HASTE_T := 2.5 ## 쓴 물(던짐): 맞은 적이 빨라지는 시간
const BITTER_HASTE := 1.5 ## 쓴 물(던짐): 적 빠르기 배수
const MURKY_R := 44.0 ## 흐린 물(던짐): 아무 일도 없는 물보라 반경

# ─── 틈 달이기 (loop2_plan.md 2장): 던진 병이 열린 틈에 닿으면 깨지지 않고 스며들어 틈 모양을 따라 퍼진다 ──
const RIFT_TOUCH := 10.0 ## 병이 틈(가운데 선 + 굵기 절반)에서 이만큼 안이면 닿음
const RIFT_AIM := 24.0 ## 이 안의 열린 틈 쪽으로 병이 살짝 휜다 (조준 조금 너그럽게 — 40은 거의 저절로 들어가서 loop3에서 줄임)
const RIFT_FRESH := 0.5 ## "갓 찢긴 틈": 열린 지 이 시간 안의 틈에 닿은 병만 보상(진함·저항 무시·꿰맬 때 한 번 더) — loop4 4장
const RIFT_SELF_T := 0.12 ## 던진 뒤 이 시간 동안은 틈 무시 (자기 손 근처 틈 — 단공 등 — 이 병을 삼키지 않게)
const RIFT_SELF_R := 40.0 ## 손에서 이 거리 안에서도 틈 무시 (둘 다 지나야 틈에 닿음)
const RIFT_STITCH_POISE := 300 ## 틈이 꿰매질 때 한 번 더: 속박 → 강자 버팀 피해
const RIFT_STITCH_STUN := 0.4 ## 틈이 꿰매질 때 한 번 더: 비명 → 기절 다시 (강자 저항 무시). 부식 → 시간 갱신
const RIFT_BAND := 24.0 ## 틈 전체 길이 ± 이만큼 안의 적에게 효과
const RIFT_MURKY_EXTEND := 1.0 ## 흐린 물: 틈이 이만큼 더 열려 있음
const RIFT_BITTER_VULN := 1.15 ## 쓴 물: 틈의 적이 빨라지지만 받는 피해 +15%
const RIFT_HITSTOP := 0.05 ## 스며드는 순간 작은 멈춤

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
	"echo": {"name": "메아리", "kind": "drink", "doses": 2, "color": Color("#b9a2ff"), "accent": Color("#ffffff"), "desc": "다음 고급 마법 2번이 50% 세기로 한 번 더"},
	"feast": {"name": "포식", "kind": "drink", "doses": 2, "color": Color("#b42a63"), "accent": Color("#ff8fb8"), "desc": "12초: 피해 1200마다 체력 +1 (최대 +2)"},
	"surge": {"name": "충만", "kind": "drink", "doses": 2, "color": Color("#e352ff"), "accent": Color("#ffe9a8"), "desc": "종언 게이지 +35%"},
	"haste": {"name": "가속", "kind": "drink", "doses": 2, "color": Color("#ff8ad8"), "accent": Color("#fff3b0"), "desc": "고급 마법 쿨다운 즉시 초기화 · 4초 이동 +15%"},
	"grow": {"name": "확장", "kind": "drink", "doses": 2, "color": Color("#9150e8"), "accent": Color("#ffb3f2"), "desc": "12초: 모든 마법 범위 1.35배"},
	"bind": {"name": "속박", "kind": "throw", "doses": 4, "color": Color("#ffb347"), "accent": Color("#fff0c8"), "desc": "깨진 자리 반경 56: 3초 묶음"},
	"scream": {"name": "비명", "kind": "throw", "doses": 3, "color": Color("#e9e4f2"), "accent": Color("#ffffff"), "desc": "반경 70: 하던 동작이 끊기고 1.2초 기절"},
	"rot": {"name": "부식", "kind": "throw", "doses": 4, "color": Color("#8fe04a"), "accent": Color("#e6ffb0"), "desc": "독안개 4초: 들어간 적은 8초 동안 받는 피해 +30%"},
	"murky": {"name": "흐린 물", "kind": "drink", "doses": 2, "color": Color("#8f877c"), "accent": Color("#d6d0c6"), "desc": "밍밍하다. 아무 일도 없다"},
	"murky_t": {"name": "흐린 물", "kind": "throw", "doses": 2, "color": Color("#8f877c"), "accent": Color("#d6d0c6"), "desc": "물보라만 튄다. 아무 일도 없다"},
	"bitter": {"name": "쓴 물", "kind": "drink", "doses": 2, "color": Color("#a2793a"), "accent": Color("#e8c98a"), "desc": "마시면 1초 비틀거리며 느려진다"},
	"bitter_t": {"name": "쓴 물", "kind": "throw", "doses": 2, "color": Color("#a2793a"), "accent": Color("#e8c98a"), "desc": "맞은 적이 잠깐 빨라진다"},
}
## 진한 물약 설명 (한 번에 강하게 — 던지는 진한 물약은 성질이 바뀜)
const STRONG_DESC := {
	"heal": "들이켜 체력 +3",
	"echo": "다음 고급 마법 4번이 60% 세기로 한 번 더",
	"feast": "18초: 피해 1200마다 체력 +1 (최대 +5)",
	"surge": "종언 게이지 +84%",
	"haste": "쿨다운 즉시 초기화 · 6초 이동 +15% · 쿨다운 2배 빠르게",
	"grow": "18초: 모든 마법 범위 1.5배",
	"bind": "4.5초 묶음 · 강자도 덜 버틴다",
	"scream": "2.4초 기절 · 반격 자세를 깨고 버팀을 크게 깎는다",
	"rot": "독안개 6초: 12초 동안 받는 피해 +45%",
}
## 마녀 수첩 메모: 아직 모르는 물약 칸에 "???" 대신 (재료 짝을 대놓고 말하지 않는 힌트)
const HINTS := {
	"heal": "뿌리의 생명을 무덤에 묻으면, 상처가 닫힌다.",
	"echo": "달빛 젖은 깃은 소리를 한 번 더 낸다.",
	"feast": "무덤 흙은 썩은 것을 먹고 자란다… 나도 그렇다.",
	"surge": "달빛에 달빛을 겹치면 잔이 넘친다.",
	"haste": "가벼운 것에 가벼운 것을. 날개가 둘이면 시간을 앞지른다.",
	"grow": "썩어 번지는 것을 그물에 걸면, 그물이 넓어진다.",
	"bind": "실에 실을 꼬면 무엇이든 붙든다.",
	"scream": "뿌리 둘을 함께 뽑으면… 비명이 난다.",
	"rot": "썩음에 썩음을 더하면 공기마저 썩는다.",
	"murky": "서로 모르는 것끼리는 섞여도 말이 없다.",
	"bitter": "원수끼리 섞으면 혀가 먼저 안다. 생명과 썩음, 달빛과 무덤.",
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

## 처음 허리띠 (훈련장에 들어가자마자 쓸 수 있게): 없음(F) = 속박 · ↑ = 메아리 · ↓ = 치유
## 속박을 방향 없는 칸에 — 폰에서 "스킬 → 물약" 0.3초 박자로 갓 찢긴 틈에 바로 던지게 (loop6_plan 3장)
const DEFAULT_LOADOUT: Array[String] = ["bind", "echo", "heal"]
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


## 설명 (진한 물약이면 진한 설명)
static func desc_of(id: String, strong: bool) -> String:
	if strong and STRONG_DESC.has(id):
		return String(STRONG_DESC[id])
	return desc(id)


## 마녀 수첩 메모 (수첩 칸 id)
static func hint(book: String) -> String:
	return String(HINTS.get(book, ""))


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

	## 틈 등록부(ERifts) — 시험 실행기 식에서 틈을 직접 열 때. 예: eska.belt.rifts().open(PackedVector2Array([...]), 20, 1.0)
	func rifts() -> GDScript:
		return ERifts

	## 다 차 있나
	func is_full() -> bool:
		for s: Dictionary in slots:
			if int(s.get("left", 0)) < int(s.get("max", 0)):
				return false
		return true


# ═══════════════════════════════════════════════════════════
# 쓰기 (마시기 · 던지기)
# ═══════════════════════════════════════════════════════════

static var rift_brews := 0 ## 시험용: 틈에 스며든 병 수
static var star_brews := 0 ## 시험용: 흑성에 빨려 든 병 수
static var stitches := 0 ## 시험용: 틈이 꿰매질 때 한 번 더 걸린 수 (틈 하나에 1)


## 칸 번호(0 없음 · 1 ↑ · 2 ↓)의 물약을 쓴다. 썼으면 true
## 빈 칸·남은 병 0이면 작은 "없음" 표시만 하고 false. 다른 동작 중(순간이동·시전·맞음·쓰러짐)이면 그냥 false
## 마시는 버프(치유 빼고)는 같은 칸을 DRINK_GAP초 안에 다시 쓰면 false
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
	var b := buffs_of(eska) # 쓰러짐·부활 연결을 미리 걸어 둠
	var gapped := kind(id) == "drink" and id != "heal"
	if gapped and b.slot_wait(slot) > 0.0:
		Sfx.play_pitch(&"es_pot_no", 1.3, -14.0) # 같은 칸은 잠깐 뒤에 (몰아 마시기 방지)
		return false
	s["left"] = int(s["left"]) - 1
	if gapped:
		b.hold_slot(slot, DRINK_GAP)
	var strong := bool(s.get("strong", false))
	if kind(id) == "drink":
		Sfx.play(&"es_pot_uncork", -5.0)
		var heal := id == "heal"
		eska.start_item("drink", HEAL_DRINK if heal else DRINK, HEAL_FIRE if heal else DRINK_FIRE,
			func() -> void: _drink(eska, id, strong))
	else:
		eska.start_item("throw", THROW, THROW_FIRE, func() -> void: _throw(eska, id, strong))
	return true


## 같은 칸을 다시 마실 수 있기까지 남은 초 (화면 표시용, 0 = 바로)
static func slot_wait(eska: EEska, slot: int) -> float:
	var b := find_buffs(eska)
	return b.slot_wait(slot) if b else 0.0


## 마신 순간 (들이켜기가 끝까지 됐을 때만 불림)
static func _drink(eska: EEska, id: String, strong: bool) -> void:
	if not is_instance_valid(eska) or eska.is_dead():
		return
	var b := buffs_of(eska)
	Sfx.play(&"es_pot_gulp", -3.0)
	EPotionFx.drink_burst(eska, id)
	match id:
		"heal":
			eska.hp = mini(eska.hp + (HEAL_HP_STRONG if strong else HEAL_HP), EEska.MAX_HP)
			b.sync_hp() # 포식이 이 회복을 제 몫으로 세지 않게
			EPotionFx.heal_rise(eska)
		"surge":
			eska.add_gauge(EEska.GAUGE_MAX * (SURGE_STRONG if strong else SURGE))
		"echo":
			b.add_charges(id, ECHO_N_STRONG if strong else ECHO_N, {"echo": ECHO_STRONG if strong else ECHO})
		"feast":
			b.add(id, LEECH_T_STRONG if strong else LEECH_T, {"leech": LEECH})
			b.feast_cap = LEECH_CAP_STRONG if strong else LEECH_CAP
			b.feast_got = 0
		"haste":
			for k: String in eska.cooldowns: # 고급 마법 쿨다운 즉시 초기화
				eska.cooldowns[k] = 0.0
			var eff := {"speed": HASTE_SPEED}
			if strong:
				eff["cd_rate"] = HASTE_CD_STRONG
			b.add(id, HASTE_T_STRONG if strong else HASTE_T, eff)
			EPotionFx.haste_reset(eska)
		"grow":
			b.add(id, GROW_T_STRONG if strong else GROW_T, {"size": GROW_STRONG if strong else GROW})
		"bitter":
			b.add(id, BITTER_T * (STRONG_MULT if strong else 1.0), {"speed": BITTER_SLOW})
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


# ─── 던지는 물약이 표적 하나에 거는 것 (깨진 자리 · 틈 · 흑성이 같이 쓴다) ──

## 속박: 묶음. 진한 속박은 강자의 status_resist를 절반만 받는다. full = 저항 무시 (틈에 스민 물약)
static func bind_one(d: Node2D, strong: bool, full := false) -> void:
	if not d.has_method("root"):
		return
	var sec := BIND_T * (STRONG_MULT if strong else 1.0)
	var sr := _resist(d)
	if sr > 0.0 and sr < 1.0: # root가 (1 - sr)을 곱하므로 미리 나눠 둔다
		if full:
			sec /= 1.0 - sr
		elif strong: # (1 - sr × 절반)이 되게
			sec *= (1.0 - sr * BIND_RESIST_CUT) / (1.0 - sr)
	d.root(sec)


## 강자 저항 (status_resist, 없으면 0)
static func _resist(d: Node2D) -> float:
	var res: Variant = d.get("status_resist")
	return float(res) if res != null else 0.0


## 기절 sec초 (full = 강자 저항 무시 — stun이 (1 - sr)을 곱하므로 미리 나눔)
static func _stun(d: Node2D, sec: float, full: bool) -> void:
	if not d.has_method("stun"):
		return
	var sr := _resist(d)
	if full and sr > 0.0 and sr < 1.0:
		sec /= 1.0 - sr
	d.stun(sec)


## 비명: 하던 동작이 끊기고 기절 + 강자 버팀 피해. 진한 비명은 반격 자세를 확실히 깬다 (break_counter가 있으면)
static func scream_one(d: Node2D, strong: bool, full := false) -> void:
	_stun(d, scream_time(strong), full)
	if d.has_method("poise_damage"):
		d.poise_damage(SCREAM_POISE_STRONG if strong else SCREAM_POISE)
	if strong and d.has_method("break_counter"):
		d.break_counter()


static func scream_time(strong: bool) -> float:
	return SCREAM_T_STRONG if strong else SCREAM_T


## 부식: 받는 피해 증가 (더 센 부식을 약한 것으로 덮지 않음)
static func rot_one(d: Node2D, strong: bool) -> void:
	if not d.has_method("set_vuln"):
		return
	var k := STRONG_MULT if strong else 1.0
	_vuln(d, ROT_VULN_T * k, ROT_VULN_STRONG if strong else ROT_VULN)


## 쓴 물(던짐): 적이 잠깐 빨라짐. vuln > 1이면 받는 피해도 늘림 (틈 달이기)
static func bitter_one(d: Node2D, strong: bool, vuln := 1.0) -> void:
	var sec := BITTER_HASTE_T * (STRONG_MULT if strong else 1.0)
	if d.has_method("haste"):
		d.haste(sec, BITTER_HASTE)
	elif d is EEnemy:
		EPotionFx.hasten(d as EEnemy, sec, BITTER_HASTE)
	if vuln > 1.0 and d.has_method("set_vuln"):
		_vuln(d, sec, vuln)


## set_vuln은 배수를 덮어쓰므로, 이미 더 센 부식이 걸려 있으면 그 배수를 지킨다
static func _vuln(d: Node2D, sec: float, mult: float) -> void:
	var cur_t: Variant = d.get("vuln_t")
	var cur_m: Variant = d.get("vuln_mult")
	if cur_t != null and cur_m != null and float(cur_t) > 0.0 and float(cur_m) > mult:
		d.set_vuln(sec, float(cur_m))
	else:
		d.set_vuln(sec, mult)


## id 물약을 표적 하나에 (rift = 틈·흑성에서 — 쓴 물이 받는 피해도 늘림 · full = 강자 저항 무시: 갓 찢긴 틈·흑성)
static func apply_one(d: Node2D, id: String, strong: bool, rift := false, full := false) -> void:
	match id:
		"bind":
			bind_one(d, strong, full)
		"scream":
			scream_one(d, strong, full)
		"rot":
			rot_one(d, strong)
		"bitter_t":
			bitter_one(d, strong, RIFT_BITTER_VULN if rift else 1.0)


## 틈이 꿰매질 때 한 번 더 (틈에 스민 물약): 속박 → 버팀 피해 · 비명 → 기절 다시 · 부식 → 시간 갱신
static func stitch_one(d: Node2D, id: String) -> void:
	match id:
		"bind":
			if d.has_method("poise_damage"):
				d.poise_damage(RIFT_STITCH_POISE)
		"scream":
			_stun(d, RIFT_STITCH_STUN, true)
		"rot":
			rot_one(d, true)


## 갓 찢긴 틈인가 (열린 지 RIFT_FRESH초 안)
static func rift_fresh(rift: Dictionary) -> bool:
	return ERifts.age(rift) < RIFT_FRESH


## 이 틈에 물약이 스며들 만한가: 틈 ± RIFT_BAND 안에 살아 있는 표적이 있어야 (아무도 없는 틈은 병을 삼키지 않음). 흐린 물은 늘 (틈을 늘리는 게 일이라)
static func rift_live(tree: SceneTree, rift: Dictionary, id: String) -> bool:
	if id.begins_with("murky"):
		return true
	var pts: PackedVector2Array = rift.get("pts", PackedVector2Array())
	for d: Node2D in ETarget.alive(tree):
		if rect_to_line(d.hit_rect(), pts) <= RIFT_BAND:
			return true
	return false


## 병이 깨진 자리에 효과를 건다 (EPotionFx.Bottle이 부름). 맞은 표적 수를 돌려준다
static func splash(tree: SceneTree, _eska: EEska, id: String, strong: bool, pos: Vector2) -> int:
	var hits := 0
	var fx := EPotionFx.splash(id, strong, pos)
	match id:
		"bind":
			for d: Node2D in in_radius(tree, pos, BIND_R):
				hits += 1
				bind_one(d, strong)
				fx.track(d)
		"scream":
			for d: Node2D in in_radius(tree, pos, SCREAM_R):
				hits += 1
				scream_one(d, strong)
				fx.track(d)
		"rot":
			fx.rot_on = true # 안개가 남아 있는 동안 스스로 들어온 적에게 건다 (EPotionFx.Splash)
			hits = in_radius(tree, pos, ROT_R).size()
		"bitter_t":
			for d: Node2D in in_radius(tree, pos, BIND_R):
				hits += 1
				bitter_one(d, strong)
		_:
			hits = in_radius(tree, pos, MURKY_R).size()
	last_splash = {"id": id, "pos": pos, "hits": hits}
	return hits


## 틈 달이기: 병이 열린 틈(ERifts의 틈 하나)에 스며들었다 — 효과가 틈 모양을 따라 퍼진다 (틈 ± RIFT_BAND 안의 적).
## **갓 찢긴 틈**(fresh — 닿은 순간 ERifts.age < RIFT_FRESH)에 스민 물약만 **저절로 진하고 강자 저항(status_resist)을 무시**하며
## **틈이 꿰매질 때 한 번 더** 걸린다(stitch_one) — loop3 1장 · loop4 4장. 늦은 틈은 틈 모양으로 퍼지기만 (병 그대로의 세기).
## 속박 = 틈을 따라 거미줄 · 비명 = 틈이 울려 자리마다 기절 · 부식 = 틈 전체에서 독안개 · 흐린 물 = 틈이 1초 더 · 쓴 물 = 빨라지지만 피해 +15%
## 효과는 물약 색이 틈을 타고 번지다 표적에 닿는 순간 걸린다 (EPotionFx.RiftBrew). 걸릴 표적 수를 돌려준다
static func rift_brew(tree: SceneTree, _eska: EEska, id: String, strong: bool, rift: Dictionary, at: Vector2, fresh := true) -> int:
	var pts: PackedVector2Array = rift.get("pts", PackedVector2Array())
	ERifts.infuse(rift, id, color(id))
	if id.begins_with("murky"):
		ERifts.extend(rift, RIFT_MURKY_EXTEND)
	var targets := along(tree, pts, RIFT_BAND)
	var fx := EPotionFx.rift_brew(id, strong or fresh, pts, float(rift.get("w", 12.0)), at, fresh)
	fx.targets = targets
	fx.rift_id = int(rift.get("id", 0)) if fresh else 0 # 늦은 틈은 꿰맬 때 한 번 더 없음
	rift_brews += 1
	last_splash = {"id": id, "pos": at, "hits": targets.size(), "rift": int(rift.get("id", 0)), "fresh": fresh}
	return targets.size()


## 흑성이 병을 빨아들였다: 그 색의 검은 별이 되어 끌려온 적 모두에게 효과 (틈과 같이 저절로 진하고 저항 무시).
## 흑성의 absorb(id, color, apply)가 연출하고 apply를 부른다(인자 없이 — 걸린 표적 수를 돌려줌): 빨아들인 순간 + 붕괴 직전.
## 붕괴 직전 두 번째 부름 = 꿰매질 때 한 번 더(stitch_one). 흑성이 사라졌거나 더 못 빨아들이면 false (병은 그 자리에서 깨짐 — 효과·기록 없음)
static func star_brew(tree: SceneTree, _eska: EEska, id: String, _strong: bool, star: Node2D) -> bool:
	if not is_instance_valid(star) or not star.is_inside_tree():
		return false
	var c := EPotionFx.star_center(star)
	var r := EPotionFx.star_radius(star)
	var calls := [0]
	var apply := func() -> int:
		calls[0] += 1
		if not is_instance_valid(star):
			return 0
		return _star_apply(tree, id, EPotionFx.star_center(star), r, calls[0] > 1)
	if star.has_method("absorb"):
		if not bool(star.absorb(id, color(id), apply)):
			return false
	else:
		apply.call()
	star_brews += 1
	EPotionFx.star_gulp(id, c)
	return true


## 흑성에 끌려온(끌어당기는 반경 안의) 적 모두에게 id 물약 (stitch = 붕괴 직전 두 번째 — 꿰매질 때 한 번 더)
static func _star_apply(tree: SceneTree, id: String, c: Vector2, r: float, stitch: bool) -> int:
	var targets := in_radius(tree, c, r)
	var fx := EPotionFx.rift_brew(id, true, PackedVector2Array(), 0.0, c, true) # 흑성은 늘 보상 (대마법 게이지를 다 쓰므로)
	fx.targets = targets
	fx.stitch_only = stitch
	if not stitch:
		last_splash = {"id": id, "pos": c, "hits": targets.size(), "star": true}
	return targets.size()


## 시험용: 지금 떠 있는 틈 달이기 그림의 비용 (EPotionFx.brew_cost)
static func brew_cost() -> String:
	return EPotionFx.brew_cost()


## 반경 r 원에 맞히는 판정 사각형이 걸치는 살아 있는 표적들
static func in_radius(tree: SceneTree, pos: Vector2, r: float) -> Array:
	var out := []
	for d: Node2D in ETarget.alive(tree):
		var rc: Rect2 = d.hit_rect()
		var q := Vector2(clampf(pos.x, rc.position.x, rc.end.x), clampf(pos.y, rc.position.y, rc.end.y))
		if q.distance_to(pos) <= r:
			out.append(d)
	return out


## 꺾은선(틈) pts ± band 안에 판정 사각형이 걸치는 살아 있는 표적들
static func along(tree: SceneTree, pts: PackedVector2Array, band: float) -> Array:
	var out := []
	for d: Node2D in ETarget.alive(tree):
		if rect_to_line(d.hit_rect(), pts) <= band:
			out.append(d)
	return out


## 사각형과 꺾은선 사이 거리 (가운데에서 선으로, 다시 사각형 안 가장 가까운 점에서 선으로 — 두 번 맞추면 충분히 가깝다)
static func rect_to_line(rc: Rect2, pts: PackedVector2Array) -> float:
	if pts.size() < 2:
		return INF
	var q := closest_on(pts, rc.get_center())
	var r := Vector2(clampf(q.x, rc.position.x, rc.end.x), clampf(q.y, rc.position.y, rc.end.y))
	return closest_on(pts, r).distance_to(r)


## 꺾은선 위에서 p에 가장 가까운 점
static func closest_on(pts: PackedVector2Array, p: Vector2) -> Vector2:
	var best := pts[0] if pts.size() > 0 else p
	var best_d := INF
	for i in pts.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])
		var dd := q.distance_squared_to(p)
		if dd < best_d:
			best_d = dd
			best = q
	return best


# ═══════════════════════════════════════════════════════════
# 몸에 도는 물약 (버프)
# ═══════════════════════════════════════════════════════════

## 지금 걸린 물약들 [{id, left, dur, charges}] — 화면 표시용. 메아리처럼 횟수로 세는 것은 charges = true, left = 남은 횟수, dur = 처음 횟수
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
## 같은 물약을 또 마시면 시간(횟수)만 처음부터(겹치지 않음). 다른 물약끼리는 같이 걸린다(배수는 곱, 메아리는 큰 쪽, 포식은 작은 간격).
## 메아리는 시간이 아니라 횟수: 고급 마법이 나갈 때마다 하나씩 줄고(에스카가 mods.echo를 읽은 뒤), 0이 되면 풀린다.
## 포식은 한 번 마실 때 최대 feast_cap만큼 회복하면 풀린다. 쓰러지면 모두 풀리고 허리띠가 다시 가득 찬다 (design.md 4-2).
## 에스카(부모)가 먼저 움직인 뒤 이 노드가 돈다 — 그래서 같은 프레임에 나간 마법·회복을 바로 본다.
class Buffs extends Node2D:
	## 물약이 건드리는 mods 열쇠와 기본값 (나머지 열쇠는 건드리지 않는다)
	const BASE := {"size": 1.0, "cd_rate": 1.0, "speed": 1.0, "echo": 0.0, "leech": 0}
	var eska: EEska
	var list := {} ## id → {"left": 남은 초(또는 횟수), "dur": 처음 값, "eff": {mods 열쇠: 값}, "charges": 횟수로 세나}
	var feast_cap := 0 ## 포식: 이번에 마신 것으로 회복할 수 있는 최대
	var feast_got := 0 ## 포식: 이번에 회복한 양
	var _gap: Array[float] = [0.0, 0.0, 0.0] ## 칸마다 다시 마시기까지 남은 초
	var _hp_prev := 0
	var _cd_prev := {}
	var _fx_prev := 0
	var _cast_wait := false ## 고급 마법을 시작했고 아직 안 나감 (메아리 횟수를 나간 뒤에 줄이려고)

	func _ready() -> void:
		for icons: bool in [false, true]: # 몸 둘레 빛(가산, 몸 뒤) · 머리 위 시간 아이콘
			var v := EPotionFx.BuffView.new()
			v.buffs = self
			v.icons = icons
			add_child(v)
		if is_instance_valid(eska):
			_hp_prev = eska.hp
			_cd_prev = eska.cooldowns.duplicate()
			if not eska.died.is_connected(_on_died):
				eska.died.connect(_on_died)

	## 시간으로 풀리는 버프
	func add(id: String, dur: float, eff: Dictionary) -> void:
		list[id] = {"left": dur, "dur": dur, "eff": eff, "charges": false}
		_apply()

	## 횟수로 풀리는 버프 (메아리)
	func add_charges(id: String, n: int, eff: Dictionary) -> void:
		list[id] = {"left": float(n), "dur": float(n), "eff": eff, "charges": true}
		_apply()

	func clear() -> void:
		list.clear()
		_apply()

	func slot_wait(slot: int) -> float:
		return _gap[slot] if slot >= 0 and slot < _gap.size() else 0.0

	func hold_slot(slot: int, sec: float) -> void:
		if slot >= 0 and slot < _gap.size():
			_gap[slot] = sec

	## 지금 체력을 기준으로 삼음 (치유 물약 회복을 포식이 세지 않게)
	func sync_hp() -> void:
		if is_instance_valid(eska):
			_hp_prev = eska.hp

	func list_view() -> Array:
		var out := []
		for id: String in list:
			var e: Dictionary = list[id]
			out.append({"id": id, "left": float(e.left), "dur": float(e.dur), "charges": bool(e.charges)})
		return out

	func _physics_process(delta: float) -> void:
		for i in _gap.size():
			_gap[i] = maxf(_gap[i] - delta, 0.0)
		if not is_instance_valid(eska):
			return
		_watch_casts()
		_watch_feast()
		if list.is_empty():
			return
		var gone := false
		for id: String in list.keys():
			var e: Dictionary = list[id]
			if not bool(e.charges):
				e["left"] = float(e.left) - delta
			if float(e.left) <= 0.0:
				list.erase(id)
				gone = true
				Sfx.play_pitch(&"es_pot_no", 1.6, -16.0) # 풀리는 작은 소리
		if gone:
			_apply()

	## 메아리 횟수: 고급 마법이 시작되면(쿨다운이 새로 걸림) 기다렸다가, 실제로 나가면(fx_spawned 증가) 하나 줄인다.
	## 나가기 전에 끊기면(맞음) 줄이지 않는다. 메아리 자체(0.35초 뒤)는 시작 표시가 없으므로 세지 않는다
	func _watch_casts() -> void:
		var started := false
		for k: String in eska.cooldowns:
			if float(eska.cooldowns[k]) > float(_cd_prev.get(k, 0.0)) + 0.05:
				started = true
		_cd_prev = eska.cooldowns.duplicate()
		if started:
			_cast_wait = true
			_fx_prev = eska.fx_spawned
			return
		if not _cast_wait:
			return
		if eska.fx_spawned > _fx_prev:
			_cast_wait = false
			if list.has("echo"):
				var e: Dictionary = list["echo"]
				e["left"] = float(e.left) - 1.0
				EPotionFx.echo_tick(eska, int(e.left))
				if float(e.left) <= 0.0:
					list.erase("echo")
					_apply()
		elif eska.st != EEska.St.CAST:
			_cast_wait = false

	## 포식: 회복한 만큼 세다가 feast_cap이 되면 풀림
	func _watch_feast() -> void:
		var gain := eska.hp - _hp_prev
		_hp_prev = eska.hp
		if gain <= 0 or not list.has("feast"):
			return
		feast_got += gain
		if feast_got >= feast_cap:
			list.erase("feast")
			_apply()
			EPotionFx.drink_burst(eska, "feast") # 배가 찼다

	## 걸린 버프들로 mods를 처음부터 다시 계산
	func _apply() -> void:
		if not is_instance_valid(eska):
			return
		var m := BASE.duplicate()
		for id: String in list:
			var eff: Dictionary = list[id]["eff"]
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
		feast_got = 0
		_cast_wait = false
		for i in _gap.size():
			_gap[i] = 0.0
		eska.belt.refill()
