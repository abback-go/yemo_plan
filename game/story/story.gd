extends Node
## 이야기 진행 (오토로드 Story). 컷신·대화·읽기·안내를 실행하고, 방에 들어올 때의 이벤트를 부른다.
## 대본은 story/scripts_*.gd 의 메서드 (이름 = 실행 ID). 메서드는 Cut을 받아 await로 순서대로 진행한다.

const SCRIPT_FILES := [
	"res://story/scripts_prologue.gd",
	"res://story/scripts_school.gd",
	"res://story/scripts_npc.gd",
]

var world: World
var _busy := 0
var _scripts: Array = []
var _gen := 0 ## 부활·타이틀 이동 시 진행 중이던 컷신을 무효화


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in SCRIPT_FILES:
		if ResourceLoader.exists(path):
			_scripts.append((load(path) as GDScript).new())


func attach(w: World) -> void:
	world = w
	_busy = 0
	_gen += 1


func busy() -> bool:
	return _busy > 0


func busy_count() -> int:
	return _busy


## 지금의 진행 세대 (쓰러지거나 타이틀로 가면 바뀜). 오래 기다리는 대본이 확인용으로 씀
func generation() -> int:
	return _gen


func has_script(id: String) -> bool:
	for s in _scripts:
		if s.has_method(id):
			return true
	return false


## 컷신·대화 실행. 세라 조작은 끝날 때까지 잠긴다
func run(id: String, soft := false) -> void:
	if id == "" or world == null:
		return
	for s in _scripts:
		if s.has_method(id):
			var gen := _gen
			_busy += 1
			var c := Cut.new(world)
			if not soft and not id.begins_with("teach_"):
				c.begin() # 멈춤 안내·방 입장 대본은 세라를 멈춰 세우지 않음 (필요하면 대본이 c.lock())
			else:
				c.soft()
			await Callable(s, id).call(c)
			if gen != _gen:
				return
			c.finish()
			_busy = maxi(_busy - 1, 0)
			return
	push_warning("Story: no script '%s'" % id)


## 방에 들어올 때 (enter_<방ID> 메서드가 있으면 실행)
func on_room_entered(room_id: String, _respawn: bool) -> void:
	var id := "enter_" + room_id
	if has_script(id):
		run(id, true)


## 쓰러져 부활할 때: 진행 중이던 컷신을 버린다
func reset() -> void:
	_gen += 1
	_busy = 0
	if world:
		world.dialogue.close()
		world.player.controls_enabled = true
		world.hud.visible = true


func toast(text: String, time := 2.4) -> void:
	if world:
		world.notice.toast(text, time)


func item_get(title: String, desc: String, icon := "") -> void:
	if world:
		world.notice.item_get(title, desc, icon)


## 게시판·책 읽기: 초상화 없는 대화창으로 한 쪽씩
func read(pages: Array) -> void:
	if world == null or busy():
		return
	_busy += 1
	var gen := _gen
	var c := Cut.new(world)
	c.begin()
	for p in pages:
		if gen != _gen:
			return
		await c.narrate(String(p))
	if gen == _gen:
		c.finish()
		_busy = maxi(_busy - 1, 0)
