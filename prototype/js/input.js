/*
 * input.js — 하스스톤식 드래그
 *  · 대상 카드: 카드를 끌면 손에서 화살표 → 유효 대상 위에서 놓으면 사용
 *  · 대상 없는 카드: 손패 위쪽으로 끌어올려 놓으면 사용
 *  · 운명 전가: ① 적의 예고에 놓기 → ② 새로 맞을 아군 클릭 (우클릭·Esc: 취소)
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var I = Game.Input = { mode: 'idle', px: 0, py: 0, drag: null, hoverIntent: null };
  var R = Game.Rules;

  function H() { return Game.Hand; }
  function V() { return Game.View; }
  function C() { return Game.Ctl; }
  function L() { return Game.DATA.layout; }

  I.toStage = function (cx, cy) {
    var r = document.getElementById('stage').getBoundingClientRect();
    var s = r.width / 1920;
    return { x: (cx - r.left) / s, y: (cy - r.top) / s };
  };
  function battleReady() {
    var c = C();
    return c.inBattle && c.st && c.st.battle && c.st.battle.phase === 'player' && !c.st.battle.result && !Game.Scenes.current;
  }

  // 마우스·터치 모두 Pointer Events 로 같은 드래그. 터치에서는 마우스 올림(hover) 대신:
  //  · 카드를 누르고 있으면 확대, 끌면 사용 / 적 예고를 탭하면 대상 선 / 빈 곳을 탭하면 대사 넘김
  I.init = function () {
    var stage = document.getElementById('stage');
    stage.addEventListener('pointermove', onMove);
    stage.addEventListener('pointerdown', onDown);
    stage.addEventListener('pointerup', onUp);
    stage.addEventListener('pointercancel', function () { if (I.mode === 'drag') I.cancelDrag(); });
    // 마우스 우클릭은 취소. 터치의 길게 누르기(일부 브라우저가 contextmenu 를 보냄)는 무시
    stage.addEventListener('contextmenu', function (e) { e.preventDefault(); if (I.lastType === 'mouse') I.cancelDrag(); });
    window.addEventListener('keydown', function (e) { if (e.key === 'Escape') I.cancelDrag(); });
  };
  function isTouch(e) { return e.pointerType && e.pointerType !== 'mouse'; }
  // 터치는 손가락이 커서 적·예고·아군을 누르는 영역을 넓힌다(실제 화면 약 16px, 무대 좌표 최대 40)
  function setPointer(e) {
    I.lastType = e.pointerType || 'mouse';
    V().hitPad = isTouch(e) ? Math.min(40, 16 / (Game.stageScale || 1)) : 0;
  }
  function moveThresh() { return (I.lastType === 'mouse' ? 8 : 12) / Math.min(1, Game.stageScale || 1); }
  function setIntentHover(id) {
    I.hoverIntent = id;
    document.querySelectorAll('.intent.hover').forEach(function (el) { el.classList.remove('hover'); });
    if (id && V().els.intents[id]) V().els.intents[id].classList.add('hover');
  }

  function setPrompt(text) {
    var p = document.getElementById('pickPrompt');
    if (!text) { if (p) p.remove(); return; }
    if (!p) { p = document.createElement('div'); p.id = 'pickPrompt'; p.className = 'prompt'; document.getElementById('stage').appendChild(p); }
    p.textContent = text;
  }

  function onMove(e) {
    var p = I.toStage(e.clientX, e.clientY);
    I.px = p.x; I.py = p.y;
    if (!C().inBattle || !V().vm) return;
    if (I.mode === 'drag') { updateDrag(); return; }
    if (I.mode === 'pick') { var a = V().allyAt(p.x, p.y); V().hot(null, I.drag.choices.indexOf(a) >= 0 ? a : null); return; }
    if (isTouch(e)) return;   // 터치에는 마우스 올림이 없다(누르고 있으면 확대, 예고는 탭)
    // 마우스 올림
    var uid = H().hitTest(p.x, p.y);
    if (Game.Scenes.current) uid = null;
    H().setHover(uid);
    setIntentHover(uid ? null : V().intentAt(p.x, p.y));
  }

  function onDown(e) {
    if (e.button !== 0) return;
    setPointer(e);
    var p = I.toStage(e.clientX, e.clientY);
    I.px = p.x; I.py = p.y;
    if (I.mode === 'pick') {
      var a = V().allyAt(p.x, p.y);
      var d = I.drag;
      if (a && d.choices.indexOf(a) >= 0) {
        I.mode = 'busy';
        setPrompt(null);
        C().playCard(d.uid, { enemy: d.enemy, to: a });
      } else I.cancelDrag();
      return;
    }
    var inBattle = C().inBattle && V().vm && !Game.Scenes.current;
    if (!battleReady() || C().busy || I.mode !== 'idle') {
      if (inBattle && I.mode !== 'drag' && Game.Dialog.busy()) Game.Dialog.advance();   // 연출 중에도 빈 곳 탭 = 대사 넘김
      return;
    }
    var uid = H().hitTest(p.x, p.y);
    if (!uid) {
      var it = V().intentAt(p.x, p.y);
      // 터치: 예고를 탭하면 그 공격의 대상 선을 보여 준다(같은 예고를 다시 탭하거나 다른 곳을 탭하면 사라짐)
      if (isTouch(e)) setIntentHover(it && it !== I.hoverIntent ? it : null);
      if (!it && Game.Dialog.busy()) Game.Dialog.advance();   // 빈 곳 탭 = 대사 넘김
      return;
    }
    var st = C().st, def = R.def(st, uid);
    I.drag = { uid: uid, spec: def.target, start: p, moved: false, valid: R.validTargets(st, uid), hot: null };
    I.mode = 'drag';
    setIntentHover(null);
    try { document.getElementById('stage').setPointerCapture(e.pointerId); } catch (err) { /* 무시 */ }
    H().hoverUid = null;
    // 누르고 있는 동안은 확대해서 보여 주고(대상 없는 카드도), 끌기 시작하면 사용 조작으로
    H().liftedUid = uid;
    V().highlight(I.drag.valid, def.target, null);
    H().layout();
  }

  function updateDrag() {
    var d = I.drag;
    if (!d) return;
    if (Math.abs(I.px - d.start.x) + Math.abs(I.py - d.start.y) > moveThresh()) d.moved = true;
    if (d.spec === 'none') {
      if (!d.moved) return;
      if (H().dragMode !== 'follow') { H().liftedUid = null; H().dragUid = d.uid; H().dragMode = 'follow'; }
      H().dragPos = { x: I.px, y: I.py };
      H().layout();
      return;
    }
    var en = V().enemyAt(I.px, I.py);
    d.hot = en && d.valid.indexOf(en) >= 0 ? en : null;
    V().hot(d.hot, null);
  }

  function onUp(e) {
    if (e.button !== 0) return;
    if (I.mode !== 'drag') return;
    var d = I.drag, st = C().st;
    var p = I.toStage(e.clientX, e.clientY);
    I.px = p.x; I.py = p.y;
    if (!d.moved) { I.cancelDrag(); return; }
    var chk = R.canPlay(st, d.uid);
    if (d.spec === 'none') {
      if (p.y < L().playZoneY) {
        if (!chk.ok) { Game.FX.toast(chk.reason); I.cancelDrag(); return; }
        I.mode = 'busy';
        C().playCard(d.uid, {});
      } else I.cancelDrag();
      return;
    }
    updateDrag();
    if (!d.hot) {
      var over = V().enemyAt(p.x, p.y);
      if (!chk.ok) Game.FX.toast(chk.reason);
      else if (over || p.y < L().playZoneY) Game.FX.toast(d.spec === 'intent' ? '예고된 공격에 놓아야 한다' : '여기에는 낼 수 없다');
      I.cancelDrag();
      return;
    }
    if (!chk.ok) { Game.FX.toast(chk.reason); I.cancelDrag(); return; }
    if (R.needsSecondTarget(st, d.uid)) {
      d.enemy = d.hot;
      d.choices = R.redirectChoices(st, d.enemy);
      I.mode = 'pick';
      V().highlight(null, null, d.choices);
      V().hot(null, null);
      setPrompt('새로 맞을 아군을 고르세요 · 우클릭/Esc: 취소');
      return;
    }
    I.mode = 'busy';
    C().playCard(d.uid, { enemy: d.hot });
  }

  // 카드를 손패로 되돌린다
  I.cancelDrag = function () {
    I.mode = 'idle';
    I.drag = null;
    setPrompt(null);
    if (H().dragUid || H().liftedUid) { H().dragUid = null; H().dragMode = null; H().liftedUid = null; }
    if (V().vm) { V().highlight(null, null, null); V().hot(null, null); H().layout(); }
  };
  // 사용 확정 후 정리 (카드 요소는 연출이 처리)
  I.endDrag = function () {
    I.mode = 'idle';
    I.drag = null;
    setPrompt(null);
    if (V().vm) { V().highlight(null, null, null); V().hot(null, null); }
  };

  // ───────── 화살표·예고 선 ─────────
  // lift: 곡선이 위로 휘는 정도(손에서 위로 쏘는 화살표는 크게, 예고 선은 작게)
  function arrow(ctx, a, b, color, width, dashed, lift) {
    var mx = (a.x + b.x) / 2, my = lift == null ? Math.min(a.y, b.y) - 80 : (a.y + b.y) / 2 - lift;
    ctx.save();
    ctx.strokeStyle = color; ctx.lineWidth = width; ctx.lineCap = 'round';
    ctx.shadowColor = color; ctx.shadowBlur = 14;
    if (dashed) ctx.setLineDash(dashed);
    ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.quadraticCurveTo(mx, my, b.x, b.y); ctx.stroke();
    ctx.setLineDash([]);
    var ang = Math.atan2(b.y - my, b.x - mx), s = width * 3.2;
    ctx.fillStyle = color;
    ctx.beginPath(); ctx.moveTo(b.x, b.y);
    ctx.lineTo(b.x - Math.cos(ang - 0.45) * s, b.y - Math.sin(ang - 0.45) * s);
    ctx.lineTo(b.x - Math.cos(ang + 0.45) * s, b.y - Math.sin(ang + 0.45) * s);
    ctx.closePath(); ctx.fill();
    ctx.restore();
  }
  I.arrow = arrow;

  I.drawOverlay = function (ctx, now) {
    if (!C().inBattle || !V().vm) return;
    var d = I.drag;
    if (I.mode === 'drag' && d && d.spec !== 'none') {
      var from = H().topPoint(d.uid) || { x: 960, y: 700 };
      arrow(ctx, from, { x: I.px, y: I.py }, d.hot ? '#ffd36b' : '#ff3346', 9, [18, 10]);
    } else if (I.mode === 'drag' && d && d.spec === 'none') {
      var on = I.py < L().playZoneY;
      var g = ctx.createLinearGradient(0, L().playZoneY - 40, 0, L().playZoneY);
      g.addColorStop(0, 'rgba(255,40,60,0)'); g.addColorStop(1, on ? 'rgba(255,60,80,.35)' : 'rgba(255,60,80,.12)');
      ctx.fillStyle = g; ctx.fillRect(360, L().playZoneY - 40, 1200, 40);
      ctx.fillStyle = on ? 'rgba(255,220,220,.9)' : 'rgba(255,200,200,.5)';
      ctx.font = '700 20px ' + getComputedStyle(document.body).fontFamily;
      ctx.textAlign = 'center';
      ctx.fillText(on ? '놓으면 사용' : '위로 끌어올려 사용', 960, L().playZoneY - 12);
    } else if (I.mode === 'pick' && d) {
      var r = V().intentRect(d.enemy);
      var a = r ? { x: r.x + r.w / 2, y: r.y + r.h } : V().enemyCenter(d.enemy);
      arrow(ctx, a, { x: I.px, y: I.py }, '#ff3346', 6, [12, 8], 40);
    } else if (I.hoverIntent) {
      drawIntentLines(ctx, I.hoverIntent);
    }
  };
  function drawIntentLines(ctx, enemyId) {
    var it = V().vm.intents[enemyId], r = V().intentRect(enemyId);
    if (!it || !r) return;
    var a = { x: r.x + r.w / 2, y: r.y + r.h };
    var targets = it.target === 'all' ? ['witch'].concat(C().st.party.order.filter(function (id) { return V().vm.status[id] === 'ok'; })) : [it.target];
    targets.forEach(function (t) { arrow(ctx, a, V().targetPoint(t), 'rgba(255,60,75,.95)', 4, [10, 7], 40); });
  }
})(window);
