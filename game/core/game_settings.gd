## game_settings.gd — 설정: 화면(창·전체 화면)과 글자 속도(대사가 나오는 빠르기). 소리 항목은 아직 없다.
## user://settings.cfg(ConfigFile)에 저장하고 시작할 때 불러온다(main.gd). 웹은 user:// 가 브라우저 저장소에 남는다.
## 화면: 데스크톱은 저장한 값을 시작할 때 적용한다. 웹은 브라우저가 사용자 입력(클릭) 안에서만 전체 화면을 허락하므로
##       저장하지 않고 지금 상태만 보여 준다 — 버튼을 누른 그 처리 안에서 바꾼다(game_menu.gd).
## --nosave(시험 실행): 설정 파일도 읽지도 쓰지도 않는다(기본값으로).
class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"
const SPEEDS := ["slow", "normal", "fast", "instant"]

static var text_speed := "normal"
static var fullscreen := false
static var persist := true


static func load_file() -> void:
	if not persist:
		return
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	var sp := str(cf.get_value("text", "speed", "normal"))
	text_speed = sp if sp in SPEEDS else "normal"
	fullscreen = bool(cf.get_value("display", "fullscreen", false))


static func save_file() -> void:
	if not persist:
		return
	var cf := ConfigFile.new()
	cf.set_value("text", "speed", text_speed)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.save(PATH)


## 시작할 때: 데스크톱이면 저장한 화면 모드를 적용한다
static func apply_display() -> void:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	if fullscreen != is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


## 전체 화면을 쓸 수 있는가. 웹은 브라우저에 물어본다(아이폰 Safari 는 video 밖의 요소를 전체 화면으로 하지 못한다)
static func fullscreen_available() -> bool:
	if not OS.has_feature("web"):
		return true
	return JavaScriptBridge.eval("!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)", true) == true


static func is_fullscreen() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## 버튼을 누른 처리 안에서 부른다(웹의 전체 화면 요청은 사용자 입력이 있어야 한다)
static func set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
	if not OS.has_feature("web"):
		fullscreen = on
		save_file()


static func set_text_speed(sp: String) -> void:
	if not sp in SPEEDS:
		return
	text_speed = sp
	save_file()


## 대사 글자가 1초에 몇 자 나오는가 (game_data.gd timing.typeCharsPerSec × typeSpeed). 즉시는 아주 큰 값
static func chars_per_sec() -> float:
	var T: Dictionary = GameData.D.timing
	var k := float(T.get("typeSpeed", {}).get(text_speed, 1.0))
	if k <= 0.0:
		return 100000.0
	return float(T.typeCharsPerSec) * k
