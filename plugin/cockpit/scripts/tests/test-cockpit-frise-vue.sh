#!/usr/bin/env bash
# test-cockpit-frise-vue.sh : la vue « Frise » de l'onglet Équipe sous Chrome (Phase 74, plan 74-04 ; TEMP-01, TEMP-02 hors Dépôt, TEMP-03, TEMP-04, TEMP-12 part forme).
# Le nom `test-cockpit-frise.sh` appartient à 79-13 (la route) : cette suite ne la touche pas. La route de frise est REMPLACÉE dans la page par un `fetch` de test (VF_PRE) qui sert
# la fixture de `frise-fabrique.mjs` et tient le journal des requêtes ; la page, le serveur, le flux (enveloppe AMORCE_FLUX) et la régie de la 73 sont les vrais.
#   S0 les scénarios se lisent (node --check)  S1 vue déclarée à la régie  S2 barre d'outils  S3 hauteur des voies  S4 segments  S5 événements  S6 colonne de gauche
#   S7 repli  S8 voies commencées avant la fenêtre  S9 états de la source  S10 direct  S11 alternative textuelle  S12 lectures Horloge / Événements, « maintenant »
#   S13 forme du code (statique)  S14 couleurs et contrastes  S15 mouvement réduit  S16 téléphone  S17 cycle de vie  S18 bandeau haut  S19 aller-retour Code -> Équipe -> Code -> Équipe
#   Mutants (copies du module : cockpit_module_muter, puis cockpit_lancer ; ligne `MUTANT-ROUGE <nom> <sonde>` écrite seulement quand la sonde a rougi) : M-BASCULE-PROPRE (S1),
#   M-TRONQUE-MUET (S9), M-CONTOUR (S4), M-SILENCE-DESSINE (S4), M-COULEUR-NOEUD (S14), M-HORLOGE-COMPRESSEE (S12), M-FETCH-DIRECT (S13), M-REPLI-SILENCIEUX (S7),
#   M-SANS-NETTOYAGE (S17, S19), M-SANS-CLE (S19), M-REGLAGES-OUBLIES (S19), M-COURBE-ABSENTE (S18). (Plan 74-04 non marqué audit : le régime allégé de la session principale
#   du 2026-11-13 ne demande pas de mutant ; ils sont joués ici parce que le plan les nomme.)
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

# ---------- crochets de page (VF_PRE) : route de frise remplacée, espions, mesures ----------
cat > "$AUX/pre.js" <<'JS'
window.__errs = [];
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
window.__couleur = (x) => { const p = document.createElement('i'); p.style.color = x.startsWith('--') ? 'var(' + x + ')' : x; document.body.appendChild(p); const c = getComputedStyle(p).color; p.remove(); return c; };
window.__px = (v) => { const p = document.createElement('i'); p.style.cssText = 'position:absolute;width:var(' + v + ')'; document.body.appendChild(p); const w = parseFloat(getComputedStyle(p).width); p.remove(); return w; };
window.__vfF = { reponse: null, statut: 503, delai: 0, reqs: [] };
// l'espion d'ouverture de la fiche survit au chargement du vrai module (74-vf-fiche.js) : la lecture rend toujours l'espion, l'écriture est ignorée
window.__fiche = [];
{ const espion = { ouvrir: (id, el) => { window.__fiche.push({ id, tag: el && el.tagName, data: el && el.getAttribute && el.getAttribute('data-id') }); } };
  Object.defineProperty(window, '__vfFiche', { configurable: true, get: () => espion, set: () => {} }); }
// les abonnements `frise` sont attribués à leur ORIGINE par la pile d'appel : ceux de la frise (74-vf-frise*.js) comptent, ceux de la fiche ou d'autres non
window.__aboF = [];
window.__aboFrise = () => window.__aboF.length;
{ let e; Object.defineProperty(window, 'VF_ETAT', { configurable: true, get: () => e,
  set: (x) => { e = x && typeof x.abonner === 'function' ? Object.freeze(Object.assign({}, x, { abonner: (cle, f) => {
    const un = x.abonner(cle, f), reg = cle === 'frise' && /74-vf-frise/.test(String(new Error().stack)) ? {} : null;
    if (reg) window.__aboF.push(reg);
    return () => { un(); if (reg) window.__aboF = window.__aboF.filter((r) => r !== reg); }; } })) : x; } }); }
window.__declarer = []; window.__surOnglet = [];
{ let v; Object.defineProperty(window, '__vfEquipeVues', { configurable: true, get: () => v,
  set: (x) => { v = x && typeof x.declarer === 'function' ? Object.assign({}, x, { declarer: (o) => { window.__declarer.push(o && o.id); return x.declarer(o); } }) : x; } }); }
{ let c; Object.defineProperty(window, 'VF_COQUILLE', { configurable: true, get: () => c,
  set: (x) => { c = x && typeof x.surOnglet === 'function' ? Object.freeze(Object.assign({}, x, { surOnglet: (r, o) => {
    window.__surOnglet.push({ cle: o && o.cle, frise: /74-vf-frise\.js/.test(String(new Error().stack))  }); return x.surOnglet(r, o); } })) : x; } }); }
{ const f0 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
    if (!/^\/api\/vf\/frise(\?|$)/.test(url)) return f0(u, i);
    const F = window.__vfF, h = (i && i.headers) || {};
    F.reqs.push({ url, methode: (i && i.method) || 'GET', jeton: !!h['x-vf-cockpit-token'] && h['x-vf-cockpit-token'] === (window.VF_COCKPIT_SERVER && window.VF_COCKPIT_SERVER.token) });
    const q = new URLSearchParams(url.split('?')[1] || ''), c = F.reponse ? JSON.parse(JSON.stringify(F.reponse)) : {};
    c.at = new Date().toISOString();
    if (q.get('jusqua') && c.voies) { const J0 = c.jusqua, J = Number(q.get('jusqua'));
      for (const v of c.voies) { if (v.fin === J0) v.fin = J; for (const s of v.segments || []) if (s[1] === J0) s[1] = J; }
      c.depuis = Number(q.get('depuis')); c.jusqua = J; }
    const rep = () => new Response(JSON.stringify(F.statut === 200 ? c : { erreur: F.statut === 400 ? 'bornes-invalides' : 'indisponible' }),
      { status: F.statut, headers: { 'content-type': 'application/json' } });
    return new Promise((ok) => setTimeout(() => ok(rep()), F.delai || 0)); }; }
window.__kd = [];
{ const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener;
  EventTarget.prototype.addEventListener = function (t, f, o) { if (t === 'keydown' && this.classList && this.classList.contains('vf-frise') && !window.__kd.some((x) => x[0] === this && x[1] === f)) window.__kd.push([this, f]); return A.call(this, t, f, o); };
  EventTarget.prototype.removeEventListener = function (t, f, o) { if (t === 'keydown') window.__kd = window.__kd.filter((x) => !(x[0] === this && x[1] === f)); return R.call(this, t, f, o); }; }
window.__nkd = () => window.__kd.filter((x) => x[0].isConnected).length;
JS
export VF_PRE="$AUX/pre.js"

# ---------- scénarios (une fois par section ou groupe de sections ; une instance de Chrome chacun) ----------
cat > "$AUX/s1.mjs" <<'JS'
export const ids = ['S1'];
export default async function (h) {
  await h.section('S1', async () => {
    await h.monter({ vue: 'regie' });
    const av = await h.ev(() => { const tl = document.querySelector('#vf-equipe [role=tablist]');
      return { n: document.querySelectorAll('#vf-equipe [role=tablist]').length, nom: tl ? tl.getAttribute('aria-label') : null, dedans: tl ? !!tl.closest('.vf-frise') : null,
        onglets: tl ? [...tl.querySelectorAll('[role=tab]')].map((t) => t.textContent) : [], sel: tl ? [...tl.querySelectorAll('[aria-selected=true]')].map((t) => t.textContent) : [],
        pages: document.querySelectorAll('nav.vf-tabs a').length, decl: window.__declarer.slice(), cles: Object.keys(sessionStorage).sort(), loc: Object.keys(localStorage).sort() }; });
    h.sonde('S1', `un seul tablist dessiné par la régie, hors de la frise, nom lu dans le DOM : « ${av.nom} »`, av.n === 1 && !!av.nom && av.dedans === false, JSON.stringify([av.n, av.nom, av.dedans]));
    h.egal('S1', 'deux positions « Régie » et « Frise », défaut Régie, trois onglets de page', [av.onglets, av.sel, av.pages], [['Régie', 'Frise'], ['Régie'], 3]);
    h.egal('S1', "window.__vfEquipeVues.declarer appelé UNE fois, avec id 'frise'", av.decl, ['frise']);
    await h.choisir('Frise'); await h.attendreFrise();
    const ap = await h.ev(() => { const vue = document.querySelector('.vf-vue[data-vf-vue="frise"]');
      return { sel: [...document.querySelectorAll('#vf-equipe [role=tab][aria-selected=true]')].map((t) => t.textContent), monte: !!(vue && vue.querySelector('.vf-frise')), cache: vue ? vue.hidden : null,
        n: document.querySelectorAll('#vf-equipe [role=tablist]').length, pages: document.querySelectorAll('nav.vf-tabs a').length, cles: Object.keys(sessionStorage).sort(), loc: Object.keys(localStorage).sort() }; });
    h.egal('S1', 'choisir « Frise » : vue montée dans .vf-vue[data-vf-vue=frise], visible, toujours UN tablist, trois onglets de page', [ap.sel, ap.monte, ap.cache, ap.n, ap.pages], [['Frise'], true, false, 1, 3]);
    h.egal('S1', 'clés sessionStorage écrites : celle de la régie et vibeflow-cockpit:frise-reglages, aucune autre ; localStorage inchangé',
      [ap.cles.filter((c) => !av.cles.includes(c)), JSON.stringify(ap.loc) === JSON.stringify(av.loc)], [['vibeflow-cockpit:equipe-vue', 'vibeflow-cockpit:frise-reglages'], true]);
  });
}
JS
cat > "$AUX/s2.mjs" <<'JS'
export const ids = ['S2'];
export default async function (h) {
  await h.section('S2', async () => {
    await h.monter({});
    await h.calme();
    const lib = await h.ev(() => { const g = (n) => document.querySelector('.vf-frise-outils [role=radiogroup][aria-label="' + n + '"]');
      const radios = (n) => (g(n) ? [...g(n).querySelectorAll('[role=radio]')].map((r) => [r.textContent, r.getAttribute('aria-checked')]) : null);
      return { lecture: radios('Lecture'), fenetre: radios('Fenêtre'), sj: /7\s*j\b/.test(document.body.innerText) }; });
    h.egal('S2', 'radiogroup « Lecture » : Horloge (défaut) et Événements', lib.lecture, [['Horloge', 'true'], ['Événements', 'false']]);
    h.egal('S2', 'radiogroup « Fenêtre » : EXACTEMENT « 1 h 30 » (défaut), « 6 h », « 24 h » (U+00A0), aucun « 7 j » dans la page',
      [lib.fenetre, lib.sj], [[['1 h 30', 'true'], ['6 h', 'false'], ['24 h', 'false']], false]);
    const attendus = [['6 h', 21600000], ['24 h', 86400000], ['1 h 30', 5400000]];
    for (const [l, ms] of attendus) {
      const n0 = (await h.reqs()).length;
      await h.changer(() => h.radio(l));
      await h.pause(600);
      const u = await h.reqs(); const nouv = u.slice(n0).map((x) => { const q = new URLSearchParams(x.split('?')[1]); return Number(q.get('jusqua')) - Number(q.get('depuis')); });
      h.egal('S2', `choisir « ${l} » : UNE lecture, jusqua - depuis = ${ms}`, nouv, [ms]);
    }
  });
}
JS
cat > "$AUX/s3.mjs" <<'JS'
export const ids = ['S3'];
const mesure = () => ({ hs: [...document.querySelectorAll('.vf-frise-voies > .vf-frise-voie')].map((l) => l.getBoundingClientRect().height),
  svg: (document.querySelector('svg.vf-frise-pistes') || { getBoundingClientRect: () => ({ height: -1 }) }).getBoundingClientRect().height, coarse: matchMedia('(pointer: coarse)').matches });
export default async function (h) {
  await h.section('S3', async () => {
    await h.monter({});
    const f = await h.ev(mesure);
    h.sonde('S3', 'pointeur fin : chaque cellule de voie = 32 px, égale à sa piste (hauteur du svg = 32 × voies)', f.hs.length > 0 && f.hs.every((x) => x === 32) && f.svg === 32 * f.hs.length && !f.coarse, JSON.stringify(f));
    await h.monter({ coarse: true });
    const c = await h.ev(mesure);
    h.sonde('S3', 'pointer: coarse : 44 px (cellule et piste)', c.coarse && c.hs.length > 0 && c.hs.every((x) => x === 44) && c.svg === 44 * c.hs.length, JSON.stringify(c));
  });
}
JS
cat > "$AUX/s4.mjs" <<'JS'
export const ids = ['S4'];
const voies = (now, F) => { const d = (m) => now - m * F.MIN;
  return [F.voie({ id: 'q-1', debut: d(88), fin: now, segments: [[d(88), d(78), 'travail'], [d(78), d(68), 'attend-humain'], [d(68), d(58), 'attend-agents'], [d(58), d(48), 'repos'], [d(48), d(38), 'silence'], [d(38), now, 'travail']] })]; };
export default async function (h) {
  await h.section('S4', async () => {
    const now = await (async () => { await h.monter({ voies }); return h.ev('Date.now()'); })();
    const m = await h.ev(() => { const g = document.querySelector('g[data-voie="q-1"]'), cs = (e) => getComputedStyle(e);
      const q = (k) => [...g.querySelectorAll('[data-etat="' + k + '"]')];
      const tr = q('travail'), at = q('attend')[0], ag = q('agents'), re = q('repos')[0];
      const id = at && /url\(#([^)]+)\)/.exec(at.getAttribute('fill') || ''), pat = id && document.getElementById(id[1]);
      const hh = (ms) => { const d = new Date(ms); return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0'); };
      const ti = (e) => (e && e.querySelector('title') ? e.querySelector('title').textContent : null);
      const patLine = pat && pat.querySelector('line, path, rect');
      return { sp8: window.__px('--sp-8'), sp2: window.__px('--sp-2'), act: window.__couleur('--st-active'), t4: window.__couleur('--text-4'),
        tr: tr[0] ? { tag: tr[0].tagName, h: tr[0].getAttribute('height'), fill: cs(tr[0]).fill, stroke: cs(tr[0]).stroke } : null,
        at: at ? { tag: at.tagName, fill: at.getAttribute('fill'), fillCs: cs(at).fill, pat: pat ? pat.tagName : null, patStroke: patLine ? cs(patLine).stroke : null, stroke: at.getAttribute('stroke'), strokeCs: cs(at).stroke, h: at.getAttribute('height') } : null,
        ag: ag[0] ? { tag: ag[0].tagName, sw: cs(ag[0]).strokeWidth, dash: cs(ag[0]).strokeDasharray, rects: ag.filter((e) => e.tagName === 'rect').length } : null,
        re: re ? { dash: cs(re).strokeDasharray, stroke: cs(re).stroke, sw: cs(re).strokeWidth } : null,
        total: g.querySelectorAll('[data-etat]').length, silence: g.querySelectorAll('[data-etat="silence"]').length,
        titres: [...g.querySelectorAll('title')].map((e) => e.textContent), derniere: tr[1] ? ti(tr[1]) : null, trN: tr.length };
    });
    h.sonde('S4', 'travail : rect plein, hauteur = --sp-8, fill = --st-active, aucun contour', !!m.tr && m.tr.tag === 'rect' && parseFloat(m.tr.h) === m.sp8 && m.tr.fill === m.act && m.tr.stroke === 'none', JSON.stringify(m.tr));
    h.sonde('S4', 'attend : rect rempli par un <pattern> aux traits --st-active, stroke none, aucune bordure', !!m.at && m.at.tag === 'rect' && /^url\(#/.test(m.at.fill) && m.at.pat === 'pattern' && /^url\(/.test(m.at.fillCs) && m.at.patStroke === m.act && m.at.stroke === 'none' && m.at.strokeCs === 'none', JSON.stringify(m.at));
    h.sonde('S4', 'agents : line ou path d\'épaisseur --sp-2, aucun rect plein', !!m.ag && ['line', 'path'].includes(m.ag.tag) && parseFloat(m.ag.sw) === m.sp2 && m.ag.rects === 0, JSON.stringify(m.ag));
    h.sonde('S4', 'repos : pointillé non vide, couleur --text-4', !!m.re && m.re.dash !== 'none' && m.re.dash !== '' && m.re.stroke === m.t4, JSON.stringify(m.re));
    const jeu = [[m.tr && m.tr.h, false, 'none'], [m.at && m.at.h, true, 'none'], [m.ag && m.ag.sw, false, m.ag && m.ag.dash], [m.re && m.re.sw, false, m.re && m.re.dash]].map((x) => JSON.stringify(x));
    h.sonde('S4', 'les quatre jeux (hauteur, pattern, dasharray) sont deux à deux distincts', new Set(jeu).size === 4 && jeu.every((x) => !x.includes('null')), jeu.join(' '));
    h.egal('S4', 'un segment silence ne produit aucun élément ni title : cinq éléments pour six segments', [m.silence, m.total, m.titres.length], [0, 5, 5]);
    const fin = await h.ev(() => window.__vfFrise.donnees().jusqua);
    const attendu = await h.ev((a, b) => { const hh = (ms) => { const d = new Date(ms); return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0'); }; return 'au travail, ' + hh(a) + ' à ' + hh(b) + ', 38 min'; }, now - 38 * 60000, fin);
    h.egal('S4', 'title du segment « au travail, hh:mm à hh:mm, 38 min » aux instants vrais', m.derniere, attendu);
  });
}
JS
cat > "$AUX/s5.mjs" <<'JS'
export const ids = ['S5'];
const voies = (now, F) => { const d = (m) => now - m * F.MIN;
  return [F.voie({ id: 'ev-1', debut: d(80), fin: now, segments: [[d(80), now, 'travail']],
    evenements: [[d(40), 'erreur'], [d(30), 'compaction'], [d(25), 'humain'], [d(20), 'rapport'], [d(50), 'erreur'], [d(50) + 3000, 'compaction'], [d(50) + 6000, 'rapport']] })]; };
export default async function (h) {
  await h.section('S5', async () => {
    await h.monter({ voies });
    const m = await h.ev(() => { const g = document.querySelector('g[data-voie="ev-1"]'), cs = (e) => getComputedStyle(e);
      const barre = g.querySelector('[data-etat]').getBoundingClientRect(), evs = [...g.querySelectorAll('[data-evt]')];
      const erreurs = evs.filter((e) => e.getAttribute('data-evt') === 'erreur');
      const teinte = (e) => { const f = e.querySelector('*') || e; return cs(f).stroke !== 'none' ? cs(f).stroke : cs(f).fill; };
      return { n: evs.length, genres: evs.map((e) => e.getAttribute('data-evt')).sort(), plus: [...g.querySelectorAll('.vf-frise-plus')].map((e) => e.textContent), bas: erreurs.map((e) => e.getBoundingClientRect().bottom), haut: barre.top,
        sev: window.__couleur('--sev-high'), teintes: erreurs.map(teinte), segs: [...g.querySelectorAll('[data-etat]')].map((e) => [cs(e).fill, cs(e).stroke]),
        commit: document.querySelectorAll('svg.vf-frise-pistes [data-evt="commit"], .vf-frise-pistes .vf-frise-commit').length };
    });
    h.egal('S5', 'sept événements dont trois confondus : cinq glyphes et un seul « +2 » écrit', [m.n, m.plus], [5, ['+2']]);
    h.sonde('S5', "croix d'erreur dans le rail du haut : bas du glyphe < haut de la barre de la voie", m.bas.length === 2 && m.bas.every((b) => b < m.haut), JSON.stringify([m.bas, m.haut]));
    h.sonde('S5', 'la croix porte --sev-high (témoin positif) et aucun segment n\'a cette couleur', m.teintes.length > 0 && m.teintes.every((t) => t === m.sev) && m.segs.every(([f, s]) => f !== m.sev && s !== m.sev), JSON.stringify([m.teintes, m.sev]));
    h.egal('S5', 'aucun losange de commit dans une voie', m.commit, 0);
  });
}
JS
cat > "$AUX/s6.mjs" <<'JS'
export const ids = ['S6'];
export default async function (h) {
  await h.section('S6', async () => {
    await h.monter({});
    const m = await h.ev(() => { const R = window.__vfEquipeRendu, cell = (id) => document.querySelector('.vf-frise-voie[data-id="' + id + '"] .vf-frise-cell');
      const sous = (id) => { const c = cell(id); const e = c && c.querySelector('.vf-frise-sous'); return e ? e.textContent : null; };
      const noeud = (id) => { const e = cell(id) && cell(id).querySelector('.vf-frise-sous .mono, .vf-frise-sous code'); return e ? e.textContent : null; };
      const glyphe = (id, nom) => { const c = cell(id), t = document.createElement('div'); t.innerHTML = R.glyphe(nom, ''); return !!c && c.querySelector('svg').innerHTML === t.querySelector('svg').innerHTML; };
      const unefois = [...document.querySelectorAll('.vf-frise-voie')].every((li) => { const nom = li.querySelector('.vf-frise-nom'); return !!nom && li.querySelectorAll('.vf-frise-nom').length === 1 && li.innerText.split('\n').filter((l) => l.trim() === nom.textContent.trim()).length === 1; });
      return { s: { 'sess-1': sous('sess-1'), 'mg-1': sous('mg-1'), 'wk-1': sous('wk-1'), 'wk-2': sous('wk-2'), 'hw-1': sous('hw-1'), 'lf-1': sous('lf-1') }, noeud: [noeud('wk-1'), noeud('mg-1')], unefois,
        inconnu: [...document.querySelectorAll('.vf-frise-voies')].some((e) => /inconnu/i.test(e.textContent)),
        gl: [glyphe('wk-1', R.GLYPHE_ETAT.termine), glyphe('mg-1', R.GLYPHE_ETAT['en-attente']), glyphe('wk-2', R.GLYPHE_ETAT.attend), glyphe('sess-1', R.GLYPHE_ETAT['au-repos'])] };
    });
    h.egal('S6', 'seconde ligne : tête, manager rattaché par ses agents, nœud en mono, arbre null = arbre principal, arbre nommé', m.s,
      { 'sess-1': 'au repos · tête · arbre principal', 'mg-1': 'attend ses agents · rattaché par ses agents', 'wk-1': 'terminé · nœud n1', 'wk-2': 'vous attend · nœud n2', 'hw-1': 'terminé · arbre principal', 'lf-1': 'terminé · wt-a' });
    h.egal('S6', 'l\'identifiant du nœud est en mono ; le manager n\'en porte aucun', m.noeud, ['n1', null]);
    h.egal('S6', 'le nom une seule fois par voie ; jamais « inconnu » dans la colonne', [m.unefois, m.inconnu], [true, false]);
    h.egal('S6', 'glyphes d\'état égaux à ceux de __vfEquipeRendu.GLYPHE_ETAT (table de la régie, aucune forme redéfinie)', m.gl, [true, true, true, true]);
    // survol : nom souligné, aucun fond ; focus : contour
    const p = await h.ev(() => { const b = document.querySelector('.vf-frise-voie[data-id="wk-1"] .vf-frise-cell').getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; });
    await h.s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: p.x, y: p.y });
    await h.pause(300);
    const v = await h.ev(() => { const c = document.querySelector('.vf-frise-voie[data-id="wk-1"] .vf-frise-cell'), nom = c.querySelector('.vf-frise-nom'), surf = window.__couleur('--surface');
      const fonds = []; for (let e = c; e && !e.classList.contains('vf-frise'); e = e.parentElement) fonds.push(getComputedStyle(e).backgroundColor);
      const carte = document.querySelector('.vf-frise'); fonds.push(getComputedStyle(carte).backgroundColor);
      return { sur: c.matches(':hover'), souligne: getComputedStyle(nom).textDecorationLine, fonds, surf }; });
    h.sonde('S6', 'survol : nom souligné ; fond de la cellule et de ses ancêtres jusqu\'à la carte transparent ou --surface', v.sur && /underline/.test(v.souligne) && v.fonds.every((f) => f === 'rgba(0, 0, 0, 0)' || f === v.surf), JSON.stringify(v));
    // clic, Entrée, Espace : la fiche s'ouvre par window.__vfFiche.ouvrir(id, élément)
    await h.ev(() => { window.__fiche.length = 0; document.querySelector('.vf-frise-voie[data-id="wk-1"] .vf-frise-cell').click(); });
    await h.ev(() => document.querySelector('.vf-frise-voie[data-id="wk-2"] .vf-frise-cell').focus());
    await h.touche('Enter', 'Enter', 13, '\r');
    await h.ev(() => document.querySelector('.vf-frise-voie[data-id="hw-1"] .vf-frise-cell').focus());
    await h.touche(' ', 'Space', 32, ' ');
    await h.pause(300);
    const f = await h.ev(() => window.__fiche.map((x) => [x.id, x.tag, x.data]));
    h.egal('S6', 'clic, Entrée et Espace appellent __vfFiche.ouvrir(id, bouton de la voie)', f, [['wk-1', 'BUTTON', 'wk-1'], ['wk-2', 'BUTTON', 'wk-2'], ['hw-1', 'BUTTON', 'hw-1']]);
  });
}
JS
cat > "$AUX/s7.mjs" <<'JS'
export const ids = ['S7'];
const gros = (now, F) => { const d = (m) => now - m * F.MIN, v = [];
  v.push(F.voie({ id: 'sess-1', kind: 'session', role: null, depth: null, debut: d(80), fin: now, segments: [[d(80), now, 'repos']] }));
  for (const [id, t] of [['mg-1', 70], ['mg-2', 69]]) v.push(F.voie({ id, parent: 'sess-1', dispatchA: d(t), debut: d(t), fin: now, segments: [[d(t), now, 'attend-agents']], rattachement: { dag: 'm1.md', noeud: null, source: 'enfants' } }));
  for (let i = 0; i < 15; i++) v.push(F.voie({ id: `w-${i}`, parent: 'mg-1', depth: 2, dispatchA: d(60 - i), debut: d(60 - i), fin: d(30), fini: true, segments: [[d(60 - i), d(30), 'travail']] }));
  return v; };
export default async function (h) {
  await h.section('S7', async () => {
    await h.monter({ voies: gros });
    const lire = () => h.ev(() => ({ voies: document.querySelectorAll('.vf-frise-voies > .vf-frise-voie').length, boutons: [...document.querySelectorAll('button.vf-frise-repli')].map((b) => [b.textContent, b.getAttribute('aria-expanded'), b.getAttribute('aria-label')]),
      sr: document.querySelectorAll('.vf-frise-sr li[data-id]').length }));
    const a = await lire();
    h.sonde('S7', '18 voies : au plus 12 visibles et un bouton « + 15 agents » aria-expanded=false', a.voies <= 12 && a.boutons.length === 1 && a.boutons[0][0] === '+ 15 agents' && a.boutons[0][1] === 'false' && a.boutons[0][2].startsWith('+ 15 agents'), JSON.stringify(a));
    await h.ev(() => document.querySelector('button.vf-frise-repli').click());
    await h.pause(400);
    const b = await lire();
    h.sonde('S7', 'activer le bouton : aria-expanded=true, les 18 voies sont là, libellé « Replier les agents »', b.voies === 18 && b.boutons[0][1] === 'true' && b.boutons[0][0] === 'Replier les agents', JSON.stringify(b));
    h.egal('S7', 'la liste .sr garde ses 18 voies repliée comme dépliée', [a.sr, b.sr], [18, 18]);
  });
}
JS
cat > "$AUX/s8.mjs" <<'JS'
export const ids = ['S8'];
const tr = (n) => (now, F) => { const d = (m) => now - m * F.MIN, v = [F.voie({ id: 'ok-1', debut: d(60), fin: now, segments: [[d(60), now, 'travail']] })];
  for (let i = 0; i < n; i++) v.push(F.voie({ id: `t-${i}`, debut: d(120 + i), fin: d(50), fini: true, segments: [[d(120 + i), d(50), 'travail']] }));
  return v; };
export default async function (h) {
  await h.section('S8', async () => {
    await h.monter({ voies: tr(3) });
    const ligne = () => h.ev(() => { const l = document.querySelector('.vf-frise-ligne[data-ligne="mission"]'); return l ? l.textContent : null; });
    h.egal('S8', 'trois voies commencées avant la fenêtre : la ligne dit le nombre, au pluriel', await ligne(), '3 voies commencées avant la fenêtre : elles sont coupées à gauche.');
    const coupe = await h.ev(() => { const g = document.querySelector('g[data-voie="t-0"]'); const c = g && g.querySelector('rect[data-coupe]'); const r = g && g.querySelector('rect[data-etat]');
      return { cap: !!c, rx: c ? c.getAttribute('rx') : null, x: c && r ? Math.abs(c.getBoundingClientRect().left - r.getBoundingClientRect().left) : null }; });
    h.sonde('S8', 'bord gauche du segment coupé carré : un cache de rayon 0 posé sur son bord gauche', coupe.cap && Number(coupe.rx) === 0 && coupe.x < 0.5, JSON.stringify(coupe));
    await h.poser({ voies: tr(1) });
    await h.changer(() => h.emettre(21));
    h.egal('S8', 'une seule voie : forme singulière', await ligne(), '1 voie commencée avant la fenêtre : elle est coupée à gauche.');
  });
}
JS
cat > "$AUX/s9.mjs" <<'JS'
export const ids = ['S9'];
const T = { construction: 'Lecture des traces en cours : la frise peut être incomplète.', partielle: "Certaines traces n'ont pas pu être lues : la frise est partielle.",
  tronque: (n) => `${n} voies ne sont pas montrées : la lecture est tronquée.`, des: 'Des voies ne sont pas montrées : la lecture est tronquée.' };
export default async function (h) {
  let seq = 100;
  const etat = () => h.ev(() => { const r = document.querySelector('.vf-frise'); const t = (s) => { const e = r.querySelector(s); return e ? e.textContent : null; };
    return { source: t('.vf-frise-ligne[data-ligne="source"]'), tronque: t('.vf-frise-ligne[data-ligne="tronque"]'), carte: t('.vf-frise-carte-titre'), vide: t('.vf-frise-vide'), reessayer: !!r.querySelector('.vf-frise-reessayer'),
      voies: r.querySelectorAll('.vf-frise-voies > .vf-frise-voie').length, busy: r.getAttribute('aria-busy'), ctx: window.__ctx || null, texte: r.textContent }; });
  const jusqua = async (pred, nom) => { const v = await h.attendreValeur(etat, pred, { max: 9000 }); if (!pred(v)) throw new Error('état non atteint : ' + nom + ' ' + JSON.stringify(v).slice(0, 200)); return v; };
  const pousser = async (o, pred, nom) => { await h.poser(o); await h.emettre(seq++); return jusqua(pred, nom); };
  await h.section('S9', async () => {
    await h.monter({ sourceEtat: 'en-construction' });
    await h.ev(() => window.__vfFrise.enregistrer('curseur', { rendre: (ctx) => { window.__ctx = { incomplet: ctx.incomplet, voiesOmises: ctx.voiesOmises }; } }));
    let e = await jusqua((x) => x.source === T.construction, 'en construction');
    h.sonde('S9', 'en-construction : voies dessinées et ligne « Lecture des traces en cours »', e.source === T.construction && e.voies > 0, JSON.stringify([e.source, e.voies]));
    e = await pousser({ sourceEtat: 'partielle' }, (x) => x.source === T.partielle, 'partielle');
    h.sonde('S9', 'partielle : la ligne « partielle », frise dessinée', e.source === T.partielle && e.voies > 0, e.source);
    e = await pousser({ sourceEtat: 'forme-inconnue', voies: [] }, (x) => x.carte === 'La frise ne se lit pas', 'forme inconnue');
    h.sonde('S9', 'forme-inconnue : carte « La frise ne se lit pas » SANS « Réessayer », aucune voie', e.carte === 'La frise ne se lit pas' && !e.reessayer && e.voies === 0, JSON.stringify([e.carte, e.reessayer, e.voies]));
    for (const [nom, o] of [['indisponible', { sourceEtat: 'indisponible', voies: [] }], ['503', { statut: 503 }], ['400 bornes-invalides', { statut: 400 }]]) {
      e = await pousser(o, (x) => x.carte === 'La frise est indisponible', nom);
      h.sonde('S9', `${nom} : carte « La frise est indisponible » AVEC « Réessayer », aucune voie`, e.carte === 'La frise est indisponible' && e.reessayer && e.voies === 0, JSON.stringify([e.carte, e.reessayer, e.voies]));
    }
    await h.poser({});
    const n0 = (await h.reqs()).length;
    await h.ev(() => document.querySelector('.vf-frise-reessayer').click());
    e = await jusqua((x) => x.carte === null && x.voies > 0, 'après Réessayer');
    h.sonde('S9', '« Réessayer » relance une lecture GET et la frise revient', (await h.reqs()).length > n0 && e.voies > 0, String((await h.reqs()).length - n0));
    e = await pousser({ tronque: true, voiesOmises: 37 }, (x) => x.tronque === T.tronque(37), 'tronque 37');
    h.sonde('S9', 'tronque avec voiesOmises 37 : « 37 voies ne sont pas montrées », ctx.incomplet vrai, voiesOmises transmis', e.tronque === T.tronque(37) && !!e.ctx && e.ctx.incomplet === true && e.ctx.voiesOmises === 37, JSON.stringify([e.tronque, e.ctx]));
    e = await pousser({ tronque: true, sansOmises: true }, (x) => x.tronque === T.des, 'tronque sans compte');
    h.sonde('S9', 'tronque sans voiesOmises : « Des voies ne sont pas montrées »', e.tronque === T.des, String(e.tronque));
    e = await pousser({ tronque: false }, (x) => x.tronque === null, 'sans troncature');
    h.sonde('S9', 'tronque faux : le texte est absent (apparié aux deux positifs) et ctx.incomplet faux', e.tronque === null && !e.texte.includes('ne sont pas montrées') && !!e.ctx && e.ctx.incomplet === false, JSON.stringify([e.tronque, e.ctx]));
    e = await pousser({ voies: [] }, (x) => !!x.vide, 'vide');
    h.sonde('S9', 'vide à 1 h 30 : « Rien à raconter sur cette fenêtre » avec « fenêtre plus large »', /^Rien à raconter sur cette fenêtre/.test(e.texte.trim()) || (e.texte.includes('Rien à raconter sur cette fenêtre') && e.texte.includes('fenêtre plus large')), (e.vide || '').slice(0, 160));
    await h.changer(() => h.radio('24 h'));
    e = await etat();
    h.sonde('S9', 'vide à 24 h : sans « fenêtre plus large »', e.texte.includes('Rien à raconter sur cette fenêtre') && !e.texte.includes('fenêtre plus large'), (e.vide || '').slice(0, 160));
    await h.poser({ delai: 700 });
    await h.radio('6 h');
    const occ = await h.attendreValeur(etat, (x) => x.busy === 'true' && x.texte.includes('Lecture de la frise'), { max: 1500 });
    h.sonde('S9', 'réponse retardée : aria-busy="true" et « Lecture de la frise » au-delà de 150 ms', occ.busy === 'true' && occ.texte.includes('Lecture de la frise'), JSON.stringify([occ.busy]));
  });
}
JS
cat > "$AUX/s10.mjs" <<'JS'
export const ids = ['S10'];
export default async function (h) {
  await h.section('S10', async () => {
    await h.monter({});
    await h.ev(() => { window.__ann = []; const live = document.querySelector('.vf-frise-live'); new MutationObserver(() => { const t = live.textContent; if (t && t !== window.__ann[window.__ann.length - 1]) window.__ann.push(t); }).observe(live, { childList: true, characterData: true, subtree: true }); });
    for (const tour of [1, 2]) {
      await h.calme();
      const n0 = (await h.reqs()).length, f0 = (await h.reqs('/api/vf/frise')).length;
      await h.emettre(100 + tour);
      await h.attendreValeur(async () => (await h.reqs()).length, (n) => n > n0, { max: 8000 });
      await h.pause(1500);
      const n1 = (await h.reqs()).length;
      h.egal('S10', `événement frise (tour ${tour}) : UNE relecture bornée de GET /api/vf/frise`, n1 - n0, 1);
      const fl = await h.ev(() => ({ cles: Object.keys({ seq: 1, at: 1, sig: 1 }), voies: JSON.stringify(window.__es.map((e) => e.url)).includes('voies') }));
      h.sonde('S10', `le flux ne porte aucune donnée de frise (tour ${tour}), garde apparié à un positif : l'événement est bien parti`, n1 > n0 && !fl.voies && f0 >= 0, JSON.stringify(fl));
    }
    const a1 = await h.ev(() => window.__ann.filter((t) => t === 'Frise mise à jour').length);
    await h.emettre(201); await h.pause(300); await h.emettre(202); await h.pause(2500);
    const a2 = await h.ev(() => window.__ann.filter((t) => t === 'Frise mise à jour').length);
    h.sonde('S10', 'au plus une annonce « Frise mise à jour » par minute, et au moins une au premier événement (positif)', a1 >= 1 && a2 === a1 && a1 <= 1, JSON.stringify([a1, a2]));
    // focus : une voie, puis frise ; la voie disparue : focus sur la voie du parent
    await h.ev(() => document.querySelector('.vf-frise-voie[data-id="wk-1"] .vf-frise-cell').focus());
    await h.changer(() => h.emettre(301));
    const f = await h.ev(() => document.activeElement && document.activeElement.getAttribute('data-id'));
    h.egal('S10', 'focus sur une voie puis événement frise : activeElement porte le même data-id', f, 'wk-1');
    await h.poser({ voies: (now, F) => F.voiesParDefaut(now).filter((v) => v.id !== 'wk-1') });
    await h.changer(() => h.emettre(302));
    const g = await h.ev(() => document.activeElement && document.activeElement.getAttribute('data-id'));
    h.egal('S10', 'voie disparue : le focus va à la voie du parent (mg-1)', g, 'mg-1');
  });
}
JS
cat > "$AUX/s11.mjs" <<'JS'
export const ids = ['S11'];
export default async function (h) {
  await h.section('S11', async () => {
    await h.monter({});
    const m = await h.ev(() => { const sr = document.querySelector('.vf-frise-sr'); const svgs = [...document.querySelectorAll('.vf-frise svg')].filter((s) => !s.closest('.vf-frise-legende') && !s.classList.contains('vf-frise-glyphe'));
      return { caches: svgs.length > 0 && svgs.every((s) => s.getAttribute('aria-hidden') === 'true' || !!s.closest('[aria-hidden=true]')), titre: sr && sr.querySelector('h3.sr') ? sr.querySelector('h3.sr').textContent : null,
        voies: sr ? sr.querySelectorAll(':scope > ul > li[data-id]').length : -1, rangs: document.querySelectorAll('.vf-frise-voies > .vf-frise-voie').length,
        segs: sr ? sr.querySelectorAll(':scope > ul > li[data-id] li[data-seg]').length : -1, dessines: document.querySelectorAll('svg.vf-frise-pistes [data-etat]').length };
    });
    h.sonde('S11', 'les pistes (svg de courbe, d\'axe et de voies) sont aria-hidden', m.caches, String(m.caches));
    h.egal('S11', 'h3.sr « Frise en liste, sur les dernières 1 h 30, lecture horloge »', m.titre, 'Frise en liste, sur les dernières 1 h 30, lecture horloge');
    h.sonde('S11', 'un élément par voie et par segment affiché', m.voies === m.rangs && m.segs === m.dessines && m.dessines > 0, JSON.stringify(m));
  });
}
JS
cat > "$AUX/s12.mjs" <<'JS'
export const ids = ['S12'];
const hor = (now, F) => { const d = (m) => now - m * F.MIN;
  return [F.voie({ id: 'hl-1', debut: d(80), fin: now, segments: [[d(80), d(50), 'travail'], [d(40), d(30), 'travail']] }), F.voie({ id: 'Close-1', role: 'Close', debut: d(20), fin: d(10), fini: true, rattachement: { dag: 'm1.md', noeud: 'Close', source: 'mandat' }, segments: [[d(20), d(10), 'travail']] })]; };
const evt = (now, F) => { const d = (m) => now - m * F.MIN;
  return [F.voie({ id: 'ev-1', debut: d(300), fin: now, segments: [[d(300), d(290), 'travail'], [d(287), d(277), 'travail'], [d(237), d(227), 'travail']] })]; };
const axe = () => ({ cellule: document.querySelector('.vf-frise-rang-axe .vf-frise-c').textContent.trim(),
  reperes: [...document.querySelectorAll('.vf-frise-rang-axe g.vf-frise-repere')].map((g) => { const l = [...g.querySelectorAll('line')].map((x) => Number(x.getAttribute('x1'))); return { larg: Math.abs(l[1] - l[0]), nl: l.length, texte: (g.querySelector('text') || {}).textContent }; }),
  maintenant: (() => { const m = document.querySelector('.vf-frise-rang-axe line.vf-frise-maintenant'); return m ? getComputedStyle(m).strokeDasharray : null; })(),
  mot: [...document.querySelectorAll('.vf-frise-rang-axe text')].some((t) => t.textContent === 'maintenant') });
export default async function (h) {
  await h.section('S12', async () => {
    await h.monter({ voies: hor });
    const a = await h.ev(() => { const rs = [...document.querySelectorAll('g[data-voie="hl-1"] rect[data-etat="travail"]')].map((e) => e.getBoundingClientRect()), r = rs.map((x) => x.width);
      const nom = document.querySelector('.vf-frise-voie[data-id="Close-1"] .vf-frise-nom'); const c = document.querySelector('.vf-frise-voie[data-id="Close-1"] .vf-frise-cell');
      return { r, ecart: rs.length === 2 ? rs[1].left - rs[0].right : null, reperes: document.querySelectorAll('.vf-frise-repere').length, nom: nom ? nom.textContent : null, mono: !!(nom && nom.closest('.mono, code, pre')), noeud: (c.querySelector('.vf-frise-sous .mono, .vf-frise-sous code') || {}).textContent }; });
    h.sonde('S12', 'Horloge : largeur(segment) / durée constante (30 min contre 10 min, et l\'écart de 10 min = un segment de 10 min), aucun repère de silence', a.r.length === 2 && Math.abs(a.r[0] - 3 * a.r[1]) < 0.5 && Math.abs(a.ecart - a.r[1]) < 0.5 && a.reperes === 0, JSON.stringify(a));
    h.sonde('S12', 'un nom d\'agent « Close » et un nœud « Close » restent « Close » (hors de la traduction : .mono)', !!a.nom && a.nom.startsWith('Close') && a.mono && a.noeud === 'Close', JSON.stringify([a.nom, a.mono, a.noeud]));
    const ax = await h.ev(axe);
    h.sonde('S12', 'la cellule d\'axe dit « Horloge » ; trait « maintenant » en pointillé et étiquette « maintenant »', ax.cellule === 'Horloge' && !!ax.maintenant && ax.maintenant !== 'none' && ax.mot, JSON.stringify([ax.cellule, ax.maintenant, ax.mot]));
    await h.monter({ voies: evt });
    await h.changer(() => h.radio('6 h'));
    await h.radio('Événements'); await h.pause(500);
    const e = await h.ev(axe);
    const larg = e.reperes.map((x) => Math.round(x.larg * 100) / 100), textes = e.reperes.map((x) => x.texte);
    h.sonde('S12', 'Événements : tous les repères ont la MÊME largeur fixe, dont ceux de 3 min et de 40 min', e.reperes.length >= 3 && new Set(larg).size === 1 && larg[0] > 0 && e.reperes.every((x) => x.nl === 2), JSON.stringify(larg));
    h.sonde('S12', 'les durées vraies sont écrites : « 3 min » et « 40 min »', textes.includes('3 min') && textes.includes('40 min'), JSON.stringify(textes));
    h.egal('S12', 'la cellule d\'axe dit « Événements, silences raccourcis »', e.cellule, 'Événements, silences raccourcis');
  });
}
JS
cat > "$AUX/s14.mjs" <<'JS'
export const ids = ['S14'];
const voies = (now, F) => { const d = (m) => now - m * F.MIN;
  return [F.voie({ id: 'c-1', debut: d(80), fin: now, rattachement: { dag: 'm1.md', noeud: 'noeud-bleu', source: 'registre' }, segments: [[d(80), d(60), 'travail'], [d(60), d(50), 'attend-humain'], [d(50), d(40), 'attend-agents'], [d(40), d(30), 'repos'], [d(30), now, 'travail']],
    evenements: [[d(70), 'erreur'], [d(65), 'compaction'], [d(45), 'humain'], [d(20), 'rapport']] }),
    F.voie({ id: 'c-2', parent: 'c-1', depth: 2, dispatchA: d(75), debut: d(75), fin: now, rattachement: { dag: 'm1.md', noeud: 'noeud-rouge', source: 'mandat' }, segments: [[d(75), now, 'travail']], evenements: [[d(75), 'dispatch']] })]; };
const mesure = () => { const R = document.querySelector('.vf-frise'), cs = (e) => getComputedStyle(e), out = new Set();
  for (const e of [R, ...R.querySelectorAll('*')]) { const c = cs(e);
    if ([...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim())) out.add(c.color);
    if (e.matches('line, rect, polygon, polyline, circle, path, text')) for (const p of ['fill', 'stroke']) { const v = c[p]; if (v && v !== 'none' && !v.startsWith('url')) out.add(v); }
    if (c.backgroundColor !== 'rgba(0, 0, 0, 0)') out.add(c.backgroundColor);
    for (const s of ['Top', 'Right', 'Bottom', 'Left']) if (parseFloat(c['border' + s + 'Width']) > 0 && c['border' + s + 'Style'] !== 'none') out.add(c['border' + s + 'Color']); }
  const rgb = (x) => { const m = /rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?/.exec(x); return m ? { k: m[1] + ',' + m[2] + ',' + m[3], a: m[4] === undefined ? 1 : Number(m[4]) } : null; };
  const v = (n) => rgb(window.__couleur(n)).k, ink = rgb(window.__couleur('rgb(var(--ink))')).k;
  const etats = { actif: v('--st-active'), fin: v('--recent'), sev: v('--sev-high') }, neutres = ['--text', '--text-2', '--text-3', '--text-4', '--hair', '--hair-2', '--raise', '--raise-2', '--surface'].map(v).concat([ink]);
  const trouves = [...out].map(rgb).filter(Boolean).filter((c) => c.a > 0), hors = trouves.filter((c) => !Object.values(etats).includes(c.k) && !neutres.includes(c.k)).map((c) => c.k);
  const couleur = (sel, p) => { const e = R.querySelector(sel); return e ? cs(e)[p] : null; };
  return { hors, vus: { actif: trouves.some((c) => c.k === etats.actif), fin: trouves.some((c) => c.k === etats.fin), sev: trouves.some((c) => c.k === etats.sev) },
    surface: window.__couleur('--surface'), axe: couleur('.vf-frise-rang-axe text.vf-frise-grad', 'fill'), travail: couleur('[data-etat="travail"]', 'fill'), agents: couleur('[data-etat="agents"]', 'stroke'),
    repos: couleur('[data-etat="repos"]', 'stroke'), croix: (() => { const g = R.querySelector('[data-evt="erreur"] *'); return g ? (cs(g).stroke !== 'none' ? cs(g).stroke : cs(g).fill) : null; })(),
    coche: (() => { const g = R.querySelector('[data-evt="rapport"] *'); return g ? (cs(g).stroke !== 'none' ? cs(g).stroke : cs(g).fill) : null; })() }; };
export default async function (h) {
  await h.section('S14', async () => {
    for (const theme of ['dark', 'light']) {
      await h.monter({ voies, media: [{ name: 'prefers-color-scheme', value: theme }] });
      const m = await h.ev(mesure);
      h.sonde('S14', `thème ${theme} : les couleurs résolues ⊂ {--st-active, --recent, --sev-high} + neutres (aucune par nœud), les trois sont présentes`, m.hors.length === 0 && m.vus.actif && m.vus.fin && m.vus.sev, JSON.stringify([m.hors, m.vus]));
      const r = (a, b) => Math.round(h.ratio(a, b) * 100) / 100;
      const cr = { axe: r(m.axe, m.surface), travail: r(m.travail, m.surface), agents: r(m.agents, m.surface), repos: r(m.repos, m.surface), croix: r(m.croix, m.surface), coche: r(m.coche, m.surface) };
      h.sonde('S14', `thème ${theme} : texte d'axe ≥ 4,5:1 ; barres et traits ≥ 3:1 sur --surface`, cr.axe >= 4.5 && Object.entries(cr).filter(([k]) => k !== 'axe').every(([, x]) => x >= 3), JSON.stringify(cr));
    }
  });
}
JS
cat > "$AUX/s15.mjs" <<'JS'
export const ids = ['S15'];
export default async function (h) {
  await h.section('S15', async () => {
    await h.monter({ media: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    const m = await h.ev(() => { const R = document.querySelector('.vf-vue[data-vf-vue="frise"]'), sec = (v) => String(v).split(',').map((x) => (x.trim().endsWith('ms') ? parseFloat(x) / 1000 : parseFloat(x)));
      const vivants = [...R.querySelectorAll('*')].filter((e) => { const c = getComputedStyle(e); return sec(c.animationDuration).some((x) => x > 0) && c.animationName !== 'none' || sec(c.transitionDuration).some((x) => x > 0); }).length;
      const mnt = R.querySelector('line.vf-frise-maintenant'), tr = mnt ? getComputedStyle(mnt).transitionDuration : null;
      return { vivants, maintenant: tr, reduit: matchMedia('(prefers-reduced-motion: reduce)').matches, n: R.querySelectorAll('*').length }; });
    h.sonde('S15', 'mouvement réduit : aucune animation ni transition active, « maintenant » sans transition', m.reduit && m.n > 20 && m.vivants === 0 && /^0s(, 0s)*$/.test(m.maintenant || ''), JSON.stringify(m));
  });
}
JS
cat > "$AUX/s16.mjs" <<'JS'
export const ids = ['S16'];
export default async function (h) {
  await h.section('S16', async () => {
    await h.monter({ largeur: 390, hauteur: 800, coarse: true });
    const m = await h.stabiliser(() => h.ev(() => { const d = document.querySelector('.vf-frise-defil'), li = document.querySelector('.vf-frise-voie');
      return { page: [document.scrollingElement.scrollWidth, innerWidth], defil: d ? [d.scrollWidth, d.clientWidth, d.scrollLeft, d.getAttribute('tabindex'), d.getAttribute('aria-label')] : null,
        col: li ? [li.getBoundingClientRect().width, li.getBoundingClientRect().height] : null, sticky: li ? getComputedStyle(li.parentElement.parentElement).position : null }; }), { pas: 300, max: 8000 });
    h.sonde('S16', 'à 390 px : la page ne défile pas horizontalement', m.page[0] <= m.page[1], JSON.stringify(m.page));
    h.sonde('S16', 'le conteneur des pistes défile, nommé « Frise, défilement horizontal », tabindex 0, scrollLeft initial = maximum', !!m.defil && m.defil[0] > m.defil[1] && Math.abs(m.defil[2] - (m.defil[0] - m.defil[1])) <= 1 && m.defil[3] === '0' && m.defil[4] === 'Frise, défilement horizontal', JSON.stringify(m.defil));
    h.sonde('S16', 'colonne de gauche de 120 de large, voies de 44', !!m.col && m.col[0] === 120 && m.col[1] === 44, JSON.stringify(m.col));
  });
}
JS
cat > "$AUX/s17.mjs" <<'JS'
export const ids = ['S17'];
export default async function (h) {
  const lire = () => h.ev(() => ({ abo: window.__aboFrise(), racines: document.querySelectorAll('.vf-frise').length, kd: window.__nkd(), tablists: document.querySelectorAll('#vf-equipe [role=tablist]').length, voies: document.querySelectorAll('.vf-frise-voies > .vf-frise-voie').length }));
  const un = async (nom, seq) => { await h.calme(); const n0 = (await h.reqs()).length; await h.emettre(seq);
    await h.attendreValeur(async () => (await h.reqs()).length, (n) => n > n0, { max: 8000 }); await h.pause(1500);
    h.egal('S17', `${nom} : une relecture par événement`, (await h.reqs()).length - n0, 1); };
  await h.section('S17', async () => {
    await h.monter({});
    h.egal('S17', 'témoin : monté une fois (abonnés frise, racines, écouteurs Échap, tablists)', await lire().then((x) => [x.abo, x.racines, x.kd, x.tablists]), [1, 1, 1, 1]);
    await un('montage', 10);
    await h.cycle('code'); await h.attendreFrise();
    h.egal('S17', 'Équipe -> autre onglet -> Équipe : un seul abonnement, une seule racine, un seul écouteur, un seul tablist', await lire().then((x) => [x.abo, x.racines, x.kd, x.tablists]), [1, 1, 1, 1]);
    await un('après l\'aller-retour d\'onglet', 20);
    await h.ev(() => { [...document.querySelectorAll('#vf-equipe [role=tab]')].find((t) => t.textContent === 'Régie').click(); });
    await h.pause(400);
    const r = await lire();
    h.egal('S17', '« Frise » -> « Régie » : la frise est démontée (aucun abonné, aucune racine, aucun écouteur)', [r.abo, r.racines, r.kd], [0, 0, 0]);
    await h.choisir('Frise'); await h.attendreFrise();
    h.egal('S17', '« Régie » -> « Frise » : un seul abonnement, une racine, un écouteur, aucun doublon de DOM', await lire().then((x) => [x.abo, x.racines, x.kd, x.voies > 0]), [1, 1, 1, true]);
    await un('après Régie puis Frise', 30);
  });
}
JS
cat > "$AUX/s18.mjs" <<'JS'
export const ids = ['S18'];
export default async function (h) {
  await h.section('S18', async () => {
    await h.monter({});
    const m = await h.ev(() => { const M = window.__vfFriseModele, d = window.__vfFrise.donnees(), c = M.courbe(d.frise.voies, d.depuis, d.jusqua), rang = document.querySelector('.vf-frise-rang-courbe');
      const poly = rang && rang.querySelector('polygon[data-marches]'); const svg = rang && rang.querySelector('svg');
      return { col: rang ? rang.querySelector('.vf-frise-c').innerText.split('\n').map((x) => x.trim()).filter(Boolean) : null, pic: c.pic, marches: c.pas.length, dessine: poly ? Number(poly.getAttribute('data-marches')) : null,
        caches: !!svg && svg.getAttribute('aria-hidden') === 'true' }; });
    h.egal('S18', 'colonne : « Agents au travail » puis « jusqu\'à N en même temps sur 1 h 30 » (pic de la fixture, fenêtre écrite)', m.col, ['Agents au travail', `jusqu'à ${m.pic} en même temps sur 1 h 30`]);
    h.sonde('S18', 'escalier rendu : autant de marches que courbe() ; piste aria-hidden', m.dessine === m.marches && m.marches > 0 && m.caches, JSON.stringify(m));
  });
}
JS
cat > "$AUX/s19.mjs" <<'JS'
export const ids = ['S19'];
export default async function (h) {
  const lire = () => h.ev(() => ({ abo: window.__aboFrise(), racines: document.querySelectorAll('.vf-frise').length, kd: window.__nkd(),
    checks: [...document.querySelectorAll('.vf-frise-outils [role=radio][aria-checked=true]')].map((r) => r.textContent), curseur: window.__vfFrise.donnees().curseurMs ?? null,
    cles: Object.keys(sessionStorage).sort(), ouvertures: window.__fiche.length, reglages: sessionStorage.getItem('vibeflow-cockpit:frise-reglages') }));
  await h.section('S19', async () => {
    await h.monter({});
    await h.changer(() => h.radio('6 h')); await h.changer(() => h.radio('Événements'));
    const av = await lire();
    h.sonde('S19', 'témoin : les deux choix sont gardés sous vibeflow-cockpit:frise-reglages', !!av.reglages && av.checks.includes('6 h') && av.checks.includes('Événements'), String(av.reglages));
    await h.cycle('code'); await h.attendreFrise();
    const a = await lire();
    h.egal('S19', 'Code -> Équipe : fenêtre et lecture restituées, curseur absent, fiche fermée, une racine, un abonné, un écouteur', [a.checks.sort(), a.curseur, a.ouvertures, a.racines, a.abo, a.kd], [['6 h', 'Événements'].sort(), null, 0, 1, 1, 1]);
    await h.cycle('code'); await h.attendreFrise();
    const b = await lire();
    h.egal('S19', 'après DEUX changements d\'onglet : aucun abonnement ni écouteur doublé, réglages toujours restitués', [b.checks.sort(), b.racines, b.abo, b.kd], [['6 h', 'Événements'].sort(), 1, 1, 1]);
    h.egal('S19', 'aucune autre clé de stockage que celle de la régie et celle des réglages', b.cles.filter((c) => !c.startsWith('vibeflow-cockpit:equipe-vue') && c !== 'vibeflow-cockpit:frise-reglages'), []);
    const s = await h.ev(() => window.__surOnglet.filter((x) => x.frise));
    h.sonde('S19', 'surOnglet appelé par la frise avec { cle: \'74-vf-frise.js\' } à chaque arrivée (chaque exécution du module, aucune sans clé)', s.length >= 3 && s.every((x) => x.cle === '74-vf-frise.js'), JSON.stringify(s));
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

# joue <scénario> <port> <sections…> : une ligne PASS/FAIL par sonde ; une section sans sonde est un FAIL nommé ; remplit RESULTAT (lignes FAIL par section)
joue() {
  local f="$1" port="$2" out line id lib ok ob n0 rc; shift 2
  JOUE_FAIL=""
  if [ -n "${SEUL:-}" ]; then case " $SEUL " in *" $f "*) ;; *) return ;; esac; fi   # SEUL="s1 s6" : ne jouer que ces scénarios (mise au point)
  out="$("$NODE" "$HERE_T/chrome-frise.mjs" "$CHROME" "$AUX/$f.mjs" "http://127.0.0.1:$port" 2>&1 | tail -1)"
  JOUE_FAIL=""
  line="$("$NODE" -e 'let j; try { j = JSON.parse(process.argv[1]); } catch { process.exit(3); }
    if (!j.sondes) { console.log("ERR\t" + (j.erreur || "sortie illisible")); process.exit(0); }
    for (const s of j.sondes) console.log([s.ok ? "OK" : "KO", s.id, s.lib, s.obtenu].join("\t"));' "$out" 2>/dev/null)"
  if [ -z "$line" ] || [ "${line%%$'\t'*}" = ERR ]; then
    for id in "$@"; do echo "  ❌ FAIL — $id — scénario $f interrompu"; echo "     obtenu:  [${line:-${out:0:200}}]"; FAIL=$((FAIL+1)); JOUE_FAIL="$JOUE_FAIL $id"; done
    return
  fi
  while IFS=$'\t' read -r ok id lib ob; do
    if [ "$ok" = OK ]; then echo "  ✅ PASS — $id — $lib"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — $id — $lib"; echo "     obtenu:  [$ob]"; FAIL=$((FAIL+1)); JOUE_FAIL="$JOUE_FAIL $id"; fi
  done <<EOF
$line
EOF
}

echo "=== S0 — les scénarios se lisent ==="
bad=""; for f in "$AUX"/s*.mjs; do "$NODE" --check "$f" 2>/dev/null || bad="$bad $(basename "$f")"; done
assert_eq "S0 — chaque scénario passe node --check" "${bad:-aucun}" "aucun"

# ---------- S13 : forme du code (statique, sans navigateur) ----------
MODS="74-vf-frise.js 74-vf-frise-colonne.js 74-vf-frise-pistes.js 74-vf-frise-source.js 74-vf-frise-style.js"
statique() { # <dossier ui> : une ligne par écart ; rien si tout est conforme
  local d="$1" f p
  for f in $MODS; do p="$d/$f"; [ -s "$p" ] || { echo "$f : module absent ou vide"; continue; }
    "$NODE" "$HERE_T/css-jetons.mjs" "$p" 2>&1 | sed "s#^#css-jetons #"
    grep -nE 'VF_FLUX|fetch\(|EventSource|€|tarif|—' "$p" | sed "s#^#$f : interdit #"
    head -5 "$p" | grep -q 'vf-coquille: persistant' && echo "$f : marqué persistant"
    [ "$(awk 'END { print NR }' "$p")" -le 299 ] || echo "$f : plus de 299 lignes"
    "$NODE" -e 'const l = require("fs").readFileSync(process.argv[1], "utf8").split("\n"); const n = l.filter((x) => [...x].length > 160).length; if (n) console.log(process.argv[2] + " : " + n + " ligne(s) de plus de 160 colonnes");' "$p" "$f"
    grep -nE "font-size: *[0-9.]+px" "$p" | grep -vE "font-size: *(11\.5|12\.5|13|15|20)px" | sed "s#^#$f : taille hors échelle #"
    grep -nE '(border-color|outline-color|box-shadow|filter)[^;]*var\(--(st-|sev-|recent)' "$p" | sed "s#^#$f : couleur d'état en contour ou ombre #"
    grep -nE 'background[^;]*var\(--(st-|sev-|recent)' "$p" | sed "s#^#$f : fond teinté d'état #"
  done
  for f in $MODS; do p="$d/$f"; [ -s "$p" ] || continue
    deb="$(grep -n 'glyphes d.événement : début' "$p" | head -1 | cut -d: -f1)"; fin="$(grep -n 'glyphes d.événement : fin' "$p" | head -1 | cut -d: -f1)"
    grep -n "'path'\|<path" "$p" | cut -d: -f1 | while IFS= read -r lig; do
      { [ -n "$deb" ] && [ -n "$fin" ] && [ "$lig" -gt "$deb" ] && [ "$lig" -lt "$fin" ]; } || echo "$f : tracé path hors de la fonction des glyphes d'événement (ligne $lig)"
    done
  done
  grep -q 'GLYPHE_ETAT' "$d/74-vf-frise-colonne.js" 2>/dev/null || echo "colonne : GLYPHE_ETAT jamais lu"
  for f in $MODS; do grep -nE "const GLYPHE\b|GLYPHE = \{" "$d/$f" 2>/dev/null; done | sed "s#^#table de glyphes redéfinie #"
}
echo "=== S13 — forme du code (A44, jetons, aucun réseau direct) ==="
ECARTS="$(statique "$UI")"
assert_eq "S13 — cinq modules : jetons, aucun réseau direct ni lecture du flux brut, ni persistant, ≤ 299 lignes, ≤ 160 colonnes, glyphes de la régie, path confiné" "${ECARTS:-aucun écart}" "aucun écart"

if [ -z "$CHROME" ]; then
  skip "S1 à S12, S14 à S19 et les mutants" "pas de navigateur"
else
  demarrer base; PORT="$VF_PORT"; SRV="$VF_PID"
  assert_eq "S0 — contrôle positif : serveur de la suite démarré, page Équipe servie" "$([ "$PORT" -gt 0 ] && echo serveur)" "serveur"
  avant="$(somme_lab)"
  echo "=== S1 — vue déclarée à la régie (73) ==="; joue s1 "$PORT" S1
  assert_eq "S1 — aucun fichier du lab modifié (somme du dossier avant/après)" "$(somme_lab)" "$avant"
  echo "=== S2 — barre d'outils ==="; joue s2 "$PORT" S2
  echo "=== S3 — hauteur des voies ==="; joue s3 "$PORT" S3
  echo "=== S4 — segments ==="; joue s4 "$PORT" S4
  echo "=== S5 — événements ==="; joue s5 "$PORT" S5
  echo "=== S6 — colonne de gauche ==="; joue s6 "$PORT" S6
  echo "=== S7 — repli ==="; joue s7 "$PORT" S7
  echo "=== S8 — voies commencées avant la fenêtre ==="; joue s8 "$PORT" S8
  echo "=== S9 — états de la source ==="; joue s9 "$PORT" S9
  echo "=== S10 — direct ==="; joue s10 "$PORT" S10
  echo "=== S11 — alternative textuelle ==="; joue s11 "$PORT" S11
  echo "=== S12 — lectures, « maintenant », données non traduites ==="; joue s12 "$PORT" S12
  echo "=== S14 — couleurs et contrastes (deux thèmes) ==="; joue s14 "$PORT" S14
  echo "=== S15 — mouvement réduit ==="; joue s15 "$PORT" S15
  echo "=== S16 — téléphone 390 px ==="; joue s16 "$PORT" S16
  echo "=== S17 — cycle de vie ==="; joue s17 "$PORT" S17
  echo "=== S18 — bandeau haut ==="; joue s18 "$PORT" S18
  if [ -n "${DBG:-}" ]; then cp "$DBG" "$AUX/dbg.mjs"; joue dbg "$PORT" DBG; fi   # mise au point seulement
  echo "=== S19 — aller-retour Code -> Équipe -> Code -> Équipe ==="; joue s19 "$PORT" S19
  cockpit_arreter "$SRV"; SRV=""

  # ---------- mutants : copie du module, motif vérifié par cockpit_module_muter, sonde rejouée sur le serveur de la copie ----------
  echo "=== Mutants ==="
  if [ -n "${SEUL:-}" ]; then echo "  (mutants non joués : SEUL est posé)"; else
  mutant() { # <nom> <fichier ui> <expression sed> <scénario> <section>… ; MUTANT-ROUGE seulement si la sonde a rougi
    local nom="$1" fic="$2" expr="$3" scen="$4" sec s rouge="" pc pf; shift 4
    unset COCKPIT_MODULE
    if ! cockpit_module_muter "$nom" "$fic" "$expr" 2>"$WORK/mut-$nom.err"; then echo "  ❌ FAIL — M-$nom — motif absent de $fic ($(head -c 160 "$WORK/mut-$nom.err"))"; FAIL=$((FAIL+1)); unset COCKPIT_MODULE; return; fi
    demarrer "mut-$nom"
    if [ "${VF_PORT:-0}" -le 0 ]; then echo "  ❌ FAIL — M-$nom — serveur du mutant non lancé"; FAIL=$((FAIL+1)); unset COCKPIT_MODULE; return; fi
    pc=$PASS; pf=$FAIL; joue "$scen" "$VF_PORT" "$@" > "$WORK/mut-$nom.out"; PASS=$pc; FAIL=$pf
    cockpit_arreter "$VF_PID"; unset COCKPIT_MODULE
    for s in "$@"; do case "$JOUE_FAIL" in *" $s"*) rouge="$s" ;; esac; done
    if [ -n "$rouge" ]; then echo "MUTANT-ROUGE $nom $rouge"; echo "  ✅ PASS — M-$nom — la sonde $rouge rougit sur le mutant"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — M-$nom — sonde restée verte sur le mutant (${*})"; FAIL=$((FAIL+1)); fi
  }
  mutant BASCULE-PROPRE 74-vf-frise.js "s/const barre = h('div', 'vf-frise-outils');/const barre = h('div', 'vf-frise-outils'); barre.setAttribute('role', 'tablist');/" s1 S1
  mutant TRONQUE-MUET 74-vf-frise-source.js "s/ne sont pas montrées/sont affichées/g" s9 S9
  mutant CONTOUR 74-vf-frise-pistes.js "s/rect.setAttribute('fill', 'url(#' + ID_HACHURES + ')');/rect.setAttribute('fill', 'url(#' + ID_HACHURES + ')'); rect.setAttribute('stroke', 'var(--text)');/" s4 S4
  mutant SILENCE-DESSINE 74-vf-frise-pistes.js "s/s.genre !== 'silence' \&\& //" s4 S4
  mutant COULEUR-NOEUD 74-vf-frise-pistes.js "s/rect.classList.add('vf-frise-seg');/rect.classList.add('vf-frise-seg'); rect.style.fill = 'hsl(' + (String(v.rattachement \&\& v.rattachement.noeud).length * 47) + ', 70%, 40%)';/" s14 S14
  mutant HORLOGE-COMPRESSEE 74-vf-frise.js "s/lecture: lecture,/lecture: 'evenements',/" s12 S12
  mutant REPLI-SILENCIEUX 74-vf-frise-colonne.js "s/'+ ' + n + ' agents'/'+ agents'/" s7 S7
  mutant SANS-NETTOYAGE 74-vf-frise.js "s/m.abo(); m.abo = null;//" s17 S17 S19
  mutant SANS-CLE 74-vf-frise.js "s/{ cle: '74-vf-frise.js' }/{}/" s19 S19
  mutant REGLAGES-OUBLIES 74-vf-frise.js "s/sessionStorage.setItem(CLE_REGLAGES/void (CLE_REGLAGES/" s19 S19
  mutant COURBE-ABSENTE 74-vf-frise-pistes.js "s/poly.setAttribute('data-marches', String(c.pas.length));/poly.setAttribute('data-marches', '0');/" s18 S18
  # M-FETCH-DIRECT : un fetch( ajouté à un module ; la sonde est la section statique S13, rejouée sur la copie
  unset COCKPIT_MODULE
  if cockpit_module_muter FETCH-DIRECT 74-vf-frise-source.js "s/^(() => {\$/(() => { fetch('\/api\/vf\/frise');/" 2>/dev/null; then
    E="$(statique "$COCKPIT_MODULE/skills/cockpit-moteur/assets/ui")"
    if [ -n "$E" ]; then echo "MUTANT-ROUGE FETCH-DIRECT S13"; echo "  ✅ PASS — M-FETCH-DIRECT — S13 rougit sur le mutant"; PASS=$((PASS+1)); else echo "  ❌ FAIL — M-FETCH-DIRECT — S13 reste verte"; FAIL=$((FAIL+1)); fi
  else echo "  ❌ FAIL — M-FETCH-DIRECT — motif absent (module source introuvable ou ancre manquante)"; FAIL=$((FAIL+1)); fi
  unset COCKPIT_MODULE
  fi
fi

echo
echo "durée : $(( $(date +%s) - T0 )) s"
echo "Résultat : $PASS réussis, $FAIL échecs, $SKIP sautés"
[ "$FAIL" -eq 0 ]
