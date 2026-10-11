class_name EKeys
extends RefCounted
## 에스카 시제품 키 (본편·세라 시제품 입력과 섞이지 않게 es_ 접두사로 따로 등록).
## 방향키 이동 · Z 점프 · X 공격 · C 순간이동 · A 고급 마법(그냥 천열 · ↑+A 단공 · ↓+A 낙성)
## · S 대마법(종언 게이지가 가득일 때) · D 대마법 고르기 · F 물약(그냥 0칸 · ↑+F 1칸 · ↓+F 2칸)
## · 훈련장 시험: W 적 물결 켜기/끄기 · T 봉공 진화 켜기/끄기 · G 게이지 가득 · Esc 나가기
## 모바일은 ETouch가 같은 동작 이름을 보낸다.

const KEYS := {
	"es_left": [KEY_LEFT], "es_right": [KEY_RIGHT], "es_up": [KEY_UP], "es_down": [KEY_DOWN],
	"es_jump": [KEY_Z], "es_attack": [KEY_X], "es_blink": [KEY_C],
	"es_skill": [KEY_A], "es_bind": [KEY_S], "es_ult_next": [KEY_D], "es_potion": [KEY_F],
	"es_exit": [KEY_ESCAPE], "es_waves": [KEY_W], "es_still_t": [KEY_T], "es_gauge_fill": [KEY_G],
}


## 지금 터치로 하고 있나 (ETouch가 켜고 끈다) — 안내 글이 입력 방식에 맞춰 바뀐다
static var touch_mode := false

## 키보드 이름 / 터치 버튼 이름
const LABELS := {
	"es_jump": ["Z", "점프"], "es_attack": ["X", "공격"], "es_blink": ["C", "순간"],
	"es_skill": ["A", "스킬"], "es_bind": ["S", "대마법"], "es_ult_next": ["D", "고르기"], "es_potion": ["F", "물약"],
	"es_up": ["↑", "↑"], "es_down": ["↓", "↓"], "es_left": ["←", "←"], "es_right": ["→", "→"],
}


## 동작 이름 → 지금 입력 방식에 맞는 이름 (loop4_plan 2장)
static func label(action: String) -> String:
	if not LABELS.has(action):
		return action
	return String(LABELS[action][1 if touch_mode else 0])


## 방향 + 동작 이름 (예: 키보드 "↓+A" · 터치 "↓+스킬")
static func with_dir(dir_action: String, action: String) -> String:
	return label(dir_action) + "+" + label(action)


## 글 안의 {es_동작} 자리를 지금 입력 방식의 이름으로 바꾼다 (장면 안내·안내판이 씀). 예: "{es_up}+{es_skill} 단공"
static func fmt(text: String) -> String:
	if not text.contains("{"):
		return text
	var out := text
	for a: String in LABELS:
		out = out.replace("{" + a + "}", label(a))
	return out


static func register() -> void:
	for a: String in KEYS:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.2)
		InputMap.action_erase_events(a)
		for k: int in KEYS[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(a, ev)
