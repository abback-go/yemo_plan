// 전체 플레이 시뮬레이션: 봇이 규칙대로 엔딩까지 플레이한다.
// 사용: node tests/simulate.cjs [판 수=200] [--verbose]
const { load } = require('./harness.cjs');

const W = load();
const R = W.rules;
const D = W.DATA;
const F = W.world;

const MAX_DAYS = 90;

function antiqueScore(def) {
  const e = D.ANTIQUES[def].effect;
  return (e.atk || 0) * 3 + (e.def || 0) * 2.5 + (e.maxHp || 0) * 0.4 + (e.maxMp || 0) * 0.5 +
    (e.mpRegen || 0) * 6 + (e.lightBoost || 0) * 12 + (e.iceBoost || 0) * 8 + (e.fireBoost || 0) * 6 +
    (e.crit || 0) * 30 + (e.flee || 0) * 3 + (e.potionBoost || 0) * 6 + (e.silverBoost || 0) * 4 + (e.sleepChance || 0) * 4;
}

function expectedDamage(s, b, action) {
  const st = R.stats(s);
  const atk = b.pcurse > 0 ? st.atk * D.TUNING.curseMult : st.atk;
  if (action.type === 'attack') {
    const hit = 1 - (b.traits.evasive || 0);
    return Math.max(1, atk - b.def * 0.6) * hit * (1 + D.TUNING.critBase * 0.6);
  }
  const sp = D.SPELLS[action.id];
  const m = R.elemMult(b, sp.elem).m;
  const boost = 1 + (st[sp.elem + 'Boost'] || 0);
  let dmg = Math.max(1, atk * sp.power * m * boost - b.def * 0.3);
  if (b.shield > 0 && sp.elem !== 'light') dmg *= D.TUNING.shieldMult;
  return dmg;
}

function chooseBattleAction(s, b) {
  const st = R.stats(s);
  const hp = s.player.hp, mp = s.player.mp;
  const spells = R.knownSpells(s);
  const can = (a) => R.canAct(s, b, a).ok;
  const lowHp = hp < st.maxHp * (b.boss || b.elite ? 0.45 : 0.35);
  if (lowHp) {
    if (spells.includes('heal') && mp >= D.SPELLS.heal.mp && hp < st.maxHp * 0.3 && can({ type: 'spell', id: 'heal' })) return { type: 'spell', id: 'heal' };
    if (R.count(s, 'big_potion') && can({ type: 'item', id: 'big_potion' })) return { type: 'item', id: 'big_potion' };
    if (R.count(s, 'hp_potion') && can({ type: 'item', id: 'hp_potion' })) return { type: 'item', id: 'hp_potion' };
    if (spells.includes('heal') && mp >= D.SPELLS.heal.mp && can({ type: 'spell', id: 'heal' })) return { type: 'spell', id: 'heal' };
    if (!b.noFlee && R.count(s, 'smoke')) return { type: 'item', id: 'smoke' };
    if (!b.noFlee) return { type: 'flee' };
  }
  if (b.pcurse > 0 && (b.boss || b.elite) && R.count(s, 'salt') && can({ type: 'item', id: 'salt' })) return { type: 'item', id: 'salt' };
  if (s.player.status.poison > 0 && hp < st.maxHp * 0.6 && R.count(s, 'herb')) return { type: 'item', id: 'herb' };
  if (b.charging && spells.includes('ice') && mp >= D.SPELLS.ice.mp) return { type: 'spell', id: 'ice' };
  if (b.shield > 0 && spells.includes('light') && mp >= D.SPELLS.light.mp) return { type: 'spell', id: 'light' };
  if ((b.boss || b.elite) && mp < 6 && R.count(s, 'mp_potion') && can({ type: 'item', id: 'mp_potion' })) return { type: 'item', id: 'mp_potion' };
  let best = { type: 'attack' };
  let bestVal = expectedDamage(s, b, best);
  const reserve = spells.includes('heal') ? D.SPELLS.heal.mp : 0;
  for (const id of spells) {
    const sp = D.SPELLS[id];
    if (sp.kind !== 'attack' || mp < sp.mp) continue;
    const important = b.boss || b.elite || b.hp > bestVal * 1.5;
    if (!important) continue;
    if (!b.boss && !b.elite && mp - sp.mp < reserve) continue;
    const v = expectedDamage(s, b, { type: 'spell', id });
    if (v > bestVal * 1.25) { best = { type: 'spell', id }; bestVal = v; }
  }
  if (b.boss && R.count(s, 'firecracker') && b.weak === 'fire' && bestVal < 30) return { type: 'item', id: 'firecracker' };
  return best;
}

function fight(s, enemy, ctx, log) {
  const b = R.createBattle(s, enemy, ctx);
  let guard = 0;
  while (!b.over && guard++ < 200) {
    const a = chooseBattleAction(s, b);
    const ev = R.playerAction(s, b, a);
    if (ev.length === 1 && ev[0].t === 'deny') R.playerAction(s, b, { type: 'attack' });
  }
  if (log) log.push(`  전투 ${D.ENEMIES[enemy].name}: ${b.result} (HP ${s.player.hp}/${R.stats(s).maxHp}, Lv${s.player.lv})`);
  return b;
}

function hubPhase(s, log) {
  // 엔딩
  if (R.canSeeEnding(s)) { s.flags.endingSeen = true; return 'end'; }
  const st = R.stats(s);
  // 치료
  if ((s.player.hp < st.maxHp * 0.9 || s.player.mp < st.maxMp * 0.7 || s.player.status.poison) && s.silver >= (s.flags.infirmaryFree ? 0 : 20)) R.infirmary(s);
  // 정화
  for (const q of D.QUESTS) if (R.canPurifyQuest(s, q.id)) { R.purifyQuest(s, q.id); log.push(`  정화: ${q.cursedName}`); }
  for (const a of s.antiques.filter((x) => x.state === 'cursed')) {
    if (!R.count(s, 'salt') && s.silver >= 120) R.buy(s, 'salt', 1);
    if (R.count(s, 'salt')) R.purifyFound(s, a.uid);
  }
  // 장착/판매
  const purified = s.antiques.filter((a) => a.state === 'purified').sort((a, b) => antiqueScore(b.def) - antiqueScore(a.def));
  s.equip = [purified[0] ? purified[0].uid : null, purified[1] ? purified[1].uid : null];
  R.clampVitals(s);
  for (const a of purified.slice(2)) R.sellAntique(s, a.uid);
  // 마법 수업 (미니게임은 통과했다고 본다)
  for (const id of D.SPELL_ORDER) {
    if (R.canLearn(s, id).ok && s.silver >= D.SPELLS[id].tuition + 30) { R.learnSpell(s, id); log.push(`  수업: ${D.SPELLS[id].name} (-${D.SPELLS[id].tuition})`); }
  }
  // 의뢰 매입 + 재료 구매
  for (const q of R.customers(s)) {
    if (R.activeQuests(s).length >= 3) break;
    if (s.silver >= q.buy + 60) { R.acceptQuest(s, q.id); log.push(`  매입: ${q.cursedName} (-${q.buy})`); }
  }
  if (fieldPhase(s, log) === 'dead') return 'ok';
  for (const q of D.QUESTS) if (R.canPurifyQuest(s, q.id)) { R.purifyQuest(s, q.id); log.push(`  정화: ${q.cursedName}`); }
  for (const q of R.activeQuests(s)) {
    if (q.objective.type !== 'items') continue;
    for (const id of Object.keys(q.objective.items)) {
      const need = q.objective.items[id] - R.count(s, id);
      const it = D.ITEMS[id];
      if (need > 0 && (!it.unlockFloor || s.floorsReached >= it.unlockFloor) && s.silver >= it.price * need + 50) R.buy(s, id, need);
    }
    if (R.canPurifyQuest(s, q.id)) { R.purifyQuest(s, q.id); log.push(`  정화(재료): ${q.cursedName}`); }
  }
  // 물약 준비
  const want = s.floorsReached >= 3 && s.silver > 300 ? { big_potion: 2, hp_potion: 3 } : { hp_potion: 4 };
  Object.assign(want, { mp_potion: s.player.lv >= 3 ? 2 : 0, herb: 1, feather: 1 });
  for (const id of Object.keys(want)) {
    while (R.count(s, id) < want[id] && s.silver >= D.ITEMS[id].price + 30) {
      if (D.ITEMS[id].unlockFloor && s.floorsReached < D.ITEMS[id].unlockFloor) break;
      R.buy(s, id, 1);
    }
  }
  R.checkBadges(s);
  return 'ok';
}

// 학교 필드: 필드 의뢰와 필드 퍼즐(도서관·분수)을 실제 규칙 함수로 푼다
function fieldWalk(s, x, y) { const p = F.findPath(s, x, y); if (!p) return false; for (const [a, b] of p) F.step(s, a, b); return true; }
function fieldPhase(s, log) {
  const mv = (dx, dy) => F.step(s, s.field.x + dx, s.field.y + dy);
  if (s.quests.q1.status === 'active') {
    F.enterArea(s, 'music', 8, 4);
    F.search(s, 'bench');
    if (F.useLocker(s).ok) log.push('  필드: 음악실 사물함에서 태엽');
  }
  if (!s.field.libGate) {
    F.enterArea(s, 'library', 5, 11);
    fieldWalk(s, 5, 10); mv(0, -1); mv(-1, 0); mv(-1, 0);
    fieldWalk(s, 2, 10); mv(0, -1); mv(0, -1);
    fieldWalk(s, 5, 10); mv(0, -1); mv(1, 0); mv(1, 0);
    fieldWalk(s, 8, 10); mv(0, -1); mv(0, -1);
    if (s.field.libGate) { F.openLibChest(s); log.push('  필드: 도서관 철문 개방'); }
  }
  if (s.field.libGate && s.quests.q4.status === 'active') { F.enterArea(s, 'library', 5, 2); if (F.useLectern(s).ok) log.push('  필드: 일기장을 독서대에'); }
  if (!s.field.fountain) {
    F.enterArea(s, 'garden', 5, 1);
    for (const [x, y] of [[3, 10], [3, 6], [7, 6], [7, 10]]) fieldWalk(s, x, y);
    if (F.useWell(s).ok) log.push('  필드: 분수 퍼즐 → 우물');
  }
  if (s.quests.q5.status === 'active' && s.player.lv >= 3) {
    F.enterArea(s, 'maze', 13, 9);
    const m = F.genMaze(s.day);
    // 오두막 옆 칸까지 지도 전체 기준 최단 경로 (몬스터는 싸워서 지나간다)
    const key = (x, y) => x + ',' + y;
    const prev = new Map([[key(13, 9), null]]); const q = [[13, 9]]; let end = null;
    while (q.length && !end) {
      const [x, y] = q.shift();
      for (const [dx, dy] of [[0, -1], [1, 0], [0, 1], [-1, 0]]) {
        const nx = x + dx, ny = y + dy;
        if (nx === m.shed.x && ny === m.shed.y) { end = [x, y]; break; }
        if (prev.has(key(nx, ny)) || !m.rows[ny] || m.rows[ny][nx] !== '.') continue;
        prev.set(key(nx, ny), [x, y]); q.push([nx, ny]);
      }
    }
    const path = []; for (let c = end; c && !(c[0] === 13 && c[1] === 9); c = prev.get(key(c[0], c[1]))) path.unshift(c);
    for (const [nx, ny] of path) {
      let r = F.step(s, nx, ny);
      if (r.type === 'battle') {
        const b = fight(s, r.obj.enemy, {}, null);
        if (b.result === 'lose') { die(s, log); F.enterArea(s, 'hall', 9, 2); return 'dead'; }
        if (b.result === 'win') F.defeatMonster(s, nx, ny);
        r = F.step(s, nx, ny);
      }
    }
    if (F.useShed(s).qid) log.push('  필드: 미로 오두막에서 빗자루 끈');
  }
  F.enterArea(s, 'club', 4, 5);
  return 'ok';
}

function targetFloor(s) {
  // 진행 중 의뢰가 있는 층 우선
  for (const q of R.activeQuests(s)) {
    const o = q.objective;
    if (o.floor && s.quests[q.id].status === 'active' && s.floorsReached >= o.floor && s.player.lv >= D.FLOORS[o.floor].recLv) return { floor: o.floor, goDeeper: false };
  }
  const lvCap = Math.max(1, Math.min(5, s.player.lv));
  const f = Math.min(s.floorsReached, lvCap);
  return { floor: f, goDeeper: f === s.floorsReached && !(f === 5) };
}

function walkTo(s, tx, ty, log, ctx) {
  let guard = 0;
  while (!(s.exp.x === tx && s.exp.y === ty) && guard++ < 300) {
    const path = R.findPath(s, tx, ty, true);
    if (!path || !path.length) return 'nopath';
    const [nx, ny] = path[0];
    const r = R.stepInto(s, nx, ny);
    const res = handle(s, r, nx, ny, log, ctx);
    if (res === 'dead' || res === 'home') return res;
    if (ctx.floorChanged) return 'floor';
  }
  return 'arrived';
}

function handle(s, r, nx, ny, log, ctx) {
  if (!r) return null;
  const list = r.type === 'multi' ? r.list : [r];
  for (const e of list) {
    switch (e.type) {
      case 'battle': {
        const b = fight(s, e.enemy, e.fixed ? { fixedKey: R.key(nx, ny) } : {}, ctx.verbose ? log : null);
        if (b.result === 'lose') return die(s, log);
        if (b.result === 'win' && e.fixed) { s.exp.x = nx; s.exp.y = ny; R.reveal(s); }
        break;
      }
      case 'boss': {
        const b = fight(s, e.enemy, {}, log);
        if (b.result === 'lose') return die(s, log);
        s.exp.x = nx; s.exp.y = ny;
        break;
      }
      case 'door': if (R.count(s, 'key')) R.openDoor(s, nx, ny); else ctx.doorBlocked = true; break;
      case 'chest': R.openChest(s, e.x, e.y, e.treasure); break;
      case 'lockedChest': if (R.count(s, 'key') > (ctx.wantDoor ? 1 : 0)) R.openLockedChest(s, e.x, e.y); break;
      case 'mimic': { R.markOpened(s, e.x, e.y); const b = fight(s, 'lockmimic', {}, ctx.verbose ? log : null); if (b.result === 'lose') return die(s, log); break; }
      case 'fountain': { const st = R.stats(s); if (s.player.hp < st.maxHp * 0.8 || s.player.mp < st.maxMp * 0.6) R.useFountain(s, e.x, e.y); break; }
      case 'event': {
        R.markUsed(s, e.x, e.y);
        if (e.ev === 'quiz') { const i = R.pickQuiz(s); R.answerQuiz(s, i, R.rand() < 0.75 ? D.QUIZ[i].c : (D.QUIZ[i].c + 1) % 3); }
        else if (e.ev === 'jar') { if (s.silver > 150) R.gamble(s); }
        else if (e.ev === 'treasure') R.treasureFind(s);
        else if (e.ev === 'rumor') R.rumor(s);
        else if (e.ev === 'ambush') { const b = fight(s, R.weighted(D.FLOORS[s.exp.floor].enemies), {}, null); if (b.result === 'lose') return die(s, log); }
        break;
      }
      case 'puzzle': R.puzzleReward(s, e.x, e.y); break;
      case 'merchant': if (R.count(s, 'hp_potion') < 2 && s.silver > 100) R.buy(s, 'hp_potion', 2, 1.5); break;
      case 'quest': {
        const q = R.questDef(e.qid);
        if (q.objective.type === 'defeat') {
          const b = fight(s, q.objective.enemy, { qid: q.id }, log);
          if (b.result === 'lose') return die(s, log);
        } else R.completeObjective(s, q.id);
        log.push(`  의뢰 목표 달성: ${q.cursedName}`);
        break;
      }
      case 'up': break;
      case 'down': break;
      default: break;
    }
  }
  return null;
}

function die(s, log) {
  const r = R.applyDefeat(s);
  log.push(`  ✖ 패배 (B${'?'}) 은화 -${r.lost}`);
  return 'dead';
}

function goHome(s, log, ctx) {
  if (R.count(s, 'feather')) { R.removeItem(s, 'feather', 1); R.returnHome(s); return 'home'; }
  // 걸어서 올라가기
  let guard = 0;
  while (s.exp && guard++ < 10) {
    const map = R.genFloor(s.exp.floor);
    const r = walkTo(s, map.start.x, map.start.y, log, ctx);
    if (r === 'dead') return 'dead';
    if (s.exp.floor === 1) { R.returnHome(s); return 'home'; }
    R.enterFloor(s, s.exp.floor - 1, 'goal');
  }
  if (s.exp) R.returnHome(s);
  return 'home';
}

function lowOnResources(s) {
  const st = R.stats(s);
  const potions = R.count(s, 'hp_potion') + R.count(s, 'big_potion') * 2;
  return s.player.hp < st.maxHp * 0.4 && potions === 0;
}

function expedition(s, log, verbose) {
  const tf = targetFloor(s);
  R.startExpedition(s, tf.floor);
  log.push(`Day ${s.day} → B${tf.floor} (Lv${s.player.lv}, 은화 ${s.silver}, 실적 ${s.purified})`);
  const ctx = { verbose };
  for (let hop = 0; hop < 6 && s.exp; hop++) {
    const f = s.exp.floor;
    const map = R.genFloor(f);
    const run = s.exp.runs[f];
    // 1) 이 층의 진행 중 의뢰 표식
    for (const m of Object.keys(map.markers)) {
      const ts = R.tileState(s, map.markers[m].x, map.markers[m].y);
      if (ts.kind === 'quest') {
        const r = walkTo(s, map.markers[m].x, map.markers[m].y, log, ctx);
        if (r === 'dead') return;
        if (!s.exp) return;
      }
    }
    // 2) 상자·샘물·이벤트 줍기 (가까운 순)
    const targets = [];
    for (let y = 0; y < map.h; y++) for (let x = 0; x < map.w; x++) {
      const ts = R.tileState(s, x, y);
      if (['chest', 'event', 'key', 'puzzle'].includes(ts.kind) && !map.locked.includes(R.key(x, y))) targets.push([x, y]);
      if (ts.kind === 'lockedChest' && R.count(s, 'key')) targets.push([x, y]);
    }
    if (map.door && map.treasure && !s.world.doors[f]?.[R.key(map.door.x, map.door.y)] && R.count(s, 'key')) targets.push([map.door.x, map.door.y], [map.treasure.x, map.treasure.y]);
    if (map.door && s.world.doors[f]?.[R.key(map.door.x, map.door.y)] && !run.opened[R.key(map.treasure.x, map.treasure.y)]) targets.push([map.treasure.x, map.treasure.y]);
    for (const [x, y] of targets) {
      if (lowOnResources(s)) break;
      const ts = R.tileState(s, x, y);
      if (ts.kind === 'floor' || ts.kind === 'chestOpen') continue;
      if (ts.kind === 'door') {
        const p = R.findPath(s, x, y, true);
        if (!p) continue;
        for (const [nx, ny] of p.slice(0, -1)) { const r = handle(s, R.stepInto(s, nx, ny), nx, ny, log, ctx); if (r === 'dead') return; }
        if (R.count(s, 'key')) R.openDoor(s, x, y);
        continue;
      }
      const r = walkTo(s, x, y, log, ctx);
      if (r === 'dead') return;
    }
    if (lowOnResources(s)) break;
    // 3) 더 내려가기
    const wantDeeper = tf.goDeeper && D.FLOORS[f].down && s.player.lv >= D.FLOORS[f + 1].recLv - 1;
    const bossTime = f === 5 && !s.flags.bossDefeated && s.player.lv >= 6;
    if (bossTime) {
      const st = R.stats(s);
      if (s.player.hp < st.maxHp * 0.8 && run && !run.used[R.key(0, 0)]) { /* 샘물은 위에서 처리 */ }
      const r = walkTo(s, map.goal.x, map.goal.y, log, ctx);
      if (r === 'dead') return;
      break;
    }
    if (wantDeeper) {
      const r = walkTo(s, map.goal.x, map.goal.y, log, ctx);
      if (r === 'dead') return;
      if (!s.exp) return;
      R.enterFloor(s, f + 1, 'start');
      log.push(`  ↓ B${f + 1} 도착`);
      continue;
    }
    break;
  }
  if (s.exp) goHome(s, log, ctx);
}

function playOne(seed, verbose) {
  R.setRng(R.makeRng(seed));
  const s = R.newGame();
  s.flags.introSeen = true;
  const log = [];
  let bossDay = null, bossLv = null;
  while (s.day <= MAX_DAYS) {
    const h = hubPhase(s, log);
    if (h === 'end') break;
    expedition(s, log, verbose);
    if (s.flags.bossDefeated && bossDay == null) { bossDay = s.day; bossLv = s.player.lv; }
  }
  const finished = s.flags.endingSeen || R.canSeeEnding(s);
  return {
    seed, finished, days: s.day, lv: s.player.lv, purified: s.purified, deaths: s.stats.defeats, battles: s.stats.battles,
    bossDay, bossLv, silver: s.silver, spells: s.spells.length, badges: Object.keys(s.badges).length, codex: Object.keys(s.codex).length, log,
  };
}

function median(a) { const b = [...a].sort((x, y) => x - y); return b[Math.floor(b.length / 2)]; }

if (require.main === module) {
  const n = Number(process.argv[2] || 200);
  const verbose = process.argv.includes('--verbose');
  const results = [];
  for (let i = 0; i < n; i++) results.push(playOne(1000 + i, verbose));
  const fin = results.filter((r) => r.finished);
  console.log(`판 수 ${n} · 엔딩 도달 ${fin.length} (${Math.round((fin.length / n) * 100)}%)`);
  if (fin.length) {
    console.log(`엔딩까지 일수 중앙값 ${median(fin.map((r) => r.days))} (최소 ${Math.min(...fin.map((r) => r.days))}, 최대 ${Math.max(...fin.map((r) => r.days))})`);
    console.log(`배운 마법 수 중앙값 ${median(fin.map((r) => r.spells))}/${D.SPELL_ORDER.length}`);
    console.log(`보스 격파 레벨 중앙값 ${median(fin.map((r) => r.bossLv))} · 패배 횟수 중앙값 ${median(fin.map((r) => r.deaths))} · 전투 수 중앙값 ${median(fin.map((r) => r.battles))}`);
    console.log(`훈장 중앙값 ${median(fin.map((r) => r.badges))}/${D.BADGES.length} · 도감 중앙값 ${median(fin.map((r) => r.codex))}/20`);
  }
  const fail = results.filter((r) => !r.finished);
  if (fail.length) {
    console.log(`미완료 예시(seed ${fail[0].seed}): Lv${fail[0].lv} 실적 ${fail[0].purified} 보스${fail[0].bossDay ? 'O' : 'X'} 패배 ${fail[0].deaths}`);
    if (verbose) console.log(fail[0].log.slice(-40).join('\n'));
  }
  if (process.argv.includes('--log')) console.log(results[0].log.join('\n'));
}

module.exports = { playOne };
