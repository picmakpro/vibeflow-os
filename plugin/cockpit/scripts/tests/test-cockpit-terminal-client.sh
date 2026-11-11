#!/usr/bin/env bash
# test-cockpit-terminal-client.sh — client de la page du terminal (Q) : amorçage dans l'onglet, secret hors cookie, cadre sous sandbox, canal
# Q vers P, options xterm (TERM-04, TERM-05, TERM-10 statique, T17 côté Q ; P71-D-12, D-13, D-15, D-16, D-18 ; O4, O8 ; plan 71-06).
#   ST   statique (page servie par Q, scripts propres = vue et client) : T14.S1-S4 (options xterm sûres), T17.Q1-Q3 (canal sortant), T6.5 (aucun set-cookie)
#   T6   navigateur : amorçage P/project.html#t=… (SAF-1 : l'échange se fait dans le cadre de Q, jamais au premier niveau), fragment effacé AVANT l'échange, aucun cookie, stockage de Q illisible depuis P, fichier consommé
#   T9   navigateur : T9.5 cadre sandbox="allow-scripts allow-same-origin" (ready puis etat:connecte d'origine Q), T9.6 origine tierce bloquée par
#        frame-ancestors, T9.7 0 violation de CSP (Q en premier niveau, P avec le cadre attaché), TQ.1 saisie -> shell -> sortie (transport)
#   T17  T17.Q4 Ctrl+Maj+Espace dans le cadre -> message toggle reçu par P, T17.Q5 tout message reçu est dans la liste fermée
#   O4   O4.1 même onglet = reprise (le second cadre se reconnecte) · O4.2 autre onglet (sessionStorage vide) = carte « Terminal déjà ouvert »
#   O8   MESURE-O8 : liens (window.open) bloqués ou ouverts sous le sandbox minimal puis avec allow-popups, opener nul (mesure, non comptée)
#   M-*  mutants (copies de la sortie, « mutant sans effet » = FAIL) : M-COOKIE, M-FRAGMENT, M-STOCKAGE, M-PREMIER-NIVEAU, M-SANS-AMORCE, M-ETOILE, M-ECOUTE + M-CLIP, M-ANCETRES, M-SETCOOKIE
# Sans Chrome : les sections statiques tournent, la suite annonce « SUITE SAUTÉE (navigateur) » et ne compte rien d'invérifié comme réussi.
# Variables : VF_CLIENT_MS (échéance d'une attente navigateur, 20000 par défaut). Exit 0 si tout passe, 1 sinon.
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
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : TERM-04 et TERM-05 NON vérifiés, non comptés comme réussis"; fi

# shell de test : marqué par son chemin (hygiene.sh le retrouve), shell interactif sans exec
printf '#!/bin/sh\n/bin/sh -i\n' > "$WORK/bin/shell-test"; chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/stat.mjs" <<'JS'
// stat.mjs <page.html> : faits statiques des deux scripts propres (vue = 3e, client = 4e <script>), motifs tolérants (espaces, guillemets)
import fs from 'node:fs';
const h = fs.readFileSync(process.argv[2], 'utf8');
const s = [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
const p = s.slice(2).join('\n');
const n = (re) => (p.match(re) || []).length;
const etats = [...new Set([...p.matchAll(/['"`]etat:([a-z]+)['"`]/g)].map((m) => m[1]))].sort().join(',');
console.log(JSON.stringify({
  scripts: s.length, propres: p.length,
  dcs: /registerDcsHandler\(\s*\{(?=[^}]*intermediates\s*:\s*['"]\$['"])(?=[^}]*final\s*:\s*['"]q['"])/.test(p),
  winopt: /windowOptions\s*:\s*\{\s*\}/.test(p), macopt: /macOptionIsMeta\s*:\s*false/.test(p),
  presse: n(/ClipboardAddon|navigator\s*\.\s*clipboard|execCommand\s*\(/g),
  execVue: ((s[2] || '').match(/execCommand\s*\(/g) || []).length, execCopy: ((s[2] || '').match(/execCommand\(\s*['"]copy['"]\s*\)/g) || []).length,
  lien: /linkHandler\s*:/.test(p) && /activate/.test(p) && /window\s*\.\s*open\s*\([^)]*['"]noopener['"]/.test(p), confirm: n(/\bconfirm\s*\(/g),
  ecoute: n(/addEventListener\(\s*['"]message['"]|\bonmessage\s*=/g), postmsg: n(/\bpostMessage\s*\(/g), etoile: n(/postMessage\s*\([^)]*['"]\*['"]/g), etats,
}));
JS
cat > "$AUX/pagegen.mjs" <<'JS'
// pagegen.mjs <sortie> <moteur> <theme> <fichier> : page rendue par le module de la sortie (sans serveur)
import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
const [, , sortie, moteur, theme, out] = process.argv;
const m = await import(pathToFileURL(`${sortie}/vf-cockpit-terminal-page.mjs`).href);
m.preparerPage({ engineDir: moteur }); fs.writeFileSync(out, m.pageTerminal({ theme, origineP: 'http://127.0.0.1:4242' }).html);
JS
cat > "$AUX/queue.mjs" <<'JS'
// queue.mjs <module-client.mjs> : file d'entrée du client de Q sans navigateur (N11). Le client est joué avec des doublures (Terminal, fetch, DOM) ;
// on pousse un morceau VIDE puis un octet par onData et on compte les POST /entree. fetch rend la main à la boucle d'évènements (setImmediate) : une boucle sans fin ne gèle pas la mesure.
import { pathToFileURL } from 'node:url';
const posts = []; let onData = null, onBinary = null;
const el = () => ({ addEventListener() {}, setAttribute() {}, querySelector: () => null, classList: { add() {}, remove() {} }, style: {}, textContent: '' });
globalThis.getComputedStyle = () => ({ paddingTop: '0', paddingBottom: '0' });
globalThis.window = { top: {}, opener: null, parent: { postMessage() {} }, addEventListener() {}, vfTermVue: { theme: () => ({}), carte() {}, effacer() {}, bandeau() {}, collage() {} } };
globalThis.document = { fonts: { load: () => Promise.resolve(), ready: Promise.resolve() }, getElementById: el, addEventListener() {} };
globalThis.location = { hash: '', pathname: '/', search: '' };
globalThis.history = { replaceState() {} };
const memoire = () => { const m = new Map(); return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, String(v)), removeItem: (k) => m.delete(k) }; };
globalThis.localStorage = memoire(); globalThis.sessionStorage = memoire(); localStorage.setItem('vf.terminal.secret', 'a'.repeat(64));
globalThis.ResizeObserver = class { observe() {} };
globalThis.requestAnimationFrame = () => 0;
globalThis.FitAddon = { FitAddon: class { fit() {} } };
globalThis.Terminal = class {
  constructor() { this.rows = 24; this.cols = 80; this.parser = { registerDcsHandler() {} }; this.textarea = { addEventListener() {} }; }
  loadAddon() {} open() {} attachCustomKeyEventHandler() {} focus() {} write() {} paste() {} reset() {}
  onData(f) { onData = f; } onBinary(f) { onBinary = f; }
};
globalThis.fetch = (u, o = {}) => {
  if (String(u) === '/entree') { posts.push(o.body ? o.body.length : 0); return new Promise((ok) => setImmediate(() => ok({ status: 200 }))); }
  return new Promise(() => {}); // /flux et le reste : jamais de réponse
};
const m = await import(pathToFileURL(process.argv[2]).href);
m.clientTerminal({ origineP: 'http://127.0.0.1:1', theme: 'dark' });
const att = (ms) => new Promise((ok) => setTimeout(ok, ms));
for (let i = 0; i < 50 && !onData; i++) await att(20);
if (!onData) { console.log('client non démarré'); process.exit(0); }
onData('');                       // un morceau vide : jamais un POST, jamais une boucle
await att(300); const a = posts.length;
onData('x'); onBinary('');        // un octet utile, puis un rapport binaire vide
await att(300);
console.log(`apresVide=${a} total=${posts.length} vides=${posts.filter((n) => n === 0).length} utiles=${posts.filter((n) => n > 0).length}`);
process.exit(0);
JS
cat > "$AUX/etat.mjs" <<'JS'
// etat.mjs <module-client.mjs> <scenario> : la fin du flux vue par le client de Q, sans navigateur (G2, E4). Le client est joué avec des doublures (Terminal, fetch, DOM, vue) ;
// scénarios : arret (flux fermé puis /etat {"etat":"arret"}) · coupure (serveur injoignable : flux et /etat échouent) · python (flux 503 puis /etat indisponible/python3-absent).
// Une ligne : cartes=<types, en ordre>@<vite si la première est venue en moins de 500 ms> bandeaux=<oui|non> flux=<appels à /flux> messages=<postMessage vers P, dans l'ordre>
import { pathToFileURL } from 'node:url';
const sc = process.argv[3], t0 = Date.now(), cartes = [], msgs = []; let bandeaux = 0, flux = 0, premiere = 0;
const el = () => ({ addEventListener() {}, setAttribute() {}, querySelector: () => null, classList: { add() {}, remove() {} }, style: {}, textContent: '' });
globalThis.getComputedStyle = () => ({ paddingTop: '0', paddingBottom: '0' });
globalThis.window = { top: {}, opener: null, parent: { postMessage: (m) => msgs.push(m) }, addEventListener() {},
  vfTermVue: { theme: () => ({}), carte: (t) => { if (!premiere) premiere = Date.now() - t0; cartes.push(t); }, effacer() {}, bandeau: () => { bandeaux++; }, collage() {}, invisible: () => false } };
globalThis.document = { fonts: { load: () => Promise.resolve(), ready: Promise.resolve() }, getElementById: el, addEventListener() {} };
globalThis.location = { hash: '', pathname: '/', search: '' };
globalThis.history = { replaceState() {} };
const memoire = () => { const m = new Map(); return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, String(v)), removeItem: (k) => m.delete(k) }; };
globalThis.localStorage = memoire(); globalThis.sessionStorage = memoire(); localStorage.setItem('vf.terminal.secret', 'a'.repeat(64));
globalThis.ResizeObserver = class { observe() {} };
globalThis.requestAnimationFrame = () => 0;
globalThis.FitAddon = { FitAddon: class { fit() {} } };
globalThis.Terminal = class {
  constructor() { this.rows = 24; this.cols = 80; this.parser = { registerDcsHandler() {} }; this.textarea = { addEventListener() {} }; }
  loadAddon() {} open() {} attachCustomKeyEventHandler() {} focus() {} write() {} paste() {} reset() {} resize() {} onData() {} onBinary() {}
};
const rep = (status, corps) => ({ status, ok: status >= 200 && status < 300, json: async () => corps, body: { getReader: () => ({ read: async () => ({ done: true }) }) } });
globalThis.fetch = async (u) => {
  const url = String(u);
  if (url === '/flux') { flux++; if (sc === 'arret') return rep(200, null); if (sc === 'python') return rep(503, null); throw new Error('injoignable'); }
  if (url === '/etat') {
    if (sc === 'arret') return rep(200, { etat: 'arret' });
    if (sc === 'python') return rep(200, { etat: 'indisponible', raison: 'python3-absent' });
    throw new Error('injoignable');
  }
  return rep(204, null);
};
const m = await import(pathToFileURL(process.argv[2]).href);
m.clientTerminal({ origineP: 'http://127.0.0.1:1', theme: 'dark' });
await new Promise((ok) => setTimeout(ok, sc === 'coupure' ? 2500 : 1500));
console.log(`cartes=${cartes.join(',')}@${premiere && premiere < 500 ? 'vite' : premiere || 'jamais'} bandeaux=${bandeaux > 0 ? 'oui' : 'non'} flux=${sc === 'coupure' ? (flux >= 2 ? '>=2' : flux) : flux} messages=${[...new Set(msgs)].join(",")}`);
process.exit(0);
JS
cat > "$AUX/tierce.mjs" <<'JS'
// tierce.mjs <port> <urlQ> : origine tierce qui encadre Q ; consigne les messages reçus (espion posé dans la page)
import http from 'node:http';
const [, , port, urlq] = process.argv;
const page = `<!doctype html><title>tierce</title><script>window.__msgs=[];addEventListener('message',function(e){window.__msgs.push({o:e.origin,d:String(e.data).slice(0,40)})})</script><iframe src="${urlq}/?theme=dark" style="width:400px;height:240px"></iframe>`;
http.createServer((q, r) => { r.writeHead(200, { 'Content-Type': 'text/html' }); r.end(page); }).listen(Number(port), '127.0.0.1');
JS
cat > "$AUX/chrome-client.mjs" <<'JS'
// chrome-client.mjs <chrome> <mode> <json> : scénarios navigateur du client de Q ; UNE ligne JSON. Modes : t6 · cadre · tierce.
// Chaque étape est isolée (essai) : une mesure indisponible est nommée dans `erreurs`, jamais un résultat vide. Amorçage et secret sont masqués en sortie.
import { pathToFileURL } from 'node:url'; import { execFileSync } from 'node:child_process'; import fs from 'node:fs';
const { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, AMORCE } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv;
const { P, Q, amorce, tierce, secret: secretN = '', pid: pidN = 0, fichier = '', octets = 0 } = JSON.parse(brut);
const OP = `http://127.0.0.1:${P}`, OQ = `http://127.0.0.1:${Q}`, MS = Number(process.env.VF_CLIENT_MS) || 20000;
const LISTE = ['ready', 'etat:connecte', 'etat:reconnexion', 'etat:termine', 'etat:refuse', 'etat:expire', 'etat:arrete', 'toggle'];
const erreurs = {};
const essai = async (nom, f) => { try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 140); return undefined; } };
const INVITE = `/\\$/.test((document.querySelector('.xterm-rows') || {}).textContent || '')`;
const masquer = (o, secret) => { let t = JSON.stringify(o).split(amorce).join('<amorce>'); if (secret) t = t.split(secret).join('<secret>'); return JSON.parse(t); };

// Q n'ouvre un shell que dans son cadre (F4, P71-D-25) : les scénarios qui attendent un shell jouent Q dans un cadre sandbox de P, plein viewport, comme le tiroir.
// `q` : ev/attendre/naviguer visent le monde principal du cadre de Q (retrouvé par sondage des identifiants de contexte, qui repartent de 1 à chaque processus de rendu : le socle n'expose pas les évènements).
const SBXQ = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
let ctx = 0;
const mondeQ = async (s, etendue = 600) => {
  let trouve = 0;
  for (let id = 1; id < etendue; id++) {
    const v = await s.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
    if (v === true) trouve = id;
  }
  return trouve;
};
const facadeQ = (s) => {
  const ev = async (expression) => { const x = await s.send('Runtime.evaluate', { expression, contextId: ctx, returnByValue: true, awaitPromise: true }); return x && x.result && x.result.value; };
  const attendre = async (expr, nom, ms = MS) => {
    const fin = Date.now() + ms; let v;
    do { try { v = await ev(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
    throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
  };
  const naviguer = async () => {
    ctx = 0;
    await s.naviguer(`${OP}/project.html`); await s.attendre(`document.readyState === 'complete'`, 'page P', MS);
    await s.ev(`(() => { document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove()); const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBXQ)});
      f.style.cssText = 'position:fixed;left:0;top:0;width:100vw;height:100vh;border:0;z-index:99999'; f.src = '${OQ}/?theme=dark'; document.body.appendChild(f); })()`);
    const fin = Date.now() + MS;
    let essais = 0;
    while (!ctx) { ctx = await mondeQ(s, 600 * 5 ** Math.min(essais++, 3)); if (!ctx) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
    await attendre(`!!document.querySelector('.xterm-helper-textarea') || !!document.querySelector('#etat:not([hidden])')`, 'terminal ou carte dans le cadre');
    await s.ev(`document.querySelector('iframe[data-t]').focus()`); await ev(`(document.querySelector('.xterm-helper-textarea') || document.body).focus()`);
  };
  return { ev, attendre, naviguer, send: s.send };
};

await executer(chrome, async (s) => {
  const att = (expr, nom) => s.attendre(expr, nom, MS);
  const q = facadeQ(s);
  const poll = async (f, nom) => { const fin = Date.now() + MS; for (;;) { const v = await f().catch(() => null); if (v) return v; if (Date.now() > fin) throw new Error(`attente de « ${nom} » dépassée (${MS} ms)`); await pause(100); } };
  const r = { erreurs };

  if (mode === 'tierce') {
    await essai('tierce', async () => {
      await s.naviguer(tierce);
      await poll(async () => s.violations.some((v) => /frame-ancestors/.test(v)), 'violation frame-ancestors');
    });
    r.violations = [...s.violations];
    r.msgs = await s.ev('JSON.stringify(window.__msgs)').then((x) => JSON.parse(x || '[]')).catch(() => []);
    r.temoin = await s.ev(`({ cadres: document.querySelectorAll('iframe').length, href: location.href })`).catch(() => null); // la page tierce a chargé et porte le cadre de Q : la sonde s'est exécutée
    return masquer(r);
  }

  // --- scénarios sur le serveur réel : secret périmé (J2), serveur arrêté (J2), « Terminé » (J12), onBinary (S5), contre-pression (S3) ---
  if (['perime', 'arret', 'termine', 'binaire', 'pression', 'popup', 'gros', 'limite', 'sansamorce', 'reprise'].includes(mode)) {
    const att = (expr, nom) => q.attendre(expr, nom, MS);
    const texte = () => q.ev(`(document.getElementById('etat') || {}).textContent || ''`).catch(() => '');
    const invite = () => q.ev(INVITE).catch(() => false);
    const lignes = () => q.ev(`(document.querySelector('.xterm-rows') || {}).textContent || ''`).catch(() => '');
    const taper = async (t) => {
      for (const c of t) { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: c, text: c, unmodifiedText: c }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: c }); }
      await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' });
      await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 });
    };
    const etatServeur = () => q.ev(`fetch('/etat', { headers: { 'X-VF-Terminal': localStorage.getItem('vf.terminal.secret'), 'X-VF-Onglet': sessionStorage.getItem('vf.terminal.onglet') }, cache: 'no-store' }).then((x) => x.json()).then((j) => j.session)`).catch(() => '?');
    // le secret est posé dans le stockage de Q (premier niveau) : la page se charge ensuite comme après un amorçage réussi
    if (mode !== 'sansamorce') await essai('secret', async () => { await s.naviguer(`${OQ}/`); await s.ev(`localStorage.setItem('vf.terminal.secret', ${JSON.stringify(secretN)})`); }); // sansamorce : aucun secret rangé, comme dans un onglet où le terminal n'a jamais été ouvert
    r.mode = mode;
    if (mode === 'perime') {
      const t0 = Date.now();
      await essai('carte-expiree', async () => { await q.naviguer(); await att(`(document.getElementById('etat') || {}).textContent && document.getElementById('etat').textContent.includes('Session expirée')`, 'carte Session expirée (secret périmé)'); });
      r.duree = Date.now() - t0; r.carte = await texte();
    } else if (mode === 'sansamorce') {
      // PU-G-132 : aucun secret dans le stockage de Q (onglet où le terminal n'a jamais été ouvert) : la carte le dit juste, elle ne prétend pas qu'une session a expiré
      await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `if (window.top === window) { window.__msgs = []; addEventListener('message', (e) => { if (typeof e.data === 'string') window.__msgs.push(e.data); }); }` });
      await essai('carte-sans-amorce', async () => { await q.naviguer(); await att(`((document.getElementById('etat') || {}).textContent || '').length > 0`, 'une carte dans le cadre (secret absent)'); });
      await pause(800); r.msgs = await s.ev('JSON.stringify(window.__msgs || [])').then((x) => JSON.parse(x || '[]')).catch(() => ['?']); // ce que P a reçu : la barre du tiroir ne doit pas dire « Session expirée »
      r.carte = await texte();
    } else if (mode === 'reprise') {
      // DG-08 : un cadre qui se reconnecte à un shell déjà ouvert, à une AUTRE taille, dit sa taille : le terminal la reprend (stty size) ; sinon le shell dessine pour une grille que l'écran n'a pas
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1000, height: 700, deviceScaleFactor: 1, mobile: false });
      await essai('invite', async () => { await q.naviguer(); await att(INVITE, 'invite du shell'); });
      await q.ev(`localStorage.setItem('vf.terminal.accueil', '1')`); // la phrase d'accueil (LB3-S2 : dans la colonne) rétrécirait le terminal et ferait redire la taille au second cadre : elle masquerait ce que ce scénario mesure ; elle est rangée avant (son propre témoin : LB.V20)
      await q.ev(`(() => { const f0 = window.fetch; window.fetch = function (u) { if (String(u) === '/taille') return Promise.resolve(new Response(null, { status: 204 })); return f0.apply(this, arguments); }; })()`); // le premier cadre ne dit plus sa taille : le terminal garde celle de sa création
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1000, height: 400, deviceScaleFactor: 1, mobile: false });
      await essai('reconnexion', async () => { await q.naviguer(); await att(INVITE, 'invite après la reconnexion'); });
      const GRILLE = `document.querySelectorAll('.xterm-rows > div').length`;
      await stabiliser(() => q.ev(GRILLE).catch(() => -2), { max: 5000 }); // le terminal a pris la grille de l'écran (et dit sa taille) avant la commande
      await essai('taille', async () => { await taper('echo TAI""LLE=$(stty size)x'); await poll(async () => /TAILLE=\d+ \d+x/.test(await lignes()), 'sortie de stty size'); });
      const m = /TAILLE=(\d+) (\d+)x/.exec(await lignes()); r.pty = m ? Number(m[1]) : -1;
      r.ecran = await stabiliser(() => q.ev(GRILLE).catch(() => -2), { max: 5000 });
    } else if (mode === 'arret') {
      await essai('invite', async () => { await q.naviguer(); await att(INVITE, 'invite du shell'); });
      try { process.kill(pidN, 'SIGTERM'); r.tue = true; } catch (e) { r.tue = false; }
      await essai('carte-arret', async () => { await q.attendre(`(document.getElementById('etat') || {}).textContent && document.getElementById('etat').textContent.includes('Serveur arrêté')`, 'carte Serveur arrêté', 60000); });
      r.carte = await texte();
    } else if (mode === 'termine') {
      const BANDEAU = `((document.getElementById('etat') || {}).textContent || '').includes('terminé')`;
      await essai('invite', async () => { await q.naviguer(); await att(INVITE, 'invite du shell'); });
      await essai('exit', async () => { await taper('exit'); await att(BANDEAU, 'bandeau « Le shell s’est terminé »'); });
      r.avant = { bandeau: (await texte()).includes('terminé'), session: await etatServeur() };
      await essai('rechargement', async () => { await q.naviguer(); await poll(async () => (await texte()).includes('terminé') || (await invite()), 'bandeau ou invite après rechargement'); });
      r.apres = { bandeau: (await texte()).includes('terminé'), session: await etatServeur() };
      await essai('relance', async () => {
        await q.ev(`(() => { const b = [...document.querySelectorAll('button')].find((x) => x.textContent.includes('Relancer')); if (b) b.click(); return !!b; })()`);
        await poll(async () => (await invite()) && (await etatServeur()) === 'vivante', 'nouveau shell après « Relancer le shell »');
      });
      r.relance = { bandeau: (await texte()).includes('terminé'), session: await etatServeur() };
    } else if (mode === 'binaire') {
      await essai('invite', async () => { await q.naviguer(); await att(INVITE, 'invite du shell'); });
      // suivi de la souris en codage par défaut : xterm l'émet par onBinary ; le noyau renvoie l'écho des octets reçus (ESC affiché « ^[ »)
      await essai('souris', async () => {
        await taper(`printf '\\033[?1000h';cat -v`);
        await poll(async () => {
          await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 200, y: 100, button: 'left', buttons: 1, clickCount: 1 });
          await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 200, y: 100, button: 'left', buttons: 0, clickCount: 1 });
          return (await lignes()).includes('^[[M');
        }, 'rapport de souris (onBinary) revenu du shell');
      });
      r.rapport = (await lignes()).includes('^[[M');
    } else if (mode === 'pression') {
      await essai('invite', async () => { await q.naviguer(); await att(INVITE, 'invite du shell'); });
      await q.ev(`(() => { window.__e = 0; const f0 = window.fetch; window.fetch = function (u) { if (String(u) === '/entree') { window.__e++; if (window.__e <= 2) return Promise.resolve(new Response(null, { status: 429 })); } return f0.apply(this, arguments); }; })()`);
      await essai('saisie', async () => { await taper(`echo PRESS""ION-OK`); await poll(async () => (await lignes()).includes('PRESSION-OK'), 'sortie de la commande saisie sous contre-pression'); });
      r.appels = await q.ev('window.__e').catch(() => -1); r.sortie = (await lignes()).includes('PRESSION-OK');
    } else if (mode === 'gros' || mode === 'limite') {
      // M4 : une entrée de plus de 64 Kio (collage) part en tranches, dans l'ordre, sans 413 ; « limite » : un serveur qui refuse au-delà de 4 Kio (413 synthétique) -> la page découpe et rien n'est perdu
      await essai('invite', async () => { await q.naviguer(); await att(INVITE, 'invite du shell'); });
      await q.ev(`(() => { window.__tr = []; const f0 = window.fetch; window.fetch = function (u, o) { if (String(u) !== '/entree') return f0.apply(this, arguments);
        const n = o.body.length; if (${mode === 'limite'} && n > 4096) { window.__tr.push([n, 413]); return Promise.resolve(new Response(null, { status: 413 })); }
        return f0.apply(this, arguments).then((x) => { window.__tr.push([n, x.status]); return x; }); }; })()`);
      await essai('prepare', async () => { await taper(`stty raw -echo; echo PRET-""OK; head -c ${octets} | cksum > ${fichier}`); await poll(async () => (await lignes()).includes('PRET-OK'), 'shell prêt à lire en brut'); });
      await essai('collage', async () => { await q.ev(`(() => { const dt = new DataTransfer(); dt.setData('text/plain', 'a'.repeat(${octets})); document.getElementById('terminal').dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true })); return true; })()`); });
      await essai('cksum', async () => { await poll(async () => { try { return fs.readFileSync(fichier, 'utf8').trim(); } catch (e) { return ''; } }, 'somme de contrôle écrite par le shell'); });
      r.cksum = (() => { try { return fs.readFileSync(fichier, 'utf8').trim(); } catch (e) { return ''; } })();
      r.tr = await q.ev('JSON.stringify(window.__tr)').then((x) => JSON.parse(x || '[]')).catch(() => []);
    } else if (mode === 'popup') {
      // F4 : Q ouverte en popup par P (window.open copie le sessionStorage, donc l'identifiant d'onglet) ne prend pas la session et ne lance aucun shell
      // P71-D-33 : les assistants sont enfants du processus du terminal (lui-même enfant du serveur) ; on compte sous les deux
      const shells = () => { const ls = execFileSync('ps', ['-axo', 'pid=,ppid=,args=']).toString().split('\n').map((l) => l.trim().split(/\s+/)); const peres = new Set([String(pidN), ...ls.filter((c) => c[1] === String(pidN) && /vf-cockpit-terminal-processus\.mjs/.test(c.slice(2).join(' '))).map((c) => c[0])]); return ls.filter((c) => peres.has(c[1]) && /vf-cockpit-pty\.py/.test(c.slice(2).join(' '))).length; };
      const popups = async () => (await s.send('Target.getTargets')).targetInfos.filter((t) => t.type === 'page' && t.url.includes('theme=dark')).length;
      await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
      const refocaliser = async () => { await s.send('Page.bringToFront'); await s.ev(`document.querySelector('iframe[data-t]').focus()`); await q.ev(`document.querySelector('.xterm-helper-textarea').focus()`);
        await attendreValeur(() => q.ev(`document.hasFocus() && !!document.activeElement && document.activeElement.classList.contains('xterm-helper-textarea')`).catch(() => false), (v) => v === true, { max: 5000 }); }; // la frappe suivante se perd si le focus du cadre n'est pas posé
      await essai('invite', async () => { await q.naviguer(); await att(INVITE, 'invite du shell'); });
      await s.ev(`window.__msgs = []; addEventListener('message', (e) => window.__msgs.push(String(e.data).slice(0, 40)))`);
      r.avant = { shells: shells() };
      await essai('popup1', async () => { await s.send('Runtime.evaluate', { expression: `window.open('${OQ}/?theme=dark', 'vfq1') && 1`, userGesture: true }); await pause(5000); });
      r.popup1 = await popups();
      r.apres = { shells: shells(), msgs: await s.ev('JSON.stringify(window.__msgs)').then((x) => JSON.parse(x || '[]')).catch(() => []), session: await etatServeur() };
      await essai('saisie', async () => { await refocaliser(); await taper(`echo POP""UP-OK`); await poll(async () => (await lignes()).includes('POPUP-OK'), 'saisie dans le terminal légitime après le popup'); r.saisie = true; });
      await essai('exit', async () => { await refocaliser(); await taper('exit'); await att(`((document.getElementById('etat') || {}).textContent || '').includes('terminé')`, 'bandeau « Le shell s’est terminé »'); });
      r.finShells = shells();
      await essai('popup2', async () => { await s.send('Runtime.evaluate', { expression: `window.open('${OQ}/?theme=dark', 'vfq2') && 1`, userGesture: true }); await pause(5000); });
      r.popup2 = await popups(); r.apresFin = { shells: shells(), session: await etatServeur() };
    }
    return masquer(r, secretN);
  }

  // --- S0 (SAF-1) : une adresse de Q avec un amorçage, ouverte seule (premier niveau), n'échange rien : carte « Terminal indisponible », aucun secret rangé, amorçage intact (S1 le consomme ensuite) ---
  r.q1 = { carte: '?', hash: '?', secret: '?' };
  if (mode === 't6') await essai('q-seul', async () => {
    await s.naviguer(`${OQ}/#t=${amorce}`);
    await att(`((document.getElementById('etat') || {}).textContent || '').includes('Terminal indisponible')`, 'carte Terminal indisponible (Q ouvert seul avec un amorçage)');
    await pause(1500);
    r.q1 = await s.ev(`({ carte: (document.getElementById('etat') || {}).textContent || '', hash: location.hash, secret: localStorage.getItem('vf.terminal.secret') === null ? 'aucun' : 'range' })`);
  });
  // --- S1 : amorçage par la page Projet (SAF-1) : P monte le cadre de Q, l'échange se fait DANS le cadre, qui se recharge sans fragment (message ready) ---
  // adresse (url + fragment) du cadre de Q dans l'arbre des cadres de la page
  const cadreQ = async () => { const f = ((await s.send('Page.getFrameTree')).frameTree.childFrames || []).find((c) => c.frame.url.startsWith(OQ)); return f ? { url: f.frame.url, fragment: f.frame.urlFragment || '' } : null; };
  r.adresse1 = '?'; r.histoireFrag = -1; r.cadre1 = null;
  await essai('amorcage', async () => {
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `if (window.top === window) { window.__prets = []; addEventListener('message', (e) => { if (typeof e.data === 'string') window.__prets.push(e.data); }); }` });
    await s.naviguer(`${OP}/project.html#t=${amorce}`);
    await s.attendre(`window.__prets.includes('ready') && !location.hash`, 'cadre de Q prêt (échange fait dans le cadre)', process.env.VF_CLIENT_MS ? MS : Math.max(MS, AMORCE)); // amorçage : borné par l'échéance globale (par défaut), sauf VF_CLIENT_MS posée explicitement (mutants à 6 s)
  });
  r.cadre1 = await cadreQ().catch(() => null);
  r.adresse1 = await s.ev('location.href').catch(() => '?');
  r.histoireFrag = await s.send('Page.getNavigationHistory').then((h) => h.entries.filter((e) => /#t=/.test(e.url)).length).catch(() => -1);

  if (mode === 't6') {
    // --- S2 : échange refusé (amorçage déjà consommé) dans le cadre de Q : son adresse reste sans fragment, carte « Session expirée » (P reçoit etat:expire, la barre le dit) ---
    r.refus = { hash: '?', port: '?', carte: '' };
    await essai('refus', async () => {
      await s.naviguer(`${OP}/project.html#t=${amorce}`);
      await att(`window.__prets.includes('etat:expire') && !location.hash`, 'etat:expire (échange refusé dans le cadre)');
    });
    const lireRefus = async () => { const c = await cadreQ(); return { hash: c.fragment, port: new URL(c.url).port, carte: await s.ev(`(document.querySelector('.vf-term-etat') || {}).textContent || ''`) }; };
    r.refus = (await attendreEtStabiliser(lireRefus, (v) => !!v && v.hash === '' && v.carte.includes('Session expirée'), { max: 8000 })) || r.refus;
    // --- S3 : Q en premier niveau : secret dans son stockage, aucun cookie, terminal vivant ---
    r.secretQ = null; r.cookieQ = '?'; r.invite = false;
    await essai('q-premier-niveau', async () => {
      await s.naviguer(`${OQ}/`);
      r.secretQ = await s.ev(`localStorage.getItem('vf.terminal.secret')`);
      r.cookieQ = await s.ev('document.cookie');
      // F4 : Q en premier niveau (ni cadre ni opener) ne prend pas la session : carte « Terminal indisponible », aucun shell
      await att(`((document.getElementById('etat') || {}).textContent || '').includes('Terminal indisponible') && !document.querySelector('.xterm')`, 'carte Terminal indisponible (Q hors cadre)');
      r.horsCadre = { carte: await s.ev(`document.getElementById('etat').textContent`), session: await s.ev(`fetch('/etat', { headers: { 'X-VF-Terminal': localStorage.getItem('vf.terminal.secret'), 'X-VF-Onglet': sessionStorage.getItem('vf.terminal.onglet') || 'x' }, cache: 'no-store' }).then((x) => x.json()).then((j) => j.session)`) };
      await q.naviguer(); await q.attendre(INVITE, 'invite du shell (Q dans le cadre)', MS);
      r.invite = true;
    });
    r.secretOk = /^[0-9a-f]{64}$/.test(r.secretQ || '');
    const secret = r.secretOk ? r.secretQ : '';
    // --- S4 : P : aucun cookie, aucune trace de l'amorçage ni du secret ; stockage de Q illisible depuis P ---
    r.cookieP = '?'; r.scanP = null; r.stockageCadre = '?'; r.stockageP = '?';
    await essai('retour-P', async () => {
      await s.naviguer(`${OP}/project.html`);
      r.cookieP = await s.ev('document.cookie');
      r.scanP = await s.ev(`(() => {
        const A = ${JSON.stringify(amorce)}, S = ${JSON.stringify(secret)};
        const st = []; for (const k of Object.keys(localStorage)) st.push(k, localStorage.getItem(k)); for (const k of Object.keys(sessionStorage)) st.push(k, sessionStorage.getItem(k));
        const nb = (t) => (t.includes(A) ? 1 : 0) + (S && t.includes(S) ? 1 : 0);
        return { adresse: nb(location.href), dom: nb(document.documentElement.outerHTML), stockage: nb(st.join('\\n')), cookie: nb(document.cookie) };
      })()`);
      r.stockageCadre = await s.ev(`(async () => {
        const f = document.createElement('iframe'); f.dataset.t = '1'; f.style.cssText = 'position:fixed;left:0;top:0;width:640px;height:360px;border:0';
        f.src = '${OQ}/?theme=dark'; await new Promise((ok) => { f.onload = ok; document.body.appendChild(f); });
        let n; try { f.contentWindow.localStorage.getItem('x'); n = 'lisible'; } catch (e) { n = e.name; } f.remove(); return n; })()`);
      r.stockageP = await s.ev(`(() => { localStorage.setItem('vf.test.temoin', '1'); const v = localStorage.getItem('vf.test.temoin') === '1' ? 'lisible' : 'illisible'; localStorage.removeItem('vf.test.temoin'); return v; })()`);
    });
    return masquer(r, secret);
  }

  // --- mode cadre : P avec le cadre de Q sous sandbox ---
  const monter = async (sandbox) => {
    await s.ev(`(() => { window.__msgs = [];
      if (!window.__espion) { window.__espion = true; addEventListener('message', (e) => window.__msgs.push({ o: e.origin, d: typeof e.data === 'string' ? e.data.slice(0, 40) : '<' + typeof e.data + '>' })); }
      document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove());
      const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(sandbox)});
      f.style.cssText = 'position:fixed;left:0;top:0;width:640px;height:360px;border:0;z-index:99999'; f.src = '${OQ}/?theme=dark'; document.body.appendChild(f); })()`);
  };
  const messages = () => s.ev('JSON.stringify(window.__msgs)').then((x) => JSON.parse(x || '[]')).catch(() => []);
  const CONNECTE = `window.__msgs.some((m) => m.d === 'etat:connecte')`;
  const SBX1 = 'allow-scripts allow-same-origin', SBX2 = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
  await essai('P', async () => { await s.naviguer(`${OP}/project.html`); await att(`document.readyState === 'complete'`, 'page P'); });

  // T9.5 / T9.7 (P)
  await essai('cadre1', async () => { await monter(SBX1); await att(CONNECTE, 'etat:connecte du cadre sandbox'); });
  r.msgs1 = await messages(); r.violationsP = [...s.violations];

  // T17.Q4 : Ctrl+Maj+Espace dans le cadre
  await essai('toggle', async () => {
    const clic = (type) => s.send('Input.dispatchMouseEvent', { type, x: 320, y: 180, button: 'left', clickCount: 1 });
    await clic('mousePressed'); await clic('mouseReleased');
    const touche = (type) => s.send('Input.dispatchKeyEvent', { type, key: ' ', code: 'Space', windowsVirtualKeyCode: 32, modifiers: 10 });
    await touche('keyDown'); await touche('keyUp');
    await att(`window.__msgs.some((m) => m.d === 'toggle')`, 'message toggle');
  });
  r.msgsToggle = await messages();

  // O8 : window.open depuis le cadre, sandbox minimal puis avec allow-popups
  const o8 = async (sandbox) => {
    await monter(sandbox);
    const enfant = await poll(async () => (await s.send('Page.getFrameTree')).frameTree.childFrames?.find((c) => c.frame.url.startsWith(OQ)), 'cadre de Q dans l’arbre des cadres');
    const monde = await s.send('Page.createIsolatedWorld', { frameId: enfant.frame.id, worldName: 'o8' });
    const dans = (expression) => s.send('Runtime.evaluate', { contextId: monde.executionContextId, expression, returnByValue: true, userGesture: true }).then((x) => x?.result?.value);
    const statut = await dans(`(() => { const w = window.open('about:blank', '_blank'); if (w) { w.close(); return 'ouvert'; } return 'bloque'; })()`);
    let opener = 'sans objet';
    if (statut === 'ouvert') {
      const avant = new Set((await s.send('Target.getTargets')).targetInfos.map((t) => t.targetId));
      await dans(`window.open('about:blank', '_blank', 'noopener') && 0`);
      const nouveau = await poll(async () => (await s.send('Target.getTargets')).targetInfos.find((t) => t.type === 'page' && !avant.has(t.targetId)), 'fenêtre ouverte en noopener');
      opener = nouveau.canAccessOpener ? 'present' : 'nul';
      await s.send('Target.closeTarget', { targetId: nouveau.targetId }).catch(() => {});
    }
    return { statut, opener };
  };
  r.o8min = await essai('o8-minimal', () => o8(SBX1));
  r.o8pop = await essai('o8-popups', () => o8(SBX2));
  // O4.1 : le second cadre (monté par la mesure ci-dessus, même onglet) reprend la session
  await essai('cadre2', async () => { await monter(SBX2); await att(CONNECTE, 'etat:connecte du second cadre (reprise)'); });
  r.msgs2 = await messages();
  await s.ev(`document.querySelectorAll('iframe[data-t]').forEach((f) => f.remove())`).catch(() => {});

  // T9.7 (Q en premier niveau) + TQ.1 : saisie -> shell -> sortie
  r.invite = false; r.eco = false; r.violationsQ = [];
  const marq = `${Date.now()}`;
  await essai('q-cadre', async () => {
    await q.naviguer();
    await q.attendre(INVITE, 'invite du shell (Q dans le cadre)', MS);
    r.invite = true; r.violationsQ = [...s.violations];
    for (const c of `echo MA""RQ-${marq}`) { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: c, text: c, unmodifiedText: c }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: c }); }
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' });
    await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 });
    await q.attendre(`document.querySelector('.xterm-rows').textContent.includes('MARQ-${marq}')`, 'sortie de la commande saisie', MS);
    r.eco = true;
  });
  r.violationsQ = r.violationsQ.length ? r.violationsQ : [...s.violations];

  // O4.2 : autre onglet = sessionStorage vide
  r.autre = '?';
  await essai('autre-onglet', async () => {
    await q.ev(`sessionStorage.clear()`);
    await q.naviguer();
    await q.attendre(`(document.getElementById('etat') || {}).textContent && document.getElementById('etat').textContent.includes('Terminal déjà ouvert')`, 'carte Terminal déjà ouvert', MS);
  });
  r.autre = await q.ev(`(document.getElementById('etat') || {}).textContent || ''`).catch(() => '?');
  r.liste = LISTE;
  return masquer(r);
}, { csp: true });
JS

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
srv() { # srv <sortie> -> SRV_PORT SRV_PID SRV_O SRV_OUT QP AMORCE ; serveur lancé directement avec --terminal, comme le lanceur
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"; mkdir -p "$o/.cache"
  AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce")
  COCKPIT_PRET=terminal COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" --terminal
  SRV_PID="$VF_PID"
  SRV_PORT="${VF_PORT:-0}"; QP="$(sj '(j.terminal&&j.terminal.url)||"http://127.0.0.1:0"')"; QP="${QP##*:}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
mutant() { # mutant <nom> <fichier-relatif-à-la-sortie> <expression-sed> -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
navig() { node "$AUX/chrome-client.mjs" "$CHROME" "$@"; } # navig <mode> <json>
run_t6() { # run_t6 <sortie> -> T6J T6_FICHIER ; un serveur neuf, un amorçage neuf, un Chrome neuf
  srv "$1"; T6_P=$SRV_PORT; T6_Q=$QP
  T6J="$(navig t6 "{\"P\":$T6_P,\"Q\":$T6_Q,\"amorce\":\"$AMORCE\"}")"
  T6_FICHIER="$([ -e "$1/.cache/terminal-amorce" ] && echo present || echo supprime)"; unsrv
}

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
ATTENDU_ETATS="arrete,connecte,expire,refuse,reconnexion,termine"

echo "=== ST — scripts propres de la page servie par Q (statique) ==="
srv "$OUT"; mkdir -p "$WORK/q"; rq "$QP" GET / --corps-vers "$WORK/q/page.html" > "$WORK/q/page.out"
ST="$(node "$AUX/stat.mjs" "$WORK/q/page.html")"
assert_eq "ST.0 — témoin : la page de Q a ses quatre <script> (les deux derniers sont les scripts propres)" "$(rj "$ST" 'j.scripts')" "4"
assert_eq "T14.S1 — gestionnaire DCS de remplacement (registerDcsHandler sur \$ et q) dans le client servi" "$(rj "$ST" 'j.dcs')" "true"
assert_eq "T14.S2 — windowOptions vide et macOptionIsMeta faux" "$(rj "$ST" 'j.winopt+"/"+j.macopt')" "true/true"
assert_eq "T14.S3 — aucun addon presse-papiers ni navigator.clipboard dans les scripts propres, et UN SEUL execCommand : execCommand('copy') dans la vue, pour le bouton « Copier la commande » de la carte (Q14, arbitrage de Samuel, AskUserQuestion, session principale, 2026-11-06) ; le client n'en a aucun (la page est vivante : propres > 200)" "$(rj "$ST" '(j.presse-j.execVue)+"/"+j.execVue+"/"+j.execCopy+"/"+(j.propres>200)')" "0/1/1/true"
assert_eq "T14.S4 — linkHandler avec activate qui ouvre en noopener ; aucun confirm(" "$(rj "$ST" 'j.lien+"/"+j.confirm')" "true/0"
assert_eq "T17.Q1 — aucun écouteur de messages entrants dans Q (la page est vivante : propres > 200)" "$(rj "$ST" 'j.ecoute+"/"+(j.propres>200)')" "0/true"
assert_eq "T17.Q2 — au moins un postMessage( et aucun avec l'étoile" "$(rj "$ST" '(j.postmsg>=1)+"/"+j.etoile')" "true/0"
assert_eq "T17.Q3 — les littéraux etat:* des scripts propres sont exactement les six valeurs de la liste" "$(rj "$ST" 'j.etats' | tr ',' '\n' | sort | tr '\n' ',')" "$(printf '%s' "$ATTENDU_ETATS" | tr ',' '\n' | sort | tr '\n' ',')"
# T6.5 : aucun set-cookie sur les routes de Q (réponses admises ET refusées), témoin : l'échange réussit
rq "$QP" GET / > "$WORK/q/c-page.out"; rq "$QP" POST /amorce --amorce "mauvais" > "$WORK/q/c-refus.out"
rq "$QP" POST /amorce --amorce "$AMORCE" > "$WORK/q/c-amorce.out"; SEC="$(sed 1,2d "$WORK/q/c-amorce.out" | node "$AUX/ev.mjs" j.secret 2>/dev/null)"
rq "$QP" GET /etat --secret "$SEC" > "$WORK/q/c-etat.out"; rq "$QP" POST /entree --secret "$SEC" --onglet c0ffee --corps "" > "$WORK/q/c-entree.out"
COOKIES=0; for f in page refus amorce etat entree; do COOKIES=$((COOKIES + $(sed -n 2p "$WORK/q/c-$f.out" | node "$AUX/ev.mjs" 'Object.keys(j).filter(k=>k==="set-cookie").length' 2>/dev/null || echo 9))); done
assert_eq "T6.5 — aucun set-cookie sur GET /, POST /amorce (refusé et admis), GET /etat, POST /entree (témoin : l'échange rend un secret de 64 hexadécimaux)" "$COOKIES/$([[ "$SEC" =~ ^[0-9a-f]{64}$ ]] && echo secret || echo "sans-secret")" "0/secret"
unsrv

echo "=== M-ETOILE / M-ECOUTE / M-CLIP / M-SETCOOKIE — mutants statiques ==="
mut_page() { node "$AUX/pagegen.mjs" "$MUT_OUT" "$ENG" dark "$WORK/m-$1.html"; node "$AUX/stat.mjs" "$WORK/m-$1.html"; }
if mutant etoile vf-cockpit-terminal-client.mjs "s|MESSAGES\[cle\], cfg.origineP|MESSAGES[cle], '*'|"; then
  assert_eq "M-ETOILE — le mutant rougit T17.Q2 : un postMessage avec l'étoile" "$(rj "$(mut_page etoile)" 'j.etoile>=1')" "true"
else sans_effet "M-ETOILE"; fi
if mutant ecoute vf-cockpit-terminal-client.mjs "s|const RACCOURCI|addEventListener('message', () => {}); const RACCOURCI|"; then
  assert_eq "M-ECOUTE — le mutant rougit T17.Q1 : un écouteur de messages entrants" "$(rj "$(mut_page ecoute)" 'j.ecoute>=1')" "true"
else sans_effet "M-ECOUTE"; fi
if mutant execc vf-cockpit-terminal-client.mjs "s|const RACCOURCI|document.execCommand('copy'); const RACCOURCI|"; then
  assert_eq "M-EXEC — un second execCommand (dans le client) rougit T14.S3 : le presse-papiers ne se touche que par la vue" "$(rj "$(mut_page execc)" '(j.presse-j.execVue)>=1')" "true"
else sans_effet "M-EXEC"; fi
if mutant clip vf-cockpit-terminal-client.mjs "s|const RACCOURCI|navigator.clipboard.writeText('x'); const RACCOURCI|"; then
  assert_eq "M-CLIP — le mutant rougit T14.S3 : un appel au presse-papiers" "$(rj "$(mut_page clip)" '(j.presse-j.execVue)>=1')" "true"
else sans_effet "M-CLIP"; fi
if mutant setcookie vf-cockpit-terminal-processus.mjs "s|res.setHeader('Referrer-Policy', 'no-referrer');|res.setHeader('Referrer-Policy', 'no-referrer'); res.setHeader('Set-Cookie', 'a=b');|"; then
  srv "$MUT_OUT"; rq "$QP" GET / > "$WORK/m-setcookie.out"
  assert_eq "M-SETCOOKIE — le mutant rougit T6.5 : set-cookie présent" "$(sed -n 2p "$WORK/m-setcookie.out" | node "$AUX/ev.mjs" 'Object.keys(j).filter(k=>k==="set-cookie").length' 2>/dev/null)" "1"; unsrv
else sans_effet "M-SETCOOKIE"; fi

echo "=== N11 — file d'entrée : un morceau vide est retiré sans envoi, jamais de boucle de POST vides (sans navigateur) ==="
file_vide() { node "$AUX/queue.mjs" "$1/vf-cockpit-terminal-client.mjs"; }
assert_eq "N11.1 — un morceau vide (onData vide) ne part jamais : 0 POST vide, la file est vidée (l'octet utile suivant part seul, une fois)" "$(file_vide "$OUT")" "apresVide=0 total=1 vides=0 utiles=1"
if mutant videtout vf-cockpit-terminal-client.mjs 's|while (file.length && file\[0\].length === 0) file.shift();||;s|if (!corps.length) break;||'; then
  assert_eq "M-VIDE-TOUT — le mutant (le code d'avant : ni retrait ni garde) rougit N11.1 : boucle de POST vides (plus de 100 en 300 ms)" "$(file_vide "$MUT_OUT" | awk '{ split($3, v, "="); print (v[2] > 100) ? "rouge" : "identique : " $0 }')" "rouge"
else sans_effet "M-VIDE-TOUT"; fi
if mutant videenvoi vf-cockpit-terminal-client.mjs 's|if (!corps.length) break;||'; then
  assert_eq "M-VIDE-ENVOI — le mutant (la file vidée envoie encore un corps vide) rougit N11.1 : au moins un POST vide" "$(file_vide "$MUT_OUT" | awk '{ split($3, v, "="); print (v[2] >= 1) ? "rouge" : "identique : " $0 }')" "rouge"
else sans_effet "M-VIDE-ENVOI"; fi

echo "=== G2 / E4 — fin du flux : arrêt volontaire dit tout de suite, Python 3 absent dit en clair, vraie coupure = reconnexion (sans navigateur) ==="
etat_fin() { node "$AUX/etat.mjs" "$1/vf-cockpit-terminal-client.mjs" "$2"; }
assert_eq "G2.1 — /etat {\"etat\":\"arret\"} à la fin du flux : la carte « Serveur arrêté » s'affiche tout de suite (moins de 500 ms, pas de « Reconnexion… »), P reçoit etat:arrete, un seul flux" "$(etat_fin "$OUT" arret)" "cartes=arrete@vite bandeaux=non flux=1 messages=ready,etat:connecte,etat:arrete"
assert_eq "G2.2 — témoin : une vraie coupure (serveur injoignable) garde la reconnexion : aucune carte avant 30 s, le bandeau « Reconnexion… » est posé, le flux est réessayé" "$(etat_fin "$OUT" coupure)" "cartes=@jamais bandeaux=oui flux=>=2 messages=ready,etat:reconnexion"
assert_eq "E4.1 — /etat indisponible/python3-absent : la carte « python » s'affiche tout de suite, jamais « arrete », pas d'etat:arrete vers P, pas de boucle (un seul flux)" "$(etat_fin "$OUT" python)" "cartes=python@vite bandeaux=non flux=1 messages=ready"
assert_has "E4.2 — la carte python dit le poste et la marche à suivre (installer Python 3, relancer la commande), sans le mot « arrêté »" "$(grep -E '^ *python: ' "$OUT/vf-cockpit-terminal-vue.mjs")" "Terminal indisponible', corps: ['Python 3 est introuvable sur ce poste. Installez-le, puis relancez ', COMMANDE"
assert_eq "E4.3 — la carte python ne contient pas « arrêté »" "$(grep -E '^ *python: ' "$OUT/vf-cockpit-terminal-vue.mjs" | grep -c 'arrêt')" "0"
if mutant gdeux vf-cockpit-terminal-client.mjs "s|if (e \&\& e.etat === 'arret') {|if (false) {|"; then
  assert_eq "M-G2 — le mutant (l'arrêt n'est pas lu) rougit G2.1 : aucune carte, le bandeau « Reconnexion… » est posé" "$(etat_fin "$MUT_OUT" arret | cut -d' ' -f1-2)" "cartes=@jamais bandeaux=oui"
else sans_effet "M-G2"; fi
if mutant mpython vf-cockpit-terminal-client.mjs "s|e.raison === 'python3-absent'|e.raison === 'x'|"; then
  assert_eq "M-E4 — le mutant (python3-absent non reconnu) rougit E4.1 : plus de carte, la reconnexion tourne" "$(etat_fin "$MUT_OUT" python | cut -d' ' -f1-2)" "cartes=@jamais bandeaux=oui"
else sans_effet "M-E4"; fi

if [ -n "$CHROME" ]; then
echo "=== T6 — amorçage dans l'onglet, secret hors cookie (TERM-04 ; P71-D-12, D-13) ==="
run_t6 "$OUT"; J="$T6J"; OP="http://127.0.0.1:$T6_P"
assert_eq "T6.0 — témoin : le scénario n'a pas échoué globalement" "$(rj "$J" 'j.erreur||"ok"')" "ok"
assert_eq "T6.1 — SAF-1 : P/project.html#t=… efface le fragment de son adresse avant tout autre traitement ; aucune entrée d'historique ne porte #t=" "$(rj "$J" '"adresse="+j.adresse1+" historique_avec_fragment="+j.histoireFrag')" "adresse=$OP/project.html historique_avec_fragment=0"
assert_eq "T6.1b — SAF-1 : échange refusé dans le cadre de Q : son adresse sans fragment, carte « Session expirée » (dite à P)" "$(rj "$J" '"hash=["+j.refus.hash+"] port="+j.refus.port+" carte="+(j.refus.carte.includes("Session expirée")?"oui":"non")')" "hash=[] port=$T6_Q carte=oui"
assert_eq "T6.9 — SAF-1 : Q ouvert seul avec un amorçage (premier niveau) n'échange rien : carte « Terminal indisponible », fragment effacé, aucun secret rangé ; l'amorçage reste intact (T6.1 le consomme ensuite par P)" "carte=$(rj "$J" '((j.q1||{}).carte||"?").includes("Terminal indisponible")?"oui":"non"') hash=[$(rj "$J" '(j.q1||{}).hash')] secret=$(rj "$J" '(j.q1||{}).secret')" "carte=oui hash=[] secret=aucun"
assert_eq "T6.1c — SAF-1 : après l'échange fait dans le cadre, l'adresse du cadre de Q ne porte ni fragment ni autre paramètre que theme (le cadre se recharge sans l'amorçage ni le secret)" "$(rj "$J" '"url="+((j.cadre1||{}).url||"?").replace(/theme=(dark|light)$/,"theme=<t>")+" fragment=["+((j.cadre1||{}).fragment||"")+"]"')" "url=http://127.0.0.1:$T6_Q/?theme=<t> fragment=[]"
SECRET_OK="$(rj "$J" 'j.secretOk?"oui":"non"')"
assert_eq "T6.3 — le secret (64 hexadécimaux), posé par le cadre de Q, est lisible dans le stockage de Q (relu en premier niveau : Chrome ne partitionne pas deux origines d'un même site), terminal vivant" "secret=$SECRET_OK invite=$(rj "$J" 'j.invite')" "secret=oui invite=true"
assert_eq "T6.8 — F4 : Q en premier niveau (ni cadre ni opener, après l'amorçage) n'ouvre pas de terminal : carte « Terminal indisponible », aucun shell (le serveur dit absente) ; puis le cadre de P, lui, donne l'invite" "carte=$(rj "$J" '(j.horsCadre||{}).carte||"?"') session=$(rj "$J" '(j.horsCadre||{}).session||"?"') cadre=$(rj "$J" 'j.invite')" "carte=Terminal indisponibleCe terminal ne s’ouvre que dans le cockpit. Relancez /vf-cockpit --terminal.Copier la commande session=absente cadre=true"
assert_eq "T6.2 — document.cookie vide sur P et sur Q (témoin : le secret existe bien, sinon le vide ne prouve rien)" "P=[$(rj "$J" 'j.cookieP')] Q=[$(rj "$J" 'j.cookieQ')] secret_connu=$SECRET_OK" "P=[] Q=[] secret_connu=oui"
assert_eq "T6.4 — depuis P, le stockage du cadre de Q lève SecurityError (témoins : le secret est dans Q, le stockage de P est lisible)" "$(rj "$J" 'j.stockageCadre')/secret_dans_q=$SECRET_OK/stockage_p=$(rj "$J" 'j.stockageP')" "SecurityError/secret_dans_q=oui/stockage_p=lisible"
assert_eq "T6.6 — le fichier d'amorçage est supprimé après l'échange" "$T6_FICHIER" "supprime"
assert_eq "T6.7 — ni l'amorçage ni le secret dans l'adresse, le DOM, le stockage ou les cookies de P (témoin : secret connu)" "$(rj "$J" '"adresse="+j.scanP.adresse+" dom="+j.scanP.dom+" stockage="+j.scanP.stockage+" cookie="+j.scanP.cookie')/secret_connu=$SECRET_OK" "adresse=0 dom=0 stockage=0 cookie=0/secret_connu=oui"

echo "=== T9 / T17 / O4 / O8 — cadre sous sandbox dans P (TERM-05, A1 ; P71-D-18) ==="
srv "$OUT"; CP=$SRV_PORT; CQ=$QP; OP="http://127.0.0.1:$CP"; OQ="http://127.0.0.1:$CQ"
J="$(navig cadre "{\"P\":$CP,\"Q\":$CQ,\"amorce\":\"$AMORCE\"}")"; unsrv
assert_eq "T9.0 — témoin : le scénario n'a pas échoué globalement" "$(rj "$J" 'j.erreur||"ok"')" "ok"
assert_eq "T9.5 — cadre sandbox=\"allow-scripts allow-same-origin\" dans P : ready puis etat:connecte, tous d'origine Q" "$(rj "$J" '(function(){const m=j.msgs1||[];const a=m.findIndex(x=>x.d==="ready"),b=m.findIndex(x=>x.d==="etat:connecte");return "ordre="+(a>=0&&b>a?"ok":"ko")+" origines="+[...new Set(m.map(x=>x.o))].join(",")})()')" "ordre=ok origines=$OQ"
assert_eq "T9.7 — 0 violation de CSP : P avec le cadre chargé et attaché, puis Q dans le cadre plein viewport (témoins : connecté sous sandbox, invite du shell dans le cadre)" "$(rj "$J" '"connecte="+((j.msgs1||[]).some(x=>x.d==="etat:connecte")?"oui":"non")+" P="+(j.violationsP||["?"]).length+" Q="+(j.invite?"oui":"non")+"/"+(j.violationsQ||["?"]).length')" "connecte=oui P=0 Q=oui/0"
assert_eq "TQ.1 — la saisie atteint le shell et sa sortie revient (POST /entree puis flux, Q dans le cadre)" "$(rj "$J" 'j.eco')" "true"
assert_eq "T17.Q4 — Ctrl+Maj+Espace dans le cadre : message toggle reçu par P, d'origine Q" "$(rj "$J" '"toggle="+((j.msgsToggle||[]).some(x=>x.d==="toggle"&&x.o==="'"$OQ"'")?"oui":"non")')" "toggle=oui"
assert_eq "T17.Q5 — tout message reçu par P est dans la liste fermée (au moins ready, etat:connecte et toggle ont été vus)" "$(rj "$J" '(function(){const m=[...(j.msgsToggle||[]),...(j.msgs2||[])];return "hors_liste="+m.filter(x=>!j.liste.includes(x.d)).length+" vus="+["ready","etat:connecte","toggle"].every(v=>m.some(x=>x.d===v))})()')" "hors_liste=0 vus=true"
assert_eq "O4.1 — même onglet = reprise : le second cadre se reconnecte (etat:connecte, pas etat:refuse)" "$(rj "$J" '"connecte="+((j.msgs2||[]).some(x=>x.d==="etat:connecte")?"oui":"non")+" refuse="+((j.msgs2||[]).some(x=>x.d==="etat:refuse")?"oui":"non")')" "connecte=oui refuse=non"
assert_eq "O4.2 — autre onglet (sessionStorage vide) : carte « Terminal déjà ouvert »" "$(rj "$J" '(j.autre||"").includes("Terminal déjà ouvert")?"oui":"non"')" "oui"
echo "  mesure : MESURE-O8 minimal=$(rj "$J" '(j.o8min||{}).statut||"indisponible"') popups=$(rj "$J" '(j.o8pop||{}).statut||"indisponible"') opener=$(rj "$J" '(j.o8pop||{}).opener||"indisponible"')"
echo "MESURE-O8 minimal=$(rj "$J" '(j.o8min||{}).statut||"indisponible"') popups=$(rj "$J" '(j.o8pop||{}).statut||"indisponible"') opener=$(rj "$J" '(j.o8pop||{}).opener||"indisponible"')"

echo "=== T9.6 — origine tierce : Q refuse d'être encadrée (frame-ancestors) ==="
srv "$OUT"; TP="$(libre)"; node "$AUX/tierce.mjs" "$TP" "http://127.0.0.1:$QP" & TIERCE_PID=$!; PIDS+=($TIERCE_PID)
for _ in $(seq 1 50); do rq "$TP" GET / --host "127.0.0.1:$TP" --sans-origin 2>/dev/null | grep -q '^200' && break; sleep 0.1; done
J="$(navig tierce "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"tierce\":\"http://127.0.0.1:$TP/\"}")"; vf_hyg_stop "$TIERCE_PID"; unsrv
assert_eq "T9.6 — page tierce (autre port) qui encadre Q : une violation frame-ancestors, aucun message reçu (témoin : la violation est relevée)" "$(rj "$J" '"violation="+((j.violations||[]).some(v=>/frame-ancestors/.test(v))?"oui":"non")+" messages="+(j.msgs||["?"]).length')" "violation=oui messages=0"

echo "=== M-COOKIE / M-FRAGMENT / M-STOCKAGE / M-PREMIER-NIVEAU / M-SANS-AMORCE / M-ANCETRES — mutants jouées en navigateur ==="
if mutant cookie vf-cockpit-terminal-client.mjs "s|localStorage.setItem(CLE_SECRET, secret);|localStorage.setItem(CLE_SECRET, secret); document.cookie = 'vfs=' + secret + '; path=/';|"; then
  VF_CLIENT_MS=20000 run_t6 "$MUT_OUT" # mutant : un amorçage cassé doit rougir en 20 s (VF_CLIENT_MS posée = pas de borne AMORCE)
  assert_has "M-COOKIE — le mutant rougit T6.2 : un cookie existe" "$(rj "$T6J" 'j.cookieQ')" "vfs="
else sans_effet "M-COOKIE"; fi
if mutant fragment vf-cockpit-terminal-client.mjs "s|history.replaceState(null, '', location.pathname + location.search);||"; then
  VF_CLIENT_MS=20000 run_t6 "$MUT_OUT" # mutant : un amorçage cassé doit rougir en 20 s (VF_CLIENT_MS posée = pas de borne AMORCE)
  assert_eq "M-FRAGMENT — le mutant rougit T6.1b : l'échange refusé laisse #t= dans l'adresse de Q" "$(rj "$T6J" 'j.refus.hash.slice(0,3)')" "#t="
else sans_effet "M-FRAGMENT"; fi
if mutant premier vf-cockpit-terminal-client.mjs "s|^    if (!encadree) { vue.carte('horscadre'); return; }||"; then
  VF_CLIENT_MS=20000 run_t6 "$MUT_OUT" # mutant : un amorçage cassé doit rougir en 20 s (VF_CLIENT_MS posée = pas de borne AMORCE)
  assert_eq "M-PREMIER-NIVEAU — le mutant (SAF-1 défait : l'échange refait au premier niveau de Q) rougit T6.9 : un secret est rangé par Q ouvert seul" "$(rj "$T6J" '(j.q1||{}).secret')" "range"
else sans_effet "M-PREMIER-NIVEAU"; fi
if mutant sansamorce vf-cockpit-terminal-tiroir.mjs "s|adresse + '#t=' + amorce|adresse|"; then
  VF_CLIENT_MS=20000 run_t6 "$MUT_OUT" # mutant : un amorçage cassé doit rougir en 20 s (VF_CLIENT_MS posée = pas de borne AMORCE)
  assert_eq "M-SANS-AMORCE — le mutant (l'amorçage n'est plus passé dans l'adresse du cadre de Q) rougit T6.3 : le cadre n'échange rien, aucun secret n'est rangé" "$(rj "$T6J" '(j.q1&&j.q1.carte&&j.q1.carte.includes("Terminal indisponible")&&j.cadre1)?(j.secretOk?"oui":"non"):"mutant non jugé (sonde non exécutée)"')" "non"
else sans_effet "M-SANS-AMORCE"; fi
if mutant stockage vf-cockpit-terminal-client.mjs "s|location.replace(location.pathname + location.search)|location.replace(location.pathname + '?s=' + secret)|"; then
  VF_CLIENT_MS=20000 run_t6 "$MUT_OUT" # mutant : un amorçage cassé doit rougir en 20 s (VF_CLIENT_MS posée = pas de borne AMORCE)
  assert_has "M-STOCKAGE — le mutant rougit T6.1c : le secret figure dans l'adresse du cadre de Q" "$(rj "$T6J" '(j.cadre1||{}).url')" "?s="
else sans_effet "M-STOCKAGE"; fi
if mutant ancetres vf-cockpit-terminal-page.mjs 's|frame-ancestors \${origineP}|frame-ancestors *|'; then
  srv "$MUT_OUT"; TP="$(libre)"; node "$AUX/tierce.mjs" "$TP" "http://127.0.0.1:$QP" & TIERCE_PID=$!; PIDS+=($TIERCE_PID)
  for _ in $(seq 1 50); do rq "$TP" GET / --host "127.0.0.1:$TP" --sans-origin 2>/dev/null | grep -q '^200' && break; sleep 0.1; done
  VF_CLIENT_MS=6000 J="$(navig tierce "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"tierce\":\"http://127.0.0.1:$TP/\"}")"; vf_hyg_stop "$TIERCE_PID"; unsrv
  assert_eq "M-ANCETRES — le mutant rougit T9.6 : aucune violation frame-ancestors (la page tierce encadre Q)" "$(rj "$J" '(j.temoin&&j.temoin.cadres>=1)?((j.violations||[]).some(v=>/frame-ancestors/.test(v))?"oui":"non"):"mutant non jugé (sonde non exécutée)"')" "non"
else sans_effet "M-ANCETRES"; fi

echo "=== J2 / J12 / S5 / S3 — scénarios sur le serveur réel (secret périmé, serveur arrêté, « Terminé », onBinary, contre-pression) ==="
secret_neuf() { # secret_neuf <sortie> -> SRV_* et SECRET_N : serveur neuf, amorçage échangé
  srv "$1"; cp "$SRV_O/.cache/terminal-amorce" "$WORK/am-$SRVN.copy"
  SECRET_N="$(node "$TA" amorcer "$QP" "$WORK/am-$SRVN.copy" | sed -n 2p)"; [[ "$SECRET_N" =~ ^[0-9a-f]{64}$ ]] || SECRET_N=""
}
scenario() { # scenario <sortie> <mode> [secret imposé] -> SCJ ; sert le serveur, joue le scénario dans un Chrome neuf, arrête le serveur s'il vit encore
  secret_neuf "$1"; [ -n "${3:-}" ] && SECRET_N="$3"
  SCJ="$(VF_CLIENT_MS="${MS_SC:-20000}" navig "$2" "{\"P\":$SRV_PORT,\"Q\":$QP,\"amorce\":\"$AMORCE\",\"secret\":\"$SECRET_N\",\"pid\":$SRV_PID${SC_EXTRA:-}}")"
  SC_SECRET="$SECRET_N"; unsrv
}
FAUX_SEC="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
scenario "$OUT" perime "$FAUX_SEC"
assert_eq "J2.0 — témoin : le scénario n'a pas échoué globalement" "$(rj "$SCJ" 'j.erreur||"ok"')" "ok"
assert_eq "J2.1 — secret périmé (serveur relancé) : la carte « Session expirée » s'affiche en moins de 10 s, jamais « Serveur arrêté »" "$(rj "$SCJ" '"erreurs="+JSON.stringify(j.erreurs)+" expiree="+(j.carte||"").includes("Session expirée")+" arrete="+(j.carte||"").includes("Serveur arrêté")+" rapide="+(j.duree<10000)')" "erreurs={} expiree=true arrete=false rapide=true"
scenario "$OUT" sansamorce ""
assert_eq "J2.3 — PU-G-132 : aucun secret (terminal jamais ouvert dans cet onglet) : la carte dit « Terminal non ouvert dans cet onglet » (AUDC-M10 : le titre ne dit plus « non disponible », le corps nomme l'amorce à usage unique) et la commande, jamais « Session expirée », et P ne reçoit que « ready » (jamais etat:expire : la barre du tiroir ne ment pas non plus)" "$(rj "$SCJ" '"erreurs="+JSON.stringify(j.erreurs)+" juste="+(j.carte||"").includes("Terminal non ouvert dans cet onglet")+" commande="+(j.carte||"").includes("/vf-cockpit --terminal")+" expiree="+(j.carte||"").includes("Session expirée")+" msgs="+JSON.stringify(j.msgs)')" "erreurs={} juste=true commande=true expiree=false msgs=[\"ready\"]"
MS_SC=60000 scenario "$OUT" arret
assert_eq "J2.2 — serveur réellement arrêté en cours de session : « Serveur arrêté », jamais « Session expirée » (témoin : le PID enregistré a reçu le signal)" "$(rj "$SCJ" '"tue="+j.tue+" erreurs="+JSON.stringify(j.erreurs)+" arrete="+((j.carte||"").includes("Serveur arrêté"))+" expiree="+((j.carte||"").includes("Session expirée"))')" "tue=true erreurs={} arrete=true expiree=false"
scenario "$OUT" reprise
assert_eq "DG08.1 — reconnexion à un shell déjà ouvert, cadre d'une autre taille : le terminal a la taille de l'écran (stty size rend les lignes de la grille ; le premier cadre, privé de /taille, avait créé le terminal plus haut)" "$(rj "$SCJ" '"erreurs="+JSON.stringify(j.erreurs)+" pty="+j.pty+" ecran="+j.ecran+" egal="+(j.pty===j.ecran&&j.ecran>0)')" "erreurs={} pty=$(rj "$SCJ" 'j.ecran') ecran=$(rj "$SCJ" 'j.ecran') egal=true"
scenario "$OUT" termine
assert_eq "J12.1 — témoin : « exit » dans le shell affiche « Le shell s'est terminé », le serveur dit terminee" "$(rj "$SCJ" '"erreurs="+JSON.stringify(j.erreurs)+" bandeau="+(j.avant&&j.avant.bandeau)+" session="+(j.avant&&j.avant.session)')" "erreurs={} bandeau=true session=terminee"
assert_eq "J12.2 — rechargement du cadre dans le même onglet après « Terminé » : le bandeau est toujours là et aucun nouveau shell ne démarre (session = terminee)" "$(rj "$SCJ" '"bandeau="+(j.apres&&j.apres.bandeau)+" session="+(j.apres&&j.apres.session)')" "bandeau=true session=terminee"
assert_eq "J12.3 — seul « Relancer le shell » démarre un nouveau shell : invite revenue, session = vivante, bandeau retiré" "$(rj "$SCJ" '"erreurs="+JSON.stringify(j.erreurs)+" bandeau="+(j.relance&&j.relance.bandeau)+" session="+(j.relance&&j.relance.session)')" "erreurs={} bandeau=false session=vivante"
scenario "$OUT" binaire
assert_eq "S5.1 — le rapport de souris émis par xterm (onBinary) atteint le shell : l'écho « ^[[M » revient (témoin : mode souris enfoncé par printf, cat -v actif)" "$(rj "$SCJ" '"erreurs="+JSON.stringify(j.erreurs)+" rapport="+j.rapport')" "erreurs={} rapport=true"
scenario "$OUT" pression
assert_eq "S3.1 — contre-pression 429 sur /entree : le client garde ses octets et les renvoie (la commande saisie s'exécute, au moins 3 POST)" "$(rj "$SCJ" '"erreurs="+JSON.stringify(j.erreurs)+" sortie="+j.sortie+" appels>=3="+(j.appels>=3)')" "erreurs={} sortie=true appels>=3=true"

echo "=== M4 / N6c — grosse entrée : tranches de 64 Kio au plus, dans l'ordre, jamais de 413 silencieux ==="
OCT=150000; ATT_CK="$(head -c $OCT /dev/zero | tr '\0' a | cksum | awk '{print $1" "$2}')"
gros() { # gros <sortie> <gros|limite> -> GR_J, GR_CK : un collage de $OCT octets, somme de contrôle relue côté shell
  local f="$WORK/gros-$2-$RANDOM.ck"; rm -f "$f"; SC_EXTRA=",\"fichier\":\"$f\",\"octets\":$OCT" MS_SC="${MS_SC:-30000}" scenario "$1" "$2"; SC_EXTRA=""; GR_J="$SCJ"
}
gros "$OUT" gros
assert_eq "M4.1 — un collage de 150 000 octets part en au moins 3 tranches de 65 536 octets au plus, sans aucun 413, et le shell reçoit tout (somme de contrôle identique)" "$(rj "$GR_J" '"erreurs="+JSON.stringify(j.erreurs)+" cksum="+(j.cksum==="'"$ATT_CK"'"?"ok":"["+j.cksum+"]")+" max<=65536="+(Math.max(0,...(j.tr||[]).map((t)=>t[0]))<=65536)+" n413="+(j.tr||[]).filter((t)=>t[1]===413).length+" tranches>=3="+((j.tr||[]).filter((t)=>t[1]===204).length>=3)')" "erreurs={} cksum=ok max<=65536=true n413=0 tranches>=3=true"
gros "$OUT" limite
assert_eq "M4.2 — serveur qui refuse (413) au-delà de 4 Kio : la page découpe plus petit et rien n'est perdu (somme de contrôle identique, au moins un 413 vu, aucun corps accepté au-delà de 4 Kio)" "$(rj "$GR_J" '"erreurs="+JSON.stringify(j.erreurs)+" cksum="+(j.cksum==="'"$ATT_CK"'"?"ok":"["+j.cksum+"]")+" n413>=1="+((j.tr||[]).filter((t)=>t[1]===413).length>=1)+" accepte<=4096="+(Math.max(0,...(j.tr||[]).filter((t)=>t[1]===204).map((t)=>t[0]))<=4096)')" "erreurs={} cksum=ok n413>=1=true accepte<=4096=true"

scenario "$OUT" popup
assert_eq "F4.0 — témoin : le scénario n'a pas échoué, un popup de Q a réellement été ouvert par P (cible de navigateur), la saisie atteint encore le terminal légitime" "erreurs=$(rj "$SCJ" 'JSON.stringify(j.erreurs)') popup=$(rj "$SCJ" 'j.popup1>=1') saisie=$(rj "$SCJ" 'j.saisie')" "erreurs={} popup=true saisie=true"
assert_eq "F4.1 — un popup de Q ouvert par P (window.open, sessionStorage copié) ne prend pas la session : un seul shell avant et après, la session légitime reste vivante, P ne reçoit ni etat:reconnexion ni etat:refuse" "avant=$(rj "$SCJ" 'j.avant.shells') apres=$(rj "$SCJ" 'j.apres.shells') session=$(rj "$SCJ" 'j.apres.session') reconnexion=$(rj "$SCJ" 'j.apres.msgs.includes("etat:reconnexion")') refuse=$(rj "$SCJ" 'j.apres.msgs.includes("etat:refuse")')" "avant=1 apres=1 session=vivante reconnexion=false refuse=false"
assert_eq "F4.2 — le shell légitime terminé, un popup de Q ouvert par P ne lance aucun shell sans frappe de l'utilisateur : zéro shell, session = terminee" "fin=$(rj "$SCJ" 'j.finShells') popup=$(rj "$SCJ" 'j.popup2>=1') shells=$(rj "$SCJ" 'j.apresFin.shells') session=$(rj "$SCJ" 'j.apresFin.session')" "fin=0 popup=true shells=0 session=terminee"

echo "=== M-J2 / M-J12 / M-S5 / M-429 — mutants du client sur le serveur réel ==="
if mutant mj2 vf-cockpit-terminal-client.mjs "s|return r.status === 401; } catch|return false; } catch|"; then
  MS_SC=8000 scenario "$MUT_OUT" perime "$FAUX_SEC"
  assert_eq "M-J2 — le mutant (la sonde ne reconnaît plus le secret périmé) rougit J2.1 : pas de carte « Session expirée »" "$(rj "$SCJ" '(j.carte||"").includes("Session expirée")?"expiree":"pas expiree"')" "pas expiree"
else sans_effet "M-J2"; fi
if mutant mj12 vf-cockpit-terminal-client.mjs "s|sessionStorage.setItem(CLE_FIN, |void (|"; then
  scenario "$MUT_OUT" termine
  assert_eq "M-J12 — le mutant (l'état « Terminé » n'est pas retenu) rougit J12.2 : un nouveau shell démarre au rechargement" "$(rj "$SCJ" '"bandeau="+(j.apres&&j.apres.bandeau)+" session="+(j.apres&&j.apres.session)')" "bandeau=false session=vivante"
else sans_effet "M-J12"; fi
if mutant msa vf-cockpit-terminal-client.mjs "s|vue.carte('sansamorce'); return;|expire(); return;|"; then
  MS_SC=8000 scenario "$MUT_OUT" sansamorce ""
  assert_eq "M-SANS-AMORCE-CARTE — le mutant (secret absent traité de nouveau comme une expiration) rougit J2.3 : « Session expirée » sans session préalable" "$(rj "$SCJ" '"expiree="+(j.carte||"").includes("Session expirée")')" "expiree=true"
else sans_effet "M-SANS-AMORCE-CARTE"; fi
if mutant mrep vf-cockpit-terminal-client.mjs "s|derniere = ''; taille();|derniere = term.rows + ' ' + term.cols;|"; then
  MS_SC=8000 scenario "$MUT_OUT" reprise
  assert_eq "M-REPRISE-TAILLE — le mutant (la taille n'est plus redite à la connexion) rougit DG08.1 : le terminal garde la taille du premier cadre" "$(rj "$SCJ" '"egal="+(j.pty===j.ecran)')" "egal=false"
else sans_effet "M-REPRISE-TAILLE"; fi
if mutant ms5 vf-cockpit-terminal-client.mjs "s|term.onBinary(|void (|"; then
  MS_SC=6000 scenario "$MUT_OUT" binaire
  assert_eq "M-S5 — le mutant (onBinary non relayé) rougit S5.1 : aucun écho de rapport de souris" "$(rj "$SCJ" '"rapport="+j.rapport')" "rapport=false"
else sans_effet "M-S5"; fi
if mutant mhc vf-cockpit-terminal-client.mjs "s|^ *if (!encadree) { vue.carte('horscadre'); return; }||"; then
  VF_CLIENT_MS=6000 run_t6 "$MUT_OUT"
  assert_eq "M-HORS-CADRE — le mutant (garde du cadre retirée) rougit T6.8 : Q en premier niveau ouvre un terminal et prend la session" "$(rj "$T6J" '"carte="+((j.horsCadre||{}).carte||"?")+" session="+((j.horsCadre||{}).session||"?")')" "carte=? session=?"
else sans_effet "M-HORS-CADRE"; fi
if mutant mpopup vf-cockpit-terminal-client.mjs "s|^ *if (!encadree) { vue.carte('horscadre'); return; }||"; then
  MS_SC=8000 scenario "$MUT_OUT" popup
  assert_eq "M-POPUP — le mutant (garde du cadre retirée) rougit F4.1 : le popup prend la session, P reçoit etat:reconnexion" "reconnexion=$(rj "$SCJ" 'j.apres.msgs.includes("etat:reconnexion")')" "reconnexion=true"
else sans_effet "M-POPUP"; fi
if mutant mtranche vf-cockpit-terminal-client.mjs "s|tranche = 65536;|tranche = 1 << 30;|"; then
  MS_SC=8000 gros "$MUT_OUT" gros
  assert_eq "M-TRANCHE — le mutant (aucune tranche) rougit M4.1 : un corps de plus de 64 Kio part et le serveur répond 413 (le découpage de repli sur 413 sauve ensuite les octets, mais la borne est franchie)" "$(rj "$GR_J" '"max>65536="+(Math.max(0,...(j.tr||[]).map((t)=>t[0]))>65536)+" n413>=1="+((j.tr||[]).filter((t)=>t[1]===413).length>=1)')" "max>65536=true n413>=1=true"
else sans_effet "M-TRANCHE"; fi
if mutant m413 vf-cockpit-terminal-client.mjs "s|if (r.status === 413) {|if (false) {|"; then
  MS_SC=8000 gros "$MUT_OUT" limite
  assert_eq "M-413 — le mutant (413 non traité) rougit M4.2 : la saisie est perdue sans signal" "$(rj "$GR_J" '"cksum="+(j.cksum==="'"$ATT_CK"'"?"ok":"perdu")')" "cksum=perdu"
else sans_effet "M-413"; fi
if mutant m429 vf-cockpit-terminal-client.mjs "s|if (r.status === 429) {|if (false) {|"; then
  MS_SC=6000 scenario "$MUT_OUT" pression
  assert_eq "M-429 — le mutant (429 ignoré, octets perdus) rougit S3.1 : la commande saisie ne s'exécute pas" "$(rj "$SCJ" '"sortie="+j.sortie')" "sortie=false"
else sans_effet "M-429"; fi
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
