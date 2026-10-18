class_name BEska
extends EEska
## 빗자루 검 손맛 데모의 에스카 (docs/eska-turn/README.md §0). 기술 이름·수치는 시험용.
## 두 모드를 버튼 하나(S · 터치 "모드")로 바꾸고, 바꾸는 순간 전환 공격이 나간다.
##   마법 모드(빗자루): X 흑백 균열(양손에 흰 기운·검은 기운을 0.5초 모아 앞 범위(RIFT_ZONE) 전체를 흑백 균열로 가름 — 한 방이 큼, 모으는 동안 움직일 수 있음) · A 낙성(EEska 그대로)
##   검술 모드(검): X 3연격(대각선 내려베기 "\" → 올려베기 "/" → 큰 내려베기 + 잔영) · 공중 X 두 번 · A 마검술 「공간참」
##   마법 → 검: 검무(빗자루가 검으로 펼쳐지자마자 몸 둘레로 검을 세 바퀴 돌려 주변을 벤다)
##   검 → 마법: 접힘 파동(몸 둘레로 라벤더 파동)
## 두 모드 연결(데모에서 시험하는 하나): 큰 내려베기·공간참에 맞은 표적에 틈 자국이 남고(BDummy, 최대 3),
## 검이 아닌 공격(마법)이 닿으면 자국이 한꺼번에 터진다.
## 휘두름 = 준비(wu) → 휘두름(sw, 칼끝은 BFx.head_f로 첫 프레임에 약 70%) → 거둠(rec). 휘두름 0.6 지점에서 한 번 판정.
## 참격은 기울인(rot) 납작한(sq) 타원의 호 — 기본 공격은 sq 0.3 안팎·rot ±35~40도로 대각선 초승달이 된다.
## 이동·점프·이단점프·그림의 몸·낙성은 EEska를 그대로 쓴다. 순간이동·물약·대마법은 데모에서 뺐다.

enum Mode { MAGIC, SWORD }

const SHOULDER := Vector2(1.5, -23.5) ## 그림 좌표(오른쪽을 보는 기준)의 어깨 — 휘두를 때 손이 이 둘레를 돈다
const ARM := 7.0
## 휘두름 표. 각도(도)는 오른쪽을 보는 기준, 아래가 +. c = 호 중심(발 기준), lunge = 휘두르는 순간 앞으로 미끄러지는 빠르기
## "\" = rot +, 위-뒤 끝(180)에서 바깥으로 불룩하게(270) 아래-앞 끝(360)으로. "/" = rot −, 아래-뒤 끝(180)에서 앞-아래로 불룩하게(90) 위-앞 끝(0)으로
const SWING := {
	"s1": {"wu": 0.04, "sw": 0.05, "rec": 0.16, "a0": 175.0, "a1": 365.0, "r": 58.0, "w": 16.0, "sq": 0.3, "rot": 38.0,
		"c": Vector2(16, -28), "dmg": 55, "lunge": 170.0, "hs": 0.05, "kick": 3.0, "cut": 80.0},
	"s2": {"wu": 0.035, "sw": 0.05, "rec": 0.16, "a0": 185.0, "a1": -5.0, "r": 60.0, "w": 17.0, "sq": 0.3, "rot": -38.0,
		"c": Vector2(16, -24), "dmg": 55, "lunge": 150.0, "hs": 0.05, "kick": 3.0, "cut": 80.0},
	"s3": {"wu": 0.09, "sw": 0.06, "rec": 0.3, "a0": 172.0, "a1": 372.0, "r": 108.0, "w": 26.0, "sq": 0.3, "rot": 32.0,
		"c": Vector2(26, -32), "dmg": 130, "lunge": 260.0, "hs": 0.09, "kick": 7.0, "cut": 130.0, "heavy": true, "scar": true, "echo": true},
	"air1": {"wu": 0.035, "sw": 0.05, "rec": 0.14, "a0": 175.0, "a1": 365.0, "r": 52.0, "w": 16.0, "sq": 0.32, "rot": 40.0,
		"c": Vector2(14, -26), "dmg": 55, "lunge": 60.0, "hs": 0.05, "kick": 3.0, "cut": 80.0},
	"air2": {"wu": 0.035, "sw": 0.05, "rec": 0.18, "a0": 185.0, "a1": -5.0, "r": 55.0, "w": 17.0, "sq": 0.32, "rot": -40.0,
		"c": Vector2(14, -22), "dmg": 55, "lunge": 60.0, "hs": 0.05, "kick": 3.0, "cut": 80.0},
	"skill": {"wu": 0.14, "sw": 0.045, "rec": 0.32, "a0": 105.0, "a1": -100.0, "r": 165.0, "w": 30.0, "sq": 0.2, "rot": 0.0,
		"c": Vector2(0, -22), "dmg": 110, "lunge": 120.0, "hs": 0.08, "kick": 6.0, "cut": 130.0, "heavy": true, "scar": true},
}
const COMBO := ["s1", "s2", "s3"]
const SLASH_ECHO_DELAY := 0.035 ## 큰 내려베기의 잔영 참격이 뒤따르는 시간
const SPACING := 22.0 ## 휘두르며 앞으로 미끄러질 때 앞 표적과 이만큼은 떨어져 멈춘다 (몸이 겹쳐 보이지 않게)
const LUNGE_DECEL := 2200.0
const CHAIN_AFTER := 0.04 ## 휘두름이 끝나고 이만큼 뒤부터 다음 휘두름·점프·모드 바꾸기로 끊을 수 있다
const COMBO_GAP := 0.4 ## 거둠이 끝나고 이 시간 안에 다시 누르면 연격이 이어진다
const AIR_MAX := 2
const HIT_PAD := 12.0 ## 판정은 그림보다 이만큼 넓게
const SKILL_CD := 2.5
const SPACE_LEN := 250.0 ## 공간참 가른 선 길이
const SPACE_DMG := 160 ## 공간참 틈이 터질 때 피해
## 검무 (마법 → 검): 빗자루가 펼쳐지는 동안(SPIN_UNFOLD) 검을 머리 위로 세웠다가, 몸 둘레로 세 바퀴(바퀴마다 기울기가 다름)
const SPIN_UNFOLD := 0.08
const SPIN_LOOPS := [
	{"sw": 0.12, "a0": 180.0, "a1": -180.0, "r": 70.0, "w": 17.0, "sq": 0.3, "rot": 0.0, "c": Vector2(0, -20), "dmg": 45},
	{"sw": 0.12, "a0": 180.0, "a1": -180.0, "r": 80.0, "w": 18.0, "sq": 0.45, "rot": 28.0, "c": Vector2(0, -24), "dmg": 45},
	{"sw": 0.11, "a0": 180.0, "a1": -180.0, "r": 92.0, "w": 22.0, "sq": 0.4, "rot": -24.0, "c": Vector2(0, -24), "dmg": 80, "heavy": true},
]
const SPIN_TAIL := 0.2 ## 마지막 바퀴 뒤 마무리 자세
const SPIN_BURST_R := 118.0
const SPIN_BURST_DMG := 40
const FOLD_T := 0.26 ## 접힘 파동 동작 시간
const FOLD_FIRE := 0.06
const FOLD_R := 66.0
const FOLD_DMG := 40
## 흑백 균열 (마법 기본): 누르면 양팔을 벌려 RIFT_FIRE초 모은 뒤 앞 범위(RIFT_ZONE) 전체가 갈라진다 — 겨누지 않고 범위 안은 모두 맞는다.
## 모으는 동안 움직이고 뛸 수 있다(바라보는 쪽은 그대로 — 뒷걸음질). 누르고 있어도 다시 쏘지 않는다 (한 방씩)
const RIFT_FIRE := 0.5
const RIFT_END := 0.72
const RIFT_ZONE := Rect2(26.0, -74.0, 184.0, 118.0) ## 몸 중심 기준, x는 바라보는 쪽으로
const RIFT_ANG := -0.32 ## 큰 틈의 기울기 (앞쪽이 올라감)
const RIFT_MOVE := 0.85 ## 모으는 동안 이동 빠르기 배수
const RIFT_DMG := 240
const FRONT_HAND := Vector2(12.5, -26.0) ## 균열을 모을 때 앞손 (팔을 앞으로 벌림)
const BACK_HAND := Vector2(-11.0, -25.5) ## 뒷손 (팔을 뒤로 벌림 — BArt가 그린다)
const MORPH_T := 0.07 ## 빗자루 ↔ 검 바뀌는 그림 시간

var mode := Mode.MAGIC
var morph := 0.0 ## 0 = 빗자루, 1 = 검 (그림이 읽는다)
var act := "" ## "" · "swing" · "spin" · "fold" · "rift"
var act_t := 0.0
var cur_id := ""
var cur: Dictionary = {}
var pose_on := false ## 그림: 손·무기를 아래 값으로 바로 놓는다
var hand_local := Vector2(3, -15.5)
var blade_vec := Vector2(-0.8, 0.6) ## 무기 방향 (길이 = 원근으로 줄어든 비율 0~1)
var skill_cd := 0.0
var swings := 0 ## 휘두른 수 (시험용)
var blade_hits := 0 ## 검이 맞힌 수 (시험용)
var rifts := 0 ## 흑백 균열이 터진 수 (시험용)
var last_target := Vector2.ZERO ## 마지막 흑백 균열 한가운데 (시험용)
var _combo_i := 0
var _combo_gap := 0.0
var _air_n := 0
var _hit_done := false
var _swept := false
var _at := Vector2.ZERO ## 휘두름 호 중심 (전역, 휘두르기 시작할 때 고정)
var _dir := 1
var _buf_mode := 0.0
var _fired := false ## 접힘 파동·흑백 균열이 이번 동작에서 나갔나
var _loop := -1 ## 검무: 지금 도는 바퀴 (-1 = 펼치는 중)
var _loop_hit := false
var _charge: Node2D


func _make_art() -> EArt:
	return BArt.new()


func bart() -> BArt:
	return art as BArt


## 시전(낙성)이 끝나 EEska._resume이 기억해 둔 입력을 꺼낼 때 — 이 데모의 동작으로
func _try_actions(dir_x: float) -> bool:
	return _start_actions(dir_x)


func skill_name() -> String:
	return "공간참" if mode == Mode.SWORD else "낙성"


func skill_ratio() -> float:
	return clampf(skill_cd / SKILL_CD, 0.0, 1.0) if mode == Mode.SWORD else cd_ratio("nakseong")


## 흑백 균열을 모으는 중의 진행도 (0~1, 아니면 -1) — 그림·모으기 이펙트가 읽는다
func rift_charge() -> float:
	return clampf(act_t / RIFT_FIRE, 0.0, 1.0) if act == "rift" and not _fired else -1.0


## 흑백 균열이 갈라질 범위 (전역)
func rift_zone() -> Rect2:
	var c := center()
	var x0 := c.x + (RIFT_ZONE.position.x if facing > 0 else -(RIFT_ZONE.position.x + RIFT_ZONE.size.x))
	return Rect2(x0, c.y + RIFT_ZONE.position.y, RIFT_ZONE.size.x, RIFT_ZONE.size.y)


## 큰 틈이 열릴 선의 양 끝 (전역) — 모으기 그림과 터짐이 같이 쓴다
func rift_line() -> PackedVector2Array:
	var z := rift_zone()
	var mid := Vector2(z.position.x + z.size.x * 0.5, z.position.y + z.size.y * 0.55)
	var d := Vector2(cos(RIFT_ANG) * float(facing), sin(RIFT_ANG))
	var hl := z.size.x * 0.5
	return PackedVector2Array([mid - d * hl, mid + d * hl])


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	st_t += delta
	for k in cooldowns:
		cooldowns[k] = maxf(float(cooldowns[k]) - delta, 0.0)
	skill_cd = maxf(skill_cd - delta, 0.0)
	_combo_gap = maxf(_combo_gap - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)
	combo_left = maxf(combo_left - delta, 0.0)
	if combo_left <= 0.0:
		hit_count = 0
		hit_damage = 0
	_coyote = COYOTE if is_on_floor() else maxf(_coyote - delta, 0.0)
	_jump_buf = maxf(_jump_buf - delta, 0.0)
	_atk_buf = maxf(_atk_buf - delta, 0.0)
	_buf_skill = maxf(_buf_skill - delta, 0.0)
	_buf_mode = maxf(_buf_mode - delta, 0.0)
	_poll_presses()
	var dir_x := Input.get_axis("es_left", "es_right")
	morph = move_toward(morph, 1.0 if mode == Mode.SWORD else 0.0, delta / MORPH_T)
	if st == St.CAST: # 낙성 (EEska 그대로)
		_cast(delta)
	elif act != "":
		_act(delta, dir_x)
	else:
		_free(delta, dir_x)
	move_and_slide()
	var on_floor := is_on_floor()
	if on_floor:
		_air_n = 0
		_air_jump = true
		if not _was_floor:
			EVfx.land_dust(global_position)
			Sfx.play(&"land", -14.0)
	_was_floor = on_floor
	_ground_fx(delta)
	_update_pose()
	art.tick(delta)


func _poll_presses() -> void:
	if Input.is_action_just_pressed("es_jump"):
		_jump_buf = JUMP_BUFFER
	if Input.is_action_just_pressed("es_attack"):
		_atk_buf = ATTACK_BUFFER
	if Input.is_action_just_pressed("es_skill"):
		_buf_skill = ACTION_BUFFER
	if Input.is_action_just_pressed(BStage.MODE_ACTION):
		_buf_mode = ACTION_BUFFER


## 아무 동작도 없을 때: 달리기·점프 + 동작 시작
func _free(delta: float, dir_x: float) -> void:
	_run(delta, dir_x)
	_try_jump(dir_x)
	_gravity(delta)
	_start_actions(dir_x)


## 기억해 둔 입력으로 동작 시작 (시작했으면 true)
func _start_actions(dir_x: float) -> bool:
	if _buf_mode > 0.0:
		_buf_mode = 0.0
		_switch_mode(dir_x)
		return true
	if _buf_skill > 0.0:
		if mode == Mode.SWORD and skill_cd <= 0.0:
			_buf_skill = 0.0
			skill_cd = SKILL_CD
			_start_swing("skill", dir_x)
			return true
		if mode == Mode.MAGIC and cd_left("nakseong") <= 0.0:
			_buf_skill = 0.0
			act = ""
			_start_cast("nakseong")
			return true
	if mode == Mode.MAGIC:
		if _atk_buf > 0.0: # 마법은 한 방씩 — 누르고 있어도 다시 쏘지 않는다
			_atk_buf = 0.0
			_start_rift(dir_x)
			return true
		return false
	if not (_atk_buf > 0.0 or Input.is_action_pressed("es_attack")):
		return false
	if is_on_floor():
		_atk_buf = 0.0
		if _combo_gap <= 0.0:
			_combo_i = 0
		_start_swing(COMBO[_combo_i], dir_x)
		_combo_i = (_combo_i + 1) % COMBO.size()
		return true
	if _air_n < AIR_MAX:
		_atk_buf = 0.0
		_start_swing("air1" if _air_n == 0 else "air2", dir_x)
		_air_n += 1
		return true
	return false


func _face(dir_x: float) -> void:
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1


func _act(delta: float, dir_x: float) -> void:
	act_t += delta
	match act:
		"swing":
			_swing(delta)
		"spin":
			_spin(delta)
		"fold":
			_fold(delta)
		"rift":
			_rift(delta, dir_x)


func _end_act() -> void:
	act = ""
	act_t = 0.0


# ═══════════════════════════════════════════════════════════
# 휘두름 (검술)
# ═══════════════════════════════════════════════════════════

func _start_swing(id: String, dir_x: float) -> void:
	_face(dir_x)
	act = "swing"
	act_t = 0.0
	cur_id = id
	cur = SWING[id]
	_hit_done = false
	_swept = false
	_dir = facing
	var c: Vector2 = cur.c
	_at = global_position + Vector2(c.x * facing, c.y)
	swings += 1
	art.squash(Vector2(1.08, 0.92) if id != "skill" else Vector2(1.14, 0.86)) # 준비: 살짝 웅크림
	if id == "skill":
		EVfx.sigil(bart().hand_global(), SIGIL)
		Sfx.play_pitch(&"kb_glint", 1.1, -6.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y, -30.0) # 공중 베기: 잠깐 떠 있음


func _swing(delta: float) -> void:
	var wu := float(cur.wu)
	var sw := float(cur.sw)
	var end := wu + sw + float(cur.rec)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, LUNGE_DECEL * delta)
		_gravity(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		_gravity(delta, 0.45)
	if not _swept and act_t >= wu:
		_swept = true
		_sweep()
	if _swept and not _hit_done and act_t >= wu + sw * 0.6:
		_hit_done = true
		_swing_hit()
	if act_t >= wu + sw + CHAIN_AFTER: # 거둠 중: 다음 휘두름·점프·스킬·모드 바꾸기로 끊는다
		var dx := Input.get_axis("es_left", "es_right")
		if _jump_buf > 0.0 and (_coyote > 0.0 or (_air_jump and not is_on_floor())):
			_end_act()
			_try_jump(dx)
			return
		if _buf_mode > 0.0 or _buf_skill > 0.0 or _atk_buf > 0.0 or Input.is_action_pressed("es_attack"):
			var keep := act_t
			act = ""
			_combo_gap = COMBO_GAP
			if _start_actions(dx):
				return
			act = "swing" # 아무것도 시작 못 함 (스킬 쿨다운·공중 횟수) → 하던 거둠을 이어 감
			act_t = keep
	if act_t >= end:
		_end_act()
		_combo_gap = COMBO_GAP


## 칼이 나가는 순간: 앞으로 미끄러짐 · 참격 그림 · 소리 · 몸 기울기 · 잔상
func _sweep() -> void:
	var room := maxf(_room_ahead() - SPACING, 0.0)
	velocity.x = float(_dir) * minf(float(cur.lunge), sqrt(2.0 * LUNGE_DECEL * room))
	var heavy := bool(cur.get("heavy", false))
	BFx.slash(_at, cur, _dir)
	if bool(cur.get("echo", false)): # 큰 내려베기: 조금 작고 더 기운 잔영 참격이 한 박자 뒤따른다
		var echo := cur.duplicate()
		echo.r = float(cur.r) * 0.84
		echo.w = float(cur.w) * 0.6
		echo.rot = float(cur.rot) + 12.0
		echo.heavy = false
		var at := _at + Vector2(-_dir * 6.0, 4.0)
		var d := _dir
		get_tree().create_timer(SLASH_ECHO_DELAY, false).timeout.connect(func() -> void: BFx.slash(at, echo, d))
	art.squash(Vector2(0.94, 1.06))
	bart().kick_lean(9.0) # 휘두르는 쪽으로 몸이 확 기운다
	Sfx.play_pitch(&"bl_swish_big" if heavy else &"bl_swish", randf_range(0.95, 1.06), -2.0 if heavy else -4.0)
	# 잔상: 휘두르기 직전 모습이 뒤에 옅게 남는다 (속도감 — 큰 휘두름은 더 진하고 길게)
	EVfx.afterimage(art, 0.16 if heavy else 0.1, EVfx.VIOLET, Vector2(-_dir * 4.0, 0), 0.6 if heavy else 0.32)
	if cur_id == "skill":
		var sc := BFx.SpaceCut.new()
		sc.len = SPACE_LEN
		sc.scale = Vector2(float(_dir), 1.0)
		sc.on_burst = _space_burst
		PVfx.add(sc, _at + Vector2(_dir * 6.0, 0), false)
		Fx.zoom_punch(0.04)


## 바라보는 쪽으로 가장 가까운 표적 앞 가장자리까지 거리 (높이가 겹치는 것만, 없으면 아주 큼)
func _room_ahead() -> float:
	var best := 9999.0
	var me := hurt_rect()
	for d: Node2D in ETarget.alive(get_tree()):
		var hr: Rect2 = d.hit_rect()
		if hr.end.y < me.position.y or hr.position.y > me.end.y:
			continue
		var gap := (hr.position.x - me.end.x) if _dir > 0 else (me.position.x - hr.end.x)
		if gap > -6.0:
			best = minf(best, maxf(gap, 0.0))
	return best


## 호 판정: 사각형의 점 9개 중 하나라도 휘두른 타원 부채꼴 안에 들면. 각도는 휘두른 쪽으로 a0부터 잰다 (한 바퀴·180도 넘김도 됨)
## 납작한 대각선 참격도 위아래로 넉넉하게 맞도록 납작함은 0.55 아래로 내리지 않는다
func _arc_hits(rect: Rect2, at: Vector2, spec: Dictionary, dir: int) -> bool:
	var r := float(spec.r) + HIT_PAD
	var sq := maxf(float(spec.sq), 0.55)
	var rot := deg_to_rad(float(spec.rot))
	var a0 := deg_to_rad(float(spec.a0))
	var a1 := deg_to_rad(float(spec.a1))
	var span := absf(a1 - a0)
	var dirn := signf(a1 - a0)
	var p0 := rect.position
	var p1 := rect.end
	var m := rect.get_center()
	for pt: Vector2 in [m, p0, p1, Vector2(p0.x, p1.y), Vector2(p1.x, p0.y), Vector2(m.x, p0.y), Vector2(m.x, p1.y), Vector2(p0.x, m.y), Vector2(p1.x, m.y)]:
		var q := pt - at
		q.x *= float(dir)
		q = q.rotated(-rot)
		var e := Vector2(q.x / r, q.y / (r * sq))
		var rho := e.length()
		if rho > 1.0:
			continue
		if rho < 0.3 or span >= TAU - 0.01:
			return true
		var d := fposmod((atan2(e.y, e.x) - a0) * dirn, TAU)
		if d <= span + 0.3 or d >= TAU - 0.3:
			return true
	return false


## 판정 한 번: 호 안의 표적마다 피해 · 맞은 자리 참격선 · 멈춤
func _swing_hit() -> void:
	var heavy := bool(cur.get("heavy", false))
	var any := false
	var kick := Vector2.ZERO
	for d: Node2D in ETarget.alive(get_tree()):
		if not _arc_hits(d.hit_rect(), _at, cur, _dir):
			continue
		var hit := _contact(d, _at, cur, _dir)
		var tan: Vector2 = hit[1]
		_blade_deal(d, int(cur.dmg), heavy, hit[0], tan, float(cur.cut), bool(cur.get("scar", false)))
		kick += tan
		any = true
	if not any:
		return
	Fx.hitstop(float(cur.hs))
	PVfx.kick(kick.normalized() * float(cur.kick))
	if heavy:
		Fx.shake(0.45, 0.18)
		Fx.zoom_punch(0.05)


## 표적에서 칼이 닿은 자리와 참격선 방향(전역)
func _contact(d: Node2D, at: Vector2, spec: Dictionary, dir: int) -> Array:
	var sq := float(spec.sq)
	var rot := deg_to_rad(float(spec.rot))
	var a0 := deg_to_rad(float(spec.a0))
	var a1 := deg_to_rad(float(spec.a1))
	var span := absf(a1 - a0)
	var dirn := signf(a1 - a0)
	var rel: Vector2 = d.center() - at
	rel.x *= float(dir)
	var q := rel.rotated(-rot)
	q.y /= maxf(sq, 0.1)
	var k := clampf(fposmod((atan2(q.y, q.x) - a0) * dirn, TAU), 0.0, span)
	var a := a0 + dirn * k
	# 참격선 방향 = 호의 시작 → 끝을 잇는 현(弦): 내려베기는 "\", 올려베기는 "/"로 표적을 가로지른다
	# (그 순간의 접선을 쓰면 초승달과 겹쳐 묻힘). 한 바퀴 도는 검무는 현이 없으니 접선을 비스듬히 눕힌다
	var tan := (BFx.ell(1.0, sq, rot, a1) - BFx.ell(1.0, sq, rot, a0))
	if tan.length() < 0.2:
		tan = BFx.ell_t(sq, rot, a, dirn).rotated(0.5)
	tan = tan.normalized()
	tan.x *= float(dir)
	var on_arc := BFx.ell(float(spec.r) * 0.85, sq, rot, a)
	on_arc.x *= float(dir)
	var p := (at + on_arc).lerp(d.center(), 0.6)
	var hr: Rect2 = d.hit_rect()
	p = Vector2(clampf(p.x, hr.position.x + 2.0, hr.end.x - 2.0), clampf(p.y, hr.position.y + 4.0, hr.end.y - 4.0))
	return [p, tan]


## 검 피해 한 번: 표적은 1~2프레임 새하얗게(BDummy) · 관통 참격선 · 흰·보라 불티 · 파편
func _blade_deal(d: Node2D, dmg: int, heavy: bool, at: Vector2, tan: Vector2, cut_len: float, scar: bool) -> void:
	d.take_hit(dmg, global_position, {"heavy": heavy, "launch": 1.5 if heavy else 0.4, "blade": true,
		"scar": scar, "scar_at": at, "scar_angle": tan.angle()})
	blade_hits += 1
	hit_count += 1
	hit_damage += dmg
	combo_left = COMBO_WINDOW
	BFx.cut(at, tan, cut_len, heavy)
	EVfx.pixels(at, 6 if heavy else 4, 260.0 if heavy else 190.0, tan, 30.0, 0.22, Vector2(0, 260))
	EVfx.dark_bits(at, 4 if heavy else 2, 150.0, tan, 40.0, 0.28, 0)
	if heavy:
		EVfx.shards(at, 5, 170.0, Vector2(3, 3), 60.0)
	Sfx.play_pitch(&"bl_cut", randf_range(0.94, 1.06) * (0.85 if heavy else 1.0), -3.0 if heavy else -5.0)


## 공간참: 가른 선이 한 박자 뒤 틈으로 터진다 — 그때 선 위에 있던 표적
func _space_burst() -> void:
	var from := _at
	var to := _at + Vector2(_dir * (SPACE_LEN + 6.0), 0)
	var any := false
	for d: Node2D in ETarget.alive(get_tree()):
		var hr: Rect2 = d.hit_rect().grow_individual(0, 14, 0, 14)
		var x0 := minf(from.x, to.x)
		var x1 := maxf(from.x, to.x)
		if hr.end.x < x0 or hr.position.x > x1 or from.y < hr.position.y or from.y > hr.end.y:
			continue
		var p := Vector2(clampf(d.center().x, x0, x1), from.y)
		_blade_deal(d, SPACE_DMG, true, p, Vector2(_dir, 0), 90.0, false)
		EVfx.dark_burst(p, 22.0)
		any = true
	Sfx.play(&"kb_burst", -4.0)
	if any:
		Fx.hitstop(0.07)
		PVfx.kick(Vector2(_dir * 5.0, 0))
		Fx.shake(0.4, 0.16)


# ═══════════════════════════════════════════════════════════
# 모드 바꾸기 · 전환 공격
# ═══════════════════════════════════════════════════════════

func _switch_mode(dir_x: float) -> void:
	_combo_i = 0
	_cancel_charge()
	_face(dir_x)
	_dir = facing
	act_t = 0.0
	if mode == Mode.MAGIC:
		mode = Mode.SWORD
		act = "spin"
		_loop = -1
		_fired = false
		swings += 1
		var uf := BFx.Unfold.new()
		uf.dir = Vector2.UP.rotated(0.25 * float(_dir))
		uf.len = BArt.BLADE_LEN
		PVfx.add(uf, bart().hand_global(), false)
		Sfx.play(&"bl_unfold", -3.0)
		EVfx.pixels(bart().hand_global(), 6, 110.0, Vector2.UP, 70.0, 0.3)
		art.squash(Vector2(0.9, 1.12))
	else:
		mode = Mode.MAGIC
		act = "fold"
		_fired = false
		Sfx.play(&"bl_fold", -4.0)


## 검무 한 바퀴의 시작 시각
func _loop_start(k: int) -> float:
	var t := SPIN_UNFOLD
	for i in k:
		t += float(SPIN_LOOPS[i].sw)
	return t


func _spin(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	_gravity(delta, 0.4 if not is_on_floor() else 1.0)
	var n := SPIN_LOOPS.size()
	var k := -1
	for i in n:
		if act_t >= _loop_start(i):
			k = i
	if k >= 0 and act_t < _loop_start(n) and k != _loop:
		_loop = k
		_loop_hit = false
		var spec: Dictionary = SPIN_LOOPS[k]
		var c: Vector2 = spec.c
		_at = global_position + Vector2(c.x * _dir, c.y)
		BFx.slash(_at, spec, _dir)
		var halo := BFx.Halo.new()
		halo.r = float(spec.r) * 0.96
		halo.sq = float(spec.sq)
		halo.rot = deg_to_rad(float(spec.rot))
		halo.scale = Vector2(float(_dir), 1.0)
		PVfx.add(halo, _at, false)
		Sfx.play_pitch(&"bl_swish_big", 1.0 + 0.12 * float(k), -3.0)
		EVfx.afterimage(art, 0.12, EVfx.VIOLET, Vector2.ZERO, 0.4)
	if _loop >= 0 and not _loop_hit and act_t >= _loop_start(_loop) + float(SPIN_LOOPS[_loop].sw) * 0.5:
		_loop_hit = true
		_spin_hit(SPIN_LOOPS[_loop])
	if not _fired and act_t >= _loop_start(n):
		_fired = true
		_spin_burst()
	if act_t >= _loop_start(n) + SPIN_TAIL:
		facing = _dir
		act = ""
		act_t = 0.0
		_combo_gap = COMBO_GAP
		_start_actions(Input.get_axis("es_left", "es_right"))


func _spin_hit(spec: Dictionary) -> void:
	var heavy := bool(spec.get("heavy", false))
	var any := false
	for d: Node2D in ETarget.alive(get_tree()):
		if not _arc_hits(d.hit_rect(), _at, spec, _dir):
			continue
		var hit := _contact(d, _at, spec, _dir)
		_blade_deal(d, int(spec.dmg), heavy, hit[0], hit[1], 70.0 if heavy else 56.0, false)
		any = true
	if any:
		Fx.hitstop(0.06 if heavy else 0.03)
		Fx.shake(0.3 if heavy else 0.15, 0.12)


## 검무 마무리: 흰 고리가 크게 퍼지고 사방으로 빛줄기·불티, 고리 안 표적에 한 번 더 피해
func _spin_burst() -> void:
	var c := center()
	var w := BFx.Wave.new()
	w.r1 = SPIN_BURST_R
	w.bright = true
	PVfx.add(w, c, false)
	EVfx.pixels(c, 14, 300.0, Vector2.ZERO, 180.0, 0.35, Vector2(0, 120))
	EVfx.feathers(c, 3, 120.0, Vector2(10, 6))
	Fx.flash(Color(0.9, 0.85, 1.0, 0.18), 0.12)
	Fx.zoom_punch(0.06)
	Fx.shake(0.5, 0.2)
	Sfx.play_pitch(&"es_slash_big", 1.15, -2.0)
	for d: Node2D in ETarget.alive(get_tree()):
		var q: Vector2 = (d.center() - c) / Vector2(1.0, BFx.Wave.SQ)
		if q.length() <= SPIN_BURST_R + 10.0:
			_blade_deal(d, SPIN_BURST_DMG, true, d.center(), (d.center() - c).normalized().rotated(0.6), 60.0, false)


func _fold(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
	_gravity(delta, 0.6 if not is_on_floor() else 1.0)
	if not _fired and act_t >= FOLD_FIRE:
		_fired = true
		var c := center()
		PVfx.add(BFx.Wave.new(), c, false)
		var any := false
		for d: Node2D in ETarget.alive(get_tree()):
			var q: Vector2 = (d.center() - c) / Vector2(1.0, BFx.Wave.SQ)
			if q.length() <= FOLD_R + 14.0:
				_blade_deal(d, FOLD_DMG, false, d.center(), (d.center() - c).normalized(), 40.0, false)
				any = true
		if any:
			Fx.hitstop(0.04)
		Fx.zoom_punch(0.02)
	if act_t >= FOLD_T:
		_end_act()
		_start_actions(Input.get_axis("es_left", "es_right"))


# ═══════════════════════════════════════════════════════════
# 흑백 균열 (마법 기본)
# ═══════════════════════════════════════════════════════════

func _start_rift(dir_x: float) -> void:
	_face(dir_x)
	act = "rift"
	act_t = 0.0
	_fired = false
	var ch := BFx.Charge.new()
	ch.eska = self
	PVfx.add(ch, Vector2.ZERO, false)
	_charge = ch
	Sfx.play(&"bl_charge", -4.0)


func _cancel_charge() -> void:
	if is_instance_valid(_charge):
		_charge.queue_free()
	_charge = null


func _rift(delta: float, dir_x: float) -> void:
	# 모으는 동안도 움직이고 뛴다 — 바라보는 쪽은 그대로 (뒷걸음질하며 모을 수 있다)
	var keep := facing
	_run(delta, dir_x, RIFT_MOVE)
	facing = keep
	_try_jump(dir_x)
	_gravity(delta)
	if not _fired and act_t >= RIFT_FIRE:
		_fired = true
		_fire_rift()
	if not _fired and _buf_mode > 0.0: # 모으는 중에 모드를 바꾸면 끊긴다
		_end_act()
		_cancel_charge()
		_start_actions(Input.get_axis("es_left", "es_right"))
		return
	if act_t >= RIFT_END:
		_end_act()
		_start_actions(Input.get_axis("es_left", "es_right"))


## 터짐: 앞 범위 전체가 흑백 균열로 갈라진다 — 섬광 · 흰 금과 검은 금이 엇갈려 갈라짐 · 흑백 파편 · 검은 연기. 범위 안은 모두 맞는다
func _fire_rift() -> void:
	_cancel_charge()
	rifts += 1
	var line := rift_line()
	var zone := rift_zone()
	last_target = (line[0] + line[1]) * 0.5
	var rf := BFx.Rift.new()
	rf.len = RIFT_ZONE.size.x
	rf.ang = RIFT_ANG
	rf.scale = Vector2(float(facing), 1.0)
	PVfx.add(rf, last_target, false)
	art.squash(Vector2(1.12, 0.9))
	bart().snap_flash()
	Sfx.play(&"bl_rift", -1.0)
	Fx.hitstop(0.1)
	Fx.shake(0.65, 0.24)
	Fx.zoom_punch(0.07)
	Fx.flash(Color(1, 1, 1, 0.22), 0.1)
	PVfx.kick(Vector2(facing * 6.0, -2.0))
	for d: Node2D in ETarget.alive(get_tree()):
		if zone.intersects(d.hit_rect()):
			deal(d, RIFT_DMG, true, center())


# ═══════════════════════════════════════════════════════════
# 그림에 넘기는 손·무기 자세
# ═══════════════════════════════════════════════════════════

func _update_pose() -> void:
	pose_on = false
	match act:
		"swing":
			pose_on = true
			var wu := float(cur.wu)
			var sw := float(cur.sw)
			var a0 := deg_to_rad(float(cur.a0))
			var a1 := deg_to_rad(float(cur.a1))
			var dirn := signf(a1 - a0)
			var a := a0
			if act_t < wu: # 준비: 시작 각보다 조금 더 젖혀 두었다가
				a = a0 - dirn * 0.3 * (1.0 - act_t / maxf(wu, 0.001))
			elif act_t < wu + sw:
				a = lerpf(a0, a1, BFx.head_f(act_t - wu, sw))
			else: # 거둠: 휘두른 끝에 잠깐 머문 뒤 원래 자세 쪽으로
				var q := clampf((act_t - wu - sw) / maxf(float(cur.rec), 0.001), 0.0, 1.0)
				a = a1 + dirn * 0.12 * sin(minf(q * 3.0, 1.0) * PI) # 끝에서 살짝 더 밀려 나갔다 멈춤
				if q > 0.6:
					pose_on = false
			var v := BFx.ell(1.0, float(cur.sq), deg_to_rad(float(cur.rot)), a)
			blade_vec = v
			hand_local = SHOULDER + v * ARM
		"spin":
			pose_on = true
			if _loop < 0: # 펼치는 중: 검을 머리 위로 세운다
				blade_vec = Vector2.from_angle(-1.75)
				hand_local = SHOULDER + Vector2(2.0, -5.0)
			else:
				var spec: Dictionary = SPIN_LOOPS[_loop]
				var lt := act_t - _loop_start(_loop)
				var a := lerpf(deg_to_rad(float(spec.a0)), deg_to_rad(float(spec.a1)), BFx.head_f(lt, float(spec.sw)))
				if act_t >= _loop_start(SPIN_LOOPS.size()):
					a = deg_to_rad(float(spec.a1)) - 0.3 # 마무리: 검을 앞으로 뻗은 채 멈춤
				var v := BFx.ell(1.0, float(spec.sq), deg_to_rad(float(spec.rot)), a)
				# 칼이 몸 뒤로 가면 몸도 돌아선다 (그림을 좌우로 뒤집어 제자리에서 도는 느낌)
				facing = _dir if v.x >= -0.15 else -_dir
				var lv := Vector2(v.x * float(_dir) * float(facing), v.y)
				blade_vec = lv
				hand_local = SHOULDER + lv * ARM
		"fold":
			pose_on = true
			var q := clampf(act_t / FOLD_T, 0.0, 1.0)
			var a := lerpf(-2.4, -0.6, 1.0 - pow(1.0 - q, 3.0)) # 칼을 머리 위로 크게 돌려 접는다
			blade_vec = Vector2.from_angle(a)
			hand_local = SHOULDER + Vector2(2.0, -4.0) + blade_vec * 4.0
		"rift":
			pose_on = true
			var c := clampf(act_t / RIFT_FIRE, 0.0, 1.0)
			var open := 1.0 - pow(1.0 - minf(c * 3.0, 1.0), 3.0) # 양팔을 빠르게 벌림
			hand_local = Vector2(3.0, -16.0).lerp(FRONT_HAND, open)
			if _fired: # 터진 뒤: 앞손을 앞으로 쥐듯 내밈
				hand_local = FRONT_HAND + Vector2(1.5, 1.0)
			blade_vec = Vector2.from_angle(2.5)
