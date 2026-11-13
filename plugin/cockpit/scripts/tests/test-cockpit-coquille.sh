#!/usr/bin/env bash
# test-cockpit-coquille.sh — la coquille statique du cockpit (79-16, SOCL-20 ; C5, A1 à A3, A30, A37, A40, A41, A48, A51, A53, A55).
#   K0 témoins · K1 document aux quatre adresses · K2 fichiers de /_vf/ (table fermée, ETag, 304, lien) · K3 CSP · K4 E9 (fichier planté) · K5 service retiré
#   K6 module servi = module lancé · A37 gardes de chemin · C1 à C8 navigateur (onglet rendu, adresses, chargerOnglet, surOnglet, persistants, classe, terminal, échec)
#   P aide de mutation de page · M-* mutants (copies du module par cockpit_module_muter, jamais le module du dépôt)
# Lab neutre dans mktemp, HOME jetable, isolation git. Le code testé est celui du dossier de cette suite. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"; MOD="$(cd "$SCRIPTS/.." && pwd -P)"; ENG="$MOD/skills/cockpit-moteur"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [${3:0:300}]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     sous-chaîne interdite présente: [$3]"; FAIL=$((FAIL+1)); fi; }
TA="$TESTS/terminal-aux.mjs"; OR="$TESTS/coquille-oracle.mjs"; CH="$TESTS/coquille-chrome.mjs"

# --- aides ---
oj() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let j;try{j=JSON.parse(s)}catch{console.log("illisible");return}const v=new Function("j","return ("+process.argv[1]+")")(j);console.log(typeof v==="string"?v:JSON.stringify(v))})' "$1"; }
rq() { # rq <METHODE> <chemin> <fichier-corps> [options de terminal-aux req] -> RQ_CODE, RQ_H (en-têtes JSON), corps dans le fichier
  local m="$1" p="$2" f="$3"; shift 3
  node "$TA" req "${PORT:-0}" "$m" "$p" --corps-vers "$f" "$@" > "$WORK/rq.out" 2>&1
  RQ_CODE="$(sed -n 1p "$WORK/rq.out")"; RQ_H="$(sed -n 2p "$WORK/rq.out")"
}
hv() { printf '%s' "$RQ_H" | oj "j[\"$1\"]||\"\""; } # valeur d'un en-tête de la dernière réponse (nom en minuscules)
taille() { wc -c < "$1" | tr -d ' '; }
mklab() { # lab neutre : phases 1 (faite) et 2 (marqueur), un plan, une mission, un dépôt dont le remote porte un marqueur
  local L="$1"; mkdir -p "$L/src" "$L/.planning/phases/01-x" "$L/.planning/missions"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf 'export const m = 2;\n' > "$L/src/MQ16-fichier.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: MQ16-PHASE** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$L/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  printf '{"nodes":[{"id":"a","step":"un","deps":[],"status":"running"},{"id":"b","step":"deux","deps":["a"],"status":"ready"}]}\n' > "$L/.planning/missions/MISSION-1-x.dag.json"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  git -C "$L" remote add origin "https://example.invalid/MQ16-REMOTE/depot.git"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; }
}
demarrer() { cockpit_lancer "$@"; RL=$?; PORT="${VF_PORT:-0}"; }
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
REAL_HOME="$HOME"; REAL_HOME="$(node -e 'console.log(require("os").userInfo().homedir)')"
chrome() { REAL_HOME="$REAL_HOME" node "$CH" "$CHROME" "$@"; } # chrome <mode> <args…>

echo "=== K0 — témoins : serveur, sortie assemblée, marqueurs du lab ==="
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
demarrer "$LAB"
assert_eq "K0.1 — témoin : le serveur est prêt" "$RL|$([ "$PORT" -gt 0 ] && echo oui || echo non)" "0|oui"
assert_eq "K0.2 — témoin de présence : la sortie contient index.html, project.html (marqueur de phase) et graph.json (marqueur de remote)" "$(for f in index.html project.html graph.json; do [ -s "$OUT/$f" ] && echo oui || echo non; done | tr '\n' ' ')$(node "$OR" marque "$OUT/project.html" MQ16-PHASE) $(node "$OR" marque "$OUT/graph.json" MQ16-REMOTE)" "oui oui oui oui oui"
assert_eq "K0.3 — témoin : le chemin du lab est dans graph.json (meta.root)" "$(node "$OR" marque "$OUT/graph.json" "$LAB")" "oui"

echo "=== K1 — le document : composé du module, sans donnée du lab ==="
rq GET /project.html "$WORK/doc-p.html"; K1CODE="$RQ_CODE"; K1CT="$(hv content-type)"; K1CC="$(hv cache-control)"; K1CL="$(hv content-length)"; K1CSP="$(hv content-security-policy)"
TP="$(taille "$WORK/doc-p.html")"
assert_eq "K1.1 — /project.html : 200, text/html, no-store, Content-Length exact, entre 100 000 et 700 000 octets, un seul bloc de manifeste, aucun marqueur du lab ni son chemin" "$K1CODE|$K1CT|$K1CC|$([ "$K1CL" = "$TP" ] && echo exact || echo "$K1CL/$TP")|$([ "$TP" -ge 100000 ] && [ "$TP" -le 700000 ] && echo borne || echo "hors:$TP")|$(node "$OR" manifeste "$WORK/doc-p.html" | oj 'j.erreur||"un"')|$(node "$OR" marque "$WORK/doc-p.html" MQ16-PHASE)|$(node "$OR" marque "$WORK/doc-p.html" MQ16-fichier)|$(node "$OR" marque "$WORK/doc-p.html" "$LAB")" "200|text/html; charset=utf-8|no-store|exact|borne|un|non|non|non"

echo "=== K2 — les fichiers de /_vf/ : étiquette forte, 304 ==="
UIN="$(ls "$ENG/assets/ui" | grep -c '\.js$')"
node "$OR" manifeste "$WORK/doc-p.html" > "$WORK/man.json"
assert_eq "K2.1 — le manifeste nomme coquille-portee.js, coquille.js, moteur.js, graph-query.js, vendor/elk.bundled.js et une entrée par fichier de ui/ du module" "$(oj 'j.noms?(["coquille-portee.js","coquille.js","moteur.js","graph-query.js","vendor/elk.bundled.js"].every((n)=>j.noms.includes(n))&&j.noms.filter((n)=>n.startsWith("ui/")).length):"pas de manifeste"' < "$WORK/man.json")" "$UIN"
assert_has "K2.1 — chaque fichier du manifeste : 200, JavaScript, étiquette = sha256 des octets reçus, no-cache" "$(node "$OR" assets "$PORT" "$WORK/doc-p.html")" "ok "
assert_eq "K2.2 — If-None-Match : égale, faible, liste, * → 304 sans corps avec l'étiquette ; une autre étiquette → 200" "$(node "$OR" inm "$PORT" moteur.js)" "ok"

echo "=== K3 — la CSP : empreintes des scripts en ligne et une seule source, le préfixe ==="
node "$OR" csp "$WORK/doc-p.html" "$K1CSP" "http://127.0.0.1:$PORT/_vf/" > "$WORK/csp.json"
assert_eq "K3.1 — empreintes de script-src = celles des scripts en ligne du corps servi ; une seule autre source, http://127.0.0.1:<port>/_vf/ ; valeur servie = valeur reconstruite" "$(oj '[j.egales,JSON.stringify(j.autres),j.servi===j.attendu].join("|")' < "$WORK/csp.json")" "true|[\"http://127.0.0.1:$PORT/_vf/\"]|true"
assert_eq "K3.1 — script-src sans 'self', sans 'unsafe-', sans *" "$(oj '/\x27self\x27|unsafe-|\*/.test(j.servi)?"interdit":"propre"' < "$WORK/csp.json")" "propre"
cat > "$AUX/ligne.mjs" <<'JS'
// ligne.mjs <serve.mjs> : la ligne « const csp = » du serveur égale la copie figée de v2.75.0 avec la seule insertion de la source du préfixe
import fs from 'node:fs'; import { execFileSync } from 'node:child_process';
const [, , serve, aux] = process.argv;
const ancien = "  const csp = `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'`;";
const ligne = fs.readFileSync(serve, 'utf8').split('\n').find((x) => x.startsWith('  const csp = ')) || '';
const attendu = ancien.replace(".join(' ')}; style-src", ".join(' ')} ${source}; style-src");
const figee = execFileSync('node', [aux, 'ligne-csp-v275'], { encoding: 'utf8' }).trimEnd();
console.log([ligne === attendu ? 'serveur' : 'serveur-different', figee === attendu ? 'figee' : 'figee-differente'].join(' '));
JS
assert_eq "K3.3 — la ligne « const csp = » de serve.mjs ne diffère de la copie de v2.75.0 que par la source du préfixe, et terminal-aux en porte la copie figée neuve" "$(node "$AUX/ligne.mjs" "$ENG/assets/serve.mjs" "$TA")" "serveur figee"

echo "=== C1 — l'onglet Projet rendu dans le navigateur depuis le document ==="
if [ -z "$CHROME" ]; then . "$TESTS/chrome-saut.sh"; vf_chrome_saut "  ⊘ C SAUTÉ : aucun navigateur (Chrome, Chromium) — la moitié navigateur de la coquille NON vérifiée"
else
  rq GET "/api/vf/graphe?onglet=projet" "$WORK/route-p.json" --jeton "$(node "$OR" jetons "$WORK/doc-p.html" | oj 'j.token')"
  NP="$(oj 'j.nodes.length' < "$WORK/route-p.json")"
  chrome charger "http://127.0.0.1:$PORT/project.html" "http://127.0.0.1:$PORT/project.html" > "$WORK/c1.json"
  assert_eq "C1.1 — le moteur est rendu depuis le document : vfTab project, mise en page posée, autant de nœuds que la route" "$(oj '[j.res?.[0]?.tab,j.res?.[0]?.layout,j.res?.[0]?.noeuds]' < "$WORK/c1.json")" "[\"project\",true,$NP]"
  assert_eq "C1.2 — aucune violation de CSP, aucune erreur de page, onglet() = projet, data-vf-pret = oui" "$(oj '[j.res?.[0]?.violations.length,j.res?.[0]?.erreursPage.length,j.res?.[0]?.onglet,j.res?.[0]?.pret]' < "$WORK/c1.json")" "[0,0,\"projet\",\"oui\"]"
  assert_eq "C1.3 — au second chargement, au moins un fichier de /_vf/ est revalidé en 304" "$(oj 'j.res?.[1]?.reponses.some((r)=>r.statut===304)' < "$WORK/c1.json")" "true"
fi

# FIN
cockpit_arreter
vf_hyg_assert
echo ""; echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
