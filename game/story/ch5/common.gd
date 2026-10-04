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
## 이 파일: 5장 대본 파일들이 함께 쓰는 상수·도우미 (장면 파일이 모두 extends). 대본(공개 메서드)은 두지 말 것 —
## 파일마다 같은 ID가 생겨 Story가 오류를 낸다. 대본 목록은 story/data_ch5.gd SCRIPTS.


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
	return Fx.now_ms() / 1000.0


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
