extends Node
## 타격감 연출 모음: 히트스톱, 슬로모션, 화면 흔들림, 화면 번쩍임, 확대 펀치.
## 어디서든 Fx.hitstop(0.06)처럼 부른다.
## 에스카 프로젝트(cc/vigilant-dirac-751x7b, game/autoload/fx.gd)에서 이 프로토타입이 쓰는 부분만 옮겼다
## (위치 타임·폭주 테두리·파티클 burst·고리·피해 숫자 라벨은 뺌). 글꼴 대체(ThemeDB.fallback_font)도 여기서 갈무리로 맞춘다.

const TILE := 16.0
const FONT_PATH := "res://fonts/Galmuri11-subset.ttf"

var camera: Node = null ## PCamera가 스스로 등록한다
var add_material: CanvasItemMaterial ## 가산 합성(빛이 겹칠수록 밝아짐)
## 시험 실행기만 켠다(환경 변수 FRAME_CLOCK=1): 히트스톱·슬로모션을 실제 시간 대신 프레임 수(60fps)로 잰다. 게임에서는 늘 false.
var frame_clock := false

var _base_time_scale := 1.0
var _hitstop_until := 0
var _slowmo_until := 0
var _overlay: CanvasLayer
var _flash_rect: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = 50
	add_child(_overlay)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	_overlay.add_child(_flash_rect)
	add_material = CanvasItemMaterial.new()
	add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var font := load(FONT_PATH) as Font
	if font != null:
		ThemeDB.fallback_font = font # 피해 숫자(PVfx.Numbers) 등 기본 글꼴을 쓰는 곳도 한글이 나오게


## 시간 효과가 쓰는 현재 시각 (ms). 시험(FRAME_CLOCK=1)에서는 프레임 수 기준
func now_ms() -> int:
	if frame_clock:
		return Engine.get_process_frames() * 1000 / 60
	return Time.get_ticks_msec()


func _process(_delta: float) -> void:
	var now := now_ms()
	if _slowmo_until > 0 and now >= _slowmo_until:
		_slowmo_until = 0
		_base_time_scale = 1.0
		if _hitstop_until == 0:
			Engine.time_scale = 1.0
	if _hitstop_until > 0 and now >= _hitstop_until:
		_hitstop_until = 0
		Engine.time_scale = _base_time_scale


## 씬이 바뀔 때 시간·화면 효과를 원래대로
func reset() -> void:
	_hitstop_until = 0
	_slowmo_until = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0
	_flash_rect.color.a = 0.0
	camera = null


# ─── 시간 ───────────────────────────────────────────────

## 짧게 시간을 거의 멈춘다. 실제 시간(ms) 기준이라 멈춘 동안에도 끝난다.
func hitstop(sec: float) -> void:
	if sec <= 0.0:
		return
	var until := now_ms() + int(sec * 1000.0)
	if until <= _hitstop_until:
		return
	_hitstop_until = until
	Engine.time_scale = 0.03


func slowmo(scale: float, real_sec: float) -> void:
	_base_time_scale = scale
	_slowmo_until = now_ms() + int(real_sec * 1000.0)
	if _hitstop_until == 0:
		Engine.time_scale = scale


# ─── 화면 ───────────────────────────────────────────────

## 큰 타격 때 카메라를 순간 확대했다가 되돌림
func zoom_punch(amount: float) -> void:
	if camera and amount > 0.0:
		camera.punch(amount)


## amplitude_t: 진폭 (타일 단위)
func shake(amplitude_t: float, duration := 0.22) -> void:
	if camera and amplitude_t > 0.0:
		camera.shake(amplitude_t * TILE, duration)


func flash(color: Color, duration := 0.12) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween().set_ignore_time_scale(true)
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration)


# ─── 이펙트 생성 ────────────────────────────────────────

func effect_parent() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return self
	var layer := scene.get_node_or_null("Effects")
	return layer if layer else scene
