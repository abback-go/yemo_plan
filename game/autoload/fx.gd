extends Node
## 타격감 연출 모음: 히트스톱, 슬로모션, 화면 흔들림, 화면 번쩍임, 폭주 테두리, 파티클, 고리, 피해 숫자.
## 어디서든 Fx.hitstop(0.06)처럼 부른다.

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.15, 0.1, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.7778, 1.0);
	float d = length(p);
	float v = smoothstep(0.42, 1.0, d);
	COLOR = vec4(tint.rgb, v * strength * 0.8);
}
"""

const WITCH_TINT := Color(0.66, 0.58, 1.0) ## 위치 타임 중 화면에 곱하는 색

var camera: Node = null ## GameCamera가 스스로 등록한다
var add_material: CanvasItemMaterial ## 가산 합성(빛이 겹칠수록 밝아짐) — 불 이펙트 공용
var enemy_time := 1.0 ## 위치 타임 중 적·적 탄의 시간 배율 (세라는 정상 속도)
## 시험 실행기만 켠다(환경 변수 FRAME_CLOCK=1): 히트스톱·슬로모션·위치 타임을 실제 시간 대신 프레임 수(60fps)로 잰다.
## 실제 시간으로 재면 컴퓨터가 바쁠 때 멈춤이 짧아져 같은 시나리오도 결과가 달라진다. 게임에서는 늘 false.
var frame_clock := false

var _base_time_scale := 1.0
var _hitstop_until := 0
var _slowmo_until := 0
var _overlay: CanvasLayer
var _flash_rect: ColorRect
var _vignette_rect: ColorRect
var _vignette_mat: ShaderMaterial
var _flash_tween: Tween
var _shrink_curve: Curve
var _label_settings: LabelSettings
var _label_settings_heavy: LabelSettings
var _label_settings_fox: LabelSettings
var _witch_until := 0
var _tint_rect: ColorRect
## 다 터진 burst 파티클을 버리지 않고 모아 두었다가 다시 쓴다 (단일 스레드 웹에서 노드 생성·해제 비용 절약)
var _burst_pool: Array[CPUParticles2D] = []
const BURST_POOL_MAX := 96


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = CanvasLayer.new()
	_overlay.layer = 50
	add_child(_overlay)

	_vignette_rect = ColorRect.new()
	_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = shader
	_vignette_rect.material = _vignette_mat
	_vignette_rect.visible = false # 세기 0이면 숨겨 전체 화면 셰이더를 돌리지 않는다
	_overlay.add_child(_vignette_rect)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	_overlay.add_child(_flash_rect)

	# 위치 타임 색조: 게임 화면 위·HUD 아래 층에서 곱하기 합성 (밝기는 살리고 보라빛만 입힘)
	var tint_layer := CanvasLayer.new()
	tint_layer.layer = 2
	add_child(tint_layer)
	_tint_rect = ColorRect.new()
	_tint_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint_rect.color = Color.WHITE
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_tint_rect.material = mul
	_tint_rect.visible = false
	tint_layer.add_child(_tint_rect)

	add_material = CanvasItemMaterial.new()
	add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_shrink_curve = Curve.new()
	_shrink_curve.add_point(Vector2(0.0, 1.0))
	_shrink_curve.add_point(Vector2(1.0, 0.0))

	_label_settings = LabelSettings.new()
	_label_settings.font_size = 12
	_label_settings.font_color = Palette.FIRE_HOT
	_label_settings.outline_size = 4
	_label_settings.outline_color = Color("#1a0d10")
	_label_settings_heavy = _label_settings.duplicate()
	_label_settings_heavy.font_color = Palette.FIRE_CORE
	_label_settings_fox = _label_settings.duplicate()
	_label_settings_fox.font_color = Color(0.6, 0.88, 1.0)


## 시간 효과가 쓰는 현재 시각 (ms)
func _now_ms() -> int:
	if frame_clock:
		return Engine.get_process_frames() * 1000 / 60
	return Time.get_ticks_msec()


func _process(_delta: float) -> void:
	var now := _now_ms()
	if _slowmo_until > 0 and now >= _slowmo_until:
		_slowmo_until = 0
		_base_time_scale = 1.0
		if _hitstop_until == 0:
			Engine.time_scale = 1.0
	if _hitstop_until > 0 and now >= _hitstop_until:
		_hitstop_until = 0
		Engine.time_scale = _base_time_scale
	if _witch_until > 0:
		var left := float(_witch_until - now) / 1000.0
		if left <= 0.0:
			_witch_until = 0
			enemy_time = 1.0
			_tint_rect.visible = false
		else:
			_set_tint(clampf(left / 0.3, 0.0, 1.0))


## 방을 옮기거나 부활할 때: 시간·화면 효과만 원래대로 (카메라 등록은 유지)
func reset_time() -> void:
	var cam: Node = camera
	reset()
	camera = cam


## 씬이 바뀔 때 시간·화면 효과를 원래대로
func reset() -> void:
	_hitstop_until = 0
	_slowmo_until = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0
	_flash_rect.color.a = 0.0
	set_vignette(0.0)
	camera = null
	_witch_until = 0
	enemy_time = 1.0
	_tint_rect.visible = false


# ─── 시간 ───────────────────────────────────────────────

## 짧게 시간을 거의 멈춘다. 실제 시간(ms) 기준이라 멈춘 동안에도 끝난다.
func hitstop(sec: float) -> void:
	if sec <= 0.0:
		return
	var until := _now_ms() + int(sec * 1000.0)
	if until <= _hitstop_until:
		return
	_hitstop_until = until
	Engine.time_scale = 0.03


func slowmo(scale: float, real_sec: float) -> void:
	_base_time_scale = scale
	_slowmo_until = _now_ms() + int(real_sec * 1000.0)
	if _hitstop_until == 0:
		Engine.time_scale = scale


# ─── 화면 ───────────────────────────────────────────────

## 위치 타임: 적과 적의 탄만 느려진다 (세라는 정상 속도). 실제 시간 기준.
func witch_time(scale: float, real_sec: float) -> void:
	enemy_time = scale
	_witch_until = _now_ms() + int(real_sec * 1000.0)
	_set_tint(1.0)


func _set_tint(strength: float) -> void:
	_tint_rect.visible = strength > 0.0
	_tint_rect.color = Color.WHITE.lerp(WITCH_TINT, strength)


func is_witch_time() -> bool:
	return _witch_until > 0


## 큰 타격 때 카메라를 순간 확대했다가 되돌림
func zoom_punch(amount: float) -> void:
	if camera and amount > 0.0:
		camera.punch(amount)


## amplitude_t: 진폭 (T 단위, 기획서 5.8절)
func shake(amplitude_t: float, duration := 0.22) -> void:
	if camera and amplitude_t > 0.0 and GameState.settings.get("shake", true):
		camera.shake(amplitude_t * GameConst.TILE, duration)


func flash(color: Color, duration := 0.12) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween().set_ignore_time_scale(true)
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration)


## 폭주 경고용 붉은 화면 테두리 (0 = 없음, 1 = 최대)
func set_vignette(strength: float) -> void:
	var s := clampf(strength, 0.0, 1.0)
	_vignette_mat.set_shader_parameter("strength", s)
	_vignette_rect.visible = s > 0.0


# ─── 이펙트 생성 ────────────────────────────────────────

func effect_parent() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return self
	var layer := scene.get_node_or_null("Effects")
	return layer if layer else scene


## 한 번 터지고 사라지는 파티클. opts로 모양을 바꾼다.
## 다 터진 노드는 풀에 돌아가 다음 burst에서 restart()로 다시 쓰인다 — 그래서 반환값을 붙잡아 두거나 고치지 말 것.
## 전역 난수(Math::rand) 소비는 새로 만들 때와 같다: 새 노드는 생성자가, 다시 쓰는 노드는 restart()가 시드를 한 번 뽑는다.
## 그래서 다른 무작위 동작(적 AI 등)도 풀을 쓰기 전과 똑같다.
func burst(pos: Vector2, amount: int, opts := {}) -> CPUParticles2D:
	var p: CPUParticles2D = null
	while p == null and not _burst_pool.is_empty():
		p = _burst_pool.pop_back()
		if not is_instance_valid(p):
			p = null
	var reused := p != null
	if not reused:
		p = CPUParticles2D.new()
		p.one_shot = true
		p.scale_amount_curve = _shrink_curve
		p.finished.connect(_recycle_burst.bind(p))
	p.position = pos
	p.amount = maxi(amount, 1)
	p.explosiveness = opts.get("explosiveness", 1.0)
	p.lifetime = opts.get("lifetime", 0.4)
	p.lifetime_randomness = opts.get("lifetime_random", 0.4)
	p.direction = opts.get("direction", Vector2.UP)
	p.spread = opts.get("spread", 180.0)
	p.initial_velocity_min = opts.get("speed_min", 40.0)
	p.initial_velocity_max = opts.get("speed_max", 120.0)
	p.gravity = opts.get("gravity", Vector2(0, 160))
	p.damping_min = opts.get("damping", 0.0)
	p.damping_max = opts.get("damping", 0.0)
	p.scale_amount_min = opts.get("size_min", 1.0)
	p.scale_amount_max = opts.get("size_max", 2.5)
	var grad: Variant = opts.get("gradient")
	p.color_ramp = grad if grad != null else Palette.fire_gradient()
	var box: Vector2 = opts.get("box", Vector2.ZERO)
	if box != Vector2.ZERO:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = box
	elif opts.has("radius"):
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = opts.radius
	else:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	p.z_index = opts.get("z", 5)
	# 불꽃은 기본으로 가산 합성
	p.material = add_material if opts.get("add", opts.get("gradient") == null) else null
	if reused:
		# 트리 밖에서 restart: 새 노드처럼 첫 갱신이 트리에 들어간 뒤 일어나 첫 프레임 진행이 같다
		p.restart()
	effect_parent().add_child(p)
	p.emitting = true
	return p


## 끝날 때 풀에 남은(트리 밖) 파티클을 지운다 — 안 그러면 종료 시 자원 누수 오류가 찍힌다
func _exit_tree() -> void:
	for p in _burst_pool:
		if is_instance_valid(p):
			p.free()
	_burst_pool.clear()


## 다 터진 burst를 부모에서 떼어 풀에 넣는다 (finished 신호 안에서 바로 떼지 않고 지연 호출)
func _recycle_burst(p: CPUParticles2D) -> void:
	_return_burst.call_deferred(p)


func _return_burst(p: CPUParticles2D) -> void:
	if not is_instance_valid(p) or p.is_queued_for_deletion() or p.emitting:
		return
	if p.get_parent():
		p.get_parent().remove_child(p)
	if _burst_pool.size() < BURST_POOL_MAX:
		_burst_pool.append(p)
	else:
		p.free()


## 퍼져 나가는 고리
func ring(pos: Vector2, r_from: float, r_to: float, color: Color, duration := 0.25, width := 2.0, additive := true) -> void:
	var r := RingFx.new()
	if additive:
		r.material = add_material
	r.position = pos
	r.r_from = r_from
	r.r_to = r_to
	r.color = color
	r.duration = duration
	r.width = width
	effect_parent().add_child(r)


func damage_number(pos: Vector2, value: int, heavy := false, fox := false) -> void:
	var l := Label.new()
	l.text = str(value)
	l.label_settings = (_label_settings_fox if fox else (_label_settings_heavy if heavy else _label_settings))
	l.position = pos + Vector2(randf_range(-4, 4) - 6, -8)
	l.z_index = 20
	effect_parent().add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - (16.0 if heavy else 11.0), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.25).set_delay(0.3)
	t.tween_callback(l.queue_free)
