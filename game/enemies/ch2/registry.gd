extends RefCounted
## 2장 적 종류 → 스크립트 (EnemyRegistry가 합침). 설계: docs/chapter2.md 4절·7.2절. 체력은 bible/balance.md 2장 보통 값.

const KINDS := {
	"star_lizard": "res://enemies/ch2/star_lizard.gd", ## 별똥 도마뱀 450
	"gargoyle": "res://enemies/ch2/gargoyle.gd", ## 성곽 가고일 600
	"cultist": "res://enemies/ch2/cultist.gd", ## 별 신도 400 (별 수정 방패: reflect만)
	"watchman": "res://enemies/ch2/watchman.gd", ## 태엽 경비병 800
	"sewer_jelly": "res://enemies/ch2/sewer_jelly.gd", ## 하수도 해파리 500
	"star_wolf": "res://enemies/ch2/star_wolf.gd", ## 성흔 늑대 (정예) 1500
	"gladiator": "res://enemies/ch2/gladiator.gd", ## 투기장 챔피언 가론 (미니보스) 1800
	"noxis": "res://enemies/ch2/noxis.gd", ## 녹시스 (미니보스) 1600, 절반에서 도망
	"leonie_spar": "res://enemies/ch2/leonie_spar.gd", ## 레오니 목검 대련 (세 번 맞히기 / 60초)
	"leonie_duel": "res://enemies/ch2/leonie_duel.gd", ## 레오니 결투 (강자 보스) 4000
	"meteor_beast": "res://enemies/ch2/meteor_beast.gd", ## 운석수 (장 절정) 6000
}
