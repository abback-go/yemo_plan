extends RefCounted
## 4장 지역 배경 (RoomBackdrop가 부름). 1장 room_backdrop.gd의 층 그림을 참고.


static func is_animated(_theme: String, _depth: int) -> bool:
	return false


static func has_sky(_theme: String) -> bool:
	return false


## 화면 고정 하늘 (640×360)
static func draw_sky(_c: Control, _theme: String, _pal: Dictionary, _t: float) -> void:
	pass


## 시차 층. depth 0 먼 · 1 중간 · 2 가까운 · 3 전경. 이 장 테마면 그리고 true
static func draw_layer(_l: Node2D, _theme: String, _depth: int, _span: Vector2, _rng: RandomNumberGenerator, _t: float) -> bool:
	return false
