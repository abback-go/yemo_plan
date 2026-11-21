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
	"scale": 0.9946,
	"parts": [
		{
			"name": "leg_l",
			"file": "anim/sera_leg_l.png",
			"parent": "root",
			"z": 0,
			"pos": [
				98.7,
				582.8
			],
			"size": [
				106,
				515
			],
			"pivot": [
				151.4,
				617.6
			]
		},
		{
			"name": "leg_r",
			"file": "anim/sera_leg_r.png",
			"parent": "root",
			"z": 0,
			"pos": [
				230.0,
				582.8
			],
			"size": [
				127,
				517
			],
			"pivot": [
				292.6,
				617.6
			]
		},
		{
			"name": "torso",
			"file": "anim/sera_torso.png",
			"parent": "root",
			"z": 1,
			"pos": [
				121.5,
				165.1
			],
			"size": [
				203,
				425
			],
			"pivot": [
				222.0,
				567.9
			]
		},
		{
			"name": "cape",
			"file": "anim/sera_cape.png",
			"parent": "torso",
			"z": 4,
			"pos": [
				41.5,
				203.9
			],
			"size": [
				362,
				698
			],
			"pivot": [
				222.0,
				219.8
			]
		},
		{
			"name": "arm_l_up",
			"file": "anim/sera_arm_l_up.png",
			"parent": "torso",
			"z": 5,
			"pos": [
				67.8,
				259.6
			],
			"size": [
				76,
				150
			],
			"pivot": [
				104.6,
				267.5
			]
		},
		{
			"name": "arm_l_lo",
			"file": "anim/sera_arm_l_lo.png",
			"parent": "arm_l_up",
			"z": 5,
			"pos": [
				51.9,
				398.8
			],
			"size": [
				88,
				249
			],
			"pivot": [
				94.7,
				406.8
			]
		},
		{
			"name": "sword",
			"file": "anim/sera_sword.png",
			"parent": "torso",
			"z": 5,
			"pos": [
				292.6,
				257.6
			],
			"size": [
				182,
				909
			],
			"pivot": [
				338.4,
				269.5
			]
		},
		{
			"name": "pauld_l",
			"file": "anim/sera_pauld_l.png",
			"parent": "torso",
			"z": 6,
			"pos": [
				69.8,
				162.1
			],
			"size": [
				129,
				146
			],
			"pivot": [
				133.5,
				249.6
			]
		},
		{
			"name": "pauld_r",
			"file": "anim/sera_pauld_r.png",
			"parent": "torso",
			"z": 6,
			"pos": [
				246.9,
				162.1
			],
			"size": [
				128,
				146
			],
			"pivot": [
				310.5,
				249.6
			]
		},
		{
			"name": "hair",
			"file": "anim/sera_hair.png",
			"parent": "torso",
			"z": 7,
			"pos": [
				125.5,
				0.0
			],
			"size": [
				194,
				371
			],
			"pivot": [
				222.0,
				190.0
			]
		},
		{
			"name": "braid",
			"file": "anim/sera_braid.png",
			"parent": "hair",
			"z": 8,
			"pos": [
				172.3,
				110.4
			],
			"size": [
				101,
				600
			],
			"pivot": [
				222.0,
				114.4
			]
		}
	]
}
