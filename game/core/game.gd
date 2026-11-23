## G (autoload) — 게임 전체에서 쓰는 등록부(HTML 판의 window.Game 과 같은 역할).
## Main 이 화면 레이어와 각 부분(전투 화면·손패·입력·대사창·장면)을 만들어 여기에 등록한다.
extends Node

var D: Dictionary = GameData.D
var S: Dictionary = ScriptData.S

# 등록되는 부분 (main.gd 가 채운다)
var main: Node
var ctl: Ctl           # 장면 흐름·전투 진행 (core/ctl.gd)
var guide: Guide       # 튜토리얼 안내 트리거 (core/guide.gd)
var view: BattleView   # 전투 화면 + 마녀의 손(view.hand) (ui/battle_view.gd, ui/hand.gd)
var input: BattleInput # 전투 드래그 조작 (ui/battle_input.gd)
var dialog: DialogBox  # 대사창·안내 상자 (ui/dialog_box.gd)
var scenes: Scenes     # 타이틀·VN·탐색·컷신·종료 (scenes/scenes.gd)
var cutin: Cutin       # 컷인 (ui/cutin.gd)
var menu: GameMenu     # 메뉴 단추(화면 오른쪽 위)·일시정지·설정·확인 창 (ui/game_menu.gd)
var go_title := false  # 타이틀로(일시정지 메뉴): 게임 화면을 새로 만든 뒤 주소의 scene= 대신 타이틀을 연다 (main.gd)

var params := {}       # 주소 뒤 옵션 (?seed=7&speed=4&scene=giant&test=1&autoguide=1)
var test := false
var autoguide := false # 안내 상자도 일정 시간 뒤 저절로 넘김(자동 테스트용)
var stage_scale := 1.0


func name_of(who: String) -> String:
	return str(S.names.get(who, who))


## 새 전투(v2 「3D 탁자」)가 기본 — 옛 전투는 ?battle=v1(헤드리스 --battle=v1). ?battle=v2 는 시험 전투 하나로 바로 가기(main.gd) (밤샘 계획 2 A)
func battle_v2() -> bool:
	return str(params.get("battle", "")) != "v1"


## 카드 이름(문구용 — 방에서 얻은 카드·좌판·훈련): 새 전투면 그 짝 카드(RulesV2.def_from_v1)의 이름(Lv2 포함), 옛 전투면 옛 카드 이름
func card_label(v1id: String, up := false) -> String:
	if battle_v2():
		var d := RulesV2.def_from_v1(v1id, up)
		if not d.is_empty():
			return str(d.name)
	return Rules.card_name(v1id, up)


## 화면 문구 (script_data.gd "ui") — {n} 같은 자리를 args 로 채운다
func ui(key: String, args := {}) -> String:
	return _fill(str(S.ui.get(key, key)), args)


## 메뉴 문구 (script_data.gd "menu")
func menu_text(key: String, args := {}) -> String:
	return _fill(str(S.menu.get(key, key)), args)


func _fill(s: String, args: Dictionary) -> String:
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
	# 개발용 바로 가기(?scene= / --scene=)로 연 판은 --nosave 처럼 — 플레이어의 자동 저장·설정 파일을 쓰지도 읽지도 않는다.
	# 바로 가기 판을 일부러 저장하려면(헤드리스로 이어하기 시험: 저장하며 돌리다 끊고 --continue) --save(?save=1)를 함께
	# 전투 시험판 v2(?battle=v2 / --battle=v2)도 바로 가기처럼 저장하지 않는다
	if (params.has("scene") or str(params.get("battle", "")) == "v2") and not params.has("save"):
		params["nosave"] = ""
	test = params.has("test")
	autoguide = params.has("autoguide")
	if params.has("speed"):
		FX.speed = maxf(0.1, float(params.speed))
