#!/usr/bin/env bash
# test-cockpit-git-tiroir.sh — tiroir Git de la page (78-06 ; GITC-04, 05, 06, 08, 10, 11 ; P78-D-04, 10, 11, 12, 14, 19).
#   D1 ouverture depuis la seconde ligne, graphe servi, schéma vérifié · D2 sections, graphe complet, commandes à copier, états, XSS
#   D3 clavier, focus, coexistence avec le Terminal et le zoom, mobile
#   D7 détail d'un commit sous sa rangée · D8 clavier du graphe, état des worktrees · D9 rafraîchissement par vf-git:signal (78-10)
#   D10 correction design de la critique fraîche (F2 étiquettes, F12 stash, F14 glyphes muets, F15 tailles et graisses)
#   Recette du 2026-11-08 (PU-G-193, 196) : D18.1 à D18.4 et D16.3b — la définition d'un terme Git (HEAD détaché, Worktrees, ↑/↓) se montre aussi au focus clavier, Échap la ferme sans fermer le tiroir ; mutants M-BULLE-ECHAP, M-BULLE-FOCUS.
#   Mutants (D12 : M-SEQ-WT, M-ANNONCE) : M-HTML, M-COPIE, M-GLOBAL-G, M-HORS-DEPOT, M-DETAIL-HTML, M-SELECTION, M-RAFALE, M-NONVERIFIE (D11 : worktree non vérifié, audit A3). La réponse `/api/vf/git` est figée (temoins/git-tiroir.json) et servie par un `fetch` remplacé dans la page.
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
  // VF_MEDIA (posé par TIROIR_MEDIA="nom=valeur,nom=valeur", ex. prefers-color-scheme=light,pointer=none,hover=none) : émule les media features de Chrome headless sous Linux (thème clair, `pointer: none`) sur un poste macOS. Absent : le poste réel.
  if (process.env.VF_MEDIA) await s.send('Emulation.setEmulatedMedia', { features: process.env.VF_MEDIA.split(',').map((x) => { const [name, value] = x.split('='); return { name, value }; }) });
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
export VF_MEDIA="${TIROIR_MEDIA:-}"; export VF_CS="$HERE_T/chrome-session.mjs"; export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-25000}" VF_CDP_TAG=git-tiroir
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
    if (m[1] === 'worktrees') return window.__vfDet.delaiWt ? new Promise((ok) => setTimeout(() => ok(rep(200, window.__vfDet.worktrees)), window.__vfDet.delaiWt)).then((r) => r) : rep(200, window.__vfDet.worktrees);
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
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs) : on mesure une fois posé
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
out.copie.apres = await attendreValeur(() => s.ev(`${cible}.parentNode.querySelector('.vf-git-retour').textContent`), (v) => v === '', { max: 4000 }); // minuterie produit 1600 ms : borne 4 s (≈ 2,5 x) — une régression du minuteur (retour jamais effacé) reste rouge
await s.ev(`window.__refuse = true; ${cible}.parentNode.querySelector('button').click()`);
await s.attendre(`/Copie impossible/.test(${cible}.parentNode.querySelector('.vf-git-retour').textContent)`, 'copie refusée');
out.refus = await s.ev(`({ retour: ${cible}.parentNode.querySelector('.vf-git-retour').textContent, selection: String(window.getSelection()), affiche: ${cible}.textContent })`);
// D2.5 : XSS (tout est déplié)
await s.ev(`new Promise((r) => setTimeout(r, 400))`);
out.xss = await s.ev(`(() => { const T = ${T}, tx = T.textContent;
  return { img: T.querySelectorAll('img, script, b, u, iframe, style').length, svgEtrangers: [...T.querySelectorAll('svg')].filter((s) => !s.classList.contains('vf-git-gcol') && !s.classList.contains('i')).length, surveillants: T.querySelectorAll('[onload], [onerror]').length,
    lit: ['<svg/onload=alert(1)>', '<img src=x onerror=alert(2)>', '<b>x</b>', '<script>alert(3)</script>', '<iframe src=x>', 'WIP <u>essai</u>', '<b>vieille</b>'].map((t) => tx.includes(t)).join(',') }; })()`);
out.aide = await s.ev(`(() => { const b = [...${T}.querySelectorAll('.vf-git-sec-t')].find((x) => /^Worktrees/.test(x.textContent)); return { title: b.getAttribute('title'), desc: b.getAttribute('aria-description'), detache: [...${T}.querySelectorAll('.vf-git-wt-l .vf-git-mono')].filter((m) => m.textContent === 'HEAD détaché').map((m) => m.getAttribute('title')) }; })()`); // PU-G-193 : le terme Git reste, sa définition au survol (title) et au focus (aria-description)
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
  assert_eq "D2.1 — PU-G-193 : « Worktrees » reste, avec sa définition constante au survol (title) et au focus (aria-description), identiques ; chaque « HEAD détaché » porte la sienne" "$(jq_ "$R2" '[/^Worktrees : copies de travail du dépôt/.test(j.aide.title), j.aide.title === j.aide.desc, /[<>]/.test(j.aide.title), j.aide.detache.length > 0 && j.aide.detache.every((t) => /^HEAD détaché : ce dossier/.test(t))].join("|")' 2>/dev/null)" "true|true|false|true"
  assert_eq "D2.1 — section sans donnée masquée (Tags, Stash), Graphe gardée même sans rangée" "$(jq_ "$R2" '[j.sansDonnee.join(","), j.grapheVide].join("|")' 2>/dev/null)" "Worktrees,Graphe,Auteurs et activité|true"
  assert_eq "D2.2 — 6 couloirs au plus (colonne de 96 px, nœud le plus à droite à 88) et « +17 » servi" "$(jq_ "$R2" '[j.graphe.largeurs.join(","), j.graphe.maxCx, j.graphe.plus].join("|")' 2>/dev/null)" "96|88|+17"
  assert_eq "D2.2 — nœud r=4, trait 1,75, quart de cercle de rayon 16 (arc A16 16), colonne aria-hidden" "$(jq_ "$R2" '[j.graphe.r, j.graphe.trait, j.graphe.arcs > 0, j.graphe.ariaHidden].join("|")' 2>/dev/null)" "4|1.75|true|true"
  assert_eq "D2.2 — HEAD : un nœud plein couleur du texte avec son anneau --ring ; fusions : nœuds creux à fond --surface (3)" "$(jq_ "$R2" 'JSON.stringify([j.graphe.tetes, j.graphe.teteFill === j.attendu.text, j.graphe.anneau === j.attendu.ring, j.graphe.creux, j.graphe.creuxFill === j.attendu.surface, j.graphe.normalFill !== j.graphe.creuxFill])' 2>/dev/null)" "[1,true,true,3,true,true]"
  assert_eq "D2.2 — couloirs : --text-3 puis --k-http, --k-call, --k-data, --k-event, --k-queue (couleur calculée des traits)" "$(jq_ "$R2" 'JSON.stringify(j.graphe.couleurs) === JSON.stringify(j.attendu.lanes) && new Set(j.attendu.lanes).size === 6' 2>/dev/null)" "true"
  assert_eq "D2.2 — branche distante seule en tirets, HEAD local en trait plein" "$(jq_ "$R2" 'j.graphe.tirets17 > 0 && j.graphe.tirets0 === 0' 2>/dev/null)" "true"
  assert_eq "D2.2 — rangée de 40 px (colonne 40 px) à 1440, 44 px à 768" "$(jq_ "$R2" '[j.graphe.hLi, j.graphe.hSvg, j.mobile.li, j.mobile.svg].join("|")' 2>/dev/null)" "40|40|44|44"
  assert_eq "D2.3 — étiquettes : 2 pilules puis « +4 » (2 en trop sur la rangée + refsPlus 2 servi), le title liste le reste" "$(jq_ "$R2" '[j.etiq.pilules, j.etiq.plus, /v0\.9/.test(j.etiq.titre) && /feat\/quatre/.test(j.etiq.titre) && /et 2 autres/.test(j.etiq.titre)].join("|")' 2>/dev/null)" "2|+4|true"
  assert_eq "D2.3 — mergées : « 4 branches mergées » repliées puis dépliées (4 noms, 3 commandes, 1 absence dite)" "$(jq_ "$R2" '[j.merg0.texte, j.merg0.ouvert, j.merg0.cache, j.merg1.ouvert, j.merg1.cache, j.merg1.noms.length, j.merg1.codes, j.merg1.sans].join("|")' 2>/dev/null)" "4 branches mergées|false|true|true|false|4|3|1"
  assert_eq "D2.4 — copie : l'API reçoit exactement le texte du <code> affiché (hostile compris), « Copiée », annonce, retour effacé après 1,6 s, nom court du bouton (200 : la commande n'y figure plus)" "$(jq_ "$R2" '[j.copie.spy === j.copie.affiche, j.copie.spy.includes("<b>vieille</b>"), j.copie.retour, j.copie.live, j.copie.apres === "", j.copie.label === "Copier la commande de suppression de la branche <b>vieille</b>"].join("|")' 2>/dev/null)" "true|true|Copiée|Commande copiée|true|true"
  assert_eq "D2.4 — copie refusée : « Copie impossible, commande sélectionnée » et la commande est la sélection" "$(jq_ "$R2" '[j.refus.retour, j.refus.selection === j.refus.affiche].join("|")' 2>/dev/null)" "Copie impossible, commande sélectionnée|true"
  assert_eq "D2.5 — XSS : 0 img, script, b, u, iframe ; aucun svg étranger ; aucun attribut onload ; chaînes hostiles lues telles quelles" "$(jq_ "$R2" '[j.xss.img, j.xss.svgEtrangers, j.xss.surveillants, j.xss.lit].join("|")' 2>/dev/null)" "0|0|0|true,true,true,true,true,true,true"
  assert_eq "D2.5 — aucun alert, 0 violation CSP, 0 erreur de page" "$(jq_ "$R2" '[j.alerte, j.csp, j.errs.length].join("|")' 2>/dev/null)" "0|0|0"
  cat > "$AUX/d2b.js" <<'JS'
const [base] = ARGS;
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs) : on mesure une fois posé
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#vf-git-ligne') && getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne visible');
const out = {}, T = `document.querySelector('#vf-git-tiroir')`, attente = (ms) => s.ev(`new Promise((r) => setTimeout(r, ${ms}))`);
// D2.6 : indisponible, puis « Réessayer » (nouveau GET) avec le témoin rétabli
out.brancheAvant = await s.ev(`document.querySelector('.vf-git-branche').textContent`); // la lecture du chargement a réussi : une branche est connue
await s.ev(`window.__vfGit.reponse = { schema: 'vibeflow/cockpit-git@1', etat: 'indisponible', entete: { etat: 'indisponible', depot: 'depot' }, commandes: { vide: null, diagnostic: 'git status' } }; document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`/Git est indisponible/.test(${T}.textContent)`, 'carte indisponible');
out.indispo = await s.ev(`({ code: [...${T}.querySelectorAll('.vf-git-cmd code')].map((c) => c.textContent), bouton: [...${T}.querySelectorAll('button')].some((b) => b.textContent === 'Réessayer'), ligne: document.querySelector('#vf-git-ligne').textContent, brancheLue: document.querySelector('.vf-git-branche').textContent, etat: document.querySelector('.vf-git-ligne-etat').textContent, reqs: window.__vfReqs.length, note: (() => { const n = ${T}.querySelector('.vf-git-etat .vf-git-note'), r = n.getBoundingClientRect(), t = ${T}.getBoundingClientRect(); return { ws: getComputedStyle(n).whiteSpace, debord: n.scrollWidth > n.clientWidth + 1 || r.right > t.right + 1, lignes: r.height > 1.8 * parseFloat(getComputedStyle(n).fontSize) ? 2 : 1, texte: n.textContent.slice(0, 40), large: Math.round(r.width) }; })() })`);
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); [...${T}.querySelectorAll('button')].find((b) => b.textContent === 'Réessayer').click()`);
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length === 40`, 'rangées après Réessayer');
out.reessai = await s.ev(`({ reqs: window.__vfReqs.length, page: !!document.querySelector('#proj-name') })`);
// vide
await s.ev(`window.__vfGit.reponse = { schema: 'vibeflow/cockpit-git@1', etat: 'vide', entete: { etat: 'ok', depot: 'depot', branche: 'main', detache: false }, commandes: { vide: 'git commit -m "premier commit"', diagnostic: 'git status' } }; window.VFGitTiroir.recharger()`);
await s.attendre(`/Aucun commit pour l.instant/.test(${T}.textContent)`, 'état vide');
out.vide = await s.ev(`({ code: [...${T}.querySelectorAll('.vf-git-cmd code')].map((c) => c.textContent), rangees: ${T}.querySelectorAll('li[role=option]').length })`);
// chargement : rien avant 150 ms, puis aria-busy et trois rangées fantômes
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); window.__vfGit.delai = 4000; void window.VFGitTiroir.recharger(); 0`); // réponse tenue 4 s : la fenêtre « chargement » reste ouverte sous une CI lente (l'attendu ne change pas : fantômes tant que la réponse n'est pas là)
await attente(60);
out.avant150 = await s.ev(`({ busy: ${T}.querySelector('[aria-busy="true"]') !== null || ${T}.querySelector('.vf-git-corps').getAttribute('aria-busy') === 'true', fantomes: ${T}.querySelectorAll('.vf-git-fantome').length })`);
out.pendant = await attendreValeur(() => s.ev(`({ busy: ${T}.querySelector('.vf-git-corps').getAttribute('aria-busy'), fantomes: ${T}.querySelectorAll('.vf-git-fantome').length, texte: /Lecture du dépôt/.test(${T}.textContent), anim: ${T}.querySelector('.vf-git-fantome') ? getComputedStyle(${T}.querySelector('.vf-git-fantome')).animationName : 'none' })`), (v) => v.fantomes > 0 && v.busy === 'true', { pas: 50, max: 1000 }); // squelette posé par la minuterie produit de 150 ms : borne 1 s (≈ 6 x), lecture voulue dans la fenêtre « chargement » (réponse tenue 4 s)
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length === 40`, 'rangées après le délai');
out.apres = await s.ev(`({ busy: ${T}.querySelector('.vf-git-corps').getAttribute('aria-busy'), fantomes: ${T}.querySelectorAll('.vf-git-fantome').length })`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  R2B="$(cdp "$AUX/d2b.js" "$BASE")"
  assert_eq "D2.6 — indisponible : carte « Git est indisponible », « Réessayer », commande git status" "$(jq_ "$R2B" '[j.indispo.code.join(","), j.indispo.bouton].join("|")' 2>/dev/null)" "git status|true"
  assert_eq "D2.6b — PU-G-191 : la note d'indisponibilité se replie en texte normal sur plusieurs lignes dans le tiroir et ne dépasse pas (la classe d'état de l'en-tête ne s'applique plus à rien dans le tiroir ; rouge : white-space pre, une ligne rognée)" "$(jq_ "$R2B" '[j.indispo.note.ws, j.indispo.note.debord, j.indispo.note.lignes >= 2].join("|")' 2>/dev/null)" "normal|false|true"
  assert_eq "D2.6 — l'en-tête, déjà lu une fois, garde la dernière branche (« ○ <branche> », « non confirmée ») et ne dit pas « Branche indisponible » (PU-G-003 ; « Branche indisponible » reste réservé à la première lecture sans valeur connue, H9.1)" "$(jq_ "$R2B" '[j.brancheAvant.length > 0, j.indispo.brancheLue === "○ " + j.brancheAvant, /non confirmée/.test(j.indispo.etat), /non confirmée/.test(j.indispo.ligne), /Branche indisponible/.test(j.indispo.ligne)].join("|")' 2>/dev/null)" "true|true|true|true|false"
  assert_eq "D2.6 — « Réessayer » relance un GET (3 requêtes en tout : la lecture, sa relance automatique unique, puis le clic), la page continue, 40 rangées" "$(jq_ "$R2B" '[j.reessai.reqs, j.reessai.page].join("|")' 2>/dev/null)" "3|true"
  assert_eq "D2.6 — vide : « Aucun commit pour l'instant », commande git commit -m \"premier commit\", aucune rangée" "$(jq_ "$R2B" '[j.vide.code.join(","), j.vide.rangees].join("|")' 2>/dev/null)" 'git commit -m "premier commit"|0'
  assert_eq "D2.6 — chargement : rien à 60 ms ; à 260 ms aria-busy, 3 rangées fantômes, « Lecture du dépôt », sans animation ; réponse reçue : plus rien" "$(jq_ "$R2B" 'JSON.stringify([j.avant150.busy, j.avant150.fantomes, j.pendant.busy, j.pendant.fantomes, j.pendant.texte, j.pendant.anim, j.apres.busy, j.apres.fantomes])' 2>/dev/null)" '[false,0,"true",3,true,"none",null,0]'
  assert_eq "D2.x — aucune erreur de page (états)" "$(jq_ "$R2B" 'j.errs.length' 2>/dev/null)" "0"
  echo "=== D3 — clavier, focus, coexistence, mobile ==="
  cat > "$AUX/touche.js" <<'JS'
const { stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } = await import(process.env.VF_CS); // aides communes (chrome-session.mjs) : on mesure une fois posé
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
await fenetre(1440); await s.naviguer(base + '/#t'); await pret(); // « #t » : un fragment empêche la visite guidée de se lancer seule (40-tour.js:249 rejoue SC.fit(true) à 450 ms : elle faisait varier k et poser `anim` comme un « f », rendant D3.3 non discriminant)
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
await s.ev(`document.activeElement && document.activeElement.blur()`); await touche('Escape'); out.echapCanvas = await s.ev(etat); // focus sur le canvas (body) : le viewer lève la sélection
await s.ev(`VibeFlow.select(window.__id)`); await touche('g'); await touche('/'); await s.attendre(`!!document.activeElement && document.activeElement.id === 'search'`, 'focus dans la palette'); out.palette1 = await s.ev(`({ palette: document.querySelector('#palette').classList.contains('open'), ouvert: ${OUVERT} })`);
await touche('Escape'); out.palette2 = await s.ev(`({ palette: document.querySelector('#palette').classList.contains('open'), ouvert: ${OUVERT} })`);
// D3.3 : #context masqué tiroir ouvert, f p + - vivants
await s.attendre(`${OUVERT}`, 'tiroir rouvert');
await s.attendre(`getComputedStyle(document.querySelector('#context')).opacity === '0'`, '#context masqué');
out.ctxOuvert = await s.ev(`document.body.classList.contains('vf-git-ouvert')`);
const k = () => s.ev(`VibeFlow.state.t.k`), panneau = () => s.ev(`document.body.classList.contains('no-panel')`);
const p0 = await panneau(); await s.ev(`document.querySelector('#vf-git-tiroir .vf-git-titre-t').focus()`); await touche('p'); out.p = [p0, await panneau()];
const k0 = await k(); await touche('='); const k1 = await attendreEtStabiliser(k, (v) => v > k0, { max: 5000 }); await touche('-'); const k2 = await attendreEtStabiliser(k, (v) => v < k1, { max: 5000 }); // « -» ramène le zoom à son point de départ, qui EST déjà l'ajustement (viewer.html fit()) : un « f » lu alors ne changeait rien d'observable. De plus le viewer se REPLACE seul (fit(false) à chaque mise en page du graphe, ~300 ms après un zoom dans cette page) : un état « non ajusté » ne dure donc pas.
// Discriminant : « k change » ne prouve pas que « f » marche si quelque chose d'autre ajuste la vue. C'était le cas : la visite guidée (40-tour.js:249) rejoue SC.fit(true) à 450 ms, ce qui ramenait k à 1,1 et posait `anim` comme un « f » (démontré : avec « f » rendu inopérant, D3.3 restait vert). La page est donc ouverte avec un fragment (#t, qui empêche la visite de se lancer seule) et l'observable propre à « f » est l'ajustement ANIMÉ : fit(true) pose la classe `anim` sur #viewport (viewer.html setT).
// On pose un état non ajusté (« = »), on le relève IMMÉDIATEMENT (kz), on frappe « f », on attend un état postérieur différent ET la classe `anim` vue pendant « f » ; si une remise en page est passée entre le relevé et « f » (kz périmé), on recommence (3 essais). Un « f » mort (M-AJUSTEMENT) échoue aux 3.
await s.ev(`window.__animVue = 0; { const vp = document.querySelector('#viewport'); new MutationObserver((ms) => { for (const m of ms) if (vp.classList.contains('anim') && !(m.oldValue || '').split(' ').includes('anim')) window.__animVue++; }).observe(vp, { attributes: true, attributeFilter: ['class'], attributeOldValue: true }); }`);
let kz = k2, k3 = k2, animVue = false;
for (let essai = 0; essai < 3 && !(k3 !== kz && animVue); essai++) {
  await touche('='); await touche('='); kz = await k();
  await s.ev(`window.__animVue = 0`);
  await touche('f'); k3 = await attendreEtStabiliser(k, (v) => v !== kz, { pas: 50, max: 2000 });
  animVue = await s.ev(`window.__animVue > 0`);
}
out.zoom = { plus: k1 > k0, moins: k2 < k1, fit: k3 !== kz && animVue };
await fermer();
await s.attendre(`getComputedStyle(document.querySelector('#context')).opacity === '1'`, '#context rendu');
out.ctxFerme = await s.ev(`!document.body.classList.contains('vf-git-ouvert')`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/d3a.js"; } > "$AUX/d3a-complet.js"
  R3="$(cdp "$AUX/d3a-complet.js" "$BASE")"; [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R3" > "$TIROIR_TRACE-d3a.json"
  assert_eq "D3.1 — touche g ouvre puis ferme" "$(jq_ "$R3" '[j.g1, j.g2].join("|")' 2>/dev/null)" "true|false"
  assert_eq "D3.1 — g ignorée dans INPUT, TEXTAREA, contenteditable (la lettre est tapée)" "$(jq_ "$R3" '[j.champ_input, j.champ_textarea, j.champ_edit].map((c) => c.ouvert + ":" + c.valeur.includes("g")).join("|")' 2>/dev/null)" "false:true|false:true|false:true"
  assert_eq "D3.1 — g ignorée avec Ctrl, Alt, Meta et palette ouverte" "$(jq_ "$R3" '[...j.modif, j.palette].join("|")' 2>/dev/null)" "false|false|false|false"
  assert_eq "D3.7 — animation d'entrée présente (témoin) ; aucune sous prefers-reduced-motion: reduce" "$(jq_ "$R3" '[j.anim > 0, j.animReduit].join("|")' 2>/dev/null)" "true|0"
  assert_eq "D3.2 — ouvrir porte le focus sur le titre du tiroir" "$(jq_ "$R3" '[j.sel0, j.ouverture.ouvert, j.ouverture.titre].join("|")' 2>/dev/null)" "true|true|true"
  assert_eq "D3.2 — Échap (focus dans le tiroir) : fermé, focus rendu à la seconde ligne, sélection et vue inchangées" "$(jq_ "$R3" '[j.echapTiroir.ouvert, j.echapTiroir.focus, j.echapTiroir.selection, j.echapTiroir.vue].join("|")' 2>/dev/null)" "false|vf-git-ligne|true|root"
  assert_eq "D3.2 — Échap (focus sur la seconde ligne) : fermé, sélection inchangée" "$(jq_ "$R3" '[j.echapLigne.ouvert, j.echapLigne.selection].join("|")' 2>/dev/null)" "false|true"
  assert_eq "D3.2 — tiroir fermé, Échap sur la seconde ligne : le viewer la laisse à ce contrôle, la sélection n'est pas perdue (PU-G-175, lot code-moteur : hors du canvas, Échap ne lève plus la sélection)" "$(jq_ "$R3" '[j.echapFerme.ouvert, j.echapFerme.selection].join("|")' 2>/dev/null)" "false|true"
  assert_eq "D3.2 — tiroir fermé, Échap focus sur le canvas : le viewer garde son comportement (sélection levée)" "$(jq_ "$R3" '[j.echapCanvas.ouvert, j.echapCanvas.selection].join("|")' 2>/dev/null)" "false|false"
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
    const ouvreur = w < 1280 ? '#vf-git-ouvreur' : '#vf-git-ligne'; // P78-D-34 : l'icône de 701 à 1279 px, la seconde ligne dès 1280 px
    await s.attendre(`getComputedStyle(document.querySelector('${ouvreur}')).display !== 'none'`, 'ouvreur');
    await s.ev(`if (document.body.classList.contains('no-panel')) document.querySelector('#btn-panel').click(); document.querySelector('${ouvreur}').click()`);
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
  return { apresRangee: d.previousElementSibling.lastElementChild === L && !d.closest('[role=listbox]'), nb: document.querySelectorAll('.vf-git-detail').length, sujet: q('.vf-git-d-sujet').textContent, msg: q('.vf-git-d-msg').textContent, ws: getComputedStyle(q('.vf-git-d-msg')).whiteSpace, poids: getComputedStyle(q('.vf-git-d-sujet')).fontWeight,
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
await s.attendre(`document.querySelectorAll('.vf-git-detail').length >= 1 && ${LIGNES}[3].parentNode.nextElementSibling.classList.contains('vf-git-detail')`, 'détail sous la rangée 3');
out.unSeul = await attendreEtStabiliser(() => s.ev(`({ details: document.querySelectorAll('.vf-git-detail').length, sous3: ${LIGNES}[3].parentNode.lastElementChild === ${LIGNES}[3] && ${LIGNES}[3].parentNode.nextElementSibling.classList.contains('vf-git-detail') })`), (v) => v.details === 1, { max: 3000 });
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
out.selection = await s.ev(`({ sel: ${LIGNES}.filter((l) => l.getAttribute('aria-selected') === 'true').map((l) => l.dataset.h), attendu: '${sha}', detailSous: !!document.querySelector('.vf-git-detail') && document.querySelector('.vf-git-detail').previousElementSibling.lastElementChild.dataset.h === '${sha}', premiere: ${LIGNES}[0].dataset.h, live: [...document.querySelectorAll('#vf-git-tiroir [aria-live]')].map((e) => e.textContent).join('|') })`);
out.ecartPos = Math.abs((await s.ev(pos)) - p0);
// D9.2 : la sha sélectionnée disparaît
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__vfDet.apres)); window.__vfGit.reponse.rangees = window.__vfGit.reponse.rangees.filter((r) => r.h !== '${sha}'); document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'x' } }))`);
await s.attendre(`${LIGNES}.length === 40 && !${LIGNES}.some((l) => l.dataset.h === '${sha}')`, 'sha disparue');
out.disparue = await attendreEtStabiliser(() => s.ev(`({ details: document.querySelectorAll('.vf-git-detail').length, sel: ${LIGNES}.filter((l) => l.getAttribute('aria-selected') === 'true').length, tab: ${LIGNES}.filter((l) => l.getAttribute('tabindex') === '0').length, carte: /Git est indisponible/.test(document.querySelector('#vf-git-tiroir').textContent) })`), (v) => v.details === 0, { max: 5000 });
// D9.3 : tiroir fermé, aucune requête
await s.ev(`window.VFGitTiroir.fermer()`); await pause(100);
const f0 = await s.ev(cpt);
await s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'ferme' } }))`); await pause(700);
const f1 = await s.ev(cpt);
out.ferme = { git: f1.git - f0.git, wt: f1.wt - f0.wt, commit: f1.commit - f0.commit };
// à la réouverture, le signal manqué est rattrapé
await s.ev(`window.VFGitTiroir.ouvrir()`);
const f2 = await attendreEtStabiliser(() => s.ev(cpt), (c) => c.git - f1.git >= 1, { max: 5000 }); // le signal manqué est rattrapé : on attend la relecture, puis la stabilité (aucune requête en trop)
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
  # D11 (78-10, correction audit A3, P78-D-38) : un worktree servi avec verifie === false s'affiche « non vérifié » (glyphe + mot en texte neutre), sans compte, sans commande cd, sans bouton de copie ; ses étiquettes de branche non plus.
  # Réponse figée : le worktree wt-b est « non vérifié » dans le graphe (GET /api/vf/git) ET dans GET /api/vf/git/worktrees (champs à null, verifie false, comme le serveur d0da89d0) ; wt-c reste vérifié (témoin positif).
  cat > "$AUX/d11.js" <<'JS'
const [base] = ARGS; const out = {};
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
await s.ev(`(() => { const nul = { modifies: null, nonSuivis: null, plus: false, propre: null, avance: null, retard: null, avanceOrigin: null, retardOrigin: null, commande: null };
  for (const w of window.__vfGit.reponse.worktrees) w.verifie = w.chemin !== '/tmp/wt-b'; Object.assign(window.__vfGit.reponse.worktrees.find((w) => w.chemin === '/tmp/wt-b'), { commande: null });
  for (const r of window.__vfGit.reponse.rangees) for (const e of (r.refs || [])) if (e.worktree === '/tmp/wt-b') e.commande = null;
  for (const w of window.__vfDet.worktrees.worktrees) { w.verifie = w.chemin !== '/tmp/wt-b'; if (!w.verifie) Object.assign(w, nul); } })()`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l .vf-git-etat-wt').length === 3`, 'tiroir ouvert, états des trois worktrees');
out.wt = await stabiliser(() => s.ev(`[...document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l')].map((w) => ({ nom: (w.querySelector('.vf-git-gras') || {}).textContent, pastilles: [...w.querySelectorAll('.vf-git-pastille')].map((p) => p.textContent), cmd: w.querySelectorAll('.vf-git-cmd, .vf-git-sans').length, boutons: w.querySelectorAll('button').length, texte: w.textContent }))`), { max: 5000 });
out.nv = await s.ev(`(() => { const p = document.querySelector('.vf-git-p-nonverif'); if (!p) return null; const c = getComputedStyle(p), N = window.__couleur('--text-2');
  return { glyphe: getComputedStyle(p, '::before').content, neutre: c.color === N, fond: c.backgroundColor === 'rgba(0, 0, 0, 0)' || c.backgroundImage === 'none' && c.backgroundColor === 'transparent' }; })()`);
out.etiquettes = await s.ev(`({ ref: document.querySelectorAll('#vf-git-tiroir .vf-git-ref').length, avecCmd: document.querySelectorAll('#vf-git-tiroir .vf-git-ref button, #vf-git-tiroir .vf-git-ref code').length, cdWtB: document.querySelector('#vf-git-tiroir').textContent.includes("/tmp/wt-b") })`);
if (process.env.TIROIR_CAPTURE && !(await import('node:fs')).existsSync(process.env.TIROIR_CAPTURE)) { const c = await s.send('Page.captureScreenshot', { format: 'png' }); (await import('node:fs')).writeFileSync(process.env.TIROIR_CAPTURE, Buffer.from(c.data, 'base64')); } // capture facultative du D11, la première seulement (les mutants ne l'écrasent pas)
out.errs = await s.ev(`window.__errs`);
out.csp = s.violations.length;
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d11.js"; } > "$AUX/d11-complet.js"
  R11="$(cdp "$AUX/d11-complet.js" "$BASE")"
  D11A="$(jq_ "$R11" '[j.wt.length, j.wt[1].nom, j.wt[1].pastilles.join("/"), j.wt[1].cmd, j.wt[1].boutons, /[0-9]/.test(j.wt[1].texte.replace(j.wt[1].nom, "").replace(/feat\/deux/, "")), /cd /.test(j.wt[1].texte)].join("|")' 2>/dev/null)"
  assert_eq "D11.1 — worktree « non vérifié » : une seule pastille « non vérifié », aucune commande, aucun bouton de copie, aucun chiffre, aucun « cd »" "$D11A" "3|wt-b|non vérifié|0|0|false|false"
  assert_eq "D11.2 — témoin positif : le worktree vérifié (wt-c) garde ses pastilles de comptes et sa commande cd" "$(jq_ "$R11" '[j.wt[2].pastilles.join("/"), j.wt[2].cmd, j.wt[2].boutons].join("|")' 2>/dev/null)" "1 modifié|1|1"
  assert_eq "D11.3 — « non vérifié » : glyphe décoratif (texte alternatif vide), mot en texte neutre (--text-2), fond transparent" "$(jq_ "$R11" '[/ \/ ""$/.test(j.nv && j.nv.glyphe || ""), j.nv && j.nv.neutre, j.nv && j.nv.fond].join("|")' 2>/dev/null)" "true|true|true"
  assert_eq "D11.4 — étiquettes de branche du worktree non vérifié : aucune commande, aucun bouton, aucun chemin du worktree dans le tiroir" "$(jq_ "$R11" '[j.etiquettes.ref > 0, j.etiquettes.avecCmd, j.etiquettes.cdWtB].join("|")' 2>/dev/null)" "true|0|false"
  assert_eq "D11.x — 0 violation CSP, 0 erreur de page" "$(jq_ "$R11" '[j.csp, j.errs.length].join("|")' 2>/dev/null)" "0|0"
  # D12 (78-10, revue de code S5) : relectures qui se chevauchent et annonces de la région vive.
  # a) un signal émis comme 70-vf-live (sur document, sans bubbles), réponses de /api/vf/git/worktrees RETARDÉES et rendues dans le désordre : seule la réponse de la dernière demande reste affichée.
  # b) région vive : rien d'annoncé quand la relecture ne change rien ; une seule annonce « Historique mis à jour » quand elle change quelque chose ; l'échec s'annonce une seule fois, même sur deux rafales.
  cat > "$AUX/d12.js" <<'JS'
const [base] = ARGS; const out = {};
await ouvrirTiroir(base, true);
const sig = () => s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'x' } }))`);
await s.ev(`(() => { window.__ann = []; const t = document.querySelector('#vf-git-tiroir');
  new MutationObserver((ms) => { for (const m of ms) { const e = m.target.nodeType === 1 ? m.target : m.target.parentElement; if (e && e.closest('.vf-git-live') && m.addedNodes.length) window.__ann.push([...m.addedNodes].map((n) => n.textContent).join('')); } }).observe(t, { subtree: true, childList: true, characterData: true }); })()`);
// b) 1 : rien ne change
await sig(); await pause(900);
out.inchange = await s.ev(`window.__ann.splice(0)`);
// b) 2 : le graphe change (réponse « apres » du témoin)
await s.ev(`window.__vfGit.reponse = window.__vfDet.apres`);
await sig(); await attendreValeur(() => s.ev(`window.__ann.length`), (n) => n >= 1, { max: 10000 }); await pause(900); // l'annonce arrive ; la pause prouve qu'il n'y en a qu'UNE
out.change = await s.ev(`window.__ann.splice(0)`);
// b) 3 : la relecture échoue (réponse hors schéma), deux rafales d'affilée
await s.ev(`window.__vfGit.reponse = { schema: 'autre@1', etat: 'ok', rangees: [] }`);
await sig(); await attendreValeur(() => s.ev(`window.__ann.length`), (n) => n >= 1, { max: 10000 }); await pause(900); await sig(); await pause(900); // 1er échec attendu, puis la pause du 2e prouve qu'il n'est PAS réannoncé
out.echec = await s.ev(`window.__ann.splice(0)`);
// a) page neuve : réponses des worktrees retardées, rendues dans le désordre
await ouvrirTiroir(base, true);
await s.ev(`(() => { window.__wtRes = []; const f = window.fetch; window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
  if (url.includes('/api/vf/git/worktrees')) return new Promise((ok) => window.__wtRes.push((o) => ok(new Response(JSON.stringify(o), { status: 200, headers: { 'content-type': 'application/json' } }))));
  return f(u, i); }; })()`);
const nWt = () => s.ev(`window.__wtRes.length`);
await sig(); await attendreValeur(nWt, (n) => n >= 1, { max: 10000 }); await pause(700); await sig();
out.demandes = await attendreEtStabiliser(nWt, (n) => n >= 2, { max: 10000 });
const etat = (n) => s.ev(`(() => { const o = JSON.parse(JSON.stringify(window.__vfDet.worktrees)); o.worktrees[0].modifies = ${n}; return o; })()`);
const vieux = await etat(3), neuf = await etat(9);
await s.ev(`window.__wtRes[1](${JSON.stringify(neuf)})`); // la plus RÉCENTE répond d'abord
await attendreValeur(() => s.ev(`[...document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l')][0].textContent`), (t) => /9 modifiés/.test(t), { max: 5000 }); // rendue avant de résoudre la plus ancienne
await s.ev(`window.__wtRes[0](${JSON.stringify(vieux)})`); await pause(400); // puis la plus ancienne
out.pastilles = await s.ev(`[...document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l')][0].textContent`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d12.js"; } > "$AUX/d12-complet.js"
  R12="$(cdp "$AUX/d12-complet.js" "$BASE")"
  [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R12" > "$TIROIR_TRACE-d12.json"
  assert_eq "D12.1 — une relecture qui ne change rien : aucune annonce de la région vive" "$(jq_ "$R12" 'j.inchange.length' 2>/dev/null)" "0"
  assert_eq "D12.2 — une relecture réussie qui change le graphe : une seule annonce, « Historique mis à jour »" "$(jq_ "$R12" 'j.change.join("|")' 2>/dev/null)" "Historique mis à jour"
  assert_eq "D12.3 — relecture en échec, deux rafales : l'échec est annoncé une seule fois, jamais « mis à jour »" "$(jq_ "$R12" '[j.echec.length, /indisponible/.test(j.echec[0] || ""), j.echec.some((t) => /mis à jour/.test(t))].join("|")' 2>/dev/null)" "1|true|false"
  assert_eq "D12.4 — deux relectures des worktrees en vol : les deux demandes sont parties (témoin)" "$(jq_ "$R12" 'j.demandes' 2>/dev/null)" "2"
  assert_eq "D12.4 — réponses rendues dans le désordre (la récente d'abord) : seule la dernière demande reste affichée (9 modifiés, pas 3)" "$(jq_ "$R12" '[/9 modifiés/.test(j.pastilles), /3 modifiés/.test(j.pastilles)].join("|")' 2>/dev/null)" "true|false"
  assert_eq "D12.x — aucune erreur de page" "$(jq_ "$R12" 'j.errs.length' 2>/dev/null)" "0"
  # D13 (78-10, revue de delta F1, P78-D-42) : un compteur nullable ne s'affiche jamais « 0 ». Réponse figée : une branche sans base (avance: null), la base elle-même (avance: 0), une branche à 3 ; un worktree dont avance est null et retard 1.
  cat > "$AUX/d13.js" <<'JS'
const [base] = ARGS; const out = {};
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
await s.ev(`(() => { window.__vfGit.reponse.parBranche = [{ nom: 'main', avance: 0, dernier: 1793999999 }, { nom: 'feat/inconnue', avance: null, dernier: 1793904000 }, { nom: 'feat/f4', avance: 3, dernier: 1793904000 }];
  window.__vfDet.worktrees.worktrees[0].avance = null; window.__vfDet.worktrees.worktrees[0].retard = 1; })()`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l .vf-git-etat-wt').length === 3`, 'tiroir ouvert, états des worktrees');
await s.ev(`document.querySelector('.vf-git-sec-t[aria-controls="vf-git-s-aut"]').click()`);
out.branches = await s.ev(`(() => { const l = []; let e = document.querySelector('#vf-git-s-aut .vf-git-sous'); e = e && e.nextElementSibling;
  for (; e; e = e.nextElementSibling) { const m = e.querySelector('.meta'); l.push({ nom: e.querySelector('.vf-git-mono').textContent, txt: m.textContent, label: m.getAttribute('aria-label'), chiffre: /[0-9]/.test(m.textContent) }); } return l; })()`);
out.wt = await s.ev(`[...document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l')][0].querySelector('.vf-git-p-mono')?.textContent ?? null`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d13.js"; } > "$AUX/d13-complet.js"
  R13="$(cdp "$AUX/d13-complet.js" "$BASE")"
  [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R13" > "$TIROIR_TRACE-d13.json"
  assert_eq "D13.1 — avance null : « — » sans chiffre et libellé accessible « avance inconnue », jamais « 0 commit »" "$(jq_ "$R13" '(j.branches.find((b) => b.nom === "feat/inconnue") || {}).txt + "|" + (j.branches.find((b) => b.nom === "feat/inconnue") || {}).chiffre + "|" + (j.branches.find((b) => b.nom === "feat/inconnue") || {}).label' 2>/dev/null)" "—|false|avance inconnue"
  assert_eq "D13.2 — témoins positifs : la base (avance 0) dit « 0 commit », la branche à 3 dit « 3 commits », sans libellé inconnu" "$(jq_ "$R13" 'j.branches.filter((b) => b.nom !== "feat/inconnue").map((b) => b.txt + ":" + b.label).join("|")' 2>/dev/null)" "0 commit:null|3 commits:null"
  assert_eq "D13.3 — pastille d'un worktree dont l'avance est inconnue : « ↑— ↓1 », jamais « ↑0 »" "$(jq_ "$R13" 'j.wt' 2>/dev/null)" "↑— ↓1"
  assert_eq "D13.x — aucune erreur de page" "$(jq_ "$R13" 'j.errs.length' 2>/dev/null)" "0"
  # D14 (78-10, revue de delta F6b) : la région vive annonce un échec, puis rien sur un succès sans changement, puis annonce de nouveau le second échec (le drapeau « déjà dit » retombe au succès).
  cat > "$AUX/d14.js" <<'JS'
const [base] = ARGS; const out = {};
await ouvrirTiroir(base, true);
const sig = () => s.ev(`document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: 'x' } }))`);
await s.ev(`(() => { window.__ann = []; const t = document.querySelector('#vf-git-tiroir');
  new MutationObserver((ms) => { for (const m of ms) { const e = m.target.nodeType === 1 ? m.target : m.target.parentElement; if (e && e.closest('.vf-git-live') && m.addedNodes.length) window.__ann.push([...m.addedNodes].map((n) => n.textContent).join('')); } }).observe(t, { subtree: true, childList: true, characterData: true }); })()`);
await s.ev(`window.__vfGit.reponse = { schema: 'autre@1', etat: 'ok', rangees: [] }`);
await sig(); await attendreValeur(() => s.ev(`window.__ann.length`), (n) => n >= 1, { max: 10000 }); await pause(900);
out.echec1 = await s.ev(`window.__ann.splice(0)`);
await s.ev(`window.__vfGit.reponse = JSON.parse(JSON.stringify(window.__TEMOIN_REF))`);
await sig(); await pause(900);
out.succes = await s.ev(`window.__ann.splice(0)`);
await s.ev(`window.__vfGit.reponse = { schema: 'autre@1', etat: 'ok', rangees: [] }`);
await sig(); await attendreValeur(() => s.ev(`window.__ann.length`), (n) => n >= 1, { max: 10000 }); await pause(900);
out.echec2 = await s.ev(`window.__ann.splice(0)`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d14.js"; } > "$AUX/d14-complet.js"
  R14="$(cdp "$AUX/d14-complet.js" "$BASE")"
  [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R14" > "$TIROIR_TRACE-d14.json"
  assert_eq "D14.1 — échec, succès, échec : le premier échec est annoncé, le succès ne dit jamais « indisponible »" "$(jq_ "$R14" '[j.echec1.length, /indisponible/.test(j.echec1[0] || ""), j.succes.some((x) => /indisponible/.test(x))].join("|")' 2>/dev/null)" "1|true|false"
  assert_eq "D14.2 — le second échec, après un succès, est annoncé de nouveau (une fois)" "$(jq_ "$R14" '[j.echec2.length, /indisponible/.test(j.echec2[0] || "")].join("|")' 2>/dev/null)" "1|true"
  assert_eq "D14.x — aucune erreur de page" "$(jq_ "$R14" 'j.errs.length' 2>/dev/null)" "0"
  # D15 (78-10, recette G4 à G6) : remplissage neutre des barres d'activité, contrastes >= 4,5:1 dans les deux thèmes, une seule région vive, coche le temps du « Copiée ».
  cat > "$AUX/d15.js" <<'JS'
const [base] = ARGS; const out = {};
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
await s.ev(`(() => { const w = window.__vfGit.reponse.worktrees.find((x) => !x.ici); if (w) w.commande = null; })()`); // une rangée « Aucune commande proposée »
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l .vf-git-etat-wt').length === 3`, 'tiroir ouvert, états des worktrees');
await s.ev(`document.querySelector('.vf-git-sec-t[aria-controls="vf-git-s-aut"]').click()`);
// G4 : remplissage de barre DANS le tiroir = texte neutre, jamais le vert d'état (--st-done). Témoin d'existence : la barre est là et a une largeur. `hors` (la même classe hors du tiroir) n'est pas affirmé : le thème global la rend neutre aussi (71.5), il ne sert qu'à prouver, par mutant, que le thème global a bien été recoloré.
out.barre = await s.ev(`(() => { const i = document.querySelector('#vf-git-s-aut .vf-bar i'), p = document.createElement('div'); p.className = 'vf-bar'; p.appendChild(document.createElement('i')); document.body.appendChild(p);
  const hors = getComputedStyle(p.firstChild).backgroundColor; p.remove(); return { existe: !!i, largeur: i ? i.getBoundingClientRect().width : 0, dans: i ? getComputedStyle(i).backgroundColor : null, neutre: window.__couleur('--text-3'), vert: window.__couleur('--st-done'), hors }; })()`);
// G5 : contrastes (composition alpha des fonds jusqu'au premier fond opaque), deux thèmes
const mesure = `(() => { const num = (c) => (c.match(/[\\d.]+/g) || []).map(Number), over = (f, b) => { const a = f[3] == null ? 1 : f[3]; return [0, 1, 2].map((k) => f[k] * a + b[k] * (1 - a)).concat(1); };
  const fond = (e) => { const L = []; for (let n = e; n; n = n.parentElement) { const c = num(getComputedStyle(n).backgroundColor); if (c.length >= 3 && (c[3] == null || c[3] > 0)) { L.push(c); if (c[3] == null || c[3] === 1) break; } } let b = [255, 255, 255, 1]; if (L.length && (L[L.length - 1][3] == null || L[L.length - 1][3] === 1)) b = L.pop().slice(0, 3).concat(1); while (L.length) b = over(L.pop(), b); return b; };
  const lum = (c) => { const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]); };
  const ratio = (e) => { const b = fond(e), t = num(getComputedStyle(e).color), c = over(t, b), x = lum(c), y = lum(b), h = Math.max(x, y), l = Math.min(x, y); return Math.round(((h + 0.05) / (l + 0.05)) * 100) / 100; };
  const min = (sel) => { const L = [...document.querySelectorAll(sel)]; return L.length ? Math.min(...L.map(ratio)) : -1; };
  return { sans: min('#vf-git-tiroir .vf-git-sans'), meta: min('#vf-git-tiroir .meta'), kbd: min('.vf-git-ligne .kbd'), pastille: min('#vf-git-tiroir .vf-git-pastille') }; })()`;
// le thème « auto » suit prefers-color-scheme (Chrome headless sous Linux : clair) : la mesure « sombre » le pose elle-même, sinon elle mesurerait le clair deux fois (78-10, correction CI Linux)
await s.ev(`document.documentElement.setAttribute('data-theme', 'dark')`);
out.themes = [await s.ev(`document.documentElement.getAttribute('data-theme')`)];
out.sombre = await stabiliser(() => s.ev(mesure), { max: 5000 });
await s.ev(`document.documentElement.setAttribute('data-theme', 'light')`);
out.themes.push(await s.ev(`document.documentElement.getAttribute('data-theme')`));
out.clair = await stabiliser(() => s.ev(mesure), { max: 5000 });
await s.ev(`document.documentElement.setAttribute('data-theme', 'dark')`);
// G6 : une seule région vive, une annonce par copie, coche le temps du « Copiée »
await s.ev(`(() => { navigator.clipboard.writeText = () => Promise.resolve(); window.__ann = []; const t = document.querySelector('#vf-git-tiroir');
  new MutationObserver((ms) => { for (const m of ms) { const r = m.target.nodeType === 1 ? m.target.closest('[aria-live]') : m.target.parentElement && m.target.parentElement.closest('[aria-live]'); if (r && m.addedNodes.length) window.__ann.push([r.className, [...m.addedNodes].map((n) => n.textContent).join('')]); } }).observe(t, { subtree: true, childList: true, characterData: true }); })()`);
const bouton = `document.querySelector('#vf-git-s-wt .vf-git-cmd .vf-git-btn')`;
out.iconeAvant = await s.ev(`${bouton}.querySelector('path').getAttribute('d')`);
await s.ev(`${bouton}.click()`);
const coche = await attendreValeur(() => s.ev(`({ d: ${bouton}.querySelector('path').getAttribute('d'), retour: ${bouton}.parentElement.querySelector('.vf-git-retour').textContent })`), (v) => v.retour !== '', { max: 1500 }); // « Copiée » posé au retour de la promesse, avant l'effacement produit à 1600 ms : borne 1,5 s ; « Copiée » affiché (icône et texte posés par le même appel du produit) : on lit les deux à cet instant, avant l'effacement à 1600 ms
out.iconeCoche = coche.d;
out.retour = coche.retour;
await s.ev(`${LIGNES}[2].click()`);
await s.attendre(`!!document.querySelector('.vf-git-detail .vf-git-d-fichiers')`, 'détail ouvert');
await s.ev(`document.querySelector('.vf-git-det .vf-git-cmd .vf-git-btn').click()`);
out.iconeApres = await attendreValeur(() => s.ev(`${bouton}.querySelector('path').getAttribute('d')`), (d) => d === out.iconeAvant, { max: 4000 }); // minuterie produit 1600 ms : borne 4 s (≈ 2,5 x), une régression du minuteur reste rouge
out.regions = await s.ev(`document.querySelectorAll('#vf-git-tiroir [aria-live]').length`);
out.copies = await s.ev(`window.__ann.filter((a) => /Commande copiée/.test(a[1]))`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d15.js"; } > "$AUX/d15-complet.js"
  R15="$(cdp "$AUX/d15-complet.js" "$BASE")"
  [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R15" > "$TIROIR_TRACE-d15.json"
  assert_eq "D15.1 — barres d'activité DANS le tiroir : remplissage en texte neutre (--text-3), jamais le vert d'état (--st-done) ; la barre existe, a une largeur, et le neutre est distinct du vert d'état" "$(jq_ "$R15" '[j.barre.existe, j.barre.largeur > 0, j.barre.dans === j.barre.neutre, j.barre.neutre !== j.barre.vert].join("|")' 2>/dev/null)" "true|true|true|true"
  assert_eq "D15.2 — contraste >= 4,5:1 en sombre : « Aucune commande proposée », pilules .meta, kbd « g », pastilles" "$(jq_ "$R15" 'Object.values(j.sombre).every((v) => v >= 4.5) ? "ok" : JSON.stringify(j.sombre)' 2>/dev/null)" "ok"
  assert_eq "D15.2a — témoin : la mesure « sombre » est faite en thème sombre et la mesure « clair » en thème clair (le thème n'est jamais laissé à prefers-color-scheme du poste), les deux jeux de rapports diffèrent" "$(jq_ "$R15" '[j.themes.join("/"), JSON.stringify(j.sombre) !== JSON.stringify(j.clair)].join("|")' 2>/dev/null)" "dark/light|true"
  assert_eq "D15.3 — contraste >= 4,5:1 en clair : mêmes éléments" "$(jq_ "$R15" 'Object.values(j.clair).every((v) => v >= 4.5) ? "ok" : JSON.stringify(j.clair)' 2>/dev/null)" "ok"
  assert_eq "D15.4 — une seule région aria-live dans le tiroir, une annonce « Commande copiée » par copie (deux copies : deux annonces), toutes de la même région" "$(jq_ "$R15" '[j.regions, j.copies.length, new Set(j.copies.map((c) => c[0])).size].join("|")' 2>/dev/null)" "1|2|1"
  assert_eq "D15.5 — icône de copie : coche le temps du « Copiée », puis de nouveau l'icône de copie" "$(jq_ "$R15" '[j.iconeAvant, j.iconeCoche, j.retour, j.iconeApres === j.iconeAvant].join("|")' 2>/dev/null)" "M9 9h10v10H9zM5 15V5h10|M5 13l4 4L19 7|Copiée|true"
  assert_eq "D15.x — aucune erreur de page" "$(jq_ "$R15" 'j.errs.length' 2>/dev/null)" "0"
  # D16 (GT1, PU-G-192/194/195/196/197) : « lecture… » tant que l'état des worktrees n'est pas lu (distinct d'un échec « lecture impossible »), infobulle des ↑↓, détail d'un commit :
  # la commande qui change la copie de travail porte son étiquette. SURFACE DURCIE : un nom de base hostile n'entre que dans un title/aria-label (setAttribute), jamais dans une commande ni en HTML.
  cat > "$AUX/d16.js" <<'JS'
const [base] = ARGS; const out = {};
const HOSTILE = `ma"b'$(touch x);<img src=x onerror=alert(1)>`;
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
await s.ev(`(() => { window.__vfGit.reponse.base.nom = ${JSON.stringify(HOSTILE)}; const W = window.__vfDet.worktrees.worktrees;
  Object.assign(W[0], { propre: false, modifies: 1, nonSuivis: 0, avance: 312, retard: 4 });
  Object.assign(W[1], { modifies: null, nonSuivis: null, plus: false, propre: null, avance: null, retard: null });
  window.__vfDet.delaiWt = 1200; })()`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l').length === 3`, 'tiroir ouvert');
const etats = `[...document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l')].map((w) => [...w.querySelectorAll('.vf-git-pastille')].map((p) => p.textContent).join('/'))`;
out.enCours = await s.ev(etats);
await s.attendre(`/lecture impossible/.test(document.querySelector('#vf-git-s-wt').textContent)`, 'état lu', 6000);
out.lu = await s.ev(etats);
out.avance = await s.ev(`(() => { const p = document.querySelector('#vf-git-s-wt .vf-git-p-mono'); return { txt: p.textContent, title: p.getAttribute('title'), aria: p.getAttribute('aria-label') }; })()`);
await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {}); // voir D2 : sans focus de fenêtre, aucun évènement « focus »
await s.ev(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', bubbles: true }))`); // dernière entrée = une touche (voir D2)
await s.ev(`document.querySelector('#vf-git-s-wt .vf-git-p-mono').focus()`);
await attendreValeur(() => s.ev(`!!document.querySelector('.vf-git-bulle') && !document.querySelector('.vf-git-bulle').hidden`), (v) => v === true, { max: 2000 }).catch(() => {}); // attente bornée : un mutant qui ne montre rien doit rougir, pas planter
out.focusAvance = await s.ev(`(() => { const p = document.querySelector('#vf-git-s-wt .vf-git-p-mono'), b = document.querySelector('.vf-git-bulle'); const r = b && !b.hidden ? b.getBoundingClientRect() : null; return { tab: p.tabIndex, actif: document.activeElement === p, texte: b && !b.hidden ? b.textContent : null, vu: !!r && r.width > 0 && r.right <= innerWidth && r.bottom <= innerHeight, balises: b ? b.querySelectorAll('*').length : -1 }; })()`);
await s.ev(`document.activeElement.blur()`);
out.attendu = `312 commits d'avance sur ${HOSTILE}, 4 commits de retard`;
out.inerte = await s.ev(`({ balises: document.querySelectorAll('#vf-git-tiroir img, #vf-git-tiroir script').length, alertes: window.__alerte, cmdHostile: [...document.querySelectorAll('#vf-git-tiroir .vf-git-cmd code')].some((c) => c.textContent.includes('touch x')) })`);
await s.ev(`document.querySelector('#vf-git-tiroir li[role=option]').click()`);
await s.attendre(`!!document.querySelector('.vf-git-det .vf-git-cmd')`, 'détail');
out.detail = await s.ev(`(() => { const G = [...document.querySelectorAll('.vf-git-det .vf-git-d-cmds')], N = window.__couleur('--text-3');
  return { n: G.length, titres: G.map((g) => g.firstChild.textContent), cmds: G.map((g) => g.querySelector('code').textContent.split(' ').slice(0, 2).join(' ')), change: G.map((g) => g.classList.contains('vf-git-d-change')), neutre: G.every((g) => getComputedStyle(g.firstChild).color === N), glyphe: getComputedStyle(G[1].firstChild, '::before').content, hostile: document.querySelector('.vf-git-det').textContent.includes('touch x') }; })()`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d16.js"; } > "$AUX/d16-complet.js"
  R16="$(cdp "$AUX/d16-complet.js" "$BASE")"
  assert_eq "D16.1 — PU-G-192 : tant que git status n'est pas lu, chaque worktree dit « lecture… » (jamais « état illisible »)" "$(jq_ "$R16" 'j.enCours.join(" | ")' 2>/dev/null)" "lecture… | lecture… | lecture…"
  assert_eq "D16.2 — PU-G-192 : une lecture qui échoue (comptes null) se distingue de la lecture en cours : « lecture impossible »" "$(jq_ "$R16" 'j.lu.join(" | ")' 2>/dev/null)" "1 modifié/↑312 ↓4 | lecture impossible | 1 modifié"
  assert_eq "D16.3 — PU-G-196 : infobulle ↑/↓ « 312 commits d'avance sur <base>, 4 commits de retard » (title et aria-label identiques, nom de base lu comme texte)" "$(jq_ "$R16" '[j.avance.title === j.attendu, j.avance.aria === j.attendu, j.avance.txt].join("|")' 2>/dev/null)" "true|true|↑312 ↓4"
  assert_eq "D16.3b — PU-G-196 : au focus clavier, l'indicateur ↑/↓ (atteignable par Tab) montre la même phrase que son aria-label dans une bulle visible, nom de base lu comme texte (aucun élément dans la bulle)" "$(jq_ "$R16" '[j.focusAvance.tab, j.focusAvance.actif, j.focusAvance.texte === j.attendu, j.focusAvance.vu, j.focusAvance.balises].join("|")' 2>/dev/null)" "0|true|true|true|0"
  assert_eq "D16.4 — surface durcie : un nom de base hostile ne crée ni <img>, ni <script>, ni alerte, et n'entre dans aucune commande affichée" "$(jq_ "$R16" '[j.inerte.balises, j.inerte.alertes, j.inerte.cmdHostile, j.detail.hostile].join("|")' 2>/dev/null)" "0|0|false|false"
  assert_eq "D16.5 — PU-G-194 : deux groupes, lecture puis « Change votre copie de travail » (git show / git switch --detach), séparé, texte neutre, glyphe décoratif" "$(jq_ "$R16" '[j.detail.n, j.detail.titres.join("/"), j.detail.cmds.join("/"), j.detail.change.join(), j.detail.neutre, /^"△ " \/ ""$/.test(j.detail.glyphe)].join("|")' 2>/dev/null)" "2|Pour lire ce commit/Change votre copie de travail|git show/git switch|false,true|true|true"
  assert_eq "D16.x — aucune erreur de page" "$(jq_ "$R16" 'j.errs.length' 2>/dev/null)" "0"
  # D18 (recette du 2026-11-08, PU-G-193) : la définition d'un terme Git se montre AUSSI au focus clavier (le title ne se montre qu'au survol) ; Échap la ferme sans fermer le tiroir ; elle suit l'élément qui défile ; le départ du focus la ferme.
  # Scénario neuf et isolé (page fraîche, états des worktrees lus) : le focus de la fenêtre est posé AVANT tout, sinon element.focus() ne déclenche aucun évènement « focus » ; les lectures de la bulle sont des attentes bornées (un mutant qui ne montre rien doit ROUGIR, pas planter).
  cat > "$AUX/d18.js" <<'JS'
const [base] = ARGS; const out = { detache: {} };
await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await s.attendre(`${OUVERT} && document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l').length >= 3`, 'tiroir ouvert, worktrees rendus');
await attendreValeur(() => s.ev(`!!document.querySelector('#vf-git-s-wt .vf-git-etat-wt')`), (v) => v === true, { max: 6000 }); // états lus : plus de rendu à venir sous le focus
const T = `document.querySelector('#vf-git-tiroir')`, DETACHE = `[...document.querySelectorAll('#vf-git-s-wt .vf-git-wt-l .vf-git-mono')].find((x) => x.textContent === 'HEAD détaché')`;
const BULLE = `(() => { const b = document.querySelector('.vf-git-bulle'); if (!b || b.hidden) return null; const r = b.getBoundingClientRect(); return { texte: b.textContent, vu: r.width > 0 && r.height > 0 && r.left >= 0 && r.top >= 0 && r.right <= innerWidth && r.bottom <= innerHeight, role: b.getAttribute('role') }; })()`;
const lire = async (fin) => { let v; for (let i = 0; i < 20; i++) { v = await s.ev(BULLE); if (fin(v)) return v; await pause(100); } return v; };
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const echap = (cible) => s.ev(`${cible}.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }))`);
const ouvert = () => s.ev(`(() => { const t = ${T}; return !!t && !t.hidden; })()`);
await s.ev(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', bubbles: true }))`); // la dernière entrée est une touche (le chemin des vraies touches est vérifié à la main)
await s.attendre(`!!document.querySelector('#context h1[data-vf-aide]')`, 'titre de la vue avec sa définition');
await s.ev(`document.querySelector('#context h1').focus()`);
out.h1 = await lire((v) => v !== null);
out.h1tab = await s.ev(`document.querySelector('#context h1').tabIndex`);
await s.ev(`document.activeElement.blur()`);
await lire((v) => v === null);
await s.ev(`${DETACHE}.focus()`);
out.detache.bulle = await lire((v) => v !== null);
out.detache.atteignable = await s.ev(`(() => { const m = ${DETACHE}; return { tab: m.tabIndex, desc: m.getAttribute('aria-description') === m.getAttribute('title'), actif: document.activeElement === m }; })()`);
await echap(DETACHE);
out.detache.apresEchap = { bulle: await lire((v) => v === null), tiroir: await ouvert() };
await echap(DETACHE); // second Échap (bulle déjà fermée) : c'est lui qui ferme le tiroir, preuve que le premier ne le faisait pas par impuissance
out.detache.secondEchap = await ouvert();
if (!out.detache.secondEchap) { await s.ev(`document.querySelector('#vf-git-ligne').click()`); await s.attendre(`!${T}.hidden`, 'tiroir rouvert'); }
await s.ev(`[...${T}.querySelectorAll('.vf-git-sec-t')].find((x) => /^Worktrees/.test(x.textContent)).focus()`);
out.worktrees = await lire((v) => v !== null);
await s.ev(`document.activeElement.blur()`);
out.depart = await lire((v) => v === null);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/d18.js"; } > "$AUX/d18-complet.js"
  R18="$(cdp "$AUX/d18-complet.js" "$BASE")"
  assert_eq "D18.1 — PU-G-193 : au focus clavier, « HEAD détaché » (atteignable par Tab, même phrase en aria-description) montre sa définition dans une bulle visible, dans la fenêtre" "$(jq_ "$R18" '[j.detache.atteignable.tab, j.detache.atteignable.desc, j.detache.atteignable.actif, !!j.detache.bulle && j.detache.bulle.vu, !!j.detache.bulle && /^HEAD détaché : ce dossier n.est sur aucune branche/.test(j.detache.bulle.texte)].join("|")' 2>/dev/null)" "0|true|true|true|true"
  assert_eq "D18.2 — PU-G-193 : Échap ferme la bulle SANS fermer le tiroir (le premier Échap ne sert qu'à elle) ; un second Échap, bulle fermée, ferme le tiroir (témoin : il aurait pu se fermer)" "$(jq_ "$R18" '[j.detache.apresEchap.bulle === null, j.detache.apresEchap.tiroir, j.detache.secondEchap].join("|")' 2>/dev/null)" "true|true|false"
  assert_eq "D18.3 — PU-G-193 : le bouton « Worktrees » montre aussi sa définition au focus ; elle se ferme quand le focus part" "$(jq_ "$R18" '[!!j.worktrees && /^Worktrees : copies de travail du dépôt/.test(j.worktrees.texte), j.depart === null].join("|")' 2>/dev/null)" "true|true"
  assert_eq "D18.4 — PU-G-193 : le titre de la vue (« Le code, <branche> », définition Branche / HEAD détaché) est atteignable par Tab et montre sa définition au focus clavier" "$(jq_ "$R18" '[j.h1tab, !!j.h1 && /^Branche : une ligne de travail du dépôt/.test(j.h1.texte)].join("|")' 2>/dev/null)" "0|true"
  assert_eq "D18.x — aucune erreur de page" "$(jq_ "$R18" '(j.errs || []).length' 2>/dev/null)" "0"
  # D17 (GT2, PU-G-198/199/200/201 ; DG-01 part page, PU-G-191) : focus visible à l'ouverture, détail hors de la liste, noms des boutons Copier, Échap à 390 px, une relance automatique unique.
  # SURFACE DURCIE : le nom d'une branche entre dans un aria-label (setAttribute) et nulle part ailleurs ; la commande copiée reste celle du <code> affiché.
  cat > "$AUX/d17a.js" <<'JS'
const [base] = ARGS; const out = {};
const HOSTILE = `ma"b'$(touch x);<img src=x onerror=alert(1)>`;
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
await s.ev(`(() => { const R = window.__vfGit.reponse; R.worktrees[1].nom = 'bisect-ci'; R.mergees[0] = { nom: ${JSON.stringify(HOSTILE)}, commande: "git branch -d --end-of-options 'ma\\"b'\\\\''$(touch x);<img src=x onerror=alert(1)>'" };
  window.__copies = []; navigator.clipboard.writeText = (t) => { window.__copies.push(t); return window.__refuse ? Promise.reject(new Error('refus')) : Promise.resolve(); }; })()`);
await touche('g');
await s.attendre(`${OUVERT} && ${LIGNES}.length === 40`, 'tiroir ouvert au clavier');
out.focus = await stabiliser(() => s.ev(`(() => { const t = document.querySelector('#vf-git-tiroir .vf-git-titre-t'), c = getComputedStyle(t); return { sur: document.activeElement === t, style: c.outlineStyle, largeur: c.outlineWidth, couleur: c.outlineColor, anneau: window.__couleur('--ring') }; })()`), { max: 5000 });
// 199 : la région du détail sort de la liste et se relie par aria-controls
await s.ev(`${LIGNES}[2].click()`);
await s.attendre(`!!document.querySelector('.vf-git-det .vf-git-d-fichiers')`, 'détail ouvert');
out.detail = await s.ev(`(() => { const z = document.querySelector('.vf-git-det'), L = ${LIGNES}[2], id = L.getAttribute('aria-controls');
  return { horsListe: !z.closest('[role=listbox]'), role: z.getAttribute('role'), relie: !!id && document.getElementById(id) === z, options: document.querySelectorAll('#vf-git-tiroir [role=listbox] > [role=option]').length, orphelins: [...document.querySelectorAll('#vf-git-tiroir [role=listbox] > :not([role=option])')].length, listes: document.querySelectorAll('#vf-git-tiroir [role=listbox]').length, autres: ${LIGNES}.filter((l, i) => i !== 2 && l.hasAttribute('aria-controls')).length }; })()`);
// 200 : noms courts des boutons Copier, nom hostile inerte, texte copié = texte affiché
await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-sec-t')].forEach((b) => { if (b.getAttribute('aria-expanded') !== 'true') b.click(); }); document.querySelector('#vf-git-tiroir .vf-git-merg-b').click()`);
out.noms = await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-btn')].map((b) => b.getAttribute('aria-label'))`);
out.attributs = await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-btn')].every((b) => [...b.attributes].map((a) => a.name).sort().join() === 'aria-label,class,type')`);
out.hostile = await s.ev(`(() => { const b = [...document.querySelectorAll('#vf-git-tiroir .vf-git-btn')].find((x) => x.parentNode.querySelector('code').textContent.includes('touch x')); const code = b.parentNode.querySelector('code');
  return { label: b.getAttribute('aria-label'), attendu: 'Copier la commande de suppression de la branche ' + ${JSON.stringify(HOSTILE)}, balises: document.querySelectorAll('#vf-git-tiroir img, #vf-git-tiroir script, #vf-git-tiroir [onerror]').length, alertes: window.__alerte, code: code.textContent }; })()`);
await s.ev(`[...document.querySelectorAll('#vf-git-tiroir .vf-git-btn')].find((x) => x.parentNode.querySelector('code').textContent.includes('touch x')).click()`);
await s.attendre(`window.__copies.length === 1`, 'copie du nom hostile');
out.copie = await s.ev(`({ spy: window.__copies[0], live: document.querySelector('#vf-git-tiroir .vf-git-live').textContent, alertes: window.__alerte })`);
await s.ev(`window.__refuse = true; document.querySelector('#vf-git-s-wt .vf-git-btn').click()`);
out.refus = await attendreValeur(() => s.ev(`document.querySelector('#vf-git-tiroir .vf-git-live').textContent`), (t) => /impossible/.test(t), { max: 10000 });
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d17a.js"; } > "$AUX/d17a-complet.js"
  cat > "$AUX/d17b.js" <<'JS'
const [base, w0] = ARGS, w = w0 || 390; const out = {};
await fenetre(Number(w), 800); await s.naviguer(base + '/');
await s.attendre(`document.readyState === 'complete' && !!document.querySelector('#vf-plus') && !!document.querySelector('#vf-git-tiroir')`, 'page prête');
// le vrai chemin à cette largeur : de 1000 px, la seconde ligne de l'en-tête (le menu « ⋯ » n'est posé que jusqu'à 999 px, l'ouvreur n'y figure qu'à 700 px et moins) ; à 390 px, l'entrée « Historique Git » du menu
if (Number(w) >= 1000) await s.ev(`document.querySelector('#vf-git-ligne').click()`);
else { await s.ev(`document.querySelector('#vf-plus').click()`);
  await s.ev(`[...document.querySelectorAll('#vf-plus-menu button')].find((b) => /Git/.test(b.textContent)).click()`); }
await s.attendre(`!document.querySelector('#vf-git-tiroir').hidden`, 'tiroir ouvert');
out.ouvert = await s.ev(`document.activeElement.classList.contains('vf-git-titre-t')`);
await touche('Escape');
out.ferme = await attendreValeur(() => s.ev(`document.querySelector('#vf-git-tiroir').hidden`), (h) => h === true, { max: 5000 });
out.focus = await stabiliser(() => s.ev(`document.activeElement.id`), { max: 5000 });
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d17b.js"; } > "$AUX/d17b-complet.js"
  cat > "$AUX/d17c.js" <<'JS'
const [base] = ARGS; const out = {};
await fenetre(1440, 900); await s.naviguer(base + '/'); await pret();
await s.attendre(`getComputedStyle(document.querySelector('#vf-git-ligne')).display !== 'none'`, 'seconde ligne');
const T = `document.querySelector('#vf-git-tiroir')`;
const INDISPO = `{ schema: 'vibeflow/cockpit-git@1', etat: 'indisponible', entete: { etat: 'indisponible', depot: 'depot' }, commandes: { vide: null, diagnostic: 'git status' } }`;
// mock de route : la première lecture répond « indisponible », les suivantes le bon état
await s.ev(`(() => { const f = window.fetch.bind(window), bon = JSON.parse(JSON.stringify(window.__TEMOIN_REF)); let n = 0; window.fetch = (u, i) => { if (/\\/api\\/vf\\/git(\\?|$)/.test(typeof u === 'string' ? u : u.url)) { n++; window.__vfGit.reponse = n === 1 ? ${INDISPO} : bon; } return f(u, i); }; })()`);
await s.ev(`document.querySelector('#vf-git-ligne').click()`);
await attendreValeur(() => s.ev(`${LIGNES}.length === 40`), (v) => v === true, { pas: 100, max: 10000 }); // ne lève pas : sans relance, le mutant doit rendre une trace, pas une erreur de scénario
out.relance = await s.ev(`({ reqs: window.__vfReqs.length, carte: /Git est indisponible/.test(${T}.textContent), busy: ${T}.querySelector('.vf-git-corps').getAttribute('aria-busy') })`);
// toujours « indisponible » : une seule relance, jamais de boucle, puis la raison humaine
await s.ev(`window.__vfGit.reponse = ${INDISPO}; window.fetch = (u, i) => { if (/\\/api\\/vf\\/git(\\?|$)/.test(typeof u === 'string' ? u : u.url)) { window.__vfReqs.push({ url: u }); return Promise.resolve(new Response(JSON.stringify(${INDISPO}), { status: 200, headers: { 'content-type': 'application/json' } })); } return Promise.resolve(new Response('{}')); }; window.__avant = window.__vfReqs.length; window.VFGitTiroir.fermer(); window.VFGitTiroir.recharger()`);
await s.attendre(`/Git est indisponible/.test(${T}.textContent)`, 'carte indisponible');
await pause(700);
out.boucle = await s.ev(`({ reqs: window.__vfReqs.length - window.__avant, texte: ${T}.querySelector('.vf-git-carte .vf-git-note').textContent })`);
// aucune réponse exploitable (hors schéma) : même relance unique, autre raison
await s.ev(`window.fetch = (u, i) => { window.__vfReqs.push({ url: u }); return Promise.resolve(new Response(JSON.stringify({ schema: 'autre@1' }), { status: 200, headers: { 'content-type': 'application/json' } })); }; window.__avant = window.__vfReqs.length; window.VFGitTiroir.recharger()`);
await attendreValeur(() => s.ev(`(${T}.querySelector('.vf-git-carte .vf-git-note') || {}).textContent || ''`), (t) => /n'a pas abouti/.test(t), { max: 10000 }); // raison propre à cette réponse, avant de prouver qu'il n'y a pas de boucle
await pause(700);
out.horsSchema = await s.ev(`({ reqs: window.__vfReqs.length - window.__avant, texte: ${T}.querySelector('.vf-git-carte .vf-git-note').textContent })`);
out.errs = await s.ev(`window.__errs`);
return out;
JS
  { cat "$AUX/touche.js"; cat "$AUX/clavier.js"; cat "$AUX/d17c.js"; } > "$AUX/d17c-complet.js"
  R17="$(cdp "$AUX/d17a-complet.js" "$BASE")"
  [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R17" > "$TIROIR_TRACE-d17a.json"
  assert_eq "D17.1 — PU-G-198 : après la touche g, le titre « Historique Git » a le focus ET un anneau visible (2 px, couleur --ring)" "$(jq_ "$R17" '[j.focus.sur, j.focus.style !== "none", j.focus.largeur, j.focus.couleur === j.focus.anneau].join("|")' 2>/dev/null)" "true|true|2px|true"
  assert_eq "D17.2 — PU-G-199 : la région « Détail du commit » est hors de toute liste, reliée par aria-controls à sa rangée seule ; les 40 options restent, aucun enfant de liste qui ne soit une option" "$(jq_ "$R17" '[j.detail.horsListe, j.detail.role, j.detail.relie, j.detail.options, j.detail.orphelins, j.detail.autres].join("|")' 2>/dev/null)" "true|region|true|40|0|0"
  assert_eq "D17.3 — PU-G-200 : noms courts « Copier la commande cd vers bisect-ci », « … pour voir le stash stash@{0} », jamais la commande entière" "$(jq_ "$R17" '[j.noms.includes("Copier la commande cd vers bisect-ci"), j.noms.includes("Copier la commande pour voir le stash stash@{0}"), j.noms.every((n) => !/--end-of-options|cd --/.test(n))].join("|")' 2>/dev/null)" "true|true|true"
  assert_eq "D17.4 — PU-G-200 (surface durcie) : un nom de branche hostile n'entre que dans l'aria-label (texte exact), aucun attribut ajouté, ni <img>, ni <script>, ni alerte" "$(jq_ "$R17" '[j.hostile.label === j.hostile.attendu, j.attributs, j.hostile.balises, j.hostile.alertes].join("|")' 2>/dev/null)" "true|true|0|0"
  assert_eq "D17.5 — PU-G-200 : la commande copiée est octet pour octet celle affichée (nom hostile compris), annoncée « Commande copiée » dans la région vive ; un refus s'annonce aussi" "$(jq_ "$R17" '[j.copie.spy === j.hostile.code, j.copie.live, j.refus].join("|")' 2>/dev/null)" "true|Commande copiée|Copie impossible, commande sélectionnée"
  assert_eq "D17.x — aucune erreur de page" "$(jq_ "$R17" 'j.errs.length' 2>/dev/null)" "0"
  for W in 1440 390; do # à 1440 px la seconde ligne est visible : le focus lui revient (témoin « comme à 1440 px ») ; à 390 px seul « Plus d'actions » l'est
    R17B="$(cdp "$AUX/d17b-complet.js" "$BASE" "$W")"; ATT="vf-git-ligne"; [ "$W" = 390 ] && ATT="vf-plus"
    assert_eq "D17.6 [$W px] — PU-G-201 : tiroir ouvert par son vrai chemin (seconde ligne dès 1000 px, menu « Plus d'actions » à 390 px), Échap le ferme et rend le focus à $ATT" "$(jq_ "$R17B" '[j.ouvert, j.ferme, j.focus].join("|")' 2>/dev/null)" "true|true|$ATT"
  done
  R17C="$(cdp "$AUX/d17c-complet.js" "$BASE")"
  [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$R17C" > "$TIROIR_TRACE-d17c.json"
  assert_eq "D17.7 — PU-G-191 : première lecture « indisponible » puis bon état : UNE relance automatique, les 40 rangées, aucune carte d'erreur" "$(jq_ "$R17C" '[j.relance.reqs, j.relance.carte, j.relance.busy === null].join("|")' 2>/dev/null)" "2|false|true"
  assert_eq "D17.8 — PU-G-191 : toujours « indisponible » : deux requêtes exactement (jamais de boucle), raison humaine « Git a mis trop de temps à répondre (machine chargée ?). Réessayer. »" "$(jq_ "$R17C" '[j.boucle.reqs, j.boucle.texte].join("|")' 2>/dev/null)" "2|Git a mis trop de temps à répondre (machine chargée ?). Réessayer."
  assert_eq "D17.9 — PU-G-191 : réponse hors schéma : même relance unique, raison distincte (« n'a pas abouti »)" "$(jq_ "$R17C" '[j.horsSchema.reqs, j.horsSchema.texte].join("|")' 2>/dev/null)" "2|La lecture du dépôt n'a pas abouti. Réessayer."
  assert_eq "D17.y — aucune erreur de page (relance)" "$(jq_ "$R17C" 'j.errs.length' 2>/dev/null)" "0"
  stop_srv
  # --- copies privées du module pour les mutants (build lit assets/ui/*.js) : chaque mutant a son propre lab et son propre serveur ---
  mkmod() { local d="$WORK/mod-$1"; mkdir -p "$d/scripts" "$d/skills"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/scripts/"; cp -R "$SCRIPTS/../skills/cockpit-moteur" "$d/skills/cockpit-moteur"; echo "$d/scripts"; }
  mutlab() { local L="$WORK/lab-$1"; mk_lab "$L"; [ "${2:-}" = nogit ] || { $GIT -C "$L" init -q -b main && $GIT -C "$L" add -A && $GIT -C "$L" commit -q -m init; }; echo "$L"; }
  mutant() { # mutant <nom> <fichier ui> <ancien> <nouveau> <scénario> [nogit] -> RM (une ligne JSON) ; une mutation impossible compte comme un échec
    local M L; M="$(mkmod "$1")"; L="$(mutlab "$1" "${6:-}")"
    if ! mutate "$M/../skills/cockpit-moteur/assets/ui/$2" "$3" "$4"; then echo "  ❌ FAIL — $1 : mutation impossible"; FAIL=$((FAIL+1)); RM="{}"; return; fi
    # MUT_AUX="fichier ui|ancien|nouveau" : seconde mutation sur un autre fichier (mutant à deux fichiers) ; elle aussi doit s'appliquer, sinon échec
    if [ -n "${MUT_AUX:-}" ]; then local af ao an; IFS='|' read -r af ao an <<EOF
$MUT_AUX
EOF
      if ! mutate "$M/../skills/cockpit-moteur/assets/ui/$af" "$ao" "$an"; then echo "  ❌ FAIL — $1 : mutation auxiliaire impossible"; FAIL=$((FAIL+1)); RM="{}"; return; fi
    fi
    build_serve "$L" "$M"; RM="$(cdp "$AUX/$5" "http://127.0.0.1:$PORT")"; stop_srv
    [ -n "${TIROIR_TRACE:-}" ] && printf '%s\n' "$RM" > "$TIROIR_TRACE-$1.json"
  }
  mutant M-HTML 77-vf-git-rendu.js "l1.appendChild(el('span', 'vf-git-msg', r.s));" "{ const m = el('span', 'vf-git-msg'); m.innerHTML = r.s; l1.appendChild(m); }" d2.js
  assert_eq "M-HTML — rougit D2.5 (un message rendu en HTML fait naître un <img>) alors que les 40 rangées sont là (pas une panne d'un autre ordre)" "$(jq_ "$RM" '[j.xss.img > 0, j.xss.lit.includes("false"), j.ouvert.rangees].join("|")' 2>/dev/null)" "true|true|40"
  mutant M-COPIE 77-vf-git-rendu.js "writeText(code.textContent)" "writeText(code.textContent.slice(0, -1))" d2.js
  assert_eq "M-COPIE — rougit D2.4 (le texte reçu par l'API n'est plus celui du <code>) alors que la copie a bien eu lieu" "$(jq_ "$RM" '[j.copie.spy === j.copie.affiche, typeof j.copie.spy, j.copie.retour].join("|")' 2>/dev/null)" "false|string|Copiée"
  mutant M-AJUSTEMENT ../viewer.html "else if (ev.key === 'f' || ev.key === 'F') fit(true);" "else if (ev.key === 'f' || ev.key === 'F') { }" d3a-complet.js
assert_eq "M-AJUSTEMENT — rougit D3.3 (la touche f ne fait rien : ni changement de k ni ajustement animé fit(true)) alors que + et - marchent" "$(jq_ "$RM" '[j.zoom.plus, j.zoom.moins, j.zoom.fit].join("|")' 2>/dev/null)" "true|true|false"
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
  mutant M-NONVERIFIE 77-vf-git-vue-detail.js "const nv = w.verifie === false || (etat && etat.verifie === false);" "const nv = false;" d11-complet.js
  assert_eq "M-NONVERIFIE — rougit D11.1 (l'état verifie === false est ignoré : pastille « état illisible » et pas de « non vérifié ») alors que le tiroir se charge et que le témoin positif D11.2 tient" "$(jq_ "$RM" '[j.wt[1].pastilles.join("/") === "non vérifié", j.wt[2].pastilles.join("/"), j.wt.length].join("|")' 2>/dev/null)" "false|1 modifié|3"
  mutant M-SEQ-WT 77-vf-git-vue-detail.js "if (moi !== seqWt) return null;" "/* mutant : aucune garde de séquence */" d12-complet.js
  assert_eq "M-SEQ-WT — rougit D12.4 (la réponse la plus ancienne écrase la plus récente : 3 modifiés) alors que les deux demandes sont parties" "$(jq_ "$RM" '[j.demandes, /9 modifiés/.test(j.pastilles), /3 modifiés/.test(j.pastilles)].join("|")' 2>/dev/null)" "2|false|true"
  mutant M-ANNONCE 77-vf-git-vue-detail.js "if (g.change || w.change) annoncer('Historique mis à jour');" "annoncer('Historique mis à jour');" d12-complet.js
  assert_eq "M-ANNONCE — rougit D12.1 (une relecture sans changement annonce quand même) alors que l'annonce d'un vrai changement (D12.2) est là" "$(jq_ "$RM" '[j.inchange.length > 0, j.change.length >= 1].join("|")' 2>/dev/null)" "true|true"
  mutant M-AVANCE-ZERO 77-vf-git-rendu.js "const avance = (a) => a == null ?" "const avance = (a) => (a = a || 0) == null ?" d13-complet.js
  assert_eq "M-AVANCE-ZERO — rougit D13.1 (le retour à « avance || 0 » affiche « 0 commit » pour un avance null) alors que les témoins positifs D13.2 tiennent" "$(jq_ "$RM" '[(j.branches.find((b) => b.nom === "feat/inconnue") || {}).txt, j.branches.map((b) => b.txt).join("/")].join("|")' 2>/dev/null)" "0 commit|0 commit/0 commit/3 commits"
  mutant M-ECHAPPEMENT 77-vf-git-vue-detail.js "bloc.appendChild(sp);" "if (tip && cls === 'vf-git-p-mono') sp.innerHTML = tip; bloc.appendChild(sp);" d16-complet.js
  assert_eq "M-ECHAPPEMENT — rougit D16.4 (le nom de base hostile rendu en HTML fait naître un <img>) alors que l'infobulle D16.3 et les états D16.1 tiennent" "$(jq_ "$RM" '[j.inerte.balises > 0, j.enCours.join("/") === "lecture…/lecture…/lecture…"].join("|")' 2>/dev/null)" "true|true"
  mutant M-AVANCE-WT 77-vf-git-vue-detail.js "const nb = (n) => (n == null ? '—' : n);" "const nb = (n) => (n || 0);" d13-complet.js
  assert_eq "M-AVANCE-WT — rougit D13.3 (la pastille d'un worktree à avance inconnue redit « ↑0 ») alors que les branches D13.1 tiennent" "$(jq_ "$RM" '[j.wt, (j.branches.find((b) => b.nom === "feat/inconnue") || {}).txt].join("|")' 2>/dev/null)" "↑0 ↓1|—"
  mutant M-ECHEC-DIT 77-vf-git-vue-detail.js $'echecDit = false;\n      if (g.change || w.change)' $'if (g.change || w.change)' d14-complet.js
  assert_eq "M-ECHEC-DIT — rougit D14.2 (le drapeau ne retombe plus au succès : le second échec n'est pas annoncé) alors que le premier échec (D14.1) l'est" "$(jq_ "$RM" '[j.echec1.length, j.succes.some((x) => /indisponible/.test(x)), j.echec2.length].join("|")' 2>/dev/null)" "1|false|0"
  VERT_GLOBAL="00-vibeflow.js|.vf-bar i { display: block; height: 100%; border-radius: 99px; background: var(--text-3); }|.vf-bar i { display: block; height: 100%; border-radius: 99px; background: var(--st-done); }"
  MUT_AUX="$VERT_GLOBAL" mutant M-BARRE-VERT 77-vf-git-tiroir.js "#vf-git-tiroir .vf-bar i { background: var(--text-3); }" "" d15-complet.js; MUT_AUX=
  assert_eq "M-BARRE-VERT — thème global recoloré au vert d'état ET règle du tiroir retirée : rougit D15.1 (la barre du tiroir prend le vert d'état) alors que la barre existe et que le vert d'état est distinct du neutre" "$(jq_ "$RM" '[j.barre.existe, j.barre.dans === j.barre.neutre, j.barre.dans === j.barre.vert, j.barre.neutre !== j.barre.vert].join("|")' 2>/dev/null)" "true|false|true|true"
  # preuve que la règle du tiroir porte la charge : thème global recoloré SEUL (règle du tiroir intacte) -> la barre du tiroir reste neutre alors que la même classe hors du tiroir est bien devenue verte (témoin que le mutant global est effectif)
  MUT_AUX="$VERT_GLOBAL" mutant M-BARRE-THEME-SEUL 77-vf-git-tiroir.js "#vf-git-tiroir .vf-bar i { background: var(--text-3); }" "#vf-git-tiroir .vf-bar i { background: var(--text-3); }" d15-complet.js; MUT_AUX=
  assert_eq "M-BARRE-THEME-SEUL — thème global recoloré au vert d'état, règle du tiroir intacte : D15.1 reste verte (barre du tiroir neutre) pendant que la même classe hors du tiroir est devenue verte (la règle du tiroir porte la charge)" "$(jq_ "$RM" '[j.barre.existe, j.barre.dans === j.barre.neutre, j.barre.hors === j.barre.vert, j.barre.hors !== j.barre.neutre].join("|")' 2>/dev/null)" "true|true|true|true"
  mutant M-CONTRASTE-SANS 77-vf-git-tiroir.js ".vf-git-sans { font-size: 11.5px; color: var(--text-2); }" ".vf-git-sans { font-size: 11.5px; color: var(--text-4); }" d15-complet.js
  assert_eq "M-CONTRASTE-SANS — rougit D15.2 sur « Aucune commande proposée » seule (sous 4,5:1) alors que les pilules et le kbd tiennent" "$(jq_ "$RM" '[j.sombre.sans < 4.5, j.sombre.meta >= 4.5, j.sombre.kbd >= 4.5].join("|")' 2>/dev/null)" "true|true|true"
  mutant M-LIVE-DOUBLE 77-vf-git-vue-detail.js "let l = tiroir && tiroir.querySelector('.vf-git-live');" "let l = tiroir && tiroir.querySelector('.vf-git-live-det'); if (!l && tiroir) { l = el('div', 'vf-git-live vf-git-live-det', null, { 'aria-live': 'polite' }); tiroir.appendChild(l); }" d15-complet.js
  assert_eq "M-LIVE-DOUBLE — rougit D15.4 (deux régions vives, deux régions distinctes pour les deux annonces) alors que chaque copie est annoncée" "$(jq_ "$RM" '[j.regions, j.copies.length, new Set(j.copies.map((c) => c[0])).size].join("|")' 2>/dev/null)" "2|2|2"
  mutant M-COCHE 77-vf-git-rendu.js "dire('Copiée', true);" "dire('Copiée');" d15-complet.js
  assert_eq "M-COCHE — rougit D15.5 (l'icône reste celle de la copie pendant le « Copiée ») alors que le retour textuel est là" "$(jq_ "$RM" '[j.iconeCoche === j.iconeAvant, j.retour].join("|")' 2>/dev/null)" "true|Copiée"
  mutant M-FOCUS-198 77-vf-git-tiroir.js ".vf-git-titre-t:focus-visible { outline: 2px solid var(--ring);" ".vf-git-titre-t:focus-visible { outline: none;" d17a-complet.js
  assert_eq "M-FOCUS-198 — rougit D17.1 (le titre a le focus mais plus d'anneau) alors que le focus est bien posé" "$(jq_ "$RM" '[j.focus.sur, j.focus.style === "none"].join("|")' 2>/dev/null)" "true|true"
  mutant M-DETAIL-LISTE 77-vf-git-vue-detail.js "li.appendChild(zone); ol.after(li);" "li.appendChild(zone); ligne.after(li);" d17a-complet.js
  assert_eq "M-DETAIL-LISTE — rougit D17.2 (le détail revient dans la liste) alors que la région reste reliée par aria-controls" "$(jq_ "$RM" '[j.detail.horsListe, j.detail.relie].join("|")' 2>/dev/null)" "false|true"
  mutant M-LABEL-HTML 77-vf-git-rendu.js "const b = el('button', 'vf-git-btn', null, { type: 'button', 'aria-label': 'Copier la commande' + (nom ? ' ' + nom : '') });" "const b = (() => { const h = document.createElement('div'); h.innerHTML = '<button class=\"vf-git-btn\" type=\"button\" aria-label=\"Copier la commande' + (nom ? ' ' + nom : '') + '\"></button>'; return h.firstChild; })();" d17a-complet.js
  assert_eq "M-LABEL-HTML — rougit D17.4 (le nom hostile écrit en HTML casse l'aria-label et ajoute des attributs) alors que les boutons existent et que la copie D17.5 fonctionne" "$(jq_ "$RM" '[j.hostile.label === j.hostile.attendu, j.attributs, j.copie.spy === j.hostile.code].join("|")' 2>/dev/null)" "false|false|true"
  mutant M-ECHAP-390 77-vf-git-tiroir.js ".some((d) => getComputedStyle(d).visibility !== 'hidden')" ".some(() => true)" d17b-complet.js
  assert_eq "M-ECHAP-390 — rougit D17.6 (le panneau fermé du téléphone, role=dialog invisible, bloque Échap : le tiroir reste ouvert, le focus part sur le corps) alors que le tiroir s'ouvre" "$(jq_ "$RM" '[j.ouvert, j.ferme, j.focus].join("|")' 2>/dev/null)" "true|false|"
  mutant M-BULLE-ECHAP 77-vf-git-rendu.js "if (ev.key === 'Escape' && bulle && !bulle.hidden && ancre === e) {" "if (false) {" d18-complet.js
  assert_eq "M-BULLE-ECHAP — rougit D18.2 (la bulle n'a plus son Échap : le premier Échap atteint le tiroir et le ferme, la bulle disparaît avec lui) alors que la bulle s'était bien ouverte (D18.1)" "$(jq_ "$RM" '[!!j.detache.bulle && j.detache.bulle.vu, j.detache.apresEchap.bulle === null, j.detache.apresEchap.tiroir].join("|")' 2>/dev/null)" "true|true|false"
  mutant M-BULLE-FOCUS 77-vf-git-rendu.js "if (clavier || e.matches(':focus-visible')) montrer(e, typeof texte === 'function' ? texte() : texte);" "void 0;" d18-complet.js
  assert_eq "M-BULLE-FOCUS — rougit D18.1 et D18.3 (le focus clavier ne montre plus rien : retour au title seul) alors que les éléments sont atteignables par Tab" "$(jq_ "$RM" '[j.detache.atteignable.tab, j.detache.bulle === null, j.worktrees === null, j.h1 === null].join("|")' 2>/dev/null)" "0|true|true|true"
  mutant M-RELANCE 77-vf-git-tiroir.js "if (relance !== true && (!j ||" "if (false && (!j ||" d17c-complet.js
  assert_eq "M-RELANCE — rougit D17.7 (plus de relance : une requête, la carte d'erreur au premier « indisponible ») alors que le bon état aurait été servi à la seconde" "$(jq_ "$RM" '[j.relance.reqs, j.relance.carte].join("|")' 2>/dev/null)" "1|true"
fi

echo "=== D10 — correction design de la critique fraîche (78-10 : F2, F12, F14, F15) ==="
if [ -z "$CHROME" ]; then skip "D10" "pas de navigateur"; else
  build_serve "$DEPOT"; BASE="http://127.0.0.1:$PORT"
  # rangée de tête : HEAD, une branche très longue, un message long ; mesures à largeur donnée (le tiroir est ouvert par l'API de la page, l'ouvreur dépend de la largeur)
  cat > "$AUX/d10-refs.js" <<'JS'
const [base, w] = ARGS;
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: Number(w), height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`document.readyState === 'complete' && !!window.VFGitTiroir`, 'tiroir prêt');
await s.ev(`(() => { const r = window.__vfGit.reponse.rangees[0]; r.refs[1].nom = 'feature/' + 'x'.repeat(70); r.s = 'Un message de commit assez long pour mesurer le recouvrement des étiquettes'; })()`);
await s.ev(`window.VFGitTiroir.ouvrir()`);
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length > 0`, 'rangées');
return await s.stable(`(() => { const l1 = document.querySelector('.vf-git-rangee .vf-git-l1'), L = l1.getBoundingClientRect(), m = l1.querySelector('.vf-git-msg').getBoundingClientRect();
  return { l1: [L.left, L.right], msg: [m.left, m.right], refs: [...l1.querySelectorAll('.vf-git-ref')].map((e) => { const t = e.querySelector('.vf-git-ref-t') || e, r = e.getBoundingClientRect();
    return { txt: e.textContent, interne: !!e.querySelector('.vf-git-ref-t'), coupe: t.scrollWidth > t.clientWidth + 0.5, ell: getComputedStyle(t).textOverflow, left: r.left, right: r.right }; }) }; })()`, 'rangée de tête');
JS
  for W in 1440 999 390; do
    R="$(cdp "$AUX/d10-refs.js" "$BASE" "$W")"
    assert_eq "D10.1 [$W px] — HEAD toujours entier : texte « HEAD », jamais coupé" "$(jq_ "$R" '[j.refs[0].txt, j.refs[0].coupe].join("|")' 2>/dev/null)" "HEAD|false"
    assert_eq "D10.1 [$W px] — le nom de branche est tronqué avec « … » dans un span interne" "$(jq_ "$R" '[j.refs[1].interne, j.refs[1].coupe, j.refs[1].ell].join("|")' 2>/dev/null)" "true|true|ellipsis"
    assert_eq "D10.1 [$W px] — le message n'est recouvert par aucune étiquette et les étiquettes restent dans la ligne" "$(jq_ "$R" 'j.refs.filter((e) => e.right > j.msg[0] + 0.5 || e.right > j.l1[1] + 0.5).length' 2>/dev/null)" "0"
  done
  # sections dépliées, stash entier, glyphes muets, tailles et graisses
  cat > "$AUX/d10-sec.js" <<'JS'
const [base, w] = ARGS;
await s.naviguer(base + '/');
await s.send('Emulation.setDeviceMetricsOverride', { width: Number(w), height: 900, deviceScaleFactor: 1, mobile: false });
await s.attendre(`document.readyState === 'complete' && !!window.VFGitTiroir`, 'tiroir prêt');
await s.send('Accessibility.enable');
await s.ev(`(() => { const st = window.__vfGit.reponse.stash; st[0].message = 'Un message de remisage assez long pour pousser la rangée'; st[0].branche = 'feature/' + 'y'.repeat(40); })()`); // rangée de stash chargée : l'identifiant ne doit jamais céder la place
await s.ev(`window.VFGitTiroir.ouvrir()`);
await s.attendre(`document.querySelectorAll('#vf-git-tiroir li[role=option]').length > 0 && !!document.querySelector('#vf-git-s-stash')`, 'rangées et sections');
await s.ev(`document.querySelectorAll('.vf-git-sec-t[aria-expanded="false"]').forEach((b) => b.click()); document.querySelectorAll('.vf-git-merg-b[aria-expanded="false"]').forEach((b) => b.click())`);
await s.attendre(`!!document.querySelector('.vf-git-pastille')`, 'pastilles des worktrees');
await s.ev(`document.querySelectorAll('.vf-git-rangee')[2].click()`);
await s.attendre(`!!document.querySelector('.vf-git-det .vf-git-d-fichiers')`, 'détail ouvert');
const out = {};
out.sous = await s.ev(`[...document.querySelectorAll('.vf-git-sous')].map((e) => e.textContent)`); // P78-D-40
out.stash = await s.stable(`[...document.querySelectorAll('.vf-git-st .vf-git-gras')].map((e) => ({ txt: e.textContent, coupe: e.scrollWidth > e.clientWidth + 0.5 }))`, 'stash');
const tout = `(() => { const S = new Set(), W = new Set(); const hors = [];
  for (const e of document.querySelectorAll('#vf-git-tiroir *')) {
    if (e.closest('.vf-git-live') || !e.getClientRects().length) continue;
    const direct = [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim());
    if (!direct) continue;
    const c = getComputedStyle(e); S.add(c.fontSize); W.add(c.fontWeight); }
  return { tailles: [...S].sort(), graisses: [...W].sort() }; })()`;
out.styles = await s.ev(tout);
// glyphes d'état : l'arbre d'accessibilité ne doit contenir aucun texte ✓ ◐ ○ et garder les mots
const ax = await s.send('Accessibility.getFullAXTree');
const noms = (ax.nodes || []).filter((n) => n.role && n.role.value === 'StaticText').map((n) => String((n.name && n.name.value) || ''));
out.axGlyphes = noms.filter((t) => /[✓◐○]/.test(t));
out.axMots = ['propre', 'modifié', 'non suivi'].map((m) => noms.some((t) => t.includes(m)));
out.contenus = await s.ev(`['vf-git-p-ok', 'vf-git-p-warn', 'vf-git-p-nonsuivi'].map((c) => { const e = document.querySelector('.' + c); return e ? getComputedStyle(e, '::before').content : null; })`);
// état indisponible : mêmes tailles et graisses (bouton « Réessayer » compris)
await s.ev(`window.__vfGit.reponse = { schema: 'autre@1', etat: 'ok', rangees: [] }; window.VFGitTiroir.recharger()`);
await s.attendre(`/Git est indisponible/.test(document.querySelector('#vf-git-tiroir').textContent)`, 'carte indisponible');
const apres = await s.ev(tout);
out.indispo = apres;
return out;
JS
  for W in 1440 390; do
    R="$(cdp "$AUX/d10-sec.js" "$BASE" "$W")"
    assert_eq "D10.5 [$W px] — P78-D-40 : le sous-titre de la section Auteurs dit « Par branche — avance sur la base » (aucune fenêtre de 30 jours)" "$(jq_ "$R" 'j.sous.join("|")' 2>/dev/null)" "Par branche — avance sur la base"
    assert_eq "D10.2 [$W px] — l'identifiant du stash est toujours entier (stash@{0}, stash@{1}), jamais coupé" "$(jq_ "$R" 'j.stash.map((e) => e.txt + ":" + e.coupe).join(",")' 2>/dev/null)" "stash@{0}:false,stash@{1}:false"
    assert_eq "D10.3 [$W px] — glyphes ✓ ◐ ○ : texte alternatif vide (content: '…' / '') pour les trois" "$(jq_ "$R" 'j.contenus.map((c) => / \/ ""$/.test(c || "") ? "vide" : String(c)).join(",")' 2>/dev/null)" "vide,vide,vide"
    assert_eq "D10.3 [$W px] — arbre d'accessibilité : aucun glyphe ✓ ◐ ○ lu, les mots propre, modifié, non suivi restent" "$(jq_ "$R" '[j.axGlyphes.length, j.axMots.join(",")].join("|")' 2>/dev/null)" "0|true,true,true"
    assert_eq "D10.4 [$W px] — quatre tailles de police au plus, toutes dans {11.5, 12.5, 13, 15} (liste + indisponible)" "$(jq_ "$R" '[...new Set([...j.styles.tailles, ...j.indispo.tailles])].filter((t) => ["11.5px", "12.5px", "13px", "15px"].indexOf(t) < 0).join(",") || "ok"' 2>/dev/null)" "ok"
    assert_eq "D10.4 [$W px] — deux graisses au plus (liste + indisponible)" "$(jq_ "$R" '[...new Set([...j.styles.graisses, ...j.indispo.graisses])].length <= 2 ? "ok" : [...new Set([...j.styles.graisses, ...j.indispo.graisses])].join(",")' 2>/dev/null)" "ok"
  done
  stop_srv
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
