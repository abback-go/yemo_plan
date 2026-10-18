class_name BEska
extends EEska
## 빗자루 검 손맛 데모의 에스카 (docs/eska-turn/README.md §0). 기술 이름·수치는 시험용.
## 두 모드를 버튼 하나(S · 터치 "모드")로 바꾸고, 바꾸는 순간 전환 공격이 나간다.
##   마법 모드(빗자루): X 균열 점화(앞의 표적 자리에서 공간이 갈라짐, 누르고 있으면 계속) · A 낙성(EEska 그대로)
##   검술 모드(검): X 3연격(내려베기 → 올려베기 → 회전 가르기) · 공중 X 두 번 · A 마검술 「공간참」
##   마법 → 검: 펼침 베기(빗자루 솔이 칼날로 접혀 뻗으며 앞을 벰) / 검 → 마법: 접힘 파동(몸 둘레로 라벤더 파동)
## 두 모드 연결(데모에서 시험하는 하나): 회전 가르기·공간참에 맞은 표적에 틈 자국이 남고(BDummy, 최대 3),
## 검이 아닌 공격(마법)이 닿으면 자국이 한꺼번에 터진다.
## 휘두름 = 준비(wu) → 휘두름(sw, 칼끝은 BFx.head_f로 첫 프레임에 약 70%) → 거둠(rec). 휘두름 0.6 지점에서 한 번 판정.
## 이동·점프·이단점프·그림의 몸·낙성은 EEska를 그대로 쓴다. 순간이동·물약·대마법은 데모에서 뺐다.

enum Mode { MAGIC, SWORD }

const SHOULDER := Vector2(1.5, -23.5) ## 그림 좌표(오른쪽을 보는 기준)의 어깨 — 휘두를 때 손이 이 둘레를 돈다
const ARM := 7.0
## 휘두름 표. 각도(도)는 오른쪽을 보는 기준, 아래가 +. c = 호 중심(발 기준), lunge = 휘두르는 순간 앞으로 미끄러지는 빠르기
const SWING := {
	"s1": {"wu": 0.04, "sw": 0.05, "rec": 0.16, "a0": -130.0, "a1": 50.0, "r": 46.0, "w": 13.0, "sq": 0.9, "rot": -10.0,
		"c": Vector2(4, -22), "dmg": 55, "lunge": 170.0, "hs": 0.05, "kick": 3.0, "cut": 72.0},
	"s2": {"wu": 0.035, "sw": 0.05, "rec": 0.16, "a0": 60.0, "a1": -150.0, "r": 50.0, "w": 14.0, "sq": 0.82, "rot": 12.0,
		"c": Vector2(4, -22), "dmg": 55, "lunge": 150.0, "hs": 0.05, "kick": 3.0, "cut": 72.0},
	"s3": {"wu": 0.09, "sw": 0.07, "rec": 0.3, "a0": 185.0, "a1": -75.0, "r": 82.0, "w": 20.0, "sq": 0.28, "rot": -9.0,
		"c": Vector2(2, -24), "dmg": 130, "lunge": 260.0, "hs": 0.09, "kick": 7.0, "cut": 110.0, "heavy": true, "scar": true},
	"air1": {"wu": 0.035, "sw": 0.05, "rec": 0.14, "a0": -120.0, "a1": 70.0, "r": 46.0, "w": 13.0, "sq": 0.95, "rot": -20.0,
		"c": Vector2(3, -22), "dmg": 55, "lunge": 60.0, "hs": 0.05, "kick": 3.0, "cut": 72.0},
	"air2": {"wu": 0.035, "sw": 0.05, "rec": 0.18, "a0": 75.0, "a1": -140.0, "r": 48.0, "w": 14.0, "sq": 0.9, "rot": 18.0,
		"c": Vector2(3, -22), "dmg": 55, "lunge": 60.0, "hs": 0.05, "kick": 3.0, "cut": 72.0},
	"draw": {"wu": 0.07, "sw": 0.05, "rec": 0.18, "a0": 130.0, "a1": -55.0, "r": 58.0, "w": 15.0, "sq": 0.55, "rot": -8.0,
		"c": Vector2(3, -20), "dmg": 80, "lunge": 200.0, "hs": 0.06, "kick": 4.0, "cut": 80.0},
	"skill": {"wu": 0.14, "sw": 0.045, "rec": 0.32, "a0": 105.0, "a1": -100.0, "r": 150.0, "w": 26.0, "sq": 0.2, "rot": 0.0,
		"c": Vector2(0, -22), "dmg": 110, "lunge": 120.0, "hs": 0.08, "kick": 6.0, "cut": 130.0, "heavy": true, "scar": true},
}
const COMBO := ["s1", "s2", "s3"]
const SPACING := 22.0 ## 휘두르며 앞으로 미끄러질 때 앞 표적과 이만큼은 떨어져 멈춘다 (몸이 겹쳐 보이지 않게)
const LUNGE_DECEL := 2200.0
const CHAIN_AFTER := 0.04 ## 휘두름이 끝나고 이만큼 뒤부터 다음 휘두름·점프·모드 바꾸기로 끊을 수 있다
const COMBO_GAP := 0.4 ## 거둠이 끝나고 이 시간 안에 다시 누르면 연격이 이어진다
const AIR_MAX := 2
const SKILL_CD := 2.5
const SPACE_LEN := 250.0 ## 공간참 가른 선 길이
const SPACE_DMG := 160 ## 공간참 틈이 터질 때 피해
const FOLD_T := 0.26 ## 접힘 파동 동작 시간
const FOLD_FIRE := 0.06
const FOLD_R := 66.0
const FOLD_DMG := 40
const SHOT_EVERY := 0.24 ## 균열 점화 간격 (누르고 있으면 계속)
const SHOT_FIRE := 0.05
const SHOT_POSE := 0.2
const SHOT_RANGE := Vector2(260, 120) ## 앞쪽 가로·위아래로 이 안의 가장 가까운 표적을 겨눈다
const SHOT_DMG := 45
const MORPH_T := 0.07 ## 빗자루 ↔ 검 바뀌는 그림 시간

var mode := Mode.MAGIC
var morph := 0.0 ## 0 = 빗자루, 1 = 검 (그림이 읽는다)
var act := "" ## "" · "swing" · "fold" · "shot"
var act_t := 0.0
var cur_id := ""
var cur: Dictionary = {}
var pose_on := false ## 그림: 손·무기를 아래 값으로 바로 놓는다
var hand_local := Vector2(3, -15.5)
var blade_vec := Vector2(-0.8, 0.6) ## 무기 방향 (길이 = 원근으로 줄어든 비율 0~1)
var skill_cd := 0.0
var swings := 0 ## 휘두른 수 (시험용)
var blade_hits := 0 ## 검이 맞힌 수 (시험용)
var last_target := Vector2.ZERO ## 마지막 균열 점화 자리 (시험용)
var _combo_i := 0
var _combo_gap := 0.0
var _air_n := 0
var _hit_done := false
var _swept := false
var _at := Vector2.ZERO ## 휘두름 호 중심 (전역, 휘두르기 시작할 때 고정)
var _dir := 1
var _buf_mode := 0.0
var _shot_cd := 0.0
var _fired := false ## 접힘 파동·균열 점화가 이번 동작에서 나갔나


func _make_art() -> EArt:
	return BArt.new()


func bart() -> BArt:
	return art as BArt


## 시전(낙성)이 끝나 EEska._resume이 기억해 둔 입력을 꺼낼 때 — 이 데모의 동작으로
func _try_actions(dir_x: float) -> bool:
	return _start_actions(dir_x)


func skill_name() -> String:
	return "공간참" if mode == Mode.SWORD else "낙성"


func skill_left() -> float:
	return skill_cd if mode == Mode.SWORD else cd_left("nakseong")


func skill_ratio() -> float:
	return clampf(skill_cd / SKILL_CD, 0.0, 1.0) if mode == Mode.SWORD else cd_ratio("nakseong")


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	st_t += delta
	for k in cooldowns:
		cooldowns[k] = maxf(float(cooldowns[k]) - delta, 0.0)
	skill_cd = maxf(skill_cd - delta, 0.0)
	_shot_cd = maxf(_shot_cd - delta, 0.0)
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
	var want_atk := _atk_buf > 0.0 or Input.is_action_pressed("es_attack")
	if not want_atk:
		return false
	if mode == Mode.SWORD:
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
	if _shot_cd <= 0.0:
		_atk_buf = 0.0
		_start_shot(dir_x)
		return true
	return false


func _face(dir_x: float) -> void:
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1


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


func _act(delta: float, dir_x: float) -> void:
	act_t += delta
	match act:
		"swing":
			_swing(delta)
		"fold":
			_fold(delta)
		"shot":
			_shot(delta, dir_x)


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
		if _buf_mode > 0.0 or _buf_skill > 0.0 or _atk_buf > 0.0:
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


func _end_act() -> void:
	act = ""
	act_t = 0.0


## 칼이 나가는 순간: 앞으로 미끄러짐 · 참격 그림 · 소리 · 몸 기울기
func _sweep() -> void:
	var room := maxf(_room_ahead() - SPACING, 0.0)
	velocity.x = float(_dir) * minf(float(cur.lunge), sqrt(2.0 * LUNGE_DECEL * room))
	var heavy := bool(cur.get("heavy", false))
	BFx.slash(_at, cur, _dir)
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


## 판정 한 번: 호 안의 표적마다 피해 · 맞은 자리 참격선 · 멈춤
func _swing_hit() -> void:
	var r := float(cur.r) + 8.0
	var heavy := bool(cur.get("heavy", false))
	var any := false
	var kick := Vector2.ZERO
	for d: Node2D in ETarget.alive(get_tree()):
		if not _sector_hits(d.hit_rect(), _at, r, float(cur.a0), float(cur.a1), float(cur.sq), float(cur.rot), _dir):
			continue
		var hit := _contact(d)
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


## 표적에서 칼이 닿은 자리와 그 순간 칼이 지나가던 방향(전역)
func _contact(d: Node2D) -> Array:
	var sq := float(cur.sq)
	var rot := deg_to_rad(float(cur.rot))
	var a0 := deg_to_rad(float(cur.a0))
	var a1 := deg_to_rad(float(cur.a1))
	var rel: Vector2 = d.center() - _at
	rel.x *= float(_dir)
	var q := rel.rotated(-rot)
	q.y /= maxf(sq, 0.1)
	var a := clampf(atan2(q.y, q.x), minf(a0, a1), maxf(a0, a1))
	var dirn := signf(a1 - a0)
	# 참격선 방향 = 호의 시작 → 끝을 잇는 현(弦): 내려베기는 "\", 올려베기는 "/", 가로 휘두름은 거의 가로로 표적을 가로지른다
	# (그 순간의 접선을 쓰면 초승달과 겹쳐 묻힘)
	var tan := (BFx.ell(1.0, sq, rot, a1) - BFx.ell(1.0, sq, rot, a0)).normalized()
	if tan == Vector2.ZERO:
		tan = BFx.ell_t(sq, rot, a, dirn)
	tan.x *= float(_dir)
	var on_arc := BFx.ell(float(cur.r) * 0.8, sq, rot, a)
	on_arc.x *= float(_dir)
	var p := (_at + on_arc).lerp(d.center(), 0.6)
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
	if mode == Mode.MAGIC:
		mode = Mode.SWORD
		_start_swing("draw", dir_x) # 펼침 베기
		var uf := BFx.Unfold.new()
		uf.dir = _unfold_dir()
		uf.len = BArt.BLADE_LEN
		PVfx.add(uf, bart().hand_global(), false)
		Sfx.play(&"bl_unfold", -3.0)
		EVfx.pixels(bart().hand_global(), 5, 90.0, Vector2.ZERO, 180.0, 0.25)
	else:
		mode = Mode.MAGIC
		_face(dir_x)
		act = "fold"
		act_t = 0.0
		_fired = false
		Sfx.play(&"bl_fold", -4.0)


## 펼침 섬광 방향 (지금 칼이 놓일 방향, 전역)
func _unfold_dir() -> Vector2:
	var v := BFx.ell(1.0, float(cur.sq), deg_to_rad(float(cur.rot)), deg_to_rad(float(cur.a0)))
	v.x *= float(facing)
	return v.normalized()


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
# 균열 점화 (마법 기본)
# ═══════════════════════════════════════════════════════════

func _start_shot(dir_x: float) -> void:
	_face(dir_x)
	act = "shot"
	act_t = 0.0
	_fired = false
	_shot_cd = SHOT_EVERY


func _shot(delta: float, dir_x: float) -> void:
	_run(delta, dir_x, 0.55)
	_try_jump(dir_x)
	_gravity(delta)
	if not _fired and act_t >= SHOT_FIRE:
		_fired = true
		_fire_shot()
	if act_t >= SHOT_POSE:
		_end_act()
		return
	if act_t >= SHOT_FIRE and (_buf_mode > 0.0 or _buf_skill > 0.0):
		_end_act()
		_start_actions(dir_x)


func _fire_shot() -> void:
	var tip := bart().broom_tip()
	EVfx.sigil(tip, 1.0)
	var target: Node2D = null
	var best := INF
	for d: Node2D in ETarget.alive(get_tree()):
		var dv: Vector2 = d.center() - center()
		if dv.x * float(facing) < -6.0 or absf(dv.x) > SHOT_RANGE.x or absf(dv.y) > SHOT_RANGE.y:
			continue
		if dv.length() < best:
			best = dv.length()
			target = d
	var at := center() + Vector2(facing * 110.0, -4.0)
	if target != null:
		at = target.center() + Vector2(randf_range(-4, 4), randf_range(-8, 6))
	last_target = at
	var tear := EEska.PathTear.new()
	var half := Vector2.from_angle(randf_range(-1.1, -0.5) if randf() < 0.5 else randf_range(0.5, 1.1)) * 15.0
	tear.to = half * 2.0
	PVfx.add(tear, at - half, false)
	EVfx.pixels(at, 4, 120.0, Vector2.ZERO, 180.0, 0.25)
	Sfx.play_pitch(&"es_tear", randf_range(1.15, 1.3), -6.0)
	Sfx.play_pitch(&"es_snap", 0.9, -8.0)
	if target != null:
		deal(target, SHOT_DMG, false, center())


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
		"fold":
			pose_on = true
			var q := clampf(act_t / FOLD_T, 0.0, 1.0)
			var a := lerpf(-2.4, -0.6, 1.0 - pow(1.0 - q, 3.0)) # 칼을 머리 위로 크게 돌려 접는다
			blade_vec = Vector2.from_angle(a)
			hand_local = SHOULDER + Vector2(2.0, -4.0) + blade_vec * 4.0
		"shot":
			pose_on = true
			hand_local = Vector2(11.0, -24.0)
			blade_vec = Vector2(-1.0, 0.12).normalized() # 자루 끝을 앞으로 겨누고 솔은 뒤로
