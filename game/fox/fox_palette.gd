class_name FoxPalette
extends RefCounted
## 여우(너울·여우 모드) 푸른 여우불 색. 세라·fox/ 효과가 같이 쓴다.
## (적·대본 쪽에도 같은 값이 흩어져 있다 — core/palette.gd로 올리는 것은 통합 때 결정)

const GLOW := Color(0.55, 0.85, 1.0) ## 여우불 빛: 고리·입자·잔광
const SPARK := Color(0.6, 0.85, 1.0) ## 조금 더 흰 입자 (너울 등장·퇴장, 여우비, 구미호 폭풍)
const GHOST := Color(0.4, 0.75, 1.0) ## 여우 모드 잔상 (알파는 쓰는 곳에서)
