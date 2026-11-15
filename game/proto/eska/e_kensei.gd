class_name EKensei
extends EEnemy
## 검성(劍聖) — 마지막 강자, 인간 규모 보스 (기준서 docs/eska/design.md 6장).
## 말이 없는 정통 검의 달인: 고요히 서 있다가 한순간에 베고, 칼을 거둔 뒤에야 참격선이 터진다.
## 1막(체력 100~55%, 칼은 칼집 안 — 발도술):
##   발도 일섬(웅크려 칼자루에 손 → 칼코등이 번뜩 → 300px 일섬, 칼을 거두면 한 박자 뒤 참격선이 터지며 피해 2 — 순간이동 무적·점프로 피함)
##   · 삼연참(다가오며 세 번, 매번 번뜩임) · 비검(땅을 타는 참격파, 점프) · 반격 자세(눈을 감고 서 있을 때 때리면 사라져 뒤에서 벰 — 비명 물약으로 깸)
## 막 전환(55%): 잠깐 멈춤 → 칼을 다 뽑고 칼집을 내던짐 → 이름 자막·음악 바뀜·기운
## 2막: 빨라짐 + 낙화(뛰어올라 내리꽂기, 착지 충격) + 천검(하늘에서 칼빛 여러 줄 — 땅에 예고) + 연계 · 공간 고정을 일부 버팀(still_resist 0.25)
##   + 그림자 일섬(loop5 1장): 칼을 거두면 먹빛 잔상 분신 셋이 에스카 자리에 한 줄로 서서 1.6초 자세 → 분신마다 늦게 터지는 일섬선(피해 1).
##     분신(EKensei.Shadow)은 표적(체력 1200, 버팀·넉백 없음) — 베어 없애면 그 일섬은 사라지고 검성 버팀 −500. 일섬선은 단공으로 가를 수 있음(es_projectile).
##     loop6: 분신이 서 있는 동안 검성은 먹물 속(무적 — 맞으면 "무효"). 살아 돌아간 분신마다 검성 버팀 +800(먹이 스며듦),
##     셋 다 베면 즉시 버팀 붕괴(무릎 2초) + 종언 게이지 +15%.
## 버팀(포이즈, POISE): 무너지면 2초 무릎 꿇음 + 받는 피해 +25% (대마법을 넣을 기회) — EEnemy 버팀 갈고리 사용.
## 공정함: 모든 공격은 자세 + 번뜩임 + 소리로 미리 알리고, 끝나면 반격할 틈(숨 고르기)이 있다.
## 그림: 길게 묶은 흰 머리 · 바람에 날리는 검은 겉옷 자락 · 서양식 철 견갑 한쪽 · 붉은 끈의 긴 칼 (먹·뼈흰·붉은 끈, 파랑 없음).
## 장면(EBossStage)이 begin()으로 싸움을 열고, phase_changed·died 신호로 연출을 맞춘다.

signal phase_changed(p: int) ## 2막이 됨 (칼을 다 뽑은 순간)
signal phase_starting ## 막 전환 연출이 시작됨
signal move_started(id: String) ## 기술을 시작함 (장면의 첫 만남 배움 연출)

enum S { INTRO, IDLE, WALK, IAI_WIND, IAI_DASH, IAI_FOLLOW, IAI_SHEATHE, IAI_REST,
	TRI_WIND, TRI_CUT, TRI_REST, WAVE_WIND, WAVE_CUT, WAVE_REST,
	CTR_STANCE, CTR_VANISH, CTR_WIND, CTR_CUT, CTR_RELAX,
	PHASE, LEAP_WIND, LEAP_UP, LEAP_HANG, LEAP_FALL, LEAP_REST,
	RAIN_WIND, RAIN_HOLD, RAIN_REST, VICTOR,
	SHADOW_WIND, SHADOW_HOLD, SHADOW_REST }

# ─── 몸·체력 ─────────────────────────────────────────────
## 봇으로 맞춤 (tools/test/eska_boss_bot.gd — 마법·물약·대마법·틈 달이기·단공 딱 맞춤 모두 사용, FRAME_CLOCK=1):
## 루프3: 48000·3600 → 52000·5400. 루프5(그림자 일섬 + 분신 900 + 합친 마법·물약)에서 52000은 서툰 판이 길어져(쓰러짐 1~4번)
## 50000으로: 잘함 116~140초·무너짐 4~5번·분신 약 40% 벰, 서툼 124~155초(씨앗 2는 어느 체력에서나 쓰러짐 2번·약 330초)
## 루프6(분신 1200·먹물 무적·버팀 +800/셋 다 베면 무너짐·첫 만남 배움): 그대로 50000 — 잘함 129~151초·무너짐 5~6번·분신 4~6/6 벰, 서툼 149초(쓰러지면 305초)
## 루프7(배움 다섯 기술·무시 비용 게이지 −5%·흑성 처방): 50000이면 잘함 150~162초로 길어져 45000 — 잘함 122~149초·무너짐 5번·분신 절반 벰, 서툼 144~166초(쓰러지면 268초)
## 루프8(첫 도전 개막 순서 고정·2막 확인점·봉공 처방): 45000이면 잘함 137~160초 → 42000 — 잘함 131~141초·무너짐 3~5번, 서툼 145~210초·쓰러짐 0~1
const HP := 42000
const POISE := 5400.0
const HOLD_CAP := 2.5 ## 한 번에 묶이거나 기절하는 최대 시간 (틈에 스민 진한 속박 4.5초 → 2.5초 — EEnemy.hold_cap)
const PHASE2_AT := 0.55 ## 체력이 이 몫 아래로 내려가면 2막
const STILL_RESIST_P2 := 0.25
const BODY := Vector2(16, 50) ## 피격 사각형 (에스카 30 — 모자 포함 약 45 — 보다 머리 하나 큼)
const BLADE_L := 36.0 ## 긴 태도
const SAYA_L := 34.0
const HIP_Y := -24.0 ## 서 있을 때 허리 높이
const TORSO := 14.0 ## 허리 → 어깨
const ARM_A := 9.0
const ARM_B := 9.0
const LEG_A := 12.5
const LEG_B := 12.5
const HAIR_N := 9
const HAIR_SEG := 2.9
const TAIL_N := 10
const TAIL_SEG := 3.7
const TRAIL_MIN := 7.0 ## 칼끝이 한 프레임에 이만큼 넘게 움직일 때만 붉은 잔광 (천천히 거둘 땐 없음)
const WALK_V := 52.0
const IDLE_T := [Vector2(0.8, 1.2), Vector2(0.45, 0.8)] ## 다음 기술까지 쉬는 시간 (1막, 2막)
const COMBO_CHANCE := 0.45 ## 2막: 숨 고르기를 건너뛰고 바로 다음 기술로 이어 갈 확률
const COMBO_IDLE := 0.14

# ─── 발도 일섬 ───────────────────────────────────────────
const IAI_WIND := [0.62, 0.5]
const IAI_GLINT := 0.4 ## 베기 이만큼 전에 칼코등이가 번뜩임 (피할 신호 — loop4 0.2 → 0.3, loop5 0.4: 번뜩임을 보고 점프해도 됨)
const IAI_MIN := 160.0
const IAI_MAX := 340.0
const IAI_PAST := 70.0 ## 에스카를 지나 이만큼 더 가서 멈춤
const IAI_DASH_T := 0.07
const IAI_FOLLOW_T := 0.16
const IAI_SHEATHE_T := 0.38
const IAI_BURST := 0.12 ## 칼을 거둔 뒤 참격선이 터지기까지
const IAI_REST := [0.75, 0.55]
const IAI_BAND := Vector2(-27.0, -2.0) ## 베는 높이 (발 기준 위·아래) — 점프로 넘을 수 있게 낮게
const IAI_DMG := 2
const IAI_RETURN := 0.35 ## 2막: 되돌아 한 번 더 베는 확률
const IAI_RETURN_WIND := 0.55 ## 2막 되돌아 베기의 웅크림 (loop4: 0.42는 번뜩임 뒤 실제 창이 0.07초뿐이었음)
const IAI_DIM_LEAD := 0.55 ## 베기 이만큼 전부터 화면이 살짝 어두워지기 시작 (번뜩임 때 가장 어두움)
const DIM_IN := 5.0 ## 어두워지는 빠르기 (초당)
const DIM_OUT := 3.0 ## 밝아지는 빠르기

# ─── 삼연참 ─────────────────────────────────────────────
const TRI_WIND := [0.45, 0.38]
const TRI_GAP := [0.32, 0.26] ## 베기 사이 (다음 베기 0.1초 전에 번뜩임)
const TRI_STEP := [26.0, 26.0, 36.0]
const TRI_REACH := [54.0, 54.0, 66.0]
const TRI_REST := [0.75, 0.6]
const TRI_DMG := 1
const TRI_H := 40.0 ## 삼연참 베는 높이 (발 기준 위로) — 점프 한 번(약 46px)으로 넘을 수 있게 (예전 48)
const TRI_ARC_Y := -21.0 ## 삼연참 칼자국 가운데 높이 (판정 높이에 맞춰 조금 낮춤)
const TRI_ARC_SQUASH := 0.62 ## 삼연참 칼자국 세로 납작함 (판정 위 끝과 그림 위 끝이 맞게)
const CUT_H := 48.0 ## 그 밖의 앞 베기(반격) 높이
const CUT_ARC_Y := -24.0
const CUT_ARC_SQUASH := 0.7

# ─── 비검 ───────────────────────────────────────────────
const WAVE_WIND := [0.55, 0.45]
const WAVE_SPEED := [230.0, 270.0]
const WAVE_SECOND := 0.55 ## 2막: 두 번째 파도까지 (loop5: 0.4 → 0.55, 둘째 파도에도 번뜩임·소리)
const WAVE_SECOND_TELL := 0.18 ## 둘째 파도 이만큼 전에 번뜩임
const WAVE_REST := [0.7, 0.5]

# ─── 반격 자세 ───────────────────────────────────────────
const CTR_HOLD := [1.3, 1.1]
const CTR_BEHIND := 34.0
const CTR_VANISH_T := 0.2
const CTR_WIND := [0.36, 0.3]
const CTR_REACH := 62.0
const CTR_RELAX := 0.6
const CTR_COOL := 4.0
const CTR_GRACE := 0.3 ## 자세를 잡고 고리가 다 그려지기까지 — 이 사이에 들어온 타격(이미 날린 천열 등)은 그냥 맞는다
const CTR_DMG := 1
const CTR_RING_R := 52.0 ## 반격 자세 발밑 고리 반지름 (다 조여든 크기 — 예전 30)
const CTR_RING_FROM := 16.0 ## 고리가 이만큼 더 크게 시작해 조여듦
const CTR_GUARD := Vector2(24.0, 36.0) ## 몸을 두른 세운 타원 (가로·세로 반지름) — "지금 때리면 받아친다"
const CTR_GUARD_Y := -26.0 ## 타원 가운데 높이 (발 기준)
const CTR_GUARD_ARCS := 4 ## 타원을 도는 끊긴 호 수

# ─── 막 전환 ─────────────────────────────────────────────
const PHASE_T := 3.0
const PHASE_DRAW_AT := 1.4 ## 칼을 다 뽑고 칼집을 던지는 때

# ─── 낙화 (2막) ──────────────────────────────────────────
const LEAP_WIND := 0.4
const LEAP_VY := -560.0
const LEAP_G := 980.0
const LEAP_HANG := 0.45
const LEAP_LOCK := 0.3 ## 내리꽂기 이만큼 전에 표식이 멈춤 (멈춘 뒤 떨어지기까지 약 0.5초 — 걸어서 빠져나갈 수 있게)
const LEAP_FALL_V := 820.0
const LEAP_CORE := 22.0 ## 가운데: 피해 2
const LEAP_REACH := 66.0 ## 충격파: 땅에 있으면 피해 1 (점프로도 피함)
const LEAP_REST := 0.9

# ─── 천검 (2막) ──────────────────────────────────────────
const RAIN_WIND := 0.6
const RAIN_N := 7
const RAIN_GAP := 62.0 ## 칼빛 사이 (칼빛 폭 12 → 50px 빈틈)
const RAIN_WARN := 0.75
const RAIN_STAGGER := 0.09
const RAIN_HOLD := 0.5
const RAIN_REST := 0.6
const RAIN_COOL := 8.0
const RAIN_TWICE_BELOW := 0.3 ## 체력이 이 몫 아래면 두 번째 줄(반 칸 어긋남)

# ─── 그림자 일섬 (2막, loop5 1장) ───────────────────────────
const SHADOW_WIND := 0.4 ## 칼을 거두며 웅크림 → 분신이 나타남
const SHADOW_N := 3
const SHADOW_GAP := 70.0 ## 분신 사이 (한 줄)
const SHADOW_STAGGER := 0.12 ## 분신마다 이만큼 늦게 나타나고 늦게 벤다
const SHADOW_HOLD := 2.5 ## 분신이 나온 뒤 검성이 지켜보는 시간 (분신 자세 1.6 + 터짐 0.45 + 여유) — 분신이 묶여 늦어지면 SHADOW_HOLD_MAX까지 기다림
const SHADOW_HOLD_MAX := 5.0
const SHADOW_RETURN_POISE := 800.0 ## 살아 돌아간 분신마다 검성 버팀 회복 (loop6: 무시하면 손해)
const SHADOW_ALL_GAUGE := 0.15 ## 셋 다 베면 종언 게이지 + 가득의 이 몫 (loop6: 풀면 크게 이득)
const SHADOW_RETURN_GAUGE := 0.05 ## 살아 돌아간 분신마다 종언 게이지 − 가득의 이 몫 (loop7: 버팀이 가득이어도 무시는 늘 손해)
const RIM_PAD := 3.0 ## 테두리 빛 텍스처 여백 (px)
const INK_GUARD_WORD_GAP := 0.35
const KILL_FLASH := 2.0 / 60.0 ## 에스카를 쓰러뜨린 한 방의 흰빛 번짐 (2프레임)
const RIM_IDLE := Color("#7a0d18", 0.8) ## 분신 테두리 평소 (CORD_DEEP — 먹 쪽으로, loop8 4장)
const RIM_HOT := Color("#ff2b3d", 1.0) ## 예고(9px 십자) 뒤부터 밝은 붉은색 — 위험 신호 ## 먹물 속 검성을 때렸을 때 "무효" 글자 사이 간격
const SHADOW_REST := 0.6
const SHADOW_W := 1.6 ## 고르는 무게 (판당 2~3번 — 쿨다운과 함께)
const SHADOW_COOL := 20.0
const SHADOW_FIRST := 4.0 ## 2막이 시작되고 이만큼 뒤부터
const SHADOW_POISE := 500.0 ## 분신을 베어 없애면 검성 버팀이 이만큼 깎임

# ─── 쓰러짐 ─────────────────────────────────────────────
const DEFEAT_T := 4.6

# 번뜩임 자리: 고정 · 칼코등이를 따라 · 칼끝을 따라
const GLINT_FIXED := 0
const GLINT_TSUBA := 1
const GLINT_TIP := 2

# ─── 색 (먹·뼈흰·붉은 끈) ────────────────────────────────
const INK := Color("#0b090c")
const COAT := Color("#16121a")
const COAT_HI := Color("#2b242c")
const RIM := Color("#857879") ## 달빛 테두리 (어두운 배경에서 실루엣이 읽히게)
const HAKAMA := Color("#1d181d")
const HAKAMA_SH := Color("#0f0c10")
const HAIR := Color("#f1ece4")
const HAIR_SH := Color("#bdb3a8")
const HAIR_DEEP := Color("#857b72")
const SKIN := Color("#cfb9a5")
const SKIN_SH := Color("#9d8571")
const STEEL := Color("#8e8a8c")
const STEEL_HI := Color("#e4e0da")
const STEEL_SH := Color("#4a4649")
const CORD := Color("#d01c2c")
const CORD_DEEP := Color("#7a0d18")
const BLADE_C := Color("#e9e7e3")

var phase := 1
var st := S.INTRO
var st_t := 0.0
var awake := false ## 싸움이 열렸나 (장면이 begin()으로 엶)
var has_sheath := true
var ai := true ## false = 스스로 기술을 고르지 않음 (시험: eval로 start_move만)
var _idle_for := 1.0
var _last := ""
var _ctr_cd := 0.0
var _rain_cd := 2.0
var _shadow_cd := SHADOW_FIRST
var _sh_kills := 0 ## 이번 그림자 일섬에서 베어 없앤 분신 수
var _sh_live := 0 ## 이번 그림자 일섬에서 아직 남은 분신 수
var _ink := 0.0 ## 먹물 속(무적) 정도 (그림)
var _ink_word := 0.0 ## "무효" 글자 간격
var _rim_vp: SubViewport ## 분신 테두리 빛을 구운 곳 (다음 그림자 일섬 때 새로)
var _pressed := 0.0 ## 에스카가 최근에 때렸나 (반격 자세를 더 자주)
var _k := 0 ## 삼연참 몇 번째
var _dash_from := 0.0
var _dash_to := 0.0
var _dash_dir := 1
var _iai_reach := IAI_MIN ## 이번 일섬 길이 — 웅크림을 시작한 순간의 거리로 정함 (물러서면 짧게 끝나 피할 수 있게)
var _iai_cut := false ## 일섬에 이미 베였나 (참격선이 터질 때 피해)
var _iai_hp := 0
var _iai_return := false
var _wave_n := 0
var _leap_x := 0.0
var _leap_lock := false
var _eyes_open := false
var _phase_fired := false
var _phase_rang := false
var _defeat_click := false
var _sheath_node: Node2D

# 자세 (그림이 읽는다 — 목표로 부드럽게 다가가고, 베는 순간은 바로)
var pz_crouch := 0.0
var pz_lean := 0.0
var pz_rh := Vector2(4, -20) ## 칼 쥔 손 (오른손)
var pz_lh := Vector2(2, -21) ## 칼집 쥔 손 (왼손)
var pz_out := 0.0 ## 칼이 나온 정도 (0 = 칼집 안, 1 = 다 뽑힘)
var pz_ang := 0.0 ## 손에 든 칼 방향 (0 = 앞, -PI/2 = 위)
var pz_spread := 11.0
var pz_kneel := 0.0
var pz_eyes := 0.0
var pz_bow := 0.0
var pz_air := 0.0
var pz_saya := 0.3 ## 칼집 기울기 (아래로)
var pz_alpha := 1.0
var _grip := false ## 오른손이 칼자루를 잡고 있나 (칼집 안일 때)
var _snap := false ## 이번 프레임 자세를 바로 맞춤 (베는 순간)
var _glint := 0.0 ## 칼코등이·칼끝 번뜩임 세기
var _glint_s := 1.0 ## 이번 번뜩임의 처음 세기 (십자 별 크기)
var _dim := 0.0 ## 발도 예고 중 화면 어두움 (0~1, 장면이 dim_k()로 읽음)
var _glint_at := Vector2.ZERO ## 번뜩이는 자리 (몸 기준)
var _glint_mode := 0
var _eye_glint := 0.0
var _aura := 0.0
var _hair: EArt.Chain
var _tail_a: EArt.Chain
var _tail_b: EArt.Chain
var _cord: EArt.Chain
var _chains_ready := false
var _trail := PackedVector2Array() ## 칼 궤적 [손잡이, 칼끝] 쌍 (전역)
var _last_tip := Vector2.ZERO
var _last_a := Vector2.ZERO
var _snap_v := PackedVector2Array() ## 마지막 그림 (잔상용)
var _snap_i := PackedInt32Array()
var _snap_c := PackedColorArray() ## 마지막 그림의 색 (분신이 먹빛으로 바꿔 씀)
var _shine: Shine
var _ring := 0.0 ## 반격 자세 바닥 고리
var _gust := 0.0


func _init() -> void:
	max_hp = HP
	size = BODY
	knock_resist = 0.96
	contact_dmg = 0
	still_resist = 0.0
	status_resist = 0.6
	max_poise = POISE
	hold_cap = HOLD_CAP
	break_time = 2.0
	break_mult = 1.25
	death_time = DEFEAT_T
	show_bar = false
	death_squash = false
	spawn_fx = false
	spawn_t = 0.0
	facing = -1


func _ready() -> void:
	super._ready()
	_shine = Shine.new()
	_shine.k = self
	_shine.material = Fx.add_material
	_shine.z_index = 1
	add_child(_shine)


## 장면이 싸움을 엶 (눈을 뜨고 곧 움직인다)
func begin() -> void:
	awake = true
	_go(S.IDLE)
	_idle_for = 0.9


## 연출: 눈을 뜸 (번뜩임)
func open_eyes() -> void:
	_eyes_open = true
	_eye_glint = 1.0
	Sfx.play_pitch(&"kb_glint", 0.8, -4.0)


## 발도 예고 중 화면 어두움 (0~1) — 장면이 배경을 살짝 어둡게 한다
func dim_k() -> float:
	return _dim


func p() -> int:
	return phase - 1


# ═══════════════════════════════════════════════════════════
# 생각
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if is_dead() and not is_on_floor():
		# 공중에서 쓰러지면 땅으로 내려와 무릎 꿇는다
		flying = false
		velocity.x = 0.0
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
		move_and_slide()
	super._physics_process(delta)
	var k := EKenseiFx.time_k(self) if (_bound > 0.0 or EStill.active()) else 1.0
	_anim(delta * k * haste_k())


func _think(delta: float) -> void:
	st_t += delta
	_ctr_cd = maxf(_ctr_cd - delta, 0.0)
	_rain_cd = maxf(_rain_cd - delta, 0.0)
	if phase == 2:
		_shadow_cd = maxf(_shadow_cd - delta, 0.0)
	_pressed = maxf(_pressed - delta, 0.0)
	if not awake:
		velocity.x = 0.0
		return
	if not eska_ok() and st != S.VICTOR and st != S.PHASE and not _airborne():
		_go(S.VICTOR)
		velocity.x = 0.0
	if phase == 1 and hp < int(float(max_hp) * PHASE2_AT) and st != S.PHASE and not _airborne():
		_start_phase()
	match st:
		S.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if st_t >= _idle_for and ai:
				_decide()
		S.WALK:
			facing = toward_eska()
			velocity.x = float(facing) * WALK_V
			if _dx() < 280.0 or st_t > 1.6:
				velocity.x = 0.0
				_decide(true)
		S.IAI_WIND:
			velocity.x = 0.0
			var wt := _wind(IAI_WIND)
			if st_t >= wt - IAI_GLINT and _glint <= 0.0:
				_tell(Vector2(5, -17), 1.0, GLINT_TSUBA)
			if st_t >= wt:
				_iai_go()
		S.IAI_DASH:
			var f := minf(st_t / IAI_DASH_T, 1.0)
			var x0 := global_position.x
			global_position.x = lerpf(_dash_from, _dash_to, f)
			velocity = Vector2.ZERO
			_iai_sweep(minf(x0, global_position.x), maxf(x0, global_position.x))
			if f >= 1.0:
				_iai_sweep(minf(_dash_from, _dash_to), maxf(_dash_from, _dash_to))
				_go(S.IAI_FOLLOW)
		S.IAI_FOLLOW:
			velocity.x = 0.0
			if st_t >= IAI_FOLLOW_T:
				_go(S.IAI_SHEATHE)
		S.IAI_SHEATHE:
			if st_t >= IAI_SHEATHE_T:
				_click()
				if phase == 2 and not _iai_return and randf() < IAI_RETURN and eska_ok():
					_iai_return = true
					_go(S.IAI_WIND)
					facing = toward_eska()
					st_t = _wind(IAI_WIND) - IAI_RETURN_WIND # 되돌아 베기: 웅크림이 조금 짧지만 번뜩임은 그대로
					_iai_lock()
					Sfx.play_pitch(&"kb_step", 1.1, -8.0)
				else:
					_iai_return = false
					_go(S.IAI_REST)
		S.IAI_REST:
			if st_t >= float(IAI_REST[p()]):
				_rest_done()
		S.TRI_WIND:
			velocity.x = 0.0
			var wt := _wind(TRI_WIND)
			if st_t >= wt - 0.16 and _glint <= 0.0:
				_tell(Vector2(5, -22), 0.8, GLINT_TSUBA)
			if st_t >= wt:
				_k = 0
				_go(S.TRI_CUT)
				_tri_cut()
		S.TRI_CUT:
			var step: float = TRI_STEP[_k]
			velocity.x = float(facing) * step / 0.06 if st_t < 0.06 else 0.0
			var gap: float = TRI_GAP[p()]
			if _k < 2 and st_t >= gap - 0.1 and _glint <= 0.0:
				_tell(Vector2(6, -23), 0.7, GLINT_TSUBA)
			if st_t >= gap:
				if _k < 2:
					_k += 1
					_go(S.TRI_CUT)
					_tri_cut()
				else:
					_go(S.TRI_REST)
					if phase == 1:
						_click()
		S.TRI_REST:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if st_t >= float(TRI_REST[p()]):
				_rest_done()
		S.WAVE_WIND:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			var wt := _wind(WAVE_WIND)
			if st_t >= wt - 0.18 and _glint <= 0.0:
				_tell(Vector2(4, -17), 0.9, GLINT_TSUBA)
			if st_t >= wt:
				_wave_n = 0
				_go(S.WAVE_CUT)
				_wave_fire()
		S.WAVE_CUT:
			if phase == 2 and _wave_n == 1 and st_t >= WAVE_SECOND - WAVE_SECOND_TELL and _glint <= 0.0:
				_tell(Vector2(4, -17), 0.9, GLINT_TSUBA) # 둘째 파도도 번뜩임·소리
				Sfx.play_pitch(&"kb_step", 1.1, -8.0)
			if phase == 2 and _wave_n == 1 and st_t >= WAVE_SECOND:
				_wave_fire()
			var hold := WAVE_SECOND + 0.2 if phase == 2 else 0.25
			if st_t >= hold:
				_go(S.WAVE_REST)
				if phase == 1:
					_click()
		S.WAVE_REST:
			if st_t >= float(WAVE_REST[p()]):
				_rest_done()
		S.CTR_STANCE:
			velocity.x = 0.0
			_ring = minf(_ring + delta / CTR_GRACE, 1.0)
			if st_t >= float(CTR_HOLD[p()]):
				_go(S.CTR_RELAX)
				st_t = CTR_RELAX - 0.35
		S.CTR_VANISH:
			velocity = Vector2.ZERO
			if st_t >= CTR_VANISH_T:
				_ctr_appear()
		S.CTR_WIND:
			velocity.x = 0.0
			var wt: float = CTR_WIND[p()]
			if st_t >= wt - 0.16 and _glint <= 0.0:
				_tell(Vector2(5, -17), 1.0, GLINT_TSUBA)
			if st_t >= wt:
				_go(S.CTR_CUT)
				_cut_front(CTR_REACH, CTR_DMG, -1.3, 1.0, 34.0)
				_draw_blade_now(Vector2(14, -30), -0.1)
		S.CTR_CUT:
			if st_t >= 0.16:
				_go(S.CTR_RELAX)
				if phase == 1:
					_click()
		S.CTR_RELAX:
			_ring = maxf(_ring - delta * 4.0, 0.0)
			if st_t >= CTR_RELAX:
				_rest_done()
		S.PHASE:
			_phase_tick()
		S.LEAP_WIND:
			velocity.x = 0.0
			if st_t >= LEAP_WIND - 0.18 and _glint <= 0.0:
				_tell(Vector2(3, -84), 0.9, GLINT_TIP)
			if st_t >= LEAP_WIND:
				_leap_go()
		S.LEAP_UP:
			velocity.y += LEAP_G * delta
			if eska_ok():
				_leap_x = clampf(eska.global_position.x, x_min + 10.0, x_max - 10.0)
			var want := (_leap_x - global_position.x) / maxf(-velocity.y / LEAP_G, 0.12)
			velocity.x = clampf(want, -420.0, 420.0)
			if velocity.y >= 0.0:
				_go(S.LEAP_HANG)
				velocity = Vector2.ZERO
		S.LEAP_HANG:
			velocity = Vector2.ZERO
			if st_t < LEAP_HANG - LEAP_LOCK and eska_ok():
				_leap_x = clampf(eska.global_position.x, x_min + 10.0, x_max - 10.0)
			elif not _leap_lock:
				_leap_lock = true
				_tell(Vector2(4, -6), 1.0)
			global_position.x = lerpf(global_position.x, _leap_x, 1.0 - exp(-delta * 14.0))
			if st_t >= LEAP_HANG:
				global_position.x = _leap_x
				_go(S.LEAP_FALL)
				velocity = Vector2(0, LEAP_FALL_V)
				Sfx.play_pitch(&"kb_draw", 0.8, -4.0)
		S.LEAP_FALL:
			velocity = Vector2(0, LEAP_FALL_V)
			if is_on_floor() or st_t > 1.2:
				_leap_land()
		S.LEAP_REST:
			velocity.x = 0.0
			if st_t >= LEAP_REST:
				_rest_done()
		S.RAIN_WIND:
			velocity.x = 0.0
			if st_t >= RAIN_WIND - 0.2 and _glint <= 0.0:
				_tell(Vector2(3, -92), 1.2, GLINT_TIP)
			if st_t >= RAIN_WIND:
				_rain_fire()
				_go(S.RAIN_HOLD)
		S.RAIN_HOLD:
			if st_t >= RAIN_HOLD:
				_go(S.RAIN_REST)
		S.RAIN_REST:
			if st_t >= RAIN_REST:
				_rest_done()
		S.SHADOW_WIND:
			velocity.x = 0.0
			if st_t >= SHADOW_WIND - 0.2 and _glint <= 0.0:
				_tell(Vector2(5, -17), 0.8, GLINT_TSUBA)
			if st_t >= SHADOW_WIND:
				_shadow_spawn()
				_go(S.SHADOW_HOLD)
		S.SHADOW_HOLD:
			velocity.x = 0.0
			if (st_t >= SHADOW_HOLD and _sh_live <= 0) or st_t >= SHADOW_HOLD_MAX:
				_go(S.SHADOW_REST)
		S.SHADOW_REST:
			if st_t >= SHADOW_REST:
				_rest_done()
		S.VICTOR:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)


func _go(s: S) -> void:
	st = s
	st_t = 0.0
	_glint = 0.0


func _dx() -> float:
	return absf(eska.global_position.x - global_position.x) if eska_ok() else 0.0


func _wind(arr: Array) -> float:
	return float(arr[p()])


func _airborne() -> bool:
	return st in [S.LEAP_UP, S.LEAP_HANG, S.LEAP_FALL]


## 다음 기술 고르기: 거리에 따라 무게를 두고, 방금 쓴 것은 덜 고른다
func _decide(after_walk := false) -> void:
	if not eska_ok():
		_go(S.VICTOR)
		return
	facing = toward_eska()
	var dx := _dx()
	if dx > 330.0 and not after_walk:
		_go(S.WALK)
		return
	var w := {
		"iai": 3.0 if dx > 110.0 else 1.0,
		"tri": 3.0 if dx < 150.0 else 0.4,
		"wave": 2.4 if dx > 150.0 else 0.7,
		"ctr": ((1.6 if dx < 140.0 else 0.3) * (1.8 if _pressed > 0.0 else 1.0)) if _ctr_cd <= 0.0 else 0.0,
	}
	if phase == 2:
		w["leap"] = 2.0
		w["rain"] = 1.8 if _rain_cd <= 0.0 else 0.0
		w["shadow"] = SHADOW_W if _shadow_cd <= 0.0 else 0.0
	if w.has(_last):
		w[_last] = float(w[_last]) * 0.25
	var total := 0.0
	for k: String in w:
		total += float(w[k])
	var r := randf() * total
	var pick := "iai"
	for k: String in w:
		r -= float(w[k])
		if r <= 0.0:
			pick = k
			break
	start_move(pick)


## 기술 시작 (시험 실행기 eval에서도 부른다: "iai" · "tri" · "wave" · "ctr" · "leap" · "rain" · "shadow")
func start_move(id: String) -> void:
	_last = id
	move_started.emit(id)
	if eska_ok():
		facing = toward_eska()
	match id:
		"iai":
			_go(S.IAI_WIND)
			_iai_lock()
			Sfx.play_pitch(&"kb_step", 0.8, -10.0)
			EVfx.land_dust(global_position + Vector2(-facing * 6.0, 0))
		"tri":
			_go(S.TRI_WIND)
		"wave":
			_go(S.WAVE_WIND)
			velocity.x = -float(facing) * 50.0 # 뒤로 반 걸음
		"ctr":
			_go(S.CTR_STANCE)
			_ctr_cd = CTR_COOL
			_ring = 0.0
			Sfx.play_pitch(&"kb_chime", 1.0, -3.0)
		"leap":
			_go(S.LEAP_WIND)
			_leap_lock = false
		"rain":
			_go(S.RAIN_WIND)
			_rain_cd = RAIN_COOL
			Sfx.play_pitch(&"kb_ring", 1.3, -10.0)
		"shadow":
			_go(S.SHADOW_WIND)
			_shadow_cd = SHADOW_COOL
			Sfx.play_pitch(&"kb_ring", 0.75, -8.0)
			EVfx.land_dust(global_position)


## 숨 고르기가 끝남 → 쉬었다가 다음 (2막은 가끔 바로 이어서)
func _rest_done() -> void:
	_go(S.IDLE)
	var range_t: Vector2 = IDLE_T[p()]
	_idle_for = randf_range(range_t.x, range_t.y)
	if phase == 2 and randf() < COMBO_CHANCE:
		_idle_for = COMBO_IDLE


## 예고: 번뜩임 + 소리 (자리 = 몸 기준, mode가 GLINT_TSUBA·GLINT_TIP이면 칼코등이·칼끝을 따라감)
func _tell(at: Vector2, strength: float, mode := GLINT_FIXED) -> void:
	_glint = strength
	_glint_s = maxf(strength, 0.01)
	_glint_at = at
	_glint_mode = mode
	Sfx.play_pitch(&"kb_glint", randf_range(0.97, 1.05), -6.0 + 3.0 * strength)


## 칼집에 칼이 들어가는 딸깍 (1막)
func _click() -> void:
	if has_sheath:
		Sfx.play_pitch(&"kb_sheath", randf_range(0.97, 1.03), -3.0)


# ─── 발도 일섬 ───────────────────────────────────────────

## 일섬 길이를 지금(웅크림 시작) 거리로 정함 — 그 뒤 에스카가 물러서도 따라가지 않는다
func _iai_lock() -> void:
	_iai_reach = clampf(_dx() + IAI_PAST, IAI_MIN, IAI_MAX)


func _iai_go() -> void:
	_dash_dir = facing
	_dash_from = global_position.x
	var dist := _iai_reach
	_dash_to = clampf(global_position.x + float(facing) * dist, x_min + 6.0, x_max - 6.0)
	_iai_cut = false
	_go(S.IAI_DASH)
	_snap = true
	Sfx.play_pitch(&"kb_draw", randf_range(0.97, 1.04), 0.0)
	Sfx.play_pitch(&"kb_step", 1.2, -6.0)
	EVfx.land_dust(global_position)
	# 잔상: 지나간 길에 흰 그림자 셋
	for i in 3:
		var f := (float(i) + 0.5) / 3.0
		_afterimage(Vector2(lerpf(_dash_from, _dash_to, f) - global_position.x, 0), 0.22 + 0.06 * float(i))
	# 참격선: 칼을 거둔 뒤 한 박자 늦게 터진다
	var y := global_position.y + (IAI_BAND.x + IAI_BAND.y) * 0.5 - 2.0
	var sl := EKenseiFx.SlashLine.new()
	sl.boss = self
	sl.a = Vector2(_dash_from - float(facing) * 6.0, y)
	sl.b = Vector2(_dash_to + float(facing) * 10.0, y)
	sl.delay = IAI_DASH_T + IAI_FOLLOW_T + IAI_SHEATHE_T + IAI_BURST
	sl.w = 8.0
	sl.on_burst = _iai_burst
	PVfx.add(sl, sl.a, false)
	Fx.shake(0.3, 0.1)


## 일섬이 지나간 길(x0~x1)에 에스카가 있었나 — 있으면 이미 베였다 (피해는 참격선이 터질 때)
func _iai_sweep(x0: float, x1: float) -> void:
	if _iai_cut or not eska_ok():
		return
	if eska.invuln > 0.0 or eska.st == EEska.St.BLINK:
		return
	var r := Rect2(Vector2(x0 - 6.0, global_position.y + IAI_BAND.x), Vector2(x1 - x0 + 12.0, IAI_BAND.y - IAI_BAND.x))
	if eska.hurt_rect().intersects(r):
		_iai_cut = true
		_iai_hp = eska.hp
		var m := EKenseiFx.CutMark.new()
		m.target = eska
		m.life = IAI_FOLLOW_T + IAI_SHEATHE_T + IAI_BURST + 0.05
		m.ang = -0.2 * float(_dash_dir)
		PVfx.add(m, eska.center(), false) # 먹빛 심이라 섞지 않고 그림 (loop6 색 반전)
		Fx.hitstop(0.08)
		Sfx.play_pitch(&"kb_glint", 1.4, -2.0)


func _iai_burst() -> void:
	if not _iai_cut or not eska_ok():
		return
	_iai_cut = false
	if eska.hp == _iai_hp:
		eska.invuln = 0.0 # 이미 베인 몸 — 그 사이 순간이동으로 피할 수 없다
	if eska.hurt(IAI_DMG, Vector2(eska.global_position.x - float(_dash_dir) * 30.0, eska.global_position.y)):
		_big_hit_fx(eska.center(), _dash_dir)


# ─── 삼연참 ─────────────────────────────────────────────

func _tri_cut() -> void:
	var reach: float = TRI_REACH[_k]
	var a0 := -1.3 if _k != 1 else 1.0
	var a1 := 1.0 if _k != 1 else -1.3
	if _k == 2:
		a0 = -1.6
		a1 = 0.6
	_cut_front(reach, TRI_DMG, a0, a1, reach * 0.55, TRI_H, TRI_ARC_Y, TRI_ARC_SQUASH)
	var ang := 0.9 if _k == 0 else (-1.1 if _k == 1 else -0.15)
	_draw_blade_now(Vector2(13, -27 + (4 if _k == 0 else -3)), ang)
	Sfx.play_pitch(&"kb_draw", randf_range(1.05, 1.15) - 0.08 * float(_k), -3.0)


## 앞을 벰: 초승달 칼자국 + 앞 reach 안, 발에서 h 높이까지의 에스카에게 피해 (칼자국 가운데 높이 arc_y · 납작함 squash)
func _cut_front(reach: float, dmg: int, a0: float, a1: float, r: float, h := CUT_H, arc_y := CUT_ARC_Y, squash := CUT_ARC_SQUASH) -> void:
	var c := global_position + Vector2(float(facing) * 12.0, arc_y)
	var arc := EKenseiFx.Arc.new()
	arc.dir = facing
	arc.r = r
	arc.a0 = a0
	arc.a1 = a1
	arc.w = 6.0 + reach * 0.06
	arc.squash = squash
	PVfx.add(arc, c, true)
	var x0 := global_position.x + float(facing) * -6.0
	var x1 := global_position.x + float(facing) * reach
	var rect := Rect2(Vector2(minf(x0, x1), global_position.y - h), Vector2(absf(x1 - x0), h))
	_hit_eska(rect, dmg, false)
	# 1막: 거둔 뒤 칼자국 자리에 가는 참격선이 한 번 더 터짐 (그림만)
	var sl := EKenseiFx.SlashLine.new()
	sl.boss = self
	# 칼자국의 시위(두 끝을 잇는 선)를 따라 — 벤 길 그대로
	sl.a = c + Vector2(cos(a0) * r * float(facing), sin(a0) * r * arc.squash)
	sl.b = c + Vector2(cos(a1) * r * float(facing), sin(a1) * r * arc.squash)
	sl.delay = 0.42
	sl.w = 6.0
	sl.loud = false
	PVfx.add(sl, sl.a, false)


## 칼을 뽑은 순간의 자세 (손 자리·칼 방향을 바로 맞춤)
func _draw_blade_now(hand: Vector2, ang: float) -> void:
	pz_rh = hand
	pz_ang = ang
	pz_out = 1.0
	_snap = true


func _hit_eska(r: Rect2, dmg: int, big: bool) -> bool:
	if not eska_ok():
		return false
	if eska.hurt_rect().intersects(r) and eska.hurt(dmg, center()):
		if big:
			_big_hit_fx(eska.center(), facing)
		else:
			Fx.hitstop(0.05)
			EKenseiFx.sparks(eska.center(), 8, Vector2(float(facing), -0.3), 160.0, 60.0)
		return true
	return false


## 큰 기술에 맞았을 때: 더 긴 멈춤 + 흰 섬광
func _big_hit_fx(at: Vector2, dir: int) -> void:
	Fx.hitstop(0.16)
	# 쓰러뜨린 한 방이면 흰빛 번짐을 2프레임만 (붉은 가장자리는 장면이 깖 — loop8 3장)
	Fx.flash(Color(1.0, 0.95, 0.9, 0.35), KILL_FLASH if not eska_ok() else 0.14)
	Fx.shake(0.9, 0.22)
	EKenseiFx.sparks(at, 16, Vector2(float(dir), -0.2), 220.0, 70.0)


# ─── 비검 ───────────────────────────────────────────────

func _wave_fire() -> void:
	_wave_n += 1
	var w := EKenseiFx.Wave.new()
	w.boss = self
	w.dir = facing
	w.speed = float(WAVE_SPEED[p()])
	w.x_min = x_min - 4.0
	w.x_max = x_max + 4.0
	PVfx.add(w, global_position + Vector2(float(facing) * 16.0, 0), false)
	_draw_blade_now(Vector2(13, -33), -0.75)
	Sfx.play_pitch(&"kb_wave", randf_range(0.95, 1.05), -2.0)
	EVfx.land_dust(global_position + Vector2(float(facing) * 14.0, 0))


# ─── 반격 자세 ───────────────────────────────────────────

func _intercept_hit(_dmg: int, from: Vector2, _opts: Dictionary) -> bool:
	if st == S.INTRO or st == S.CTR_VANISH or st == S.VICTOR or not awake:
		return true
	if st == S.PHASE:
		# 막 전환 중: 칼에 막힘 (그림으로 알려 줌)
		EKenseiFx.sparks(center() + Vector2(float(facing) * 6.0, -6.0), 4, (from - center()).normalized(), 120.0, 50.0)
		return true
	if ink_guard():
		# 분신이 서 있는 동안: 먹물 속이라 칼이 닿지 않음 ("무효")
		if _ink_word <= 0.0:
			_ink_word = INK_GUARD_WORD_GAP
			EKenseiFx.word(center() + Vector2(0, -34), "무효")
			EKenseiFx.petals(center(), 4, Vector2(8, 16), 50.0)
		return true
	_pressed = 2.0
	if st == S.CTR_STANCE and _bound <= 0.0 and st_t >= CTR_GRACE:
		_counter_triggered()
		return true
	return false


func _counter_triggered() -> void:
	_go(S.CTR_VANISH)
	Sfx.play_pitch(&"kb_chime", 1.5, 0.0)
	Sfx.play_pitch(&"kb_step", 1.3, -4.0)
	_afterimage(Vector2.ZERO, 0.35)
	# 받아넘김: 칼집에서 반쯤 뽑은 칼날이 번쩍 — 흰 초승달 하나
	var arc := EKenseiFx.Arc.new()
	arc.dir = facing
	arc.r = 20.0
	arc.a0 = -1.8
	arc.a1 = 1.2
	arc.w = 5.0
	PVfx.add(arc, center() + Vector2(float(facing) * 4.0, -4.0), true)
	EKenseiFx.petals(center(), 14, Vector2(8, 20), 90.0)
	EKenseiFx.sparks(center(), 6, Vector2.UP, 120.0, 180.0)
	pz_alpha = 0.0
	Fx.hitstop(0.06)


func _ctr_appear() -> void:
	var side := 1 if eska.global_position.x >= global_position.x else -1
	var x := eska.global_position.x + float(side) * CTR_BEHIND
	if x < x_min + 8.0 or x > x_max - 8.0:
		x = eska.global_position.x - float(side) * CTR_BEHIND # 벽이면 앞에서
	global_position.x = clampf(x, x_min + 8.0, x_max - 8.0)
	facing = toward_eska()
	pz_alpha = 1.0
	_go(S.CTR_WIND)
	_snap = true
	_reset_chains()
	EKenseiFx.petals(center(), 10, Vector2(6, 18), 70.0)
	Sfx.play_pitch(&"kb_step", 1.0, -4.0)


func _interrupted() -> void:
	if st in [S.IAI_WIND, S.TRI_WIND, S.WAVE_WIND, S.CTR_STANCE, S.CTR_WIND, S.LEAP_WIND, S.RAIN_WIND, S.SHADOW_WIND]:
		_go(S.IDLE)
		_idle_for = 0.5
	elif _airborne():
		flying = false
		_go(S.IDLE)
		_idle_for = 0.6
	_ring = 0.0


# ─── 버팀 ───────────────────────────────────────────────

func _on_poise_break() -> void:
	flying = false
	_ring = 0.0
	if st == S.CTR_VANISH:
		pz_alpha = 1.0
	_go(S.IDLE)
	_idle_for = 0.4
	Sfx.play_pitch(&"kb_break", 1.0, 0.0)
	Fx.hitstop(0.12)
	Fx.flash(Color(1, 1, 1, 0.3), 0.12)
	Fx.shake(0.8, 0.25)
	EKenseiFx.sparks(center(), 18, Vector2.UP, 200.0, 180.0)
	EVfx.shards(center(), 10, 160.0, Vector2(8, 14), 60.0)
	Fx.ring(center(), 8.0, 60.0, Color(1, 1, 1, 0.8), 0.3, 2.0)


func _on_poise_recover() -> void:
	_go(S.IDLE)
	_idle_for = 0.35
	Sfx.play_pitch(&"kb_step", 0.9, -8.0)


func _broken_think(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)


# ─── 막 전환 ─────────────────────────────────────────────

func _start_phase() -> void:
	flying = false
	_go(S.PHASE)
	_phase_fired = false
	_phase_rang = false
	_ring = 0.0
	velocity = Vector2.ZERO
	Fx.hitstop(0.2)
	Fx.slowmo(0.4, 0.5)
	phase_starting.emit()
	Fx.flash(Color(1, 1, 1, 0.4), 0.2)
	Sfx.play_pitch(&"kb_sheath", 0.7, 0.0)


func _phase_tick() -> void:
	velocity.x = 0.0
	if st_t >= 0.85 and not _phase_rang:
		_phase_rang = true
		Sfx.play_pitch(&"kb_ring", 1.0, 0.0)
	if not _phase_fired and st_t >= PHASE_DRAW_AT:
		_phase_fired = true
		phase = 2
		still_resist = STILL_RESIST_P2
		has_sheath = false
		_toss_sheath()
		Fx.shake(1.0, 0.4)
		Fx.flash(Color(1, 0.96, 0.92, 0.45), 0.25)
		EKenseiFx.petals(center() + Vector2(0, -10), 40, Vector2(30, 30), 160.0)
		EKenseiFx.sparks(global_position + Vector2(float(facing) * 8.0, -60.0), 20, Vector2.UP, 220.0, 180.0)
		Fx.ring(center(), 10.0, 150.0, Color(1.0, 0.96, 0.92, 0.9), 0.45, 3.0)
		Fx.ring(center(), 6.0, 90.0, Color(EKenseiFx.RED_HOT, 0.8), 0.35, 2.0)
		_shadow_cd = SHADOW_FIRST
		phase_changed.emit(2)
	if st_t >= PHASE_T:
		_go(S.IDLE)
		_idle_for = 0.3


## 2막 확인점에서 다시 시작 (loop8 1장): 칼을 뽑은 채, 체력 55%에서 바로 2막
func start_phase2() -> void:
	phase = 2
	still_resist = STILL_RESIST_P2
	has_sheath = false
	hp = int(float(max_hp) * PHASE2_AT) - 1
	_hp_trail = float(hp)
	_shadow_cd = SHADOW_FIRST
	pz_out = 1.0


func _toss_sheath() -> void:
	var s := EKenseiFx.Sheath.new()
	s.position = global_position + Vector2(float(facing) * 2.0, -20.0)
	s.vel = Vector2(-float(facing) * 140.0, -300.0)
	s.spin = -float(facing) * 15.0
	s.floor_y = global_position.y
	get_parent().add_child(s)
	_sheath_node = s


# ─── 낙화 ───────────────────────────────────────────────

func _leap_go() -> void:
	flying = true
	_go(S.LEAP_UP)
	velocity = Vector2(0, LEAP_VY)
	_leap_x = clampf(eska.global_position.x, x_min + 10.0, x_max - 10.0) if eska_ok() else global_position.x
	Sfx.play_pitch(&"kb_step", 0.7, -2.0)
	Sfx.play_pitch(&"whoosh", 0.8, -6.0)
	EVfx.land_dust(global_position)
	EKenseiFx.petals(global_position + Vector2(0, -6), 10, Vector2(12, 4), 80.0)


func _leap_land() -> void:
	flying = false
	velocity = Vector2.ZERO
	_go(S.LEAP_REST)
	var pos := global_position
	var im := EKenseiFx.Impact.new()
	im.reach = LEAP_REACH
	PVfx.add(im, pos, true)
	EFoeFx.shock(pos, LEAP_REACH * 0.6)
	Sfx.play_pitch(&"kb_land", 1.0, 0.0)
	Fx.shake(1.2, 0.32)
	Fx.hitstop(0.06)
	PVfx.kick(Vector2(0, 6))
	if not eska_ok():
		return
	var ex := absf(eska.global_position.x - pos.x)
	var grounded := eska.global_position.y > pos.y - 20.0
	if ex < LEAP_CORE and eska.global_position.y > pos.y - 60.0:
		if eska.hurt(2, pos + Vector2(0, -10)):
			_big_hit_fx(eska.center(), toward_eska())
	elif ex < LEAP_REACH and grounded:
		if eska.hurt(1, pos):
			Fx.hitstop(0.06)


# ─── 천검 ───────────────────────────────────────────────

func _rain_fire() -> void:
	var cx := eska.global_position.x if eska_ok() else global_position.x
	var order := 1 if cx >= global_position.x else -1 # 검성 쪽부터 먼 쪽으로 차례로
	var volleys := 2 if float(hp) < float(max_hp) * RAIN_TWICE_BELOW else 1
	for v in volleys:
		var shift := RAIN_GAP * 0.5 * float(v)
		for i in RAIN_N:
			var j := i if order > 0 else RAIN_N - 1 - i
			var x := cx + (float(j) - float(RAIN_N - 1) * 0.5) * RAIN_GAP + shift + randf_range(-6.0, 6.0)
			if x < x_min - 4.0 or x > x_max + 4.0:
				continue
			var rb := EKenseiFx.RainBlade.new()
			rb.boss = self
			rb.warn = RAIN_WARN + float(i) * RAIN_STAGGER + float(v) * 0.95
			PVfx.add(rb, Vector2(x, global_position.y), false)
	Sfx.play_pitch(&"kb_ring", 1.6, -4.0)
	Fx.flash(Color(1, 0.95, 0.9, 0.15), 0.1)


# ─── 그림자 일섬 ─────────────────────────────────────────

## 분신 셋을 에스카 자리에 한 줄로 세운다 (지금 그림 = 웅크린 발도 자세를 먹빛으로)
func _shadow_spawn() -> void:
	var cx := eska.global_position.x if eska_ok() else global_position.x + float(facing) * 120.0
	var dir := toward_eska()
	var rim := _bake_shadow_rim()
	for i in SHADOW_N:
		var x := clampf(cx + (float(i) - float(SHADOW_N - 1) * 0.5) * SHADOW_GAP, x_min + 10.0, x_max - 10.0)
		var sh := Shadow.new()
		sh.boss = self
		sh.src_v = _snap_v
		sh.src_i = _snap_i
		sh.src_c = _snap_c
		sh.src_facing = facing
		sh.facing = dir
		sh.rim_tex = rim[0]
		sh.rim_rect = rim[1]
		sh.order = i
		sh.position = Vector2(x, global_position.y)
		sh.x_min = x_min
		sh.x_max = x_max
		get_parent().add_child(sh)
		sh.died.connect(_on_shadow_died)
		sh.returned.connect(_on_shadow_returned)
	_sh_kills = 0
	_sh_live = SHADOW_N
	Sfx.play_pitch(&"kb_step", 0.8, -4.0)
	Sfx.play_pitch(&"kb_gust", 1.3, -8.0)
	_afterimage(Vector2.ZERO, 0.3)


## 분신 붉은 테두리 빛을 한 번만 그려 텍스처로 (loop7: 분신마다 상하좌우로 4번 겹쳐 그리던 도형 약 1700 → 사각형 하나)
## 지금 그림(_snap_*)을 붉게 1px씩 밀어 SubViewport에 한 번 그린다. 돌려줌: [텍스처, 그림 좌표 사각형]
func _bake_shadow_rim() -> Array:
	if is_instance_valid(_rim_vp):
		_rim_vp.queue_free()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for v in _snap_v:
		lo = lo.min(v)
		hi = hi.max(v)
	if _snap_v.is_empty():
		return [null, Rect2()]
	var r := Rect2(lo - Vector2(RIM_PAD, RIM_PAD), hi - lo + Vector2(RIM_PAD, RIM_PAD) * 2.0)
	var org := r.position.floor()
	r = Rect2(org, (r.end - org).ceil())
	var vp := SubViewport.new()
	vp.size = Vector2i(r.size)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter := RimPainter.new()
	painter.v = _snap_v
	painter.idx = _snap_i
	painter.c = _snap_c
	painter.position = -org
	vp.add_child(painter)
	vp.add_to_group(EKenseiFx.GROUP) # 처음부터 할 때·쓰러질 때 분신과 같이 거둠
	get_parent().add_child(vp)
	_rim_vp = vp
	return [vp.get_texture(), r]


## 분신이 사라짐: 베어 없앤 것이면(시간이 다 돼 스스로 사라진 게 아니면) 검성 버팀이 깎임
func _on_shadow_died(e: EEnemy) -> void:
	var sh := e as Shadow
	if sh == null or sh.expired or is_dead():
		return
	_sh_live = maxi(_sh_live - 1, 0)
	_sh_kills += 1
	poise_damage(SHADOW_POISE)
	EKenseiFx.sparks(center(), 6, Vector2.UP, 120.0, 90.0)
	if _sh_kills >= SHADOW_N:
		# 셋 다 베었다: 먹물이 걷히며 즉시 무너짐 + 게이지
		poise_damage(maxf(poise, 1.0))
		if is_instance_valid(eska):
			eska.add_gauge(SHADOW_ALL_GAUGE * EEska.GAUGE_MAX)
		EKenseiFx.petals(center(), 24, Vector2(14, 24), 120.0, EKenseiFx.PETAL_BIG)


## 분신이 서 있는 동안 먹물 속(무적)인가 — 봉공이 걸려 있으면 먹물이 풀림 (loop8: 「분신을 멈춰 두고 스승을 친다」 — 흑성·유성우와 다른 봉공의 답)
func ink_guard() -> bool:
	return st == S.SHADOW_HOLD and _sh_live > 0 and not is_dead() and not EStill.active()


## 분신이 살아 돌아감 (일섬을 마침): 먹이 검성에게 스며들며 버팀 회복
func _on_shadow_returned(sh: Node2D) -> void:
	_sh_live = maxi(_sh_live - 1, 0)
	if is_dead():
		return
	EKenseiFx.ink_return(sh.global_position + Vector2(0, -24), self)
	if break_t <= 0.0:
		poise = minf(poise + SHADOW_RETURN_POISE, max_poise)
	if eska_ok():
		eska.gauge = maxf(eska.gauge - SHADOW_RETURN_GAUGE * EEska.GAUGE_MAX, 0.0)


## 지금 나와 있는 분신들 (봇·시험용)
func shadows() -> Array:
	return get_tree().get_nodes_in_group(Shadow.GROUP)


# ─── 쓰러짐 ─────────────────────────────────────────────

func _death_fx(_dir: float) -> void:
	flying = false
	_ring = 0.0
	pz_alpha = 1.0
	Fx.hitstop(0.25)
	Fx.slowmo(0.35, 1.0)
	Fx.flash(Color(1, 1, 1, 0.55), 0.35)
	Fx.shake(1.0, 0.4)
	Sfx.play_pitch(&"kb_defeat", 1.0, 0.0)
	EKenseiFx.sparks(center(), 20, Vector2.UP, 220.0, 180.0)
	for n: Node in get_tree().get_nodes_in_group(EKenseiFx.GROUP):
		n.queue_free() # 남은 칼빛은 거둔다


# ═══════════════════════════════════════════════════════════
# 자세 (애니메이션)
# ═══════════════════════════════════════════════════════════

func _anim(delta: float) -> void:
	if delta <= 0.0:
		return
	_glint = maxf(_glint - delta * 2.6, 0.0)
	if _glint > 0.0 and _glint_mode != GLINT_FIXED:
		var ts := _tsuba()
		_glint_at = (ts[0] as Vector2) + ((ts[1] as Vector2) * BLADE_L * pz_out if _glint_mode == GLINT_TIP else Vector2.ZERO)
	_eye_glint = maxf(_eye_glint - delta * 1.5, 0.0)
	_ink = move_toward(_ink, 1.0 if ink_guard() else 0.0, delta * 3.0)
	_ink_word = maxf(_ink_word - delta, 0.0)
	var dim_to := 0.0
	if st == S.IAI_WIND and not is_dead():
		var wt := _wind(IAI_WIND)
		dim_to = smoothstep(wt - IAI_DIM_LEAD, wt - IAI_GLINT, st_t)
	_dim = move_toward(_dim, dim_to, delta * (DIM_IN if dim_to > _dim else DIM_OUT))
	_aura = move_toward(_aura, 1.0 if phase == 2 and not is_dead() else 0.0, delta * 1.5)
	if st != S.CTR_STANCE and st != S.CTR_RELAX:
		_ring = maxf(_ring - delta * 4.0, 0.0)
	var tg := _pose()
	var rate := float(tg.get("rate", 14.0))
	var f := 1.0 if _snap else 1.0 - exp(-delta * rate)
	_snap = false
	pz_crouch = lerpf(pz_crouch, float(tg.crouch), f)
	pz_lean = lerpf(pz_lean, float(tg.lean), f)
	pz_rh = pz_rh.lerp(tg.rh, f)
	pz_lh = pz_lh.lerp(tg.lh, f)
	pz_out = lerpf(pz_out, float(tg.out), f) if not tg.has("out_now") else float(tg.out)
	pz_ang = lerp_angle(pz_ang, float(tg.ang), f)
	pz_spread = lerpf(pz_spread, float(tg.spread), f)
	pz_kneel = lerpf(pz_kneel, float(tg.get("kneel", 0.0)), 1.0 - exp(-delta * 9.0))
	pz_eyes = lerpf(pz_eyes, float(tg.get("eyes", 1.0)), 1.0 - exp(-delta * 10.0))
	pz_bow = lerpf(pz_bow, float(tg.get("bow", 0.0)), 1.0 - exp(-delta * 6.0))
	pz_air = lerpf(pz_air, float(tg.get("air", 0.0)), 1.0 - exp(-delta * 16.0))
	pz_saya = lerpf(pz_saya, float(tg.get("saya", 0.3)), f)
	_grip = bool(tg.get("grip", false))
	if is_dead():
		_defeat_tick()
	_tick_chains(delta)
	_tick_trail()


## 지금 상태의 목표 자세 (몸 기준 좌표, 오른쪽을 보는 모습)
func _pose() -> Dictionary:
	var drawn := not has_sheath # 2막: 칼은 늘 손에
	var breath := sin(t * 1.6) * 0.6
	var idle_rh := Vector2(9, -26) if drawn else Vector2(4.5, -20.5 + breath * 0.3)
	var pose := {"crouch": 0.0, "lean": -0.02, "rh": idle_rh, "lh": _saya_mouth() + Vector2(-1.5, 0.8),
		"out": 1.0 if drawn else 0.0, "ang": 0.62, "spread": 11.0, "eyes": 1.0 if _eyes_open else 0.0, "rate": 10.0}
	if drawn:
		pose["lh"] = Vector2(-2.0, -19.0 + breath * 0.3)
	if is_dead():
		return _pose_defeat(drawn)
	if break_t > 0.0:
		pose.merge({"kneel": 1.0, "bow": 1.0, "crouch": 0.0, "lean": 0.3, "eyes": 0.0, "rate": 12.0}, true)
		if drawn:
			pose["rh"] = Vector2(10, -20)
			pose["ang"] = PI * 0.5 - 0.15 # 칼을 땅에 짚음
			pose["lh"] = Vector2(9, -22)
		else:
			pose["lh"] = _saya_mouth() + Vector2(-1, 1)
			pose["rh"] = Vector2(9, -13) # 무릎 위에 손
		return pose
	if stagger > 0.0:
		pose.merge({"crouch": 0.4, "lean": -0.15, "eyes": 0.6}, true)
		return pose
	match st:
		S.INTRO:
			pose["eyes"] = 1.0 if _eyes_open else 0.0
			pose["bow"] = 0.0 if _eyes_open else 0.4
		S.WALK:
			pose["lean"] = 0.08
		S.IAI_WIND, S.CTR_WIND:
			var wt := _wind(IAI_WIND) if st == S.IAI_WIND else float(CTR_WIND[p()])
			var k := smoothstep(0.0, 0.35, st_t / wt)
			pose.merge({"crouch": 1.0 * k, "lean": 0.38 * k, "spread": 11.0 + 9.0 * k, "saya": 0.05, "rate": 18.0}, true)
			if drawn:
				# 2막: 칼을 몸 뒤로 낮게 감춤 (와키가마에)
				pose["rh"] = Vector2(-1, -22)
				pose["ang"] = PI - 0.35
				pose["lh"] = Vector2(3, -27)
			else:
				pose["grip"] = true
				pose["rh"] = _saya_mouth() - _saya_dir() * 4.5
				pose["lh"] = _saya_mouth() + _saya_dir() * 2.5
		S.IAI_DASH, S.IAI_FOLLOW, S.CTR_CUT:
			pose.merge({"crouch": 0.75, "lean": 0.2, "spread": 20.0, "rh": Vector2(15, -30), "ang": -0.12, "out": 1.0, "rate": 30.0}, true)
			pose["lh"] = _saya_mouth() + Vector2(-1, 1) if has_sheath else Vector2(-6, -27)
			if not has_sheath:
				pose["rh"] = Vector2(14, -32)
		S.IAI_SHEATHE:
			var k := clampf(st_t / IAI_SHEATHE_T, 0.0, 1.0)
			if has_sheath:
				# 칼을 칼집 축을 따라 미끄러뜨려 넣는다 (손이 앞에서 칼집 입구로)
				var out := 1.0 - smoothstep(0.15, 1.0, k)
				pose.merge({"crouch": lerpf(0.6, 0.15, k), "lean": lerpf(0.15, 0.05, k), "spread": lerpf(20.0, 13.0, k), "out": out, "out_now": true,
					"ang": _saya_dir().angle(), "rate": 40.0, "saya": 0.3}, true)
				pose["rh"] = _saya_mouth() - _saya_dir() * (BLADE_L * out + 4.5)
				pose["lh"] = _saya_mouth() + Vector2(-1, 0.6)
			else:
				# 2막: 칼을 털고(지부리) 겨눔으로
				var flick := sin(minf(k * 2.0, 1.0) * PI)
				pose.merge({"crouch": lerpf(0.6, 0.1, k), "spread": lerpf(20.0, 12.0, k), "ang": 0.62 + flick * 0.6, "rate": 12.0}, true)
		S.IAI_REST, S.TRI_REST, S.WAVE_REST, S.RAIN_REST:
			pose["eyes"] = 1.0
			pose["lean"] = 0.0
			pose["rate"] = 6.0
		S.TRI_WIND:
			var k := smoothstep(0.0, 0.6, st_t / _wind(TRI_WIND))
			pose.merge({"crouch": 0.6 * k, "lean": 0.25 * k, "spread": 11.0 + 7.0 * k, "rate": 16.0}, true)
			if drawn:
				pose["rh"] = Vector2(1, -43) # 핫소: 칼을 어깨 위로 세움
				pose["ang"] = -2.2
				pose["lh"] = Vector2(2, -40)
			else:
				pose["grip"] = true
				pose["rh"] = _saya_mouth() - _saya_dir() * 4.5
				pose["lh"] = _saya_mouth() + _saya_dir() * 2.5
				pose["saya"] = 0.1
		S.TRI_CUT:
			var gap: float = TRI_GAP[p()]
			var held := st_t < gap * 0.55
			pose.merge({"crouch": 0.65, "lean": 0.22, "spread": 19.0, "rate": 18.0}, true)
			if held:
				pose["rh"] = pz_rh
				pose["ang"] = pz_ang
				pose["out"] = 1.0
			elif has_sheath:
				pose["grip"] = true
				pose["rh"] = _saya_mouth() - _saya_dir() * 4.5
				pose["out"] = 0.0
				pose["out_now"] = true
			else:
				pose["rh"] = Vector2(1, -43)
				pose["ang"] = -2.2 if _k != 0 else 1.2
			pose["lh"] = _saya_mouth() + _saya_dir() * 2.5 if has_sheath else Vector2(-5, -28)
		S.WAVE_WIND:
			var k := smoothstep(0.0, 0.5, st_t / _wind(WAVE_WIND))
			pose.merge({"crouch": 1.0 * k, "lean": 0.45 * k, "spread": 11.0 + 10.0 * k, "rate": 16.0}, true)
			if drawn:
				pose["rh"] = Vector2(-2, -18)
				pose["ang"] = PI - 0.25
				pose["lh"] = Vector2(4, -25)
			else:
				pose["grip"] = true
				pose["saya"] = 0.55
				pose["rh"] = _saya_mouth() - _saya_dir() * 4.5
				pose["lh"] = _saya_mouth() + _saya_dir() * 2.5
		S.WAVE_CUT:
			pose.merge({"crouch": 0.5, "lean": 0.1, "spread": 18.0, "rh": pz_rh, "ang": pz_ang, "out": 1.0, "rate": 20.0}, true)
			pose["lh"] = _saya_mouth() + Vector2(-1, 1) if has_sheath else Vector2(-5, -27)
		S.CTR_STANCE, S.CTR_RELAX:
			var on := st == S.CTR_STANCE
			pose.merge({"crouch": 0.3 if on else 0.1, "lean": 0.02, "eyes": 0.0 if on else 1.0, "bow": 0.5 if on else 0.0, "spread": 14.0 if on else 11.0, "rate": 9.0}, true)
			if drawn:
				pose["rh"] = Vector2(7, -33) # 칼끝을 땅으로 곧게 내림 — 기다리는 자세
				pose["ang"] = PI * 0.5
				pose["lh"] = Vector2(6, -35)
			else:
				pose["grip"] = on
				pose["rh"] = _saya_mouth() - _saya_dir() * 4.5 if on else idle_rh
				pose["lh"] = _saya_mouth() + _saya_dir() * 2.0
				pose["saya"] = 0.02 if on else 0.3
		S.CTR_VANISH:
			pose["rate"] = 30.0
		S.PHASE:
			return _pose_phase(pose)
		S.LEAP_WIND:
			var k := smoothstep(0.0, 0.6, st_t / LEAP_WIND)
			pose.merge({"crouch": 1.0 * k, "lean": 0.15 * k, "spread": 15.0, "rh": Vector2(3, -47), "ang": -PI * 0.5 - 0.2, "lh": Vector2(3, -44), "rate": 14.0}, true)
		S.LEAP_UP, S.LEAP_HANG, S.LEAP_FALL:
			pose.merge({"crouch": 0.2, "lean": 0.05, "air": 1.0, "rh": Vector2(4, -33), "ang": PI * 0.5, "lh": Vector2(4, -37), "rate": 16.0}, true)
			if st == S.LEAP_UP:
				pose["rh"] = Vector2(4, -49)
				pose["ang"] = -PI * 0.5
				pose["lh"] = Vector2(4, -46)
		S.LEAP_REST:
			pose.merge({"crouch": 1.0, "kneel": 0.6, "lean": 0.3, "rh": Vector2(10, -18), "ang": PI * 0.5 - 0.08, "lh": Vector2(10, -20), "spread": 16.0, "rate": 30.0}, true)
		S.SHADOW_WIND:
			# 발도 자세로 웅크려 칼을 몸 뒤로 감춤 — 이 그림이 그대로 분신이 된다
			var k := smoothstep(0.0, 0.5, st_t / SHADOW_WIND)
			pose.merge({"crouch": 1.0 * k, "lean": 0.38 * k, "spread": 11.0 + 9.0 * k, "rh": Vector2(-1, -22), "ang": PI - 0.35, "lh": Vector2(3, -27), "rate": 18.0}, true)
		S.SHADOW_HOLD:
			# 칼끝을 뒤로 낮게 늘어뜨린 채 분신들을 지켜봄
			pose.merge({"crouch": 0.2, "lean": -0.04, "rh": Vector2(6, -21), "ang": PI * 0.62, "lh": Vector2(-2, -21), "spread": 12.0, "rate": 6.0}, true)
		S.RAIN_WIND, S.RAIN_HOLD:
			var k := smoothstep(0.0, 0.5, st_t / RAIN_WIND) if st == S.RAIN_WIND else 1.0
			pose.merge({"crouch": 0.1, "lean": -0.08 * k, "rh": Vector2(4, -29).lerp(Vector2(3, -55), k), "ang": lerpf(0.6, -PI * 0.5, k),
				"lh": Vector2(-3, -23), "spread": 13.0, "rate": 12.0}, true)
		S.VICTOR:
			pose.merge({"eyes": 0.0, "bow": 0.3, "rate": 3.0}, true)
	return pose


func _pose_phase(pose: Dictionary) -> Dictionary:
	var tt := st_t
	if tt < 0.6:
		pose.merge({"eyes": 0.0, "bow": 0.5, "crouch": 0.0, "rate": 5.0}, true)
	elif tt < 1.0:
		pose.merge({"eyes": 0.0, "crouch": 0.35, "lean": 0.1, "grip": true, "rh": _saya_mouth() - _saya_dir() * 4.5,
			"lh": _saya_mouth() + _saya_dir() * 2.5, "saya": 0.1, "rate": 10.0}, true)
	elif tt < PHASE_DRAW_AT:
		# 천천히 위로 뽑아 올림
		var k := smoothstep(1.0, PHASE_DRAW_AT, tt)
		pose.merge({"eyes": 1.0, "crouch": 0.35 - 0.3 * k, "lean": 0.1 - 0.15 * k, "out": 1.0, "out_now": true,
			"rh": Vector2(6, -29).lerp(Vector2(7, -49), k), "ang": lerpf(0.0, -1.35, k), "lh": _saya_mouth() + Vector2(-1, 1), "rate": 30.0}, true)
	else:
		var k := smoothstep(PHASE_DRAW_AT + 0.6, PHASE_T, tt)
		pose.merge({"eyes": 1.0, "crouch": 0.05, "lean": -0.05 * (1.0 - k), "out": 1.0,
			"rh": Vector2(7, -49).lerp(Vector2(9, -26), k), "ang": lerp_angle(-1.35, 0.62, k), "lh": Vector2(-4, -33).lerp(Vector2(-2, -22), k), "rate": 8.0}, true)
	return pose


## 쓰러짐: 뒤로 물러섬 → 무릎 → 칼을 털고 → 천천히 거둠(딸깍) → 먹빛 꽃잎으로 흩어짐
func _pose_defeat(drawn: bool) -> Dictionary:
	var tt := dead_t
	var pose := {"crouch": 0.3, "lean": -0.2, "rh": pz_rh, "lh": Vector2(-2, -23), "out": 1.0, "ang": 0.62, "spread": 13.0, "eyes": 1.0, "rate": 8.0}
	if tt < 0.4:
		return pose
	pose.merge({"kneel": 1.0, "crouch": 0.3, "lean": 0.15}, true)
	var mouth := _saya_mouth() if has_sheath else Vector2(2, -18)
	var sdir := _saya_dir() if has_sheath else Vector2(-0.96, 0.28)
	if tt < 1.2:
		pose["rh"] = Vector2(12, -23)
		pose["ang"] = 0.3
		return pose
	if tt < 1.8:
		var k := smoothstep(1.2, 1.8, tt)
		pose["rh"] = Vector2(12, -23)
		pose["ang"] = 0.3 + sin(k * PI) * 0.9 # 칼을 털어 냄
		pose["rate"] = 20.0
		return pose
	# 칼집(또는 쥔 왼손) 축을 따라 천천히 넣는다
	var k2 := smoothstep(1.8, 2.8, tt)
	var out := 1.0 - k2
	pose["out"] = out
	pose["out_now"] = true
	pose["ang"] = sdir.angle()
	pose["rh"] = mouth - sdir * (BLADE_L * out + 4.5)
	pose["lh"] = mouth + Vector2(-1, 0.6)
	pose["rate"] = 40.0
	pose["bow"] = smoothstep(2.6, 3.2, tt)
	pose["eyes"] = 1.0 - smoothstep(2.8, 3.1, tt)
	if not drawn:
		pose["saya"] = 0.3
	return pose


## 쓰러짐 연출: 칼을 다 거두면 딸깍 → 먹빛 꽃잎으로 흩어지며 사라짐
func _defeat_tick() -> void:
	pz_alpha = 1.0 - smoothstep(3.0, DEFEAT_T - 0.2, dead_t)
	if not _defeat_click and dead_t >= 2.8:
		_defeat_click = true
		Sfx.play_pitch(&"kb_sheath", 0.9, 0.0)
		_glint = 1.0
		_glint_at = _saya_mouth() if has_sheath else Vector2(2, -18)
		if is_instance_valid(_sheath_node) and _sheath_node.has_method("vanish"):
			_sheath_node.call("vanish")
	if dead_t >= 2.9 and dead_t < DEFEAT_T - 0.4 and randf() < 0.6:
		EKenseiFx.petals(global_position + Vector2(0, -18), 2, Vector2(8, 16), 50.0)


# 칼집: 허리 앞(입구)에서 뒤로 비스듬히 아래로
func _saya_mouth() -> Vector2:
	return _hip() + Vector2(3.5, 1.0)


func _saya_dir() -> Vector2:
	return Vector2(-cos(pz_saya), sin(pz_saya))


func _hip() -> Vector2:
	return Vector2(-0.5 + pz_crouch * 1.0, HIP_Y + pz_crouch * 7.0 + pz_kneel * 11.0)


## 칼의 날밑(칼코등이) 자리와 칼 방향 (몸 기준)
func _tsuba() -> Array:
	if pz_out <= 0.001 and has_sheath:
		return [_saya_mouth(), _saya_dir()]
	var b := Vector2.from_angle(pz_ang)
	return [pz_rh + b * 2.5, b]


## 자세 이름 (eval용)
func info() -> String:
	return "st=%s hp=%d/%d poise=%d break=%.2f phase=%d x=%d y=%d" % [S.keys()[st], hp, max_hp, int(poise), break_t, phase, int(global_position.x), int(global_position.y)]


# ─── 흔들리는 줄: 머리칼·겉옷 자락·칼집 끈 ───────────────

func _g(v: Vector2) -> Vector2:
	return global_position + Vector2(v.x * float(facing), v.y)


func _up() -> Vector2:
	var lean := pz_lean + pz_kneel * 0.08
	return Vector2(sin(lean), -cos(lean))


## 어깨 가운데 (몸 기준)
func _shoulder() -> Vector2:
	return _hip() + _up() * TORSO


func _head() -> Vector2:
	return _hip() + _up() * (TORSO + 7.2) + Vector2(1.0 + pz_bow * 1.6, pz_bow * 2.2)


## 묶은 머리 매듭 (정수리 뒤)
func _hair_root() -> Vector2:
	return _head() + Vector2(-2.8, -4.2)


func _tail_root() -> Vector2:
	return _hip() + Vector2(-4.0, 0.0)


func _cord_root() -> Vector2:
	return _saya_mouth() + _saya_dir() * 6.0


func _rest_hair() -> PackedVector2Array:
	var r := PackedVector2Array()
	var p := _hair_root()
	for i in HAIR_N:
		r.append(_g(p))
		var f := float(i) / float(HAIR_N)
		p += Vector2(-1.6 + f * 0.8, 2.2 + f * 0.6)
	return r


func _rest_line(root: Vector2, n: int, step: Vector2, curl := Vector2.ZERO) -> PackedVector2Array:
	var r := PackedVector2Array()
	var p := root
	for i in n:
		r.append(_g(p))
		p += step + curl * float(i)
	return r


func _rest_tail() -> PackedVector2Array:
	return _rest_line(_tail_root(), TAIL_N, Vector2(-1.4, 3.3), Vector2(-0.3, -0.05))


func _rest_lining() -> PackedVector2Array:
	return _rest_line(_tail_root() + Vector2(2.0, 1.0), TAIL_N - 2, Vector2(-0.8, 3.4), Vector2(-0.25, 0.0))


func _rest_cord() -> PackedVector2Array:
	return _rest_line(_cord_root(), 5, Vector2(-0.4, 2.4))


func _ensure_chains() -> void:
	if _chains_ready:
		return
	_chains_ready = true
	_hair = EArt.Chain.new()
	_hair.setup(_rest_hair(), HAIR_SEG)
	_tail_a = EArt.Chain.new()
	_tail_a.setup(_rest_tail(), TAIL_SEG)
	_tail_b = EArt.Chain.new()
	_tail_b.setup(_rest_lining(), TAIL_SEG)
	_cord = EArt.Chain.new()
	_cord.setup(_rest_cord(), 2.4)


func _reset_chains() -> void:
	if not _chains_ready:
		return
	_hair.snap_to(_rest_hair())
	_tail_a.snap_to(_rest_tail())
	_tail_b.snap_to(_rest_lining())
	_cord.snap_to(_rest_cord())
	_trail.clear()


func _tick_chains(delta: float) -> void:
	_ensure_chains()
	var dt := minf(delta, 1.0 / 30.0)
	_gust = 0.5 + 0.5 * sin(t * 0.9) * sin(t * 2.3 + 1.0)
	var w := EKenseiFx.wind * (0.75 + 0.5 * _gust)
	var lift := 50.0 * _aura # 2막: 기운에 머리칼·자락이 살짝 떠오름
	var mv := Vector2(-velocity.x * 1.4, -velocity.y * 0.4)
	var grav := Vector2(w.x * 3.2, 300.0 - lift) + mv
	var flow := Vector2(w.x * 2.2 * (0.7 + 0.6 * sin(t * 3.1)), -50.0)
	_hair.step(_g(_hair_root()), _rest_hair(), grav + flow + Vector2(w.x * 2.0, -40.0), dt, 0.9, 0.025)
	_tail_a.step(_g(_tail_root()), _rest_tail(), grav + flow, dt, 0.9, 0.045)
	_tail_b.step(_g(_tail_root() + Vector2(2.0, 1.0)), _rest_lining(), grav + flow * 0.8, dt, 0.9, 0.05)
	_cord.step(_g(_cord_root()), _rest_cord(), grav, dt, 0.84, 0.1)


## 칼이 빠르게 움직이면 궤적을 남긴다 (붉은 잔광) — 천천히 움직이면 꼬리가 줄어듦
func _tick_trail() -> void:
	var ts := _tsuba()
	var tsu: Vector2 = ts[0]
	var b: Vector2 = ts[1]
	var a := _g(tsu + b * 8.0)
	var tip := _g(tsu + b * BLADE_L * pz_out)
	var moved := tip.distance_to(_last_tip)
	var prev_a := _last_a
	var prev_tip := _last_tip
	_last_tip = tip
	_last_a = a
	if pz_out < 0.5 or pz_alpha < 0.5 or moved < TRAIL_MIN or moved > 400.0:
		if _trail.size() > 0:
			_trail = _trail.slice(2) if _trail.size() > 2 else PackedVector2Array()
		return
	if _trail.is_empty():
		_trail.append(prev_a)
		_trail.append(prev_tip)
	_trail.append(a)
	_trail.append(tip)
	if _trail.size() > 12:
		_trail = _trail.slice(_trail.size() - 12)


## 지금 그림의 흰 그림자를 off(전역 x 차이)만큼 옮겨 남김
func _afterimage(off: Vector2, life: float) -> void:
	if _snap_i.is_empty():
		return
	var ai := EVfx.Afterimage.new()
	ai.v = _snap_v
	ai.idx = _snap_i
	ai.life = life
	ai.tint = EKenseiFx.BONE
	ai.strength = 1.2
	ai.z_index = -4
	ai.material = Fx.add_material
	Fx.effect_parent().add_child(ai)
	ai.global_transform = global_transform.translated(off)


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

## 두 뼈 팔·다리: 뿌리 s에서 끝 e까지, 길이 a·b, 굽는 쪽 bend(+1/-1) → 관절 자리
static func _ik(s: Vector2, e: Vector2, a: float, b: float, bend: float) -> Vector2:
	var d := e - s
	var l := clampf(d.length(), 0.01, a + b - 0.01)
	var ca := clampf((a * a + l * l - b * b) / (2.0 * a * l), -1.0, 1.0)
	var ang := d.angle() + acos(ca) * bend
	return s + Vector2.from_angle(ang) * a


func _paint_body(a0: float) -> void:
	_ensure_chains()
	var a := a0 * pz_alpha
	if a <= 0.01:
		_snap_v = PackedVector2Array()
		_snap_i = PackedInt32Array()
		return
	var hip := _hip()
	var up := _up()
	var fwd := Vector2(-up.y, up.x) # 몸 앞쪽 (기울기 따라)
	var sh := _shoulder()
	var head := _head()
	var inv := global_transform.affine_inverse()
	var to_l := _base # 몸 기준 → 이 노드 좌표 (뒤집힘 포함)

	# ── 1) 겉옷 안감(붉은 먹빛) · 겉옷 뒷자락 (전역 줄 → 이 노드 좌표, 뒤집힘 없이 그림)
	pd.draw_set_transform(Vector2.ZERO)
	var tail := inv * _tail_a.p
	var lining := inv * _tail_b.p
	_ribbon(lining, 7.0, 3.0, col(Color("#2a0a10"), a), col(CORD_DEEP, a * 0.8))
	# 자락 앞선(허리 앞 → 무릎 아래)과 뒷선(바람에 날리는 줄) 사이를 채움
	var front_edge := PackedVector2Array()
	var n := tail.size()
	var sway := sin(t * 2.2) * 0.8
	for i in n:
		var f := float(i) / float(n - 1)
		var p := hip + fwd * lerpf(2.0, 3.5 + sway * f, f) + Vector2(0, 2.0 + f * 19.0)
		front_edge.append(to_l * p)
	pd.strip(front_edge, tail, col(COAT, a))
	pd.draw_polyline(tail, col(RIM, a), 1.1)
	pd.draw_line(tail[n - 1], front_edge[n - 1], col(COAT_HI, a), 1.0) # 자락 끝단
	# 머리칼 (높이 묶은 긴 흰 머리 — 아래 그늘색 + 위 밝은 결)
	var hair := inv * _hair.p
	_ribbon(hair, 3.6, 0.8, col(HAIR_SH, a), Color(0, 0, 0, 0))
	var hl := PackedVector2Array()
	for i in hair.size():
		hl.append(hair[i] + Vector2(0, -0.5))
	_ribbon(hl, 2.0, 0.3, col(HAIR, a), Color(0, 0, 0, 0))
	# 끝이 갈라진 잔 머리 두 가닥 (바람에 따로 흔들림)
	var nh := hair.size()
	for sgn in [-1.0, 1.0]:
		var strand := PackedVector2Array()
		for i in range(nh / 2, nh):
			var f := float(i - nh / 2) / float(nh - nh / 2)
			strand.append(hair[i] + Vector2(sin(t * 3.0 + sgn * 1.7 + float(i)) * 1.2 * f, sgn * 1.6 * f))
		pd.draw_polyline(strand, col(HAIR_SH if sgn > 0.0 else HAIR, a * 0.9), 0.6)
	if has_sheath:
		pd.draw_polyline(inv * _cord.p, col(CORD, a), 1.0)
	xf()

	# ── 2) 칼집 (허리 왼쪽 → 뒤로 비스듬히)
	if has_sheath:
		var m := _saya_mouth()
		var sd := _saya_dir()
		var sn := sd.orthogonal()
		var e := m + sd * SAYA_L
		pd.draw_colored_polygon(PackedVector2Array([m + sn * 2.0, e + sn * 1.5, e + sd * 1.6, e - sn * 1.5, m - sn * 2.0]), col(INK, a))
		pd.draw_line(m + sn * 1.0 + sd * 3.0, e + sn * 0.7, col(Color("#4a3f44"), a), 0.8) # 옻칠 윤
		pd.draw_line(e - sd * 1.2, e + sd * 1.4, col(HAIR_SH, a), 3.0) # 끝 장식
		pd.draw_line(m + sd * 0.2, m + sd * 2.2, col(HAIR, a), 4.0) # 입구 고리 (뼈빛)
		pd.draw_line(m + sd * 6.0 + sn * 2.2, m + sd * 6.0 - sn * 2.2, col(CORD, a), 1.2) # 끈 매는 자리

	# ── 3) 뒤 팔 (왼손)
	var sb := sh - fwd * 2.6 + up * -0.6
	var elb := _ik(sb, pz_lh, ARM_A, ARM_B, 1.0)
	pd.line2(sb, elb, col(HAKAMA_SH, a), col(HAKAMA_SH, a), 4.6, 4.0)
	pd.line2(elb, pz_lh, col(HAKAMA_SH, a), col(HAKAMA_SH, a), 3.8, 3.2)
	pd.draw_circle(pz_lh, 1.6, col(SKIN_SH, a))

	# ── 4) 다리 (하카마: 아래로 넓게 퍼지는 바지)
	_legs(hip, fwd, a)

	# ── 5) 몸통: 검은 겉옷 (넓은 어깨 → 허리) + 흰 속옷 깃 + 허리띠·붉은 끈
	var shf := sh + fwd * 3.0
	var shb := sh - fwd * 4.0
	var torso := PackedVector2Array([hip - fwd * 4.6 + up * 1.0, shb + up * 0.2, sh + up * 1.0, shf + up * 0.4, shf + fwd * 1.6 - up * 3.0,
		hip + fwd * 4.8 + up * 5.0, hip + fwd * 4.6 + up * 0.5])
	pd.draw_colored_polygon(torso, col(COAT, a))
	pd.draw_line(hip - fwd * 4.6 + up * 1.0, shb + up * 0.2, col(RIM, a), 1.0) # 등 (달빛)
	pd.draw_line(shb + up * 0.2, sh + up * 1.0, col(RIM, a), 1.0) # 어깨 위
	pd.draw_line(sh - fwd * 1.0 - up * 2.0, hip - fwd * 1.5 + up * 3.0, col(COAT_HI, a), 0.7) # 등솔기
	# 흰 속옷 깃 (V) + 겉옷 깃
	var chest := hip + up * 8.0 + fwd * 2.4
	pd.draw_colored_polygon(PackedVector2Array([sh + fwd * 0.2 + up * 0.8, sh + fwd * 2.8 + up * 0.6, chest + fwd * 0.6, chest - fwd * 0.4]), col(HAIR, a))
	pd.draw_line(sh + fwd * 2.8 + up * 0.6, chest + fwd * 0.6, col(INK, a), 0.9)
	pd.draw_line(sh - fwd * 0.4 + up * 0.8, chest - fwd * 0.8 - up * 0.5, col(INK, a), 0.9)
	# 허리띠
	var belt := PackedVector2Array([hip - fwd * 4.8 + up * 3.0, hip + fwd * 5.0 + up * 3.0, hip + fwd * 5.0 - up * 0.6, hip - fwd * 4.8 - up * 0.6])
	pd.draw_colored_polygon(belt, col(Color("#2c2329"), a))
	pd.draw_line(hip - fwd * 4.8 + up * 1.2, hip + fwd * 5.0 + up * 1.2, col(CORD, a), 1.0)
	pd.draw_circle(hip + fwd * 4.4 + up * 1.2, 1.2, col(CORD, a))
	pd.line2(hip + fwd * 4.4 + up * 0.6, hip + fwd * (5.4 + sway * 0.4) - up * 4.0, col(CORD, a), col(CORD_DEEP, a), 0.9, 0.6)
	# 겉옷 앞자락 (앞다리 위로 늘어진 짧은 자락)
	pd.draw_colored_polygon(PackedVector2Array([hip + fwd * 4.8 + up * 0.5, hip + fwd * (6.0 + sway * 0.5) - up * 9.0, hip + fwd * (2.6 + sway * 0.5) - up * 10.5,
		hip + fwd * 0.8 - up * 0.5]), col(INK, a))
	pd.draw_line(hip + fwd * 4.8 + up * 0.5, hip + fwd * (6.0 + sway * 0.5) - up * 9.0, col(COAT_HI, a), 0.8)

	# ── 6) 머리
	_head_paint(head, a)

	# ── 7) 앞 팔 (오른손: 칼) — 넓은 소매가 아래로 늘어짐
	var sa := sh + fwd * 1.0 - up * 1.0
	var elf := _ik(sa, pz_rh, ARM_A, ARM_B, 1.0)
	pd.line2(sa, elf, col(COAT, a), col(COAT, a), 5.2, 4.6)
	pd.line2(elf, pz_rh, col(COAT, a), col(COAT, a), 4.4, 3.4)
	var fa := (pz_rh - elf)
	var hang := Vector2(0, 1).slerp(-fwd, 0.15) * 4.5
	pd.draw_colored_polygon(PackedVector2Array([elf, elf + fa * 0.75, elf + fa * 0.7 + hang, elf + hang * 0.6]), col(COAT, a)) # 소매 자락
	pd.draw_line(sa + Vector2(0, -2.2), elf + Vector2(0, -2.0), col(RIM, a * 0.8), 0.8)

	# ── 8) 칼 (칼날·날밑·붉은 끈 칼자루) + 손
	_sword_paint(a)
	pd.draw_circle(pz_rh, 1.7, col(SKIN, a))

	# ── 9) 서양식 철 견갑 (앞 어깨 한쪽, 팔을 따라 기욺)
	_pauldron(sa, (elf - sa).normalized(), fwd, up, a)

	# 잔상용 그림 (늘 최신)
	_snap_v = pd.v.duplicate()
	_snap_i = pd.idx.duplicate()
	_snap_c = pd.c.duplicate()
	if _ink > 0.01:
		_paint_ink_shroud(a)


## 먹물 속(분신이 서 있는 동안 무적): 몸을 감싸 소용돌이치는 먹빛 덩이 — 칼이 닿지 않음이 보이게
func _paint_ink_shroud(a: float) -> void:
	pd.draw_set_transform(Vector2.ZERO)
	var k := _ink * a
	for i in 9:
		var an := t * (1.2 + 0.1 * float(i)) + float(i) * 0.7
		var p := Vector2(cos(an) * 9.0, -24.0 + sin(an * 1.3) * 18.0)
		pd.glow(p, 10.0 + 3.0 * sin(t * 2.0 + float(i)), Color(0.04, 0.03, 0.05, 0.55 * k), 0.35 * k)
	pd.glow(Vector2(0, -24), 24.0, Color(0.03, 0.02, 0.04, 0.35 * k), 0.0)


## 줄을 띠로: 위 w0 → 끝 w1 굵기, 몸 색 + (투명하지 않으면) 위쪽 테두리 한 줄
func _ribbon(pts: PackedVector2Array, w0: float, w1: float, c: Color, edge: Color) -> void:
	var n := pts.size()
	if n < 2:
		return
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	for i in n:
		var pa := pts[maxi(i - 1, 0)]
		var pb := pts[mini(i + 1, n - 1)]
		var nrm := (pb - pa).normalized().orthogonal()
		var w := lerpf(w0, w1, float(i) / float(n - 1)) * 0.5
		l.append(pts[i] + nrm * w)
		r.append(pts[i] - nrm * w)
	pd.strip(l, r, c)
	if edge.a > 0.01:
		var top := l if (l[n / 2].y < r[n / 2].y) else r
		pd.draw_polyline(top, edge, 0.7)


func _legs(hip: Vector2, fwd: Vector2, a: float) -> void:
	var ff := Vector2(pz_spread * 0.55, 0.0)
	var fb := Vector2(-pz_spread * 0.45, 0.0)
	if absf(velocity.x) > 5.0 and is_on_floor() and st == S.WALK:
		var ph := t * 6.0
		ff.x += sin(ph) * 4.5
		fb.x -= sin(ph) * 4.5
		ff.y = -maxf(cos(ph), 0.0) * 2.0
		fb.y = -maxf(-cos(ph), 0.0) * 2.0
	if pz_air > 0.01:
		ff = ff.lerp(hip + Vector2(7.0, 17.0), pz_air)
		fb = fb.lerp(hip + Vector2(-6.0, 14.0), pz_air)
	var hf := hip + fwd * 2.0
	var hb := hip - fwd * 2.0
	var kf := _ik(hf, ff, LEG_A, LEG_B, -1.0)
	var kb := _ik(hb, fb, LEG_A, LEG_B, -1.0)
	if pz_kneel > 0.01:
		# 무릎 꿇음: 뒤 무릎이 땅에, 앞 다리는 세움
		var k := pz_kneel
		kb = kb.lerp(Vector2(-3.0, -1.5), k)
		fb = fb.lerp(Vector2(-15.0, -1.0), k)
		kf = kf.lerp(Vector2(9.0, -12.0), k)
		ff = ff.lerp(Vector2(9.0, 0.0), k)
	_leg(hb, kb, fb, col(HAKAMA_SH, a), a, false)
	_leg(hf, kf, ff, col(HAKAMA, a), a, true)


## 하카마 다리 하나: 허벅지는 곧고 정강이는 아래로 넓게 퍼짐 + 흰 버선발
func _leg(h: Vector2, k: Vector2, f: Vector2, c: Color, a: float, front: bool) -> void:
	pd.line2(h, k, c, c, 7.4, 6.8)
	var d := (f - k).normalized().orthogonal()
	var flare := PackedVector2Array([k + d * 3.4, f + d * 5.4 + Vector2(0, -0.6), f - d * 5.4 + Vector2(0, -0.6), k - d * 3.4])
	pd.draw_colored_polygon(flare, c)
	pd.draw_line(k, f + Vector2(0, -1.5), col(HAKAMA_SH if front else INK, a), 0.7) # 주름
	if front:
		pd.draw_line(k - d * 3.4, f - d * 5.4 + Vector2(0, -0.6), col(RIM, a * 0.7), 0.7)
	pd.draw_rect(Rect2(f + Vector2(-1.2, -1.6), Vector2(4.6, 1.6)), col(HAIR_SH if front else Color("#6e665e"), a))


func _head_paint(h: Vector2, a: float) -> void:
	# 뒤 머리 덩이 + 묶은 매듭(붉은 끈)
	pd.draw_circle(h + Vector2(-1.4, -0.6), 4.2, col(HAIR_SH, a))
	var knot := _hair_root()
	pd.draw_circle(knot, 2.1, col(HAIR, a))
	pd.draw_line(knot + Vector2(1.3, -1.8), knot + Vector2(0.9, 1.8), col(CORD, a), 1.3)
	pd.line2(knot + Vector2(1.0, 1.5), knot + Vector2(-0.5 + EKenseiFx.wind.x * float(facing) * 0.04, 6.0), col(CORD, a), col(CORD_DEEP, a), 0.9, 0.5) # 끈 꼬리
	# 얼굴 (갸름한 턱)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-1.6, -3.0), h + Vector2(3.0, -3.4), h + Vector2(4.4, -0.6), h + Vector2(4.0, 2.2),
		h + Vector2(2.4, 4.4), h + Vector2(0.4, 4.6), h + Vector2(-1.8, 2.2)]), col(SKIN, a))
	pd.draw_line(h + Vector2(4.2, 1.6), h + Vector2(2.6, 4.2), col(SKIN_SH, a), 0.8) # 턱선 그늘
	pd.draw_rect(Rect2(h + Vector2(-1.4, 2.6), Vector2(2.6, 1.4)), col(SKIN_SH, a)) # 목 그늘
	# 정수리·뒤로 빗어 넘긴 머리
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-4.8, 0.6), h + Vector2(-4.4, -3.0), h + Vector2(-1.8, -4.9), h + Vector2(1.8, -5.0),
		h + Vector2(4.2, -3.2), h + Vector2(4.6, -1.6), h + Vector2(2.4, -2.6), h + Vector2(-0.6, -2.0), h + Vector2(-2.2, 1.8)]), col(HAIR, a))
	pd.draw_line(h + Vector2(-3.6, -3.4), h + Vector2(2.4, -4.4), col(Color.WHITE, a * 0.9), 0.6)
	pd.draw_line(h + Vector2(-3.6, -0.8), h + Vector2(-0.8, -2.4), col(HAIR_SH, a), 0.6)
	# 앞머리 한 가닥 (얼굴 옆으로 길게 내려옴, 바람에 흔들림)
	var sway := sin(t * 2.6) * 0.5 + EKenseiFx.wind.x * float(facing) * 0.015
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(2.2, -4.0), h + Vector2(4.6, -3.0), h + Vector2(5.0 + sway, 1.6), h + Vector2(4.6 + sway * 1.6, 6.4),
		h + Vector2(3.6 + sway, 1.8), h + Vector2(3.0, -1.6)]), col(HAIR, a))
	# 눈 (감으면 먹선, 뜨면 흰 실눈) + 흰 눈썹
	var eye := h + Vector2(2.6, -0.6)
	if pz_eyes < 0.5:
		pd.draw_line(eye + Vector2(-1.2, 0.5), eye + Vector2(1.0, 0.7), col(INK, a), 0.9)
	else:
		pd.draw_colored_polygon(PackedVector2Array([eye + Vector2(-1.3, -0.5), eye + Vector2(1.2, -0.7), eye + Vector2(1.0, 0.5), eye + Vector2(-1.2, 0.4)]), col(INK, a))
		pd.draw_rect(Rect2(eye + Vector2(-0.1, -0.4), Vector2(1.0, 0.6)), Color(EKenseiFx.WHITE, a))
	pd.draw_line(eye + Vector2(-1.6, -1.6), eye + Vector2(1.4, -1.9), col(HAIR, a), 0.8)


func _sword_paint(a: float) -> void:
	var ts := _tsuba()
	var tsu: Vector2 = ts[0]
	var b: Vector2 = ts[1]
	var n := b.orthogonal()
	if pz_out > 0.001:
		var len := BLADE_L * pz_out
		# 땅에 꽂힌 칼은 땅 위만
		var tip := tsu + b * len
		if tip.y > 1.0 and b.y > 0.05:
			len = maxf((1.0 - tsu.y) / b.y, 0.0)
			tip = tsu + b * len
		var mid := tsu + b * len * 0.55 - n * 0.9 # 살짝 휜 날
		pd.draw_colored_polygon(PackedVector2Array([tsu + n * 1.3, mid + n * 0.9, tip, mid - n * 1.1, tsu - n * 1.1]), col(BLADE_C, a))
		pd.draw_line(tsu - n * 0.7, mid - n * 0.8, col(STEEL_SH, a), 0.7) # 칼등
		pd.draw_line(tsu + n * 0.8, tip, Color(EKenseiFx.WHITE, a), 0.7) # 날
		pd.draw_line(tsu + b * 1.0, tsu + b * 4.0, col(STEEL, a), 2.4) # 칼밑 덧쇠
	# 칼자루 (붉은 끈 감김) + 머리 장식 + 날밑
	var grip_end := tsu - b * 9.5
	pd.line2(tsu, grip_end, col(INK, a), col(INK, a), 3.0, 2.8)
	for i in 4:
		var p := tsu - b * (1.8 + float(i) * 2.0)
		pd.draw_line(p + n * 1.2, p - b * 1.2 - n * 1.2, col(CORD, a), 0.9)
	pd.draw_line(grip_end, grip_end - b * 1.5, col(HAIR, a), 3.0)
	pd.draw_colored_polygon(PackedVector2Array([tsu + n * 3.0, tsu + n * 3.0 + b * 1.2, tsu - n * 3.0 + b * 1.2, tsu - n * 3.0]), col(INK, a))
	pd.draw_line(tsu + n * 2.8 + b * 1.2, tsu - n * 2.8 + b * 1.2, col(STEEL, a), 0.6)


## 서양식 철 견갑 두 겹: 어깨 관절 s를 덮는 둥근 판(가로축 fwd, 위쪽 up)이 팔 방향 d로 살짝 내려가며 겹침
func _pauldron(s: Vector2, d: Vector2, fwd: Vector2, up: Vector2, a: float) -> void:
	for i in range(1, -1, -1):
		var c := s + d * (float(i) * 2.0 + 0.4) + up * 0.6
		var w := 3.6 - float(i) * 0.6
		var hgt := 2.6 - float(i) * 0.4
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for j in 9:
			var an := PI * float(j) / 8.0
			outer.append(c + fwd * (cos(an) * w) + up * (sin(an) * hgt))
			inner.append(c + fwd * (cos(an) * (w - 0.8)) + up * (sin(an) * (hgt - 0.8)))
		outer.append(c - up * 0.9 - fwd * w * 0.8)
		outer.append(c - up * 0.9 + fwd * w * 0.8)
		pd.draw_colored_polygon(outer, col(STEEL_SH, a))
		pd.draw_colored_polygon(inner, col(STEEL, a))
		pd.draw_polyline(inner.slice(2, 7), col(STEEL_HI, a), 0.7)
	pd.draw_circle(s + up * 2.2 + fwd * 1.0, 0.5, col(Color.WHITE, a)) # 징
	pd.line2(s - fwd * 2.8 + up * 0.2, s - fwd * 3.0 - up * 3.4, col(CORD, a), col(CORD_DEEP, a), 0.9, 0.6) # 붉은 매듭 끈


## 빛(가산) 층: 번뜩임 · 눈빛 · 칼빛과 붉은 잔광 · 2막 기운 · 반격 고리 · 낙화 표식
func _paint_shine(q: PDraw) -> void:
	var a := pz_alpha
	if is_dead():
		a *= 1.0 - smoothstep(2.6, 3.4, dead_t)
	# 궤적: 붉은 잔광 (전역 → 이 노드)
	var n := _trail.size() / 2
	if n >= 2:
		q.draw_set_transform(Vector2.ZERO)
		var l := PackedVector2Array()
		var r := PackedVector2Array()
		for i in n:
			l.append(_trail[i * 2] - global_position)
			r.append(_trail[i * 2 + 1] - global_position)
		q.strip_grad(l, r, Color(EKenseiFx.RED, 0.0), Color(EKenseiFx.RED_HOT, 0.55 * a))
		q.draw_line(r[n - 2], r[n - 1], Color(EKenseiFx.WHITE, 0.8 * a), 1.2)
	q.draw_set_transform_matrix(_base)
	var head := _head()
	# 2막 기운: 몸에서 올라가는 흰·붉은 실 + 칼빛
	if _aura > 0.01:
		var au := _aura * a
		q.glow(Vector2(0, -22), 26.0, Color(EKenseiFx.RED, 0.12 * au), 0.0)
		for i in 5:
			var f := fmod(t * 0.7 + float(i) * 0.2, 1.0)
			var x := sin(float(i) * 2.4 + t * 1.3) * 8.0
			var y := -4.0 - f * 50.0
			q.line2(Vector2(x, y), Vector2(x + EKenseiFx.wind.x * float(facing) * 0.06 * f, y - 8.0), Color(EKenseiFx.RED_HOT, 0.0), Color(EKenseiFx.RED_HOT if i % 2 == 0 else EKenseiFx.WHITE, 0.4 * au * (1.0 - f)), 1.0, 0.4)
		if pz_out > 0.5:
			var ts := _tsuba()
			var tsu: Vector2 = ts[0]
			var b: Vector2 = ts[1]
			var pulse := 0.7 + 0.3 * sin(t * 4.0)
			q.line2(tsu + b * 3.0, tsu + b * BLADE_L * 0.98, Color(EKenseiFx.RED, 0.25 * au * pulse), Color(EKenseiFx.WHITE, 0.4 * au * pulse), 4.0, 1.0)
	# 발도 일섬 예고: 허리 높이로 앞으로 뻗는 가는 기척선 (번뜩임이 가까울수록 짙어짐)
	if st == S.IAI_WIND:
		var k := smoothstep(0.35, 1.0, st_t / _wind(IAI_WIND))
		if k > 0.0:
			var y := (IAI_BAND.x + IAI_BAND.y) * 0.5 - 2.0
			var reach := _iai_reach
			q.line2(Vector2(10, y), Vector2(10.0 + reach * k, y), Color(EKenseiFx.WHITE, 0.4 * k * a), Color(EKenseiFx.RED, 0.0), 1.0, 0.5)
	# 번뜩임 (예고)
	if _glint > 0.0:
		var g := _glint / _glint_s
		q.glow(_glint_at, 14.0 * _glint, Color(EKenseiFx.WHITE, 0.2 * _glint * a), 0.0)
		EKenseiFx.star(q, _glint_at, g, _glint_s, minf(g * 1.4, 1.0) * a)
	# 눈빛
	var eye := head + Vector2(2.4, -0.4)
	if pz_eyes > 0.5:
		var ea := 0.35 + _eye_glint * 0.65
		if st in [S.IAI_WIND, S.CTR_WIND, S.TRI_WIND, S.WAVE_WIND, S.LEAP_HANG]:
			ea = 0.9
		q.glow(eye + Vector2(0.4, 0), 3.5 + _eye_glint * 4.0, Color(EKenseiFx.WHITE, 0.45 * ea * a), 0.0)
		if _eye_glint > 0.05:
			q.line2(eye, eye + Vector2(10.0 * _eye_glint, -0.6), Color(EKenseiFx.WHITE, _eye_glint * a), Color(EKenseiFx.RED, 0.0), 1.0)
	# 반격 자세: 발밑 큰 고리(조여듦) + 몸을 두른 끊긴 타원이 돎 — 이때 때리면(누르고 있기 베기 포함) 받아친다
	if _ring > 0.01:
		var rr := CTR_RING_R + CTR_RING_FROM * (1.0 - _ring)
		var pulse := 0.7 + 0.3 * sin(t * 9.0)
		var ra := _ring * a
		q.draw_set_transform_matrix(_base * Transform2D(0.0, Vector2(1.0, 0.28), 0.0, Vector2(0, -1)))
		q.glow(Vector2.ZERO, rr, Color(EKenseiFx.RED, 0.16 * ra * pulse), 0.0)
		q.draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, Color(EKenseiFx.RED_HOT, 0.85 * ra * pulse), 2.0)
		q.draw_arc(Vector2.ZERO, rr - 6.0, 0.0, TAU, 48, Color(EKenseiFx.WHITE, 0.45 * ra), 1.0)
		q.draw_set_transform_matrix(_base)
		# 몸을 두른 타원: 끊긴 호 넷이 천천히 돌며, 다 그려지면(받아칠 준비) 밝아짐
		var gc := Vector2(0, CTR_GUARD_Y)
		var ready_k := 1.0 if _ring >= 1.0 else 0.55
		for i in CTR_GUARD_ARCS:
			var a0 := t * 1.6 + TAU * float(i) / float(CTR_GUARD_ARCS)
			var pts := PackedVector2Array()
			for k in 9:
				var an := a0 + 0.9 * _ring * float(k) / 8.0
				pts.append(gc + Vector2(cos(an) * CTR_GUARD.x, sin(an) * CTR_GUARD.y))
			q.draw_polyline(pts, Color(EKenseiFx.RED_HOT, 0.8 * ra * pulse * ready_k), 1.4)
		q.glow(gc, CTR_GUARD.x * 1.1, Color(EKenseiFx.RED, 0.14 * ra * pulse), 0.0)
		var hg := Vector2(5, -20)
		q.glow(hg, 12.0, Color(EKenseiFx.RED, 0.35 * ra * pulse), 0.0)
	# 낙화: 떨어질 자리 표식
	if st in [S.LEAP_UP, S.LEAP_HANG, S.LEAP_FALL]:
		var gy := _floor_y() - global_position.y
		var mx := _leap_x - global_position.x
		q.draw_set_transform(Vector2(mx, gy), 0.0, Vector2(1.0, 0.3))
		var lk := 1.0 if _leap_lock else 0.55 + 0.25 * sin(t * 20.0)
		q.draw_arc(Vector2.ZERO, LEAP_REACH, 0.0, TAU, 40, Color(EKenseiFx.RED, 0.45 * lk), 1.0)
		q.draw_arc(Vector2.ZERO, LEAP_CORE, 0.0, TAU, 24, Color(EKenseiFx.WHITE, 0.8 * lk), 1.5)
		q.glow(Vector2.ZERO, LEAP_CORE * 1.2, Color(EKenseiFx.RED_HOT, 0.35 * lk), 0.0)
		q.draw_set_transform(Vector2.ZERO)
		if st == S.LEAP_FALL or _leap_lock:
			q.line2(Vector2(mx, gy), Vector2(mx, -40.0), Color(EKenseiFx.WHITE, 0.5 * lk), Color(EKenseiFx.WHITE, 0.0), 2.0, 0.5)
	q.draw_set_transform(Vector2.ZERO)


func _floor_y() -> float:
	var stage := get_parent()
	if stage and stage.get("floor_y") != null:
		return float(stage.get("floor_y"))
	return global_position.y


## 빛 층 노드 (가산 섞기) — 검성 자식
class Shine extends PDraw.Canvas:
	var k: EKensei

	func _process(_delta: float) -> void:
		queue_redraw()

	func _paint() -> void:
		if is_instance_valid(k):
			k._paint_shine(pd)


## 그림자 일섬의 분신: 검성의 웅크린 발도 자세를 먹빛 잔상으로 (붉은 끈만 또렷). 표적(ETarget)이라 베기·마법·물약·틈 달이기·흑성 끌림을 다 받는다.
## 체력 860(천열 한 번이 줄 전체에 걸리면 셋 다 베임), 버팀 없음, 넉백 없음. 나타난 뒤 POSE_T(+순서마다 조금씩)초 자세 → 일섬선(EKenseiFx.ShadowCut)을 긋고, CUT_DELAY 뒤 늦게 터지며 피해 1.
## 묶이거나 굳으면(속박·비명·봉공) 자세 시간도 멈춘다. 베어 없애면 아직 터지지 않은 일섬선도 사라진다(검성이 버팀 −500을 받음 — EKensei._on_shadow_died).
class Shadow extends EEnemy:
	const GROUP := &"kensei_shadow"
	const HP := 1200 ## loop6: 천열 하나(896)로는 약 300 남음 → 두 번째 도구(메아리·속박·부식·흑성·유성우)가 필요 — 서로 다른 정답 (loop5 1600 → 900 → 860 → 1200)
	const POSE_T := 1.6 ## 나타난 뒤 일섬까지 (예고)
	const CUT_DELAY := 0.45 ## 일섬선을 긋고 터지기까지
	const CUT_HALF := 45.0 ## 일섬선 반 길이 (분신 사이 70 → 이웃과 살짝 겹쳐 한 줄)
	const APPEAR := 0.3 ## 먹물이 모여 나타나는 시간
	const FADE := 0.4 ## 사라지는 시간
	const INK_A := 1.0 ## 먹빛 몸 진하기 (불투명 — 밑에 깐 붉은 테두리 빛이 몸 안으로 비치지 않게)
	const GLINT_LAST := 0.4 ## 일섬 이만큼 전부터 칼코등이 번뜩임
	const POOL_R := 16.0 ## 발밑 먹물 웅덩이 반지름
	const Z_BEHIND := -1 ## 에스카(0) 뒤
	const STILL_VULN := 1.4 ## 봉공으로 굳은 분신이 받는 피해 배수 (loop8 2장)
	const PULL_HOLD := 0.1 ## 흑성이 끄는 동안(매 프레임 다시 걸림) + 이만큼 자세 시간 멈춤
	var boss: EKensei
	var src_v := PackedVector2Array()
	var src_i := PackedInt32Array()
	var src_c := PackedColorArray()
	var src_facing := 1
	var order := 0
	var rim_tex: Texture2D ## 검성이 한 번 구운 붉은 테두리 빛 (그림 좌표 rim_rect)
	var rim_rect := Rect2()
	var _still_t := 0.0 ## 봉공으로 굳은 남은 시간 (그동안 받는 피해 ×STILL_VULN)
	var _pulled := 0.0 ## 흑성에 끌리는 중 남은 시간 — 그동안 자세 시간이 멈춤 (속박과 같은 규칙)
	signal returned(sh: Node2D) ## 일섬을 마치고 살아 돌아감 (검성 버팀 회복)
	var expired := false ## 일섬을 마치고 스스로 사라짐 (버팀 피해 없음)
	var _left := POSE_T
	var _age := 0.0
	var _cut: Node
	var _ink := PackedColorArray() ## 먹빛으로 바꾼 색 (붉은 끈만 그대로)
	var _wisp := 0.0

	func _init() -> void:
		max_hp = HP
		size = EKensei.BODY
		knock_resist = 1.0
		contact_dmg = 0
		spawn_fx = false
		spawn_t = 0.0
		death_time = FADE
		death_squash = false
		show_bar = true

	func _ready() -> void:
		super._ready()
		add_to_group(GROUP)
		add_to_group(EKenseiFx.GROUP) # 장면이 처음부터 할 때·검성이 쓰러질 때 같이 거둠
		z_index = Z_BEHIND # 에스카 몸 뒤에 (loop8 4장)
		_left = POSE_T + EKensei.SHADOW_STAGGER * float(order)
		_ink.resize(src_c.size())
		for i in src_c.size():
			var c := src_c[i]
			if c.r > 0.4 and c.r > c.g * 1.8 and c.r > c.b * 1.8:
				_ink[i] = c # 붉은 끈은 또렷하게
			else:
				var l := c.get_luminance()
				_ink[i] = Color(0.05 + l * 0.22, 0.04 + l * 0.18, 0.06 + l * 0.22, INK_A * c.a)
		EKenseiFx.petals(center(), 8, Vector2(8, 18), 60.0)
		Sfx.play_pitch(&"kb_glint", 0.7 + 0.08 * float(order), -12.0)

	## 흑성: 강자가 아니라 그대로 끌려감 (넉백 버팀과 상관없이)
	## 봉공: 굳는 동안 받는 피해가 늘어남
	func freeze(sec: float) -> void:
		super.freeze(sec)
		_still_t = sec

	func unbind() -> void:
		super.unbind()
		_still_t = 0.0

	func take_hit(dmg: int, from: Vector2, opts := {}) -> void:
		if _still_t > 0.0:
			dmg = int(round(float(dmg) * STILL_VULN))
		super.take_hit(dmg, from, opts)

	func pull(point: Vector2, strength: float, delta: float) -> void:
		var to := point - center()
		global_position.x += clampf(to.x, -strength * delta, strength * delta)
		_pulled = PULL_HOLD # 끌려 드는 동안 자세 시간 멈춤 (loop7: 흑성으로 모아서 끝내기)

	func _think(delta: float) -> void:
		velocity.x = 0.0
		if _cut != null:
			return
		if _pulled > 0.0:
			_pulled -= delta
			return
		_left -= delta
		if _left <= 0.0:
			_fire()

	func _physics_process(delta: float) -> void:
		_age += delta
		_still_t = maxf(_still_t - delta, 0.0)
		super._physics_process(delta)
		if not is_dead():
			_wisp -= delta
			if _wisp <= 0.0:
				_wisp = 0.12
				PParticles.get_layer(false).spawn(global_position + Vector2(randf_range(-8, 8), -randf_range(4, 44)), Vector2(randf_range(-6, 6), -randf_range(14, 30)), Vector2.ZERO,
					randf_range(0.4, 0.7), randf_range(2.0, 3.5), Color(0.06, 0.05, 0.07, 0.5), Color(0.06, 0.05, 0.07, 0.0), 2, 1.0)

	## 일섬선을 긋는다 (늦게 터짐)
	func _fire() -> void:
		var y := global_position.y + (EKensei.IAI_BAND.x + EKensei.IAI_BAND.y) * 0.5
		var cut := EKenseiFx.ShadowCut.new()
		cut.boss = boss
		cut.a = Vector2(global_position.x - CUT_HALF, y)
		cut.b = Vector2(global_position.x + CUT_HALF, y)
		cut.band = Rect2(global_position.x - CUT_HALF, global_position.y + EKensei.IAI_BAND.x, CUT_HALF * 2.0, EKensei.IAI_BAND.y - EKensei.IAI_BAND.x)
		cut.delay = CUT_DELAY
		cut.w = 7.0
		cut.on_done = _expire
		cut.tip_dir = facing
		PVfx.add(cut, cut.a, false)
		_cut = cut
		Sfx.play_pitch(&"kb_draw", randf_range(1.0, 1.1), -6.0)
		Fx.shake(0.15, 0.06)

	## 일섬이 끝났거나(터짐·단공에 갈림) — 스스로 사라짐 (버팀 피해 없음)
	func _expire() -> void:
		if is_dead():
			return
		expired = true
		returned.emit(self)
		banish()

	func _death_fx(_dir: float) -> void:
		if is_instance_valid(_cut) and _cut.has_method("cancel"):
			_cut.call("cancel") # 베어 없앰: 아직 터지지 않은 일섬선도 사라짐
		EKenseiFx.petals(center(), 22, Vector2(10, 22), 110.0, EKenseiFx.PETAL_BIG)
		var pp := PParticles.get_layer(false)
		for i in 10:
			pp.spawn(center() + Vector2(randf_range(-6, 6), randf_range(-16, 16)), Vector2.from_angle(randf() * TAU) * randf_range(20, 70), Vector2(0, -20),
				randf_range(0.4, 0.8), randf_range(2.5, 4.5), Color(0.05, 0.04, 0.06, 0.8), Color(0.05, 0.04, 0.06, 0.0), 2, 2.0)
		if not expired:
			Sfx.play_pitch(&"kb_shatter", 0.7, -4.0)

	func _paint_body(a0: float) -> void:
		var a := a0 * smoothstep(0.0, APPEAR, _age)
		if is_dead():
			a *= 1.0 - clampf(dead_t / FADE, 0.0, 1.0)
		if a <= 0.01 or src_v.is_empty():
			return
		# 검성 그림(그 쪽 좌표·뒤집힘 포함)을 이 분신 쪽으로: 원래 뒤집힘을 되돌리고 _base(이 분신 뒤집힘)를 얹음
		var lift := Vector2(0, (1.0 - a) * 6.0 if not is_dead() else -dead_t * 20.0)
		var m := _base * Transform2D(0.0, Vector2(float(src_facing), 1.0), 0.0, lift)
		# 발밑 먹물 웅덩이 (분신이 어디 서 있는지 바닥에서도 읽히게)
		pd.draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.25))
		pd.glow(Vector2.ZERO, POOL_R + sin(_age * 3.0 + float(order)) * 1.5, Color(0.03, 0.02, 0.04, 0.8 * a), 0.7 * a)
		pd.draw_arc(Vector2.ZERO, POOL_R * 0.8, 0.0, TAU, 20, Color(EKenseiFx.RED_DEEP, 0.5 * a), 1.0)
		pd.draw_set_transform(Vector2.ZERO)
		# 붉은 1px 테두리 빛: 검성이 한 번 구운 텍스처를 먹빛 몸 밑에 깖 (몸은 pd로 나중에 그려 위에 옴)
		if rim_tex != null:
			draw_set_transform_matrix(m)
			var hot := _cut != null or _left < GLINT_LAST
			var rc: Color = EKensei.RIM_HOT if hot else EKensei.RIM_IDLE
			draw_texture_rect(rim_tex, rim_rect, false, Color(rc, rc.a * a))
			draw_set_transform(Vector2.ZERO)
		var off := pd.v.size()
		for i in src_v.size():
			pd.v.append(m * src_v[i])
			var c := _ink[i] if i < _ink.size() else Color(0, 0, 0, INK_A)
			if flash > 0.0:
				c = c.lerp(Color.WHITE, flash * 0.6)
			pd.c.append(Color(c, c.a * a))
		for k in src_i:
			pd.idx.append(off + k)
		# 예고: 일섬선 자리에 머리카락 같은 선 (때가 가까울수록 짙음) + 마지막에 칼코등이 번뜩임
		if _cut == null and not is_dead():
			var f := 1.0 - clampf(_left / POSE_T, 0.0, 1.0)
			pd.draw_set_transform(Vector2.ZERO)
			var y := (EKensei.IAI_BAND.x + EKensei.IAI_BAND.y) * 0.5
			pd.line2(Vector2(-CUT_HALF, y), Vector2(CUT_HALF, y), Color(EKenseiFx.BONE, 0.08 * a), Color(EKenseiFx.BONE, (0.12 + 0.4 * f) * a), 0.8)
			if _left < GLINT_LAST:
				# 예고 십자 별 9px (검성 발도 번뜩임과 같은 꼴)
				var g := 1.0 - _left / GLINT_LAST
				EKenseiFx.star(pd, Vector2(5.0 * float(facing), -17.0), minf(g * 1.6, 1.0), 1.0, a)


## 분신 테두리 빛을 굽는 붓: 검성 그림을 붉게 상하좌우 1px 밀어 네 번 (SubViewport 안에서 한 번만 그림)
class RimPainter extends Node2D:
	const OFFS: Array[Vector2] = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	var v := PackedVector2Array()
	var idx := PackedInt32Array()
	var c := PackedColorArray()

	func _draw() -> void:
		var cols := PackedColorArray()
		cols.resize(v.size())
		for i in v.size():
			cols[i] = Color(1, 1, 1, c[i].a if i < c.size() else 1.0) # 흰색으로 구워 분신이 상태마다 색을 입힘
		for o in OFFS:
			var pts := PackedVector2Array()
			pts.resize(v.size())
			for i in v.size():
				pts[i] = v[i] + o
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)
