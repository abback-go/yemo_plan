/* 저주 매입합니다 — 규칙(순수 로직). 화면 코드와 분리되어 Node 테스트에서도 실행된다. */
(function () {
  'use strict';
  const W = (globalThis.W = globalThis.W || {});
  const D = W.DATA;
  const T = D.TUNING;

  // ───────── 난수 ─────────
  function makeRng(seed) {
    let a = seed >>> 0;
    return function () {
      a = (a + 0x6d2b79f5) >>> 0;
      let t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  let rng = Math.random;
  function setRng(fn) { rng = fn || Math.random; }
  const rand = () => rng();
  const randInt = (lo, hi) => lo + Math.floor(rand() * (hi - lo + 1));
  const uniform = (lo, hi) => lo + rand() * (hi - lo);
  const pick = (arr) => arr[Math.floor(rand() * arr.length)];
  function weighted(pairs, r) {
    const roll = r || rand;
    const total = pairs.reduce((s, p) => s + p[1], 0);
    let x = roll() * total;
    for (const [v, w] of pairs) { x -= w; if (x < 0) return v; }
    return pairs[pairs.length - 1][0];
  }
  const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
  const key = (x, y) => x + ',' + y;
  const pct = (v) => Math.round(v * 100) + '%';

  // ───────── 효과 설명 ─────────
  const EFFECT_TEXT = {
    atk: (v) => `공격 +${v}`, def: (v) => `방어 +${v}`, maxHp: (v) => `최대 체력 +${v}`, maxMp: (v) => `최대 마력 +${v}`,
    flee: (v) => `도망 확률 +${pct(v)}`, crit: (v) => `치명타 +${pct(v)}`, sight: (v) => `시야 +${v}`,
    petBoost: (v) => `먹물 도움 +${pct(v)}`, potionBoost: (v) => `물약 회복량 +${pct(v)}`,
    fireBoost: (v) => `불 마법 +${pct(v)}`, iceBoost: (v) => `얼음 마법 +${pct(v)}`, lightBoost: (v) => `빛 마법 +${pct(v)}`,
    mpRegen: (v) => `매 턴 마력 +${v}`, silverBoost: (v) => `전투 은화 +${pct(v)}`,
    sleepChance: (v) => `전투 시작 시 ${pct(v)} 확률로 적이 잠듦`, trapSight: () => '숨은 함정이 보임',
  };
  function describeEffect(effect) {
    return Object.keys(effect).map((k) => (EFFECT_TEXT[k] ? EFFECT_TEXT[k](effect[k]) : k)).join(' · ');
  }

  // ───────── 새 게임 / 저장 ─────────
  const SAVE_VERSION = 2;
  function newGame() {
    const P = D.PLAYER;
    const s = {
      version: SAVE_VERSION,
      player: { lv: 1, exp: 0, hp: P.base.maxHp, mp: P.base.maxMp, status: { poison: 0, curseNext: 0 } },
      silver: P.startSilver,
      inv: Object.assign({}, P.startItems),
      antiques: [],
      equip: [null, null],
      uidSeq: 1,
      quests: {},
      day: 1,
      purified: 0,
      floorsReached: 1,
      exp: null,
      spells: [],
      world: { doors: {} },
      field: newFieldState(),
      flags: { introSeen: false, bossDefeated: false, directorDefeated: false, endingSeen: false, infirmaryFree: true, legendPurified: false, metCustomer: false },
      stats: { quizCorrect: 0, quizWrong: 0, gambles: 0, shopBuys: 0, weakHits: 0, puzzles: 0, battles: 0, kills: {}, purifyAll: 0, defeats: 0 },
      known: {},
      codex: {},
      badges: {},
      settings: { sound: true },
      lastQuiz: [],
    };
    for (const q of D.QUESTS) s.quests[q.id] = { status: 'locked', cooldown: 0 };
    refreshCustomers(s);
    return s;
  }
  // 필드(학교 지도) 진행 상태. 지형·물체는 world.js 가 정의한다.
  function newFieldState() {
    return {
      area: 'club', x: 4, y: 5,
      plates: [], fountain: false, well: false, // 정원 분수 룬 판 순서 퍼즐
      carts: null, libGate: false, libChest: false, // 도서관 책수레 밀기 (null = 처음 위치)
      searched: {}, musicKey: false,       // 음악실 숨은 물건 찾기
      maze: null,                          // 밤의 미로 (날마다 새로 만든다)
    };
  }
  function serialize(s) { return JSON.stringify(s); }
  function deserialize(str) {
    let data;
    try { data = JSON.parse(str); } catch (e) { return null; }
    if (!data || data.version !== SAVE_VERSION || !data.player) return null;
    const base = newGame();
    const merged = Object.assign(base, data);
    merged.flags = Object.assign(base.flags, data.flags || {});
    merged.stats = Object.assign(base.stats, data.stats || {});
    merged.settings = Object.assign(base.settings, data.settings || {});
    merged.player.status = Object.assign({ poison: 0, curseNext: 0 }, (data.player && data.player.status) || {});
    merged.field = Object.assign(newFieldState(), data.field || {});
    for (const q of D.QUESTS) if (!merged.quests[q.id]) merged.quests[q.id] = { status: 'locked', cooldown: 0 };
    return merged;
  }

  // ───────── 능력치 ─────────
  function equippedDefs(s) {
    return s.equip.map((uid) => (uid == null ? null : s.antiques.find((a) => a.uid === uid))).filter(Boolean)
      .map((a) => D.ANTIQUES[a.def]).filter(Boolean);
  }
  function stats(s) {
    const P = D.PLAYER;
    const lv = s.player.lv;
    const o = {
      maxHp: P.base.maxHp + P.perLevel.maxHp * (lv - 1),
      maxMp: P.base.maxMp + P.perLevel.maxMp * (lv - 1),
      atk: P.base.atk + P.perLevel.atk * (lv - 1),
      def: P.base.def + P.perLevel.def * (lv - 1),
      flee: 0, crit: 0, sight: 0, petBoost: 0, potionBoost: 0, fireBoost: 0, iceBoost: 0, lightBoost: 0,
      mpRegen: 0, silverBoost: 0, sleepChance: 0, trapSight: false,
    };
    for (const def of equippedDefs(s)) {
      for (const k of Object.keys(def.effect)) {
        if (k === 'trapSight') o.trapSight = true;
        else o[k] += def.effect[k];
      }
    }
    return o;
  }
  function clampVitals(s) {
    const st = stats(s);
    s.player.hp = clamp(s.player.hp, 0, st.maxHp);
    s.player.mp = clamp(s.player.mp, 0, st.maxMp);
  }
  function knownSpells(s) { return D.SPELL_ORDER.filter((id) => s.spells.includes(id)); }
  // ───────── 마법 수업 ─────────
  function classSpells(cls) { return D.SPELL_ORDER.filter((id) => D.SPELLS[id].cls === cls); }
  function classOpen(s, cls) {
    const C = D.CLASSES[cls];
    return !C.needAll || classSpells(C.needAll).every((id) => s.spells.includes(id));
  }
  function canLearn(s, id) {
    const sp = D.SPELLS[id];
    if (!sp) return { ok: false, reason: '그런 마법은 없다.' };
    if (s.spells.includes(id)) return { ok: false, reason: '이미 배운 마법이다.' };
    if (!classOpen(s, sp.cls)) return { ok: false, reason: `${D.CLASSES[D.CLASSES[sp.cls].needAll].name} 마법을 먼저 모두 배워야 한다.` };
    if (s.player.lv < sp.learn) return { ok: false, reason: `Lv${sp.learn}부터 들을 수 있다.` };
    if (s.silver < sp.tuition) return { ok: false, reason: `수강료 은화 ${sp.tuition - s.silver}개가 모자라다.` };
    return { ok: true };
  }
  // 룬 따라 그리기 문제: 같은 룬이 세 번 연속 나오지 않게 한다
  function runeSequence(len) {
    const out = [];
    while (out.length < len) {
      const r = randInt(0, D.RUNES.length - 1);
      if (out.length >= 2 && out[out.length - 1] === r && out[out.length - 2] === r) continue;
      out.push(r);
    }
    return out;
  }
  // 미니게임을 통과한 뒤 호출한다. 수강료는 합격할 때 낸다.
  function learnSpell(s, id) {
    const chk = canLearn(s, id);
    if (!chk.ok) return chk;
    const sp = D.SPELLS[id];
    s.silver -= sp.tuition;
    s.spells.push(id);
    return { ok: true, spell: sp };
  }
  function learnableSpells(s) { return D.SPELL_ORDER.filter((id) => canLearn(s, id).ok); }
  function expToNext(s) { return D.EXP_CURVE[s.player.lv] || 99999; }

  function gainExp(s, n) {
    const ups = [];
    s.player.exp += n;
    while (s.player.lv < D.PLAYER.maxLevel && s.player.exp >= expToNext(s)) {
      s.player.exp -= expToNext(s);
      s.player.lv += 1;
      // 레벨업: 늘어난 최대치만큼만 회복 (전부 회복하면 연속 하강이 너무 쉬워진다)
      s.player.hp += D.PLAYER.perLevel.maxHp;
      s.player.mp += D.PLAYER.perLevel.maxMp;
      clampVitals(s);
      // 레벨업으로 마법이 생기지는 않는다. 새로 수강할 수 있게 된 마법만 알려준다.
      const classReady = D.SPELL_ORDER.filter((id) => D.SPELLS[id].learn === s.player.lv && !s.spells.includes(id));
      ups.push({ lv: s.player.lv, classReady });
    }
    return ups;
  }

  // ───────── 가방 ─────────
  const count = (s, id) => s.inv[id] || 0;
  function addItem(s, id, n) { s.inv[id] = count(s, id) + (n == null ? 1 : n); }
  function removeItem(s, id, n) {
    const k = n == null ? 1 : n;
    if (count(s, id) < k) return false;
    s.inv[id] -= k;
    if (s.inv[id] <= 0) delete s.inv[id];
    return true;
  }
  function hasItems(s, items) { return Object.keys(items).every((id) => count(s, id) >= items[id]); }

  // ───────── 의뢰 ─────────
  const questDef = (id) => D.QUESTS.find((q) => q.id === id);
  function unlockMet(s, u) {
    if (u.floor && s.floorsReached < u.floor) return false;
    if (u.purified && s.purified < u.purified) return false;
    return true;
  }
  function refreshCustomers(s) {
    for (const q of D.QUESTS) {
      const rec = s.quests[q.id];
      if (rec.status === 'locked' && unlockMet(s, q.unlock)) rec.status = 'available';
    }
  }
  function customers(s) {
    return D.QUESTS.filter((q) => s.quests[q.id].status === 'available' && (s.quests[q.id].cooldown || 0) <= s.day).slice(0, 2);
  }
  function activeQuests(s) {
    return D.QUESTS.filter((q) => ['active', 'ready'].includes(s.quests[q.id].status));
  }
  function canPurifyQuest(s, qid) {
    const q = questDef(qid);
    const rec = s.quests[qid];
    if (rec.status === 'ready') return true;
    if (rec.status === 'active' && q.objective.type === 'items') return hasItems(s, q.objective.items);
    return false;
  }
  function acceptQuest(s, qid) {
    const q = questDef(qid);
    const rec = s.quests[qid];
    if (rec.status !== 'available') return { ok: false, reason: '지금은 매입할 수 없어요.' };
    if (activeQuests(s).length >= 3) return { ok: false, reason: '진행 중인 의뢰가 너무 많아요. (최대 3건)' };
    if (s.silver < q.buy) return { ok: false, reason: `은화가 ${q.buy - s.silver}개 모자라요.` };
    s.silver -= q.buy;
    rec.status = 'active';
    s.flags.metCustomer = true;
    s.stats.bought = (s.stats.bought || 0) + 1;
    return { ok: true };
  }
  function declineQuest(s, qid) {
    const rec = s.quests[qid];
    if (rec.status === 'available') rec.cooldown = s.day + 1;
    s.flags.metCustomer = true;
  }
  function completeObjective(s, qid) {
    const q = questDef(qid);
    const rec = s.quests[qid];
    if (rec.status !== 'active') return false;
    if (q.objective.item) addItem(s, q.objective.item, 1);
    rec.status = 'ready';
    return true;
  }
  function newUid(s) { return s.uidSeq++; }
  function purifyQuest(s, qid) {
    if (!canPurifyQuest(s, qid)) return { ok: false, reason: '아직 정화할 준비가 안 됐어요.' };
    const q = questDef(qid);
    if (q.objective.type === 'items') {
      for (const id of Object.keys(q.objective.items)) removeItem(s, id, q.objective.items[id]);
    } else if (q.objective.item) {
      removeItem(s, q.objective.item, 1);
    }
    s.quests[qid].status = 'done';
    const a = { uid: newUid(s), def: q.antique, state: 'purified', from: qid };
    s.antiques.push(a);
    s.purified += 1;
    s.stats.purifyAll += 1;
    s.codex[q.antique] = true;
    if (D.ANTIQUES[q.antique].grade === 'legend') s.flags.legendPurified = true;
    refreshCustomers(s);
    return { ok: true, antique: a };
  }
  function addCursedAntique(s, floor, grade) {
    const a = { uid: newUid(s), def: null, state: 'cursed', floor };
    if (grade) a.grade = grade;
    s.antiques.push(a);
    return a;
  }
  function rollAntiqueDef(floor, forced) {
    const odds = D.GRADE_ODDS[floor] || D.GRADE_ODDS[1];
    const grade = forced || weighted(D.GRADE_ORDER.map((g, i) => [g, odds[i]]));
    const pool = Object.keys(D.ANTIQUES).filter((id) => D.ANTIQUES[id].random && D.ANTIQUES[id].grade === grade);
    return pick(pool);
  }
  function purifyFound(s, uid) {
    const a = s.antiques.find((x) => x.uid === uid);
    if (!a || a.state !== 'cursed') return { ok: false, reason: '정화할 수 없어요.' };
    if (count(s, 'salt') < 1) return { ok: false, reason: '정화 소금이 필요해요. (매점 40은화)' };
    removeItem(s, 'salt', 1);
    a.def = rollAntiqueDef(a.floor || 1, a.grade);
    a.state = 'purified';
    s.stats.purifyAll += 1;
    s.codex[a.def] = true;
    if (D.ANTIQUES[a.def].grade === 'legend') s.flags.legendPurified = true;
    return { ok: true, antique: a };
  }
  function sellAntique(s, uid) {
    const i = s.antiques.findIndex((x) => x.uid === uid);
    if (i < 0) return { ok: false };
    const a = s.antiques[i];
    if (s.equip.includes(uid)) return { ok: false, reason: '장착 중인 골동품은 팔 수 없어요.' };
    const price = a.state === 'purified' ? D.ANTIQUES[a.def].value : 10;
    s.antiques.splice(i, 1);
    s.silver += price;
    return { ok: true, price };
  }
  function equipAntique(s, uid, slot) {
    const a = s.antiques.find((x) => x.uid === uid);
    if (!a || a.state !== 'purified') return { ok: false, reason: '정화된 골동품만 장착할 수 있어요.' };
    const other = s.equip.indexOf(uid);
    if (other >= 0) s.equip[other] = null;
    let target = slot;
    if (target == null) target = s.equip[0] == null ? 0 : s.equip[1] == null ? 1 : 0;
    s.equip[target] = uid;
    clampVitals(s);
    return { ok: true, slot: target };
  }
  function unequip(s, slot) { s.equip[slot] = null; clampVitals(s); }

  // ───────── 상점·양호실 ─────────
  function shopItems(s, tab) {
    return Object.keys(D.ITEMS).filter((id) => {
      const it = D.ITEMS[id];
      if (it.cat === 'quest' || it.cat !== tab) return false;
      return !it.unlockFloor || s.floorsReached >= it.unlockFloor;
    });
  }
  function buy(s, id, qty, priceMult) {
    const it = D.ITEMS[id];
    const n = qty || 1;
    const price = Math.round(it.price * (priceMult || 1)) * n;
    if (s.silver < price) return { ok: false, reason: `은화가 ${price - s.silver}개 모자라요.` };
    s.silver -= price;
    addItem(s, id, n);
    s.stats.shopBuys += 1;
    return { ok: true, price };
  }
  const sellPrice = (id) => Math.floor(D.ITEMS[id].price * T.sellRatio);
  function sellItem(s, id, qty) {
    const n = qty || 1;
    if (D.ITEMS[id].cat === 'quest') return { ok: false, reason: '의뢰 물건은 팔 수 없어요.' };
    if (!removeItem(s, id, n)) return { ok: false, reason: '가진 개수가 부족해요.' };
    const price = sellPrice(id) * n;
    s.silver += price;
    return { ok: true, price };
  }
  function infirmary(s) {
    const free = s.flags.infirmaryFree;
    const cost = free ? 0 : T.infirmaryCost;
    if (s.silver < cost) return { ok: false, reason: `은화 ${cost}개가 필요해요.` };
    s.silver -= cost;
    s.flags.infirmaryFree = false;
    const st = stats(s);
    s.player.hp = st.maxHp;
    s.player.mp = st.maxMp;
    s.player.status.poison = 0;
    s.player.status.curseNext = 0;
    return { ok: true, cost };
  }

  // ───────── 훈장 ─────────
  function badgeMet(s, id) {
    switch (id) {
      case 'first_buy': return (s.stats.bought || 0) >= 1;
      case 'first_purify': return s.stats.purifyAll >= 1;
      case 'purify5': return s.purified >= 5;
      case 'floor3': return s.floorsReached >= 3;
      case 'floor5': return s.floorsReached >= 5;
      case 'director': return s.flags.directorDefeated;
      case 'nocturne': return s.flags.bossDefeated;
      case 'quiz5': return s.stats.quizCorrect >= 5;
      case 'gamble5': return s.stats.gambles >= 5;
      case 'shop10': return s.stats.shopBuys >= 10;
      case 'codex8': return Object.keys(s.codex).length >= 8;
      case 'legend': return s.flags.legendPurified;
      case 'weak20': return s.stats.weakHits >= 20;
      case 'puzzle3': return s.stats.puzzles >= 3;
      case 'level5': return s.player.lv >= 5;
      case 'basic_grad': return classSpells('basic').every((id) => s.spells.includes(id));
      case 'adv_grad': return classSpells('advanced').every((id) => s.spells.includes(id));
      case 'library': return s.field.libGate;
      case 'well': return s.field.fountain;
      case 'maze': return !!s.flags.mazeCenter;
      default: return false;
    }
  }
  function checkBadges(s) {
    const earned = [];
    for (const b of D.BADGES) {
      if (!s.badges[b.id] && badgeMet(s, b.id)) {
        s.badges[b.id] = s.day;
        s.silver += b.reward;
        earned.push(b);
      }
    }
    return earned;
  }

  // ───────── 목표 안내 ─────────
  function objectiveText(s) {
    if (!s.spells.length) return '본관 「기본마법반」에서 첫 마법(불씨)을 배우자.';
    if (!s.flags.metCustomer) return '부실로 돌아가 첫 손님을 맞이하자.';
    const ready = D.QUESTS.find((q) => canPurifyQuest(s, q.id));
    if (ready) return `부실 정화대에서 「${ready.cursedName}」을(를) 정화하자.`;
    const act = activeQuests(s)[0];
    if (act) return act.hint;
    if (s.purified < 5 && customers(s).length) return `정화 실적 ${s.purified}/5 — 부실에 손님이 기다리고 있다.`;
    if (!s.flags.bossDefeated && s.floorsReached < 5) return `봉인 창고 더 깊은 곳(B${s.floorsReached + 1})을 찾아보자.`;
    if (!s.flags.bossDefeated) return 'B5 가장 깊은 곳, 그림자 집사 녹턴을 쓰러뜨리자.';
    if (s.purified < 5) return `정화 실적 ${s.purified}/5 — 손님을 더 받아 실적을 채우자.`;
    return '자유 탐험 — 도감과 훈장을 채워 보자.';
  }
  function canSeeEnding(s) { return s.flags.bossDefeated && s.purified >= 5 && !s.flags.endingSeen; }

  // ───────── 미로 생성 ─────────
  const MAP_W = 11, MAP_H = 15, CELL_W = 5, CELL_H = 7;
  const MAP_CACHE = {};
  const DIRS = [[0, -1], [1, 0], [0, 1], [-1, 0]];

  function genFloor(id) {
    if (MAP_CACHE[id]) return MAP_CACHE[id];
    const F = D.FLOORS[id];
    const r = makeRng(F.seed);
    const pickR = (arr) => arr[Math.floor(r() * arr.length)];
    const shuffleR = (arr) => { for (let i = arr.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [arr[i], arr[j]] = [arr[j], arr[i]]; } return arr; };
    const tiles = Array.from({ length: MAP_H }, () => Array(MAP_W).fill('#'));
    const cid = (cx, cy) => cy * CELL_W + cx;
    const cxy = (c) => [c % CELL_W, Math.floor(c / CELL_W)];
    const ctile = (c) => { const [cx, cy] = cxy(c); return [cx * 2 + 1, cy * 2 + 1]; };
    const between = (a, b) => { const [ax, ay] = ctile(a); const [bx, by] = ctile(b); return [(ax + bx) / 2, (ay + by) / 2]; };
    const N = CELL_W * CELL_H;
    for (let c = 0; c < N; c++) { const [x, y] = ctile(c); tiles[y][x] = '.'; }
    const adj = Array.from({ length: N }, () => new Set());
    const cellNeighbors = (c) => {
      const [cx, cy] = cxy(c);
      const out = [];
      for (const [dx, dy] of DIRS) {
        const nx = cx + dx, ny = cy + dy;
        if (nx >= 0 && ny >= 0 && nx < CELL_W && ny < CELL_H) out.push(cid(nx, ny));
      }
      return out;
    };
    const carve = (a, b) => { adj[a].add(b); adj[b].add(a); const [x, y] = between(a, b); tiles[y][x] = '.'; };

    // 1) 완전 미로 (재귀 백트래킹)
    const corners = [cid(0, 0), cid(CELL_W - 1, 0), cid(0, CELL_H - 1), cid(CELL_W - 1, CELL_H - 1)];
    const start = pickR(corners);
    const parent = new Array(N).fill(-1);
    const seen = new Array(N).fill(false);
    const stack = [start];
    seen[start] = true;
    while (stack.length) {
      const cur = stack[stack.length - 1];
      const nbs = shuffleR(cellNeighbors(cur).filter((n) => !seen[n]));
      if (nbs.length) { const n = nbs[0]; seen[n] = true; parent[n] = cur; carve(cur, n); stack.push(n); } else stack.pop();
    }
    const bfsCells = (from) => {
      const dist = new Array(N).fill(-1);
      dist[from] = 0;
      const q = [from];
      while (q.length) { const c = q.shift(); for (const n of adj[c]) if (dist[n] < 0) { dist[n] = dist[c] + 1; q.push(n); } }
      return dist;
    };
    let dist = bfsCells(start);
    const deadEnds = () => { const out = []; for (let c = 0; c < N; c++) if (c !== start && adj[c].size === 1) out.push(c); return out; };

    // 2) 계단(또는 보스) = 가장 먼 막다른 곳
    const ends0 = deadEnds().sort((a, b) => dist[b] - dist[a]);
    const goal = ends0[0];
    const mainPath = new Set();
    for (let c = goal; c !== -1; c = parent[c]) mainPath.add(c);

    // 3) 잠긴 문 뒤 보물방 (서브트리)
    const children = Array.from({ length: N }, () => []);
    for (let c = 0; c < N; c++) if (parent[c] >= 0) children[parent[c]].push(c);
    const subtree = (c) => { const out = []; const q = [c]; while (q.length) { const x = q.shift(); out.push(x); q.push(...children[x]); } return out; };
    const locked = new Set();
    let door = null;
    if (F.door) {
      const cands = [];
      for (let c = 0; c < N; c++) {
        if (c === start || mainPath.has(c) || parent[c] < 0 || dist[c] < 2) continue;
        const st = subtree(c);
        if (st.length < 2 || st.length > 5) continue;
        if (st.some((x) => mainPath.has(x))) continue;
        cands.push(c);
      }
      if (cands.length) {
        const c = pickR(cands);
        subtree(c).forEach((x) => locked.add(x));
        door = between(parent[c], c);
      }
    }

    // 4) 의뢰 표식 = 남은 막다른 곳 중 먼 곳
    const used = new Set([start, goal]);
    const markers = {};
    for (const m of F.markers) {
      const c = deadEnds().filter((x) => !used.has(x) && !locked.has(x)).sort((a, b) => dist[b] - dist[a])[0];
      if (c == null) continue;
      used.add(c);
      markers[m] = c;
    }

    // 5) 고리 만들기 (막다른 길만 있는 미로 방지). 보물방·계단·표식 주변은 건드리지 않는다.
    const protectedCells = new Set([goal, ...Object.values(markers), ...locked]);
    const braids = id === 1 ? 3 : 4;
    const wallPairs = [];
    for (let c = 0; c < N; c++) for (const n of cellNeighbors(c)) if (c < n && !adj[c].has(n)) wallPairs.push([c, n]);
    shuffleR(wallPairs);
    let made = 0;
    for (const [a, b] of wallPairs) {
      if (made >= braids) break;
      if (protectedCells.has(a) || protectedCells.has(b)) continue;
      carve(a, b);
      made++;
    }
    dist = bfsCells(start);

    // 6) 나머지 배치
    const free = (c) => !used.has(c) && !locked.has(c);
    const place = (c, ch) => { used.add(c); const [x, y] = ctile(c); tiles[y][x] = ch; };
    const takeDeadEnd = (pref) => {
      const list = deadEnds().filter(free);
      if (!list.length) return null;
      if (pref === 'far') list.sort((a, b) => dist[b] - dist[a]);
      else if (pref === 'mid') { const md = Math.max(...dist) / 2; list.sort((a, b) => Math.abs(dist[a] - md) - Math.abs(dist[b] - md)); } else shuffleR(list);
      return list[0];
    };
    const takeCell = (filter, sorter) => {
      let list = []; for (let c = 0; c < N; c++) if (free(c) && dist[c] >= 0 && filter(c)) list.push(c);
      if (!list.length) return null;
      if (sorter) list.sort(sorter); else shuffleR(list);
      return list[0];
    };

    { const [sx, sy] = ctile(start); tiles[sy][sx] = 'S'; }
    { const [gx, gy] = ctile(goal); tiles[gy][gx] = F.down ? '>' : 'B'; }
    for (const m of Object.keys(markers)) { const [x, y] = ctile(markers[m]); tiles[y][x] = m; }
    if (door) tiles[door[1]][door[0]] = 'D';
    let treasure = null;
    if (locked.size) {
      const inner = [...locked].sort((a, b) => adj[a].size - adj[b].size || dist[b] - dist[a]);
      place(inner[0], 'C');
      const [tx, ty] = ctile(inner[0]);
      treasure = { x: tx, y: ty };
      inner.slice(1).forEach((c) => used.add(c));
    }
    if (F.key) { const c = takeDeadEnd('mid') ?? takeCell((c) => dist[c] >= 3); if (c != null) place(c, 'K'); }
    if (F.locked) { const c = takeDeadEnd('far') ?? takeCell((c) => dist[c] >= 3); if (c != null) place(c, 'L'); }
    if (F.puzzle) { const c = takeDeadEnd('far') ?? takeCell((c) => dist[c] >= 3); if (c != null) place(c, 'P'); }
    if (F.mimic) { for (let i = 0; i < F.mimic; i++) { const c = takeDeadEnd() ?? takeCell((c) => dist[c] >= 4); if (c != null) place(c, 'X'); } }
    for (let i = 0; i < F.chests; i++) { const c = takeDeadEnd() ?? takeCell((c) => dist[c] >= 3); if (c != null) place(c, 'C'); }
    if (F.merchant) { const c = takeCell((c) => dist[c] >= 3 && adj[c].size >= 3) ?? takeCell((c) => dist[c] >= 3); if (c != null) place(c, '$'); }
    if (F.fountain) {
      const md = Math.max(...dist.filter((d, c) => !locked.has(c))) / 2;
      const c = takeCell((c) => dist[c] >= 2, (a, b) => Math.abs(dist[a] - md) - Math.abs(dist[b] - md));
      if (c != null) place(c, 'F');
    }
    for (let i = 0; i < F.events; i++) { const c = takeCell((c) => dist[c] >= 2 && adj[c].size >= 3) ?? takeCell((c) => dist[c] >= 2); if (c != null) place(c, '?'); }
    // 몬스터: 본 경로 위 2마리 + 나머지 무작위
    let onPath = 0;
    for (let i = 0; i < F.monsters; i++) {
      const c = (onPath < 2 ? takeCell((c) => dist[c] >= 3 && mainPath.has(c)) : null) ?? takeCell((c) => dist[c] >= 3);
      if (c == null) break;
      if (mainPath.has(c)) onPath++;
      place(c, 'M');
    }
    // 함정: 통로 칸(방과 방 사이)
    const passages = [];
    for (let y = 0; y < MAP_H; y++) for (let x = 0; x < MAP_W; x++) {
      if (tiles[y][x] !== '.' || (x % 2 === 1 && y % 2 === 1)) continue;
      passages.push([x, y]);
    }
    const [sx0, sy0] = ctile(start);
    const trapCands = shuffleR(passages.filter(([x, y]) => Math.abs(x - sx0) + Math.abs(y - sy0) > 3 && !isLockedTile(x, y)));
    function isLockedTile(x, y) {
      for (const c of locked) { const [lx, ly] = ctile(c); if (Math.abs(lx - x) + Math.abs(ly - y) <= 1) return true; }
      return false;
    }
    for (let i = 0; i < F.traps && i < trapCands.length; i++) { const [x, y] = trapCands[i]; tiles[y][x] = 'T'; }

    const [sx, sy] = ctile(start);
    const [gx, gy] = ctile(goal);
    const map = {
      id, w: MAP_W, h: MAP_H,
      tiles: tiles.map((row) => row.join('')),
      start: { x: sx, y: sy },
      goal: { x: gx, y: gy },
      door: door ? { x: door[0], y: door[1] } : null,
      treasure,
      markers: Object.fromEntries(Object.keys(markers).map((m) => { const [x, y] = ctile(markers[m]); return [m, { x, y }]; })),
      locked: [...locked].map((c) => { const [x, y] = ctile(c); return key(x, y); }),
    };
    MAP_CACHE[id] = map;
    return map;
  }

  const tileCh = (map, x, y) => (x < 0 || y < 0 || x >= map.w || y >= map.h ? '#' : map.tiles[y][x]);

  // ───────── 탐험 ─────────
  function enemyTable(floor) { return D.FLOORS[floor].enemies; }
  function newRun(s, floor) {
    const map = genFloor(floor);
    const run = { revealed: new Array(map.w * map.h).fill(0), opened: {}, defeated: {}, used: {}, mtype: {}, etype: {}, lamp: 0, hints: T.petHints };
    for (let y = 0; y < map.h; y++) for (let x = 0; x < map.w; x++) {
      const ch = map.tiles[y][x];
      if (ch === 'M') run.mtype[key(x, y)] = weighted(enemyTable(floor));
      if (ch === '?') run.etype[key(x, y)] = weighted([['quiz', 35], ['jar', 25], ['rumor', 15], ['treasure', 15], ['ambush', 10]]);
    }
    return run;
  }
  function startExpedition(s, floor) {
    s.exp = { floor, x: 0, y: 0, runs: {}, sinceBattle: 99, steps: 0, poisonStep: 0 };
    enterFloor(s, floor, 'start');
  }
  function enterFloor(s, floor, at) {
    const map = genFloor(floor);
    if (!s.exp.runs[floor]) s.exp.runs[floor] = newRun(s, floor);
    s.exp.floor = floor;
    const p = at === 'goal' ? map.goal : map.start;
    s.exp.x = p.x; s.exp.y = p.y;
    s.exp.sinceBattle = 0;
    if (floor > s.floorsReached) s.floorsReached = floor;
    refreshCustomers(s);
    reveal(s);
    // 들어선 직후에는 주변 5×5를 밝혀 방향을 잡게 한다
    const R0 = run(s);
    for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
      const x = p.x + dx, y = p.y + dy;
      if (x >= 0 && y >= 0 && x < map.w && y < map.h) R0.revealed[y * map.w + x] = 1;
    }
  }
  const run = (s) => s.exp.runs[s.exp.floor];
  const curMap = (s) => genFloor(s.exp.floor);
  function sightRange(s) { return T.sightBase + stats(s).sight + run(s).lamp; }
  function doorOpen(s, floor, x, y) { return !!(s.world.doors[floor] && s.world.doors[floor][key(x, y)]); }
  function isWall(s, x, y) { return tileCh(curMap(s), x, y) === '#'; }
  function reveal(s) {
    const map = curMap(s);
    const R = run(s);
    const { x, y } = s.exp;
    const mark = (tx, ty) => { if (tx >= 0 && ty >= 0 && tx < map.w && ty < map.h) R.revealed[ty * map.w + tx] = 1; };
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) mark(x + dx, y + dy);
    const range = sightRange(s);
    for (const [dx, dy] of DIRS) {
      for (let k = 1; k <= range; k++) {
        const tx = x + dx * k, ty = y + dy * k;
        mark(tx, ty);
        const ch = tileCh(map, tx, ty);
        if (ch === '#' || (ch === 'D' && !doorOpen(s, s.exp.floor, tx, ty))) break;
        // 통로 옆 벽도 살짝 보이게
        mark(tx + dy, ty + dx); mark(tx - dy, ty - dx);
      }
    }
  }
  function isRevealed(s, x, y) { const map = curMap(s); return !!run(s).revealed[y * map.w + x]; }

  // 칸 정보(렌더링·이동 공용)
  function tileState(s, x, y) {
    const map = curMap(s);
    const R = run(s);
    const ch = tileCh(map, x, y);
    const k = key(x, y);
    const o = { ch, kind: 'floor', walk: true };
    switch (ch) {
      case '#': o.kind = 'wall'; o.walk = false; break;
      case 'S': o.kind = 'up'; break;
      case '>': o.kind = 'down'; break;
      case 'D': if (doorOpen(s, s.exp.floor, x, y)) o.kind = 'doorOpen'; else { o.kind = 'door'; o.walk = false; } break;
      case 'M': if (!R.defeated[k]) { o.kind = 'monster'; o.enemy = R.mtype[k]; } break;
      case 'B': if (!s.flags.bossDefeated) { o.kind = 'boss'; o.enemy = D.FLOORS[s.exp.floor].boss; } else o.kind = 'altar'; break;
      case 'C': o.kind = R.opened[k] ? 'chestOpen' : 'chest'; break;
      case 'L': o.kind = R.opened[k] ? 'chestOpen' : 'lockedChest'; break;
      case 'X': o.kind = R.opened[k] ? 'chestOpen' : 'chest'; o.mimic = !R.opened[k]; break;
      case 'K': o.kind = R.used[k] ? 'floor' : 'key'; break;
      case 'F': o.kind = R.used[k] ? 'fountainDry' : 'fountain'; break;
      case '?': o.kind = R.used[k] ? 'floor' : 'event'; break;
      case 'T': o.kind = R.used[k] ? 'trapSprung' : stats(s).trapSight ? 'trapSeen' : 'floor'; o.trap = !R.used[k]; break;
      case 'P': o.kind = R.used[k] ? 'puzzleDone' : 'puzzle'; break;
      case '$': o.kind = 'merchant'; break;
      default:
        if (/[a-f]/.test(ch)) {
          const q = markerQuest(s, ch);
          o.kind = q ? 'quest' : 'floor';
          o.quest = q ? q.id : null;
        }
    }
    return o;
  }
  // 이 표식을 쓰는 진행 중 의뢰
  function markerQuest(s, ch) {
    const q = D.QUESTS.find((qq) => qq.objective.marker === ch && qq.objective.floor === s.exp.floor);
    if (!q) return null;
    return s.quests[q.id].status === 'active' ? q : null;
  }

  // 한 칸 이동. 반환: 이동 후 일어난 사건(없으면 null)
  function stepInto(s, nx, ny) {
    const map = curMap(s);
    const R = run(s);
    if (Math.abs(nx - s.exp.x) + Math.abs(ny - s.exp.y) !== 1) return { type: 'blocked' };
    const ts = tileState(s, nx, ny);
    const k = key(nx, ny);
    if (ts.kind === 'wall') return { type: 'blocked' };
    if (ts.kind === 'door') return { type: 'door', x: nx, y: ny };
    if (ts.kind === 'monster') return { type: 'battle', enemy: ts.enemy, x: nx, y: ny, fixed: true };
    if (ts.kind === 'boss') return { type: 'boss', enemy: ts.enemy, x: nx, y: ny };
    // 이동
    s.exp.x = nx; s.exp.y = ny;
    s.exp.steps += 1;
    s.exp.sinceBattle += 1;
    reveal(s);
    const out = [];
    // 필드 독
    if (s.player.status.poison > 0) {
      s.exp.poisonStep += 1;
      if (s.exp.poisonStep >= T.poisonStepEvery) {
        s.exp.poisonStep = 0;
        const dmg = Math.max(1, Math.round(stats(s).maxHp * T.poisonPct));
        s.player.hp = Math.max(1, s.player.hp - dmg);
        s.player.status.poison -= 1;
        out.push({ type: 'poisonTick', dmg, cured: s.player.status.poison <= 0 });
      }
    }
    let ev = null;
    switch (ts.kind) {
      case 'up': ev = { type: 'up' }; break;
      case 'down': ev = { type: 'down' }; break;
      case 'chest': ev = ts.mimic ? { type: 'mimic', x: nx, y: ny } : { type: 'chest', x: nx, y: ny, treasure: !!(map.treasure && map.treasure.x === nx && map.treasure.y === ny) }; break;
      case 'lockedChest': ev = { type: 'lockedChest', x: nx, y: ny }; break;
      case 'key': R.used[k] = 1; addItem(s, 'key', 1); ev = { type: 'key' }; break;
      case 'fountain': ev = { type: 'fountain', x: nx, y: ny }; break;
      case 'event': ev = { type: 'event', ev: R.etype[k], x: nx, y: ny }; break;
      case 'puzzle': ev = { type: 'puzzle', x: nx, y: ny }; break;
      case 'merchant': ev = { type: 'merchant' }; break;
      case 'quest': ev = { type: 'quest', qid: ts.quest, x: nx, y: ny }; break;
      default:
        if (ts.trap) {
          R.used[k] = 1;
          if (stats(s).trapSight) ev = { type: 'trapAvoided' };
          else ev = springTrap(s);
        }
    }
    if (!ev && canEncounter(s)) {
      if (rand() < T.encounterRate) ev = { type: 'battle', enemy: weighted(enemyTable(s.exp.floor)), fixed: false };
    }
    if (ev) out.push(ev);
    return out.length ? (out.length === 1 ? out[0] : { type: 'multi', list: out }) : null;
  }
  function canEncounter(s) {
    if (s.exp.sinceBattle < T.encounterGrace) return false;
    const map = curMap(s);
    const d = Math.abs(s.exp.x - map.start.x) + Math.abs(s.exp.y - map.start.y);
    return d > T.startSafeRadius;
  }
  function springTrap(s) {
    const st = stats(s);
    if (rand() < 0.5) {
      const dmg = Math.max(2, Math.round(st.maxHp * 0.08));
      s.player.hp = Math.max(1, s.player.hp - dmg);
      return { type: 'trap', kind: 'pit', dmg };
    }
    s.player.status.poison = Math.max(s.player.status.poison, T.poisonTicks);
    return { type: 'trap', kind: 'poison' };
  }
  function markUsed(s, x, y) { run(s).used[key(x, y)] = 1; }
  function markOpened(s, x, y) { run(s).opened[key(x, y)] = 1; }

  function openDoor(s, x, y) {
    if (!removeItem(s, 'key', 1)) return { ok: false, reason: '녹슨 열쇠가 필요하다.' };
    const f = s.exp.floor;
    s.world.doors[f] = s.world.doors[f] || {};
    s.world.doors[f][key(x, y)] = true;
    reveal(s);
    return { ok: true };
  }
  function chestLoot(s, treasure) {
    const f = s.exp.floor;
    const loot = { silver: 0, items: {}, antiques: 0 };
    if (treasure) {
      loot.silver = 12 + f * 6;
      loot.antiques = 1;
    } else if (rand() < T.chestAntiqueChance[f]) {
      loot.antiques = 1;
    } else if (rand() < 0.5) {
      loot.silver = randInt(5, 12) + f * 4;
    } else {
      const table = [['hp_potion', 30], ['mp_potion', 15], ['herb', 12], ['salt', 10], ['lamp_oil', 10], ['smoke', 8], ['firecracker', 7], ['key', 5]];
      if (f >= 2 && f <= 3) table.push(['dew', 10]);
      if (f >= 4) table.push(['sand', 12], ['big_potion', 8]);
      const id = weighted(table);
      loot.items[id] = 1;
    }
    return applyLoot(s, loot);
  }
  function applyLoot(s, loot) {
    s.silver += loot.silver || 0;
    for (const id of Object.keys(loot.items || {})) addItem(s, id, loot.items[id]);
    const ants = [];
    for (let i = 0; i < (loot.antiques || 0); i++) ants.push(addCursedAntique(s, s.exp ? s.exp.floor : 1));
    loot.antiqueList = ants;
    return loot;
  }
  function openChest(s, x, y, treasure) { markOpened(s, x, y); return chestLoot(s, treasure); }
  function openLockedChest(s, x, y) {
    if (!removeItem(s, 'key', 1)) return { ok: false, reason: '녹슨 열쇠가 필요하다.' };
    markOpened(s, x, y);
    return { ok: true, loot: applyLoot(s, { silver: 15 + s.exp.floor * 6, items: {}, antiques: 1 }) };
  }
  function useFountain(s, x, y) {
    markUsed(s, x, y);
    const st = stats(s);
    const hp = Math.round(st.maxHp * 0.4), mp = Math.round(st.maxMp * 0.4);
    s.player.hp = Math.min(st.maxHp, s.player.hp + hp);
    s.player.mp = Math.min(st.maxMp, s.player.mp + mp);
    return { hp, mp };
  }
  function pickQuiz(s) {
    const pool = D.QUIZ.map((q, i) => i).filter((i) => !s.lastQuiz.includes(i));
    const i = pick(pool.length ? pool : D.QUIZ.map((q, i2) => i2));
    s.lastQuiz = [...s.lastQuiz.slice(-6), i];
    return i;
  }
  function answerQuiz(s, i, choice) {
    const q = D.QUIZ[i];
    if (choice === q.c) {
      const silver = 10 + s.exp.floor * 3;
      s.silver += silver;
      s.stats.quizCorrect += 1;
      return { correct: true, silver };
    }
    const dmg = Math.max(3, Math.round(stats(s).maxHp * 0.06));
    s.player.hp = Math.max(1, s.player.hp - dmg);
    s.stats.quizWrong += 1;
    return { correct: false, dmg, answer: q.a[q.c] };
  }
  function gamble(s) {
    if (s.silver < T.gambleCost) return { ok: false, reason: `은화 ${T.gambleCost}개가 필요하다.` };
    s.silver -= T.gambleCost;
    s.stats.gambles += 1;
    const out = weighted([['silver', 40], ['item', 20], ['nothing', 25], ['curse', 15]]);
    if (out === 'silver') { s.silver += 45; return { ok: true, out, silver: 45 }; }
    if (out === 'item') { const id = weighted([['hp_potion', 4], ['mp_potion', 3], ['salt', 2], ['firecracker', 2], ['key', 1]]); addItem(s, id, 1); return { ok: true, out, item: id }; }
    if (out === 'curse') { s.player.status.curseNext = T.curseTurns; return { ok: true, out }; }
    return { ok: true, out };
  }
  function treasureFind(s) { const silver = randInt(6, 14) + s.exp.floor * 4; s.silver += silver; return { silver }; }
  // 소문: 목표(진행 중 표식 > 계단/보스) 주변을 밝혀준다
  function rumor(s) {
    const map = curMap(s);
    const tgt = hintTarget(s);
    if (tgt) {
      const R = run(s);
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const x = tgt.x + dx, y = tgt.y + dy;
        if (x >= 0 && y >= 0 && x < map.w && y < map.h) R.revealed[y * map.w + x] = 1;
      }
    }
    return { text: pick(D.LINES.rumors), target: tgt };
  }
  function hintTarget(s) {
    const map = curMap(s);
    for (const m of Object.keys(map.markers)) {
      const q = markerQuest(s, m);
      if (q) return { x: map.markers[m].x, y: map.markers[m].y, label: q.objective.place };
    }
    if (D.FLOORS[s.exp.floor].down) return { x: map.goal.x, y: map.goal.y, label: '아래층 계단' };
    if (!s.flags.bossDefeated) return { x: map.goal.x, y: map.goal.y, label: '아주 짙은 그림자' };
    return null;
  }
  function pathLen(s, tx, ty) { const p = findPath(s, tx, ty, true); return p ? p.length : null; }
  function petHint(s) {
    const R = run(s);
    if (R.hints <= 0) return { ok: false, reason: '먹물이 하품을 한다. (이번 층에서는 더 못 맡는다)' };
    const tgt = hintTarget(s);
    if (!tgt) return { ok: false, reason: '먹물이 갸웃한다. 더 찾을 게 없는 모양이다.' };
    R.hints -= 1;
    const dx = tgt.x - s.exp.x, dy = tgt.y - s.exp.y;
    const len = pathLen(s, tgt.x, tgt.y);
    const steps = len == null ? Math.abs(dx) + Math.abs(dy) : len;
    const ang = Math.atan2(dy, dx);
    const names = ['오른쪽', '오른쪽 아래', '아래쪽', '왼쪽 아래', '왼쪽', '왼쪽 위', '위쪽', '오른쪽 위'];
    const idx = ((Math.round(ang / (Math.PI / 4)) % 8) + 8) % 8;
    const far = steps <= 6 ? '가까이' : steps <= 14 ? '조금 멀리' : '아주 멀리';
    return { ok: true, dir: names[idx], far, label: tgt.label, target: tgt, left: R.hints, angle: ang };
  }

  // 길 찾기 (밝혀진 칸만). ignoreFog=true면 전체 지도 기준.
  function passable(s, x, y, ignoreFog) {
    if (!ignoreFog && !isRevealed(s, x, y)) return false;
    const ts = tileState(s, x, y);
    return ts.walk;
  }
  // 몬스터를 피해 가는 길을 먼저 찾고, 없으면 몬스터가 막은 길(그 칸에서 전투)을 쓴다
  function findPath(s, tx, ty, ignoreFog) {
    return bfsPath(s, tx, ty, ignoreFog, false) || bfsPath(s, tx, ty, ignoreFog, true);
  }
  function bfsPath(s, tx, ty, ignoreFog, allowMonsters) {
    const map = curMap(s);
    const sx = s.exp.x, sy = s.exp.y;
    if (sx === tx && sy === ty) return [];
    const prev = new Map();
    const q = [[sx, sy]];
    prev.set(key(sx, sy), null);
    while (q.length) {
      const [x, y] = q.shift();
      for (const [dx, dy] of DIRS) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= map.w || ny >= map.h) continue;
        const kk = key(nx, ny);
        if (prev.has(kk)) continue;
        const isTarget = nx === tx && ny === ty;
        const ts = tileState(s, nx, ny);
        const blocking = ts.kind === 'door' || (!allowMonsters && (ts.kind === 'monster' || ts.kind === 'boss'));
        const fightable = allowMonsters && (ts.kind === 'monster' || ts.kind === 'boss');
        if (!isTarget && (blocking || (!fightable && !passable(s, nx, ny, ignoreFog)))) continue;
        if (!isTarget && fightable && !ignoreFog && !isRevealed(s, nx, ny)) continue;
        if (isTarget && !ignoreFog && !isRevealed(s, nx, ny)) continue;
        if (isTarget && ts.kind === 'wall') continue;
        prev.set(kk, [x, y]);
        if (isTarget) {
          const path = [];
          let cur = [nx, ny];
          while (cur && !(cur[0] === sx && cur[1] === sy)) { path.unshift(cur); cur = prev.get(key(cur[0], cur[1])); }
          return path;
        }
        q.push([nx, ny]);
      }
    }
    return null;
  }

  function useItemField(s, id) {
    const it = D.ITEMS[id];
    if (!it || !it.field || count(s, id) < 1) return { ok: false, reason: '지금은 쓸 수 없다.' };
    const st = stats(s);
    const u = it.use || {};
    if (u.heal) { if (s.player.hp >= st.maxHp) return { ok: false, reason: '체력이 이미 가득하다.' }; const v = Math.round(u.heal * (1 + st.potionBoost)); s.player.hp = Math.min(st.maxHp, s.player.hp + v); removeItem(s, id); return { ok: true, text: `체력이 ${v} 회복되었다.` }; }
    if (u.mp) { if (s.player.mp >= st.maxMp) return { ok: false, reason: '마력이 이미 가득하다.' }; const v = Math.round(u.mp * (1 + st.potionBoost)); s.player.mp = Math.min(st.maxMp, s.player.mp + v); removeItem(s, id); return { ok: true, text: `마력이 ${v} 회복되었다.` }; }
    if (u.cure === 'poison') { if (!s.player.status.poison) return { ok: false, reason: '독에 걸려 있지 않다.' }; s.player.status.poison = 0; removeItem(s, id); return { ok: true, text: '독이 말끔히 나았다.' }; }
    if (u.returnHome) { if (!s.exp) return { ok: false, reason: '봉인 창고 안에서만 쓸 수 있다.' }; removeItem(s, id); return { ok: true, returnHome: true, text: '깃털이 루미를 감싸 학교로 날아올랐다.' }; }
    if (u.sight) { if (!s.exp) return { ok: false, reason: '봉인 창고 안에서만 쓸 수 있다.' }; removeItem(s, id); run(s).lamp += u.sight; reveal(s); return { ok: true, text: '등불이 환해졌다. 시야가 넓어졌다.' }; }
    return { ok: false, reason: '지금은 쓸 수 없다.' };
  }

  function returnHome(s) {
    s.exp = null;
    s.day += 1;
    refreshCustomers(s);
  }
  // 부실 침대: 하루가 지나고 마력은 가득, 체력은 일부 회복 (완전 회복은 양호실)
  function sleepDay(s) {
    const st = stats(s);
    const hp = Math.round(st.maxHp * T.sleepHealPct);
    s.player.hp = Math.min(st.maxHp, s.player.hp + hp);
    s.player.mp = st.maxMp;
    s.day += 1;
    refreshCustomers(s);
    return { hp };
  }
  function applyDefeat(s) {
    const lost = Math.floor(s.silver * T.defeatSilverLoss);
    s.silver -= lost;
    const st = stats(s);
    s.player.hp = Math.max(1, Math.round(st.maxHp * 0.5));
    s.player.mp = Math.round(st.maxMp * 0.5);
    s.player.status.poison = 0;
    s.player.status.curseNext = 0;
    s.stats.defeats += 1;
    returnHome(s);
    return { lost };
  }

  // ───────── 이상한 방(촛불 퍼즐) ─────────
  function puzzleNew(presses) {
    const g = new Array(9).fill(1);
    let done = 0, guard = 0;
    while ((done < presses || g.every(Boolean)) && guard++ < 50) { puzzleToggle(g, randInt(0, 8)); done++; }
    if (g.every(Boolean)) puzzleToggle(g, 4);
    return g;
  }
  function puzzleToggle(g, i) {
    const x = i % 3, y = Math.floor(i / 3);
    const flip = (xx, yy) => { if (xx >= 0 && yy >= 0 && xx < 3 && yy < 3) g[yy * 3 + xx] = g[yy * 3 + xx] ? 0 : 1; };
    flip(x, y); flip(x + 1, y); flip(x - 1, y); flip(x, y + 1); flip(x, y - 1);
    return g;
  }
  const puzzleSolved = (g) => g.every(Boolean);
  function puzzleReward(s, x, y) {
    markUsed(s, x, y);
    s.stats.puzzles += 1;
    return applyLoot(s, { silver: 12 + s.exp.floor * 5, items: {}, antiques: 1 });
  }

  // ───────── 전투 ─────────
  function createBattle(s, enemyId, ctx) {
    const E = D.ENEMIES[enemyId];
    const st = stats(s);
    const b = {
      enemyId, name: E.name, maxHp: E.hp, hp: E.hp, atk: E.atk, def: E.def,
      traits: E.traits || {}, weak: E.weak || null, resist: E.resist || null,
      boss: !!E.boss, elite: !!E.elite, noFlee: !!E.noFlee,
      charging: false, frozen: 0, sleep: 0, burn: 0, burnDmg: 0, shield: 0,
      turn: 0, chargeCount: 0, scriptIdx: 0, phase: 1, curtainUsed: false, shieldUsed: false,
      pcurse: 0, ctx: ctx || {}, over: false, result: null, rewards: null,
    };
    const intro = [];
    if (s.player.status.curseNext > 0) {
      b.pcurse = s.player.status.curseNext;
      s.player.status.curseNext = 0;
      intro.push({ t: 'log', text: '항아리의 저주 연기가 아직 남아 있다… (공격력 감소)' });
    }
    if (!b.boss && !b.elite && st.sleepChance > 0 && rand() < st.sleepChance) {
      b.sleep = 1;
      intro.push({ t: 'log', text: `오르골 자장가에 ${b.name}이(가) 꾸벅꾸벅 존다.` });
    }
    s.stats.battles += 1;
    b.intro = intro;
    return b;
  }
  function elemMult(b, elem) {
    if (!elem) return { m: 1 };
    if (b.weak === elem) return { m: 1.3, weak: true };
    if (b.resist === elem) return { m: 0.5, resist: true };
    return { m: 1 };
  }
  function playerAtk(s, b) {
    const st = stats(s);
    return b.pcurse > 0 ? st.atk * T.curseMult : st.atk;
  }
  function dealToEnemy(s, b, raw, ev) {
    let dmg = raw;
    if (b.shield > 0) dmg = Math.max(1, Math.round(dmg * T.shieldMult));
    dmg = Math.max(1, Math.round(dmg));
    b.hp = Math.max(0, b.hp - dmg);
    ev.push({ t: 'dmg', target: 'enemy', amount: dmg, shielded: b.shield > 0 });
    return dmg;
  }
  function noteWeak(s, b, info, ev) {
    if (info.weak) {
      s.stats.weakHits += 1;
      const k = s.known[b.enemyId] || (s.known[b.enemyId] = {});
      if (!k.weak) { k.weak = true; ev.push({ t: 'log', text: `약점 발견! ${b.name}은(는) ${D.ELEMENTS[b.weak].name}에 약하다.` }); }
      ev.push({ t: 'weak' });
    }
    if (info.resist) {
      const k = s.known[b.enemyId] || (s.known[b.enemyId] = {});
      if (!k.resist) { k.resist = true; ev.push({ t: 'log', text: `${b.name}은(는) ${D.ELEMENTS[b.resist].name}을(를) 잘 버틴다.` }); }
    }
  }

  // action: {type:'attack'} | {type:'spell', id} | {type:'item', id} | {type:'flee'}
  function canAct(s, b, action) {
    const st = stats(s);
    if (action.type === 'spell') {
      const sp = D.SPELLS[action.id];
      if (!sp || !s.spells.includes(action.id)) return { ok: false, reason: '아직 배우지 못한 마법이다.' };
      if (s.player.mp < sp.mp) return { ok: false, reason: '마력이 부족하다.' };
      if (sp.kind === 'heal' && s.player.hp >= st.maxHp) return { ok: false, reason: '체력이 이미 가득하다.' };
    }
    if (action.type === 'item') {
      const it = D.ITEMS[action.id];
      if (!it || !it.battle || count(s, action.id) < 1) return { ok: false, reason: '쓸 수 없는 물건이다.' };
      const u = it.use || {};
      if (u.escape && b.noFlee) return { ok: false, reason: '이 상대에게는 연막이 통하지 않는다.' };
      if (u.heal && s.player.hp >= st.maxHp) return { ok: false, reason: '체력이 이미 가득하다.' };
      if (u.mp && s.player.mp >= st.maxMp) return { ok: false, reason: '마력이 이미 가득하다.' };
      if (u.cure === 'poison' && !s.player.status.poison) return { ok: false, reason: '독에 걸려 있지 않다.' };
      if (u.cure === 'curse' && !b.pcurse) return { ok: false, reason: '저주에 걸려 있지 않다.' };
    }
    if (action.type === 'flee' && b.noFlee) return { ok: false, reason: '도망칠 수 없다!' };
    return { ok: true };
  }

  function playerAction(s, b, action) {
    const ev = [];
    if (b.over) return ev;
    const chk = canAct(s, b, action);
    if (!chk.ok) { ev.push({ t: 'deny', text: chk.reason }); return ev; }
    const st = stats(s);
    const atk = playerAtk(s, b);
    if (action.type === 'attack') {
      ev.push({ t: 'act', who: 'player', kind: 'attack' });
      if (b.traits.evasive && rand() < b.traits.evasive) {
        ev.push({ t: 'miss', target: 'enemy' });
        ev.push({ t: 'log', text: `${b.name}이(가) 휙 피했다!` });
      } else {
        const crit = rand() < T.critBase + st.crit;
        let raw = atk * uniform(0.9, 1.1) - b.def * 0.6;
        if (crit) raw *= T.critMult;
        const dmg = dealToEnemy(s, b, Math.max(1, raw), ev);
        if (crit) ev.push({ t: 'crit' });
        ev.push({ t: 'log', text: `${crit ? '치명타! ' : ''}지팡이로 때렸다. ${b.name}에게 ${dmg}의 피해.` });
      }
    } else if (action.type === 'spell') {
      const sp = D.SPELLS[action.id];
      s.player.mp -= sp.mp;
      ev.push({ t: 'act', who: 'player', kind: 'spell', spell: sp.id, elem: sp.elem });
      if (sp.kind === 'heal') {
        const v = Math.round(st.maxHp * 0.3 + 8);
        s.player.hp = Math.min(st.maxHp, s.player.hp + v);
        ev.push({ t: 'heal', target: 'player', amount: v });
        ev.push({ t: 'log', text: `치유 마법! 체력이 ${v} 회복되었다.` });
      } else {
        const info = elemMult(b, sp.elem);
        const boost = 1 + (sp.elem ? st[sp.elem + 'Boost'] || 0 : 0);
        let raw = atk * sp.power * uniform(0.92, 1.08) * info.m * boost - b.def * 0.3;
        if (sp.elem === 'light' && b.shield > 0) { b.shield = 0; ev.push({ t: 'shieldBreak' }); ev.push({ t: 'log', text: '정화의 빛이 그림자 방패를 깨뜨렸다!' }); }
        const dmg = dealToEnemy(s, b, Math.max(1, raw), ev);
        ev.push({ t: 'log', text: `${sp.name}! ${b.name}에게 ${dmg}의 ${sp.elem ? D.ELEMENTS[sp.elem].name + ' ' : ''}피해.${info.weak ? ' (약점!)' : info.resist ? ' (잘 안 든다…)' : ''}` });
        noteWeak(s, b, info, ev);
        if (b.hp > 0) {
          if (sp.elem === 'ice') {
            if (b.charging) {
              b.charging = false;
              const big = b.boss || b.elite;
              if (!big) b.frozen = 1;
              ev.push({ t: 'status', target: 'enemy', status: 'interrupt' });
              ev.push({ t: 'log', text: `얼음 가시가 모으던 기를 흩어놓았다!${big ? '' : ' 꽁꽁 얼었다.'}` });
            } else if (!b.boss && !b.elite && rand() < T.freezeChance) {
              b.frozen = 1;
              ev.push({ t: 'status', target: 'enemy', status: 'freeze' });
              ev.push({ t: 'log', text: `${b.name}이(가) 꽁꽁 얼어붙었다!` });
            }
          }
          if (sp.elem === 'fire' && rand() < T.burnChance) {
            b.burn = T.burnTurns;
            b.burnDmg = Math.max(2, Math.round(atk * 0.25));
            ev.push({ t: 'status', target: 'enemy', status: 'burn' });
            ev.push({ t: 'log', text: `${b.name}에게 불이 붙었다!` });
          }
        }
      }
    } else if (action.type === 'item') {
      const it = D.ITEMS[action.id];
      const u = it.use;
      removeItem(s, action.id, 1);
      ev.push({ t: 'act', who: 'player', kind: 'item', item: action.id });
      if (u.heal) { const v = Math.round(u.heal * (1 + st.potionBoost)); s.player.hp = Math.min(st.maxHp, s.player.hp + v); ev.push({ t: 'heal', target: 'player', amount: v }); ev.push({ t: 'log', text: `${it.name}을(를) 마셨다. 체력 +${v}` }); }
      if (u.mp) { const v = Math.round(u.mp * (1 + st.potionBoost)); s.player.mp = Math.min(st.maxMp, s.player.mp + v); ev.push({ t: 'mp', amount: v }); ev.push({ t: 'log', text: `${it.name}을(를) 마셨다. 마력 +${v}` }); }
      if (u.cure === 'poison') { s.player.status.poison = 0; ev.push({ t: 'log', text: '독이 나았다.' }); }
      if (u.cure === 'curse') { b.pcurse = 0; ev.push({ t: 'log', text: '정화 소금을 뿌렸다. 저주가 풀렸다!' }); }
      if (u.escape) { b.over = true; b.result = 'flee'; ev.push({ t: 'log', text: '연막 구슬을 던졌다! 연기 속으로 도망쳤다.' }); ev.push({ t: 'flee' }); return ev; }
      if (u.damage) {
        const info = elemMult(b, u.elem);
        const dmg = dealToEnemy(s, b, u.damage * info.m, ev);
        ev.push({ t: 'log', text: `${it.name}이 펑! ${b.name}에게 ${dmg}의 피해.${info.weak ? ' (약점!)' : ''}` });
        noteWeak(s, b, info, ev);
      }
    } else if (action.type === 'flee') {
      const chance = clamp(T.fleeBase + st.flee, 0, 0.95);
      if (rand() < chance) {
        b.over = true; b.result = 'flee';
        ev.push({ t: 'log', text: '무사히 도망쳤다!' });
        ev.push({ t: 'flee' });
        return ev;
      }
      ev.push({ t: 'log', text: '도망치지 못했다!' });
    }
    if (b.hp <= 0) { finishWin(s, b, ev); return ev; }
    // 먹물의 도움
    if (rand() < T.petBase + st.petBoost) {
      const dmg = dealToEnemy(s, b, 3 + s.player.lv * 2, ev);
      ev.push({ t: 'pet' });
      ev.push({ t: 'log', text: `먹물의 냥냥펀치! ${dmg}의 피해.` });
      if (b.hp <= 0) { finishWin(s, b, ev); return ev; }
    }
    enemyTurn(s, b, ev);
    if (b.over) return ev;
    endRound(s, b, ev);
    return ev;
  }

  function enemyHit(s, b, mult, ev, label) {
    const st = stats(s);
    const raw = b.atk * uniform(0.85, 1.15) * mult - st.def * 0.6;
    const dmg = Math.max(1, Math.round(raw));
    s.player.hp = Math.max(0, s.player.hp - dmg);
    ev.push({ t: 'dmg', target: 'player', amount: dmg, big: mult > 1 });
    ev.push({ t: 'log', text: `${label || b.name + '의 공격!'} ${dmg}의 피해를 입었다.` });
    if (b.traits.drain) {
      const heal = Math.round(dmg * b.traits.drain);
      b.hp = Math.min(b.maxHp, b.hp + heal);
      ev.push({ t: 'heal', target: 'enemy', amount: heal });
    }
    return dmg;
  }
  function enemyCurse(s, b, ev) {
    b.pcurse = T.curseTurns;
    ev.push({ t: 'act', who: 'enemy', kind: 'curse' });
    ev.push({ t: 'status', target: 'player', status: 'curse' });
    ev.push({ t: 'log', text: `${b.name}의 저주! 공격력이 떨어졌다. (정화 소금으로 풀 수 있다)` });
  }
  function enemyTurn(s, b, ev) {
    if (b.sleep > 0) { b.sleep -= 1; b.charging = false; ev.push({ t: 'log', text: `${b.name}은(는) 쿨쿨 자고 있다.` }); return checkLose(s, b, ev); }
    if (b.frozen > 0) { b.frozen -= 1; b.charging = false; ev.push({ t: 'log', text: `${b.name}은(는) 얼어서 움직이지 못한다.` }); return checkLose(s, b, ev); }
    ev.push({ t: 'act', who: 'enemy', kind: 'attack' });
    if (b.charging) {
      b.charging = false;
      const mult = b.boss ? T.bossChargeMult : T.chargeMult;
      const label = b.enemyId === 'nocturne' ? '녹턴의 「자정의 종」!' : b.enemyId === 'director' ? '깔깔 극장장의 「웃음 폭탄」!' : `${b.name}이(가) 모은 기를 터뜨렸다!`;
      enemyHit(s, b, mult, ev, label);
      return checkLose(s, b, ev);
    }
    const E = D.ENEMIES[b.enemyId];
    if (E.script) {
      if (E.shieldAt && !b.shieldUsed && b.hp <= b.maxHp * E.shieldAt) {
        b.shieldUsed = true; b.shield = T.shieldTurns; b.phase = 2; b.scriptIdx = 0;
        ev.push({ t: 'shield' });
        ev.push({ t: 'log', text: '녹턴이 그림자 방패를 둘렀다! 받는 피해가 크게 줄어든다. (빛으로 깰 수 있다)' });
        return checkLose(s, b, ev);
      }
      if (E.curtainCall && !b.curtainUsed && b.hp <= b.maxHp * 0.3) {
        b.curtainUsed = true;
        const heal = Math.round(b.maxHp * 0.2);
        b.hp = Math.min(b.maxHp, b.hp + heal);
        ev.push({ t: 'heal', target: 'enemy', amount: heal });
        ev.push({ t: 'log', text: `"커튼콜!" 깔깔 극장장이 박수를 받으며 체력을 ${heal} 회복했다.` });
        return checkLose(s, b, ev);
      }
      const script = b.phase === 2 && E.script2 ? E.script2 : E.script;
      const act = script[b.scriptIdx % script.length];
      b.scriptIdx += 1;
      if (act === 'charge') { b.charging = true; ev.push({ t: 'charge' }); ev.push({ t: 'log', text: `${b.name}이(가) 기를 모으기 시작했다! (얼음 가시로 끊을 수 있다)` }); return checkLose(s, b, ev); }
      if (act === 'curse' && b.pcurse <= 0) { enemyCurse(s, b, ev); return checkLose(s, b, ev); }
      enemyHit(s, b, 1, ev);
      return checkLose(s, b, ev);
    }
    if (b.traits.charger) {
      b.chargeCount += 1;
      if (b.chargeCount % 3 === 0) { b.charging = true; ev.push({ t: 'charge' }); ev.push({ t: 'log', text: `${b.name}이(가) 기를 모으고 있다! (얼음 가시로 끊을 수 있다)` }); return checkLose(s, b, ev); }
    }
    if (b.traits.curser && b.pcurse <= 0 && rand() < b.traits.curser) { enemyCurse(s, b, ev); return checkLose(s, b, ev); }
    if (b.traits.poisoner && !s.player.status.poison && rand() < b.traits.poisoner) {
      enemyHit(s, b, 0.6, ev, `${b.name}의 독 포자!`);
      s.player.status.poison = T.poisonTicks;
      ev.push({ t: 'status', target: 'player', status: 'poison' });
      ev.push({ t: 'log', text: '독에 걸렸다! (해독 허브로 치료)' });
      return checkLose(s, b, ev);
    }
    enemyHit(s, b, 1, ev);
    return checkLose(s, b, ev);
  }
  function checkLose(s, b, ev) {
    if (s.player.hp <= 0) {
      b.over = true; b.result = 'lose';
      ev.push({ t: 'lose' });
      ev.push({ t: 'log', text: '눈앞이 캄캄해졌다…' });
    }
  }
  function endRound(s, b, ev) {
    const st = stats(s);
    if (s.player.status.poison > 0) {
      const dmg = Math.max(1, Math.round(st.maxHp * T.poisonPct));
      s.player.hp = Math.max(1, s.player.hp - dmg);
      s.player.status.poison -= 1;
      ev.push({ t: 'dmg', target: 'player', amount: dmg, poison: true });
      ev.push({ t: 'log', text: `독이 퍼진다. ${dmg}의 피해.` });
    }
    if (b.burn > 0 && b.hp > 0) {
      b.burn -= 1;
      const dmg = dealToEnemy(s, b, b.burnDmg, ev);
      ev.push({ t: 'log', text: `${b.name}이(가) 화상으로 ${dmg}의 피해를 입었다.` });
      if (b.hp <= 0) { finishWin(s, b, ev); return; }
    }
    if (b.traits.regen && b.hp > 0 && b.hp < b.maxHp) {
      const heal = Math.max(1, Math.round(b.maxHp * b.traits.regen));
      b.hp = Math.min(b.maxHp, b.hp + heal);
      ev.push({ t: 'heal', target: 'enemy', amount: heal });
      ev.push({ t: 'log', text: `${b.name}이(가) 촛농을 모아 ${heal} 회복했다.` });
    }
    if (b.pcurse > 0) { b.pcurse -= 1; if (b.pcurse === 0) ev.push({ t: 'log', text: '저주가 풀렸다.' }); }
    if (b.shield > 0) { b.shield -= 1; if (b.shield === 0) ev.push({ t: 'log', text: '그림자 방패가 사라졌다.' }); }
    if (st.mpRegen > 0 && s.player.mp < st.maxMp) { s.player.mp = Math.min(st.maxMp, s.player.mp + st.mpRegen); }
    b.turn += 1;
  }
  function finishWin(s, b, ev) {
    b.over = true; b.result = 'win';
    const E = D.ENEMIES[b.enemyId];
    const st = stats(s);
    const silver = Math.round(randInt(E.silver[0], E.silver[1]) * (1 + st.silverBoost));
    const items = {};
    for (const [id, p] of E.drops || []) if (rand() < p) items[id] = (items[id] || 0) + 1;
    const floor = s.exp ? s.exp.floor : 1;
    const ants = [];
    if (E.antiqueDrop && rand() < E.antiqueDrop) ants.push(addCursedAntique(s, floor));
    s.silver += silver;
    for (const id of Object.keys(items)) addItem(s, id, items[id]);
    s.stats.kills[b.enemyId] = (s.stats.kills[b.enemyId] || 0) + 1;
    const ups = gainExp(s, E.exp);
    if (b.enemyId === 'director') s.flags.directorDefeated = true;
    if (b.enemyId === 'nocturne') s.flags.bossDefeated = true;
    if (b.ctx.qid) completeObjective(s, b.ctx.qid);
    if (s.exp && b.ctx.fixedKey) run(s).defeated[b.ctx.fixedKey] = 1;
    b.rewards = { exp: E.exp, silver, items, antiques: ants, levelUps: ups };
    ev.push({ t: 'win', rewards: b.rewards });
    ev.push({ t: 'log', text: `${b.name}을(를) 정화했다!` });
  }

  W.rules = {
    makeRng, setRng, rand, randInt, weighted, clamp, key, describeEffect,
    newGame, newFieldState, serialize, deserialize, stats, clampVitals, knownSpells, expToNext, gainExp,
    classSpells, classOpen, canLearn, learnSpell, learnableSpells, runeSequence, sleepDay,
    count, addItem, removeItem, hasItems, pick,
    questDef, refreshCustomers, customers, activeQuests, canPurifyQuest, acceptQuest, declineQuest, completeObjective,
    purifyQuest, addCursedAntique, rollAntiqueDef, purifyFound, sellAntique, equipAntique, unequip,
    shopItems, buy, sellItem, sellPrice, infirmary, checkBadges, objectiveText, canSeeEnding,
    genFloor, tileCh, startExpedition, enterFloor, reveal, isRevealed, tileState, stepInto, findPath, sightRange,
    openDoor, openChest, openLockedChest, useFountain, pickQuiz, answerQuiz, gamble, treasureFind, rumor, petHint, hintTarget,
    markUsed, markOpened, useItemField, returnHome, applyDefeat,
    puzzleNew, puzzleToggle, puzzleSolved, puzzleReward,
    createBattle, canAct, playerAction, elemMult,
    MAP_W, MAP_H,
  };
})();
