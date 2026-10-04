class_name Cond
extends RefCounted
## 진행 조건식 하나 (목표 req · 퀘스트 need · 수업 unlock · 방 개체 cond/on_if/open_if …가 모두 이것을 쓴다).
## 문법 (docs/dev/story.md "조건식"):
##   ""                 항상 참
##   "k_spar_done"      플래그가 섰다
##   "!k_beast_down"    플래그가 서지 않았다
##   "a,b,!c"           쉼표 = 그리고 (모두 참이어야 참). 공백은 무시
##   "mana>=6"          지금까지 모은 마도석(mana_total)이 6 이상. "!mana>=6"은 그 반대
## 이름 바꾸기·문법 추가는 tools/story_lint.py의 해석(cond_flags)도 같이 고칠 것.


static func ok(expr: String) -> bool:
	if expr == "":
		return true
	for tok in expr.split(","):
		var t := tok.strip_edges()
		if t == "":
			continue
		var neg := t.begins_with("!")
		if neg:
			t = t.substr(1)
		if _term(t) == neg:
			return false
	return true


## 낱말 하나 (부정 없이)
static func _term(t: String) -> bool:
	if t.begins_with("mana>="):
		return int(GameState.flag("mana_total", 0)) >= int(t.substr(6))
	return GameState.has_flag(t)
