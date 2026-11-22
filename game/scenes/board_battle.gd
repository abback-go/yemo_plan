## board_battle.gd — 전투 시험판 v2 「맡기기」 화면·조작·연출 (docs/battle-v2-spec.md). 주소 ?battle=v2(헤드리스 --battle=v2)일 때만 main.gd 가 연다.
## 화면(1920×1080, 네 줄 — 지시서 2장): ① 적 줄(가운데로 모음, 하수인은 강적 앞에 겹침) / ② 적 행동 줄(노리는 동료 칸 위, 보낸 적의 작은 얼굴,
##   '모두'는 세 칸을 가로지르는 긴 카드) / ③ 내 행동 줄(맡긴 카드 — 대상 적의 작은 얼굴, 동료마다 2장) / ④ 동료 줄(초상 · 옆에 버팀/배율)
##   / 노엘의 손과 손패(지금 전투의 손 — ui/board_hand.gd), 덱 수, 행동 에너지(붉은 보석), 「턴 끝」.
## 조작(마우스·터치 같음): 손패의 카드를 끌어 동료 칸(②~④ 어디든 그 열)에 놓는다 → 공격 카드는 적 카드를 누른다.
##   노엘의 카드는 칸이 없다 — 운명 전가·저주는 ② 적 행동 카드에, 취약은 ① 적에, 축복은 ④ 동료에 직접 놓는다.
##   운명 전가는 놓은 뒤 그 적 행동 카드를 다른 칸으로 끌거나(또는 칸을 누름) 옮긴다. 놓은 카드·노엘의 표를 누르면 손패로(에너지 돌려받음).
## 규칙은 core/rules_v2.gd, 수치·문구는 data/battle_v2_data.gd. 자동 진행(--autoplay)은 RulesV2.auto_step 을 한 수씩 화면 조작과 같은 길로 낸다.
## 시험 훅: core/test_api.gd 의 witch.v2(…) → test_call
class_name BoardBattle
extends Control

static var current: BoardBattle = null

var st := {}
var mode := "busy"        # idle | drag | pick | shift | busy | over
var hand: BoardHand
var enemy_cards := {}     # 적 id → BoardPieces.EnemyCard
var ghost: BoardPieces.SummonGhost
var act_cards := {}       # 적 id → BoardPieces.ActCard (다음 적 턴의 행동)
var placed_cards := {}    # 동료 id → [BoardPieces.PlacedCard]
var tags: Array = []      # BoardPieces.NoelTag (st.noel 순서)
var ally_cards := {}      # 동료 id → BoardPieces.AllyCard
var pending := {}         # 놓았지만 대상·옮길 칸을 아직 안 고른 카드 {uid, kind: attack|shift, ally, enemy, piece}
var drag := {}            # 손패에서 끄는 카드 {uid, start, moved, hot}
var adrag := {}           # 운명 전가로 옮기는 ② 카드 {enemy, start, moved}
var tap := {}             # 누른 ③ 카드·노엘 표 {kind, ally, index, start}
var touch := false
var end_btn: Btn
var acts_layer: Control
var placed_layer: Control
var tags_layer: Control
var hud: Control
var overlay: Control      # 끄는 동안의 미리 보기 · 안내 줄
var preview_text := ""
var preview_pos := Vector2.ZERO
var prompt_text := ""
var result_panel: Control
var turn_label: Label
var _hidden: Array = []   # 뽑는 연출 중이라 아직 손패에 안 보이는 카드
var _shown_energy := 0
var _auto_t := 0.0
var _auto_busy := false
var log: Array = []


# ───────── 열기 ─────────
static func open(parent: Node, seed = null) -> BoardBattle:
	var b := BoardBattle.new()
	parent.add_child(b)
	b.start(seed)
	return b


func L() -> Dictionary:
	return BattleV2Data.D.layout


func T(key: String, args := {}) -> String:
	var s := str(BattleV2Data.D.text.get(key, key))
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
	await FX.fade(0, 400)
	if not is_inside_tree():
		return
	await _play(RulesV2.start_turn(st))
	_set_idle()


# ───────── 자리 ─────────
func col_x(id: String) -> float:
	return float(L().cols[st.order.find(id)])


func enemy_rect(eid: String) -> Rect2:
	var e = RulesV2.enemy(st, eid)
	if e != null and RulesV2.is_minion(e):
		var m := enemy_rect(str(e.of))
		var M: Dictionary = L().minion
		return Rect2(m.get_center().x - float(M.w) / 2.0, m.position.y + float(M.dy), float(M.w), float(M.h))
	var E: Dictionary = L().enemy
	return Rect2(float(E.x[eid]) - float(E.w) / 2.0, float(E.y), float(E.w), float(E.h))


func ally_rect(id: String) -> Rect2:
	var A: Dictionary = L().ally
	return Rect2(col_x(id) - float(A.w) / 2.0, float(A.y), float(A.w), float(A.h))


func placed_rect(id: String, i: int) -> Rect2:
	var P: Dictionary = L().placed
	var total := float(P.w) * 2.0 + float(P.gap)
	return Rect2(col_x(id) - total / 2.0 + i * (float(P.w) + float(P.gap)), float(P.y), float(P.w), float(P.h))


## 칸(열)의 높이 ②~④ 전체
func column_rect(id: String) -> Rect2:
	var D2: Dictionary = L().drop
	var w := float(L().colW)
	return Rect2(col_x(id) - w / 2.0, float(D2.y0), w, float(D2.y1) - float(D2.y0))


## ② 카드 자리: 한 명 공격은 노리는 칸 위(둘 이상이면 겹쳐 쌓음), '모두'는 긴 띠
func act_rect(eid: String) -> Rect2:
	var ac: BoardPieces.ActCard = act_cards.get(eid)
	if ac == null:
		return Rect2()
	if ac.kind == "sweep":
		var S: Dictionary = L().sweep
		return Rect2(float(S.x0), float(S.y), float(S.x1) - float(S.x0), float(S.h))
	var A: Dictionary = L().act
	var same := []
	for e in st.enemies:
		var o: BoardPieces.ActCard = act_cards.get(e.id)
		if o != null and o.kind != "sweep" and o.slot == ac.slot:
			same.append(e.id)
	var k := same.find(eid)
	var n := same.size()
	var dx := float(A.dx)
	if n > 1:
		dx = minf(dx, (float(L().colW) - float(A.w)) / (n - 1))
	var x := col_x(ac.slot) - float(A.w) / 2.0 + (k - (n - 1) / 2.0) * dx
	return Rect2(x, float(A.y) + k * float(A.dy), float(A.w), float(A.h))


func deck_center() -> Vector2:
	var Dk: Dictionary = L().deck
	return Vector2(float(Dk.x) + float(Dk.w) / 2.0, float(Dk.y) + float(Dk.h) / 2.0)


func _pad() -> float:
	return minf(40.0, 16.0 / maxf(0.05, FX.css_scale)) if touch else 0.0


func column_at(p: Vector2) -> String:
	for id in st.order:
		if column_rect(id).grow(_pad()).has_point(p):
			return id
	return ""


## 누른 적: 하수인이 강적 앞에 있으니 하수인 먼저
func enemy_at(p: Vector2) -> String:
	var order: Array = st.enemies.duplicate()
	order.sort_custom(func(a, b): return RulesV2.is_minion(a) and not RulesV2.is_minion(b))
	for e in order:
		if e.alive and enemy_rect(e.id).grow(_pad()).has_point(p):
			return e.id
	return ""


## 누른 ② 카드 (위에 쌓인 것부터)
func act_at(p: Vector2) -> String:
	var ids := act_cards.keys()
	ids.reverse()
	for eid in ids:
		if act_cards[eid].kind != "sweep" and act_rect(eid).grow(_pad() * 0.5).has_point(p):
			return eid
	for eid in ids:
		if act_cards[eid].kind == "sweep" and act_rect(eid).grow(_pad() * 0.5).has_point(p):
			return eid
	return ""


func ally_at(p: Vector2) -> String:
	for id in st.order:
		if ally_rect(id).grow(_pad()).has_point(p):
			return id
	return ""


func placed_at(p: Vector2) -> Array:
	for id in placed_cards:
		var list: Array = placed_cards[id]
		for i in list.size():
			if Rect2(list[i].position, list[i].size).grow(_pad() * 0.5).has_point(p):
				return [id, i]
	return []


func tag_at(p: Vector2) -> int:
	for i in range(tags.size() - 1, -1, -1):
		var t: Control = tags[i]
		if is_instance_valid(t) and Rect2(t.position, t.size).grow(_pad() * 0.5).has_point(p):
			return i
	return -1


## 노엘의 표 자리: ② 카드 오른쪽 위 · ① 적 카드 위쪽 · ④ 동료 초상 위
func tag_rect(n: Dictionary, order := 0) -> Rect2:
	var w := 150.0
	var h := 32.0
	match str(n.kind):
		"curse", "shift":
			var r := act_rect(str(n.target))
			if r.size == Vector2.ZERO:
				r = enemy_rect(str(n.target))
			return Rect2(r.end.x - w + 10 - order * 20, r.position.y - h + 8 - order * 26, w, h)
		"vuln":
			var re := enemy_rect(str(n.target))
			return Rect2(re.get_center().x - w / 2.0, re.position.y + 40, w, h)
		_:
			var ra := ally_rect(str(n.target))
			return Rect2(ra.get_center().x - w / 2.0, ra.position.y - h + 10, w, h)


# ───────── 화면 만들기 ─────────
func _build() -> void:
	var bg := UI.cover_rect(Assets.tex(str(L().bg)), Rect2(0, 0, 1920, 1080))
	var dim := float(L().bgDim)
	bg.modulate = Color(dim, dim * 0.95, dim * 0.96)
	add_child(bg)
	add_child(UI.tex_rect(UI.grad([[0, Color(0, 0, 0, 0)], [0.6, Color(0.02, 0, 0.01, 0.35)], [1, Color(0, 0, 0, 0.85)]], "radial", 256, 256, Vector2(0.5, 0.42), 0.8), Rect2(0, 0, 1920, 1080)))
	var slab := Control.new()
	slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slab.size = size
	slab.draw.connect(_draw_slabs.bind(slab))
	add_child(slab)
	var RL: Dictionary = L().rowLabels
	for k in [["rowAct", RL.act], ["rowPlaced", RL.placed]]:
		var lb := UI.label(T(k[0]), 18, Color("#a99a92"), "sans_bold", HORIZONTAL_ALIGNMENT_LEFT, 3)
		lb.position = Vector2(float(RL.x), float(k[1]))
		add_child(lb)
	# ① 적 (하수인은 강적 다음에 — 앞에 그린다)
	for e in st.enemies:
		if not RulesV2.is_minion(e):
			_make_enemy(e)
	ghost = BoardPieces.SummonGhost.new()
	ghost.visible = false
	add_child(ghost)
	for e in st.enemies:
		if RulesV2.is_minion(e):
			_make_enemy(e)
	acts_layer = _layer()
	placed_layer = _layer()
	for id in st.order:
		_make_ally(id)
		placed_cards[id] = []
	tags_layer = _layer()
	_make_hud()
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
	# 「턴 끝」 은 맨 뒤에 붙인다(누르기는 나무 순서 — 뒤에 붙인 것이 먼저)
	end_btn = UI.button(T("endTurn"), 34, _on_end)
	end_btn.name = "endTurn"
	end_btn.fit(Vector2(58, 18))
	end_btn.position = Vector2(float(L().endTurn.x), float(L().endTurn.y))
	add_child(end_btn)


func _layer() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = size
	add_child(c)
	return c


func _draw_slabs(c: Control) -> void:
	for s in L().slab:
		var r := Rect2(s[0], s[1], s[2], s[3])
		c.draw_style_box(UI.box(Color(0.045, 0.035, 0.04, 0.78), Color(0.32, 0.26, 0.24, 0.5), 18, 2), r)
		c.draw_style_box(UI.box(Color(0, 0, 0, 0), Color(0, 0, 0, 0.45), 14, 3), r.grow(-6))
		# 돌판의 금(코드 선)
		var k := int(r.position.x + r.position.y)
		for i in 5:
			var a := r.position + Vector2(fmod(k * 37.0 + i * 263.0, r.size.x - 80) + 40, fmod(k * 11.0 + i * 97.0, r.size.y - 60) + 30)
			c.draw_polyline(PackedVector2Array([a, a + Vector2(26, 9), a + Vector2(41, 3), a + Vector2(63, 15)]), Color(0, 0, 0, 0.35), 1.5, true)
	# 칸(열) 경계: 얇은 세로 선
	var D2: Dictionary = L().drop
	for i in range(1, L().cols.size()):
		var x := (float(L().cols[i - 1]) + float(L().cols[i])) / 2.0
		c.draw_line(Vector2(x, float(D2.y0) + 10), Vector2(x, float(L().placed.y) + float(L().placed.h) + 4), Color(0.6, 0.5, 0.45, 0.16), 2.0)


func _make_enemy(e: Dictionary) -> void:
	var c := BoardPieces.EnemyCard.new()
	c.eid = e.id
	c.type = e.type
	c.minion = RulesV2.is_minion(e)
	var nm := str(BattleV2Data.D.enemies[e.type].name)
	c.title = nm + (" " + str(e.tag) if str(e.tag) != "" else "")
	c.back = Assets.tex(str(GameData.D.cardBackImg))
	var r := enemy_rect(e.id)
	c.position = r.position
	c.size = r.size
	c.pivot_offset = r.size / 2.0
	c.hp = int(e.hp)
	c.max_hp = int(e.maxHp)
	c.alive = e.alive
	c.visible = e.alive or not c.minion
	add_child(c)
	enemy_cards[e.id] = c


func _make_ally(id: String) -> void:
	var a: Dictionary = st.allies[id]
	var P: Dictionary = BattleV2Data.D.portraits[id]
	var tr: Dictionary = BattleV2Data.D.traits[a.trait]
	var c := BoardPieces.AllyCard.new()
	c.aid = id
	c.title = G.name_of(id)
	c.trait_name = str(tr.name)
	c.trait_text = str(tr.text)
	c.color = Color(str(P.color))
	c.calm = Assets.tex(str(P.calm))
	c.shock = Assets.tex(str(P.shocked))
	var cr: Array = P.crop
	c.crop = Rect2(cr[0], cr[1], cr[2], cr[3])
	c.down_text = T("down")
	var r := ally_rect(id)
	c.position = r.position
	c.size = r.size
	var S: Dictionary = L().status
	c.status_rect = Rect2(float(S.dx), float(S.y) - r.position.y, float(S.w), float(S.h))
	c.hp = int(a.hp)
	c.max_hp = int(a.maxHp)
	add_child(c)
	ally_cards[id] = c


func _make_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.size = size
	hud.draw.connect(_draw_hud)
	add_child(hud)
	turn_label = UI.label("", 30, Color("#efe3e5"), "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, 5)
	turn_label.position = Vector2(26, 12)
	add_child(turn_label)
	var hint := UI.label(T("hint"), 17, Color("#b9aca6"), "sans", HORIZONTAL_ALIGNMENT_LEFT, 3)
	hint.position = Vector2(26, 56)
	hint.size = Vector2(560, 60)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)


func _draw_hud() -> void:
	# 덱: 뒷면 카드 몇 장 + 「덱 n」
	var Dk: Dictionary = L().deck
	var back := BoardPieces.tex(str(GameData.D.cardBackImg))
	var n: int = st.draw.size() if not st.is_empty() else 0
	for i in mini(3, maxi(1, n)):
		var r := Rect2(float(Dk.x) - i * 5, float(Dk.y) - i * 6, float(Dk.w), float(Dk.h))
		hud.draw_texture_rect(back, r, false, Color(0.85, 0.8, 0.82, 1.0 if n > 0 else 0.35))
	BoardPieces.text_in(hud, Rect2(float(Dk.x) - 30, float(Dk.y) + float(Dk.h) + 4, float(Dk.w) + 60, 34), T("deck", {"n": n}), 24, Color("#efe3e5"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
	# 행동 에너지: 붉은 보석
	var En: Dictionary = L().energy
	BoardPieces.text_in(hud, Rect2(float(En.x) - 20, float(En.y), 300, 32), T("energy"), 22, Color("#e8d4d6"), "sans_bold", HORIZONTAL_ALIGNMENT_LEFT, 4)
	var total := int(BattleV2Data.D.rules.energy)
	for i in total:
		var c := Vector2(float(En.x) + 22 + i * 62, float(En.y) + 74)
		var on := i < _shown_energy
		var gem := PackedVector2Array([c + Vector2(0, -26), c + Vector2(20, -6), c + Vector2(0, 26), c + Vector2(-20, -6)])
		hud.draw_colored_polygon(gem, Color("#c2101f") if on else Color("#2a1416"))
		var loop := gem.duplicate()
		loop.append(gem[0])
		hud.draw_polyline(loop, Color("#ff8a94") if on else Color("#5a3438"), 2.5, true)
		if on:
			hud.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -22), c + Vector2(12, -6), c + Vector2(0, -2), c + Vector2(-8, -8)]), Color(1, 0.75, 0.78, 0.55))


func _draw_overlay() -> void:
	if preview_text != "":
		var f := Assets.font("sans_bold")
		var sz := f.get_string_size(preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26) + Vector2(32, 14)
		var r := Rect2(preview_pos - Vector2(sz.x / 2.0, sz.y), sz)
		overlay.draw_style_box(UI.box(Color(0.06, 0.03, 0.02, 0.94), BoardPieces.GOLD, 10, 2), r)
		BoardPieces.text_in(overlay, r, preview_text, 26, Color("#ffdf8a"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
	if prompt_text != "":
		var f2 := Assets.font("sans_bold")
		var sz2 := f2.get_string_size(prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26) + Vector2(48, 18)
		var r2 := Rect2(Vector2(960 - sz2.x / 2.0, 742), sz2)
		overlay.draw_style_box(UI.box(Color(0.04, 0, 0.016, 0.92), UI.RED, 20, 2), r2)
		BoardPieces.text_in(overlay, r2, prompt_text, 26, Color("#ffd9dc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
	# 운명 전가로 끄는 ② 카드에서 옮길 칸까지
	if not adrag.is_empty() and adrag.moved and act_cards.has(adrag.enemy):
		var ac: Control = act_cards[adrag.enemy]
		UI.arrow(overlay, ac.position + ac.size / 2.0, get_local_mouse_position(), Color("#ffd36b"), 5.0, Vector2(12, 8), 30)


# ───────── 상태 → 화면 (연출이 끝난 뒤·조작할 때) ─────────
func _sync(animate_acts := true) -> void:
	for e in st.enemies:
		var c: BoardPieces.EnemyCard = enemy_cards[e.id]
		c.hp = int(e.hp)
		c.alive = e.alive
		c.visible = e.alive or not c.minion
		c.queue_redraw()
	var g = RulesV2.enemy(st, "G")
	var gi = g.intent if g != null else null
	ghost.visible = gi != null and gi.kind == "summon"
	if ghost.visible:
		var mr := enemy_rect("S")
		ghost.position = mr.position
		ghost.size = mr.size
		ghost.label = str(gi.label)
		ghost.sub = T("summonNext")
	_sync_acts(animate_acts)
	for id in st.order:
		var a: Dictionary = st.allies[id]
		var c2: BoardPieces.AllyCard = ally_cards[id]
		c2.hp = int(a.hp)
		c2.block = int(a.block)
		c2.down = a.down
		_status_of(id, c2)
		c2.queue_redraw()
	_sync_placed()
	_sync_tags()
	_update_shock()
	_shown_energy = int(st.energy) - (int(RulesV2.card_def(st, pending.uid).cost) if not pending.is_empty() else 0)
	turn_label.text = T("turn", {"n": st.turn})
	hud.queue_redraw()
	hand.update_classes(st, mode != "idle" and mode != "drag")
	end_btn.disabled = mode != "idle" or st.result != null
	end_btn.queue_redraw()


func _status_of(id: String, c: BoardPieces.AllyCard) -> void:
	var a: Dictionary = st.allies[id]
	match str(a.trait):
		"brace":
			c.status_label = T("brace")
			c.status_value = str(a.brace)
		"aim":
			c.status_label = T("mult")
			c.status_value = "×" + str(a.mult)
		_:
			c.status_label = ""


## ② 카드: 상태의 행동과 맞춘다(없어진 것은 지우고, 새로 생긴 것은 보낸 적 자리에서 내려온다)
func _sync_acts(animate := true) -> void:
	for e in st.enemies:
		var it = e.intent if e.alive else null
		var show: bool = it != null and it.kind in ["hit", "sweep"]
		var ac: BoardPieces.ActCard = act_cards.get(e.id)
		if not show:
			if ac != null:
				ac.queue_free()
				act_cards.erase(e.id)
			continue
		var fresh := ac == null
		if fresh:
			ac = BoardPieces.ActCard.new()
			ac.eid = e.id
			ac.type = e.type
			ac.tag = str(e.tag)
			ac.all_text = T("all")
			acts_layer.add_child(ac)
			act_cards[e.id] = ac
			var er := enemy_rect(e.id)
			ac.position = er.get_center() - Vector2(60, 20)
			ac.size = Vector2(120, 40)
			ac.modulate.a = 0.0
		ac.kind = str(it.kind)
		ac.value = int(it.value)
		ac.minus = int(it.get("minus", 0))
		ac.slot = str(it.slot)
		ac.label = str(it.label)
		ac.queue_redraw()
	_layout_acts(animate)


func _layout_acts(animate := true) -> void:
	for eid in act_cards:
		var ac: BoardPieces.ActCard = act_cards[eid]
		var r := act_rect(eid)
		if not animate or not adrag.is_empty() and adrag.get("enemy", "") == eid and adrag.moved:
			if adrag.get("enemy", "") != eid:
				ac.position = r.position
				ac.size = r.size
				ac.modulate.a = 1.0
			continue
		var p0 := ac.position
		var s0 := ac.size
		var a0 := ac.modulate.a
		FX.anim(260, [{"k": 0.0}, {"k": 1.0}], func(v):
			if is_instance_valid(ac):
				ac.position = p0.lerp(r.position, v.k)
				ac.size = s0.lerp(r.size, v.k)
				ac.modulate.a = lerpf(a0, 1.0, v.k), {"node": ac, "easing": "ease-out", "key": "act_" + eid})


## ③ 카드의 결과 숫자(특성·버프가 붙은 것 — RulesV2.forecast)와 대상의 작은 얼굴
func _sync_placed() -> void:
	var fc := RulesV2.forecast(st)
	for id in st.order:
		var list: Array = placed_cards[id]
		var pl: Array = st.allies[id].placed
		for i in list.size():
			var pc: BoardPieces.PlacedCard = list[i]
			if i < pl.size():
				_fill_placed(pc, pl[i], id, fc)
			var r := placed_rect(id, i)
			pc.position = r.position
			pc.size = r.size


func _fill_placed(pc: BoardPieces.PlacedCard, p: Dictionary, id: String, fc: Dictionary) -> void:
	var d: Dictionary = RulesV2.card_def(st, p.uid)
	var r: Dictionary = fc.get(p.uid, {})
	var line := T("noEffect")
	match str(d.kind):
		"attack", "release":
			if fc.has(p.uid):
				line = T("damage", {"n": int(r.get("dmg", 0))})
				if int(r.get("block", 0)) > 0:
					line += " · " + T("block", {"n": r.block})
		"block":
			if fc.has(p.uid):
				line = T("block", {"n": int(r.get("block", 0))})
				if int(r.get("counter", 0)) > 0:
					line += " · " + T("counter", {"n": r.counter})
		"aim":
			if fc.has(p.uid):
				line = T("multTo", {"n": int(r.get("mult", 1))})
	pc.line = line
	pc.target_type = ""
	pc.target_tag = ""
	if str(p.target) != "":
		var te = RulesV2.enemy(st, str(r.get("target", p.target)))
		if te == null or not te.alive:
			te = RulesV2.hit_target(st, str(p.target), bool(d.get("pierce", false)))
		if te != null:
			pc.target_type = str(te.type)
			pc.target_tag = str(te.tag)
	pc.queue_redraw()


func _sync_tags() -> void:
	for t in tags:
		if is_instance_valid(t):
			t.queue_free()
	tags = []
	var on := {}
	for i in st.noel.size():
		var n: Dictionary = st.noel[i]
		var key := str(n.kind) + ":" + str(n.target) if not str(n.kind) in ["curse", "shift"] else "act:" + str(n.target)
		var k := int(on.get(key, 0))
		on[key] = k + 1
		var t := _make_tag(n, k)
		t.index = i
		tags.append(t)
	if not pending.is_empty() and pending.kind == "shift" and pending.piece != null and is_instance_valid(pending.piece):
		var pr := tag_rect({"kind": "shift", "target": pending.enemy}, int(on.get("act:" + str(pending.enemy), 0)))
		pending.piece.position = pr.position


func _make_tag(n: Dictionary, order: int) -> BoardPieces.NoelTag:
	var t := BoardPieces.NoelTag.new()
	t.card_id = st.cards[n.uid].id
	t.text = T({"bless": "tagBless", "curse": "tagCurse", "vuln": "tagVuln", "shift": "tagShift"}[str(n.kind)])
	var r := tag_rect(n, order)
	t.position = r.position
	t.size = r.size
	tags_layer.add_child(t)
	return t


## 노려지면(그 칸에 ② 카드가 있거나 '모두' 공격) 놀란 표정 — 화면의 ② 카드로 정한다(연출 중에도 맞게)
func _update_shock() -> void:
	var sweep := false
	var hit := {}
	for eid in act_cards:
		var ac: BoardPieces.ActCard = act_cards[eid]
		if ac.kind == "sweep":
			sweep = true
		else:
			hit[ac.slot] = true
	for id in ally_cards:
		var c: BoardPieces.AllyCard = ally_cards[id]
		var s: bool = (sweep or hit.has(id)) and not c.down
		if s != c.shocked:
			c.shocked = s
			c.queue_redraw()


func hand_list() -> Array:
	var out: Array = st.hand.duplicate()
	for u in _hidden:
		out.erase(u)
	if not pending.is_empty():
		out.erase(pending.uid)
	return out


func _set_idle() -> void:
	if not is_inside_tree() or st.result != null:
		return
	mode = "idle"
	_sync()
	hand.layout()


func _toast_reason(r: String) -> void:
	FX.toast(str(BattleV2Data.D.reasons.get(r, r)))


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
			var eid := enemy_at(p)
			if eid != "":
				_commit_pending({"target": eid})
			else:
				_cancel_pending()
			return
		"shift":
			if act_at(p) == pending.enemy:
				adrag = {"enemy": pending.enemy, "start": p, "moved": false}
				return
			var col := column_at(p)
			if col != "" and RulesV2.shift_dests(st, pending.enemy).has(col):
				_commit_pending({"to": col})
			else:
				_cancel_pending()
			return
		"idle":
			pass
		_:
			return
	var uid := hand.hit_test(p)
	if uid != "":
		drag = {"uid": uid, "start": p, "moved": false, "hot": ""}
		mode = "drag"
		hand.hover_uid = ""
		hand.lifted_uid = uid
		hand.layout()
		return
	var pa := placed_at(p)
	if not pa.is_empty():
		tap = {"kind": "placed", "ally": pa[0], "index": pa[1], "start": p}
		return
	var ti := tag_at(p)
	if ti >= 0:
		tap = {"kind": "noel", "index": ti, "start": p}


func _move(p: Vector2, is_touch: bool) -> void:
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
		"shift":
			if not adrag.is_empty():
				if not adrag.moved and absf(p.x - adrag.start.x) + absf(p.y - adrag.start.y) > _move_thresh():
					adrag.moved = true
				if adrag.moved:
					var ac: Control = act_cards.get(adrag.enemy)
					if ac != null:
						ac.position = p - ac.size / 2.0
					var col := column_at(p)
					for id in ally_cards:
						ally_cards[id].drop = 2.0 if id == col and RulesV2.shift_dests(st, pending.enemy).has(id) else (1.0 if RulesV2.shift_dests(st, pending.enemy).has(id) else 0.0)
						ally_cards[id].queue_redraw()
					overlay.queue_redraw()
		"pick":
			if not is_touch:
				var eid := enemy_at(p)
				for k in enemy_cards:
					var c: BoardPieces.EnemyCard = enemy_cards[k]
					var want := 2.0 if k == eid else (1.0 if c.alive else 0.0)
					if c.pick != want:
						c.pick = want
						c.queue_redraw()
		"idle":
			if is_touch:
				return
			hand.set_hover(hand.hit_test(p))
			var pa := placed_at(p)
			for id in placed_cards:
				for i in placed_cards[id].size():
					var pc: BoardPieces.PlacedCard = placed_cards[id][i]
					var h: bool = not pa.is_empty() and pa[0] == id and pa[1] == i
					if pc.hot != h:
						pc.hot = h
						pc.queue_redraw()
			var ti := tag_at(p)
			for i in tags.size():
				if is_instance_valid(tags[i]) and tags[i].hot != (i == ti):
					tags[i].hot = i == ti
					tags[i].queue_redraw()
			# ② 카드 ↔ 그 카드를 보낸 적 (마우스를 올리면 서로 빛난다)
			var ai := act_at(p)
			var ei := enemy_at(p)
			for k in enemy_cards:
				var lk: bool = k == ai or (ei == k)
				if enemy_cards[k].link != lk:
					enemy_cards[k].link = lk
					enemy_cards[k].queue_redraw()
			for k in act_cards:
				var lk2: bool = k == ei or k == ai
				if act_cards[k].link != lk2:
					act_cards[k].link = lk2
					act_cards[k].queue_redraw()


func _up(p: Vector2) -> void:
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
		_clear_drag_marks()
		if hot == "":
			if reason != "":
				_toast_reason(reason)
			_cancel_drag()
			return
		_drop(uid, hot)
		return
	if mode == "shift" and not adrag.is_empty():
		var moved: bool = adrag.moved
		adrag = {}
		var col := column_at(p)
		if moved and col != "" and RulesV2.shift_dests(st, pending.enemy).has(col):
			_commit_pending({"to": col})
		else:
			_layout_acts(true)
			for id in ally_cards:
				ally_cards[id].drop = 1.0 if RulesV2.shift_dests(st, pending.enemy).has(id) else 0.0
				ally_cards[id].queue_redraw()
		overlay.queue_redraw()
		return
	if mode == "idle" and not tap.is_empty():
		var t2 := tap
		tap = {}
		if absf(p.x - t2.start.x) + absf(p.y - t2.start.y) > _move_thresh():
			return
		if t2.kind == "placed":
			_return_placed(str(t2.ally), int(t2.index))
		else:
			_return_tag(int(t2.index))


## 끄는 카드가 지금 놓일 곳(drag.hot) — 동료 카드는 칸(열), 노엘의 카드는 ②·①·④ 의 그 대상. 놓일 수 있는 곳은 금빛
func _update_drag_hot(p: Vector2) -> void:
	var uid: String = drag.uid
	var d := RulesV2.card_def(st, uid)
	var hot := ""
	var reason := ""
	preview_text = ""
	if str(d.owner) == "noel":
		var on := str(d.on)
		var cand := ""
		match on:
			"act":
				cand = act_at(p)
			"enemy":
				cand = enemy_at(p)
			_:
				cand = ally_at(p)
				if cand == "":
					cand = column_at(p)
		if cand != "":
			var chk := RulesV2.can_cast(st, uid, cand)
			if chk.ok:
				hot = cand
			else:
				reason = chk.reason
		_mark_noel_targets(uid, on, hot)
		if hot != "":
			preview_text = T({"bless": "tagBless", "curse": "tagCurse", "vuln": "tagVuln", "shift": "tagShift"}[str(d.kind)])
			preview_pos = p + Vector2(0, -120)
		else:
			prompt_text = T({"act": "dropAct", "enemy": "dropEnemy", "ally": "dropAlly"}[on])
	else:
		var col := column_at(p)
		for id in st.order:
			var ok: bool = RulesV2.can_place(st, uid, id).ok
			ally_cards[id].drop = (2.0 if id == col else 1.0) if ok else 0.0
			ally_cards[id].queue_redraw()
		if col != "":
			var chk2 := RulesV2.can_place(st, uid, col)
			if chk2.ok:
				hot = col
				preview_text = _preview_line(uid, col)
				preview_pos = Vector2(col_x(col), float(L().placed.y) + 2)
			else:
				reason = chk2.reason
		prompt_text = ""
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


func _mark_noel_targets(uid: String, on: String, hot: String) -> void:
	for eid in act_cards:
		var ac: BoardPieces.ActCard = act_cards[eid]
		var v := 0.0
		if on == "act" and RulesV2.can_cast(st, uid, eid).ok:
			v = 2.0 if eid == hot else 1.0
		if ac.movable != v:
			ac.movable = v
			ac.queue_redraw()
	for eid in enemy_cards:
		var c: BoardPieces.EnemyCard = enemy_cards[eid]
		var v2 := 0.0
		if on == "enemy" and RulesV2.can_cast(st, uid, eid).ok:
			v2 = 2.0 if eid == hot else 1.0
		if c.pick != v2:
			c.pick = v2
			c.queue_redraw()
	for id in ally_cards:
		var v3 := 0.0
		if on == "ally" and RulesV2.can_cast(st, uid, id).ok:
			v3 = 2.0 if id == hot else 1.0
		ally_cards[id].drop = v3
		ally_cards[id].queue_redraw()


func _clear_drag_marks() -> void:
	preview_text = ""
	prompt_text = ""
	for id in ally_cards:
		ally_cards[id].drop = 0.0
		ally_cards[id].queue_redraw()
	for eid in act_cards:
		act_cards[eid].movable = 0.0
		act_cards[eid].queue_redraw()
	for eid in enemy_cards:
		enemy_cards[eid].pick = 0.0
		enemy_cards[eid].queue_redraw()
	overlay.queue_redraw()


func _cancel_drag() -> void:
	drag = {}
	hand.drag_uid = ""
	hand.drag_mode = ""
	hand.lifted_uid = ""
	_clear_drag_marks()
	if mode == "drag":
		mode = "idle"
	hand.layout()


func _cancel_all() -> void:
	if mode == "drag":
		_cancel_drag()
	elif mode in ["pick", "shift"]:
		_cancel_pending()


# ───────── 놓기 ─────────
## 손패 카드를 그 대상(동료 칸 id · 적 행동/적 id · 동료 id)에 놓는다
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


## 손패의 카드가 날아가 작아지며 그 자리로 (r: 도착 사각형). 날아간 카드는 지운다
func _fly(uid: String, r: Rect2) -> void:
	var c: CardView = hand.detach(uid)
	if c == null:
		return
	c.smooth = true
	c.shadow = 0.0
	c.glow = 0.0
	c.z_index = 135
	var k := r.size.y / CardView.H
	c.set_rect(r.position + Vector2(4, 0), k, false)
	await FX.wait(200)
	if is_instance_valid(c):
		c.queue_free()


func _new_placed(uid: String, ally: String, idx: int) -> BoardPieces.PlacedCard:
	var pc := BoardPieces.PlacedCard.new()
	pc.uid = uid
	pc.card_id = st.cards[uid].id
	pc.ally = ally
	pc.title = str(RulesV2.card_def(st, uid).name)
	var r := placed_rect(ally, idx)
	pc.position = r.position
	pc.size = r.size
	pc.pivot_offset = r.size / 2.0
	placed_layer.add_child(pc)
	FX.anim(220, [{"s": 1.12, "a": 0.0}, {"s": 1.0, "a": 1.0}], func(v):
		if is_instance_valid(pc):
			pc.scale = Vector2(v.s, v.s)
			pc.modulate.a = v.a, {"node": pc, "easing": "ease-out"})
	return pc


func _commit_place(uid: String, ally: String, opts: Dictionary) -> bool:
	var res := RulesV2.place(st, uid, ally, opts)
	if not res.ok:
		_toast_reason(res.reason)
		_set_idle()
		return false
	mode = "busy"
	note("place %s %s %s" % [st.cards[uid].id, ally, str(opts)])
	var idx: int = st.allies[ally].placed.size() - 1
	await _fly(uid, placed_rect(ally, idx))
	if not is_inside_tree():
		return true
	placed_cards[ally].append(_new_placed(uid, ally, idx))
	_set_idle()
	return true


func _commit_cast(uid: String, target: String, opts: Dictionary) -> bool:
	var res := RulesV2.cast(st, uid, target, opts)
	if not res.ok:
		_toast_reason(res.reason)
		_set_idle()
		return false
	mode = "busy"
	note("cast %s %s %s" % [st.cards[uid].id, target, str(opts)])
	await _fly(uid, tag_rect(res.cast, 0))
	if not is_inside_tree():
		return true
	_set_idle()
	return true


## 공격 카드: 동료 칸에 놓고(깜빡임) 적 카드를 누를 때까지 기다린다
func _start_pending_attack(uid: String, ally: String) -> void:
	var chk := RulesV2.can_place(st, uid, ally)
	if not chk.ok:
		_toast_reason(chk.reason)
		_set_idle()
		return
	mode = "busy"
	pending = {"uid": uid, "kind": "attack", "ally": ally, "enemy": "", "piece": null}
	var idx: int = st.allies[ally].placed.size()
	await _fly(uid, placed_rect(ally, idx))
	if not is_inside_tree() or pending.is_empty():
		return
	var pc := _new_placed(uid, ally, idx)
	pc.pending = true
	pc.line = ""
	pending.piece = pc
	mode = "pick"
	prompt_text = T("pickEnemy")
	for k in enemy_cards:
		enemy_cards[k].pick = 1.0 if enemy_cards[k].alive else 0.0
		enemy_cards[k].queue_redraw()
	_sync()
	overlay.queue_redraw()


## 운명 전가: 그 ② 카드에 놓고 옮길 칸을 고를 때까지 기다린다
func _start_pending_shift(uid: String, eid: String) -> void:
	var chk := RulesV2.can_cast(st, uid, eid)
	if not chk.ok:
		_toast_reason(chk.reason)
		_set_idle()
		return
	mode = "busy"
	pending = {"uid": uid, "kind": "shift", "ally": "", "enemy": eid, "piece": null}
	var r := tag_rect({"kind": "shift", "target": eid})
	await _fly(uid, r)
	if not is_inside_tree() or pending.is_empty():
		return
	var t := BoardPieces.NoelTag.new()
	t.card_id = st.cards[uid].id
	t.text = T("tagShift")
	t.pending = true
	t.position = r.position
	t.size = r.size
	tags_layer.add_child(t)
	pending.piece = t
	mode = "shift"
	prompt_text = T("shiftTo")
	act_cards[eid].movable = 2.0
	act_cards[eid].queue_redraw()
	for id in ally_cards:
		ally_cards[id].drop = 1.0 if RulesV2.shift_dests(st, eid).has(id) else 0.0
		ally_cards[id].queue_redraw()
	_sync()
	overlay.queue_redraw()


func _end_pending_marks() -> void:
	prompt_text = ""
	adrag = {}
	_clear_drag_marks()


func _commit_pending(opts: Dictionary) -> void:
	var pd := pending
	pending = {}
	_end_pending_marks()
	var piece = pd.piece
	if piece != null and is_instance_valid(piece):
		piece.queue_free()
	mode = "busy"
	var ok := false
	if pd.kind == "attack":
		var res := RulesV2.place(st, pd.uid, pd.ally, opts)
		ok = res.ok
		if ok:
			note("place %s %s %s" % [st.cards[pd.uid].id, pd.ally, str(opts)])
			var pc := _new_placed(pd.uid, pd.ally, st.allies[pd.ally].placed.size() - 1)
			pc.scale = Vector2.ONE
			pc.modulate.a = 1.0
			placed_cards[pd.ally].append(pc)
		else:
			_toast_reason(res.reason)
	else:
		var res2 := RulesV2.cast(st, pd.uid, pd.enemy, opts)
		ok = res2.ok
		if ok:
			note("cast %s %s %s" % [st.cards[pd.uid].id, pd.enemy, str(opts)])
		else:
			_toast_reason(res2.reason)
	if not ok and piece != null:
		hand.create(st, pd.uid, Rect2(piece.position, piece.size).get_center())
	_set_idle()


func _cancel_pending() -> void:
	if pending.is_empty():
		mode = "idle"
		return
	var pd := pending
	pending = {}
	_end_pending_marks()
	var piece = pd.piece
	var from := deck_center()
	if piece != null and is_instance_valid(piece):
		from = Rect2(piece.position, piece.size).get_center()
		piece.queue_free()
	hand.create(st, pd.uid, from)
	_set_idle()


## ③ 카드를 누름 → 손패로(에너지 돌려받음)
func _return_placed(ally: String, index: int) -> void:
	var list: Array = placed_cards[ally]
	if index >= list.size():
		return
	var res := RulesV2.unplace(st, ally, index)
	if not res.ok:
		_toast_reason(res.reason)
		return
	var pc: BoardPieces.PlacedCard = list[index]
	list.remove_at(index)
	var from := Rect2(pc.position, pc.size).get_center()
	pc.queue_free()
	hand.create(st, res.uid, from)
	note("unplace %s %s" % [st.cards[res.uid].id, ally])
	_set_idle()


## 노엘의 표를 누름 → 손패로(효과도 없던 일로)
func _return_tag(index: int) -> void:
	var res := RulesV2.uncast(st, index)
	if not res.ok:
		_toast_reason(res.reason)
		return
	var from := deck_center()
	if index < tags.size() and is_instance_valid(tags[index]):
		from = Rect2(tags[index].position, tags[index].size).get_center()
	hand.create(st, res.uid, from)
	note("uncast %s" % st.cards[res.uid].id)
	_set_idle()


# ───────── 턴 끝 → 적 턴 ─────────
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
	_sync()
	note("endTurn %d" % int(st.turn))
	await _play(RulesV2.end_turn(st))
	if not is_inside_tree():
		return
	if st.result != null:
		_show_result()
		return
	await _play(RulesV2.start_turn(st))
	_set_idle()


# ───────── 연출 ─────────
func _play(events: Array) -> void:
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
	hud.queue_redraw()
	await FX.wait(260)


func _ev_draw(e: Dictionary) -> void:
	var list: Array = e.uids
	_hidden = list.duplicate()
	for u in list:
		_hidden.erase(u)
		hand.create(st, u, deck_center())
		hand.layout()
		hud.queue_redraw()
		await FX.wait(90)
	_hidden = []


func _ev_reshuffle(_e: Dictionary) -> void:
	FX.toast(T("reshuffle"), 1000)
	await FX.wait(200)


func _ev_intents(_e: Dictionary) -> void:
	_sync()
	await FX.wait(380)


func _ev_allyPhase(_e: Dictionary) -> void:
	await FX.wait(120)


func _flash(c: Control, prop := "act") -> void:
	FX.anim(460, [{"k": 0.0}, {"k": 1.0, "o": 0.3}, {"k": 0.0}], func(v):
		if is_instance_valid(c):
			c.set(prop, v.k)
			c.queue_redraw(), {"node": c})


func _shake(c: Control, power := 8.0) -> void:
	var base := c.position
	FX.anim(260, [{"x": 0.0}, {"x": power}, {"x": -power * 0.8}, {"x": power * 0.5}, {"x": 0.0}], func(v):
		if is_instance_valid(c):
			c.position = base + Vector2(v.x, 0), {"node": c, "key": "shake_%d" % c.get_instance_id()})


func _placed_piece(uid: String) -> BoardPieces.PlacedCard:
	for id in placed_cards:
		for pc in placed_cards[id]:
			if pc.uid == uid:
				return pc
	return null


func _ev_act(e: Dictionary) -> void:
	_flash(ally_cards[e.ally])
	var pc := _placed_piece(str(e.uid))
	if pc != null:
		_flash(pc)
	await FX.wait(240)


func _ev_retarget(e: Dictionary) -> void:
	var pc := _placed_piece(str(e.uid))
	var te = RulesV2.enemy(st, str(e.enemy))
	if pc != null and te != null:
		pc.target_type = str(te.type)
		pc.target_tag = str(te.tag)
		pc.queue_redraw()
	await FX.wait(60)


func _ev_hit(e: Dictionary) -> void:
	var c: BoardPieces.EnemyCard = enemy_cards[e.enemy]
	c.hp = int(e.hp)
	c.queue_redraw()
	var r := Rect2(c.position, c.size)
	_shake(c)
	FX.slash(r.get_center().x, r.get_center().y, {"len": 200, "color": "#ffe6c8", "width": 7})
	FX.float_text(r.get_center().x, r.get_center().y, e.amount, "enemy")
	await FX.wait(300)


func _ev_enemyDie(e: Dictionary) -> void:
	var c: BoardPieces.EnemyCard = enemy_cards[e.enemy]
	var ac: Control = act_cards.get(e.enemy)
	if ac != null:
		act_cards.erase(e.enemy)
		FX.anim(260, [{"a": 1.0}, {"a": 0.0}], func(v): if is_instance_valid(ac): ac.modulate.a = v.a, {"node": ac}).finished.connect(func(): if is_instance_valid(ac): ac.queue_free())
	if c.minion:
		FX.anim(300, [{"a": 1.0, "s": 1.0}, {"a": 0.0, "s": 0.85}], func(v):
			if is_instance_valid(c):
				c.modulate.a = v.a
				c.scale = Vector2(v.s, v.s), {"node": c})
		await FX.wait(320)
		c.alive = false
		c.visible = false
		c.modulate.a = 1.0
		c.scale = Vector2.ONE
	else:
		# 뒤집혀 뒷면으로
		var a := FX.anim(300, [{"x": 1.0}, {"x": 0.0, "o": 0.5}, {"x": 1.0}], func(v):
			if is_instance_valid(c):
				c.scale = Vector2(maxf(0.02, v.x), 1.0), {"node": c})
		await FX.wait(150)
		c.alive = false
		c.queue_redraw()
		await FX.until(a)
	_update_shock()
	_layout_acts(true)


func _ev_block(e: Dictionary) -> void:
	var c: BoardPieces.AllyCard = ally_cards[e.ally]
	c.block = int(e.total)
	c.queue_redraw()
	FX.float_text(c.position.x + c.size.x - 30, c.position.y + 40, T("block", {"n": e.amount}), "small")
	await FX.wait(200)


func _ev_mult(e: Dictionary) -> void:
	var c: BoardPieces.AllyCard = ally_cards[e.ally]
	c.status_value = "×" + str(e.mult)
	c.queue_redraw()
	await FX.wait(140)


func _ev_brace(e: Dictionary) -> void:
	var c: BoardPieces.AllyCard = ally_cards[e.ally]
	c.status_value = str(e.brace)
	c.queue_redraw()
	await FX.wait(80)


func _ev_win(_e: Dictionary) -> void:
	await FX.wait(300)


func _ev_enemyPhase(_e: Dictionary) -> void:
	FX.banner(T("enemyTurn"), 700)
	await FX.wait(420)


func _ev_enemyAct(e: Dictionary) -> void:
	if str(e.kind) == "summon":
		await FX.wait(200)
		return
	var ac: Control = act_cards.get(e.enemy)
	if ac != null:
		act_cards.erase(e.enemy)
		var p0 := ac.position
		var to: Vector2
		if str(e.kind) == "sweep":
			to = Vector2(p0.x, float(L().ally.y) + 40)
		else:
			var ar := ally_rect(str(e.slot))
			to = ar.get_center() - ac.size / 2.0
		var a := FX.anim(240, [{"k": 0.0}, {"k": 1.0}], func(v):
			if is_instance_valid(ac):
				ac.position = p0.lerp(to, v.k), {"node": ac, "easing": "ease-in"})
		await FX.until(a)
		FX.anim(200, [{"a": 1.0}, {"a": 0.0}], func(v): if is_instance_valid(ac): ac.modulate.a = v.a, {"node": ac}).finished.connect(func(): if is_instance_valid(ac): ac.queue_free())
		_update_shock()
	await FX.wait(60)


func _ev_summon(e: Dictionary) -> void:
	var c: BoardPieces.EnemyCard = enemy_cards[e.minion]
	var m = RulesV2.enemy(st, str(e.minion))
	ghost.visible = false
	c.alive = true
	c.visible = true
	c.hp = int(m.maxHp) if m != null else c.hp
	c.queue_redraw()
	FX.anim(320, [{"s": 0.6, "a": 0.0}, {"s": 1.0, "a": 1.0}], func(v):
		if is_instance_valid(c):
			c.scale = Vector2(v.s, v.s)
			c.modulate.a = v.a, {"node": c, "easing": "ease-out"})
	FX.toast(T("summoned", {"name": BattleV2Data.D.enemies[c.type].name}), 1000)
	await FX.wait(420)


func _ev_allyHit(e: Dictionary) -> void:
	var c: BoardPieces.AllyCard = ally_cards[e.ally]
	c.hp = int(e.hp)
	c.block = int(e.block)
	c.queue_redraw()
	_shake(c, 10.0)
	var ctr := c.position + c.size / 2.0
	if int(e.amount) > 0:
		FX.float_text(ctr.x, ctr.y, -int(e.amount), "ally")
	if int(e.blocked) > 0:
		FX.float_text(ctr.x, ctr.y - 70, T("blocked", {"n": e.blocked}), "small")
	await FX.wait(260)


func _ev_counter(e: Dictionary) -> void:
	var a: Vector2 = ally_cards[e.ally].position + ally_cards[e.ally].size / 2.0
	var ec: Control = enemy_cards[e.enemy]
	var b := ec.position + ec.size / 2.0
	FX.float_text(a.x, a.y - 110, T("counter", {"n": BattleV2Data.D.traits.hero.counter}), "small")
	await FX.streak(a.x, a.y - 60, b.x, b.y, {"color": "#ffe6c8", "width": 5, "dur": 200})


func _ev_allyDown(e: Dictionary) -> void:
	var c: BoardPieces.AllyCard = ally_cards[e.ally]
	c.down = true
	c.queue_redraw()
	_update_shock()
	await FX.wait(320)


func _ev_lose(_e: Dictionary) -> void:
	await FX.wait(300)


func _ev_cleanup(_e: Dictionary) -> void:
	var gone := []
	for id in placed_cards:
		gone.append_array(placed_cards[id])
		placed_cards[id] = []
	gone.append_array(tags)
	tags = []
	for eid in act_cards:
		gone.append(act_cards[eid])
	act_cards = {}
	for u in hand.cards.keys():
		var c: CardView = hand.detach(u)
		if c != null:
			gone.append(c)
	for n in gone:
		var nd = n
		FX.anim(260, [{"a": 1.0}, {"a": 0.0}], func(v):
			if is_instance_valid(nd):
				if nd is CardView:
					nd.alpha = v.a
				else:
					nd.modulate.a = v.a, {"node": nd}).finished.connect(func(): if is_instance_valid(nd): nd.queue_free())
	await FX.wait(300)
	for id in ally_cards:
		ally_cards[id].block = 0
		ally_cards[id].queue_redraw()
	if st.result == null:
		_sync()


# ───────── 결과 판 ─────────
func _show_result() -> void:
	mode = "over"
	_end_pending_marks()
	hand.set_hover("")
	# 손에 남은 앞면 카드(연출 도중의 것까지)를 치운다 — 쥔 덱(뒷면)만 남는다
	for c in hand.get_children():
		if c is CardView and not hand.backs.has(c):
			c.queue_free()
	hand.cards = {}
	end_btn.disabled = true
	end_btn.queue_redraw()
	var win: bool = st.result == "win"
	var hp := []
	for id in st.order:
		hp.append("%s=%d/%d" % [id, int(st.allies[id].hp), int(st.allies[id].maxHp)])
	G.ctl.note("result v2 %s turn=%d %s" % [str(st.result), int(st.turn), " ".join(hp)])
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
	var box := Rect2(960 - 470, 250, 940, 470)
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
	t.position = Vector2(box.position.x, box.position.y + 52)
	t.size = Vector2(box.size.x, 120)
	result_panel.add_child(t)
	var sub := UI.label(T("winText" if win else "loseText", {"n": st.turn}), 30, ink, "serif", HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(box.position.x, box.position.y + 176)
	sub.size = Vector2(box.size.x, 44)
	result_panel.add_child(sub)
	# 동료 셋의 얼굴과 남은 HP
	var x0 := 960.0 - 3 * 220.0 / 2.0
	for i in st.order.size():
		var id: String = st.order[i]
		var a: Dictionary = st.allies[id]
		var face := TextureRect.new()
		face.texture = Assets.face_tex(id, null, true)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.position = Vector2(x0 + i * 220 + 62, box.position.y + 236)
		face.size = Vector2(96, 96)
		face.modulate = Color(0.4, 0.36, 0.36) if a.down else Color.WHITE
		result_panel.add_child(face)
		var hl := UI.label(T("down") if a.down else "%d / %d" % [int(a.hp), int(a.maxHp)], 24, crimson if a.down else ink, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
		hl.position = Vector2(x0 + i * 220, box.position.y + 336)
		hl.size = Vector2(220, 34)
		result_panel.add_child(hl)
	var again := UI.button(T("again"), 34, restart)
	again.name = "again"
	again.fit(Vector2(60, 16))
	again.position = Vector2(960 - again.size.x / 2.0, box.end.y + 24)
	result_panel.add_child(again)
	add_child(result_panel)
	result_panel.modulate.a = 0.0
	FX.anim(400, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(result_panel): result_panel.modulate.a = v.a, {"node": result_panel})
	if G.params.has("quit-on-end"):
		get_tree().create_timer(1.0, false).timeout.connect(func(): get_tree().quit(0))


## 「다시 하기」: 같은 전투(같은 시드)를 처음부터
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


# ───────── 자동 진행 (--autoplay) ─────────
func _process(delta: float) -> void:
	if not G.params.has("autoplay") or mode != "idle" or _auto_busy or st.is_empty():
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
			if b.mode != "idle":
				return {"ok": false, "mode": b.mode}
			b.auto_step()
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
		al[id] = {"hp": a.hp, "maxHp": a.maxHp, "down": a.down, "brace": a.brace, "mult": a.mult, "blessed": a.blessed,
			"shocked": ally_cards[id].shocked, "placed": a.placed.map(func(p): return {"id": st.cards[p.uid].id, "target": p.target}),
			"shown": placed_cards[id].size(), "lines": placed_cards[id].map(func(pc): return pc.line)}
	var en := []
	for e in st.enemies:
		en.append({"id": e.id, "type": e.type, "hp": e.hp, "alive": e.alive, "vuln": e.vuln, "intent": e.intent, "act": act_cards.has(e.id)})
	return {"ok": true, "mode": mode, "turn": st.turn, "energy": st.energy, "result": st.result, "deck": st.draw.size(), "hand": hand_out,
		"allies": al, "enemies": en, "noel": st.noel.map(func(n): return {"kind": n.kind, "target": n.target}), "pending": not pending.is_empty(),
		"handCards": hand.cards.size(), "maxHands": hand.max_hands, "handsNow": hand.hands_visible(), "log": log.slice(maxi(0, log.size() - 30))}


## 화면 좌표(무대 1920×1080): card(손패 카드 id 또는 uid) · ally · column · enemy · act · placed("동료:번호") · endTurn · again
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
			r = ally_rect(id)
		"column":
			r = Rect2(col_x(id) - 100, float(L().placed.y), 200, float(L().placed.h))
		"enemy":
			r = enemy_rect(id)
			if RulesV2.guard_of(st, id) != null:
				r = Rect2(r.position, Vector2(r.size.x, float(L().minion.dy)))   # 하수인에 가리지 않은 윗부분
		"act":
			if not act_cards.has(id):
				return {}
			r = act_rect(id)
		"placed":
			var pp := id.split(":")
			if pp.size() < 2 or not placed_cards.has(pp[0]) or int(pp[1]) >= placed_cards[pp[0]].size():
				return {}
			var pc: Control = placed_cards[pp[0]][int(pp[1])]
			r = Rect2(pc.position, pc.size)
		"endTurn":
			r = Rect2(end_btn.position, end_btn.size)
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
