extends RefCounted
## 녹시스 몸 그림(noxis_draw.gd)과 초상화(noxis_portrait.gd)가 같이 쓰는 색 — 두 파일이 이 파일을 extends 한다.
## 이름이 같아도 값이 다른 것(MASK, MASK_D, SKIN)은 각 파일에 따로 둔다.

const KArt := preload("res://world/entities/ch2/k_art.gd")
const ROBE := Color("#2a2050")
const ROBE_L := Color("#45387a")
const ROBE_D := Color("#140e2a")
const TRIM := Color("#c8a8ff")
const HAIR := Color("#dcd4ec")
const STAR := Color("#c89aff")
