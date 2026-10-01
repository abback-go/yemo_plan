// 브라우저용 스크립트(data.js, rules.js)를 Node에서 불러오는 테스트 하네스
const fs = require('fs');
const path = require('path');
const vm = require('vm');

function load() {
  const ctx = { console, Math, JSON, Date };
  ctx.globalThis = ctx;
  vm.createContext(ctx);
  for (const f of ['data.js', 'rules.js']) {
    const code = fs.readFileSync(path.join(__dirname, '..', 'src', f), 'utf8');
    vm.runInContext(code, ctx, { filename: f });
  }
  return ctx.W;
}

module.exports = { load };
