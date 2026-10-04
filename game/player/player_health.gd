class_name PlayerHealth
extends RefCounted
## 세라 체력 — 회복, 피격(무적 시간·넉백·경직), 가시·불꽃, 퍼펙트 회피(위치 타임), 사망, 불사조 Lv3 부활.
## 체력 값은 Player.hp(대본이 직접 읽고 씀), 피격 무적은 Player._hurt_iframe(바깥은 grant_iframes·set_iframes로).

var p: Player
var hazard_cool := 0.0 ## 가시·불꽃 연속 피해 막기 (이 동안은 안전한 땅도 기록하지 않음)
var _hurt_timer := 0.0
var _witch_cooldown := 0.0


func _init(owner: Player) -> void:
	p = owner


func tick(delta: float) -> void:
	p._hurt_iframe -= delta
	_witch_cooldown -= delta
	hazard_cool -= delta
	if p.state == Player.State.HURT:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			p.state = Player.State.FALL
	elif p.state == Player.State.STUN:
		p._stun_timer -= delta
		if p._stun_timer <= 0.0:
			p.state = Player.State.FALL


## 체력을 정하고 GameState·HUD에 알린다
func set_hp(v: int) -> void:
	p.hp = v
	GameState.hp = p.hp
	p.hp_changed.emit(p.hp, p.max_hp())


## 가시·불꽃: 1 피해 + 직전 안전한 땅으로
func hazard_hit() -> void:
	if p.state == Player.State.DEAD or hazard_cool > 0.0:
		return
	hazard_cool = 0.6
	var safe := p.motor.safe_positions
	var back: Vector2 = safe[0] if not safe.is_empty() else p.global_position + Vector2(-p.facing * 32, -16)
	if take_damage(1, &"hazard", p.global_position.x, true) and p.state != Player.State.DEAD:
		p.global_position = back
		p.velocity = Vector2.ZERO
		p.state = Player.State.FALL
		p._hurt_iframe = p.tuning.hurt_invincible
		p.camera.reset_smoothing()


func check_hurtbox() -> void:
	var areas := p._hurtbox.get_overlapping_areas()
	if p.motor.dash_iframe > 0.0:
		# 대시 무적 중 공격이 몸을 스치면 퍼펙트 회피 → 위치 타임
		if not p.motor.dodged_this_dash and p.tuning.perfect_dodge_enabled and _witch_cooldown <= 0.0:
			for a in areas:
				if a is EnemyAttackArea and a.active and a.dodgeable:
					_perfect_dodge()
					break
		return
	if p.is_invincible():
		return
	for a in areas:
		if a is EnemyAttackArea and a.active:
			if take_damage(a.damage, a.cause, a.global_position.x):
				a.notify_hit(p)
			return


func _perfect_dodge() -> void:
	var tu := p.tuning
	p.motor.dodged_this_dash = true
	_witch_cooldown = tu.witch_time_cooldown
	p.motor.dash_iframe = maxf(p.motor.dash_iframe, 0.25)
	Fx.witch_time(tu.witch_time_scale, tu.witch_time_duration)
	Fx.ring(p.center(), 6.0, 60.0, Color(0.7, 0.55, 1.0), 0.45, 2.0, false)
	Fx.flash(Color(0.6, 0.45, 1.0, 0.3), 0.15)
	Fx.zoom_punch(tu.zoom_punch)
	Sfx.play(&"witch_time")
	StyleRank.bonus(PlayerText.STYLE_WITCH_TIME, 12.0)
	GameState.add("perfect_dodges")
	p._banner(PlayerText.BANNER_WITCH_TIME, 0.9)


## forced = 무적 시간과 상관없이 받는 피해 (폭주 자기 피해)
func take_damage(amount: int, cause: StringName, from_x: float, forced := false) -> bool:
	if p.state == Player.State.DEAD:
		return false
	if not forced and p.is_invincible():
		return false
	var tu := p.tuning
	if GameState.easy():
		amount = mini(amount, 1) # 초보자: 무엇이든 최대 1칸
	# set_hp와 달리 알림(hp_changed) 전에 기록·스타일을 먼저 갱신한다 (원래 순서 유지)
	p.hp = maxi(p.hp - amount, 0)
	GameState.hp = p.hp
	GameState.add("hits_" + String(cause))
	StyleRank.on_hurt()
	p.hp_changed.emit(p.hp, p.max_hp())
	p._hurt_iframe = tu.hurt_invincible
	Fx.hitstop(tu.hitstop_hurt)
	Fx.shake(tu.shake_hurt_t)
	Fx.flash(Color(1.0, 0.1, 0.1, 0.32), 0.18)
	Sfx.play(&"hurt")
	Fx.burst(p.center(), 12, {
		spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(Palette.HP), size_min = 1.0, size_max = 2.5,
	})
	if p.hp <= 0 and Spells.learned("phoenix") and Spells.level("phoenix") >= 3 and p.caster.is_ready("phoenix"):
		# 불사조 Lv3 — 부활의 불꽃
		set_hp(mini(tu.phoenix_revive_hp, p.max_hp()))
		p._hurt_iframe = tu.phoenix_revive_iframe
		p.caster.cast_phoenix(true)
		Story.toast(PlayerText.REVIVE, 1.6)
		return false
	if p.hp <= 0:
		_die()
		return true
	if not forced:
		p.caster.cancel_storm()
		p.state = Player.State.HURT
		_hurt_timer = tu.hurt_stun
		var dir := signf(p.global_position.x - from_x)
		if dir == 0.0:
			dir = -p.facing
		p.velocity = Vector2(dir * 2.0 * tu.hurt_knockback_t * GameConst.TILE / tu.hurt_stun, -140.0)
	return true


func _die() -> void:
	p.state = Player.State.DEAD
	p.controls_enabled = false
	p.fox_time = 0.0
	p.caster.stop_potion()
	p.gauge.fuse = -1.0
	Fx.set_vignette(0.0)
	p.caster.cancel_storm()
	p.velocity = Vector2(-p.facing * 60.0, -160.0)
	GameState.add("deaths")
	p.died.emit()
	Fx.slowmo(0.3, 0.7)
	Fx.burst(p.center(), 50, {
		spread = 180.0, speed_min = 40.0, speed_max = 220.0, lifetime = 0.9, damping = 80.0,
		size_min = 1.5, size_max = 3.5, gravity = Vector2(0, -50),
	})
	var t := p.create_tween().set_ignore_time_scale(true)
	t.tween_property(p._visual, "modulate:a", 0.0, 0.8).set_delay(0.3)
