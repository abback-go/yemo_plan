class_name Tuning
extends Resource
## 조작감·전투 수치 전부 (docs/prototype.md 3절: "모든 조정 수치는 한 곳에").
## 에디터에서 core/tuning.tres를 클릭하면 인스펙터에서 바로 바꿀 수 있다.
## 거리는 타일(T), 시간은 초(s).
## v0.3: 빠르고 스타일리시한 전투로 전면 조정 (docs/prototype.md 14절). 이동 수치의 기준은
## Celeste 공개 소스(화면 폭 40타일 기준 달리기 11.25타일/s, 대시 0.15s에 4.5타일).

@export_group("Move")
@export var max_speed_t := 11.0 ## 최고 달리기 속도 (T/s). v0.2: 7
@export var accel_time := 0.06 ## 정지 → 최고 속도 (s)
@export var decel_time := 0.05 ## 최고 속도 → 정지 (s)
@export var over_speed_decel_t := 25.0 ## 땅에서 최고 속도를 넘었을 때 줄어드는 정도 (T/s²)
@export var over_speed_air_decel_t := 12.0 ## 공중에서 최고 속도를 넘었을 때 (대시 점프 관성 유지. Celeste 공중 감속 비율 참고)

@export_group("Jump")
@export var jump_height_max_t := 4.0 ## 길게 눌렀을 때 점프 높이 (T). v0.2: 3.5
@export var jump_height_min_t := 1.3
@export var time_to_apex := 0.32 ## 최고점까지 시간 (s). v0.2: 0.35
@export var fall_gravity_multiplier := 1.7
@export var apex_hang_speed_t := 5.0 ## 최고점 근처(|세로 속도| < 이 값) + 점프 유지 시 중력 절반 → 공중 조준 여유
@export var max_fall_speed_t := 20.0
@export var fast_fall_speed_t := 30.0 ## ↓를 누르고 떨어질 때 최대 속도
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.12
@export var corner_correction_px := 5 ## 천장 모서리에 머리가 걸리면 옆으로 밀어 주는 최대 거리

@export_group("Dash")
@export var dash_distance_t := 4.5 ## v0.2: 3
@export var dash_duration := 0.15
@export var dash_invincible_time := 0.15
@export var dash_cooldown := 0.28 ## v0.2: 0.45
@export var air_dash_count := 1
@export var dash_jump_speed_t := 20.0 ## 대시 중(또는 직후) 점프 시 수평 속도 → 멀리 뛰는 대시 점프
@export var dash_jump_window := 0.1 ## 대시 끝난 뒤 대시 점프를 인정하는 시간
@export var hit_refreshes_air_dash := true ## 공중에서 적을 맞히면 공중 대시 회복

@export_group("Perfect Dodge")
@export var perfect_dodge_enabled := true ## 대시 무적 중 공격을 피하면 '위치 타임'(주변이 느려짐)
@export var witch_time_scale := 0.35
@export var witch_time_duration := 1.1 ## 실제 시간 (s)
@export var witch_time_cooldown := 2.0

@export_group("Fire Bolt")
## v0.4 (플레이 피드백): 3연타 대신 묵직한 한 발. 단일 대상, 폭발 없음
@export var shot_damage := 200
@export var shot_interval := 1.2 ## 한 발 쏜 뒤 다음 발까지 (누르고 있으면 이 간격으로 계속)
@export var shot_speed_t := 40.0
@export var shot_range_t := 14.0
@export var shot_knockback_t := 1.6
@export var fox_shot_damage := 260 ## 여우 모드 X: 유도 + 관통
@export var fox_shot_speed_t := 34.0
@export var fox_shot_range_t := 20.0
@export var fox_shot_homing := 4.0 ## 초당 회전 각 (라디안)
@export var attack_buffer_time := 0.15
@export var heavy_recoil_t := 0.5
@export var air_shot_hover_speed_t := 1.5 ## 공중에서 쏘면 낙하 속도를 이 값으로 눌러 잠깐 떠 있음
@export var air_shot_hover_count := 4 ## 착지 전까지 떠 있게 해 주는 발사 횟수
@export var juggle_lift_t := 0.7 ## 공중에 뜬 적을 맞히면 다시 띄우는 높이

@export_group("Overheat")
@export var overheat_damage_mult := 1.35 ## 폭주 게이지 70% 이상일 때 화염탄 피해 배율 (위험 감수 보상)
@export var overheat_bolt_scale := 1.4

@export_group("Skill: Fire Pillar")
@export var pillar_range_t := 9.0
@export var pillar_fallback_t := 6.0
@export var pillar_warn_time := 0.22 ## v0.2: 0.35
@export var pillar_width_t := 2.0 ## v0.2: 1
@export var pillar_height_t := 7.0 ## v0.2: 4
@export var pillar_damage := 45
@export var pillar_side_damage := 25 ## 연쇄로 양옆에 솟는 기둥
@export var pillar_side_count := 2 ## 한쪽당 연쇄 기둥 수
@export var pillar_side_gap_t := 2.2
@export var pillar_side_delay := 0.07 ## 연쇄 기둥 사이 간격 (s). 간격 × 개수가 중심 기둥 수명(분출 후 0.55초)보다 짧아야 함
@export var pillar_launch_t := 3.0
@export var pillar_cooldown := 0.9
@export var pillar_overload := 30.0

@export_group("Skill: Fire Storm")
@export var storm_radius_t := 5.5 ## v0.2: 3
@export var storm_angle_deg := 100.0
@export var storm_duration := 0.45
@export var storm_ticks := 5
@export var storm_tick_damage := 12
@export var storm_final_damage := 30 ## 마지막 폭발 피해
@export var storm_knockback_t := 6.0
@export var storm_move_mult := 0.5
@export var storm_recoil_t := 1.2 ## 시전 시 뒤로 밀리는 거리
@export var storm_cooldown := 1.3
@export var storm_overload := 35.0

@export_group("Overload")
@export var overload_max := 100.0
@export var overload_decay_delay := 1.5
@export var overload_decay_rate := 15.0
@export var overload_warn_ratio := 0.7
@export var overload_fuse := 0.35
@export var burst_radius_t := 6.5 ## v0.2: 4
@export var burst_damage := 90
@export var burst_self_damage := 1
@export var burst_stun := 0.6

@export_group("Health")
@export var max_hp := 5
@export var hurt_invincible := 1.0
@export var hurt_knockback_t := 1.5
@export var hurt_stun := 0.2

@export_group("Hit Feel")
@export var hitstop_light := 0.025
@export var hitstop_heavy := 0.07
@export var hitstop_pillar := 0.09
@export var hitstop_storm := 0.06
@export var hitstop_burst := 0.18
@export var hitstop_hurt := 0.08
@export var hitstop_kill := 0.06
@export var shake_light_t := 0.04
@export var shake_heavy_t := 0.15
@export var shake_pillar_t := 0.3
@export var shake_storm_t := 0.25
@export var shake_burst_t := 0.5
@export var shake_hurt_t := 0.2
@export var zoom_punch := 0.05 ## 큰 타격 때 순간 확대 비율
@export var enemy_flash_time := 0.06

@export_group("Style")
@export var combo_timeout := 2.2 ## 이 시간 동안 아무것도 못 맞히면 콤보 끊김
@export var style_decay := 6.0 ## 초당 스타일 점수 감소

@export_group("Camera")
@export var look_ahead_t := 3.5 ## v0.2: 2
@export var look_ahead_time := 0.25

@export_group("Enemy: Charger")
@export var charger_hp := 120
@export var charger_patrol_speed_t := 2.5
@export var charger_detect_t := 10.0
@export var charger_windup := 0.55
@export var charger_speed_t := 17.0
@export var charger_charge_distance_t := 8.0
@export var charger_recover := 0.9

@export_group("Enemy: Sniper")
@export var sniper_hp := 70
@export var sniper_range_t := 14.0
@export var sniper_aim_time := 0.75
@export var sniper_lock_time := 0.2
@export var sniper_shot_speed_t := 20.0
@export var sniper_reload := 2.2
