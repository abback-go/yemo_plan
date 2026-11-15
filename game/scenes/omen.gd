## omen.gd — 죽음 카드가 노엘의 손 위로 떠오르는 연출 (캠프·계단·빈 캠프).
##  · 캠프·계단: 「용사의 죽음」이 또렷하게 떠오른다(카드 문구까지 읽힌다). 세라피나 쪽 붉은 실이 팽팽해진다.
##  · 빈 캠프: 누구인지 알아볼 수 없을 만큼 흐린 카드. 실은 특정 동료에게 걸리지 않고 남은 둘 쪽이 아주 희미하게 떨릴 뿐.
## 손 그림은 전투의 '카드를 세워 든 오른손'(ui_witch_hand_raise.png)을 그대로 쓴다. 배치는 game_data.gd "omen".
class_name OmenView
extends Node2D

var vn: VnScene
var dim: ColorRect
var rig: Node2D
var card: CardView
var hand_spr: Sprite2D
var taut: Array = []
var faint: Array = []
var tension := 0.0
var faint_a := 0.0
var showing := false
var _t := 0.0


func _ready() -> void:
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.size = Vector2(1920, 1080)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var th := Node2D.new()
	th.name = "threads"
	add_child(th)
	th.draw.connect(_draw_threads.bind(th))
	rig = Node2D.new()
	rig.visible = false
	add_child(rig)


func _conf() -> Dictionary:
	return GameData.D.omen


## 카드 자리(손 그림 좌표 → 화면)
func _quad() -> PackedVector2Array:
	var o := _conf()
	var r: Dictionary = GameData.D.layout.raise
	var q := PackedVector2Array()
	for p in r.quad:
		q.append(Vector2(float(o.x) + float(p[0]) * float(o.scale), float(o.y) + float(p[1]) * float(o.scale)))
	return q


func show_omen(cfg: Dictionary) -> void:
	var o := _conf()
	showing = true
	taut = cfg.get("taut", [])
	faint = cfg.get("faint", [])
	for c in rig.get_children():
		c.queue_free()
	var st: Dictionary = G.ctl.st
	card = CardView.new()
	rig.add_child(card)
	var cid: String = cfg.get("card", "")
	var uid := ""
	for u in st.party.get("deathCards", []):
		if st.cards[u].id == cid:
			uid = u
	if cid != "" and uid == "":
		uid = "tmp_omen"
		st.cards[uid] = {"uid": uid, "id": cid}
	if cid != "":
		card.setup_face(st, uid)
		if uid == "tmp_omen":
			st.cards.erase(uid)
		card.apply_blur(clampf(1.0 - float(cfg.get("clarity", 1.0)), 0.0, 1.0))
	else:
		card.setup_unknown()
		card.apply_blur(1.0)
	# 카드는 손에 쥐이지 않고 손 위로 떠오른다(엄지가 문구를 가리지 않게) — 대본 1장 "손 위에 카드 한 장이 떠오른다"
	var ck: float = o.get("cardK", 1.4)
	card.set_rect(Vector2(o.cardX, o.cardY), ck, true)
	card.smooth = false
	hand_spr = Sprite2D.new()
	hand_spr.texture = Assets.tex(GameData.D.layout.raise.img)
	hand_spr.centered = false
	hand_spr.position = Vector2(o.x, o.y)
	hand_spr.scale = Vector2.ONE * float(o.scale)
	rig.add_child(hand_spr)
	rig.move_child(hand_spr, 0)
	rig.visible = true
	var from := Vector2(o.from[0], o.from[1])
	var d: float = cfg.get("dim", 0.25)
	if cfg.get("fireLow", false) and vn.fire:
		vn._fire_low = true
	# 화면이 아주 살짝 어두워진다(효과음 없이) → 손 위로 카드가 떠오른다 → 실이 팽팽해진다
	FX.anim(600, [{"a": 0.0}, {"a": d}], func(v): dim.color.a = v.a, {"node": self, "key": "omen_dim"})
	var a := FX.anim(float(o.rise), [{"p": from, "a": 0.0}, {"o": 0.4, "a": 1.0}, {"p": Vector2.ZERO, "a": 1.0}], func(v):
		rig.position = v.p
		rig.modulate.a = v.a, {"node": self, "easing": "cubic-bezier(.2,.7,.3,1)", "key": "omen_rig"})
	FX.anim(900, [{"t": 0.0}, {"t": 1.0}], func(v): tension = v.t; faint_a = v.t, {"node": self, "key": "omen_t", "delay": float(o.rise) * 0.6})
	await FX.until(a)
	await FX.wait(float(cfg.get("hold", 900)))


## 카드가 손 안으로 가라앉듯 사라진다
func hide_omen() -> void:
	if not showing:
		return
	var o := _conf()
	var a := FX.anim(float(o.fade), [{"p": Vector2.ZERO, "a": 1.0, "d": dim.color.a, "t": tension}, {"p": Vector2(40, 260), "a": 0.0, "d": 0.0, "t": 0.0}], func(v):
		rig.position = v.p
		rig.modulate.a = v.a
		dim.color.a = v.d
		tension = v.t
		faint_a = v.t, {"node": self, "easing": "ease-in", "key": "omen_rig"})
	await FX.until(a)
	rig.visible = false
	showing = false
	taut = []
	faint = []
	get_node("threads").queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if showing and card:
		var o := _conf()
		card.set_rect(Vector2(o.cardX, o.cardY + sin(_t * 1.6) * 6.0), float(o.get("cardK", 1.4)), true)
	if showing:
		get_node("threads").queue_redraw()
		if card and not taut.is_empty():
			card.taut = tension * 0.8
			card.queue_redraw()


func _draw_threads(ci: Node2D) -> void:
	if not showing or card == null:
		return
	var q := card.corners
	var top: Vector2 = rig.position + q[0].lerp(q[3], 0.12) + Vector2(3, 0)
	for who in taut:
		var a = vn.anchor_of(who)
		if a == null:
			continue
		var m: Vector2 = (a + top) / 2.0
		var vib := (1.5 + tension * 2.5) * sin(_t * 60.0)
		var sag := (1.0 - tension) * 60.0
		var k := 1.0 + tension * 2.0
		UI.glow_curve(ci, a, m + Vector2(vib, sag + vib * 0.5), top, 1.8 + k * 0.9, Color(1, 0.16, 0.24, 0.5 + 0.45 * tension), 10.0 + k * 4.0)
		ci.draw_circle(top, 4, Color(1, 0.24, 0.31, 0.95))
		ci.draw_circle(a, 3, Color(1, 0.24, 0.31, 0.9 * tension))
	# 아주 희미하게 떨리기만 하는 실 (어느 쪽이 팽팽해지는지는 보여 주지 않는다)
	var i := 0
	for who in faint:
		var a2 = vn.anchor_of(who)
		if a2 == null:
			continue
		var m2: Vector2 = (a2 + top) / 2.0
		var tr := sin(_t * (23.0 + i * 7.0)) * 3.0 + sin(_t * 2.1 + i) * 8.0
		UI.glow_curve(ci, a2, m2 + Vector2(tr, 70 + tr * 0.4), top + Vector2(0, 10 + i * 6), 1.2, Color(0.9, 0.12, 0.2, 0.16 * faint_a), 4.0)
		i += 1
