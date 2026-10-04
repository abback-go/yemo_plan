extends RefCounted
## 2장 대본 — 제국의 검 (docs/chapter2.md 2절 줄거리 · 7.5절 대본 목록). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 흐름: ch2_start(기숙사) → 아침 → 날개 수업(공통) → 교장실 사자 → 출발 → 시장 습격(레오니) → 대련 → 성벽 대화 →
##       지붕 → 시계 구역(톱니 시계) → 시계탑 → 지하 묘지(별 수정 장벽 → 방벽 수업) → 하수도 → 녹시스 → 밤의 결투 →
##       레오니와 함께 운석수 → 공관 작별 → 기숙사의 밤 → ChapterFlow.finish(c, 2)
## 말투: 레오니 짧고 단정("~다.", "나쁘지 않군.") · 카엘 수다·허당 · 미아 신난 아이 · 브론 무뚝뚝 · 녹시스 공손한 광신 ·
##       이졸데 차갑다가 츤데레 · 피피 하이텐션 · 엠버린 따뜻하고 엄격 · 너울 고어체("~니라", "~하거라")
## 이야기 트리거는 모두 once=False — 대본이 첫 줄에서 플래그로 지킨다(싸우다 쓰러져도 다시 걸리게).
## 이 파일: 2장 대본 파일들이 함께 쓰는 상수·도우미 (장면 파일이 모두 extends). 대본(공개 메서드)은 두지 말 것 —
## 파일마다 같은 ID가 생겨 Story가 오류를 낸다. 대본 목록은 story/data_ch2.gd SCRIPTS.


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
