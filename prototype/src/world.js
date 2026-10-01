/* 저주 매입합니다 — 학교 필드(아르피아식 탐험 지도)의 지형·물체·규칙. 화면 코드와 분리되어 Node 테스트에서도 실행된다.
 * 타일 기호: # 벽(정원·미로는 산울타리)  . 바닥  , 길(실내는 카펫)  T 나무  ~ 물  = 책장  d 책상  k 칠판
 *           * 꽃(지나갈 수 있음)  E 출입구  1~4 분수 룬 판  o 누름판  G 금서 칸 철문 */
(function () {
  'use strict';
  const W = (globalThis.W = globalThis.W || {});
  const D = W.DATA, R = W.rules, T = D.TUNING;
  const key = (x, y) => x + ',' + y;
  const DIRS = [[0, -1], [1, 0], [0, 1], [-1, 0]];

  // 분수 룬 판: 번호 → 그림. 정답 순서는 도서관 책에 적혀 있다.
  const PLATES = { 1: { name: '해', glyph: '☀' }, 2: { name: '별', glyph: '★' }, 3: { name: '달', glyph: '☾' }, 4: { name: '구름', glyph: '☁' } };
  const PLATE_ORDER = [3, 1, 2, 4];
  const CART_START = [[4, 9], [6, 9]];
  const LIB_PLATES = [[2, 7], [8, 7]];
  const MAZE_ENEMIES = [['giggledoll', 3], ['mirrorbat', 3], ['shroomella', 3], ['waxslime', 2], ['teacup', 1]];

  // 출입구: to = 다른 구역(at = 도착 칸) 또는 screen(매점처럼 별도 화면)
  const AREAS = {
    garden: {
      name: '안뜰 정원', theme: 'garden',
      rows: [
        '#####E#####',
        '#T*.,,,.*T#',
        '#...,,,...#',
        '#T..,,,..T#',
        'E,,,,,,,,,E',
        '#...,,,...#',
        '#..1,,,2..#',
        '#..,~~~,..#',
        '#.,,~~~,,.#',
        '#..,~~~,..#',
        '#..3,,,4..#',
        '#...,,,...#',
        '#T..,,,..T#',
        '#*..,,,..*#',
        '#...,,,...#',
        '#T..,,,..T#',
        '#####E#####',
      ],
      exits: [
        { x: 5, y: 0, to: 'hall', at: [5, 9], label: '본관' },
        { x: 0, y: 4, to: 'maze', at: [13, 9], label: '밤의 미로' },
        { x: 10, y: 4, to: 'club', at: [1, 4], label: '부실' },
        { x: 5, y: 16, screen: 'gate', label: '봉인 창고' },
      ],
      objects: [
        { id: 'well', kind: 'thing', sprite: 'well', x: 9, y: 8, label: '마른 우물' },
        { id: 'gardener', kind: 'npc', npc: 'gardener', x: 8, y: 13, label: '송이 아저씨' },
      ],
    },
    hall: {
      name: '본관 복도', theme: 'hall',
      rows: [
        '#####E#####',
        '#....,....#',
        'E....,....E',
        '#....,....#',
        '#*...,...*#',
        'E,,,,,,,,,E',
        '#....,....#',
        '#....,....#',
        'E....,....#',
        '#*...,...*#',
        '#####E#####',
      ],
      exits: [
        { x: 5, y: 0, to: 'library', at: [5, 11], label: '도서관' },
        { x: 0, y: 2, screen: 'shop', label: '매점' },
        { x: 10, y: 2, screen: 'infirmary', label: '양호실' },
        { x: 0, y: 5, to: 'class1', at: [7, 4], label: '기본마법반' },
        { x: 10, y: 5, to: 'class2', at: [1, 4], label: '고급마법반' },
        { x: 0, y: 8, to: 'music', at: [8, 4], label: '음악실' },
        { x: 5, y: 10, to: 'garden', at: [5, 1], label: '정원' },
      ],
      objects: [
        { id: 'portraits', kind: 'npc', npc: 'portraits', x: 8, y: 1, label: '초상화 자매' },
      ],
    },
    club: {
      name: '저주골동품부 부실', theme: 'club',
      rows: [
        '#########',
        '#==...==#',
        '#.......#',
        '#.......#',
        'E.......#',
        '#.......#',
        '#.......#',
        '#.......#',
        '#########',
      ],
      exits: [{ x: 0, y: 4, to: 'garden', at: [9, 4], label: '정원' }],
      objects: [
        { id: 'desk', kind: 'thing', sprite: 'cauldron', x: 4, y: 2, label: '정화대' },
        { id: 'bed', kind: 'thing', sprite: 'bed', x: 7, y: 6, label: '침대' },
      ],
      customerSpots: [[3, 6], [5, 6]],
    },
    class1: {
      name: '기본마법반', theme: 'classroom',
      rows: [
        '#########',
        '#kkkkkkk#',
        '#.......#',
        '#.d.d.d.#',
        '#.......E',
        '#.d.d.d.#',
        '#########',
      ],
      exits: [{ x: 8, y: 4, to: 'hall', at: [1, 5], label: '복도' }],
      objects: [{ id: 'flam', kind: 'npc', npc: 'flam', x: 4, y: 2, label: '플람 교수', cls: 'basic' }],
    },
    class2: {
      name: '고급마법반', theme: 'classroom2',
      rows: [
        '#########',
        '#kkkkkkk#',
        '#.......#',
        '#.d.d.d.#',
        'E.......#',
        '#.d.d.d.#',
        '#########',
      ],
      exits: [{ x: 0, y: 4, to: 'hall', at: [9, 5], label: '복도' }],
      objects: [{ id: 'serena', kind: 'npc', npc: 'serena', x: 4, y: 2, label: '세레나 교수', cls: 'advanced' }],
    },
    music: {
      name: '음악실', theme: 'music',
      rows: [
        '##########',
        '#........#',
        '#........#',
        '#........#',
        '#........E',
        '#........#',
        '#........#',
        '#........#',
        '##########',
      ],
      exits: [{ x: 9, y: 4, to: 'hall', at: [1, 8], label: '복도' }],
      objects: [
        { id: 'piano', kind: 'thing', sprite: 'piano', x: 2, y: 1, label: '피아노', search: true },
        { id: 'bench', kind: 'thing', sprite: 'bench', x: 2, y: 2, label: '피아노 의자', search: true },
        { id: 'locker_a', kind: 'thing', sprite: 'locker', x: 6, y: 1, label: '사물함', search: true },
        { id: 'locker', kind: 'thing', sprite: 'locker', x: 7, y: 1, label: '포포의 사물함' },
        { id: 'locker_b', kind: 'thing', sprite: 'locker', x: 8, y: 1, label: '사물함', search: true },
        { id: 'stand', kind: 'thing', sprite: 'stand', x: 4, y: 4, label: '악보대', search: true },
        { id: 'drum', kind: 'thing', sprite: 'drum', x: 7, y: 6, label: '큰북', search: true },
        { id: 'curtain', kind: 'thing', sprite: 'curtain', x: 1, y: 6, label: '커튼', search: true },
        { id: 'trash', kind: 'thing', sprite: 'trash', x: 8, y: 7, label: '휴지통', search: true },
      ],
    },
    library: {
      name: '도서관', theme: 'library',
      rows: [
        '###########',
        '#===...===#',
        '#=.......=#',
        '#####G#####',
        '#=.......=#',
        '#=.......=#',
        '#...=.=...#',
        '#.o.....o.#',
        '#...=.=...#',
        '#.........#',
        '#.........#',
        '#=.......=#',
        '#####E#####',
      ],
      exits: [{ x: 5, y: 12, to: 'hall', at: [5, 1], label: '복도' }],
      objects: [
        { id: 'lectern', kind: 'thing', sprite: 'lectern', x: 5, y: 1, label: '금서 칸 독서대' },
        { id: 'libchest', kind: 'thing', sprite: 'chest', x: 8, y: 2, label: '금서 칸 상자' },
        { id: 'hintbook', kind: 'thing', sprite: 'book', x: 2, y: 4, label: '펼쳐진 책' },
      ],
      push: true,
    },
  };
  const AREA_IDS = Object.keys(AREAS).concat(['maze']);

  // ───────── 밤의 미로 (날마다 바뀐다) ─────────
  const MAZE_CACHE = {};
  const MAZE_W = 15, MAZE_H = 19;
  function genMaze(day) {
    if (MAZE_CACHE[day]) return MAZE_CACHE[day];
    const r = R.makeRng(9100 + day * 7919);
    const CW = 7, CH = 9, N = CW * CH;
    const tiles = Array.from({ length: MAZE_H }, () => Array(MAZE_W).fill('#'));
    const cid = (cx, cy) => cy * CW + cx;
    const cxy = (c) => [c % CW, Math.floor(c / CW)];
    const ct = (c) => { const [cx, cy] = cxy(c); return [cx * 2 + 1, cy * 2 + 1]; };
    for (let c = 0; c < N; c++) { const [x, y] = ct(c); tiles[y][x] = '.'; }
    const adj = Array.from({ length: N }, () => new Set());
    const nbs = (c) => { const [cx, cy] = cxy(c); return DIRS.map(([dx, dy]) => [cx + dx, cy + dy]).filter(([x, y]) => x >= 0 && y >= 0 && x < CW && y < CH).map(([x, y]) => cid(x, y)); };
    const carve = (a, b) => { adj[a].add(b); adj[b].add(a); const [ax, ay] = ct(a); const [bx, by] = ct(b); tiles[(ay + by) / 2][(ax + bx) / 2] = '.'; };
    const shuffle = (arr) => { for (let i = arr.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [arr[i], arr[j]] = [arr[j], arr[i]]; } return arr; };
    const start = cid(CW - 1, 4), center = cid(3, 4);
    const seen = new Array(N).fill(false);
    const stack = [start]; seen[start] = true;
    while (stack.length) {
      const cur = stack[stack.length - 1];
      const n = shuffle(nbs(cur).filter((x) => !seen[x]));
      if (n.length) { seen[n[0]] = true; carve(cur, n[0]); stack.push(n[0]); } else stack.pop();
    }
    // 고리 4개 (막다른 길만 있는 미로 방지)
    const pairs = [];
    for (let c = 0; c < N; c++) for (const n of nbs(c)) if (c < n && !adj[c].has(n)) pairs.push([c, n]);
    shuffle(pairs).slice(0, 4).forEach(([a, b]) => carve(a, b));
    const dist = new Array(N).fill(-1); dist[start] = 0;
    const q = [start];
    while (q.length) { const c = q.shift(); for (const n of adj[c]) if (dist[n] < 0) { dist[n] = dist[c] + 1; q.push(n); } }
    const used = new Set([start, center]);
    const deadEnds = shuffle([...Array(N).keys()].filter((c) => !used.has(c) && adj[c].size === 1));
    const chests = deadEnds.slice(0, 2).map((c) => { used.add(c); const [x, y] = ct(c); return { x, y }; });
    const mons = [];
    const cands = shuffle([...Array(N).keys()].filter((c) => !used.has(c) && dist[c] >= 3 && !adj[center].has(c)));
    for (const c of cands) {
      if (mons.length >= 4) break;
      const [x, y] = ct(c);
      mons.push({ x, y, enemy: R.weighted(MAZE_ENEMIES, r) });
      used.add(c);
    }
    tiles[9][MAZE_W - 1] = 'E';
    const [shx, shy] = ct(center);
    const m = {
      day, w: MAZE_W, h: MAZE_H, rows: tiles.map((row) => row.join('')),
      shed: { x: shx, y: shy }, chests, monsters: mons,
    };
    MAZE_CACHE[day] = m;
    return m;
  }
  function mazeState(s) {
    const f = s.field;
    if (!f.maze || f.maze.day !== s.day) {
      const m = genMaze(s.day);
      f.maze = { day: s.day, defeated: {}, opened: {}, revealed: new Array(m.w * m.h).fill(0), shed: false };
    }
    return f.maze;
  }
  function mazeArea(s) {
    const m = genMaze(s.day);
    const objects = [{ id: 'shed', kind: 'thing', sprite: 'shed', x: m.shed.x, y: m.shed.y, label: '오두막' }];
    return {
      id: 'maze', name: '밤의 미로', theme: 'maze', night: true, fog: true,
      rows: m.rows, w: m.w, h: m.h,
      exits: [{ x: m.w - 1, y: 9, to: 'garden', at: [1, 4], label: '정원' }],
      objects, maze: m,
    };
  }

  const AREA_CACHE = {};
  function area(s, id) {
    if (id === 'maze') return mazeArea(s);
    if (!AREA_CACHE[id]) {
      const a = AREAS[id];
      AREA_CACHE[id] = Object.assign({ id, w: a.rows[0].length, h: a.rows.length }, a);
    }
    return AREA_CACHE[id];
  }
  const cur = (s) => area(s, s.field.area);
  const tileAt = (a, x, y) => (x < 0 || y < 0 || x >= a.w || y >= a.h ? '#' : a.rows[y][x]);
  const SOLID_TILES = new Set(['#', 'T', '~', '=', 'd', 'k']);

  function carts(s) { return s.field.carts || CART_START.map((c) => c.slice()); }
  function cartAt(s, x, y) { return s.field.area === 'library' && carts(s).some(([cx, cy]) => cx === x && cy === y); }

  // 지금 구역에 있는 물체(정적 + 손님 + 미로 몬스터·상자)
  function objects(s) {
    const a = cur(s);
    const out = a.objects.slice();
    if (a.id === 'club') {
      R.customers(s).forEach((q, i) => {
        const [x, y] = a.customerSpots[i];
        out.push({ id: 'cust:' + q.id, kind: 'customer', npc: q.customer, qid: q.id, x, y, label: D.NPCS[q.customer].name });
      });
    }
    if (a.id === 'maze') {
      const st = mazeState(s);
      a.maze.chests.forEach((c) => { const k = key(c.x, c.y); out.push({ id: 'mchest:' + k, kind: 'thing', sprite: st.opened[k] ? 'chestOpen' : 'chest', x: c.x, y: c.y, label: '상자', opened: !!st.opened[k] }); });
      a.maze.monsters.forEach((m) => { const k = key(m.x, m.y); if (!st.defeated[k]) out.push({ id: 'mon:' + k, kind: 'monster', enemy: m.enemy, x: m.x, y: m.y, label: D.ENEMIES[m.enemy].name }); });
    }
    return out;
  }
  function objectAt(s, x, y) { return objects(s).find((o) => o.x === x && o.y === y) || null; }
  function exitAt(a, x, y) { return a.exits.find((e) => e.x === x && e.y === y) || null; }

  function isOpen(s, x, y) {
    const a = cur(s);
    const ch = tileAt(a, x, y);
    if (SOLID_TILES.has(ch)) return false;
    if (ch === 'G' && !s.field.libGate) return false;
    return true;
  }
  // 걸어서 지나갈 수 있는 칸인가 (물체·수레·몬스터는 막힘)
  function walkable(s, x, y) {
    if (!isOpen(s, x, y)) return false;
    if (cartAt(s, x, y)) return false;
    if (objectAt(s, x, y)) return false;
    return true;
  }

  // ───────── 안개 (미로) ─────────
  function revealed(s, x, y) {
    const a = cur(s);
    if (!a.fog) return true;
    return !!mazeState(s).revealed[y * a.w + x];
  }
  function reveal(s) {
    const a = cur(s);
    if (!a.fog) return;
    const st = mazeState(s);
    const rad = T.mazeSight + R.stats(s).sight;
    const { x, y } = s.field;
    for (let dy = -rad; dy <= rad; dy++) for (let dx = -rad; dx <= rad; dx++) {
      const tx = x + dx, ty = y + dy;
      if (tx >= 0 && ty >= 0 && tx < a.w && ty < a.h) st.revealed[ty * a.w + tx] = 1;
    }
  }

  // ───────── 이동 ─────────
  function enterArea(s, id, x, y) {
    s.field.area = id; s.field.x = x; s.field.y = y;
    s.field.plates = [];
    if (id === 'library' && !s.field.libGate) s.field.carts = null; // 다시 들어오면 수레가 제자리로
    if (id === 'maze') { mazeState(s); reveal(s); }
  }
  // 한 칸 이동. 반환: {type: blocked|moved|exit|battle|push|pushBlocked, ...}
  function step(s, nx, ny) {
    const f = s.field;
    const dx = nx - f.x, dy = ny - f.y;
    if (Math.abs(dx) + Math.abs(dy) !== 1) return { type: 'blocked' };
    const a = cur(s);
    const ex = exitAt(a, nx, ny);
    if (ex) return { type: 'exit', exit: ex };
    const obj = objectAt(s, nx, ny);
    if (obj && obj.kind === 'monster') return { type: 'battle', obj };
    if (obj) return { type: 'blocked', obj };
    if (cartAt(s, nx, ny)) return pushCart(s, nx, ny, dx, dy);
    if (!isOpen(s, nx, ny)) return { type: 'blocked' };
    f.x = nx; f.y = ny;
    reveal(s);
    const out = { type: 'moved' };
    const ch = tileAt(a, nx, ny);
    if (a.id === 'garden' && /[1-4]/.test(ch)) out.plate = plateStep(s, Number(ch));
    return out;
  }
  function pushCart(s, cx, cy, dx, dy) {
    const tx = cx + dx, ty = cy + dy;
    const a = cur(s);
    const ch = tileAt(a, tx, ty);
    if (s.field.libGate) return { type: 'blocked' };
    if (!isOpen(s, tx, ty) || ch === 'E' || ch === 'G' || cartAt(s, tx, ty) || objectAt(s, tx, ty)) return { type: 'pushBlocked' };
    const list = carts(s);
    const c = list.find(([x, y]) => x === cx && y === cy);
    c[0] = tx; c[1] = ty;
    s.field.carts = list;
    s.field.x = cx; s.field.y = cy;
    const out = { type: 'push', cart: [tx, ty], onPlate: LIB_PLATES.some(([px, py]) => px === tx && py === ty) };
    if (LIB_PLATES.every(([px, py]) => list.some(([x, y]) => x === px && y === py))) {
      s.field.libGate = true;
      out.gateOpened = true;
    }
    return out;
  }
  function resetCarts(s) { if (!s.field.libGate) s.field.carts = null; }
  function platesCovered(s) { return LIB_PLATES.filter(([px, py]) => carts(s).some(([x, y]) => x === px && y === py)).length; }

  // 분수 룬 판 순서
  function plateStep(s, n) {
    const f = s.field;
    if (f.fountain) return { result: 'done', n };
    const want = PLATE_ORDER[f.plates.length];
    if (n === want) {
      f.plates.push(n);
      if (f.plates.length === PLATE_ORDER.length) { f.fountain = true; return { result: 'solved', n }; }
      return { result: 'progress', n, count: f.plates.length };
    }
    if (f.plates.length && f.plates[f.plates.length - 1] === n) return { result: 'same', n };
    f.plates = n === PLATE_ORDER[0] ? [n] : [];
    return { result: 'reset', n };
  }

  // 길 찾기. target 이 물체·출입구면 그 칸까지(마지막 칸은 막혀 있어도 됨)
  function findPath(s, tx, ty) {
    return bfs(s, tx, ty, false) || bfs(s, tx, ty, true);
  }
  function bfs(s, tx, ty, allowMonsters) {
    const a = cur(s);
    const sx = s.field.x, sy = s.field.y;
    if (sx === tx && sy === ty) return [];
    const prev = new Map([[key(sx, sy), null]]);
    const q = [[sx, sy]];
    while (q.length) {
      const [x, y] = q.shift();
      for (const [dx, dy] of DIRS) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= a.w || ny >= a.h) continue;
        const k = key(nx, ny);
        if (prev.has(k)) continue;
        if (!revealed(s, nx, ny)) continue;
        const isTarget = nx === tx && ny === ty;
        const obj = objectAt(s, nx, ny);
        const mon = obj && obj.kind === 'monster';
        if (!isTarget) {
          if (exitAt(a, nx, ny)) continue;
          if (mon && !allowMonsters) continue;
          if (!mon && !walkable(s, nx, ny)) continue;
        } else if (!exitAt(a, nx, ny) && !obj && !walkable(s, nx, ny) && !cartAt(s, nx, ny)) continue;
        prev.set(k, [x, y]);
        if (isTarget) {
          const path = [];
          let c = [nx, ny];
          while (c && !(c[0] === sx && c[1] === sy)) { path.unshift(c); c = prev.get(key(c[0], c[1])); }
          return path;
        }
        if (mon) continue; // 몬스터 칸에서 걸음이 멈춘다(전투)
        q.push([nx, ny]);
      }
    }
    return null;
  }
  // 물체 옆 칸까지 가는 길 (가장 짧은 것)
  function pathToObject(s, o) {
    const f = s.field;
    if (Math.abs(o.x - f.x) + Math.abs(o.y - f.y) === 1) return [];
    let best = null;
    for (const [dx, dy] of DIRS) {
      const x = o.x + dx, y = o.y + dy;
      if (!walkable(s, x, y) || !revealed(s, x, y)) continue;
      const p = findPath(s, x, y);
      if (p && (!best || p.length < best.length)) best = p;
    }
    return best;
  }

  // ───────── 상호작용 ─────────
  const SEARCH = {
    piano: { text: '도— 레— 미— 낡은 피아노가 맑게 울렸다. 건반 사이엔 먼지뿐이다.' },
    stand: { text: '악보 귀퉁이에 쪽지가 끼워져 있다. 「사물함 열쇠는 내가 앉아서 연습하던 곳에 떨어뜨린 것 같아. — 포포」' },
    drum: { text: '둥! 북 속에서 은화가 굴러 나왔다.', silver: 8, once: true },
    curtain: { text: '커튼 뒤에는 누가 먹다 숨긴 사탕 껍질뿐이다. …으스스한 바람이 분다.' },
    trash: { text: '구겨진 악보 사이에서 해독 허브를 찾았다.', item: 'herb', once: true },
    locker_a: { text: '잠긴 사물함이다. 이름표: 「합창부 공용」.' },
    locker_b: { text: '잠긴 사물함이다. 안에서 트라이앵글이 땡그랑 울렸다.' },
    bench: { text: '의자 밑에 무언가 반짝인다… 음표 고리가 달린 작은 열쇠다!', key: true },
  };
  function search(s, id) {
    const sp = SEARCH[id];
    if (!sp) return { text: '별다른 것은 없다.' };
    const f = s.field;
    if (sp.key) {
      if (f.musicKey) return { text: '의자 밑에는 이제 아무것도 없다.' };
      f.musicKey = true;
      R.addItem(s, 'locker_key', 1);
      return { text: sp.text, item: 'locker_key', found: true };
    }
    if (sp.once && f.searched[id]) return { text: '이미 살펴본 곳이다.' };
    f.searched[id] = true;
    if (sp.silver) s.silver += sp.silver;
    if (sp.item) R.addItem(s, sp.item, 1);
    return { text: sp.text, silver: sp.silver, item: sp.item };
  }
  function fieldQuest(s, areaId, target) {
    return D.QUESTS.find((q) => q.objective.type === 'field' && q.objective.area === areaId && q.objective.target === target && s.quests[q.id].status === 'active') || null;
  }
  function useLocker(s) {
    const q = fieldQuest(s, 'music', 'locker');
    if (!q) {
      if (s.quests.q1.status === 'locked' || s.quests.q1.status === 'available') return { ok: false, text: '「포포」 이름표가 붙은 사물함. 주인 허락 없이 열면 안 되겠지.' };
      return { ok: false, text: '텅 빈 사물함이다.' };
    }
    if (!R.count(s, 'locker_key')) return { ok: false, text: '잠겨 있다. 음악실 어딘가에 떨어진 열쇠를 찾아야 한다.' };
    R.removeItem(s, 'locker_key', 1);
    R.completeObjective(s, q.id);
    return { ok: true, qid: q.id };
  }
  function useLectern(s) {
    const q = fieldQuest(s, 'library', 'lectern');
    if (!q) return { ok: false, text: '금서 칸 독서대. 펼쳐진 책은 없다.' };
    R.completeObjective(s, q.id);
    return { ok: true, qid: q.id };
  }
  function openLibChest(s) {
    if (s.field.libChest) return { ok: false, text: '텅 빈 상자다.' };
    s.field.libChest = true;
    s.silver += 30;
    R.addItem(s, 'mp_potion', 1);
    const a = R.addCursedAntique(s, 3, 'uncommon');
    return { ok: true, loot: { silver: 30, items: { mp_potion: 1 }, antiques: 1, antiqueList: [a] } };
  }
  function useWell(s) {
    if (!s.field.fountain) return { ok: false, text: '바싹 마른 우물. 뚜껑이 단단히 잠겨 있다. 분수 쪽 룬 판과 연결된 것 같다.' };
    if (s.field.well) return { ok: false, text: '우물 바닥에 이제 달빛만 고여 있다.' };
    s.field.well = true;
    s.silver += 40;
    const a = R.addCursedAntique(s, 5, 'rare');
    return { ok: true, loot: { silver: 40, items: {}, antiques: 1, antiqueList: [a] } };
  }
  function openMazeChest(s, x, y) {
    const st = mazeState(s);
    const k = key(x, y);
    if (st.opened[k]) return { ok: false, text: '이미 연 상자다.' };
    st.opened[k] = true;
    const loot = { silver: 0, items: {}, antiques: 0 };
    const roll = R.rand();
    if (roll < 0.3) loot.antiques = 1;
    else if (roll < 0.6) loot.silver = R.randInt(10, 20);
    else loot.items[R.weighted([['hp_potion', 4], ['mp_potion', 3], ['salt', 2], ['key', 1], ['dew', 2]])] = 1;
    s.silver += loot.silver;
    for (const id of Object.keys(loot.items)) R.addItem(s, id, loot.items[id]);
    loot.antiqueList = loot.antiques ? [R.addCursedAntique(s, 2)] : [];
    return { ok: true, loot };
  }
  function useShed(s) {
    const st = mazeState(s);
    const first = !s.flags.mazeCenter;
    s.flags.mazeCenter = true;
    const q = fieldQuest(s, 'maze', 'shed');
    if (q) { R.completeObjective(s, q.id); return { ok: true, qid: q.id, first }; }
    if (st.shed) return { ok: false, first, text: '오두막 안은 조용하다. 정원 도구들만 가지런하다.' };
    st.shed = true;
    s.silver += 15;
    return { ok: false, first, silver: 15, text: '오두막 탁자 위에 「미로를 끝까지 온 아이에게」라는 쪽지와 은화 15개가 놓여 있다.' };
  }
  function defeatMonster(s, x, y) { mazeState(s).defeated[key(x, y)] = true; }

  // ───────── 목표 안내: 지금 가야 할 구역과 그쪽 출입구 ─────────
  function targetArea(s) {
    if (!s.spells.length) return 'class1';
    if (!s.flags.metCustomer) return 'club';
    if (D.QUESTS.some((q) => R.canPurifyQuest(s, q.id))) return 'club';
    for (const q of R.activeQuests(s)) {
      if (s.quests[q.id].status !== 'active') continue;
      const o = q.objective;
      if (o.type === 'field') return o.area;
      if (o.type === 'defeat') return 'screen:gate';
      if (o.type === 'items') return 'screen:gate';
    }
    if (s.purified < 5 && R.customers(s).length) return 'club';
    const learn = R.learnableSpells(s)[0];
    if (learn) return D.CLASSES[D.SPELLS[learn].cls].area;
    return 'screen:gate';
  }
  // 현재 구역에서 target 으로 가는 첫 출입구
  function routeExit(s, target) {
    const tgt = target || targetArea(s);
    const from = s.field.area;
    if (tgt === from) return null;
    const prev = new Map([[from, null]]);
    const q = [from];
    while (q.length) {
      const id = q.shift();
      const a = area(s, id);
      for (const e of a.exits) {
        const to = e.to || 'screen:' + e.screen;
        if (prev.has(to)) continue;
        prev.set(to, { id, e });
        if (to === tgt) {
          let c = to;
          while (prev.get(c) && prev.get(c).id !== from) c = prev.get(c).id;
          return prev.get(c).e;
        }
        if (e.to) q.push(e.to);
      }
    }
    return null;
  }

  W.world = {
    AREAS, AREA_IDS, PLATES, PLATE_ORDER, LIB_PLATES, CART_START, SEARCH,
    area, cur, tileAt, objects, objectAt, exitAt, isOpen, walkable, revealed, reveal, enterArea, step,
    carts, cartAt, resetCarts, platesCovered, plateStep, findPath, pathToObject,
    search, useLocker, useLectern, openLibChest, useWell, openMazeChest, useShed, defeatMonster, mazeState, genMaze,
    fieldQuest, targetArea, routeExit,
  };
})();
