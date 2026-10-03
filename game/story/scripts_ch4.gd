extends "res://story/ch4/talk.gd"
## 4장 — 황금창의 수호자: 메인 이야기 대본 (docs/chapter4.md 2절·7.8절). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 인물 대화·서브 퀘스트는 story/ch4/talk.gd, 공용 도우미·개발용 대본은 story/ch4/base.gd (상속 사슬).
## 흐름: ch4_start(학교 앞마당) → 순례길 → 정문(tp_gate_scene) → 시련 셋 → 본당(tp_aurelia_talk) → 내전(tp_sanctum_scene)
##       → 첨탑 추격(tp_spire_*) → 꼭대기 결전(tp_boss) → 정화·리라(_boss_end) → 기숙사의 밤 → ChapterFlow.finish(c, 4)


# ═══════════════════════════════════════════════════════════
# 1. 학교 — 레오니가 오다, 교장이 길을 열다
# ═══════════════════════════════════════════════════════════

func ch4_start(c: Cut) -> void:
	c.lock()
	c.hud(true)
	await c.goto_room("s_courtyard", "yard")
	c.music("school_day", 1.0)
	var p := _ptile(c)
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
	var iso := _npc(c, "isolde")
	if iso:
		Fx.burst(iso.global_position + Vector2(0, -4), 24, {spread = 80.0, direction = Vector2.UP, speed_min = 20.0, speed_max = 60.0,
			lifetime = 0.9, gradient = Palette.fade_gradient(Color(0.7, 0.9, 1.0)), add = true})
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
	Fx.burst(circle, 40, {spread = 60.0, direction = Vector2.UP, speed_min = 40.0, speed_max = 140.0, lifetime = 1.0,
		gradient = Palette.fade_gradient(Color(0.85, 0.85, 1.0)), add = true})
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
	_pose(c, "aurelia", "cast")
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
	Fx.burst(hit_at, 24, {spread = 180.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(Color(1.0, 0.9, 0.6)), add = true})
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
	_pose(c, "aurelia", "idle")
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
	Fx.burst(Vector2(46 * 16 + 8, 19 * 16 - 20), 30, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(Color(1.0, 0.88, 0.5)), add = true})
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


## 시련을 처음 마친 순간: 아우렐리아가 소리 없이 지켜보고 있었다
func _aurelia_cameo(c: Cut, line: String) -> void:
	var p := _ptile(c)
	var room_w := c.world.room.size_px.x / 16.0
	var x := clampf(p.x - 6.0, 3.0, room_w - 3.0)
	c.flash(Color(1.0, 0.92, 0.7, 0.4), 0.3)
	c.spawn_npc("aurelia", x, p.y, 1)
	c.player_face(-1 if x < p.x else 1)
	await c.say("aurelia", line)
	await c.say("sera", "언제부터 거기 있었어?!", "surprised")
	await c.say("aurelia", "수호자는 시련을 지켜봅니다. 다음 시련에서는 우연이 통하지 않을 겁니다.")
	c.close_box()
	c.flash(Color(1.0, 0.92, 0.7, 0.4), 0.3)
	c.hide_actor("aurelia")
	await c.say("neoul", "…발소리도 없이. 저 계집, 사람이 맞긴 하느냐.")
	c.close_box()


# ═══════════════════════════════════════════════════════════
# 4. 시련 ① 빛의 거울
# ═══════════════════════════════════════════════════════════

func enter_tp_mirror_1(c: Cut) -> void:
	if c.has("tp_mirror1_seen") or c.has("tp_trial_mirror"):
		return
	c.flag("tp_mirror1_seen")
	c.lock()
	await c.wait(0.4)
	await c.camera_to(Vector2(60 * 16, 12 * 16), 0.9)
	await c.say("sera", "빛줄기가… 거울에 꺾여서 바닥으로 사라져.")
	await c.say("neoul", "저 위 수정에 빛을 닿게 하라는 게로구나. 거울은 손으로 돌리거나, 불기둥으로 두드려 돌릴 수 있겠다.")
	c.close_box()
	await c.camera_back(0.6)
	await c.teach("빛의 거울", "거울 앞에서 ↑ — 거울을 돌린다. 손이 닿지 않는 거울은 불기둥을 맞혀도 돌아간다.\n빛줄기가 수정에 닿으면 길이 열린다.", ["move_up"])


func enter_tp_mirror_3(c: Cut) -> void:
	if c.has("tp_mirror3_seen") or c.has("tp_trial_mirror"):
		return
	c.flag("tp_mirror3_seen")
	c.lock()
	await c.wait(0.4)
	await c.say("neoul", "빛이 저 눈에서 왼쪽으로만 흐르는구나. 수정은 오른쪽 위인데.")
	await c.say("sera", "'빛을 마주 보고, 불의 원으로 되돌려 보내라'… 석판에 그렇게 쓰여 있었어.")
	if Spells.learned("ward"):
		await c.say("neoul", "불꽃 방벽이니라. 빛줄기 속에 서서 빛이 오는 쪽을 보고 방벽을 펼치면, 빛이 네가 보는 쪽으로 튕겨 나갈 게다.")
		c.close_box()
		var key := "skill_1" if Spells.equipped("a") == "ward" else "skill_2"
		await c.teach("빛 되돌리기", "빛줄기 안에 서서, 빛이 오는 쪽을 바라보고 불꽃 방벽.\n빛이 세라가 바라보는 쪽으로 되돌아간다. (오른쪽 거울 둘도 먼저 맞춰 둘 것)\n방벽은 마법서에서 A·S 칸에 끼워 두어야 쓸 수 있다.", [key])
	else:
		await c.say("neoul", "…방벽을 아직 못 배웠느냐. 학교 실습장의 엠버린에게 배워 오거라. 회랑의 전이진으로 다녀올 수 있다.", "sad")
		c.close_box()


func tp_mirror_trial_done(c: Cut) -> void:
	c.lock()
	await c.wait(0.4)
	c.sfx("reveal")
	await c.say("sera", "됐다! 수정이 빛나!", "happy")
	c.close_box()
	var first := _trials_count() == 0
	await _trial_done(c, "tp_trial_mirror", "빛의 거울")
	if first:
		await _aurelia_cameo(c, "…빛의 길을 읽는군요. 우연이겠지요.")
	Story.toast("왼쪽 문으로 회랑에 바로 돌아갈 수 있다.", 2.6)


# ═══════════════════════════════════════════════════════════
# 5. 시련 ② 종탑
# ═══════════════════════════════════════════════════════════

func tp_bell_intro(c: Cut) -> void:
	if c.has("tp_bell_intro"):
		return
	c.flag("tp_bell_intro")
	c.lock()
	await c.say("sera", "종탑… 저 위에서 유령이 종을 치고 있어.", "surprised")
	await c.say("neoul", "종지기의 혼이로구나. 박자를 잃고 영원히 종을 치는 게지.")
	await c.say("neoul", "저 진짜 청동 종 — 불기둥으로 아래에서 쳐 보거라. 진짜 종소리엔 망령도 귀를 막을 게다.")
	c.close_box()
	await c.teach("진짜 종", "종 아래에서 불기둥 — 종이 울린다.\n가까운 종지기 망령은 귀를 막고 주저앉는다(그동안 받는 피해 1.5배).", ["skill_1"])


func tp_beat_intro(c: Cut) -> void:
	if c.has("tp_beat_intro") or c.has("tp_beat_done"):
		return
	c.flag("tp_beat_intro")
	c.lock()
	await c.say("sera", "종이 넷… 받침마다 문양이 달라. 달, 불꽃, 별, 여우.")
	await c.say("neoul", "위층 계단을 빛살이 막고 있구나. 정해진 차례로 쳐야 열리는 게지. 박자를 놓치면 처음부터일 게다.")
	await c.say("neoul", "…저 벽, 그림이 지워진 것 같지 않으냐? 여우창문으로 들여다보거라.")
	c.close_box()


func tp_beat_done(c: Cut) -> void:
	c.sfx("reveal")
	Story.toast("종소리가 맞았다! 위층 계단의 빛살이 걷혔다.", 2.6)
	c.bubble("…박자도 맞았구나. 제법이니라.", 2.6)


func tp_bell_trial_done(c: Cut) -> void:
	c.lock()
	await c.wait(0.8)
	for e in c.world.room.enemies:
		if is_instance_valid(e) and e is BellWraith and e.is_alive():
			e.take_hit(Hit.make(99999, &"bell", e.global_position + Vector2(0, -10)))
	await c.narrate("큰 종소리가 탑을 타고 산 아래까지 굴러갔다. 망령들이 귀를 막은 채… 고개를 숙이더니, 흩어졌다.")
	c.close_box()
	var first := _trials_count() == 0
	await _trial_done(c, "tp_trial_bell", "종탑")
	if c.actor("gregor"):
		c.face("gregor", 1 if c.player.global_position.x > _npc(c, "gregor").global_position.x else -1)
		await c.say("gregor", "누가 큰 종을 쳤어?! …아, 시련이로구먼! 잘했다, 아가씨! 소리가 맑다!", "happy")
		c.close_box()
	if first:
		await _aurelia_cameo(c, "…종이 당신을 받아들였군요. 종은 마음이 굽은 자에게 울리지 않습니다.")
	Story.toast("종탑 아래층에서 수도사 숙소로 가는 지름길 철창이 열렸다.", 3.0)


# ═══════════════════════════════════════════════════════════
# 6. 시련 ③ 기록실 — 백금 사도, 가장 오래된 기록 (tp_archive_read)
# ═══════════════════════════════════════════════════════════

func tp_archive_intro(c: Cut) -> void:
	if c.has("tp_archive_intro"):
		return
	c.flag("tp_archive_intro")
	c.lock()
	await c.say("sera", "어두워… 조각상이 잔뜩이야.")
	await c.say("neoul", "세라, 저 날개 달린 석상들 — 등을 보이지 말거라. 눈을 떼면 움직이는 놈들이니라.")
	await c.say("neoul", "마주 보고 있을 땐 돌이다. 화염탄은 튕겨 나겠지만… 발밑에서 솟는 불이라면 금이 갈 게다.")
	c.close_box()


func tp_herald_fight(c: Cut) -> void:
	if c.has("tp_herald_down"):
		return
	var h := c.enemy("gold_herald")
	if h == null:
		await _herald_end(c)
		return
	c.lock()
	if not c.has("tp_herald_met"):
		c.flag("tp_herald_met")
		await c.camera_to(h.global_position + Vector2(0, -20), 0.8)
		c.freeze_enemies(false)
		c.sfx("sky_crack", 2.0)
		c.shake(0.3, 0.8)
		await c.wait(0.8)
		c.freeze_enemies(true)
		await c.say("sera", "저건… 사람이 아니야. 금빛인데… 하얘.", "surprised")
		await c.say("neoul", "흰빛… 세계수에서 본 그 사도와 같은 냄새니라! 여기까지 와 있었구나.", "angry")
		await c.say("tp_voice", "…그릇… 별의… 그릇…")
		await c.say("sera", "또 그 말…!", "angry")
		await c.say("neoul", "거울판이 막는 쪽으로 쏘면 튕겨 나온다. 판 사이 틈을 노리거나, 튕겨 온 조각을 방벽으로 되쏘거라!")
		await c.say("neoul", "바닥에 내려앉을 때가 기회니라. 그땐 불기둥도 닿는다!")
		c.close_box()
		await c.camera_back(0.5)
	else:
		await c.say("neoul", "다시니라. 판 사이를 노려라.")
		c.close_box()
	c.music("herald", 0.5)
	c.flag("tp_herald_fight")
	c.save_here("record")
	h.engaged = true
	c.release()
	await c.wait_enemy(h, 0.5)
	if not c.ok():
		return
	if is_instance_valid(h) and h.is_alive():
		c.bubble("판이 빨라졌다! 안쪽이나 바깥으로 피하거라!", 2.6)
	await c.wait_enemy(h)
	if not c.ok():
		return
	await _herald_end(c)


func _herald_end(c: Cut) -> void:
	c.lock()
	c.flag("tp_herald_down")
	c.flag("tp_herald_fight", false)
	Music.stop(1.5)
	await c.wait(1.2)
	await c.say("sera", "하아… 사라졌어. 흰 조각이 되어서.")
	await c.say("neoul", "기록을 지키던 게 아니라… 먹고 있었던 게로구나. 저 오래된 책을.", "sad")
	c.close_box()
	c.music("temple_dark", 1.5)
	c.save_here("record")


func tp_archive_record(c: Cut) -> void:
	if not c.has("tp_herald_down"):
		await c.narrate("하얀 빛이 책을 감싸고 있다. 손을 대려 하자 차가운 기운에 손끝이 저렸다.")
		c.close_box()
		return
	if c.has("tp_archive_read"):
		await c.narrate("초대 대사제의 기록. 「…수호자여. 계시가 끊기는 날이 오거든, 대답하는 목소리를 믿지 말라.」")
		c.close_box()
		return
	c.lock()
	await c.narrate("가장 오래된 기록. 표지에 해 문양, 그 아래 초대 대사제의 이름이 새겨져 있다.")
	await c.narrate("「…빛의 주재는 영원하지 않다. 나는 그것을 별을 보다 알았다. 수백 년에 걸쳐, 아주 천천히, 그분의 빛이 엷어지고 있다.」")
	await c.narrate("「주재가 약해진 세계에는 하늘 바깥의 것들이 냄새를 맡고 온다. 얼굴 없는 흰 것들. 그들은 세계를 먹는다 — 관리자가 약한 세계부터.」")
	await c.narrate("「그들은 먼저 사도를 보내 길을 닦고, 그 세계에서 가장 강한 그릇을 문으로 삼아 들어온다.」")
	await c.narrate("「…수호자여. 계시가 끊기는 날이 오거든, 대답하는 목소리를 믿지 말라.」")
	await c.narrate("마지막 장에는 다른 손으로 쓴 짧은 메모가 덧붙어 있다.")
	await c.narrate("「재 속에서 다시 타오르는 불이 있다 했다. 마녀들의 창립자가 끝내 금서로 묶은 마지막 불 — 불사조.」")
	c.close_box()
	await c.say("sera", "…수백 년째 약해지고 있었다고? 루멘이?", "surprised")
	await c.say("neoul", "…그래서였구나. 세계수의 흰 역병도, 방금 그 흰 사도도.", "sad")
	await c.say("neoul", "'가장 강한 그릇을 문으로'… 세라, 이 기록은 잘 기억해 두거라.")
	await c.say("sera", "불사조… 학교 도서관 금서 구역에서 본 이름이야. 그레타 선생님이라면 알지도.")
	c.close_box()
	c.flag("tp_archive_read")
	var first := _trials_count() == 0
	await _trial_done(c, "tp_trial_archive", "기록실")
	Story.toast("학교 도서관의 그레타에게 금서 '불사조' 열람을 부탁할 수 있다. (수업 게시판)", 3.4)
	if first:
		await _aurelia_cameo(c, "…그 기록을 읽었군요. 수호자 말고는 아무도 읽지 않던 것을.")


# ═══════════════════════════════════════════════════════════
# 7. 본당 — 아우렐리아와의 대화 ("주께서 대답하지 않으십니다", "별빛이 섞였다")
# ═══════════════════════════════════════════════════════════

func npc_aurelia(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("aurelia", "세라 님. 다시 찾아 주셨군요.", "smile")
		await c.say("aurelia", "주께서는 여전히 침묵하십니다. 하지만 이제는… 침묵 속에서도 창을 들 수 있습니다.")
	elif c.has("tp_trials_done"):
		await tp_aurelia_talk(c)
		return
	else:
		var n := _trials_count()
		if n == 0:
			await c.say("aurelia", "기도 중입니다. 시련은 회랑에서 시작됩니다. 물러나십시오.")
		else:
			await c.say("aurelia", "%d개. …아직 끝나지 않았습니다." % n)
			await c.say("aurelia", "남은 것은 %s." % _trials_left())
	c.close_box()


func tp_aurelia_talk(c: Cut) -> void:
	if c.has("tp_aurelia_talk") or not c.has("tp_trials_done"):
		return
	c.lock()
	await c.player_walk(52.0, 70.0)
	c.player_face(1)
	_pose(c, "aurelia", "kneel")
	await c.wait(0.6)
	await c.say("aurelia", "…세 시련을 모두 마쳤군요.")
	_pose(c, "aurelia", "idle")
	c.face("aurelia", -1)
	await c.say("aurelia", "인정하겠습니다. 빛의 거울은 거짓을 비추지 않고, 큰 종은 마음이 굽은 자에게 울리지 않습니다.")
	await c.say("aurelia", "기록실의 것도… 읽었겠지요.")
	await c.say("sera", "루멘이 수백 년째 약해지고 있었다고.")
	await c.say("aurelia", "압니다. 수호자는 모두 압니다. 그래서 지켜 왔습니다. 더 단단히, 흔들리지 않게.")
	await c.wait(0.5)
	await c.say("aurelia", "…열흘 전부터, 주께서 대답하지 않으십니다.", "sad")
	await c.say("aurelia", "아침 기도에도, 저녁 기도에도. 계시가 끊겼습니다. 수호자가 된 뒤로 처음입니다.", "sad")
	await c.say("sera", "그래서 문을 닫은 거야?")
	await c.say("aurelia", "흔들리는 수호자를 순례자에게 보일 수는 없으니까요.")
	c.close_box()
	await c.walk("aurelia", 56.0, 40.0)
	await c.say("aurelia", "…잠깐.")
	c.emote("aurelia", "?")
	await c.say("aurelia", "당신의 마력. 붉은 불 속에… 별빛이 섞여 있습니다.", "surprised")
	await c.say("sera", "별빛?", "surprised")
	c.emote("neoul", "!")
	await c.say("neoul", "(……!)")
	await c.say("aurelia", "…착각이겠지요. 마녀의 불이니.")
	await c.say("aurelia", "오늘 밤, 내전의 제단에서 마지막 기도를 올리겠습니다. 수호자의 모든 빛을 바쳐서라도 주와의 연결을 되살리겠습니다.")
	await c.say("aurelia", "대사제님께서 당신도 증인으로 세우고 싶어 하십니다. 내전으로 오십시오. 제단 옆 계단입니다.")
	c.close_box()
	c.flash(Color(1.0, 0.92, 0.7, 0.35), 0.3)
	c.hide_actor("aurelia")
	await c.wait(0.5)
	var a := _leonie_join(c, 10.0, 19.0)
	await a.move_to(_ptile(c).x - 2.5)
	a.mode = "follow"
	await c.say("leonie", "세라. 끝났나.")
	await c.say("sera", "응. 오늘 밤 내전에서 아우렐리아가 마지막 기도를 올린대.")
	await c.say("leonie", "…나도 가겠다. 수도사들 말로는, 저 사람 열흘째 잠을 자지 않았다고 한다.")
	await c.say("neoul", "…세라. 아까 그 계집이 한 말. 별빛이라 했지.", "sad")
	await c.say("sera", "응. 무슨 뜻이야?")
	await c.say("neoul", "…아무것도 아니니라. 가자.")
	c.close_box()
	c.flag("tp_aurelia_talk")
	c.save()


# ═══════════════════════════════════════════════════════════
# 8. 내전 — 기도, 겹친 메아리, 폭주. 레오니가 대사제를 감싼다
# ═══════════════════════════════════════════════════════════

func tp_sanctum_scene(c: Cut) -> void:
	if c.has("tp_sanctum_berserk") or not c.has("tp_aurelia_talk"):
		return
	c.lock()
	var a := _leonie(c)
	if a == null:
		a = _leonie_join(c)
	a.mode = "script"
	await c.player_walk(44.0, 60.0)
	await a.move_to(41.0)
	a.facing = 1
	c.player_face(1)
	c.tint(Color(0.04, 0.05, 0.2, 0.3), 1.0)
	_pose(c, "aurelia", "kneel")
	await c.say("benedicta", "와 주었군요. 수호자의 기도는 대신전의 모든 빛을 한곳에 모아요. …조금 위험할 수도 있어요.")
	await c.say("aurelia", "빛의 주재여.")
	c.sfx("bell", -2.0)
	await c.say("aurelia", "당신의 수호자가 묻습니다. 어찌하여 침묵하십니까.")
	c.close_box()
	c.tint(Color(1.0, 0.85, 0.4, 0.18), 1.2)
	await c.wait(1.2)
	await c.say("aurelia", "…대답하소서.")
	c.close_box()
	await c.wait(1.2)
	c.shake(0.2, 0.8)
	await c.say("aurelia", "대답하소서!", "angry")
	c.close_box()
	Music.stop(0.5)
	await c.wait(1.4)
	c.flash(Color(1, 1, 1, 0.9), 0.4)
	c.sfx("sky_crack", 4.0)
	c.tint(Color(0.9, 0.92, 1.0, 0.22), 0.3)
	await c.say("tp_voice", "…대답… 하마…")
	c.emote("sera", "!")
	c.emote("benedicta", "!")
	await c.say("aurelia", "주…여?", "surprised")
	await c.say("tp_voice", "그릇… 빛의 그릇… 단단하구나… 아주… 단단해…")
	await c.say("tp_voice", "문이… 되어라…")
	await c.say("neoul", "아니다! 저건 루멘이 아니니라! 듣지 마라, 수호자!", "angry")
	await c.say("aurelia", "아… 아아……", "sad")
	c.close_box()
	# 광륜이 흰빛으로 금 가며 폭주
	var n := _npc(c, "aurelia")
	var pos := n.global_position if n else Vector2(63 * 16 + 8, 17 * 16)
	c.hide_actor("aurelia")
	var b := c.spawn_npc("aurelia_berserk", pos.x / 16.0 - 0.5, pos.y / 16.0, -1)
	b.visual.set_pose("berserk_kneel")
	c.sfx("holy_charge", 4.0)
	c.shake(0.6, 1.2)
	c.flash(Color(1, 1, 1, 1), 0.5)
	for i in 3:
		Fx.ring(pos + Vector2(0, -30), 6.0, 60.0 + i * 30.0, Color(1.0, 0.97, 0.9), 0.6, 3.0)
	Fx.burst(pos + Vector2(0, -30), 50, {spread = 180.0, speed_min = 60.0, speed_max = 220.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(Color(1.0, 0.95, 0.8)), add = true})
	await c.wait(1.0)
	b.visual.set_pose("berserk_idle")
	await c.say("aurelia_berserk", "물러—나—십시오.", "berserk")
	await c.say("aurelia_berserk", "빛을—더럽히는—모든—것을—", "berserk")
	await c.say("benedicta", "아우렐리아…!", "surprised")
	c.close_box()
	# 레오니가 대사제 앞으로 — 신성 돌진을 정면으로 받아낸다
	c.flash(Color(1, 1, 1, 0.5), 0.2)
	c.hide_actor("aurelia_berserk")
	a.global_position = Vector2(57 * 16 + 8, 17 * 16)
	a.velocity = Vector2.ZERO
	a.facing = 1
	a.set_pose("guard")
	await c.say("leonie", "대사제님, 뒤로!")
	c.close_box()
	var ch := _chaser(c)
	if ch:
		await ch.charge_at(17 * 16 - 18.0, -1, a, 0.9)
	c.shake(0.5, 0.5)
	await c.say("leonie", "크윽…!", "angry")
	await c.say("leonie", "세라! 대사제님은 내가 맡는다! 너는 위로 — 첨탑으로 도망쳐라!")
	await c.say("sera", "레오니! 혼자서는—", "surprised")
	await c.say("leonie", "가라! 지금의 우리로는 저걸 못 막는다! 위에서 버텨라, 곧 따라간다!")
	await c.say("neoul", "세라, 가자! 저 기사 계집은 쉽게 안 쓰러진다!")
	c.close_box()
	c.flag("tp_sanctum_berserk")
	c.sfx("crumble", 4.0)
	c.shake(0.4, 0.8)
	_leonie_leave(c)
	var ln := c.spawn_npc("leonie", 57.0, 17.0, 1)
	ln.visual.set_pose("guard")
	c.tint(Color(0, 0, 0, 0), 0.8)
	c.music("chase", 0.6)
	Story.toast("첨탑으로! 오른쪽 봉인 문이 부서졌다.", 2.6)


# ═══════════════════════════════════════════════════════════
# 9. 첨탑 추격 — 차오르는 금빛, 신성 돌진, 레오니가 받아내고, 교장이 별을 깐다
# ═══════════════════════════════════════════════════════════

func tp_spire1_enter(c: Cut) -> void:
	if c.has("tp_spire1_seen"):
		return
	c.flag("tp_spire1_seen")
	c.lock()
	await c.say("sera", "하아, 하아… 계단이 끝이 없어!", "surprised")
	await c.say("neoul", "아래를 보거라 — 금빛이 차오른다! 멈추면 잡힌다, 위로!", "angry")
	c.close_box()
	await c.teach("첨탑 추격", "멈추지 말고 위로! 아래에서 금빛이 차오른다.\n금빛 띠가 층을 가로지르면(예고) 다른 높이로 뛰거나 대시로 피한다.\n띠가 지나간 나무 발판은 부서진다.", ["jump"])


func tp_spire3_leonie(c: Cut) -> void:
	if c.has("tp_spire3_leonie"):
		return
	c.lock()
	var ch := _chaser(c)
	if ch:
		ch.set_paused(true)
		if ch.cstate != HolyChaser.C.NONE:
			await ch.charge_done
	var p := _ptile(c)
	var a := _leonie_join(c, 7.0, 35.0)
	a.mode = "script"
	await c.say("leonie", "세라!")
	c.player_face(-1)
	await c.say("sera", "레오니?! 대사제님은?", "surprised")
	await c.say("leonie", "수도사들에게 맡겼다. 무사하다.")
	await c.say("leonie", "…온다. 뒤로 물러서라.")
	c.close_box()
	await a.move_to(maxf(p.x + 6.0, 18.0))
	a.facing = 1
	a.set_pose("guard")
	c.player_face(1)
	if ch:
		await ch.charge_at(35 * 16 - 18.0, -1, a, 0.9)
	c.shake(0.6, 0.6)
	await c.say("leonie", "크으…! …이 정도는.", "angry")
	await c.say("leonie", "올라가라, 세라! 여기는 내가 막는다!")
	await c.say("sera", "같이 가!", "sad")
	await c.say("leonie", "빈민가에서 맨손으로 여기까지 왔다. 이 정도 돌진, 몇 번이고 받아 준다.")
	await c.say("leonie", "꼭대기에서 보자. …가라!")
	c.close_box()
	var lx := a.global_position.x / 16.0 - 0.5
	_leonie_leave(c)
	var ln := c.spawn_npc("leonie", lx, 35.0, 1)
	ln.visual.set_pose("guard")
	c.flag("tp_spire3_leonie")
	if ch:
		ch.set_paused(false)


func tp_spire4_astrid(c: Cut) -> void:
	if c.has("tp_star_steps"):
		return
	c.lock()
	var ch := _chaser(c)
	if ch:
		ch.set_paused(true)
	await c.camera_to(c.player.global_position + Vector2(90, -170), 0.9)
	await c.say("sera", "계단이… 통째로 없어! 위까지 너무 멀어!", "surprised")
	await c.say("neoul", "아래는 금빛, 위는 허공… 날개로도 저 높이는…", "sad")
	c.close_box()
	await c.camera_back(0.5)
	c.sfx("star_twinkle", 2.0)
	await c.wait(0.6)
	await c.say("astrid", "세라. 위를 보세요.")
	await c.say("sera", "교장 선생님?! 어디서—", "surprised")
	await c.say("astrid", "전이진에 남겨 둔 별 하나를 통해서요. 멀리서는 이 정도가 한계군요.")
	c.close_box()
	c.flag("tp_star_steps")
	c.sfx("star_burst", 2.0)
	c.flash(Color(0.75, 0.8, 1.0, 0.6), 0.6)
	await c.camera_to(c.player.global_position + Vector2(90, -150), 1.6)
	await c.wait(0.6)
	await c.say("astrid", "나머지는 당신 발로. …서두르세요. 금빛 아가씨가 화가 많이 났네요.", "happy")
	await c.say("neoul", "흥, 그 할망구… 별을 다 깔아 주는구나. 가자, 세라!", "happy")
	c.close_box()
	await c.camera_back(0.5)
	if ch:
		ch.set_paused(false)


func enter_tp_spire_top(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		return
	c.flag("tp_spire_top_reached")


# ═══════════════════════════════════════════════════════════
# 10. 꼭대기 결전 — 아우렐리아 (레오니 합류), 푸른 불의 정화, 리라
# ═══════════════════════════════════════════════════════════

func tp_boss(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		return
	var boss := c.enemy("aurelia_boss") as AureliaBoss
	if boss == null:
		return
	c.lock()
	if not c.has("tp_boss_met"):
		c.flag("tp_boss_met")
		Music.stop(1.0)
		c.sfx("wind", 0.0)
		await c.wait(0.6)
		await c.camera_to(boss.global_position + Vector2(-60, -50), 1.2)
		await c.say("sera", "꼭대기… 하늘이 열려 있어.", "surprised")
		c.sfx("holy_charge", 4.0)
		c.flash(Color(1.0, 0.95, 0.85, 0.7), 0.4)
		c.shake(0.4, 0.6)
		await c.say("aurelia_berserk", "도망—칠 곳은—없습니다.", "berserk")
		await c.say("aurelia", "…세라… 님… 피하십시오… 제 창이… 멈추지 않습니다…", "sad")
		await c.say("sera", "아우렐리아! 안에 아직 있구나!", "surprised")
		await c.say("neoul", "세라. 저 안의 흰 것만 태우면 된다. 푸른 불로. 그러려면 먼저 저 금빛을 꺾어야 하느니라.", "angry")
		await c.say("sera", "…알았어. 기다려, 아우렐리아. 꺼내 줄게.", "angry")
		c.close_box()
		await c.camera_back(0.6)
	else:
		await c.say("neoul", "다시 가자, 세라. 돌진은 예고 띠를 보고, 심판의 창은 기둥 뒤로!")
		c.close_box()
	c.music("aurelia", 0.5)
	c.flag("tp_boss_fight")
	c.save_here("start")
	boss.engaged = true
	c.release()
	# 2페이즈(66%): 레오니 합류
	await c.wait_until(func() -> bool: return not is_instance_valid(boss) or not boss.is_alive() or boss.phase >= 2, 1200.0)
	if not c.ok():
		return
	if is_instance_valid(boss) and boss.is_alive() and _leonie(c) == null:
		var a := _leonie_join(c, 3.0, 19.0)
		c.sfx("sword_slash", 2.0)
		a.say("기다렸지! 다리를 끊어 주마!", 3.0)
		c.bubble("기사 계집이 왔구나! 돌진이 오면 저 계집이 받아칠 게다!", 3.5)
	# 싸우는 동안: 돌진 예고가 보이면 레오니가 받아친다 (12초에 한 번)
	var cd := 2.0
	var shown3 := false
	while c.ok() and is_instance_valid(boss) and boss.is_alive():
		await c.world.get_tree().physics_frame
		cd -= c.world.get_physics_process_delta_time()
		var al := _leonie(c)
		if al and cd <= 0.0 and boss.charge_windup_active():
			al.special(boss)
			cd = 12.0
		if boss.phase >= 3 and not shown3:
			shown3 = true
			if al:
				al.say("흰빛이 짙어졌다! 조심해라, 세라!", 3.0)
			c.bubble("심판의 창이 오면 기둥 뒤, 파란 그늘로!", 3.2)
	if not c.ok():
		return
	await _boss_end(c, boss)


func _boss_end(c: Cut, boss: AureliaBoss) -> void:
	c.lock()
	c.flag("tp_aurelia_defeated")
	c.flag("tp_boss_fight", false)
	Music.stop(2.0)
	var a := _leonie(c)
	if a:
		a.mode = "script"
	await c.wait(1.6)
	var bpos := boss.global_position if is_instance_valid(boss) else Vector2(40 * 16, 19 * 16)
	await c.camera_to(bpos + Vector2(0, -30), 0.8)
	await c.say("tp_voice", "그릇이… 부서지지… 않는다… 놓지… 않는다…")
	await c.say("neoul", "지금이니라, 세라! 내 불을 쓰거라 — 푸른 불로, 저 흰 것만 태워라!", "angry")
	await c.say("sera", "응…!", "angry")
	c.close_box()
	# 푸른 불 (잠재우는 불): 바깥 신들의 연결만 태운다
	c.player_face(1 if bpos.x > c.player.global_position.x else -1)
	c.sfx("fox_transform", 2.0)
	for i in 3:
		Fx.ring(bpos + Vector2(0, -20), 6.0, 70.0 + i * 25.0, Color(0.5, 0.8, 1.0), 0.7, 3.0)
		Fx.burst(bpos + Vector2(0, -20), 40, {spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.9,
			gradient = Palette.fade_gradient(Color(0.55, 0.85, 1.0)), add = true})
		await c.wait(0.35)
	c.flash(Color(0.6, 0.85, 1.0, 0.9), 0.8)
	c.shake(0.5, 1.0)
	await c.say("tp_voice", "…아아… 또… 다른… 그릇이… 있으니…")
	c.close_box()
	if is_instance_valid(boss):
		boss.purify()
	c.tint(Color(0.05, 0.08, 0.25, 0.3), 1.5)
	await c.wait(1.5)
	if a:
		await a.move_to(bpos.x / 16.0 - 2.5)
		a.facing = 1
	await c.say("aurelia", "……", "sad")
	await c.say("aurelia", "…저는… 무엇을…", "surprised")
	await c.say("sera", "괜찮아? 흰 것한테 홀렸었어. 이제 다 태웠어.")
	await c.say("aurelia", "…기억납니다. 대답한 것은 주가 아니었습니다.", "sad")
	await c.say("aurelia", "저는 그 목소리에 기뻐했습니다. 열흘 만에 들린 대답이라고.", "sad")
	await c.say("aurelia", "흔들리지 않겠다고 서원한 수호자가, 가장 먼저 흔들렸습니다.", "sad")
	await c.say("sera", "…흔들린 게 나쁜 거야? 대답 없는 기도를 열흘이나 했잖아. 나 같으면 사흘 만에 그만뒀어.")
	await c.wait(0.4)
	await c.say("aurelia", "……")
	await c.say("aurelia", "…빛을 지킨 것은 당신이었습니다.", "smile")
	if a:
		await c.say("leonie", "…웃었다.", "surprised")
	await c.say("aurelia", "웃지 않겠다는 서원은… 오늘로 깨진 것 같군요.", "smile")
	await c.say("aurelia", "그 목소리. 기록에 있던 자들입니다. 천외(天外)의 신들 — 하늘 바깥에서, 빛이 약한 세계를 먹는 것들.")
	await c.say("aurelia", "그들은 저를 문으로 쓰려 했습니다. 그리고 제 안을 지나가며… 다른 이름을 불렀습니다.")
	await c.say("aurelia", "'별의 그릇'. 그리고 — '별의 마녀'.")
	c.emote("neoul", "!")
	await c.say("neoul", "…별의, 마녀.", "sad")
	c.close_box()
	# 달빛 아래 첨탑 끝 — 리라
	await c.wait(0.6)
	c.music("lyra", 1.5)
	c.sfx("star_twinkle", 2.0)
	var lyra_at := Vector2(40 * 16 + 8, 7 * 16)
	c.spawn_npc("lyra", 40.0, 7.0, -1)
	Fx.burst(lyra_at + Vector2(0, -16), 40, {spread = 180.0, speed_min = 20.0, speed_max = 90.0, lifetime = 1.2,
		gradient = Palette.fade_gradient(Color(0.85, 0.85, 1.0)), add = true})
	await c.camera_to(lyra_at + Vector2(0, -10), 1.4)
	await c.say("lyra", "어머. 다 끝나 버렸네.", "happy")
	await c.say("sera", "…누구?", "surprised")
	await c.say("lyra", "……")
	await c.say("lyra", "잘 자랐구나, 나의 별.", "happy")
	await c.say("neoul", "너… 네 이놈…! 그 별빛, 그 냄새… 너였느냐!", "angry")
	await c.say("lyra", "오랜만이야, 꼬마 여우님. 꼬리가 또 하나 돋으려나 보네? 귀여워라.", "happy")
	if is_instance_valid(boss):
		boss.pose("guard")
	await c.say("aurelia", "물러나십시오.", "angry")
	await c.say("lyra", "무서워라. 금빛 아가씨, 오늘은 인사만 하러 왔어.")
	await c.say("lyra", "세라피나. 조금만 더 자라렴. 너를 만나러 갈게. …곧.", "happy")
	c.close_box()
	c.sfx("star_burst", 2.0)
	c.flash(Color(0.8, 0.85, 1.0, 0.9), 0.6)
	Fx.burst(lyra_at + Vector2(0, -16), 60, {spread = 180.0, speed_min = 40.0, speed_max = 200.0, lifetime = 1.0,
		gradient = Palette.fade_gradient(Color(0.9, 0.9, 1.0)), add = true})
	c.hide_actor("lyra")
	await c.wait(1.0)
	await c.camera_back(0.8)
	await c.say("sera", "…나의 별…?", "sad")
	c.close_box()
	c.flag("tp_lyra_seen")
	if a:
		await c.say("leonie", "제국에 보고하러 돌아가겠다. …세라.")
		await c.say("leonie", "오늘, 나쁘지 않았다.", "happy")
	await c.say("aurelia", "세라 님. 대신전의 문은 이제 당신에게 닫히지 않습니다.", "smile")
	c.close_box()
	await c.fade_out(1.6)
	_leonie_leave(c)
	c.tint(Color(0, 0, 0, 0), 0.01)
	await c.narrate("그날 밤, 성산의 큰 종이 열흘 만에 울렸다.")
	await c.narrate("루멘은 여전히 침묵했지만, 수호자는 다시 창을 들었다.")
	c.close_box()
	await _dorm_night(c)


# ═══════════════════════════════════════════════════════════
# 11. 끝 — 기숙사의 밤 (짧게, 불안)
# ═══════════════════════════════════════════════════════════

func _dorm_night(c: Cut) -> void:
	await c.goto_room("s_dorm", "bed")
	c.lock()
	c.hud(false)
	Music.stop(0.5)
	c.tint(Color(0.02, 0.03, 0.12, 0.45), 0.01)
	c.player_face(1)
	await c.wait(0.5)
	await c.fade_in(2.0)
	await c.wait(0.6)
	await c.say("sera", "…너울. 자?")
	await c.say("neoul", "…자는 중이니라.")
	await c.say("sera", "리라라는 사람. 나를 '나의 별'이라고 불렀어. 나, 저 사람 몰라.", "sad")
	await c.say("neoul", "……")
	await c.say("neoul", "그 별빛… 네 마력 속에 섞인 그것과 같은 냄새였느니라.", "sad")
	await c.say("sera", "…무슨 뜻이야.")
	await c.say("neoul", "나도 모른다. 모르니까… 자거라. 내일 일은 내일 생각하자꾸나.")
	await c.wait(0.5)
	await c.say("neoul", "…세라. 오늘 푸른 불, 잘 썼다.")
	await c.say("sera", "…응.", "happy")
	c.close_box()
	await c.fade_out(2.0)
	c.tint(Color(0, 0, 0, 0), 0.01)
	c.save_here("bed")
	await ChapterFlow.finish(c, 4)
