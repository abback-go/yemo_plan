class_name TActor
extends Node2D
## 전장 위의 한 명: 규칙 유닛(TUnit)과 그림을 잇는다. 에스카는 실시간판 그림(EEska/EArt)을 물리 없이 서 있는 모드로,
## 불의 마녀 둘은 TWitchArt, 적은 TEnemyArt. 자세 바꾸기·맞음·쓰러짐·되살아남·보이는 체력(천천히 따라감)을 맡는다.

const SCALE := 2.0 ## 마녀 코드 그림(키 40px)을 화면에서 이만큼 키움 (키 약 80px = 화면 22%, review_C §5.3)
const ENEMY_SCALE := 1.8 ## 적 그림 배율 (× 데이터 size): 일반 약 90 · 강적 약 140 · 보스 약 160~175px
const DOWN_FADE := 0.25 ## 쓰러진 마녀는 이만큼 옅게 남아 되살릴 수 있음을 보여 준다

var unit: TUnit
var home := Vector2.ZERO
var shown_hp := 1.0 ## 보이는 체력 비율 (천천히 따라감)
var eska: EEska
var witch: TWitchArt
var enemy: TEnemyArt
var facing := 1
var _lunge := 0.0
var _lunge_v := 0.0
var _down := false
var _down_t := 0.0
var _mark: DownMark
var _shadow: Node2D
var deco := true ## 전장 꾸밈(발밑 고리 등). 패널 초상·컷인처럼 그림만 빌려 쓸 때는 setup 전에 false
var turn_on := false ## 지금 이 마녀의 차례 (발밑 속성 고리)
var act_on := false ## 지금 행동 중인 적 (발밑 DANGER 고리)
var _ring: FootRing
var _walk := 0.0 ## 걸어 들어오는 중: 남은 가로 거리 (화면 px, 웨이브 전환)
var _walk_v := 0.0
var _walk_ph := 0.0


func setup(u: TUnit, at: Vector2) -> void:
	unit = u
	home = at
	position = at
	shown_hp = u.hp_ratio()
	var sz := 1.0
	if u.is_witch():
		facing = 1
		if u.id == "eska":
			eska = EEska.new()
			add_child(eska)
			eska.set_physics_process(false)
			eska.set_process(false)
			eska.art.stand = true
			eska.art.rim_on = true
		else:
			witch = TWitchArt.new()
			witch.kind = u.id
			add_child(witch)
	else:
		facing = -1
		var sh := Shadow.new()
		add_child(sh)
		_shadow = sh
		enemy = TEnemyArt.new()
		enemy.kind = TEnemyArt.kind_for(u.id, String(u.data.get("art", u.id))) # 재의 왕·시련의 거상은 전용 그림
		sz = float(u.data.get("size", 1.0)) * ENEMY_SCALE / SCALE
		add_child(enemy)
		sh.hw = enemy.half_w() + 4.0
	scale = Vector2(SCALE * sz, SCALE * sz)
	if facing < 0:
		# 적 그림은 왼콈을 보게 그렸으므로 뒤집지 않는다
		pass
	z_index = int(at.y) # 아래(앞)에 있는 쪽이 위에 그려짐
	_mark = DownMark.new()
	_mark.visible = false
	add_child(_mark)
	if get_parent() is Control: # 패널 초상 (THud) — 꾸밈 없음
		deco = false
	if deco:
		_ring = FootRing.new()
		_ring.actor = self
		_ring.visible = false
		add_child(_ring)
		move_child(_ring, 0) # 그림 아래


func _process(delta: float) -> void:
	if unit == null:
		return
	var dt := minf(delta, 1.0 / 30.0)
	if eska != null:
		eska.art.tick(delta)
	elif witch != null:
		witch.tick(delta)
	elif enemy != null:
		enemy.tick(delta)
	shown_hp = move_toward(shown_hp, unit.hp_ratio(), dt * 1.6)
	_lunge_v += (-_lunge * 160.0 - _lunge_v * 14.0) * dt
	_lunge += _lunge_v * dt
	var hop := 0.0
	if _walk > 0.0:
		_walk = maxf(_walk - _walk_v * delta, 0.0)
		_walk_ph += delta * 18.0
		hop = -absf(sin(_walk_ph)) * 3.0
	position = home + Vector2(_lunge * float(facing) + _walk, hop)
	if enemy != null and enemy.phase != unit.bar_i:
		enemy.set_phase(unit.bar_i)
	if _ring != null:
		var on := unit.alive and (turn_on or act_on or (unit.is_witch() and unit.is_taunting()))
		_ring.visible = on
		if on:
			_ring.t += delta
			_ring.queue_redraw()
	if _down:
		_down_t += delta
		_mark.t = _down_t
		_mark.queue_redraw()


## 몸 가운데 (전역)
func center() -> Vector2:
	if enemy != null:
		return to_global(enemy.center_local())
	return to_global(Vector2(0, -20.0))


## 머리 위 (전역) — 체력 바 자리
func head() -> Vector2:
	if enemy != null:
		return to_global(Vector2(0, -enemy.height() - 4.0))
	return to_global(Vector2(0, -50.0))


func feet() -> Vector2:
	return global_position


## 마법이 나가는 손 (전역)
func hand() -> Vector2:
	if eska != null:
		return eska.art.fingertip() if eska.st != EEska.St.ULT else eska.art.to_global(EArt.ULT_HAND)
	if witch != null:
		return witch.hand_global()
	return center()


## 소품의 빛나는 자리 (엠버의 등불 · 이그니스의 장갑), 없으면 손
func prop_pos() -> Vector2:
	if witch != null:
		return witch.prop_global()
	return hand()


func half_w() -> float:
	if enemy != null:
		return enemy.half_w() * scale.x
	return 10.0 * scale.x


## 자세: idle · cast · cast_big · hit · win · attack(적)
func pose(p: String) -> void:
	if _down and p != "idle":
		return
	if eska != null:
		match p:
			"cast":
				eska.st = EEska.St.CAST
				eska.cast_kind = "cheonyeol"
			"cast_big":
				eska.st = EEska.St.ULT
			"win":
				eska.st = EEska.St.CAST
				eska.cast_kind = "dangong"
			_:
				eska.st = EEska.St.NORMAL
		eska.st_t = 0.0
	elif witch != null:
		witch.set_pose(p)
	elif enemy != null:
		enemy.set_pose(p)


## 맞음: 움찔 + 붉게 + 뒤로 밀림
func hurt(heavy: bool) -> void:
	if eska != null:
		eska.art.hurt()
	elif witch != null:
		witch.hurt()
	elif enemy != null:
		enemy.hurt()
	_lunge_v -= (120.0 if heavy else 60.0)


## 공격 시작: 앞으로 살짝 내딛음
func lunge() -> void:
	_lunge_v += 90.0


## 웨이브 전환: 오른쪽 밖(dist px)에서 dur초 동안 걸어 들어온다 (review_C §8.4)
func walk_in(dist: float, dur := 0.4) -> void:
	_walk = dist
	_walk_v = dist / maxf(dur, 0.05)
	_walk_ph = 0.0


func set_turn(on: bool) -> void:
	turn_on = on


func set_acting(on: bool) -> void:
	act_on = on


func set_down(down: bool) -> void:
	if down == _down:
		return
	_down = down
	_down_t = 0.0
	if down:
		pose("idle")
		if eska != null:
			eska.art.dissolve()
			EVfx.dark_bits(center(), 18, 200.0, Vector2.UP, 180.0, 0.6, 4)
			EVfx.dark_burst(center(), 26.0)
		elif witch != null:
			EVfx.dark_bits(center(), 14, 180.0, Vector2.UP, 180.0, 0.6, 4)
			witch.set_pose("down")
		elif enemy != null:
			pass # 재로 흩어지는 입자는 장면이 TFx.ash_dissolve로 띄운다 (TActor ↔ TFx 순환 참조를 만들지 않게)
	else:
		if eska != null:
			eska.art.revive()
			eska.art.visible = true
			eska.art.reset_chains()
		elif witch != null:
			witch.fade = 1.0
			witch.set_pose("idle")
			witch.reset_chains()
	_mark.visible = down and unit.is_witch()
	if not down:
		return
	# 그림을 옅게
	var tw := create_tween()
	if eska != null:
		tw.tween_interval(0.5)
		tw.tween_callback(func() -> void: eska.art.visible = false)
	elif witch != null:
		tw.tween_property(witch, "fade", 0.5, 0.6) # 무릎 꿇고 반쯤 흐리게 — 되살릴 수 있다
	elif enemy != null:
		enemy.set_pose("down")
		tw.tween_property(enemy, "fade", 0.0, 0.5)
		if _shadow != null:
			tw.parallel().tween_property(_shadow, "modulate:a", 0.0, 0.5)


## 적 발밑 그림자 타원 (마녀는 그림 안에 있음) — 적이 떠 보이지 않게
class Shadow extends PDraw.Canvas:
	var hw := 12.0

	func _paint() -> void:
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
		pd.glow(Vector2.ZERO, hw + 3.0, Color(0, 0, 0, 0.5), 0.0)
		pd.draw_set_transform(Vector2.ZERO)


## 쓰러진 자리 표시: 바닥의 보랏빛 고리 + 떠오르는 작은 빛 + 머리 위 작은 영혼 불꽃 (되살릴 수 있다는 뜻)
class DownMark extends PDraw.Canvas:
	var t := 0.0

	func _paint() -> void:
		var pulse := 0.5 + 0.5 * sin(t * 2.4)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		pd.glow(Vector2.ZERO, 11.0 + pulse * 2.0, Color("#b9a2ff", 0.3), 0.0)
		pd.draw_arc(Vector2.ZERO, 9.0 + pulse * 1.5, 0.0, TAU, 24, Color("#d9ccff", 0.6), 1.0)
		pd.draw_set_transform(Vector2.ZERO)
		for i in 3:
			var ph := fmod(t * 0.5 + float(i) / 3.0, 1.0)
			var p := Vector2(-6.0 + float(i) * 6.0 + sin(t * 2.0 + float(i)) * 1.5, -ph * 22.0)
			pd.draw_rect(Rect2(p, Vector2(1.2, 1.2)), Color("#e6dcff", (1.0 - ph) * 0.8))
		# 영혼 불꽃 (머리 위에서 흔들리며 숨 쉼)
		var a := minf(t * 2.0, 1.0)
		var c := Vector2(sin(t * 1.7) * 1.5, -40.0 - 1.5 * sin(t * 2.3))
		pd.glow(c, 6.0 + 1.5 * pulse, Color("#b9a2ff", 0.4 * a), 0.0)
		var tip := c + Vector2(sin(t * 6.0) * 1.2, -6.0 - pulse)
		pd.convex(PackedVector2Array([c + Vector2(-2.4, 0.6), tip, c + Vector2(2.4, 0.6), c + Vector2(0, 2.6)]), Color("#d9ccff", 0.85 * a))
		pd.convex(PackedVector2Array([c + Vector2(-1.1, 0.8), c + Vector2(0, -3.0), c + Vector2(1.1, 0.8), c + Vector2(0, 1.8)]), Color("#ffffff", 0.9 * a))


## 발밑 고리: 차례인 마녀 = 속성 색 숨쉬기 + 위로 오르는 알갱이 4 · 행동 중인 적 = DANGER · 도발 중 = 붉은 점선 (review_C §8.1)
class FootRing extends PDraw.Canvas:
	var actor: TActor
	var t := 0.0

	func _paint() -> void:
		var u := actor.unit
		var r := 9.0 # 로컬 (마녀 배율 2 → 화면 반지름 18)
		var col := Color("#ff4f6a")
		if u.is_witch():
			col = TData.ELEMENT_COLOR.get(u.element, Color("#b9a2ff"))
		else:
			r = actor.enemy.half_w() + 4.0
		var br := 0.6 + 0.4 * (0.5 + 0.5 * sin(t * 4.0))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
		if actor.turn_on or actor.act_on:
			pd.glow(Vector2.ZERO, r * 1.3, Color(col, 0.25 * br), 0.0)
			pd.draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(col, br), 1.0)
			pd.draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 24, Color(col, 0.5 * br), 0.6)
		if u.is_witch() and u.is_taunting():
			for i in 10:
				var a0 := TAU * float(i) / 10.0 + t * 0.8
				pd.draw_arc(Vector2.ZERO, r + 3.0, a0, a0 + 0.35, 4, Color("#ff7a5a", 0.8), 0.8)
		pd.draw_set_transform(Vector2.ZERO)
		if actor.turn_on and u.is_witch():
			for i in 4:
				var ph := fmod(t * 0.9 + float(i) * 0.25, 1.0)
				var p := Vector2(cos(float(i) * 1.7) * r * 0.8, sin(float(i) * 1.7) * r * 0.25 - ph * 16.0)
				pd.draw_rect(Rect2(p, Vector2(0.8, 0.8)), Color(col, (1.0 - ph) * 0.9))
