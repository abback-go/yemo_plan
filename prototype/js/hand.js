/*
 * hand.js — 마녀의 손과 손패.
 * 손 그림(ui_witch_hands.png)의 투명한 다섯 카드 자리에 맞춰 카드를 원근 사각형(matrix3d)으로 끼워 넣는다.
 * 카드는 손 그림 아래 레이어 → 엄지가 카드 위에 겹쳐 쥔 것처럼 보인다.
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var H = Game.Hand = { els: {}, quads: {}, z: {}, hoverUid: null, dragUid: null, dragMode: null, dragPos: null, liftedUid: null };

  function L() { return Game.DATA.layout; }
  function HL() { return Game.DATA.layout.hand; }

  // ───────── 기하 ─────────
  function toScreen(p) { var h = HL(); return [h.x + p[0] * h.scale, h.y + p[1] * h.scale]; }
  function lerp(a, b, t) { return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]; }

  // 슬롯 i(0~4)의 카드 사각형(화면 좌표): 자리 아래쪽 cardFrac 만큼
  H.slotQuad = function (i) {
    var s = HL().slots[i], f = HL().cardFrac;
    var tl = lerp(s[3], s[0], f), tr = lerp(s[2], s[1], f);
    return [toScreen(tl), toScreen(tr), toScreen(s[2]), toScreen(s[3])];
  };
  // 0~4 사이 실수 위치의 사각형 (이웃 슬롯 사이를 꼭짓점별로 보간)
  H.quadAt = function (s) {
    var n = HL().slots.length;
    s = Math.max(0, Math.min(n - 1, s));
    var i = Math.min(n - 2, Math.floor(s)), t = s - i;
    var a = H.slotQuad(i), b = H.slotQuad(i + 1);
    return [lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t), lerp(a[3], b[3], t)];
  };
  // n장일 때 각 카드의 위치. 5장 이하는 슬롯 간격 그대로, 6장 이상은 같은 부채꼴 안에 압축
  H.fan = function (n) {
    var slots = HL().slots.length, mid = (slots - 1) / 2, res = [];
    if (n <= 0) return res;
    var spacing = n <= slots ? 1 : (slots - 1) / (n - 1);
    var start = mid - (n - 1) * spacing / 2;
    for (var i = 0; i < n; i++) {
      var s = start + i * spacing;
      res.push({ s: s, quad: H.quadAt(s), key: -Math.abs(s - mid) * 100 + i });
    }
    var order = res.slice().sort(function (a, b) { return a.key - b.key; });
    order.forEach(function (r, k) { r.z = 50 + k; });
    return res;
  };

  // 단위 정사각형 → 사각형 투영 행렬
  function sq2q(q) {
    var x0 = q[0][0], y0 = q[0][1], x1 = q[1][0], y1 = q[1][1], x2 = q[2][0], y2 = q[2][1], x3 = q[3][0], y3 = q[3][1];
    var dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3, dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
    var g = 0, h = 0;
    if (Math.abs(dx3) > 1e-9 || Math.abs(dy3) > 1e-9) {
      var det = dx1 * dy2 - dx2 * dy1;
      g = (dx3 * dy2 - dx2 * dy3) / det; h = (dx1 * dy3 - dx3 * dy1) / det;
    }
    return [x1 - x0 + g * x1, x3 - x0 + h * x3, x0, y1 - y0 + g * y1, y3 - y0 + h * y3, y0, g, h];
  }
  H.matrix3d = function (q) {
    var W = L().card.w, Hh = L().card.h, m = sq2q(q);
    var v = [m[0] / W, m[3] / W, 0, m[6] / W, m[1] / Hh, m[4] / Hh, 0, m[7] / Hh, 0, 0, 1, 0, m[2], m[5], 0, 1];
    return 'matrix3d(' + v.map(function (x) { return +x.toPrecision(10); }).join(',') + ')';
  };
  function inQuad(q, x, y) {
    var sign = 0;
    for (var i = 0; i < 4; i++) {
      var a = q[i], b = q[(i + 1) % 4];
      var c = (b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0]);
      if (c === 0) continue;
      var s = c > 0 ? 1 : -1;
      if (!sign) sign = s; else if (s !== sign) return false;
    }
    return true;
  }
  H.inQuad = inQuad;

  // 확대(마우스 올림) 위치
  H.hoverRect = function (uid) {
    var q = H.quads[uid], hl = HL(), c = L().card;
    var k = hl.hoverScale, w = c.w * k, h = c.h * k;
    var cx = q ? (q[0][0] + q[1][0] + q[2][0] + q[3][0]) / 4 : 960;
    cx = Math.max(w / 2 + 360, Math.min(1920 - w / 2 - 360, cx));
    return { x: cx - w / 2, y: hl.hoverBottom - h, w: w, h: h, k: k };
  };
  H.dragRect = function () {
    var k = HL().dragScale, c = L().card, p = H.dragPos || { x: 960, y: 600 };
    return { x: p.x - c.w * k / 2, y: p.y - c.h * k / 2, w: c.w * k, h: c.h * k, k: k };
  };
  // 카드 윗변 가운데 (붉은 실이 걸리는 곳)
  H.topPoint = function (uid) {
    if (uid === H.dragUid && H.dragMode === 'follow') { var d = H.dragRect(); return { x: d.x + d.w / 2, y: d.y + 6 }; }
    if (uid === H.hoverUid || uid === H.liftedUid) { var r = H.hoverRect(uid); return { x: r.x + r.w / 2, y: r.y + 6 }; }
    var q = H.quads[uid];
    if (!q) return null;
    return { x: (q[0][0] + q[1][0]) / 2, y: (q[0][1] + q[1][1]) / 2 + 4 };
  };
  H.center = function (uid) {
    var q = H.quads[uid];
    if (!q) return { x: 960, y: 800 };
    return { x: (q[0][0] + q[1][0] + q[2][0] + q[3][0]) / 4, y: (q[0][1] + q[1][1] + q[2][1] + q[3][1]) / 4 };
  };

  // ───────── 손 그림 ─────────
  H.init = function () {
    var layer = document.getElementById('handLayer');
    var old = document.getElementById('handImg');
    if (old) old.remove();
    var hl = HL();
    var img = Game.Assets.el(hl.img, hl.imgW, hl.imgH);
    img.id = 'handImg';
    img.style.left = hl.x + 'px'; img.style.top = hl.y + 'px';
    img.style.transform = 'scale(' + hl.scale + ')';
    img.style.transformOrigin = '0 0';
    layer.appendChild(img);
  };
  H.clear = function () {
    Object.keys(H.els).forEach(function (u) { H.els[u].remove(); });
    H.els = {}; H.quads = {}; H.z = {}; H.hoverUid = null; H.dragUid = null; H.liftedUid = null; H.dragMode = null;
    var layer = document.getElementById('handLayer');
    Array.prototype.slice.call(layer.querySelectorAll('.card')).forEach(function (e) { e.remove(); });
  };

  // ───────── 카드 DOM ─────────
  var OWNER = { witch: '노엘', hero: '세라피나', warrior: '브룬힐드', archer: '엘리안' };
  function esc(s) { return String(s).replace(/[&<>]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]; }); }

  H.cardHtml = function (st, uid) {
    var card = st.cards[uid], d = Game.DATA.cards[card.id], R = Game.Rules;
    var tone = d.kind === 'death' ? 'death' : d.kind === 'inherit' ? 'inherit' : d.kind === 'relic' ? 'relic' : d.kind === 'wound' ? 'wound' : d.owner;
    var text = R.cardText(card.id, function (v) { return '\u0001' + v + '\u0002'; });
    text = esc(text).replace(/\u0001/g, '<b>').replace(/\u0002/g, '</b>');
    var owner = d.kind === 'death' ? '죽음 · ' + OWNER[d.ally]
      : d.kind === 'relic' ? '유품 · ' + OWNER[d.owner]
      : d.kind === 'inherit' ? '상속 · ' + OWNER[d.from]
      : d.kind === 'wound' ? '상처 · ' + (OWNER[card.woundOf] || '')
      : OWNER[d.owner] || '';
    var art = Game.CardArt.svg(d.art, tone);
    var face = '';
    if (Game.CardArt.hasFace(d.art)) {
      face = '<div class="c-face" data-face="hero"></div><svg viewBox="0 0 212 184" style="position:absolute;inset:0;width:100%;height:100%">' +
        '<path d="M0 30 L60 70 L92 60 L130 110 L212 120" stroke="#ff2a3c" stroke-width="2" fill="none" opacity=".9"/>' +
        '<path d="M150 0 L138 50 L160 92 L144 184" stroke="#000" stroke-width="3" fill="none" opacity=".8"/></svg>';
    }
    var tags = (d.tags || []).map(function (t) { return '<span>' + esc(t) + '</span>'; }).join('');
    var frame = Game.Assets.ok('card_frame.png')
      ? '<img class="c-frameimg" src="' + Game.Assets.url('card_frame.png') + '" draggable="false" alt="">'
      : '<div class="c-frame"></div>';
    return '<div class="c-in"></div><div class="c-art">' + art + face + '</div>' +
      '<div class="c-namebar"></div>' + frame +
      '<div class="c-name">' + esc(d.name) + '</div>' +
      '<div class="c-text"><span>' + text + '</span></div>' +
      '<div class="c-owner">' + esc(owner) + '</div>' +
      (tags ? '<div class="c-tags">' + tags + '</div>' : '') +
      '<div class="c-cost"><span>' + d.cost + '</span></div>' +
      '<div class="c-block"></div>';
  };

  H.render = function (st, uid) {
    var el = H.els[uid];
    if (!el) return;
    var card = st.cards[uid];
    if (!card) return;
    var d = Game.DATA.cards[card.id];
    el.setAttribute('data-id', card.id);
    el.className = 'card o-' + (d.kind === 'wound' ? (card.woundOf || 'witch') : (d.owner || 'witch')) + ' k-' + d.kind + (el.classList.contains('notrans') ? ' notrans' : '');
    el.innerHTML = H.cardHtml(st, uid);
    var f = el.querySelector('.c-face');
    if (f) Game.Assets.applyFace(f, 'hero', 212, 0.9);
  };

  H.create = function (st, uid, from) {
    var el = document.createElement('div');
    el.setAttribute('data-uid', uid);
    H.els[uid] = el;
    H.render(st, uid);
    el.classList.add('notrans');
    var c = L().card, p = from || L().drawPile;
    el.style.transform = 'translate(' + (p.x - c.w * 0.15) + 'px,' + (p.y - c.h * 0.15) + 'px) scale(.3)';
    el.style.opacity = '0';
    document.getElementById('handLayer').appendChild(el);
    void el.offsetWidth;
    el.classList.remove('notrans');
    el.style.opacity = '';
    return el;
  };

  // 카드를 손패에서 떼어낸다(사용 연출용). 반환된 요소는 호출한 쪽이 지운다.
  H.detach = function (uid) {
    var el = H.els[uid];
    delete H.els[uid]; delete H.quads[uid];
    if (H.hoverUid === uid) H.hoverUid = null;
    if (H.dragUid === uid) { H.dragUid = null; H.dragMode = null; }
    if (H.liftedUid === uid) H.liftedUid = null;
    return el;
  };

  // 상태 표시(낼 수 있음/에너지 부족/쓰러진 동료/이번 턴 비용 0)
  H.updateClasses = function (st) {
    var R = Game.Rules, b = st.battle;
    Object.keys(H.els).forEach(function (uid) {
      var el = H.els[uid];
      if (!st.cards[uid]) return;
      var d = R.def(st, uid);
      var blocked = R.ownerBlocked(st, uid);
      el.classList.toggle('blocked', !!blocked && d.kind !== 'death');
      var blk = el.querySelector('.c-block');
      if (blk) blk.textContent = blocked ? (blocked.indexOf('쓰러진') >= 0 ? '쓰러짐' : '사용 불가') : '';
      var cost = b ? R.cost(st, uid) : d.cost;
      var costEl = el.querySelector('.c-cost span');
      if (costEl) costEl.textContent = cost;
      el.classList.toggle('free', !!b && cost < d.cost);
      el.classList.toggle('poor', !!b && b.phase === 'player' && cost > b.energy && !d.unplayable);
      var can = b && b.phase === 'player' && !b.result && R.canPlay(st, uid).ok;
      el.classList.toggle('playable-glow', !!can && !Game.Ctl.busy);
    });
  };

  // ───────── 배치 ─────────
  H.layout = function () {
    var vm = Game.View.vm;
    if (!vm) return;
    var list = vm.hand.slice();
    if (vm.ghost && list.indexOf(vm.ghost) < 0) list.splice(Math.max(0, Math.min(list.length, vm.ghostIndex)), 0, vm.ghost);
    var fan = H.fan(list.length);
    var st = Game.Ctl.st;
    list.forEach(function (uid, i) {
      var el = H.els[uid];
      if (!el) el = H.create(st, uid);
      var f = fan[i];
      H.quads[uid] = f.quad; H.z[uid] = f.z;
      el.classList.remove('hover', 'dragging', 'lifted');
      if (uid === H.dragUid && H.dragMode === 'follow') {
        var d = H.dragRect();
        el.classList.add('dragging');
        el.style.transform = 'translate(' + d.x + 'px,' + d.y + 'px) scale(' + d.k + ')';
        el.style.zIndex = '';
      } else if ((uid === H.hoverUid && !H.dragUid) || uid === H.liftedUid) {
        var r = H.hoverRect(uid);
        el.classList.add(uid === H.liftedUid ? 'lifted' : 'hover');
        el.style.transform = 'translate(' + r.x + 'px,' + r.y + 'px) scale(' + r.k + ')';
        el.style.zIndex = '';
      } else {
        el.style.transform = H.matrix3d(f.quad);
        el.style.zIndex = f.z;
      }
    });
    // 목록에 없는 카드 요소 제거
    Object.keys(H.els).forEach(function (uid) {
      if (list.indexOf(uid) < 0) { H.els[uid].remove(); delete H.els[uid]; delete H.quads[uid]; }
    });
  };

  // 화면 좌표의 카드 (위에 있는 것부터)
  H.hitTest = function (x, y) {
    if (H.hoverUid && H.els[H.hoverUid]) {
      var r = H.hoverRect(H.hoverUid);
      if (x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h) return H.hoverUid;
    }
    var vm = Game.View.vm;
    var uids = Object.keys(H.quads).filter(function (u) { return !vm || u !== vm.ghost; });
    uids.sort(function (a, b) { return (H.z[b] || 0) - (H.z[a] || 0); });
    for (var i = 0; i < uids.length; i++) if (inQuad(H.quads[uids[i]], x, y)) return uids[i];
    return null;
  };
  H.setHover = function (uid) {
    if (H.hoverUid === uid) return;
    H.hoverUid = uid;
    H.layout();
  };
})(window);
