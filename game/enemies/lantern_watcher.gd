class_name LanternWatcher
extends Sniper
## 등롱 감시자 (docs/chapter1.md 7절·12.5절): 저격형(Sniper)의 신계판 — 석등의 불창 안에 눈이 하나 있다.
## 리듬은 저격형 그대로: 시야가 트이면 조준(붉은 선이 세라를 따라감) → 마지막 0.2초 고정(흰색 깜빡임) → 광선탄 1발 → 재장전.
## 재장전 동안 불창이 꺼졌다가 천천히 다시 차오른다. 공략 포인트 = 엄폐물 너머로 불기둥, 띄우면 조준이 끊긴다.

const HP := 90
const EYE_OFFSET := Vector2(0, -24) ## 원점(발밑) → 불창 속 눈
const FLAME := Color(1.0, 0.62, 0.32)

var _glow: LightGlow


func _build() -> void:
	max_hp = HP
	body_size = Vector2(16, 38)
	knock_mult = 0.25 # 무거운 돌
	kind_id = "lantern_watcher"
	display_name = "등롱 감시자"
	subtitle = "꺼지지 않는 눈"
	_visual = LanternWatcherVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_glow = LightGlow.make(EYE_OFFSET, 34.0, FLAME, 0.4)
	add_child(_glow)


func eye() -> Vector2:
	return global_position + EYE_OFFSET


## 불창의 밝기와 색 (상태마다): 그림과 주변 빛이 같이 쓴다
func window_light() -> Color:
	match state:
		S.AIM:
			var k := 1.0 - (_timer - tuning.sniper_lock_time) / (tuning.sniper_aim_time - tuning.sniper_lock_time)
			return FLAME.lerp(Palette.DANGER, clampf(k, 0.0, 1.0))
		S.LOCK:
			return Color(1, 0.95, 0.95) if int(_t * 30.0) % 2 == 0 else Palette.DANGER
		S.RELOAD:
			var k2 := clampf(1.0 - _timer / tuning.sniper_reload, 0.0, 1.0)
			return Color(0.25, 0.12, 0.1).lerp(FLAME, k2 * k2)
	return FLAME


func _ai(delta: float) -> void:
	super(delta)
	var c := window_light()
	_glow.modulate = Color(c, _glow.modulate.a) # 투명도는 LightGlow가 일렁임으로 정한다
	_glow.base_alpha = 0.15 + 0.35 * c.v
