#!/usr/bin/env bash
# test-cockpit-equipe-retraits.sh — gardes d'absence et jointure de la régie avec la fiche (Phase 74, plan 74-08 ; TEMP-06, TEMP-12 ; P74-D-28, D-51).
# Ce que la 73 a retiré ne revient pas (R1 bouton et boîte de transcript, R6 carte « Terminés »), la durée des veilles n'est jamais affichée par la 74 (R3),
# l'export `transcript` vit encore (R7, retiré par 74-10 seul : 73-C2), et la fiche porte l'ouverture d'un agent depuis la régie (R2 rendu en texte,
# R5 ancre, R5b nom et rapport). Les sondes de page se jouent par chrome-fiche.mjs sur un serveur lancé depuis une COPIE du module.
#   R1 absence (garde)   R2 rendu en texte contre la fiche   R3 durée (garde)   R4 T26.8, T27.B2, T27.C1, T27.C2 contre la fiche   R5 ancre   R5b nom, Entrée, Espace, rapport   R6 carte (garde)   R7 export (garde)
#   RETRAITS_SANS_FICHE=1 : la copie du module est privée de ses ui/74-vf-fiche*.js (la base de la 73 seule) — R2, R4, R5, R5b y rougissent ; R1, R3, R6, R7 y restent verts.
#   Mutants (copies du MODULE ; « MUTANT-ROUGE <nom> <sonde> » seulement quand la sonde a rougi) : M-BOUTON-REVENU (R1), M-DUREE-VEILLES-REVENUE (R3),
#   M-CARTE-REVENUE (R6), M-NON-ANNULE (R5b), M-EXPORT-PREMATURE (R7). RETRAITS_SANS_MUTANTS=1 les saute. Navigateur absent : sondes de page SAUTÉES (dites).
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"; export HOME="$WORK/home"
PIDS=(); T0=$(date +%s)
PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }
NODE="$(command -v node)"; export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-30000}"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
echo "navigateur : ${CHROME:-aucun (les sondes de page sont SAUTÉES)}"

# ---------- crochets de page (VF_PRE) : routes de frise et de transcript remplacées, journaux ----------
cat > "$AUX/pre.js" <<'JS'
window.__xss = 0; window.__req = []; window.__scrolls = 0;
window.__vfF = { reponse: null, statut: 200, delai: 0 };
window.__vfT = { parId: {}, statut: 200, delai: 0 };
{ const S0 = Element.prototype.scrollIntoView; Element.prototype.scrollIntoView = function (...a) { window.__scrolls++; return S0.apply(this, a); }; }
{ const f0 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
    if (/^\/api\/vf\//.test(url)) window.__req.push(url);
    const rep = (corps, statut) => Promise.resolve(new Response(JSON.stringify(corps), { status: statut, headers: { 'content-type': 'application/json' } }));
    if (/^\/api\/vf\/frise(\?|$)/.test(url)) { const F = window.__vfF, c = F.reponse ? JSON.parse(JSON.stringify(F.reponse)) : {}; c.at = new Date().toISOString();
      return rep(F.statut === 200 ? c : { erreur: 'indisponible' }, F.statut); }
    if (/^\/api\/vf\/transcript\?/.test(url)) { const id = new URLSearchParams(url.split('?')[1]).get('id'), c = window.__vfT.parId[id];
      return c ? rep(JSON.parse(JSON.stringify(c)), 200) : rep({ schema: 'vibeflow/cockpit-transcript@2', id, erreur: 'inconnu' }, 200); }
    return f0(u, i); }; }
JS
export VF_PRE="$AUX/pre.js"

# ---------- fixtures : une session, un manager, deux agents terminés (dont un à 101 h de veille), un actif ----------
cat > "$AUX/fix.mjs" <<'JS'
export const HOSTILE = '<img src=x onerror=window.__xss=1>';
export const iso = (now, m) => new Date(now - m * 60000).toISOString();
export const corps = (id, fil) => ({ schema: 'vibeflow/cockpit-transcript@2', id, fil, tronque: false, mandat: null });
export const voies = (now, F) => {
  const d = (m) => now - m * F.MIN;
  return [
    F.voie({ id: 'sess-1', kind: 'session', role: null, depth: null, debut: d(600), fin: now, segments: [[d(600), d(580), 'travail'], [d(580), now, 'repos']],
      durees: { travailS: 1200, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 } }),
    F.voie({ id: 'mg-1', parent: 'sess-1', role: 'vf-dev-manager', dispatchA: d(250), debut: d(250), fin: now, segments: [[d(250), now, 'attend-agents']] }),
    // 101 h de veille (dureeS = 363600 s), 2 h 14 de travail (8040 s = 100 min + 34 min de segments)
    F.voie({ id: 'wk-1', parent: 'mg-1', depth: 2, role: 'vf-coder', dispatchA: d(200), debut: d(200), fin: d(21), fini: true, etatOfficiel: 'termine', dureeS: 363600,
      segments: [[d(200), d(100), 'travail'], [d(90), d(56), 'travail']], durees: { travailS: 8040, attenteHumainS: 1080, attenteAgentsS: 0, reposS: 0, silenceS: 0 } }),
    F.voie({ id: 'wk-2', parent: 'mg-1', depth: 2, role: 'vf-coder', dispatchA: d(50), debut: d(50), fin: now, segments: [[d(50), now, 'travail']],
      durees: { travailS: 3000, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 } }),
    // terminé il y a 5 h : l'historique des terminés se lit sur la frise à 24 h
    F.voie({ id: 'wk-5', parent: 'mg-1', depth: 2, role: 'vf-reviewer', dispatchA: d(400), debut: d(400), fin: d(300), fini: true, etatOfficiel: 'termine',
      segments: [[d(400), d(300), 'travail']], durees: { travailS: 6000, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 } }),
  ];
};
const agent = (id, role, task, etat, ageS) => ({ id, kind: 'subagent', role, task, parent: 'mg-1', etat, ageS, branch: 'feat/x', tree: '.' });
export const WHO = [
  { id: 'sess-1', kind: 'session', etat: 'au-repos', titre: 'Session principale', branch: 'feat/x', tree: '.', ageS: 300 },
  { id: 'mg-1', kind: 'subagent', role: 'vf-dev-manager', task: 'Piloter la phase 74', parent: 'sess-1', etat: 'actif', ageS: 10, branch: 'feat/x', tree: '.' },
  agent('wk-1', 'vf-coder', 'Écrire la fiche', 'termine', 1800), agent('wk-2', 'vf-coder', 'Rédiger les faits', 'actif', 20), agent('wk-5', 'vf-reviewer', 'Relire la jointure', 'termine', 18000),
];
export const ORIGINE = (id) => `#vf-equipe li[data-vf-agent="${id}"] .vf-rg-tog`;
export const RAPPORT = (id) => `#vf-equipe li[data-vf-agent="${id}"] .vf-rg-act button`;
// espion de la page : chaque vf-agent:ouvrir (détail, annulé ou non, relu après un tour) et chaque vf-agent:lu
export const ESPIONS = () => { window.__ouv = []; window.__lus = [];
  document.addEventListener('vf-agent:ouvrir', (e) => { const r = { d: e.detail && e.detail.declencheur, id: e.detail && e.detail.id, e }; window.__ouv.push(r); });
  document.addEventListener('vf-agent:lu', (e) => window.__lus.push(e.detail && e.detail.id)); };
export const OUVERTS = () => new Promise((ok) => setTimeout(() => ok(window.__ouv.map((r) => [r.d, r.id, r.e.defaultPrevented])), 50));
JS

# ---------- scénario : toutes les sondes de page ----------
cat > "$AUX/r.mjs" <<'JS'
import { voies, WHO, corps, iso, HOSTILE, ORIGINE, RAPPORT, ESPIONS, OUVERTS } from './fix.mjs';
export const ids = ['R1', 'R2', 'R3', 'R4', 'R5', 'R5b', 'R7'];
const BAS = "(() => { const e = document.querySelector('.vf-fiche'); return !!e && e.getAttribute('aria-busy') !== 'true'; })()";
export default async function (h) {
  const fil = (now) => ({ 'wk-1': corps('wk-1', [{ t: iso(now, 150), genre: 'message', texte: HOSTILE }]), 'wk-2': corps('wk-2', [{ t: iso(now, 5), genre: 'message', texte: 'x' }]) });
  await h.monter({ voies, who: WHO, fil });
  await h.ev(ESPIONS);
  const avecFiche = await h.ev(() => !!window.__vfFiche);
  await h.section('R1', async () => {
    const r = await h.ev(() => ({ bouton: document.querySelectorAll('[data-vf-transcript]').length, texte: /Lire le transcript/.test(document.body.textContent),
      ligne: document.querySelectorAll('#vf-equipe li[data-vf-agent]').length,
      boites: [...document.querySelectorAll('#vf-equipe *')].filter((e) => getComputedStyle(e).maxHeight === '320px' || e.style.height === '320px').length }));
    h.egal('R1', 'régie montée (témoin positif : 5 lignes d\'agents), ni [data-vf-transcript], ni « Lire le transcript », ni boîte de 320 px dans l\'onglet',
      [r.ligne >= 4, r.bouton, r.texte, r.boites], [true, 0, false, 0]);
  });
  await h.section('R2', async () => {
    await h.ev((id) => { document.querySelector(`#vf-equipe li[data-vf-agent="${id}"] .vf-rg-act button`).click(); }, 'wk-1');
    await h.attendre(BAS, 'fiche posée');
    await h.attendre("document.querySelector('.vf-fiche').textContent.includes('onerror')", 'source lisible', 8000);
    const r = await h.ev(() => { const f = document.querySelector('.vf-fiche'); return { img: f.querySelectorAll('img, script, iframe').length, xss: window.__xss, src: f.textContent.includes('<img src=x onerror=window.__xss=1>'),
      attrs: [...f.querySelectorAll('*')].filter((e) => [...e.attributes].some((a) => /^on/i.test(a.name))).length }; });
    h.egal('R2', 'T26.7, T27.C1, T27.C2 contre la fiche : le message <img onerror> s\'affiche en texte (0 img, 0 attribut on*, source lisible, aucun script exécuté)', [r.img, r.attrs, r.src, r.xss], [0, 0, true, 0]);
    await h.fermer();
  });
  await h.section('R3', async () => {
    const attendu = await h.ev(() => window.__vfFriseModele.fmtDuree(8040));
    await h.ouvrir('wk-1', ORIGINE('wk-1')).catch(() => {});
    const r = await h.ev(() => { const t = (s) => [...document.querySelectorAll(s)].map((e) => e.textContent).join(' ');
      const chiffre = [...document.querySelectorAll('.vf-fiche-chiffre')].find((c) => /Au travail/.test(c.textContent));
      return { fiche: t('.vf-fiche'), cout: t('[class*="vf-cout"]'), frise: t('[class*="vf-frise"]'), travail: chiffre ? chiffre.querySelector('.vf-fiche-val').textContent.trim() : null }; });
    const cent = (x) => /101/.test(x);
    h.egal('R3', 'fixture dureeS = 101 h : aucun « 101 » dans la fiche, le coût ni la frise (durée des veilles jamais affichée)', [cent(r.fiche), cent(r.cout), cent(r.frise)], [false, false, false]);
    if (avecFiche) h.egal('R3.1', '« Au travail » de la fiche = somme des segments travail (2 h 14), jamais la durée qui compte les veilles', r.travail, attendu);
    else h.sonde('R3.1', '(sans fiche) « Au travail » : sans objet, la fiche est absente', true, 'sans objet');
    if (avecFiche) await h.fermer();
  });
  // R4 : T27.C1, T27.C2, T26.8 et T27.B2 rejoués contre la fiche (focus sur la fiche, lecture qui survit aux who, rien gardé, redemandée au rechargement)
  await h.section('R4', async () => {
    await h.ev((s) => document.querySelector(s).click(), ORIGINE('wk-1'));
    await h.attendre(BAS, 'fiche posée', 8000);
    await h.attendre("document.querySelector('.vf-fiche').textContent.includes('onerror')", 'fil lu', 8000);
    for (let n = 2; n <= 5; n++) await h.who(WHO.map((w) => ({ ...w, ageS: (w.ageS || 0) + n })), n);
    await h.ev(() => new Promise((ok) => setTimeout(ok, 300)));
    const r = await h.ev((hostile) => { const f = document.querySelector('.vf-fiche'), dump = JSON.stringify([...Object.entries(localStorage), ...Object.entries(sessionStorage)]);
      return { ouverte: !!f, texte: !!f && f.textContent.includes('onerror'), focus: !!f && f.contains(document.activeElement), stockage: dump.includes('onerror') || dump.includes(hostile) }; }, HOSTILE);
    h.egal('R4', 'T27.C1 : la fiche ouverte reste affichée après quatre who, le focus reste dans la fiche, rien du fil dans un stockage du navigateur', [r.ouverte, r.texte, r.focus, r.stockage], [true, true, true, false]);
    await h.s.naviguer(`${h.base}/equipe.html`);
    await h.attendre("!!document.querySelector('#vf-equipe') && !!window.VF_ETAT && !!window.VF_ETAT.lire('etat')", 'régie remontée', 15000);
    const apres = await h.ev(() => ({ fiche: !!document.querySelector('.vf-fiche'), reqs: window.__req.filter((u) => /transcript/.test(u)).length }));
    h.egal('R4', 'T27.C2 : après un rechargement la fiche n\'est pas rouverte et aucun fil n\'a été redemandé tout seul', [apres.fiche, apres.reqs], [false, 0]);
    await h.poser({ voies }); await h.filFixe(fil(await h.horloge())); await h.who(WHO); await h.ev(ESPIONS);
    await h.attendre("!!document.querySelector('#vf-equipe li[data-vf-agent=\"wk-2\"] .vf-rg-tog')", 'ligne de wk-2', 8000);
    await h.ev(() => window.__vfRegie.arriver('n:ag-wk-2'));
    await h.attendre(BAS, 'fiche posée par l\'ancre', 8000);
    const foc = await h.ev(() => { const f = document.querySelector('.vf-fiche'); return { dans: !!f && f.contains(document.activeElement), regie: !!document.activeElement.closest('#vf-equipe li[data-vf-agent]') }; });
    h.egal('R4', 'T26.8 et T27.B2 : arriver sur un agent donne le focus à la fiche (jamais à sa ligne de régie), sans rechargement', [foc.dans, foc.regie], [true, false]);
    await h.fermer().catch(() => {});
  });
  // R5 : arriver sur #r=n:ag-<id>
  await h.section('R5', async () => {
    await h.ev(() => { window.__ouv = []; window.__scrolls = 0; });
    await h.ev(() => { location.hash = '#r=n:ag-wk-2'; });
    await h.attendre("(window.__ouv || []).length >= 1", 'vf-agent:ouvrir (ancre)', 8000);
    await h.ev(() => new Promise((ok) => setTimeout(ok, 400)));
    const o = await h.ev(OUVERTS);
    const r = await h.ev(() => { const li = document.querySelector('#vf-equipe li[data-vf-agent="wk-2"]'), tog = li && li.querySelector('.vf-rg-tog');
      const f = document.querySelector('.vf-fiche'); return { fiches: document.querySelectorAll('.vf-fiche').length, titre: f ? f.getAttribute('aria-label') : null,
        deplie: tog ? tog.getAttribute('aria-expanded') : null, defil: window.__scrolls }; });
    h.egal('R5', '#r=n:ag-wk-2 : la régie émet vf-agent:ouvrir (ancre), la fiche l\'annule et s\'ouvre UNE fois sur cet agent ; la régie ne défile pas et ne déplie pas la ligne',
      [o.map((x) => x.slice(0, 3)), r.fiches, /Fiche de/.test(r.titre || ''), r.deplie, r.defil], [[['ancre', 'wk-2', true]], 1, true, 'false', 0]);
    await h.ev(() => { history.replaceState(null, '', location.pathname); });
    await h.fermer().catch(() => {});
  });
  // R5b : nom (clic, Entrée, Espace) et rapport — la 74 annule, ouvre par la fiche, rend le focus à l'origine
  await h.section('R5b', async () => {
    const cas = [['nom', 'clic', 'wk-2', ORIGINE('wk-2')], ['nom', 'Entrée', 'wk-2', ORIGINE('wk-2')], ['nom', 'Espace', 'wk-2', ORIGINE('wk-2')], ['rapport', 'clic', 'wk-5', RAPPORT('wk-5')]];
    for (const [decl, geste, id, sel] of cas) {
      await h.ev(() => { window.__ouv = []; window.__lus = []; });
      if (geste === 'clic') await h.ev((s) => document.querySelector(s).click(), sel);
      else { await h.ev((s) => document.querySelector(s).focus(), sel); if (geste === 'Entrée') await h.touche('Enter', 'Enter', 13, '\r'); else await h.touche(' ', 'Space', 32, ' '); }
      await h.attendre(BAS, 'fiche posée', 8000);
      const o = await h.ev(OUVERTS);
      const r = await h.ev(() => ({ ouverte: !!(window.__vfFiche && window.__vfFiche.ouverte()), lus: window.__lus.slice(), repli: document.querySelectorAll('#panel [data-vf-repli], #panel .vf-transcript, .vf-rg-lecteur').length }));
      h.egal('R5b', `${decl} (${geste}) : vf-agent:ouvrir annulé (defaultPrevented), la fiche s'ouvre, le lecteur de repli de la 73 ne s'ouvre pas, vf-agent:lu seulement pour un terminé`,
        [o.map((x) => x.slice(0, 3)), r.ouverte, r.repli, r.lus], [[[decl, id, true]], true, 0, id === 'wk-5' ? ['wk-5'] : []]);
      await h.echap();
      await h.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée', 8000);
      // le bouton « Lire le rapport » d'un terminé disparaît quand l'agent est marqué lu : le focus revient alors dans la régie, jamais sur BODY
      const foc = await h.ev((s, d) => (d === 'rapport' ? !!document.activeElement && document.activeElement !== document.body && !!document.activeElement.closest('#vf-equipe')
        : document.activeElement === document.querySelector(s)), sel, decl);
      h.egal('R5b', `${decl} (${geste}) : Échap ferme la fiche et rend le focus à l'élément d'origine (rapport : dans la régie, le bouton ayant disparu avec le marquage « lu »)`, foc, true);
    }
  });
  await h.section('R7', async () => {
    const r = await h.ev(() => typeof (window.__vfEquipeRendu && window.__vfEquipeRendu.transcript));
    h.egal('R7', 'garde : window.__vfEquipeRendu.transcript est ENCORE une fonction (retiré par 74-10 seul, 73-C2)', r, 'function');
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

# joue <port> [sondes attendues] : une ligne PASS/FAIL par sonde de page ; une section sans sonde est un FAIL nommé (sortie dans $SORTIE)
joue() {
  local port="$1" out line id lib ok ob
  out="$("$NODE" "$HERE_T/chrome-fiche.mjs" "$CHROME" "$AUX/r.mjs" "http://127.0.0.1:$port" 2>&1 | tail -1)"
  line="$("$NODE" -e 'let j; try { j = JSON.parse(process.argv[1]); } catch { process.exit(3); }
    if (!j.sondes) { console.log("ERR\t" + (j.erreur || "sortie illisible")); process.exit(0); }
    for (const s of j.sondes) console.log([s.ok ? "OK" : "KO", s.id, s.lib, s.obtenu].join("\t"));' "$out" 2>/dev/null)"
  SORTIE="$line"
  if [ -z "$line" ] || [ "${line%%$'\t'*}" = ERR ]; then
    echo "  ❌ FAIL — scénario interrompu"; echo "     obtenu:  [${line:-${out:0:200}}]"; FAIL=$((FAIL+1)); return
  fi
  while IFS=$'\t' read -r ok id lib ob; do
    if [ "$ok" = OK ]; then echo "  ✅ PASS — $id — $lib"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — $id — $lib"; echo "     obtenu:  [$ob]"; FAIL=$((FAIL+1)); fi
  done <<EOF
$line
EOF
}
# sonde_rouge <sonde> : 0 si la sortie de la dernière lecture contient une sonde KO dont l'identifiant commence par <sonde>
sonde_rouge() { printf '%s\n' "$SORTIE" | awk -F'\t' -v s="$1" '$1 == "KO" && index($2, s) == 1 { f = 1 } END { exit f ? 0 : 1 }'; }

# ---------- R6 (garde, sans navigateur) : aucun nœud de la carte « Terminés » dans le graphe du canevas ----------
cat > "$AUX/carte.mjs" <<'JS'
// carte.mjs <racine du module> : buildEquipeGraph d'un who qui porte un agent terminé il y a 5 h ; rend UNE ligne JSON
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(path.join(process.argv[2], 'scripts', 'vf-cockpit-equipe-carte.mjs')).href);
const who = { workers: [{ id: 'a', kind: 'session', etat: 'au-repos' }, { id: 'b', kind: 'subagent', etat: 'termine', ageS: 18000 }, { id: 'c', kind: 'subagent', etat: 'actif', ageS: 10 }] };
const g = m.buildEquipeGraph(who, { nom: 'Essai', racine: '.' });
console.log(JSON.stringify({ termine: g.meta.vf.compte.termine, nodes: g.nodes.length, terminesNoeud: g.nodes.filter((n) => n && (n.id === '~termines' || n.kind === 'terminés' || /^~termines/.test(String(n.id)))).length }));
JS
carte() { "$NODE" "$AUX/carte.mjs" "$1" 2>&1 | tail -1; }
R6_ATTENDU='{"termine":1,"nodes":0,"terminesNoeud":0}'

# ---------- R7 statique : l'export vit encore dans le module (retiré par 74-10 seul) ----------
ECART7="$(grep -c 'agentsDuNoeud, transcript,' "$UI/71-vf-equipe-rendu.js" 2>/dev/null || true)"

RACINE_MODULE=""
if [ -n "${RETRAITS_SANS_FICHE:-}" ]; then
  RACINE_MODULE="$(cockpit_module_copie)" || RACINE_MODULE=""
  rm -f "$RACINE_MODULE"/skills/cockpit-moteur/assets/ui/74-vf-fiche*.js
  export COCKPIT_MODULE="$RACINE_MODULE"
  echo "mode RETRAITS_SANS_FICHE : copie du module privée de ses ui/74-vf-fiche*.js ($(ls "$RACINE_MODULE"/skills/cockpit-moteur/assets/ui | grep -c '^74-vf-fiche') fichier(s) de fiche restant)"
fi

echo "=== R6 — aucune carte « Terminés » dans le graphe du canevas (garde, apparié : l'agent terminé est compté) ==="
assert_eq "R6 — buildEquipeGraph : l'agent terminé il y a 5 h est compté, aucun nœud, aucun nœud ~termines ni kind « terminés »" "$(carte "${RACINE_MODULE:-$SCRIPTS/..}")" "$R6_ATTENDU"
echo "=== R7 — l'export transcript est encore posé (garde statique) ==="
assert_eq "R7 — 71-vf-equipe-rendu.js exporte encore transcript (une ligne d'export)" "$ECART7" "1"

if [ -z "$CHROME" ]; then
  skip "R1, R2, R3, R5, R5b, R7 (page)" "pas de navigateur"
else
  demarrer base; PORT="$VF_PORT"; SRV="$VF_PID"
  assert_eq "S0 — contrôle positif : serveur de la suite démarré, page Équipe servie" "$([ "$PORT" -gt 0 ] && echo serveur)" "serveur"
  echo "=== R1 à R5b, R7 — page Équipe : retraits, rendu en texte, durée, ancre, nom, rapport ==="
  joue "$PORT"
  cockpit_arreter "$SRV"; SRV=""

  if [ -z "${RETRAITS_SANS_MUTANTS:-}" ] && [ -z "${RETRAITS_SANS_FICHE:-}" ]; then
    echo "=== mutants (copies du module ; chacun rougit sa sonde) ==="
    mutant_page() { # <nom> <sonde> <fichier> <expression sed>
      local nom="$1" sonde="$2" fic="$3" expr="$4"
      if ! cockpit_module_muter "$nom" "$fic" "$expr"; then echo "  ❌ FAIL — $nom — mutation non posée (ancre absente)"; FAIL=$((FAIL+1)); unset COCKPIT_MODULE; return; fi
      demarrer "$nom"
      if [ "${VF_PORT:-0}" -le 0 ]; then echo "  ❌ FAIL — $nom — serveur du mutant non démarré"; FAIL=$((FAIL+1)); unset COCKPIT_MODULE; return; fi
      local sav_p=$PASS sav_f=$FAIL; joue "$VF_PORT" > "$WORK/mut-$nom.out"; PASS=$sav_p; FAIL=$sav_f
      if sonde_rouge "$sonde"; then echo "MUTANT-ROUGE $nom $sonde"; PASS=$((PASS+1)); else echo "MUTANT-VERT $nom $sonde"; echo "  ❌ FAIL — $nom — la sonde $sonde n'a pas rougi"; FAIL=$((FAIL+1)); fi
      cockpit_arreter "$VF_PID"; unset COCKPIT_MODULE
    }
    mutant_page M-BOUTON-REVENU R1 72-vf-regie-rendu.js "s#'Lire le rapport');#'Lire le rapport'); b.setAttribute('data-vf-transcript', '');#"
    mutant_page M-DUREE-VEILLES-REVENUE R3 74-vf-fiche-faits.js "s#\['Au travail', f(d, 'travailS', (x) => M().fmtDuree(x))\]#['Au travail', M().fmtDuree(v ? v.dureeS : null)]#"
    mutant_page M-NON-ANNULE R5b 74-vf-fiche.js "s#e.preventDefault(); ouvrir(d.id, elementDe(d));#ouvrir(d.id, elementDe(d));#"
    mutant_page M-EXPORT-PREMATURE R7 71-vf-equipe-rendu.js "s#agentsDuNoeud, transcript, #agentsDuNoeud, #"
    # M-CARTE-REVENUE : sans navigateur, sur une copie du module
    if cockpit_module_muter M-CARTE-REVENUE vf-cockpit-equipe-carte.mjs "s#nodes: \[\], files: \[\]#nodes: [{ id: '~termines', kind: 'terminés' }], files: []#"; then
      if [ "$(carte "$COCKPIT_MODULE")" != "$R6_ATTENDU" ]; then echo "MUTANT-ROUGE M-CARTE-REVENUE R6"; PASS=$((PASS+1)); else echo "MUTANT-VERT M-CARTE-REVENUE R6"; echo "  ❌ FAIL — M-CARTE-REVENUE — R6 n'a pas rougi"; FAIL=$((FAIL+1)); fi
    else echo "  ❌ FAIL — M-CARTE-REVENUE — mutation non posée (ancre absente)"; FAIL=$((FAIL+1)); fi
    unset COCKPIT_MODULE
  fi
fi

echo
echo "durée : $(( $(date +%s) - T0 )) s"
echo "Résultat : $PASS réussis, $FAIL échecs, $SKIP sautés"
[ "$FAIL" -eq 0 ]
