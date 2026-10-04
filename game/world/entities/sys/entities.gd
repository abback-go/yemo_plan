extends RefCounted
## 공통 시스템(학교 수업 시험) 장치 종류 → 스크립트 (WorldEntities가 합침)

const KINDS := {
	"orb_turret": "res://world/entities/sys/orb_turret.gd", ## 마력탄 발사대 (불꽃 방벽 시험)
	"reflect_target": "res://world/entities/sys/reflect_target.gd", ## 되쏜 탄으로만 켜지는 과녁
	"star_point": "res://world/entities/sys/star_point.gd", ## 별자리 별 (순서대로 밝히기)
	"control_trial": "res://world/entities/sys/control_trial.gd", ## 폭주 제어 시험 (게이지 70~95% 유지)
	"ash_trial": "res://world/entities/sys/ash_trial.gd", ## 재의 서고: 촛불 시간 관리
	"ash_candle": "res://world/entities/sys/ash_candle.gd", ## 재의 서고 촛불
	"phoenix_egg": "res://world/entities/sys/phoenix_egg.gd", ## 불사조의 알 (지키기)
}
