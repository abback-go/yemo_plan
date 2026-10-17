extends "res://story/ch5/common.gd"
## 5장 대본 — 인물 5장 덮어쓰기(npc_<who>_ch5) · 에필로그의 다시 세우기 도움.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ─── 그 밖의 학교 인물 (5장) ────────────────────────────

func npc_mirabel_ch5(c: Cut) -> void:
	if await _letter(c, "mirabel"):
		return
	match _phase(c):
		"fest":
			await c.say("mirabel", "축제 날엔 넘어지는 학생이 꼭 있어요. 다치면 천막으로 와요~", "happy")
		"trial":
			await c.say("mirabel", "교장 선생님은 제가 보고 있을게요. 세라 양은… 다치지 말고요. 약속이에요.", "sad")
			c.close_box()
			GameState.heal_full()
			c.player.restore_from_state()
			Story.toast("체력이 가득 찼다.", 1.6)
		"war":
			await c.say("mirabel", "다친 학생은 여기로! 세라 양, 당신도 숨 좀 돌려요!", "sad")
		_:
			await c.say("mirabel", "이제야 의무실이 한가해졌어요~ 이대로만 계속되면 좋겠네요.", "happy")
	c.close_box()


func npc_greta_ch5(c: Cut) -> void:
	if await _letter(c, "greta"):
		return
	match _phase(c):
		"fest":
			await c.say("greta", "축제 날에도 도서관은 연다. 불사조의 금서가 필요하면 말해라. 교장의 서명이 있어야 한다.")
		"trial":
			await c.say("greta", "별의 마녀… 리라. 기록에 이름이 한 줄 있다. 창립자의 제자. 그 뒤로는 아무것도.")
		"war":
			await c.say("greta", "…책은 두고 가지 않는다.")
		_:
			await c.say("greta", "재가 된 책은 다시 쓰면 된다. 사람은 그럴 수 없지. 다행이다.", "happy")
	c.close_box()


func npc_veronica_ch5(c: Cut) -> void:
	if await _letter(c, "veronica"):
		return
	match _phase(c):
		"fest":
			await c.say("veronica", "축제라도 결투장은 닫지 않는다. …불꽃놀이는 구경하지.")
		"trial":
			await c.say("veronica", "결계를 다시 친다. 교사들이 학교를 맡는다. 너는 네 할 일을 해라.")
		_:
			await c.say("veronica", "…잘했다. 한 번만 말한다.", "happy")
	c.close_box()


func npc_emberlyn_ch5(c: Cut) -> void:
	if await _letter(c, "emberlyn"):
		return
	match _phase(c):
		"fest":
			await c.say("emberlyn", "세라, 또 사고 쳤니? …아니, 오늘은 아무 일도 없었다고? 축제니까 믿어 주마.", "happy")
		"trial":
			if c.has("st_key_s"):
				await c.say("emberlyn", "정원의 별은 끝났다. 남은 별도 같은 마음으로 가라.")
			else:
				await c.say("emberlyn", "정원으로 가는 별의 문이다. 이졸데와 같이 들어가자.")
		"epi":
			await _rebuild_giver(c)
		_:
			await c.say("emberlyn", "…세라.", "sad")
	c.close_box()


func npc_astrid_ch5(c: Cut) -> void:
	match _phase(c):
		"fest":
			if not c.has("st_fest_ready"):
				await c.call_script("st_photo_scene")
				return
			await c.say("astrid", "축제는 즐기고 있나요? 저녁 불꽃놀이 때 내려가겠어요.", "happy")
		"trial":
			var left: Array = []
			for k in ["k", "e", "tp", "s"]:
				if not c.has("st_key_" + k):
					left.append({"k": "제국", "e": "세계수", "tp": "대신전", "s": "별의 정원"}[k])
			if left.is_empty():
				await c.say("astrid", "열쇠 넷이 모였군요. 가운데 계단이 열렸어요. …선배가 기다리고 있을 거예요.")
			else:
				await c.say("astrid", "남은 시련은 %s. 문마다 제가 작은 별을 달아 두었어요. 끝나면 곧장 이리로 돌아올 수 있게." % ", ".join(left))
			c.close_box()
			GameState.heal_full()
			c.player.restore_from_state()
			Story.toast("체력이 가득 찼다.", 1.6)
		"epi":
			if not c.has("st_tea_done"):
				await c.call_script("st_tea")
				return
			await c.say("astrid", "차가 식기 전에 선배랑 같이 마셔요. 오늘은 수업 없어요.", "happy")
		_:
			await c.say("astrid", "……", "tired")
	c.close_box()


func npc_leonie_ch5(c: Cut) -> void:
	if await _cook_taste(c, "leonie"):
		return
	match _phase(c):
		"fest":
			await c.say("leonie", "카엘이 소시지를 너무 많이 가져왔다. …다 팔 때까지 못 간다.")
		"trial":
			await c.say("leonie", "제국의 별은 내가 지킨다. 와라, 세라.")
		"epi":
			await _rebuild_help(c, "leonie")
		_:
			await c.say("leonie", "…아직 서 있다.")
	c.close_box()


func npc_elarien_ch5(c: Cut) -> void:
	if await _cook_taste(c, "elarien"):
		return
	match _phase(c):
		"fest":
			await c.say("elarien", "사람이 많다. 바람이 안 읽힌다. …꿀빵은 맛있다.")
		"trial":
			await c.say("elarien", "세계수 꼭대기에 별이 박혔다. 가지 위에서 기다리겠다.")
		"epi":
			await _rebuild_help(c, "elarien")
		_:
			await c.say("elarien", "…")
	c.close_box()


func npc_aurelia_ch5(c: Cut) -> void:
	if await _cook_taste(c, "aurelia"):
		return
	match _phase(c):
		"fest":
			await c.say("aurelia", "축제란 처음입니다. …이렇게 시끄러운 것이었군요. 나쁘지 않습니다.")
		"trial":
			await c.say("aurelia", "대신전의 종루에서 기다리겠습니다, 세라피나.")
		"epi":
			await c.say("aurelia", "새 종을 축복했습니다. 루멘의 빛이 아니라, 우리 손으로 만든 빛으로.", "happy")
			await c.say("aurelia", "…웃는 법은 아직 연습 중입니다.")
		_:
			await c.say("aurelia", "…")
	c.close_box()


func npc_lyra_ch5(c: Cut) -> void:
	if c.has("st_epilogue") and not c.has("st_tea_done"):
		await c.call_script("st_tea")
		return
	if c.has("ch5_done"):
		var lines := [
			"별 보는 법? 그건 쉬워. 고개를 들면 돼. …어려운 건 고개를 드는 거지.",
			"꼬마 아스트리드가 자꾸 나보고 할머니래. 나보다 한참 어리면서.",
			"흰머리가 하나 늘었어. 축하해 줄래?",
			"나의 별— 아, 미안. 버릇이야. …불러도 된다고? 고마워.",
		]
		await c.say("lyra", String(lines[randi() % lines.size()]), "aged")
	else:
		await c.say("lyra", "…차 마시는 중이야. 이리 와, 세라피나.", "aged")
	c.close_box()


func npc_st_yard_a(c: Cut) -> void:
	await c.say("student_a", "세라! 축제 광장 가 봤어? 제국 기사단장이 소시지를 굽고 있대! 진짜 그 레오니 단장님이!", "happy")


func npc_st_fest_a(c: Cut) -> void:
	await c.say("student_a", "엘프 꿀빵 먹어 봤어? 혀 데었어… 그래도 또 먹을 거야.", "happy")


func npc_st_fest_b(c: Cut) -> void:
	await c.say("student_b", "저녁에 무도회 한대. 이졸데가 상대를 찾는다던데… 너 아냐?")


func npc_st_fest_c(c: Cut) -> void:
	if c.has("ch5_done"):
		await c.say("student_c", "축제를 다시 연대! 이번엔 끝까지 하는 거야. 하늘이 갈라져도!", "happy")
	else:
		await c.say("student_c", "오필리아 교수님이 비계 위에서 별을 보시는데… 깨어 계신 거 맞지?")


func npc_r5_stu(c: Cut) -> void:
	await c.say("student_c", "교장 선생님이 여기 있으면 괜찮대… 괜찮은 거지? 그렇지?", "sad")


# ─── 다시 세우기 (엠버린) ───────────────────────────────

func _rebuild_giver(c: Cut) -> void:
	var st := Quests.state("st_rebuild")
	if st == 0:
		await c.say("emberlyn", "세라. 일손을 도와줄 사람 여섯— 피피, 버터워스, 호두, 이졸데, 레오니, 엘라리엔이 너를 찾고 있다.")
		await c.say("emberlyn", "다 돕고 오면… 그래, 다 같이 사진이라도 찍자.", "happy")
		c.close_box()
		c.quest_start("st_rebuild")
	elif st == 1 and Quests.step("st_rebuild") >= 1:
		await c.say("emberlyn", "다 도왔다고? …그래. 모여라, 다들! 사진 찍는다!", "happy")
		c.close_box()
		await c.fade_out(0.6, Color(1, 1, 1))
		c.sfx("reveal", 2.0)
		await c.narrate("찰칵.")
		c.close_box()
		c.flag("st_photo_taken")
		await c.fade_in(0.8)
		await c.say("emberlyn", "교장실에 걸어 두마. 창립자 선생님 사진 옆에.", "happy")
		c.close_box()
		await c.quest_done("st_rebuild")
	elif st == 1:
		var n := 0
		for w in REBUILD_HELP:
			if c.has("st_rb_" + w):
				n += 1
		await c.say("emberlyn", "도운 사람 %d/6. 천천히 해라. 학교는 도망가지 않는다." % n)
	else:
		await c.say("emberlyn", "사진 잘 나왔다. …네 꼬리가 아홉 개 다 찍혔더구나.", "happy")
