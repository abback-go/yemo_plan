extends RefCounted
## 3장 대본 — 세계수의 눈 (docs/chapter3.md 2절 줄거리, 12절 대본 목록). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 흐름: ch3_start(온실) → e_headmaster(편지) → 전이진 → 경계의 숲(경고 사격·저격) → 뿌리 문 → 장로 → 뿌리 동굴 → 줄기 시장·티엘
##       → 바람길 → 가지 마을 → 달샘(잠재우는 불) → 흰 역병의 숲 → 심장 정화 → 수관 → 사냥 시험 → 꼭대기 → 백색 사도
##       → 장로의 집 → 기숙사의 밤 → 꼬리 셋 → 달 위의 그림자 → ChapterFlow.finish(c, 3)
## 말투: 엘라리엔 짧고 건조한 반말 · 오르티아 느릿한 하게체("~구먼", "~게") · 피오 아이 반말("누나!") · 티엘 신난 반말
##       파수꾼 딱딱한 해라체 · 너울 "~니라" · 아스트리드 존댓말 · 피피 하이텐션 · 이졸데 차갑고 오만(점점 츤데레)

const SEEDS := ["e_seed_1", "e_seed_2", "e_seed_3", "e_seed_4", "e_seed_5"]
const MOSS := ["e_moss_1", "e_moss_2", "e_moss_3"]
const VALVES := ["e_valve_fix_1", "e_valve_fix_2", "e_valve_fix_3"]
const TEA := ["e_tea_leaf", "e_tea_dew"]
const SNIPE_EVERY := 13.0 ## 백색 사도전: 엘라리엔이 수정 눈을 쏘는 간격(초)
const ARCHERY_TIME := 20.0


# ─── 도우미 ─────────────────────────────────────────────

func _ptile(c: Cut) -> Vector2:
	return c.player.global_position / 16.0


func _n(keys: Array) -> int:
	return QuestCounter.count_of(keys)


## 세라 곁(같은 높이)에 인물을 세움
func _beside(c: Cut, who: String, dx: float) -> Npc:
	var p := _ptile(c)
	return c.spawn_npc(who, p.x + dx, p.y, -1 if dx > 0.0 else 1)


## 꽃가루 비 (세계수가 되살아날 때) — 방을 옮기면 사라짐
func _pollen(c: Cut) -> void:
	var size := c.world.room.size_px
	var p := CPUParticles2D.new()
	p.position = Vector2(size.x * 0.5, -8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x * 0.5 + 40, 4)
	p.local_coords = false
	p.z_index = 24
	p.amount = 160
	p.lifetime = 7.0
	p.preprocess = 2.0
	p.direction = Vector2(0.2, 1)
	p.spread = 25.0
	p.initial_velocity_min = 16.0
	p.initial_velocity_max = 38.0
	p.gravity = Vector2(4, 8)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	var g := Gradient.new()
	g.set_color(0, Color(0.9, 1.0, 0.6, 0.0))
	g.add_point(0.15, Color(0.85, 1.0, 0.55, 0.9))
	g.set_color(1, Color(1.0, 0.85, 0.45, 0.0))
	p.color_ramp = g
	p.material = Fx.add_material
	c.world.effects.add_child(p)


## 엘프 화살 연출 (해롭지 않음): from → to 로 날아가 지형에 박힘
func _show_arrow(c: Cut, from: Vector2, to: Vector2, speed := 900.0) -> void:
	Ch3Sfx.ensure()
	var a := ElfArrow.new()
	a.setup(from, to - from, speed, {"damage": 0, "life": 2.0})
	a.active = false
	c.world.room.add_entity(a)
	Ch3Sfx.play(&"arrow_shot", 0.0, 0.0)


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
	await c.camera_to(Vector2(22 * 16 + 8, 19 * 16 - 30), 0.8)
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


# ═══════════════════════════════════════════════════════════
# 뿌리 동굴
# ═══════════════════════════════════════════════════════════

func e_cave_dark(c: Cut) -> void:
	c.release()
	c.bubble("어둡구나… 저 버섯들, 불을 대면 빛을 낼 것 같구나. 낙서도 있느니라.", 3.4)


func e_cave_mush_done(c: Cut) -> void:
	c.lock()
	await c.wait(0.5)
	await c.camera_to(Vector2(47 * 16, 15 * 16), 0.6)
	await c.wait(0.5)
	await c.say("neoul", "버섯들이 깨어나 뿌리를 달랬구나. 길이 열렸느니라.", "happy")
	c.close_box()
	await c.camera_back(0.5)


func e_stag_teach(c: Cut) -> void:
	var s := c.enemy("moss_stag")
	if s == null:
		return
	c.lock()
	await c.camera_to(s.global_position + Vector2(0, -24), 0.7)
	await c.say("neoul", "저 사슴… 등의 이끼가 하얗게 굳었구나. 본디 순한 짐승이니라.")
	await c.say("neoul", "쓰러뜨려도 죽지 않는다. 굳은 것만 떨어져 나가고 숲으로 돌아갈 게야. 머뭇거리지 말거라.")
	c.close_box()
	await c.camera_back(0.5)


# ═══════════════════════════════════════════════════════════
# 줄기 시장 · 티엘
# ═══════════════════════════════════════════════════════════

func e_market_arrive(c: Cut) -> void:
	c.lock()
	await c.say("sera", "줄기 시장… 나무 줄기에 시장이 있어!", "happy")
	await c.say("neoul", "…꿀떡 냄새가 나는구나.", "happy")
	await c.say("sera", "편지 심부름 중이거든? 티엘이라는 사람부터 찾자. 공방이 오른쪽 끝이랬지.")
	c.close_box()
	c.save()


func enter_e_workshop(c: Cut) -> void:
	if c.has("e_met_tiel"):
		return
	c.lock()
	await c.wait(0.4)
	await c.say("tiel", "어? 손님? 잠깐만, 이 톱니만… 됐다!", "happy")
	await c.say("tiel", "……마녀? 진짜 마녀다! 불 쓰는 마녀! 장로님이 보냈구나, 그치?", "surprised")
	await c.say("sera", "네. 꼭대기로 가야 하는데 바람길이—")
	await c.say("tiel", "엉망이지! 바람 밸브들이 죄다 엉뚱한 쪽으로 돌아가 있어. 하얀 거 생기고 나서부터야.")
	await c.say("tiel", "근데 너, 불 쓰지? 그럼 딱이야. 밸브는 데우면 한 칸씩 돌거든. 저기 시범용 밸브 쏴 봐!", "happy")
	c.close_box()
	await c.teach("바람 밸브", "불로 맞히면 밸브가 한 칸 돈다 — 위 화살표: 상승 기류 / 옆 화살표: 옆바람.\n상승 기류는 불꽃 날개(공중에서 Z를 다시 누르고 있기)로 활공할 때 몸을 띄운다.", ["attack"])
	await c.say("tiel", "바람길 입구는 시장 오른쪽 끝 계단이야. 파수꾼한테 내가 보냈다고 해!")
	await c.say("tiel", "아, 그리고 굴마다 하나씩 녹슨 밸브가 있는데… 고쳐 주면 고맙겠다! 아니, 진짜 진짜 고맙겠다!", "happy")
	await c.say("tiel", "세 번 데우면 풀려! 네 번은 안 돼, 녹아!")
	c.close_box()
	c.flag("e_met_tiel")
	c.quest_start("e_tiel_valve")
	if _n(VALVES) >= 3:
		c.quest_step("e_tiel_valve", 1)


func e_wind_teach(c: Cut) -> void:
	c.release()
	c.bubble("옆바람이 거꾸로 부는구나. 저 밸브를 불로 돌려 보거라.", 3.0)


# ═══════════════════════════════════════════════════════════
# 가지 마을 · 달샘 — "잠재우는 불"
# ═══════════════════════════════════════════════════════════

func enter_e_branch_homes(c: Cut) -> void:
	if c.has("e_wind_done"):
		return
	c.flag("e_wind_done")
	c.flag("e_lift_fixed")
	c.lock()
	await c.wait(0.5)
	await c.say("sera", "후… 바람길 끝! 여기가 가지 마을이구나.", "happy")
	await c.say("neoul", "바람이 제자리를 찾았구나. …아래에서 덜컹, 하는 소리가 나는데.")
	c.close_box()
	c.sfx("chain")
	c.shake(0.1, 0.6)
	await c.narrate("멀리서 승강기 바퀴가 다시 돌기 시작했다. — 이제 승강기로 뿌리 마을·줄기 시장·가지 마을을 오갈 수 있다.")
	await c.say("neoul", "장로가 말한 달샘은 위층 가지 오른쪽 끝이라 했지.")
	c.close_box()
	c.save()


func e_moon_arrive(c: Cut) -> void:
	if c.has("e_moon_talk"):
		return
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "여기가 달샘… 천장 틈으로 달빛이 방울져 떨어져.", "surprised")
	await c.camera_to(Vector2(38 * 16, 14 * 16), 0.8)
	await c.say("neoul", "세라. 저 뿌리 너머, 하얀 숲이 보이느냐.")
	await c.say("neoul", "저것을 태우려 들지 말거라. 태우는 불은 저 하양을 더 단단하게 할 뿐이니라.")
	c.close_box()
	await c.camera_back(0.6)
	await c.say("sera", "그럼 어떻게 해? 내 불은 태우는 것밖에 몰라.", "sad")
	await c.say("neoul", "……달빛을 보거라. 떨어지는 빛을 방벽으로 받아, 위로 돌려보내라. 매달린 수정 셋에.")
	await c.say("neoul", "불을 '두르는' 손으로 빛을 돌려보내다 보면 — 알게 될 게다.")
	c.close_box()
	c.flag("e_moon_talk")
	await c.teach("달빛 되쏘기", "달빛 방울이 떨어질 때 불꽃 방벽을 펼치면 곧장 위로 되쏘아진다.\n위에 매달린 수정 셋을 모두 밝히자. (방벽은 마법서에서 A·S 칸에 끼워 쓴다)", ["skill_1", "skill_2"])


## 달빛 수정 셋 → 너울의 가르침 → e_moon_lesson (뿌리 문 열림, 역병 덩굴이 불을 받아들임)
func e_moon_lesson(c: Cut) -> void:
	c.lock()
	await c.wait(0.8)
	c.flash(Color(0.8, 0.85, 1.0, 0.5), 0.6)
	c.sfx("star_twinkle")
	await c.wait(0.4)
	await c.say("neoul", "…보았느냐. 네 불이 빛을 '돌려'보냈다. 아무것도 태우지 않고.", "happy")
	await c.say("neoul", "흰 역병은 아무것도 아닌 것 — 빈자리니라. 태우는 불은 그 빈자리를 넓힐 뿐이다.")
	await c.say("neoul", "하지만 지키려는 불, 잠재우는 불은 그 빈자리를 채운다. 옛날 네 학교를 세운 마녀가 그리 했다지.")
	await c.say("sera", "잠재우는 불…")
	await c.say("sera", "……해 볼게. 태우는 게 아니라, 재우는 거. 아귀한테 했던 것처럼.", "happy")
	await c.say("neoul", "그래. 이제 저 하얀 덩굴에 손을 얹듯 불을 대 보거라.", "happy")
	c.close_box()
	c.flag("e_moon_lesson")
	await c.wait(0.8)
	c.bubble("뿌리가 물러났구나. 흰 숲으로 가자.", 2.6)


## 역병 덩굴: 잠재우는 불을 배우기 전 (blight_vine hint)
func e_vine_hint(c: Cut) -> void:
	c.bubble("불이 하얀 결정에 먹혀 버리는구나… 태우는 불로는 안 된다. 장로가 말한 달샘에 가 보자꾸나.", 3.4)


## 첫 덩굴 정화 (blight_vine first)
func e_vine_first(c: Cut) -> void:
	c.bubble("…타지 않고 잠들었구나. 초록 새순이 보이느냐, 세라.", 3.0)


# ═══════════════════════════════════════════════════════════
# 흰 역병의 숲 — 굳은 숲의 심장
# ═══════════════════════════════════════════════════════════

func e_blight_arrive(c: Cut) -> void:
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "…소리가 없어. 새도, 벌레도.", "sad")
	await c.say("neoul", "흰 역병의 숲이니라. 저 흰 벌레들은… 이 세상 것이 아니구나. 조심하거라.")
	await c.say("neoul", "덩굴부터 잠재우거라. 아까 배운 대로.")
	c.close_box()


func e_heart_arrive(c: Cut) -> void:
	c.lock()
	await c.camera_to(Vector2(68 * 16, 14 * 16), 1.0)
	await c.say("sera", "저게… 숲의 심장?", "surprised")
	await c.say("neoul", "흰 것이 가장 짙게 뭉친 곳이니라. 저것을 잠재우면 숲이 숨을 쉴 게다.")
	await c.say("neoul", "크다. 여러 번 불을 대야 할 게야. 지키는 벌레도 있구나.")
	c.close_box()
	await c.camera_back(0.8)
	c.save()


## 심장 정화 (e_heart_burnt 사건) → 숲이 되살아남 → 엘라리엔 "시험이다" → e_grove_purified
func e_grove_purify(c: Cut) -> void:
	c.lock()
	await c.wait(1.6)
	c.flag("e_grove_purified")
	Ch3Sfx.play(&"ch3_purify", 2.0, 0.0)
	c.flash(Color(0.85, 1.0, 0.7, 0.6), 1.0)
	_pollen(c)
	await c.wait(0.8)
	await c.narrate("하얗게 굳었던 가지에서, 초록이 번져 나갔다.")
	await c.say("sera", "됐다… 타지 않았어. 잠들었어!", "happy")
	c.close_box()
	var p := _ptile(c)
	c.spawn_npc("elarien", p.x + 5.0, p.y - 6.0, -1)
	await c.move("elarien", p.x + 4.0, p.y, 0.45, Tween.TRANS_QUAD)
	c.face("elarien", -1 if c.player.global_position.x < (p.x + 4.0) * 16.0 else 1)
	await c.wait(0.3)
	await c.say("elarien", "………")
	await c.say("elarien", "불을 쓰는데, 숲이 타지 않았다.", "surprised")
	await c.say("sera", "말했잖아요. 편지 심부름 온 거라고.", "happy")
	await c.say("elarien", "역병의 근원은 꼭대기다. 수관 위, 하얀 것이 둥지를 틀었다.", "focus")
	await c.say("elarien", "하지만 거기 보낼지는 내가 정한다. 수관 경기장으로 와라. 가지 마을 위층 계단이다.")
	await c.say("elarien", "시험이다. 마녀가 숲에 들어올 자격이 있는지.", "smirk")
	c.close_box()
	await c.move("elarien", p.x + 10.0, p.y - 10.0, 0.4)
	c.hide_actor("elarien")
	await c.say("neoul", "흥, 시험이라니. 여우신의 그릇을 시험한다고?", "angry")
	await c.say("sera", "그릇이라고 하지 말랬지.", "angry")
	await c.say("sera", "…그러고 보니 피피가 그랬지. 유성이 떨어질 하늘이라고.")
	await c.say("neoul", "학교 게시판에 새 수업이 붙었을지도 모르겠구나. 별을 떨어뜨리는 불이라던가.")
	c.close_box()
	c.save()
	Story.toast("가지 마을 위층 계단(수관)이 열렸다. 학교 수업 게시판에 '유성 낙화' 수업이 열렸다(선택).", 4.0)


# ═══════════════════════════════════════════════════════════
# 수관 · 사냥 시험
# ═══════════════════════════════════════════════════════════

func enter_e_canopy_1(c: Cut) -> void:
	if not c.has("e_meteor_hint"):
		c.flag("e_meteor_hint")
	if not c.has("e_canopy_seen"):
		c.flag("e_canopy_seen")
		await c.wait(0.8)
		c.bubble("잎 사이로 하늘이 보이는구나. 저 등불의 나방들, 등불에 앉아 쉴 때가 빈틈이니라.", 3.4)


func e_hunt_offer(c: Cut) -> void:
	if c.has("e_hunt_offer"):
		return
	c.flag("e_meteor_hint")
	c.lock()
	c.face("elarien", -1)
	await c.say("elarien", "왔군.")
	await c.say("elarien", "규칙은 하나. 내가 경기장에서 너를 사냥한다. 너는 나에게 세 번 닿아라.", "focus")
	await c.say("sera", "닿기만 하면 돼요? 이기는 게 아니라?")
	await c.say("elarien", "가까이 와서 몸에 닿든, 곁에서 불을 맞히든, 내 화살을 돌려보내든. 셋.")
	await c.say("elarien", "멀리서 쏘는 불은 안 맞는다. 바람이 다 알려 주니까.", "smirk")
	await c.say("neoul", "…닿으라니. 사냥꾼이 사냥감에게 거리를 내주겠다는 게냐.")
	await c.say("elarien", "준비되면 올라와라. 기록은 해 두고.")
	c.close_box()
	c.flag("e_hunt_offer")
	await c.walk("elarien", 72.0, 90.0)
	c.sfx("door")
	c.hide_actor("elarien")


## 수관 경기장: 사냥 시험 (강자 보스 — 세 번 닿기). 쓰러지면 다시 들어올 때 "다시."
func e_hunt_begin(c: Cut) -> void:
	if c.has("e_hunt_done"):
		return
	var e := c.enemy("elarien_hunt") as ElarienHunt
	if e == null or not e.is_alive():
		await _hunt_after(c, null)
		return
	if e.engaged:
		return
	c.lock()
	if not c.has("e_hunt_seen"):
		c.flag("e_hunt_seen")
		await c.camera_to(e.global_position + Vector2(0, 30), 1.0)
		await c.say("elarien", "위다.", "focus")
		await c.say("elarien", "가지는 네 발판이고, 나는 바람이다. 올라와 봐라.")
		c.close_box()
		await c.camera_back(0.8)
		await c.teach("세 번 닿기", "엘라리엔에게 세 번 닿으면 끝 — 체력 싸움이 아니다.\n① 몸에 부딪치기  ② 4칸 안에서 불 맞히기  ③ 화살을 불꽃 방벽으로 되쏘기\n붉은 예고선이 흰색으로 깜빡이면 곧 화살 — 가지를 옮겨 피하자.", ["jump"])
	else:
		await c.say("elarien", "다시.", "focus")
		c.close_box()
	c.music("elf_hunt")
	var won := [false]
	e.defeated.connect(func(_who: Variant) -> void: won[0] = true)
	e.touched.connect(func(n: int) -> void:
		if n == 1:
			c.bubble("닿았다! 그 기세다, 세라!", 2.0)
		elif n == 2:
			c.bubble("하나만 더! 화살비가 온다 — 붉은 표시를 보거라!", 2.6))
	e.engaged = true
	c.release()
	await c.wait_enemy(e)
	if not c.ok() or not won[0]:
		return # 쓰러졌거나 경기장을 나감 → 다시 들어오면 "다시."
	await _hunt_after(c, e if is_instance_valid(e) else null)


func _hunt_after(c: Cut, e: EnemyBase) -> void:
	c.lock()
	c.flag("e_hunt_done")
	await c.wait(1.0)
	var at := Vector2(20, 17)
	if is_instance_valid(e):
		at = e.global_position / 16.0
		e.visible = false
	var p := _ptile(c)
	var side := 1.0 if at.x >= p.x else -1.0
	c.spawn_npc("elarien", at.x, at.y, -1)
	await c.move("elarien", clampf(p.x + side * 3.0, 2.0, 37.0), p.y, 0.5, Tween.TRANS_QUAD)
	c.face("elarien", -int(side))
	c.music("elf", 1.5)
	await c.say("elarien", "……셋.", "smirk")
	await c.say("sera", "헉… 헉… 닿았다…!", "happy")
	await c.say("elarien", "닿았다. 인정한다.")
	await c.say("sera", "근데… 화살이 한 번도 저를 제대로 안 노렸죠? 일부러.", "surprised")
	await c.say("elarien", "맞히는 건 쉽다. 안 맞히는 게 어렵지.", "smirk")
	await c.say("elarien", "…네 불도 그렇더군. 태우는 건 쉽다. 안 태우는 게 어렵지.")
	await c.say("neoul", "허. 사냥꾼이 철학을 하는구나.")
	c.close_box()
	_beside(c, "warden_a", -4.0)
	await c.say("warden_a", "엘라리엔! 큰일이다! 아이들이… 피오랑 아이들이 꼭대기로 올라갔어!", "surprised")
	await c.say("elarien", "…뭐?", "surprised")
	await c.say("warden_a", "하얀 것이 꼭대기에서 노래를 불렀다고… 아이들이 홀린 것처럼 따라갔다고!")
	await c.say("elarien", "………", "angry")
	await c.say("elarien", "세라피나. 따라와라. 경기장 꼭대기 계단이다.", "angry")
	c.close_box()
	c.flag("e_fio_gone")
	await c.move("elarien", 17.0, 9.0, 0.6, Tween.TRANS_QUAD)
	c.sfx("door")
	c.hide_actor("elarien")
	c.hide_actor("warden_a")
	c.bubble("서두르자, 세라!", 2.0)


# ═══════════════════════════════════════════════════════════
# 꼭대기 · 백색 사도 (엘라리엔 엄호)
# ═══════════════════════════════════════════════════════════

## 사도전에 지고 돌아오면 동료·결계를 처음 상태로
func _herald_reset(c: Cut) -> void:
	if c.has("e_herald_done"):
		return
	if c.ally("elarien"):
		c.ally_leave("elarien")
	if c.has("e_herald_fight"):
		c.flag("e_herald_fight", false)


func enter_e_crown_1(c: Cut) -> void:
	_herald_reset(c)


func enter_e_crown_2(c: Cut) -> void:
	_herald_reset(c)


func enter_e_crown_nest(c: Cut) -> void:
	_herald_reset(c)


func e_crown_arrive(c: Cut) -> void:
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "꼭대기가… 전부 하얘.", "surprised")
	await c.say("neoul", "…아이들 냄새가 이 위로 이어지는구나. 서두르자, 세라.")
	c.close_box()
	c.save()


func e_herald_begin(c: Cut) -> void:
	if c.has("e_herald_done"):
		return
	var h := c.enemy("white_herald") as WhiteHerald
	if h == null or not h.is_alive():
		await _herald_after(c)
		return
	if h.engaged:
		return
	c.lock()
	c.flag("e_herald_fight")
	var kid := c.spawn_npc("elf_c", 3.0, 19.0, 1)
	kid.emote("sweat", 3.0)
	if not c.has("e_herald_seen"):
		c.flag("e_herald_seen")
		Music.stop(1.0)
		var el := c.spawn_npc("elarien", 5.0, 19.0, 1)
		el.visual.set_pose("kneel")
		await c.camera_to(h.global_position + Vector2(0, -50), 1.2)
		await c.narrate("「……불…… 꺼라…… 숲은…… 잠들어라……」")
		var pod := c.actor("pod")
		if pod and pod.has_method("struggle"):
			pod.struggle()
		await c.camera_to(Vector2(68 * 16 + 8, 8 * 16), 0.7)
		await c.say("fio", "누나…! 마녀 누나…!", "sad")
		await c.say("sera", "피오!", "surprised")
		c.close_box()
		await c.camera_back(0.6)
		await c.say("elarien", "…늦었다. 내가.", "hurt")
		await c.say("elarien", "아이들을 감싸다 한 대 맞았다. 다리가… 말을 안 듣는군.", "hurt")
		await c.say("sera", "엘라리엔!", "surprised")
		await c.say("elarien", "괜찮다. 화살 하나 빗나갔을 뿐이다.", "tired")
		await c.say("elarien", "저 위 가지로 오르겠다. 놈의 수정 눈을 쏜다 — 눈이 깨지면 놈이 땅에 떨어진다.", "focus")
		await c.say("elarien", "그때 쳐라. 네 불로.", "focus")
		await c.say("neoul", "…바깥에서 온 것이로구나. 세라, 저건 아귀와 다르다. 굶주림도, 미움도 없다. 그냥 '비어' 있느니라.", "scary")
		c.close_box()
		c.hide_actor("elarien")
	else:
		await c.say("neoul", "다시 가자, 세라. 아이들이 기다린다.")
		c.close_box()
	var a := c.ally_join("elarien", 27.0, 8.0)
	a.mode = "hold"
	a.say("엄호한다.")
	c.music("herald")
	var phase := [1]
	var won := [false]
	h.phase_changed.connect(func(n: int) -> void: phase[0] = n)
	h.defeated.connect(func(_who: Variant) -> void: won[0] = true)
	h.engaged = true
	c.release()
	await c.teach("엘라리엔의 엄호", "엘라리엔이 때때로 사도의 수정 눈을 쏜다 — 눈이 깨지면 사도가 땅에 떨어져 잠시 무방비(피해가 크게 들어감).\n흰 띠(빛창)·육각 감옥은 굵게 깜빡인 뒤 꽂힌다. 띠 밖으로, 감옥 밖으로!", ["attack"])
	var t := 4.0
	var said := 1
	while c.ok() and is_instance_valid(h) and h.is_alive():
		await c.wait(0.5)
		t += 0.5
		if t >= SNIPE_EVERY and is_instance_valid(a):
			t = 0.0
			a.special(h)
		if phase[0] >= 2 and said < 2:
			said = 2
			a.say("눈 하나 더. 버텨라!")
		if phase[0] >= 3 and said < 3:
			said = 3
			c.lock()
			await c.narrate("「……별의…… 그릇……」")
			await c.narrate("「……찾았다……」")
			await c.say("neoul", "……감히.", "scary")
			await c.say("sera", "그릇 아니라니까! 다들 왜 그래!", "angry")
			c.close_box()
			c.release()
	if not c.ok() or not won[0]:
		return
	await _herald_after(c)


func _herald_after(c: Cut) -> void:
	c.lock()
	c.flag("e_herald_done")
	c.flag("e_herald_fight", false)
	Music.stop(2.0)
	await c.wait(2.2)
	var pod := c.actor("pod")
	if pod and pod.has_method("crack"):
		await pod.crack()
	c.spawn_npc("fio", 68.0, 12.0, -1)
	await c.move("fio", 68.0, 19.0, 0.5, Tween.TRANS_QUAD)
	var a := c.ally("elarien")
	if a:
		a.mode = "script"
	c.flash(Color(0.85, 1.0, 0.7, 0.6), 1.2)
	Ch3Sfx.play(&"ch3_purify", 4.0, 0.0)
	_pollen(c)
	c.music("elf", 2.0)
	await c.narrate("사도가 흩어진 자리에서, 세계수 꼭대기의 하양이 녹듯 물러났다. 연둣빛 꽃가루가 비처럼 내렸다.")
	await c.approach("fio", 1.6, 120.0)
	await c.say("fio", "누나아…!", "sad")
	await c.say("sera", "피오! 다친 데 없어?", "surprised")
	await c.say("fio", "하얀 게 노래했어… 별 노래… 따라가면 안 되는 거였는데…", "sad")
	await c.say("sera", "괜찮아. 이제 다 끝났어.", "happy")
	c.close_box()
	if c.ally("elarien"):
		c.ally_leave("elarien")
	_beside(c, "elarien", -4.0)
	await c.say("elarien", "………")
	await c.say("elarien", "네 불은 숲을 태우지 않는구나.", "happy")
	await c.say("sera", "…응. 이제 나도 알았어.", "happy")
	await c.say("elarien", "세라피나. 숲은 너를 기억할 거다. …나도.", "smirk")
	c.close_box()
	c.flag("e_fio_gone", false)
	await c.fade_out(1.5)
	await c.goto_room("e_elder_hall", "door")
	await _ending_elder(c)


## 끝 1: 장로의 집 — "한 아이는 남고, 한 아이는 별을 보러 떠났지"
func _ending_elder(c: Cut) -> void:
	c.lock()
	c.spawn_npc("elarien", 15.0, 19.0, 1)
	c.spawn_npc("fio", 19.0, 19.0, 1)
	c.player.global_position = Vector2(22 * 16 + 8, 19 * 16)
	c.player_face(1)
	await c.fade_in(1.2)
	await c.say("ortia", "허허… 세계수가 다시 숨을 쉬는구먼. 꽃가루 냄새가 여기까지 나는군.", "happy")
	await c.say("ortia", "고맙네, 세라피나. 그리고 너울 님.", "happy")
	await c.say("neoul", "…흥. 인사는 받아 두마.", "happy")
	await c.say("sera", "장로님. 그 하얀 것이… 저를 '별의 그릇'이라고 불렀어요.", "sad")
	await c.say("ortia", "………", "serious")
	await c.say("ortia", "옛날, 별을 다루는 마녀가 있었네. 자네 학교를 세운 마녀지. 그분에게 두 제자가 있었어.", "serious")
	await c.say("ortia", "한 아이는 남고, 한 아이는 별을 보러 떠났지.", "serious")
	await c.say("sera", "남은 아이가… 교장 선생님?", "surprised")
	await c.say("ortia", "허허. 떠난 아이 이야기는, 언젠가 아스트리드가 직접 해 주겠지.", "happy")
	await c.say("ortia", "학교로 돌아가게. 오늘 밤은 푹 자야 할 얼굴이구먼.", "happy")
	await c.say("fio", "누나, 또 와! 별이 될 씨앗 심는 거 보여 줄게!", "happy")
	await c.say("elarien", "…다음엔 모자 말고 과녁을 맞혀 보자. 활터에서 기다리겠다.", "smirk")
	c.close_box()
	c.save_here("door")
	await c.fade_out(1.5)
	await c.goto_room("s_dorm", "ch3_night")
	await _ending_dorm(c)


## 끝 2: 기숙사의 밤 → 꼬리 셋 → 달 위의 그림자 → 4장
func _ending_dorm(c: Cut) -> void:
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.music("ending")
	c.player_face(1)
	await c.wait(0.5)
	await c.fade_in(2.0)
	await c.wait(0.6)
	await c.say("sera", "…너울. 자?")
	await c.say("neoul", "…자는 중이니라.")
	await c.say("sera", "별의 그릇이 뭘까.", "sad")
	await c.say("neoul", "……모른다. 하지만 그 하얀 것이 너를 그릇이라 부를 때, 화가 났느니라.")
	await c.say("sera", "너도 맨날 그릇이라고 부르잖아.", "angry")
	await c.say("neoul", "…그래서 화가 났느니라. 세라.", "sad")
	await c.say("sera", "……방금 '세라'라고 했어?", "surprised")
	await c.say("neoul", "잠이나 자거라.", "angry")
	c.close_box()
	c.flag("e_end")
	await c.wait(0.6)
	await c.tails(3)
	await c.say("neoul", "…꼬리가 하나 더 돋았구나. 세계수의 숨이 내 구슬까지 닿았나 보다.", "happy")
	c.close_box()
	await c.fade_out(1.2)
	await c.narrate("그 밤. 학교 위, 아주 높은 곳.")
	c.close_box()
	await Ch3MoonScene.play(c.world, 6.5)
	c.save_here("bed")
	await ChapterFlow.finish(c, 3)


# ═══════════════════════════════════════════════════════════
# 인물 대화 (엘프의 숲)
# ═══════════════════════════════════════════════════════════

func npc_ortia(c: Cut) -> void:
	if not c.has("e_met_ortia"):
		await c.say("ortia", "허허, 손님이구먼.", "happy")
		return
	var st := Quests.state("e_ortia_tea")
	var n := _n(TEA)
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
	var n := _n(SEEDS)
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
	if _n(SEEDS) < 5:
		await c.say("fio", "지금 %d개야! 마을, 우리 집, 시장, 바람길, 가지 마을!" % _n(SEEDS))
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
	var n := _n(VALVES)
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


# ═══════════════════════════════════════════════════════════
# 학교 인물 (3장 덮어쓰기 npc_<who>_ch3) · 서브 퀘스트
# ═══════════════════════════════════════════════════════════

func npc_pippa_ch3(c: Cut) -> void:
	var st := Quests.state("e_pippa_moss")
	var n := _n(MOSS)
	if st == 0 and c.has("e_start"):
		await c.say("pippa", "세라, 세라! 엘프 숲에 간다며? 부탁 하나만!", "happy")
		await c.say("pippa", "세계수 뿌리 쪽에 빛이끼가 자란대. 그걸로 약을 만들면 묘목이 덜 굳을지도 몰라!")
		await c.say("pippa", "표본 세 개! 동굴 같은 데, 축축한 곳에 있을 거야. 부탁해!", "happy")
		c.close_box()
		c.quest_start("e_pippa_moss")
		if n >= 3:
			c.quest_step("e_pippa_moss", 1)
		return
	if st == 1:
		if n >= 3:
			await e_pippa_moss_done(c)
		else:
			await c.say("pippa", "빛이끼는 세계수 뿌리 동굴 어딘가! 숨은 구석도 꼭 봐! (%d/3)" % n)
		return
	if c.has("e_herald_done"):
		await c.say("pippa", "묘목이 다시 초록이 됐어! 잎이 막 반짝여! 네 덕분이야, 세라!", "happy")
	else:
		await c.say("pippa", "묘목은 내가 지키고 있을게. 넌 엘프 숲 잘 다녀와!", "happy")


func e_pippa_moss_done(c: Cut) -> void:
	await c.say("pippa", "우와아! 반짝반짝해! …냄새는 좀 꾸리하지만!", "happy")
	await c.say("pippa", "이거 받아! 연금술 재료 사려고 모은 거지만… 네가 더 잘 쓸 거야.", "happy")
	c.close_box()
	await c.quest_done("e_pippa_moss")


func npc_butterworth_ch3(c: Cut) -> void:
	var st := Quests.state("e_honey")
	if st == 0 and c.has("e_start"):
		await c.say("butterworth", "세라, 엘프 숲에 간다고? 거기 숲 꿀 말이야… 한 숟갈이면 사흘을 버틴단다.", "happy")
		await c.say("butterworth", "구해 오면 기가 막힌 걸 만들어 주마. 꿀은 오래된 벌집에 있지. 그런 건 꼭 숨겨진 데 있더라.")
		c.close_box()
		c.quest_start("e_honey")
		if c.has("e_honey_got"):
			c.quest_step("e_honey", 1)
		return
	if st == 1:
		if c.has("e_honey_got"):
			await e_honey_done(c)
		else:
			await c.say("butterworth", "꿀은 오래된 벌집에 있단다. 사람 발길 안 닿는 숨겨진 곳 말이야.")
		return
	await c.say("butterworth", "숲빵 맛있었지? 배고프면 언제든 오너라.", "happy")


func e_honey_done(c: Cut) -> void:
	await c.say("butterworth", "이 빛깔 좀 봐라! 진짜 숲 꿀이구나!", "happy")
	await c.say("butterworth", "자, 꿀 바른 숲빵이다. 먹고 쑥쑥 크거라!", "happy")
	c.close_box()
	await c.quest_done("e_honey")


func npc_astrid_ch3(c: Cut) -> void:
	if c.has("e_herald_done"):
		await c.say("astrid", "세계수가 꽃을 피웠다고 오르티아에게서 소식이 왔어요. …잘했어요, 세라피나 양.", "happy")
		await c.say("astrid", "그분이 제 이야기를 하던가요? …나쁜 이야기만 아니면 좋겠네요.", "smug")
	elif c.has("e_letter"):
		await c.say("astrid", "숲의 화살은 조심하셨나요? …어머, 모자에 구멍이 났군요.", "smug")
	else:
		await c.say("astrid", "어서 오세요.")


## 학교 결투 대회 (s_duel_cup): 앞마당의 이졸데 → 결투장
func npc_isolde_ch3(c: Cut) -> void:
	var st := Quests.state("s_duel_cup")
	if st == 2:
		await c.say("isolde", "…뭘 봐. 다음엔 내가 이길 거야. 서리 마법 연습 중이니까.", "angry")
		return
	if not c.has("e_letter"):
		await c.say("isolde", "결투 대회 결승. 상대가 너라니. …교장실부터 다녀와. 기다려 줄 테니.", "smug")
		return
	if st == 0:
		await c.say("isolde", "세라. 결투 대회 결승이야. 네가 지하 괴물을 잡았다는 소문 때문에 다들 시끄러워.", "smug")
		await c.say("isolde", "내가 이기면 그 소문, 내 이름으로 바꿔 부르게 할 거야.")
		await c.say("sera", "…그거 그렇게 갖고 싶은 소문이야?", "surprised")
		await c.say("isolde", "시끄러워. 받을 거야, 말 거야?", "angry")
		c.quest_start("s_duel_cup")
	if Quests.active("cls_meteor") and Quests.step("cls_meteor") >= 3 and not GameState.has_ability("meteor"):
		await c.say("isolde", "…결투장은 지금 베로니카 교수님 시험 중이야. 그거 끝나고 와.")
		return
	var pick := await c.choose("isolde", "결투장으로. 지금 바로.", ["붙자", "나중에"])
	if pick != 0:
		await c.say("isolde", "도망치는 건 아니겠지?", "smug")
		return
	await c.say("isolde", "좋아. 봐주지 않아.", "smug")
	c.close_box()
	await c.fade_out(0.6)
	await c.goto_room("s_duel", "in")
	await _isolde_duel(c)


func _isolde_duel(c: Cut) -> void:
	c.lock()
	c.player.global_position = Vector2(20 * 16 + 8, 19 * 16)
	c.player_face(1)
	var b := c.spawn_enemy("isolde_duel", 60.0, 19.0, "isolde_duel", {"engaged": false})
	if b == null:
		return
	b.facing = -1
	var won := [false]
	b.defeated.connect(func(_who: Variant) -> void: won[0] = true)
	await c.wait(0.4)
	await c.say("isolde", "결투 대회 결승. 이졸데 폰 크레스트 — 서리의 고급반.", "smug")
	await c.say("sera", "…일반반 세라피나. 불.", "angry")
	c.close_box()
	c.music("boss")
	b.engaged = true
	c.release()
	await c.wait_enemy(b, 0.5)
	if not c.ok() or not is_instance_valid(b):
		return
	if b.is_alive():
		c.bubble("빙판 질주다! 붉은 띠 밖으로 피하거라!", 2.4)
	await c.wait_enemy(b)
	if not c.ok() or not won[0]:
		return # 쓰러졌거나 결투장을 나감 → 앞마당의 이졸데에게 다시
	c.lock()
	var at := b.global_position / 16.0 if is_instance_valid(b) else Vector2(60, 19)
	await c.wait(0.6)
	c.spawn_npc("isolde", at.x, 19.0, -1 if c.player.global_position.x < at.x * 16.0 else 1)
	c.music("school_day", 2.0)
	await c.say("isolde", "………", "angry")
	await c.say("isolde", "…졌네. 인정해.", "sad")
	await c.say("isolde", "네 불, 예전처럼 막 터지지 않더라. 꼭… 누굴 지키는 것처럼.", "surprised")
	await c.say("sera", "칭찬이야?", "happy")
	await c.say("isolde", "아니거든! 이건 우승 상품. 수호의 깃털. …내가 받으려던 건데.", "angry")
	c.close_box()
	await c.quest_done("s_duel_cup")
	c.flag("s_duel_won")
	c.save()


# ─── 개발용 (시나리오 tools/test/scenarios/ch3_*.json 에서 부름) ───

## 시험 방 인물: 말을 걸어도 아무 일 없음
func dev_ch3_silent(_c: Cut) -> void:
	pass


## 초상화 점검: 3장 인물의 표정을 차례로
func dev_ch3_portrait(c: Cut) -> void:
	await c.say("elarien", "…돌아가라, 마녀. 다음은 모자가 아니다.", "normal")
	await c.say("elarien", "맞히는 건 쉽다. 안 맞히는 게 어렵지.", "smirk")
	await c.say("elarien", "바람이 오른쪽에서 분다. 셋을 세면 쏜다.", "focus")
	await c.say("elarien", "…아이들을 건드렸다고?", "angry")
	await c.say("elarien", "네 불은… 숲을 태우지 않는구나.", "happy")
	await c.say("elarien", "하나.", "surprised")
	await c.say("elarien", "…늦었다. 내가.", "sad")
	await c.say("elarien", "괜찮다. 화살 하나 빗나갔을 뿐이다.", "hurt")
	await c.say("elarien", "…오늘은 그만 쏘자.", "tired")
	await c.say("ortia", "아스트리드라… 그 꼬마가 교장이라니. 세월 참 빠르구나.", "happy")
	await c.say("ortia", "한 아이는 남고, 한 아이는 별을 보러 떠났지.", "serious")
	await c.say("ortia", "…역병이 꼭대기까지?", "surprised")
	await c.say("fio", "마녀 누나! 그 모자 진짜 구멍 났어? 보여 줘, 보여 줘!", "happy")
	await c.say("fio", "…엘라리엔 언니는 무서운 게 아니야. 말이 없을 뿐이야.", "sad")
	await c.say("tiel", "바람 밸브 3번이 또 막혔어. 불로 한 번 데우면 돌아갈 거야!", "surprised")
	await c.say("elf_warden", "멈춰라. 장로님의 허락 없이는 지나갈 수 없다.", "angry")


## 엘라리엔 자세 점검: 자세마다 한 명씩 세워 둔다 (시험 방 dev_e_tree 바닥 19행)
func dev_ch3_poses(c: Cut) -> void:
	var poses := ["idle", "walk", "run", "aim", "attack", "attack2", "windup", "guard", "hurt", "kneel", "down", "special", "charge", "leap"]
	var x0 := c.player.global_position.x / 16.0 - 18.5
	for i in poses.size():
		var pose: String = poses[i]
		var n := Npc.new()
		n.setup(c.world.room, {"who": "elarien", "x": x0 + i * 2.8, "y": 19, "face": "right", "talk": "dev_ch3_silent"}, "pose_" + pose)
		c.world.room.add_entity(n)
		if pose == "walk":
			n.visual.walking = true
		else:
			n.visual.set_pose(pose)
		if pose == "aim":
			n.visual.set_meta("aim_ang", -0.25)
		var lb := Label.new()
		lb.text = pose
		lb.position = Vector2(-10, -50 - (i % 2) * 8)
		lb.add_theme_font_size_override("font_size", 8)
		n.add_child(lb)
	await c.wait(0.1)


## 엘프 인물 자세 점검 (파수꾼 자세 + 피오·티엘·장로)
func dev_ch3_folk(c: Cut) -> void:
	var specs := [["elf_warden", "idle"], ["elf_warden", "windup"], ["elf_warden", "attack"], ["elf_warden", "guard"], ["elf_warden", "hurt"],
		["elf_warden", "kneel"], ["ortia", "idle"], ["ortia", "special"], ["fio", "idle"], ["tiel", "idle"], ["elf_c", "idle"]]
	var x0 := c.player.global_position.x / 16.0 - 16.0
	for i in specs.size():
		var who: String = specs[i][0]
		var pose: String = specs[i][1]
		var n := Npc.new()
		n.setup(c.world.room, {"who": who, "x": x0 + i * 3.0, "y": 19, "face": "right", "talk": "dev_ch3_silent"}, "folk_%d" % i)
		c.world.room.add_entity(n)
		n.visual.set_pose(pose)
	await c.wait(0.1)


## 시험: 사냥 시험 보스 곁으로 세라를 옮김 (몸에 닿기 시험)
func dev_ch3_touch_elarien(c: Cut) -> void:
	c.release() # 보스전 대본이 도는 중에 불려도 적을 멈추지 않게
	var e := c.enemy("elarien_hunt")
	if e:
		c.player.global_position = e.global_position + Vector2(-10, 0)
		c.player.velocity = Vector2.ZERO


## 시험: 되쏜 화살이 사냥 시험 보스를 맞힘 (Hit.kind = reflect)
func dev_ch3_reflect_elarien(c: Cut) -> void:
	c.release() # 보스전 대본이 도는 중에 불려도 적을 멈추지 않게
	var e := c.enemy("elarien_hunt")
	if e:
		e.take_hit(Hit.make(150, &"reflect", e.global_position + Vector2(-200, -16), 1))


## 시험: 세라를 백색 사도 왼쪽 6T에 세움 (사도를 바라봄)
func dev_ch3_near_herald(c: Cut) -> void:
	c.release() # 보스전 대본이 도는 중에 불려도 적을 멈추지 않게
	var e := c.enemy("white_herald")
	if e:
		c.player.global_position = Vector2(e.global_position.x - 6.0 * 16.0, c.player.global_position.y)
		c.player.facing = 1


## 시험: 끝 장면(달 위의 그림자)만
func dev_ch3_moon(c: Cut) -> void:
	await Ch3MoonScene.play(c.world, 6.5)


## 시험: 사도의 둥지 꼬투리 꿈틀 → 깨짐
func dev_ch3_pod(c: Cut) -> void:
	var pod := c.actor("pod")
	if pod == null:
		return
	await c.camera_to(pod.global_position + Vector2(0, -20), 0.4)
	pod.struggle()
	await c.wait(1.0)
	await pod.crack()
	await c.wait(0.5)
	await c.camera_back(0.3)


## 시험: 동료 저격 — 백색 사도의 수정 눈을 깸
func dev_ch3_snipe(c: Cut) -> void:
	c.release() # 보스전 대본이 도는 중에 불려도 적을 멈추지 않게
	var e := c.enemy("white_herald") as WhiteHerald
	if e:
		e.snipe_eye()
