extends RefCounted
## 4장 적 종류 → 스크립트 (EnemyRegistry가 합침) — docs/chapter4.md 4절·7.4절 (체력은 보통 난이도 값)

const KINDS := {
	"holy_monk": "res://enemies/ch4/holy_monk.gd", ## 성갑 수도사 900 — 빛의 방패가 화염탄을 되돌려 보냄 (방벽으로 되쏘면 방패가 깨짐)
	"lumen_eye": "res://enemies/ch4/lumen_eye.gd", ## 빛의 감시안 700 — 쓸어 오는 빛줄기 / source=true면 퍼즐 광원
	"bell_wraith": "res://enemies/ch4/bell_wraith.gd", ## 종지기 망령 800 — 소리 고리 / 진짜 종을 울리면 멈춤
	"seraph_statue": "res://enemies/ch4/seraph_statue.gd", ## 날개 조각상 900 — 등을 돌릴 때만 움직임, 굳으면 화염탄 무효
	"pilgrim_shade": "res://enemies/ch4/pilgrim_shade.gd", ## 순례자의 그림자 600 — 붙잡기, 쓰러뜨리면 풀려남
	"gold_herald": "res://enemies/ch4/gold_herald.gd", ## 백금 사도 2400 (기록실 미니보스) — 거울판·프리즘·격자
	"aurelia_boss": "res://enemies/ch4/aurelia_boss.gd", ## 아우렐리아 9000 (4장 강자 보스, 3페이즈)
}
