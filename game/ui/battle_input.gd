## battle_input.gd — 하스스톤식 드래그 (HTML 판 input.js). 마우스·터치 공통(터치는 마우스로 흉내 낸 이벤트).
##  · 대상 카드: 카드를 끌면 손에서 화살표 → 유효 대상 위에서 놓으면 사용
##  · 대상 없는 카드: 손패 위쪽으로 끌어올려 놓으면 사용
##  · 운명 전가: ① 적의 예고에 놓기 → ② 새로 맞을 아군 누르기 (빈 곳·우클릭·Esc: 취소)
##  · 잠긴 죽음 카드: 끌거나 누르면 손패로 돌아가고 노엘의 속마음이 뜬다(대본 2장)
## 터치에는 마우스 올림이 없다: 카드를 누르고 있으면 확대, 끌면 사용 / 적 예고를 탭하면 대상 선 / 빈 곳을 탭하면 대사 넘김
class_name BattleInput
extends Node

var mode := "idle"        # idle | drag | pick | busy
var p := Vector2.ZERO
var drag := {}
var touch := false
var prompt: Label


func V() -> BattleView:
	return G.view


func H() -> HandView:
	return G.view.hand


func battle_ready() -> bool:
	var c = G.ctl
	return c.in_battle and not c.st.is_empty() and c.st.battle != null and c.st.battle.phase == "player" and c.st.battle.result == null and not G.scenes.is_open()


func move_thresh() -> float:
	return (12.0 if touch else 8.0) / minf(1.0, maxf(0.05, FX.css_scale))


func set_pointer(is_touch: bool) -> void:
	touch = is_touch
	V().hit_pad = minf(40.0, 16.0 / maxf(0.05, FX.css_scale)) if is_touch else 0.0


func set_intent_hover(id: String) -> void:
	V().hover_intent = id
	V().render()


func set_prompt(text: String) -> void:
	if prompt == null:
		var bgp := Control.new()
		bgp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bgp.z_index = 330
		G.main.ui_layer.add_child(bgp)
		prompt = UI.label("", 28, Color("#ffd9dc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
		bgp.add_child(prompt)
		bgp.draw.connect(func(): bgp.draw_style_box(UI.box(Color(0.04, 0, 0.016, 0.9), UI.RED, 22, 2), Rect2(Vector2.ZERO, bgp.size)))
	var holder: Control = prompt.get_parent()
	holder.visible = text != ""
	prompt.text = text
	prompt.reset_size()
	var sz := Assets.font("sans_bold").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28) + Vector2(48, 18)
	holder.size = sz
	holder.position = Vector2(960 - sz.x / 2.0, 600)
	prompt.position = Vector2(24, 7)
	holder.queue_redraw()


## Main 이 전투 중 입력을 넘겨준다. pos: 무대 좌표
func handle(e: InputEvent, pos: Vector2, is_touch: bool) -> void:
	p = pos
	if e is InputEventMouseMotion:
		_on_move(is_touch)
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
			if not is_touch:
				cancel_drag()
			return
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			set_pointer(is_touch)
			_on_down(is_touch)
		else:
			_on_up()


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		cancel_drag()


func _on_move(is_touch: bool) -> void:
	if not G.ctl.in_battle or V().vm.is_empty():
		return
	if mode == "drag":
		_update_drag()
		return
	if mode == "pick":
		var a := V().ally_at(p)
		V().hot("", a if drag.choices.has(a) else "")
		return
	if is_touch:
		return
	# 마우스 올림
	var uid := H().hit_test(p)
	if G.scenes.is_open() or G.dialog.guide_open():
		uid = ""
	H().set_hover(uid)
	var it := "" if uid != "" else V().intent_at(p)
	if it != V().hover_intent:
		set_intent_hover(it)


func _on_down(is_touch: bool) -> void:
	if mode == "pick":
		var a := V().ally_at(p)
		if a != "" and drag.choices.has(a):
			mode = "busy"
			set_prompt("")
			G.ctl.play_card(drag.uid, {"enemy": drag.enemy, "to": a})
		else:
			cancel_drag()
		return
	# 안내 상자가 떠 있으면 탭 = 다음 (안내가 떠 있는 동안 진행이 멈춘다)
	if G.dialog.guide_open():
		G.dialog.advance()
		return
	if G.cutin.is_active():
		G.cutin.skip()
		return
	var in_battle: bool = G.ctl.in_battle and not V().vm.is_empty() and not G.scenes.is_open()
	if not battle_ready() or G.ctl.busy or mode != "idle":
		if in_battle and mode != "drag" and G.dialog.is_busy():
			G.dialog.advance()   # 연출 중에도 빈 곳 탭 = 대사 넘김
		return
	var uid := H().hit_test(p)
	if uid == "":
		var it := V().intent_at(p)
		# 터치: 예고를 탭하면 그 공격의 대상 선을 보여 준다(같은 예고를 다시 탭하거나 다른 곳을 탭하면 사라짐)
		if is_touch:
			set_intent_hover(it if it != "" and it != V().hover_intent else "")
		if it == "" and G.dialog.is_busy():
			G.dialog.advance()
		return
	var st: Dictionary = G.ctl.st
	var d := Rules.def(st, uid)
	drag = {"uid": uid, "spec": d.target, "start": p, "moved": false, "valid": Rules.valid_targets(st, uid), "hot": ""}
	mode = "drag"
	set_intent_hover("")
	H().hover_uid = ""
	# 누르고 있는 동안은 확대해서 보여 주고(대상 없는 카드도), 끌기 시작하면 사용 조작으로
	H().lifted_uid = uid
	V().highlight(drag.valid, d.target, null)
	H().layout()


func _update_drag() -> void:
	if drag.is_empty():
		return
	if absf(p.x - drag.start.x) + absf(p.y - drag.start.y) > move_thresh():
		drag.moved = true
	if drag.spec == "none":
		if not drag.moved:
			return
		if H().drag_mode != "follow":
			H().lifted_uid = ""
			H().drag_uid = drag.uid
			H().drag_mode = "follow"
		H().drag_pos = p
		H().layout()
		return
	# 대상 카드: 끌기 시작하면 확대를 풀어 동료·적을 가리지 않게 한다(누르고 있는 동안만 확대 보기)
	if drag.moved and H().drag_mode != "aim":
		H().lifted_uid = ""
		H().drag_uid = drag.uid
		H().drag_mode = "aim"
		H().layout()
	var en := V().enemy_at(p)
	var hot_id: String = en if drag.valid.has(en) else ""
	if hot_id != drag.hot:
		drag.hot = hot_id
		V().hot(hot_id, "")


func _on_up() -> void:
	if mode != "drag":
		return
	var st: Dictionary = G.ctl.st
	var uid: String = drag.uid
	# 잠긴 죽음 카드: 끌거나 누르면 손패로 돌아가고 속마음이 뜬다
	if Rules.is_locked(st, uid):
		cancel_drag()
		G.ctl.locked_try(uid)
		return
	if not drag.moved:
		cancel_drag()
		return
	var chk := Rules.can_play(st, uid)
	var pz: float = GameData.D.layout.playZoneY
	if drag.spec == "none":
		if p.y < pz:
			if not chk.ok:
				FX.toast(G.ctl.reason_text(chk.reason))
				cancel_drag()
				return
			mode = "busy"
			G.ctl.play_card(uid, {})
		else:
			cancel_drag()
		return
	_update_drag()
	if drag.hot == "":
		var over := V().enemy_at(p)
		if not chk.ok:
			FX.toast(G.ctl.reason_text(chk.reason))
		elif over != "" or p.y < pz:
			FX.toast(G.ui("needIntent") if drag.spec == "intent" else G.ui("cantHere"))
		cancel_drag()
		return
	if not chk.ok:
		FX.toast(G.ctl.reason_text(chk.reason))
		cancel_drag()
		return
	if Rules.needs_second_target(st, uid):
		drag.enemy = drag.hot
		drag.choices = Rules.redirect_choices(st, drag.enemy)
		mode = "pick"
		H().lifted_uid = ""
		H().layout()
		V().highlight(null, "", drag.choices)
		V().hot("", "")
		set_prompt(G.ui("pickAlly"))
		return
	mode = "busy"
	G.ctl.play_card(uid, {"enemy": drag.hot})


## 카드를 손패로 되돌린다
func cancel_drag() -> void:
	mode = "idle"
	drag = {}
	set_prompt("")
	if G.view == null:
		return
	H().drag_uid = ""
	H().drag_mode = ""
	H().lifted_uid = ""
	if not V().vm.is_empty():
		V().highlight(null, "", null)
		V().hot("", "")
		H().layout()


## 사용 확정 후 정리 (카드는 연출이 처리)
func end_drag() -> void:
	mode = "idle"
	drag = {}
	set_prompt("")
	if not V().vm.is_empty():
		V().highlight(null, "", null)
		V().hot("", "")


# ───────── 화살표·예고 선 (효과 레이어에 그린다) ─────────
func draw_overlay(ci: CanvasItem) -> void:
	if not G.ctl.in_battle or V().vm.is_empty():
		return
	var pz: float = GameData.D.layout.playZoneY
	if mode == "drag" and not drag.is_empty() and drag.spec != "none":
		var from = H().top_point(drag.uid)
		if from == null:
			from = Vector2(960, 700)
		UI.arrow(ci, from, p, Color("#ffd36b") if drag.hot != "" else Color("#ff3346"), 9.0, Vector2(18, 10))
	elif mode == "drag" and not drag.is_empty() and drag.spec == "none" and drag.moved:
		var on := p.y < pz
		for i in 10:
			ci.draw_rect(Rect2(360, pz - 40 + i * 4, 1200, 4), Color(1, 0.24, 0.31, (0.35 if on else 0.12) * i / 10.0))
		var f := Assets.font("sans_bold")
		var t := G.ui("dropHere") if on else G.ui("dragUp")
		var sz := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		ci.draw_string(f, Vector2(960 - sz.x / 2.0, pz - 12), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.86, 0.86, 0.9 if on else 0.5))
	elif mode == "pick" and not drag.is_empty():
		var r = V().intent_rect(drag.enemy)
		var a: Vector2 = Vector2(r.get_center().x, r.end.y) if r != null else V().enemy_center(drag.enemy)
		UI.arrow(ci, a, p, Color("#ff3346"), 6.0, Vector2(12, 8), 40)
	elif V().hover_intent != "":
		_draw_intent_lines(ci, V().hover_intent)


func _draw_intent_lines(ci: CanvasItem, enemy_id: String) -> void:
	var it = V().vm.intents.get(enemy_id)
	var r = V().intent_rect(enemy_id)
	if it == null or r == null:
		return
	var a := Vector2(r.get_center().x, r.end.y)
	var targets := []
	if it.target == "all":
		targets.append("witch")
		for id in G.ctl.st.party.order:
			if V().vm.status.get(id) == "ok":
				targets.append(id)
	else:
		targets.append(it.target)
	for t in targets:
		UI.arrow(ci, a, V().target_point(t), Color(1, 0.24, 0.29, 0.95), 4.0, Vector2(10, 7), 40)
