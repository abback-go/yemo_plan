## card_pick.gd — 카드 고르기 화면: 카드 몇 장을 나란히 보여 주고 하나를 고른다(넘기기 버튼은 선택).
## 전투 보상(3장 중 1장 — 대본 v3 1장)·강적 희귀 보상·묘지기의 좌판(거래)·훈련(강화할 카드)에서 같이 쓴다.
## (예전 vn.gd 의 TrainPicker 를 넓힌 것 — 훈련도 이것을 쓴다)
class_name CardPick
extends Control

var hits: Array = []
var skip_btn: Btn = null
var _picked := [-2]
var _w: DialogBox.Waiter


## items: [{id, up?, summary?}] · title·hint: 위쪽 문구 · skip: 넘기기 버튼 글("" = 없음)
## auto: 자동 진행(헤드리스)에서 고를 것 — 카드 id | "skip" | "" (= 첫 장). 반환: 고른 번호(-1 = 넘김)
func run(items: Array, title: String, hint := "", skip := "", auto := "") -> int:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(1920, 1080)
	var st: Dictionary = G.ctl.st
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var t := UI.label(title, 44, Color("#f6e7c8"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 6)
	t.position = Vector2(0, 150)
	t.size = Vector2(1920, 60)
	add_child(t)
	if hint != "":
		var h := UI.label(hint, 26, Color("#c9b9bc"), "sans", HORIZONTAL_ALIGNMENT_CENTER)
		h.position = Vector2(0, 215)
		h.size = Vector2(1920, 40)
		add_child(h)
	var k := 1.25
	var gap := 80.0
	var total := items.size() * CardView.W * k + maxi(0, items.size() - 1) * gap
	var x0 := 960 - total / 2.0
	_w = DialogBox.Waiter.new()
	for i in items.size():
		var it: Dictionary = items[i]
		var id: String = str(it.id)
		var tmp := "tmp_pick_%d" % i
		st.cards[tmp] = {"uid": tmp, "id": id}
		if it.get("up", false):
			st.cards[tmp].up = true
		var holder := Node2D.new()
		add_child(holder)
		var cv := CardView.new()
		holder.add_child(cv)
		cv.setup_face(st, tmp)
		var pos := Vector2(x0 + i * (CardView.W * k + gap), 300)
		cv.set_rect(pos, k, true)
		cv.glow = 1.0
		st.cards.erase(tmp)
		var summary := str(it.get("summary", ""))
		if summary != "":
			var sl := UI.label(summary, 28, Color("#ffcf6a"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
			sl.position = Vector2(pos.x - 40, pos.y + CardView.H * k + 20)
			sl.size = Vector2(CardView.W * k + 80, 40)
			add_child(sl)
		var hit := Btn.new()
		hit.setup("", 10)
		hit.position = pos
		hit.size = Vector2(CardView.W, CardView.H) * k + Vector2(0, 70 if summary != "" else 0)
		hit.self_modulate.a = 0.0
		hit.set_meta("value", id)
		hit.name = "pick_%d" % i
		var idx := i
		hit.pressed.connect(func():
			_picked[0] = idx
			_w.finish())
		add_child(hit)
		hits.append(hit)
	if skip != "":
		skip_btn = UI.button(skip, 30, func():
			_picked[0] = -1
			_w.finish(), "serif_bold")
		skip_btn.style_kind = "small"
		skip_btn.fit(Vector2(48, 14))
		skip_btn.position = Vector2(960 - skip_btn.size.x / 2.0, 300 + CardView.H * k + 110)
		skip_btn.name = "skip"
		add_child(skip_btn)
	modulate.a = 0.0
	FX.anim(300, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(self): modulate.a = v.a, {"node": self})
	G.ctl.note("pick " + ",".join(items.map(func(x): return str(x.id))))
	if G.autoguide:
		get_tree().create_timer(0.3).timeout.connect(func():
			if _w.finished:
				return
			var want := auto
			_picked[0] = 0 if not items.is_empty() else -1
			if want == "skip" and skip != "":
				_picked[0] = -1
			else:
				for i in items.size():
					if str(items[i].id) == want:
						_picked[0] = i
			_w.finish())
	if not _w.finished:
		await _w.done
	G.ctl.note("picked " + str(_picked[0]))
	return int(_picked[0])


## 시험: 카드 id 로 고른다 ("skip" = 넘기기)
func pick(id: String) -> bool:
	if id == "skip" and skip_btn != null:
		skip_btn.pressed.emit()
		return true
	for h in hits:
		if str(h.get_meta("value")) == id:
			h.pressed.emit()
			return true
	return false
