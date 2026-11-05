#!/usr/bin/env bash
# test-cockpit-git-tiroir.sh — tiroir Git de la page (78-06 ; GITC-04, 05, 06, 08, 10, 11 ; P78-D-04, 10, 11, 12, 14, 19).
#   D1 ouverture depuis la seconde ligne, graphe servi, schéma vérifié · D2 sections, graphe complet, commandes à copier, états, XSS
#   D3 clavier, focus, coexistence avec le Terminal et le zoom, mobile
#   Mutants : M-HTML, M-COPIE, M-GLOBAL-G. La réponse `/api/vf/git` est figée (temoins/git-tiroir.json) et servie par un `fetch` remplacé dans la page.
#   Chrome headless en CDP (SAUTÉ, jamais compté réussi, sans navigateur), ports éphémères. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
UI="$(cd "$SCRIPTS/.." && pwd)/skills/cockpit-moteur/assets/ui"
TEMOIN="$HERE_T/temoins/git-tiroir.json"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
REAL_HOME="$HOME"; export HOME="$WORK/home"
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${TIROIR_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES)}"

cat > "$AUX/json.mjs" <<'JS'
const j = JSON.parse(process.argv[2]);
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/cdp-run.mjs" <<'JS'
// cdp-run.mjs <chrome> <scenario.js> [args…] : joue le corps asynchrone du scénario avec (s, ARGS) après avoir posé les crochets de pre.js (VF_PRE) ; une ligne JSON
import fs from 'node:fs';
const { executer } = await import(process.env.VF_CS);
const [, , chrome, fichier, ...ARGS] = process.argv;
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const corps = new AsyncFunction('s', 'ARGS', fs.readFileSync(fichier, 'utf8'));
const PRE = process.env.VF_PRE ? fs.readFileSync(process.env.VF_PRE, 'utf8') : '';
await executer(chrome, async (s) => {
  await s.send('Browser.grantPermissions', { permissions: ['clipboardReadWrite', 'clipboardSanitizedWrite'] }).catch(() => {});
  if (PRE) await s.send('Page.addScriptToEvaluateOnNewDocument', { source: PRE });
  return corps(s, ARGS);
}, { csp: true });
JS
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <fichier> <ancien> <nouveau> : remplace UNE occurrence ; échoue (code 1) si l'ancien texte est absent (un mutant mort ne prouve rien)
import fs from 'node:fs';
const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
export VF_CS="$HERE_T/chrome-session.mjs"; export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-25000}" VF_CDP_TAG=git-tiroir
cdp() { local r; r="$(node "$AUX/cdp-run.mjs" "$CHROME" "$@" 2>&1 | tail -1)"; case "$r" in *'"erreur"'*) echo "     (scénario interrompu : $r)" >&2;; esac; printf '%s\n' "$r"; }
jq_() { node "$AUX/json.mjs" "$1" "$2"; }
mutate() { node "$AUX/mut.mjs" "$@"; }

NODE="$(command -v node)"; ENVX=""
GIT="git -c user.email=t@t -c user.name=t"
mk_lab() {
  mkdir -p "$1/src" "$1/.planning/phases/01-x"
  printf 'export const util = () => 1;\n' > "$1/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$1/.planning/ROADMAP.md"
  printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$1/.planning/STATE.md"
  printf '<objective>Faire le socle</objective>\n' > "$1/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$1/.planning/phases/01-x/01-01-SUMMARY.md"
}
build_serve() { # $1 = lab, $2 = dossier de scripts (défaut : le module, ou TIROIR_SCRIPTS pour jouer la suite contre une copie) ; pose OUT, PORT ; démarre le serveur (SRV)
  env $ENVX "$NODE" "${2:-${TIROIR_SCRIPTS:-$SCRIPTS}}/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  OUT="$1/.vibeflow/cockpit"
  env $ENVX ${ENVS:-} "$NODE" "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
  SRV=$!
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
DEPOT="$WORK/depot"; mk_lab "$DEPOT"
$GIT -C "$DEPOT" init -q -b main && $GIT -C "$DEPOT" add -A && $GIT -C "$DEPOT" commit -q -m init

# crochets posés avant la page : erreurs, alert, `fetch` de /api/vf/git remplacé par la réponse témoin (window.__vfGit.reponse), journal des requêtes
{ printf 'window.__vfGit = { reponse: '; cat "$TEMOIN"; printf ', delai: 0 };\n'; cat <<'JS'; } > "$AUX/pre.js"
window.__errs = []; window.__vfReqs = []; window.__TEMOIN_REF = JSON.parse(JSON.stringify(window.__vfGit.reponse));
window.__couleur = (v) => { const p = document.createElement('i'); p.style.color = 'var(' + v + ')'; document.body.appendChild(p); const c = getComputedStyle(p).color; p.remove(); return c; };
addEventListener('error', (e) => window.__errs.push(String(e.message)));
addEventListener('unhandledrejection', (e) => window.__errs.push('rejet ' + String(e.reason)));
{ const ce = console.error; console.error = (...a) => { window.__errs.push(a.map(String).join(' ')); ce.apply(console, a); } }
window.__alerte = 0; window.alert = () => { window.__alerte++; };
{ const f0 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
    if (/\/api\/vf\/git(\?|$)/.test(url)) {
      window.__vfReqs.push({ url, methode: (i && i.method) || 'GET', headers: (i && i.headers) || {} });
      return new Promise((ok) => setTimeout(() => ok(new Response(JSON.stringify(window.__vfGit.reponse), { status: 200, headers: { 'content-type': 'application/json' } })), window.__vfGit.delai || 0)); }
    return f0(u, i); }; }
JS
export VF_PRE="$AUX/pre.js"

echo "=== D1 — de la seconde ligne au tiroir ouvert ==="
if [ -z "$CHROME" ]; then skip "D1, D2, D3" "pas de navigateur"; else
  build_serve "$DEPOT"; BASE="http://127.0.0.1:$PORT"
  cat > "$AUX/d1.js" <<'JS'
const [base] = ARGS;
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#vf-git-ligne') && getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {};
const vis = `(() => { const t = document.querySelector('#vf-git-tiroir'); return !!t && !t.hidden && t.getBoundingClientRect().width > 0 && getComputedStyle(t).display !== 'none'; })()`;
out.avant = await s.ev(vis);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`${vis} && document.querySelectorAll('#vf-git-tiroir li[role=option]').length > 0`, 'tiroir ouvert avec ses rangées');
out.ouvert = await s.ev(`(() => ({ expanded: document.querySelector('#vf-git-ligne').getAttribute('aria-expanded'), rangees: document.querySelectorAll('#vf-git-tiroir ol[role=listbox] > li[role=option]').length,
  graphes: document.querySelectorAll('#vf-git-tiroir li[role=option] svg.vf-git-gcol').length, role: document.querySelector('#vf-git-tiroir').getAttribute('role'), label: document.querySelector('#vf-git-tiroir').getAttribute('aria-label'),
  balise: document.querySelector('#vf-git-tiroir').tagName, classes: document.querySelector('#vf-git-tiroir').className }))()`);
out.reqs = await s.ev(`window.__vfReqs.map((r) => ({ methode: r.methode, jeton: r.headers['x-vf-cockpit-token'] === window.VF_COCKPIT_SERVER.token && !!window.VF_COCKPIT_SERVER.token }))`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`!(${vis})`, 'tiroir fermé');
out.ferme = await s.ev(`document.querySelector('#vf-git-ligne').getAttribute('aria-expanded')`);
// D1.2 : réponse hors schéma -> indisponible, aucun rendu partiel
await s.ev(`window.__vfGit.reponse = { schema: 'autre@1', etat: 'ok', rangees: [{ h: 'a', s: 'pirate' }] }; window.VFGitTiroir.recharger()`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`${vis} && /Git est indisponible/.test(document.querySelector('#vf-git-tiroir').textContent)`, 'carte indisponible sur schéma refusé');
out.horsSchema = await s.ev(`({ rangees: document.querySelectorAll('#vf-git-tiroir li[role=option]').length, pirate: document.querySelector('#vf-git-tiroir').textContent.includes('pirate') })`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R="$(cdp "$AUX/d1.js" "$BASE")"
  assert_eq "D1.0 — témoin : le tiroir n'existe pas ouvert avant le clic" "$(jq_ "$R" 'j.avant' 2>/dev/null)" "false"
  assert_eq "D1.1 — clic sur la seconde ligne : tiroir aside#vf-git-tiroir.vf-git-tiroir.glass, role complementary, libellé « Historique Git »" "$(jq_ "$R" '[j.ouvert.balise, /vf-git-tiroir/.test(j.ouvert.classes), /glass/.test(j.ouvert.classes), j.ouvert.role, j.ouvert.label].join("|")' 2>/dev/null)" "ASIDE|true|true|complementary|Historique Git"
  assert_eq "D1.1 — aria-expanded de la ligne = true tiroir ouvert" "$(jq_ "$R" 'j.ouvert.expanded' 2>/dev/null)" "true"
  assert_eq "D1.1 — 40 li[role=option] dans ol[role=listbox], une colonne SVG par rangée" "$(jq_ "$R" '[j.ouvert.rangees, j.ouvert.graphes].join("|")' 2>/dev/null)" "40|40"
  assert_eq "D1.1 — second clic : tiroir caché, aria-expanded false" "$(jq_ "$R" 'j.ferme' 2>/dev/null)" "false"
  assert_eq "D1.2 — une seule requête, GET, avec le jeton de la page" "$(jq_ "$R" 'j.reqs.map((r) => r.methode + ":" + r.jeton).join(",")' 2>/dev/null)" "GET:true"
  assert_eq "D1.2 — réponse hors schéma : carte « Git est indisponible », aucune rangée, rien du contenu refusé" "$(jq_ "$R" '[j.horsSchema.rangees, j.horsSchema.pirate].join("|")' 2>/dev/null)" "0|false"
  assert_eq "D1.x — aucune erreur de page" "$(jq_ "$R" 'j.errs.length' 2>/dev/null)" "0"
  echo "=== D2 — sections, graphe, étiquettes, commandes à copier, XSS ==="
  cat > "$AUX/d2.js" <<'JS'
const [base] = ARGS;
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#vf-git-ligne') && getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {};
const T = `document.querySelector('#vf-git-tiroir')`;
await s.ev(`window.__copies = []; navigator.clipboard.writeText = (t) => { window.__copies.push(t); return window.__refuse ? Promise.reject(new Error('refus')) : Promise.resolve(); }`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length === 40`, 'rangées');
out.ouvert = await s.ev(`({ rangees: document.querySelectorAll('#vf-git-tiroir li[role=option]').length })`);
// D2.1 : ordre, état et compteur des sections
out.sections = await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-sec > button')].map((b) => [b.querySelector('.vf-git-sec-n').textContent, b.getAttribute('aria-expanded'), (b.querySelector('.meta') || { textContent: '' }).textContent].join(':'))`);
await s.ev(`window.__vfGit.reponse = Object.assign({}, window.__vfGit.reponse, { tags: [], stash: [] }); window.VFGitTiroir.recharger()`);
await s.attendre(`!document.querySelector('#vf-git-tiroir #vf-git-s-tags')`, 'section Tags retirée');
out.sansDonnee = await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-sec > button .vf-git-sec-n')].map((b) => b.textContent)`);
await s.ev(`window.__vfGit.reponse = Object.assign({}, window.__vfGit.reponse, { rangees: [] }); window.VFGitTiroir.recharger()`);
await s.attendre(`/Aucun commit à afficher/.test(${T}.textContent)`, 'graphe vide');
out.grapheVide = await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-sec > button .vf-git-sec-n')].map((b) => b.textContent).includes('Graphe')`);
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); window.VFGitTiroir.recharger()`);
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length === 40 && !!document.querySelector('#vf-git-s-tags')`, 'témoin rétabli');
// D2.2 : graphe
out.graphe = await s.ev(`(() => { const T = ${T}, svgs = [...T.querySelectorAll('svg.vf-git-gcol')], cx = [...T.querySelectorAll('circle.vf-git-noeud')].map((c) => Number(c.getAttribute('cx')));
  const n = T.querySelector('circle.vf-git-noeud'), li0 = T.querySelector('li[role=option]');
  const teinte = (k) => { const p = T.querySelector('path.vf-git-t' + k); return p ? getComputedStyle(p).stroke : null; };
  const tete = T.querySelectorAll('circle.vf-git-tete'), creux = T.querySelectorAll('circle.vf-git-creux');
  const h17 = T.querySelector('li[data-h="1717171717171717171717171717171717171717"]'), h0 = li0;
  return { largeurs: [...new Set(svgs.map((s) => s.getAttribute('width')))], maxCx: Math.max(...cx), plus: (T.querySelector('.vf-git-plus') || {}).textContent, r: n.getAttribute('r'), trait: n.getAttribute('stroke-width'),
    arcs: [...T.querySelectorAll('path')].filter((p) => /A16 16 0 0 [01] /.test(p.getAttribute('d'))).length, tetes: tete.length, creux: creux.length,
    teteFill: getComputedStyle(tete[0]).fill, anneau: !!tete[0].parentNode.querySelector('.vf-git-anneau') && getComputedStyle(tete[0].parentNode.querySelector('.vf-git-anneau')).stroke,
    creuxFill: getComputedStyle(creux[0]).fill, normalFill: getComputedStyle(n).fill, hLi: Math.round(li0.getBoundingClientRect().height), hSvg: Math.round(svgs[0].getBoundingClientRect().height),
    couleurs: [0, 1, 2, 3, 4, 5].map(teinte), tirets17: h17 ? h17.querySelectorAll('path[stroke-dasharray]').length : -1, tirets0: h0.querySelectorAll('path[stroke-dasharray]').length, ariaHidden: svgs.every((s) => s.getAttribute('aria-hidden') === 'true') }; })()`);
out.attendu = await s.ev(`({ text: __couleur('--text'), ring: __couleur('--ring'), surface: __couleur('--surface'), lanes: ['--text-3', '--k-http', '--k-call', '--k-data', '--k-event', '--k-queue'].map(__couleur) })`);
// D2.3 : étiquettes et mergées
out.etiq = await s.ev(`(() => { const li = document.querySelector('#vf-git-tiroir li[data-h="1818181818181818181818181818181818181818"]'), l1 = li.querySelector('.vf-git-l1'), plus = l1.querySelector('.meta');
  return { pilules: l1.querySelectorAll('.vf-git-ref').length, plus: plus && plus.textContent, titre: plus && plus.title }; })()`);
out.merg0 = await s.ev(`(() => { const b = document.querySelector('#vf-git-tiroir .vf-git-merg-b'); return { texte: b.textContent, ouvert: b.getAttribute('aria-expanded'), cache: b.nextElementSibling.hidden }; })()`);
await s.ev(`document.querySelector('#vf-git-tiroir .vf-git-merg-b').click()`);
out.merg1 = await s.ev(`(() => { const b = document.querySelector('#vf-git-tiroir .vf-git-merg-b'), l = b.nextElementSibling; return { ouvert: b.getAttribute('aria-expanded'), cache: l.hidden, noms: [...l.querySelectorAll('.vf-git-mono')].map((m) => m.textContent), codes: l.querySelectorAll('code').length, sans: l.querySelectorAll('.vf-git-sans').length }; })()`);
// D2.4 : copie (le texte reçu par l'API = le texte du <code> affiché)
await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-sec-t')].forEach((b) => { if (b.getAttribute('aria-expanded') !== 'true') b.click(); })`);
const cible = `[...document.querySelectorAll('#vf-git-tiroir .vf-git-cmd code')].find((c) => c.textContent.includes('<b>vieille</b>'))`;
await s.ev(`${cible}.parentNode.querySelector('button').click()`);
await s.attendre(`window.__copies.length === 1`, 'copie');
out.copie = await s.ev(`({ spy: window.__copies[0], affiche: ${cible}.textContent, retour: ${cible}.parentNode.querySelector('.vf-git-retour').textContent, live: document.querySelector('#vf-git-tiroir .vf-git-live').textContent, label: ${cible}.parentNode.querySelector('button').getAttribute('aria-label') })`);
await s.ev(`new Promise((r) => setTimeout(r, 1900))`);
out.copie.apres = await s.ev(`${cible}.parentNode.querySelector('.vf-git-retour').textContent`);
await s.ev(`window.__refuse = true; ${cible}.parentNode.querySelector('button').click()`);
await s.attendre(`/Copie impossible/.test(${cible}.parentNode.querySelector('.vf-git-retour').textContent)`, 'copie refusée');
out.refus = await s.ev(`({ retour: ${cible}.parentNode.querySelector('.vf-git-retour').textContent, selection: String(window.getSelection()), affiche: ${cible}.textContent })`);
// D2.5 : XSS (tout est déplié)
await s.ev(`new Promise((r) => setTimeout(r, 400))`);
out.xss = await s.ev(`(() => { const T = ${T}, tx = T.textContent;
  return { img: T.querySelectorAll('img, script, b, u, iframe, style').length, svgEtrangers: [...T.querySelectorAll('svg')].filter((s) => !s.classList.contains('vf-git-gcol') && !s.classList.contains('i')).length, surveillants: T.querySelectorAll('[onload], [onerror]').length,
    lit: ['<svg/onload=alert(1)>', '<img src=x onerror=alert(2)>', '<b>x</b>', '<script>alert(3)</script>', '<iframe src=x>', 'WIP <u>essai</u>', '<b>vieille</b>'].map((t) => tx.includes(t)).join(',') }; })()`);
out.alerte = await s.ev(`window.__alerte`);
out.csp = s.violations.length;
out.errs = await s.ev(`window.__errs`);
// D2.2 (suite) : 768 px -> rangées et colonnes de 44 px
await s.send('Emulation.setDeviceMetricsOverride', { width: 768, height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`Math.round(document.querySelector('#vf-git-tiroir li[role=option]').getBoundingClientRect().height) === 44`, 'rangée de 44 px');
out.mobile = await s.ev(`({ li: Math.round(document.querySelector('#vf-git-tiroir li[role=option]').getBoundingClientRect().height), svg: Math.round(document.querySelector('#vf-git-tiroir svg.vf-git-gcol').getBoundingClientRect().height) })`);
return out;
JS
  R2="$(cdp "$AUX/d2.js" "$BASE")"
  assert_eq "D2.1 — ordre des sections et état initial : Worktrees et Graphe ouvertes, Tags, Stash, Auteurs fermées avec compteur" "$(jq_ "$R2" 'j.sections.join("|")' 2>/dev/null)" "Worktrees:true:3|Graphe:true:|Tags:false:2|Stash:false:2|Auteurs et activité:false:3"
  assert_eq "D2.1 — section sans donnée masquée (Tags, Stash), Graphe gardée même sans rangée" "$(jq_ "$R2" '[j.sansDonnee.join(","), j.grapheVide].join("|")' 2>/dev/null)" "Worktrees,Graphe,Auteurs et activité|true"
  assert_eq "D2.2 — 6 couloirs au plus (colonne de 96 px, nœud le plus à droite à 88) et « +17 » servi" "$(jq_ "$R2" '[j.graphe.largeurs.join(","), j.graphe.maxCx, j.graphe.plus].join("|")' 2>/dev/null)" "96|88|+17"
  assert_eq "D2.2 — nœud r=4, trait 1,75, quart de cercle de rayon 16 (arc A16 16), colonne aria-hidden" "$(jq_ "$R2" '[j.graphe.r, j.graphe.trait, j.graphe.arcs > 0, j.graphe.ariaHidden].join("|")' 2>/dev/null)" "4|1.75|true|true"
  assert_eq "D2.2 — HEAD : un nœud plein couleur du texte avec son anneau --ring ; fusions : nœuds creux à fond --surface (3)" "$(jq_ "$R2" 'JSON.stringify([j.graphe.tetes, j.graphe.teteFill === j.attendu.text, j.graphe.anneau === j.attendu.ring, j.graphe.creux, j.graphe.creuxFill === j.attendu.surface, j.graphe.normalFill !== j.graphe.creuxFill])' 2>/dev/null)" "[1,true,true,3,true,true]"
  assert_eq "D2.2 — couloirs : --text-3 puis --k-http, --k-call, --k-data, --k-event, --k-queue (couleur calculée des traits)" "$(jq_ "$R2" 'JSON.stringify(j.graphe.couleurs) === JSON.stringify(j.attendu.lanes) && new Set(j.attendu.lanes).size === 6' 2>/dev/null)" "true"
  assert_eq "D2.2 — branche distante seule en tirets, HEAD local en trait plein" "$(jq_ "$R2" 'j.graphe.tirets17 > 0 && j.graphe.tirets0 === 0' 2>/dev/null)" "true"
  assert_eq "D2.2 — rangée de 40 px (colonne 40 px) à 1440, 44 px à 768" "$(jq_ "$R2" '[j.graphe.hLi, j.graphe.hSvg, j.mobile.li, j.mobile.svg].join("|")' 2>/dev/null)" "40|40|44|44"
  assert_eq "D2.3 — étiquettes : 2 pilules puis « +4 » (2 en trop sur la rangée + refsPlus 2 servi), le title liste le reste" "$(jq_ "$R2" '[j.etiq.pilules, j.etiq.plus, /v0\.9/.test(j.etiq.titre) && /feat\/quatre/.test(j.etiq.titre) && /et 2 autres/.test(j.etiq.titre)].join("|")' 2>/dev/null)" "2|+4|true"
  assert_eq "D2.3 — mergées : « 4 branches mergées » repliées puis dépliées (4 noms, 3 commandes, 1 absence dite)" "$(jq_ "$R2" '[j.merg0.texte, j.merg0.ouvert, j.merg0.cache, j.merg1.ouvert, j.merg1.cache, j.merg1.noms.length, j.merg1.codes, j.merg1.sans].join("|")' 2>/dev/null)" "4 branches mergées|false|true|true|false|4|3|1"
  assert_eq "D2.4 — copie : l'API reçoit exactement le texte du <code> affiché (hostile compris), « Copiée », annonce, retour effacé après 1,6 s" "$(jq_ "$R2" '[j.copie.spy === j.copie.affiche, j.copie.spy.includes("<b>vieille</b>"), j.copie.retour, j.copie.live, j.copie.apres === "", j.copie.label === "Copier la commande : " + j.copie.affiche].join("|")' 2>/dev/null)" "true|true|Copiée|Commande copiée|true|true"
  assert_eq "D2.4 — copie refusée : « Copie impossible, commande sélectionnée » et la commande est la sélection" "$(jq_ "$R2" '[j.refus.retour, j.refus.selection === j.refus.affiche].join("|")' 2>/dev/null)" "Copie impossible, commande sélectionnée|true"
  assert_eq "D2.5 — XSS : 0 img, script, b, u, iframe ; aucun svg étranger ; aucun attribut onload ; chaînes hostiles lues telles quelles" "$(jq_ "$R2" '[j.xss.img, j.xss.svgEtrangers, j.xss.surveillants, j.xss.lit].join("|")' 2>/dev/null)" "0|0|0|true,true,true,true,true,true,true"
  assert_eq "D2.5 — aucun alert, 0 violation CSP, 0 erreur de page" "$(jq_ "$R2" '[j.alerte, j.csp, j.errs.length].join("|")' 2>/dev/null)" "0|0|0"
  cat > "$AUX/d2b.js" <<'JS'
const [base] = ARGS;
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#vf-git-ligne') && getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {}, T = `document.querySelector('#vf-git-tiroir')`, attente = (ms) => s.ev(`new Promise((r) => setTimeout(r, ${ms}))`);
// D2.6 : indisponible, puis « Réessayer » (nouveau GET) avec le témoin rétabli
await s.ev(`window.__vfGit.reponse = { schema: 'vibeflow/cockpit-git@1', etat: 'indisponible', entete: { etat: 'indisponible', depot: 'depot' }, commandes: { vide: null, diagnostic: 'git status' } }; document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`/Git est indisponible/.test(${T}.textContent)`, 'carte indisponible');
out.indispo = await s.ev(`({ code: [...${T}.querySelectorAll('.vf-git-cmd code')].map((c) => c.textContent), bouton: [...${T}.querySelectorAll('button')].some((b) => b.textContent === 'Réessayer'), ligne: document.querySelector('#vf-git-ligne').textContent, reqs: window.__vfReqs.length })`);
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); [...${T}.querySelectorAll('button')].find((b) => b.textContent === 'Réessayer').click()`);
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length === 40`, 'rangées après Réessayer');
out.reessai = await s.ev(`({ reqs: window.__vfReqs.length, page: !!document.querySelector('#proj-name') })`);
// vide
await s.ev(`window.__vfGit.reponse = { schema: 'vibeflow/cockpit-git@1', etat: 'vide', entete: { etat: 'ok', depot: 'depot', branche: 'main', detache: false }, commandes: { vide: 'git commit -m "premier commit"', diagnostic: 'git status' } }; window.VFGitTiroir.recharger()`);
await s.attendre(`/Aucun commit pour l.instant/.test(${T}.textContent)`, 'état vide');
out.vide = await s.ev(`({ code: [...${T}.querySelectorAll('.vf-git-cmd code')].map((c) => c.textContent), rangees: ${T}.querySelectorAll('li[role=option]').length })`);
// chargement : rien avant 150 ms, puis aria-busy et trois rangées fantômes
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); window.__vfGit.delai = 500; void window.VFGitTiroir.recharger(); 0`);
await attente(60);
out.avant150 = await s.ev(`({ busy: ${T}.querySelector('[aria-busy="true"]') !== null || ${T}.querySelector('.vf-git-corps').getAttribute('aria-busy') === 'true', fantomes: ${T}.querySelectorAll('.vf-git-fantome').length })`);
await attente(200);
out.pendant = await s.ev(`({ busy: ${T}.querySelector('.vf-git-corps').getAttribute('aria-busy'), fantomes: ${T}.querySelectorAll('.vf-git-fantome').length, texte: /Lecture du dépôt/.test(${T}.textContent), anim: ${T}.querySelector('.vf-git-fantome') ? getComputedStyle(${T}.querySelector('.vf-git-fantome')).animationName : 'none' })`);
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length === 40`, 'rangées après le délai');
out.apres = await s.ev(`({ busy: ${T}.querySelector('.vf-git-corps').getAttribute('aria-busy'), fantomes: ${T}.querySelectorAll('.vf-git-fantome').length })`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R2B="$(cdp "$AUX/d2b.js" "$BASE")"
  assert_eq "D2.6 — indisponible : carte « Git est indisponible », « Réessayer », commande git status, l'en-tête dit « Branche indisponible »" "$(jq_ "$R2B" '[j.indispo.code.join(","), j.indispo.bouton, /Branche indisponible/.test(j.indispo.ligne)].join("|")' 2>/dev/null)" "git status|true|true"
  assert_eq "D2.6 — « Réessayer » relance un GET (2 requêtes en tout), la page continue, 40 rangées" "$(jq_ "$R2B" '[j.reessai.reqs, j.reessai.page].join("|")' 2>/dev/null)" "2|true"
  assert_eq "D2.6 — vide : « Aucun commit pour l'instant », commande git commit -m \"premier commit\", aucune rangée" "$(jq_ "$R2B" '[j.vide.code.join(","), j.vide.rangees].join("|")' 2>/dev/null)" 'git commit -m "premier commit"|0'
  assert_eq "D2.6 — chargement : rien à 60 ms ; à 260 ms aria-busy, 3 rangées fantômes, « Lecture du dépôt », sans animation ; réponse reçue : plus rien" "$(jq_ "$R2B" 'JSON.stringify([j.avant150.busy, j.avant150.fantomes, j.pendant.busy, j.pendant.fantomes, j.pendant.texte, j.pendant.anim, j.apres.busy, j.apres.fantomes])' 2>/dev/null)" '[false,0,"true",3,true,"none",null,0]'
  assert_eq "D2.x — aucune erreur de page (états)" "$(jq_ "$R2B" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
  # --- copies privées du module pour les mutants (build lit assets/ui/*.js) : chaque mutant a son propre lab et son propre serveur ---
  mkmod() { local d="$WORK/mod-$1"; mkdir -p "$d/scripts" "$d/skills"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/scripts/"; cp -R "$SCRIPTS/../skills/cockpit-moteur" "$d/skills/cockpit-moteur"; echo "$d/scripts"; }
  mutlab() { local L="$WORK/lab-$1"; mk_lab "$L"; $GIT -C "$L" init -q -b main && $GIT -C "$L" add -A && $GIT -C "$L" commit -q -m init; echo "$L"; }
  mutant() { # mutant <nom> <fichier ui> <ancien> <nouveau> <scénario> -> RM (une ligne JSON) ; une mutation impossible compte comme un échec
    local M L; M="$(mkmod "$1")"; L="$(mutlab "$1")"
    if ! mutate "$M/../skills/cockpit-moteur/assets/ui/$2" "$3" "$4"; then echo "  ❌ FAIL — $1 : mutation impossible"; FAIL=$((FAIL+1)); RM="{}"; return; fi
    build_serve "$L" "$M"; RM="$(cdp "$AUX/$5" "http://127.0.0.1:$PORT")"; stop_srv
    [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$RM" > "$TIROIR_TRACE-$1.json"
  }
  mutant M-HTML 77-vf-git-rendu.js "l1.appendChild(el('span', 'vf-git-msg', r.s));" "{ const m = el('span', 'vf-git-msg'); m.innerHTML = r.s; l1.appendChild(m); }" d2.js
  assert_eq "M-HTML — rougit D2.5 (un message rendu en HTML fait naître un <img>) alors que les 40 rangées sont là (pas une panne d'un autre ordre)" "$(jq_ "$RM" '[j.xss.img > 0, j.xss.lit.includes("false"), j.ouvert.rangees].join("|")' 2>/dev/null)" "true|true|40"
  mutant M-COPIE 77-vf-git-rendu.js "writeText(code.textContent)" "writeText(code.textContent.slice(0, -1))" d2.js
  assert_eq "M-COPIE — rougit D2.4 (le texte reçu par l'API n'est plus celui du <code>) alors que la copie a bien eu lieu" "$(jq_ "$RM" '[j.copie.spy === j.copie.affiche, typeof j.copie.spy, j.copie.retour].join("|")' 2>/dev/null)" "false|string|Copiée"
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
