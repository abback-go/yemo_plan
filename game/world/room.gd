class_name Room
extends Node2D
## RoomData를 받아 실제 방을 만든다: 배경 → 타일(이미지 한 장으로 굽기) → 충돌 → 개체.
## 방을 떠나면 통째로 지운다. 지속되는 상태(처치·열림·발견)는 GameState에 기록.

const T := 16.0
const ENEMY_KINDS := {
	"charger": "res://enemies/charger.tscn",
	"sniper": "res://enemies/sniper.tscn",
}

var data: RoomData
var theme: Dictionary
var size_px := Vector2.ZERO
var markers := {} ## 이름 → 발밑 전역 좌표
var exits := {} ## id → RoomExit
var doors := {} ## id → RoomDoor
var saves := {} ## id → SavePoint
var actors := {} ## npc id → Npc (컷신에서 움직임)
var enemies: Array = []

var _bg: Node2D
var _tiles: Sprite2D
var _entities: Node2D
var _front: Node2D


func build(d: RoomData) -> void:
	data = d
	name = "Room_" + d.id
	theme = RoomTheme.get_theme(d.theme)
	size_px = d.size_px()
	_bg = Node2D.new()
	_bg.name = "Background"
	_bg.z_index = -20
	add_child(_bg)
	RoomBackdrop.build(self, _bg)

	_tiles = Sprite2D.new()
	_tiles.name = "Tiles"
	_tiles.centered = false
	_tiles.texture = ImageTexture.create_from_image(TilePainter.paint(d, theme, "#=^"))
	_tiles.z_index = -2
	add_child(_tiles)

	_build_solids()
	_build_bounds()
	_build_platforms()
	_build_hazards()
	_build_special_regions()

	_entities = Node2D.new()
	_entities.name = "Entities"
	add_child(_entities)
	_front = Node2D.new()
	_front.name = "Foreground"
	_front.z_index = 30
	add_child(_front)
	for i in d.entities.size():
		var e: Dictionary = d.entities[i]
		if not RoomData.cond_ok(String(e.get("cond", ""))):
			continue
		_spawn_entity(e, i)
	RoomBackdrop.build_foreground(self, _front)


# ─── 충돌 ───────────────────────────────────────────────

## 같은 문자 칸을 직사각형으로 묶는다 (가로로 이어진 칸 → 아래로 같은 폭이면 합침)
static func merge_rects(d: RoomData, ch: String) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	var open := {} # "x0,x1" → Rect2i
	for y in d.row_count() + 1:
		var runs := {}
		if y < d.row_count():
			var x := 0
			var cols := d.cols()
			while x < cols:
				if d.char_at(x, y) == ch:
					var x0 := x
					while x < cols and d.char_at(x, y) == ch:
						x += 1
					runs["%d,%d" % [x0, x]] = Vector2i(x0, x)
				else:
					x += 1
		var next_open := {}
		for k in open:
			if runs.has(k):
				var r: Rect2i = open[k]
				r.size.y += 1
				next_open[k] = r
				runs.erase(k)
			else:
				out.append(open[k])
		for k in runs:
			var v: Vector2i = runs[k]
			next_open[k] = Rect2i(v.x, y, v.y - v.x, 1)
		open = next_open
	return out


func _rect_shape(r: Rect2i) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(r.size) * T
	cs.shape = rs
	cs.position = (Vector2(r.position) + Vector2(r.size) * 0.5) * T
	return cs


func _build_solids() -> void:
	var body := StaticBody2D.new()
	body.name = "Solids"
	body.collision_layer = GameConst.L_WORLD
	body.collision_mask = 0
	for r in merge_rects(data, "#"):
		body.add_child(_rect_shape(r))
	add_child(body)


## 방 좌우 바깥의 보이지 않는 벽: 출구 자리가 뚫려 있어도 세라·적이 방 밖 허공으로 나가지 못하게 한다.
## (출구 판정은 방 안쪽 첫 칸이라, 벽에 붙어 서면 출구가 작동한다. 보스전처럼 대본이 출구를 막는 동안엔 그냥 벽)
func _build_bounds() -> void:
	var body := StaticBody2D.new()
	body.name = "Bounds"
	body.collision_layer = GameConst.L_WORLD
	body.collision_mask = 0
	var h := size_px.y + 800.0
	for x: float in [-32.0, size_px.x + 32.0]:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(64, h)
		cs.shape = rs
		cs.position = Vector2(x, size_px.y * 0.5)
		body.add_child(cs)
	add_child(body)


func _build_platforms() -> void:
	var body := StaticBody2D.new()
	body.name = "Platforms"
	body.collision_layer = GameConst.L_PLATFORM
	body.collision_mask = 0
	for r in merge_rects(data, "="):
		# 통과 발판은 한 줄씩 (위에서만 밟힘)
		for row in r.size.y:
			var cs := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = Vector2(r.size.x * T, 6)
			cs.shape = rs
			cs.one_way_collision = true
			cs.position = Vector2((r.position.x + r.size.x * 0.5) * T, (r.position.y + row) * T + 3)
			body.add_child(cs)
	add_child(body)


func _build_hazards() -> void:
	for r in merge_rects(data, "^"):
		var hz := Hazard.new()
		hz.setup(Rect2(Vector2(r.position) * T + Vector2(1, 6), Vector2(r.size) * T - Vector2(2, 6)))
		add_child(hz)


## 환영 벽(I)·숨은 발판(H)·부서지는 벽(W): 이어진 덩어리마다 노드 하나
func _build_special_regions() -> void:
	var idx := 0
	for ch in ["I", "W", "H"]:
		for region in _regions(ch):
			idx += 1
			var key := "%s_%s%d" % [data.id, ch, idx]
			match ch:
				"I":
					var w := IllusionWall.new()
					w.setup(self, region, key)
					add_child(w)
				"W":
					var b := BreakableWall.new()
					b.setup(self, region, key)
					add_child(b)
				"H":
					var h := HiddenPlatform.new()
					h.setup(self, region, key)
					add_child(h)


## 같은 문자로 이어진 칸 묶음(상하좌우 연결)
func _regions(ch: String) -> Array:
	var seen := {}
	var out := []
	for y in data.row_count():
		for x in data.cols():
			if data.char_at(x, y) != ch or seen.has(Vector2i(x, y)):
				continue
			var cells: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[Vector2i(x, y)] = true
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				cells.append(c)
				for dv in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n: Vector2i = c + dv
					if data.char_at(n.x, n.y) == ch and not seen.has(n):
						seen[n] = true
						stack.append(n)
			out.append(cells)
	return out


# ─── 개체 ───────────────────────────────────────────────

func tile_pos(e: Dictionary) -> Vector2:
	return Vector2(float(e.get("x", 0)), float(e.get("y", 0))) * T


func _spawn_entity(e: Dictionary, index: int) -> void:
	var t := String(e.get("t", ""))
	var eid := String(e.get("id", "%s_%d" % [t, index]))
	match t:
		"exit":
			var x := RoomExit.new()
			x.setup(self, e, eid)
			_entities.add_child(x)
			exits[eid] = x
		"door":
			var dr := RoomDoor.new()
			dr.setup(self, e, eid)
			_entities.add_child(dr)
			doors[eid] = dr
		"spawn":
			markers[eid] = tile_pos(e) + Vector2(8, 0)
		"save":
			var sp := SavePoint.new()
			sp.setup(self, e, eid)
			_entities.add_child(sp)
			saves[eid] = sp
		"trigger":
			var tr := StoryTrigger.new()
			tr.setup(self, e, eid)
			_entities.add_child(tr)
		"sign":
			var sg := Readable.new()
			sg.setup(self, e, eid)
			_entities.add_child(sg)
		"light":
			_entities.add_child(LightGlow.make(tile_pos(e) + Vector2(8, 8), float(e.get("r", 3.0)) * T, e.get("color", theme.accent)))
		"prop":
			var p := Prop.new()
			p.setup(self, e)
			(_front if bool(e.get("front", false)) else _entities).add_child(p)
		"pickup":
			if GameState.is_collected(eid):
				return
			var pk := Pickup.new()
			pk.setup(self, e, eid)
			_entities.add_child(pk)
		"brazier":
			var bz := Brazier.new()
			bz.setup(self, e, eid)
			_entities.add_child(bz)
		"gate":
			var g := FlagGate.new()
			g.setup(self, e, eid)
			_entities.add_child(g)
		"npc":
			var n := Npc.new()
			n.setup(self, e, eid)
			_entities.add_child(n)
			actors[String(e.get("who", eid))] = n
		"enemy":
			_spawn_enemy(e, eid)
		_:
			var custom := WorldEntities.make(t, self, e, eid)
			if custom:
				_entities.add_child(custom)
				if custom.has_method("actor_id"):
					actors[custom.actor_id()] = custom
			else:
				push_warning("unknown entity type %s in %s" % [t, data.id])


func _spawn_enemy(e: Dictionary, eid: String) -> void:
	var uid := data.id + ":" + eid
	if GameState.is_killed(uid):
		return
	var kind := String(e.get("kind", "charger"))
	var en: EnemyBase = EnemyRegistry.create(kind)
	if en == null:
		push_warning("unknown enemy kind %s" % kind)
		return
	en.position = tile_pos(e) + Vector2(8, 0)
	en.facing = -1 if String(e.get("face", "left")) == "left" else 1
	en.uid = uid
	for k in e:
		if k in ["t", "id", "x", "y", "kind", "face", "cond"]:
			continue
		if k in en:
			en.set(k, e[k])
	_entities.add_child(en)
	enemies.append(en)


func add_entity(n: Node) -> void:
	_entities.add_child(n)


## 등장 위치 찾기: 표식 → 출구 → 문 → 기록 지점 순
func spawn_point(id: String) -> Dictionary:
	if markers.has(id):
		return {"pos": markers[id], "face": 1}
	if exits.has(id):
		return exits[id].arrival()
	if doors.has(id):
		return {"pos": doors[id].global_position, "face": 1}
	if saves.has(id):
		return {"pos": saves[id].global_position + Vector2(-14, 0), "face": 1}
	# 못 찾으면 방 왼쪽 바닥
	return {"pos": Vector2(3 * T, (data.row_count() - 3) * T), "face": 1}
