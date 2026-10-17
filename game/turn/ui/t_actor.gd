class_name TActor
extends Node2D
## 전투 유닛의 화면 몸 v2 (2.5D): 아군은 뒷모습(TBackArt), 적은 정면(TEnemyArt). 코드 그림을 draw_scale로 키워 그린다.
## 그 위에 머리 위 표시(이름·체력·버프·시전·다음 행동·고르기 고리)와 아군의 버프 그림(틈·방벽·별빛)을 그린다.
## 원점 = 발밑. 그림 좌표는 모두 draw_scale을 곱해 화면 px로.

const DESIGN_H := {"eska": 46.0, "sera": 44.0, "ashe": 42.0, "hound": 24.0, "monk": 44.0, "king": 74.0}
const HAND := {"eska": Vector2(10.5, -37), "sera": Vector2(10, -36), "ashe": Vector2(10, -36)}

var unit: TBattle.Unit
var battle: TBattle
var body: Node2D
var back: TBackArt
var enemy: TEnemyArt
var draw_scale := 3.0
var ring := 0 ## 0 없음 · 1 고를 수 있음 · 2 고른 대상
var active := false ## 메뉴가 열린 마녀 / 행동 중인 적
var hp_shown := 1.0
var pd := PDraw.new()
var _t := 0.0
var _pose := "idle"
var _pose_t := 0.0
var _atk_t := 0.0
var _atk_dur := 0.4
var _step := 0.0 ## 행동할 때 한 발 앞으로 (화면 px)


func setup(u: TBattle.Unit, b: TBattle, p_scale: float) -> void:
	unit = u
	battle = b
	draw_scale = p_scale
	body = Node2D.new()
	body.scale = Vector2(draw_scale, draw_scale)
	add_child(body)
	if u.ally:
		back = TBackArt.new()
		back.who = u.base
		body.add_child(back)
	else:
		enemy = TEnemyArt.new()
		enemy.kind = u.base
		enemy.seed_n = u.slot
		enemy.phase = u.bar_i
		body.add_child(enemy)
	hp_shown = u.hp_ratio()


func height() -> float:
	return float(DESIGN_H.get(unit.base, 40.0)) * draw_scale


func center() -> Vector2:
	return global_position + Vector2(0, -height() * 0.55)


func head() -> Vector2:
	return global_position + Vector2(0, -height())


func hand() -> Vector2:
	if HAND.has(unit.base):
		return global_position + (HAND[unit.base] as Vector2) * draw_scale
	return center()


func info() -> Dictionary:
	return {"feet": global_position, "center": center(), "size": unit.size}


func hit_rect() -> Rect2:
	var w := 26.0 * draw_scale if not unit.boss else 44.0 * draw_scale
	return Rect2(global_position.x - w * 0.5, global_position.y - height() - 10.0, w, height() + 16.0)


## 동작: idle · cast(마법 손짓) · attack · ult · support · hurt · die
func pose(kind: String, dur := 0.6) -> void:
	_pose = kind
	_pose_t = dur
	_atk_t = 0.0
	_atk_dur = dur
	if back:
		match kind:
			"cast", "attack", "support", "ult":
				back.pose = "cast"
			"hurt":
				back.pose = "hurt"
				back.flash = 1.0
			"die":
				back.pose = "down"
			_:
				back.pose = "idle"
	elif enemy:
		match kind:
			"attack":
				enemy.pose = "attack"
				enemy.atk_k = 0.0
			"cast", "support", "ult":
				enemy.pose = "cast"
			"hurt":
				enemy.pose = "hurt"
				enemy.flash = 1.0
			"die":
				enemy.pose = "die"
			_:
				enemy.pose = "idle"


func _process(delta: float) -> void:
	_t += delta
	if _pose_t > 0.0 and _pose != "die":
		_pose_t -= delta
		_atk_t += delta
		var k := clampf(_atk_t / maxf(_atk_dur, 0.01), 0.0, 1.0)
		if enemy and enemy.pose == "attack":
			enemy.atk_k = k
		if _pose_t <= 0.0:
			_pose = "idle"
			pose("idle", 0.0)
	if enemy:
		enemy.phase = unit.bar_i
		if unit.is_casting() and _pose == "idle":
			enemy.pose = "cast"
		elif not unit.is_casting() and enemy.pose == "cast" and _pose == "idle":
			enemy.pose = "idle"
		enemy.step(delta)
	if back:
		back.step(delta)
	# 메뉴가 열린 마녀는 한 발 앞으로 (뒤에서 보니 화면 위쪽 = 앞)
	var want := -6.0 if (active and unit.ally) else 0.0
	_step = lerpf(_step, want, 1.0 - exp(-delta * 10.0))
	if body:
		body.position = Vector2(0, _step)
	hp_shown = lerpf(hp_shown, unit.hp_ratio(), 1.0 - exp(-delta * 8.0))
	queue_redraw()


func _draw() -> void:
	var h := height()
	# ── 고르기 고리 (발밑 타원)
	if ring > 0 or active:
		var col := TUi.GOLD if (ring == 2) else (TUi.PALE if ring == 1 else TUi.TEXT)
		var pulse := 0.6 + 0.4 * sin(_t * 7.0)
		var r := (13.0 * draw_scale) * (1.0 + 0.06 * pulse * float(ring))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		if ring == 2:
			draw_circle(Vector2.ZERO, r, Color(col, 0.18))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(col, (0.9 if ring == 2 else 0.5) * (0.7 + 0.3 * pulse)), 2.0 if ring == 2 else 1.0)
		draw_set_transform(Vector2.ZERO)
	if unit.ally and unit.alive:
		_paint_ally_buffs(h)
	pd.flush(self)
	var top := -h - 8.0
	if not unit.ally:
		# 머리 위 글이 상단 HUD(카메라가 당겨도 화면 y≈40)와 겹치지 않게 — 맨 윗줄(top-32)이 y 66 아래로
		top = maxf(top, 98.0 - global_position.y)
		_draw_enemy_head(top)
	elif not unit.alive:
		TUi.text(self, Vector2(-40, top + 30), "쓰러짐", 12, Color(TUi.DIM, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 80)


func _draw_enemy_head(top: float) -> void:
	var w := 60.0 if not unit.boss else 110.0
	var x := -w * 0.5
	# 위에서부터: 다음 행동 (top-32) · 이름 (top-19) · 체력바 (top-11) · 아이콘 (top+1)
	TUi.text(self, Vector2(x - 40, top - 19), unit.name, 11, Color(TUi.BONE, 0.95), HORIZONTAL_ALIGNMENT_CENTER, w + 80)
	if unit.alive:
		var rect := Rect2(x, top - 11, w, 6)
		TUi.bar(self, rect, hp_shown, TUi.ENEMY_C if not unit.boss else Color("#ff8a4a"))
		if unit.boss:
			var bars := unit.bars.size()
			for i in bars:
				var on := i >= unit.bar_i
				draw_rect(Rect2(x + w + 3.0 + 7.0 * float(i), top - 11, 5, 6), Color("#ff8a4a") if on else Color(0.3, 0.2, 0.2, 0.8))
		TUi.text(self, Vector2(x + w + 2, top - 5), str(unit.hp), 9, TUi.BONE, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		var bx := x
		var seen := {}
		for b in unit.buffs:
			var key := String(b.kind)
			if seen.has(key):
				continue
			seen[key] = true
			var n := 0
			for b2 in unit.buffs:
				if b2.kind == key:
					n += 1
			var col: Color = TUi.BUFF_COLORS.get(key, TUi.TEXT)
			var bad := (key == "vuln") or (key == "def" and float(b.amt) < 0.0)
			if key in TData.MARK_KINDS:
				# 소모형 상태(금·기름)는 크게 — 조합의 재료가 눈에 띄어야 한다
				var mw := 30.0
				var pulse := 0.75 + 0.25 * sin(_t * 5.0 + float(n))
				draw_rect(Rect2(bx, top, mw, 12), Color(col, 0.35 * pulse))
				draw_rect(Rect2(bx, top, mw, 12), Color(col, 0.95), false, 1.0)
				TUi.text(self, Vector2(bx, top + 10), TData.kind_name(key) + "×" + str(n), 9, col.lightened(0.35), HORIZONTAL_ALIGNMENT_CENTER, mw, 2)
				bx += mw + 2.0
				continue
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(col, 0.35 if bad else 0.3))
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(col, 0.9), false, 1.0)
			TUi.text(self, Vector2(bx, top + 10), String(TUi.BUFF_SHORT.get(key, key)) + (str(n) if n > 1 else ""), 9, col.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 16, 2)
			bx += 18
		if unit.burn_left > 0:
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(TUi.FIRE_OUT, 0.35))
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(TUi.FIRE_OUT, 0.9), false, 1.0)
			TUi.text(self, Vector2(bx, top + 10), "화" + str(unit.burn_left), 9, TUi.FIRE_HOT, HORIZONTAL_ALIGNMENT_CENTER, 16, 2)
		if unit.skip_next:
			TUi.text(self, Vector2(x - 40, top - 32), "봉쇄됨 · 행동 없음", 10, TUi.PALE, HORIZONTAL_ALIGNMENT_CENTER, w + 80, 2)
		elif unit.is_casting():
			var sp := battle.spec_of(unit, String(unit.casting.spell))
			var heavy := bool(sp.get("heavy", false))
			var col := TUi.RED if heavy else Color("#ffb0a6")
			var k := 0.6 + 0.4 * sin(_t * 6.0)
			TUi.text(self, Vector2(x - 50, top - 32), "시전 중 · " + String(sp.get("name", "")) + (" (굳셈)" if heavy else "") + " → 다음 적 턴", 10, Color(col, k), HORIZONTAL_ALIGNMENT_CENTER, w + 100, 2)
		elif not unit.pattern.is_empty():
			var nxt := String(unit.pattern[unit.pattern_i % unit.pattern.size()])
			var spec := battle.spec_of(unit, nxt)
			var nm := String(spec.get("name", nxt))
			var danger := String(spec.get("kind", "")) == "cast"
			TUi.text(self, Vector2(x - 40, top - 32), "다음 " + nm, 10, Color(TUi.RED if danger else TUi.DIM, 0.95), HORIZONTAL_ALIGNMENT_CENTER, w + 80, 2)


## 아군 버프를 몸에 그린다 (그림 px = 설계 px × draw_scale): 틈(최종) · 별빛(치명) · 방벽 · 가속 · 풀무 · 공격
func _paint_ally_buffs(h: float) -> void:
	var s := draw_scale
	var rifts := unit.stacks_of_spell("rift")
	for i in rifts:
		var x := (13.0 + 4.0 * float(i)) * s
		var shape := EVfx.rift_line(Vector2(x, -2.0 * s), Vector2(x + 1.0 * s, -h * 0.95), (3.2 - 0.4 * float(i)) * s, 9, 11 + i * 5 + unit.slot * 3, 0.4 * s, 0.06)
		var open := 0.75 + 0.15 * sin(_t * 3.0 + float(i))
		var oa := EVfx.rift_open(shape[2], open, 0.0, 1.0, 0.85)
		EVfx.rift(pd, shape[0], shape[1], oa[0], oa[1], 11 + i * 5, _t, 0.0, 0.8, 0.9)
	if unit.stacks_of_spell("stareyes") > 0:
		var n := unit.stacks_of_spell("stareyes") * 3
		for i in n:
			var ph := _t * 2.0 + float(i) * 1.6
			var p := Vector2(cos(ph) * 6.0 * s, -h * 0.84 + sin(ph * 1.3) * 3.0 * s)
			EVfx.star4(pd, p, (1.0 + 0.4 * sin(_t * 8.0 + float(i))) * s, ph, Color(TUi.PALE, 0.9), Color(TUi.VIOLET, 0.25))
	if unit.shield_left() > 0.0:
		var k := 0.8 + 0.2 * sin(_t * 9.0)
		pd.draw_set_transform(Vector2(0, -h * 0.45), 0.0, Vector2(1.0, 0.5))
		pd.draw_arc(Vector2.ZERO, 12.0 * s, 0.0, TAU, 32, Color(TUi.FIRE_MID, 0.75 * k), 1.0 * s)
		pd.glow(Vector2.ZERO, 13.0 * s, Color(TUi.FIRE_OUT, 0.12 * k), 0.4)
		pd.draw_set_transform(Vector2.ZERO)
		for i in 8:
			var an := _t * 1.5 + float(i) * TAU / 8.0
			var p := Vector2(cos(an) * 12.0 * s, -h * 0.45 + sin(an) * 6.0 * s)
			pd.draw_line(p, p + Vector2(0, -(2.0 + 1.5 * sin(_t * 11.0 + float(i))) * s), Color(TUi.FIRE_HOT, 0.9), 0.6 * s)
	if unit.sum("haste") > 0.0:
		for i in 4:
			var ph := _t * 5.0 + float(i) * 1.5
			var p := Vector2((-6.0 - fmod(ph * 4.0, 10.0)) * s, (-1.0 - float(i) * 1.5) * s)
			pd.draw_rect(Rect2(p, Vector2(2.0 * s, 0.5 * s)), Color(TUi.FIRE_HOT, 0.7))
	if unit.elem == TData.ELEM_FIRE and unit.stacks_of_spell("bellows") > 0:
		var n := unit.stacks_of_spell("bellows") * 4
		for i in n:
			var ph := _t * 3.0 + float(i) * 1.1
			var rise := fmod(ph * 4.0, 16.0)
			pd.draw_rect(Rect2(Vector2(sin(ph * 2.0) * 5.0 * s - 0.4 * s, (-3.0 - rise) * s), Vector2(0.8 * s, 0.8 * s)), Color(TUi.FIRE_MID, 0.8 * (1.0 - rise / 16.0)))
	if unit.sum("atk") > 0.0:
		var k := 0.5 + 0.5 * sin(_t * 4.0)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		pd.draw_arc(Vector2.ZERO, 9.0 * s, 0.0, TAU, 24, Color(TUi.ATTACK_C, 0.35 + 0.25 * k), 0.4 * s)
		pd.draw_set_transform(Vector2.ZERO)
