class_name Credits
extends RefCounted
## 엔딩 크레디트 줄 (# 으로 시작하면 제목 줄). 5장 대본이 c.credits()로 띄운다.
## 가운데 인물 소개는 각 story/data_<장>.gd 의 CHAPTER.credits를 장 순서로 이어 붙인다 (장을 더하면 거기에).

const HEAD := [
	"# 마녀학교와 여우신",
	"",
]

const TAIL := [
	"",
	"# 만든 이",
	"기획 · 개발: abback-go 와 Claude",
	"그래픽 · 음악 · 효과음: 모두 코드로 그림",
	"엔진: Godot 4.7",
	"글꼴: Galmuri (OFL)",
	"",
	"",
	"# 플레이해 주셔서 고맙습니다",
	"",
	"…구슬은 조금만 더 맡겨 두마.",
]


static func lines() -> Array:
	var out: Array = HEAD.duplicate()
	for d: Dictionary in ChapterRegistry.chapters():
		out.append_array(d.get("credits", []))
	out.append_array(TAIL)
	return out
