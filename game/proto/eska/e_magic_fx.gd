class_name EMagicFx
extends RefCounted
## 에스카 낙성(↓+고급) · 대마법 4종 중 셋(흑성·유성우·종말의 운석)의 연출과 판정. 봉공은 EStill (e_still.gd).
## 기준서: docs/eska/design.md 3장. 만드는 쪽(EEska)은 노드를 만들어 eska·dir를 넣고 EVfx.add(노드, 에스카 발 위치, false)로 붙이기만 한다.
## 노드는 스스로 판정(eska.deal)·소리·화면 효과를 처리하고 끝나면 사라진다.
## 대마법 피해는 종언 게이지를 채우지 않게 eska.deal(..., {"ult": true})로 준다.
## 범위는 eska.mods.size(확장 물약)를 곱한다.


## 낙성: 앞쪽 하늘을 찢어 별 조각 6개가 비스듬히 쏟아짐 (6×60)
class Nakseong extends Node2D:
	var eska: EEska
	var dir := 1

	func _ready() -> void:
		queue_free() # 틀만 — 담당 작업자가 채운다


## 흑성: 앞 150px에 검은 별이 2초 동안 끌어당기며 갈다가 붕괴 (30×20 + 1500)
class BlackStar extends Node2D:
	var eska: EEska
	var dir := 1

	func _ready() -> void:
		queue_free()


## 유성우: 하늘이 길게 찢어지고 유성 12개가 1.6초 동안 앞쪽 400px 안으로 (12×180)
class MeteorShower extends Node2D:
	var eska: EEska
	var dir := 1

	func _ready() -> void:
		queue_free()


## 종말의 운석: 가장 가까운 적 위 큰 틈에서 거대한 운석이 1.1초 걸려 떨어짐, 반경 120 (3600)
class DoomMeteor extends Node2D:
	var eska: EEska
	var dir := 1

	func _ready() -> void:
		queue_free()
