class_name Rewards
extends RefCounted
## 보상 지급 한 곳 (퀘스트 완료 · 대본 c.give_* · 인물 대화). 숫자를 올리는 일만 하고 알림 창은 부른 쪽이 띄운다.
##   Rewards.grant({stones = 2, potion_slot = 1, heart = 1, feather = 1, text = "덤 문구"}) -> 보상 문구 목록
## 최대 체력이 늘면 HUD·세라 체력이 바로 맞도록 세라의 restore_from_state()를 부른다 (restore = false면 생략).


## 사전 보상을 한꺼번에. 알림 창에 쓸 문구 목록을 돌려준다 (퀘스트 보상 형식: story/data_*.gd QUESTS의 reward)
static func grant(r: Dictionary, restore := true) -> Array:
	var out: Array = []
	var n_st := int(r.get("stones", 0))
	if n_st > 0:
		Spells.add_stones(n_st)
		out.append("마도석 %d개" % n_st)
	var n_pot := int(r.get("potion_slot", 0))
	if n_pot > 0:
		add_potion_slot(n_pot)
		out.append("물약 최대 +%d" % n_pot)
	var n_heart := int(r.get("heart", 0)) + int(r.get("feather", 0))
	if n_heart > 0:
		add_max_hp(n_heart, restore)
		out.append("최대 체력 +%d" % n_heart)
	var txt := String(r.get("text", ""))
	if txt != "":
		out.append(txt)
	return out


## 물약 칸 +n (물약도 가득)
static func add_potion_slot(n := 1) -> void:
	GameState.potions_max += n
	GameState.potions = GameState.potions_max


## 최대 체력 +n (체력도 가득)
static func add_max_hp(n := 1, restore := true) -> void:
	GameState.max_hp += n
	GameState.hp = GameState.max_hp
	if restore:
		var w := World.get_world()
		if w:
			w.player.restore_from_state()
