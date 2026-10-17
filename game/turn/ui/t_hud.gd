class_name THud
extends Control
## 전투 판 v0.3 (마력제): 왼쪽 위 파티 카드(누르면 그 마녀의 마법창) · 위 가운데 라운드·남은 마력·[턴 종료] · 그 아래 이번 턴 연계 줄 · 오른쪽 위 [자동][×2]
## · 행동하는 마녀 **옆에 펼쳐지는** 세로 마법창(6칸 + 물약) · 알림 띠. 전부 _draw로 그리고 탭을 직접 받는다. 상태는 장면이 들고 있다.

const CARD_W := 170.0
const CARD_H := 24.0
const MENU_W := 138.0
const MENU_H := 24.0
const MENU_GAP := 2.0

var scene: TBattleScene
var _t := 0.0
var banner := ""
var banner_t := 0.0
var banner_col := Color.WHITE
var tip := ""
var tip_t := 0.0
var turn_text := ""
var turn_t := 0.0
var turn_col := Color.WHITE
var _menu_anchor := Vector2.ZERO
var _menu_left := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	banner_t = maxf(banner_t - delta, 0.0)
	tip_t = maxf(tip_t - delta, 0.0)
	turn_t = maxf(turn_t - delta, 0.0)
	queue_redraw()


func show_banner(text: String, col := TUi.TEXT, sec := 1.6) -> void:
	banner = text
	banner_col = col
	banner_t = sec


func show_turn(text: String, col: Color) -> void:
	turn_text = text
	turn_col = col
	turn_t = 1.1


func show_tip(text: String, sec := 4.0) -> void:
	tip = text
	tip_t = sec


# ── 자리 ──────────────────────────────────────────────

func card_rect(i: int) -> Rect2:
	return Rect2(6.0, 6.0 + float(i) * (CARD_H + 3.0), CARD_W, CARD_H)


func end_rect() -> Rect2:
	return Rect2(434.0, 6.0, 50.0, 24.0)


func auto_rect() -> Rect2:
	return Rect2(488.0, 6.0, 56.0, 24.0)


func speed_rect() -> Rect2:
	return Rect2(550.0, 6.0, 40.0, 24.0)


## 마법창 자리: 마녀 머리 높이에서 위로 6칸. 오른쪽에 있는 마녀(x > 300)는 왼쪽으로 펼친다
func _menu_origin() -> Vector2:
	var a := scene.actor_of(scene.sel_unit.id) if scene.sel_unit else null
	if a == null:
		return Vector2(240, 60)
	var left := a.position.x > 300.0
	var x := a.position.x + 40.0 if not left else a.position.x - 40.0 - MENU_W
	x = clampf(x, 6.0, 640.0 - MENU_W - 6.0)
	var bottom := a.head().y
	var top := bottom - 6.0 * (MENU_H + MENU_GAP)
	top = clampf(top, 36.0, 360.0 - 7.0 * (MENU_H + MENU_GAP) - 6.0)
	_menu_left = left
	_menu_anchor = Vector2(x, top)
	return _menu_anchor


func menu_rect(i: int) -> Rect2:
	var o := _menu_origin()
	return Rect2(o.x, o.y + float(i) * (MENU_H + MENU_GAP), MENU_W, MENU_H)


## 7번째 칸 = 물약 (가방이 비었으면 흐리게)
func potion_btn_rect() -> Rect2:
	return menu_rect(6)


## 물약 하위 메뉴: 마법창 자리에 가방 물약 3개 + 닫기
func potion_rect(i: int) -> Rect2:
	return menu_rect(i)


func potion_close_rect() -> Rect2:
	return menu_rect(3)


func _input(event: InputEvent) -> void:
	if scene == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if scene.on_tap((event as InputEventMouseButton).position):
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if scene.on_key(event as InputEventKey):
			get_viewport().set_input_as_handled()


# ── 그리기 ────────────────────────────────────────────

func _draw() -> void:
	if scene == null or scene.battle == null:
		return
	_draw_party()
	_draw_top()
	_draw_combo()
	if scene.waiting() and scene.sel_unit != null:
		_draw_menu()
	_draw_target_hint()
	_draw_banner()


func _draw_party() -> void:
	var b := scene.battle
	for u in b.allies(false):
		var r := card_rect(u.slot)
		var sel := scene.sel_unit != null and scene.sel_unit.id == u.id
		var col := Color(u.color)
		TUi.panel(self, r, Color(col, 0.16 if sel else 0.08) if u.alive else Color(0.1, 0.08, 0.12, 0.7), Color(col, 1.0 if sel else 0.45))
		draw_circle(r.position + Vector2(12, 12), 8.0, Color(col, 0.35 if u.alive else 0.12))
		draw_arc(r.position + Vector2(12, 12), 8.0, 0.0, TAU, 16, Color(col, 1.0 if u.alive else 0.3), 1.0)
		TUi.text(self, Vector2(r.position.x + 4, r.position.y + 16), u.short, 10, Color.WHITE if u.alive else TUi.DIM, HORIZONTAL_ALIGNMENT_CENTER, 16, 2)
		TUi.text(self, Vector2(r.position.x + 26, r.position.y + 11), u.name + " Lv" + str(u.level), 10, TUi.TEXT if u.alive else TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		TUi.bar(self, Rect2(r.position.x + 26, r.position.y + 13, 70, 6), u.hp_ratio(), TUi.HP_C if u.hp_ratio() > 0.35 else TUi.RED)
		if u.shield_left() > 0.0:
			draw_rect(Rect2(r.position.x + 26, r.position.y + 13, 70.0 * clampf(u.shield_left() / float(u.max_hp), 0.0, 1.0), 2), TUi.SHIELD_C)
		TUi.text(self, Vector2(r.position.x + 98, r.position.y + 19), str(u.hp), 9, TUi.TEXT if u.alive else TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		if u.has_gauge:
			var g := u.gauge / TData.GAUGE_MAX
			var gcol := TUi.ULT_C if u.base == "eska" else TUi.FIRE_MID
			var full := g >= 0.999
			TUi.bar(self, Rect2(r.position.x + 26, r.position.y + 20, 70, 3), g, gcol.lightened(0.3 if full else 0.0), Color(0.12, 0.08, 0.16))
			if full:
				draw_rect(Rect2(r.position.x + 26, r.position.y + 20, 70, 3), Color(gcol, 0.6 + 0.4 * sin(_t * 8.0)), false, 1.0)
		# 버프 아이콘 (오른쪽 끝)
		var bx := r.position.x + r.size.x - 4.0
		var seen := {}
		var shown := 0
		for bf in u.buffs:
			var key := String(bf.kind)
			if seen.has(key) or shown >= 3:
				continue
			seen[key] = true
			shown += 1
			var n := 0
			for b2 in u.buffs:
				if b2.kind == key:
					n += 1
			var c: Color = TUi.BUFF_COLORS.get(key, TUi.TEXT)
			bx -= 15.0
			draw_rect(Rect2(bx, r.position.y + 7, 14, 10), Color(c, 0.3))
			draw_rect(Rect2(bx, r.position.y + 7, 14, 10), Color(c, 0.9), false, 1.0)
			TUi.text(self, Vector2(bx, r.position.y + 16), String(TUi.BUFF_SHORT.get(key, key)).substr(0, 1) + (str(n) if n > 1 else ""), 8, c.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 14, 2)


func _draw_top() -> void:
	var b := scene.battle
	var my := b.player_phase and scene.phase != TBattleScene.Phase.OVER
	draw_rect(Rect2(186, 6, 244, 24), Color(0.02, 0.01, 0.04, 0.6))
	draw_rect(Rect2(186, 6, 244, 24), Color(TUi.GOLD if my else TUi.ENEMY_C, 0.5), false, 1.0)
	TUi.text(self, Vector2(194, 23), "라운드 " + str(b.round), 12, TUi.PALE, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	if my:
		TUi.text(self, Vector2(258, 23), "내 턴 · 마력", 11, TUi.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		var n := maxi(b.mana_left, 0)
		var total := maxi(b.mana_max, n)
		# 고른 마법의 비용만큼은 붉게 (쓰면 사라질 마력)
		var spend := 0
		if scene.sel_spell != "":
			spend = mini(b.cost_of(scene.sel_spell), n)
		for i in total:
			var on := i < n
			var cx := 334.0 + float(i) * 10.0
			var cc := Color(TUi.GOLD, 0.95) if on else Color(TUi.GOLD, 0.15)
			if on and i >= n - spend:
				cc = Color(TUi.FIRE_HOT, 0.75 + 0.25 * sin(_t * 9.0))
			draw_circle(Vector2(cx, 18), 4.2, cc)
			draw_arc(Vector2(cx, 18), 4.2, 0.0, TAU, 12, Color(TUi.GOLD, 0.8), 1.0)
	else:
		TUi.text(self, Vector2(258, 23), "적 턴", 11, TUi.ENEMY_C, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	if scene.waiting():
		TUi.button(self, end_rect(), "턴 종료", TUi.PALE, 10, not b.any_usable())
	TUi.button(self, auto_rect(), "자동", TUi.GOLD if scene.auto else TUi.DIM, 10, scene.auto)
	TUi.button(self, speed_rect(), "×2" if scene.fast else "×1", TUi.GOLD if scene.fast else TUi.DIM, 10, scene.fast)
	if turn_t > 0.0 and turn_text != "":
		var a := minf(turn_t * 2.0, 1.0)
		var k := 1.0 - clampf((turn_t - 0.9) / 0.2, 0.0, 1.0)
		draw_rect(Rect2(0, 150, 640, 40), Color(0.02, 0.01, 0.04, 0.5 * a))
		draw_rect(Rect2(0, 150, 640 * k, 1), Color(turn_col, a))
		draw_rect(Rect2(640 - 640 * k, 189, 640 * k, 1), Color(turn_col, a))
		TUi.text(self, Vector2(0, 178), turn_text, 20, Color(turn_col, a), HORIZONTAL_ALIGNMENT_CENTER, 640, 4)


## 이번 턴의 연계 줄: 쓴 마법 이름들과 마지막 공격의 총 배율
func _draw_combo() -> void:
	var b := scene.battle
	if not b.player_phase or b.combo.is_empty() or scene.phase == TBattleScene.Phase.OVER:
		return
	var names := " → ".join(b.combo)
	var mult := b.combo_mult
	var ms := ("  ×%.1f" % mult) if mult > 1.05 else ""
	var txt := TUi.fit("연계  " + names, 10, 300.0 - TUi.text_w(ms, 11))
	var w := TUi.text_w(txt, 10) + TUi.text_w(ms, 11) + 16.0
	var x := maxf(330.0 - w * 0.5, 186.0) ## 파티 카드(~176)와 겹치지 않게
	draw_rect(Rect2(x, 34, w, 16), Color(0.02, 0.01, 0.04, 0.7))
	draw_rect(Rect2(x, 34, w, 16), Color(TUi.GOLD, 0.25 if mult < 4.0 else 0.7), false, 1.0)
	TUi.text(self, Vector2(x + 8, 46), txt, 10, TUi.PALE, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	if ms != "":
		var mcol := TUi.GOLD if mult >= 4.0 else TUi.TEXT
		TUi.text(self, Vector2(x + 8 + TUi.text_w(txt, 10), 46), ms, 11, mcol, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)


func _draw_menu() -> void:
	var b := scene.battle
	var u := scene.sel_unit
	var o := _menu_origin()
	# 바탕 (뒤의 마녀·적이 비치지 않게) + 머리글
	draw_rect(Rect2(o.x - 3, o.y - 19, MENU_W + 6, 7.0 * (MENU_H + MENU_GAP) + 20), Color(0.03, 0.02, 0.06, 0.84))
	draw_rect(Rect2(o.x - 3, o.y - 19, MENU_W + 6, 7.0 * (MENU_H + MENU_GAP) + 20), Color(Color(u.color), 0.35), false, 1.0)
	draw_rect(Rect2(o.x, o.y - 16, MENU_W, 14), Color(Color(u.color), 0.25))
	TUi.text(self, Vector2(o.x + 4, o.y - 5), u.name + "의 마법", 10, Color(u.color).lightened(0.3), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	if scene.potion_menu:
		for i in 3:
			var r := potion_rect(i)
			if i < b.bag.size():
				var pid := b.bag[i]
				var sp: Dictionary = TData.POTIONS[pid]
				var hot := scene.sel_potion == pid
				var col := Color(String(sp.color))
				TUi.button(self, r, "", col, 10, hot)
				TUi.text(self, Vector2(r.position.x + 5, r.position.y + 11), String(sp.name) + ("  (던짐)" if bool(sp.throw) else ""), 10, Color.WHITE if hot else col.lightened(0.3), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
				TUi.text(self, Vector2(r.position.x + 5, r.position.y + 21), TUi.fit(String(sp.desc), 8, r.size.x - 8.0), 8, TUi.TEXT if hot else TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
			else:
				TUi.button(self, r, "—", TUi.DIM, 10, false, true)
		TUi.button(self, potion_close_rect(), "닫기 · 물약은 마력을 안 씀", TUi.DIM, 9)
		return
	var spells: Array = TData.witch(u.base).get("spells", [])
	for i in spells.size():
		var sid := String(spells[i])
		var sp := TData.spell(sid)
		var r := menu_rect(i)
		var unlocked := sid in u.spells
		var usable := b.can_use(u, sid)
		var kind := String(sp.get("kind", ""))
		var col := TUi.kind_color(kind)
		var hot := scene.sel_spell == sid
		TUi.button(self, r, "", col, 10, hot, not usable)
		var name_col := Color.WHITE if hot else (col.lightened(0.25) if usable else Color(col, 0.45))
		TUi.text(self, Vector2(r.position.x + 5, r.position.y + 11), String(sp.name), 11, name_col, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		var tag := ""
		if not unlocked:
			tag = "아직 못 배움"
		elif kind == "ult":
			tag = "대마법 · 게이지 " + str(int(u.gauge)) + "%"
		elif u.cd_left(sid) > 0:
			tag = "재사용까지 %d턴" % u.cd_left(sid)
		elif b.cost_of(sid) > b.mana_left:
			tag = "마력 %d 필요" % b.cost_of(sid)
		else:
			var tg := String(sp.get("target", ""))
			var tgn: String = {"enemy": "적 하나", "all": "적 모두", "ally": "아군 하나", "allies": "아군 모두", "self": "자신"}.get(tg, "")
			tag = ("공격" if kind == "attack" else "지원") + " · " + tgn
			if float(sp.get("power", 0.0)) > 0.0:
				tag += " · 위력 " + str(int(sp.power)) + (" ×" + str(int(sp.get("hits", 1))) if int(sp.get("hits", 1)) > 1 else "")
			elif int(sp.get("cd", 0)) > 0:
				tag += " · 쿨 " + str(int(sp.cd)) + "턴"
		TUi.text(self, Vector2(r.position.x + 5, r.position.y + 21), TUi.fit(tag, 8, r.size.x - 28.0), 8, TUi.TEXT if hot else (TUi.DIM if usable else Color(TUi.DIM, 0.5)), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		TUi.text(self, Vector2(r.position.x + r.size.x - 12, r.position.y + 11), str(i + 1), 8, Color(TUi.DIM, 0.7), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		# 마력 비용 배지
		var cost := b.cost_of(sid)
		var ccol := TUi.GOLD if (usable or unlocked and cost <= b.mana_left) else Color(TUi.DIM, 0.6)
		TUi.text(self, Vector2(r.position.x + r.size.x - 34, r.position.y + 11), ("◆" + str(cost)) if cost > 0 else "◆0", 9, ccol, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		if bool(sp.get("interrupt", false)):
			TUi.text(self, Vector2(r.position.x + r.size.x - 24, r.position.y + 21), "끊기", 8, TUi.PALE, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	var pr := potion_btn_rect()
	TUi.button(self, pr, "물약 " + str(b.bag.size()) + "개 (마력 안 씀)", TUi.GREEN if not b.bag.is_empty() else TUi.DIM, 9, false, b.bag.is_empty())


func _draw_target_hint() -> void:
	if scene.sel_spell == "" and scene.sel_potion == "":
		return
	var what := ""
	if scene.sel_spell != "":
		what = String(TData.spell(scene.sel_spell).get("name", ""))
	else:
		what = String(TData.POTIONS[scene.sel_potion].name)
	var tname := scene.cand[scene.cand_i].name if not scene.cand.is_empty() else ""
	# 아래 띠(도움말 자리)에 — 위쪽은 마법창 머리글과 겹친다
	draw_rect(Rect2(90, 338, 460, 18), Color(0.02, 0.01, 0.04, 0.85))
	TUi.text(self, Vector2(90, 352), what + " → 대상을 누르세요 (다시 누르면 " + tname + ")", 11, TUi.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 460, 2)


func _draw_banner() -> void:
	if tip_t > 0.0 and tip != "" and scene.sel_spell == "" and scene.sel_potion == "":
		var a := minf(tip_t, 1.0)
		draw_rect(Rect2(90, 338, 460, 18), Color(0.02, 0.01, 0.04, 0.6 * a))
		TUi.text(self, Vector2(90, 352), TUi.fit(tip, 10, 450.0), 10, Color(TUi.PALE, a), HORIZONTAL_ALIGNMENT_CENTER, 460, 2)
	if banner_t > 0.0 and banner != "":
		var a := minf(banner_t * 2.0, 1.0)
		var pop := 1.0 + 0.15 * clampf((banner_t - 1.2) / 0.4, 0.0, 1.0)
		draw_rect(Rect2(0, 120, 640, 48), Color(0.02, 0.01, 0.04, 0.55 * a))
		draw_set_transform(Vector2(320, 144), 0.0, Vector2(pop, pop))
		TUi.text(self, Vector2(-300, 9), banner, 22, Color(banner_col, a), HORIZONTAL_ALIGNMENT_CENTER, 600, 4)
		draw_set_transform(Vector2.ZERO)
