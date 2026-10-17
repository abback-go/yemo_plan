extends "res://story/ch2/common.gd"
## 2장 대본 — 12. 학교 인물 2장 덮어쓰기(npc_<who>_ch2) · 버터워스·그레타 서브.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 12. 학교 인물 — 2장 덮어쓰기 (npc_<who>_ch2) · 서브 퀘스트(버터워스·그레타)
# ═══════════════════════════════════════════════════════════

func npc_emberlyn_ch2(c: Cut) -> void:
	var room := _room(c)
	if room.begins_with("s_"):
		if c.has("k_crypt_seen") and not GameState.has_ability("ward"):
			await c.say("emberlyn", "레오니 단장에게 막는 법부터 배워 오라는 소리를 들었다며?", "smug")
			await c.say("emberlyn", "중앙 홀 수업 게시판에서 '불꽃 방벽'을 신청해라. 실습장에서 기다리마.")
		elif c.has("k_beast_down"):
			await c.say("emberlyn", "레오니 단장이 너를 '세라'라고 불렀다더군. …그 사람에게 그건 훈장 같은 거다.", "happy")
		else:
			await c.say("emberlyn", "제국 일은 잘 되어 가니? 무리하지 마라. 전이진은 언제든 열려 있다.")
		return
	if c.has("k_beast_down"):
		await c.say("emberlyn", "잘했다, 세라. 정말로.", "happy")
	elif c.has("k_duel_called"):
		await c.say("emberlyn", "…결투라니. 레오니 단장다운 방식이군.", "sad")
		await c.say("emberlyn", "세라. 이기라고는 안 하마. 네 불이 무엇인지만 보여 주고 와라.")
	elif c.has("k_crypt_seen") and not GameState.has_ability("ward"):
		await c.say("emberlyn", "별 수정 장벽? 되받아쳐야 깨진다면 방벽이 답이다.")
		await c.say("emberlyn", "학교로 가자. 전이진 → 중앙 홀 게시판 → '불꽃 방벽'. 실습장에서 가르쳐 주마.")
	elif c.has("k_walls_talk"):
		await c.say("emberlyn", "지붕 위라. 날개를 믿어라. 굴뚝 열기는 생각보다 세다.")
	elif c.has("k_spar_done"):
		await c.say("emberlyn", "단장과 붙었다고? …살아 돌아왔구나.", "surprised")
		await c.say("emberlyn", "검 한 번 막지 못했다는 얼굴이군. 학교 게시판에 '불꽃 방벽' 수업을 열어 두었다. 원하면 언제든.", "smug")
	else:
		await c.say("emberlyn", "기사단 연무장은 시장 지나 동쪽이다. 단장에게 예의 바르게 굴어라. …특히 너, 세라.")


func npc_pippa_ch2(c: Cut) -> void:
	if _room(c) == "k_embassy":
		GameState.potions = GameState.potions_max
		c.sfx("potion")
		Story.toast("피피가 물약을 가득 채워 주었다.", 2.0)
		var lines := [
			"물약 보급 완료! 이번 건 제국 별향신료를 살짝 넣었어. 맛은… 반짝반짝해!",
			"시장 구경했어? 별 사탕 진짜 별 맛 나! 별 맛이 뭔지는 모르겠지만!",
			"이졸데가 밤에 몰래 지붕에서 연습하는 거 봤다? 쉿, 비밀이야~",
		]
		if c.has("k_beast_down"):
			lines = ["세라! 운석 괴물이랑 싸웠다며! 다친 데 없어? 물약 더 줄까? 열 병? 스무 병?"]
		elif c.has("k_duel_called"):
			lines = ["…결투라니. 세라, 진짜 갈 거야? …그럼 물약 세 배로 챙겨. 아니, 네 배!"]
		await c.say("pippa", String(lines[randi() % lines.size()]), "happy")
		return
	if not c.has("k_departed"):
		await c.say("pippa", "제국 가면 시장부터 가자! 별향신료! 별 사탕! 별… 아무튼 다!", "happy")
	else:
		await c.say("pippa", "학교에 볼일 있어서 왔어? 나는 연금술실 재료 가지러! 금방 공관으로 돌아갈 거야~", "happy")


func npc_isolde_ch2(c: Cut) -> void:
	var room := _room(c)
	if room == "k_roof_1" and Quests.state("k_isolde_race") == 1 and not c.has("k_race_won"):
		await _race_start(c)
		return
	if room == "k_embassy":
		var q := Quests.state("k_isolde_race")
		if q == 0 and c.has("k_clock_arrived"):
			await c.say("isolde", "…폐급. 지붕 위를 날아다닌다며.")
			await c.say("isolde", "날개 수업은 내가 작년에 수석으로 통과했어. 누가 더 빠른지 — 겨뤄 볼래?", "smug")
			var i := await c.choose("isolde", "굴뚝 숲에서 시계 거리 지붕까지. 2분.", ["좋아, 해 보자", "다음에"])
			if i == 0:
				c.quest_start("k_isolde_race")
				c.flag("k_race_ready")
				await c.say("isolde", "굴뚝 숲 지붕(성벽 서쪽 끝이나 뒷골목 사다리)에서 기다릴게. 도망치지 마.")
				c.close_box()
				c.hide_actor("isolde")
			else:
				await c.say("isolde", "흥. 겁나는 거지.", "smug")
			return
		if c.has("k_race_won"):
			await c.say("isolde", "…세라. 다음 경주는 내가 이길 거야. 지붕 위에서 연습 중이니까.", "smug")
			return
		if c.has("k_duel_called") and not c.has("k_duel_done"):
			await c.say("isolde", "결투라며. …바보야? 기사단장이랑 진검으로?", "angry")
			await c.say("isolde", "…지지 마. 폐급한테 진 내 체면도 생각해.", "sad")
			return
		await c.say("isolde", "말 걸지 마. 바빠.", "smug")
		return
	if room == "s_cafeteria":
		await c.say("isolde", "밥 먹는 중이야.", "smug")
		return
	await c.say("isolde", "…제국 일이나 신경 써. 나도 곧 공관으로 갈 거니까.")


func npc_butterworth_ch2(c: Cut) -> void:
	var q := Quests.state("k_spice")
	if q == 1 and c.has("k_spice_got"):
		await c.say("butterworth", "어머나, 별향신료! 이 냄새 얼마 만이야! 시장 그 녀석, 아직 장사하는구나!", "happy")
		c.close_box()
		await c.quest_done("k_spice")
		await c.say("butterworth", "오늘 저녁은 별향신료 스튜다! 먼저 한 그릇 먹고 가. 힘이 불끈 날 거야!", "happy")
		c.emote("neoul", "heart")
		return
	if q == 0 and c.has("k_departed"):
		await c.say("butterworth", "제국에 간다고? 그럼 부탁 하나 하자. 시장에 '별향신료'라는 게 있어.")
		await c.say("butterworth", "젊었을 때 제국에서 먹어 본 맛인데… 그걸로 학교 저녁을 만들고 싶구나. 시장 향신료 상인한테 내 이름 대렴.", "happy")
		c.quest_start("k_spice")
		return
	if q == 1:
		await c.say("butterworth", "별향신료는 제국 시장 상인한테! 내 이름 대면 알 거야.")
		return
	if not c.has("k_breakfast"):
		await c.say("butterworth", "아이고, 우리 영웅님! 앉아, 앉아. 오늘은 곱빼기다!", "happy")
	else:
		await c.say("butterworth", "밥은 먹고 다니니? 그 여우도? 둘 다 말랐어!", "happy")


func npc_greta_ch2(c: Cut) -> void:
	var q := Quests.state("k_greta_books")
	var n := _book_count()
	if q == 1 and n >= 3:
		await c.say("greta", "…세 권. 전부.", "surprised")
		await c.say("greta", "『은사자 전기』, 『시간을 거스르는 태엽』, 『빛의 기도서(어린이용)』. 연체 기간 합계 십일 년.")
		await c.say("greta", "…고맙다.", "happy")
		c.close_box()
		await c.quest_done("k_greta_books")
		c.emote("hodu", "!")
		return
	if q == 0 and c.has("k_departed"):
		await c.say("greta", "…제국에 간다지.")
		await c.say("greta", "학교 책 세 권이 몇 년째 제국에서 돌아오지 않았다. 기사단, 시계 공방, 대성당에 빌려준 것.")
		await c.say("greta", "찾으면 가져와라. …화난 건 아니다.", "angry")
		c.quest_start("k_greta_books")
		c.quest_step("k_greta_books", mini(n, 3))
		return
	if q == 1:
		await c.say("greta", "…%d권. 아직 %d권." % [n, 3 - n])
		return
	await c.say("greta", "…도서관에서는 조용히.")


func k_book_got(c: Cut) -> void:
	var n := _book_count()
	if Quests.state("k_greta_books") == 1:
		c.quest_step("k_greta_books", mini(n, 3))
		c.bubble("그레타의 책이다. %d권째구나." % n, 2.4)
	else:
		c.bubble("마녀학교 도서관 도장이 찍혀 있구나. 그레타에게 돌려주자.", 2.6)


func npc_astrid_ch2(c: Cut) -> void:
	if c.has("k_brooch_broken"):
		await c.say("astrid", "…브로치가 깨졌군요.")
		await c.say("astrid", "그럼 됐어요. 그 별은 제 몫을 다했으니까. 사과하지 말아요, 세라. 고맙다고 해 줘요.", "happy")
	elif c.has("k_departed"):
		await c.say("astrid", "제국은 어떤가요? 레오니 단장은… 예전 그 아이 그대로겠죠. 칼끝처럼 곧은.")
		await c.say("astrid", "브로치는 잘 지니고 있나요? …한 번쯤은, 이라고 했던 거 잊지 말아요.")
	else:
		await c.say("astrid", "손님이 기다리고 계세요, 세라.")


func npc_mirabel_ch2(c: Cut) -> void:
	await c.say("mirabel", "제국에 다녀온다면서요? 다치면 바로 돌아와요! 공관 전이진 있잖아요~", "happy")
	await c.say("mirabel", "…여우는 그래도 침대에 올리지 말고요.")


func npc_ophelia_ch2(c: Cut) -> void:
	if GameState.has_ability("wings"):
		await c.say("ophelia", "날개는 잘 쓰고 있니~? 제국 굴뚝 바람은 학교 바람보다 따뜻하지~", "happy")
	else:
		await c.say("ophelia", "날개 수업은 게시판에서 신청하렴~ 중앙 홀이야~ 쿨…")


func npc_veronica_ch2(c: Cut) -> void:
	await c.say("veronica", "제국 파견이라. 돌아오면 고급반 수업도 생각해 봐라. …아직은 이르지만.")
