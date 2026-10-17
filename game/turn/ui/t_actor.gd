class_name TActor
extends Node2D
## 전투 유닛의 화면 몸: 코드 그림(에스카 EArt · 세라 SeraArt · 아셰 TAsheArt · 적 TEnemyArt)을 TUi.ACTOR_SCALE로 키워 그리고,
## 그 위에 머리 위 표시(이름·체력·버프·시전·다음 행동·고르기 고리)와 아군의 버프 그림(틈·방벽·별빛)을 그린다.
## 원점 = 발밑. 아군은 오른쪽을, 적은 왼쪽을 본다.

const HEIGHTS := {"eska": 60.0, "sera": 58.0, "ashe": 56.0, "hound": 30.0, "monk": 72.0, "king": 118.0}
const HAND := {"eska": Vector2(18, -42), "sera": Vector2(15, -30), "ashe": Vector2(15, -38)}

var unit: TBattle.Unit
var battle: TBattle
var body: Node2D
var eska: EEska
var sera: SeraArt
var ashe: TAsheArt
var enemy: TEnemyArt
var ring := 0 ## 0 없음 · 1 고를 수 있음 · 2 고른 대상
var active := false ## 지금 차례
var hp_shown := 1.0
var pd := PDraw.new()
var _t := 0.0
var _pose := "idle"
var _pose_t := 0.0
var _atk_t := 0.0
var _atk_dur := 0.4
var _lunge := 0.0
var _ko := false
var _wait_shown := 0.0


func setup(u: TBattle.Unit, b: TBattle) -> void:
	unit = u
	battle = b
	body = Node2D.new()
	body.scale = Vector2(TUi.ACTOR_SCALE, TUi.ACTOR_SCALE)
	add_child(body)
	match u.base:
		"eska":
			eska = EEska.new()
			body.add_child(eska) # 물리·입력은 _ready에서 끈다 (EEska가 트리에 들어가며 켜므로)
		"sera":
			sera = SeraArt.new()
			body.add_child(sera)
		"ashe":
			ashe = TAsheArt.new()
			body.add_child(ashe)
		_:
			enemy = TEnemyArt.new()
			enemy.kind = u.base
			enemy.seed_n = u.slot
			enemy.phase = u.bar_i
			body.add_child(enemy)
	hp_shown = u.hp_ratio()
	_wait_shown = u.wait


func _ready() -> void:
	if eska:
		eska.set_physics_process(false)
		eska.set_process(false)
		eska.art.stand = true


func height() -> float:
	return float(HEIGHTS.get(unit.base, 50.0))


func center() -> Vector2:
	return global_position + Vector2(0, -height() * 0.55)


func head() -> Vector2:
	return global_position + Vector2(0, -height())


func hand() -> Vector2:
	if HAND.has(unit.base):
		return global_position + (HAND[unit.base] as Vector2)
	return center()


func info() -> Dictionary:
	return {"feet": global_position, "center": center(), "size": unit.size}


func hit_rect() -> Rect2:
	var w := 56.0 if not unit.boss else 100.0
	return Rect2(global_position.x - w * 0.5, global_position.y - height() - 14.0, w, height() + 22.0)


## 동작: idle · cast(마법 손짓) · attack · ult(대마법 의식) · hurt · die · support
func pose(kind: String, dur := 0.6) -> void:
	_pose = kind
	_pose_t = dur
	_atk_t = 0.0
	_atk_dur = dur
	match kind:
		"die":
			_ko = true
	if eska:
		match kind:
			"cast", "attack":
				eska.st = EEska.St.CAST
				eska.cast_kind = "cheonyeol"
			"support":
				eska.st = EEska.St.CAST
				eska.cast_kind = "nakseong"
			"ult":
				eska.st = EEska.St.ULT
			"hurt":
				eska.art.hurt()
				eska.st = EEska.St.NORMAL
			"die":
				eska.art.dissolve()
				eska.st = EEska.St.DEAD
			_:
				eska.st = EEska.St.NORMAL
	elif sera:
		match kind:
			"attack":
				sera.pose = "throw"
				sera.atk_step = 0
				sera.atk_k = 0.0
			"cast", "support":
				sera.pose = "cast"
			"ult":
				sera.pose = "focus"
				sera.focus_k = 1.0
			"hurt":
				sera.pose = "hurt"
				sera.flash = 1.0
			"die":
				sera.pose = "hurt"
			_:
				sera.pose = "idle"
				sera.focus_k = 0.0
	elif ashe:
		match kind:
			"cast", "attack", "support", "ult":
				ashe.pose = "cast"
			"hurt":
				ashe.pose = "hurt"
				ashe.flash = 1.0
			"die":
				ashe.pose = "down"
			_:
				ashe.pose = "idle"
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
		if sera and sera.pose == "throw":
			sera.atk_k = k
		if enemy and enemy.pose == "attack":
			enemy.atk_k = k
			_lunge = sin(minf(k * 1.3, 1.0) * PI)
		if _pose_t <= 0.0:
			pose("idle", 0.0)
			_pose = "idle"
	if enemy:
		enemy.phase = unit.bar_i
		if unit.is_casting() and _pose == "idle":
			enemy.pose = "cast"
		elif not unit.is_casting() and enemy.pose == "cast" and _pose == "idle":
			enemy.pose = "idle"
	if eska:
		if unit.is_casting() and _pose == "idle":
			eska.st = EEska.St.ULT
		elif not unit.is_casting() and _pose == "idle" and eska.st == EEska.St.ULT:
			eska.st = EEska.St.NORMAL
		eska.art.tick(delta)
	if sera:
		if unit.is_casting() and _pose == "idle":
			sera.pose = "focus"
			sera.focus_k = minf(sera.focus_k + delta * 2.0, 1.0)
		elif not unit.is_casting() and _pose == "idle" and sera.pose == "focus":
			sera.pose = "idle"
			sera.focus_k = 0.0
		sera.step(delta)
	if ashe:
		if unit.is_casting() and _pose == "idle":
			ashe.pose = "cast"
		elif not unit.is_casting() and _pose == "idle" and ashe.pose == "cast":
			ashe.pose = "idle"
		ashe.step(delta)
	if enemy:
		enemy.step(delta)
	hp_shown = lerpf(hp_shown, unit.hp_ratio(), 1.0 - exp(-delta * 8.0))
	_wait_shown = lerpf(_wait_shown, unit.wait, 1.0 - exp(-delta * 10.0))
	if _ko and unit.ally:
		body.modulate.a = maxf(body.modulate.a - delta * 1.5, 0.35)
	queue_redraw()


func _draw() -> void:
	var h := height()
	# ── 고르기 고리 (발밑 타원)
	if ring > 0 or active:
		var col := TUi.GOLD if (ring == 2) else (TUi.PALE if ring == 1 else TUi.TEXT)
		var pulse := 0.6 + 0.4 * sin(_t * 7.0)
		var r := (30.0 if not unit.boss else 54.0) * (1.0 + 0.06 * pulse * float(ring))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		if ring == 2:
			draw_circle(Vector2.ZERO, r, Color(col, 0.18))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(col, (0.9 if ring == 2 else 0.5) * (0.7 + 0.3 * pulse)), 2.0 if ring == 2 else 1.0)
		draw_set_transform(Vector2.ZERO)
	# ── 아군 버프 그림 (틈 · 방벽 · 별빛 · 가속)
	if unit.ally and unit.alive:
		_paint_ally_buffs(h)
	pd.flush(self)
	# ── 머리 위
	var top := -h - 8.0
	if active:
		var bob := sin(_t * 6.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-5, top - 14 + bob), Vector2(5, top - 14 + bob), Vector2(0, top - 7 + bob)]), TUi.GOLD)
	if not unit.ally:
		_draw_enemy_head(top)
	elif not unit.alive:
		TUi.text(self, Vector2(-30, top), "쓰러짐", 11, Color(TUi.DIM, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 60)
	if unit.is_casting():
		_draw_cast_bar(top - (30.0 if not unit.ally else 2.0))


func _draw_enemy_head(top: float) -> void:
	var w := 52.0 if not unit.boss else 96.0
	var x := -w * 0.5
	# 위에서부터: 다음 행동 (top-30) · 이름 (top-18) · 체력바 (top-9) · 아이콘 (top+1)
	TUi.text(self, Vector2(x - 30, top - 17), unit.name, 11, Color(TUi.BONE, 0.95), HORIZONTAL_ALIGNMENT_CENTER, w + 60)
	if unit.alive:
		var rect := Rect2(x, top - 10, w, 6)
		TUi.bar(self, rect, hp_shown, TUi.ENEMY_C if not unit.boss else Color("#ff8a4a"))
		if unit.boss:
			var bars := unit.bars.size()
			for i in bars:
				var on := i >= unit.bar_i
				draw_rect(Rect2(x + w + 3.0 + 7.0 * float(i), top - 10, 5, 6), Color("#ff8a4a") if on else Color(0.3, 0.2, 0.2, 0.8))
			draw_rect(Rect2(x, top - 10, w, 6), Color(0, 0, 0, 0.6), false, 1.0)
		# 버프·디버프 아이콘
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
			var bad := (key == "vuln") or (key == "def" and float(b.amt) < 0.0) or key == "burn"
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(col, 0.35 if bad else 0.3))
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(col, 0.9), false, 1.0)
			TUi.text(self, Vector2(bx, top + 10), String(TUi.BUFF_SHORT.get(key, key)) + (str(n) if n > 1 else ""), 9, col.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 16, 2)
			bx += 18
		if unit.burn_left > 0:
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(TUi.FIRE_OUT, 0.35))
			draw_rect(Rect2(bx, top + 1, 16, 10), Color(TUi.FIRE_OUT, 0.9), false, 1.0)
			TUi.text(self, Vector2(bx, top + 10), "화" + str(unit.burn_left), 9, TUi.FIRE_HOT, HORIZONTAL_ALIGNMENT_CENTER, 16, 2)
		# 다음 행동 예고
		if not unit.is_casting() and not unit.pattern.is_empty():
			var nxt := String(unit.pattern[unit.pattern_i % unit.pattern.size()])
			var spec := battle.spec_of(unit, nxt)
			var nm := String(spec.get("name", nxt))
			var danger := String(spec.get("kind", "")) == "cast"
			TUi.text(self, Vector2(x - 40, top - 30), "다음 " + nm, 10, Color(TUi.RED if danger else TUi.DIM, 0.95), HORIZONTAL_ALIGNMENT_CENTER, w + 80, 2)


func _draw_cast_bar(top: float) -> void:
	var sp := battle.spec_of(unit, String(unit.casting.spell))
	var total := float(sp.get("cast", 2.0))
	var f := 1.0 - clampf(_wait_shown / maxf(total, 0.01), 0.0, 1.0)
	var w := 56.0
	var heavy := bool(sp.get("heavy", false))
	var col := TUi.CAST_C if unit.ally else (TUi.RED if heavy else Color("#ffb0a6"))
	var rect := Rect2(-w * 0.5, top - 6, w, 5)
	TUi.bar(self, rect, f, col, Color(0.1, 0.05, 0.1, 0.8))
	var label := "시전 " + String(sp.get("name", "")) + (" (굳셈)" if heavy else "")
	TUi.text(self, Vector2(-60, top - 9), label, 10, col, HORIZONTAL_ALIGNMENT_CENTER, 120, 2)


## 아군 버프를 몸에 그린다: 틈(최종 피해) · 별빛(치명) · 방벽 · 가속
func _paint_ally_buffs(h: float) -> void:
	var rifts := unit.stacks_of_spell("rift")
	for i in rifts:
		var x := 20.0 + 9.0 * float(i)
		var shape := EVfx.rift_line(Vector2(x, -4.0), Vector2(x + 2.0, -h * 0.95), 6.5 - float(i), 9, 11 + i * 5 + unit.slot * 3, 1.2, 0.06)
		var open := 0.75 + 0.15 * sin(_t * 3.0 + float(i))
		var oa := EVfx.rift_open(shape[2], open, 0.0, 1.0, 0.85)
		EVfx.rift(pd, shape[0], shape[1], oa[0], oa[1], 11 + i * 5, _t, 0.0, 0.8, 0.9)
	if unit.stacks_of_spell("stareyes") > 0:
		var n := unit.stacks_of_spell("stareyes") * 2
		for i in n:
			var ph := _t * 2.0 + float(i) * 1.6
			var p := Vector2(6.0 + cos(ph) * 9.0, -h * 0.82 + sin(ph * 1.3) * 5.0)
			EVfx.star4(pd, p, 2.0 + sin(_t * 8.0 + float(i)) * 0.8, ph, Color(TUi.PALE, 0.9), Color(TUi.VIOLET, 0.25))
	if unit.shield_left() > 0.0:
		var k := 0.8 + 0.2 * sin(_t * 9.0)
		pd.draw_set_transform(Vector2(0, -h * 0.45), 0.0, Vector2(1.0, 0.55))
		pd.draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 28, Color(TUi.FIRE_MID, 0.75 * k), 2.0)
		pd.glow(Vector2.ZERO, 34.0, Color(TUi.FIRE_OUT, 0.12 * k), 0.4)
		pd.draw_set_transform(Vector2.ZERO)
		for i in 6:
			var an := _t * 1.5 + float(i) * TAU / 6.0
			var p := Vector2(cos(an) * 30.0, -h * 0.45 + sin(an) * 16.5)
			pd.draw_line(p, p + Vector2(0, -4.0 - 3.0 * sin(_t * 11.0 + float(i))), Color(TUi.FIRE_HOT, 0.9), 1.5)
	if unit.sum("haste") > 0.0:
		for i in 3:
			var ph := _t * 5.0 + float(i) * 2.0
			var p := Vector2(-10.0 - fmod(ph * 6.0, 18.0), -2.0 - float(i) * 3.0)
			pd.draw_rect(Rect2(p, Vector2(4.0, 1.2)), Color(TUi.FIRE_HOT, 0.7))
	if unit.sum("elem", TData.ELEM_FIRE) > 0.0 and unit.elem == TData.ELEM_FIRE:
		var n := unit.stacks_of_spell("bellows")
		for i in n * 3:
			var ph := _t * 3.0 + float(i) * 1.1
			var rise := fmod(ph * 9.0, 40.0)
			pd.draw_rect(Rect2(Vector2(sin(ph * 2.0) * 10.0 - 0.75, -6.0 - rise), Vector2(1.5, 1.5)), Color(TUi.FIRE_MID, 0.8 * (1.0 - rise / 40.0)))
	if unit.sum("atk") > 0.0:
		var k := 0.5 + 0.5 * sin(_t * 4.0)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		pd.draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, Color(TUi.ATTACK_C, 0.35 + 0.25 * k), 1.0)
		pd.draw_set_transform(Vector2.ZERO)
