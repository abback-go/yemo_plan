class_name GameConst
## 게임 전체에서 공유하는 상수.
## 기획서의 거리 단위는 타일(T)이고, 코드에서는 TILE을 곱해 픽셀로 바꾼다.

const TILE := 16.0 # 1T = 16px (docs/prototype.md 3절)

# 충돌 레이어 비트 (docs/prototype.md 13.5절). 에디터 표기 번호 n → 비트 값 2^(n-1)
const L_WORLD := 1
const L_PLAYER := 2
const L_ENEMY := 4
const L_PLAYER_HURT := 8
const L_ENEMY_HURT := 16
const L_PLAYER_ATTACK := 32
const L_ENEMY_ATTACK := 64
const L_TRIGGER := 128
const L_PLATFORM := 256 ## 통과 발판: 몸은 밟지만 탄·시야는 통과

const GROUP_PLAYER := &"player"
const GROUP_ENEMY := &"enemy"
