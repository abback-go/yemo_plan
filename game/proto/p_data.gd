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

# ─── 기본공격 X = 불덩이 던지기 (사이퍼즈 타라 '홍염화' 느낌, 같은 위력 3연타: 오른손 · 왼손 · 두 손 큰 덩이) ───
## 간격·피해·게이지는 옛 발톱과 같다. 크기·사거리·폭발 반경은 꼬리 수(= 기본공격 레벨 1~9)에 따라 커진다.
const SHOT_COOLDOWN := 0.26
const SHOT_COOLDOWN_FOX := 0.18
const SHOT_DAMAGE := 21
const SHOT_SPEED := 560.0
const SHOT_RANGE := 300.0 ## 화면 절반쯤 (꼬리마다 +6)
const SHOT_RADIUS := 6.0 ## 불덩이 반지름 (3타 ×1.5, 꼬리마다 +9%)
const SHOT_BLAST := 15.0 ## 맞으면 작은 폭발 반경 (3타 ×1.5)
const SHOT_HITSTOP := 0.045 ## 3타는 0.075
const SHOT_RECOIL := 70.0 ## 3타(두 손) 던질 때 뒤로 살짝 밀림

# ─── 생존 ───
const MAX_HEARTS := 5
const HURT_IFRAME := 1.0
const HURT_KNOCK := Vector2(150, -170)
const SHIELD_TIME := 1.5 ## 거대 여우 정령이 방패로 앞을 막는 시간(무적)
const SHIELD_COOLDOWN := 3.0 ## 할퀴기까지 끝난 뒤부터
const SHIELD_SWIPE_BASE := 40.0 ## 방패를 내린 뒤 정령 할퀴기 기본 피해
const SHIELD_SWIPE_PER_HEART := 45.0 ## 막은 피해 1칸마다 더하는 피해
const POTION_HEAL := 2
const REVIVE_HEARTS := 1 ## 불사조 부활: 하트 1칸 (각성 2칸)
const REVIVE_HEARTS_AWAKE := 2
const POTION_TIME := 0.8

# ─── 폭주 게이지 (마나 없음 — 마법은 쿨타임만. 넘치는 마력이 차오르고, 가득 차면 Space로 너울에게 넘겨 변신) ───
## 게이지 0~1. 싸워야만 찬다(시간·피격으로는 차지 않음). 가득 차면 변신 전까지 마법 봉인(기본공격·대시는 됨) — 아껴 둘 수는 있지만 마법을 포기하는 대가. 변신 연장·반동 없음
const OD_SPELL := {"초급": 0.03, "중급": 0.08, "대마법": 0.15} ## 마법을 쓸 때
const OD_SHOT := 0.005 ## 기본공격 적중 한 번 (맞은 대상마다)
const OD_EASY := 1.3 ## 쉬움 난이도 배율

# ─── 변신 ───
const TRANSFORM_BASE := 10.0 ## 꼬리 1개 10초 → 9개 15초
const FOX_DAMAGE := 1.3

## 마법 6종 (초급 2 · 중급 2 · 대마법 2) — 키·쿨·레벨 상한·이름. 마나 없음: 제약은 쿨타임(연금술 물약으로 −10%씩). 피해는 각 마법 함수가 레벨 배율을 곱해 쓴다.
const SPELLS := [
	{"id": "fireball", "name": "파이어볼", "key": "A", "cd": 3.0, "max_lv": 4, "line": "fire", "grade": "초급"},
	{"id": "foxrain", "name": "불비", "key": "S", "cd": 10.0, "max_lv": 4, "line": "fire", "grade": "초급"}, ## 변신 중 = 푸른 여우비
	{"id": "laser", "name": "압축 열선", "key": "Q", "cd": 20.0, "max_lv": 3, "line": "fire", "grade": "중급"},
	{"id": "meteor", "name": "대유성", "key": "W", "cd": 30.0, "max_lv": 3, "line": "fire", "grade": "중급"},
	{"id": "phoenix", "name": "불사조", "key": "E", "cd": 90.0, "max_lv": 2, "line": "fire", "grade": "대마법"},
	{"id": "bind", "name": "너울 바인드", "key": "R", "cd": 90.0, "max_lv": 2, "line": "fire", "grade": "대마법"}, ## 평소 = 붉은 불 여우 정령, 변신 중 = 푸른 아홉 꼬리 여우신
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
