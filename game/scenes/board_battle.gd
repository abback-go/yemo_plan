## board_battle.gd — 전투 시험판 v2.1 「3D 탁자」 화면·조작·연출 (docs/battle-v2-spec.md 9장). 주소 ?battle=v2(헤드리스 --battle=v2)일 때만 main.gd 가 연다.
## 3D(ui/board_table.gd): 돌판 탁자 위 같은 크기 카드 3열 × 4줄 — ① 적 ② 적 행동(노리는 칸 위) ③ 맡긴 카드 ④ 동료. 한 칸에 여러 장이면 옆으로 겹친다(A안 —
##   맨 앞 카드는 전부, 뒤 카드는 왼쪽 띠만. 장수가 늘면 간격을 좁히고, 마우스를 올리거나 길게 누르면 펼친다). 적 행동이 겹치면 위에 합계 피해.
##   오른쪽 위 = 적 덱(행동 카드가 여기서 나와 뒤집힌다)·설명, 오른쪽 아래 = 대기 동료(벤치) — 지시서 9-4.
## 2D(겹침): 왼쪽 아래 편 왼손 위에 뜬 손패, 오른쪽 아래 오른손(평소·집기·가리키기) — ui/board_hand.gd. 덱·노엘 HP·행동 에너지·「턴 끝」, 크게 보기, 결과 판.
## 흐름: 출전 배치(동료 카드를 칸·벤치로 끌기 — 공짜) → 「출전」 → 내 턴(카드를 끌어 놓기 · 동료 카드를 끌어 자리 바꾸기·빼기·넣기 = 에너지 1) → 「턴 끝」 → 적 턴(한꺼번에) → …
## 조작(마우스·터치 같음): 손패의 카드를 끌어 탁자의 칸에 놓는다(화면 좌표 → 탁자 평면 교차로 칸을 찾는다) → 공격 카드는 적 카드를 누른다.
##   노엘의 카드는 칸이 없다 — 운명 전가·저주는 ② 적 행동 카드에, 운명 찢기는 죽음 카드에, 취약은 ① 적에, 축복은 ④ 동료에 직접 놓는다.
##   운명 전가는 놓은 뒤 그 적 행동 카드를 다른 칸으로 끌거나(또는 칸을 누름) 옮긴다. 놓은 카드(③·노엘 카드)를 누르면 손패로(에너지 돌려받음).
## 규칙은 core/rules_v2.gd, 수치·문구는 data/battle_v2_data.gd. 자동 진행(--autoplay)은 RulesV2.auto_step 을 한 수씩 화면 조작과 같은 길로 낸다.
## 시험 훅: core/test_api.gd 의 witch.v2(…) → test_call
class_name BoardBattle
extends Control

static var current: BoardBattle = null

var st := {}
var mode := "busy"        # formation | idle | drag | pick | shift | move | busy | over
var table: BoardTable
var hand: BoardHand
var hud: Control
var overlay: Control
var zoom: Control
var end_btn: Btn
var start_btn: Btn
var turn_label: Label
var hint_label: Label
var result_panel: Control
var pending := {}         # 놓았지만 대상·옮길 칸을 아직 안 고른 카드 {uid, kind: attack|shift, ally, target}
var drag := {}            # 손패에서 끄는 카드 {uid, start, moved, hot, col, reason}
var mdrag := {}           # 탁자에서 끄는 카드 {kind: ally|act, id, key, start, moved}
var tap := {}             # 누른 탁자 카드 {key, start, t}
var hover_key := ""       # 크게 보기 할 탁자 카드
var spread_cell := ""     # 펼친 칸 ("r:c" · "bench")
var touch := false
var preview_text := ""
var preview_pos := Vector2.ZERO
var prompt_text := ""
var _cell_of := {}        # 카드 key → 칸 id
var _hidden: Array = []
var _hand_snap = null      # 턴 끝 연출 동안 보이는 손패(상태는 이미 정리됨) — 정리 연출에서 버린다
var _shown_energy := 0
var _noel_shake := 0.0
var _auto_t := 0.0
var _auto_busy := false
var _zoom_face := {}
var _zoom_left := true
var log: Array = []


# ───────── 열기 ─────────
static func open(parent: Node, seed = null) -> BoardBattle:
	var b := BoardBattle.new()
	parent.add_child(b)
	b.start(seed)
	return b


static func D() -> Dictionary:
	return BattleV2Data.D


func L() -> Dictionary:
	return D().layout


func TL() -> Dictionary:
	return D().table3d


func T(key: String, args := {}) -> String:
	var s := str(D().text.get(key, key))
	for k in args:
		s = s.replace("{" + str(k) + "}", str(args[k]))
	return s


func note(s: String) -> void:
	log.append(s)
	if log.size() > 200:
		log.pop_front()
	G.ctl.note("v2 " + s)


func start(seed) -> void:
	current = self
	position = Vector2.ZERO
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	st = RulesV2.new_battle(seed)
	_build()
	note("battle seed=%d" % int(st.seed))
	mode = "formation"
	_sync_table(false)
	_sync_hud()
	await FX.fade(0, 400)
	if not is_inside_tree():
		return
	FX.banner(T("formation"), 900)


# ───────── 화면 만들기 ─────────
func _build() -> void:
	table = BoardTable.new()
	table.name = "table"
	add_child(table)
	table.setup()
	# 탁자 가장자리를 어둡게(2D 그라디언트 — 후처리 없이)
	add_child(UI.tex_rect(UI.grad([[0, Color(0, 0, 0, 0)], [0.62, Color(0.02, 0, 0.01, 0.25)], [1, Color(0, 0, 0, 0.75)]], "radial", 256, 256, Vector2(0.5, 0.45), 0.78), Rect2(0, 0, 1920, 1080)))
	var T3 := TL()
	table.label("bench", T("bench"), Vector3(float(T3.bench.x), 0, float(T3.bench.z) + 0.95), 64)
	table.label("deck", T("enemyDeck"), Vector3(float(T3.enemyDeck.x), 0.08, float(T3.enemyDeck.z)), 64, Color(0.95, 0.85, 0.8, 0.9), 40)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.size = size
	hud.draw.connect(_draw_hud)
	add_child(hud)
	turn_label = UI.label("", 30, Color("#efe3e5"), "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, 5)
	turn_label.position = Vector2(26, 12)
	add_child(turn_label)
	hint_label = UI.label("", 17, Color("#b9aca6"), "sans", HORIZONTAL_ALIGNMENT_LEFT, 3)
	hint_label.position = Vector2(26, 56)
	hint_label.size = Vector2(620, 60)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint_label)
	hand = BoardHand.new()
	hand.board = self
	hand.name = "hand"
	add_child(hand)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.size = size
	overlay.z_index = 220
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	zoom = Control.new()
	zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom.size = size
	zoom.z_index = 240
	zoom.draw.connect(_draw_zoom)
	add_child(zoom)
	# 「턴 끝」·「출전」은 맨 뒤에 붙인다(누르기는 나무 순서 — 뒤에 붙인 것이 먼저)
	end_btn = UI.button(T("endTurn"), 34, _on_end)
	end_btn.name = "endTurn"
	end_btn.fit(Vector2(58, 18))
	end_btn.position = Vector2(float(L().endTurn.x), float(L().endTurn.y))
	end_btn.visible = false
	add_child(end_btn)
	start_btn = UI.button(T("start"), 36, _on_start)
	start_btn.name = "start"
	start_btn.fit(Vector2(70, 18))
	start_btn.position = Vector2(float(L().start.x), float(L().start.y))
	add_child(start_btn)


# ───────── 탁자 자리 ─────────
func cell_pos(row: int, col: int) -> Vector3:
	return Vector3(float(TL().cols[col]), 0, float(TL().rows[row]))


func bench_pos(i: int) -> Vector3:
	var B: Dictionary = TL().bench
	return Vector3(float(B.x), 0, float(B.z) + i * float(B.dz))


func deck_pos(i := 0) -> Vector3:
	var Dk: Dictionary = TL().enemyDeck
	return Vector3(float(Dk.x) + sin(i * 2.3) * 0.02, 0.004 + i * 0.012, float(Dk.z) + cos(i * 1.7) * 0.02)


## 화면 점 아래의 탁자 자리: {col, row} · {bench: true} · {}
func zone_at(p: Vector2) -> Dictionary:
	var g = table.ground(p)
	if g == null:
		return {}
	var T3 := TL()
	var rows: Array = T3.rows
	var ch: float = T3.card[1]
	var pad := 0.25 if touch else 0.08
	var B: Dictionary = T3.bench
	if absf(g.x - float(B.x)) <= 0.75 + pad and g.z <= float(B.z) + ch / 2.0 + pad and g.z >= float(B.z) + 2 * float(B.dz) - ch / 2.0 - pad:
		return {"bench": true}
	if g.z < float(rows[0]) - ch / 2.0 - pad or g.z > float(rows[rows.size() - 1]) + ch / 2.0 + pad:
		return {}
	for c in T3.cols.size():
		if absf(g.x - float(T3.cols[c])) <= float(T3.cellW) / 2.0 + pad:
			var best := 0
			for r in rows.size():
				if absf(g.z - float(rows[r])) < absf(g.z - float(rows[best])):
					best = r
			return {"col": c, "row": best}
	return {}


func col_at(p: Vector2) -> int:
	var z := zone_at(p)
	return int(z.col) if z.has("col") else -1


func deck_center() -> Vector2:
	var Dk: Dictionary = L().deck
	return Vector2(float(Dk.x) + float(Dk.w) / 2.0, float(Dk.y) + float(Dk.h) / 2.0)


func noel_center() -> Vector2:
	return Vector2(float(L().noel.x), float(L().noel.y))


func _pad() -> float:
	return minf(40.0, 16.0 / maxf(0.05, FX.css_scale)) if touch else 0.0


# ───────── 카드 앞면 자료 ─────────
func face_enemy(e: Dictionary) -> Dictionary:
	var minion := RulesV2.is_minion(e)
	var nm := str(D().enemies[e.type].name) + (" " + str(e.tag) if str(e.tag) != "" else "")
	return {"kind": "minion" if minion else "enemy", "type": e.type, "name": nm, "hp": int(e.hp), "maxHp": int(e.maxHp)}


func face_act(e: Dictionary) -> Dictionary:
	var it: Dictionary = e.intent
	var sweep: bool = it.kind == "sweep"
	return {"kind": "act", "type": e.type, "tag": str(e.tag), "name": str(it.label) + (" · " + T("all") if sweep else ""), "value": int(it.value),
		"minus": int(it.get("minus", 0)), "minion": RulesV2.is_minion(e), "sub": T("all") if sweep else ""}


func face_death(d: Dictionary) -> Dictionary:
	return {"kind": "death", "name": str(d.label), "art": str(D().death.art.get(d.ally, "")), "text": T("deathMark")}


func face_mine(uid: String, fc := {}) -> Dictionary:
	var d: Dictionary = RulesV2.card_def(st, uid)
	var f := {"kind": "mine", "name": str(d.name), "cost": int(d.cost), "owner": str(d.owner), "art": str(d.art), "dark": bool(d.get("dark", false)),
		"text": str(d.text).replace("{n}", str(int(d.get("damage", d.get("block", 0)))))}
	if fc.has(uid):
		var r: Dictionary = fc[uid]
		match str(d.kind):
			"attack", "release":
				f.result = T("damage", {"n": int(r.get("dmg", 0))})
			"block":
				f.result = T("block", {"n": int(r.get("block", 0))})
			"aim":
				f.result = T("multTo", {"n": int(r.get("mult", 1))})
		if r.has("target"):
			var te = RulesV2.enemy(st, str(r.target))
			if te != null:
				f.target_type = str(te.type)
				f.target_tag = str(te.tag)
	return f


func face_ally(id: String) -> Dictionary:
	var a: Dictionary = st.allies[id]
	var tr: Dictionary = D().traits[a.trait]
	if a.dead:
		return {"kind": "dead", "name": G.name_of(id), "art": str(D().portraits[id].img), "deadText": T("dead")}
	var f := {"kind": "ally", "name": G.name_of(id), "art": str(D().portraits[id].img), "hp": int(a.hp), "maxHp": int(a.maxHp), "block": int(a.block),
		"trait": str(tr.name), "text": str(tr.text).replace("\n", " "), "down": bool(a.down), "downText": T("down")}
	match str(a.trait):
		"brace":
			f.statusLabel = T("brace")
			f.statusValue = str(a.brace)
		"aim":
			f.statusLabel = T("mult")
			f.statusValue = "×" + str(a.mult)
	return f


# ───────── 상태 → 탁자 (자리·앞면) ─────────
## key → {pos, prio, face, flip, lift, glow, gcol, pick, wobble}. 칸마다 카드 목록(뒤 → 앞)을 만들어 옆으로 겹쳐 놓는다
func _layout() -> Dictionary:
	var out := {}
	_cell_of = {}
	var fc := RulesV2.forecast(st)
	var ncol := RulesV2.ncols()
	# ① 적: 강적 → 하수인(앞) · 취약 카드
	for c in ncol:
		var pile := []
		for e in st.enemies:
			if RulesV2.is_minion(e) or int(e.col) != c:
				continue
			pile.append({"key": "e:" + e.id, "face": face_enemy(e), "flip": 0.0 if e.alive else 1.0, "pick": e.alive})
			_noel_on(pile, e.id, "vuln")
			var gi = e.intent if e.alive else null
			for m in st.enemies:
				if str(m.of) == e.id and m.alive:
					pile.append({"key": "e:" + m.id, "face": face_enemy(m), "flip": 0.0, "pick": true})
					_noel_on(pile, m.id, "vuln")
			if gi != null and gi.kind == "summon":
				var mt := str(D().enemies[e.type].get("minion", ""))
				var gf := {"kind": "minion", "type": mt, "name": str(gi.label), "hp": int(D().enemies[mt].hp) if mt != "" else 0, "maxHp": int(D().enemies[mt].hp) if mt != "" else 0,
					"summon": true, "summonText": T("summonNext")}
				pile.append({"key": "g:" + e.id, "face": gf, "flip": 0.0, "pick": true, "alpha": 0.55})
		_place_pile(out, pile, cell_pos(0, c), "0:%d" % c, 10)
	# ② 적 행동: 그 칸을 노린 한 명 공격 · '모두'의 한 장 · 그 칸 동료의 죽음 카드 (+ 그 위의 노엘 카드)
	for c in ncol:
		var pile2 := []
		for e in st.enemies:
			if not e.alive or e.intent == null:
				continue
			if e.intent.kind == "hit" and int(e.intent.slot) == c:
				pile2.append({"key": "a:" + e.id, "face": face_act(e), "flip": 0.0, "pick": true})
				_noel_on(pile2, e.id, "act")
			elif e.intent.kind == "sweep":
				pile2.append({"key": "a:%s#%d" % [e.id, c], "face": face_act(e), "flip": 0.0, "pick": true})
				if c == 0:
					_noel_on(pile2, e.id, "act")
		for dd in st.deaths:
			if RulesV2.col_of(st, dd.ally) == c:
				pile2.append({"key": "d:" + dd.id, "face": face_death(dd), "flip": 0.0, "pick": true, "glow": 0.9, "gcol": Color(1, 0.1, 0.16), "death": true})
				_noel_on(pile2, dd.id, "act")
		_place_pile(out, pile2, cell_pos(1, c), "1:%d" % c, 30)
	# ③ 맡긴 카드 · ④ 동료(축복 카드) — 빈칸이면 점선 표시
	for c in ncol:
		var id := RulesV2.ally_at(st, c)
		var pile3 := []
		var pile4 := []
		if id != "":
			for p in st.allies[id].placed:
				pile3.append({"key": "p:" + p.uid, "face": face_mine(p.uid, fc), "flip": 0.0, "pick": true})
			if not pending.is_empty() and pending.kind == "attack" and pending.ally == id:
				pile3.append({"key": "p:" + pending.uid, "face": face_mine(pending.uid), "flip": 0.0, "pick": false, "glow": 1.0, "gcol": Color(1, 0.3, 0.36)})
			var targeted := RulesV2.is_targeted(st, id)
			pile4.append({"key": "ally:" + id, "face": face_ally(id), "flip": 0.0, "pick": true, "wobble": 1.0 if targeted and mode != "formation" else 0.0,
				"glow": 0.75 if targeted and mode != "formation" else 0.0, "gcol": Color(1, 0.16, 0.22)})
			_noel_on(pile4, id, "bless")
		else:
			pile4.append({"key": "slot:%d" % c, "face": {"kind": "slot", "text": T("emptySlot")}, "flip": 0.0, "pick": false})
		_place_pile(out, pile3, cell_pos(2, c), "2:%d" % c, 50)
		_place_pile(out, pile4, cell_pos(3, c), "3:%d" % c, 70)
	# 벤치(오른쪽 아래): 앞 카드부터, 기다리는 죽음 카드는 그 동료 카드 왼쪽에 겹침
	for i in st.bench.size():
		var bid: String = st.bench[i]
		var bp := bench_pos(i)
		var sp := spread_cell == "bench"
		if sp:
			bp.z = float(TL().bench.z) + i * float(TL().bench.dz) * 2.6
		out["ally:" + bid] = {"pos": bp + Vector3(0, 0.004 + (0.06 if sp else 0.0), 0), "prio": 90 - i * 4, "face": face_ally(bid), "flip": 0.0, "pick": true}
		_cell_of["ally:" + bid] = "bench"
		for dd in st.deaths:
			if dd.ally == bid:
				out["d:" + dd.id] = {"pos": bp + Vector3(-0.42, 0.012, -0.12), "prio": 91 - i * 4, "face": face_death(dd), "flip": 0.0, "pick": true, "glow": 0.9, "gcol": Color(1, 0.1, 0.16)}
				_cell_of["d:" + dd.id] = "bench"
				for n in st.noel:
					if n.target == dd.id:
						out["n:" + n.uid] = {"pos": bp + Vector3(-0.2, 0.02, -0.05), "prio": 92 - i * 4, "face": face_mine(n.uid), "flip": 0.0, "pick": true}
	if not pending.is_empty() and pending.kind == "shift" and not out.has("n:" + pending.uid):
		var tk := _target_key(str(pending.target))
		if out.has(tk):
			out["n:" + pending.uid] = {"pos": out[tk].pos + Vector3(0.38, 0.02, 0), "prio": int(out[tk].prio) + 1, "face": face_mine(pending.uid), "flip": 0.0, "pick": false, "glow": 1.0, "gcol": Color(1, 0.3, 0.36)}
	# 적 덱 · 설명 (오른쪽 위)
	for i in 4:
		out["deck:%d" % i] = {"pos": deck_pos(i), "prio": 5 + i, "face": {"kind": "slot", "text": ""}, "flip": 1.0, "pick": false, "back": true}
	out["note"] = {"pos": Vector3(float(TL().note.x), 0.004, float(TL().note.z)), "prio": 6, "face": {"kind": "note", "name": "설명", "text": T("note")}, "flip": 0.0, "pick": true}
	return out


## 노엘이 그 대상에 놓은 카드를 같은 더미에 (pending 운명 전가 포함)
func _noel_on(pile: Array, target: String, what: String) -> void:
	for n in st.noel:
		if str(n.target) != target:
			continue
		var k := str(n.kind)
		if (what == "vuln" and k == "vuln") or (what == "bless" and k == "bless") or (what == "act" and k in ["curse", "shift", "tear"]):
			pile.append({"key": "n:" + n.uid, "face": face_mine(n.uid), "flip": 0.0, "pick": true})
	if what == "act" and not pending.is_empty() and pending.kind == "shift" and str(pending.target) == target:
		pile.append({"key": "n:" + pending.uid, "face": face_mine(pending.uid), "flip": 0.0, "pick": false, "glow": 1.0, "gcol": Color(1, 0.3, 0.36)})


func _target_key(target: String) -> String:
	if RulesV2.death(st, target) != null:
		return "d:" + target
	var e = RulesV2.enemy(st, target)
	if e != null and e.intent != null and e.intent.kind == "sweep":
		return "a:%s#0" % target
	return "a:" + target


## 한 칸에 여러 장: 옆으로 겹친다(A안). 칸 너비를 넘으면 간격을 좁히고, 펼친 칸은 넓게
func _place_pile(out: Dictionary, pile: Array, center: Vector3, cell: String, base: int) -> void:
	var n := pile.size()
	if n == 0:
		return
	var cw: float = TL().card[0]
	var sp := spread_cell == cell and n > 1
	var dx := float(TL().pileDx)
	if n > 1:
		dx = minf(dx, (float(TL().cellW) - cw) / (n - 1))
	if sp:
		dx = float(TL().spreadDx)
	var x0 := center.x - (cw + (n - 1) * dx) / 2.0 + cw / 2.0
	for i in n:
		var e: Dictionary = pile[i]
		var w := e.duplicate()
		w.pos = Vector3(x0 + i * dx, 0.004 + i * 0.008 + (0.07 if sp else 0.0), center.z)
		w.prio = base + i * 2 + (12 if sp else 0)
		out[e.key] = w
		_cell_of[e.key] = cell


## 탁자 카드를 상태에 맞춘다. 새 카드는 떨어지고(animate), 없어진 카드는 밀려나 사라진다
func _sync_table(animate := true) -> void:
	var want := _layout()
	for key in want:
		var w: Dictionary = want[key]
		var c: BoardTable.Card3D = table.card(key)
		var fresh := c == null
		if fresh:
			c = table.make_card(key, w.face, w.pos)
			c.flip = float(w.flip)
			c.tflip = float(w.flip)
			if w.get("back", false):
				c.set_back(table.back_tex, Color(0.62, 0.32, 0.34))
		elif c.face != w.face:
			c.set_face(w.face)
		if mdrag.get("key", "") == key and mdrag.get("moved", false):
			c.set_prio(120)
		else:
			c.tpos = w.pos
			c.set_prio(int(w.prio))
			c.tlift = 0.0
			c.ttilt = 0.0
		if not c.pinned:
			c.tflip = float(w.flip)
		c.pickable = bool(w.get("pick", true))
		c.wobble = float(w.get("wobble", 0.0))
		c.set_glow(float(w.get("glow", 0.0)), w.get("gcol", Color(1, 0.78, 0.38)))
		c.set_alpha(float(w.get("alpha", 1.0)))
		if fresh and animate:
			c.drop_in()
	for key in table.cards.keys():
		if not want.has(key):
			if animate:
				table.push_out(key)
			else:
				table.remove_card(key)


## 앞면만 다시(연출 중 숫자 바뀜)
func _refresh_faces() -> void:
	var want := _layout()
	for key in want:
		var c: BoardTable.Card3D = table.card(key)
		if c != null and c.face != want[key].face:
			c.set_face(want[key].face)


func _sync_hud() -> void:
	_shown_energy = int(st.energy) - (int(RulesV2.card_def(st, pending.uid).cost) if not pending.is_empty() else 0)
	turn_label.text = T("formation") if st.phase == "formation" else T("turn", {"n": st.turn})
	hint_label.text = T("formationHint") if st.phase == "formation" else (T("hintTouch") if FX.touch else T("hint"))
	end_btn.visible = st.phase == "battle" and st.result == null
	start_btn.visible = st.phase == "formation"
	end_btn.disabled = mode != "idle" or st.result != null
	start_btn.disabled = mode != "formation"
	end_btn.queue_redraw()
	start_btn.queue_redraw()
	hud.queue_redraw()
	overlay.queue_redraw()
	hand.update_classes(st, mode != "idle" and mode != "drag")


func _set_idle() -> void:
	if not is_inside_tree() or st.result != null:
		return
	mode = "idle" if st.phase == "battle" else "formation"
	hand.point_at = null
	_sync_table()
	_sync_hud()
	hand.layout()


func hand_list() -> Array:
	var out: Array = st.hand.duplicate() if _hand_snap == null else _hand_snap.duplicate()
	for u in _hidden:
		out.erase(u)
	if not pending.is_empty():
		out.erase(pending.uid)
	return out


func _toast_reason(r: String) -> void:
	FX.toast(str(D().reasons.get(r, r)))


# ───────── 2D 그리기 ─────────
func _draw_hud() -> void:
	if st.is_empty():
		return
	# 덱: 뒷면 카드 몇 장 + 「덱 n」
	var Dk: Dictionary = L().deck
	var back := BoardPieces.tex(str(GameData.D.cardBackImg))
	var n: int = st.draw.size()
	for i in mini(3, maxi(1, n)):
		var r := Rect2(float(Dk.x) - i * 4, float(Dk.y) - i * 5, float(Dk.w), float(Dk.h))
		if back != null:
			hud.draw_texture_rect(back, r, false, Color(0.85, 0.8, 0.82, 1.0 if n > 0 else 0.35))
	BoardPieces.text_in(hud, Rect2(float(Dk.x) - 30, float(Dk.y) + float(Dk.h) + 2, float(Dk.w) + 60, 30), T("deck", {"n": n}), 22, Color("#efe3e5"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
	# 노엘 HP: 붉은 봉인 (빈칸 공격을 맞으면 흔들림)
	var nc := noel_center() + Vector2(sin(_noel_shake * 40.0) * 10.0 * _noel_shake, 0)
	BoardPieces.text_in(hud, Rect2(nc.x - 90, nc.y - 92, 180, 30), T("noel"), 24, Color("#f3dcec"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
	BoardPieces.seal(hud, nc, 44, Color("#8e1220") if int(st.noelHp) > 5 else Color("#c0121f"), str(st.noelHp), 36, "/" + str(st.noelMax))
	if st.phase != "battle":
		return
	# 행동 에너지: 붉은 보석
	var En: Dictionary = L().energy
	BoardPieces.text_in(hud, Rect2(float(En.x) - 10, float(En.y) - 4, 240, 28), T("energy"), 20, Color("#e8d4d6"), "sans_bold", HORIZONTAL_ALIGNMENT_LEFT, 4)
	var total := int(D().rules.energy)
	for i in total:
		var c := Vector2(float(En.x) + 22 + i * 58, float(En.y) + 66)
		var on := i < _shown_energy
		var gem := PackedVector2Array([c + Vector2(0, -26), c + Vector2(20, -6), c + Vector2(0, 26), c + Vector2(-20, -6)])
		hud.draw_colored_polygon(gem, Color("#c2101f") if on else Color("#2a1416"))
		var loop := gem.duplicate()
		loop.append(gem[0])
		hud.draw_polyline(loop, Color("#ff8a94") if on else Color("#5a3438"), 2.5, true)
		if on:
			hud.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -22), c + Vector2(12, -6), c + Vector2(0, -2), c + Vector2(-8, -8)]), Color(1, 0.75, 0.78, 0.55))


func _draw_overlay() -> void:
	if st.is_empty():
		return
	# ② 적 행동이 겹치면 합계 피해 · 빈칸을 노리면 「노엘」
	if st.phase == "battle" and mode != "over":
		var ch: float = TL().card[1]
		for c in RulesV2.ncols():
			var ids := RulesV2.intents_at(st, c)
			var sw = RulesV2.sweep_enemy(st)
			var cnt := ids.size() + (1 if sw != null else 0)
			var inc := RulesV2.incoming(st, c)
			var noel := RulesV2.receiver(st, c) == "noel" and inc > 0
			if cnt < 2 and not noel:
				continue
			var top := table.to_screen(cell_pos(1, c) + Vector3(0, 0, -ch / 2.0 - 0.06))
			var txt := T("total", {"n": inc}) if cnt >= 2 else ""
			if noel:
				txt = (txt + " → " if txt != "" else "→ ") + T("toNoel") + " " + str(inc)
			var f := Assets.font("sans_bold")
			var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22) + Vector2(24, 10)
			var r := Rect2(top - Vector2(sz.x / 2.0, sz.y + 2), sz)
			overlay.draw_style_box(UI.box(Color(0.1, 0.0, 0.02, 0.92), Color("#ff4b5a") if noel else Color("#a8323e"), 8, 2), r)
			BoardPieces.text_in(overlay, r, txt, 22, Color("#ffd9dc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
	if preview_text != "":
		var f2 := Assets.font("sans_bold")
		var sz2 := f2.get_string_size(preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26) + Vector2(32, 14)
		var r2 := Rect2(preview_pos - Vector2(sz2.x / 2.0, sz2.y), sz2)
		overlay.draw_style_box(UI.box(Color(0.06, 0.03, 0.02, 0.94), BoardPieces.GOLD, 10, 2), r2)
		BoardPieces.text_in(overlay, r2, preview_text, 26, Color("#ffdf8a"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
	if prompt_text != "":
		var f3 := Assets.font("sans_bold")
		var sz3 := f3.get_string_size(prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26) + Vector2(48, 18)
		var r3 := Rect2(Vector2(960 - sz3.x / 2.0, 866), sz3)
		overlay.draw_style_box(UI.box(Color(0.04, 0, 0.016, 0.92), UI.RED, 20, 2), r3)
		BoardPieces.text_in(overlay, r3, prompt_text, 26, Color("#ffd9dc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
	# 운명 전가로 끄는 ② 카드에서 옮길 칸까지
	if not mdrag.is_empty() and mdrag.kind == "act" and mdrag.moved:
		var tk := _target_key(str(pending.get("target", "")))
		var c3: BoardTable.Card3D = table.card(tk)
		if c3 != null:
			UI.arrow(overlay, table.to_screen(c3.position), get_local_mouse_position(), Color("#ffd36b"), 5.0, Vector2(12, 8), 30)


## 크게 보기: 탁자 카드에 마우스를 올리거나(터치는 길게 누르면) 그 카드를 크게
func _draw_zoom() -> void:
	if _zoom_face.is_empty():
		return
	var Z: Dictionary = L().zoom
	var w := float(Z.w)
	var h := w * 1.5
	var x := float(Z.margin) if _zoom_left else 1920.0 - float(Z.margin) - w
	var r := Rect2(x, float(Z.y), w, h)
	zoom.draw_style_box(UI.box(Color(0, 0, 0, 0.55), Color.TRANSPARENT, 18), Rect2(r.position + Vector2(6, 12), r.size))
	BoardPieces.draw_face(zoom, r, _zoom_face)


func _set_zoom(key: String, p := Vector2(960, 0)) -> void:
	var f := {}
	if key != "":
		var c: BoardTable.Card3D = table.card(key)
		if c != null and not (c.flip > 0.5) and str(c.face.get("kind", "")) != "slot":
			f = c.face.duplicate()
			f.big = true
	_zoom_left = p.x > 760.0
	if f != _zoom_face:
		_zoom_face = f
		zoom.queue_redraw()


func _set_spread(cell: String) -> void:
	if spread_cell == cell:
		return
	spread_cell = cell
	_sync_table()


# ───────── 입력 ─────────
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouse:
		var is_touch: bool = e.device == InputEvent.DEVICE_ID_EMULATION
		if is_touch:
			FX.touch = true
		if e is InputEventMouseButton:
			if e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
				if not is_touch:
					_cancel_all()
				accept_event()
				return
			if e.button_index != MOUSE_BUTTON_LEFT:
				return
			accept_event()
			if e.pressed:
				touch = is_touch
				_down(e.position)
			else:
				_up(e.position)
		elif e is InputEventMouseMotion:
			_move(e.position, is_touch)


func _move_thresh() -> float:
	return (12.0 if touch else 8.0) / minf(1.0, maxf(0.05, FX.css_scale))


func _down(p: Vector2) -> void:
	if mode == "drag":
		_cancel_drag()
	match mode:
		"pick":
			var k := table.pick(p, func(key): return key.begins_with("e:"))
			if k != "":
				_commit_pending({"target": k.substr(2)})
			else:
				_cancel_pending()
			return
		"shift":
			var tk := _target_key(str(pending.target))
			if table.pick(p) == tk:
				mdrag = {"kind": "act", "id": str(pending.target), "key": tk, "start": p, "moved": false}
				return
			var col := col_at(p)
			if col >= 0 and RulesV2.shift_dests(st, pending.target).has(col):
				_commit_pending({"to": col})
			else:
				_cancel_pending()
			return
		"idle", "formation":
			pass
		_:
			return
	if mode == "idle":
		var uid := hand.hit_test(p)
		if uid != "":
			drag = {"uid": uid, "start": p, "moved": false, "hot": "", "col": -1}
			mode = "drag"
			hand.hover_uid = ""
			hand.lifted_uid = uid
			_set_zoom("")
			hand.layout()
			return
	var key := table.pick(p)
	tap = {"key": key, "start": p, "t": Time.get_ticks_msec()}
	if key.begins_with("ally:"):
		mdrag = {"kind": "ally", "id": key.substr(5), "key": key, "start": p, "moved": false}


func _move(p: Vector2, is_touch: bool) -> void:
	if not mdrag.is_empty():
		_move_mdrag(p)
		return
	match mode:
		"drag":
			if drag.is_empty():
				return
			if not drag.moved and absf(p.x - drag.start.x) + absf(p.y - drag.start.y) > _move_thresh():
				drag.moved = true
				hand.lifted_uid = ""
				hand.drag_uid = drag.uid
				hand.drag_mode = "follow"
			if drag.moved:
				hand.drag_pos = p
				hand.layout()
				_update_drag_hot(p)
		"pick":
			var k := table.pick(p, func(key): return key.begins_with("e:"))
			for key in table.cards:
				if key.begins_with("e:"):
					var e = RulesV2.enemy(st, key.substr(2))
					table.card(key).set_glow(2.0 if key == k else (1.0 if e != null and e.alive else 0.0))
			hand.point_at = table.to_screen(table.card(k).position) + Vector2(0, 30) if k != "" else p
		"idle", "formation":
			if is_touch:
				return   # 터치: 길게 누르면 크게 보기 · 그 칸 펼치기(_process_touch_zoom)
			var hu := hand.hit_test(p) if mode == "idle" else ""
			hand.set_hover(hu)
			if hu != "":
				_set_zoom("")
				return
			var key := table.pick(p)
			_set_zoom(key, p)
			var cell := str(_cell_of.get(key, ""))
			if key != "" and cell != "" and _pile_size(cell) > 1:
				_set_spread(cell)
			elif key == "" or cell != spread_cell:
				_set_spread("")
			# ② 카드 ↔ 그 카드를 보낸 적(올리면 서로 빛난다)
			var link := ""
			if key.begins_with("a:"):
				link = key.substr(2).split("#")[0]
			elif key.begins_with("e:"):
				link = key.substr(2)
			for k2 in table.cards:
				var c: BoardTable.Card3D = table.card(k2)
				if (k2.begins_with("e:") or k2.begins_with("a:")) and c.tglow < 1.5:
					var me: String = k2.substr(2).split("#")[0]
					c.set_glow(0.7 if link != "" and me == link else 0.0, Color(1, 0.35, 0.4))


func _pile_size(cell: String) -> int:
	var n := 0
	for k in _cell_of:
		if _cell_of[k] == cell:
			n += 1
	return n


func _process_touch_zoom() -> void:
	if not touch or tap.is_empty() or str(tap.key) == "" or mode not in ["idle", "formation"]:
		return
	if not mdrag.is_empty() and mdrag.moved:
		return
	if Time.get_ticks_msec() - int(tap.t) > 380:
		_set_zoom(str(tap.key), tap.start)
		var cell := str(_cell_of.get(tap.key, ""))
		if _pile_size(cell) > 1:
			_set_spread(cell)


func _up(p: Vector2) -> void:
	var t2 := tap
	tap = {}
	var long_press := touch and not t2.is_empty() and Time.get_ticks_msec() - int(t2.t) > 380
	if touch:
		_set_zoom("")
		if spread_cell != "":
			_set_spread("")
	if not mdrag.is_empty():
		_up_mdrag(p)
		return
	if mode == "drag":
		if drag.is_empty():
			mode = "idle"
			return
		if not drag.moved:
			_cancel_drag()
			return
		_update_drag_hot(p)
		var uid: String = drag.uid
		var hot: String = drag.hot
		var reason: String = drag.get("reason", "")
		_clear_marks()
		if hot == "":
			if reason != "":
				_toast_reason(reason)
			_cancel_drag()
			return
		_drop(uid, hot)
		return
	if mode == "idle" and not t2.is_empty() and not long_press:
		if absf(p.x - t2.start.x) + absf(p.y - t2.start.y) > _move_thresh():
			return
		var key := str(t2.key)
		if key.begins_with("p:"):
			_return_placed(key.substr(2))
		elif key.begins_with("n:"):
			_return_noel(key.substr(2))


# ───────── 탁자 카드 끌기: 동료 자리 바꾸기·빼기·넣기 · 운명 전가로 ② 옮기기 ─────────
func _move_mdrag(p: Vector2) -> void:
	if not mdrag.moved:
		if absf(p.x - mdrag.start.x) + absf(p.y - mdrag.start.y) <= _move_thresh():
			return
		if mdrag.kind == "ally" and mode not in ["idle", "formation"]:
			mdrag = {}
			return
		mdrag.moved = true
		_set_zoom("")
	var c: BoardTable.Card3D = table.card(mdrag.key)
	if c == null:
		return
	var g = table.ground(p, float(TL().lift))
	if g != null:
		c.tpos = Vector3(g.x, 0, g.z)
		c.tlift = float(TL().lift)
		c.ttilt = 0.28
		c.set_prio(120)
	hand.point_at = p + Vector2(10, 40)
	var z := zone_at(p)
	if mdrag.kind == "ally":
		for k in table.cards:
			if k.begins_with("ally:") or k.begins_with("slot:"):
				table.card(k).set_glow(0.0)
		var to = _ally_dest(z)
		var chk := RulesV2.can_move(st, mdrag.id, to) if to != null else {"ok": false}
		preview_text = ""
		if chk.ok:
			var tk := ("slot:%d" % int(to)) if str(to) != "bench" and RulesV2.ally_at(st, int(to)) == "" else ("ally:" + RulesV2.ally_at(st, int(to)) if str(to) != "bench" else "")
			if tk != "" and table.card(tk) != null:
				table.card(tk).set_glow(1.6)
			if int(chk.cost) > 0:
				preview_text = T("moved", {"n": chk.cost})
				preview_pos = p + Vector2(0, -90)
	else:
		var dests := RulesV2.shift_dests(st, pending.target)
		for k in table.cards:
			if k.begins_with("ally:") or k.begins_with("slot:"):
				var cc := RulesV2.col_of(st, k.substr(5)) if k.begins_with("ally:") else int(k.substr(5))
				table.card(k).set_glow(2.0 if z.get("col", -1) == cc and dests.has(cc) else (1.0 if dests.has(cc) else 0.0))
	overlay.queue_redraw()


func _ally_dest(z: Dictionary):
	if z.has("bench"):
		return "bench"
	if z.has("col"):
		return int(z.col)
	return null


func _up_mdrag(p: Vector2) -> void:
	var md := mdrag
	mdrag = {}
	preview_text = ""
	hand.point_at = null
	if not md.moved:
		_sync_table()
		return
	var z := zone_at(p)
	if md.kind == "ally":
		var to = _ally_dest(z)
		if to != null and RulesV2.can_move(st, md.id, to).ok:
			_commit_move(str(md.id), to)
			return
		if to != null:
			_toast_reason(RulesV2.can_move(st, md.id, to).reason)
		_sync_table()
		return
	# 운명 전가: 옮길 칸에 놓음
	var col := int(z.get("col", -1))
	if col >= 0 and RulesV2.shift_dests(st, pending.target).has(col):
		_commit_pending({"to": col})
	else:
		_sync_table()
		_mark_shift_dests()


func _commit_move(id: String, to) -> void:
	var res := RulesV2.move_ally(st, id, to)
	if not res.ok:
		_toast_reason(res.reason)
		_sync_table()
		return
	note("move %s %s cost=%d" % [id, str(to), int(res.cost)])
	for u in res.returned:
		var k: String = "p:" + str(u)
		var from := deck_center()
		if table.card(k) != null:
			from = table.screen_rect(k).get_center()
		elif table.card("n:" + u) != null:
			from = table.screen_rect("n:" + u).get_center()
		hand.create(st, u, from)
	if int(res.cost) > 0:
		FX.toast(T("moved", {"n": res.cost}), 900)
	_set_idle()


# ───────── 손패 카드 끌기 ─────────
## 끄는 카드가 지금 놓일 곳(drag.hot) — 동료 카드는 칸(그 칸의 동료), 노엘의 카드는 ②·①·④ 의 그 대상. 놓일 수 있는 곳은 금빛
func _update_drag_hot(p: Vector2) -> void:
	var uid: String = drag.uid
	var d := RulesV2.card_def(st, uid)
	var hot := ""
	var reason := ""
	preview_text = ""
	prompt_text = ""
	for k in table.cards:
		table.card(k).set_glow(0.0)
	if str(d.owner) == "noel":
		var on := str(d.on)
		var cand := ""
		var kind := str(d.kind)
		match on:
			"act":
				var k := table.pick(p, func(key): return key.begins_with("a:") or key.begins_with("d:"))
				if k.begins_with("a:"):
					cand = k.substr(2).split("#")[0]
				elif k.begins_with("d:"):
					cand = k.substr(2)
			"enemy":
				var k2 := table.pick(p, func(key): return key.begins_with("e:"))
				cand = k2.substr(2) if k2 != "" else ""
			_:
				var k3 := table.pick(p, func(key): return key.begins_with("ally:"))
				cand = k3.substr(5) if k3 != "" else ""
				if cand == "":
					var c := col_at(p)
					cand = RulesV2.ally_at(st, c) if c >= 0 else ""
		if cand != "":
			var chk := RulesV2.can_cast(st, uid, cand)
			if chk.ok:
				hot = cand
			else:
				reason = chk.reason
		# 놓을 수 있는 대상에 금빛
		for k4 in table.cards:
			var tid := ""
			if on == "act" and (k4.begins_with("a:") or k4.begins_with("d:")):
				tid = k4.substr(2).split("#")[0]
			elif on == "enemy" and k4.begins_with("e:"):
				tid = k4.substr(2)
			elif on == "ally" and k4.begins_with("ally:"):
				tid = k4.substr(5)
			if tid != "" and RulesV2.can_cast(st, uid, tid).ok:
				table.card(k4).set_glow(2.0 if tid == hot else 1.0)
		if hot != "":
			preview_text = T({"bless": "tagBless", "curse": "tagCurse", "vuln": "tagVuln", "shift": "tagShift", "tear": "tagTear"}[kind])
			preview_pos = p + Vector2(0, -110)
		else:
			prompt_text = T({"act": "dropDeath" if kind == "tear" else "dropAct", "enemy": "dropEnemy", "ally": "dropAlly"}[on])
	else:
		var col := col_at(p)
		for c in RulesV2.ncols():
			var id := RulesV2.ally_at(st, c)
			if id != "" and RulesV2.can_place(st, uid, id).ok:
				table.card("ally:" + id).set_glow(2.0 if c == col else 1.0)
		if col >= 0:
			var chk2 := RulesV2.can_place_col(st, uid, col)
			if chk2.ok:
				hot = RulesV2.ally_at(st, col)
				preview_text = _preview_line(uid, hot)
				preview_pos = table.to_screen(cell_pos(2, col) + Vector3(0, 0, -0.75)) + Vector2(0, -6)
			else:
				reason = chk2.reason
	drag.hot = hot
	drag.reason = reason
	overlay.queue_redraw()


func _preview_line(uid: String, ally: String) -> String:
	var d := RulesV2.card_def(st, uid)
	var r := RulesV2.forecast_place(st, uid, ally)
	var nm := str(d.name)
	match str(d.kind):
		"attack", "release":
			var s := "%s %d" % [nm, int(r.get("dmg", 0))]
			if int(r.get("block", 0)) > 0:
				s += " · " + T("block", {"n": r.block})
			return s
		"block":
			var s2 := "%s %d" % [nm, int(r.get("block", 0))]
			if int(r.get("counter", 0)) > 0:
				s2 += " · " + T("counter", {"n": r.counter})
			return s2
		"aim":
			return "%s · %s" % [nm, T("multTo", {"n": int(r.get("mult", 1))})]
	return nm


func _clear_marks() -> void:
	preview_text = ""
	prompt_text = ""
	for k in table.cards:
		table.card(k).set_glow(0.0)
	_sync_table()
	overlay.queue_redraw()


func _cancel_drag() -> void:
	drag = {}
	hand.drag_uid = ""
	hand.drag_mode = ""
	hand.lifted_uid = ""
	preview_text = ""
	prompt_text = ""
	if mode == "drag":
		mode = "idle"
	_sync_table()
	overlay.queue_redraw()
	hand.layout()


func _cancel_all() -> void:
	if mode == "drag":
		_cancel_drag()
	elif mode in ["pick", "shift"]:
		_cancel_pending()


# ───────── 놓기 ─────────
## 손패 카드를 그 대상(동료 id · 적 행동/죽음/적 id · 동료 id)에 놓는다
func _drop(uid: String, hot: String) -> void:
	drag = {}
	hand.drag_uid = ""
	hand.drag_mode = ""
	hand.lifted_uid = ""
	var d := RulesV2.card_def(st, uid)
	if str(d.owner) == "noel":
		if str(d.kind) == "shift":
			await _start_pending_shift(uid, hot)
		else:
			await _commit_cast(uid, hot, {})
		return
	if RulesV2.needs_target(st, uid):
		var al := RulesV2.alive_enemies(st)
		if al.size() == 1:
			await _commit_place(uid, hot, {"target": al[0].id})
		else:
			await _start_pending_attack(uid, hot)
		return
	await _commit_place(uid, hot, {})


## 손패의 카드가 날아가 작아지며 탁자의 그 자리 위(들린 높이)로 → 3D 카드가 이어서 떨어진다
func _fly(uid: String, r: Rect2) -> void:
	var c: CardView = hand.detach(uid)
	if c == null:
		return
	c.smooth = true
	c.shadow = 0.0
	c.glow = 0.0
	c.z_index = 135
	var k := r.size.x / CardView.W
	c.set_rect(r.position, k, false)
	await FX.wait(170)
	if is_instance_valid(c):
		c.queue_free()


## 그 동료 칸 ③ 의 다음 카드 자리(화면, 조금 들린 높이)
func _slot_rect(ally: String, idx: int) -> Rect2:
	var col := RulesV2.col_of(st, ally)
	var n := idx + 1
	var cw: float = TL().card[0]
	var dx := float(TL().pileDx)
	if n > 1:
		dx = minf(dx, (float(TL().cellW) - cw) / (n - 1))
	var ctr := cell_pos(2, col)
	var x := ctr.x - (cw + (n - 1) * dx) / 2.0 + cw / 2.0 + idx * dx
	return table.rect_at(Vector3(x, 0.9, ctr.z))


func _target_rect(target: String) -> Rect2:
	for k in ["d:" + target, "a:" + target, "a:%s#0" % target, "e:" + target, "ally:" + target]:
		if table.card(k) != null:
			var c: BoardTable.Card3D = table.card(k)
			return table.rect_at(c.tpos + Vector3(0.3, 0.9, 0))
	return Rect2(deck_center(), Vector2(60, 90))


func _commit_place(uid: String, ally: String, opts: Dictionary) -> bool:
	var res := RulesV2.place(st, uid, ally, opts)
	if not res.ok:
		_toast_reason(res.reason)
		_set_idle()
		return false
	mode = "busy"
	note("place %s %s %s" % [st.cards[uid].id, ally, str(opts)])
	await _fly(uid, _slot_rect(ally, st.allies[ally].placed.size() - 1))
	if not is_inside_tree():
		return true
	_set_idle()
	return true


func _commit_cast(uid: String, target: String, opts: Dictionary) -> bool:
	var tr := _target_rect(target)
	var res := RulesV2.cast(st, uid, target, opts)
	if not res.ok:
		_toast_reason(res.reason)
		_set_idle()
		return false
	mode = "busy"
	note("cast %s %s %s" % [st.cards[uid].id, target, str(opts)])
	await _fly(uid, tr)
	if not is_inside_tree():
		return true
	if str(res.cast.kind) == "tear":
		FX.flash("#ff2a3a", 260, 0.35)
		var dk := "d:" + target
		if table.card(dk) != null:
			table.card(dk).set_flash(1.0)
			table.push_out(dk, Vector3(0, 0.6, -0.4), 420)
	_set_idle()
	return true


## 공격 카드: 동료 칸에 놓고(붉게 깜빡임) 적 카드를 누를 때까지 기다린다
func _start_pending_attack(uid: String, ally: String) -> void:
	var chk := RulesV2.can_place(st, uid, ally)
	if not chk.ok:
		_toast_reason(chk.reason)
		_set_idle()
		return
	mode = "busy"
	var idx: int = st.allies[ally].placed.size()
	await _fly(uid, _slot_rect(ally, idx))
	if not is_inside_tree():
		return
	pending = {"uid": uid, "kind": "attack", "ally": ally, "target": ""}
	mode = "pick"
	prompt_text = T("pickEnemy")
	_sync_table()
	for k in table.cards:
		if k.begins_with("e:"):
			var e = RulesV2.enemy(st, k.substr(2))
			table.card(k).set_glow(1.0 if e != null and e.alive else 0.0)
	_sync_hud()
	overlay.queue_redraw()


## 운명 전가: 그 ② 카드(또는 죽음 카드)에 놓고 옮길 칸을 고를 때까지 기다린다
func _start_pending_shift(uid: String, target: String) -> void:
	var chk := RulesV2.can_cast(st, uid, target)
	if not chk.ok:
		_toast_reason(chk.reason)
		_set_idle()
		return
	mode = "busy"
	await _fly(uid, _target_rect(target))
	if not is_inside_tree():
		return
	pending = {"uid": uid, "kind": "shift", "ally": "", "target": target}
	mode = "shift"
	prompt_text = T("shiftTo")
	_sync_table()
	_mark_shift_dests()
	_sync_hud()
	overlay.queue_redraw()


func _mark_shift_dests() -> void:
	if pending.is_empty():
		return
	var dests := RulesV2.shift_dests(st, pending.target)
	for c in RulesV2.ncols():
		var id := RulesV2.ally_at(st, c)
		var k: String = ("ally:" + id) if id != "" else ("slot:%d" % c)
		if table.card(k) != null:
			table.card(k).set_glow(1.0 if dests.has(c) else 0.0)
	var tk := _target_key(str(pending.target))
	if table.card(tk) != null:
		table.card(tk).set_glow(2.0)


func _commit_pending(opts: Dictionary) -> void:
	var pd := pending
	pending = {}
	prompt_text = ""
	mode = "busy"
	var ok := false
	if pd.kind == "attack":
		var res := RulesV2.place(st, pd.uid, pd.ally, opts)
		ok = res.ok
		if ok:
			note("place %s %s %s" % [st.cards[pd.uid].id, pd.ally, str(opts)])
		else:
			_toast_reason(res.reason)
	else:
		var res2 := RulesV2.cast(st, pd.uid, pd.target, opts)
		ok = res2.ok
		if ok:
			note("cast %s %s %s" % [st.cards[pd.uid].id, pd.target, str(opts)])
		else:
			_toast_reason(res2.reason)
	if not ok:
		var k: String = ("p:" if pd.kind == "attack" else "n:") + str(pd.uid)
		hand.create(st, pd.uid, table.screen_rect(k).get_center() if table.card(k) != null else deck_center())
	_set_idle()


func _cancel_pending() -> void:
	if pending.is_empty():
		mode = "idle"
		return
	var pd := pending
	pending = {}
	prompt_text = ""
	mdrag = {}
	var k: String = ("p:" if pd.kind == "attack" else "n:") + str(pd.uid)
	var from := table.screen_rect(k).get_center() if table.card(k) != null else deck_center()
	hand.create(st, pd.uid, from)
	_set_idle()


## ③ 카드를 누름 → 손패로(에너지 돌려받음)
func _return_placed(uid: String) -> void:
	for id in st.order:
		var pl: Array = st.allies[id].placed
		for i in pl.size():
			if pl[i].uid == uid:
				var from := table.screen_rect("p:" + uid).get_center()
				var res := RulesV2.unplace(st, id, i)
				if not res.ok:
					_toast_reason(res.reason)
					return
				hand.create(st, uid, from)
				note("unplace %s %s" % [st.cards[uid].id, id])
				_set_idle()
				return


## 노엘의 카드를 누름 → 손패로(효과도 없던 일로)
func _return_noel(uid: String) -> void:
	for i in st.noel.size():
		if st.noel[i].uid == uid:
			var from := table.screen_rect("n:" + uid).get_center()
			var res := RulesV2.uncast(st, i)
			if not res.ok:
				_toast_reason(res.reason)
				return
			hand.create(st, uid, from)
			note("uncast %s" % st.cards[uid].id)
			_set_idle()
			return


# ───────── 출전 · 턴 끝 → 적 턴 ─────────
func _on_start() -> void:
	if mode != "formation":
		return
	var res := RulesV2.start_battle(st)
	if not res.ok:
		_toast_reason(res.reason)
		return
	mode = "busy"
	note("start %s bench=%s" % [str(st.slots), str(st.bench)])
	_sync_table()
	_sync_hud()
	await _play(res.events)
	_set_idle()


func _on_end() -> void:
	if mode in ["pick", "shift"]:
		_cancel_pending()
	if mode == "drag":
		_cancel_drag()
	if mode != "idle" or st.result != null:
		return
	await end_turn()


func end_turn() -> void:
	mode = "busy"
	hand.set_hover("")
	_set_zoom("")
	spread_cell = ""
	_sync_table()
	_sync_hud()
	note("endTurn %d" % int(st.turn))
	_hand_snap = st.hand.duplicate()
	var evs := RulesV2.end_turn(st)
	if not evs.any(func(x): return str(x.t) == "cleanup"):
		_hand_snap = null
	await _play(evs)
	_hand_snap = null
	if not is_inside_tree():
		return
	if st.result != null:
		_show_result()
		return
	await _play(RulesV2.start_turn(st))
	_set_idle()


# ───────── 연출 ─────────
func _play(events: Array) -> void:
	# 뽑을 카드는 뽑는 연출 전까지 손패에 보이지 않게
	for e in events:
		if str(e.t) == "draw":
			_hidden.append_array(e.uids)
	for e in events:
		if not is_inside_tree():
			return
		var h := "_ev_" + str(e.t)
		if has_method(h):
			await call(h, e)


func _ev_turnStart(e: Dictionary) -> void:
	turn_label.text = T("turn", {"n": e.turn})
	note("turn %d" % int(e.turn))
	FX.banner(T("turn", {"n": e.turn}), 800)
	_shown_energy = int(st.energy)
	_sync_hud()
	await FX.wait(260)


func _ev_draw(e: Dictionary) -> void:
	var list: Array = e.uids
	for u in list:
		_hidden.erase(u)
		hand.create(st, u, deck_center())
		hand.layout()
		hud.queue_redraw()
		await FX.wait(90)


func _ev_reshuffle(_e: Dictionary) -> void:
	FX.toast(T("reshuffle"), 1000)
	await FX.wait(200)


## 적 행동 카드: 적 덱에서 뒷면으로 나와 노리는 칸으로 날아가며 뒤집힌다
func _ev_intents(_e: Dictionary) -> void:
	var want := _layout()
	var keys: Array = want.keys()
	var n := 0
	for key in keys:
		if not (key.begins_with("a:") or key.begins_with("d:") or key.begins_with("g:")) or table.card(key) != null:
			continue
		var w: Dictionary = want[key]
		var c := table.make_card(key, w.face, deck_pos(4))
		c.flip = 1.0
		c.tflip = 1.0
		c.set_prio(int(w.prio))
		c.position = deck_pos(4) + Vector3(0, 0.1, 0)
		var death: bool = key.begins_with("d:")
		c.fly_to(w.pos, 420 if not death else 620, 0.7 if not death else 1.2, true)
		n += 1
		await FX.wait(110 if not death else 520)
		if death:
			FX.flash("#8a0010", 300, 0.4)
			FX.toast(str(w.face.name) + " — " + T("deathMark"), 1600)
	if n > 0:
		await FX.wait(420)
	_sync_table()
	_sync_hud()
	await FX.wait(200)


func _ev_deathCard(_e: Dictionary) -> void:
	pass


func _ev_allyPhase(_e: Dictionary) -> void:
	await FX.wait(120)


func _ev_act(e: Dictionary) -> void:
	var ac: BoardTable.Card3D = table.card("ally:" + str(e.ally))
	if ac != null:
		ac.set_glow(1.2, Color.WHITE)
	var pc: BoardTable.Card3D = table.card("p:" + str(e.uid))
	if pc != null:
		pc.hop(Vector3(0, 0, -0.35))
	await FX.wait(240)
	if ac != null and is_instance_valid(ac):
		ac.set_glow(0.0)


func _ev_retarget(_e: Dictionary) -> void:
	await FX.wait(60)


func _float_at(key: String, text, cls: String, dy := 0.0) -> void:
	var c: BoardTable.Card3D = table.card(key)
	var p := table.to_screen(c.position) if c != null else Vector2(960, 400)
	FX.float_text(p.x, p.y + dy, text, cls)


func _ev_hit(e: Dictionary) -> void:
	var key := "e:" + str(e.enemy)
	var c: BoardTable.Card3D = table.card(key)
	if c != null:
		c.set_face(_hp_face(c.face, int(e.hp)))
		c.hit_shake(1.0)
		var p := table.to_screen(c.position)
		FX.slash(p.x, p.y, {"len": 160, "color": "#ffe6c8", "width": 7})
	_float_at(key, e.amount, "enemy")
	await FX.wait(300)


func _hp_face(f: Dictionary, hp: int) -> Dictionary:
	var g := f.duplicate()
	g.hp = hp
	return g


func _ev_enemyDie(e: Dictionary) -> void:
	var key := "e:" + str(e.enemy)
	var c: BoardTable.Card3D = table.card(key)
	var en = RulesV2.enemy(st, str(e.enemy))
	for k in table.cards.keys():
		if k.begins_with("a:" + str(e.enemy)) or k == "g:" + str(e.enemy):
			table.push_out(k)
	if c == null:
		return
	if en != null and RulesV2.is_minion(en):
		table.push_out(key, Vector3(0.8, 0, -0.6), 360)
		await FX.wait(300)
	else:
		await c.flip_to(false, 380)


func _ev_deathGone(e: Dictionary) -> void:
	var k := "d:" + str(e.id)
	if table.card(k) != null:
		table.card(k).set_flash(1.0)
		table.push_out(k, Vector3(0, 0.8, -0.5), 460)
	FX.toast(T("deathGone"), 1400)
	await FX.wait(300)


func _ev_block(e: Dictionary) -> void:
	_refresh_faces()
	_float_at("ally:" + str(e.ally), T("block", {"n": e.amount}), "small", -60)
	await FX.wait(200)


func _ev_mult(_e: Dictionary) -> void:
	_refresh_faces()
	await FX.wait(140)


func _ev_brace(_e: Dictionary) -> void:
	_refresh_faces()
	await FX.wait(80)


func _ev_win(_e: Dictionary) -> void:
	await FX.wait(300)


func _ev_enemyPhase(_e: Dictionary) -> void:
	FX.banner(T("enemyTurn"), 700)
	await FX.wait(420)


## 적 행동 카드가 노린 칸의 동료 카드로(빈칸이면 노엘 — 화면 쪽으로) 날아가 부딪히고 사라진다
func _ev_enemyAct(e: Dictionary) -> void:
	if str(e.kind) in ["summon", "death"]:
		await FX.wait(160)
		return
	var keys := []
	if str(e.kind) == "sweep":
		for c in RulesV2.ncols():
			keys.append(["a:%s#%d" % [e.enemy, c], c])
	else:
		keys.append(["a:" + str(e.enemy), int(e.slot)])
	var flying := []
	for kc in keys:
		var c3: BoardTable.Card3D = table.card(kc[0])
		if c3 == null:
			continue
		var col: int = kc[1]
		var to: Vector3
		if RulesV2.receiver(st, col) == "noel":
			to = cell_pos(3, col) + Vector3(0, 1.6, 2.6)
		else:
			to = cell_pos(3, col) + Vector3(0, 0.25, -0.2)
		table.cards.erase(kc[0])
		c3.dying = true
		c3.set_prio(110)
		flying.append(c3)
		c3.fly_to(to, 260, 0.35)
	if flying.is_empty():
		await FX.wait(60)
		return
	await FX.wait(270)
	# 부딪힌 카드는 사라진다
	for c4 in flying:
		var nn: BoardTable.Card3D = c4
		if is_instance_valid(nn):
			nn.pinned = true
			FX.anim(200, [{"a": 1.0}, {"a": 0.0}], func(v): if is_instance_valid(nn): nn.set_alpha(v.a), {"node": nn}).finished.connect(func(): if is_instance_valid(nn): nn.free_all())
	await FX.wait(60)


func _ev_summon(_e: Dictionary) -> void:
	_sync_table()
	FX.toast(T("summoned", {"name": D().enemies.skeleton.name}), 1000)
	await FX.wait(420)


func _ev_allyHit(e: Dictionary) -> void:
	var key := "ally:" + str(e.ally)
	var c: BoardTable.Card3D = table.card(key)
	if c != null:
		c.set_face(face_ally(str(e.ally)))
		c.hit_shake(1.2)
	if int(e.amount) > 0:
		_float_at(key, -int(e.amount), "ally")
	if int(e.blocked) > 0:
		_float_at(key, T("blocked", {"n": e.blocked}), "small", -70)
	await FX.wait(260)


func _ev_noelHit(e: Dictionary) -> void:
	FX.flash("#ff1a2a", 240, 0.35)
	FX.shake(10, 300)
	var nc := noel_center()
	FX.float_text(nc.x, nc.y - 60, -int(e.amount), "ally")
	_noel_shake = 1.0
	hud.queue_redraw()
	await FX.wait(300)


func _ev_counter(e: Dictionary) -> void:
	var a: BoardTable.Card3D = table.card("ally:" + str(e.ally))
	var b: BoardTable.Card3D = table.card("e:" + str(e.enemy))
	if a == null or b == null:
		return
	var pa := table.to_screen(a.position)
	var pb := table.to_screen(b.position)
	FX.float_text(pa.x, pa.y - 90, T("counter", {"n": D().traits.hero.counter}), "small")
	await FX.streak(pa.x, pa.y - 40, pb.x, pb.y, {"color": "#ffe6c8", "width": 5, "dur": 200})


func _ev_allyDown(e: Dictionary) -> void:
	var c: BoardTable.Card3D = table.card("ally:" + str(e.ally))
	if c != null:
		c.set_face(face_ally(str(e.ally)))
	await FX.wait(320)


## 죽음 카드: 그 동료 카드 위로 내려앉고, 동료 카드가 「죽음」으로 뒤집힌다
func _ev_death(e: Dictionary) -> void:
	var dk := "d:" + str(e.id)
	var ak := "ally:" + str(e.ally)
	var d3: BoardTable.Card3D = table.card(dk)
	var a3: BoardTable.Card3D = table.card(ak)
	FX.banner(str(e.label), 1200)
	if d3 != null and a3 != null:
		d3.set_prio(115)
		await d3.fly_to(a3.tpos + Vector3(0, 0.05, 0), 520, 0.9)
		FX.flash("#6a0008", 380, 0.55)
		table.push_out(dk, Vector3(0, 0.5, -0.2), 300)
	if a3 != null:
		await a3.flip_swap(face_ally(str(e.ally)), 520)
	await FX.wait(500)


func _ev_deathWait(e: Dictionary) -> void:
	FX.toast(T("deathWait", {"name": G.name_of(str(e.ally))}), 1600)
	_sync_table()
	await FX.wait(400)


func _ev_lose(_e: Dictionary) -> void:
	await FX.wait(300)


## 정리: 처리된 카드(③·노엘 카드·남은 행동 카드)는 밀려나 사라지고, 손패는 버린다
func _ev_cleanup(_e: Dictionary) -> void:
	for k in table.cards.keys():
		if k.begins_with("p:") or k.begins_with("n:"):
			table.push_out(k, Vector3(-0.3, 0, 1.4), 320)
		elif k.begins_with("a:") or k.begins_with("g:"):
			table.push_out(k, Vector3(1.6, 0, -0.8), 320)
	_hand_snap = null
	for u in hand.cards.keys():
		var c: CardView = hand.detach(u)
		if c != null:
			var nd := c
			FX.anim(260, [{"a": 1.0}, {"a": 0.0}], func(v): if is_instance_valid(nd): nd.alpha = v.a, {"node": nd}).finished.connect(func(): if is_instance_valid(nd): nd.queue_free())
	await FX.wait(340)
	if st.result == null:
		_sync_table()
		_sync_hud()


# ───────── 결과 판 ─────────
func _show_result() -> void:
	mode = "over"
	preview_text = ""
	prompt_text = ""
	hand.set_hover("")
	_set_zoom("")
	for u in hand.cards.keys():
		var c: CardView = hand.detach(u)
		if c != null:
			c.queue_free()
	_sync_table()
	_sync_hud()
	end_btn.visible = false
	var win: bool = st.result == "win"
	var hp := []
	for id in st.order:
		hp.append("%s=%d/%d%s" % [id, int(st.allies[id].hp), int(st.allies[id].maxHp), " dead" if st.allies[id].dead else ""])
	var post := RulesV2.postponed(st)
	G.ctl.note("result v2 %s turn=%d noel=%d %s%s" % [str(st.result), int(st.turn), int(st.noelHp), " ".join(hp), (" postponed=" + ",".join(post)) if not post.is_empty() else ""])
	log.append("result " + str(st.result))
	result_panel = Control.new()
	result_panel.name = "result"
	result_panel.size = size
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	result_panel.z_index = 300
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.add_child(dim)
	var box := Rect2(960 - 490, 210, 980, 540)
	var VB: Dictionary = GameData.D.vnBox
	if Assets.ok(str(VB.img)):
		var fr := NinePatchRect.new()
		fr.texture = Assets.tex(str(VB.img))
		var mg: Array = VB.margin
		fr.patch_margin_left = int(mg[0])
		fr.patch_margin_top = int(mg[1])
		fr.patch_margin_right = int(mg[2])
		fr.patch_margin_bottom = int(mg[3])
		fr.position = box.position
		fr.size = box.size
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_panel.add_child(fr)
	var ink := Color("#2b1a12")
	var crimson := Color("#78141e")
	var t := UI.label(T("win") if win else T("lose"), 92, crimson if not win else ink, "serif_wide", HORIZONTAL_ALIGNMENT_CENTER)
	t.position = Vector2(box.position.x, box.position.y + 46)
	t.size = Vector2(box.size.x, 120)
	result_panel.add_child(t)
	var sub_key := "winText" if win else ("loseNoel" if st.loseBy == "noel" else "loseText")
	var sub := UI.label(T(sub_key, {"n": st.turn}), 30, ink, "serif", HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(box.position.x, box.position.y + 166)
	sub.size = Vector2(box.size.x, 44)
	result_panel.add_child(sub)
	# 동료 셋의 얼굴과 남은 HP · 노엘 HP
	var x0 := 960.0 - 4 * 200.0 / 2.0
	for i in st.order.size() + 1:
		var lab := ""
		var col := ink
		if i < st.order.size():
			var id: String = st.order[i]
			var a: Dictionary = st.allies[id]
			var face := TextureRect.new()
			face.texture = Assets.face_tex(id, null, true)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.position = Vector2(x0 + i * 200 + 52, box.position.y + 224)
			face.size = Vector2(96, 96)
			face.modulate = Color(0.4, 0.36, 0.36) if a.down else Color.WHITE
			result_panel.add_child(face)
			lab = T("dead") if a.dead else (T("down") if a.down else "%d / %d" % [int(a.hp), int(a.maxHp)])
			if st.bench.has(id) and not a.down:
				lab += " · " + T("bench_state")
			col = crimson if a.down else ink
		else:
			var nl := UI.label(T("noel"), 30, ink, "serif_bold", HORIZONTAL_ALIGNMENT_CENTER)
			nl.position = Vector2(x0 + i * 200, box.position.y + 250)
			nl.size = Vector2(200, 44)
			result_panel.add_child(nl)
			lab = "%d / %d" % [int(st.noelHp), int(st.noelMax)]
			col = crimson if int(st.noelHp) <= 0 else ink
		var hl := UI.label(lab, 24, col, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
		hl.position = Vector2(x0 + i * 200, box.position.y + 326)
		hl.size = Vector2(200, 34)
		result_panel.add_child(hl)
	if not post.is_empty():
		var pl := UI.label(T("postponed", {"list": ", ".join(post)}), 28, crimson, "serif_bold", HORIZONTAL_ALIGNMENT_CENTER)
		pl.position = Vector2(box.position.x, box.position.y + 392)
		pl.size = Vector2(box.size.x, 44)
		pl.name = "postponed"
		result_panel.add_child(pl)
	var again := UI.button(T("again"), 34, restart)
	again.name = "again"
	again.fit(Vector2(60, 16))
	again.position = Vector2(960 - again.size.x / 2.0, box.end.y + 20)
	result_panel.add_child(again)
	add_child(result_panel)
	result_panel.modulate.a = 0.0
	FX.anim(400, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(result_panel): result_panel.modulate.a = v.a, {"node": result_panel})
	if G.params.has("quit-on-end"):
		get_tree().create_timer(1.0, false).timeout.connect(func(): get_tree().quit(0))


## 「다시 하기」: 같은 전투(같은 시드)를 처음부터(출전 배치부터)
func restart() -> void:
	var p := get_parent()
	var sd = st.seed
	note("restart seed=%d" % int(sd))
	mode = "busy"
	await FX.fade(1, 300)
	if current == self:
		current = null
	queue_free()
	BoardBattle.open(p, sd)


# ───────── 매 프레임 · 자동 진행 (--autoplay) ─────────
func _process(delta: float) -> void:
	if _noel_shake > 0.0:
		_noel_shake = maxf(0.0, _noel_shake - delta * FX.speed * 2.5)
		hud.queue_redraw()
	_process_touch_zoom()
	if mode in ["idle", "pick", "shift"]:
		overlay.queue_redraw()
	if not G.params.has("autoplay") or _auto_busy or st.is_empty() or mode not in ["idle", "formation"]:
		return
	_auto_t += delta * FX.speed
	if _auto_t < 0.35:
		return
	_auto_t = 0.0
	_auto_busy = true
	await auto_step()
	_auto_busy = false


## 한 수(사람이 끌어 놓는 것과 같은 길 — 카드가 날아가 놓인다). 반환: 한 일
func auto_step() -> String:
	if mode == "formation":
		await _on_start()
		return "start"
	if mode != "idle" or st.result != null:
		return ""
	if int(st.turn) > 60:
		push_error("v2 자동 진행: 60턴이 넘도록 끝나지 않음")
		mode = "over"
		return "stuck"
	var a := RulesV2.auto_step(st)
	match str(a.kind):
		"place":
			if not await _commit_place(str(a.uid), str(a.ally), a.opts):
				await end_turn()
				return "end"
			return "place"
		"cast":
			if not await _commit_cast(str(a.uid), str(a.target), a.opts):
				await end_turn()
				return "end"
			return "cast"
		"move":
			if not RulesV2.can_move(st, str(a.ally), a.to).ok:
				await end_turn()
				return "end"
			_commit_move(str(a.ally), a.to)
			return "move"
	await end_turn()
	return "end"


# ───────── 시험 훅 (core/test_api.gd → witch.v2(명령, …)) ─────────
static func test_call(args: Array) -> Dictionary:
	var b := current
	if b == null or not is_instance_valid(b) or b.st.is_empty():
		return {"ok": false, "reason": "no v2"}
	var cmd := str(args[0]) if args.size() > 0 else "state"
	var a1 := str(args[1]) if args.size() > 1 and args[1] != null else ""
	var a2 := str(args[2]) if args.size() > 2 and args[2] != null else ""
	match cmd:
		"state":
			return b.test_state()
		"geom":
			return b.test_geom(a1, a2)
		"auto":
			if b.mode not in ["idle", "formation"]:
				return {"ok": false, "mode": b.mode}
			b.auto_step()
			return {"ok": true}
		"start":
			b._on_start()
			return {"ok": true}
		"end":
			b._on_end()
			return {"ok": true}
	return {"ok": false, "reason": "unknown"}


func test_state() -> Dictionary:
	var hand_out := []
	for u in st.hand:
		var d := RulesV2.card_def(st, u)
		hand_out.append({"uid": u, "id": st.cards[u].id, "owner": d.owner, "cost": d.cost, "kind": d.kind, "affordable": RulesV2.affordable(st, u)})
	var al := {}
	for id in st.order:
		var a: Dictionary = st.allies[id]
		al[id] = {"hp": a.hp, "maxHp": a.maxHp, "down": a.down, "dead": a.dead, "brace": a.brace, "mult": a.mult, "blessed": a.blessed,
			"col": RulesV2.col_of(st, id), "placed": a.placed.map(func(p): return {"id": st.cards[p.uid].id, "target": p.target})}
	var en := []
	for e in st.enemies:
		en.append({"id": e.id, "type": e.type, "hp": e.hp, "alive": e.alive, "vuln": e.vuln, "intent": e.intent})
	return {"ok": true, "mode": mode, "phase": st.phase, "turn": st.turn, "energy": st.energy, "result": st.result, "loseBy": st.loseBy, "deck": st.draw.size(),
		"hand": hand_out, "slots": st.slots, "bench": st.bench, "noelHp": st.noelHp, "deaths": st.deaths, "postponed": RulesV2.postponed(st),
		"allies": al, "enemies": en, "noel": st.noel.map(func(n): return {"kind": n.kind, "target": n.target}), "pending": not pending.is_empty(),
		"tableCards": table.cards.size(), "handCards": hand.cards.size(), "maxHands": hand.max_hands, "handsNow": hand.hands_visible(), "log": log.slice(maxi(0, log.size() - 30))}


## 화면 좌표(무대 1920×1080): card(손패 카드 id 또는 uid) · ally(동료 카드) · column(그 칸 ③) · slot(그 칸 ④) · bench · enemy · act(적 id·죽음 카드 id)
## · placed("동료:번호") · endTurn · start · again
func test_geom(kind: String, id: String) -> Dictionary:
	var r := Rect2()
	match kind:
		"card":
			for u in hand.cards:
				if u == id or st.cards[u].id == id:
					var c: CardView = hand.cards[u]
					return {"x": c.center().x, "y": c.center().y, "uid": u}
			return {}
		"ally":
			if table.card("ally:" + id) == null:
				return {}
			r = table.screen_rect("ally:" + id)
		"column":
			r = table.rect_at(cell_pos(2, int(id)))
		"slot":
			r = table.rect_at(cell_pos(3, int(id)))
		"bench":
			r = table.rect_at(bench_pos(0))
		"enemy":
			if table.card("e:" + id) == null:
				return {}
			r = table.screen_rect("e:" + id)
			if RulesV2.guard_of(st, id) != null:
				r = Rect2(r.position, Vector2(r.size.x * 0.3, r.size.y))   # 하수인에 가리지 않은 왼쪽 띠
		"act":
			var k := _target_key(id)
			if table.card(k) == null:
				return {}
			r = table.screen_rect(k)
		"placed":
			var pp := id.split(":")
			if pp.size() < 2 or not st.allies.has(pp[0]) or int(pp[1]) >= st.allies[pp[0]].placed.size():
				return {}
			r = table.screen_rect("p:" + st.allies[pp[0]].placed[int(pp[1])].uid)
		"endTurn":
			r = Rect2(end_btn.position, end_btn.size)
		"start":
			r = Rect2(start_btn.position, start_btn.size)
		"again":
			if result_panel == null:
				return {}
			var ab: Control = result_panel.find_child("again", true, false)
			if ab == null:
				return {}
			r = Rect2(ab.position, ab.size)
		_:
			return {}
	return {"x": r.get_center().x, "y": r.get_center().y, "w": r.size.x, "h": r.size.y}
