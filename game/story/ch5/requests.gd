extends "res://story/ch5/common.gd"
## 5장 대본 — 축제의 부탁 — 편지(호두)·물약 가게(피피)·요리 대회(버터워스)·무도회(이졸데)·별 관측(오필리아).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


func npc_hodu_ch5(c: Cut) -> void:
	match _phase(c):
		"fest":
			var st := Quests.state("st_hodu_letters")
			if st == 0:
				await c.say("hodu", "호우. 호우우.")
				await c.narrate("호두가 부리로 초대장 뭉치를 내밀었다. 받는 사람: 미라벨 · 그레타 · 베로니카 · 오필리아 · 엠버린 · 버터워스.")
				var i := await c.choose("sera", "같이 돌려 줄까?", ["돌려 줄게", "나중에"])
				c.close_box()
				if i == 0:
					c.quest_start("st_hodu_letters")
					await c.say("hodu", "호우!", "happy")
			elif st == 1 and Quests.step("st_hodu_letters") >= 1:
				await c.say("hodu", "호우우!", "happy")
				await c.narrate("호두가 날개를 퍼덕이며 세라의 모자 위에 잠깐 앉았다 갔다. …발톱이 따끔하다.")
				c.close_box()
				await c.quest_done("st_hodu_letters")
			else:
				await c.say("hodu", "호우.")
		"war":
			await c.say("hodu", "호우…")
		"epi":
			await _rebuild_help(c, "hodu")
		_:
			await c.say("hodu", "호우.", "happy")
	c.close_box()


# ─── 피피의 축제 물약 가게 ──────────────────────────────

func npc_pippa_ch5(c: Cut) -> void:
	match _phase(c):
		"fest":
			var st := Quests.state("st_pippa_stall")
			if st == 0:
				await c.say("pippa", "어서 오세요~ 피피의 축제 물약 가게! …라고 하고 싶은데, 재료가 모자라!", "sad")
				await c.say("pippa", "별사탕 꿀(식당), 반딧불 이끼(유리 온실), 시계탑 이슬(시계탑 톱니 사이). 이 셋이면 물약 병을 하나 더 만들 수 있어!")
				await c.say("pippa", "구해 주면 네 물약 주머니부터 늘려 줄게. 진짜야!", "happy")
				c.close_box()
				c.quest_start("st_pippa_stall")
			elif st == 1:
				var got := 0
				for f in ["st_ing_honey", "st_ing_moss", "st_ing_dew"]:
					if c.has(f):
						got += 1
				if got >= 3:
					await c.say("pippa", "꿀, 이끼, 이슬… 다 있어! 꺄아, 세라 최고!", "happy")
					c.close_box()
					c.sfx("squish")
					c.shake(0.05, 0.4)
					await c.wait(0.6)
					await c.say("pippa", "짜잔! 별사탕 물약 주머니야. …맛은 여전히 보장 못 해.", "smug")
					c.close_box()
					await c.quest_done("st_pippa_stall")
				else:
					await c.say("pippa", "재료는 %d/3. 식당, 유리 온실, 시계탑이야!" % got)
			else:
				await c.say("pippa", "별사탕 물약 한 병 마셔 볼래? …왜 표정이 그래?", "happy")
		"trial":
			await c.say("pippa", "…교장 선생님은 별의 문간에서 버티고 계셔. 미라벨 선생님이 말려도 소용없대.", "sad")
			await c.say("pippa", "난 물약을 잔뜩 만들어 둘게. 다녀와, 세라. 꼭!")
		"epi":
			await _pippa_epi(c)
		_:
			await c.say("pippa", "세라…!", "sad")
	c.close_box()


# ─── 버터워스의 요리 대회 ───────────────────────────────

func npc_butterworth_ch5(c: Cut) -> void:
	if await _letter(c, "butterworth"):
		return
	match _phase(c):
		"fest":
			var st := Quests.state("st_cook_off")
			if st == 0:
				await c.say("butterworth", "왔구나, 세라! 올해 축제 요리 대회 심사위원이 모자라서 말이야.", "happy")
				await c.say("butterworth", "제국 소시지, 엘프 꿀빵, 신전 성찬 빵. 세 가게를 다 맛보고, 어디가 제일인지 알려 주렴.")
				await c.say("neoul", "세라. 이것은 하늘이 내린 사명이니라.", "happy")
				c.close_box()
				c.quest_start("st_cook_off")
			elif st == 1 and Quests.step("st_cook_off") >= 1:
				await _cook_judge(c)
			elif st == 1:
				var n := 0
				for w in ["leonie", "elarien", "aurelia"]:
					if c.has("st_cook_" + w):
						n += 1
				await c.say("butterworth", "맛본 가게는 %d/3. 천천히 꼭꼭 씹어 먹고 오렴." % n)
			else:
				await c.say("butterworth", "심사 고마웠다! 내 국도 한 그릇 하고 가렴.", "happy")
		"trial":
			await c.say("butterworth", "밥은 먹고 다니니? 싸우는 사람일수록 든든히 먹어야 해.", "sad")
			await c.say("butterworth", "주먹밥 싸 줄 테니 들고 가렴.")
			c.close_box()
			GameState.heal_full()
			c.player.restore_from_state()
			Story.toast("체력이 가득 찼다.", 1.6)
		"epi":
			await _rebuild_help(c, "butterworth")
		_:
			await c.say("butterworth", "…", "sad")
	c.close_box()


func _cook_judge(c: Cut) -> void:
	await c.say("butterworth", "그래, 어디가 제일이었니?")
	var i := await c.choose("sera", "가장 맛있었던 건…", ["제국 소시지", "엘프 꿀빵", "신전 성찬 빵", "…셋 다 1등!"])
	c.close_box()
	match i:
		0: await c.say("butterworth", "역시 고기지! 레오니 단장한테 전해 줘야겠구나.", "happy")
		1: await c.say("butterworth", "꿀빵이라… 단 게 당겼구나. 엘라리엔이 귀까지 빨개지겠어.", "happy")
		2: await c.say("butterworth", "담백한 걸 고를 줄 알다니, 어른이 다 됐구나.", "happy")
		_: await c.say("butterworth", "아이고, 심사위원이 이러면 어쩌니! …하하, 그래도 그게 정답이지.", "happy")
	await c.say("butterworth", "자, 심사위원 상이다. 든든한 한 끼야. 남기지 마라!")
	c.close_box()
	await c.quest_done("st_cook_off")


# ─── 이졸데의 무도회 ────────────────────────────────────

func npc_isolde_ch5(c: Cut) -> void:
	match _phase(c):
		"fest":
			if Quests.state("st_isolde_dance") == 0:
				await c.say("isolde", "…세라. 잠깐. 저녁 무도회 말인데.")
				await c.say("isolde", "연습 상대가 필요해. 고급반 애들은 다 발을 밟는다고. 너라면… 밟혀도 상관없으니까.", "smug")
				c.close_box()
				c.quest_start("st_isolde_dance")
				await _isolde_dance(c)
			else:
				await c.say("isolde", "…연습한 대로 해. 저녁에 발 밟으면 얼려 버릴 거야.", "smug")
		"trial":
			if c.has("st_key_s"):
				await c.say("isolde", "정원의 별은 끝났어. 나머지 셋도 빨리 끝내고 와. …기다리는 거 아니야.", "smug")
			else:
				await c.say("isolde", "정원 쪽 별의 문이야. 엠버린 교수님이랑 먼저 가 있을게.")
		"epi":
			await _rebuild_help(c, "isolde")
		_:
			await c.say("isolde", "……", "sad")
	c.close_box()


func _isolde_dance(c: Cut) -> void:
	await c.say("isolde", "오른손은 여기. 왼손은… 거기. 박자는 셋. 하나, 둘—")
	var score := 0
	var a := await c.choose("sera", "첫 박자!", ["한 발 앞으로", "한 바퀴 돌기", "가만히 있기"])
	if a == 0:
		score += 1
		await c.say("isolde", "…그래, 그거야.")
	else:
		await c.say("isolde", "아니, 그건 셋째 박자고!", "angry")
	var b := await c.choose("sera", "둘째 박자!", ["손을 놓기", "손을 들어 이졸데를 돌리기", "발을 밟기"])
	if b == 1:
		score += 1
		await c.say("isolde", "…! 제법이네.", "surprised")
	elif b == 2:
		await c.say("isolde", "아야! 일부러지?!", "angry")
	else:
		await c.say("isolde", "놓으면 어떡해!", "angry")
	var d := await c.choose("sera", "마지막 박자!", ["인사하며 마무리", "그대로 불꽃 한 발", "웃기"])
	if d == 0:
		score += 1
	elif d == 2:
		await c.say("isolde", "…왜 웃어. 바보.", "smug")
	c.close_box()
	if score >= 2:
		await c.say("isolde", "흥. 폐급치고는 나쁘지 않아. …아니, 폐급이란 말은 취소할게. 오래전에 했어야 했는데.", "happy")
	else:
		await c.say("isolde", "…연습이 더 필요하네. 그래도, 같이 춰 준 건 고마워.", "smug")
	await c.say("isolde", "이거 받아. 무도회 상대 사례. 고급반에서 쓰다 남은 마도석이야. 어디까지나 남은 거야.")
	c.close_box()
	await c.quest_done("st_isolde_dance")


# ─── 오필리아의 별 관측 ─────────────────────────────────

func npc_ophelia_ch5(c: Cut) -> void:
	if await _letter(c, "ophelia"):
		return
	match _phase(c):
		"fest":
			if Quests.state("st_ophelia_stars") == 0:
				await c.say("ophelia", "어머~ 세라. 마침 잘 왔어. 별 보는 사람이 한 명 더 필요했거든~")
				c.close_box()
				c.quest_start("st_ophelia_stars")
				await _ophelia_stars(c)
			else:
				await c.say("ophelia", "저 별~ 아직도 가까워지고 있어~ 신기하지~?")
		"trial":
			await c.say("ophelia", "별의 정원은 내 별 관측 수업 뜰이야~ 별은 아래에서 위로, 가까운 것부터 이어~")
		_:
			await c.say("ophelia", "별이 다시 제자리로 돌아갔네~ 다행이야~", "happy")
	c.close_box()


func _ophelia_stars(c: Cut) -> void:
	await c.say("ophelia", "저기 봐~ 저건 구미호자리. 꼬리가 아홉 개라 별도 아홉 개야~")
	await c.say("neoul", "(…흥. 잘 아는구나, 이 졸린 마녀.)", "smug")
	await c.say("ophelia", "그리고 저쪽은 마녀의 모자자리~ 끝에 매달린 별이 제일 밝지~")
	await c.say("ophelia", "그런데 이상하지~ 오늘 저녁부터 별 하나가 너무 가까워. 어젯밤보다 손가락 한 마디만큼~", "surprised")
	await c.say("sera", "별이 가까워진다는 게… 무슨 뜻이에요?")
	await c.say("ophelia", "글쎄~ 별이 걸어 내려오는 건 아니겠지~? …아니겠지~?")
	await c.say("neoul", "세라. 저 별의 빛… 네 불 속의 냄새와 같구나.")
	c.close_box()
	await c.say("ophelia", "같이 봐 줘서 고마워~ 이건 별 관측반 출석 도장 대신이야~", "happy")
	c.close_box()
	await c.quest_done("st_ophelia_stars")
