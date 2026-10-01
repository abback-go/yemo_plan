// 전투 밸런스 측정: 레벨·장비·물약 조건별 승률
// 사용: node tests/battle-sim.cjs
const { load } = require('./harness.cjs');
const W = load();
const R = W.rules;
const D = W.DATA;

// simulate.cjs 와 같은 전투 정책을 쓰기 위해 가져온다
const sim = require('./simulate.cjs');
void sim;

function makePlayer(lv, gear, items) {
  const s = R.newGame();
  if (lv > 1) R.gainExp(s, D.EXP_CURVE.slice(1, lv).reduce((a, b) => a + b, 0));
  // v0.2: 마법은 수업으로 배운다. 그 레벨에서 들을 수 있는 수업은 모두 들었다고 본다
  s.spells = D.SPELL_ORDER.filter((id) => D.SPELLS[id].learn <= lv);
  s.inv = Object.assign({}, items);
  s.antiques = gear.map((def, i) => ({ uid: 900 + i, def, state: 'purified' }));
  s.equip = [gear[0] ? 900 : null, gear[1] ? 901 : null];
  const st = R.stats(s);
  s.player.hp = st.maxHp; s.player.mp = st.maxMp;
  return s;
}

// simulate.cjs의 chooseBattleAction 을 그대로 복제 (모듈 내부 함수라 재정의)
function expectedDamage(s, b, action) {
  const st = R.stats(s);
  const atk = b.pcurse > 0 ? st.atk * D.TUNING.curseMult : st.atk;
  if (action.type === 'attack') return Math.max(1, atk - b.def * 0.6) * (1 - (b.traits.evasive || 0)) * 1.05;
  const sp = D.SPELLS[action.id];
  let dmg = Math.max(1, atk * sp.power * R.elemMult(b, sp.elem).m * (1 + (st[sp.elem + 'Boost'] || 0)) - b.def * 0.3);
  if (b.shield > 0 && sp.elem !== 'light') dmg *= D.TUNING.shieldMult;
  return dmg;
}
function choose(s, b) {
  const st = R.stats(s);
  const hp = s.player.hp, mp = s.player.mp;
  const spells = R.knownSpells(s);
  const can = (a) => R.canAct(s, b, a).ok;
  if (hp < st.maxHp * 0.45) {
    if (R.count(s, 'big_potion') && can({ type: 'item', id: 'big_potion' })) return { type: 'item', id: 'big_potion' };
    if (R.count(s, 'hp_potion') && can({ type: 'item', id: 'hp_potion' })) return { type: 'item', id: 'hp_potion' };
    if (spells.includes("heal") && mp >= 7) return { type: 'spell', id: 'heal' };
  }
  if (b.pcurse > 0 && R.count(s, 'salt') && can({ type: 'item', id: 'salt' })) return { type: 'item', id: 'salt' };
  if (b.charging && spells.includes("ice") && mp >= 6) return { type: 'spell', id: 'ice' };
  if (b.shield > 0 && spells.includes("light") && mp >= 10) return { type: 'spell', id: 'light' };
  if (mp < 8 && R.count(s, 'mp_potion') && can({ type: 'item', id: 'mp_potion' })) return { type: 'item', id: 'mp_potion' };
  let best = { type: 'attack' }, bestVal = expectedDamage(s, b, best);
  for (const id of spells) {
    const sp = D.SPELLS[id];
    if (sp.kind !== 'attack' || mp < sp.mp) continue;
    const v = expectedDamage(s, b, { type: 'spell', id });
    if (v > bestVal * 1.2) { best = { type: 'spell', id }; bestVal = v; }
  }
  return best;
}

function trial(enemy, lv, gear, items, n) {
  let wins = 0, hpLeft = 0, turns = 0, potions = 0;
  for (let i = 0; i < n; i++) {
    R.setRng(R.makeRng(5000 + i));
    const s = makePlayer(lv, gear, items);
    const before = R.count(s, 'hp_potion') + R.count(s, 'big_potion');
    const b = R.createBattle(s, enemy, {});
    let g = 0;
    while (!b.over && g++ < 300) {
      const ev = R.playerAction(s, b, choose(s, b));
      if (ev.length === 1 && ev[0].t === 'deny') R.playerAction(s, b, { type: 'attack' });
    }
    if (b.result === 'win') { wins++; hpLeft += s.player.hp / R.stats(s).maxHp; }
    turns += b.turn + 1;
    potions += before - (R.count(s, 'hp_potion') + R.count(s, 'big_potion'));
  }
  return { win: wins / n, hp: wins ? hpLeft / wins : 0, turns: turns / n, potions: potions / n };
}

const fmt = (r) => `승률 ${String(Math.round(r.win * 100)).padStart(3)}% · 남은 체력 ${String(Math.round(r.hp * 100)).padStart(3)}% · 평균 ${r.turns.toFixed(1)}턴 · 물약 ${r.potions.toFixed(1)}개`;
const N = 400;
const cases = [
  ['mirrorbat_king', [2, 3], ['musicbox'], { hp_potion: 3 }],
  ['director', [3, 4, 5], ['musicbox', 'handmirror'], { hp_potion: 3, mp_potion: 1 }],
  ['lockmimic_king', [5, 6, 7], ['doll', 'teapot'], { hp_potion: 3, mp_potion: 2 }],
  ['nocturne', [5, 6, 7, 8], ['doll', 'diary'], { hp_potion: 3, big_potion: 1, mp_potion: 2, salt: 1 }],
];
console.log('── 보스·의뢰 대상 ──');
for (const [enemy, lvs, gear, items] of cases) {
  for (const lv of lvs) console.log(`${D.ENEMIES[enemy].name.padEnd(10)} Lv${lv}: ${fmt(trial(enemy, lv, gear, items, N))}`);
}
console.log('── 일반 몬스터 (권장 레벨, 물약 없이 1:1) ──');
for (let f = 1; f <= 5; f++) {
  const lv = D.FLOORS[f].recLv;
  for (const [id] of D.FLOORS[f].enemies) {
    const r = trial(id, lv, [], {}, 200);
    console.log(`B${f} ${D.ENEMIES[id].name.padEnd(8)} Lv${lv}: ${fmt(r)}`);
  }
}
