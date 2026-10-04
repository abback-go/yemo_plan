class_name PState
extends RefCounted
## 훈련장 상태 — 시험 패널(Tab)로 바꾸는 값과 키 등록. 정적 변수라 어디서나 PState.tails 처럼 읽는다.

static var evade := true ## 회피술(공중 대시 + 무적) 배움
static var tails := 1 ## 1~9: 변신 시간·발톱 위력/사거리
static var od_mult := 1.0 ## 폭주 게이지 차는 배율 (시험용)
static var cd_potions := 0 ## 연금술 '쿨 감소' 물약 수 0~2 (−10%씩)
static var no_cooldown := false
static var difficulty := 1 ## 0 쉬움 · 1 보통 · 2 어려움
static var launcher_on := false ## 연습용 발사대(맞는 연습: 피격·대시 무적)
static var damage_numbers := true
static var levels := {} ## 마법 ID → 레벨 (없으면 1)
static var show_keys := false


static func level(id: String) -> int:
	return int(levels.get(id, 1))


static func awakened(id: String) -> bool:
	return level(id) >= int(PData.spell(id).get("max_lv", 1))


## 마법 쿨타임 (연금술 물약 하나마다 −10%)
static func spell_cd(id: String) -> float:
	return float(PData.spell(id).get("cd", 1.0)) * (1.0 - 0.1 * float(cd_potions))


static func transform_time() -> float:
	return PData.TRANSFORM_BASE + 0.625 * float(tails - 1) ## 10초 → 15초


static func claw_mult() -> float:
	return 1.0 + 0.06 * float(tails - 1)


## 키 방식 (시험 패널에서 바꿈)
##   0 = 등급 키: A 초급 · S 중급 · D 대마법 + 누르는 순간의 방향(중립·↑·↓)으로 마법을 고름. C 대시
##   1 = 전용 키: 마법마다 한 키(A S F Q W E R). Shift 대시
static var key_mode := 0

## 등급 키 → {방향: 마법 ID}. 그 방향에 마법이 없으면 중립 마법
const GRADE_KEYS := {
	"pr_g1": {"mid": "fireball", "down": "foxrain"},
	"pr_g2": {"mid": "laser", "up": "meteor", "down": "asura"},
	"pr_g3": {"mid": "bind", "up": "phoenix"},
}
const GRADE_LETTER := {"pr_g1": "A", "pr_g2": "S", "pr_g3": "D"}

## 키 등록 (데모 본편의 입력과 섞이지 않게 pr_ 접두사로 따로)
const KEYS_COMMON := {
	"pr_left": [KEY_LEFT], "pr_right": [KEY_RIGHT], "pr_up": [KEY_UP], "pr_down": [KEY_DOWN],
	"pr_jump": [KEY_Z], "pr_claw": [KEY_X], "pr_transform": [KEY_SPACE], "pr_potion": [KEY_G],
	"pr_panel": [KEY_TAB], "pr_keys": [KEY_H], "pr_exit": [KEY_ESCAPE],
}
const KEYS_GRADE := {
	"pr_dash": [KEY_C], "pr_g1": [KEY_A], "pr_g2": [KEY_S], "pr_g3": [KEY_D],
}
const KEYS_DIRECT := {
	"pr_dash": [KEY_SHIFT],
	"pr_s_fireball": [KEY_A], "pr_s_foxrain": [KEY_S], "pr_s_asura": [KEY_F],
	"pr_s_laser": [KEY_Q], "pr_s_meteor": [KEY_W], "pr_s_phoenix": [KEY_E], "pr_s_bind": [KEY_R],
}


## 지금 키 방식으로 다시 등록. 다른 방식의 동작 이름도 만들어 두되 키는 비운다(어디서 읽어도 오류 없게).
static func register_keys() -> void:
	var cur: Dictionary = KEYS_COMMON.duplicate()
	cur.merge(KEYS_GRADE if key_mode == 0 else KEYS_DIRECT)
	var all: Dictionary = KEYS_COMMON.duplicate()
	all.merge(KEYS_GRADE)
	all.merge(KEYS_DIRECT)
	for a: String in all:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.2)
		InputMap.action_erase_events(a)
		for k: int in cur.get(a, []):
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(a, ev)


## 이번 프레임에 누른 마법 ID (없으면 ""). 등급 키는 누르는 순간의 ↑·↓로 고른다.
static func spell_pressed() -> String:
	if key_mode == 0:
		for a: String in GRADE_KEYS:
			if Input.is_action_just_pressed(a):
				var m: Dictionary = GRADE_KEYS[a]
				var dir := "up" if Input.is_action_pressed("pr_up") else ("down" if Input.is_action_pressed("pr_down") else "mid")
				return String(m.get(dir, m["mid"]))
		return ""
	for s: Dictionary in PData.SPELLS:
		if Input.is_action_just_pressed("pr_s_" + String(s.id)):
			return String(s.id)
	return ""


## 그 마법을 쥐고 있는 동작 이름 (열선처럼 꾹 누르는 마법이 손을 뗐는지 볼 때)
static func spell_action(id: String) -> String:
	if key_mode == 0:
		for a: String in GRADE_KEYS:
			if (GRADE_KEYS[a] as Dictionary).values().has(id):
				return a
	return "pr_s_" + id


## 퀵슬롯에 쓰는 키 글자 (등급 키면 "↑S"처럼 방향 + 글자)
static func spell_label(id: String) -> String:
	if key_mode == 0:
		for a: String in GRADE_KEYS:
			var m: Dictionary = GRADE_KEYS[a]
			for dir: String in m:
				if m[dir] == id:
					return {"mid": "", "up": "↑", "down": "↓"}[dir] + String(GRADE_LETTER[a])
	return String(PData.spell(id).get("key", ""))
