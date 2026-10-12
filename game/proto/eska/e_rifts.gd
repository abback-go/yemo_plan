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
const FRESH_FLASH := 0.5 ## 갓 찢긴 틈에 스몄을 때의 신호 전체 시간 (loop5_plan 2장 — 색이 아니라 모양으로)
const FRESH_STARS := 6 ## 그때 튀는 흰 별빛 수
## "마녀가 틈을 꿰맨다"(loop6_plan 4장): 흰 바느질 땀 STITCHES개가 STITCH_SEW초 동안 닿은 자리에서 양쪽으로 차례로 박히고,
## STITCH_HOLD까지 머물렀다 사라진다. 땀은 틈을 비스듬히 가로지르는 STITCH_LEN px 흰 선(검은 테) — 흡수 고리(반지름 약 20) 바깥부터
const STITCHES := 10
const STITCH_SEW := 0.2
const STITCH_HOLD := 0.38
const STITCH_LEN := 8.0
const STITCH_FROM := 24.0 ## 닿은 자리에서 첫 땀까지 (흡수 고리 바깥)
const STITCH_GAP := 9.0 ## 땀 사이 간격 (틈 길이 따라)
const QUIET_EDGE := "rot" ## 이 물약은 테 물듦 선을 아주 옅게 (부식은 물약 쪽 독안개가 퍼지므로 가는 초록 선이 남아 보이지 않게)
const QUIET_A := 0.0 ## 그때 테 선 진하기 (루프6: 아예 끔 — 부식은 물약 쪽 안개·방울이 신호)
const EDGE_HOLD := 0.5 ## 물약 색 테 선이 그대로 있는 시간 — 물약 쪽 실(1초)과 맞춰 1초 안에 사라짐 (loop6)
const EDGE_FADE := 0.45 ## 그 뒤 흐려지는 시간

static var _list: Array[Dictionary] = []
static var _next_id := 1
static var _now := 0.0 ## 등록부 시계 (ms, 게임 시간)
static var _layer: Layer
static var _cast_born := {} ## 시전 번호 → 그 시전의 첫 틈이 열린 시각 (한 시전의 틈들은 나이를 같이 셈)
static var _next_cast := 1


## 등록부 시계 (ms) — "until"과 같은 눈금
static func now_ms() -> int:
	return int(_now)


## 틈이 열린 뒤 지난 초 (게임 시계). "갓 찢긴 틈"(0.5초 안) 판단에 쓴다 — loop4_plan 4장.
## 같은 시전(cast_id)의 틈들은 그 시전의 첫 틈이 열린 시각을 born으로 같이 쓴다 (천열 10장이 창을 늘리지 않게 — loop5_plan 2장)
static func age(rift: Dictionary) -> float:
	return maxf(float(now_ms() - int(rift.get("born", now_ms()))) / 1000.0, 0.0)


## 새 시전 번호 (open의 cast_id로 — 한 시전의 틈들이 나이를 같이 셈)
static func new_cast() -> int:
	var c := _next_cast
	_next_cast += 1
	if _cast_born.size() > 64: # 오래된 시전은 잊음 (틈이 다 닫혔을 만큼 지난 것)
		var now := now_ms()
		for k: int in _cast_born.keys():
			if now - int(_cast_born[k]) > 10000:
				_cast_born.erase(k)
	return c


## 열린 틈 하나 등록 (life초 동안 열려 있음). 번호를 돌려준다.
## cast_id가 0이 아니면 같은 번호의 틈들은 그 시전의 첫 틈이 열린 시각을 born으로 공유한다 (new_cast로 받음).
## born_in = 등록보다 이만큼 뒤를 "열린 순간"으로 (천열·단공: 참격이 나오는 순간 등록하지만 열린 순간은 첫 판정 시각)
static func open(pts: PackedVector2Array, width: float, life: float, cast_id := 0, born_in := 0.0) -> int:
	_ensure_layer()
	_prune()
	var id := _next_id
	_next_id += 1
	var born := now_ms() + int(born_in * 1000.0)
	if cast_id != 0:
		born = int(_cast_born.get(cast_id, born))
		_cast_born[cast_id] = born
	_list.append({"id": id, "pts": pts, "w": width, "born": born, "cast": cast_id, "until": now_ms() + int(life * 1000.0)})
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
## 갓 찢긴 틈(age < EPotions.RIFT_FRESH)이면 물약 색과 상관없이 흰 꿰맴 선이 가장자리를 한 번 훑고 흰 별빛이 튄다 (모양으로 구별).
## 효과가 퍼지는 그림(거미줄·독안개 등, 금빛 섬광)과 효과 자체는 물약 쪽이 맡는다
static func infuse(rift: Dictionary, potion_id: String, color: Color) -> void:
	if rift.is_empty() or not _ensure_layer():
		return
	rift["potion"] = potion_id
	rift["color"] = color
	_layer.add_infusion(rift, color, age(rift) < EPotions.RIFT_FRESH, potion_id.begins_with(QUIET_EDGE))


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
	var items: Array = [] ## [틈, 색, 나이, 닫힌 뒤 나이, 갓 찢긴 틈인가, 테 선을 옅게, 바느질 땀들 [가운데, 가로지르는 방향(길이 포함)]]

	func _ready() -> void:
		z_index = 7 # 틈(6) 위에

	func add_infusion(rift: Dictionary, color: Color, fresh := false, quiet := false) -> void:
		items.append([rift, color, 0.0, 0.0, fresh, quiet, _stitches(rift) if fresh else []])
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
			if float(it[2]) >= ERifts.EDGE_HOLD + ERifts.EDGE_FADE and float(it[2]) >= ERifts.FRESH_FLASH: # 다 사라졌으면 그만 그림
				items.remove_at(i)
				continue
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
			var edge_a := fade * (1.0 - clampf((age - ERifts.EDGE_HOLD) / ERifts.EDGE_FADE, 0.0, 1.0)) * (ERifts.QUIET_A if bool(it[5]) else 1.0)
			var w := float(r.w)
			# 테가 물약 색으로 물듦: 병이 닿은 마디(없으면 가운데)에서 양 끝으로 (점마다 위아래 두 줄)
			var mid := float(r.get("near_i", (n - 1) * 0.5))
			var span := maxf(maxf(mid, float(n - 1) - mid), 0.5)
			for k in n - 1:
				var f := absf(float(k) + 0.5 - mid) / span
				if f > seep:
					continue
				var a := edge_a * (1.0 - 0.5 * f) * (0.75 + 0.25 * sin(age * 9.0 + float(k)))
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
			if bool(it[4]) and age < ERifts.FRESH_FLASH:
				_paint_fresh(r, it[6], age, mid)

	## 바느질 땀 자리: 닿은 자리에서 틈 길이를 따라 양쪽으로 번갈아 (STITCH_FROM부터 STITCH_GAP마다), 박히는 순서대로
	func _stitches(r: Dictionary) -> Array:
		var pts: PackedVector2Array = r.pts
		var n := pts.size()
		if n < 2:
			return []
		var cum := PackedFloat32Array([0.0]) # 점마다 틈 길이
		for k in n - 1:
			cum.append(cum[k] + pts[k].distance_to(pts[k + 1]))
		var near: Vector2 = r.get("near", pts[n / 2])
		var ni := clampi(int(r.get("near_i", n / 2)), 0, n - 2)
		var s0 := cum[ni] + pts[ni].distance_to(near)
		var across := clampf(float(r.w) + 4.0, ERifts.STITCH_LEN, 16.0)
		var out := []
		var step := 0
		while out.size() < ERifts.STITCHES and step < ERifts.STITCHES * 3:
			var side := 1.0 if step % 2 == 0 else -1.0
			var sd := s0 + side * (ERifts.STITCH_FROM + ERifts.STITCH_GAP * float(step / 2))
			step += 1
			if sd < 0.0 or sd > cum[n - 1]:
				continue
			var k := 0
			while k < n - 2 and cum[k + 1] < sd:
				k += 1
			var seg := maxf(cum[k + 1] - cum[k], 0.001)
			var c := pts[k].lerp(pts[k + 1], (sd - cum[k]) / seg)
			var t := (pts[k + 1] - pts[k]) / seg
			out.append([c, (t.orthogonal() + t * 0.45).normalized() * across])
		return out

	## 갓 찢긴 틈의 신호: 흰 바느질 땀이 차례로 박힘(툭 커졌다 자리 잡음) + 닿은 자리에서 흰 별빛이 튐 — 물약 색과 상관없이 읽히게 검은 테
	func _paint_fresh(r: Dictionary, st: Array, age: float, mid: float) -> void:
		var pts: PackedVector2Array = r.pts
		var fade := 1.0 - clampf((age - ERifts.STITCH_HOLD) / (ERifts.FRESH_FLASH - ERifts.STITCH_HOLD), 0.0, 1.0)
		for i in st.size():
			var at := ERifts.STITCH_SEW * float(i) / float(maxi(st.size() - 1, 1))
			if age < at:
				break
			var k := clampf((age - at) / 0.05, 0.0, 1.0)
			var c: Vector2 = st[i][0]
			var d: Vector2 = st[i][1] * (0.5 * (1.0 + 0.35 * (1.0 - k))) # 박힐 때 살짝 길었다 자리 잡음
			pd.draw_line(c - d, c + d, Color(EVfx.INK, 0.85 * fade), 3.0)
			pd.draw_line(c - d, c + d, Color(Color.WHITE, fade), 1.5)
			if k < 1.0:
				pd.draw_rect(Rect2(c - Vector2(1.5, 1.5), Vector2(3, 3)), Color(Color.WHITE, (1.0 - k) * fade)) # 바늘이 꽂히는 반짝임
		var e := clampf(age / ERifts.FRESH_FLASH, 0.0, 1.0)
		var a := 1.0 - e * e
		var c0: Vector2 = r.get("near", pts[clampi(int(mid), 0, pts.size() - 1)])
		var e2 := 1.0 - pow(1.0 - e, 2.0)
		for i in ERifts.FRESH_STARS:
			var dir := Vector2.from_angle(float(i) * TAU / float(ERifts.FRESH_STARS) + 0.4)
			EVfx.star4(pd, c0 + dir * (22.0 + 20.0 * e2), 4.0 * (1.0 - e) + 1.5, e * 3.0, Color(Color.WHITE, a), Color(EVfx.PALE, 0.35 * a))
