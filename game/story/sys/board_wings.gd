extends RefCounted
## 공통 시스템 대본 — 1장 끝 이어하기 · 수업 게시판 · 불꽃 날개 수업(오필리아·바람의 탑).
## 공통 시스템 대본 — 수업 게시판 안내, 마법 수업 4종(불꽃 날개·불꽃 방벽·유성 낙화·불사조), 1장 끝 기록 이어하기.
## 수업 정의는 story/data_sys.gd (QUESTS), 방은 tools/rooms/sys.py. 흐름은 docs/magic.md 4절.
## 인물 말투: 오필리아 "~란다~" 몽롱 · 엠버린 따뜻하고 엄격 · 베로니카 냉철하고 짧게 · 그레타 과묵 · 아스트리드 존댓말(가끔 장난).


# ─── 1장 끝 기록으로 이어하기 ────────────────────────────

## 예전 기록(1장 데모 끝 화면에서 이어한 것)을 2장으로 넘김
func sys_chapter1_resume(c: Cut) -> void:
	if c.has("ch1_done"):
		return
	c.lock()
	await c.wait(0.5)
	await c.say("neoul", "…세라. 푹 잤느냐. 이 학교에 새 바람이 부는 냄새가 나는구나.")
	c.close_box()
	await ChapterFlow.finish(c, 1)


# ─── 수업 게시판 ─────────────────────────────────────────

func sys_board_intro(c: Cut) -> void:
	c.flag("sys_board_seen")
	c.lock()
	var board := Vector2(27 * 16 + 8, 42 * 16)
	await c.camera_to(board + Vector2(0, -30), 0.7)
	c.emote("neoul", "!")
	await c.say("neoul", "세라, 저 게시판이 반짝이는구나. 무어라 쓰여 있느냐?")
	await c.say("sera", "실기 수업 게시판! 듣고 싶은 수업을 여기서 신청하는 거야.", "happy")
	await c.say("sera", "수업을 끝까지 마치면… 새 마법을 정식으로 배울 수 있어.")
	await c.say("neoul", "흥. 마법이야 내 구슬이 다 해 주는 것을. …뭐, 배워 두면 나쁠 건 없지.")
	c.close_box()
	await c.camera_back(0.5)
	await c.teach("마법 배우기", "중앙 홀의 수업 게시판 앞에서 ↑ — 들을 수 있는 수업을 골라 신청한다.\n수업(퀘스트)을 마치면 새 마법을 배운다. 수업은 한 번에 하나.\n진행 중인 수업은 일시정지 → 퀘스트 → 수업 칸에서 볼 수 있다.", ["move_up"])


# ═══════════════════════════════════════════════════════════
# 불꽃 날개 (중급) — 오필리아 · 바람의 탑
# ═══════════════════════════════════════════════════════════

func cls_wings_begin(c: Cut) -> void:
	c.bubble("오필리아라는 그 잠꾸러기 마녀에게 가 보자꾸나. 비속성마법반이었지.", 3.0)


func cls_wings_lesson(c: Cut) -> void:
	await c.approach("ophelia", 3.0, 80.0)
	await c.say("ophelia", "어머~ 세라~ 날개 수업을 신청했구나~", "happy")
	await c.say("ophelia", "부양이 무게를 잠깐 잊는 거라면~ 날개는… 바람을 기억하는 거란다~")
	await c.say("sera", "바람을… 기억해요?")
	await c.say("ophelia", "떨어질 때 무서워서 몸을 웅크리면 그냥 떨어지지~ 대신 팔을 활짝 펴고, 불을 등 뒤로 흘려 보내면~")
	c.emote("ophelia", "note")
	await c.say("ophelia", "…훨훨~ 바람이 받아 준단다~ 특히 아래에서 위로 부는 바람은~ 쭈욱 위로~", "happy")
	await c.say("neoul", "말이 길구나. 요컨대 떨어질 때 날개를 펴라는 게지.")
	c.close_box()
	c.flag("temp_wings")
	await c.item("연습용 날개깃", "공중에서 점프를 다시 길게 누르고 있으면 불꽃 날개로 활공한다. (수업 동안 빌린 것)")
	await c.teach("불꽃 날개 (연습)", "공중에서 점프를 다시 누르고 있으면 활공한다.\n위로 부는 바람(상승 기류) 안에서 활공하면 높이 솟아오른다.", ["jump"])
	await c.say("ophelia", "부양 실습실 왼쪽 끝에 '바람의 탑' 문을 열어 두었어~ 꼭대기까지 등불 다섯 개를 밝히면 합격~")
	await c.say("ophelia", "나는 꼭대기에서… 기다릴게… 쿨…", "happy")
	c.close_box()
	c.flag("cls_wings_open")
	c.quest_step("cls_wings", 1)
	c.save()


func enter_s_windtower(c: Cut) -> void:
	if c.has("windtower_intro") or c.has("windtower_done"):
		return
	c.flag("windtower_intro")
	c.lock()
	await c.wait(0.3)
	await c.camera_to(c.player.global_position + Vector2(0, -260), 1.6)
	c.sfx("wind", -2.0)
	await c.say("sera", "우와… 탑 안에 바람이 기둥처럼 불어…", "surprised")
	await c.camera_back(1.0)
	await c.say("neoul", "점프하고, 떨어지려 할 때 다시 눌러 날개를 펴거라. 바람 기둥에 몸을 맡기면 된다.")
	c.close_box()


func cls_wings_tower_done(c: Cut) -> void:
	await c.wait(0.5)
	c.lock()
	c.sfx("bell", 2.0)
	c.flash(Color(0.85, 0.8, 1.0, 0.5), 0.5)
	await c.wait(0.8)
	var p := c.player_tile()
	c.spawn_npc("ophelia", p.x + 3.0, p.y - 8.0, -1)
	await c.move("ophelia", p.x + 3.0, p.y, 1.4, Tween.TRANS_QUAD)
	await c.say("ophelia", "띵동~ 종이 울렸네~ 합격이란다~", "happy")
	await c.say("ophelia", "바람을 기억했구나~ 이제 그 날개는 빌린 게 아니라 세라 거야~")
	c.close_box()
	c.flag("temp_wings", false)
	await c.spell_learned("wings")
	await c.quest_done("cls_wings")
	await c.say("ophelia", "그리고 이거~ 바람에 실려 온 마도석이야~ 마법서에서 마법을 더 단단하게 다듬을 수 있단다~")
	await c.say("sera", "마법서… 일시정지해서 보는 그거요?")
	await c.say("ophelia", "응~ 등급이 높은 마법일수록 마도석이 많이 들지~ 아껴 쓰렴~")
	c.close_box()
	c.save()
