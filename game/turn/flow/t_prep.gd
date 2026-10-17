class_name TPrep
extends Control
## 준비 화면(마법학교 교실): 수업 점수로 마법을 배우고, 빗자루를 바꾸고, 물약 가방(3개)을 꾸린 뒤 출발.
## 왼쪽 마녀 카드 셋(누르면 오른쪽에 그 마녀의 마법 여섯) · 아래 물약 · 오른쪽 아래 [출발]

signal go
signal back

var run: TRun
var sel := "eska"
var _rects := {} ## id → Rect2 (프레임마다 다시 채움)
var _t := 0.0
var _msg := ""
var _msg_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sel = run.dealer if run else "eska"


func _process(delta: float) -> void:
	_t += delta
	_msg_t = maxf(_msg_t - delta, 0.0)
	queue_redraw()


func _say(s: String) -> void:
	_msg = s
	_msg_t = 2.5


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := (event as InputEventMouseButton).position
		for id in _rects.keys():
			if (_rects[id] as Rect2).has_point(p):
				_tap(String(id))
				get_viewport().set_input_as_handled()
				return
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			go.emit()


func _tap(id: String) -> void:
	var parts := id.split(":")
	match parts[0]:
		"go":
			if run.bag.is_empty():
				_say("물약을 하나도 안 들고 가요 — 그래도 출발합니다")
			Sfx.play(&"ui_ok", -4.0, 0.0)
			go.emit()
		"back":
			back.emit()
		"witch":
			sel = parts[1]
			Sfx.play(&"ui_move", -6.0, 0.0)
		"dealer":
			run.dealer = parts[1]
			Sfx.play(&"ui_move", -6.0, 0.0)
		"broom":
			var w := parts[1]
			var ids: Array = TData.BROOMS.keys()
			var cur: String = run.brooms.get(w, "")
			var i := ids.find(cur)
			var nxt := String(ids[(i + 1) % ids.size()]) if i >= 0 else String(ids[0])
			if i == ids.size() - 1:
				nxt = ""
			run.set_broom(w, nxt)
			Sfx.play(&"ui_move", -6.0, 0.0)
		"learn":
			var w := parts[1]
			var s := parts[2]
			if run.learn(w, s):
				Sfx.play(&"magic_learn", -4.0, 0.0)
				_say(String(TData.spell(s).name) + " 배움!")
			else:
				Sfx.play(&"block", -6.0, 0.0)
				_say("수업 점수가 모자라요 (" + str(run.spell_cost(s)) + "점 필요)")
		"potion":
			run.toggle_bag(parts[1])
			Sfx.play(&"ui_move", -6.0, 0.0)


func _draw() -> void:
	_rects.clear()
	draw_rect(Rect2(0, 0, 640, 360), Color("#0e0a16"))
	var b := run.current_battle()
	TUi.text(self, Vector2(10, 20), "교실 · 다음 전투: " + str(run.battle_i + 1) + ". " + String(b.get("name", "")), 13, TUi.PALE)
	TUi.text(self, Vector2(10, 36), TUi.fit(String(b.get("intro", "")), 10, 430.0), 10, TUi.DIM)
	TUi.text(self, Vector2(640 - 12, 20), "수업 점수 " + str(run.points) + "점", 13, TUi.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 200)
	if run.best_hit > 0:
		TUi.text(self, Vector2(640 - 12, 36), "최고 한 방 " + TUi.fmt(run.best_hit), 10, TUi.EDGE, HORIZONTAL_ALIGNMENT_RIGHT, 200)
	# ── 마녀 카드
	var y := 46.0
	for w in run.party:
		var d: Dictionary = TData.witch(w)
		var st := run.stats(w)
		var rect := Rect2(6, y, 232, 78)
		var hot := sel == w
		TUi.panel(self, rect, Color(Color(String(d.color)), 0.14 if hot else 0.06), Color(Color(String(d.color)), 0.9 if hot else 0.35))
		_rects["witch:" + w] = rect
		TUi.text(self, Vector2(14, y + 16), String(d.name), 13, Color(String(d.color)).lightened(0.2))
		TUi.text(self, Vector2(14 + TUi.text_w(String(d.name), 13) + 6, y + 16), String(d.title) + " · Lv" + str(st.level), 10, TUi.DIM)
		TUi.text(self, Vector2(14, y + 31), "체력 %d · 공격 %d · 차례 %.1f칸 · %s" % [int(st.hp), int(round(float(st.atk))), float(st.wait), TData.elem_name(String(d.elem))], 10, TUi.TEXT)
		var broom: String = run.brooms.get(w, "")
		var bd: Dictionary = TData.BROOMS.get(broom, {})
		var brect := Rect2(14, y + 38, 150, 18)
		TUi.button(self, brect, "빗자루: " + (String(bd.get("name", "")) if not bd.is_empty() else "없음"), Color(String(bd.get("color", "#8a7fa3"))), 10)
		_rects["broom:" + w] = brect
		TUi.text(self, Vector2(14, y + 70), TUi.fit(String(bd.get("desc", "누르면 바꿈. 한 자루는 한 사람만.")), 9, 218.0), 9, TUi.DIM)
		var drect := Rect2(170, y + 38, 60, 18)
		var is_dealer := run.dealer == w
		TUi.button(self, drect, "딜러" if is_dealer else "딜러로", TUi.ATTACK_C if is_dealer else TUi.DIM, 10, is_dealer)
		_rects["dealer:" + w] = drect
		y += 82.0
	TUi.text(self, Vector2(8, 300), "[딜러] = 자동 전투·기본 대상이 버프를 몰아줄 사람", 9, TUi.DIM)
	# ── 마법 목록
	var wd: Dictionary = TData.witch(sel)
	var sx := 246.0
	var sy := 46.0
	TUi.text(self, Vector2(sx, sy + 10), String(wd.name) + "의 마법 — " + String(wd.get("desc", "")), 10, TUi.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 390)
	sy += 16.0
	for s in wd.get("spells", []):
		var sid := String(s)
		var sp := TData.spell(sid)
		var rect := Rect2(sx, sy, 388, 38)
		var unlocked := run.is_unlocked(sel, sid)
		var kind := String(sp.get("kind", ""))
		var col := TUi.kind_color(kind)
		draw_rect(rect, Color(col, 0.08 if unlocked else 0.03))
		draw_rect(rect, Color(col, 0.5 if unlocked else 0.2), false, 1.0)
		TUi.text(self, Vector2(sx + 6, sy + 14), String(sp.name), 12, col.lightened(0.2) if unlocked else Color(col, 0.5))
		var kn: String = {"attack": "공격", "support": "지원", "ult": "대마법"}.get(kind, "")
		var nx := sx + 6 + TUi.text_w(String(sp.name), 12) + 6
		TUi.text(self, Vector2(nx, sy + 14), TUi.fit(kn + " · " + _summary(sp), 9, sx + 298 - nx), 9, TUi.DIM if unlocked else Color(TUi.DIM, 0.6))
		TUi.text(self, Vector2(sx + 6, sy + 30), TUi.fit(String(sp.get("desc", "")), 9, 290.0), 9, TUi.TEXT if unlocked else Color(TUi.DIM, 0.7))
		if not unlocked:
			var cost := run.spell_cost(sid)
			var lrect := Rect2(sx + 304, sy + 6, 78, 26)
			var can := run.points >= cost
			TUi.button(self, lrect, "배우기 " + str(cost) + "점", TUi.GOLD if can else TUi.DIM, 10, false, not can)
			_rects["learn:" + sel + ":" + sid] = lrect
		else:
			TUi.text(self, Vector2(sx + 304, sy + 22), "배움", 10, Color(TUi.GREEN, 0.7), HORIZONTAL_ALIGNMENT_CENTER, 78)
		sy += 40.0
	# ── 물약 가방
	var py := 306.0
	TUi.text(self, Vector2(10, py + 12), "물약 가방 %d/%d (차례를 쓰지 않음)" % [run.bag.size(), TData.BAG_SIZE], 10, TUi.GREEN)
	var px := 10.0
	for pid in TData.POTIONS.keys():
		var have := int(run.pouch.get(pid, 0))
		var inbag := run.bag.count(String(pid))
		var sp: Dictionary = TData.POTIONS[pid]
		var rect := Rect2(px, py + 18, 96, 30)
		var col := Color(String(sp.color))
		TUi.button(self, rect, "", col, 10, inbag > 0, have == 0)
		TUi.text(self, Vector2(px + 5, py + 31), String(sp.name) + " ×" + str(have), 10, Color.WHITE if inbag > 0 else (col.lightened(0.3) if have > 0 else Color(col, 0.4)))
		TUi.text(self, Vector2(px + 5, py + 43), ("가방 " + str(inbag)) if inbag > 0 else String(sp.get("desc", "")).substr(0, 14), 8, TUi.TEXT if inbag > 0 else TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, 90)
		if have > 0:
			_rects["potion:" + String(pid)] = rect
		px += 100.0
	var go_rect := Rect2(536, 310, 98, 42)
	TUi.button(self, go_rect, "출발 ▶", TUi.GOLD, 14, fmod(_t, 1.2) < 0.7)
	_rects["go"] = go_rect
	var back_rect := Rect2(536, 290, 98, 16)
	TUi.button(self, back_rect, "타이틀로", TUi.DIM, 9)
	_rects["back"] = back_rect
	if _msg_t > 0.0:
		draw_rect(Rect2(140, 150, 360, 24), Color(0.02, 0.01, 0.04, 0.8))
		TUi.text(self, Vector2(140, 167), _msg, 11, TUi.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 360)


## 마법 한 줄 요약
static func _summary(sp: Dictionary) -> String:
	var parts: Array[String] = []
	var tg := String(sp.get("target", ""))
	parts.append(String({"enemy": "적 하나", "all": "적 모두", "ally": "아군 하나", "allies": "아군 모두", "self": "자신"}.get(tg, "")))
	if float(sp.get("power", 0.0)) > 0.0:
		parts.append("위력 " + str(int(sp.power)) + (" ×" + str(int(sp.get("hits", 1))) if int(sp.get("hits", 1)) > 1 else ""))
	for b in sp.get("buffs", []):
		var kind := String(b.kind)
		var amt := float(b.amt)
		var s := TData.kind_name(kind)
		if kind == "shield":
			s += " " + str(int(amt))
		else:
			s += (" +" if amt >= 0.0 else " ") + TUi.pct(amt)
		s += " " + str(int(b.dur)) + "칸"
		if int(b.get("stack", 1)) > 1:
			s += " " + str(int(b.stack)) + "겹"
		parts.append(s)
	if float(sp.get("heal", 0.0)) > 0.0:
		parts.append("회복 " + TUi.pct(float(sp.heal)))
	if float(sp.get("push", 0.0)) > 0.0:
		parts.append("미룸 " + str(sp.push) + "칸")
	if float(sp.get("pull", 0.0)) > 0.0:
		parts.append("당김 " + str(sp.pull) + "칸")
	if bool(sp.get("interrupt", false)):
		parts.append("끊기" + ("(굳센)" if bool(sp.get("heavy", false)) else ""))
	if float(sp.get("cast", 0.0)) > 0.0:
		parts.append("시전 " + str(int(sp.cast)) + "칸")
	if float(sp.get("cd", 0.0)) > 0.0:
		parts.append("재사용 " + str(int(sp.cd)) + "칸")
	return " · ".join(parts)
