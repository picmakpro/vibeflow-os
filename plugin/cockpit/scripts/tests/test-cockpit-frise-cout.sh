#!/usr/bin/env bash
# test-cockpit-frise-cout.sh : le bandeau « Dépôt » et le coût de la frise sous Chrome (Phase 74, plan 74-07 ; TEMP-02 part Dépôt, TEMP-09, TEMP-10 côté page, TEMP-12 part forme).
# Routes factices posées par VF_PRE (journal des requêtes) : frise, git (cockpit-git@1), détail d'un commit, état (missions et phases fusionnées à la vraie réponse) ;
# la page, le serveur, le flux (enveloppe AMORCE_FLUX), la régie de la 73 et le tiroir Git de la 80 sont les vrais.
#   D1 bandeau (branches, « Autres commits », losanges, boutons)  D2 heure des commits  D3 couverture et états (chargement, échec, vide)  D4 clic vers le tiroir Git
#   D5 jamais attribué à une voie  D5b lecture Git au montage puis sur l'événement git  D6 synthèse de l'en-tête  D7 section « Coût »  D8 trois regroupements
#   D9 aucune devise ni estimation  D10 un seul calcul de jetons  D11 formats  D12 forme du code (statique) et téléphone  D13 incomplet  D14 aller-retour d'onglet  D15 focus conservé à la relecture  D16 aucune donnée de frise : coût vide  D17 aucun texte non fiable dans un sélecteur
# Plan 74-07 non marqué audit : le régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) ne demande aucun mutant ;
# les douze mutants du plan ne sont pas joués ici.
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
[ -n "${FRISE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES)}"
NODE="$(command -v node)"
export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-30000}"
DETAILS="$HERE_T/temoins/git-tiroir-details.json"

# ---------- crochets de page (VF_PRE) : routes factices, journal, espions ----------
{ cat <<'JS'; printf 'window.__vfDet = '; cat "$DETAILS"; printf ';\n'; cat <<'JS2'; } > "$AUX/pre.js"
window.__errs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
{ const ce = console.error; console.error = (...a) => { window.__errs.push(a.map(String).join(' ')); ce.apply(console, a); }; }
window.__couleur = (x) => { const p = document.createElement('i'); p.style.color = x.startsWith('--') ? 'var(' + x + ')' : x; document.body.appendChild(p); const c = getComputedStyle(p).color; p.remove(); return c; };
window.__vfF = { reponse: null, statut: 503, delai: 0, reqs: [] };
window.__vfG = { reponse: null, statut: 503, delai: 0, reqs: [] };
window.__vfS = { signal: { missions: [{ nom: 'Mission un', fichier: 'm1.md', phaseKey: '74' }, { nom: 'Mission deux', fichier: 'm2.md', phaseKey: null }],
  phases: [{ key: '74', n: 74, ws: null, nom: "L'équipe dans le temps" }] } };
window.__tous = []; window.__sp = { sur: [], appels: [] }; window.__surOnglet = [];
const appelant = () => String(new Error().stack).split('\n')[3] || '';
{ let t; Object.defineProperty(window, 'VFGitTiroir', { configurable: true, get: () => t,
  set: (x) => { t = x && typeof x.ouvrirSur === 'function' ? Object.freeze(Object.assign({}, x, {
    ouvrir: (...a) => { window.__sp.appels.push(['tiroir.ouvrir', appelant()]); return x.ouvrir(...a); },
    ouvrirSur: (s) => { window.__sp.sur.push(s); return x.ouvrirSur(s); } })) : x; } }); }
{ let v; Object.defineProperty(window, 'VFGitVolet', { configurable: true, get: () => v,
  set: (x) => { v = x && typeof x.ouvrir === 'function' ? Object.freeze(Object.assign({}, x, {
    ouvrir: (...a) => { window.__sp.appels.push(['volet.ouvrir', appelant()]); return x.ouvrir(...a); } })) : x; } }); }
{ let c; Object.defineProperty(window, 'VF_COQUILLE', { configurable: true, get: () => c,
  set: (x) => { c = x && typeof x.surOnglet === 'function' ? Object.freeze(Object.assign({}, x, { surOnglet: (r, o) => { window.__surOnglet.push(o && o.cle); return x.surOnglet(r, o); } })) : x; } }); }
{ const f0 = window.fetch.bind(window);
  const rep = (st, o) => new Response(JSON.stringify(o), { status: st, headers: { 'content-type': 'application/json' } });
  const apres = (ms, f) => new Promise((ok) => setTimeout(() => ok(f()), ms || 0));
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url; window.__tous.push(url);
    if (/^\/api\/vf\/frise(\?|$)/.test(url)) {
      const F = window.__vfF, c = F.reponse ? JSON.parse(JSON.stringify(F.reponse)) : {}; F.reqs.push({ url });
      c.at = new Date().toISOString();
      const q = new URLSearchParams(url.split('?')[1] || '');
      if (q.get('jusqua') && c.voies) { const J0 = c.jusqua, J = Number(q.get('jusqua'));
        for (const v of c.voies) { if (v.fin === J0) v.fin = J; for (const s of v.segments || []) if (s[1] === J0) s[1] = J; }
        c.depuis = Number(q.get('depuis')); c.jusqua = J; }
      return apres(F.delai, () => rep(F.statut, F.statut === 200 ? c : { erreur: 'indisponible' })); }
    if (/^\/api\/vf\/git(\?|$)/.test(url)) { const G = window.__vfG; G.reqs.push(url);
      return apres(G.delai, () => rep(G.statut, G.statut === 200 ? G.reponse : { erreur: 'indisponible' })); }
    if (/^\/api\/vf\/state(\?|$)/.test(url)) return f0(u, i).then((r) => r.json()).then((j) => rep(200, Object.assign({}, j, { signal: Object.assign({}, j.signal, window.__vfS.signal) })));
    const m = /^\/api\/vf\/git\/commit(\?|$)/.exec(url);
    if (m) { const sha = decodeURIComponent((/sha=([^&]*)/.exec(url) || [])[1] || '');
      if (window.__vfDet.erreurs[sha]) return Promise.resolve(rep(window.__vfDet.erreurs[sha], { erreur: 'commit-inconnu' }));
      return Promise.resolve(rep(200, Object.assign({}, window.__vfDet.commit, { h: sha, h7: sha.slice(0, 7),
        commandes: { show: 'git show --stat --end-of-options ' + sha.slice(0, 7), detacher: 'git switch --detach --end-of-options ' + sha.slice(0, 7) } }))); }
    return f0(u, i); }; }
JS
window.__vfDet.erreurs = {};
JS2
export VF_PRE="$AUX/pre.js"

# ---------- aides communes aux scénarios ----------
cat > "$AUX/commun.mjs" <<'JS'
export const NB = ' ';
export const sha = (i) => String(i).padStart(2, '0').repeat(20);
export const L = (n) => ['locale', n];
export const DS = (n) => ['distante', n];
// [indice du commit, parents, minutes avant maintenant, refs] ; 7 branches (main, 4 locales, 2 distantes), 2 commits sans branche, 11 commits sur 1 h 30
export const RANG = [[3, [2], 10, [L('main')]], [2, [1], 11], [1, [], 40], [11, [1], 15, [L('feat/a')]], [12, [1], 25, [L('feat/b')]], [13, [1], 30, [L('feat/c')]],
  [14, [1], 35, [L('feat/d')]], [15, [1], 50, [DS('origin/feat/e')]], [16, [1], 55, [DS('origin/feat/f')]], [21, [1], 60], [22, [1], 65]];
export async function poserGit(h, o = {}) {
  const now = await h.s.ev('Date.now()');
  const at = (min) => Math.floor((now - min * h.MIN) / 1000) * 1000, te = o.teintes || [0];
  const rangees = (o.rangees || RANG).map(([i, ps, min, refs = []], k) => ({ ...h.FAB.rangee(sha(i), ps.map(sha), at(min) / 1000, refs.map(([t, n]) => h.FAB.tete(t, n))), teinte: te[k % te.length] }));
  const rep = o.brut ?? h.FAB.git({ rangees, tronque: !!o.tronque, now });
  await h.s.ev(`Object.assign(window.__vfG, { reponse: ${JSON.stringify(rep)}, statut: ${o.statut ?? 200}, delai: ${o.delai ?? 0} })`);
  return { now, at };
}
export async function monterD(h, o = {}) {
  const { git, ...reste } = o;
  await h.monter({ ...reste, vue: 'regie' });
  const T = await poserGit(h, git || {});
  await h.ev("window.__emit('etat', { seq: 1 })");
  await h.attendre("window.VF_ETAT.lire('etat') !== null", 'état lu');
  await h.choisir('Frise'); await h.attendreFrise();
  return T;
}
export const radio = (h, libelle) => h.ev((l) => { const r = [...document.querySelectorAll('.vf-cout [role=radio]')].find((x) => x.textContent === l); if (r) r.click(); return !!r; }, libelle);
// voies du coût : totaux connus (entrée 221 000, sortie 43 500, cache lu 1 800 000, cache écrit 66 000, travail 14 700 s dont 1 500 s à vous attendre), deux agents au travail maintenant
export const voiesCout = (now, F) => {
  const d = (m) => now - m * F.MIN, j = (e, s, cl, cc) => ({ entree: e, sortie: s, cacheLu: cl, cacheCree: cc, contexteMax: 40000, contexteDernier: 30000 });
  const du = (t, a) => ({ travailS: t, attenteHumainS: a, attenteAgentsS: 0, reposS: 0, silenceS: 0 });
  return [
    F.voie({ id: 'sess-1', kind: 'session', role: null, depth: null, debut: d(80), fin: now, segments: [[d(80), d(60), 'travail'], [d(60), now, 'repos']], jetons: j(168000, 30000, 1000000, 50000), durees: du(7500, 0) }),
    F.voie({ id: 'mg-1', parent: 'sess-1', role: 'vf-dev-manager', dispatchA: d(70), debut: d(70), fin: now, segments: [[d(70), now, 'attend-agents']], rattachement: { dag: 'm1.md', noeud: null, source: 'enfants' }, jetons: j(20000, 5000, 500000, 10000), durees: du(720, 0) }),
    F.voie({ id: 'wk-1', parent: 'mg-1', depth: 2, debut: d(65), fin: now, segments: [[d(65), now, 'travail']], rattachement: { dag: 'm1.md', noeud: 'n1', source: 'registre' }, jetons: j(15000, 4000, 200000, 5000), durees: du(3000, 0) }),
    F.voie({ id: 'wk-2', parent: 'mg-1', depth: 2, debut: d(50), fin: d(20), attend: true, segments: [[d(50), d(20), 'travail']], rattachement: { dag: 'm1.md', noeud: 'n2', source: 'mandat' }, jetons: j(5000, 2000, 100000, 1000), durees: du(2400, 1500) }),
    F.voie({ id: 'wk-3', parent: 'sess-1', depth: 1, debut: d(30), fin: now, segments: [[d(30), now, 'travail']], rattachement: { dag: 'm2.md', noeud: 'n1', source: 'mandat' }, jetons: j(3000, 1000, 0, 0), durees: du(900, 0) }),
    F.voie({ id: 'hw-1', parent: 'sess-1', debut: d(45), fin: d(44), fini: true, segments: [[d(45), d(44), 'travail']], jetons: j(8000, 1000, 0, 0), durees: du(60, 0) }),
    F.voie({ id: 'lf-1', parent: 'sess-1', debut: d(95), fin: d(85), fini: true, segments: [[d(95), d(85), 'travail']], arbre: 'wt-a', jetons: j(2000, 500, 0, 0), durees: du(120, 0) }),
  ];
};
export const TOTAUX = [14700, 1500, 221000, 43500, 1800000, 66000];
JS

# ---------- scénarios ----------
cat > "$AUX/d1.mjs" <<'JS'
import { monterD, sha, NB, L } from './commun.mjs';
export const ids = ['D1', 'D2'];
const lire = () => (document => {
  const row = document.querySelector('.vf-frise-rang-depot'), c = row.querySelector('.vf-frise-c'), p = row.querySelector('.vf-frise-p'), t = (e) => (e ? e.textContent : null);
  const lane = (n) => [...p.querySelectorAll('.vf-depot-piste[data-branche]')].find((e) => e.getAttribute('data-branche') === n);
  const bs = (l) => (l ? [...l.querySelectorAll('.vf-depot-commit')] : []), tous = [...document.querySelectorAll('.vf-depot-commit')];
  let recouv = 0;
  for (const l of p.querySelectorAll('.vf-depot-piste')) { const r = bs(l).map((b) => b.getBoundingClientRect());
    for (let i = 0; i < r.length; i++) for (let j = i + 1; j < r.length; j++) if (r[i].left < r[j].right && r[j].left < r[i].right) recouv++; }
  const plus = c.querySelector('.vf-depot-plus'), autres = c.querySelector('.vf-depot-autres'), pa = p.querySelector('.vf-depot-autres');
  const poly = tous.length ? tous[0].querySelector('.vf-frise-losange') : null;
  return { titre: t(c.querySelector('.vf-depot-titre')), compte: t(c.querySelector('.vf-depot-compte')),
    noms: [...c.querySelectorAll('.vf-depot-voie[data-branche]')].map((e) => e.getAttribute('data-branche')),
    plus: plus ? [plus.textContent, plus.getAttribute('aria-expanded'), plus.getAttribute('aria-label')] : null,
    autres: autres ? [t(autres.querySelector('.vf-depot-nom')), t(autres.querySelector('.vf-depot-n2'))] : null, autresBoutons: bs(pa).length,
    dansVoies: document.querySelectorAll('.vf-frise-voies .vf-depot-commit, .vf-frise-pistes .vf-depot-commit, .vf-frise-pistes [data-evt=commit]').length,
    tags: [...new Set(tous.map((b) => b.tagName))], mini: Math.min(...tous.map((b) => Math.min(b.getBoundingClientRect().width, b.getBoundingClientRect().height))),
    feat: bs(lane('feat/a')).map((b) => b.getAttribute('aria-label')), main: bs(lane('main')).map((b) => [b.getAttribute('aria-label'), b.title, t(b.querySelector('.vf-depot-n'))]),
    decal: [...c.querySelectorAll('.vf-depot-voie')].map((l, i) => Math.abs(l.getBoundingClientRect().top - p.querySelectorAll('.vf-depot-voie')[i].getBoundingClientRect().top)),
    recouv, fill: poly ? getComputedStyle(poly).fill : null, texte2: window.__couleur('--text-2'), recent: window.__couleur('--recent'), nb: tous.length };
})(document);
export default async function (h) {
  let T;
  await h.section('D1', async () => {
    T = await monterD(h, {});
    const m = await h.ev(lire);
    h.egal('D1', 'colonne : « Dépôt » puis « 11 commits sur 1 h 30 » (fenêtre écrite)', [m.titre, m.compte], ['Dépôt', `11 commits sur 1${NB}h${NB}30`]);
    h.egal('D1', 'une sous-voie par branche, la base d\'abord : quatre visibles', m.noms, ['main', 'feat/a', 'feat/b', 'feat/c']);
    h.egal('D1', '« + 3 branches » (aria-expanded faux, nom accessible qui commence par le texte visible)', m.plus, ['+ 3 branches', 'false', `+ 3 branches${NB}: afficher les autres branches du dépôt`]);
    h.egal('D1', 'dernière ligne « Autres commits (branches fusionnées ou sans nom) » comptée, ses deux commits dessinés alors que les branches sont repliées', [m.autres, m.autresBoutons],
      [['Autres commits (branches fusionnées ou sans nom)', '2 commits'], 2]);
    h.egal('D1', 'aucun losange de commit dans une voie d\'agent ni dans les pistes', m.dansVoies, 0);
    h.egal('D1', 'chaque commit est un bouton d\'au moins 24 x 24, aucune zone de saisie n\'en recouvre une autre', [m.tags, m.mini >= 24, m.recouv], [['BUTTON'], true, 0]);
    const h7 = (i) => sha(i).slice(0, 7), re = (x) => new RegExp(x);
    h.sonde('D1', 'nom accessible d\'un commit : « Commit 1111111, branche feat/a, 14 h 32. Ouvrir dans le tiroir Git »',
      m.feat.length === 1 && re(`^Commit ${h7(11)}, branche feat/a, \\d{1,2}${NB}h \\d{2}\\. Ouvrir dans le tiroir Git$`).test(m.feat[0]), JSON.stringify(m.feat));
    const g = m.main.find((x) => x[0].startsWith('2 commits'));
    h.sonde('D1', 'deux commits proches : un seul bouton, le nombre « 2 », nom accessible qui LISTE les deux (le plus récent d\'abord), title identique',
      m.main.length === 2 && !!g && g[2] === '2' && g[0] === g[1]
      && re(`^2 commits, de \\d{1,2}${NB}h \\d{2} à \\d{1,2}${NB}h \\d{2}, branche main${NB}: ${h7(3)}, ${h7(2)}\\. Ouvrir le plus récent dans le tiroir Git$`).test(g[0]), JSON.stringify(m.main));
    h.sonde('D1', 'la couleur résolue du losange est --text-2 et n\'est jamais --recent', !!m.fill && m.fill === m.texte2 && m.fill !== m.recent, JSON.stringify([m.fill, m.texte2, m.recent]));
    h.sonde('D1', 'chaque sous-voie de la colonne est alignée sur sa piste (écart < 1 px)', m.decal.length === 5 && m.decal.every((d) => d < 1), JSON.stringify(m.decal));
    await h.ev(() => document.querySelector('.vf-depot-plus').click());
    const e = await h.ev(lire);
    h.egal('D1', '« + 3 branches » déplié : sept branches, « Replier les branches », « Autres commits » toujours là', [e.noms.length, e.plus && e.plus.slice(0, 2), e.autres && e.autres[1]],
      [7, ['Replier les branches', 'true'], '2 commits']);
    h.egal('D1', 'ordre : la base, les locales, puis les distantes', e.noms, ['main', 'feat/a', 'feat/b', 'feat/c', 'feat/d', 'origin/feat/e', 'origin/feat/f']);
    await monterD(h, { coarse: true });
    const k = await h.ev(lire);
    h.sonde('D1', 'pointeur grossier : chaque commit mesure au moins 44 x 44, sans recouvrement', k.nb > 0 && k.mini >= 44 && k.recouv === 0, JSON.stringify([k.mini, k.recouv]));
  });
  await h.section('D2', async () => {
    T = await monterD(h, {});
    const m = await h.ev((a, d) => { const F = window.__vfFrise.donnees(), x = F.ctx.x, p = document.querySelector('.vf-frise-rang-depot .vf-frise-p').getBoundingClientRect();
      const centre = (n) => { const r = document.querySelector('.vf-depot-piste[data-branche="' + n + '"] .vf-depot-commit').getBoundingClientRect(); return r.left + r.width / 2 - p.left; };
      return { a: [centre('feat/a'), x(a)], d: [centre('feat/c'), x(d)], echelle: (x(F.jusqua) - x(F.depuis)) / (F.jusqua - F.depuis), ta: a, td: d };
    }, T.at(15), T.at(30));
    h.sonde('D2', 'abscisse d\'un commit posée à la milliseconde de son `at` en secondes (aucun écart d\'un facteur 1 000)', Math.abs(m.a[0] - m.a[1]) < 1.5 && Math.abs(m.d[0] - m.d[1]) < 1.5, JSON.stringify([m.a, m.d]));
    const pente = (m.a[0] - m.d[0]) / (m.ta - m.td);
    h.sonde('D2', 'l\'échelle mesurée dans le DOM entre deux commits est celle de la fenêtre (15 min = 900 000 ms)', Math.abs(pente / m.echelle - 1) < 0.02, JSON.stringify([pente, m.echelle]));
    await monterD(h, { git: { rangees: [[1, [], 0, [L('main')]], [2, [1], 1, [L('feat/a')]]] } });
    const bord = await h.ev(() => { const p = document.querySelector('.vf-frise-rang-depot .vf-frise-p').getBoundingClientRect(), d = document.querySelector('.vf-frise-defil');
      return { hors: [...document.querySelectorAll('.vf-depot-commit')].filter((b) => b.getBoundingClientRect().right > p.right + 0.5 || b.getBoundingClientRect().left < p.left - 0.5).length, n: document.querySelectorAll('.vf-depot-commit').length,
        defil: d.scrollWidth <= d.clientWidth || Math.abs(d.scrollLeft - (d.scrollWidth - d.clientWidth)) <= 1 }; });
    h.sonde('D2', 'un commit à l\'instant « maintenant » : sa zone de saisie reste dans la piste, le défilement ne déborde pas', bord.n === 2 && bord.hors === 0 && bord.defil, JSON.stringify(bord));
  });
}
JS
cat > "$AUX/d3.mjs" <<'JS'
import { monterD, poserGit, NB, L } from './commun.mjs';
export const ids = ['D3'];
const lire = () => ((document) => {
  const row = document.querySelector('.vf-frise-rang-depot'), c = row.querySelector('.vf-frise-c'), p = row.querySelector('.vf-frise-p'), t = (e) => (e ? e.textContent : null);
  return { compte: t(c.querySelector('.vf-depot-compte')), mention: t(c.querySelector('.vf-depot-mention')), filets: [...p.querySelectorAll('.vf-depot-filet')].map((e) => parseFloat(e.style.left)),
    noms: [...c.querySelectorAll('.vf-depot-voie[data-branche]')].map((e) => e.getAttribute('data-branche')), nb: p.querySelectorAll('.vf-depot-commit').length, etat: t(p.querySelector('.vf-depot-etat .vf-depot-texte')),
    busy: row.getAttribute('aria-busy'), reessayer: [...row.querySelectorAll('button')].some((b) => b.textContent === 'Réessayer'), voies: document.querySelectorAll('.vf-frise-voie').length,
    vieux: /60 derniers commits|Dépôt incomplet avant/.test(document.body.textContent) };
})(document);
const TROU = [[42, [41], 10, [L('main')]], [41, [99], 20], [43, [], 50, [L('feat/old')]], [44, [], 200, [L('feat/older')]]];
export default async function (h) {
  const hr = (ms) => h.ev((x) => { const d = new Date(x); return d.getHours() + ' h ' + String(d.getMinutes()).padStart(2, '0'); }, ms);
  const win = `1${NB}h${NB}30`;
  await h.section('D3', async () => {
    let T = await monterD(h, { git: { rangees: TROU, tronque: true } });
    let m = await h.ev(lire);
    const x20 = await h.ev((ms) => window.__vfFrise.donnees().ctx.x(ms), T.at(20));
    h.egal('D3', 'marche tronquée, trou topologique (une rangée récente dont un parent n\'est pas lu, le plus ancien commit lu est antérieur à la fenêtre) : « Dépôt peut-être incomplet avant HH h MM »',
      m.mention, `Dépôt peut-être incomplet avant ${await hr(T.at(20))}`);
    h.sonde('D3', 'filet vertical à cet instant, aucun commit dessiné avant (2 commits sur 1 h 30, une seule branche)', m.filets.length === 1 && Math.abs(m.filets[0] - x20) < 1.5 && m.compte === `2 commits sur ${win}`
      && m.noms.join() === 'main', JSON.stringify([m.filets, x20, m.compte, m.noms]));
    h.egal('D3', 'aucune ancienne forme (« 60 derniers commits », « Dépôt incomplet avant »)', m.vieux, false);
    T = await monterD(h, { git: { rangees: TROU, tronque: false } });
    m = await h.ev(lire);
    h.sonde('D3', 'même marche non tronquée : texte et filet absents, le commit de 50 min est dessiné (3 commits)', m.mention === null && m.filets.length === 0 && m.compte === `3 commits sur ${win}`, JSON.stringify(m));
    await monterD(h, { git: { rangees: [[51, [], 200, [L('main')]]], tronque: false } });
    m = await h.ev(lire);
    h.egal('D3', 'vide : « Aucun commit sur 1 h 30 », colonne « 0 commit sur 1 h 30 », aucune sous-voie', [m.etat, m.compte, m.noms.length, m.nb], [`Aucun commit sur ${win}`, `0 commit sur ${win}`, 0, 0]);
    await monterD(h, { git: { statut: 500 } });
    m = await h.ev(lire);
    h.sonde('D3', 'échec : « Le dépôt n\'a pas pu être lu. » et « Réessayer », colonne « Dépôt » seule, le reste de la frise intact', m.etat === 'Le dépôt n\'a pas pu être lu.' && m.reessayer
      && m.compte === null && m.voies > 0, JSON.stringify(m));
    await poserGit(h, {});
    await h.ev(() => [...document.querySelectorAll('.vf-frise-rang-depot button')].find((b) => b.textContent === 'Réessayer').click());
    await h.attendre("document.querySelectorAll('.vf-frise-rang-depot .vf-depot-voie[data-branche]').length > 0", 'dépôt relu', 8000);
    m = await h.ev(lire);
    h.sonde('D3', '« Réessayer » : nouvelle lecture, les sous-voies reviennent', m.noms.length === 4 && m.etat === null, JSON.stringify(m));
    await monterD(h, { git: { delai: 4000 } });
    await h.attendre("document.querySelector('.vf-frise-rang-depot').getAttribute('aria-busy') === 'true'", 'dépôt en chargement', 8000);
    m = await h.ev(lire);
    h.sonde('D3', 'chargement (au-delà de 150 ms) : aria-busy, « Lecture du dépôt », colonne « Dépôt » seule', m.busy === 'true' && m.etat === 'Lecture du dépôt' && m.compte === null, JSON.stringify(m));
    await h.attendre("document.querySelectorAll('.vf-frise-rang-depot .vf-depot-voie[data-branche]').length > 0", 'fin du chargement', 12000);
  });
}
JS
cat > "$AUX/d4.mjs" <<'JS'
import { monterD, sha } from './commun.mjs';
export const ids = ['D4'];
const RANG = [[11, [], 15, [['locale', 'feat/a']]], [12, [], 25, [['locale', 'feat/b']]], [13, [], 30, [['locale', 'feat/c']]], ['zz', [], 35, [['locale', 'feat/z']]]];
const bouton = (h, n) => h.ev((b) => { const x = document.querySelector('.vf-depot-piste[data-branche="' + b + '"] .vf-depot-commit'); if (x) x.focus(); return !!x; }, n);
export default async function (h) {
  await h.section('D4', async () => {
    await monterD(h, { git: { rangees: RANG } });
    const sp = () => h.ev(() => ({ sur: window.__sp.sur.slice(), appels: window.__sp.appels.slice(), errs: window.__errs.slice(), details: window.__tous.filter((u) => /git\/commit/.test(u)).length }));
    await bouton(h, 'feat/a'); await h.ev(() => document.activeElement.click());
    await h.attendre(`!!document.querySelector('[role=region][aria-label="Détail du commit ${sha(11).slice(0, 7)}"]')`, 'région du détail', 8000);
    let s = await sp();
    h.egal('D4', 'un clic appelle window.VFGitTiroir.ouvrirSur(sha) et la région « Détail du commit <sha> » est présente (tiroir Git de la 80, non factice)', s.sur, [sha(11)]);
    h.egal('D4', 'ni VFGitTiroir.ouvrir ni VFGitVolet.ouvrir ne sont appelés par la 74', s.appels.filter((a) => /74-vf-/.test(a[1])), []);
    await h.ev(() => window.VFGitTiroir.fermer());
    await bouton(h, 'feat/b'); await h.touche('Enter', 'Enter', 13, '\r');
    await h.attendre(`!!document.querySelector('[role=region][aria-label="Détail du commit ${sha(12).slice(0, 7)}"]')`, 'région du détail (Entrée)', 8000);
    s = await sp();
    h.egal('D4', 'Entrée sur un commit : même chemin, ouvrirSur(sha)', s.sur, [sha(11), sha(12)]);
    await h.ev((x) => { window.__vfDet.erreurs[x] = 404; }, sha(13));
    await bouton(h, 'feat/c'); await h.ev(() => document.activeElement.click());
    await h.attendre("(document.querySelector('.vf-frise-live') || {}).textContent === \"Ce commit n'est pas disponible dans le tiroir Git.\"", 'annonce', 8000);
    s = await sp();
    h.egal('D4', 'ouvrirSur rend false : l\'annonce de la région aria-live est dite, aucune erreur levée', [s.sur.length, s.errs], [3, []]);
    const n0 = s.sur.length, d0 = s.details;
    await bouton(h, 'feat/z'); await h.ev(() => document.activeElement.click()); await h.pause(500);
    s = await sp();
    h.egal('D4', 'un sha non hexadécimal ne déclenche aucun appel de ouvrirSur ni requête de détail', [s.sur.length, s.details], [n0, d0]);
    await h.ev(() => Object.defineProperty(window, 'VFGitTiroir', { configurable: true, value: { ouvrir() {} } }));
    await h.changer(() => h.radio('6 h'));
    const t = await h.ev(() => [...document.querySelectorAll('.vf-depot-commit')].map((b) => [b.tagName, b.getAttribute('aria-label')]));
    h.sonde('D4', 'sans ouvrirSur : aucun commit n\'est un bouton, aucun nom accessible ne dit « Ouvrir dans le tiroir Git »', t.length > 0 && t.every((x) => x[0] !== 'BUTTON' && !/Ouvrir/.test(x[1])), JSON.stringify(t));
  });
}
JS
cat > "$AUX/d5.mjs" <<'JS'
import { monterD, poserGit } from './commun.mjs';
export const ids = ['D5', 'D5b'];
const gits = (h) => h.ev(() => window.__vfG.reqs.length);
export default async function (h) {
  await h.section('D5b', async () => {
    await monterD(h, { git: { teintes: [10, 200] } });
    await h.pause(1500);
    h.egal('D5b', 'au montage : exactement une requête /api/vf/git', await gits(h), 1);
    const f0 = (await h.reqs()).length;
    for (let i = 1; i <= 5; i++) { await h.emettre(i); await h.pause(300); }
    await h.attendreValeur(async () => (await h.reqs()).length, (n) => n > f0, { max: 8000 });
    await h.pause(2000);
    h.sonde('D5b', 'témoin : les événements frise ont bien déclenché des lectures de la route de frise', (await h.reqs()).length > f0, String((await h.reqs()).length - f0));
    h.egal('D5b', 'cinq événements frise : aucune requête /api/vf/git de plus', await gits(h), 1);
    await h.ev(() => window.__emit('git', { seq: 2, at: Date.now(), sig: 'b' }));
    await h.attendreValeur(() => gits(h), (n) => n >= 2, { max: 8000 });
    await h.pause(1200);
    h.egal('D5b', 'un événement git : exactement une requête de plus', await gits(h), 2);
  });
  await h.section('D5', async () => {
    await monterD(h, { git: { teintes: [10, 200] } });
    const html = () => h.ev(() => document.querySelector('.vf-frise-rang-depot').outerHTML.replace(/ style="[^"]*"/g, ''));
    const a = await html();
    const f = await h.reqs('/api/vf/frise'), nf = (await h.reqs()).length;
    h.sonde('D5', 'aucune requête de la route de frise ne sert aux commits (témoin : la frise a bien été lue)', nf > 0 && f.length >= nf && (await h.ev(() => window.__tous.filter((u) => /\/api\/vf\/frise/.test(u) && /git|commit/.test(u)).length)) === 0, String(f.length));
    h.egal('D5', 'aucun commit dans une voie d\'agent, aucune voie ne porte de commit', await h.ev(() => [document.querySelectorAll('.vf-frise-voie .vf-depot-commit').length,
      window.__vfFrise.donnees().frise.voies.some((v) => 'commits' in v || 'commit' in v)]), [0, false]);
    await poserGit(h, { teintes: [250, 3, 77] });
    await h.ev(() => window.__emit('git', { seq: 9, at: Date.now(), sig: 'z' }));
    await h.attendreValeur(() => gits(h), (n) => n >= 2, { max: 8000 });
    await h.pause(600);
    h.sonde('D5', 'la `teinte` de la route n\'est pas lue : changer toutes les teintes ne change aucun octet du bandeau (hors positions en pixels)', (await html()) === a, 'html différent');
  });
}
JS
cat > "$AUX/d6.mjs" <<'JS'
import { monterD, radio, voiesCout, TOTAUX, NB } from './commun.mjs';
export const ids = ['D6', 'D7', 'D8', 'D9', 'D10'];
const lignes = (h) => h.ev(() => [...document.querySelectorAll('.vf-cout tbody tr')].map((tr) => { const q = (s) => tr.querySelector(s), b = q('button[aria-expanded]');
  return { cls: tr.className, nom: (q('.vf-cout-nom') || {}).textContent, sous: q('.vf-cout-sous') ? q('.vf-cout-sous').textContent : null, exp: b ? b.getAttribute('aria-expanded') : null,
    v: [...tr.querySelectorAll('td')].map((td) => (td.hasAttribute('data-v') ? Number(td.getAttribute('data-v')) : null)), pad: parseFloat(getComputedStyle(q('th')).paddingLeft) }; }));
const haut = (ls) => ls.filter((l) => !/vf-cout-phase|vf-cout-total/.test(l.cls));
const total = (ls) => ls.find((l) => /vf-cout-total/.test(l.cls));
const somme = (ls) => TOTAUX.map((_, k) => ls.reduce((s, l) => s + (l.v[k] ?? 0), 0));
export default async function (h) {
  const win = `1${NB}h${NB}30`;
  await h.section('D6', async () => {
    await monterD(h, { voies: voiesCout });
    const s = await h.ev(() => { const p = document.querySelector('.vf-frise-lignes .vf-frise-synthese'), a = p && p.querySelector('a');
      return { txt: p ? p.textContent : null, lien: a ? a.textContent : null }; });
    const attendu = `Sur les dernières ${win}${NB}: 2 agents au travail maintenant, 4${NB}h 05 au travail dont 25${NB}min à vous attendre. Jetons sur les dernières 24${NB}h${NB}: 221${NB}k en entrée, 43,5${NB}k en sortie.`;
    h.egal('D6', 'synthèse : fenêtre écrite, agents au travail maintenant, durées, jetons sur les dernières 24 h', (s.txt || '').slice(0, attendu.length), attendu);
    h.egal('D6', 'suivie du lien « Détail du coût »', s.lien, 'Détail du coût');
    await h.ev(() => document.querySelector('.vf-frise-synthese a').click());
    const f = await h.ev(() => ({ id: document.activeElement.id, tab: document.activeElement.getAttribute('tabindex'), txt: document.activeElement.textContent }));
    h.egal('D6', 'le lien place le focus sur le titre de la section (tabindex -1)', [f.id, f.tab, f.txt.startsWith('Coût sur les dernières')], ['vf-cout-titre', '-1', true]);
  });
  await h.section('D7', async () => {
    const s = await h.ev(() => { const c = document.querySelector('.vf-cout'), t = c.querySelector('h3'), cap = c.querySelector('table > caption');
      return { h3: t.textContent, ls: getComputedStyle(t).letterSpacing, fs: getComputedStyle(t).fontSize, sous: c.querySelector('.vf-cout-soustitre').textContent, cap: cap ? cap.textContent : null,
        ths: [...c.querySelectorAll('thead tr:last-child th')].map((e) => e.textContent), coiffes: [...c.querySelectorAll('thead tr:first-child th')].map((e) => [e.textContent, e.colSpan]),
        radios: [...c.querySelectorAll('[role=radiogroup] [role=radio]')].map((r) => [r.textContent, r.getAttribute('aria-checked')]) }; });
    h.egal('D7', 'intertitre dynamique « Coût sur les dernières 1 h 30 », interlettrage -0,015em', [s.h3, s.ls], [`Coût sur les dernières ${win}`, `${(-0.015 * parseFloat(s.fs)).toFixed(3).replace(/0+$/, '')}px`]);
    h.egal('D7', 'sous-titre exact', s.sous, `Durées lues sur la fenêtre, jetons sur les dernières 24${NB}h (horizon de l'index). Rien n'est estimé.`);
    h.egal('D7', '<table> avec <caption> et les six colonnes', [s.cap, s.ths], [`Coût sur les dernières ${win}`, ['Mission et phase', 'Au travail', 'À vous attendre', 'Entrée', 'Sortie', 'Cache lu', 'Cache écrit']]);
    h.egal('D7', 'quatre colonnes de jetons coiffées de « Jetons, sur les dernières 24 h », deux colonnes de durée de la fenêtre', s.coiffes,
      [['', 1], [`Durées, sur les dernières ${win}`, 2], [`Jetons, sur les dernières 24${NB}h`, 4]]);
    h.egal('D7', 'choix « Regrouper par » : Agent, Mission et phase (défaut), Étage', s.radios, [['Agent', 'false'], ['Mission et phase', 'true'], ['Étage', 'false']]);
    await h.changer(() => h.radio('6 h'));
    h.egal('D7', 'l\'intertitre suit la fenêtre : « Coût sur les dernières 6 h »', await h.ev(() => document.querySelector('.vf-cout h3').textContent), `Coût sur les dernières 6${NB}h`);
    await h.changer(() => h.radio('1 h 30'));
  });
  await h.section('D8', async () => {
    let ls = await lignes(h);
    const h1 = haut(ls);
    h.egal('D8', 'Mission et phase : une ligne par mission, « Hors mission » dernière (tri « Au travail » décroissant hors cette ligne)', h1.map((l) => l.nom), ['Mission un', 'Mission deux', 'Hors mission']);
    h.egal('D8', '« Hors mission » : ni dépliable ni découpée, note « agents sans nœud de plan rattaché »', [h1[2].exp, h1[2].sous], [null, 'agents sans nœud de plan rattaché']);
    h.egal('D8', 'un manager rattaché par ses agents compte dans sa mission (entrée 40 000 = 20 000 + 15 000 + 5 000)', h1[0].v[2], 40000);
    h.egal('D8', '« Hors mission » somme les agents sans nœud (tête comprise), jamais répartis dans les missions', h1[2].v[2], 178000);
    h.egal('D8', 'une mission sans clé de phase n\'a pas de bouton de dépli', h1[1].exp, null);
    h.egal('D8', 'Mission et phase : « Total » égal à la somme des lignes (hors mission comprise)', [total(ls).v, somme(h1)], [TOTAUX, TOTAUX]);
    await h.ev(() => document.querySelector('.vf-cout button[aria-expanded=false]').click());
    ls = await lignes(h);
    const ph = ls.find((l) => /vf-cout-phase/.test(l.cls)), mi = ls.find((l) => l.nom === 'Mission un');
    h.sonde('D8', 'les phases se déplient (aria-expanded), en retrait, avec les valeurs de la mission (jointure par phaseKey)', !!ph && mi.exp === 'true' && ph.nom === 'L\'équipe dans le temps' && ph.pad > mi.pad
      && ph.v.join() === mi.v.join(), JSON.stringify([ph, mi.exp]));
    await radio(h, 'Étage');
    ls = await lignes(h);
    h.egal('D8', 'Étage : Têtes, Managers, Workers (tri « Au travail » décroissant) ; Total identique', [haut(ls).map((l) => l.nom), total(ls).v], [['Têtes', 'Workers', 'Managers'], TOTAUX]);
    h.egal('D8', 'Étage : somme des lignes = Total', somme(haut(ls)), TOTAUX);
    await radio(h, 'Agent');
    ls = await lignes(h);
    const ag = haut(ls), tri = ag.map((l) => l.v[0]);
    h.egal('D8', 'Agent : une ligne par voie, tri décroissant, Total identique', [ag.length, tri.every((x, i) => i === 0 || tri[i - 1] >= x), total(ls).v], [7, true, TOTAUX]);
    h.egal('D8', 'Agent : la seconde ligne des agents sans mission dit « hors mission » (tête, hw-1, lf-1)', ag.filter((l) => l.sous === 'hors mission').length, 3);
    h.egal('D8', 'Agent : somme des lignes = Total', somme(ag), TOTAUX);
    await radio(h, 'Mission et phase');
  });
  await h.section('D9', async () => {
    const t = await h.ev(() => { const r = document.querySelector('.vf-frise'), surf = window.__couleur('--surface'), t = document.createTreeWalker(r, NodeFilter.SHOW_TEXT), tx = [];
      while (t.nextNode()) tx.push(t.currentNode.textContent);
      const fonds = [...document.querySelectorAll('.vf-cout table, .vf-cout tr, .vf-cout th, .vf-cout td, .vf-cout caption')].map((e) => getComputedStyle(e).backgroundColor).filter((c) => c !== 'rgba(0, 0, 0, 0)' && c !== surf);
      return { txt: tx.join('|').replace("Rien n'est estimé.", ''), fonds, graph: document.querySelectorAll('.vf-cout svg, .vf-cout canvas, .vf-cout progress, .vf-cout meter').length, cellules: document.querySelectorAll('.vf-cout td').length }; });
    h.sonde('D9', 'témoin : le tableau du coût est dessiné (aucun vert à vide)', t.cellules > 0, String(t.cellules));
    h.egal('D9', 'aucun montant, devise, « euro », « tarif » ni « estimé » dans la frise et le coût', /€|\$|euro|tarif|estimé/i.test(t.txt), false);
    // « 5 h » seul est une limite ; « 5 h 46 » est une heure d'horloge (les bulles de la frise) : le test ne dépend pas de l'heure du poste
    h.egal('D9', 'aucune limite d\'abonnement (5 h, 7 j)', /(^|[^\d])5[\s ]*h(?![\s ]*\d)|7\s*j\b|abonnement/i.test(t.txt), false);
    h.egal('D9', 'aucune barre, aucune teinte dans le tableau (aucun fond hors --surface ou transparent)', [t.graph, t.fonds], [0, []]);
  });
  await h.section('D10', async () => {
    const tr = await h.ev(() => window.__tous.filter((u) => /\/api\/vf\/transcript/.test(u)).length);
    h.egal('D10', 'le journal des requêtes ne voit aucune requête de transcript : le coût ne recompte rien', tr, 0);
    const ls = await lignes(h);
    const voies = voiesCout(0, h.FAB), att = [(v) => v.durees.travailS, (v) => v.durees.attenteHumainS, (v) => v.jetons.entree, (v) => v.jetons.sortie, (v) => v.jetons.cacheLu, (v) => v.jetons.cacheCree];
    h.egal('D10', 'les totaux de la page égalent la somme entière des `jetons` et des durées de la fixture', [total(ls).v, att.map((f) => voies.reduce((s, v) => s + f(v), 0))], [TOTAUX, TOTAUX]);
  });
}
JS
cat > "$AUX/d11.mjs" <<'JS'
import { monterD, radio, voiesCout, NB } from './commun.mjs';
export const ids = ['D11'];
const cellules = (h) => h.ev(() => [...document.querySelectorAll('.vf-cout tbody tr')].map((tr) => [(tr.querySelector('.vf-cout-nom') || {}).textContent, [...tr.querySelectorAll('td')].map((td) => td.textContent)]));
export default async function (h) {
  await h.section('D11', async () => {
    await monterD(h, { voies: voiesCout });
    await radio(h, 'Agent');
    const ls = await cellules(h), par = (n) => (ls.find((l) => l[0].includes(n)) || [null, []])[1], tot = ls.find((l) => /^Total/.test(l[0]));
    h.egal('D11', 'durées : « 2 h 05 », « 12 min » avec espace insécable avant l\'unité', [par('sess-1')[0], par('mg-1')[0]], [`2${NB}h 05`, `12${NB}min`]);
    h.egal('D11', 'jetons : « 168 k », « 1,8 M », « 3,0 k » et « 8,0 k » (une décimale sous 100 k)', [par('sess-1')[2], tot[1][4], par('wk-3')[2], par('hw-1')[2]], [`168${NB}k`, `1,8${NB}M`, `3,0${NB}k`, `8,0${NB}k`]);
    const txt = await h.ev(() => [document.querySelector('.vf-frise-synthese'), document.querySelector('.vf-cout'), document.querySelector('.vf-frise-rang-depot')].map((e) => e.textContent).join('|'));
    h.egal('D11', 'aucune espace ordinaire avant : ; ! ?', /[ ][:;!?]/.test(txt), false);
    await monterD(h, { voies: (now, F) => [...voiesCout(now, F), F.voie({ id: 'wk-4', parent: 'sess-1', debut: now - 20 * F.MIN, fin: now, rattachement: { dag: 'm2.md', noeud: 'n2', source: 'mandat' },
      jetons: { entree: null, sortie: null, cacheLu: null, cacheCree: null, contexteMax: null, contexteDernier: null }, durees: { travailS: null, attenteHumainS: null, attenteAgentsS: null, reposS: null, silenceS: null } })] });
    await radio(h, 'Agent');
    const u = await cellules(h), l4 = (u.find((l) => l[0].includes('wk-4')) || [null, []])[1], t2 = u.find((l) => /^Total/.test(l[0]));
    const note = await h.ev(() => (document.querySelector('.vf-cout-note') || {}).textContent || '');
    h.sonde('D11', '« inconnu » pour une durée ou un jeton absent, jamais 0 ; la ligne est exclue du total, avec la mention du nombre d\'agents sans mesure',
      l4.length === 6 && l4.every((x) => x === 'inconnu') && t2[1][0] === `4${NB}h 05` && /1 agent sans mesure/.test(note), JSON.stringify([l4, t2 && t2[1][0], note]));
  });
}
JS
cat > "$AUX/d12.mjs" <<'JS'
import { monterD, voiesCout } from './commun.mjs';
export const ids = ['D12'];
export default async function (h) {
  await h.section('D12', async () => {
    await monterD(h, { voies: voiesCout, largeur: 390, hauteur: 844, coarse: true });
    const m = await h.ev(() => { const c = document.querySelector('.vf-cout');
      return { lignes: [...c.querySelectorAll('tbody tr')].map((tr) => getComputedStyle(tr).display), doc: document.documentElement.scrollWidth, fen: window.innerWidth, cout: c.scrollWidth, coutL: c.clientWidth,
        etiq: [...c.querySelectorAll('tbody tr:first-child td')].map((td) => td.getAttribute('data-lib')) }; });
    h.sonde('D12', 'téléphone 390 px : chaque ligne devient un bloc (ni table-row, ni table)', m.lignes.length > 0 && m.lignes.every((d) => d !== 'table-row' && d !== 'table'), JSON.stringify(m.lignes));
    h.sonde('D12', 'téléphone 390 px : aucun défilement horizontal (page et section), chaque valeur garde son libellé', m.doc <= m.fen && m.cout <= m.coutL + 1 && m.etiq.length === 6 && m.etiq.every(Boolean), JSON.stringify(m));
  });
}
JS
cat > "$AUX/d13.mjs" <<'JS'
import { monterD, radio, voiesCout, NB } from './commun.mjs';
export const ids = ['D13'];
const lire = (h) => h.ev(() => ({ syn: document.querySelector('.vf-frise-synthese').textContent, tot: (document.querySelector('.vf-cout-total .vf-cout-nom') || {}).textContent, sec: document.querySelector('.vf-cout').textContent }));
export default async function (h) {
  await h.section('D13', async () => {
    await monterD(h, { voies: voiesCout, tronque: true, voiesOmises: 37 });
    let m = await lire(h);
    h.sonde('D13', 'tronque + voiesOmises 37 : la synthèse dit « incomplet » et « 37 voies non montrées »', /incomplet/.test(m.syn) && m.syn.includes('37 voies non montrées'), m.syn);
    const totaux = [];
    for (const l of ['Mission et phase', 'Agent', 'Étage']) { await radio(h, l); totaux.push((await lire(h)).tot); }
    h.egal('D13', 'chaque ligne « Total » des trois regroupements dit « incomplet »', totaux, ['Total (incomplet)', 'Total (incomplet)', 'Total (incomplet)']);
    await monterD(h, { voies: voiesCout, tronque: true, sansOmises: true });
    m = await lire(h);
    h.sonde('D13', 'sans voiesOmises : « incomplet » seul', /incomplet/.test(m.syn) && !/voies? non montrées?/.test(m.syn), m.syn);
    await monterD(h, { voies: voiesCout, tronque: false });
    m = await lire(h);
    h.sonde('D13', 'tronque faux : le mot « incomplet » est absent de la synthèse et de la section, « Total » seul', !/incomplet/.test(m.syn + m.sec) && m.tot === 'Total', JSON.stringify([m.tot]));
  });
}
JS
cat > "$AUX/d14.mjs" <<'JS'
import { monterD, voiesCout } from './commun.mjs';
export const ids = ['D14'];
export default async function (h) {
  const lire = () => h.ev(() => ({ cout: document.querySelectorAll('.vf-cout').length, depot: document.querySelectorAll('.vf-frise-rang-depot').length, racines: document.querySelectorAll('.vf-frise').length,
    tire: document.querySelectorAll('.vf-frise-synthese a').length, ab: window.VF_ETAT.abonnes(),
    // l'arbre de la régie (Phase 73) pose son propre abonnement git : on le retranche, il n'est pas celui de la 74-07
    gitSans: window.VF_ETAT.abonnes().git - document.querySelectorAll('.vf-rg-arbres').length }));
  const ou = (n) => h.attendre(`window.VF_COQUILLE.onglet() === '${n}' && document.documentElement.dataset.vfPret === 'oui'`, `onglet ${n}`);
  await h.section('D14', async () => {
    await monterD(h, { voies: voiesCout });
    const a = await lire();
    h.egal('D14', 'témoin : un seul bandeau, une seule section, un seul abonnement git (les abonnés frise sont ceux des autres modules, jamais ceux de la 74-07)', [a.cout, a.depot, a.racines, a.tire, a.gitSans, a.ab.frise >= 1], [1, 1, 1, 1, 1, true]);
    await h.ev("window.VF_COQUILLE.chargerOnglet('code').then(() => 1)"); await ou('code');
    const loin = await h.ev(() => window.VF_ETAT.abonnes());
    // sur Code, 75-vf-activite.js abonne `git` (contrat de 75-08) : seul cet abonné reste, ceux de la régie et de la 74-07 sont partis
    h.egal('D14', 'hors de l\'onglet Équipe : plus aucun abonnement git de la régie ni de la 74-07 (reste le seul abonné de l\'activité de la 75 sur Code)', loin.git, 1);
    await h.ev("window.VF_COQUILLE.chargerOnglet('equipe').then(() => 1)"); await ou('equipe'); await h.attendreFrise();
    const b = await lire();
    await h.cycle('code'); await h.attendreFrise();
    const c = await lire();
    h.egal('D14', 'après DEUX changements d\'onglet : une seule section, un seul bandeau, aucun abonnement doublé (git, frise, etat)', [c.cout, c.depot, c.racines, c.tire, c.gitSans, c.ab.frise, c.ab.etat],
      [1, 1, 1, 1, 1, a.ab.frise, a.ab.etat]);
    h.egal('D14', 'les deux changements d\'onglet donnent le même état que le premier', [b.cout, b.depot, b.gitSans, b.ab.frise, b.ab.etat], [1, 1, 1, a.ab.frise, a.ab.etat]);
    const s = await h.ev(() => window.__surOnglet.filter((x) => /^74-vf-(frise-depot|cout)\.js$/.test(x)));
    h.sonde('D14', 'surOnglet appelé avec { cle: \'74-vf-frise-depot.js\' } et { cle: \'74-vf-cout.js\' } à chaque arrivée, jamais sans clé', s.filter((x) => x === '74-vf-frise-depot.js').length >= 3
      && s.filter((x) => x === '74-vf-cout.js').length >= 3, JSON.stringify(s));
    const m = await h.ev(() => window.__errs.slice());
    h.egal('D14', 'aucune erreur de page ni console.error pendant tout le parcours', m, []);
  });
}
JS

cat > "$AUX/d15.mjs" <<'JS'
import { monterD, poserGit, voiesCout, NB } from './commun.mjs';
export const ids = ['D15', 'D16', 'D17'];
const actif = (h) => h.ev(() => { const a = document.activeElement; return a && a !== document.body ? [a.tagName, a.getAttribute('data-foc'), a.textContent.slice(0, 30)] : null; });
const frise = async (h, n) => { const f0 = (await h.reqs()).length; await h.emettre(n); await h.attendreValeur(async () => (await h.reqs()).length, (k) => k > f0, { max: 8000 }); await h.pause(800); };
const focaliser = (h, motif, texte) => h.ev((m, t) => { const l = [...document.querySelectorAll(m)].find((x) => !t || x.textContent === t); if (l) l.focus(); return !!l && document.activeElement === l; }, motif, texte);
export default async function (h) {
  await h.section('D15', async () => {
    await monterD(h, { voies: voiesCout });
    const cas = [['bascule « Regrouper par »', '.vf-cout [role=radio][aria-checked=true]', null], ['bouton de dépli d\'une mission', '.vf-cout button[aria-expanded]', null],
      ['commit du Dépôt', '.vf-depot-commit', null], ['« + N branches »', '.vf-depot-plus', null]];
    let n = 0;
    for (const [nom, m, t] of cas) {
      const ok = await focaliser(h, m, t), av = await actif(h);
      await frise(h, ++n);
      const ap = await actif(h);
      h.sonde('D15', `${nom} : après un événement frise, le même contrôle garde le focus`, ok && !!av && JSON.stringify(av) === JSON.stringify(ap), JSON.stringify([av, ap]));
    }
    await monterD(h, { voies: voiesCout, git: { statut: 500 } });
    const ok = await focaliser(h, '.vf-frise-rang-depot button', 'Réessayer'), av = await actif(h);
    await frise(h, 9);
    const ap = await actif(h);
    h.sonde('D15', '« Réessayer » : après un événement frise, le même contrôle garde le focus', ok && !!av && JSON.stringify(av) === JSON.stringify(ap), JSON.stringify([av, ap]));
  });
  await h.section('D16', async () => {
    const lire = () => h.ev(() => ({ cout: document.querySelectorAll('.vf-cout').length, lien: document.querySelectorAll('.vf-frise-lignes a').length, td: document.querySelectorAll('.vf-cout td').length,
      carte: !!document.querySelector('.vf-frise-carte, .vf-frise-vide') }));
    await monterD(h, { voies: voiesCout });
    const a = await lire();
    await h.ev('window.__vfF.statut = 503');
    await h.changer(() => h.radio('6 h')).catch(() => 0); await h.pause(1500);
    const b = await lire();
    h.sonde('D16', 'route de frise en erreur après un premier rendu : ni tableau du coût ni « Détail du coût » de la lecture précédente', a.td > 0 && a.lien === 1 && b.carte && b.cout === 0 && b.lien === 0, JSON.stringify([a, b]));
    await monterD(h, { voies: voiesCout });
    await h.ev("window.__vfF.statut = 200; window.__vfF.reponse = Object.assign({}, window.__vfF.reponse, { voies: [] })");
    await h.changer(() => h.radio('6 h')).catch(() => 0); await h.pause(1500);
    const c = await lire();
    h.sonde('D16', 'fenêtre sans agent : ni tableau du coût ni « Détail du coût » de la lecture précédente', c.carte && c.cout === 0 && c.lien === 0, JSON.stringify(c));
  });
  await h.section('D17', async () => {
    await monterD(h, { voies: (now, F) => voiesCout(now, F).map((v) => (v.rattachement && v.rattachement.dag === 'm1.md' ? { ...v, rattachement: { ...v.rattachement, dag: 'x"y.md' } } : v)) });
    await h.ev("window.__vfS.signal.missions[0].fichier = 'x\"y.md'; window.__emit('etat', { seq: 2 })");
    await h.pause(1500); await h.ev('window.__errs.length = 0');
    const ok = await h.ev(() => { const b = document.querySelector('.vf-cout-depli'); if (b) { b.focus(); b.click(); } return !!b; });
    await h.pause(500);
    const e = await h.ev(() => ({ errs: window.__errs.slice(), exp: document.querySelector('.vf-cout-depli') ? document.querySelector('.vf-cout-depli').getAttribute('aria-expanded') : null,
      foc: document.activeElement === document.querySelector('.vf-cout-depli'), phases: document.querySelectorAll('.vf-cout-phase').length }));
    h.sonde('D17', 'dépli d\'une mission dont le fichier contient un guillemet : aucune erreur, phases dépliées, focus rendu au bouton', ok && e.errs.length === 0 && e.exp === 'true' && e.foc && e.phases > 0, JSON.stringify(e));
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

# joue <scénario> <port> <sections…> : une ligne PASS/FAIL par sonde ; une section sans sonde est un FAIL nommé
joue() {
  local f="$1" port="$2" out line id lib ok ob; shift 2
  if [ -n "${SEUL:-}" ]; then case " $SEUL " in *" $f "*) ;; *) return ;; esac; fi   # SEUL="d1 d6" : ne jouer que ces scénarios (mise au point)
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

echo "=== D0 — les scénarios se lisent ==="
bad=""; for f in "$AUX"/*.mjs; do "$NODE" --check "$f" 2>/dev/null || bad="$bad $(basename "$f")"; done
assert_eq "D0 — chaque scénario passe node --check" "${bad:-aucun}" "aucun"

# ---------- D12 : forme du code (statique, sans navigateur) ----------
MODS="74-vf-frise-depot.js 74-vf-frise-depot-voies.js 74-vf-cout.js 74-vf-cout-tableau.js"
statique() { # <dossier ui> : une ligne par écart ; rien si tout est conforme
  local d="$1" f p
  for f in $MODS; do p="$d/$f"; [ -s "$p" ] || { echo "$f : module absent ou vide"; continue; }
    "$NODE" "$HERE_T/css-jetons.mjs" "$p" 2>&1 | sed "s#^#css-jetons #"
    grep -nE 'VF_FLUX|fetch\(|usage|€|tarif|—|EventSource' "$p" | sed "s#^#$f : interdit #"
    head -8 "$p" | grep -q 'vf-coquille: persistant' && echo "$f : marqué persistant"
    [ "$(awk 'END { print NR }' "$p")" -le 299 ] || echo "$f : plus de 299 lignes"
    "$NODE" -e 'const l = require("fs").readFileSync(process.argv[1], "utf8").split("\n"); const n = l.filter((x) => [...x].length > 160).length; if (n) console.log(process.argv[2] + " : " + n + " ligne(s) de plus de 160 colonnes");' "$p" "$f"
  done
  grep -q "cle: '74-vf-frise-depot.js'" "$d/74-vf-frise-depot.js" 2>/dev/null || echo "depot : surOnglet sans sa clé"
  grep -q "cle: '74-vf-cout.js'" "$d/74-vf-cout.js" 2>/dev/null || echo "cout : surOnglet sans sa clé"
  grep -q "abonner('git'" "$d/74-vf-frise-depot.js" 2>/dev/null || echo "depot : la route Git n'est pas lue sur l'événement git"
  grep -q "lireJson(" "$d/74-vf-frise-depot.js" 2>/dev/null || echo "depot : la route Git n'est pas lue par VF_ETAT.lireJson"
  grep -nE "teinte" "$d/74-vf-frise-depot.js" "$d/74-vf-frise-depot-voies.js" 2>/dev/null | sed "s#^#la teinte serveur est lue #"
  for f in "$d/74-vf-frise-depot.js" "$d/74-vf-frise-depot-voies.js"; do grep -nE "VFGitVolet|\.ouvrir\(" "$f" 2>/dev/null | sed "s#^#interne du tiroir Git composé #"; done
}
echo "=== D12 — forme du code (A44, jetons, aucun réseau direct, aucun usage, aucune devise) ==="
ECARTS="$(statique "$UI")"
assert_eq "D12 — quatre modules : jetons, aucun réseau direct ni lecture du flux brut, ni persistant, ≤ 299 lignes, ≤ 160 colonnes, clés de surOnglet, route Git par VF_ETAT" "${ECARTS:-aucun écart}" "aucun écart"

if [ -z "$CHROME" ]; then
  skip "D1 à D11, D13, D14 et la part téléphone de D12" "pas de navigateur"
else
  demarrer base; PORT="$VF_PORT"; SRV="$VF_PID"
  assert_eq "D0 — contrôle positif : serveur de la suite démarré, page Équipe servie" "$([ "$PORT" -gt 0 ] && echo serveur)" "serveur"
  echo "=== D1 et D2 — bandeau, heure des commits ==="; joue d1 "$PORT" D1 D2
  echo "=== D3 — couverture et états du bandeau ==="; joue d3 "$PORT" D3
  echo "=== D4 — clic vers le tiroir Git ==="; joue d4 "$PORT" D4
  echo "=== D5 et D5b — jamais attribué, lecture Git ==="; joue d5 "$PORT" D5 D5b
  echo "=== D6 à D10 — synthèse, section, regroupements, devise, un seul calcul ==="; joue d6 "$PORT" D6 D7 D8 D9 D10
  echo "=== D11 — formats ==="; joue d11 "$PORT" D11
  echo "=== D12 — téléphone 390 px ==="; joue d12 "$PORT" D12
  echo "=== D13 — incomplet ==="; joue d13 "$PORT" D13
  echo "=== D14 — aller-retour d'onglet ==="; joue d14 "$PORT" D14
  echo "=== D15 à D17 — focus à la relecture, aucune donnée de frise, texte non fiable ==="; joue d15 "$PORT" D15 D16 D17
  cockpit_arreter "$SRV"; SRV=""
fi

echo
echo "durée : $(( $(date +%s) - T0 )) s"
echo "Résultat : $PASS réussis, $FAIL échecs, $SKIP sautés"
[ "$FAIL" -eq 0 ]
