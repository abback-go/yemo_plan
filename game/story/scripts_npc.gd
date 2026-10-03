extends RefCounted
## 대본: 인물에게 말 걸기 (npc_<who> 또는 방 데이터의 talk ID). 진행 플래그에 따라 대사가 바뀐다.


func _pick(lines: Array) -> String:
	return String(lines[randi() % lines.size()])


# ─── 의무실·기숙사 ──────────────────────────────────────

func npc_mirabel(c: Cut) -> void:
	if c.has("agwi_defeated"):
		await c.say("mirabel", "지하에서 결계 실습 사고가 있었대요. 다친 사람은 없다니 다행이에요~", "happy")
		await c.say("mirabel", "…세라 양, 왜 그렇게 웃어요?")
	elif c.has("key_basement"):
		await c.say("mirabel", "지하로 간다고요? 그럼 물약은 꼭 챙기고요. 무리하면 안 돼요!", "sad")
	elif c.has("golem_done"):
		await c.say("mirabel", "실습장에서 골렘이 날뛰었다면서요? 다친 데는 없어요?", "surprised")
		await c.say("mirabel", "힘들면 침대에서 쉬어 가요. 체력도 물약도 다시 채워 줄게요.")
	else:
		await c.say("mirabel", "폭주했던 몸은 쉬어야 해요. 아프면 언제든 침대로 와요~", "happy")
		await c.say("mirabel", "…그 여우, 침대엔 올리지 말고요. 털이 날려요.")
	c.bubble("…무엄하구나.", 1.6)


# ─── 연금술실: 피피 (월광초 부탁) ───────────────────────

func npc_pippa(c: Cut) -> void:
	if c.has("moonherb") and not c.has("pippa_quest_done"):
		await c.say("pippa", "그거… 그거 월광초?! 진짜?! 온실 안쪽에서?!", "surprised")
		await c.say("pippa", "꺄아아! 이걸로 물약 병 하나 더 만들 수 있어! 잠깐만, 잠깐만…!", "happy")
		c.close_box()
		c.sfx("squish")
		c.shake(0.05, 0.4)
		await c.wait(0.8)
		c.flag("pippa_quest_done")
		GameState.potions_max += 1
		GameState.potions = GameState.potions_max
		await c.item("회복 물약 +1", "물약을 하나 더 들고 다닐 수 있다.")
		await c.say("pippa", "짠! 맛은… 여전히 보장 못 해.", "smug")
		return
	if not c.has("pippa_asked"):
		c.flag("pippa_asked")
		await c.say("pippa", "세라! 마침 잘 왔어. 부탁이 있는데…")
		await c.say("pippa", "온실 안쪽에 '월광초'라는 약초가 있거든. 그게 있으면 물약 병을 하나 더 만들 수 있어!")
		await c.say("pippa", "근데 요즘 덩굴이 사나워져서 무서워서 못 가겠어. 앞마당 아래 유리 온실이야.", "sad")
		await c.say("sera", "알았어. 지나가는 길에 볼게.")
		return
	if c.has("chapter_end"):
		await c.say("pippa", "오늘 학교 진짜 이상했지? 근데 너 표정이 왜 이렇게 좋아?", "happy")
		return
	var lines := [
		["pippa", "물약은 기록 지점에서 다시 채워져. 아끼지 말고 마셔!"],
		["pippa", "실험 안 했어! …아니, 했어. 조금. 그 초록 병은 건드리지 마."],
		["pippa", "너울이라고? 사역마 이름 예쁘다. …방금 날 노려본 것 같은데?"],
	]
	var l: Array = lines[randi() % lines.size()]
	await c.say(String(l[0]), String(l[1]), "happy")


# ─── 마법반·실습장: 엠버린 ──────────────────────────────

func npc_emberlyn(c: Cut) -> void:
	if c.has("agwi_defeated"):
		await c.say("emberlyn", "오늘은 푹 쉬어라. …그리고, 잘했다.", "happy")
	elif c.has("golem_done"):
		await c.say("emberlyn", "도서관에 가 봤니? 그레타는 무뚝뚝해도 책 일이라면 믿을 만하다.")
		if not GameState.has_ability("double_jump"):
			await c.say("emberlyn", "높은 곳이 문제라면 오필리아에게 가 봐라. 서관 계단 아래, 잠꾸러기 교수 말이다.")
	elif c.has("met_emberlyn"):
		await c.say("emberlyn", "과녁 셋이 동시에 타야 한다. 쏘는 순서와 쉬는 틈을 생각해라.")
		await c.say("emberlyn", "게이지가 차면 잠깐 멈춰. 불은 숨을 쉬어야 커진다.")
	else:
		await c.say("emberlyn", "수업 중이다, 세라.")


# ─── 중앙 홀·복도 학생들 ────────────────────────────────

func npc_isolde(c: Cut) -> void:
	if c.has("golem_done"):
		await c.say("isolde", "골렘을 쓰러뜨렸다고? …운이 좋았겠지.", "smug")
		c.bubble("…흥.", 1.4)
	else:
		await c.say("isolde", "말 걸지 마. 폐급이 옮을 것 같으니까.", "smug")
		await c.say("neoul", "…저 아이, 조금 혼내 줄까.", "scary")
		await c.say("sera", "(작게) 하지 마.")


func npc_hall_a(c: Cut) -> void:
	if c.has("adv_done"):
		await c.say("student_a", "고급반에서 갑옷이 날뛰었는데 일반반 애가 막았대! …너야?")
	elif c.has("golem_done"):
		await c.say("student_a", "실습장 골렘이 폭주했다며? 무서워…")
	else:
		await c.say("student_a", "어젯밤 지하에서 이상한 소리 들었어? 꾸르륵… 하는 거.")


func npc_hall_b(c: Cut) -> void:
	if c.has("chapter_end"):
		await c.say("student_b", "결계 실습 사고였대. …근데 왜 지하에서 파란 빛이 났지?")
	else:
		await c.say("student_b", "저 여우, 네 사역마야? 귀엽다. …쟤 지금 나한테 하품한 거야?")
		c.emote("neoul", "...")


func npc_hall_c(c: Cut) -> void:
	await c.say("student_c", "샹들리에 위에 뭔가 반짝이는 거 봤어? 부양을 배우면 닿을지도.")


func npc_westcorr(c: Cut) -> void:
	if c.has("golem_done"):
		await c.say("student_c", "비속성반 계단 공사 끝났대. 오필리아 교수님은… 아마 주무시겠지.")
	else:
		await c.say("student_c", "마법반 실습 늦으면 엠버린 교수님한테 그을음 청소당한다?")


func npc_class_a(c: Cut) -> void:
	await c.say("student_a", "칠판 그을음, 진짜 네가 한 거야? …멋있다.")


func npc_class_b(c: Cut) -> void:
	await c.say("student_b", "…쟤 지금 여우랑 싸워?")
	c.emote("sera", "sweat")


func npc_cafe(c: Cut) -> void:
	await c.say("student_a", "오늘 메뉴는 '수상한 수프'래. 매일 그렇지만.")


func npc_courtyard(c: Cut) -> void:
	if c.has("key_basement"):
		await c.say("student_b", "지하 철문이 열려 있어…? 거긴 출입 금지인데.", "surprised")
	else:
		await c.say("student_b", "밤마다 지하 철문 안에서 뭘 씹는 소리가 난대. 소문이겠지?")


# ─── 식당: 버터워스 아주머니 ────────────────────────────

func npc_butterworth(c: Cut) -> void:
	await c.say("butterworth", "아이고, 세라 왔나! 배고프제? 이거 한 그릇 묵고 가라.", "happy")
	c.close_box()
	GameState.heal_full()
	c.player.restore_from_state()
	c.sfx("potion")
	Story.toast("따끈한 수프를 먹었다. 체력이 모두 회복되었다.")
	await c.wait(0.6)
	if not c.has("butter_fox"):
		c.flag("butter_fox")
		await c.say("butterworth", "그 여우도 하나 줄까? 고기 쪼가리 남은 게 있는데.")
		await c.say("neoul", "…이 마녀, 마음에 드는구나.", "happy")
	else:
		await c.say("butterworth", _pick(["많이 묵어라. 마녀는 배가 든든해야 불도 든든한 기라.", "학교가 요즘 시끄럽제? 밥은 거르지 말고.", "국자 들고 쫓아가믄 빗자루도 도망간다 아이가."]))


# ─── 도서관: 그레타·호두 ────────────────────────────────

func npc_greta(c: Cut) -> void:
	if c.has("key_recovered"):
		await c.say("greta", "…열쇠를 되찾았나. 그 마도서는 '연체' 도장을 찍어 두지.")
	elif c.has("key_stolen"):
		await c.say("greta", "서가 미로는 위로 갈수록 좁다. 길을 잃으면 호두에게 물어라.")
	else:
		await c.say("greta", "정숙.")


func npc_hodu(c: Cut) -> void:
	await c.say("hodu", "호우.")
	await c.narrate("(호두가 고개를 갸웃했다. 뭔가 다 안다는 표정이다.)")


func npc_hodu_maze(c: Cut) -> void:
	await c.say("hodu", "호우. 호우.")
	await c.narrate("(호두가 날개로 왼쪽 위를 가리킨다. 오른쪽 끝은 막다른 길인 모양이다.)")


# ─── 비속성반·고급반·교장실 ─────────────────────────────

func npc_ophelia(c: Cut) -> void:
	if GameState.has_ability("double_jump"):
		await c.say("ophelia", "합격이란다~ 이제 그 깃털은 너의 몸이 기억해~", "happy")
		await c.say("ophelia", "높은 곳에서 떨어질 땐… 무게를 다시 기억하면 된단다~ 쿨…")
	else:
		await c.say("ophelia", "등불 다섯 개~ 왼쪽 실습실이란다~ …쿨…")


func npc_veronica(c: Cut) -> void:
	if c.has("adv_done"):
		await c.say("veronica", "교장실에 가 보아라. 기다리고 계신다.")
	else:
		await c.say("veronica", "물러서 있어라.")


func npc_astrid(c: Cut) -> void:
	if c.has("agwi_defeated"):
		await c.say("astrid", "푹 쉬세요, 세라피나 양. 그리고 너울 님께도 안부를.", "happy")
		c.emote("neoul", "...")
	else:
		await c.say("astrid", "봉인 회랑의 불은 순서가 있어요. 참모습을 보는 눈으로 벽을 보세요.")
