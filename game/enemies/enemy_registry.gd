class_name EnemyRegistry
extends RefCounted
## 적 종류 이름 → 만드는 방법. 방 데이터의 enemy 개체가 kind로 고른다 (docs/chapter1.md 7절, 12.5절).

const KINDS := {
	"charger": "res://enemies/charger.tscn", ## 프로토타입 돌진형
	"sniper": "res://enemies/sniper.tscn", ## 프로토타입 저격형
	"stone_fox": "res://enemies/stone_fox.gd",
	"lantern_watcher": "res://enemies/lantern_watcher.gd",
	"wisp": "res://enemies/wisp.gd",
	"haetae": "res://enemies/haetae.gd",
	"golem": "res://enemies/golem.gd",
	"broom": "res://enemies/broom.gd",
	"armor": "res://enemies/armor_knight.gd",
	"grimoire": "res://enemies/grimoire.gd",
	"slime": "res://enemies/alchemy_slime.gd",
	"hound": "res://enemies/shadow_hound.gd",
	"snapvine": "res://enemies/snapvine.gd",
	"agwi": "res://enemies/agwi.gd",
}


static func create(kind: String) -> EnemyBase:
	var path: String = KINDS.get(kind, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res := load(path)
	if res is PackedScene:
		return (res as PackedScene).instantiate() as EnemyBase
	if res is GDScript:
		return (res as GDScript).new() as EnemyBase
	return null
