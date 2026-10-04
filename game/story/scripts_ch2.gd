extends RefCounted
## 2장 대본 — 제국의 검 (docs/chapter2.md 2절 줄거리 · 7.5절 대본 목록). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 흐름: ch2_start(기숙사) → 아침 → 날개 수업(공통) → 교장실 사자 → 출발 → 시장 습격(레오니) → 대련 → 성벽 대화 →
##       지붕 → 시계 구역(톱니 시계) → 시계탑 → 지하 묘지(별 수정 장벽 → 방벽 수업) → 하수도 → 녹시스 → 밤의 결투 →
##       레오니와 함께 운석수 → 공관 작별 → 기숙사의 밤 → ChapterFlow.finish(c, 2)
## 말투: 레오니 짧고 단정("~다.", "나쁘지 않군.") · 카엘 수다·허당 · 미아 신난 아이 · 브론 무뚝뚝 · 녹시스 공손한 광신 ·
##       이졸데 차갑다가 츤데레 · 피피 하이텐션 · 엠버린 따뜻하고 엄격 · 너울 고어체("~니라", "~하거라")
## 이야기 트리거는 모두 once=False — 대본이 첫 줄에서 플래그로 지킨다(싸우다 쓰러져도 다시 걸리게).

const KE := preload("res://enemies/ch2/k_enemy.gd")
const RACE_LIMIT := 120.0 ## 이졸데 지붕 경주 제한 시간(초)


# ═══════════════════════════════════════════════════════════
# 도우미
# ═══════════════════════════════════════════════════════════

func _room(c: Cut) -> String:
	return c.world.room.data.id if c.world.room else ""


## 잔상 하나 (레오니의 순간 거리 좁히기)
func _ghost(who: String, pos: Vector2, facing: int, p: String, alpha: float) -> void:
	var holder := Node2D.new()
	holder.scale.x = float(facing)
	var v := CharacterVisual.new()
	v.setup(who)
	holder.add_child(v)
	Fx.effect_parent().add_child(holder)
	holder.global_position = pos
	v.set_pose(p)
	holder.modulate = Color(1.0, 0.75, 0.8, alpha)
	var tw := holder.create_tween()
	tw.tween_property(holder, "modulate:a", 0.0, 0.5)
	tw.tween_callback(holder.queue_free)


## 인물이 잔상을 남기며 to_x(타일)까지 순간 이동
func _flash_step(c: Cut, who: String, to_x: float) -> void:
	var n := c.actor(who) as Npc
	if n == null:
		return
	var from := n.global_position
	var to := Vector2(to_x * 16.0 + 8.0, from.y)
	var dir := 1 if to.x >= from.x else -1
	n.face(dir)
	n.visual.set_pose("charge")
	c.sfx("dash", 2.0)
	for i in 3:
		_ghost(who, from.lerp(to, float(i) / 3.0), dir, "charge", 0.6 - float(i) * 0.12)
	n.global_position = to
	n.visual.set_pose("attack")
	await c.wait(0.05)


func _ensure_leonie(c: Cut) -> Ally:
	if not c.has("k_duel_done") or c.has("k_beast_down"):
		return null
	return c.ensure_ally("leonie")


## 약한 참조의 적이 사라졌거나 쓰러졌는가 (람다가 지워진 노드를 붙잡지 않게)
func _dead(ref: WeakRef) -> bool:
	var e := ref.get_ref() as EnemyBase
	return e == null or not e.is_alive()


## 약한 참조의 노드가 사라졌거나, 그 속성(문자열)이 비어 있지 않은가
func _gone_or(ref: WeakRef, prop: String) -> bool:
	var n := ref.get_ref() as Node
	return n == null or String(n.get(prop)) != ""


func _book_count() -> int:
	return Cut.count(["k_book_1", "k_book_2", "k_book_3"])


func _bread_count() -> int:
	return Cut.count(["k_bread_kael", "k_bread_bron", "k_bread_priest"])


## 미아의 빵 배달: 이 인물에게 아직 안 줬으면 주고 true
func _deliver_bread(c: Cut, who: String) -> bool:
	if Quests.state("k_mia_bread") != 1 or c.has("k_bread_" + who):
		return false
	c.flag("k_bread_" + who)
	c.sfx("pickup")
	c.quest_step("k_mia_bread", mini(_bread_count(), 3))
	return true


# ═══════════════════════════════════════════════════════════
# 1. 아침 (학교) — 기숙사 → 식당 → 수업 게시판(공통) → 날개 수업(공통)
# ═══════════════════════════════════════════════════════════

## 장 카드 뒤 기숙사 (검은 화면·HUD 꺼짐 상태에서 시작)
func ch2_start(c: Cut) -> void:
	c.lock()
	c.hud(false)
	c.music("school_day", 1.0)
	c.player_face(1)
	await c.wait(0.4)
	await c.fade_in(1.2)
	c.hud(true)
	await c.wait(0.4)
	c.sfx("door")
	c.spawn_npc("pippa", 34.0, 19.0, -1)
	await c.walk("pippa", 24.0, 110.0)
	c.emote("pippa", "!")
	await c.say("pippa", "세라! 세라피나! 일어나! 해가 중천이야!", "surprised")
	await c.say("sera", "으음… 오 분만…", "sad")
	await c.say("pippa", "학교가 아주 난리야. '폐급이 지하 괴물을 잡았대' — 복도마다 그 얘기뿐이라고!", "happy")
	await c.say("sera", "…! 아, 아니야. 그건 교사들 결계 실습 사고라니까. 교장 선생님이 그러셨어.", "surprised")
	await c.say("pippa", "흐응~ 그렇다 치고. 오늘부터 중앙 홀에 실기 수업 게시판도 열린대!", "happy")
	await c.say("pippa", "일단 아침부터! 식당에서 기다릴게. 늦으면 네 빵은 내 거다~", "smug")
	c.close_box()
	await c.walk("pippa", 35.0, 120.0)
	c.hide_actor("pippa")
	c.sfx("door")
	await c.wait(0.4)
	c.emote("neoul", "!")
	await c.say("neoul", "…배고프니라. 그 국자 든 마녀에게 가자꾸나. 어서.")
	await c.say("sera", "알았어, 알았어. 너울 너, 어젯밤에도 똑같은 말 했거든?", "happy")
	c.close_box()
	c.save_here("bed")


## 식당: 아침 식사 — 소문, 피피·이졸데, 너울의 배
func k_cafe_morning(c: Cut) -> void:
	if c.has("k_breakfast"):
		return
	c.lock()
	c.emote("pippa", "!")
	await c.say("pippa", "세라! 여기, 여기!", "happy")
	await c.player_walk(15.0)
	c.player_face(1)
	await c.say("isolde", "…왜 하필 내 옆자리야.", "smug")
	await c.say("pippa", "자리가 여기밖에 없거든요~ 고급반 아가씨.", "happy")
	await c.say("student_a", "(속닥) 저기 봐, 폐급이야. 지하에서 괴물을 맨손으로 찢었대.")
	await c.say("student_a", "(속닥) 교장 선생님은 젊었을 때 하늘을 셋으로 갈랐다던데… 둘 중에 누가 더 무서울까?")
	c.emote("sera", "sweat")
	await c.say("sera", "…맨손으로 찢은 적 없거든.", "sad")
	await c.walk("butterworth", 19.0, 70.0)
	c.face("butterworth", -1)
	await c.say("butterworth", "아이고, 우리 영웅님 오셨네! 오늘은 곱빼기다. 그리고 이건 — 여우 몫!", "happy")
	c.emote("neoul", "heart")
	await c.say("neoul", "…! 이 마녀, 사람 볼 줄 아는구나. 고기니라. 고기…!")
	c.sfx("squish", -4.0)
	await c.wait(0.6)
	await c.say("isolde", "실기 게시판에 '불꽃 날개' 수업이 붙었더군. 오필리아 교수 수업.")
	await c.say("isolde", "폐급이 날개를 달면… 추락하는 별똥별이나 되겠지.", "smug")
	await c.say("pippa", "그래 놓고 너도 신청할 거잖아~", "smug")
	await c.say("isolde", "…난 이미 들었어. 작년에.", "angry")
	await c.say("sera", "날개라… 나 해 볼래. 중앙 홀 게시판이지?", "happy")
	c.close_box()
	await c.walk("butterworth", 26.0, 70.0)
	c.face("butterworth", -1)
	c.flag("k_breakfast")
	c.bubble("배가 부르니 날 수도 있을 것 같구나. 중앙 홀로 가자.", 3.0)
	c.save()


## 바람의 탑: 날개 수업이 끝난 직후 — 교장의 부름
func k_after_wings(c: Cut) -> void:
	await c.wait(0.4)
	c.lock()
	if c.actor("ophelia"):
		await c.say("ophelia", "아 참~ 깜빡할 뻔했네~ 교장 선생님이 세라를 찾으셨어~", "happy")
		await c.say("ophelia", "손님이 오셨대~ 아주 반짝반짝한 갑옷을 입은~ 시계탑 꼭대기 교장실이야~")
	else:
		await c.say("neoul", "세라. 종소리에 섞여 들리던데… 교장이 너를 찾는다는구나.")
	await c.say("sera", "교장 선생님이…? 설마 어제 지하 일 때문에…", "surprised")
	await c.say("neoul", "혼나러 가는 얼굴은 하지 말거라. 우린 잘못한 게 없느니라.")
	c.close_box()


## 교장실: 제국의 사자 — 파견 결정, 별 브로치
func k_envoy(c: Cut) -> void:
	if c.has("k_envoy_seen"):
		return
	c.lock()
	c.spawn_npc("k_envoy", 20.0, 19.0, 1)
	c.spawn_npc("emberlyn", 31.0, 19.0, -1)
	c.spawn_npc("isolde", 34.0, 19.0, -1)
	c.spawn_npc("pippa", 36.0, 19.0, -1)
	await c.player_walk(12.0)
	c.player_face(1)
	await c.say("astrid", "어서 와요, 세라. 마침 모두 모였네요.")
	await c.say("k_envoy", "아르덴 제국 황실의 사자, 기사 오스카입니다. 마녀학교에 정식으로 도움을 청하러 왔습니다.")
	await c.say("k_envoy", "황도에 '별의 짐승'이 나타났습니다. 별 조각을 삼킨 짐승들입니다. 밤마다 늘어나고 있습니다.")
	await c.say("astrid", "10년 전 별이 떨어진 그 도시군요.", "sad")
	await c.say("k_envoy", "은사자 기사단이 막고 있지만… 단장님께서는 마녀의 도움을 썩 반기지 않으십니다. 황제 폐하의 뜻입니다.")
	await c.say("astrid", "그럼 '현장 실습'이라고 해 두죠. 마녀학교 학생들이 제국 구경을 좀 하는 거예요.", "smug")
	await c.say("astrid", "인솔은 엠버린 교수. 학생은 이졸데, 피피 — 그리고 세라.")
	c.emote("isolde", "!")
	await c.say("isolde", "…폐급을 데려간다고요? 교장 선생님, 실습이 아니라 사고 수습이 될 텐데요.", "angry")
	await c.say("astrid", "제가 고른 학생들이에요. …불만 있나요?", "happy")
	await c.say("isolde", "…아뇨.", "sad")
	await c.say("pippa", "제국! 제국 시장에는 별향신료가 있다던데! 물약 재료도!", "happy")
	await c.say("emberlyn", "놀러 가는 게 아니다, 피피. 짐승 조사다. …시장 구경은 틈이 나면.", "smug")
	c.close_box()
	await c.walk("astrid", 16.0, 50.0)
	c.face("astrid", -1)
	await c.say("astrid", "세라, 잠깐. 이걸 가져가요.")
	c.flag("k_brooch")
	c.sfx("star_twinkle", 2.0)
	await c.item("교장의 별 브로치", "별 모양 은장식 브로치. 희미하게 별빛이 돈다. '한 번쯤은, 당신을 지켜 줄 거예요.'")
	await c.say("sera", "이걸… 저한테요?", "surprised")
	await c.say("astrid", "오래된 별 장식이에요. 한 번쯤은, 당신을 지켜 줄 거예요. …한 번쯤은요.")
	await c.say("neoul", "…별 냄새가 나는구나. 이 마녀, 무엇을 아는 게냐.", "sad")
	await c.say("emberlyn", "앞마당 전이진에서 출발한다. 준비되면 오너라. 공관과 이어 두었다.")
	c.close_box()
	c.flag("k_envoy_seen")
	c.save()


## 앞마당 전이진: 출발 → 제국 공관 도착 (첫 왕복은 대본이 옮긴다)
func k_depart(c: Cut) -> void:
	if c.has("k_departed"):
		return
	c.lock()
	await c.player_walk(24.0)
	c.player_face(-1)
	await c.say("emberlyn", "모두 모였구나. 이 전이진은 제국 주재 공관과 이어져 있다.")
	await c.say("pippa", "물약 잔뜩 챙겼어! 세라, 다 떨어지면 나한테 와!", "happy")
	await c.say("isolde", "…발목이나 잡지 마.", "smug")
	await c.say("sera", "잡을 발목이 있어야 잡지. 너 날아다닐 거잖아.", "smug")
	c.close_box()
	c.sfx("warp", 2.0)
	c.flash(Color(0.75, 0.6, 1.0, 0.8), 0.6)
	c.shake(0.15, 0.6)
	await c.wait(0.4)
	await c.fade_out(0.8, Color(0.85, 0.8, 1.0))
	c.flag("k_departed")
	c.warp_unlock("kingdom")
	await c.goto_room("k_embassy", "warp")
	c.music("kingdom", 1.0)
	await c.fade_in(1.0)
	await c.wait(0.3)
	c.sfx("warp", -4.0)
	await c.say("sera", "…우와. 벌써 도착이야?", "surprised")
	await c.say("emberlyn", "제국 주재 마녀학교 공관이다. 여기서 쉬고, 기록하고, 전이진으로 언제든 학교에 돌아갈 수 있다.")
	await c.say("emberlyn", "먼저 은사자 기사단장에게 인사를 해야 하는데… 시장을 지나 동쪽, 기사단 연무장이다.")
	await c.say("pippa", "나는 공관에 물약 가게 차릴래! 필요하면 언제든 와. 공짜야, 친구니까!", "happy")
	await c.say("isolde", "…나는 짐 정리. 먼저 가 봐.")
	await c.say("neoul", "흐음… 이 도시, 별 냄새와 쇠 냄새가 섞여 있구나.")
	c.close_box()
	c.save()


func enter_k_embassy(c: Cut) -> void:
	if c.has("k_departed") and not c.has("warp_kingdom"):
		c.warp_unlock("kingdom")


# ═══════════════════════════════════════════════════════════
# 2. 시장 습격 — 레오니 등장
# ═══════════════════════════════════════════════════════════

func k_market_beast(c: Cut) -> void:
	if c.has("k_met_leonie") or not c.has("k_departed"):
		return
	c.lock()
	c.sfx("roar", 2.0)
	c.shake(0.3, 0.6)
	await c.wait(0.4)
	await c.say("k_citizen_b", "지, 짐승이다! 별의 짐승이 또 나타났어!", "surprised")
	c.close_box()
	var w := c.spawn_enemy("star_wolf", 82.0, 19.0, "beast_wolf", {"engaged": true})
	c.freeze_enemies(true)
	if w:
		await c.camera_to(w.global_position + Vector2(0, -30), 0.6)
		await c.wait(0.5)
		await c.camera_back(0.5)
	c.emote("neoul", "!")
	await c.say("neoul", "세라, 온다! 사람들 쪽으로 보내지 마라!")
	c.close_box()
	c.music("starbeast", 0.4)
	c.release()
	if w:
		await c.wait_enemy(w, 0.55, 22.0)
	if not c.ok():
		return
	# 은사자 기사단장
	c.lock()
	var alive := w != null and is_instance_valid(w) and w.is_alive()
	var tx := (w.global_position.x / 16.0) if alive else c.player_tile().x + 5.0
	c.spawn_npc("leonie", 118.0, 19.0, -1)
	c.sfx("whoosh", 2.0)
	await c.wait(0.2)
	await _flash_step(c, "leonie", tx + (2.0 if alive else 0.0))
	if alive:
		c.sfx("sword_slash", 4.0)
		c.flash(Color(1, 1, 1, 0.7), 0.25)
		c.shake(0.4, 0.4)
		w.take_hit(Hit.make(99999, &"ally", w.global_position + Vector2(20, -10)))
	await c.wait(0.8)
	c.pose("leonie", "idle")
	c.music("kingdom", 1.0)
	c.sfx("crowd", 2.0)
	await c.say("k_citizen_c", "단장님이다! 레오니 단장님!", "happy")
	await c.say("k_citizen_b", "한 칼이야, 한 칼! 봤어? 칼이 안 보였어!", "happy")
	c.close_box()
	if not alive:
		await c.say("leonie", "…쓰러뜨렸나. 혼자서.")
	await c.say("leonie", "다친 사람은.")
	await c.say("k_citizen_c", "없습니다, 단장님!", "happy")
	await c.say("leonie", "…좋다.")
	c.close_box()
	await c.approach("leonie", 3.5, 60.0)
	await c.say("leonie", "그 모자. 마녀학교에서 왔다는 학생들인가.")
	await c.say("sera", "아, 네! 세라피나예요. 다들 세라라고…", "happy")
	await c.say("leonie", "레오니 발렌하르트. 은사자 기사단장이다.")
	await c.say("leonie", "여긴 마녀 놀이터가 아니다. 짐승은 우리가 벤다.", "stern")
	await c.say("sera", "놀러 온 거 아니거든요!", "angry")
	await c.say("leonie", "…그렇다면 연무장으로 와라. 놀러 온 게 아닌지, 내 눈으로 보겠다.")
	c.close_box()
	await c.walk("leonie", 119.0, 80.0)
	c.hide_actor("leonie")
	await c.say("neoul", "…저 계집, 마력이 한 톨도 없구나. 헌데 그 검은 바람보다 빨랐다.", "sad")
	await c.say("sera", "…멋있다.", "happy")
	await c.say("neoul", "흥. 감탄은 나중에 하거라. 연무장이라 했지.")
	c.close_box()
	c.flag("k_met_leonie")
	c.save()


# ═══════════════════════════════════════════════════════════
# 3. 기사단 연무장 — 목검 대련 · 성벽 위 대화
# ═══════════════════════════════════════════════════════════

func k_spar(c: Cut) -> void:
	if c.has("k_spar_done") or not c.has("k_met_leonie"):
		return
	c.lock()
	await c.player_walk(34.0)
	c.player_face(1)
	await c.say("leonie", "왔군.")
	await c.say("leonie", "목검이다. 규칙은 간단하다. 내게 세 번 맞히거나 — 일 분을 버텨라.")
	await c.say("kael", "단장님 상대로 일 분이요?! 저는 십 초도 못 버티는데!", "surprised")
	await c.say("leonie", "카엘. 조용.")
	await c.say("sera", "불은… 써도 돼요?", "surprised")
	await c.say("leonie", "써라. 안 쓰면 일 초도 못 버틴다.")
	c.close_box()
	var n := c.actor("leonie") as Node2D
	var lx := (n.global_position.x / 16.0) if n else 46.0
	c.hide_actor("leonie")
	var sp := c.spawn_enemy("leonie_spar", lx - 0.5, 19.0, "spar", {"engaged": false})
	if sp == null:
		c.flag("k_spar_done")
		return
	sp.facing = -1
	c.music("knight_duel", 0.4)
	await c.title_card("대련", "세 번 맞히거나 · 60초 버티기", 1.4)
	sp.engaged = true
	c.release()
	var sp_ref: WeakRef = weakref(sp)
	await c.wait_until(func() -> bool: return _gone_or(sp_ref, "result"), 240.0)
	if not c.ok():
		return
	c.lock()
	var result := String(sp.get("result")) if is_instance_valid(sp) else "time"
	await c.wait(0.8)
	var ln := c.actor("leonie") as Node2D
	if is_instance_valid(sp):
		var pos := sp.global_position
		sp.queue_free()
		if ln:
			ln.global_position = pos
	if ln:
		ln.visible = true
		ln.process_mode = Node.PROCESS_MODE_INHERIT
		c.face("leonie", -1 if c.player.global_position.x < ln.global_position.x else 1)
	c.music("kingdom", 1.0)
	match result:
		"hits":
			await c.say("leonie", "…세 번.", "surprised")
			await c.say("leonie", "나쁘지 않군.", "happy")
		"time":
			await c.say("leonie", "…일 분. 끝까지 눈을 감지 않았군.")
			await c.say("leonie", "나쁘지 않군.", "happy")
		_:
			await c.say("leonie", "그만. 오늘은 여기까지다.")
			await c.say("sera", "아, 아직… 할 수 있어요…!", "sad")
			await c.say("leonie", "알고 있다. 넘어져도 불을 꺼뜨리지 않더군. …나쁘지 않군.", "happy")
	c.emote("kael", "!")
	await c.say("kael", "단장님이 '나쁘지 않군'이라니! 마녀님, 그거 단장님 최고 칭찬이에요! 저는 삼 년 동안 한 번도…!", "surprised")
	await c.say("leonie", "카엘.")
	await c.say("kael", "…조용히 하겠습니다.", "sad")
	await c.say("leonie", "세라피나라고 했지. 따라와라. 성벽 위에서 할 말이 있다.")
	c.close_box()
	c.flag("k_spar_done")
	await c.walk("leonie", 72.0, 70.0)
	c.hide_actor("leonie")
	await c.say("neoul", "…칼이 보이지도 않더구나. 막는 법을 배워야겠어, 세라.", "sad")
	await c.say("sera", "막는 법… 엠버린 선생님이 '불꽃 방벽' 수업을 하신다고 했었지.")
	c.close_box()
	c.bubble("학교 수업 게시판에 '불꽃 방벽'이 열렸을 게다. 언제든 공관 전이진으로.", 3.4)
	c.save()


## 성벽 위: 무력(無力)과 폐급 — 2장의 정서 핵심
func k_walls_talk(c: Cut) -> void:
	if c.has("k_walls_talk") or not c.has("k_spar_done"):
		return
	c.lock()
	await c.player_walk(40.0)
	c.player_face(1)
	c.face("leonie", -1)
	await c.wait(0.4)
	await c.say("leonie", "시장에서. 짐승이 덤빌 때 겁도 없이 앞으로 나서더군.")
	await c.say("sera", "…겁은 났어요. 근데 뒤에 사람들이 있었으니까.")
	c.face("leonie", 1)
	await c.wait(0.6)
	await c.say("leonie", "나는 마력이 없다. 한 톨도.")
	await c.say("leonie", "그래서 '무력(無力)'이라 불렸지. 빈민가에서도, 기사 시험장에서도.", "sad")
	await c.wait(0.4)
	await c.say("sera", "……")
	await c.say("sera", "…나는 마력이 너무 많아서 '폐급'이에요.", "sad")
	c.face("leonie", -1)
	c.emote("leonie", "?")
	await c.say("leonie", "너무 많아서?", "surprised")
	await c.say("sera", "조절을 못 하거든요. 쏘면 터지고, 참으면 넘치고. 그래서 일반반.")
	await c.say("leonie", "…이상한 일이군.")
	await c.say("leonie", "없어서 버림받은 자와, 넘쳐서 버림받은 자가 같은 성벽 위에 서 있다니.", "happy")
	c.close_box()
	c.bubble("…흥.", 1.4)
	await c.wait(0.8)
	await c.say("leonie", "세라피나. 저기 — 굴뚝 그을음 사이로 별가루 자국이 보이나?")
	await c.camera_to(Vector2(80.0, 120.0), 1.2)
	await c.say("leonie", "짐승들은 밤마다 지붕을 타고 다닌다. 흔적은 저 지붕들을 넘어 시계 구역 쪽으로 이어진다.")
	await c.camera_back(0.8)
	await c.say("leonie", "나는 기사단과 땅 밑을 뒤진다. 너는 위를 맡아라.")
	await c.say("sera", "지붕 위요? …아, 날개!", "happy")
	await c.say("leonie", "서쪽 끝 철창을 열어 두지. 굴뚝 열기를 타면 높이 오를 수 있을 거다.")
	await c.say("leonie", "떨어지지 마라. 주워 담을 기사가 없다.")
	c.close_box()
	c.flag("k_walls_talk")
	c.sfx("door")
	await c.walk("leonie", 12.0, 70.0)
	c.hide_actor("leonie")
	c.save()


# ═══════════════════════════════════════════════════════════
# 4. 지붕 — 이졸데 지붕 경주(서브)
# ═══════════════════════════════════════════════════════════

func _race_time() -> float:
	return GameState.run_time - float(GameState.flag("k_race_t0", 0.0))


func enter_k_roof_1(c: Cut) -> void:
	if not c.has("k_roof_intro"):
		c.flag("k_roof_intro")
		c.bubble("굴뚝 연기가 따뜻하구나. 날개를 펴고 그 열기를 타 보거라.", 3.2)
	elif c.has("k_race_on"):
		Story.toast("경주 — %d초" % int(_race_time()), 1.4)


func enter_k_roof_2(c: Cut) -> void:
	if c.has("k_race_on"):
		Story.toast("경주 — %d초 / %d초" % [int(_race_time()), int(RACE_LIMIT)], 1.6)
	elif not c.has("k_roof2_intro"):
		c.flag("k_roof2_intro")
		c.bubble("빨래 너머 저 집… 벽이 어딘가 어색하구나. 여우창문으로 들여다보거라.", 3.2)


func enter_k_roof_3(c: Cut) -> void:
	if c.has("k_race_on"):
		Story.toast("경주 — %d초 / %d초" % [int(_race_time()), int(RACE_LIMIT)], 1.6)


## 지붕4(시계 거리 위): 시계 구역 도착 + 경주 결승
func enter_k_roof_4(c: Cut) -> void:
	if c.has("k_walls_talk") and not c.has("k_clock_arrived"):
		c.flag("k_clock_arrived")
	if c.has("k_race_on"):
		await _race_finish(c)


func _race_finish(c: Cut) -> void:
	var t := _race_time()
	c.flag("k_race_on", false)
	c.lock()
	await c.wait(0.3)
	var p := c.player_tile()
	if t <= RACE_LIMIT:
		Story.toast("결승! %d초" % int(t), 2.0)
		c.sfx("checkpoint", 2.0)
		await c.wait(0.8)
		c.spawn_npc("isolde", p.x - 8.0, p.y - 8.0, 1)
		c.sfx("glide")
		await c.move("isolde", p.x - 3.0, p.y, 0.9, Tween.TRANS_QUAD)
		c.sfx("land")
		await c.say("isolde", "…헉, 헉. 쳇.", "angry")
		await c.say("isolde", "졌어. 인정할게.", "sad")
		await c.say("sera", "어? 이졸데가 인정을 다 하네?", "smug")
		await c.say("isolde", "…시끄러워, 세라.", "smug")
		c.emote("sera", "!")
		await c.say("sera", "…방금 나 이름으로 불렀어?", "surprised")
		await c.say("isolde", "착각이야. 바람 소리겠지. …다음엔 안 져.", "happy")
		c.close_box()
		c.flag("k_race_won")
		await c.quest_done("k_isolde_race")
		c.bubble("흐흥. 저 아이, 귀가 빨갛구나.", 2.4)
	else:
		Story.toast("시간 초과 — %d초" % int(t), 2.0)
		await c.wait(0.6)
		c.spawn_npc("isolde", p.x - 3.0, p.y, 1)
		await c.say("isolde", "늦었어, 폐급. 난 벌써 차 한 잔 마셨는데.", "smug")
		await c.say("isolde", "…다시 할 거면 굴뚝 숲으로 와. 기다려 줄 테니까.")
		c.close_box()
		c.quest_step("k_isolde_race", 0)
		c.hide_actor("isolde")


func _race_start(c: Cut) -> void:
	await c.say("isolde", "왔네. 규칙은 간단해. 여기서 시계 거리 지붕까지 — 2분.")
	await c.say("isolde", "굴뚝 열기를 타고, 빨래 골목을 지나, 풍향계 지붕에서 내려가는 계단까지. 늦으면 내 승리.")
	var i := await c.choose("isolde", "준비됐어?", ["출발!", "잠깐만"])
	if i != 0:
		await c.say("isolde", "…겁나면 그만둬도 돼.", "smug")
		return
	c.close_box()
	Story.toast("셋…", 0.6)
	c.sfx("blip")
	await c.wait(0.6)
	Story.toast("둘…", 0.6)
	c.sfx("blip")
	await c.wait(0.6)
	Story.toast("하나… 출발!", 1.0)
	c.sfx("bell_small", 2.0)
	c.flag("k_race_on")
	c.flag("k_race_t0", GameState.run_time)
	c.quest_step("k_isolde_race", 1)
	c.sfx("glide")
	await c.move("isolde", 80.0, 14.0, 0.8, Tween.TRANS_QUAD)
	c.hide_actor("isolde")


# ═══════════════════════════════════════════════════════════
# 5. 시계 구역 — 시계공 오토 · 톱니 시계 · 시계탑
# ═══════════════════════════════════════════════════════════

func enter_k_clock_street(c: Cut) -> void:
	if c.has("k_walls_talk") and not c.has("k_clock_arrived"):
		c.flag("k_clock_arrived")
	if c.has("k_clock_intro") or not c.has("k_walls_talk"):
		return
	c.flag("k_clock_intro")
	c.lock()
	await c.wait(0.4)
	await c.say("k_clockmaker", "거기, 마녀 아가씨! 지붕에서 내려온 거요? 다친 데는?", "surprised")
	await c.say("sera", "괜찮아요! 짐승 흔적을 따라왔는데… 이쪽으로 이어져 있어서요.")
	await c.say("k_clockmaker", "흔적이라면 시계탑이오. 별가루 묻은 도마뱀들이 밤마다 저 탑을 오르내리지.")
	await c.say("k_clockmaker", "헌데 탑 문이 안 열려. 태엽 공방의 톱니 시계 셋이 엉망이 됐거든. 그 셋이 맞아야 탑의 큰 태엽이 맞물려.")
	await c.say("k_clockmaker", "그 시계들은 대성당 종과 함께 울리게 돼 있소. 종이 언제 몇 번 치는지는… 대성당 게시판에 있을 거요.")
	await c.say("k_clockmaker", "아, 그리고 태엽 경비병들! 요즘 고장 나서 아무나 찔러. 정면은 단단하니 등의 태엽 열쇠를 노리시오.")
	await c.say("neoul", "종소리를 세어 시곗바늘을 맞추라는 게로구나. 바늘은 불을 쬐면 돈다 했지.")
	c.close_box()
	c.save()


func npc_k_clockmaker(c: Cut) -> void:
	if c.has("k_tower_top"):
		await c.say("k_clockmaker", "탑 꼭대기에 짐승 둥지가 있었다고? …평생 저 탑을 고쳤는데 몰랐다니.", "sad")
	elif c.has("k_gears_done"):
		await c.say("k_clockmaker", "들었소? 탑의 큰 태엽이 맞물리는 소리! 이제 탑 문이 열릴 거요. 꼭대기까지는 바람을 타야 하지만.", "happy")
	else:
		await c.say("k_clockmaker", "태엽 공방은 바로 저 아래 계단이오. 시계 셋 — 새벽, 정오, 저녁.")
		await c.say("k_clockmaker", "바늘은 불을 쬐면 한 시간씩 돌아가. 종 치는 횟수는 대성당 게시판에. 대성당은 이 거리 동쪽 끝이오.")


## 톱니 시계 셋이 맞았을 때 (태엽 공방 이벤트)
func k_gears_solved(c: Cut) -> void:
	await c.wait(0.6)
	c.lock()
	c.sfx("bell", 2.0)
	c.shake(0.2, 1.0)
	await c.wait(0.8)
	c.sfx("chain", 0.0)
	await c.say("sera", "…어디선가 큰 태엽이 철컥, 맞물리는 소리가…!", "surprised")
	await c.say("neoul", "탑이 깨어났구나. 가자, 세라. 시계탑 문은 거리 동쪽에 있었다.")
	c.close_box()
	Story.toast("시계탑 문이 열렸다.", 2.4)
	c.save()


## 시계탑 꼭대기: 짐승 둥지 + 성흔 늑대
func k_tower_top(c: Cut) -> void:
	if c.has("k_tower_top") or not c.has("k_gears_done"):
		return
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "여기… 둥지야. 별 조각이 잔뜩…", "surprised")
	await c.say("neoul", "짐승 냄새. 그리고 — 사람 냄새. 누군가 짐승을 여기 불러 모았구나.", "sad")
	c.sfx("growl", 2.0)
	c.shake(0.2, 0.5)
	await c.wait(0.4)
	var w := c.spawn_enemy("star_wolf", 34.0, 12.0, "tower_wolf", {"engaged": true})
	c.freeze_enemies(true)
	c.emote("neoul", "!")
	await c.say("neoul", "몸에 별자리가 새겨진 늑대다! 울부짖으면 발밑을 보거라!")
	c.close_box()
	c.music("starbeast", 0.4)
	c.release()
	if w:
		await c.wait_enemy(w)
	if not c.ok():
		return
	c.lock()
	c.music("kingdom", 1.5)
	await c.wait(0.8)
	await c.say("sera", "하아… 하아…")
	await c.say("sera", "저기, 늑대가 끌고 온 자국이… 탑 아래로, 대성당 쪽으로 이어져.", "surprised")
	await c.say("neoul", "대성당 밑이라… 지하 묘지겠구나. 죽은 이들 곁에 숨는 놈들이라니, 고약하니라.")
	c.close_box()
	c.flag("k_tower_top")
	c.save()


# ═══════════════════════════════════════════════════════════
# 6. 대성당 · 지하 묘지 — 별 수정 장벽 (불꽃 방벽 수업으로)
# ═══════════════════════════════════════════════════════════

func enter_k_cathedral(c: Cut) -> void:
	if c.has("k_cathedral_intro"):
		return
	c.flag("k_cathedral_intro")
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "…커다랗다. 그런데 좀 어둡네. 촛불이 이렇게 많은데.")
	await c.say("k_priest", "어서 오세요, 작은 마녀님. 빛의 신 루멘의 집입니다.")
	await c.say("k_priest", "…어둡지요? 요즘 루멘의 빛이 약해졌답니다. 촛불을 두 배로 켜도 예전만 못해요.", "sad")
	await c.say("k_priest", "성산의 대신전에서도 같은 소식이 들립니다. …별이 떨어진 뒤로, 하늘이 무언가를 잃어버린 것 같아요.", "sad")
	await c.say("neoul", "…신의 빛이 약해진다라. 남의 일 같지 않구나.", "sad")
	c.close_box()


func npc_k_priest(c: Cut) -> void:
	if _deliver_bread(c, "priest"):
		await c.say("k_priest", "미아가 보낸 빵이로군요. 고맙습니다. …그 아이 빵 덕분에 아침 기도가 덜 쓸쓸하답니다.", "happy")
		return
	if c.has("k_beast_down"):
		await c.say("k_priest", "별의 짐승이 쓰러졌다니. 루멘께 감사를… 아니, 작은 마녀님께 감사를 드려야겠군요.", "happy")
	elif c.has("k_tower_top") and not c.has("k_crypt_open"):
		await c.say("k_priest", "지하 묘지에 짐승이 드나든다고요? …요 며칠 밤마다 아래에서 유리 부딪는 소리가 났어요.", "surprised")
		await c.say("k_priest", "묘지 계단은 오른쪽 끝입니다. 루멘의 가호가… 약하게나마 함께하기를.")
	else:
		await c.say("k_priest", "종은 하루 세 번 칩니다. 새벽에 다섯 번, 정오에 열두 번, 저녁에 일곱 번.")
		await c.say("k_priest", "기도 시간을 알리는 종이에요. 시계 거리의 시계들도 이 종에 맞춰 왔지요.")


## 지하 묘지 입구: 별 수정 장벽 — 레오니 "막지도 못하면서"
func k_crypt_wall(c: Cut) -> void:
	if c.has("k_crypt_seen"):
		return
	c.flag("k_crypt_seen")
	c.lock()
	await c.wait(0.3)
	await c.camera_to(Vector2(41.0 * 16.0, 16.0 * 16.0), 0.8)
	await c.say("sera", "보라색 수정이… 길을 막고 있어. 안쪽에서 별빛이 뛰어.", "surprised")
	await c.camera_back(0.6)
	c.sfx("door")
	c.spawn_npc("leonie", 4.0, 19.0, 1)
	await c.walk("leonie", 21.0, 90.0)
	await c.say("leonie", "역시 이리로 이어졌군. 하수도에서 거슬러 올라왔다.")
	await c.say("leonie", "칼로는 흠집도 안 난다. 붙잡은 신도 말로는 '별의 방패'라더군.")
	await c.say("leonie", "저 수정이 쏘는 별 조각을 되받아쳐야 깨진다고 했다.")
	if GameState.has_ability("ward"):
		await c.say("sera", "되받아치는 거라면… 할 수 있어요. 방벽이면!", "happy")
		await c.say("leonie", "…배워 왔나. 보여 줘라.")
		c.close_box()
		await c.walk("leonie", 10.0, 80.0)
		c.face("leonie", 1)
		c.bubble("가까이 가면 조각이 날아온다. 닿기 직전에 방벽을 세우거라!", 3.0)
	else:
		await c.say("leonie", "넌 아까 대련에서 내 검을 한 번도 막지 못했지.", "stern")
		await c.say("leonie", "막지도 못하면서 되받아치겠다고?")
		await c.say("sera", "…배우면 되잖아요!", "angry")
		await c.say("leonie", "그럼 배워 와라. 그동안 이 묘지는 기사들이 지킨다.")
		c.close_box()
		await c.walk("leonie", 4.0, 80.0)
		c.hide_actor("leonie")
		await c.say("neoul", "엠버린에게 가자꾸나. 학교 수업 게시판에 '불꽃 방벽'이 있었지. 공관 전이진으로 가면 금방이니라.")
		c.close_box()
	c.save()


func k_crypt_broken(c: Cut) -> void:
	await c.wait(0.8)
	c.lock()
	if c.actor("leonie") and (c.actor("leonie") as Node2D).visible:
		await c.say("leonie", "…깨졌군.", "surprised")
		await c.say("leonie", "아래는 하수도다. 신도들의 굴이 그 끝에 있을 거다. 나는 기사들을 모아 뒤따르겠다.")
		c.close_box()
		await c.walk("leonie", 4.0, 80.0)
		c.hide_actor("leonie")
	else:
		await c.say("neoul", "되쏜 별이 제 방패를 깨뜨렸구나. 길이 열렸다. 아래는 하수도니라.")
		c.close_box()
	c.save()


# ═══════════════════════════════════════════════════════════
# 7. 하수도 — 수문 밸브 · 별철 · 녹시스
# ═══════════════════════════════════════════════════════════

func enter_k_sewer_1(c: Cut) -> void:
	if c.has("k_sewer_intro"):
		return
	c.flag("k_sewer_intro")
	c.bubble("…코가 떨어지겠구나. 물이 별빛으로 번들거리는 게 수상하니라.", 3.0)


func enter_k_sewer_2(c: Cut) -> void:
	if c.has("k_sewer2_intro"):
		return
	c.flag("k_sewer2_intro")
	c.bubble("다리 밑 굴에 뭔가 반짝인다. 수로 물을 빼면 닿겠구나.", 3.0)


func enter_k_sewer_3(c: Cut) -> void:
	if c.has("k_sewer3_intro"):
		return
	c.flag("k_sewer3_intro")
	c.bubble("물이 그득하구나. 뗏목을 밟고 건너거라. 빠지면 떠내려간다.", 3.0)


func enter_k_sewer_4(c: Cut) -> void:
	if c.has("k_sewer4_intro"):
		return
	c.flag("k_sewer4_intro")
	c.bubble("위로 뚫린 갱도다. 뗏목에 올라탄 채 밸브를 돌려 보거라.", 3.0)


func k_star_iron_got(c: Cut) -> void:
	if Quests.state("k_bron_ore") == 1:
		c.quest_step("k_bron_ore", 1)
	c.bubble("별철이다. 대장장이 브론이 반기겠구나.", 2.4)


func k_grate_open(c: Cut) -> void:
	if c.has("k_sewer_grate"):
		return
	c.flag("k_sewer_grate")
	c.sfx("chain")
	c.sfx("door", -2.0)
	Story.toast("녹슨 빗장을 풀었다. 위는 시장 뒷골목이다.", 2.4)


## 별 신도 은신처: 대사제 녹시스 (체력 절반에서 도망) → 기록 → 레오니의 결투 신청
func k_noxis(c: Cut) -> void:
	if c.has("k_noxis_fled") or not c.has("k_crypt_open"):
		return
	c.lock()
	c.flag("k_noxis_half", false)
	c.music("", 1.0)
	await c.player_walk(50.0)
	c.player_face(-1)
	c.spawn_npc("noxis", 28.0, 19.0, 1)
	c.sfx("reveal", 2.0)
	c.burst(Vector2(28.0 * 16.0 + 8.0, 19.0 * 16.0 - 20.0), 30, Color("#c89aff"),
		{spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.7})
	await c.wait(0.6)
	await c.say("noxis", "어서 오십시오, 별에 이끌린 아이여.")
	await c.say("noxis", "녹시스라 합니다. '별을 좇는 자들'의 미천한 대사제지요.")
	await c.say("sera", "짐승들을 도시에 풀어놓은 게 당신이야?", "angry")
	await c.say("noxis", "풀어놓다니요. 짐승들은 스스로 옵니다. 별을 따라… 그리고 지금은—", "happy")
	await c.say("noxis", "당신에게로.", "zeal")
	c.emote("sera", "!")
	await c.say("neoul", "…이놈, 무슨 소리를 하는 게냐.", "scary")
	await c.say("noxis", "그분께서 보고 계십니다. 자, 보여 주십시오 — 별이 고른 그릇을!", "zeal")
	c.close_box()
	var nn := c.actor("noxis") as Node2D
	var nx := (nn.global_position.x / 16.0) if nn else 28.0
	c.hide_actor("noxis")
	var b := c.spawn_enemy("noxis", nx - 0.5, 19.0, "noxis", {"engaged": false, "auto_flee": false, "respawns": true})
	if b == null:
		c.flag("k_noxis_fled")
		return
	b.facing = 1
	c.music("boss", 0.4)
	b.engaged = true
	c.release()
	var nx_ref: WeakRef = weakref(b)
	await c.wait_until(func() -> bool: return c.has("k_noxis_half") or _dead(nx_ref), 900.0)
	if not c.ok():
		return
	c.lock()
	c.freeze_enemies(false)
	c.music("", 1.0)
	await c.wait(0.4)
	await c.say("noxis", "후후… 후후후. 충분합니다. 충분히 보았습니다.", "happy")
	await c.say("noxis", "그분은 소문 하나로 별을 움직이시지. …오늘 밤, 별이 떨어진 자리에서 다시 뵙지요.", "zeal")
	c.close_box()
	if is_instance_valid(b) and b.has_method("flee"):
		b.call("flee")
	await c.wait(1.4)
	c.flag("k_noxis_fled")
	await c.say("sera", "잠깐…! …사라졌어. 별빛 속으로.", "angry")
	c.close_box()
	# 레오니와 기사들
	c.sfx("door")
	c.spawn_npc("leonie", 79.0, 19.0, -1)
	c.spawn_npc("kael", 79.0, 19.0, -1)
	await c.walk("leonie", 56.0, 110.0)
	await c.say("leonie", "세라피나! …놈은?", "surprised")
	await c.say("sera", "도망쳤어요. 별빛 속으로.")
	await c.walk("kael", 62.0, 100.0)
	await c.say("kael", "단장님, 여기 책이…! 신도들의 기록 같습니다.", "surprised")
	await c.walk("leonie", 26.0, 70.0)
	c.face("leonie", 1)
	await c.wait(0.6)
	c.sfx("page")
	await c.say("leonie", "'짐승들은 별의 마력에 끌린다. 별이 떨어진 밤부터 늘 그랬다.'")
	await c.say("leonie", "'그런데 요즘 짐승들이 끌려가는 곳은 별이 아니다.'")
	await c.say("leonie", "'붉은 머리의 어린 마녀. 그 아이의 마력이 별보다 더 크게 운다.'", "surprised")
	await c.wait(0.6)
	await c.say("sera", "…나, 나는…", "sad")
	await c.say("leonie", "짐승들이 몰려든 이유가… 너였나.", "stern")
	await c.say("kael", "다, 단장님. 그건 마녀님 잘못이 아니잖아요…", "sad")
	await c.say("leonie", "잘잘못을 따지는 게 아니다, 카엘.")
	c.close_box()
	await c.walk("leonie", 46.0, 60.0)
	c.face("leonie", 1)
	await c.say("leonie", "세라피나. 오늘 밤, 황궁 광장으로 와라.", "stern")
	await c.say("leonie", "너를 지키는 방법이 이 도시에서 내보내는 것뿐이라면 — 그렇게 하겠다. 검으로.", "angry")
	c.close_box()
	await c.walk("leonie", 79.0, 90.0)
	c.hide_actor("leonie")
	await c.say("kael", "…마녀님. 단장님은, 그게… 원래 저런 분이 아니에요. 아니, 원래 저런 분이긴 한데…", "sad")
	c.close_box()
	await c.walk("kael", 79.0, 90.0)
	c.hide_actor("kael")
	await c.say("neoul", "…저 계집, 진심이구나.", "sad")
	await c.say("sera", "…내 마력이, 짐승을 부른다고.", "sad")
	await c.say("neoul", "세라. 넘치는 건 내가 받아 준다 하지 않았느냐. 부르는 게 짐승이든 별이든, 우린 도망치지 않느니라.")
	c.close_box()
	c.flag("k_duel_called")
	await c.fade_out(1.4)
	await c.narrate("그날 밤 — 시계탑 꼭대기.")
	c.close_box()
	await c.goto_room("k_clocktower", "top_save")
	c.music("kingdom_night", 1.0)
	await c.fade_in(1.4)
	c.player_face(-1)
	await c.wait(0.4)
	await c.say("neoul", "갈 테냐.")
	await c.say("sera", "응. 여기서 도망치면… 진짜 폐급이 되는 거니까.")
	await c.say("neoul", "흥. 그 말을 기다렸느니라. 다리 건너 귀족 구역, 그 너머가 황궁이다.")
	await c.say("neoul", "등불 든 태엽 경비병들이 깨어 있다. 들키면 싸움이 되니, 발코니 위로 가든 정면으로 가든 네 마음이니라.")
	c.close_box()
	c.save_here("top_save")


func enter_k_noble(c: Cut) -> void:
	if c.has("k_noble_intro") or not c.has("k_duel_called"):
		return
	c.flag("k_noble_intro")
	c.bubble("경비병 등불 앞은 피하거라. 등 뒤의 태엽 열쇠가 약점이니라.", 3.0)


func k_noble_alarm(c: Cut) -> void:
	c.sfx("bell_small", 2.0)
	Story.toast("들켰다! 경비병들이 몰려온다!", 2.2)
	c.bubble("들켰구나! 할 수 없지. 등 뒤로 돌아 들어가거라!", 2.4)


func npc_k_palace_guard(c: Cut) -> void:
	await c.say("k_knight", "단장님께서 광장에서 기다리십니다. 기사단 누구도 들이지 말라 하셨습니다.")
	await c.say("k_knight", "…마녀님. 부디, 몸조심하십시오.", "sad")


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


# ═══════════════════════════════════════════════════════════
# 10. 투기장 (서브: 챔피언 가론)
# ═══════════════════════════════════════════════════════════

func npc_k_arena_master(c: Cut) -> void:
	var q := Quests.state("k_arena")
	if q == 0 and c.has("k_spar_done"):
		await c.say("k_arena_master", "오오! 마녀님이시라! 단장님과 대련해서 일 분을 버텼다는 그 마녀님!", "happy")
		await c.say("k_arena_master", "우리 챔피언 '그물의 가론'과 한판 어떻소? 관중들이 좋아 죽을 거요. 이기면 수호의 깃털을 드리지!")
		var i := await c.choose("k_arena_master", "도전하시겠소?", ["도전한다", "다음에"])
		if i == 0:
			c.quest_start("k_arena")
			c.flag("k_arena_ok")
			await c.say("k_arena_master", "좋소! 오른쪽 계단으로 내려가시오. 가론! 손님이다!", "happy")
		else:
			await c.say("k_arena_master", "언제든 오시오. 투기장 문은 도전자에게 늘 열려 있소!")
	elif q == 1 and c.has("k_arena_won"):
		await c.say("k_arena_master", "들었소, 그 함성! 십 년 만에 가론이 졌어! 약속한 수호의 깃털이오!", "happy")
		c.close_box()
		await c.quest_done("k_arena")
		await c.say("k_arena_master", "다음 시즌 포스터에 마녀님 얼굴을 넣어도 되겠소? …안 된다고? 아쉽군.")
	elif q == 1:
		await c.say("k_arena_master", "가론이 바닥에서 기다리오. 그물을 조심하시오! 환호를 받기 시작하면 — 끊어 버리시오!")
	elif q == 2:
		await c.say("k_arena_master", "챔피언 마녀님! 언제든 환영이오!", "happy")
	else:
		await c.say("k_arena_master", "투기장은 지금 기사단 행사 준비 중이오. 단장님과 인사부터 하고 오시오.")


func npc_garon(c: Cut) -> void:
	if c.has("k_arena_won"):
		await c.say("garon", "오, 마녀 챔피언! 그날 관중 함성, 아직도 귀가 울린다! 하하하!", "happy")
		await c.say("garon", "다음엔 그물을 두 개 들고 나가겠다. 각오해라!")
	else:
		await c.say("garon", "나는 가론! 그물과 삼지창, 그리고 관중의 사랑으로 싸우지!", "happy")
		await c.say("garon", "환호를 받으면 힘이 솟거든. 그걸 끊을 수 있는 놈은 지금까지 없었다!")


func npc_k_arena_fan(c: Cut) -> void:
	await c.say("k_citizen_c", "가론은 관중이 소리를 지르면 더 세져요! 팔을 들고 환호를 받을 때 때려야 해요. …아, 이건 비밀인데.")


func k_arena_fight(c: Cut) -> void:
	if c.has("k_arena_won") or not c.has("k_arena_ok"):
		return
	c.lock()
	c.sfx("crowd", 4.0)
	await c.player_walk(24.0)
	c.player_face(1)
	var g := c.spawn_enemy("gladiator", 62.0, 19.0, "garon", {"engaged": false, "respawns": true})
	if g == null:
		c.flag("k_arena_won")
		return
	g.facing = -1
	await c.say("garon", "오오! 마녀 도전자라니! 관중들이여, 함성을!", "happy")
	c.sfx("crowd", 6.0)
	await c.say("garon", "그물의 가론이다! 오늘도 멋지게 묶어 주지!")
	c.close_box()
	await c.title_card("투기장", "챔피언 · 그물의 가론", 1.4)
	c.music("boss", 0.3)
	g.engaged = true
	c.release()
	await c.wait_enemy(g)
	if not c.ok():
		return
	c.lock()
	c.sfx("crowd", 6.0)
	await c.wait(1.2)
	c.music("kingdom", 1.0)
	c.spawn_npc("garon", 62.0, 19.0, -1)
	await c.say("garon", "하하하! 졌다, 졌어! 오랜만에 관중이 진짜로 소리를 질렀군!", "happy")
	await c.say("garon", "지배인한테 가 봐라. 깃털이 기다린다!")
	c.close_box()
	c.flag("k_arena_won")
	c.quest_step("k_arena", 1)
	c.save()


# ═══════════════════════════════════════════════════════════
# 11. 제국 인물 대화 (+ 서브 퀘스트)
# ═══════════════════════════════════════════════════════════

func npc_leonie(c: Cut) -> void:
	match _room(c):
		"k_knights_yard":
			if not c.has("k_spar_done"):
				await k_spar(c)
				return
		"k_walls":
			if not c.has("k_walls_talk"):
				await k_walls_talk(c)
				return
		"k_palace_plaza":
			if not c.has("k_duel_done"):
				await k_duel(c)
				return
	if c.has("k_beast_down"):
		await c.say("leonie", "세라. 왔나.", "happy")
		if Quests.done("k_bron_ore"):
			await c.say("leonie", "브론이 새 검을 벼려 줬다. 누가 별철을 구해다 줬는지는 끝내 말을 안 하더군.")
			await c.say("leonie", "…네 짓이로군. 고맙다. 이 검은 오래 쓰겠다.", "happy")
		else:
			await c.say("leonie", "검은 언젠가 부러진다. 그 전에 지킬 것을 지키면 된다.")
			await c.say("leonie", "…브론 녀석이 별철 타령을 하던데. 시간이 나면 들어 줘라. 나한테는 말을 안 하니까.")
	else:
		await c.say("leonie", "할 일이 남았다. 가라.")


func npc_kael(c: Cut) -> void:
	if _deliver_bread(c, "kael"):
		await c.say("kael", "미아네 빵! 사자 머리 빵이다! …어, 단장님 크림빵은 없어요? 아, 없구나. 다행이다. 아니, 아쉽다!", "happy")
		return
	var q := Quests.state("k_kael_helmet")
	if q == 1 and c.has("k_helmet"):
		await c.say("kael", "그, 그거 제 투구! 찾아 주셨어요?! 마녀님은 생명의 은인이에요!", "happy")
		c.close_box()
		await c.quest_done("k_kael_helmet")
		await c.say("kael", "단장님께는 비밀이에요! 절대로! …단장님 뒤에 계세요? 아니죠? 휴.", "sad")
		return
	if q == 0 and c.has("k_walls_talk"):
		await c.say("kael", "저, 저기 마녀님… 부탁이 하나 있는데요.", "sad")
		await c.say("kael", "지붕 순찰을 하다가… 가고일한테 투구를 뺏겼어요. 풍향계 근처에 걸려 있는 건 봤는데 손이 안 닿아서…")
		await c.say("kael", "단장님께 들키면 저는 끝이에요! 연무장 백 바퀴예요! 마녀님은 날 수 있잖아요!", "surprised")
		c.quest_start("k_kael_helmet")
		if c.has("k_helmet"):
			await c.say("sera", "혹시… 이거?")
			await c.say("kael", "…!! 벌써?! 마녀님 대체 뭐예요?!", "surprised")
			c.close_box()
			await c.quest_done("k_kael_helmet")
		return
	if q == 1:
		await c.say("kael", "풍향계 지붕이에요! 굴뚝 열기를 타면 위로 올라간다던데… 저는 갑옷이 무거워서…", "sad")
		return
	if c.has("k_beast_down"):
		await c.say("kael", "운석 괴물! 마녀님이랑 단장님이 같이! 그 장면 제가 봤어야 했는데! 아이 데려다주느라!", "sad")
	elif c.has("k_spar_done"):
		await c.say("kael", "단장님이 '나쁘지 않군' 한 사람, 제가 아는 걸로 마녀님이 세 번째예요. 첫 번째는 브론 아저씨 검, 두 번째는 미아네 크림빵!", "happy")
	else:
		await c.say("kael", "은사자 기사단 부단장 카엘입니다! 단장님은 무섭지만 좋은 분이에요! 아, 무섭다는 건 비밀로…", "happy")


func k_helmet_got(c: Cut) -> void:
	if Quests.state("k_kael_helmet") == 1:
		c.quest_step("k_kael_helmet", 1)
		c.bubble("카엘의 투구다. 돌려주자꾸나.", 2.4)
	else:
		c.bubble("기사의 투구로구나. 주인이 찾고 있겠지.", 2.4)


func npc_mia(c: Cut) -> void:
	var q := Quests.state("k_mia_bread")
	if q == 0 and c.has("k_met_leonie"):
		await c.say("mia", "어서 오세요! 미아네 빵집이에요! 앗, 마녀님이다! 단장님이랑 시장에서 만났다는 그 마녀님!", "happy")
		await c.say("mia", "저기, 부탁이 있어요! 빵 배달 세 곳인데요, 엄마가 허리를 다쳐서…", "sad")
		await c.say("mia", "기사단 연무장의 카엘 아저씨, 대장간의 브론 아저씨, 대성당의 사제님! 셋 다 단골이에요!")
		c.quest_start("k_mia_bread")
		c.close_box()
		await c.item("배달할 빵 바구니", "사자 머리 빵 세 봉지. 아직 따뜻하다.")
		await c.say("mia", "다 돌리면 와요! 단장님 옛날이야기 해 줄게요. 아무도 모르는 거!", "happy")
		return
	if q == 1:
		if _bread_count() >= 3:
			await c.say("mia", "벌써 다 돌렸어요?! 마녀님 빠르다! 날아서 갔죠?", "happy")
			await c.say("mia", "약속한 이야기! …단장님은요, 어릴 때 빈민가에 살았대요. 우리 엄마도 거기 출신이라 알아요.")
			await c.say("mia", "별이 떨어진 밤에, 단장님이 막대기 하나 들고 불타는 골목에서 애들을 지켰대요. 그때 단장님도 열여덟 살이었는데.")
			await c.say("mia", "그 애들 중에 한 명이… 우리 엄마예요. 그래서 우리 집은 단장님 크림빵을 공짜로 드려요. 단장님은 맨날 돈 내고 가지만!", "happy")
			c.close_box()
			await c.quest_done("k_mia_bread")
			c.bubble("…막대기 하나로. 마력 없이.", 2.4)
		else:
			await c.say("mia", "카엘 아저씨는 연무장, 브론 아저씨는 시장 대장간, 사제님은 시계 거리 동쪽 대성당이에요!")
		return
	if c.has("k_beast_down"):
		await c.say("mia", "세라 언니 그림도 그렸어요! 단장님 옆에! 다락방 상자에 넣어 둘 거예요!", "happy")
	elif c.has("k_duel_called"):
		await c.say("mia", "오늘 밤에 황궁 광장에서 뭔가 한대요! 엄마가 절대 나가지 말래요. …궁금한데.", "sad")
	else:
		await c.say("mia", "사자 머리 빵 드실래요? 단장님 빵이에요! 갈기가 바삭바삭해요!", "happy")


func npc_bron(c: Cut) -> void:
	if _deliver_bread(c, "bron"):
		await c.say("bron", "…미아 빵인가. 거기 둬라.")
		await c.say("bron", "…따뜻하군.", "happy")
		return
	var q := Quests.state("k_bron_ore")
	if q == 1 and c.has("k_star_iron"):
		await c.say("bron", "…그거, 별철이로군.", "surprised")
		await c.say("bron", "좋은 쇠다. 차갑고, 고집이 세다. 단장 검으로 벼리겠다.")
		await c.say("bron", "단장한테는 말하지 마라. 자기가 산 줄 알게 해. 그 녀석, 공짜는 안 받는다.")
		c.close_box()
		await c.quest_done("k_bron_ore")
		await c.say("bron", "그건 피피라는 꼬마가 맡긴 물약 주머니다. 내가 꿰맸다. 하나 더 들어간다.")
		return
	if q == 0 and c.has("k_spar_done"):
		await c.say("bron", "…단장 검, 봤나. 이가 다 나갔다. 짐승 뼈를 너무 베서.")
		await c.say("bron", "별철이 있으면 새로 벼려 줄 수 있다. 10년 전 별이 떨어질 때 같이 쏟아진 쇠다.")
		await c.say("bron", "하수도 수로 바닥에 가라앉아 있단 소문이 있다. 물을 빼야 보이겠지.")
		c.quest_start("k_bron_ore")
		if c.has("k_star_iron"):
			c.quest_step("k_bron_ore", 1)
		return
	if q == 1:
		await c.say("bron", "하수도 수로. 다리 밑 굴. 물을 빼라.")
		return
	await c.say("bron", "…검은 주인을 닮는다. 쓸데없이 반짝이는 건 질색이야.")


func npc_k_merchant(c: Cut) -> void:
	if Quests.state("k_spice") == 1 and not c.has("k_spice_got"):
		await c.say("k_merchant", "별향신료? 아아, 마녀학교 식당 아주머니 심부름이구먼! 그분 단골이었지, 젊었을 때.", "happy")
		c.flag("k_spice_got")
		c.quest_step("k_spice", 1)
		c.close_box()
		await c.item("별향신료", "별 모양 열매를 말린 향신료. 코끝이 반짝반짝 따끔하다.")
		await c.say("k_merchant", "돈은 됐어. 버터워스 누님한테 안부나 전해 줘!")
		return
	await c.say("k_merchant", "별 사탕, 별 열매, 별가루 소금! 별이 떨어진 도시의 명물이오!", "happy")
	await c.say("k_merchant", "…요즘은 짐승 때문에 손님이 반으로 줄었지만.", "sad")


# ─── 거리 사람들 ─────────────────────────────────────────

func npc_k_gate_guard(c: Cut) -> void:
	if c.has("k_spar_done"):
		await c.say("k_knight", "투기장은 열렸습니다. 챔피언 가론이 도전자를 기다리고 있지요.")
	else:
		await c.say("k_knight", "투기장은 기사단 행사로 닫혀 있습니다. 단장님께 인사는 하셨습니까? 연무장은 시장 지나 동쪽입니다.")


func npc_k_gate_a(c: Cut) -> void:
	if c.has("k_beast_down"):
		await c.say("k_citizen_a", "밤하늘이 그렇게 환한 건 10년 만이었어. 근데 이번엔 무섭지 않았단다.", "happy")
	elif c.has("k_met_leonie"):
		await c.say("k_citizen_a", "단장님이 시장에서 짐승을 한 칼에 베셨다며? 역시 우리 단장님이야!", "happy")
	else:
		await c.say("k_citizen_a", "마녀학교에서 왔니? 조심하렴. 요즘 별의 짐승이 대낮에도 나온단다.", "sad")


func npc_k_gate_child(c: Cut) -> void:
	await c.say("k_child", "나중에 크면 은사자 기사가 될 거야! 마력 없어도 될 수 있대! 단장님처럼!", "happy")


func npc_k_market_b(c: Cut) -> void:
	if c.has("k_beast_down"):
		await c.say("k_citizen_b", "마녀 아가씨, 고맙네. 늙은이는 오래 살다 보니 별이 두 번 떨어지는 것도 보는구먼.", "happy")
	else:
		await c.say("k_citizen_b", "10년 전 그 밤에도 하늘이 갈라졌지. 별 하나가 옛 성곽에 떨어졌는데, 이상하게 조용히 내려앉았어.")


func npc_k_market_c(c: Cut) -> void:
	await c.say("k_citizen_c", "대장간 굴뚝 열기가 엄청나요. 새들이 그걸 타고 지붕 위로 휙 올라간다니까요.")


func npc_k_alley(c: Cut) -> void:
	if c.has("k_sewer_grate"):
		await c.say("k_citizen_c", "철창이 열렸네? 하수도 냄새가… 으. 빨래 다시 해야겠다.", "sad")
	else:
		await c.say("k_citizen_c", "저 철창 아래는 하수도야. 밤마다 별빛이 새어 나와. 안쪽에서 빗장이 걸려 있어서 못 열지만.")


func npc_k_yard_a(c: Cut) -> void:
	await c.say("k_knight", "관람석에서 보면 단장님 검이 잔상처럼 보입니다. 사실 저도 잘 안 보입니다.")


func npc_k_yard_b(c: Cut) -> void:
	if c.has("k_spar_done"):
		await c.say("k_knight_b", "단장님과 대련을 버틴 마녀라니! 오늘 저녁 술안주는 정해졌군요!", "happy")
	else:
		await c.say("k_knight_b", "단장님은 마력이 한 톨도 없으세요. 그래서 다들 '무력'이라 놀렸대요. …지금은 아무도 안 놀리죠.")


func npc_k_barracks(c: Cut) -> void:
	await c.say("k_knight_b", "부단장님 침대 밑을 보지 마세요. 단장님 초상화가 잔뜩… 아, 말해 버렸다.", "sad")


# ═══════════════════════════════════════════════════════════
# 12. 학교 인물 — 2장 덮어쓰기 (npc_<who>_ch2) · 서브 퀘스트(버터워스·그레타)
# ═══════════════════════════════════════════════════════════

func npc_emberlyn_ch2(c: Cut) -> void:
	var room := _room(c)
	if room.begins_with("s_"):
		if c.has("k_crypt_seen") and not GameState.has_ability("ward"):
			await c.say("emberlyn", "레오니 단장에게 막는 법부터 배워 오라는 소리를 들었다며?", "smug")
			await c.say("emberlyn", "중앙 홀 수업 게시판에서 '불꽃 방벽'을 신청해라. 실습장에서 기다리마.")
		elif c.has("k_beast_down"):
			await c.say("emberlyn", "레오니 단장이 너를 '세라'라고 불렀다더군. …그 사람에게 그건 훈장 같은 거다.", "happy")
		else:
			await c.say("emberlyn", "제국 일은 잘 되어 가니? 무리하지 마라. 전이진은 언제든 열려 있다.")
		return
	if c.has("k_beast_down"):
		await c.say("emberlyn", "잘했다, 세라. 정말로.", "happy")
	elif c.has("k_duel_called"):
		await c.say("emberlyn", "…결투라니. 레오니 단장다운 방식이군.", "sad")
		await c.say("emberlyn", "세라. 이기라고는 안 하마. 네 불이 무엇인지만 보여 주고 와라.")
	elif c.has("k_crypt_seen") and not GameState.has_ability("ward"):
		await c.say("emberlyn", "별 수정 장벽? 되받아쳐야 깨진다면 방벽이 답이다.")
		await c.say("emberlyn", "학교로 가자. 전이진 → 중앙 홀 게시판 → '불꽃 방벽'. 실습장에서 가르쳐 주마.")
	elif c.has("k_walls_talk"):
		await c.say("emberlyn", "지붕 위라. 날개를 믿어라. 굴뚝 열기는 생각보다 세다.")
	elif c.has("k_spar_done"):
		await c.say("emberlyn", "단장과 붙었다고? …살아 돌아왔구나.", "surprised")
		await c.say("emberlyn", "검 한 번 막지 못했다는 얼굴이군. 학교 게시판에 '불꽃 방벽' 수업을 열어 두었다. 원하면 언제든.", "smug")
	else:
		await c.say("emberlyn", "기사단 연무장은 시장 지나 동쪽이다. 단장에게 예의 바르게 굴어라. …특히 너, 세라.")


func npc_pippa_ch2(c: Cut) -> void:
	if _room(c) == "k_embassy":
		GameState.potions = GameState.potions_max
		c.sfx("potion")
		Story.toast("피피가 물약을 가득 채워 주었다.", 2.0)
		var lines := [
			"물약 보급 완료! 이번 건 제국 별향신료를 살짝 넣었어. 맛은… 반짝반짝해!",
			"시장 구경했어? 별 사탕 진짜 별 맛 나! 별 맛이 뭔지는 모르겠지만!",
			"이졸데가 밤에 몰래 지붕에서 연습하는 거 봤다? 쉿, 비밀이야~",
		]
		if c.has("k_beast_down"):
			lines = ["세라! 운석 괴물이랑 싸웠다며! 다친 데 없어? 물약 더 줄까? 열 병? 스무 병?"]
		elif c.has("k_duel_called"):
			lines = ["…결투라니. 세라, 진짜 갈 거야? …그럼 물약 세 배로 챙겨. 아니, 네 배!"]
		await c.say("pippa", String(lines[randi() % lines.size()]), "happy")
		return
	if not c.has("k_departed"):
		await c.say("pippa", "제국 가면 시장부터 가자! 별향신료! 별 사탕! 별… 아무튼 다!", "happy")
	else:
		await c.say("pippa", "학교에 볼일 있어서 왔어? 나는 연금술실 재료 가지러! 금방 공관으로 돌아갈 거야~", "happy")


func npc_isolde_ch2(c: Cut) -> void:
	var room := _room(c)
	if room == "k_roof_1" and Quests.state("k_isolde_race") == 1 and not c.has("k_race_won"):
		await _race_start(c)
		return
	if room == "k_embassy":
		var q := Quests.state("k_isolde_race")
		if q == 0 and c.has("k_clock_arrived"):
			await c.say("isolde", "…폐급. 지붕 위를 날아다닌다며.")
			await c.say("isolde", "날개 수업은 내가 작년에 수석으로 통과했어. 누가 더 빠른지 — 겨뤄 볼래?", "smug")
			var i := await c.choose("isolde", "굴뚝 숲에서 시계 거리 지붕까지. 2분.", ["좋아, 해 보자", "다음에"])
			if i == 0:
				c.quest_start("k_isolde_race")
				c.flag("k_race_ready")
				await c.say("isolde", "굴뚝 숲 지붕(성벽 서쪽 끝이나 뒷골목 사다리)에서 기다릴게. 도망치지 마.")
				c.close_box()
				c.hide_actor("isolde")
			else:
				await c.say("isolde", "흥. 겁나는 거지.", "smug")
			return
		if c.has("k_race_won"):
			await c.say("isolde", "…세라. 다음 경주는 내가 이길 거야. 지붕 위에서 연습 중이니까.", "smug")
			return
		if c.has("k_duel_called") and not c.has("k_duel_done"):
			await c.say("isolde", "결투라며. …바보야? 기사단장이랑 진검으로?", "angry")
			await c.say("isolde", "…지지 마. 폐급한테 진 내 체면도 생각해.", "sad")
			return
		await c.say("isolde", "말 걸지 마. 바빠.", "smug")
		return
	if room == "s_cafeteria":
		await c.say("isolde", "밥 먹는 중이야.", "smug")
		return
	await c.say("isolde", "…제국 일이나 신경 써. 나도 곧 공관으로 갈 거니까.")


func npc_butterworth_ch2(c: Cut) -> void:
	var q := Quests.state("k_spice")
	if q == 1 and c.has("k_spice_got"):
		await c.say("butterworth", "어머나, 별향신료! 이 냄새 얼마 만이야! 시장 그 녀석, 아직 장사하는구나!", "happy")
		c.close_box()
		await c.quest_done("k_spice")
		await c.say("butterworth", "오늘 저녁은 별향신료 스튜다! 먼저 한 그릇 먹고 가. 힘이 불끈 날 거야!", "happy")
		c.emote("neoul", "heart")
		return
	if q == 0 and c.has("k_departed"):
		await c.say("butterworth", "제국에 간다고? 그럼 부탁 하나 하자. 시장에 '별향신료'라는 게 있어.")
		await c.say("butterworth", "젊었을 때 제국에서 먹어 본 맛인데… 그걸로 학교 저녁을 만들고 싶구나. 시장 향신료 상인한테 내 이름 대렴.", "happy")
		c.quest_start("k_spice")
		return
	if q == 1:
		await c.say("butterworth", "별향신료는 제국 시장 상인한테! 내 이름 대면 알 거야.")
		return
	if not c.has("k_breakfast"):
		await c.say("butterworth", "아이고, 우리 영웅님! 앉아, 앉아. 오늘은 곱빼기다!", "happy")
	else:
		await c.say("butterworth", "밥은 먹고 다니니? 그 여우도? 둘 다 말랐어!", "happy")


func npc_greta_ch2(c: Cut) -> void:
	var q := Quests.state("k_greta_books")
	var n := _book_count()
	if q == 1 and n >= 3:
		await c.say("greta", "…세 권. 전부.", "surprised")
		await c.say("greta", "『은사자 전기』, 『시간을 거스르는 태엽』, 『빛의 기도서(어린이용)』. 연체 기간 합계 십일 년.")
		await c.say("greta", "…고맙다.", "happy")
		c.close_box()
		await c.quest_done("k_greta_books")
		c.emote("hodu", "!")
		return
	if q == 0 and c.has("k_departed"):
		await c.say("greta", "…제국에 간다지.")
		await c.say("greta", "학교 책 세 권이 몇 년째 제국에서 돌아오지 않았다. 기사단, 시계 공방, 대성당에 빌려준 것.")
		await c.say("greta", "찾으면 가져와라. …화난 건 아니다.", "angry")
		c.quest_start("k_greta_books")
		c.quest_step("k_greta_books", mini(n, 3))
		return
	if q == 1:
		await c.say("greta", "…%d권. 아직 %d권." % [n, 3 - n])
		return
	await c.say("greta", "…도서관에서는 조용히.")


func k_book_got(c: Cut) -> void:
	var n := _book_count()
	if Quests.state("k_greta_books") == 1:
		c.quest_step("k_greta_books", mini(n, 3))
		c.bubble("그레타의 책이다. %d권째구나." % n, 2.4)
	else:
		c.bubble("마녀학교 도서관 도장이 찍혀 있구나. 그레타에게 돌려주자.", 2.6)


func npc_astrid_ch2(c: Cut) -> void:
	if c.has("k_brooch_broken"):
		await c.say("astrid", "…브로치가 깨졌군요.")
		await c.say("astrid", "그럼 됐어요. 그 별은 제 몫을 다했으니까. 사과하지 말아요, 세라. 고맙다고 해 줘요.", "happy")
	elif c.has("k_departed"):
		await c.say("astrid", "제국은 어떤가요? 레오니 단장은… 예전 그 아이 그대로겠죠. 칼끝처럼 곧은.")
		await c.say("astrid", "브로치는 잘 지니고 있나요? …한 번쯤은, 이라고 했던 거 잊지 말아요.")
	else:
		await c.say("astrid", "손님이 기다리고 계세요, 세라.")


func npc_mirabel_ch2(c: Cut) -> void:
	await c.say("mirabel", "제국에 다녀온다면서요? 다치면 바로 돌아와요! 공관 전이진 있잖아요~", "happy")
	await c.say("mirabel", "…여우는 그래도 침대에 올리지 말고요.")


func npc_ophelia_ch2(c: Cut) -> void:
	if GameState.has_ability("wings"):
		await c.say("ophelia", "날개는 잘 쓰고 있니~? 제국 굴뚝 바람은 학교 바람보다 따뜻하지~", "happy")
	else:
		await c.say("ophelia", "날개 수업은 게시판에서 신청하렴~ 중앙 홀이야~ 쿨…")


func npc_veronica_ch2(c: Cut) -> void:
	await c.say("veronica", "제국 파견이라. 돌아오면 고급반 수업도 생각해 봐라. …아직은 이르지만.")


# ─── 개발·시험용 (게임 안에서는 부르지 않음) ────────────

## 초상화 표정 견본 (tools/test/scenarios/ch2_portraits.json)
func dev_ch2_portrait(c: Cut) -> void:
	await c.say("leonie", "황도 아르덴에 온 걸 환영한다고는 하지 않겠다.", "normal")
	await c.say("leonie", "여긴 마녀 놀이터가 아니다.", "stern")
	await c.say("leonie", "…나쁘지 않군.", "happy")
	await c.say("leonie", "물러서라. 두 번 말하지 않는다.", "angry")
	await c.say("leonie", "나는 마력이 없다. 그래서 '무력(無力)'이라 불렸지.", "sad")
	await c.say("leonie", "…그 불이, 사람을 감쌌다고?", "surprised")
	await c.say("noxis", "어서 오십시오, 별에 이끌린 아이여.", "normal")
	await c.say("noxis", "후후후… 그분은 소문 하나로 별을 움직이시지.", "happy")
	await c.say("noxis", "보이십니까? 별 너머의 눈이 이쪽을 보고 계십니다!", "zeal")
	await c.say("noxis", "감히… 성스러운 의식을!", "angry")
	await c.say("kael", "단장님! 아, 아니, 마녀님들! 어서 오세요! 은사자 기사단 부단장 카엘입니다!", "happy")
	await c.say("mia", "레오니 단장님이 또 짐승을 한 칼에 베셨대요! 진짜예요!", "happy")
	await c.say("bron", "…검은 주인을 닮는다. 쓸데없이 반짝이는 건 질색이야.", "normal")


## 방의 살아 있는 적 모두에게 "되쏜 탄"(Hit.kind = reflect) 한 발 — 불꽃 방벽이 아직 없을 때 별 수정 방패·갑피 시험용
func dev_ch2_reflect(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en and en.is_alive():
			var h := Hit.make(150, &"reflect", c.player.center())
			h.hitstop = 0.05
			h.shake_t = 0.1
			en.take_hit(h)
			print("DEV reflect -> ", en.kind_id, " hp=", en.hp)


## 운석수를 4초 경직 (동료 레오니의 "다리를 벤다!"를 흉내)
func dev_ch2_stagger(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if e.has_method("stagger"):
			e.call("stagger", 4.0)
			print("DEV stagger -> ", (e as EnemyBase).kind_id)


## 동료 공격(Hit.kind = ally) 한 대 — 강자 보스의 막기 반응 시험용
func dev_ch2_ally_hit(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en and en.is_alive():
			en.take_hit(Hit.make(80, &"ally", en.global_position + Vector2(-30, -10)))
			print("DEV ally -> ", en.kind_id, " hp=", en.hp)


## 운석수의 큰 일격(브로치 장면용) 시험
func dev_ch2_ultimate(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if e.has_method("ultimate"):
			e.call("ultimate")
			print("DEV ultimate -> ", (e as EnemyBase).kind_id)


## 적·장치 상태 출력 (시나리오 로그용)
func dev_ch2_info(c: Cut) -> void:
	c.release()
	for e in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en:
			var extra := ""
			for k in ["hits_taken", "result", "phase", "shield_up", "carapace", "fled", "state_name"]:
				if k in en:
					extra += " %s=%s" % [k, str(en.get(k))]
			print("DEV info ", en.kind_id, " hp=", en.hp, "/", en.max_hp, " alive=", en.is_alive(), extra)
	var flags := []
	for k in ["k_sw2_low", "k_sw3_low", "k_sw4_high", "k_gears_done", "k_crypt_open", "k_sw2_wall", "k_race_on", "k_duel_done", "k_beast_down"]:
		if GameState.has_flag(k):
			flags.append(k)
	print("DEV flags ", flags, " room=", _room(c), " pos=", c.player_tile().snapped(Vector2(0.1, 0.1)),
		" chapter=", GameState.flag("chapter", 1), " tails=", GameState.flag("tails", 1), " ch2_done=", GameState.has_flag("ch2_done"),
		" maxhp=", GameState.max_hp, " pot=", GameState.potions_max, " stones=", Spells.stones())
