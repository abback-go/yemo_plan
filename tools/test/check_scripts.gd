extends SceneTree
var _done := false
func _process(_d: float) -> bool:
	if _done: return true
	_done = true
	var bad := 0
	var files := []
	_collect("res://", files)
	for f in files:
		var s = ResourceLoader.load(f, "", ResourceLoader.CACHE_MODE_IGNORE)
		if s == null or (s is GDScript and not s.can_instantiate() and not f.ends_with("game_const.gd") and not f.ends_with("palette.gd")):
			print("FAIL ", f)
			bad += 1
	print("CHECKED ", files.size(), " scripts, failures: ", bad)
	return true
func _collect(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"): out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if not d.begins_with("."): _collect(dir.path_join(d), out)
