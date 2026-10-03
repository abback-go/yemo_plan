extends RefCounted
## 대본: 프롤로그 신계 (docs/chapter1.md 2절 P0~P7, 12.1절).
## 메서드 이름 = 실행 ID. enter_<방ID>는 방에 들어올 때 자동 실행.


# ─── P0 오프닝 + P1 여우고개 ────────────────────────────

func enter_t_pass(c: Cut) -> void:
	if c.has("p_intro_done"):
		return
	c.flag("p_intro_done")
	c.hud(false)
	await c.fade_out(0.01)
	await c.narrate("폐급 마녀.\n마녀학교에서 나를 부르는 이름이다. 마력이 너무 커서, 마법이 늘 제멋대로 터져 버린다.")
	await c.narrate("그런데 소문을 들었다.\n신계(神界) 깊은 곳에 — 폭주를 고쳐 줄 보물이 잠들어 있다고.")
	c.close_box()
	await c.fade_in(1.2)
	await c.wait(0.4)
	await c.say("sera", "…여기가 신계. 생각보다 조용하네.")
	await c.say("sera", "보물만 슬쩍 빌리고 바로 돌아가는 거야. 아무도 모르게.", "happy")
	c.close_box()
	c.hud(true)
	await c.teach("이동", "← → 로 걷는다.\n세라는 빠르다 — 바람처럼 달려 보자.", ["move"])


func teach_jump(c: Cut) -> void:
	await c.teach("점프", "Z 로 뛰어오른다.\n낮은 턱쯤은 가볍게.", ["jump"])


func teach_high_jump(c: Cut) -> void:
	await c.teach("높이 뛰기", "Z 를 길게 누를수록 높이 뛴다.\n꼭대기에서 누르고 있으면 잠깐 떠 있는다.", ["jump"])


func teach_dash(c: Cut) -> void:
	await c.say("sera", "넓다… 그냥 뛰어선 안 닿겠어.", "surprised")
	c.close_box()
	await c.teach("대시", "C 로 짧게 돌진한다. 공중에서도 한 번.\n점프한 뒤 대시하면 멀리 간다.", ["dash", "jump"], ["jump", "dash"])


func p_pass_gate(c: Cut) -> void:
	await c.say("sera", "홍살문… 여기서부턴 진짜 신의 땅이야.")
	await c.say("sera", "괜찮아, 세라. 들키지만 않으면 돼.", "sad")
