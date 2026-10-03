extends RefCounted
## 대본: 프롤로그 신계 (docs/chapter1.md 2절 P0~P7, 12.1절).
## 메서드 이름 = 실행 ID. enter_<방ID>는 방에 들어올 때 자동 실행. teach_로 시작하면 세라를 멈춰 세우지 않는다.


# ─── P0 오프닝 + P1 여우고개 ────────────────────────────

func enter_t_pass(c: Cut) -> void:
	if c.has("p_intro_done"):
		return
	c.flag("p_intro_done")
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	await c.narrate("폐급 마녀.\n마녀학교에서 나를 부르는 이름이다. 마력이 너무 커서, 마법이 늘 제멋대로 터져 버린다.")
	await c.narrate("그런데 소문을 들었다.\n신계(神界) 깊은 곳에 — 폭주를 고쳐 줄 보물이 잠들어 있다고.")
	c.close_box()
	await c.fade_in(1.2)
	await c.wait(0.4)
	await c.say("sera", "…여기가 신계. 생각보다 조용하네.")
	await c.say("sera", "보물만 슬쩍 빌리고 바로 돌아가는 거야. 아무도 모르게.", "happy")
	c.close_box()
	c.hud(true)
	await c.teach("이동", "← → 로 걷는다.\n세라는 빠르다 — 바람처럼 달려 보자.", ["move"])


func teach_jump(c: Cut) -> void:
	await c.teach("점프", "Z 로 뛰어오른다.\n낮은 턱쯤은 가볍게.", ["jump"])


func teach_high_jump(c: Cut) -> void:
	await c.teach("높이 뛰기", "Z 를 길게 누를수록 높이 뛴다.\n꼭대기에서 누르고 있으면 잠깐 떠 있는다.", ["jump"])


func teach_dash(c: Cut) -> void:
	await c.teach("대시", "C 로 짧게 돌진한다. 공중에서도 한 번.\n점프한 뒤 대시하면 멀리 간다.", ["dash", "jump"], ["jump", "dash"])


func p_pass_gate(c: Cut) -> void:
	await c.say("sera", "홍살문… 여기서부턴 진짜 신의 땅이야.")
	await c.say("sera", "괜찮아, 세라. 들키지만 않으면 돼.", "sad")


# ─── P2 도깨비불 숲길 ───────────────────────────────────

func p_wisp_seen(c: Cut) -> void:
	var wisp := c.enemy("wisp")
	if wisp:
		await c.camera_to(wisp.global_position + Vector2(-60, 0), 0.6)
	await c.say("sera", "도깨비불…! 신단의 문지기들이야.", "surprised")
	await c.say("sera", "어차피 들킬 거면 — 먼저 쏴 버리는 수밖에.", "angry")
	c.close_box()
	await c.camera_back(0.4)
	await c.teach("화염탄", "X 로 화염탄을 쏜다. 연달아 누르면 3연타.\n세 번째 불덩이가 가장 세다.", ["attack"])


func p_fox_seen(c: Cut) -> void:
	var fox := c.enemy("stone_fox")
	if fox == null:
		c.flag("p_dodge_ready")
		return
	await c.camera_to(fox.global_position + Vector2(-40, -10), 0.7)
	c.sfx("growl")
	await c.wait(0.3)
	await c.say("sera", "석상이… 움직였어?! 눈이 빨개지는데.", "surprised")
	await c.say("sera", "저건 맞으면 아프겠다. 부딪히기 직전에 피해야 해.")
	c.close_box()
	await c.camera_back(0.5)
	c.flag("p_dodge_ready")


## 공격이 몸에 닿기 직전에 나오는 안내 (World._tutorial_hooks)
func teach_dodge(c: Cut) -> void:
	await c.teach("퍼펙트 회피", "공격이 닿기 직전 C (대시)로 스쳐 지나가면 —\n잠깐 세상이 느려진다. 위치 타임!", ["dash"])


## 폭주 게이지가 처음 45를 넘었을 때 (World._tutorial_hooks)
func teach_overload(c: Cut) -> void:
	c.sfx("overload_pulse")
	await c.teach("폭주 게이지", "마법을 쓸수록 화면 위의 폭주 게이지가 찬다. 70부터는 과열 — 화염탄이 세진다.\n가득 차면 마력이 폭발해 세라도 다친다. 잠깐 쉬면 식는다.", ["attack", "move"], ["attack", "move", "jump", "dash"])


# ─── P3 신단 계단 ───────────────────────────────────────

func p_watcher_seen(c: Cut) -> void:
	var w := c.enemy("lantern_watcher")
	if w == null:
		return
	await c.camera_to(w.global_position + Vector2(-50, 20), 0.6)
	await c.say("sera", "등롱 속에 눈이…! 저 위에서 노리고 있어.", "surprised")
	c.close_box()
	await c.camera_back(0.4)
	await c.teach("불기둥", "A 로 불기둥. 가장 가까운 적의 발밑에서 불길이 솟는다.\n엄폐물 너머, 높은 곳에도 닿는다.", ["skill_1"])


func teach_drop(c: Cut) -> void:
	await c.teach("발판 내려가기", "통과 발판 위에서 ↓ + Z — 아래로 내려간다.\n공중에서 ↓ 는 빠른 낙하.", ["move_down", "jump"], ["jump"])


# ─── P4 봉화 시련 ───────────────────────────────────────

func p_trial_enter(c: Cut) -> void:
	await c.say("sera", "봉화 셋… 저기 문. 불을 붙이면 열리는 건가?")
	await c.say("sera", "불이라면 자신 있지. 제멋대로라서 문제지만.", "smug")


func p_trial_burst(c: Cut) -> void:
	await c.wait(0.5)
	await c.say("sera", "됐다! 이제 문이—")
	c.close_box()
	c.sfx("ignite")
	c.shake(0.15, 0.6)
	# 제단이 봉화의 불을 세라에게 되돌린다
	for b in c.world.get_tree().get_nodes_in_group(&"brazier"):
		Fx.burst(b.global_position + Vector2(0, -22), 30, {direction = (c.player.center() - b.global_position).normalized(),
			spread = 8.0, speed_min = 160.0, speed_max = 320.0, lifetime = 0.6, add = true,
			gradient = Palette.fade_gradient(Palette.FIRE_OUT), size_min = 2.0, size_max = 4.0})
	await c.wait(0.6)
	c.emote("sera", "!")
	await c.say("sera", "어, 어?! 불이 나한테로…!", "surprised")
	c.close_box()
	c.player.hp = maxi(c.player.hp, 3)
	c.player.force_overload_full()
	await c.wait(0.5)
	await c.say("sera", "안 돼, 멈춰… 멈추라고…!", "sad")
	c.close_box()
	await c.wait_until(func() -> bool: return c.player.overload <= 0.0, 4.0)
	await c.wait(1.2)
	c.flag("t_trial_done")
	await c.fade_out(1.0)
	await c.narrate("……")
	c.close_box()
	await c.goto_room("t_throne", "chained")


# ─── P5 왕좌의 전당 ─────────────────────────────────────

func enter_t_throne(c: Cut) -> void:
	if c.has("p_bead_done") or not c.has("t_trial_done"):
		return
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	var god := c.actor("neoul_god")
	var bead := c.actor("bead")
	var chains := c.actor("chains")
	c.player_face(1)
	await c.wait(0.6)
	await c.fade_in(1.5)
	await c.say("sera", "으… 머리야… 여긴…?", "sad")
	c.sfx("chain")
	c.shake(0.08, 0.3)
	if chains:
		chains.pulse(1.0)
	await c.say("sera", "사슬…? 뭐야, 이거 풀어! 풀라고!", "angry")
	c.close_box()
	c.music("shingye_tension")
	c.sfx("roar", -6.0)
	c.flash(Color(0.0, 0.02, 0.06, 0.7), 0.6)
	c.vignette(0.7)
	c.shake(0.25, 1.2)
	if god:
		god.set_power(0.7, 0.8)
		await god.appear(1.2)
	await c.say("neoul_god", "감히.", "scary")
	await c.say("neoul_god", "필멸의 아이가 내 신단에 숨어들어, 시련의 봉화를 어지럽히다니.", "scary")
	await c.say("sera", "여, 여신님…? 그게, 저는…", "surprised")
	var i := await c.choose("sera", "(뭐라고 하지…?)", ["보물을 훔치러 왔어요.", "길을 잃었어요…"])
	if i == 0:
		await c.say("neoul_god", "…정직하구나. 정직한 도둑이라.")
	else:
		await c.say("neoul_god", "거짓의 냄새… 아니, 겁의 냄새로구나.")
	await c.say("neoul_god", "무엇을 찾아 왔느냐.")
	await c.say("sera", "폭주를… 고칠 수 있는 거요. 제 마력은 늘 제멋대로 터져서, 다들 저를 폐급이라고 불러요.", "sad")
	if god:
		god.set_power(0.15, 1.0)
	c.vignette(0.3)
	await c.say("neoul_god", "폐급이라.")
	await c.say("neoul_god", "그런 그릇에 신의 보물이 담길 리 없느니라. 돌아가거라 — 이곳의 기억을 지운 채로.", "scary")
	c.close_box()
	if god:
		god.set_power(1.0, 0.6)
	c.sfx("overload_warn")
	# 겁에 질린 마력이 다시 끓어오른다
	var t := 0.0
	while t < 1.4:
		t += 0.05
		c.player.overload = minf(c.player.overload + 4.5, 92.0)
		await c.wait(0.05)
	c.vignette(0.8)
	await c.say("sera", "싫어… 싫어, 또 시작이야…!", "sad")
	c.close_box()
	if bead:
		bead.set_power(1.0, 0.5)
		bead.pulse(1.0)
		c.sfx("reveal")
		await bead.move_to(bead.global_position + Vector2(0, -20), 0.8)
	await c.say("neoul_god", "…구슬이, 네 마력에 반응한다고? 그럴 리가—", "surprised")
	c.close_box()
	await c.teach("손을 뻗는다", "↑ 로 떠오른 구슬을 향해 손을 뻗는다.", ["move_up"])
	if bead:
		c.sfx("whoosh")
		await bead.move_to(c.player.center(), 0.35)
		bead.visible = false
	c.flash(Color(0.7, 0.9, 1.0, 1.0), 0.8)
	c.sfx("fox_transform", 2.0)
	c.shake(0.6, 1.0)
	Fx.ring(c.player.center(), 8.0, 220.0, Color(0.55, 0.85, 1.0), 0.8, 4.0)
	if chains:
		chains.break_chains()
	c.player.overload = 0.0
	c.vignette(0.0)
	await c.wait(0.4)
	if god:
		await c.say("neoul_god", "안 돼, 내 구슬—!", "angry")
		c.close_box()
		god.pulse(1.0)
		Fx.burst(god.global_position + Vector2(0, -60), 80, {spread = 180.0, speed_min = 60.0, speed_max = 260.0, lifetime = 1.0,
			gradient = Palette.fade_gradient(Color(0.6, 0.85, 1.0)), add = true, size_min = 2.0, size_max = 4.0})
		c.flash(Color(0.6, 0.85, 1.0, 0.9), 0.6)
		c.sfx("fox_end")
		await god.vanish(0.5)
		c.world.pet.place(god.global_position + Vector2(0, -40), -1)
		var drop := c.world.pet.create_tween()
		drop.tween_property(c.world.pet, "global_position:y", god.global_position.y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await drop.finished
	await c.wait(0.8)
	c.music("shingye", 2.0)
	await c.say("sera", "…어?", "surprised")
	c.emote("neoul", "?")
	await c.say("neoul", "……")
	await c.say("neoul", "내, 내 몸이!? 이 꼴이 뭐냐!", "angry")
	await c.say("sera", "여우…? 작다. 귀엽…", "happy")
	await c.say("neoul", "무엄하다! 당장 구슬을 토해 내거라!", "angry")
	await c.say("sera", "삼킨 게 아니라 들어온 거라고! 나도 모르겠어!", "angry")
	await c.approach("neoul", 1.5, 120.0)
	await c.say("neoul", "킁킁… 네 폭주하는 마력이 구슬과 얽혔구나. 억지로 빼내면 너도 나도 끝이니라.")
	await c.say("neoul", "그런데… 이상하구나. 네 마력이 잠잠해. 구슬이 네 폭주를 붙잡고 있는 게야.")
	await c.say("sera", "진짜…? 손이 하나도 안 뜨거워.", "surprised")
	c.close_box()
	c.sfx("roar", 4.0)
	c.shake(0.5, 2.0)
	c.weather("dust")
	await c.wait(1.0)
	await c.say("neoul", "…수문장 해태가 깨어났다. 신단을 어지럽힌 자를 먹어 치우러 오는 게야.", "scary")
	await c.say("neoul", "뛰거라, 그릇아! 이 전당은 곧 무너진다!", "angry")
	await c.say("sera", "그릇이라고 부르지 마!", "angry")
	c.close_box()
	GameState.unlock_ability("neoul")
	c.flag("p_bead_done")
	c.save_here("after")
	GameState.save_game()
	c.hud(true)


# ─── P6 무너지는 회랑 ───────────────────────────────────

func enter_t_collapse(c: Cut) -> void:
	if c.has("t_escaped"):
		return
	var ch := c.actor("chaser")
	c.lock()
	c.shake(0.2, 0.8)
	c.sfx("crumble")
	if not c.has("p_collapse_seen"):
		c.flag("p_collapse_seen")
		await c.wait(0.4)
		await c.say("neoul", "뒤를 보지 말고 달리거라!", "angry")
		c.close_box()
	else:
		await c.wait(0.6)
	c.release()
	if ch:
		ch.start()


func teach_dash_jump(c: Cut) -> void:
	await c.teach("대시 점프", "C 대시 직후 Z — 대시의 속도를 싣고 멀리 뛴다.\n모자라면 공중에서 C 로 한 번 더.", ["dash", "jump"], ["dash"])


# ─── P7 수문: 해태 ──────────────────────────────────────

func p_haetae(c: Cut) -> void:
	if c.has("haetae_down"):
		return
	var h := c.enemy("haetae")
	if h == null:
		await p_haetae_end(c)
		return
	if not c.has("p_haetae_met"):
		c.flag("p_haetae_met")
		await c.camera_to(h.global_position + Vector2(-30, -30), 0.8)
		c.freeze_enemies(false)
		c.sfx("roar", 4.0)
		c.shake(0.5, 1.0)
		await c.wait(0.8)
		c.freeze_enemies(true)
		await c.say("sera", "저건… 사자? 개? 뿔이 달렸어!", "surprised")
		await c.say("neoul", "해태니라. 불을 먹는 신수. 신계의 문을 지키는 아이지.")
		await c.say("neoul", "붉은 불은 저놈에겐 밥이나 다름없다. 쏘아 봐야 반은 먹어 치울 게야.")
		await c.say("sera", "그럼 어떡하라고! 난 불밖에 못 쓰는데!", "angry")
		await c.say("neoul", "…방법은 있다. 일단 버티거라.")
		c.close_box()
		await c.camera_back(0.5)
	else:
		await c.say("neoul", "다시 가자. 이번엔 물러서지 말거라.")
		c.close_box()
	c.music("boss")
	h.engaged = true
	c.release()
	# 체력 절반: 첫 빙의
	await c.wait_enemy(h, 0.5)
	if not c.ok():
		return
	if is_instance_valid(h) and h.is_alive() and not GameState.has_ability("fox_mode"):
		c.lock()
		c.sfx("roar", 4.0)
		c.shake(0.4, 1.0)
		await c.say("sera", "하아… 하아… 안 돼, 또 끓어올라…!", "sad")
		c.player.overload = 96.0
		await c.say("neoul", "세라! 그 힘, 이리 다오!", "angry")
		c.close_box()
		GameState.unlock_ability("fox_mode")
		c.player.fox_energy = 1.0
		c.player.force_overload_full()
		await c.wait(0.9)
		c.player.fox_time = 18.0 # 첫 빙의는 조금 길게
		await c.say("sera", "이게… 뭐야. 몸이 가벼워. 불이 — 파래!", "surprised")
		await c.say("neoul", "빙의니라. 네 폭주를 내가 받아 다스린다. 꼬리 하나만큼이지만.")
		c.close_box()
		await c.learn("fox_mode")
		await c.teach("여우 모드", "X 여우불 · A 여우비 · S 구미호 폭풍.\n푸른 불은 해태도 먹지 못한다!", ["attack", "skill_1", "skill_2"])
		c.release()
	# 쓰러질 때까지
	await c.wait_enemy(h)
	if not c.ok():
		return
	await p_haetae_end(c)


func p_haetae_end(c: Cut) -> void:
	c.lock()
	c.flag("haetae_down")
	Music.stop(2.0)
	await c.wait(1.5)
	await c.say("neoul", "…잠들었구나. 이 아이는 그저 문을 지켰을 뿐이니라.", "sad")
	c.close_box()
	c.weather("fox_rain")
	c.sfx("reveal")
	await c.wait(1.2)
	await c.say("sera", "비…? 파란 비야.", "surprised")
	await c.say("neoul", "여우비니라. 신계의 문이 잠깐 열린다. 지금이 아니면 영영 못 나가.")
	await c.say("neoul", "구슬을 되찾을 때까진 네 곁에 붙어 있어야겠구나. …꽉 잡거라.")
	await c.say("sera", "…응.", "happy")
	c.close_box()
	await c.player_walk(36.0, 80.0)
	c.flash(Color(0.85, 0.95, 1.0, 1.0), 1.2)
	c.sfx("fox_transform")
	await c.fade_out(1.2, Color(0.9, 0.96, 1.0))
	c.flag("t_escaped")
	await c.fade_out(0.8)
	await c.narrate("(빗소리)")
	c.close_box()
	await c.goto_room("s_infirmary", "bed")
