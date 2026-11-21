/*
 * dialog.js — 전투 중 대사창(화면 위쪽 + 작은 얼굴)과 튜토리얼 안내 트리거
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var DL = Game.Dialog = { queue: [], cur: null };
  var G = Game.Guide = { done: {} };

  function $(id) { return document.getElementById(id); }

  // lines: [{who, text}] / 반환: 모두 보여 준 뒤 끝나는 Promise
  DL.say = function (lines) {
    if (!lines || !lines.length) return Promise.resolve();
    return new Promise(function (resolve) {
      lines.forEach(function (ln, i) { DL.queue.push({ line: ln, resolve: i === lines.length - 1 ? resolve : null }); });
      if (!DL.cur) pump();
    });
  };
  DL.clear = function () {
    var q = DL.queue; DL.queue = [];
    if (DL.cur) { clearTimeout(DL.cur.timer); clearInterval(DL.cur.typer); if (DL.cur.resolve) DL.cur.resolve(); DL.cur = null; }
    q.forEach(function (x) { if (x.resolve) x.resolve(); });
    $('dialog').classList.add('hidden');
  };
  DL.busy = function () { return !!DL.cur || DL.queue.length > 0; };
  DL.dropPending = function () {
    var q = DL.queue; DL.queue = [];
    q.forEach(function (x) { if (x.resolve) x.resolve(); });
  };

  function pump() {
    var item = DL.queue.shift();
    var box = $('dialog');
    if (!item) { DL.cur = null; box.classList.add('hidden'); return; }
    var ln = item.line, who = ln.who, D = Game.DATA;
    box.classList.remove('hidden', 'inner', 'system', 'noface');
    var faceWho = who === 'inner' ? 'noel' : who, faceEl = box.querySelector('.dlg-face');
    var faces = ln.faces || (ln.face ? [ln.face] : [null]);
    if (who === 'system' || !D.faces[faceWho]) box.classList.add('noface');
    else Game.Assets.applyFace(faceEl, faceWho, 96, 1, faces[0]);
    if (who === 'inner') box.classList.add('inner');
    if (who === 'system') box.classList.add('system');
    box.querySelector('.dlg-name').textContent = who === 'system' ? '안내' : who === 'inner' ? '노엘 (속마음)' : (D.names[who] || '');
    var textEl = box.querySelector('.dlg-text');
    var full = ln.text, n = 0, T = D.timing;
    DL.cur = { item: item, resolve: item.resolve, typing: true };
    textEl.textContent = '';
    var stepMs = 1000 / (T.typeCharsPerSec * Game.FX.speed);
    DL.cur.typer = setInterval(function () {
      n += 1;
      textEl.textContent = full.slice(0, n);
      if (n >= full.length) finishTyping();
    }, stepMs);
    function finishTyping() {
      if (!DL.cur || !DL.cur.typing) return;
      clearInterval(DL.cur.typer);
      DL.cur.typing = false;
      textEl.textContent = full;
      var hold = (ln.pause || 0) + T.guideBase + T.guidePerChar * full.length;
      DL.cur.timer = setTimeout(next, Game.FX.ms(hold));
      // 표정이 여러 개면 머무는 동안 차례로 바꾼다 (예: 놀람 → 슬픔 → 텅 빔)
      if (faces.length > 1) {
        var me = DL.cur;
        faces.slice(1).forEach(function (fc, i) {
          var t = setTimeout(function () { if (DL.cur === me) Game.Assets.applyFace(faceEl, faceWho, 96, 1, fc); }, Game.FX.ms(hold * (i + 1) / faces.length));
          me.faceTimers = (me.faceTimers || []).concat(t);
        });
      }
    }
    DL.cur.finishTyping = finishTyping;
  }
  function next() {
    if (!DL.cur) return;
    clearTimeout(DL.cur.timer); clearInterval(DL.cur.typer);
    (DL.cur.faceTimers || []).forEach(clearTimeout);
    var r = DL.cur.resolve;
    DL.cur = null;
    if (r) r();
    pump();
  }
  DL.advance = function () {
    if (!DL.cur) return;
    if (DL.cur.typing) DL.cur.finishTyping();
    else next();
  };
  document.addEventListener('DOMContentLoaded', function () {
    $('dialog').addEventListener('pointerdown', function (e) { e.stopPropagation(); DL.advance(); });
  });

  // ───────── 튜토리얼 안내 ─────────
  G.reset = function () { G.done = {}; };
  // ctx: { enc, turn, card }
  G.fire = function (on, ctx) {
    ctx = ctx || {};
    var st = Game.Ctl.st, out = [];
    // 새 턴이 시작되면 아직 못 읽은 지난 안내는 버린다(밀려서 늦게 나오지 않게)
    if (on === 'turnStart') { DL.dropPending(); if (DL.cur) next(); }
    Game.DATA.guide.forEach(function (g) {
      if (g.on !== on) return;
      if (g.enc && g.enc !== ctx.enc) return;
      if (g.turn != null && g.turn !== ctx.turn) return;
      if (g.card && g.card !== ctx.card) return;
      if (g.once && G.done[g.id]) return;
      G.done[g.id] = true;
      g.lines.forEach(function (ln) {
        var a = st && st.party.allies[ln.who];
        if (a && a.status === 'dead') return;   // 죽은 동료는 말하지 않는다
        out.push(ln);
      });
    });
    return DL.say(out);
  };
})(window);
