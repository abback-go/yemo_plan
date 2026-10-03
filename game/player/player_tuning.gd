class_name PlayerTuning
extends Resource
## 세라의 조작감 수치 모음.
## 에디터에서 player_tuning.tres를 클릭하면 인스펙터에서 바로 바꿀 수 있다.
## 거리는 타일(T), 시간은 초(s) 단위. 시작값은 docs/prototype.md 5.1·5.2절.

@export_group("Move")
@export var max_speed_t := 7.0 ## 최고 이동 속도 (T/s)
@export var accel_time := 0.08 ## 정지 → 최고 속도까지 걸리는 시간 (s)
@export var decel_time := 0.06 ## 최고 속도 → 정지까지 걸리는 시간 (s)

@export_group("Jump")
@export var jump_height_max_t := 3.5 ## 길게 눌렀을 때 점프 높이 (T)
@export var jump_height_min_t := 1.2 ## 짧게 눌렀을 때 점프 높이 (T)
@export var time_to_apex := 0.35 ## 최고점까지 올라가는 시간 (s). 작을수록 빠르고 묵직한 점프
@export var fall_gravity_multiplier := 1.5 ## 떨어질 때 중력 배율. 1보다 크면 낙하가 빨라져 둥실거림이 줄어듦
@export var max_fall_speed_t := 18.0 ## 최대 낙하 속도 (T/s)
@export var coyote_time := 0.10 ## 발판에서 떨어진 직후 점프를 허용하는 시간 (s)
@export var jump_buffer_time := 0.10 ## 착지 직전 점프 입력을 기억하는 시간 (s)

@export_group("Dash")
@export var dash_distance_t := 3.0 ## 대시 이동 거리 (T)
@export var dash_duration := 0.15 ## 대시 지속 시간 (s)
@export var dash_invincible_time := 0.12 ## 대시 시작부터 무적인 시간 (s)
@export var dash_cooldown := 0.45 ## 대시가 끝난 뒤 다시 쓸 수 있을 때까지 (s)
@export var air_dash_count := 1 ## 착지 전까지 공중 대시 횟수
