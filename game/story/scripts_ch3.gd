extends RefCounted
## 3장 대본 (docs/chapter3.md). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 1단계: 개발용 시험 대본만 (dev_ch3_*). 본 대본은 2단계에서 docs/chapter3.md 12절 목록대로.


# ─── 개발용 (시나리오 tools/test/scenarios/ch3_*.json 에서 부름) ───

## 시험 방 인물: 말을 걸어도 아무 일 없음
func dev_ch3_silent(_c: Cut) -> void:
	pass


## 초상화 점검: 3장 인물의 표정을 차례로
func dev_ch3_portrait(c: Cut) -> void:
	await c.say("elarien", "…돌아가라, 마녀. 다음은 모자가 아니다.", "normal")
	await c.say("elarien", "맞히는 건 쉽다. 안 맞히는 게 어렵지.", "smirk")
	await c.say("elarien", "바람이 오른쪽에서 분다. 셋을 세면 쏜다.", "focus")
	await c.say("elarien", "…아이들을 건드렸다고?", "angry")
	await c.say("elarien", "네 불은… 숲을 태우지 않는구나.", "happy")
	await c.say("elarien", "하나.", "surprised")
	await c.say("elarien", "…늦었다. 내가.", "sad")
	await c.say("elarien", "괜찮다. 화살 하나 빗나갔을 뿐이다.", "hurt")
	await c.say("elarien", "…오늘은 그만 쏘자.", "tired")
	await c.say("ortia", "아스트리드라… 그 꼬마가 교장이라니. 세월 참 빠르구나.", "happy")
	await c.say("ortia", "한 아이는 남고, 한 아이는 별을 보러 떠났지.", "serious")
	await c.say("ortia", "…역병이 꼭대기까지?", "surprised")
	await c.say("fio", "마녀 누나! 그 모자 진짜 구멍 났어? 보여 줘, 보여 줘!", "happy")
	await c.say("fio", "…엘라리엔 언니는 무서운 게 아니야. 말이 없을 뿐이야.", "sad")
	await c.say("tiel", "바람 밸브 3번이 또 막혔어. 불로 한 번 데우면 돌아갈 거야!", "surprised")
	await c.say("elf_warden", "멈춰라. 장로님의 허락 없이는 지나갈 수 없다.", "angry")


## 엘라리엔 자세 점검: 자세마다 한 명씩 세워 둔다 (시험 방 dev_e_tree 바닥 19행)
func dev_ch3_poses(c: Cut) -> void:
	var poses := ["idle", "walk", "run", "aim", "attack", "attack2", "windup", "guard", "hurt", "kneel", "down", "special", "charge", "leap"]
	var x0 := c.player.global_position.x / 16.0 - 18.5
	for i in poses.size():
		var pose: String = poses[i]
		var n := Npc.new()
		n.setup(c.world.room, {"who": "elarien", "x": x0 + i * 2.8, "y": 19, "face": "right", "talk": "dev_ch3_silent"}, "pose_" + pose)
		c.world.room.add_entity(n)
		if pose == "walk":
			n.visual.walking = true
		else:
			n.visual.set_pose(pose)
		if pose == "aim":
			n.visual.set_meta("aim_ang", -0.25)
		var lb := Label.new()
		lb.text = pose
		lb.position = Vector2(-10, -50 - (i % 2) * 8)
		lb.add_theme_font_size_override("font_size", 8)
		n.add_child(lb)
	await c.wait(0.1)


## 엘프 인물 자세 점검 (파수꾼 자세 + 피오·티엘·장로)
func dev_ch3_folk(c: Cut) -> void:
	var specs := [["elf_warden", "idle"], ["elf_warden", "windup"], ["elf_warden", "attack"], ["elf_warden", "guard"], ["elf_warden", "hurt"],
		["elf_warden", "kneel"], ["ortia", "idle"], ["ortia", "special"], ["fio", "idle"], ["tiel", "idle"], ["elf_c", "idle"]]
	var x0 := c.player.global_position.x / 16.0 - 16.0
	for i in specs.size():
		var who: String = specs[i][0]
		var pose: String = specs[i][1]
		var n := Npc.new()
		n.setup(c.world.room, {"who": who, "x": x0 + i * 3.0, "y": 19, "face": "right", "talk": "dev_ch3_silent"}, "folk_%d" % i)
		c.world.room.add_entity(n)
		n.visual.set_pose(pose)
	await c.wait(0.1)
