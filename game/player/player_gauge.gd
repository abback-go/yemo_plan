class_name PlayerGauge
extends RefCounted
## 폭주 게이지와 여우 모드(빙의).
## 마법을 쓰면 게이지가 오르고(add), 70% 이상이면 과열(화염탄 강화), 가득 차면
##   너울이 있고 기운이 차 있으면 여우 모드, 아니면 잠시 뒤 폭주 폭발(자기 피해 + 경직).
## 게이지 값은 Player.overload, 여우 시간·기운은 Player.fox_time·fox_energy (대본이 직접 씀).

var p: Player
var fuse := -1.0 ## 0 이상이면 폭주 폭발까지 남은 시간
var _idle := 99.0 ## 마지막으로 게이지가 오른 뒤 흐른 시간 (감소 시작 판정)
var _pulse_timer := 0.0
var _was_overheated := false


func _init(owner: Player) -> void:
	p = owner


func tick(delta: float) -> void:
	_idle += delta


## 너울의 꼬리 수(장 진행)에 따른 여우 모드 시간
func fox_duration() -> float:
	var tu := p.tuning
	var n := p.tails()
	if n >= 9:
		return tu.fox_duration_nine_tails
	return tu.fox_duration + tu.fox_duration_per_tail * (n - 1)


## 너울의 기운이 다시 차는 시간
func fox_recharge() -> float:
	var tu := p.tuning
	return maxf(tu.fox_recharge - tu.fox_recharge_per_tail * (p.tails() - 1), tu.fox_recharge_min)


## 폭주 게이지 70% 이상(또는 폭발 직전): 화염탄이 강해지는 과열 상태 (위험을 감수한 보상)
func overheated() -> bool:
	return p.overload_ratio() >= p.tuning.overload_warn_ratio or fuse >= 0.0


## 게이지를 비우고 폭발 예고·화면 붉은 테두리를 끈다
func clear() -> void:
	p.overload = 0.0
	fuse = -1.0
	Fx.set_vignette(0.0)


func add(amount: float) -> void:
	if p.is_fox() or p.no_overload:
		return
	var tu := p.tuning
	p.overload = minf(p.overload + amount, tu.overload_max)
	_idle = 0.0
	if p.overload >= tu.overload_max:
		_on_full()


## 폭주 게이지가 가득 참: 너울이 있고 기운이 차 있으면 여우 모드, 아니면 폭주 폭발
func _on_full() -> void:
	if GameState.has_ability("fox_mode") and p.fox_energy >= 1.0:
		start_fox_mode()
	elif fuse < 0.0:
		fuse = p.tuning.overload_fuse
		Sfx.play(&"overload_warn", 2.0, 0.0)


## 대본에서 폭주 게이지를 강제로 채움 (P4 폭주 폭발, P7 첫 빙의)
func force_full() -> void:
	p.overload = p.tuning.overload_max
	_idle = 0.0
	_on_full()


func start_fox_mode() -> void:
	clear()
	p.fox_time = fox_duration()
	p.fox_energy = 0.0
	p.grant_iframes(1.0)
	GameState.add("fox_modes")
	var fx := FoxTransformFx.new()
	fx.setup(p)
	Fx.effect_parent().add_child(fx)
	var w := World.get_world()
	if w:
		w.pet.merge_into_player()


func _end_fox_mode() -> void:
	p.fox_time = 0.0
	p.overload = 0.0
	var b := FoxEndBurst.new()
	b.setup(p.center(), p.tuning)
	Fx.effect_parent().add_child(b)
	var w := World.get_world()
	if w:
		w.pet.leave_player()


## 매 물리 프레임: 여우 시간·기운, 과열 알림, 폭발 예고, 자연 감소
func update(delta: float) -> void:
	var tu := p.tuning
	var body := p._body
	if p.fox_time > 0.0:
		if not GameState.has_flag("fox_permanent"): # 5장 최종 구간: 아홉 꼬리 완전 빙의
			p.fox_time -= delta
		body.fox = minf(body.fox + delta * 4.0, 1.0)
		if p.fox_time <= 0.0:
			_end_fox_mode()
		return
	body.fox = maxf(body.fox - delta * 3.0, 0.0)
	if p.fox_energy < 1.0:
		p.fox_energy = minf(p.fox_energy + delta / fox_recharge(), 1.0)
	body.mimic = 1.0 if GameState.has_ability("fox_mode") and overheated() and p.fox_energy >= 1.0 else 0.0
	var heated := overheated()
	if heated and not _was_overheated:
		Sfx.play(&"overheat", -2.0, 0.0)
		Fx.ring(p.center(), 4.0, 26.0, Palette.FIRE_OUT, 0.3, 1.0)
		p._banner(PlayerText.BANNER_OVERHEAT, 0.8)
	_was_overheated = heated

	if fuse >= 0.0:
		fuse -= delta
		Fx.set_vignette(0.5 + 0.5 * (1.0 - fuse / tu.overload_fuse))
		if fuse < 0.0:
			_trigger_burst()
		return
	if _idle > tu.overload_decay_delay and p.overload > 0.0:
		p.overload = maxf(p.overload - tu.overload_decay_rate * delta, 0.0)
	if heated:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_pulse_timer = 0.45
			Sfx.play(&"overload_pulse", -6.0, 0.0)
	else:
		_pulse_timer = 0.0


func _trigger_burst() -> void:
	clear()
	var b := OverloadBurst.new()
	b.setup(p.center(), p.tuning)
	Fx.effect_parent().add_child(b)
	GameState.add("overloads")
	p.caster.cancel_storm()
	p.take_damage(p.tuning.burst_self_damage, &"overload", p.global_position.x, true)
	if p.state != Player.State.DEAD:
		p.stun(p.tuning.burst_stun)
		p.velocity = Vector2(0, -180)
