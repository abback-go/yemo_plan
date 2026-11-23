## ease.gd — CSS 와 같은 이징(cubic-bezier). HTML 판 연출 곡선을 그대로 옮기려고 쓴다.
class_name Ease
extends RefCounted

const NAMED := {
	"linear": [0.0, 0.0, 1.0, 1.0],
	"ease": [0.25, 0.1, 0.25, 1.0],
	"ease-in": [0.42, 0.0, 1.0, 1.0],
	"ease-out": [0.0, 0.0, 0.58, 1.0],
	"ease-in-out": [0.42, 0.0, 0.58, 1.0],
}

static var _cache := {}


## spec: "linear" | "ease-out" | "cubic-bezier(.2,.7,.3,1)" | [x1,y1,x2,y2]
static func parse(spec) -> Array:
	if spec == null:
		return NAMED.linear
	if spec is Array:
		return spec
	var s := str(spec)
	if NAMED.has(s):
		return NAMED[s]
	if _cache.has(s):
		return _cache[s]
	var inner := s.replace("cubic-bezier(", "").replace(")", "")
	var parts := inner.split(",")
	var out := [float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3])]
	_cache[s] = out
	return out


static func _bz(t: float, a: float, b: float) -> float:
	# 시작 0, 끝 1, 제어점 a, b 인 3차 베지어
	var u := 1.0 - t
	return 3.0 * u * u * t * a + 3.0 * u * t * t * b + t * t * t


static func _dbz(t: float, a: float, b: float) -> float:
	var u := 1.0 - t
	return 3.0 * u * u * a + 6.0 * u * t * (b - a) + 3.0 * t * t * (1.0 - b)


## x(0~1) → y
static func apply(spec, x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	var c := parse(spec)
	if c[0] == 0.0 and c[1] == 0.0 and c[2] == 1.0 and c[3] == 1.0:
		return x
	# 뉴턴법으로 x → t
	var t := x
	for i in 8:
		var cx := _bz(t, c[0], c[2]) - x
		var d := _dbz(t, c[0], c[2])
		if absf(cx) < 1e-5:
			break
		if absf(d) < 1e-6:
			break
		t = clampf(t - cx / d, 0.0, 1.0)
	# 이분법 보정
	var cx2 := _bz(t, c[0], c[2])
	if absf(cx2 - x) > 1e-3:
		var lo := 0.0
		var hi := 1.0
		t = x
		for i in 30:
			var v := _bz(t, c[0], c[2])
			if absf(v - x) < 1e-5:
				break
			if v < x:
				lo = t
			else:
				hi = t
			t = (lo + hi) * 0.5
	return _bz(t, c[1], c[3])
