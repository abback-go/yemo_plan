extends RefCounted
## 레오니 몸 그림(leonie_draw.gd)과 초상화(leonie_portrait.gd)가 같이 쓰는 색 — 두 파일이 이 파일을 extends 한다.
## 이름이 같아도 값이 다른 것(HAIR_L, HAIR_D, SKIN_D, EYE, SCAR)은 각 파일에 따로 둔다.

const KArt := preload("res://world/entities/ch2/k_art.gd")
const OUT := Color("#07060c")
const HAIR := Color("#1e2748")
const SKIN := Color("#f2d2be")
const ARMOR := Color("#a6adc0")
const ARMOR_L := Color("#e6eaf2")
const ARMOR_D := Color("#5a6078")
const CAPE := Color("#a01e2c")
const CAPE_L := Color("#d23a44")
const CAPE_D := Color("#5c0e18")
