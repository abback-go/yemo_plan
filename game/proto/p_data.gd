class_name PData
extends RefCounted
## 전투 시제품(훈련장) 수치·마법 표 — docs/design/controls_skills.md 의 결정을 그대로 옮긴 것.
## 조작감 수치는 여기 한 곳에서 고친다(px 단위, 1타일 = 16px). 시험 패널(Tab)로 바꾸는 값은 PState에 있다.

const T := 16.0

# ─── 이동 (할로우 나이트 느낌: 가속 거의 없이 바로 최고 속도, 강한 중력, 가변 점프) ───
const RUN_SPEED := 150.0 ## 달리기 (약 9.4타일/초)
const RUN_ACCEL := 2400.0 ## 거의 즉시 최고 속도
const RUN_DECEL := 3000.0
const AIR_ACCEL := 1900.0
const GRAVITY := 1350.0
const FALL_MAX := 330.0
const FAST_FALL_MAX := 430.0 ## 공중에서 ↓를 누르고 있으면
const JUMP_SPEED := 365.0 ## 최대 높이 약 3.1타일(꾹 누르면 약 4.9타일 — 아래 HOLD 참고)
const JUMP_HOLD_TIME := 0.20 ## 누르고 있는 동안 중력 약하게 → 길게 = 높게
const JUMP_HOLD_GRAVITY := 0.42
const JUMP_CUT := 0.45 ## 일찍 떼면 위 속도에 곱함
const APEX_HANG := 0.55 ## 꼭짓점 근처 중력 배율(살짝 떠 있는 느낌)
const COYOTE := 0.09
const JUMP_BUFFER := 0.12
const DOUBLE_JUMP_SPEED := 330.0

const DASH_SPEED := 420.0
const DASH_TIME := 0.17 ## 약 4.5타일
const DASH_COOLDOWN := 0.38
const DASH_IFRAME := 0.17 ## 회피술을 배운 뒤에만

const WALL_SLIDE := 70.0 ## 벽에 붙으면 천천히 미끄러짐
const WALL_JUMP_X := 190.0
const WALL_JUMP_Y := 330.0
const WALL_JUMP_LOCK := 0.14 ## 벽 점프 직후 방향 입력을 잠깐 무시(같은 벽으로 바로 붙지 않게)

const GLIDE_FALL := 45.0
const GLIDE_SPEED := 165.0

const MIMIC_SPEED := 520.0 ## 의태 돌진 = 변신 중 대시 (거대 여우 정령, 관통·피해·무적, 대시와 같은 간격)
const MIMIC_TIME := 0.24 ## 약 7.8타일
const MIMIC_DAMAGE := 18

# ─── 발톱 (같은 위력 3연타, 모션만 바뀜) ───
const CLAW_COOLDOWN := 0.26
const CLAW_COOLDOWN_FOX := 0.18
const CLAW_ACTIVE := 0.07
const CLAW_DAMAGE := 21
const CLAW_REACH := 45.0 ## 앞으로 (꼬리마다 +2.25) — 사용자 요청으로 1.5배
const CLAW_HEIGHT := 26.0
const CLAW_RECOIL := 120.0 ## 맞히면 세라가 뒤로 조금
const CLAW_HITSTOP := 0.045
const CLAW_GAUGE := 0.075 ## 맞힐 때마다 변신 게이지

# ─── 생존 ───
const MAX_HEARTS := 5
const HURT_IFRAME := 1.0
const HURT_KNOCK := Vector2(150, -170)
const SHIELD_TIME := 1.5 ## 거대 여우 정령이 방패로 앞을 막는 시간(무적)
const SHIELD_COOLDOWN := 3.0 ## 할퀴기까지 끝난 뒤부터
const SHIELD_SWIPE_BASE := 40.0 ## 방패를 내린 뒤 정령 할퀴기 기본 피해
const SHIELD_SWIPE_PER_HEART := 45.0 ## 막은 피해 1칸마다 더하는 피해
const POTION_HEAL := 2
const POTION_TIME := 0.8

# ─── 집중·마나 ───
const FOCUS_FULL_BASE := 3.0 ## 3칸이 차는 시간(꼬리 9개면 약 2초)
const FOX_MANA_REGEN := 4.0 ## 변신 중 저절로 1칸 차는 시간

# ─── 변신 ───
const TRANSFORM_BASE := 10.0 ## 꼬리 1개 10초 → 9개 15초
const FOX_DAMAGE := 1.3

## 마법 7종 (초급 2 · 중급 3 · 대마법 2) — 키·소모 칸·쿨·레벨 상한·이름. 피해는 각 마법 함수가 레벨 배율을 곱해 쓴다.
const SPELLS := [
	{"id": "fireball", "name": "파이어볼", "key": "A", "cost": 1, "cd": 1.2, "max_lv": 4, "line": "fire", "grade": "초급"},
	{"id": "foxrain", "name": "여우비", "key": "S", "cost": 1, "cd": 1.6, "max_lv": 4, "line": "fox", "grade": "초급"},
	{"id": "asura", "name": "여우불 발톱 난무", "key": "F", "cost": 2, "cd": 7.0, "max_lv": 3, "line": "fox", "grade": "중급"},
	{"id": "laser", "name": "압축 열선", "key": "Q", "cost": 2, "cd": 6.0, "max_lv": 3, "line": "fire", "grade": "중급"},
	{"id": "meteor", "name": "대유성", "key": "W", "cost": 2, "cd": 8.0, "max_lv": 3, "line": "fire", "grade": "중급"},
	{"id": "phoenix", "name": "불사조", "key": "E", "cost": 3, "cd": 55.0, "max_lv": 2, "line": "fire", "grade": "대마법"},
	{"id": "bind", "name": "너울 바인드", "key": "R", "cost": 3, "cd": 50.0, "max_lv": 2, "line": "fox", "grade": "대마법"},
]


static func spell(id: String) -> Dictionary:
	for s: Dictionary in SPELLS:
		if s.id == id:
			return s
	return {}


## 레벨 피해 배율 (Lv마다 +20%)
static func lv_mult(lv: int) -> float:
	return 1.0 + 0.2 * float(lv - 1)


# ─── 색 (불 = 붉은 마녀 불 / 여우불 = 푸른 불) ───
const FIRE_CORE := Color(1.0, 0.97, 0.82)
const FIRE_HOT := Color(1.0, 0.82, 0.32)
const FIRE_MID := Color(1.0, 0.5, 0.12)
const FIRE_DARK := Color(0.78, 0.18, 0.06)
const FOX_CORE := Color(0.92, 0.98, 1.0)
const FOX_HOT := Color(0.62, 0.9, 1.0)
const FOX_MID := Color(0.3, 0.62, 1.0)
const FOX_DARK := Color(0.16, 0.26, 0.82)
