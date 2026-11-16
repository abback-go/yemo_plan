## test_api.gd — 자동 시험용 훅 (웹 빌드, 주소에 ?test=1 일 때만).
## Godot 캔버스에는 DOM 이 없으므로 JavaScriptBridge 로 window.witch 에 함수를 붙인다.
## 함수의 결과는 window.__witchOut (JSON 문자열)에 남긴다 — 시험 쪽에서 W(name, ...args) 로 부르고 읽는다.
##   state() · jump(scene, opts) · play(cardId, target) · endTurn() · advance() · pickPath(id) · choose(value) · train(id)
##   openMap() · closeMap() · winBattle() · geom(kind, id) · handCut() · resetGuides() · setSpeed(n)
class_name TestApi
extends Node

var _cbs: Array = []
var _win: JavaScriptObject
var _obj: JavaScriptObject


func _ready() -> void:
	if not OS.has_feature("web") or not G.test:
		return
	_win = JavaScriptBridge.get_interface("window")
	_obj = JavaScriptBridge.create_object("Object")
	for name in ["state", "jump", "play", "endTurn", "advance", "pickPath", "choose", "train", "openMap", "closeMap", "winBattle", "geom", "handCut", "resetGuides", "setSpeed", "tapStart", "again"]:
		var cb := JavaScriptBridge.create_callback(_call.bind(name))
		_cbs.append(cb)
		_obj.set(name, cb)
	_win.witch = _obj
	_win.__witchReady = true
	_out({"ok": true})


func _out(v) -> void:
	if _win:
		_win.__witchOut = JSON.stringify(v)


func _arg(args: Array, i: int, def = null):
	if i < args.size() and args[i] != null:
		return args[i]
	return def


func _call(args: Array, name: String) -> void:
	var r = null
	match name:
		"state": r = state()
		"jump":
			var opts := {}
			var o = _arg(args, 1)
			if o is String and o != "":
				opts = JSON.parse_string(o)
			G.ctl.jump(str(_arg(args, 0, "title")), opts)
			r = {"ok": true}
		"play":
			r = play(str(_arg(args, 0, "")), str(_arg(args, 1, "")))
		"endTurn":
			G.ctl.end_turn()
			r = {"ok": true}
		"advance":
			r = advance()
		"pickPath":
			var e = G.scenes.current
			if e is ExploreScene:
				e.pick(str(_arg(args, 0, "")))
				r = {"ok": true}
			else:
				r = {"ok": false}
		"choose":
			var v = G.scenes.current
			r = {"ok": v is VnScene and v.pick_choice(str(_arg(args, 0, "")))}
		"train":
			r = {"ok": false}
			var cur = G.scenes.current
			if cur is VnScene:
				for c in cur.get_children():
					if c is VnScene.TrainPicker:
						r = {"ok": c.pick(str(_arg(args, 0, "")))}
		"openMap":
			var e2 = G.scenes.current
			if e2 is ExploreScene:
				e2.open_map(false)
			r = {"ok": e2 is ExploreScene}
		"closeMap":
			var e3 = G.scenes.current
			if e3 is ExploreScene and e3.map.visible:
				e3.map.close()
			r = {"ok": true}
		"winBattle":
			r = win_battle()
		"geom":
			r = geom(str(_arg(args, 0, "")), str(_arg(args, 1, "")))
		"handCut":
			r = hand_cut(_arg(args, 0, "[]"))
		"resetGuides":
			G.dialog.reset_seen()
			r = {"ok": true}
		"setSpeed":
			FX.speed = maxf(0.1, float(_arg(args, 0, 1)))
			r = {"ok": true}
	_out(r)


func state() -> Dictionary:
	var c = G.ctl
	var st: Dictionary = c.st
	var s := {
		"stage": c.stage, "scene": G.scenes.current_name, "inBattle": c.in_battle, "busy": c.busy,
		"guideOpen": G.dialog.guide_open(), "dialogBusy": G.dialog.is_busy(), "fade": FX.fade_rect.modulate.a if FX.fade_rect else 0.0,
		"maxHands": G.view.hand.max_hands, "handsNow": G.view.hand.hands_visible(),
		"raiseLog": G.view.hand.raise_log, "cutinLog": G.cutin.log, "motionLog": G.view.motion_log, "cutLog": G.scenes.cut_log,
		"dialog": G.dialog.log.slice(maxi(0, G.dialog.log.size() - 30)), "log": c.log.slice(maxi(0, c.log.size() - 40)),
		"cssScale": FX.css_scale, "ui": FX.ui, "small": FX.small, "cardPreview": FX.card_preview, "fps": Engine.get_frames_per_second(),
		"cutinActive": G.cutin.is_active(),
		"handLifted": G.view.hand.lifted_uid, "handDragMode": G.view.hand.drag_mode,
		"handGrip": G.view.hand.grip.get("uid", ""), "handGripBox": _grip_box(), "handRightOut": G.view.hand.right_out,
	}
	if st.is_empty():
		return s
	s.flags = st.flags
	s.progress = st.progress
	s.party = {"witch": st.party.witch, "allies": st.party.allies, "deck": st.party.deck.size(), "deathCards": st.party.get("deathCards", []).size()}
	var b = st.battle
	if b != null:
		var hand := []
		for u in b.hand:
			hand.append({"uid": u, "id": st.cards[u].id, "locked": Rules.is_locked(st, u), "playable": Rules.can_play(st, u).ok, "up": Rules.is_up(st, u)})
		var ens := []
		for e in b.enemies:
			ens.append({"id": e.id, "hp": e.hp, "alive": e.alive, "intent": e.intent})
		s.battle = {"enc": b.enc, "kind": b.kind, "turn": b.turn, "phase": b.phase, "result": b.result, "energy": b.energy, "hand": hand, "enemies": ens,
			"shadow": G.view.shadow_v, "footZ": G.view.layers.foot.z_index, "alliesZ": G.view.layers.allies.z_index}
	var cur = G.scenes.current
	if cur is ExploreScene:
		s.explore = {"place": cur.place, "selected": cur.selected, "map": cur.map.visible, "walking": cur.walking, "paths": cur.path_list().map(func(p): return p.id)}
	if cur is VnScene:
		s.vn = {"name": cur.scene_name, "line": cur.line_index, "choices": cur.choice_btns.size(), "omen": cur.omen.showing, "typing": cur.typing}
	return s


func play(card_id: String, target_json: String) -> Dictionary:
	var st: Dictionary = G.ctl.st
	if st.is_empty() or st.battle == null:
		return {"ok": false, "reason": "no battle"}
	var uid := ""
	for u in st.battle.hand:
		if st.cards[u].id == card_id:
			uid = u
			break
	if uid == "":
		return {"ok": false, "reason": "not in hand"}
	var t := {}
	if target_json != "":
		t = JSON.parse_string(target_json)
	if Rules.is_locked(st, uid):
		G.ctl.locked_try(uid)
		return {"ok": false, "reason": "locked"}
	G.ctl.play_card(uid, t)
	return {"ok": true}


func advance() -> Dictionary:
	if G.dialog.guide_open() or G.dialog.is_busy():
		G.dialog.advance()
		return {"ok": true, "what": "dialog"}
	var cur = G.scenes.current
	if cur is VnScene:
		cur.tap()
		return {"ok": true, "what": "vn"}
	if cur is Control and G.scenes.current_name == "cutscene" and not G.scenes.cut.is_empty() and G.scenes.cut.get("waiter") != null:
		G.scenes.cut.waiter.finish()
		return {"ok": true, "what": "cut"}
	if G.cutin.is_active():
		G.cutin.skip()
		return {"ok": true, "what": "cutin"}
	return {"ok": false}


func win_battle() -> Dictionary:
	var st: Dictionary = G.ctl.st
	if st.is_empty() or st.battle == null or G.ctl.busy:
		return {"ok": false}
	G.ctl.busy = true
	var ev := Rules.debug_win(st)
	_play_then_result(ev)
	return {"ok": true}


func _play_then_result(ev: Array) -> void:
	await G.view.play_events(ev)
	G.ctl.result_ready = true


## 화면 좌표(무대 1920×1080) — 실제 터치·드래그 시험용
func geom(kind: String, id: String) -> Dictionary:
	var v: BattleView = G.view
	match kind:
		"card":
			var st: Dictionary = G.ctl.st
			for u in v.hand.cards:
				if st.cards.has(u) and (st.cards[u].id == id or u == id):
					var c: CardView = v.hand.cards[u]
					return {"x": c.center().x, "y": c.center().y, "quad": Array(c.target).map(func(p): return [p.x, p.y])}
		"enemy":
			var p := v.enemy_center(id)
			return {"x": p.x, "y": p.y}
		"intent":
			var r = v.intent_rect(id)
			if r != null:
				return {"x": r.get_center().x, "y": r.get_center().y}
		"ally":
			var a := v.target_point(id)
			return {"x": a.x, "y": a.y}
		"endTurn":
			var e := Rect2(v.end_btn.position, v.end_btn.size)
			return {"x": e.get_center().x, "y": e.get_center().y}
		"path":
			var cur = G.scenes.current
			if cur is ExploreScene:
				for pa in cur.path_list():
					if pa.id == id:
						return {"x": pa.x, "y": pa.y}
		"button":
			var cur2 = G.scenes.current
			if cur2:
				var n = cur2.find_child(id, true, false)
				if n is Control:
					var gr: Rect2 = n.get_global_rect()
					return {"x": gr.get_center().x, "y": gr.get_center().y}
				if cur2 is VnScene:
					for b in cur2.choice_btns:
						if str(b.get_meta("value", "")) == id:
							var r2: Rect2 = b.get_global_rect()
							return {"x": r2.get_center().x, "y": r2.get_center().y}
	return {}


## 손 그림의 잘린 자리(원본 좌표 목록)가 카드·뒷면 카드로 덮였는지 → 덮이지 않은 점
func hand_cut(pts_json) -> Dictionary:
	var pts = JSON.parse_string(str(pts_json))
	if not pts is Array:
		pts = []
	return {"uncovered": G.view.hand.uncovered(pts), "hands": G.view.hand.hands_visible()}


## 시험용: 작은 오른손이 쥔 카드의 화면 사각형 [x0, y0, x1, y1] (쥔 카드가 없으면 [])
func _grip_box() -> Array:
	var h: HandView = G.view.hand
	if h.grip.is_empty() or not is_instance_valid(h.grip.card):
		return []
	var r := Rect2(h.rig.transform * h.grip.card.corners[0], Vector2.ZERO)
	for p in h.grip.card.corners:
		r = r.expand(h.rig.transform * p)
	return [r.position.x, r.position.y, r.end.x, r.end.y]
