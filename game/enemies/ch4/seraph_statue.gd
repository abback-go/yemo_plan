class_name SeraphStatue
extends EnemyBase
## 날개 조각상 (docs/archive/sera/chapter4.md 4절·7.4절): 회랑의 얼굴 없는 날개 천사상. **세라가 등을 돌렸을 때만** 움직인다.
## - 세라가 바라보면(조각상이 세라 앞쪽에 있으면) 그 자리에서 돌로 굳는다: 굳은 동안 화염탄·화염 폭풍은 튕겨 나간다(피해 0),
##   대신 불기둥은 1.5배(굳은 돌이 발밑의 열에 금이 감).
##   불기둥(발밑)·폭주 폭발·유성·불사조·동료 공격·되쏜 탄은 굳어 있어도 들어간다 → 답: 마주 보고 불기둥.
## - 등을 돌리면 금빛 눈이 켜지고 뚝뚝 끊기듯 미끄러져 다가온다(초당 5칸). 1.8칸 안이면 날개 칼날을 치켜든다(0.45초 예고 — 날개 끝이 붉게)
##   → 휘두르기(앞 2.5칸, 1 피해). 예고 중에 돌아보면 그대로 굳어 취소된다.
## - 세라가 멀거나(16칸 밖) 쓰러지면 잠든다.

enum S { DORMANT, FROZEN, MOVE, WINDUP, SLASH, RECOVER }

const H := preload("res://enemies/ch4/holy.gd")
const VIS := preload("res://enemies/ch4/seraph_statue_visual.gd")

const HP := 900
const MOVE_T := 5.0
const STEP_ON := 0.16 ## 미끄러지는 시간
const STEP_OFF := 0.09 ## 멈칫하는 시간
const REACH_T := 1.8
const WINDUP := 0.45
const SLASH_TIME := 0.18
const RECOVER := 0.5
const STONE_BLOCKS := Hit.STONE_BLOCKS_STATUE

var state: S = S.DORMANT
var stone := 1.0 ## 1 = 완전히 돌 (그림)
var _clock := StateClock.new() ## 상태 시간 (남은 시간·길이·진행도)
var _step_t := 0.0
var _slash: EnemyAttackArea
var _grind_t := 0.0


func _build() -> void:
	max_hp = HP
	body_size = Vector2(22, 40)
	knock_mult = 0.0
	launch_mult = 0.0
	display_name = "날개 조각상"
	subtitle = "등을 보이지 마라"
	kind_id = "seraph_statue"
	var v: Node2D = VIS.new()
	v.set("enemy", self)
	_visual = v
	add_child(v)
	_slash = add_attack_area(Vector2(40, 30), Vector2(18, -18), &"seraph_statue")
	_slash.active = false


func progress() -> float:
	return _clock.k()


func _go(s: S, time := 0.0) -> void:
	state = s
	_clock.enter(time)


## 세라가 이쪽을 보고 있는가 (조각상이 세라의 앞쪽에 있음)
func watched() -> bool:
	var p := player()
	if p == null or not p.is_alive() or not p.controls_enabled:
		return true
	var dx := global_position.x - p.global_position.x
	if absf(dx) < 6.0:
		return true
	return signf(dx) == float(p.facing)


func is_frozen() -> bool:
	return state == S.FROZEN or state == S.DORMANT


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	var cs := _slash.get_child(0) as CollisionShape2D
	cs.position = Vector2(18 * facing, -18)
	var p := player()
	_clock.tick(delta)
	var seen := watched()
	var near := p != null and p.is_alive() and engaged and global_position.distance_to(p.global_position) < 16.0 * t
	stone = move_toward(stone, 1.0 if (seen or state == S.DORMANT) else 0.0, delta * (12.0 if seen else 3.0))
	if not near:
		_slash.active = false
		velocity.x = 0.0
		if state != S.DORMANT:
			_go(S.DORMANT)
		return
	if seen and state != S.SLASH and state != S.RECOVER:
		if state != S.FROZEN:
			_freeze()
		velocity.x = 0.0
		return
	match state:
		S.DORMANT, S.FROZEN:
			_go(S.MOVE)
			_step_t = 0.0
			H.snd(&"crumble", &"crumble", -14.0)
		S.MOVE:
			facing = 1 if p.global_position.x >= global_position.x else -1
			_step_t += delta
			var cycle := fmod(_step_t, STEP_ON + STEP_OFF)
			velocity.x = facing * MOVE_T * t if cycle < STEP_ON else 0.0
			if ledge_ahead(13.0, 16.0):
				velocity.x = 0.0
			_grind_t -= delta
			if _grind_t <= 0.0 and velocity.x != 0.0:
				_grind_t = 0.35
				Sfx.play(&"land", -12.0, 0.2)
				Fx.burst(global_position + Vector2(-facing * 8, -1), 2, {
					direction = Vector2(-facing, -1), spread = 30.0, speed_min = 10.0, speed_max = 30.0, lifetime = 0.3,
					gradient = Palette.fade_gradient(Color("#8a8aa0")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 100),
				})
			if absf(p.global_position.x - global_position.x) < REACH_T * t and absf(p.global_position.y - global_position.y) < 3.0 * t:
				_go(S.WINDUP, Difficulty.telegraph(WINDUP))
				velocity.x = 0.0
				H.snd(&"spear", &"charger_windup", -4.0)
		S.WINDUP:
			velocity.x = 0.0
			if _clock.done():
				_go(S.SLASH, SLASH_TIME)
				_slash.active = true
				H.snd(&"sword_slash", &"swing", 0.0)
				Fx.shake(0.1, 0.15)
		S.SLASH:
			velocity.x = facing * 2.0 * t
			if _clock.done():
				_slash.active = false
				_go(S.RECOVER, RECOVER)
		S.RECOVER:
			velocity.x = 0.0
			if _clock.done():
				_go(S.MOVE)


func _freeze() -> void:
	_slash.active = false
	var was_moving := state == S.MOVE or state == S.WINDUP
	_go(S.FROZEN)
	if was_moving:
		Sfx.play(&"block", -10.0, 0.05)
		Fx.burst(global_position + Vector2(0, -22), 6, {
			spread = 180.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.4,
			gradient = Palette.fade_gradient(Color("#a8a8bc")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 120),
		})


func modify_damage(hit: Hit) -> float:
	var center := hit.direction == 0 and absf(hit.source_pos.x - global_position.x) < 6.0
	if is_frozen() and hit.kind in STONE_BLOCKS and not center:
		return 0.0
	if is_frozen() and (hit.kind == &"pillar" or hit.kind == &"fox_pillar"):
		return 1.5 # 굳은 돌은 발밑의 열에 금이 간다
	return 1.0


func _on_blocked(hit: Hit) -> void:
	super(hit)
	if not GameState.has_flag("tp_statue_hint"):
		GameState.set_flag("tp_statue_hint")
		Story.toast("굳은 돌에는 화염탄이 튕겨 나간다. 발밑에서 솟는 불이라면…", 3.0)


func _die(dir: int) -> void:
	_slash.active = false
	Sfx.play(&"crumble", 0.0, 0.0)
	Fx.burst(global_position + Vector2(0, -20), 30, {
		spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.8, gravity = Vector2(0, 450),
		gradient = Palette.fade_gradient(Color("#a8a8bc")), size_min = 2.0, size_max = 4.0,
	})
	H.sparkle(global_position + Vector2(0, -26), 16, 8.0, 30.0, 0.8)
	super(dir)
