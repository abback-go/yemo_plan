class_name Tuning
## 손맛 프로토타입 수치. 기획서 docs/gdd/05-mechanics.md 파라미터 표와 같은 값이다 — 바꾸면 기획서도 같이 고친다.
## 길이 단위는 px (1타일 = 16px), 시간 단위는 초.

const TILE := 16.0

# ── 이동 (M-01) ──
const RUN_SPEED := 130.0 ## 최고 속도 (px/s)
const ACCEL_TIME := 0.08 ## 멈춤 → 최고 속도까지 걸리는 시간
const DECEL_TIME := 0.06 ## 최고 속도 → 멈춤까지 걸리는 시간
const AIR_CONTROL := 0.85 ## 공중에서 가감속 배수

# ── 점프 (M-02) ──
const JUMP_HEIGHT := 52.0 ## 최대 점프 높이 (3.25타일)
const JUMP_APEX_TIME := 0.34 ## 정점까지 걸리는 시간
const FALL_GRAVITY_MULT := 1.7 ## 떨어질 때 중력 배수 (빨리 떨어져야 묵직하다)
const JUMP_CUT := 0.45 ## 점프 버튼을 일찍 떼면 오르는 속도에 곱하는 값 (가변 점프)
const MAX_FALL_SPEED := 420.0
const COYOTE_TIME := 0.10 ## 발판을 벗어난 뒤에도 점프를 받아주는 시간
const JUMP_BUFFER := 0.12 ## 착지 직전에 누른 점프를 기억하는 시간

# ── 검술 (M-04) ──
## 휘두름 한 번 = 준비(wu) → 휘두름(sw, 절반 지점에서 한 번 판정) → 거둠(rec).
## lunge = 휘두르는 순간 앞으로 미끄러지는 빠르기, hs = 히트스톱, shake = 화면 흔들림(px), kb = 적이 밀려나는 빠르기.
## reach·height = 판정 범위, r·w·a0·a1·sq·rot = 참격 그림 (반지름·두께·시작각·끝각·납작함·기울기).
## 시간 값은 에스카 빗자루 검 데모(cc/vigilant-dirac-751x7b, game/proto/blade/b_eska.gd)를 참고했다.
const SWINGS := {
	"s1": {"wu": 0.04, "sw": 0.05, "rec": 0.16, "dmg": 20, "lunge": 110.0, "hs": 0.05, "shake": 2.0, "kb": 70.0,
		"reach": 34.0, "height": 26.0, "r": 26.0, "w": 9.0, "a0": 175.0, "a1": 365.0, "sq": 0.32, "rot": 38.0},
	"s2": {"wu": 0.035, "sw": 0.05, "rec": 0.16, "dmg": 20, "lunge": 100.0, "hs": 0.05, "shake": 2.0, "kb": 70.0,
		"reach": 34.0, "height": 26.0, "r": 26.0, "w": 9.0, "a0": 185.0, "a1": -5.0, "sq": 0.32, "rot": -38.0},
	"s3": {"wu": 0.09, "sw": 0.06, "rec": 0.30, "dmg": 45, "lunge": 170.0, "hs": 0.09, "shake": 4.0, "kb": 150.0,
		"reach": 46.0, "height": 34.0, "r": 38.0, "w": 13.0, "a0": 172.0, "a1": 372.0, "sq": 0.32, "rot": 32.0, "heavy": true},
	"air1": {"wu": 0.035, "sw": 0.05, "rec": 0.14, "dmg": 20, "lunge": 0.0, "hs": 0.05, "shake": 2.0, "kb": 60.0,
		"reach": 32.0, "height": 28.0, "r": 24.0, "w": 8.0, "a0": 175.0, "a1": 365.0, "sq": 0.35, "rot": 40.0, "air": true},
	"air2": {"wu": 0.035, "sw": 0.05, "rec": 0.18, "dmg": 20, "lunge": 0.0, "hs": 0.05, "shake": 2.0, "kb": 60.0,
		"reach": 32.0, "height": 28.0, "r": 24.0, "w": 8.0, "a0": 185.0, "a1": -5.0, "sq": 0.35, "rot": -40.0, "air": true},
}
const COMBO := ["s1", "s2", "s3"] ## 땅 위 3연격
const AIR_COMBO := ["air1", "air2"] ## 공중 2연격 (착지하면 다시 쓸 수 있다)
const ATTACK_BUFFER := 0.15 ## 휘두르는 중에 누른 공격을 기억하는 시간
const CHAIN_AFTER := 0.04 ## 거둠이 시작되고 이만큼 뒤부터 다음 휘두름·점프로 끊을 수 있다
const COMBO_GAP := 0.4 ## 거둠이 끝나고 이 시간 안에 다시 누르면 연격이 이어진다
const LUNGE_DECEL := 1800.0 ## 앞으로 미끄러지는 힘이 줄어드는 빠르기 (px/s²)
const SPACING := 20.0 ## 미끄러질 때 앞 표적과 이만큼은 떨어져 멈춘다
const AIR_SWING_FALL := 60.0 ## 공중에서 휘두르는 동안 떨어지는 속도 상한 (잠깐 떠 있는 느낌)

# ── 허수아비 (적 1종, M-07 피격 시험용) ──
const DUMMY_HP := 300
const DUMMY_REGEN_DELAY := 2.0 ## 이 시간 동안 안 맞으면 체력이 다시 찬다
const DUMMY_FLASH := 0.08 ## 맞았을 때 하얗게 번쩍이는 시간
