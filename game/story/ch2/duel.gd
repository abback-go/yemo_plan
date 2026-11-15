extends "res://story/ch2/common.gd"
## 2장 대본 — 8~9. 밤의 결투 · 옛 성곽·운석수(레오니와 함께) · 공관 작별·기숙사의 밤.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 8. 밤의 황궁 광장 — 진검 결투 → 사람을 감싸는 불
# ═══════════════════════════════════════════════════════════

func k_duel(c: Cut) -> void:
	if c.has("k_duel_done") or not c.has("k_duel_called"):
		return
	c.lock()
	# 결투는 이겼는데 뒷장면(별비·아이·합류) 도중 꺼졌던 기록: 결투 없이 뒷장면부터
	if c.has("k_duel_won"):
		await c.player_walk(52.0)
		c.player_face(-1)
		var ln0 := c.actor("leonie") as Npc
		if ln0:
			ln0.global_position.x = 49.0 * 16.0
			ln0.face(1)
			ln0.visual.set_pose("kneel")
		await _duel_end(c, null)
		return
	c.music("", 1.0)
	await c.player_walk(52.0)
	c.player_face(-1)
	await c.wait(0.4)
	await c.say("leonie", "왔군.")
	await c.say("sera", "도망칠 생각 없어요.")
	await c.say("leonie", "짐승들이 너 때문에 몰려든다면 — 너를 지키는 방법은, 너를 이 도시에서 내보내는 것뿐이다.", "stern")
	await c.say("sera", "그럼 그 짐승들은요? 내가 가면, 다음엔 누굴 노리는데요?", "angry")
	await c.say("leonie", "그건 기사단의 일이다.")
	await c.say("leonie", "…검을 거두게 하고 싶다면 증명해라. 네 불이, 이 도시에 무엇인지.", "angry")
	c.close_box()
	c.sfx("sword_clash", 2.0)
	c.pose("leonie", "guard")
	await c.wait(0.5)
	var n := c.actor("leonie") as Node2D
	var lx := (n.global_position.x / 16.0) if n else 30.0
	c.hide_actor("leonie")
	var d := c.spawn_enemy("leonie_duel", lx - 0.5, 19.0, "duel", {"engaged": false, "respawns": true})
	if d == null:
		c.flag("k_duel_done")
		return
	d.facing = 1
	await c.title_card("결투", "은사자 기사단장 · 레오니 발렌하르트", 1.6)
	c.music("knight_duel", 0.3)
	d.engaged = true
	c.release()
	await c.wait_enemy(d)
	if not c.ok():
		return
	# 이긴 즉시 기록 — 뒷장면 도중 꺼져도 결투를 다시 하지 않게
	c.flag("k_duel_won")
	GameState.save_game()
	await _duel_end(c, d)


func _duel_end(c: Cut, d: EnemyBase) -> void:
	c.lock()
	await c.wait(1.6)
	c.music("", 0.8)
	# 무릎 꿇은 적 → 대화용 인물로 바꿔 세움
	var ln := c.actor("leonie") as Npc
	if ln and is_instance_valid(d):
		ln.global_position = d.global_position
		ln.visible = true
		ln.process_mode = Node.PROCESS_MODE_INHERIT
		ln.face(1)
		ln.visual.set_pose("kneel")
		d.queue_free()
	await c.say("leonie", "…하아.", "sad")
	await c.say("sera", "…레오니 단장님.")
	c.close_box()
	# 별이 쏟아진다
	c.sfx("sky_crack", 4.0)
	c.shake(0.4, 1.2)
	c.flash(Color(0.8, 0.6, 1.0, 0.5), 0.6)
	await c.wait(0.8)
	await c.say("leonie", "…저 빛은. 옛 성곽 쪽이다.", "surprised")
	c.close_box()
	for i in 6:
		var mx := 10.0 + float(i) * 11.0 + randf_range(-3.0, 3.0)
		var m := KE.meteor(Vector2(mx * 16.0, 19.0 * 16.0), 0.7 + float(i) * 0.12)
		m.harmless = true
	await c.wait(0.4)
	c.spawn_npc("k_child", 8.0, 19.0, 1)
	await c.say("k_child", "다, 단장님…! 결투 보러 몰래 나왔는데… 무, 무서워…!", "sad")
	c.close_box()
	# 큰 별 하나가 아이 쪽으로 (붉은 원 2.2초 뒤 떨어짐) — 세라가 달려가 떨어지는 순간 방벽
	var big := KE.meteor(Vector2(9.0 * 16.0, 19.0 * 16.0), 2.2, 40.0, KE.STAR, true)
	big.harmless = true
	c.emote("sera", "!")
	await c.player_walk(10.0, 420.0)
	c.player_face(-1)
	var big_ref: WeakRef = weakref(big)
	await c.wait_until(func() -> bool:
		var m := big_ref.get_ref() as Node
		return m == null or float(m.get("_t")) >= 2.05, 3.0)
	c.player.call("_cast_ward")
	await c.wait(0.9)
	c.flash(Color(1.0, 0.7, 0.4, 0.7), 0.5)
	Fx.ring(c.player.global_position + Vector2(0, -16), 10.0, 70.0, Color(1.0, 0.6, 0.3), 0.6, 4.0)
	c.burst(c.player.global_position + Vector2(0, -16), 40, Color(1.0, 0.6, 0.3),
		{spread = 180.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.8})
	await c.wait(1.2)
	await c.say("k_child", "…어? 안 아파. 따뜻해…", "surprised")
	await c.say("k_child", "마녀 언니가… 불로 감싸 줬어!", "happy")
	c.close_box()
	c.pose("leonie", "idle")
	await c.wait(0.6)
	await c.say("leonie", "…그 불이. 사람을 감쌌다.", "surprised")
	c.sfx("sword_clash", -2.0)
	await c.say("leonie", "…내가 틀렸다, 세라피나.")
	await c.say("leonie", "너를 내보낸다고 이 도시가 지켜지는 게 아니었군. 네 불은 — 여기 있어야 한다.", "happy")
	c.close_box()
	# 카엘
	c.sfx("dash")
	c.spawn_npc("kael", 79.0, 19.0, -1)
	await c.walk("kael", 30.0, 160.0)
	await c.say("kael", "단장님! 옛 성곽 지구에서… 운석이, 그 운석이 움직입니다! 별 신도들이 둘러싸고…!", "surprised")
	await c.say("leonie", "녹시스…!", "angry")
	await c.say("leonie", "카엘, 아이를 집에 데려다줘라. 기사단은 성곽 지구 둘레를 막는다.")
	await c.say("kael", "예, 옛! …단장님은요?", "surprised")
	await c.say("leonie", "세라피나. 같이 가자.")
	await c.say("leonie", "이번엔 — 등을 맡기겠다.", "happy")
	await c.say("sera", "…네!", "happy")
	c.close_box()
	c.hide_actor("k_child")
	c.hide_actor("kael")
	var lp := (ln.global_position / 16.0) if ln else Vector2(30, 19)
	c.hide_actor("leonie")
	var a := c.ally_join("leonie", lp.x, lp.y)
	if a:
		a.say("서쪽이다. 뒤처지지 마라.")
	c.flag("k_duel_done")
	c.music("starbeast", 1.0)
	await c.item("동료 — 레오니", "레오니가 함께 싸운다. 가까운 적에게 잔상 돌진으로 파고들고, 큰 적이 틈을 보이면 다리를 베어 쓰러뜨린다.")
	c.save()


# ═══════════════════════════════════════════════════════════
# 9. 옛 성곽 지구 · 별이 떨어진 자리 — 레오니와 함께 운석수
# ═══════════════════════════════════════════════════════════

func enter_k_oldquarter_1(c: Cut) -> void:
	var a := _ensure_leonie(c)
	if a and not c.has("k_oq_intro"):
		c.flag("k_oq_intro")
		a.say("신도들이다. 앞은 내가 맡지.")
		c.bubble("별 냄새가 진동하는구나…", 2.4)


func enter_k_oldquarter_2(c: Cut) -> void:
	var a := _ensure_leonie(c)
	if a and not c.has("k_oq2_intro"):
		c.flag("k_oq2_intro")
		a.say("성벽 틈으로 별빛이 솟는다. 날개라는 걸로 타고 올라가라. 난 벽을 탄다.")


func enter_k_oldquarter_3(c: Cut) -> void:
	var a := _ensure_leonie(c)
	if a and not c.has("k_oq3_intro"):
		c.flag("k_oq3_intro")
		a.say("…여기다. 10년 전 그 밤, 별이 떨어진 거리.")


func enter_k_crater(c: Cut) -> void:
	_ensure_leonie(c)


func k_crater(c: Cut) -> void:
	if c.has("k_beast_down") or not c.has("k_duel_done"):
		return
	c.lock()
	var a := _ensure_leonie(c)
	if a:
		a.mode = "script"
	c.music("", 1.0)
	await c.player_walk(44.0)
	c.player_face(-1)
	if a:
		await a.move_to(48.0)
	c.spawn_npc("noxis", 12.0, 34.0, 1)
	c.sfx("reveal", 2.0)
	await c.wait(0.4)
	await c.say("noxis", "늦으셨군요, 단장님. 그리고 — 별의 그릇이여.", "happy")
	await c.say("leonie", "녹시스. 이 도시에서 십 년 동안 모은 별 조각, 오늘 전부 돌려받겠다.", "angry")
	await c.say("noxis", "돌려받는다니요. 이것은 처음부터 그분의 것.", "zeal")
	await c.say("noxis", "보십시오! 10년 전 떨어진 별이 — 그릇의 마력을 맛보고, 이제 눈을 뜹니다!", "zeal")
	c.close_box()
	c.hide_actor("noxis")
	var b := c.spawn_enemy("meteor_beast", 22.0, 42.0, "beast", {"engaged": false, "respawns": true})
	if b == null:
		c.flag("k_beast_down")
		return
	b.facing = 1
	c.freeze_enemies(true)
	c.sfx("sky_crack", 4.0)
	c.shake(0.6, 1.6)
	c.flash(Color(0.8, 0.6, 1.0, 0.7), 0.8)
	await c.camera_to(b.global_position + Vector2(0, -60), 1.0)
	await c.wait(0.6)
	await c.say("sera", "운석이… 일어서…!", "surprised")
	await c.camera_back(0.8)
	await c.say("leonie", "세라피나. 등의 수정은 네 방벽으로 깨라. 놈이 뱉는 조각을 되돌려 줘.")
	await c.say("leonie", "다리는 내가 벤다. 쓰러지면 — 가슴의 핵을 노려라.")
	await c.say("neoul", "세라, 우리 둘이 아니니라. 셋이다. 가자!")
	c.close_box()
	c.music("starbeast", 0.3)
	b.engaged = true
	if a:
		a.mode = "follow"
	c.release()
	await _beast_fight(c, b, a)
	if not c.ok():
		return
	await _beast_end(c)


func _beast_fight(c: Cut, b: EnemyBase, a: Ally) -> void:
	var brooch := false
	var t := 0.0
	var next_cut := 16.0
	while c.ok() and is_instance_valid(b) and b.is_alive():
		await c.world.get_tree().physics_frame
		t += c.world.get_physics_process_delta_time()
		var staggered := bool(b.call("is_staggered"))
		if not brooch and b.hp <= int(b.max_hp * 0.35) and not staggered:
			brooch = true
			await _brooch_scene(c, b, a)
			t = 0.0
			continue
		if t >= next_cut and not staggered and a and is_instance_valid(a):
			t = 0.0
			next_cut = 15.0
			a.special(b)


## 위기: 운석수의 큰 일격 — 교장의 별 브로치가 막고 깨진다
func _brooch_scene(c: Cut, b: EnemyBase, a: Ally) -> void:
	b.set("ultimate_harmless", true)
	var got := [false]
	b.connect("ultimate_hit", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	b.call("ultimate")
	if a and is_instance_valid(a):
		a.say("하늘이…! 세라피나, 피해!")
	c.bubble("저 큰 별은 피할 데가 없구나…!", 2.2)
	var b_ref: WeakRef = weakref(b)
	await c.wait_until(func() -> bool: return bool(got[0]) or _dead(b_ref), 8.0)
	if not c.ok():
		return
	c.lock()
	c.sfx("star_burst", 4.0)
	c.flash(Color(0.85, 0.9, 1.0, 0.9), 0.8)
	Fx.ring(c.player.global_position + Vector2(0, -16), 8.0, 110.0, Color(0.8, 0.85, 1.0), 0.9, 5.0)
	KE.star_burst(c.player.global_position + Vector2(0, -16), 60, Color(0.85, 0.9, 1.0), 220.0, 1.0)
	await c.wait(1.0)
	await c.say("sera", "…어? 나, 안 다쳤어…?", "surprised")
	c.flag("k_brooch_broken")
	c.sfx("crumble", 0.0)
	await c.item("교장의 별 브로치", "브로치가 별빛을 터뜨리고 산산조각 났다.")
	await c.say("astrid", "(어디선가, 아주 멀리서) …한 번쯤은 지켜 준다고 했지요. 이다음은, 당신 차례예요.")
	await c.say("sera", "…교장 선생님.", "sad")
	await c.say("neoul", "교장의 별이 너를 감쌌구나. …저 마녀, 역시 무언가를 알고 있었느니라.", "sad")
	await c.say("leonie", "지금이다 — 놈이 숨을 고른다! 다리를 벤다!", "angry")
	c.close_box()
	c.release()
	if a and is_instance_valid(a) and is_instance_valid(b) and b.is_alive():
		a.special(b)
		await c.wait(0.3)
		if is_instance_valid(b) and b.is_alive():
			b.call("stagger", 4.0)


func _beast_end(c: Cut) -> void:
	c.lock()
	await c.wait(2.8)
	c.music("", 1.5)
	var a := c.ally("leonie")
	if a:
		a.mode = "script"
	c.spawn_npc("noxis", 12.0, 34.0, 1)
	c.sfx("reveal")
	await c.say("noxis", "아아… 별이, 다시 잠드는군요.", "sad")
	await c.say("noxis", "후후… 후후후. 상관없습니다. 오늘 밤, 그분께서 충분히 보셨으니.", "happy")
	await c.say("noxis", "별의 마녀께서 지켜보신다. 그릇이여 — 또 뵙지요.", "zeal")
	c.close_box()
	var nn := c.actor("noxis") as Node2D
	if nn:
		KE.star_burst(nn.global_position + Vector2(0, -20), 50, Color("#c89aff"), 200.0, 1.0)
		Fx.ring(nn.global_position + Vector2(0, -20), 6.0, 60.0, Color("#c89aff"), 0.5, 2.0)
	c.sfx("warp")
	c.hide_actor("noxis")
	await c.wait(0.8)
	await c.say("sera", "별의… 마녀?", "surprised")
	await c.say("neoul", "…그 이름. 어디선가 들은 듯하구나. 먼 옛날, 아주 먼 곳에서.", "sad")
	c.close_box()
	c.music("ending", 2.0)
	if a:
		var px := c.player_tile().x
		await a.move_to(px + 2.5)
		a.facing = -1
	await c.wait(0.6)
	await c.say("leonie", "세라.")
	c.emote("sera", "!")
	await c.say("sera", "…방금, 세라라고…", "surprised")
	await c.say("leonie", "네 불은 사람을 지키는 불이다.", "happy")
	await c.say("leonie", "…'나쁘지 않군'은 아껴 두지. 이번엔 그보다 훨씬 나았으니까.", "happy")
	await c.say("sera", "…헤헤.", "happy")
	c.close_box()
	c.flag("k_beast_down")
	await c.fade_out(2.0)
	c.ally_leave("leonie")
	await _farewell(c)


## 다음 날, 공관 — 작별 → 학교 기숙사의 밤 → 3장
func _farewell(c: Cut) -> void:
	await c.narrate("다음 날 아침 — 제국 주재 공관.")
	c.close_box()
	await c.goto_room("k_embassy", "warp")
	c.music("kingdom", 1.0)
	c.spawn_npc("leonie", 30.0, 19.0, -1)
	c.spawn_npc("kael", 34.0, 19.0, -1)
	c.spawn_npc("mia", 26.0, 19.0, -1)
	c.hide_actor("isolde")
	c.spawn_npc("isolde", 14.0, 19.0, 1)
	await c.fade_in(1.4)
	await c.say("leonie", "황제 폐하께서 감사를 전하셨다. 마녀학교에 큰 빚을 졌다고.")
	await c.say("kael", "그리고요! 단장님이 직접 배웅 나오신 건 폐하 심부름이라서가 아니라—", "happy")
	await c.say("leonie", "카엘.")
	await c.say("kael", "…조용히 하겠습니다.", "sad")
	await c.say("mia", "세라 언니! 단장님이랑 같이 운석 괴물을 쓰러뜨렸다면서요! 또 와요! 꼭요! 빵 구워 놓을게요!", "happy")
	if c.has("k_race_won"):
		await c.say("isolde", "…세라. 다음엔 지붕 경주, 내가 이겨.")
	else:
		await c.say("isolde", "…세라.")
		c.emote("sera", "!")
		await c.say("sera", "어? 이졸데, 지금 내 이름—", "surprised")
		await c.say("isolde", "…가자. 늦으면 엠버린 교수님한테 혼나.", "smug")
	await c.say("emberlyn", "모두 잘했다. 돌아가자. …버터워스 아주머니가 잔치 준비를 하신다더군.", "happy")
	await c.say("pippa", "잔치!!", "happy")
	await c.say("leonie", "세라. 언젠가 네 학교에 갈 일이 생기면 — 그땐 내가 손님이다.")
	await c.say("sera", "네! 그때는 제가 안내할게요!", "happy")
	c.close_box()
	c.sfx("warp", 2.0)
	c.flash(Color(0.75, 0.6, 1.0, 0.8), 0.6)
	await c.fade_out(1.2, Color(0.85, 0.8, 1.0))
	await c.narrate("그날 밤 — 마녀학교 기숙사.")
	c.close_box()
	await c.goto_room("s_dorm", "bed")
	c.hud(false)
	c.music("ending", 1.0)
	c.player_face(1)
	c.tint(Color(0.04, 0.05, 0.18, 0.38), 0.01)
	await c.fade_in(2.0)
	await c.wait(0.6)
	await c.say("sera", "…너울. 자?")
	await c.say("neoul", "…자는 중이니라.")
	await c.say("sera", "레오니 단장님이 나를 '세라'라고 불렀어.", "happy")
	await c.say("neoul", "흥. 나는 처음부터 그렇게 불렀느니라.")
	await c.say("sera", "…그리고, 내 불은 사람을 지키는 불이래.")
	await c.say("neoul", "……")
	await c.say("neoul", "그 계집, 마력은 한 톨도 없지만 보는 눈은 있구나.")
	await c.say("sera", "교장 선생님 브로치… 깨져 버렸어. 내일 사과드려야겠다.", "sad")
	await c.say("neoul", "사과가 아니라 고맙다고 하거라. 별은 제 할 일을 한 것이니.")
	await c.say("neoul", "…그리고 세라. 아까부터 엉덩이께가 근질거리느니라. 무언가… 돋아날 것 같구나.", "surprised")
	c.close_box()
	c.save_here("bed")
	c.tint(Color(0, 0, 0, 0), 1.0)
	await ChapterFlow.finish(c, 2)
