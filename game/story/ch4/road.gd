extends "res://story/ch4/common.gd"
## 4장 대본 — 1~3. 학교(레오니가 오다) · 순례길 · 정문(아우렐리아가 막아서다).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 1. 학교 — 레오니가 오다, 교장이 길을 열다
# ═══════════════════════════════════════════════════════════

func ch4_start(c: Cut) -> void:
	c.lock()
	c.hud(true)
	await c.goto_room("s_courtyard", "yard")
	c.music("school_day", 1.0)
	var p := c.player_tile()
	var fy := p.y
	c.player_face(-1)
	c.spawn_npc("pippa", p.x - 3.0, fy, 1)
	c.spawn_npc("isolde", p.x + 4.5, fy, -1)
	c.spawn_npc("student_a", p.x - 11.0, fy, 1)
	c.spawn_npc("student_c", p.x - 13.5, fy, 1)
	await c.fade_in(1.0)
	await c.wait(0.4)
	await c.say("pippa", "세라, 세라! 들었어? 정문으로 제국 기사단장이 왔대!", "happy")
	await c.say("sera", "기사단장? …설마.", "surprised")
	c.close_box()
	c.sfx("crowd", -4.0)
	c.spawn_npc("leonie", 1.0, fy, 1)
	await c.walk("leonie", p.x - 16.0, 70.0)
	c.emote("student_a", "!")
	c.emote("student_c", "heart")
	await c.say("student_a", "진짜다! 은사자 기사단장, 레오니 발렌하르트!", "happy")
	await c.say("student_c", "제국제일검… 실물이 더 멋있어…", "happy")
	await c.say("leonie", "…길 좀 비켜 주겠나.")
	c.close_box()
	c.face("student_a", -1)
	c.face("student_c", -1)
	await c.walk("leonie", p.x - 2.5, 60.0)
	c.face("leonie", 1)
	c.player_face(-1)
	await c.say("leonie", "세라. 오랜만이다.")
	await c.say("sera", "레오니! 학교엔 웬일이야?", "happy")
	c.emote("isolde", "!")
	await c.say("isolde", "(레, 레오니 발렌하르트 경…! 저 애는 왜 반말을…?!)", "surprised")
	await c.say("leonie", "…크레스트 가문의 딸이군. 서리 마법이 뛰어나다고 들었다.")
	c.emote("isolde", "sweat")
	await c.say("isolde", "가, 감, 감사…", "surprised")
	c.close_box()
	var iso := c.npc("isolde")
	if iso:
		c.burst(iso.global_position + Vector2(0, -4), 24, Color(0.7, 0.9, 1.0),
			{spread = 80.0, direction = Vector2.UP, speed_min = 20.0, speed_max = 60.0, lifetime = 0.9})
	await c.narrate("이졸데가 그 자리에서 얼어붙었다. 말 그대로 — 발밑에 서리가 피었다.")
	await c.say("pippa", "단장님! 사, 사인해 주세요! 여기, 실험 노트에!", "happy")
	await c.say("leonie", "…연금술 노트에 사인하는 건 처음이다.")
	c.sfx("pickup")
	await c.say("pippa", "꺄아! 가보로 삼을 거야!", "happy")
	await c.say("leonie", "놀러 온 건 아니다. 제국 예배당의 빛이 꺼졌다. 루멘의 성화가 사흘째 타지 않는다.", "sad")
	await c.say("leonie", "그리고 성산의 대신전이 문을 닫았다. 순례자도, 황제의 사절도 들이지 않는다.")
	await c.say("sera", "루멘이면… 빛의 신?")
	await c.say("neoul", "이 세계를 돌보는 큰 신이니라. 나 같은 산신과는 격이 다르지. …흥, 인정하기는 싫다만.")
	c.close_box()
	# 교장 등장 (학교 정문 계단 위에서 내려옴)
	c.sfx("star_twinkle", 0.0)
	c.spawn_npc("astrid", 40.0, 16.0, -1)
	await c.say("astrid", "그래서 제가 레오니 경을 불렀답니다.")
	c.close_box()
	await c.move("astrid", p.x + 2.5, fy, 1.2)
	c.player_face(1)
	await c.say("astrid", "세계수의 흰 역병, 그다음은 루멘의 침묵. 우연이라 하기엔 너무 가깝지요.")
	await c.say("astrid", "대신전은 마녀를 들이지 않습니다. 그러니…")
	await c.say("astrid", "마녀 한 명쯤 데려가 보는 것도 재미있지 않겠어요? 제국제일검이 곁에 있다면 문 앞에서 쫓겨나지는 않을 테니.", "happy")
	await c.say("sera", "교장 선생님, 그거 그냥 저를 들이밀어 보는 거잖아요!", "angry")
	await c.say("astrid", "…라고 해 두죠.", "happy")
	await c.say("leonie", "성산까지는 걸어서 열흘이다.")
	await c.say("astrid", "그 길은 제가 열어 드리죠.")
	c.close_box()
	await c.walk("astrid", 26.0, 50.0)
	c.face("astrid", -1)
	var circle := Vector2(24 * 16 + 8, 19 * 16 - 4)
	c.sfx("star_burst", 0.0)
	for i in 3:
		Fx.ring(circle, 4.0, 40.0 + i * 16.0, Color(0.75, 0.7, 1.0), 0.6, 2.0)
	c.burst(circle, 40, Color(0.85, 0.85, 1.0), {spread = 60.0, direction = Vector2.UP, speed_min = 40.0, speed_max = 140.0, lifetime = 1.0})
	c.flash(Color(0.8, 0.75, 1.0, 0.4), 0.4)
	await c.wait(0.8)
	await c.narrate("교장이 지팡이 끝으로 전이진을 두드리자, 보랏빛 마법진 위에 별자리 하나가 새로 그려졌다.")
	await c.narrate("…그 손끝이, 아주 조금 떨렸다.")
	await c.say("astrid", "성산 순례길 입구로 이어 두었어요. 돌아올 때도 이 길로 오세요.")
	await c.say("pippa", "세라! 가는 김에 성수 좀 떠다 줘! 빛이 녹아 있는 물이라니, 연금술사의 꿈이야!", "happy")
	c.quest_start("tp_pippa_water")
	await c.say("pippa", "아, 그리고 버터워스 아주머니가 눈꽃 약초도 부탁하셨어! 성산에만 핀대!")
	c.quest_start("tp_herbs")
	await c.say("neoul", "성산이라… 남의 신 집에 쳐들어가는 셈이니라. 세라, 예의는 지키거라.")
	await c.say("sera", "너나 잘해.")
	c.close_box()
	await c.player_walk(24.0, 80.0)
	c.sfx("warp", 2.0)
	c.flash(Color(0.85, 0.8, 1.0, 0.9), 0.6)
	await c.fade_out(0.6, Color(0.92, 0.9, 1.0))
	await c.goto_room("tp_road", "warp")
	await _arrive_road(c)


## 순례길 첫 도착: 전이진 해금, 레오니 동행, 산 풍경
func _arrive_road(c: Cut) -> void:
	c.warp_unlock("temple")
	c.flag("tp_arrived")
	c.lock()
	c.hud(true)
	c.music("temple", 1.5)
	c.player_face(1)
	_leonie_join(c)
	await c.fade_in(1.2)
	c.sfx("wind", -4.0)
	await c.wait(0.4)
	await c.camera_to(c.player.global_position + Vector2(200, -90), 1.4)
	await c.say("sera", "우와… 눈이다! 저 산꼭대기에 반짝이는 게 대신전?", "surprised")
	await c.say("leonie", "루멘 대신전. 이 대륙에서 하늘과 가장 가까운 집이다.")
	await c.camera_back(0.8)
	await c.say("leonie", "…춥군.")
	await c.say("neoul", "기사 계집이 추위를 다 타는구나. 내 털이라도 빌려주랴?")
	await c.say("leonie", "됐다.")
	c.close_box()
	await c.title_card("성산 순례길", "루멘 대신전 가는 길", 2.2)
	c.save()


func enter_tp_road(c: Cut) -> void:
	if Story.busy_count() > 1 or c.has("tp_arrived") or not c.has("ch3_done"):
		return
	await _arrive_road(c)


# ═══════════════════════════════════════════════════════════
# 2. 순례길
# ═══════════════════════════════════════════════════════════

## 산길에서: 레오니가 루멘을 믿는 이유 (빈민가 예배당의 수프) + 잃어버린 배지
func tp_road1_talk(c: Cut) -> void:
	if c.has("tp_road1_talk") or _leonie(c) == null:
		return
	c.flag("tp_road1_talk")
	c.lock()
	await c.say("sera", "레오니는 루멘을 믿어?")
	await c.say("leonie", "믿는다.")
	await c.say("sera", "…의외다. 검밖에 안 믿을 줄 알았는데.")
	await c.say("leonie", "어렸을 때, 빈민가 예배당에서 매일 저녁 수프를 줬다.")
	await c.say("leonie", "신부님은 우리가 기도를 하든 말든 그릇을 채워 줬지. 마력도 없고 쓸모도 없다는 소리만 듣던 애한테도.")
	await c.say("leonie", "빛은 쓸모를 묻지 않는다고 했다. …그 말 하나로 여기까지 왔다.")
	await c.say("sera", "…좋은 사람이었네.", "sad")
	await c.say("leonie", "그분을 따라 이 길을 오른 적이 있다. 열 살 때. 눈보라를 만나 벼랑길 위 동굴에서 하룻밤을 보냈지.")
	await c.say("leonie", "그때 견습 기사 배지를 잃어버렸다. 신부님이 양철로 만들어 준 가짜였지만.")
	await c.say("neoul", "흥, 찾아 주면 되지 않느냐. 벼랑길 위라면 금방이니라.")
	await c.say("leonie", "이십 년 전 일이다. 신경 쓰지 마라.")
	await c.say("sera", "(…벼랑길 위, 동굴. 기억해 둬야지.)")
	c.close_box()
	c.quest_start("tp_leonie_badge")
	c.bubble("바위 틈이 수상하거든 여우창문으로 보거라.", 3.0)


## 바람의 능선: 끊긴 다리 — 불꽃 날개
func tp_road3_glide(c: Cut) -> void:
	if c.has("tp_road3_glide"):
		return
	c.flag("tp_road3_glide")
	c.lock()
	await c.say("sera", "다리가… 끊겼어.", "surprised")
	await _leonie_say(c, "돌아가는 길을 찾아야겠군.")
	if Spells.learned("wings"):
		await c.say("sera", "아니, 날아서 건너면 돼!", "happy")
		await _leonie_say(c, "…날아서?", "surprised")
		await c.say("neoul", "불꽃 날개니라. 높은 턱에서 뛰어 날개를 펴면 바람이 받아 준다. 아래에서 솟는 바람을 타면 더 높이도.")
		await _leonie_say(c, "…나는 알아서 건너겠다. 먼저 가라.")
		c.close_box()
		await c.teach("활공", "공중에서 점프를 다시 길게 누르면 불꽃 날개로 활공한다.\n위로 부는 바람 안에서 활공하면 높이 솟아오른다.", ["jump"])
	else:
		await c.say("neoul", "…날개가 없으면 못 건너겠구나. 학교의 오필리아에게 불꽃 날개를 배워 오거라.", "sad")
		c.close_box()


## 순례자 쉼터
func tp_hut_scene(c: Cut) -> void:
	if c.has("tp_hut_seen"):
		return
	c.flag("tp_hut_seen")
	c.lock()
	await c.player_walk(10.0, 70.0)
	await c.say("tp_anselm", "어서 오시오. 이런 날씨에 순례라니, 신심이 깊구려.")
	await _leonie_say(c, "은사자 기사단장 레오니다. 대신전에 무슨 일이 있는가.")
	await c.say("tp_anselm", "…열흘 전부터 정문이 닫혔소. 수호자님이 아무도 들이지 않으시오.", "sad")
	await c.say("tp_pilgrim_b", "밤마다 길 잃은 순례자들이 하얗게 변해서 돌아다녀요. 빛이 안 보인다고 중얼거리면서…", "sad")
	await c.say("tp_anselm", "수호자 아우렐리아 님은 대신전의 창이오. 열 살에 서원하고 스무 해, 단 한 번도 흔들린 적이 없는 분이지.")
	await c.say("tp_anselm", "그런 분이 문을 닫았다면… 산 위에 무언가 있는 게요.")
	await c.say("sera", "(…흔들린 적 없는 수호자.)")
	await c.say("neoul", "세라, 저 화롯가에서 몸을 녹이고 가자꾸나. 내 꼬리가 얼어붙겠다.")
	c.close_box()
	c.save()


## 대신전 오르막: 빛의 감시안 첫 만남
func tp_road4_eyes(c: Cut) -> void:
	if c.has("tp_eyes_seen"):
		return
	c.flag("tp_eyes_seen")
	c.lock()
	var e := c.enemy("lumen_eye")
	if e:
		await c.camera_to(e.global_position + Vector2(0, -10), 0.7)
	await c.say("sera", "저건… 눈? 하늘에 떠 있는 금빛 눈!", "surprised")
	await c.say("neoul", "대신전의 파수꾼이로구나. 붉은 선이 그어지면 빛줄기가 그 사이를 쓸고 지나간다. 선 밖으로 피하거라.")
	await _leonie_say(c, "순례자를 쏘는 파수꾼이라니. …신전이 정말 이상해졌군.")
	c.close_box()
	if e:
		await c.camera_back(0.5)


# ═══════════════════════════════════════════════════════════
# 3. 정문 — 아우렐리아가 막아서다 (두 손가락), 베네딕타의 중재
# ═══════════════════════════════════════════════════════════

func tp_gate_scene(c: Cut) -> void:
	if c.has("tp_gate_scene"):
		return
	c.lock()
	var a := _leonie(c)
	if a == null:
		a = _leonie_join(c)
	a.mode = "script"
	await c.player_walk(36.0, 70.0)
	await a.move_to(39.0)
	a.facing = 1
	c.player_face(1)
	await c.say("leonie", "제국 은사자 기사단장 레오니 발렌하르트다. 문을 열어라.")
	c.close_box()
	Music.stop(1.0)
	await c.wait(1.0)
	c.sfx("door", 4.0)
	c.shake(0.15, 0.8)
	c.flash(Color(1.0, 0.92, 0.7, 0.7), 0.6)
	c.spawn_npc("aurelia", 64.0, 16.0, -1)
	c.music("aurelia", 1.0)
	await c.camera_to(Vector2(56 * 16, 12 * 16), 0.9)
	await c.walk("aurelia", 54.0, 40.0)
	await c.say("aurelia", "대신전은 지금 순례를 받지 않습니다. 돌아가십시오.")
	await c.say("leonie", "제국 예배당의 빛이 꺼졌다. 수호자에게 이유를 들어야겠다.")
	await c.say("aurelia", "빛의 일은 빛의 집이 답합니다. 제국의 검이 물을 일이 아닙니다.")
	await c.wait(0.3)
	await c.say("aurelia", "…그리고, 그 뒤의 것.")
	c.emote("sera", "!")
	await c.say("aurelia", "이단의 마녀는 들어올 수 없습니다. 물러나십시오.", "angry")
	await c.say("sera", "이단?! 나 그냥 마녀학교 학생인데!", "angry")
	await c.say("neoul", "…세라. 저 계집, 금빛이 보통이 아니니라.")
	c.close_box()
	await c.camera_back(0.5)
	await c.say("leonie", "이 아이는 내 동행이다. 길을 비켜라.")
	await c.say("aurelia", "물러나십시오. 세 번 말하지 않습니다.")
	c.close_box()
	# 레오니가 검을 뽑아 단숨에 좁혀 들고 — 아우렐리아가 금빛 걸음으로 내려와 두 손가락으로 칼날을 집는다
	a.set_pose("attack")
	c.sfx("sword_slash", 2.0)
	c.flash(Color(1.0, 0.95, 0.75, 0.6), 0.15)
	await c.move("aurelia", 46.0, 19.0, 0.12)
	c.pose("aurelia", "cast")
	var tw := a.create_tween()
	tw.tween_property(a, "global_position:x", 44.0 * 16.0 - 2.0, 0.12)
	await tw.finished
	c.sfx("sword_clash", 4.0)
	c.sfx("parry", 2.0)
	Fx.hitstop(0.25)
	c.shake(0.5, 0.4)
	c.flash(Color(1.0, 0.95, 0.8, 0.8), 0.2)
	var hit_at := Vector2(45 * 16, 19 * 16 - 22)
	Fx.ring(hit_at, 4.0, 46.0, Color(1.0, 0.9, 0.6), 0.4, 3.0)
	c.burst(hit_at, 24, Color(1.0, 0.9, 0.6), {spread = 180.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.4})
	c.zoom(1.6, 0.3)
	await c.wait(0.7)
	await c.narrate("검끝이 멈췄다. 아우렐리아가 두 손가락으로 칼날을 집고 있었다.")
	await c.say("leonie", "…!", "surprised")
	await c.say("aurelia", "제국제일검. 듣던 대로 곧은 검입니다.")
	await c.say("aurelia", "그러나 곧은 검은 막기도 쉽습니다.")
	await c.say("leonie", "…두 손가락으로.", "angry")
	await c.say("sera", "레오니의 검을… 손가락으로?!", "surprised")
	await c.say("neoul", "세라. 저 계집과는 싸우지 말거라. 지금의 너로는 못 이긴다.", "sad")
	c.close_box()
	c.zoom(1.0, 0.5)
	# 베네딕타
	c.spawn_npc("benedicta", 64.0, 16.0, -1)
	c.sfx("bell_small", 0.0)
	await c.say("benedicta", "아우렐리아. 그만두렴.")
	c.pose("aurelia", "idle")
	c.face("aurelia", 1)
	a.set_pose("idle")
	await c.say("aurelia", "대사제님. 하지만—")
	c.close_box()
	await c.walk("benedicta", 52.0, 30.0)
	await c.say("benedicta", "루멘께서 침묵하신 지 열흘이란다. 우리끼리는 답을 찾지 못했지.", "sad")
	c.face("aurelia", -1)
	await c.say("benedicta", "…마녀님, 이름이?")
	await c.say("sera", "세라. 세라피나예요.")
	await c.say("benedicta", "세라 양. 대신전에는 오래된 규칙이 있어요. 빛의 집에 들고자 하는 이는 '자격의 시련'을 치러야 하지요.")
	await c.say("benedicta", "빛의 거울, 종탑, 그리고 기록실. 세 시련을 마치면, 수호자도 당신을 막지 않을 거예요.")
	await c.say("aurelia", "…대사제님의 뜻이라면.")
	await c.say("aurelia", "다만 시련은 마녀 혼자 치르십시오. 기사단장께서는 회랑에서 기다리시고.")
	await c.say("leonie", "…세라. 할 수 있겠나.")
	await c.say("sera", "당연하지. 시련이든 뭐든!", "happy")
	await c.say("aurelia", "빛은 거짓을 비추지 않습니다. 그것만 기억하십시오.")
	c.close_box()
	c.flag("tp_gate_open")
	c.sfx("door", 4.0)
	c.shake(0.3, 1.0)
	c.flash(Color(1.0, 0.9, 0.6, 0.5), 0.6)
	await c.wait(0.3)
	c.hide_actor("aurelia")
	c.burst(Vector2(46 * 16 + 8, 19 * 16 - 20), 30, Color(1.0, 0.88, 0.5),
		{spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.6})
	await c.wait(0.5)
	await c.say("benedicta", "회랑에서 기다리겠어요. 천천히 오세요.", "happy")
	c.close_box()
	c.hide_actor("benedicta")
	await c.say("leonie", "먼저 들어가 있겠다. …시련, 무리하지 마라.")
	c.close_box()
	_leonie_leave(c)
	c.flag("tp_gate_scene")
	c.music("temple", 1.5)
	Story.toast("대신전 정문이 열렸다. 다음부터는 순례길 입구로 내려가는 지름길 계단을 쓸 수 있다.", 3.2)
	c.save()


## 회랑 첫 방문
func enter_tp_cloister(c: Cut) -> void:
	if not c.has("tp_gate_scene") or c.has("tp_cloister_seen"):
		return
	c.flag("tp_cloister_seen")
	await c.wait(0.8)
	c.bubble("회랑이로구나. 시련은 셋 — 왼쪽 거울, 정원 너머 종탑, 아래 기록실이니라.", 4.0)
	await c.wait(1.0)
	Story.toast("회랑의 전이진으로 학교에 다녀올 수 있다. (피피의 성수 · 버터워스의 약초)", 3.4)
