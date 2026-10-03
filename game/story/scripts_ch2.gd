extends RefCounted
## 2장 대본 (docs/chapter2.md). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 1단계(지금)는 시험용 dev_ch2_* 대본만 있다. 실제 장 대본은 2단계에서 docs/chapter2.md 7.5절 대본 목록대로 쓴다.


# ─── 개발·시험용 (게임 안에서는 부르지 않음) ────────────

## 초상화 표정 견본 (tools/test/scenarios/ch2_portraits.json)
func dev_ch2_portrait(c: Cut) -> void:
	await c.say("leonie", "황도 아르덴에 온 걸 환영한다고는 하지 않겠다.", "normal")
	await c.say("leonie", "여긴 마녀 놀이터가 아니다.", "stern")
	await c.say("leonie", "…나쁘지 않군.", "happy")
	await c.say("leonie", "물러서라. 두 번 말하지 않는다.", "angry")
	await c.say("leonie", "나는 마력이 없다. 그래서 '무력(無力)'이라 불렸지.", "sad")
	await c.say("leonie", "…그 불이, 사람을 감쌌다고?", "surprised")
	await c.say("noxis", "어서 오십시오, 별에 이끌린 아이여.", "normal")
	await c.say("noxis", "후후후… 그분은 소문 하나로 별을 움직이시지.", "happy")
	await c.say("noxis", "보이십니까? 별 너머의 눈이 이쪽을 보고 계십니다!", "zeal")
	await c.say("noxis", "감히… 성스러운 의식을!", "angry")
	await c.say("kael", "단장님! 아, 아니, 마녀님들! 어서 오세요! 은사자 기사단 부단장 카엘입니다!", "happy")
	await c.say("mia", "레오니 단장님이 또 짐승을 한 칼에 베셨대요! 진짜예요!", "happy")
	await c.say("bron", "…검은 주인을 닮는다. 쓸데없이 반짝이는 건 질색이야.", "normal")


## 방의 살아 있는 적 모두에게 "되쏜 탄"(Hit.kind = reflect) 한 발 — 불꽃 방벽이 아직 없을 때 별 수정 방패·갑피 시험용
func dev_ch2_reflect(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en and en.is_alive():
			var h := Hit.make(150, &"reflect", c.player.center())
			h.hitstop = 0.05
			h.shake_t = 0.1
			en.take_hit(h)
			print("DEV reflect -> ", en.kind_id, " hp=", en.hp)


## 운석수를 4초 경직 (동료 레오니의 "다리를 벤다!"를 흉내)
func dev_ch2_stagger(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if e.has_method("stagger"):
			e.call("stagger", 4.0)
			print("DEV stagger -> ", (e as EnemyBase).kind_id)


## 동료 공격(Hit.kind = ally) 한 대 — 강자 보스의 막기 반응 시험용
func dev_ch2_ally_hit(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en and en.is_alive():
			en.take_hit(Hit.make(80, &"ally", en.global_position + Vector2(-30, -10)))
			print("DEV ally -> ", en.kind_id, " hp=", en.hp)


## 운석수의 큰 일격(브로치 장면용) 시험
func dev_ch2_ultimate(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if e.has_method("ultimate"):
			e.call("ultimate")
			print("DEV ultimate -> ", (e as EnemyBase).kind_id)


## 적 상태 출력 (시나리오 로그용)
func dev_ch2_info(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en:
			var extra := ""
			for k in ["hits_taken", "result", "phase", "shield_up", "carapace", "fled", "state_name"]:
				if k in en:
					extra += " %s=%s" % [k, str(en.get(k))]
			print("DEV info ", en.kind_id, " hp=", en.hp, "/", en.max_hp, " alive=", en.is_alive(), extra)
