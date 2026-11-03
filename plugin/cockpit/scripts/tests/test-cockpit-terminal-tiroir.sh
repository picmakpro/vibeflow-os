#!/usr/bin/env bash
# test-cockpit-terminal-tiroir.sh — tiroir du terminal dans P : UI-SPEC §15, CSP de P, canal Q vers P côté P
# (TERM-01, TERM-05, TERM-07, T17 de TERM-12 ; P71-D-07, D-08, D-18, D-19 ; P71-D-20 : O1 B ; P71-D-21 : O6, O8 ; plan 71-07).
#   ST    statique : TU.13 (aucune adresse web écrite en entier, un seul fetch vers /api/vf/terminal, deux clés de stockage), T17.6 (aucun postMessage), T17.4 table
#         de accepteMessage (Node) + mutants M-MSG-ORIGINE, M-MSG-SOURCE, M-MSG-LISTE, M-MSG-CONFIANCE
#   TU    navigateur : TU.1 sans drapeau · TU.2 pastille, aucun cadre, /etat absente · TU.3 ouverture (cadre, barre, /etat vivante) · TU.4 raccourci à trois temps
#         et retour du focus · TU.5 poignée au clavier, rechargement · TU.6 Agrandir · TU.7 glissement souris · TU.8 thème par l'adresse du cadre · TU.9 O6 localhost
#         · TU.10 puce Windows · TU.11 injoignable après 8 s · TU.12 page hors Projet et Code
#   T8    T8.2 tiroir ouvert : 0 violation de CSP, ready reçu · T8.3 sans frame-src : violation, aucun ready (M-FRAMESRC)
#   T17   T17.1 témoin (messages réels de Q) · T17.2 postMessage de P ignoré · T17.3 MessageEvent forgé ignoré · T17.5 espion : liste fermée, aucun octet du shell (M-MSG-DONNEE)
# Mesure O8 (71-06-SUMMARY, MESURE-O8 minimal=bloque popups=ouvert opener=nul) + décision du manager : cinq jetons de sandbox, aucun autre.
# Sans Chrome : les sections statiques tournent, la suite annonce « SUITE SAUTÉE (navigateur) ». VF_TIROIR_MS : échéance d'une attente (20000). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin" "$WORK/run"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : TERM-05 et TERM-07 NON vérifiés, non comptés comme réussis"; fi

# shell de test (P71-PL-11) : marqué par son chemin, écrit son PID puis lance un shell interactif SANS exec (le PID reste celui du script)
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$WORK/run/shell.pid"
/bin/sh -i
SH
chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"; export VF_COCKPIT_TERM_GRACE_MS=5000
SANDBOX_O8="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox" # mesure O8 de 71-06 : popups ouvert, opener nul

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/harnais-msg.mjs" <<'JS'
// harnais-msg.mjs <sortie> : table de accepteMessage (T17.4) ; une ligne « nom=oui|non » par cas, « ABSENT » si la fonction n'existe pas
import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(`${process.argv[2]}/vf-cockpit-terminal-tiroir.mjs`).href);
if (typeof m.accepteMessage !== 'function') { console.log('ABSENT'); process.exit(0); }
const Q = 'http://127.0.0.1:4242', P = 'http://127.0.0.1:4141', F = {}, L = m.LISTE_MESSAGES || [];
const base = { isTrusted: true, origin: Q, source: F, data: 'toggle' };
const cas = [['accepte', {}], ['accepte-ready', { data: 'ready' }], ['origine-de-P', { origin: P }], ['origine-voisine', { origin: Q + '/' }], ['source-autre', { source: {} }], ['source-nulle', { source: null }],
  ['valeur-inconnue', { data: 'fermer-tout' }], ['objet', { data: { toggle: 1 } }], ['tableau', { data: ['toggle'] }], ['chaine-10000', { data: 'x'.repeat(10000) }],
  ['non-fiable', { isTrusted: false }], ['confiance-absente', { isTrusted: undefined }]];
console.log(cas.map(([n, d]) => `${n}=${m.accepteMessage({ ...base, ...d }, Q, F, L) === true ? 'oui' : 'non'}`).join(' '));
console.log('liste=' + [...L].sort().join(','));
JS
cat > "$AUX/scriptgen.mjs" <<'JS'
// scriptgen.mjs <sortie> <indisponible 0|1> : faits statiques du script injecté (contenu du <script>) ; une ligne JSON
import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(`${process.argv[2]}/vf-cockpit-terminal-tiroir.mjs`).href);
const h = m.injectionTiroir({ indisponible: process.argv[3] === '1' }) || '';
const s = (h.match(/<script>([\s\S]*?)<\/script>/) || [, ''])[1];
const adr = /https?:\/\//g;
console.log(JSON.stringify({
  taille: s.length, style: /<style>/.test(h), premiere: s.split('\n')[0],
  adresses: (s.match(adr) || []).length, temoin: ('x http://exemple.test y'.match(adr) || []).length,
  fetchs: (s.match(/\bfetch\s*\(/g) || []).length, api: s.includes('/api/vf/terminal'), postmsg: (s.match(/\bpostMessage\s*\(/g) || []).length,
  cles: [...new Set(s.match(/vf\.terminal\.[a-z]+/g) || [])].sort().join(','), cookie: (s.match(/document\s*\.\s*cookie/g) || []).length, echap: (s.match(/Escape|\bEsc\b/g) || []).length,
  allow: (s.match(/setAttribute\(\s*['"]allow['"]/g) || []).length,
}));
JS
cat > "$AUX/page-tiroir.mjs" <<'JS'
// page-tiroir.mjs <sortie> <port> <indisponible 0|1> : serveur jetable qui sert une page portant injectionTiroir() sous n'importe quel chemin
import http from 'node:http'; import { pathToFileURL } from 'node:url';
const [, , sortie, port, indispo] = process.argv;
const m = await import(pathToFileURL(`${sortie}/vf-cockpit-terminal-tiroir.mjs`).href);
const page = `<!doctype html><html><head><meta charset="utf-8"><script>window.VF_COCKPIT_SERVER={token:"t"};</script>${m.injectionTiroir({ indisponible: indispo === '1' }) || ''}</head><body><p id="x">page</p></body></html>`;
http.createServer((q, r) => {
  if (q.url.startsWith('/api/')) { r.writeHead(200, { 'Content-Type': 'application/json' }); return r.end('{"etat":"arrete"}'); }
  r.writeHead(200, { 'Content-Type': 'text/html' }); r.end(page);
}).listen(Number(port), '127.0.0.1');
JS
cat > "$AUX/chrome-tiroir.mjs" <<'JS'
// chrome-tiroir.mjs <chrome> <mode> <json> : scénarios navigateur du tiroir ; UNE ligne JSON. Modes : sans · flag · donnee · froid · localhost · page.
// Chaque étape est isolée (essai) ; en mode flag, la première étape en échec arrête le reste (les mesures absentes sont nommées dans `erreurs`).
// Gestes par Input.dispatchMouseEvent / Input.dispatchKeyEvent seulement. Le secret de session n'apparaît jamais en sortie.
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import { execFileSync } from 'node:child_process';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv;
const A = JSON.parse(brut);
const OP = `http://127.0.0.1:${A.P}`, OQ = A.Q ? `http://127.0.0.1:${A.Q}` : '', MS = Number(process.env.VF_TIROIR_MS) || 20000;
const erreurs = {}; let echec = false;
const essai = async (nom, f) => { if (echec) return undefined; try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 140); echec = true; return undefined; } };
const ESPION = `if (window.top === window) { window.__msgs = []; addEventListener('message', (e) => window.__msgs.push({ o: e.origin, d: typeof e.data === 'string' ? e.data.slice(0, 200) : '<' + typeof e.data + '>' })); }`;
const OUVERT = `(() => { const r = document.querySelector('.vf-term-tiroir'); return !!r && !r.hidden && r.getBoundingClientRect().height > 0; })()`;
const HAUT = `Math.round(document.querySelector('.vf-term-tiroir').getBoundingClientRect().height)`;
const MSG = (d) => `window.__msgs.some((m) => m.o === ${JSON.stringify(OQ)} && m.d === ${JSON.stringify(d)})`;

await executer(chrome, async (s) => {
  const att = (expr, nom, ms) => s.attendre(expr, nom, ms || MS);
  const prep = async () => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'dark' }] });
    await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: ESPION });
  };
  const centre = (sel) => s.ev(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
  const clic = async (sel) => { const c = await centre(sel); if (!c) throw new Error(`élément absent : ${sel}`); await souris('mouseMoved', c.x, c.y); await souris('mousePressed', c.x, c.y); await souris('mouseReleased', c.x, c.y); };
  const touche = async (key, code, vk, modifiers = 0) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, modifiers }); };
  const raccourci = () => touche(' ', 'Space', 32, 10);
  const texte = (sel) => s.ev(`(document.querySelector(${JSON.stringify(sel)}) || {}).textContent || ''`);

  if (mode === 'sans' || mode === 'localhost' || mode === 'page') {
    const url = mode === 'sans' ? `${OP}/${A.chemin || ''}` : mode === 'localhost' ? `http://localhost:${A.P}/project.html` : `http://127.0.0.1:${A.T}${A.chemin}`;
    await essai('page', async () => { await s.naviguer(url); await att(`document.readyState === 'complete'`, 'page chargée'); });
    if (A.attendre) { try { await att(`!!document.querySelector(${JSON.stringify(A.attendre)})`, 'nœud attendu', Math.min(MS, 8000)); } catch (e) { erreurs.attente = String(e.message).slice(0, 100); } }
    await pause(1200);
    const f = await s.ev(`(() => ({ vivante: document.readyState === 'complete' && document.body.children.length > 0, noeuds: document.querySelectorAll('[class*="vf-term"]').length,
      pastilles: document.querySelectorAll('button.vf-term-pastille').length, iframes: document.querySelectorAll('iframe').length,
      puce: (document.querySelector('.vf-term-puce') || {}).textContent || '', role: (document.querySelector('.vf-term-puce') || { getAttribute: () => '' }).getAttribute('role'),
      cles: Object.keys(localStorage).concat(Object.keys(sessionStorage)).filter((k) => k.indexOf('vf.terminal.') === 0).length, hote: location.hostname }))()`);
    return { erreurs, ...f };
  }

  await prep();
  if (mode === 'froid') {
    await essai('ouverture', async () => { await s.naviguer(`${OP}/project.html`); await att(`!!document.querySelector('button.vf-term-pastille')`, 'pastille'); await clic('button.vf-term-pastille'); });
    if (A.attendre === 'carte') await essai('carte', () => att(`!!document.querySelector('.vf-term-carte') && document.querySelector('.vf-term-carte').textContent.length > 0`, 'carte injoignable', 15000));
    else await essai('violation', async () => { const fin = Date.now() + MS; while (!s.violations.length && Date.now() < fin) await pause(100); await pause(2500); });
    return { erreurs, carte: await texte('.vf-term-carte').catch(() => ''), violations: [...s.violations], ready: await s.ev(MSG('ready')).catch(() => false), iframes: await s.ev(`document.querySelectorAll('iframe').length`).catch(() => -1) };
  }

  // --- flag / donnee : amorçage dans Chrome, secret lu sans démarrer le shell, puis P ---
  let secret = '';
  const r = { erreurs };
  const pid = () => { try { return fs.readFileSync(A.fichierPid, 'utf8').trim(); } catch { return ''; } };
  const session = () => { try { return JSON.parse(execFileSync('node', [A.TA, 'etat', String(A.Q), secret], { encoding: 'utf8' }).split('\n')[2] || '{}').session; } catch { return 'ERREUR'; } };
  await essai('amorcage', async () => {
    await s.naviguer(`${OQ}/#t=${A.amorce}`);
    await att(`location.port === '${A.P}' && location.pathname === '/project.html' && document.readyState === 'complete'`, 'arrivée sur P');
    await s.naviguer(`${OQ}/#t=${'0'.repeat(48)}`);
    await att(`((document.getElementById('etat') || {}).textContent || '').includes('Session expirée')`, 'carte Session expirée (échange refusé)');
    secret = await s.ev(`localStorage.getItem('vf.terminal.secret')`);
    if (!/^[0-9a-f]{64}$/.test(secret || '')) throw new Error('secret absent du stockage de Q');
  });
  await essai('P', async () => { await s.naviguer(`${OP}/project.html`); await att(`!!document.querySelector('button.vf-term-pastille')`, 'pastille Terminal'); });
  r.tu2 = await essai('tu2', async () => ({ ...(await s.ev(`(() => { const b = document.querySelector('button.vf-term-pastille'); return { n: document.querySelectorAll('button.vf-term-pastille').length, texte: b.textContent.trim(), aria: b.getAttribute('aria-label'), titre: b.title, iframes: document.querySelectorAll('iframe').length }; })()`)), etat: session() }));
  await essai('ouvreur', () => s.ev(`(() => { const b = document.createElement('button'); b.id = 'ouvreur'; b.textContent = 'o'; b.style.cssText = 'position:fixed;left:0;top:0;width:12px;height:12px;z-index:1'; document.body.appendChild(b); b.focus(); window.__annonces = []; new MutationObserver(() => window.__annonces.push(document.querySelector('.vf-term-annonce').textContent)).observe(document.querySelector('.vf-term-annonce'), { childList: true, characterData: true, subtree: true }); return true; })()`));
  // TU.3 / TU.4 temps 1 : le raccourci ouvre, le cadre est créé, le focus lui est donné
  await essai('ouvrir', async () => { await raccourci(); await att(OUVERT, 'tiroir ouvert'); await att(`document.activeElement && document.activeElement.tagName === 'IFRAME'`, 'focus au cadre'); await att(`${MSG('ready')} && ${MSG('etat:connecte')}`, 'ready puis etat:connecte'); });
  r.tu3 = await essai('tu3', async () => ({ ...(await s.ev(`(() => { const f = document.querySelector('iframe'); return { n: document.querySelectorAll('iframe').length, src: f.getAttribute('src'), title: f.title, sandbox: f.getAttribute('sandbox'), allow: f.hasAttribute('allow'),
    barre: (document.querySelector('.vf-term-etat') || {}).textContent, region: document.querySelector('.vf-term-tiroir').getAttribute('role') + '/' + document.querySelector('.vf-term-tiroir').getAttribute('aria-label'),
    annonce: window.__annonces[0], ready: ${MSG('ready')}, connecte: ${MSG('etat:connecte')} }; })()`)), etat: session(), violations: [...s.violations], pid: pid() }));
  if (A.court) { /* mode donnee : pas de gestes intermédiaires */ } else {
  await essai('tu4b', async () => { await s.ev(`document.getElementById('ouvreur').focus()`); await raccourci(); await pause(300);
    r.tu4b = await s.ev(`({ ouvert: ${OUVERT}, actif: document.activeElement.tagName })`); });
  await essai('tu4c', async () => { await raccourci(); await att(`!(${OUVERT})`, 'fermeture par le message toggle de Q'); await att(`document.activeElement && document.activeElement.id === 'ouvreur'`, 'focus rendu à l’ouvreur');
    r.tu4c = await s.ev(`({ ferme: !(${OUVERT}), focus: document.activeElement.id, toggle: ${MSG('toggle')}, annonce: (document.querySelector('.vf-term-annonce') || {}).textContent, inert: document.querySelector('.vf-term-tiroir').inert })`); });
  await essai('reouvrir', async () => { await clic('button.vf-term-pastille'); await att(OUVERT, 'tiroir rouvert au clic'); await pause(500); r.reouv = await s.ev(`({ iframes: document.querySelectorAll('iframe').length })`); r.reouv.pid = pid(); });
  await essai('tu5', async () => {
    r.h0 = await s.ev(HAUT); await s.ev(`document.querySelector('.vf-term-poignee').focus()`);
    await touche('ArrowUp', 'ArrowUp', 38); await touche('ArrowUp', 'ArrowUp', 38);
    r.tu5 = await s.ev(`({ h: ${HAUT}, now: document.querySelector('.vf-term-poignee').getAttribute('aria-valuenow'), stock: [localStorage.getItem('vf.terminal.h'), localStorage.getItem('vf.terminal.open')].join('/') })`);
    const pid1 = pid(); await s.send('Page.reload');
    await att(`${OUVERT} && ${MSG('etat:connecte')}`, 'tiroir rouvert et reconnecté après rechargement');
    r.tu5.reload = await s.ev(`({ h: ${HAUT}, iframes: document.querySelectorAll('iframe').length })`); r.tu5.pid = pid1 === pid() ? 'identique' : 'change:' + pid1 + '>' + pid();
  });
  await essai('tu6', async () => {
    r.h5 = await s.ev(HAUT); await clic('.vf-term-plein');
    r.tu6 = { pressed: await s.ev(`document.querySelector('.vf-term-plein').getAttribute('aria-pressed')`), aria: await s.ev(`document.querySelector('.vf-term-plein').getAttribute('aria-label')`), h: await s.ev(HAUT) };
    await clic('.vf-term-plein'); r.tu6.retour = await s.ev(`document.querySelector('.vf-term-plein').getAttribute('aria-pressed') + '/' + ${HAUT}`);
  });
  await essai('tu7', async () => {
    const c = await centre('.vf-term-poignee'); await souris('mouseMoved', c.x, c.y); await souris('mousePressed', c.x, c.y);
    for (let i = 1; i <= 8; i++) await souris('mouseMoved', c.x, c.y - 10 * i);
    r.tu7 = { pendant: await s.ev(`getComputedStyle(document.querySelector('iframe')).pointerEvents + '/' + document.body.classList.contains('resizing')`) };
    await souris('mouseReleased', c.x, c.y - 80);
    r.tu7.apres = await s.ev(`getComputedStyle(document.querySelector('iframe')).pointerEvents + '/' + document.body.classList.contains('resizing')`); r.tu7.h = await s.ev(HAUT);
  });
  await essai('tu8', async () => {
    const hist = await s.ev('history.length'), n0 = await s.ev(`window.__msgs.filter((m) => m.d === 'etat:connecte').length`), pid1 = pid();
    await s.ev(`document.documentElement.setAttribute('data-theme', 'light')`);
    const url = async () => { const t = (await s.send('Page.getFrameTree')).frameTree.childFrames || []; const f = t.find((c) => c.frame.url.indexOf(OQ) === 0); return f ? f.frame.url : ''; };
    const fin = Date.now() + MS; let u = ''; while (Date.now() < fin) { u = await url(); if (u.indexOf('theme=light') >= 0) break; await pause(100); }
    await att(`window.__msgs.filter((m) => m.d === 'etat:connecte').length > ${n0}`, 'reconnexion du cadre après la bascule');
    r.tu8 = { url: u.replace(OQ, 'Q'), histoire: hist === (await s.ev('history.length')) ? 'inchangee' : 'changee', pid: pid1 === pid() ? 'identique' : 'change' };
  });
  await essai('t172', async () => {
    r.t17 = { avant: await s.ev(OUVERT) };
    await s.ev(`postMessage('toggle', location.origin)`); await pause(600); r.t17.postMessage = await s.ev(OUVERT);
    await s.ev(`dispatchEvent(new MessageEvent('message', { data: 'toggle', origin: ${JSON.stringify(OQ)}, source: document.querySelector('iframe').contentWindow }))`); await pause(600); r.t17.forge = await s.ev(OUVERT);
  });
  }
  // T17.5 : saisie au clavier dans le cadre, relevé de l'espion
  await essai('t175', async () => {
    if (!(await s.ev(OUVERT))) { await clic('button.vf-term-pastille'); await att(OUVERT, 'tiroir ouvert pour la saisie'); }
    await s.ev(`document.querySelector('iframe').focus()`); await pause(400);
    for (const c of `echo ${A.marqueur} > ${A.fichierM}`) { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: c, text: c, unmodifiedText: c }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: c }); }
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 });
    const fin = Date.now() + MS; while (!fs.existsSync(A.fichierM) && Date.now() < fin) await pause(100);
    r.t175 = { fichier: fs.existsSync(A.fichierM) };
    await pause(800);
    const msgs = JSON.parse(await s.ev('JSON.stringify(window.__msgs)')), deQ = msgs.filter((m) => m.o === OQ), txt = JSON.stringify(msgs);
    r.t175 = { ...r.t175, de_q: deQ.length, hors_liste: deQ.filter((m) => !A.liste.includes(m.d)).length, marqueur: txt.includes(A.marqueur) ? 1 : 0, secret: txt.includes(secret) ? 1 : 0, amorce: txt.includes(A.amorce) ? 1 : 0, vus: [...new Set(deQ.map((m) => m.d))].sort().join(',') };
  });
  r.violations = [...s.violations];
  return r;
}, { csp: true });
JS
echo ok
rq() { node "$TA" req "$@"; }
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
SRVN=0
srv() { # srv <sortie> <0|1 terminal> -> SRV_PORT SRV_PID SRV_O SRV_OUT QP AMORCE ; serveur lancé directement depuis la sortie, comme le lanceur
  local o="$1" term="${2:-1}" lab flag=(); lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  if [ "$term" = 1 ]; then flag=(--terminal); AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce"); fi
  ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open ${flag[@]+"${flag[@]}"} --port "$(libre)" > "$SRV_OUT" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"port"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  if [ "$term" = 1 ]; then for _ in $(seq 1 50); do grep -q '"terminal"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done; fi
  SRV_PORT="$(sj j.port)"; SRV_PORT="${SRV_PORT:-0}"; QP="$(sj '(j.terminal&&j.terminal.url)||"http://127.0.0.1:0"')"; QP="${QP##*:}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
mutant() { # mutant <nom> <fichier-relatif-à-la-sortie> <expression-sed> -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
navig() { node "$AUX/chrome-tiroir.mjs" "$CHROME" "$@"; } # navig <mode> <json>
LISTE_JSON='["ready","etat:connecte","etat:reconnexion","etat:termine","etat:refuse","etat:expire","etat:arrete","toggle"]'
run_flag() { # run_flag <sortie> <court 0|1> -> FJ FP FQ ; un serveur neuf, un amorçage neuf, un Chrome neuf
  srv "$1" 1; FP=$SRV_PORT; FQ=$QP; FMARQ="MARQUEUR-P-$RANDOM$RANDOM"; rm -f "$WORK/run/m.txt" "$WORK/run/shell.pid"
  FJ="$(navig flag "{\"P\":$FP,\"Q\":$FQ,\"amorce\":\"$AMORCE\",\"marqueur\":\"$FMARQ\",\"fichierPid\":\"$WORK/run/shell.pid\",\"fichierM\":\"$WORK/run/m.txt\",\"TA\":\"$TA\",\"liste\":$LISTE_JSON,\"court\":$2}")"; unsrv
}

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

echo "=== ST — script injecté (statique) : TU.13, T17.6 ==="
node "$AUX/scriptgen.mjs" "$OUT" 0 > "$WORK/sg.out" 2>&1; SG="$(tail -n 1 "$WORK/sg.out")"
assert_eq "TU.13.0 — témoin : le script injecté existe (taille > 500), sa première ligne est l'en-tête VibeFlow (71-07), il vient avec sa feuille" "$(rj "$SG" '(j.taille>500)+"/"+j.premiere+"/"+j.style')" "true/// VibeFlow (71-07) : tiroir du terminal/true"
assert_eq "TU.13 — aucune adresse web écrite en entier dans le script injecté, commentaires compris (témoin : le motif trouve une adresse plantée)" "$(rj "$SG" 'j.adresses+"/"+j.temoin')" "0/1"
assert_eq "TU.13b — un seul fetch( et il vise /api/vf/terminal ; aucun cookie ; seules clés de stockage : vf.terminal.h et vf.terminal.open" "$(rj "$SG" '(j.taille>500)+"/"+j.fetchs+"/"+j.api+"/"+j.cookie+"/"+j.cles')" "true/1/true/0/vf.terminal.h,vf.terminal.open"
assert_eq "T17.6 — aucun postMessage( dans le script injecté (le sens P vers le cadre est fermé), aucun attribut allow posé, Échap jamais cité (le script est vivant)" "$(rj "$SG" '(j.taille>500)+"/"+j.postmsg+"/"+j.allow+"/"+j.echap')" "true/0/0/0"

echo "=== T17.4 — table de accepteMessage et mutants M-MSG-* ==="
ATT_TABLE="accepte=oui accepte-ready=oui origine-de-P=non origine-voisine=non source-autre=non source-nulle=non valeur-inconnue=non objet=non tableau=non chaine-10000=non non-fiable=non confiance-absente=non"
node "$AUX/harnais-msg.mjs" "$OUT" > "$WORK/h.out" 2>&1
assert_eq "T17.4 — accepté seulement : isTrusted, origine de Q exacte, source = le cadre, valeur de la liste ; refusés : origine de P ou voisine, autre source ou nulle, valeur inconnue, objet, tableau, 10 000 caractères, non fiable ou confiance absente" "$(sed -n 1p "$WORK/h.out")" "$ATT_TABLE"
assert_eq "T17.4b — LISTE_MESSAGES : exactement les huit valeurs de l'UI-SPEC §13" "$(sed -n 2p "$WORK/h.out")" "liste=etat:arrete,etat:connecte,etat:expire,etat:reconnexion,etat:refuse,etat:termine,ready,toggle"
mut_msg() { # mut_msg <nom> <expression-sed> <cas qui doit passer à « oui »>
  if mutant "$1" vf-cockpit-terminal-tiroir.mjs "$2"; then
    node "$AUX/harnais-msg.mjs" "$MUT_OUT" > "$WORK/hm-$1.out" 2>&1
    assert_eq "$1 — le mutant rougit T17.4 : le cas « $3 » est accepté" "$(sed -n 1p "$WORK/hm-$1.out" | tr ' ' '\n' | grep "^$3=")" "$3=oui"
  else sans_effet "$1"; fi
}
mut_msg M-MSG-ORIGINE 's|if (e.origin !== origineQ) return false;||' origine-de-P
mut_msg M-MSG-SOURCE 's|if (!fenetreCadre \|\| e.source !== fenetreCadre) return false;||' source-autre
mut_msg M-MSG-LISTE 's|typeof e.data === .string. && liste.indexOf(e.data) >= 0|typeof e.data === "string"|' valeur-inconnue
mut_msg M-MSG-CONFIANCE 's|if (!e \|\| e.isTrusted !== true) return false;|if (!e) return false;|' non-fiable

if [ -n "$CHROME" ]; then
echo "=== TU.1 — sans --terminal : rien (UI-SPEC §15.1) ==="
srv "$OUT" 0
for ch in "" "project.html"; do
  J="$(navig sans "{\"P\":$SRV_PORT,\"chemin\":\"$ch\"}")"
  assert_eq "TU.1 — sans le drapeau, /$ch : aucun nœud vf-term, aucune clé vf.terminal.*, aucun cadre (témoin : la page est chargée et vivante)" "$(rj "$J" '"vivante="+j.vivante+" noeuds="+j.noeuds+" cles="+j.cles+" iframes="+j.iframes')" "vivante=true noeuds=0 cles=0 iframes=0"
done
unsrv

echo "=== TU.2-TU.8 / T8.2 / T17 — avec --terminal : pastille, ouverture, raccourci, poignée, thème, canal ==="
run_flag "$OUT" 0; J="$FJ"; QQ="http://127.0.0.1:$FQ"
assert_eq "TU.0 — témoin : le scénario n'a pas échoué (aucune étape en erreur)" "$(rj "$J" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "TU.2 — pastille « Terminal » unique, aria-label et titre « Ouvrir le terminal (Ctrl+Maj+Espace) », aucun cadre, aucun shell (/etat absente)" "$(rj "$J" '"n="+j.tu2.n+" texte="+j.tu2.texte+" aria="+j.tu2.aria+" titre="+j.tu2.titre+" iframes="+j.tu2.iframes+" etat="+j.tu2.etat')" "n=1 texte=Terminal aria=Ouvrir le terminal (Ctrl+Maj+Espace) titre=Ouvrir le terminal (Ctrl+Maj+Espace) iframes=0 etat=absente"
assert_eq "TU.3 — ouverture : un cadre d'origine Q en ?theme=dark, title « Terminal », sandbox de la mesure O8 (cinq jetons), aucun attribut allow, région « Terminal », barre « Connecté », shell vivant" "$(rj "$J" '"n="+j.tu3.n+" src="+j.tu3.src+" title="+j.tu3.title+" sandbox="+j.tu3.sandbox+" allow="+j.tu3.allow+" region="+j.tu3.region+" barre="+j.tu3.barre+" etat="+j.tu3.etat')" "n=1 src=$QQ/?theme=dark title=Terminal sandbox=$SANDBOX_O8 allow=false region=region/Terminal barre=Connecté etat=vivante"
assert_eq "T8.2 — tiroir ouvert : 0 violation de CSP dans P, ready puis etat:connecte reçus" "$(rj "$J" '"violations="+j.tu3.violations.length+" ready="+j.tu3.ready+" connecte="+j.tu3.connecte')" "violations=0 ready=true connecte=true"
assert_eq "TU.4 — temps 1 : le raccourci ouvre (annonce « Terminal ouvert »), le focus est au cadre ; temps 2 : focus ailleurs dans P, le raccourci rend le focus au cadre sans fermer" "$(rj "$J" 'j.tu3.annonce+" / ouvert="+j.tu4b.ouvert+" actif="+j.tu4b.actif')" "Terminal ouvert / ouvert=true actif=IFRAME"
assert_eq "TU.4 — temps 3 : dans le terminal, le raccourci ferme (message toggle de Q), annonce « Terminal fermé », tiroir inerte, focus rendu à l'ouvreur" "$(rj "$J" '"ferme="+j.tu4c.ferme+" focus="+j.tu4c.focus+" toggle="+j.tu4c.toggle+" annonce="+j.tu4c.annonce+" inert="+j.tu4c.inert')" "ferme=true focus=ouvreur toggle=true annonce=Terminal fermé inert=true"
assert_eq "TU.4b — ouvrir, fermer, ouvrir : un seul cadre, le même shell (PID du shell inchangé)" "$(rj "$J" 'j.reouv.iframes+"/"+((j.reouv.pid===j.tu3.pid&&j.tu3.pid!=="")?"meme-shell":"autre:"+j.reouv.pid+">"+j.tu3.pid)')" "1/meme-shell"
assert_eq "TU.5 — poignée au clavier : 320 px par défaut, deux flèches haut = +48 px, aria-valuenow suit, mémorisés (vf.terminal.h/open) ; rechargement : même hauteur, tiroir rouvert, même PID de shell" "$(rj "$J" '"h0="+j.h0+" h1="+j.tu5.h+" now="+j.tu5.now+" stock="+j.tu5.stock+" apres="+j.tu5.reload.h+"/"+j.tu5.reload.iframes+" shell="+j.tu5.pid')" "h0=320 h1=368 now=368 stock=368/1 apres=368/1 shell=identique"
assert_eq "TU.6 — Agrandir : aria-pressed vrai et libellé « Réduire le terminal », tiroir plus haut ; second clic : retour à la hauteur d'avant" "$(rj "$J" '"pressed="+j.tu6.pressed+" aria="+j.tu6.aria+" plus_haut="+(j.tu6.h>j.h5)+" retour="+j.tu6.retour')" "pressed=true aria=Réduire le terminal plus_haut=true retour=false/368"
assert_eq "TU.7 — glissement souris de 80 px vers le haut : cadre en pointer-events none et body.resizing pendant le geste, rendus après ; hauteur 368 + 80" "$(rj "$J" '"pendant="+j.tu7.pendant+" apres="+j.tu7.apres+" h="+j.tu7.h')" "pendant=none/true apres=auto/false h=448"
assert_eq "TU.8 — bascule de thème : l'adresse du cadre passe à ?theme=light, history.length inchangé, même PID de shell (P71-D-19)" "$(rj "$J" '"url="+j.tu8.url+" histoire="+j.tu8.histoire+" pid="+j.tu8.pid')" "url=Q/?theme=light histoire=inchangee pid=identique"
assert_eq "T17.1 — témoin : les vrais messages de Q agissent (toggle reçu : le tiroir s'est fermé ; etat:connecte : la barre dit « Connecté »)" "$(rj "$J" '"toggle="+j.tu4c.toggle+" ferme="+j.tu4c.ferme+" barre="+j.tu3.barre')" "toggle=true ferme=true barre=Connecté"
assert_eq "T17.2 — postMessage('toggle') émis par P vers elle-même : ignoré (tiroir ouvert avant et après)" "$(rj "$J" '"avant="+j.t17.avant+" apres="+j.t17.postMessage')" "avant=true apres=true"
assert_eq "T17.3 — MessageEvent forgé (origine de Q, source = le cadre) : ignoré, car non fiable (tiroir ouvert avant et après)" "$(rj "$J" '"avant="+j.t17.avant+" apres="+j.t17.forge')" "avant=true apres=true"
assert_eq "T17.5 — espion : après une commande tapée dans le shell, tout message d'origine Q est dans la liste fermée ; ni le marqueur, ni le secret, ni l'amorçage n'y figurent (témoin : la commande a tourné)" "$(rj "$J" '"fichier="+j.t175.fichier+" hors_liste="+j.t175.hors_liste+" marqueur="+j.t175.marqueur+" secret="+j.t175.secret+" amorce="+j.t175.amorce+" ready_et_connecte="+(j.t175.vus.includes("ready")&&j.t175.vus.includes("etat:connecte"))')" "fichier=true hors_liste=0 marqueur=0 secret=0 amorce=0 ready_et_connecte=true"

echo "=== TU.9 / TU.10 / TU.12 — localhost, Windows, autres pages ==="
srv "$OUT" 1
J="$(navig localhost "{\"P\":$SRV_PORT,\"attendre\":\".vf-term-puce\"}")"; unsrv
assert_eq "TU.9 — P ouvert par localhost : le message d'O6 (P71-D-21) dans une puce, ni pastille ni cadre" "$(rj "$J" '"hote="+j.hote+" puce="+j.puce+" pastilles="+j.pastilles+" iframes="+j.iframes')" "hote=localhost puce=Ouvrez le cockpit à l'adresse 127.0.0.1 pour utiliser le terminal. pastilles=0 iframes=0"
PORT_T="$(libre)"; node "$AUX/page-tiroir.mjs" "$OUT" "$PORT_T" 1 & PID_T=$!; PIDS+=($PID_T); sleep 1
J="$(navig page "{\"P\":0,\"T\":$PORT_T,\"chemin\":\"/project.html\",\"attendre\":\".vf-term-puce\"}")"; vf_hyg_stop "$PID_T"
assert_eq "TU.10 — Windows (indisponible) : puce « Terminal indisponible sous Windows. » en role status, ni pastille ni cadre" "$(rj "$J" '"puce="+j.puce+" role="+j.role+" pastilles="+j.pastilles+" iframes="+j.iframes')" "puce=Terminal indisponible sous Windows. role=status pastilles=0 iframes=0"
PORT_T="$(libre)"; node "$AUX/page-tiroir.mjs" "$OUT" "$PORT_T" 0 & PID_T=$!; PIDS+=($PID_T); sleep 1
J="$(navig page "{\"P\":0,\"T\":$PORT_T,\"chemin\":\"/project.html\",\"attendre\":\"[class*=vf-term]\"}")"; JA="$(navig page "{\"P\":0,\"T\":$PORT_T,\"chemin\":\"/autre.html\"}")"; vf_hyg_stop "$PID_T"
assert_eq "TU.12 — la même injection : des nœuds sous /project.html (témoin), aucun nœud, aucune clé et aucun cadre sous /autre.html" "$(rj "$J" '"projet_noeuds>0="+(j.noeuds>0)')/$(rj "$JA" '"vivante="+j.vivante+" noeuds="+j.noeuds+" cles="+j.cles+" iframes="+j.iframes')" "projet_noeuds>0=true/vivante=true noeuds=0 cles=0 iframes=0"

echo "=== TU.11 / T8.3 — cadre injoignable, frame-src absent (mutants jouées en navigateur) ==="
if mutant injoignable vf-cockpit-terminal.mjs "s|{ etat: 'actif', port: portQ }|{ etat: 'actif', port: 1 }|"; then
  srv "$MUT_OUT" 1; J="$(navig froid "{\"P\":$SRV_PORT,\"attendre\":\"carte\"}")"; unsrv
  assert_eq "TU.11 — aucun ready : après 8 s, carte « Le terminal ne répond pas. Relancez /vf-cockpit --terminal. »" "$(rj "$J" '"carte="+j.carte+" ready="+j.ready')" "carte=Le terminal ne répond pas. Relancez /vf-cockpit --terminal. ready=false"
else sans_effet "TU.11 (injection de panne)"; fi
if mutant framesrc vf-cockpit-terminal.mjs "s#frameSrc: () => (portQ ? \`; frame-src http://127\.0\.0\.1:\${portQ}\` : ''),#frameSrc: () => '',#"; then
  srv "$MUT_OUT" 1; J="$(navig froid "{\"P\":$SRV_PORT,\"attendre\":\"violation\"}")"; unsrv
  assert_eq "T8.3 / M-FRAMESRC — copie de sortie sans frame-src : une violation de CSP relevée, aucun ready reçu" "$(rj "$J" '"violation="+(j.violations.length>=1)+" ready="+j.ready')" "violation=true ready=false"
else sans_effet "M-FRAMESRC"; fi

echo "=== M-MSG-DONNEE — client de Q qui joint du texte du terminal à un message (T17.5) ==="
if mutant donnee vf-cockpit-terminal-client.mjs 's|term.write(m.value);|term.write(m.value); window.parent.postMessage(new TextDecoder().decode(m.value), cfg.origineP);|'; then
  run_flag "$MUT_OUT" 1; J="$FJ"
  assert_eq "M-MSG-DONNEE — le mutant rougit T17.5 : un message hors liste ou portant le marqueur arrive à P (témoin : la commande a tourné)" "$(rj "$J" '"fichier="+j.t175.fichier+" rouge="+(j.t175.hors_liste>=1||j.t175.marqueur>=1)')" "fichier=true rouge=true"
else sans_effet "M-MSG-DONNEE"; fi
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
