class_name SaveCodeUI
extends RefCounted
## 저장 코드 주고받기 (웹: 브라우저의 입력 창을 써서 휴대폰·태블릿에서도 복사·붙여넣기가 확실하게 됨)


## 코드를 보여 주고 복사해 둔다. 웹에선 코드가 미리 채워진 창이 떠서 길게 눌러 복사할 수도 있다
static func show_code(code: String) -> void:
	if not OS.has_feature("web"):
		DisplayServer.clipboard_set(code)
		return
	# 브라우저가 허락하면 바로 복사, 아니면 아래 창에서 직접 복사
	JavaScriptBridge.eval("try { navigator.clipboard.writeText(%s).catch(function(){}); } catch (e) {}" % JSON.stringify(code), true)
	JavaScriptBridge.eval("prompt(%s, %s)" % [JSON.stringify("저장 코드 (복사해 두었어요). 카톡 나에게 보내기·메모장 등에 붙여 두세요.\n다른 컴퓨터·태블릿의 타이틀 → '저장 코드로 이어하기'에 붙여 넣으면 이어집니다."), JSON.stringify(code)], true)


## 코드를 받아 온다 (취소하면 ""). 웹: 붙여 넣는 창, 그 밖: 클립보드
static func ask_code() -> String:
	if OS.has_feature("web"):
		var v: Variant = JavaScriptBridge.eval("(function(){ var s = prompt(%s, ''); return s === null ? '' : String(s); })()" % JSON.stringify("저장 코드를 붙여 넣으세요 (YEMO1-로 시작). 이 기기의 기록은 코드의 기록으로 바뀝니다."), true)
		return String(v) if v != null else ""
	return DisplayServer.clipboard_get()
