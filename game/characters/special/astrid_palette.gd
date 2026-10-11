extends RefCounted
## 아스트리드 몸 그림(astrid_draw.gd)과 초상화(astrid_portrait.gd)가 같이 쓰는 색 — 두 파일이 이 파일을 extends 한다.
## 이름이 같아도 값이 다른 것(HAIR_SH, HAIR_HI, SKIN_SH, SILVER)은 각 파일에 따로 둔다.

const HAIR := Color("#c4c4d4")
const SKIN := Color("#f0dcd4")
const EYE := Color("#a0a0e8")
const LASH := Color("#2a2438")
const CLOAK := Color("#20203a")
const TRIM := Color("#c8c0ff")
const HAT := Color("#181830")
