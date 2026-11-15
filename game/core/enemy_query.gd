class_name EnemyQuery
extends RefCounted
## 공용 "적 찾기" — 그룹(기본 enemy)을 돌며 살아 있는 것 중에서 고른다.
## 기존 루프와 결과가 같도록: 그룹 순서대로 보고, 거리가 같으면 먼저 나온 것이 이긴다(엄격한 `<`).
## 쓰는 곳: 세라(불기둥 조준·불씨), 동료 대상 고르기, 여우 효과(여우불·여우비·구미호 폭풍·변신·해제 폭발).


## metric(e) → 거리(작을수록 가깝다). INF를 돌려주면 후보에서 뺀다.
## limit보다 가까운 것만 고른다(limit = 처음 기준 거리). 없으면 null.
static func nearest(tree: SceneTree, metric: Callable, limit := INF, group: StringName = GameConst.GROUP_ENEMY) -> Node2D:
	var best: Node2D = null
	var best_d := limit
	for e in tree.get_nodes_in_group(group):
		if not e.is_alive():
			continue
		var d: float = metric.call(e)
		if d < best_d:
			best_d = d
			best = e
	return best


## 살아 있고 pred(e)가 참인 것마다 fn(e)를 부른다.
## 하나씩 확인하며 부르므로, 앞의 타격으로 죽은 적은 건너뛴다(기존 "돌면서 때리는" 루프와 같다).
static func within(tree: SceneTree, pred: Callable, fn: Callable, group: StringName = GameConst.GROUP_ENEMY) -> void:
	for e in tree.get_nodes_in_group(group):
		if e.is_alive() and pred.call(e):
			fn.call(e)
