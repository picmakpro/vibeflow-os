#!/usr/bin/env bash
# test-cockpit-lancer-ui.sh — interface de lancement des cartes sur page factice : section de panneau, action principale et menu, pré-vols, état lancée, rendu hostile, clavier
# (LANC-01, LANC-02 côté script ; P72-D-04, D-05, D-06, D-07, D-08, D-09, D-17, D-18 ; plan 72-06).
#   LU.S  statique (sans navigateur) : S1 chaîne vide si indisponible · S2 une balise <script> nue, aucun <style>, en-tête · S3 aucune adresse web en entier · S4 deux fetch exactement
#         · S5 aucun appel ni littéral interdit · S6 LIBELLES_VERBES · S7 MOTIFS (codes et textes)
#   LU    page factice sous Chrome (serveur HTTP jetable, faux window.VibeFlow qui rejoue la boucle des sections du viewer et son écouteur d'Entrée sur window, CSP de v2.75.0) :
#         LU.1 carte de phase et de mission · LU.2 cibles non ouvrantes · LU.3 envoi (en-têtes, corps exact, double clic) · LU.4 verbe du menu · LU.5 bloquants et avertissements
#         · LU.6 emplacement « travail non commité » · LU.7 état lancée · LU.8 rendu hostile · LU.9 touche Entrée · LU.10 ordre de définition de window.VibeFlow · LU.11 hors Projet
#         · LU.12 refus et pannes · LU.13 liste invalide · LU.14 verbes inconnus, principal absent, aucun verbe · LU.15 port du serveur factice
#   Mutants (une garde du module = une ligne marquée « garde:<nom> ») : M-INNERHTML, M-ENTREE-VIEWER, M-BLOQUANT-IGNORE, M-CHAT-ENVOYE, M-VERBE-LIBRE, M-DOUBLE-ENVOI, M-JETON-ABSENT,
#         M-HORS-PROJET, M-CIBLE-LIBRE. Un mutant « sans effet » est un défaut du module (marqueur absent), jamais de la suite.
# Sans Chrome : les sections statiques tournent, la suite annonce « SUITE SAUTÉE (navigateur) ». VF_LU_MS : échéance d'une attente (6000). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; TA="$HERE_T/terminal-aux.mjs"; MOD="$SCRIPTS/vf-cockpit-lancer-ui.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX"
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
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE (navigateur) : LU.1 à LU.14, LU.16 à LU.18 et les mutants NON vérifiés, non comptés comme réussis"; fi

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/statique.mjs" <<'JS'
// statique.mjs <module> : faits statiques de injectionLancer (une ligne JSON) ; { absent: true } si le module ou l'export manque
import { pathToFileURL } from 'node:url';
let m = null; try { m = await import(pathToFileURL(process.argv[2]).href); } catch { m = null; }
if (!m || typeof m.injectionLancer !== 'function') { console.log(JSON.stringify({ absent: true })); process.exit(0); }
const indispo = m.injectionLancer({ indisponible: true }), h = m.injectionLancer({});
const s = (h.match(/<script>([\s\S]*?)<\/script>/) || [, ''])[1];
const INTERDITS = { innerHTML: /\binnerHTML\b/, outerHTML: /\bouterHTML\b/, insertAdjacentHTML: /\binsertAdjacentHTML\b/, 'document.write': /document\s*\.\s*write\b/, 'eval(': /\beval\s*\(/, 'new Function': /\bnew\s+Function\b/,
  'postMessage(': /\bpostMessage\s*\(/, localStorage: /\blocalStorage\b/, sessionStorage: /\bsessionStorage\b/, 'document.cookie': /document\s*\.\s*cookie\b/, couleur: /#[0-9a-fA-F]{3,8}\b/, '.style': /\.style\b/, cssText: /\bcssText\b/ };
const PLANTE = 'innerHTML outerHTML insertAdjacentHTML document.write eval( new Function postMessage( localStorage sessionStorage document.cookie #fff .style cssText';
const adr = /https?:\/\//g;
const ATTENDUS = { 'phase-finie': 'La phase est terminée.', 'terminal-absent': 'Le terminal est indisponible sur ce poste.', 'terminal-arrete': 'Le terminal est arrêté. Relancez /vf-cockpit --terminal.',
  'premier-plan-occupe': 'Un programme occupe déjà le terminal.', 'claude-introuvable': 'La commande claude est introuvable.', 'python3-absent': 'Python 3 est introuvable sur ce poste.',
  'phase-hors-motif': "Le numéro de phase n'est pas lançable.", 'compartiment-hors-motif': "Le nom du compartiment n'est pas lançable.", 'mission-hors-phase': "Cette mission n'est rattachée à aucune phase : le lancement depuis une carte ne part que d'un numéro de phase. Pour la reprendre, ouvrez une session Claude Code dans le terminal, tapez /vf-dev et nommez la mission.",
  'dependance-non-close': "Une phase dont celle-ci dépend n'est pas close (lecture de la prose du ROADMAP, indicative).", 'mission-vivante': 'Une mission vivante travaille déjà sur cette phase.',
  'phase-plus-avancee-ailleurs': "Une version plus récente de ce travail existe à part (autre arbre de travail). Le lancement part du dossier principal, qui n'a pas cette avance : consultez cette version avant de lancer.", 'phase-sans-plan': "Aucun plan à exécuter pour cette phase : cadrez puis planifiez d'abord.", 'lancement-recent': 'Cette cible a déjà été lancée récemment.',
  'travail-non-commite': "Du travail non commité existe dans l'arbre de travail." };
const mo = m.MOTIFS || {}, ecart = [...new Set([...Object.keys(ATTENDUS), ...Object.keys(mo)])].filter((k) => mo[k] !== ATTENDUS[k]);
const lib = m.LIBELLES_VERBES || {};
console.log(JSON.stringify({
  indispoVide: indispo === '', balises: (h.match(/<script/g) || []).length, fermees: (h.match(/<\/script>/g) || []).length, nue: h.startsWith('<script>') && h.trimEnd().endsWith('</script>'),
  style: (h.match(/<style/g) || []).length, premiere: s.split('\n')[0], adresses: (s.match(adr) || []).length, temoinAdr: ('x http://exemple.test y'.match(adr) || []).length,
  fetchs: (s.match(/\bfetch\s*\(/g) || []).length, urls: [...s.matchAll(/\bfetch\s*\(\s*(['"`])([^'"`]*)\1/g)].map((x) => x[2]).sort().join(','),
  interdits: Object.keys(INTERDITS).filter((k) => INTERDITS[k].test(s)).join(',') || 'aucun', temoinInterdits: Object.keys(INTERDITS).filter((k) => INTERDITS[k].test(PLANTE)).length,
  cles: Object.keys(lib).join(','), valeurs: Object.values(lib).join(','), fige: Object.isFrozen(lib) && Object.isFrozen(mo), ecart: ecart.join(',') || 'aucun',
}));
JS
cat > "$AUX/page-lancer.mjs" <<'JS'
// page-lancer.mjs <module> <port> <terminal-aux> : serveur jetable (127.0.0.1) qui sert une page Projet factice portant injectionLancer(), un faux window.VibeFlow et les routes du lancement.
// Pages : /project.html /index.html /autre.html (?ordre=avant|apres|jamais : définition de window.VibeFlow avant le script, 600 ms après, ou jamais). Pilotage : POST /__scenario, GET /__journal.
// Le journal ne compte pas /__* ni /favicon.ico ; il garde méthode et chemin de tout le reste, plus le détail des POST et la validité du jeton des GET de la liste.
import http from 'node:http'; import fs from 'node:fs'; import { execFileSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , module_, port, ta] = process.argv; const WORKD = process.env.LU_WORK;
let inj = ''; try { inj = (await import(pathToFileURL(module_).href)).injectionLancer({ indisponible: false, expireMs: process.env.LU_EXPIRE_MS ? Number(process.env.LU_EXPIRE_MS) : undefined }) || ''; } catch { inj = ''; }
function aide() { // exécutée dans la page : le faux viewer (boucle des sections de viewer.html, écouteur d'Entrée de window)
  window.__err = []; window.__sections = { item: [] }; window.__redraws = 0; window.__sel = null; window.__M72 = undefined; window.__prop = 0;
  document.addEventListener('vf-lancer-propose', () => { window.__prop++; }); // SP-1 : le signal de proposition acceptée que le tiroir écoute
  addEventListener('error', (e) => window.__err.push(String(e.message))); addEventListener('unhandledrejection', () => window.__err.push('rejet'));
  window.definirVibeFlow = () => { window.VibeFlow = { addPanelSection(where, fn) { (window.__sections[where] = window.__sections[where] || []).push(fn); } }; };
  window.__selectionner = (cible, titre) => {
    const panel = document.getElementById('panel'); window.__sel = { cible, titre }; window.__redraws++;
    let html = '<div class="sec"><h2 class="pt"></h2></div><div class="sec"><h3>Autre section</h3></div>'; const out = [];
    for (const fn of window.__sections.item) {
      try {
        const r = fn(cible); if (!r) continue;
        const o = typeof r === 'string' ? { html: r } : r; out.push(o);
        const block = '<div data-ext="' + (out.length - 1) + '">' + (o.html || '') + '</div>';
        const second = o.top ? html.indexOf('<div class="sec"', 1) : -1;
        html = second > 0 ? html.slice(0, second) + block + html.slice(second) : html + block;
      } catch (e) { window.__err.push('ext:' + e.message); }
    }
    panel.innerHTML = html; panel.querySelector('.pt').textContent = titre;
    out.forEach((o, i) => { try { if (o.bind) o.bind(panel.querySelector('[data-ext="' + i + '"]')); } catch (e) { window.__err.push('bind:' + e.message); } });
  };
  addEventListener('keydown', (ev) => { if (ev.key === 'Enter' && window.__sel) window.__selectionner(window.__sel.cible, window.__sel.titre); }); // imite « ouvrir le nœud sélectionné » : redessine le panneau
}
const page = (ordre) => ['<!doctype html><html><head><meta charset="utf-8">', '<script>window.VF_COCKPIT_SERVER={token:"jeton-test"};</script>', `<script>(${aide.toString()})();</script>`,
  ordre === 'avant' ? '<script>definirVibeFlow();</script>' : '', inj, ordre === 'apres' ? '<script>setTimeout(definirVibeFlow, 600);</script>' : '',
  '</head><body><div id="panel"></div></body></html>'].join('\n');
const cache = {};
const pageCsp = (ordre) => { if (!cache[ordre]) { const html = page(ordre), f = `${WORKD}/page-${ordre}.html`; fs.writeFileSync(f, html); cache[ordre] = { html, csp: execFileSync('node', [ta, 'csp-v275', f], { encoding: 'utf8' }).trim() }; } return cache[ordre]; };
const S = { liste: null, listeRaw: null, listeStatus: 200, listeDelai: 0, post: { status: 202, body: '{"propose":true}', delai: 0 }, panne: false };
const journal = [], posts = [], gets = [];
http.createServer((q, r) => {
  const u = new URL(q.url, 'http://x'), p = u.pathname, morceaux = []; q.on('data', (d) => morceaux.push(d));
  q.on('end', () => {
    const brut = Buffer.concat(morceaux).toString('utf8'), json = (st, c) => { r.writeHead(st, { 'Content-Type': 'application/json' }); r.end(c); };
    if (p === '/__scenario') {
      const o = JSON.parse(brut || '{}'); if (o.reset) { journal.length = 0; posts.length = 0; gets.length = 0; }
      for (const k of ['liste', 'listeRaw', 'listeStatus', 'listeDelai', 'panne']) if (k in o) S[k] = o[k];
      if (o.post) S.post = Object.assign({ status: 202, body: '{"propose":true}', delai: 0 }, o.post);
      return json(200, '{}');
    }
    if (p === '/__journal') return json(200, JSON.stringify({ journal, posts, gets }));
    if (p === '/favicon.ico') { r.writeHead(404); return r.end(); }
    journal.push(q.method + ' ' + p);
    if (q.method === 'GET' && ['/project.html', '/index.html', '/autre.html'].includes(p)) {
      const { html, csp } = pageCsp(u.searchParams.get('ordre') || 'avant'); r.writeHead(200, { 'Content-Type': 'text/html', 'Content-Security-Policy': csp, 'Cache-Control': 'no-store' }); return r.end(html);
    }
    const jeton = q.headers['x-vf-cockpit-token'] === 'jeton-test';
    if (p === '/api/vf/lancer/cibles' && q.method === 'GET') {
      gets.push({ jeton }); if (!jeton) return json(403, '{"refus":"jeton"}');
      const rend = () => { r.writeHead(S.listeStatus, { 'Content-Type': 'application/json' }); r.end(S.listeRaw !== null ? S.listeRaw : JSON.stringify(S.liste)); }; if (S.listeDelai) setTimeout(rend, S.listeDelai); else rend(); return;
    }
    if (p === '/api/vf/lancer' && q.method === 'POST') {
      const ct = q.headers['content-type'] || '', origin = q.headers.origin || ''; posts.push({ ct, jeton, origin, corps: brut });
      if (!jeton || ct !== 'application/json' || origin !== 'http://' + q.headers.host) return json(403, '{"refus":"jeton"}');
      if (S.panne) { q.socket.destroy(); return; }
      const rep = () => json(S.post.status, S.post.body); if (S.post.delai) setTimeout(rep, S.post.delai); else rep(); return;
    }
    r.writeHead(404); r.end('{}');
  });
}).listen(Number(port), '127.0.0.1');
JS
cat > "$AUX/chrome-lancer-ui.mjs" <<'JS'
// chrome-lancer-ui.mjs <chrome> <mode> <json> : scénarios navigateur de l'interface de lancement ; UNE ligne JSON. Entrée : { P }. Modes : lu1 … lu14.
// Chaque mode joue ses étapes isolées par `essai` (la première en échec arrête le mode : la mesure absente est nommée dans `erreurs`, jamais un résultat vide).
// Gestes par Input.dispatchMouseEvent / Input.dispatchKeyEvent seulement. Toute sonde négative joint son témoin positif (la carte valide rend sa section) dans le MÊME mode.
import { pathToFileURL } from 'node:url';
const { executer, pause, attendreEtStabiliser, positionPosee } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, mode, brut] = process.argv; const A = JSON.parse(brut);
const OP = `http://127.0.0.1:${A.P}`, MS = Number(process.env.VF_LU_MS) || 6000, J = JSON.stringify;
const erreurs = {}; let echec = false;
const essai = async (nom, f) => { if (echec) return undefined; try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 140); echec = true; return undefined; } };
const scen = (o) => fetch(OP + '/__scenario', { method: 'POST', body: J(o) });
const jrn = async () => (await fetch(OP + '/__journal')).json();
const attNode = async (pred, nom, ms = MS) => { const fin = Date.now() + ms; let v; do { v = await jrn(); if (pred(v)) return v; await pause(100); } while (Date.now() < fin); throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`); };
const E = (id, kind, principal, verbes, extra = {}) => ({ id, kind, principal, verbes, bloquants: [], avertissements: [], lancee: false, ...extra });
const liste = (cibles, extra = {}) => ({ actif: true, terminal: 'actif', claude: true, cibles, ...extra });
const BASE = liste([E('ph-72', 'phase', 'planifier', ['cadrer', 'planifier', 'executer']), E('dag-m1', 'mission', 'reprendre', ['reprendre'])]);
const defaut = (o = {}) => scen({ reset: true, listeDelai: 0, liste: BASE, listeRaw: null, listeStatus: 200, post: { status: 202, body: '{"propose":true}', delai: 0 }, panne: false, ...o });
const HOSTILE = '<img src=x onerror=window.__M72=1>', TOUCH = '"; touch M #';
const VISIBLE = `!!document.querySelector('#panel [data-vf-lancer]:not([hidden])')`;
const STATUT = `((document.querySelector('#panel [data-vf-lancer] [role="status"]') || {}).textContent || '')`;
const SNAP = `(() => { const z = document.querySelector('#panel [data-vf-lancer]'); if (!z || z.hidden) return null; const t = (e) => e.textContent.trim(), c = (e) => [...e.classList].sort().join(' ');
  const tous = [...z.querySelectorAll('button')], hors = tous.filter((b) => !b.closest('details')), dans = [...z.querySelectorAll('details button')], kids = [...document.getElementById('panel').children];
  return { h3: [...z.querySelectorAll('h3')].map(t), princ: hors.map((b) => t(b) + ':' + c(b)), menu: [...z.querySelectorAll('details > summary')].map(t), autres: dans.map((b) => t(b) + ':' + c(b)),
    lignes: [...z.querySelectorAll('p:not([role="status"])')].map(t), nb: tous.length, dis: tous.filter((b) => b.disabled).length, boutons: tous.map(t), details: z.querySelectorAll('details').length,
    statut: [...z.querySelectorAll('[role="status"]')].map(t), imgs: document.querySelectorAll('#panel img').length, avantAutre: kids.findIndex((k) => k.contains(z)) < kids.findIndex((k) => /Autre section/.test(k.textContent)) }; })()`;
const ETAT = `(() => ({ zones: document.querySelectorAll('#panel [data-vf-lancer]:not([hidden])').length, titres: document.querySelectorAll('#panel [data-vf-lancer] h3').length, err: window.__err.length }))()`;
const ESPION = `window.__err = window.__err || [];`;

await executer(chrome, async (s) => {
  const att = (expr, nom, ms) => s.attendre(expr, nom, ms || MS);
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: ESPION });
  const centreDe = async (expr) => { const p = await positionPosee(s.ev, expr); return p ? { x: p.cx, y: p.cy } : null; }; // le geste vise le centre lu une fois l'élément posé (deux lectures égales), pas celui d'une mise en page en mouvement
  const souris = (type, x, y, n = 1) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: n });
  const BTN = (t) => `[...document.querySelectorAll('#panel [data-vf-lancer] button')].find((b) => b.textContent.trim() === ${J(t)})`;
  const clicExpr = async (expr, nom, fois = 1) => { const c = await centreDe(expr); if (!c) throw new Error(`élément absent : ${nom}`); await souris('mouseMoved', c.x, c.y); for (let i = 1; i <= fois; i++) { await souris('mousePressed', c.x, c.y, i); await souris('mouseReleased', c.x, c.y, i); } };
  const clic = (t, fois) => clicExpr(BTN(t), t, fois);
  const touche = async (key, code, vk, text) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, text: type === 'keyDown' ? text : undefined }); };
  const ouvrir = async (page = 'project.html', ordre = 'avant', hote = '127.0.0.1') => { await s.naviguer(`http://${hote}:${A.P}/${page}?ordre=${ordre}`); await att(`document.readyState === 'complete' && typeof window.__selectionner === 'function'`, 'page factice prête'); };
  const choisir = (cible, titre = 'Carte de test') => s.ev(`window.__selectionner(${J(cible)}, ${J(titre)})`);
  const carte = async (cible, titre) => { await choisir(cible, titre); await att(VISIBLE, `section de ${cible}`); return s.stable(SNAP, `section de ${cible}`); };
  const R = { erreurs };

  if (mode === 'lu1') {
    await essai('phase', async () => { await defaut(); await ouvrir(); R.phase = await carte('n:ph-72', 'Phase 72'); });
    await essai('mission', async () => { R.mission = await carte('n:dag-m1', 'Mission m1'); });
  } else if (mode === 'lu2') {
    await essai('temoin', async () => { await defaut({ liste: liste([...BASE.cibles]) }); await ouvrir(); R.temoin = (await carte('n:ph-72')).princ.join(); });
    await essai('negatives', async () => {
      R.neg = {};
      for (const c of ['n:ph-404', 'f:src/x.js', 'x:abc', 'ph-72', 'x:ph-72', 'f:dag-m1']) { await choisir(c); R.neg[c] = (await s.stable(ETAT, `cible ${c}`)).zones; }
      const j = await jrn(); R.posts = j.posts.length; R.err = await s.ev('window.__err.length');
    });
  } else if (mode === 'lu3') {
    await essai('envoi', async () => {
      await defaut({ post: { status: 202, body: '{"propose":true}', delai: 500 } }); await ouvrir(); await carte('n:ph-72', 'Phase 72');
      await clic('Planifier', 2); await att(`${STATUT}.length > 0`, 'message de l’envoi'); R.statutRole = await s.ev(`document.querySelector('#panel [data-vf-lancer] [role="status"]').tagName.toLowerCase()`);
      R.statut = await s.ev(STATUT); const j = await jrn(); R.n = j.posts.length; R.p = j.posts[0] || {}; R.cles = Object.keys(JSON.parse(R.p.corps || '{}')).join();
      R.getsJeton = j.gets.map((g) => g.jeton).join(); R.gets = j.gets.length; R.prop = await s.ev('window.__prop');
    });
    R.fin = await jrn().then((j) => ({ gets: j.gets.length, getsKo: j.gets.filter((g) => !g.jeton).length, posts: j.posts.length, postsKo: j.posts.filter((p) => !p.jeton).length }), () => null);
    await essai('menu', async () => {
      await defaut(); await ouvrir(); await carte('n:ph-72', 'Phase 72'); await clicExpr(`document.querySelector('#panel [data-vf-lancer] details > summary')`, 'menu Autres actions');
      await clic('Exécuter'); const j = await attNode((v) => v.posts.length >= 1, 'POST du verbe du menu'); R.menu = j.posts[0].corps;
    });
  } else if (mode === 'lu5') {
    await essai('bloques', async () => {
      await defaut({ liste: liste([E('ph-72', 'phase', 'planifier', ['cadrer', 'planifier', 'executer'], { bloquants: ['phase-finie', 'terminal-absent'] })]) }); await ouvrir();
      R.bloq = await carte('n:ph-72'); await clic('Planifier'); await s.stable(ETAT, 'après le clic sur un bouton bloqué'); R.bloqPosts = (await jrn()).posts.length;
    });
    await essai('avertis', async () => {
      await defaut({ liste: liste([E('ph-72', 'phase', 'planifier', ['cadrer', 'planifier', 'executer'], { avertissements: ['dependance-non-close', 'lancement-recent'] })]) }); await ouvrir();
      R.aver = await carte('n:ph-72'); await clic('Planifier'); R.averPosts = (await attNode((v) => v.posts.length >= 1, 'POST malgré les avertissements')).posts.length;
    });
  } else if (mode === 'lu6') {
    await essai('liste', async () => {
      await defaut({ liste: liste([E('ph-sans', 'phase', 'planifier', ['planifier']), E('ph-avec', 'phase', 'planifier', ['planifier'], { avertissements: ['travail-non-commite'] })]) }); await ouvrir();
      R.sans = await carte('n:ph-sans'); R.avec = await carte('n:ph-avec');
    });
  } else if (mode === 'lu7') {
    const L7 = { vrai: true, attendue: { etat: 'attendue', verbe: 'planifier' }, vue: { etat: 'vue', verbe: 'planifier' }, terminee: { etat: 'terminee', verbe: 'planifier' }, faux: false, nul: null, absent: undefined,
      etatx: { etat: 'x', verbe: 'planifier' }, verbex: { etat: 'vue', verbe: 'x;y' }, chaine: 'vue', un: 1, vide: {} };
    await essai('liste', async () => {
      await defaut({ liste: liste(Object.entries(L7).map(([k, v]) => { const e = E('l-' + k, 'phase', 'planifier', ['planifier']); if (v === undefined) delete e.lancee; else e.lancee = v; return e; })) }); await ouvrir();
      for (const k of Object.keys(L7)) { const lg = (await carte('n:l-' + k)).lignes; R[k] = lg.filter((l) => l.indexOf('Lancée') === 0 || l.indexOf('Commande préparée') === 0 || l.indexOf('Préparée depuis') === 0).join('|'); R[k + 'L'] = lg.filter((l) => l.indexOf('Lancée') === 0).join('|'); } // LB1 PU-G-113 : « attendue » n'est plus une « Lancée »
    });
  } else if (mode === 'lu8') {
    await essai('hostile', async () => {
      await defaut({ liste: liste([E('ph-h1', 'phase', 'planifier', [TOUCH, 'planifier'], { bloquants: [HOSTILE], avertissements: [HOSTILE] }), E('ph-h2', 'phase', 'planifier', [TOUCH, 'planifier'], { avertissements: [HOSTILE] })]) }); await ouvrir();
      R.h1 = await carte('n:ph-h1', 'Titre ' + TOUCH);
      R.h2 = await carte('n:ph-h2', TOUCH); await clic('Planifier'); await att(`${STATUT}.length > 0`, 'message avec le titre hostile'); R.statuts = [await s.ev(STATUT)]; R.imgs = await s.ev(`document.querySelectorAll('#panel img').length`);
      await choisir('n:ph-h2', HOSTILE); await att(VISIBLE, 'section après titre hostile'); await clic('Planifier'); await att(`${STATUT}.length > 0`, 'message avec le titre img'); R.statuts.push(await s.ev(STATUT));
      R.imgs = Math.max(R.imgs, await s.ev(`document.querySelectorAll('#panel img').length`));
      await s.stable(ETAT, 'rendu hostile stable'); R.m72 = await s.ev('String(window.__M72)'); R.violations = s.violations.length;
      const j = await jrn(); R.hors = j.journal.filter((l) => !/^(GET \/project\.html|GET \/api\/vf\/lancer\/cibles|POST \/api\/vf\/lancer)$/.test(l)); R.nposts = j.posts.length; R.corps = j.posts.map((p) => p.corps);
    });
  } else if (mode === 'lu9') {
    await essai('entree', async () => {
      await defaut(); await ouvrir(); await carte('n:ph-72', 'Phase 72'); await s.ev(`document.querySelector('#panel [data-vf-lancer] button.primary').focus()`);
      R.avant = await s.ev('window.__redraws'); await touche('Enter', 'Enter', 13, '\r');
      /* le message de la réponse est attendu AVANT de juger la stabilité (une réponse lente ne laisse plus deux lectures égales à vide) */
      await attendreEtStabiliser(() => s.ev(`({ r: window.__redraws, p: ${STATUT}.length })`), (v) => !!v && v.p > 0, { pas: 250, max: MS }); const j = await jrn();
      R.posts = j.posts.length; R.redessine = (await s.ev('window.__redraws')) - R.avant;
    });
  } else if (mode === 'lu10') {
    await essai('avant', async () => { await defaut(); await ouvrir('project.html', 'avant'); R.avant = (await carte('n:ph-72')).princ.join(); });
    await essai('apres', async () => { await ouvrir('project.html', 'apres'); await att(`window.__sections.item.length > 0`, 'section enregistrée après le script'); R.apres = (await carte('n:ph-72')).princ.join(); });
    await essai('jamais', async () => {
      await scen({ reset: true }); await ouvrir('project.html', 'jamais'); await choisir('n:ph-72'); const e = await s.stable(ETAT, 'page sans window.VibeFlow'); const j = await jrn();
      R.jamais = { zones: e.zones, err: e.err, reqs: j.journal.filter((l) => /api\/vf\/lancer/.test(l)).length, api: await s.ev('typeof window.VibeFlow') };
    });
  } else if (mode === 'lu11') {
    await essai('temoin', async () => { await defaut(); await ouvrir(); R.temoin = (await carte('n:ph-72')).princ.join(); });
    await essai('hors', async () => {
      R.hors = {};
      for (const [nom, page, hote] of [['index', 'index.html', '127.0.0.1'], ['autre', 'autre.html', '127.0.0.1'], ['localhost', 'project.html', 'localhost']]) {
        await scen({ reset: true }); await ouvrir(page, 'avant', hote); await choisir('n:ph-72'); const e = await s.stable(ETAT, `page ${nom}`);
        R.hors[nom] = { zones: e.zones, err: e.err, reqs: (await jrn()).journal.filter((l) => /api\/vf\/lancer/.test(l)).length };
      }
    });
  } else if (mode === 'lu12') {
    const CAS = [[403, '{"refus":"jeton"}'], [404, '{}'], [409, '{"refus":"bloque"}'], [500, 'oups'], ['panne'], [403, J({ refus: HOSTILE })], [403, '{"motif":"x"}'], [409, '{"refus":"jeton"}'], [400, 'pas du json']];
    await essai('cas', async () => {
      R.msgs = []; R.imgs = 0; await defaut(); await ouvrir();
      for (const [st, corps] of CAS) {
        await scen(st === 'panne' ? { panne: true } : { panne: false, post: { status: st, body: corps, delai: 0 } }); await carte('n:ph-72', 'Phase 72'); await clic('Planifier');
        await att(`${STATUT}.length > 0`, `message du cas ${st}`); R.msgs.push(await s.ev(STATUT)); R.imgs = Math.max(R.imgs, await s.ev(`document.querySelectorAll('#panel img').length`));
      }
      R.prop = await s.ev('window.__prop');
    });
  } else if (mode === 'lu13') {
    await essai('temoin', async () => { await defaut(); await ouvrir(); R.temoin = (await carte('n:ph-72')).princ.join(); });
    await essai('invalides', async () => {
      R.cas = []; R.titres = [];
      for (const o of [{ liste: { ...BASE, actif: false } }, { liste: { actif: true, terminal: 'actif', claude: true } }, { listeRaw: 'ceci n’est pas du json' }, { listeStatus: 404 }, { liste: { ...BASE, cibles: 'x' } }]) {
        await defaut(o); await ouvrir(); await choisir('n:ph-72'); const e = await s.stable(ETAT, 'liste invalide'); R.cas.push(e.zones); R.titres.push(e.titres + '/' + e.err);
      }
      R.posts = (await jrn()).posts.length;
    });
  } else if (mode === 'lu14') {
    await essai('liste', async () => {
      const sans = E('v-sans', 'phase', undefined, ['executer', 'cadrer']); delete sans.principal;
      await defaut({ liste: liste([E('v-inconnu', 'phase', 'planifier', ['bidule', 'planifier', 'executer']), sans, E('v-hors', 'phase', 'bidule', ['executer']), E('v-vide', 'phase', 'planifier', []), E('v-inval', 'phase', 'x', ['x', 'y'])]) }); await ouvrir();
      for (const k of ['inconnu', 'sans', 'hors', 'vide', 'inval']) R[k] = await carte('n:v-' + k);
    });
  } else if (mode === 'lu16') { // LB1 : PU-G-116 (retour immédiat, focus gardé), PU-G-111 (aide au survol et au clavier), PU-G-110 (sous le titre)
    await essai('liste', async () => {
      await defaut({ liste: liste([E('ph-72', 'phase', 'planifier', ['cadrer', 'planifier', 'executer'])]), post: { status: 202, body: '{"propose":true}', delai: 4000 } }); await ouvrir();
      R.carte = await carte('n:ph-72', 'Phase 72');
      R.sousTitre = await s.ev(`(() => { const pt = document.querySelector('#panel .pt'); return !!pt.nextElementSibling && pt.nextElementSibling.contains(document.querySelector('[data-vf-lancer]')) && pt.parentNode.classList.contains('sec'); })()`);
      await s.ev(`document.querySelector('#panel [data-vf-lancer] button[data-verbe="planifier"]').focus()`);
      R.aide = await s.ev(`(() => { const b = document.querySelector('#panel [data-vf-lancer] button[data-verbe="planifier"]'), a = document.getElementById('vf-lancer-aide'), d = document.getElementById(b.getAttribute('aria-describedby'));
        return { visible: !a.hidden, texte: a.textContent, titre: b.title, decrit: d ? d.textContent : null, horsBouton: d ? !b.contains(d) : null }; })()`);
      await clic('Planifier');
      R.pendant = await s.stable(`(() => { const b = document.querySelector('#panel [data-vf-lancer] button[data-verbe="planifier"]'); return { txt: b.textContent, busy: b.getAttribute('aria-busy'), focus: document.activeElement === b, zone: document.querySelector('#panel [data-vf-lancer]').getAttribute('aria-busy') }; })()`, 'bouton en préparation');
      await att(`/Proposition envoyée/.test(document.getElementById('panel').textContent)`, 'message après la réponse', 8000);
      R.apres = await s.ev(`(() => ({ focus: document.activeElement && document.activeElement.dataset ? document.activeElement.dataset.verbe : null, txt: document.activeElement.textContent, busy: document.querySelector('#panel [data-vf-lancer]').getAttribute('aria-busy') }))()`);
    });
  } else if (mode === 'lu17') { // LB1 : PU-G-113 (le message d'envoi est borné à la durée d'une proposition) et PU-G-125 (Exécuter sans plan)
    await essai('envoi', async () => {
      await defaut({ liste: liste([E('ph-72', 'phase', 'cadrer', ['cadrer', 'planifier', 'executer']), E('ph-45', 'phase', 'executer', ['executer', 'cadrer'])]) }); await ouvrir();
      await carte('n:ph-72', 'Phase 72'); await clic('Cadrer'); await att(`/Proposition envoyée/.test(${STATUT})`, 'message d\'envoi');
      R.avant = await s.ev(STATUT);
      await att(`/n'est plus valable/.test(${STATUT})`, 'message borné à la durée de la proposition', 8000); R.apres = await s.ev(STATUT);
    });
    await essai('sansplan', async () => {
      R.sans = await s.ev(`(() => { const z = document.querySelector('#panel [data-vf-lancer]'); const b = z.querySelector('button[data-verbe="executer"]'); return { dansMenu: !!b.closest('details'), note: [...z.querySelectorAll('details div.pd')].map((e) => e.textContent), decrit: document.getElementById(b.getAttribute('aria-describedby')).textContent, actif: !b.disabled && b.getAttribute('aria-disabled') !== 'true' }; })()`);
      await carte('n:ph-45', 'Phase 45');
      R.avec = await s.ev(`(() => { const z = document.querySelector('#panel [data-vf-lancer]'); const b = z.querySelector('button[data-verbe="executer"]'); return { note: z.querySelectorAll('details div.pd').length, decrit: document.getElementById(b.getAttribute('aria-describedby')).textContent }; })()`);
    });
  } else if (mode === 'lu18') { // LB1 : DG-11 (section absente tant que la liste ne répond pas : elle se dit « en chargement ») et mission hors phase
    await essai('lent', async () => {
      await defaut({ liste: liste([E('ph-51', 'phase', 'cadrer', ['cadrer', 'planifier'])]), listeDelai: 2500 }); await ouvrir();
      await choisir('n:ph-51', 'Phase 51'); await att(VISIBLE, 'section en chargement', 1800);
      R.charge = await s.ev(`document.querySelector('#panel [data-vf-lancer]').innerText.replace(/\\s+/g, ' ').trim() + '|' + document.querySelector('#panel [data-vf-lancer]').getAttribute('aria-busy') + '|' + document.querySelectorAll('#panel [data-vf-lancer] button').length`);
      await att(`document.querySelectorAll('#panel [data-vf-lancer] button').length > 0`, 'boutons après la réponse', 8000);
      R.pret = await s.ev(`document.querySelector('#panel [data-vf-lancer]').getAttribute('aria-busy') + '|' + document.querySelectorAll('#panel [data-vf-lancer] button').length`);
    });
    await essai('inconnue', async () => {
      await defaut({ liste: liste([E('ph-51', 'phase', 'cadrer', ['cadrer'])]), listeDelai: 1200 }); await ouvrir();
      await choisir('n:ph-99', 'Phase 99'); await pause(2500);
      R.absente = await s.ev(`(() => { const z = document.querySelector('#panel [data-vf-lancer]'); return z.hidden + '|' + z.children.length; })()`);
    });
  } else { throw new Error('mode inconnu : ' + mode); }
  return R;
}, { csp: true });
JS
cat > "$AUX/parite.mjs" <<'JS'
// parite.mjs <module-ui> <module-cibles> : ST-2. La liste des codes de pré-vol est DÉRIVÉE du module de cibles (import réel, jamais un littéral) ; { n, sans } = nombre de codes et codes sans texte dans MOTIFS.
import { pathToFileURL } from 'node:url';
const [, , ui, cibles] = process.argv;
const c = await import(pathToFileURL(cibles).href), u = await import(pathToFileURL(ui).href);
const codes = [...c.BLOQUANTS, ...c.AVERTISSEMENTS, ...c.AVERTISSEMENTS_RESERVES];
console.log(JSON.stringify({ n: codes.length, sans: codes.filter((k) => !Object.prototype.hasOwnProperty.call(u.MOTIFS, k) || typeof u.MOTIFS[k] !== 'string' || !u.MOTIFS[k]) }));
JS
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
rq() { node "$TA" req "$@"; }

mutant() { # mutant <nom> <expression-sed> -> MUT_MOD ; code 1 si le module manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; f="$d/vf-cockpit-lancer-ui.mjs"; MUT_MOD="$f"; [ -f "$MOD" ] || return 1
  cp "$MOD" "$f"; cp "$(dirname "$MOD")/vf-cockpit-lancer-style.mjs" "$d/"; cp "$f" "$f.orig"; sed -i.bak "$2" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (module absent ou ligne marquée inchangée)" "sans effet" "effet"; }
SRVN=0
run_lu() { # run_lu <module> <mode> -> LJ LU_PORT ; un serveur factice neuf, un Chrome neuf
  SRVN=$((SRVN+1)); LU_PORT="$(libre)"
  LU_EXPIRE_MS="${LU_EXPIRE_MS:-}" LU_WORK="$WORK" node "$AUX/page-lancer.mjs" "$1" "$LU_PORT" "$TA" > "$WORK/srv-$SRVN.out" 2>&1 </dev/null & LU_PID=$!; PIDS+=($LU_PID)
  for _ in $(seq 1 100); do [ "$(rq "$LU_PORT" GET /__journal 2>/dev/null | head -1)" = "200" ] && break; sleep 0.1; done
  LJ="$(node "$AUX/chrome-lancer-ui.mjs" "$CHROME" "$2" "{\"P\":$LU_PORT}")"; vf_hyg_stop "$LU_PID"
}
ABS='j.absent?"ABSENT":'

echo "=== LU.S — faits statiques du script servi (sans navigateur) ==="
ST="$(node "$AUX/statique.mjs" "$MOD")"
assert_eq "LU.S1 — injectionLancer({ indisponible: true }) rend la chaîne vide" "$(rj "$ST" "${ABS}j.indispoVide")" "true"
assert_eq "LU.S2 — injectionLancer({}) : une seule balise <script> sans attribut, aucun <style>, première ligne = l'en-tête" "$(rj "$ST" "${ABS}(j.balises+\"/\"+j.fermees+\"/\"+j.nue+\"/\"+j.style+\"/\"+j.premiere)")" "1/1/true/0/// VibeFlow (72-06) : lancer du travail depuis les cartes"
assert_eq "LU.S3 — aucune adresse web écrite en entier dans le script (témoin : le motif en trouve une plantée)" "$(rj "$ST" "${ABS}(\"adresses=\"+j.adresses+\" temoin=\"+j.temoinAdr)")" "adresses=0 temoin=1"
assert_eq "LU.S4 — exactement deux fetch, vers /api/vf/lancer et /api/vf/lancer/cibles" "$(rj "$ST" "${ABS}(j.fetchs+\"|\"+j.urls)")" "2|/api/vf/lancer,/api/vf/lancer/cibles"
assert_eq "LU.S5 — aucun innerHTML, outerHTML, insertAdjacentHTML, document.write, eval(, new Function, postMessage(, localStorage, sessionStorage, document.cookie, littéral de couleur, .style, cssText (témoin : le détecteur en voit 13 plantés)" "$(rj "$ST" "${ABS}(\"interdits=\"+j.interdits+\" temoin=\"+j.temoinInterdits)")" "interdits=aucun temoin=13"
assert_eq "LU.S6 — LIBELLES_VERBES : exactement cadrer, planifier, executer, verifier, reprendre (ordre fermé), figé, libellés accentués" "$(rj "$ST" "${ABS}(j.cles+\"|\"+j.valeurs+\"|\"+j.fige)")" "cadrer,planifier,executer,verifier,reprendre|Cadrer,Planifier,Exécuter,Vérifier,Reprendre|true"
CIB="$SCRIPTS/vf-cockpit-lancer-cibles.mjs"; PJ="$(node "$AUX/parite.mjs" "$MOD" "$CIB")"
assert_eq "LU.S8 — ST-2 : chaque code de la table de cibles (liste DÉRIVÉE du module réel, au moins 14 codes) a un texte dans MOTIFS de l'interface" "$(rj "$PJ" '(j.n>=14?"n>=14":"liste trop courte "+j.n)+"/sans="+j.sans.join()')" "n>=14/sans="
assert_eq "LU.S7 — MOTIFS : les quatorze codes de 72-03 et phase-sans-plan (LB1) avec leurs textes, mot pour mot, aucun code en plus" "$(rj "$ST" "${ABS}j.ecart")" "aucun"

# LU.S9 (lot 8 LB3-S, revue LB1-LB2, finding c) : la durée de validité que la page connaît suit la variable que Q lit (VF_COCKPIT_LANCER_EXPIRE_MS, 1 000 à 600 000), et non une constante : défaut 120 s, valeur hors bornes ou illisible = défaut
expire_servi() { VF_COCKPIT_LANCER_ARME_MS="${3:-}" VF_COCKPIT_LANCER_EXPIRE_MS="$2" node -e "import(process.argv[1]).then((m) => { const h = m.injectionLancer({}); const x = /\"expireMs\":([0-9]+)/.exec(h); console.log(x ? x[1] : 'absent'); })" "$1" 2>&1 | tail -1; }
assert_eq "LU.S9 — expireMs du script servi : variable absente 120000 ; 30000 -> 30000 ; 600000 -> 600000 ; 500 (hors bornes) -> 120000 ; 'abc' -> 120000" "$(expire_servi "$MOD" ''),$(expire_servi "$MOD" 30000),$(expire_servi "$MOD" 600000),$(expire_servi "$MOD" 500),$(expire_servi "$MOD" abc)" "120000,30000,600000,120000,120000"
if mutant M-EXPIRE-CONSTANTE 's|^const EXPIRE_PAGE_MS = (() => {|const EXPIRE_PAGE_MS = 120000; const EXPIRE_ENV_IGNOREE = (() => {|'; then
  assert_eq "M-EXPIRE-CONSTANTE — le mutant (durée codée en dur) rougit LU.S9 : la variable posée à 30000 n'est plus suivie (témoin : le défaut, lui, reste 120000)" "$(expire_servi "$MUT_MOD" ''),$(expire_servi "$MUT_MOD" 30000)" "120000,120000"
else sans_effet M-EXPIRE-CONSTANTE; fi
# LU.S10 (lot 8 LB3-S2, revue du delta, finding F7) : la page retient EXACTEMENT la durée que Q retient (lancer-q : expire > arme, sinon défaut) ; témoin : mêmes réponses que le module de Q lui-même, pour toutes les combinaisons
q_servi() { VF_COCKPIT_LANCER_ARME_MS="${2:-}" VF_COCKPIT_LANCER_EXPIRE_MS="$1" node -e "import(process.argv[1]).then((m) => console.log(m.EXPIRE_MS))" "$SCRIPTS/vf-cockpit-lancer-q.mjs" 2>&1 | tail -1; }
combi() { local e="$1" a="$2" q p; q="$(q_servi "$e" "$a")"; p="$(expire_servi "$MOD" "$e" "$a")"; [ "$q" = "$p" ] && echo "$e/$a=$p" || echo "$e/$a=ECART(Q $q, page $p)"; }
assert_eq "LU.S10 — la page suit la règle de cohérence de Q : (expire/arme) 1500/2000 -> 120000 (Q et page) ; 2000/2000 -> 120000 ; 2001/2000 -> 2001 ; 1000/500 -> 120000 (plancher d'armement 1000) ; 1500/1000 -> 1500 ; 30000/abc -> 30000 ; 600000/10000 -> 600000" "$(combi 1500 2000),$(combi 2000 2000),$(combi 2001 2000),$(combi 1000 500),$(combi 1500 1000),$(combi 30000 abc),$(combi 600000 10000)" "1500/2000=120000,2000/2000=120000,2001/2000=2001,1000/500=120000,1500/1000=1500,30000/abc=30000,600000/10000=600000"
if mutant M-EXPIRE-SANS-COHERENCE 's|return expire > arme ? expire : 120000;|return expire;|'; then
  assert_eq "M-EXPIRE-SANS-COHERENCE — le mutant (la page ignore expire > arme) rougit LU.S10 : avec 1500/2000 la page prend 1500 là où Q sert 120000 (témoin : le module de Q sert bien 120000, et 1500/1000 reste 1500)" "$(expire_servi "$MUT_MOD" 1500 2000),$(q_servi 1500 2000),$(expire_servi "$MUT_MOD" 1500 1000)" "1500,120000,1500"
else sans_effet M-EXPIRE-SANS-COHERENCE; fi

if [ -n "$CHROME" ]; then
echo "=== LU.15 — port du serveur factice ==="
P15="$(libre)"; assert_eq "LU.15 — le port du serveur factice vient de libre() : >= 4600 et différent de 4456" "$([ "$P15" -ge 4600 ] && [ "$P15" != 4456 ] && echo ok || echo "port=$P15")" "ok"

echo "=== LU.1 — carte de phase et de mission ==="
run_lu "$MOD" lu1; J="$LJ"
assert_eq "LU.1 (phase n:ph-72) — section visible, h3 « Lancer du travail », principal « Planifier » en btn primary, menu « Autres actions » avec Cadrer et Exécuter en btn soft (ordre fermé), placée avant la section suivante du panneau" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+(j.phase?j.phase.h3.join()+"|"+j.phase.princ.join()+"|"+j.phase.menu.join()+"|"+j.phase.autres.join()+"|"+j.phase.avantAutre:"section absente")')" '{} Lancer du travail|Planifier:btn primary|Autres actions|Cadrer:btn soft,Exécuter:btn soft|true'
assert_eq "LU.1 (mission n:dag-m1) — principal « Reprendre » (btn primary), son seul verbe : aucun menu" "$(rj "$J" '(j.mission?j.mission.h3.join()+"|"+j.mission.princ.join()+"|"+j.mission.details+"|"+j.mission.nb:"section absente")')" "Lancer du travail|Reprendre:btn primary|0|1"

echo "=== LU.2 — cibles qui n'ouvrent pas de section ==="
run_lu "$MOD" lu2; J="$LJ"
assert_eq "LU.2 — n:ph-404 (absente de la liste), f:src/x.js, x:abc, ph-72 sans préfixe, x:ph-72 et f:dag-m1 (préfixe autre dont la fin est un identifiant listé) : aucune section, aucun POST, aucune exception ; témoin : la carte valide rend son principal" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+(j.neg?Object.values(j.neg).join():"?")+" posts="+j.posts+" err="+j.err+" temoin="+j.temoin')" "{} 0,0,0,0,0,0 posts=0 err=0 temoin=Planifier:btn primary"

echo "=== LU.3 / LU.4 — envoi d'une proposition ==="
run_lu "$MOD" lu3; J="$LJ"
assert_eq "LU.3 — clic sur le principal : UN POST /api/vf/lancer, Content-Type application/json, jeton de la page, Origin de la page, corps exact {cible, verbe}, clés cible et verbe seulement" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+j.n+"|"+(j.p&&j.p.ct)+"|"+(j.p&&j.p.jeton)+"|"+(j.p&&j.p.origin)+"|"+(j.p&&j.p.corps)+"|"+j.cles')" "{} 1|application/json|true|http://127.0.0.1:$LU_PORT|{\"cible\":\"ph-72\",\"verbe\":\"planifier\"}|cible,verbe"
assert_eq "LU.3 — un double clic rapide (réponse retardée de 500 ms) ne fait partir qu'UN POST" "$(rj "$J" '"posts="+(j.fin&&j.fin.posts)')" "posts=1"
assert_eq "LU.3 — le GET de la liste porte le jeton de la page (témoin : au moins une lecture), le POST aussi" "$(rj "$J" '"gets="+(j.fin&&j.fin.gets>=1)+" getsKo="+(j.fin&&j.fin.getsKo)+" postsKo="+(j.fin&&j.fin.postsKo)')" "gets=true getsKo=0 postsKo=0"
assert_eq "LU.3 — réponse 202 : message d'envoi dans un p role=status, avec le titre de la carte" "$(rj "$J" 'j.statutRole+"|"+j.statut')" "p|Proposition envoyée au terminal : Planifier — Phase 72. Confirmez-la dans le terminal."
assert_eq "LU.3 — SP-1 : le 202 signale la proposition acceptée par UN évènement vf-lancer-propose du document (le double clic ne fait partir qu'un POST)" "$(rj "$J" '"prop="+j.prop+" n="+j.n')" "prop=1 n=1"
assert_eq "LU.4 — clic sur « Exécuter » du menu : corps {cible: ph-72, verbe: executer}" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+j.menu')" "{} {\"cible\":\"ph-72\",\"verbe\":\"executer\"}"

echo "=== LU.5 / LU.6 — pré-vols : bloquants, avertissements, travail non commité ==="
run_lu "$MOD" lu5; J="$LJ"
assert_eq "LU.5 — bloquants phase-finie et terminal-absent : deux lignes « Bloqué : <motif> », les trois boutons disabled, un clic ne produit aucun POST" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+(j.bloq?j.bloq.lignes.join("|")+" dis="+j.bloq.dis+"/"+j.bloq.nb:"section absente")+" posts="+j.bloqPosts')" "{} Bloqué : La phase est terminée.|Bloqué : Le terminal est indisponible sur ce poste. dis=3/3 posts=0"
assert_eq "LU.5 — avertissements dependance-non-close et lancement-recent : deux lignes « Attention : <motif> », boutons actifs, le clic produit un POST" "$(rj "$J" '(j.aver?j.aver.lignes.join("|")+" dis="+j.aver.dis+" posts="+j.averPosts:"section absente")')" "Attention : Une phase dont celle-ci dépend n'est pas close (lecture de la prose du ROADMAP, indicative).|Attention : Cette cible a déjà été lancée récemment. dis=0 posts=1"
run_lu "$MOD" lu6; J="$LJ"
assert_eq "LU.6 — sans le code travail-non-commite aucune ligne de ce motif ; avec lui, la ligne s'affiche (Attention) et le principal reste actif" "$(rj "$J" 'JSON.stringify(j.erreurs)+" sans="+(j.sans?j.sans.lignes.length+"/"+j.sans.princ.join():"?")+" avec="+(j.avec?j.avec.lignes.join("|")+"/dis="+j.avec.dis:"?")')" "{} sans=0/Planifier:btn primary avec=Attention : Du travail non commité existe dans l'arbre de travail./dis=0"

echo "=== LU.7 — état « lancée » ==="
run_lu "$MOD" lu7; J="$LJ"
assert_eq "LU.7 — lancee = true : « Préparée depuis la carte. » (jamais « Lancée » sans signal d'exécution, PU-G-113) ; forme riche attendue, vue, terminée : « Lancée : Planifier, … »" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+[j.vrai,j.attendue,j.vue,j.terminee].join("¤")')" "{} Préparée depuis la carte.¤Commande préparée dans le terminal : Planifier. Elle ne démarre qu'avec Entrée dans le terminal ; en attente de la session.¤Lancée : Planifier, session en cours.¤Lancée : Planifier, session terminée."
assert_eq "LU.7 (PU-G-113) — forme sans état (lancee = true) et état attendue (ligne seulement posée dans le terminal, rien n'a démarré) : aucune ligne « Lancée » ; vue et terminée en ont une (témoin)" "$(rj "$J" '"vrai="+j.vraiL+"|attendue="+j.attendueL+"|vue="+j.vueL+"|terminee="+j.termineeL')" "vrai=|attendue=|vue=Lancée : Planifier, session en cours.|terminee=Lancée : Planifier, session terminée."
assert_eq "LU.7 — false, null, absent, {etat:x}, {etat:vue, verbe:x;y}, 'vue', 1, {} : aucune ligne « Lancée » (témoin : les quatre formes valides en ont une)" "$(rj "$J" '[j.faux,j.nul,j.absent,j.etatx,j.verbex,j.chaine,j.un,j.vide].map((x)=>x===undefined?"?":x).join("¤")+" temoin="+(j.vrai&&j.vue&&j.terminee&&j.attendue?"oui":"non")')" "¤¤¤¤¤¤¤ temoin=oui"

echo "=== LU.8 — rendu hostile ==="
run_lu "$MOD" lu8; J="$LJ"
assert_eq "LU.8 — titres, codes et verbe hostiles : aucun img dans le panneau, window.__M72 jamais posé, 0 violation de CSP" "$(rj "$J" 'JSON.stringify(j.erreurs)+" imgs="+j.imgs+" m72="+j.m72+" violations="+j.violations')" "{} imgs=0 m72=undefined violations=0"
assert_eq "LU.8 — le journal du faux serveur : aucune requête hors GET /project.html, GET /api/vf/lancer/cibles et POST /api/vf/lancer (donc jamais GET /x) ; deux POST (témoin)" "$(rj "$J" 'JSON.stringify(j.hors)+" posts="+j.nposts')" "[] posts=2"
assert_eq "LU.8 — le titre hostile s'affiche mot pour mot dans le message d'envoi, par textContent" "$(rj "$J" '(j.statuts||[]).join(" ## ")')" "Proposition envoyée au terminal : Planifier — \"; touch M #. Confirmez-la dans le terminal. ## Proposition envoyée au terminal : Planifier — <img src=x onerror=window.__M72=1>. Confirmez-la dans le terminal."
assert_eq "LU.8 — le titre n'apparaît dans AUCUN corps de requête : corps = {cible, verbe} seulement" "$(rj "$J" '(j.corps||[]).join(" ")')" '{"cible":"ph-h2","verbe":"planifier"} {"cible":"ph-h2","verbe":"planifier"}'
assert_eq "LU.8 — aucun bouton à texte hostile (seul « Planifier »), codes hostiles = « Contrôle non reconnu. » jamais le code brut" "$(rj "$J" '(j.h1?j.h1.boutons.join()+"|"+j.h1.lignes.join("|")+"|"+j.h2.boutons.join()+"|"+j.h2.lignes.join("|"):"?")')" "Planifier|Bloqué : Contrôle non reconnu.|Attention : Contrôle non reconnu.|Planifier|Attention : Contrôle non reconnu."

echo "=== LU.9 — la touche Entrée ne déclenche pas le raccourci du viewer ==="
run_lu "$MOD" lu9; J="$LJ"
assert_eq "LU.9 — Entrée de confiance sur le principal focalisé : UN POST, le panneau n'a pas été redessiné par le raccourci du viewer" "$(rj "$J" 'JSON.stringify(j.erreurs)+" posts="+j.posts+" redessine="+j.redessine')" "{} posts=1 redessine=0"

echo "=== LU.10 / LU.11 — ordre de définition de window.VibeFlow, pages hors Projet ==="
run_lu "$MOD" lu10; J="$LJ"
assert_eq "LU.10 — window.VibeFlow défini AVANT le script, puis APRÈS (attente bornée) : la section est présente" "$(rj "$J" 'JSON.stringify(j.erreurs)+" avant="+j.avant+" apres="+j.apres')" "{} avant=Planifier:btn primary apres=Planifier:btn primary"
assert_eq "LU.10 — jamais défini : aucune section, aucune exception, aucune requête de lancement" "$(rj "$J" 'j.jamais?"zones="+j.jamais.zones+" err="+j.jamais.err+" reqs="+j.jamais.reqs+" api="+j.jamais.api:"?"')" "zones=0 err=0 reqs=0 api=undefined"
run_lu "$MOD" lu11; J="$LJ"
assert_eq "LU.11 — /index.html, /autre.html et localhost au lieu de 127.0.0.1 : aucune section, aucune requête vers /api/vf/lancer, aucune exception ; témoin : /project.html rend sa section" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+(j.hors?["index","autre","localhost"].map((k)=>j.hors[k].zones+"/"+j.hors[k].reqs+"/"+j.hors[k].err).join(" "):"?")+" temoin="+j.temoin')" "{} 0/0/0 0/0/0 0/0/0 temoin=Planifier:btn primary"

echo "=== LU.12 — refus et pannes ==="
run_lu "$MOD" lu12; J="$LJ"
REFUSE="Le lancement a été refusé."
assert_eq "LU.12 — 403, 404, 409 {refus:bloque}, 500, réseau coupé, refus hostile, champ motif, 409 {refus:jeton}, corps illisible : un message par cas, jamais le texte du serveur ni un img" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+(j.msgs||[]).join(" ## ")+" imgs="+j.imgs')" "{} $REFUSE ## Le lancement n'est pas disponible. Relancez /vf-cockpit --terminal. ## Le lancement est bloqué : voyez les motifs ci-dessus. ## $REFUSE ## Le cockpit ne répond pas. ## $REFUSE ## $REFUSE ## $REFUSE ## $REFUSE imgs=0"

assert_eq "LU.12 — SP-1 : aucun des refus ou pannes ne signale d'évènement vf-lancer-propose (témoin : les neuf cas ont rendu leur message)" "$(rj "$J" '"prop="+j.prop+" msgs="+(j.msgs||[]).length')" "prop=0 msgs=9"

echo "=== LU.13 / LU.14 — liste invalide, verbes ==="
run_lu "$MOD" lu13; J="$LJ"
assert_eq "LU.13 — actif:false, cibles absent, corps non JSON, statut 404, cibles non tableau : aucune section ni titre, aucune exception, aucun POST ; témoin : la liste valide rend son principal" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+(j.cas||[]).join()+" "+(j.titres||[]).join()+" posts="+j.posts+" temoin="+j.temoin')" "{} 0,0,0,0,0 0/0,0/0,0/0,0/0,0/0 posts=0 temoin=Planifier:btn primary"
run_lu "$MOD" lu14; J="$LJ"
assert_eq "LU.14 — verbe inconnu ignoré (principal Planifier, autre Exécuter) ; principal absent : premier verbe de l'ordre fermé (Cadrer, puis Exécuter) ; principal hors liste : Exécuter" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+["inconnu","sans","hors"].map((k)=>j[k]?j[k].princ.join()+"+"+j[k].autres.join():"?").join(" ")')" "{} Planifier:btn primary+Exécuter:btn soft Cadrer:btn primary+Exécuter:btn soft Exécuter:btn primary+"
assert_eq "LU.14 — verbes vide ou sans verbe valide : « Aucune action disponible. » et aucun bouton" "$(rj "$J" '["vide","inval"].map((k)=>j[k]?j[k].lignes.join("|")+"/"+j[k].nb:"?").join(" ")')" "Aucune action disponible./0 Aucune action disponible./0"

echo "=== LU.16 à LU.18 — LB1 : retour immédiat, aide, sous le titre, message borné, sans plan, chargement ==="
run_lu "$MOD" lu16; J="$LJ"
assert_eq "LU.16 (PU-G-110) — la section est placée sous le titre du panneau, dans son en-tête" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+j.sousTitre')" "{} true"
assert_eq "LU.16 (PU-G-111) — au focus clavier, la phrase d'aide s'affiche, est le title du bouton et sa description liée (hors du bouton)" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+[j.aide.visible,j.aide.texte===j.aide.titre,j.aide.decrit===j.aide.titre,j.aide.horsBouton,j.aide.texte.indexOf("Planifier :")===0].join()')" "{} true,true,true,true,true"
assert_eq "LU.16 (PU-G-116) — pendant l'attente du serveur : le bouton dit « Préparation… », aria-busy, le focus RESTE sur lui" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+JSON.stringify(j.pendant)')" '{} {"txt":"Préparation…","busy":"true","focus":true,"zone":"true"}'
assert_eq "LU.16 (PU-G-116) — après la réponse : le focus est sur le bouton « Planifier » reconstruit, plus aucun aria-busy" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+JSON.stringify(j.apres)')" '{} {"focus":"planifier","txt":"Planifier","busy":null}'
LU_EXPIRE_MS=1500 run_lu "$MOD" lu17; J="$LJ"
assert_eq "LU.17 (PU-G-113) — le message « Proposition envoyée » est borné à la durée d'une proposition : il cède la place à une phrase qui ne prétend plus rien" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+(j.avant||"").slice(0,22)+"|"+(j.apres||"").slice(0,48)')" "{} Proposition envoyée au|La proposition envoyée il y a plus de deux minut"
assert_eq "LU.17 (PU-G-125) — phase sans plan (principal Cadrer) : « Exécuter » du menu avertit « cadrez puis planifiez d'abord », reste actif (le serveur juge) ; phase avec plan : aucun avertissement" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+JSON.stringify([j.sans.dansMenu,j.sans.note,j.sans.actif,j.sans.decrit.indexOf("cadrez puis planifiez")>0,j.avec.note,j.avec.decrit.indexOf("cadrez")])')" '{} [true,["Attention : Aucun plan à exécuter pour cette phase : cadrez puis planifiez d'"'"'abord."],true,true,0,-1]'
run_lu "$MOD" lu18; J="$LJ"
assert_eq "LU.18 (DG-11) — la liste met 2,5 s à répondre : la section n'est pas absente, elle dit « Chargement des actions… » (aria-busy, aucun bouton), puis rend ses boutons" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+j.charge+" => "+j.pret')" "{} Lancer du travail Chargement des actions…|true|0 => null|2"
assert_eq "LU.18 (DG-11) — carte absente de la liste (témoin du chargement ci-dessus) : la section se retire d'elle-même, rien d'affiché" "$(rj "$J" 'JSON.stringify(j.erreurs)+" "+j.absente')" "{} true|0"

echo "=== Mutants — chaque garde du module a sa sonde ==="
if mutant M-TEXTE-RETIRE "/^  'lancement-recent':/d"; then
  assert_eq "M-TEXTE-RETIRE — le mutant rougit LU.S8 : un code de la table de cibles n'a plus de texte dans l'interface (témoin : la liste dérivée a ses codes)" "$(rj "$(node "$AUX/parite.mjs" "$MUT_MOD" "$CIB")" '(j.n>=14?"n>=14":"plante")+"/"+(j.sans.length>=1?"rouge":"sain")')" "n>=14/rouge"
else sans_effet M-TEXTE-RETIRE; fi
if [ -n "$CHROME" ] && mutant M-PROPOSE '/garde:propose/d'; then run_lu "$MUT_MOD" lu3
  assert_eq "M-PROPOSE — le mutant rougit LU.3 : le 202 ne signale plus rien au tiroir (témoin : le POST est parti et le message d'envoi s'affiche)" "$(rj "$LJ" '"n="+j.n+" rouge="+(j.prop!==1)')" "n=1 rouge=true"
elif [ -n "$CHROME" ]; then sans_effet M-PROPOSE; fi
if mutant M-INNERHTML '/garde:titre/s/\.textContent =/.innerHTML =/'; then run_lu "$MUT_MOD" lu8
  assert_eq "M-INNERHTML — le mutant rougit LU.8 : un img entre dans le panneau, une requête hors liste part ou la CSP est violée (témoin : section rendue)" "$(rj "$LJ" '"section="+(!!j.h2&&j.h2.nb>0)+" rouge="+(j.imgs>=1||(j.hors||[]).length>=1||j.violations>=1)')" "section=true rouge=true"
else sans_effet M-INNERHTML; fi
if mutant M-ENTREE-VIEWER '/garde:entree/d'; then run_lu "$MUT_MOD" lu9
  assert_eq "M-ENTREE-VIEWER — le mutant rougit LU.9 : le panneau est redessiné par Entrée et plus aucun POST ne part (témoin : section rendue, aucune erreur)" "$(rj "$LJ" 'JSON.stringify(j.erreurs)+" rouge="+(j.redessine>=1&&j.posts===0)')" "{} rouge=true"
else sans_effet M-ENTREE-VIEWER; fi
if mutant M-BLOQUANT-IGNORE '/garde:bloquants/d'; then run_lu "$MUT_MOD" lu5
  assert_eq "M-BLOQUANT-IGNORE — le mutant rougit LU.5 : les boutons ne sont plus disabled sous bloquant (témoin : lignes « Bloqué » affichées)" "$(rj "$LJ" '"lignes="+(j.bloq?j.bloq.lignes.length:0)+" rouge="+(!!j.bloq&&j.bloq.dis<j.bloq.nb)')" "lignes=2 rouge=true"
else sans_effet M-BLOQUANT-IGNORE; fi
if mutant M-CHAT-ENVOYE '/garde:corps/s/{ cible: id, verbe }/{ cible: id, verbe, chat: null }/'; then run_lu "$MUT_MOD" lu3
  assert_eq "M-CHAT-ENVOYE — le mutant rougit LU.3 : le corps porte une clé de plus que cible et verbe (témoin : un POST est parti)" "$(rj "$LJ" '"n="+j.n+" rouge="+(j.cles!=="cible,verbe")')" "n=1 rouge=true"
else sans_effet M-CHAT-ENVOYE; fi
if mutant M-VERBE-LIBRE '/garde:verbes/s/cfg\.verbes\.indexOf(v) >= 0/true/'; then
  run_lu "$MUT_MOD" lu14; assert_eq "M-VERBE-LIBRE — le mutant rougit LU.14 : un verbe hors de la liste fermée donne un bouton (témoin : aucune erreur, section rendue)" "$(rj "$LJ" 'JSON.stringify(j.erreurs)+" rouge="+(!!j.inconnu&&j.inconnu.nb!==2)')" "{} rouge=true"
  run_lu "$MUT_MOD" lu8; assert_eq "M-VERBE-LIBRE — le mutant rougit LU.8 : le verbe hostile donne un bouton (témoin : section rendue)" "$(rj "$LJ" '"section="+(!!j.h2&&j.h2.nb>0)+" rouge="+(!!j.h2&&j.h2.boutons.join()!=="Planifier")')" "section=true rouge=true"
else sans_effet M-VERBE-LIBRE; fi
if mutant M-DOUBLE-ENVOI '/garde:envol/d'; then run_lu "$MUT_MOD" lu3
  assert_eq "M-DOUBLE-ENVOI — le mutant rougit LU.3 : le double clic fait partir deux POST (témoin : au moins un POST)" "$(rj "$LJ" '"posts="+((j.fin&&j.fin.posts)>=1)+" rouge="+((j.fin&&j.fin.posts)!==1)')" "posts=true rouge=true"
else sans_effet M-DOUBLE-ENVOI; fi
if mutant M-JETON-ABSENT '/garde:jeton/s/x-vf-cockpit-token/x-vf-absent/'; then run_lu "$MUT_MOD" lu3
  assert_eq "M-JETON-ABSENT — le mutant rougit LU.3 : le faux serveur reçoit une lecture ou un POST sans le jeton (témoin : au moins une lecture de la liste)" "$(rj "$LJ" '"gets="+((j.fin&&j.fin.gets)>=1)+" rouge="+((j.fin&&(j.fin.getsKo>=1||j.fin.postsKo>=1))===true)')" "gets=true rouge=true"
else sans_effet M-JETON-ABSENT; fi
if mutant M-HORS-PROJET '/garde:chemin/d'; then run_lu "$MUT_MOD" lu11
  assert_eq "M-HORS-PROJET — le mutant rougit LU.11 : /index.html ou /autre.html reçoit une section ou une requête de lancement (témoin : /project.html rend sa section)" "$(rj "$LJ" '"temoin="+(j.temoin==="Planifier:btn primary")+" rouge="+(!!j.hors&&(j.hors.index.zones+j.hors.index.reqs+j.hors.autre.zones+j.hors.autre.reqs)>=1)')" "temoin=true rouge=true"
else sans_effet M-HORS-PROJET; fi
if mutant M-CIBLE-LIBRE '/garde:cible/d'; then run_lu "$MUT_MOD" lu2
  assert_eq "M-CIBLE-LIBRE — le mutant rougit LU.2 : une cible sans le préfixe n: ouvre une section (témoin : la carte valide rend son principal)" "$(rj "$LJ" '"temoin="+(j.temoin==="Planifier:btn primary")+" rouge="+(!!j.neg&&Object.values(j.neg).some((z)=>z>=1))')" "temoin=true rouge=true"
else sans_effet M-CIBLE-LIBRE; fi
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
