/*
 * rules.js — 전투 규칙 (화면과 분리, DOM 사용 안 함 → Node에서도 테스트 가능)
 *
 * 상태(st) 구조
 *   st.rng          난수 상태(숫자)
 *   st.cards        { uid: { uid, id, woundOf? } }  — 모든 카드 인스턴스
 *   st.party        { witch:{hp,maxHp}, allies:{id:{id,hp,maxHp,status}}, order:[], deck:[uid] }
 *                   status: ok | down(쓰러짐) | dead(사망)
 *   st.battle       전투 중일 때만. draw/hand/discard/exhaust 는 uid 배열
 *
 * 규칙 함수는 상태를 바꾸고, 화면이 연출할 이벤트 배열을 돌려준다.
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var R = Game.Rules = {};

  function D() { return Game.DATA; }
  function copy(o) { return JSON.parse(JSON.stringify(o)); }

  // ───────── 난수 (mulberry32, 상태를 숫자로 저장 → 스냅샷 가능) ─────────
  function rnd(st) {
    var t = (st.rng = (st.rng + 0x6D2B79F5) >>> 0);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  function rint(st, n) { return Math.floor(rnd(st) * n); }
  function shuffle(st, arr) {
    for (var i = arr.length - 1; i > 0; i--) {
      var j = rint(st, i + 1); var t = arr[i]; arr[i] = arr[j]; arr[j] = t;
    }
    return arr;
  }
  R.rnd = rnd;

  // ───────── 카드 ─────────
  function newCard(st, id, extra) {
    if (!D().cards[id]) throw new Error('알 수 없는 카드: ' + id);
    var c = { uid: 'k' + (st.nextUid++), id: id };
    if (extra) for (var k in extra) c[k] = extra[k];
    st.cards[c.uid] = c;
    return c.uid;
  }
  R.def = function (st, uid) { return D().cards[st.cards[uid].id]; };
  R.cardOf = function (st, uid) { return st.cards[uid]; };

  // 카드 설명문: {dmg} {all} {draw} {self} {weaken} → 효과 수치
  R.cardText = function (id) {
    var c = D().cards[id];
    var v = {};
    (c.effects || []).forEach(function (e) {
      if (e.type === 'damage') v.dmg = e.amount;
      if (e.type === 'damageAll') v.all = e.amount;
      if (e.type === 'draw') v.draw = e.count;
      if (e.type === 'selfDamage') v.self = e.amount;
      if (e.type === 'weaken') v.weaken = e.amount;
    });
    return String(c.text || '').replace(/\{(\w+)\}/g, function (m, k) { return v[k] != null ? String(v[k]) : m; });
  };

  // ───────── 새 게임 / 파티 ─────────
  R.newGame = function (seed) {
    var d = D();
    seed = (seed == null ? Math.floor(Math.random() * 1e9) : seed) >>> 0;
    var st = { seed: seed, rng: seed || 1, nextUid: 1, cards: {}, party: null, battle: null };
    var p = st.party = {
      witch: { hp: d.party.witch.hp, maxHp: d.party.witch.hp },
      allies: {}, order: d.party.order.slice(), deck: []
    };
    p.order.forEach(function (id) {
      var a = d.party.allies[id];
      p.allies[id] = { id: id, hp: a.hp, maxHp: a.hp, status: 'ok' };
    });
    d.startingDeck.forEach(function (e) {
      for (var i = 0; i < e[1]; i++) p.deck.push(newCard(st, e[0]));
    });
    return st;
  };

  R.snapshot = function (st) { return JSON.stringify(st); };
  // 스냅샷 복원. 난수는 이어서 진행하고 뽑을 더미는 다시 섞는다(같은 손패 반복 방지).
  R.restore = function (snap, rngNow) {
    var st = JSON.parse(snap);
    if (rngNow != null) st.rng = rngNow >>> 0;
    if (st.battle) shuffle(st, st.battle.draw);
    return st;
  };

  function ally(st, id) { return st.party.allies[id]; }
  function isOk(st, who) {
    if (who === 'witch') return st.party.witch.hp > 0;
    var a = ally(st, who); return !!a && a.status === 'ok';
  }
  R.isOk = isOk;
  // 공격받을 수 있는 아군 (마녀 + 서 있는 동료)
  function hittable(st) {
    var list = [];
    if (st.party.witch.hp > 0) list.push('witch');
    st.party.order.forEach(function (id) { if (isOk(st, id)) list.push(id); });
    return list;
  }
  R.hittable = hittable;
  R.isDefeat = function (st) {
    if (st.party.witch.hp <= 0) return true;
    return !st.party.order.some(function (id) { return isOk(st, id); });
  };

  // ───────── 전투 시작 ─────────
  R.startBattle = function (st, encId) {
    var d = D(), enc = d.encounters[encId];
    var b = st.battle = {
      enc: encId, kind: enc.kind, turn: 0, phase: 'start', energy: 0,
      draw: shuffle(st, st.party.deck.slice()), hand: [], discard: [], exhaust: [],
      free: {}, enemies: [], result: null, shadow: 0, giantTriggered: false, lastPlayedIndex: -1
    };
    enc.enemies.forEach(function (e) {
      var t = d.enemies[e.type];
      b.enemies.push({
        id: e.id, type: e.type, name: t.name, hp: t.hp, maxHp: t.hp,
        immune: !!t.immune, retreatOn: t.retreatOn || null, alive: true, slot: e.slot, intent: null
      });
    });
    return [{ t: 'battleStart', enc: encId, kind: enc.kind }];
  };

  function enemy(st, id) {
    var es = st.battle.enemies;
    for (var i = 0; i < es.length; i++) if (es[i].id === id) return es[i];
    return null;
  }
  R.enemy = enemy;
  function aliveEnemies(st) { return st.battle.enemies.filter(function (e) { return e.alive; }); }
  R.aliveEnemies = aliveEnemies;

  // 손패: 보존(죽음) 카드를 가운데로
  function arrangeHand(st) {
    var b = st.battle;
    var keep = [], normal = [];
    b.hand.forEach(function (u) { (R.def(st, u).retain ? keep : normal).push(u); });
    if (!keep.length) return;
    var mid = Math.floor(normal.length / 2);
    b.hand = normal.slice(0, mid).concat(keep, normal.slice(mid));
  }

  function drawCards(st, n, scripted, ev) {
    var b = st.battle, d = D();
    for (var i = 0; i < n; i++) {
      if (b.hand.length >= d.rules.maxHand) { ev.push({ t: 'handFull' }); break; }
      if (!b.draw.length) {
        if (!b.discard.length) break;
        b.draw = shuffle(st, b.discard.slice()); b.discard = [];
        ev.push({ t: 'reshuffle', draw: b.draw.length });
      }
      var uid = null;
      if (scripted && scripted[i]) {
        for (var j = b.draw.length - 1; j >= 0; j--) {
          if (st.cards[b.draw[j]].id === scripted[i]) { uid = b.draw.splice(j, 1)[0]; break; }
        }
      }
      if (!uid) uid = b.draw.pop();
      b.hand.push(uid);
      arrangeHand(st);
      ev.push({ t: 'draw', uid: uid, hand: b.hand.slice(), drawLeft: b.draw.length });
    }
  }
  R._drawCards = drawCards;

  function addToHand(st, uid, at) {
    var b = st.battle;
    if (at != null && at >= 0 && at <= b.hand.length) b.hand.splice(at, 0, uid);
    else b.hand.push(uid);
    arrangeHand(st);
  }

  // ───────── 예고 ─────────
  function pickTarget(st) {
    var w = D().rules.targetWeights, list = hittable(st), total = 0;
    list.forEach(function (id) { total += (w[id] != null ? w[id] : 1); });
    var r = rnd(st) * total;
    for (var i = 0; i < list.length; i++) {
      r -= (w[list[i]] != null ? w[list[i]] : 1);
      if (r < 0) return list[i];
    }
    return list[list.length - 1];
  }

  function rollIntents(st) {
    var b = st.battle, enc = D().encounters[b.enc];
    b.enemies.forEach(function (e) {
      if (!e.alive) { e.intent = null; return; }
      if (b.kind === 'giant') {
        var cd = enc.countdown, idx = Math.min(b.turn, cd.length) - 1, step = cd[idx];
        e.intent = {
          kind: step.kind, label: step.label, detail: step.detail || '', value: step.value || 0,
          hitsWitch: !!step.hitsWitch, lethal: !!step.lethal, target: 'all',
          step: b.turn, total: cd.length, redirectable: false
        };
        return;
      }
      var sc = enc.scriptedIntents && enc.scriptedIntents[b.turn] && enc.scriptedIntents[b.turn][e.id];
      var value, target;
      if (sc && isOk(st, sc.target)) { value = sc.value; target = sc.target; }
      else {
        var r = enc.attackRange;
        value = r[0] + rint(st, r[1] - r[0] + 1);
        target = pickTarget(st);
      }
      e.intent = { kind: 'attack', value: value, reduce: 0, halve: false, target: target, by: [], redirectable: true };
    });
  }
  function intentsEvent(st) {
    return { t: 'intents', intents: st.battle.enemies.map(function (e) { return { enemy: e.id, intent: e.intent ? copy(e.intent) : null }; }) };
  }
  // 예고된 공격의 최종 피해
  R.intentDamage = function (intent) {
    if (!intent || intent.kind !== 'attack') return intent ? intent.value : 0;
    var v = Math.max(0, intent.value - (intent.reduce || 0));
    if (intent.halve) v = D().rules.guardRound === 'ceil' ? Math.ceil(v / 2) : Math.floor(v / 2);
    return v;
  };

  // ───────── 턴 시작 ─────────
  R.startTurn = function (st) {
    var b = st.battle, d = D(), enc = d.encounters[b.enc], ev = [];
    b.turn++; b.phase = 'player'; b.energy = d.rules.energyPerTurn; b.lastPlayedIndex = -1;
    ev.push({ t: 'turnStart', turn: b.turn, energy: b.energy });
    var adds = enc.turnStartCards && enc.turnStartCards[b.turn];
    if (adds) adds.forEach(function (id) {
      var def = d.cards[id];
      // 같은 동료의 죽음 카드가 이미 손에 있거나 그 동료가 이미 죽었으면 넣지 않는다
      if (def.kind === 'death') {
        var a = ally(st, def.ally);
        if (!a || a.status === 'dead') return;
        if (b.hand.some(function (u) { return st.cards[u].id === id; })) return;
      }
      var uid = newCard(st, id);
      addToHand(st, uid);
      ev.push({ t: 'addCard', uid: uid, reason: 'turnStart', hand: b.hand.slice() });
    });
    var retained = b.hand.filter(function (u) { return R.def(st, u).retain; }).length;
    var n = Math.max(0, d.rules.drawPerTurn - retained);
    drawCards(st, n, enc.scriptedHands && enc.scriptedHands[b.turn], ev);
    rollIntents(st);
    ev.push(intentsEvent(st));
    ev.push({ t: 'energy', energy: b.energy });
    return ev;
  };

  // ───────── 카드 사용 가능 여부·대상 ─────────
  R.cost = function (st, uid) {
    var b = st.battle;
    if (b && b.free[uid] === b.turn) return 0;
    return R.def(st, uid).cost;
  };
  function no(reason) { return { ok: false, reason: reason }; }

  R.ownerBlocked = function (st, uid) {
    var c = R.def(st, uid);
    if (c.kind === 'ally') {
      var a = ally(st, c.owner);
      if (!a || a.status === 'dead') return '죽은 동료의 카드';
      if (a.status === 'down') return '쓰러진 동료의 카드';
    }
    if (c.kind === 'death') {
      var a2 = ally(st, c.ally);
      if (!a2 || a2.status === 'dead') return '이미 죽었다';
    }
    return null;
  };

  R.canPlay = function (st, uid) {
    var b = st.battle;
    if (!b || b.phase !== 'player' || b.result) return no('지금은 낼 수 없다');
    if (b.hand.indexOf(uid) < 0) return no('손패에 없는 카드');
    var c = R.def(st, uid);
    if (c.unplayable) return no('낼 수 없는 카드');
    var blocked = R.ownerBlocked(st, uid);
    if (blocked) return no(blocked);
    if (R.cost(st, uid) > b.energy) return no('에너지가 부족하다');
    if (c.target !== 'none' && R.validTargets(st, uid).length === 0) return no('대상이 없다');
    return { ok: true };
  };

  function redirectEffect(c) {
    for (var i = 0; i < (c.effects || []).length; i++) if (c.effects[i].type === 'redirect') return c.effects[i];
    return null;
  }

  // 대상 후보: 적 id 배열
  R.validTargets = function (st, uid) {
    var b = st.battle, c = R.def(st, uid);
    if (!b) return [];
    if (c.target === 'enemy') return aliveEnemies(st).map(function (e) { return e.id; });
    if (c.target === 'intent') {
      var rd = redirectEffect(c);
      return aliveEnemies(st).filter(function (e) {
        var it = e.intent;
        if (!it || it.kind !== 'attack' || !it.redirectable) return false;
        if (!rd) return true;
        if (rd.to === 'choose') return R.redirectChoices(st, e.id).length > 0;
        if (!isOk(st, rd.to)) return false;
        if (rd.halve) return !(it.target === rd.to && it.halve);
        return it.target !== rd.to;
      }).map(function (e) { return e.id; });
    }
    return [];
  };
  // 운명 전가 ②단계: 새로 맞을 아군 후보
  R.redirectChoices = function (st, enemyId) {
    var e = enemy(st, enemyId);
    if (!e || !e.intent) return [];
    return hittable(st).filter(function (w) { return w !== e.intent.target; });
  };
  R.needsSecondTarget = function (st, uid) {
    var rd = redirectEffect(R.def(st, uid));
    return !!rd && rd.to === 'choose';
  };

  // ───────── 피해 처리 ─────────
  function hitEnemy(st, e, amount, srcUid, ev) {
    if (!e.alive) return;
    if (e.immune) {
      if (e.retreatOn && srcUid && st.cards[srcUid].id === e.retreatOn) {
        e.alive = false; e.retreated = true; e.intent = null;
        st.battle.result = 'retreat';
        ev.push({ t: 'retreat', enemy: e.id });
        return;
      }
      ev.push({ t: 'damage', who: { enemy: e.id }, amount: 0, immune: true, hp: null, src: srcUid ? st.cards[srcUid].id : null });
      return;
    }
    e.hp = Math.max(0, e.hp - amount);
    ev.push({ t: 'damage', who: { enemy: e.id }, amount: amount, hp: e.hp, src: srcUid ? st.cards[srcUid].id : null });
    if (e.hp <= 0) {
      e.alive = false; e.intent = null;
      ev.push({ t: 'enemyDie', enemy: e.id });
    }
  }

  function hitAlly(st, who, amount, ev, cause) {
    if (who === 'witch') {
      var w = st.party.witch;
      w.hp = Math.max(0, w.hp - amount);
      ev.push({ t: 'damage', who: { ally: 'witch' }, amount: amount, hp: w.hp, cause: cause || 'attack' });
      return;
    }
    var a = ally(st, who);
    if (!a || a.status !== 'ok') return;
    a.hp = Math.max(0, a.hp - amount);
    ev.push({ t: 'damage', who: { ally: who }, amount: amount, hp: a.hp, cause: cause || 'attack' });
    if (a.hp <= 0) {
      a.status = 'down';
      ev.push({ t: 'allyDown', ally: who });
    }
  }

  function checkDefeat(st, ev) {
    var b = st.battle;
    if (!b.result && R.isDefeat(st)) {
      b.result = 'lose';
      ev.push({ t: 'battleEnd', result: 'lose', reason: st.party.witch.hp <= 0 ? 'witch' : 'allies' });
      return true;
    }
    return false;
  }

  function checkEnemies(st, ev) {
    var b = st.battle, enc = D().encounters[b.enc];
    if (b.result) return;
    var alive = aliveEnemies(st);
    if (b.kind === 'normal' && enc.giantTriggerAlive && !b.giantTriggered &&
        alive.length > 0 && alive.length <= enc.giantTriggerAlive) {
      b.giantTriggered = true;
      b.result = 'giant';
      var victims = alive.map(function (e) { return e.id; });
      alive.forEach(function (e) { e.alive = false; e.hp = 0; e.intent = null; e.stomped = true; });
      ev.push({ t: 'giantTrigger', victims: victims });
      return;
    }
    if (!alive.length) {
      b.result = 'win';
      ev.push({ t: 'battleEnd', result: 'win' });
    }
  }

  // ───────── 카드 사용 ─────────
  // target: { enemy: id, to: 'warrior' (운명 전가 ②단계) }
  R.play = function (st, uid, target) {
    target = target || {};
    var chk = R.canPlay(st, uid);
    if (!chk.ok) return { ok: false, reason: chk.reason, events: [] };
    var b = st.battle, c = R.def(st, uid), ev = [];
    if (c.target !== 'none') {
      if (R.validTargets(st, uid).indexOf(target.enemy) < 0) return { ok: false, reason: '대상이 올바르지 않다', events: [] };
      if (R.needsSecondTarget(st, uid) && R.redirectChoices(st, target.enemy).indexOf(target.to) < 0) {
        return { ok: false, reason: '새로 맞을 아군이 올바르지 않다', events: [] };
      }
    }
    var cost = R.cost(st, uid);
    b.energy -= cost;
    b.lastPlayedIndex = b.hand.indexOf(uid);
    b.hand.splice(b.lastPlayedIndex, 1);
    ev.push({ t: 'play', uid: uid, id: st.cards[uid].id, target: copy(target), cost: cost, energy: b.energy, hand: b.hand.slice(), handIndex: b.lastPlayedIndex });

    for (var i = 0; i < c.effects.length; i++) {
      applyEffect(st, uid, c, c.effects[i], target, ev);
      if (b.result === 'lose') break;
    }
    if (c.exhaust) b.exhaust.push(uid); else b.discard.push(uid);
    if (!b.result) checkDefeat(st, ev);
    if (!b.result) checkEnemies(st, ev);
    if (!b.result && b.energy <= 0) ev.push({ t: 'energyOut' });
    return { ok: true, events: ev };
  };

  function applyEffect(st, uid, c, eff, target, ev) {
    var b = st.battle, d = D();
    switch (eff.type) {
      case 'damage': {
        var e = enemy(st, target.enemy);
        if (e) hitEnemy(st, e, eff.amount, uid, ev);
        break;
      }
      case 'damageAll': {
        ev.push({ t: 'aoe', src: st.cards[uid].id });
        aliveEnemies(st).forEach(function (en) { hitEnemy(st, en, eff.amount, uid, ev); });
        break;
      }
      case 'draw':
        drawCards(st, eff.count, null, ev);
        break;
      case 'redirect': {
        var en = enemy(st, target.enemy);
        if (!en || !en.intent) break;
        var from = en.intent.target;
        var to = eff.to === 'choose' ? target.to : eff.to;
        en.intent.target = to;
        if (eff.halve) en.intent.halve = true;
        else en.intent.halve = false;   // 다른 아군으로 옮기면 감싸기 효과는 사라진다
        en.intent.by.push(c.name);
        ev.push({ t: 'redirect', enemy: en.id, from: from, to: to, halve: !!eff.halve, card: st.cards[uid].id });
        ev.push(intentsEvent(st));
        break;
      }
      case 'weaken': {
        var ew = enemy(st, target.enemy);
        if (ew && ew.intent && ew.intent.kind === 'attack') {
          ew.intent.reduce = (ew.intent.reduce || 0) + eff.amount;
          ew.intent.by.push(c.name);
          ev.push({ t: 'weaken', enemy: ew.id, amount: eff.amount });
          ev.push(intentsEvent(st));
        }
        break;
      }
      case 'selfDamage':
        hitAlly(st, 'witch', eff.amount, ev, 'relic');
        break;
      case 'killAlly': {
        var a = ally(st, eff.ally);
        if (a) {
          a.status = 'dead'; a.hp = 0;
          ev.push({ t: 'allyDeath', ally: eff.ally, cause: 'deathCard', card: st.cards[uid].id, handIndex: b.lastPlayedIndex });
        }
        break;
      }
      case 'relicize': {
        var changes = [];
        Object.keys(st.cards).forEach(function (u) {
          var card = st.cards[u], df = d.cards[card.id];
          if (df.kind === 'ally' && df.owner === eff.ally && d.relicMap[card.id]) {
            changes.push({ uid: u, from: card.id, to: d.relicMap[card.id] });
            card.id = d.relicMap[card.id];
          }
        });
        ev.push({ t: 'relicize', ally: eff.ally, changes: changes });
        break;
      }
      case 'addCard': {
        var nu = newCard(st, eff.card);
        if (eff.permanent) st.party.deck.push(nu);
        if (eff.freeThisTurn) b.free[nu] = b.turn;
        addToHand(st, nu, eff.at === 'source' ? b.lastPlayedIndex : null);
        ev.push({ t: 'addCard', uid: nu, reason: 'effect', free: !!eff.freeThisTurn, hand: b.hand.slice() });
        break;
      }
      default:
        throw new Error('알 수 없는 효과: ' + eff.type);
    }
  }

  // ───────── 턴 종료 → 적 턴 ─────────
  R.endTurn = function (st) {
    var b = st.battle, ev = [];
    if (!b || b.phase !== 'player' || b.result) return ev;
    b.phase = 'enemy';
    var keep = [], gone = [];
    b.hand.forEach(function (u) { (R.def(st, u).retain ? keep : gone).push(u); });
    b.hand = keep; b.discard = b.discard.concat(gone);
    ev.push({ t: 'discardHand', uids: gone, hand: keep.slice() });
    ev.push({ t: 'enemyPhase' });
    var es = b.enemies.slice();
    for (var i = 0; i < es.length; i++) {
      var e = es[i];
      if (!e.alive || !e.intent) continue;
      performIntent(st, e, ev);
      if (b.result) break;
    }
    if (!b.result) checkDefeat(st, ev);
    return ev;
  };

  function performIntent(st, e, ev) {
    var b = st.battle, it = e.intent;
    if (it.kind === 'attack') {
      var amount = R.intentDamage(it);
      var target = it.target;
      if (!isOk(st, target)) {
        var list = hittable(st);
        if (!list.length) return;
        target = list[rint(st, list.length)];
      }
      ev.push({ t: 'enemyAct', enemy: e.id, kind: 'attack', target: target, amount: amount });
      hitAlly(st, target, amount, ev, 'attack');
      checkDefeat(st, ev);
    } else if (it.kind === 'shadow') {
      b.shadow = 1;
      ev.push({ t: 'enemyAct', enemy: e.id, kind: 'shadow' });
    } else if (it.kind === 'aoe') {
      ev.push({ t: 'enemyAct', enemy: e.id, kind: 'aoe', amount: it.value });
      if (it.hitsWitch) hitAlly(st, 'witch', it.value, ev, 'aoe');
      st.party.order.forEach(function (id) { hitAlly(st, id, it.value, ev, 'aoe'); });
      checkDefeat(st, ev);
    } else if (it.kind === 'stomp') {
      ev.push({ t: 'enemyAct', enemy: e.id, kind: 'stomp' });
      st.party.order.forEach(function (id) {
        var a = ally(st, id);
        if (a.status === 'ok') { var hp = a.hp; hitAlly(st, id, hp, ev, 'stomp'); }
      });
      if (st.party.witch.hp > 0) hitAlly(st, 'witch', st.party.witch.hp, ev, 'stomp');
      if (!b.result) { b.result = 'lose'; ev.push({ t: 'battleEnd', result: 'lose', reason: 'stomp' }); }
    }
  }

  // ───────── 전투 종료 처리 (쓰러진 동료: HP 1 복귀 + 상처 카드) ─────────
  R.finishBattle = function (st) {
    var ev = [], p = st.party, d = D();
    p.order.forEach(function (id) {
      var a = p.allies[id];
      if (a.status !== 'down') return;
      a.status = 'ok'; a.hp = d.rules.downedReviveHp;
      var cands = p.deck.filter(function (u) {
        var df = d.cards[st.cards[u].id];
        return df.kind === 'ally' && df.owner === id;
      });
      if (cands.length) {
        var u = cands[rint(st, cands.length)];
        var from = st.cards[u].id;
        st.cards[u].id = 'wound'; st.cards[u].woundOf = id;
        ev.push({ t: 'wound', ally: id, uid: u, from: from });
      }
      ev.push({ t: 'revive', ally: id, hp: a.hp });
    });
    // 임시 카드(죽음 카드 등)는 버린다
    var keep = {};
    p.deck.forEach(function (u) { keep[u] = true; });
    Object.keys(st.cards).forEach(function (u) { if (!keep[u]) delete st.cards[u]; });
    st.battle = null;
    return ev;
  };

  // ───────── 디버그 ─────────
  R.debugSetHp = function (st, who, hp) {
    hp = Math.max(0, Math.floor(hp));
    if (who === 'witch') { st.party.witch.hp = Math.min(hp, 999); return; }
    var a = ally(st, who);
    if (a) {
      if (a.status === 'dead') return;
      a.hp = hp; a.status = hp > 0 ? 'ok' : 'down';
      return;
    }
    if (st.battle) {
      var e = enemy(st, who);
      if (e && e.maxHp != null) { e.hp = hp; e.alive = hp > 0; if (!e.alive) e.intent = null; }
    }
  };
  R.debugAddCard = function (st, cardId) {
    var b = st.battle;
    if (!b) return [];
    var uid = newCard(st, cardId);
    addToHand(st, uid);
    return [{ t: 'addCard', uid: uid, reason: 'debug', hand: b.hand.slice() }];
  };
  // 전투 즉시 승리: 일반 전투 → 거대 존재 등장 / 거대 존재 → 물러남
  R.debugWin = function (st) {
    var b = st.battle, ev = [];
    if (!b || b.result) return ev;
    if (b.kind === 'giant') {
      var g = aliveEnemies(st)[0];
      if (g) { g.alive = false; g.retreated = true; g.intent = null; b.result = 'retreat'; ev.push({ t: 'retreat', enemy: g.id }); }
      return ev;
    }
    var alive = aliveEnemies(st);
    var enc = D().encounters[b.enc];
    var leave = enc.giantTriggerAlive || 0;
    for (var i = 0; i < alive.length - leave; i++) hitEnemy(st, alive[i], 999, null, ev);
    checkEnemies(st, ev);
    return ev;
  };
})(typeof window !== 'undefined' ? window : globalThis);
