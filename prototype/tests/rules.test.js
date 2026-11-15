/*
 * 규칙 단위 테스트 (브라우저 없이 Node로 실행)
 *   node --test prototype/tests/rules.test.js
 */
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

require(path.join(__dirname, '../js/data.js'));
require(path.join(__dirname, '../js/rules.js'));
const Game = globalThis.Game;
const R = Game.Rules;
const D = Game.DATA;

function ids(st, uids) { return uids.map(u => st.cards[u].id); }
function handIds(st) { return ids(st, st.battle.hand); }
function findInHand(st, id) { return st.battle.hand.find(u => st.cards[u].id === id); }
function giveCard(st, id) { R.debugAddCard(st, id); return st.battle.hand[st.battle.hand.length - 1] && findInHand(st, id); }

function normalBattle(seed) {
  const st = R.newGame(seed || 7);
  R.startBattle(st, 'normal');
  R.startTurn(st);
  return st;
}
function giantBattle(seed) {
  const st = R.newGame(seed || 7);
  R.startBattle(st, 'giant');
  R.startTurn(st);
  return st;
}

test('시작 덱 15장, 구성이 문서와 같다', () => {
  const st = R.newGame(1);
  assert.equal(st.party.deck.length, 15);
  const count = {};
  ids(st, st.party.deck).forEach(id => { count[id] = (count[id] || 0) + 1; });
  assert.deepEqual(count, { curse_flame: 2, fate_shift: 2, take_hit: 1, foresight: 1, holy_slash: 2, vanguard: 1, cover: 2, shield_bash: 1, snipe: 2, suppress: 1 });
  assert.equal(st.party.witch.hp, 15);
  assert.equal(st.party.allies.hero.hp, 30);
  assert.equal(st.party.allies.warrior.hp, 24);
  assert.equal(st.party.allies.archer.hp, 12);
});

test('카드 설명문 수치 치환', () => {
  assert.equal(R.cardText('holy_slash'), '적 1명에게 14 피해');
  assert.equal(R.cardText('suppress'), '적 1명에게 3 피해 + 그 적의 이번 공격 피해 -4');
  assert.equal(R.cardText('foresight'), '카드 2장을 뽑는다');
});

test('1턴: 에너지 3, 5장 드로우(튜토리얼 손패), 광신도 3명 예고', () => {
  const st = normalBattle();
  assert.equal(st.battle.energy, 3);
  assert.equal(st.battle.hand.length, 5);
  assert.deepEqual(handIds(st).slice().sort(), D.encounters.normal.scriptedHands[1].slice().sort());
  assert.equal(st.battle.enemies.length, 3);
  st.battle.enemies.forEach(e => { assert.equal(e.hp, 14); assert.equal(e.intent.kind, 'attack'); });
  assert.equal(st.battle.enemies[0].intent.target, 'warrior');
});

test('성검 베기는 광신도를 일격에 쓰러뜨리고 에너지 1을 쓴다', () => {
  const st = normalBattle();
  const uid = findInHand(st, 'holy_slash');
  const r = R.play(st, uid, { enemy: 'c2' });
  assert.ok(r.ok);
  assert.equal(R.enemy(st, 'c2').alive, false);
  assert.equal(st.battle.energy, 2);
  assert.ok(st.battle.discard.includes(uid));
});

test('에너지 부족이면 낼 수 없다', () => {
  const st = normalBattle();
  st.battle.energy = 0;
  const r = R.play(st, findInHand(st, 'holy_slash'), { enemy: 'c1' });
  assert.equal(r.ok, false);
  assert.equal(r.reason, '에너지가 부족하다');
});

test('운명 전가: 예고 대상을 다른 아군으로 바꾼다', () => {
  const st = normalBattle();
  const uid = giveCard(st, 'fate_shift');
  const e = R.enemy(st, 'c3');
  assert.equal(e.intent.target, 'archer');
  assert.ok(R.redirectChoices(st, 'c3').includes('warrior'));
  assert.ok(!R.redirectChoices(st, 'c3').includes('archer'));
  const r = R.play(st, uid, { enemy: 'c3', to: 'warrior' });
  assert.ok(r.ok);
  assert.equal(e.intent.target, 'warrior');
  // 적 턴: 전사가 맞는다
  const before = st.party.allies.warrior.hp;
  const archerBefore = st.party.allies.archer.hp;
  R.endTurn(st);
  assert.equal(st.party.allies.archer.hp, archerBefore);
  assert.equal(st.party.allies.warrior.hp, before - 5 - 5); // c1(5→전사) + c3(5→전사)
});

test('운명 전가 ②단계 대상이 잘못되면 실패', () => {
  const st = normalBattle();
  const uid = giveCard(st, 'fate_shift');
  assert.equal(R.play(st, uid, { enemy: 'c3', to: 'archer' }).ok, false);
});

test('감싸기: 전사가 받되 피해 절반 (8 → 4 예시 확인)', () => {
  const st = normalBattle();
  R.enemy(st, 'c2').intent.value = 8;
  const uid = giveCard(st, 'cover');
  assert.ok(R.play(st, uid, { enemy: 'c2' }).ok);
  assert.equal(R.enemy(st, 'c2').intent.target, 'warrior');
  assert.equal(R.intentDamage(R.enemy(st, 'c2').intent), 4);
});

test('대신 받기: 비용 0, 마녀가 받는다', () => {
  const st = normalBattle();
  const uid = findInHand(st, 'take_hit');
  assert.equal(R.cost(st, uid), 0);
  assert.ok(R.play(st, uid, { enemy: 'c2' }).ok);
  assert.equal(st.battle.energy, 3);
  R.endTurn(st);
  assert.equal(st.party.witch.hp, 15 - 6);
  assert.equal(st.party.allies.hero.hp, 30);
});

test('견제 사격: 3 피해 + 그 적의 이번 공격 -4', () => {
  const st = normalBattle();
  const uid = giveCard(st, 'suppress');
  assert.ok(R.play(st, uid, { enemy: 'c2' }).ok);
  assert.equal(R.enemy(st, 'c2').hp, 11);
  assert.equal(R.intentDamage(R.enemy(st, 'c2').intent), 2);
});

test('쓰러진 동료의 카드는 낼 수 없고, 전투 후 HP 1 + 상처 카드', () => {
  const st = normalBattle();
  R.debugSetHp(st, 'archer', 0);
  const uid = giveCard(st, 'snipe');
  const r = R.canPlay(st, uid);
  assert.equal(r.ok, false);
  assert.equal(r.reason, '쓰러진 동료의 카드');
  const ev = R.finishBattle(st);
  assert.equal(st.party.allies.archer.status, 'ok');
  assert.equal(st.party.allies.archer.hp, 1);
  const wounds = st.party.deck.filter(u => st.cards[u].id === 'wound');
  assert.equal(wounds.length, 1);
  assert.equal(st.cards[wounds[0]].woundOf, 'archer');
  assert.equal(st.party.deck.length, 15);
  assert.ok(ev.some(e => e.t === 'wound'));
});

test('상처 카드는 낼 수 없다', () => {
  const st = normalBattle();
  const uid = giveCard(st, 'wound');
  assert.equal(R.canPlay(st, uid).ok, false);
});

test('광신도가 1명 남으면 거대 존재가 짓밟는다', () => {
  const st = normalBattle();
  R.play(st, findInHand(st, 'holy_slash'), { enemy: 'c1' });
  R.debugSetHp(st, 'c2', 1);
  const r = R.play(st, findInHand(st, 'curse_flame'), { enemy: 'c2' });
  const trig = r.events.find(e => e.t === 'giantTrigger');
  assert.ok(trig);
  assert.deepEqual(trig.victims, ['c3']);
  assert.equal(st.battle.result, 'giant');
  assert.equal(R.aliveEnemies(st).length, 0);
});

test('남은 광신도가 한 번에 모두 쓰러져도 거대 존재가 등장한다', () => {
  const st = normalBattle();
  R.play(st, findInHand(st, 'holy_slash'), { enemy: 'c1' });
  R.debugSetHp(st, 'c2', 3); R.debugSetHp(st, 'c3', 3);
  const r = R.play(st, giveCard(st, 'vanguard'), {});
  assert.ok(r.events.some(e => e.t === 'giantTrigger'));
  assert.equal(st.battle.result, 'giant');
});

test('턴 종료: 손패 버림, 덱 소진 시 버림 더미를 섞는다', () => {
  const st = normalBattle();
  R.endTurn(st);
  assert.equal(st.battle.hand.length, 0);
  assert.equal(st.battle.discard.length, 5);
  R.startTurn(st); R.endTurn(st);
  R.startTurn(st); R.endTurn(st);  // 15장 소진
  const ev = R.startTurn(st);
  assert.ok(ev.some(e => e.t === 'reshuffle'));
  assert.equal(st.battle.hand.length, 5);
});

test('거대 존재: 1턴에 죽음 카드가 들어오고 4장만 뽑는다, 손패에 보존', () => {
  const st = giantBattle();
  const hand = handIds(st);
  assert.equal(hand.length, 5);
  assert.equal(hand.filter(x => x === 'hero_death').length, 1);
  assert.equal(hand[2], 'hero_death');   // 가운데
  R.endTurn(st);
  assert.deepEqual(handIds(st), ['hero_death']);
  R.startTurn(st);
  assert.equal(st.battle.hand.length, 5);
  assert.equal(handIds(st).filter(x => x === 'hero_death').length, 1);
});

test('거대 존재: 공격 무효(피해 0)', () => {
  const st = giantBattle();
  const uid = giveCard(st, 'holy_slash');
  const r = R.play(st, uid, { enemy: 'giant' });
  assert.ok(r.ok);
  assert.ok(r.events.some(e => e.t === 'damage' && e.immune));
  assert.equal(R.enemy(st, 'giant').alive, true);
});

test('거대 존재: 3턴 카운트다운 — 그림자 → 기둥 붕괴(전원 5) → 짓밟기(전멸)', () => {
  const st = giantBattle();
  assert.equal(R.enemy(st, 'giant').intent.kind, 'shadow');
  R.endTurn(st);
  assert.equal(st.battle.shadow, 1);
  assert.equal(st.battle.result, null);
  R.startTurn(st);
  assert.equal(R.enemy(st, 'giant').intent.kind, 'aoe');
  R.endTurn(st);
  assert.equal(st.party.witch.hp, 10);
  assert.equal(st.party.allies.hero.hp, 25);
  assert.equal(st.party.allies.archer.hp, 7);
  R.startTurn(st);
  assert.equal(R.enemy(st, 'giant').intent.kind, 'stomp');
  const ev = R.endTurn(st);
  assert.equal(st.battle.result, 'lose');
  assert.ok(ev.some(e => e.t === 'battleEnd' && e.reason === 'stomp'));
});

test('죽음 카드: 비용 0 → 용사 사망, 용사 카드 3장이 유품으로, 짓밟힘 획득(이번 턴 비용 0)', () => {
  const st = giantBattle();
  st.battle.energy = 0;
  const death = findInHand(st, 'hero_death');
  const idx = st.battle.hand.indexOf(death);
  const r = R.play(st, death, {});
  assert.ok(r.ok, r.reason);
  assert.equal(st.party.allies.hero.status, 'dead');
  const all = ids(st, Object.keys(st.cards));
  assert.equal(all.filter(x => x === 'holy_slash' || x === 'vanguard').length, 0);
  assert.equal(all.filter(x => x === 'broken_sword').length, 2);
  assert.equal(all.filter(x => x === 'last_charge').length, 1);
  const tr = findInHand(st, 'trample');
  assert.ok(tr);
  assert.equal(st.battle.hand.indexOf(tr), idx);   // 죽음 카드가 있던 자리
  assert.equal(R.cost(st, tr), 0);
  assert.ok(st.party.deck.includes(tr));
  assert.equal(st.party.deck.length, 16);
  // 짓밟힘 → 존재가 물러난다
  const r2 = R.play(st, tr, {});
  assert.ok(r2.ok, r2.reason);
  assert.ok(r2.events.some(e => e.t === 'retreat'));
  assert.equal(st.battle.result, 'retreat');
});

test('짓밟힘: 획득한 다음 턴부터는 비용 2', () => {
  const st = giantBattle();
  R.play(st, findInHand(st, 'hero_death'), {});
  const tr = findInHand(st, 'trample');
  R.endTurn(st);
  R.startTurn(st);
  assert.equal(R.cost(st, tr), 2);
});

test('유품 카드: 원래보다 강하고 마녀 HP를 잃는다', () => {
  const st = R.newGame(3);
  R.startBattle(st, 'normal'); R.startTurn(st);
  st.party.allies.hero.status = 'dead';
  const uid = giveCard(st, 'broken_sword');
  const r = R.play(st, uid, { enemy: 'c1' });
  assert.ok(r.ok, r.reason);
  assert.equal(R.enemy(st, 'c1').alive, false);
  assert.equal(st.party.witch.hp, 12);
});

test('패배 조건: 마녀 HP 0 또는 동료 전원 쓰러짐', () => {
  const st = normalBattle();
  R.debugSetHp(st, 'witch', 0);
  assert.ok(R.isDefeat(st));
  const st2 = normalBattle();
  ['hero', 'warrior', 'archer'].forEach(a => R.debugSetHp(st2, a, 0));
  assert.ok(R.isDefeat(st2));
});

test('스냅샷 복원: 거대 존재 등장 직후 상태로 돌아간다', () => {
  const st = R.newGame(11);
  R.startBattle(st, 'giant');
  const snap = R.snapshot(st);
  R.startTurn(st); R.endTurn(st); R.startTurn(st); R.endTurn(st);
  const st2 = R.restore(snap, st.rng);
  assert.equal(st2.party.witch.hp, 15);
  assert.equal(st2.battle.turn, 0);
  R.startTurn(st2);
  assert.ok(handIds(st2).includes('hero_death'));
});
