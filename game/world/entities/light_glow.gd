class_name LightGlow
extends Sprite2D
## 은은한 빛 (가산 합성 원형 그라데이션). 촛불·등불·창문 빛에 쓴다. 살짝 일렁인다.

static var _tex: GradientTexture2D

var base_alpha := 0.5
var flicker := 0.08
var _t := 0.0


static func glow_texture() -> GradientTexture2D:
	if _tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.35))
		_tex = GradientTexture2D.new()
		_tex.gradient = g
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 0.5)
		_tex.width = 64
		_tex.height = 64
	return _tex


static func make(pos: Vector2, radius: float, color: Color, alpha := 0.5) -> LightGlow:
	var l := LightGlow.new()
	l.texture = glow_texture()
	l.position = pos
	l.scale = Vector2.ONE * radius / 32.0
	l.modulate = Color(color, alpha)
	l.base_alpha = alpha
	l.material = Fx.add_material
	l.z_index = 8
	return l


func _ready() -> void:
	_t = randf() * 10.0


func _process(delta: float) -> void:
	if flicker <= 0.0:
		return
	_t += delta
	modulate.a = base_alpha * (1.0 - flicker + flicker * (0.6 + 0.4 * sin(_t * 7.0) * sin(_t * 3.1)))
