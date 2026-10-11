extends RefCounted
## 5장 적 종류 → 스크립트 (EnemyRegistry가 합침). 체력은 보통 난이도 값(docs/archive/sera/bible/balance.md 2절 5장 열).
##   star_knight   별 기사 1300 (grand 2600)      star_archer  별 궁수 1000 (grand 2000)
##   star_lancer   별 창기사 1400 (grand 2800)    star_wisp    별 정령 450 (별자리 선)
##   outer_seraph  천외 사도 2400 (정예)          colossus     거신 (무적 — 절망 구간)
##   lyra_boss     리라 12000 (강자 보스, 4페이즈 + 별의 비)
##   sky_gate      하늘의 문 14000 (최종, 동료 지원 API — docs/archive/sera/chapter5.md 8절)

const KINDS := {
	"star_knight": "res://enemies/ch5/star_knight.gd",
	"star_archer": "res://enemies/ch5/star_archer.gd",
	"star_lancer": "res://enemies/ch5/star_lancer.gd",
	"star_wisp": "res://enemies/ch5/star_wisp.gd",
	"outer_seraph": "res://enemies/ch5/outer_seraph.gd",
	"colossus": "res://enemies/ch5/colossus.gd",
	"lyra_boss": "res://enemies/ch5/lyra_boss.gd",
	"sky_gate": "res://enemies/ch5/sky_gate.gd",
}
