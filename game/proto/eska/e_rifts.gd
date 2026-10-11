class_name ERifts
extends RefCounted
## 열린 틈 등록부 — 「틈 달이기」(docs/eska/loop2_plan.md 2장).
## 고급 마법·대마법 연출이 공간을 찢을 때 그 모양(점들)을 여기 등록한다. 던진 물약은 at()으로 열린 틈을 찾아 infuse()로 스며든다.
## 틈 = {"id": 번호, "pts": 점들(전역), "w": 굵기, "until": 닫히는 시각(ms)}
## (틀: 기본 동작만 — 연출은 마법 담당 작업자가 채운다)

static var _list: Array[Dictionary] = []
static var _next_id := 1


## 열린 틈 하나 등록 (life초 동안 열려 있음). 번호를 돌려준다
static func open(pts: PackedVector2Array, width: float, life: float) -> int:
	_prune()
	var id := _next_id
	_next_id += 1
	_list.append({"id": id, "pts": pts, "w": width, "until": Time.get_ticks_msec() + int(life * 1000.0)})
	return id


## pos에서 radius 안에 있는 열린 틈 하나 (없으면 {})
static func at(pos: Vector2, radius: float) -> Dictionary:
	_prune()
	for r: Dictionary in _list:
		var pts: PackedVector2Array = r.pts
		for i in pts.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(pos, pts[i], pts[i + 1])
			if q.distance_to(pos) <= radius + float(r.w) * 0.5:
				return r
	return {}


## 물약이 틈에 스며드는 연출 (틀: 아무것도 그리지 않음)
static func infuse(_rift: Dictionary, _potion_id: String, _color: Color) -> void:
	pass


## 틈을 sec초 더 열어 둠 (흐린 물)
static func extend(rift: Dictionary, sec: float) -> void:
	if rift.has("until"):
		rift["until"] = int(rift.until) + int(sec * 1000.0)


static func _prune() -> void:
	var now := Time.get_ticks_msec()
	_list = _list.filter(func(r: Dictionary) -> bool: return int(r.until) > now)
