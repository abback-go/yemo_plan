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
## 게임 모드(밤샘 계획 2 A·B — open_game, core/ctl.gd 가 연다): 1층 전투(encounters)를 게임 상태에서 받은 파티·덱·직전 배치·난수로 연다.
##   그 방의 VN 배경을 탁자 너머에 어둡게 · 튜토리얼 안내(core/guide.gd 의 guideV2) · 어둠(적 행동 카드 몇 장을 뒷면으로) · 거대한 발(세 칸을 덮는 큰 카드)
##   · 죽음 카드에 맞으면 그 동료의 데스신(세라피나 C1~C6 등) · 끝나면 결과 판(이김: 「계속」 / 짐: 「다시 하기」) 뒤 finished 신호(win|lose|giant|retreat)
##   — 게임 상태에 돌려 적는 것은 Ctl(RulesV2.apply_result)
class_name BoardBattle
extends Control

signal finished(result: String)

static var current: BoardBattle = null
var game := {}            # 게임 모드 설정 {battle: new_battle opts, enc, bg} — 비어 있으면 시험 전투(?battle=v2)
var _done := false
var _cut := false          # 데스신이 도는 중(자동 진행 멈춤)
var _hold := {}            # 죽음 연출 전인 동료 id → 보이는 HP (그때까지 산 얼굴로)
# 턴 끝 연출 동안 보이는 값(밤샘 계획 2 D): 규칙은 턴 끝을 한꺼번에 계산해 상태(st)가 이미 마지막 값이라, 연출 중에 앞면을 다시 그리면
# 적 HP·동료 HP·막기가 맞기도 전에 마지막 값으로 바뀌었다 → 턴 끝 직전 값을 적어 두고 사건(맞음·막기·회복…)이 연출될 때마다 그 값으로 옮긴다.
# "e:<적 id>" → {hp} · "ally:<동료 id>" → {hp, block, brace, mult, down} · "noel" → HP. 정리(cleanup) 뒤에는 비운다
var _disp := {}

var st := {}
var mode := "busy"        # formation | idle | drag | shift | move | busy | over
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
var pending := {}         # 놓았지만 옮길 칸을 아직 안 고른 운명 전가 {uid, kind: shift, ally, target}
var drag := {}            # 손패에서 끄는 카드 {uid, start, moved, hot, col, reason}
var mdrag := {}           # 탁자에서 끄는 카드 {kind: ally|act, id, key, start, moved}
var tap := {}             # 누른 탁자 카드 {key, start, t}
var hover_key := ""       # 크게 보기 할 탁자 카드
var spread_cell := ""     # 펼친 칸 ("r:c" · "bench")
var touch := false
var preview_text := ""
var preview_pos := Vector2.ZERO
var preview_cell := Rect2()   # v2.3: 크게 보이는 결과 미리 보기 — 이 칸(화면 사각형) 옆에. 빈 사각형이면 예전처럼 작은 판
var preview_bad := false      # 놓을 수 없는 까닭(붉은 판)
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
var _zoom_sticky := false   # 휴대폰: 탁자 카드를 탭해 띄운 크게 보기 — 다음 터치까지 남는다(밤샘 계획 2 C 0단계)
var _opened_once := false   # 시험 훅 openhand
var _fate_seen := {}        # 2·3층: 이미 안내한 운명의 죽음 카드 id
var log: Array = []


# ───────── 열기 ─────────
static func open(parent: Node, seed = null) -> BoardBattle:
	var b := BoardBattle.new()
	parent.add_child(b)
	b.start(seed)
	return b


## 게임 모드로 연다(core/ctl.gd): cfg {battle: RulesV2.battle_opts(…), enc, bg}. 끝나면 finished(결과)
static func open_game(parent: Node, cfg: Dictionary) -> BoardBattle:
	var b := BoardBattle.new()
	b.game = cfg
	parent.add_child(b)
	b.start(null)
	return b


func _exit_tree() -> void:
	if current == self:
		current = null
		if G.dialog != null:
			G.dialog.guide_mid_y = -1.0   # 이어서 연 전투(가장 깊은 곳 → 거대한 발)가 정한 값은 두고, 마지막 전투가 닫힐 때만
			G.dialog.guide_low_y = -1.0


## 게임 모드의 튜토리얼 안내·대사(core/guide.gd — script_data.gd guideV2). 시험 전투에는 없다
func _guide(on: String, ctx := {}) -> void:
	if game.is_empty() or not is_inside_tree():
		return
	var c := ctx.duplicate()
	c.enc = str(st.enc)
	c.v2 = true
	await G.guide.fire(on, c)


## 게임 모드: 끝내고 게임 흐름(Ctl)에 결과를 넘긴다
func _finish(res: String) -> void:
	if _done:
		return
	_done = true
	mode = "over"
	await FX.fade(1, 400)
	finished.emit(res)


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
	st = RulesV2.new_battle(seed) if game.is_empty() else RulesV2.new_battle(null, game.battle)
	_build()
	note("battle seed=%d" % int(st.seed) if game.is_empty() else "battle %s darkness=%d slots=%s" % [st.enc, int(st.darkness), str(st.slots)])
	# 게임 모드: 밝아지는 동안·안내를 다 읽을 때까지 「출전」을 막는다(자동 진행이 그사이 출전하면 뒤에서 배치 화면으로 되돌아가 멈췄다)
	mode = "formation" if game.is_empty() else "busy"
	_sync_table(false)
	_sync_hud()
	await FX.fade(0, 400)
	if not is_inside_tree():
		return
	FX.banner(T("formation"), 900)
	if not game.is_empty():
		await _guide("battleStart")
		if int(st.darkness) > 0:
			await _guide("darkness")
		if not is_inside_tree():
			return
		await _show_fates()
		if not is_inside_tree():
			return
		mode = "formation"
		_sync_hud()


# ───────── 화면 만들기 ─────────
func _build() -> void:
	table = BoardTable.new()
	table.name = "table"
	add_child(table)
	table.setup()
	var bg := str(game.get("bg", ""))
	if bg != "" and Assets.ok(bg):
		table.set_room(Assets.tex(bg))   # 그 방의 VN 배경을 탁자 너머에 어둡게
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
	end_btn.z_index = 46   # v2.3: 손패를 펼쳐 탁자가 어두워져도 「턴 끝」은 보이고 눌린다(누르면 닫힘)
	add_child(end_btn)
	start_btn = UI.button(T("start"), 36, _on_start)
	start_btn.name = "start"
	start_btn.fit(Vector2(70, 18))
	start_btn.position = Vector2(float(L().start.x), float(L().start.y))
	add_child(start_btn)
	# 안내 상자(게임 모드 튜토리얼): 화면 맨 위에 뜨면 적 줄을 가렸다 → ② 적 행동 줄과 ④ 동료 줄 사이(③ 맡긴 카드 줄 — 안내가 뜰 때는 대개 비어 있다)를 가운데로(밤샘 계획 2 D)
	if G.dialog != null:
		G.dialog.guide_mid_y = (table.rect_at(cell_pos(1, 1)).end.y + table.rect_at(cell_pos(3, 1)).position.y) / 2.0
		G.dialog.guide_low_y = table.rect_at(cell_pos(3, 1)).end.y   # 휴대폰: 안내 상자는 ④ 동료 줄 아래(화면 맨 아래)로 — 0단계


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
	if RulesV2.wide(e):
		return {"kind": "giant", "type": e.type, "name": nm, "hpText": T("unknownHp")}
	var f := {"kind": "minion" if minion else "enemy", "type": e.type, "name": nm, "hp": int(_disp["e:" + str(e.id)].hp) if _disp.has("e:" + str(e.id)) else int(e.hp), "maxHp": int(e.maxHp)}
	if RulesV2.immune(e):
		f.hpText = T("unknownHp")
	return f


func face_act(e: Dictionary) -> Dictionary:
	var it: Dictionary = e.intent
	var sweep: bool = it.kind == "sweep"
	var f := {"kind": "act", "type": e.type, "tag": str(e.tag), "name": str(it.label) + (" · " + T("all") if sweep else ""), "value": int(it.value),
		"minus": int(it.get("minus", 0)), "minion": RulesV2.is_minion(e), "sub": T("all") if sweep else str(it.get("sub", ""))}
	if it.kind == "none":
		f.noValue = true
	if bool(it.get("erased", false)):
		f.erased = true
		f.sub = T("erased")
	if str(it.get("reflect", "")) != "":
		f.sub = T("reflected")   # 꿰뚫린 방패: 막고 되돌린다
	return f


func face_death(d: Dictionary) -> Dictionary:
	var tx := T("deathFixed") if bool(d.get("fixed", false)) else T("deathMark")
	if RulesV2.is_fate(d):
		tx = T("fateMark", {"sub": str(d.get("sub", ""))})   # 2·3층 운명: 「운명의 관통 · 옮길 수 없음」
	return {"kind": "death", "name": str(d.label), "art": str(D().death.art.get(str(d.ally), "")), "text": tx}


func face_mine(uid: String, fc := {}) -> Dictionary:
	var d: Dictionary = RulesV2.card_def(st, uid)
	var f := RulesV2.mine_face(d)
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
	var held := _hold.has(id)   # 죽음 연출 전: 상태는 이미 「죽음」이어도 그 순간까지는 산 얼굴(직전 HP)로
	if a.dead and not held:
		return {"kind": "dead", "name": G.name_of(id), "art": str(D().portraits[id].img), "deadText": T("dead")}
	var dv: Dictionary = _disp.get("ally:" + id, {})
	var f := {"kind": "ally", "name": G.name_of(id), "art": str(D().portraits[id].img), "hp": int(_hold[id]) if held else int(dv.get("hp", a.hp)), "maxHp": int(a.maxHp),
		"block": int(dv.get("block", a.block)), "trait": str(tr.name), "text": str(tr.text), "down": bool(dv.get("down", a.down)) and not held, "downText": T("down")}
	match str(a.trait):
		"brace":
			f.statusLabel = T("brace")
			f.statusValue = str(dv.get("brace", a.brace))
		"aim":
			f.statusLabel = T("mult")
			f.statusValue = "×" + str(dv.get("mult", a.mult))
	return f


## 턴 끝 직전에 보이던 값(_disp) — 연출이 사건마다 옮긴다
func _disp_snapshot() -> Dictionary:
	var d := {"noel": int(st.noelHp)}
	for e in st.enemies:
		if e.alive:
			d["e:" + str(e.id)] = {"hp": int(e.hp)}
	for id in st.order:
		var a: Dictionary = st.allies[id]
		d["ally:" + id] = {"hp": int(a.hp), "block": int(a.block), "brace": int(a.brace), "mult": int(a.mult), "down": bool(a.down)}
	return d


## 사건 하나가 보이는 값을 옮긴다 (key 가 _disp 에 있을 때만 — 턴 끝 연출 중)
func _disp_set(key: String, vals: Dictionary) -> void:
	if _disp.has(key):
		var d: Dictionary = _disp[key]
		for k in vals:
			d[k] = vals[k]


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
			if RulesV2.wide(e):   # 거대한 발: 세 칸을 덮는 큰 카드(가운데 칸에 놓고 양옆으로)
				var tc: Array = TL().cols
				pile.append({"key": "e:" + e.id, "face": face_enemy(e), "flip": 0.0, "pick": e.alive,
					"size": Vector2(float(tc[tc.size() - 1]) - float(tc[0]) + float(TL().card[0]) - 0.1, float(TL().card[1]))})
				_noel_on(pile, e.id, "vuln")
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
			var hid := 1.0 if bool(e.intent.get("hidden", false)) else 0.0   # 어둠: 뒷면
			if e.intent.kind in ["hit", "none"] and int(e.intent.slot) == c:
				pile2.append({"key": "a:" + e.id, "face": face_act(e), "flip": hid, "pick": true})
				_noel_on(pile2, e.id, "act")
			elif e.intent.kind == "sweep":
				pile2.append({"key": "a:%s#%d" % [e.id, c], "face": face_act(e), "flip": hid, "pick": true})
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
		if (what == "vuln" and k == "vuln") or (what == "bless" and k == "bless") or (what == "act" and k in ["curse", "shift", "tear", "reflect"]):
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
			c = table.make_card(key, w.face, w.pos, w.get("size", Vector2.ZERO))
			c.flip = float(w.flip)
			c.tflip = float(w.flip)
			if w.get("back", false):
				c.set_back(table.back_tex, Color(0.92, 0.6, 0.6))   # 적 덱: 붉게(노엘의 덱과 가르게 — 밤샘 계획 2 D: 새 뒷면은 원래 어두워 옅게)
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
	var back := BoardPieces.back_tex()
	var n: int = st.draw.size()
	for i in mini(3, maxi(1, n)):
		var r := Rect2(float(Dk.x) - i * 4, float(Dk.y) - i * 5, float(Dk.w), float(Dk.h))
		if back != null:
			hud.draw_texture_rect(back, r, false, Color(0.85, 0.8, 0.82, 1.0 if n > 0 else 0.35))
	BoardPieces.text_in(hud, Rect2(float(Dk.x) - 30, float(Dk.y) + float(Dk.h) + 2, float(Dk.w) + 60, 30), T("deck", {"n": n}), 22, Color("#efe3e5"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
	# 노엘 HP: 붉은 봉인 (빈칸 공격을 맞으면 흔들림)
	var nc := noel_center() + Vector2(sin(_noel_shake * 40.0) * 10.0 * _noel_shake, 0)
	BoardPieces.text_in(hud, Rect2(nc.x - 90, nc.y - 92, 180, 30), T("noel"), 24, Color("#f3dcec"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
	var nhp := int(_disp.get("noel", st.noelHp))
	BoardPieces.seal(hud, nc, 44, Color("#8e1220") if nhp > 5 else Color("#c0121f"), str(nhp), 36, "/" + str(st.noelMax))
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
			# 어둠에 뒷면인 행동이 있으면 합계는 「?」
			var hid := sw != null and bool(sw.intent.get("hidden", false))
			for eid in ids:
				if bool(RulesV2.enemy(st, eid).intent.get("hidden", false)):
					hid = true
			var shown := T("hiddenValue") if hid else str(inc)
			var top := table.to_screen(cell_pos(1, c) + Vector3(0, 0, -ch / 2.0 - 0.06))
			var txt := T("total", {"n": shown}) if cnt >= 2 else ""
			if noel:
				txt = (txt + " → " if txt != "" else "→ ") + T("toNoel") + " " + shown
			var f := Assets.font("sans_bold")
			var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22) + Vector2(24, 10)
			var r := Rect2(top - Vector2(sz.x / 2.0, sz.y + 2), sz)
			overlay.draw_style_box(UI.box(Color(0.1, 0.0, 0.02, 0.92), Color("#ff4b5a") if noel else Color("#a8323e"), 8, 2), r)
			BoardPieces.text_in(overlay, r, txt, 22, Color("#ffd9dc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
	if preview_text != "" and preview_cell.has_area():
		_draw_big_preview()
	elif preview_text != "":
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


## v2.3 결과 미리 보기(크게): 첫 줄(예 「저격 21」) 46px · 다음 줄(대상 등) 30px, 어두운 판을 칸 오른쪽(자리가 없으면 왼쪽)에
func _draw_big_preview() -> void:
	var f := Assets.font("sans_bold")
	var lines := preview_text.split("\n")
	var sizes: Array = []
	var w := 0.0
	var h := 0.0
	for i in lines.size():
		var fs := 46 if i == 0 else 30
		sizes.append(fs)
		w = maxf(w, f.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		h += f.get_height(fs)
	var sz := Vector2(w + 44, h + 24)
	var c := preview_cell
	var x := c.end.x + 18.0
	if x + sz.x > 1900.0:
		x = c.position.x - 18.0 - sz.x
	var r := Rect2(Vector2(x, c.get_center().y - sz.y / 2.0), sz)
	overlay.draw_style_box(UI.box(Color(0.0, 0.0, 0.0, 0.55), Color.TRANSPARENT, 16), Rect2(r.position + Vector2(5, 8), r.size))
	overlay.draw_style_box(UI.box(Color(0.05, 0.02, 0.02, 0.95), Color("#ff4b5a") if preview_bad else BoardPieces.GOLD, 14, 3), r)
	var y := r.position.y + 12.0
	for i in lines.size():
		var lh := f.get_height(sizes[i])
		var col := Color("#ffd9dc") if preview_bad else (Color("#ffdf8a") if i == 0 else Color("#efe3e5"))
		BoardPieces.text_in(overlay, Rect2(r.position.x, y, r.size.x, lh), lines[i], sizes[i], col, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
		y += lh


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
	if key == "":
		_zoom_sticky = false
	var f := {}
	if key != "":
		var c: BoardTable.Card3D = table.card(key)
		if c != null and not (c.flip > 0.5) and not str(c.face.get("kind", "")) in ["slot", "giant"]:
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
		# 안내 상자가 떠 있으면 어디를 눌러도 넘긴다(그동안 카드는 놓을 수 없다)
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and G.dialog.guide_open():
			G.dialog.advance()
			accept_event()
			return
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
	# 휴대폰: 탭으로 띄운 크게 보기는 다음 터치에 닫는다(손패를 누른 것이 아니면 그 터치는 닫기만)
	if touch and _zoom_sticky:
		_set_zoom("")
		_set_spread("")
		if mode != "idle" or hand.hit_test(p) == "":
			return
	if mode == "drag":
		_cancel_drag()
	match mode:
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
		if uid != "" and touch and not hand.open:
			# 휴대폰(터치): 닫힌 손패는 카드가 겹쳐 손가락 아래에 옆 카드가 걸려 집혔다 → 누르면 먼저 펼친다. 카드는 펼친 손패에서 끈다(밤샘 계획 2 C 0단계)
			hand.set_open(true)
			_set_zoom("")
			return
		if uid != "":
			drag = {"uid": uid, "start": p, "moved": false, "hot": "", "col": -1, "open": hand.open}
			mode = "drag"
			hand.hover_uid = ""
			hand.lifted_uid = uid if hand.open else ""
			_set_zoom("")
			hand.layout()
			return
		if hand.open:
			hand.set_open(false)   # v2.3: 펼친 손패 — 빈 곳을 누르면 닫는다
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
				# v2.3: 펼친 손패에서 끌면 손이 내려가고(닫힘) 끄는 카드는 펼친 크기 그대로
				hand.drag_k = hand.open_scale() if bool(drag.get("open", false)) else 0.0
				hand.set_open(false)
				hand.drag_uid = drag.uid
				hand.drag_mode = "follow"
			if drag.moved:
				hand.drag_pos = p
				hand.layout()
				_update_drag_hot(p)
		"idle", "formation":
			if is_touch or touch:
				# 터치: 길게 누르면 크게 보기 · 그 칸 펼치기(_process_touch_zoom). 마지막 누름이 터치였으면(touch) 움직임도 터치로 본다 —
				# 웹에서 터치로 끄는 움직임이 마우스 움직임(DEVICE_ID_EMULATION 아님)으로 와서, 펼친 손패 밖으로 나가면 닫는 PC 처리가 막 펼친 손패를 닫았다(0단계 시험에서 찾음)
				return
			var hu := hand.hit_test(p) if mode == "idle" else ""
			# v2.3: PC 는 손패 위에 마우스를 올려도 펼친다 · 펼친 곳 밖으로 나가면 닫는다
			if hand.open and not hand.open_area().has_point(p):
				hand.set_open(false)
				hu = hand.hit_test(p)
			if hu != "" and not hand.open:
				hand.set_open(true)
			hand.set_hover(hu if hand.open else "")
			if hu != "" or hand.open:
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
		var mk := str(mdrag.key) if not bool(mdrag.moved) else ""
		_up_mdrag(p)
		if touch and mk != "" and mode in ["idle", "formation"]:
			_tap_zoom(mk, t2.get("start", p))
		return
	if mode == "drag":
		if drag.is_empty():
			mode = "idle"
			return
		if not drag.moved:
			_cancel_drag()
			hand.set_open(true)   # v2.3: 손패를 탭하면 왼손을 당겨와 크게 펼친다(펼친 채 카드를 탭하면 그대로)
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
		elif touch:
			_tap_zoom(key, t2.start)
	elif mode in ["idle", "formation"] and touch and not t2.is_empty():
		# 휴대폰: 길게 눌러 띄운 크게 보기도 손을 떼면 그대로 남긴다(맡긴 카드·노엘 카드 포함 — 짧은 탭은 되돌리기라). 배치 화면은 탭도
		if absf(p.x - t2.start.x) + absf(p.y - t2.start.y) <= _move_thresh():
			_tap_zoom(str(t2.key), t2.start, long_press)


## 휴대폰: 탁자 카드를 한 번 탭하면 크게 보기(탁자 위 설명 글씨가 작다 — 길게 누르기 말고도). 맡긴 카드·노엘 카드는 탭이 「손패로 되돌리기」라 그대로 길게 누르기
func _tap_zoom(key: String, p: Vector2, placed_too := false) -> void:
	if key == "" or key.begins_with("slot:") or key.begins_with("deck:") or ((key.begins_with("p:") or key.begins_with("n:")) and not placed_too):
		return
	_set_zoom(key, p)
	if _zoom_face.is_empty():
		return
	_zoom_sticky = true
	var cell := str(_cell_of.get(key, ""))
	if cell != "" and _pile_size(cell) > 1:
		_set_spread(cell)


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
		_guide("redirect")   # 처음 맞을 자리를 바꿨을 때 — 세라피나 「좋아, 그거야.」
	_set_idle()


# ───────── 손패 카드 끌기 ─────────
## 끄는 카드가 지금 놓일 곳(drag.hot) — 동료 카드는 칸(그 칸의 동료), 노엘의 카드는 ②·①·④ 의 그 대상. 놓일 수 있는 곳은 금빛
func _update_drag_hot(p: Vector2) -> void:
	var uid: String = drag.uid
	var d := RulesV2.card_def(st, uid)
	var hot := ""
	var reason := ""
	preview_text = ""
	preview_cell = Rect2()
	preview_bad = false
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
			preview_text = _noel_tag(d, kind)
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
			preview_cell = table.rect_at(cell_pos(2, col))
			if chk2.ok:
				hot = RulesV2.ally_at(st, col)
				preview_text = _preview_line(uid, hot)
			else:
				reason = chk2.reason
				if reason in ["noFront", "notOwner", "down", "noEnergy"]:
					preview_text = str(D().reasons.get(reason, reason))
					preview_bad = true
	drag.hot = hot
	drag.reason = reason
	overlay.queue_redraw()


## 노엘의 카드를 대상 위로 끌 때의 짧은 미리 보기
func _noel_tag(d: Dictionary, kind: String) -> String:
	match kind:
		"curse":
			return T("tagCurse", {"n": int(d.get("minus", 0))})
		"stomp":
			return T("tagStomp", {"n": int(d.get("damage", 0))})
		"heal":
			return T("tagHeal", {"n": int(d.get("heal", 0))})
		"erase":
			return T("tagErase")
		"reflect":
			return T("tagReflectAll") if bool(d.get("all", false)) else T("tagReflect")
	return T({"bless": "tagBless", "vuln": "tagVuln", "shift": "tagShift", "tear": "tagTear"}.get(kind, "tagShift"))


func _preview_line(uid: String, ally: String) -> String:
	var d := RulesV2.card_def(st, uid)
	var r := RulesV2.forecast_place(st, uid, ally)
	var nm := str(d.name)
	match str(d.kind):
		"attack", "release":
			var s := "%s %d" % [nm, int(r.get("dmg", 0))]
			if int(r.get("block", 0)) > 0:
				s += " · " + T("block", {"n": r.block})
			var te = RulesV2.front_of(st, ally, uid)   # 9-6: 앞(같은 열) 적
			if te != null:
				s += "\n→ " + str(face_enemy(te).name)
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
	preview_cell = Rect2()
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
	hand.drag_k = 0.0
	preview_text = ""
	preview_cell = Rect2()
	prompt_text = ""
	if mode == "drag":
		mode = "idle"
	_sync_table()
	overlay.queue_redraw()
	hand.layout()


func _cancel_all() -> void:
	if mode == "drag":
		_cancel_drag()
	elif mode == "shift":
		_cancel_pending()


# ───────── 놓기 ─────────
## 손패 카드를 그 대상(동료 id · 적 행동/죽음/적 id · 동료 id)에 놓는다
func _drop(uid: String, hot: String) -> void:
	drag = {}
	hand.drag_uid = ""
	hand.drag_mode = ""
	hand.lifted_uid = ""
	hand.drag_k = 0.0
	var d := RulesV2.card_def(st, uid)
	if str(d.owner) == "noel":
		if str(d.kind) == "shift":
			await _start_pending_shift(uid, hot)
		else:
			await _commit_cast(uid, hot, {})
		return
	await _commit_place(uid, hot, {})   # 9-6: 공격은 앞(같은 열) 적에게 자동 — 대상을 고르지 않는다


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
	var res2 := RulesV2.cast(st, pd.uid, pd.target, opts)
	var ok: bool = res2.ok
	if ok:
		note("cast %s %s %s" % [st.cards[pd.uid].id, pd.target, str(opts)])
		_guide("redirect")   # 처음 운명 전가로 옮겼을 때 — 세라피나 「좋아, 그거야.」
	else:
		_toast_reason(res2.reason)
	if not ok:
		var k: String = "n:" + str(pd.uid)
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
	var k: String = "n:" + str(pd.uid)
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
	if mode != "formation" or G.dialog.guide_open():
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
	await _guide("turnStart", {"turn": st.turn})
	_set_idle()


func _on_end() -> void:
	if G.dialog.guide_open():
		return
	hand.set_open(false)
	if mode == "shift":
		_cancel_pending()
	if mode == "drag":
		_cancel_drag()
	if mode != "idle" or st.result != null:
		return
	await end_turn()


func end_turn() -> void:
	mode = "busy"
	hand.set_open(false)
	hand.set_hover("")
	_set_zoom("")
	spread_cell = ""
	_sync_table()
	_sync_hud()
	note("endTurn %d" % int(st.turn))
	_hand_snap = st.hand.duplicate()
	_disp = _disp_snapshot()
	var evs := RulesV2.end_turn(st)
	if not evs.any(func(x): return str(x.t) == "cleanup"):
		_hand_snap = null
	await _play(evs)
	_hand_snap = null
	_disp = {}
	if not is_inside_tree():
		return
	if st.result != null:
		_show_result()
		return
	await _guide("enemyPhaseEnd")
	await _play(RulesV2.start_turn(st))
	await _guide("turnStart", {"turn": st.turn})
	_set_idle()


# ───────── 연출 ─────────
func _play(events: Array) -> void:
	# 뽑을 카드는 뽑는 연출 전까지 손패에 보이지 않게 · 죽음 연출 전까지 그 동료는 산 얼굴로(_hold)
	for e in events:
		if str(e.t) == "draw":
			_hidden.append_array(e.uids)
		elif str(e.t) == "death" and table.card("ally:" + str(e.ally)) != null:
			_hold[str(e.ally)] = int(table.card("ally:" + str(e.ally)).face.get("hp", 0))
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
		var c := table.make_card(key, w.face, deck_pos(4), w.get("size", Vector2.ZERO))
		c.flip = 1.0
		c.tflip = 1.0
		c.set_prio(int(w.prio))
		c.position = deck_pos(4) + Vector3(0, 0.1, 0)
		var death: bool = key.begins_with("d:")
		c.fly_to(w.pos, 420 if not death else 620, 0.7 if not death else 1.2, float(w.get("flip", 0.0)) < 0.5)   # 어둠: 뒷면 그대로
		n += 1
		await FX.wait(110 if not death else 520)
		if death:
			FX.flash("#8a0010", 300, 0.4)
			FX.toast(str(w.face.name) + " — " + str(w.face.text).replace("\n", " · "), 1600)
	if n > 0:
		await FX.wait(420)
	_sync_table()
	_sync_hud()
	await FX.wait(200)
	# 2·3층: 운명의 죽음 카드가 처음 놓였을 때 안내
	var fresh := false
	for dd in st.deaths:
		if RulesV2.is_fate(dd) and not _fate_seen.has(str(dd.id)):
			_fate_seen[str(dd.id)] = true
			fresh = true
	if fresh:
		await _guide("fateIntent")


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
	_disp_set(key, {"hp": int(e.hp)})
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
	_disp_set(key, {"hp": 0})
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
	_disp_set("ally:" + str(e.ally), {"block": int(e.total)})
	_refresh_faces()
	_float_at("ally:" + str(e.ally), T("block", {"n": e.amount}), "small", -60)
	await FX.wait(200)


func _ev_mult(e: Dictionary) -> void:
	_disp_set("ally:" + str(e.ally), {"mult": int(e.mult)})
	_refresh_faces()
	await FX.wait(140)


func _ev_brace(e: Dictionary) -> void:
	_disp_set("ally:" + str(e.ally), {"brace": int(e.brace)})
	_refresh_faces()
	await FX.wait(80)


func _ev_win(_e: Dictionary) -> void:
	await FX.wait(300)


func _ev_enemyPhase(_e: Dictionary) -> void:
	FX.banner(T("enemyTurn"), 700)
	await FX.wait(420)


## 적 행동 카드가 노린 칸의 동료 카드로(빈칸이면 노엘 — 화면 쪽으로) 날아가 부딪히고 사라진다
func _ev_enemyAct(e: Dictionary) -> void:
	if str(e.kind) in ["summon", "death", "none", "erased"]:
		await FX.wait(160)
		return
	if str(e.kind) == "reflected":
		# 꿰뚫린 방패: 적 행동 카드가 그 적에게 되돌아간다
		var ek: BoardTable.Card3D = table.card("e:" + str(e.enemy))
		for k in table.cards.keys():
			if (k == "a:" + str(e.enemy) or k.begins_with("a:" + str(e.enemy) + "#")) and ek != null:
				var rc: BoardTable.Card3D = table.card(k)
				table.cards.erase(k)
				rc.dying = true
				rc.set_prio(110)
				rc.fly_to(ek.tpos + Vector3(0, 0.25, 0.2), 300, 0.4)
				var nn := rc
				get_tree().create_timer(FX.ms(330) / 1000.0, false).timeout.connect(func(): if is_instance_valid(nn): nn.free_all())
		FX.flash("#c9a24a", 200, 0.3)
		await FX.wait(340)
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
		c3.fly_to(to, 260, 0.35, true)   # 어둠에 뒷면이던 카드도 맞는 순간 뒤집혀 보인다
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
	if _hold.has(str(e.ally)):
		_hold[str(e.ally)] = int(e.hp)
	_disp_set(key, {"hp": int(e.hp), "block": int(e.block)})
	if c != null:
		c.set_face(face_ally(str(e.ally)))
		c.hit_shake(1.2)
	if int(e.amount) > 0:
		_float_at(key, -int(e.amount), "ally")
	if int(e.blocked) > 0:
		_float_at(key, T("blocked", {"n": e.blocked}), "small", -70)
	await FX.wait(260)


func _ev_noelHit(e: Dictionary) -> void:
	if _disp.has("noel"):
		_disp.noel = int(e.hp)
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
	_disp_set("ally:" + str(e.ally), {"down": true, "hp": 0})
	var c: BoardTable.Card3D = table.card("ally:" + str(e.ally))
	if c != null:
		c.set_face(face_ally(str(e.ally)))
	await FX.wait(320)
	await _guide("allyDown")


## 죽음 카드: 그 동료 카드 위로 내려앉는다 → 그 동료의 데스신(battle_v2_data deathScenes — 세라피나 C1~C6 · 브룬힐드 W1·W2 · 엘리안 A1·A2)
## → 동료 카드가 「죽음」으로 뒤집힌다(데스신이 없으면 이 뒤집기만). 시험 전투는 그 뒤 전투가 이어진다.
## 피할 수 없는 죽음(게임 1층 거대한 발 — fixed): 화면이 멈추고 「알고 있었는데.」(대본 v3 5.2) → 데스신 → 사망 직후(_after_death) → 물러남
func _ev_death(e: Dictionary) -> void:
	var dk := "d:" + str(e.id)
	var who := str(e.ally)
	var ak := "ally:" + who
	var d3: BoardTable.Card3D = table.card(dk)
	var a3: BoardTable.Card3D = table.card(ak)
	var tut := bool(e.get("fixed", false)) and not game.is_empty()
	FX.banner(str(e.label), 1200)
	if d3 != null and a3 != null:
		d3.set_prio(115)
		await d3.fly_to(a3.tpos + Vector3(0, 0.05, 0), 520, 0.9)
		FX.flash("#6a0008", 380, 0.55)
		table.push_out(dk, Vector3(0, 0.5, -0.2), 300)
	elif d3 != null:
		table.push_out(dk, Vector3(0, 0.5, -0.2), 300)
	_hold.erase(who)
	if tut:
		await G.dialog.say(_fate_lines(who, "trap"))   # 속마음 — 안내 상자는 띄우지 않는다
	var key := str(D().deathScenes.get(who, ""))
	if key != "" and (key == "hero" or GameData.D.deathScenes.has(key)) and is_inside_tree():
		note("deathscene " + key)
		G.dialog.clear()
		_cut = true
		G.scenes.cutscene(key, int(e.get("level", 1)))   # 2·3층: 2단계 죽음이면 더 어둡게 + 창/불 덧그림
		await G.scenes.cutscene_done
		await G.scenes.close_cutscene(float(GameData.D.cutscene.returnDelay))
		_cut = false
		if not is_inside_tree():
			return
	a3 = table.card(ak)
	if a3 != null:
		await a3.flip_swap(face_ally(who), 520)
	if tut:
		await _after_death(who, str(e.label))
	elif RulesV2.is_fate(e):
		await _after_fate_death(who, str(e.fate))
	await FX.wait(500)


## 그 동료의 운명(GameData fates) id ("" = 없음)
func _fate_of(who: String) -> String:
	for fid in GameData.D.fates:
		if str(GameData.D.fates[fid].who) == who:
			return str(fid)
	return ""


## 그 동료 운명의 대사(script_data.gd fate.<운명>.<kind> — trap: 「알고 있었는데.」)
func _fate_lines(who: String, kind: String) -> Array:
	return G.S.fate.get(_fate_of(who), {}).get(kind, [])


## 1층 세라피나의 죽음 직후(대본 v3 5.4): 노엘의 손에 남은 카드 — 이제야 문구가 보인다 → 사망 직후 안내 → 얻은 카드(상속 짓밟힘 · 유품) → 남은 동료의 반응.
## 덱에 실제로 넣는 것은 전투가 끝난 뒤 게임(RulesV2.apply_result → ally_died)
func _after_death(who: String, label: String) -> void:
	var fid := _fate_of(who)
	var cid := str(GameData.D.fates.get(fid, {}).get("card", ""))
	var txt := str(GameData.D.cards.get(cid, {}).get("text", ""))
	var df := face_death({"label": label, "ally": who})
	df.text = txt
	await G.scenes.card_gain([{"face": df}], "note", str(G.S.deathCardShown).replace("{card}", label).replace("{text}", txt))
	await _guide("afterDeath", {"card": cid})
	var gain := []
	var inh := str(D().fromV1.get(str(GameData.D.fates.get(fid, {}).get("inherit", "")), ""))
	if inh != "":
		gain.append({"face": RulesV2.mine_face(RulesV2.def_of(inh))})
	for k in D().relicMap:
		if str(D().cards[k].owner) == who:
			gain.append({"face": RulesV2.mine_face(RulesV2.def_of(str(D().relicMap[k])))})
	if not gain.is_empty():
		var names: Array = gain.map(func(g): return "「" + str(g.face.name) + "」")
		await G.scenes.card_gain(gain, "inherit", T("gained", {"list": "·".join(names)}))
	await G.dialog.say(G.S.reactions)


# ───────── 2·3층 운명 (밤샘 계획 2 C) ─────────
## 전투가 열릴 때: 이 전투에서 올 운명의 죽음 카드(노엘이 쥔 죽음)를 보여 준다 — 3층은 두 장(브룬힐드 Lv2 · 엘리안 Lv1, 옛 「두 죽음 카드」 장면)
func _show_fates() -> void:
	var fs: Dictionary = RulesV2.enc_def(st).get("fates", {})
	var turns: Array = fs.keys().map(func(k): return int(k))
	turns.sort()
	var items := []
	var names := []
	for t in turns:
		var fx: Dictionary = fs[str(t)]
		var rec = RulesV2._fate_rec(st, str(fx.fate))
		if rec == null or st.allies[str(rec.ally)].dead:
			continue
		var lab := RulesV2.death_label(str(rec.ally)) + (" Lv%d" % int(rec.level) if int(rec.level) >= 2 else "")
		var en = RulesV2.enemy(st, str(fx.enemy))
		var enm := str(face_enemy(en).name) if en != null else ""
		items.append({"face": {"kind": "death", "name": lab, "art": str(D().death.art.get(str(rec.ally), "")), "text": T("fateWhen", {"sub": str(fx.get("sub", "")), "n": t, "enemy": enm})}})
		names.append(lab)
	if items.is_empty():
		return
	note("fates held " + ",".join(names))
	await G.scenes.card_gain(items, "note", T("fatesHeld", {"list": " · ".join(names)}))
	await _guide("fateBattle")
	if items.size() > 1:
		await _guide("twoDeathCards")


## 집행자가 쓰러졌다: 운명의 죽음 카드는 남아 동료를 따라가고, 아직 내지 않은 운명도 지금 나온다
func _ev_fateRelease(e: Dictionary) -> void:
	await G.dialog.say(G.S.fate.get("dying", []))
	var want := _layout()
	var from := deck_pos(4)
	var ek: BoardTable.Card3D = table.card("e:" + str(e.enemy))
	if ek != null:
		from = ek.tpos
	for id in e.ids:
		var k := "d:" + str(id)
		if table.card(k) != null or not want.has(k):
			continue
		var w: Dictionary = want[k]
		var c := table.make_card(k, w.face, from + Vector3(0, 0.1, 0))
		c.set_prio(int(w.prio))
		c.fly_to(w.pos, 620, 1.2)
		await FX.wait(520)
		FX.flash("#8a0010", 300, 0.4)
	await FX.wait(300)


## 운명의 시도(적 턴 끝 — 그 동료가 칸에 있을 때): 죽음 카드가 그 동료 카드 위로 → 속마음 → 받아들인다/거스른다(옛 선택 화면) → 그 결과와 남은 턴 끝
func _ev_fateTrial(e: Dictionary) -> void:
	var who := str(e.ally)
	var fid := str(e.fate)
	var lv := int(e.get("level", 1))
	var d3: BoardTable.Card3D = table.card("d:" + str(e.id))
	var a3: BoardTable.Card3D = table.card("ally:" + who)
	note("fate trial %s lv%d" % [fid, lv])
	FX.banner(str(e.label), 1100)
	if d3 != null and a3 != null:
		d3.set_prio(115)
		await d3.fly_to(a3.tpos + Vector3(0, 0.3, -0.35), 560, 1.1)
		FX.flash("#6a0008", 320, 0.45)
		FX.shake(6, 300)
	_cut = true
	var L: Dictionary = G.S.fate.get(fid, {})
	await G.dialog.say(L.trap2 if lv >= 2 and L.has("trap2") else L.get("trap", []))
	await _guide("fateFirst")
	var choice := "defy"
	var f = Rules.fate_by_id(G.ctl.st, fid) if not game.is_empty() and not G.ctl.st.is_empty() else null
	if f != null and is_inside_tree():
		choice = await G.scenes.fate_choice(f)
	_cut = false
	if not is_inside_tree():
		return
	note("fate %s %s" % [fid, choice])
	await _play(RulesV2.fate_choice(st, choice))


## 받아들인 운명의 죽음 뒤(데스신 다음): 남은 동료의 반응 · 받아들인 뒤의 말(옛 fate.<운명>.offered) — 죽은 동료는 말하지 않는다
func _after_fate_death(who: String, fid: String) -> void:
	var lines := []
	var src: Array = G.S.get("reactionsBy", {}).get(who, []) + G.S.fate.get(fid, {}).get("offered", [])
	for ln in src:
		var w := str(ln.get("who", ""))
		if st.allies.has(w) and st.allies[w].dead:
			continue
		if lines.any(func(x): return str(x.text) == str(ln.text)):
			continue
		lines.append(ln)
	await G.dialog.say(lines)


## 받아들인 운명: 상속 카드(같은 Lv — 다음 턴에 손에 든다)와 그 동료의 유품 → 카드 획득 화면 → 사망 직후 안내
func _ev_fateGain(e: Dictionary) -> void:
	var gain := []
	var seen := {}
	for u in e.inherit + e.relics:
		var key := str(st.cards[u].id) + str(st.cards[u].get("lv", 1))
		if seen.has(key):
			continue
		seen[key] = true
		gain.append({"face": RulesV2.mine_face(RulesV2.card_def(st, u))})
	if not gain.is_empty():
		var names: Array = gain.map(func(g): return "「" + str(g.face.name) + "」")
		await G.scenes.card_gain(gain, "inherit", T("gained", {"list": "·".join(names)}))
	await _guide("afterDeath", {"card": str(GameData.D.fates.get(str(e.fate), {}).get("card", ""))})
	_sync_table()


## 거슬렀다: 죽음 카드가 찢겨 흩어진다 → 흉터(뽑을 더미에 섞였다) → 거스른 뒤의 말 → 흉터 안내
func _ev_fateDefied(e: Dictionary) -> void:
	var dk := "d:" + str(e.id)
	var d3: BoardTable.Card3D = table.card(dk)
	FX.flash("#ff2a3c", 240, 0.5)
	FX.shake(12, 420)
	if d3 != null:
		var r := table.screen_rect(dk)
		if r.has_area():
			FX.burst(r.get_center().x, r.get_center().y, {"count": 40, "colors": ["#ff2a3c", "#ff8a90", "#2a0006"], "speed": 480, "life": 700, "size": 4, "gravity": 300, "shape": "line"})
		table.push_out(dk, Vector3(0, 0.8, -0.6), 260)
	FX.banner(T("fateDefied"), 900)
	await FX.wait(500)
	var scars: Array = e.scars.map(func(u): return {"face": RulesV2.mine_face(RulesV2.card_def(st, u))})
	if not scars.is_empty():
		await G.scenes.card_gain(scars, "scar")
	var L: Dictionary = G.S.fate.get(str(e.fate), {})
	await G.dialog.say(L.get("defied", []))
	await _guide("scarFirst")
	hud.queue_redraw()


## 꿰뚫린 방패: 막은 피해만큼 그 적에게(이어서 hit 이 맞는 연출)
func _ev_reflect(e: Dictionary) -> void:
	_float_at("e:" + str(e.enemy), T("reflected"), "small", -60)
	await FX.wait(120)


func _ev_immune(e: Dictionary) -> void:
	var key := "e:" + str(e.enemy)
	var c: BoardTable.Card3D = table.card(key)
	if c != null:
		c.hit_shake(0.4)
	_float_at(key, T("immune"), "small", -40)
	_guide("immune")   # 처음 쳤을 때 — 브룬힐드 「흠집밖에 안 나.」
	await FX.wait(260)


## 짓밟힘(노엘): 모든 적에게
func _ev_noelAct(_e: Dictionary) -> void:
	FX.flash("#ff2a3a", 220, 0.4)
	FX.shake(18, 420)
	await FX.wait(260)


func _ev_heal(e: Dictionary) -> void:
	var key := "ally:" + str(e.ally)
	var c: BoardTable.Card3D = table.card(key)
	_disp_set(key, {"hp": int(e.hp)})
	if c != null:
		c.set_face(face_ally(str(e.ally)))
	_float_at(key, T("heal", {"n": e.amount}), "small", -60)
	await FX.wait(260)


## 노엘 HP 를 대가로(유품·이름 없는 마녀의 카드)
func _ev_noelPay(e: Dictionary) -> void:
	if _disp.has("noel"):
		_disp.noel = int(e.hp)
	var nc := noel_center()
	FX.float_text(nc.x, nc.y - 60, T("noelPay", {"n": e.amount}), "small")
	_noel_shake = 0.6
	hud.queue_redraw()
	await FX.wait(220)


## 가장 깊은 곳: 광신도가 하나 남으면 구멍 위의 어둠이 내려온다 — 발. 남은 광신도가 한 번에 사라진다(대본 v3 5.1)
func _ev_giant(e: Dictionary) -> void:
	G.dialog.say(G.S.giantAppear.get("before", []))
	for i in 3:
		FX.shake(4 + i * 2, 300)
		await FX.wait(380)
	var foot := TextureRect.new()
	foot.texture = BoardPieces.tex("spr_giant_foot.png")
	foot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.modulate = Color(0.22, 0.18, 0.18, 0.96)
	foot.size = Vector2(1100, 900)
	foot.z_index = 150
	var vx := 960.0
	var vy := 200.0
	for vid in e.victims:
		var r := table.screen_rect("e:" + str(vid))
		if r.has_area():
			vx = r.get_center().x
			vy = r.end.y
	foot.position = Vector2(vx - 550, -950)
	add_child(foot)
	var a := FX.anim(380, [{"y": -950.0}, {"y": vy - 860.0}], func(v): if is_instance_valid(foot): foot.position.y = v.y, {"node": foot, "easing": "ease-in"})
	await FX.until(a)
	FX.flash("#ffffff", 200, 0.55)
	FX.shake(30, 800)
	FX.burst(vx, vy, {"count": 70, "colors": ["#8a8580", "#6a6560", "#4a4540"], "speed": 620, "spread": PI * 1.1, "angle": -PI / 2, "gravity": 420, "size": 6, "life": 1500})
	FX.burst(vx, vy - 10, {"count": 24, "colors": ["#7a0010", "#4a0008"], "speed": 420, "spread": PI, "angle": -PI / 2, "gravity": 900, "size": 4, "life": 900})
	for vid in e.victims:
		for k in table.cards.keys():
			if k == "e:" + str(vid) or k.begins_with("a:" + str(vid)):
				table.push_out(k, Vector3(0, -0.3, 0.6), 200)
	await FX.wait(800)
	var b := FX.anim(900, [{"y": vy - 860.0, "a": 0.96}, {"y": -950.0, "a": 0.0}], func(v): if is_instance_valid(foot): foot.position.y = v.y; foot.modulate.a = v.a, {"node": foot})
	await FX.until(b)
	if is_instance_valid(foot):
		foot.queue_free()


func _ev_retreat(e: Dictionary) -> void:
	if bool(e.get("alone", false)):
		FX.banner(T("alone"), 1400)   # 운명을 받아들여 동료가 모두 죽었다 — 노엘 혼자 물러난다
		await FX.wait(900)
	await FX.wait(200)


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
	_disp = {}   # 정리 뒤: 보이는 값 = 상태
	if st.result == null:
		_sync_table()
		_sync_hud()


# ───────── 결과 판 ─────────
func _show_result() -> void:
	hand.set_open(false)
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
	var sumline := "%s turn=%d noel=%d %s%s" % [str(st.result), int(st.turn), int(st.noelHp), " ".join(hp), (" postponed=" + ",".join(post)) if not post.is_empty() else ""]
	log.append("result " + str(st.result))
	if not game.is_empty():
		# 게임 모드: 결과는 게임 흐름이 이어 간다(「] result」 는 결과 요약 화면만 — CI 가 끝까지 갔는지 본다)
		G.ctl.note("v2 battle end enc=%s %s" % [str(st.enc), sumline])
		match str(st.result):
			"giant":
				await G.dialog.say(G.S.giantAppear.after)
				await _finish("giant")
				return
			"retreat":
				await FX.wait(600)
				await _finish("retreat")
				return
			"win":
				await _guide("battleWin")
				if not is_inside_tree():
					return
	else:
		G.ctl.note("result v2 " + sumline)
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
	var res := str(st.result)
	# 시험 전투: 「다시 하기」(같은 시드로 처음부터) · 게임 모드: 이기면 「계속」, 지면 「다시 하기」(게임 흐름이 그 전투를 처음부터)
	var again := UI.button(T("again"), 34, restart) if game.is_empty() else UI.button(T("continue") if res == "win" else T("again"), 34, func(): _finish(res))
	if not game.is_empty():
		if G.params.has("autoplay") or G.autoguide:
			get_tree().create_timer(FX.ms(1600) / 1000.0, false).timeout.connect(func(): _finish(res))
	again.name = "again"
	again.fit(Vector2(60, 16))
	again.position = Vector2(960 - again.size.x / 2.0, box.end.y + 20)
	result_panel.add_child(again)
	add_child(result_panel)
	result_panel.modulate.a = 0.0
	FX.anim(400, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(result_panel): result_panel.modulate.a = v.a, {"node": result_panel})
	if G.params.has("quit-on-end") and game.is_empty():
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
	if mode in ["idle", "shift"]:
		overlay.queue_redraw()
	end_btn.z_index = 90 if hand.open else 46   # v2.4: 펼친 두 손 그림(z 80)에 가려지지 않게
	# 시험 전용(?test=1&openhand · 헤드리스 --test --openhand): 첫 내 턴에 손패를 펼쳐 둔다(스크린샷용)
	if G.test and G.params.has("openhand") and mode == "formation" and not _opened_once:
		_on_start()
	if G.test and G.params.has("openhand") and mode == "idle" and not _opened_once:
		_opened_once = true
		hand.set_open(true)
	if not G.params.has("autoplay") or _auto_busy or st.is_empty() or mode not in ["idle", "formation"]:
		return
	if _cut or G.dialog.guide_open() or G.scenes.overlay_open():
		return   # 안내 상자·데스신·카드 획득 화면이 끝날 때까지
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
		# 출전 배치(D1): 앞 적이 있는 칸에 센 동료를 세운 뒤 「출전」 (RulesV2._auto_formation)
		var f := RulesV2.auto_step(st)
		if str(f.kind) == "move" and RulesV2.can_move(st, str(f.ally), f.to).ok:
			_commit_move(str(f.ally), f.to)
			return "move"
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
		"open":
			b.hand.set_open(a1 != "0")
			return {"ok": true, "open": b.hand.open}
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
		"tableCards": table.cards.size(), "handCards": hand.cards.size(), "handOpen": hand.open, "maxHands": hand.max_hands, "handsNow": hand.hands_visible(), "log": log.slice(maxi(0, log.size() - 30)),
		"shown": _shown_faces(), "guideRect": _guide_rect(), "zoom": str(_zoom_face.get("name", "")),
		"awaitFate": st.get("awaitFate"), "fateResults": st.get("fateResults", [])}


## 시험용: 탁자에 지금 그려진 적·동료 카드 앞면의 HP(연출 중 앞면이 미리 바뀌지 않는지 — 밤샘 계획 2 D)
func _shown_faces() -> Dictionary:
	var out := {}
	for k in table.cards:
		if str(k).begins_with("e:") or str(k).begins_with("ally:"):
			out[k] = table.card(k).face.get("hp", null)
	return out


## 시험용: 안내 상자 사각형(무대 px)과 적 줄 아래 끝 — 안내 상자가 적 줄을 가리지 않는지
func _guide_rect() -> Dictionary:
	if G.dialog == null or not G.dialog.guide.visible:
		return {}
	var g: Control = G.dialog.guide
	var enemy_bottom := 0.0
	for k in table.cards:
		if str(k).begins_with("e:"):
			enemy_bottom = maxf(enemy_bottom, table.screen_rect(k).end.y)
	return {"y": g.position.y, "h": g.size.y * g.scale.y, "x": g.position.x, "w": g.size.x * g.scale.x, "scale": g.scale.y, "enemyBottom": enemy_bottom,
		"actBottom": table.rect_at(cell_pos(1, 1)).end.y, "allyTop": table.rect_at(cell_pos(3, 1)).position.y, "allyBottom": table.rect_at(cell_pos(3, 1)).end.y}


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
