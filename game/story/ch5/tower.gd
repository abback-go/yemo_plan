extends "res://story/ch5/common.gd"
## 5장 대본 — 4~7. 별의 탑(기억 조각·교장의 별빛) · 리라 결전 · 진실 · 침공.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 4. 별의 탑
# ═══════════════════════════════════════════════════════════

func enter_st_tower_1(c: Cut) -> void:
	_leave_all(c)
	if c.has("st_tower_seen"):
		return
	c.flag("st_tower_seen")
	c.lock()
	await c.wait(0.4)
	await c.say("neoul", "…별자리 계단이니라. 저 떨어진 별들을 아래에서 위로 쏘아 잇거라.")
	await c.say("neoul", "그리고 벽의 수정들. 별빛에 기억이 갇혀 있구나. 들여다보면 무언가 보일 게다.")
	c.close_box()
	c.save_here("in")
	c.release()


func st_t1_done(c: Cut) -> void:
	await c.wait(0.3)
	c.bubble("길이 생겼느니라! 별을 밟고 오르거라.", 2.6)


func st_t3_done(c: Cut) -> void:
	await c.wait(0.3)
	c.bubble("잘했느니라. 위로!", 2.2)


func enter_st_tower_2(c: Cut) -> void:
	if c.has("st_tower2_seen"):
		return
	c.flag("st_tower2_seen")
	await c.wait(0.5)
	c.bubble("별 정령의 회랑이로구나. 선이 꺼진 틈을 노리거라.", 2.8)


func enter_st_tower_4(c: Cut) -> void:
	if c.has("st_tower4_seen"):
		return
	c.flag("st_tower4_seen")
	await c.wait(0.5)
	c.bubble("…발밑이 끊겼느니라. 저 문양, 위아래가 뒤집힌 별이구나.", 3.0)


## 중력 반전: 화면이 뒤집히며 위아래를 바꾼 판으로 (같은 x 자리)
func st_flip_down(c: Cut) -> void:
	await _flip(c, "st_tower_4r", "in")


func st_flip_up(c: Cut) -> void:
	await _flip(c, "st_tower_4", "back")


func _flip(c: Cut, to: String, spawn: String) -> void:
	c.lock()
	var cam := c.player.camera
	c.sfx("reveal", 2.0)
	Fx.ring(c.player.center(), 6.0, 80.0, StArt.STAR, 0.5, 3.0)
	cam.ignore_rotation = false
	var tw := cam.create_tween()
	tw.tween_property(cam, "rotation", PI, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	c.flash(Color(1.0, 0.97, 0.85, 0.5), 0.5)
	await tw.finished
	await c.fade_out(0.12, Color(1.0, 0.97, 0.85))
	cam.rotation = 0.0
	cam.ignore_rotation = true
	await c.goto_room(to, spawn)
	c.flash(Color(1.0, 0.97, 0.85, 0.6), 0.4)
	if to == "st_tower_4r" and not c.has("st_flip_seen"):
		c.flag("st_flip_seen")
		await c.wait(0.3)
		await c.say("sera", "…어? 천장에… 서 있어?", "surprised")
		await c.say("neoul", "아니니라. 탑이 뒤집힌 게다. 아까 닿지 않던 천장이, 지금은 발밑이니라.")
		c.close_box()
	c.release()


# ─── 리라의 기억 조각 (7) ───────────────────────────────

const MEM_TITLES := ["옥상의 별", "꼬마 아스트리드", "흰 별", "선생님의 마지막 밤", "세계수의 밤", "떨어진 별", "소문"]


func _memory_open(c: Cut, n: int) -> void:
	c.lock()
	c.hud(false)
	c.flash(Color(0.85, 0.8, 1.0, 0.6), 0.5)
	c.sfx("star_twinkle", 0.0)
	c.tint(Color(0.2, 0.18, 0.4, 0.45), 0.6)
	await c.wait(0.4)
	await c.title_card("리라의 기억 · %d" % n, String(MEM_TITLES[n - 1]), 1.6)


func _memory_close(c: Cut, n: int) -> void:
	c.close_box()
	c.tint(Color(0, 0, 0, 0), 0.6)
	c.hud(true)
	if not c.has("st_mem_%d" % n):
		c.flag("st_mem_%d" % n)
		var got := 0
		for i in range(1, 8):
			if c.has("st_mem_%d" % i):
				got += 1
		Story.toast("리라의 기억 조각 %d/7" % got, 2.0)
	c.release()


func st_mem_1(c: Cut) -> void:
	await _memory_open(c, 1)
	await c.narrate("— 백이십 년 전. 마녀학교의 옥상.")
	await c.say("lyra", "선생님, 저 별은 왜 저렇게 하얘요? 다른 별은 다 따뜻한데.", "surprised")
	await c.narrate("「그건 별이 아니란다, 리라. 하늘의 틈이지. 저 너머에서 무언가가 이쪽을 들여다보는.」 — 창립자")
	await c.say("lyra", "…저를 보고 있는 것 같아요.", "serious")
	await c.narrate("「쳐다보지 마라. 너처럼 별을 좋아하는 아이는, 특히.」")
	await _memory_close(c, 1)


func st_mem_2(c: Cut) -> void:
	await _memory_open(c, 2)
	await c.narrate("— 백십 년 전. 별 관측 뜰.")
	await c.say("lyra", "꼬마 아스트리드, 별은 쏘는 게 아니라 부르는 거야. 이름을 불러 주면 와.", "happy")
	await c.say("astrid", "선배는 맨날 꼬마래요. 저 이제 열두 살이에요.", "angry")
	await c.say("lyra", "그럼 꼬마 맞네. 자, 따라 해 봐. 하나, 둘—", "happy")
	await c.narrate("작은 별 하나가 어린 아스트리드의 손바닥 위에 내려앉았다. 두 소녀가 함께 웃었다.")
	await _memory_close(c, 2)


func st_mem_3(c: Cut) -> void:
	await _memory_open(c, 3)
	await c.narrate("— 백오 년 전. 깊은 밤, 혼자.")
	await c.narrate("「…그릇. 가장 큰… 그릇. 문. 문이 되어라.」")
	await c.say("lyra", "…또 그 목소리. 나를 부르는 거야?", "serious")
	await c.say("lyra", "싫어. 나는 문 같은 거 안 돼. 나는… 별을 보고 싶을 뿐이야.", "sad")
	await c.narrate("하얀 틈이 하나, 하늘에서 조용히 눈을 떴다.")
	await _memory_close(c, 3)


func st_mem_4(c: Cut) -> void:
	await _memory_open(c, 4)
	await c.narrate("— 백 년 전. 창립자의 마지막 밤.")
	await c.narrate("「리라, 아스트리드. 이 학교의 결계를… 부탁한다.」")
	await c.say("astrid", "네, 선생님. 제가 지킬게요. 선배랑 같이.", "sad")
	await c.say("lyra", "…저는 갈게요.", "sad")
	await c.say("astrid", "선배?", "surprised")
	await c.say("lyra", "별을 보러 갈래. 아주 멀리. …미안해, 꼬마 아스트리드.", "sad")
	await c.narrate("그날 밤 떠난 리라는, 백 년 동안 돌아오지 않았다.")
	await _memory_close(c, 4)


func st_mem_5(c: Cut) -> void:
	await _memory_open(c, 5)
	await c.narrate("— 백 년 전. 세계수의 가지 위.")
	await c.say("lyra", "내가 너무 강해서, 저들이 나를 문으로 쓰려고 해.", "sad")
	await c.say("lyra", "내가 문이 되면 이 숲도, 학교도, 아스트리드도… 전부 끝나.", "sad")
	await c.say("lyra", "그런데 나를 막을 수 있는 사람이 없어. 이 세상 어디에도.", "sad")
	await c.narrate("멀리서 활을 든 엘프 소녀가, 우는 마녀를 말없이 지켜보았다.")
	await _memory_close(c, 5)


func st_mem_6(c: Cut) -> void:
	await _memory_open(c, 6)
	await c.narrate("— 십칠 년 전. 별 하나가 떨어진 밤.")
	await c.say("lyra", "…미안해. 정말 미안해.", "sad")
	await c.narrate("마녀의 품에서 갓난아기가 울음을 그쳤다. 작은 손이 별빛 쪽으로 뻗었다.")
	await c.say("lyra", "웃었어…? 너, 지금 웃은 거야?", "surprised")
	await c.say("lyra", "…그래. 너라면, 나보다 강해질 수 있어. 나의 별.", "happy")
	await _memory_close(c, 6)


func st_mem_7(c: Cut) -> void:
	await _memory_open(c, 7)
	await c.narrate("— 일 년 전. 마녀학교 근처의 작은 찻집.")
	await c.say("lyra", "그거 알아? 신계 깊은 곳에 폭주를 고쳐 주는 보물이 있대.", "happy")
	await c.narrate("「정말요? 그럼 일반반 그 폐급도…」 — 낯선 학생들")
	await c.say("lyra", "소문 하나면 충분해. 별은 늘 소문을 따라 움직이니까.", "serious")
	await c.say("neoul", "(…이 녀석이었구나. 그 소문은.)", "angry")
	await _memory_close(c, 7)


## 엔딩 뒤 교장실의 사진첩: 본 기억을 다시 본다
func st_mem_album(c: Cut) -> void:
	var opts: Array = []
	var ids: Array = []
	for i in range(1, 8):
		if c.has("st_mem_%d" % i):
			opts.append("%d. %s" % [i, MEM_TITLES[i - 1]])
			ids.append(i)
	if ids.is_empty():
		await c.narrate("빈 사진첩이다. 별의 탑에서 기억 조각을 찾으면 여기에 남는다.")
		c.close_box()
		return
	opts.append("닫기")
	var k := await c.choose("narration", "기억의 사진첩 (%d/7)" % ids.size(), opts)
	c.close_box()
	if k < ids.size():
		await Callable(self, "st_mem_%d" % int(ids[k])).call(c)


# ─── 5층: 교장의 별빛 ───────────────────────────────────

func st_t5_astrid(c: Cut) -> void:
	if c.has("st_t5_open"):
		return
	c.lock()
	c.sfx("star_twinkle", 0.0)
	c.spawn_npc("astrid", 70.0, 19.0, -1)
	c.burst(c.marker("astrid_in") + Vector2(64, -20), 30, StArt.STAR, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.6})
	await c.wait(0.4)
	await c.say("astrid", "여기까지 왔군요, 세라피나 양.")
	await c.say("sera", "교장 선생님? 몸은…", "surprised")
	await c.say("astrid", "괜찮다고는 못 하겠네요. 그래도 이 봉인은 제 몫이에요.")
	await c.say("astrid", "선배의 봉인은 선배의 별빛으로만 열리죠. 그런데— 저도 같은 선생님께 배운 별이 있거든요.", "wink")
	c.close_box()
	c.pose("astrid", "cast")
	c.sfx("star_burst", 2.0)
	c.flash(Color(0.85, 0.85, 1.0, 0.6), 0.5)
	Fx.ring(Vector2(72 * 16.0, 16 * 16.0), 4.0, 90.0, StArt.STAR, 0.7, 3.0)
	c.flag("st_t5_open")
	await c.wait(0.8)
	c.pose("astrid", "idle")
	await c.say("astrid", "선배는 강해요. 저보다, 그 누구보다.")
	await c.say("astrid", "하지만 백 년 동안, 그 사람은 늘 혼자서 무언가를 견디고 있었어요. 저는 끝내 그게 뭔지 묻지 못했고요.", "sad")
	await c.say("astrid", "…부탁해요. 이기세요. 그리고 선배의 이야기를 들어 주세요.")
	await c.say("sera", "네. 꼭.")
	c.close_box()
	c.save()
	c.release()


# ═══════════════════════════════════════════════════════════
# 5. 리라 결전 · 6. 진실 · 7. 침공
# ═══════════════════════════════════════════════════════════

func enter_st_tower_top(c: Cut) -> void:
	if c.has("st_lyra_beaten"):
		return
	c.lock()
	Music.stop(1.0)
	var boss := c.spawn_enemy("lyra_boss", 30, 19, "lyra", {"hold_transition": true, "auto_lines": false})
	if boss == null:
		c.release()
		return
	await c.wait(0.5)
	if not c.has("st_lyra_met"):
		c.flag("st_lyra_met")
		c.letterbox(true)
		await c.camera_to(boss.global_position + Vector2(-60, -30), 1.0)
		await c.say("lyra", "어서 와, 나의 별. 열쇠 넷… 정말로 다 모아 왔구나.", "happy")
		await c.say("sera", "당신은 대체 뭐야. 왜 나를 '나의 별'이라고 불러.", "angry")
		await c.say("lyra", "이기면 다 알려 줄게. 약속했잖아.")
		await c.say("lyra", "봐 둬. 꼬마 아스트리드의 별, 제국의 검, 세계수의 눈, 빛의 창.", "serious")
		await c.say("lyra", "네가 만나 온 강함을— 전부 한꺼번에 상대하는 거야.", "serious")
		await c.say("neoul", "세라. 저것은 지금까지 만난 누구보다도 강하다. 그래도—")
		await c.say("sera", "알아. 그래도 가.")
		await c.say("lyra", "나를 넘어 보렴, 나의 별.", "happy")
		c.close_box()
		await c.camera_back(0.6)
		c.letterbox(false)
	else:
		await c.say("lyra", "다시 왔구나. 몇 번이든 좋아. 별은 기다리는 게 일이니까.", "happy")
		c.close_box()
	c.music("lyra")
	boss.phase_changed.connect(_lyra_phase.bind(boss, c))
	boss.engaged = true
	c.release()
	await c.wait_enemy(boss)
	if not c.ok():
		return
	await _lyra_truth(c, boss)


## 리라 페이즈 전환: 전환 연출을 붙잡고 짧은 대사 → resume()
func _lyra_phase(n: int, boss: Node, c: Cut) -> void:
	if not c.ok() or not is_instance_valid(boss):
		return
	c.lock()
	c.freeze_enemies(false)
	match n:
		2:
			await c.say("lyra", "꼬마 아스트리드의 별은 이 정도. 이번엔… 검이야.", "serious")
			await c.say("sera", "그 자세— 레오니?", "surprised")
			await c.say("lyra", "마력 하나 없이 제국제일검이 된 아이. 정말 멋지지?", "happy")
		3:
			await c.say("lyra", "맞히는 건 쉽대. 안 맞히는 게 어렵고.", "serious")
			await c.say("neoul", "붉은 선이 굳으면 비켜라! 두 발이 온다!")
		4:
			await c.say("lyra", "빛을 지키는 창. …저 아이는 끝까지 혼자 지키려 했지. 나처럼.", "sad")
		5:
			await c.say("lyra", "이게 나의 전부야. 받아 보렴!", "serious")
			await c.say("neoul", "별 사이의 빈칸을 찾거라, 세라! 큰 별은 피하고!")
	c.close_box()
	c.release()
	if is_instance_valid(boss):
		boss.resume()


func _lyra_truth(c: Cut, boss: Node) -> void:
	c.lock()
	c.flag("st_lyra_beaten")
	Music.stop(2.0)
	c.letterbox(true)
	await c.wait(1.6)
	await c.say("lyra", "…하아. 정말로… 넘었구나.", "weak")
	await c.say("sera", "약속했지. 다 말해.", "angry")
	await c.say("lyra", "…열일곱 해 전. 별 하나가 떨어진 밤, 나는 갓난아기에게 그 별의 조각을 심었어. 별의 씨앗.", "sad")
	await c.say("sera", "…갓난아기?")
	await c.say("lyra", "너야, 세라피나.", "sad")
	c.music("despair", 2.0)
	await c.say("sera", "그럼 내 폭주는… 폐급이라고 손가락질받은 건 전부—", "surprised")
	await c.say("lyra", "응. 내가 한 일이야.", "sad")
	await c.say("lyra", "그리고 작년. '신계 깊은 곳에 폭주를 고쳐 줄 보물이 있다'— 그 소문도 내가 퍼뜨렸어.")
	c.vignette(0.5)
	c.shake(0.12, 0.8)
	await c.say("neoul", "…그렇다면 내 구슬도. 내 구슬을 미끼로 썼다고?!", "angry")
	c.vignette(0.0)
	await c.say("lyra", "미안해요, 여우신님. 당신의 구슬이 아니었다면, 이 아이의 몸은 별의 씨앗을 견디지 못했을 거예요.", "sad")
	await c.say("sera", "왜…! 왜 그런 짓을 한 건데!", "angry")
	c.close_box()
	await c.wait(0.6)
	await c.say("lyra", "하늘 저편에 바깥 신들이 있어. 이 세계의 틈으로 들어오려는 것들.", "serious")
	await c.say("lyra", "그들에게는 문이 필요해. 아주 강한 그릇으로 만든 문.", "serious")
	await c.say("lyra", "이 세계에서 가장 강한 그릇은… 나야. 백 년 전부터 그들은 나를 부르고 있어. 나는 언젠가 문이 될 거야.", "serious")
	await c.say("lyra", "그래서 나를 막아 줄 사람이 필요했어. 나보다 강한 사람이.", "sad")
	await c.say("lyra", "…그런 사람이 없으면, 만들 수밖에 없었어.", "sad")
	await c.say("sera", "……")
	c.close_box()
	c.spawn_npc("astrid", 2.0, 19.0, 1)
	await c.walk("astrid", 8.0, 50.0)
	await c.say("astrid", "…알고 있었어요. 확신은 없었지만.", "sad")
	await c.say("astrid", "선배가 떠나던 밤, 하늘에 흰 틈이 하나 있었으니까요.", "sad")
	await c.say("lyra", "꼬마 아스트리드. …미안해. 결계를 혼자 들게 해서.", "sad")
	await c.say("astrid", "백 년이나 기다리게 해 놓고, 사과는 한 줄이군요.", "tired")
	c.close_box()
	await c.say("lyra", "세라피나. 미워해도 돼.", "sad")
	await c.say("lyra", "그래도 이것만은 진짜야. 너를 처음 안았을 때, 너는 웃었어. 그날부터 너는 나의 별이었어.", "sad")
	await c.say("sera", "……그런 말, 지금 하지 마.", "sad")
	c.close_box()
	c.flag("st_truth")
	await c.wait(1.0)
	# 침공
	Music.stop(0.3)
	c.sfx("sky_crack", 6.0)
	c.flash(Color(1, 1, 1, 0.9), 0.5)
	c.shake(0.5, 1.6)
	await c.wait(0.6)
	await c.say("lyra", "…아. 벌써 왔구나. 내가 약해진 틈을—", "surprised")
	c.close_box()
	var lp: Vector2 = (boss as Node2D).global_position if is_instance_valid(boss) else Vector2(30 * 16.0, 19 * 16.0)
	for k in 3:
		StStrike.spawn(lp + Vector2((k - 1) * 30.0, -20), "pillar", Vector2(18, 400), 0.4, {"damage": 0, "style": "white", "hold": 1.4, "fade": 0.6})
	c.sfx("holy_charge", 2.0)
	await c.wait(0.6)
	if is_instance_valid(boss):
		var v: Variant = boss.get("visual")
		if v is CharacterVisual:
			(v as CharacterVisual).set_pose("possessed")
		var tw := (boss as Node2D).create_tween()
		tw.tween_property(boss, "global_position", lp + Vector2(0, -260), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await c.say("lyra", "세라— 도망쳐!", "possessed")
	c.close_box()
	await c.say("sera", "리라!!", "surprised")
	c.close_box()
	await c.wait(1.6)
	if is_instance_valid(boss):
		(boss as Node2D).visible = false
	c.flag("st_invaded")
	c.music("despair", 1.0)
	c.shake(0.7, 2.0)
	c.sfx("crumble", 4.0)
	await c.say("astrid", "탑이 무너져요! 세라피나 양, 제 손을—!", "surprised")
	c.close_box()
	await c.fade_out(1.2, Color(1, 1, 1))
	await c.title_card("그날, 하늘이 갈라졌다", "바깥 신들의 침공", 2.8)
	c.letterbox(false)
	await c.fade_out(0.6)
	await c.goto_room("r5_clock", "land")
