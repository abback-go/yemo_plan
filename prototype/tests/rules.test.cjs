// 규칙·미로 단위 테스트: node --test prototype/tests
const test = require('node:test');
const assert = require('node:assert/strict');
const { load } = require('./harness.cjs');

const W = load();
const R = W.rules;
const D = W.DATA;

function seeded(seed) { R.setRng(R.makeRng(seed)); }
const plain = (v) => JSON.parse(JSON.stringify(v));

// ───────── 미로 ─────────
function reach(map, opts) {
  const { doorsOpen } = opts || {};
  const seen = new Set();
  const q = [[map.start.x, map.start.y]];
  seen.add(R.key(map.start.x, map.start.y));
  while (q.length) {
    const [x, y] = q.shift();
    for (const [dx, dy] of [[0, -1], [1, 0], [0, 1], [-1, 0]]) {
      const nx = x + dx, ny = y + dy;
      const ch = R.tileCh(map, nx, ny);
      if (ch === '#') continue;
      if (ch === 'D' && !doorsOpen) continue;
      const k = R.key(nx, ny);
      if (seen.has(k)) continue;
      seen.add(k);
      q.push([nx, ny]);
    }
  }
  return seen;
}

for (let f = 1; f <= 5; f++) {
  test(`B${f} 미로: 크기·필수 칸·연결성`, () => {
    const F = D.FLOORS[f];
    const map = R.genFloor(f);
    assert.equal(map.tiles.length, R.MAP_H);
    map.tiles.forEach((row) => assert.equal(row.length, R.MAP_W));
    const all = map.tiles.join('');
    assert.equal((all.match(/S/g) || []).length, 1, '시작 칸 1개');
    if (F.down) assert.equal((all.match(/>/g) || []).length, 1, '계단 1개');
    else assert.equal((all.match(/B/g) || []).length, 1, '보스 1개');
    for (const m of F.markers) assert.ok(map.markers[m], `의뢰 표식 ${m}`);
    assert.equal((all.match(/M/g) || []).length, F.monsters, '몬스터 수');
    if (F.door) assert.ok(map.door, '잠긴 문');
    if (F.key) assert.equal((all.match(/K/g) || []).length, 1, '열쇠');
    if (F.puzzle) assert.equal((all.match(/P/g) || []).length, 1, '이상한 방');
    if (F.merchant) assert.equal((all.match(/\$/g) || []).length, 1, '상인');

    const closed = reach(map, { doorsOpen: false });
    const open = reach(map, { doorsOpen: true });
    // 문을 열지 않아도: 계단/보스, 의뢰 표식, 열쇠, 잠긴 상자, 퍼즐, 상인, 샘물은 갈 수 있어야 한다
    const mustReach = [];
    for (let y = 0; y < map.h; y++) for (let x = 0; x < map.w; x++) {
      const ch = map.tiles[y][x];
      if ('>BKLP$F?a-f'.includes(ch) || /[a-f]/.test(ch)) mustReach.push([x, y, ch]);
    }
    for (const [x, y, ch] of mustReach) assert.ok(closed.has(R.key(x, y)), `B${f} (${x},${y}) '${ch}'에 문 없이 도달 가능`);
    // 문을 열면 모든 바닥 칸에 도달 가능
    for (let y = 0; y < map.h; y++) for (let x = 0; x < map.w; x++) {
      if (map.tiles[y][x] !== '#') assert.ok(open.has(R.key(x, y)), `B${f} (${x},${y}) 문을 열면 도달 가능`);
    }
    // 보물방은 문 없이는 못 들어간다
    if (map.treasure) {
      assert.ok(!closed.has(R.key(map.treasure.x, map.treasure.y)), '보물방은 잠겨 있어야 한다');
      assert.ok(open.has(R.key(map.treasure.x, map.treasure.y)));
    }
    // 열쇠는 보물방 밖
    for (const k of map.locked) assert.notEqual(R.tileCh(map, ...k.split(',').map(Number)), 'K');
  });
}

test('미로는 시드 고정이라 매번 같다', () => {
  const a = R.genFloor(2).tiles.join('|');
  assert.equal(R.genFloor(2).tiles.join('|'), a);
});

// ───────── 기본 ─────────
test('새 게임 초기값', () => {
  const s = R.newGame();
  assert.equal(s.silver, 150);
  assert.equal(s.player.lv, 1);
  assert.equal(R.stats(s).maxHp, 60);
  assert.equal(R.count(s, 'hp_potion'), 3);
  assert.deepEqual(plain(R.customers(s).map((q) => q.id)), ['q1']);
  assert.match(R.objectiveText(s), /첫 손님/);
});

test('레벨업: 능력치·마법 습득·늘어난 만큼 회복', () => {
  const s = R.newGame();
  s.player.hp = 5;
  const ups = R.gainExp(s, 20);
  assert.equal(s.player.lv, 2);
  assert.deepEqual(plain(ups[0].learned), ['ice']);
  assert.equal(s.player.hp, 5 + 12);
  assert.equal(R.stats(s).maxHp, 72);
  R.gainExp(s, 45 + 80 + 125);
  assert.equal(s.player.lv, 5);
  assert.deepEqual(plain(R.knownSpells(s)), ['fire', 'ice', 'heal', 'light']);
});

test('의뢰: 매입 → 찾아오기 → 정화 → 판매', () => {
  const s = R.newGame();
  assert.ok(R.acceptQuest(s, 'q1').ok);
  assert.equal(s.silver, 120);
  assert.equal(s.quests.q1.status, 'active');
  assert.ok(!R.canPurifyQuest(s, 'q1'));
  R.completeObjective(s, 'q1');
  assert.equal(R.count(s, 'q_spring'), 1);
  const res = R.purifyQuest(s, 'q1');
  assert.ok(res.ok);
  assert.equal(s.purified, 1);
  assert.equal(R.count(s, 'q_spring'), 0);
  assert.equal(s.quests.q1.status, 'done');
  // 정화 1건 → q3(재료형) 손님 등장
  assert.ok(R.customers(s).some((q) => q.id === 'q3'));
  const sold = R.sellAntique(s, res.antique.uid);
  assert.equal(sold.price, 120);
  const badges = R.checkBadges(s).map((b) => b.id);
  assert.ok(badges.includes('first_buy') && badges.includes('first_purify'));
});

test('의뢰: 재료형은 재료가 모이면 바로 정화 가능', () => {
  const s = R.newGame();
  s.purified = 1; R.refreshCustomers(s);
  assert.ok(R.acceptQuest(s, 'q3').ok);
  assert.ok(!R.canPurifyQuest(s, 'q3'));
  R.addItem(s, 'salt', 1); R.addItem(s, 'dew', 1);
  assert.ok(R.canPurifyQuest(s, 'q3'));
  assert.ok(R.purifyQuest(s, 'q3').ok);
  assert.equal(R.count(s, 'salt'), 0);
  assert.equal(R.count(s, 'dew'), 0);
});

test('의뢰: 돈이 모자라면 매입 불가, 거절하면 다음 날 다시 온다', () => {
  const s = R.newGame();
  s.silver = 10;
  assert.ok(!R.acceptQuest(s, 'q1').ok);
  R.declineQuest(s, 'q1');
  assert.equal(R.customers(s).length, 0);
  s.day += 1;
  assert.equal(R.customers(s)[0].id, 'q1');
});

test('상점·장비·능력치', () => {
  seeded(1);
  const s = R.newGame();
  assert.ok(R.buy(s, 'hp_potion', 2).ok);
  assert.equal(s.silver, 100);
  assert.ok(!R.shopItems(s, 'potion').includes('big_potion'), '큰 물약은 B3 이후');
  s.floorsReached = 3;
  assert.ok(R.shopItems(s, 'potion').includes('big_potion'));
  assert.ok(R.sellItem(s, 'hp_potion', 1).ok);
  assert.equal(s.silver, 112);
  const a = { uid: 99, def: 'doll', state: 'purified' };
  s.antiques.push(a);
  R.equipAntique(s, 99);
  assert.equal(R.stats(s).atk, 15);
  assert.equal(R.stats(s).def, 6);
  assert.ok(!R.sellAntique(s, 99).ok, '장착 중에는 못 판다');
  R.unequip(s, 0);
  assert.ok(R.sellAntique(s, 99).ok);
});

test('던전 골동품: 정화 소금으로 정화하면 등급이 정해진다', () => {
  seeded(7);
  const s = R.newGame();
  const a = R.addCursedAntique(s, 5);
  assert.ok(!R.purifyFound(s, a.uid).ok, '소금 없으면 실패');
  R.addItem(s, 'salt', 1);
  const res = R.purifyFound(s, a.uid);
  assert.ok(res.ok);
  assert.ok(D.ANTIQUES[res.antique.def].random);
  assert.equal(s.purified, 0, '던전 골동품은 의뢰 실적에 포함되지 않는다');
});

test('등급 확률 분포(B5): 전설이 가끔, 일반이 가장 적지 않다', () => {
  seeded(42);
  const n = 4000, c = { common: 0, uncommon: 0, rare: 0, legend: 0 };
  for (let i = 0; i < n; i++) c[D.ANTIQUES[R.rollAntiqueDef(5)].grade]++;
  assert.ok(Math.abs(c.legend / n - 0.07) < 0.02, JSON.stringify(c));
  assert.ok(Math.abs(c.common / n - 0.25) < 0.03, JSON.stringify(c));
});

// ───────── 전투 ─────────
function battleState(lv) {
  const s = R.newGame();
  if (lv > 1) R.gainExp(s, D.EXP_CURVE.slice(1, lv).reduce((a, b) => a + b, 0));
  return s;
}

test('물리 공격 피해 범위', () => {
  seeded(3);
  const s = battleState(1);
  for (let i = 0; i < 300; i++) {
    const b = R.createBattle(s, 'teacup', {});
    b.traits = {};
    s.player.hp = 60;
    const ev = R.playerAction(s, b, { type: 'attack' });
    const d = ev.find((e) => e.t === 'dmg' && e.target === 'enemy');
    // 10*0.9-1.8=7.2 ~ (10*1.1-1.8)*1.6=14.7
    assert.ok(d.amount >= 7 && d.amount <= 15, String(d.amount));
  }
});

test('약점·저항 배율과 약점 기록', () => {
  seeded(5);
  const s = battleState(2);
  const b = R.createBattle(s, 'waxslime', {});
  const ev = R.playerAction(s, b, { type: 'spell', id: 'ice' });
  assert.ok(ev.some((e) => e.t === 'weak'));
  assert.ok(s.known.waxslime.weak);
  const b2 = R.createBattle(s, 'waxslime', {});
  s.player.mp = 20;
  const ev2 = R.playerAction(s, b2, { type: 'spell', id: 'fire' });
  assert.ok(ev2.some((e) => e.t === 'log' && /잘 안 든다/.test(e.text)));
});

test('기 모으기는 얼음 가시로 끊긴다', () => {
  seeded(11);
  const s = battleState(3);
  const b = R.createBattle(s, 'giggledoll', {});
  b.charging = true;
  const ev = R.playerAction(s, b, { type: 'spell', id: 'ice' });
  assert.ok(ev.some((e) => e.t === 'status' && e.status === 'interrupt'));
  assert.equal(b.charging, false);
});

test('보스: 도망 불가, 연막 불가', () => {
  const s = battleState(5);
  R.addItem(s, 'smoke', 1);
  const b = R.createBattle(s, 'nocturne', {});
  assert.ok(!R.canAct(s, b, { type: 'flee' }).ok);
  assert.ok(!R.canAct(s, b, { type: 'item', id: 'smoke' }).ok);
});

test('녹턴: 체력 절반에서 그림자 방패, 빛으로 깨진다', () => {
  seeded(9);
  const s = battleState(6);
  const b = R.createBattle(s, 'nocturne', {});
  b.hp = Math.floor(b.maxHp * 0.5);
  s.player.hp = 999;
  R.playerAction(s, b, { type: 'attack' });
  assert.ok(b.shield > 0, '방패가 생겨야 한다');
  const before = b.hp;
  s.player.mp = 40;
  const ev = R.playerAction(s, b, { type: 'spell', id: 'light' });
  assert.ok(ev.some((e) => e.t === 'shieldBreak'));
  assert.ok(before - b.hp > 30, '방패를 깨고 큰 피해');
});

test('독: 전투 중에는 체력 1 아래로 떨어지지 않는다', () => {
  seeded(2);
  const s = battleState(1);
  s.player.status.poison = 6;
  s.player.hp = 2;
  const b = R.createBattle(s, 'dustwisp', {});
  b.atk = 0; b.frozen = 5;
  R.playerAction(s, b, { type: 'attack' });
  assert.ok(s.player.hp >= 1);
});

test('승리 보상: 경험치·은화·처치 기록·의뢰 완료', () => {
  seeded(4);
  const s = battleState(1);
  R.acceptQuest(s, 'q1');
  s.floorsReached = 2; R.refreshCustomers(s);
  s.silver = 500;
  R.acceptQuest(s, 'q2');
  const b = R.createBattle(s, 'mirrorbat_king', { qid: 'q2' });
  b.hp = 1; b.traits = {};
  const ev = R.playerAction(s, b, { type: 'attack' });
  assert.ok(ev.some((e) => e.t === 'win'));
  assert.equal(s.quests.q2.status, 'ready');
  assert.equal(s.stats.kills.mirrorbat_king, 1);
});

// ───────── 탐험 ─────────
test('탐험: 시작·이동·안개·계단', () => {
  seeded(8);
  const s = R.newGame();
  R.startExpedition(s, 1);
  const map = R.genFloor(1);
  assert.equal(s.exp.x, map.start.x);
  assert.ok(R.isRevealed(s, map.start.x, map.start.y));
  // 전체 지도 기준 경로로 계단까지 걸어간다 (전투는 무시하고 재시도)
  let guard = 0;
  while (!(s.exp.x === map.goal.x && s.exp.y === map.goal.y) && guard++ < 400) {
    const path = R.findPath(s, map.goal.x, map.goal.y, true);
    assert.ok(path && path.length, '계단 경로');
    const [nx, ny] = path[0];
    const ev = R.stepInto(s, nx, ny);
    if (ev && ev.type === 'battle' && ev.fixed) s.exp.runs[1].defeated[R.key(nx, ny)] = 1;
  }
  assert.equal(s.exp.x, map.goal.x);
  assert.equal(s.exp.y, map.goal.y);
});

test('저장/불러오기 왕복', () => {
  const s = R.newGame();
  R.acceptQuest(s, 'q1');
  R.startExpedition(s, 1);
  const t = R.deserialize(R.serialize(s));
  assert.equal(t.quests.q1.status, 'active');
  assert.equal(t.exp.floor, 1);
  assert.equal(R.deserialize('{broken'), null);
  assert.equal(R.deserialize(JSON.stringify({ version: 999 })), null);
});

test('촛불 퍼즐: 생성은 미해결 상태, 토글은 자기 자신+상하좌우', () => {
  seeded(10);
  for (let i = 0; i < 50; i++) assert.ok(!R.puzzleSolved(R.puzzleNew(4)));
  const g = [1, 1, 1, 1, 1, 1, 1, 1, 1];
  R.puzzleToggle(g, 4);
  assert.deepEqual(plain(g), [1, 0, 1, 0, 0, 0, 1, 0, 1]);
  R.puzzleToggle(g, 4);
  assert.ok(R.puzzleSolved(g));
});

test('먹물 힌트: 진행 중 의뢰 표식을 가리킨다', () => {
  const s = R.newGame();
  R.acceptQuest(s, 'q1');
  R.startExpedition(s, 1);
  const h = R.petHint(s);
  assert.ok(h.ok);
  assert.equal(h.label, '먼지 쌓인 음악실 사물함');
  assert.equal(h.left, 2);
});
