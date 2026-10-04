extends RefCounted
## 3장 대본 — 세계수의 눈 (docs/chapter3.md 2절 줄거리, 12절 대본 목록). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 흐름: ch3_start(온실) → e_headmaster(편지) → 전이진 → 경계의 숲(경고 사격·저격) → 뿌리 문 → 장로 → 뿌리 동굴 → 줄기 시장·티엘
##       → 바람길 → 가지 마을 → 달샘(잠재우는 불) → 흰 역병의 숲 → 심장 정화 → 수관 → 사냥 시험 → 꼭대기 → 백색 사도
##       → 장로의 집 → 기숙사의 밤 → 꼬리 셋 → 달 위의 그림자 → ChapterFlow.finish(c, 3)
## 말투: 엘라리엔 짧고 건조한 반말 · 오르티아 느릿한 하게체("~구먼", "~게") · 피오 아이 반말("누나!") · 티엘 신난 반말
##       파수꾼 딱딱한 해라체 · 너울 "~니라" · 아스트리드 존댓말 · 피피 하이텐션 · 이졸데 차갑고 오만(점점 츤데레)
## 이 파일: 3장 대본 파일들이 함께 쓰는 상수·도우미 (장면 파일이 모두 extends). 대본(공개 메서드)은 두지 말 것 —
## 파일마다 같은 ID가 생겨 Story가 오류를 낸다. 대본 목록은 story/data_ch3.gd SCRIPTS.


const SEEDS := ["e_seed_1", "e_seed_2", "e_seed_3", "e_seed_4", "e_seed_5"]
const MOSS := ["e_moss_1", "e_moss_2", "e_moss_3"]
const VALVES := ["e_valve_fix_1", "e_valve_fix_2", "e_valve_fix_3"]
const TEA := ["e_tea_leaf", "e_tea_dew"]
const SNIPE_EVERY := 13.0 ## 백색 사도전: 엘라리엔이 수정 눈을 쏘는 간격(초)
const ARCHERY_TIME := 20.0


# ─── 도우미 ─────────────────────────────────────────────

## 꽃가루 비 (세계수가 되살아날 때) — 방을 옮기면 사라짐
func _pollen(c: Cut) -> void:
	var size := c.world.room.size_px
	var p := CPUParticles2D.new()
	p.position = Vector2(size.x * 0.5, -8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x * 0.5 + 40, 4)
	p.local_coords = false
	p.z_index = 24
	p.amount = 160
	p.lifetime = 7.0
	p.preprocess = 2.0
	p.direction = Vector2(0.2, 1)
	p.spread = 25.0
	p.initial_velocity_min = 16.0
	p.initial_velocity_max = 38.0
	p.gravity = Vector2(4, 8)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	var g := Gradient.new()
	g.set_color(0, Color(0.9, 1.0, 0.6, 0.0))
	g.add_point(0.15, Color(0.85, 1.0, 0.55, 0.9))
	g.set_color(1, Color(1.0, 0.85, 0.45, 0.0))
	p.color_ramp = g
	p.material = Fx.add_material
	c.world.effects.add_child(p)


## 엘프 화살 연출 (해롭지 않음): from → to 로 날아가 지형에 박힘
func _show_arrow(c: Cut, from: Vector2, to: Vector2, speed := 900.0) -> void:
	Ch3Sfx.ensure()
	var a := ElfArrow.new()
	a.setup(from, to - from, speed, {"damage": 0, "life": 2.0})
	a.active = false
	c.world.room.add_entity(a)
	Ch3Sfx.play(&"arrow_shot", 0.0, 0.0)
