class_name Difficulty
extends RefCounted
## 난이도 도우미 (docs/bible/balance.md 3절). 적 코드는 공격 예고 시간을 Difficulty.telegraph(초)로 감싼다.


## 공격 예고 시간: 쉬움이면 1.2배 (피하기 쉽게)
static func telegraph(sec: float) -> float:
	return sec * (1.2 if GameState.easy() else 1.0)


## 쉬움이면 적 공격 간격(쉬는 시간)을 늘린다
static func rest(sec: float) -> float:
	return sec * (1.25 if GameState.easy() else 1.0)
