extends EnemyBase
## 성곽 가고일 (docs/chapter2.md 4절) — 지붕 처마에 앉은 돌 괴물.
## 앉아 있을 땐 돌(무적, "팅"). 세라가 아래를 지나가면 눈이 붉게 켜지고(0.55초, 내려꽂힐 궤적이 붉은 점선으로 보임)
## 호를 그리며 급강하 → 땅에 박혀 1.2초 버둥(빈틈, 피해 125%) → 날아서 처마로 돌아감(돌아가는 동안은 피해 100%).
## 답: 아래를 지나가 유인 → 옆으로 피하기(대시하면 퍼펙트 회피) → 박힌 동안 두들기기.

const KE := preload("res://enemies/ch2/k_enemy.gd")

enum S { PERCH, WAKE, DIVE, STUCK, RETURN }

const HP := 600
const SEE_X_T := 4.5 ## 아래로 이만큼 가까이 오면 깨어남
const SEE_DOWN_T := 13.0
const WAKE_TIME := 0.55
const DIVE_TIME := 0.55
const STUCK_TIME := 1.2
const RETURN_TIME := 0.9
const REST_AFTER := 1.4 ## 처마로 돌아온 뒤 다시 깨어나기까지
const STUCK_MULT := 1.25
const STONE := Color("#6a6a78")
const STONE_L := Color("#9a9aa8")
const STONE_D := Color("#3a3a46")
const LIVE := Color("#4a5048")
const LIVE_L := Color("#6a7468")
const LIVE_D := Color("#262a26")

var state: S = S.PERCH
var perch := Vector2.ZERO
var target := Vector2.ZERO
var _from := Vector2.ZERO
var _ctrl := Vector2.ZERO
var _timer := 0.0
var _dur := 0.0
var _rest := 0.0
var _contact: EnemyAttackArea
var _dive_area: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(22, 20)
	knock_mult = 0.0
	launch_mult = 0.0
	flying = true
	display_name = "성곽 가고일"
	subtitle = "처마 끝의 돌 파수꾼"
	kind_id = "gargoyle"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	_visual = v
	add_child(v)
	var fx := KE.Vis.new()
	fx.enemy = self
	fx.fn = _draw_fx
	fx.flip = false
	fx.z_index = 6
	add_child(fx)
	_contact = add_attack_area(Vector2(18, 16), Vector2(0, -10), &"gargoyle", 1)
	_dive_area = add_attack_area(Vector2(24, 22), Vector2(0, -11), &"gargoyle", 1)
	_dive_area.active = false


func _ready() -> void:
	super()
	collision_mask = 0 # 벽을 뚫고 궤적대로 날아다님 (박히는 지점은 땅을 찾아 정함)
	perch = global_position
	_enter(S.PERCH, 0.0)


func _enter(s: S, d: float) -> void:
	state = s
	_timer = d
	_dur = d


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	_rest -= delta
	velocity = Vector2.ZERO
	_contact.active = engaged and state != S.PERCH and _alive
	var p := player()
	match state:
		S.PERCH:
			global_position = perch
			if engaged and _rest <= 0.0 and p and p.is_alive():
				var dx := absf(p.global_position.x - perch.x)
				var dy := p.global_position.y - perch.y
				if dx < SEE_X_T * t and dy > t and dy < SEE_DOWN_T * t:
					_wake()
		S.WAKE:
			if p and p.is_alive():
				facing = 1 if p.global_position.x >= global_position.x else -1
				# 예고 동안 착지점이 세라를 따라감 (마지막 0.15초엔 고정)
				if _timer > 0.15:
					_aim(p)
			if _timer <= 0.0:
				_start_dive()
		S.DIVE:
			var k := progress()
			var e := k * k
			global_position = _bezier(_from, _ctrl, target, e)
			if _timer <= 0.0:
				_land()
		S.STUCK:
			global_position = target + Vector2(sin(_t * 30.0) * (1.0 if _timer < 0.4 else 0.3), 0)
			if _timer <= 0.0:
				_enter(S.RETURN, RETURN_TIME)
				_from = global_position
				_ctrl = (global_position + perch) * 0.5 + Vector2(-facing * 3.0 * t, -2.0 * t)
				KE.snd(&"wind", &"whoosh", -4.0)
				KE.debris(global_position, 10, STONE_L, Vector2.UP, 120.0)
		S.RETURN:
			var k2 := progress()
			global_position = _bezier(_from, _ctrl, perch, 1.0 - pow(1.0 - k2, 2.0))
			if _timer <= 0.0:
				global_position = perch
				_enter(S.PERCH, 0.0)
				_rest = Difficulty.rest(REST_AFTER)
				KE.snd(&"crumble", &"crumble", -10.0)
				KE.debris(perch + Vector2(0, -6), 6, STONE_L, Vector2.UP, 60.0)


func _wake() -> void:
	_enter(S.WAKE, Difficulty.telegraph(WAKE_TIME))
	_aim(player())
	KE.snd(&"growl", &"growl", -2.0, 0.15)
	KE.snd(&"crumble", &"crumble", -8.0)
	KE.debris(global_position + Vector2(0, -12), 8, STONE_L, Vector2(0, -1), 80.0)


## 착지점: 세라 발밑의 땅
func _aim(p: Player) -> void:
	if p == null:
		return
	var fy := KE.floor_at(self, p.global_position.x, p.global_position.y)
	target = Vector2(p.global_position.x, fy)


func _start_dive() -> void:
	_enter(S.DIVE, DIVE_TIME)
	_from = global_position
	# 호를 그리며: 처음엔 뒤로 살짝 떴다가 비스듬히 내리꽂힘
	_ctrl = Vector2(_from.x - facing * 2.0 * GameConst.TILE, minf(_from.y, target.y) - 1.5 * GameConst.TILE)
	_dive_area.active = true
	_dive_area.dodgeable = true
	KE.snd(&"wind", &"whoosh", 0.0)
	KE.snd(&"charger_charge", &"charger_charge", -4.0)


func _land() -> void:
	global_position = target
	_dive_area.active = false
	_enter(S.STUCK, Difficulty.rest(STUCK_TIME))
	Fx.shake(0.3, 0.25)
	KE.snd(&"slam", &"slam", 0.0)
	KE.snd(&"crumble", &"crumble", -4.0)
	KE.debris(target, 16, Color("#8a8494"), Vector2.UP, 160.0)
	Fx.ring(target + Vector2(0, -2), 4.0, 26.0, Color(1, 0.9, 0.8, 0.6), 0.25, 2.0)


func _bezier(a: Vector2, b: Vector2, c: Vector2, k: float) -> Vector2:
	return a.lerp(b, k).lerp(b.lerp(c, k), k)


func modify_damage(_hit: Hit) -> float:
	match state:
		S.PERCH, S.WAKE:
			return 0.0 # 돌
		S.STUCK:
			return STUCK_MULT
	return 1.0


func _on_blocked(hit: Hit) -> void:
	super(hit)
	KE.debris(global_position + Vector2(0, -12), 4, STONE_L, Vector2(signf(hit.source_pos.x - global_position.x), -1), 80.0)


func _die(dir: int) -> void:
	KE.death_fx(global_position + Vector2(0, -10), Color("#c8b8a0"))
	KE.debris(global_position + Vector2(0, -10), 22, STONE_L, Vector2(dir, -1), 180.0)
	super(dir)


# ─── 그림 ───────────────────────────────────────────────

func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var stone := state == S.PERCH
	var wake_k := progress() if state == S.WAKE else (1.0 if state != S.PERCH else 0.0)
	var base := STONE.lerp(LIVE, wake_k)
	var lite := STONE_L.lerp(LIVE_L, wake_k)
	var dark := STONE_D.lerp(LIVE_D, wake_k)
	if white:
		base = Color.WHITE
		lite = Color.WHITE
		dark = Color(0.85, 0.85, 0.9)
	var spread := 0.0
	var tilt := 0.0
	match state:
		S.DIVE:
			spread = 1.0
			tilt = 0.6
		S.RETURN:
			spread = 0.6 + 0.4 * sin(_t * 18.0)
		S.WAKE:
			spread = 0.35 * wake_k
		S.STUCK:
			tilt = 0.9
			spread = 0.3 + 0.2 * sin(_t * 25.0)
	c.draw_set_transform(Vector2(0, -10), tilt, Vector2.ONE)
	# 날개 (접힘 → 펼침)
	for side in [-1.0, 1.0]:
		var root := Vector2(-2, -4 + side * 0.5)
		var tip := root + Vector2(-8 - 8 * spread, -6 - 6 * spread + side * 3.0)
		var mid := root + Vector2(-3 - 10 * spread, 2 + side * 2.0)
		var wing := PackedVector2Array([root, tip, mid + Vector2(-2, 3), root + Vector2(2, 4)])
		c.draw_colored_polygon(wing, KE.OUT)
		c.draw_colored_polygon(PackedVector2Array([root + Vector2(0.5, 0.5), tip + Vector2(0.8, 0.8), mid + Vector2(-1, 2), root + Vector2(2, 3)]), dark if side > 0.0 else base.darkened(0.15))
		c.draw_line(root, tip, lite, 1.0)
	# 몸 (웅크린 돌 짐승)
	var body := PackedVector2Array([Vector2(-7, 6), Vector2(-8, -2), Vector2(-3, -7), Vector2(5, -6), Vector2(8, 0), Vector2(6, 7)])
	c.draw_colored_polygon(PackedVector2Array([Vector2(-8, 7), Vector2(-9, -2), Vector2(-3, -8), Vector2(6, -7), Vector2(9, 0), Vector2(7, 8)]), KE.OUT)
	c.draw_colored_polygon(body, base)
	c.draw_line(Vector2(-6, -3), Vector2(4, -5), lite, 1.0)
	# 다리 (쭈그림)
	c.draw_rect(Rect2(-6, 5, 4, 4), dark)
	c.draw_rect(Rect2(3, 5, 4, 4), base)
	c.draw_rect(Rect2(6, 8, 3, 1), lite)
	# 머리: 뿔 둘 + 큰 입
	var hc := Vector2(7, -6)
	c.draw_circle(hc, 5.0, KE.OUT)
	c.draw_circle(hc, 4.2, base)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-2, -3), hc + Vector2(-5, -9), hc + Vector2(0, -4)]), lite)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(1, -3), hc + Vector2(2, -9), hc + Vector2(3, -3)]), base)
	var open := 1.0 if state == S.DIVE or state == S.WAKE else (0.4 if state == S.STUCK else 0.0)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(1, 1), hc + Vector2(6, 0), hc + Vector2(5, 2 + open * 3.0), hc + Vector2(1, 2 + open)]), dark.darkened(0.4))
	if open > 0.0:
		c.draw_line(hc + Vector2(2, 1), hc + Vector2(2, 2), Color.WHITE, 1.0)
		c.draw_line(hc + Vector2(4, 1), hc + Vector2(4, 2.5), Color.WHITE, 1.0)
	# 눈: 돌일 땐 어둡고, 깨어나면 붉게 번쩍
	var eye := Color("#2a2a30")
	if not stone:
		eye = KE.DANGER.lerp(Color(1, 0.8, 0.6), 0.2 * sin(_t * 20.0))
	c.draw_rect(Rect2(hc + Vector2(1, -2), Vector2(2, 1.5)), eye)
	if not stone and not white:
		c.draw_circle(hc + Vector2(2, -1.2), 3.0, Color(KE.DANGER, 0.3 * (0.6 + 0.4 * wake_k)))
	# 돌일 때의 금과 이끼
	if stone and not white:
		c.draw_line(Vector2(-4, -4), Vector2(-2, 1), STONE_D, 1.0)
		c.draw_line(Vector2(2, 2), Vector2(4, 5), STONE_D, 1.0)
		c.draw_rect(Rect2(-7, 4, 3, 1), Color("#4a6a4a"))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 예고: 내리꽂힐 궤적(붉은 점선)과 착지점 표시 — 좌우를 뒤집지 않는 층
func _draw_fx(c: Node2D) -> void:
	if state != S.WAKE:
		return
	var k := progress()
	var a := KE.warn_pulse(_t, k)
	var from := Vector2(0, -10)
	var ctrl := Vector2(-facing * 2.0 * GameConst.TILE, minf(0.0, target.y - global_position.y) - 1.5 * GameConst.TILE)
	var to := target - global_position
	var n := 14
	for i in n:
		if i % 2 == 1:
			continue
		var k0 := float(i) / n
		var k1 := float(i + 1) / n
		var p0 := _bezier(from, ctrl, to, k0 * k0)
		var p1 := _bezier(from, ctrl, to, k1 * k1)
		c.draw_line(p0, p1, Color(KE.DANGER, 0.25 + 0.5 * a * k1), 2.0)
	c.draw_set_transform(to + Vector2(0, -1), 0.0, Vector2(1.0, 0.3))
	c.draw_arc(Vector2.ZERO, 14.0, 0, TAU, 18, Color(KE.DANGER, 0.4 + 0.5 * a), 2.0)
	c.draw_circle(Vector2.ZERO, 14.0 * k, Color(KE.DANGER, 0.2 * a))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
