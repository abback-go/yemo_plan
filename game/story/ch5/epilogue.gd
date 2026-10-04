extends "res://story/ch5/common.gd"
## 5장 대본 — 13. 에필로그 — 다시 세우는 학교·차·엔딩 크레디트.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 13. 에필로그 — 다시 세우는 학교, 차, 엔딩 크레디트
# ═══════════════════════════════════════════════════════════

func enter_st_rebuild(c: Cut) -> void:
	if c.has("st_epilogue") or not c.has("st_gate_done"):
		return
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.flag("st_epilogue")
	c.flag("fox_permanent", false)
	if c.player.is_fox():
		c.player.fox_time = 0.01
	c.music("ending2")
	await c.wait(0.8)
	await c.title_card("몇 주 뒤", "다시 세우는 마녀학교", 2.4)
	await c.fade_in(2.0)
	await c.say("emberlyn", "세라! 마침 잘 왔다. 손이 모자라.", "happy")
	await c.say("emberlyn", "학생, 교사, 기사, 엘프, 신관까지 전부 모였는데도 손이 모자라. 학교란 게 이렇게 컸나 싶다.")
	await c.say("neoul", "…세라. 저기 차 탁자에, 할머니 마녀 둘이 앉아 있느니라.", "smug")
	await c.say("sera", "들리겠어.", "smug")
	c.close_box()
	c.hud(true)
	c.save()
	c.release()


## 차 탁자 (트리거): 리라와 아스트리드, 너울의 마지막 말 → 엔딩 크레디트
func st_tea(c: Cut) -> void:
	if c.has("st_tea_done"):
		return
	c.lock()
	c.letterbox(true)
	await c.wait(0.3)
	await c.say("lyra", "아스트리드, 봐 봐. 흰머리가 났어.", "aged")
	await c.say("astrid", "축하해요, 선배. 드디어 저를 따라오기 시작했군요.", "wink")
	await c.say("lyra", "백 년이나 기다리게 했네.", "aged")
	await c.say("astrid", "백이십 년이요. 선생님이 떠나신 날부터 세면.", "happy")
	await c.say("lyra", "…꼬마 아스트리드는 여전히 셈이 정확하구나.", "happy")
	c.close_box()
	await c.say("lyra", "세라피나. '나의 별'이라고 부르는 거, 이제 그만둘게.", "aged")
	await c.say("sera", "…불러도 돼. 대신 이번엔 진짜로 별 보는 법 가르쳐 줘.", "happy")
	await c.say("lyra", "…응. 고개를 드는 것부터.", "happy")
	c.close_box()
	await c.wait(0.5)
	await c.say("sera", "너울. 이제 구슬, 돌려받을 수 있어?")
	await c.say("neoul", "구슬은… 이제 안전하게 뺄 수 있지만.", "normal")
	await c.say("neoul", "조금만 더 맡겨 두마.", "happy")
	await c.say("sera", "…응? 왜?", "surprised")
	await c.say("neoul", "배가 고프니라. 버터워스의 국을 먹으려면 네 몸이 편하구나.", "smug")
	await c.say("sera", "그게 이유야?!", "angry")
	await c.say("astrid", "…라고 해 두죠.", "wink")
	c.close_box()
	c.flag("st_tea_done")
	await c.wait(0.8)
	await c.fade_out(2.0)
	c.hud(false)
	await c.credits()
	await ChapterFlow.finish(c, 5)
	# 엔딩 뒤: 자유 탐험 (다시 세우는 안뜰)
	c.letterbox(false)
	c.hud(true)
	c.music("ending2")
	await c.fade_in(1.6)
	await c.title_card("고마워요", "모든 이야기가 끝났다 — 자유롭게 둘러보세요", 2.6)
	c.save()
	c.release()
