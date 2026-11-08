#!/usr/bin/env bash
# test-cockpit-terminal-tiroir.sh — tiroir du terminal dans P : UI-SPEC §15, CSP de P, canal Q vers P côté P
# (TERM-01, TERM-05, TERM-07, T17 de TERM-12 ; P71-D-07, D-08, D-18, D-19 ; P71-D-20 : O1 B ; P71-D-21 : O6, O8 ; plan 71-07).
#   ST    statique : TU.13 (aucune adresse web écrite en entier, un seul fetch vers /api/vf/terminal, deux clés de stockage), T17.6 (aucun postMessage), T17.4 table
#         de accepteMessage (Node) + mutants M-MSG-ORIGINE, M-MSG-SOURCE, M-MSG-LISTE, M-MSG-CONFIANCE
#   TU    navigateur : TU.1 sans drapeau · TU.2 pastille, aucun cadre, /etat absente · TU.3 ouverture (cadre, barre, /etat vivante) · TU.4 raccourci à trois temps
#         et retour du focus · TU.5 poignée au clavier, rechargement · TU.6 Agrandir · TU.7 glissement souris · TU.8 thème par l'adresse du cadre · TU.9 O6 localhost
#         · TU.10 puce Windows · TU.11 injoignable après 8 s · TU.12 page hors Projet et Code
#   T8    T8.2 tiroir ouvert : 0 violation de CSP, ready reçu · T8.3 sans frame-src : violation, aucun ready (M-FRAMESRC)
#   T20   critique design 71 (lot A1) : J1 libellé de la barre = état de la carte (refusé, expiré) · J4 focus de la poignée sur le grip · J5 commande et point jamais coupés
#         (cartes de P et de Q, balayage de largeurs) · J6 aucun terminal sous la carte « déjà ouvert » · J7 boutons de la barre >= 44 px sous pointer: coarse · J13 pas de bague
#         de focus sur une carte d'alerte focalisée par programme
#   T21   recette 71 (E2, G1 ; P71-D-34, P71-D-35) : zoom jamais sous la pastille, atteignable tiroir ouvert · « Ajuster » et cadrage initial au-dessus du tiroir · #ask rangée · visite fermée ;
#         huit relevés (2 pages x 2 fenêtres x 2 thèmes) + mutants M-PASTILLE-SUR-ZOOM, M-AJUSTE-SANS-TIROIR, M-ASK-RESTE, M-VISITE-RESTE ;
#         T21.7/T21.8 (71.5, P71.5-D-06) : la pastille fermée ne recouvre ni la barre de question, ni la feuille de détail, ni le zoom, ni la visite (de 390 à 1280 px, panneau ouvert,
#         fermé, rouvert, visite affichée, état tactile) + témoin d'atteinte ; mutants M-PASTILLE-SUR-ASK et M-PASTILLE-SANS-RAPPEL
#   T22   recette 71 (G4 ; P71-D-37) : hauteur par défaut = 36 % de la fenêtre (220 à 380 px), bande de carte >= moitié de la fenêtre en 1280x720, hauteur mémorisée plafonnée à 70 %,
#         la fenêtre qui rétrécit ; mutants M-HAUTEUR-FIXE-320, M-MEMO-NON-BORNEE
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
// 72-14 : la phase 71 garde ses huit valeurs (ligne 2), la phase 72 ajoute des valeurs FIXES, déclarées ici (ligne 3), avec leur table de cas (ligne 4)
const AJOUTS_72 = ['proposition'];
console.log('liste=' + [...L].filter((v) => !AJOUTS_72.includes(v)).sort().join(','));
console.log('ajouts72=' + AJOUTS_72.filter((v) => L.includes(v)).sort().join(','));
const casP = [['prop', {}], ['prop-suffixe', { data: 'proposition:ouvre' }], ['prop-majuscule', { data: 'Proposition' }], ['prop-espace', { data: 'proposition ' }],
  ['prop-10000', { data: 'proposition' + 'x'.repeat(9989) }], ['prop-origine-de-P', { origin: P }], ['prop-source-autre', { source: {} }], ['prop-non-fiable', { isTrusted: false }]];
console.log(casP.map(([n, d]) => `${n}=${m.accepteMessage({ ...base, data: 'proposition', ...d }, Q, F, L) === true ? 'oui' : 'non'}`).join(' '));
JS
cat > "$AUX/harnais-liste-q.mjs" <<'JS'
// harnais-liste-q.mjs <sortie> : la liste fermée de P égale l'ensemble des valeurs de la table MESSAGES du client de Q (72-14, contrat §8) ; une ligne JSON
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(`${process.argv[2]}/vf-cockpit-terminal-tiroir.mjs`).href);
const src = fs.readFileSync(`${process.argv[2]}/vf-cockpit-terminal-client.mjs`, 'utf8');
const bloc = (src.match(/const MESSAGES = Object\.freeze\(\{([\s\S]*?)\}\)/) || [, ''])[1];
const paires = [...bloc.matchAll(/([A-Za-z]+):\s*'([^']+)'/g)].map((x) => [x[1], x[2]]);
const Qv = paires.map((x) => x[1]).sort(), Pv = [...(m.LISTE_MESSAGES || [])].sort();
const cle = (paires.find((x) => x[1] === 'proposition') || [, ''])[1];
const appel = !!cle && new RegExp("emettre\\('" + cle + "'\\)").test(src);
console.log(JSON.stringify({ q: Qv.length, p: Pv.length, egal: Qv.join(',') === Pv.join(','), cle, appel }));
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
// chrome-tiroir.mjs <chrome> <mode> <json> : scénarios navigateur du tiroir ; UNE ligne JSON. Modes : sans · flag · donnee · froid · localhost · page · etats · proposition.
// Chaque étape est isolée (essai) ; en mode flag, la première étape en échec arrête le reste (les mesures absentes sont nommées dans `erreurs`).
// Gestes par Input.dispatchMouseEvent / Input.dispatchKeyEvent seulement. Le secret de session n'apparaît jamais en sortie.
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import { execFileSync } from 'node:child_process';
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee, AMORCE } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv;
const A = JSON.parse(brut);
const OP = `http://127.0.0.1:${A.P}`, OQ = A.Q ? `http://127.0.0.1:${A.Q}` : '', MS = Number(process.env.VF_TIROIR_MS) || 20000;
const erreurs = {}; let echec = false;
const essai = async (nom, f) => { if (echec) return undefined; try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 140); echec = true; return undefined; } };
const ESPION = `if (window.top === window) { window.__msgs = []; addEventListener('message', (e) => window.__msgs.push({ o: e.origin, d: typeof e.data === 'string' ? e.data.slice(0, 200) : '<' + typeof e.data + '>' })); }`;
const OUVERT = `(() => { const r = document.querySelector('.vf-term-tiroir'); return !!r && !r.hidden && r.getBoundingClientRect().height > 0; })()`;
const HAUT = `Math.round(document.querySelector('.vf-term-tiroir').getBoundingClientRect().height)`;
const MSG = (d) => `window.__msgs.some((m) => m.o === ${JSON.stringify(OQ)} && m.d === ${JSON.stringify(d)})`;

// Q n'ouvre un shell que dans son cadre (F4, P71-D-25) : le mode `etats` joue la page de Q dans un cadre sandbox de P, plein viewport, comme le tiroir.
// `q` : ev/attendre/naviguer visent le monde principal du cadre de Q (retrouvé par sondage des identifiants de contexte, qui repartent de 1 à chaque processus de rendu : le socle n'expose pas les évènements).
const SBXQ = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
let ctxQ = 0;
const mondeQ = async (s, etendue = 600) => {
  let trouve = 0;
  for (let id = 1; id < etendue; id++) {
    const v = await s.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && location.hash === '#cadre-test' && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
    if (v === true) trouve = id;
  }
  return trouve;
};
const facadeQ = (s) => {
  const ev = async (expression) => { const x = await s.send('Runtime.evaluate', { expression, contextId: ctxQ, returnByValue: true, awaitPromise: true }); return x && x.result && x.result.value; };
  const attendre = async (expr, nom, ms = MS) => {
    const fin = Date.now() + ms; let v;
    do { try { v = await ev(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
    throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
  };
  const naviguer = async () => {
    ctxQ = 0;
    await s.naviguer(`${OP}/project.html`); await s.attendre(`document.readyState === 'complete'`, 'page P', MS);
    await s.ev(`(() => { document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove()); const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBXQ)});
      f.style.cssText = 'position:fixed;left:0;top:0;width:100vw;height:100vh;border:0;z-index:99999'; f.src = '${OQ}/?theme=dark#cadre-test'; document.body.appendChild(f); })()`);
    const fin = Date.now() + MS;
    let essais = 0;
    while (!ctxQ) { ctxQ = await mondeQ(s, 600 * 5 ** Math.min(essais++, 3)); if (!ctxQ) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
    await attendre(`!!document.querySelector('.xterm-helper-textarea') || !!document.querySelector('#etat:not([hidden])')`, 'terminal ou carte dans le cadre');
  };
  return { ev, attendre, naviguer, send: s.send };
};

await executer(chrome, async (s) => {
  const att = (expr, nom, ms) => s.attendre(expr, nom, ms || MS);
  const q = facadeQ(s);
  const prep = async () => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'dark' }] });
    await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: ESPION });
  };
  // SAF-1 : l'amorçage passe par la page Projet, qui monte le cadre de Q ; l'échange se fait dans le cadre (prêt = message ready de Q, après son rechargement sans fragment)
  const amorcerParP = async () => {
    await s.naviguer(`${OP}/project.html#t=${A.amorce}`);
    await att(`window.__msgs.some((m) => m.o === ${JSON.stringify(OQ)} && m.d === 'ready') && !location.hash`, 'cadre de Q prêt (échange fait dans le cadre)', process.env.VF_TIROIR_MS ? MS : Math.max(MS, AMORCE)); // amorçage : borné par l'échéance globale (par défaut), sauf VF_TIROIR_MS posée explicitement (les mutants la posent à 20000 : un amorçage cassé doit rougir en 20 s)
  };
  const centre = async (sel) => { const p = await positionPosee(s.ev, `document.querySelector(${JSON.stringify(sel)})`); return p ? { x: p.cx, y: p.cy } : null; }; // le rect est relu jusqu'à deux lectures égales : le tiroir entre en 250 ms, monte à 300 px, la pastille suit le rappel de la barre
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
  const clic = async (sel) => { const c = await centre(sel); if (!c) throw new Error(`élément absent : ${sel}`); await souris('mouseMoved', c.x, c.y); await souris('mousePressed', c.x, c.y); await souris('mouseReleased', c.x, c.y); };
  const touche = async (key, code, vk, modifiers = 0) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, modifiers }); };
  const raccourci = () => touche(' ', 'Space', 32, 10);
  const texte = (sel) => s.ev(`(document.querySelector(${JSON.stringify(sel)}) || {}).textContent || ''`);

  // J5 : la commande ne se coupe jamais et le point final reste sur sa ligne ; balayage de largeurs de fenêtre (le renvoi à la ligne en dépend)
  const COUPURE = (cmd, corps) => `(() => { const c = document.querySelector(${JSON.stringify(cmd)}); const k = document.querySelector(${JSON.stringify(corps)}); if (!c || !k) return null;
    const w = document.createTreeWalker(k, NodeFilter.SHOW_TEXT); let n, dernier = null; while ((n = w.nextNode())) dernier = n; if (!dernier || dernier.data.slice(-1) !== '.') return { sansPoint: true };
    const rg = document.createRange(); rg.setStart(dernier, dernier.data.length - 1); rg.setEnd(dernier, dernier.data.length); const p = rg.getBoundingClientRect(), rs = c.getClientRects(), d = rs[rs.length - 1];
    return { coupee: rs.length > 1, decolle: Math.abs(p.top - d.top) > d.height / 2, larg: Math.round(k.getBoundingClientRect().width) }; })()`;
  const balayer = async (cmd, corps, largeurs, cible = s) => {
    const mal = [], vus = new Set();
    for (const W of largeurs) {
      await s.send('Emulation.setDeviceMetricsOverride', { width: W, height: 800, deviceScaleFactor: 1, mobile: false });
      await attendreValeur(() => cible.ev('innerWidth'), (v) => v === W, { max: 5000 }); // le redimensionnement atteint le cadre de Q après P
      const m = await stabiliser(() => cible.ev(COUPURE(cmd, corps)), { max: 5000 }); if (!m || m.sansPoint) throw new Error(`carte illisible à ${W} px`);
      vus.add(m.larg); if (m.coupee || m.decolle) mal.push(`${W}:${m.coupee ? 'coupee' : ''}${m.decolle ? 'decolle' : ''}`);
    }
    return { mal, largeurs: vus.size };
  };
  const LARGEURS = [260, 280, 300, 320, 340, 360, 380, 400];

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
    if (A.attendre === 'carte') await essai('coupure', async () => { A.coupure = await balayer('.vf-term-carte code', '.vf-term-carte', LARGEURS); });
    else await essai('violation', async () => { const fin = Date.now() + MS; while (!s.violations.length && Date.now() < fin) await pause(100); await pause(2500); });
    return { erreurs, coupure: A.coupure, carte: await texte('.vf-term-carte').catch(() => ''), violations: [...s.violations], ready: await s.ev(MSG('ready')).catch(() => false), iframes: await s.ev(`document.querySelectorAll('iframe').length`).catch(() => -1) };
  }

  if (mode === 'etats') { // les états de la carte vus par Q seul, puis par la barre du tiroir de P (J1, J5, J6, J13)
    const r = { erreurs };
    const INVITE = `((document.querySelector('.xterm-rows') || {}).textContent || '').trim().length > 0`;
    const CARTE = (t) => `((document.getElementById('etat') || {}).textContent || '').includes(${JSON.stringify(t)})`;
    await essai('amorcage', async () => {
      await amorcerParP();
    });
    await essai('connecte', async () => { await q.naviguer(); await q.attendre(INVITE, 'invite du shell dans le cadre de Q (la session est prise par cet onglet)'); });
    await essai('refuse-q', async () => { // J6 : un autre onglet (sessionStorage vide) ; sous la carte, ni terminal ni curseur visibles
      await q.ev(`sessionStorage.clear()`); await q.naviguer(); await q.attendre(CARTE('Terminal déjà ouvert'), 'carte Terminal déjà ouvert');
      r.refuse = await q.ev(`(() => { const v = (e) => !!e && e.checkVisibility({ visibilityProperty: true }); return { terminal: v(document.getElementById('terminal')), xterm: v(document.querySelector('.xterm')), curseur: [...document.querySelectorAll('.xterm-cursor, .xterm-cursor-outline, .xterm-cursor-block')].filter(v).length, xtermPresent: !!document.querySelector('.xterm'), carte: v(document.querySelector('.vf-q-carte')), titre: (document.querySelector('.vf-q-titre') || {}).textContent, bouton: document.activeElement && document.activeElement.tagName }; })()`);
    });
    await essai('refuse-p', async () => { // J1 : la barre dit « Déjà ouvert » (autre onglet que celui de Q ci-dessus)
      await s.naviguer(`${OP}/project.html`); await att(`!!document.querySelector('button.vf-term-pastille')`, 'pastille'); await clic('button.vf-term-pastille');
      const lireRefuse = async () => ({ texte: await texte('.vf-term-etat'), point: await s.ev(`(document.querySelector('.vf-term-etat-point') || { getAttribute: () => null }).getAttribute('data-etat')`), annonce: await texte('.vf-term-annonce') });
      r.barreRefuse = await attendreEtStabiliser(lireRefuse, (v) => !!v && v.texte === 'Déjà ouvert' && v.point === 'refuse', { max: 10000 }); // le libellé attendu, pas « non vide » (qui accepte « Connexion… »)
    });
    await essai('expire-p', async () => { // J1 : secret absent, la barre dit « Session expirée »
      await s.naviguer(`${OQ}/`); await s.ev(`localStorage.setItem('vf.terminal.secret', 'secret-perime-' + 'x'.repeat(24))`); // PU-G-132 : un secret ABSENT n'est plus une expiration (la carte dit « non disponible », rien n'est dit à P) ; l'expiration vraie est un secret périmé, refusé par le serveur
      await s.naviguer(`${OP}/project.html`); await att(`!!document.querySelector('button.vf-term-pastille')`, 'pastille'); await clic('button.vf-term-pastille');
      const lireExpire = async () => ({ texte: await texte('.vf-term-etat'), point: await s.ev(`(document.querySelector('.vf-term-etat-point') || { getAttribute: () => null }).getAttribute('data-etat')`) });
      r.barreExpire = await attendreEtStabiliser(lireExpire, (v) => !!v && v.texte === 'Session expirée' && v.point === 'expire', { max: 10000 });
    });
    await essai('expire-q', async () => { // J13 : carte d'alerte focalisée par programme ; J5 : commande et point jamais coupés
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
      // refuse-p et expire-p ont laissé vf.terminal.open=1 dans le stockage de P : le rechargement de P rouvrirait le tiroir, donc un SECOND cadre Q dont carte('expire') prend aussi le focus (le dernier chargé
      // gagne, course). Un seul cadre Q pendant la mesure : on efface la mémoire d'ouverture avant de naviguer. Le focus perdu au chargement reste rouge ; la sonde dit pageFocus, l'élément actif et les cadres de P.
      await s.ev(`localStorage.removeItem('vf.terminal.open')`);
      await q.naviguer(); await q.attendre(CARTE('Session expirée'), 'carte Session expirée');
      // L2 : la vue ne prend le focus que si le cadre l'a déjà ; P donne le focus au cadre de Q, puis la carte est montée de nouveau (même contenu), comme à la perte de session dans un cadre actif
      await s.ev(`(() => { const f = document.querySelector('iframe'); if (f) f.focus(); return true; })()`);
      await attendreValeur(() => q.ev('document.hasFocus()'), (v) => v === true, { max: 5000 }); // la carte ne prend le focus que si le cadre l'a déjà : on attend qu'il l'ait
      await q.ev(`window.vfTermVue.carte('expire')`);
      const SONDE_J13 = `(() => { const k = document.querySelector('.vf-q-carte'), c = getComputedStyle(k); return { titre: (document.querySelector('.vf-q-titre') || {}).textContent, focus: document.activeElement === k, fv: k.matches(':focus-visible'), role: k.getAttribute('role'), contour: c.outlineStyle, pageFocus: document.hasFocus(), actif: document.activeElement && document.activeElement.tagName }; })()`;
      r.alerte = await attendreEtStabiliser(() => q.ev(SONDE_J13), (v) => !!v && v.focus === true, { max: 5000 }); r.alerte.cadresP = await s.ev(`document.querySelectorAll('iframe').length`);
      r.coupure = await balayer('.vf-q-commande', '.vf-q-corps', LARGEURS, q);
    });
    return r;
  }

  if (mode === 'proposition') { // 72-14 : la valeur fixe `proposition` émise par Q ouvre le tiroir de P, sans focus, sans canal de P vers Q (contrat §8 ; P72-D-09)
    const r = { erreurs };
    const pid = () => { try { return fs.readFileSync(A.fichierPid, 'utf8').trim(); } catch { return ''; } };
    const RECT = (sel) => `(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; const b = e.getBoundingClientRect(); return { l: Math.round(b.left), t: Math.round(b.top), r: Math.round(b.right), b: Math.round(b.bottom) }; })()`;
    const RELEVE = `({ ouvert: ${OUVERT}, focus: document.activeElement ? (document.activeElement.id || document.activeElement.tagName) : '', annonce: (document.querySelector('.vf-term-annonce') || {}).textContent || '',
      cadres: document.querySelectorAll('iframe').length, barre: (document.querySelector('.vf-term-etat') || {}).textContent || '', etiquette: (document.querySelector('button.vf-term-pastille') || { getAttribute: () => '' }).getAttribute('aria-label'),
      h: document.querySelector('.vf-term-tiroir') ? Math.round(document.querySelector('.vf-term-tiroir').getBoundingClientRect().height) : -1 })`;
    // attente tolérante : sur la base ou sous un mutant le tiroir ne s'ouvre pas ; la mesure continue, c'est l'assertion qui rougit (pas une erreur de scénario)
    const attOuvre = async (ms = 6000) => { const fin = Date.now() + ms; while (Date.now() < fin) { if (await s.ev(OUVERT)) return true; await pause(100); } return false; };
    const monde = async () => { // le monde du cadre de Q DANS le tiroir de P : origine de Q et window.vfTermVue, sans condition de fragment
      const fin = Date.now() + MS; let essais = 0, c = 0;
      while (!c) {
        const et = 600 * 5 ** Math.min(essais++, 3);
        for (let id = 1; id < et && !c; id++) {
          const v = await s.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
          if (v === true) c = id;
        }
        if (!c) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); }
      }
      return c;
    };
    const lireRel = async () => ({ releve: await s.ev(RELEVE), pastille: await s.ev(RECT('button.vf-term-pastille')), zoom: await s.ev(RECT('#zoom')) });
    let cq = 0;
    const deQ = (valeur) => s.send('Runtime.evaluate', { contextId: cq, expression: `window.parent.postMessage(${JSON.stringify(valeur)}, ${JSON.stringify(OP)})`, returnByValue: true });
    await essai('amorcage', () => amorcerParP());
    await essai('P', async () => { await s.naviguer(`${OP}/project.html`); await att(`!!document.querySelector('button.vf-term-pastille')`, 'pastille Terminal'); });
    await essai('ouvrir', async () => {
      await s.ev(`(() => { const b = document.createElement('button'); b.id = 'temoin'; b.textContent = 't'; b.style.cssText = 'position:fixed;left:0;top:0;width:12px;height:12px;z-index:1'; document.body.appendChild(b); b.focus(); })()`);
      await raccourci(); await att(OUVERT, 'tiroir ouvert'); await att(`${MSG('ready')} && ${MSG('etat:connecte')}`, 'ready puis etat:connecte');
      r.pid0 = pid(); cq = await monde();
    });
    await essai('fermer', async () => {
      await clic('.vf-term-fermer'); await att(`!(${OUVERT})`, 'tiroir fermé par le bouton');
      await s.ev(`document.getElementById('temoin').focus()`);
      const av = await attendreEtStabiliser(lireRel, (v) => !!v && !!v.releve && v.releve.ouvert === false && !!v.pastille && !!v.zoom && v.pastille.t >= v.zoom.b, { max: 5000 }); // les positions que TP.7 compare, pas seulement « fermé »
      r.avant = av.releve; r.avant.pastille = av.pastille; r.avant.zoom = av.zoom;
    });
    await essai('proposition-1', async () => { // TP.4 : tiroir fermé, la valeur fixe arrive de Q
      await deQ('proposition'); await attOuvre();
      const o1 = await stabiliser(async () => ({ releve: await s.ev(RELEVE), pid: pid(), recu: await s.ev(MSG('proposition')) }), { max: 5000 }); // tiroir ouvert : la montée à 300 px est posée avant la mesure
      r.ouvre1 = o1.releve; r.ouvre1.pid = o1.pid; r.ouvre1.recu = o1.recu;
    });
    await essai('proposition-2', async () => { // TP.5 : tiroir déjà ouvert ; l'annonce est effacée avant, elle seule doit revenir
      await s.ev(`document.querySelector('.vf-term-annonce').textContent = ''`);
      await deQ('proposition');
      await attendreValeur(() => s.ev(`(document.querySelector('.vf-term-annonce') || {}).textContent || ''`), (v) => !!v, { max: 5000 }); // l'annonce est revenue
      await pause(500); // fenêtre d'absence conservée : aucun second cadre ni autre shell ne doit apparaître
      const o2 = await stabiliser(async () => ({ releve: await s.ev(RELEVE), pid: pid() }), { max: 5000 });
      r.ouvre2 = o2.releve; r.ouvre2.pid = o2.pid;
    });
    await essai('cycle', async () => { // TP.7 et TP.8 : fermeture au bouton après l'ouverture par proposition
      if (!(await s.ev(OUVERT))) { r.cycleSansOuverture = true; return; }
      await clic('.vf-term-fermer'); await att(`!(${OUVERT})`, 'tiroir refermé');
      const ap = await attendreEtStabiliser(lireRel, (v) => !!v && !!v.releve && v.releve.ouvert === false && !!v.pastille && !!v.zoom && !!r.avant && !!r.avant.pastille && JSON.stringify(v.pastille) === JSON.stringify(r.avant.pastille) && JSON.stringify(v.zoom) === JSON.stringify(r.avant.zoom), { max: 5000 }); // revenu au rectangle d'avant le cycle (TP.7)
      r.apres = ap.releve; r.apres.pastille = ap.pastille; r.apres.zoom = ap.zoom;
    });
    await essai('espion', async () => { // TP.8 : tout message d'origine Q vu par P est dans la liste (relevé AVANT les envois hostiles de TP.6)
      const msgs = JSON.parse(await s.ev('JSON.stringify(window.__msgs)')), q = msgs.filter((m) => m.o === OQ);
      r.espion = { de_q: q.length, hors_liste: q.filter((m) => !A.liste.includes(m.d)).length, proposition: q.filter((m) => m.d === 'proposition').length };
    });
    await essai('hostiles', async () => { // TP.6 : tiroir fermé, tout ce qui n'est pas la valeur fixe de Q laisse le tiroir fermé
      if (await s.ev(OUVERT)) { await clic('.vf-term-fermer'); await att(`!(${OUVERT})`, 'tiroir fermé avant les envois hostiles'); }
      const clos = async () => { await pause(600); return !(await s.ev(OUVERT)); };
      r.hostile = {};
      await s.ev(`postMessage('proposition', location.origin)`); r.hostile.deP = await clos();
      await s.ev(`dispatchEvent(new MessageEvent('message', { data: 'proposition', origin: ${JSON.stringify(OQ)}, source: document.querySelector('iframe').contentWindow }))`); r.hostile.forge = await clos();
      await deQ('proposition:ouvre'); r.hostile.suffixe = await clos();
      await deQ('Proposition'); r.hostile.majuscule = await clos();
      await deQ('proposition '); r.hostile.espace = await clos();
      await deQ('proposition' + 'x'.repeat(9989)); r.hostile.long = await clos();
      await deQ('proposition'); r.hostile.vivant = await attOuvre(); // témoin positif : le canal de Q vit, les refus ci-dessus ne sont pas un harnais mort
    });
    if (A.hauteur) await essai('hauteur', async () => { // PU-G-136 : une proposition ouvre le tiroir à 300 px au moins, sans écraser la hauteur choisie, jamais en plein écran
      const MES = `({ ouvert: ${OUVERT}, now: Number(document.querySelector('.vf-term-poignee').getAttribute('aria-valuenow')), px: Math.round(document.querySelector('.vf-term-tiroir').getBoundingClientRect().height), memo: localStorage.getItem('vf.terminal.h'), plein: document.querySelector('.vf-term-tiroir').classList.contains('vf-term-plein-etat') })`;
      const fermer = async () => { if (await s.ev(OUVERT)) { await clic('.vf-term-fermer'); await att(`!(${OUVERT})`, 'tiroir fermé'); } };
      const ouvrirP = async () => { if (!(await s.ev(OUVERT))) { await clic('button.vf-term-pastille'); await att(OUVERT, 'tiroir ouvert'); } };
      const regler = async (grands, petits) => { // Home = 160 px, Maj+flèche = 96 px, flèche = 24 px ; mémorisé par la poignée
        await ouvrirP(); await s.ev(`document.querySelector('.vf-term-poignee').focus()`); await touche('Home', 'Home', 36);
        for (let i = 0; i < grands; i++) await touche('ArrowUp', 'ArrowUp', 38, 8);
        for (let i = 0; i < petits; i++) await touche('ArrowUp', 'ArrowUp', 38);
      };
      const evenement = () => s.ev(`document.dispatchEvent(new Event('vf-lancer-propose'))`);
      const message = () => deQ('proposition');
      const cas = async (nom, grands, petits, chemin, plein) => {
        await fermer(); await regler(grands, petits);
        if (plein) await clic('.vf-term-plein');
        await fermer(); const avant = await s.ev(MES);
        await chemin(); await attOuvre();
        const apres = await stabiliser(() => s.ev(MES), { max: 5000 });
        // la hauteur d'une proposition (300 px) est lue une fois posée
        r.haut[nom] = { avantNow: avant.now, avantMemo: avant.memo, ...apres };
        if (plein) { await clic('.vf-term-plein'); }
      };
      r.haut = {};
      await cas('bas-evt', 0, 0, evenement, false);
      await cas('bas-msg', 0, 0, message, false);
      await cas('haut-evt', 2, 3, evenement, false);
      await cas('haut-msg', 2, 3, message, false);
      await cas('plein-evt', 0, 0, evenement, true);
      await cas('plein-msg', 0, 0, message, true);
    });
    r.violations = [...s.violations];
    return r;
  }

  // --- flag / donnee : amorçage dans Chrome, secret lu sans démarrer le shell, puis P ---
  let secret = '';
  const r = { erreurs };
  const pid = () => { try { return fs.readFileSync(A.fichierPid, 'utf8').trim(); } catch { return ''; } };
  const session = () => { try { return JSON.parse(execFileSync('node', [A.TA, 'etat', String(A.Q), secret], { encoding: 'utf8' }).split('\n')[2] || '{}').session; } catch { return 'ERREUR'; } };
  await essai('amorcage', async () => {
    await amorcerParP();
    // échange refusé (amorçage de bon format, jamais posé) : le cadre de Q dit « Session expirée » à P (message etat:expire) ; le secret déjà rangé reste intact
    await s.naviguer(`${OP}/project.html#t=${'0'.repeat(64)}`);
    await att(`window.__msgs.some((m) => m.o === ${JSON.stringify(OQ)} && m.d === 'etat:expire')`, 'etat:expire du cadre de Q (échange refusé)');
    await s.naviguer(`${OQ}/`);
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
  await essai('tu4b', async () => { await s.ev(`document.getElementById('ouvreur').focus()`); await raccourci();
    r.tu4b = await attendreEtStabiliser(() => s.ev(`({ ouvert: ${OUVERT}, actif: document.activeElement.tagName })`), (v) => !!v && v.actif === 'IFRAME', { max: 5000 }); });
  await essai('tu4c', async () => { await raccourci(); await att(`!(${OUVERT})`, 'fermeture par le message toggle de Q'); await att(`document.activeElement && document.activeElement.id === 'ouvreur'`, 'focus rendu à l’ouvreur');
    r.tu4c = await s.ev(`({ ferme: !(${OUVERT}), focus: document.activeElement.id, toggle: ${MSG('toggle')}, annonce: (document.querySelector('.vf-term-annonce') || {}).textContent, inert: document.querySelector('.vf-term-tiroir').inert })`); });
  await essai('reouvrir', async () => { await clic('button.vf-term-pastille'); await att(OUVERT, 'tiroir rouvert au clic'); await pause(500); r.reouv = await s.ev(`({ iframes: document.querySelectorAll('iframe').length })`); r.reouv.pid = pid(); });
  await essai('tu5', async () => {
    r.h0 = await s.ev(HAUT); await s.ev(`document.querySelector('.vf-term-poignee').focus()`);
    await touche('ArrowUp', 'ArrowUp', 38); await touche('ArrowUp', 'ArrowUp', 38);
    r.tu5 = await s.ev(`({ h: ${HAUT}, now: document.querySelector('.vf-term-poignee').getAttribute('aria-valuenow'), texte: document.querySelector('.vf-term-poignee').getAttribute('aria-valuetext'), stock: [localStorage.getItem('vf.terminal.h'), localStorage.getItem('vf.terminal.open')].join('/') })`);
    const pid1 = pid(); await s.send('Page.reload');
    await att(`${OUVERT} && ${MSG('etat:connecte')}`, 'tiroir rouvert et reconnecté après rechargement');
    r.tu5.reload = await stabiliser(() => s.ev(`({ h: ${HAUT}, iframes: document.querySelectorAll('iframe').length })`), { max: 5000 }); r.tu5.pid = pid1 === pid() ? 'identique' : 'change:' + pid1 + '>' + pid();
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
  await essai('tu14', async () => { // J4 : focus clavier de la poignée = bague autour du grip, pas deux bandes pleine largeur
    await s.ev(`document.querySelector('.vf-term-plein').focus()`); await touche('Tab', 'Tab', 9, 8); // Maj+Tab depuis le bouton : le clavier amène le focus sur la poignée
    r.tu14 = await attendreEtStabiliser(() => s.ev(`(() => { const p = document.querySelector('.vf-term-poignee'), g = document.querySelector('.vf-term-grip'), cp = getComputedStyle(p), cg = getComputedStyle(g), b = g.getBoundingClientRect(), q = p.getBoundingClientRect();
      return { sur_poignee: document.activeElement === p, fv: p.matches(':focus-visible'), poignee: cp.outlineStyle, grip: cg.outlineStyle + '/' + cg.outlineWidth, opaque: cg.opacity, grip_larg: Math.round(b.width), poignee_larg: Math.round(q.width) }; })()`), (v) => !!v && v.sur_poignee === true, { max: 5000 });
  });
  await essai('tu15', async () => { // J7 : sous pointer: coarse les boutons de la barre font au moins 44 px et la barre les contient ; sous pointeur fin, 28 px
    const mesure = () => s.ev(`(() => { const bs = [...document.querySelectorAll('.vf-term-bouton')].map((b) => { const r = b.getBoundingClientRect(); return Math.round(r.width) + 'x' + Math.round(r.height); }); return { coarse: matchMedia('(pointer: coarse)').matches, boutons: bs.join(','), barre: Math.round(document.querySelector('.vf-term-barre').getBoundingClientRect().height), pastille: parseFloat(getComputedStyle(document.querySelector('button.vf-term-pastille')).height) }; })()`);
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
    r.tu15 = { fin: await attendreEtStabiliser(mesure, (v) => !!v && v.coarse === false, { max: 5000 }) };
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: true }); await s.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 });
    r.tu15.tactile = await attendreEtStabiliser(mesure, (v) => !!v && v.coarse === true, { max: 5000 }); // matchMedia(pointer: coarse) se met à jour après l'émulation
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: false }); await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
    await attendreValeur(() => s.ev(`matchMedia('(pointer: coarse)').matches`), (v) => v === false, { max: 5000 });
  });
  // T17.5 : saisie au clavier dans le cadre, relevé de l'espion
  await essai('t175', async () => {
    if (!(await s.ev(OUVERT))) { await clic('button.vf-term-pastille'); await att(OUVERT, 'tiroir ouvert pour la saisie'); }
    await s.ev(`document.querySelector('iframe').focus()`);
    await attendreValeur(() => s.ev(`document.activeElement && document.activeElement.tagName`), (v) => v === 'IFRAME', { max: 5000 });
    { // le focus doit être arrivé jusqu'au terminal du cadre de Q avant la frappe, sinon les octets se perdent
      const scan = async (n) => { let c = 0; for (let id = 1; id < n && !c; id++) { const v = await s.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false); if (v === true) c = id; } return c; };
      let essais = 0; const cq = await attendreValeur(() => scan(essais++ ? 3000 : 600), (v) => v > 0, { pas: 150, max: 10000 });
      if (cq) await attendreValeur(() => s.send('Runtime.evaluate', { contextId: cq, expression: `document.hasFocus() && !!document.activeElement && document.activeElement.classList.contains('xterm-helper-textarea')`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false), (v) => v === true, { max: 5000 });
    }
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
cat > "$AUX/chrome-geom.mjs" <<'JS'
// chrome-geom.mjs <chrome> <json> : géométrie du tiroir dans les pages Projet et Code (E2, G1 ; P71-D-34, P71-D-35) ; UNE ligne JSON.
// Entrée : { P } (port du cockpit lancé avec --terminal), optionnel { shots } (dossier de captures), { court } (2 combinaisons au lieu de 8, pour les mutants). Chaque combinaison page x fenêtre x thème a son relevé.
// Gestes par Input.dispatchMouseEvent / Input.dispatchKeyEvent seulement : le test de recouvrement est celui du navigateur (elementFromPoint).
import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, brut] = process.argv; const A = JSON.parse(brut);
const OP = `http://127.0.0.1:${A.P}`, MS = Number(process.env.VF_TIROIR_MS) || 20000;
const FENETRES = [[1440, 900], [1280, 720]], THEMES = ['dark', 'light'], PAGES = ['index.html', 'project.html'];
const ZOOM = `['z-out', 'z-fit', 'z-in'].map((id) => { const e = document.getElementById(id); if (!e) return id + ':absent'; const r = e.getBoundingClientRect(); const t = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
  const b = t && t.closest('button'); return id + ':' + (b ? b.id || b.className : 'rien'); })`;
const TIROIR = `(() => { const r = document.querySelector('.vf-term-tiroir'); if (!r || r.hidden) return null; const b = r.getBoundingClientRect(); return { top: b.top, bottom: b.bottom, left: b.left, right: b.right }; })()`;
const NOEUDS = `(() => { const ns = [...document.querySelectorAll('#viewport .node')].filter((n) => n.getClientRects().length); if (!ns.length) return null; let top = 1e9, bottom = -1e9, left = 1e9, right = -1e9;
  for (const n of ns) { const b = n.getBoundingClientRect(); top = Math.min(top, b.top); bottom = Math.max(bottom, b.bottom); left = Math.min(left, b.left); right = Math.max(right, b.right); } return { n: ns.length, top: Math.round(top), bottom: Math.round(bottom), left: Math.round(left), right: Math.round(right) }; })()`;
const ASK = `(() => { const a = document.getElementById('ask'); if (!a) return null; const b = a.getBoundingClientRect(); return { display: getComputedStyle(a).display, bottom: Math.round(b.bottom), h: Math.round(b.height) }; })()`;
const PAST = `(() => { const p = document.querySelector('.vf-term-pastille'); if (!p || p.hidden) return null; const b = p.getBoundingClientRect(); return { left: Math.round(b.left), top: Math.round(b.top), right: Math.round(b.right), bottom: Math.round(b.bottom) }; })()`;
const ZRECT = `(() => { const z = document.getElementById('zoom'); const b = z.getBoundingClientRect(); return { top: Math.round(b.top), bottom: Math.round(b.bottom), left: Math.round(b.left), right: Math.round(b.right) }; })()`;

await executer(chrome, async (s) => {
  const att = (expr, nom, ms) => s.attendre(expr, nom, ms || MS);
  const centre = async (sel) => { const p = await positionPosee(s.ev, `document.querySelector(${JSON.stringify(sel)})`); return p ? { x: p.cx, y: p.cy } : null; }; // le rect est relu jusqu'à deux lectures égales : le tiroir entre en 250 ms, monte à 300 px, la pastille suit le rappel de la barre
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
  const clic = async (sel) => { const c = await centre(sel); if (!c) throw new Error(`élément absent : ${sel}`); await souris('mouseMoved', c.x, c.y); await souris('mousePressed', c.x, c.y); await souris('mouseReleased', c.x, c.y); };
  const touche = async (key, code, vk) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, text: type === 'keyDown' ? key : undefined, code, windowsVirtualKeyCode: vk }); };
  const ouvert = `(() => { const r = document.querySelector('.vf-term-tiroir'); return !!r && !r.hidden && r.getBoundingClientRect().height > 0; })()`;
  const capture = async (nom) => { if (!A.shots) return; fs.mkdirSync(A.shots, { recursive: true }); const r = await s.send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${A.shots}/${nom}.png`, Buffer.from(r.data, 'base64')); };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const sorties = [], erreurs = {};
  const combos = [];
  for (const page of PAGES) for (const [W, H] of FENETRES) for (const theme of THEMES) combos.push([page, W, H, theme]);
  const retenues = A.court ? combos.filter(([p, W, , t]) => (p === 'index.html' && W === 1440 && t === 'dark') || (p === 'project.html' && W === 1280 && t === 'light')) : combos;
  for (const [page, W, H, theme] of retenues) {
    const cle = `${page}@${W}x${H}/${theme}`; const r = { cle };
    try {
      await s.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: theme }] });
      await s.naviguer(`${OP}/${page}`); await s.ev(`localStorage.clear(); sessionStorage.clear(); document.documentElement.setAttribute('data-theme', ${JSON.stringify(theme)})`);
      await s.naviguer(`${OP}/${page}`); await s.ev(`document.documentElement.setAttribute('data-theme', ${JSON.stringify(theme)})`);
      await att(`!!document.querySelector('button.vf-term-pastille') && document.querySelectorAll('#viewport .node').length > 0`, 'pastille et nœuds', MS);
      const fe = await stabiliser(async () => ({ zoom: await s.ev(ZOOM), past: await s.ev(PAST), z: await s.ev(ZRECT), ask: await s.ev(ASK) }), { max: 8000 }); // page neuve : mise en page lue une fois posée
      r.fermeZoom = fe.zoom; r.fermePast = fe.past; r.fermeZ = fe.z; r.fermeAsk = fe.ask;
      // un clic sur « + » ne doit pas ouvrir le terminal
      const k0 = await s.ev(`window.VibeFlow ? 1 : 0`); r.api = k0;
      await clic('#z-in'); await pause(300); r.clicPlusOuvre = await s.ev(ouvert);
      await capture(`${cle.replace(/[^a-z0-9]+/gi, '_')}-ferme`);
      // la visite « Par où commencer » est ouverte avant l'ouverture du tiroir
      r.visiteAvant = await s.ev(`(() => { try { if (window.VibeFlowTour && !window.VibeFlowTour.active()) window.VibeFlowTour.start(); return !!(window.VibeFlowTour && window.VibeFlowTour.active()); } catch (e) { return 'err'; } })()`);
      await stabiliser(() => s.ev(PAST), { max: 5000 });
      await clic('button.vf-term-pastille'); await att(ouvert, 'tiroir ouvert');
      const lireOuv = async () => ({ tiroir: await s.ev(TIROIR), zoom: await s.ev(ZOOM), z: await s.ev(ZRECT), ask: await s.ev(ASK), visiteApres: await s.ev(`window.VibeFlowTour ? window.VibeFlowTour.active() : null`), visiteCachee: await s.ev(`(document.getElementById('tour') || { hidden: true }).hidden`) });
      const ou = await attendreEtStabiliser(lireOuv, (v) => !!v && !!v.tiroir && !!v.z && v.z.bottom <= v.tiroir.top, { max: 5000 }); // le zoom a quitté le dessous du tiroir (l'assertion E2o juge ensuite)
      r.tiroir = ou.tiroir; r.ouvZoom = ou.zoom; r.ouvZ = ou.z; r.ouvAsk = ou.ask; r.visiteApres = ou.visiteApres; r.visiteCachee = ou.visiteCachee;
      // « Ajuster » : touche F (focus rendu à la page) puis bouton
      await s.ev(`document.activeElement && document.activeElement.blur && document.activeElement.blur()`);
      await stabiliser(() => s.ev(NOEUDS), { max: 5000 });
      await touche('f', 'KeyF', 70); r.apresF = await attendreEtStabiliser(() => s.ev(NOEUDS), (v) => !!v && !!r.tiroir && v.bottom <= r.tiroir.top, { max: 5000 });
      await capture(`${cle.replace(/[^a-z0-9]+/gi, '_')}-ouvert-F`);
      await clic('#z-fit'); r.apresBouton = await attendreEtStabiliser(() => s.ev(NOEUDS), (v) => !!v && !!r.tiroir && v.bottom <= r.tiroir.top, { max: 5000 });
      // un clic sur « + » tiroir ouvert rend la main à la page : le tiroir reste ouvert, le zoom agit (les nœuds grossissent)
      const avant = await stabiliser(() => s.ev(NOEUDS), { max: 5000 }); await clic('#z-out'); const apres = await attendreEtStabiliser(() => s.ev(NOEUDS), (v) => !!v && !!avant && (v.right - v.left) < (avant.right - avant.left), { max: 5000 }); r.zoomOutAgit = !!avant && !!apres && (apres.right - apres.left) < (avant.right - avant.left); r.tiroirResteOuvert = await s.ev(ouvert);
      // fermeture : tout revient
      await clic('.vf-term-fermer');
      const fi = await attendreEtStabiliser(async () => ({ ferme2: await s.ev(`!document.querySelector('.vf-term-tiroir') || document.querySelector('.vf-term-tiroir').hidden`), ask: await s.ev(ASK), zoom: await s.ev(ZOOM), past: await s.ev(PAST), z: await s.ev(ZRECT) }), (v) => !!v && v.ferme2 === true && !!v.z && JSON.stringify(v.z) === JSON.stringify(fe.z) && !!v.ask && v.ask.display !== 'none' && !!fe.ask && v.ask.bottom === fe.ask.bottom, { max: 5000 }); // E2f/fin : retour aux positions d'avant l'ouverture
      r.ferme2 = fi.ferme2; r.finAsk = fi.ask; r.finZoom = fi.zoom; r.finPast = fi.past; r.finZ = fi.z;
      // reprise : tiroir mémorisé ouvert, la première mise en page tient déjà compte de lui
      await s.ev(`localStorage.setItem('vf.terminal.open', '1')`); await s.naviguer(`${OP}/${page}`); await s.ev(`document.documentElement.setAttribute('data-theme', ${JSON.stringify(theme)})`);
      await att(`${ouvert} && document.querySelectorAll('#viewport .node').length > 0`, 'tiroir rouvert et nœuds');
      const rp = await attendreEtStabiliser(async () => ({ tiroir: await s.ev(TIROIR), noeuds: await s.ev(NOEUDS) }), (v) => !!v && !!v.tiroir && !!v.noeuds && v.noeuds.bottom <= v.tiroir.top, { max: 6000 });
      r.repriseTiroir = rp.tiroir; r.repriseNoeuds = rp.noeuds;
      await capture(`${cle.replace(/[^a-z0-9]+/gi, '_')}-reprise`);
    } catch (e) { erreurs[cle] = String(e.message).slice(0, 160); }
    sorties.push(r);
  }
  // verdicts : un groupe par propriété, la liste des relevés qui la tiennent mal (vide = tenue partout)
  const trois = (r) => (id) => r.every((x, i) => x === ['z-out', 'z-fit', 'z-in'][i] + ':' + ['z-out', 'z-fit', 'z-in'][i]);
  const hors = (a, b) => !!a && !!b && !(a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top);
  const G = { E2f: [], E2o: [], G1F: [], G1ask: [], G1visite: [], G1reprise: [], fin: [], agit: [] };
  for (const r of sorties) {
    const t = r.tiroir, ok3 = (l) => Array.isArray(l) && trois(l)();
    if (!(ok3(r.fermeZoom) && r.clicPlusOuvre === false && hors(r.fermePast, r.fermeZ) && (r.fermePast.left >= r.fermeZ.right || r.fermePast.right <= r.fermeZ.left || r.fermePast.top >= r.fermeZ.bottom))) G.E2f.push(r.cle);
    if (!(t && ok3(r.ouvZoom) && r.ouvZ && r.ouvZ.bottom <= t.top)) G.E2o.push(r.cle);
    if (!(t && r.apresF && r.apresBouton && r.apresF.bottom <= t.top && r.apresBouton.bottom <= t.top)) G.G1F.push(r.cle);
    if (!(r.ouvAsk && r.ouvAsk.display === 'none' && r.finAsk && r.finAsk.display !== 'none' && r.finAsk.bottom === r.fermeAsk.bottom)) G.G1ask.push(r.cle);
    if (!(r.visiteAvant === true && r.visiteApres === false && r.visiteCachee === true)) G.G1visite.push(r.cle);
    if (!(t && r.repriseTiroir && r.repriseNoeuds && r.repriseNoeuds.bottom <= r.repriseTiroir.top)) G.G1reprise.push(r.cle);
    if (!(ok3(r.finZoom) && JSON.stringify(r.finZ) === JSON.stringify(r.fermeZ) && r.ferme2 === true)) G.fin.push(r.cle);
    if (!(r.zoomOutAgit === true && r.tiroirResteOuvert === true)) G.agit.push(r.cle);
  }
  return { erreurs, n: sorties.length, api: sorties.every((r) => r.api === 1), noeuds: sorties.every((r) => r.apresF && r.apresF.n > 0), G, sorties: A.detail ? sorties : undefined };
});
JS
cat > "$AUX/chrome-pastille.mjs" <<'JS'
// chrome-pastille.mjs <chrome> <json> : T21.7 (71.5, P71.5-D-06) — la pastille fermée ne recouvre ni #ask (affichée), ni #panel (ouvert), ni #zoom, ni #tour (affichée) ; UNE ligne JSON.
// Entrée : { P, court }. Les relevés ne dépendent pas de chrome-geom (son « court » ne règle que ses propres huit combinaisons). Par largeur : panneau dans son état initial, puis bascule, puis bascule
// retour (le cas « refermé » est celui qu'un rappel périmé laisse faux). Puis : la visite affichée, panneau ouvert, aux cinq largeurs qui comptent ; puis deux états tactiles (pointer: coarse).
import { pathToFileURL } from 'node:url';
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, brut] = process.argv; const A = JSON.parse(brut);
const OP = `http://127.0.0.1:${A.P}`, MS = Number(process.env.VF_TIROIR_MS) || 20000;
const TOUTES = [[390, 844], [600, 900], [700, 900], [701, 900], [768, 1024], [900, 900], [1000, 800], [1024, 768], [1100, 800], [1200, 800], [1260, 800], [1280, 800]];
const COURTES = [[390, 844], [768, 1024], [1024, 768], [1200, 800]];
const AVEC_VISITE = new Set([390, 600, 700, 768, 1024]);
const MESURE = `(() => {
  const r = (e) => { if (!e) return null; const b = e.getBoundingClientRect(), cs = getComputedStyle(e); if (!(b.width > 0 && b.height > 0) || cs.display === 'none' || cs.visibility === 'hidden') return null; return { left: b.left, top: b.top, right: b.right, bottom: b.bottom }; };
  const p = r(document.querySelector('.vf-term-pastille')); const ouvert = !document.body.classList.contains('no-panel');
  const ask = r(document.getElementById('ask')), panel = ouvert ? r(document.getElementById('panel')) : null, zoom = r(document.getElementById('zoom')), tour = r(document.getElementById('tour'));
  const sur = (a, o) => !!a && !!o && a.left < o.right && a.right > o.left && a.top < o.bottom && a.bottom > o.top;
  return { pastille: !!p, ask: !!ask, panneau: ouvert, tour: !!tour, mal: [['ask', ask], ['panel', panel], ['zoom', zoom], ['tour', tour]].filter(([, o]) => sur(p, o)).map(([n]) => n) };
})()`;
await executer(chrome, async (s) => {
  const releves = [], erreurs = {};
  const mesurer = async (cle, extra, lecture = () => s.ev(MESURE), pred = null) => { try { const m = pred ? await attendreEtStabiliser(lecture, pred, { max: 6000 }) : await stabiliser(lecture, { max: 6000 }); releves.push({ cle, ...m, ...(extra || {}) }); } catch (e) { erreurs[cle] = String(e.message).slice(0, 160); } };
  const basculer = async () => { await s.ev(`document.getElementById('btn-panel').click()`); };
  const charger = async (W, H, tactile) => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: !!tactile });
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: !!tactile });
    await s.naviguer(`${OP}/index.html`); await s.ev(`localStorage.clear(); sessionStorage.clear()`);
    await s.naviguer(`${OP}/index.html`);
    await s.attendre(`!!document.querySelector('button.vf-term-pastille') && document.querySelectorAll('#viewport .node').length > 0`, 'pastille et nœuds', MS);
    await attendreValeur(() => s.ev(`matchMedia('(pointer: coarse)').matches`), (v) => v === !!tactile, { max: 5000 }); // l'émulation tactile se répercute sur le média après coup
  };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  for (const [W, H] of (A.court ? COURTES : TOUTES)) {
    const cle = `${W}x${H}`;
    try {
      await charger(W, H, false);
      await mesurer(`${cle}/initial`);
      await basculer(); await mesurer(`${cle}/bascule`);
      await basculer(); await mesurer(`${cle}/retour`);
      // 72.1 : de 701 à 1 279 px la barre garde son bord gauche quel que soit le panneau, donc seule sa HAUTEUR change le recouvrement : l'avertissement « connecter un outil d'IA » l'allonge vers le haut, la pastille doit remonter avec elle (rappel du ResizeObserver de la barre)
      if (W >= 701 && W <= 1279) {
        await s.ev(`(() => { const a = document.getElementById('ask'), w = document.getElementById('ask-warn'); if (!a || !w) return 0; a.classList.add('asking'); w.hidden = false; return 1; })()`);
        // la barre s'allonge, le rappel remonte la pastille : on attend l'avertissement posé, puis la mise en page stable (sans prédicat sur le verdict)
        const lireAv = async () => ({ ...(await s.ev(MESURE)), avert: await s.ev(`(() => { const w = document.getElementById('ask-warn'); return !!w && w.getBoundingClientRect().height > 0; })()`) });
        await mesurer(`${cle}/avertissement`, {}, lireAv, (v) => !!v && v.avert === true);
        await s.ev(`(() => { const a = document.getElementById('ask'), w = document.getElementById('ask-warn'); if (a) a.classList.remove('asking'); if (w) w.hidden = true; return 1; })()`); await pause(400);
      }
      if (AVEC_VISITE.has(W)) { // visite affichée, panneau ouvert
        if (await s.ev(`document.body.classList.contains('no-panel')`)) await basculer();
        await s.ev(`window.VibeFlowTour && !window.VibeFlowTour.active() && window.VibeFlowTour.start()`);
        await mesurer(`${cle}/visite`, {}, () => s.ev(MESURE), (v) => !!v && v.tour === true); await s.ev(`window.VibeFlowTour && window.VibeFlowTour.active() && window.VibeFlowTour.end()`);
      }
    } catch (e) { erreurs[cle] = String(e.message).slice(0, 160); }
  }
  if (!A.court) for (const [W, H] of [[390, 844], [768, 1024]]) { // état tactile : pointer: coarse (pastille de 44 px)
    const cle = `tactile-${W}x${H}`;
    try {
      await charger(W, H, true);
      const coarse = await s.ev(`matchMedia('(pointer: coarse)').matches`);
      await mesurer(`${cle}/initial`, { coarse });
      await basculer(); await mesurer(`${cle}/bascule`, { coarse }); await basculer(); await mesurer(`${cle}/retour`, { coarse });
    } catch (e) { erreurs[cle] = String(e.message).slice(0, 160); }
  }
  const mauvais = releves.filter((x) => !x.pastille || x.mal.length).map((x) => x.cle + ':' + (x.pastille ? x.mal.join('+') : 'sans-pastille'));
  return { erreurs, n: releves.length, mauvais, avecAskOuvert: releves.filter((x) => x.ask && x.panneau).length, avecVisite: releves.filter((x) => x.tour).length, avertissements: releves.filter((x) => x.avert === true).length, tactile: releves.filter((x) => x.coarse === true).length };
});
JS
cat > "$AUX/chrome-axe.mjs" <<'JS'
// chrome-axe.mjs <chrome> <json> : T21.9 à T21.11 (recette du 2026-11-08, lot C ; PU-G-021 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « La zone basse sous 1 280 px ») — l'axe commun de la zone basse,
// de 390 à 1 440 px, sur Code et sur Projet : zoom, pastille « Terminal » et barre de question au même bord gauche --edge (16), pastille aussi large que le zoom, barre de 40 px. UNE ligne JSON.
// Les rects se lisent une fois posés (stabiliser : deux lectures identiques).
// Exceptions écrites, mesurées ici pour qu'elles ne glissent pas : sous 701 px le zoom reste la pile verticale du téléphone (P70-D-09, demande de Samuel du 2026-11-02) donc la pastille n'a pas sa largeur ;
// sous 1 000 px les cibles font 44 px (viewer.html, règle « 999 px et moins ») et l'invite reste entière sur sa ligne : la barre n'y fait pas 40 px (finding ask-user du lot C) ; dès 1 280 px la barre est centrée, après la colonne du zoom.
import { pathToFileURL } from 'node:url';
const { executer, stabiliser, attendreValeur } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, brut] = process.argv; const A = JSON.parse(brut);
const OP = `http://127.0.0.1:${A.P}`, MS = Number(process.env.VF_TIROIR_MS) || 20000, EDGE = 16, TOL = 0.6;
const LARGEURS = A.court ? [[390, 844], [768, 1024], [1000, 800], [1440, 900]] : [[390, 844], [700, 900], [701, 900], [768, 1024], [999, 900], [1000, 800], [1279, 800], [1280, 800], [1440, 900]];
const MESURE = `(() => {
  const r = (s) => { const e = document.querySelector(s); if (!e) return null; const b = e.getBoundingClientRect(), cs = getComputedStyle(e); if (!(b.width > 0 && b.height > 0) || cs.display === 'none' || cs.visibility === 'hidden') return null; return { x: +b.x.toFixed(1), y: +b.y.toFixed(1), l: +b.width.toFixed(1), h: +b.height.toFixed(1) }; };
  return { zoom: r('#zoom'), pastille: r('.vf-term-pastille'), barre: r('#ask-form'), edge: parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--edge')) || null };
})()`;
await executer(chrome, async (s) => {
  const rel = [], erreurs = {};
  for (const page of ['index.html', 'project.html']) for (const [W, H] of LARGEURS) {
    const cle = `${page.replace('index.html', 'code').replace('project.html', 'projet')}-${W}`;
    try {
      await s.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
      await s.naviguer(`${OP}/${page}`); await s.ev(`localStorage.clear(); sessionStorage.clear()`); await s.naviguer(`${OP}/${page}`);
      await s.attendre(`!!document.querySelector('button.vf-term-pastille') && !!document.getElementById('ask-form') && document.querySelectorAll('#viewport .node, #svg g.node').length > 0`, 'pastille, barre et nœuds', MS);
      const lire = () => s.ev(MESURE);
      await attendreValeur(lire, (v) => !!v && !!v.zoom && !!v.pastille && !!v.barre, { max: 6000 });
      const m = await stabiliser(lire, { max: 6000 });
      rel.push({ cle, W, ...m });
    } catch (e) { erreurs[cle] = String(e.message).slice(0, 160); }
  }
  const proche = (a, b) => Math.abs(a - b) <= TOL;
  const complets = rel.filter((x) => x.zoom && x.pastille && x.barre);
  const zoom = [], pastille = [], barre = [];
  for (const x of complets) {
    const { cle, W, zoom: z, pastille: p, barre: b } = x;
    // T21.9 : le zoom est au bord --edge ; en rangée dès 701 px, posé au-dessus de la pastille ; en pile (plus haute que large) sous 701 px
    if (!proche(z.x, EDGE)) zoom.push(`${cle}: bord ${z.x}`);
    if (W >= 701 && !(z.l > z.h)) zoom.push(`${cle}: pas en rangée (${z.l}x${z.h})`);
    if (W < 701 && !(z.h > z.l)) zoom.push(`${cle}: la pile du téléphone a changé (${z.l}x${z.h})`);
    if (W >= 701 && W <= 1279 && !(z.y + z.h <= p.y + TOL)) zoom.push(`${cle}: le zoom n'est pas au-dessus de la pastille (bas ${+(z.y + z.h).toFixed(1)} > haut ${p.y})`);
    // T21.10 : la pastille est au bord --edge, aussi large que le zoom dès 701 px
    if (!proche(p.x, EDGE)) pastille.push(`${cle}: bord ${p.x}`);
    if (W >= 701 && !proche(p.l, z.l)) pastille.push(`${cle}: largeur ${p.l} contre zoom ${z.l}`);
    // T21.11 : la barre est au bord --edge jusqu'à 1 279 px (après la colonne du zoom dès 1 280 px), de 40 px dès 1 000 px
    if (W <= 1279 && !proche(b.x, EDGE)) barre.push(`${cle}: bord ${b.x}`);
    if (W >= 1280 && !(b.x >= z.x + z.l)) barre.push(`${cle}: la barre (${b.x}) recouvre la colonne du zoom (jusqu'à ${+(z.x + z.l).toFixed(1)})`);
    if (W >= 1000 && !proche(b.h, 40)) barre.push(`${cle}: hauteur ${b.h}`);
  }
  return { erreurs, n: rel.length, complets: complets.length, edge: [...new Set(rel.map((x) => x.edge))], zoom, pastille, barre };
});
JS
cat > "$AUX/chrome-defaut.mjs" <<'JS'
// chrome-defaut.mjs <chrome> <json> : hauteur du tiroir selon la fenêtre (G4 ; P71-D-37) ; UNE ligne JSON. Entrée : { P }. Page Projet, stockage vidé avant chaque relevé.
import { pathToFileURL } from 'node:url';
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, brut] = process.argv; const A = JSON.parse(brut);
const OP = `http://127.0.0.1:${A.P}`, MS = Number(process.env.VF_TIROIR_MS) || 20000;
const OUVERT = `(() => { const r = document.querySelector('.vf-term-tiroir'); return !!r && !r.hidden && r.getBoundingClientRect().height > 0; })()`;
const MESURE = `(() => { const b = document.querySelector('.vf-term-tiroir').getBoundingClientRect(); const hh = parseFloat(getComputedStyle(document.body).getPropertyValue('--hh')) || 64; return { h: Math.round(b.height), bande: Math.round(b.top - hh), fenetre: window.innerHeight }; })()`;
await executer(chrome, async (s) => {
  const att = (expr, nom) => s.attendre(expr, nom, MS);
  const fenetre = (W, H) => s.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  const ouvrirA = async (W, H, stock) => {
    await fenetre(W, H); await s.naviguer(`${OP}/project.html`); await s.ev(`localStorage.clear()`);
    if (stock) await s.ev(`localStorage.setItem('vf.terminal.h', '${stock}'); localStorage.setItem('vf.terminal.open', '1')`); else await s.ev(`localStorage.setItem('vf.terminal.open', '1')`);
    await s.naviguer(`${OP}/project.html`); await att(OUVERT, 'tiroir ouvert'); return stabiliser(() => s.ev(MESURE), { max: 5000 });
  };
  const r = { erreurs: {} };
  try {
    r.d720 = await ouvrirA(1280, 720); r.d900 = await ouvrirA(1440, 900); r.d1080 = await ouvrirA(1920, 1080);
    r.m720 = await ouvrirA(1280, 720, 600); r.m900 = await ouvrirA(1440, 900, 600);
    r.m360 = await ouvrirA(1280, 720, 360);
    await ouvrirA(1440, 900); await fenetre(1280, 720); r.suit = await attendreEtStabiliser(() => s.ev(MESURE), (v) => !!v && v.fenetre === 720, { max: 5000 });
    await ouvrirA(1440, 900, 600); await fenetre(1280, 720); r.retrecit = await attendreEtStabiliser(() => s.ev(MESURE), (v) => !!v && v.fenetre === 720, { max: 5000 });
  } catch (e) { r.erreurs.defaut = String(e.message).slice(0, 160); }
  return r;
});
JS
echo ok
rq() { node "$TA" req "$@"; }
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"; }
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
run_etats() { # run_etats <sortie> -> EJ ; un serveur neuf, un amorçage neuf, un Chrome neuf
  srv "$1" 1; EJ="$(navig etats "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\"}")"; unsrv
}
run_geom() { # run_geom <sortie> <court 0|1> -> GJ ; un serveur neuf, un Chrome neuf (le shell n'est pas piloté : la géométrie seule)
  srv "$1" 1; GJ="$(node "$AUX/chrome-geom.mjs" "$CHROME" "{\"P\":$SRV_PORT,\"court\":$2}")"; unsrv
}
run_pastille() { # run_pastille <sortie> <court 0|1> -> PJ ; un serveur neuf, un Chrome neuf (T21.7)
  srv "$1" 1; PJ="$(node "$AUX/chrome-pastille.mjs" "$CHROME" "{\"P\":$SRV_PORT,\"court\":$2}")"; unsrv
}
run_axe() { # run_axe <sortie> <court 0|1> -> XJ ; un serveur neuf, un Chrome neuf (T21.9 à T21.11)
  srv "$1" 1; XJ="$(node "$AUX/chrome-axe.mjs" "$CHROME" "{\"P\":$SRV_PORT,\"court\":$2}")"; unsrv
}
run_defaut() { # run_defaut <sortie> -> DJ ; un serveur neuf, un Chrome neuf
  srv "$1" 1; DJ="$(node "$AUX/chrome-defaut.mjs" "$CHROME" "{\"P\":$SRV_PORT}")"; unsrv
}
LISTE_JSON='["ready","etat:connecte","etat:reconnexion","etat:termine","etat:refuse","etat:expire","etat:arrete","toggle","proposition"]'
run_flag() { # run_flag <sortie> <court 0|1> -> FJ FP FQ ; un serveur neuf, un amorçage neuf, un Chrome neuf
  srv "$1" 1; FP=$SRV_PORT; FQ=$QP; FMARQ="MARQUEUR-P-$RANDOM$RANDOM"; rm -f "$WORK/run/m.txt" "$WORK/run/shell.pid"
  FJ="$(navig flag "{\"P\":$FP,\"Q\":$FQ,\"amorce\":\"$AMORCE\",\"marqueur\":\"$FMARQ\",\"fichierPid\":\"$WORK/run/shell.pid\",\"fichierM\":\"$WORK/run/m.txt\",\"TA\":\"$TA\",\"liste\":$LISTE_JSON,\"court\":$2}")"; unsrv
}

run_haut() { # run_haut <sortie> -> PJ ; comme run_prop, avec en plus le scénario de hauteur (PU-G-136)
  srv "$1" 1; rm -f "$WORK/run/shell.pid"
  PJ="$(navig proposition "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"fichierPid\":\"$WORK/run/shell.pid\",\"liste\":$LISTE_JSON,\"hauteur\":true}")"; unsrv
}

run_prop() { # run_prop <sortie> -> PJ ; un serveur neuf, un amorçage neuf, un Chrome neuf (72-14 : valeur fixe proposition)
  srv "$1" 1; rm -f "$WORK/run/shell.pid"
  PJ="$(navig proposition "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"fichierPid\":\"$WORK/run/shell.pid\",\"liste\":$LISTE_JSON}")"; unsrv
}

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

echo "=== ST — script injecté (statique) : TU.13, T17.6 ==="
node "$AUX/scriptgen.mjs" "$OUT" 0 > "$WORK/sg.out" 2>&1; SG="$(tail -n 1 "$WORK/sg.out")"
assert_eq "TU.13.0 — témoin : le script injecté existe (taille > 500), sa première ligne est l'en-tête VibeFlow (71-07), il vient avec sa feuille" "$(rj "$SG" '(j.taille>500)+"/"+j.premiere+"/"+j.style')" "true/// VibeFlow (71-07) : tiroir du terminal/true"
assert_eq "TU.13 — aucune adresse web écrite en entier dans le script injecté, commentaires compris (témoin : le motif trouve une adresse plantée)" "$(rj "$SG" 'j.adresses+"/"+j.temoin')" "0/1"
assert_eq "TU.13b — un seul fetch( et il vise /api/vf/terminal ; aucun cookie ; seules clés de stockage : vf.terminal.h et vf.terminal.open" "$(rj "$SG" '(j.taille>500)+"/"+j.fetchs+"/"+j.api+"/"+j.cookie+"/"+j.cles')" "true/1/true/0/vf.terminal.h,vf.terminal.open"
assert_eq "T17.6 — aucun postMessage( dans le script injecté (le sens P vers le cadre est fermé), aucun attribut allow posé, Échap jamais cité (le script est vivant)" "$(rj "$SG" '(j.taille>500)+"/"+j.postmsg+"/"+j.allow+"/"+j.echap')" "true/0/0/0"

echo "=== T23 — point de la pastille fermée : jamais une teinte d'état sur --raise en clair (71.5, juge de rendu 2026-11-06 ; DESIGN.md §9) ==="
cat > "$AUX/contraste-point.mjs" <<'JS'
// contraste-point.mjs <style.mjs> <viewer.html> : rapport de contraste du point `.vf-term-point` sur --raise, thème sombre puis clair ; UNE ligne « sombre=N clair=N ».
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const { STYLE_TIROIR } = await import(pathToFileURL(process.argv[2]).href); const html = fs.readFileSync(process.argv[3], 'utf8');
const bloc = (re) => { const m = re.exec(html); return m ? m[0] : ''; };
const jetons = { sombre: bloc(/:root \{[\s\S]*?\n\}/), clair: bloc(/:root\[data-theme="light"\] \{[\s\S]*?\n\}/) };
const lin = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
const L = (h) => { const n = parseInt(h.slice(1), 16); return 0.2126 * lin(n >> 16) + 0.7152 * lin((n >> 8) & 255) + 0.0722 * lin(n & 255); };
const ratio = (a, b) => { const [x, y] = [L(a), L(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
const regle = /\.vf-term-point \{[^}]*background: var\((--[\w-]+)\)/.exec(STYLE_TIROIR); const out = [];
for (const t of ['sombre', 'clair']) {
  const val = (nom) => { const m = new RegExp(nom + ': (#[0-9a-fA-F]{6})').exec(jetons[t]) || (t === 'clair' ? new RegExp(nom + ': (#[0-9a-fA-F]{6})').exec(jetons.sombre) : null); return m && m[1]; };
  const fond = val('--raise'), pt = regle && val(regle[1]);
  out.push(t + '=' + (fond && pt ? ratio(pt, fond).toFixed(2) : 'illisible'));
}
console.log(out.join(' '));
JS
CT="$(node "$AUX/contraste-point.mjs" "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs" "$ENG/assets/viewer.html" 2>&1 | tail -n 1)"
assert_eq "T23.1 — le point de la pastille fermée fait au moins 3:1 sur --raise dans les deux thèmes (sombre inchangé : 8,6:1 ; clair : --recent-text 4,3:1, --recent faisait 2,9:1)" "$(echo "$CT" | awk '{ split($1,a,"="); split($2,b,"="); print (a[2]+0 >= 3 && b[2]+0 >= 3) ? "ok" : "ko" }') [$CT]" "ok [$CT]"
MUTP="$WORK/mut-point-style.mjs"; sed 's|background: var(--recent-text); }|background: var(--recent); }|' "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs" > "$MUTP"
if cmp -s "$MUTP" "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs"; then sans_effet "M-POINT-RECENT"; else
  CM="$(node "$AUX/contraste-point.mjs" "$MUTP" "$ENG/assets/viewer.html" 2>&1 | tail -n 1)"
  assert_eq "M-POINT-RECENT — l'ancien point (--recent) rougit T23.1 : clair sous 3:1 (témoin : le sombre est lu)" "$(echo "$CM" | awk '{ split($1,a,"="); split($2,b,"="); print (a[2]+0 >= 3 && b[2]+0 < 3) ? "rouge" : "vert" }')" "rouge"
fi

cat > "$AUX/contraste-etat.mjs" <<'JS'
// contraste-etat.mjs <style.mjs> <viewer.html> : rapport de contraste de chaque point d'état de la barre (`.vf-term-etat-point`) sur --raise, par thème ; UNE ligne « sombre:defaut=N sombre:connecte=N ... clair:expire=N ». Résolution : dernière règle applicable (en clair, les règles `:root[data-theme="light"]` s'ajoutent aux règles de base).
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const { STYLE_TIROIR } = await import(pathToFileURL(process.argv[2]).href); const html = fs.readFileSync(process.argv[3], 'utf8');
const bloc = (re) => { const m = re.exec(html); return m ? m[0] : ''; };
const jetons = { sombre: bloc(/:root \{[\s\S]*?\n\}/), clair: bloc(/:root\[data-theme="light"\] \{[\s\S]*?\n\}/) };
const lin = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
const L = (h) => { const n = parseInt(h.slice(1), 16); return 0.2126 * lin(n >> 16) + 0.7152 * lin((n >> 8) & 255) + 0.0722 * lin(n & 255); };
const ratio = (a, b) => { const [x, y] = [L(a), L(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
const regles = []; const re = /([^{}\/]+)\{([^}]*)\}/g; let m;
while ((m = re.exec(STYLE_TIROIR.replace(/\/\*[\s\S]*?\*\//g, '')))) { const bg = /background: var\((--[\w-]+)\)/.exec(m[2]); if (bg) regles.push({ sels: m[1].split(',').map((s) => s.trim()), jeton: bg[1] }); }
const out = [];
for (const t of ['sombre', 'clair']) {
  const val = (nom) => { const x = new RegExp(nom + ': (#[0-9a-fA-F]{6})').exec(jetons[t]) || new RegExp(nom + ': (#[0-9a-fA-F]{6})').exec(jetons.sombre); return x && x[1]; };
  for (const etat of ['defaut', 'connecte', 'reconnexion', 'refuse', 'arrete', 'expire']) {
    let jeton = null;
    for (const r of regles) for (const s of r.sels) {
      const clair = s.startsWith(':root[data-theme="light"] '); const nu = clair ? s.slice(26) : s;
      if (clair && t !== 'clair') continue;
      const ok = etat === 'defaut' ? nu === '.vf-term-etat-point' : nu === '.vf-term-etat-point[data-etat="' + etat + '"]';
      if (ok) jeton = r.jeton;
    }
    const fond = val('--raise'), pt = jeton && val(jeton);
    out.push(t + ':' + etat + '=' + (fond && pt ? ratio(pt, fond).toFixed(2) : 'illisible'));
  }
}
console.log(out.join(' '));
JS
CE="$(node "$AUX/contraste-etat.mjs" "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs" "$ENG/assets/viewer.html" 2>&1 | tail -n 1)"
assert_eq "T23.2 — les six points d'état de la barre (défaut, connecte, reconnexion, refuse, arrete, expire) font au moins 3:1 sur --raise dans les deux thèmes, douze mesures lues (clair : variantes -text, sombre inchangé ; DESIGN.md §9, P71.5-D-36)" "$(echo "$CE" | awk '{ n=0; bon=0; for (i=1;i<=NF;i++) { split($i,a,"="); n++; if (a[2]+0 >= 3) bon++ } print (n==12 && bon==12) ? "ok" : "ko" }') [$CE]" "ok [$CE]"
MUTE="$WORK/mut-etat-style.mjs"; sed 's|:root\[data-theme="light"\] .vf-term-etat-point\[data-etat="connecte"\] { background: var(--recent-text); }|:root[data-theme="light"] .vf-term-etat-point[data-etat="connecte"] { background: var(--recent); }|' "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs" > "$MUTE"
if cmp -s "$MUTE" "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs"; then sans_effet "M-ETAT-RECENT"; else
  CM="$(node "$AUX/contraste-etat.mjs" "$MUTE" "$ENG/assets/viewer.html" 2>&1 | tail -n 1)"
  assert_eq "M-ETAT-RECENT — le point connecté en --recent sur --raise clair rougit T23.2 (clair:connecte sous 3:1, témoin : le sombre est lu)" "$(echo "$CM" | awk '{ for (i=1;i<=NF;i++) { split($i,a,"="); v[a[1]]=a[2]+0 } print (v["clair:connecte"] < 3 && v["sombre:connecte"] >= 3) ? "rouge" : "vert" }')" "rouge"
fi
MUTH="$WORK/mut-etat-medium.mjs"; sed 's|\(:root\[data-theme="light"\] .vf-term-etat-point\[data-etat="refuse"\] { background: \)var(--warn-text)|\1var(--sev-medium)|' "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs" > "$MUTH"
if cmp -s "$MUTH" "$SCRIPTS/vf-cockpit-terminal-tiroir-style.mjs"; then sans_effet "M-ETAT-MEDIUM"; else
  CM="$(node "$AUX/contraste-etat.mjs" "$MUTH" "$ENG/assets/viewer.html" 2>&1 | tail -n 1)"
  assert_eq "M-ETAT-MEDIUM — le point reconnexion/refus en --sev-medium sur --raise clair rougit T23.2 (clair:reconnexion sous 3:1, témoin : le sombre est lu)" "$(echo "$CM" | awk '{ for (i=1;i<=NF;i++) { split($i,a,"="); v[a[1]]=a[2]+0 } print (v["clair:reconnexion"] < 3 && v["sombre:reconnexion"] >= 3) ? "rouge" : "vert" }')" "rouge"
fi

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

echo "=== TP — valeur fixe « proposition » de Q vers P (72-14 ; P72-D-09, P71-D-18 ; contrat §8) ==="
assert_eq "TP.1 — la liste de la phase 71 garde ses huit valeurs (ligne 2 du harnais), la phase 72 ajoute exactement une valeur fixe (ligne 3)" "$(sed -n 2p "$WORK/h.out") $(sed -n 3p "$WORK/h.out")" "liste=etat:arrete,etat:connecte,etat:expire,etat:reconnexion,etat:refuse,etat:termine,ready,toggle ajouts72=proposition"
assert_eq "TP.2 — accepteMessage : « proposition » seule passe ; refusés : suffixe, majuscule, espace final, 10 000 caractères, origine de P, autre source, non fiable" "$(sed -n 4p "$WORK/h.out")" "prop=oui prop-suffixe=non prop-majuscule=non prop-espace=non prop-10000=non prop-origine-de-P=non prop-source-autre=non prop-non-fiable=non"
node "$AUX/harnais-liste-q.mjs" "$OUT" > "$WORK/hq.out" 2>&1
assert_eq "TP.3 — câblage : LISTE_MESSAGES de P = ensemble des valeurs de la table MESSAGES du client de Q (neuf valeurs), et le client appelle emettre sur la clé de « proposition »" "$(tail -n 1 "$WORK/hq.out" | node "$AUX/ev.mjs" '"q="+j.q+" p="+j.p+" egal="+j.egal+" cle="+j.cle+" appel="+j.appel')" "q=9 p=9 egal=true cle=proposition appel=true"
mut_prop() { # mut_prop <libellé> <nom> <expression-sed> <cas qui doit passer à « oui » dans la ligne 4>
  if mutant "$2" vf-cockpit-terminal-tiroir.mjs "$3"; then
    node "$AUX/harnais-msg.mjs" "$MUT_OUT" > "$WORK/hm-$2.out" 2>&1
    assert_eq "$1 $2 — le mutant rougit TP.2 : le cas « $4 » est accepté" "$(sed -n 4p "$WORK/hm-$2.out" | tr ' ' '\n' | grep "^$4=")" "$4=oui"
  else sans_effet "$1 $2"; fi
}
mut_prop TP.9 M-MESSAGE-LIBRE 's|liste.indexOf(e.data) >= 0|(liste.indexOf(e.data) >= 0 \|\| e.data.indexOf("proposition") === 0)|' prop-suffixe

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
assert_eq "TU.5 — poignée au clavier : 288 px par défaut (36 % de 800 px, P71-D-37), deux flèches haut = +48 px, aria-valuenow suit et aria-valuetext la dit avec son unité (« 336 px », PU-G-142), mémorisés (vf.terminal.h/open) ; rechargement : même hauteur, tiroir rouvert, même PID de shell" "$(rj "$J" '"h0="+j.h0+" h1="+j.tu5.h+" now="+j.tu5.now+" texte="+j.tu5.texte+" stock="+j.tu5.stock+" apres="+j.tu5.reload.h+"/"+j.tu5.reload.iframes+" shell="+j.tu5.pid')" "h0=288 h1=336 now=336 texte=336 px stock=336/1 apres=336/1 shell=identique"
assert_eq "TU.6 — Agrandir : aria-pressed vrai et libellé « Réduire le terminal », tiroir plus haut ; second clic : retour à la hauteur d'avant" "$(rj "$J" '"pressed="+j.tu6.pressed+" aria="+j.tu6.aria+" plus_haut="+(j.tu6.h>j.h5)+" retour="+j.tu6.retour')" "pressed=true aria=Réduire le terminal plus_haut=true retour=false/336"
assert_eq "TU.7 — glissement souris de 80 px vers le haut : cadre en pointer-events none et body.resizing pendant le geste, rendus après ; hauteur 336 + 80" "$(rj "$J" '"pendant="+j.tu7.pendant+" apres="+j.tu7.apres+" h="+j.tu7.h')" "pendant=none/true apres=auto/false h=416"
assert_eq "TU.8 — bascule de thème : l'adresse du cadre passe à ?theme=light, history.length inchangé, même PID de shell (P71-D-19)" "$(rj "$J" '"url="+j.tu8.url+" histoire="+j.tu8.histoire+" pid="+j.tu8.pid')" "url=Q/?theme=light histoire=inchangee pid=identique"
assert_eq "T17.1 — témoin : les vrais messages de Q agissent (toggle reçu : le tiroir s'est fermé ; etat:connecte : la barre dit « Connecté »)" "$(rj "$J" '"toggle="+j.tu4c.toggle+" ferme="+j.tu4c.ferme+" barre="+j.tu3.barre')" "toggle=true ferme=true barre=Connecté"
assert_eq "T17.2 — postMessage('toggle') émis par P vers elle-même : ignoré (tiroir ouvert avant et après)" "$(rj "$J" '"avant="+j.t17.avant+" apres="+j.t17.postMessage')" "avant=true apres=true"
assert_eq "T17.3 — MessageEvent forgé (origine de Q, source = le cadre) : ignoré, car non fiable (tiroir ouvert avant et après)" "$(rj "$J" '"avant="+j.t17.avant+" apres="+j.t17.forge')" "avant=true apres=true"
assert_eq "T17.5 — espion : après une commande tapée dans le shell, tout message d'origine Q est dans la liste fermée ; ni le marqueur, ni le secret, ni l'amorçage n'y figurent (témoin : la commande a tourné)" "$(rj "$J" '"fichier="+j.t175.fichier+" hors_liste="+j.t175.hors_liste+" marqueur="+j.t175.marqueur+" secret="+j.t175.secret+" amorce="+j.t175.amorce+" ready_et_connecte="+(j.t175.vus.includes("ready")&&j.t175.vus.includes("etat:connecte"))')" "fichier=true hors_liste=0 marqueur=0 secret=0 amorce=0 ready_et_connecte=true"

assert_eq "T20.4 (J4) — poignée focalisée au clavier : le contour est sur le grip (40 px, 2 px pleins, visible), jamais sur la poignée pleine largeur (témoin : :focus-visible est vrai)" "$(rj "$J" '"sur="+j.tu14.sur_poignee+" fv="+j.tu14.fv+" poignee="+j.tu14.poignee+" grip="+j.tu14.grip+" opaque="+j.tu14.opaque+" grip_larg="+j.tu14.grip_larg+" large="+(j.tu14.poignee_larg>400)')" "sur=true fv=true poignee=none grip=solid/2px opaque=1 grip_larg=40 large=true"
assert_eq "T20.7 (J7) — pointeur fin : boutons de 28 px, barre de 36 px ; pointer: coarse (témoin : le média est vrai) : boutons d'au moins 44 px et barre qui les contient" "$(rj "$J" '"fin="+j.tu15.fin.coarse+" "+j.tu15.fin.boutons+" "+j.tu15.fin.barre+" / tactile="+j.tu15.tactile.coarse+" "+(j.tu15.tactile.boutons.split(",").every((b)=>b.split("x").every((n)=>Number(n)>=44)))+" "+(j.tu15.tactile.barre>=44)')" "fin=false 28x28,28x28 36 / tactile=true true true"
assert_eq "T20.8 (F-A1-3) — la pastille « Terminal » fermée : 32 px au pointeur fin, au moins 44 px sous pointer: coarse (témoin : le média est vrai)" "$(rj "$J" '"fin="+j.tu15.fin.pastille+" / tactile="+j.tu15.tactile.coarse+" "+(j.tu15.tactile.pastille>=44)')" "fin=32 / tactile=true true"

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

echo "=== T20 — états de la carte : barre de P et page de Q (critique design 71, J1, J5, J6, J13) ==="
run_etats "$OUT"; E="$EJ"
assert_eq "T20.0 — témoin : le scénario n'a pas échoué (aucune étape en erreur)" "$(rj "$E" 'j.erreur||JSON.stringify(j.erreurs)')" "{}"
assert_eq "T20.1 (J1) — barre du tiroir, état refusé (autre onglet) : libellé « Déjà ouvert », pastille d'état refuse, annonce du lecteur d'écran identique ; état expiré : « Session expirée », pastille expire" "$(rj "$E" '"refuse="+j.barreRefuse.texte+"/"+j.barreRefuse.point+"/"+j.barreRefuse.annonce+" expire="+j.barreExpire.texte+"/"+j.barreExpire.point')" "refuse=Déjà ouvert/refuse/Déjà ouvert expire=Session expirée/expire"
assert_eq "T20.2 (J1) — la barre dit le même état que la carte de Q : le libellé de la barre est contenu dans le titre de la carte, pour refusé et expiré" "$(rj "$E" '"refuse="+j.refuse.titre.toLowerCase().includes(j.barreRefuse.texte.toLowerCase())+" expire="+j.alerte.titre.toLowerCase().includes(j.barreExpire.texte.toLowerCase())')" "refuse=true expire=true"
assert_eq "T20.3 (J6) — sous la carte « déjà ouvert » : ni terminal, ni grille xterm, ni curseur visibles (témoin : la grille existe dans le DOM et la carte est visible)" "$(rj "$E" '"terminal="+j.refuse.terminal+" xterm="+j.refuse.xterm+" curseur="+j.refuse.curseur+" present="+j.refuse.xtermPresent+" carte="+j.refuse.carte')" "terminal=false xterm=false curseur=0 present=true carte=true"
assert_eq "T20.6 (J13) — carte d'alerte focalisée par programme : elle a le focus et :focus-visible est vrai (témoin), mais aucune bague de focus" "$(rj "$E" '"focus="+j.alerte.focus+" fv="+j.alerte.fv+" role="+j.alerte.role+" contour="+j.alerte.contour')" "focus=true fv=true role=alert contour=none"
[ "$(rj "$E" 'j.alerte.focus')" = "true" ] || echo "     ℹ T20.6 — focus perdu au chargement : pageFocus=$(rj "$E" 'j.alerte.pageFocus') actif=$(rj "$E" 'j.alerte.actif') cadres_de_P=$(rj "$E" 'j.alerte.cadresP')"
assert_eq "T20.5 (J5, carte de Q) — la commande /vf-cockpit --terminal ne se coupe jamais et son point final reste collé, à huit largeurs de fenêtre (témoin : la carte a changé de largeur au moins trois fois)" "$(rj "$E" '"mal="+JSON.stringify(j.coupure.mal)+" larges="+(j.coupure.largeurs>=3)')" 'mal=[] larges=true'

echo "=== T21 — géométrie du tiroir : zoom, Ajuster, barre de question, visite (recette 71, E2 et G1 ; P71-D-34, P71-D-35) ==="
run_geom "$OUT" 0; G="$GJ"
assert_eq "T21.0 — témoin : aucune étape en erreur, huit relevés (2 pages x 2 fenêtres x 2 thèmes), l'API du viewer est là, des nœuds sont dessinés" "$(rj "$G" '(j.erreur||JSON.stringify(j.erreurs))+" n="+j.n+" api="+j.api+" noeuds="+j.noeuds')" "{} n=8 api=true noeuds=true"
assert_eq "T21.1 (E2) — tiroir fermé : au centre de #z-out, #z-fit, #z-in, elementFromPoint rend le bouton et non la pastille, la pastille ne recouvre pas #zoom, un clic sur « + » n'ouvre pas le terminal (1440x900 et 1280x720, thèmes sombre et clair, pages Code et Projet)" "$(rj "$G" 'JSON.stringify(j.G.E2f)')" "[]"
assert_eq "T21.2 (E2) — tiroir ouvert : les trois boutons restent atteignables, posés au-dessus du tiroir, et « − » agit sans fermer le tiroir" "$(rj "$G" 'JSON.stringify(j.G.E2o)+JSON.stringify(j.G.agit)')" "[][]"
assert_eq "T21.3 (G1) — « Ajuster » (touche F, puis bouton) tiroir ouvert : la boîte englobante des nœuds visibles finit au-dessus du tiroir" "$(rj "$G" 'JSON.stringify(j.G.G1F)')" "[]"
assert_eq "T21.4 (G1) — la barre de question #ask est rangée tant que le tiroir est ouvert et revient à sa place (même bas) à la fermeture ; zoom et pastille aussi" "$(rj "$G" 'JSON.stringify(j.G.G1ask)+JSON.stringify(j.G.fin)')" "[][]"
assert_eq "T21.5 (G1) — la visite « Par où commencer » est ouverte avant (témoin) et fermée par l'ouverture du tiroir" "$(rj "$G" 'JSON.stringify(j.G.G1visite)')" "[]"
assert_eq "T21.6 (G1) — tiroir mémorisé ouvert, rechargement : le cadrage initial finit déjà au-dessus du tiroir" "$(rj "$G" 'JSON.stringify(j.G.G1reprise)')" "[]"
mut_geom() { # mut_geom <nom> <fichier> <expression-sed> <groupe qui doit rougir>
  if mutant "$1" "$2" "$3"; then
    srv "$MUT_OUT" 1; GM="$(node "$AUX/chrome-geom.mjs" "$CHROME" "{\"P\":$SRV_PORT,\"court\":1}")"; unsrv
    assert_eq "$1 — le mutant rougit T21 : le groupe $4 compte au moins un relevé en défaut (témoin : deux relevés, aucune erreur)" "$(rj "$GM" '"n="+j.n+" erreurs="+JSON.stringify(j.erreurs)+" rouge="+(j.G.'"$4"'.length>=1)')" "n=2 erreurs={} rouge=true"
  else sans_effet "$1"; fi
}
mut_geom M-PASTILLE-SUR-ZOOM vf-cockpit-terminal-tiroir.mjs 's|if (recouvre) z.style.bottom|if (false) z.style.bottom|' E2f
mut_geom M-AJUSTE-SANS-TIROIR vf-cockpit-terminal-tiroir-style.mjs 's|body.vf-term-ouvert #stage {|body.vf-term-ouvert #stage-absent {|' G1F
mut_geom M-ASK-RESTE vf-cockpit-terminal-tiroir-style.mjs 's|body.vf-term-ouvert #ask { display: none; }|body.vf-term-ouvert #ask { }|' G1ask
mut_geom M-VISITE-RESTE vf-cockpit-terminal-tiroir.mjs 's|window.VibeFlowTour.end();|void 0;|' G1visite
run_pastille "$OUT" 0; PA="$PJ"
assert_eq "T21.7 (D-06) — tiroir fermé : la pastille ne recouvre ni la barre de question, ni la feuille de détail, ni le zoom, ni la visite, de 390 à 1280 px, panneau dans son état initial, basculé, rebasculé, visite affichée, et en état tactile" "$(rj "$PA" '(j.erreur||JSON.stringify(j.erreurs))+" "+JSON.stringify(j.mauvais)')" "{} []"
assert_eq "T21.8 — témoin de T21.7 : au moins 36 relevés pris, au moins 6 avec #ask affiché ET panneau ouvert, au moins 5 avec la visite affichée, au moins 3 en état tactile, au moins 6 avec l'avertissement de la barre réellement affiché de 701 à 1 279 px (sinon T21.7 est vert à vide)" "$(rj "$PA" '(j.n>=36&&j.avecAskOuvert>=6&&j.avecVisite>=5&&j.tactile>=3&&j.avertissements>=6)?"ok":"n="+j.n+" ask="+j.avecAskOuvert+" visite="+j.avecVisite+" tactile="+j.tactile+" avert="+j.avertissements')" "ok"
mut_pastille() { # mut_pastille <nom> <expression-sed> : le mutant doit laisser au moins un relevé en défaut (témoin : au moins 8 relevés, aucune erreur)
  if mutant "$1" vf-cockpit-terminal-tiroir.mjs "$2"; then
    srv "$MUT_OUT" 1; PM="$(node "$AUX/chrome-pastille.mjs" "$CHROME" "{\"P\":$SRV_PORT,\"court\":1}")"; unsrv
    assert_eq "$1 — le mutant rougit T21.7 : au moins un relevé en défaut (témoin : au moins 8 relevés, aucune erreur)" "$(rj "$PM" '(j.n>=8)+" "+JSON.stringify(j.erreurs)+" rouge="+(j.mauvais.length>=1)')" "true {} rouge=true"
  else sans_effet "$1"; fi
}
mut_pastille M-PASTILLE-SUR-ASK 's|if (sur(n.getBoundingClientRect(), kb)) n.style.bottom|if (false) n.style.bottom|'
mut_pastille M-PASTILLE-SANS-RAPPEL "s|if (ask) { if (window.ResizeObserver)|if (false) { if (window.ResizeObserver)|" # jointure du panel (2026-11-07) : le mutant retire TOUT rappel lié à la barre (ResizeObserver et transitionend) ; la forme précédente, qui ne retirait que l'observateur, restait verte en CI Linux (shard 5, run 42386847278) alors qu'elle rougissait sous macOS : la fin de transition suffisait là-bas à replacer la pastille

run_axe "$OUT" 0; AX="$XJ"
assert_eq "T21.9 — témoin de l'axe : 18 relevés complets (9 largeurs x Code et Projet), aucune erreur, --edge vaut 16" "$(rj "$AX" '(j.erreur||JSON.stringify(j.erreurs))+" n="+j.n+" complets="+j.complets+" edge="+JSON.stringify(j.edge)')" "{} n=18 complets=18 edge=[16]"
assert_eq "T21.9 (PU-G-021) — zoom au bord --edge de 390 à 1 440 px : en rangée au-dessus de la pastille de 701 à 1 279 px (plus la pile du haut à droite), pile du téléphone sous 701 px (P70-D-09)" "$(rj "$AX" 'JSON.stringify(j.zoom)')" "[]"

echo "=== T22 — hauteur par défaut proportionnelle à la fenêtre (recette 71, G4 ; P71-D-37) ==="
run_defaut "$OUT"; D="$DJ"
assert_eq "T22.0 — témoin : aucune étape en erreur, huit relevés mesurés (tiroir ouvert, hauteur lue sur la boîte)" "$(rj "$D" 'JSON.stringify(j.erreurs)+" "+["d720","d900","d1080","m720","m900","m360","suit","retrecit"].filter((k)=>j[k]&&j[k].h>0).length')" "{} 8"
assert_eq "T22.1 (G4) — sans hauteur mémorisée : 36 % de la fenêtre, bornée entre 220 et 380 px (1280x720 : 259, 1440x900 : 324, 1920x1080 : 380 plafonné ; 389 non borné)" "$(rj "$D" 'j.d720.h+"/"+j.d900.h+"/"+j.d1080.h')" "259/324/380"
assert_eq "T22.2 (G4) — 1280x720 : la bande de carte au-dessus du tiroir (haut du tiroir moins l'en-tête) fait au moins la moitié de la fenêtre (360 px ; 320 px de tiroir fixe en laissaient 320)" "$(rj "$D" 'j.d720.bande>=j.d720.fenetre/2')" "true"
assert_eq "T22.3 (G4) — hauteur mémorisée de 600 px : plafonnée à 70 % de la fenêtre en 1280x720 (504), intacte en 1440x900 (630 de plafond) ; 360 px mémorisés restent 360" "$(rj "$D" 'j.m720.h+"/"+j.m900.h+"/"+j.m360.h')" "504/600/360"
assert_eq "T22.4 (G4) — la fenêtre rétrécit tiroir ouvert : la hauteur par défaut suit (324 puis 259), une hauteur de 600 px est ramenée à 504" "$(rj "$D" 'j.suit.h+"/"+j.retrecit.h')" "259/504"
mut_defaut() { # mut_defaut <nom> <fichier> <expression-sed> <relevé> <valeur saine>
  if mutant "$1" "$2" "$3"; then
    srv "$MUT_OUT" 1; DM="$(node "$AUX/chrome-defaut.mjs" "$CHROME" "{\"P\":$SRV_PORT}")"; unsrv
    assert_eq "$1 — le mutant rougit T22 : le relevé $4 n'est plus $5 (témoin : aucune erreur, tiroir mesuré)" "$(rj "$DM" 'JSON.stringify(j.erreurs)+" mesure="+(j.'"$4"'&&j.'"$4"'.h>0)+" rouge="+(j.'"$4"'.h!=='"$5"')')" "{} mesure=true rouge=true"
  else sans_effet "$1"; fi
}
mut_defaut M-HAUTEUR-FIXE-320 vf-cockpit-terminal-tiroir.mjs 's|const defaut = () => borne([^;]*;|const defaut = () => 320;|' d720 259
mut_defaut M-MEMO-NON-BORNEE vf-cockpit-terminal-tiroir.mjs 's|Math.min(borne(memo), plafondMemo())|borne(memo)|' m720 504

echo "=== TU.11 / T8.3 — cadre injoignable, frame-src absent (mutants jouées en navigateur) ==="
if mutant injoignable vf-cockpit-terminal.mjs "s|{ etat: 'actif', port: portQ }|{ etat: 'actif', port: 1 }|"; then
  srv "$MUT_OUT" 1; J="$(VF_TIROIR_MS=20000 navig froid "{\"P\":$SRV_PORT,\"attendre\":\"carte\"}")"; unsrv
  assert_eq "TU.11 — aucun ready : après 8 s, carte « Le terminal ne répond pas. Relancez /vf-cockpit --terminal. »" "$(rj "$J" '"carte="+j.carte+" ready="+j.ready')" "carte=Le terminal ne répond pas. Relancez /vf-cockpit --terminal. ready=false"
  assert_eq "T20.5 (J5, carte de P) — la commande /vf-cockpit --terminal ne se coupe jamais et son point final reste collé, à huit largeurs de fenêtre (témoin : la carte a changé de largeur au moins trois fois)" "$(rj "$J" '"mal="+JSON.stringify(j.coupure&&j.coupure.mal)+" larges="+(j.coupure&&j.coupure.largeurs>=3)')" 'mal=[] larges=true'
else sans_effet "TU.11 (injection de panne)"; fi
if mutant framesrc vf-cockpit-terminal.mjs "s#frameSrc: () => (portQ ? \`; frame-src http://127\.0\.0\.1:\${portQ}\` : ''),#frameSrc: () => '',#"; then
  srv "$MUT_OUT" 1; J="$(VF_TIROIR_MS=20000 navig froid "{\"P\":$SRV_PORT,\"attendre\":\"violation\"}")"; unsrv
  assert_eq "T8.3 / M-FRAMESRC — copie de sortie sans frame-src : une violation de CSP relevée, aucun ready reçu" "$(rj "$J" '"violation="+(j.violations.length>=1)+" ready="+j.ready')" "violation=true ready=false"
else sans_effet "M-FRAMESRC"; fi

echo "=== M-MSG-DONNEE — client de Q qui joint du texte du terminal à un message (T17.5) ==="
if mutant donnee vf-cockpit-terminal-client.mjs 's|term.write(m.value);|term.write(m.value); window.parent.postMessage(new TextDecoder().decode(m.value), cfg.origineP);|'; then
  VF_TIROIR_MS=20000 run_flag "$MUT_OUT" 1; J="$FJ"
  assert_eq "M-MSG-DONNEE — le mutant rougit T17.5 : un message hors liste ou portant le marqueur arrive à P (témoin : la commande a tourné)" "$(rj "$J" '"fichier="+j.t175.fichier+" rouge="+(j.t175.hors_liste>=1||j.t175.marqueur>=1)')" "fichier=true rouge=true"
else sans_effet "M-MSG-DONNEE"; fi

echo "=== TP.4-TP.8 — le tiroir s'ouvre sur « proposition » : sans focus, sans canal vers Q, pastille de la clôture 71 intacte ==="
run_prop "$OUT"; PJ0="$PJ"
PA="Proposition de lancement dans le terminal."
assert_eq "TP.0 — témoin : le scénario n'a pas échoué (aucune étape en erreur), le tiroir était fermé et la valeur fixe de Q est parvenue à P" "$(rj "$PJ0" '(j.erreur||JSON.stringify(j.erreurs))+" ferme="+(j.avant&&!j.avant.ouvert)+" recu="+(j.ouvre1&&j.ouvre1.recu)')" "{} ferme=true recu=true"
assert_eq "TP.4 — tiroir fermé, « proposition » de Q : il s'ouvre, le focus reste sur l'élément de P, un seul cadre, même shell, annonce « $PA »" "$(rj "$PJ0" '"ouvre="+(j.ouvre1&&j.ouvre1.ouvert)+" focus="+(j.ouvre1&&j.ouvre1.focus)+" cadres="+(j.ouvre1&&j.ouvre1.cadres)+" shell="+(j.ouvre1&&j.pid0&&j.ouvre1.pid===j.pid0?"meme":"autre")+" annonce="+(j.ouvre1&&j.ouvre1.annonce)')" "ouvre=true focus=temoin cadres=1 shell=meme annonce=$PA"
assert_eq "TP.5 — tiroir déjà ouvert : même hauteur, même focus, aucun cadre de plus, l'annonce seule est redite (effacée avant)" "$(rj "$PJ0" '"ouvert="+(j.ouvre2&&j.ouvre2.ouvert)+" h="+(j.ouvre2&&j.ouvre1&&j.ouvre2.h===j.ouvre1.h&&j.ouvre1.h>0)+" focus="+(j.ouvre2&&j.ouvre2.focus)+" cadres="+(j.ouvre2&&j.ouvre2.cadres)+" annonce="+(j.ouvre2&&j.ouvre2.annonce)')" "ouvert=true h=true focus=temoin cadres=1 annonce=$PA"
assert_eq "TP.7 — après ouverture par proposition puis fermeture au bouton : la pastille est sous #zoom (haut >= bas du zoom), ne le recouvre pas et reprend son rectangle d'avant le cycle" "$(rj "$PJ0" '(()=>{const a=j.apres,v=j.avant;if(!a||!v||!a.pastille||!a.zoom||!v.pastille)return "cycle="+!!a;const p=a.pastille,z=a.zoom,inter=p.l<z.r&&p.r>z.l&&p.t<z.b&&p.b>z.t;return "cycle=true sous="+(p.t>=z.b)+" libre="+(!inter)+" meme="+(JSON.stringify(p)===JSON.stringify(v.pastille)&&JSON.stringify(z)===JSON.stringify(v.zoom))})()')" "cycle=true sous=true libre=true meme=true"
assert_eq "TP.8 — la proposition ne passe pas par la branche des états : barre « Connecté », pastille « session en cours », 0 violation de CSP, espion : que des valeurs de la liste étendue (la valeur fixe y figure)" "$(rj "$PJ0" '"ouvre="+(j.ouvre1&&j.ouvre1.ouvert)+" barre="+(j.apres&&j.apres.barre)+" etiquette="+(j.apres&&j.apres.etiquette)+" violations="+(j.violations&&j.violations.length)+" hors_liste="+(j.espion&&j.espion.hors_liste)+" prop="+(j.espion&&j.espion.proposition>=1)')" "ouvre=true barre=Connecté etiquette=Ouvrir le terminal, une session est en cours violations=0 hors_liste=0 prop=true"
assert_eq "TP.6 — tiroir fermé : postMessage de P, MessageEvent forgé, « proposition:ouvre », « Proposition », « proposition » + espace, 10 000 caractères depuis Q : il reste fermé ; témoin : la vraie valeur de Q l'ouvre ensuite" "$(rj "$PJ0" 'JSON.stringify(j.hostile)')" '{"deP":true,"forge":true,"suffixe":true,"majuscule":true,"espace":true,"long":true,"vivant":true}'
mut_prop_nav() { # mut_prop_nav <libellé> <nom> <expression-sed> <expression de rougissement sur le relevé du mutant>
  if mutant "$2" vf-cockpit-terminal-tiroir.mjs "$3"; then
    VF_TIROIR_MS=20000 run_prop "$MUT_OUT"
    assert_eq "$1 $2 — le mutant rougit : $5 (témoin : aucune erreur de scénario)" "$(rj "$PJ" '(j.erreur||JSON.stringify(j.erreurs))+" rouge="+('"$4"')')" "{} rouge=true"
  else sans_effet "$1 $2"; fi
}
mut_prop_nav TP.10 M-LISTE-SANS-PROPOSITION "s|, 'proposition'\]);|]);|" '!(j.ouvre1&&j.ouvre1.ouvert)' "le tiroir ne s'ouvre plus (liste sans la valeur)"
mut_prop_nav TP.11 M-PROPOSITION-COMME-ETAT 's|else if (e.data === .proposition.) proposer();||' '!(j.ouvre1&&j.ouvre1.barre==="Connecté")' "la barre perd son libellé « Connecté »"
mut_prop_nav TP.12 M-FOCUS-VOLE 's|const proposer = () => { ouvrir(false);|const proposer = () => { ouvrir(true);|' '!(j.ouvre1&&j.ouvre1.focus==="temoin")' "le focus passe au cadre"

echo "=== TH — la proposition ouvre le tiroir à 300 px au moins (PU-G-136) ==="
run_haut "$OUT"; PH="$PJ"
HV() { rj "$PH" "(()=>{const c=j.haut&&j.haut['$1'];if(!c)return 'absent';$2})()"; }
assert_eq "TH.0 — témoin : aucune étape en erreur, les six cas ont été mesurés" "$(rj "$PH" '(j.erreur||JSON.stringify(j.erreurs))+" cas="+Object.keys(j.haut||{}).length')" "{} cas=6"
for ch in evt msg; do
  assert_eq "TH.1 ($ch) — tiroir fermé réglé à 160 px : la proposition l'ouvre à 300 px au moins (avant : 160), hauteur mesurée ET aria-valuenow" "$(HV bas-$ch 'return "avant="+c.avantNow+" ouvert="+c.ouvert+" now="+(c.now>=300)+" px="+(c.px>=300)')" "avant=160 ouvert=true now=true px=true"
  assert_eq "TH.2 ($ch) — tiroir réglé à 424 px : la proposition le laisse à 424 (jamais réduit)" "$(HV haut-$ch 'return "avant="+c.avantNow+" now="+c.now+" px="+c.px')" "avant=424 now=424 px=424"
  assert_eq "TH.3 ($ch) — la hauteur mémorisée (vf.terminal.h) n'est pas touchée par le rehaussement : 160 avant, 160 après (cas bas) ; 424 avant, 424 après (cas haut)" "$(HV bas-$ch 'return c.avantMemo+"/"+c.memo') $(HV haut-$ch 'return c.avantMemo+"/"+c.memo')" "160/160 424/424"
  assert_eq "TH.4 ($ch) — plein écran : la proposition ne rehausse pas (hauteur interne restée à 160, état plein conservé)" "$(HV plein-$ch 'return "avant="+c.avantNow+" now="+c.now+" plein="+c.plein+" ouvert="+c.ouvert+" memo="+c.memo')" "avant=160 now=160 plein=true ouvert=true memo=160"
done
mut_haut() { # mut_haut <libellé> <nom> <expression-sed> <expression de rougissement>
  if mutant "$2" vf-cockpit-terminal-tiroir.mjs "$3"; then
    VF_TIROIR_MS=20000 run_haut "$MUT_OUT"
    assert_eq "$1 $2 — le mutant rougit : $5 (témoin : aucune erreur de scénario)" "$(rj "$PJ" '(j.erreur||JSON.stringify(j.erreurs))+" rouge="+('"$4"')')" "{} rouge=true"
  else sans_effet "$1 $2"; fi
}
mut_haut TH.9 M-HAUT-SANS-REHAUSSEMENT 's|if (!plein \&\& h < 300) { h = borne(300); appliquer(); }||' 'j.haut["bas-evt"].now<300&&j.haut["bas-msg"].now<300' "le tiroir reste sous 300 px par les deux chemins"
mut_haut TH.10 M-HAUT-ECRASE-MEMO 's|h = borne(300); appliquer(); }|h = borne(300); appliquer(); memoH(); }|' 'j.haut["bas-evt"].memo!=="160"' "la hauteur mémorisée est écrasée"
mut_haut TH.11 M-HAUT-REDUIT 's|if (!plein \&\& h < 300) { h = borne(300)|if (!plein) { h = borne(300)|' 'j.haut["haut-evt"].now!==424' "un tiroir à 424 px est ramené à 300"
mut_haut TH.12 M-HAUT-EN-PLEIN 's|if (!plein \&\& h < 300)|if (h < 300)|' 'j.haut["plein-evt"].now>=300' "le plein écran est rehaussé"
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
