extends "res://story/ch3/common.gd"
## 3장 대본 — 학교 아침·편지 · 숲 입구·경계의 숲 · 뿌리 마을·장로.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 학교 — 아침 · 편지
# ═══════════════════════════════════════════════════════════

## 장 카드 뒤(검은 화면·HUD 꺼짐) ChapterFlow가 부른다
func ch3_start(c: Cut) -> void:
	c.flag("e_start")
	c.hud(true)
	await c.goto_room("s_greenhouse", "ch3")
	c.lock()
	c.music("school_day")
	c.player_face(1)
	await c.fade_in(1.0)
	await c.wait(0.4)
	await c.say("pippa", "세라! 큰일 났어, 큰일! 이리 와 봐!", "surprised")
	await c.say("sera", "…아침부터 또 뭐야. 실험 재료가 살아서 도망쳤어?")
	await c.say("pippa", "아니! 세계수 묘목이! 엘프 숲에서 선물로 받은, 온실에서 제일 소중한 애가…", "sad")
	c.close_box()
	await c.camera_to(Vector2(11 * 16 + 8, 19 * 16 - 30), 0.8)
	await c.wait(0.4)
	await c.say("pippa", "하얗게 굳어 가고 있어. 물도 줬고, 햇빛도 줬는데… 잎이 꼭 돌처럼.", "sad")
	await c.say("neoul", "……이 냄새. 불도, 썩음도 아니니라. 아무것도 아닌 냄새로구나.")
	await c.say("sera", "아무것도 아닌 냄새?")
	await c.say("neoul", "그래서 더 고약하다니라. 빈자리 같은 냄새다.")
	c.close_box()
	await c.camera_back(0.6)
	await c.say("pippa", "참, 교장 선생님이 너 찾으셨어! 줄 게 있대. 시계탑 꼭대기 교장실!", "happy")
	await c.say("pippa", "그리고 그리고, 오필리아 교수님이 어젯밤 별을 보시다가 \"유성이 떨어질 하늘이란다~\" 하셨대. 무슨 뜻일까?")
	await c.say("pippa", "아, 앞마당 결투 대회 공고도 봤어? 결승 상대 이름에 네가 있더라! 이졸데가 직접 지목했대!", "smug")
	await c.say("sera", "나?! 신청한 적도 없는데!", "surprised")
	await c.say("pippa", "지하 괴물 잡았다는 소문 때문이지 뭐~ 아무튼 교장실 먼저! 다녀와서 나한테도 들러 줘. 부탁할 게 있거든!", "happy")
	c.close_box()
	c.save()
	c.bubble("시계탑 꼭대기라… 중앙 홀 2층 오른쪽이었지.", 3.0)


## 교장실 (덧붙인 트리거): 편지 · 숲의 결계 · 떨리는 손 (교장이 돕는 장면 3)
func e_headmaster(c: Cut) -> void:
	if c.has("e_letter"):
		return
	c.lock()
	await c.wait(0.3)
	await c.say("astrid", "어서 오세요, 세라피나 양. 온실의 묘목은 보셨나요?")
	await c.say("sera", "네. 하얗게… 돌처럼 굳어 가고 있었어요.")
	await c.say("astrid", "그 묘목은 엘프의 숲, 세계수 에일라흐의 씨앗에서 자랐답니다. 묘목이 굳는다는 건 — 어미 나무가 아프다는 뜻이죠.")
	await c.say("astrid", "엘프의 장로 오르티아에게 이 편지를 전해 주세요. 아주 오래전에… 신세를 진 분이랍니다.", "happy")
	c.close_box()
	await c.item("교장의 편지", "엘프의 장로 오르티아에게. 봉인에 별 문양이 찍혀 있다.")
	await c.narrate("편지를 건네는 교장 선생님의 손끝이, 아주 조금 떨렸다.")
	await c.say("sera", "…선생님, 손이—", "surprised")
	await c.say("astrid", "아침 차가 좀 진했나 봐요.", "smug")
	await c.say("astrid", "숲을 두른 결계는 제가 잠시 풀어 두겠어요. 앞마당 전이진에 '엘프의 숲'이 보일 거예요.")
	c.warp_unlock("elf")
	c.sfx("star_twinkle")
	c.flash(Color(0.8, 0.85, 1.0, 0.35), 0.4)
	await c.say("astrid", "그리고 숲에선 화살을 조심하세요. 그곳 사람들은… 마녀를 썩 반기지 않거든요.")
	await c.say("neoul", "흥. 화살 따위.")
	await c.say("astrid", "여우신께서도 조심하시길. 엘프의 화살은 신의 꼬리도 가리지 않는답니다.", "smug")
	await c.say("neoul", "……", "surprised")
	await c.say("astrid", "앞마당까지는 제가 바래다 드리죠. 눈을 감으세요.", "happy")
	c.close_box()
	c.flag("e_letter")
	c.sfx("warp")
	await c.fade_out(0.8, Color(0.85, 0.85, 1.0))
	await c.goto_room("s_courtyard", "warp")
	c.lock()
	await c.wait(0.3)
	c.bubble("…눈 깜짝할 새로구나. 전이진 앞에서 ↑ — '엘프의 숲'을 고르거라.", 3.6)


# ═══════════════════════════════════════════════════════════
# 엘프의 숲 — 입구 · 경계의 숲
# ═══════════════════════════════════════════════════════════

func enter_e_gate(c: Cut) -> void:
	if c.has("e_arrived"):
		return
	c.warp_unlock("elf")
	c.flag("e_arrived")
	c.lock()
	c.music("elf")
	await c.wait(0.8)
	await c.say("sera", "여기가… 엘프의 숲.", "surprised")
	await c.say("neoul", "나무가 하늘을 떠받치고 있구나. 저것이 세계수 에일라흐 — 신계에서도 이름이 들리던 나무니라.")
	await c.say("sera", "근데 저 꼭대기… 하얗지 않아?")
	await c.say("neoul", "……온실의 그 냄새가 여기까지 나는구나. 가자, 세라.")
	c.close_box()
	c.save()


## 경계의 숲 1 첫걸음: 경고 사격 — 화살이 모자를 꿰뚫음
func e_warning_shot(c: Cut) -> void:
	if c.has("e_hat"):
		return
	c.flag("e_hat")
	c.lock()
	await c.wait(0.4)
	var head := c.player.global_position + Vector2(c.player.facing * 2.0, -38)
	_show_arrow(c, head + Vector2(420, -60), head + Vector2(-60, 8))
	await c.wait(0.42)
	c.emote("sera", "!")
	c.shake(0.15, 0.2)
	Fx.burst(head, 8, {spread = 120.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(Color(0.25, 0.15, 0.3)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 60)})
	await c.wait(0.6)
	await c.say("sera", "……", "surprised")
	await c.say("sera", "내, 내 모자에 구멍이!!", "angry")
	await c.narrate("「돌아가라, 마녀. 다음은 모자가 아니다.」")
	await c.say("neoul", "…저 먼 가지 위다. 보이지도 않는 거리에서 모자 끝만 꿰었구나.", "surprised")
	await c.say("sera", "편지 전하러 온 거라고요! 교장 선생님 심부름!", "angry")
	await c.narrate("「……」")
	await c.say("neoul", "대답 대신 시위 당기는 소리로구나. 세라, 숨을 곳을 보며 가거라.")
	c.close_box()


## 처음 조준당할 때 (저격 구간 first 플래그 → 사건)
func e_snipe_teach(c: Cut) -> void:
	await c.wait(0.05)
	await c.teach("엄폐", "붉은 예고선이 세라를 따라온다 — 흰색으로 깜빡이면 곧 화살!\n바위·쓰러진 나무 뒤에 서면 선이 끊긴다. 화살이 지나간 틈에 다음 엄폐물로.\n불꽃 방벽으로 화살을 되쏠 수도 있다.", ["move_right"])


func e_warden_seen(c: Cut) -> void:
	var w := c.enemy("elf_warden")
	if w == null:
		return
	c.lock()
	await c.camera_to(w.global_position + Vector2(0, -24), 0.7)
	await c.say("elf_warden", "멈춰라, 마녀. 장로님의 허락 없이는 한 발짝도 못 들어간다.")
	await c.say("sera", "그 장로님께 편지를 전하러 왔다니까요!", "angry")
	await c.say("elf_warden", "말은 창으로 해라.")
	await c.say("neoul", "막무가내로구나. …세라, 너무 다치게 하진 말거라. 지키는 자들이니.")
	c.close_box()
	await c.camera_back(0.5)
	c.release()
	c.bubble("잎 방패는 앞만 막느니라. 창을 찌른 뒤가 빈틈이다.", 3.2)


func e_blight_first(c: Cut) -> void:
	var s := c.enemy("blight_spore")
	if s == null:
		return
	c.lock()
	await c.camera_to(s.global_position + Vector2(0, -20), 0.7)
	await c.say("sera", "저 하얀 거… 온실 묘목이랑 똑같아.", "surprised")
	await c.say("neoul", "역병 포자 덩어리로구나. 터지면 하얀 가루가 바닥에 깔린다 — 밟으면 발이 굳느니라.")
	await c.say("neoul", "불에는 약하다. 태워 버리거라. 바닥의 가루도 불이 닿으면 사라진다.")
	c.close_box()
	await c.camera_back(0.5)


## 뿌리 문: 파수꾼 둘 → 엘라리엔 등장 → 편지 확인 → 문이 열림 (e_border_passed)
func e_border_gate(c: Cut) -> void:
	if c.has("e_border_passed"):
		return
	c.lock()
	await c.say("warden_a", "거기 서라. 경계를 넘어온 마녀가 있다더니.")
	await c.say("warden_b", "화살 비를 뚫고 여기까지? …제법인데.")
	await c.say("sera", "아스트리드 교장 선생님의 편지예요. 오르티아 장로님께!")
	await c.say("warden_a", "아스트리드? 그런 이름은 들은 적—")
	c.close_box()
	c.spawn_npc("elarien", 34.0, 4.0, -1)
	Ch3Sfx.ensure()
	Ch3Sfx.play(&"ch3_rustle", 0.0, 0.0)
	await c.move("elarien", 33.0, 19.0, 0.45, Tween.TRANS_QUAD)
	c.shake(0.08, 0.15)
	await c.wait(0.3)
	await c.say("elarien", "…편지.")
	await c.say("sera", "아. 당신이구나. 내 모자.", "angry")
	await c.say("elarien", "모자만 맞혔다. 일부러.", "smirk")
	await c.say("elarien", "편지, 보여 봐라.")
	c.close_box()
	await c.narrate("엘라리엔이 뿌리 틈으로 편지의 봉인을 살핀다. 별 문양이 희미하게 빛났다.")
	await c.say("elarien", "…장로님의 옛 벗 표식이다. 진짜군.")
	await c.say("elarien", "리엔, 문을 열어. 장로님께 모셔라.")
	await c.say("warden_a", "하지만 엘라리엔, 마녀를—")
	await c.say("elarien", "허튼짓하면 내가 쏜다. 그거면 충분하다.", "focus")
	c.close_box()
	c.flag("e_border_passed")
	await c.wait(1.2)
	await c.move("elarien", 37.0, 3.0, 0.4)
	c.hide_actor("elarien")
	await c.say("neoul", "…무서운 아이로구나. 그런데 세라, 그 화살들 — 하나도 너를 제대로 겨누지 않았느니라.")
	await c.say("sera", "…모자는 제대로 겨눴거든.", "angry")
	c.close_box()


# ═══════════════════════════════════════════════════════════
# 뿌리 마을 · 장로
# ═══════════════════════════════════════════════════════════

func enter_e_roots(c: Cut) -> void:
	if c.has("e_roots_seen") or not c.has("e_border_passed"):
		return
	c.flag("e_roots_seen")
	c.lock()
	await c.wait(0.5)
	await c.camera_to(Vector2(70 * 16, 30 * 16), 1.2)
	await c.say("sera", "우와… 나무뿌리 사이에 마을이…!", "happy")
	c.close_box()
	await c.camera_back(0.8)
	await c.approach("fio", 2.5, 120.0)
	await c.say("fio", "마녀다! 진짜 마녀! 모자 끝 뾰족한 거 진짜야?", "happy")
	await c.say("fio", "어! 모자에 구멍 났다! 엘라리엔 언니한테 맞았지? 맞았지?", "surprised")
	await c.say("sera", "…맞았어.", "sad")
	await c.say("fio", "헤헤, 언니는 절대 안 빗나가! 근데 사람은 절대 안 맞혀. 그게 더 어려운 거래!", "happy")
	await c.say("fio", "난 피오야! 장로님 집은 저기 큰 뿌리 문! …나도 따라가고 싶은데 엄마가 집에 있으래.")
	c.close_box()
	c.save()


## 장로의 집: 편지 · "그 꼬마가 교장이라니" · 엘라리엔 첫 대면 · 다음 목적지(티엘·달샘)
func enter_e_elder_hall(c: Cut) -> void:
	if c.has("e_met_ortia") or not c.has("e_border_passed"):
		return
	c.lock()
	c.spawn_npc("elarien", 34.0, 19.0, -1)
	await c.wait(0.4)
	await c.say("ortia", "어서 오게, 작은 마녀. 바깥이 소란스럽더니 자네였구먼.", "happy")
	await c.say("sera", "처음 뵙겠습니다. 마녀학교의 세라피나예요. 교장 선생님께서 이걸…")
	c.close_box()
	await c.player_walk(22.0)
	await c.narrate("오르티아 장로가 편지를 펼쳐, 한참을 읽었다.")
	await c.say("ortia", "아스트리드라…… 그 꼬마가 교장이라니. 세월 참 빠르구먼.", "happy")
	await c.say("sera", "꼬, 꼬마요?", "surprised")
	await c.say("ortia", "내 무릎에 올라와 별 이야기를 조르던 아이였다네. 그 아이의 스승과 나는 오랜 벗이었지.", "happy")
	await c.say("ortia", "……편지에 적혀 있군. 학교 온실의 묘목이 하얗게 굳었다고. 여기도 마찬가지일세.", "serious")
	await c.say("ortia", "한 달 전부터 세계수 꼭대기가 하얗게 굳기 시작했네. 불에 탄 것도, 병든 것도 아닌… '아무것도 아닌' 하양이야.", "serious")
	await c.say("neoul", "…온실에서 맡은 냄새 그대로니라.")
	await c.say("ortia", "허허, 여우신께서도 함께 오셨구먼. 반갑소이다.", "happy")
	await c.say("neoul", "흥… 이 노인, 눈이 밝구나.", "surprised")
	await c.say("elarien", "장로님. 마녀를 숲 안으로 들이실 겁니까.")
	await c.say("ortia", "엘라리엔. 아스트리드가 보낸 아이일세.")
	await c.say("elarien", "불을 다루는 자는 숲에 해롭습니다. 저 하양에 불을 대면, 숲이 먼저 탈 겁니다.")
	await c.say("ortia", "그래서 이 아이가 온 게지. 태우는 불 말고 다른 불을 쓸 줄 아는 아이라면 말일세.")
	await c.say("elarien", "……지켜보겠습니다.")
	c.close_box()
	await c.walk("elarien", 4.0, 100.0)
	c.sfx("door")
	c.hide_actor("elarien")
	await c.say("ortia", "저 아이는 말이 짧아도 속은 깊다네. 허허.", "happy")
	await c.say("ortia", "자, 세라피나. 줄기 시장의 티엘을 찾아가게. 바람길을 고치는 장인이지. 꼭대기로 가려면 바람길을 타야 하네.")
	await c.say("ortia", "승강기가 멈췄으니 마을 오른쪽 끝 뿌리 동굴로 돌아가게. 동굴 끝의 굴을 오르면 줄기 시장일세.")
	await c.say("ortia", "그리고… 하양 앞에서 막히거든, 가지 마을 위쪽 끝의 달샘에 가 보게. 마음을 가라앉히기엔 거기만 한 데가 없지.")
	c.close_box()
	c.flag("e_met_ortia")
	c.save()
