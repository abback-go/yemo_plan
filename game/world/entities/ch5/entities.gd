extends RefCounted
## 5장 방 개체 종류 → 스크립트 (WorldEntities가 합침). 스크립트는 setup(room, e, eid)
##   st_awaken         너울 본모습 + 아홉 꼬리 각성 (actor처럼 대본이 c.actor(who)로 움직임)
##   st_colossus_ride  반격 구간: 팔 위를 달려 오르는 거신 발판
##   st_quake          땅울림: 배경 거신 행진과 같은 박자의 화면 흔들림

const KINDS := {
	"st_awaken": "res://world/entities/ch5/ninetail_awaken.gd",
	"st_colossus_ride": "res://world/entities/ch5/colossus_ride.gd",
	"st_quake": "res://world/entities/ch5/quake.gd",
}
