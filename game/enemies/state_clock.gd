class_name StateClock
extends RefCounted
## 적 상태의 시간 시계 (opt-in 도우미): 남은 시간·상태 길이·진행도.
## 상태 값(enum S나 문자열)은 적이 그대로 `state` 변수로 갖는다 — 그림 노드·대본이 `enemy.state`를 읽기 때문.
## 기반 클래스가 자동으로 tick하지 않는다: 적마다 _timer를 줄이던 그 자리에서 tick(delta)를 불러야 타이밍이 그대로다.
##   var _clock := StateClock.new()          # dur 0일 때 k()가 1.0 (1·2·4장 관례). 3장·해태 관례는 StateClock.new(0.0)
##   func _go(s: S, time := 0.0): state = s; _clock.enter(time)
##   func progress() -> float: return _clock.k()    # 그림 노드가 읽는 이름은 별칭으로 남긴다
##   _ai: _clock.tick(delta) … if _clock.done(): …

var left := 0.0 ## 남은 시간 (s). 0 아래로도 내려간다 (예전 _timer와 같음)
var dur := 0.0 ## 지금 상태의 길이 (s)
var zero_k := 1.0 ## dur이 0 이하일 때 k()가 돌려줄 값


func _init(p_zero_k := 1.0) -> void:
	zero_k = p_zero_k


## 새 상태에 들어감: d초짜리
func enter(d: float) -> void:
	left = d
	dur = d


func tick(delta: float) -> void:
	left -= delta


## 시간이 다 됐는가 (left <= 0)
func done() -> bool:
	return left <= 0.0


## 진행도 0 → 1 (상태에 들어간 직후 0, 끝나면 1)
func k() -> float:
	return clampf(1.0 - left / dur, 0.0, 1.0) if dur > 0.0 else zero_k
