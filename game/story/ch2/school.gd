extends "res://story/ch2/common.gd"
## 2장 대본 — 1. 아침(학교) — 기숙사·식당·날개 수업 뒤·교장실 사자·출발.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 1. 아침 (학교) — 기숙사 → 식당 → 수업 게시판(공통) → 날개 수업(공통)
# ═══════════════════════════════════════════════════════════

## 장 카드 뒤 기숙사 (검은 화면·HUD 꺼짐 상태에서 시작)
func ch2_start(c: Cut) -> void:
	c.lock()
	c.hud(false)
	c.music("school_day", 1.0)
	c.player_face(1)
	await c.wait(0.4)
	await c.fade_in(1.2)
	c.hud(true)
	await c.wait(0.4)
	c.sfx("door")
	c.spawn_npc("pippa", 34.0, 19.0, -1)
	await c.walk("pippa", 24.0, 110.0)
	c.emote("pippa", "!")
	await c.say("pippa", "세라! 세라피나! 일어나! 해가 중천이야!", "surprised")
	await c.say("sera", "으음… 오 분만…", "sad")
	await c.say("pippa", "학교가 아주 난리야. '폐급이 지하 괴물을 잡았대' — 복도마다 그 얘기뿐이라고!", "happy")
	await c.say("sera", "…! 아, 아니야. 그건 교사들 결계 실습 사고라니까. 교장 선생님이 그러셨어.", "surprised")
	await c.say("pippa", "흐응~ 그렇다 치고. 오늘부터 중앙 홀에 실기 수업 게시판도 열린대!", "happy")
	await c.say("pippa", "일단 아침부터! 식당에서 기다릴게. 늦으면 네 빵은 내 거다~", "smug")
	c.close_box()
	await c.walk("pippa", 35.0, 120.0)
	c.hide_actor("pippa")
	c.sfx("door")
	await c.wait(0.4)
	c.emote("neoul", "!")
	await c.say("neoul", "…배고프니라. 그 국자 든 마녀에게 가자꾸나. 어서.")
	await c.say("sera", "알았어, 알았어. 너울 너, 어젯밤에도 똑같은 말 했거든?", "happy")
	c.close_box()
	c.save_here("bed")


## 식당: 아침 식사 — 소문, 피피·이졸데, 너울의 배
func k_cafe_morning(c: Cut) -> void:
	if c.has("k_breakfast"):
		return
	c.lock()
	c.emote("pippa", "!")
	await c.say("pippa", "세라! 여기, 여기!", "happy")
	await c.player_walk(15.0)
	c.player_face(1)
	await c.say("isolde", "…왜 하필 내 옆자리야.", "smug")
	await c.say("pippa", "자리가 여기밖에 없거든요~ 고급반 아가씨.", "happy")
	await c.say("student_a", "(속닥) 저기 봐, 폐급이야. 지하에서 괴물을 맨손으로 찢었대.")
	await c.say("student_a", "(속닥) 교장 선생님은 젊었을 때 하늘을 셋으로 갈랐다던데… 둘 중에 누가 더 무서울까?")
	c.emote("sera", "sweat")
	await c.say("sera", "…맨손으로 찢은 적 없거든.", "sad")
	await c.walk("butterworth", 19.0, 70.0)
	c.face("butterworth", -1)
	await c.say("butterworth", "아이고, 우리 영웅님 오셨네! 오늘은 곱빼기다. 그리고 이건 — 여우 몫!", "happy")
	c.emote("neoul", "heart")
	await c.say("neoul", "…! 이 마녀, 사람 볼 줄 아는구나. 고기니라. 고기…!")
	c.sfx("squish", -4.0)
	await c.wait(0.6)
	await c.say("isolde", "실기 게시판에 '불꽃 날개' 수업이 붙었더군. 오필리아 교수 수업.")
	await c.say("isolde", "폐급이 날개를 달면… 추락하는 별똥별이나 되겠지.", "smug")
	await c.say("pippa", "그래 놓고 너도 신청할 거잖아~", "smug")
	await c.say("isolde", "…난 이미 들었어. 작년에.", "angry")
	await c.say("sera", "날개라… 나 해 볼래. 중앙 홀 게시판이지?", "happy")
	c.close_box()
	await c.walk("butterworth", 26.0, 70.0)
	c.face("butterworth", -1)
	c.flag("k_breakfast")
	c.bubble("배가 부르니 날 수도 있을 것 같구나. 중앙 홀로 가자.", 3.0)
	c.save()


## 바람의 탑: 날개 수업이 끝난 직후 — 교장의 부름
func k_after_wings(c: Cut) -> void:
	await c.wait(0.4)
	c.lock()
	if c.actor("ophelia"):
		await c.say("ophelia", "아 참~ 깜빡할 뻔했네~ 교장 선생님이 세라를 찾으셨어~", "happy")
		await c.say("ophelia", "손님이 오셨대~ 아주 반짝반짝한 갑옷을 입은~ 시계탑 꼭대기 교장실이야~")
	else:
		await c.say("neoul", "세라. 종소리에 섞여 들리던데… 교장이 너를 찾는다는구나.")
	await c.say("sera", "교장 선생님이…? 설마 어제 지하 일 때문에…", "surprised")
	await c.say("neoul", "혼나러 가는 얼굴은 하지 말거라. 우린 잘못한 게 없느니라.")
	c.close_box()


## 교장실: 제국의 사자 — 파견 결정, 별 브로치
func k_envoy(c: Cut) -> void:
	if c.has("k_envoy_seen"):
		return
	c.lock()
	c.spawn_npc("k_envoy", 20.0, 19.0, 1)
	c.spawn_npc("emberlyn", 31.0, 19.0, -1)
	c.spawn_npc("isolde", 34.0, 19.0, -1)
	c.spawn_npc("pippa", 36.0, 19.0, -1)
	await c.player_walk(12.0)
	c.player_face(1)
	await c.say("astrid", "어서 와요, 세라. 마침 모두 모였네요.")
	await c.say("k_envoy", "아르덴 제국 황실의 사자, 기사 오스카입니다. 마녀학교에 정식으로 도움을 청하러 왔습니다.")
	await c.say("k_envoy", "황도에 '별의 짐승'이 나타났습니다. 별 조각을 삼킨 짐승들입니다. 밤마다 늘어나고 있습니다.")
	await c.say("astrid", "10년 전 별이 떨어진 그 도시군요.", "sad")
	await c.say("k_envoy", "은사자 기사단이 막고 있지만… 단장님께서는 마녀의 도움을 썩 반기지 않으십니다. 황제 폐하의 뜻입니다.")
	await c.say("astrid", "그럼 '현장 실습'이라고 해 두죠. 마녀학교 학생들이 제국 구경을 좀 하는 거예요.", "smug")
	await c.say("astrid", "인솔은 엠버린 교수. 학생은 이졸데, 피피 — 그리고 세라.")
	c.emote("isolde", "!")
	await c.say("isolde", "…폐급을 데려간다고요? 교장 선생님, 실습이 아니라 사고 수습이 될 텐데요.", "angry")
	await c.say("astrid", "제가 고른 학생들이에요. …불만 있나요?", "happy")
	await c.say("isolde", "…아뇨.", "sad")
	await c.say("pippa", "제국! 제국 시장에는 별향신료가 있다던데! 물약 재료도!", "happy")
	await c.say("emberlyn", "놀러 가는 게 아니다, 피피. 짐승 조사다. …시장 구경은 틈이 나면.", "smug")
	c.close_box()
	await c.walk("astrid", 16.0, 50.0)
	c.face("astrid", -1)
	await c.say("astrid", "세라, 잠깐. 이걸 가져가요.")
	c.flag("k_brooch")
	c.sfx("star_twinkle", 2.0)
	await c.item("교장의 별 브로치", "별 모양 은장식 브로치. 희미하게 별빛이 돈다. '한 번쯤은, 당신을 지켜 줄 거예요.'")
	await c.say("sera", "이걸… 저한테요?", "surprised")
	await c.say("astrid", "오래된 별 장식이에요. 한 번쯤은, 당신을 지켜 줄 거예요. …한 번쯤은요.")
	await c.say("neoul", "…별 냄새가 나는구나. 이 마녀, 무엇을 아는 게냐.", "sad")
	await c.say("emberlyn", "앞마당 전이진에서 출발한다. 준비되면 오너라. 공관과 이어 두었다.")
	c.close_box()
	c.flag("k_envoy_seen")
	c.save()


## 앞마당 전이진: 출발 → 제국 공관 도착 (첫 왕복은 대본이 옮긴다)
func k_depart(c: Cut) -> void:
	if c.has("k_departed"):
		return
	c.lock()
	await c.player_walk(24.0)
	c.player_face(-1)
	await c.say("emberlyn", "모두 모였구나. 이 전이진은 제국 주재 공관과 이어져 있다.")
	await c.say("pippa", "물약 잔뜩 챙겼어! 세라, 다 떨어지면 나한테 와!", "happy")
	await c.say("isolde", "…발목이나 잡지 마.", "smug")
	await c.say("sera", "잡을 발목이 있어야 잡지. 너 날아다닐 거잖아.", "smug")
	c.close_box()
	c.sfx("warp", 2.0)
	c.flash(Color(0.75, 0.6, 1.0, 0.8), 0.6)
	c.shake(0.15, 0.6)
	await c.wait(0.4)
	await c.fade_out(0.8, Color(0.85, 0.8, 1.0))
	c.flag("k_departed")
	c.warp_unlock("kingdom")
	await c.goto_room("k_embassy", "warp")
	c.music("kingdom", 1.0)
	await c.fade_in(1.0)
	await c.wait(0.3)
	c.sfx("warp", -4.0)
	await c.say("sera", "…우와. 벌써 도착이야?", "surprised")
	await c.say("emberlyn", "제국 주재 마녀학교 공관이다. 여기서 쉬고, 기록하고, 전이진으로 언제든 학교에 돌아갈 수 있다.")
	await c.say("emberlyn", "먼저 은사자 기사단장에게 인사를 해야 하는데… 시장을 지나 동쪽, 기사단 연무장이다.")
	await c.say("pippa", "나는 공관에 물약 가게 차릴래! 필요하면 언제든 와. 공짜야, 친구니까!", "happy")
	await c.say("isolde", "…나는 짐 정리. 먼저 가 봐.")
	await c.say("neoul", "흐음… 이 도시, 별 냄새와 쇠 냄새가 섞여 있구나.")
	c.close_box()
	c.save()


func enter_k_embassy(c: Cut) -> void:
	if c.has("k_departed") and not c.has("warp_kingdom"):
		c.warp_unlock("kingdom")
