/*
 * data.js — 수치·카드·적·대사·화면 배치를 모두 모아 둔 파일.
 * 이 파일만 고쳐도 코드 수정 없이 조정할 수 있다.
 * (브라우저: window.Game.DATA / Node: globalThis.Game.DATA)
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};

  Game.DATA = {
    meta: {
      title: '죽음을 보는 마녀',
      subtitle: '(가제) · 튜토리얼 프로토타입',
      startButton: '시작',
      note: '마우스·터치로 플레이 · ` (백틱) 키 또는 화면 오른쪽 위 구석 3번 탭: 디버그 패널'
    },

    // ───────────── 기본 규칙 (combat-system.md 2장) ─────────────
    rules: {
      energyPerTurn: 3,
      drawPerTurn: 5,          // 죽음 카드(보존)가 손에 있으면 그 장수만큼 덜 뽑는다
      maxHand: 10,             // 손패 상한 (넘치면 더 뽑지 않음)
      guardRound: 'floor',     // 감싸기 '절반' 반올림: floor | ceil
      downedReviveHp: 1,       // 전투 후 쓰러진 동료가 복귀하는 HP
      // 적이 대상을 고를 때 가중치 (스크립트 예고가 없는 턴)
      targetWeights: { witch: 1, hero: 1, warrior: 1, archer: 1 }
    },

    // ───────────── 캐릭터 (3장) ─────────────
    party: {
      witch: { name: '노엘', role: '마녀', hp: 15 },
      order: ['archer', 'hero', 'warrior'],   // 화면 왼쪽 → 오른쪽
      allies: {
        hero:    { name: '세라피나', short: '세라피나', role: '용사', hp: 30 },
        warrior: { name: '브룬힐드', short: '브룬힐드', role: '전사', hp: 24 },
        archer:  { name: '엘리안',   short: '엘리안',   role: '궁수', hp: 12 }
      }
    },

    // ───────────── 카드 (6장) ─────────────
    // kind: witch | ally | death | inherit | relic | wound
    // target: enemy(적 1명) | intent(예고 1개) | none(대상 없음)
    // text 안의 {dmg} {all} {draw} {self} {weaken} 은 effects 수치로 자동 치환된다.
    cards: {
      curse_flame: { name: '저주의 불꽃', kind: 'witch', owner: 'witch', cost: 1, target: 'enemy', art: 'flame',
        effects: [{ type: 'damage', amount: 6 }], text: '적 1명에게 {dmg} 피해' },
      fate_shift: { name: '운명 전가', kind: 'witch', owner: 'witch', cost: 1, target: 'intent', art: 'fate',
        effects: [{ type: 'redirect', to: 'choose' }], text: '예고된 공격 1개의 대상을 다른 아군으로 바꾼다' },
      take_hit: { name: '대신 받기', kind: 'witch', owner: 'witch', cost: 0, target: 'intent', art: 'hand',
        effects: [{ type: 'redirect', to: 'witch' }], text: '예고된 공격 1개를 노엘이 대신 받는다' },
      foresight: { name: '죽음의 예지', kind: 'witch', owner: 'witch', cost: 1, target: 'none', art: 'eye',
        effects: [{ type: 'draw', count: 2 }], text: '카드 {draw}장을 뽑는다' },

      holy_slash: { name: '성검 베기', kind: 'ally', owner: 'hero', cost: 1, target: 'enemy', art: 'sword',
        effects: [{ type: 'damage', amount: 14 }], text: '적 1명에게 {dmg} 피해' },
      vanguard: { name: '선봉', kind: 'ally', owner: 'hero', cost: 1, target: 'none', art: 'charge',
        effects: [{ type: 'damageAll', amount: 6 }], text: '모든 적에게 {all} 피해' },

      cover: { name: '감싸기', kind: 'ally', owner: 'warrior', cost: 1, target: 'intent', art: 'shield',
        effects: [{ type: 'redirect', to: 'warrior', halve: true }], text: '예고된 공격 1개를 브룬힐드가 받되 피해 절반' },
      shield_bash: { name: '방패 강타', kind: 'ally', owner: 'warrior', cost: 1, target: 'enemy', art: 'bash',
        effects: [{ type: 'damage', amount: 6 }], text: '적 1명에게 {dmg} 피해' },

      snipe: { name: '저격', kind: 'ally', owner: 'archer', cost: 1, target: 'enemy', art: 'arrow',
        effects: [{ type: 'damage', amount: 8 }], text: '적 1명에게 {dmg} 피해' },
      suppress: { name: '견제 사격', kind: 'ally', owner: 'archer', cost: 1, target: 'enemy', art: 'arrows',
        effects: [{ type: 'damage', amount: 3 }, { type: 'weaken', amount: 4 }], text: '적 1명에게 {dmg} 피해 + 그 적의 이번 공격 피해 -{weaken}' },

      // 죽음 카드 (6.3) — 비용 0, 손패 보존, 사용 시 용사 사망 → 유품 변환 → 짓밟힘 획득
      hero_death: { name: '용사의 죽음', kind: 'death', ally: 'hero', owner: 'witch', cost: 0, target: 'none', art: 'deathface',
        retain: true, exhaust: true,
        effects: [
          { type: 'killAlly', ally: 'hero' },
          { type: 'relicize', ally: 'hero' },
          { type: 'addCard', card: 'trample', permanent: true, freeThisTurn: true, at: 'source' }
        ],
        text: '세라피나는 이곳에서 짓밟혀 죽는다.\n내면, 지금 일어난다.',
        tags: ['보존', '사용 시 짓밟힘 획득'] },

      // 상속 카드
      trample: { name: '짓밟힘', kind: 'inherit', owner: 'witch', from: 'hero', cost: 2, target: 'none', art: 'foot',
        effects: [{ type: 'damageAll', amount: 15 }], text: '모든 적에게 {all} 피해\n획득한 턴에는 비용 0',
        tags: ['상속'] },

      // 유품 카드 (용사)
      broken_sword: { name: '부러진 성검', kind: 'relic', owner: 'hero', cost: 1, target: 'enemy', art: 'brokensword',
        effects: [{ type: 'damage', amount: 20 }, { type: 'selfDamage', amount: 3 }], text: '적 1명에게 {dmg} 피해\n노엘 HP -{self}' },
      last_charge: { name: '용사의 마지막 돌격', kind: 'relic', owner: 'hero', cost: 1, target: 'none', art: 'lastcharge',
        effects: [{ type: 'damageAll', amount: 9 }, { type: 'selfDamage', amount: 2 }], text: '모든 적에게 {all} 피해\n노엘 HP -{self}' },
      // 유품 카드 (궁수, 참고용 — 튜토리얼에서는 나오지 않음)
      archer_arrow: { name: '궁수의 화살', kind: 'relic', owner: 'archer', cost: 1, target: 'enemy', art: 'arrow',
        effects: [{ type: 'damage', amount: 12 }, { type: 'selfDamage', amount: 2 }], text: '적 1명에게 {dmg} 피해\n노엘 HP -{self}' },
      archer_last_suppress: { name: '궁수의 마지막 견제', kind: 'relic', owner: 'archer', cost: 1, target: 'enemy', art: 'arrows',
        effects: [{ type: 'damage', amount: 4 }, { type: 'weaken', amount: 6 }, { type: 'selfDamage', amount: 1 }],
        text: '적 1명에게 {dmg} 피해 + 이번 공격 피해 -{weaken}\n노엘 HP -{self}' },

      // 상처 카드 (5장)
      wound: { name: '상처', kind: 'wound', owner: null, cost: 0, target: 'none', art: 'wound', unplayable: true,
        effects: [], text: '낼 수 없다. 손패만 차지한다.' }
    },

    // 동료가 죽으면 그 동료의 카드가 이것으로 바뀐다
    relicMap: {
      holy_slash: 'broken_sword',
      vanguard: 'last_charge',
      snipe: 'archer_arrow',
      suppress: 'archer_last_suppress'
    },

    // 튜토리얼 시작 덱 15장 (6.2)
    startingDeck: [
      ['curse_flame', 2], ['fate_shift', 2], ['take_hit', 1], ['foresight', 1],
      ['holy_slash', 2], ['vanguard', 1],
      ['cover', 2], ['shield_bash', 1],
      ['snipe', 2], ['suppress', 1]
    ],

    // ───────────── 적 ─────────────
    enemies: {
      cultist: { name: '광신도', hp: 14, sprite: 'spr_cultist.png' },
      giant: { name: '거대한 존재', hp: null, immune: true, retreatOn: 'trample', sprite: 'spr_giant_foot.png' }
    },

    // ───────────── 전투 (7장) ─────────────
    encounters: {
      normal: {
        kind: 'normal',
        enemies: [{ id: 'c1', type: 'cultist', slot: 0 }, { id: 'c2', type: 'cultist', slot: 1 }, { id: 'c3', type: 'cultist', slot: 2 }],
        attackRange: [5, 6],            // 광신도 공격 5~6
        giantTriggerAlive: 1,           // 광신도가 이 수만큼 남으면 거대 존재가 짓밟는다
        // 튜토리얼 각 턴의 예고 (없으면 무작위)
        scriptedIntents: {
          1: { c1: { value: 5, target: 'warrior' }, c2: { value: 6, target: 'hero' }, c3: { value: 5, target: 'archer' } },
          2: { c1: { value: 6, target: 'archer' }, c2: { value: 6, target: 'archer' }, c3: { value: 6, target: 'archer' } }
        },
        // 튜토리얼 각 턴의 손패 (덱에 있으면 그 카드를 뽑는다. 없으면 무작위)
        scriptedHands: {
          1: ['holy_slash', 'curse_flame', 'shield_bash', 'foresight', 'take_hit'],
          2: ['fate_shift', 'cover', 'snipe', 'curse_flame', 'holy_slash']
        }
      },
      giant: {
        kind: 'giant',
        enemies: [{ id: 'giant', type: 'giant', slot: 'giant' }],
        // 3턴 카운트다운 (마지막 항목이 계속 반복)
        countdown: [
          { kind: 'shadow', label: '그림자', detail: '행동 없음' },
          { kind: 'aoe', label: '기둥 붕괴', value: 5, hitsWitch: true, detail: '아군 전원' },
          { kind: 'stomp', label: '짓밟기', detail: '전원 사망', lethal: true }
        ],
        turnStartCards: { 1: ['hero_death'] }   // 거대 존재 전투 1턴 시작 시 죽음 카드
      }
    },

    // ───────────── 전투 중 안내 대사 ─────────────
    // who: hero | warrior | archer | noel | inner(노엘 속마음) | system(안내 상자: 규칙 설명은 여기로)
    // face: 표정 그림 이름(예: 'hero_smile' → face_hero_smile.png). 없으면 스탠딩에서 잘라 쓴 얼굴
    // faces: 한 대사 안에서 표정이 바뀔 때(글자가 다 나온 뒤 차례로 바뀐다)
    // on: battleStart | turnStart | cardPlayed | redirect | energyOut | allyDown | immune | afterDeath | restart
    guide: [
      { id: 'n_start', on: 'battleStart', enc: 'normal', lines: [
        { who: 'hero', face: 'hero_determined', text: '광신도 셋. 평소대로 간다. 앞은 내가 연다. 노엘, 운명은 네 몫이야.' }] },
      { id: 'n_t1', on: 'turnStart', enc: 'normal', turn: 1, lines: [
        { who: 'hero', face: 'hero_calm', text: '가운데부터 친다. 엘리안, 뒤는 맡겼어.' },
        { who: 'system', text: '카드를 끌어 적 위에 놓으면 사용합니다. 카드 왼쪽 위 숫자가 비용, 에너지는 매 턴 3.' },
        { who: 'system', text: '대상이 없는 카드는 손패 위쪽으로 끌어올려 놓습니다. 에너지를 다 쓰면 오른쪽 아래 「턴 종료」.' }] },
      { id: 'n_sword', on: 'cardPlayed', enc: 'normal', card: 'holy_slash', once: true, lines: [
        { who: 'hero', face: 'hero_smile', text: '하나. 오늘은 칼이 잘 드네.' }] },
      { id: 'n_energy', on: 'energyOut', enc: 'normal', once: true, lines: [
        { who: 'system', text: '에너지를 다 썼습니다. 「턴 종료」를 누르면 적의 차례입니다.' }] },
      { id: 'n_t2', on: 'turnStart', enc: 'normal', turn: 2, lines: [
        { who: 'hero', face: 'hero_determined', text: '셋 다 엘리안을 노린다. 브룬힐드, 엘리안 쪽 막아. 노엘, 누가 맞을지는 네가 정해.' },
        { who: 'warrior', face: 'warrior_stern', text: '맡겨라. 절반은 방패가 먹는다.' },
        { who: 'system', text: '적 머리 위의 예고 = 누구를, 얼마나. 예고에 마우스를 올리거나 탭하면 대상 선이 보입니다.' },
        { who: 'system', text: '「운명 전가」: 예고에 놓은 뒤 새로 맞을 아군을 고릅니다. 「감싸기」: 브룬힐드가 받되 피해 절반.' }] },
      { id: 'n_redirect', on: 'redirect', enc: 'normal', once: true, lines: [
        { who: 'hero', face: 'hero_smile', text: '좋아, 그 수야. 역시 우리 마녀지.' }] },
      { id: 'n_cover', on: 'cardPlayed', card: 'cover', once: true, lines: [
        { who: 'warrior', face: 'warrior_stern', text: '…이 정도는 아무것도 아니다.' }] },
      { id: 'n_down', on: 'allyDown', enc: 'normal', once: true, lines: [
        { who: 'hero', face: 'hero_shocked', text: '버텨! 금방 끝낸다!' },
        { who: 'system', text: '쓰러진 동료의 카드는 이번 전투에서 쓸 수 없습니다.' }] },

      { id: 'g_start', on: 'battleStart', enc: 'giant', lines: [
        { who: 'hero', face: 'hero_determined', text: '진형 유지! 저건… 내가 막는다!' },
        { who: 'system', text: '거대한 존재의 예고를 보세요. 3턴째에 「짓밟기」가 옵니다.' }] },
      { id: 'g_t1', on: 'turnStart', enc: 'giant', turn: 1, lines: [
        { who: 'inner', text: '…보인다. 저 발 아래의 세라피나가.' },
        { who: 'inner', text: '이 카드를 내면 그녀는 지금 죽는다. 그리고 그 죽음은— 내 것이 된다.' },
        { who: 'system', text: '「용사의 죽음」은 비용 0. 턴이 끝나도 버려지지 않고 손패에 남습니다.' }] },
      { id: 'g_immune', on: 'immune', once: true, lines: [
        { who: 'warrior', face: 'warrior_shocked', text: '…흠집 하나 안 난다. 우리 공격이, 전부.' }] },
      { id: 'g_immune_sword', on: 'immune', card: 'holy_slash', once: true, lines: [
        { who: 'hero', face: 'hero_shocked', text: '성검이… 들어가질 않아? 이런 건, 처음이야.' }] },
      { id: 'g_t2', on: 'turnStart', enc: 'giant', turn: 2, lines: [
        { who: 'hero', face: 'hero_shocked', text: '기둥이 무너진다! 다들 버텨!' }] },
      { id: 'g_t3', on: 'turnStart', enc: 'giant', turn: 3, lines: [
        { who: 'hero', face: 'hero_calm', text: '노엘. 늘 하던 말이야. 카드는 아끼다간 죽는 거야.' },
        { who: 'hero', face: 'hero_smile', text: '…써야 할 땐, 망설이지 마.' }] },
      { id: 'g_after', on: 'afterDeath', lines: [
        { who: 'inner', text: '그녀가 죽은 방식이, 내 손에 남았다.' },
        { who: 'system', text: '「짓밟힘」 — 이번 턴에는 비용 0. 손패 위쪽으로 끌어올려 사용하세요.' }] },
      { id: 'g_restart', on: 'restart', lines: [
        { who: 'system', text: '전멸했다. 거대한 존재가 나타난 직후로 돌아간다.' }] }
    ],

    // 거대 존재 등장 연출 중 대사
    giantAppear: {
      before: [{ who: 'hero', face: 'hero_determined', text: '…잠깐. 이 그림자는 뭐지?' }],
      after: [{ who: 'archer', face: 'archer_shocked', text: '광신도가… 한 번에…' }]
    },

    // ───────────── 캠프 대화 (비주얼노벨) ─────────────
    // show: 등장 인물과 자리 (L, C, R, FL, FR) / speaker: 말하는 사람 (narr = 내레이션, inner = 노엘 속마음)
    camp: {
      bg: 'bg_camp.png',
      script: [
        { speaker: 'narr', text: '무너진 성당의 곁방. 오늘 밤은 여기서 쉬기로 했다.' },
        { speaker: 'narr', text: '모닥불이 타닥거린다. 이 세계에서 따뜻한 건, 이런 불빛 정도뿐이다.' },
        { show: { warrior: 'L', hero: 'C', archer: 'R' }, speaker: 'hero', face: 'hero_smile', text: '자, 오늘 저녁. 세라피나 특제 스튜야.' },
        { speaker: 'archer', face: 'archer_smile', text: '…대장, 이거 어제랑 같은 거 아니에요?' },
        { speaker: 'hero', face: 'hero_smile', text: '어제 건 「특제」가 아니었지. 오늘은 소금을 넣었거든.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '소금 넣은 걸 특제라고 부르는 건 대장뿐이다.' },
        { speaker: 'hero', face: 'hero_smile', text: '불만 있으면 내일부터 브룬힐드가 해. 그 방패에다 끓이든가.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '……먹겠다.' },
        { speaker: 'archer', face: 'archer_smile', text: '(웃음) 노엘도 먹어요. 하루 종일 아무것도 안 먹었잖아요.' },
        { show: { warrior: 'FL', hero: 'L', archer: 'C', noel: 'FR' }, speaker: 'noel', text: '…괜찮아.' },
        { speaker: 'hero', face: 'hero_calm', text: '괜찮긴. 우리 마녀가 굶어서 예지가 흐려지면 큰일이지. 자, 받아.' },
        { speaker: 'inner', text: '그릇이 따뜻하다. 건네는 손도.' },
        { speaker: 'hero', face: 'hero_smile', text: '맛은 기대하지 마. 대신 뜨겁긴 할 거야.' },
        { speaker: 'noel', text: '……뜨거워.' },
        { speaker: 'hero', face: 'hero_smile', text: '거 봐. 살아 있다는 증거야.' },
        { speaker: 'archer', face: 'archer_smile', text: '내일이면 성당 제일 깊은 곳이죠. 이것만 끝내면 왕도에서 또 노래가 나오겠네요. 「잿빛 성당을 연 넷」.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '노래보다 남은 광신도가 먼저다. 냄새가 난다.' },
        { speaker: 'archer', face: 'archer_smile', text: '밥 먹는데 그런 말 하지 마요….' },
        { speaker: 'hero', face: 'hero_determined', text: '셋이든 서른이든, 평소대로야. 앞은 내가 연다.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '열린 앞을 지키는 건 내 방패다.' },
        { speaker: 'hero', face: 'hero_smile', text: '그래. 나는 베고, 너는 막고. 몇 년째 그 순서지.' },
        { speaker: 'archer', face: 'archer_smile', text: '저는요?' },
        { speaker: 'hero', face: 'hero_smile', text: '엘리안은 늘 하던 대로 뒤에서 우리 등을 봐 줘. 네 화살이 우리 목숨줄이야.' },
        { speaker: 'archer', face: 'archer_smile', text: '맡겨 주세요. 한 발도 안 놓칠게요.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '지난번엔 세 발 놓쳤다.' },
        { speaker: 'archer', face: 'archer_shocked', text: '그건 바람이 불어서였어요!' },
        { speaker: 'hero', face: 'hero_smile', text: '(웃음) 됐어, 됐어. 그 바람 덕에 내가 한 마리 더 벴으니까.' },
        { show: { warrior: 'FL', hero: 'C', archer: 'L', noel: 'FR' }, speaker: 'narr', text: '세라피나가 노엘 쪽으로 돌아앉는다.' },
        { speaker: 'hero', face: 'hero_calm', text: '노엘. 내일은 뭐가 보여? 네 예지가 틀린 적은 없잖아.' },
        { speaker: 'noel', text: '…늘 보이던 것.' },
        { speaker: 'hero', face: 'hero_smile', text: '그럼 됐어. 늘 하던 말이지만, 한 번 더.' },
        { speaker: 'hero', face: 'hero_calm', text: '카드는 아끼다간 죽는 거야. 써야 할 땐 망설이지 마.' },
        { speaker: 'noel', text: '…………' },
        { speaker: 'narr', text: '노엘은 목에 건 낡은 카드 묶음을 쥐었다. 오늘따라 묶음이 무겁다.' },
        { speaker: 'hero', face: 'hero_smile', text: '걱정 마. 우리가 누구야. 이 넷이 함께한 뒤로, 아무도 안 죽었어.' },
        { speaker: 'inner', text: '…보지 않으려 해도, 보인다.' },
        { speaker: 'archer', face: 'archer_smile', text: '대장, 이 일 끝나면 뭐 할 거예요?' },
        { speaker: 'hero', face: 'hero_smile', text: '음… 바다. 남쪽 바다를 한 번 보고 싶어. 다 같이 가자.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '바다는 짜다.' },
        { speaker: 'hero', face: 'hero_smile', text: '내 스튜보다는 덜 짜겠지.' },
        { speaker: 'archer', face: 'archer_smile', text: '그럼 저는 바닷가에서 노래할게요. 엘프 노래, 아직 한 번도 안 들려 드렸잖아요.' },
        { speaker: 'hero', face: 'hero_smile', text: '약속했다? 노엘, 너도 와야 해.' },
        { speaker: 'noel', text: '…응.' },
        { speaker: 'inner', text: '남쪽 바다. 기억해 둘게.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '이제 자라. 불은 내가 본다.' },
        { speaker: 'hero', face: 'hero_calm', text: '교대는 나야. 새벽에 깨워.' },
        { speaker: 'warrior', face: 'warrior_stern', text: '대장은 자라. 내일 제일 많이 싸우는 건 대장이다.' },
        { speaker: 'hero', face: 'hero_smile', text: '…그럼 고맙게. 다들, 잘 자.' },
        { show: {}, speaker: 'narr', text: '불씨가 하나둘 사그라든다.' },
        { speaker: 'inner', text: '모두가 잠든 뒤에도, 나는 오래 눈을 감지 못했다.' },
        { speaker: 'narr', text: '다음 날 — 성당의 가장 깊은 곳.' }
      ]
    },

    // ───────────── 용사 사망 컷신 (C1~C8) ─────────────
    // duration: 자동 진행까지의 시간(ms). 클릭하면 바로 다음 컷.
    cutscene: {
      cuts: [
        { id: 'C1', image: 'cut_hero_reverse.png', fallback: '../reference/images/07_cutscene_archer_v3_APPROVED.png',
          duration: 5200, zoom: [1.0, 1.06],
          lines: [{ who: 'hero', text: '…노엘? 왜 그런 얼굴이야.' }, { who: 'hero', text: '괜찮아. 앞은 내가 연다고 했잖아.' }] },
        { id: 'C2', image: 'cut_hero_reach.png', duration: 2600, zoom: [1.04, 1.12],
          lines: [{ who: 'hero', text: '노엘—' }] },
        { id: 'C3', code: 'impact', duration: 3200 },          // 흰 섬광 → 암전 → 강한 흔들림 → 피 튐(화면 위)
        { id: 'C4', image: 'cut_hero_crushed.png', duration: 1600 },
        // C5: C4 그림 자체를 움직인다 — 살짝 들렸다가(위로) 세게 내리찍기 + 확대 펄스 + 강한 흔들림 × slams, 마지막에 비트는 회전 흔들림.
        //     매번 화면 아래쪽(돌 틈)에 코드로 그린 피 번짐이 넓어진다.
        { id: 'C5', code: 'grind', image: 'cut_hero_crushed.png', duration: 4400, slams: 2, lift: 46, twistDeg: 2.2 },
        // (C5 피 번짐 위치: cutscene.pool)
        { id: 'C6', image: 'cut_hero_aftermath.png', duration: 3600, zoom: [1.08, 1.0] }
      ],
      // C5에서 피가 번지는 자리(화면 아래쪽 돌 틈, 1920×1080 기준) — 건틀릿 손 주변
      pool: { x0: 560, x1: 1380, y: 880 },
      // C7·C8은 전투 화면에서 진행 (피 튐 오버레이, 죽음 카드가 재로 부서짐, 끊어진 실, 동료 반응)
      returnDelay: 600,
      ashDuration: 1600,
      // pause: 그 대사 뒤에 더 머무는 시간(ms) — 엘리안의 말 뒤 침묵, 그리고 브룬힐드
      // faces: 글자가 다 나온 뒤 차례로 바뀌는 표정 (놀람 → 슬픔 → 텅 빔)
      reactions: [
        { who: 'archer', faces: ['archer_shocked', 'archer_grief', 'archer_hollow'], text: '…세라?', pause: 1600 },
        { who: 'warrior', faces: ['warrior_shocked', 'warrior_grief'], text: '……', pause: 800 }
      ],
      reactionTremble: 2600,
      bloodRemain: 0.6        // C7 피 자국이 옅어진 뒤 남는 진하기
    },

    // ───────────── 짓밟힘 → 탈출 ─────────────
    escape: {
      lines: [
        { who: 'system', text: '거대한 발이 비틀거리며 물러난다.' },
        { who: 'warrior', face: 'warrior_rage', text: '물러난다…! 지금이다. 엘리안, 노엘. 뛰어!' },
        { who: 'archer', face: 'archer_grief', text: '대장은요? 대장은—!' },
        { who: 'warrior', face: 'warrior_grief', text: '…뛰라고!' }
      ],
      title: '탈출'
    },

    ending: {
      title: '튜토리얼 끝',
      lines: ['세라피나는 돌아오지 않았다.', '남쪽 바다를 보자던 약속도.'],
      inner: '…다음엔, 구할 수 있을까.',
      button: '다시 하기'
    },

    wipe: {
      giant: { title: '운명이 집행되었다', text: '아무도 살아남지 못했다.', button: '다시 — 거대한 존재가 나타난 직후부터' },
      normal: { title: '전멸', text: '노엘의 눈앞에서 파티가 쓰러졌다.', button: '다시 — 이 전투 처음부터' }
    },

    // 대사창 작은 얼굴: 스탠딩 그림에서 얼굴 부분 (원본 픽셀 좌표 중심, 한 변 크기)
    faces: {
      hero:    { img: 'stand_hero.png',    cx: 322, cy: 125, size: 190 },
      warrior: { img: 'stand_warrior.png', cx: 255, cy: 112, size: 190 },
      archer:  { img: 'stand_archer.png',  cx: 335, cy: 112, size: 190 },
      noel:    { img: 'stand_witch.png',   cx: 250, cy: 118, size: 190 }
    },
    // 표정 그림 (대사의 face: 'hero_smile' → face_hero_smile.png). 정면 상반신(약 435×887)에서 얼굴 부분(원본 픽셀 중심, 한 변)
    // 표정 이름이 없는 캐릭터(노엘)·표정을 지정하지 않은 대사는 위 faces(스탠딩에서 잘라 쓴 얼굴)를 쓴다
    expressions: {
      file: 'face_{name}.png',
      crop: {
        hero:    { cx: 220, cy: 270, size: 360 },
        archer:  { cx: 215, cy: 280, size: 360 },
        warrior: { cx: 220, cy: 270, size: 360 }
      },
      // 캠프 대화창의 큰 얼굴(어깨까지 조금 더 넓게)
      cropLarge: {
        hero:    { cx: 220, cy: 300, size: 470 },
        archer:  { cx: 215, cy: 310, size: 470 },
        warrior: { cx: 220, cy: 300, size: 470 }
      },
      names: {
        hero: ['calm', 'smile', 'determined', 'shocked'],
        archer: ['smile', 'shocked', 'grief', 'hollow'],
        warrior: ['stern', 'shocked', 'grief', 'rage']
      }
    },
    standing: {
      hero: 'stand_hero.png', warrior: 'stand_warrior.png', archer: 'stand_archer.png', noel: 'stand_witch.png'
    },
    names: { hero: '세라피나', warrior: '브룬힐드', archer: '엘리안', noel: '노엘', inner: '노엘', narr: '', system: '' },

    // ───────────── 화면 배치 (1920×1080 기준 좌표) ─────────────
    layout: {
      W: 1920, H: 1080,
      bg: 'bg_cathedral.png',
      // 마녀의 손 그림: 원본 1672×941. scale 배로 줄여 (x, y)에 둔다.
      hand: {
        img: 'ui_witch_hands.png', imgW: 1672, imgH: 941,
        scale: 0.9, x: 212, y: 370,
        // 원본 그림 속 다섯 장 카드 자리 (투명 영역, 원본 좌표). [왼위, 오위, 오아래, 왼아래]
        slots: [
          [[351.3, 287.5], [579.6, 171.7], [726.7, 603.8], [566.2, 685.2]],
          [[521.8, 184.0], [771.7, 128.6], [809.8, 582.9], [634.1, 621.9]],
          [[706.2, 130.1], [961.6, 130.4], [918.0, 581.3], [738.2, 580.9]],
          [[900.2, 132.7], [1151.0, 184.1], [1009.3, 613.3], [833.0, 577.1]],
          [[1089.7, 173.3], [1318.9, 287.4], [1092.8, 678.8], [931.7, 598.6]]
        ],
        cardFrac: 0.685,     // 카드 자리 아래에서부터 이 비율만큼만 카드(2:3)로 채운다
        hoverScale: 1.12,    // 마우스를 올렸을 때 카드 배율 (카드 원본 240×360 기준)
        hoverBottom: 1060,   // 확대된 카드의 아랫변 y
        dragScale: 0.85,
        // 손패가 5장보다 적어 비는 카드 자리에는 마녀가 쥔 덱(뒷면 카드)이 보인다(손 그림이 잘려 보이지 않게)
        backs: true,
        dropY: 70            // 카드를 낼 때 부채꼴 손이 내려가는 거리
      },
      // 카드를 낼 때 오른손이 카드 한 장을 세워 드는 그림 (ui_witch_hand_raise.png, 원본 1672×941)
      // quad: 그 카드 자리의 네 모서리 [왼위, 오위, 오아래, 왼아래] — assets/ui_witch_hand_raise.json 값과 같아야 한다(테스트로 확인)
      raise: {
        img: 'ui_witch_hand_raise.png', imgW: 1672, imgH: 941,
        // 다 올라왔을 때 위치(손 그림과 같은 방식: 원본 좌표 × scale + x,y). 세운 카드가 세라피나의 등을 가리지 않게 오른쪽에 둔다
        scale: 0.9, x: 420, y: 320,
        from: [300, 520],                 // 시작 위치(오른쪽 아래로 이만큼 떨어진 곳)
        quad: [[866, 64], [1186, 32], [1221, 480], [914, 507]]
      },
      // 동료 행동 자세(뒷모습). 기본 자세와 같은 배율로, 발끝(그림 아래 가운데)을 맞춰 겹친다. dx·dy: 미세 조정(화면 px)
      poses: {
        hero:    { attack: { img: 'spr_hero_back_attack.png', dx: 30, dy: 0 } },
        archer:  { attack: { img: 'spr_archer_back_attack.png', dx: 20, dy: 0 } },
        warrior: { guard:  { img: 'spr_warrior_back_guard.png', dx: -30, dy: 0 } }
      },
      card: { w: 240, h: 360 },
      playZoneY: 610,        // 대상 없는 카드: 이 선보다 위에서 놓으면 사용
      // 동료 뒷모습: x(가운데), top(머리 위), h(그림 높이), anchor(붉은 실이 나오는 등 위치, 그림 비율), hpY(HP판 y)
      allies: {
        archer:  { img: 'spr_archer_back.png',  x: 290,  top: 440, h: 960, anchor: [0.50, 0.24] },
        hero:    { img: 'spr_hero_back.png',    x: 960,  top: 392, h: 820, anchor: [0.50, 0.165] },
        warrior: { img: 'spr_warrior_back.png', x: 1640, top: 428, h: 990, anchor: [0.55, 0.22] }
      },
      allyHpOffset: 34,       // 머리 위로 얼마나 띄울지
      // 적: x(가운데), feet(발 y), h(그림 높이). 광신도 그림은 2:3
      enemySlots: [
        { x: 700, feet: 352, h: 232 },
        { x: 960, feet: 316, h: 232 },
        { x: 1220, feet: 352, h: 232 }
      ],
      enemyAspect: 2 / 3,     // 광신도 그림이 없을 때의 회색 박스 비율 (그림이 있으면 그림 비율)
      // 거대 존재의 발: 그림 비율을 지킨 채 너비 w, 아랫변 bottom(화면 위쪽에서 잘림). feetY: ??? 표시, intentY: 예고
      giant: { cx: 960, w: 900, bottom: 560, feetY: 322, intentY: 214 },
      witchPanel: { x: 24, y: 952, w: 320, h: 104 },
      energy: { x: 1716, y: 930, r: 56 },
      endTurn: { x: 1640, y: 1004, w: 260, h: 60 },
      drawPile: { x: 400, y: 1034 },
      discardPile: { x: 1574, y: 1034 },
      dialog: { x: 24, y: 20, w: 580, h: 132 }
    },

    // 대화·연출 속도 (ms)
    timing: {
      typeCharsPerSec: 38,
      guideBase: 1800, guidePerChar: 70,
      enemyAttack: 520, drawGap: 90, banner: 900,
      footDrop: 520,
      // 카드 내기(손 들기): 부채꼴 손이 내려가고 오른손이 카드를 세워 든 뒤 카드가 날아간다. 일반 카드 합계 약 0.45초
      raiseUp: 150, raiseHold: 60, cardFly: 240, raiseDown: 170,
      // 죽음 카드: 천천히 들어 올려 떨며 붉은 실이 최대로 팽팽해진 뒤 컷신으로
      deathRaiseUp: 420, deathHold: 1700, deathTremble: 4
    },

    // ───────────── 컷인 (대표 카드를 낼 때마다) ─────────────
    // 화면을 가로지르는 띠(검붉은 배경 + 코드로 그린 속도선·빛 궤적) 안으로 캐릭터가 미끄러져 들어왔다 빠진다. 클릭/탭하면 건너뜀
    // focus: 그림 속 띠 가운데에 올 점(그림 비율) / at: 띠 안에서 그 점이 머무는 가로 위치(화면 x)
    cutin: {
      duration: 820,           // 일반 컷인 길이(ms)
      heavyDuration: 1350,     // 무거운 컷인(짓밟힘) 길이
      band: { y: 300, h: 420, slant: 70 },   // 띠 위쪽 y, 높이, 기울기(왼쪽이 이만큼 아래)
      imgH: 820,               // 그림 높이(화면 px, 원본 941)
      cards: {
        holy_slash:  { img: 'cutin_hero.png',          focus: [0.50, 0.40], at: 1000, from: 1, color: '#e8f4ff' },
        snipe:       { img: 'cutin_archer.png',        focus: [0.55, 0.30], at: 940, from: 1, color: '#d8ffb8' },
        cover:       { img: 'cutin_warrior.png',       focus: [0.45, 0.40], at: 1140, from: -1, color: '#ffd36b' },
        curse_flame: { img: 'cutin_witch_cast.png',    focus: [0.45, 0.30], at: 1000, from: 1, color: '#ff7a3a' },
        trample:     { img: 'cutin_witch_inherit.png', focus: [0.40, 0.28], at: 980, from: 1, color: '#ff2a3c', heavy: true }
      }
    },

    // ───────────── 동료·적 움직임 ─────────────
    // 동료 카드: 준비(움츠림) → 기본·행동 자세를 겹쳐 녹임 → 타격(대상 쪽으로 튀어나감, 순간 멈춤, 잔상) → 복귀(살짝 지나쳤다 돌아옴)
    motion: {
      windup: 150, blend: 100, strike: 110, hitstop: 80, recover: 260,
      crouch: 10,              // 준비 때 내려앉는 정도(px)
      // 카드 → [동료, 자세]
      cards: {
        holy_slash: ['hero', 'attack'], vanguard: ['hero', 'attack'],
        snipe: ['archer', 'attack'], suppress: ['archer', 'attack'],
        cover: ['warrior', 'guard'], shield_bash: ['warrior', 'guard']
      },
      // 타격 때: toward(대상 쪽으로 가로 이동 비율), max(가로 이동 상한 px), dy(앞으로 = 위쪽 px), scale(확대)
      lunge: {
        hero:    { toward: 0.18, max: 110, dy: -70, scale: 1.07 },
        archer:  { toward: 0.04, max: 30,  dy: -16, scale: 1.03 },
        warrior: { toward: 0.12, max: 90,  dy: -46, scale: 1.06 }
      },
      breathe: { amp: 1.5, period: 3800 },   // 대기 중 숨쉬기 (위아래 px, 주기 ms)
      // 적 공격: 몸을 젖혔다가 달려든다(아래로 = 화면 앞쪽), 맞은 동료는 흔들린다
      enemy: { windup: 130, rush: 150, back: 300, dy: 46, scale: 1.28 },
      hurt: { power: 9, dur: 300 }
    },

    // 그림 파일 목록. 없으면 같은 자리에 회색 박스 + 파일명 (파일을 넣고 새로고침하면 교체)
    // 카드 그림 파일 (카드 id → 파일). 있으면 코드로 그린 그림 대신 쓴다
    cardArtImg: { hero_death: 'card_art_hero_death.png', trample: 'card_art_trample.png' },

    assets: [
      'card_art_hero_death.png', 'card_art_trample.png',
      'bg_cathedral.png', 'bg_camp.png',
      'spr_hero_back.png', 'spr_warrior_back.png', 'spr_archer_back.png',
      'spr_cultist.png', 'spr_giant_foot.png',
      'stand_hero.png', 'stand_warrior.png', 'stand_archer.png', 'stand_witch.png',
      'ui_witch_hands.png', 'ui_witch_hand_raise.png', 'card_frame.png',
      'cut_hero_reverse.png', 'cut_hero_reach.png', 'cut_hero_crushed.png', 'cut_hero_aftermath.png',
      'cutin_hero.png', 'cutin_archer.png', 'cutin_warrior.png', 'cutin_witch_cast.png', 'cutin_witch_inherit.png',
      'face_hero_calm.png', 'face_hero_smile.png', 'face_hero_determined.png', 'face_hero_shocked.png',
      'face_archer_smile.png', 'face_archer_shocked.png', 'face_archer_grief.png', 'face_archer_hollow.png',
      'face_warrior_stern.png', 'face_warrior_shocked.png', 'face_warrior_grief.png', 'face_warrior_rage.png',
      'spr_hero_back_attack.png', 'spr_archer_back_attack.png', 'spr_warrior_back_guard.png'
    ],
    assetDir: 'assets/'
  };
})(typeof window !== 'undefined' ? window : globalThis);
