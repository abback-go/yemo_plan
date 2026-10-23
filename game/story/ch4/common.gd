extends RefCounted
## 4장 대본 — 황금창의 수호자 (docs/archive/sera/chapter4.md 2절·6절·7.7~7.8절). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 흐름: ch4_start(학교 앞마당) → 순례길 → 정문(tp_gate_scene) → 시련 셋 → 본당(tp_aurelia_talk) → 내전(tp_sanctum_scene)
##       → 첨탑 추격(tp_spire_*) → 꼭대기 결전(tp_boss) → 정화·리라(_boss_end) → 기숙사의 밤 → ChapterFlow.finish(c, 4)
## 말투(docs/archive/sera/bible/characters.md): 베네딕타 온화한 존댓말 · 루카 수줍은 존댓말 · 그레고르 귀가 어두워 크게("!") ·
## 엘사(성가대) 조용한 존댓말 · 안셀름 느긋한 하오체 · 순례자들 하오체/해요체 · 레오니 짧고 단정한 반말 · 아우렐리아 차가운 존댓말.
## 이 파일: 4장 대본 파일들이 함께 쓰는 상수·도우미 (장면 파일이 모두 extends). 대본(공개 메서드)은 두지 말 것 —
## 파일마다 같은 ID가 생겨 Story가 오류를 낸다. 대본 목록은 story/data_ch4.gd SCRIPTS.


const T := 16.0
const HolyChaser := preload("res://world/entities/ch4/holy_chaser.gd")


# ─── 공용 도우미 ─────────────────────────────────────────

func _leonie(c: Cut) -> Ally:
	return c.ally("leonie")


## 레오니 동행 시작 (tp_leonie_on — 방 장치 tp_ally가 저장·부활 뒤에도 다시 불러 줌)
func _leonie_join(c: Cut, x_t := INF, y_t := INF) -> Ally:
	c.flag("tp_leonie_on")
	var a := c.ally_join("leonie", x_t, y_t)
	a.mode = "follow"
	return a


func _leonie_leave(c: Cut) -> void:
	c.flag("tp_leonie_on", false)
	c.ally_leave("leonie")


## 레오니가 곁에 있으면 대사창으로, 없으면 아무것도 하지 않음
func _leonie_say(c: Cut, text: String, expr := "normal") -> void:
	if _leonie(c):
		await c.say("leonie", text, expr)


func _chaser(c: Cut) -> HolyChaser:
	return c.actor("holy_chaser") as HolyChaser


func _trials_count() -> int:
	return Cut.count(["tp_trial_mirror", "tp_trial_bell", "tp_trial_archive"])


## 이름 순서대로 남은 시련
func _trials_left() -> String:
	var out: Array[String] = []
	if not GameState.has_flag("tp_trial_mirror"):
		out.append("빛의 거울(회랑 왼쪽)")
	if not GameState.has_flag("tp_trial_bell"):
		out.append("종탑(정원 → 성가대석 너머)")
	if not GameState.has_flag("tp_trial_archive"):
		out.append("기록실(회랑 아래)")
	return ", ".join(out)


## 시련 하나를 마침: 플래그·알림. 셋을 다 마치면 tp_trials_done
func _trial_done(c: Cut, key: String, title: String) -> void:
	c.flag(key)
	var n := _trials_count()
	c.sfx("quest_done")
	c.flash(Color(1.0, 0.9, 0.6, 0.35), 0.5)
	await c.title_card("자격의 시련 — " + title, "%d / 3" % n, 2.2)
	if n >= 3:
		c.flag("tp_trials_done")
		Story.toast("세 시련을 모두 마쳤다. 본당의 아우렐리아에게 가자.", 3.2)
	else:
		Story.toast("남은 시련: " + _trials_left(), 3.2)


## 기도 촛불 (tp_candles) 켠 수
func _candles_lit() -> int:
	return Cut.count(["tp_candle_1", "tp_candle_2", "tp_candle_3", "tp_candle_4", "tp_candle_5"])


## 시련을 처음 마친 순간: 아우렐리아가 소리 없이 지켜보고 있었다
func _aurelia_cameo(c: Cut, line: String) -> void:
	var p := c.player_tile()
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
