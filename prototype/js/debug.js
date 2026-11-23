/*
 * debug.js — 디버그 패널 (` 백틱 또는 F9로 열고 닫기) + 자동 테스트용 훅(Game.debug)
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var DBG = Game.debug = {};
  var R = Game.Rules;

  function C() { return Game.Ctl; }
  function $(id) { return document.getElementById(id); }

  // ───────── 훅 ─────────
  DBG.jump = async function (scene) {
    Game.Dialog.clear();
    Game.Input.cancelDrag();
    C().busy = false;
    switch (scene) {
      case 'title': Game.Scenes.title(); break;
      case 'camp': C().newGame(); Game.Scenes.camp().then(function () { return C().startNormal(); }); break;
      case 'normal': C().newGame(); await C().startNormal(); break;
      case 'giant': C().newGame(); C().st.battle = null; await C().startGiant(false); break;
      case 'cutscene':
        C().newGame(); C().st.battle = null; await C().startGiant(false);
        await DBG.waitIdle();
        var d = C().st.battle.hand.filter(function (u) { return C().st.cards[u].id === 'hero_death'; })[0];
        if (d) await C().playCard(d, {});
        break;
      case 'ending': Game.Scenes.ending(); break;
    }
  };
  DBG.waitIdle = function (timeout) {
    var t0 = Date.now();
    return new Promise(function (res, rej) {
      (function poll() {
        if (!C().busy) return res();
        if (Date.now() - t0 > (timeout || 30000)) return rej(new Error('waitIdle timeout'));
        setTimeout(poll, 50);
      })();
    });
  };
  DBG.setHp = function (who, hp) {
    var st = C().st;
    if (!st) return;
    R.debugSetHp(st, who, hp);
    if (Game.View.vm) { Game.View.syncFromState(st); Game.View.render(); }
  };
  DBG.setEnergy = function (v) {
    var st = C().st;
    if (!st || !st.battle) return;
    st.battle.energy = v;
    Game.View.syncFromState(st); Game.View.render();
  };
  DBG.addCard = async function (id) {
    var st = C().st;
    if (!st || !st.battle) return;
    await Game.View.play(R.debugAddCard(st, id));
  };
  DBG.win = async function () {
    var st = C().st;
    if (!st || !st.battle || C().busy) return;
    C().busy = true;
    await Game.View.play(R.debugWin(st));
    await C().afterAction();
  };
  DBG.endTurn = function () { return C().endTurn(); };
  DBG.setSpeed = function (s) { Game.FX.speed = s; };
  DBG.state = function () {
    var st = C().st, b = st && st.battle;
    return {
      scene: Game.Scenes.current || (C().inBattle ? 'battle' : null),
      busy: C().busy,
      battle: b ? { kind: b.kind, turn: b.turn, phase: b.phase, energy: b.energy, result: b.result,
        hand: b.hand.map(function (u) { return st.cards[u].id; }), handUids: b.hand.slice(),
        enemies: b.enemies.map(function (e) { return { id: e.id, hp: e.hp, alive: e.alive, intent: e.intent }; }) } : null,
      party: st ? { witch: st.party.witch.hp, allies: JSON.parse(JSON.stringify(st.party.allies)), deck: st.party.deck.map(function (u) { return st.cards[u].id; }) } : null,
      log: C().log.slice(-20)
    };
  };

  // ───────── 패널 ─────────
  DBG.init = function () {
    window.addEventListener('keydown', function (e) {
      if (e.code === 'Backquote' || e.key === 'F9') { e.preventDefault(); DBG.toggle(); }
    });
    // 키보드가 없는 휴대폰: 화면 오른쪽 위 구석(무대 x ≥ 1800, y ≤ 110)을 빠르게 3번 탭하면 열고 닫는다
    var taps = [];
    window.addEventListener('pointerdown', function (e) {
      if (e.target && e.target.closest && e.target.closest('#debugPanel')) return;
      var p = Game.Input.toStage(e.clientX, e.clientY), now = Date.now();
      if (p.x < 1800 || p.y > 110) { taps = []; return; }
      taps = taps.filter(function (t) { return now - t < 900; });
      taps.push(now);
      if (taps.length >= 3) { taps = []; DBG.toggle(); }
    }, true);
  };
  // 시험용: 손패 장수를 n장으로 (덱에서 뽑거나 버림 더미로 보낸다. 모자라면 카드를 만들어 넣는다)
  DBG.setHandSize = async function (n) {
    var st = C().st, b = st && st.battle;
    if (!b) return;
    while (b.hand.length > n) {
      var i = b.hand.findIndex(function (u) { return !R.def(st, u).retain; });
      if (i < 0) i = b.hand.length - 1;
      b.discard.push(b.hand.splice(i, 1)[0]);
    }
    var pool = ['curse_flame', 'snipe', 'cover', 'foresight', 'shield_bash', 'fate_shift'];
    while (b.hand.length < n) R.debugAddCard(st, pool[b.hand.length % pool.length]);
    Game.View.syncFromState(st);
    Game.View.render();
  };
  DBG.toggle = function () {
    var p = $('debugPanel');
    if (p.classList.contains('hidden')) { DBG.renderPanel(); p.classList.remove('hidden'); }
    else p.classList.add('hidden');
  };

  DBG.renderPanel = function () {
    var p = $('debugPanel'), st = C().st, b = st && st.battle;
    var h = '<h3>장면 바로 가기</h3>' +
      ['title:타이틀', 'camp:캠프', 'normal:일반 전투', 'giant:거대 존재', 'cutscene:컷신', 'ending:종료'].map(function (x) {
        var k = x.split(':'); return '<button data-jump="' + k[0] + '">' + k[1] + '</button>';
      }).join('') +
      '<h3>전투</h3><button data-act="win">전투 즉시 승리</button><button data-act="end">턴 종료</button>' +
      '<div class="row"><label>에너지</label><input type="number" id="dbgEnergy" value="' + (b ? b.energy : 3) + '"><button data-act="energy">적용</button></div>' +
      '<div class="row"><label>연출 속도</label><input type="number" id="dbgSpeed" step="0.5" value="' + Game.FX.speed + '"><button data-act="speed">적용</button></div>' +
      '<h3>HP 수정</h3>';
    if (st) {
      var rows = [['witch', '노엘', st.party.witch.hp]];
      st.party.order.forEach(function (id) { rows.push([id, Game.DATA.party.allies[id].name, st.party.allies[id].hp]); });
      if (b) b.enemies.forEach(function (e) { if (e.maxHp != null) rows.push([e.id, e.name + ' ' + e.id, e.hp]); });
      rows.forEach(function (r) {
        h += '<div class="row"><label>' + r[1] + '</label><input type="number" data-hp="' + r[0] + '" value="' + r[2] + '"><button data-sethp="' + r[0] + '">적용</button></div>';
      });
    } else h += '<div>게임 시작 전</div>';
    h += '<h3>카드 손패에 추가</h3><div class="row"><select id="dbgCard">' +
      Object.keys(Game.DATA.cards).map(function (id) { return '<option value="' + id + '">' + Game.DATA.cards[id].name + ' (' + id + ')</option>'; }).join('') +
      '</select><button data-act="draw">추가</button></div>';
    h += '<h3>그림 파일 상태</h3><div class="assets">' + Object.keys(Game.Assets.status).map(function (k) {
      var ok = Game.Assets.status[k].ok; return '<div class="' + (ok ? 'ok' : 'miss') + '">' + (ok ? '✔ ' : '✘ 없음 ') + k + '</div>';
    }).join('') + '</div>';
    h += '<h3>상태</h3><div class="state">' + JSON.stringify(DBG.state(), null, 1).slice(0, 2400) + '</div>';
    h += '<div style="margin-top:8px"><button data-act="refresh">새로고침</button><button data-act="close">닫기 (`)</button></div>';
    p.innerHTML = h;
    p.onclick = function (e) {
      var t = e.target;
      if (t.dataset.jump) { DBG.jump(t.dataset.jump); setTimeout(DBG.renderPanel, 600); return; }
      if (t.dataset.sethp) { DBG.setHp(t.dataset.sethp, +p.querySelector('[data-hp="' + t.dataset.sethp + '"]').value); DBG.renderPanel(); return; }
      switch (t.dataset.act) {
        case 'win': DBG.win(); break;
        case 'end': DBG.endTurn(); break;
        case 'energy': DBG.setEnergy(+$('dbgEnergy').value); break;
        case 'speed': DBG.setSpeed(+$('dbgSpeed').value || 1); break;
        case 'draw': DBG.addCard($('dbgCard').value); break;
        case 'refresh': DBG.renderPanel(); break;
        case 'close': DBG.toggle(); break;
      }
    };
    p.onpointerdown = function (e) { e.stopPropagation(); };
  };
})(window);
