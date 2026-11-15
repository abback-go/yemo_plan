## Assets (autoload) — 그림·글꼴 불러오기. 그림은 res://assets/ (prototype/assets 를 복사, 웹 배포용 손실 압축으로 가져옴).
## 그림은 쓸 때 불러오고(load), 쓰는 노드가 사라지면 엔진이 메모리에서 내린다 → 휴대폰 메모리 절약.
extends Node

const DIR := "res://assets/"

var _sizes := {}
var _fonts := {}


func _ready() -> void:
	_fonts.sans = load(DIR + "fonts/sans.tres")
	_fonts.sans_bold = load(DIR + "fonts/sans_bold.tres")
	_fonts.sans_black = load(DIR + "fonts/sans_black.tres")
	_fonts.serif = load(DIR + "fonts/NotoSerifKR-KS-Regular.ttf")
	_fonts.serif_bold = load(DIR + "fonts/NotoSerifKR-KS-Bold.ttf")
	var black := FontVariation.new()
	black.base_font = _fonts.serif_bold
	black.variation_embolden = 0.55
	_fonts.serif_black = black
	var wide := FontVariation.new()
	wide.base_font = black
	wide.spacing_glyph = 10
	_fonts.serif_wide = wide


func font(kind: String) -> Font:
	return _fonts.get(kind, _fonts.sans)


func ok(name: String) -> bool:
	return name != "" and ResourceLoader.exists(DIR + name)


func tex(name: String) -> Texture2D:
	if not ok(name):
		return null
	var t: Texture2D = load(DIR + name)
	if t and not _sizes.has(name):
		_sizes[name] = t.get_size()
	return t


## 그림 크기(원본 픽셀). 없으면 Vector2.ZERO
func size(name: String) -> Vector2:
	if _sizes.has(name):
		return _sizes[name]
	var t := tex(name)
	return t.get_size() if t else Vector2.ZERO


## 표정 이름(예: "hero_smile") → 그림 파일 이름
func expression_file(face) -> String:
	if face == null or str(face) == "":
		return ""
	return str(GameData.D.expressions.file).replace("{name}", str(face))


## 얼굴을 잘라 보여 줄 그림과 영역. face(표정 이름)가 있고 그 그림이 있으면 표정 그림, 없으면 스탠딩에서 잘라 쓴다.
## 반환: {"tex": Texture2D, "rect": Rect2} 또는 {}
func face_region(who: String, face = null, large := false, zoom := 1.0) -> Dictionary:
	var E: Dictionary = GameData.D.expressions
	var file := expression_file(face)
	var f := {}
	if file != "" and ok(file):
		var ch := str(face).split("_")[0]
		var crops: Dictionary = E.cropLarge if large else E.crop
		var c: Dictionary = crops.get(ch, E.crop.get(ch, {}))
		if c.is_empty():
			return {}
		f = {"img": file, "cx": c.cx, "cy": c.cy, "size": c.size}
	else:
		var fw = GameData.D.faces.get(who)
		if fw == null:
			return {}
		f = fw
	var t := tex(f.img)
	if t == null:
		return {}
	var s: float = float(f.size) / zoom
	return {"tex": t, "rect": Rect2(float(f.cx) - s / 2.0, float(f.cy) - s / 2.0, s, s)}
