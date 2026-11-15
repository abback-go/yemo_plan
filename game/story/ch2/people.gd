extends "res://story/ch2/common.gd"
## 2장 대본 — 10~11. 투기장(가론) · 제국 인물 대화·서브 퀘스트 · 거리 사람들.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 10. 투기장 (서브: 챔피언 가론)
# ═══════════════════════════════════════════════════════════

func npc_k_arena_master(c: Cut) -> void:
	var q := Quests.state("k_arena")
	if q == 0 and c.has("k_spar_done"):
		await c.say("k_arena_master", "오오! 마녀님이시라! 단장님과 대련해서 일 분을 버텼다는 그 마녀님!", "happy")
		await c.say("k_arena_master", "우리 챔피언 '그물의 가론'과 한판 어떻소? 관중들이 좋아 죽을 거요. 이기면 수호의 깃털을 드리지!")
		var i := await c.choose("k_arena_master", "도전하시겠소?", ["도전한다", "다음에"])
		if i == 0:
			c.quest_start("k_arena")
			c.flag("k_arena_ok")
			await c.say("k_arena_master", "좋소! 오른쪽 계단으로 내려가시오. 가론! 손님이다!", "happy")
		else:
			await c.say("k_arena_master", "언제든 오시오. 투기장 문은 도전자에게 늘 열려 있소!")
	elif q == 1 and c.has("k_arena_won"):
		await c.say("k_arena_master", "들었소, 그 함성! 십 년 만에 가론이 졌어! 약속한 수호의 깃털이오!", "happy")
		c.close_box()
		await c.quest_done("k_arena")
		await c.say("k_arena_master", "다음 시즌 포스터에 마녀님 얼굴을 넣어도 되겠소? …안 된다고? 아쉽군.")
	elif q == 1:
		await c.say("k_arena_master", "가론이 바닥에서 기다리오. 그물을 조심하시오! 환호를 받기 시작하면 — 끊어 버리시오!")
	elif q == 2:
		await c.say("k_arena_master", "챔피언 마녀님! 언제든 환영이오!", "happy")
	else:
		await c.say("k_arena_master", "투기장은 지금 기사단 행사 준비 중이오. 단장님과 인사부터 하고 오시오.")


func npc_garon(c: Cut) -> void:
	if c.has("k_arena_won"):
		await c.say("garon", "오, 마녀 챔피언! 그날 관중 함성, 아직도 귀가 울린다! 하하하!", "happy")
		await c.say("garon", "다음엔 그물을 두 개 들고 나가겠다. 각오해라!")
	else:
		await c.say("garon", "나는 가론! 그물과 삼지창, 그리고 관중의 사랑으로 싸우지!", "happy")
		await c.say("garon", "환호를 받으면 힘이 솟거든. 그걸 끊을 수 있는 놈은 지금까지 없었다!")


func npc_k_arena_fan(c: Cut) -> void:
	await c.say("k_citizen_c", "가론은 관중이 소리를 지르면 더 세져요! 팔을 들고 환호를 받을 때 때려야 해요. …아, 이건 비밀인데.")


func k_arena_fight(c: Cut) -> void:
	if c.has("k_arena_won") or not c.has("k_arena_ok"):
		return
	c.lock()
	c.sfx("crowd", 4.0)
	await c.player_walk(24.0)
	c.player_face(1)
	var g := c.spawn_enemy("gladiator", 62.0, 19.0, "garon", {"engaged": false, "respawns": true})
	if g == null:
		c.flag("k_arena_won")
		return
	g.facing = -1
	await c.say("garon", "오오! 마녀 도전자라니! 관중들이여, 함성을!", "happy")
	c.sfx("crowd", 6.0)
	await c.say("garon", "그물의 가론이다! 오늘도 멋지게 묶어 주지!")
	c.close_box()
	await c.title_card("투기장", "챔피언 · 그물의 가론", 1.4)
	c.music("boss", 0.3)
	g.engaged = true
	c.release()
	await c.wait_enemy(g)
	if not c.ok():
		return
	c.lock()
	c.sfx("crowd", 6.0)
	await c.wait(1.2)
	c.music("kingdom", 1.0)
	c.spawn_npc("garon", 62.0, 19.0, -1)
	await c.say("garon", "하하하! 졌다, 졌어! 오랜만에 관중이 진짜로 소리를 질렀군!", "happy")
	await c.say("garon", "지배인한테 가 봐라. 깃털이 기다린다!")
	c.close_box()
	c.flag("k_arena_won")
	c.quest_step("k_arena", 1)
	c.save()


# ═══════════════════════════════════════════════════════════
# 11. 제국 인물 대화 (+ 서브 퀘스트)
# ═══════════════════════════════════════════════════════════

func npc_leonie(c: Cut) -> void:
	match _room(c):
		"k_knights_yard":
			if not c.has("k_spar_done"):
				await c.call_script("k_spar")
				return
		"k_walls":
			if not c.has("k_walls_talk"):
				await c.call_script("k_walls_talk")
				return
		"k_palace_plaza":
			if not c.has("k_duel_done"):
				await c.call_script("k_duel")
				return
	if c.has("k_beast_down"):
		await c.say("leonie", "세라. 왔나.", "happy")
		if Quests.done("k_bron_ore"):
			await c.say("leonie", "브론이 새 검을 벼려 줬다. 누가 별철을 구해다 줬는지는 끝내 말을 안 하더군.")
			await c.say("leonie", "…네 짓이로군. 고맙다. 이 검은 오래 쓰겠다.", "happy")
		else:
			await c.say("leonie", "검은 언젠가 부러진다. 그 전에 지킬 것을 지키면 된다.")
			await c.say("leonie", "…브론 녀석이 별철 타령을 하던데. 시간이 나면 들어 줘라. 나한테는 말을 안 하니까.")
	else:
		await c.say("leonie", "할 일이 남았다. 가라.")


func npc_kael(c: Cut) -> void:
	if _deliver_bread(c, "kael"):
		await c.say("kael", "미아네 빵! 사자 머리 빵이다! …어, 단장님 크림빵은 없어요? 아, 없구나. 다행이다. 아니, 아쉽다!", "happy")
		return
	var q := Quests.state("k_kael_helmet")
	if q == 1 and c.has("k_helmet"):
		await c.say("kael", "그, 그거 제 투구! 찾아 주셨어요?! 마녀님은 생명의 은인이에요!", "happy")
		c.close_box()
		await c.quest_done("k_kael_helmet")
		await c.say("kael", "단장님께는 비밀이에요! 절대로! …단장님 뒤에 계세요? 아니죠? 휴.", "sad")
		return
	if q == 0 and c.has("k_walls_talk"):
		await c.say("kael", "저, 저기 마녀님… 부탁이 하나 있는데요.", "sad")
		await c.say("kael", "지붕 순찰을 하다가… 가고일한테 투구를 뺏겼어요. 풍향계 근처에 걸려 있는 건 봤는데 손이 안 닿아서…")
		await c.say("kael", "단장님께 들키면 저는 끝이에요! 연무장 백 바퀴예요! 마녀님은 날 수 있잖아요!", "surprised")
		c.quest_start("k_kael_helmet")
		if c.has("k_helmet"):
			await c.say("sera", "혹시… 이거?")
			await c.say("kael", "…!! 벌써?! 마녀님 대체 뭐예요?!", "surprised")
			c.close_box()
			await c.quest_done("k_kael_helmet")
		return
	if q == 1:
		await c.say("kael", "풍향계 지붕이에요! 굴뚝 열기를 타면 위로 올라간다던데… 저는 갑옷이 무거워서…", "sad")
		return
	if c.has("k_beast_down"):
		await c.say("kael", "운석 괴물! 마녀님이랑 단장님이 같이! 그 장면 제가 봤어야 했는데! 아이 데려다주느라!", "sad")
	elif c.has("k_spar_done"):
		await c.say("kael", "단장님이 '나쁘지 않군' 한 사람, 제가 아는 걸로 마녀님이 세 번째예요. 첫 번째는 브론 아저씨 검, 두 번째는 미아네 크림빵!", "happy")
	else:
		await c.say("kael", "은사자 기사단 부단장 카엘입니다! 단장님은 무섭지만 좋은 분이에요! 아, 무섭다는 건 비밀로…", "happy")


func k_helmet_got(c: Cut) -> void:
	if Quests.state("k_kael_helmet") == 1:
		c.quest_step("k_kael_helmet", 1)
		c.bubble("카엘의 투구다. 돌려주자꾸나.", 2.4)
	else:
		c.bubble("기사의 투구로구나. 주인이 찾고 있겠지.", 2.4)


func npc_mia(c: Cut) -> void:
	var q := Quests.state("k_mia_bread")
	if q == 0 and c.has("k_met_leonie"):
		await c.say("mia", "어서 오세요! 미아네 빵집이에요! 앗, 마녀님이다! 단장님이랑 시장에서 만났다는 그 마녀님!", "happy")
		await c.say("mia", "저기, 부탁이 있어요! 빵 배달 세 곳인데요, 엄마가 허리를 다쳐서…", "sad")
		await c.say("mia", "기사단 연무장의 카엘 아저씨, 대장간의 브론 아저씨, 대성당의 사제님! 셋 다 단골이에요!")
		c.quest_start("k_mia_bread")
		c.close_box()
		await c.item("배달할 빵 바구니", "사자 머리 빵 세 봉지. 아직 따뜻하다.")
		await c.say("mia", "다 돌리면 와요! 단장님 옛날이야기 해 줄게요. 아무도 모르는 거!", "happy")
		return
	if q == 1:
		if _bread_count() >= 3:
			await c.say("mia", "벌써 다 돌렸어요?! 마녀님 빠르다! 날아서 갔죠?", "happy")
			await c.say("mia", "약속한 이야기! …단장님은요, 어릴 때 빈민가에 살았대요. 우리 엄마도 거기 출신이라 알아요.")
			await c.say("mia", "별이 떨어진 밤에, 단장님이 막대기 하나 들고 불타는 골목에서 애들을 지켰대요. 그때 단장님도 열여덟 살이었는데.")
			await c.say("mia", "그 애들 중에 한 명이… 우리 엄마예요. 그래서 우리 집은 단장님 크림빵을 공짜로 드려요. 단장님은 맨날 돈 내고 가지만!", "happy")
			c.close_box()
			await c.quest_done("k_mia_bread")
			c.bubble("…막대기 하나로. 마력 없이.", 2.4)
		else:
			await c.say("mia", "카엘 아저씨는 연무장, 브론 아저씨는 시장 대장간, 사제님은 시계 거리 동쪽 대성당이에요!")
		return
	if c.has("k_beast_down"):
		await c.say("mia", "세라 언니 그림도 그렸어요! 단장님 옆에! 다락방 상자에 넣어 둘 거예요!", "happy")
	elif c.has("k_duel_called"):
		await c.say("mia", "오늘 밤에 황궁 광장에서 뭔가 한대요! 엄마가 절대 나가지 말래요. …궁금한데.", "sad")
	else:
		await c.say("mia", "사자 머리 빵 드실래요? 단장님 빵이에요! 갈기가 바삭바삭해요!", "happy")


func npc_bron(c: Cut) -> void:
	if _deliver_bread(c, "bron"):
		await c.say("bron", "…미아 빵인가. 거기 둬라.")
		await c.say("bron", "…따뜻하군.", "happy")
		return
	var q := Quests.state("k_bron_ore")
	if q == 1 and c.has("k_star_iron"):
		await c.say("bron", "…그거, 별철이로군.", "surprised")
		await c.say("bron", "좋은 쇠다. 차갑고, 고집이 세다. 단장 검으로 벼리겠다.")
		await c.say("bron", "단장한테는 말하지 마라. 자기가 산 줄 알게 해. 그 녀석, 공짜는 안 받는다.")
		c.close_box()
		await c.quest_done("k_bron_ore")
		await c.say("bron", "그건 피피라는 꼬마가 맡긴 물약 주머니다. 내가 꿰맸다. 하나 더 들어간다.")
		return
	if q == 0 and c.has("k_spar_done"):
		await c.say("bron", "…단장 검, 봤나. 이가 다 나갔다. 짐승 뼈를 너무 베서.")
		await c.say("bron", "별철이 있으면 새로 벼려 줄 수 있다. 10년 전 별이 떨어질 때 같이 쏟아진 쇠다.")
		await c.say("bron", "하수도 수로 바닥에 가라앉아 있단 소문이 있다. 물을 빼야 보이겠지.")
		c.quest_start("k_bron_ore")
		if c.has("k_star_iron"):
			c.quest_step("k_bron_ore", 1)
		return
	if q == 1:
		await c.say("bron", "하수도 수로. 다리 밑 굴. 물을 빼라.")
		return
	await c.say("bron", "…검은 주인을 닮는다. 쓸데없이 반짝이는 건 질색이야.")


func npc_k_merchant(c: Cut) -> void:
	if Quests.state("k_spice") == 1 and not c.has("k_spice_got"):
		await c.say("k_merchant", "별향신료? 아아, 마녀학교 식당 아주머니 심부름이구먼! 그분 단골이었지, 젊었을 때.", "happy")
		c.flag("k_spice_got")
		c.quest_step("k_spice", 1)
		c.close_box()
		await c.item("별향신료", "별 모양 열매를 말린 향신료. 코끝이 반짝반짝 따끔하다.")
		await c.say("k_merchant", "돈은 됐어. 버터워스 누님한테 안부나 전해 줘!")
		return
	await c.say("k_merchant", "별 사탕, 별 열매, 별가루 소금! 별이 떨어진 도시의 명물이오!", "happy")
	await c.say("k_merchant", "…요즘은 짐승 때문에 손님이 반으로 줄었지만.", "sad")


# ─── 거리 사람들 ─────────────────────────────────────────

func npc_k_gate_guard(c: Cut) -> void:
	if c.has("k_spar_done"):
		await c.say("k_knight", "투기장은 열렸습니다. 챔피언 가론이 도전자를 기다리고 있지요.")
	else:
		await c.say("k_knight", "투기장은 기사단 행사로 닫혀 있습니다. 단장님께 인사는 하셨습니까? 연무장은 시장 지나 동쪽입니다.")


func npc_k_gate_a(c: Cut) -> void:
	if c.has("k_beast_down"):
		await c.say("k_citizen_a", "밤하늘이 그렇게 환한 건 10년 만이었어. 근데 이번엔 무섭지 않았단다.", "happy")
	elif c.has("k_met_leonie"):
		await c.say("k_citizen_a", "단장님이 시장에서 짐승을 한 칼에 베셨다며? 역시 우리 단장님이야!", "happy")
	else:
		await c.say("k_citizen_a", "마녀학교에서 왔니? 조심하렴. 요즘 별의 짐승이 대낮에도 나온단다.", "sad")


func npc_k_gate_child(c: Cut) -> void:
	await c.say("k_child", "나중에 크면 은사자 기사가 될 거야! 마력 없어도 될 수 있대! 단장님처럼!", "happy")


func npc_k_market_b(c: Cut) -> void:
	if c.has("k_beast_down"):
		await c.say("k_citizen_b", "마녀 아가씨, 고맙네. 늙은이는 오래 살다 보니 별이 두 번 떨어지는 것도 보는구먼.", "happy")
	else:
		await c.say("k_citizen_b", "10년 전 그 밤에도 하늘이 갈라졌지. 별 하나가 옛 성곽에 떨어졌는데, 이상하게 조용히 내려앉았어.")


func npc_k_market_c(c: Cut) -> void:
	await c.say("k_citizen_c", "대장간 굴뚝 열기가 엄청나요. 새들이 그걸 타고 지붕 위로 휙 올라간다니까요.")


func npc_k_alley(c: Cut) -> void:
	if c.has("k_sewer_grate"):
		await c.say("k_citizen_c", "철창이 열렸네? 하수도 냄새가… 으. 빨래 다시 해야겠다.", "sad")
	else:
		await c.say("k_citizen_c", "저 철창 아래는 하수도야. 밤마다 별빛이 새어 나와. 안쪽에서 빗장이 걸려 있어서 못 열지만.")


func npc_k_yard_a(c: Cut) -> void:
	await c.say("k_knight", "관람석에서 보면 단장님 검이 잔상처럼 보입니다. 사실 저도 잘 안 보입니다.")


func npc_k_yard_b(c: Cut) -> void:
	if c.has("k_spar_done"):
		await c.say("k_knight_b", "단장님과 대련을 버틴 마녀라니! 오늘 저녁 술안주는 정해졌군요!", "happy")
	else:
		await c.say("k_knight_b", "단장님은 마력이 한 톨도 없으세요. 그래서 다들 '무력'이라 놀렸대요. …지금은 아무도 안 놀리죠.")


func npc_k_barracks(c: Cut) -> void:
	await c.say("k_knight_b", "부단장님 침대 밑을 보지 마세요. 단장님 초상화가 잔뜩… 아, 말해 버렸다.", "sad")
