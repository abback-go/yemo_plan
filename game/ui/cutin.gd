## cutin.gd — 대표 카드를 낼 때의 컷인 (HTML 판 cutin.js).
## 화면을 가로지르는 기울어진 띠(검붉은 바탕 + 코드로 그린 속도선·빛 궤적) 안으로 캐릭터가 미끄러져 들어왔다 빠진다.
## 탭하면 건너뛴다. 설정은 game_data.gd "cutin".
class_name Cutin
extends Node2D

var log: Array = []
var active := {}          # {"id", "root", "finish": Callable}
var _waiter: DialogBox.Waiter


func has(card_id: String) -> bool:
	var c = GameData.D.cutin.cards.get(card_id)
	return c != null and Assets.ok(c.img)


func finish_all() -> void:
	if not active.is_empty():
		active.finish.call()


func is_active() -> bool:
	return not active.is_empty()


## 탭: 건너뛰기
func skip() -> void:
	finish_all()


func play(card_id: String) -> void:
	if not has(card_id):
		return
	finish_all()
	var cfg: Dictionary = GameData.D.cutin
	var c: Dictionary = cfg.cards[card_id]
	var heavy: bool = c.get("heavy", false)
	var dur_ms: float = float(cfg.heavyDuration if heavy else cfg.duration)
	log.append(card_id)
	var b: Dictionary = cfg.band
	var cy := float(b.y) + float(b.h) / 2.0
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://ui/shaders/band_mask.gdshader")
	mat.set_shader_parameter("mid", cy)
	mat.set_shader_parameter("slant", float(b.slant))
	mat.set_shader_parameter("half_h", 0.0)
	var root := Node2D.new()
	add_child(root)
	# 띠 바탕
	var band := UI.tex_rect(UI.grad([[0, Color("#000000") if heavy else Color("#1a0006")], [0.38, Color("#2a0004") if heavy else Color("#4a0812")], [0.52, Color("#5a0008") if heavy else Color("#6a0c18")], [0.72, Color("#1a0003") if heavy else Color("#3a0510")], [1, Color("#000000") if heavy else Color("#12000a")]], "h", 256, 4), Rect2(0, float(b.y) - float(b.slant), 1920, float(b.h) + float(b.slant) * 2))
	band.material = mat
	root.add_child(band)
	var glow := UI.tex_rect(UI.grad([[0, Color(1, 0.35, 0.4, 0.18)], [1, Color(0, 0, 0, 0)]], "radial", 128, 128, Vector2(0.52, 0.5), 0.6), band.get_rect())
	glow.material = mat
	root.add_child(glow)
	# 속도선 + 빛 궤적
	var lines := []
	var n := roundi((70 if heavy else 54) * (0.6 if FX.low else 1.0))
	for i in n:
		lines.append({"y": float(b.y) - 40 + randf() * (float(b.h) + 80), "x": randf() * 2400, "len": 120 + randf() * 520, "w": 1 + randf() * 3.5, "sp": 2600 + randf() * 3200, "a": 0.15 + randf() * 0.5})
	var dirv: int = c.get("from", 1)
	var lcol := Color("#ff3a4a") if heavy else Color.WHITE
	var ccol := Color(c.get("color", "#ffffff"))
	var t0 := FX.now_ms()
	var dur := FX.ms(dur_ms)
	var fx_node := Node2D.new()
	fx_node.material = mat
	root.add_child(fx_node)
	fx_node.draw.connect(func():
		var el := (FX.now_ms() - t0)
		var k := el / dur
		for l in lines:
			var x := fposmod(float(l.x) - dirv * float(l.sp) * el / 1000.0, 2400.0) - 240.0
			fx_node.draw_rect(Rect2(x, l.y, l.len, l.w), Color(lcol.r, lcol.g, lcol.b, l.a))
		var sweep := minf(1.0, k * 2.2)
		var gx := 1920.0 - sweep * 2300.0 if dirv > 0 else -380.0 + sweep * 2300.0
		var fa := 0.55 * (1.0 - maxf(0.0, k - 0.6) / 0.4)
		for j in 8:
			var w := 380.0 * (1.0 - j / 8.0)
			fx_node.draw_rect(Rect2(gx - w, cy - 6, w * 2, 12), Color(ccol.r, ccol.g, ccol.b, fa / 8.0 * 2.0))
			fx_node.draw_rect(Rect2(gx - w, cy - 40, w * 2, 80), Color(ccol.r, ccol.g, ccol.b, 0.25 * (1.0 - k) / 8.0)))
	# 캐릭터
	var sz := Assets.size(c.img)
	var ih: float = cfg.imgH
	var iw := ih * sz.x / sz.y if sz.y > 0 else ih * 16.0 / 9.0
	var base := Vector2(float(c.at) - float(c.focus[0]) * iw, cy - float(c.focus[1]) * ih)
	var chr := Node2D.new()
	chr.material = mat
	root.add_child(chr)
	var shadow := Sprite2D.new()
	shadow.texture = Assets.tex(c.img)
	shadow.centered = false
	shadow.scale = Vector2(iw, ih) / sz
	shadow.position = Vector2(8, 10)
	shadow.modulate = Color(1, 0.08, 0.16, 0.45) if heavy else Color(0, 0, 0, 0.6)
	shadow.material = mat
	chr.add_child(shadow)
	var spr := Sprite2D.new()
	spr.texture = Assets.tex(c.img)
	spr.centered = false
	spr.scale = Vector2(iw, ih) / sz
	spr.material = mat
	chr.add_child(spr)
	# 가장자리 어둠
	var edge := UI.tex_rect(UI.grad([[0, Color(0, 0, 0, 0.7)], [0.15, Color(0, 0, 0, 0)], [0.85, Color(0, 0, 0, 0)], [1, Color(0, 0, 0, 0.7)]], "h", 256, 4), band.get_rect())
	edge.material = mat
	root.add_child(edge)
	# 타임라인(비율): 띠가 열림 → 캐릭터 들어옴 → 머묾(살짝 흐름) → 빠짐 + 띠 닫힘
	var in_x := dirv * 760.0
	var out_x := -dirv * 900.0
	var t_in := 0.22 if heavy else 0.24
	var t_hold := 0.78 if heavy else 0.74
	var drift := -dirv * (30.0 if heavy else 50.0)
	var half := float(b.h) / 2.0
	var anims := []
	anims.append(FX.anim(dur_ms, [{"o": 0.0, "h": 0.0}, {"o": 0.1, "h": half}, {"o": 0.86, "h": half}, {"o": 1.0, "h": 0.0}], func(v):
		mat.set_shader_parameter("half_h", v.h)
		fx_node.queue_redraw(), {"node": fx_node}))
	if FX.reduced:
		anims.append(FX.anim(dur_ms, [{"o": 0.0, "a": 0.0}, {"o": 0.2, "a": 1.0}, {"o": 0.8, "a": 1.0}, {"o": 1.0, "a": 0.0}], func(v): chr.modulate.a = v.a; chr.position = base, {"node": chr}))
	else:
		anims.append(FX.anim(dur_ms, [
			{"o": 0.0, "x": in_x, "a": 0.0, "e": "cubic-bezier(.15,.8,.3,1)"},
			{"o": t_in, "x": 0.0, "a": 1.0, "e": "linear"},
			{"o": t_hold, "x": drift, "a": 1.0, "e": "cubic-bezier(.6,0,.9,.4)"},
			{"o": 1.0, "x": out_x, "a": 0.0}], func(v):
				chr.position = base + Vector2(v.x, 0)
				chr.modulate.a = v.a, {"node": chr}))
	if heavy:
		# 무거운 컷인: 들어오는 순간 핏빛 섬광과 흔들림
		get_tree().create_timer(dur * t_in * 0.8 / 1000.0).timeout.connect(func():
			if not active.is_empty() and active.root == root:
				FX.flash("#5a0010", 380, 0.55)
				FX.shake(14, 420))
	var w := DialogBox.Waiter.new()
	var finish := func():
		if w.finished:
			return
		for a in anims:
			a.cancel()
		if is_instance_valid(root):
			root.queue_free()
		if not active.is_empty() and active.root == root:
			active = {}
		w.finish()
	active = {"id": card_id, "root": root, "finish": finish}
	get_tree().create_timer(dur / 1000.0).timeout.connect(finish)
	if not w.finished:
		await w.done
