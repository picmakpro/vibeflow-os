#!/usr/bin/env bash
# test-cockpit-frise-curseur.sh : le curseur de relecture, l'encart « À cet instant », les fichiers à t et « Voir sur la carte » de la frise (Phase 74, plan 74-06 ;
# TEMP-05, part forme de TEMP-12), sous Chrome. La route de frise, celle du fil réduit (/api/vf/transcript) et l'état (missions) sont REMPLACÉS dans la page par des `fetch` de
# test (VF_PRE) qui servent les fixtures de frise-fabrique.mjs et tiennent le journal des requêtes (départ, fin, concurrence) ; la page, le serveur, le flux, la régie, le
# canal de marquage de la 75 (VF_MARQUES) et la navigation d'onglets de la 80 (VF_ONGLETS) sont les vrais.
#   C1 repère clavier  C2 pointeur  C3 trait et sortie de fenêtre  C4 voies  C5 nœuds portés  C6 fichiers  C6b analyse du suffixe et cibles coupées
#   C7 plafond de lectures  C8 « Voir sur la carte » (canal de la 75)  C8c routage d'onglet  C9 aucune persistance  C10 forme du code  C11 tactile  C12 cycle de vie
# Écart de contrat (écrit au SUMMARY) : « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par la session principale le 2026-11-13 ;
# amende l'arrangement de P74-D-47 (le rebranchement de "Voir sur la carte" passe de 75-07 à 74-06) » : plus de C8b (aucun showBoard), C8 lit le canal de la 75.
# Plan non marqué audit : pas de mutants (rituel levé : régime allégé). Chrome headless en CDP (SAUTÉ, jamais compté réussi, sans navigateur). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
UI="$(cd "$SCRIPTS/.." && pwd)/skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
SRV=""
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
export HOME="$WORK/home"
T0=$(date +%s)

PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${FRISE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES)}"
NODE="$(command -v node)"
export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-30000}"

# ---------- crochets de page (VF_PRE) ----------
cat > "$AUX/pre.js" <<'JS'
window.__errs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
{ const ce = console.error; console.error = (...a) => { window.__errs.push(a.map(String).join(' ')); ce.apply(console, a); }; }
window.__couleur = (x) => { const p = document.createElement('i'); p.style.color = x.startsWith('--') ? 'var(' + x + ')' : x; document.body.appendChild(p); const c = getComputedStyle(p).color; p.remove(); return c; };
window.__vfF = { reponse: null, statut: 503, delai: 0, reqs: [] };
window.__vfS = { signal: { missions: [], phases: [] } };
window.__tr = { corps: {}, echec: [], delai: 40, reqs: [], enVol: 0, max: 0 };
window.__urls = []; window.__charger = []; window.__fin = 0; window.__voir = []; window.__marqLus = 0; window.__geste = false; window.__surOnglet = [];
window.__fiche = [];
{ const espion = { ouvrir: (id) => { window.__fiche.push(id); } };
  Object.defineProperty(window, '__vfFiche', { configurable: true, get: () => espion, set: () => {} }); }
// __vfFrise : finirRelecture et voirSurLaCarte (posées par 74-vf-frise-carte.js dans le rappel d'arrivée) sont comptées, puis déléguées
{ let f; const veille = (o, nom, log) => { let fn = o[nom];
    Object.defineProperty(o, nom, { configurable: true, enumerable: true, get: () => (typeof fn === 'function' ? (...a) => log(a, fn) : fn), set: (x) => { fn = x; } }); };
  Object.defineProperty(window, '__vfFrise', { configurable: true, get: () => f, set: (o) => { if (o && typeof o === 'object') {
    veille(o, 'finirRelecture', (a, fn) => { window.__fin++; return fn(...a); });
    veille(o, 'voirSurLaCarte', (a, fn) => { window.__voir.push(JSON.parse(JSON.stringify(a))); return fn(...a); }); } f = o; } }); }
{ let m; Object.defineProperty(window, 'VF_MARQUES', { configurable: true,
  get: () => { if (/74-vf-frise-carte/.test(String(new Error().stack)) && !window.__geste) window.__marqLus++; return m; }, set: (x) => { m = x; } }); }
{ let c; Object.defineProperty(window, 'VF_COQUILLE', { configurable: true, get: () => c,
  set: (x) => { c = x && typeof x.surOnglet === 'function' ? Object.assign({}, x, {
    chargerOnglet: (...a) => { window.__charger.push(a[0]); return x.chargerOnglet(...a); },
    surOnglet: (r, o) => { const m = /74-vf-frise-(curseur|encart|fichiers|carte)\.js/.exec(String(new Error().stack));
      window.__surOnglet.push({ cle: o && o.cle, source: m ? m[0] : null }); return x.surOnglet(r, o); } }) : x; } }); }
window.__kdC = [];
{ const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener;
  EventTarget.prototype.addEventListener = function (t, f, o) { if (t === 'keydown' && this === document && /74-vf-frise-curseur/.test(String(new Error().stack))) window.__kdC.push(f); return A.call(this, t, f, o); };
  EventTarget.prototype.removeEventListener = function (t, f, o) { if (t === 'keydown' && this === document) window.__kdC = window.__kdC.filter((x) => x !== f); return R.call(this, t, f, o); }; }
{ const f0 = window.fetch.bind(window);
  const rep = (st, o) => new Response(JSON.stringify(o), { status: st, headers: { 'content-type': 'application/json' } });
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url; window.__urls.push([url, (i && i.method) || 'GET']);
    if (/^\/api\/vf\/frise(\?|$)/.test(url)) {
      const F = window.__vfF, c = F.reponse ? JSON.parse(JSON.stringify(F.reponse)) : {}; F.reqs.push({ url }); c.at = new Date().toISOString();
      const q = new URLSearchParams(url.split('?')[1] || '');
      if (q.get('jusqua') && c.voies) { const J0 = c.jusqua, J = Number(q.get('jusqua'));
        for (const v of c.voies) { if (v.fin === J0) v.fin = J; for (const s of v.segments || []) if (s[1] === J0) s[1] = J; }
        c.depuis = Number(q.get('depuis')); c.jusqua = J; }
      return new Promise((ok) => setTimeout(() => ok(rep(F.statut, F.statut === 200 ? c : { erreur: 'indisponible' })), F.delai || 0)); }
    if (/^\/api\/vf\/state(\?|$)/.test(url)) return f0(u, i).then((r) => r.json()).then((j) => rep(200, Object.assign({}, j, { signal: Object.assign({}, j.signal, window.__vfS.signal) })));
    if (/^\/api\/vf\/transcript\?/.test(url)) { const T = window.__tr, id = decodeURIComponent((/id=([^&]*)/.exec(url) || [])[1] || ''), r = { id, t0: Date.now() };
      T.reqs.push(r); T.enVol++; T.max = Math.max(T.max, T.enVol);
      return new Promise((ok, ko) => setTimeout(() => { T.enVol--; r.t1 = Date.now(); if (T.echec.includes(id)) return ko(new TypeError('Failed to fetch'));
        const b = T.corps[id], S = 'vibeflow/cockpit-transcript@2';
        ok(rep(200, b ? Object.assign({ schema: S, id }, b) : { schema: S, id, erreur: 'inconnu' })); }, T.delai)); }
    return f0(u, i); }; }
JS
export VF_PRE="$AUX/pre.js"

cat > "$AUX/commun.mjs" <<'JS'
export const MIN = 60000;
export const NB = ' ';
export const K = { gauche: ['ArrowLeft', 37], droite: ['ArrowRight', 39], debut: ['Home', 36], fin: ['End', 35], echap: ['Escape', 27] };
export const touche = async (h, [key, vk], mod = 0) => { for (const type of ['keyDown', 'keyUp']) await h.s.send('Input.dispatchKeyEvent', { type, key, code: key, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk, modifiers: mod }); };
export const curseur = (h) => h.ev(() => window.__vfFrise.donnees().curseurMs);
export const focus = (h) => h.ev(() => { const e = document.querySelector('.vf-frise [role=slider]'); if (e) e.focus(); return !!e && document.activeElement === e; });
export const pas = (h) => h.ev(() => { const d = window.__vfFrise.donnees(); return (d.jusqua - d.depuis) / 90; });
export const poser = (h, ms) => h.ev((m) => { window.__vfFrise.poserCurseur(m); return true; }, ms);
export const souris = (h, type, x, y, buttons = 0) => h.s.send('Input.dispatchMouseEvent', { type, x, y, button: buttons ? 'left' : 'none', buttons, clickCount: 1 });
export const xDe = (h, ms, ligne = 0) => h.ev((m, l) => { const d = window.__vfFrise.donnees(), p = document.querySelector('svg.vf-frise-pistes'); p.scrollIntoView({ block: 'center' });
  const r = p.getBoundingClientRect(); return { x: Math.round(r.left + d.ctx.x(m)), y: Math.round(r.top + 12 + l * 32), mpp: (d.jusqua - d.depuis) / d.ctx.largeur }; }, ms, ligne);
export const texte = (h, sel = '.vf-encart') => h.ev((s) => { const e = document.querySelector(s); return e ? e.innerText.replace(/\s+/g, ' ').trim() : null; }, sel);
export const encartPret = (h) => h.attendre(() => { const f = document.querySelector('.vf-encart-fichiers'); return !!f && f.getAttribute('aria-busy') === 'false'; }, 'fichiers lus');
export const fil = (h, id, elements, tronque = false) => h.ev((i, e, t) => { window.__tr.corps[i] = { fil: e, tronque: t }; return true; }, id, elements, tronque);
export const nbTr = (h) => h.ev(() => window.__tr.reqs.length);
export const idsTr = (h, depuis = 0) => h.ev((d) => window.__tr.reqs.slice(d).map((r) => r.id).sort(), depuis);
export const el = (t, cible, extra = {}) => ({ t, genre: 'outil', outil: 'Edit', verbe: 'modifie', cible, n: 1, ...extra });
// fixture des fichiers : x1.js certain (route), z.js, w.js (worktree wt-a), cible coupée et « hors du lab » lus dans le fil de fa-3
export const fixFichiers = (now, F) => { const d = (m) => now - m * MIN, E = F.entree, base = { debut: d(40), fin: d(20), fini: true, segments: [[d(40), d(20), 'travail']] };
  return [F.voie({ id: 'fa-1', ...base, cibles: { etat: 'ok', tronque: false, ecritures: [E('x1.js', d(30)), E('old.js', d(50))], lectures: [] } }),
    F.voie({ id: 'fa-2', ...base, cibles: { etat: 'ok', tronque: false, ecritures: [E('y.js', d(35))], lectures: [] } }),
    F.voie({ id: 'fa-3', debut: d(40), fin: d(2), segments: [[d(40), d(2), 'travail']], cibles: { etat: 'ok', tronque: false, ecritures: [E('z.js', d(5))], lectures: [] } })]; };
export const filFa3 = (now) => { const d = (m) => now - m * MIN;
  return [el(d(30), 'z.js'), el(d(30), 'w.js (worktree wt-a)'), el(d(30), 'cut…'), el(d(30), 'un fichier hors du lab'), el(d(10), 'late.js')]; };
export const voyants = (h) => h.ev(() => [...document.querySelectorAll('.vf-encart-liste [data-fichier]')].map((e) => [e.getAttribute('data-arbre') || null, e.getAttribute('data-cible')]));
JS

cat > "$AUX/c1.mjs" <<'JS'
import { MIN, K, touche, curseur, focus, pas, poser, souris, xDe, texte } from './commun.mjs';
export const ids = ['C1'];
const voies = (now, F) => { const d = (m) => now - m * MIN;
  return [F.voie({ id: 'e-1', debut: d(80), fin: now, segments: [[d(80), d(60), 'travail'], [d(50), now, 'travail']], evenements: [[d(70), 'erreur']] })]; };
export default async function (h) {
  await h.section('C1', async () => {
    await h.monter({});
    const a = await h.ev(() => { const s = [...document.querySelectorAll('.vf-frise [role=slider]')];
      return { n: s.length, nom: s[0] && s[0].getAttribute('aria-label'), tab: s[0] && s[0].getAttribute('tabindex'), cache: !!(s[0] && s[0].closest('[aria-hidden=true]')),
        now: s[0] && s[0].getAttribute('aria-valuenow'), max: s[0] && s[0].getAttribute('aria-valuemax') }; });
    h.egal('C1', 'un repère role=slider « Curseur de la frise », tabindex 0, hors de tout aria-hidden, valuenow = valuemax au départ', [a.n, a.nom, a.tab, a.cache, a.now === a.max && !!a.max], [1, 'Curseur de la frise', '0', false, true]);
    h.sonde('C1', 'le repère se focalise', await focus(h), '');
    await touche(h, K.droite);
    h.egal('C1', '→ sans curseur posé ne change rien', await curseur(h), null);
    const p = await pas(h), j0 = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await touche(h, K.gauche);
    const c1 = await curseur(h);
    h.sonde('C1', '← pose le curseur à 1/90 de la fenêtre avant « maintenant »', c1 !== null && Math.abs(j0 - c1 - p) < 2, `${j0 - c1} attendu ${p}`);
    await touche(h, K.gauche, 8);
    const c2 = await curseur(h);
    h.sonde('C1', 'Maj + ← recule de dix pas', Math.abs(c1 - c2 - 10 * p) < 2, `${c1 - c2} attendu ${10 * p}`);
    await touche(h, K.debut);
    const d0 = await h.ev(() => window.__vfFrise.donnees().depuis);
    h.egal('C1', 'Début pose le curseur au début de la fenêtre', await curseur(h), d0);
    await touche(h, K.fin);
    h.egal('C1', 'Fin revient à « maintenant » (curseur retiré)', await curseur(h), null);
    await touche(h, K.gauche); await touche(h, K.echap);
    const t = await texte(h);
    h.sonde('C1', 'Échap retire le curseur et l\'encart revient à son message d\'aide', (await curseur(h)) === null && /Posez le curseur/.test(t), t);
    // lecture Événements : frontière de segment ou événement précédent / suivant
    await h.monter({ voies });
    await h.changer(() => h.radio('Événements'));
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua), d = (m) => now - m * MIN;
    await focus(h);
    await touche(h, K.gauche); const e1 = await curseur(h);
    await touche(h, K.gauche); const e2 = await curseur(h);
    await touche(h, K.droite); const e3 = await curseur(h);
    h.egal('C1', 'Événements : ← → sautent à la frontière de segment (d50, d60) ou à l\'événement (d70), puis →', [e1, e2, e3].map((x) => Math.round((now - x) / MIN)), [50, 60, 50]);
    // un instant tombé dans un repère de silence se cale sur le bord le plus proche
    const k = await h.ev(() => { const d = window.__vfFrise.donnees(), s = d.ctx.proj.troncons.find((x) => x.silence); return s ? { debut: s.debut, fin: s.fin, x0: s.x0, x1: s.x1 } : null; });
    h.sonde('C1', 'la fixture a un repère de silence (témoin)', !!k, JSON.stringify(k));
    if (k) {
      const xy = await xDe(h, k.debut), px = xy.x + Math.round(0.25 * (k.x1 - k.x0));
      await souris(h, 'mousePressed', px, xy.y, 1); await souris(h, 'mouseReleased', px, xy.y);
      h.sonde('C1', 'clic au quart d\'un repère de silence : le curseur se cale sur le bord le plus proche (le début)', Math.abs((await curseur(h)) - k.debut) < 2, `${await curseur(h)} attendu ${k.debut}`);
    }
  });
}
JS

cat > "$AUX/c2.mjs" <<'JS'
import { MIN, curseur, souris, xDe } from './commun.mjs';
export const ids = ['C2'];
export default async function (h) {
  await h.section('C2', async () => {
    await h.monter({});
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua), d = (m) => now - m * MIN;
    const a = await xDe(h, d(40)), b = await xDe(h, d(20));
    await souris(h, 'mouseMoved', a.x, a.y);
    const s = await h.ev(() => { const l = document.querySelector('[data-survol]'), df = document.querySelector('.vf-frise-defil');
      return { c: window.__vfFrise.donnees().curseurMs, ligne: !!l, stroke: l ? getComputedStyle(l).stroke : null, hair: window.__couleur('--hair-2'), titre: df.title }; });
    h.sonde('C2', 'le survol seul ne pose rien : trait de repère --hair-2 et heure en title', s.c === null && s.ligne && s.stroke === s.hair && /^\d{2}:\d{2}/.test(s.titre), JSON.stringify(s));
    await souris(h, 'mousePressed', a.x, a.y, 1); await souris(h, 'mouseReleased', a.x, a.y);
    const c1 = await curseur(h);
    h.sonde('C2', 'un clic dans les pistes pose le curseur à l\'instant cliqué', c1 !== null && Math.abs(c1 - d(40)) < 2 * a.mpp, `${c1 && Math.round((now - c1) / MIN)} min avant`);
    await souris(h, 'mousePressed', a.x, a.y, 1); await souris(h, 'mouseMoved', Math.round((a.x + b.x) / 2), a.y, 1); await souris(h, 'mouseMoved', b.x, b.y, 1); await souris(h, 'mouseReleased', b.x, b.y);
    const c2 = await curseur(h);
    h.sonde('C2', 'glisser déplace le curseur jusqu\'au relâché', c2 !== null && Math.abs(c2 - d(20)) < 2 * a.mpp, `${c2 && Math.round((now - c2) / MIN)} min avant`);
    await h.ev(() => window.__vfFrise.poserCurseur(null));
    const col = await h.ev(() => { const b = document.querySelector('.vf-frise-voies .vf-frise-cell'); b.scrollIntoView({ block: 'center' }); const r = b.getBoundingClientRect(); return { x: Math.round(r.left + r.width / 2), y: Math.round(r.top + r.height / 2) }; });
    await souris(h, 'mousePressed', col.x, col.y, 1); await souris(h, 'mouseReleased', col.x, col.y);
    const f = await h.ev(() => [window.__vfFrise.donnees().curseurMs, window.__fiche.length]);
    h.egal('C2', 'un clic sur la colonne de gauche n\'est pas un curseur : il ouvre la fiche', f, [null, 1]);
  });
}
JS

cat > "$AUX/c3.mjs" <<'JS'
import { MIN, poser, curseur } from './commun.mjs';
export const ids = ['C3'];
export default async function (h) {
  await h.section('C3', async () => {
    await h.monter({});
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await poser(h, now - 30 * MIN);
    const t = await h.ev(() => { const c = document.querySelector('.vf-frise line.vf-frise-curseur-trait'), m = document.querySelector('.vf-frise line.vf-frise-maintenant');
      return { c: !!c, attr: c ? c.hasAttribute('stroke-dasharray') : null, cs: c ? getComputedStyle(c).strokeDasharray : null, ms: m ? getComputedStyle(m).strokeDasharray : null }; });
    h.sonde('C3', 'le trait du curseur est plein (aucun stroke-dasharray) ; celui de « maintenant » est en tirets', t.c && t.attr === false && t.cs === 'none' && !!t.ms && t.ms !== 'none', JSON.stringify(t));
    await poser(h, await h.ev(() => window.__vfFrise.donnees().depuis) + 1500);
    await h.pause(2600); await h.emettre(5);
    await h.attendre(() => /Le curseur est sorti de la fenêtre/.test(document.querySelector('.vf-frise-live').textContent), 'annonce de sortie');
    h.egal('C3', 'le curseur sorti de la fenêtre par la gauche est retiré avec l\'annonce « Le curseur est sorti de la fenêtre »', await curseur(h), null);
  });
}
JS

cat > "$AUX/c4.mjs" <<'JS'
import { MIN, poser, texte } from './commun.mjs';
export const ids = ['C4'];
export default async function (h) {
  await h.section('C4', async () => {
    await h.monter({ voies: (now, F) => F.voiesParDefaut(now).map((v) => (v.id === 'wk-1' ? { ...v, etatOfficiel: 'actif' } : v)) });
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua), d = (m) => now - m * MIN;
    const etat = (id) => h.ev((i) => { const l = document.querySelector(`.vf-encart-voies [data-id="${i}"]`); return l ? l.innerText.replace(/\s+/g, ' ') : null; }, id);
    await poser(h, d(25));
    const titre = await h.ev((t) => [document.querySelector('.vf-encart-titre').textContent, window.__vfFriseModele.fmtHeure(t, { phrase: true })], d(25));
    h.egal('C4', 'titre « À cet instant, 14 h 32 » à l\'instant posé', titre[0], `À cet instant, ${titre[1]}`);
    const n = await h.ev(() => [document.querySelectorAll('.vf-encart-voies li').length, window.__vfFrise.donnees().frise.voies.length]);
    h.egal('C4', 'une ligne par voie', n[0], n[1]);
    h.egal('C4', 'à d25 : worker au travail, manager qui attend ses agents, tête au repos, worker fini terminé',
      [/au travail/.test(await etat('wk-2')), /attend ses agents/.test(await etat('mg-1')), /au repos/.test(await etat('sess-1')), /terminé/.test(await etat('wk-1'))], [true, true, true, true]);
    await poser(h, d(10));
    h.sonde('C4', 'à d10 : le worker dont la queue attend l\'humain « vous attend »', /vous attend/.test(await etat('wk-2')), await etat('wk-2'));
    h.sonde('C4', 'un instant passé ne porte jamais « · déduit »', !/déduit/.test(await texte(h, '.vf-encart-voies')), '');
    await poser(h, now - 100);
    const p = await h.ev(() => ({ sans: document.querySelector('.vf-encart-voies [data-id="mg-1"]').innerText, avec: document.querySelector('.vf-encart-voies [data-id="wk-1"]').innerText }));
    h.sonde('C4', '« · déduit » seulement pour l\'état présent d\'une voie sans etatOfficiel', /· déduit/.test(p.sans) && !/déduit/.test(p.avec), JSON.stringify(p));
    await poser(h, d(60));
    h.sonde('C4', '« pas encore lancé » avant le début d\'une voie', /pas encore lancé/.test(await etat('wk-2')), await etat('wk-2'));
  });
}
JS

cat > "$AUX/c5.mjs" <<'JS'
import { MIN, poser, texte } from './commun.mjs';
export const ids = ['C5'];
const voies = (now, F) => { const d = (m) => now - m * MIN;
  return [...F.voiesParDefaut(now),
    F.voie({ id: 'wk-3', parent: 'mg-1', depth: 2, debut: d(60), fin: now, segments: [[d(60), now, 'attend-agents']], rattachement: { dag: 'm1.md', noeud: 'n3', source: 'mandat' } }),
    F.voie({ id: 'wk-4', parent: 'mg-1', depth: 2, debut: d(60), fin: now, segments: [[d(60), now, 'repos']], role: null, rattachement: { dag: 'm1.md', noeud: 'n4', source: 'mandat' } })]; };
const ligne = (h, n) => h.ev((k) => { const l = [...document.querySelectorAll('.vf-encart-noeuds li')].find((x) => x.querySelector('.mono') && x.querySelector('.mono').textContent === k); return l ? l.innerText.replace(/\s+/g, ' ') : null; }, n);
export default async function (h) {
  await h.section('C5', async () => {
    await h.monter({ voies });
    const miss = await h.ev(() => { const n = ['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8'].map((id) => ({ id, status: 'pending', step: '', stage: '', deps: [] }));
      window.__vfS.signal.missions = [{ nom: 'Mission un', fichier: 'm1.md', phaseKey: '74', ws: null, etat: 'en-cours', libelle: 'en cours', vie: null, noeuds: n }];
      window.__emit('etat', { seq: 77, at: Date.now(), sig: 'm77' }); return true; });
    await h.attendre(() => { const s = window.VF_ETAT.lire('etat'); return !!(s && s.signal && s.signal.missions && s.signal.missions.length); }, 'missions lues');
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua), d = (m) => now - m * MIN;
    await poser(h, d(40));
    h.sonde('C5', 'un worker au travail : « porté par vf-coder, au travail »', /porté par vf-coder, au travail/.test(await ligne(h, 'n2')), await ligne(h, 'n2'));
    h.sonde('C5', 'voie qui attend ses agents : « porté par vf-coder, attend ses agents »', /porté par vf-coder, attend ses agents/.test(await ligne(h, 'n3')), await ligne(h, 'n3'));
    h.sonde('C5', 'segment repos : « porté, agent au repos »', /porté, agent au repos/.test(await ligne(h, 'n4')) && !/par/.test(await ligne(h, 'n4')), await ligne(h, 'n4'));
    const t = await texte(h);
    h.sonde('C5', 'le manager `enfants` n\'a aucune ligne ; bilan « 4 autres nœuds du plan : aucun agent »', (await h.ev(() => document.querySelectorAll('.vf-encart-noeuds li').length)) === 4 && /4 autres nœuds du plan : aucun agent/.test(t), t);
    await poser(h, d(10));
    h.sonde('C5', 'queue attend-humain : « porté par vf-coder, vous attend »', /porté par vf-coder, vous attend/.test(await ligne(h, 'n2')), await ligne(h, 'n2'));
    const t2 = await texte(h);
    h.sonde('C5', 'aucun mot ready ni blocked ; la note « déduit des voies » est présente', !/\b(ready|blocked)\b/i.test(t2) && /déduit des voies/.test(t2), t2);
    await h.ev(() => { window.__vfS.signal.missions = [{ nom: 'Mission un', fichier: 'm1.md', phaseKey: '74', ws: null, etat: 'planifiee', libelle: 'planifiée', vie: null }]; window.__emit('etat', { seq: 78, at: Date.now(), sig: 'm78' }); });
    await h.attendre(() => { const s = window.VF_ETAT.lire('etat'); return !!(s && s.signal.missions[0] && !s.signal.missions[0].noeuds); }, 'missions sans nœuds');
    await poser(h, d(10)); await poser(h, d(11));
    h.sonde('C5', 'sans `noeuds` : aucune ligne de bilan chiffrée (jamais « 0 autres »)', !/autre[s]? nœud/.test(await texte(h)), await texte(h));
  });
}
JS

cat > "$AUX/c6.mjs" <<'JS'
import { MIN, poser, texte, encartPret, fil, filFa3, fixFichiers, voyants, idsTr, nbTr, el } from './commun.mjs';
export const ids = ['C6'];
export default async function (h) {
  await h.section('C6', async () => {
    await h.monter({ voies: fixFichiers });
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua), d = (m) => now - m * MIN;
    await fil(h, 'fa-3', filFa3(now));
    await h.ev(() => { window.__tr.delai = 700; });
    await poser(h, d(30)); await h.pause(120);
    const occ = await h.ev(() => { const f = document.querySelector('.vf-encart-fichiers'); return [f.getAttribute('aria-busy'), f.innerText]; });
    h.sonde('C6', 'pendant la lecture : aria-busy true et « Lecture des fichiers »', occ[0] === 'true' && /Lecture des fichiers/.test(occ[1]), JSON.stringify(occ));
    await encartPret(h);
    h.egal('C6', 'seule la voie « incertaine » lit son fil : une requête, pour fa-3 (fa-1 certaine dans la fenêtre, fa-2 certaine avant)', await idsTr(h), ['fa-3']);
    const l = await voyants(h);
    h.egal('C6', 'liste : x1.js (table), z.js, w.js du worktree wt-a (fil) ; ni la cible coupée ni « hors du lab »', l.map((x) => x.join('@')).sort(), ['null@x1.js', 'null@z.js', 'wt-a@w.js']);
    await h.ev(() => { window.__tr.delai = 40; });
    // plus de huit fichiers
    await h.monter({ voies: (n, F) => { const dd = (m) => n - m * MIN; return [F.voie({ id: 'big', debut: dd(40), fin: dd(20), fini: true, segments: [[dd(40), dd(20), 'travail']],
      cibles: { etat: 'ok', tronque: false, ecritures: Array.from({ length: 12 }, (_, i) => F.entree(`f${String(i + 1).padStart(2, '0')}.js`, dd(30))), lectures: [] } })]; } });
    const n2 = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await poser(h, n2 - 30 * MIN); await encartPret(h);
    h.egal('C6', 'jusqu\'à 8 chemins puis « et 4 autres »', [(await voyants(h)).length, /et 4 autres/.test(await texte(h))], [8, true]);
    // « 200 ou plus »
    await h.monter({ voies: (n, F) => { const dd = (m) => n - m * MIN; return [F.voie({ id: 'trq', debut: dd(40), fin: dd(20), fini: true, segments: [[dd(40), dd(20), 'travail']],
      cibles: { etat: 'ok', tronque: true, ecritures: [F.entree('t1.js', dd(30))], lectures: [] } })]; } });
    const n3 = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await fil(h, 'trq', [el(n3 - 30 * MIN, 'tt.js')]);
    await poser(h, n3 - 30 * MIN); await encartPret(h);
    h.sonde('C6', 'cibles.tronque : « 200 ou plus » écrit', /200 ou plus/.test(await texte(h)), await texte(h));
    // vide et complet, cibles nul
    await h.monter({ voies: (n, F) => { const dd = (m) => n - m * MIN; return [F.voie({ id: 'nul', debut: dd(40), fin: dd(20), fini: true, segments: [[dd(40), dd(20), 'travail']], cibles: null })]; } });
    const n4 = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await fil(h, 'nul', []);
    await poser(h, n4 - 30 * MIN); await encartPret(h);
    h.sonde('C6', '`cibles: null` : la voie est incertaine (son fil est lu) ; fil lu et vide : « Aucun fichier écrit à cet instant. » sans bouton « Voir sur la carte »',
      (await nbTr(h)) === 1 && /Aucun fichier écrit à cet instant\./.test(await texte(h)) && (await h.ev(() => !document.querySelector('.vf-encart-carte'))), await texte(h));
    // échec
    await h.monter({ voies: fixFichiers });
    const n5 = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await fil(h, 'fa-3', filFa3(n5)); await h.ev(() => { window.__tr.echec = ['fa-3']; });
    await poser(h, n5 - 30 * MIN);
    await h.attendre(() => /Les fichiers n'ont pas pu être lus\./.test(document.querySelector('.vf-encart-fichiers').innerText), 'échec dit');
    await h.ev(() => { window.__tr.echec = []; document.querySelector('.vf-encart-fichiers button').click(); });
    await encartPret(h);
    h.sonde('C6', 'échec : message et « Réessayer » qui relance la lecture', (await voyants(h)).length === 3, JSON.stringify(await voyants(h)));
    // comptes par couple (arbre, cible)
    await h.monter({ voies: (n, F) => { const dd = (m) => n - m * MIN; return [F.voie({ id: 'cp', debut: dd(40), fin: dd(20), fini: true, segments: [[dd(40), dd(20), 'travail']],
      cibles: { etat: 'ok', tronque: false, ecritures: [F.entree('a.js', dd(30)), F.entree('a.js', dd(30), { arbre: 'wt-a' })], lectures: [] } })]; } });
    const n6 = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await poser(h, n6 - 30 * MIN); await encartPret(h);
    h.egal('C6', 'a.js du lab et a.js d\'un worktree sont deux lignes ; arbre null écrit comme le lab, jamais « inconnu »', [(await voyants(h)).length, /inconnu/i.test(await texte(h))], [2, false]);
  });
}
JS

cat > "$AUX/c6b.mjs" <<'JS'
import { MIN, poser, texte, encartPret, fil, voyants, el } from './commun.mjs';
export const ids = ['C6b'];
export default async function (h) {
  await h.section('C6b', async () => {
    await h.monter({ voies: (now, F) => { const dd = (m) => now - m * MIN;
      return [F.voie({ id: 'rt', debut: dd(40), fin: dd(20), fini: true, segments: [[dd(40), dd(20), 'travail']], cibles: { etat: 'ok', tronque: false, ecritures: [F.entree('doc (worktree x)', dd(30))], lectures: [] } }),
        F.voie({ id: 'fl', debut: dd(40), fin: dd(2), segments: [[dd(40), dd(2), 'travail']], cibles: null })]; } });
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua), d = (m) => now - m * MIN;
    await fil(h, 'fl', [el(d(30), 's.js (worktree wt-b)'), el(d(30), 'q.js (worktree wt(c))'), el(d(30), 'r.js (worktree <b>x</b>)'), el(d(30), 'c1…'), el(d(30), 'c2… (worktree wt-b)'), el(d(30), 'un fichier hors du lab'), el(d(30), 'plain.js')]);
    await poser(h, d(30)); await encartPret(h);
    const l = (await voyants(h)).map((x) => x.join('@')).sort();
    h.egal('C6b', 'route de frise : « doc (worktree x) » reste tel quel (arbre null) ; fil : suffixe en fin de chaîne lu en { arbre, cible }, parenthèses et balisage restent du texte',
      l, ['<b>x</b>@r.js', 'null@doc (worktree x)', 'null@plain.js', 'wt(c)@q.js', 'wt-b@s.js']);
    const t = await texte(h);
    h.sonde('C6b', 'deux cibles coupées (avec ou sans suffixe) : comptées à part « 2 cibles coupées », jamais cachées ni posées', /2 cibles coupées/.test(t) && !/c1/.test(await h.ev(() => document.querySelector('.vf-encart-liste').innerText)), t);
    h.sonde('C6b', 'aucun balisage créé par un nom de worktree (textContent)', await h.ev(() => !document.querySelector('.vf-encart-liste b')), '');
  });
}
JS

cat > "$AUX/c7.mjs" <<'JS'
import { MIN, K, touche, focus, poser, texte, encartPret, fil, nbTr, idsTr, el } from './commun.mjs';
export const ids = ['C7'];
const huit = (now, F) => { const d = (m) => now - m * MIN;
  return Array.from({ length: 8 }, (_, i) => (i < 4 ? F.voie({ id: `iv-${i + 1}`, debut: d(60), fin: d(15), fini: true, segments: [[d(60), d(15), 'travail']], cibles: null })
    : F.voie({ id: `iv-${i + 1}`, debut: d(60), fin: now, segments: [[d(60), now, 'travail']], cibles: null }))); };
export default async function (h) {
  await h.section('C7', async () => {
    await h.monter({ voies: huit });
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua), d = (m) => now - m * MIN;
    for (let i = 1; i <= 8; i++) await fil(h, `iv-${i}`, [el(d(30), `p${i}.js`)]);
    await h.ev(() => { window.__tr.delai = 80; });
    await poser(h, d(10)); await encartPret(h);
    await h.ev(() => { window.__tr.reqs.length = 0; window.__tr.max = 0; document.querySelector('.vf-frise [role=slider]').focus(); });
    await h.ev(() => { const s = document.querySelector('.vf-frise [role=slider]'); for (let i = 0; i < 90; i++) s.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true })); });
    h.egal('C7', 'un glissement de 90 pas en moins de 250 ms ne lit rien pendant le glissement', await nbTr(h), 0);
    await h.pause(1800);
    const n = await nbTr(h), mx = await h.ev(() => window.__tr.max);
    h.egal('C7', 'au plus SIX lectures après le relâché (huit voies incertaines) et jamais plus de DEUX en vol', [n, mx], [6, 2]);
    const t = await texte(h);
    h.sonde('C7', 'liste partielle : « 2 voies non lues », jamais une liste vide ; « Voir sur la carte » présent', /2 voies non lues/.test(t) && (await h.ev(() => document.querySelectorAll('.vf-encart-liste li').length)) === 6 && (await h.ev(() => !!document.querySelector('.vf-encart-carte'))), t);
    // second déplacement sans événement frise : zéro lecture (cache)
    await h.ev(() => { window.__tr.reqs.length = 0; }); await focus(h); await touche(h, K.gauche); await h.pause(900);
    h.egal('C7', 'un second déplacement sans événement `frise` relit zéro fil en cache (six voies lues restent en cache, deux jamais lues sont relues au plus)', (await nbTr(h)) <= 2, String(await nbTr(h)));
    // après un événement frise : cache gardé pour fin inchangée, vidé pour fin bougée
    await h.ev(() => { window.__tr.reqs.length = 0; });
    await h.emettre(31); await h.pause(1600); await focus(h); await touche(h, K.gauche); await h.pause(1400);
    const ids = await idsTr(h);
    h.sonde('C7', 'après un événement `frise` : cache GARDÉ pour iv-1 à iv-4 (fin inchangée), relues iv-5 à iv-8 (fin bougée)', ids.length > 0 && ids.every((x) => /iv-[5-8]/.test(x)), JSON.stringify(ids));
    // fil trop court, corps inconnu
    await h.monter({ voies: (nw, F) => { const dd = (m) => nw - m * MIN; const b = { debut: dd(60), fin: dd(15), fini: true, segments: [[dd(60), dd(15), 'travail']], cibles: null };
      return [F.voie({ id: 'ct-1', ...b }), F.voie({ id: 'inc-1', ...b })]; } });
    const n2 = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await fil(h, 'ct-1', [el(n2 - 10 * MIN, 'tard.js')], true);
    await poser(h, n2 - 30 * MIN); await encartPret(h);
    const t2 = await texte(h);
    h.sonde('C7', 'fil tronqué qui ne remonte pas à t − δ ET corps `inconnu` : « 2 voies non lues », jamais « Aucun fichier écrit », « Fichiers non lus », pas de bouton',
      /2 voies non lues/.test(t2) && /Fichiers non lus/.test(t2) && !/Aucun fichier/.test(t2) && (await h.ev(() => !document.querySelector('.vf-encart-carte'))), t2);
  });
}
JS

cat > "$AUX/c8.mjs" <<'JS'
import { MIN, poser, encartPret, fil, el } from './commun.mjs';
export const ids = ['C8'];
export const fix = (now, F) => { const dd = (m) => now - m * MIN, E = F.entree;
  return [F.voie({ id: 'ca-1', debut: dd(40), fin: dd(20), fini: true, segments: [[dd(40), dd(20), 'travail']], cibles: { etat: 'ok', tronque: false, lectures: [],
      ecritures: [E('r1.js', dd(30)), E('r2.js', dd(30)), E('shared.js', dd(30)), E('shared.js', dd(30), { arbre: 'wt-a' }), E('r3.js', dd(30), { arbre: 'wt-a' })] } }),
    F.voie({ id: 'ca-2', debut: dd(40), fin: dd(2), segments: [[dd(40), dd(2), 'travail']], cibles: null })]; };
export const filCa2 = (now) => { const dd = (m) => now - m * MIN;
  return [el(dd(30), 'f1.js'), el(dd(30), 'f2.js (worktree wt-a)'), el(dd(30), 'f3.js'), el(dd(30), 'un fichier hors du lab'), el(dd(30), 'cut…')]; };
export default async function (h) {
  await h.section('C8', async () => {
    await h.monter({ voies: fix });
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await fil(h, 'ca-2', filCa2(now));
    h.sonde('C8', 'chargement : aucune lecture de window.VF_MARQUES par le module avant le geste, aucune erreur', (await h.ev(() => [window.__marqLus, window.__errs.length])).join() === '0,0', JSON.stringify(await h.ev(() => [window.__marqLus, window.__errs])));
    await poser(h, now - 30 * MIN); await encartPret(h);
    const b = await h.ev(() => { const x = document.querySelector('.vf-encart-carte'); return x ? [x.getAttribute('aria-label'), x.tagName] : null; });
    h.egal('C8', '« Voir sur la carte » présent avec la liste non vide, aria-label « Voir ces 8 fichiers sur la carte »', b, ['Voir ces 8 fichiers sur la carte', 'BUTTON']);
    await h.ev(() => { window.__geste = true; document.querySelector('.vf-encart-carte').click(); });
    await h.attendre(() => window.VF_COQUILLE.onglet() === 'code' && !!window.VF_MARQUES && window.VF_MARQUES.active() === 'relecture', 'couche relecture posée sur l\'onglet Code', 20000);
    const v = await h.ev(() => ({ n: window.__voir.length, liste: (window.__voir[0] || [[]])[0], titre: (window.__voir[0] || [])[1], r1: window.VF_MARQUES.lire('f:r1.js').length, f1: window.VF_MARQUES.lire('f:f1.js').length, wt: window.VF_MARQUES.lire('f:f2.js').length, errs: window.__errs.length }));
    h.egal('C8', 'voirSurLaCarte appelée UNE fois : 8 entrées { arbre, cible } (arbre null ou worktree), titre non vide ; aucune cible hors du lab ni coupée',
      [v.n, v.liste.length, v.liste.every((x) => x.arbre === null || typeof x.arbre === 'string' && typeof x.cible === 'string'), /^Fichiers écrits vers/.test(v.titre), v.liste.some((x) => /hors du lab|…/.test(x.cible))], [1, 8, true, true, false]);
    h.egal('C8', 'les cartes des fichiers de l\'arbre principal portent la marque de la couche relecture ; ceux d\'un worktree ne marquent aucune carte du lab ; aucune erreur', [v.r1 > 0, v.f1 > 0, v.wt, v.errs], [true, true, 0, 0]);
  });
}
JS
cat > "$AUX/c8b.mjs" <<'JS'
import { MIN, K, touche, focus, poser, encartPret } from './commun.mjs';
export const ids = ['C8f'];
export default async function (h) {
  await h.section('C8f', async () => {
    await h.monter({ voies: (now, F) => [F.voie({ id: 'q', debut: now - 40 * MIN, fin: now, segments: [[now - 40 * MIN, now, 'travail']], cibles: { etat: 'ok', tronque: false, ecritures: [], lectures: [] } })] });
    await focus(h); await touche(h, K.gauche);
    const a = await h.ev(() => window.__fin);
    await touche(h, K.echap);
    h.sonde('C8f', 'finirRelecture est appelée au retrait du curseur (Échap)', (await h.ev(() => window.__fin)) > a, '');
    await poser(h, await h.ev(() => window.__vfFrise.donnees().jusqua - 5 * 60000));
    const b = await h.ev(() => window.__fin);
    await h.cycle('code'); await h.attendreFrise();
    h.sonde('C8f', 'finirRelecture est appelée au nettoyage de l\'onglet (départ vers Code)', (await h.ev(() => window.__fin)) > b, '');
  });
}
JS

cat > "$AUX/c8c.mjs" <<'JS'
import { poser, encartPret, fil } from './commun.mjs';
import { fix, filCa2 } from './c8.mjs';
export const ids = ['C8c'];
export default async function (h) {
  await h.section('C8c', async () => {
    await h.monter({ voies: fix });
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await fil(h, 'ca-2', filCa2(now)); await poser(h, now - 30 * 60000); await encartPret(h);
    await h.ev(() => { window.__vraiOnglets = window.VF_ONGLETS; window.__aller = []; window.VF_ONGLETS = { aller: (n) => { window.__aller.push(n); return Promise.resolve(); }, courant: () => 'equipe' }; window.__charger.length = 0;
      document.querySelector('.vf-encart-carte').click(); });
    await h.pause(400);
    h.egal('C8c', 'avec VF_ONGLETS : aller(\'code\') appelé UNE fois, chargerOnglet zéro fois', await h.ev(() => [window.__aller, window.__charger.length]), [['code'], 0]);
    await h.ev(() => { window.VF_ONGLETS = { aller: () => Promise.reject(new Error('Onglet inconnu.')), courant: () => 'equipe' }; window.__errs.length = 0; document.querySelector('.vf-encart-carte').click(); });
    await h.attendre(() => /L'onglet Code n'a pas pu s'ouvrir\./.test(document.querySelector('.vf-frise-live').textContent), 'annonce du rejet');
    h.egal('C8c', 'une promesse de aller rejetée n\'est pas une erreur non rattrapée : le geste dit « L\'onglet Code n\'a pas pu s\'ouvrir. »', await h.ev(() => window.__errs.filter((e) => /rejet/.test(e)).length), 0);
    await h.ev(() => { window.VF_ONGLETS = undefined; window.__charger.length = 0; document.querySelector('.vf-encart-carte').click(); });
    await h.attendre(() => window.__charger.length > 0, 'chargerOnglet appelé', 8000);
    h.egal('C8c', 'sans VF_ONGLETS : VF_COQUILLE.chargerOnglet(\'code\') est le repli', await h.ev(() => window.__charger[0]), 'code');
  });
}
JS

cat > "$AUX/c9.mjs" <<'JS'
import { MIN, K, touche, focus, poser, encartPret, fil } from './commun.mjs';
import { fix, filCa2 } from './c8.mjs';
export const ids = ['C9'];
export default async function (h) {
  await h.section('C9', async () => {
    await h.monter({ voies: fix });
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua);
    await fil(h, 'ca-2', filCa2(now)); await focus(h); await touche(h, K.gauche); await poser(h, now - 30 * MIN); await encartPret(h);
    await touche(h, K.echap);
    const s = await h.ev(() => ({ ss: JSON.stringify(Object.entries(sessionStorage)), ls: JSON.stringify(Object.entries(localStorage)),
      nonGet: window.__urls.filter((u) => u[1] !== 'GET').map((u) => u[0]), doing: window.__urls.filter((u) => /\/api\/vf\/doing/.test(u[0])).length }));
    h.sonde('C9', 'aucun chemin de fichier en sessionStorage ni localStorage', !/r1\.js|f1\.js|shared\.js|\.js/.test(s.ss + s.ls), s.ss.slice(0, 200));
    h.egal('C9', 'aucune requête autre que GET ; aucun /api/vf/doing', [s.nonGet, s.doing], [[], 0]);
  });
}
JS

cat > "$AUX/c11.mjs" <<'JS'
import { MIN, curseur, xDe } from './commun.mjs';
export const ids = ['C11'];
export default async function (h) {
  await h.section('C11', async () => {
    await h.monter({ largeur: 390, hauteur: 800, coarse: true });
    const r = await h.ev(() => { const s = document.querySelector('.vf-frise [role=slider]'), b = s.getBoundingClientRect(); return { w: b.width, h: b.height, ta: getComputedStyle(s).touchAction }; });
    h.egal('C11', 'repère 44 × 44 en pointer: coarse, touch-action: none', [r.w, r.h, r.ta], [44, 44, 'none']);
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua);
    const p = await xDe(h, now - 30 * MIN), vis = await h.ev(() => { const d = document.querySelector('.vf-frise-defil').getBoundingClientRect(); return d.right; });
    const x = Math.min(p.x, Math.round(vis) - 30);
    await h.s.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y: p.y }] });
    await h.s.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: x - 90, y: p.y }] });
    await h.s.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    h.egal('C11', 'un glissement dans le conteneur ne pose pas le curseur', await curseur(h), null);
    await h.s.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y: p.y }] });
    await h.s.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    h.sonde('C11', 'un toucher dans les pistes pose le curseur', (await curseur(h)) !== null, String(await curseur(h)));
  });
}
JS

cat > "$AUX/c12.mjs" <<'JS'
import { MIN, poser, texte } from './commun.mjs';
export const ids = ['C12'];
export default async function (h) {
  await h.section('C12', async () => {
    await h.monter({});
    const mes = () => h.ev(() => ({ sliders: document.querySelectorAll('.vf-frise [role=slider]').length, kd: window.__kdC.length, curseur: window.__vfFrise.donnees().curseurMs,
      att: window.__vfFriseFichiers ? window.__vfFriseFichiers.enAttente() : -1, fin: window.__fin, tr: window.__tr.reqs.length, abo: window.VF_ETAT.abonnes().frise }));
    const now = await h.ev(() => window.__vfFrise.donnees().jusqua);
    const base = await mes();
    h.egal('C12', 'témoin : un repère, un écouteur Échap, un abonnement `frise`', [base.sliders, base.kd, base.abo], [1, 1, 1]);
    await poser(h, now - 30 * MIN);
    await h.cycle('code'); await h.attendreFrise(); await h.cycle('code'); await h.attendreFrise();
    await h.pause(700);
    const m = await mes(), t = await texte(h);
    h.egal('C12', 'après Code → Équipe → Code → Équipe : un seul repère, un seul écouteur clavier, un seul abonnement, aucune minuterie en attente, curseur absent', [m.sliders, m.kd, m.abo, m.att, m.curseur], [1, 1, 1, 0, null]);
    h.sonde('C12', 'l\'encart est revenu à son message d\'aide ; aucune lecture de fil sans pose de curseur', /Posez le curseur/.test(t) && m.tr === 0, `${t} / ${m.tr}`);
    const s = await h.ev(() => window.__surOnglet.filter((x) => x.source));
    const cles = new Set(s.map((x) => x.cle));
    h.sonde('C12', 'quatre modules inscrits, chacun avec une clé égale à son nom de fichier (extension comprise)', cles.size === 4 && s.every((x) => x.source === x.cle) && ['curseur', 'encart', 'fichiers', 'carte'].every((n) => cles.has(`74-vf-frise-${n}.js`)), JSON.stringify([...cles]));
    h.sonde('C12', 'finirRelecture appelée à chaque départ de l\'onglet Équipe (deux)', m.fin >= 2, String(m.fin));
  });
}
JS

# ---------- lancement ----------
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$LAB/.planning/STATE.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q -b main && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
demarrer() { COCKPIT_LOG="$WORK/serve-$1.out" cockpit_lancer "$LAB" HOME="$WORK/home" || true; }

joue() {
  local f="$1" port="$2" out line id lib ok ob; shift 2
  if [ -n "${SEUL:-}" ]; then case " $SEUL " in *" $f "*) ;; *) return ;; esac; fi   # SEUL="c1 c7" : mise au point
  out="$("$NODE" "$HERE_T/chrome-frise.mjs" "$CHROME" "$AUX/$f.mjs" "http://127.0.0.1:$port" 2>&1 | tail -1)"
  line="$("$NODE" -e 'let j; try { j = JSON.parse(process.argv[1]); } catch { process.exit(3); }
    if (!j.sondes) { console.log("ERR\t" + (j.erreur || "sortie illisible")); process.exit(0); }
    for (const s of j.sondes) console.log([s.ok ? "OK" : "KO", s.id, s.lib, s.obtenu].join("\t"));' "$out" 2>/dev/null)"
  if [ -z "$line" ] || [ "${line%%$'\t'*}" = ERR ]; then
    for id in "$@"; do echo "  ❌ FAIL — $id — scénario $f interrompu"; echo "     obtenu:  [${line:-${out:0:200}}]"; FAIL=$((FAIL+1)); done
    return
  fi
  while IFS=$'\t' read -r ok id lib ob; do
    if [ "$ok" = OK ]; then echo "  ✅ PASS — $id — $lib"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — $id — $lib"; echo "     obtenu:  [$ob]"; FAIL=$((FAIL+1)); fi
  done <<EOF
$line
EOF
}

echo "=== C0 — les scénarios se lisent ==="
bad=""; for f in "$AUX"/*.mjs; do "$NODE" --check "$f" 2>/dev/null || bad="$bad $(basename "$f")"; done
assert_eq "C0 — chaque scénario passe node --check" "${bad:-aucun}" "aucun"

# ---------- C10 : forme du code (statique) ----------
MODS="74-vf-frise-curseur.js 74-vf-frise-encart.js 74-vf-frise-fichiers.js 74-vf-frise-carte.js"
statique() { # <dossier ui> : une ligne par écart
  local d="$1" f p
  for f in $MODS; do p="$d/$f"; [ -s "$p" ] || { echo "$f : module absent ou vide"; continue; }
    "$NODE" "$HERE_T/css-jetons.mjs" "$p" 2>&1 | sed "s#^#css-jetons #"
    grep -nE 'fetch\(|EventSource|innerHTML|\bready\b|\bblocked\b|VF_FLUX|—|showBoard' "$p" | sed "s#^#$f : interdit #"
    head -5 "$p" | grep -q 'vf-coquille: persistant' && echo "$f : marqué persistant"
    [ "$(awk 'END { print NR }' "$p")" -le 299 ] || echo "$f : plus de 299 lignes"
    python3 -I -c 'import sys; sys.exit(any(len(l.rstrip("\n"))>160 for l in open(sys.argv[1],encoding="utf-8")))' "$p" || echo "$f : ligne de plus de 160 colonnes"
    grep -nE "font-size: *[0-9.]+px" "$p" | grep -vE "font-size: *(11\.5|12\.5|13|15|20)px" | sed "s#^#$f : taille hors échelle #"
    grep -nE '^[^/]*VF_MARQUES' "$p" | grep -vE '^[0-9]+:\s*(//|\*)' | grep -vE 'W\.VF_MARQUES|window\.VF_MARQUES' | sed "s#^#$f : canal lu hors d'un corps #"
  done
  grep -n 'showBoard' "$d"/74-vf-frise-*.js 2>/dev/null | sed "s#^#showBoard #"
}
echo "=== C10 — forme du code (jetons, aucun réseau direct, ≤ 299 lignes, ≤ 160 colonnes) ==="
ECARTS="$(statique "$UI")"
assert_eq "C10 — quatre modules : jetons, aucun réseau direct, ni statut de DAG, ni showBoard, ≤ 299 lignes, ≤ 160 colonnes, aucun persistant" "${ECARTS:-aucun écart}" "aucun écart"

if [ -z "$CHROME" ]; then
  skip "C1 à C9, C11, C12" "pas de navigateur"
else
  demarrer base; PORT="$VF_PORT"; SRV="$VF_PID"
  assert_eq "C0 — contrôle positif : serveur de la suite démarré, page Équipe servie" "$([ "$PORT" -gt 0 ] && echo serveur)" "serveur"
  echo "=== C1 — repère et clavier ==="; joue c1 "$PORT" C1
  echo "=== C2 — pointeur ==="; joue c2 "$PORT" C2
  echo "=== C3 — trait et sortie de fenêtre ==="; joue c3 "$PORT" C3
  echo "=== C4 — voies ==="; joue c4 "$PORT" C4
  echo "=== C5 — nœuds portés ==="; joue c5 "$PORT" C5
  echo "=== C6 — fichiers à t ==="; joue c6 "$PORT" C6
  echo "=== C6b — suffixe et cibles coupées ==="; joue c6b "$PORT" C6b
  echo "=== C7 — plafond de lectures ==="; joue c7 "$PORT" C7
  echo "=== C8 — Voir sur la carte ==="; joue c8 "$PORT" C8
  echo "=== C8f — finirRelecture ==="; joue c8b "$PORT" C8f
  echo "=== C8c — routage d'onglet ==="; joue c8c "$PORT" C8c
  echo "=== C9 — aucune persistance ==="; joue c9 "$PORT" C9
  echo "=== C11 — tactile ==="; joue c11 "$PORT" C11
  echo "=== C12 — cycle de vie ==="; joue c12 "$PORT" C12
  cockpit_arreter "$SRV"; SRV=""
fi

echo
echo "durée : $(( $(date +%s) - T0 )) s"
echo "Résultat : $PASS réussis, $FAIL échecs, $SKIP sautés"
[ "$FAIL" -eq 0 ]
