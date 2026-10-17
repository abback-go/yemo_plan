class_name RoomData
extends RefCounted
## 방 하나의 데이터 (docs/archive/sera/chapter1.md 4.1절). 방마다 world/rooms/<id>.gd 가 이 클래스를 상속해 _init()에서 값을 채운다.
##
## map: ASCII 지도. 1글자 = 1타일(16px). 화면 1칸 = 40×23타일.
##   #  벽·바닥 (지역 스타일로 그림)        =  통과 발판 (아래에서 뛰어오를 수 있음)
##   ^  가시·불꽃 (1 피해 + 직전 안전 지점으로)
##   I  환영 벽 (여우창문으로 정체가 드러나면 사라짐)
##   H  숨은 발판 (여우창문으로 드러나면 생김)
##   W  부서지는 나무 벽·거미줄 (불로 태우면 사라짐)
##   .  빈칸 (공백도 빈칸)
##
## entities: 개체 목록. 좌표 x, y는 타일 단위. 서 있는 것(NPC·문·기록 지점 등)의 y는 **발이 닿는 바닥 타일의 행 번호**.
##   공통 키: t(종류), id, cond("플래그,!플래그" 모두 만족할 때만 생성)
##   exit   {x,y,w,h, to, to_id}           방 가장자리 출구 (걸어서 나감)
##   door   {x,y, to, to_id, label, style, lock, lock_msg}   ↑로 드나드는 문·계단
##   spawn  {x,y, face}                     이름 붙은 등장 위치 (새 게임 시작, 컷신)
##   save   {x,y, style}                    기록 지점
##   npc    {x,y, who, face, talk}          인물 (talk: 대화 스크립트 ID)
##   enemy  {x,y, kind, face, ...}          적 (처치하면 다시 나오지 않음)
##   trigger{x,y,w,h, run, once}            영역에 들어가면 컷신·안내 실행
##   pickup {x,y, kind}                     줍는 물건
##   sign   {x,y, text}                     읽을 수 있는 것 (게시판·책·비석)
##   prop   {x,y, kind, ...}                장식
##   light  {x,y, r, color}                 은은한 빛
##   brazier{x,y, group, order}             봉화 (불로 켜는 퍼즐)
##   gate   {x,y,w,h, open_if}              플래그가 서면 열리는 막힌 곳

var id := ""
var title := "" ## 지역 이름 표시용
var area := "school" ## 지도 지역: shingye(신계) / school(학교)
var theme := "hall" ## 배경·타일 그림 스타일 (world/themes)
var music := "school"
var cell := Vector2i.ZERO ## 지도 칸 좌표
var cells := Vector2i.ONE ## 지도 칸 크기
var map := ""
var entities: Array = []
var dark := 0.0 ## 방 전체 어둡기 0~1 (지하 등)
var no_pet_comment := false

var _rows: PackedStringArray


func rows() -> PackedStringArray:
	if _rows.is_empty():
		var lines := map.split("\n")
		var out := PackedStringArray()
		for l in lines:
			if l.strip_edges() == "" and out.is_empty():
				continue
			out.append(l)
		while out.size() > 0 and out[out.size() - 1].strip_edges() == "":
			out.remove_at(out.size() - 1)
		var w := 0
		for l in out:
			w = maxi(w, l.length())
		for i in out.size():
			out[i] = out[i].rpad(w, ".")
		_rows = out
	return _rows


func cols() -> int:
	var r := rows()
	return r[0].length() if r.size() > 0 else 0


func row_count() -> int:
	return rows().size()


func char_at(x: int, y: int) -> String:
	var r := rows()
	if y < 0 or y >= r.size() or x < 0 or x >= r[y].length():
		return "#" # 바깥은 벽 취급 (타일 그리기에서 테두리가 끊기지 않게)
	return r[y][x]


func size_px() -> Vector2:
	return Vector2(cols(), row_count()) * GameConst.TILE


## 개체 조건 검사: "a,!b" → a 플래그가 서 있고 b는 없을 때. 해석은 Cond.ok 하나 (core/cond.gd — 문법 설명)
static func cond_ok(cond: String) -> bool:
	return Cond.ok(cond)
