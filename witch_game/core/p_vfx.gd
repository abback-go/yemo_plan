class_name PVfx
extends RefCounted
## 이펙트 공통 바탕과 작은 이펙트. 모두 코드 그림(Node2D._draw)이고, 수명이 끝나면 스스로 사라진다.
## 에스카 프로젝트(game/proto/p_vfx.gd)에서 이 프로토타입이 쓰는 것만 옮겼다: Base · add · kick · sparks · dust · 피해 숫자(Numbers).

## 공통 바탕: life초 동안 k(0→1)로 그리고 사라진다
class Base extends PDraw.Canvas:
	var life := 0.3
	var t := 0.0
	var fox := false

	func k() -> float:
		return clampf(t / life, 0.0, 1.0)

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		_tick(delta)
		queue_redraw()

	func _tick(_delta: float) -> void:
		pass


static func add(n: Node2D, pos: Vector2, additive := false) -> Node2D:
	n.position = pos
	if additive:
		n.material = Fx.add_material
	Fx.effect_parent().add_child(n)
	return n


## 화면을 v(px) 방향으로 순간 밀었다 되돌림 — 흔들림(무작위)과 달리 방향이 있어 타격 방향이 느껴진다
static func kick(v: Vector2) -> void:
	if Fx.camera and Fx.camera.has_method("kick"):
		Fx.camera.kick(v)


## 튀는 불꽃: dir 방향 ±spread도로 speed까지 (빠르면 속도 방향 줄, 느리면 네모 불티). 한 노드(PParticles)에서 그린다
static func sparks(pos: Vector2, n: int, col: Color, speed := 120.0, life := 0.35, dir := Vector2.UP, spread := 180.0, grav := Vector2(0, 220)) -> void:
	var pp := PParticles.get_layer(true)
	var base := dir.angle()
	var hot := col.lerp(Color.WHITE, 0.55)
	for i in n:
		var a := base + deg_to_rad(randf_range(-spread, spread))
		var sp := randf_range(speed * 0.4, speed)
		pp.spawn(pos, Vector2(cos(a), sin(a)) * sp, grav, life * randf_range(0.6, 1.0), randf_range(1.0, 2.0), hot, col, 1 if sp > 90.0 else 0, 2.0)


## 발밑 먼지 (보통 합성 입자: 둥글게 커지며 옅어짐)
static func dust(pos: Vector2, n: int, spread_x := 1.0, up := 18.0) -> void:
	var pp := PParticles.get_layer(false)
	for i in n:
		var v := Vector2(randf_range(-40, 40) * spread_x, -randf_range(4, up))
		pp.spawn(pos + Vector2(randf_range(-4, 4), 0), v, Vector2.ZERO, 0.38, randf_range(2.0, 3.6), Color(0.82, 0.8, 0.86, 0.45), Color(0.6, 0.58, 0.68, 0.45), 2, 6.0)


static func number(key: Object, pos: Vector2, value: int, heavy := false, fox := false) -> void:
	var n := Numbers.inst
	if not is_instance_valid(n) or not n.is_inside_tree():
		n = Numbers.new()
		Numbers.inst = n
		Fx.effect_parent().add_child(n)
	n.add(key, pos, value, heavy, fox)


class Numbers extends Node2D:
	static var inst: Numbers
	var items: Array = [] ## [대상, 위치, 값, 나이, 큼, 여우불, 합친 횟수, 마지막 타격 뒤 시간, 대상 자리(어긋남 전), 쌓인 칸, 같은 숫자로 묶인 다른 표적들]
	var _font: Font
	const LIFE := 0.75
	const MERGE := 0.25
	const MAX_ITEMS := 32
	const SPREAD_X := 14 ## 대상마다 가로 어긋남 (±px)
	const STAGGER_Y := 7.0 ## 대상마다 세로 어긋남 단계 (0·1·2단)
	const GROW_MAX := 8 ## 합칠수록 커지는 글자 크기 상한 (px)
	const HOLD_AGE := 0.2 ## 합칠 때 나이를 여기까지만 되돌림 (숫자가 다시 바닥으로 튀지 않고 떠 있는 채 커짐)
	const BUMP_Y := 11.0 ## 같은 대상의 새 숫자가 뜨면 아직 떠 있는 예전 숫자를 이만큼 위로 밀어 겹치지 않게
	const STACK_GAP := 4.0 ## 숫자끼리 가로로 이만큼도 안 떨어지면(숫자 폭 + 4px) 위아래로 쌓는다 (loop7_plan 3장: 50px 간격 이웃이 "640 64640"처럼 붙던 것)
	const WIDTH_SIZE := 20 ## 폭을 잴 때 글자 크기 (합쳐져 커진 숫자 기준)
	const WIDTH_MIN := "0000" ## 폭은 적어도 이만큼으로 잼 — 처음엔 80처럼 짧아도 합쳐지며 896·1440으로 길어지므로
	const STACK_MAX := 3 ## 쌓는 칸 최대 (loop4_plan 6장) — 넘치면 같은 숫자를 "값×N"으로 묶음
	const STACK_H := 25.0 ## 쌓는 칸 높이 (합쳐져 커진 글자도 겹치지 않게)

	func _ready() -> void:
		z_index = 20
		_font = ThemeDB.fallback_font

	func add(key: Object, pos: Vector2, value: int, heavy: bool, fox: bool) -> void:
		for it: Array in items:
			if float(it[7]) >= MERGE:
				continue
			if it[0] == key:
				it[2] = int(it[2]) + value
				it[3] = minf(float(it[3]), HOLD_AGE)
				it[4] = bool(it[4]) or heavy
				it[6] = int(it[6]) + 1
				it[7] = 0.0
				return
			if (it[10] as Array).has(key): # 같은 숫자로 묶인 표적(×N): 대표 숫자가 대신 셈 — 반짝임만
				it[7] = 0.0
				return
		var at := pos + _offset(key)
		var slot := 0
		var anchor_found := false
		var same: Array = [] ## 쌓이는 칸이 넘칠 때 묶을 같은 숫자
		for it: Array in items:
			if it[0] == key:
				it[1] = (it[1] as Vector2) + Vector2(0, -BUMP_Y)
			elif _touching(at, value, it):
				if not anchor_found or int(it[9]) == 0:
					at = it[1] # 붙어 선 표적들은 같은 세로줄에서
					anchor_found = true
				slot = maxi(slot, int(it[9]) + 1) # 그 위 칸으로
				if int(it[2]) == value and same.is_empty():
					same = it
		if slot >= STACK_MAX:
			if not same.is_empty(): # 넘치면 같은 숫자는 하나로: "896×8"
				(same[10] as Array).append(key)
				same[3] = minf(float(same[3]), HOLD_AGE)
				same[7] = 0.0
				return
			slot = STACK_MAX - 1 # 같은 숫자가 없으면 맨 위 칸에 겹쳐 둠
		items.append([key, at, value, 0.0, heavy, fox, 0, 0.0, pos, slot, []])
		if items.size() > MAX_ITEMS:
			items.pop_front()

	## 새 숫자(자리 at, 값 value)가 떠 있는 숫자 it과 겹치는가: 가로는 두 숫자 폭의 반씩 + STACK_GAP, 세로는 한 칸 안
	func _touching(at: Vector2, value: int, it: Array) -> bool:
		var half := (_width(value) + _width(int(it[2]))) * 0.5 + STACK_GAP
		var p: Vector2 = it[1]
		return absf(at.x - p.x) < half and absf(at.y - p.y) < STACK_H

	func _width(v: int) -> float:
		var t := str(v)
		if t.length() < WIDTH_MIN.length():
			t = WIDTH_MIN
		return _font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, WIDTH_SIZE).x

	## 대상마다 늘 같은 어긋남 (숫자가 프레임마다 흔들리지 않게)
	func _offset(key: Object) -> Vector2:
		if key == null:
			return Vector2(randf_range(-4, 4), 0)
		var h := hash(key.get_instance_id())
		return Vector2(float(h % (SPREAD_X * 2 + 1) - SPREAD_X), -STAGGER_Y * float((h / 97) % 3))

	func _process(delta: float) -> void:
		if items.is_empty():
			return
		for it: Array in items:
			it[3] = float(it[3]) + delta
			it[7] = float(it[7]) + delta
		items = items.filter(func(it: Array) -> bool: return float(it[3]) < LIFE)
		queue_redraw()

	func _draw() -> void:
		for it: Array in items:
			var age: float = it[3]
			var heavy: bool = it[4]
			var merged: int = it[6]
			var big := heavy or merged >= 3
			var pop := 1.0 - clampf(float(it[7]) / 0.12, 0.0, 1.0) # 맞을 때마다 툭 커짐
			var sz := (13 if big else 10) + int(round(5.0 * pop)) + mini(merged, GROW_MAX)
			var rise := (16.0 if big else 11.0) * (1.0 - pow(1.0 - minf(age / 0.45, 1.0), 2.0))
			var a := 1.0 - clampf((age - 0.45) / (LIFE - 0.45), 0.0, 1.0)
			var col: Color
			if bool(it[5]):
				col = Color(0.62, 0.9, 1.0) if not big else Color(0.85, 0.97, 1.0)
			else:
				col = Color(1.0, 0.82, 0.32) if not big else Color(1.0, 0.97, 0.82) # 원본 PData.FIRE_HOT / FIRE_CORE
			col = col.lerp(Color.WHITE, pop * 0.7)
			col.a = a
			var p: Vector2 = (it[1] as Vector2) + Vector2(-60, -8 - rise - STACK_H * float(it[9]))
			var s := str(it[2])
			var many := (it[10] as Array).size()
			if many > 0:
				s += "×%d" % (many + 1)
			draw_string_outline(_font, p, s, HORIZONTAL_ALIGNMENT_CENTER, 120, sz, 4, Color(0.08, 0.03, 0.06, a))
			draw_string(_font, p, s, HORIZONTAL_ALIGNMENT_CENTER, 120, sz, col)


## 변신 순간: 세라 뒤로 빛의 꼬리(꼬리 수만큼)가 부채꼴로 확 펼쳐졌다 사라지고, 위로 빛기둥이 선다
