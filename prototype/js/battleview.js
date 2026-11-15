/*
 * battleview.js — 전투 화면: 배경·동료 뒷모습·적·HP·예고·마녀 HP·에너지, 붉은 실, 규칙 이벤트 연출
 * 화면은 규칙 상태를 직접 읽지 않고, 이벤트로 받은 값(vm)을 그린다 → 연출 중간 값이 자연스럽게 보인다.
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var V = Game.View = { vm: null, els: { enemies: {}, allies: {}, hpAlly: {}, hpEnemy: {}, intents: {} } };
  var FX = Game.FX;

  function D() { return Game.DATA; }
  function LY() { return Game.DATA.layout; }
  function $(id) { return document.getElementById(id); }
  function div(cls, parent) { var d = document.createElement('div'); if (cls) d.className = cls; if (parent) parent.appendChild(d); return d; }
  function name(who) { return who === 'witch' ? D().party.witch.name : D().party.allies[who] ? D().party.allies[who].name : who; }
  V.name = name;

  // ───────── 위치 계산 ─────────
  V.allyBox = function (id) {
    var a = LY().allies[id], sz = Game.Assets.size(a.img), ar = sz ? sz.w / sz.h : 0.42;
    var w = a.h * ar;
    return { x: a.x - w / 2, y: a.top, w: w, h: a.h };
  };
  V.allyAnchor = function (id) {
    var a = LY().allies[id], b = V.allyBox(id);
    return { x: b.x + b.w * a.anchor[0], y: b.y + b.h * a.anchor[1] };
  };
  V.allyHpPos = function (id) { var a = LY().allies[id]; return { x: a.x, y: a.top - LY().allyHpOffset }; };
  // 공격·선택 대상으로서의 영역(머리~상체 + HP판)
  V.allyHitRect = function (id) {
    var b = V.allyBox(id), hp = V.allyHpPos(id);
    return { x: b.x + b.w * 0.12, y: hp.y - 6, w: b.w * 0.76, h: (b.y + Math.min(b.h * 0.42, 330)) - (hp.y - 6) };
  };
  V.witchRect = function () { var p = LY().witchPanel; return { x: p.x, y: p.y, w: p.w, h: p.h }; };
  // 거대 존재의 발 그림 위치(그림 비율 유지). 그림이 없으면 화면 위쪽 회색 박스
  V.footRect = function () {
    var g = LY().giant, sz = Game.Assets.size(D().enemies.giant.sprite);
    if (!sz) return { x: 0, y: -40, w: 1920, h: g.bottom + 40, ph: true };
    var h = g.w * sz.h / sz.w;
    return { x: g.cx - g.w / 2, y: g.bottom - h, w: g.w, h: h };
  };
  function enemyAspect(type) {
    var sz = Game.Assets.size(D().enemies[type].sprite);
    return sz ? sz.w / sz.h : LY().enemyAspect;
  }
  V.enemyBox = function (id) {
    var e = Game.Rules.enemy(Game.Ctl.st, id);
    if (!e) return null;
    if (e.slot === 'giant') { var f = V.footRect(), top = Math.max(0, f.y); return { x: Math.max(0, f.x), y: top, w: Math.min(1920, f.w), h: LY().giant.bottom - top }; }
    var s = LY().enemySlots[e.slot], w = s.h * enemyAspect(e.type);
    return { x: s.x - w / 2, y: s.feet - s.h, w: w, h: s.h };
  };
  V.enemyCenter = function (id) {
    var b = V.enemyBox(id);
    if (!b) return { x: 960, y: 300 };
    return { x: b.x + b.w / 2, y: b.y + b.h * 0.45 };
  };
  V.intentRect = function (id) {
    var el = V.els.intents[id];
    if (!el || el.classList.contains('hidden')) return null;
    var w = el.offsetWidth, h = el.offsetHeight;
    return { x: el.offsetLeft - w / 2, y: el.offsetTop, w: w, h: h };
  };
  V.targetPoint = function (who) {
    if (who === 'witch') { var r = V.witchRect(); return { x: r.x + r.w / 2, y: r.y + r.h / 2 }; }
    if (LY().allies[who]) { var hp = V.allyHpPos(who); return { x: hp.x, y: hp.y + 60 }; }
    return V.enemyCenter(who);
  };
  function inRect(r, x, y, pad) { pad = pad || 0; return r && x >= r.x - pad && x <= r.x + r.w + pad && y >= r.y - pad && y <= r.y + r.h + pad; }
  V.inRect = inRect;

  // 좌표의 적 (몸·HP·예고)
  V.enemyAt = function (x, y) {
    var st = Game.Ctl.st;
    if (!st || !st.battle) return null;
    var es = st.battle.enemies;
    for (var i = 0; i < es.length; i++) {
      var e = es[i];
      if (!e.alive) continue;
      if (inRect(V.intentRect(e.id), x, y, 6)) return e.id;
    }
    for (var j = 0; j < es.length; j++) {
      var e2 = es[j];
      if (!e2.alive) continue;
      var b = V.enemyBox(e2.id);
      if (inRect(b, x, y, 6)) return e2.id;
      if (e2.slot !== 'giant' && inRect({ x: b.x, y: b.y + b.h, w: b.w, h: 34 }, x, y)) return e2.id;
    }
    return null;
  };
  V.intentAt = function (x, y) {
    var st = Game.Ctl.st;
    if (!st || !st.battle) return null;
    var es = st.battle.enemies;
    for (var i = 0; i < es.length; i++) if (es[i].alive && inRect(V.intentRect(es[i].id), x, y, 4)) return es[i].id;
    return null;
  };
  // 좌표의 아군 (동료 상체·HP판, 마녀 HP판)
  V.allyAt = function (x, y) {
    if (inRect(V.witchRect(), x, y, 4)) return 'witch';
    var st = Game.Ctl.st, order = st.party.order;
    for (var i = 0; i < order.length; i++) {
      var id = order[i];
      if (st.party.allies[id].status === 'dead') continue;
      if (inRect(V.allyHitRect(id), x, y)) return id;
    }
    return null;
  };

  // ───────── 화면 구성 ─────────
  V.clear = function () {
    ['bgLayer', 'enemyLayer', 'allyLayer', 'hudLayer'].forEach(function (id) { $(id).innerHTML = ''; });
    Game.Hand.clear();
    ['handImg', 'raiseRig'].forEach(function (id) { var o = $(id); if (o) o.remove(); });
    if (Game.Cutin && Game.Cutin.active) Game.Cutin.active.finish();
    $('shadowLayer').style.opacity = 0;
    V.els = { enemies: {}, allies: {}, hpAlly: {}, hpEnemy: {}, intents: {} };
    V.vm = null;
    V.tempFoot = null; V.footY = 0;
    if (V.bloodLayer) { Game.Blood.remove(V.bloodLayer); V.bloodLayer = null; }
    $('floatLayer').innerHTML = '';
  };

  V.build = function (st) {
    V.clear();
    var ly = LY(), b = st.battle;
    var bg = Game.Assets.el(ly.bg, 1920, 1080, { cls: 'bg-img', phCls: 'bg' });
    bg.classList.add('bg-img');
    $('bgLayer').appendChild(bg);

    // 동료 뒷모습 (좌우 반전 없음)
    // .ally(위치·타격 움직임) > .pose(숨쉬기) > .body(기본 자세) + .act(행동 자세). 각 그림 위에 거대 존재의 그림자(.shade)
    st.party.order.forEach(function (id) {
      var a = st.party.allies[id], box = V.allyBox(id), conf = ly.allies[id];
      var el = div('ally', $('allyLayer'));
      el.setAttribute('data-ally', id);
      el.style.left = box.x + 'px'; el.style.top = box.y + 'px'; el.style.width = box.w + 'px'; el.style.height = box.h + 'px';
      var pose = div('pose', el);
      var body = div('body', pose);
      body.appendChild(Game.Assets.el(conf.img, box.w, box.h));
      function shade(img, w, h, ox, oy) { return V.shadeEl(img, w, h, box.x + ox, box.y + oy); }
      body.appendChild(shade(conf.img, box.w, box.h, 0, 0));
      Game.Motion.buildAlly(id, el, shade);
      V.els.allies[id] = el;
      var hp = div('hp-ally', $('hudLayer'));
      var p = V.allyHpPos(id);
      hp.style.left = p.x + 'px'; hp.style.top = p.y + 'px';
      hp.innerHTML = '<div class="nm"><span>' + name(id) + '</span><span class="v"></span></div><div class="bar"><i></i></div>';
      V.els.hpAlly[id] = hp;
      if (a.status === 'dead') { el.classList.add('dead'); hp.classList.add('hidden'); }
    });

    // 적
    b.enemies.forEach(function (e) { V.makeEnemy(e); });

    // 마녀 HP (왼쪽 아래)
    var wp = div('', $('hudLayer'));
    wp.id = 'witchPanel';
    var r = ly.witchPanel;
    wp.style.left = r.x + 'px'; wp.style.top = r.y + 'px'; wp.style.width = r.w + 'px'; wp.style.height = r.h + 'px';
    wp.innerHTML = '<div class="face"></div><div class="info"><div class="nm"><span>' + D().party.witch.name + '</span><span class="v"></span></div><div class="bar"><i></i></div><div class="sub">마녀 · 나</div></div>';
    Game.Assets.applyFace(wp.querySelector('.face'), 'noel', 78);
    // 에너지 (오른쪽 아래)
    var eo = div('', $('hudLayer'));
    eo.id = 'energyOrb';
    var en = ly.energy;
    eo.style.left = (en.x - en.r) + 'px'; eo.style.top = (en.y - en.r) + 'px'; eo.style.width = en.r * 2 + 'px'; eo.style.height = en.r * 2 + 'px';
    // 턴 종료
    var et = div('', $('hudLayer'));
    et.id = 'endTurn';
    var t = ly.endTurn;
    et.style.left = t.x + 'px'; et.style.top = t.y + 'px'; et.style.width = t.w + 'px'; et.style.height = t.h + 'px';
    et.textContent = '턴 종료';
    et.addEventListener('pointerdown', function (ev) { ev.stopPropagation(); if (ev.button === 0) Game.Ctl.endTurn(); });
    // 덱·버림 더미
    var dp = div('pile', $('hudLayer')); dp.id = 'drawPile';
    dp.style.left = ly.drawPile.x + 'px'; dp.style.top = ly.drawPile.y + 'px';
    var dc = div('pile', $('hudLayer')); dc.id = 'discardPile';
    dc.style.left = ly.discardPile.x + 'px'; dc.style.top = ly.discardPile.y + 'px';

    Game.Hand.init();
    V.bloodLayer = Game.Blood.layer($('bloodCanvas'));

    V.vm = {
      kind: b.kind, enc: b.enc, turn: b.turn,
      hp: {}, maxHp: {}, status: {}, enemyAlive: {}, intents: {},
      hand: b.hand.slice(), ghost: null, ghostIndex: -1,
      energy: b.energy, drawCount: b.draw.length, discardCount: b.discard.length,
      shadow: b.kind === 'giant' ? (b.shadow ? 0.95 : 0.78) : 0, tension: 0, pull: 0, broken: null
    };
    V.syncFromState(st);
    V.setShadow(V.vm.shadow, 0);
    V.render();
  };

  V.makeEnemy = function (e) {
    var ly = LY(), el;
    if (e.slot === 'giant') {
      el = makeFoot();
    } else {
      var s = ly.enemySlots[e.slot], w = s.h * enemyAspect(e.type);
      el = div('enemy', $('enemyLayer'));
      el.style.left = (s.x - w / 2) + 'px'; el.style.top = (s.feet - s.h) + 'px'; el.style.width = w + 'px'; el.style.height = s.h + 'px';
      var body2 = div('body', el);
      body2.appendChild(Game.Assets.el(D().enemies[e.type].sprite, w, s.h));
    }
    el.setAttribute('data-enemy', e.id);
    V.els.enemies[e.id] = el;
    var hp = div('hp-enemy' + (e.slot === 'giant' ? ' giant' : ''), $('hudLayer'));
    var pos = e.slot === 'giant' ? { x: ly.giant.cx, y: ly.giant.feetY } : { x: ly.enemySlots[e.slot].x, y: ly.enemySlots[e.slot].feet + 6 };
    hp.style.left = pos.x + 'px'; hp.style.top = pos.y + 'px';
    hp.innerHTML = '<div class="bar"><i></i></div><div class="v"></div>';
    V.els.hpEnemy[e.id] = hp;
    var it = div('intent hidden' + (e.slot === 'giant' ? ' giant' : ''), $('hudLayer'));
    it.setAttribute('data-intent', e.id);
    V.els.intents[e.id] = it;
    if (!e.alive) { el.classList.add('dead'); hp.classList.add('hidden'); }
    return el;
  };

  V.syncFromState = function (st) {
    var vm = V.vm, b = st.battle;
    if (!vm || !b) return;
    vm.hp.witch = st.party.witch.hp; vm.maxHp.witch = st.party.witch.maxHp;
    st.party.order.forEach(function (id) { var a = st.party.allies[id]; vm.hp[id] = a.hp; vm.maxHp[id] = a.maxHp; vm.status[id] = a.status; });
    b.enemies.forEach(function (e) { vm.hp[e.id] = e.hp; vm.maxHp[e.id] = e.maxHp; vm.enemyAlive[e.id] = e.alive; vm.intents[e.id] = e.intent ? JSON.parse(JSON.stringify(e.intent)) : null; });
    if (!vm.ghost) vm.hand = b.hand.slice();
    vm.energy = b.energy; vm.turn = b.turn;
    vm.drawCount = b.draw.length; vm.discardCount = b.discard.length;
    vm.tension = b.kind === 'giant' ? Math.max(1, Math.min(3, b.turn || 1)) : 0;
  };

  // ───────── 그리기 ─────────
  var ICON = {
    attack: '<svg viewBox="0 0 32 32"><path d="M6 26 L22 10 L25 4 L28 7 L22 10" stroke="#ff6b76" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 18 L14 24 M5 27 L9 23" stroke="#ddd" stroke-width="3" stroke-linecap="round"/></svg>',
    shadow: '<svg viewBox="0 0 32 32"><ellipse cx="16" cy="20" rx="13" ry="6" fill="#000" stroke="#777" stroke-width="2"/><path d="M8 4 C10 12 22 12 24 4" stroke="#888" stroke-width="2" fill="none"/></svg>',
    aoe: '<svg viewBox="0 0 32 32"><rect x="11" y="2" width="10" height="20" fill="#888" transform="rotate(18 16 12)"/><g fill="#aaa"><circle cx="7" cy="26" r="3"/><circle cx="16" cy="28" r="2.5"/><circle cx="25" cy="25" r="3"/></g></svg>',
    stomp: '<svg viewBox="0 0 32 32"><path d="M10 12 C9 18 9 26 15 29 C21 31 24 27 23 21 C22 16 22 12 22 10 C22 7 11 7 10 12Z" fill="#ff3346"/><circle cx="10" cy="6" r="2.5" fill="#ff3346"/><circle cx="14.5" cy="4" r="2.4" fill="#ff3346"/><circle cx="19" cy="4" r="2.2" fill="#ff3346"/><circle cx="22.5" cy="6" r="2" fill="#ff3346"/></svg>'
  };

  V.render = function () {
    var vm = V.vm, st = Game.Ctl.st;
    if (!vm || !st || !st.battle) return;
    // 동료 HP
    st.party.order.forEach(function (id) {
      var hp = V.els.hpAlly[id], el = V.els.allies[id];
      if (!hp) return;
      var status = vm.status[id];
      el.classList.toggle('down', status === 'down');
      el.classList.toggle('dead', status === 'dead');
      hp.classList.toggle('hidden', status === 'dead');
      hp.classList.toggle('down', status === 'down');
      hp.querySelector('.v').textContent = status === 'down' ? '쓰러짐' : vm.hp[id] + ' / ' + vm.maxHp[id];
      hp.querySelector('.bar i').style.width = Math.max(0, 100 * vm.hp[id] / vm.maxHp[id]) + '%';
    });
    // 마녀 HP
    var wp = $('witchPanel');
    if (wp) {
      wp.querySelector('.v').textContent = vm.hp.witch + ' / ' + vm.maxHp.witch;
      wp.querySelector('.bar i').style.width = Math.max(0, 100 * vm.hp.witch / vm.maxHp.witch) + '%';
    }
    // 적 HP·예고
    st.battle.enemies.forEach(function (e) {
      var hp = V.els.hpEnemy[e.id], el = V.els.enemies[e.id];
      if (!hp) return;
      var alive = vm.enemyAlive[e.id];
      hp.classList.toggle('hidden', !alive);
      if (e.maxHp == null) { hp.querySelector('.v').textContent = '???'; }
      else {
        hp.querySelector('.v').textContent = vm.hp[e.id] + ' / ' + vm.maxHp[e.id];
        hp.querySelector('.bar i').style.width = Math.max(0, 100 * vm.hp[e.id] / vm.maxHp[e.id]) + '%';
      }
      V.renderIntent(e.id, alive ? vm.intents[e.id] : null);
    });
    // 에너지·턴 종료·더미
    var eo = $('energyOrb');
    if (eo) {
      eo.innerHTML = vm.energy + '<small>/ ' + D().rules.energyPerTurn + '</small>';
      eo.classList.toggle('empty', vm.energy <= 0);
    }
    var et = $('endTurn');
    if (et) {
      var playerTurn = st.battle.phase === 'player' && !st.battle.result;
      et.classList.toggle('disabled', !playerTurn || Game.Ctl.busy);
      et.classList.toggle('ready', playerTurn && !Game.Ctl.busy && !anyPlayable(st));
    }
    if ($('drawPile')) $('drawPile').textContent = '덱 ' + vm.drawCount;
    if ($('discardPile')) $('discardPile').textContent = '버림 ' + vm.discardCount;
    Game.Hand.layout();
    Game.Hand.updateClasses(st);
  };
  function anyPlayable(st) {
    return st.battle.hand.some(function (u) { return Game.Rules.canPlay(st, u).ok; });
  }

  V.renderIntent = function (id, it) {
    var el = V.els.intents[id];
    if (!el) return;
    if (!it) { el.classList.add('hidden'); el.innerHTML = ''; return; }
    el.classList.remove('hidden');
    var ly = LY(), e = Game.Rules.enemy(Game.Ctl.st, id);
    var html;
    if (e.slot === 'giant') {
      var pips = '';
      for (var i = 1; i <= it.total; i++) pips += '<i class="' + (i <= it.step ? 'on' : '') + '"></i>';
      var val = it.kind === 'aoe' ? '<span class="val">' + it.value + '</span><span class="arrow">→</span><span class="tgt">' + it.detail + '</span>'
        : '<span class="det">' + it.detail + '</span>';
      html = (ICON[it.kind] || ICON.attack) + '<span class="lbl">' + it.label + '</span>' + val +
        '<span class="pips" title="짓밟기까지">' + pips + '</span>';
      el.classList.toggle('lethal', !!it.lethal);
      el.style.left = ly.giant.cx + 'px'; el.style.top = ly.giant.intentY + 'px';
    } else {
      var dmg = Game.Rules.intentDamage(it), reduced = dmg < it.value;
      html = ICON.attack + '<span class="val' + (reduced ? ' reduced' : '') + '">' + dmg + '</span><span class="arrow">→</span><span class="tgt">' + name(it.target) + '</span>' +
        (it.by && it.by.length ? '<span class="mod">(' + it.by[it.by.length - 1] + ')</span>' : '');
      var s = ly.enemySlots[e.slot];
      el.style.left = s.x + 'px'; el.style.top = (s.feet - s.h - 50) + 'px';
    }
    if (el.innerHTML !== html) el.innerHTML = html;
  };

  // 유효 대상 강조
  V.highlight = function (enemyIds, mode, allyIds) {
    Object.keys(V.els.enemies).forEach(function (id) {
      var on = enemyIds && enemyIds.indexOf(id) >= 0;
      V.els.enemies[id].classList.toggle('valid', on && mode === 'enemy');
      if (V.els.intents[id]) V.els.intents[id].classList.toggle('valid', on && mode === 'intent');
    });
    Object.keys(V.els.allies).forEach(function (id) {
      var on = allyIds && allyIds.indexOf(id) >= 0;
      V.els.allies[id].classList.toggle('valid', on);
      V.els.hpAlly[id].classList.toggle('valid', on);
    });
    var wp = $('witchPanel');
    if (wp) wp.classList.toggle('valid', !!allyIds && allyIds.indexOf('witch') >= 0);
  };
  V.hot = function (enemyId, allyId) {
    Object.keys(V.els.enemies).forEach(function (id) {
      V.els.enemies[id].classList.toggle('target-hot', id === enemyId);
      if (V.els.intents[id]) V.els.intents[id].classList.toggle('target-hot', id === enemyId);
    });
    Object.keys(V.els.allies).forEach(function (id) { V.els.allies[id].classList.toggle('target-hot', id === allyId); });
    var wp = $('witchPanel');
    if (wp) wp.classList.toggle('target-hot', allyId === 'witch');
  };

  // 거대 존재의 그림자: 배경·적에는 #shadowLayer(발보다 아래 레이어), 동료에게는 각 그림 모양대로 덮는 .shade
  // (발이 동료 뒤에 있어도 그림자는 동료 위에 드리워진다)
  V.setShadow = function (v, ms) {
    var tr = 'opacity ' + (FX.ms(ms == null ? 1200 : ms) / 1000) + 's';
    var s = $('shadowLayer');
    s.style.transition = tr;
    s.style.opacity = v;
    Array.prototype.forEach.call(document.querySelectorAll('#allyLayer .shade'), function (e) { e.style.transition = tr; e.style.opacity = v; });
    if (V.vm) V.vm.shadow = v;
  };
  // 그림 모양 그대로의 검은 덮개. 세로 그라데이션 가림막을 화면 좌표(sx, sy)에 맞춰 #shadowLayer 와 같은 어둠이 되게 한다
  V.shadeEl = function (img, w, h, sx, sy) {
    var e = Game.Assets.el(img, w, h, { cls: 'shade' });
    e.classList.add('shade');
    e.style.webkitMaskPosition = e.style.maskPosition = (-sx) + 'px ' + (-sy) + 'px';
    e.style.opacity = $('shadowLayer').style.opacity || 0;
    return e;
  };

  // ───────── 붉은 실 ─────────
  function deathCardInHand() {
    var vm = V.vm, st = Game.Ctl.st;
    if (!vm || !st) return null;
    var list = vm.hand.slice();
    if (vm.ghost) list.push(vm.ghost);
    for (var i = 0; i < list.length; i++) {
      var c = st.cards[list[i]];
      if (c && D().cards[c.id].kind === 'death') return { uid: list[i], ally: D().cards[c.id].ally };
    }
    return null;
  }
  V.deathCardInHand = deathCardInHand;

  function strokeThread(ctx, a, c, b, width, color, glow) {
    ctx.strokeStyle = color; ctx.lineWidth = width; ctx.lineCap = 'round';
    ctx.shadowColor = 'rgba(255,30,50,.9)'; ctx.shadowBlur = glow || 0;
    ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.quadraticCurveTo(c.x, c.y, b.x, b.y); ctx.stroke();
    ctx.shadowBlur = 0;
  }

  V.drawThreads = function (ctx, now) {
    var vm = V.vm, st = Game.Ctl.st;
    if (!vm || !st || !st.battle || !Game.Ctl.inBattle) return;
    var H = Game.Hand, order = st.party.order;
    var list = vm.hand.slice();
    if (vm.ghost) list.splice(Math.min(list.length, vm.ghostIndex), 0, vm.ghost);
    var tops = list.map(function (u) { return H.topPoint(u); }).filter(Boolean);
    var dc = deathCardInHand();
    var tension = vm.tension || 0, t = now / 1000;
    var raisedDeath = dc && H.raised && H.raised.uid === dc.uid;
    order.forEach(function (id, idx) {
      if (vm.status[id] === 'dead') return;
      var a = V.allyAnchor(id);
      var taut = dc && dc.ally === id;
      if (taut && raisedDeath) return;   // 들어 올린 죽음 카드의 실은 카드 위 레이어에 그린다(V.drawRaisedThread)
      var b;
      if (taut) b = H.topPoint(dc.uid);
      if (!b) {
        if (tops.length) b = tops[Math.round((tops.length - 1) * idx / Math.max(1, order.length - 1))];
        else b = { x: 960, y: 760 };
      }
      if (!b) return;
      var mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
      if (taut) {
        drawTaut(ctx, a, b, tension, idx, t);
      } else {
        var sag = 70 - tension * 6;
        var sway = Math.sin(t * 0.9 + idx * 1.7) * 10;
        var dim = vm.status[id] === 'down' ? 0.14 : 0.4 + tension * 0.06;
        strokeThread(ctx, a, { x: mx + sway, y: my + sag }, b, 1.5 + tension * 0.2, 'rgba(230,30,48,' + dim + ')', FX.low ? 3 : 7);
      }
    });
    // 용사가 있던 자리에 남은 끊어진 실 끝
    if (vm.broken) {
      var sw0 = Math.sin(t * 1.6) * 8, hb = V.allyAnchor('hero');
      strokeThread(ctx, { x: hb.x, y: hb.y - 16 }, { x: hb.x + 12 + sw0 * 0.4, y: hb.y + 30 }, { x: hb.x + 18 + sw0, y: hb.y + 74 }, 1.6, 'rgba(160,12,26,.6)', 4);
    }
  };
  // 죽음 카드에 걸린 팽팽한 실. pull: 1 = 카드를 낸 순간, 2 = 들어 올린 손에서 최대로 팽팽 (곧게 펴지고 굵게 떨린다)
  function drawTaut(ctx, a, b, tension, idx, t) {
    var vm = V.vm, pull = vm.pull || 0, mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
    var k = 1 + tension * 0.55 + pull * (pull > 1 ? 2.4 : 3);
    var vib = (tension * 0.9 + pull * (pull > 1 ? 3.2 : 4)) * Math.sin(t * 60 + idx);
    var c = { x: mx + vib, y: my + (pull > 1 ? 0 : Math.max(0, 14 - tension * 5)) + vib * 0.5 };
    strokeThread(ctx, a, c, b, 1.8 + k * 0.9, 'rgba(255,' + Math.max(10, 50 - tension * 12 - pull * 10) + ',60,' + Math.min(1, 0.72 + tension * 0.09 + pull * 0.1) + ')', (10 + k * 5) * (FX.low ? 0.5 : 1));
    // 매듭(카드에 걸린 곳)
    ctx.fillStyle = 'rgba(255,60,80,.95)'; ctx.shadowColor = '#ff2a3c'; ctx.shadowBlur = 14;
    ctx.beginPath(); ctx.arc(b.x, b.y, 3 + tension, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.arc(a.x, a.y, 2.5 + tension * 0.6, 0, Math.PI * 2); ctx.fill();
    ctx.shadowBlur = 0;
  }
  // 들어 올린 죽음 카드 ↔ 그 동료의 등: 들어 올린 손(손패보다 위 레이어)에 걸리므로 효과 캔버스에 그린다
  V.drawRaisedThread = function (ctx, now) {
    var vm = V.vm, st = Game.Ctl.st, H = Game.Hand;
    if (!vm || !st || !st.battle || !Game.Ctl.inBattle || !H.raised) return;
    var dc = deathCardInHand();
    if (!dc || H.raised.uid !== dc.uid || vm.status[dc.ally] === 'dead') return;
    drawTaut(ctx, V.allyAnchor(dc.ally), H.raiseTopPoint(), vm.tension || 0, st.party.order.indexOf(dc.ally), now / 1000);
  };

  // 카드에 걸린 채 끊어져 늘어진 실 (카드 위에 그린다)
  V.drawBroken = function (ctx, now) {
    var vm = V.vm;
    if (!vm || !vm.broken || !Game.Ctl.inBattle) return;
    var p = vm.broken.uid ? Game.Hand.topPoint(vm.broken.uid) : null;
    p = p || vm.broken.at;
    if (!p) return;
    vm.broken.at = p;
    var t = now / 1000, sw = Math.sin(t * 1.6) * 8;
    var c1 = { x: p.x - 30 + sw * 0.3, y: p.y - 54 }, e1 = { x: p.x - 46 + sw, y: p.y + 130 };
    strokeThread(ctx, p, c1, e1, 2.4, 'rgba(185,16,32,.92)', 8);
    ctx.strokeStyle = 'rgba(185,16,32,.85)'; ctx.lineWidth = 1.2;
    ctx.beginPath(); ctx.moveTo(e1.x, e1.y); ctx.lineTo(e1.x - 6 + sw * 0.2, e1.y + 11); ctx.moveTo(e1.x, e1.y); ctx.lineTo(e1.x + 5, e1.y + 12); ctx.stroke();
    ctx.fillStyle = 'rgba(220,40,60,.95)';
    ctx.beginPath(); ctx.arc(p.x, p.y, 3, 0, Math.PI * 2); ctx.fill();
  };

  // ───────── 이벤트 연출 ─────────
  V.play = async function (events) {
    for (var i = 0; i < events.length; i++) {
      var h = V.on[events[i].t];
      if (h) await h(events[i]);
      V.render();
    }
    V.syncFromState(Game.Ctl.st);
    V.render();
  };

  function hpFloat(who, amount, cls) {
    var p;
    if (who.enemy) p = V.enemyCenter(who.enemy);
    else if (who.ally === 'witch') { var r = V.witchRect(); p = { x: r.x + r.w / 2, y: r.y - 20 }; }
    else { var hp = V.allyHpPos(who.ally); p = { x: hp.x, y: hp.y + 90 }; }
    FX.floatText(p.x, p.y, amount, cls);
    return p;
  }
  function flashEl(el) { if (!el) return; el.classList.remove('hit'); void el.offsetWidth; el.classList.add('hit'); }
  function ownerColor(id) {
    var d = D().cards[id];
    if (!d) return ['#fff'];
    if (d.kind === 'inherit' || d.kind === 'death') return ['#ff2a3c', '#7a0010'];
    if (d.kind === 'relic') return ['#ddd', '#888'];
    return { witch: ['#c86bff', '#ff4a6a'], hero: ['#ffffff', '#bfe6ff'], warrior: ['#ffd36b', '#c9a24a'], archer: ['#b6ff9a', '#ffffff'] }[d.owner] || ['#fff'];
  }

  // 카드 사용 모션: 카드가 (세워 든 손에서) 대상 쪽으로 날아가며 사라진다
  async function flyCard(el, to) {
    if (!el) return;
    el.classList.remove('hover', 'lifted', 'dragging', 'raised');
    el.classList.add('notrans');
    el.style.zIndex = 140;
    var c = LY().card;
    var from = el.style.transform;
    var mid = 'translate(' + (to.x - c.w * 0.45) + 'px,' + (to.y - c.h * 0.45 - 60) + 'px) scale(.9)';
    var end = 'translate(' + (to.x - c.w * 0.2) + 'px,' + (to.y - c.h * 0.2) + 'px) scale(.4)';
    await FX.anim(el, [{ transform: from, opacity: 1, filter: 'brightness(1)' }, { transform: mid, opacity: 1, filter: 'brightness(1.6)', offset: 0.55 }, { transform: end, opacity: 0, filter: 'brightness(3)' }], { duration: D().timing.cardFly, easing: 'ease-in', fill: 'forwards' });
    el.remove();
  }

  V.on = {
    battleStart: async function () {},
    turnStart: async function (e) {
      V.vm.turn = e.turn; V.vm.energy = e.energy;
      if (V.vm.kind === 'giant') {
        V.vm.tension = Math.min(3, e.turn);
        var total = D().encounters.giant.countdown.length, left = Math.max(1, total - e.turn + 1);
        await FX.banner(e.turn + '턴 · 짓밟기까지 ' + left, 1000);
      } else {
        await FX.banner(e.turn + '턴', 700);
      }
    },
    energy: async function (e) { V.vm.energy = e.energy; },
    draw: async function (e) {
      V.vm.hand = e.hand; V.vm.drawCount = e.drawLeft;
      if (!Game.Hand.els[e.uid]) Game.Hand.create(Game.Ctl.st, e.uid, LY().drawPile);
      V.render();
      await FX.wait(D().timing.drawGap);
    },
    reshuffle: async function () { FX.toast('버림 더미를 섞어 새 덱으로'); await FX.wait(300); },
    handFull: async function () { FX.toast('손패가 가득 찼다'); },
    addCard: async function (e) {
      var st = Game.Ctl.st, d = Game.Rules.def(st, e.uid);
      if (d.kind === 'death') {
        // 죽음 카드가 손에 들어온다: 손패 가운데에서 붉게 떠오름
        V.vm.hand = e.hand;
        var el = Game.Hand.create(st, e.uid, { x: 960, y: 700 });
        V.render();
        el.classList.add('appear');
        FX.flash('#5a0010', 500, 0.45);
        FX.shake(4, 300);
        await FX.wait(900);
        el.classList.remove('appear');
        return;
      }
      if (e.reason === 'effect' && V.vm.ghost) {
        // 죽음 카드가 있던 자리에 짓밟힘이 남는다
        var g = Game.Hand.els[V.vm.ghost];
        if (g) { g.remove(); delete Game.Hand.els[V.vm.ghost]; delete Game.Hand.quads[V.vm.ghost]; }
        V.vm.broken = { uid: e.uid };
        V.vm.ghost = null;
        V.vm.hand = e.hand;
        var c = Game.Hand.center(e.uid) ;
        var el2 = Game.Hand.create(st, e.uid, { x: 960, y: 760 });
        V.render();
        el2.classList.add('appear');
        FX.burst(c.x, c.y, { count: 40, colors: ['#ff2a3c', '#7a0010', '#ff8a90'], speed: 260, life: 900, size: 3, gravity: -60 });
        await FX.wait(1000);
        el2.classList.remove('appear');
        return;
      }
      V.vm.hand = e.hand;
      if (!Game.Hand.els[e.uid]) Game.Hand.create(st, e.uid, { x: 960, y: 700 });
      V.render();
      await FX.wait(250);
    },
    intents: async function (e) {
      e.intents.forEach(function (x) { V.vm.intents[x.enemy] = x.intent; });
      V.render();
      await FX.wait(60);
    },
    play: async function (e) {
      var st = Game.Ctl.st, d = D().cards[e.id], H = Game.Hand, T = D().timing;
      V.vm.energy = e.energy;
      V.vm.discardCount = st.battle.discard.length;
      H.hoverUid = null; H.liftedUid = null; H.dragUid = null; H.dragMode = null;
      if (d.kind === 'death') {
        // 죽음 카드: 오른손이 천천히 들어 올린 채 떨리고, 세라피나의 등까지 이어진 붉은 실이 최대로 팽팽해진 뒤 컷신으로
        V.vm.ghost = e.uid; V.vm.ghostIndex = e.handIndex;
        V.vm.hand = e.hand;
        var g = H.els[e.uid];
        if (g) g.classList.add('taut');
        V.vm.pull = 1;
        var up = H.raiseCard(e.uid, g, { slow: true });
        V.render();
        if (V.els.allies.hero) V.els.allies.hero.classList.add('tremble');
        await up;
        V.vm.pull = 2;
        H.raiseTremble(true, T.deathTremble);
        FX.shake(3, T.deathHold);
        await FX.wait(T.deathHold);
        return;
      }
      var to;
      if (e.target && e.target.enemy) to = d.target === 'intent' ? (function () { var r = V.intentRect(e.target.enemy); return r ? { x: r.x + r.w / 2, y: r.y + r.h / 2 } : V.enemyCenter(e.target.enemy); })() : V.enemyCenter(e.target.enemy);
      else to = { x: 960, y: 430 };
      // 카드 내기: 부채꼴 손이 내려가고, 오른손이 그 카드를 세워 든다 → (대표 카드면 컷인) → 카드가 날아간다
      V.vm.hand = e.hand;
      var cel = H.detach(e.uid);
      var raised = H.raiseCard(e.uid, cel);
      V.render();
      await raised;
      await FX.wait(T.raiseHold);
      if (Game.Cutin.has(e.id)) await Game.Cutin.play(e.id);
      var mv = D().motion.cards[e.id];
      var strike = mv && st.party.allies[mv[0]] ? Game.Motion.strike(mv[0], mv[1], to) : null;
      var flyEl = H.releaseRaised();
      H.raiseDown();
      var fly = flyCard(flyEl, to);
      await (strike ? Promise.all([fly, strike.hit]) : fly);
      FX.burst(to.x, to.y, { count: 26, colors: ownerColor(e.id), speed: 320, life: 600, size: 3, gravity: 0 });
      // 카드별 짧은 연출
      if (d.art === 'sword' || d.art === 'brokensword') { FX.slash(to.x, to.y, { len: 260, width: 12, color: d.kind === 'relic' ? '#ddd' : '#eaf6ff', ang: -0.9 }); FX.shake(8, 260); }
      else if (d.art === 'arrow' || d.art === 'arrows') { var a = V.allyAnchor('archer'); await FX.streak(a.x, a.y - 120, to.x, to.y, { color: '#f4f0d0', width: 4, dur: 180 }); }
      else if (d.art === 'flame') { FX.burst(to.x, to.y, { count: 50, colors: ['#ff3a1e', '#ff9a2a', '#ffe08a'], speed: 260, life: 800, size: 5, gravity: -200 }); }
      else if (d.art === 'bash') { FX.burst(to.x, to.y, { count: 20, colors: ['#ffd36b'], speed: 500, life: 400, size: 3, gravity: 0, shape: 'line' }); FX.shake(10, 280); }
      if (d.kind === 'relic') FX.flash('#300', 300, 0.25);
      await FX.wait(120);
    },
    aoe: async function (e) {
      if (e.src === 'trample') { await V.trampleStrike(); return; }
      var st = Game.Ctl.st;
      Game.Rules.aliveEnemies(st).forEach(function (en, i) {
        var c = V.enemyCenter(en.id);
        setTimeout(function () { FX.slash(c.x, c.y, { len: 220, width: 10, color: '#fff', ang: -0.6, count: 2 }); }, FX.ms(i * 90));
      });
      FX.shake(10, 360);
      await FX.wait(260);
    },
    damage: async function (e) {
      var vm = V.vm, w = e.who;
      if (w.enemy) {
        if (e.immune) {
          var c = V.enemyCenter(w.enemy);
          FX.floatText(c.x, c.y + 120, '통하지 않는다', 'immune');
          FX.burst(c.x, c.y + 160, { count: 14, colors: ['#999', '#666'], speed: 200, life: 500, size: 3 });
          Game.Guide.fire('immune', { card: e.src, enc: vm.enc });
          await FX.wait(380);
          return;
        }
        vm.hp[w.enemy] = e.hp;
        hpFloat(w, e.amount, 'enemy');
        flashEl(V.els.enemies[w.enemy]);
        if (e.amount >= 12) FX.shake(9, 300);
        V.render();
        await FX.wait(260);
        return;
      }
      vm.hp[w.ally] = e.hp;
      var cls = 'ally' + (e.cause === 'relic' ? ' small' : '');
      hpFloat(w, '-' + e.amount, cls);
      if (w.ally === 'witch') flashEl($('witchPanel'));
      else { flashEl(V.els.allies[w.ally]); if (e.cause !== 'stomp') Game.Motion.hurt(w.ally); }
      if (e.cause === 'attack') FX.shake(6 + e.amount * 0.6, 280);
      V.render();
      await FX.wait(e.cause === 'aoe' || e.cause === 'stomp' ? 120 : 300);
    },
    enemyDie: async function (e) {
      V.vm.enemyAlive[e.enemy] = false;
      var el = V.els.enemies[e.enemy];
      if (el) {
        var c = V.enemyCenter(e.enemy);
        FX.burst(c.x, c.y + 60, { count: 30, colors: ['#555', '#333', '#7a0010'], speed: 220, life: 900, size: 4 });
        await FX.anim(el, [{ transform: 'translateY(0) scale(1)', opacity: 1 }, { transform: 'translateY(30px) scale(.9,.6)', opacity: 0 }], { duration: 420, easing: 'ease-in', fill: 'forwards' });
        el.classList.add('dead');
      }
      V.render();
    },
    allyDown: async function (e) {
      V.vm.status[e.ally] = 'down';
      V.render();
      FX.toast(name(e.ally) + ' 쓰러짐', 1200);
      Game.Guide.fire('allyDown', { enc: V.vm.enc });
      await FX.wait(500);
    },
    enemyPhase: async function () { await FX.banner('적의 차례', 600); },
    discardHand: async function (e) {
      var p = LY().discardPile, c = LY().card, ps = [];
      Object.keys(Game.Hand.els).forEach(function (uid) {
        if (e.hand.indexOf(uid) >= 0) return;
        var el = Game.Hand.detach(uid);
        if (!el) return;
        el.classList.remove('hover', 'lifted');
        ps.push(FX.anim(el, [{ transform: el.style.transform, opacity: 1 }, { transform: 'translate(' + (p.x - c.w * 0.1) + 'px,' + (p.y - c.h * 0.1) + 'px) scale(.2)', opacity: 0 }], { duration: 360, easing: 'ease-in', fill: 'forwards' }).then(function () { el.remove(); }));
      });
      V.vm.hand = e.hand;
      V.vm.discardCount = Game.Ctl.st.battle.discard.length;
      V.render();
      await Promise.all(ps);
    },
    enemyAct: async function (e) {
      var el = V.els.enemies[e.enemy];
      if (e.kind === 'attack') {
        // 몸을 젖혔다가 달려든다 → 맞는 순간 베기 자국 (맞은 동료의 흔들림은 이어지는 damage 에서)
        var tp = V.targetPoint(e.target);
        var ln = Game.Motion.enemyLunge(el);
        await ln.hit;
        FX.slash(tp.x, tp.y, { len: 150, width: 7, color: '#ff4050', ang: -0.8, count: 3 });
        await FX.wait(Math.max(60, D().timing.enemyAttack - 440));
      } else if (e.kind === 'shadow') {
        await V.giantShadow();
      } else if (e.kind === 'aoe') {
        await V.pillarCollapse();
      } else if (e.kind === 'stomp') {
        await V.giantStomp();
      }
    },
    redirect: async function (e) {
      var r = V.intentRect(e.enemy), from = r ? { x: r.x + r.w / 2, y: r.y + r.h } : V.enemyCenter(e.enemy);
      var to = V.targetPoint(e.to);
      await FX.streak(from.x, from.y, to.x, to.y, { color: '#ff2a3c', width: 5, dur: 300 });
      FX.burst(to.x, to.y, { count: 16, colors: ['#ff2a3c', '#ff8a90'], speed: 160, life: 500, size: 3, gravity: 0 });
      Game.Guide.fire('redirect', { enc: V.vm.enc, card: e.card });
    },
    weaken: async function (e) {
      var r = V.intentRect(e.enemy);
      if (r) FX.floatText(r.x + r.w / 2, r.y - 10, '-' + e.amount, 'small');
      await FX.wait(200);
    },
    giantTrigger: async function (e) { await V.giantAppear(e.victims); },
    retreat: async function () { await V.giantRetreat(); },
    allyDeath: async function (e) {
      if (e.cause === 'deathCard') await V.deathSequence(e);
    },
    relicize: async function (e) {
      var st = Game.Ctl.st;
      e.changes.forEach(function (ch) {
        if (Game.Hand.els[ch.uid]) {
          Game.Hand.render(st, ch.uid);
          var el = Game.Hand.els[ch.uid];
          el.classList.add('relicflash');
          setTimeout(function () { el.classList.remove('relicflash'); }, FX.ms(1000));
        }
      });
      V.render();
      if (e.changes.length) FX.toast(name(e.ally) + '의 카드 ' + e.changes.length + '장이 유품이 되었다', 1800);
      await FX.wait(600);
    },
    wound: async function (e) {
      FX.toast(name(e.ally) + '의 카드 1장이 「상처」가 되었다', 1800);
      await FX.wait(900);
    },
    revive: async function (e) { V.vm.hp[e.ally] = e.hp; V.vm.status[e.ally] = 'ok'; },
    energyOut: async function () { Game.Guide.fire('energyOut', { enc: V.vm.enc }); },
    battleEnd: async function () {}
  };

  // ───────── 거대 존재 ─────────
  function makeFoot() {
    var r = V.footRect(), el = div('enemy giant', $('enemyLayer'));
    el.style.left = r.x + 'px'; el.style.top = r.y + 'px'; el.style.width = r.w + 'px'; el.style.height = r.h + 'px';
    var body = div('body', el);
    body.appendChild(Game.Assets.el(D().enemies.giant.sprite, r.w, r.h, { phCls: 'foot' }));
    return el;
  }
  function footEl() {
    var st = Game.Ctl.st;
    var g = st.battle && st.battle.enemies.filter(function (e) { return e.slot === 'giant'; })[0];
    if (g && V.els.enemies[g.id]) return V.els.enemies[g.id];
    if (V.tempFoot) return V.tempFoot;
    // 일반 전투 중 등장: 임시로 만든다
    V.tempFoot = makeFoot();
    return V.tempFoot;
  }
  function moveFoot(el, y0, y1, ms, easing) {
    return FX.anim(el, [{ transform: 'translateY(' + y0 + 'px)' }, { transform: 'translateY(' + y1 + 'px)' }], { duration: ms, easing: easing || 'ease-out', fill: 'forwards' })
      .then(function () { el.style.transform = 'translateY(' + y1 + 'px)'; V.footY = y1; });
  }
  V.footY = 0;

  V.giantAppear = async function (victims) {
    Game.Dialog.clear();
    Game.Dialog.say(D().giantAppear.before);
    V.setShadow(0.78, 1400);
    FX.rain(0, 1920, -20, { count: 50, colors: ['#8a8580', '#5a5550'], size: 3, life: 1800 });
    for (var i = 0; i < 3; i++) { FX.shake(4 + i * 2, 300); await FX.wait(420); }
    var foot = footEl();
    foot.style.transform = 'translateY(-1200px)';
    var v = victims && victims[0], vel = v ? V.els.enemies[v] : null;
    var drop = 60;
    await moveFoot(foot, -1200, drop, D().timing.footDrop, 'cubic-bezier(.55,0,1,.45)');
    FX.flash('#fff', 200, 0.55);
    FX.shake(30, 800);
    if (vel) {
      var c = V.enemyCenter(v), b = V.enemyBox(v);
      vel.style.transformOrigin = '50% 100%';
      vel.style.transition = 'transform .08s, opacity .2s';
      vel.style.transform = 'scaleY(.05)'; vel.style.opacity = '0';
      if (V.els.hpEnemy[v]) V.els.hpEnemy[v].classList.add('hidden');
      if (V.els.intents[v]) V.els.intents[v].classList.add('hidden');
      FX.burst(c.x, b.y + b.h, { count: 70, colors: ['#8a8580', '#6a6560', '#4a4540'], speed: 620, spread: Math.PI * 1.1, angle: -Math.PI / 2, gravity: 420, size: 6, life: 1500 });
      FX.burst(c.x, b.y + b.h, { count: 26, colors: ['#5a5550', '#3a3530'], speed: 700, spread: Math.PI, angle: -Math.PI / 2, gravity: 900, size: 10, life: 1300, shape: 'rock' });
      FX.burst(c.x, b.y + b.h - 10, { count: 24, colors: ['#7a0010', '#4a0008'], speed: 420, spread: Math.PI, angle: -Math.PI / 2, gravity: 900, size: 4, life: 900 });
    }
    V.vm.enemyAlive[v] = false;
    await FX.wait(800);
    await moveFoot(foot, drop, 0, 1000, 'ease-out');
    await Game.Dialog.say(D().giantAppear.after);
  };

  V.giantShadow = async function () {
    var foot = footEl();
    FX.rain(0, 1920, -10, { count: 40, colors: ['#777', '#555'], size: 3, life: 2000 });
    V.setShadow(0.95, 1600);
    FX.shake(5, 900);
    await moveFoot(foot, V.footY, 40, 1600, 'ease-in-out');
  };
  V.pillarCollapse = async function () {
    var foot = footEl();
    moveFoot(foot, V.footY, 70, 300, 'ease-in');
    FX.shake(22, 900);
    FX.rain(0, 1920, -60, { count: 60, colors: ['#6a6560', '#4a4540', '#7a7570'], size: 16, life: 1500, gravity: 1400, shape: 'rock', stagger: 300 });
    FX.rain(0, 1920, -20, { count: 80, colors: ['#9a958f', '#777'], size: 3, life: 1800 });
    await FX.wait(700);
    FX.burst(400, 560, { count: 50, colors: ['#8a8580', '#5a5550'], speed: 500, spread: Math.PI, angle: -Math.PI / 2, gravity: 300, size: 7, life: 1300 });
    FX.burst(1500, 560, { count: 50, colors: ['#8a8580', '#5a5550'], speed: 500, spread: Math.PI, angle: -Math.PI / 2, gravity: 300, size: 7, life: 1300 });
    FX.shake(16, 500);
    await FX.wait(300);
  };
  V.giantStomp = async function () {
    var foot = footEl();
    V.setShadow(0.97, 700);
    await moveFoot(foot, V.footY, -180, 700, 'ease-out');
    await FX.wait(400);
    // 마지막 짓밟기만은 발이 일행을 덮친다(평소에는 동료 뒤 레이어)
    foot.classList.add('crushing');
    await moveFoot(foot, -180, 900, 260, 'cubic-bezier(.6,0,1,.4)');
    FX.flash('#fff', 260, 1);
    FX.shake(40, 900);
    await FX.fade(1, 200);
  };
  V.giantRetreat = async function () {
    Game.Dialog.clear();
    var foot = footEl();
    var hp = Object.keys(V.els.hpEnemy).map(function (k) { return V.els.hpEnemy[k]; });
    FX.shake(18, 900);
    FX.rain(0, 1920, -20, { count: 70, colors: ['#8a8580', '#5a5550'], size: 4, life: 2000 });
    await moveFoot(foot, V.footY, -60, 300, 'ease-out');
    hp.forEach(function (h) { h.classList.add('hidden'); });
    Object.keys(V.els.intents).forEach(function (k) { V.els.intents[k].classList.add('hidden'); });
    V.setShadow(0, 2200);
    await moveFoot(foot, -60, -1300, 1600, 'ease-in');
  };
  // 짓밟힘: 붉은 환영의 발이 내리찍는다
  V.trampleStrike = async function () {
    var ph = document.createElement('div');
    // 거대 존재(동료 뒤)를 내리찍으므로 발과 같은 층(동료 뒤)에 그린다
    ph.style.cssText = 'position:absolute;left:560px;top:-700px;width:800px;height:700px;z-index:17;pointer-events:none;filter:drop-shadow(0 0 30px #ff2a3c);opacity:.85';
    ph.innerHTML = '<svg viewBox="0 0 212 184" width="800" height="700" preserveAspectRatio="none"><path d="M70 10 C64 60 66 130 102 166 C130 186 156 160 152 120 C150 90 146 40 146 10Z" fill="rgba(160,0,20,.75)" stroke="#ff3346" stroke-width="3"/></svg>';
    $('world').appendChild(ph);
    FX.flash('#600', 400, 0.5);
    await FX.anim(ph, [{ transform: 'translateY(0)' }, { transform: 'translateY(820px)' }], { duration: 380, easing: 'cubic-bezier(.6,0,1,.4)', fill: 'forwards' });
    FX.flash('#fff', 220, 0.8);
    FX.shake(36, 900);
    FX.burst(960, 420, { count: 80, colors: ['#ff2a3c', '#7a0010', '#8a8580'], speed: 700, spread: Math.PI * 2, gravity: 500, size: 6, life: 1400 });
    await FX.anim(ph, [{ opacity: 0.85 }, { opacity: 0 }], { duration: 700, fill: 'forwards' });
    ph.remove();
  };

  // ───────── 용사의 죽음: 컷신(C1~C6) → 전투 화면 복귀(C7) ─────────
  V.deathSequence = async function () {
    var cs = D().cutscene;
    Game.Dialog.clear();
    var cut = Game.Scenes.cutscene();     // 컷신 화면이 곧바로(동기) 덮는다
    // 컷신 뒤에서: 들어 올렸던 손을 내리고 죽음 카드를 원래 손패 자리로 (C7에서 그 자리에서 재가 된다)
    Game.Hand.raiseReset();
    await cut;
    // 화면 뒤에서 정리: 용사가 사라지고, 손패 위로 피가 튄다
    V.vm.pull = 0;
    V.vm.status.hero = 'dead';
    if (V.els.allies.hero) V.els.allies.hero.classList.remove('tremble');
    V.vm.broken = { uid: null, at: Game.Hand.topPoint(V.vm.ghost) };
    V.render();
    // 마녀의 손·손패 위에 튄 피 (C7)
    Game.Blood.spray(V.bloodLayer, { count: 3, x0: 620, x1: 820, y0: 890, y1: 1030, min: 60, max: 120, seed: 4242 });
    Game.Blood.spray(V.bloodLayer, { count: 3, x0: 1100, x1: 1300, y0: 890, y1: 1030, min: 60, max: 120, seed: 5151 });
    Game.Blood.spray(V.bloodLayer, { count: 2, x0: 820, x1: 1100, y0: 650, y1: 760, min: 34, max: 70, seed: 99 });
    Game.Blood.spray(V.bloodLayer, { count: 5, x0: 300, x1: 1620, y0: 280, y1: 1000, min: 14, max: 34, seed: 7 });
    V.bloodLayer.alpha = 1;
    await Game.Scenes.closeCutscene(cs.returnDelay);
    // 죽음 카드가 재로 부서진다
    var g = V.vm.ghost && Game.Hand.els[V.vm.ghost];
    if (g) {
      var q = Game.Hand.quads[V.vm.ghost];
      g.classList.remove('taut');
      g.classList.add('ash');
      var steps = 10;
      for (var i = 0; i < steps; i++) {
        var tt = i / steps;
        var x = q[0][0] + (q[1][0] - q[0][0]) * Math.random(), y = q[0][1] + (q[3][1] - q[0][1]) * (1 - tt);
        FX.burst(x, y, { count: 14, colors: ['#2a2a2a', '#555', '#111', '#7a0010'], speed: 90, angle: -Math.PI / 2, spread: 1.6, gravity: -90, size: 3, life: 1400, shape: 'flake', jitterX: 120 });
        await FX.wait(cs.ashDuration / steps);
      }
    }
  };

  // C8: 남은 동료의 반응 (굳고 떨림 + 짧은 대사)
  V.reactions = async function () {
    var cs = D().cutscene, st = Game.Ctl.st;
    var who = st.party.order.filter(function (id) { return st.party.allies[id].status !== 'dead'; });
    who.forEach(function (id) { V.els.allies[id].classList.add('tremble'); });
    var stop = setTimeout(function () { who.forEach(function (id) { V.els.allies[id].classList.remove('tremble'); }); }, FX.ms(cs.reactionTremble));
    await Game.Dialog.say(cs.reactions);
    clearTimeout(stop);
    who.forEach(function (id) { V.els.allies[id].classList.remove('tremble'); });
    // 피 자국은 조금 옅어진 채 남는다 (손패를 읽을 수 있게)
    var L = V.bloodLayer, a0 = L ? L.alpha : 0, t0 = performance.now();
    (function fade() {
      if (!L || V.bloodLayer !== L) return;
      var k = Math.min(1, (performance.now() - t0) / FX.ms(1600));
      L.alpha = a0 + (cs.bloodRemain - a0) * k;
      if (k < 1) requestAnimationFrame(fade);
    })();
  };
})(window);
