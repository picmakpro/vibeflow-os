#!/usr/bin/env bash
# test-cockpit-git-tiroir.sh — tiroir Git de la page (78-06 ; GITC-04, 05, 06, 08, 10, 11 ; P78-D-04, 10, 11, 12, 14, 19).
#   D1 ouverture depuis la seconde ligne, graphe servi, schéma vérifié · D2 sections, graphe complet, commandes à copier, états, XSS
#   D3 clavier, focus, coexistence avec le Terminal et le zoom, mobile
#   D7 détail d'un commit sous sa rangée · D8 clavier du graphe, état des worktrees · D9 rafraîchissement par vf-git:signal (78-10)
#   Mutants : M-HTML, M-COPIE, M-GLOBAL-G, M-HORS-DEPOT, M-DETAIL-HTML, M-SELECTION, M-RAFALE. La réponse `/api/vf/git` est figée (temoins/git-tiroir.json) et servie par un `fetch` remplacé dans la page.
#   Chrome headless en CDP (SAUTÉ, jamais compté réussi, sans navigateur), ports éphémères. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
UI="$(cd "$SCRIPTS/.." && pwd)/skills/cockpit-moteur/assets/ui"
TEMOIN="$HERE_T/temoins/git-tiroir.json"
DETAILS="$HERE_T/temoins/git-tiroir-details.json"
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
{ printf 'window.__vfDet = '; cat "$DETAILS"; printf ';\n'; cat <<'JS'; } >> "$AUX/pre.js"
window.__vfDet.erreurs = {}; window.__vfDetReqs = [];
{ const f1 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url, rep = (st, o) => Promise.resolve(new Response(JSON.stringify(o), { status: st, headers: { 'content-type': 'application/json' } }));
    const m = /^\/api\/vf\/git\/(commit|worktrees)(\?|$)/.exec(url);
    if (!m) return f1(u, i);
    window.__vfDetReqs.push({ url, route: m[1], methode: (i && i.method) || 'GET', headers: (i && i.headers) || {} });
    if (m[1] === 'worktrees') return rep(200, window.__vfDet.worktrees);
    const sha = decodeURIComponent((/sha=([^&]*)/.exec(url) || [])[1] || '');
    if (window.__vfDet.erreurs[sha]) return rep(window.__vfDet.erreurs[sha], { erreur: 'commit-inconnu' });
    return rep(200, Object.assign({}, window.__vfDet.commit, { h: sha, h7: sha.slice(0, 7), commandes: { show: 'git show --stat --end-of-options ' + sha.slice(0, 7), detacher: 'git switch --detach --end-of-options ' + sha.slice(0, 7) } })); }; }
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
await s.attendre(`Math.round(document.querySelector('#vf-git-tiroir li[role=option]').getBoundingClientRect().height) === 44 && Math.round(document.querySelector('#vf-git-tiroir svg.vf-git-gcol').getBoundingClientRect().height) === 44`, 'rangée et colonne de 44 px (le rendu suit le changement de requête media)');
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
  echo "=== D3 — clavier, focus, coexistence, mobile ==="
  cat > "$AUX/touche.js" <<'JS'
// aide partagée des scénarios D3 (recopiée en tête de chaque corps) : une vraie frappe CDP, avec ses modificateurs
const VK = { Escape: 27, '/': 191, '=': 187, '-': 189 }, CODE = { Escape: 'Escape', '/': 'Slash', '=': 'Equal', '-': 'Minus' };
const touche = async (key, o = {}) => {
  for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code: CODE[key] || 'Key' + key.toUpperCase(), windowsVirtualKeyCode: VK[key] || key.toUpperCase().charCodeAt(0), modifiers: o.modifiers || 0, ...(type === 'keyDown' && key.length === 1 && !o.modifiers ? { text: key } : {}) });
};
const fenetre = (w, h = 900) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
const pret = () => s.attendre(`document.readyState === 'complete' && !!document.querySelector('#vf-git-ligne') && !!window.VibeFlow`, 'page prête');
const OUVERT = `(() => { const t = document.querySelector('#vf-git-tiroir'); return !!t && !t.hidden; })()`;
JS
  cat > "$AUX/d3a.js" <<'JS'
const [base] = ARGS;
await fenetre(1440); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {}, fermer = () => s.ev(`window.VFGitTiroir.fermer()`);
await s.ev(`document.activeElement && document.activeElement.blur()`);
// D3.1 : g ouvre puis ferme ; ignorée dans un champ, avec modificateur, palette ouverte
await touche('g'); out.g1 = await s.ev(OUVERT); await touche('g'); out.g2 = await s.ev(OUVERT);
for (const [nom, html] of [['input', '<input id="t-champ">'], ['textarea', '<textarea id="t-champ"></textarea>'], ['edit', '<div id="t-champ" contenteditable="true" tabindex="0">x</div>']]) {
  await s.ev(`document.body.insertAdjacentHTML('beforeend', ${JSON.stringify(html)}); document.querySelector('#t-champ').focus()`);
  await touche('g');
  out['champ_' + nom] = await s.ev(`({ ouvert: ${OUVERT}, valeur: document.querySelector('#t-champ').value ?? document.querySelector('#t-champ').textContent })`);
  await s.ev(`document.querySelector('#t-champ').remove()`); await fermer();
}
out.modif = [];
for (const m of [2, 1, 4]) { await s.ev(`document.activeElement && document.activeElement.blur()`); await touche('g', { modifiers: m }); out.modif.push(await s.ev(OUVERT)); await fermer(); }
await s.ev(`document.activeElement && document.activeElement.blur(); document.querySelector('#palette').classList.add('open')`);
await touche('g'); out.palette = await s.ev(OUVERT); await s.ev(`document.querySelector('#palette').classList.remove('open')`); await fermer();
// D3.7 : animation d'entrée (témoin positif), puis aucune sous mouvement réduit
const anim = `(() => { window.VFGitTiroir.ouvrir(); const n = document.querySelector('#vf-git-tiroir').getAnimations().length; window.VFGitTiroir.fermer(); return n; })()`;
out.anim = await s.ev(anim);
await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
out.animReduit = await s.ev(anim);
await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: '' }] });
// D3.2 : Échap ferme le tiroir (focus dans le tiroir ou sur l'ouvreur) sans toucher la sélection du viewer ; il ne l'avale pas tiroir fermé
await s.ev(`window.__id = VibeFlow.graph.nodes[0].id; VibeFlow.select(window.__id)`);
const etat = `({ ouvert: ${OUVERT}, focus: (document.activeElement || {}).id || '', titre: !!document.activeElement && document.activeElement.classList.contains('vf-git-titre-t'), selection: VibeFlow.state.selected === window.__id, vue: VibeFlow.state.container })`;
out.sel0 = await s.ev(`VibeFlow.state.selected === window.__id`);
await touche('g'); out.ouverture = await s.ev(etat);
await touche('Escape'); out.echapTiroir = await s.ev(etat);
await touche('g'); await s.ev(`document.querySelector('#vf-git-ligne').focus()`); await touche('Escape'); out.echapLigne = await s.ev(etat);
await s.ev(`document.querySelector('#vf-git-ligne').focus()`); await touche('Escape'); out.echapFerme = await s.ev(etat);
await s.ev(`VibeFlow.select(window.__id)`); await touche('g'); await touche('/'); await s.attendre(`!!document.activeElement && document.activeElement.id === 'search'`, 'focus dans la palette'); out.palette1 = await s.ev(`({ palette: document.querySelector('#palette').classList.contains('open'), ouvert: ${OUVERT} })`);
await touche('Escape'); out.palette2 = await s.ev(`({ palette: document.querySelector('#palette').classList.contains('open'), ouvert: ${OUVERT} })`);
// D3.3 : #context masqué tiroir ouvert, f p + - vivants
await s.attendre(`${OUVERT}`, 'tiroir rouvert');
await s.attendre(`getComputedStyle(document.querySelector('#context')).opacity === '0'`, '#context masqué');
out.ctxOuvert = await s.ev(`document.body.classList.contains('vf-git-ouvert')`);
const k = () => s.ev(`VibeFlow.state.t.k`), panneau = () => s.ev(`document.body.classList.contains('no-panel')`);
const p0 = await panneau(); await s.ev(`document.querySelector('#vf-git-tiroir .vf-git-titre-t').focus()`); await touche('p'); out.p = [p0, await panneau()];
const k0 = await k(); await touche('='); const k1 = await k(); await touche('-'); const k2 = await k(); await touche('f'); await s.ev(`new Promise((r) => setTimeout(r, 700))`); const k3 = await k();
out.zoom = { plus: k1 > k0, moins: k2 < k1, fit: k3 !== k2 };
await fermer();
await s.attendre(`getComputedStyle(document.querySelector('#context')).opacity === '1'`, '#context rendu');
out.ctxFerme = await s.ev(`!document.body.classList.contains('vf-git-ouvert')`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/d3a.js"; } > "$AUX/d3a-complet.js"
  R3="$(cdp "$AUX/d3a-complet.js" "$BASE")"
  assert_eq "D3.1 — touche g ouvre puis ferme" "$(jq_ "$R3" '[j.g1, j.g2].join("|")' 2>/dev/null)" "true|false"
  assert_eq "D3.1 — g ignorée dans INPUT, TEXTAREA, contenteditable (la lettre est tapée)" "$(jq_ "$R3" '[j.champ_input, j.champ_textarea, j.champ_edit].map((c) => c.ouvert + ":" + c.valeur.includes("g")).join("|")' 2>/dev/null)" "false:true|false:true|false:true"
  assert_eq "D3.1 — g ignorée avec Ctrl, Alt, Meta et palette ouverte" "$(jq_ "$R3" '[...j.modif, j.palette].join("|")' 2>/dev/null)" "false|false|false|false"
  assert_eq "D3.7 — animation d'entrée présente (témoin) ; aucune sous prefers-reduced-motion: reduce" "$(jq_ "$R3" '[j.anim > 0, j.animReduit].join("|")' 2>/dev/null)" "true|0"
  assert_eq "D3.2 — ouvrir porte le focus sur le titre du tiroir" "$(jq_ "$R3" '[j.sel0, j.ouverture.ouvert, j.ouverture.titre].join("|")' 2>/dev/null)" "true|true|true"
  assert_eq "D3.2 — Échap (focus dans le tiroir) : fermé, focus rendu à la seconde ligne, sélection et vue inchangées" "$(jq_ "$R3" '[j.echapTiroir.ouvert, j.echapTiroir.focus, j.echapTiroir.selection, j.echapTiroir.vue].join("|")' 2>/dev/null)" "false|vf-git-ligne|true|root"
  assert_eq "D3.2 — Échap (focus sur la seconde ligne) : fermé, sélection inchangée" "$(jq_ "$R3" '[j.echapLigne.ouvert, j.echapLigne.selection].join("|")' 2>/dev/null)" "false|true"
  assert_eq "D3.2 — tiroir fermé, Échap sur la seconde ligne : le viewer garde son comportement (sélection levée)" "$(jq_ "$R3" '[j.echapFerme.ouvert, j.echapFerme.selection].join("|")' 2>/dev/null)" "false|false"
  assert_eq "D3.2 — palette ouverte au-dessus du tiroir : Échap ferme la palette, le tiroir reste" "$(jq_ "$R3" '[j.palette1.palette, j.palette1.ouvert, j.palette2.palette, j.palette2.ouvert].join("|")' 2>/dev/null)" "true|true|false|true"
  assert_eq "D3.3 — body.vf-git-ouvert, #context transparent puis rendu à la fermeture" "$(jq_ "$R3" '[j.ctxOuvert, j.ctxFerme].join("|")' 2>/dev/null)" "true|true"
  assert_eq "D3.3 — p, +, -, f marchent tiroir ouvert (panneau basculé, zoom + puis -, ajustement)" "$(jq_ "$R3" '[j.p[0] !== j.p[1], j.zoom.plus, j.zoom.moins, j.zoom.fit].join("|")' 2>/dev/null)" "true|true|true|true"
  assert_eq "D3.x — aucune erreur de page (clavier)" "$(jq_ "$R3" 'j.errs.length' 2>/dev/null)" "0"

  cat > "$AUX/d3b.js" <<'JS'
const [base, mode] = ARGS;
const out = {}, rect = (sel) => `(() => { const e = document.querySelector('${sel}'); if (!e) return null; const r = e.getBoundingClientRect(); return { left: r.left, right: r.right, top: r.top, bottom: r.bottom, width: r.width, height: r.height }; })()`;
if (mode === 'bureau') {
  for (const w of [1000, 1440]) {
    await fenetre(w, 800); await s.naviguer(base + '/'); await pret();
    await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
    await s.ev(`if (document.body.classList.contains('no-panel')) document.querySelector('#btn-panel').click(); document.querySelector('#vf-git-ligne').click()`);
    await s.attendre(`${OUVERT} && !document.body.classList.contains('no-panel')`, 'tiroir et panneau ouverts');
    out[w] = await s.stable(`({ tiroir: ${rect('#vf-git-tiroir')}, panel: ${rect('#panel')} })`, 'mesure ' + w);
  }
} else {
  for (const w of [375, 700, 768]) {
    await fenetre(w, 800); await s.naviguer(base + '/'); await pret();
    const visible = await s.ev(`(() => { const e = document.querySelector('#vf-git-ouvreur'); return !!e && getComputedStyle(e).display !== 'none' && e.getBoundingClientRect().width > 0; })()`);
    if (visible) await s.ev(`document.querySelector('#vf-git-ouvreur').click()`);
    else {
      await s.attendre(`!!document.querySelector('#vf-plus') && getComputedStyle(document.querySelector('#vf-plus')).display !== 'none'`, 'bouton ⋯');
      await s.ev(`document.querySelector('#vf-plus').click()`);
      await s.attendre(`!![...document.querySelectorAll('#vf-plus-menu [role="menuitem"]')].find((e) => e.textContent.trim() === 'Historique Git')`, 'entrée du menu');
      await s.ev(`[...document.querySelectorAll('#vf-plus-menu [role="menuitem"]')].find((e) => e.textContent.trim() === 'Historique Git').click()`);
    }
    await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-tiroir li[role=option]').length === 40`, 'tiroir ouvert');
    await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-sec-t, #vf-git-tiroir .vf-git-merg-b')].forEach((b) => { if (b.getAttribute('aria-expanded') !== 'true') b.click(); })`);
    out[w] = Object.assign({ via: visible ? 'ouvreur' : 'menu' }, await s.stable(`(() => { const T = document.querySelector('#vf-git-tiroir'), vis = (e) => e.getClientRects().length > 0, r = T.getBoundingClientRect();
      const bt = [...T.querySelectorAll('button')].filter(vis).map((b) => Math.round(b.getBoundingClientRect().height)), li = [...T.querySelectorAll('li[role=option]')].map((l) => Math.round(l.getBoundingClientRect().height));
      return { debord: document.documentElement.scrollWidth > innerWidth, ask: getComputedStyle(document.querySelector('#ask')).display, minBouton: Math.min(...bt), minRangee: Math.min(...li), gauche: r.left, droite: innerWidth - r.right, bas: innerHeight - r.bottom, boutons: bt.length }; })()`, 'mesure ' + w));
  }
}
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/d3b.js"; } > "$AUX/d3b-complet.js"
  R3B="$(cdp "$AUX/d3b-complet.js" "$BASE" bureau)"
  assert_eq "D3.5 — 1000 px, panneau de détails ouvert : au moins 280 px de plan entre le tiroir et #panel (mesuré)" "$(jq_ "$R3B" 'j[1000].panel.left - j[1000].tiroir.right >= 280 && j[1000].panel.width > 0' 2>/dev/null)" "true"
  assert_eq "D3.5 — 1440 px : le tiroir garde ses 360 px, bord gauche à 16 px" "$(jq_ "$R3B" '[j[1440].tiroir.width, j[1440].tiroir.left].join("|")' 2>/dev/null)" "360|16"
  R3C="$(cdp "$AUX/d3b-complet.js" "$BASE" mobile)"
  for w in 375 700 768; do
    assert_eq "D3.6 — ${w} px : ouvert par l'ouvreur (menu ⋯ sous 701 px), aucun défilement horizontal, #ask masqué, tiroir à 8 px des bords" "$(jq_ "$R3C" "[j['$w'].via, j['$w'].debord, j['$w'].ask, j['$w'].gauche, j['$w'].droite, j['$w'].bas].join('|')" 2>/dev/null)" "$([ "$w" = 768 ] && echo ouvreur || echo menu)|false|none|8|8|8"
    assert_eq "D3.6 — ${w} px : rangées et boutons (nombre mesuré > 5) d'au moins 44 px de haut" "$(jq_ "$R3C" "[j['$w'].minBouton >= 44, j['$w'].minRangee >= 44, j['$w'].boutons > 5].join('|')" 2>/dev/null)" "true|true|true"
  done
  assert_eq "D3.x — aucune erreur de page (mise en page)" "$(jq_ "$R3C" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
  # D3.1 hors dépôt : aucun ouvreur, g ne crée aucun tiroir
  NOGIT="$WORK/hors-depot"; mk_lab "$NOGIT"; build_serve "$NOGIT"
  cat > "$AUX/d3n.js" <<'JS'
const [base] = ARGS;
await fenetre(1440); await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#proj-name') && !!window.VibeFlow`, 'page prête');
await s.ev(`document.activeElement && document.activeElement.blur()`);
await touche('g');
return await s.ev(`({ tiroir: !!document.querySelector('#vf-git-tiroir'), ligne: !!document.querySelector('#vf-git-ligne'), api: typeof window.VFGitTiroir, corps: document.body.classList.contains('vf-git-ouvert') })`);
JS
  { cat "$AUX/touche.js"; cat "$AUX/d3n.js"; } > "$AUX/d3n-complet.js"
  R3N="$(cdp "$AUX/d3n-complet.js" "http://127.0.0.1:$PORT")"; stop_srv
  assert_eq "D3.1 — lab hors dépôt : ni ouvreur, ni tiroir, ni API, g ne crée rien" "$(jq_ "$R3N" '[j.tiroir, j.ligne, j.api, j.corps].join("|")' 2>/dev/null)" "false|false|undefined|false"
  # D3.4 : coexistence avec le Terminal réel (serveur lancé avec --terminal) : fermé, ouvert, plein, réduit, refermé
  TL="$WORK/lab-term"; mk_lab "$TL"; $GIT -C "$TL" init -q -b main && $GIT -C "$TL" add -A && $GIT -C "$TL" commit -q -m init
  "$NODE" "${TIROIR_SCRIPTS:-$SCRIPTS}/vf-cockpit-build.mjs" "$TL" --quiet > "$WORK/build-term.out" 2>&1 || cat "$WORK/build-term.out"
  OUT_T="$TL/.vibeflow/cockpit"; mkdir -p "$OUT_T/.cache"; rm -f "$OUT_T/.cache/server.json"
  (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" | tr -d '\n' > "$OUT_T/.cache/terminal-amorce")
  ( cd "$TL" && SHELL=/bin/sh VF_COCKPIT_TERM_GRACE_MS=5000 VF_COCKPIT_ENGINE_DIR="$SCRIPTS/../skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="${TIROIR_SCRIPTS:-$SCRIPTS}" exec "$NODE" "$OUT_T/serve.mjs" --no-open --terminal --port "$(libre)" > "$WORK/serve-term.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV=$!
  for _ in $(seq 1 100); do grep -q '"terminal"' "$OUT_T/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  PORT_T="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT_T/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
  cat > "$AUX/d3t.js" <<'JS'
const [base] = ARGS;
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
try { await s.attendre(`!!document.querySelector('.vf-term-pastille') && !document.querySelector('.vf-term-pastille').hidden`, 'pastille Terminal', 15000); } catch (e) { return { sautee: String(e.message) }; }
const out = {};
const mesure = `(() => { const r = (sel) => { const e = document.querySelector(sel); if (!e || e.hidden || !e.getClientRects().length) return null; const b = e.getBoundingClientRect(); return { l: b.left, r: b.right, t: b.top, b: b.bottom }; };
  const g = r('#vf-git-tiroir'), autres = { zoom: r('#zoom'), pastille: r('.vf-term-pastille'), puce: r('.vf-term-puce'), terminal: r('.vf-term-tiroir') };
  const rec = (a, b) => !!a && !!b && a.l < b.r && a.r > b.l && a.t < b.b && a.b > b.t;
  return { recouvre: Object.keys(autres).filter((k) => rec(g, autres[k])), presents: Object.keys(autres).filter((k) => autres[k]), git: !!g, g, autres }; })()`;
const dessus = `(() => { const T = document.querySelector('#vf-git-tiroir'), b = T.getBoundingClientRect(), e = document.elementFromPoint((b.left + b.right) / 2, (b.top + b.bottom) / 2), l = document.querySelector('#vf-git-ligne').getBoundingClientRect(), h = document.elementFromPoint((l.left + l.right) / 2, (l.top + l.bottom) / 2);
  return { git: !!e && T.contains(e), terminal: !!e && !!e.closest('.vf-term-tiroir'), ligne: !!h && (h.id === 'vf-git-ligne' || !!h.closest('#vf-git-ligne')) }; })()`;
await s.ev(`document.querySelector('#vf-git-ligne').click()`); await s.attendre(OUVERT, 'tiroir Git ouvert');
out.ferme = await s.stable(mesure, 'Terminal fermé');
await s.ev(`document.querySelector('.vf-term-pastille').click()`); await s.attendre(`document.body.classList.contains('vf-term-ouvert') && !!document.querySelector('.vf-term-tiroir') && !document.querySelector('.vf-term-tiroir').hidden`, 'Terminal ouvert');
out.ouvert = await s.stable(mesure, 'Terminal ouvert');
await s.ev(`document.querySelector('.vf-term-tiroir button[aria-label^="Agrandir"]').click()`); await s.attendre(`!!document.querySelector('.vf-term-tiroir.vf-term-plein-etat')`, 'Terminal plein');
out.plein = await s.stable(dessus, 'Terminal plein');
await s.ev(`document.querySelector('.vf-term-tiroir button[aria-label^="Réduire"]').click()`); await s.attendre(`!document.querySelector('.vf-term-tiroir.vf-term-plein-etat')`, 'Terminal réduit');
out.reduit = await s.stable(`({ m: ${mesure}, d: ${dessus} })`, 'Terminal réduit');
await s.ev(`document.querySelector('.vf-term-tiroir button[aria-label^="Fermer"]').click()`); await s.attendre(`!document.body.classList.contains('vf-term-ouvert')`, 'Terminal refermé');
out.refermé = await s.stable(mesure, 'Terminal refermé');
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/d3t.js"; } > "$AUX/d3t-complet.js"
  R3T="$(cdp "$AUX/d3t-complet.js" "http://127.0.0.1:$PORT_T")"; stop_srv; [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R3T" > "$TIROIR_TRACE-terminal.json"
  if [ -n "$(jq_ "$R3T" 'j.sautee || ""' 2>/dev/null)" ]; then skip "D3.4 (coexistence avec le Terminal)" "terminal non lancé : $(jq_ "$R3T" 'j.sautee')"; else
    assert_eq "D3.4 — Terminal fermé : le tiroir Git ne recouvre ni le zoom ni la pastille (témoins : les deux sont présents)" "$(jq_ "$R3T" '[j.ferme.recouvre.length, j.ferme.presents.includes("zoom"), j.ferme.presents.includes("pastille")].join("|")' 2>/dev/null)" "0|true|true"
    assert_eq "D3.4 — Terminal ouvert : aucun recouvrement avec le zoom ni avec le tiroir Terminal (témoin : il est présent)" "$(jq_ "$R3T" '[j.ouvert.recouvre.length, j.ouvert.presents.includes("terminal"), j.ouvert.presents.includes("zoom")].join("|")' 2>/dev/null)" "0|true|true"
    assert_eq "D3.4 — Terminal plein : il recouvre le tiroir Git (z-index) mais la seconde ligne reste atteignable" "$(jq_ "$R3T" '[j.plein.terminal, j.plein.git, j.plein.ligne].join("|")' 2>/dev/null)" "true|false|true"
    assert_eq "D3.4 — sortie du plein : le tiroir Git réapparaît au-dessus, sans recouvrement" "$(jq_ "$R3T" '[j.reduit.d.git, j.reduit.m.recouvre.length, j.reduit.m.presents.includes("terminal")].join("|")' 2>/dev/null)" "true|0|true"
    assert_eq "D3.4 — Terminal refermé : la pastille revient, sans recouvrement" "$(jq_ "$R3T" '[j.refermé.recouvre.length, j.refermé.presents.includes("pastille")].join("|")' 2>/dev/null)" "0|true"
    assert_eq "D3.4 — aucune erreur de page (Terminal)" "$(jq_ "$R3T" 'j.errs.length' 2>/dev/null)" "0"
  fi
  stop_srv
  echo "=== D7 à D9 — détail d'un commit, clavier du graphe, état des worktrees, rafraîchissement par le signal (78-10) ==="
  cat > "$AUX/clavier.js" <<'JS'
// aide D7 à D9 : frappes CDP des touches de navigation (Entrée et Espace portent leur texte pour activer un bouton natif) et pause côté Node
const KV = { ArrowDown: [40, 'ArrowDown'], ArrowUp: [38, 'ArrowUp'], Home: [36, 'Home'], End: [35, 'End'], Enter: [13, 'Enter', '\r'], ' ': [32, 'Space', ' '], Escape: [27, 'Escape'] };
const clavier = async (key) => { const [vk, code, text] = KV[key]; for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, ...(type === 'keyDown' && text ? { text } : {}) }); };
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const LIGNES = `[...document.querySelectorAll('#vf-git-tiroir li[role=option]')]`;
const ouvrirTiroir = async (base, avecEtats) => {
  await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
  await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
  await s.ev(`document.querySelector('#vf-git-ligne').click()`);
  await s.attendre(`${OUVERT} && ${LIGNES}.length >= 40`, 'tiroir ouvert et rangées');
  if (avecEtats) await s.attendre(`!!document.querySelector('#vf-git-s-wt .vf-git-wt-l .vf-git-etat-wt')`, 'états des worktrees');
};
JS
  cat > "$AUX/d7.js" <<'JS'
const [base] = ARGS; const out = {};
await ouvrirTiroir(base);
out.sha = await s.ev(`${LIGNES}[2].dataset.h`);
out.avant = await s.ev(`document.querySelectorAll('.vf-git-detail').length`);
await s.ev(`${LIGNES}[2].click()`);
await s.attendre(`!!document.querySelector('.vf-git-detail .vf-git-d-fichiers')`, 'détail ouvert');
out.reqs = await s.ev(`window.__vfDetReqs.filter((r) => r.route === 'commit').map((r) => r.methode + ' ' + r.url)`);
out.jeton = await s.ev(`window.__vfDetReqs.filter((r) => r.route === 'commit').every((r) => r.headers['x-vf-cockpit-token'] === window.VF_COCKPIT_SERVER.token && !!window.VF_COCKPIT_SERVER.token)`);
out.ouvert = await s.ev(`(() => { const d = document.querySelector('.vf-git-detail'), L = ${LIGNES}[2], q = (x) => d.querySelector(x), fl = [...d.querySelectorAll('.vf-git-d-fichiers > li')], reste = fl.filter((l) => l.classList.contains('vf-git-d-reste')), vrais = fl.filter((l) => !l.classList.contains('vf-git-d-reste'));
  const f1 = vrais[1], bin = vrais.find((l) => /binaire/.test(l.textContent)), ren = vrais.find((l) => /ancien-nom/.test(l.textContent));
  return { apresRangee: L.nextElementSibling === d, nb: document.querySelectorAll('.vf-git-detail').length, sujet: q('.vf-git-d-sujet').textContent, msg: q('.vf-git-d-msg').textContent, ws: getComputedStyle(q('.vf-git-d-msg')).whiteSpace, poids: getComputedStyle(q('.vf-git-d-sujet')).fontWeight,
    meta: q('.vf-git-d-meta').textContent, sha: q('.vf-git-d-sha code').textContent, sel: getComputedStyle(q('.vf-git-d-sha code')).userSelect, titre: q('.vf-git-d-fichiers-t').textContent, nVrais: vrais.length, reste: reste.map((l) => l.textContent),
    plus: f1.querySelector('.vf-git-d-plus').textContent, moins: f1.querySelector('.vf-git-d-moins').textContent, cPlus: getComputedStyle(f1.querySelector('.vf-git-d-plus')).color, cMoins: getComputedStyle(f1.querySelector('.vf-git-d-moins')).color, attPlus: window.__couleur('--ok-text'), attMoins: window.__couleur('--err-text'),
    bin: !!bin, ren: ren ? ren.textContent : '', cmds: [...d.querySelectorAll('.vf-git-cmd code')].map((c) => c.textContent), region: q('[role=region]').getAttribute('aria-label'), diff: /^@@|^diff --git/m.test(d.textContent) }; })()`);
out.hostile = await s.ev(`(() => { const d = document.querySelector('.vf-git-detail'); return { balises: d.querySelectorAll('b, img, script, iframe, [onerror], [onload]').length, svgFichiers: d.querySelectorAll('.vf-git-d-fichiers svg').length, alertes: window.__alerte, auteur: d.textContent.includes('<img src=x onerror=alert(3)>'), chemin: d.textContent.includes('a/<svg onload=1>.txt'), msgLit: d.textContent.includes('<b>gras</b>') && d.textContent.includes('<script>alert(4)</script>') }; })()`);
await s.ev(`${LIGNES}[2].click()`);
await s.attendre(`document.querySelectorAll('.vf-git-detail').length === 0`, 'détail replié au second clic');
out.replie = await s.ev(`document.querySelectorAll('.vf-git-detail').length`);
// D7.3 : 404 -> « Indisponible » local, le reste du tiroir intact ; Réessayer relit
const sha4 = await s.ev(`${LIGNES}[4].dataset.h`);
await s.ev(`window.__vfDet.erreurs['${sha4}'] = 404; ${LIGNES}[4].click()`);
await s.attendre(`!!document.querySelector('.vf-git-detail') && /Indisponible/.test(document.querySelector('.vf-git-detail').textContent)`, 'détail indisponible');
out.indispo = await s.ev(`({ reessayer: [...document.querySelectorAll('.vf-git-detail button')].some((b) => b.textContent.trim() === 'Réessayer'), rangees: ${LIGNES}.length, sections: document.querySelectorAll('#vf-git-tiroir .vf-git-sec').length, carteGlobale: /Git est indisponible/.test(document.querySelector('#vf-git-tiroir').textContent) })`);
await s.ev(`delete window.__vfDet.erreurs['${sha4}']; [...document.querySelectorAll('.vf-git-detail button')].find((b) => b.textContent.trim() === 'Réessayer').click()`);
await s.attendre(`!!document.querySelector('.vf-git-detail .vf-git-d-fichiers')`, 'Réessayer relit');
out.retry = await s.ev(`document.querySelectorAll('.vf-git-detail').length`);
// sha refusé par la page avant toute requête
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); window.__vfGit.reponse.rangees[1].h = '../etc/passwd'; window.__vfDetReqs.length = 0; window.VFGitTiroir.recharger()`);
await s.attendre(`${LIGNES}.length === 40 && ${LIGNES}[1].dataset.h === '../etc/passwd'`, 'réponse à sha invalide rendue');
await s.ev(`${LIGNES}[1].click()`);
await s.attendre(`!!document.querySelector('.vf-git-detail') && /Indisponible/.test(document.querySelector('.vf-git-detail').textContent)`, 'sha refusé : indisponible local');
out.shaRefuse = await s.ev(`({ reqs: window.__vfDetReqs.filter((r) => r.route === 'commit').length })`);
out.csp = s.violations.length;
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d7.js"; } > "$AUX/d7-complet.js"
  cat > "$AUX/d8.js" <<'JS'
const [base] = ARGS; const out = {};
await ouvrirTiroir(base, true);
out.tabulables = await s.ev(`${LIGNES}.filter((l) => l.getAttribute('tabindex') === '0').length`);
await s.ev(`${LIGNES}[0].focus()`);
const etat = `({ i: ${LIGNES}.findIndex((l) => l === document.activeElement), sel: ${LIGNES}.map((l, i) => l.getAttribute('aria-selected') === 'true' ? i : -1).filter((i) => i >= 0), tab: ${LIGNES}.map((l, i) => l.getAttribute('tabindex') === '0' ? i : -1).filter((i) => i >= 0), details: document.querySelectorAll('.vf-git-detail').length })`;
await clavier('ArrowDown'); await clavier('ArrowDown'); await clavier('ArrowUp'); out.bas2haut1 = await s.ev(etat);
await clavier('End'); out.fin = await s.ev(etat);
await clavier('Home'); out.debut = await s.ev(etat);
await clavier('ArrowDown'); await clavier('Enter');
await s.attendre(`document.querySelectorAll('.vf-git-detail').length === 1`, 'Entrée ouvre le détail');
out.entree = await s.ev(etat);
await clavier('Escape'); out.echap = await s.ev(`Object.assign(${etat}, { tiroir: ${OUVERT}, focusLigne: !!document.activeElement && document.activeElement.getAttribute('role') === 'option' })`);
await clavier(' ');
await s.attendre(`document.querySelectorAll('.vf-git-detail').length === 1`, 'Espace ouvre le détail');
out.espace = await s.ev(etat);
// un seul détail à la fois : un clic sur une autre rangée déplace le détail
await s.ev(`${LIGNES}[3].click()`);
await s.attendre(`document.querySelectorAll('.vf-git-detail').length >= 1 && ${LIGNES}[3].nextElementSibling.classList.contains('vf-git-detail')`, 'détail sous la rangée 3');
await pause(150);
out.unSeul = await s.ev(`({ details: document.querySelectorAll('.vf-git-detail').length, sous3: ${LIGNES}[3].nextElementSibling.classList.contains('vf-git-detail') })`);
await s.ev(`${LIGNES}[3].click()`); await s.attendre(`document.querySelectorAll('.vf-git-detail').length === 0`, 'tout replié');
out.libelle = await s.ev(`(() => { const r = window.VFGitTiroir.donnees().rangees[0], L = ${LIGNES}[0]; return { label: L.getAttribute('aria-label'), h7: r.h7, s: r.s }; })()`);
// D8.2 : états des worktrees
out.wtReqs = await s.ev(`window.__vfDetReqs.filter((r) => r.route === 'worktrees').length`);
out.wt = await s.ev(`[...document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l')].map((w) => ({ txt: [...w.querySelectorAll('.vf-git-etat-wt .vf-git-pastille')].map((p) => p.textContent), vide: [...w.querySelectorAll('.vf-git-pastille')].some((p) => !p.textContent.trim()), mono: [...w.querySelectorAll('.vf-git-pastille')].filter((p) => /↑/.test(p.textContent)).map((p) => getComputedStyle(p).fontFamily.includes('mono') || /mono|Mono|Menlo|monospace/i.test(getComputedStyle(p).fontFamily)) }))`);
out.mention = await s.ev(`document.querySelector('#vf-git-s-wt').textContent.includes('approximatif : filtres du dépôt non exécutés')`);
out.couleurs = await s.ev(`(() => { const P = [...document.querySelectorAll('#vf-git-s-wt .vf-git-pastille')], mod = P.find((p) => /modifiés/.test(p.textContent)), pro = P.find((p) => p.textContent === 'propre'); const N = window.__couleur('--text-2'), ok = (p) => { const c = getComputedStyle(p); return c.color === N && (c.backgroundColor === 'rgba(0, 0, 0, 0)' || c.backgroundColor === 'transparent') && c.backgroundImage === 'none'; }; const g = (p) => getComputedStyle(p, '::before').content; return { mod: ok(mod), pro: ok(pro), tous: P.every(ok), gl: g(mod).includes('◐') && g(pro).includes('✓') }; })()`);
// D8.3 : sections au clavier
await s.ev(`document.querySelector('#vf-git-s-tags') || 0; document.querySelectorAll('#vf-git-tiroir .vf-git-sec-t')[2].focus()`);
const sec = `(() => { const b = document.activeElement; return { exp: b.getAttribute('aria-expanded'), nom: document.getElementById(b.getAttribute('aria-controls')).getAttribute('aria-label'), role: document.getElementById(b.getAttribute('aria-controls')).getAttribute('role') }; })()`;
out.secAvant = await s.ev(sec);
await clavier('Enter'); out.secEntree = await s.ev(sec);
await clavier(' '); out.secEspace = await s.ev(sec);
out.csp = s.violations.length;
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d8.js"; } > "$AUX/d8-complet.js"
  cat > "$AUX/d9.js" <<'JS'
const [base] = ARGS; const out = {};
await ouvrirTiroir(base);
const sha = await s.ev(`${LIGNES}[2].dataset.h`);
await s.ev(`${LIGNES}[2].click()`);
await s.attendre(`!!document.querySelector('.vf-git-detail .vf-git-d-fichiers')`, 'détail ouvert avant la rafale');
await s.ev(`document.querySelector('#vf-git-tiroir .vf-git-corps').scrollTop = 200`); await pause(100);
const pos = `(() => { const c = document.querySelector('#vf-git-tiroir .vf-git-corps'), l = ${LIGNES}.find((x) => x.dataset.h === '${sha}'); return l ? Math.round(l.getBoundingClientRect().top - c.getBoundingClientRect().top) : null; })()`;
const cpt = `({ git: window.__vfReqs.length, wt: window.__vfDetReqs.filter((r) => r.route === 'worktrees').length, commit: window.__vfDetReqs.filter((r) => r.route === 'commit').length })`;
const c0 = await s.ev(cpt); const p0 = await s.ev(pos);
await s.ev(`window.__vfGit.reponse = window.__vfDet.apres; document.querySelector('#vf-git-tiroir .vf-git-live') && 0`);
for (let i = 0; i < 3; i++) { await s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'sig${i}' } }))`); await pause(35); }
await s.attendre(`${LIGNES}.length === 41`, 'rafraîchi : une rangée de plus');
await pause(700);
const c1 = await s.ev(cpt);
out.deltas = { git: c1.git - c0.git, wt: c1.wt - c0.wt, commit: c1.commit - c0.commit };
out.selection = await s.ev(`({ sel: ${LIGNES}.filter((l) => l.getAttribute('aria-selected') === 'true').map((l) => l.dataset.h), attendu: '${sha}', detailSous: !!document.querySelector('.vf-git-detail') && document.querySelector('.vf-git-detail').previousElementSibling.dataset.h === '${sha}', premiere: ${LIGNES}[0].dataset.h, live: [...document.querySelectorAll('#vf-git-tiroir [aria-live]')].map((e) => e.textContent).join('|') })`);
out.ecartPos = Math.abs((await s.ev(pos)) - p0);
// D9.2 : la sha sélectionnée disparaît
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__vfDet.apres)); window.__vfGit.reponse.rangees = window.__vfGit.reponse.rangees.filter((r) => r.h !== '${sha}'); document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'x' } }))`);
await s.attendre(`${LIGNES}.length === 40 && !${LIGNES}.some((l) => l.dataset.h === '${sha}')`, 'sha disparue');
await pause(200);
out.disparue = await s.ev(`({ details: document.querySelectorAll('.vf-git-detail').length, sel: ${LIGNES}.filter((l) => l.getAttribute('aria-selected') === 'true').length, tab: ${LIGNES}.filter((l) => l.getAttribute('tabindex') === '0').length, carte: /Git est indisponible/.test(document.querySelector('#vf-git-tiroir').textContent) })`);
// D9.3 : tiroir fermé, aucune requête
await s.ev(`window.VFGitTiroir.fermer()`); await pause(100);
const f0 = await s.ev(cpt);
await s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'ferme' } }))`); await pause(700);
const f1 = await s.ev(cpt);
out.ferme = { git: f1.git - f0.git, wt: f1.wt - f0.wt, commit: f1.commit - f0.commit };
// à la réouverture, le signal manqué est rattrapé
await s.ev(`window.VFGitTiroir.ouvrir()`); await pause(700);
const f2 = await s.ev(cpt);
out.reouverture = { git: f2.git - f1.git, wt: f2.wt - f1.wt };
// D9.4 : 375 px
await fenetre(375, 800); await s.naviguer(base + '/'); await pret();
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); window.VFGitTiroir.ouvrir()`);
await s.attendre(`${LIGNES}.length === 40`, 'mobile : rangées');
await s.ev(`${LIGNES}[2].click()`);
await s.attendre(`!!document.querySelector('.vf-git-detail .vf-git-d-fichiers')`, 'mobile : détail');
out.mobile = await s.stable(`(() => { const T = document.querySelector('#vf-git-tiroir'), c = T.querySelector('.vf-git-corps'), d = document.querySelector('.vf-git-detail'); d.scrollIntoView({ block: 'nearest' }); const t = T.getBoundingClientRect(), r = d.getBoundingClientRect();
  return { debord: document.documentElement.scrollWidth > innerWidth, corpsDebord: c.scrollWidth > c.clientWidth + 1, defile: c.scrollHeight > c.clientHeight, dansTiroir: r.left >= t.left - 1 && r.right <= t.right + 1, pageDefile: document.documentElement.scrollHeight > innerHeight + 1 }; })()`, 'mesure mobile');
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d9.js"; } > "$AUX/d9-complet.js"
  build_serve "$DEPOT"; BASE="http://127.0.0.1:$PORT"
  R7="$(cdp "$AUX/d7-complet.js" "$BASE")"
  assert_eq "D7.0 — témoin : aucun détail avant le clic" "$(jq_ "$R7" 'j.avant' 2>/dev/null)" "0"
  assert_eq "D7.1 — clic sur la 3e rangée : un GET /api/vf/git/commit?sha=<sha complet de la rangée>, avec le jeton de la page" "$(jq_ "$R7" 'j.reqs.join(",") === "GET /api/vf/git/commit?sha=" + j.sha && /^[0-9a-f]{40}$/.test(j.sha) && j.jeton' 2>/dev/null)" "true"
  assert_eq "D7.1 — détail déplié juste sous la rangée, un seul" "$(jq_ "$R7" '[j.ouvert.apresRangee, j.ouvert.nb].join("|")' 2>/dev/null)" "true|1"
  assert_eq "D7.1 — message entier (3 paragraphes), pre-wrap, sujet en 600" "$(jq_ "$R7" '[j.ouvert.sujet, j.ouvert.msg.includes("Second paragraphe."), j.ouvert.msg.includes("Premier paragraphe du corps"), j.ouvert.ws, j.ouvert.poids].join("|")' 2>/dev/null)" "Sujet du commit <b>gras</b>|true|true|pre-wrap|600"
  assert_eq "D7.1 — auteur et date longue « 5 nov. 2026, 14 h 32 », sha complet sélectionnable" "$(jq_ "$R7" '[/\d{1,2} \S+ 2026, \d{1,2} h \d{2}/.test(j.ouvert.meta), j.ouvert.meta.includes("<img src=x"), j.ouvert.sha === j.sha, j.ouvert.sel].join("|")' 2>/dev/null)" "true|true|true|text"
  assert_eq "D7.1 — « Fichiers (45) », 30 lignes puis « et 15 autres »" "$(jq_ "$R7" '[j.ouvert.titre, j.ouvert.nVrais, j.ouvert.reste.join("/")].join("|")' 2>/dev/null)" "Fichiers (45)|30|et 15 autres"
  assert_eq "D7.1 — « +n » en --ok-text et « −n » en --err-text, signe dans le texte" "$(jq_ "$R7" '[j.ouvert.plus, j.ouvert.moins, j.ouvert.cPlus === j.ouvert.attPlus, j.ouvert.cMoins === j.ouvert.attMoins, j.ouvert.cPlus !== j.ouvert.cMoins].join("|")' 2>/dev/null)" "+2|−1|true|true|true"
  assert_eq "D7.1 — binaire dit « binaire », renommage dit l'ancien et le nouveau chemin, deux commandes à copier, région nommée, aucun diff" "$(jq_ "$R7" '[j.ouvert.bin, /ancien-nom.*nouveau-nom|nouveau-nom.*ancien-nom/.test(j.ouvert.ren), j.ouvert.cmds.join(" ; "), /Détail du commit/.test(j.ouvert.region), j.ouvert.diff].join("|")' 2>/dev/null)" "true|true|git show --stat --end-of-options 2626262 ; git switch --detach --end-of-options 2626262|true|false"
  assert_eq "D7.1 — second clic : détail replié" "$(jq_ "$R7" 'j.replie' 2>/dev/null)" "0"
  assert_eq "D7.2 — chaînes hostiles lues telles quelles : 0 b/img/script/svg injecté dans le détail, auteur, chemin et message littéraux, 0 alert" "$(jq_ "$R7" '[j.hostile.balises, j.hostile.svgFichiers, j.hostile.alertes, j.hostile.auteur, j.hostile.chemin, j.hostile.msgLit].join("|")' 2>/dev/null)" "0|0|0|true|true|true"
  assert_eq "D7.3 — réponse 404 : « Indisponible » et « Réessayer » dans le détail seul, 40 rangées et sections intactes, pas de carte globale" "$(jq_ "$R7" '[j.indispo.reessayer, j.indispo.rangees, j.indispo.sections > 0, j.indispo.carteGlobale].join("|")' 2>/dev/null)" "true|40|true|false"
  assert_eq "D7.3 — Réessayer relit et affiche le détail" "$(jq_ "$R7" 'j.retry' 2>/dev/null)" "1"
  assert_eq "D7.3 — sha hors motif : refusé par la page avant toute requête, « Indisponible » local" "$(jq_ "$R7" 'j.shaRefuse.reqs' 2>/dev/null)" "0"
  assert_eq "D7.x — 0 violation CSP, 0 erreur de page" "$(jq_ "$R7" '[j.csp, j.errs.length].join("|")' 2>/dev/null)" "0|0"
  R8="$(cdp "$AUX/d8-complet.js" "$BASE")"
  assert_eq "D8.1 — une seule rangée tabulable (tabindex 0)" "$(jq_ "$R8" 'j.tabulables' 2>/dev/null)" "1"
  assert_eq "D8.1 — ↓ ↓ ↑ : 2e rangée focalisée, sélectionnée et seule tabulable" "$(jq_ "$R8" '[j.bas2haut1.i, j.bas2haut1.sel.join(), j.bas2haut1.tab.join(), j.bas2haut1.details].join("|")' 2>/dev/null)" "1|1|1|0"
  assert_eq "D8.1 — Fin : dernière rangée ; Début : première" "$(jq_ "$R8" '[j.fin.i, j.fin.sel.join(), j.debut.i, j.debut.sel.join()].join("|")' 2>/dev/null)" "39|39|0|0"
  assert_eq "D8.1 — Entrée ouvre le détail de la rangée sélectionnée ; Échap le replie, le tiroir reste ouvert, le focus reste sur la rangée" "$(jq_ "$R8" '[j.entree.i, j.entree.details, j.echap.details, j.echap.tiroir, j.echap.focusLigne, j.echap.i].join("|")' 2>/dev/null)" "1|1|0|true|true|1"
  assert_eq "D8.1 — Espace ouvre aussi le détail" "$(jq_ "$R8" 'j.espace.details' 2>/dev/null)" "1"
  assert_eq "D8.1 — un seul détail ouvert : le clic sur une autre rangée déplace le détail" "$(jq_ "$R8" '[j.unSeul.details, j.unSeul.sous3].join("|")' 2>/dev/null)" "1|true"
  assert_eq "D8.1 — aria-label « <sha7>, <message>, branche <b>, il y a <t> »" "$(jq_ "$R8" '(new RegExp("^" + j.libelle.h7 + ", " + j.libelle.s + ", branche main, (il y a .+|à l.instant)$")).test(j.libelle.label)' 2>/dev/null)" "true"
  assert_eq "D8.2 — ouverture du tiroir : une seule requête /api/vf/git/worktrees" "$(jq_ "$R8" 'j.wtReqs' 2>/dev/null)" "1"
  assert_eq "D8.2 — pastilles : « 3 modifiés », « 2 non suivis », « ↑2 ↓1 » ; « propre » ; « 1 modifié »" "$(jq_ "$R8" 'j.wt.map((w) => w.txt.join("/")).join(" | ")' 2>/dev/null)" "3 modifiés/2 non suivis/↑2 ↓1 | propre | 1 modifié"
  assert_eq "D8.2 — aucune pastille vide, « ↑a ↓r » en police mono" "$(jq_ "$R8" '[j.wt.some((w) => w.vide), j.wt[0].mono.join()].join("|")' 2>/dev/null)" "false|true"
  assert_eq "D8.2 — « approximatif : filtres du dépôt non exécutés » ; P78-D-33 : toute pastille en texte neutre (--text-2) sur fond transparent, état porté par un glyphe (jamais --warn-text/--ok-text ni fond teinté)" "$(jq_ "$R8" '[j.mention, j.couleurs.mod, j.couleurs.pro, j.couleurs.tous, j.couleurs.gl].join("|")' 2>/dev/null)" "true|true|true|true|true"
  assert_eq "D8.3 — section au clavier : Entrée la déplie, Espace la replie, la région porte un nom et un rôle" "$(jq_ "$R8" '[j.secAvant.exp, j.secEntree.exp, j.secEspace.exp, j.secAvant.role, j.secAvant.nom.length > 0].join("|")' 2>/dev/null)" "false|true|false|region|true"
  assert_eq "D8.x — 0 violation CSP, 0 erreur de page" "$(jq_ "$R8" '[j.csp, j.errs.length].join("|")' 2>/dev/null)" "0|0"
  R9="$(cdp "$AUX/d9-complet.js" "$BASE")"
  assert_eq "D9.1 — trois signaux en ~100 ms : une relecture de /api/vf/git, une de worktrees, aucune requête de détail (cache par sha)" "$(jq_ "$R9" '[j.deltas.git, j.deltas.wt, j.deltas.commit].join("|")' 2>/dev/null)" "1|1|0"
  assert_eq "D9.1 — la même sha reste sélectionnée, son détail dessous, la nouvelle rangée est en tête" "$(jq_ "$R9" '[j.selection.sel.join() === j.selection.attendu, j.selection.detailSous, j.selection.premiere].join("|")' 2>/dev/null)" "true|true|2929292929292929292929292929292929292929"
  assert_eq "D9.1 — position à l'écran inchangée à ± 2 px, annonce « Historique mis à jour »" "$(jq_ "$R9" '[j.ecartPos <= 2, j.selection.live.includes("Historique mis à jour")].join("|")' 2>/dev/null)" "true|true"
  assert_eq "D9.2 — sha sélectionnée disparue : détail replié, aucune sélection, une rangée tabulable, aucune carte d'erreur" "$(jq_ "$R9" '[j.disparue.details, j.disparue.sel, j.disparue.tab, j.disparue.carte].join("|")' 2>/dev/null)" "0|0|1|false"
  assert_eq "D9.3 — tiroir fermé : un signal ne déclenche aucune requête" "$(jq_ "$R9" '[j.ferme.git, j.ferme.wt, j.ferme.commit].join("|")' 2>/dev/null)" "0|0|0"
  assert_eq "D9.3 — à la réouverture, le signal manqué est rattrapé (une relecture de chaque)" "$(jq_ "$R9" '[j.reouverture.git, j.reouverture.wt].join("|")' 2>/dev/null)" "1|1"
  assert_eq "D9.4 — 375 px : le détail se déplie dans le tiroir, la page ne défile pas horizontalement, le tiroir défile seul" "$(jq_ "$R9" '[j.mobile.debord, j.mobile.corpsDebord, j.mobile.defile, j.mobile.dansTiroir, j.mobile.pageDefile].join("|")' 2>/dev/null)" "false|false|true|true|false"
  assert_eq "D9.x — aucune erreur de page" "$(jq_ "$R9" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
  # --- copies privées du module pour les mutants (build lit assets/ui/*.js) : chaque mutant a son propre lab et son propre serveur ---
  mkmod() { local d="$WORK/mod-$1"; mkdir -p "$d/scripts" "$d/skills"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/scripts/"; cp -R "$SCRIPTS/../skills/cockpit-moteur" "$d/skills/cockpit-moteur"; echo "$d/scripts"; }
  mutlab() { local L="$WORK/lab-$1"; mk_lab "$L"; [ "${2:-}" = nogit ] || { $GIT -C "$L" init -q -b main && $GIT -C "$L" add -A && $GIT -C "$L" commit -q -m init; }; echo "$L"; }
  mutant() { # mutant <nom> <fichier ui> <ancien> <nouveau> <scénario> [nogit] -> RM (une ligne JSON) ; une mutation impossible compte comme un échec
    local M L; M="$(mkmod "$1")"; L="$(mutlab "$1" "${6:-}")"
    if ! mutate "$M/../skills/cockpit-moteur/assets/ui/$2" "$3" "$4"; then echo "  ❌ FAIL — $1 : mutation impossible"; FAIL=$((FAIL+1)); RM="{}"; return; fi
    build_serve "$L" "$M"; RM="$(cdp "$AUX/$5" "http://127.0.0.1:$PORT")"; stop_srv
    [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$RM" > "$TIROIR_TRACE-$1.json"
  }
  mutant M-HTML 77-vf-git-rendu.js "l1.appendChild(el('span', 'vf-git-msg', r.s));" "{ const m = el('span', 'vf-git-msg'); m.innerHTML = r.s; l1.appendChild(m); }" d2.js
  assert_eq "M-HTML — rougit D2.5 (un message rendu en HTML fait naître un <img>) alors que les 40 rangées sont là (pas une panne d'un autre ordre)" "$(jq_ "$RM" '[j.xss.img > 0, j.xss.lit.includes("false"), j.ouvert.rangees].join("|")' 2>/dev/null)" "true|true|40"
  mutant M-COPIE 77-vf-git-rendu.js "writeText(code.textContent)" "writeText(code.textContent.slice(0, -1))" d2.js
  assert_eq "M-COPIE — rougit D2.4 (le texte reçu par l'API n'est plus celui du <code>) alors que la copie a bien eu lieu" "$(jq_ "$RM" '[j.copie.spy === j.copie.affiche, typeof j.copie.spy, j.copie.retour].join("|")' 2>/dev/null)" "false|string|Copiée"
  mutant M-GLOBAL-G 77-vf-git-tiroir.js "if (t && (t.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].indexOf(t.tagName) >= 0)) return;" "if (false) return;" d3a-complet.js
  assert_eq "M-GLOBAL-G — rougit D3.1 (g ouvre le tiroir depuis un champ de saisie) alors que g hors champ marche toujours" "$(jq_ "$RM" '[j.champ_input.ouvert, j.g1, j.g2].join("|")' 2>/dev/null)" "true|true|false"
  mutant M-HORS-DEPOT 77-vf-git-tiroir.js "if (!V || V.etat === 'absent' || !V.depot) return; // sans dépôt" "if (false) return; // sans dépôt" d3n-complet.js nogit
  assert_eq "M-HORS-DEPOT — rougit D3.1 hors dépôt (le tiroir existe alors qu'aucun ouvreur n'existe) alors que la page est rendue" "$(jq_ "$RM" '[j.tiroir, j.ligne].join("|")' 2>/dev/null)" "true|false"
  mutant M-DETAIL-HTML 77-vf-git-vue-detail.js "corpsMsg.textContent = m.length > 1 ? '\n' + m.slice(1).join('\n') : '';" "corpsMsg.innerHTML = m.length > 1 ? '\n' + m.slice(1).join('\n') : '';" d7-complet.js
  assert_eq "M-DETAIL-HTML — rougit D7.2 (un message rendu en HTML fait naître un <script> dans le détail) alors que le détail et ses 30 fichiers sont là" "$(jq_ "$RM" '[j.hostile.balises > 0, j.hostile.msgLit, j.ouvert.nb, j.ouvert.nVrais].join("|")' 2>/dev/null)" "true|false|1|30"
  mutant M-SELECTION 77-vf-git-vue-detail.js "fermerDetail(); // un seul détail à la fois" "/* mutant : le détail précédent reste ouvert */" d8-complet.js
  assert_eq "M-SELECTION — rougit D8.1 (deux détails ouverts) alors que le clavier du graphe marche (↓ ↓ ↑ -> 2e rangée)" "$(jq_ "$RM" '[j.unSeul.details > 1, j.bas2haut1.i, j.entree.details].join("|")' 2>/dev/null)" "true|1|1"
  mutant M-RAFALE 77-vf-git-vue-detail.js "clearTimeout(minuterie); minuterie = setTimeout(rafraichir, RAFALE);" "rafraichir();" d9-complet.js
  assert_eq "M-RAFALE — rougit D9.1 (une relecture par signal : 3 et 3 au lieu de 1 et 1) alors que la sélection est conservée" "$(jq_ "$RM" '[j.deltas.git, j.deltas.wt, j.selection.sel.join() === j.selection.attendu].join("|")' 2>/dev/null)" "3|3|true"
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
