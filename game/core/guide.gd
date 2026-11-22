## guide.gd — 튜토리얼 안내 트리거 (HTML 판 dialog.js 의 Guide). 대본 script_data.gd "guide" 에서 조건에 맞는 줄을 골라 대사창으로.
## 안내 상자(system) 줄은 DialogBox 가 '한 번만' 거른다(다시 하기 후에도). 캐릭터 대사 묶음은 once 일 때만 한 판에 한 번.
class_name Guide
extends Node

var done := {}


func reset() -> void:
	done = {}


## ctx: {enc, turn, card, explore, v2}. 반환을 await 하면 모두 보여 줄 때까지 기다린다
## v2: 새 전투(3D 탁자, scenes/board_battle.gd 게임 모드)의 안내 — script_data.gd "guideV2". linesOf: 그 옛 안내(guide)의 줄(대본 v3 대사)을 앞에 그대로
func fire(on: String, ctx := {}) -> void:
	var st: Dictionary = G.ctl.st
	var out := []
	# 새 턴이 시작되면 아직 못 읽은 지난 대사는 버린다(밀려서 늦게 나오지 않게)
	if on == "turnStart":
		G.dialog.drop_pending()
	var list: Array = G.S.get("guideV2", []) if bool(ctx.get("v2", false)) else G.S.guide
	for g in list:
		if g.on != on:
			continue
		if g.has("enc") and g.enc != ctx.get("enc"):
			continue
		if g.has("turn") and int(g.turn) != int(ctx.get("turn", -1)):
			continue
		if g.has("card") and g.card != ctx.get("card"):
			continue
		if g.has("explore") and g.explore != ctx.get("explore"):
			continue
		if g.get("once", false) and done.has(g.id):
			continue
		done[g.id] = true
		var lines: Array = g.get("lines", [])
		if g.has("linesOf"):
			for g1 in G.S.guide:
				if g1.id == g.linesOf:
					var l1: Array = g1.lines.filter(func(x): return str(x.get("who", "")) != "system") if g.get("skipSystem", false) else g1.lines
					lines = l1 + lines
		for ln in lines:
			var a = st.party.allies.get(ln.who) if not st.is_empty() else null
			if a != null and a.status == "dead":
				continue   # 죽은 동료는 말하지 않는다
			out.append(ln)
	if out.is_empty():
		return
	await G.dialog.say(out)
