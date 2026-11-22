## board_hand.gd — 전투 시험판 v2.1 「3D 탁자」의 노엘의 손과 손패 (scenes/board_battle.gd, docs/battle-v2-spec.md 9-4 사용자 결정).
##  · 왼손: 화면 왼쪽 아래에 편 왼손(그림은 손패 뒤). 그 위로 손패가 부채꼴로 살짝 떠서 천천히 흔들린다. 손가락과 카드 사이에 붉은 실 몇 가닥(코드).
##  · 오른손: 평소 오른쪽 아래에 놓여 있다(idle). 카드를 끌면 집어 들고 따라간다(pinch). 대상을 고를 때 그 자리를 가리킨다(point).
##  · v2.3 손패 당겨 보기(9-5 바꿈): open 이면 왼손·오른손 대신 양손 그림(both_l·both_r)이 가운데 아래로 올라오고 손패 전체가 크게(카드 높이 open.cardH) 펼쳐진다.
##    탁자는 검은 반투명(dim)으로 가라앉힌다. 열고 닫기는 board(scenes/board_battle.gd)가 set_open 으로.
##  · 손 그림은 data layout.hands 의 후보 가운데 파일이 있는 것(그림체 F 78·79·80 → 없으면 지금 손 그림 ui_witch_hand_*). 위치·실 끝은 그림마다 데이터.
## 카드 앞면은 CardView(원근 사각형 그리기)를 그대로 쓰고, 앞면 그림만 BoardPieces.draw_face(kind mine) — 탁자 카드와 같은 앞면.
## 지금 게임의 hand.gd·card_view.gd 는 건드리지 않는다(?battle=v2 가 아니면 쓰이지 않음).
class_name BoardHand
extends Node2D

var board = null          # BoardBattle (손패 목록·덱 자리)
var cards := {}           # uid → Card
var hover_uid := ""
var lifted_uid := ""
var drag_uid := ""
var drag_mode := ""       # "" | "follow"
var drag_pos := Vector2(960, 600)
var point_at = null       # 대상을 고르는 중: 오른손이 가리키는 화면 점(Vector2) · null
var max_hands := 0        # 시험용: 한 번에 보인 손의 최대 수
var open := false         # v2.3 손패 당겨 보기
var drag_k := 0.0         # 끄는 카드 배율 (0 = dragScale — 펼친 손패에서 끌면 펼친 크기 그대로)
var _open_k := 0.0        # 0 = 평소 · 1 = 펼침 (부드럽게)
var both_l: Sprite2D
var both_r: Sprite2D
var dim: Node2D
var left: Sprite2D
var right: Sprite2D
var pinch: Sprite2D
var threads: Node2D
var _L := {}
var _R := {}
var _P := {}
var _t := 0.0
var _rpos := Vector2.ZERO     # 오른손 손끝(화면) — 부드럽게 따라간다
var _pinch_a := 0.0


func HL() -> Dictionary:
	return BattleV2Data.D.layout.hands


static func _pick(list: Array) -> Dictionary:
	for e in list:
		if Assets.ok(str(e.file)):
			return e
	return {}


func _ready() -> void:
	var h := HL()
	_L = _pick(h.left)
	_R = _pick(h.right)
	_P = _pick(h.pinch)
	left = _sprite(_L, 30)
	if not _L.is_empty():
		left.position = Vector2(_L.pos[0], _L.pos[1])
	threads = Node2D.new()
	threads.z_index = 35
	threads.draw.connect(_draw_threads)
	add_child(threads)
	right = _sprite(_R, 150)
	pinch = _sprite(_P, 160)
	pinch.visible = false
	_rpos = _rest()
	# v2.3 양손(펼친 손패 뒤) · 탁자 어둡게(그 뒤)
	dim = Node2D.new()
	dim.z_index = 40
	dim.draw.connect(func(): dim.draw_rect(Rect2(-200, -200, 2320, 1480), Color(0, 0, 0, float(OL().dim) * _open_k)))
	add_child(dim)
	var O := OL()
	both_l = _sprite({"file": O.files[0], "scale": O.scale}, 45)
	both_r = _sprite({"file": O.files[1], "scale": O.scale}, 45)
	both_l.visible = false
	both_r.visible = false


func OL() -> Dictionary:
	return HL().open


func _sprite(e: Dictionary, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.z_index = z
	if not e.is_empty() and Assets.ok(str(e.file)):
		s.texture = Assets.tex(str(e.file))
		s.scale = Vector2.ONE * float(e.scale)
		if bool(e.get("flip", false)):
			s.flip_h = true
	else:
		s.visible = false
	add_child(s)
	return s


func _rest() -> Vector2:
	return Vector2(_R.rest[0], _R.rest[1]) if not _R.is_empty() else Vector2(1600, 1000)


# ───────── 손패 부채꼴 (왼손 위에 떠 있다) ─────────
func card_scale() -> float:
	return float(HL().fan.scale)


## n장일 때 각 카드의 {c: 가운데, a: 기울기, z}
func fan(n: int) -> Array:
	var F: Dictionary = HL().fan
	var res := []
	if n <= 0:
		return res
	var step := float(F.step)
	if (n - 1) * step > float(F.maxSpread):
		step = float(F.maxSpread) / (n - 1)
	var p := Vector2(F.pivot[0], F.pivot[1])
	for i in n:
		var a := float(F.center) + (i - (n - 1) / 2.0) * step
		var sway := sin(_t * 1.1 + i * 1.7) * float(F.sway)
		var c := p + Vector2(sin(a), -cos(a)) * float(F.r) + Vector2(0, sway)
		res.append({"c": c, "a": a + sin(_t * 0.8 + i) * 0.012, "z": 50 + i})
	return res


## v2.3 펼친 손패: n장일 때 각 카드의 {c, a, z} — 가운데 아래 양손 위로 크게
func open_fan(n: int) -> Array:
	var O := OL()
	var k := open_scale()
	var w := CardView.W * k
	var step := float(O.step)
	if n > 1 and (n - 1) * step + w > float(O.maxW):
		step = (float(O.maxW) - w) / (n - 1)
	var res := []
	for i in n:
		var t := i - (n - 1) / 2.0
		var c := Vector2(960.0 + t * step, float(O.cy) + t * t * float(O.drop))
		res.append({"c": c, "a": t * float(O.rot), "z": 60 + i})
	return res


func open_scale() -> float:
	return float(OL().cardH) / CardView.H


## 펼친 손패가 차지하는 곳(카드 + 양손) — PC 에서 마우스가 이 밖으로 나가면 닫는다
func open_area() -> Rect2:
	var n: int = board.hand_list().size() if board != null else 0
	var r := Rect2(Vector2(both_l.position.x, float(OL().y) + 300), Vector2(1672 * float(OL().scale), 1080))
	for f in open_fan(n):
		var q := quad(f.c, f.a, open_scale())
		for v in q:
			r = r.expand(v)
	return r.grow(24)


func set_open(on: bool) -> void:
	if open == on:
		return
	open = on
	hover_uid = ""
	layout()


static func quad(c: Vector2, a: float, k: float) -> PackedVector2Array:
	var hw := CardView.W * k / 2.0
	var hh := CardView.H * k / 2.0
	var out := PackedVector2Array()
	for v in [Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)]:
		out.append(c + v.rotated(a))
	return out


func drag_k_now() -> float:
	return drag_k if drag_k > 0.0 else float(HL().dragScale)


## 끄는 카드: 커서가 카드 아래쪽에 오게(크게 끌 때 놓을 칸이 카드에 가리지 않게)
func drag_rect() -> Rect2:
	var k := drag_k_now()
	var sz := Vector2(CardView.W, CardView.H) * k
	var up := sz.y * 0.34 if drag_k > 0.0 else 0.0
	return Rect2(drag_pos - sz / 2.0 - Vector2(0, up), sz)


func create(st: Dictionary, uid: String, from = null) -> CardView:
	if cards.has(uid) and is_instance_valid(cards[uid]):
		cards[uid].queue_free()
	var c := Card.new()
	add_child(c)
	c.setup_face(st, uid)
	c.z_index = 50
	var p: Vector2 = from if from is Vector2 else (board.deck_center() if board != null else Vector2(460, 960))
	c.set_rect(p - Vector2(CardView.W, CardView.H) * 0.15, 0.3, true)
	c.alpha = 0.0
	FX.anim(250, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(c): c.alpha = v.a, {"node": c})
	cards[uid] = c
	return c


## 손패에서 떼어낸다 (날아가는 연출용). 반환된 카드는 부른 쪽이 지운다
func detach(uid: String) -> CardView:
	var c: CardView = cards.get(uid)
	cards.erase(uid)
	if hover_uid == uid:
		hover_uid = ""
	if drag_uid == uid:
		drag_uid = ""
		drag_mode = ""
	if lifted_uid == uid:
		lifted_uid = ""
	return c


## 낼 수 있는 카드에 금빛 테두리
func update_classes(st: Dictionary, busy: bool) -> void:
	for uid in cards:
		cards[uid].glow = 1.0 if (not busy and RulesV2.affordable(st, uid)) else 0.0


func layout(_instant := false) -> void:
	if board == null or board.st.is_empty():
		return
	var st: Dictionary = board.st
	var list: Array = board.hand_list()
	var f := open_fan(list.size()) if open else fan(list.size())
	var k := open_scale() if open else card_scale()
	for i in list.size():
		var uid: String = list[i]
		var c: CardView = cards.get(uid)
		if c == null:
			c = create(st, uid)
		c.shadow = 0.0
		if uid == drag_uid and drag_mode == "follow":
			var d := drag_rect()
			c.set_rect(d.position, drag_k_now(), false)
			c.z_index = 130
			c.smooth = false
		elif open:
			var up := float(OL().lift) if (uid == hover_uid or uid == lifted_uid) else 0.0
			c.set_quad(quad(f[i].c + Vector2(0, -up), f[i].a, k), false)
			c.z_index = 120 if up > 0.0 else int(f[i].z)
			c.shadow = 1.0 if up > 0.0 else 0.0
			c.smooth = true
		else:
			c.set_quad(quad(f[i].c, f[i].a, k), false)
			c.z_index = int(f[i].z)
			c.smooth = true
	for uid in cards.keys():
		if not list.has(uid):
			cards[uid].queue_free()
			cards.erase(uid)


## 화면 좌표의 카드 (위에 있는 것부터)
func hit_test(p: Vector2) -> String:
	var uids: Array = cards.keys()
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


## 지금 화면에 보이는 손의 수 (왼손 + 오른손 하나). 항상 2 이하여야 한다
func hands_visible() -> int:
	if not is_visible_in_tree():
		return 0
	if _open_k > 0.5:
		return 2   # 펼침: 양손 그림 둘 (왼손·오른손은 숨김)
	var n := 1 if left.visible else 0
	if right.visible and right.modulate.a > 0.02:
		n += 1
	if pinch.visible and pinch.modulate.a > 0.02:
		n += 1
	return n


# ───────── 붉은 실 (왼손가락 → 카드 아래 가장자리) ─────────
func _draw_threads() -> void:
	if _L.is_empty() or _open_k > 0.01:
		return
	var tips: Array = _L.get("tips", [])
	var list: Array = []
	for u in cards:
		if u != drag_uid and u != hover_uid and u != lifted_uid:
			list.append(cards[u])
	if list.is_empty() or tips.is_empty():
		return
	list.sort_custom(func(a, b): return a.center().x < b.center().x)
	var sc := float(_L.scale)
	for i in tips.size():
		var tip: Vector2 = left.position + Vector2(tips[i][0], tips[i][1]) * sc
		var c: CardView = list[mini(list.size() - 1, int(round(float(i) * (list.size() - 1) / maxf(1.0, tips.size() - 1))))]
		var q := c.corners
		var end := (q[2] + q[3]) / 2.0 + (q[0] - q[3]) * 0.08
		var mid := (tip + end) / 2.0 + Vector2(sin(_t * 1.3 + i) * 10.0, 26.0)
		var pts := UI.quad_curve(tip, mid, end, 18)
		threads.draw_polyline(pts, Color(0.35, 0.0, 0.03, 0.5), 3.2, true)
		threads.draw_polyline(pts, Color(0.72, 0.06, 0.1, 0.85), 1.6, true)


func _process(delta: float) -> void:
	_t += delta * minf(FX.speed, 3.0)
	if board != null and not board.st.is_empty() and drag_uid == "":
		layout()
	threads.queue_redraw()
	# 오른손: 평소 자리 · 끄는 카드를 집음 · 가리킴
	var want := _rest()
	var pinching := drag_uid != "" and drag_mode == "follow" and not _P.is_empty()
	if point_at is Vector2:
		want = point_at
	var k := 1.0 - exp(-delta * FX.speed / 0.09)
	_rpos = _rpos.lerp(want, k)
	if not _R.is_empty():
		var tip := Vector2(_R.tip[0], _R.tip[1]) * float(_R.scale)
		right.position = _rpos - tip
	_pinch_a = move_toward(_pinch_a, 1.0 if pinching else 0.0, delta * FX.speed * 6.0)
	# v2.3 손패 당겨 보기: 양손이 아래에서 올라오고 왼손·오른손은 사라진다
	var ok := _open_k
	_open_k = move_toward(_open_k, 1.0 if open else 0.0, delta * FX.speed * 4.5)
	if ok != _open_k:
		dim.queue_redraw()
	var ek := ease(_open_k, -2.0)
	for i in 2:
		var sp: Sprite2D = [both_l, both_r][i]
		sp.visible = sp.texture != null and _open_k > 0.01
		sp.modulate.a = ek
		sp.position = Vector2(float(OL().x) + i * float(OL().split) * float(OL().scale), float(OL().y) + (1.0 - ek) * 420.0)
	left.modulate.a = 1.0 - ek
	left.visible = left.texture != null and ek < 0.99
	right.modulate.a = (1.0 - _pinch_a) * (1.0 - ek)
	right.visible = right.texture != null and right.modulate.a > 0.01
	pinch.visible = pinch.texture != null and _pinch_a > 0.01
	pinch.modulate.a = _pinch_a
	if pinch.visible and cards.has(drag_uid):
		# 세운 손 그림의 카드 자리(quad 왼위)가 끄는 카드의 왼위에 오게
		var q: Array = _P.quad
		var c: CardView = cards[drag_uid]
		var sc := float(_P.scale) * drag_k_now() / float(_P.get("cardScale", HL().dragScale))
		pinch.scale = Vector2.ONE * sc
		pinch.position = c.corners[0] - Vector2(q[0][0], q[0][1]) * sc
	if is_visible_in_tree():
		max_hands = maxi(max_hands, hands_visible())


## v2.1 카드 앞면: BoardPieces.draw_face(kind mine) — 탁자의 카드와 같은 앞면
class Card extends CardView:
	func build(st: Dictionary) -> void:
		for c in face.get_children():
			c.queue_free()
		card_id = st.cards[uid].id
		var d: Dictionary = BattleV2Data.D.cards[card_id]
		var f := {"kind": "mine", "name": str(d.name), "cost": int(d.cost), "owner": str(d.owner), "art": str(d.art), "dark": bool(d.get("dark", false)),
			"text": str(d.text).replace("{n}", str(int(d.get("damage", d.get("block", 0)))))}
		var dc := Control.new()
		dc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dc.size = face.size
		dc.draw.connect(func(): BoardPieces.draw_face(dc, Rect2(Vector2.ZERO, dc.size), f))
		face.add_child(dc)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE

	## 상태 표시는 글로(금빛 테두리)만 — 앞면은 그대로
	func refresh(_st: Dictionary) -> void:
		pass
