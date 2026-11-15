class_name ChapterFlow
extends RefCounted
## 장 흐름 (docs/archive/sera/systems2.md 7절). 장마다 다른 게임처럼 끊기지 않게: 장 끝 대본 → 꼬리 연출 → 저장 → 다음 장 카드 → chN_start.
## 장 제목·꼬리 수·마지막 장은 각 story/data_<장>.gd 의 CHAPTER (ChapterRegistry) — 여기는 읽기만 한다.


## 장 카드 제목 [장 표시, 부제] (없는 장이면 ["", ""])
static func title(n: int) -> Array:
	return ChapterRegistry.chapter(n).get("title", ["", ""])


static func current() -> int:
	return int(GameState.flag("chapter", 1))


## 장 끝 대본의 마지막 줄: await ChapterFlow.finish(c, N)
static func finish(c: Cut, n: int) -> void:
	var info := ChapterRegistry.chapter(n)
	GameState.set_flag("ch%d_done" % n)
	var tails := int(info.get("tails_at_end", 0))
	if tails > 0 and int(GameState.flag("tails", 1)) < tails:
		await c.tails(tails)
	if bool(info.get("last", false)):
		GameState.save_game()
		return
	GameState.set_flag("chapter", n + 1)
	GameState.save_game()
	await c.chapter_card(n + 1)
	var next := "ch%d_start" % (n + 1)
	if Story.has_script(next):
		Story.run(next)
	else:
		# 다음 장 대본이 아직 없을 때(제작 중 빌드): 검은 화면에 갇히지 않게 돌려놓음
		c.hud(true)
		await c.fade_in(1.0)
		c.bubble("…다음 이야기는 아직 쓰이지 않았다니라.", 3.0)
