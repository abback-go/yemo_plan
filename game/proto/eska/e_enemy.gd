class_name EEnemy
extends CharacterBody2D
## 에스카 시제품의 적 공통 바탕 — 허수아비와 같은 표적 약속(ETarget)을 지키고, 에스카를 맞힐 수 있다.
## 하위 종류(ERunner 돌진 · ECaster 원거리 · EColossus 거구)는 _think(생각·움직임)와 _paint_body(그림)만 채운다.
## 공통: 틈에서 나타남 · 피격 번쩍임·피해 숫자·넉백(knock_resist만큼 버팀)·경직 · 봉공(공간 고정)에 굳으면 멈춤(하던 동작은 풀린 뒤 이어서)
##       · 몸통 닿으면 피해(_contact_now가 참일 때) · 쓰러지면 흩어져 사라짐.
## 강자(보스)용: 버팀(포이즈) — max_poise > 0이면 맞을 때 opts["poise"]만큼 깎이고, 0이 되면 무너져(break_t초) 받는 피해가 늘어난다.
##   맞지 않고 poise_delay초가 지나면 다시 찬다. 무너짐 동안은 _think 대신 _broken_think가 불린다.
##   그 밖의 갈고리: _intercept_hit(받아넘기기·무적 연출) · _death_fx(쓰러짐 연출) · death_time · show_bar.
## 색: 검정·뼈흰색·핏빛 빨강 (에스카의 보라와 섞이지 않게, 파랑 없음).
## 그림 좌표: 원점 = 발밑 가운데, 오른쪽을 보는 모습으로 그린다(facing이 -1이면 뒤집힘).

signal died(e: EEnemy)
signal poise_broken(e: EEnemy) ## 버팀이 무너진 순간 (장면 연출용)

const GRAVITY := 980.0
const FALL_MAX := 520.0
const SPAWN_TIME := 0.55
const DEATH_TIME := 0.6

const BLACK := Color("#0c090f")
const SHADE := Color("#251b29")
const BONE := Color("#ece4d6")
const BONE_DIM := Color("#a3978a")
const RED := Color("#ff2b3d")
const RED_DEEP := Color("#7d0c1f")
const RED_HOT := Color("#ffb0a6")

var max_hp := 300
var hp := 300
var size := Vector2(20, 28) ## 피격 사각형 (원점 = 발밑 가운데)
var knock_resist := 0.0 ## 0 = 잘 밀림 · 1 = 넉백·경직 없음
var contact_dmg := 1
var lockable := true ## 겨누기 대상인가 (구슬 등은 false)
var still_resist := 0.0 ## 강자: 공간 고정 중에도 이만큼의 빠르기로 움직임 (0 = 완전히 멈춤)
var status_resist := 0.0 ## 강자: 묶음·기절 시간이 (1 - 이 값)배로 줄어듦 (물약 속박·비명)
var vuln_t := 0.0 ## 부식: 남은 시간 동안 받는 피해 × vuln_mult
var vuln_mult := 1.0
var flying := false
var facing := -1
var x_min := 24.0 ## 움직일 수 있는 가로 범위 (장면이 정함)
var x_max := 1256.0
var eska: EEska
var death_time := DEATH_TIME ## 쓰러진 뒤 사라지기까지 (강자는 길게 — 쓰러짐 연출)
var show_bar := true ## 맞으면 머리 위 작은 체력바 (보스는 화면 위 큰 바를 쓰므로 끔)
var spawn_fx := true ## 나타날 때 붉은 틈 (강자는 처음부터 서 있으므로 끔 — spawn_t도 0으로)
var death_squash := true ## 쓰러질 때 기본 눌리며 사라지기 (강자는 끄고 _paint_body에서 직접 그림)

# 버팀(포이즈): 강자만 (max_poise 0 = 없음)
var max_poise := 0.0
var poise := 0.0
var poise_delay := 2.5 ## 마지막으로 맞은 뒤 이만큼 지나면 다시 차기 시작
var poise_regen := 1.0 ## 다시 찰 때 초당 max_poise의 이 몫
var break_time := 2.0 ## 무너져 있는 시간
var break_mult := 1.25 ## 무너진 동안 받는 피해 배수
var break_t := 0.0 ## 무너짐 남은 시간 (0 = 버티는 중)
var _poise_idle := 0.0 ## 마지막으로 맞은 뒤 시간

var pd := PDraw.new()
var t := 0.0 ## 나타난 뒤 시간 (그림 흔들림 등)
var flash := 0.0
var stagger := 0.0
var spawn_t := SPAWN_TIME ## 나타나는 중 남은 시간 (이동·공격 안 함)
var dead_t := -1.0 ## 쓰러진 뒤 시간 (-1 = 살아 있음)
var _bound := 0.0
var _bind_awake := false
var _bar := 0.0
var _hp_trail := 0.0
var _base := Transform2D.IDENTITY


func _ready() -> void:
	add_to_group(PDummy.GROUP)
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 4.0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size
	cs.shape = rs
	cs.position = Vector2(0, -size.y / 2)
	add_child(cs)
	hp = max_hp
	_hp_trail = max_hp
	poise = max_poise
	t = randf() * 2.0
	z_index = 2
	eska = EEska.find(get_tree())
	if spawn_fx:
		EFoeFx.rift(center(), size.y * 0.75)
		Sfx.play_pitch(&"spawn", randf_range(0.8, 1.0), -10.0)


# ═══════════════════════════════════════════════════════════
# 표적 약속 (ETarget)
# ═══════════════════════════════════════════════════════════

func hit_rect() -> Rect2:
	return Rect2(global_position + Vector2(-size.x * 0.5, -size.y), size)


func center() -> Vector2:
	return global_position + Vector2(0, -size.y * 0.5)


func is_dead() -> bool:
	return dead_t >= 0.0


func take_hit(dmg: int, from: Vector2, opts := {}) -> void:
	if is_dead():
		return
	if _intercept_hit(dmg, from, opts):
		return
	var d := dmg
	if break_t > 0.0:
		d = int(round(float(d) * break_mult))
	if _bound > 0.0 and _bind_awake:
		d = int(round(float(d) * 1.3))
	if vuln_t > 0.0:
		d = int(round(float(d) * vuln_mult))
	hp -= d
	flash = 1.0
	_bar = 2.5
	if max_poise > 0.0 and hp > 0:
		poise_damage(float(opts.get("poise", dmg)))
	var heavy := bool(opts.get("heavy", false))
	var dir := signf(global_position.x - from.x)
	if dir == 0.0:
		dir = -float(facing)
	var give := 0.0 if _armored() else 1.0 - knock_resist
	if _bound <= 0.0 and give > 0.3:
		stagger = maxf(stagger, (0.26 if heavy else 0.17) * give)
		velocity.x = dir * (150.0 if heavy else 85.0) * give
		if flying:
			velocity.y = (center().y - from.y) * 0.6 * give
		elif heavy:
			velocity.y = -130.0 * give
		_interrupted()
	elif _bound <= 0.0 and not flying:
		velocity.x += dir * 40.0 * give # 거구: 밀리지 않고 살짝만 흔들림
	if PState.damage_numbers:
		PVfx.number(self, center() + Vector2(0, -size.y * 0.45), d, heavy)
	if hp <= 0:
		_die(dir)


## 버팀 깎기 (물약 비명 등이 직접 불러도 됨). 0이 되면 무너진다. 무너져 있는 동안은 깎이지 않는다
func poise_damage(amount: float) -> void:
	if max_poise <= 0.0 or is_dead():
		return
	_poise_idle = 0.0
	if break_t > 0.0:
		return
	poise = maxf(poise - amount, 0.0)
	if poise <= 0.0:
		break_t = break_time
		stagger = 0.0
		velocity.x = 0.0
		_interrupted()
		_on_poise_break()
		poise_broken.emit(self)


func bind(sec: float, awake: bool, _fox := true, _style := "") -> void:
	_bound = sec
	_bind_awake = awake
	_interrupted()


func unbind() -> void:
	_bound = 0.0


## 봉공(공간 고정, EStill): sec초 동안 굳는다. 묶기(bind)와 달리 준비 동작을 끊지 않고, 풀리면 하던 걸 이어서 한다. 받는 피해는 그대로
func freeze(sec: float) -> void:
	_bound = sec
	_bind_awake = false


func is_bound() -> bool:
	return _bound > 0.0


# ─── 물약·대마법이 거는 상태 (design.md 4장) ─────────────

## 속박: sec초 묶음 (하던 동작 끊김). 강자는 status_resist만큼 짧게
func root(sec: float) -> void:
	bind(sec * (1.0 - status_resist), false)


## 비명: 하던 동작이 끊기고 sec초 기절 (경직). 강자는 status_resist만큼 짧게
func stun(sec: float) -> void:
	stagger = maxf(stagger, sec * (1.0 - status_resist))
	velocity.x = 0.0
	_interrupted()


## 부식: sec초 동안 받는 피해 × mult
func set_vuln(sec: float, mult: float) -> void:
	vuln_t = maxf(vuln_t, sec)
	vuln_mult = maxf(mult, 1.0)


## 흑성: point 쪽으로 이번 프레임 끌려감 (넉백 버팀만큼 덜 끌림)
func pull(point: Vector2, strength: float, delta: float) -> void:
	var k := 1.0 - knock_resist * 0.8
	var to := point - center()
	global_position.x += clampf(to.x, -strength * delta * k, strength * delta * k)
	if flying:
		global_position.y += clampf(to.y, -strength * delta * k, strength * delta * k)


# ═══════════════════════════════════════════════════════════
# 하위 종류가 채우는 것
# ═══════════════════════════════════════════════════════════

## 한 프레임 생각·움직임 (나타남·경직·묶임이 아닐 때만 불림)
func _think(_delta: float) -> void:
	pass


## 맞아서 경직되거나 묶였을 때 — 준비하던 공격을 끊는다
func _interrupted() -> void:
	pass


## 맞기 직전: true를 돌려주면 이 타격을 받지 않는다 (반격 자세·막 전환 중 무적 등). 기본은 다 받음
func _intercept_hit(_dmg: int, _from: Vector2, _opts: Dictionary) -> bool:
	return false


## 버팀이 무너진 순간 / 무너짐에서 일어선 순간
func _on_poise_break() -> void:
	pass


func _on_poise_recover() -> void:
	pass


## 무너져 있는 동안의 한 프레임 (기본: 제자리에 멈춤)
func _broken_think(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)


## 쓰러질 때 연출 (기본: 뼈 조각·검은 연기·흔들림)
func _death_fx(dir: float) -> void:
	EFoeFx.death(center(), size, dir)
	Sfx.play_pitch(&"enemy_die", randf_range(0.9, 1.1), -4.0)
	Fx.shake(0.35 + size.y * 0.004, 0.18)


## 지금 넉백·경직을 무시하나 (돌진 중 등)
func _armored() -> bool:
	return false


## 지금 몸통이 닿으면 아픈가
func _contact_now() -> bool:
	return false


## 몸 그림 (오른쪽을 보는 모습, a = 나타남·쓰러짐 투명도)
func _paint_body(_a: float) -> void:
	pass


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(flash - delta * 6.0, 0.0)
	_bar = maxf(_bar - delta, 0.0)
	if _bar < 2.2: # 맞은 직후 0.3초는 깎인 자리를 밝게 남겼다가 따라 내려감
		_hp_trail = maxf(float(hp), _hp_trail - float(max_hp) * delta * 0.8)
	if is_dead():
		dead_t += delta
		if dead_t >= death_time:
			queue_free()
		queue_redraw()
		return
	if not is_instance_valid(eska):
		eska = EEska.find(get_tree())
	_bound = maxf(_bound - delta, 0.0)
	vuln_t = maxf(vuln_t - delta, 0.0)
	var slow := _bound > 0.0 and still_resist > 0.0 # 강자: 굳은 공간을 버티며 느리게 움직임
	var d := delta * still_resist if slow else delta
	_tick_poise(d)
	if spawn_t > 0.0:
		spawn_t -= d
		velocity.x = 0.0
	elif _bound > 0.0 and not slow:
		velocity = Vector2.ZERO
	elif break_t > 0.0:
		break_t -= d
		_broken_think(d)
		if break_t <= 0.0:
			break_t = 0.0
			poise = max_poise
			_on_poise_recover()
	elif stagger > 0.0:
		stagger -= d
		velocity.x = move_toward(velocity.x, 0.0, 520.0 * d)
		if flying:
			velocity.y = move_toward(velocity.y, 0.0, 520.0 * d)
	else:
		_think(d)
	if not flying and (_bound <= 0.0 or slow):
		velocity.y = minf(velocity.y + GRAVITY * d, FALL_MAX)
	if slow:
		velocity *= still_resist
		move_and_slide()
		velocity /= still_resist
	else:
		move_and_slide()
	global_position.x = clampf(global_position.x, x_min, x_max)
	if spawn_t <= 0.0 and (_bound <= 0.0 or slow) and stagger <= 0.0 and contact_dmg > 0 and _contact_now() and eska_ok():
		if eska.hurt_rect().intersects(hit_rect()):
			eska.hurt(contact_dmg, center())
	queue_redraw()


## 버팀: 마지막으로 맞은 뒤 poise_delay초가 지나면 다시 참
func _tick_poise(delta: float) -> void:
	if max_poise <= 0.0 or break_t > 0.0:
		return
	_poise_idle += delta
	if _poise_idle >= poise_delay and poise < max_poise:
		poise = minf(poise + max_poise * poise_regen * delta, max_poise)


## 장면이 거두어 감 (튜토리얼 끝 등 — 피해 숫자 없이 바로 쓰러짐)
func banish() -> void:
	if not is_dead():
		_die(float(-facing))


## 에스카가 살아서 겨눌 수 있나
func eska_ok() -> bool:
	return is_instance_valid(eska) and not eska.is_dead()


## 에스카 쪽 방향 (-1/1)
func toward_eska() -> int:
	if not is_instance_valid(eska):
		return facing
	return 1 if eska.global_position.x >= global_position.x else -1


func _die(dir: float) -> void:
	dead_t = 0.0
	hp = 0
	remove_from_group(PDummy.GROUP)
	collision_layer = 0
	velocity = Vector2(dir * 60.0, -40.0 if not flying else 0.0)
	break_t = 0.0
	_death_fx(dir)
	died.emit(self)


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

func _draw() -> void:
	var a := 1.0
	var sc := Vector2.ONE
	if spawn_t > 0.0:
		var f := 1.0 - spawn_t / SPAWN_TIME
		a = smoothstep(0.15, 0.9, f)
		sc = Vector2(0.4 + 0.6 * f, 1.25 - 0.25 * f)
	elif is_dead() and death_squash:
		var f := dead_t / death_time
		a = 1.0 - f
		sc = Vector2(1.0 + 0.35 * f, 1.0 - 0.4 * f)
	if _bound <= 0.0 and stagger > 0.0:
		sc *= Vector2(1.08, 0.94)
	_base = Transform2D(0.0, Vector2(float(facing) * sc.x, sc.y), 0.0, Vector2.ZERO)
	# 바닥 그림자
	if not flying:
		pd.draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.22))
		pd.glow(Vector2.ZERO, size.x * 0.9, Color(0, 0, 0, 0.5 * a), 0.0)
	xf()
	_paint_body(a)
	pd.draw_set_transform(Vector2.ZERO)
	if show_bar and _bar > 0.0 and not is_dead():
		_paint_bar(minf(_bar / 0.4, 1.0))
	pd.flush(self)


## 그림 좌표 정하기: 몸 기준(뒤집힘·눌림 포함) 위에 pos·rot·sc를 얹는다
func xf(pos := Vector2.ZERO, rot := 0.0, sc := Vector2.ONE) -> void:
	pd.draw_set_transform_matrix(_base * Transform2D(rot, sc, 0.0, pos))


## 색 하나: 맞으면 흰빛, 굳으면(봉공) 색이 빠진 잿빛 보라, a = 투명도
func col(c: Color, a := 1.0) -> Color:
	var out := c
	if _bound > 0.0:
		var l := c.get_luminance()
		out = out.lerp(Color(l * 0.85, l * 0.82, l * 1.0), 0.7)
	out = out.lerp(Color.WHITE, flash * 0.85)
	out.a *= a
	return out


## 머리 위 작은 체력바 (맞은 뒤 잠깐)
func _paint_bar(a: float) -> void:
	var w := clampf(size.x * 1.4, 24.0, 64.0)
	var p := Vector2(-w * 0.5, -size.y - 10.0)
	var f := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var ft := clampf(_hp_trail / float(max_hp), 0.0, 1.0)
	pd.draw_rect(Rect2(p - Vector2(1, 1), Vector2(w + 2, 4)), Color(0, 0, 0, 0.75 * a))
	pd.draw_rect(Rect2(p, Vector2(w * ft, 2)), Color(RED_HOT, 0.8 * a))
	pd.draw_rect(Rect2(p, Vector2(w * f, 2)), Color(RED, a))
