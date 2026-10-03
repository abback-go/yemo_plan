class_name ChapterFlow
extends RefCounted
## 장 흐름 (docs/systems2.md 7절). 장마다 다른 게임처럼 끊기지 않게: 장 끝 대본 → 꼬리 연출 → 저장 → 다음 장 카드 → chN_start.

const TITLES := {
	1: ["1장", "폐급 마녀와 여우신"],
	2: ["2장", "제국의 검"],
	3: ["3장", "세계수의 눈"],
	4: ["4장", "황금창의 수호자"],
	5: ["5장", "별의 마녀"],
}
## 장이 끝날 때 너울의 꼬리 수 (docs/bible/progression.md 3절)
const TAILS_AT_END := {2: 2, 3: 3, 4: 4}


static func current() -> int:
	return int(GameState.flag("chapter", 1))


## 장 끝 대본의 마지막 줄: await ChapterFlow.finish(c, N)
static func finish(c: Cut, n: int) -> void:
	GameState.set_flag("ch%d_done" % n)
	if TAILS_AT_END.has(n) and int(GameState.flag("tails", 1)) < int(TAILS_AT_END[n]):
		await c.tails(int(TAILS_AT_END[n]))
	if n >= 5:
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
