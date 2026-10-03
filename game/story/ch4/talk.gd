extends "res://story/ch4/base.gd"
## 4장 인물 대화·서브 퀘스트 대본 (docs/chapter4.md 6절·7.7절). 메인 이야기는 story/scripts_ch4.gd.
## 말투(docs/bible/characters.md): 베네딕타 온화한 존댓말 · 루카 수줍은 존댓말 · 그레고르 귀가 어두워 크게("!") ·
## 엘사(성가대) 조용한 존댓말 · 안셀름 느긋한 하오체 · 순례자들 하오체/해요체 · 레오니 짧고 단정한 반말 · 아우렐리아 차가운 존댓말.


# ═══════════════════════════════════════════════════════════
# 순례길 사람들
# ═══════════════════════════════════════════════════════════

func npc_tp_pilgrim(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("tp_pilgrim", "어젯밤 산 위에서 종소리가 들리더이다. 열흘 만에.")
		await c.say("tp_pilgrim", "…마녀 아가씨가 무슨 일을 했는지는 모르겠지만, 고맙소.", "happy")
	elif c.has("tp_gate_open"):
		await c.say("tp_pilgrim", "문이 열렸다고? 허허, 수호자님이 마녀를 들이시다니. 세상이 바뀌는구먼.", "happy")
		await c.say("tp_pilgrim", "정문 옆 계단으로 내려오면 여기까지 금방이오. 늙은이 무릎에도 고마운 길이지.")
	else:
		await c.say("tp_pilgrim", "젊은이들, 대신전에 가는 게요? 소용없소. 수호자님이 문을 닫으셨다오. 열흘째.")
		await c.say("tp_pilgrim", "…그래도 오르겠다면, 길 잃은 하얀 그림자를 만나거든 불을 비춰 주시오.")
		await c.say("tp_pilgrim", "그들도 다 순례자였다오. 빛을 찾다가, 빛을 잃은 사람들.", "sad")
	c.close_box()


func npc_tp_pilgrim_b(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("tp_pilgrim_b", "하얀 사람들이 하나둘 돌아오고 있대요. 우리 마을 대장장이 아저씨도요!", "happy")
	else:
		await c.say("tp_pilgrim_b", "어젯밤 쉼터 밖에서 하얀 사람을 봤어요. 우리 마을 대장장이 아저씨였어요.")
		await c.say("tp_pilgrim_b", "등불을 든 채로 '빛이 안 보인다'고 중얼거리면서… 저를 못 알아보더라고요.", "sad")
		await c.say("sera", "…쓰러뜨리면, 풀려나는 것 같았어. '고맙다'고 하면서.")
		await c.say("tp_pilgrim_b", "정말요? …그럼, 부탁해요. 아프게 하지 말고요.", "sad")
	c.close_box()


func npc_tp_pilgrim_nave(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("tp_pilgrim_b", "수호자님이 웃으셨다고요? …에이, 거짓말.", "surprised")
	elif c.has("tp_aurelia_talk"):
		await c.say("tp_pilgrim_b", "수호자님이 내전으로 올라가셨어요. 마지막 기도를 올린다고… 무서운 얼굴이었어요.", "sad")
	else:
		await c.say("tp_pilgrim_b", "수호자님은 하루 종일 저렇게 기도만 하세요. 무릎에 피가 배어도.", "sad")
		await c.say("tp_pilgrim_b", "대답이 없는 기도를… 열흘째요.")
	c.close_box()


func npc_tp_anselm(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("tp_anselm", "다녀오셨구려. 산 위가 한결 따뜻해진 것 같소.", "happy")
		await c.say("tp_anselm", "불 앞에 앉아 쉬다 가시오. 쉼터는 원래 그러라고 있는 거요.")
	else:
		await c.say("tp_anselm", "몸을 녹이고 가시오. 기록은 저 촛불에 남기면 되오.")
		await c.say("tp_anselm", "이 쉼터는 초대 대사제가 세웠소. 누구든 쉬어 갈 수 있다고. 마녀든, 기사든, 여우든.")
		c.emote("neoul", "!")
		await c.say("neoul", "…이 중이 날 보는구나?")
		await c.say("tp_anselm", "허허. 산에 오래 살면 이것저것 보이는 법이오.", "happy")
	c.close_box()


# ═══════════════════════════════════════════════════════════
# 대신전 사람들
# ═══════════════════════════════════════════════════════════

func npc_benedicta(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("benedicta", "그 아이가 웃었다지요.", "happy")
		await c.say("benedicta", "열 살에 이 신전에 와서… 한 번도 웃지 않던 아이가. 살아서 그 얼굴을 보게 될 줄은 몰랐어요.", "happy")
		c.close_box()
		return
	if not c.has("tp_bene_met"):
		c.flag("tp_bene_met")
		await c.say("benedicta", "세라 양. 시련은 순서가 없답니다.")
		await c.say("benedicta", "빛의 거울은 회랑 왼쪽, 종탑은 정원과 성가대석 너머, 기록실은 이 계단 아래예요.")
	if Quests.state("tp_candles") == 0:
		await c.say("benedicta", "…그리고, 부탁이 하나 있어요.")
		await c.say("benedicta", "루멘께서 침묵하신 뒤로 신전 곳곳의 기도 촛불이 꺼졌답니다. 수도사들이 다시 붙여도 금세 꺼져요.", "sad")
		await c.say("benedicta", "마녀의 불이라면… 혹시, 붙을지도 모르겠어요.")
		var i := await c.choose("benedicta", "촛불 다섯 개. 정원, 거울의 방, 종탑, 필사실, 수도사 숙소에 있어요.", ["맡겨 주세요!", "나중에요"])
		if i == 0:
			c.quest_start("tp_candles")
			if _candles_lit() >= 5:
				c.quest_step("tp_candles", 1)
				await tp_candles_done(c)
				return
			await c.say("benedicta", "고마워요. 빛은… 누가 붙였는지 묻지 않을 거예요.", "happy")
		else:
			await c.say("benedicta", "언제든지요. 촛불은 기다려 줄 테니까요.")
	elif Quests.active("tp_candles"):
		await c.say("benedicta", "촛불이 %d개 다시 타고 있어요. 정원, 거울의 방, 종탑, 필사실, 수도사 숙소…" % _candles_lit())
	else:
		await c.say("benedicta", "아우렐리아는 열 살에 이 신전에 왔어요. 그때부터 한 번도 웃지 않았지요.")
		await c.say("benedicta", "흔들리지 않는 수호자가 되겠다고. …그 아이가 지금 가장 흔들리고 있답니다.", "sad")
	c.close_box()


func tp_candle_lit(c: Cut) -> void:
	var n := _candles_lit()
	c.sfx("bell_small")
	Story.toast("기도 촛불이 다시 타오른다. (%d/5)" % n, 2.4)
	if n >= 5 and Quests.active("tp_candles") and Quests.step("tp_candles") == 0:
		c.quest_step("tp_candles", 1)
		c.bubble("다섯 개 다 켰구나. 그 늙은 사제에게 알려 주거라.", 3.0)


func tp_candles_done(c: Cut) -> void:
	await c.say("benedicta", "…느껴져요. 신전 곳곳에서 촛불이 숨 쉬는 게.", "happy")
	await c.say("benedicta", "루멘께서 대답하지 않으셔도, 우리가 불을 지키면 빛은 남아요. 고마워요, 세라 양.", "happy")
	c.close_box()
	await c.quest_done("tp_candles")


func npc_leonie_ch4(c: Cut) -> void:
	if c.has("ch4_done"):
		await c.say("leonie", "세라. 몸은 괜찮나. …그날 첨탑에서, 나쁘지 않았다.")
		c.close_box()
		return
	var n := _trials_count()
	if Quests.active("tp_leonie_badge") and Quests.step("tp_leonie_badge") == 0:
		await c.say("leonie", "배지 얘기는 잊어라. 이십 년 전 일이다.")
		await c.say("leonie", "…찾아 준다면, 고맙겠지만.")
	elif n == 0:
		await c.say("leonie", "두 손가락이었다. 내 검을.")
		await c.say("leonie", "…분하지만, 저 사람은 강하다. 시련은 너 혼자라지. 기다리는 건 익숙하지 않다.")
	else:
		await c.say("leonie", "%d개째군. 나쁘지 않다." % n)
		await c.say("leonie", "수도사들에게 들었다. 수호자가 열흘째 잠을 자지 않는다고. …신앙이 사람을 저렇게 깎아 내기도 하는군.")
	c.close_box()


func npc_tp_priest(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("tp_priest", "수호자님이 다시 아침 기도를 이끄셨습니다. 목소리가… 전보다 부드러웠어요.", "happy")
	else:
		await c.say("tp_priest", "어서 오세요, 시련을 치르는 분. 회랑의 석판에 지금까지 마친 시련이 새겨집니다.")
		await c.say("tp_priest", "회랑의 성수반은 누구나 쓸 수 있어요. 마녀님도요. …아마도.")
	c.close_box()


func npc_tp_monk_cloister(c: Cut) -> void:
	await c.narrate("수도사는 고개를 숙인 채 묵상하고 있다. 입술만 조용히 움직인다.")
	await c.narrate("「…빛이시여, 대답이 없으셔도 저희는 여기 있습니다…」")
	c.close_box()


func npc_tp_monk_cells(c: Cut) -> void:
	await c.narrate("수도사가 손바닥만 한 석판에 분필로 글을 쓴다.")
	if c.has("tp_aurelia_defeated"):
		await c.narrate("「오늘은 푹 잤습니다. 종소리 덕분에.」")
	elif _candles_lit() >= 5:
		await c.narrate("「촛불이 돌아왔군요. 침묵 서원이 아니었다면 소리 내어 감사했을 겁니다.」")
	else:
		await c.narrate("「침묵 서원 중. 촛불이 꺼진 뒤로 잠을 못 잡니다. 저 안쪽 촛불도요.」")
	c.close_box()


func npc_tp_scribe(c: Cut) -> void:
	if c.has("tp_archive_read"):
		await c.say("tp_monk", "가장 깊은 서고의 기록을 읽으셨군요. …그건 초대 대사제의 글입니다.")
		await c.say("tp_monk", "우리 필사 수도사들은 대대로 그 기록만은 베끼지 않았습니다. 베끼면 퍼질까 봐.", "sad")
	else:
		await c.say("tp_monk", "필사실입니다. 경전을 베껴 순례자들에게 나눠 주지요.")
		await c.say("tp_monk", "이상한 일입니다. 요즘 옛 경전을 베끼면 같은 구절에서 손이 떨려요. '빛이 약한 세계'라는 구절에서.")
	c.close_box()


func tp_trials_status(c: Cut) -> void:
	var marks: Array[String] = []
	for k: String in ["tp_trial_mirror", "tp_trial_bell", "tp_trial_archive"]:
		marks.append("금빛으로 새겨짐" if c.has(k) else "아직 비어 있음")
	await c.narrate("시련의 석판. 세 칸에 해 문양이 파여 있다.")
	await c.narrate("① 빛의 거울(회랑 왼쪽) — %s\n② 종탑(정원 → 성가대석 너머) — %s\n③ 기록실(회랑 아래) — %s" % [marks[0], marks[1], marks[2]])
	c.close_box()


## 회랑 성수반 (피피의 성수 실험)
func tp_font(c: Cut) -> void:
	if Quests.active("tp_pippa_water") and Quests.step("tp_pippa_water") == 0:
		await c.narrate("맑은 물 바닥에 금빛이 모래처럼 가라앉아 있다. 피피가 준 병에 조심스럽게 떠 담았다.")
		c.close_box()
		c.flag("tp_holy_water")
		c.sfx("pickup")
		await c.item("성수 한 병", "대신전 성수반의 물. 병 속에서 금빛이 천천히 돈다. 학교의 피피에게 가져다주자.")
		c.quest_step("tp_pippa_water", 1)
	else:
		await c.narrate("맑은 물 바닥에 금빛이 모래처럼 가라앉아 있다. 손을 담그니 따뜻하다.")
		c.close_box()


# ─── 루카: 잃어버린 종 추 ────────────────────────────────

func npc_luca(c: Cut) -> void:
	if Quests.done("tp_luca_clapper"):
		await c.say("luca", "그 종 추, 제가 처음으로 맡은 종 거예요. 그레고르 할아버지가 '네 종'이라고 하셨거든요.", "happy")
		c.close_box()
		return
	if Quests.state("tp_luca_clapper") == 0:
		await c.say("luca", "아, 마녀님! 저, 루카예요. 견습 사제고요.")
		await c.say("luca", "저기… 혹시 종탑에 가시면, 종 추 하나만 찾아 주실 수 있어요?")
		await c.say("luca", "청소하다가 들보에서 떨어뜨렸는데… 망령이 무서워서 못 올라가겠어요.", "sad")
		c.quest_start("tp_luca_clapper")
		if c.has("tp_clapper_found"):
			await c.say("sera", "혹시 이거? 끈에 '루카'라고 적혀 있던데.")
			c.quest_step("tp_luca_clapper", 1)
			await tp_luca_return(c)
			return
		await c.say("luca", "종탑 아래층이에요. 위쪽 들보 근처에…")
	else:
		await c.say("luca", "종탑 아래층이에요. 위쪽 들보 근처에…! 망령은 진짜 종소리를 무서워해요.")
	c.close_box()


func tp_clapper_found(c: Cut) -> void:
	if Quests.active("tp_luca_clapper"):
		c.quest_step("tp_luca_clapper", 1)
		c.bubble("루카의 종 추로구나. 정원으로 가져다주거라.", 3.0)
	else:
		c.bubble("종 추로구나. 끈에 '루카'라고 적혀 있다니라.", 3.0)


func tp_luca_return(c: Cut) -> void:
	await c.say("luca", "그거예요! 제 종 추!", "happy")
	c.emote("luca", "heart")
	await c.say("luca", "감사합니다, 마녀님. 마녀는 무섭다고 배웠는데… 하나도 안 무서워요.", "happy")
	await c.say("neoul", "흥. 이 아이는 무섭게 굴 때가 따로 있느니라.")
	c.close_box()
	await c.quest_done("tp_luca_clapper")


# ─── 그레고르: 종 조율 ──────────────────────────────────

func npc_gregor(c: Cut) -> void:
	if Quests.done("tp_gregor_bells"):
		await c.say("gregor", "종소리가 맑다! 들린다고! …아니, 사실 잘 안 들려! 하하!", "happy")
		c.close_box()
		return
	if Quests.state("tp_gregor_bells") == 0:
		await c.say("gregor", "뭐라고?! 크게 말해!")
		await c.say("sera", "안! 녕! 하! 세! 요!")
		await c.say("gregor", "그래, 안녕하다! 시련을 치러 온 아가씨로구먼!")
		if not c.has("tp_trial_bell"):
			await c.say("gregor", "큰 종은 저 가운데 거다! 아래에서 불로 쳐! 망령 놈들이 방해할 거다!")
		await c.say("gregor", "그리고 말이야! 저 작은 종 셋! 소리가 다 틀어졌어! 내 귀로는 이제 못 맞춰!", "sad")
		await c.say("gregor", "아가씨가 쳐 봐! 높은 거, 낮은 거, 가운데, 다시 높은 거! 그 차례로! 박자 놓치지 말고!")
		await c.say("sera", "높은 게 어느 거예요?!")
		await c.say("gregor", "제일 오른쪽! 낮은 건 큰 종 바로 옆! 가운데는 가운데!")
		c.quest_start("tp_gregor_bells")
	else:
		await c.say("gregor", "높은 거! 낮은 거! 가운데! 다시 높은 거! 오른쪽 끝, 큰 종 옆, 그 사이!")
	c.close_box()


func tp_gregor_tuned(c: Cut) -> void:
	Story.toast("작은 종 셋의 소리가 맑게 어우러졌다!", 2.6)
	if Quests.active("tp_gregor_bells") and Quests.step("tp_gregor_bells") == 0:
		c.quest_step("tp_gregor_bells", 1)


func tp_gregor_done(c: Cut) -> void:
	await c.say("gregor", "들었어! 이번엔 들었다고! 높은 거, 낮은 거, 가운데, 높은 거!", "happy")
	await c.say("gregor", "사십 년 종을 쳤는데, 마녀가 맞춰 준 건 처음이다! 고맙다, 아가씨!", "happy")
	c.close_box()
	await c.quest_done("tp_gregor_bells")


# ─── 엘사(성가대): 사라진 성가대원 ──────────────────────

func npc_tp_choir(c: Cut) -> void:
	if Quests.done("tp_choir_voice"):
		await c.say("tp_choir", "마리가 돌아왔어요! 끝 소절도 기억났대요.", "happy")
		await c.say("tp_choir", "오늘 저녁 성가는 둘이서 불러요. …대답이 없어도요.", "happy")
		c.close_box()
		return
	if Quests.state("tp_choir_voice") == 0:
		await c.say("tp_choir", "…마리가 돌아오지 않아요.", "sad")
		await c.say("tp_choir", "성가 끝 소절을 자꾸 잊어버린다고, 순례길 얼음 사당에서 연습하겠다고 나갔는데…")
		await c.say("tp_choir", "요즘 순례길에 하얀 그림자가 나온대요. 혹시 마리도…", "sad")
		c.quest_start("tp_choir_voice")
		if c.has("tp_choir_found"):
			await c.say("sera", "…바람의 능선 사당 곁에서, 노래를 흥얼거리던 그림자가 있었어. 풀려나면서 성가대로 돌아간다고 했어.")
			c.quest_step("tp_choir_voice", 1)
			await tp_choir_done(c)
			return
		await c.say("tp_choir", "바람의 능선 너머예요. 끊긴 다리 건너편에 얼음 사당이 있어요.")
	else:
		await c.say("tp_choir", "바람의 능선, 끊긴 다리 건너편 얼음 사당이요…")
	c.close_box()


func tp_choir_found(c: Cut) -> void:
	if Quests.active("tp_choir_voice"):
		c.quest_step("tp_choir_voice", 1)
		c.bubble("성가대로 돌아간다 하는구나. 그 엘사라는 아이에게 알려 주자꾸나.", 3.2)
	else:
		c.bubble("…성가대로 돌아간다고? 신전 사람이었던 게로구나.", 3.0)


func tp_choir_done(c: Cut) -> void:
	await c.say("tp_choir", "마리가…! 정말요?", "surprised")
	c.sfx("bell_small")
	await c.narrate("성가대석 뒤에서 하얀 옷의 소녀가 숨을 헐떡이며 뛰어 들어온다. 엘사가 달려가 끌어안는다.")
	await c.say("tp_choir", "고마워요… 정말로. 이거, 성가대가 순례자에게 주는 물약 주머니예요. 길에서 쓰세요.", "happy")
	c.close_box()
	await c.quest_done("tp_choir_voice")


func npc_tp_choirmaster(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("tp_priest", "성가가 다시 울립니다. 대답이 없어도, 부르는 것을 멈추지 않기로 했습니다.", "happy")
	else:
		await c.say("tp_priest", "성가는 빛을 부르는 노래입니다. …요즘은 대답이 없지만요.")
		await c.say("tp_priest", "종탑은 저쪽입니다. 그레고르 영감이 꼭대기에 있을 거예요. 크게 말하세요.")
	c.close_box()


# ─── 레오니: 견습 기사의 배지 ────────────────────────────

func tp_badge_found(c: Cut) -> void:
	var a := _leonie(c)
	if a == null:
		if Quests.state("tp_leonie_badge") == 0:
			c.quest_start("tp_leonie_badge")
		c.quest_step("tp_leonie_badge", 1)
		c.bubble("레오니의 배지로구나. 돌려주자꾸나.", 3.0)
		return
	c.lock()
	if Quests.state("tp_leonie_badge") == 0:
		c.quest_start("tp_leonie_badge")
	c.quest_step("tp_leonie_badge", 1)
	await tp_badge_return(c)


func tp_badge_return(c: Cut) -> void:
	await c.say("sera", "레오니! 이거. 동굴 안쪽에 있었어.", "happy")
	await c.say("leonie", "……")
	await c.say("leonie", "…이걸, 어떻게.", "surprised")
	await c.say("leonie", "신부님이 양철을 두드려 만들어 준 가짜 배지다. 진짜 기사가 된 날까지 품고 다녔는데… 그 동굴에서 잃었다.")
	await c.say("leonie", "…고맙다, 세라.")
	c.emote("neoul", "note")
	await c.say("neoul", "흥. 감동이 짧구나, 기사 계집.")
	await c.say("leonie", "칭찬은 한 번이면 된다.", "happy")
	c.close_box()
	await c.quest_done("tp_leonie_badge")


# ═══════════════════════════════════════════════════════════
# 학교 (4장 덮어쓰기 npc_<who>_ch4 · 퀘스트 걸이)
# ═══════════════════════════════════════════════════════════

func npc_pippa_ch4(c: Cut) -> void:
	if c.has("ch4_done"):
		await c.say("pippa", "세라! 성수 실험 결과 나왔어! 빛나는 물약이 됐는데… 마시면 눈에서 빛이 나!", "happy")
		await c.say("pippa", "…부작용이 좀 있지만 그건 다음 실험에서!", "happy")
	elif Quests.active("tp_pippa_water"):
		await c.say("pippa", "성수! 성수! 빛이 녹아 있는 물! 회랑의 성수반이랬지? 병 잃어버리지 마!", "happy")
	else:
		await c.say("pippa", "레오니 단장님 사인… 액자에 넣었어. 실험 노트째로.", "happy")
	c.close_box()


func tp_pippa_done(c: Cut) -> void:
	await c.say("pippa", "성수다아아!", "happy")
	c.emote("pippa", "heart")
	await c.say("pippa", "봐, 봐! 병 속에서 금빛이 돌아! 이건 빛이 액체에 녹아 있다는 증거야!", "happy")
	c.sfx("bubble")
	await c.narrate("피피가 성수 한 방울을 시험관에 떨어뜨리자, 시험관이 잠깐 해처럼 빛났다.")
	await c.say("pippa", "…눈 부셔. 대성공! 이건 답례야. 실험하다 남은 결정인데, 마도석 맞지?", "happy")
	c.close_box()
	await c.quest_done("tp_pippa_water")


func npc_butterworth_ch4(c: Cut) -> void:
	if Quests.active("tp_herbs"):
		await c.say("butterworth", "눈꽃 약초! 성산 골짜기, 바람이 솟는 데 핀단다. 수프에 넣으면 사흘은 안 춥지!", "happy")
	else:
		await c.say("butterworth", "많이 먹어라, 세라. 마녀는 배가 든든해야 불도 든든한 법이야.", "happy")
	c.close_box()


func tp_herb_found(c: Cut) -> void:
	if Quests.active("tp_herbs") and Quests.step("tp_herbs") == 0:
		c.quest_step("tp_herbs", 1)
	c.bubble("버터워스의 약초로구나. 수프… 꿀꺽.", 2.8)


func tp_herbs_done(c: Cut) -> void:
	await c.say("butterworth", "어머나, 눈꽃 약초! 이렇게 싱싱한 건 처음 보는구나!", "happy")
	await c.narrate("버터워스 아주머니가 커다란 국자로 원기 수프를 휘휘 젓는다. 하얀 꽃잎이 녹아들자 김에서 눈 냄새가 났다.")
	await c.say("butterworth", "자, 첫 그릇은 세라 거다. 남김없이!", "happy")
	await c.say("neoul", "…두 번째 그릇은 내 것이니라.")
	c.close_box()
	await c.quest_done("tp_herbs")


func npc_isolde_ch4(c: Cut) -> void:
	if c.has("ch4_done"):
		await c.say("isolde", "신전에서 무슨 일이 있었는지 들었어.")
		await c.say("isolde", "…무사해서 다행이라고 생각하는 건 아니야. 결투 상대가 없어지면 곤란할 뿐이지.", "angry")
	else:
		await c.say("isolde", "레, 레오니 경이 나를 기억하고 계셨어… 크레스트 가문의 서리 마법이 좋다고…", "surprised")
		await c.say("isolde", "…흥. 당연하지. 그, 그보다 너는 왜 그분이랑 그렇게 편하게 말하는 거야?!", "angry")
	c.close_box()


func npc_astrid_ch4(c: Cut) -> void:
	if c.has("ch4_done"):
		await c.say("astrid", "별빛 발판은 마음에 드셨나요?")
		await c.say("astrid", "…제 별은 아직 녹슬지 않았답니다. 라고 해 두죠.", "happy")
		await c.say("astrid", "그리고 세라. 그 사람이 당신을 뭐라고 불렀는지… 언젠가 제가 직접 이야기할게요. 조금만 기다려 주세요.", "sad")
	else:
		await c.say("astrid", "루멘의 침묵이라… 오래 살다 보면 알게 되죠. 신들도 늙는다는 걸.")
		await c.say("astrid", "레오니 경과 함께라면 걱정은 덜하지만… 조심하세요, 세라.")
	c.close_box()
