class_name Tuning
extends Resource
## 조작감·전투 수치 전부 (docs/prototype.md 3절: "모든 조정 수치는 한 곳에").
## 에디터에서 core/tuning.tres를 클릭하면 인스펙터에서 바로 바꿀 수 있다.
## 거리는 타일(T), 시간은 초(s). 시작값은 docs/prototype.md 5~6절.

@export_group("Move")
@export var max_speed_t := 7.0 ## 최고 이동 속도 (T/s)
@export var accel_time := 0.08 ## 정지 → 최고 속도까지 걸리는 시간 (s)
@export var decel_time := 0.06 ## 최고 속도 → 정지까지 걸리는 시간 (s)

@export_group("Jump")
@export var jump_height_max_t := 3.5 ## 길게 눌렀을 때 점프 높이 (T)
@export var jump_height_min_t := 1.2 ## 짧게 눌렀을 때 점프 높이 (T)
@export var time_to_apex := 0.35 ## 최고점까지 올라가는 시간 (s)
@export var fall_gravity_multiplier := 1.5 ## 떨어질 때 중력 배율
@export var max_fall_speed_t := 18.0 ## 최대 낙하 속도 (T/s)
@export var coyote_time := 0.10 ## 발판에서 떨어진 직후 점프를 허용하는 시간 (s)
@export var jump_buffer_time := 0.10 ## 착지 직전 점프 입력을 기억하는 시간 (s)

@export_group("Dash")
@export var dash_distance_t := 3.0
@export var dash_duration := 0.15
@export var dash_invincible_time := 0.12
@export var dash_cooldown := 0.45
@export var air_dash_count := 1

@export_group("Fire Bolt")
@export var bolt_damage_light := 10 ## 1·2타 피해
@export var bolt_damage_heavy := 25 ## 3타 피해
@export var bolt_speed_light_t := 20.0
@export var bolt_speed_heavy_t := 24.0
@export var bolt_range_light_t := 9.0
@export var bolt_range_heavy_t := 10.0
@export var bolt_interval_light := 0.16 ## 1·2타 다음 발사까지 간격
@export var bolt_interval_heavy := 0.30 ## 3타 후 숨 고르기
@export var bolt_knockback_light_t := 0.2
@export var bolt_knockback_heavy_t := 1.0
@export var combo_keep_time := 0.35 ## 이 시간 안에 다음 발사가 없으면 1타로
@export var attack_buffer_time := 0.15 ## 간격 중에 누른 공격을 기억하는 시간
@export var heavy_recoil_t := 0.35 ## 3타 반동으로 뒤로 밀리는 거리

@export_group("Skill: Fire Pillar")
@export var pillar_range_t := 7.0
@export var pillar_fallback_t := 5.0 ## 대상이 없을 때 생성 거리
@export var pillar_warn_time := 0.35
@export var pillar_width_t := 1.0
@export var pillar_height_t := 4.0
@export var pillar_damage := 40
@export var pillar_launch_t := 2.0
@export var pillar_cooldown := 1.0
@export var pillar_overload := 30.0

@export_group("Skill: Fire Storm")
@export var storm_radius_t := 3.0
@export var storm_angle_deg := 90.0
@export var storm_duration := 0.30
@export var storm_ticks := 3
@export var storm_tick_damage := 12
@export var storm_knockback_t := 4.0
@export var storm_move_mult := 0.3
@export var storm_cooldown := 1.5
@export var storm_overload := 35.0

@export_group("Overload")
@export var overload_max := 100.0
@export var overload_decay_delay := 1.5
@export var overload_decay_rate := 15.0 ## 초당 감소량
@export var overload_warn_ratio := 0.7
@export var overload_fuse := 0.3 ## 100 도달 후 폭발까지
@export var burst_radius_t := 4.0
@export var burst_damage := 80
@export var burst_self_damage := 1
@export var burst_stun := 0.8

@export_group("Health")
@export var max_hp := 5
@export var hurt_invincible := 1.0
@export var hurt_knockback_t := 1.5
@export var hurt_stun := 0.2

@export_group("Hit Feel")
@export var hitstop_light := 0.03
@export var hitstop_heavy := 0.06
@export var hitstop_pillar := 0.08
@export var hitstop_storm := 0.05
@export var hitstop_burst := 0.15
@export var hitstop_hurt := 0.08
@export var shake_heavy_t := 0.1
@export var shake_pillar_t := 0.2
@export var shake_storm_t := 0.2
@export var shake_burst_t := 0.4
@export var shake_hurt_t := 0.2
@export var enemy_flash_time := 0.05

@export_group("Camera")
@export var look_ahead_t := 2.0
@export var look_ahead_time := 0.3

@export_group("Enemy: Charger")
@export var charger_hp := 80
@export var charger_patrol_speed_t := 2.0
@export var charger_detect_t := 8.0
@export var charger_windup := 0.6
@export var charger_speed_t := 12.0
@export var charger_charge_distance_t := 6.0
@export var charger_recover := 1.0

@export_group("Enemy: Sniper")
@export var sniper_hp := 50
@export var sniper_range_t := 12.0
@export var sniper_aim_time := 0.8 ## 조준 예고 전체 (마지막 lock 구간 포함)
@export var sniper_lock_time := 0.2 ## 조준선 고정 구간
@export var sniper_shot_speed_t := 14.0
@export var sniper_reload := 2.5
