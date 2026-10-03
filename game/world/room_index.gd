class_name RoomIndex
extends RefCounted
## 모든 방 ID 목록 (지도 화면·연결 검사용). 방을 추가하면 여기에도 적는다.

const ROOMS := [
	# 신계 (프롤로그)
	"t_pass", "t_forest", "t_stairs", "t_trial", "t_throne", "t_collapse", "t_gate",
	# 마녀학교
	"s_infirmary", "s_dorm", "s_eastcorr", "s_hall", "s_westcorr", "s_class", "s_training",
	"s_nonelem", "s_levcourse", "s_library", "s_stacks", "s_archive", "s_gallery", "s_advclass",
	"s_clock", "s_headmaster", "s_courtyard", "s_greenhouse", "s_cafeteria", "s_alchemy",
	"s_cellar", "s_sealcorr", "s_sealroom",
]

static var _cache := {}


static func data(id: String) -> RoomData:
	if _cache.has(id):
		return _cache[id]
	var path := "res://world/rooms/%s.gd" % id
	if not ResourceLoader.exists(path):
		return null
	var d: RoomData = (load(path) as GDScript).new()
	_cache[id] = d
	return d
