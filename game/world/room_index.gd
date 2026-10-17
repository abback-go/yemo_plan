class_name RoomIndex
extends RefCounted
## 모든 방의 메타 색인 (지도 화면·HUD 미니맵용). tools/roomgen.py가 방을 만들 때 함께 쓰는
## res://world/rooms/_index.gd 의 ROOMS(방 ID → 제목·지역·지도 칸·기록 지점)를 읽는다.
## 예전에는 방 스크립트(지형·개체 전체)를 165개 모두 불러와 지도 정보만 봤다 — 첫 미니맵 프레임이 약 1초 멈췄다.
## 방 목록도 색인에서 나온다(ID가 dev_로 시작하는 개발용 방은 뺌) → 방을 추가할 때 손으로 고칠 ROOMS 목록이 없다.

const INDEX := preload("res://world/rooms/_index.gd")

static var _cache := {}
static var _all: Array = []


## 지도에 나오는 모든 방 ID (색인 순서 = 1장 → sys → ch2 → … , 장 안에서는 tools/rooms/*.py에 적은 순서)
static func all() -> Array:
	if _all.is_empty():
		for id in INDEX.ROOMS:
			if not bool(INDEX.ROOMS[id].dev):
				_all.append(id)
	return _all


## 색인 한 줄: {title, area, theme, music, cell, cells, dark, saves(기록 지점 ID들), dev, src(정의한 곳)}. 없으면 빈 사전
static func info(id: String) -> Dictionary:
	return INDEX.ROOMS.get(id, {})


static func has(id: String) -> bool:
	return INDEX.ROOMS.has(id)


## 지도용 가벼운 RoomData: id·title·area·theme·music·cell·cells·dark와, entities에는 기록 지점(t = "save")만 들어 있다.
## 지형(map)과 다른 개체가 필요하면 load_full(id). 결과는 캐시해 같은 객체를 돌려준다(고치지 말 것).
static func data(id: String) -> RoomData:
	if _cache.has(id):
		return _cache[id]
	var row := info(id)
	if row.is_empty():
		return null
	var d := RoomData.new()
	d.id = id
	d.title = row.title
	d.area = row.area
	d.theme = row.theme
	d.music = row.music
	d.cell = row.cell
	d.cells = row.cells
	d.dark = row.dark
	for sid in row.saves:
		d.entities.append({"t": "save", "id": sid})
	_cache[id] = d
	return d


## 방 전체 데이터 (방 스크립트를 불러와 새로 만든다 — 매번 새 객체). 없는 방이면 null
static func load_full(id: String) -> RoomData:
	var path := "res://world/rooms/%s.gd" % id
	if not ResourceLoader.exists(path):
		return null
	return (load(path) as GDScript).new()
