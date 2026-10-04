extends Node
## 이야기 진행 (오토로드 Story). 컷신·대화·읽기·안내를 실행하고, 방에 들어올 때의 이벤트를 부른다.
## 대본은 story/<장>/*.gd 의 공개 메서드 (이름 = 실행 ID). 메서드는 Cut을 받아 await로 순서대로 진행한다.
## 읽을 파일은 각 story/data_<장>.gd 의 SCRIPTS (ChapterRegistry.script_paths). 작성 안내: docs/dev/story.md

var world: World
var _busy := 0
var _scripts: Array = []
var _index := {} ## 대본 ID → 그 메서드를 가진 대본 객체 (로드할 때 한 번 만듦)
var _gen := 0 ## 부활·타이틀 이동 시 진행 중이던 컷신을 무효화


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var paths: Array = []
	for path in ChapterRegistry.script_paths():
		if ResourceLoader.exists(path):
			paths.append(path)
		else:
			push_error("Story: 대본 파일 없음 %s (data_<장>.gd SCRIPTS 확인)" % path)
	var batch := _compile_together(paths) # 아래 load가 캐시에서 바로 나오게 함수 끝까지 붙잡아 둠
	for path: String in paths:
		var gd := load(path) as GDScript
		var obj: Object = gd.new()
		_scripts.append(obj)
		_add_index(obj, path)
	batch = null


## 대본 파일들을 한 번의 컴파일로 읽는다. 파일마다 따로 load하면 Cut·World·Player 같은 의존 스크립트 분석을
## 파일 수만큼 되풀이한다 (대본 36개에서 시작 CPU +1.5초를 쟀음). preload를 모은 임시 스크립트 하나로 읽으면
## 의존 분석을 한 번만 해서 예전(파일 8개) 수준으로 돌아온다. 실패하면 null — 그래도 아래 load가 하나씩 읽는다
func _compile_together(paths: Array) -> GDScript:
	var src := "extends RefCounted\n"
	for i in paths.size():
		src += "const _S%d = preload(\"%s\")\n" % [i, paths[i]]
	var gd := GDScript.new()
	gd.source_code = src
	return gd if gd.reload() == OK else null


## 공개 메서드(_로 시작하지 않는 것)를 대본 ID로 색인. 같은 ID가 두 파일에 있으면 앞 파일을 쓰고 오류를 남긴다
func _add_index(obj: Object, path: String) -> void:
	for m in (obj.get_script() as GDScript).get_script_method_list():
		var id := String(m.name)
		if id.begins_with("_") or id.begins_with("@"):
			continue
		if _index.has(id):
			var prev: Object = _index[id]
			if prev != obj:
				push_error("Story: 대본 ID '%s'가 %s 와 %s 에 둘 다 있다 — 앞 파일 것을 쓴다" % [id, (prev.get_script() as GDScript).resource_path, path])
			continue
		_index[id] = obj


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
	return _index.has(id)


## 다른 대본을 같은 Cut으로 이어서 실행 (잠금·대사창을 그대로 넘김 — 메서드를 직접 부르는 것과 같음).
## 대본이 다른 파일에 있을 때 c.call_script(id)가 쓴다
func call_in(id: String, c: Cut) -> void:
	var s: Object = _index.get(id)
	if s == null:
		push_warning("Story: no script '%s'" % id)
		return
	await Callable(s, id).call(c)


## 컷신·대화 실행. 세라 조작은 끝날 때까지 잠긴다
func run(id: String, soft := false) -> void:
	if id == "" or world == null:
		return
	# 진행 중인 퀘스트가 지금 단계에서 이 인물과의 대화를 기다리면 그 대본 (퀘스트 정의의 talk: [[단계, 인물, 대본ID], ...])
	if id.begins_with("npc_"):
		var hook := Quests.talk_hook(id.substr(4))
		if hook != "" and has_script(hook):
			id = hook
	# 인물 대화는 지금 장의 덮어쓰기(npc_<who>_ch<N>)가 있으면 그것을 쓴다 (docs/bible/progression.md 5절)
	if id.begins_with("npc_"):
		for n in range(int(GameState.flag("chapter", 1)), 1, -1):
			var alt := "%s_ch%d" % [id, n]
			if has_script(alt):
				id = alt
				break
	var s: Object = _index.get(id)
	if s == null:
		push_warning("Story: no script '%s'" % id)
		return
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
