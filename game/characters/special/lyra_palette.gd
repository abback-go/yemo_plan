extends RefCounted
## 리라 몸 그림(lyra_draw.gd)과 초상화(lyra_portrait.gd)가 같이 쓰는 색 — 두 파일이 이 파일을 extends 한다.
## 이름이 같아도 값이 다른 것(HAIR, HAIR_SH, HAIR_DEEP, SKIN, SKIN_SH, EYE, EYE_DEEP, LASH, HAT)은 각 파일에 따로 둔다.

const HAIR_HI := Color("#ffffff")
const ROBE := Color("#1c2256")
const ROBE_HI := Color("#34428e")
const HAT_SH := Color("#0c0e2c")
const GOLD := Color("#ecd28a")
const STAR := Color("#fff3c0")
const STAR_CORE := Color("#fffbea")
const WHITE_GOD := Color("#f4f6ff")
