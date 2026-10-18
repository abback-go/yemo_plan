class_name TActor
extends Node2D
## 전장 위의 한 명: 규칙 유닛(TUnit)과 그림을 잇는다. 에스카는 실시간판 그림(EEska/EArt)을 물리 없이 서 있는 모드로,
## 불의 마녀 둘은 TWitchArt, 적은 TEnemyArt. 자세 바꾸기·맞음·쓰러짐·되살아남·보이는 체력(천천히 따라감)을 맡는다.

const SCALE := 1.6 ## 코드 그림(키 40px)을 화면에서 이만큼 키움
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
		enemy = TEnemyArt.new()
		enemy.kind = u.id
		sz = float(u.data.get("size", 1.0))
		add_child(enemy)
	scale = Vector2(SCALE * sz, SCALE * sz)
	if facing < 0:
		# 적 그림은 왼콈을 보게 그렸으므로 뒤집지 않는다
		pass
	z_index = int(at.y) # 아래(앞)에 있는 쪽이 위에 그려짐
	_mark = DownMark.new()
	_mark.visible = false
	add_child(_mark)


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
	position = home + Vector2(_lunge * float(facing), 0)
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
		elif enemy != null:
			pass
	else:
		if eska != null:
			eska.art.revive()
			eska.art.visible = true
			eska.art.reset_chains()
		elif witch != null:
			witch.fade = 1.0
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
		tw.tween_property(witch, "fade", 0.0, 0.6)
	elif enemy != null:
		enemy.set_pose("down")
		tw.tween_property(enemy, "fade", 0.0, 0.8)


## 쓰러진 자리 표시: 바닥의 보랏빛 고리 + 떠오르는 작은 빛 (되살릴 수 있다는 뜻)
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
