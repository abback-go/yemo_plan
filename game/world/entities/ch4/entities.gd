extends RefCounted
## 4장 방 개체 종류 → 스크립트 (WorldEntities가 합침). 스크립트는 setup(room, e, eid) — docs/archive/sera/chapter4.md 7.5절

const KINDS := {
	"temple_bell": "res://world/entities/ch4/temple_bell.gd", ## 진짜 종: 불기둥으로 울림 → 종지기 망령 멈춤, 종 퍼즐
	"light_mirror": "res://world/entities/ch4/light_mirror.gd", ## 빛의 거울: 빛줄기를 꺾음, ↑·불기둥으로 돌림
	"light_crystal": "res://world/entities/ch4/light_crystal.gd", ## 빛의 수정: 빛줄기가 닿으면 flag
	"seal_stone": "res://world/entities/ch4/seal_stone.gd", ## 금빛 봉인석: 유성 낙화로만 부서짐
	"holy_chaser": "res://world/entities/ch4/holy_chaser.gd", ## 첨탑 추격: 신성 돌진 + 차오르는 금빛
	"spire_plank": "res://world/entities/ch4/spire_plank.gd", ## 신성 돌진에 무너지는 비계 발판
	"bell_puzzle": "res://world/entities/ch4/bell_puzzle.gd", ## 종 퍼즐: 순서·박자대로 울리면 플래그
	"star_steps": "res://world/entities/ch4/star_steps.gd", ## 교장의 별빛 발판 (플래그가 서면 나타남)
	"tp_ally": "res://world/entities/ch4/ally_keeper.gd", ## 동료 유지 (저장·부활 뒤에도 레오니가 곁에)
}
