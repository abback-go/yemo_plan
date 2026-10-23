extends "res://story/ch3/common.gd"
## 3장 대본 — 뿌리 동굴 · 줄기 시장(티엘) · 가지 마을·달샘 · 흰 역병의 숲(심장 정화).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


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
	if Cut.count(VALVES) >= 3:
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
	var p := c.player_tile()
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
