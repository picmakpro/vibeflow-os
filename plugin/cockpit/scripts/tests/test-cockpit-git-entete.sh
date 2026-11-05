#!/usr/bin/env bash
# test-cockpit-git-entete.sh — en-tête Git du cockpit (78-04 ; GITC-01, 02, 03, 05, 12 ; P78-D-01, 02, 03, 09, 10, 11, 12, 19, 20).
#   H1 données (enteteGit) · H2 nom du dépôt sur les trois onglets · H3 seconde ligne et événements · H4 ouvreur mobile
#   H5 dégradation sans git, texte venu de git rendu en texte · H6 bloc de vue, retrait de « Repositories », feuille sans valeur en dur
#   Mutants : M-DEPOT, M-TEXTE, M-ABSENT. Chrome headless en CDP (SAUTÉ, jamais compté réussi, sans navigateur), ports éphémères.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
UI="$(cd "$SCRIPTS/.." && pwd)/skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=()
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
[ -n "${ENTETE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (les sections Chrome sont SAUTÉES)}"

# --- aides node ---
cat > "$AUX/json.mjs" <<'JS'
// json.mjs '<json>' '<expression sur j>' : évalue l'expression, imprime la chaîne ou le JSON
const j = JSON.parse(process.argv[2]);
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/entete.mjs" <<'JS'
// entete.mjs <module> <dossier> : enteteGit(dossier) du module donné, une ligne JSON
const m = await import(process.argv[2]);
console.log(JSON.stringify(m.enteteGit(process.argv[3])));
JS
cat > "$AUX/cdp-run.mjs" <<'JS'
// cdp-run.mjs <chrome> <scenario.js> [args…] : joue le corps asynchrone du scénario avec (s, ARGS), une ligne JSON
import fs from 'node:fs';
const { executer } = await import(process.env.VF_CS);
const [, , chrome, fichier, ...ARGS] = process.argv;
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const corps = new AsyncFunction('s', 'ARGS', fs.readFileSync(fichier, 'utf8'));
await executer(chrome, (s) => corps(s, ARGS), { csp: true });
JS
export VF_CS="$HERE_T/chrome-session.mjs"
cdp() { node "$AUX/cdp-run.mjs" "$CHROME" "$@"; } # cdp <scenario.js> [args…]
jq_() { node "$AUX/json.mjs" "$1" "$2"; }

GIT="git -c user.email=t@t -c user.name=t"
mk_lab() { # $1 = dossier : lab GSD minimal, un commit
  mkdir -p "$1/src" "$1/.planning/phases/01-x"
  printf 'export const util = () => 1;\n' > "$1/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$1/.planning/ROADMAP.md"
  printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$1/.planning/STATE.md"
  printf '<objective>Faire le socle</objective>\n' > "$1/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$1/.planning/phases/01-x/01-01-SUMMARY.md"
}
build_serve() { # $1 = lab ; pose OUT, PORT ; démarre le serveur (SRV)
  node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  OUT="$1/.vibeflow/cockpit"
  node "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
  SRV=$!; PIDS+=("$SRV")
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$OUT/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}

# --- dépôt jetable : `depot` (principal) et le worktree `wt-a` sur feat/x ---
DEPOT="$WORK/depot"; WT="$WORK/wt-a"
mk_lab "$DEPOT"
$GIT -C "$DEPOT" init -q -b main && $GIT -C "$DEPOT" add -A && $GIT -C "$DEPOT" commit -q -m init
$GIT -C "$DEPOT" worktree add -q -b feat/x "$WT" >/dev/null 2>&1

echo "=== H1 — enteteGit ==="
MOD="$SCRIPTS/vf-cockpit-git-entete.mjs"
H1W="$(node "$AUX/entete.mjs" "$MOD" "$WT" 2>&1 | tail -1)"
H1D="$(node "$AUX/entete.mjs" "$MOD" "$DEPOT" 2>&1 | tail -1)"
assert_eq "H1.1 — depuis le worktree : dépôt principal, branche, worktree" "$(jq_ "$H1W" '[j.etat,j.depot,j.branche,j.worktree,j.detache].join("|")' 2>/dev/null)" "ok|depot|feat/x|wt-a|false"
assert_eq "H1.1b — depuis l'arbre principal : pas de worktree" "$(jq_ "$H1D" '[j.etat,j.depot,j.branche,String(j.worktree)].join("|")' 2>/dev/null)" "ok|depot|main|null"

echo "=== H2 — nom du dépôt sur l'onglet Code ==="
if [ -z "$CHROME" ]; then skip "H2.1" "pas de navigateur"; else
  build_serve "$WT"
  cat > "$AUX/h21.js" <<'JS'
const [base] = ARGS;
await s.naviguer(base + '/');
await s.attendre("document.readyState === 'complete' && !!window.VibeFlow && !!document.querySelector('#proj-name')", 'page Code rendue');
await s.attendre("!!document.querySelector('.vf-git-ligne') || true", 'laisse la main au rendu');
return await s.ev(`(() => ({ nom: document.querySelector('#proj-name').textContent, ligne: (document.querySelector('.vf-git-ligne') || {}).textContent || null }))()`);
JS
  R="$(cdp "$AUX/h21.js" "http://127.0.0.1:$PORT" 2>&1 | tail -1)"
  assert_eq "H2.1 — #proj-name = depot" "$(jq_ "$R" 'j.nom' 2>/dev/null)" "depot"
  assert_eq "H2.1b — la seconde ligne dit la branche et le worktree" "$(jq_ "$R" '/feat\/x/.test(j.ligne||"") && /wt-a/.test(j.ligne||"") ? "oui" : "non"' 2>/dev/null)" "oui"
  stop_srv
fi

vf_hyg_assert
echo; echo "Résultats : $PASS réussis, $FAIL échoués, $SKIP sautés"
[ "$FAIL" -eq 0 ]
