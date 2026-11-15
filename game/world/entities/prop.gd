class_name Prop
extends Node2D
## 장식 소품 (코드 그래픽). 원점은 바닥(발밑) 기준이고, 매달린 것(샹들리에·등롱·사슬)은 천장 기준.
## 공통 키: w, h(타일), flip, front(전경), col(색), glow(빛 세기). kind별 그림은 소품 모듈에 있다:
##   1장 world/entities/base_props.gd, 2장부터 world/entities/<장>/props.gd (ChapterRegistry.prop_scripts()).
## 모듈마다 `const PROPS := {kind: {anim, glow, split}}` 표 하나에 kind를 등록하고 `static func draw(p, kind)`에서 그린다
## (docs/dev/world.md "소품 kind 추가"). 여기서 모든 표를 한 번 합쳐 kind → 모듈 사전을 만든다.
##
## 성능 (웹 단일 스레드에서 소품이 매 프레임 수천 개의 그리기 명령을 만들던 문제):
##   - 움직이지 않는 소품(anim 아님)은 _process를 끈다 — 처음 한 번만 그림.
##   - 움직이는 소품은 시간(_t)은 계속 흐르되, 화면(+여유) 밖이면 다시 그리지 않는다.
##     Godot는 화면 밖이어도 queue_redraw하면 _draw를 실행한다(렌더 컬링은 그 뒤 단계).
##   - split 소품은 정적 부분을 이 노드에 한 번 그리고, 움직이는 부분만 자식 Prop(layer = LAYER_ANIM)이 다시 그린다.

const LAYER_ALL := 0 ## 전부 그림 (보통)
const LAYER_STATIC := 1 ## split 소품의 정적 부분 (이 노드, 한 번만)
const LAYER_ANIM := 2 ## split 소품의 움직이는 부분 (자식 노드, 매 프레임)
const BASE_PROPS := preload("res://world/entities/base_props.gd")
const VIEW_MARGIN := 32.0 ## 화면 사각형 여유(px) — 카메라가 한 프레임에 이보다 많이 움직이면 가장자리 한 프레임이 늦게 갱신될 수 있음

static var _kinds := {} ## kind → {script, anim, glow, split, vflip} (모든 소품 모듈의 PROPS를 합친 것)
static var _view := Rect2()
static var _view_frame := -1

var kind := ""
var w := 1.0
var h := 1.0
var params := {}
var theme := {}
var anchor := Vector2.ZERO ## 방 안 위치 (그림의 시드·위상용 — 움직임 층 자식도 부모 위치를 그대로 씀)
var layer := LAYER_ALL
var _t := 0.0
var _animated := false
var _glow: LightGlow
var _mod: Variant = null ## 이 kind를 그리는 소품 모듈 (GDScript — static draw를 부름)
var _reach := Vector2.ZERO ## 그림이 닿을 수 있는 반경(대략, 넉넉히) — 화면 밖 판정용


## kind 정보 (없으면 빈 사전). 처음 부를 때 모든 소품 모듈의 PROPS를 합친다 — 앞 모듈이 이김(1장 → sys → ch2 → …)
static func kind_info(k: String) -> Dictionary:
	if _kinds.is_empty():
		var mods: Array = [BASE_PROPS]
		mods.append_array(ChapterRegistry.prop_scripts())
		for m: GDScript in mods:
			var consts := m.get_script_constant_map()
			var table: Dictionary = consts.get("PROPS", {})
			var defaults: Dictionary = consts.get("DEFAULTS", {})
			for key in table:
				if _kinds.has(key):
					continue
				var info: Dictionary = defaults.duplicate()
				info.merge(table[key], true)
				info["script"] = m
				_kinds[key] = info
	return _kinds.get(k, {})


func setup(room: Room, e: Dictionary) -> void:
	kind = String(e.get("kind", ""))
	w = float(e.get("w", 1))
	h = float(e.get("h", 1))
	params = e
	theme = room.theme
	position = room.tile_pos(e) + Vector2(8, 0)
	anchor = position
	z_index = 20 if bool(e.get("front", false)) else -3
	if bool(e.get("flip", false)):
		scale.x = -1
	_t = randf() * 6.0
	var info := kind_info(kind)
	_mod = info.get("script", null)
	_animated = bool(info.get("anim", false))
	if bool(info.get("vflip", false)) and bool(e.get("vflip", false)):
		scale.y = -1.0
	var g: Variant = info.get("glow", null)
	if g is StringName:
		g = _mod.call(g, self)
	if g is Array and g.size() == 3 and float(g[1]) > 0.0:
		var col: Variant = g[2]
		_glow = LightGlow.make(g[0], float(g[1]), Color(theme.accent) if col == null else col, float(e.get("glow", 0.45)))
		_glow.z_index = 9
		add_child(_glow)
	_reach = Vector2(maxf(w, 2.0) * 16.0 + 96.0,
		(maxf(h, 2.0) + float(e.get("len", 0)) + float(e.get("sag", 0))) * 16.0 + 128.0)
	if _animated and bool(info.get("split", false)):
		_add_anim_layer()


## _process가 있으면 Godot가 준비될 때 처리를 켜므로 여기서 끈다 (setup에서 끄면 다시 켜짐)
func _ready() -> void:
	set_process(_animated)


## split 소품: 움직이는 부분만 그리는 자식 Prop. 정적 부분(이 노드)은 다시 그리지 않는다.
## 자식은 setup을 거치지 않는다(randf·빛을 다시 만들지 않게 — 전역 난수 순서가 그대로).
func _add_anim_layer() -> void:
	var a := Prop.new()
	a.name = "Anim"
	a.kind = kind
	a.w = w
	a.h = h
	a.params = params
	a.theme = theme
	a.anchor = anchor
	a.layer = LAYER_ANIM
	a._t = _t
	a._animated = true
	a._mod = _mod
	a._reach = _reach
	add_child(a)
	layer = LAYER_STATIC
	_animated = false


## 장별 소품 그림이 쓰는 시간 (초)
func time() -> float:
	return _t


## 소품 그림 함수가 이 층에서 정적 부분 / 움직이는 부분을 그려야 하나 (split 소품만 신경 씀)
func static_part() -> bool:
	return layer != LAYER_ANIM


func anim_part() -> bool:
	return layer != LAYER_STATIC


func _process(delta: float) -> void:
	_t += delta
	if near_view(self, Rect2(global_position - _reach, _reach * 2.0)):
		queue_redraw()


## 지금 화면(+VIEW_MARGIN)과 rect(월드 좌표)가 겹치나. 화면 사각형은 프레임마다 한 번만 계산한다.
## 움직이는 그림을 화면 밖에서 다시 그리지 않으려는 곳(소품·상승 기류)이 같이 쓴다. item은 기본 캔버스(층 0)에 있어야 함.
static func near_view(item: CanvasItem, rect: Rect2) -> bool:
	var f := Engine.get_process_frames()
	if f != _view_frame:
		_view_frame = f
		var vp := item.get_viewport()
		_view = (vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(VIEW_MARGIN)
	return _view.intersects(rect)


## 선(draw_line)을 삼각형 배열로 묶어 그릴 때 쓸 꼭짓점 색. draw_line은 색을 반정밀도(half float)로 렌더러에 넘기고
## 삼각형 배열은 32비트 그대로라, 그대로 쓰면 화면 밝기 보정(CanvasModulate 등)과 곱해질 때 1 차이가 난다.
static func line_color(c: Color) -> Color:
	var b := PackedByteArray()
	b.resize(2)
	var out := Color()
	for i in 4:
		b.encode_half(0, c[i])
		out[i] = b.decode_half(0)
	return out


func _draw() -> void:
	if _mod:
		_mod.draw(self, kind)
