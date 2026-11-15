/*
 * controller.js — 장면 흐름과 전투 진행
 * 캠프 → 일반 전투 → 거대 존재 등장 → 거대 존재 전투 → (죽음 카드 → 컷신 → 짓밟힘 → 탈출 → 종료) / (전멸 → 등장 직후부터 재시작)
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var C = Game.Ctl = { st: null, busy: false, inBattle: false, snapGiant: null, snapNormal: null, seed: null, log: [] };
  var R = Game.Rules, FX = Game.FX;

  function D() { return Game.DATA; }
  function V() { return Game.View; }
  C.note = function (s) { C.log.push(s); if (C.log.length > 200) C.log.shift(); };

  C.newGame = function (seed) {
    C.st = R.newGame(seed != null ? seed : C.seed);
    Game.Guide.reset();
    C.snapGiant = null; C.snapNormal = null;
    C.note('newGame seed=' + C.st.seed);
    return C.st;
  };

  C.startTutorial = async function () {
    Game.Dialog.clear();
    C.newGame();
    await Game.Scenes.camp();
    await C.startNormal();
  };

  function setBusy(b) { C.busy = b; if (V().vm) V().render(); }

  // ───────── 일반 전투 ─────────
  C.startNormal = async function (fromSnapshot) {
    Game.Dialog.clear();
    Game.Scenes.clear();
    if (fromSnapshot && C.snapNormal) C.st = R.restore(C.snapNormal, C.st.rng);
    else {
      if (!C.st) C.newGame();
      R.startBattle(C.st, 'normal');
      C.snapNormal = R.snapshot(C.st);
    }
    setBusy(true);
    V().build(C.st);
    C.inBattle = true;
    C.note('battle normal');
    await FX.fade(0, 500);
    Game.Guide.fire('battleStart', { enc: 'normal' });
    await C.beginTurn();
  };

  // ───────── 거대 존재 전투 ─────────
  C.startGiant = async function (fromSnapshot) {
    Game.Dialog.clear();
    Game.Scenes.clear();
    if (fromSnapshot && C.snapGiant) {
      C.st = R.restore(C.snapGiant, C.st.rng);
    } else {
      if (!C.st) C.newGame();
      if (C.st.battle) await V().play(R.finishBattle(C.st));
      R.startBattle(C.st, 'giant');
      C.snapGiant = R.snapshot(C.st);
    }
    setBusy(true);
    V().build(C.st);
    C.inBattle = true;
    C.note('battle giant' + (fromSnapshot ? ' (restart)' : ''));
    await FX.fade(0, 500);
    if (fromSnapshot) await Game.Guide.fire('restart', {});
    await Game.Guide.fire('battleStart', { enc: 'giant' });
    await C.beginTurn();
  };

  C.beginTurn = async function () {
    setBusy(true);
    var b = C.st.battle;
    var ev = R.startTurn(C.st);
    await V().play(ev);
    Game.Guide.fire('turnStart', { enc: b.enc, turn: b.turn });
    setBusy(false);
  };

  // ───────── 카드 사용 ─────────
  C.playCard = async function (uid, target) {
    if (C.busy || !C.st || !C.st.battle) { Game.Input.cancelDrag(); return { ok: false, reason: 'busy' }; }
    var chk = R.canPlay(C.st, uid);
    if (!chk.ok) { FX.toast(chk.reason); Game.Input.cancelDrag(); return chk; }
    setBusy(true);
    var id = C.st.cards[uid].id;
    var res = R.play(C.st, uid, target);
    if (!res.ok) { FX.toast(res.reason); Game.Input.cancelDrag(); setBusy(false); return res; }
    Game.Input.endDrag();
    C.note('play ' + id + ' ' + JSON.stringify(target || {}));
    await V().play(res.events);
    Game.Guide.fire('cardPlayed', { enc: C.st.battle && C.st.battle.enc, card: id });
    var died = res.events.some(function (e) { return e.t === 'allyDeath'; });
    if (died) {
      await V().reactions();
      await Game.Guide.fire('afterDeath', {});
    }
    await C.afterAction();
    return res;
  };

  C.endTurn = async function () {
    if (C.busy || !C.st || !C.st.battle || C.st.battle.phase !== 'player' || C.st.battle.result) return;
    setBusy(true);
    Game.Input.cancelDrag();
    C.note('endTurn ' + C.st.battle.turn);
    var ev = R.endTurn(C.st);
    await V().play(ev);
    if (C.st.battle.result) { await C.afterAction(); return; }
    await C.beginTurn();
  };

  C.afterAction = async function () {
    var b = C.st.battle;
    if (!b) return;
    switch (b.result) {
      case 'giant':
        C.note('giant appears');
        await C.startGiant(false);
        return;
      case 'retreat':
        C.note('retreat → escape');
        C.inBattle = true;
        await Game.Scenes.escape();
        return;
      case 'win':
        await Game.Scenes.escape();
        return;
      case 'lose':
        C.note('wipe ' + b.kind);
        await FX.fade(1, 600);
        Game.Dialog.clear();
        C.inBattle = false;
        await Game.Scenes.wipe(b.kind);
        await FX.fade(1, 200);
        if (b.kind === 'giant') await C.startGiant(true);
        else await C.startNormal(true);
        return;
      default:
        setBusy(false);
    }
  };
})(window);
