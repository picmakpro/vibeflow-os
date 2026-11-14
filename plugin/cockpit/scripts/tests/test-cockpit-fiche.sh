#!/usr/bin/env bash
# test-cockpit-fiche.sh : la fiche d'agent plein cadre de l'onglet Équipe, sous Chrome (Phase 74, plan 74-05 ; TEMP-06, TEMP-07, TEMP-08 côté vue, TEMP-12 part forme).
# Les routes de frise, de transcript et d'état sont REMPLACÉES dans la page par un `fetch` de test (VF_PRE) qui sert les fixtures et tient le journal des requêtes ;
# la page, le serveur, le flux (enveloppe AMORCE_FLUX), la régie de la 73 et le magasin VF_ETAT sont les vrais. La pile de surcouches de la 80 est SIMULÉE par un
# écouteur factice en capture sur window (preventDefault puis stopPropagation, le geste de la 80) : la suite n'en dépend pas.
#   P1 ouverture  P2 session et sous-agent  P3 faits (a à f)  P4 rattachement  P5 fil (a états, b fusion, c corps inconnu)  P6 direct  P7 bornes  P8 fermeture et Échap
#   P9 lien du parent  P10 deux colonnes  P11 aucune fuite  P12 forme du code (statique)  P13 mouvement, contrastes, focus  P14 donnée hostile
#   P15 cycle de vie  P16 vf-agent:lu  P17 les trois déclencheurs de la régie  P18 aller-retour d'onglet  P19 clic sur la bascule fiche ouverte
# Plan 74-05 non marqué audit : le régime allégé de la session principale (2026-11-13) ne demande aucun mutant ; la suite n'en joue pas.
# Chrome headless en CDP (SAUTÉ, jamais compté réussi, sans navigateur). Exit 0 si tout passe, 1 sinon.

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
[ -n "${FICHE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES)}"
NODE="$(command -v node)"
export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-30000}"

# ---------- crochets de page (VF_PRE) : routes remplacées, journaux, espions ----------
cat > "$AUX/pre.js" <<'JS'
window.__errs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
window.__couleur = (x) => { const p = document.createElement('i'); p.style.color = x.startsWith('--') ? 'var(' + x + ')' : x; document.body.appendChild(p);
  const c = getComputedStyle(p).color; p.remove(); return c; };
window.__xss = 0; window.__req = []; window.__meth = []; window.__acces = []; window.__tm = new Set(); window.__fl = []; window.__surOnglet = [];
window.__vfF = { reponse: null, statut: 200, delai: 0 };
window.__vfT = { parId: {}, statut: 200, delai: 0 };
window.__vfS = { signal: { missions: [{ nom: 'MISSION-74', fichier: 'm1.md', phaseKey: '74', ws: null, etat: 'en-cours', libelle: 'en cours', vie: null }],
  phases: [{ key: '74', n: 74, ws: null, nom: "L'équipe dans le temps", fait: false }] } };
const SCHEMA = 'vibeflow/cockpit-transcript@2';
{ const f0 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url, m = (i && i.method) || 'GET';
    if (/^\/api\/vf\//.test(url)) { window.__req.push(url); window.__meth.push(m); }
    const rep = (corps, statut, delai) => new Promise((ok) => setTimeout(() => ok(new Response(JSON.stringify(corps), { status: statut, headers: { 'content-type': 'application/json' } })), delai || 0));
    if (/^\/api\/vf\/frise(\?|$)/.test(url)) {
      const F = window.__vfF, q = new URLSearchParams(url.split('?')[1] || ''), c = F.reponse ? JSON.parse(JSON.stringify(F.reponse)) : {};
      c.at = new Date().toISOString();
      if (q.get('jusqua') && c.voies) { const J0 = c.jusqua, J = Number(q.get('jusqua'));
        for (const v of c.voies) { if (v.fin === J0) v.fin = J; for (const s of v.segments || []) if (s[1] === J0) s[1] = J; }
        c.depuis = Number(q.get('depuis')); c.jusqua = J; }
      return rep(F.statut === 200 ? c : { erreur: F.statut === 400 ? 'bornes-invalides' : 'indisponible' }, F.statut, F.delai); }
    if (/^\/api\/vf\/transcript\?/.test(url)) {
      const T = window.__vfT, id = new URLSearchParams(url.split('?')[1]).get('id'), c = T.parId[id];
      if (T.statut !== 200) return rep({ erreur: 'indisponible' }, T.statut, T.delai);
      return c ? rep(JSON.parse(JSON.stringify(c)), 200, T.delai) : rep({ schema: SCHEMA, id, erreur: 'inconnu' }, 200, T.delai); }
    if (/^\/api\/vf\/state$/.test(url)) return rep({ schema: 'vibeflow/cockpit-state@1', at: new Date().toISOString(), seq: 1,
      collecte: { etat: 'ok', derniereA: null, mode: 'watch', dureeMs: 0, clients: 1 }, signal: window.__vfS.signal }, 200, 0);
    return f0(u, i); }; }
// espions : ce que le module de la fiche (74-vf-fiche.js) pose, repéré par la pile d'appel
const DELAFICHE = () => /74-vf-fiche\.js/.test(String(new Error().stack));
{ const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener, cap = (o) => !!(o === true || (o && o.capture));
  EventTarget.prototype.addEventListener = function (t, f, o) {
    if ((t === 'keydown' || t === 'vf-agent:ouvrir') && DELAFICHE() && !window.__fl.some((x) => x.c === this && x.t === t && x.f === f && x.cap === cap(o))) window.__fl.push({ c: this, t, f, cap: cap(o) });
    return A.call(this, t, f, o); };
  EventTarget.prototype.removeEventListener = function (t, f, o) { window.__fl = window.__fl.filter((x) => !(x.c === this && x.t === t && x.f === f && x.cap === cap(o))); return R.call(this, t, f, o); };
  window.__nfl = (t) => window.__fl.filter((x) => x.t === t && (x.c === window || x.c === document || x.c.isConnected)).length; }
for (const k of ['VF_SURCOUCHES', 'VF_PANNEAU']) { let v; Object.defineProperty(window, k, { configurable: true, get() { if (/74-vf-fiche/.test(String(new Error().stack))) window.__acces.push(k); return v; }, set(x) { v = x; } }); }
{ const ST = window.setTimeout, CT = window.clearTimeout, SI = window.setInterval, CI = window.clearInterval;
  window.setTimeout = function (f, ...a) { const own = DELAFICHE(); const id = ST.call(window, own && typeof f === 'function' ? function (...b) { window.__tm.delete(id); return f.apply(this, b); } : f, ...a); if (own) window.__tm.add(id); return id; };
  window.setInterval = function (f, ...a) { const own = DELAFICHE(); const id = SI.call(window, f, ...a); if (own) window.__tm.add(id); return id; };
  window.clearTimeout = function (id) { window.__tm.delete(id); return CT.call(window, id); };
  window.clearInterval = function (id) { window.__tm.delete(id); return CI.call(window, id); }; }
{ let c; Object.defineProperty(window, 'VF_COQUILLE', { configurable: true, get: () => c,
  set: (x) => { c = x && typeof x.surOnglet === 'function' ? Object.freeze(Object.assign({}, x, { surOnglet: (r, o) => {
    window.__surOnglet.push({ cle: o && o.cle, fiche: DELAFICHE() }); return x.surOnglet(r, o); } })) : x; } }); }
// la pile de surcouches de la 80, simulée : sur Échap, preventDefault puis stopPropagation, en capture sur window ; inerte tant qu'on ne l'arme pas
window.__pris = 0; window.__pileActive = false;
window.__poserPile = (actif) => { if (!window.__pile) { window.__pile = (e) => { if (window.__pileActive && e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); window.__pris++; } };
  addEventListener('keydown', window.__pile, true); } window.__pileActive = !!actif; };
JS
export VF_PRE="$AUX/pre.js"

# ---------- fixtures partagées par les scénarios ----------
cat > "$AUX/fix.mjs" <<'JS'
export const NB = ' ';
const SCH = 'vibeflow/cockpit-transcript@2';
export const iso = (now, m) => new Date(now - m * 60000).toISOString();
export const msg = (now, m, texte) => ({ t: iso(now, m), genre: 'message', texte });
export const outil = (now, m, o = {}) => ({ t: iso(now, m), genre: 'outil', outil: 'Edit', verbe: 'modifie', cible: 'a.js', ...o });
export const corps = (id, fil, o = {}) => ({ schema: SCH, id, fil, tronque: false, mandat: null, ...o });
export const lignes = (now, nb, genre = 'outil', debut = 200) => Array.from({ length: nb }, (_, i) => (genre === 'outil'
  ? outil(now, debut - i * 0.2, { cible: `f${i}.js` }) : msg(now, debut - i * 0.2, `message ${i}`)));
export const entrees = (n, arbre = null) => Array.from({ length: n }, (_, i) => ({ arbre, cible: `src/f${i}.js`, n: 1, dernierMs: 1 }));
// la frise : une tête, un manager `enfants`, un worker terminé et rattaché, un actif rattaché, deux actifs non rattachés
export const voies = (now, F, sur = {}) => {
  const d = (m) => now - m * F.MIN, e = (c, a = null) => F.entree(c, d(60), { arbre: a });
  const base = [
    F.voie({ id: 'sess-1', kind: 'session', role: null, depth: null, debut: d(300), fin: now, segments: [[d(300), d(280), 'travail'], [d(280), now, 'repos']],
      durees: { travailS: 1200, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 } }),
    F.voie({ id: 'mg-1', parent: 'sess-1', role: 'vf-dev-manager', dispatchA: d(250), debut: d(250), fin: now, segments: [[d(250), now, 'attend-agents']],
      rattachement: { dag: 'm1.md', noeud: null, source: 'enfants' } }),
    F.voie({ id: 'wk-1', parent: 'mg-1', depth: 2, role: 'vf-coder', dispatchA: d(200), debut: d(200), fin: d(21), fini: true, etatOfficiel: 'termine', dureeS: 363600,
      segments: [[d(200), d(100), 'travail'], [d(90), d(56), 'travail']],
      durees: { travailS: 8040, attenteHumainS: 1080, attenteAgentsS: 0, reposS: 0, silenceS: 0 },
      jetons: { entree: 12400, sortie: 3400, cacheLu: 150000, cacheCree: 2200, contexteMax: 200000, contexteDernier: 168000 },
      compteurs: { appels: 214, erreurs: 6, refus: 0, questions: 0, compactions: 3, tours: 40, reponsesApi: 40 },
      rattachement: { dag: 'm1.md', noeud: 'exec-lot-a', source: 'registre' },
      cibles: { etat: 'ok', tronque: false, ecritures: [e('src/a.js'), e('src/a.js', 'wt-a'), e('src/b.js')], lectures: [e('x.md')] } }),
    F.voie({ id: 'wk-2', parent: 'mg-1', depth: 2, role: 'vf-coder', arbre: 'wt-b', dispatchA: d(50), debut: d(50), fin: now, segments: [[d(50), now, 'travail']],
      durees: { travailS: 3000, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 }, rattachement: { dag: 'm1.md', noeud: 'n2', source: 'mandat' } }),
    F.voie({ id: 'wk-3', parent: 'mg-1', depth: 2, role: 'vf-reviewer', dispatchA: d(40), debut: d(40), fin: now, segments: [[d(40), now, 'travail']] }),
    F.voie({ id: 'wk-4', parent: 'mg-1', depth: 2, role: 'vf-auditer', dispatchA: d(30), debut: d(30), fin: now, segments: [[d(30), now, 'travail']] }),
  ];
  return base.map((v) => (sur[v.id] ? { ...v, ...sur[v.id] } : v));
};
export const WHO = [
  { id: 'sess-1', kind: 'session', etat: 'au-repos', titre: 'Session principale', branch: 'feat/x', tree: '.', ageS: 300 },
  { id: 'mg-1', kind: 'subagent', role: 'vf-dev-manager', task: 'Piloter la phase 74', parent: 'sess-1', etat: 'actif', ageS: 10, branch: 'feat/x', tree: '.',
    rattachement: { etat: 'rattache', source: 'enfants', dag: 'm1.md', noeud: null } },
  { id: 'wk-1', kind: 'subagent', role: 'vf-coder', task: 'Écrire la fiche', parent: 'mg-1', etat: 'termine', ageS: 1800, branch: 'feat/x', tree: '.',
    rattachement: { etat: 'rattache', source: 'registre', dag: 'm1.md', noeud: 'exec-lot-a' } },
  { id: 'wk-2', kind: 'subagent', role: 'vf-coder', task: 'Rédiger les faits', parent: 'mg-1', etat: 'actif', ageS: 20, branch: 'feat/x', tree: '.',
    rattachement: { etat: 'rattache', source: 'mandat', dag: 'm1.md', noeud: 'n2' } },
  { id: 'wk-3', kind: 'subagent', role: 'vf-reviewer', task: 'Relire le diff', parent: 'mg-1', etat: 'actif', ageS: 20, branch: 'feat/x', tree: '.',
    rattachement: { etat: 'non-rattache', raison: 'ambigu' } },
  { id: 'wk-4', kind: 'subagent', role: 'vf-auditer', task: 'Auditer', parent: 'mg-1', etat: 'actif', ageS: 20, branch: 'feat/x', tree: '.',
    rattachement: { etat: 'non-rattache', raison: 'inconnu' } },
];
// lecture de la fiche dans la page : paires libellé -> valeur de la colonne des faits (six chiffres et listes de définitions)
export const FAITS = () => {
  const f = document.querySelector('.vf-fiche'), t = (e) => e.textContent.replace(/\s/g, ' ').trim(), m = {}, ordre = [];
  if (!f) return null;
  for (const c of f.querySelectorAll('.vf-fiche-chiffre')) { const l = t(c.querySelector('.vf-fiche-lib')); ordre.push(l); m[l] = t(c.querySelector('.vf-fiche-val')); }
  for (const dt of f.querySelectorAll('.vf-fiche-faits dt')) m[t(dt)] = t(dt.nextElementSibling);
  return { m, ordre, texte: t(f.querySelector('.vf-fiche-faits') || f) };
};
JS

# ---------- scénarios (une instance de Chrome par groupe de sections) ----------
cat > "$AUX/s1.mjs" <<'JS'
import { voies, WHO, corps, msg, FAITS } from './fix.mjs';
export const ids = ['P1', 'P2', 'P4', 'P9'];
const fil = (now) => ({ 'wk-2': corps('wk-2', [msg(now, 5, 'bonjour')], { mandat: 'MANDAT-SECRET-74 : fais X' }), 'sess-1': corps('sess-1', [msg(now, 5, 'salut')]),
  'wk-1': corps('wk-1', [msg(now, 5, 'fini')]), 'mg-1': corps('mg-1', [msg(now, 5, 'gère')]) });
const ORIGINE = (id) => `#vf-equipe li[data-vf-agent="${id}"] .vf-rg-tog`;
export default async function (h) {
  await h.monter({ voies, who: WHO, fil });
  await h.section('P1', async () => {
    const av = await h.ev(() => { const v = document.querySelector('.vf-vue:not([hidden])'), r = v.getBoundingClientRect();
      return { vue: [r.left, r.top, r.width].map(Math.round), panel: document.getElementById('panel').outerHTML, href: location.href,
        fp: Object.keys(window.Floorplan || {}).sort().join(), vb: Object.keys(window.VibeFlow || {}).sort().join() }; });
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    const ap = await h.ev(() => { const f = document.querySelector('.vf-fiche'), r = f.getBoundingClientRect(), a = document.activeElement;
      const regs = [...document.querySelectorAll('[role=region][aria-label^="Fiche de "]')];
      return { n: regs.length, nom: regs[0] && regs[0].getAttribute('aria-label'), foc: a && [a.tagName, a.getAttribute('tabindex'), a.textContent],
        rect: [r.left, r.top, r.width].map(Math.round), panel: document.getElementById('panel').outerHTML, href: location.href,
        fp: Object.keys(window.Floorplan || {}).sort().join(), vb: Object.keys(window.VibeFlow || {}).sort().join() }; });
    h.egal('P1', 'ouverture : une région « Fiche de Rédiger les faits », le focus sur le titre (H2, tabindex -1)', [ap.n, ap.nom, ap.foc], [1, 'Fiche de Rédiger les faits', ['H2', '-1', 'Rédiger les faits']]);
    h.egal('P1.a', 'la fiche occupe la zone de contenu : même gauche, même haut, même largeur que la vue d\'origine', ap.rect, av.vue);
    h.sonde('P1.b', '#panel inchangé (hors page) et aucune adresse dans l\'URL', ap.panel === av.panel && ap.href === av.href, ap.href);
    h.sonde('P1.c', 'aucune propriété neuve sur window.Floorplan ni window.VibeFlow', ap.fp === av.fp && ap.vb === av.vb, '');
  });
  await h.section('P2', async () => {
    await h.fermer(); await h.ouvrir('sess-1');
    const s = await h.ev(() => { const f = document.querySelector('.vf-fiche');
      return { mandat: !!f.querySelector('.vf-fiche-mandat'), mot: /Mandat/.test(f.innerText), regs: [...f.querySelectorAll('[role=region]')].map((r) => r.getAttribute('aria-label')) }; });
    await h.fermer(); await h.ouvrir('wk-2');
    const a = await h.ev(() => { const f = document.querySelector('.vf-fiche'), b = f.querySelector('.vf-fiche-mandat');
      return { b: b && [b.textContent, b.getAttribute('aria-expanded')], secret: /MANDAT-SECRET-74/.test(f.innerText), regs: [...f.querySelectorAll('[role=region]')].map((r) => r.getAttribute('aria-label')) }; });
    await h.ev(() => document.querySelector('.vf-fiche-mandat').click());
    const o = await h.ev(() => { const f = document.querySelector('.vf-fiche'), b = f.querySelector('.vf-fiche-mandat');
      return [b.textContent, b.getAttribute('aria-expanded'), /MANDAT-SECRET-74/.test(f.innerText)]; });
    h.egal('P2', 'session : ni bouton ni ligne « Mandat » ; sous-agent : « Afficher le mandat » replié, contenu absent', [s.mandat, s.mot, a.b, a.secret], [false, false, ['Afficher le mandat', 'false'], false]);
    h.egal('P2.a', 'déplié : « Replier le mandat », aria-expanded vrai, contenu lu', o, ['Replier le mandat', 'true', true]);
    h.egal('P2.b', 'même fiche : deux régions, « Faits de … » puis « Fil de … », pour la session comme pour le sous-agent',
      [s.regs, a.regs], [['Faits de Session principale', 'Fil de Session principale'], ['Faits de Rédiger les faits', 'Fil de Rédiger les faits']]);
  });
  await h.section('P4', async () => {
    const lire = async (id) => { await h.fermer().catch(() => {}); await h.ouvrir(id);
      return h.ev(() => { const r = document.querySelector('.vf-fiche-ratt'), t = r.textContent.replace(/\s/g, ' ').replace(/ +/g, ' ').trim();
        return { t, liens: [...r.querySelectorAll('a')].map((a) => a.getAttribute('href')), boutons: [...r.querySelectorAll('button')].map((b) => b.textContent) }; }); };
    const u = function (x) { return 'project.html#r=' + encodeURIComponent(x); };
    const w1 = await lire('wk-1'), mg = await lire('mg-1'), w3 = await lire('wk-3'), w4 = await lire('wk-4'), se = await lire('sess-1');
    h.egal('P4', 'worker rattaché : « Worker de vf-dev-manager · nœud exec-lot-a · Phase 74 », trois liens (fiche du parent, nœud, phase)',
      [w1.t, w1.boutons, w1.liens], ['Worker de vf-dev-manager · nœud exec-lot-a · Phase 74', ['vf-dev-manager'], [u('f:m1.md#exec-lot-a'), u('n:ph-74')]]);
    h.egal('P4.a', 'manager `enfants` : « rattaché par ses agents » (lien vers la carte de mission), aucun id de nœud', [mg.t, mg.liens.includes(u('n:dag-MISSION-74')), /nœud/.test(mg.t)],
      ['Manager · rattaché par ses agents · Phase 74', true, false]);
    h.egal('P4.b', 'ambigu et non lié : les deux phrases, aucun lien deviné', [w3.t, w3.liens, w4.t, w4.liens],
      ['Worker de vf-dev-manager · Non rattaché (ambigu)', [], 'Worker de vf-dev-manager · Pas lié à une phase du projet', []]);
    h.egal('P4.c', 'session : « Session · arbre principal · branche feat/x », arbre nul dit « arbre principal », aucun lien', [se.t, se.liens, se.boutons], ['Session · arbre principal · branche feat/x', [], []]);
  });
  await h.section('P9', async () => {
    await h.fermer().catch(() => {});
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    await h.ev(() => document.querySelector('.vf-fiche-ratt button').click());
    await h.fiche();
    const p = await h.ev(() => { const a = document.activeElement; return { n: document.querySelectorAll('.vf-fiche').length, nom: document.querySelector('.vf-fiche').getAttribute('aria-label'),
      foc: a && a.tagName + ':' + a.textContent }; });
    await h.fermer();
    const r = await h.ev((sel) => ({ ferme: !document.querySelector('.vf-fiche'), foc: document.activeElement === document.querySelector(sel), vue: !document.querySelector('.vf-vue[data-vf-vue="regie"]').hidden }), ORIGINE('wk-2'));
    h.egal('P9', 'le lien du parent REMPLACE la vue par la fiche du parent, le focus va au titre', [p.n, p.nom, p.foc], [1, 'Fiche de Piloter la phase 74', 'H2:Piloter la phase 74']);
    h.egal('P9.a', '« Retour » ramène à la vue d\'origine (pas à la fiche précédente), le focus à l\'élément d\'origine de la première ouverture', r, { ferme: true, foc: true, vue: true });
  });
}
JS
cat > "$AUX/s3.mjs" <<'JS'
import { voies, WHO, corps, msg, FAITS, entrees, NB } from './fix.mjs';
export const ids = ['P3'];
export default async function (h) {
  const sur = (o) => ({ voies: (now, F) => voies(now, F, o) });
  const faits = async (id = 'wk-1') => { await h.fermer().catch(() => {}); await h.ouvrir(id); return h.ev(FAITS); };
  await h.monter({ voies, who: WHO, fil: (now) => ({ 'wk-1': corps('wk-1', [msg(now, 5, 'x')]) }) });
  await h.section('P3', async () => {
    const f = await faits(), fm = await h.ev(() => ({ duree: window.__vfFriseModele.fmtDuree(8040).replace(/\s/g, ' '), jet: window.__vfFriseModele.fmtJetons(168000).replace(/\s/g, ' ') }));
    const ordre = ['Au travail', 'À vous attendre', 'Contexte au dernier tour', 'Compactions', "Appels d'outil", 'En échec'];
    h.egal('P3', 'six chiffres dans l\'ordre ; « Au travail » = somme des segments (2 h 14), jamais la durée de 101 h ; contexte en jetons, jamais « % »',
      [f.ordre, f.m['Au travail'], f.m['Contexte au dernier tour'], /%|101/.test(f.texte)], [ordre, fm.duree, `${fm.jet} jetons`, false]);
    h.egal('P3.a', 'compteurs : compactions 3, appels 214, en échec 6 ; sous-titre « Sur les dernières 24 h »',
      [f.m.Compactions, f.m["Appels d'outil"], f.m['En échec'], /Sur les dernières 24 h/.test(f.texte)], ['3', '214', '6', true]);
    const reqs = await h.ev(() => window.__req.filter((u) => u.includes('/api/vf/frise?depuis=')).map((u) => { const q = new URLSearchParams(u.split('?')[1]); return Number(q.get('jusqua')) - Number(q.get('depuis')); }));
    h.sonde('P3.f', 'la fiche lit la frise sur 24 h exactement, quelle que soit la fenêtre de la frise', reqs.length > 0 && reqs.every((x) => x === 86400000), JSON.stringify(reqs));
  });
  await h.section('P3', async () => {
    await h.poser(sur({ 'wk-1': { durees: { travailS: null, attenteHumainS: null, attenteAgentsS: null, reposS: null, silenceS: null },
      jetons: { entree: null, sortie: null, cacheLu: null, cacheCree: null, contexteMax: null, contexteDernier: null },
      compteurs: { appels: null, erreurs: null, refus: null, questions: null, compactions: null, tours: null, reponsesApi: null }, modeles: [] } }));
    const f = await faits();
    const vals = ['Au travail', 'À vous attendre', 'Contexte au dernier tour', 'Compactions', "Appels d'outil", 'En échec', 'Entrée', 'Sortie', 'Cache lu', 'Cache écrit', 'Modèle'].map((k) => f.m[k]);
    h.egal('P3.g', 'champ absent : « inconnu » partout, jamais « 0 », « n/a » ni un tiret', [vals.every((v) => v === 'inconnu'), vals.some((v) => ['0', 'n/a', '-', '–'].includes(v))], [true, false]);
    await h.poser(sur({ 'wk-1': { cibles: { etat: 'en-construction', tronque: false, ecritures: [], lectures: [] } } }));
    const c = await faits();
    h.egal('P3.h', 'cibles.etat « en-construction » : « en cours de lecture » (ni zéro ni inconnu)', [c.m['Écrits'], c.m['Lus']], ['en cours de lecture', 'en cours de lecture']);
  });
  await h.section('P3', async () => {
    const e = (n) => entrees(n);
    const mix = [{ arbre: null, cible: 'src/a.js', n: 1, dernierMs: 1 }, { arbre: 'wt-a', cible: 'src/a.js', n: 1, dernierMs: 1 }];
    await h.poser(sur({ 'wk-1': { cibles: { etat: 'ok', tronque: false, ecritures: mix, lectures: [] }, arbre: null } }));
    const b = await faits();
    await h.poser(sur({ 'wk-1': { cibles: null } }));
    const n = await faits();
    h.egal('P3.b', 'fichiers par couple (arbre, cible) : deux écritures de même chemin dans deux arbres comptent pour DEUX ; arbre nul = « arbre principal » ; cibles nul = « inconnu »',
      [b.m['Écrits'], b.m.Arbre, n.m['Écrits'], n.m['Lus']], ['2', 'arbre principal', 'inconnu', 'inconnu']);
    await h.poser(sur({ 'wk-1': { cibles: { etat: 'ok', tronque: false, ecritures: e(200), lectures: e(199) } } }));
    const c = await faits();
    h.egal('P3.c', 'plafond : 200 entrées = « 200 ou plus » ; 199 sans drapeau = « 199 » exact', [c.m['Écrits'], c.m['Lus']], ['200 ou plus', '199']);
    await h.poser(sur({ 'wk-1': { cibles: { etat: 'ok', tronque: true, ecritures: e(5), lectures: e(3) } } }));
    const t = await faits();
    h.egal('P3.e', 'plafond total (cibles.tronque, moins de 200 par liste) : « 200 ou plus » aussi', [t.m['Écrits'], t.m['Lus']], ['200 ou plus', '200 ou plus']);
  });
  await h.section('P3', async () => {
    await h.poser({ voies, statut: 400 });
    const i = await faits();
    h.egal('P3.d', 'frise en 400 bornes-invalides : « indisponible », aucun chiffre ni « Réessayer » absent', [/indisponible/.test(i.texte), /\d/.test(i.ordre.map((k) => i.m[k]).join('')),
      await h.ev(() => [...document.querySelectorAll('.vf-fiche-faits button')].map((b) => b.textContent))], [true, false, ['Réessayer']]);
    await h.poser({ voies: (now, F) => voies(now, F).filter((v) => v.id !== 'wk-1'), tronque: true, voiesOmises: 3 });
    const a = await faits();
    await h.poser({ voies: (now, F) => voies(now, F).filter((v) => v.id !== 'wk-1') });
    const b = await faits();
    h.egal('P3.i', 'voie absente d\'une frise tronquée : « voies ne sont pas montrées », faits « inconnu », jamais 0 ; frise entière : « Plus dans la fenêtre de 24 h »',
      [/oies ne sont pas montrées/i.test(a.texte), a.m['Au travail'], /Plus dans la fenêtre de 24 h/.test(b.texte), b.m['Au travail']], [true, 'inconnu', true, 'inconnu']);
  });
}
JS
cat > "$AUX/s5.mjs" <<'JS'
import { voies, WHO, corps, msg, outil, lignes, iso } from './fix.mjs';
export const ids = ['P5', 'P7'];
const LIGNES = () => document.querySelectorAll('.vf-fiche-lignes > li').length;
export default async function (h) {
  const jeu = (now) => [msg(now, 20, 'premier **gras**'), outil(now, 19), outil(now, 18, { echec: true, erreur: 'ERREUR-SECRETE-74' }), msg(now, 17, 'deux'), outil(now, 16),
    msg(now, 15, 'trois'), outil(now, 14, { echec: true }), outil(now, 13, { n: 4 }), msg(now, 12, 'quatre')];
  await h.monter({ voies, who: WHO, fil: (now) => ({ 'wk-2': corps('wk-2', jeu(now)) }) });
  const texte = () => h.ev(() => document.querySelector('.vf-fiche-fil').innerText.replace(/\s+/g, ' '));
  const compteur = () => h.ev(() => document.querySelector('.vf-fiche-compteur').textContent.replace(/\s/g, ' ').trim());
  await h.section('P5', async () => {
    await h.ouvrir('wk-2');
    const l = await h.ev(() => { const li = [...document.querySelectorAll('.vf-fiche-lignes > li')], echec = li.filter((x) => x.querySelector('.vf-fiche-echec'));
      const d = (e) => [...e.querySelectorAll('path')].map((p) => p.getAttribute('d')).join('|'), ref = window.__vfEquipeRendu.glyphe(window.__vfEquipeRendu.GLYPHE_ETAT.bloque, '');
      return { n: li.length, heures: li.every((x) => /^\d\d:\d\d:\d\d$/.test(x.querySelector('.vf-fiche-heure').textContent)),
        echecs: echec.length, glypheEchec: echec.every((x) => d(x.querySelector('.vf-fiche-glyphe')) === [...ref.matchAll(/ d="([^"]*)"/g)].map((m) => m[1]).join('|') && d(x.querySelector('.vf-fiche-glyphe')) !== ''),
        mot: echec.every((x) => /échec$/.test(x.textContent.trim())), fuite: /ERREUR-SECRETE/.test(document.querySelector('.vf-fiche').innerText) }; });
    h.egal('P5', 'fil : 9 lignes datées, deux « échec » avec le glyphe de GLYPHE_ETAT (bloque), sans texte d\'erreur', [l.n, l.heures, l.echecs, l.glypheEchec, l.mot, l.fuite], [9, true, 2, true, true, false]);
    const filtres = await h.ev(() => [...document.querySelectorAll('.vf-fiche-filtre')].map((b) => [b.textContent.trim(), b.getAttribute('aria-pressed')]));
    h.egal('P5.a', 'trois filtres « Messages », « Outils », « Erreurs », aucun enfoncé, compteur « 9 lignes sur 9 »', [filtres, await compteur()], [[['Messages', 'false'], ['Outils', 'false'], ['Erreurs', 'false']], '9 lignes sur 9']);
    const clic = (nom) => h.ev((n) => { [...document.querySelectorAll('.vf-fiche-filtre')].find((b) => b.textContent.trim() === n).click(); }, nom);
    await clic('Messages'); const m = [await compteur(), await h.ev(LIGNES)];
    await clic('Erreurs'); const me = [await compteur(), await h.ev(LIGNES)];
    await clic('Messages'); const e = [await compteur(), await h.ev(LIGNES)];
    await clic('Erreurs'); await clic('Outils'); const o = [await compteur(), await h.ev(LIGNES)];
    h.egal('P5.d', 'filtres cumulables (union) : Messages 4, + Erreurs 6, Erreurs seul 2, Outils seul 5 — « N lignes sur 9 » exact',
      [m, me, e, o], [['4 lignes sur 9', 4], ['6 lignes sur 9', 6], ['2 lignes sur 9', 2], ['5 lignes sur 9', 5]]);
  });
  await h.section('P5', async () => {
    const etat = async (id, corpsFil, o = {}) => { await h.fermer().catch(() => {}); await h.filFixe(corpsFil === null ? {} : { [id]: corpsFil }, o);
      await h.ouvrir(id); return h.ev(() => { const f = document.querySelector('.vf-fiche-fil'); return { t: f.innerText.replace(/\s+/g, ' '), n: document.querySelectorAll('.vf-fiche-lignes > li').length,
        boutons: [...f.querySelectorAll('button')].filter((b) => b.offsetParent !== null).map((b) => b.textContent.trim()).filter((x) => !['Messages', 'Outils', 'Erreurs'].includes(x)) }; }); };
    const now = await h.horloge();
    const vide = await etat('wk-2', corps('wk-2', []));
    h.egal('P5.e', 'fil réel de 0 ligne : « Aucune ligne dans le fil. »', [/Aucune ligne dans le fil\./.test(vide.t), vide.n], [true, 0]);
    const inc = await etat('wk-2', null);
    h.egal('P5.c', 'corps `inconnu` : « non lu », ni liste vide, ni erreur, ni « Réessayer »', [/non lu/.test(inc.t), /Aucune ligne dans le fil/.test(inc.t), /indisponible/.test(inc.t), inc.boutons], [true, false, false, []]);
    const filt = await etat('wk-2', corps('wk-2', [msg(now, 5, 'seul')]));
    await h.ev(() => [...document.querySelectorAll('.vf-fiche-filtre')].find((b) => b.textContent.trim() === 'Erreurs').click());
    const sans = await h.ev(() => ({ t: document.querySelector('.vf-fiche-fil').innerText.replace(/\s+/g, ' '), tout: [...document.querySelectorAll('.vf-fiche-fil button')].map((b) => b.textContent.trim()).includes('Tout afficher') }));
    await h.ev(() => [...document.querySelectorAll('.vf-fiche-fil button')].find((b) => b.textContent.trim() === 'Tout afficher').click());
    const apres = await h.ev(() => [document.querySelectorAll('.vf-fiche-lignes > li').length, [...document.querySelectorAll('.vf-fiche-filtre')].map((b) => b.getAttribute('aria-pressed'))]);
    h.egal('P5.f', 'filtres sans résultat : « Aucune ligne ne correspond aux filtres. » + « Tout afficher » qui rend tout', [/Aucune ligne ne correspond aux filtres\./.test(sans.t), sans.tout, apres], [true, true, [1, ['false', 'false', 'false']]]);
    await h.filFixe({ 'wk-2': corps('wk-2', [msg(now, 5, 'seul')]) }, { statut: 500 });
    await h.fermer().catch(() => {}); await h.ouvrir('wk-2');
    const err = await h.ev(() => document.querySelector('.vf-fiche-fil').innerText.replace(/\s+/g, ' '));
    await h.filFixe({ 'wk-2': corps('wk-2', [msg(now, 5, 'seul')]) }, { statut: 200 });
    const n0 = await h.reqs('/api/vf/transcript');
    await h.ev(() => [...document.querySelectorAll('.vf-fiche-fil button')].find((b) => b.textContent.trim() === 'Réessayer').click());
    await h.attendre(() => document.querySelectorAll('.vf-fiche-lignes > li').length === 1, 'fil relu après « Réessayer »');
    h.egal('P5.g', 'erreur : « Le fil est indisponible. » + « Réessayer » qui relance UNE lecture GET', [/Le fil est indisponible\./.test(err), (await h.reqs('/api/vf/transcript')) - n0], [true, 1]);
    await h.fermer(); await h.poser({ voies: (n, F) => voies(n, F).filter((v) => v.id !== 'wk-2') });
    await h.ouvrir('wk-2');
    h.sonde('P5.h', 'agent hors de la frise de 24 h : « Cet agent n\'est plus dans la fenêtre de 24 h : rien à montrer. »',
      /Cet agent n'est plus dans la fenêtre de 24 h : rien à montrer\./.test(await texte()), await texte());
    await h.fermer(); await h.poser({ voies });
    await h.filFixe({ 'wk-2': corps('wk-2', jeu(now)) }, { delai: 1500 });
    await h.ouvrir('wk-2', null, false);
    await h.attendre(() => /Lecture du fil/.test(document.querySelector('.vf-fiche-fil').innerText), 'état de chargement du fil');
    h.sonde('P5.i', 'chargement : « Lecture du fil »', true, '');
    await h.fiche(); await h.filFixe({ 'wk-2': corps('wk-2', jeu(now)) }, { delai: 0 });
  });
  await h.section('P5', async () => {
    const now = await h.horloge();
    await h.fermer().catch(() => {});
    await h.poser({ voies: (n, F) => voies(n, F, { 'wk-2': { evenements: [[now - 15 * 60000, 'humain'], [now - 14 * 60000, 'compaction'], [now - 60 * 60000, 'humain']] } }) });
    await h.filFixe({ 'wk-2': corps('wk-2', [msg(now, 20, 'a'), outil(now, 10), msg(now, 5, 'b')]) });
    await h.ouvrir('wk-2');
    const lire = () => h.ev(() => [...document.querySelectorAll('.vf-fiche-lignes > li')].map((li) => li.querySelector('.vf-fiche-texte').textContent.replace(/\s+/g, ' ').trim()));
    const sans = await lire();
    await h.ev(() => [...document.querySelectorAll('.vf-fiche-filtre')].find((b) => b.textContent.trim() === 'Messages').click());
    const msgs = await lire();
    h.egal('P5.b', 'fusion : « Message de l\'humain » et « Compaction » viennent de la voie (le fil n\'en porte aucun) ; la compaction n\'est visible que sans filtre ; l\'événement plus ancien que le fil n\'est pas rendu',
      [sans.filter((x) => x === "Message de l'humain").length, sans.filter((x) => x === 'Compaction').length, msgs.filter((x) => x === "Message de l'humain").length, msgs.filter((x) => x === 'Compaction').length],
      [1, 1, 1, 0]);
    await h.fermer(); await h.poser({ voies: (n, F) => voies(n, F, { 'wk-2': { evenements: [[now - 15 * 60000, 'humain'], [now - 14 * 60000, 'compaction']] } }), sourceEtat: 'en-construction' });
    await h.ouvrir('wk-2');
    const cons = await lire();
    h.egal('P5.j', 'source `en-construction` : aucune de ces deux lignes', cons.filter((x) => x === "Message de l'humain" || x === 'Compaction').length, 0);
    await h.poser({ voies });
  });
  await h.section('P7', async () => {
    const now = await h.horloge();
    await h.fermer().catch(() => {});
    const long = Array.from({ length: 9 }, (_, i) => `ligne ${i}`).join('\n\n');
    await h.filFixe({ 'wk-2': corps('wk-2', [...lignes(now, 80, 'message', 400), ...lignes(now, 260, 'outil', 300), msg(now, 1, long)], { tronque: true }) });
    await h.ouvrir('wk-2');
    const c = await h.ev(() => ({ m: document.querySelectorAll('li.vf-fiche-message').length, o: document.querySelectorAll('li.vf-fiche-outil').length,
      coupe: /Plus ancien que la fenêtre lue/.test(document.querySelector('.vf-fiche-fil').innerText) }));
    h.egal('P7', 'au plus 50 messages et 200 outils rendus ; « Plus ancien que la fenêtre lue » présente quand tronque', [c.m, c.o, c.coupe], [50, 200, true]);
    const r = await h.ev(() => { const b = [...document.querySelectorAll('.vf-fiche-fil button')].find((x) => /Afficher tout le message/.test(x.textContent));
      const av = b && [b.getAttribute('aria-expanded'), b.textContent.trim()]; if (b) b.click();
      const ap = b && [b.getAttribute('aria-expanded'), b.textContent.trim()]; return { av, ap }; });
    h.egal('P7.a', 'message de plus de 6 lignes replié : « Afficher tout le message » (aria-expanded), puis « Réduire le message »', r, { av: ['false', 'Afficher tout le message'], ap: ['true', 'Réduire le message'] });
    await h.fermer(); await h.filFixe({ 'wk-2': corps('wk-2', [msg(now, 5, 'court')]) }); await h.ouvrir('wk-2');
    h.sonde('P7.b', 'pas de coupe dite quand le fil n\'est pas tronqué (témoin négatif apparié)', !/Plus ancien que la fenêtre lue/.test(await texte()), '');
  });
}
JS
cat > "$AUX/s6.mjs" <<'JS'
import { voies, WHO, corps, lignes } from './fix.mjs';
export const ids = ['P6'];
const DIST = () => { const c = document.querySelector('.vf-fiche-fil'); return Math.round(c.scrollHeight - c.scrollTop - c.clientHeight); };
export default async function (h) {
  await h.monter({ voies, who: WHO, fil: (now) => ({ 'wk-2': corps('wk-2', lignes(now, 70)) }) });
  await h.section('P6', async () => {
    const now = await h.horloge();
    const nb = () => h.ev(() => document.querySelectorAll('.vf-fiche-lignes > li').length);
    const croitre = async (n) => { await h.filFixe({ 'wk-2': corps('wk-2', lignes(now, n)) }); await h.emettre('frise', n);
      await h.attendre(`document.querySelectorAll('.vf-fiche-lignes > li').length === ${n}`, `fil à ${n} lignes`, 8000); };
    await h.ouvrir('wk-2');
    await h.ev(() => { const c = document.querySelector('.vf-fiche-fil'); c.scrollTop = c.scrollHeight; });
    await h.pause(300);
    const haut = await h.ev(() => { const c = document.querySelector('.vf-fiche-fil'); return [c.scrollHeight > c.clientHeight + 100, getComputedStyle(c).scrollBehavior]; });
    await croitre(73);
    const colle = await h.ev(DIST);
    h.egal('P6', 'fil collé en bas (moins de --sp-24) : il y reste à chaque nouvelle ligne ; le conteneur défile ; aucun scroll-behavior animé', [haut, colle <= 1], [[true, 'auto'], true]);
    await h.ev(() => { document.querySelector('.vf-fiche-fil').scrollTop = 0; });
    await h.pause(300);
    await croitre(76);
    const r = await h.ev(() => { const c = document.querySelector('.vf-fiche-fil'), b = [...c.querySelectorAll('button')].find((x) => x.textContent.trim().startsWith('Revenir au direct')),
      a = c.closest('.vf-fiche').querySelector('[aria-live=polite]');
      return { top: c.scrollTop, b: !!b && !b.hidden && b.offsetParent !== null, annonce: a ? a.textContent.replace(/\s+/g, ' ') : null }; });
    h.egal('P6.a', 'après remontée : le défilement ne bouge pas, « Revenir au direct » apparaît, « 3 nouvelles lignes » annoncé (aria-live)', [r.top, r.b, /3 nouvelles lignes/.test(r.annonce || '')], [0, true, true]);
    const s = await h.ev(() => { const c = document.querySelector('.vf-fiche-fil'); [...c.querySelectorAll('button')].find((x) => x.textContent.trim().startsWith('Revenir au direct')).click();
      return Math.round(c.scrollHeight - c.scrollTop - c.clientHeight); });
    h.egal('P6.b', '« Revenir au direct » place le fil en bas dans la même image (saut immédiat)', s <= 1, true);
  });
}
JS
cat > "$AUX/s8.mjs" <<'JS'
import { voies, WHO, corps, msg } from './fix.mjs';
export const ids = ['P8', 'P17', 'P19'];
const ORIGINE = (id) => `#vf-equipe li[data-vf-agent="${id}"] .vf-rg-tog`;
const ETAT = (sel) => ({ ferme: !document.querySelector('.vf-fiche'), foc: document.activeElement === document.querySelector(sel) });
export default async function (h) {
  const fil = (now) => ({ 'wk-2': corps('wk-2', [msg(now, 5, 'x')]), 'wk-1': corps('wk-1', [msg(now, 5, 'y')]) });
  await h.monter({ voies, who: WHO, fil });
  await h.ev(() => { window.__ouv = []; document.addEventListener('vf-agent:ouvrir', (e) => window.__ouv.push({ d: e.detail && e.detail.declencheur, prevented: e.defaultPrevented })); });
  await h.section('P8', async () => {
    await h.ev(() => { const v = document.querySelector('.vf-vue[data-vf-vue="regie"]'); window.__v = v; v.dataset.sentinelle = '1'; });
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    const pendant = await h.ev(() => { const v = window.__v; return [v.hidden, v.inert, document.body.contains(v)]; });
    await h.ev(() => document.querySelector('.vf-fiche-retour').click());
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée');
    const r = await h.ev((sel) => ({ foc: document.activeElement === document.querySelector(sel), memeVue: window.__v === document.querySelector('.vf-vue[data-vf-vue="regie"]'),
      etat: [window.__v.hidden, window.__v.inert, window.__v.dataset.sentinelle] }), ORIGINE('wk-2'));
    h.egal('P8', '« Retour » ferme et rend le focus à l\'élément d\'origine ; la vue d\'origine reste dans le DOM, hidden et inert pendant l\'ouverture, intacte au retour',
      [pendant, r.foc, r.memeVue, r.etat], [[true, true, true], true, true, [false, false, '1']]);
    // origine disparue : d'abord la voie du même agent (un bouton `data-id`), puis la bascule
    await h.ev(() => window.__vfEquipeVues.declarer({ id: 'essai', libelle: 'Essai', monter() {}, demonter() {} }));
    await h.attendre("!!document.querySelector('#vf-equipe [role=tablist][aria-label=\"Vue de l\\'équipe\"]')", 'bascule dessinée');
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    await h.ev(() => { const b = document.createElement('button'); b.setAttribute('data-id', 'wk-2'); b.id = 'voie-factice'; b.textContent = 'voie'; document.getElementById('vf-equipe-entete').after(b);
      document.querySelector('#vf-equipe li[data-vf-agent="wk-2"]').remove(); });
    await h.ev(() => document.querySelector('.vf-fiche-retour').click());
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée');
    const voie = await h.ev(() => document.activeElement && document.activeElement.id);
    await h.ev(() => document.getElementById('voie-factice').remove());
    await h.ouvrir('wk-1', ORIGINE('wk-1'));
    await h.ev(() => document.querySelector('#vf-equipe li[data-vf-agent="wk-1"]').remove());
    await h.ev(() => document.querySelector('.vf-fiche-retour').click());
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée');
    const bascule = await h.ev(() => { const a = document.activeElement; return a && [a.getAttribute('role'), a.closest('[role=tablist]') && a.closest('[role=tablist]').getAttribute('aria-label')]; });
    h.egal('P8.e', 'origine disparue : le focus va à la voie du même agent, sinon à la bascule « Vue de l\'équipe »', [voie, bascule], ['voie-factice', ['tab', "Vue de l'équipe"]]);
  });
  await h.section('P8', async () => {
    const poser = async (pile) => { await h.ev((p) => { if (p) window.__poserPile(false); }, pile); };
    for (const pile of [false, true]) {
      await h.monter({ voies, who: WHO, fil });
      await h.ev(() => { window.__tmpv = 1; });
      await poser(pile);
      await h.ouvrir('wk-2', ORIGINE('wk-2'));
      await h.echap();
      await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée par Échap');
      const e = await h.ev(ETAT, ORIGINE('wk-2'));
      h.egal('P8.a', `un Échap intact ferme la fiche et rend le focus (pile factice ${pile ? 'présente' : 'absente'})`, e, { ferme: true, foc: true });
    }
    // un Échap déjà pris : preventDefault seul, en capture sur document (la fiche l'ignore) ; puis le même geste que la pile de la 80
    await h.monter({ voies, who: WHO, fil });
    await h.ev(() => { window.__bloque = true; document.addEventListener('keydown', (e) => { if (window.__bloque && e.key === 'Escape') e.preventDefault(); }, true); });
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    await h.echap(); await h.pause(300);
    const reste = await h.ev(() => !!document.querySelector('.vf-fiche'));
    await h.ev(() => { window.__bloque = false; });
    await h.echap();
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée sans blocage');
    h.egal('P8.b', 'un Échap dont defaultPrevented est vrai ne ferme PAS la fiche ; sans blocage, le même appui la ferme (témoin positif)', reste, true);
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    await h.ev(() => window.__poserPile(true));
    await h.echap(); await h.pause(300);
    const pile = await h.ev(() => [!!document.querySelector('.vf-fiche'), window.__pris]);
    await h.ev(() => window.__poserPile(false));
    await h.echap();
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée, pile inerte');
    h.egal('P8.f', 'la pile factice (preventDefault puis stopPropagation en capture sur window) garde la fiche ouverte ; inerte, la fiche se ferme', pile, [true, 1]);
    const acces = await h.ev(() => ({ n: window.__acces.slice(), get: typeof Object.getOwnPropertyDescriptor(window, 'VF_SURCOUCHES').get }));
    h.egal('P8.c', 'la fiche ne lit jamais VF_SURCOUCHES ni VF_PANNEAU (espion armé : zéro accès)', [acces.n, acces.get], [[], 'function']);
    const fl = await h.ev(() => window.__fl.filter((x) => x.t === 'keydown').map((x) => [x.c === document, x.c === window, x.cap]));
    h.egal('P8.d', 'l\'écoute d\'Échap : sur document, en phase de remontée, jamais sur window (un écouteur exactement)', fl, [[true, false, false]]);
  });
  await h.section('P17', async () => {
    await h.monter({ voies, who: WHO, fil });
    await h.ev(() => window.__vfEquipeVues.declarer({ id: 'essai', libelle: 'Essai', monter() {}, demonter() {} }));
    await h.ev(() => { window.__ouv = []; document.addEventListener('vf-agent:ouvrir', (e) => window.__ouv.push({ d: e.detail && e.detail.declencheur, prevented: e.defaultPrevented })); window.__lus = [];
      document.addEventListener('vf-agent:lu', (e) => window.__lus.push(e.detail && e.detail.id)); });
    const cas = [['nom', ORIGINE('wk-2'), 'wk-2', () => document.querySelector('#vf-equipe li[data-vf-agent="wk-2"] .vf-rg-tog').click()],
      ['rapport', '#vf-equipe li[data-vf-agent="wk-1"] .vf-rg-act button', 'wk-1', () => document.querySelector('#vf-equipe li[data-vf-agent="wk-1"] .vf-rg-act button').click()],
      ['ancre', '#vf-equipe li[data-vf-agent="wk-2"]', 'wk-2', () => window.__vfRegie.arriver('n:ag-wk-2')]];
    for (const [decl, sel, id, geste] of cas) {
      const av = await h.ev(() => ({ panel: document.getElementById('panel').outerHTML, n: window.__ouv.length }));
      await h.ev(geste);
      await h.fiche();
      const o = await h.ev((i) => ({ ouv: window.__ouv.slice(-1)[0], ouvre: !!document.querySelector(`.vf-fiche[data-vf-fiche="${i}"]`), panel: document.getElementById('panel').outerHTML,
        repli: !!document.querySelector('.vf-transcript'), etendu: [...document.querySelectorAll('#vf-equipe .vf-rg-tog')].map((b) => b.getAttribute('aria-expanded')),
        lus: window.__lus.slice() }), id);
      h.egal(`P17`, `déclencheur « ${decl} » : annulé (preventDefault), la fiche s'ouvre, la régie ne fait rien d'autre (aucun détail déplié, aucun lecteur de repli, #panel intact)`,
        [o.ouv, o.ouvre, o.panel === av.panel, o.repli, o.etendu.every((x) => x === 'false'), o.lus.includes('wk-2')], [{ d: decl, prevented: true }, true, true, false, true, false]);
      await h.ev(() => document.querySelector('.vf-fiche-retour').click());
      await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée');
      const r = await h.ev((s) => { const el = document.querySelector(s), a = document.activeElement;
        return { foc: el ? a === el : a !== document.body && !!a.closest('#vf-equipe') }; }, sel);
      h.egal('P17.a', `à la fermeture le focus revient à l'élément du déclencheur « ${decl} »`, r, { foc: true });
    }
    const faux = await h.ev(() => { const mk = (d) => new CustomEvent('vf-agent:ouvrir', { detail: { id: 'wk-2', kind: 'subagent', declencheur: d }, cancelable: true, bubbles: true });
      const autre = document.dispatchEvent(mk('autre')), ouvertAutre = !!document.querySelector('.vf-fiche'), nom = document.dispatchEvent(mk('nom'));
      return { autre, ouvertAutre, nom, ouvertNom: !!document.querySelector('.vf-fiche') }; });
    h.egal('P17.b', 'un déclencheur inconnu n\'est pas annulé et n\'ouvre rien ; « nom » (témoin positif) est annulé et ouvre', faux, { autre: true, ouvertAutre: false, nom: false, ouvertNom: true });
  });
  await h.section('P19', async () => {
    const vues = () => h.ev(() => [...document.querySelectorAll('#vf-equipe .vf-vue')].map((v) => [v.getAttribute('data-vf-vue'), v.hidden, v.inert]));
    const tab = (lib) => h.ev((l) => { const t = [...document.querySelectorAll('#vf-equipe [role=tablist] [role=tab]')].find((x) => x.textContent === l); if (t) t.click(); return !!t; }, lib);
    await h.monter({ voies, who: WHO, fil });
    await h.attendre("[...document.querySelectorAll('#vf-equipe [role=tablist] [role=tab]')].some((x) => x.textContent === 'Frise')", 'bascule Régie et Frise');
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    await tab('Frise');
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée par la bascule');
    const a = await vues();
    h.egal('P19', 'fiche ouverte depuis la régie, clic sur « Frise » : la fiche se ferme, UNE seule vue visible (la frise), aucune inert', a, [['regie', true, false], ['frise', false, false]]);
    await h.ouvrir('wk-2');
    await tab('Régie');
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée par la bascule');
    const b = await vues();
    h.egal('P19.a', 'fiche ouverte depuis la frise, clic sur « Régie » : une seule vue visible (la régie), aucune inert', b, [['regie', false, false], ['frise', true, false]]);
    await h.ouvrir('wk-2');
    await tab('Régie');
    await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée par la bascule');
    h.egal('P19.b', 'clic sur la vue déjà choisie (témoin) : la vue d\'origine revient, aucune inert', await vues(), [['regie', false, false], ['frise', true, false]]);
    // le FOND de la bascule (le conteneur, hors d'un onglet) ne change aucune vue : la fiche reste ouverte ; une fois fermée, exactement une vue visible
    await h.ouvrir('wk-2');
    await h.ev(() => document.querySelector('#vf-equipe [role=tablist]').click());
    await h.pause(300);
    const ouverte = await h.ev(() => !!document.querySelector('.vf-fiche'));
    await h.fermer();
    const c = await vues();
    h.egal('P19.c', 'clic sur le fond de la bascule, fiche ouverte : elle reste ouverte ; une fois fermée, UNE seule vue visible, aucune inert',
      [ouverte, c.filter((v) => !v[1]).length, c.some((v) => v[2])], [true, 1, false]);
  });
}
JS
cat > "$AUX/s10.mjs" <<'JS'
import { voies, WHO, corps, msg, outil } from './fix.mjs';
export const ids = ['P10', 'P11', 'P13', 'P14'];
export default async function (h) {
  const fil = (now) => ({ 'wk-2': corps('wk-2', [msg(now, 9, 'bonjour'), outil(now, 8), outil(now, 7, { echec: true, erreur: 'ERREUR-SECRETE-74', commande: 'rm -rf /' }),
    outil(now, 6, { outil: 'Bash', verbe: 'lance une commande', cible: '', commande: 'rm -rf /', cout: '12,50 €' })], { mandat: 'mandat' }) });
  await h.section('P10', async () => {
    await h.monter({ voies, who: WHO, fil });
    await h.ouvrir('wk-2');
    const g = await h.ev(() => { const r = (e) => { const b = e.getBoundingClientRect(); return [Math.round(b.left), Math.round(b.top), Math.round(b.width)]; };
      const f = document.querySelector('.vf-fiche-faits'), l = document.querySelector('.vf-fiche-fil'), cs = (e) => getComputedStyle(e);
      return { faits: r(f), fil: r(l), roles: [f, l].map((e) => [e.getAttribute('role'), e.getAttribute('tabindex'), e.getAttribute('aria-label')]), oy: [cs(f).overflowY, cs(l).overflowY] }; });
    h.egal('P10', 'à 1280 px : faits et fil côte à côte (même haut, le fil à droite), chacun région tabindex 0 nommée, défilement propre',
      [g.faits[1] === g.fil[1], g.faits[0] < g.fil[0], g.roles, g.oy], [true, true, [['region', '0', 'Faits de Rédiger les faits'], ['region', '0', 'Fil de Rédiger les faits']], ['auto', 'auto']]);
    await h.monter({ voies, who: WHO, fil, largeur: 390, hauteur: 800, coarse: true });
    await h.ouvrir('wk-2');
    const t = await h.ev(() => { const f = document.querySelector('.vf-fiche-faits'), l = document.querySelector('.vf-fiche-fil'), d = document.querySelector('.vf-fiche details'), s = d && d.querySelector('summary');
      return { une: Math.round(f.getBoundingClientRect().left) === Math.round(l.getBoundingClientRect().left), det: d && [d.open, s.textContent.replace(/\s+/g, ' ').trim().startsWith("Faits de l'agent")],
        sx: document.documentElement.scrollWidth <= document.documentElement.clientWidth, oyFil: getComputedStyle(l).overflowY }; });
    h.egal('P10.a', 'à 390 px : une colonne, « Faits de l\'agent » (details) fermé, aucun défilement horizontal, le fil sans boîte de hauteur propre',
      [t.une, t.det, t.sx, ['visible', 'clip'].includes(t.oyFil)], [true, [false, true], true, true]);
  });
  await h.section('P11', async () => {
    await h.monter({ voies, who: WHO, fil });
    await h.ouvrir('wk-2');
    const x = await h.ev(() => { const f = document.querySelector('.vf-fiche'), t = f.innerText;
      return { secret: /ERREUR-SECRETE-74|rm -rf/.test(t), montant: /[€$]|12,50/.test(t), commande: /lance une commande/.test(t),
        boutons: [...f.querySelectorAll('button')].map((b) => b.textContent.trim()).filter((s) => /terminal|écrire|arrêt/i.test(s)),
        doing: window.__req.some((u) => u.includes('/api/vf/doing')), meth: [...new Set(window.__meth)] }; });
    h.egal('P11', 'aucune fuite : ni erreur ni argument de commande ni montant, aucun bouton d\'action sur la session, aucune requête à /doing, aucune requête autre que GET ; les lignes sont bien rendues (témoin)',
      [x.secret, x.montant, x.commande, x.boutons, x.doing, x.meth], [false, false, true, [], false, ['GET']]);
  });
  await h.section('P13', async () => {
    const mes = () => h.ev(() => { const f = document.querySelector('.vf-fiche'), c = getComputedStyle(f), sf = window.__couleur('--surface'), col = (s) => getComputedStyle(f.querySelector(s)).color;
      return { anim: [c.animationName, c.animationDuration], surface: sf, cols: { ratt: col('.vf-fiche-ratt'), heure: col('.vf-fiche-heure'), compteur: col('.vf-fiche-compteur'),
        lib: col('.vf-fiche-lib'), titre: col('.vf-fiche-titre') } }; });
    await h.monter({ voies, who: WHO, fil, media: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    await h.ouvrir('wk-2');
    const r = await mes();
    h.sonde('P13', 'mouvement réduit : aucune animation d\'ouverture', r.anim[0] === 'none' || r.anim[1] === '0s', JSON.stringify(r.anim));
    await h.monter({ voies, who: WHO, fil });
    await h.ouvrir('wk-2');
    const n = await mes();
    h.sonde('P13.a', 'mouvement normal : un fondu de 200 ms à l\'ouverture (témoin apparié)', n.anim[0] !== 'none' && n.anim[1] === '0.2s', JSON.stringify(n.anim));
    for (const theme of ['dark', 'light']) {
      await h.monter({ voies, who: WHO, fil, media: [{ name: 'prefers-color-scheme', value: theme }] });
      await h.ouvrir('wk-2');
      const m = await mes(), q = Object.fromEntries(Object.entries(m.cols).map(([k, c]) => [k, Math.round(h.ratio(c, m.surface) * 100) / 100]));
      h.sonde('P13.b', `thème ${theme} : texte de la fiche ≥ 4,5:1 sur --surface`, Object.values(q).every((x) => x >= 4.5), JSON.stringify(q));
    }
    await h.touche('Shift', 'ShiftLeft', 16);
    await h.ev(() => document.querySelector('.vf-fiche-filtre').focus());
    const f = await h.ev(() => { const c = getComputedStyle(document.querySelector('.vf-fiche-filtre')); return [c.outlineStyle, c.outlineWidth, c.outlineColor === window.__couleur('--ring')]; });
    h.egal('P13.c', 'focus visible : 2px solid var(--ring)', f, ['solid', '2px', true]);
  });
  await h.section('P14', async () => {
    const hostile = '<img src=x onerror="window.__xss=1">';
    const who = WHO.map((w) => (w.id === 'wk-2' ? { ...w, task: hostile, role: hostile, rattachement: { ...w.rattachement, noeud: hostile } } : w));
    await h.monter({ voies: (now, F) => voies(now, F, { 'wk-2': { role: hostile, rattachement: { dag: 'm1.md', noeud: hostile, source: 'mandat' } } }), who,
      fil: (now) => ({ 'wk-2': corps('wk-2', [msg(now, 3, hostile + '\n\n<script>window.__xss=2</script>'), outil(now, 2, { cible: hostile, verbe: hostile })], { mandat: hostile }) }) });
    await h.ouvrir('wk-2');
    await h.ev(() => document.querySelector('.vf-fiche-mandat') && document.querySelector('.vf-fiche-mandat').click());
    await h.pause(300);
    const x = await h.ev(() => { const f = document.querySelector('.vf-fiche');
      return { inj: f.querySelectorAll('img, script, b, iframe, [onerror]').length, xss: window.__xss, titre: f.querySelector('.vf-fiche-titre').textContent, texte: f.innerText.includes('<img src=x') }; });
    h.egal('P14', 'donnée hostile : aucun élément injecté, aucun script exécuté, le titre et le texte s\'affichent tels quels', [x.inj, x.xss, x.titre, x.texte], [0, 0, '<img src=x onerror="window.__xss=1">', true]);
  });
}
JS
cat > "$AUX/s15.mjs" <<'JS'
import { voies, WHO, corps, msg } from './fix.mjs';
export const ids = ['P15', 'P16', 'P18'];
const ORIGINE = (id) => `#vf-equipe li[data-vf-agent="${id}"] .vf-rg-tog`;
const ETAT = () => ({ ferme: !document.querySelector('.vf-fiche'), nFiches: document.querySelectorAll('.vf-fiche').length, esc: window.__nfl('keydown'), ouvrir: window.__nfl('vf-agent:ouvrir'),
  abo: window.VF_ETAT.abonnes().frise, tm: window.__tm.size, vue: (() => { const v = document.querySelector('.vf-vue[data-vf-vue="regie"]'); return v ? [v.hidden, v.inert] : null; })() });
export default async function (h) {
  const fil = (now) => ({ 'wk-2': corps('wk-2', [msg(now, 5, 'x')]), 'wk-1': corps('wk-1', [msg(now, 5, 'y')]) });
  await h.monter({ voies, who: WHO, fil });
  await h.section('P16', async () => {
    await h.ev(() => { window.__lus = []; document.addEventListener('vf-agent:lu', (e) => window.__lus.push(e.detail && e.detail.id)); });
    const lus = () => h.ev(() => window.__lus.slice());
    await h.ouvrir('wk-1'); const a = await lus(); await h.fermer();
    await h.ouvrir('wk-2'); const b = await lus(); await h.fermer();
    await h.ouvrir('wk-1'); const c = await lus();
    h.egal('P16', 'agent TERMINÉ : exactement un vf-agent:lu { id } par ouverture (deux ouvertures, deux événements) ; agent actif : aucun', [a, b, c], [['wk-1'], ['wk-1'], ['wk-1', 'wk-1']]);
    await h.fermer();
  });
  await h.section('P15', async () => {
    const av = await h.ev(ETAT);
    await h.cycle('code'); await h.cycle('code');
    const ap = await h.ev(ETAT);
    h.egal('P15', 'après deux allers-retours d\'onglet : un seul écouteur Échap, un seul écouteur vf-agent:ouvrir, AUCUN abonnement frise (il n\'existe que fiche ouverte), aucune fiche, aucune minuterie',
      [av.esc, av.ouvrir, av.abo, ap.esc, ap.ouvrir, ap.abo, ap.nFiches, ap.tm], [1, 1, 0, 1, 1, 0, 0, 0]);
    await h.ouvrir('wk-2');
    const ouvert = (await h.ev(ETAT)).abo;
    const n0 = [await h.reqs('depuis='), await h.reqs('/api/vf/transcript')];
    await h.emettre('frise', 900);
    await h.pause(2500);
    const n1 = [await h.reqs('depuis='), await h.reqs('/api/vf/transcript')];
    h.egal('P15.a', 'un événement frise : UNE relecture de la frise et UNE du fil, UN abonnement fiche ouverte, un seul DOM de fiche', [n1[0] - n0[0], n1[1] - n0[1], (await h.ev(ETAT)).nFiches, ouvert], [1, 1, 1, 1]);
    await h.fermer();
    h.egal('P15.b', 'fiche fermée : l\'abonnement frise est retiré', (await h.ev(ETAT)).abo, 0);
  });
  await h.section('P18', async () => {
    await h.monter({ voies, who: WHO, fil });
    await h.ev(() => { window.__esc2 = null; window.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__esc2 = e.defaultPrevented; }); });
    await h.ouvrir('wk-2', ORIGINE('wk-2'));
    await h.cycle('code'); await h.cycle('code');
    const a = await h.ev(ETAT);
    h.egal('P18', 'Code, Équipe, Code, Équipe avec la fiche ouverte : au retour elle est FERMÉE, la vue d\'origine ni hidden ni inert, un seul écouteur Échap, un seul vf-agent:ouvrir, aucun abonnement frise, aucune minuterie',
      [a.ferme, a.vue, a.esc, a.ouvrir, a.abo, a.tm], [true, [false, false], 1, 1, 0, 0]);
    await h.ev(() => { window.__esc2 = null; window.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__esc2 = e.defaultPrevented; }); });
    await h.echap(); await h.pause(300);
    const e = await h.ev(() => ({ esc: window.__esc2, fiches: document.querySelectorAll('.vf-fiche').length, errs: window.__errs.length }));
    h.egal('P18.a', 'Échap après le retour ne fait rien (aucune fiche, événement non pris, aucune erreur de page)', e, { esc: false, fiches: 0, errs: 0 });
    const s = await h.ev(() => window.__surOnglet.filter((x) => x.fiche).map((x) => x.cle));
    h.sonde('P18.b', 'l\'inscription porte cle « 74-vf-fiche.js » à chaque arrivée (au moins trois, aucune sans clé)', s.length >= 3 && s.every((c) => c === '74-vf-fiche.js'), JSON.stringify(s));
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
somme_lab() { ( cd "$LAB" && find . -path ./.vibeflow -prune -o -path ./.git -prune -o -type f -print | sort | while IFS= read -r f; do cksum "$f"; done | cksum ); }
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
demarrer() { COCKPIT_LOG="$WORK/serve-$1.out" cockpit_lancer "$LAB" HOME="$WORK/home" || true; }

# joue <scénario> <port> <sections…> : une ligne PASS/FAIL par sonde ; une section sans sonde est un FAIL nommé
joue() {
  local f="$1" port="$2" out line id lib ok ob; shift 2
  out="$("$NODE" "$HERE_T/chrome-fiche.mjs" "$CHROME" "$AUX/$f.mjs" "http://127.0.0.1:$port" 2>&1 | tail -1)"
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

echo "=== S0 — les scénarios se lisent ==="
bad=""; for f in "$AUX"/s*.mjs "$AUX/fix.mjs"; do "$NODE" --check "$f" 2>/dev/null || bad="$bad $(basename "$f")"; done
assert_eq "S0 — chaque scénario passe node --check" "${bad:-aucun}" "aucun"

# ---------- P12 : forme du code (statique) ----------
MODS="74-vf-fiche-faits.js 74-vf-fiche-style.js 74-vf-fiche.js"
statique() { # <dossier ui> : une ligne par écart ; rien si tout est conforme
  local d="$1" f p
  for f in $MODS; do p="$d/$f"; [ -s "$p" ] || { echo "$f : module absent ou vide"; continue; }
    "$NODE" "$HERE_T/css-jetons.mjs" "$p" 2>&1 | sed "s#^#css-jetons #"
    grep -nE 'fetch\(|EventSource|innerHTML|#panel|VF_SURCOUCHES|VF_PANNEAU|VF_FLUX|sessionStorage|—|dureeS|/api/vf/doing|showPanel' "$p" | sed "s#^#$f : interdit #"
    grep -nE '<path|createElementNS\([^)]*, *.path.\)' "$p" | sed "s#^#$f : tracé d'état défini ici #"
    head -5 "$p" | grep -q 'vf-coquille: persistant' && echo "$f : marqué persistant"
    [ "$(awk 'END { print NR }' "$p")" -le 299 ] || echo "$f : plus de 299 lignes"
    "$NODE" -e 'const l = require("fs").readFileSync(process.argv[1], "utf8").split("\n"); const n = l.filter((x) => [...x].length > 160).length; if (n) console.log(process.argv[2] + " : " + n + " ligne(s) de plus de 160 colonnes");' "$p" "$f"
    grep -nE "font-size: *[0-9.]+px" "$p" | grep -vE "font-size: *(11\.5|12\.5|13|15|20)px" | sed "s#^#$f : taille hors échelle #"
  done
  [ -s "$d/74-vf-fiche-style.js" ] && { [ "$(grep -c 'var(--mono)' "$d/74-vf-fiche-style.js")" -eq 1 ] || echo "style : plus d'une règle de police mono (une seule taille)"; }
  [ -s "$d/74-vf-fiche.js" ] && { grep -q '__vfEquipeRendu' "$d/74-vf-fiche.js" || echo "fiche : la table de glyphes de la régie n'est jamais lue"; }
  [ -s "$d/74-vf-fiche.js" ] && { grep -q "cle: '74-vf-fiche.js'" "$d/74-vf-fiche.js" || echo "fiche : inscription surOnglet sans cle « 74-vf-fiche.js »"; }
  [ -s "$d/74-vf-fiche.js" ] && { grep -q "keydown" "$d/74-vf-fiche.js" && grep -qE "keydown'?, *[a-zA-Z]+, *(true|\{[^}]*capture)" "$d/74-vf-fiche.js" && echo "fiche : écoute d'Échap en capture"; }
  return 0
}
echo "=== P12 — forme du code (A44, jetons, aucun réseau direct, ni surcouche ni panneau) ==="
ECARTS="$(statique "$UI")"
assert_eq "P12 — trois modules : jetons, rien d'interdit, ni persistant ni capture, ≤ 299 lignes, ≤ 160 colonnes, une taille de mono, glyphes de la régie, cle de surOnglet" "${ECARTS:-aucun écart}" "aucun écart"

if [ -z "$CHROME" ]; then
  skip "P1 à P11, P13 à P18" "pas de navigateur"
else
  demarrer base; PORT="$VF_PORT"; SRV="$VF_PID"
  assert_eq "S0 — contrôle positif : serveur de la suite démarré, page Équipe servie" "$([ "$PORT" -gt 0 ] && echo serveur)" "serveur"
  avant="$(somme_lab)"
  echo "=== P1, P2, P4, P9 — ouverture, session et sous-agent, rattachement, lien du parent ==="; joue s1 "$PORT" P1 P2 P4 P9
  echo "=== P3 — faits ==="; joue s3 "$PORT" P3
  echo "=== P5, P7 — fil, bornes ==="; joue s5 "$PORT" P5 P7
  echo "=== P6 — direct ==="; joue s6 "$PORT" P6
  echo "=== P8, P17, P19 — fermeture, Échap, déclencheurs de la régie, bascule de vue ==="; joue s8 "$PORT" P8 P17 P19
  echo "=== P10, P11, P13, P14 — colonnes, fuites, mouvement et contrastes, donnée hostile ==="; joue s10 "$PORT" P10 P11 P13 P14
  echo "=== P15, P16, P18 — cycle de vie, vf-agent:lu, aller-retour d'onglet ==="; joue s15 "$PORT" P15 P16 P18
  assert_eq "S0 — aucun fichier du lab modifié (somme du dossier avant/après)" "$(somme_lab)" "$avant"
  cockpit_arreter "$SRV"; SRV=""
fi

echo
echo "durée : $(( $(date +%s) - T0 )) s"
echo "Résultat : $PASS réussis, $FAIL échecs, $SKIP sautés"
[ "$FAIL" -eq 0 ]
