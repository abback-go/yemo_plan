## G (autoload) — 게임 전체에서 쓰는 등록부(HTML 판의 window.Game 과 같은 역할).
## Main 이 화면 레이어와 각 부분(전투 화면·손패·입력·대사창·장면)을 만들어 여기에 등록한다.
extends Node

var D: Dictionary = GameData.D
var S: Dictionary = ScriptData.S

# 등록되는 부분 (main.gd 가 채운다)
var main: Node
var ctl: Node          # 장면 흐름·전투 진행 (core/ctl.gd)
var view: Node2D       # 전투 화면 (ui/battle_view.gd)
var hand: Node2D       # 마녀의 손과 손패 (ui/hand.gd)
var input: Node        # 전투 드래그 조작 (ui/battle_input.gd)
var dialog: Node2D     # 대사창·안내 상자 (ui/dialog_box.gd)
var scenes: Node       # 타이틀·캠프·컷신·탐색·종료 (scenes/scenes.gd)
var cutin: Node2D      # 컷인 (ui/cutin.gd)
var debug: Node        # 디버그 패널
var L := {}            # 레이어 노드 {"world", "bg", "enemies", ...}

var params := {}       # 주소 뒤 옵션 (?seed=7&speed=4&scene=giant&test=1&autoguide=1)
var test := false
var autoguide := false # 안내 상자도 일정 시간 뒤 저절로 넘김(자동 테스트용)
var stage_scale := 1.0


func name_of(who: String) -> String:
	return str(S.names.get(who, who))


## 화면 문구 (script_data.gd "ui") — {n} 같은 자리를 args 로 채운다
func ui(key: String, args := {}) -> String:
	var s := str(S.ui.get(key, key))
	for k in args:
		s = s.replace("{" + str(k) + "}", str(args[k]))
	return s


func read_params() -> void:
	params = {}
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("location.search", true)
		if q is String:
			for kv: String in str(q).trim_prefix("?").split("&", false):
				var p: PackedStringArray = kv.split("=")
				params[p[0].uri_decode()] = p[1].uri_decode() if p.size() > 1 else ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var p: PackedStringArray = a.substr(2).split("=")
			params[p[0]] = p[1] if p.size() > 1 else ""
	test = params.has("test")
	autoguide = params.has("autoguide")
	if params.has("speed"):
		FX.speed = maxf(0.1, float(params.speed))
