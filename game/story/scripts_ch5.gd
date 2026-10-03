extends RefCounted
## 5장 대본 — 별의 마녀 (docs/chapter5.md 7절 이후). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## enter_<방ID>는 방에 들어올 때 잠그지 않고 시작한다 — 컷신이면 c.lock()부터. 1장 학교 방은 1장 대본이 enter_를 이미 쓰므로
## 축제 장면은 방에 덧붙인 trigger(tools/rooms/ch5.py)로 부른다. 인물 대화는 npc_<who>_ch5 (Story가 장 번호로 고름).
##
## 흐름 (플래그): ch5_start → st_fest(축제) → st_fest_seen → st_fest_ready(교장의 사진) → st_evening(리라 방문, st_lyra_came)
##   → 별의 시련 넷(st_key_k·e·tp·s) → st_tower_open → 별의 탑(st_tower_1~5) → 리라 결전(st_lyra_beaten) → 진실(st_truth)
##   → 침공(st_invaded) → 무너진 학교(r5_*: st_escort·st_dorm_seen) → 절망(st_fallen) → 어둠(st_void_done, 꼬리 9 · fox_permanent)
##   → 반격(st_rise) → 거신(st_c1_clear) → 하늘로(st_launch) → 하늘의 문(st_gate_done) → 에필로그(st_epilogue) → 차(st_tea_done)
##   → 엔딩 크레디트 → ChapterFlow.finish(c, 5) (ch5_done) → 자유 탐험
## 시험용 대본(dev_ch5_*)은 파일 끝.

const KEY_NAMES := {"k": "제국의 별 열쇠", "e": "세계수의 별 열쇠", "tp": "대신전의 별 열쇠", "s": "정원의 별 열쇠"}
const TRIAL_ALLIES := ["leonie", "elarien", "aurelia", "isolde", "emberlyn"]
const LETTER_TO := ["mirabel", "greta", "veronica", "ophelia", "emberlyn", "butterworth"]
const REBUILD_HELP := ["pippa", "butterworth", "hodu", "isolde", "leonie", "elarien"]

var _gate_cd := {} ## 하늘의 문: 동료별 지원 재사용 대기 (초 단위 시각)


# ═══════════════════════════════════════════════════════════
# 공용 도우미
# ═══════════════════════════════════════════════════════════

## 지금 장면의 시기: fest(축제 낮) · trial(리라 방문 뒤, 시련) · war(침공 뒤) · epi(에필로그)
func _phase(c: Cut) -> String:
	if c.has("st_epilogue"):
		return "epi"
	if c.has("st_invaded"):
		return "war"
	if c.has("st_lyra_came"):
		return "trial"
	return "fest"


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _pose(c: Cut, who: String, pose: String) -> void:
	var a := c.actor(who)
	if a is Npc:
		(a as Npc).visual.set_pose(pose)


func _npc_pos(c: Cut, who: String) -> Vector2:
	var a := c.actor(who)
	if a is Node2D:
		return (a as Node2D).global_position
	return c.player.global_position


## 동료가 없으면 부른다 (x_t가 INF면 세라 곁)
func _join(c: Cut, kind: String, x_t := INF, y_t := INF) -> Ally:
	var a := c.ally(kind)
	if a == null:
		a = c.ally_join(kind, x_t, y_t)
	elif x_t != INF:
		a.global_position = Vector2(x_t * 16.0 + 8.0, y_t * 16.0)
	return a


func _leave_all(c: Cut) -> void:
	for k in TRIAL_ALLIES:
		c.ally_leave(k)
	c.ally_leave("astrid")


## 아홉 꼬리 완전 빙의 구간: 쓰러졌다 일어나도 여우 모드로
func _ensure_fox(c: Cut) -> void:
	if c.has("fox_permanent") and not c.has("st_epilogue") and not c.player.is_fox():
		c.player.start_fox_mode()


## 작은 너울을 화면 밖으로 치워 둠 (어둠·환상 장면). show=true면 세라 곁으로 돌려놓음
func _pet_away(c: Cut, away := true) -> void:
	var pet := c.world.pet
	if pet == null:
		return
	if away:
		pet.place(Vector2(-4000, -4000), 1)
	else:
		pet.release_script()
		pet.snap_to_player()


## 대본 중에 따라오는 학생들을 만든다 (방 데이터의 st_follow와 같음)
func _spawn_followers(c: Cut) -> void:
	if c.actor("followers") != null:
		return
	var f: Node2D = (load("res://world/entities/ch5/follower.gd") as GDScript).new()
	f.setup(c.world.room, {"who": ["pippa", "student_a", "student_b"]}, "followers")
	c.world.room.add_entity(f)
	c.world.room.actors["followers"] = f


## 이 방의 kind 적이 모두 쓰러질 때까지 기다린다. 그 전에 방을 떠나면 false (대본은 거기서 그만둔다)
func _wait_clear(c: Cut, kind: String, timeout := 1800.0) -> bool:
	var rid := c.world.room.data.id
	await c.wait_until(func() -> bool: return c.world.room == null or c.world.room.data.id != rid or c.enemy(kind) == null, timeout)
	return c.ok() and c.world.room != null and c.world.room.data.id == rid


## 대본 중에 별의 문을 하나 세운다 (시련을 마친 아레나: 곧장 문간으로 돌아가는 문)
func _spawn_star_door(c: Cut, eid: String, x_t: float, y_t: float, to: String, to_id: String, col: String) -> void:
	var room := c.world.room
	if room == null or room.doors.has(eid):
		return
	var pr := Prop.new()
	pr.setup(room, {"kind": "st_star_door", "x": x_t, "y": y_t, "col": col})
	room.add_entity(pr)
	var d := RoomDoor.new()
	d.setup(room, {"x": x_t, "y": y_t, "to": to, "to_id": to_id, "style": "st", "label": "별의 문간"}, eid)
	room.add_entity(d)
	room.doors[eid] = d
	Fx.ring(Vector2(x_t * 16.0 + 8.0, y_t * 16.0 - 20.0), 4.0, 40.0, StArt.STAR, 0.5, 2.0)
	c.sfx("star_twinkle", 0.0)


## 아레나 입장: 문 너머로 몇 걸음 들어올 때까지 기다린 뒤 결계(FlagGate)를 닫는다.
## 들어오지 않고 방을 나가면 false (대본은 거기서 그만둔다)
func _close_arena(c: Cut, flag: String, past_x := 6.0) -> bool:
	c.flag(flag, false)
	var rid := c.world.room.data.id
	await c.wait_until(func() -> bool: return c.world.room == null or c.world.room.data.id != rid or c.player.global_position.x > past_x * 16.0, 3600.0)
	if not c.ok() or c.world.room == null or c.world.room.data.id != rid:
		return false
	c.flag(flag)
	c.sfx("ward", -4.0)
	return true


## 별의 열쇠
func _key_get(c: Cut, id: String) -> void:
	c.flag("st_key_" + id)
	var n := 0
	for k in ["k", "e", "tp", "s"]:
		if c.has("st_key_" + k):
			n += 1
	Music.jingle("jingle_ability")
	c.flash(Color(1.0, 0.95, 0.75, 0.6), 0.5)
	await c.item(String(KEY_NAMES[id]), "별의 문간의 받침대에 꽂히는 별빛 열쇠. (%d/4)" % n)
	if n >= 4 and not c.has("st_tower_open"):
		c.flag("st_tower_open")
		c.shake(0.15, 1.2)
		await c.say("neoul", "열쇠 넷이 모였느니라. …탑이 부르는구나. 별의 문간 가운데 계단이다.")
		c.close_box()
	c.save()


# ═══════════════════════════════════════════════════════════
# 1. 축제 (학교)
# ═══════════════════════════════════════════════════════════

## 4장 끝 → 장 카드 → 여기 (검은 화면, HUD 꺼짐)
func ch5_start(c: Cut) -> void:
	c.lock()
	c.flag("st_fest")
	c.hud(true)
	c.music("festival", 2.0)
	await c.goto_room("s_courtyard", "gate")
	c.lock()
	await c.fade_out(0.01)
	c.player_face(1)
	c.letterbox(true)
	await c.wait(0.4)
	await c.fade_in(1.0)
	await c.title_card("축제의 날", "신전에서 돌아온 다음 날 — 마녀학교", 2.4)
	c.spawn_npc("pippa", 52.0, 19.0, -1)
	await c.walk("pippa", 44.0, 120.0)
	await c.say("pippa", "세라—! 찾았다! 오늘 무슨 날인지 알지? 축! 제!", "happy")
	await c.say("sera", "…알아. 어젯밤에 신전에서 돌아왔잖아. 아직 다리가 후들거려.")
	await c.say("pippa", "그러니까 더 놀아야지! 내 물약 가게 꼭 와. 오늘만 파는 '별사탕 물약'도 있어!", "happy")
	c.bubble("별사탕… 먹을 수 있는 것이니라?", 2.2)
	await c.say("pippa", "광장은 앞마당 오른쪽 끝이야. 레오니 단장님이랑 엘라리엔이랑 아우렐리아도 가게를 열었대! 교장 선생님이 초대하셨다나 봐.")
	await c.say("sera", "…아우렐리아가 가게를? 상상이 안 되는데.", "surprised")
	c.close_box()
	c.sfx("whoosh", -6.0)
	c.face("hodu", -1)
	await c.move("hodu", 46.0, 10.0, 0.01)
	await c.move("hodu", 41.0, 19.0, 0.8)
	await c.say("hodu", "호우.")
	await c.say("pippa", "어, 호두다. 그레타 선생님네 부엉이. …편지? 아, 교장 선생님께 드릴 축제 초대장이구나.")
	await c.say("pippa", "학생 대표가 전해 드리는 게 전통이거든. 그리고 올해 학생 대표는— 짜잔, 우리 세라!", "happy")
	await c.say("sera", "그런 걸 왜 마음대로 정해!", "angry")
	await c.say("pippa", "투표했어. 만장일치. …이졸데도 손 들었다?", "smug")
	await c.say("sera", "…이졸데가?", "surprised")
	c.close_box()
	await c.item("축제 초대장", "교장실(시계탑 꼭대기)의 아스트리드 교장에게 전하자.")
	await c.say("hodu", "호우. 호우우.")
	await c.say("pippa", "호두가 초대장이 아직 잔뜩 남았대. 한가하면 같이 돌려 달라는데? 그럼 난 가게 준비하러 간다!", "happy")
	c.close_box()
	c.walk("pippa", 70.0, 140.0)
	await c.wait(0.6)
	c.hide_actor("pippa")
	await c.say("neoul", "…세라. 어젯밤 첨탑 위의 그 마녀 말이다.")
	await c.say("sera", "'잘 자랐구나, 나의 별.' …나도 계속 생각나.", "sad")
	await c.say("neoul", "그 별빛, 어디선가 맡아 본 냄새였느니라. 아주 오래전에.")
	await c.say("neoul", "…허나 오늘은 축제니라. 일단 먹고, 생각은 그다음에 하자꾸나.", "happy")
	await c.say("sera", "너 그냥 배고픈 거지.", "smug")
	c.close_box()
	c.letterbox(false)
	c.save()
	c.release()


func st_yard_first(c: Cut) -> void:
	await c.wait(0.2)
	c.bubble("고소한 냄새가… 오른쪽 끝에서 나는구나.", 2.6)


func enter_st_festival(c: Cut) -> void:
	match _phase(c):
		"fest":
			if c.has("st_fest_seen"):
				return
			c.flag("st_fest_seen")
			c.lock()
			c.music("festival")
			await c.wait(0.3)
			await c.camera_to(Vector2(30 * 16.0, 15 * 16.0), 1.2)
			await c.say("leonie", "세라. 왔군.")
			await c.say("leonie", "제국 기사단이 가게를 연다. 카엘의 생각이다. …나는 굽기만 한다.")
			await c.camera_to(Vector2(42 * 16.0, 15 * 16.0), 0.8)
			await c.say("elarien", "꿀빵이다. 숲의 벌이 만든 꿀. …사람이 많군.")
			await c.camera_to(Vector2(82 * 16.0, 15 * 16.0), 1.0)
			await c.say("aurelia", "루멘 대신전의 성찬 빵입니다. 축제에 빵을 나누는 것도 신전의 일입니다.")
			await c.say("sera", "아우렐리아가… 빵을 팔아?", "surprised")
			await c.say("aurelia", "나눕니다. 팔지 않습니다.")
			await c.camera_back(0.8)
			await c.say("neoul", "…세라. 여기는… 천국이니라.", "happy")
			c.close_box()
			c.release()
			await c.teach("축제", "인물에게 말을 걸어 축제를 즐기자. 부탁(퀘스트)이 있는 인물 머리 위엔 ! 가 뜬다.\n저녁 무도회는 광장 가운데 무대에서. 그 전에 교장실에 초대장을 전하자.", ["move_up"])
		"trial":
			await c.wait(0.4)
			c.bubble("광장이 텅 비었구나… 다들 무사해야 할 텐데.", 2.6)
		"epi":
			if c.has("ch5_done") and not c.has("st_fest2_seen"):
				c.flag("st_fest2_seen")
				await c.wait(0.4)
				c.bubble("축제를 다시 열었구나. …냄새가 그대로니라!", 2.6)


## 교장실 덧붙임 트리거: 창립자의 사진
func st_photo_scene(c: Cut) -> void:
	if c.has("st_fest_ready"):
		return
	c.lock()
	await c.wait(0.4)
	c.face("astrid", -1)
	await c.say("sera", "교장 선생님. 축제 초대장 가져왔어요.")
	await c.say("astrid", "…고마워요, 세라피나 양. 올해도 학생 대표에게 받는군요.")
	await c.player_walk(10.0)
	await c.say("sera", "그 사진…")
	await c.say("astrid", "창립자이신 선생님과, 마지막 제자 둘. 백이십 년 전이에요.")
	await c.say("sera", "이 작은 쪽이 교장 선생님? …그럼 이쪽은요? 모자가 엄청 크네.", "surprised")
	await c.say("astrid", "…별을 무척 좋아하던 선배였죠.")
	await c.say("astrid", "선생님이 돌아가신 해에 '별을 보러 간다'며 떠났어요. 그 뒤로는 한 번도.", "sad")
	c.close_box()
	c.emote("neoul", "...")
	await c.say("neoul", "(…저 모자. 어젯밤 첨탑 위의 그림자도 저런 모자였느니라.)")
	await c.say("sera", "(…응. 나도 봤어.)", "sad")
	c.close_box()
	c.face("astrid", 1)
	c.emote("astrid", "...")
	await c.say("astrid", "축제는 언제나 생각보다 짧답니다. 하고 싶은 일은 저녁 무도회 전에 다 해 두세요.")
	await c.say("astrid", "불사조의 금서를 원한다면 도서관의 그레타 선생님께. 서명은 언제든 해 드리죠.")
	await c.say("astrid", "저녁에 광장 무대에서 불꽃놀이가 시작되면… 저도 내려가겠어요.", "wink")
	c.close_box()
	c.flag("st_fest_ready")
	c.save()
	c.release()


## 축제 광장 무대: 저녁 축제 시작 물음
func st_evening_ask(c: Cut) -> void:
	if c.has("st_lyra_came") or not c.has("st_fest_ready"):
		return
	var i := await c.choose("sera", "저녁 축제를 시작할까? (무도회와 불꽃놀이 — 낮의 부탁은 그 전에)", ["시작하자", "조금 더 둘러볼래"])
	c.close_box()
	if i == 0:
		await st_evening(c)


## 2. 리라의 방문 (축제 광장)
func st_evening(c: Cut) -> void:
	c.lock()
	c.hud(false)
	await c.fade_out(1.2)
	c.close_box()
	await c.narrate("해가 지고 — 축제의 저녁.")
	c.close_box()
	c.player.global_position = c.marker("evening")
	c.player_face(1)
	c.spawn_npc("astrid", 62.0, 16.0, -1)
	c.letterbox(true)
	c.music("festival")
	await c.fade_in(1.6)
	c.sfx("crowd", -4.0)
	await c.say("astrid", "여러분. 올해도 무사히 축제를 열게 되어 기쁩니다.")
	await c.say("astrid", "이 학교의 결계는 백 년 동안 한 번도 깨진 적이 없어요. 오늘 밤도 마음껏 즐기세요.", "happy")
	c.close_box()
	for i in 3:
		c.flash([Color(1.0, 0.8, 0.45, 0.25), Color(0.55, 0.8, 1.0, 0.25), Color(0.85, 0.6, 1.0, 0.25)][i], 0.4)
		c.sfx("explode", -10.0)
		await c.wait(0.5)
	c.sfx("crowd", -2.0)
	await c.say("emberlyn", "불꽃은 내 담당이다. …올해는 아무도 그을리지 않았다.", "happy")
	await c.say("isolde", "…세라. 무도회 상대가 없으면, 내가 해 줄 수도 있어. 어디까지나 할 수도 있다는 거야.")
	await c.say("sera", "응? 이졸데, 지금 얼굴 빨개진 거—", "smug")
	await c.say("isolde", "불꽃 때문이야!", "angry")
	c.close_box()
	await c.wait(0.4)
	await c.say("ophelia", "어머~ 저 별, 아까보다 더 가까워졌네~? 별이 걸어 내려오는 건… 처음 보는데~", "surprised")
	c.close_box()
	# 별이 내려온다
	Music.stop(1.0)
	await c.camera_to(Vector2(62 * 16.0, 6 * 16.0), 1.2)
	c.sfx("star_twinkle", 2.0)
	await c.wait(0.8)
	c.shake(0.15, 1.0)
	c.sfx("sky_crack", 4.0)
	c.flash(Color(1, 1, 1, 0.85), 0.6)
	Fx.burst(Vector2(62 * 16.0, 6 * 16.0), 80, {spread = 180.0, speed_min = 80.0, speed_max = 320.0, lifetime = 1.2,
		gradient = Palette.fade_gradient(Color(0.85, 0.9, 1.0)), size_min = 2.0, size_max = 5.0, gravity = Vector2(0, 200), add = true})
	await c.narrate("쩌억 — 하는 소리와 함께, 학교를 백 년 동안 지켜 온 큰 결계가 유리처럼 갈라졌다.")
	c.close_box()
	c.sfx("crowd", 2.0)
	c.spawn_npc("lyra", 62.0, 3.0, -1)
	_pose(c, "lyra", "cast")
	c.music("lyra", 2.0)
	await c.move("lyra", 62.0, 11.0, 2.4)
	_pose(c, "lyra", "idle")
	await c.say("lyra", "안녕, 꼬마 아스트리드. …많이 늙었네.", "happy")
	await c.say("astrid", "선배는 하나도 안 변했군요.")
	await c.camera_back(0.8)
	await c.say("lyra", "그리고—", "normal")
	c.face("lyra", -1)
	await c.say("lyra", "잘 자랐구나, 나의 별.", "happy")
	await c.say("sera", "당신… 어젯밤 첨탑 위의.", "surprised")
	c.vignette(0.4)
	await c.say("neoul", "이 냄새… 별의 씨앗. 네 녀석이었구나.", "scary")
	c.vignette(0.0)
	await c.say("lyra", "안녕하세요, 여우신님. 꼬리가 넷이나 돌아왔네요. 다행이에요.", "happy")
	c.close_box()
	# 교장의 진짜 힘 — 그래도 진다
	_pose(c, "astrid", "cast")
	await c.say("astrid", "학생들은 물러나세요.")
	await c.say("astrid", "…백 년 동안 결계를 떠받치던 손이, 오랜만에 가볍군요.")
	c.close_box()
	c.sfx("star_burst", 2.0)
	c.flash(Color(0.85, 0.85, 1.0, 0.6), 0.4)
	Fx.ring(Vector2(62 * 16.0, 14 * 16.0), 10.0, 220.0, Color(0.85, 0.85, 1.0), 0.8, 4.0)
	for k in 3:
		StStrike.spawn(Vector2((54 + k * 8) * 16.0, 8 * 16.0), "pillar", Vector2(28, 220), 0.3, {"damage": 0, "style": "star", "hold": 0.4, "fade": 0.5})
		await c.wait(0.15)
	c.shake(0.3, 0.8)
	await c.say("lyra", "와아. 그거 선생님 마법이지? 하늘을 셋으로 가르던.", "surprised")
	await c.say("lyra", "그런데 아스트리드. 그 손, 떨리고 있어.", "sad")
	c.close_box()
	_pose(c, "lyra", "cast")
	c.sfx("parry", 2.0)
	c.flash(Color(1.0, 0.95, 0.8, 0.7), 0.3)
	await c.wait(0.3)
	_pose(c, "astrid", "kneel")
	c.shake(0.2, 0.5)
	await c.say("astrid", "……!", "tired")
	await c.say("sera", "교장 선생님!", "surprised")
	c.close_box()
	# 강자들이 나서지만 — 별의 무게
	await c.say("leonie", "물러서라, 별의 마녀.")
	await c.say("elarien", "…이 거리면 빗나가지 않는다.")
	await c.say("aurelia", "학생들에게서 떨어지십시오.")
	c.close_box()
	await c.say("lyra", "제국의 검, 세계수의 눈, 빛의 수호자. 다들 와 줬구나. 고마워.", "happy")
	await c.say("lyra", "…그래도 지금은, 앉아 있어 줘.", "serious")
	c.close_box()
	_pose(c, "lyra", "special")
	c.sfx("star_burst", 0.0)
	c.shake(0.4, 0.6)
	c.flash(Color(1.0, 0.95, 0.8, 0.5), 0.5)
	for who in ["leonie", "elarien", "aurelia", "isolde", "emberlyn"]:
		_pose(c, who, "kneel")
		var p := _npc_pos(c, who)
		Fx.ring(p + Vector2(0, -12), 4.0, 26.0, StArt.STAR, 0.5, 2.0)
	await c.say("leonie", "몸이… 움직이지 않는다…", "angry")
	await c.say("aurelia", "이건… 신성력이 아닙니다. 별 하나의 무게가… 그대로.", "surprised")
	c.close_box()
	_pose(c, "lyra", "idle")
	await c.say("lyra", "무서워하지 마. 오늘은 인사만 하러 온 거야.", "happy")
	await c.say("lyra", "네 곳에 별을 내려 두었어. 제국, 세계수, 대신전, 그리고 이 학교의 정원.")
	await c.say("lyra", "별마다 시련이 기다려. 각자의 땅에서, 각자의 강함으로.")
	c.close_box()
	c.shake(0.35, 2.4)
	c.sfx("crumble", 2.0)
	await c.narrate("학교 뒤편 하늘로 — 별빛으로 지은 탑이 솟아올랐다.")
	c.close_box()
	await c.say("lyra", "별의 열쇠 넷을 모으면 저 탑이 열려. 꼭대기에서 기다릴게.")
	await c.say("sera", "…왜 나야. 당신은 대체 뭔데!", "angry")
	await c.say("lyra", "이기면 전부 알려 줄게. 약속해.", "serious")
	await c.say("lyra", "나를 넘어 보렴, 나의 별.", "happy")
	c.close_box()
	_pose(c, "lyra", "special")
	c.sfx("star_burst", 2.0)
	c.flash(Color(1.0, 0.98, 0.9, 0.8), 0.6)
	Fx.burst(Vector2(62 * 16.0, 10 * 16.0), 60, {spread = 180.0, speed_min = 60.0, speed_max = 260.0, lifetime = 1.0,
		gradient = Palette.fade_gradient(StArt.STAR), add = true})
	c.hide_actor("lyra")
	Music.stop(2.0)
	for who in ["leonie", "elarien", "aurelia", "isolde", "emberlyn"]:
		_pose(c, who, "idle")
	await c.wait(1.0)
	await c.approach("astrid", 1.5, 70.0)
	await c.say("sera", "교장 선생님! 괜찮아요?", "sad")
	await c.say("astrid", "…괜찮아요. 백 년 만에 진심으로 마법을 써 봤더니, 몸이 놀랐을 뿐이에요.", "tired")
	await c.say("astrid", "그녀의 이름은 리라. 사진 속의 그 선배예요.", "sad")
	await c.say("leonie", "제국에 별이 떨어졌다면 내 자리는 거기다. 세라— 와라. 기다리겠다.")
	await c.say("elarien", "숲에도 떨어졌다. …늦지 마라.")
	await c.say("aurelia", "대신전의 종루에 별이 내렸습니다. 먼저 가겠습니다, 세라피나.")
	await c.say("emberlyn", "정원 쪽에도 별이 떨어졌다. 이졸데와 내가 함께 간다. 학교는 우리가 지킨다.")
	await c.say("isolde", "…따라오지 말라는 말은 안 했어. 오고 싶으면 와.", "smug")
	await c.say("astrid", "앞마당에 별의 문이 열렸을 거예요. 문마다 시련이 있는 곳으로 곧장 이어지죠. …선배다운 친절이에요.")
	c.close_box()
	c.flag("st_fest_seen")
	c.flag("st_fest_ready")
	c.flag("st_lyra_came")
	c.letterbox(false)
	await c.fade_out(1.0)
	c.hud(true)
	c.music("star_tower", 1.0)
	await c.goto_room("s_courtyard", "star")
	c.lock()
	await c.wait(0.4)
	await c.say("neoul", "…세라. 저 마녀의 별빛과 네 안의 불은 같은 냄새가 나느니라.")
	await c.say("sera", "알아. 그러니까 가서 물어볼 거야. 직접.", "angry")
	c.close_box()
	c.save()
	c.release()


# ═══════════════════════════════════════════════════════════
# 축제의 부탁 (서브 퀘스트) — docs/chapter5.md 6절
# ═══════════════════════════════════════════════════════════

## 호두의 초대장: 받는 사람이면 먼저 전한다 (전했으면 true)
func _letter(c: Cut, who: String) -> bool:
	if not Quests.active("st_hodu_letters") or Quests.step("st_hodu_letters") != 0:
		return false
	if not who in LETTER_TO or c.has("st_letter_" + who):
		return false
	c.flag("st_letter_" + who)
	var n := 0
	for w in LETTER_TO:
		if c.has("st_letter_" + w):
			n += 1
	var thanks: String = {
		"mirabel": "어머, 초대장! 의무실 천막은 광장 오른쪽에 있을게요~ 다치면 와요!",
		"greta": "…초대장. 축제 날에도 도서관은 연다. 그래도 받아 두지.",
		"veronica": "초대장인가. …불꽃놀이 담당이 엠버린이면 소화 결계부터 쳐 두지.",
		"ophelia": "어머~ 초대장이네~ 별 관측대에서 기다릴게~ (아마도)",
		"emberlyn": "고맙다. 올해는 불꽃이 아무도 그을리지 않게 하겠다. …아마.",
		"butterworth": "초대장? 아이고, 나야 매년 식당 지키느라 바쁘지만— 올해는 광장에 솥을 걸었단다!",
	}.get(who, "고마워.")
	await c.say(who, thanks, "happy")
	c.close_box()
	Story.toast("초대장 전하기 %d/6" % n, 1.8)
	if n >= LETTER_TO.size():
		c.quest_step("st_hodu_letters", 1)
	return true


func npc_hodu_ch5(c: Cut) -> void:
	match _phase(c):
		"fest":
			var st := Quests.state("st_hodu_letters")
			if st == 0:
				await c.say("hodu", "호우. 호우우.")
				await c.narrate("호두가 부리로 초대장 뭉치를 내밀었다. 받는 사람: 미라벨 · 그레타 · 베로니카 · 오필리아 · 엠버린 · 버터워스.")
				var i := await c.choose("sera", "같이 돌려 줄까?", ["돌려 줄게", "나중에"])
				c.close_box()
				if i == 0:
					c.quest_start("st_hodu_letters")
					await c.say("hodu", "호우!", "happy")
			elif st == 1 and Quests.step("st_hodu_letters") >= 1:
				await c.say("hodu", "호우우!", "happy")
				await c.narrate("호두가 날개를 퍼덕이며 세라의 모자 위에 잠깐 앉았다 갔다. …발톱이 따끔하다.")
				c.close_box()
				await c.quest_done("st_hodu_letters")
			else:
				await c.say("hodu", "호우.")
		"war":
			await c.say("hodu", "호우…")
		"epi":
			await _rebuild_help(c, "hodu")
		_:
			await c.say("hodu", "호우.", "happy")
	c.close_box()


# ─── 피피의 축제 물약 가게 ──────────────────────────────

func npc_pippa_ch5(c: Cut) -> void:
	match _phase(c):
		"fest":
			var st := Quests.state("st_pippa_stall")
			if st == 0:
				await c.say("pippa", "어서 오세요~ 피피의 축제 물약 가게! …라고 하고 싶은데, 재료가 모자라!", "sad")
				await c.say("pippa", "별사탕 꿀(식당), 반딧불 이끼(유리 온실), 시계탑 이슬(시계탑 톱니 사이). 이 셋이면 물약 병을 하나 더 만들 수 있어!")
				await c.say("pippa", "구해 주면 네 물약 주머니부터 늘려 줄게. 진짜야!", "happy")
				c.close_box()
				c.quest_start("st_pippa_stall")
			elif st == 1:
				var got := 0
				for f in ["st_ing_honey", "st_ing_moss", "st_ing_dew"]:
					if c.has(f):
						got += 1
				if got >= 3:
					await c.say("pippa", "꿀, 이끼, 이슬… 다 있어! 꺄아, 세라 최고!", "happy")
					c.close_box()
					c.sfx("squish")
					c.shake(0.05, 0.4)
					await c.wait(0.6)
					await c.say("pippa", "짜잔! 별사탕 물약 주머니야. …맛은 여전히 보장 못 해.", "smug")
					c.close_box()
					await c.quest_done("st_pippa_stall")
				else:
					await c.say("pippa", "재료는 %d/3. 식당, 유리 온실, 시계탑이야!" % got)
			else:
				await c.say("pippa", "별사탕 물약 한 병 마셔 볼래? …왜 표정이 그래?", "happy")
		"trial":
			await c.say("pippa", "…교장 선생님은 별의 문간에서 버티고 계셔. 미라벨 선생님이 말려도 소용없대.", "sad")
			await c.say("pippa", "난 물약을 잔뜩 만들어 둘게. 다녀와, 세라. 꼭!")
		"epi":
			await _pippa_epi(c)
		_:
			await c.say("pippa", "세라…!", "sad")
	c.close_box()


# ─── 버터워스의 요리 대회 ───────────────────────────────

func npc_butterworth_ch5(c: Cut) -> void:
	if await _letter(c, "butterworth"):
		return
	match _phase(c):
		"fest":
			var st := Quests.state("st_cook_off")
			if st == 0:
				await c.say("butterworth", "왔구나, 세라! 올해 축제 요리 대회 심사위원이 모자라서 말이야.", "happy")
				await c.say("butterworth", "제국 소시지, 엘프 꿀빵, 신전 성찬 빵. 세 가게를 다 맛보고, 어디가 제일인지 알려 주렴.")
				await c.say("neoul", "세라. 이것은 하늘이 내린 사명이니라.", "happy")
				c.close_box()
				c.quest_start("st_cook_off")
			elif st == 1 and Quests.step("st_cook_off") >= 1:
				await _cook_judge(c)
			elif st == 1:
				var n := 0
				for w in ["leonie", "elarien", "aurelia"]:
					if c.has("st_cook_" + w):
						n += 1
				await c.say("butterworth", "맛본 가게는 %d/3. 천천히 꼭꼭 씹어 먹고 오렴." % n)
			else:
				await c.say("butterworth", "심사 고마웠다! 내 국도 한 그릇 하고 가렴.", "happy")
		"trial":
			await c.say("butterworth", "밥은 먹고 다니니? 싸우는 사람일수록 든든히 먹어야 해.", "sad")
			await c.say("butterworth", "주먹밥 싸 줄 테니 들고 가렴.")
			c.close_box()
			GameState.heal_full()
			c.player.restore_from_state()
			Story.toast("체력이 가득 찼다.", 1.6)
		"epi":
			await _rebuild_help(c, "butterworth")
		_:
			await c.say("butterworth", "…", "sad")
	c.close_box()


## 맛보기 (요리 대회 진행 중일 때 레오니·엘라리엔·아우렐리아 가게)
func _cook_taste(c: Cut, who: String) -> bool:
	if not Quests.active("st_cook_off") or Quests.step("st_cook_off") != 0 or c.has("st_cook_" + who):
		return false
	match who:
		"leonie":
			await c.say("leonie", "제국 기사단 소시지다. 숯불에 세 번 뒤집었다. …먹어 봐라.")
			await c.narrate("짭조름하고, 터질 듯 탱탱하다. 너울의 꼬리가 넷 다 붕붕 돈다.")
			await c.say("leonie", "…나쁘지 않은 표정이군.", "happy")
		"elarien":
			await c.say("elarien", "꿀빵. 숲의 벌은 별꽃에서만 꿀을 딴다. …천천히 먹어라. 뜨겁다.")
			await c.narrate("겉은 바삭, 속은 꿀이 흘러내린다. 혀가 데었다.")
			await c.say("elarien", "…말했잖아.", "smug")
		"aurelia":
			await c.say("aurelia", "성찬 빵입니다. 나누어 먹는 빵이니, 반은 그 여우에게.")
			await c.narrate("담백하고, 씹을수록 단맛이 난다. 너울이 조용히 반쪽을 받아 들었다.")
			await c.say("neoul", "…이 마녀, 생각보다 좋은 녀석이니라.", "happy")
	c.close_box()
	c.flag("st_cook_" + who)
	var n := 0
	for w in ["leonie", "elarien", "aurelia"]:
		if c.has("st_cook_" + w):
			n += 1
	Story.toast("요리 대회 맛보기 %d/3" % n, 1.8)
	if n >= 3:
		c.quest_step("st_cook_off", 1)
	return true


func _cook_judge(c: Cut) -> void:
	await c.say("butterworth", "그래, 어디가 제일이었니?")
	var i := await c.choose("sera", "가장 맛있었던 건…", ["제국 소시지", "엘프 꿀빵", "신전 성찬 빵", "…셋 다 1등!"])
	c.close_box()
	match i:
		0: await c.say("butterworth", "역시 고기지! 레오니 단장한테 전해 줘야겠구나.", "happy")
		1: await c.say("butterworth", "꿀빵이라… 단 게 당겼구나. 엘라리엔이 귀까지 빨개지겠어.", "happy")
		2: await c.say("butterworth", "담백한 걸 고를 줄 알다니, 어른이 다 됐구나.", "happy")
		_: await c.say("butterworth", "아이고, 심사위원이 이러면 어쩌니! …하하, 그래도 그게 정답이지.", "happy")
	await c.say("butterworth", "자, 심사위원 상이다. 든든한 한 끼야. 남기지 마라!")
	c.close_box()
	await c.quest_done("st_cook_off")


# ─── 이졸데의 무도회 ────────────────────────────────────

func npc_isolde_ch5(c: Cut) -> void:
	match _phase(c):
		"fest":
			if Quests.state("st_isolde_dance") == 0:
				await c.say("isolde", "…세라. 잠깐. 저녁 무도회 말인데.")
				await c.say("isolde", "연습 상대가 필요해. 고급반 애들은 다 발을 밟는다고. 너라면… 밟혀도 상관없으니까.", "smug")
				c.close_box()
				c.quest_start("st_isolde_dance")
				await _isolde_dance(c)
			else:
				await c.say("isolde", "…연습한 대로 해. 저녁에 발 밟으면 얼려 버릴 거야.", "smug")
		"trial":
			if c.has("st_key_s"):
				await c.say("isolde", "정원의 별은 끝났어. 나머지 셋도 빨리 끝내고 와. …기다리는 거 아니야.", "smug")
			else:
				await c.say("isolde", "정원 쪽 별의 문이야. 엠버린 교수님이랑 먼저 가 있을게.")
		"epi":
			await _rebuild_help(c, "isolde")
		_:
			await c.say("isolde", "……", "sad")
	c.close_box()


func _isolde_dance(c: Cut) -> void:
	await c.say("isolde", "오른손은 여기. 왼손은… 거기. 박자는 셋. 하나, 둘—")
	var score := 0
	var a := await c.choose("sera", "첫 박자!", ["한 발 앞으로", "한 바퀴 돌기", "가만히 있기"])
	if a == 0:
		score += 1
		await c.say("isolde", "…그래, 그거야.")
	else:
		await c.say("isolde", "아니, 그건 셋째 박자고!", "angry")
	var b := await c.choose("sera", "둘째 박자!", ["손을 놓기", "손을 들어 이졸데를 돌리기", "발을 밟기"])
	if b == 1:
		score += 1
		await c.say("isolde", "…! 제법이네.", "surprised")
	elif b == 2:
		await c.say("isolde", "아야! 일부러지?!", "angry")
	else:
		await c.say("isolde", "놓으면 어떡해!", "angry")
	var d := await c.choose("sera", "마지막 박자!", ["인사하며 마무리", "그대로 불꽃 한 발", "웃기"])
	if d == 0:
		score += 1
	elif d == 2:
		await c.say("isolde", "…왜 웃어. 바보.", "smug")
	c.close_box()
	if score >= 2:
		await c.say("isolde", "흥. 폐급치고는 나쁘지 않아. …아니, 폐급이란 말은 취소할게. 오래전에 했어야 했는데.", "happy")
	else:
		await c.say("isolde", "…연습이 더 필요하네. 그래도, 같이 춰 준 건 고마워.", "smug")
	await c.say("isolde", "이거 받아. 무도회 상대 사례. 고급반에서 쓰다 남은 마도석이야. 어디까지나 남은 거야.")
	c.close_box()
	await c.quest_done("st_isolde_dance")


# ─── 오필리아의 별 관측 ─────────────────────────────────

func npc_ophelia_ch5(c: Cut) -> void:
	if await _letter(c, "ophelia"):
		return
	match _phase(c):
		"fest":
			if Quests.state("st_ophelia_stars") == 0:
				await c.say("ophelia", "어머~ 세라. 마침 잘 왔어. 별 보는 사람이 한 명 더 필요했거든~")
				c.close_box()
				c.quest_start("st_ophelia_stars")
				await _ophelia_stars(c)
			else:
				await c.say("ophelia", "저 별~ 아직도 가까워지고 있어~ 신기하지~?")
		"trial":
			await c.say("ophelia", "별의 정원은 내 별 관측 수업 뜰이야~ 별은 아래에서 위로, 가까운 것부터 이어~")
		_:
			await c.say("ophelia", "별이 다시 제자리로 돌아갔네~ 다행이야~", "happy")
	c.close_box()


func _ophelia_stars(c: Cut) -> void:
	await c.say("ophelia", "저기 봐~ 저건 구미호자리. 꼬리가 아홉 개라 별도 아홉 개야~")
	await c.say("neoul", "(…흥. 잘 아는구나, 이 졸린 마녀.)", "smug")
	await c.say("ophelia", "그리고 저쪽은 마녀의 모자자리~ 끝에 매달린 별이 제일 밝지~")
	await c.say("ophelia", "그런데 이상하지~ 오늘 저녁부터 별 하나가 너무 가까워. 어젯밤보다 손가락 한 마디만큼~", "surprised")
	await c.say("sera", "별이 가까워진다는 게… 무슨 뜻이에요?")
	await c.say("ophelia", "글쎄~ 별이 걸어 내려오는 건 아니겠지~? …아니겠지~?")
	await c.say("neoul", "세라. 저 별의 빛… 네 불 속의 냄새와 같구나.")
	c.close_box()
	await c.say("ophelia", "같이 봐 줘서 고마워~ 이건 별 관측반 출석 도장 대신이야~", "happy")
	c.close_box()
	await c.quest_done("st_ophelia_stars")


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
				await st_photo_scene(c)
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
				await st_tea(c)
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
		await st_tea(c)
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


# ═══════════════════════════════════════════════════════════
# 3. 별의 문간 · 별의 시련 넷
# ═══════════════════════════════════════════════════════════

func enter_st_crossroads(c: Cut) -> void:
	_leave_all(c)
	if c.has("st_cross_seen") or not c.has("st_lyra_came"):
		return
	c.flag("st_cross_seen")
	c.lock()
	await c.wait(0.4)
	await c.say("astrid", "…역시 왔군요, 세라피나 양.", "tired")
	await c.say("sera", "교장 선생님! 쉬셔야죠!", "surprised")
	await c.say("astrid", "쉬고 있어요. 서서 쉬는 것도 교장의 특기랍니다.", "wink")
	await c.say("astrid", "이곳은 선배가 만든 별의 문간이에요. 문 넷이 각각 제국, 세계수, 대신전, 학교의 정원으로 곧장 이어져요.")
	await c.say("astrid", "가운데 계단이 탑의 꼭대기로 가는 길. 별의 열쇠 넷을 받침대에 꽂아야 열리죠.")
	await c.say("astrid", "문마다 제가 작은 별을 하나씩 달아 두었어요. 시련을 마치면 그 별을 타고 곧장 이리로 돌아올 수 있게.")
	await c.say("astrid", "그리고 촛대도 하나. 다치면 언제든 여기서 쉬어 가세요.")
	await c.say("sera", "…고마워요. 순서는 상관없어요?")
	await c.say("astrid", "선배는 원래 순서 같은 걸 싫어했어요. 마음 가는 곳부터.", "happy")
	c.close_box()
	c.save()
	c.release()


# ─── 제국: 레오니와 별 기사 ─────────────────────────────

func enter_st_trial_k1(c: Cut) -> void:
	if c.has("st_key_k"):
		return
	if c.has("st_k_met"):
		_join(c, "leonie")
		return
	c.flag("st_k_met")
	c.lock()
	c.music("kingdom_night")
	_join(c, "leonie", 12.0, 19.0)
	await c.wait(0.5)
	await c.say("leonie", "왔군, 세라.")
	await c.say("leonie", "별빛 기사가 거리를 걷는다. 시민은 모두 집 안에 들였다. …내 검을 흉내 내는 놈들이다.")
	await c.say("sera", "레오니의 검을? 리라가 만든 거야?")
	await c.say("leonie", "그래. 잔상 베기, 받아치기까지 똑같다. 하지만 흉내는 흉내일 뿐이다.")
	await c.say("leonie", "같이 간다. 등 뒤는 맡겨라.")
	await c.say("neoul", "별 정령의 선은 숨을 쉬듯 켜졌다 꺼지느니라. 꺼졌을 때 지나가거나, 정령 하나를 끄거라.")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_trial_k(c: Cut) -> void:
	if c.has("st_key_k"):
		return
	_join(c, "leonie")
	if not await _close_arena(c, "st_k_fight", 5.0):
		return
	c.lock()
	var en := c.spawn_enemy("star_knight", 30, 19, "grand_knight", {"grand": true})
	await c.say("leonie", "…저건 나다. 열 살의 나. 처음 검을 쥐었을 때의 자세.")
	await c.say("sera", "레오니?")
	await c.say("leonie", "리라라는 마녀는 나를 오래 보아 온 모양이다. …괜찮다. 이번엔 둘이다.")
	c.close_box()
	c.music("knight_duel")
	if en:
		en.engaged = true
	c.release()
	await c.wait_enemy(en, 0.5)
	if not c.ok():
		return
	var a := c.ally("leonie")
	if a and is_instance_valid(en) and en.is_alive():
		a.say("세라, 지금이다!")
		a.special(en)
	await c.wait_enemy(en)
	if not c.ok():
		return
	c.flag("st_k_fight", false)
	c.lock()
	Music.stop(1.0)
	await c.wait(0.8)
	await c.say("leonie", "…끝났다. 나쁘지 않군, 세라.", "happy")
	await _key_get(c, "k")
	_spawn_star_door(c, "out", 20.0, 19.0, "st_crossroads", "k", "k")
	await c.say("leonie", "브론이 밤새 새 검을 벼리고 있다. 별빛 따위가 아니라— 진짜 적을 벨 검을.")
	await c.say("leonie", "그 마녀가 노리는 게 무엇이든, 그 검이 필요할 날이 올 것 같다.")
	c.close_box()
	c.music("kingdom_night")
	c.release()


# ─── 세계수: 엘라리엔의 엄호와 별 궁수 ──────────────────

func enter_st_trial_e1(c: Cut) -> void:
	if c.has("st_key_e"):
		return
	var cover := c.marker("cover") / 16.0
	var a := _join(c, "elarien", cover.x - 0.5, cover.y)
	a.mode = "hold"
	if c.has("st_e_met"):
		return
	c.flag("st_e_met")
	c.lock()
	c.music("elf")
	await c.wait(0.5)
	await c.say("elarien", "…왔나. 위에 둘. 별을 쏘는 그림자다.")
	await c.say("elarien", "붉은 선이 너를 따라오다 굳으면, 그때 쏜다. 굳은 선에서 비켜라.")
	await c.say("elarien", "나는 여기서 쏜다. 네가 오를 길은 내가 비운다.")
	await c.say("sera", "엘라리엔이 엄호해 주면 든든하지.")
	await c.say("elarien", "…맞히는 건 쉽다. 안 맞히는 게 어렵지.", "smug")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_trial_e(c: Cut) -> void:
	if c.has("st_key_e"):
		return
	var cover := c.marker("cover") / 16.0
	var a := _join(c, "elarien", cover.x - 0.5, cover.y)
	a.mode = "hold"
	if not await _close_arena(c, "st_e_fight", 4.0):
		return
	c.lock()
	var en := c.spawn_enemy("star_archer", 20, 10, "grand_archer", {"grand": true})
	await c.say("elarien", "…저 자세. 내 활이다. 백 년 전의 나.")
	await c.say("elarien", "그해, 숲에 별을 보러 온 마녀가 있었다. 모자가 컸다. 내 활을 오래 보더니 웃었다.")
	await c.say("elarien", "그리고 밤새 별을 보면서… 울었다.")
	await c.say("sera", "리라가… 울었다고?", "surprised")
	await c.say("elarien", "이유는 몰랐다. 지금도 모른다. 쏴라, 세라.")
	c.close_box()
	c.music("elf_hunt")
	if en:
		en.engaged = true
	c.release()
	await c.wait_enemy(en, 0.5)
	if not c.ok():
		return
	if a and is_instance_valid(a) and is_instance_valid(en) and en.is_alive():
		a.special(en)
	await c.wait_enemy(en)
	if not c.ok():
		return
	c.flag("st_e_fight", false)
	c.lock()
	Music.stop(1.0)
	await c.wait(0.8)
	await c.say("elarien", "…맞혔군. 네 불은 여전히 숲을 태우지 않는다.", "happy")
	await _key_get(c, "e")
	_spawn_star_door(c, "out", 20.0, 19.0, "st_crossroads", "e", "e")
	await c.say("elarien", "장로님이 세계수의 가지 하나를 떼어 두셨다. 언젠가 활로 깎으라고.")
	await c.say("elarien", "…무엇을 쏘게 될지는 모르겠다. 다만, 튕기지 않는 화살이 필요할 거다.")
	c.close_box()
	c.music("elf")
	c.release()


# ─── 대신전: 아우렐리아와 별 창기사 ─────────────────────

func enter_st_trial_tp1(c: Cut) -> void:
	if c.has("st_key_tp"):
		return
	if c.has("st_tp_met"):
		_join(c, "aurelia")
		return
	c.flag("st_tp_met")
	c.lock()
	c.music("temple")
	_join(c, "aurelia", 12.0, 19.0)
	await c.wait(0.5)
	await c.say("aurelia", "왔군요, 세라피나. 회랑의 별빛 창기사는 제 창을 흉내 냅니다.")
	await c.say("aurelia", "바닥의 금빛 띠가 보이면 돌진이 옵니다. 돌진은 직선입니다. 기둥 뒤로.")
	await c.say("sera", "아우렐리아의 돌진이라면… 첨탑에서 질리도록 봤지.", "smug")
	await c.say("aurelia", "…그때는 실례했습니다.")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_trial_tp(c: Cut) -> void:
	if c.has("st_key_tp"):
		return
	_join(c, "aurelia")
	if not await _close_arena(c, "st_tp_fight", 5.0):
		return
	c.lock()
	var en := c.spawn_enemy("star_lancer", 30, 19, "grand_lancer", {"grand": true})
	c.sfx("bell", 0.0)
	await c.say("aurelia", "종루에 내린 별… 이 별빛 속에, 흰빛이 아주 조금 섞여 있습니다.", "surprised")
	await c.say("aurelia", "바깥 신들의 흰빛입니다. 리라라는 마녀는— 그들을 알고 있습니다.")
	await c.say("sera", "리라가 바깥 신들이랑 한편이라는 거야?")
	await c.say("aurelia", "모릅니다. 다만 이 별빛은… 무언가를 견디는 빛입니다. 제가 그랬던 것처럼.")
	c.close_box()
	c.music("aurelia")
	if en:
		en.engaged = true
	c.release()
	await c.wait_enemy(en, 0.5)
	if not c.ok():
		return
	var a := c.ally("aurelia")
	if a and is_instance_valid(en) and en.is_alive():
		a.special(en)
	await c.wait_enemy(en)
	if not c.ok():
		return
	c.flag("st_tp_fight", false)
	c.lock()
	Music.stop(1.0)
	c.sfx("bell", 2.0)
	await c.wait(1.0)
	await c.say("aurelia", "종이 울렸습니다. 별의 시련, 통과입니다.")
	await _key_get(c, "tp")
	_spawn_star_door(c, "out", 20.0, 19.0, "st_crossroads", "tp", "tp")
	await c.say("aurelia", "루멘이 마지막으로 남긴 빛이 제단에 조금 있습니다. 쓸 때가 오면… 당신 곁에서 쓰겠습니다.")
	c.close_box()
	c.music("temple")
	c.release()


# ─── 학교: 이졸데·엠버린과 별의 정원 ────────────────────

func enter_st_trial_s1(c: Cut) -> void:
	if c.has("st_key_s"):
		return
	_join(c, "isolde")
	_join(c, "emberlyn")
	if c.has("st_s_met"):
		return
	c.flag("st_s_met")
	c.lock()
	c.music("school_day")
	await c.wait(0.4)
	await c.say("isolde", "늦었어, 세라. …뭐, 나도 방금 왔지만.", "smug")
	await c.say("emberlyn", "별의 정원이다. 오필리아가 별 관측 수업에 쓰던 뜰이지.")
	await c.say("emberlyn", "떨어진 별을 화염탄으로 순서대로 이어라. 순서가 틀리면 별이 꺼진다. 표지판을 읽고.")
	await c.say("isolde", "별 쏘는 건 네가 해. 난 옆에서 틀렸다고 말해 줄게.", "smug")
	c.close_box()
	c.save_here("start")
	c.release()


func st_s1_done(c: Cut) -> void:
	await c.wait(0.3)
	c.sfx("star_burst", 0.0)
	await c.say("isolde", "…별자리가 다리가 됐어. 예쁘네. 인정해.", "surprised")
	c.close_box()


func enter_st_trial_s(c: Cut) -> void:
	if c.has("st_key_s"):
		return
	_join(c, "isolde")
	_join(c, "emberlyn")
	if c.has("st_s2_seen"):
		return
	c.flag("st_s2_seen")
	await c.wait(0.4)
	c.bubble("별 정령이 고리를 이루고 있구나. 하나를 끄면 고리가 끊어지느니라.", 3.2)


func st_s2_done(c: Cut) -> void:
	await c.wait(0.3)
	c.sfx("star_burst", 0.0)
	await c.say("emberlyn", "길이 열렸다. 테라스의 별을 지키는 정령은 셋이다. 서두르지 마라.")
	c.close_box()


func st_s_key(c: Cut) -> void:
	if c.has("st_key_s"):
		return
	c.lock()
	for e in c.world.room.enemies:
		if is_instance_valid(e) and e.is_alive() and String(e.get("link")) == "sgk":
			e.take_hit(Hit.make(99999, &"fox", e.global_position))
	await c.wait(0.4)
	await _key_get(c, "s")
	_spawn_star_door(c, "out", 76.0, 10.0, "st_crossroads", "s", "s")
	await c.say("emberlyn", "세라. 네 불은… 이제 내가 가르칠 게 별로 없구나.", "happy")
	await c.say("isolde", "다음 시련엔 나도 데려가. …싫으면 말고.", "smug")
	await c.say("sera", "싫다고 한 적 없어.", "happy")
	c.close_box()
	c.release()


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
	Fx.burst(c.marker("astrid_in") + Vector2(64, -20), 30, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(StArt.STAR), add = true})
	await c.wait(0.4)
	await c.say("astrid", "여기까지 왔군요, 세라피나 양.")
	await c.say("sera", "교장 선생님? 몸은…", "surprised")
	await c.say("astrid", "괜찮다고는 못 하겠네요. 그래도 이 봉인은 제 몫이에요.")
	await c.say("astrid", "선배의 봉인은 선배의 별빛으로만 열리죠. 그런데— 저도 같은 선생님께 배운 별이 있거든요.", "wink")
	c.close_box()
	_pose(c, "astrid", "cast")
	c.sfx("star_burst", 2.0)
	c.flash(Color(0.85, 0.85, 1.0, 0.6), 0.5)
	Fx.ring(Vector2(72 * 16.0, 16 * 16.0), 4.0, 90.0, StArt.STAR, 0.7, 3.0)
	c.flag("st_t5_open")
	await c.wait(0.8)
	_pose(c, "astrid", "idle")
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


# ═══════════════════════════════════════════════════════════
# 8. 절망 — 무너진 학교 (r5_*)
# ═══════════════════════════════════════════════════════════

func enter_r5_clock(c: Cut) -> void:
	if c.has("st_r5_woke"):
		return
	c.flag("st_r5_woke")
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.music("despair")
	c.letterbox(true)
	c.player_face(1)
	await c.wait(0.6)
	await c.say("neoul", "세라! 눈을 떠라, 세라!", "angry")
	await c.fade_in(2.0)
	await c.say("sera", "…으. 여기… 시계탑?")
	await c.say("neoul", "교장이 별빛으로 너를 받아 내던졌느니라. 교장은— 모르겠다. 빛이 흩어졌다.")
	await c.say("sera", "리라는…?", "sad")
	await c.say("neoul", "하늘로 끌려갔느니라. 그리고… 보거라.")
	c.close_box()
	c.zoom(0.82, 2.0)
	await c.camera_to(c.player.global_position + Vector2(200, -60), 2.4)
	for k in 3:
		c.sfx("colossus_step", 4.0)
		c.shake(0.45, 0.5)
		await c.wait(1.2)
	await c.narrate("지평선을 하얀 거신들이 메우고 있었다.")
	await c.narrate("도시보다 큰 발이 땅을 디딜 때마다, 세계가 울렸다.")
	await c.say("sera", "…저게, 뭐야.", "surprised")
	await c.say("neoul", "바깥 신들의 손발이니라. 저것들은 생각하지 않는다. 그저 걷고, 밟고, 지운다.")
	await c.say("sera", "학교에… 학교에 다들 있어! 피피, 이졸데…!")
	await c.say("neoul", "가자. 아래로!")
	c.close_box()
	await c.camera_back(1.0)
	c.zoom(1.0, 0.8)
	c.letterbox(false)
	c.hud(true)
	c.save_here("land")
	c.release()


## 통신 수정 구슬: 각 지역 강자에게서 오는 소식
func _comm(c: Cut, flag: String, lines: Array, vision := "", who := "", pose := "kneel", caption := "") -> void:
	if c.has(flag):
		return
	c.flag(flag)
	c.lock()
	c.sfx("window", 0.0)
	await c.narrate("깨진 통신 수정 구슬이 지직거리며 빛났다.")
	c.close_box()
	if vision != "":
		await _vision(c, vision, who, pose, caption, lines)
	else:
		for l in lines:
			var row: Array = l
			await c.say(String(row[0]), String(row[1]), String(row[2]) if row.size() > 2 else "normal")
	c.close_box()
	c.release()


## 같은 시각, 다른 지역 (침공의 땅울림): 통신이 울리는 동안 그 땅을 보여 주고 돌아온다.
## 세라는 보이지 않고 다치지 않는다. 돌아오는 자리는 지금 방의 "comm" 표식
func _vision(c: Cut, room_id: String, who: String, pose: String, _caption: String, lines: Array) -> void:
	var back := c.world.room.data.id
	await c.fade_out(0.6)
	c.hud(false)
	c.letterbox(true)
	c.player.set("_hurt_iframe", 999.0)
	await c.goto_room(room_id, "view")
	c.lock()
	await c.fade_out(0.01)
	c.player.visible = false
	_pet_away(c)
	var n := c.spawn_npc(who, 14.0, 19.0, 1)
	if n:
		n.visual.set_pose(pose)
	c.freeze_enemies(false)
	await c.fade_in(1.0)
	for k in 2:
		c.sfx("colossus_step", 4.0)
		c.shake(0.5, 0.5)
		await c.wait(0.9)
	for l in lines:
		var row: Array = l
		await c.say(String(row[0]), String(row[1]), String(row[2]) if row.size() > 2 else "normal")
	c.close_box()
	await c.fade_out(0.6)
	c.player.visible = true
	await c.goto_room(back, "comm")
	_pet_away(c, false)
	c.lock()
	c.player.set("_hurt_iframe", 1.0)
	c.letterbox(false)
	c.hud(true)


func r5_comm_leonie(c: Cut) -> void:
	await _comm(c, "st_comm_k", [
		["leonie", "…세라, 들리나. 황도에 거신이 들어왔다.", "sad"],
		["leonie", "검을 맞혔다. 흠집 하나 나지 않았다. …검이 부러졌다.", "sad"],
		["leonie", "시민은 성 지하로 옮겼다. 나는 아직 서 있다. 너도— 서 있어라."],
	], "r5_vision_k", "leonie", "kneel", "같은 시각 — 황도 아르덴")
	await c.say("sera", "레오니! 레오니!!", "surprised")
	await c.say("neoul", "…끊겼느니라.", "sad")
	c.close_box()
	c.release()


func enter_r5_hall(c: Cut) -> void:
	if c.has("st_escort"):
		return
	if not c.has("st_hall_seen"):
		c.flag("st_hall_seen")
		c.lock()
		await c.wait(0.4)
		await c.say("pippa", "세라!! 여기야, 여기!", "sad")
		await c.say("sera", "피피!", "surprised")
		await c.say("pippa", "발코니가 무너져서 못 나가! 저 하얀 것들이 계속 내려와…!", "sad")
		await c.say("neoul", "흰 사도니라. 저것들은 푸른 불을 싫어하지만— 지금 네 불로도 끌 수는 있다. 가거라!")
		c.close_box()
		c.release()
	if not await _wait_clear(c, "outer_seraph"):
		return
	c.lock()
	await c.wait(0.5)
	await c.approach("pippa", 2.0, 90.0)
	await c.say("pippa", "…세라. 고마워. 다리가 좀 아프지만, 걸을 수 있어.", "sad")
	await c.say("pippa", "얘들아, 세라 따라가! 절대 손 놓지 마!")
	await c.say("sera", "기숙사 쪽 대피소로 가자. 서관을 돌아서!")
	c.close_box()
	c.flag("st_escort")
	for who in ["pippa", "student_a", "student_b"]:
		c.hide_actor(who)
	_spawn_followers(c)
	c.save_here("start")
	c.release()


func enter_r5_westcorr(c: Cut) -> void:
	if c.has("st_westcorr_seen"):
		return
	c.flag("st_westcorr_seen")
	await c.wait(0.5)
	var f := c.actor("followers")
	if f and f.has_method("say"):
		f.say(0, "천장이…!", 2.0)
	c.bubble("위니라! 손이 내려온다 — 멈추지 말고 달려라!", 3.0)


func enter_r5_library(c: Cut) -> void:
	if c.has("st_lib_saved"):
		return
	if not c.has("st_lib_seen"):
		c.flag("st_lib_seen")
		c.lock()
		await c.wait(0.4)
		await c.say("greta", "…세라피나. 이쪽으로 오지 마라. 위에 하나 있다.")
		await c.say("sera", "그레타 선생님! 빨리 나가요, 책은 두고!")
		await c.say("greta", "책은 두고 가지 않는다.")
		await c.say("hodu", "호우…!")
		c.close_box()
		c.release()
	if not await _wait_clear(c, "outer_seraph"):
		return
	c.lock()
	await c.wait(0.4)
	await c.say("greta", "…고맙다. 금서 몇 권은 챙겼다. 나머지는— 다시 쓰면 된다.")
	await c.say("greta", "기억해 둬라. 불사조는 제 재 속에서 다시 일어난다.")
	await c.say("hodu", "호우.")
	c.close_box()
	c.flag("st_lib_saved")
	c.walk("greta", 2.0, 100.0)
	c.walk("hodu", 2.0, 100.0)
	await c.wait(1.0)
	c.hide_actor("greta")
	c.hide_actor("hodu")
	c.release()
	# 싸우는 동안 수정 구슬 곁을 지나쳤어도 소식은 듣는다
	await c.wait(0.6)
	await r5_comm_elarien(c)


func r5_comm_elarien(c: Cut) -> void:
	await _comm(c, "st_comm_e", [
		["elarien", "…세라. 숲이다.", "sad"],
		["elarien", "거신의 눈을 맞혔다. 세 번. 화살이 튕겼다.", "sad"],
		["elarien", "세계수가 탄다. 아이들은 뿌리 아래에 숨겼다. …살아라."],
	], "r5_vision_e", "elarien", "hurt", "같은 시각 — 세계수")
	await c.say("sera", "엘라리엔…!", "sad")
	c.close_box()
	c.release()


func enter_r5_dorm(c: Cut) -> void:
	if c.has("st_dorm_seen") or c.has("st_dorm_vision"):
		return
	c.lock()
	await c.wait(0.4)
	await c.say("astrid", "…세라피나 양. 다행이에요. 살아 있었군요.", "tired")
	await c.say("sera", "교장 선생님! 탑에서 저를—", "surprised")
	await c.say("astrid", "던진 건 저예요. 받는 건 조금 서툴렀네요. 미안해요.", "tired")
	c.close_box()
	c.flag("st_dorm_vision")
	await _comm(c, "st_comm_tp", [
		["aurelia", "…세라피나. 대신전입니다. 창이… 부서졌습니다.", "sad"],
		["aurelia", "루멘의 빛이 닿지 않습니다. 종루도 무너졌습니다.", "sad"],
		["aurelia", "그래도 저는 아직 서 있습니다. 당신도.", "sad"],
	], "r5_vision_tp", "aurelia", "kneel", "같은 시각 — 루멘 대신전")
	c.lock()
	await c.wait(0.3)
	await c.say("mirabel", "교장 선생님 얼굴이 하얘요… 더 이상은 무리예요!", "sad")
	await c.say("astrid", "괜찮아요. 아직은.", "tired")
	await c.say("astrid", "학생들을 앞마당으로 모읍시다. 제가 결계를 치겠어요.")
	await c.say("astrid", "백 년 동안 떠받치던 것보다는… 작은 결계라 다행이네요.", "wink")
	await c.say("sera", "제가 앞장설게요.")
	c.close_box()
	c.flag("st_dorm_seen")
	for who in ["astrid", "mirabel", "student_c"]:
		c.walk(who, 1.0, 90.0)
	await c.wait(1.2)
	for who in ["astrid", "mirabel", "student_c"]:
		c.hide_actor(who)
	c.save()
	c.release()


## 9. 절망: 무너진 앞마당 (트리거)
func r5_despair(c: Cut) -> void:
	if c.has("st_fallen"):
		return
	c.lock()
	c.letterbox(true)
	var giant: EnemyBase = null
	for e in c.world.room.enemies:
		if not is_instance_valid(e) or e.kind_id != "colossus":
			continue
		if String(e.get("mode")) == "hand":
			e.set("walking", false)
		else:
			giant = e
	await c.wait(0.4)
	c.player_face(1)
	await c.say("sera", "더는 도망칠 데가 없어… 그럼—!", "angry")
	c.close_box()
	# 세라의 공격이 통하지 않는다
	var target := c.player.global_position + Vector2(140, -60)
	if giant and is_instance_valid(giant):
		target = giant.global_position + Vector2(0, -80)
	for k in 3:
		c.sfx("shoot_heavy", 0.0)
		var from := c.player.center()
		StStrike.spawn(from, "beam", Vector2(0, 4), 0.01, {"to": target + Vector2(0, k * 10.0), "damage": 0, "style": "fire", "hold": 0.08, "fade": 0.3})
		Fx.burst(target + Vector2(0, k * 10.0), 18, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.4,
			gradient = Palette.fade_gradient(Color(1.0, 0.6, 0.3)), add = true})
		if giant and is_instance_valid(giant):
			giant.take_hit(Hit.make(60, &"bolt", target + Vector2(0, k * 10.0)))
		await c.wait(0.45)
	await c.narrate("…흠집 하나 나지 않았다.")
	await c.say("sera", "왜… 왜 안 통하는 거야!", "angry")
	await c.say("neoul", "세라, 저것은 싸울 수 있는 것이 아니니라! 물러서라!", "angry")
	c.close_box()
	# 교장의 마지막 결계
	c.spawn_npc("astrid", 22.0, 19.0, 1)
	c.spawn_npc("mirabel", 20.0, 19.0, 1)
	c.spawn_npc("student_c", 18.0, 19.0, 1)
	await c.walk("astrid", 30.0, 80.0)
	_pose(c, "astrid", "shield")
	await c.say("astrid", "학생들은 제 뒤로. 세라피나 양도!")
	c.close_box()
	c.sfx("ward", 4.0)
	var dome := Vector2(28 * 16.0, 19 * 16.0)
	var shield := StStrike.spawn(dome + Vector2(0, -24), "circle", Vector2(80, 80), 0.01, {"damage": 0, "style": "star", "hold": 9.0, "fade": 1.2})
	await c.player_walk(32.0, 140.0)
	c.player_face(1)
	var f := c.actor("followers")
	if f and f.has_method("scatter"):
		f.scatter()
	# 발이 내려온다
	c.sfx("colossus_step", 6.0)
	StStrike.spawn(dome + Vector2(0, -20), "band", Vector2(260, 40), 1.2, {"damage": 0, "style": "white", "hold": 0.2, "fade": 0.3})
	await c.wait(1.2)
	c.shake(0.9, 0.8)
	c.flash(Color(1, 1, 1, 0.8), 0.3)
	c.sfx("slam", 6.0)
	await c.say("astrid", "…학생들에게는, 손가락 하나… 대게 하지 않아요.", "tired")
	c.close_box()
	await c.wait(0.8)
	c.sfx("colossus_step", 6.0)
	await c.wait(0.9)
	c.shake(1.0, 1.0)
	c.flash(Color(1, 1, 1, 0.9), 0.4)
	c.sfx("crumble", 6.0)
	if is_instance_valid(shield):
		shield.queue_free()
	Fx.burst(dome + Vector2(0, -60), 60, {spread = 180.0, speed_min = 60.0, speed_max = 240.0, lifetime = 0.9,
		gradient = Palette.fade_gradient(StArt.STAR), add = true})
	_pose(c, "astrid", "down")
	await c.say("astrid", "세라피나 양… 미안해요… 조금만… 쉬었다가…", "tired")
	await c.say("sera", "교장 선생님!!", "surprised")
	c.close_box()
	await c.player_walk(31.0, 160.0)
	# 손이 세라를 덮친다
	c.sfx("colossus_step", 6.0)
	StStrike.spawn(c.player.global_position + Vector2(0, -30), "band", Vector2(100, 60), 0.8, {"damage": 0, "style": "white", "hold": 0.1, "fade": 0.3})
	await c.wait(0.8)
	c.shake(1.2, 1.2)
	c.flash(Color(1, 1, 1, 1.0), 0.6)
	c.sfx("hit_heavy", 6.0)
	c.player.velocity = Vector2(-220, -200)
	await c.wait(0.8)
	await c.say("neoul", "세라! 세라!!", "angry")
	c.close_box()
	Music.stop(3.0)
	await c.fade_out(3.0)
	await c.narrate("발소리가 멀어지지 않았다.")
	await c.narrate("세라는 차가운 돌바닥 위에서, 손가락 하나 움직일 수 없었다.")
	await c.narrate("……")
	c.close_box()
	c.flag("st_fallen")
	c.letterbox(false)
	await c.goto_room("st_void", "start")


# ═══════════════════════════════════════════════════════════
# 10. 어둠 — 아홉 꼬리
# ═══════════════════════════════════════════════════════════

func enter_st_void(c: Cut) -> void:
	if c.has("st_void_done"):
		await c.goto_room("r5_courtyard_rise", "wake")
		return
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	Music.stop(0.1)
	c.player_face(1)
	_pet_away(c)
	await c.wait(1.0)
	await c.fade_in(3.0)
	await c.wait(0.8)
	await c.say("sera", "…여기는.", "sad")
	await c.say("sera", "아무것도 안 보여. 아무 소리도… 발소리도.", "sad")
	c.close_box()
	await c.wait(1.0)
	var g := c.actor("neoul_god")
	c.music("nine_tails", 3.0)
	if g:
		await g.appear(1.6)
	await c.say("neoul_god", "일어나거라, 그릇아.", "normal")
	await c.say("sera", "……그릇이라고 부르지 마.", "sad")
	await c.say("neoul_god", "…", "sad")
	c.close_box()
	await c.wait(0.6)
	await c.say("sera", "나 말이야. 처음부터 남이 만든 거였대.", "sad")
	await c.say("sera", "폭주도, 마력도, 너의 구슬을 삼킨 것도. 전부 리라가 정해 놓은 길이었대.", "sad")
	await c.say("sera", "그럼 나는… 뭐야? 누군가를 막으려고 만든 도구야?", "sad")
	await c.say("sera", "그 도구는 거신 발가락 하나 못 긁었어. 교장 선생님도… 아무도 못 지켰어.", "sad")
	c.close_box()
	await c.wait(1.2)
	if g:
		g.unveil(true, 1.6)
		g.face(-1)
	await c.wait(1.6)
	await c.say("neoul_god", "……세라야.", "gentle")
	c.close_box()
	await c.wait(1.0)
	await c.say("sera", "…방금. 이름…", "surprised")
	await c.say("neoul_god", "구슬이 네 안에 들어간 그날부터, 나는 너를 쭉 보아 왔느니라.", "gentle")
	await c.say("neoul_god", "폐급이라 손가락질받던 날도, 남을 지키겠다고 불 속에 뛰어든 날도.", "gentle")
	await c.say("neoul_god", "별의 씨앗이 누구의 것이든, 구슬이 누구의 것이든— 그 힘으로 누구를 지킬지 정한 것은, 언제나 너였다.", "gentle")
	await c.say("neoul_god", "레오니의 시장에서. 엘라리엔의 숲에서. 아우렐리아의 첨탑에서. 그건 리라가 그려 둔 길이 아니었느니라.", "gentle")
	await c.say("neoul_god", "네 발로 걸어간 길이었다.", "tearful")
	await c.say("sera", "…너울.", "sad")
	await c.say("neoul_god", "그러니 이번엔 내가 묻겠다. 너는 무엇이냐.", "normal")
	c.close_box()
	await c.wait(0.8)
	await c.say("sera", "나는… 세라피나. 폐급 마녀.", "sad")
	await c.say("sera", "그리고— 너의 짝이야.", "happy")
	await c.say("neoul_god", "…그래. 너는 그릇이 아니니라. 너는 나의 짝이다.", "tearful")
	await c.say("neoul_god", "구슬은 이미 네 안에서 울고 있다. 끝까지 울려 보자꾸나. 아홉 꼬리 전부.", "awaken")
	c.close_box()
	if g:
		await g.awaken()
	await c.tails(9)
	c.flag("fox_permanent")
	await c.title_card("아홉 꼬리", "구미호 — 너울과 하나 되어", 2.6)
	if g:
		await g.merge_into(c.player.center(), 1.4)
	_pet_away(c, false)
	c.player.start_fox_mode()
	await c.wait(0.8)
	await c.say("neoul", "가자, 세라야. 깨워야 할 것들이 있느니라. 그리고— 잠재워야 할 것들도.", "happy")
	c.close_box()
	c.flag("st_void_done")
	await c.fade_out(1.6, Color(0.7, 0.85, 1.0))
	await c.goto_room("r5_courtyard_rise", "wake")


# ═══════════════════════════════════════════════════════════
# 11. 반격 — 다시 일어서는 사람들, 거신 위를 달려
# ═══════════════════════════════════════════════════════════

func enter_r5_courtyard_rise(c: Cut) -> void:
	_ensure_fox(c)
	if c.has("st_rise"):
		for k in TRIAL_ALLIES:
			_join(c, k)
		return
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.music("nine_tails")
	c.letterbox(true)
	c.player_face(1)
	_ensure_fox(c)
	await c.wait(0.4)
	await c.fade_in(2.0)
	c.sfx("fox_storm", 4.0)
	c.flash(Color(0.6, 0.85, 1.0, 0.6), 0.6)
	Fx.ring(c.player.center(), 8.0, 260.0, StArt.FOX_BLUE, 1.2, 5.0)
	await c.wait(0.8)
	await c.narrate("푸른 불이 무너진 앞마당을 따라 번져 나갔다. 거신들의 발이 — 멈칫, 하고 느려졌다.")
	c.close_box()
	c.spawn_npc("pippa", 34.0, 19.0, 1)
	await c.say("pippa", "세라…? 너, 꼬리가… 아홉 개야…", "surprised")
	await c.say("sera", "피피. 괜찮아?")
	await c.say("pippa", "다리 좀 다쳤어. 근데 물약은 아직 있어! 마셔, 전부!", "happy")
	c.close_box()
	GameState.heal_full()
	c.player.restore_from_state()
	c.give_potions(maxi(GameState.potions_max, 3))
	c.spawn_npc("isolde", 30.0, 19.0, 1)
	c.spawn_npc("emberlyn", 26.0, 19.0, 1)
	await c.say("isolde", "…늦잠 잤어? 바보.", "sad")
	await c.say("emberlyn", "교사들이 학교에 결계를 다시 친다. 학생들은 우리가 지킨다.")
	await c.say("emberlyn", "세라. 너는— 앞만 봐라.", "happy")
	c.close_box()
	# 전이진이 빛난다 — 세 강자
	c.sfx("warp", 4.0)
	c.flash(Color(0.75, 0.6, 1.0, 0.5), 0.5)
	await c.wait(0.4)
	c.spawn_npc("leonie", 55.0, 19.0, -1)
	await c.say("leonie", "세라.")
	await c.say("leonie", "브론이 밤새 두드린 검이다. 이번엔 부러지지 않는다.", "happy")
	c.spawn_npc("elarien", 60.0, 19.0, -1)
	await c.say("elarien", "세계수의 가지로 깎은 활이다. 이건 튕기지 않는다.")
	c.spawn_npc("aurelia", 66.0, 19.0, -1)
	await c.say("aurelia", "루멘이 마지막으로 남긴 빛입니다.")
	await c.say("aurelia", "…이번엔, 저도 혼자 지키지 않겠습니다.")
	c.close_box()
	await c.wait(0.4)
	c.spawn_npc("astrid", 20.0, 19.0, 1)
	_pose(c, "astrid", "kneel")
	await c.say("astrid", "…세라피나 양. 그 빛, 정말 따뜻하네요.", "tired")
	await c.say("sera", "교장 선생님! 깨어나셨어요?!", "surprised")
	await c.say("astrid", "저에게도 마지막 한 번쯤은 날 수 있는 힘이 남아 있어요.", "tired")
	await c.say("astrid", "가장 큰 거신의 머리 위에서 기다리겠어요. 거기서— 당신을 하늘까지 쏘아 올려 드리죠.", "wink")
	c.close_box()
	if c.actor("astrid"):
		var ap := _npc_pos(c, "astrid")
		Fx.burst(ap + Vector2(0, -20), 30, {spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.6,
			gradient = Palette.fade_gradient(StArt.STAR), add = true})
	c.hide_actor("astrid")
	await c.say("neoul", "거신들은 지금 푸른 불에 졸고 있느니라. 그 몸을 밟고 올라가거라!")
	await c.say("sera", "다들— 가자!", "angry")
	c.close_box()
	await c.title_card("반격", "", 1.8)
	for who in ["pippa", "leonie", "elarien", "aurelia", "isolde", "emberlyn"]:
		c.hide_actor(who)
	for k in TRIAL_ALLIES:
		_join(c, k)
	c.flag("st_rise")
	c.letterbox(false)
	c.hud(true)
	c.music("final")
	c.save_here("wake")
	c.release()


func r5_rise_go(c: Cut) -> void:
	c.flag("st_rise_go")
	c.bubble("오른쪽이니라! 거신들의 발치로!", 2.4)


func enter_st_colossus_1(c: Cut) -> void:
	_ensure_fox(c)
	for k in TRIAL_ALLIES:
		_join(c, k)
	if c.has("st_c1_clear"):
		return
	if not c.has("st_c1_seen"):
		c.flag("st_c1_seen")
		c.save_here("start")
		c.lock()
		await c.wait(0.3)
		await c.say("leonie", "사도다. 셋.")
		await c.say("elarien", "푸른 불에 약하다. …세라, 네 불이다.")
		await c.say("aurelia", "거신의 발은 우리가 막습니다. 앞으로!")
		c.close_box()
		c.release()
	if not await _wait_clear(c, "outer_seraph"):
		return
	c.flag("st_c1_clear")
	c.sfx("ward", 0.0)
	c.bubble("길이 열렸느니라!", 2.0)


func enter_st_colossus_2(c: Cut) -> void:
	_ensure_fox(c)
	for k in TRIAL_ALLIES:
		_join(c, k)
	if c.has("st_c2_seen"):
		return
	c.flag("st_c2_seen")
	c.lock()
	await c.wait(0.4)
	await c.say("neoul", "거신의 손바닥에서 팔을 타고 어깨로, 머리로. 그리고 다음 거신의 손으로 건너뛰거라!")
	await c.say("leonie", "우리는 발치에서 사도를 막는다. 올라가라, 세라!")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_colossus_3(c: Cut) -> void:
	_ensure_fox(c)
	for k in TRIAL_ALLIES:
		_join(c, k)
	if c.has("st_c3_seen"):
		return
	c.flag("st_c3_seen")
	c.save_here("start")
	await c.wait(0.4)
	c.bubble("가장 큰 거신이니라. 머리 꼭대기까지!", 2.6)


## 교장이 세라를 하늘로 쏘아 올린다 (가장 큰 거신의 머리, 트리거)
func st_launch(c: Cut) -> void:
	if c.has("st_launch"):
		return
	c.lock()
	c.letterbox(true)
	var p := c.player.global_position
	c.spawn_npc("astrid", p.x / 16.0 + 3.0, p.y / 16.0, -1)
	_pose(c, "astrid", "special")
	Fx.burst(p + Vector2(48, -24), 30, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(StArt.STAR), add = true})
	await c.wait(0.5)
	await c.say("astrid", "기다렸어요.", "happy")
	await c.say("astrid", "백 년 동안 결계를 들던 손으로, 이번엔 학생 하나를 하늘로 던져 보죠.", "wink")
	await c.say("sera", "교장 선생님은요?", "sad")
	await c.say("astrid", "저는 여기서 별을 보며 기다리겠어요. 선배가 좋아하던 일이거든요.")
	await c.say("astrid", "…세라피나 양. 선배를— 리라를 부탁해요.", "sad")
	await c.say("sera", "데리고 올게요. 꼭.", "angry")
	c.close_box()
	_pose(c, "astrid", "cast")
	c.sfx("star_burst", 4.0)
	Fx.ring(c.player.global_position, 6.0, 120.0, StArt.STAR, 0.8, 4.0)
	c.flash(Color(1.0, 0.97, 0.85, 0.7), 0.5)
	c.flag("st_launch")
	for k in TRIAL_ALLIES:
		c.ally_leave(k)
	var tw := c.player.create_tween()
	tw.tween_property(c.player, "global_position", c.player.global_position + Vector2(0, -420), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	c.sfx("whoosh", 4.0)
	await c.fade_out(1.0, Color(1.0, 0.97, 0.9))
	c.letterbox(false)
	await c.goto_room("st_sky_1", "launch")


func enter_st_sky_1(c: Cut) -> void:
	_ensure_fox(c)
	if c.has("st_sky_seen"):
		return
	c.flag("st_sky_seen")
	c.lock()
	await c.fade_out(0.01, Color(1.0, 0.97, 0.9))
	c.music("final")
	await c.fade_in(1.2)
	await c.say("neoul", "부서진 세계의 조각들이니라. 위로— 문이 보인다!")
	await c.say("sera", "교장 선생님이 깔아 둔 별빛 기둥도 있어. 가자!")
	c.close_box()
	c.save_here("launch")
	c.release()


# ═══════════════════════════════════════════════════════════
# 12. 하늘의 문 — 최종전
# ═══════════════════════════════════════════════════════════

const GATE_ALLY_SPOT := {"leonie": 0, "aurelia": 1, "isolde": 2, "emberlyn": 3, "elarien": 4}


func enter_st_skygate(c: Cut) -> void:
	if c.has("st_gate_done"):
		return
	_ensure_fox(c)
	c.save_here("start")
	if not await _close_arena(c, "st_gate_fight", 3.0):
		return
	c.lock()
	var gate := c.spawn_enemy("sky_gate", 20, 10, "gate")
	if gate == null:
		c.release()
		return
	await c.wait(0.4)
	if not c.has("st_gate_met"):
		c.flag("st_gate_met")
		c.letterbox(true)
		Music.stop(1.0)
		await c.camera_to(gate.global_position, 1.2)
		await c.say("lyra", "…세… 라…. 오지… 마…", "possessed")
		await c.narrate("「그릇. 그릇. 가장 큰 그릇의 문. 열려라. 열려라.」")
		await c.say("sera", "리라는 문이 아니야.", "angry")
		await c.say("sera", "데리러 왔어.", "angry")
		await c.camera_back(0.8)
		c.close_box()
	# 별빛 길을 타고 동료들이 도착한다
	c.sfx("star_burst", 2.0)
	c.flash(Color(1.0, 0.95, 0.8, 0.5), 0.4)
	for who in GATE_ALLY_SPOT:
		var m := c.marker("al%d" % int(GATE_ALLY_SPOT[who])) / 16.0
		var a := _join(c, String(who), m.x - 0.5, m.y)
		a.mode = "hold"
	await c.say("leonie", "교장의 별빛 길이다. 다 왔다, 세라.")
	await c.say("aurelia", "촉수는 레오니가, 눈은 엘라리엔이. 장막은 제가 꿰뚫겠습니다.")
	await c.say("isolde", "얼리는 건 내 몫이야.", "smug")
	await c.say("emberlyn", "불은 내가 보탠다. 세라— 문 가운데를 노려라!")
	c.close_box()
	c.letterbox(false)
	c.music("final")
	_gate_cd.clear()
	gate.support_needed.connect(_final_support.bind(gate, c))
	gate.phase_changed.connect(_gate_phase.bind(gate, c))
	gate.engaged = true
	c.release()
	_gate_side_loop(c, gate)
	await c.wait_enemy(gate)
	if not c.ok():
		return
	await _gate_end(c, gate)


## 문이 지원을 청할 때: 그 일을 맡은 동료가 대사와 함께 지원기를 쓴다 (동료별 재사용 대기)
func _final_support(kind: String, _pos: Vector2, gate: Node, c: Cut) -> void:
	if not is_instance_valid(gate) or not c.ok():
		return
	var who: String = {"tendril": "leonie", "hand": "leonie", "eye": "elarien", "veil": "aurelia", "shield": "astrid"}.get(kind, "")
	if who == "":
		return
	var cd := 6.0 if who != "astrid" else 9.0
	if _now() < float(_gate_cd.get(who, 0.0)):
		return
	_gate_cd[who] = _now() + cd
	var a := c.ally(who)
	var from := a.global_position + Vector2(0, -20) if a else Vector2.INF
	match kind:
		"tendril", "hand":
			if a:
				a.say(["촉수는 내가 벤다!", "손이다. 받는다!", "물러서라, 세라!"][randi() % 3])
				a.set_pose("special")
			gate.cut_tendril(-1, from)
		"eye":
			if a:
				a.say(["…거기.", "보인다.", "감아라."][randi() % 3])
				a.set_pose("special")
			gate.snipe_eye(-1, from)
		"veil":
			if a:
				a.say(["빛이여!", "장막을 꿰뚫습니다!"][randi() % 2])
				a.set_pose("special")
			gate.holy_lance(5.0, from)
		"shield":
			Story.toast("— 지켜 드리죠. (아스트리드의 별빛)", 1.6)
			gate.star_shield(3.0)


## 문이 청하지 않아도 이졸데(서리)와 엠버린(불꽃)은 틈틈이 돕는다
func _gate_side_loop(c: Cut, gate: Node) -> void:
	var t := 0.0
	var turn := 0
	while c.ok() and is_instance_valid(gate) and (gate as EnemyBase).is_alive():
		await c.wait(0.5)
		t += 0.5
		if Story.busy_count() > 1 or t < 12.0:
			continue
		t = 0.0
		turn += 1
		if turn % 2 == 1:
			var a := c.ally("isolde")
			if a:
				a.say("얼어붙어라!")
				a.set_pose("special")
			gate.frost_bind(4.0)
		else:
			var b := c.ally("emberlyn")
			if b:
				b.say("불을 보탠다!")
				b.set_pose("special")
			gate.fire_volley(300)


func _gate_phase(n: int, gate: Node, c: Cut) -> void:
	if not c.ok() or not is_instance_valid(gate):
		return
	match n:
		2:
			c.bubble("문 너머에서 거신의 손이 온다! 그림자를 피하거라!", 2.8)
			var a := c.ally("leonie")
			if a:
				a.say("손은 내가 받는다!")
		3:
			c.bubble("빨려 들어가지 말거라! 바깥쪽으로 버텨라!", 2.8)
			var b := c.ally("aurelia")
			if b:
				b.say("버티십시오, 세라피나!")
		4:
			c.lock()
			c.letterbox(true)
			await c.say("lyra", "세라… 나를… 막아 줘…", "weak")
			await c.say("sera", "막을 거야. 그리고 데려갈 거야.", "angry")
			await c.say("sera", "너를 막는 건, 너를 구하는 거야.", "angry")
			await c.say("neoul", "푸른 불은 잠재우는 불이니라. 문을 재우거라, 세라야!", "happy")
			c.close_box()
			c.letterbox(false)
			c.release()


func _gate_end(c: Cut, gate: Node) -> void:
	c.lock()
	c.flag("st_gate_fight", false)
	for k in TRIAL_ALLIES:
		var a := c.ally(k)
		if a:
			a.mode = "script"
	Music.stop(2.0)
	c.letterbox(true)
	await c.wait(3.2)
	await c.narrate("하늘의 틈이 — 푸른 실로 꿰매어지듯 닫혀 갔다.")
	c.close_box()
	c.flash(Color(0.6, 0.85, 1.0, 0.7), 1.0)
	c.sfx("fox_end", 2.0)
	c.spawn_npc("lyra", 20.0, 19.0, -1)
	_pose(c, "lyra", "down")
	if is_instance_valid(gate):
		(gate as Node2D).visible = false
	c.music("ending", 2.0)
	await c.wait(1.0)
	await c.player_walk(17.0, 90.0)
	c.player_face(1)
	_pose(c, "lyra", "kneel")
	await c.say("lyra", "…따뜻해. 이게, 잠재우는 불이구나.", "weak")
	await c.say("lyra", "별빛이… 다 빠져나갔어. 이제 나, 그냥 할머니가 되겠네.", "aged")
	await c.say("sera", "…같이 내려가. 교장 선생님이 기다린대. 별 보면서.", "sad")
	await c.say("lyra", "꼬마 아스트리드가…? …응.", "happy")
	await c.say("lyra", "고마워, 세라피나. 나를 넘어 줘서. 그리고— 나를 데리러 와 줘서.", "sad")
	c.close_box()
	await c.narrate("하늘 아래, 거신들이 하나둘 무릎을 꿇고 잠들었다. 푸른 불이 그 위로 이불처럼 내려앉았다.")
	c.close_box()
	c.flag("st_gate_done")
	await c.fade_out(2.4, Color(1, 1, 1))
	_leave_all(c)
	c.letterbox(false)
	await c.goto_room("st_rebuild", "wake")


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


## 다시 세우기를 돕는 여섯 (돕지 않았으면 그 장면, 아니면 평소 대사)
func _rebuild_help(c: Cut, who: String) -> void:
	if not Quests.active("st_rebuild") or Quests.step("st_rebuild") != 0 or c.has("st_rb_" + who):
		await _epi_line(c, who)
		return
	match who:
		"pippa":
			await c.say("pippa", "세라! 이 물약 상자들 저쪽 천막까지 옮겨 줄래? 흔들면 안 돼. …터져.", "happy")
			await c.narrate("세라는 조심조심 상자를 옮겼다. 한 병이 퐁, 하고 연기를 뿜었다.")
			await c.say("pippa", "…괜찮아! 그건 원래 그래!", "smug")
		"butterworth":
			await c.say("butterworth", "일꾼들 점심이다! 이 솥 좀 같이 들자꾸나. 하나, 둘—", "happy")
			await c.narrate("국 냄새가 안뜰에 퍼졌다. 너울의 꼬리 아홉 개가 동시에 흔들렸다.")
		"hodu":
			await c.say("hodu", "호우. 호우우.")
			await c.narrate("호두가 그을린 책 더미를 가리킨다. 세라는 쓸 만한 책과 다시 써야 할 책을 나누어 쌓았다.")
			await c.say("hodu", "호우!", "happy")
		"isolde":
			await c.say("isolde", "얼음 벽돌로 임시 벽을 세우는 중이야. 녹지 않게… 네 불은 저쪽으로 하고.", "smug")
			await c.narrate("세라가 비켜서 있는 동안, 이졸데는 흠잡을 데 없는 얼음벽을 쌓았다.")
			await c.say("isolde", "…도와준 거 맞아. 비켜 준 것도 도운 거야.", "smug")
		"leonie":
			await c.say("leonie", "들보다. 한쪽을 들어라. 셋에.")
			await c.narrate("레오니가 반대쪽을 혼자 번쩍 들어 올렸다. 세라 쪽은… 거의 무게가 없었다.")
			await c.say("leonie", "나쁘지 않군.", "happy")
		"elarien":
			await c.say("elarien", "세계수의 묘목이다. 여기 심는다. 백 년 뒤엔 그늘이 된다.")
			await c.narrate("둘이서 작은 묘목을 심었다. 바람이 한 번, 잎을 흔들고 지나갔다.")
			await c.say("elarien", "…백 년 뒤에도 보러 와라.", "happy")
	c.close_box()
	c.flag("st_rb_" + who)
	var n := 0
	for w in REBUILD_HELP:
		if c.has("st_rb_" + w):
			n += 1
	Story.toast("다시 세우기 %d/6" % n, 1.8)
	if n >= REBUILD_HELP.size():
		c.quest_step("st_rebuild", 1)


func _epi_line(c: Cut, who: String) -> void:
	match who:
		"pippa": await c.say("pippa", "축제 다시 열면, 이번엔 별사탕 물약 진짜 맛있게 만들 거야!", "happy")
		"butterworth": await c.say("butterworth", "많이 먹으렴. 네 꼬리가 아홉 개라 그런지 너울이 세 그릇씩 먹더구나.", "happy")
		"hodu": await c.say("hodu", "호우.", "happy")
		"isolde": await c.say("isolde", "…세라. 다음 축제 무도회, 이번엔 끝까지 춰. 약속이야.", "smug")
		"leonie": await c.say("leonie", "제국도 다시 세우는 중이다. 카엘이 소시지 가게를 상설로 하자더군.", "happy")
		"elarien": await c.say("elarien", "세계수에 새잎이 났다. …보러 와라.", "happy")
		_: await c.say(who, "…", "happy")


func _pippa_epi(c: Cut) -> void:
	await _rebuild_help(c, "pippa")


# ═══════════════════════════════════════════════════════════
# 시험용 대본 (1단계): dev_ch5_portrait · poses · poses2 · poses_b · awaken · lyra · gate
# ═══════════════════════════════════════════════════════════

const LYRA_EXPRS := ["normal", "happy", "sad", "serious", "surprised", "possessed", "weak", "aged"]
const ASTRID_EXPRS := ["normal", "happy", "sad", "angry", "surprised", "tired", "wink"]
const NEOUL_EXPRS := ["normal", "angry", "sad", "gentle", "tearful", "awaken"]
const LYRA_POSES := ["idle", "run", "cast", "attack", "windup", "special", "guard", "hurt", "kneel", "down",
	"sword", "sword_windup", "sword_attack", "bow", "bow_draw", "bow_release", "spear", "spear_windup", "spear_charge", "possessed"]
const ASTRID_POSES := ["idle", "run", "cast", "attack", "windup", "shield", "hurt", "kneel", "down", "special"]


## 화면 위에 진열대를 하나 깐다 (방을 옮기면 사라짐)
func _gallery_layer(c: Cut, dim := 0.0) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 40
	c.world.room.add_child(layer)
	if dim > 0.0:
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.02, 0.05, dim)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.size = Vector2(640, 360)
		layer.add_child(bg)
	return layer


func _label(layer: CanvasLayer, text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0, 0.8))
	layer.add_child(l)


func dev_ch5_portrait(c: Cut) -> void:
	c.hud(false)
	var layer := _gallery_layer(c, 0.85)
	var rows := [["lyra", LYRA_EXPRS], ["astrid", ASTRID_EXPRS], ["neoul_god", NEOUL_EXPRS]]
	for ri in rows.size():
		var who: String = rows[ri][0]
		var exprs: Array = rows[ri][1]
		for i in exprs.size():
			var p := Portrait.new()
			p.position = Vector2(8 + i * 78, 14 + ri * 112)
			p.size = Vector2(72, 72)
			p.set_speaker(who, String(exprs[i]))
			layer.add_child(p)
			_label(layer, String(exprs[i]), p.position + Vector2(2, 74))
	await c.wait(0.2)


func dev_ch5_poses(c: Cut) -> void:
	await _lyra_page(c, 0)


func dev_ch5_poses2(c: Cut) -> void:
	await _lyra_page(c, 1)


## 리라 자세 10개씩 (5개 × 2줄, 2배 확대)
func _lyra_page(c: Cut, page: int) -> void:
	c.hud(false)
	var layer := _gallery_layer(c, 0.55)
	for k in 10:
		var i := page * 10 + k
		if i >= LYRA_POSES.size():
			break
		var v := CharacterVisual.new()
		v.setup("lyra")
		v.set_pose(String(LYRA_POSES[i]))
		v.position = Vector2(64 + (k % 5) * 128, 160 + (k / 5) * 178)
		v.scale = Vector2(2, 2)
		layer.add_child(v)
		_label(layer, String(LYRA_POSES[i]), v.position + Vector2(-30, 2))
	await c.wait(0.2)


func dev_ch5_poses_b(c: Cut) -> void:
	c.hud(false)
	var layer := _gallery_layer(c, 0.45)
	for i in ASTRID_POSES.size():
		var v := CharacterVisual.new()
		v.setup("astrid")
		v.set_pose(String(ASTRID_POSES[i]))
		v.position = Vector2(34 + i * 62, 140)
		v.scale = Vector2(2, 2)
		layer.add_child(v)
		_label(layer, String(ASTRID_POSES[i]), v.position + Vector2(-26, 4))
	# 실제 크기 (1배): 세라 키와 나란히 보는 용도
	var sample := ["idle", "cast", "sword_windup", "bow_draw", "spear_charge", "special", "kneel", "possessed"]
	for i in sample.size():
		var v2 := CharacterVisual.new()
		v2.setup("lyra")
		v2.set_pose(String(sample[i]))
		v2.position = Vector2(40 + i * 46, 300)
		layer.add_child(v2)
	for i in 4:
		var v3 := CharacterVisual.new()
		v3.setup("astrid")
		v3.set_pose(["idle", "cast", "shield", "special"][i])
		v3.position = Vector2(430 + i * 52, 300)
		layer.add_child(v3)
	await c.wait(0.2)


## 아홉 꼬리 각성 시험 (dev_st_void): 천을 걷고 → 각성 → 빛이 되어 세라에게
func dev_ch5_awaken(c: Cut) -> void:
	c.lock()
	var g := c.actor("neoul_god")
	if g == null:
		return
	g.set_talking(true)
	await c.wait(0.6)
	g.set_talking(false)
	g.unveil(true)
	await c.wait(1.6)
	await g.awaken()
	await c.wait(0.8)
	await g.merge_into(c.player.center(), 1.4)
	await c.wait(0.5)


## 리라 결전 대본 연결 예시 (dev_st_tower): 페이즈마다 전환을 붙잡고 짧은 대사를 넣은 뒤 resume()
func dev_ch5_lyra(c: Cut) -> void:
	c.release()
	var boss := c.spawn_enemy("lyra_boss", 30, 19, "lyra")
	if boss == null:
		return
	boss.set("hold_transition", true)
	boss.set("auto_lines", true)
	boss.phase_changed.connect(func(n: int) -> void:
		Story.toast("리라 — %d페이즈" % n, 1.6)
		await c.wait(1.2)
		if is_instance_valid(boss):
			boss.resume())
	boss.engaged = true
	await c.wait_enemy(boss)


## 하늘의 문 지원 연결 예시 (dev_st_sky): 동료 시스템 대신 support_needed에 바로 지원 함수를 잇는다
func dev_ch5_gate(c: Cut) -> void:
	c.release()
	var gate := c.spawn_enemy("sky_gate", 20, 10, "gate")
	if gate == null:
		return
	gate.support_needed.connect(_gate_support.bind(gate))
	gate.engaged = true
	await c.wait_enemy(gate)


## 하늘의 문이 지원을 청할 때 (동료 시스템이 들어오면 동료가 이 자리에서 special 연출 + 같은 함수를 부른다)
func _gate_support(kind: String, _pos: Vector2, gate: Node) -> void:
	if not is_instance_valid(gate):
		return
	match kind:
		"tendril", "hand":
			gate.cut_tendril()
		"eye":
			gate.snipe_eye()
		"veil":
			gate.holy_lance(5.0)
		"shield":
			gate.star_shield(3.0)
