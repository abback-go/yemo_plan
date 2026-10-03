extends RefCounted
## 4장 소품 그림 (Prop이 1장 목록에 없는 kind를 여기로 넘김)


## 빛·움직임 정보: {animated, glow_pos, glow_r, glow_col} — 이 장 소품이 아니면 {}
static func setup_info(_kind: String, _p: Prop) -> Dictionary:
	return {}


## 그렸으면 true
static func draw(_p: Prop, _kind: String) -> bool:
	return false
