extends RefCounted
## 3장 방 개체 종류 → 스크립트 (WorldEntities가 합침). 스크립트는 setup(room, e, eid) — docs/chapter3.md 7.3절

const KINDS := {
	"sniper_cover_arrows": "res://world/entities/ch3/sniper_cover_arrows.gd", ## 저격 구간: 예고선이 세라를 따라옴, 지형 뒤에 숨어 전진
	"wind_valve": "res://world/entities/ch3/wind_valve.gd", ## 바람 밸브: 불로 돌려 플래그 켜고 끔 (updraft on_if / crosswind on_if)
	"crosswind": "res://world/entities/ch3/crosswind.gd", ## 옆바람: 공중의 세라를 옆으로 밀어 줌
	"blight_vine": "res://world/entities/ch3/blight_vine.gd", ## 흰 역병 덩굴: 불로 정화해 길을 엶
	"glow_mushroom": "res://world/entities/ch3/glow_mushroom.gd", ## 빛버섯: 불로 켜는 봉화 (puzzle 처리기와 함께, 순서 퍼즐)
	"moon_drop": "res://world/entities/ch3/moon_drop.gd", ## 달샘의 달빛 방울: 방벽으로 되쏘면 위로
	"moon_crystal": "res://world/entities/ch3/moon_crystal.gd", ## 달빛 수정: 되쏜 달빛에만 켜짐 (puzzle mode=all)
	"archery_mark": "res://world/entities/ch3/archery_mark.gd", ## 활터 과녁 (엘라리엔의 부탁)
	"root_gate": "res://world/entities/ch3/root_gate.gd", ## 뿌리 문: open_if가 서면 뿌리가 물러남
}
