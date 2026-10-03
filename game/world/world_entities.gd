class_name WorldEntities
extends RefCounted
## 방 데이터의 특수 개체(퍼즐 장치 등) 종류 이름 → 스크립트. Room._spawn_entity의 기본 목록에 없는 것들.

const KINDS := {
	"target": "res://world/entities/practice_target.gd", ## 실습장 움직이는 과녁
	"float_lantern": "res://world/entities/float_lantern.gd", ## 부양 실습 등불
	"switch": "res://world/entities/candle_switch.gd", ## 시간 문 촛대 스위치
	"actor": "res://story/actor.gd", ## 컷신 전용 등장물(너울 본모습 등)
	"puzzle": "res://world/entities/brazier_puzzle.gd", ## 봉화 퍼즐 처리기
	"chaser": "res://world/entities/collapse_chaser.gd", ## 붕괴 회랑 추격
	"hint_mural": "res://world/entities/hint_mural.gd", ## 여우창문으로만 보이는 벽화
	"calm": "res://world/entities/calm_zone.gd", ## 봉인 결계: 안에서는 폭주 게이지가 오르지 않음
	"event": "res://world/entities/flag_event.gd", ## 플래그가 서면 대본 실행
	"cracked": "res://world/entities/cracked_wall.gd", ## 금 간 벽: 폭발(슬라임 자폭·폭주 폭발)로만 부서짐
	"updraft": "res://world/entities/updraft.gd", ## 상승 기류: 불꽃 날개 활공 중 위로 (docs/systems2.md 6절)
	"warp": "res://world/entities/warp_circle.gd", ## 전이진: 해금된 지역으로 이동
	"class_board": "res://world/entities/class_board.gd", ## 수업 게시판: 마법 배우기 창
}


static func make(t: String, room: Room, e: Dictionary, eid: String) -> Node:
	var path: String = KINDS.get(t, ChapterRegistry.entity_kinds().get(t, ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	var n: Node = (load(path) as GDScript).new()
	if n.has_method("setup"):
		n.setup(room, e, eid)
	return n
