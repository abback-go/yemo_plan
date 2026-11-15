class_name ETarget
extends RefCounted
## 에스카가 벨 수 있는 것들(허수아비 PDummy · 적 EEnemy)의 공통 약속.
## 둘 다 PDummy.GROUP 그룹에 들고, 다음을 가진다:
##   hit_rect() -> Rect2 · center() -> Vector2 · take_hit(dmg, from, opts) · bind(sec, awake, fox, style) · unbind()
## 판정 코드는 종류를 묻지 않고 이 목록만 돈다.


static func all(tree: SceneTree) -> Array:
	return tree.get_nodes_in_group(PDummy.GROUP)


## 살아 있는(벨 수 있는) 것만
static func alive(tree: SceneTree) -> Array:
	return all(tree).filter(func(n: Node) -> bool: return not n.has_method("is_dead") or not n.is_dead())
