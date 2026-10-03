extends RefCounted
## 2장 방 개체 종류 → 스크립트 (WorldEntities가 합침). 스크립트는 setup(room, e, eid)

const KINDS := {
	"k_pose": "res://world/entities/ch2/k_pose.gd", ## 자세를 잡은 인물 (그림만, 컷신 배우로도 씀)
	"k_crystal_wall": "res://world/entities/ch2/crystal_wall.gd", ## 별 수정 장벽: 되쏜 탄에만 깨짐 (불꽃 방벽 게이트)
	"k_valve": "res://world/entities/ch2/valve.gd", ## 수문 밸브: ↑로 플래그 뒤집기
	"k_water": "res://world/entities/ch2/water.gd", ## 수위가 오르내리는 물 (빠지면 바닥 길, 차면 떠밀림)
	"k_raft": "res://world/entities/ch2/raft.gd", ## 수면에 뜬 뗏목 (통과 발판)
	"k_clock_dial": "res://world/entities/ch2/clock_dial.gd", ## 톱니 시계판: 불을 맞히면 한 시간씩
}
