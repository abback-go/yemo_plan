## hand.gd — 마녀의 손과 손패 (HTML 판 hand.js 를 옮기고 '손 세 개' 문제를 고쳤다).
## 손 그림(ui_witch_hands.png)을 왼손/오른손으로 나눈 그림 두 장의 투명한 카드 자리에 맞춰 카드를 원근 사각형으로 끼운다.
## 카드는 손 그림 아래 → 엄지가 카드 위에 겹쳐 쥔 것처럼 보인다.
##
## 카드 내기: ① 오른손만 손패에서 빠져 내려간다(오른쪽 덱 덮개와 함께). 손패는 왼손 쪽으로 살짝 모인다.
##            ② 카드를 세워 든 오른손(ui_witch_hand_raise.png)이 올라와 카드를 보여 준다 → 효과
##            ③ 세운 손이 내려간 뒤 오른손이 손패로 돌아온다. 왼손은 내내 손패를 쥐고 있다.
##  → 어느 순간에도 보이는 손은 둘(왼손 + 오른손 하나)뿐이다. hands_visible() 로 확인한다.
##
## 대상 카드 조준: 끌기 시작하면 ① 오른손이 손패에서 빠지고 ② 같은 세운 손 그림을 작게 줄인 오른손(layout.grip)이 그 카드를 쥐고
##   손패 높이로 올라온다(화살표는 쥔 카드에서 나간다). 놓아서 확정하면 이 작은 손이 그대로 커지며 세운 손이 되고(raise_card),
##   취소하면 카드를 손패로 돌려놓고 내려간 뒤 오른손이 손패로 돌아온다(aim_release).
class_name HandView
extends Node2D

var cards := {}           # uid → CardView
var backs: Array = []     # 덱 덮개(뒷면 카드) 5장
var left: Sprite2D
var right: Sprite2D
var rig: Node2D           # 카드를 세워 드는 오른손
var raise_img: Sprite2D
var fly: Node2D           # 날아가는 카드
var raised := {}          # {"uid", "card"}
var hover_uid := ""
var lifted_uid := ""
var drag_uid := ""
var drag_mode := ""
var drag_pos := Vector2(960, 600)
var dy := 0.0             # 손패 전체가 내려간 거리
var gather := 0.0         # 0~1: 오른손이 빠지는 동안 손패가 왼손 쪽으로 모인 정도
var right_out := 0.0      # 0~1: 오른손이 빠진 정도
var rig_off := Vector2.ZERO
var rig_alpha := 0.0
var tremble := 0.0
var raise_log: Array = []
var busy_hands := false   # 세운 손이 내려가고 오른손이 돌아오는 중
var rig_scale := 1.0      # 세운 손 배율(작게 쥔 손일 때 layout.grip.scale)
var grip_uid := ""        # 조준 중 작은 오른손이 쥐러 가는(또는 쥔) 카드
var grip := {}            # 작은 오른손이 쥔 카드 {"uid", "card", "glow"} — 쥔 동안은 cards 에서 빠져 rig 아래에 있다
var _grip_gen := 0        # 조준·취소가 겹칠 때 앞선 연출을 무효로 한다
signal hands_back
var max_hands := 0        # 시험용: 한 번에 보인 손의 최대 수
var _tt := 0.0


func HL() -> Dictionary:
	return GameData.D.layout.hand


func RL() -> Dictionary:
	return GameData.D.layout.raise


func GL() -> Dictionary:
	return GameData.D.layout.grip


func _ready() -> void:
	var hl := HL()
	for i in hl.slots.size():
		var b := CardView.new()
		b.setup_back()
		b.bright = 0.82
		b.z_index = 41 + (2 if i == 2 else (1 if i == 1 or i == 3 else 0))
		add_child(b)
		backs.append(b)
	fly = Node2D.new()
	fly.z_index = 140
	add_child(fly)
	left = Sprite2D.new()
	left.texture = Assets.tex(hl.imgL)
	left.centered = false
	left.scale = Vector2.ONE * float(hl.scale)
	left.z_index = 80
	add_child(left)
	right = Sprite2D.new()
	right.texture = Assets.tex(hl.imgR)
	right.centered = false
	right.scale = Vector2.ONE * float(hl.scale)
	right.z_index = 80
	add_child(right)
	rig = Node2D.new()
	rig.z_index = 141
	add_child(rig)
	var r := RL()
	raise_img = Sprite2D.new()
	raise_img.texture = Assets.tex(r.img)
	raise_img.centered = false
	raise_img.position = Vector2(r.x, r.y)
	raise_img.scale = Vector2.ONE * float(r.scale)
	raise_img.z_index = 1
	rig.add_child(raise_img)
	rig_off = Vector2(r.from[0], r.from[1])
	rig_alpha = 0.0
	_apply_rig()
	layout_static(true)


func clear() -> void:
	for u in cards:
		cards[u].queue_free()
	cards = {}
	if raised.has("card") and is_instance_valid(raised.card):
		raised.card.queue_free()
	raised = {}
	if grip.has("card") and is_instance_valid(grip.card):
		grip.card.queue_free()
	grip = {}
	grip_uid = ""
	_grip_gen += 1
	rig_scale = 1.0
	for c in fly.get_children():
		c.queue_free()
	hover_uid = ""
	lifted_uid = ""
	drag_uid = ""
	drag_mode = ""
	dy = 0.0
	gather = 0.0
	right_out = 0.0
	tremble = 0.0
	rig_off = Vector2(RL().from[0], RL().from[1])
	rig_alpha = 0.0
	_apply_rig()
	layout_static(true)


# ───────── 기하 ─────────
func to_screen(p) -> Vector2:
	var h := HL()
	return Vector2(float(h.x) + float(p[0]) * float(h.scale), float(h.y) + dy + float(p[1]) * float(h.scale))


func slot_quad(i: int) -> PackedVector2Array:
	var s: Array = HL().slots[i]
	var f: float = HL().cardFrac
	var tl := Vector2(s[3][0], s[3][1]).lerp(Vector2(s[0][0], s[0][1]), f)
	var tr := Vector2(s[2][0], s[2][1]).lerp(Vector2(s[1][0], s[1][1]), f)
	return PackedVector2Array([to_screen([tl.x, tl.y]), to_screen([tr.x, tr.y]), to_screen(s[2]), to_screen(s[3])])


## 0~4 사이 실수 위치의 사각형 (이웃 슬롯 사이를 꼭짓점별로 보간)
func quad_at(s: float) -> PackedVector2Array:
	var n: int = HL().slots.size()
	s = clampf(s, 0.0, n - 1.0)
	var i := mini(n - 2, int(floor(s)))
	var t := s - i
	var a := slot_quad(i)
	var b := slot_quad(i + 1)
	return PackedVector2Array([a[0].lerp(b[0], t), a[1].lerp(b[1], t), a[2].lerp(b[2], t), a[3].lerp(b[3], t)])


## n장일 때 각 카드의 자리. 5장 이하는 슬롯 간격 그대로, 6장 이상은 같은 부채꼴 안에 압축.
## 오른손이 빠진 동안(gather)은 왼손 쪽으로 모은다.
func fan(n: int) -> Array:
	var slots: int = HL().slots.size()
	var mid := (slots - 1) / 2.0
	var res := []
	if n <= 0:
		return res
	var spacing := 1.0 if n <= slots else (slots - 1.0) / (n - 1.0)
	var start := mid - (n - 1) * spacing / 2.0
	var gk: float = lerpf(1.0, float(HL().gather), gather)
	for i in n:
		var s := (start + i * spacing) * gk
		res.append({"s": s, "quad": quad_at(s), "key": -absf(start + i * spacing - mid) * 100.0 + i})
	var order := res.duplicate()
	order.sort_custom(func(a, b): return a.key < b.key)
	for k in order.size():
		order[k].z = 50 + k
	return res


func hover_rect(uid: String) -> Rect2:
	var k := FX.card_preview
	var w := CardView.W * k
	var h := CardView.H * k
	var cx := 960.0
	if cards.has(uid):
		cx = cards[uid].center().x
	cx = clampf(cx, w / 2.0 + 360.0, 1920.0 - w / 2.0 - 360.0)
	var bottom := float(HL().hoverBottom)
	return Rect2(cx - w / 2.0, minf(bottom - h, 1080.0 - h - 4.0) if h < 1080 else 0.0, w, h)


func drag_rect() -> Rect2:
	var k: float = HL().dragScale
	return Rect2(drag_pos - Vector2(CardView.W, CardView.H) * k / 2.0, Vector2(CardView.W, CardView.H) * k)


## 카드 윗변 가운데 (붉은 실이 걸리는 곳)
func top_point(uid: String):
	if raised.get("uid", "") == uid or grip.get("uid", "") == uid:
		return raise_top_point()
	if not cards.has(uid):
		return null
	return cards[uid].top_point()


func center_of(uid: String) -> Vector2:
	return cards[uid].center() if cards.has(uid) else Vector2(960, 800)


# ───────── 세워 드는 오른손 ─────────
func raise_quad() -> PackedVector2Array:
	var r := RL()
	var lift: Array = r.get("cardLift", [0, 0])
	var q := PackedVector2Array()
	for p in r.quad:
		q.append(Vector2(float(r.x) + (float(p[0]) + float(lift[0])) * float(r.scale), float(r.y) + (float(p[1]) + float(lift[1])) * float(r.scale)))
	return q


## 세운 카드에 붉은 실이 걸리는 곳: 세라피나 쪽(왼쪽) 변의 위쪽. 손이 올라오는 중·떨리는 중에도 따라간다
func raise_top_point() -> Vector2:
	var q := raise_quad()
	var p := q[0].lerp(q[3], 0.12) + Vector2(3, 0)
	return rig.transform * p


func _apply_rig() -> void:
	var jit := Vector2.ZERO
	var rot := 0.0
	if tremble > 0:
		jit = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * tremble
		rot = deg_to_rad(randf_range(-1, 1) * tremble * 0.12)
	rig.position = rig_off + jit
	rig.rotation = rot
	rig.scale = Vector2.ONE * rig_scale
	rig.modulate.a = rig_alpha
	rig.visible = rig_alpha > 0.001


## 카드 한 장을 세운 손으로 든다. 카드는 놓은 자리에서 올라오는 손 안으로 빨려 들어간다. slow: 죽음 카드처럼 천천히
func raise_card(uid: String, card: CardView, slow := false) -> void:
	var T: Dictionary = GameData.D.timing
	var up: float = T.deathRaiseUp if slow else T.raiseUp
	raise_log.append(card.card_id if card else uid)
	if card != null and card.get_parent() == rig:
		await _raise_from_grip(uid, card, up)
		return
	rig_scale = 1.0
	# ① 오른손이 빠지고 손패가 왼손 쪽으로 모인다
	await hand_out()
	if card == null:
		return
	raised = {"uid": uid, "card": card}
	var from_q := card.corners.duplicate()
	if card.get_parent() != rig:
		card.reparent(rig, false)
	card.z_index = 0
	card.shadow = 0.0
	card.glow = 0.0
	card.smooth = false
	var r := RL()
	var start := Vector2(r.from[0], r.from[1])
	var fin := raise_quad()
	rig_alpha = 1.0
	# ② 세운 손이 올라온다 (카드는 손 안으로)
	var a := FX.anim(up, [{"k": 0.0}, {"k": 1.0}], func(v):
		rig_off = start.lerp(Vector2.ZERO, v.k)
		_apply_rig()
		if is_instance_valid(card):
			var q := PackedVector2Array()
			for i in 4:
				q.append((from_q[i] - rig_off).lerp(fin[i], v.k))
			card.set_quad(q, true), {"node": card, "easing": "cubic-bezier(.2,.7,.3,1)", "key": "rig"})
	await FX.until(a)
	rig_off = Vector2.ZERO
	_apply_rig()


## 조준하며 작게 쥐고 있던 카드를 그 손이 그대로 커지며 세워 든다 (오른손은 이미 손패에서 빠져 있다)
func _raise_from_grip(uid: String, card: CardView, up: float) -> void:
	_grip_gen += 1
	grip = {}
	grip_uid = ""
	FX.cancel_key("rig")
	raised = {"uid": uid, "card": card}
	card.z_index = 0
	card.shadow = 0.0
	card.glow = 0.0
	card.smooth = false
	var p0 := rig_off
	var k0 := rig_scale
	var q0 := card.corners.duplicate()
	var fin := raise_quad()
	if right_out < 1.0:
		await hand_out()
	rig_alpha = 1.0
	var a := FX.anim(up, [{"k": 0.0}, {"k": 1.0}], func(v):
		rig_off = p0.lerp(Vector2.ZERO, v.k)
		rig_scale = lerpf(k0, 1.0, v.k)
		_apply_rig()
		if is_instance_valid(card):
			var q := PackedVector2Array()
			for i in 4:
				q.append(q0[i].lerp(fin[i], v.k))
			card.set_quad(q, true), {"node": card, "easing": "cubic-bezier(.2,.7,.3,1)", "key": "rig"})
	await FX.until(a)
	rig_off = Vector2.ZERO
	rig_scale = 1.0
	_apply_rig()


# ───────── 조준: 작은 오른손이 카드를 쥔다 ─────────
## 대상 카드를 끌기 시작했다 → 오른손이 빠지고, 작게 줄인 세운 손이 그 카드를 손패 높이에서 쥔다 (화살표는 그 카드에서)
func aim_grab(uid: String) -> void:
	if grip_uid == uid or not cards.has(uid) or not raised.is_empty() or busy_hands:
		return
	if grip_uid != "":
		_drop_grip()
	_grip_gen += 1
	var gen := _grip_gen
	grip_uid = uid
	# 앞선 취소 연출(작은 손이 내려가는 중)이 남아 있으면 바로 치운다 — 손이 셋 보이지 않게
	FX.cancel_key("rig")
	rig_alpha = 0.0
	rig_scale = 1.0
	rig_off = Vector2(RL().from[0], RL().from[1])
	_apply_rig()
	var T: Dictionary = GameData.D.timing
	# ① 오른손이 손패에서 빠진다 (카드는 손패 자리에서 aimLift 만큼 떠 있다)
	await hand_out(float(T.gripOut))
	if gen != _grip_gen or grip_uid != uid or not cards.has(uid):
		return
	# ② 작은 오른손이 아래에서 올라와 그 카드를 쥔다
	var card: CardView = cards[uid]
	cards.erase(uid)
	grip = {"uid": uid, "card": card, "glow": card.glow}
	var from_q := card.corners.duplicate()
	card.reparent(rig, false)
	card.z_index = 0
	card.shadow = 0.0
	card.glow = 0.0
	card.smooth = false
	var g := GL()
	rig_scale = float(g.scale)
	var to := Vector2(float(g.x), float(g.y))
	var start := to + Vector2(float(g.from[0]), float(g.from[1]))
	var fin := raise_quad()
	rig_alpha = 1.0
	rig_off = start
	_apply_rig()
	var a := FX.anim(float(T.gripUp), [{"k": 0.0}, {"k": 1.0}], func(v):
		rig_off = start.lerp(to, v.k)
		_apply_rig()
		if is_instance_valid(card) and card.get_parent() == rig:
			var inv := rig.transform.affine_inverse()
			var q := PackedVector2Array()
			for i in 4:
				q.append((inv * from_q[i]).lerp(fin[i], v.k))
			card.set_quad(q, true), {"node": card, "easing": "cubic-bezier(.2,.7,.3,1)", "key": "rig"})
	await FX.until(a)
	if gen != _grip_gen:
		return
	rig_off = to
	_apply_rig()
	layout()


## 쥔 카드를 손패 레이어로 되돌린다 (화면 좌표 그대로, 손패 자리로는 smooth 로 미끄러져 간다)
func _drop_grip() -> void:
	if grip.is_empty():
		return
	var c: CardView = grip.card
	var uid: String = grip.uid
	var glow: float = grip.get("glow", 0.0)
	grip = {}
	if not is_instance_valid(c):
		return
	var q := c.corners.duplicate()
	for i in 4:
		q[i] = rig.transform * q[i]
	c.reparent(self, false)
	c.set_quad(q, true)
	c.smooth = true
	c.glow = glow
	cards[uid] = c


## 조준을 취소했다 → 작은 오른손이 카드를 손패로 돌려놓고 내려간 뒤, 오른손이 손패로 돌아온다
func aim_release() -> void:
	if grip_uid == "" and grip.is_empty():
		return
	_grip_gen += 1
	var gen := _grip_gen
	grip_uid = ""
	var T: Dictionary = GameData.D.timing
	FX.cancel_key("rig")
	if not grip.is_empty():
		_drop_grip()
		layout()
		var r0 := rig_off
		var a0 := rig_alpha
		var down := Vector2(float(GL().from[0]), float(GL().from[1]))
		var a := FX.anim(float(T.gripBack), [{"k": 0.0}, {"k": 1.0}], func(v):
			rig_off = r0 + down * v.k
			rig_alpha = a0 * (1.0 - v.k)
			_apply_rig(), {"node": rig, "easing": "ease-in", "key": "rig"})
		await FX.until(a)
		if gen != _grip_gen:
			return
	rig_alpha = 0.0
	rig_scale = 1.0
	rig_off = Vector2(RL().from[0], RL().from[1])
	_apply_rig()
	layout()
	await hand_in()


## 세운 카드를 손에서 뗀다 (날아가는 연출용). 반환: 카드
func release_raised() -> CardView:
	if raised.is_empty():
		return null
	var card: CardView = raised.card
	raised = {}
	set_tremble(0)
	var q := card.corners.duplicate()
	for i in 4:
		q[i] = rig.transform * q[i]
	card.reparent(fly, false)
	card.set_quad(q, true)
	return card


## 세운 손을 내리고(③) 오른손을 손패로 되돌린다
func raise_down(ms := -1.0) -> void:
	var r := RL()
	var T: Dictionary = GameData.D.timing
	var dur: float = T.raiseDown if ms < 0 else ms
	busy_hands = true
	var to := Vector2(r.from[0], r.from[1]) * 0.6
	var a := FX.anim(dur, [{"p": Vector2.ZERO, "a": 1.0}, {"p": to, "a": 0.0}], func(v):
		rig_off = v.p
		rig_alpha = v.a
		_apply_rig(), {"node": rig, "easing": "ease-in", "key": "rig"})
	await FX.until(a)
	rig_alpha = 0.0
	rig_off = Vector2(r.from[0], r.from[1])
	_apply_rig()
	await hand_in()
	busy_hands = false
	hands_back.emit()


func hand_out(ms := -1.0) -> void:
	var T: Dictionary = GameData.D.timing
	var d0 := dy
	var g0 := gather
	var r0 := right_out
	var drop: float = HL().dropY
	var a := FX.anim(T.handOut if ms < 0 else ms, [{"k": 0.0}, {"k": 1.0}], func(v):
		dy = lerpf(d0, drop, v.k)
		gather = lerpf(g0, 1.0, v.k)
		right_out = lerpf(r0, 1.0, v.k)
		layout_static(), {"easing": "ease-in", "key": "handOut"})
	await FX.until(a)


func hand_in() -> void:
	var T: Dictionary = GameData.D.timing
	var d0 := dy
	var g0 := gather
	var r0 := right_out
	var a := FX.anim(T.handIn, [{"k": 0.0}, {"k": 1.0}], func(v):
		dy = lerpf(d0, 0.0, v.k)
		gather = lerpf(g0, 0.0, v.k)
		right_out = lerpf(r0, 0.0, v.k)
		layout_static(), {"easing": "ease-out", "key": "handOut"})
	await FX.until(a)


## 화면 밖(컷신 중 등)에서 손을 즉시 원래대로. 들고 있던 카드는 손패 레이어로 돌아온다
func raise_reset() -> void:
	set_tremble(0)
	FX.cancel_key("rig")
	FX.cancel_key("handOut")
	_grip_gen += 1
	grip_uid = ""
	_drop_grip()
	rig_alpha = 0.0
	rig_scale = 1.0
	rig_off = Vector2(RL().from[0], RL().from[1])
	_apply_rig()
	if not raised.is_empty():
		var c: CardView = raised.card
		raised = {}
		if is_instance_valid(c):
			c.reparent(self, false)
			c.smooth = true
			cards[c.uid] = c
	dy = 0.0
	gather = 0.0
	right_out = 0.0
	layout_static(true)
	layout(true)


func set_tremble(p: float) -> void:
	tremble = p * (0.3 if FX.reduced else 1.0)
	if p <= 0:
		_apply_rig()


# ───────── 카드 ─────────
func create(st: Dictionary, uid: String, from = null) -> CardView:
	var c := CardView.new()
	add_child(c)
	c.setup_face(st, uid)
	c.z_index = 50
	var p: Vector2 = from if from is Vector2 else Vector2(GameData.D.layout.drawPile.x, GameData.D.layout.drawPile.y)
	c.set_rect(p - Vector2(CardView.W, CardView.H) * 0.15, 0.3, true)
	c.alpha = 0.0
	FX.anim(250, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(c): c.alpha = v.a, {"node": c})
	cards[uid] = c
	return c


## 손패에서 떼어낸다 (사용 연출용). 반환된 카드는 부른 쪽이 지운다
func detach(uid: String) -> CardView:
	var c: CardView = cards.get(uid)
	cards.erase(uid)
	if grip_uid == uid:
		grip_uid = ""
		_grip_gen += 1
	if grip.get("uid", "") == uid:
		c = grip.card     # 작은 오른손이 쥔 채로 넘긴다 (raise_card 가 그 손을 키워 세운다)
		grip = {}
	if hover_uid == uid:
		hover_uid = ""
	if drag_uid == uid:
		drag_uid = ""
		drag_mode = ""
	if lifted_uid == uid:
		lifted_uid = ""
	return c


func render_card(st: Dictionary, uid: String) -> void:
	if cards.has(uid):
		cards[uid].build(st)


func update_classes(st: Dictionary, busy: bool) -> void:
	var b = st.battle
	for uid in cards:
		var c: CardView = cards[uid]
		if not st.cards.has(uid):
			continue
		c.refresh(st)
		var can: bool = b != null and b.phase == "player" and b.result == null and Rules.can_play(st, uid).ok and not busy
		c.glow = 1.0 if can else 0.0


# ───────── 배치 ─────────
func layout_static(_instant := false) -> void:
	var hl := HL()
	var sc: float = hl.scale
	var out: Array = hl.rightOut
	var ro := Vector2(out[0], out[1]) * right_out
	left.position = Vector2(float(hl.x), float(hl.y) + dy)
	right.position = Vector2(float(hl.x) + float(hl.splitX) * sc, float(hl.y) + dy) + ro
	right.modulate.a = 1.0 - smoothstep(0.85, 1.0, right_out)
	var rb: Array = hl.rightBacks
	for i in backs.size():
		var q := slot_quad(i)
		if rb.has(i):
			for k in 4:
				q[k] += ro
		backs[i].set_quad(q, true)
		backs[i].visible = bool(hl.backs)
		backs[i].alpha = 1.0 - (smoothstep(0.85, 1.0, right_out) if rb.has(i) else 0.0)
	layout(true)


func layout(instant := false) -> void:
	var vm: Dictionary = G.view.vm if G.view else {}
	if vm.is_empty():
		return
	var st: Dictionary = G.ctl.st
	var list: Array = vm.hand.duplicate()
	var raised_uid: String = raised.get("uid", "")
	# 들어 올린 카드(죽음 카드)는 부채꼴에서 빠지고, 나머지 카드가 자리를 메운다
	if vm.ghost != "" and vm.ghost != raised_uid and not list.has(vm.ghost):
		list.insert(clampi(int(vm.ghostIndex), 0, list.size()), vm.ghost)
	# 작은 오른손이 쥔 카드도 부채꼴에서 빠진다
	var grip_card: String = grip.get("uid", "")
	if grip_card != "":
		list.erase(grip_card)
	var f := fan(list.size())
	var sink: float = HL().get("lockSink", 0)
	for i in list.size():
		var uid: String = list[i]
		var c: CardView = cards.get(uid)
		if c == null:
			if not st.cards.has(uid):
				continue
			c = create(st, uid)
		var fi: Dictionary = f[i]
		c.shadow = 0.0
		if uid == drag_uid and drag_mode == "follow":
			var d := drag_rect()
			c.set_rect(d.position, HL().dragScale, false)
			c.z_index = 130
			c.smooth = false
		elif uid == drag_uid and drag_mode == "aim":
			# 화살표로 대상을 고르는 중(작은 오른손이 쥐러 오기 전): 확대하지 않고 제자리에서 살짝 떠 있기만 한다
			var qa: PackedVector2Array = fi.quad
			var lift := Vector2(0, -float(HL().get("aimLift", 60)))
			for k in 4:
				qa[k] += lift
			c.set_quad(qa, false)
			c.z_index = 125
			c.shadow = 1.0
			c.smooth = true
		elif (uid == hover_uid and drag_uid == "") or uid == lifted_uid:
			var r := hover_rect(uid)
			c.set_rect(r.position, FX.card_preview, false)
			c.z_index = 125 if uid == lifted_uid else 120
			c.shadow = 1.0
			c.smooth = true
		else:
			var q: PackedVector2Array = fi.quad
			if sink > 0 and Rules.is_face_down(st, uid):
				for k in 4:
					q[k] += Vector2(0, sink)
			c.set_quad(q, false)
			c.z_index = int(fi.z)
			c.smooth = true
	# 목록에 없는 카드 제거 (들어 올린 카드는 그대로)
	for uid in cards.keys():
		if uid == raised_uid:
			continue
		if not list.has(uid):
			cards[uid].queue_free()
			cards.erase(uid)
	if instant:
		pass


## 화면 좌표의 카드 (위에 있는 것부터)
func hit_test(p: Vector2) -> String:
	if hover_uid != "" and cards.has(hover_uid):
		if hover_rect(hover_uid).has_point(p):
			return hover_uid
	var vm: Dictionary = G.view.vm
	var uids := []
	for u in cards:
		if u != vm.get("ghost", ""):
			uids.append(u)
	uids.sort_custom(func(a, b): return cards[a].z_index > cards[b].z_index)
	for u in uids:
		if cards[u].contains(p):
			return u
	return ""


func set_hover(uid: String) -> void:
	if hover_uid == uid:
		return
	hover_uid = uid
	layout()


## 시험용: 손 그림의 잘린 자리(원본 좌표)가 카드나 뒷면 카드로 덮였는지 → 덮이지 않은 점(화면 좌표)
func uncovered(pts: Array) -> Array:
	var quads := []
	for u in cards:
		quads.append(cards[u].target)
	if bool(HL().backs):
		for i in backs.size():
			if backs[i].alpha > 0.5:
				quads.append(backs[i].target)
	var out := []
	for p in pts:
		var sp := to_screen(p)
		var hit := false
		for q in quads:
			if Geometry2D.is_point_in_polygon(sp, q):
				hit = true
				break
		if not hit:
			out.append([sp.x, sp.y])
	return out


## 지금 화면에 보이는 손의 수 (왼손 + 오른손 + 세운/쥔 오른손). 항상 2 이하여야 한다
func hands_visible() -> int:
	if not visible or not is_visible_in_tree():
		return 0
	var n := 1
	if right.modulate.a > 0.02 and right.position.y + 220.0 < 1080.0:
		n += 1
	if rig.visible and rig_alpha > 0.02:
		n += 1
	return n


func _process(delta: float) -> void:
	_tt += delta
	if tremble > 0:
		_apply_rig()
	if is_visible_in_tree():
		max_hands = maxi(max_hands, hands_visible())
