class_name EPotions
extends RefCounted
## 에스카 물약: 재료·조합표·물약 자료 + 허리띠(3칸) + 마시기·던지기. 기준서: docs/eska/design.md 4장.
## 에스카(EEska)는 belt를 하나 들고, F(+↑/↓)를 누르면 EPotions.use(eska, 칸 번호)를 부른다.
## 마시기·던지기 동작 시간은 eska.start_item(...)으로 맡긴다. 쓰러지거나 가마솥에 들르면 belt.refill().


## 허리띠: 칸 3개. 칸 = {"id": 물약 id ("" = 빈 칸), "left": 남은 병, "max": 가득일 때 병, "strong": 진한 물약인가}
class Belt extends RefCounted:
	var slots: Array = [{}, {}, {}]

	func refill() -> void:
		for s: Dictionary in slots:
			if s.has("max"):
				s["left"] = s["max"]


## 칸 번호(0 없음 · 1 ↑ · 2 ↓)의 물약을 쓴다. 썼으면 true
static func use(_eska: EEska, _slot: int) -> bool:
	return false # 틀만 — 담당 작업자가 채운다
