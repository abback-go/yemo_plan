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
	COLOR = vec4(tint.rgb, v * strength);
}
"""

var camera: Node = null ## GameCamera가 스스로 등록한다

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
	_overlay.add_child(_vignette_rect)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	_overlay.add_child(_flash_rect)

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


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
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
	set_vignette(0.0)
	camera = null


# ─── 시간 ───────────────────────────────────────────────

## 짧게 시간을 거의 멈춘다. 실제 시간(ms) 기준이라 멈춘 동안에도 끝난다.
func hitstop(sec: float) -> void:
	if sec <= 0.0:
		return
	var until := Time.get_ticks_msec() + int(sec * 1000.0)
	if until <= _hitstop_until:
		return
	_hitstop_until = until
	Engine.time_scale = 0.03


func slowmo(scale: float, real_sec: float) -> void:
	_base_time_scale = scale
	_slowmo_until = Time.get_ticks_msec() + int(real_sec * 1000.0)
	if _hitstop_until == 0:
		Engine.time_scale = scale


# ─── 화면 ───────────────────────────────────────────────

## amplitude_t: 진폭 (T 단위, 기획서 5.8절)
func shake(amplitude_t: float, duration := 0.22) -> void:
	if camera and amplitude_t > 0.0:
		camera.shake(amplitude_t * GameConst.TILE, duration)


func flash(color: Color, duration := 0.12) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween().set_ignore_time_scale(true)
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration)


## 폭주 경고용 붉은 화면 테두리 (0 = 없음, 1 = 최대)
func set_vignette(strength: float) -> void:
	_vignette_mat.set_shader_parameter("strength", clampf(strength, 0.0, 1.0))


# ─── 이펙트 생성 ────────────────────────────────────────

func effect_parent() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return self
	var layer := scene.get_node_or_null("Effects")
	return layer if layer else scene


## 한 번 터지고 사라지는 파티클. opts로 모양을 바꾼다.
func burst(pos: Vector2, amount: int, opts := {}) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
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
	p.scale_amount_curve = _shrink_curve
	p.color_ramp = opts.get("gradient", Palette.fire_gradient())
	var box: Vector2 = opts.get("box", Vector2.ZERO)
	if box != Vector2.ZERO:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = box
	elif opts.has("radius"):
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = opts.radius
	p.z_index = opts.get("z", 5)
	effect_parent().add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## 퍼져 나가는 고리
func ring(pos: Vector2, r_from: float, r_to: float, color: Color, duration := 0.25, width := 2.0) -> void:
	var r := RingFx.new()
	r.position = pos
	r.r_from = r_from
	r.r_to = r_to
	r.color = color
	r.duration = duration
	r.width = width
	effect_parent().add_child(r)


func damage_number(pos: Vector2, value: int, heavy := false) -> void:
	var l := Label.new()
	l.text = str(value)
	l.label_settings = _label_settings_heavy if heavy else _label_settings
	l.position = pos + Vector2(randf_range(-4, 4) - 6, -8)
	l.z_index = 20
	effect_parent().add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - (16.0 if heavy else 11.0), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.25).set_delay(0.3)
	t.tween_callback(l.queue_free)
