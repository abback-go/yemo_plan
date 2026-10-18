extends SceneTree
## 마법 아이콘 전체 시트 (검증용): 마녀 12 × (기본 + 마법 10), 속성 색. 큰 판(바퀴 r 8.7) + 고른 칸(LAV 바탕, INK) 두 가지로 그려 한눈에 확인.
## 창 크기(프로젝트 640×360)에 묶이지 않게 SubViewport 1280×820에 그려 저장한다.
##   cd game && FRAME_CLOCK=1 xvfb-run -a -s "-screen 0 1280x820x24" godot --rendering-driver opengl3 --script ../tools/test/icon_sheet.gd -- <out.png>

const W := 1280
const H := 820


class Sheet:
	extends Node2D
	var font: Font

	func _draw() -> void:
		draw_rect(Rect2(0, 0, W, H), Color("#1a1026"))
		var y := 14.0
		for wid in TData.ROSTER:
			var w: Dictionary = TData.WITCHES[wid]
			var col: Color = TData.ELEMENT_COLOR.get(w.element, Color("#b9a2ff"))
			draw_string(font, Vector2(8, y + 24), String(w.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e6dcff"))
			var x := 70.0
			var ids: Array = ["basic"]
			ids.append_array(w.skills)
			for sid in ids:
				var icon := "strike"
				var name := String(w.basic.name)
				if sid != "basic":
					icon = String(TData.SKILLS[sid].icon)
					name = String(TData.SKILLS[sid].name)
				draw_circle(Vector2(x + 20, y + 20), 19.0, Color("#14081f"))
				draw_arc(Vector2(x + 20, y + 20), 19.0, 0.0, TAU, 28, Color(col, 0.7), 1.0)
				TIcon.draw(self, Vector2(x + 20, y + 17.5), icon, col, 8.7)
				draw_circle(Vector2(x + 56, y + 20), 12.0, Color("#b9a2ff"))
				TIcon.draw(self, Vector2(x + 56, y + 20), icon, Color("#14081f"), 7.5)
				draw_string(font, Vector2(x, y + 54), name, HORIZONTAL_ALIGNMENT_LEFT, 106, 8, Color("#e6dcff", 0.85))
				x += 110
			y += 67


var _n := 0
var _vp: SubViewport


func _initialize() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(W, H)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.transparent_bg = false
	var sheet := Sheet.new()
	sheet.font = load("res://assets/fonts/Galmuri11.ttf")
	_vp.add_child(sheet)
	root.add_child(_vp)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 8:
		var img := _vp.get_texture().get_image()
		var args := OS.get_cmdline_user_args()
		img.save_png(args[0] if args.size() > 0 else "icon_sheet.png")
		print("SHEET SAVED ", img.get_size())
		return true
	return false
