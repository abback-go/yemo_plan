class_name ECauldron
extends Node2D
## 마녀의 가마솥 (쉼터): 앞에 서서 ↑(터치: 달이기 버튼)를 누르면 달이기 화면 → 재료 2~3개로 물약을 달여 허리띠 칸에 넣는다.
## 들르기만 해도 허리띠 물약이 가득 찬다. 기준서: docs/eska/design.md 4장.


## 장면(stage)의 pos(발밑)에 가마솥 하나를 놓는다
static func place(stage: Node, pos: Vector2) -> ECauldron:
	var c := ECauldron.new()
	c.position = pos
	stage.add_child(c)
	return c
