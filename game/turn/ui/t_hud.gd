class_name THud
extends Control
## 전투 화면의 판: 위 순서표 · 왼쪽 아래 파티 · 오른쪽 아래 마법 칸(2×3) + 물약·기다림·자동 · 알림 띠. 전부 _draw로 그리고 탭을 직접 받는다.
## 상태는 장면(TBattleScene)이 들고 있고 여기서는 읽기만 한다.

const TL_X0 := 40.0 ## 순서표 "지금" 자리
const TL_X1 := 596.0
const TL_SPAN := 8.0 ## 보이는 칸 수
const TL_Y := 20.0
const PANEL_Y := 266.0
const GRID_X := 246.0
const GRID_W := 126.0
const GRID_H := 42.0
const GRID_GAP := 4.0
const SIDE_X := 204.0

var scene: TBattleScene
var _t := 0.0
var _tl := {} ## 유닛 id → 순서표 x (부드럽게)
var banner := ""
var banner_t := 0.0
var banner_col := Color.WHITE
var tip := ""
var tip_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	banner_t = maxf(banner_t - delta, 0.0)
	tip_t = maxf(tip_t - delta, 0.0)
	queue_redraw()


func show_banner(text: String, col := TUi.TEXT, sec := 1.6) -> void:
	banner = text
	banner_col = col
	banner_t = sec


func show_tip(text: String, sec := 4.0) -> void:
	tip = text
	tip_t = sec


func spell_rect(i: int) -> Rect2:
	var cx := GRID_X + float(i % 3) * (GRID_W + GRID_GAP)
	var cy := PANEL_Y + 4.0 + float(i / 3) * (GRID_H + GRID_GAP)
	return Rect2(cx, cy, GRID_W, GRID_H)


func side_rect(i: int) -> Rect2:
	return Rect2(SIDE_X, PANEL_Y + 4.0 + float(i) * 30.0, 38.0, 26.0)


func speed_rect() -> Rect2:
	return Rect2(602.0, 4.0, 34.0, 26.0)


func potion_rect(i: int) -> Rect2:
	return Rect2(GRID_X + float(i) * (GRID_W + GRID_GAP), PANEL_Y + 4.0, GRID_W, GRID_H)


func potion_close_rect() -> Rect2:
	return Rect2(GRID_X, PANEL_Y + 4.0 + GRID_H + GRID_GAP, GRID_W * 3.0 + GRID_GAP * 2.0, GRID_H)


func _input(event: InputEvent) -> void:
	if scene == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if scene.on_tap((event as InputEventMouseButton).position):
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if scene.on_key(event as InputEventKey):
			get_viewport().set_input_as_handled()


func _draw() -> void:
	if scene == null or scene.battle == null:
		return
	_draw_timeline()
	_draw_party()
	_draw_actions()
	_draw_banner()


# ═══════════════════════════════════════════════════════════

func _draw_timeline() -> void:
	var b := scene.battle
	draw_rect(Rect2(0, 0, 640, 38), Color(0.02, 0.01, 0.04, 0.6))
	draw_line(Vector2(TL_X0, TL_Y), Vector2(TL_X1, TL_Y), Color(TUi.DIM, 0.5), 1.0)
	for i in range(1, int(TL_SPAN) + 1):
		var x := TL_X0 + (TL_X1 - TL_X0) * float(i) / TL_SPAN
		draw_line(Vector2(x, TL_Y - 3), Vector2(x, TL_Y + 3), Color(TUi.DIM, 0.5), 1.0)
		if i % 2 == 0:
			TUi.text(self, Vector2(x - 8, TL_Y + 15), str(i) + "칸", 9, Color(TUi.DIM, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 16, 2)
	draw_colored_polygon(PackedVector2Array([Vector2(TL_X0 - 5, TL_Y - 12), Vector2(TL_X0 + 5, TL_Y - 12), Vector2(TL_X0, TL_Y - 5)]), TUi.GOLD)
	TUi.text(self, Vector2(4, TL_Y + 4), "차례", 10, TUi.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	# 유닛 (기다림 순서대로, 겹치면 세로로 비킴)
	var sorted: Array[TBattle.Unit] = []
	for u in b.units:
		if u.alive:
			sorted.append(u)
	sorted.sort_custom(func(a: TBattle.Unit, c: TBattle.Unit) -> bool: return a.wait < c.wait)
	var placed: Array[float] = []
	for u in sorted:
		var tx := TL_X0 + (TL_X1 - TL_X0) * clampf(u.wait, 0.0, TL_SPAN) / TL_SPAN
		if scene.active != null and u.id == scene.active.id:
			tx = TL_X0
		var cur: float = _tl.get(u.id, tx)
		cur = lerpf(cur, tx, 0.25)
		_tl[u.id] = cur
		var row := 0
		for px in placed:
			if absf(px - cur) < 14.0:
				row += 1
		placed.append(cur)
		var y := TL_Y + (-1.0 if u.ally else 1.0) * (9.0 + 7.0 * float(mini(row, 2)))
		var col := Color(u.color)
		if not u.ally:
			col = TUi.ENEMY_C if not u.boss else Color("#ff8a4a")
		var r := 7.0 if not u.boss else 9.0
		var is_active := scene.active != null and u.id == scene.active.id
		draw_circle(Vector2(cur, y), r + 1.5, Color(0, 0, 0, 0.8))
		draw_circle(Vector2(cur, y), r, Color(col, 0.35 if not is_active else 0.7))
		draw_arc(Vector2(cur, y), r, 0.0, TAU, 16, col, 1.5 if is_active else 1.0)
		TUi.text(self, Vector2(cur - 10, y + 4), u.short, 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 20, 2)
		if u.is_casting():
			var sp := b.spec_of(u, String(u.casting.spell))
			var heavy := bool(sp.get("heavy", false))
			var ccol := TUi.CAST_C if u.ally else (TUi.RED if heavy else Color("#ffb0a6"))
			draw_arc(Vector2(cur, y), r + 3.5, _t * 4.0, _t * 4.0 + 4.0, 10, ccol, 1.5)
			var label := String(sp.get("name", ""))
			var ly := y - r - 6.0 if u.ally else y + r + 11.0
			TUi.text(self, Vector2(cur - 40, ly), label, 9, ccol, HORIZONTAL_ALIGNMENT_CENTER, 80, 2)
	# 빠르기 단추
	TUi.button(self, speed_rect(), "×2" if scene.fast else "×1", TUi.DIM if not scene.fast else TUi.GOLD, 11, scene.fast)


func _draw_party() -> void:
	var b := scene.battle
	TUi.panel(self, Rect2(0, PANEL_Y, 200, 94))
	var y := PANEL_Y + 3.0
	for u in b.allies(false):
		var is_active := scene.active != null and u.id == scene.active.id
		var col := Color(u.color)
		if is_active:
			draw_rect(Rect2(2, y, 196, 29), Color(col, 0.12))
			draw_rect(Rect2(2, y, 2, 29), col)
		draw_circle(Vector2(14, y + 14), 9.0, Color(col, 0.3 if u.alive else 0.1))
		draw_arc(Vector2(14, y + 14), 9.0, 0.0, TAU, 16, Color(col, 1.0 if u.alive else 0.3), 1.0)
		TUi.text(self, Vector2(6, y + 18), u.name.substr(0, 1), 11, Color.WHITE if u.alive else TUi.DIM, HORIZONTAL_ALIGNMENT_CENTER, 16, 2)
		TUi.text(self, Vector2(28, y + 11), u.name, 11, TUi.TEXT if u.alive else TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		TUi.text(self, Vector2(28 + TUi.text_w(u.name, 11) + 4, y + 11), "Lv" + str(u.level), 9, TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		# 체력
		var hp_rect := Rect2(28, y + 14, 80, 7)
		TUi.bar(self, hp_rect, u.hp_ratio(), TUi.HP_C if u.hp_ratio() > 0.35 else TUi.RED)
		if u.shield_left() > 0.0:
			draw_rect(Rect2(28, y + 14, 80.0 * clampf(u.shield_left() / float(u.max_hp), 0.0, 1.0), 2), TUi.SHIELD_C)
		TUi.text(self, Vector2(111, y + 21), str(u.hp), 9, TUi.TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		# 게이지
		if u.has_gauge:
			var g := u.gauge / TData.GAUGE_MAX
			var gcol := TUi.ULT_C if u.base == "eska" else TUi.FIRE_MID
			var full := g >= 0.999
			TUi.bar(self, Rect2(28, y + 24, 80, 3), g, gcol.lightened(0.3 if full else 0.0), Color(0.12, 0.08, 0.16))
			if full:
				draw_rect(Rect2(28, y + 24, 80, 3), Color(gcol, 0.6 + 0.4 * sin(_t * 8.0)), false, 1.0)
			TUi.text(self, Vector2(111, y + 29), u.gauge_name + ("!" if full else " " + str(int(u.gauge))), 8, gcol, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		# 버프 아이콘
		var bx := 148.0
		var seen := {}
		for bf in u.buffs:
			var key := String(bf.kind)
			if seen.has(key):
				continue
			seen[key] = true
			var n := 0
			var left := 0.0
			for b2 in u.buffs:
				if b2.kind == key:
					n += 1
					left = maxf(left, float(b2.left))
			var c: Color = TUi.BUFF_COLORS.get(key, TUi.TEXT)
			draw_rect(Rect2(bx, y + 3, 15, 10), Color(c, 0.3))
			draw_rect(Rect2(bx, y + 3, 15, 10), Color(c, 0.9), false, 1.0)
			TUi.text(self, Vector2(bx, y + 12), String(TUi.BUFF_SHORT.get(key, key)) + (str(n) if n > 1 else ""), 8, c.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 15, 2)
			bx += 16.0
			if bx > 184.0:
				break
		y += 30.0


func _draw_actions() -> void:
	var b := scene.battle
	TUi.panel(self, Rect2(202, PANEL_Y, 438, 94))
	var u := scene.active
	if u == null or not scene.waiting():
		var msg := ""
		if scene.auto:
			msg = "자동 전투 중 — 멈추려면 [자동]을 다시 누르세요"
		elif scene.phase == TBattleScene.Phase.PLAYING:
			msg = ""
		TUi.text(self, Vector2(220, PANEL_Y + 54), msg, 11, TUi.DIM, HORIZONTAL_ALIGNMENT_CENTER, 400, 2)
		TUi.button(self, side_rect(2), "자동", TUi.GOLD if scene.auto else TUi.DIM, 10, scene.auto)
		return
	# 옆 단추
	TUi.button(self, side_rect(0), "물약", TUi.GREEN if not b.bag.is_empty() else TUi.DIM, 10, scene.potion_menu, b.bag.is_empty())
	TUi.button(self, side_rect(1), "대기", TUi.DIM, 10)
	TUi.button(self, side_rect(2), "자동", TUi.GOLD if scene.auto else TUi.DIM, 10, scene.auto)
	if scene.potion_menu:
		for i in mini(b.bag.size(), 3):
			var pid := b.bag[i]
			var sp: Dictionary = TData.POTIONS[pid]
			var hot := scene.sel_potion == pid
			var col := Color(String(sp.color))
			TUi.button(self, potion_rect(i), "", col, 11, hot)
			var r := potion_rect(i)
			TUi.text(self, Vector2(r.position.x + 6, r.position.y + 16), String(sp.name) + ("  (던짐)" if bool(sp.throw) else "  (마심)"), 11, Color.WHITE if hot else col.lightened(0.3), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
			TUi.text(self, Vector2(r.position.x + 6, r.position.y + 32), TUi.fit(String(sp.desc), 9, r.size.x - 10.0), 9, TUi.DIM if not hot else TUi.TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		TUi.button(self, potion_close_rect(), "닫기  (물약은 차례를 쓰지 않아요)", TUi.DIM, 11)
		return
	var spells: Array = TData.witch(u.base).get("spells", [])
	for i in spells.size():
		var sid := String(spells[i])
		var sp := TData.spell(sid)
		var r := spell_rect(i)
		var unlocked := sid in u.spells
		var usable := b.can_use(u, sid)
		var kind := String(sp.get("kind", ""))
		var col := TUi.kind_color(kind)
		var hot := scene.sel_spell == sid
		TUi.button(self, r, "", col, 11, hot, not usable)
		var name_col := Color.WHITE if hot else (col.lightened(0.25) if usable else Color(col, 0.45))
		TUi.text(self, Vector2(r.position.x + 6, r.position.y + 15), String(sp.name), 12, name_col, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		var tag := ""
		if not unlocked:
			tag = "아직 못 배움"
		elif kind == "ult":
			tag = "대마법 " + str(int(u.gauge)) + "%" + ("  시전 " + str(int(sp.get("cast", 0))) + "칸" if usable else "")
		elif u.cd_left(sid) > 0.001:
			tag = "재사용까지 %.1f칸" % u.cd_left(sid)
		else:
			var kn := "공격" if kind == "attack" else "지원"
			var tg := String(sp.get("target", ""))
			var tgn: String = {"enemy": "적 하나", "all": "적 모두", "ally": "아군 하나", "allies": "아군 모두", "self": "자신"}.get(tg, "")
			tag = kn + " · " + tgn
			if float(sp.get("power", 0.0)) > 0.0:
				tag += " · 위력 " + str(int(sp.power)) + (" ×" + str(int(sp.get("hits", 1))) if int(sp.get("hits", 1)) > 1 else "")
		TUi.text(self, Vector2(r.position.x + 6, r.position.y + 31), TUi.fit(tag, 9, r.size.x - 40.0), 9, TUi.TEXT if hot else (TUi.DIM if usable else Color(TUi.DIM, 0.5)), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		TUi.text(self, Vector2(r.position.x + r.size.x - 14, r.position.y + 13), str(i + 1), 9, Color(TUi.DIM, 0.7), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		if bool(sp.get("interrupt", false)):
			TUi.text(self, Vector2(r.position.x + r.size.x - 36, r.position.y + 31), "끊기", 9, TUi.PALE, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	# 고르기 안내
	if scene.sel_spell != "" or scene.sel_potion != "":
		var what := ""
		if scene.sel_spell != "":
			what = String(TData.spell(scene.sel_spell).get("name", ""))
		else:
			what = String(TData.POTIONS[scene.sel_potion].name)
		var tname := scene.cand[scene.cand_i].name if not scene.cand.is_empty() else ""
		draw_rect(Rect2(160, 236, 320, 20), Color(0.02, 0.01, 0.04, 0.7))
		TUi.text(self, Vector2(160, 251), what + " → 대상을 누르세요 (다시 누르면 " + tname + ")", 11, TUi.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 320, 2)


func _draw_banner() -> void:
	if tip_t > 0.0 and tip != "":
		var a := minf(tip_t, 1.0)
		draw_rect(Rect2(120, 40, 400, 20), Color(0.02, 0.01, 0.04, 0.6 * a))
		TUi.text(self, Vector2(120, 55), tip, 11, Color(TUi.PALE, a), HORIZONTAL_ALIGNMENT_CENTER, 400, 2)
	if banner_t > 0.0 and banner != "":
		var a := minf(banner_t * 2.0, 1.0)
		var pop := 1.0 + 0.15 * clampf((banner_t - 1.2) / 0.4, 0.0, 1.0)
		draw_rect(Rect2(0, 120, 640, 48), Color(0.02, 0.01, 0.04, 0.55 * a))
		draw_set_transform(Vector2(320, 144), 0.0, Vector2(pop, pop))
		TUi.text(self, Vector2(-300, 9), banner, 22, Color(banner_col, a), HORIZONTAL_ALIGNMENT_CENTER, 600, 4)
		draw_set_transform(Vector2.ZERO)
