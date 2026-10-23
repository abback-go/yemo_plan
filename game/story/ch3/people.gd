extends "res://story/ch3/common.gd"
## 3장 대본 — 엘프 인물 대화·서브 퀘스트 · 활쏘기.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 인물 대화 (엘프의 숲)
# ═══════════════════════════════════════════════════════════

func npc_ortia(c: Cut) -> void:
	if not c.has("e_met_ortia"):
		await c.say("ortia", "허허, 손님이구먼.", "happy")
		return
	var st := Quests.state("e_ortia_tea")
	var n := Cut.count(TEA)
	if st == 0:
		await c.say("ortia", "세라피나, 늙은이 부탁 하나 들어주겠나.", "happy")
		await c.say("ortia", "달잎 차가 떨어졌다네. 달샘의 달잎 한 장, 수관 높은 잎의 이슬 한 방울. 그거면 되네.")
		await c.say("ortia", "서두를 건 없네. 가는 길에 눈에 띄거든 챙겨 오게.")
		c.close_box()
		c.quest_start("e_ortia_tea")
		if n >= 2:
			c.quest_step("e_ortia_tea", 1)
		return
	if st == 1:
		if n >= 2:
			await e_ortia_tea_done(c)
		else:
			await c.say("ortia", "달잎은 달샘에, 이슬은 수관 높은 잎에 고인다네. (%d/2)" % n)
		return
	if c.has("e_herald_done"):
		await c.say("ortia", "세계수가 꽃을 피웠네. 언제든 놀러 오게. 아스트리드에게도 안부 전하고.", "happy")
	elif c.has("e_hunt_done"):
		await c.say("ortia", "아이들이… 꼭대기에? 엘라리엔을 부탁하네, 세라피나.", "serious")
	elif c.has("e_grove_purified"):
		await c.say("ortia", "엘라리엔이 시험을 하겠다고? 허허, 그 아이 나름의 환영 인사일세.", "happy")
	elif c.has("e_moon_lesson"):
		await c.say("ortia", "잠재우는 불이라… 그분과 똑같은 말을 하는구먼.", "happy")
	else:
		await c.say("ortia", "티엘은 줄기 시장 오른쪽 끝 공방에 있다네. 달샘은 가지 마을 위쪽 끝이고.")


func e_ortia_tea_done(c: Cut) -> void:
	await c.say("ortia", "오오, 달잎에 이슬까지. …향이 좋구먼.", "happy")
	await c.say("ortia", "답례일세. 이 주머니면 물약을 하나 더 넣고 다닐 수 있을 게야. 젊을 땐 늘 하나가 모자라거든.", "happy")
	c.close_box()
	await c.quest_done("e_ortia_tea")


func npc_fio(c: Cut) -> void:
	if c.has("e_herald_done"):
		await c.say("fio", "누나가 구해 줬어! 엘라리엔 언니가 그랬어, 누나 불은 따뜻하대!", "happy")
		if Quests.state("e_fio_seeds") != 1:
			return
	if not c.has("e_met_ortia"):
		await c.say("fio", "장로님 집은 저 큰 뿌리 문이야! 빨리 가 봐!", "happy")
		return
	var st := Quests.state("e_fio_seeds")
	var n := Cut.count(SEEDS)
	if st == 0:
		await c.say("fio", "누나, 누나! 부탁이 있어. 내 반짝이 씨앗… 다 흘렸어.", "sad")
		await c.say("fio", "별이 될 씨앗이야! 밤에 심으면 별이 돋는대. …엄마는 그냥 콩이래.")
		await c.say("fio", "다섯 개야. 마을이랑, 우리 집이랑, 시장이랑, 바람길이랑, 가지 마을! 찾아 줄 거지?", "happy")
		c.close_box()
		c.quest_start("e_fio_seeds")
		if n >= 5:
			c.quest_step("e_fio_seeds", 1)
		else:
			return
	elif st == 2:
		await c.say("fio", "씨앗 심을 화분 찾는 중이야! 별 돋으면 누나한테 제일 먼저 보여 줄게!", "happy")
		return
	await e_fio_seeds_done(c)


## 씨앗 돌려주기 (퀘스트 talk 갈고리 — 다른 장의 피오 대사 덮어쓰기보다 먼저)
func e_fio_seeds_done(c: Cut) -> void:
	if Cut.count(SEEDS) < 5:
		await c.say("fio", "지금 %d개야! 마을, 우리 집, 시장, 바람길, 가지 마을!" % Cut.count(SEEDS))
		return
	await c.say("fio", "우와아! 다섯 개 다! 누나 최고!", "happy")
	await c.say("fio", "선물이야! 그리고 비밀 하나 알려 줄게…")
	await c.say("fio", "가지 마을 왼쪽 위 끝에, 벽이 가끔 반짝이는 데가 있어. 여우 눈으로 보면 뭐가 보일걸?", "happy")
	c.close_box()
	await c.quest_done("e_fio_seeds")


func npc_fio_mom(c: Cut) -> void:
	if c.has("e_fio_gone"):
		await c.say("fio_mom", "피오가… 피오가 안 보여요! 아이들이 꼭대기로 올라갔다고…", "sad")
		return
	if c.has("e_herald_done"):
		await c.say("fio_mom", "피오를 구해 주셨다고요. …고마워요, 마녀님. 정말로.", "happy")
		return
	await c.say("fio_mom", "피오가 마녀님 이야기만 해요. 별이 될 씨앗 이야기도 들으셨죠?", "happy")
	await c.say("fio_mom", "…저는 그냥 콩이라고 했는데. 쉿, 비밀이에요.")


func npc_tiel(c: Cut) -> void:
	var st := Quests.state("e_tiel_valve")
	var n := Cut.count(VALVES)
	if st == 0 and c.has("e_met_tiel"):
		c.quest_start("e_tiel_valve")
		st = 1
	if st == 1:
		if n >= 3:
			await e_tiel_valve_done(c)
		else:
			await c.say("tiel", "녹슨 밸브는 바람길 굴마다 하나씩이야. 세 번 데우면 풀려! (%d/3)" % n)
			await c.say("tiel", "고친 밸브는 숨은 바람을 되살려. 위로 올려 주는 바람 말이야. 어디로 데려갈진 나도 몰라!", "happy")
		return
	if c.has("e_herald_done"):
		await c.say("tiel", "꼭대기 바람이 깨끗해졌어! 이제 새 밸브 설계도를 그릴 수 있겠다!", "happy")
	else:
		await c.say("tiel", "바람길은 시장 오른쪽 끝 계단! 밸브는 데우면 돈다, 기억하지?")


func e_tiel_valve_done(c: Cut) -> void:
	await c.say("tiel", "다 고쳤어?! 와… 진짜로? 어쩐지 바람 소리가 달라졌다 했어!", "surprised")
	await c.say("tiel", "이건 수고비! 바람길 바닥에서 주운 보라 돌인데, 마녀들은 이런 거 좋아하지?", "happy")
	c.close_box()
	await c.quest_done("e_tiel_valve")


## 활터 퀘스트 갈고리: 활터에서만 시험, 다른 곳의 엘라리엔은 안내만
func e_archery_talk(c: Cut) -> void:
	if c.world.room.data.id == "e_archery":
		await _archery(c)
	else:
		await c.say("elarien", "활터는 가지 마을 아래 가지 끝이다. 과녁이 기다린다.")


func npc_elarien(c: Cut) -> void:
	if c.world.room.data.id == "e_archery":
		await _archery(c)
		return
	if c.has("e_hunt_offer"):
		await c.say("elarien", "준비되면 올라와라.", "focus")
	else:
		await c.say("elarien", "……")


## 활터 (e_archery): 과녁 넷을 20초 안에
func _archery(c: Cut) -> void:
	var st := Quests.state("e_archery")
	if st == 2:
		await c.say("elarien", "또 왔나. …바람이 좋다. 쏘고 싶으면 쏴라.", "smirk")
		var again := await c.choose("elarien", "한 판 더?", ["쏜다", "나중에"])
		if again != 0:
			return
		await _archery_round(c)
		return
	if st == 0:
		await c.say("elarien", "왔군. 과녁 넷. 스무 초.", "focus")
		await c.say("elarien", "움직이는 과녁은 지금 자리가 아니라, 갈 자리를 쏴라. 바람을 읽어라.")
		c.quest_start("e_archery")
	var go := await c.choose("elarien", "해 보겠나?", ["한다", "나중에"])
	if go != 0:
		await c.say("elarien", "…언제든.")
		return
	await _archery_round(c)


func _archery_round(c: Cut) -> void:
	var tree := c.world.get_tree()
	ArcheryMark.reset_group(tree, "archery")
	await c.say("elarien", "셋을 세면 시작.")
	c.close_box()
	for s in ["셋", "둘", "하나"]:
		Story.toast(s, 0.6)
		await c.wait(0.7)
	c.flag("e_archery_on")
	Story.toast("시작!", 1.0)
	c.release()
	var total := ArcheryMark.count_all(tree, "archery")
	var left := ARCHERY_TIME
	var next_call := 15.0
	while left > 0.0 and c.ok():
		await c.wait(0.1)
		left -= 0.1
		if ArcheryMark.count_hit(tree, "archery") >= total:
			break
		if left <= next_call:
			Story.toast("남은 시간 %d초 — %d/%d" % [int(ceil(left)), ArcheryMark.count_hit(tree, "archery"), total], 1.2)
			next_call -= 5.0
	c.flag("e_archery_on", false)
	if not c.ok():
		return
	c.lock()
	var got := ArcheryMark.count_hit(tree, "archery")
	if got >= total:
		await c.say("elarien", "…넷. %.1f초 남았다." % maxf(left, 0.0), "smirk")
		if Quests.state("e_archery") == 1:
			await c.say("elarien", "바람을 읽을 줄 아는군. 가져가라. 사냥꾼의 몫이다.")
			c.close_box()
			await c.quest_done("e_archery")
		else:
			await c.say("elarien", "더 빨라졌군.")
	else:
		await c.say("elarien", "%d개. …바람을 읽어라. 다시 하고 싶으면 말해라." % got)
	ArcheryMark.reset_group(tree, "archery")


func npc_warden_a(c: Cut) -> void:
	if c.has("e_herald_done"):
		await c.say("warden_a", "아이들을 데려와 줘서… 고맙다. 창을 겨눈 걸 사과한다.")
	elif c.has("e_grove_purified"):
		await c.say("warden_a", "숲을 살렸다고? …마녀가?", "surprised")
	elif c.has("e_border_passed"):
		await c.say("warden_a", "장로님 손님이라면 할 말 없다. …다음엔 화살 비 속을 걷지 마라.")
	else:
		await c.say("warden_a", "돌아가라. 장로님의 허락 없이는 못 지나간다.")


func npc_warden_b(c: Cut) -> void:
	var rid := c.world.room.data.id
	if rid == "e_trunk_market":
		if c.has("e_met_tiel"):
			await c.say("warden_b", "티엘이 보냈다고? 올라가라. 바람이 거칠다.")
		else:
			await c.say("warden_b", "바람길은 티엘의 허락이 있어야 한다. 공방은 바로 왼쪽이다.")
		return
	if rid == "e_archery":
		await c.say("warden_b", "엘라리엔은 여기서 매일 천 발을 쏜다. 한 발도 과녁 밖으로 안 나가지.")
		await c.say("warden_b", "…사람한테 쏠 때만 빼고. 그땐 일부러 비껴 쏜다.")
		return
	if c.has("e_border_passed"):
		await c.say("warden_b", "화살 비를 뚫은 마녀라. 마을에선 소문이 벌써 났다.")
	else:
		await c.say("warden_b", "…제법인데. 그래도 못 지나간다.")


func npc_e_roots_a(c: Cut) -> void:
	if c.has("e_grove_purified"):
		await c.say("elf_a", "숲을 살린 마녀님! 이 달잎 과자 하나 드세요. 아니, 두 개!", "happy")
	else:
		await c.say("elf_a", "마녀가 마을에? …불은 저 멀리서만 써 줘요. 뿌리가 놀라요.")


func npc_e_roots_b(c: Cut) -> void:
	if c.has("e_lift_fixed"):
		await c.say("elf_b", "승강기가 다시 돈다! 바람길을 고친 게 너였어?", "happy")
	else:
		await c.say("elf_b", "승강기가 멈춘 지 열흘째야. 바람길이 하얘지고부터.")


func npc_e_roots_c(c: Cut) -> void:
	if c.has("e_fio_gone"):
		await c.say("elf_c", "피오가… 하얀 노래 따라갔어. 나도 들었는데, 무서워서 안 갔어…", "sad")
	elif c.has("e_herald_done"):
		await c.say("elf_c", "피오가 그러는데, 누나가 하얀 걸 불로 재웠대! 진짜야?", "happy")
	else:
		await c.say("elf_c", "피오 봤어? 걔 맨날 씨앗 얘기만 해. 별이 된다나.")


func npc_e_roots_warden(c: Cut) -> void:
	if c.has("e_cave_mush"):
		await c.say("elf_warden", "동굴 버섯을 깨웠다고? 아기 버섯부터 깨우는 건 엘프 아이들도 다 아는 거다.")
	else:
		await c.say("elf_warden", "뿌리 동굴은 어둡다. 버섯을 깨우면 길이 보인다고들 하지.")


func npc_e_market_a(c: Cut) -> void:
	await c.say("elf_a", "달잎 차, 꿀떡, 화살깃! …마녀는 돈 대신 뭘 내지? 불?", "happy")
	if GameState.potions < GameState.potions_max:
		await c.say("elf_a", "에이, 꿀떡 하나 그냥 가져가요. 힘내라고!")
		GameState.potions = GameState.potions_max
		c.close_box()
		Story.toast("꿀떡을 먹었다. 물약이 가득 찼다.", 2.0)


func npc_e_market_c(c: Cut) -> void:
	await c.say("elf_c", "티엘 언니 공방은 시장 오른쪽 끝! 문에서 쿵쾅 소리 나는 데!", "happy")


func npc_e_branch_a(c: Cut) -> void:
	if c.has("e_grove_purified") and not c.has("e_herald_done"):
		await c.say("elf_a", "꼭대기에서 하얀 노래가 들려… 아이들한테 귀 막으라고 했어.", "sad")
	else:
		await c.say("elf_a", "가지 마을은 바람이 세. 날개 있는 사람은 좋겠다.")


func npc_e_branch_b(c: Cut) -> void:
	if c.has("e_hunt_done"):
		await c.say("elf_b", "엘라리엔한테 닿았다고? …세 번이나? 말도 안 돼.", "surprised")
	elif c.has("e_grove_purified"):
		await c.say("elf_b", "엘라리엔이 경기장에서 기다린대. 사냥 시험이래! 수관 계단은 저기야.")
	else:
		await c.say("elf_b", "수관 계단은 막혀 있어. 위는 역병이 짙대. 달샘은 이 가지 오른쪽 끝이야.")


func npc_e_branch_c(c: Cut) -> void:
	await c.say("elf_c", "달샘 가 봤어? 밤엔 달이 물에 빠진 것 같아!", "happy")


## 대본으로 세운 아이들 (꼭대기 등)
func npc_elf_c(c: Cut) -> void:
	await c.say("elf_c", "마녀 누나…", "sad")
