class_name EEska
extends CharacterBody2D
## 에스카(종언의 마녀) 전투 시제품. 기획: Claude 문서 "새 컨셉: 종언의 마녀" 탭.
## 조작: 이동(떠서 활주) · 점프 + 이단점프(공중에서 한 번) · 순간이동(지상은 자유, 공중은 착지 전까지 1번)
##       · 베기(기본 공격): 손가락 한 번 튕기면 앞에 큰 참격 하나 — 이동을 막지 않아 달리고 뛰고 떨어지는 중에도 자유롭게 나간다.
##         누르고 있으면 SLASH_RECOVER마다 저절로 다시 벤다
##       · 입력 기억: 순간이동·고급 마법·물약·대마법은 0.12초 기억 — 시전·의식·물약 동작·피격 경직이 끝나는 순간 꺼내 쓴다
##       · 순간이동 경로 찢기: 맞힌 뒤 0.6초 안에 순간이동하면 지나간 길이 찢겨 50 피해 (1초에 한 번, 틈 등록부 ERifts에 등록)
##       · 고급 마법 키: 그냥 = 천열(손가락을 튕기면 앞으로 거대한 참격 열 번) / ↑ = 단공(머리 위를 납작한 회오리 참격으로 연달아 휘감음)
##         / ↓ = 낙성(앞쪽 하늘을 찢어 별 조각이 쏟아짐, EMagicFx). 고급 마법은 각자 쿨다운만 쓴다.
##       · 대마법(흑성·유성우·종말의 운석·봉공): 종언 게이지가 가득일 때 고른 하나를 짧은 의식과 함께 발동 → 게이지 0. 고르기는 언제나.
##       · 물약: 허리띠 3칸(그냥·↑·↓) — 마시기·던지기 동작(St.ITEM)은 EPotions가 start_item으로 맡긴다.
## 공격 판정은 물리 없이 표적(ETarget: 허수아비·적)의 hit_rect()와 부채꼴·선분으로 계산한다(세라 시제품과 같은 방식).

enum St { NORMAL, BLINK, CAST, HURT, DEAD, ULT, ITEM }

signal hurt_taken(hp: int) ## 맞았을 때 (남은 체력)
signal died ## 쓰러졌을 때 — 장면이 부활시킨다 (respawn)

const GROUP := &"e_eska"
const SIZE := Vector2(10, 30)

# 이동: 땅 위를 살짝 떠서 미끄러지듯 활주 (상체를 숙이고 빠르게)
const RUN_SPEED := 210.0
const RUN_ACCEL := 2800.0
const RUN_DECEL := 3200.0
const AIR_ACCEL := 1900.0
const GRAVITY := 1350.0
const FALL_MAX := 330.0
const JUMP_SPEED := 360.0 ## 높이 고정 (길게 눌러도 같음) — 약 46px (예전 길게 누르면 약 65px)
const APEX_HANG := 0.55
const COYOTE := 0.09
const JUMP_BUFFER := 0.12
const AIR_JUMP_SPEED := 320.0 ## 이단점프: 공중의 공간을 밟고 한 번 더 도약 (착지 전까지 1번, 높이 고정)
const ATTACK_BUFFER := 0.14
const ACTION_BUFFER := 0.12 ## 순간이동·고급 마법·물약·대마법 입력 기억 — 시전·의식·물약 동작·피격 경직 중에 눌러도 끝나는 순간 꺼내 쓴다
const FAST_FALL_MAX := 440.0 ## 공중에서 ↓를 누르고 있으면
const COMBO_WINDOW := 1.6 ## 이 시간 안에 다시 맞히면 연타 수가 이어진다

# 순간이동
const BLINK_DIST := 150.0 ## 약 9타일 (100에서 1.5배)
const BLINK_GONE := 0.07 ## 사라져 있는 시간
const BLINK_CD := 0.26
const BLINK_INVULN := 0.2 ## 순간이동 무적 (사라짐 0.07초 + 나타난 뒤 0.13초)
## 순간이동 경로 찢기: 맞힌 뒤 TEAR_WINDOW초 안에 순간이동하면 지나간 길이 찢겨 그 위의 적에게 TEAR_DMG (TEAR_CD초에 한 번)
const TEAR_WINDOW := 0.6
const TEAR_DMG := 50
const TEAR_CD := 1.0
const TEAR_W := 18.0 ## 찢긴 길의 굵기 (판정·틈 등록 — 물약을 부어 넣을 수 있음)
const TEAR_LIFE := 0.8 ## 찢긴 길이 열려 있는 시간
const TEAR_STEP := 6.0 ## 경로 판정: 이 간격으로 점을 찍어 표적 사각형에 닿는지 본다

# 체력·피격
const MAX_HP := 6
const HURT_LOCK := 0.3 ## 맞은 뒤 조작이 막히는 시간
const HURT_INVULN := 1.1 ## 맞은 뒤 무적(깜빡임)
const RESPAWN_INVULN := 1.6 ## 부활 뒤 무적

## 고급 마법 쿨다운 (짧게 — 손맛 시험용)
const CD := {"cheonyeol": 5.0, "dangong": 2.0, "nakseong": 4.0} ## 천열은 896 피해라 5초 (2초면 연격을 쓸 이유가 없어짐) — docs/eska/combat_spec.md 밸런스
const NAMES := {"cheonyeol": "천열", "dangong": "단공", "nakseong": "낙성"}
## 고급 마법 시전: 동작 시간 · 마법이 나가는 시각 (초)
const CAST_DUR := {"cheonyeol": 0.26, "dangong": 0.32, "nakseong": 0.3}
const CAST_FIRE := {"cheonyeol": 0.07, "dangong": 0.06, "nakseong": 0.08}
const ECHO_DELAY := 0.35 ## 메아리 물약: 고급 마법이 이만큼 뒤에 한 번 더 (세기는 mods.echo)
const UPSWEEP_AREA := Rect2(-140, -230, 280, 222) ## 단공 판정: 발 기준 머리 위 (양옆으로 넓게)

## 대마법: 고르는 순서 · 이름. 종언 게이지가 가득일 때만 S로 발동 (봉공도 이제 쿨다운 대신 게이지를 다 쓴다)
const ULTS := ["blackstar", "meteor", "doom", "bonggong"]
const ULT_NAMES := {"blackstar": "흑성", "meteor": "유성우", "doom": "종말의 운석", "bonggong": "봉공"}
const ULT_RITUAL := 0.4 ## 의식 동작: 떠오르며 손을 펼친 뒤 이 시각에 대마법이 나간다 (그동안 무적)
const ULT_END := 0.52 ## 의식이 끝나고 다시 움직이는 시각
const ULT_RISE := 36.0 ## 의식 중 떠오르는 빠르기 (px/초 — 약 12px)
const ULT_SIGIL := 2.5 ## 의식 때 몸 뒤에 펼쳐지는 큰 문장 크기 (손끝에는 SIGIL 크기)
const ULT_SIGIL_Z := -6 ## 의식 문장을 몸 뒤로: 이펙트 층(z 5) 기준 -6 = 전체 z -1 (에스카 0보다 뒤, 바닥 -2보다 앞)
const ULT_SIGIL_UP := 20.0 ## 의식 문장 중심: 발에서 이만큼 위 (등 한가운데)
const ULT_DENY_GAP := 0.35 ## 게이지가 모자랄 때 "안 됨" 알림 사이 간격 (연타해도 소리가 겹치지 않게)
const STILL_TIME := 5.0 ## 봉공(공간 고정)이 공간을 굳히는 시간 (고정)
const STILL_BURST := 0.5 ## 진화한 봉공(1장 무구): 굳은 동안 준 피해의 이만큼이 깨질 때 한꺼번에 터짐
const SIGIL := 1.4 ## 베기·고급 마법 때 손끝 문장 크기 (작아서 안 보인다는 평가로 1.0 → 1.4)

## 물약 동작 (EPotions가 start_item으로 맡김)
const DRINK_MOVE := 0.4 ## 마시는 동안 이동 빠르기 배수
const THROW_HANG := 20.0 ## 공중에서 던질 때 낙하 속도를 이만큼으로 잡아 둠 (잠깐 머묾)

## 베기(기본 공격) — 예전 4타의 가장 큰 가로 참격 하나. 납작한 회오리(sq)를 rot만큼 기울인 호를 a0 → a1로 휘두른다 (각도는 도, 0 = 앞, + = 아래)
## hit 판정 시각 · r 반지름 · w 가장 굵은 곳 · c 몸 기준 중심. 참격은 튕긴 자리에 걸리고, 몸이 움직여도 그 자리에서 벤다
const SLASH := {"dur": 0.34, "hit": 0.06, "a0": -200.0, "a1": 160.0, "r": 140.0, "w": 44.0, "sq": 0.4, "rot": -8.0, "c": Vector2(6, -26), "dmg": 70}
const SLASH_RECOVER := 0.32 ## 다음 베기까지 (후딜) — 초당 약 220 피해 (예전 연격 약 200)
const SLASH_POSE := 0.22 ## 손짓이 보이는 시간

var st := St.NORMAL
var st_t := 0.0
var facing := 1
var art: EArt
var cooldowns := {"cheonyeol": 0.0, "dangong": 0.0, "nakseong": 0.0}

var _coyote := 0.0
var _jump_buf := 0.0
var _atk_buf := 0.0
var _was_floor := true

var slash_t := 9.0 ## 마지막 베기 뒤 시간 (그림이 손짓에 씀)
var _atk_cd := 0.0
var _slash_pending := false
var _slash_at := Vector2.ZERO ## 참격이 걸린 자리 (전역)
var _slash_dir := 1
var _slash_size := 1.0 ## 베기를 튕긴 순간의 범위 배수 (확장 물약)
var _air_hang := true ## 공중 첫 베기는 살짝 떠오름 (착지 전까지 1번)
var _air_jump := true ## 이단점프 남았는지 (착지하면 다시)
var _ghost_t := 0.0 ## 활주 잔상 간격

var _air_blink := true
var _blink_cd := 0.0
var _blink_dir := 1
var _blink_to := Vector2.ZERO
var _since_hit := 9.0 ## 마지막으로 맞힌 뒤 시간 (순간이동 경로 찢기)
var _tear_cd := 0.0
var tears := 0 ## 경로 찢기가 난 횟수 (시험용)

## 입력 기억 (남은 시간 — 0이면 없음). 고급 마법·물약은 누른 순간의 방향을 같이 기억한다
var _buf_blink := 0.0
var _buf_skill := 0.0
var _buf_skill_kind := ""
var _buf_potion := 0.0
var _buf_potion_slot := 0
var _buf_ult := 0.0
var _phys_seen := -1 ## 지난 _process 때의 물리 틱 번호 (멈춤 중 누름 놓치지 않기)

var cast_kind := ""
var _cast_dur := 0.0
var _cast_fired := false
var still_evolved := false ## 봉공 진화 (1장 무구를 거두면 켜짐 — 훈련장은 버튼/T 키로 시험)
var ult_index := 0 ## 고른 대마법 (ULTS 번호)
var ult_kind := "" ## 지금 의식 중인 대마법
var _ult_fired := false
var ult_denied := 0.0 ## 게이지가 모자라 막힌 뒤 남은 시간 (화면 표시가 흔들림에 씀)
var ult_full_t := 0.0 ## 게이지가 막 가득 찬 뒤 시간 (화면 표시가 번쩍임에 씀)
var item_kind := "" ## 물약 동작 "drink" | "throw"
var _item_dur := 0.0
var _item_fire_at := 0.0
var _item_cb := Callable()
var _item_fired := false
var fx_spawned := 0 ## 고급 마법·대마법 이펙트를 만든 수 (메아리 포함 — 시험용)
var last_potion_slot := -1 ## 마지막으로 F로 고른 허리띠 칸 (화면 표시·시험용)
var _leech_acc := 0.0 ## 포식 물약: 쌓인 피해

## 물약이 바꾸는 값 (EPotions가 켜고 끈다): size 범위 배수 · cd_rate 고급 마법 쿨다운이 줄어드는 빠르기 · speed 이동 배수
## echo 고급 마법이 한 번 더 나가는 세기(0 = 없음) · leech 이만큼 피해마다 체력 +1 (0 = 없음) · gauge 종언 게이지 차는 배수 · dmg 주는 피해 배수
var mods := {"size": 1.0, "cd_rate": 1.0, "speed": 1.0, "echo": 0.0, "leech": 0, "gauge": 1.0, "dmg": 1.0}
const GAUGE_MAX := 6600.0 ## 종언 게이지: 대마법이 아닌 피해 이만큼이면 가득 (초당 약 220이면 30초) — design.md 3-3
const GAUGE_RATE := 220.0 ## cd_left가 대마법까지 남은 시간을 셀 때 쓰는 초당 피해 (기본 베기 기준)
const ULT_NOT_SELECTED := 1.0 ## 게이지가 가득해도 고르지 않은 대마법은 cd_left가 이만큼 (0이 아니게)
var gauge := 0.0
var belt := EPotions.Belt.new()

var invuln := 0.0
var hp := MAX_HP
var hurt_flicker := 0.0 ## 맞은 뒤 깜빡이는 남은 시간 (그림이 읽는다)
var controls_locked := false ## 연출 중 조작 막기 (튜토리얼 대사 등)

# 연타 수 (화면 오른쪽 위)
var hit_count := 0
var hit_damage := 0
var combo_left := 0.0
var _dust_t := 0.0
var _last_dir := 1


static func find(tree: SceneTree) -> EEska:
	return tree.get_first_node_in_group(GROUP) as EEska


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = SIZE
	cs.shape = rs
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)
	art = EArt.new()
	art.body = self
	add_child(art)


func center() -> Vector2:
	return global_position + Vector2(0, -SIZE.y * 0.55)


## 남은 쿨다운(초). 대마법 id는 쿨다운이 없어서 "지금 S로 쓸 수 있나"로 답한다:
## 게이지가 가득하고 그 대마법이 골라져 있으면 0, 아니면 게이지가 다 차기까지 남은 몫(초당 약 220 기준 초)
## (자동 플레이 봇처럼 cd_left로 쓸 수 있는지 묻는 쪽이 그대로 동작하게)
func cd_left(id: String) -> float:
	if ULTS.has(id):
		if gauge_ratio() >= 1.0 and selected_ult() == id:
			return 0.0
		return maxf((GAUGE_MAX - gauge) / GAUGE_RATE, ULT_NOT_SELECTED)
	return float(cooldowns.get(id, 0.0))


func cd_ratio(id: String) -> float:
	if not CD.has(id):
		return 0.0 if cd_left(id) <= 0.0 else 1.0 - gauge_ratio()
	return clampf(cd_left(id) / float(CD[id]), 0.0, 1.0)


func is_up_held() -> bool:
	return Input.is_action_pressed("es_up")


func is_down_held() -> bool:
	return Input.is_action_pressed("es_down")


## 고급 마법 키가 지금 고를 마법: ↓ = 낙성 · ↑ = 단공 · 그냥 = 천열
func skill_for_dir() -> String:
	if is_down_held():
		return "nakseong"
	if is_up_held():
		return "dangong"
	return "cheonyeol"


## 물약 키가 지금 고를 허리띠 칸: 그냥 0 · ↑ 1 · ↓ 2
func potion_slot_for_dir() -> int:
	if is_up_held():
		return 1
	if is_down_held():
		return 2
	return 0


# ── 종언 게이지 · 대마법 고르기

func gauge_ratio() -> float:
	return clampf(gauge / GAUGE_MAX, 0.0, 1.0)


## 게이지를 채운다 (막 가득 차면 번쩍임 + 소리)
func add_gauge(amount: float) -> void:
	var was_full := gauge >= GAUGE_MAX
	gauge = clampf(gauge + amount, 0.0, GAUGE_MAX)
	if not was_full and gauge >= GAUGE_MAX:
		ult_full_t = 0.0
		Sfx.play(&"star_twinkle", -4.0)


func fill_gauge() -> void:
	add_gauge(GAUGE_MAX)


func selected_ult() -> String:
	return ULTS[posmod(ult_index, ULTS.size())]


## 대마법 고르기 순환 (D) — 언제나 가능
func next_ult() -> void:
	ult_index = posmod(ult_index + 1, ULTS.size())
	Sfx.play(&"ui_move", -6.0)


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	st_t += delta
	var cd_step := delta * float(mods.cd_rate) # 가속 물약: 고급 마법 쿨다운이 더 빨리 준다
	for k in cooldowns:
		cooldowns[k] = maxf(float(cooldowns[k]) - cd_step, 0.0)
	ult_denied = maxf(ult_denied - delta, 0.0)
	ult_full_t += delta
	_blink_cd = maxf(_blink_cd - delta, 0.0)
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	_since_hit += delta
	_tear_cd = maxf(_tear_cd - delta, 0.0)
	slash_t += delta
	if _slash_pending and slash_t >= float(SLASH.hit):
		_slash_pending = false
		_slash_hit()
	invuln = maxf(invuln - delta, 0.0)
	combo_left = maxf(combo_left - delta, 0.0)
	if combo_left <= 0.0:
		hit_count = 0
		hit_damage = 0
	_coyote = COYOTE if is_on_floor() else maxf(_coyote - delta, 0.0)
	_jump_buf = maxf(_jump_buf - delta, 0.0)
	_atk_buf = maxf(_atk_buf - delta, 0.0)
	_buf_blink = maxf(_buf_blink - delta, 0.0)
	_buf_skill = maxf(_buf_skill - delta, 0.0)
	_buf_potion = maxf(_buf_potion - delta, 0.0)
	_buf_ult = maxf(_buf_ult - delta, 0.0)
	_poll_presses()
	hurt_flicker = maxf(hurt_flicker - delta, 0.0)
	var dir_x := Input.get_axis("es_left", "es_right")
	if controls_locked:
		dir_x = 0.0
		_jump_buf = 0.0
		_atk_buf = 0.0
		_forget_inputs()
	elif Input.is_action_just_pressed("es_ult_next") and st != St.DEAD:
		next_ult()
	match st:
		St.NORMAL:
			_normal(delta, dir_x)
		St.BLINK:
			_blink(delta)
		St.CAST:
			_cast(delta)
		St.HURT:
			_hurt_state(delta)
		St.ULT:
			_ult(delta)
		St.ITEM:
			_item(delta, dir_x)
		St.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_gravity(delta)
	if st != St.BLINK:
		move_and_slide()
	var on_floor := is_on_floor()
	if on_floor:
		_air_blink = true
		_air_hang = true
		_air_jump = true
		if not _was_floor:
			EVfx.land_dust(global_position)
			Sfx.play(&"land", -14.0)
	_was_floor = on_floor
	_ground_fx(delta)
	art.tick(delta)


func _gravity(delta: float, mult := 1.0) -> void:
	var g := GRAVITY * mult
	if absf(velocity.y) < 60.0 and not is_on_floor():
		g *= APEX_HANG
	var cap := FALL_MAX
	if Input.is_action_pressed("es_down") and not is_on_floor():
		g *= 1.35
		cap = FAST_FALL_MAX
	velocity.y = minf(velocity.y + g * delta, cap)


## 활주: 발밑에 낮게 깔리는 보랏빛 바람 · 뒤로 흐르는 속도선 · 짧은 잔상 / 방향 바꿀 때 미끄러지는 먼지
func _ground_fx(delta: float) -> void:
	var vx := velocity.x
	var fast := absf(vx) > 190.0 and st == St.NORMAL
	if fast:
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = 0.14
			EVfx.afterimage(art, 0.14, EVfx.VIOLET, Vector2.ZERO, 0.4) # 최고 속도에서만 아주 옅은 잔상
	if not is_on_floor() or st == St.BLINK:
		return
	if absf(vx) > 110.0:
		_dust_t -= delta
		if _dust_t <= 0.0:
			_dust_t = 0.045
			EMoveFx.glide_wake(global_position, signf(vx), absf(vx) / RUN_SPEED)
	var d := int(signf(Input.get_axis("es_left", "es_right")))
	if d != 0 and d != _last_dir and absf(vx) > 90.0 and st == St.NORMAL:
		PVfx.dust(global_position + Vector2(-d * 2.0, 0), 4, 1.2, 16.0)
		art.squash(Vector2(1.12, 0.9))
	if d != 0:
		_last_dir = d


func _run(delta: float, dir_x: float, speed_mult := 1.0) -> void:
	var target := dir_x * RUN_SPEED * speed_mult
	var acc := RUN_ACCEL if is_on_floor() else AIR_ACCEL
	if absf(dir_x) < 0.01:
		acc = RUN_DECEL if is_on_floor() else AIR_ACCEL * 0.6
	velocity.x = move_toward(velocity.x, target, acc * delta)
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1


func _normal(delta: float, dir_x: float) -> void:
	_run(delta, dir_x, float(mods.speed))
	if _jump_buf > 0.0 and _coyote > 0.0:
		_jump_buf = 0.0
		_coyote = 0.0
		velocity.y = -JUMP_SPEED
		art.squash(Vector2(0.82, 1.2))
		if is_on_floor():
			PVfx.dust(global_position, 4, 1.0, 14.0)
		Sfx.play(&"jump", -6.0)
	elif _jump_buf > 0.0 and _air_jump and not is_on_floor():
		_double_jump(dir_x)
	_gravity(delta)
	_try_actions(dir_x)


## 이단점프: 발밑 공중에 다크 회오리 고리가 생겨 그것을 밟고 도약, 몸이 아주 빠르게 한 바퀴(치맛자락이 우산처럼 퍼짐). 누른 방향으로 바로 꺾는다
func _double_jump(dir_x: float) -> void:
	_jump_buf = 0.0
	_air_jump = false
	velocity.y = -AIR_JUMP_SPEED
	if absf(dir_x) > 0.01:
		velocity.x = signf(dir_x) * RUN_SPEED * float(mods.speed)
		facing = 1 if dir_x > 0.0 else -1
	art.air_flourish()
	art.squash(Vector2(0.9, 1.12))
	EMoveFx.air_step(global_position)
	Sfx.play(&"es_air_step", -4.0)
	Sfx.play_pitch(&"whoosh", 1.4, -12.0)


## 입력 기억: 눌린 순간을 기억한다 (점프 JUMP_BUFFER · 베기 ATTACK_BUFFER · 나머지 ACTION_BUFFER초, 상태와 상관없이).
## 꺼내 쓰는 건 평소 상태의 _try_actions (시전·의식·물약 동작·피격 경직이 끝나는 순간 _resume이 바로 부름)
func _poll_presses() -> void:
	if Input.is_action_just_pressed("es_jump"):
		_jump_buf = JUMP_BUFFER
	if Input.is_action_just_pressed("es_attack"):
		_atk_buf = ATTACK_BUFFER
	if controls_locked or st == St.DEAD:
		return
	if Input.is_action_just_pressed("es_blink"):
		_buf_blink = ACTION_BUFFER
	if Input.is_action_just_pressed("es_skill"):
		_buf_skill = ACTION_BUFFER
		_buf_skill_kind = skill_for_dir()
	if Input.is_action_just_pressed("es_potion"):
		_buf_potion = ACTION_BUFFER
		_buf_potion_slot = potion_slot_for_dir()
	if Input.is_action_just_pressed("es_bind"):
		_buf_ult = ACTION_BUFFER


## 멈춤(히트스톱)으로 시간이 거의 멈춘 프레임엔 물리 틱이 돌지 않아 그 프레임의 짧은 누름을 물리에서 못 본다 →
## 이번 프레임에 물리 틱이 한 번도 없었으면 여기서 대신 기억해 둔다 (기억 시간은 물리 틱에서만 줄어서 멈춤이 풀린 뒤 꺼내 씀)
func _process(_delta: float) -> void:
	var pf := Engine.get_physics_frames()
	if pf == _phys_seen:
		_poll_presses()
	_phys_seen = pf


func _forget_inputs() -> void:
	_buf_blink = 0.0
	_buf_skill = 0.0
	_buf_potion = 0.0
	_buf_ult = 0.0


## 시전·의식·피격 경직이 끝남: 평소 상태로 돌아가며 그동안 기억해 둔 입력(ACTION_BUFFER)을 같은 프레임에 꺼낸다
func _resume() -> void:
	st = St.NORMAL
	st_t = 0.0
	_try_actions(Input.get_axis("es_left", "es_right"))


func _can_blink() -> bool:
	return _blink_cd <= 0.0 and (is_on_floor() or _air_blink)


## 순간이동·스킬·공격 시작 (상태가 바뀌면 true). 기억해 둔 입력(0.12초)을 여기서 꺼낸다
## 공격은 누르고 있으면 SLASH_RECOVER마다 저절로 다시 벤다 (터치 공격 버튼도 같음)
func _try_actions(dir_x: float) -> bool:
	if controls_locked:
		return false
	if _buf_ult > 0.0:
		_buf_ult = 0.0
		if gauge_ratio() >= 1.0:
			_start_ult()
			return true
		_deny_ult()
	if _buf_skill > 0.0 and cd_left(_buf_skill_kind) <= 0.0:
		_buf_skill = 0.0
		_start_cast(_buf_skill_kind)
		return true
	if _buf_potion > 0.0:
		_buf_potion = 0.0
		last_potion_slot = _buf_potion_slot
		if not EPotions.use(self, last_potion_slot):
			Sfx.play(&"block", -14.0) # 빈 칸 · 쓸 수 없음
		if st != St.NORMAL:
			return true
	if _buf_blink > 0.0 and _can_blink():
		_buf_blink = 0.0
		_start_blink(dir_x)
		return true
	if _atk_cd <= 0.0 and (_atk_buf > 0.0 or Input.is_action_pressed("es_attack")):
		_atk_buf = 0.0
		_fire_slash() # 상태는 그대로 — 이동을 막지 않는다
	return false


# ═══════════════════════════════════════════════════════════
# 베기 (기본 공격)
# ═══════════════════════════════════════════════════════════

## 손가락 한 번 튕기면 앞에 큰 참격 하나. 움직임은 그대로 두고, 참격만 그 자리에 건다
func _fire_slash() -> void:
	var dir_x := Input.get_axis("es_left", "es_right")
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1
	_atk_cd = SLASH_RECOVER
	slash_t = 0.0
	_slash_dir = facing
	var c: Vector2 = SLASH.c
	_slash_at = global_position + Vector2(c.x * facing, c.y)
	_slash_pending = true
	_slash_size = float(mods.size)
	if not is_on_floor() and _air_hang:
		_air_hang = false
		velocity.y = minf(velocity.y, -40.0) # 공중 첫 베기: 살짝 떠오름
	var shape := SLASH
	if _slash_size != 1.0: # 확장 물약: 참격 반지름·굵기를 같이 키움
		shape = SLASH.duplicate()
		shape.r = float(SLASH.r) * _slash_size
		shape.w = float(SLASH.w) * _slash_size
	var sl := ESkillFx.Slash.new()
	sl.setup(shape, facing, true)
	EVfx.add(sl, _slash_at, false) # 다크 참격은 보통 섞기 (검은 테두리가 보이게)
	EVfx.sigil(art.fingertip(), SIGIL) # 손끝 문장이 번쩍인 뒤 공간이 찢긴다 (design.md 3-4)
	Sfx.play_pitch(&"es_snap", 0.86 * randf_range(0.97, 1.03), -6.0)
	Sfx.play_pitch(&"es_slash_big", randf_range(0.96, 1.04), 0.0)
	art.snap_flash()
	art.squash(Vector2(1.04, 0.97))
	EVfx.afterimage(art, 0.22)


func _slash_hit() -> void:
	var any := false
	for d: Node2D in ETarget.alive(get_tree()):
		if _sector_hits(d.hit_rect(), _slash_at, float(SLASH.r) * _slash_size + 8.0, float(SLASH.a0), float(SLASH.a1), float(SLASH.sq), float(SLASH.rot), _slash_dir):
			deal(d, int(SLASH.dmg), true, _slash_at)
			any = true
	if any:
		Fx.hitstop(0.06)
		PVfx.kick(Vector2(_slash_dir * 5.0, 0))
		Fx.shake(0.4, 0.18)
		Fx.zoom_punch(0.05)


## 부채꼴(납작함 sq) 안에 사각형이 걸치는지. 각도는 앞 기준(도)
## 기울인(rot, 도) 납작한(sq) 호 안에 rect가 들어오는지 — 그림(Slash)과 같은 변환을 거꾸로 적용
func _sector_hits(rect: Rect2, cen: Vector2, r: float, a0: float, a1: float, sq: float, rot := 0.0, dir := 0) -> bool:
	sq = maxf(sq, 0.6) # 그림은 납작한 회오리지만 판정은 위아래로 넉넉하게 (공중에서도 맞게)
	var f := dir if dir != 0 else facing # 방향 (0 = 지금 바라보는 쪽)
	var unrot := -deg_to_rad(rot) * float(f)
	var lo := deg_to_rad(minf(a0, a1)) - 0.25
	var hi := deg_to_rad(maxf(a0, a1)) + 0.25
	var p0 := rect.position
	var p1 := rect.end
	var m := rect.get_center()
	for pt: Vector2 in [m, p0, p1, Vector2(p0.x, p1.y), Vector2(p1.x, p0.y), Vector2(m.x, p0.y), Vector2(m.x, p1.y), Vector2(p0.x, m.y), Vector2(p1.x, m.y)]:
		var q := (pt - cen).rotated(unrot)
		q.x *= f
		q.y /= sq
		var l := q.length()
		if l > r:
			continue
		if l < 16.0:
			return true
		var ang := atan2(q.y, q.x)
		if ang >= lo and ang <= hi:
			return true
	return false


## 피해 한 번 (이펙트 노드들도 이걸 부른다). opts: "ult" = 대마법 피해(게이지를 채우지 않음) · "poise" = 강자 버팀을 깎는 양(기본 = 피해)
## 물약: mods.dmg 배수를 곱하고, 대마법이 아니면 종언 게이지를 채우며(mods.gauge 배수), mods.leech마다 체력 +1
func deal(d: Node2D, dmg: int, heavy: bool, from: Vector2, opts := {}) -> void:
	if not is_instance_valid(d):
		return
	var mult := float(mods.dmg)
	if mult != 1.0:
		dmg = roundi(float(dmg) * mult)
	d.take_hit(dmg, from, {"heavy": heavy, "launch": 1.5 if heavy else 0.0, "poise": opts.get("poise", dmg)})
	if EStill.active():
		EStill.current.store(d, dmg) # 진화한 봉공: 굳은 동안 준 피해를 쌓아 둠
	if not opts.get("ult", false):
		add_gauge(float(dmg) * float(mods.gauge))
	_leech(dmg)
	_since_hit = 0.0
	hit_count += 1
	hit_damage += dmg
	combo_left = COMBO_WINDOW
	EVfx.hit_crack(d.center() + Vector2(randf_range(-4, 4), randf_range(-8, 8)), heavy, signf(d.global_position.x - from.x))
	Sfx.play(&"hit_heavy" if heavy else &"hit", -6.0 if not heavy else -2.0)


## 포식 물약: 준 피해가 mods.leech만큼 쌓일 때마다 체력 +1 (가득이면 그대로, 0 = 꺼짐)
func _leech(dmg: int) -> void:
	var every := float(mods.leech)
	if every <= 0.0:
		_leech_acc = 0.0
		return
	_leech_acc += float(dmg)
	while _leech_acc >= every:
		_leech_acc -= every
		if hp < MAX_HP and st != St.DEAD:
			hp += 1
			hurt_taken.emit(hp)
			EVfx.dark_bits(center(), 6, 60.0, Vector2.UP, 50.0, 0.4)


# ═══════════════════════════════════════════════════════════
# 물약 동작 (마시기 · 던지기)
# ═══════════════════════════════════════════════════════════

## 물약 마시기·던지기 동작 (EPotions가 부름): dur초 동안 동작, fire_at초에 on_fire를 부른다. kind = "drink" | "throw"
## 마시기: 40% 빠르기로만 움직이고 공격·마법은 막힘. fire_at 전에 맞으면 끊겨서 on_fire를 부르지 않는다.
## 던지기: 짧게(약 0.22초), 공중에서도 됨 (잠깐 머묾)
func start_item(kind: String, dur: float, fire_at: float, on_fire: Callable) -> void:
	if st == St.DEAD:
		return
	item_kind = kind
	_item_dur = dur
	_item_fire_at = fire_at
	_item_cb = on_fire
	_item_fired = false
	st = St.ITEM
	st_t = 0.0
	_atk_buf = 0.0
	if kind == "throw":
		if not is_on_floor():
			velocity.y = minf(velocity.y, THROW_HANG)
		Sfx.play_pitch(&"whoosh", 1.3, -8.0)
	else:
		Sfx.play(&"potion", -6.0)


## 물약 동작 진행도 0~1 (그림이 읽는다)
func item_progress() -> float:
	return clampf(st_t / maxf(_item_dur, 0.01), 0.0, 1.0)


## 물약 효과가 났는가 (던지기: 병이 손을 떠났는가 — 그림이 읽는다)
func item_fired() -> bool:
	return _item_fired


func _item(delta: float, dir_x: float) -> void:
	if item_kind == "drink":
		_run(delta, dir_x, DRINK_MOVE * float(mods.speed))
		_gravity(delta)
	else:
		_run(delta, dir_x, float(mods.speed))
		if is_on_floor():
			_gravity(delta)
		else:
			velocity.y = move_toward(velocity.y, THROW_HANG, GRAVITY * delta) # 던지는 동안 공중에 잠깐 머문다
	if not _item_fired and st_t >= _item_fire_at:
		_item_fired = true
		var cb := _item_cb
		_item_cb = Callable()
		if cb.is_valid():
			cb.call()
	if st_t >= _item_dur:
		_end_item()
		if st == St.NORMAL:
			_try_actions(Input.get_axis("es_left", "es_right")) # 기억해 둔 입력을 바로 꺼냄


func _end_item() -> void:
	item_kind = ""
	_item_cb = Callable()
	if st == St.ITEM:
		st = St.NORMAL
		st_t = 0.0


# ═══════════════════════════════════════════════════════════
# 순간이동
# ═══════════════════════════════════════════════════════════

func _start_blink(dir_x: float) -> void:
	var d := facing
	if dir_x > 0.01:
		d = 1
	elif dir_x < -0.01:
		d = -1
	facing = d
	_blink_dir = d
	var motion := Vector2(d * BLINK_DIST, 0)
	var from_xf := global_transform.translated(Vector2(0, -2))
	var col := KinematicCollision2D.new()
	var travel := motion
	if test_move(from_xf, motion, col):
		travel = col.get_travel()
	_blink_to = global_position + Vector2(travel.x, 0)
	if not is_on_floor():
		_air_blink = false
	st = St.BLINK
	st_t = 0.0
	invuln = BLINK_INVULN
	var to_c := _blink_to + Vector2(0, -SIZE.y * 0.55)
	EMoveFx.blink_out(art, center(), d)
	EMoveFx.blink_trail(art, center(), to_c, not is_on_floor())
	if _since_hit <= TEAR_WINDOW and _tear_cd <= 0.0:
		_tear_path(center(), to_c)
	art.visible = false
	velocity = Vector2.ZERO
	Sfx.play(&"es_blink", -3.0)


## 순간이동 경로 찢기: 지나간 길(from → to)이 찢겨 그 위의 표적에 TEAR_DMG, 열린 틈으로 등록 (던진 물약이 스며들 수 있게)
func _tear_path(from: Vector2, to: Vector2) -> void:
	_tear_cd = TEAR_CD
	tears += 1
	var n := maxi(int(from.distance_to(to) / TEAR_STEP), 1)
	for d: Node2D in ETarget.alive(get_tree()):
		var r: Rect2 = d.hit_rect().grow(TEAR_W * 0.5)
		for i in n + 1:
			if r.has_point(from.lerp(to, float(i) / float(n))):
				deal(d, TEAR_DMG, false, from)
				break
	ERifts.open(PackedVector2Array([from, to]), TEAR_W, TEAR_LIFE)
	var tear := PathTear.new()
	tear.to = to - from
	EVfx.add(tear, from, false)
	Sfx.play_pitch(&"es_tear", 1.25, -5.0)
	Fx.shake(0.25, 0.1)


func _blink(_delta: float) -> void:
	velocity = Vector2.ZERO
	if st_t >= BLINK_GONE:
		global_position = _blink_to
		art.visible = true
		st = St.NORMAL
		st_t = 0.0
		_blink_cd = BLINK_CD
		velocity.x = _blink_dir * RUN_SPEED
		velocity.y = 0.0
		EMoveFx.blink_in(center(), _blink_dir)
		art.squash(Vector2(1.9, 0.5)) # 길게 늘어난 채 나타났다가 탁 돌아온다
		PVfx.kick(Vector2(_blink_dir * 3.0, 0))


# ═══════════════════════════════════════════════════════════
# 고급 마법: 천열 · 단공 · 낙성
# ═══════════════════════════════════════════════════════════

func _start_cast(kind: String) -> void:
	var dir_x := Input.get_axis("es_left", "es_right")
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1
	cast_kind = kind
	_cast_dur = float(CAST_DUR[kind])
	_cast_fired = false
	cooldowns[kind] = CD[kind]
	st = St.CAST
	st_t = 0.0
	if not is_on_floor():
		velocity.y = minf(velocity.y, 0.0) * 0.3
	EVfx.sigil(art.fingertip(), SIGIL)


func _cast(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		velocity.y = move_toward(velocity.y, 20.0, 900.0 * delta) # 시전 중엔 공중에 잠깐 머문다 (낙성도 지상과 같게 — 내려찍기 없음)
	if not _cast_fired and st_t >= float(CAST_FIRE.get(cast_kind, 0.05)):
		_cast_fired = true
		_spawn_skill(cast_kind, facing, global_position, 0.0)
		art.snap_flash()
		match cast_kind:
			"cheonyeol":
				Sfx.play_pitch(&"blip", 1.6, -2.0)
				Sfx.play(&"whoosh", -4.0)
			"dangong":
				Sfx.play(&"storm", -6.0)
			"nakseong":
				Sfx.play_pitch(&"sky_crack", 1.2, -6.0)
		var echo := float(mods.echo)
		if echo > 0.0: # 메아리 물약: 같은 마법이 조금 뒤 같은 자리에서 한 번 더
			get_tree().create_timer(ECHO_DELAY, false).timeout.connect(_spawn_skill.bind(cast_kind, facing, global_position, echo))
	if _cast_fired and _buf_blink > 0.0 and _can_blink(): # 마법이 나간 뒤엔 순간이동으로 끊을 수 있다
		_buf_blink = 0.0
		_start_blink(Input.get_axis("es_left", "es_right"))
		return
	if st_t >= _cast_dur:
		_resume()


## 고급 마법 이펙트 하나를 at(발 위치)에 만든다. power > 0 = 메아리(그 세기로 — 세기 필드는 이펙트 쪽이 읽음)
func _spawn_skill(kind: String, dir: int, at: Vector2, power: float) -> void:
	if not is_inside_tree():
		return
	var n: Node2D
	match kind:
		"cheonyeol":
			var fl := ESkillFx.Flurry.new()
			fl.eska = self
			fl.dir = dir
			n = fl
		"dangong":
			var up := ESkillFx.Upsweep.new()
			up.eska = self
			up.dir = dir
			var k := float(mods.size)
			var sz := UPSWEEP_AREA.size * k
			up.area = Rect2(at + Vector2(-sz.x * 0.5, UPSWEEP_AREA.end.y - sz.y), sz) # 머리 위 (양옆으로 넓게, 확장 물약이면 발 위 기준으로 커짐)
			n = up
		"nakseong":
			var nk := EMagicFx.Nakseong.new()
			nk.eska = self
			nk.dir = dir
			n = nk
		_:
			return
	if power > 0.0:
		n.set("power", power)
	fx_spawned += 1
	EVfx.add(n, at, false)


# ═══════════════════════════════════════════════════════════
# 대마법: 흑성 · 유성우 · 종말의 운석 · 봉공 (종언 게이지 가득 = 1번)
# ═══════════════════════════════════════════════════════════

## 의식 시작: 무적, 떠오르며 손을 펼치고 손끝에 큰 문장 → ULT_RITUAL초에 대마법
func _start_ult() -> void:
	var dir_x := Input.get_axis("es_left", "es_right")
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1
	ult_kind = selected_ult()
	gauge = 0.0
	_ult_fired = false
	st = St.ULT
	st_t = 0.0
	velocity = Vector2(velocity.x * 0.3, -ULT_RISE)
	EVfx.sigil(art.fingertip(), SIGIL)
	_ritual_sigil()
	Fx.zoom_punch(0.04)
	Sfx.play(&"magic_learn", -6.0)
	Sfx.play_pitch(&"es_tear", 0.7, -6.0)


func _ult(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	velocity.y = -ULT_RISE if st_t < ULT_RITUAL else move_toward(velocity.y, 0.0, 600.0 * delta) # 의식 중엔 천천히 떠오른다
	if not _ult_fired and st_t >= ULT_RITUAL:
		_ult_fired = true
		_fire_ult(ult_kind)
	if st_t >= ULT_END:
		_resume()


func _fire_ult(kind: String) -> void:
	Fx.hitstop(0.08)
	Fx.zoom_punch(0.09)
	Fx.shake(0.6, 0.25)
	art.snap_flash()
	Sfx.play(&"star_burst", -3.0)
	var n: Node2D
	match kind:
		"blackstar":
			var bs := EMagicFx.BlackStar.new()
			bs.eska = self
			bs.dir = facing
			n = bs
		"meteor":
			var ms := EMagicFx.MeteorShower.new()
			ms.eska = self
			ms.dir = facing
			n = ms
		"doom":
			var dm := EMagicFx.DoomMeteor.new()
			dm.eska = self
			dm.dir = facing
			n = dm
		"bonggong":
			EStill.cast(self, STILL_TIME, STILL_BURST if still_evolved else 0.0)
	if n != null:
		fx_spawned += 1
		EVfx.add(n, global_position, false)


## 의식 문장: 몸 뒤(등 한가운데)에 큰 문장 — 손끝 문장과 달리 캐릭터를 가리지 않게 z를 몸 뒤로 내린다
func _ritual_sigil() -> void:
	var s := EVfx.Sigil.new()
	s.size = ULT_SIGIL
	EVfx.add(s, global_position + Vector2(0, -ULT_SIGIL_UP), true)
	s.z_index = ULT_SIGIL_Z # Sigil._ready가 앞(z 7)으로 정하므로 붙인 뒤에 내린다
	Sfx.play_pitch(&"es_sigil", 0.8, -7.0)


## 게이지가 모자랄 때: 작은 막힘 소리 + 화면 표시가 살짝 흔들림 (연타해도 소리는 ULT_DENY_GAP마다 한 번)
func _deny_ult() -> void:
	if ult_denied > 0.0:
		return
	ult_denied = ULT_DENY_GAP
	Sfx.play(&"block", -12.0)


# ═══════════════════════════════════════════════════════════
# 체력 · 피격 · 쓰러짐 · 부활
# ═══════════════════════════════════════════════════════════

## 맞는 판정 사각형 (전역)
func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), SIZE)


func is_dead() -> bool:
	return st == St.DEAD


## 적에게 맞음 (맞았으면 true). 순간이동 중·대마법 의식 중·무적 중엔 안 맞는다. 물약을 마시다 맞으면 마시기가 끊긴다
func hurt(dmg: int, from: Vector2) -> bool:
	if invuln > 0.0 or st in [St.DEAD, St.BLINK, St.ULT]:
		return false
	if st == St.ITEM:
		_end_item() # 아직 효과가 나기 전이면 on_fire를 부르지 않고 버린다
	hp = maxi(hp - dmg, 0)
	invuln = HURT_INVULN
	hurt_flicker = HURT_INVULN
	var d := signf(global_position.x - from.x)
	if d == 0.0:
		d = -float(facing)
	velocity = Vector2(d * 190.0, -190.0)
	st = St.HURT
	st_t = 0.0
	art.visible = true
	art.hurt()
	Fx.hitstop(0.09)
	Fx.shake(0.55, 0.22)
	PVfx.kick(Vector2(d * 4.0, -2.0))
	Fx.flash(Color(1.0, 0.2, 0.3, 0.22), 0.16)
	Sfx.play(&"hurt", -3.0)
	EVfx.dark_bits(center(), 8, 160.0, Vector2(d, -0.4), 70.0, 0.4, 2)
	hurt_taken.emit(hp)
	if hp <= 0:
		_die()
	return true


func _hurt_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	_gravity(delta)
	if st_t >= HURT_LOCK:
		_resume()


func _die() -> void:
	item_kind = ""
	_item_cb = Callable()
	st = St.DEAD
	st_t = 0.0
	hurt_flicker = 0.0
	art.dissolve()
	EVfx.dark_bits(center(), 22, 220.0, Vector2.UP, 180.0, 0.7, 6)
	EVfx.dark_burst(center(), 30.0)
	Fx.slowmo(0.35, 0.5)
	died.emit()


## 장면이 부르는 부활: 자리를 옮기고 체력을 채운 뒤 공간 틈에서 나타난다
func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	hp = MAX_HP
	st = St.NORMAL
	st_t = 0.0
	item_kind = ""
	_item_cb = Callable()
	belt.refill() # 쓰러지면 허리띠 물약이 다시 가득 (design.md 4-2)
	invuln = RESPAWN_INVULN
	hurt_flicker = RESPAWN_INVULN
	art.revive()
	EMoveFx.blink_in(center(), facing)
	art.squash(Vector2(0.7, 1.35))
	hurt_taken.emit(hp)


## 순간이동 경로 찢기 그림: 출발점 → 도착점 곧은 틈이 순식간에 벌어졌다가 출발점 쪽부터 꿰매어 닫힌다 (EVfx.rift — 다른 마법의 틈과 같은 말투)
class PathTear extends PVfx.Base:
	const HALF_W := 5.0 ## 그림의 반폭 (판정 굵기 TEAR_W보다 가늘게 — 길이 찢긴 줄로 읽히게)
	const SEG := 14
	const OPEN_T := 0.06 ## 벌어지는 시간
	var to := Vector2.ZERO
	var _shape: Array = []
	var _seed := 0

	func _ready() -> void:
		life = TEAR_LIFE
		z_index = 4
		_seed = randi() % 997
		_shape = EVfx.rift_line(Vector2.ZERO, to, HALF_W, SEG, _seed, 2.0)

	func _paint() -> void:
		var x := k()
		var open := minf(t / OPEN_T, 1.0)
		var zip := clampf((x - 0.3) / 0.7, 0.0, 1.0)
		var oa: Array = EVfx.rift_open(_shape[2], open, zip, 0.6, 1.0 - x * x)
		EVfx.rift(pd, _shape[0], _shape[1], oa[0], oa[1], _seed, t)
