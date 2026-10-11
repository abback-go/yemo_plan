extends RefCounted
## 3장 적 종류 → 스크립트 (EnemyRegistry가 합침) — docs/archive/sera/chapter3.md 4절·7.4절

const KINDS := {
	"moss_stag": "res://enemies/ch3/moss_stag.gd", ## 이끼 사슴 700 (순함/역병: blighted = true) — 쓰러지면 정화되어 떠남
	"blight_spore": "res://enemies/ch3/blight_spore.gd", ## 역병 포자 덩어리 560 — 하얀 바닥(느려짐), 불로 태움
	"vine_stalker": "res://enemies/ch3/vine_stalker.gd", ## 덩굴 사냥꾼 820 — 덤불에 숨음, 가까이·여우창문으로 드러남
	"lantern_moth": "res://enemies/ch3/lantern_moth.gd", ## 등불 나방 640 — 나선 비행·가루 구름, 등불에서 쉼
	"elf_warden": "res://enemies/ch3/elf_warden.gd", ## 엘프 파수꾼 900 — 비살상(물러남), 잎 방패
	"white_mite": "res://enemies/ch3/white_mite.gd", ## 백색 진드기 정예 1800 → 작은 둘(450, small = true)
	"elarien_hunt": "res://enemies/ch3/elarien_hunt.gd", ## 엘라리엔 사냥 시험 (강자 보스, 세 번 닿기)
	"white_herald": "res://enemies/ch3/white_herald.gd", ## 백색 사도 7000 (절정 보스, snipe_eye)
	"isolde_duel": "res://enemies/ch3/isolde_duel.gd", ## 이졸데 결투 2000 (서브 s_duel_cup — 서리 조각·얼음 창·가시)
}
