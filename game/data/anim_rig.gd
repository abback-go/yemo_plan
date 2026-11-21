## 자동 생성 — tools/anim_parts.py (움직임 시험 C ?anim=c: 세라피나 부위 배치). 손으로 고치지 말고 도구를 다시 돌린다.
## 좌표는 뒷모습 spr_hero_back.png 틀(507×1100) 기준: pos = 그림 왼쪽 위, pivot = 관절(부모 기준 회전 중심)
class_name AnimRig
extends RefCounted

const SERA := {
	"frame": [
		507,
		1100
	],
	"source": "art/raw/vs/04_seraphina_parts.webp",
	"scale": 0.9378,
	"parts": [
		{
			"name": "leg_l",
			"file": "anim/sera_leg_l.png",
			"parent": "root",
			"z": 0,
			"pos": [
				105.7,
				549.5
			],
			"size": [
				100,
				486
			],
			"pivot": [
				155.4,
				582.4
			]
		},
		{
			"name": "leg_r",
			"file": "anim/sera_leg_r.png",
			"parent": "root",
			"z": 0,
			"pos": [
				229.5,
				549.5
			],
			"size": [
				120,
				488
			],
			"pivot": [
				288.6,
				582.4
			]
		},
		{
			"name": "torso",
			"file": "anim/sera_torso.png",
			"parent": "root",
			"z": 1,
			"pos": [
				127.3,
				155.7
			],
			"size": [
				191,
				400
			],
			"pivot": [
				222.0,
				535.5
			]
		},
		{
			"name": "cape",
			"file": "anim/sera_cape.png",
			"parent": "torso",
			"z": 4,
			"pos": [
				51.8,
				192.2
			],
			"size": [
				341,
				658
			],
			"pivot": [
				222.0,
				207.2
			]
		},
		{
			"name": "arm_l_up",
			"file": "anim/sera_arm_l_up.png",
			"parent": "torso",
			"z": 5,
			"pos": [
				76.6,
				244.8
			],
			"size": [
				71,
				142
			],
			"pivot": [
				111.3,
				252.3
			]
		},
		{
			"name": "arm_l_lo",
			"file": "anim/sera_arm_l_lo.png",
			"parent": "arm_l_up",
			"z": 5,
			"pos": [
				61.6,
				376.0
			],
			"size": [
				83,
				234
			],
			"pivot": [
				102.0,
				383.5
			]
		},
		{
			"name": "sword",
			"file": "anim/sera_sword.png",
			"parent": "torso",
			"z": 5,
			"pos": [
				288.6,
				242.9
			],
			"size": [
				172,
				857
			],
			"pivot": [
				331.7,
				254.1
			]
		},
		{
			"name": "pauld_l",
			"file": "anim/sera_pauld_l.png",
			"parent": "torso",
			"z": 6,
			"pos": [
				78.5,
				152.9
			],
			"size": [
				122,
				138
			],
			"pivot": [
				138.5,
				235.4
			]
		},
		{
			"name": "pauld_r",
			"file": "anim/sera_pauld_r.png",
			"parent": "torso",
			"z": 6,
			"pos": [
				245.4,
				152.9
			],
			"size": [
				121,
				138
			],
			"pivot": [
				305.5,
				235.4
			]
		},
		{
			"name": "hair",
			"file": "anim/sera_hair.png",
			"parent": "torso",
			"z": 7,
			"pos": [
				131.0,
				0.0
			],
			"size": [
				183,
				350
			],
			"pivot": [
				222.0,
				179.1
			]
		},
		{
			"name": "braid",
			"file": "anim/sera_braid.png",
			"parent": "hair",
			"z": 8,
			"pos": [
				175.1,
				104.1
			],
			"size": [
				96,
				565
			],
			"pivot": [
				222.0,
				107.8
			]
		}
	]
}
