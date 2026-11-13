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
chrome() { local m="$1"; shift; REAL_HOME="$REAL_HOME" node "$CH" "$m" "$CHROME" "$@"; } # chrome <mode> <args…>
# état de départ de la boucle de serveurs : serveur de base (module du dépôt) sur le lab
base_srv() { cockpit_arreter; unset COCKPIT_MODULE; demarrer "$LAB"; }
v_service() { local u r=""; for u in /graph.json /lien-interne.json /plante.js /creds.txt /.cache/server.json; do rq GET "$u" "$WORK/x.out"; r="$r$RQ_CODE "; done; printf '%s' "$r"; }
v_csp() { rq GET /project.html "$WORK/x.out"; printf '%s' "$(hv content-security-policy)" | sed -n 's|.*script-src \([^;]*\);.*|\1|p' | grep -c "'self'\|unsafe-\|\*\|blob:\|data:" | sed 's/^0$/propre/;s/^[1-9].*$/interdit/'; }



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
// ligne.mjs <serve.mjs> : la ligne « const csp = » du serveur égale la copie figée de v2.75.0 avec les deux seules insertions (source du préfixe, directive de worker)
import fs from 'node:fs'; import { execFileSync } from 'node:child_process';
const [, , serve, aux] = process.argv;
const ancien = "  const csp = `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'`;";
const ligne = fs.readFileSync(serve, 'utf8').split('\n').find((x) => x.startsWith('  const csp = ')) || '';
const attendu = ancien.replace(".join(' ')}; style-src", ".join(' ')} ${source}; ${worker}; style-src"); // les DEUX insertions de la phase : la source du préfixe (79-16) et le worker (79-18)
const figee = execFileSync('node', [aux, 'ligne-csp-v275'], { encoding: 'utf8' }).trimEnd();
console.log([ligne === attendu ? 'serveur' : 'serveur-different', figee === attendu ? 'figee' : 'figee-differente'].join(' '));
JS
assert_eq "K3.3 — la ligne « const csp = » de serve.mjs ne diffère de la copie de v2.75.0 que par la source du préfixe et la directive de worker (deux insertions exactes), et terminal-aux en porte la copie figée neuve" "$(node "$AUX/ligne.mjs" "$ENG/assets/serve.mjs" "$TA")" "serveur figee"

echo "=== K1 (suite) — les quatre adresses, les méthodes, les jetons ==="
rq GET / "$WORK/doc-r.html"; rq GET /index.html "$WORK/doc-i.html"; rq GET /equipe.html "$WORK/doc-e.html"; rq GET /project.html "$WORK/doc-p.html"
assert_eq "K1.1 — les quatre adresses rendent les mêmes octets une fois retirés le <title> et le script de jeton" "$(node "$OR" memes "$WORK/doc-r.html" "$WORK/doc-i.html" "$WORK/doc-p.html" "$WORK/doc-e.html")" "oui"
assert_eq "K1.1 — chaque adresse porte le titre de son onglet" "$(for f in r i p e; do node "$OR" titre "$WORK/doc-$f.html"; done | tr '\n' '|')" "VibeFlow · Code|VibeFlow · Code|VibeFlow · Projet|VibeFlow · Équipe|"
TOKC="$(node "$OR" jetons "$WORK/doc-r.html" | oj 'j.token')"; TOKP="$(node "$OR" jetons "$WORK/doc-p.html" | oj 'j.token')"
assert_eq "K1.1 — le champ token est la première clé : jeton Code pour /, /index.html et /equipe.html, jeton Projet pour /project.html, deux jetons distincts" "$(for f in r i e p; do node "$OR" jetons "$WORK/doc-$f.html" | oj 'j.premiere'; done | tr '\n' ' ')$([ "$TOKC" != "$TOKP" ] && [ "${#TOKC}" -ge 16 ] && [ "$(node "$OR" jetons "$WORK/doc-i.html" | oj 'j.token')" = "$TOKC" ] && [ "$(node "$OR" jetons "$WORK/doc-e.html" | oj 'j.token')" = "$TOKC" ] && echo oui || echo non)" "true true true true oui"
rq GET /project.html "$WORK/doc-p.html"
assert_eq "K1.2 — en-têtes : no-store, nosniff, DENY, CSP présente" "$(hv cache-control)|$(hv x-content-type-options)|$(hv x-frame-options)|$([ -n "$(hv content-security-policy)" ] && echo csp)" "no-store|nosniff|DENY|csp"
rq HEAD /project.html "$WORK/head.out"; HC="$(hv content-length)"; HT="$(hv content-type)"
assert_eq "K1.3 — HEAD : 200, mêmes en-têtes, corps vide ; POST, PUT, DELETE : 405" "$RQ_CODE|$HC|$HT|$(taille "$WORK/head.out")|$(for m in POST PUT DELETE; do rq "$m" /project.html "$WORK/m.out"; printf '%s ' "$RQ_CODE"; done)" "200|$(taille "$WORK/doc-p.html")|text/html; charset=utf-8|0|405 405 405 "
J="$(node "$OR" jetons "$WORK/doc-p.html")"
assert_eq "K1.4 — un seul script de jeton, les trois jetons y sont (equipe = code), nulle part ailleurs dans le document" "$(printf '%s' "$J" | oj '[j.nbScripts,j.jetons.code===j.jetons.equipe,j.jetons.projet.length>=16,j.dehors]')" "[1,true,true,0]"
assert_eq "K1.4 — ni le manifeste ni aucun fichier de /_vf/ ne porte un jeton, le chemin du lab, un marqueur du lab, une clé interdite" "$(node "$OR" contient "$PORT" "$WORK/doc-p.html" "$TOKC" "$TOKP" "$LAB" MQ16-PHASE MQ16-fichier MQ16-REMOTE '"doing"' '"mandat"' '"messages"' '"outils"' '"fil"' | sed 's/^document$//;s/,document//;s/document,//')" ""
assert_eq "K1.5 — Sec-Fetch-Site: cross-site : 403 sur les quatre adresses et sur /_vf/" "$(for u in / /index.html /project.html /equipe.html /_vf/moteur.js; do rq GET "$u" "$WORK/x.out" --entete sec-fetch-site:cross-site; printf '%s ' "$RQ_CODE"; done)" "403 403 403 403 403 "

echo "=== K2 (suite) — table fermée, lien symbolique, liste calculée au démarrage ==="
FERME="$(for u in /_vf/ /_vf//moteur.js /_vf/../serve.mjs /_vf/ui/../moteur.js /_vf/%2e%2e/serve.mjs '/_vf/moteur.js%00' /_vf/MOTEUR.js /_vf/ui/ "/_vf/$(printf 'a%.0s' $(seq 1 4096))"; do rq GET "$u" "$WORK/x.out"; printf '%s ' "$RQ_CODE"; done)"
assert_eq "K2.3 — table fermée : /_vf/, //, .., ui/.., %2e%2e, NUL, majuscules, ui/, 4 Kio → 404 chacun" "$FERME" "404 404 404 404 404 404 404 404 404 "
ALIAS="$(for u in //x/ //x/project.html /./project.html /./ //project.html /project.html/ /equipe.html/. /index.html/../project.html; do rq GET "$u" "$WORK/x.out"; printf '%s ' "$RQ_CODE"; done)"
assert_eq "K2.3 (AU16-01) — seules les quatre adresses déclarées répondent : //x/, //x/project.html, /./project.html, /./, //project.html, barre finale, segment .. → 404 (chemin brut, comme /_vf/)" "$ALIAS" "404 404 404 404 404 404 404 404 "
rq GET "/project.html?x=1" "$WORK/x.out"
assert_eq "K2.3 (AU16-01) — témoin positif : /project.html?x=1 répond 200 (la requête est coupée avant le jugement)" "$RQ_CODE" "200"
rq GET "/_vf/moteur.js?x=1" "$WORK/x.out"; Q1="$RQ_CODE"; rq POST /_vf/moteur.js "$WORK/x.out"
assert_eq "K2.3 — témoin positif : ?x=1 est ignoré (200) ; K2.4 — POST /_vf/moteur.js : 405" "$Q1|$RQ_CODE" "200|405"
# fichiers plantés dans la SORTIE, après le démarrage (E9, A40)
for f in plante.js plante.mjs serve.mjs vf-cockpit-server.mjs index.html.bak project.html.old; do printf 'window.__plante16 = 1; // MQ16-PLANTE\n' > "$OUT/$f"; done
cp "$OUT/graph.json" "$WORK/graph-copie.json"; ln -sf "$OUT/graph.json" "$OUT/lien-interne.json"; printf 'MQ16-CREDS\n' > "$WORK/creds-hors.txt"; ln -sf "$WORK/creds-hors.txt" "$OUT/creds.txt"
rq GET /_vf/plante.js "$WORK/x.out"; PA="$RQ_CODE"; rq GET /_vf/ui/plante.js "$WORK/x.out"
assert_eq "K2.6 — un plante.js posé dans la sortie : /_vf/plante.js et /_vf/ui/plante.js → 404" "$PA|$RQ_CODE" "404|404"
printf 'window.__ajout_apres = 1;\n' > "$ENG/assets/ui/zz-plante-ui-tmp.js"; rq GET /_vf/ui/zz-plante-ui-tmp.js "$WORK/x.out"; rm -f "$ENG/assets/ui/zz-plante-ui-tmp.js"
assert_eq "K2.6 — un fichier ajouté au ui/ du module APRÈS le démarrage : 404 (liste calculée au démarrage)" "$RQ_CODE" "404"

echo "=== K4 — E9 : un fichier planté dans la sortie n'est ni servi, ni lu, ni exécuté ==="
assert_eq "K4.0 — témoin de présence : le marqueur et le script planté sont bien dans la sortie" "$(node "$OR" marque "$OUT/plante.js" MQ16-PLANTE)" "oui"
sed 's|</body>|<script>window.__plante16 = 1</script></body>|' "$WORK/doc-p.html" > "$OUT/project.html"; cp "$OUT/project.html" "$OUT/index.html"
assert_eq "K4.1 — ni le document, ni le manifeste, ni un fichier de /_vf/ ne contient le marqueur planté" "$(node "$OR" contient "$PORT" "$WORK/doc-p.html" MQ16-PLANTE __plante16)" ""
assert_eq "K4.2 — /plante.js, /plante.mjs, /serve.mjs, /vf-cockpit-server.mjs, /index.html.bak, /project.html.old : 404" "$(for u in /plante.js /plante.mjs /serve.mjs /vf-cockpit-server.mjs /index.html.bak /project.html.old; do rq GET "$u" "$WORK/x.out"; printf '%s ' "$RQ_CODE"; done)" "404 404 404 404 404 404 "
rq GET /project.html "$WORK/doc-p2.html"
assert_eq "K4.2 — /project.html servi après la plantation ne contient pas le script planté" "$(node "$OR" marque "$WORK/doc-p2.html" __plante16)" "non"

echo "=== K5 — le service statique de la sortie est retiré (A41) ==="
K5="$(for u in /graph.json /projet.json /recent-work.json /architecture.json /custom-flows.json /LICENSE /LICENCES-TIERCES.txt /lien-interne.json /creds.txt /.cache/server.json; do rq GET "$u" "$WORK/x.out"; a="$RQ_CODE"; rq GET "$u" "$WORK/x.out" --jeton "$TOKP"; printf '%s/%s ' "$a" "$RQ_CODE"; done)"
assert_eq "K5.1 — /graph.json, /projet.json, /recent-work.json, /architecture.json, /custom-flows.json, licences, lien interne, lien sortant, .cache/server.json : 404 sans jeton comme avec" "$K5" "$(printf '404/404 %.0s' $(seq 1 10))"
assert_eq "K5.1 — témoin de présence : graph.json, le lien interne et le fichier visé par le lien sortant existent sur disque" "$([ -s "$OUT/graph.json" ] && [ -e "$OUT/lien-interne.json" ] && [ -s "$WORK/creds-hors.txt" ] && echo oui || echo non)" "oui"
assert_eq "K5.2 — ni le remote du dépôt, ni le chemin du lab, ni un jeton dans le document ou un fichier de /_vf/ (ils sont dans graph.json, K0.2)" "$(node "$OR" contient "$PORT" "$WORK/doc-p.html" MQ16-REMOTE "$LAB" "$TOKC" "$TOKP" | sed 's/^document$//;s/,document//;s/document,//')" ""

echo "=== K3 (suite) — la source du préfixe suit l'hôte validé ==="
rq GET /project.html "$WORK/x.out" --host "localhost:$PORT"; HL="$(hv content-security-policy)"
assert_eq "K3.2 — Host: localhost:<port> : la source est http://localhost:<port>/_vf/ ; script-src sans 'self', 'unsafe-, *, blob:, data:" "$(printf '%s' "$HL" | sed -n "s|.*script-src \([^;]*\);.*|\1|p" | tr ' ' '\n' | grep -v "^'sha256-" | tr '\n' ' ')|$(printf '%s' "$HL" | sed -n 's|.*script-src \([^;]*\);.*|\1|p' | grep -c "'self'\|unsafe-\|\*\|blob:\|data:")" "http://localhost:$PORT/_vf/ |0"

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

Q="$(printf '\047')"  # apostrophe : les expressions sed des mutants la portent
cat > "$AUX/lien-sortie.mjs" <<'JS'
// lien-sortie.mjs <serve.mjs> <sortie> [<motif du message>, défaut « chemin r »] : lance le serveur sur une sortie donnée par un chemin non réel ; « refus » (sortie 1, message) ou « demarre » (tué après 8 s)
import { spawn } from 'node:child_process';
const [, , serve, sortie, motif = 'chemin r'] = process.argv;
const c = spawn(process.execPath, [serve, '--no-open', '--port', '0', `--sortie=${sortie}`], { stdio: ['ignore', 'ignore', 'pipe'] });
let err = ''; c.stderr.on('data', (d) => { err += d; });
const t = setTimeout(() => { c.kill('SIGKILL'); console.log('demarre'); }, 8000);
c.on('exit', (code) => { clearTimeout(t); console.log(code === 1 && new RegExp(motif).test(err) ? 'refus' : `autre ${code}`); });
JS
if [ -n "$CHROME" ]; then
echo "=== C2 à C5 — changer d'onglet dans le même document ==="
base_srv
rq GET / "$WORK/doc-r.html"; rq GET /project.html "$WORK/doc-p.html"   # le serveur a été relancé : les jetons des documents d'avant sont périmés
TOKC="$(node "$OR" jetons "$WORK/doc-r.html" | oj 'j.token')"; TOKP="$(node "$OR" jetons "$WORK/doc-p.html" | oj 'j.token')"
cat > "$AUX/c2.js" <<'JS'
const sond = await s.ev(`({ titreMoteur: (__s.ins.find((x) => x.src === '/_vf/moteur.js') || {}).titre, depart: __s.depart, apres: { href: location.href, longueur: history.length } })`);
return { ...(await s.ev(SOMMAIRE)), ...sond };
JS
nombre() { rq GET "/api/vf/graphe?onglet=$1" "$WORK/n-$1.json" --jeton "$2"; oj 'j.nodes.length' < "$WORK/n-$1.json"; }
NC="$(nombre code "$TOKC")"; NP="$(nombre projet "$TOKP")"; NE="$(nombre equipe "$TOKC")"
for a in / /index.html /project.html /equipe.html; do chrome avec "http://127.0.0.1:$PORT$a" "$AUX/c2.js" > "$WORK/c2$(echo "$a" | tr -c 'a-z\n' '_').json"; done
cj() { cat "$WORK/c2$(echo "$1" | tr -c 'a-z\n' '_').json" | oj "$2"; }
assert_eq "C2.1 — chacune des quatre adresses rend son onglet : / et /index.html → code, /project.html → project, /equipe.html → equipe ; onglet() égale le nom" "$(for a in / /index.html /project.html /equipe.html; do cj "$a" '[j.tab,j.onglet]'; done | tr '\n' ' ')" '["code","code"] ["code","code"] ["project","projet"] ["equipe","equipe"] '
assert_eq "C2.2 — le nombre de nœuds du graphe vu par le moteur égale celui de la route de l'onglet" "$(for a in / /project.html /equipe.html; do cj "$a" 'j.noeuds'; done | tr '\n' ' ')" "$NC $NP $NE "
assert_eq "C2.3 — la coquille pose le titre de l'onglet avant le moteur (relevé à l'insertion de moteur.js)" "$(for a in / /index.html /project.html /equipe.html; do cj "$a" 'j.titreMoteur'; done | tr '\n' '|')" "VibeFlow · Code|VibeFlow · Code|VibeFlow · Projet|VibeFlow · Équipe|"
chrome avec "http://127.0.0.1:$PORT/project.html#s=ph-2" "$AUX/c2.js" > "$WORK/c24.json"
assert_eq "C2.4 (A1) — /project.html#s=ph-2 : l'adresse, fragment compris, et le compte de l'historique sont les mêmes avant et après le chargement" "$(oj '[j.depart.href===j.apres.href,j.depart.longueur===j.apres.longueur]' < "$WORK/c24.json")" "[true,true]"

cat > "$AUX/c3.js" <<'JS'
// panne: non
const tabs = { code: 'code', projet: 'project', equipe: 'equipe' };
const un = (nom) => s.ev(`VF_COQUILLE.chargerOnglet(${JSON.stringify(nom)}).then(() => ({ ok: true, tab: VibeFlow.graph.meta.vfTab, layout: !!VibeFlow.state.layout, pret: document.documentElement.dataset.vfPret, j: __s.journal.slice(-1)[0] }), (e) => ({ ok: false, msg: String(e.message) }))`);
const c31 = []; for (const nom of ['code', 'equipe', 'projet', 'projet']) c31.push({ nom, tab: tabs[nom], ...(await un(nom)) });
const empreinte = () => s.ev(`({ n: __s.req.length, h: document.body.innerHTML.length, onglet: VF_COQUILLE.onglet(), tab: VibeFlow.graph.meta.vfTab })`);
const avant = await empreinte();
const mauvais = [ '', 'Code', 'PROJET', 'projet ', '__proto__', 'constructor', 'toString', 'projet&onglet=code', 7, null, ['projet'] ];
const c32 = await s.ev(`(async () => { const r = []; for (const v of ${JSON.stringify(mauvais)}) { try { await VF_COQUILLE.chargerOnglet(v); r.push('resolu'); } catch (e) { r.push('rejete'); } } return r; })()`);
const apres = await empreinte();
panne.actif = true;
const c33 = await un('code'); const intact = await empreinte(); panne.actif = false; const suite = await un('projet');
const j0 = await s.ev('__s.journal.length');
const c34 = await s.ev(`(async () => { const a = VF_COQUILLE.chargerOnglet('code'), b = VF_COQUILLE.chargerOnglet('equipe'); await Promise.all([a, b]); return { onglet: VF_COQUILLE.onglet(), j: __s.journal.slice(${j0}) }; })()`);
await s.ev(`(VibeFlow.graph.nodes[0].MQ16 = 'MQ16-MUTE', 1)`); const nr = reseau.length;
await s.ev(`VF_COQUILLE.chargerOnglet('equipe')`);
const gr = reseau.slice(nr).filter((x) => /api\/vf\/graphe/.test(x.url)).pop() || {};
const c35 = { inm: !!gr.inm, statut: gr.statut, neuf: await s.ev(`JSON.stringify(VibeFlow.graph).includes('MQ16-MUTE') ? 'mute' : 'neuf'`) };
return { c31, c32: { rej: c32, req: [avant.n, apres.n], h: [avant.h, apres.h], onglet: [avant.onglet, apres.onglet] }, c33, intact: [intact.h === apres.h, intact.onglet === apres.onglet, intact.tab === apres.tab], suite, c34, c35, viol: s.violations.length };
JS
chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c3.js" > "$WORK/c3.json"
assert_eq "C3.1 — la suite code, equipe, projet, projet : chaque promesse se résout APRÈS « ready » du moteur de l'onglet (relevé de la sonde), mise en page posée, data-vf-pret = oui, aucune violation" "$(oj 'j.c31.map((c)=>c.ok&&c.tab===c.j.replace("ready:","")&&c.layout&&c.pret==="oui")' < "$WORK/c3.json")|$(oj 'j.viol' < "$WORK/c3.json")" "[true,true,true,true]|0"
assert_eq "C3.1 — le moteur est celui de l'onglet demandé" "$(oj 'j.c31.map((c)=>c.j)' < "$WORK/c3.json")" '["ready:code","ready:equipe","ready:project","ready:project"]'
assert_eq "C3.2 — onze noms invalides (vide, majuscules, espace, __proto__, constructor, toString, concaténation, nombre, null, tableau) : promesse rejetée, aucune requête de graphe, onglet affiché intact" "$(oj '[j.c32.rej.every((r)=>r==="rejete"),j.c32.rej.length,j.c32.req[0]===j.c32.req[1],j.c32.h[0]===j.c32.h[1],j.c32.onglet[0]===j.c32.onglet[1]]' < "$WORK/c3.json")" "[true,11,true,true,true]"
assert_eq "C3.3 — lecture en échec (500 au corps synthétique) : rejet au message fixe sans le corps, l'onglet affiché reste intact, un chargement suivant réussit" "$(oj '[j.c33.ok,/MQ16-CORPS/.test(j.c33.msg||""),(j.c33.msg||"").length>0,j.intact.every(Boolean),j.suite.ok]' < "$WORK/c3.json")" "[false,false,true,true,true]"
assert_eq "C3.4 — deux appels non attendus (code puis equipe) se terminent dans l'ordre des appels, l'onglet final est equipe" "$(oj '[j.c34.onglet,j.c34.j]' < "$WORK/c3.json")" '["equipe",["ready:code","ready:equipe"]]'
assert_eq "C3.5 — un second chargement du même onglet envoie If-None-Match et reçoit 304 ; le graphe du moteur est un objet NEUF" "$(oj '[j.c35.inm,j.c35.statut,j.c35.neuf]' < "$WORK/c3.json")" '[true,304,"neuf"]'
cat > "$AUX/c4.js" <<'JS'
return await s.ev(`(async () => {
  const o = {}, nets = [], C = VF_COQUILLE;
  await C.chargerOnglet('projet');
  // C4.1 à C4.3
  const calls = [], ctrl = [];
  const off1 = C.surOnglet((a) => { calls.push(a.onglet); return () => ctrl.push('net:' + (window.VibeFlow && VibeFlow.graph.meta.vfTab) + ':' + !!document.querySelector('header')); });
  o.c41a = calls.slice(); o.c42a = ctrl.length;
  await C.chargerOnglet('code');
  o.c41b = calls.slice(); o.c42b = ctrl.slice();
  const j2 = []; const off2 = C.surOnglet((a) => { j2.push('appel:' + a.onglet); return () => j2.push('net'); });
  o.c43a = j2.slice(); off2(); o.c43b = j2.slice();
  await C.chargerOnglet('equipe'); o.c43c = j2.slice();
  off1();
  // C4.4 : un rappel qui lève
  const errs = []; const ce = console.error; console.error = (...a) => errs.push(a.length);
  const ok = []; C.surOnglet(() => { throw new Error('boum'); }); const apresInscription = errs.length;
  const off4 = C.surOnglet((a) => { ok.push(a.onglet); });
  await C.chargerOnglet('projet'); o.c44 = { erreursInscription: apresInscription, erreursChangement: errs.length - apresInscription, ok: ok.slice() };
  console.error = ce;
  // C4.5 : un rappel posé pendant un autre est appelé pour l'onglet courant après le lot
  const ordre = []; let premier = true;
  C.surOnglet(() => { ordre.push('externe'); if (premier) { premier = false; C.surOnglet(() => { ordre.push('interne'); }); ordre.push('apres-pose'); } });
  o.c45 = ordre.slice();
  return o;
})()`);
JS
chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c4.js" > "$WORK/c4.json"
assert_eq "C4.1 — un rappel posé après le premier rendu est appelé aussitôt pour l'onglet courant, puis après chaque chargerOnglet" "$(oj '[j.c41a,j.c41b]' < "$WORK/c4.json")" '[["projet"],["projet","code"]]'
assert_eq "C4.2 — la fonction qu'il rend est appelée juste avant le démontage (le moteur précédent et son corps existent encore), et pas avant" "$(oj '[j.c42a,j.c42b]' < "$WORK/c4.json")" '[0,["net:project:true"]]'
assert_eq "C4.3 — la désinscription arrête les appels, et le nettoyage en attente est appelé aussitôt" "$(oj '[j.c43a,j.c43b,j.c43c]' < "$WORK/c4.json")" '[["appel:code"],["appel:code","net"],["appel:code","net"]]'
assert_eq "C4.4 — un rappel qui lève n'empêche ni les autres, ni la résolution, et laisse exactement une ligne d'erreur par appel" "$(oj '[j.c44.erreursInscription,j.c44.erreursChangement,j.c44.ok]' < "$WORK/c4.json")" '[1,1,["equipe","projet"]]'
assert_eq "C4.5 — un rappel posé pendant un autre est appelé pour l'onglet courant après le lot" "$(oj 'j.c45' < "$WORK/c4.json")" '["externe","apres-pose","interne"]'

cat > "$AUX/c46.js" <<'JS'
return await s.ev(`(async () => {
  const C = VF_COQUILLE, nets = [], appels = [], ecrire = (id) => (a) => { appels.push(id + ':' + a.onglet); return () => nets.push(id); };
  await C.chargerOnglet('projet');
  C.surOnglet(ecrire('v1'), { cle: 'ext.js' });
  await C.chargerOnglet('code'); await C.chargerOnglet('equipe');
  C.surOnglet(ecrire('v2'), { cle: 'ext.js' });
  const apresRemplacement = { appels: appels.slice(), nets: nets.slice() };
  await C.chargerOnglet('projet');
  const o = { c46: { v1: appels.filter((x) => x.startsWith('v1')).length, v2: appels.filter((x) => x.startsWith('v2')), nets: nets.slice(), apresRemplacement } };
  // C4.7
  const d = []; const a = C.surOnglet(() => { d.push('a'); }), b = C.surOnglet(() => { d.push('b'); });
  const k1 = C.surOnglet(() => { d.push('k1'); }, { cle: 'x' }), k2 = C.surOnglet(() => { d.push('k2'); }, { cle: 'y' });
  o.c47a = d.slice();
  const avant = d.length; let leve = false;
  try { for (const cle of ['', 5, {}, 'z'.repeat(100)]) C.surOnglet(() => { d.push('invalide'); }, { cle }); } catch { leve = true; }
  o.c47b = { leve, appelsInvalides: d.slice(avant).filter((x) => x === 'invalide').length };
  const r1 = C.surOnglet(() => { d.push('r1'); }, { cle: 'r' }); C.surOnglet(() => { d.push('r2'); }, { cle: 'r' }); r1();
  d.length = 0; await C.chargerOnglet('code'); o.c47c = d.filter((x) => x === 'r1' || x === 'r2');
  return o;
})()`);
JS
chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c46.js" > "$WORK/c46.json"
assert_eq "C4.6 (A51) — deux changements d'onglet puis une réexécution du même fichier (même cle) : le rappel courant n'est appelé qu'une fois par arrivée, l'ancien jamais après, l'ancien nettoyage une fois au remplacement, le nettoyage rendu avant chaque changement" "$(oj '[j.c46.v1,j.c46.v2,j.c46.nets]' < "$WORK/c46.json")" '[3,["v2:equipe","v2:projet"],["v1","v1","v1","v2"]]'
assert_eq "C4.7 — deux inscriptions sans cle coexistent, deux cle distinctes coexistent ; une cle invalide (vide, nombre, objet, 100 caractères) n'inscrit rien et ne lève pas ; la désinscription d'une inscription remplacée est sans effet sur la nouvelle" "$(oj '[j.c47a,j.c47b.leve,j.c47b.appelsInvalides,j.c47c]' < "$WORK/c46.json")" '[["a","b","k1","k2"],false,0,["r2"]]'

cat > "$AUX/c5.js" <<'JS'
// panne: non
const man = await s.ev(`JSON.parse(document.getElementById('vf-coquille-manifeste').textContent).fichiers`);
for (const nom of ['code', 'equipe', 'projet', 'code', 'equipe', 'projet']) await s.ev(`VF_COQUILLE.chargerOnglet('${nom}')`);
const ins = await s.ev(`__s.ins.map((x) => x.src)`);
const n = (src) => ins.filter((x) => x === src).length;
const attendu = (cl) => man.filter((f) => f.classe === cl).map((f) => '/_vf/' + f.nom);
let tabs = -1; for (let i = 0; i < 40; i++) { tabs = await s.ev(`fetch('/api/status', { headers: { 'x-vf-cockpit-token': VF_COCKPIT_SERVER.token } }).then((r) => r.json()).then((j) => j.tabs)`); if (tabs === 1) break; await pause(250); }
return { unefois: [...attendu('bibliotheque'), ...attendu('persistant')].map((x) => [x.replace('/_vf/', ''), n(x)]), parOnglet: [...attendu('i18n'), ...attendu('moteur'), ...attendu('onglet')].map((x) => [x.replace('/_vf/', ''), n(x)]), tabs,
  persistants: attendu('persistant').map((x) => x.replace('/_vf/', '')) };
JS
chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c5.js" > "$WORK/c5.json"
assert_eq "C5.1 — sur six changements d'onglet, bibliothèques et persistants (dont ui/69-vf-flux.js et ui/00-vf-surcouches.js) sont insérés EXACTEMENT une fois ; moteur.js et chaque script par onglet sept fois" "$(oj '[j.unefois.filter(([,n])=>n!==1).map(([x])=>x).join(",")||"une-fois",j.parOnglet.filter(([,n])=>n!==7).map(([x])=>x).join(",")||"sept-fois",j.persistants.includes("ui/69-vf-flux.js"),j.persistants.includes("ui/00-vf-surcouches.js")]' < "$WORK/c5.json")" '["une-fois","sept-fois",true,true]'
assert_eq "C5.2 — le serveur ne compte qu'un flux de page ouvert (/api/status, tabs)" "$(oj 'j.tabs' < "$WORK/c5.json")" "1"
# C5.4 à C5.6 (A53) : quatre fixtures dans une copie du module (jamais dans le module du dépôt), aucune liste, aucune CSP à changer
fixtures() { # <copie>
  local u="$1/skills/cockpit-moteur/assets/ui"
  printf '%s\n' '// vf-coquille: persistant' '(() => { window.__fix16a = (window.__fix16a || 0) + 1; (window.__ordre16 = window.__ordre16 || []).push("a"); })();' > "$u/00-vf-zz-fixture-persistant-a.js"
  printf '%s\n' '// vf-coquille: persistant' '(() => { window.__fix16b = (window.__fix16b || 0) + 1; (window.__ordre16 = window.__ordre16 || []).push("b"); })();' > "$u/00-vf-zz-fixture-persistant-b.js"
  printf '%s\n' '// un en-tête de huit lignes' '//' '//' '//' '//' '//' '//' '//' '// vf-coquille: persistant' '(() => { window.__fix16l = (window.__fix16l || 0) + 1; })();' > "$u/00-vf-zz-fixture-ligne9.js"
  printf '%s\n' '(() => { window.__fix16o = (window.__fix16o || 0) + 1; })();' > "$u/95-vf-fixture-onglet.js"
}
cat > "$AUX/c54.js" <<'JS'
const man = await s.ev(`JSON.parse(document.getElementById('vf-coquille-manifeste').textContent).fichiers.map((f) => f.nom + ':' + f.classe)`);
const premier = await s.ev(`__s.ins.map((x) => x.src.replace('/_vf/', ''))`);
const ordreInit = premier.slice(0, premier.indexOf('moteur.js'));
for (const nom of ['code', 'equipe']) await s.ev(`VF_COQUILLE.chargerOnglet('${nom}')`);
const ins = await s.ev(`__s.ins.map((x) => x.src.replace('/_vf/', ''))`);
const n = (x) => ins.filter((y) => y === x).length;
return { man, ordreInit, a: n('ui/00-vf-zz-fixture-persistant-a.js'), b: n('ui/00-vf-zz-fixture-persistant-b.js'), l9: n('ui/00-vf-zz-fixture-ligne9.js'), o: n('ui/95-vf-fixture-onglet.js'),
  fa: await s.ev('window.__fix16a'), fb: await s.ev('window.__fix16b'), ordre: await s.ev('window.__ordre16') };
JS
attendu_init() { # <copie> : bibliothèques, puis TOUS les persistants (marqueur dans les huit premières lignes, tri C), puis les scripts i18n : recalculé depuis les fichiers
  local u="$1/skills/cockpit-moteur/assets/ui" f
  printf '%s\n' graph-query.js vendor/elk.bundled.js
  for f in $(LC_ALL=C ls "$u" | grep '\.js$'); do sed -n '1,8p' "$u/$f" | grep -q 'vf-coquille: persistant' && echo "ui/$f"; done | LC_ALL=C sort
  for f in $(LC_ALL=C ls "$u" | grep '\.js$'); do sed -n '1,8p' "$u/$f" | grep -q 'vf-coquille: persistant' || { [ "$(sed -n 1p "$u/$f")" = '// vibeflow:fr' ] && echo "ui/$f"; }; done | LC_ALL=C sort
}
cockpit_arreter; CPF="$(cockpit_module_copie)"; fixtures "$CPF"
COCKPIT_MODULE="$CPF" demarrer "$LAB"
chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c54.js" > "$WORK/c54.json"
ATT="$(attendu_init "$CPF" | tr '\n' ' ')"
assert_eq "C5.0 — témoin de présence : les trois fixtures sont au manifeste servi, deux persistants, une du neuvième rang et une par onglet" "$(oj '[j.man.includes("ui/00-vf-zz-fixture-persistant-a.js:persistant"),j.man.includes("ui/00-vf-zz-fixture-persistant-b.js:persistant"),j.man.includes("ui/00-vf-zz-fixture-ligne9.js:onglet"),j.man.includes("ui/95-vf-fixture-onglet.js:onglet")]' < "$WORK/c54.json")" "[true,true,true,true]"
assert_eq "C5.4 — chaque persistant de fixture est évalué UNE fois sur deux changements d'onglet ; le fixture à marqueur à la ligne 9 et le fixture sans marqueur sont insérés trois fois (une par arrivée)" "$(oj '[j.a,j.b,j.fa,j.fb,j.l9,j.o]' < "$WORK/c54.json")" "[1,1,1,1,3,3]"
assert_eq "C5.5 — ordre au premier chargement : avant moteur.js, les bibliothèques, TOUS les persistants (ordre d'octets recalculé depuis les fichiers de la copie), puis les scripts de traduction ; les deux fixtures dans l'ordre entre eux" "$(oj 'j.ordreInit.join(" ")+" "' < "$WORK/c54.json")|$(oj 'j.ordre.join("")' < "$WORK/c54.json")" "$ATT|ab"
assert_eq "C5.5 — témoin rouge de l'oracle : un ordre attendu où le persistant suit moteur.js est refusé par la comparaison" "$([ "$(oj 'j.ordreInit.concat(["moteur.js"]).join(" ")+" "' < "$WORK/c54.json")" = "$ATT" ] && echo accepte || echo refuse)" "refuse"
cockpit_arreter

echo "=== mutants du client : M-PERSISTANT, M-REEVAL, M-PRET, M-CLE ==="
unset COCKPIT_MODULE
cat > "$AUX/c51.js" <<'JS'
// panne: non
const man = await s.ev(`JSON.parse(document.getElementById('vf-coquille-manifeste').textContent).fichiers`);
for (const nom of ['code', 'equipe', 'projet']) await s.ev(`VF_COQUILLE.chargerOnglet('${nom}')`);
const ins = await s.ev(`__s.ins.map((x) => x.src)`);
const n = (f) => ins.filter((x) => x === '/_vf/' + f).length;
return { flux: n('ui/69-vf-flux.js'), surcouches: n('ui/00-vf-surcouches.js'), moteur: n('moteur.js') };
JS
if cockpit_module_muter persistant 69-vf-flux.js 's|vf-coquille: persistant|vf-coquille: sans|' && [ -n "$CHROME" ]; then
  demarrer "$LAB"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c51.js" > "$WORK/c51.json"
  assert_eq "M-PERSISTANT — ui/69-vf-flux.js sans son marqueur : inséré à chaque onglet (4 fois), ui/00-vf-surcouches.js reste à 1 : rouge pour ce fichier seul" "$(oj '[j.flux,j.surcouches]' < "$WORK/c51.json")" "[4,1]"
  cockpit_arreter; unset COCKPIT_MODULE
else assert_eq "M-PERSISTANT — mutant sans effet (le marqueur de 69-vf-flux.js est absent)" "sans effet" "effet"; fi
cockpit_arreter; CPR="$(cockpit_module_copie)"; fixtures "$CPR"
if cockpit_module_muter reeval vf-coquille.js "s|nomsDe(.i18n., .moteur., .onglet.)); // garde:coquille-persistants|nomsDe(initial ? ${Q}i18n${Q} : ${Q}persistant${Q}, ${Q}i18n${Q}, ${Q}moteur${Q}, ${Q}onglet${Q})); // garde:coquille-persistants|" && [ -n "$CHROME" ]; then
  fixtures "$COCKPIT_MODULE"; demarrer "$LAB"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c54.js" > "$WORK/c54m.json"
  assert_eq "M-REEVAL — les persistants ré-insérés à chaque onglet : C5.4 rougit seul (fixtures persistants à 3, compteurs à 3) alors que C5.5 (premier chargement) reste vert" "$(oj '[j.a,j.b,j.fa,j.fb]' < "$WORK/c54m.json")|$(oj 'j.ordreInit.join(" ")+" "' < "$WORK/c54m.json")" "[3,3,3,3]|$ATT"
  cockpit_arreter; unset COCKPIT_MODULE
else assert_eq "M-REEVAL — mutant sans effet (ancre garde:coquille-persistants absente)" "sans effet" "effet"; fi
cat > "$AUX/c36.js" <<'JS'
// echec: true
// amorce: window.VF_COQUILLE_REGLAGES = { delaiMs: 2000 };
return await s.ev(`({ t: Math.round(performance.now()), etat: VF_COQUILLE.etat(), pret: document.documentElement.dataset.vfPret })`);
JS
if cockpit_module_muter pret viewer.html "s|emit('ready', {});|;|" && [ -n "$CHROME" ]; then
  demarrer "$LAB"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c36.js" > "$WORK/c36.json"
  assert_eq "C3.6 / M-PRET — un moteur qui ne dit jamais « ready » : la promesse initiale est rejetée après le délai réglé (2 000 ms : ni avant 1 500 ms, ni après 6 000), data-vf-pret reste non" "$(oj '[j.etat.phase,j.pret,j.t>=1500,j.t<=6000]' < "$WORK/c36.json")" '["echec","non",true,true]'
  cockpit_arreter; unset COCKPIT_MODULE
else assert_eq "M-PRET — mutant sans effet (ancre emit ready absente)" "sans effet" "effet"; fi
if cockpit_module_muter cle vf-coquille.js "s|const remplacee = .*// garde:coquille-cle|const remplacee = null; // garde:coquille-cle|" && [ -n "$CHROME" ]; then
  demarrer "$LAB"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c46.js" > "$WORK/c46m.json"
  assert_eq "M-CLE — sans le remplacement par cle : C4.6 rougit seul (l'ancien rappel est encore appelé après la réexécution, ses nettoyages ne tombent plus dans l'ordre du remplacement)" "$(oj '[j.c46.v1>3,JSON.stringify(j.c46.nets)!==JSON.stringify(["v1","v1","v1","v2"])]' < "$WORK/c46m.json")" "[true,true]"
  cockpit_arreter; unset COCKPIT_MODULE
else assert_eq "M-CLE — mutant sans effet (ancre garde:coquille-cle absente)" "sans effet" "effet"; fi
echo "=== C6 — après des changements d'onglet, le document équivaut à un chargement à froid (par classes) ==="
cat > "$AUX/c6froid.js" <<'JS'
await s.attendre(`document.documentElement.dataset.vfPret === 'oui'`, 'document prêt');
// la pastille #vf-lock naît du premier évènement du flux du direct : elle arrive APRÈS « pret », en un temps que la charge allonge ; mesurer une fois posée
await s.attendre(`!!document.getElementById('vf-lock')`, 'pastille du direct (premier évènement du flux)'); 
const emp = await s.stable('__s.empreinte()', 'empreinte du document à froid'); // mesurer une fois posé : deux relevés consécutifs égaux, jamais une pause fixe
return { emp, prof: await s.ev(`__s.profondeurFetch()`) };
JS
cat > "$AUX/c6seq.js" <<'JS'
const res = [];
for (const nom of (JSON.parse('SUITE'))) {
  await s.ev(`VF_COQUILLE.chargerOnglet('${nom}')`);
  await s.attendre(`!!document.getElementById('vf-lock')`, 'pastille du direct (premier évènement du flux)'); 
  res.push({ nom, emp: await s.stable('__s.empreinte()', 'empreinte après ' + nom), prof: await s.ev(`__s.profondeurFetch()`) });
}
return res;
JS
cat > "$AUX/classes.mjs" <<'JS'
// classes.mjs <froid-code> <froid-projet> <froid-equipe> <suite> : pour chaque étape, les classes d'état du document qui diffèrent du chargement à froid de l'onglet atteint
import fs from 'node:fs';
const [, , c, p, e, suite] = process.argv; const froid = { code: JSON.parse(fs.readFileSync(c)), projet: JSON.parse(fs.readFileSync(p)), equipe: JSON.parse(fs.readFileSync(e)) };
const egal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const classes = (x, f) => [['ids', x.emp.corps.ids, f.emp.corps.ids], ['balises', x.emp.corps.balises, f.emp.corps.balises], ['tete', x.emp.tete, f.emp.tete], ['classesBody', x.emp.classesBody, f.emp.classesBody],
  ['attrsHtml', x.emp.attrsHtml, f.emp.attrsHtml], ['props', x.emp.props, f.emp.props], ['ecouteurs', x.emp.ecouteurs, f.emp.ecouteurs], ['vivants', x.emp.vivants, f.emp.vivants], ['fetch', x.prof, f.prof]]
  .filter(([, a, b]) => !egal(a, b)).map(([n]) => n);
const j = JSON.parse(fs.readFileSync(suite)); const tout = new Set(), detail = [];
const ecart = (x, y) => { const k = (v) => (Array.isArray(v) ? v.map(String) : Object.entries(v || {}).map(([n, w]) => n + '=' + JSON.stringify(w))); const A = k(x), B = k(y);
  return { en_plus: A.filter((e) => !B.includes(e)).slice(0, 6), en_moins: B.filter((e) => !A.includes(e)).slice(0, 6) }; };
for (const etape of j) { const f = froid[etape.nom]; for (const n of classes(etape, f)) { tout.add(n); if (process.env.C6DETAIL) detail.push([etape.nom, n, n === 'fetch' ? [etape.prof, f.prof] : ecart(etape.emp[n === 'ids' || n === 'balises' ? 'corps' : n]?.[n] ?? etape.emp[n], f.emp[n === 'ids' || n === 'balises' ? 'corps' : n]?.[n] ?? f.emp[n])]); } }
console.log(JSON.stringify({ classes: [...tout].sort(), etapes: j.length, ...(process.env.C6DETAIL ? { detail } : {}) }));
JS
froids() { # <dossier de sortie des fichiers> : les trois chargements à froid d'un serveur démarré
  chrome avec "http://127.0.0.1:$PORT/index.html" "$AUX/c6froid.js" > "$1-code.json"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c6froid.js" > "$1-projet.json"; chrome avec "http://127.0.0.1:$PORT/equipe.html" "$AUX/c6froid.js" > "$1-equipe.json"
}
suite_classes() { # <préfixe des froids> <suite JSON> : les classes qui diffèrent, sur un document chargé depuis /project.html
  sed "s|SUITE|$2|" "$AUX/c6seq.js" > "$AUX/c6seq-x.js"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c6seq-x.js" > "$WORK/c6suite.json"
  node "$AUX/classes.mjs" "$1-code.json" "$1-projet.json" "$1-equipe.json" "$WORK/c6suite.json" | oj 'j.classes.join(",")||"aucune"'
}
base_srv; froids "$WORK/froid"
assert_eq "C6.0 — témoin : les trois chargements à froid portent des écouteurs et des identifiants (l'empreinte n'est pas vide)" "$(for o in code projet equipe; do oj '[Object.keys(j.emp.ecouteurs).length>5,j.emp.corps.ids.length>20,j.emp.tete.length>5]' < "$WORK/froid-$o.json"; done | tr '\n' ' ')" "[true,true,true] [true,true,true] [true,true,true] "
assert_eq "C6.1 — suite code, projet, equipe, code, equipe, projet, projet (auto-transition comprise) depuis /project.html : après CHAQUE changement le document est équivalent à un chargement à froid de l'onglet atteint (identifiants, balises, tête, classes, attributs, propriétés de window, écouteurs, minuteries, observateurs, flux)" "$(suite_classes "$WORK/froid" '["code","projet","equipe","code","equipe","projet","projet"]')" "aucune"
cockpit_arreter
cat > "$AUX/c6fetch.js" <<'JS'
const res = [];
for (const nom of ['code', 'projet', 'equipe', 'code']) { await s.ev(`VF_COQUILLE.chargerOnglet('${nom}')`); await pause(300); res.push(await s.ev(`__s.profondeurFetch()`)); }
return res;
JS
CPX="$(cockpit_module_copie)"; printf '%s\n' '(() => { const f = window.fetch; window.fetch = function (...a) { return f.apply(this, a); }; })();' > "$CPX/skills/cockpit-moteur/assets/ui/96-vf-fixture-fetch.js"
COCKPIT_MODULE="$CPX" demarrer "$LAB"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c6fetch.js" > "$WORK/c6fetch-t.json"; cockpit_arreter; unset COCKPIT_MODULE
assert_eq "C6.2 — témoin du mutant M-FETCH : une extension de test enveloppe fetch à chaque onglet ; la profondeur reste la même à chaque onglet (le remplacement est défait à chaque changement) et l'enveloppe est vue (profondeur au moins 1)" "$(oj '[new Set(j).size===1,j[0]>=1]' < "$WORK/c6fetch-t.json")" "[true,true]"
for m in "ecouteurs|ecouteurs|s|for (const \[c, t, f, o\] of j.ecouteurs) REL.call(c, t, f, o); // garde:coquille-demontage-ecouteurs|;|" \
         "corps|balises,ids,vivants|s|for (const n of \[...D.body.childNodes\]) if (!etrangers.has(n)) n.remove(); // garde:coquille-corps|;|" \
         "head|tete|s|for (const n of apres.tete) if (!j.avant.tete.has(n)) n.remove(); // garde:coquille-head|;|"; do
  nom="${m%%|*}"; reste="${m#*|}"; att="${reste%%|*}"; expr="${reste#*|}"
  if cockpit_module_muter "$nom" vf-coquille-portee.js "$expr"; then
    demarrer "$LAB"; assert_eq "M-$(echo "$nom" | tr a-z A-Z) — rougit les classes « $att » (les siennes seules : la visite du premier passage, qui réveillait selon la charge les gestionnaires d'un moteur mort, est lue comme faite), aucune autre, sur code, projet, equipe depuis /project.html" "$(suite_classes "$WORK/froid" '["code","projet","equipe"]')" "$att"; cockpit_arreter; unset COCKPIT_MODULE
  else assert_eq "M-$(echo "$nom" | tr a-z A-Z) — mutant sans effet (ancre absente)" "sans effet" "effet"; fi
done
CPY="$(cockpit_module_copie)"; cp "$CPX/skills/cockpit-moteur/assets/ui/96-vf-fixture-fetch.js" "$CPY/skills/cockpit-moteur/assets/ui/"
sed -i.avant 's|W.fetch = j.fetch; // garde:coquille-fetch|;|' "$CPY/skills/cockpit-moteur/assets/vf-coquille-portee.js"
if ! cmp -s "$CPY/skills/cockpit-moteur/assets/vf-coquille-portee.js.avant" "$CPY/skills/cockpit-moteur/assets/vf-coquille-portee.js"; then
  COCKPIT_MODULE="$CPY" demarrer "$LAB"; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/c6fetch.js" > "$WORK/c6fetch-m.json"; cockpit_arreter; unset COCKPIT_MODULE
  assert_eq "M-FETCH — le remplacement de fetch non défait : la profondeur croît à chaque onglet (classe « fetch » seule)" "$(oj 'j[0]<j[1]&&j[1]<j[2]&&j[2]<j[3]' < "$WORK/c6fetch-m.json")" "true"
else assert_eq "M-FETCH — mutant sans effet" "sans effet" "effet"; fi
echo "=== C7 — sous --terminal, le tiroir est posé UNE fois par chargement de la coquille (A3) ==="
base_srv
assert_eq "C7.4 — sans --terminal : ni le document, ni le manifeste, ni un fichier de /_vf/ ne contient « vf-term- »" "$(rq GET /project.html "$WORK/doc-sans-t.html"; node "$OR" contient "$PORT" "$WORK/doc-sans-t.html" vf-term-)" ""
cockpit_arreter
mkdir -p "$WORK/bin" "$WORK/run" "$OUT/.cache"
printf '#!/bin/sh\necho $$ > "%s/run/shell.pid"\n/bin/sh -i\n' "$WORK" > "$WORK/bin/shell-test"; chmod +x "$WORK/bin/shell-test"
AMORCE="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"; (umask 077; printf '%s' "$AMORCE" > "$OUT/.cache/terminal-amorce")
SHELL="$WORK/bin/shell-test" VF_COCKPIT_TERM_GRACE_MS=5000 COCKPIT_PRET=terminal demarrer "$LAB" --terminal
QPORT="$(node -e 'try{console.log(new URL(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).terminal.url).port)}catch{console.log(0)}' "$OUT/.cache/server.json")"
cat > "$AUX/c7.js" <<'JS'
// amorce: window.__q7 = 0;
await s.attendre(`!location.hash && document.querySelectorAll('iframe').length === 1`, 'cadre de Q posé, fragment effacé');
const T = (e) => s.ev(e);
await T(`(() => { for (const e of [document.querySelector('.vf-term-pastille'), document.querySelector('iframe')]) e.dataset.m16 = 'x'; const f = document.querySelector('iframe'); f.addEventListener('load', () => { window.__q7 += 1; }); return 1; })()`);
const arbre = await s.send('Page.getFrameTree'); const enfants = arbre.frameTree.childFrames || [];
const avant = await T(`({ hash: location.hash, cadres: document.querySelectorAll('iframe').length })`); avant.origine = enfants.length ? new URL(enfants[0].frame.url).origin : 'aucun';
for (const nom of ['code', 'equipe', 'projet', 'code', 'equipe', 'projet']) await T(`VF_COQUILLE.chargerOnglet('${nom}')`);
await pause(600);
const apres = await T(`({ hash: location.hash, cadres: document.querySelectorAll('iframe').length, marques: [document.querySelector('.vf-term-pastille').dataset.m16, document.querySelector('iframe').dataset.m16], navigations: window.__q7 })`);
const ouvert0 = await T(`document.body.classList.contains('vf-term-ouvert')`);
for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: ' ', code: 'Space', windowsVirtualKeyCode: 32, modifiers: 10 });
await pause(500);
const ouvert1 = await T(`document.body.classList.contains('vf-term-ouvert')`);
return { avant, apres, bascule: ouvert0 !== ouvert1, amorces: reseau.filter((r) => r.methode === 'POST' && /\/amorce$/.test(r.url)).length, violations: s.violations.length };
JS
if [ "${QPORT:-0}" -gt 0 ]; then
  chrome avec "http://127.0.0.1:$PORT/project.html#t=$AMORCE" "$AUX/c7.js" > "$WORK/c7.json"
  assert_eq "C7.1 — /project.html#t=<amorce> : le fragment est effacé de l'adresse, un seul cadre, d'origine celle de Q" "$(oj '[j.avant.hash,j.avant.cadres,j.avant.origine]' < "$WORK/c7.json")" "[\"\",1,\"http://127.0.0.1:$QPORT\"]"
  assert_eq "C7.2 — après six changements d'onglet : mêmes pastille et même cadre (marque posée sur l'élément), un seul cadre, aucune navigation de cadre de plus, fragment jamais revenu, l'amorce n'a servi qu'une fois" "$(oj '[j.apres.marques,j.apres.cadres,j.apres.navigations,j.apres.hash,j.amorces]' < "$WORK/c7.json")" '[["x","x"],1,0,"",1]'
  assert_eq "C7.3 — le raccourci du tiroir (Ctrl+Maj+Espace) bascule encore vf-term-ouvert sur body" "$(oj 'j.bascule' < "$WORK/c7.json")" "true"
else assert_eq "C7 — le serveur --terminal n'a pas démarré (port de Q absent)" "sans terminal" "terminal"; fi
cockpit_arreter
echo "=== C8 — échec d'un chargement d'onglet : jamais une page blanche, jamais le corps de la réponse (A55) ==="
cockpit_arreter
CPE="$(cockpit_module_copie)"
printf '%s\n' '// vf-coquille: persistant' '(() => {' '  window.__fix16eval = (window.__fix16eval || 0) + 1; window.__fix16e = window.__fix16e || []; window.__fix16r = 0;' \
  "  document.addEventListener('vf:coquille-echec', (ev) => { window.__fix16e.push(ev.detail); if (window.__fix16Annule) ev.preventDefault(); });" \
  "  VF_COQUILLE.surOnglet(() => { window.__fix16r += 1; }, { cle: '00-vf-zz-fixture-echec.js' });" '})();' > "$CPE/skills/cockpit-moteur/assets/ui/00-vf-zz-fixture-echec.js"
LET="Lecture impossible : les données de cet onglet n'ont pas pu être lues."
cat > "$AUX/c8mesure.js" <<'JS'
const MESURE = `(() => { const st = document.querySelector('#stage'), n = document.getElementById('vf-coquille-echec'), b = n && n.querySelector('button'), cs = n && getComputedStyle(n), ps = n && getComputedStyle(n.parentElement);
  const texte = document.body.innerText;
  return { etat: VF_COQUILLE.etat(), onglet: VF_COQUILLE.onglet(), pret: document.documentElement.dataset.vfPret, stageTexte: st.innerText.trim().length > 0, nbTextes: texte.split("TEXTE-FIXE").length - 1, noeud: !!n,
    bouton: b ? b.textContent.trim() : null, nbBoutons: n ? n.querySelectorAll('button').length : 0, evts: window.__fix16e || [], evals: window.__fix16eval, r: window.__fix16r,
    corps: texte.includes('MQ16-CORPS') || JSON.stringify(window.__fix16e || []).includes('MQ16-CORPS'), fond: cs && cs.backgroundColor, couleur: cs && cs.color, couleurParent: ps && ps.color, h: document.body.querySelectorAll('*').length }; })()`;
JS
# un corps de scénario = en-têtes + la mesure ; TEXTE-FIXE remplacé par le texte attendu
corps8() { { head -n "$1" "$AUX/c8$2.js"; cat "$AUX/c8mesure.js"; tail -n +"$(($1+1))" "$AUX/c8$2.js"; } | sed "s|TEXTE-FIXE|$LET|"; }
cat > "$AUX/c8a.js" <<'JS'
// echec: true
// panne: oui
await pause(500); return { ...(await s.ev(MESURE)), erreurs: erreurs.length };
JS
cat > "$AUX/c8b.js" <<'JS'
// echec: true
// panne: oui
// amorce: window.__fix16Annule = true;
await pause(500); return { ...(await s.ev(MESURE)), erreurs: erreurs.length };
JS
cat > "$AUX/c8c.js" <<'JS'
// echec: true
// panne: oui
await pause(300); panne.actif = false;
await s.ev(`document.querySelector('#vf-coquille-echec button').click()`);
await s.attendre(`VF_COQUILLE.etat().phase === 'pret'`, 'retour à pret après Réessayer');
await s.attendre(`!!document.getElementById('vf-lock')`, 'pastille du direct (premier évènement du flux)'); 
const empC = await s.stable('__s.empreinte()', 'empreinte après Réessayer');
return { ...(await s.ev(MESURE)), emp: empC, prof: await s.ev('__s.profondeurFetch()') };
JS
cat > "$AUX/c8d.js" <<'JS'
// echec: true
// panne: oui
await pause(300); await s.ev(`document.querySelector('#vf-coquille-echec button').click()`); await pause(700);
return await s.ev(MESURE);
JS
cat > "$AUX/c8e.js" <<'JS'
// panne: non
await s.attendre(`!!document.getElementById('vf-lock')`, 'pastille du direct (premier évènement du flux)'); await pause(700); const avant = await s.ev(MESURE);
panne.actif = true;
const rej = await s.ev(`VF_COQUILLE.chargerOnglet('code').then(() => 'resolu', (e) => String(e.message))`); await pause(300);
const apres = await s.ev(MESURE); panne.actif = false;
const suite = await s.ev(`VF_COQUILLE.chargerOnglet('code').then(() => 'ok', () => 'ko')`);
return { avant, rej, apres, suite };
JS
cat > "$AUX/c8f.js" <<'JS'
// panne: non
await s.attendre(`document.documentElement.dataset.vfPret === 'oui'`, 'document prêt'); await s.attendre(`!!document.getElementById('vf-lock')`, 'pastille du direct (premier évènement du flux)'); const empF = await s.stable('__s.empreinte()', 'empreinte du chargement normal'); return { ...(await s.ev(MESURE)), emp: empF, prof: await s.ev('__s.profondeurFetch()') };
JS
cat > "$AUX/c8verdict.mjs" <<'JS'
// c8verdict.mjs <dossier> : les contrôles de C8 qui échouent (noms), un par ligne ; vide = tout vert
import fs from 'node:fs';
const [, , d] = process.argv, L = (f) => JSON.parse(fs.readFileSync(`${d}/${f}.json`, 'utf8')); const rouge = [];
const ok = (nom, v) => { if (!v) rouge.push(nom); };
const a = L('c8a'), b = L('c8b'), c = L('c8c'), e = L('c8d'), f = L('c8e'), g = L('c8f');
ok('c81.etat', JSON.stringify(a.etat) === JSON.stringify({ onglet: 'projet', phase: 'echec', motif: 'lecture' })); ok('c81.nonBlanche', a.stageTexte); ok('c81.texteUnique', a.nbTextes === 1);
ok('c81.bouton', a.bouton === 'Réessayer' && a.nbBoutons === 1); ok('c81.evenement', a.evts.length === 1 && a.evts[0].initial === true && a.evts[0].onglet === 'projet'); ok('c81.rappels', a.r === 0);
ok('c81.sansErreurPage', a.erreurs === 0); ok('c81.corps', !a.corps); ok('c81.sobre', a.fond === 'rgba(0, 0, 0, 0)' && a.couleur === a.couleurParent);
ok('c82.evenement', b.evts.length === 1); ok('c82.texteAbsent', b.nbTextes === 0 && !b.noeud && b.nbBoutons === 0); ok('c82.etat', b.etat.phase === 'echec');
ok('c83.pret', c.etat.phase === 'pret' && c.onglet === 'projet' && c.pret === 'oui'); ok('c83.rappels', c.r === 1); ok('c83.retire', !c.noeud && c.nbTextes === 0); ok('c83.uneEvaluation', c.evals === 1);
ok('c84.evenementRepete', e.evts.length === 2 && e.evts[1].initial === true); ok('c84.uniques', e.nbTextes === 1 && e.nbBoutons === 1);
ok('c85.rejet', typeof f.rej === 'string' && f.rej.length > 0 && !f.rej.includes('MQ16-CORPS')); ok('c85.evenement', f.apres.evts.length === 1 && f.apres.evts[0].initial === false && f.apres.evts[0].onglet === 'code');
ok('c85.intact', f.apres.h === f.avant.h && f.apres.onglet === 'projet'); ok('c85.rappels', f.apres.r === f.avant.r); ok('c85.aucunTexte', !f.apres.noeud && f.apres.nbTextes === 0); ok('c85.suite', f.suite === 'ok');
const cl = (x, y) => [['ids', x.emp.corps.ids, y.emp.corps.ids], ['balises', x.emp.corps.balises, y.emp.corps.balises], ['tete', x.emp.tete, y.emp.tete], ['classesBody', x.emp.classesBody, y.emp.classesBody], ['attrsHtml', x.emp.attrsHtml, y.emp.attrsHtml],
  ['props', x.emp.props, y.emp.props], ['ecouteurs', x.emp.ecouteurs, y.emp.ecouteurs], ['vivants', x.emp.vivants, y.emp.vivants], ['fetch', x.prof, y.prof]].filter(([, p, q]) => JSON.stringify(p) !== JSON.stringify(q)).map(([n]) => n);
const diff = cl(c, g); ok('c83.equivalence:' + diff.join('+'), diff.length === 0);
if (rouge.length) console.log(rouge.sort().join('\n'));
JS
c8_rouges() { # <dossier de sortie> : joue les six scénarios sur le serveur courant, rend les contrôles qui échouent
  mkdir -p "$1"; local sc
  for sc in "a:2" "b:3" "c:2" "d:2" "e:1" "f:1"; do corps8 "${sc#*:}" "${sc%%:*}" > "$1/c8${sc%%:*}.js"; chrome avec "http://127.0.0.1:$PORT/project.html" "$1/c8${sc%%:*}.js" > "$1/c8${sc%%:*}.json"; done
  node "$AUX/c8verdict.mjs" "$1" | tr '\n' ' '
}
if [ -n "$CHROME" ]; then
  COCKPIT_MODULE="$CPE" demarrer "$LAB"
  assert_eq "C8 — témoin : le persistant de fixture est au manifeste et le serveur de la copie répond" "$(rq GET /project.html "$WORK/doc-e8.html"; node "$OR" manifeste "$WORK/doc-e8.html" | oj 'j.classes["ui/00-vf-zz-fixture-echec.js"]')" "persistant"
  assert_eq "C8.1 à C8.4 — premier chargement en échec : état, événement annulable, texte fixe et « Réessayer » (jamais le corps), annulation, retour à pret sans ré-évaluer les persistants, panne maintenue, changement d'onglet en échec intact" "$(c8_rouges "$WORK/c8base")" ""
  cockpit_arreter; unset COCKPIT_MODULE
  for m in "emission|c81.evenement c82.evenement c82.texteAbsent c84.evenementRepete c85.evenement |s|const annule = !D.dispatchEvent(ev); // garde:coquille-echec-emission|const annule = false;|" \
           "prevent|c82.texteAbsent |s|if (initial \&\& !annule) afficherEchec(nom); // garde:coquille-echec-prevent|if (initial) afficherEchec(nom);|" \
           "corps|c81.corps |s|t.textContent = MESSAGE_LECTURE; // garde:coquille-echec-corps|t.textContent = MESSAGE_LECTURE; fetch('/api/vf/graphe?onglet=' + nom, { headers: { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.jetons[nom] } }).then((r) => r.text()).then((x) => { t.textContent += ' ' + x; });|"; do
    nom="${m%%|*}"; reste="${m#*|}"; att="${reste%%|*}"; expr="${reste#*|}"; expr="${expr#*|}"; expr="s|${expr}"
    CPM="$(cockpit_module_copie)"; cp "$CPE/skills/cockpit-moteur/assets/ui/00-vf-zz-fixture-echec.js" "$CPM/skills/cockpit-moteur/assets/ui/"
    cp "$CPM/skills/cockpit-moteur/assets/vf-coquille.js" "$WORK/vf-coquille-$nom.avant"; sed -i.bak "$expr" "$CPM/skills/cockpit-moteur/assets/vf-coquille.js"
    if ! cmp -s "$WORK/vf-coquille-$nom.avant" "$CPM/skills/cockpit-moteur/assets/vf-coquille.js"; then
      COCKPIT_MODULE="$CPM" demarrer "$LAB"
      assert_eq "M-ECHEC-$(echo "$nom" | tr a-z A-Z) — l'ensemble des contrôles rouges de C8 est exactement { $att}" "$(c8_rouges "$WORK/c8mut-$nom")" "$att"
      cockpit_arreter; unset COCKPIT_MODULE
    else assert_eq "M-ECHEC-$(echo "$nom" | tr a-z A-Z) — mutant sans effet (ancre absente)" "sans effet" "effet"; fi
  done
fi
fi

echo "=== A37 — les gardes de chemin jugent la résolution physique, jamais la forme écrite ==="
node "$TESTS/coquille-propriete.mjs" gardes "$SCRIPTS" "$WORK/a37" > "$WORK/a37.json" 2>"$WORK/a37.err"
assert_eq "A37.1 — moduleAdmis : le verdict égale celui du noyau (realpath natif) pour neuf dispositions de liens (intérieur, chaîne, extérieur, pendant, boucle, sain, deux orthographes)" "$(oj 'Object.entries(j.cas).filter(([,c])=>!c.ok).map(([n])=>n).join(",")||"tous"' < "$WORK/a37.json")" "tous"
assert_eq "A37.2 — identité du serveur : deux orthographes d'un même lab = une identité, deux orthographes d'un même module = une identité ; un lab préfixe d'un autre = deux identités ; une sortie pendante n'a pas d'identité" "$(oj '[j.identites.memeLab,j.identites.prefixe,j.identites.pendante,j.identites.memeModule]' < "$WORK/a37.json")" "[true,true,true,true]"
assert_eq "A37.3 — couverture : au moins quatre refus et trois accords parmi les dispositions (la propriété n'est pas vide)" "$(oj '[Object.values(j.cas).filter(c=>c.oracle==="refus").length>=4,Object.values(j.cas).filter(c=>c.oracle==="accord").length>=3]' < "$WORK/a37.json")" "[true,true]"
ln -sfn "$OUT" "$WORK/lien-sortie"
assert_eq "A37.4 — serve.mjs --sortie= donné par un chemin qui traverse un lien : refus (code 1, message)" "$(node "$AUX/lien-sortie.mjs" "$ENG/assets/serve.mjs" "$WORK/lien-sortie")" "refus"
mkdir -p "$WORK/pend/.vibeflow"; ln -sfn "$WORK/nexiste-pas" "$WORK/pend/.vibeflow/cockpit"   # AU16-02 : une sortie PENDANTE à la bonne forme (<lab>/.vibeflow/cockpit) : seule la résolution physique la refuse
PEND="--sortie= est introuvable"
assert_eq "A37.5 — serve.mjs --sortie= pendante, de la forme <lab>/.vibeflow/cockpit : refus (code 1, « introuvable »), jamais un jugement sur la forme écrite" "$(node "$AUX/lien-sortie.mjs" "$ENG/assets/serve.mjs" "$WORK/pend/.vibeflow/cockpit" "$PEND")" "refus"
mut_a37() { # <nom> <sed> : le modèle de jugement muté, rejoué sur les mêmes dispositions
  cockpit_module_muter "$1" vf-cockpit-module.mjs "$2" || return 1
  rm -rf "$WORK/a37m"; node "$TESTS/coquille-propriete.mjs" gardes "$COCKPIT_MODULE/scripts" "$WORK/a37m" 2>/dev/null | oj 'Object.entries(j.cas).filter(([,c])=>!c.ok).map(([n])=>n).join(",")||"tous"'
}
assert_eq "M-LEXICAL — moduleAdmis jugeant des chemins normalisés : rougit A37.1 sur les liens (vers l'intérieur, chaîne, vers l'extérieur, pendant, boucle), jamais sur les cas sains" "$(mut_a37 lexical 's|const r = cheminPhysique(d); // garde:coquille-chemin|const r = path.resolve(d);|')" "lien-vers-interieur,chaine-de-deux,lien-vers-exterieur,pendant,boucle"
assert_eq "M-ECHEC-OUVERT — un échec de résolution vaut accord : rougit A37.1 sur le lien pendant et la boucle" "$(mut_a37 ouvert 's|if (r === null) throw refus(.dossier du module introuvable : refus..); // garde:coquille-echec|if (r === null) continue;|')" "pendant,boucle"
mut_id() { # <nom> <sed> : identiteServeur muté, rejoué sur les mêmes dispositions ; rend les quatre verdicts d'A37.2
  cockpit_module_muter "$1" vf-cockpit-serveur-vivant.mjs "$2" || return 1
  rm -rf "$WORK/a37i"; node "$TESTS/coquille-propriete.mjs" gardes "$COCKPIT_MODULE/scripts" "$WORK/a37i" 2>/dev/null | oj '[j.identites.memeLab,j.identites.prefixe,j.identites.pendante,j.identites.memeModule].join()'
}
assert_eq "M-IDENTITE-SORTIE (AU16-02) — identiteServeur jugeant la sortie par path.resolve : A37.2 rougit (deux orthographes d'un lab, sortie pendante), le reste vert" "$(mut_id idsortie 's|reelle = cheminPhysique(sortie);|reelle = path.resolve(sortie);|')" "false,true,false,true"
assert_eq "M-IDENTITE-SERVE (AU16-02) — identiteServeur jugeant serve.mjs par path.resolve : A37.2 rougit (deux orthographes d'un module), le reste vert" "$(mut_id idserve 's|const serve = cheminPhysique(path.join(moteur, .assets., .serve.mjs.)), reelle|const serve = path.resolve(path.join(moteur, "assets", "serve.mjs")), reelle|')" "true,true,true,false"
assert_eq "M-IDENTITE-LEXICALE (AU16-02) — les deux à la forme lexicale (path.resolve) : A37.2 rougit sur les trois identités qui dépendent de la résolution" "$(mut_id idlex 's|const serve = cheminPhysique(path.join(moteur, .assets., .serve.mjs.)), reelle = cheminPhysique(sortie);|const serve = path.resolve(path.join(moteur, "assets", "serve.mjs")), reelle = path.resolve(sortie);|')" "false,true,false,false"
if cockpit_module_muter sortielex serve.mjs 's#^if (!here) refus(.*);$#if (!here) here = path.resolve(sortieArg);#'; then
  SM="$(node "$AUX/lien-sortie.mjs" "$COCKPIT_MODULE/skills/cockpit-moteur/assets/serve.mjs" "$WORK/pend/.vibeflow/cockpit" "$PEND")|$(node "$AUX/lien-sortie.mjs" "$COCKPIT_MODULE/skills/cockpit-moteur/assets/serve.mjs" "$WORK/lien-sortie")"
  assert_eq "M-SORTIE-LEXICALE (AU16-02) — la garde « if (!here) refus » remplacée par un repli sur la forme écrite : A37.5 rougit (le refus d'une sortie pendante disparaît), A37.4 reste vert (le contrôle de forme du lien le tient seul)" "$SM" "autre 1|refus"
else assert_eq "M-SORTIE-LEXICALE — mutant sans effet (ancre absente)" "sans effet" "effet"; fi
unset COCKPIT_MODULE

echo "=== K6 — le module servi est celui que cockpit_lancer démarre (A48, point 41) ==="
base_srv; rq GET /_vf/ui/25-recent.js "$WORK/k6-base.js"; E0="$(hv etag)"
cockpit_arreter
if cockpit_module_muter k6 ui/25-recent.js '1s|^|/* MQ16-MUTANT */ |'; then
  MUT6="$COCKPIT_MODULE"; demarrer "$LAB"; rq GET /_vf/ui/25-recent.js "$WORK/k6-mut.js"; E1="$(hv etag)"
  assert_eq "K6.1 — le ui/*.js muté dans la copie est celui servi sous /_vf/ (contenu et étiquette changés)" "$(node "$OR" marque "$WORK/k6-mut.js" MQ16-MUTANT)|$([ "$E0" != "$E1" ] && [ -n "$E1" ] && echo diff || echo meme)" "oui|diff"
  assert_eq "K6.1 — témoin : le module d'origine ne porte pas la mutation, la copie diffère par cmp" "$(node "$OR" marque "$ENG/assets/ui/25-recent.js" MQ16-MUTANT)|$(node "$OR" marque "$WORK/k6-base.js" MQ16-MUTANT)|$(cmp -s "$ENG/assets/ui/25-recent.js" "$MUT6/skills/cockpit-moteur/assets/ui/25-recent.js" && echo egal || echo diff)" "non|non|diff"
else assert_eq "K6.1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== K2 (liens et liste) — un lien hors du moteur refuse le démarrage ; un fichier ajouté avant le démarrage entre dans la liste ==="
cockpit_arreter; unset COCKPIT_MODULE
CP="$(cockpit_module_copie)"; printf 'hors\n' > "$WORK/hors.js"; ln -sf "$WORK/hors.js" "$CP/skills/cockpit-moteur/assets/ui/05-theme.js"
COCKPIT_MODULE="$CP" COCKPIT_LOG="$WORK/lien.log" demarrer "$LAB"; K25="$RL|$(grep -c 'dossier des assets du moteur' "$WORK/lien.log")|$PORT"
assert_eq "K2.5 — un fichier d'asset relié à un fichier hors du moteur : le serveur refuse de démarrer (code 1, message français, rien n'écoute)" "$K25" "1|1|0"
CP2="$(cockpit_module_copie)"; ln -sf ../graph-query.js "$CP2/skills/cockpit-moteur/assets/ui/05-theme.js"
COCKPIT_MODULE="$CP2" demarrer "$LAB"; rq GET /_vf/ui/05-theme.js "$WORK/x.out"
assert_eq "K2.5 — témoin positif : un lien dont la cible reste sous le dossier des assets est accepté et servi" "$RL|$RQ_CODE" "0|200"
cockpit_arreter
CP3="$(cockpit_module_copie)"; printf 'window.__avant16 = 1;\n' > "$CP3/skills/cockpit-moteur/assets/ui/zz-vf-plante-avant.js"
base_srv; rq GET /project.html "$WORK/x.out"; CSPB="$(hv content-security-policy | sed "s/'sha256-[^']*'//g; s/:$PORT/:PORT/g; s/  */ /g")"; cockpit_arreter
COCKPIT_MODULE="$CP3" demarrer "$LAB"; rq GET /project.html "$WORK/doc-c3.html"; CSP3="$(hv content-security-policy | sed "s/'sha256-[^']*'//g; s/:$PORT/:PORT/g; s/  */ /g")"; rq GET /_vf/ui/zz-vf-plante-avant.js "$WORK/x.out"
assert_eq "K2.6 — le même nom ajouté AVANT le démarrage est servi (200), nommé au manifeste, sans que la CSP change (hors empreintes et port)" "$RQ_CODE|$(node "$OR" manifeste "$WORK/doc-c3.html" | oj 'j.noms.includes("ui/zz-vf-plante-avant.js")')|$([ "$CSP3" = "$CSPB" ] && echo meme || echo diff)" "200|true|meme"
cockpit_arreter

echo "=== M-PATHNAME (AU16-01) — la route du document jugeant url.pathname au lieu du chemin brut ==="
if cockpit_module_muter pathname serve.mjs "s#const brut = String(req.url || '').split('?')\[0\];#const brut = url.pathname;#"; then
  demarrer "$LAB"
  PM="$(for u in //x/ //x/project.html /./project.html /./ //project.html /project.html/ /equipe.html/. /index.html/../project.html /project.html / /index.html /equipe.html; do rq GET "$u" "$WORK/x.out"; printf '%s ' "$RQ_CODE"; done)"
  assert_eq "M-PATHNAME — url.pathname remis : les alias //x/, //x/project.html, /./project.html, /./, //project.html, /index.html/../project.html répondent 200 (K2.3 AU16-01 rouge), les quatre adresses restent 200, la barre finale reste 404" "$PM" "200 200 200 200 200 404 404 200 200 200 200 200 "
  cockpit_arreter
else assert_eq "M-PATHNAME — mutant sans effet (ancre absente)" "sans effet" "effet"; fi
unset COCKPIT_MODULE

echo "=== M-MARQUEUR — un marqueur de gabarit absent : le serveur refuse de démarrer et le nomme ==="
if cockpit_module_muter marq viewer.html 's|/\*__FONTS__\*/||'; then
  COCKPIT_LOG="$WORK/marq.log" demarrer "$LAB"
  assert_eq "M-MARQUEUR — viewer.html sans __FONTS__ : démarrage refusé (code 1), message qui nomme le marqueur" "$RL|$(grep -c '__FONTS__' "$WORK/marq.log")" "1|1"
else assert_eq "M-MARQUEUR — mutant sans effet" "sans effet" "effet"; fi
unset COCKPIT_MODULE

echo "=== K4.3, K4.4, K5.3 — les deux couches de l'E9, chacune avec son mutant ==="
cat > "$AUX/planter.js" <<'JS'
// echec: false
const ins = await s.ev(`new Promise((ok) => { const x = document.createElement('script'); x.src = '/plante.js'; x.onload = () => ok('charge'); x.onerror = () => ok('refuse'); document.head.appendChild(x); })`);
await pause(300);
return { insere: ins, plante: await s.ev('typeof window.__plante16'), violations: s.violations.length };
JS
if [ -n "$CHROME" ]; then
  base_srv; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/planter.js" > "$WORK/k43.json"
  assert_eq "K4.3 — /project.html : window.__plante16 indéfini et le script inséré par la page est refusé par la CSP (une violation), le service ne le sert pas" "$(oj '[j.plante,j.violations>0]' < "$WORK/k43.json")" "[\"undefined\",true]"
fi
base_srv; BASE_SERVICE="$(v_service)"; BASE_CSP="$(v_csp)"
assert_eq "K5.3 — témoin : le serveur de base ne sert rien de la sortie et sa CSP est propre" "$BASE_SERVICE|$BASE_CSP" "404 404 404 404 404 |propre"
cockpit_arreter
NAIF="if (!path.relative(here, path.join(here, decodeURIComponent(url.pathname))).split(path.sep).some((x) => x.startsWith('.'))) { let r = ''; try { r = fs.realpathSync(path.join(here, decodeURIComponent(url.pathname))); } catch {} if (r.startsWith(here + path.sep)) { res.writeHead(200, { 'Content-Type': 'text/javascript' }); return fs.createReadStream(r).pipe(res); } } res.writeHead(404); return res.end(); // garde:coquille-404"
if cockpit_module_muter service serve.mjs "s|res.writeHead(404); return res.end(); // garde:coquille-404|$NAIF|"; then
  MS="$COCKPIT_MODULE"; demarrer "$LAB"
  assert_eq "M-SERVICE — service de la sortie rétabli : K5.1 rougit pour /graph.json, le lien interne et /plante.js (200), pas pour le lien sortant ni .cache/" "$(v_service)" "200 200 200 404 404 "
  rq GET /project.html "$WORK/x.out"; assert_eq "M-SERVICE — témoin positif : /project.html répond 200 dans le même serveur muté" "$RQ_CODE" "200"
  if [ -n "$CHROME" ]; then chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/planter.js" > "$WORK/k44.json"
    assert_eq "K4.4 — service ouvert (200 sur /plante.js), la CSP seule suffit : le script inséré est refusé, __plante16 indéfini (couche CSP)" "$(oj '[j.plante,j.violations>0]' < "$WORK/k44.json")" "[\"undefined\",true]"; fi
  cockpit_arreter
  sed -i.avant "s|\${PREFIXE}\`; // garde:coquille-source|\${PREFIXE} ${Q}self${Q}\`; // garde:coquille-source|" "$MS/scripts/vf-cockpit-coquille.mjs"
  if ! cmp -s "$MS/scripts/vf-cockpit-coquille.mjs.avant" "$MS/scripts/vf-cockpit-coquille.mjs"; then
    COCKPIT_MODULE="$MS" demarrer "$LAB"
    assert_eq "M-CSP-SELF — la source 'self' ajoutée : K3.2 rougit (script-src porte 'self')" "$(v_csp)" "interdit"
    if [ -n "$CHROME" ]; then chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/planter.js" > "$WORK/k44s.json"
      assert_eq "M-CSP-SELF — service ouvert ET 'self' : K4.4 rougit, le marqueur s'exécute (la CSP est bien la seconde couche)" "$(oj 'j.plante' < "$WORK/k44s.json")" "number"; fi
    cockpit_arreter
  else assert_eq "M-CSP-SELF — mutant sans effet (ancre absente)" "sans effet" "effet"; fi
else assert_eq "M-SERVICE — mutant sans effet (ancre garde:coquille-404 absente ou inchangée)" "sans effet" "effet"; fi
unset COCKPIT_MODULE

echo "=== P — l'aide de mutation de page et le détecteur des mutations de page (79-16, tâche 5) ==="
src_pages() { local a="$1/skills/cockpit-moteur/assets" f; for f in "$a/viewer.html" "$a/graph-query.js" "$a"/ui/*.js; do printf '%s\n' "$f"; done; }
somme_depot() { src_pages "$MOD" | xargs cat | cksum; }
SD0="$(somme_depot)"
cockpit_module_muter_page p1abs 's|ANCRE-QUI-N-EXISTE-PAS-79-16|x|' 2>/dev/null; P11=$?
assert_eq "P1.1 — une ancre absente de toutes les sources de page : code 1, aucune copie utilisable laissée" "$P11|$([ -d "$WORK/mod-p1abs" ] && echo copie-laissee || echo aucune-copie)|${COCKPIT_MODULE:-aucun}" "1|aucune-copie|aucun"
ANC='<span class="meta">${h(size)}</span>'
unset COCKPIT_MODULE; cockpit_module_muter_page p12 "s#$ANC#<span class=\"meta\">\${size}</span>#"; P12=$?; CP12="${COCKPIT_MODULE:-}"; unset COCKPIT_MODULE
ATTENDUS="$(for f in $(src_pages "$MOD"); do grep -qF "$ANC" "$f" && printf '%s\n' "${f#$MOD/}"; done | LC_ALL=C sort | tr '\n' ' ')"
DIFF="$(for f in $(src_pages "$MOD"); do g="$CP12/${f#$MOD/}"; cmp -s "$f" "$g" || printf '%s\n' "${f#$MOD/}"; done | LC_ALL=C sort | tr '\n' ' ')"
assert_eq "P1.2 — sinon code 0, exactement les fichiers qui portent l'ancre diffèrent (cmp), le module du dépôt est identique avant et après (sommes)" "$P12|$([ -n "$ATTENDUS" ] && [ "$DIFF" = "$ATTENDUS" ] && echo egal || echo "attendus[$ATTENDUS] diffèrent[$DIFF]")|$([ "$SD0" = "$(somme_depot)" ] && echo depot-intact)" "0|egal|depot-intact"
AN3='window.VibeFlow = Object.freeze('
cockpit_module_muter_page p13 "s|$AN3|$AN3/*MQ16-ASSEMBLEE*/|" 2>/dev/null; P13=$?; CP13="${COCKPIT_MODULE:-}"; unset COCKPIT_MODULE
assert_eq "P1.3 — une ancre écrite contre la page ASSEMBLÉE (nom VibeFlow, que la source porte sous son nom d'origine) est trouvée : l'aide renomme d'abord" "$P13|$(grep -rlF 'MQ16-ASSEMBLEE' "$CP13/skills/cockpit-moteur/assets" 2>/dev/null | wc -l | tr -d ' ')" "0|1"
base_srv; unset COCKPIT_MODULE; cockpit_arreter
if [ "$P13" = 0 ]; then
  COCKPIT_MODULE="$CP13" demarrer "$LAB"; P14L=$RL; rq GET /_vf/moteur.js "$WORK/p14.js"
  assert_eq "P1.4 — le serveur lancé par cockpit_lancer sur la copie publie son empreinte (cockpit_module_charge, code 0) ET /_vf/moteur.js porte le fragment muté (témoin d'effet : le mutant est chargé)" "$P14L|$(node "$OR" marque "$WORK/p14.js" MQ16-ASSEMBLEE)" "0|oui"
  cockpit_arreter; unset COCKPIT_MODULE
else assert_eq "P1.4 — sans copie (P1.3 rouge)" "sans copie" "copie"; fi
# P1.5 mutant M-AIDE-SANS-RENOMMAGE : l'aide applique la substitution au texte NON renommé -> l'ancre de P1.3 n'existe plus
( _cockpit_page_renommer() { cp "$2" "$3"; }; cockpit_module_muter_page p15 "s|$AN3|$AN3/*MQ16-ASSEMBLEE*/|" 2>/dev/null; echo "rc=$?" ) > "$WORK/p15.out"
assert_eq "M-AIDE-SANS-RENOMMAGE — l'aide sans le renommage ne trouve plus l'ancre écrite contre la page assemblée : P1.3 rougit (code 1)" "$(cat "$WORK/p15.out")" "rc=1"
cat > "$AUX/exceptions.txt" <<'EXC'
# fichier|fragment de la ligne|motif : la page assemblée reste ÉCRITE (instantané ouvrable en fichier, base de l'export) ; ces lignes ne mutent rien de ce que le serveur sert
test-cockpit-chrome-fr.sh|const f=process.argv[1],fs=require("fs")|copie de la page assemblée, lue en fichier (file://) par l'inventaire des chaînes : jamais servie
test-cockpit-chrome-fr.sh|cp "$O12/index.html"|copie de la page assemblée, lue en fichier (file://) par l'inventaire des chaînes : jamais servie
test-cockpit-coquille.sh|window.__plante16 = 1</script></body>|plantation voulue par la suite de la coquille (E9) : le fichier planté n'est jamais servi
test-cockpit-coquille.sh|mkdir -p "$WORK/faux-tests"|texte synthétique du témoin positif du détecteur (P2.2) : écrit dans le dossier de travail, jamais servi
test-cockpit-reseau.sh|charger() { node "$AUX/get.mjs"|lecture de pages servies vers le dossier de travail : aucune écriture dans la sortie
test-cockpit-securite.sh|const urls = ['project.html#'|liste d'adresses de navigation, aucune écriture
test-cockpit-serveur.sh|mkdir -p "$WORK/lab-eq"|gabarit de DONNÉES d'un lab factice pour un serveur en processus : jamais servi
test-cockpit-terminal-lanceur.sh|L6 — SAF-1|texte d'un libellé d'assertion, aucune écriture
test-cockpit-terminal-lanceur.sh|L12b|texte d'un libellé d'assertion, aucune écriture
test-cockpit-terminal-lanceur.sh|L12c|texte d'un libellé d'assertion, aucune écriture
EXC
node "$TESTS/coquille-propriete.mjs" detecteur-pages "$TESTS" "$AUX/exceptions.txt" > "$WORK/p21.out"
assert_eq "P2.1 — aucune écriture de page de sortie hors de la liste d'exceptions FERMÉE (chacune porte son motif) : le détecteur ne nomme aucune suite" "$(sed -n '2,$p' "$WORK/p21.out" | head -3 | tr '\n' ' ')|$(sed -n 1p "$WORK/p21.out" | sed 's/touches=\([0-9]*\) exceptions=\([0-9]*\)/\1 \2/' | awk '{print ($1==$2 && $1>0)?"toutes-excusees":"reste"}')" "|toutes-excusees"
mkdir -p "$WORK/faux-tests"; printf '%s\n' 'mutant() { sed -i.bak "s#a#b#" "$o/project.html"; }' > "$WORK/faux-tests/test-cockpit-faux.sh"
assert_eq "P2.2 — témoin positif : un texte de suite synthétique qui écrit dans la page d'une sortie est détecté" "$(node "$TESTS/coquille-propriete.mjs" detecteur-pages "$WORK/faux-tests" "$AUX/exceptions.txt" | sed -n 2p | cut -d: -f1)" "test-cockpit-faux.sh"
: > "$AUX/exceptions-vide.txt"
assert_eq "P2.3 — mutant : liste d'exceptions vidée : P2.1 rougit et nomme les suites exceptées (chrome-fr, coquille, reseau, securite, serveur, terminal-lanceur)" "$(node "$TESTS/coquille-propriete.mjs" detecteur-pages "$TESTS" "$AUX/exceptions-vide.txt" | sed '1d' | cut -d: -f1 | LC_ALL=C sort -u | tr '\n' ' ')" "test-cockpit-chrome-fr.sh test-cockpit-coquille.sh test-cockpit-reseau.sh test-cockpit-securite.sh test-cockpit-serveur.sh test-cockpit-terminal-lanceur.sh "

# FIN
cockpit_arreter
vf_hyg_assert
echo ""; echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
