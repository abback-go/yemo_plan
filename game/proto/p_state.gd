class_name PState
extends RefCounted
## 훈련장 상태 — 시험 패널(Tab)로 바꾸는 값과 키 등록. 정적 변수라 어디서나 PState.tails 처럼 읽는다.

static var evade := true ## 회피술(공중 대시 + 무적) 배움
static var tails := 1 ## 1~9: 변신 시간·발톱 위력/사거리·집중 속도
static var mana_max := 3 ## 3~5
static var infinite_mana := false
static var no_cooldown := false
static var difficulty := 1 ## 0 쉬움 · 1 보통 · 2 어려움
static var launcher_on := false ## 연습용 발사대(맞는 연습: 방패·피격·집중 끊김)
static var damage_numbers := true
static var levels := {} ## 마법 ID → 레벨 (없으면 1)
static var show_keys := false


static func level(id: String) -> int:
	return int(levels.get(id, 1))


static func awakened(id: String) -> bool:
	return level(id) >= int(PData.spell(id).get("max_lv", 1))


static func focus_full_time() -> float:
	return PData.FOCUS_FULL_BASE - 0.125 * float(tails - 1) ## 3초 → 꼬리 9개 2초


static func transform_time() -> float:
	return PData.TRANSFORM_BASE + 0.625 * float(tails - 1) ## 10초 → 15초


static func claw_mult() -> float:
	return 1.0 + 0.06 * float(tails - 1)


## 키 등록 (데모 본편의 입력과 섞이지 않게 pr_ 접두사로 따로)
const KEYS := {
	"pr_left": [KEY_LEFT], "pr_right": [KEY_RIGHT], "pr_up": [KEY_UP], "pr_down": [KEY_DOWN],
	"pr_jump": [KEY_Z], "pr_claw": [KEY_X], "pr_dash": [KEY_C], "pr_focus": [KEY_V], "pr_mimic": [KEY_B],
	"pr_shield": [KEY_SHIFT], "pr_transform": [KEY_SPACE], "pr_potion": [KEY_G],
	"pr_s_fireball": [KEY_A], "pr_s_foxrain": [KEY_S], "pr_s_rising": [KEY_D], "pr_s_asura": [KEY_F],
	"pr_s_laser": [KEY_Q], "pr_s_meteor": [KEY_W], "pr_s_phoenix": [KEY_E], "pr_s_bind": [KEY_R],
	"pr_panel": [KEY_TAB], "pr_keys": [KEY_H], "pr_exit": [KEY_ESCAPE],
}


static func register_keys() -> void:
	for a: String in KEYS:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.2)
		InputMap.action_erase_events(a)
		for k: int in KEYS[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(a, ev)
