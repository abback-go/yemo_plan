## topdown.gd — 픽셀아트 탑뷰 이동 시험판 (?scene=topdown, 헤드리스 --scene=topdown). 기존 튜토리얼 흐름과 따로 노는 장면.
## 1층 갈림길 방을 위에서 내려다보며 노엘이 혼자 걷는다. PC: WASD·방향키, 휴대폰·마우스: 탭한 곳으로 걸어감(장애물을 피해 감).
## 물건 가까이에서 탭 / E·스페이스 → 대화창(G.dialog)에 노엘 속마음 + 대화창 옆 스탠딩. 출구 앞 → 갈림길 설명, 한 번 더 → 입구로 되돌림.
## 맵·노엘 모두 같은 정수 배율(zoom)로 확대해 Nearest 로 그린다(픽셀 밀도 통일). 앞벽은 노엘 위에 덮고, 기둥·돌무더기는 y 기준 정렬.
## 수치·다각형은 game_data.gd "topdown", 대사는 script_data.gd "topdown".
class_name TopdownScene
extends Control

const DIRS := ["down", "left", "right", "up"]   # 걷기 시트의 행 순서
const SEQ := [0, 1, 2, 1]                        # 왼발-서기-오른발-서기

var C: Dictionary
var T: Dictionary
var k := 3.0
var map_size := Vector2.ZERO
var nav: TopdownNav
var world: Node2D
var sorter: Node2D
var noel: Node2D
var noel_spr: Sprite2D
var marks: Node2D
var stand: TextureRect
var stand_who := ""
var desc: Control
var desc_title: Label
var desc_text: Label
var desc_hint: Label
var help_l: Label

var foot := Vector2.ZERO
var dir := "up"
var frame := 1
var moving := false
var walk_t := 0.0
var path := PackedVector2Array()
var pending := ""          # 도착하면 조사할 물건
var mode := "intro"        # intro | free | talk | leaving
var near := ""             # 조사할 수 있는 거리 안의 물건
var exit_sel := ""         # 지금 서 있는 출구 앞
var inspecting := ""
var inspected: Array = []
var exits_log: Array = []
var cam := Vector2.ZERO
var tap_mark := {}
var _t := 0.0


func setup() -> void:
	C = GameData.D.topdown
	T = G.S.topdown
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(1920, 1080)
	k = float(C.zoom)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var tex := Assets.tex(C.map)
	map_size = tex.get_size()
	nav = TopdownNav.new(C, Vector2i(map_size))
	world = Node2D.new()
	world.scale = Vector2(k, k)
	world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world)
	var map := Sprite2D.new()
	map.texture = tex
	map.centered = false
	world.add_child(map)
	# 노엘과 가리는 물건: 발끝(=노드 y) 기준으로 정렬
	sorter = Node2D.new()
	sorter.y_sort_enabled = true
	world.add_child(sorter)
	noel = Node2D.new()
	sorter.add_child(noel)
	var shadow := Node2D.new()
	shadow.draw.connect(func():
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(Vector2(cos(a) * 11.0, sin(a) * 3.5))
		shadow.draw_colored_polygon(pts, Color(0, 0, 0, 0.35)))
	noel.add_child(shadow)
	noel_spr = Sprite2D.new()
	noel_spr.texture = Assets.tex(C.sheet)
	noel_spr.centered = false
	noel_spr.hframes = int(C.cols)
	noel_spr.vframes = int(C.rows)
	noel_spr.offset = Vector2(-float(C.foot[0]), -float(C.foot[1]))
	noel.add_child(noel_spr)
	for o in C.occluders:
		sorter.add_child(_cut(tex, o.poly, float(o.base)))
	# 앞벽: 언제나 노엘 위
	var front := Node2D.new()
	front.z_index = 1
	world.add_child(front)
	for poly in C.front:
		front.add_child(_cut(tex, poly, 0.0))
	marks = Node2D.new()
	marks.z_index = 2
	world.add_child(marks)
	marks.draw.connect(_draw_marks)
	# 대화창 옆 스탠딩
	stand = TextureRect.new()
	stand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stand.stretch_mode = TextureRect.STRETCH_SCALE
	stand.modulate.a = 0.0
	stand.visible = false
	stand.z_index = 5   # 맵 안의 앞벽(z 1)·표시(z 2)보다 위
	add_child(stand)
	# 출구 설명 (화면 아래쪽 가운데)
	desc = Control.new()
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.visible = false
	desc.z_index = 5
	desc.draw.connect(func(): desc.draw_style_box(UI.box(Color(0.05, 0.03, 0.03, 0.92), UI.GOLD, 12, 2), Rect2(Vector2.ZERO, desc.size)))
	add_child(desc)
	desc_title = UI.label("", 34, Color("#f6e7c8"), "serif_bold")
	desc.add_child(desc_title)
	desc_text = UI.label("", 28, Color("#e8ddd2"), "sans")
	desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_child(desc_text)
	desc_hint = UI.label("", 22, Color("#ff9aa4"), "sans_bold", HORIZONTAL_ALIGNMENT_RIGHT)
	desc.add_child(desc_hint)
	help_l = UI.label(str(T.help), 22, Color(0.85, 0.8, 0.75, 0.75), "sans", HORIZONTAL_ALIGNMENT_RIGHT, 6)
	help_l.position = Vector2(960, 1080 - 46)
	help_l.size = Vector2(940, 34)
	help_l.z_index = 5
	add_child(help_l)
	foot = _v(C.start)
	cam = _cam_target()
	_apply()


func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


## 맵 그림의 한 부분(다각형)만 잘라 그리는 노드. base: y 정렬 기준(발끝 y)
func _cut(tex: Texture2D, pts: Array, base: float) -> Polygon2D:
	var pg := Polygon2D.new()
	pg.texture = tex
	var pp := TopdownNav.poly(pts)
	pg.uv = pp
	var sh := PackedVector2Array()
	for p in pp:
		sh.append(p - Vector2(0, base))
	pg.polygon = sh
	pg.position = Vector2(0, base)
	return pg


func _enter_tree() -> void:
	G.dialog.dock = "bottom"
	G.dialog.dock_x = float(GameData.D.topdown.dialogX)
	G.dialog.dock_w = 0.0
	G.dialog.relayout()


func _exit_tree() -> void:
	G.dialog.dock = ""
	G.dialog.dock_w = 0.0
	G.dialog.relayout()


# ───────── 진행 ─────────
## 아래 입구 아치에서 걸어 들어온다 → 세라피나의 첫 대사 → 자유 이동
func run() -> void:
	mode = "intro"
	dir = "up"
	var a := _v(C.start)
	var b := _v(C.entry)
	foot = a
	cam = _cam_target()
	await FX.fade(0, 500)
	moving = true
	var an := FX.anim(a.distance_to(b) / float(C.speed) * 1000.0, [{"y": a.y}, {"y": b.y}], func(v): foot.y = v.y, {"node": self})
	await FX.until(an)
	if not is_inside_tree():
		return
	moving = false
	await FX.wait(250)
	mode = "talk"
	await G.dialog.say(T.intro)
	if is_inside_tree() and mode == "talk":
		mode = "free"


func _process(dt: float) -> void:
	_t += dt
	if mode == "free":
		var kv := _key_dir()
		if kv != Vector2.ZERO:
			path = PackedVector2Array()
			pending = ""
			_step(kv.normalized() * float(C.speed) * dt * FX.speed)
		elif not path.is_empty():
			_follow(float(C.speed) * dt * FX.speed)
		else:
			moving = false
		_update_near()
	elif mode != "intro":
		moving = false
	if moving:
		walk_t += dt * float(C.fps) * FX.speed
		frame = SEQ[int(walk_t) % SEQ.size()]
	else:
		walk_t = 0.0
		frame = 1
	if not tap_mark.is_empty():
		tap_mark.t += dt
		if tap_mark.t > 0.6:
			tap_mark = {}
	var tc := _cam_target()
	cam = cam.lerp(tc, 1.0 - exp(-float(C.camLerp) * dt))
	_apply()
	_update_stand(dt)
	help_l.visible = not G.dialog.dlg.visible and not desc.visible
	marks.queue_redraw()


func _apply() -> void:
	noel.position = foot.round()
	noel_spr.frame = DIRS.find(dir) * int(C.cols) + frame
	# 카메라: 픽셀 한 칸 단위로 맞춰 움직인다(Nearest 확대가 흔들리지 않게)
	world.position = Vector2(960, 540) - cam.round() * k


func _cam_target() -> Vector2:
	var view := Vector2(1920, 1080) / k
	var t := foot - Vector2(0, 28)
	var out := Vector2.ZERO
	for i in 2:
		if map_size[i] <= view[i]:
			out[i] = map_size[i] / 2.0
		else:
			out[i] = clampf(t[i], view[i] / 2.0, map_size[i] - view[i] / 2.0)
	return out


func _key_dir() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1
	return v


func _face(d: Vector2) -> void:
	if absf(d.x) > absf(d.y) + 0.01:
		dir = "left" if d.x < 0 else "right"
	elif absf(d.y) > absf(d.x) + 0.01:
		dir = "up" if d.y < 0 else "down"
	elif d != Vector2.ZERO:
		# 대각선: 지금 보는 쪽이 그 대각선의 한쪽이면 그대로
		var ok := (dir == "left" and d.x < 0) or (dir == "right" and d.x > 0) or (dir == "up" and d.y < 0) or (dir == "down" and d.y > 0)
		if not ok:
			dir = "left" if d.x < 0 else "right"


func _step(d: Vector2) -> void:
	_face(d)
	var n := nav.move(foot, d)
	moving = n.distance_squared_to(foot) > 0.0001
	foot = n


func _follow(dist: float) -> void:
	var target: Vector2 = path[0]
	var v := target - foot
	_face(v)
	if v.length() <= dist:
		foot = target
		path.remove_at(0)
		moving = true
		if path.is_empty():
			_arrived()
		return
	var n := nav.move(foot, v.normalized() * dist)
	if n.distance_squared_to(foot) < 0.0001:
		path = PackedVector2Array()
		_arrived()
		return
	foot = n
	moving = true


func _arrived() -> void:
	moving = false
	var id := pending
	pending = ""
	_update_near()
	if id != "" and in_range(id):
		investigate(id)


func item(id: String) -> Dictionary:
	for it in C.items:
		if it.id == id:
			return it
	return {}


func exit_conf(id: String) -> Dictionary:
	for e in C.exits:
		if e.id == id:
			return e
	return {}


func in_range(id: String) -> bool:
	var it := item(id)
	return not it.is_empty() and foot.distance_to(_v(it.spot)) <= float(it.r)


func _update_near() -> void:
	near = ""
	var bd := INF
	for it in C.items:
		var d := foot.distance_to(_v(it.spot))
		if d <= float(it.r) and d < bd:
			bd = d
			near = it.id
	var ex := ""
	for e in C.exits:
		if foot.distance_to(_v(e.at)) <= float(e.r):
			ex = e.id
	if ex != exit_sel:
		exit_sel = ex
		_show_exit(ex)


# ───────── 출구 (설명은 화면 아래쪽 가운데) ─────────
func _show_exit(id: String) -> void:
	if id == "":
		desc.visible = false
		return
	var txt: Dictionary = G.S.explore.fork.paths.get(id, {})
	_desc(str(txt.get("title", id)), str(txt.get("desc", "")), str(T.exitHint))
	G.ctl.note("td exit " + id)


func _desc(title: String, text: String, hint: String) -> void:
	desc_title.text = title
	desc_text.text = text
	desc_hint.text = hint
	var u := minf(FX.ui, 1.5)
	var w := 760.0
	desc.scale = Vector2(u, u)
	desc_title.position = Vector2(26, 18)
	desc_text.position = Vector2(26, 70)
	desc_text.size = Vector2(w - 52, 0)
	desc_text.custom_minimum_size = Vector2(w - 52, 0)
	var th := desc_text.get_combined_minimum_size().y
	desc.size = Vector2(w, 70 + th + (56 if hint != "" else 24))
	desc_hint.position = Vector2(26, desc.size.y - 40)
	desc_hint.size = Vector2(w - 52, 30)
	# 출구는 모두 맵 위쪽이라 노엘·출구를 가리지 않게 화면 아래쪽 가운데에 띄운다
	desc.position = Vector2(960 - w * u / 2.0, 1080 - 30 - desc.size.y * u)
	desc.visible = true
	desc.queue_redraw()


## 출구로 들어간다 → "시험판은 여기까지" → 입구 자리로 되돌림
func leave(id: String) -> void:
	if mode != "free":
		return
	mode = "leaving"
	path = PackedVector2Array()
	pending = ""
	moving = false
	exits_log.append(id)
	G.ctl.note("td leave " + id)
	var txt: Dictionary = G.S.explore.fork.paths.get(id, {})
	_desc(str(txt.get("title", id)), str(T.trialEnd), "")
	await FX.wait(1400)
	if not is_inside_tree():
		return
	await FX.fade(1, 450)
	if not is_inside_tree():
		return
	desc.visible = false
	exit_sel = ""
	foot = _v(C.entry)
	dir = "up"
	cam = _cam_target()
	_apply()
	await FX.fade(0, 450)
	if is_inside_tree():
		mode = "free"


# ───────── 조사 ─────────
func investigate(id: String) -> void:
	if mode != "free":
		return
	mode = "talk"
	inspecting = id
	path = PackedVector2Array()
	pending = ""
	moving = false
	_face(_v(item(id).at) - foot)
	if not inspected.has(id):
		inspected.append(id)
	G.ctl.note("td inspect " + id)
	await G.dialog.say(T.items.get(id, []))
	if not is_inside_tree():
		return
	inspecting = ""
	if mode == "talk":
		mode = "free"


# ───────── 입력 ─────────
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		accept_event()
		tap(get_local_mouse_position())


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		confirm()


## E·스페이스: 대사 넘기기 → 출구 앞이면 들어가기 → 가까운 물건 조사
func confirm() -> void:
	if G.dialog.is_busy():
		G.dialog.advance()
		return
	if mode != "free":
		return
	if exit_sel != "":
		leave(exit_sel)
	elif near != "":
		investigate(near)


func to_map(p: Vector2) -> Vector2:
	return (p - world.position) / k


func to_stage(p: Vector2) -> Vector2:
	return world.position + p * k


func _hit(list: Array, mp: Vector2) -> String:
	var m := 6.0 if FX.touch else 2.0
	for o in list:
		var h: Array = o.hit
		if Rect2(float(h[0]), float(h[1]), float(h[2]), float(h[3])).grow(m).has_point(mp):
			return str(o.id)
	return ""


## 탭(무대 좌표): 대사 넘기기 / 물건 → 가까우면 조사, 멀면 걸어가서 조사 / 출구 → 걸어감, 출구 앞에서 한 번 더 → 들어감 / 그 밖 → 그곳으로 걸어감
func tap(p: Vector2) -> void:
	if G.dialog.is_busy() or G.dialog.guide_open():
		G.dialog.advance()
		return
	if mode != "free":
		return
	if desc.visible and exit_sel != "" and Rect2(desc.position, desc.size * desc.scale).has_point(p):
		leave(exit_sel)
		return
	var mp := to_map(p)
	var it := _hit(C.items, mp)
	if it != "":
		if in_range(it):
			investigate(it)
		else:
			go(_v(item(it).spot), it)
		return
	var ex := _hit(C.exits, mp)
	if ex != "":
		if ex == exit_sel:
			leave(ex)
		else:
			go(_v(exit_conf(ex).at))
		return
	go(mp)


func go(p: Vector2, then := "") -> void:
	path = nav.find_path(foot, p)
	pending = then
	tap_mark = {"p": path[path.size() - 1] if not path.is_empty() else p, "t": 0.0}
	G.ctl.note("td go %s → %d점" % [str(p.round()), path.size()])
	if path.is_empty():
		_arrived()


# ───────── 표시 ─────────
## 물건마다 옅은 반짝임, 조사할 수 있는 거리면 ! 말풍선, 탭한 곳 표시 (맵 픽셀 단위로 그려 도트와 맞춘다)
func _draw_marks() -> void:
	var ci := marks
	for it in C.items:
		var at := _v(it.at)
		var ph := _t * 2.2 + at.x * 0.05
		var a := 0.25 + 0.35 * (0.5 + 0.5 * sin(ph))
		if inspected.has(it.id):
			a *= 0.5
		var c := Color(1.0, 0.9, 0.6, a)
		var s := 1.0 + (1.0 if sin(ph) > 0.6 else 0.0)
		ci.draw_rect(Rect2(at + Vector2(-s, -1 - s * 2), Vector2(s * 2, 2 + s * 4)), c)
		ci.draw_rect(Rect2(at + Vector2(-1 - s * 2, -s), Vector2(2 + s * 4, s * 2)), c)
		if it.id == near and mode == "free":
			var b := at + Vector2(0, -26 + (1 if fmod(_t, 0.8) < 0.4 else 0))
			ci.draw_rect(Rect2(b + Vector2(-5, -8), Vector2(11, 15)), Color("#1a0a0e"))
			ci.draw_rect(Rect2(b + Vector2(-4, -7), Vector2(9, 13)), Color("#f6e7c8"))
			ci.draw_rect(Rect2(b + Vector2(-1, 6), Vector2(3, 3)), Color("#f6e7c8"))
			ci.draw_rect(Rect2(b + Vector2(-1, -5), Vector2(3, 6)), UI.RED)
			ci.draw_rect(Rect2(b + Vector2(-1, 2), Vector2(3, 2)), UI.RED)
	if exit_sel == "" and mode == "free":
		for e in C.exits:
			var at := _v(e.at)
			if foot.distance_to(at) < 90:
				var a2 := 0.3 + 0.3 * sin(_t * 3.0)
				ci.draw_rect(Rect2(at + Vector2(-1, -14), Vector2(3, 8)), Color(1, 0.85, 0.5, a2))
				ci.draw_rect(Rect2(at + Vector2(-4, -17), Vector2(9, 3)), Color(1, 0.85, 0.5, a2))
	if not tap_mark.is_empty():
		var tp: Vector2 = tap_mark.p.round()
		var r: float = 3.0 + float(tap_mark.t) * 10.0
		var a3: float = 1.0 - float(tap_mark.t) / 0.6
		ci.draw_rect(Rect2(tp + Vector2(-r, -r * 0.5), Vector2(r * 2, 1)), Color(1, 0.8, 0.5, a3))
		ci.draw_rect(Rect2(tp + Vector2(-r, r * 0.5), Vector2(r * 2, 1)), Color(1, 0.8, 0.5, a3))
		ci.draw_rect(Rect2(tp + Vector2(-r, -r * 0.5), Vector2(1, r)), Color(1, 0.8, 0.5, a3))
		ci.draw_rect(Rect2(tp + Vector2(r - 1, -r * 0.5), Vector2(1, r)), Color(1, 0.8, 0.5, a3))


## 대사 중이면 말하는 인물의 스탠딩을 대화창 옆에 띄운다 (노엘 속마음 = 노엘)
func _update_stand(dt: float) -> void:
	var who := ""
	if G.dialog.cur != null and not G.dialog.cur.guide:
		who = str(G.dialog.cur.line.get("who", ""))
	var files: Dictionary = C.stand.files
	var file: String = files.get(who, "")
	if file != "" and who != stand_who:
		stand_who = who
		var sz := Assets.size(file)
		var h := float(C.stand.h)
		var w := h * sz.x / maxf(1.0, sz.y)
		stand.texture = Assets.tex(file)
		stand.size = Vector2(w, h)
		# 노엘이 화면 왼쪽에 있으면 스탠딩을 오른쪽에, 대화창을 왼쪽에 (노엘·물건을 가리지 않게)
		var right := to_stage(foot).x < 960.0
		var sx := float(C.stand.x)
		stand.position = Vector2((1920.0 - sx if right else sx) - w / 2.0, float(C.stand.top))
		G.dialog.dock_x = 30.0 if right else float(C.dialogX)
		G.dialog.dock_w = 1920.0 - float(C.dialogX) - 30.0
		G.dialog.relayout()
		stand.modulate.a = 0.0
	var on := file != ""
	if on:
		stand.visible = true
	stand.modulate.a = move_toward(stand.modulate.a, 1.0 if on else 0.0, dt * 5.0)
	if not on and stand.modulate.a <= 0.0:
		stand.visible = false
		stand_who = ""


## 시험용 상태
func test_state() -> Dictionary:
	return {"pos": [snappedf(foot.x, 0.1), snappedf(foot.y, 0.1)], "dir": dir, "frame": frame, "sheetFrame": noel_spr.frame, "moving": moving,
		"mode": mode, "near": near, "exit": exit_sel, "inspecting": inspecting, "inspected": inspected, "exits": exits_log,
		"canStand": nav.can_stand(foot), "path": path.size(), "cam": [cam.x, cam.y], "zoom": k, "map": [map_size.x, map_size.y],
		"stand": stand_who if stand.visible else "", "desc": desc_text.text if desc.visible else "",
		"world": [world.position.x, world.position.y]}
