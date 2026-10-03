extends RefCounted
## 5장 데이터 — ChapterRegistry가 합친다 (docs/systems2.md 1절).
## 1단계(에셋·설계): 인물 그림 등록만. 방·목표·퀘스트는 2단계에서 docs/chapter5.md 7절 설계대로 채운다.

## 인물: 1장 Characters.DB와 같은 키 (+ 전용 그림 "draw"·"portrait"). 같은 ID면 키를 덮어씀.
##   lyra       별의 마녀 (새 인물). 일반 그림 키는 전용 그림이 없을 때를 위한 대비값.
##   astrid     1장 DB 항목(이름·색·목소리)은 그대로 두고 전용 그림만 덧붙임 → 1장부터 새 그림으로 보인다.
##   neoul_god  너울 본모습의 초상화만 새로 (몸은 컷신 actor·5장 각성 장치가 그림)
const CHARACTERS := {
	"lyra": {
		"name": "리라", "color": Color("#ffe7a0"), "voice": 0.95,
		"robe": Color("#1c2256"), "robe2": Color("#ecd28a"), "skin": Color("#f8e8e2"), "hair": Color("#e7eaf8"),
		"hair_style": "long", "hat": "witch", "hat_col": Color("#181c4a"), "eye": Color("#a070e8"), "height": 40, "extra": ["stars"],
		"draw": "res://characters/special/lyra_draw.gd",
		"portrait": "res://characters/special/lyra_portrait.gd",
	},
	"astrid": {
		"draw": "res://characters/special/astrid_draw.gd",
		"portrait": "res://characters/special/astrid_portrait.gd",
	},
	"neoul_god": {
		"portrait": "res://characters/special/neoul_portrait.gd",
	},
}

## 이 장의 방 ID (지도·검사용) — 2단계
const ROOMS := []

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 플래그] — 2단계 (설계: docs/chapter5.md 9절)
const OBJECTIVES := []

## 퀘스트 (docs/systems2.md 4절) — 2단계 (설계: docs/chapter5.md 10절)
const QUESTS := {}
