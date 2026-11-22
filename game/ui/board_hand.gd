## board_hand.gd — 전투 시험판 v2 「맡기기」의 노엘의 손과 손패 (scenes/board_battle.gd).
## 지금 전투의 손(HandView: 손 그림 두 장·부채꼴 카드 자리·덱 덮개·마우스 올림 확대·끌기)을 그대로 물려받고,
## 손패 목록과 카드 앞면만 v2 상태(RulesV2)에서 읽는다. 손 자리는 지금 전투와 같고, 끄는 카드 크기만 BattleV2Data.layout.hand 로 덮어쓴다.
## 지금 게임의 hand.gd·card_view.gd 는 건드리지 않는다(?battle=v2 가 아니면 쓰이지 않음).
class_name BoardHand
extends HandView

var board = null          # BoardBattle (손패 목록·덱 자리)
var _hl := {}


## 손 배치: 지금 전투의 layout.hand 에 v2 의 끄는 카드 배율을 덮어쓴 것
func HL() -> Dictionary:
	if _hl.is_empty():
		_hl = GameData.D.layout.hand.duplicate()
		var o: Dictionary = BattleV2Data.D.layout.hand
		for k in o:
			_hl[k] = o[k]
	return _hl


func create(st: Dictionary, uid: String, from = null) -> CardView:
	var c := Card.new()
	add_child(c)
	c.setup_face(st, uid)
	c.z_index = 50
	var p: Vector2 = from if from is Vector2 else (board.deck_center() if board != null else Vector2(260, 960))
	c.set_rect(p - Vector2(CardView.W, CardView.H) * 0.15, 0.3, true)
	c.alpha = 0.0
	FX.anim(250, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(c): c.alpha = v.a, {"node": c})
	cards[uid] = c
	return c


## 낼 수 있는(예지가 되는) 카드에 금빛 테두리
func update_classes(st: Dictionary, busy: bool) -> void:
	for uid in cards:
		cards[uid].glow = 1.0 if (not busy and RulesV2.affordable(st, uid)) else 0.0


## 손패 배치 — HandView.layout 과 같은 규칙(끌기·확대·부채꼴), 목록만 v2 상태에서
func layout(_instant := false) -> void:
	if board == null or board.st.is_empty():
		return
	var st: Dictionary = board.st
	var list: Array = board.hand_list()
	var f := fan(list.size())
	for i in list.size():
		var uid: String = list[i]
		var c: CardView = cards.get(uid)
		if c == null:
			c = create(st, uid)
		var fi: Dictionary = f[i]
		c.shadow = 0.0
		if uid == drag_uid and drag_mode == "follow":
			var d := drag_rect()
			c.set_rect(d.position, float(HL().dragScale), false)
			c.z_index = 130
			c.smooth = false
		elif (uid == hover_uid and drag_uid == "") or uid == lifted_uid:
			var r := hover_rect(uid)
			c.set_rect(r.position, FX.card_preview, false)
			c.z_index = 125 if uid == lifted_uid else 120
			c.shadow = 1.0
			c.smooth = true
		else:
			c.set_quad(fi.quad, false)
			c.z_index = int(fi.z)
			c.smooth = true
	for uid in cards.keys():
		if not list.has(uid):
			cards[uid].queue_free()
			cards.erase(uid)


## v2 카드 앞면: 지금 카드와 같은 틀(card_frame.png)·그림 창·이름·설명·비용(행동 에너지) 자리·아래쪽 주인(공용·동료 전용·노엘).
## 데이터는 BattleV2Data.cards. 그림이 없는 카드(축복)는 코드로 그린 빛(BoardPieces.bless_art), dark 면 그림을 어둡게
class Card extends CardView:
	func build(st: Dictionary) -> void:
		for c in face.get_children():
			c.queue_free()
		card_id = st.cards[uid].id
		var d: Dictionary = BattleV2Data.D.cards[card_id]
		var s := K
		var bg := UI.panel(UI.box(Color("#170e18"), Color.TRANSPARENT, int(14 * s)))
		bg.size = face.size
		face.add_child(bg)
		var art_r := Rect2(Vector2(22, 24) * s, Vector2(201, 204) * s)
		if str(d.art) != "" and Assets.ok(str(d.art)):
			var art := UI.cover_rect(Assets.tex(str(d.art)), art_r)
			if bool(d.get("dark", false)):
				art.modulate = Color(0.6, 0.56, 0.58)
			face.add_child(art)
		else:
			var ac := Control.new()
			ac.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ac.position = art_r.position
			ac.size = art_r.size
			ac.draw.connect(func(): BoardPieces.bless_art(ac, Rect2(Vector2.ZERO, ac.size)))
			face.add_child(ac)
		if Assets.ok("card_frame.png"):
			face.add_child(UI.tex_rect(Assets.tex("card_frame.png"), Rect2(Vector2.ZERO, face.size)))
		var nm := UI.label(str(d.name), int(21 * s), Color("#f4ead6"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, int(3 * s))
		nm.position = Vector2(10, 238) * s
		nm.size = Vector2(220, 32) * s
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		face.add_child(nm)
		var cc := CenterContainer.new()
		cc.position = Vector2(20, 270) * s
		cc.size = Vector2(200, 62) * s
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rt := UI.rich(int(15 * s), Color("#e7dfd2"))
		rt.custom_minimum_size = Vector2(200, 0) * s
		rt.add_theme_constant_override("line_separation", int(-1 * s))
		var n := int(d.get("damage", d.get("block", 0)))
		var txt := UI.esc(str(d.text)).replace("{n}", "[b][color=#ffcf6a]%d[/color][/b]" % n)
		rt.text = "[center]" + txt + "[/center]"
		cc.add_child(rt)
		face.add_child(cc)
		var own := str(d.get("owner", ""))
		var ocol: Color = {"hero": Color("#cfd3dd"), "warrior": Color("#c9a985"), "archer": Color("#9fc38f"), "noel": Color("#c79ab0")}.get(own, Color("#a8a2a0"))
		var ow := UI.label(str(BattleV2Data.D.owners.get(own, "")), int(12 * s), ocol, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
		ow.position = Vector2(0, 360 - 16 - 17) * s
		ow.size = Vector2(240, 17) * s
		face.add_child(ow)
		var cost := Panel.new()
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost.position = Vector2(15, 16) * s
		cost.size = Vector2(37, 37) * s
		cost.add_theme_stylebox_override("panel", UI.box(Color("#b3121f"), Color("#1b0b0e"), int(19 * s), int(2 * s)))
		face.add_child(cost)
		var cl := UI.label(str(d.cost), int(22 * s), Color.WHITE, "serif_black", HORIZONTAL_ALIGNMENT_CENTER, int(3 * s))
		cl.size = cost.size
		cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost.add_child(cl)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE

	## 상태 표시는 글로(금빛 테두리)만 — 앞면은 그대로
	func refresh(_st: Dictionary) -> void:
		pass
