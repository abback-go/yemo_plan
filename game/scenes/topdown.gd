## topdown.gd — 픽셀아트 탑뷰 탐사 (1차 시험판 v2). 맵 하나를 위에서 내려다보며 노엘이 4방향으로 걷고, 동료가 노엘이 지나간 경로를 따라 줄지어 걷는다.
## 맵마다 걸을 수 있는 다각형·가림·출구·트리거·인물은 data/maps_data.gd (갈림길 맵 "fork" 는 game_data.gd "topdown"). 대사는 script_data.gd maps.
## PC: WASD·방향키, 마우스: 클릭한 곳으로 걸어감. 터치: 왼쪽 절반 조이스틱(아날로그), 오른쪽 아래 조사 버튼.
## 물건 → 조사(대화창 + 옆 스탠딩). 출구 앞 → 설명, 한 번 더 → 사건(event). 트리거 안에 들어서면 → 사건(event).
## 흐름(ctl.gd)은 run() 으로 걸어 들어오게 한 뒤 next_event() 를 기다려 전투·운명의 시도·다음 맵으로 잇는다.
## ?scene=topdown(시험판)은 trial 모드: 출구에서 "시험판은 여기까지" → 입구로 되돌린다.
## 맵·사람 모두 같은 정수 배율(zoom)로 확대해 Nearest 로 그린다(픽셀 밀도 통일). 앞벽은 사람 위에, 기둥·물건은 발끝 y 기준 정렬.
class_name TopdownScene
extends Control

signal fired(ev)

const DIRS := ["down", "left", "right", "up"]   # 걷기 시트의 행 순서
const SEQ := [0, 1, 2, 1]                        # 왼발-서기-오른발-서기
## 따라 걷는 동료 id → 걷기 그림·동료 id(규칙)
const FOLLOW := {
	"seraphina": {"sheet": "td_seraphina_walk.png", "ally": "hero"},
	"brunhild": {"sheet": "td_brunhild_walk.png", "ally": "warrior"},
	"elian": {"sheet": "td_elian_walk.png", "ally": "archer"},
}

var map_id := "fork"
var opts := {}
var C: Dictionary
var T: Dictionary          # 이 맵의 대사·문구 (script_data.gd maps.<맵>, 갈림길 시험판은 topdown)
var k := 3.0
var map_size := Vector2.ZERO
var map_tex: Texture2D
var nav: TopdownNav
var world: Node2D
var sorter: Node2D
var noel: Node2D
var noel_spr: Sprite2D
var followers: Array = []  # [{"id", "node", "spr", "pos", "dir", "frame", "walk_t", "moving", "free"}] — 노엘 뒤 순서대로
var npcs := {}             # id → {"node", "spr", "conf", "pos", "dir", "frame", "walk_t", "moving"}
var trail := TopdownNav.Trail.new()
var pad: Control           # 터치 조이스틱·조사 버튼 (무대 좌표로 그림)
var marks: Node2D
var fxl: Node2D            # 운명 연출(붉은 실·함정) — 맵 좌표
var tint: ColorRect        # 시간 정지(붉게)
var lights: Array = []     # [{"spr", "conf", "ph"}]
var grates: Array = []
var stand: TextureRect
var stand_who := ""
var desc: Control
var desc_title: Label
var desc_text: Label
var desc_hint: Label
var help_l: Label
var hud: FateHud
var vn: VnScene = null     # 탑뷰 위에 띄운 대화 장면(캠프)

var foot := Vector2.ZERO
var dir := "up"
var frame := 1
var moving := false
var walk_t := 0.0
var held: Array = []       # 누르고 있는 방향키 (누른 순서). 마지막 것 하나로만 걷는다
var pace := 1.0            # 지금 걷는 빠르기 비율 (조이스틱을 덜 기울이면 1보다 작다)
var stick := {}            # 조이스틱을 누른 손가락 {"i", "c", "p", "drag"} (무대 좌표)
var btn_flash := 0.0
var touch_ui := false
var path := PackedVector2Array()
var pending := ""          # 도착하면 조사할 물건
var mode := "intro"        # intro | free | talk | event | leaving
var near := ""
var exit_sel := ""
var inspecting := ""
var inspected: Array = []
var exits_log: Array = []
var armed: Array = []      # 켜져 있는 트리거 id
var locked_exits: Array = []
var trial := false
var cam := Vector2.ZERO
var cam_hold = null        # 연출 중 카메라를 붙잡아 둘 맵 좌표
var tap_mark := {}
var trap := {}             # 운명의 시도 함정 {"spr", "pos", "frame", "who"}
var fate_thread := {}      # {"who": 동료 id, "t": 팽팽함}
var _t := 0.0


func setup(id := "fork", o := {}) -> void:
	map_id = id
	opts = o
	trial = bool(o.get("trial", false))
	C = GameData.D.topdown.duplicate()
	if map_id != "fork":
		var m: Dictionary = MapsData.M[map_id]
		for key in m:
			C[key] = m[key]
		T = G.S.maps.get(map_id, {})
	else:
		T = G.S.topdown
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(1920, 1080)
	k = float(C.zoom)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	map_tex = Assets.tex(C.map)
	map_size = map_tex.get_size()
	nav = TopdownNav.new(C, Vector2i(map_size))
	world = Node2D.new()
	world.scale = Vector2(k, k)
	world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world)
	var map := Sprite2D.new()
	map.texture = map_tex
	map.centered = false
	world.add_child(map)
	# 불 창살(기름 도랑) 애니메이션
	for g in C.get("grates", []):
		var gs := Sprite2D.new()
		gs.texture = Assets.tex("td_trap_fire.png")
		gs.hframes = 3
		gs.vframes = 2
		gs.frame = 0
		gs.position = _v(g)
		world.add_child(gs)
		grates.append(gs)
	# 사람과 가리는 물건: 발끝(=노드 y) 기준으로 정렬
	sorter = Node2D.new()
	sorter.y_sort_enabled = true
	world.add_child(sorter)
	# 함정(운명의 시도): 바닥에 깔리므로 사람보다 아래
	fxl = Node2D.new()
	fxl.z_index = 0
	world.add_child(fxl)
	world.move_child(fxl, sorter.get_index())
	fxl.draw.connect(_draw_fate)
	# 인물(적·광신도)
	for n in C.get("npcs", []):
		_make_npc(n)
	# 동료(뒤에 선 사람부터 먼저 넣어 같은 y 일 때 노엘이 위)
	var party: Array = o.get("party", ["seraphina", "brunhild", "elian"] if map_id == "fork" else [])
	foot = _v(o.get("at", C.start))
	dir = str(o.get("dir", C.get("dir", "up")))
	trail.keep = float(C.followGap) * (party.size() + 1) + 24.0
	trail.line_up(foot, _back_of(dir))
	var seats: Dictionary = C.get("party", {}) if o.get("seated", false) else {}
	for i in range(party.size() - 1, -1, -1):
		var fid: String = party[i]
		var w := _walker(str(FOLLOW[fid].sheet), [36, 70])
		var f := {"id": fid, "ally": FOLLOW[fid].ally, "node": w[0], "spr": w[1], "pos": trail.at(foot, _gap(i)), "dir": dir, "frame": 1, "walk_t": 0.0,
			"moving": false, "free": false}
		# ?followers=0: 동료 따라 걷기를 끈다(보이지 않게). 운명의 시도 때만 그 동료가 나타난다
		if G.params.get("followers", "") == "0":
			w[0].visible = false
		if seats.has(fid):
			var s: Array = seats[fid]
			f.pos = Vector2(float(s[0]), float(s[1]))
			f.dir = str(s[2])
			f.free = true   # 처음 자리에서 줄로 걸어 들어간다
		followers.push_front(f)
	var nw := _walker(str(C.sheet), C.foot)
	noel = nw[0]
	noel_spr = nw[1]
	for oc in C.get("occluders", []):
		sorter.add_child(_cut(map_tex, oc.poly, float(oc.base)))
	# 앞벽: 언제나 사람 위
	var front := Node2D.new()
	front.z_index = 1
	world.add_child(front)
	for poly in C.get("front", []):
		front.add_child(_cut(map_tex, poly, 0.0))
	# 불빛(깜빡임) — 더해 그린다
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var glow := UI.grad([[0, Color(1, 0.62, 0.28, 0.55)], [0.45, Color(1, 0.45, 0.15, 0.18)], [1, Color(0, 0, 0, 0)]], "radial", 64, 64)
	for l in C.get("lights", []):
		var ls := Sprite2D.new()
		ls.texture = glow
		ls.material = add
		ls.position = _v(l.at)
		var r := float(l.r) / 32.0
		ls.scale = Vector2(r, r * 0.8)
		ls.z_index = 1
		ls.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		if l.kind == "ember":
			ls.modulate = Color(1, 0.4, 0.15, 0.7)
		world.add_child(ls)
		lights.append({"spr": ls, "conf": l, "ph": randf() * TAU})
	marks = Node2D.new()
	marks.z_index = 2
	world.add_child(marks)
	marks.draw.connect(_draw_marks)
	# 시간 정지(붉은 덮개) — 맵 위, 화면 UI 아래
	tint = ColorRect.new()
	tint.color = Color(0.55, 0.0, 0.05, 0.0)
	tint.size = size
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.z_index = 3
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	add_child(tint)
	# 대화창 옆 스탠딩
	stand = TextureRect.new()
	stand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stand.stretch_mode = TextureRect.STRETCH_SCALE
	stand.modulate.a = 0.0
	stand.visible = false
	stand.z_index = 5
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
	help_l = UI.label(str(G.S.topdown.help), 22, Color(0.85, 0.8, 0.75, 0.75), "sans", HORIZONTAL_ALIGNMENT_RIGHT, 6)
	help_l.position = Vector2(960, 1080 - 46)
	help_l.size = Vector2(940, 34)
	help_l.z_index = 5
	add_child(help_l)
	# 운명 표시·지도 버튼 (시험판에는 없음)
	if not trial:
		hud = FateHud.new()
		hud.z_index = 6
		add_child(hud)
	pad = Control.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size = size
	pad.z_index = 7
	pad.draw.connect(_draw_pad)
	add_child(pad)
	for g in o.get("hide", []):
		npc_group(str(g), false)
	cam = _cam_target()
	_apply()


## 걷는 사람 하나(발밑 그림자 + 걷기 시트). 노드 위치 = 발끝(y 정렬 기준). 반환 [노드, 시트]
func _walker(sheet: String, ft: Array, sc := 1.0) -> Array:
	var n := Node2D.new()
	sorter.add_child(n)
	var shadow := Node2D.new()
	shadow.draw.connect(func():
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(Vector2(cos(a) * 11.0 * sc, sin(a) * 3.5 * sc))
		shadow.draw_colored_polygon(pts, Color(0, 0, 0, 0.35)))
	n.add_child(shadow)
	var spr := Sprite2D.new()
	spr.texture = Assets.tex(sheet)
	spr.centered = false
	spr.hframes = int(C.cols)
	spr.vframes = int(C.rows)
	spr.offset = Vector2(-float(ft[0]), -float(ft[1]))
	spr.scale = Vector2(sc, sc)
	n.add_child(spr)
	return [n, spr]


func _make_npc(n: Dictionary) -> void:
	var sc := float(n.get("scale", 1.0))
	var w := _walker(str(n.sheet), n.get("foot", [36, 70]), sc)
	if n.get("dark", false):
		w[1].modulate = Color(0.42, 0.44, 0.55)
	var e := {"id": str(n.id), "node": w[0], "spr": w[1], "conf": n, "pos": _v(n.at), "dir": str(n.get("dir", "down")), "frame": 1, "walk_t": 0.0, "moving": false}
	if n.get("hidden", false):
		w[0].visible = false
	npcs[str(n.id)] = e


## 인물 무리를 보이거나 숨긴다 (이긴 뒤 광신도를 치움)
func npc_group(group: String, on: bool) -> void:
	for id in npcs:
		if str(npcs[id].conf.get("group", "")) == group:
			npcs[id].node.visible = on


## 인물이 walkTo 자리로 걸어 나온다 (납골당: 석상 사이에서 창 기사)
func npc_walk_out(group: String) -> void:
	var waits := []
	for id in npcs:
		var e: Dictionary = npcs[id]
		if str(e.conf.get("group", "")) != group or not e.conf.has("walkTo"):
			continue
		e.node.visible = true
		var a: Vector2 = e.pos
		var b := _v(e.conf.walkTo)
		e.moving = true
		e.dir = TopdownNav.face_dir(e.dir, b - a)
		var an := FX.anim(a.distance_to(b) / 60.0 * 1000.0, [{"p": a}, {"p": b}], func(v): e.pos = v.p, {"node": self})
		an.finished.connect(func(): e.moving = false)
		waits.append(an)
	await FX.all(waits)


## i 번째 동료가 노엘 뒤로 떨어진 거리 (경로를 따라 잰 맵 px)
func _gap(i: int) -> float:
	return float(C.followGap) * (i + 1)


func _back_of(d: String) -> Vector2:
	return {"up": Vector2.DOWN, "down": Vector2.UP, "left": Vector2.RIGHT, "right": Vector2.LEFT}.get(d, Vector2.DOWN)


## 동료를 노엘 뒤(back 쪽) 일직선 줄로 다시 세운다
func _line_up(back: Vector2) -> void:
	trail.line_up(foot, back)
	for i in followers.size():
		var f: Dictionary = followers[i]
		f.pos = trail.at(foot, _gap(i))
		f.dir = dir
		f.moving = false
		f.walk_t = 0.0
		f.frame = 1
		f.free = false


func _v(a) -> Vector2:
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
## 입구에서 걸어 들어온다(at 이 주어지면 그 자리에서 시작). 시험판은 세라피나의 첫 대사 → 자유 이동
func run() -> void:
	mode = "intro"
	if not opts.has("at"):
		var a := _v(C.start)
		var b := _v(C.entry)
		foot = a
		_line_up(_back_of(dir))
		cam = _cam_target()
		await FX.fade(0, 500)
		if a.distance_to(b) > 1.0:
			moving = true
			dir = TopdownNav.face_dir(dir, b - a)
			var an := FX.anim(a.distance_to(b) / float(C.speed) * 1000.0, [{"p": a}, {"p": b}], func(v): foot = v.p, {"node": self})
			await FX.until(an)
		if not is_inside_tree():
			return
		moving = false
	else:
		await FX.fade(0, 500)
	if trial:
		await FX.wait(250)
		mode = "talk"
		await G.dialog.say(T.intro)
		if is_inside_tree() and mode == "talk":
			mode = "free"


## 자유 이동 → 출구로 나가거나 트리거에 들어서면 그 사건을 돌려준다 ({"type": "exit"|"trigger", "id"})
func next_event() -> Dictionary:
	if not is_inside_tree():
		return {}
	mode = "free"
	var ev = await fired
	return ev


## 트리거를 켠다(이 id 들만 사건이 된다)
func arm(ids: Array) -> void:
	armed = ids.duplicate()


## 탑뷰 위 대사 (대화창 + 옆 스탠딩). 끝나면 원래 상태로
func say(lines: Array) -> void:
	var prev := mode
	mode = "talk"
	path = PackedVector2Array()
	moving = false
	await G.dialog.say(lines)
	if is_inside_tree() and mode == "talk":
		mode = prev if prev != "free" else "event"


## 탑뷰 위에 비주얼노벨 대화(스탠딩·이름표·죽음 카드)를 띄운다 — 캠프·빈 캠프
func play_vn(name: String) -> void:
	mode = "talk"
	vn = VnScene.new()
	vn.setup(name, {"overlay": true})
	vn.z_index = 8
	add_child(vn)
	await vn.run()
	if is_instance_valid(vn):
		var v := vn
		var a := FX.anim(400, [{"a": 1.0}, {"a": 0.0}], func(x): if is_instance_valid(v): v.modulate.a = x.a, {"node": v})
		await FX.until(a)
		v.queue_free()
	vn = null
	mode = "event"


func _process(dt: float) -> void:
	_t += dt
	pace = 1.0
	if mode == "free":
		var kv := _key_dir()
		var sv := stick_vec()
		if kv != Vector2.ZERO:
			path = PackedVector2Array()
			pending = ""
			_step(kv.normalized() * float(C.speed) * dt * FX.speed)
		elif sv != Vector2.ZERO:
			path = PackedVector2Array()
			pending = ""
			pace = sv.length()
			_step(sv * float(C.speed) * dt * FX.speed)
		elif not path.is_empty():
			_follow(float(C.speed) * dt * FX.speed)
		else:
			moving = false
		_update_near()
		_check_triggers()
	elif mode != "intro":
		moving = false
	if moving:
		walk_t += dt * float(C.fps) * FX.speed * pace
		frame = SEQ[int(walk_t) % SEQ.size()]
	else:
		walk_t = 0.0
		frame = 1
	trail.push(foot)
	_update_followers(dt)
	_update_npcs(dt)
	btn_flash = maxf(0.0, btn_flash - dt)
	if not tap_mark.is_empty():
		tap_mark.t += dt
		if tap_mark.t > 0.6:
			tap_mark = {}
	var tc := _cam_target()
	cam = cam.lerp(tc, 1.0 - exp(-float(C.camLerp) * dt))
	_apply()
	_update_stand(dt)
	_update_lights()
	if FX.touch != touch_ui:
		_layout_touch()
	help_l.visible = mode == "free" and not G.dialog.dlg.visible and not desc.visible
	if hud:
		hud.visible = vn == null
	marks.queue_redraw()
	fxl.queue_redraw()
	pad.queue_redraw()


## 동료: 경로를 따라 정해진 거리 뒤의 점으로. 처음 자리(캠프)에 있던 동료는 그 점까지 걸어 들어온다
func _update_followers(dt: float) -> void:
	var full := maxf(0.0001, float(C.speed) * dt * FX.speed)
	var walking_in := mode == "free" or mode == "intro"
	for i in followers.size():
		var f: Dictionary = followers[i]
		var np := trail.at(foot, _gap(i))
		if f.free:
			if not walking_in:
				continue
			var dd: Vector2 = np - f.pos
			if dd.length() <= full * 1.1:
				f.free = false
			else:
				np = f.pos + dd.normalized() * full * 1.1
		var d: Vector2 = np - f.pos
		f.moving = d.length() > 0.02
		if f.moving:
			f.dir = TopdownNav.face_dir(f.dir, d)
			f.walk_t += dt * float(C.fps) * FX.speed * clampf(d.length() / full, 0.3, 1.2)
			f.frame = SEQ[int(f.walk_t) % SEQ.size()]
		else:
			f.walk_t = 0.0
			f.frame = 1
		f.pos = np


func _update_npcs(dt: float) -> void:
	for id in npcs:
		var e: Dictionary = npcs[id]
		if e.moving:
			e.walk_t += dt * float(C.fps) * 0.6 * FX.speed
			e.frame = SEQ[int(e.walk_t) % SEQ.size()]
		else:
			e.frame = 1


func _update_lights() -> void:
	for l in lights:
		var c: Dictionary = l.conf
		var fl := 0.82 + 0.12 * sin(_t * (9.0 if c.kind == "candle" else 6.0) + l.ph) + 0.06 * sin(_t * 23.0 + l.ph * 2.0)
		l.spr.modulate.a = fl * (0.8 if c.kind == "candle" else 1.0) * (0.75 if c.kind == "ember" else 1.0)
	var gf := int(_t * 5.0) % 2
	for g in grates:
		g.frame = gf


func _apply() -> void:
	noel.position = foot.round()
	noel_spr.frame = DIRS.find(dir) * int(C.cols) + frame
	for f in followers:
		f.node.position = f.pos.round()
		f.spr.frame = DIRS.find(f.dir) * int(C.cols) + int(f.frame)
	for id in npcs:
		var e: Dictionary = npcs[id]
		e.node.position = e.pos.round()
		e.spr.frame = DIRS.find(e.dir) * int(C.cols) + int(e.frame)
	# 카메라: 픽셀 한 칸 단위로 맞춰 움직인다(Nearest 확대가 흔들리지 않게)
	world.position = Vector2(960, 540) - cam.round() * k


func _cam_target() -> Vector2:
	var view := Vector2(1920, 1080) / k
	var t: Vector2 = (cam_hold if cam_hold != null else foot) - Vector2(0, 28)
	var out := Vector2.ZERO
	for i in 2:
		if map_size[i] <= view[i]:
			out[i] = map_size[i] / 2.0
		else:
			out[i] = clampf(t[i], view[i] / 2.0, map_size[i] - view[i] / 2.0)
	return out


## 키보드: 누르고 있는 방향 중 가장 나중에 누른 하나로만 걷는다 (4방향, 대각선 없음)
func _key_dir() -> Vector2:
	var keys := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN]}
	for name in keys:
		var on := false
		for kc in keys[name]:
			on = on or Input.is_physical_key_pressed(kc)
		if on and not held.has(name):
			held.append(name)
		elif not on and held.has(name):
			held.erase(name)
	if held.is_empty():
		return Vector2.ZERO
	return {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}[held[held.size() - 1]]


func _face(d: Vector2) -> void:
	dir = TopdownNav.face_dir(dir, d)


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
	for it in C.get("items", []):
		if it.id == id:
			return it
	return {}


func exit_conf(id: String) -> Dictionary:
	for e in C.get("exits", []):
		if e.id == id:
			return e
	return {}


func in_range(id: String) -> bool:
	var it := item(id)
	return not it.is_empty() and foot.distance_to(_v(it.spot)) <= float(it.r)


func _update_near() -> void:
	near = ""
	var bd := INF
	for it in C.get("items", []):
		var d := foot.distance_to(_v(it.spot))
		if d <= float(it.r) and d < bd:
			bd = d
			near = it.id
	var ex := ""
	for e in C.get("exits", []):
		if foot.distance_to(_v(e.at)) <= float(e.r):
			ex = e.id
	if ex != exit_sel:
		exit_sel = ex
		_show_exit(ex)


## 트리거 안에 들어서면 사건 (켜진 것만, 한 번)
func _check_triggers() -> void:
	for t in C.get("triggers", []):
		if not armed.has(t.id):
			continue
		var r: Array = t.rect
		if Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).has_point(foot):
			armed.erase(t.id)
			_fire({"type": "trigger", "id": str(t.id)})
			return


func _fire(ev: Dictionary) -> void:
	mode = "event"
	path = PackedVector2Array()
	pending = ""
	moving = false
	stick = {}
	G.ctl.note("td %s %s" % [ev.type, ev.id])
	fired.emit(ev)


# ───────── 출구 (설명은 화면 아래쪽 가운데) ─────────
func _exit_text(id: String) -> Dictionary:
	if map_id == "fork":
		return G.S.explore.fork.paths.get(id, {})
	return T.get("exits", {}).get(id, {})


func _show_exit(id: String) -> void:
	if id == "":
		desc.visible = false
		return
	var txt := _exit_text(id)
	if locked_exits.has(id):
		_desc(str(txt.get("title", id)), str(txt.get("locked", G.S.topdown.exitLocked)), "")
	else:
		_desc(str(txt.get("title", id)), str(txt.get("desc", "")), str(G.S.topdown.exitHint))
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
	# 노엘이 화면 아래쪽에 있으면 설명을 화면 위쪽에
	var low := to_stage(foot).y > 640.0
	desc.position = Vector2(960 - w * u / 2.0, 30.0 + (120.0 if hud else 0.0) if low else 1080 - 30 - desc.size.y * u)
	desc.visible = true
	desc.queue_redraw()


## 출구로 들어간다 → 시험판: "시험판은 여기까지" → 입구로 / 흐름: 사건(exit)
func leave(id: String) -> void:
	if mode != "free" or locked_exits.has(id):
		return
	exits_log.append(id)
	G.ctl.note("td leave " + id)
	if not trial:
		desc.visible = false
		_fire({"type": "exit", "id": id})
		return
	mode = "leaving"
	path = PackedVector2Array()
	pending = ""
	moving = false
	var txt := _exit_text(id)
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
	_line_up(Vector2.DOWN)
	cam = _cam_target()
	_apply()
	await FX.fade(0, 450)
	if is_inside_tree():
		mode = "free"


## 철창문이 위로 들린다 (맵 그림의 철창 자리를 잘라 위로 밀어 올리고, 그 뒤는 어두운 통로)
func open_gate(exit_id: String) -> void:
	var g: Array = C.get("gates", {}).get(exit_id, [])
	if g.is_empty():
		return
	var r := Rect2(float(g[0]), float(g[1]), float(g[2]), float(g[3]))
	var dark := ColorRect.new()
	dark.color = Color(0.03, 0.02, 0.03)
	dark.position = r.position
	dark.size = r.size
	world.add_child(dark)
	world.move_child(dark, 1)
	var bars := Sprite2D.new()
	bars.texture = map_tex
	bars.centered = false
	bars.region_enabled = true
	bars.region_rect = r
	bars.position = r.position
	world.add_child(bars)
	world.move_child(bars, 2)
	FX.shake(3, 900)
	var a := FX.anim(900, [{"d": 0.0}, {"d": r.size.y - 6.0}], func(v):
		if is_instance_valid(bars):
			bars.region_rect = Rect2(r.position.x, r.position.y + v.d, r.size.x, r.size.y - v.d), {"node": self, "easing": "ease-in-out"})
	await FX.until(a)


## 나가는 연출: 출구 쪽으로 몇 걸음 → 어두워짐 (철창문이면 먼저 들린다)
func walk_out(to = null) -> void:
	mode = "event"
	if exit_sel != "" and C.get("gates", {}).has(exit_sel):
		await open_gate(exit_sel)
		to = [foot.x, foot.y - 30.0]
	var target: Vector2 = foot if to == null else _v(to)
	if foot.distance_to(target) > 1.0:
		moving = true
		_face(target - foot)
		var a := foot
		var an := FX.anim(a.distance_to(target) / float(C.speed) * 1000.0, [{"p": a}, {"p": target}], func(v): foot = v.p, {"node": self})
		await FX.until(an)
		moving = false
	await FX.fade(1, 450)


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
	await G.dialog.say(_item_lines(id))
	if not is_inside_tree():
		return
	inspecting = ""
	if mode == "talk":
		mode = "free"


## 조사 대사: 죽은 동료의 줄은 빼고, 동료가 살아 있을 때만 나오는 줄(alive)은 그때만
func _item_lines(id: String) -> Array:
	var out := []
	var st: Dictionary = G.ctl.st
	for ln in T.get("items", {}).get(id, []):
		var who := str(ln.get("who", ""))
		if not st.is_empty() and st.party.allies.has(who) and st.party.allies[who].status == "dead":
			continue
		out.append(ln)
	return out


# ───────── 입력 ─────────
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		accept_event()
		# 터치에서 흉내 낸 마우스는 버린다 (터치는 _input 의 조이스틱·탭으로 처리)
		if e.device == InputEvent.DEVICE_ID_EMULATION:
			return
		tap(get_local_mouse_position())


# ───────── 터치: 조이스틱 · 조사 버튼 ─────────
func _input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventScreenDrag):
		return
	if G.main and G.main.rotate_hint and G.main.rotate_hint.visible:
		return
	if vn != null or G.scenes.overlay_open():
		return   # 대화 장면·컷신·선택 화면은 자기 입력을 쓴다
	FX.touch = true
	var p := make_canvas_position_local(e.position)
	if e is InputEventScreenTouch:
		if e.pressed:
			if hud and hud.visible and hud.hit(p):
				hud.tap(p)
				get_viewport().set_input_as_handled()
				return
			_touch_down(e.index, p)
		elif not stick.is_empty() and stick.i == e.index:
			if not stick.drag:
				tap(p, true)
			stick = {}
	elif not stick.is_empty() and stick.i == e.index:
		var r := stick_r()
		stick.p = p
		var v: Vector2 = p - stick.c
		if v.length() > float(C.stick.slop) / _cs():
			stick.drag = true
		if v.length() > r:
			stick.c = p - v.normalized() * r
	get_viewport().set_input_as_handled()


func _touch_down(i: int, p: Vector2) -> void:
	if G.dialog.is_busy() or G.dialog.guide_open() or mode != "free":
		tap(p, true)
		return
	if btn_rect().has_point(p):
		btn_flash = 0.2
		confirm()
		return
	if stick.is_empty() and p.x < 960.0:
		stick = {"i": i, "c": p, "p": p, "drag": false}
		return
	tap(p, true)


func _cs() -> float:
	return maxf(0.05, FX.css_scale)


func stick_r() -> float:
	return float(C.stick.d) / 2.0 / _cs()


func stick_vec() -> Vector2:
	if stick.is_empty():
		return Vector2.ZERO
	return TopdownNav.snap4(dir, TopdownNav.stick_to_vec((stick.p - stick.c) / stick_r(), float(C.stick.dead), float(C.stick.min)))


func btn_rect() -> Rect2:
	if not FX.touch or mode != "free":
		return Rect2()
	var d := float(C.stick.btn) / _cs()
	var m := float(C.stick.margin) / _cs()
	return Rect2(Vector2(1920.0 - m - d, 1080.0 - m - d), Vector2(d, d))


func btn_active() -> bool:
	return exit_sel != "" or near != ""


func _layout_touch() -> void:
	touch_ui = FX.touch
	if touch_ui:
		var u := minf(FX.ui, 1.5)
		help_l.text = str(G.S.topdown.helpTouch)
		help_l.scale = Vector2(u, u)
		help_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		help_l.size = Vector2(1100.0 / u, 34)
		help_l.position = Vector2(960 - 550, 1080 - 30 - 34 * u)
	else:
		help_l.text = str(G.S.topdown.help)
		help_l.scale = Vector2.ONE
		help_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		help_l.position = Vector2(960, 1080 - 46)
		help_l.size = Vector2(940, 34)


func _draw_pad() -> void:
	if not stick.is_empty() and mode == "free":
		var r := stick_r()
		var c: Vector2 = stick.c
		var kp: Vector2 = c + (stick.p - c).limit_length(r)
		pad.draw_circle(c, r, Color(1, 1, 1, 0.10))
		pad.draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.35), maxf(3.0, 2.0 / _cs()), true)
		pad.draw_circle(kp, r * float(C.stick.knob), Color(1, 1, 1, 0.32))
		pad.draw_arc(kp, r * float(C.stick.knob), 0, TAU, 32, Color(1, 1, 1, 0.5), maxf(2.0, 1.5 / _cs()), true)
	var b := btn_rect()
	if b.size.x > 0.0:
		var on := btn_active()
		var bc := b.get_center()
		var br := b.size.x / 2.0
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		pad.draw_circle(bc, br, Color(0.08, 0.04, 0.04, (0.62 if on else 0.3) + (0.2 if btn_flash > 0.0 else 0.0)))
		var ring := Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.75 + 0.25 * pulse) if on else Color(1, 1, 1, 0.22)
		pad.draw_arc(bc, br, 0, TAU, 48, ring, maxf(3.0, 2.5 / _cs()), true)
		var txt := str(G.S.topdown.btnEnter) if exit_sel != "" else str(G.S.topdown.btnInspect)
		var fs := int(br * (0.42 if txt.length() <= 2 else 0.3))
		pad.draw_string(Assets.font("sans_bold"), bc + Vector2(-br, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER, br * 2.0, fs,
			Color("#f6e7c8") if on else Color(1, 1, 1, 0.35))


func _unhandled_input(e: InputEvent) -> void:
	if vn != null:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		confirm()
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_M and hud:
		get_viewport().set_input_as_handled()
		hud.open_map()


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


## 탭(무대 좌표): 대사 넘기기 / 운명 표시·지도 / 물건 → 조사 / 출구 → 걸어감, 출구 앞에서 한 번 더 → 들어감 / 그 밖 → 그곳으로 걸어감
## touch: 터치 탭이면 빈 바닥으로 걸어가지 않는다 (이동은 조이스틱)
func tap(p: Vector2, touch := false) -> void:
	if G.dialog.is_busy() or G.dialog.guide_open():
		G.dialog.advance()
		return
	if hud and hud.visible and hud.hit(p):
		if not touch:
			hud.tap(p)
		return
	if mode != "free":
		return
	if desc.visible and exit_sel != "" and Rect2(desc.position, desc.size * desc.scale).has_point(p):
		leave(exit_sel)
		return
	var mp := to_map(p)
	var it := _hit(C.get("items", []), mp)
	if it != "":
		if in_range(it):
			investigate(it)
		else:
			go(_v(item(it).spot), it)
		return
	var ex := _hit(C.get("exits", []), mp)
	if ex != "":
		if ex == exit_sel:
			leave(ex)
		else:
			go(_v(exit_conf(ex).at))
		return
	if not touch:
		go(mp)


func go(p: Vector2, then := "") -> void:
	path = nav.find_path(foot, p)
	pending = then
	tap_mark = {"p": path[path.size() - 1] if not path.is_empty() else p, "t": 0.0}
	G.ctl.note("td go %s → %d점" % [str(p.round()), path.size()])
	if path.is_empty():
		_arrived()


## 시험·자동 진행: 그 출구 앞까지 걸어가 들어간다 / 그 트리거 안으로 걸어간다
func auto_exit(id: String) -> void:
	var e := exit_conf(id)
	if e.is_empty():
		return
	go(_v(e.at))


func auto_trigger(id: String) -> void:
	for t in C.get("triggers", []):
		if t.id == id:
			var r: Array = t.rect
			var c := Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + float(r[3]) / 2.0)
			# 트리거 안의 설 수 있는 가장 가까운 점
			var best := c
			var bd := INF
			for yy in range(int(r[1]) + 2, int(r[1]) + int(r[3]) - 1, 4):
				for xx in range(int(r[0]) + 2, int(r[0]) + int(r[2]) - 1, 4):
					var q := Vector2(xx, yy)
					if nav.can_stand(q) and q.distance_to(foot) < bd:
						bd = q.distance_to(foot)
						best = q
			go(best)


# ───────── 운명의 시도 (필드) ─────────
func follower(fid: String) -> Dictionary:
	for f in followers:
		if f.id == fid:
			return f
	return {}


func follower_of_ally(ally: String) -> String:
	for fid in FOLLOW:
		if FOLLOW[fid].ally == ally:
			return fid
	return ""


## 동료 발밑 함정 판이 철컥 → 시간이 멈추고(붉게) 붉은 실이 팽팽해진다
func fate_trap(fid: String) -> void:
	mode = "event"
	var f := follower(fid)
	if f.is_empty():
		return
	f.node.visible = true
	var spr := Sprite2D.new()
	spr.texture = Assets.tex("td_trap_spike.png")
	spr.hframes = 3
	spr.frame = 0
	spr.scale = Vector2(2, 2)
	spr.offset = Vector2(0, -36)   # 칸 아래 가운데 = 발끝
	spr.position = f.pos.round() + Vector2(0, 8)
	fxl.add_child(spr)
	trap = {"spr": spr, "who": fid}
	cam_hold = (foot + f.pos) / 2.0
	FX.shake(6, 260)
	FX.flash("#ffffff", 120, 0.25)
	G.ctl.note("td fate trap " + fid)
	await FX.wait(350)
	# 시간 정지: 화면이 붉게, 실이 팽팽
	fate_thread = {"who": fid, "t": 0.0}
	var a := FX.anim(700, [{"a": 0.0, "t": 0.0}, {"a": 0.34, "t": 1.0}], func(v):
		tint.color.a = v.a
		fate_thread.t = v.t, {"node": self, "key": "fate_tint"})
	await FX.until(a)


## 바닥에서 창이 솟는다 (바친다): 판 → 짧은 창 → 긴 창, 피
func fate_spikes() -> void:
	if trap.is_empty():
		return
	var spr: Sprite2D = trap.spr
	spr.frame = 1
	FX.shake(8, 200)
	await FX.wait(140)
	spr.frame = 2
	var f := follower(str(trap.who))
	var sp := to_stage(f.get("pos", foot) - Vector2(0, 26))
	FX.flash("#ffffff", 160, 0.6)
	FX.shake(26, 600)
	FX.burst(sp.x, sp.y, {"count": 60, "colors": ["#7a0010", "#b3121f", "#3a0006"], "speed": 420, "life": 900, "size": 5, "gravity": 600})
	if not f.is_empty():
		f.spr.modulate = Color(1.6, 0.4, 0.4)
	await FX.wait(500)


## 거스른다: 붉은 실이 튕기고, 창은 한 뼘 앞에서 멈췄다가 부서진다. 동료는 붉게 깜빡인다
func fate_defy_fx() -> void:
	if trap.is_empty():
		return
	var spr: Sprite2D = trap.spr
	var f := follower(str(trap.who))
	spr.frame = 1
	await FX.wait(160)
	var sp := to_stage(f.get("pos", foot) - Vector2(0, 10))
	FX.flash("#ff2a3c", 200, 0.45)
	FX.shake(14, 400)
	FX.burst(sp.x, sp.y, {"count": 40, "colors": ["#9a9a9a", "#5a5a5a", "#d0c0c0"], "speed": 380, "life": 700, "size": 4, "gravity": 500, "shape": "rock"})
	fate_thread = {}
	var tw := get_tree().create_tween()
	tw.tween_property(spr, "modulate:a", 0.0, FX.ms(500) / 1000.0)
	if not f.is_empty():
		for i in 4:
			f.spr.modulate = Color(1.8, 0.35, 0.35)
			await FX.wait(110)
			f.spr.modulate = Color.WHITE
			await FX.wait(110)
	await FX.wait(200)


## 바친 뒤 남겨 둔 창 함정이 바닥으로 가라앉고 핏자국만 남는다 (뒤따르던 동료가 그 자리에 서므로)
func fate_trap_fade() -> void:
	for c in fxl.get_children():
		if c is Sprite2D and c.texture == Assets.tex("td_trap_spike.png"):
			var s: Sprite2D = c
			var at := s.position
			var stain := Node2D.new()
			stain.position = at + Vector2(0, -8)
			stain.draw.connect(func():
				for i in 7:
					var o := Vector2(cos(i * 2.1) * 9.0, sin(i * 1.7) * 3.0)
					stain.draw_circle(o, 5.0 + (i % 3) * 2.0, Color(0.35, 0.0, 0.03, 0.7))
				stain.draw_circle(Vector2.ZERO, 7.0, Color(0.45, 0.0, 0.04, 0.8)))
			fxl.add_child(stain)
			fxl.move_child(stain, 0)
			var tw := get_tree().create_tween()
			tw.tween_property(s, "modulate:a", 0.0, FX.ms(600) / 1000.0)
			tw.tween_callback(s.queue_free)


## 운명 연출을 걷는다(붉은 덮개·실). keep_trap: 바친 뒤 피 묻은 창은 바닥에 남긴다
func fate_clear(keep_trap := false) -> void:
	fate_thread = {}
	var a := FX.anim(500, [{"a": tint.color.a}, {"a": 0.0}], func(v): tint.color.a = v.a, {"node": self, "key": "fate_tint"})
	if not keep_trap and not trap.is_empty() and is_instance_valid(trap.spr):
		trap.spr.queue_free()
	trap = {}
	cam_hold = null
	await FX.until(a)


## 바친 동료가 줄에서 빠진다
func remove_follower(fid: String) -> void:
	for i in followers.size():
		if followers[i].id == fid:
			followers[i].node.queue_free()
			followers.remove_at(i)
			return


## 붉은 실(맵 좌표): 그 동료의 등 → 노엘의 손
func _draw_fate() -> void:
	if fate_thread.is_empty():
		return
	var f := follower(str(fate_thread.who))
	if f.is_empty():
		return
	var a: Vector2 = f.pos + Vector2(0, -34)
	var b := foot + Vector2(4, -26)
	var tt: float = fate_thread.t
	var vib := sin(_t * 50.0) * (0.6 + tt * 0.8)
	var m := (a + b) / 2.0 + Vector2(vib, (1.0 - tt) * 10.0)
	UI.glow_curve(fxl, a, m, b, 0.8 + tt * 0.6, Color(1, 0.12, 0.2, 0.6 + 0.4 * tt), 3.0 + tt * 3.0)
	fxl.draw_circle(a, 1.5, Color(1, 0.3, 0.35, tt))
	fxl.draw_circle(b, 1.5, Color(1, 0.3, 0.35, tt))


# ───────── 표시 ─────────
## 물건마다 옅은 반짝임, 조사할 수 있는 거리면 ! 말풍선, 탭한 곳 표시 (맵 픽셀 단위로 그려 도트와 맞춘다)
func _draw_marks() -> void:
	var ci := marks
	for it in C.get("items", []):
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
		for e in C.get("exits", []):
			if locked_exits.has(e.id):
				continue
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
	if vn == null and G.dialog.cur != null and not G.dialog.cur.guide and not (hud and hud.map != null and hud.map.visible):
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
	return {"map": map_id, "pos": [snappedf(foot.x, 0.1), snappedf(foot.y, 0.1)], "dir": dir, "frame": frame, "sheetFrame": noel_spr.frame, "moving": moving,
		"mode": mode, "near": near, "exit": exit_sel, "inspecting": inspecting, "inspected": inspected, "exits": exits_log, "armed": armed,
		"canStand": nav.can_stand(foot), "path": path.size(), "cam": [cam.x, cam.y], "zoom": k, "mapSize": [map_size.x, map_size.y],
		"stand": stand_who if stand.visible else "", "desc": desc_text.text if desc.visible else "",
		"world": [world.position.x, world.position.y], "t": Time.get_ticks_msec(), "pace": pace, "gap": float(C.followGap),
		"followers": followers.map(func(f): return {"id": f.id, "pos": [snappedf(f.pos.x, 0.1), snappedf(f.pos.y, 0.1)], "dir": f.dir,
			"frame": f.frame, "sheetFrame": f.spr.frame, "moving": f.moving}),
		"npcs": npcs.keys().filter(func(id): return npcs[id].node.visible),
		"trap": trap.get("spr").frame if not trap.is_empty() and is_instance_valid(trap.get("spr")) else -1, "tint": tint.color.a, "vn": vn != null,
		"touch": FX.touch, "stick": {"on": not stick.is_empty(), "drag": stick.get("drag", false),
			"c": [stick.c.x, stick.c.y] if not stick.is_empty() else [], "r": stick_r(), "v": [stick_vec().x, stick_vec().y]},
		"btn": {"rect": [btn_rect().position.x, btn_rect().position.y, btn_rect().size.x, btn_rect().size.y], "active": btn_active()},
		"hud": hud.test_state() if hud else {}}
