## 모든 스크립트·셰이더를 불러와 문법·타입 오류가 없는지 확인한다 (헤드리스).
## 자동 로드(G·FX·Assets)가 필요하므로 게임을 띄운 채로 검사한다:
##   godot --headless --path game -- --check-scripts
## 마지막 줄 "scripts: N ok, failures: M" — M 이 0 이어야 통과(종료 코드도 0).
class_name CheckScripts
extends RefCounted

var ok := 0
var fails := 0


func run() -> int:
	_walk("res://")
	print("scripts: %d ok, failures: %d" % [ok, fails])
	return fails


func _walk(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		var p := dir.path_join(f)
		if f.ends_with(".gd") or f.ends_with(".gdshader"):
			var r = load(p)
			var good: bool = r != null
			if good and r is GDScript:
				good = r.can_instantiate() or r.get_instance_base_type() != &""
			if good:
				ok += 1
			else:
				fails += 1
				print("  ✘ " + p)
	for sub in d.get_directories():
		if sub.begins_with(".") or sub == "tools" or sub == "web":
			continue
		_walk(dir.path_join(sub))
