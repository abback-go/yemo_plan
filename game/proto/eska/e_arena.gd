extends EStage
## 에스카 훈련장: 마녀 분위기의 일자형 마당 + 허수아비 하나 + 끝없는 적 물결(EWaves).
## 들어오는 길: 타이틀 메뉴 "에스카 시제품" 또는 웹 주소 뒤 ?eska

const W := 1280.0
const FLOOR := 300.0

var dummy: PDummy
var waves: EWaves


func _build() -> void:
	stage_w = W
	floor_y = FLOOR
	cam_top = FLOOR - 560.0
	respawn_at = Vector2(400, FLOOR)
	EScenery.build(self, W, FLOOR)
	flat_ground()
	dummy = PDummy.new()
	dummy.setup("small")
	dummy.position = Vector2(540, FLOOR)
	add_child(dummy)


func _start() -> void:
	waves = EWaves.new()
	waves.stage = self
	add_child(waves)


## 시험 실행기 eval용: 적 하나 놓기
func spawn_foe(kind: String, x: float, y: float) -> String:
	var e := EWaves.spawn(self, kind, Vector2(x, y))
	return "%s hp=%d" % [kind, e.max_hp]


## 시험 실행기 eval용: 살아 있는 적 상태
func foes() -> String:
	var out := ""
	for n: Node in get_children():
		if n is EEnemy:
			var e := n as EEnemy
			out += "%s(x=%d hp=%d st=%d) " % [e.get_script().get_global_name(), int(e.global_position.x), e.hp, int(e.get("st"))]
	return out
