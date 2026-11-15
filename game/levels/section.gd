@tool
class_name Section
extends Node2D
## 레벨의 한 구간. 같은 번호의 체크포인트에서 다시 시작할 때, 그보다 앞 구간의 적은 만들지 않는다.

@export var index := 0 ## 0부터. 같은 번호의 체크포인트와 짝
@export var title := "구간"
@export var start_x := 0.0 ## 구간 시작 x (px). HUD의 구간 표시용
