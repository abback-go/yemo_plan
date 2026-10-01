// 빌드: src/* 를 HTML 한 파일로 합친다.
//  dist/index.html  — 단독 실행용 (휴대폰 브라우저에서 파일로 열거나 아무 정적 호스팅에 올려도 됨)
//  dist/artifact.html — claude.ai 아티팩트 게시용 (doctype/head/body 없이 내용만)
const fs = require('fs');
const path = require('path');
const src = (f) => fs.readFileSync(path.join(__dirname, 'src', f), 'utf8');
const JS_ORDER = ['data.js', 'rules.js', 'art.js', 'audio.js', 'ui.js', 'main.js'];
const css = src('style.css');
const js = JS_ORDER.map((f) => `/* ── ${f} ── */\n` + src(f)).join('\n');
if (js.includes('</script')) throw new Error('스크립트 안에 </script 문자열이 있으면 안 됩니다');
const head = `<title>저주 매입합니다</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Gowun+Dodum&family=Yeon+Sung&display=swap">
<style>
${css}
</style>`;
const body = `<div id="app"><div id="screen"></div><div id="overlay"></div><div id="sheet"></div><div id="dialog"></div><div id="toasts" aria-live="polite"></div></div>
<script>
${js}
</script>`;
const artifact = `${head}\n${body}\n`;
const standalone = `<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#140e1c">
<meta name="description" content="마녀학교 저주골동품부 — 저주 물건을 매입해 정화하는 세로형 탐험 RPG 프로토타입">
${head}
</head>
<body>
${body}
</body>
</html>
`;
fs.mkdirSync(path.join(__dirname, 'dist'), { recursive: true });
fs.writeFileSync(path.join(__dirname, 'dist', 'artifact.html'), artifact);
fs.writeFileSync(path.join(__dirname, 'dist', 'index.html'), standalone);
console.log(`빌드 완료: dist/index.html ${(standalone.length / 1024).toFixed(0)}KB, dist/artifact.html ${(artifact.length / 1024).toFixed(0)}KB`);
