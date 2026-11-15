extends Node2D
## 접히는 헥스 지도 시안 (docs/eska-turn/game_structure.md — 2026-10-19 사용자 "간단하게만 폰으로 조작할 수 있게").
## 에스카(공간의 마녀)가 지도 칸을 돌리고(60°) 맞바꿔 길을 잇는다. 길로 이어진 칸만 걸어갈 수 있다.
## 목표: 마을에 들러 탑 열쇠를 얻고 탑에 닿기. 마력(접기 횟수)은 정해져 있다. 장소 칸은 안내 판만 (장면·전투는 시안 밖).
## 칸 = 뾰족 위 헥스, 홀수 줄이 반 칸 오른쪽(odd-r). 방향 0 동 · 1 북동 · 2 북서 · 3 서 · 4 남서 · 5 남동 (화면 y 아래).
## 조작: 누르기(마우스·터치) · 키 1 이동 / 2 돌리기 / 3 맞바꾸기 · Z 되돌리기 · R 처음부터 · Esc 타이틀.

const R := 30.0 ## 헥스 반지름 (꼭짓점까지)
const COLS := 7
const ROWS := 5
const ORIGIN := Vector2(236, 80) ## (0,0) 칸 가운데
const POWER_MAX := 8
const DIRS := [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)] ## 축 좌표 이웃
const STEP_T := 0.16 ## 한 칸 걷는 시간

## 지형: grass 풀밭 · forest 숲 · water 호수 · mountain 산 · home 마녀의 집 · village 마을 · tower 탑
## fixed = 돌리기·맞바꾸기 안 됨 (호수·산·장소)
const TERRAIN_COL := {"grass": Color("#3f6a3a"), "forest": Color("#2c4f34"), "water": Color("#2d5f8a"), "mountain": Color("#5a5566"),
	"home": Color("#4a3a5e"), "village": Color("#6a5236"), "tower": Color("#3a3050")}
const ROAD := Color("#d8c08a")
const ROAD_EDGE := Color("#5a4428")
const ESKA := Color("#b48cff") ## 공간 마녀 색 (보라)

## 처음 지도 — [지형, 길 방향들]. 풀이: (2,1) 1회 · (1,2) 1회 · (2,2) 2회 · (4,2) 1회 돌리기, (3,1)↔(6,4) 맞바꾸고 1회 돌리기 = 7 (마력 8)
const LEVEL := [
	[["forest", []], ["grass", []], ["village", [5]], ["mountain", []], ["grass", [1, 4]], ["forest", []], ["mountain", []]],
	[["water", []], ["grass", [3, 5]], ["grass", [1, 3, 5]], ["grass", []], ["forest", []], ["grass", [3]], ["water", []]],
	[["home", [0]], ["grass", [1, 4]], ["grass", [3, 5]], ["water", []], ["grass", [1, 3]], ["grass", [0, 3]], ["tower", [3]]],
	[["forest", []], ["grass", [1, 4]], ["grass", []], ["mountain", []], ["mountain", []], ["grass", [0, 2]], ["forest", []]],
	[["mountain", []], ["grass", []], ["grass", [0, 2, 4]], ["grass", []], ["forest", []], ["grass", []], ["grass", [4, 0]]],
]
const FIXED_KINDS := ["water", "mountain", "home", "village", "tower"]

var tiles := {} ## Vector2i(col,row) → {kind, roads: Array[int], rot_anim: float}
var party := Vector2i(0, 2)
var party_pos := Vector2.ZERO ## 그릴 자리 (걷는 동안 사이)
var path: Array = []
var step_t := 0.0
var power := POWER_MAX
var mode := "move" ## move · rotate · swap
var pick := Vector2i(-1, -1) ## 맞바꾸기 첫 칸
var has_key := false
var won := false
var popup := "" ## 장소 안내 글
var undo: Array = []
var flash := {} ## 칸 → 남은 빛 시간 (접기 연출)
var hint := ""
var _t := 0.0
var _scale_was: Array = []

## 왼쪽 판 버튼 (640×360 설계 좌표)
const BTN := {
	"move": Rect2(12, 92, 176, 40), "rotate": Rect2(12, 138, 176, 40), "swap": Rect2(12, 184, 176, 40),
	"undo": Rect2(12, 250, 84, 36), "reset": Rect2(104, 250, 84, 36),
}


func _ready() -> void:
	# 폰 시험에서 화면을 채우게 소수 배율 (나갈 때 되돌림 — TStage와 같은 방식)
	var win := get_tree().root
	_scale_was = [win.content_scale_stretch]
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	_reset()


func _exit_tree() -> void:
	TTheme.release()
	if not _scale_was.is_empty():
		get_tree().root.content_scale_stretch = _scale_was[0]


func _reset() -> void:
	tiles.clear()
	for row in ROWS:
		for col in COLS:
			var d: Array = LEVEL[row][col]
			tiles[Vector2i(col, row)] = {"kind": String(d[0]), "roads": (d[1] as Array).duplicate(), "rot_anim": 0.0}
	party = Vector2i(0, 2)
	party_pos = center(party)
	path = []
	power = POWER_MAX
	mode = "move"
	pick = Vector2i(-1, -1)
	has_key = false
	won = false
	popup = ""
	undo = []
	flash = {}
	hint = "칸을 눌러 걸어가세요. 길이 끊겼으면 '돌리기'·'맞바꾸기'로 지도를 접습니다."
	queue_redraw()


# ─── 좌표 ───────────────────────────────────────────

static func to_axial(c: Vector2i) -> Vector2i:
	return Vector2i(c.x - (c.y - (c.y & 1)) / 2, c.y)


static func to_offset(a: Vector2i) -> Vector2i:
	return Vector2i(a.x + (a.y - (a.y & 1)) / 2, a.y)


static func neighbor(c: Vector2i, d: int) -> Vector2i:
	return to_offset(to_axial(c) + DIRS[d])


static func center(c: Vector2i) -> Vector2:
	var w := sqrt(3.0) * R
	return ORIGIN + Vector2(w * (float(c.x) + (0.5 if (c.y & 1) == 1 else 0.0)), 1.5 * R * float(c.y))


## 방향 d 쪽 변의 가운데 각도 (라디안)
static func dir_angle(d: int) -> float:
	return deg_to_rad(-60.0 * float(d))


func cell_at(p: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := INF
	for c: Vector2i in tiles:
		var dd := center(c).distance_to(p)
		if dd < bd:
			bd = dd
			best = c
	return best if bd <= R * 0.95 else Vector2i(-1, -1)


func fixed(c: Vector2i) -> bool:
	return String(tiles[c].kind) in FIXED_KINDS


## a에서 방향 d로 길이 이어지나
func linked(a: Vector2i, d: int) -> bool:
	var b := neighbor(a, d)
	if not tiles.has(b):
		return false
	return (tiles[a].roads as Array).has(d) and (tiles[b].roads as Array).has((d + 3) % 6)


## 일행 칸에서 길로 갈 수 있는 칸 → 앞 칸 (BFS)
func reach() -> Dictionary:
	var prev := {party: party}
	var q: Array = [party]
	while not q.is_empty():
		var a: Vector2i = q.pop_front()
		for d in 6:
			if linked(a, d):
				var b := neighbor(a, d)
				if not prev.has(b):
					prev[b] = a
					q.append(b)
	return prev


# ─── 입력 ───────────────────────────────────────────

func _unhandled_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and not k.echo:
		match k.keycode:
			KEY_1: _set_mode("move")
			KEY_2: _set_mode("rotate")
			KEY_3: _set_mode("swap")
			KEY_Z: _undo()
			KEY_R: _reset()
			KEY_ESCAPE: get_tree().change_scene_to_file("res://ui/title.tscn")
		return
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_tap(get_global_mouse_position())


func _tap(p: Vector2) -> void:
	if won:
		_reset()
		return
	if popup != "":
		popup = ""
		queue_redraw()
		return
	for k: String in BTN:
		if (BTN[k] as Rect2).has_point(p):
			match k:
				"undo": _undo()
				"reset": _reset()
				_: _set_mode(k)
			return
	if not path.is_empty():
		return # 걷는 중
	var c := cell_at(p)
	if c.x < 0:
		return
	match mode:
		"move": _walk_to(c)
		"rotate": _rotate(c)
		"swap": _swap_pick(c)


func _set_mode(m: String) -> void:
	mode = m
	pick = Vector2i(-1, -1)
	match m:
		"move": hint = "갈 칸을 누르세요. 길로 이어진 칸(밝게 빛남)만 갈 수 있습니다."
		"rotate": hint = "돌릴 칸을 누르세요. 누를 때마다 60° 돌고 마력 1을 씁니다."
		"swap": hint = "바꿀 두 칸을 차례로 누르세요. 멀리 떨어져도 공간을 접어 맞바꿉니다 (마력 1)."
	queue_redraw()


func _walk_to(c: Vector2i) -> void:
	if c == party:
		return
	var prev := reach()
	if not prev.has(c):
		hint = "그 칸으로 가는 길이 없습니다. 지도를 접어 길을 이으세요."
		queue_redraw()
		return
	var seq: Array = []
	var cur := c
	while cur != party:
		seq.push_front(cur)
		cur = prev[cur]
	path = seq
	step_t = 0.0


func _can_fold(c: Vector2i) -> bool:
	if fixed(c):
		hint = "산·호수·장소 칸은 접을 수 없습니다."
	elif c == party:
		hint = "일행이 서 있는 칸은 접을 수 없습니다."
	elif power <= 0:
		hint = "마력이 바닥났습니다. 되돌리기(Z)나 처음부터(R)."
	else:
		return true
	queue_redraw()
	return false


func _rotate(c: Vector2i) -> void:
	if not _can_fold(c):
		return
	if (tiles[c].roads as Array).is_empty():
		hint = "길이 없는 칸은 돌려도 그대로입니다 — 맞바꾸기로 길 칸을 가져오세요."
		queue_redraw()
		return
	_push_undo()
	var nr: Array = []
	for d: int in tiles[c].roads:
		nr.append((d + 5) % 6) # 시계 방향 60°
	tiles[c].roads = nr
	tiles[c].rot_anim = 1.0
	power -= 1
	flash[c] = 0.5
	hint = "돌렸습니다. 남은 마력 %d" % power
	queue_redraw()


func _swap_pick(c: Vector2i) -> void:
	if not _can_fold(c):
		return
	if pick.x < 0:
		pick = c
		hint = "바꿀 다른 칸을 누르세요 (같은 칸을 다시 누르면 취소)."
		queue_redraw()
		return
	if pick == c:
		pick = Vector2i(-1, -1)
		hint = "취소했습니다."
		queue_redraw()
		return
	_push_undo()
	var a: Dictionary = tiles[pick]
	tiles[pick] = tiles[c]
	tiles[c] = a
	power -= 1
	flash[pick] = 0.7
	flash[c] = 0.7
	pick = Vector2i(-1, -1)
	hint = "공간을 접어 두 칸을 맞바꿨습니다. 남은 마력 %d" % power
	queue_redraw()


func _push_undo() -> void:
	var snap := {}
	for c: Vector2i in tiles:
		snap[c] = {"kind": tiles[c].kind, "roads": (tiles[c].roads as Array).duplicate(), "rot_anim": 0.0}
	undo.append({"tiles": snap, "power": power})


func _undo() -> void:
	if undo.is_empty() or not path.is_empty():
		return
	var u: Dictionary = undo.pop_back()
	tiles = u.tiles
	power = int(u.power)
	pick = Vector2i(-1, -1)
	hint = "되돌렸습니다. 남은 마력 %d" % power
	queue_redraw()


func _arrive(c: Vector2i) -> void:
	match String(tiles[c].kind):
		"village":
			if not has_key:
				has_key = true
				popup = "버려진 마을\n\n여기서 이야기 장면과 전투가 열립니다 (시안에는 없음).\n마을 사람에게서 '탑 열쇠'를 받았습니다."
			else:
				popup = "버려진 마을\n\n이미 들른 곳입니다."
		"tower":
			if has_key:
				won = true
			else:
				popup = "잠긴 탑\n\n문이 잠겨 있습니다. 마을에서 열쇠를 찾아야 합니다."
		"home":
			popup = "마녀의 집\n\n거점 — 편성·성장·대화 (시안에는 없음)."


# ─── 매 프레임 ─────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	if not path.is_empty():
		step_t += delta
		var nxt: Vector2i = path[0]
		party_pos = center(party).lerp(center(nxt), clampf(step_t / STEP_T, 0.0, 1.0))
		if step_t >= STEP_T:
			party = nxt
			path.pop_front()
			step_t = 0.0
			party_pos = center(party)
			if path.is_empty() or String(tiles[party].kind) in ["village", "tower"]:
				path = []
				_arrive(party)
	for c: Vector2i in tiles:
		if float(tiles[c].rot_anim) > 0.0:
			tiles[c].rot_anim = maxf(0.0, float(tiles[c].rot_anim) - delta / 0.15)
	for c in flash.keys():
		flash[c] = float(flash[c]) - delta
		if float(flash[c]) <= 0.0:
			flash.erase(c)
	queue_redraw()


# ─── 그리기 ─────────────────────────────────────────

func _hex_pts(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * float(i) - 30.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw() -> void:
	draw_rect(Rect2(-400, -400, 1440, 1160), Color("#0e0916"))
	# 밤하늘 띠
	draw_rect(Rect2(0, 0, 640, 360), Color("#140c22"))
	for i in 24:
		var sp := Vector2(fmod(float(i) * 97.0, 640.0), fmod(float(i) * 53.0, 70.0) + 6.0)
		draw_rect(Rect2(sp, Vector2(1, 1)), Color(1, 1, 1, 0.25 + 0.2 * sin(_t * 1.3 + float(i))))
	var rch := reach() if mode == "move" and path.is_empty() else {}
	for c: Vector2i in tiles:
		_draw_tile(c, rch.has(c) and c != party)
	_draw_party()
	_draw_panel()
	if popup != "":
		_draw_popup()
	if won:
		_draw_win()


func _draw_tile(c: Vector2i, reachable: bool) -> void:
	var t: Dictionary = tiles[c]
	var p := center(c)
	var kind := String(t.kind)
	var base: Color = TERRAIN_COL[kind]
	var hex := _hex_pts(p, R - 1.0)
	draw_colored_polygon(hex, base)
	# 아래쪽 그늘 (입체감)
	var lo := _hex_pts(p + Vector2(0, R * 0.35), R * 0.62)
	draw_colored_polygon(lo, base.darkened(0.12))
	match kind:
		"forest":
			for o: Vector2 in [Vector2(-10, -4), Vector2(8, -8), Vector2(2, 8), Vector2(-14, 10), Vector2(14, 6)]:
				var q := p + o
				draw_colored_polygon(PackedVector2Array([q + Vector2(0, -8), q + Vector2(-5, 3), q + Vector2(5, 3)]), Color("#1c3a24"))
		"water":
			for i in 3:
				var y := -8.0 + 8.0 * float(i)
				var x := sin(_t * 1.5 + float(i)) * 3.0
				draw_line(p + Vector2(-10 + x, y), p + Vector2(4 + x, y), Color("#7fb6e0", 0.6), 1.0)
		"mountain":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 10), p + Vector2(-2, -14), p + Vector2(12, 10)]), Color("#8a8496"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -14), p + Vector2(4, -4), p + Vector2(-8, -4)]), Color("#e6e0f0"))
		"grass":
			for o: Vector2 in [Vector2(-12, -10), Vector2(12, 12), Vector2(-6, 14)]:
				draw_line(p + o, p + o + Vector2(1, -3), Color("#5f8a50"), 1.0)
	# 길
	var rot := float(t.rot_anim) * deg_to_rad(-60.0) # 돌리는 중 (시계 방향으로 따라 돎)
	for d: int in t.roads:
		var a := dir_angle(d) + rot
		var e := p + Vector2(cos(a), sin(a)) * (sqrt(3.0) * 0.5 * R)
		draw_line(p, e, ROAD_EDGE, 9.0)
	for d: int in t.roads:
		var a := dir_angle(d) + rot
		var e := p + Vector2(cos(a), sin(a)) * (sqrt(3.0) * 0.5 * R)
		draw_line(p, e, ROAD, 6.0)
	if not (t.roads as Array).is_empty():
		draw_circle(p, 4.5, ROAD)
	# 장소
	match kind:
		"home":
			_house(p, Color("#c9a0ff"))
		"village":
			_house(p + Vector2(-6, -2), Color("#ffcf8a"))
			_house(p + Vector2(7, 3), Color("#e0a870"))
			if has_key:
				draw_circle(p + Vector2(0, R * 0.55), 3.5, TTheme.HEAL)
		"tower":
			draw_rect(Rect2(p + Vector2(-6, -16), Vector2(12, 24)), Color("#6a5a8a"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -16), p + Vector2(0, -26), p + Vector2(9, -16)]), Color("#9a7ad0"))
			draw_rect(Rect2(p + Vector2(-2, -2), Vector2(4, 10)), Color("#1a1226"))
			if not has_key:
				draw_arc(p + Vector2(0, -4), 3.0, PI, TAU, 8, TTheme.GOLD, 1.5)
				draw_rect(Rect2(p + Vector2(-4, -4), Vector2(8, 6)), TTheme.GOLD)
	# 테: 고정 칸 돌테, 접을 수 있는 칸 옅은 테, 갈 수 있는 칸 빛
	var border := Color("#2a2036")
	var bw := 2.0
	if fixed(c):
		border = Color("#8a8070") if kind in ["water", "mountain"] else TTheme.GOLD
		bw = 2.0
	if reachable:
		border = Color(TTheme.GOLD, 0.55 + 0.35 * sin(_t * 4.0))
		bw = 2.5
	if mode != "move" and not fixed(c) and c != party:
		border = Color(ESKA, 0.6)
	if c == pick:
		border = Color(ESKA, 0.7 + 0.3 * sin(_t * 8.0))
		bw = 3.5
	var ring := _hex_pts(p, R - 1.0)
	ring.append(ring[0])
	draw_polyline(ring, border, bw)
	if flash.has(c):
		var k := clampf(float(flash[c]) / 0.7, 0.0, 1.0)
		draw_colored_polygon(_hex_pts(p, R - 2.0), Color(ESKA, 0.45 * k))
		var r2 := _hex_pts(p, R * (1.0 + 0.4 * (1.0 - k)))
		r2.append(r2[0])
		draw_polyline(r2, Color(ESKA, k), 2.0)


func _house(p: Vector2, roof: Color) -> void:
	draw_rect(Rect2(p + Vector2(-6, -4), Vector2(12, 10)), Color("#d8c8b0"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -4), p + Vector2(0, -12), p + Vector2(8, -4)]), roof)
	draw_rect(Rect2(p + Vector2(-2, 1), Vector2(4, 5)), Color("#3a2a20"))


func _draw_party() -> void:
	var p := party_pos + Vector2(0, -6 + sin(_t * 3.0) * 1.5)
	draw_circle(party_pos + Vector2(0, 9), 7.0, Color(0, 0, 0, 0.35))
	# 에스카: 옷 · 얼굴 · 모자
	draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 12), p + Vector2(0, -2), p + Vector2(7, 12)]), Color("#3a2a5e"))
	draw_circle(p + Vector2(0, -4), 4.5, Color("#f0e0d0"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -6), p + Vector2(2, -22), p + Vector2(9, -6)]), Color("#2a1e48"))
	draw_line(p + Vector2(-10, -6), p + Vector2(10, -6), ESKA, 2.0)


func _btn(k: String, label: String, sub: String) -> void:
	var r: Rect2 = BTN[k]
	var on := mode == k
	TTheme.panel(self, r, TTheme.PANEL_HI if on else TTheme.PANEL, TTheme.GOLD if on else Color(TTheme.LINE, 0.55), 2 if on else 1, 4)
	TTheme.text(self, r.position + Vector2(10, 17), label, 12, TTheme.GOLD if on else TTheme.TEXT)
	if sub != "":
		TTheme.text(self, r.position + Vector2(10, 32), sub, 10, TTheme.TEXT_SUB)


func _draw_panel() -> void:
	TTheme.text(self, Vector2(12, 26), "접히는 지도", 15, TTheme.GOLD)
	TTheme.text(self, Vector2(12, 42), "시안 — 에스카의 공간 접기", 10, TTheme.TEXT_SUB)
	# 마력
	TTheme.text(self, Vector2(12, 66), "마력", 10, TTheme.TEXT_SUB)
	for i in POWER_MAX:
		var c := Vector2(48 + 16 * i, 62)
		TTheme.diamond(self, c, 5.0, ESKA if i < power else TTheme.EMPTY)
	TTheme.text(self, Vector2(12, 82), "탑 열쇠: %s" % ("있음" if has_key else "없음 (마을에서)"), 10, TTheme.HEAL if has_key else TTheme.TEXT_SUB)
	_btn("move", "1  걷기", "길로 이어진 칸으로")
	_btn("rotate", "2  돌리기", "60° · 마력 1")
	_btn("swap", "3  맞바꾸기", "두 칸 자리 바꿈 · 마력 1")
	for k: String in ["undo", "reset"]:
		var r: Rect2 = BTN[k]
		TTheme.panel(self, r, TTheme.PANEL, Color(TTheme.LINE, 0.55), 1, 4)
		TTheme.text(self, r.position + Vector2(r.size.x * 0.5, 23), "되돌리기" if k == "undo" else "처음부터", 12, TTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	TTheme.wrap(self, Vector2(12, 304), hint, 186, 10, TTheme.TEXT, 13.0, 4)
	TTheme.text(self, Vector2(628, 352), "목표: 마을에 들러 열쇠 → 탑", 10, TTheme.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_popup() -> void:
	var r := Rect2(240, 96, 340, 170)
	draw_rect(Rect2(-400, -400, 1440, 1160), Color(0, 0, 0, 0.45))
	TTheme.panel(self, r, TTheme.PANEL, TTheme.GOLD, 2, 6)
	var lines := popup.split("\n")
	TTheme.text(self, r.position + Vector2(r.size.x * 0.5, 30), lines[0], 15, TTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var rest := "\n".join(lines.slice(1)).strip_edges()
	TTheme.wrap(self, r.position + Vector2(20, 62), rest, r.size.x - 40, 12, TTheme.TEXT, 17.0)
	TTheme.text(self, r.position + Vector2(r.size.x * 0.5, r.size.y - 12), "누르면 닫힘", 10, TTheme.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_win() -> void:
	draw_rect(Rect2(-400, -400, 1440, 1160), Color(0, 0, 0, 0.5))
	var r := Rect2(200, 130, 400, 100)
	TTheme.panel(self, r, TTheme.PANEL_HI, TTheme.GOLD, 2, 6)
	TTheme.text(self, r.position + Vector2(r.size.x * 0.5, 40), "탑에 닿았습니다", 15, TTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	TTheme.text(self, r.position + Vector2(r.size.x * 0.5, 64), "쓴 마력 %d / %d" % [POWER_MAX - power, POWER_MAX], 12, TTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	TTheme.text(self, r.position + Vector2(r.size.x * 0.5, 86), "누르면 처음부터", 10, TTheme.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
