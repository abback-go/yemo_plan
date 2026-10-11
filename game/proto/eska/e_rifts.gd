class_name ERifts
extends RefCounted
## 열린 틈 등록부 — 「틈 달이기」(docs/eska/loop2_plan.md 2장).
## 고급 마법·대마법 연출(천열·단공 참격, 낙성, 흑성·유성우·종말의 운석)이 공간을 찢을 때 그 모양(점들)을 여기 등록한다.
## 던진 물약은 at()으로 열린 틈을 찾아 infuse()로 스며든다. 틈 = {"id": 번호, "pts": 점들(전역), "w": 굵기, "until": 닫히는 시각(ms)}
## 시각은 이 등록부의 시계(now_ms — 게임 시간: 히트스톱·멈춤에 같이 느려짐)로 잰다. 연출 노드는 left(id)를 보고 그때 꿰매기 시작하므로
## extend()로 늘리면 그림도 그만큼 더 열려 있다. close(id)는 바로 닫기(천열: 새 참격이 열리면 오래된 것부터 닫힘).
## 그림: 장면에 Layer 노드 하나 — 시계를 돌리고, 물약이 스며든 틈(infuse)을 모두 그린다.

const INFUSE_SEEP := 0.35 ## 물약 색이 틈 한쪽 끝에서 다른 끝까지 번지는 시간
const INFUSE_FLASH := 0.16 ## 병이 빨려 들어가는 섬광 시간
const INFUSE_FADE := 0.25 ## 틈이 닫힌 뒤 색이 사라지는 시간

static var _list: Array[Dictionary] = []
static var _next_id := 1
static var _now := 0.0 ## 등록부 시계 (ms, 게임 시간)
static var _layer: Layer


## 등록부 시계 (ms) — "until"과 같은 눈금
static func now_ms() -> int:
	return int(_now)


## 틈이 열린 뒤 지난 초 (게임 시계). "갓 찢긴 틈"(0.5초 안) 판단에 쓴다 — loop4_plan 4장
static func age(rift: Dictionary) -> float:
	return maxf(float(now_ms() - int(rift.get("born", now_ms()))) / 1000.0, 0.0)


## 열린 틈 하나 등록 (life초 동안 열려 있음). 번호를 돌려준다
static func open(pts: PackedVector2Array, width: float, life: float) -> int:
	_ensure_layer()
	_prune()
	var id := _next_id
	_next_id += 1
	_list.append({"id": id, "pts": pts, "w": width, "born": now_ms(), "until": now_ms() + int(life * 1000.0)})
	return id


## pos에서 radius 안에 있는 열린 틈 하나 (없으면 {}) — 가장 가까운 것. 돌려준 틈에 "near"(틈 위 가장 가까운 점, 전역)·"near_i"(마디 번호)를
## 적어 둔다 — infuse가 병이 닿은 그 자리에서 섬광을 내고 물듦을 퍼뜨린다
static func at(pos: Vector2, radius: float) -> Dictionary:
	if not _ensure_layer():
		return {}
	_prune()
	var best: Dictionary = {}
	var bd := INF
	var bq := Vector2.ZERO
	var bi := 0
	for r: Dictionary in _list:
		var pts: PackedVector2Array = r.pts
		for i in pts.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(pos, pts[i], pts[i + 1])
			var d := q.distance_to(pos) - float(r.w) * 0.5
			if d <= radius and d < bd:
				bd = d
				best = r
				bq = q
				bi = i
	if not best.is_empty():
		best["near"] = bq
		best["near_i"] = bi
	return best


## 번호로 찾기 (닫혔으면 {})
static func find(id: int) -> Dictionary:
	for r: Dictionary in _list:
		if int(r.id) == id:
			return r
	return {}


## 남은 열림 시간(초). 닫혔거나 없으면 0
static func left(id: int) -> float:
	var r := find(id)
	if r.is_empty():
		return 0.0
	return maxf(float(int(r.until) - now_ms()) / 1000.0, 0.0)


## 지금 바로 닫기 (연출 노드는 다음 프레임에 꿰매기 시작)
static func close(id: int) -> void:
	var r := find(id)
	if not r.is_empty():
		r["until"] = now_ms()


## 물약이 틈에 스며드는 연출 (틈 쪽만): 병이 빨려 드는 섬광 + 틈의 테가 물약 색으로 물듦 (가운데에서 양 끝으로, 틈이 닫히면 같이 사라짐).
## 효과가 퍼지는 그림(거미줄·독안개 등)과 효과 자체는 물약 쪽이 맡는다
static func infuse(rift: Dictionary, potion_id: String, color: Color) -> void:
	if rift.is_empty() or not _ensure_layer():
		return
	rift["potion"] = potion_id
	rift["color"] = color
	_layer.add_infusion(rift, color)


## 틈을 sec초 더 열어 둠 (흐린 물)
static func extend(rift: Dictionary, sec: float) -> void:
	if rift.has("until"):
		rift["until"] = int(rift.until) + int(sec * 1000.0)


static func _prune() -> void:
	var now := now_ms()
	_list = _list.filter(func(r: Dictionary) -> bool: return int(r.until) > now)


## 장면에 Layer가 있게 한다. 장면이 바뀌어 새로 만들었으면 지난 장면의 틈은 지운다. 장면이 없으면 false
static func _ensure_layer() -> bool:
	if is_instance_valid(_layer) and _layer.is_inside_tree():
		return true
	var parent := Fx.effect_parent()
	if parent == null or not parent.is_inside_tree():
		return false
	_list.clear()
	_layer = Layer.new()
	parent.add_child(_layer)
	return true


## 등록부 시계 + 물약이 스며든 틈 그림 (장면에 한 노드)
class Layer extends PDraw.Canvas:
	var items: Array = [] ## [틈, 색, 나이, 닫힌 뒤 나이]

	func _ready() -> void:
		z_index = 7 # 틈(6) 위에

	func add_infusion(rift: Dictionary, color: Color) -> void:
		items.append([rift, color, 0.0, 0.0])
		Sfx.play_pitch(&"es_infuse", randf_range(0.95, 1.05), -6.0)

	func _process(delta: float) -> void:
		ERifts._now += delta * 1000.0
		if items.is_empty():
			return
		queue_redraw() # 마지막 하나가 사라지는 프레임에도 한 번 더 그려 지운다
		var i := 0
		while i < items.size():
			var it: Array = items[i]
			it[2] = float(it[2]) + delta
			if ERifts.left(int((it[0] as Dictionary).id)) <= 0.0:
				it[3] = float(it[3]) + delta
				if float(it[3]) >= ERifts.INFUSE_FADE:
					items.remove_at(i)
					continue
			i += 1

	func _paint() -> void:
		for it: Array in items:
			var r: Dictionary = it[0]
			var col: Color = it[1]
			var age: float = it[2]
			var fade := 1.0 - clampf(float(it[3]) / ERifts.INFUSE_FADE, 0.0, 1.0)
			var pts: PackedVector2Array = r.pts
			var n := pts.size()
			if n < 2:
				continue
			var seep := clampf(age / ERifts.INFUSE_SEEP, 0.0, 1.0)
			var w := float(r.w)
			# 테가 물약 색으로 물듦: 병이 닿은 마디(없으면 가운데)에서 양 끝으로 (점마다 위아래 두 줄)
			var mid := float(r.get("near_i", (n - 1) * 0.5))
			var span := maxf(maxf(mid, float(n - 1) - mid), 0.5)
			for k in n - 1:
				var f := absf(float(k) + 0.5 - mid) / span
				if f > seep:
					continue
				var a := fade * (1.0 - 0.5 * f) * (0.75 + 0.25 * sin(age * 9.0 + float(k)))
				var d := (pts[k + 1] - pts[k])
				var o := d.orthogonal().normalized() * (w * 0.5 + 1.5)
				pd.draw_line(pts[k] + o, pts[k + 1] + o, Color(col, 0.9 * a), 2.0)
				pd.draw_line(pts[k] - o, pts[k + 1] - o, Color(col, 0.9 * a), 2.0)
			# 병이 빨려 드는 섬광 (가운데 점)
			if age < ERifts.INFUSE_FLASH:
				var c: Vector2 = r.get("near", pts[int(mid)])
				var e := age / ERifts.INFUSE_FLASH
				pd.glow(c, 18.0 * (1.0 - e) + 4.0, Color(col.lerp(Color.WHITE, 0.5), 0.9 * (1.0 - e)), 0.0)
				pd.draw_arc(c, 4.0 + 16.0 * (1.0 - e), 0.0, TAU, 16, Color(col, 1.0 - e), 1.5)
