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
build_serve() { # $1 = lab, $2 = dossier de scripts (défaut : le module) ; pose OUT, PORT ; démarre le serveur (SRV)
  env $ENVX "$NODE" "${2:-$SCRIPTS}/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
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
window.__errs = []; window.__vfReqs = [];
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
  stop_srv
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
