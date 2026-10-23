class_name BossKit
extends RefCounted
## 보스 공통 도우미 (정적 함수 모음). 새 보스를 만들 때 페이즈 문턱·공격 고르기·페이즈별 빠르기를 여기 것으로 쓴다.
## phase 변수와 phase_changed 신호·전환 연출은 보스가 그대로 갖는다 (대본이 phase를 읽고 신호를 듣기 때문).


## 체력 문턱으로 다음 페이즈 번호를 정한다. marks[i] = (i+1)페이즈를 떠나는 체력 비율 (예: [0.66, 0.33]).
## 지금 phase의 문턱 아래로 내려왔으면 phase + 1, 아니면 0. block_skip이면 이번 공격 전(before)에 문턱 위였을 때
## 체력을 문턱에 멈춰 한 방에 두 페이즈를 건너뛰지 못하게 한다 (전환 연출을 반드시 거침).
## 문턱 체력은 int(max_hp * 비율) — 아우렐리아·리라의 예전 계산 그대로.
static func phase_cross(e: EnemyBase, phase: int, before: int, marks: Array, block_skip := true) -> int:
	var i := phase - 1
	if i < 0 or i >= marks.size():
		return 0
	var at := int(e.max_hp * float(marks[i]))
	if e.hp > at:
		return 0
	if block_skip and before > at:
		e.hp = at
	return phase + 1


## 후보 목록에서 공격 하나 고르기: 직전 공격(last)을 한 번 빼고(같은 것 연속 방지), 비면 fallback.
## test_queue(시험 시나리오가 방 데이터로 넣음)가 있으면 그 맨 앞을 쓴다. 난수는 늘 한 번 쓴다 (예전과 같은 난수 흐름).
static func pick_attack(pool: Array, last: String, test_queue: Array, fallback: String) -> String:
	pool.erase(last)
	if pool.is_empty():
		pool.append(fallback)
	if not test_queue.is_empty():
		pool.clear()
		pool.append(String(test_queue.pop_front()))
	return pool[randi() % pool.size()]


## 페이즈별 배율 (예고·휴식 시간 등). mults[phase-1], 목록보다 높은 페이즈는 마지막 값
static func phase_mult(phase: int, mults: Array) -> float:
	return float(mults[clampi(phase - 1, 0, mults.size() - 1)])
